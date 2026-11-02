# Palewheel

Palewheel is a 2D action puzzle game set inside a failing orbital gravity engine.
Carry light through each chamber by running, jumping, and turning gravity in quarter turns.
Each turn moves loose cargo, changes the light bridges, and briefly stills the security drones.

## Play

Run `./play.sh` from this directory to play locally with Godot 4.7.
The browser version is published from this repository's `gh-pages` branch.
Use a landscape phone screen for touch controls.

On desktop, use A and D to move, Space to jump, Q and E to turn gravity, R to restart the chamber, and P to pause.

## Development

The project uses GDScript and the GL Compatibility renderer.
Run `godot --headless --path . -s res://tests/run_tests.gd` for the gameplay checks.
Run `godot --headless --path . --export-release Web build/web/index.html` after importing the project to make a browser build.
See [PLAN.md](PLAN.md), [MATH.md](MATH.md), and [CREDITS.md](CREDITS.md).
