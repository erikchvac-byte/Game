"""
Palette quantizer — remaps all PNGs in game/GameAssets/ to the master palette.
Run from the repo root: python quantize_assets.py
"""
import json
import os
import sys
import time
from pathlib import Path
from PIL import Image

PALETTE_JSON = Path("game/addons/palette_enforcer/palette.json")
ASSETS_DIR   = Path("game/GameAssets")

def load_palette():
    with open(PALETTE_JSON) as f:
        data = json.load(f)
    return [
        (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16))
        for h in data["colors"]
    ]

def make_pil_palette(colors):
    """Build a PIL 'P' mode image containing the palette."""
    flat = []
    for r, g, b in colors:
        flat.extend([r, g, b])
    # Pad to 256 entries
    flat.extend([0, 0, 0] * (256 - len(colors)))
    pal_img = Image.new("P", (1, 1))
    pal_img.putpalette(flat)
    return pal_img

def quantize_image(path: Path, pal_img: Image.Image) -> bool:
    """Quantize one image in-place. Returns True if the file changed."""
    orig = Image.open(path).convert("RGBA")
    r, g, b, a = orig.split()
    rgb = Image.merge("RGB", (r, g, b))

    # PIL quantize with no dithering — nearest palette color per pixel
    quantized = rgb.quantize(palette=pal_img, dither=0).convert("RGB")
    result = Image.merge("RGBA", (*quantized.split(), a))

    if list(result.getdata()) == list(orig.getdata()):
        return False

    result.save(path)
    return True

def main():
    palette = load_palette()
    print(f"Palette: {len(palette)} colors")

    pal_img = make_pil_palette(palette)

    pngs = sorted(ASSETS_DIR.rglob("*.png"))
    print(f"Files:   {len(pngs)}")
    print()

    fixed = 0
    t0 = time.time()
    for i, path in enumerate(pngs, 1):
        try:
            changed = quantize_image(path, pal_img)
            if changed:
                fixed += 1
                print(f"  FIXED  {path.relative_to(ASSETS_DIR)}")
        except Exception as e:
            print(f"  ERROR  {path.relative_to(ASSETS_DIR)}: {e}", file=sys.stderr)

        if i % 50 == 0:
            elapsed = time.time() - t0
            print(f"  ... {i}/{len(pngs)} ({elapsed:.1f}s)")

    elapsed = time.time() - t0
    print()
    print(f"Done in {elapsed:.1f}s — {fixed}/{len(pngs)} files remapped.")

if __name__ == "__main__":
    main()
