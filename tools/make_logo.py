#!/usr/bin/env python3
"""Draws Stitchfall's logo directions from the game's own fonts and runner art.

    python3 tools/make_logo.py            # every direction into build/logo/, with a contact sheet
    python3 tools/make_logo.py leap       # one direction, also written to .github/logo.png for the README

Each direction is a transparent PNG with a cream edge, so it reads on light and dark pages alike. The README's copy
lives in .github/, which Godot never imports, so the logo adds nothing to the game's builds.
"""

import math
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "build/logo"
WOVEN = ROOT / "assets/fonts/Threadline-Woven.ttf"
SATIN = ROOT / "assets/fonts/Threadline-Satin.ttf"
DARN = ROOT / "assets/fonts/Darn-Display.ttf"
DARN_UI = ROOT / "assets/fonts/Darn-UI.ttf"
ACTIONS = ROOT / "assets/art/seam_runner_actions.png"
FELT = ROOT / "assets/art/felt_tile.png"

INK = (73, 58, 55, 255)
PAPER = (247, 237, 218, 255)
RUST = (168, 86, 72, 255)
GOLD = (217, 164, 65, 255)
SAGE = (143, 164, 131, 255)
STEEL = (196, 200, 204, 255)
# The action sheet is a 4 by 3 grid of square cells.
CELL = 362


def text_image(text: str, font_path: Path, size: int, fill: tuple) -> Image.Image:
    font = ImageFont.truetype(str(font_path), size)
    box = font.getbbox(text)
    im = Image.new("RGBA", (box[2] - box[0] + 8, box[3] - box[1] + 8), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((4 - box[0], 4 - box[1]), text, font=font, fill=fill)
    return im


def runner(column: int, row: int, height: int) -> Image.Image:
    sheet = Image.open(ACTIONS).convert("RGBA")
    cell = sheet.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))
    cell = cell.crop(cell.getbbox())
    return cell.resize((int(cell.width * height / cell.height), height), Image.LANCZOS)


def shadow(im: Image.Image, offset: tuple = (6, 8), blur: int = 8, strength: float = 0.35) -> Image.Image:
    """The image over a soft drop shadow, on a canvas grown to hold both."""
    pad = blur * 3 + max(offset)
    out = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    alpha = im.split()[3].point(lambda v: int(v * strength))
    dark = Image.new("RGBA", im.size, (40, 28, 24, 0))
    dark.putalpha(alpha)
    out.alpha_composite(dark, (pad + offset[0], pad + offset[1]))
    out = out.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(im, (pad, pad))
    return out


def halo(im: Image.Image, width: int = 14, colour: tuple = PAPER) -> Image.Image:
    """The image on a cream sticker edge, so it reads on light and dark pages alike."""
    pad = width + 2
    grown = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2), (0, 0, 0, 0))
    grown.alpha_composite(im, (pad, pad))
    edge = grown.split()[3].point(lambda v: 255 if v > 40 else 0).filter(ImageFilter.MaxFilter(width * 2 + 1))
    out = Image.new("RGBA", grown.size, colour[:3] + (0,))
    out.putalpha(edge.filter(ImageFilter.GaussianBlur(1)))
    out.alpha_composite(grown)
    return out


def stitches(draw: ImageDraw.ImageDraw, points: list, colour: tuple, width: int, dash: int, gap: int) -> None:
    """A running stitch along a polyline: dashes of thread with gaps, the pattern carried across corners."""
    period = dash + gap
    travelled = 0.0
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        length = math.hypot(bx - ax, by - ay)
        if length == 0:
            continue
        t = 0.0
        while t < length:
            phase = (travelled + t) % period
            if phase < dash:
                end = min(length, t + dash - phase)
                draw.line([(ax + (bx - ax) * t / length, ay + (by - ay) * t / length),
                           (ax + (bx - ax) * end / length, ay + (by - ay) * end / length)], fill=colour, width=width)
            else:
                end = min(length, t + period - phase)
            t = end
        travelled += length


def arc_points(cx: float, cy: float, r: float, start: float, end: float, steps: int = 48) -> list:
    return [(cx + r * math.cos(start + (end - start) * i / steps), cy + r * math.sin(start + (end - start) * i / steps))
            for i in range(steps + 1)]


def button(size: int, colour: tuple = RUST) -> Image.Image:
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rim = tuple(int(c * 0.72) for c in colour[:3]) + (255,)
    d.ellipse((0, 0, size - 1, size - 1), fill=rim)
    d.ellipse((size * 0.08, size * 0.08, size * 0.92, size * 0.92), fill=colour)
    d.ellipse((size * 0.2, size * 0.2, size * 0.8, size * 0.8), outline=rim, width=max(2, size // 22))
    hole = size * 0.09
    for dx, dy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        x, y = size / 2 + dx * size * 0.13, size / 2 + dy * size * 0.13
        d.ellipse((x - hole, y - hole, x + hole, y + hole), fill=rim)
    return im


def needle(length: int, angle: float) -> Image.Image:
    """A sewing needle pointing along angle (degrees, 0 = right), eye at the tail."""
    w = max(10, length // 14)
    im = Image.new("RGBA", (length + 4, w * 2 + 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cy = w + 2
    d.polygon([(2, cy - w * 0.5), (length * 0.82, cy - w * 0.42), (length + 2, cy), (length * 0.82, cy + w * 0.42),
               (2, cy + w * 0.5)], fill=STEEL)
    d.line([(4, cy - w * 0.22), (length * 0.8, cy - w * 0.18)], fill=(240, 242, 244, 255), width=max(2, w // 4))
    d.ellipse((w * 0.6, cy - w * 0.22, w * 2.2, cy + w * 0.22), fill=(0, 0, 0, 0))
    eye = Image.new("L", im.size, 255)
    ImageDraw.Draw(eye).ellipse((w * 0.6, cy - w * 0.2, w * 2.2, cy + w * 0.2), fill=0)
    im.putalpha(ImageChops.multiply(im.split()[3], eye))
    return im.rotate(angle, resample=Image.BICUBIC, expand=True)


def felt(size: tuple, tint: tuple, mix: float = 0.55) -> Image.Image:
    tile = Image.open(FELT).convert("RGB")
    out = Image.new("RGB", size)
    for x in range(0, size[0], tile.width):
        for y in range(0, size[1], tile.height):
            out.paste(tile, (x, y))
    return Image.blend(out, Image.new("RGB", size, tint[:3]), mix).convert("RGBA")


def crop(im: Image.Image, margin: int = 24) -> Image.Image:
    box = im.getbbox()
    return im.crop((max(0, box[0] - margin), max(0, box[1] - margin), min(im.width, box[2] + margin),
                    min(im.height, box[3] + margin)))


# 1. The turning seam: STITCH runs along a thread that turns a quarter turn, and FALL drops down it.
def seam() -> Image.Image:
    canvas = Image.new("RGBA", (2000, 1500), (0, 0, 0, 0))
    word = halo(text_image("STITCH", WOVEN, 260, INK))
    fall = halo(text_image("FALL", WOVEN, 260, RUST)).rotate(-90, expand=True)
    x0, y0 = 60, 120
    canvas.alpha_composite(word, (x0, y0))
    corner_x = x0 + word.width + 70
    line_y = y0 + word.height + 30
    fall_top = line_y + 90
    canvas.alpha_composite(fall, (corner_x + 40, fall_top))
    thread = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    td = ImageDraw.Draw(thread)
    path = ([(x0 + 30, line_y), (corner_x - 70, line_y)] + arc_points(corner_x - 70, line_y + 70, 70, -math.pi / 2, 0)[1:]
            + [(corner_x, fall_top + fall.height - 40)])
    stitches(td, path, RUST, 13, 36, 20)
    canvas.alpha_composite(halo(thread.crop(thread.getbbox()), 8), (x0 + 22, line_y - 15))
    canvas.alpha_composite(halo(button(120), 8), (corner_x - 78, line_y - 70))
    n = halo(needle(260, -90), 8)
    canvas.alpha_composite(n, (corner_x - n.width // 2 + 2, fall_top + fall.height - 60))
    hero = shadow(runner(0, 2, 330).rotate(-96, resample=Image.BICUBIC, expand=True))
    canvas.alpha_composite(hero, (x0 + word.width // 2 - hero.width // 2 + 60, line_y + 120))
    return crop(canvas)


# 2. The leap: the word in satin stitch with the runner leaping across it and a needle sewing the line beneath.
def leap() -> Image.Image:
    canvas = Image.new("RGBA", (2200, 1200), (0, 0, 0, 0))
    word = halo(text_image("STITCHFALL", WOVEN, 230, INK))
    x0, y0 = 60, 560
    hero = shadow(runner(3, 1, 560).rotate(10, resample=Image.BICUBIC, expand=True))
    canvas.alpha_composite(hero, (x0 + int(word.width * 0.46), y0 - 520))
    canvas.alpha_composite(word, (x0, y0))
    thread = Image.new("RGBA", (word.width, 60), (0, 0, 0, 0))
    stitches(ImageDraw.Draw(thread), [(20, 30), (word.width - 150, 30)], RUST, 13, 38, 22)
    canvas.alpha_composite(halo(thread.crop(thread.getbbox()), 8), (x0 + 10, y0 + word.height + 10))
    n = halo(needle(240, 0), 8)
    canvas.alpha_composite(n, (x0 + word.width - 160, y0 + word.height + 20 - n.height // 2 + 6))
    return crop(canvas)


# 3. The patch: a round sew-on patch with a satin border, the name arched over the leaping runner.
def patch() -> Image.Image:
    size = 1200
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((40, 40, size - 40, size - 40), fill=255)
    disc = felt((size, size), SAGE)
    disc.putalpha(mask)
    canvas.alpha_composite(shadow(disc, (8, 12), 12, 0.3).crop((0, 0, size + 200, size + 200)), (-50, -50))
    d = ImageDraw.Draw(canvas)
    c = size / 2
    for i in range(240):
        a = i / 240 * math.tau
        d.line([(c + (c - 44) * math.cos(a), c + (c - 44) * math.sin(a)),
                (c + (c - 100) * math.cos(a + 0.02), c + (c - 100) * math.sin(a + 0.02))], fill=RUST, width=11)
    stitches(d, arc_points(c, c, c - 135, 0, math.tau, 180), PAPER, 7, 22, 16)
    size_px = 110
    font = ImageFont.truetype(str(WOVEN), size_px)
    text = "STITCHFALL"
    radius = c - 205
    widths = [font.getbbox(ch)[2] - font.getbbox(ch)[0] + 18 for ch in text]
    span = sum(widths) / radius
    a = -math.pi / 2 - span / 2
    for ch, w in zip(text, widths):
        mid = a + w / 2 / radius
        glyph = text_image(ch, WOVEN, size_px, PAPER).rotate(-math.degrees(mid) - 90, resample=Image.BICUBIC, expand=True)
        canvas.alpha_composite(glyph, (int(c + radius * math.cos(mid) - glyph.width / 2),
                                       int(c + radius * math.sin(mid) - glyph.height / 2)))
        a += w / radius
    hero = shadow(runner(3, 1, 600).rotate(6, resample=Image.BICUBIC, expand=True))
    canvas.alpha_composite(hero, (int(c - hero.width / 2 + 20), int(c - hero.height / 2 + 120)))
    return crop(canvas, 6)


# 4. The turned room: an app-style tile, a stitched room turned on its side with the runner falling through it.
def room() -> Image.Image:
    size = 1100
    tile = felt((size, size), SAGE, 0.5)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=220, fill=255)
    tile.putalpha(mask)
    d = ImageDraw.Draw(tile)
    frame = Image.new("RGBA", (680, 680), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((20, 20, 660, 660), radius=60, fill=(247, 237, 218, 235), outline=INK, width=16)
    stitches(fd, [(70, 70), (610, 70), (610, 610), (70, 610), (70, 70)], RUST, 9, 26, 16)
    zip_box = (500, 470, 590, 600)
    fd.rounded_rectangle(zip_box, radius=14, fill=(84, 140, 130, 255), outline=INK, width=8)
    frame = frame.rotate(-14, resample=Image.BICUBIC, expand=True)
    tile.alpha_composite(shadow(frame, (8, 10), 10, 0.3), (int(size / 2 - frame.width / 2 - 40), int(size / 2 - frame.height / 2 - 40)))
    hero = shadow(runner(0, 2, 470).rotate(-80, resample=Image.BICUBIC, expand=True))
    tile.alpha_composite(hero, (int(size / 2 - hero.width / 2 + 10), int(size / 2 - hero.height / 2 - 10)))
    stitches(d, arc_points(size / 2, size / 2, 470, -math.pi * 0.95, -math.pi * 0.55, 40), PAPER, 14, 30, 18)
    tip = arc_points(size / 2, size / 2, 470, -math.pi * 0.55, -math.pi * 0.55, 1)[0]
    d.polygon([(tip[0] + 10, tip[1] - 38), (tip[0] + 58, tip[1] + 4), (tip[0] - 6, tip[1] + 28)], fill=PAPER)
    return tile


# 5. The monogram: a satin-stitched S with a needle through its top curl and the thread ending in a button.
def monogram() -> Image.Image:
    canvas = Image.new("RGBA", (1100, 1200), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    s = text_image("S", WOVEN, 900, RUST)
    canvas.alpha_composite(shadow(s, (6, 10), 10, 0.3), (130, 60))
    n = needle(520, 32)
    canvas.alpha_composite(n, (520, 70))
    stitches(d, [(560, 330)] + arc_points(740, 900, 230, -math.pi * 0.6, math.pi * 0.25, 30), INK, 10, 26, 16)
    b = button(140, GOLD)
    canvas.alpha_composite(b, (870, 1000))
    return crop(canvas)


# 6. The label: the name woven on a sewn clothing label, with the runner leaping off its corner.
def label() -> Image.Image:
    canvas = Image.new("RGBA", (2100, 1000), (0, 0, 0, 0))
    word = text_image("STITCHFALL", WOVEN, 200, PAPER)
    w, h = word.width + 220, word.height + 200
    tag = felt((w, h), RUST, 0.62)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=46, fill=255)
    tag.putalpha(mask)
    td = ImageDraw.Draw(tag)
    stitches(td, [(34, 34), (w - 34, 34), (w - 34, h - 34), (34, h - 34), (34, 34)], PAPER, 9, 28, 16)
    tag.alpha_composite(word, ((w - word.width) // 2, (h - word.height) // 2 + 6))
    x0, y0 = 60, 330
    canvas.alpha_composite(shadow(tag, (8, 12), 12, 0.35), (x0 - 40, y0 - 40))
    hero = shadow(runner(3, 1, 430).rotate(12, resample=Image.BICUBIC, expand=True))
    canvas.alpha_composite(hero, (x0 + w - hero.width // 2 - 120, y0 - 330))
    return crop(canvas)


DIRECTIONS = {
    "seam": ("The turning seam", seam),
    "leap": ("The leap", leap),
    "patch": ("The patch", patch),
    "room": ("The turned room", room),
    "monogram": ("The monogram", monogram),
    "label": ("The label", label),
}


def sheet(images: dict) -> Image.Image:
    """Each direction on light and on dark, with its name, to choose by eye."""
    cell_w, cell_h = 820, 560
    out = Image.new("RGB", (cell_w * 2, cell_h * len(images) + 20), (255, 255, 255))
    label = ImageFont.truetype(str(DARN_UI), 34)
    for row, (key, im) in enumerate(images.items()):
        for col, bg in enumerate([(247, 237, 218), (52, 44, 50)]):
            panel = Image.new("RGBA", (cell_w - 20, cell_h - 20), bg + (255,))
            fit = im.copy()
            fit.thumbnail((cell_w - 80, cell_h - 110), Image.LANCZOS)
            panel.alpha_composite(fit, ((panel.width - fit.width) // 2, 70 + (panel.height - 70 - fit.height) // 2))
            ImageDraw.Draw(panel).text((20, 14), f"{row + 1}. {DIRECTIONS[key][0]}", font=label,
                                       fill=(73, 58, 55) if col == 0 else (247, 237, 218))
            out.paste(panel.convert("RGB"), (col * cell_w + 10, row * cell_h + 10))
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    chosen = [arg for arg in sys.argv[1:] if arg in DIRECTIONS]
    keys = chosen or list(DIRECTIONS)
    images = {}
    for key in keys:
        images[key] = DIRECTIONS[key][1]()
        images[key].save(OUT / f"{key}.png")
        print("drew", key, images[key].size)
    if chosen:
        logo = images[chosen[0]].copy()
        logo.thumbnail((1400, 1400), Image.LANCZOS)
        target = ROOT / ".github/logo.png"
        logo.save(target, optimize=True)
        print("wrote", target.relative_to(ROOT), logo.size, f"{target.stat().st_size // 1024} KB")
    else:
        sheet(images).save(OUT / "sheet.png")
        print("wrote", (OUT / "sheet.png").relative_to(ROOT))


if __name__ == "__main__":
    main()
