# Stitchfall mechanics

The pilot's gravity is a unit vector that points down, left, up or right.
Each shift rotates it by ninety degrees and rounds the result to a cardinal direction.
Running follows the tangent to gravity, so the same left and right controls work on every surface.
Jumping pushes against gravity.

The cargo applies force along the same gravity vector each physics frame.
When the runner presses into the cargo, a contact impulse points along the surface tangent.
The impulse is scaled by cargo mass so changing its mass does not change the immediate speed gain.
Light bridge collisions swap state on each shift.
Mint buttons collect only in the lit bridge phase, which occurs after an odd number of gravity turns.
Each clock eye moves between authored endpoints with a sine curve.
A gravity shift pauses its patrol and contact hazard briefly, which creates a safe crossing window.
The pilot keeps a short jump buffer and coyote window so a button press near an edge still feels responsive.
Releasing jump while rising cuts upward speed to 48 percent of the full jump speed, so a tap gives a lower arc.
A gravity turn changes acceleration and the collision frame immediately, while world-space momentum stays continuous.
The character drawing rotates over 0.23 seconds to show the body catching up with the new down direction.
Authored environment rectangles change movement only while the pilot is inside them.
Floodwater adds 33 percent of normal gravity and damps existing fall speed each physics frame.
Dune wind adds a rightward world force, while the forest canopy adds an upward world force.
The orbital rim uses 27 percent of normal gravity and slower air steering, extending jumps without changing the pull's direction.
Timed seams open for a room-specific window when gravity shifts and close after the runner leaves their opening.
Touching a bloom keeps the runner's tangential speed and applies an impulse opposite gravity.

## Falling sideways

Turns only go one way, down, left, up, right, then down again.
So to fall to the right from the left wall takes two turns, up and then right, and *Nothing New* is built on that.
Stand on the left wall, run along it to the height you want, then turn twice.
During the first turn's quarter second the pull is up, and the runner drifts about 0.5 × 1550 × 0.24² ≈ 45 pixels toward the ceiling.
Then the pull points right and the runner falls across the whole room at nearly that height, reaching the far wall in under a second.
So the height you pick on the wall is the height you cross at, which is why the room's mid-air button sits a little above the middle.
`tools/route.gd` prints the crossing, and the room's route in `tests/run_tests.gd` proves it.

The current movement constants and their actual behavior live in `scripts/player.gd` and `scripts/cargo.gd`.
Tune them by playing through every room, especially after consecutive shifts.
