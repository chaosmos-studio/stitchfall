# Palewheel design

## Intent

The player is a gravity mechanic trying to restart a failing orbital engine.
The signature move turns gravity by a quarter turn.
That turn also trades solid and ghosted bridges, pushes loose cargo, pauses moving drones, and sends a visible pulse across the chamber.
The player collects light to open each exit, with beacons preserving progress after a hit.

## Direction chosen on 3 November 2026

Shravan chose the name Palewheel and gave full creative freedom after rejecting the previous game's assets, look, UI, and experience.
The first art pass was too ornate and felt like fantasy, so Shravan redirected the project toward comics, manga, and anime.
The working assumptions are a light default palette, crisp sci-fi machinery, a limited ink/cyan/coral palette, and an expressive gravity mechanic as the visual anchor.
The current pass uses held drawings for idle, running, takeoff, flight, landing, and gravity turns.
The camera follows the mechanic through a full-screen room.
The airlocks, light cells, beacons, and cargo use painted sprite art.
The first world expansion adds flooded machinery, desert relay, and reclaimed forest rooms with distinct painted backgrounds and movement fields.
Floodwater slows and buoys the pilot, dune wind pushes across open jumps, canopy drafts lift upward, and the exterior ring lengthens each low-gravity jump.
Slide left or right to walk, swipe up to jump, swipe down to crouch, and tap the playfield to turn gravity.
The title screen has one start button and a short control legend.
Jump height follows the hold time, and gravity turns preserve momentum while the character art rotates into the new orientation.
Rooms now continue without an interstitial menu.
Web preview links can open a selected room for art and route review.

## Structure

`scripts/level_data.gd` owns authored room geometry and goals.
`scripts/game_controller.gd` owns progress, pickups, hazards, checkpoint state, and gravity shifts.
`scripts/player.gd` owns courier movement and visual motion.
`scripts/cargo.gd` applies gravity to the movable block.
`scripts/sentry.gd` owns watcher patrol, collision, and freeze timing.
`scripts/world_view.gd` draws the engine chamber and gameplay objects over a distinct painted anime background for each room.
`scripts/hud.gd` owns status, hints, and panels.

## Next milestones

- Expand the campaign toward more than 100 reviewed rooms across distinct worlds, with route audits before each pack ships.
- Add more world rules that change movement and puzzles.
- Tune routes, movement, and touch controls through real phone play.
- Add chambers with distinct puzzle patterns that build on turning, cargo, bridges, and watcher timing.
- Add ambient music, richer motion, transition effects, and an ending sequence.
- Review accessibility, performance, and the Game Off submission build.
