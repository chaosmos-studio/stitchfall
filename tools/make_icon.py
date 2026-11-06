#!/usr/bin/env python3
"""Draws Stitchfall's icon: the runner's portrait on sage felt inside a stitched border.

    python3 tools/make_icon.py

Writes assets/branding/icon.png at 1024 square, from the front reference sheet and the felt tile, so a
change to either reaches the icon on the next run.
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


if __name__ == "__main__":
    main()
