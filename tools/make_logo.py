#!/usr/bin/env python3
"""Sets Stitchfall's name into its logo art.

    python3 tools/make_logo.py

The art in assets/branding/source/ was painted for the logo, on transparent backgrounds: a felt label the runner
leaps from, and a round sew-on patch. The name goes on in Darn Display, the game's title font. It writes:

- .github/logo.png, the label with the name, for the README (Godot never imports .github/);
- assets/art/logo_label.png, the label and name without the runner, for Home, the web loader and the store art,
  where the runner already stands beside it;
- assets/branding/badge.png, the patch with the name on its upper arc, for avatars and the press kit;
- build/logo/sheet.png, all three on a light and a dark page, to look at.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/branding/source"
TITLE_FONT = ROOT / "assets/fonts/Darn-Display.ttf"
CREAM = (248, 236, 210, 255)
EMBOSS = (70, 22, 10)

# Where the name goes, in the source images' pixels. Measure again if the art is replaced.
LABEL_TEXT_BOX = (135, 362, 1290, 548)
# The plain label: the runner's boot rests on the label's top edge inside RUNNER_FOOT, so that strip is covered
# with the same straight edge from CLONE_SHIFT pixels to the left, blended over FEATHER pixels at each side, and
# LABEL_ONLY then leaves out the runner above and the thread below.
RUNNER_FOOT = (1130, 300, 1240, 356)
CLONE_SHIFT = 130
FEATHER = 16
LABEL_ONLY = (80, 318, 1340, 588)
PLAIN_WIDTH = 1000
PATCH_CENTRE = (508, 511)
# The name's middle sits on this circle, between the runner's raised hands and the ring of stitches.
PATCH_NAME_RADIUS = 366
PATCH_NAME_SIZE = 74
PATCH_TRACKING = 1.04
README_WIDTH = 1120
BADGE_WIDTH = 720


def pressed(glyphs: Image.Image, blur: float = 3, offset: tuple = (3, 6)) -> Image.Image:
    """Lettering with a soft shadow below it, as if sewn into the felt."""
    pad = 16
    out = Image.new("RGBA", (glyphs.width + pad * 2, glyphs.height + pad * 2), (0, 0, 0, 0))
    shade = Image.new("RGBA", glyphs.size, EMBOSS + (0,))
    shade.putalpha(glyphs.split()[3].point(lambda v: int(v * 0.55)))
    out.alpha_composite(shade, (pad + offset[0], pad + offset[1]))
    out = out.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(glyphs, (pad, pad))
    return out


def without_runner(art: Image.Image) -> Image.Image:
    x0, y0, x1, y1 = RUNNER_FOOT
    edge = art.crop((x0 - CLONE_SHIFT, y0, x1 - CLONE_SHIFT, y1))
    ramp = [min(255, 255 * min(x + 1, x1 - x0 - x) // FEATHER) for x in range(x1 - x0)]
    mask = Image.new("L", edge.size)
    mask.putdata(ramp * edge.height)
    art.paste(edge, (x0, y0), mask)
    out = art.crop(LABEL_ONLY)
    return out.crop(out.getbbox())


def label(runner: bool = True) -> Image.Image:
    art = Image.open(SOURCE / "label_banner.png").convert("RGBA")
    x0, y0, x1, y1 = LABEL_TEXT_BOX
    size = 400
    while True:
        font = ImageFont.truetype(str(TITLE_FONT), size)
        box = font.getbbox("Stitchfall")
        if box[2] - box[0] <= (x1 - x0) * 0.86 and box[3] - box[1] <= (y1 - y0) * 0.8:
            break
        size -= 2
    glyphs = Image.new("RGBA", (box[2] - box[0] + 8, box[3] - box[1] + 8), (0, 0, 0, 0))
    ImageDraw.Draw(glyphs).text((4 - box[0], 4 - box[1]), "Stitchfall", font=font, fill=CREAM)
    name = pressed(glyphs)
    art.alpha_composite(name, ((x0 + x1 - name.width) // 2, (y0 + y1 - name.height) // 2))
    return art.crop(art.getbbox()) if runner else without_runner(art)


def badge() -> Image.Image:
    art = Image.open(SOURCE / "sew_on_patch.png").convert("RGBA")
    font = ImageFont.truetype(str(TITLE_FONT), PATCH_NAME_SIZE)
    ascent, descent = font.getmetrics()
    widths = [font.getlength(ch) * PATCH_TRACKING for ch in "Stitchfall"]
    cx, cy, r = *PATCH_CENTRE, PATCH_NAME_RADIUS
    # Angles in degrees, -90 straight up, so the name reads left to right across the top.
    angle = -90 - math.degrees(sum(widths) / r) / 2
    for ch, width in zip("Stitchfall", widths):
        middle = angle + math.degrees(width / 2 / r)
        glyph = Image.new("RGBA", (int(width) + 20, ascent + descent + 20), (0, 0, 0, 0))
        ImageDraw.Draw(glyph).text((10, 10), ch, font=font, fill=CREAM)
        glyph = pressed(glyph, blur=2.5, offset=(2, 5)).rotate(-(middle + 90), Image.BICUBIC, expand=True)
        x = cx + r * math.cos(math.radians(middle))
        y = cy + r * math.sin(math.radians(middle))
        art.alpha_composite(glyph, (int(x - glyph.width / 2), int(y - glyph.height / 2)))
        angle += math.degrees(width / r)
    return art.crop(art.getbbox())


def fit(im: Image.Image, width: int) -> Image.Image:
    return im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)


def sheet(images: list) -> Image.Image:
    """Each image on a light page and a dark one, side by side."""
    height = 420
    rows = [im.resize((int(im.width * height / im.height), height), Image.LANCZOS) for im in images]
    width = max(im.width for im in rows) + 40
    out = Image.new("RGB", (width * 2, (height + 40) * len(rows)))
    for row, im in enumerate(rows):
        for column, page in enumerate([(255, 255, 255), (13, 17, 23)]):
            panel = Image.new("RGBA", (width, height + 40), page + (255,))
            panel.alpha_composite(im, ((width - im.width) // 2, 20))
            out.paste(panel.convert("RGB"), (column * width, row * (height + 40)))
    return out


def main() -> None:
    wordmark = label()
    fit(wordmark, README_WIDTH).save(ROOT / ".github/logo.png", optimize=True)
    plain = label(runner=False)
    fit(plain, PLAIN_WIDTH).save(ROOT / "assets/art/logo_label.png", optimize=True)
    patch = badge()
    fit(patch, BADGE_WIDTH).save(ROOT / "assets/branding/badge.png", optimize=True)
    (ROOT / "build/logo").mkdir(parents=True, exist_ok=True)
    sheet([wordmark, plain, patch]).save(ROOT / "build/logo/sheet.png")
    for path in (".github/logo.png", "assets/art/logo_label.png", "assets/branding/badge.png", "build/logo/sheet.png"):
        print(ROOT / path)


if __name__ == "__main__":
    main()
