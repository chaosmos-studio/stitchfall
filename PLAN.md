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
Each room's name appears briefly when the room begins.
The HUD cloth palette follows the setting.
The Home screen plays the runner's front-facing dance sheet.
Its sewn woodland stage has a quiet fabric pocket for the menu.
The title is the logo's felt label (`assets/art/logo_label.png`, from `tools/make_logo.py`), headings use Darn Display, reading text uses Darn UI, the main menu uses Threadline Woven, and other stitched controls use Threadline Satin.
An original music loop accompanies the dance and continues into play.
Level Select shows one chapter a page, its five rooms as textile patches.
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

`scripts/level_data.gd` lists the chapters in order, and each chapter's rooms and the routes that prove them are in `scripts/chapters/`.
`scripts/game_controller.gd` owns progression, pickups, flowers, and shifts.
`scripts/player.gd` owns movement, environmental forces, and sprite animation.
`scripts/cargo.gd` and `scripts/sentry.gd` own moving obstacles.
`scripts/world_view.gd` draws the textile world.
`scripts/hud.gd`, `scripts/stitched_button.gd`, `scripts/button_meter.gd`, and `scripts/stitch_border.gd` draw the interface.

## Monetization

The Android build carries everything the kit games ship, rebuilt in Stitchfall's own stitched look rather than taken from the kit.
The browser build has none of it: no ads, no shop, no analytics, every Wardrobe piece free and every skip free.

- Ids: `scripts/monetize.gd`. AdMob on, with the studio's house ads filling in whenever AdMob has nothing, and Google's test units in every debug build.
- Pacing: `scripts/ad_pacing.gd`, the kit's numbers. A banner from 3 rooms sewn, on the Levels, Wardrobe, Credits and Stats pages only, never on Settings (Privacy and Reset) or About, as in the kit games. Those pages shrink so every button keeps 40 dp above it. An ad between rooms only from Next on the clear card, from 12 rooms sewn, once every 4 clears, 4 minutes after any full-screen ad and 3 after launch, and never when Next leads to a chapter's title card.
- Skip this room: offered on the pause page once the runner has unravelled 5 times in the room and the next room is still shut, and from then on a "Stuck? Pause" tag sits beside the pause button (a hint, never a button, so it is never tapped mid-jump). A video, or a quick game of the studio's in its place, pays for it, and the line says a Supporter skips free. It is free for a Supporter and in the browser. The skipped room keeps no stars.
- Products: `supporter` (no banner or ads between rooms, free skips), `all_levels` (every room open), `wardrobe`, `complete` (all three) and six tips, sold on the Shop page (`hud.gd`) through `scripts/android/play_billing.gd`. The table is in `PUBLISHING.md`. Every purchase, a tip included, opens its own page first (`show_offer` in `hud.gd`): what it is for and holds, Play's price on the button, the Complete pack's saving worked out from Play's own prices (`StitchfallShop.saving()`, shown only when all four are priced in one currency), and a note that Google Play's sheet comes next. Play draws that sheet itself and holds it upright on many phones, even over a landscape game, and no app can turn it, so the note says so. The ways to the Shop, as in the kit games: Home, Settings, the Wardrobe, a shut room on Levels (it names the room that opens it and offers Every room), and the end of the campaign for a player without the Supporter pack. Nothing offers it after an ad or during play. Google Play's answers show on the page they belong to, or as a toast on any other.
- Consent and analytics: Google's UMP through the AdMob plugin, Privacy choices in Settings when UMP asks for it, and Firebase Analytics counting only where no consent is needed (`scripts/analytics.gd`): room starts, clears with stars, time and unravels, unravels, skips, purchases and ads shown.
- Play's review card at 10 and 25 rooms sewn, each as Next leaves a chapter's last room, and in-app updates offered on Home or Levels (`scripts/play_core.gd`).
- Google Play Games as the kit games have it, off until `play_games.json` exists: a quiet sign-in, the Stars, Rooms sewn and Plain Linen speedrun boards, twelve achievements, Game Stats and a cloud save (`scripts/play_games.gd`, `scripts/android/play_games.gd`, `scripts/cloud_save.gd`, `play_games/catalog.json`), with Leaderboards and Achievements on the Stats page. The console setup is in `PUBLISHING.md`.
- `scripts/ads.gd` places it all, `scripts/house_ads.gd`, `house_banner.gd`, `house_card.gd` and `house_games.gd` are the house ads, and `scripts/android/` holds what only the Android build may load.

## Campaign and presentation checklist

The current rooms introduce movement, gravity, phase bridges, weighted patches, water, wind, canopy lift, low gravity, rain, and ice.

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
- [ ] Design room families around a single movement idea: ceiling runs, cargo transport, water ascent, wind carry, canopy lift, low-gravity arcs, rain reversal, and ice braking.
- [ ] Add setting families beyond the current route, with a visible interaction and sound identity for each.
- [ ] Build deterministic candidate generation with protected start and exit zones, reachable collectibles, hazard clearance, and repeated-layout rejection.
- [ ] Replay generated candidates with the actual movement constants, reject unreachable routes, and order accepted rooms by measured difficulty.
- [ ] Play every family on desktop and phone, tune flowers, then expand the campaign in reviewed batches.
- [ ] Finish transitions, ending, accessibility, performance, and Android export.
- [x] Submit the playable public build to Game Off with the source repository and AI disclosure.

## Surprise and mechanism pass, 5 November 2026

[Level Devil's official site](https://playleveldevil.com/) presents disappearing floors, falling blocks, shifting doors, and immediate retries as its core pacing.
Stitchfall takes the pacing idea, then uses visible cloth machinery that reacts to a gravity shift.
A trap must show its track or anchor before it moves, give the player a short wind-up, and restart quickly after a hit.

On a hit, the runner's drawn fabric image separates into patches and thread for a short beat, then reappears at the start or the last flower touched.
This is a non-graphic cloth effect with no blood or human injury detail.
Before an Android release, complete the current [Google Play content rating questionnaire](https://support.google.com/googleplay/android-developer/answer/9859655) for the actual build and review its [violence policy](https://support.google.com/googleplay/android-developer/answer/9878810).
The [itch.io quality guidelines](https://itch.io/docs/creators/quality-guidelines) require the listing and AI disclosure to match the game.

- [x] Add a cloth-scatter hit animation and a timed retry.
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

## Room design rules, 4 November 2026

A room must change the route the player has to understand, not only its setting or its hazards.
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
World art, sound, hazard silhouettes, and HUD materials should explain the physical rule without a written hint.

The generator should assemble authored route segments and vary their spacing, orientation, safe landing area, and optional detours from a saved seed.
It should reserve start, exit, and flower clearances before placing hazards.
A deterministic fixed-step replay using the game's movement values should prove at least one exit route and record jumps, shifts, airtime, retraces, and near misses.
Compare route signatures and geometry after translation or reflection to reject repetitions.
Rank candidates within a family, then playtest the chosen rooms on phone and desktop before releasing them.
Automated reachability is a gate, while human playtesting decides whether a route is readable and fun.

## Campaign production order

1. Build a room grammar from authored entrances, ceiling runs, wall turns, landings, phase seams, cargo stations, and exits.
2. Give each setting a physical rule that changes the route, then make an introduction, variation, reversal, combination, and mastery room for that rule.
3. Generate candidates from fixed seeds within one family, replay them with the real physics constants, and reject blocked pickups, unsafe starts, impossible exits, and repeated route shapes.
4. Hand-pick and tune accepted rooms in small batches on phone and desktop.
5. Add textile art, sound, and HUD cues that show the rule without a written hint.

The first families are gravity routing, phase seams, cargo, water currents, dunes wind, canopy lift, low gravity, rain gusts, and frost momentum.
New nature settings should earn a place by changing movement or interaction, not by changing the backdrop alone.

## Campaign scope, 7 November 2026

The campaign is twelve chapters of five rooms, each built and proved by its routes as `LEVELS.md` describes.
The 50 older wide rooms are gone, and with them the parts only they used: moving hems, cutters, chains, pulley weights, springs, timed seams, bloom pads, mint buttons and thorn strips.
Keep the campaign count private.

## Interaction pass, 5 November 2026

The first phone Play opens a guide that illustrates movement, crouch, jump, and Shift with animated gestures.
The web build streams a gzip-compressed engine on browsers with stream decompression, with a raw fallback.
