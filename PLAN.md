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
The Home screen plays a dance loop made from 32 poses.
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

- Play every route on desktop and phone, then revise jumps and hazards that fail the intended path.
- Expand the campaign with reviewed rooms and new natural settings.
- Give each setting distinct interaction patterns, art details, and audio.
- Add a composed score, transitions, and an ending sequence.
- Review accessibility, performance, and the Game Off submission.
