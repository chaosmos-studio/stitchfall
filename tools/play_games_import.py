#!/usr/bin/env python3
"""Writes what Play Console's imports take for Stitchfall's Play Games project, from play_games/catalog.json, with
every icon drawn at 512 px in Stitchfall's own colours (the ink, paper and accent of scripts/hud.gd and the star
gold of scripts/star_row.gd), each glyph ringed by a running stitch. Stitchfall's copy of the kit's
kit/tools/play_games_import.py:

- build/play_games/achievements.zip: Achievements, Import achievements, then Save as draft. An achievement with
  a goal past one is incremental, with its goal as the steps, so Play Games shows how far along it is.
- leaderboard_<key>.png: an icon for each leaderboard, since leaderboards have no import and are made by hand.
- PlayerGameEvent.csv: Game Stats, Add an event, Import via CSV.
- game_stats.zip: Game Stats, Add a stat, Import via ZIP, after the events.

Run from the game's folder: python3 tools/play_games_import.py

The achievement CSVs have no header row and no commas in a name or description, as that import requires. The
Game Stats CSVs have a header row. Play Games shows an achievement's icon inside a circle and greys the locked
one by itself, so each is one bold glyph on a full-bleed fill. A stat's icon sits on a transparent ground.
"""

import csv
import io
import json
import math
import re
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

CATALOG = Path("play_games/catalog.json")
OUT = Path("build/play_games")
SIZE = 512
SCALE = 4
# The game's reading face: solid strokes stay legible at Play Games' small icon sizes, where Darn Display's
# stitched fill turns to stripes.
FONT = Path("assets/fonts/Darn-UI.ttf")
# The measures an achievement counts, as StitchfallPlayGames.MEASURES names them.
MEASURES = ("sewn", "chapters", "three", "seamless", "quick", "banked", "turns", "unravels")


def palette() -> dict:
    """Stitchfall's colours, read from the scripts that draw the game, as hex strings."""
    hud = Path("scripts/hud.gd").read_text()
    stars = Path("scripts/star_row.gd").read_text()

    def colour(text: str, name: str) -> str:
        return "#" + re.search(r'const %s: Color = Color\("([0-9a-fA-F]{6})"\)' % name, text).group(1)
    return {"ink": colour(hud, "INK"), "paper": colour(hud, "PAPER"), "accent": colour(hud, "ACCENT"),
            "gold": colour(stars, "GOLD")}


def stitch_ring(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str, width: float) -> None:
    """A running stitch around a circle: short dashes with gaps, as the game's borders are sewn."""
    count = 28
    for k in range(count):
        a0 = k * math.tau / count
        a1 = a0 + math.tau / count * 0.55
        points = [(cx + math.cos(a0 + (a1 - a0) * t / 6) * r, cy + math.sin(a0 + (a1 - a0) * t / 6) * r)
                  for t in range(7)]
        draw.line(points, fill=fill, width=int(width), joint="curve")
        for x, y in (points[0], points[-1]):
            draw.ellipse((x - width / 2, y - width / 2, x + width / 2, y + width / 2), fill=fill)


def star(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str) -> None:
    points = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        rr = r if k % 2 == 0 else r * 0.45
        points.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    draw.polygon(points, fill=fill)


def patch(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str, hole: str) -> None:
    """A square cloth patch with a running stitch inside its edge: a chapter."""
    draw.rounded_rectangle((cx - r, cy - r, cx + r, cy + r), radius=r * 0.16, fill=fill)
    inset = r * 0.8
    dash = r * 0.16
    w = int(r * 0.07)
    for side in range(4):
        steps = 5
        for k in range(steps):
            t0 = -inset + (k + 0.25) * 2 * inset / steps
            t1 = t0 + dash
            if side == 0:
                draw.line([(cx + t0, cy - inset), (cx + t1, cy - inset)], fill=hole, width=w)
            elif side == 1:
                draw.line([(cx + t0, cy + inset), (cx + t1, cy + inset)], fill=hole, width=w)
            elif side == 2:
                draw.line([(cx - inset, cy + t0), (cx - inset, cy + t1)], fill=hole, width=w)
            else:
                draw.line([(cx + inset, cy + t0), (cx + inset, cy + t1)], fill=hole, width=w)


def spool(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str, hole: str) -> None:
    """A spool of thread, wound without a break: Seamless."""
    draw.rounded_rectangle((cx - r * 0.72, cy - r, cx + r * 0.72, cy - r * 0.72), radius=r * 0.08, fill=fill)
    draw.rounded_rectangle((cx - r * 0.72, cy + r * 0.72, cx + r * 0.72, cy + r), radius=r * 0.08, fill=fill)
    draw.rectangle((cx - r * 0.5, cy - r * 0.72, cx + r * 0.5, cy + r * 0.72), fill=fill)
    w = int(r * 0.06)
    for k in range(6):
        y = cy - r * 0.6 + k * r * 0.24
        draw.line([(cx - r * 0.5, y + r * 0.06), (cx + r * 0.5, y - r * 0.06)], fill=hole, width=w)


def stopwatch(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str) -> None:
    w = int(r * 0.17)
    draw.ellipse((cx - r, cy - r * 0.86, cx + r, cy + r * 1.14), outline=fill, width=w)
    draw.rounded_rectangle((cx - r * 0.22, cy - r * 1.28, cx + r * 0.22, cy - r * 1.04), radius=r * 0.06, fill=fill)
    draw.line([(cx, cy - r * 1.04), (cx, cy - r * 0.86)], fill=fill, width=int(w * 0.8))
    draw.line([(cx, cy + r * 0.14), (cx + r * 0.42, cy - r * 0.32)], fill=fill, width=int(w * 0.9))
    draw.ellipse((cx - r * 0.13, cy + r * 0.01, cx + r * 0.13, cy + r * 0.27), fill=fill)


def flower(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str, hole: str, centre: str) -> None:
    """A flower with a button at its heart: buttons banked."""
    for k in range(5):
        a = -math.pi / 2 + k * math.tau / 5
        px, py = cx + math.cos(a) * r * 0.55, cy + math.sin(a) * r * 0.55
        draw.ellipse((px - r * 0.45, py - r * 0.45, px + r * 0.45, py + r * 0.45), fill=fill)
    draw.ellipse((cx - r * 0.42, cy - r * 0.42, cx + r * 0.42, cy + r * 0.42), fill=centre)
    for dx, dy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        x, y = cx + dx * r * 0.13, cy + dy * r * 0.13
        draw.ellipse((x - r * 0.07, y - r * 0.07, x + r * 0.07, y + r * 0.07), fill=hole)


def turn(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str) -> None:
    """The room turned a quarter: an arc with its arrowhead, as the game's shift icon."""
    w = int(r * 0.2)
    draw.arc((cx - r, cy - r, cx + r, cy + r), start=-150, end=150, fill=fill, width=w)
    a = math.radians(150)
    tip = (cx + math.cos(a) * r, cy + math.sin(a) * r)
    draw.polygon([(tip[0] - r * 0.42, tip[1] - r * 0.02), (tip[0] + r * 0.3, tip[1] - r * 0.3),
                  (tip[0] + r * 0.12, tip[1] + r * 0.42)], fill=fill)


def yarn(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str, hole: str) -> None:
    """A ball of yarn with its end coming loose: unravels."""
    bx, by, br = cx - r * 0.2, cy - r * 0.1, r * 0.78
    draw.ellipse((bx - br, by - br, bx + br, by + br), fill=fill)
    w = int(r * 0.07)
    for k in range(3):
        off = (k - 1) * br * 0.42
        draw.arc((bx - br * 1.6 + off, by - br * 0.9, bx + br * 0.4 + off, by + br * 1.1), start=-60, end=40,
                 fill=hole, width=w)
    tail = [(bx + br * 0.62, by + br * 0.55)]
    for k in range(1, 13):
        t = k / 12
        tail.append((bx + br * 0.62 + t * r * 0.75, by + br * 0.55 + t * r * 0.45 + math.sin(t * math.tau) * r * 0.12))
    draw.line(tail, fill=fill, width=int(r * 0.11), joint="curve")


def zipper(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str, hole: str) -> None:
    """The zipper every room ends at, closed: a room sewn. Its teeth interlock down a band, under the slider and
    its pull."""
    band = r * 0.62
    draw.rounded_rectangle((cx - band / 2, cy - r, cx + band / 2, cy + r * 0.55), radius=band * 0.2, fill=fill)
    gap = int(r * 0.07)
    tooth = r * 0.22
    for k in range(6):
        y = cy - r + tooth * 0.5 + k * tooth
        draw.line([(cx, y), (cx + (band / 2 if k % 2 == 0 else -band / 2), y)], fill=hole, width=gap)
    draw.line([(cx, cy - r), (cx, cy + r * 0.55)], fill=hole, width=gap)
    draw.rounded_rectangle((cx - r * 0.44, cy + r * 0.38, cx + r * 0.44, cy + r * 0.78), radius=r * 0.14, fill=fill)
    draw.rounded_rectangle((cx - r * 0.2, cy + r * 0.7, cx + r * 0.2, cy + r * 1.3), radius=r * 0.12, fill=fill)
    draw.ellipse((cx - r * 0.08, cy + r * 1.02, cx + r * 0.08, cy + r * 1.18), fill=hole)


def steps(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill: str) -> None:
    """Rising patches: different rooms sewn."""
    for k in range(3):
        x = cx - r * 0.9 + k * r * 0.64
        top = cy + r * 0.7 - (k + 1) * r * 0.5
        draw.rounded_rectangle((x, top, x + r * 0.5, cy + r * 0.7), radius=r * 0.08, fill=fill)


def three_stars(draw: ImageDraw.ImageDraw, c: float, y: float, s: float, gold: str) -> None:
    for k, dx in enumerate((-0.2, 0.0, 0.2)):
        star(draw, c + dx * s, y - (0.045 * s if k == 1 else 0), s * 0.105, gold)


def stat_icon(key: str, colours: dict) -> Image.Image:
    """A Game Stats icon: one glyph on a stitched disc in the accent, on a transparent ground."""
    s = SIZE * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    ink, fill, gold = colours["paper"], colours["accent"], colours["gold"]
    c = s / 2
    draw.ellipse((s * 0.04, s * 0.04, s * 0.96, s * 0.96), fill=fill)
    stitch_ring(draw, c, c, s * 0.39, ink, s * 0.012)
    if key == "rooms_sewn":
        zipper(draw, c, c - s * 0.04, s * 0.24, ink, fill)
    elif key == "stars_collected":
        star(draw, c, c + s * 0.02, s * 0.25, gold)
    elif key == "three_star_rooms":
        three_stars(draw, c, c + s * 0.02, s, gold)
    elif key == "unravels":
        yarn(draw, c, c, s * 0.24, ink, fill)
    elif key == "time_in_rooms":
        stopwatch(draw, c, c, s * 0.2, ink)
    elif key == "different_rooms":
        steps(draw, c, c, s * 0.27, ink)
    else:
        raise SystemExit(f"{key}: no stat icon is drawn for it")
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def write_game_stats(catalog: dict, colours: dict) -> None:
    events = io.StringIO()
    out = csv.writer(events, lineterminator="\n")
    out.writerow(["Event Name", "Property Name", "Property Type"])
    for event, props in catalog["events"].items():
        for prop, kind in props.items():
            out.writerow([event, prop, kind])
    (OUT / "PlayerGameEvent.csv").write_text(events.getvalue())

    repetitive = io.StringIO()
    out = csv.writer(repetitive, lineterminator="\n")
    # Format is not in Google's documented header, but the import asks for it on a DURATION stat: UNIT_BASED,
    # COMPONENT_NUMERIC or COMPONENT_TEXT, whose Unit is then the smallest part shown (MINUTES gives "3h 25m").
    out.writerow(["Stat Id", "Event Name", "Event Property Name", "Aggregation Type", "Stat Display Name",
                  "Stat Description", "Filter Property", "Filter Operator", "Filter Value", "Is Competitive",
                  "Min limit", "Max limit", "Icon File Name", "Good value direction", "Unit", "Format"])
    files = {}
    for s in catalog["stats"]:
        f = s.get("filter", ["", "", ""])
        lo, hi = s.get("competitive", ["", ""])
        png = f"stat_{s['key']}.png"
        out.writerow([s["key"], s["event"], s["property"], s["aggregation"], s["name"], s["text"], f[0], f[1], f[2],
                      "true" if "competitive" in s else "false", lo, hi, png, "INCREASING", s.get("unit", ""),
                      s.get("format", "")])
        files[png] = stat_icon(s["key"], colours)
    p = catalog["progression"]
    progression = io.StringIO()
    out = csv.writer(progression, lineterminator="\n")
    out.writerow(["Stat Id", "Event Property Name", "Stat Display Name", "Stat Description", "Icon File Name",
                  "Good value direction", "Unit"])
    png = f"stat_{p['key']}.png"
    out.writerow([p["key"], p["property"], p["name"], p["text"], png, "INCREASING", p.get("unit", "")])
    files[png] = stat_icon(p["key"], colours)
    with zipfile.ZipFile(OUT / "game_stats.zip", "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("RepetitiveStatsConfig.csv", repetitive.getvalue())
        z.writestr("ProgressionStatConfig.csv", progression.getvalue())
        for png, image in files.items():
            buffer = io.BytesIO()
            image.save(buffer, "PNG")
            image.save(OUT / png)
            z.writestr(png, buffer.getvalue())
    print(f"wrote {OUT / 'PlayerGameEvent.csv'} and {OUT / 'game_stats.zip'}: {len(files)} stats")


def goal(entry: dict) -> int:
    """StitchfallPlayGames.goal: an achievement's threshold, and so its steps."""
    for measure in MEASURES:
        if measure in entry:
            return int(entry[measure])
    return 1


def icon(entry: dict, colours: dict) -> Image.Image:
    s = SIZE * SCALE
    fill, ink, gold = colours["accent"], colours["paper"], colours["gold"]
    img = Image.new("RGB", (s, s), fill)
    draw = ImageDraw.Draw(img)
    c = s / 2
    stitch_ring(draw, c, c, s * 0.4, ink, s * 0.014)

    def number(value: int, y: float, size: float) -> None:
        font = ImageFont.truetype(str(FONT), int(s * size))
        draw.text((c, y), str(value), font=font, fill=ink, anchor="mm")

    if "sewn" in entry:
        number(entry["sewn"], c + s * 0.01, 0.3 if entry["sewn"] < 100 else 0.2)
    elif "chapters" in entry:
        patch(draw, c, c, s * 0.24, ink, fill)
        font = ImageFont.truetype(str(FONT), int(s * 0.22))
        draw.text((c, c + s * 0.01), str(entry["chapters"]), font=font, fill=fill, anchor="mm")
    elif "three" in entry:
        three_stars(draw, c, c - s * 0.09, s, gold)
        number(entry["three"], c + s * 0.17, 0.17)
    elif "seamless" in entry:
        spool(draw, c, c, s * 0.25, ink, fill)
    elif "quick" in entry or entry.get("chapter"):
        stopwatch(draw, c, c - s * 0.01, s * 0.21, ink)
    elif "banked" in entry:
        flower(draw, c, c - s * 0.08, s * 0.2, ink, fill, gold)
        number(entry["banked"], c + s * 0.22, 0.13)
    elif "turns" in entry:
        turn(draw, c, c - s * 0.07, s * 0.17, ink)
        number(entry["turns"], c + s * 0.22, 0.12)
    elif "unravels" in entry:
        yarn(draw, c, c - s * 0.07, s * 0.2, ink, fill)
        number(entry["unravels"], c + s * 0.22, 0.12)
    elif entry.get("key") == "stars":
        star(draw, c, c + s * 0.02, s * 0.26, gold)
    elif entry.get("key") == "rooms":
        zipper(draw, c, c - s * 0.04, s * 0.24, ink, fill)
    else:
        raise SystemExit(f"{entry['key']}: no icon is drawn for it")
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    catalog = json.loads(CATALOG.read_text())
    colours = palette()
    OUT.mkdir(parents=True, exist_ok=True)
    metadata = io.StringIO()
    mappings = io.StringIO()
    meta = csv.writer(metadata, lineterminator="\n")
    maps = csv.writer(mappings, lineterminator="\n")
    files = {}
    for order, entry in enumerate(catalog["achievements"], start=1):
        name, text = entry["name"], entry["text"]
        if "," in name or "," in text:
            raise SystemExit(f"{entry['key']}: the import forbids commas in a name or description")
        steps_needed = goal(entry)
        meta.writerow([name, text, "True" if steps_needed > 1 else "False", steps_needed if steps_needed > 1 else "",
                       "Revealed", entry["points"], order])
        png = f"{entry['key']}.png"
        maps.writerow([name, png])
        buffer = io.BytesIO()
        image = icon(entry, colours)
        image.save(buffer, "PNG")
        image.save(OUT / png)
        files[png] = buffer.getvalue()
    for board in catalog["leaderboards"]:
        icon(board, colours).save(OUT / f"leaderboard_{board['key']}.png")
    zip_path = OUT / "achievements.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("AchievementsMetadata.csv", metadata.getvalue())
        z.writestr("AchievementsIconsMappings.csv", mappings.getvalue())
        for png, data in files.items():
            z.writestr(png, data)
    print(f"wrote {zip_path}: {len(files)} achievements, icons in {OUT}")
    write_game_stats(catalog, colours)


if __name__ == "__main__":
    main()
