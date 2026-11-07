#!/usr/bin/env python3
"""Sets Stitchfall's name into its logo art.

    python3 tools/make_logo.py

The art in assets/branding/source/ was painted for the logo: a felt label the runner leaps from, and a round
sew-on patch. Each is lifted off its white paper (or keeps its own transparency, when it has some), and the name
goes on in Darn Display, the game's title font. It writes:

- .github/logo.png, the label with the name, for the README (Godot never imports .github/);
- assets/branding/badge.png, the patch with the name on its upper arc, for avatars and the press kit;
- build/logo/sheet.png, both on a light and a dark page, to look at.

Needs numpy and scipy. MATH.md, Lifting art off white paper, explains the cut.
"""

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/branding/source"
TITLE_FONT = ROOT / "assets/fonts/Darn-Display.ttf"
CREAM = (248, 236, 210, 255)
EMBOSS = (70, 22, 10)

# Where the name goes, in the source images' pixels. Measure again if the art is replaced.
LABEL_TEXT_BOX = (135, 362, 1290, 548)
# The needle's steel is as grey as the paper's shadow, so inside this box only clean paper is cut away.
NEEDLE_BOX = (1325, 585, 1500, 625)
PATCH_CENTRE = (508, 512)
# The name's middle sits on this circle, between the runner's raised hands and the ring of stitches.
PATCH_NAME_RADIUS = 366
PATCH_NAME_SIZE = 74
PATCH_TRACKING = 1.04
README_WIDTH = 1120

# The cut. Paper and its shadows are light and nearly grey. Any patch of them touching the image's edge, or
# larger than PAPER_AREA, is paper; smaller ones are highlights inside the art and stay.
PAPER_MIN = 150
PAPER_GREY = 40
PAPER_AREA = 400
PAPER_WHITE = 238
EDGE_PX = 2


def lift(path: Path, solid: tuple = ()) -> Image.Image:
    """The art without its paper: shadows become soft dark, edges keep their own colour."""
    im = Image.open(path)
    if im.mode == "RGBA" and im.getextrema()[3][0] < 255:
        return im
    a = np.asarray(im.convert("RGB")).astype(np.float64)
    low = a.min(axis=2)
    grey = a.max(axis=2) - low
    paper = (low >= PAPER_MIN) & (grey <= PAPER_GREY)
    paper = ndimage.binary_opening(paper, structure=np.ones((3, 3)))
    for x0, y0, x1, y1 in solid:
        paper[y0:y1, x0:x1] &= low[y0:y1, x0:x1] >= 240
    labels, count = ndimage.label(paper, structure=np.ones((3, 3)))
    ids = np.arange(count + 1)
    area = np.asarray(ndimage.sum(paper, labels, ids))
    lightest = np.asarray(ndimage.minimum(low, labels, ids))
    border = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
    is_paper = np.zeros(count + 1, bool)
    is_paper[border] = True
    is_paper[area >= PAPER_AREA] = True
    # Small holes of clean paper, such as the gaps between curls of hair.
    is_paper[(area >= 6) & (lightest >= PAPER_WHITE)] = True
    is_paper[0] = False
    background = is_paper[labels]
    edge = ndimage.binary_dilation(background, iterations=EDGE_PX) & ~background
    inside = ~(background | edge)
    # Each edge pixel is a mix of the nearest solid colour and white: how far along that line it sits is its alpha.
    _, nearest = ndimage.distance_transform_edt(~inside, return_indices=True)
    solid_colour = a[nearest[0], nearest[1]] - 255.0
    mix = ((a - 255.0) * solid_colour).sum(axis=2) / np.maximum((solid_colour ** 2).sum(axis=2), 1.0)
    # Paper and shadow take the least alpha that still makes the pixel over white.
    least = (255.0 - low) / 255.0
    alpha = np.ones(low.shape)
    alpha[edge] = np.maximum(np.clip(mix, 0, 1), least)[edge]
    alpha[background] = least[background]
    keep = np.maximum(alpha, 1e-3)[..., None]
    rgb = np.where((edge | background)[..., None], np.clip((a - (1 - keep) * 255.0) / keep, 0, 255), a)
    alpha[alpha < 0.02] = 0
    return Image.fromarray(np.dstack([rgb, alpha * 255]).round().astype(np.uint8), "RGBA")


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


def label() -> Image.Image:
    art = lift(SOURCE / "label_banner.png", solid=(NEEDLE_BOX,))
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
    return art.crop(art.getbbox())


def badge() -> Image.Image:
    art = lift(SOURCE / "sew_on_patch.png")
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
    readme = wordmark.resize((README_WIDTH, round(wordmark.height * README_WIDTH / wordmark.width)), Image.LANCZOS)
    readme.save(ROOT / ".github/logo.png", optimize=True)
    patch = badge()
    patch.save(ROOT / "assets/branding/badge.png", optimize=True)
    (ROOT / "build/logo").mkdir(parents=True, exist_ok=True)
    sheet([wordmark, patch]).save(ROOT / "build/logo/sheet.png")
    for path in (".github/logo.png", "assets/branding/badge.png", "build/logo/sheet.png"):
        print(ROOT / path)


if __name__ == "__main__":
    main()
