# Palewheel

Palewheel is a 2D action puzzle game set inside a failing orbital gravity engine.
Carry light through each chamber by running, jumping, and turning gravity in quarter turns.
Each turn moves loose cargo, changes the light bridges, and briefly stills the security drones.

## Play

[Play Palewheel in your browser](https://chaosmos.studio/palewheel/).
Turn a phone sideways.
Slide left or right to walk, swipe up to jump, swipe down to crouch, and tap the playfield to turn gravity.
Preview the [flooded station](https://chaosmos.studio/palewheel/?room=4), [dune relay](https://chaosmos.studio/palewheel/?room=6), [forest canopy](https://chaosmos.studio/palewheel/?room=8), or [orbital rim](https://chaosmos.studio/palewheel/?room=10) directly.
Run `./play.sh` from this directory to play locally with Godot 4.7.

On desktop, use A and D or the arrow keys to move, W, Up, or Space to jump, S or Down to crouch, and Shift or a mouse click to turn gravity.
Use R to restart the chamber and P or Escape to pause.

## Development

The project uses GDScript and the GL Compatibility renderer.
Run `godot --headless --path . -s res://tests/run_tests.gd` for the gameplay checks.
Run `godot --headless --path . --export-release Web build/web/index.html` after importing the project to make a browser build.
See [PLAN.md](PLAN.md), [MATH.md](MATH.md), and [CREDITS.md](CREDITS.md).
