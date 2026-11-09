# Stitchfall mechanics

The pilot's gravity is a unit vector that points down, left, up or right.
Each shift rotates it by ninety degrees and rounds the result to a cardinal direction.
Running follows the tangent to gravity, and jumping pushes against gravity.

## Controls that follow the screen

The runner's own moves are along its surface and away from it: run with `t = (g.y, −g.x)`, the tangent to gravity `g`, and jump against `g`.
On a wall those are up and down the screen and off the wall, so the keys and slides are read as screen directions and turned into the runner's moves for the way gravity points.
A push `p` (an arrow, a stick, or a slide's offset from where the finger landed) splits three ways:
- along the surface, `p · r`, runs, where `r` is the screen direction the runner's +1 move takes it: `t` on the floor and walls, `−t` on the ceiling, where the runner turns its moves round so right stays right;
- away from it, `p · (−g)`, jumps;
- into it, `p · g`, crouches.

So on the left wall (`g = (−1, 0)`, `r = (0, 1)`) up runs up the wall, right jumps off it, and left crouches into it, and on the floor it is the usual left, right, up to jump and down to crouch.
A key counts toward jumping or crouching past `KEY_ROLE = 0.5`, so a diagonal, 0.71 each way, still runs and jumps at once.
A slide runs when it is `SLIDE_RUN_BIAS = 1.15` times more along the surface than across it.

A push held through a turn would change its meaning under the finger: running right on the floor, then the room turns onto the left wall, where right means jump.
So after a turn a push that now points away from the surface or into it does nothing until it is let go (`_reread_held_controls`), and a held slide takes its new meaning without acting on it.
The rooms' proofs press the runner's own moves (`move_left`, `move_right`, `jump`, `crouch`), which have no keys of their own, so the proofs stay true whatever the screen mapping is.

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

## Fitting a room to a phone

A room is always seen whole, but a phone is wider than the 16:9 the rooms were drawn for, so a fixed zoom left a 20:9 phone with empty strips beside a small room.
Now the camera fits the room's inside, 1200 by 580, plus 16 units of wall on every side (1232 by 612), into whatever the HUD leaves of the screen.
With the screen `W × H` and the HUD keeping `l, t, r, b` pixels clear at the left, top, right and bottom, the zoom is the smaller of `(W − l − r) / 1232` and `(H − t − b) / 612`.
The camera then looks `((l − r) / 2, (t − b) / 2) / zoom` up and to the left of the room's middle, so the room sits in the middle of the free part, not the middle of the screen.

Where the HUD goes decides the reserve, and the HUD tries both places and keeps the larger room:
- **A strip along the top**, 138 pixels on a phone and 8 at the foot: on 16:9, 1920 by 1080, the height decides, `(1080 − 146) / 612 ≈ 1.53`, a little under the width's `(1920 − 16) / 1232 ≈ 1.55`.
- **One rail on the right**, 142 pixels, with the pause button, the meter and the counts in a column, and only an 8 pixel edge on the left: on 20:9, 2400 by 1080, a top strip would also give 1.53, but the rail leaves the full height, `(2400 − 150) / 1232 ≈ 1.83` against `(1080 − 16) / 612 ≈ 1.74`, so 1.74, and the room sits just in from the left with the spare width beside the rail.

Against the old 1.4 everywhere, that is about 9% larger on a 16:9 phone and 23% larger on a 20:9 one, half as much area again.
The zoom stops at 2, so a tablet does not blow the art up past its detail.

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
