"""Trim native alpha margins and pad separate image_gen sprites without repainting."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / "assets/schoolgirl_profile"
NAMES = ["head", "hair_back", "torso", "skirt", "upper_arm", "forearm",
         "thigh", "shin", "foot", "hand_sword", "hand_bow", "hand_pull",
         "hand_relaxed", "sword", "bow", "arrow"]


def main():
    manifest = {}
    for name in NAMES:
        source = Image.open(DIRECTORY / "source" / (name + ".png"))
        assert source.mode == "RGBA", name
        alpha = source.getchannel("A")
        assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] >= 250, name
        # Threshold locates almost invisible margin speckles only. Output alpha
        # and all RGB values inside the crop are copied byte-for-byte.
        bounds = alpha.point(lambda a: 255 if a >= 8 else 0).getbbox()
        cropped = source.crop(bounds)
        padded = Image.new("RGBA", (cropped.width + 8, cropped.height + 8))
        padded.paste(cropped, (4, 4))
        assert padded.crop((4, 4, 4 + cropped.width, 4 + cropped.height)).tobytes() == cropped.tobytes()
        padded.save(DIRECTORY / (name + ".png"))
        manifest[name] = {"source": "source/" + name + ".png", "source_size": source.size,
                          "alpha_crop": bounds, "padding": 4, "size": padded.size}
    (DIRECTORY / "parts.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({name: entry["size"] for name, entry in manifest.items()}))


if __name__ == "__main__":
    main()
