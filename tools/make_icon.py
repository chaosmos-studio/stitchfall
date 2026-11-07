#!/usr/bin/env python3
"""Draws Stitchfall's icon: the runner's portrait on sage felt inside a stitched border.

    python3 tools/make_icon.py

Writes assets/branding/icon.png at 1024 square, from the front reference sheet and the felt tile, so a
change to either reaches the icon on the next run. Also writes Android's adaptive icon layers and Google
Play's 512 icon.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SIZE = 1024
SAGE = (134, 156, 118)
# How much of the felt's own colour gives way to sage.
SAGE_MIX = 0.6
THREAD = (250, 238, 214, 240)
# From the edge, in pixels, and the length of one stitch plus its gap.
STITCH_INSET = 52
STITCH_PITCH = 42
STITCH_WIDTH = 13
# The share of the runner's height kept: hair, face, scarf and the top of the coat.
PORTRAIT = 0.42
# Android's adaptive icon is 108 dp with 72 dp shown and a 66 dp safe circle, drawn here at 432 px. The
# portrait's width and where its bottom sits, as shares of the layer: the face stays in the safe circle and
# the shoulders run off the bottom of the shown area, as on the full icon.
ADAPTIVE = 432
ADAPTIVE_WIDTH = 0.78
ADAPTIVE_BOTTOM = 0.9


def felt() -> Image.Image:
    tile = Image.open(ROOT / "assets/art/felt_tile.png").convert("RGB")
    out = Image.new("RGB", (SIZE, SIZE))
    for y in range(0, SIZE, tile.height):
        for x in range(0, SIZE, tile.width):
            out.paste(tile, (x, y))
    return Image.blend(out, Image.new("RGB", (SIZE, SIZE), SAGE), SAGE_MIX).convert("RGBA")


def portrait() -> Image.Image:
    sheet = Image.open(ROOT / "assets/art/seam_runner_front_reference.png").convert("RGBA")
    # The sheet's faint halo would count in a plain bounding box.
    body = sheet.crop(sheet.split()[3].point(lambda v: 255 if v > 60 else 0).getbbox())
    head = body.crop((0, 0, body.width, int(body.height * PORTRAIT)))
    scale = SIZE * 0.98 / head.width
    return head.resize((int(head.width * scale), int(head.height * scale)), Image.LANCZOS)


def stitches(draw: ImageDraw.ImageDraw) -> None:
    m = STITCH_INSET
    corners = [(m, m), (SIZE - m, m), (SIZE - m, SIZE - m), (m, SIZE - m)]
    for (x0, y0), (x1, y1) in zip(corners, corners[1:] + corners[:1]):
        n = int(math.dist((x0, y0), (x1, y1)) // STITCH_PITCH)
        for k in range(n):
            a, b = k / n, (k + 0.55) / n
            draw.line([(x0 + (x1 - x0) * a, y0 + (y1 - y0) * a), (x0 + (x1 - x0) * b, y0 + (y1 - y0) * b)],
                      fill=THREAD, width=STITCH_WIDTH)


def main() -> None:
    icon = felt()
    head = portrait()
    x, y = (SIZE - head.width) // 2, SIZE - head.height + 6
    shadow = Image.new("RGBA", head.size, (40, 40, 25, 0))
    shadow.putalpha(head.split()[3].filter(ImageFilter.GaussianBlur(16)).point(lambda v: int(v * 0.5)))
    icon.alpha_composite(shadow, (x + 12, y + 18))
    icon.alpha_composite(head, (x, y))
    stitches(ImageDraw.Draw(icon))
    out = ROOT / "assets/branding/icon.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    icon.convert("RGB").save(out)
    print(out)
    # Play wants a 32-bit PNG and rounds the corners itself.
    store = ROOT / "assets/store/play_store_icon_512.png"
    store.parent.mkdir(parents=True, exist_ok=True)
    icon.resize((512, 512), Image.LANCZOS).save(store)
    print(store)
    adaptive(head)


def adaptive(head: Image.Image) -> None:
    background = felt().resize((ADAPTIVE, ADAPTIVE), Image.LANCZOS)
    background.convert("RGB").save(ROOT / "assets/branding/adaptive_background.png")
    width = int(ADAPTIVE * ADAPTIVE_WIDTH)
    small = head.resize((width, int(head.height * width / head.width)), Image.LANCZOS)
    foreground = Image.new("RGBA", (ADAPTIVE, ADAPTIVE), (0, 0, 0, 0))
    x, y = (ADAPTIVE - small.width) // 2, int(ADAPTIVE * ADAPTIVE_BOTTOM) - small.height
    shadow = Image.new("RGBA", small.size, (40, 40, 25, 0))
    shadow.putalpha(small.split()[3].filter(ImageFilter.GaussianBlur(7)).point(lambda v: int(v * 0.5)))
    foreground.alpha_composite(shadow, (x + 5, y + 7))
    foreground.alpha_composite(small, (x, y))
    foreground.save(ROOT / "assets/branding/adaptive_foreground.png")
    print(ROOT / "assets/branding/adaptive_foreground.png")


if __name__ == "__main__":
    main()
