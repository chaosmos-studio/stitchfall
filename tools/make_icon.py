#!/usr/bin/env python3
"""Makes Stitchfall's icons from the painted art in assets/branding/source/.

    python3 tools/make_icon.py

mobile_icon.png is the full square icon: assets/branding/icon.png and Google Play's 512 icon come from it.
adaptive_foreground.png (the runner on the patch, transparent) and adaptive_background.png (seamless felt) are
Android's adaptive icon layers. It also writes build/logo/icon_masks.png, the adaptive icon under the shapes
phones cut it to and the full icon at launcher size, to look at.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/branding/source"
SIZE = 1024
# Android's adaptive icon layers are 108 dp, drawn here at 432 px. Launchers show the middle 72 dp (288 px)
# under their mask, which is why the painted foreground keeps the runner inside the middle two thirds.
ADAPTIVE = 432
SHOWN = 288


def masks(art: Image.Image, background: Image.Image, foreground: Image.Image) -> Image.Image:
    """The adaptive icon under a circle, a squircle and a rounded square, then the full icon at 64 and 48 px."""
    layered = background.convert("RGBA")
    layered.alpha_composite(foreground)
    edge = (ADAPTIVE - SHOWN) // 2
    shown = layered.crop((edge, edge, edge + SHOWN, edge + SHOWN))
    out = Image.new("RGB", (SHOWN * 3 + 64 + 48 + 120, SHOWN + 12), (232, 232, 232))
    for i, radius in enumerate([SHOWN // 2, 100, 48]):
        mask = Image.new("L", (SHOWN, SHOWN), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, SHOWN - 1, SHOWN - 1), radius=radius, fill=255)
        out.paste(shown.convert("RGB"), (i * (SHOWN + 10), 6), mask)
    out.paste(art.resize((64, 64), Image.LANCZOS), (SHOWN * 3 + 40, 118))
    out.paste(art.resize((48, 48), Image.LANCZOS), (SHOWN * 3 + 120, 126))
    return out


def main() -> None:
    art = Image.open(SOURCE / "mobile_icon.png").convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)
    art.save(ROOT / "assets/branding/icon.png", optimize=True)
    # Play wants a 32-bit PNG and rounds the corners itself.
    art.resize((512, 512), Image.LANCZOS).convert("RGBA").save(ROOT / "assets/store/play_store_icon_512.png", optimize=True)
    background = Image.open(SOURCE / "adaptive_background.png").convert("RGB").resize((ADAPTIVE, ADAPTIVE), Image.LANCZOS)
    background.save(ROOT / "assets/branding/adaptive_background.png", optimize=True)
    foreground = Image.open(SOURCE / "adaptive_foreground.png").convert("RGBA").resize((ADAPTIVE, ADAPTIVE), Image.LANCZOS)
    foreground.save(ROOT / "assets/branding/adaptive_foreground.png", optimize=True)
    (ROOT / "build/logo").mkdir(parents=True, exist_ok=True)
    masks(art, background, foreground).save(ROOT / "build/logo/icon_masks.png")
    for path in ("assets/branding/icon.png", "assets/store/play_store_icon_512.png",
                 "assets/branding/adaptive_background.png", "assets/branding/adaptive_foreground.png",
                 "build/logo/icon_masks.png"):
        print(ROOT / path)


if __name__ == "__main__":
    main()
