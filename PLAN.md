# Working game design

## Intent

The temporary title is Palewheel.
The game has no wheel in its story or art.
The player guides a young runner through a world assembled from cloth, thread, and buttons.
One Shift press turns gravity by a quarter turn and changes which sewn bridges are solid.
The same shift moves weighted patches and pauses needle moths.
Collect the buttons in each room to open its zipper exit.

## Art direction

Shravan chose the stitched world direction on 3 November 2026.
Backgrounds are layered textile scenes with visible fiber, cut edges, and embroidery.
The runner uses hand-drawn character sheets with a longer run cycle and separate action poses.
Platforms, hazards, pickups, exits, enemies, cargo, and HUD elements are drawn in Godot to match the fabric scenes.
The HUD keeps button progress and pause available during play.
Each room name and its instruction appear briefly when the room begins.
The HUD cloth palette follows the setting.
The Home screen plays a slower front-facing dance loop made from 62 sprite frames.
Its sewn woodland stage has a quiet fabric pocket for the menu.
Game labels and buttons use Averia Sans Libre for a warm handmade letterform.
An original music loop accompanies the dance and continues into play.
Level Select presents the rooms as two pages of larger textile cards with setting symbols.
Help uses sewn gesture diagrams, and Pause uses a stitched icon during play.

## Settings and rules

The current route moves through the first cloth chambers, water, dunes, forest, night quilt, rain meadow, and frost woodland.
Water softens falls.
Sand wind pushes sideways.
Canopy drafts lift the runner.
The night quilt lengthens jumps.
Rain gusts change direction.
Frost preserves horizontal momentum.

## Structure

`scripts/level_data.gd` holds authored room geometry and goals.
`scripts/game_controller.gd` owns progression, pickups, checkpoints, and shifts.
`scripts/player.gd` owns movement, environmental forces, and sprite animation.
`scripts/cargo.gd` and `scripts/sentry.gd` own moving obstacles.
`scripts/world_view.gd` draws the textile world.
`scripts/hud.gd`, `scripts/stitched_button.gd`, `scripts/button_meter.gd`, and `scripts/stitch_border.gd` draw the interface.

## Next milestones

## Campaign and presentation checklist

The current rooms introduce movement, gravity, phase bridges, weighted patches, water, wind, canopy lift, low gravity, rain, and ice.
Several rooms repeat the same left-to-right wall rhythm, so a new backdrop alone will not make them feel different.

Plumb's generator uses chapter rules, seeded candidates, a solver, difficulty bands, and duplicate rejection.
Carillon grows an answer first and checks that added rules matter.
Apsis places features with spacing constraints and verifies the result.
Palewheel needs the same discipline for movement routes, with a replayable physics path and clearance checks before a room joins the campaign.

- [ ] Measure and repair player movement in every gravity orientation on keyboard and touch.
- [x] Make the browser loader show actual downloaded bytes and a distinct opening sequence.
- [x] Fit home, pause, help, and level selection to the visible phone viewport.
- [x] Add a browser fullscreen action where the browser supports it.
- [x] Replace the home dance with a front-facing, detailed loop and give menu controls textile artwork.
- [x] Add an About page with a short studio introduction.
- [x] Give the studio site a game page and publish the playable build at `/palewheel/play/`.
- [ ] Design room families around a single movement idea: ceiling runs, timed bridge crossings, cargo transport, water ascent, wind carry, canopy lift, low-gravity arcs, rain reversal, and ice braking.
- [ ] Add setting families beyond the current route, with a visible interaction and sound identity for each.
- [ ] Build deterministic candidate generation with protected start and exit zones, reachable collectibles, hazard clearance, and repeated-layout rejection.
- [ ] Replay generated candidates with the actual movement constants, reject unreachable routes, and order accepted rooms by measured difficulty.
- [ ] Play every family on desktop and phone, tune checkpoints, then expand the campaign in reviewed batches.
- [ ] Finish transitions, ending, accessibility, performance, Android export, and Game Off submission review.

## Campaign decisions, 3 November 2026

| Decision | Choice | Revisit when |
| --- | --- | --- |
| Scope | A long-term single-player campaign built in reviewed batches | The first generated batch is playtested |
| Dimension and engine | 2D GDScript in Godot 4.7 with the Compatibility renderer | A new mechanic needs another dimension |
| Level authorship | Hand-authored opening rooms followed by seeded, validated candidates | The route validator cannot model a mechanic |
| Difficulty | Teach one interaction, vary the route, then combine interactions | Player testing shows a different learning curve |
| Presentation | Stitched world with varied natural settings and a light home screen | A setting reads poorly on a phone |

These decisions use Shravan's earlier creative freedom and instruction to build without waiting for concept approval.

## Room design audit, 4 November 2026

The 16 current rooms establish useful movement rules, but most start near the left floor, end near the right floor, place a wall in the middle, and scatter three sparks along the route.
Changing the setting or adding a sentry does not change the route the player has to understand.
Plumb's lesson is to make each stage earn its place through a new rule, a proved solution, a difficulty target, and a difference from nearby stages.
Palewheel needs those checks around continuous movement and timing rather than a grid solver.

Each room should have a one sentence action, such as "shift from the ceiling to catch a falling platform," that remains recognizable without its art.
Build its route from a start state, a readable discovery, a commitment point, a payoff, and a safe finish.
Put optional sparks on alternate paths, not on the mandatory line to the exit.
Vary direction and shape: short vertical climbs, loops, descending runs, two-screen journeys, and compact timing rooms should interrupt left-to-right crossings.

| Family | First room | Variation | Mastery room |
| --- | --- | --- | --- |
| Ceiling run | Cross one floor gap on the ceiling | Switch between offset floor and ceiling ledges | Descend from the ceiling into a moving exit window |
| Phase seam | Reveal one bridge with a shift | Keep a route through two alternately solid seams | Shift while airborne to cross a broken chain |
| Weighted patch | Move one patch onto its mark | Use the patch as temporary cover or footing | Carry it through a vertical route while gravity changes |
| Water | Learn buoyant fall and a visible current | Enter and leave pools at different heights | Ride a current, then shift before the exit |
| Wind and dunes | Cross a short gust with generous ground | Redirect a long jump with a shift | Brake against a gust and land on a narrow safe strip |
| Forest | Bounce from one canopy lift | Chain two lifts with a ceiling run | Choose a high route or a low, safer route |
| Night | Read a long low gravity arc | Make two shifts during one arc | Recover from overshoot in a room with sparse footing |
| Rain and frost | Feel one slick or gusting surface | Alternate dry grip and wet slide | Stop precisely after a gravity change |

For every family, ship an introduction, a reversal, a combination with an earlier rule, and a short mastery room before generating close variants.
Revisit earlier families after each new world so a later room feels like a new situation, not a reskin.
World art, sound, hazard silhouettes, and HUD materials should explain the physical rule before the player reads a hint.

The generator should assemble authored route segments and vary their spacing, orientation, safe landing area, and optional detours from a saved seed.
It should reserve start, exit, and checkpoint clearances before placing hazards.
A deterministic fixed-step replay using the game's movement values should prove at least one exit route and record jumps, shifts, airtime, retraces, and near misses.
Compare route signatures and geometry after translation or reflection to reject repetitions.
Rank candidates within a family, then playtest the chosen rooms on phone and desktop before releasing them.
Automated reachability is a gate, while human playtesting decides whether a route is readable and fun.
