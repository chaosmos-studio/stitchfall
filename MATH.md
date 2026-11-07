# Stitchfall mechanics

The pilot's gravity is a unit vector that points down, left, up or right.
Each shift rotates it by ninety degrees and rounds the result to a cardinal direction.
Running follows the tangent to gravity, so the same left and right controls work on every surface.
Jumping pushes against gravity.

The cargo applies force along the same gravity vector each physics frame.
When the runner presses into the cargo, a contact impulse points along the surface tangent.
The impulse is scaled by cargo mass so changing its mass does not change the immediate speed gain.
Light bridge collisions swap state on each shift, so a lit seam is solid after an odd number of gravity turns.
Each needle moth moves between authored endpoints with a sine curve.
A gravity shift pauses its patrol and contact hazard briefly, which creates a safe crossing window.
The pilot keeps a short jump buffer and coyote window so a button press near an edge still feels responsive.
Releasing jump while rising cuts upward speed to 48 percent of the full jump speed, so a tap gives a lower arc.
A gravity turn changes acceleration and the collision frame immediately, while world-space momentum stays continuous.
The character drawing rotates over 0.23 seconds to show the body catching up with the new down direction.
Authored environment rectangles change movement only while the pilot is inside them.
Floodwater adds 33 percent of normal gravity and damps existing fall speed each physics frame.
Dune wind adds a rightward world force, while the forest canopy adds an upward world force.
The orbital rim uses 27 percent of normal gravity and slower air steering, extending jumps without changing the pull's direction.

## Falling sideways

Turns only go one way, down, left, up, right, then down again.
So to fall to the right from the left wall takes two turns, up and then right, and *Nothing New* is built on that.
Stand on the left wall, run along it to the height you want, then turn twice.
During the first turn's quarter second the pull is up, and the runner drifts about 0.5 × 1550 × 0.24² ≈ 45 pixels toward the ceiling.
Then the pull points right and the runner falls across the whole room at nearly that height, reaching the far wall in under a second.
So the height you pick on the wall is the height you cross at, which is why the room's mid-air button sits a little above the middle.
`tools/route.gd` prints the crossing, and the room's route in `tests/run_tests.gd` proves it.

## Why a pin keeps its place in line

A pincushion falls with the same pull as the runner, 1550 pixels per second squared, and both start a turn at rest along the new direction.
Two things falling together from rest stay the same distance apart, which is Galileo's point about dropped weights.
So a pin to your left before a turn is still to your left after it, and a pin in your lane lands where you land.
Three ways out follow from that, and Loose Pins teaches each.
Get past the pin before you turn (*Heads Up*), so the order is the one you want.
Be in a different lane when you turn, by jumping first or standing higher up a wall (*Clean Sweep*, *Company*), since the gap across the fall never closes.
Or arrive first: the pin and you fall together, so whoever starts nearer the new floor lands first (*Pin Drop*'s race).
The runner keeps the speed it gains during a turn's first quarter second and can steer, while a pin drops its sideways speed at each turn and cannot.
That is why `tools/route.gd` shows the runner drifting about 140 pixels in a single turn left, while a pin drifts about 50.

## Banking buttons

A collected button is loose until the runner touches a flower with it, then it is banked.
An unravel puts every loose button back, so a room is a run you either finish or redo from the last flower.
The flower also saves where every pin is, so coming back to it puts the room as it was when you touched it.

The current movement constants and their actual behavior live in `scripts/player.gd` and `scripts/cargo.gd`.
Tune them by playing through every room, especially after consecutive shifts.

## Two phones, one progress

With Play Games on, the progress file is kept in the player's Google account too, and a phone that signs in joins
that copy with its own (`scripts/cloud_save.gd`).
Every value is joined by a rule that only keeps the better of two: the most stars, the least time, a room skipped
on either phone, the larger count of unravels.
Rules like max, min and "either" give the same answer in any order, `join(a, b) == join(b, a)`, and joining a copy
with itself changes nothing, `join(a, a) == a`.
So it never matters which phone saved first or how often a copy is read back: three phones in any order end at the
best of each room, and nothing played on any of them is lost.
The one thing a join cannot do is forget, which is why Reset writes the cloud copy over instead of joining it.
The speedrun board adds up the five best times of Plain Linen, each of which can only fall, so the sum only falls too.
