"""Losslessly align AI-generated RGBA frames and author a native SpriteFrames resource.

No raster painting, alpha reconstruction, resampling or synthetic in-between frames.
Alpha thresholds locate crop/ground bounds only; copied RGBA pixels are unchanged.
"""
import hashlib
import json
from pathlib import Path
from statistics import median

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/schoolgirl_frames"
NAMES = ["idle_sword", "walk_sword", "jump_sword", "slash", "idle_bow", "walk_bow",
         "jump_bow", "bow_draw", "bow_release", "bow_draw_up", "bow_release_up",
         "bow_draw_down", "bow_release_down"]
CELL = 512
PIVOT = (256, 464)


def bounds_at(image, threshold):
    return image.getchannel("A").point(lambda a: 255 if a >= threshold else 0).getbbox()


def split_sheet(name):
    source = Image.open(ART / "source" / f"{name}.png")
    assert source.mode == "RGBA", name
    alpha = source.getchannel("A")
    assert alpha.getextrema() == (0, 255), (name, alpha.getextrema())
    width, height = source.size
    x_edges = [round(width * i / 4) for i in range(5)]
    # Raised bow tips can cross the nominal half-height. Locate the actual
    # transparent gutter independently in each column, without touching pixels.
    row_cuts = []
    for left, right in zip(x_edges, x_edges[1:]):
        middle = height // 2
        rows = range(middle - 24, middle + 25)
        cut = min(rows, key=lambda y: (sum(a >= 32 for a in alpha.crop((left, y, right, y + 1)).getdata()), abs(y - middle)))
        assert sum(a >= 32 for a in alpha.crop((left, cut, right, cut + 1)).getdata()) == 0, (name, "no row gutter", left)
        row_cuts.append(cut)
    cells = []
    for index in range(8):
        col, row = index % 4, index // 4
        rect = (x_edges[col], 0 if row == 0 else row_cuts[col], x_edges[col + 1], row_cuts[col] if row == 0 else height)
        part = source.crop(rect)
        core = bounds_at(part, 192)
        assert core is not None, (name, index)
        cells.append((rect, part, core))
    # The jump's airborne poses keep the standing root; aligning their soles
    # would incorrectly erase the bent-leg/tucked-leg motion.
    jump_ground = median(cells[i][0][1] + cells[i][2][3] - (0 if i < 4 else height / 2) for i in [0, 1, 6, 7])
    sheet = Image.new("RGBA", (CELL * 4, CELL * 2))
    records = []
    for index, (rect, part, core) in enumerate(cells):
        crop_bounds = bounds_at(part, 16)
        crop = part.crop(crop_bounds)
        root_x = rect[0] + 225
        ground_y = rect[1] + core[3]
        if name.startswith("jump") and index in [2, 3, 4, 5]:
            ground_y = round(jump_ground + (0 if index < 4 else height / 2))
        origin = (PIVOT[0] + rect[0] + crop_bounds[0] - root_x,
                  PIVOT[1] + rect[1] + crop_bounds[1] - ground_y)
        assert min(origin) >= 4 and origin[0] + crop.width <= CELL - 4 and origin[1] + crop.height <= CELL - 4, (name, index, origin, crop.size)
        frame = Image.new("RGBA", (CELL, CELL))
        frame.paste(crop, origin)
        copied = frame.crop((origin[0], origin[1], origin[0] + crop.width, origin[1] + crop.height))
        assert copied.tobytes() == crop.tobytes(), (name, index, "RGBA changed")
        frame.save(ART / "frames" / f"{name}_{index:02}.png")
        sheet.paste(frame, ((index % 4) * CELL, (index // 4) * CELL))
        records.append({"cell": rect, "crop": crop_bounds, "source_pivot": [root_x, ground_y],
                        "paste": origin, "rgba_sha256": hashlib.sha256(crop.tobytes()).hexdigest()})
    sheet.save(ART / f"{name}.png")
    return {"source_size": source.size, "row_cuts": row_cuts, "frames": records}


def write_resource():
    lines = ['[gd_resource type="SpriteFrames" format=3]', ""]
    for name in NAMES:
        lines.append(f'[ext_resource type="Texture2D" path="res://assets/schoolgirl_frames/{name}.png" id="{name}"]')
    for name in NAMES:
        for i in range(8):
            lines += ["", f'[sub_resource type="AtlasTexture" id="{name}_{i}"]',
                      f'atlas = ExtResource("{name}")', f'region = Rect2({i % 4 * CELL}, {i // 4 * CELL}, {CELL}, {CELL})', "filter_clip = true"]
    animations = []

    def add(name, sheet, indices, fps, loop, durations=None):
        durations = durations or [1.0] * len(indices)
        frames = []
        for index, duration in zip(indices, durations):
            source_name = sheet
            source_index = index
            # Use the exact held drawing pose at release start, avoiding a
            # different generated full-draw pose at the state boundary.
            if sheet.startswith("bow_release") and index == 0:
                source_name = sheet.replace("release", "draw")
                source_index = 7
            frames.append('{"duration": %s, "texture": SubResource("%s_%s")}' % (duration, source_name, source_index))
        animations.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s}' %
                          (", ".join(frames), str(loop).lower(), name, fps))

    for name in NAMES:
        fps, loop, durations = 10.0, False, None
        if name.startswith("idle"):
            fps, loop, durations = 6.0, True, [4, 2, 2, 2, .5, .5, .5, 2.5]
        elif name.startswith("walk"):
            fps, loop = 12.0, True
        elif name == "slash":
            fps, durations = 16.0, [1, 1.4, 1.1, .65, .65, 1.3, 1.3, 1.6]
        elif name.startswith("bow_release"):
            fps, durations = 16.0, [.35, .65, .8, 1, 1.2, 1.2, 1.2, 1.6]
        add(name, name, range(8), fps, loop, durations)
    for weapon in ["sword", "bow"]:
        add("jump_start_" + weapon, "jump_" + weapon, [0, 1, 2], 24, False)
        add("jump_air_" + weapon, "jump_" + weapon, [3, 4, 5], 8, False)
        add("jump_land_" + weapon, "jump_" + weapon, [6, 7], 16, False)
    lines += ["", "[resource]", "animations = [" + ",\n".join(animations) + "]", ""]
    (ART / "schoolgirl_frames.tres").write_text("\n".join(lines), encoding="utf-8")


def main():
    (ART / "frames").mkdir(exist_ok=True)
    (ART / "frames/.gdignore").write_text("\n", encoding="utf-8")
    manifest = {"cell_size": [CELL, CELL], "pivot": PIVOT, "display_scale": .6,
                "sheets": {name: split_sheet(name) for name in NAMES}}
    (ART / "frames.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_resource()
    print(f"SPRITE_ART_OK: {len(NAMES)} sheets, {len(NAMES) * 8} generated frames; all cropped RGBA bytes preserved.")


if __name__ == "__main__":
    main()
