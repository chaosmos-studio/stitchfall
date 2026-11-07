#!/usr/bin/env python3
"""Makes Stitchfall's Google Play graphics from the real game.

    python3 tools/store_art.py            # capture every shot, then compose
    python3 tools/store_art.py 08_home    # capture only the shots named, then compose
    python3 tools/store_art.py --compose  # compose from the captures already made

Each screenshot is captured at the game's full 1920 by 1080 through tools/gallery.gd (its hd mode), then sewn
onto linen with a stitched border and a caption above it. Play takes 16:9 shots for phones and tablets alike, so
one set serves the phone, 7-inch and 10-inch slots. The feature graphic is the woodland the Home screen opens on,
with the runner and the name on a linen patch. Everything lands in assets/store/, which Godot ignores.

Play's rules for graphics: no device frames, and no ranking, price or promotion words in a caption.
"""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/store"
GALLERY = Path.home() / ".local/share/godot/app_userdata/Stitchfall/gallery"
DISPLAY_FONT = ROOT / "assets/fonts/Darn-Display.ttf"
BODY_FONT = ROOT / "assets/fonts/Darn-UI.ttf"
INK = (73, 58, 55)
MUTED = (122, 96, 84)
CREAM = (247, 239, 220)
THREAD = (180, 93, 76)
SIZE = (1920, 1080)
# The shot sits under the caption band, with this much linen around it.
SHOT_WIDTH = 1500
SHOT_BOTTOM = 36
CAPTION_TOP = 26
HEADLINE_SIZE = 72
SUBLINE_SIZE = 36
SUBLINE_GAP = 88

# Each shot is a room's own proving route cut off at the frame worth showing.
ROUTES = {
    "canopy/2": "0:+move_right,52:+jump,60:-move_right,90:-jump,110:shift,125:shift,126:+move_right,203:+jump,223:-jump",
    "frost/5": "0:shift,15:shift,40:+move_right,84:+jump,99:-jump,179:+jump,194:-jump,300:-move_right,301:+move_left,"
               "376:+jump,390:-jump,422:shift,437:shift,446:-move_left,476:+move_left,476:shift",
    "night/1": "0:+move_right,22:+jump,60:-jump",
    "water/1": "0:+move_right,62:+jump,86:-jump,150:+jump,174:-jump,248:+jump,272:-jump",
    "dunes/1": "0:+move_right,48:+jump",
}

# name, room, gallery steps, headline, subline. The rooms are chapter rooms, so they survive reordering. The
# first three are the ones Play shows in search, so they carry the pitch. 0:play shows the Google Play build's pages.
SHOTS = [
    ("01_turn", "canopy/2", ROUTES["canopy/2"] + ",170:shot",
     "Turn the whole room over.", "A quarter turn at a time, and the ceiling is your floor"),
    ("02_trick", "frost/5", ROUTES["frost/5"] + ",480:shot",
     "Every room plays a trick.", "Reach the zipper and it runs off across the ice"),
    ("03_night", "night/1", ROUTES["night/1"] + ",90:shot",
     "Float through the night.", "On the night quilt every jump drifts long and slow"),
    ("04_water", "water/1", ROUTES["water/1"] + ",165:shot",
     "Jump higher from the water.", "Water slows every fall and lifts every jump"),
    ("05_wind", "dunes/1", ROUTES["dunes/1"] + ",60:shot",
     "Let the wind carry you.", "In the dunes every jump drifts the same way"),
    ("06_stars", "water/1", ROUTES["water/1"] + ",500:shot",
     "Earn three stars a room.", "Sew it, sew it unbroken, sew it quick"),
    ("07_wardrobe", "linen/1", "0:play,1:wear=runner/seam,2:wear=trail/trail_rainbow,3:hud=show_wardrobe,4:hud=_show_kind/trail,60:shot",
     "Dress your runner.", "Stars open trails, unravels and buttons"),
    ("08_home", "linen/1", "0:play,1:wear=runner/seam,2:hud=show_home,44:shot",
     "A world sewn from cloth.", "Textile art and music made for this game"),
]
# The feature graphic, in its own 1024 by 500 pixels: the woodland's stitched pocket (left, top, right, bottom)
# that holds the name, and where the runner stands on the meadow path.
POCKET = (40, 30, 480, 460)
POCKET_PADDING = 34
FEATURE_LINE_GAP = 40
FEATURE_RUNNER_HEIGHT = 400
FEATURE_RUNNER_X = 690
FEATURE_RUNNER_FEET = 40
BANNED = re.compile(r"\b(best|#1|top|new|free|sale|discount|download|play now|try now|install)\b", re.I)


def capture(only: list[str]) -> None:
    for name, room, steps, _, _ in SHOTS:
        if only and name not in only:
            continue
        command = ["flock", "/tmp/godot.lock", "systemd-run", "--user", "--scope", "-q", "-p", "MemoryMax=3G", "--",
                   "timeout", "120", "godot", "--path", str(ROOT), "--fixed-fps", "60", "res://tools/gallery.tscn",
                   "--", f"store_{name}", room, steps, "hd"]
        result = subprocess.run(command, env={**os.environ, "DISPLAY": ":0"}, capture_output=True, text=True)
        if "GALLERY_SAVED" not in result.stdout:
            sys.exit(f"capture {name} failed:\n{result.stdout[-2000:]}\n{result.stderr[-2000:]}")
        print("captured", name)


def linen(size: tuple[int, int]) -> Image.Image:
    cloth = Image.open(ROOT / "assets/art/linen_landscape.png").convert("RGB")
    scale = max(size[0] / cloth.width, size[1] / cloth.height)
    cloth = cloth.resize((int(cloth.width * scale) + 1, int(cloth.height * scale) + 1), Image.LANCZOS)
    cloth = cloth.crop((0, 0, size[0], size[1]))
    return Image.blend(cloth, Image.new("RGB", size, CREAM), 0.35)


def stitches(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], colour: tuple[int, int, int], pitch: int = 26,
             width: int = 5) -> None:
    x0, y0, x1, y1 = box
    for (ax, ay), (bx, by) in [((x0, y0), (x1, y0)), ((x1, y0), (x1, y1)), ((x1, y1), (x0, y1)), ((x0, y1), (x0, y0))]:
        length = max(abs(bx - ax), abs(by - ay))
        for k in range(0, length, pitch):
            t0, t1 = k / length, min(k + pitch * 0.55, length) / length
            draw.line([(ax + (bx - ax) * t0, ay + (by - ay) * t0), (ax + (bx - ax) * t1, ay + (by - ay) * t1)],
                      fill=colour, width=width)


def screenshot(name: str, headline: str, subline: str) -> Image.Image:
    for line in (headline, subline):
        if BANNED.search(line):
            sys.exit(f"{name}: Play forbids promotional words in graphics: {line!r}")
    canvas = linen(SIZE)
    draw = ImageDraw.Draw(canvas)
    title = ImageFont.truetype(str(DISPLAY_FONT), HEADLINE_SIZE)
    body = ImageFont.truetype(str(BODY_FONT), SUBLINE_SIZE)
    draw.text((SIZE[0] // 2, CAPTION_TOP), headline, font=title, fill=INK, anchor="mt")
    draw.text((SIZE[0] // 2, CAPTION_TOP + SUBLINE_GAP), subline, font=body, fill=MUTED, anchor="mt")
    caption_bottom = draw.textbbox((SIZE[0] // 2, CAPTION_TOP + SUBLINE_GAP), subline, font=body, anchor="mt")[3]
    shot = Image.open(GALLERY / f"store_{name}.png").convert("RGB")
    shot = shot.resize((SHOT_WIDTH, SHOT_WIDTH * shot.height // shot.width), Image.LANCZOS)
    x = (SIZE[0] - shot.width) // 2
    y = SIZE[1] - shot.height - SHOT_BOTTOM
    # The cream border reaches 18 above the shot, and the caption must clear it.
    if caption_bottom > y - 18 - 12:
        sys.exit(f"{name}: the caption runs into the shot ({caption_bottom} against {y - 18})")
    shadow = Image.new("L", SIZE, 0)
    ImageDraw.Draw(shadow).rectangle([x - 6, y + 4, x + shot.width + 14, y + shot.height + 18], fill=120)
    canvas.paste(Image.new("RGB", SIZE, (60, 45, 38)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(14)))
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([x - 18, y - 18, x + shot.width + 18, y + shot.height + 18], fill=CREAM)
    canvas.paste(shot, (x, y))
    stitches(draw, (x - 10, y - 10, x + shot.width + 10, y + shot.height + 10), THREAD)
    return canvas


def feature() -> Image.Image:
    size = (1024, 500)
    wood = Image.open(ROOT / "assets/art/home_woodland.webp").convert("RGB")
    scale = size[0] / wood.width
    wood = wood.resize((size[0], int(wood.height * scale)), Image.LANCZOS)
    canvas = wood.crop((0, (wood.height - size[1]) // 2, size[0], (wood.height - size[1]) // 2 + size[1]))
    runner = Image.open(ROOT / "assets/art/hero_pose_3.png").convert("RGBA")
    runner = runner.crop(runner.getbbox())
    runner = runner.resize((int(runner.width * FEATURE_RUNNER_HEIGHT / runner.height), FEATURE_RUNNER_HEIGHT), Image.LANCZOS)
    runner_at = (FEATURE_RUNNER_X - runner.width // 2, size[1] - FEATURE_RUNNER_FEET - runner.height)
    shadow = Image.new("RGBA", runner.size, (40, 30, 20, 0))
    shadow.putalpha(runner.split()[3].filter(ImageFilter.GaussianBlur(10)).point(lambda v: int(v * 0.45)))
    canvas.paste(shadow, (runner_at[0] + 10, runner_at[1] + 12), shadow)
    canvas.paste(runner, runner_at, runner)
    # The name and line sit in the woodland's own stitched pocket, the one the Home menu sits in.
    draw = ImageDraw.Draw(canvas)
    centre = (POCKET[0] + POCKET[2]) // 2
    name_font = fit_font(DISPLAY_FONT, "STITCHFALL", POCKET[2] - POCKET[0] - 2 * POCKET_PADDING, 96)
    name_box = draw.textbbox((centre, 0), "STITCHFALL", font=name_font, anchor="mt")
    line = "Turn the room. Sew your way out."
    line_font = fit_font(BODY_FONT, line, POCKET[2] - POCKET[0] - 2 * POCKET_PADDING, 30)
    line_box = draw.textbbox((centre, 0), line, font=line_font, anchor="mt")
    block = (name_box[3] - name_box[1]) + FEATURE_LINE_GAP + (line_box[3] - line_box[1])
    top = (POCKET[1] + POCKET[3] - block) // 2
    draw.text((centre, top - name_box[1]), "STITCHFALL", font=name_font, fill=INK, anchor="mt")
    rule_y = top + (name_box[3] - name_box[1]) + FEATURE_LINE_GAP // 2
    half = (line_box[2] - line_box[0]) // 2
    for k in range(centre - half, centre + half, 18):
        draw.line([(k, rule_y), (k + 10, rule_y)], fill=THREAD, width=3)
    draw.text((centre, top + (name_box[3] - name_box[1]) + FEATURE_LINE_GAP - line_box[1]), line, font=line_font,
              fill=MUTED, anchor="mt")
    return canvas


def fit_font(path: Path, text: str, width: int, largest: int) -> ImageFont.FreeTypeFont:
    size = largest
    while size > 12:
        font = ImageFont.truetype(str(path), size)
        box = font.getbbox(text)
        if box[2] - box[0] <= width:
            return font
        size -= 2
    return ImageFont.truetype(str(path), size)


def main() -> None:
    if "--compose" not in sys.argv:
        capture([arg for arg in sys.argv[1:] if not arg.startswith("--")])
    phone = OUT / "screenshots/phone"
    for folder in (phone, OUT / "screenshots/tablet7", OUT / "screenshots/tablet10"):
        shutil.rmtree(folder, ignore_errors=True)
        folder.mkdir(parents=True)
    for name, _, _, headline, subline in SHOTS:
        image = screenshot(name, headline, subline)
        for folder in ("phone", "tablet7", "tablet10"):
            image.save(OUT / f"screenshots/{folder}/{name}.png")
        print("composed", name)
    feature().save(OUT / "feature_graphic_1024x500.png")
    print("composed feature graphic")


if __name__ == "__main__":
    main()
