# Room design

How Stitchfall's rooms are built from now on, what we took from Level Devil, and the chapter plan.
The first chapter, Plain Linen, is built this way and opens the campaign. The older wide rooms follow it until each is rebuilt.

## What was wrong with the old rooms

- **You could not see the room.** The camera is zoomed to 1.6 on a computer and 2 on a phone and follows the runner, so the exit and most traps start off screen. A trap you cannot see is not a joke, it is a guess.
- **The hint was the answer.** Every room opened with a sentence like "Shift twice and run along the ceiling". Nothing was left to find.
- **Every room had the same shape.** A big box, a pillar or two, three buttons spread along the floor, the zipper on the right. Settings and mechanisms changed, and the route did not.
- **More parts, not more ideas.** Later rooms stacked cutters, chains, moths, ferries and seams together. They got busier, not funnier.

## What Level Devil does

Level Devil is a one-screen platformer where the level itself pranks you: floors drop, spikes pop up, the exit door moves, controls flip.
Its official site sells it as disappearing floors, dropping blocks and doors that move, with instant retries.
What makes it work, as best we can tell from playing it and from its guides:

1. **The whole level is on screen.** Nothing comes from off camera. When it gets you, you can see what happened.
2. **One prank per level.** A level is a setup and a punchline, five to twenty seconds once you know it.
3. **Same room, new prank.** A world reuses one layout for several levels, each with a new trick. You recognise the room, so you expect the old answer, and that expectation is the joke.
4. **It trains a habit, then punishes it.** Early levels build confidence, later ones turn that confidence against you.
5. **Death is cheap.** Instant restart, no long animation, so a death is information, not a punishment.
6. **Choices are bait.** The obvious path, the button in plain sight, the safe-looking floor.

Players also call it unfair and rage-inducing. Stitchfall should keep the surprise and lose the rage.

## Stitchfall's rules for a room

- **Seen whole.** A screen room is 1260 by 640, at a fixed zoom of 1.4 on every device, and the camera never moves (`SCREEN` and `SCREEN_ZOOM` in `scripts/level_data.gd`).
- **One prank, and a tell.** Every trap is fair on a second look: pop-up needles show their eyes in the cloth, a zipper that runs is sewn on a visible track. The first death should make you laugh, the second try should work.
- **The buttons are the clue.** Where a button sits says which way to go: on the ceiling, in mid-air, on a wall. No room explains itself in words.
- **A name, not an instruction.** The intro card shows only the room's name, like "Same Room" or "Nothing New".
- **Short.** Five to twenty seconds once you know the room. A hit sends you back to the start, and your buttons stay sewn on.
- **Gravity is the punchline.** Level Devil's pranks are about the floor. Ours are about down: the room that needs you to fall sideways, the zipper that runs to where gravity is not.
- **Proved.** Every screen room has a recorded route that finishes it and the obvious run its prank is built to catch, both replayed by `tests/run_tests.gd` (`SCREEN_ROUTES`). Design a room with `tools/route.gd`, which prints where the runner goes.

## The parts

| Part | In the level data | What it does |
| --- | --- | --- |
| Needle strip | `spikes` | Needles on any surface, pointing along `dir` |
| Pop-up needles | `popups` | Lie flat, showing only their eyes, and stand up `delay` seconds after the runner enters `trigger` |
| Runaway zipper | `exit_flee`, `flee_radius` | Once open, the zipper runs along its track to the next point when the runner comes near |
| Unpinned patch | `fray_ledges` | Looks sewn on but is only pinned. Shivers once stood on, drops after `delay` seconds, leaves its tacking stitches |
| Pincushion | `pins` | Falls the way gravity points, as fast as the runner does, and hurts from every side. Pins stack on each other |
| Flower | `flowers` | Stands on any surface (`gravity` is the way its stem points). Touching it banks your buttons, saves where the pins are, and makes it the place you come back to, facing that way |
| Everything older | | Phase bridges, timed seams, moths, cutters, chains, weights, springs, blooms, the weighted patch, and the six worlds' forces |

## Chapter plan

Each chapter is one room layout played five times, each with a new prank, and the fifth combines them.

1. **Plain Linen** (built). A needle strip, two buttons and a zipper.
   1. *A Gentle Start*: jump the strip.
   2. *Same Room*: the landing pops up its needles, and the second button is on the ceiling. Go over by the ceiling.
   3. *Almost There*: the zipper runs up its track to the top corner. Turn the room over to reach it.
   4. *Nothing New*: needles on the floor and the ceiling, and a button in mid-air. Climb the left wall and fall sideways across the room.
   5. *One More Time*: everything at once, and the zipper starts on the ceiling and runs to the floor.
2. **Loose Pins** (built). A pin falls exactly as fast as you do, so it keeps its place in line with you through every turn.
   1. *Mind the Pins*: jump the pin, grabbing the button over it.
   2. *Heads Up*: the chapter one habit, turning over to the ceiling, lands the pin in your path. Get past the pin before you turn.
   3. *Clean Sweep*: the zipper is on the ceiling and the pin waits under it. Turn once to sweep the pin into the far corner, climbing the wall to let it pass beneath you.
   4. *Company*: two pins follow you all the way round the room. Jump as you turn so you fall in a different lane, and wait for them to settle before the last turn, or they drop on you from mid-room. A flower on the ceiling.
   5. *Pin Drop*: pins on shelves over a needled floor, the ceiling button between where they land, and a race into the zipper before they land on it.
3. **Unpinned** (built). The same needle pit five times, crossed on patches that look sewn on but are only pinned.
   1. *Tacked On*: one patch, held long enough to cross.
   2. *Keep Moving*: a row of patches that only lasts at a run. Stop for the button and you go in.
   3. *Last Step*: two sewn steps and a third that only looks it. Jump the last step.
   4. *No Way Back*: the bridge drops once crossed and the zipper is back at the start. Come home by the ceiling.
   5. *Hold On*: Keep Moving's habit sends you onto a patch that drops at a touch. Stop at the flower on the island, turn up for the button between two needle strips, turn back down, and jump the trap.
4. **The Turning Seam.** Stitched bands that turn gravity when you cross them, as trap and as help.
5. **Lit Seams.** The phase bridges, now with the prank that a turn mid-crossing takes your bridge away.
6. **The Weighted Patch.** The patch as a shield, a step and a falling danger.
7. to 10. **Water, Dunes and Canopy, Night Quilt, Rain and Frost.** Each world's pull as the prank, ending in a finale that mixes chapters.

A chapter is built, proved by its routes, then played on a phone before the next one starts.

## Rewards

- **Three stars a room.** *Sewn* for finishing, *Unbroken* for finishing without an unravel, *Quick* for beating par. A room's par is its proved route's time times 1.5, rounded up (`SCREEN_PARS`), and the tests check every route earns all three.
- **The clear card.** The stars pop in one by one with a chime, then the time against par, a line about how many times you unravelled, and a call-out for a new best. Next, Replay and Levels.
- **Buttons are loose until a flower banks them.** An unravel shakes every loose button back to where it was found. A room without a flower is all or nothing.
- **Saved progress** (`scripts/progress.gd`, `user://progress.cfg`): each room's best stars and time. A room opens once the one before it is sewn, Play continues from the first room not yet sewn, and Levels shows one chapter a page with its stars.
- **Drama.** The camera shakes on a hit, on every prank (needles popping up, the zipper running, a patch giving way) and when a pin lands, and the zipper throws up thread snips and petals when it takes you.

## Art

The needle strips (`needle_strip_raised.png`, `needle_strip_flat.png`) and the zipper track (`zipper_track.png`) are drawn by `scripts/world_view.gd`, tiled along any surface and turned to face it.
The pincushion (`scripts/pincushion.gd`) and the unpinned patch (`scripts/fray_ledge.gd`) draw their art. The turning seam waits for chapter 4.
