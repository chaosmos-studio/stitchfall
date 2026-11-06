# Working game design

## Intent

The public title is Stitchfall.
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
The Home screen plays a slow front-facing loop from four high-resolution poses.
Its sewn woodland stage has a quiet fabric pocket for the menu.
The title uses Darn Display, reading text uses Darn UI, the main menu uses Threadline Woven, and other stitched controls use Threadline Satin.
An original music loop accompanies the dance and continues into play.
Level Select presents the current rooms as two pages of textile patches.
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
Stitchfall needs the same discipline for movement routes, with a replayable physics path and clearance checks before a room joins the campaign.

- [ ] Measure and repair player movement in every gravity orientation on keyboard and touch.
- [x] Make the browser loader show actual downloaded bytes and a distinct opening sequence.
- [x] Fit home, pause, help, and level selection to the visible phone viewport.
- [x] Add a browser fullscreen action where the browser supports it.
- [x] Replace the home dance with a front-facing, detailed loop and give menu controls textile artwork.
- [x] Add an About page with a short studio introduction.
- [x] Give the studio site a game page and publish the playable build at `/stitchfall/play/`.
- [ ] Design room families around a single movement idea: ceiling runs, timed bridge crossings, cargo transport, water ascent, wind carry, canopy lift, low-gravity arcs, rain reversal, and ice braking.
- [ ] Add setting families beyond the current route, with a visible interaction and sound identity for each.
- [ ] Build deterministic candidate generation with protected start and exit zones, reachable collectibles, hazard clearance, and repeated-layout rejection.
- [ ] Replay generated candidates with the actual movement constants, reject unreachable routes, and order accepted rooms by measured difficulty.
- [ ] Play every family on desktop and phone, tune checkpoints, then expand the campaign in reviewed batches.
- [ ] Finish transitions, ending, accessibility, performance, and Android export.
- [x] Submit the playable public build to Game Off with the source repository and AI disclosure.

The current wider-room pass extends Needle Clock, Sand Drift, Green Canopy, and Rainline with a following camera, moving cloth platforms, new route targets, and longer crossings.
These rooms still need human route playtests before they count as finished campaign stages.
The next pass should change the route structure in the remaining rooms, then add short family-specific interactions and physics replay checks before increasing the room count.

## Surprise and mechanism pass, 5 November 2026

[Level Devil's official site](https://playleveldevil.com/) presents disappearing floors, falling blocks, shifting doors, and immediate retries as its core pacing.
Stitchfall takes the pacing idea, then uses visible cloth machinery that reacts to a gravity shift.
A trap must show its track or anchor before it moves, give the player a short wind-up, and restart quickly after a hit.

The first trap vocabulary is a spinning cutter, a moving chain, a hanging pulley weight, and a sewn spring launcher.
Needle Clock and Rainline wake a moving hazard when the player shifts.
Sand Drift puts a pulley weight over the ferry crossing.
Green Canopy uses a spring to change the climb.
Frostline combines momentum with a moving cutter.
The Last Seam combines a spring with a shift-armed chain.

On a hit, the runner's drawn fabric image separates into patches and thread for a short beat, then reappears at the pin.
This is a non-graphic cloth effect with no blood or human injury detail.
Before an Android release, complete the current [Google Play content rating questionnaire](https://support.google.com/googleplay/android-developer/answer/9859655) for the actual build and review its [violence policy](https://support.google.com/googleplay/android-developer/answer/9878810).
The [itch.io quality guidelines](https://itch.io/docs/creators/quality-guidelines) require the listing and AI disclosure to match the game.

- [x] Make the first four mechanism types playable in selected authored rooms.
- [x] Add a cloth-scatter hit animation and a timed retry.
- [ ] Play the whole route through each new mechanism on keyboard and touch, then tune the wind-up and safe gaps.
- [ ] Add one new route rule per room and reject layouts that share the same route shape.
- [ ] Develop more trap families, including seams that fold, bridges with counterweights, and flowers that open only during a shift.
- [ ] Build and validate new rooms in reviewed batches before increasing the campaign count.

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
Stitchfall needs those checks around continuous movement and timing rather than a grid solver.

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

## Next playable batch

Replace the opening rooms before adding more settings.
Each room needs a different route and a different reason to shift.

| Room | Main action | What makes it distinct |
| --- | --- | --- |
| First Stitch | Turn onto a wall, then return to the floor | A short safe route teaches the quarter turn without a sentry or cargo |
| Reverse Hem | Run across the ceiling to reach a button behind a floor barrier | The player must read the same space from the opposite side |
| Loose Bridge | Shift while airborne to sew a missing bridge under the landing | The bridge changes the path, not only the look of the room |
| Needle Clock | Shift to freeze a moth, cross its patrol, and land before it moves again | Timing matters, with a safe place to observe before committing |
| Weighted Patch | Move cargo onto its mark through a gravity turn | Cargo and player need different routes through one room |
| Stitch Relay | Carry the patch, reveal a bridge, then cross back for the exit | The earlier ideas combine without adding a new control |

The first implementation slice is First Stitch through Loose Bridge.
Play those rooms on phone and keyboard before changing the later route.
Each room gets a sketched solution path, a fixed-step replay from its actual movement rules, and one optional button detour.
Record shifts, jumps, airtime, safe landing width, hits, retries, and completion time from playtests.
Difficulty rises through route reasoning, timing, and recovery pressure, not by adding more hazards to the same crossing.

## Campaign production order

1. Build a room grammar from authored entrances, ceiling runs, wall turns, landings, phase seams, cargo stations, and exits.
2. Give each setting a physical rule that changes the route, then make an introduction, variation, reversal, combination, and mastery room for that rule.
3. Generate candidates from fixed seeds within one family, replay them with the real physics constants, and reject blocked pickups, unsafe starts, impossible exits, and repeated route shapes.
4. Hand-pick and tune accepted rooms in small batches on phone and desktop.
5. Add textile art, sound, and HUD cues that show the rule before the player reads a hint.

The first families are gravity routing, phase seams, cargo, water currents, dunes wind, canopy lift, low gravity, rain gusts, and frost momentum.
New nature settings should earn a place by changing movement or interaction, not by changing the backdrop alone.

## Campaign scope, 5 November 2026

The current target is 50 authored rooms across gravity, phase seams, cargo, water, dunes, canopy, rain, frost, low gravity, and a final recombination.
The authored data reaches that target, including marked falling bobbins, long moving-hem relays, vertical corner routes, and reverse entrances.
The room-clearance checks and scripted completion flow pass, but most rooms still need physics-driven route replays and manual phone and desktop playthroughs.
Revise or remove rooms that repeat a route shape or cannot be finished reliably with normal controls.
Keep the campaign count private until those route checks prove the target is worth keeping.

## Room revision, 5 November 2026

The authored rooms use different start and exit sides, ceiling routes, wall turns, cargo placements, environmental fields, and landing shapes.
Mint buttons require a lit seam and make the phase change part of the route.
The runner can push cargo into a corner before a gravity turn moves it to a ceiling mark.
The opening ceiling button and both cargo marks have physics-driven checks.
All room goals have a basic geometry clearance check.
The campaign still needs full manual playthroughs and route replays before release quality is claimed.

## Interaction pass, 5 November 2026

Needle Clock, Rainline, and the finale now use timed seams that open on Shift and close after a room-specific window.
The runner can stay inside a seam without being crushed when the window expires.
Forest, night, and finale rooms use bloom pads that launch the runner opposite the current pull.
The forest pad teaches the launch before a canopy lift, while later pads combine it with longer arcs or a timed seam.
The first phone Play opens a guide that illustrates movement, crouch, jump, and Shift with animated gestures.
The first compressed Web export transfers about 45.2 MB instead of the previous 83.4 MB on browsers with stream decompression, with the same art and a raw fallback.
The new mechanics have physics checks, but the full campaign still needs manual phone and desktop playthroughs.
