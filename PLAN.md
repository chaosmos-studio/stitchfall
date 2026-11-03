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
