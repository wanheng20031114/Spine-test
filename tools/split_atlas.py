"""Lossless 4x4 atlas slicing. Preserve source RGBA; never infer alpha from RGB."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / "assets" / "operator"
NAMES = [
    "head", "hair_back", "torso", "coat_tail",
    "upper_arm_far", "forearm_far", "upper_arm_near", "forearm_near",
    "thigh_far", "shin_far", "thigh_near", "shin_near",
    "sword", "bow", "arrow", "pull_hand",
]


def main():
    source = Image.open(DIRECTORY / "parts_atlas.png")
    assert source.mode == "RGBA" and source.getchannel("A").getextrema() == (0, 255)
    parts = {}
    for index, name in enumerate(NAMES):
        col, row = index % 4, index // 4
        cell = (round(col * source.width / 4), round(row * source.height / 4),
                round((col + 1) * source.width / 4), round((row + 1) * source.height / 4))
        tile = source.crop(cell)
        # AI output has almost invisible alpha speckles in the empty margins.
        # Use alpha >= 8 only to locate the crop, then retain all original pixels
        # inside a four-pixel guard. This never rewrites the alpha channel.
        bounds = tile.getchannel("A").point(lambda a: 255 if a >= 8 else 0).getbbox()
        assert bounds, name
        bounds = (max(0, bounds[0] - 4), max(0, bounds[1] - 4),
                  min(tile.width, bounds[2] + 4), min(tile.height, bounds[3] + 4))
        cropped = tile.crop(bounds)
        # Transparent padding protects the original alpha edges during texture sampling.
        padded = Image.new("RGBA", (cropped.width + 8, cropped.height + 8))
        padded.paste(cropped, (4, 4))
        padded.save(DIRECTORY / (name + ".png"))
        parts[name] = {"cell": cell, "alpha_bounds": bounds, "size": padded.size}
    (DIRECTORY / "parts.json").write_text(json.dumps(parts, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(parts, ensure_ascii=False))


if __name__ == "__main__":
    main()
