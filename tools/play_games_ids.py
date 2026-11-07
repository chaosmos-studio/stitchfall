#!/usr/bin/env python3
"""Writes play_games.json from the ids Play Console gives for Stitchfall's Play Games project, which turns Play
Games on in the next Android build. Stitchfall's copy of the kit's kit/tools/play_games_ids.py.

Run from the game's folder, with the XML from Play Console (Play Games Services, Achievements or Leaderboards,
Get resources) saved to a file:
    python3 tools/play_games_ids.py build/play_games/games-ids.xml

Each achievement and leaderboard is matched to play_games/catalog.json by its name, the way Play Console names
its resource (`achievement_first_stitch` for "First stitch"), and the script stops if any is missing. The
Publishing API could make them, but it refuses service accounts on this account, so they come from
tools/play_games_import.py and Play Console instead.
"""

import json
import re
import sys
from pathlib import Path

CATALOG = Path("play_games/catalog.json")
IDS = Path("play_games.json")


def slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    found = dict(re.findall(r'<string name="([a-z0-9_]+)"[^>]*>([^<]+)</string>', Path(sys.argv[1]).read_text()))
    catalog = json.loads(CATALOG.read_text())
    ids = {"app": found.get("app_id", ""), "leaderboards": {}, "achievements": {}}
    missing = []
    for kind, prefix in (("leaderboards", "leaderboard_"), ("achievements", "achievement_")):
        for entry in catalog[kind]:
            key = prefix + slug(entry["name"])
            if key in found:
                ids[kind][entry["key"]] = found[key]
            else:
                missing.append(entry["name"])
    if not ids["app"] or missing:
        sys.exit("not in the XML: %s" % ", ".join((["app_id"] if not ids["app"] else []) + missing))
    IDS.write_text(json.dumps(ids, indent="\t") + "\n")
    print(f"wrote {IDS} for project {ids['app']}: {len(ids['leaderboards'])} leaderboards, "
          f"{len(ids['achievements'])} achievements")


if __name__ == "__main__":
    main()
