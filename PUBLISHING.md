# Publishing Stitchfall on Google Play

Stitchfall's own values and progress. The account setup done once, and the answers shared by every Chaosmos
game, are in `docs/STUDIO_PLAY_SETUP.md` in the Games workspace (`~/Work/Weekend-Projects/Games/`). Section
numbers below point there. Stitchfall is not on the kit, but its Android build carries what the kit games
carry, in its own stitched look: AdMob ads with Google's consent message, the studio's house ads under them,
Firebase Analytics, Google Play Billing with the Supporter pack, Every room, the Wardrobe pack, the Complete pack
and six tips, Play's review card and in-app updates, and Google Play Games once its project is set up (below). So
its Play Console answers are the kit games' (2.4), except the content rating: its rooms have needles that make the
runner come apart. The browser build has none of it.

## The app

| | |
| --- | --- |
| Package | `com.shravangoswami.stitchfall` |
| App name | Stitchfall: Turn Gravity (until 8 November 2026 "Stitchfall: Gravity Platformer", still the AdMob app's name until AdMob is linked to the listing) |
| Play Console | https://play.google.com/console/u/0/developers/7125427200489329211/app/4976430851362506674/app-dashboard |
| Privacy policy | https://chaosmos.studio/stitchfall/privacy/ |
| Terms | https://chaosmos.studio/stitchfall/terms/ |
| Website (Store settings) | https://chaosmos.studio/stitchfall/support/ |
| Graphics | `assets/store/`, made by `tools/store_art.py` and `tools/make_icon.py` |
| Build | `.github/workflows/release-android.yml`, named by `CHANGELOG.md` |
| Permissions | `VIBRATE` and `INTERNET`, from the billing library `com.android.vending.BILLING`, and from the ads and Analytics libraries `ACCESS_NETWORK_STATE`, `AD_ID`, Play's install referrer and the few others they declare (the release workflow prints them all) |
| AdMob app | `ca-app-pub-3135321730568420~7142610841`, in `scripts/monetize.gd` and the project setting `admob/general/android/app_id` |
| AdMob units | Menu banner `ca-app-pub-3135321730568420/1826704985`, Between rooms (interstitial) `ca-app-pub-3135321730568420/5268302721`, Skip video (rewarded, reward item "Skip", amount 1) `ca-app-pub-3135321730568420/7089630792` |
| Firebase app | `1:774261168232:android:094cfdd352479536db03dd` in project `chaosmos-studio`, config in `google-services.json` |
| Upload key | `studio/release-keys/stitchfall-release.jks`, alias `stitchfall` (password in `stitchfall-key.properties`) |
| Upload key SHA-1 | `A2:FA:E1:F5:48:EF:20:4C:6B:D2:47:8D:B2:0A:53:7E:99:62:CA:F0` |
| Upload key SHA-256 | `92:07:54:DE:C6:AF:42:42:95:90:E7:C7:C3:EF:F2:55:04:FF:8B:B8:0A:F7:8A:9D:CD:A3:CF:6B:D0:70:B9:B9` |
| App signing key SHA-1 | `05:E6:CF:3F:36:C7:FA:01:FC:38:96:30:02:F1:22:FE:EB:1A:01:A1` (Play's key, in use) |
| App signing key SHA-256 | `99:6C:9E:23:21:FD:C1:51:9F:84:9C:66:98:10:40:17:ED:8D:59:12:20:23:F3:D6:52:94:1D:EE:A4:B3:AA:5D` |
| Other Play signing SHA-1s | `46:CB:4E:76:A2:B2:57:91:46:54:CE:06:92:F1:91:30:08:9F:B8:D9` and `1E:27:B3:78:C2:68:F8:2C:6E:0B:AF:0F:B2:E5:04:D4:1E:B4:12:5E`, the two more that App signing's Copy all certificate fingerprints lists (one is the "Quantum-ready" previous key) |
| What makes it unique (2.9) | You turn gravity a quarter turn at a time, and every small cloth room plays a trick that the turn gets you out of. |

## Builds and releases

- **CI** (`.github/workflows/ci.yml`), on every push and pull request: the tests (run with `--fixed-fps 60`, about
  a minute) and the browser build with its phone check (`tools/check_web.cjs`) side by side. A push to `main` that
  passes both publishes the browser build to `chaosmos.studio/stitchfall/play/`, writing only that folder of the
  studio site's `gh-pages` with the `SITE_DEPLOY_KEY` secret (a write deploy key on
  `chaosmos-studio.github.io`), as every other game does.
- **Android** (`.github/workflows/release-android.yml`): a new version at the top of `CHANGELOG.md` pushed to
  `main` releases by itself. The run tests, builds and signs the AAB and APK, makes the `v<version>` tag and the
  GitHub release, and uploads to the Play track named by the repository variable `AUTO_PLAY_TRACK`. That variable
  stays `none` until the first AAB is in Play Console and `ci-uploader` has the app, then becomes `alpha` (closed
  testing). Actions > Release Android > Run does the same by hand, with a dry run and a track to choose.
- The repository is public. Every action is pinned to a commit and Dependabot proposes updates monthly.
  `google-services.json` holds only Stitchfall's app and the Firebase key the build uses, which only works from
  the studio's signed apps. The web pack is checked to carry none of it. `SECURITY.md` says how to report a
  problem.

## Progress

- [x] Create the app (2.1)
- [x] Upload key, repo secrets and pin, `PLAY_SERVICE_ACCOUNT_JSON`
- [x] Release workflow dry run: signed AAB 1.0.0, code 10000, target 36
- [x] Store settings (2.3): Game > Arcade, tags Arcade, Brain teaser, Casual, Physics-based, Platformer, contact
- [x] App content: privacy policy, sign-in details, ads, government apps
- [x] App content, Ads: **Yes, my app contains ads**
- [x] App content: financial features, health, content rating, target audience, data safety, advertising ID,
  trader status ("You're all caught up", 7 November 2026)
- [x] AdMob app and its three units (above)
- [x] AdMob, Privacy & messaging: Stitchfall on both consent messages, with its privacy URL (1.3)
- [x] Firebase API keys (1.8): Stitchfall's upload SHA-1 (7 November) and its three Play signing SHA-1s (8 November)
  are on both Android keys, 20 app entries each. Builds use the Oct 10 key (`0dd826c1`), the first in
  `google-services.json`
- [x] The privacy page at chaosmos.studio/stitchfall/privacy/ covers ads, AdMob, consent and Analytics (live 7 November)
- [x] Closed testing track: Google Group `chaosmos@googlegroups.com`, feedback URL, all countries
- [x] Store listing words and graphics (2.2), saved. AI asset declaration: "Don't label assets", the owner's choice.
  The painted icon replaced the portrait one in the listing and on Play Games' properties (8 November)
- [x] First AAB (1.0.0, code 10000, from the v1.0.0 GitHub release) in Closed testing (2.8), and 17 changes sent
  for review with the listing (8 November). The browser tool cannot send a file over 10 MB, so the release page's
  `.aab` input was given the file from a server on `127.0.0.1` (play-console-browser's First AAB)
- [x] `ci-uploader` given this app in Users and permissions (3.4), 7 permissions with "Release apps to testing
  tracks", so later releases upload from the workflow (7 November). The repository variable `AUTO_PLAY_TRACK` is
  `alpha` (8 November)
- [x] Products (2.6): the ten below, active in 174 regions, made with `play_product.py` and the `ci-uploader` key
  (the `studio-ops` key has no access to this app), each copying Pyxis's prices for the same product (8 November)
- [ ] AdMob linked to the listing once it is public (3.1)
- [ ] Test purchase (2.7)
- [x] Play Games: Cloud project `chaosmos-stitchfall` and Play Games project `1647106634` made, properties saved,
  achievements, events, stats and the three leaderboards in as drafts. The OAuth consent screen is made (External,
  the game page, privacy and terms, the authorized domain `chaosmos.studio`), published by the owner on 8 November.
  Four Android OAuth clients and Play Games credentials, one per signing certificate above (the app signing key's
  is the one for new installs), and `play_games.json` committed (8 November). 1.0.0 was approved for Closed testing
  on 8 November, and 1.0.1, which carries Play Games, went up from the workflow and into review the same day.
  Achievements, leaderboards (formats, orders, limits, tamper protection), events and stats were read back as
  "Ready to publish". 1.0.1 was approved and the Play Games project published with the owner's go, and the listing's
  last bullet now names Play Games, sent for review (8 November)
- [ ] 12 testers opted in for 14 days (write the date): ____
- [ ] Applied for production (2.9)
- [ ] Live on Play (2.10)

## App content: the owner's answers

The kit games' answers (2.4), since the Android build now has their ads, consent and Analytics. Only the content
rating differs.

| Form | Answer |
| --- | --- |
| Ads | Yes, my app contains ads |
| Financial features | My app doesn't provide any financial features |
| Health apps | My app doesn't provide any health features |
| Data safety | As 2.4: **Yes**, encrypted in transit, no account, no deletion request. Exactly the four data types there (Approximate location, App interactions, Diagnostics, Device or other IDs), each Collected and Shared, not ephemeral, required, for Advertising or marketing, Analytics, and Fraud prevention, security, and compliance. |
| Advertising ID | Yes, for Advertising or marketing, Analytics, and Fraud prevention, security, and compliance |
| Target audience | As 2.4: 13-15, 16-17, 18 and over, and the listing could unintentionally appeal to children: **No**. An earlier draft of this guide said Yes for the build without ads, but with ads a Yes puts the app under the Families ads rules, which the studio's AdMob setup (not child-directed) does not meet. Keep the listing's words and pictures for a teen and adult audience. |
| Trader status | Trader, as every Chaosmos app, with the terms URL above |

**Content rating:** Start, email `hello@chaosmos.studio`, category **Game**. The one difference from the kit games
is violence: when the runner touches needles, a pin or a moth, they come apart into threads and buttons and sew
themselves back together a moment later, with no blood and no harm to anyone real.

| Section | Answer |
| --- | --- |
| Violence, Blood, or Gory Images | **Yes**, then only the mildest kind the form offers: cartoon or fantasy violence against a non-realistic character, no blood, no gore |
| Fear | No |
| Sexuality, Suggestiveness, or Dating Games | No |
| Gambling Themes, Simulated Gambling, or Real Gambling | No |
| Language | No |
| Controlled Substance | No |
| Crude Humor | No |
| Digital Purchases, Cash Convertible Rewards, or NFTs | **Yes**, tick only **Purchases of digital goods** |
| Random items, loot boxes, chance-based purchases | No |
| Players trade items for real money | No |
| Users interact or exchange content | No |
| Shares the user's precise location | No |
| Nazi symbols, Korea's national identity, terrorism, crimes | No |

Expected result: ESRB Everyone, PEGI 3 or 7, with an "In-app purchases" notice.

## Store listing (2.2)

| Field | Text |
| --- | --- |
| App name (30) | Stitchfall: Turn Gravity |
| Short description (80) | Turn the whole room over and sew your way past every trick. |

Full description:

> Stitchfall is a platformer in a world sewn from cloth. Run, jump and turn gravity a quarter turn at a time. Walls become floors, the ceiling becomes the way across, and every button you collect brings a room's zipper closer to opening.
>
> Every room plays a trick on you. The landing grows needles as you jump. The zipper runs off across the ice. The patch that looks sewn down was only pinned. Each trick has a tell, so the first fall makes you laugh and the second try gets you through.
>
> • Small rooms you see whole, with instant retries
> • Chapters that each turn one idea into five jokes: falling pins, lit seams, needle moths, a weighted patch, water, wind, canopy drafts, a night quilt, rain and frost
> • Up to three stars a room: finish it, finish it without coming apart, finish it fast
> • Flowers bank the buttons you carry and become the place you come back to
> • A Wardrobe of runners, trails, unravel styles, buttons and fabrics. Stars open the trails, unravels and buttons, and the Wardrobe pack adds every runner and fabric
> • Textile art and music made for this game
> • Plays offline. Sign in with Play Games for achievements, leaderboards and progress that follows you to a new phone

Screenshots (phone, 7-inch and 10-inch tablet, the same eight 1920 by 1080 images from `tools/store_art.py`), in
this order:

1. `01_turn`: Treetops in the Green Canopy, the runner walking the ceiling beside a pin.
2. `02_trick`: Runaway on the frost, the zipper gone home across the ice while the runner stands at the flower.
3. `03_night`: Hang Time on the night quilt, a floaty jump with its dotted arc over the moon.
4. `04_water`: Deep End, the runner jumping out of the pool toward a button.
5. `05_wind`: Tailwind in the dunes, a jump carried by the wind.
6. `06_stars`: The Sewn card with three stars, the time and the par.
7. `07_wardrobe`: The Wardrobe's trails, with the Seam Runner and the Google Play build's pack button.
8. `08_home`: Home in the Google Play build, the runner dancing in the embroidered woodland.

The feature graphic is the woodland with the name in its stitched pocket. Play Games' copy of it must be 1 MB or
less, so it takes `build/play_games/feature_graphic_1024x500.jpg`.

## Products (2.6)

Monetize with Play > Products > **One-time products** > Create one-time product, once for each row below, with
the settings every product shares in 2.6 (tax category Digital app sales, purchase option `buy`, all countries,
the price by Set prices > Bulk edit, then Activate). The ids must be exactly these, and they are permanent. The
four packs are acknowledged by the game and kept for good, the Complete pack holding the other three. The tips
are consumed after each purchase so they can be given again. The ids live in `scripts/monetize.gd`, the Shop page
lists them (Home and the Wardrobe lead to it), and the browser build sells nothing.

| Product ID | Name | Price | Description |
| --- | --- | --- | --- |
| `supporter` | `Supporter pack` | US$2.99 | Turns off the banner and the ads between rooms in Stitchfall for good, and makes skipping a room free. One purchase, yours to keep, and it helps me make the next game. |
| `all_levels` | `Every room` | US$1.99 | Opens every room at once, so you can play them in any order. Stars are still earned by sewing each room. One purchase, yours to keep. |
| `wardrobe` | `Wardrobe pack` | US$2.99 | Every runner and fabric in the Wardrobe: Patch, Bobbin, Tam, Moth, Fennel and Indigo, and six room fabrics. One purchase, yours to keep. |
| `complete` | `Complete pack` | US$6.99 | The Supporter pack, Every room and the Wardrobe pack in one, for less than buying them apart: no banner or ads between rooms, free skips, every room open, every runner and fabric. |
| `tip_1` | `Small tip` | US$0.99 | A thank-you to the maker of this game. It opens nothing, but it helps make the next game and more rooms. Tip as often as you like. |
| `tip_2` | `Tip` | US$1.99 | A thank-you to the maker of this game. It opens nothing, but it helps make the next game and more rooms. Tip as often as you like. |
| `tip_5` | `Big tip` | US$4.99 | A thank-you to the maker of this game. It opens nothing, but it helps make the next game and more rooms. Tip as often as you like. |
| `tip_10` | `Generous tip` | US$9.99 | A thank-you to the maker of this game. It opens nothing, but it helps make the next game and more rooms. Tip as often as you like. |
| `tip_20` | `Very generous tip` | US$19.99 | A thank-you to the maker of this game. It opens nothing, but it helps make the next game and more rooms. Tip as often as you like. |
| `tip_50` | `Huge thank you` | US$49.99 | A thank-you to the maker of this game. It opens nothing, but it helps make the next game and more rooms. Tip as often as you like. |

The Complete pack is less than its parts bought apart (US$7.97). Every description fits Play's 200 characters.
Every price is Pyxis's for the same product in each region (the Wardrobe pack takes the Supporter pack's), so the
studio's games cost the same: INR 280 for the Supporter and Wardrobe packs, 190 for Every room, 650 for Complete.

To test, after 2.7, in the game installed from Play:

1. Shop > Supporter pack with the test card: the banner on Levels goes, Next brings no more ads between rooms,
   and the pause page's skip is free.
2. Shop > Every room: every locked tile on Levels opens.
3. Wardrobe > Wardrobe pack: every runner and fabric opens.
4. Tip twice in a row: the Shop thanks you for both.
5. Uninstall, reinstall, open: the packs come back by themselves. Restore in the Shop asks again.
6. The Complete pack shows only while none of its packs is owned, so test it on a fresh test account or after a
   refund.

## Ads (AdMob, 1.2 to 1.5)

The app and its three units are made (ids in the table at the top). Each debug build loads Google's test units
whatever `monetize.gd` says. Until AdMob approves the account, and whenever it has no ad to give, the house ads
stand in: a banner for another Chaosmos game, and a quick game in place of the skip video.

- The banner: Levels, Wardrobe, Settings, About, Credits and Stats only, once 3 rooms are sewn, a 320 dp strip
  centred at the foot of the screen, 48 dp clear of the screen's edge. The page above it shrinks so every button
  keeps 40 dp clear of it.
- Between rooms: only from Next on the clear card, from 12 rooms sewn, once every 4 clears, 4 minutes after any
  full-screen ad and 3 after launch, never when Next leads to a chapter's title card, never during play.
- The skip video: offered on the pause page after 5 unravels in a room, for a room whose next room is still shut.
  Declining never blocks play, and with nothing to play the room just stays.
- Register your phone as a test device (1.5) before installing a release build, and never tap a real ad.

## Play Games

Stitchfall has Google Play Games the way the kit games have it (game-making-skills' `puzzle-kit.md`, Play Games,
and `docs/PLAY_GAMES.md`), in its own words: a quiet sign-in at launch, three leaderboards, twelve achievements,
Game Stats and a cloud save, so a new phone picks up the old one's progress. Nothing ever waits on it.

It is all off until `play_games.json` is at the project's root. Without it the Android build carries no Play
Games library, no SDK and no project id in its manifest (the SDK would stop an app whose manifest names no
project), and the Stats page shows no Play Games buttons. The browser build never carries any of it. So builds
ship without Play Games until the setup below is done and `play_games.json` is committed.

| File | What it does |
| --- | --- |
| `addons/play_games/` | The plugin, unchanged from the kit games: GodotPlayGameServices 3.4.0's two patched AARs (no uncaught exception handler, Play Games SDK 22.1.0, Game Stats added) and the studio's `plugin.gd`, which adds the AAR, the SDK, Gson and the manifest's `APP_ID` only when `play_games.json` exists |
| `play_games/catalog.json` | The leaderboards, achievements, Game Stats events and stats below, in the kit's format |
| `scripts/play_games.gd` | `StitchfallPlayGames`: reads the catalog and the ids, measures progress for the achievements and boards, starts the backend on Android only |
| `scripts/android/play_games.gd` | The backend: calls the plugin's Android singleton directly, unlocks and steps achievements, submits scores, sends Game Stats events, loads and saves the cloud copy |
| `scripts/cloud_save.gd` | `StitchfallCloudSave`: `progress.cfg` as text in one Saved Games snapshot, merged key by key on sign-in |
| `tools/play_games_import.py` | Writes Play Console's import files to `build/play_games/`, every icon drawn in Stitchfall's colours |
| `tools/play_games_ids.py` | Turns Play Console's Get resources XML into `play_games.json` |

**Sign-in.** Play Games signs the player in by itself at launch. Nothing asks again unless they tap Leaderboards or
Achievements on the Stats page (Settings, Stats), which signs in first and then opens Play Games' own page.
Scores and achievements made before sign-in wait in the progress itself: sign-in sends them all.

**The cloud save.** The progress file goes up 15 seconds after a room is sewn or skipped, on pause and on Home,
and at once when the app goes to the background with a save waiting. On sign-in the copy is read and joined
with the phone's, key by key: each room's best stars and best time, every room skipped, sewn unbroken or sewn
quick, and the larger of each lifetime count (unravels, turns, buttons, buttons banked, time in the rooms). What
is worn, the settings and where Play's review card stands stay the phone's own, and the packs and tips come from
Google Play. Settings' Reset writes the reset progress over the cloud copy at once, so the next launch does not
bring the old progress back.

### The catalog

Leaderboards, in this order, each with its icon from `build/play_games/` and tamper protection on:

| Leaderboard | Format | Order | Limits | Score |
| --- | --- | --- | --- | --- |
| Stars | Numeric | Larger is better | 1 to 10,000 | Every star earned, the best of each room |
| Rooms sewn | Numeric, unit room and rooms | Larger is better | 1 to 10,000 | Different rooms sewn |
| Plain Linen speedrun | Time | Smaller is better | 1,000 to 3,600,000 ms (1 second to 1 hour) | The sum of the five best times in Plain Linen, sent once all five are sewn |

Achievements, all Revealed, 500 points of Play's 1,000 (12 of them). One with a goal past one is incremental,
with the goal as its steps, so Play Games shows how far along a player is.

| Achievement | Description | Points | Type |
| --- | --- | --- | --- |
| First stitch | Sew your first room. | 5 | Standard |
| Getting the knack | Sew 10 rooms. | 20 | Incremental, 10 steps |
| Good with a needle | Sew 25 rooms. | 40 | Incremental, 25 steps |
| Master tailor | Sew 50 rooms. | 100 | Incremental, 50 steps |
| Whole cloth | Sew every room of a chapter. | 20 | Standard |
| Patchwork quilt | Sew every room of five chapters. | 75 | Incremental, 5 steps |
| Neat work | Earn all three stars in 10 rooms. | 60 | Incremental, 10 steps |
| Seamless | Sew each room of a chapter without unravelling. | 60 | Standard |
| Quick fingers | Sew a room inside its par time. | 20 | Standard |
| Safe keeping | Bank 15 buttons at flowers. | 35 | Incremental, 15 steps |
| Head over heels | Turn the room 500 times. | 40 | Incremental, 500 steps |
| Hanging by a thread | Unravel 100 times. The rooms enjoyed every one. | 25 | Incremental, 100 steps |

None of them moves with a purchase, an ad or the Wardrobe: a skipped room is not sewn, and Every room opens rooms
without sewing them. The tests hold every goal to what the rooms in the code can give, so a chapter cut later
cannot leave one out of reach.

Game Stats events:

| Event | Properties | Sent |
| --- | --- | --- |
| `roomCompleted` | `room` (INT64, numbered as players see it), `stars` (INT64), `unravels` (INT64), `time` (DURATION, an hour at most) | Each room sewn, replays included |
| `progressUpdate` | `currentProgress` (INT64) | Different rooms sewn, at sign-in and whenever it grows |

Game Stats, every one Increasing:

| Stat id | Name | From | Aggregation | Notes |
| --- | --- | --- | --- | --- |
| `rooms_sewn` | Rooms sewn | `roomCompleted.room` | COUNT | The competitive stat, limits 0 to 600 an hour |
| `stars_collected` | Stars collected | `roomCompleted.stars` | SUM | |
| `three_star_rooms` | Three-star rooms | `roomCompleted.stars` | COUNT where stars = 3 | |
| `unravels` | Times unravelled | `roomCompleted.unravels` | SUM | |
| `time_in_rooms` | Time in the rooms | `roomCompleted.time` | SUM | Format COMPONENT_TEXT, unit MINUTES |
| `different_rooms` | Different rooms sewn | `progressUpdate.currentProgress` | Progression | |

Google's rules for stats hold: none moves with purchases or ads, none is plain app use, none sits behind a gate.

### Setting it up in Play Console

All signed in as the studio account, in Play Console and Google Cloud (never gcloud on this machine).

1. **A Cloud project of its own**, `chaosmos-stitchfall` (Chaosmos Stitchfall). Google links a Cloud project to
   only one Play Games project, so `chaosmos-studio` stays for Firebase and the service accounts.
2. **Play Games Services, Setup and management, Configuration**: create a new Play Games project on that Cloud
   project. Properties: display name Stitchfall, the store's short description, category Arcade, **Saved games
   on** (it can never be turned off once published), `assets/store/play_store_icon_512.png` and
   `assets/store/feature_graphic_1024x500.png`, next-generation player IDs on, Recall off.
3. **The imports**: `python3 tools/play_games_import.py`, then
   - Achievements, Import achievements: `build/play_games/achievements.zip`, then Save as draft.
   - Game Stats, Add an event, Import via CSV: `build/play_games/PlayerGameEvent.csv`.
   - Game Stats, Add a stat, Import via ZIP: `build/play_games/game_stats.zip`.
4. **The three leaderboards by hand**, in the catalog's order, with the names, formats, orders and limits in the
   table above, each with its icon (`build/play_games/leaderboard_stars.png`, `leaderboard_rooms.png`,
   `leaderboard_linen.png`) and tamper protection on. Rooms sewn's unit is room (one) and rooms (other).
5. **The ids**: Achievements, Get resources, saved as `build/play_games/games-ids.xml`, then
   `python3 tools/play_games_ids.py build/play_games/games-ids.xml`, which writes `play_games.json` and stops if
   any name in the catalog is missing from the XML.
6. **The OAuth consent screen** on `chaosmos-stitchfall`: External, app name Stitchfall, support email
   `hello@chaosmos.studio`, home page https://chaosmos.studio/stitchfall/, privacy policy
   https://chaosmos.studio/stitchfall/privacy/, authorized domain `chaosmos.studio`, no logo (a logo needs
   Google's verification), then Publish app.
7. **Android OAuth clients** on `chaosmos-stitchfall`, package `com.shravangoswami.stitchfall`, one per
   certificate Play could sign with: the app signing key (its SHA-1 on Play Console's App signing page), any
   earlier key listed there, and the upload key (SHA-1 in the table at the top). Add each as a Play Games
   credential (Android), anti-piracy off.
8. **Testers**: add your own account on the Play Games project's Testers page, so a build carrying
   `play_games.json` signs in before the project is published.

### What to publish, and when

- **Now**: steps 1 to 8. Nothing is public, and Stitchfall builds still carry no Play Games while
  `play_games.json` is not committed.
- **With the release that carries `play_games.json`**: commit it, add a CHANGELOG line about Play Games, release.
  Before Review and publish, read back everything that locks: each achievement's type and initial state (and that
  it can never be deleted), each leaderboard's order and limits, Saved games, and each stat's id, event, property,
  aggregation, direction, format and unit. Then Review and publish the Play Games project as the release goes
  out. Publishing also needs the category and the feature graphic on Properties: the publishing page names what is
  missing.
- **Before that release goes live**: the privacy page at chaosmos.studio/stitchfall/privacy/ says what the kit
  games' page says about Google Play Games (the `playGames` list in the studio site's
  `src/pages/[game]/privacy.astro`), in Stitchfall's terms: the three boards, the achievements, the room events
  and the cloud save. The store listing's last bullet names Play Games, as Pyxis's does. Both done for 1.0.1.
