# Palewheel mechanics

The pilot's gravity is a unit vector that points down, left, up or right.
Each shift rotates it by ninety degrees and rounds the result to a cardinal direction.
Running follows the tangent to gravity, so the same left and right controls work on every surface.
Jumping pushes against gravity.

The cargo applies force along the same gravity vector each physics frame.
Light bridge collisions swap state on each shift.
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

The current movement constants and their actual behavior live in `scripts/player.gd` and `scripts/cargo.gd`.
Tune them by playing through every room, especially after consecutive shifts.
