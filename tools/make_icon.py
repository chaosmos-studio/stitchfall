#!/usr/bin/env python3
"""Makes Stitchfall's icons from the painted icon in assets/branding/source/mobile_icon.png.

    python3 tools/make_icon.py

Writes assets/branding/icon.png at 1024 square, Google Play's 512 icon, Android's adaptive icon layers, and
build/logo/icon_masks.png, the icon under the shapes phones cut it to and at launcher size, to look at.
"""

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/branding/source/mobile_icon.png"
SIZE = 1024
# Android's adaptive icon is 108 dp, drawn here at 432 px. Launchers show the middle 72 dp under their mask and
# keep the rest for motion. The art spans a little more than the shown part, so a round mask trims only felt
# and the scarf's fringe, and the felt beyond it is the art mirrored, so a moving icon never shows an edge.
ADAPTIVE = 432
ADAPTIVE_ART_DP = 74


def adaptive_background(art: Image.Image) -> Image.Image:
    side = round(ADAPTIVE * ADAPTIVE_ART_DP / 108)
    small = np.asarray(art.resize((side, side), Image.LANCZOS))
    margin = (ADAPTIVE - side) // 2
    rest = ADAPTIVE - side - margin
    return Image.fromarray(np.pad(small, ((margin, rest), (margin, rest), (0, 0)), mode="reflect"))


def masks(art: Image.Image, background: Image.Image) -> Image.Image:
    """The adaptive icon under a circle, a squircle and a rounded square, then the full icon at 64 and 48 px."""
    shown = background.crop((72, 72, 360, 360)).resize((288, 288), Image.LANCZOS)
    out = Image.new("RGB", (288 * 3 + 64 + 48 + 120, 300), (232, 232, 232))
    for i, radius in enumerate([144, 100, 48]):
        mask = Image.new("L", (288, 288), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, 287, 287), radius=radius, fill=255)
        out.paste(shown, (i * 298, 6), mask)
    out.paste(art.resize((64, 64), Image.LANCZOS), (288 * 3 + 40, 118))
    out.paste(art.resize((48, 48), Image.LANCZOS), (288 * 3 + 120, 126))
    return out


def main() -> None:
    art = Image.open(SOURCE).convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)
    art.save(ROOT / "assets/branding/icon.png", optimize=True)
    # Play wants a 32-bit PNG and rounds the corners itself.
    art.resize((512, 512), Image.LANCZOS).convert("RGBA").save(ROOT / "assets/store/play_store_icon_512.png", optimize=True)
    background = adaptive_background(art)
    background.save(ROOT / "assets/branding/adaptive_background.png", optimize=True)
    Image.new("RGBA", (ADAPTIVE, ADAPTIVE), (0, 0, 0, 0)).save(ROOT / "assets/branding/adaptive_foreground.png")
    (ROOT / "build/logo").mkdir(parents=True, exist_ok=True)
    masks(art, background).save(ROOT / "build/logo/icon_masks.png")
    for path in ("assets/branding/icon.png", "assets/store/play_store_icon_512.png",
                 "assets/branding/adaptive_background.png", "assets/branding/adaptive_foreground.png",
                 "build/logo/icon_masks.png"):
        print(ROOT / path)


if __name__ == "__main__":
    main()
