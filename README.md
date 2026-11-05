# Palewheel

Palewheel is the working title for a 2D action puzzle game in a world made of cloth and thread.
Run, jump, and shift gravity to collect buttons and reach each open seam.
Each shift also changes sewn bridges, moves weighted patches, and briefly stills needle moths.

## Play

[Play Palewheel in your browser](https://chaosmos.studio/palewheel/play/).
Turn a phone sideways.
Use the Home screen to play, choose a seam, or open the illustrated controls.
Slide left or right to walk, swipe up to jump, swipe down to crouch, and tap the playfield to turn gravity.
Preview the [water](https://chaosmos.studio/palewheel/play/?room=4), [dunes](https://chaosmos.studio/palewheel/play/?room=6), [forest](https://chaosmos.studio/palewheel/play/?room=8), [night quilt](https://chaosmos.studio/palewheel/play/?room=10), [rain meadow](https://chaosmos.studio/palewheel/play/?room=12), or [frost woodland](https://chaosmos.studio/palewheel/play/?room=14).
Run `./play.sh` from this directory to play locally with Godot 4.7.

On desktop, use A and D or the arrow keys to move, W, Up, or Space to jump, S or Down to crouch, and Shift or a mouse click to turn gravity.
Use R to restart the chamber and P or Escape to pause.
The sewn pause icon opens Resume, Restart, and Home.
The Sound control is in Settings, and M toggles music and effects during play.

## Development

The project uses GDScript and the GL Compatibility renderer.
Run `godot --headless --path . -s res://tests/run_tests.gd` for the gameplay checks.
After importing the project, run `godot --headless --path . --export-release Web build/web/index.html` and `python3 tools/prepare_web.py` to make a browser build.
See [PLAN.md](PLAN.md), [MATH.md](MATH.md), and [CREDITS.md](CREDITS.md).
