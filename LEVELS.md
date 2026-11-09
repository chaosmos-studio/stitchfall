# Room design

How Stitchfall's rooms are built from now on, what we took from Level Devil, and the chapter plan.
The whole campaign is built this way, twelve chapters of five rooms. The older wide rooms are gone, with the parts only they used.

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

- **Seen whole.** A screen room is 1260 by 640, and the camera never moves. It is fitted to the screen as large as the HUD allows, so its inside is always wholly in view (`fit_zoom` in `scripts/level_data.gd`, and MATH.md, Fitting a room to a phone).
- **One prank, and a tell.** Every trap is fair on a second look: pop-up needles show their eyes in the cloth, a zipper that runs is sewn on a visible track. The first death should make you laugh, the second try should work.
- **The buttons are the clue.** Where a button sits says which way to go: on the ceiling, in mid-air, on a wall. No room explains itself in words.
- **A name, not an instruction.** The intro card shows only the room's name, like "Same Room" or "Nothing New".
- **Short.** Five to twenty seconds once you know the room. A hit sends you back to the start, and your buttons stay sewn on.
- **Gravity is the punchline.** Level Devil's pranks are about the floor. Ours are about down: the room that needs you to fall sideways, the zipper that runs to where gravity is not.
- **Proved.** Every room has a recorded route that finishes it and the obvious run its prank is built to catch, both replayed by `tests/run_tests.gd` (each chapter's `ROUTES`). Design a room with `tools/route.gd`, which prints where the runner goes.

## The parts

| Part | In the level data | What it does |
| --- | --- | --- |
| Needle strip | `spikes` | Needles on any surface, pointing along `dir` |
| Pop-up needles | `popups` | Lie flat, showing only their eyes, and stand up `delay` seconds after the runner enters `trigger` |
| Runaway zipper | `exit_flee`, `flee_radius` | Once open, the zipper runs along its track to the next point when the runner comes near |
| Unpinned patch | `fray_ledges` | Looks sewn on but is only pinned. Shivers once stood on, drops after `delay` seconds, leaves its tacking stitches |
| Pincushion | `pins` | Falls the way gravity points, as fast as the runner does, and hurts from every side. Pins stack on each other |
| Flower | `flowers` | Stands on any surface (`gravity` is the way its stem points). Touching it banks your buttons, saves where the pins and the patch are, and makes it the place you come back to, facing that way |
| Lit seam | `phase_walls` | Solid while gravity points left or right, after an odd number of turns, and a ghost while it points down or up |
| Needle moth | `sentries` | Swings between `from` and `to` once every `period` seconds, and `offset` sets where in the swing it starts. A turn stills it, harmless, for 0.55 seconds |
| Weighted patch | `crate`, `pad` | Falls the way gravity points. The zipper opens only once the patch has sat on its pad, and an unravel puts the patch back |
| World | `environment`, `environment_zone` | Changes how the runner moves inside the zone: `water`, `dunes`, `forest`, `space` (the night quilt), `rain` or `frost` |

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
4. **Lit Seams** (`seams`, built). *Some floors only hold you sideways.* A lit seam is solid after an odd number of turns, when gravity points left or right, and a ghost when it points down or up. A seam hangs over a needled pit.
   1. *Lights On*: fall sideways onto the seam, walk it for a button, turn down onto a sewn shelf and jump the pit.
   2. *Lights Out*: the shelf is a seam now, lit while you stand sideways above it and gone the moment you turn down onto it.
   3. *See Through*: a wall seam from roof to floor catches the sideways fall. Turn upright just before it to slide through, past a button sewn inside it.
   4. *Round the Back*: the zipper runs up the back of the wall seam, where only a sideways runner can stand.
   5. *Seam Ripper*: everything at once, and the zipper runs to the roof corner, where turning up off the seam lands in needles. Jump clear and turn in the air.
5. **Needle Moths** (`moths`, built). *Every turn holds its breath.* Moths fly their tracks, and a turn stills them, harmless, for about half a second.
   1. *Hush*: climb past the wall moth, wait on the roof for the roof moth, and turn to dash past it.
   2. *Cornered*: a moth waits where the roof dash ends, awake by the time you arrive. Turn down again in the air.
   3. *Out of Step*: two roof moths fly opposite ways, and one turn passes both only when they bunch up.
   4. *Doorman*: two moths sit on the zipper and wake before a fall from the roof arrives. Walk down the right wall sideways and turn when the zipper is a short fall away.
   5. *Flutter By*: everything at once, with a lit seam catching the roof dash short of the corner moth.
6. **The Weighted Patch** (`patch`, built). *Some doors need a little weight.* The zipper opens only with the patch on its pad, and the patch falls the way gravity points. It sits in the pit, and a turn up lifts it slowly to the pad on the roof while you wait pinned under a shelf. The patch resets with you when you unravel.
   1. *Weighted*: wait for the patch to arrive before turning on.
   2. *Stepping Stone*: a button over the pit can only be reached standing on the patch, so use it before you send it.
   3. *Pushover*: turning off the patch throws you into needles on the left wall. Jump and turn at the top of the jump.
   4. *Hold the Door*: the door moths wake before a fall from the top of the wall arrives, so walk down the wall first.
   5. *Dead Weight*: everything at once, plus a moth where the turn off the patch lands. One turn in the air stills the moth, pins you under the shelf and sends the patch home.
7. **Blue Thread** (`water`, built). *Hold your breath.* One pool over a needle strip, with a pin and a step by the zipper. A dry jump clears about 180 px of needles, a jump from the water about 265.
   1. *Deep End*: only a jump from inside the pool clears the strip.
   2. *Step Up*: a second step that only a water jump from the first step reaches.
   3. *High Water*: the pool, strip and steps hang from the ceiling, so turn over and play the room upside down.
   4. *Slow Motion*: the landing raises pop-up needles while you hang in slow water, and the pin, which water does not slow, beats you to the ceiling.
   5. *Hold Your Breath*: Slow Motion upside down.
8. **Sand Drift** (`dunes`, built). *The wind only knows one way.* In the air the wind always wins. One turn sets it against gravity, so you drift slowly left.
   1. *Tailwind*: a strip only a wind-carried jump clears, a hop over the pin, a ceiling button, and a turn down near the wall that throws you into the zipper's corner.
   2. *Kite*: a second strip right after the landing, so the second jump leaves as you land.
   3. *Upwind*: the zipper is back by the start, and a jump into the wind falls short. Hop, turn once at the top, and drift home.
   4. *Crosswind*: needles high on the right wall catch the climb rooms 1 and 2 taught. Turn down further out.
   5. *Sand Drift*: both strips, the wall needles, the ceiling button and a flower, then the drift home.
9. **Green Canopy** (`canopy`, built). *Up is where the leaves go.* A draft column over the needle pit, stronger than gravity, is the only way across and back.
   1. *Updraft*: ride the draft up to the ceiling button, then jump into it at a run and it carries you home.
   2. *Treetops*: the far floor is needled, so turn over inside the draft and walk the ceiling there and back.
   3. *Thorns*: needles at the top of the draft. Cross it at a run so it lifts you only part way.
   4. *Pin Drop*: turned over inside the draft you are pressed up too hard to jump, and the pin lands beside you.
   5. *Green Canopy*: Pin Drop with thorns at the near end of the ceiling.
10. **Night Quilt** (`night`, built). *Everything floats a little longer here.* The whole room is night quilt, with a sewn moon over a needle pit. Pins ignore the quilt.
    1. *Hang Time*: a floaty jump to the moon, one off it, then a slow turn at the wall up to the zipper.
    2. *Soft Landing*: the far floor's needles pop up while your floaty jump is still drifting down. Turn in mid-air and come home by the ceiling.
    3. *Mind Your Head*: a needled cloud hangs where a full jump peaks.
    4. *After You*: after an early turn in the air, the pin reaches the ceiling first and waits where you land.
    5. *Moonset*: the moon is only pinned, and the zipper runs down its track into raised needles.
11. **Rainline** (`rain`, built). *The rain keeps its own time.* The way out on the floor runs with the gusts, and the way home on the ceiling runs into them. The drawn rain leans with the real push.
    1. *Rain Check*: a gust carries a jump past the island and blows a homeward jump short.
    2. *Don't Wait Up*: the ceiling island is a pinned patch, so waiting on it for a calm drops you.
    3. *Second Wind*: the far strip is wider than any calm jump.
    4. *Featherweight*: on its side, the gust holds you up for a long leap off the left wall.
    5. *Cloudburst*: both islands pinned, a strip that needs a gust, and a flower to bank the way out.
12. **Frost** (`frost`, built). *Nothing here stops when you do.* The whole room is ice, with a pit and a sewn step, and the way across is the ceiling. A turn while running the right way brakes you dead, and any other turn throws you.
    1. *Black Ice*: across by the ceiling and back, braking with a turn while running left.
    2. *Slip Up*: stopping above the step and turning throws you past it.
    3. *Wrong Way*: turning while running right over the step throws you, so go round and come back left.
    4. *Hard Stop*: no room to glide, so turn in mid-air while running left.
    5. *Runaway*: the zipper waits on the step, then runs home across the ice the moment you land beside it.

Every chapter after Plain Linen keeps the earlier parts in play (needles, pop-up needles, the running zipper, pins, unpinned patches, flowers), so its rooms get harder by having more pieces, never more rules. A chapter's first room teaches its idea in a room at least as demanding as the chapter before it ended.

A chapter is built, proved by its routes, then played on a phone before the next one starts.

## Building a chapter

A chapter is one script, `scripts/chapters/<id>.gd`, with `NAME`, `LINE` (its title card's mood line, never an instruction), `ROUTES` and `build(index)`, which returns room `index` from 0 to 4 built on `StitchfallLevels.screen_base()`. `scripts/chapters/pins.gd` is a good model. Every room states its `name`, `par`, `accent`, `backdrop` and its parts, and the parts are the keys `screen_base()` already has. The chapter joins the campaign when its id is added to `CHAPTER_IDS` in `scripts/level_data.gd`.

The tools play a chapter before it joins, by its id and room number:

```bash
godot --headless --path . -s res://tools/route.gd -- seams/2 "0:+move_right,40:shift,55:shift" 600   # where the runner goes
godot --headless --path . -s res://tools/prove.gd -- seams                                          # every check the tests make
DISPLAY=:0 godot --path . --fixed-fps 60 res://tools/gallery.tscn -- seams_2 seams/2 "1:shot"       # a picture of the room
```

Numbers worth knowing, all at 60 physics frames a second:

- The inside of a screen room runs from x 360 to 1560 and y 280 (ceiling) to 860 (floor). The runner stands at y 821 on the floor and 319 on the ceiling, starts at (430, 821), and the zipper sits at (1500, 781) on the floor or (1500, 359) on the ceiling.
- The runner runs at 360 px/s and jumps about 112 px high, about 270 px across at a run. Letting go of jump early cuts the jump.
- A turn rotates gravity a quarter turn: down, left, up, right, down. Two turns 15 frames apart put the runner on the ceiling. Left and right stay left and right on the screen.
- Water: falls are capped at 400 px/s, a jump rises about 135 px and hangs about 1.5 s, carrying about 360 px across, and running is 240 px/s. Night quilt: gravity is 0.27 times as strong, a jump goes about 220 px, running is 300 px/s. Dunes: the wind adds 1100 px/s² to the right. Canopy: the draft adds 1850 px/s² upward. Rain: the push to the right is 900·sin(1.7t) + 360 px/s². Frost: on the ground the runner speeds up and slows down at 300 px/s² rather than 1850. Each force works only inside its `environment_zone`, and always in screen directions, whatever way gravity points.

## Rewards

- **Three stars a room.** *Sewn* for finishing, *Unbroken* for finishing without an unravel, *Quick* for beating par. A room's par is its proved route's time times 1.5, rounded up (each room's `par`), and the tests check every route earns all three.
- **The clear card.** The stars pop in one by one with a chime, then the time against par, a line about how many times you unravelled, and a call-out for a new best. Next, Replay and Levels.
- **Buttons are loose until a flower banks them.** An unravel shakes every loose button back to where it was found. A room without a flower is all or nothing.
- **Saved progress** (`scripts/progress.gd`, `user://progress.cfg`): each room's best stars and time. A room opens once the one before it is sewn, Play continues from the first room not yet sewn, and Levels shows one chapter a page with its stars.
- **The unravel.** A thread snaps, the runner comes apart in the wardrobe's unravel style, a felt horn sighs down three notes, the music dips, the screen flashes, and the room's unravel count ticks up beside the buttons, the way Level Devil keeps its death count in sight. Loose buttons fly home with their own falling plucks, and the runner pops back together.
- **The clear.** The zipper pulls the runner in with a spin and zips shut behind them, the room throws up thread and petals with a camera punch, then the card slides up to a plucked fanfare. The last room of a chapter gets a bigger fanfare and CHAPTER SEWN! with the chapter's stars. The card names anything the new stars opened in the wardrobe.
- **Chapters.** A chapter opens on a title card with its number, name and a line, and the room's chapter and name stay small at the top of the screen.
- **Every prank has a sound.** Needles shing up, the zipper's teeth rattle as it runs, a patch rips, a pin thuds, a flower blooms, and banked buttons pluck twice.
- The camera shake can be turned off in Settings.

## The Wardrobe and the shop

The Wardrobe (`scripts/looks.gd`, `scripts/shop.gd`) has five kinds of piece: runners, trails, unravels, buttons and fabrics.
The browser build cannot take payments, so there every piece is free.
On Android, trails, unravels and buttons open with stars, and runners and fabrics come with the Wardrobe pack through Google Play, with a tip product beside it.
A runner appears once its art is in `assets/art/runners/<id>/` (`run.png`, `actions.png`, `pose_0.png` to `pose_3.png`, and an optional `dance.png`), so a new runner needs no code.

## Art

The needle strips (`needle_strip_raised.png`, `needle_strip_flat.png`) and the zipper track (`zipper_track.png`) are drawn by `scripts/world_view.gd`, tiled along any surface and turned to face it.
The pincushion (`scripts/pincushion.gd`) and the unpinned patch (`scripts/fray_ledge.gd`) draw their art.
