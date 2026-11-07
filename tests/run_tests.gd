extends SceneTree

# Run: godot --headless --path . -s res://tests/run_tests.gd
# CI greps for "0 failed", so keep that wording.

const InputMapGen: GDScript = preload("res://tools/make_input_map.gd")
const ADMOB_SETTINGS: GDScript = preload("res://addons/admob/internal/services/project_settings_service.gd")
const APP_ID_SETTING: String = "admob/general/android/app_id"
const PLUGINS: PackedStringArray = [
	"res://addons/GodotGooglePlayBilling/plugin.cfg",
	"res://addons/admob/plugin.cfg",
	"res://addons/godotx_firebase/plugin.cfg",
	"res://addons/firebase_build/plugin.cfg",
	"res://addons/play_core/plugin.cfg",
	"res://addons/shrink_build/plugin.cfg",
	"res://addons/play_games/plugin.cfg",
]

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	StitchfallProgress.path = "user://test_progress.cfg"
	_test_progress()
	_test_wardrobe()
	_test_android_build()
	_test_plugins_and_ids()
	_test_shrink_rules()
	_test_pacing()
	_test_products()
	_test_consent_rule()
	_test_play_core()
	_test_play_games_catalog()
	_test_game_stats()
	_test_play_games_build()
	_test_cloud_save()
	await _test_play_games_backend()
	await _test_play_games_pages()
	await _test_house_ads()
	await _test_back_gesture()
	await _test_moments()
	await _test_unravel_holds_the_zipper()
	await _test_skip()
	await _test_next_brings_the_ad()
	await _test_banner_keeps_clear()
	await _test_shop_page()
	_test_input_map_is_wired()
	_test_orientation_is_an_int()
	await _test_movement_feel()
	await _test_environment_forces()
	await _test_gesture_controls()
	await _test_fraying_ledge()
	_test_room_clearance()
	await _test_screen_routes()
	await _test_stitchfall_playthrough()
	print("\n==== TESTS: %d passed, %d failed ====" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _test_android_build() -> void:
	var version: PackedStringArray = StitchfallHud.version_name().split(".")
	_check("the version shown is CHANGELOG.md's newest x.y.z", version.size() == 3 and Array(version).all(func(part: String) -> bool: return part.is_valid_int()))
	var presets: ConfigFile = ConfigFile.new()
	presets.load("res://export_presets.cfg")
	var found: Dictionary = {}
	for section: String in presets.get_sections():
		if not section.ends_with(".options"):
			found[str(presets.get_value(section, "name"))] = section
	_check("there are Web, Android AAB and Android APK presets", found.has("Web") and found.has("Android AAB") and found.has("Android APK"))
	var web: String = found.get("Web", "")
	var web_out: String = str(presets.get_value(web, "exclude_filter"))
	_check("the web build leaves every plugin, the Android scripts and the Firebase config out, and carries the changelog", "addons/*" in web_out and "scripts/android/*" in web_out and "google-services.json" in web_out and "CHANGELOG.md" in str(presets.get_value(web, "include_filter")))
	for name: String in ["Android AAB", "Android APK"]:
		var options: String = "%s.options" % found.get(name, "")
		var out: String = str(presets.get_value(found.get(name, ""), "exclude_filter"))
		_check("%s is com.shravangoswami.stitchfall, Gradle-built for API 36" % name, presets.get_value(options, "package/unique_name") == "com.shravangoswami.stitchfall" and presets.get_value(options, "gradle_build/use_gradle_build") == true and presets.get_value(options, "gradle_build/target_sdk") == "36")
		_check("%s may use the network for ads, and vibrates, and carries the changelog" % name, presets.get_value(options, "permissions/vibrate") == true and presets.get_value(options, "permissions/internet") == true and "CHANGELOG.md" in str(presets.get_value(found.get(name, ""), "include_filter")))
		_check("%s builds Firebase Core and Analytics only, starting with collection off" % name, presets.get_value(options, "firebase/enable_core") == true and presets.get_value(options, "firebase/enable_analytics") == true and presets.get_value(options, "firebase/enable_crashlytics") == false and presets.get_value(options, "firebase/enable_messaging") == false and presets.get_value(options, "firebase/privacy_safe_defaults") == true and presets.get_value(options, "firebase/android_config_file") == "res://google-services.json")
		var left_out: bool = true
		for pattern: String in ["addons/admob/gdscript/sample/*", "addons/admob/csharp/*", "addons/admob/docs/*", "addons/admob/skills/*", "addons/admob/assets/*", "addons/admob/internal/mock/*", "addons/godotx_firebase/*", "addons/firebase_build/*", "addons/shrink_build/*", "addons/play_core/*"]:
			left_out = left_out and pattern in out
		_check("%s leaves the plugins' samples, docs and editor-only scripts out" % name, left_out)
	_check("the AAB preset builds an app bundle", presets.get_value("%s.options" % found.get("Android AAB", ""), "gradle_build/export_format") == 1)
	_check("back does not quit the game by itself", not ProjectSettings.get_setting("application/config/quit_on_go_back", true))


# Every plugin enabled, through tools/configure_android.gd, with the binaries a build needs already in place, and
# the manifest's AdMob app id the one the code names. The plugin falls back to Google's test app when the setting
# is unset, as this mirrors.
func _test_plugins_and_ids() -> void:
	var enabled: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	var configure: String = FileAccess.get_file_as_string("res://tools/configure_android.gd")
	for plugin: String in PLUGINS:
		_check("%s is enabled, and configure_android keeps it so" % plugin, enabled.has(plugin) and configure.contains(plugin) and FileAccess.file_exists(plugin))
	_check("the AdMob and billing binaries are in place, so no build downloads them",
		FileAccess.file_exists("res://addons/admob/android/bin/ads/libs/poing-godot-admob-ads-release.aar")
		and FileAccess.file_exists("res://addons/admob/android/bin/package.gd")
		and FileAccess.file_exists("res://addons/GodotGooglePlayBilling/bin/release/GodotGooglePlayBilling-release.aar"))
	for module: String in ["firebase_core", "firebase_analytics"]:
		for build: String in ["release", "debug"]:
			_check("android/%s/%s.%s.aar is in place" % [module, module, build], FileAccess.file_exists("res://android/%s/%s.%s.aar" % [module, module, build]))
	_check("the Play Core helper is there to build in", FileAccess.file_exists("res://addons/play_core/PlayCore.java"))
	var services: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://google-services.json"))
	var packages: Array[String] = []
	for client: Variant in services.get("client", []):
		packages.append(String(((client as Dictionary)["client_info"] as Dictionary)["android_client_info"]["package_name"]))
	_check("google-services.json has the Stitchfall app", packages.has("com.shravangoswami.stitchfall"))
	var setting: String = ProjectSettings.get_setting(APP_ID_SETTING, ADMOB_SETTINGS.ANDROID_DEFAULT_APP_ID)
	_check("the manifest's AdMob app id is StitchfallMonetize.APP_ID (%s)" % setting, setting == StitchfallMonetize.APP_ID)
	var app: RegEx = RegEx.create_from_string("^ca-app-pub-\\d{16}~\\d{10}$")
	var unit: RegEx = RegEx.create_from_string("^ca-app-pub-\\d{16}/\\d{10}$")
	_check("the app id is an AdMob app id", app.search(StitchfallMonetize.APP_ID) != null)
	var units: Array[String] = [StitchfallMonetize.BANNER_ID, StitchfallMonetize.INTERSTITIAL_ID, StitchfallMonetize.REWARDED_ID]
	for id: String in units:
		_check("%s is an AdMob unit id" % id, unit.search(id) != null)
	_check("each placement has its own unit", units[0] != units[1] and units[1] != units[2] and units[0] != units[2])
	var google_test: String = "ca-app-pub-3940256099942544"
	_check("the release ids are the studio's, not Google's test publisher", not StitchfallMonetize.APP_ID.begins_with(google_test) and not units.any(func(id: String) -> bool: return id.begins_with(google_test)))
	# Only a phone ever runs these, so a mistake in one would otherwise show first on a phone.
	for path: String in _scripts("res://scripts/android"):
		var script: GDScript = load(path) as GDScript
		_check("%s compiles against the plugins" % path.get_file(), script != null and script.can_instantiate())
	var admob: String = FileAccess.get_file_as_string("res://scripts/android/admob.gd")
	_check("a debug build always asks for Google's test units", admob.contains("OS.is_debug_build()") and admob.contains("TEST_BANNER if debug") and admob.contains("TEST_INTERSTITIAL if debug") and admob.contains("TEST_REWARDED if debug"))
	_check("ads are rated PG at most", admob.contains("MAX_AD_CONTENT_RATING_PG"))
	_check("the products are the kit's ids", StitchfallMonetize.SUPPORTER_ID == "supporter" and StitchfallMonetize.LEVELS_ID == "all_levels" and StitchfallMonetize.WARDROBE_ID == "wardrobe" and StitchfallMonetize.COMPLETE_ID == "complete" and StitchfallMonetize.TIP_IDS == PackedStringArray(["tip_1", "tip_2", "tip_5", "tip_10", "tip_20", "tip_50"]))


# R8 strips and renames what nothing calls, and Play Core's helper is reached only by name, through
# JavaClassWrapper, so each such class must have a keep rule or it fails only on a phone.
func _test_shrink_rules() -> void:
	var rules: String = FileAccess.get_file_as_string("res://addons/shrink_build/plugin.gd")
	var named: Array[String] = [StitchfallPlayCore.HELPER]
	var wrap: RegEx = RegEx.create_from_string("JavaClassWrapper\\.wrap\\(\"([^\"]+)\"\\)")
	for path: String in _scripts("res://scripts"):
		for found: RegExMatch in wrap.search_all(FileAccess.get_file_as_string(path)):
			named.append(found.get_string(1))
	var kept: Array[String] = []
	for found: RegExMatch in RegEx.create_from_string("-keep class ([\\w.$*]+) \\{").search_all(rules):
		kept.append(found.get_string(1))
	var missing: Array[String] = []
	for java: String in named:
		var covered: bool = false
		for rule: String in kept:
			covered = covered or rule == java or (rule.ends_with(".**") and java.begins_with(rule.trim_suffix("**")))
		if not covered:
			missing.append(java)
	_check("every Java class the game names has a keep rule %s" % [missing], missing.is_empty())


func _scripts(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			found.append(folder.path_join(file))
	for sub: String in DirAccess.get_directories_at(folder):
		found.append_array(_scripts(folder.path_join(sub)))
	return found


# The kit's numbers, then each rule on its edge with every other rule met.
func _test_pacing() -> void:
	_check("the banner waits for 3 rooms sewn", StitchfallAdPacing.BANNER_AFTER == 3 and not StitchfallAdPacing.banner_due(2, false) and StitchfallAdPacing.banner_due(3, false))
	_check("never a banner for a Supporter", not StitchfallAdPacing.banner_due(99, true))
	_check("the between-room pacing is 12 rooms, every 4, 4 minutes apart, 3 minutes in",
		StitchfallAdPacing.INTERSTITIAL_AFTER == 12 and StitchfallAdPacing.INTERSTITIAL_EVERY == 4
		and is_equal_approx(StitchfallAdPacing.FULLSCREEN_GAP, 240.0) and is_equal_approx(StitchfallAdPacing.LAUNCH_GAP, 180.0))
	var ok: Callable = func(sewn: int, since: int, now: float, last: float) -> bool:
		return StitchfallAdPacing.interstitial_due(sewn, since, now, last, false)
	_check("due once every rule is met", ok.call(12, 4, 180.0, -1.0))
	_check("never before 12 rooms are sewn", not ok.call(11, 40, 9999.0, -1.0))
	_check("never before 4 clears this session", not ok.call(60, 3, 9999.0, -1.0))
	_check("never in the first 3 minutes after launch", not ok.call(60, 9, 179.9, -1.0))
	_check("never within 4 minutes of a full-screen ad", not ok.call(60, 9, 1000.0, 1000.0 - 239.9))
	_check("due 4 minutes after one", ok.call(60, 9, 1000.0, 1000.0 - 240.0))
	_check("never between rooms for a Supporter", not StitchfallAdPacing.interstitial_due(60, 9, 9999.0, -1.0, true))
	_check("a skip waits for 5 unravels in the room", StitchfallAdPacing.SKIP_AFTER == 5 and not StitchfallAdPacing.skip_offered(4, true, false) and StitchfallAdPacing.skip_offered(5, true, false))
	_check("no skip from the last room, or into a room already open", not StitchfallAdPacing.skip_offered(9, false, false) and not StitchfallAdPacing.skip_offered(9, true, true))
	_check("a skip is free for a Supporter and wherever no ads play, and a video otherwise",
		StitchfallAdPacing.skip_cost(true, true) == StitchfallAdPacing.Skip.FREE and StitchfallAdPacing.skip_cost(false, false) == StitchfallAdPacing.Skip.FREE
		and StitchfallAdPacing.skip_cost(false, true) == StitchfallAdPacing.Skip.VIDEO)


# What each product gives, kept across a reload, with the Complete pack holding the other three.
func _test_products() -> void:
	var progress: StitchfallProgress = StitchfallProgress.new()
	progress.reset()
	var was_on_play: bool = StitchfallShop.on_play
	StitchfallShop.on_play = true
	_check("nothing is owned at the start", not StitchfallShop.ads_off(progress) and not StitchfallShop.levels_open(progress) and not StitchfallShop.has_pack(progress) and StitchfallShop.offers_complete(progress))
	_check("a locked room stays locked", not StitchfallShop.room_open(progress, 3))
	StitchfallShop.grant(progress, StitchfallMonetize.SUPPORTER_ID, true)
	_check("the Supporter pack turns the ads off and nothing else", StitchfallShop.ads_off(progress) and not StitchfallShop.levels_open(progress) and not StitchfallShop.has_pack(progress))
	_check("once a part is owned the Complete pack is no longer offered", not StitchfallShop.offers_complete(progress))
	StitchfallShop.grant(progress, StitchfallMonetize.SUPPORTER_ID, false)
	StitchfallShop.grant(progress, StitchfallMonetize.LEVELS_ID, true)
	_check("Every room opens every room", StitchfallShop.room_open(progress, 3) and StitchfallShop.room_open(progress, StitchfallLevels.count() - 1))
	StitchfallShop.grant(progress, StitchfallMonetize.LEVELS_ID, false)
	StitchfallShop.grant(progress, StitchfallMonetize.COMPLETE_ID, true)
	var reloaded: StitchfallProgress = StitchfallProgress.new()
	reloaded.load_saved()
	_check("the Complete pack holds all three, and survives a reload", StitchfallShop.ads_off(reloaded) and StitchfallShop.levels_open(reloaded) and StitchfallShop.has_pack(reloaded) and StitchfallShop.is_open(StitchfallLooks.find("fabric_night"), reloaded))
	StitchfallShop.grant(progress, StitchfallMonetize.COMPLETE_ID, false)
	_check("a refund takes it away again", not StitchfallShop.ads_off(progress) and not StitchfallShop.has_pack(progress))
	for id: String in StitchfallMonetize.TIP_IDS:
		StitchfallShop.grant(progress, id, true)
	_check("every tip counts one more, and opens nothing", progress.tips == StitchfallMonetize.TIP_IDS.size() and progress.owned.is_empty())
	progress.reset()
	_check("a reset keeps the tips", progress.tips == StitchfallMonetize.TIP_IDS.size())
	_check("the shop lists the Complete pack, then the three packs, then six tips", StitchfallShop.one_time_ids() == PackedStringArray(["complete", "supporter", "all_levels", "wardrobe"]) and StitchfallShop.all_ids().size() == 10)
	var wordy: Array[String] = []
	for id: String in StitchfallShop.one_time_ids():
		for row: String in StitchfallShop.rows(id):
			if row.length() > 20 or row.contains(";"):
				wordy.append(row)
		if StitchfallShop.title(id) == "Tip" or StitchfallShop.thanks(id).contains(";"):
			wordy.append(id)
	_check("every pack has a title, and its card's lines fit (%s)" % ", ".join(wordy), wordy.is_empty())
	StitchfallShop.on_play = false
	_check("the browser opens no room early, since Every room is sold only on Google Play", not StitchfallShop.room_open(progress, 3))
	StitchfallShop.on_play = was_on_play
	progress.tips = 0
	progress.reset()


# UMP consent status: 0 unknown, 1 not required, 2 required, 3 obtained. Only 1 counts, and never in a debug build.
func _test_consent_rule() -> void:
	_check("a release build counts where no consent is needed", StitchfallAnalytics.counts(1, false))
	_check("a debug build never counts", not StitchfallAnalytics.counts(1, true))
	for status: int in [0, 2, 3]:
		_check("consent status %d counts nothing" % status, not StitchfallAnalytics.counts(status, false))
	_check("nothing is counted off Android", not StitchfallAnalytics.counting())
	_check("no ads start off Android", not StitchfallAds.live() and not StitchfallAds.rewards() and not StitchfallAds.privacy_options_required())


func _test_play_core() -> void:
	var java: String = FileAccess.get_file_as_string("res://addons/play_core/PlayCore.java")
	var helper: PackedStringArray = StitchfallPlayCore.HELPER.rsplit(".", true, 1)
	_check("Play Core looks for the helper's own package and class", java.contains("package %s;" % helper[0]) and java.contains("public final class %s " % helper[1]))
	var core: String = FileAccess.get_file_as_string("res://scripts/play_core.gd")
	var missing: PackedStringArray = PackedStringArray()
	for method: String in ["requestReview", "reviewState", "checkForUpdate", "updateState", "completeUpdate"]:
		if not core.contains('"%s"' % method) or RegEx.create_from_string("public static \\w+ %s\\(" % method).search(java) == null:
			missing.append(method)
	_check("every helper method the game calls exists in the Java (%s)" % ", ".join(missing), missing.is_empty())
	var was_on_play: bool = StitchfallShop.on_play
	StitchfallShop.on_play = true
	var went: Array[bool] = [false]
	StitchfallPlayCore.review(func() -> void: went[0] = true)
	_check("without the helper the review goes straight on, and no update is ready", went[0] and not StitchfallPlayCore.available() and not StitchfallPlayCore.update_ready())
	var progress: StitchfallProgress = StitchfallProgress.new()
	progress.reset()
	for room: int in range(9):
		progress.best_stars[room] = 1
	_check("no review before the first milestone", StitchfallPlayCore.review_due(progress) == 0)
	progress.best_stars[9] = 1
	_check("the first ask comes at 10 rooms sewn", StitchfallPlayCore.review_due(progress) == 10)
	went[0] = false
	StitchfallPlayCore.ask(progress, 10, func() -> void: went[0] = true)
	_check("once asked it waits for the next milestone, and the game goes on", went[0] and StitchfallPlayCore.review_due(progress) == 0)
	for room: int in range(10, 30):
		progress.best_stars[room] = 1
	_check("the next milestone asks again", StitchfallPlayCore.review_due(progress) == 25)
	progress.rated = true
	_check("after Rate it never asks again", StitchfallPlayCore.review_due(progress) == 0)
	StitchfallShop.on_play = false
	progress.rated = false
	_check("the browser never asks", StitchfallPlayCore.review_due(progress) == 0)
	StitchfallShop.on_play = was_on_play
	progress.reset()


# The Play Games catalog, held to Play Console's rules and to the rooms in the code: enough achievements to
# publish, points in fives, plain words the import takes, no room count in a description, every goal one the rooms
# can give, and the three boards with limits that fit what can be scored.
func _test_play_games_catalog() -> void:
	var catalog: Dictionary = StitchfallPlayGames.catalog()
	var achievements: Array = catalog.get("achievements", [])
	var points: int = 0
	var fair: bool = true
	var keys: Dictionary = {}
	var names: Dictionary = {}
	var wordy: PackedStringArray = PackedStringArray()
	var digits: RegEx = RegEx.create_from_string("\\d+")
	for entry: Variant in achievements:
		var a: Dictionary = entry
		var name: String = a["name"]
		var text: String = a["text"]
		var goal: int = StitchfallPlayGames.goal(a)
		points += int(a["points"])
		fair = fair and int(a["points"]) > 0 and int(a["points"]) % 5 == 0 and int(a["points"]) <= 200 \
			and not StitchfallPlayGames.measure_of(a).is_empty() and not keys.has(a["key"]) and not names.has(name) \
			and (goal == 1 or (goal >= 2 and goal <= 10000))
		var plain: bool = name.length() <= 100 and text.length() <= 500 and text.ends_with(".") \
			and not (name + text).contains(";") and not (name + text).contains(",")
		# A number in a description is the achievement's own goal, never how many rooms the game or a chapter has.
		for found: RegExMatch in digits.search_all(name + " " + text):
			plain = plain and int(found.get_string()) == goal
		plain = plain and not text.contains("%d rooms" % StitchfallLevels.count()) and not text.contains("five rooms")
		if not plain:
			wordy.append(String(a["key"]))
		keys[a["key"]] = true
		names[name] = true
	_check("Play Games gets the five achievements it needs to publish, and a dozen at most", achievements.size() >= 5 and achievements.size() <= 12)
	_check("each achievement is measured, one step or 2 to 10,000, and worth points in fives, 1000 at most in all (%d)" % points, fair and points <= 1000)
	_check("every name and description is plain words the import takes, with no room count (%s)" % ", ".join(wordy), wordy.is_empty())
	var buttons_by_flowers: int = 0
	for room: int in range(StitchfallLevels.count()):
		var data: Dictionary = StitchfallLevels.get_level(room)
		if not (data["flowers"] as Array).is_empty():
			buttons_by_flowers += (data["shards"] as Array).size()
	var most: Dictionary[String, int] = {
		"sewn": StitchfallLevels.count(), "chapters": StitchfallLevels.chapter_count(), "three": StitchfallLevels.count(),
		"seamless": StitchfallLevels.chapter_count(), "quick": StitchfallLevels.count(), "banked": buttons_by_flowers,
		"turns": 1000000, "unravels": 1000000,
	}
	var out_of_reach: PackedStringArray = PackedStringArray()
	for entry: Variant in achievements:
		var a: Dictionary = entry
		if StitchfallPlayGames.goal(a) > most.get(StitchfallPlayGames.measure_of(a), 0):
			out_of_reach.append(String(a["key"]))
	_check("every goal is one the rooms in the code can give (%s)" % ", ".join(out_of_reach), out_of_reach.is_empty())
	var none: Array = achievements.filter(func(a: Dictionary) -> bool:
		return a.has("owned") or a.has("tips") or a.has("wear") or a.has("skipped"))
	_check("no achievement counts purchases, the Wardrobe or skips", none.is_empty())
	var boards: Dictionary = {}
	for entry: Variant in catalog.get("leaderboards", []):
		boards[(entry as Dictionary)["key"]] = entry
	_check("the boards are Stars, Rooms sewn and the Plain Linen speedrun, in that order",
		boards.keys() == ["stars", "rooms", "linen"] and boards["rooms"]["name"] == "Rooms sewn")
	_check("stars and rooms are numbers, the most first, with room for every star and room",
		boards["stars"]["order"] == "LARGER_IS_BETTER" and boards["stars"]["format"] == "NUMERIC" and int(boards["stars"]["max"]) >= StitchfallLevels.count() * 3
		and boards["rooms"]["order"] == "LARGER_IS_BETTER" and boards["rooms"]["format"] == "NUMERIC" and int(boards["rooms"]["max"]) >= StitchfallLevels.count())
	var linen: Dictionary = boards["linen"]
	var chapter: int = StitchfallLevels.chapter_ids.find(String(linen["chapter"]))
	var par_ms: float = 0.0
	for room: int in StitchfallPlayGames.chapter_rooms(maxi(chapter, 0)):
		par_ms += float(StitchfallLevels.get_level(room)["par"]) * 1000.0
	_check("the speedrun is a time, the fastest first, on a chapter that opens the campaign, named for it",
		linen["order"] == "SMALLER_IS_BETTER" and linen["format"] == "TIME_DURATION" and chapter >= 0
		and String(linen["name"]).begins_with(StitchfallLevels.chapter_name(chapter)))
	_check("and its limits hold every time from a second to an hour, par included", int(linen["min"]) == 1000
		and int(linen["max"]) == 3600000 and par_ms > float(linen["min"]) and par_ms < float(linen["max"]))
	var progress: StitchfallProgress = StitchfallProgress.new()
	progress.reset()
	_check("nothing is earned at the start", StitchfallPlayGames.earned(StitchfallPlayGames.measures(progress)).is_empty())
	for room: int in range(10):
		progress.best_stars[room] = 1
	_check("ten rooms sewn earn the first room, ten rooms and a whole chapter",
		StitchfallPlayGames.earned(StitchfallPlayGames.measures(progress)) == PackedStringArray(["first_room", "rooms_10", "chapter_1"]))
	var steps: Dictionary[String, int] = StitchfallPlayGames.steps(StitchfallPlayGames.measures(progress))
	_check("progress counts up to each goal and stops there", steps["rooms_10"] == 10 and steps["rooms_25"] == 10
		and steps["chapters_5"] == 2 and steps["three_10"] == 0)
	for room: int in range(4):
		progress.unbroken[room] = true
	_check("Seamless waits for every room of a chapter sewn without unravelling", StitchfallPlayGames.measures(progress)["seamless"] == 0)
	progress.unbroken[4] = true
	progress.quick[7] = true
	progress.best_stars[2] = 3
	progress.banked = 30
	progress.turns = 499
	progress.unravels = 100
	var earned: PackedStringArray = StitchfallPlayGames.earned(StitchfallPlayGames.measures(progress))
	_check("then it comes, with Quick fingers, Safe keeping and Hanging by a thread, but not one turn early",
		earned.has("seamless") and earned.has("quick_1") and earned.has("banked_15") and earned.has("unravels_100")
		and not earned.has("turns_500") and not earned.has("three_10"))
	var first: int = chapter * StitchfallLevels.CHAPTER_ROOMS
	var rooms: Array[int] = StitchfallPlayGames.chapter_rooms(chapter)
	for room: int in rooms:
		progress.best_stars[room] = maxi(progress.stars(room), 1)
		progress.best_time[room] = 6.25
	progress.best_stars.erase(first + 1)
	_check("the speedrun waits until every room of its chapter is sewn", StitchfallPlayGames.scores(progress)["linen"] == 0)
	progress.best_stars[first + 1] = 1
	var scores: Dictionary[String, int] = StitchfallPlayGames.scores(progress)
	_check("then it is the sum of their best times, in milliseconds", scores["linen"] == roundi(6.25 * rooms.size() * 1000.0)
		and scores["stars"] == progress.total_stars() and scores["rooms"] == StitchfallPlayGames.rooms_sewn(progress))
	progress.reset()


# Game Stats, held to Play Console's import rules so the files it is given never bounce, as the kit holds them.
func _test_game_stats() -> void:
	var catalog: Dictionary = StitchfallPlayGames.catalog()
	var events: Dictionary = catalog.get("events", {})
	var name_ok: RegEx = RegEx.create_from_string("^[A-Za-z0-9_]{1,50}$")
	var reserved: PackedStringArray = ["id", "count", "key", "value", "where", "from", "and", "or", "true", "false"]
	var schema_ok: bool = events.size() >= 1 and events.size() <= 20
	for event: String in events:
		var props: Dictionary = events[event]
		schema_ok = schema_ok and name_ok.search(event) != null and props.size() >= 1 and props.size() <= 20
		for prop: String in props:
			schema_ok = schema_ok and name_ok.search(prop) != null and not reserved.has(prop.to_lower()) \
				and ["INT64", "DOUBLE", "STRING", "BOOL", "DURATION"].has(String(props[prop]))
	_check("every event and property name and type is one Play Console takes", schema_ok)
	_check("progress goes up as progressUpdate's whole-number currentProgress",
		events.has("progressUpdate") and (events["progressUpdate"] as Dictionary).get("currentProgress") == "INT64")
	var stats: Array = catalog.get("stats", [])
	var progression: Dictionary = catalog.get("progression", {})
	var id_ok: RegEx = RegEx.create_from_string("^[A-Za-z0-9_]{1,100}$")
	var units: PackedStringArray = ["", "UNITLESS", "SECOND", "MINUTE", "HOUR", "SECONDS", "MINUTES", "HOURS"]
	var formats: PackedStringArray = ["", "UNIT_BASED", "COMPONENT_NUMERIC", "COMPONENT_TEXT"]
	var keys: Dictionary = {progression.get("key", ""): true}
	var names: Dictionary = {progression.get("name", ""): true}
	var stats_ok: bool = true
	var competitive: int = 0
	for entry: Variant in stats:
		var s: Dictionary = entry
		var props: Dictionary = events.get(s["event"], {})
		stats_ok = stats_ok and id_ok.search(s["key"]) != null and not keys.has(s["key"]) and s["event"] != "progressUpdate" \
			and props.has(s["property"]) and ["SUM", "MAX", "MIN", "COUNT"].has(s["aggregation"]) \
			and String(s["name"]).length() <= 50 and not names.has(s["name"]) and String(s["text"]).length() <= 500 \
			and String(s["text"]).ends_with(".") and not String(s["text"]).contains(";") and units.has(String(s.get("unit", ""))) \
			and formats.has(String(s.get("format", ""))) and (props[s["property"]] == "DURATION") == s.has("format")
		if s.has("filter"):
			var f: Array = s["filter"]
			stats_ok = stats_ok and props.has(f[0]) and ["=", "!=", ">", "<", ">=", "<="].has(f[1])
		if s.has("competitive"):
			competitive += 1
			stats_ok = stats_ok and (s["competitive"] as Array).size() == 2 and int(s["competitive"][0]) < int(s["competitive"][1])
		keys[s["key"]] = true
		names[s["name"]] = true
	_check("each stat names a real event and property, with a unique id and name", stats_ok)
	_check("five repetitive stats, one of them competitive, as Play's guidelines ask",
		stats.size() >= 5 and stats.size() <= 49 and competitive >= 1)
	_check("the progression stat reads currentProgress and its text fits in 50",
		progression.get("property") == "currentProgress" and id_ok.search(progression.get("key", "")) != null
		and String(progression.get("text", "")).length() <= 50 and String(progression.get("name", "")).length() <= 50)
	var sewn: Dictionary = StitchfallPlayGames.room_event(11, 3, 2, 5000.0)
	var rooms: Dictionary = events.get("roomCompleted", {})
	var typed: bool = sewn.size() == rooms.size()
	for prop: String in rooms:
		var want: int = {"INT64": TYPE_INT, "DOUBLE": TYPE_FLOAT, "BOOL": TYPE_BOOL, "STRING": TYPE_STRING,
			"DURATION": TYPE_DICTIONARY}[rooms[prop]]
		typed = typed and sewn.has(prop) and typeof(sewn[prop]) == want
		if rooms[prop] == "DURATION":
			typed = typed and typeof((sewn[prop] as Dictionary).get("seconds")) == TYPE_FLOAT
	_check("a room sewn sends every roomCompleted property, each in its declared type", typed)
	_check("numbered as players see it, and one room adds an hour at most to the time in the rooms", int(sewn["room"]) == 12
		and float(sewn["time"]["seconds"]) == 3600.0 and float(StitchfallPlayGames.room_event(0, 1, 0, 12.34)["time"]["seconds"]) == 12.3)


# Without play_games.json the Android build carries nothing of Play Games, which is how it ships until the console
# setup is done, and the browser build never carries any of it.
func _test_play_games_build() -> void:
	var has_ids: bool = FileAccess.file_exists(StitchfallPlayGames.IDS)
	_check("Play Games is on only once the game has its project", StitchfallPlayGames.app_id().is_empty() != has_ids)
	_check("and never starts off Android", not StitchfallPlayGames.ready() and not StitchfallPlayGames.signed_in())
	# Only the editor may make an export plugin, so the build is read through its static app() and its source.
	var plugin: GDScript = load("res://addons/play_games/plugin.gd") as GDScript
	var build_class: Variant = plugin.get_script_constant_map().get("_PlayGamesBuild")
	var build_app: String = String((build_class as GDScript).call("app")) if build_class is GDScript else "?"
	_check("the build reads the project id from play_games.json, the same one the game reads (%s)" % build_app,
		build_app == StitchfallPlayGames.app_id())
	var source: String = FileAccess.get_file_as_string("res://addons/play_games/plugin.gd")
	_check("the build adds the library, the SDK and the manifest's project id only with a project id",
		source.count('if app() == ""') == 2 and source.contains('DEPENDENCIES if app() != "" else PackedStringArray()')
		and source.contains('or app() == ""') and source.contains("play-services-games-v2:22.1.0") and source.contains("play_games/bin/%s-%s.aar"))
	if has_ids:
		var missing: PackedStringArray = PackedStringArray()
		for kind: String in ["achievements", "leaderboards"]:
			for entry: Variant in StitchfallPlayGames.catalog().get(kind, []):
				if StitchfallPlayGames.id_of(kind, String((entry as Dictionary)["key"])).is_empty():
					missing.append(String((entry as Dictionary)["key"]))
		_check("play_games.json has an id for everything in the catalog (%s)" % ", ".join(missing), missing.is_empty())
	for build_type: String in ["release", "debug"]:
		var aar: String = "res://addons/play_games/bin/GodotPlayGameServices-%s.aar" % build_type
		_check("the %s library is in place, with no uncaught exception handler" % build_type,
			FileAccess.file_exists(aar) and _aar_has(aar, "GodotAndroidPlugin") and not _aar_has(aar, "setDefaultUncaughtExceptionHandler"))
		_check("and it has Game Stats and achievement steps", _aar_has(aar, "recordGameEvent")
			and _aar_has(aar, "uploadGameEvents") and _aar_has(aar, "setAchievementSteps"))
	var presets: ConfigFile = ConfigFile.new()
	presets.load("res://export_presets.cfg")
	for section: String in presets.get_sections():
		if section.ends_with(".options"):
			continue
		var preset: String = presets.get_value(section, "name")
		var include: String = presets.get_value(section, "include_filter", "")
		var exclude: String = presets.get_value(section, "exclude_filter", "")
		if presets.get_value(section, "platform") == "Android":
			_check("%s ships the Play Games catalog and ids, and leaves the plugin's own files out" % preset,
				include.contains("play_games.json") and include.contains("play_games/catalog.json") and exclude.contains("addons/play_games/*"))
		else:
			_check("%s leaves all of Play Games out: the plugin, the backend, the catalog and the ids" % preset,
				exclude.contains("addons/*") and exclude.contains("scripts/android/*") and exclude.contains("play_games.json")
				and exclude.contains("play_games/*") and not include.contains("play_games"))


# The cloud save's merge rules, then a copy from the cloud landing in a player's progress.
func _test_cloud_save() -> void:
	var mine: ConfigFile = ConfigFile.new()
	var theirs: ConfigFile = ConfigFile.new()
	mine.set_value("stars", "0", 3)
	mine.set_value("stars", "1", 1)
	theirs.set_value("stars", "1", 2)
	theirs.set_value("stars", "2", 1)
	mine.set_value("time", "0", 9.5)
	mine.set_value("time", "1", 20.0)
	theirs.set_value("time", "1", 14.0)
	theirs.set_value("time", "2", 30.0)
	mine.set_value("skipped", "4", true)
	theirs.set_value("skipped", "5", true)
	theirs.set_value("unbroken", "1", true)
	theirs.set_value("quick", "2", true)
	mine.set_value("stats", "unravels", 40)
	theirs.set_value("stats", "unravels", 25)
	theirs.set_value("stats", "turns", 90)
	mine.set_value("stats", "play_time", 100.0)
	theirs.set_value("stats", "play_time", 250.5)
	mine.set_value("settings", "music", false)
	theirs.set_value("settings", "music", true)
	mine.set_value("wear", "runner", "seam")
	theirs.set_value("wear", "runner", "fox")
	theirs.set_value("owned", "complete", true)
	theirs.set_value("stats", "tips", 6)
	theirs.set_value("rating", "rated", true)
	StitchfallCloudSave.merge(mine, theirs)
	_check("each room keeps its best stars", int(mine.get_value("stars", "0")) == 3 and int(mine.get_value("stars", "1")) == 2
		and int(mine.get_value("stars", "2")) == 1)
	_check("and its best time", is_equal_approx(float(mine.get_value("time", "0")), 9.5) and is_equal_approx(float(mine.get_value("time", "1")), 14.0)
		and is_equal_approx(float(mine.get_value("time", "2")), 30.0))
	_check("rooms skipped, sewn unbroken and sewn quick join", mine.has_section_key("skipped", "4") and mine.has_section_key("skipped", "5")
		and mine.has_section_key("unbroken", "1") and mine.has_section_key("quick", "2"))
	_check("each lifetime count keeps the larger", int(mine.get_value("stats", "unravels")) == 40 and int(mine.get_value("stats", "turns")) == 90
		and is_equal_approx(float(mine.get_value("stats", "play_time")), 250.5))
	_check("settings, what is worn, purchases, tips and the review card stay this phone's own",
		mine.get_value("settings", "music") == false and mine.get_value("wear", "runner") == "seam" and not mine.has_section("owned")
		and not mine.has_section_key("stats", "tips") and not mine.has_section("rating"))
	var old_path: String = StitchfallProgress.path
	StitchfallProgress.path = "user://test_cloud.cfg"
	var progress: StitchfallProgress = StitchfallProgress.new()
	progress.reset()
	progress.record(0, 12.0, 1, 9.0)
	progress.wear["trail"] = "trail_gold"
	progress.save()
	# Counted in a room, not yet saved.
	progress.unravels = 7
	var cloud: StitchfallProgress = StitchfallProgress.new()
	cloud.best_stars[0] = 3
	cloud.best_stars[1] = 2
	cloud.best_time[0] = 8.0
	cloud.best_time[1] = 11.0
	cloud.unbroken[0] = true
	cloud.quick[0] = true
	cloud.quick[1] = true
	cloud.unravels = 3
	cloud.turns = 55
	cloud.banked = 9
	var text: String = _progress_text(cloud)
	_check("a copy from the cloud lands in the progress", StitchfallCloudSave.absorb(text, progress)
		and progress.stars(0) == 3 and progress.stars(1) == 2 and is_equal_approx(progress.best_time[0], 8.0)
		and progress.unbroken.has(0) and progress.quick.has(1) and progress.turns == 55 and progress.banked == 9)
	_check("and keeps what this phone counted but had not yet saved, and what it wears", progress.unravels == 7 and progress.wear["trail"] == "trail_gold")
	var reloaded: StitchfallProgress = StitchfallProgress.new()
	reloaded.load_saved()
	_check("the joined progress is saved", reloaded.stars(1) == 2 and reloaded.turns == 55)
	_check("the same copy again changes nothing", not StitchfallCloudSave.absorb(text, progress))
	_check("and anything unreadable changes nothing", not StitchfallCloudSave.absorb("not a save", progress)
		and not StitchfallCloudSave.absorb("", progress) and progress.stars(1) == 2)
	_check("the snapshot's progress grows with stars, then rooms", StitchfallCloudSave.progress_value(progress) == 5 * 1000 + 2)
	progress.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_cloud.cfg"))
	StitchfallProgress.path = old_path


# A progress file's text, as another phone would have saved it.
func _progress_text(progress: StitchfallProgress) -> String:
	var old_path: String = StitchfallProgress.path
	StitchfallProgress.path = "user://test_cloud_other.cfg"
	progress.save()
	var file: ConfigFile = ConfigFile.new()
	file.load(StitchfallProgress.path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(StitchfallProgress.path))
	StitchfallProgress.path = old_path
	return file.encode_to_text()


# The real backend, driven by a stand-in for the plugin's Android singleton: a quiet sign-in, the cloud copy read
# and joined before anything is written over it, achievements unlocked or stepped once each, scores sent once each,
# Game Stats events, the boards behind a sign-in, and Reset written over the cloud at once.
func _test_play_games_backend() -> void:
	var old_path: String = StitchfallProgress.path
	StitchfallProgress.path = "user://test_backend.cfg"
	var old_ids: Dictionary = StitchfallPlayGames._ids
	var ids: Dictionary = {"app": "1", "achievements": {}, "leaderboards": {}}
	for kind: String in ["achievements", "leaderboards"]:
		for entry: Variant in StitchfallPlayGames.catalog().get(kind, []):
			ids[kind][String((entry as Dictionary)["key"])] = "id_" + String((entry as Dictionary)["key"])
	StitchfallPlayGames._ids = ids
	var progress: StitchfallProgress = StitchfallProgress.new()
	progress.reset()
	for room: int in range(3):
		progress.record(room, 30.0, 0, 9.0)
	var fake: _FakePlayGames = _FakePlayGames.new()
	var backend: Node = (load(StitchfallPlayGames.BACKEND) as GDScript).new() as Node
	backend.set("plugin", fake)
	backend.set("progress", progress)
	var restores: Array[int] = [0]
	backend.set("restored", func() -> void: restores[0] += 1)
	root.add_child(backend)
	_check("the backend asks only whether Play Games signed the player in", fake.named("initialize") == 1 and fake.named("isAuthenticated") == 1
		and fake.named("signIn") == 0)
	backend.call("record_event", "roomCompleted", StitchfallPlayGames.room_event(0, 1, 0, 3.0))
	backend.call("show_boards")
	_check("before sign-in nothing is sent, and the boards sign in first", fake.named("recordGameEvent") == 0 and fake.named("signIn") == 1
		and fake.named("showAllLeaderboards") == 0)
	fake.userAuthenticated.emit(true)
	_check("sign-in reads the cloud copy, then opens the boards that asked for it", fake.named("loadGame") == 1 and fake.named("showAllLeaderboards") == 1)
	_check("and sends what progress already holds: the first room unlocked, rooms stepped",
		fake.sent("unlockAchievement", "id_first_room") and fake.sent("setAchievementSteps", "id_rooms_10", 3)
		and not fake.sent("unlockAchievement", "id_chapter_1"))
	_check("the boards' scores, made before sign-in, go once it comes", fake.sent("submitScore", "id_stars", 6) and fake.sent("submitScore", "id_rooms", 3)
		and not fake.named_with("submitScore", "id_linen"))
	_check("and the different rooms sewn go to Game Stats", fake.event("progressUpdate").get("currentProgress") == 3)
	_check("nothing is written to the cloud before its copy is read", fake.named("saveGame") == 0)
	var calls: int = fake.calls.size()
	backend.call("progressed")
	_check("nothing already sent goes again", fake.calls.size() == calls)
	var cloud: StitchfallProgress = StitchfallProgress.new()
	for room: int in range(5):
		cloud.best_stars[room] = 3
		cloud.best_time[room] = 4.0
		cloud.unbroken[room] = true
	var signed: Array = []
	for byte: int in (_progress_text(cloud) + "\n; café\n").to_utf8_buffer():
		signed.append(byte - 256 if byte > 127 else byte)
	fake.gameLoaded.emit(JSON.stringify({"content": signed}))
	_check("the cloud copy, in Gson's signed bytes, joins this phone's", progress.stars(4) == 3 and progress.stars(0) == 3 and restores[0] == 1)
	_check("what the two phones earn together goes up", fake.sent("unlockAchievement", "id_chapter_1") and fake.sent("unlockAchievement", "id_seamless")
		and fake.sent("submitScore", "id_stars", 15) and fake.sent("setAchievementSteps", "id_rooms_10", 5)
		and fake.sent("submitScore", "id_linen", 20000))
	var saved: Array = fake.last("saveGame")
	_check("then the joined copy is written back at once", saved.size() == 6 and saved[1] == "progress"
		and (saved[3] as PackedByteArray).get_string_from_utf8().contains("[stars]") and int(saved[5]) == StitchfallCloudSave.progress_value(progress))
	var timer: Timer = backend.get("_save_timer")
	backend.call("progressed")
	_check("later progress waits a little to be saved", not timer.is_stopped())
	backend.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check("and goes at once when the app is sent to the background", timer.is_stopped() and fake.named("saveGame") == 2)
	StitchfallPlayGames.use(backend)
	StitchfallPlayGames.room_sewn(5, 3, 0, 6.5)
	var heard: Dictionary = fake.event("roomCompleted")
	_check("a room sewn sends its Game Stats event", heard.get("room") == 6 and heard.get("stars") == 3 and heard.get("unravels") == 0
		and float((heard.get("time", {}) as Dictionary).get("seconds", 0.0)) == 6.5)
	progress.reset()
	StitchfallPlayGames.progress_reset()
	var wiped: Array = fake.last("saveGame")
	_check("Reset writes the reset progress over the cloud copy at once", fake.named("saveGame") == 3
		and not (wiped[3] as PackedByteArray).get_string_from_utf8().contains("[stars]"))
	StitchfallPlayGames.show_achievements()
	_check("a signed-in player's Achievements opens at once", fake.named("showAchievements") == 1 and fake.named("signIn") == 1)
	StitchfallPlayGames.use(null)
	await process_frame
	StitchfallPlayGames._ids = old_ids
	progress.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_backend.cfg"))
	StitchfallProgress.path = old_path


# The Stats page offers Play Games' own pages only once Play Games is on, beside the lines and clear of the banner,
# and the game tells Play Games of every room sewn, every skip, every pause and a Reset. A cloud save that lands on
# Home moves Play on past the rooms it brought.
func _test_play_games_pages() -> void:
	var game: Node2D = _game()
	await process_frame
	game.progress.reset()
	var hud: StitchfallHud = game.hud
	hud.show_stats()
	_check("off Android the Stats page has no Play Games buttons", not hud.stats_boards.visible and not hud.stats_achievements.visible)
	var stand_in: _PlayGamesStandIn = _PlayGamesStandIn.new()
	StitchfallPlayGames.use(stand_in)
	hud.show_stats()
	_check("with Play Games the Stats page offers Leaderboards and Achievements", hud.stats_boards.is_visible_in_tree()
		and hud.stats_achievements.is_visible_in_tree() and hud.stats_boards.caption == "LEADERBOARDS" and hud.stats_achievements.caption == "ACHIEVEMENTS")
	var lines: Rect2 = Rect2(hud.stats_lines.position, Vector2(hud.stats_lines.get_minimum_size().x, hud.stats_lines.size.y))
	_check("beside the lines, not on them, and ending above their foot", lines.end.x < hud.stats_boards.position.x
		and hud.stats_achievements.position.y + hud.stats_achievements.size.y <= hud.stats_lines.position.y + hud.stats_lines.size.y)
	var fits: bool = true
	for button: StitchedButton in [hud.stats_boards, hud.stats_achievements]:
		fits = fits and StitchedButton.MENU_FONT.get_string_size(button.caption, HORIZONTAL_ALIGNMENT_LEFT, -1, button.caption_size).x <= button.size.x
	_check("each caption fits under its patch whole", fits)
	hud.stats_boards.pressed.emit()
	hud.stats_achievements.pressed.emit()
	_check("each opens Play Games' own page", stand_in.heard.has("boards") and stand_in.heard.has("achievements"))
	game._load_level(1)
	game._on_begin()
	game.room_time = 4.5
	game.room_deaths = 2
	game._clear_room()
	_check("a room sewn goes to Play Games with its stars, unravels and time", stand_in.events.size() == 1
		and stand_in.events[0]["room"] == 2 and stand_in.events[0]["unravels"] == 2 and stand_in.heard.has("progressed"))
	stand_in.heard.clear()
	game._load_level(2)
	game._on_begin()
	game._on_pause()
	_check("a pause tells Play Games of the progress so far", stand_in.heard.has("progressed"))
	stand_in.heard.clear()
	game.room_deaths = StitchfallAdPacing.SKIP_AFTER
	game._on_skip()
	_check("and so does a skip", stand_in.heard.has("progressed") and game.progress.skipped.has(2))
	game._on_home()
	game.launch_room = game.level_index
	game.room_begun = false
	for room: int in range(6):
		game.progress.best_stars[room] = 2
	game._on_cloud_restore()
	_check("a cloud save landing on Home moves Play on past the rooms it brought", game.level_index == game.progress.continue_room(StitchfallLevels.count()))
	game.progress.unbroken[0] = true
	hud.show_settings()
	hud._reset_progress()
	hud._reset_progress()
	_check("Reset goes over the cloud copy at once", stand_in.heard.has("reset") and game.progress.unbroken.is_empty())
	StitchfallPlayGames.use(null)
	game.progress.reset()
	game.queue_free()
	await process_frame


func _test_house_ads() -> void:
	var backend: StitchfallHouseAds = StitchfallHouseAds.new()
	root.add_child(backend)
	_check("house ads never show an ad between rooms, and always have a game to give a reward",
		not backend.ready_to_show(StitchfallAdBackend.INTERSTITIAL) and backend.ready_to_show(StitchfallAdBackend.REWARDED))
	var heights: Array[float] = []
	backend.banner_changed.connect(func(h: float) -> void: heights.append(h))
	backend.set_banner(true)
	_check("the house banner takes a phone banner's height", heights.size() == 1 and heights[0] > 0.0)
	backend.stop()
	_check("and gives the room back when ads stop", heights.size() == 2 and is_zero_approx(heights[1]))
	backend.free()
	_check("every studio game has its icon", StitchfallStudio.others().all(func(game: Dictionary) -> bool: return ResourceLoader.exists(String(game["icon"]))))
	var cleared: Array[String] = []
	for game: Dictionary in StitchfallStudio.others():
		var board: Control = StitchfallHouseGames.make(String(game["name"]))
		root.add_child(board)
		var fresh: bool = not board.call("is_solved")
		board.call("play_through")
		if fresh and board.call("is_solved"):
			cleared.append(String(game["name"]))
		board.free()
	_check("every quick game starts unsolved and its winning moves clear it (%s)" % ", ".join(cleared), cleared.size() == StitchfallStudio.others().size())
	var card: StitchfallHouseCard = StitchfallHouseAds.open_card(StitchfallStudio.others()[0])
	await process_frame
	var closed: Array[bool] = [false]
	card.closed.connect(func() -> void: closed[0] = true)
	_check("the quick game has GET and CONTINUE", card.get_button.caption == "GET" and card.continue_button.caption == "CONTINUE")
	_check("Android's back closes the quick game", StitchfallAds.back() and closed[0])
	await process_frame
	_check("and with none open, back goes on to the page", not StitchfallAds.back())


func _test_back_gesture() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	_check("no Google Play store starts outside Android", StitchfallShop.backend == null)
	game._load_level(0)
	game._on_begin()
	game.last_back_msec = -1000
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check("back during play pauses", not game.playing and game.hud.screen == "pause")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check("a second request inside one press is ignored", game.hud.screen == "pause")
	game.last_back_msec = -1000
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check("back on pause resumes", game.playing)
	game._on_home()
	game.hud.show_wardrobe()
	game.last_back_msec = -1000
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check("back from the wardrobe goes home", game.hud.screen == "home")
	game.hud.show_settings()
	game.hud.show_credits()
	game.last_back_msec = -1000
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check("back from credits goes to settings", game.hud.screen == "settings")
	game.queue_free()
	await process_frame


func _test_progress() -> void:
	_check("a clean quick clear earns three stars", StitchfallProgress.stars_for(8.0, 0, 9.0) == 3)
	_check("an unravel costs the Unbroken star", StitchfallProgress.stars_for(8.0, 1, 9.0) == 2)
	_check("a slow clean clear earns two stars", StitchfallProgress.stars_for(12.0, 0, 9.0) == 2)
	_check("finishing always earns one star", StitchfallProgress.stars_for(60.0, 9, 9.0) == 1)
	var progress: StitchfallProgress = StitchfallProgress.new()
	progress.reset()
	_check("only the first room is open at the start", progress.is_open(0) and not progress.is_open(1))
	var first: Dictionary = progress.record(0, 12.0, 2, 9.0)
	_check("a first clear is marked first", first["first"] and first["stars"] == 1)
	var better: Dictionary = progress.record(0, 7.0, 0, 9.0)
	_check("a better clear is called out", better["more_stars"] and better["faster"])
	progress.record(0, 20.0, 5, 9.0)
	var reloaded: StitchfallProgress = StitchfallProgress.new()
	reloaded.load_saved()
	_check("the best stars and time survive a worse run and a reload", reloaded.stars(0) == 3 and is_equal_approx(reloaded.best_time[0], 7.0))
	_check("a sewn room opens the next", reloaded.is_open(1) and not reloaded.is_open(2))
	_check("Play continues from the first room not yet sewn", reloaded.continue_room(StitchfallLevels.count()) == 1)
	progress.reset()


func _test_wardrobe() -> void:
	var gold: Dictionary = StitchfallLooks.find("trail_gold")
	var fabric: Dictionary = StitchfallLooks.find("fabric_night")
	_check("the browser opens every piece", StitchfallLooks.is_open(gold, 0, false, false) and StitchfallLooks.is_open(fabric, 0, false, false))
	_check("on Android a star piece waits for its stars", not StitchfallLooks.is_open(gold, 14, false, true) and StitchfallLooks.is_open(gold, 15, false, true))
	_check("on Android a paid piece waits for the Wardrobe pack", not StitchfallLooks.is_open(fabric, 999, false, true) and StitchfallLooks.is_open(fabric, 0, true, true))
	var opened: Array[Dictionary] = StitchfallLooks.opened_between(14, 18)
	var opened_ids: Array[String] = []
	for item: Dictionary in opened:
		opened_ids.append(item["id"])
	_check("new stars call out exactly the pieces they open", opened_ids == ["trail_gold", "unravel_petals"])
	for kind: String in StitchfallLooks.KINDS:
		_check("the default %s is free and open" % kind, StitchfallLooks.is_open(StitchfallLooks.find(StitchfallLooks.DEFAULTS[kind]), 0, false, true))
	for item: Dictionary in StitchfallLooks.ITEMS:
		if item["kind"] != "runner":
			continue
		var art: Dictionary = StitchfallLooks.runner_art(item["id"])
		var sheets_fit: bool = true
		for sheet: String in ["run", "actions"]:
			sheets_fit = sheets_fit and ResourceLoader.exists(art[sheet]) and (load(art[sheet]) as Texture2D).get_size() == Vector2(1448, 1086)
		for pose: String in art["poses"]:
			sheets_fit = sheets_fit and ResourceLoader.exists(pose) and (load(pose) as Texture2D).get_size() == Vector2(400, 650)
		sheets_fit = sheets_fit and ResourceLoader.exists(art["dance"]) and (load(art["dance"]) as Texture2D).get_size() == Vector2(1600, 1300)
		_check("%s has every sheet at its size" % item["name"], sheets_fit)
	_check("the extra icon sheet is the main sheet's size", StitchedButton.EXTRA_ICONS.get_size() == StitchedButton.ICONS.get_size())
	for kind: String in StitchfallLooks.KINDS:
		_check("the %s tab fits on one page" % kind, StitchfallLooks.items(kind).size() <= 8)
	var progress: StitchfallProgress = StitchfallProgress.new()
	progress.reset()
	progress.wear["trail"] = "trail_gold"
	progress.music = false
	progress.unravels = 7
	StitchfallShop.grant(progress, StitchfallMonetize.WARDROBE_ID, true)
	var reloaded: StitchfallProgress = StitchfallProgress.new()
	reloaded.load_saved()
	_check("what is worn, settings, stats and purchases survive a reload", reloaded.wear["trail"] == "trail_gold" and not reloaded.music and reloaded.unravels == 7 and StitchfallShop.has_pack(reloaded))
	reloaded.reset()
	_check("a reset clears play but keeps purchases", reloaded.unravels == 0 and reloaded.wear["trail"] == "trail_none" and StitchfallShop.has_pack(reloaded))
	StitchfallShop.grant(reloaded, StitchfallMonetize.WARDROBE_ID, false)
	var was_on_play: bool = StitchfallShop.on_play
	StitchfallShop.on_play = true
	_check("without Google Play, buying says so instead of failing", not StitchfallShop.buy(StitchfallMonetize.WARDROBE_ID).is_empty())
	StitchfallShop.on_play = was_on_play


# The moments around play: an unravel counts and shakes the loose buttons home, a clear zips the runner away
# and brings the card, and a new chapter opens on its title card.
func _test_moments() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	var heard: Dictionary = {}
	StitchfallAnalytics.sink = func(event: StringName, params: Dictionary) -> void: heard[event] = params
	game.progress.reset()
	game._load_level(4)
	game._on_begin()
	_check("a room's start is counted, numbered as players see it", heard.has(&"room_start") and heard[&"room_start"]["room"] == 5)
	game.pilot.position = game.level["shards"][0]
	game.pilot.reset_physics_interpolation()
	await physics_frame
	await physics_frame
	game.pilot.position = game.level["spikes"][0]["rect"].get_center()
	game.pilot.reset_physics_interpolation()
	await physics_frame
	await physics_frame
	_check("an unravel is counted for the room, for life, and on screen", game.room_deaths == 1 and game.progress.unravels == 1 and game.hud.unravel_label.text == "x 1")
	for frame: int in range(50):
		await physics_frame
	_check("an unravel without a flower sends the button home", not game.collected[0])
	for index: int in range(game.level["shards"].size()):
		game.collected[index] = true
	game._update_door()
	# This room's zipper runs once, so follow it until it is caught.
	for attempt: int in range(3):
		if game.cleared:
			break
		game.pilot.position = game.exit_position
		game.pilot.reset_physics_interpolation()
		await physics_frame
		await physics_frame
	_check("the zipper takes the runner and the room is saved without the Unbroken star", game.cleared and game.progress.stars(4) == 2)
	_check("the unravel and the clear are counted with their stars, time and unravels", heard.has(&"room_unravel") and heard.has(&"room_clear")
		and heard[&"room_clear"]["stars"] == 2 and heard[&"room_clear"]["unravels"] == 1 and heard[&"room_clear"].has("seconds"))
	StitchfallAnalytics.sink = Callable()
	await create_timer(1.2).timeout
	_check("the clear card follows the zipper closing", game.hud.screen == "clear" and not game.world.door_open)
	_check("the last room of a chapter says so", game.hud.clear_heading.text == "CHAPTER SEWN!")
	game._on_next()
	_check("a new chapter opens on its title card", game.level_index == 5 and game.hud.screen == "chapter" and not game.playing)
	game.hud.skip_chapter()
	_check("the title card gives way to the room", game.playing and game.hud.screen == "game")
	game.queue_free()
	await process_frame


func _game() -> Node2D:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	return game


# A runner coming apart on needles beside an open zipper is not sewn out while it unravels.
func _test_unravel_holds_the_zipper() -> void:
	var game: Node2D = _game()
	await process_frame
	game.progress.reset()
	game._load_level(0)
	game._on_begin()
	for index: int in range(game.collected.size()):
		game.collected[index] = true
	game._update_door()
	game.pilot.position = game.level["spikes"][0]["rect"].get_center()
	game.pilot.reset_physics_interpolation()
	for frame: int in range(6):
		await physics_frame
	game.pilot.position = game.exit_position
	game.pilot.reset_physics_interpolation()
	await physics_frame
	await physics_frame
	_check("an unravelling runner is not sewn out by the open zipper", game.respawning and game.world.door_open and not game.cleared)
	game.progress.reset()
	game.queue_free()
	await process_frame


# Five unravels in a room offer a skip on the pause page. It opens the next room without stars, free off Android
# and for a Supporter, after the video otherwise, and with nothing to play the room simply stays.
func _test_skip() -> void:
	var game: Node2D = _game()
	await process_frame
	game.progress.reset()
	game._load_level(0)
	game._on_begin()
	game.room_deaths = 4
	game._on_pause()
	_check("no skip before 5 unravels", not game.hud.skip_button.visible and game.hud.pause_body.text.is_empty())
	game._on_begin()
	game.room_deaths = 5
	game._on_pause()
	_check("the pause page offers a skip after 5 unravels, with Resume and Retry beside it",
		game.hud.skip_button.visible and game.hud.resume_button.visible and game.hud.restart_button.visible)
	_check("off Android the skip is free, and asks for no video", game.hud.pause_body.text.contains("skip this room") and not game.hud.pause_body.text.contains("video"))
	var resume_bottom: float = game.hud.resume_button.position.y + game.hud.resume_button.size.y
	_check("the skip sits under the pause actions, clear of them", game.hud.skip_button.position.y >= resume_bottom + 20.0)
	game._on_skip()
	_check("a skip opens the next room without stars", game.level_index == 1 and game.playing and game.progress.skipped.has(0) and game.progress.stars(0) == 0)
	_check("the room after a skip stays open, and Play picks up past it", game.progress.is_open(1) and game.progress.continue_room(StitchfallLevels.count()) == 1)
	var ads: _VideoAds = _VideoAds.new()
	StitchfallAds.use(ads)
	game.room_deaths = 5
	game._on_pause()
	_check("with ads the skip names the video it costs", game.hud.pause_body.text.contains("Watch a video"))
	game._on_skip()
	await process_frame
	await process_frame
	_check("the video's reward opens the next room", ads.presented.size() == 1 and ads.presented[0] == StitchfallAdBackend.REWARDED and game.level_index == 2 and game.progress.skipped.has(1))
	StitchfallShop.grant(game.progress, StitchfallMonetize.SUPPORTER_ID, true)
	game.room_deaths = 5
	game._on_pause()
	_check("a Supporter skips free", game._skip_cost() == StitchfallAdPacing.Skip.FREE and not game.hud.pause_body.text.contains("video"))
	StitchfallShop.grant(game.progress, StitchfallMonetize.SUPPORTER_ID, false)
	StitchfallAds.use(_NoAds.new())
	game._on_skip()
	await process_frame
	_check("with nothing to play the room stays, paused, and says so", game.level_index == 2 and game.hud.screen == "pause" and not game.advancing and game.hud.pause_body.text.begins_with("Nothing to play"))
	game.room_deaths = 0
	game._on_begin()
	game._on_pause()
	_check("no skip offered in a room not yet failed", not game.hud.skip_button.visible)
	StitchfallAds.use(null)
	game.progress.reset()
	game.queue_free()
	await process_frame


# Next on the clear card brings the ad between rooms once every rule is met, then goes on to the next room, and
# never stands beside a chapter's title card.
func _test_next_brings_the_ad() -> void:
	var game: Node2D = _game()
	await process_frame
	game.progress.reset()
	for room: int in range(12):
		game.progress.best_stars[room] = 1
	var ads: _VideoAds = _VideoAds.new()
	ads.interstitials = true
	StitchfallAds.use(ads)
	StitchfallAds.skew = 1000.0
	for clear: int in range(3):
		StitchfallAds.room_cleared()
	game._load_level(1)
	game.cleared = true
	game._on_next()
	_check("no ad after only 3 clears this session", ads.presented.is_empty() and game.level_index == 2)
	StitchfallAds.room_cleared()
	game.cleared = true
	game._on_next()
	_check("the fourth clear's Next brings the ad", ads.presented.size() == 1 and ads.presented[0] == StitchfallAdBackend.INTERSTITIAL and game.advancing)
	game._on_next()
	await process_frame
	await process_frame
	_check("a second press waits, and the room after it opens once the ad closes", ads.presented.size() == 1 and game.level_index == 3 and game.playing and not game.advancing)
	for clear: int in range(4):
		StitchfallAds.room_cleared()
	game.cleared = true
	game._on_next()
	_check("never within 4 minutes of the last", ads.presented.size() == 1 and game.level_index == 4)
	StitchfallAds.skew += 1000.0
	game.cleared = true
	game._on_next()
	_check("never beside a chapter's title card", ads.presented.size() == 1 and game.level_index == 5 and game.hud.screen == "chapter")
	StitchfallShop.grant(game.progress, StitchfallMonetize.SUPPORTER_ID, true)
	StitchfallAds.skew += 1000.0
	for clear: int in range(4):
		StitchfallAds.room_cleared()
	game.cleared = true
	game._on_next()
	_check("never for a Supporter", ads.presented.size() == 1 and game.level_index == 6)
	StitchfallShop.grant(game.progress, StitchfallMonetize.SUPPORTER_ID, false)
	StitchfallAds.use(null)
	StitchfallAds.skew = 0.0
	game.progress.reset()
	game.queue_free()
	await process_frame


# On every menu page that carries the banner, the page shrinks so its lowest button keeps BUTTON_GAP_DP above
# the banner and its cloth stops short of it. Home, play and the full-screen cards never carry one.
func _test_banner_keeps_clear() -> void:
	var game: Node2D = _game()
	await process_frame
	game.progress.reset()
	StitchfallAds.preview = true
	game.hud.show_levels()
	_check("no banner before 3 rooms are sewn", not StitchfallAds.banner_wanted())
	for room: int in range(3):
		game.progress.best_stars[room] = 1
	var hud: StitchfallHud = game.hud
	var pages: Dictionary = {"levels": hud.level_page, "wardrobe": hud.wardrobe_page, "settings": hud.settings_page,
		"about": hud.about_page, "credits": hud.credits_page, "stats": hud.stats_page}
	for name: String in pages:
		hud.call("show_%s" % name)
		var page: Control = pages[name]
		var banner: Rect2 = StitchfallAds.banner_rect()
		var clear_line: float = banner.position.y - StitchfallAds.BUTTON_GAP_DP * StitchfallAds.per_dp()
		var lowest: float = 0.0
		var cloth_end: float = 0.0
		for part: Node in page.find_children("*", "Control", true, false):
			var control: Control = part as Control
			if not control.is_visible_in_tree() or control is StitchBorder:
				continue
			if control.has_meta(&"cloth"):
				cloth_end = maxf(cloth_end, control.get_global_rect().end.y)
			else:
				lowest = maxf(lowest, control.get_global_rect().end.y)
		_check("%s carries the banner once 3 rooms are sewn" % name, StitchfallAds.banner_wanted())
		_check("%s keeps every button and line %d px clear of the banner (lowest %d, banner top %d)" % [name, roundi(StitchfallAds.BUTTON_GAP_DP * StitchfallAds.per_dp()), roundi(lowest), roundi(banner.position.y)], lowest <= clear_line + 0.5)
		_check("%s's cloth stops above the banner" % name, cloth_end <= banner.position.y)
		_check("%s shrinks no further than it must" % name, hud.page_fit(page) >= 0.7)
	for name: String in ["home", "help"]:
		hud.call("show_%s" % name)
		_check("%s never carries the banner" % name, not StitchfallAds.banner_wanted())
	hud.show_shop()
	_check("the Shop never carries the banner", not StitchfallAds.banner_wanted())
	game._load_level(0)
	game._on_begin()
	_check("play never carries the banner", not StitchfallAds.banner_wanted())
	game._on_pause()
	_check("the pause page never carries the banner", not StitchfallAds.banner_wanted())
	hud.show_settings()
	StitchfallShop.grant(game.progress, StitchfallMonetize.SUPPORTER_ID, true)
	_check("a Supporter never sees the banner", not StitchfallAds.banner_wanted() and is_equal_approx(hud.page_fit(hud.settings_page), 1.0))
	StitchfallShop.grant(game.progress, StitchfallMonetize.SUPPORTER_ID, false)
	StitchfallAds.preview = false
	hud.show_home()
	game.progress.reset()
	game.queue_free()
	await process_frame


# The Shop lists the packs with Play's prices, the six tips and Restore, and leaves the Complete pack out once any
# part of it is owned. The browser build has no way to it.
func _test_shop_page() -> void:
	var game: Node2D = _game()
	await process_frame
	game.progress.reset()
	var hud: StitchfallHud = game.hud
	var home_captions: PackedStringArray = PackedStringArray()
	for button: Node in hud.home_page.find_children("*", "StitchedButton", true, false):
		home_captions.append((button as StitchedButton).caption)
	_check("the browser build's Home has no Shop", not home_captions.has("SHOP"))
	hud.show_wardrobe()
	_check("nor its Wardrobe", not hud.wardrobe_shop.visible and not hud.wardrobe_buy.visible)
	var was_on_play: bool = StitchfallShop.on_play
	StitchfallShop.on_play = true
	StitchfallShop.prices = {"supporter": "$2.99", "tip_50": "Rp 799.000,00"}
	hud.show_wardrobe()
	_check("Google Play's Wardrobe leads to the Shop", hud.wardrobe_shop.visible and hud.wardrobe_buy.visible)
	hud.show_shop("wardrobe")
	var shown: Array[String] = []
	for id: String in hud.shop_cards:
		if hud.shop_cards[id].visible:
			shown.append(id)
	_check("the Shop shows all four packs while none is owned", PackedStringArray(shown) == PackedStringArray(["complete", "supporter", "all_levels", "wardrobe"]))
	_check("each card has Play's price once Play gives one", hud.shop_cards["supporter"].price_tag == "$2.99" and hud.shop_cards["wardrobe"].price_tag == "")
	_check("six tips, a long price in a smaller hand", hud.shop_tips.size() == 6 and hud.shop_tips[5].caption == "Rp 799.000,00" and hud.shop_tips[5].caption_size < hud.shop_tips[0].caption_size)
	var cards_end: float = 0.0
	for id: String in shown:
		cards_end = maxf(cards_end, hud.shop_cards[id].position.x + hud.shop_cards[id].size.x)
	_check("the cards fit on the cloth", hud.shop_cards["complete"].position.x >= 65.0 and cards_end <= 1855.0)
	hud.shop_cards["supporter"].pressed.emit()
	_check("buying without Google Play says so", hud.shop_note.text == StitchfallShop.UNREACHABLE)
	StitchfallShop.grant(game.progress, StitchfallMonetize.SUPPORTER_ID, true)
	hud.refresh_store()
	_check("once the Supporter pack is owned the Complete pack goes, and the pack says so", not hud.shop_cards["complete"].visible and hud.shop_cards["supporter"].owned and hud.shop_line.text.begins_with("You are a Supporter"))
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check("back from the Shop goes where it came from", hud.screen == "wardrobe")
	hud.show_shop()
	game.last_back_msec = -1000
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check("and from Home's Shop goes Home", hud.screen == "home")
	StitchfallShop.grant(game.progress, StitchfallMonetize.SUPPORTER_ID, false)
	StitchfallShop.prices = {}
	StitchfallShop.on_play = was_on_play
	game.progress.reset()
	game.queue_free()
	await process_frame


func _check(name: String, cond: bool) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		print("  FAIL: ", name)

# An action can exist with zero events, and then every is_action_pressed() silently returns false.
func _test_input_map_is_wired() -> void:
	var table: Dictionary = InputMapGen.bindings()
	for action: String in table:
		_check("action %s exists, re-run tools/make_input_map.gd" % action, InputMap.has_action(action))
		if InputMap.has_action(action):
			_check("action %s has bindings" % action, InputMap.action_get_events(action).size() > 0)

# A string here converts to 0, which is Landscape, whatever the string said.
func _test_orientation_is_an_int() -> void:
	var value: Variant = ProjectSettings.get_setting("display/window/handheld/orientation")
	_check("handheld orientation is stored as an int, re-run tools/configure_project.gd",
		typeof(value) == TYPE_INT)


func _test_movement_feel() -> void:
	var pilot: StitchfallCourier = StitchfallCourier.new()
	pilot.control_enabled = false
	root.add_child(pilot)
	await process_frame
	var momentum: Vector2 = Vector2(120, -220)
	pilot.velocity = momentum
	pilot.set_gravity_direction(Vector2.LEFT)
	_check("gravity turns preserve incoming momentum", pilot.velocity.is_equal_approx(momentum))
	_check("the pilot art begins its turn from the previous world angle", absf(pilot.sprite.global_rotation) < 0.02)
	pilot.queue_free()
	await process_frame
	var inverted: StitchfallCourier = StitchfallCourier.new()
	inverted.position = Vector2(2200, 350)
	root.add_child(inverted)
	await process_frame
	inverted.set_gravity_direction(Vector2.UP)
	inverted.touch_axis = 1.0
	await physics_frame
	await physics_frame
	_check("a right slide moves right on the ceiling", inverted.velocity.x > 0.0)
	inverted.queue_free()
	await process_frame


func _test_fraying_ledge() -> void:
	var script: GDScript = load("res://scripts/fray_ledge.gd") as GDScript
	_check("a fraying ledge has a reusable physics body", script != null)
	if script == null:
		return
	var ledge: StaticBody2D = script.new() as StaticBody2D
	ledge.configure({"rect": Rect2(400, 650, 260, 28), "delay": 0.35})
	root.add_child(ledge)
	ledge.active = true
	var runner: StitchfallCourier = StitchfallCourier.new()
	runner.control_enabled = false
	runner.position = Vector2(500, 595)
	root.add_child(runner)
	for frame: int in range(5):
		await physics_frame
	_check("the fraying ledge warns before tearing", ledge.countdown > 0.0 and not ledge.collapsed)
	for frame: int in range(30):
		await physics_frame
	_check("the fraying ledge opens after its warning", ledge.collapsed and ledge.collision_shape.disabled)
	ledge.reset()
	await physics_frame
	_check("retry sews the fraying ledge closed", not ledge.collapsed and not ledge.collision_shape.disabled)
	runner.queue_free()
	ledge.queue_free()
	await process_frame


func _test_environment_forces() -> void:
	var dry: StitchfallCourier = StitchfallCourier.new()
	var wet: StitchfallCourier = StitchfallCourier.new()
	dry.position = Vector2(2200, 350)
	wet.position = Vector2(2600, 350)
	root.add_child(dry)
	root.add_child(wet)
	await process_frame
	_check("the pilot accepts an authored environment zone", wet.has_method("set_environment"))
	if wet.has_method("set_environment"):
		wet.call("set_environment", "water", Rect2(2500, 200, 220, 500))
		for frame: int in range(12):
			await physics_frame
		_check("water slows a fall", wet.velocity.y < dry.velocity.y * 0.55)
		wet.velocity = Vector2.ZERO
		dry.velocity = Vector2.ZERO
		wet.call("set_environment", "space", Rect2(2500, 200, 220, 500))
		for frame: int in range(12):
			await physics_frame
		_check("orbit gravity lengthens a fall", wet.velocity.y < dry.velocity.y * 0.45)
		wet.velocity = Vector2.ZERO
		dry.velocity = Vector2.ZERO
		wet.call("set_environment", "rain", Rect2(2500, 200, 220, 500))
		for frame: int in range(12):
			await physics_frame
		_check("rain gust pushes the pilot across the field", wet.velocity.x > dry.velocity.x + 35.0)
		wet.velocity = Vector2(300, 0)
		dry.velocity = Vector2(300, 0)
		wet.call("set_environment", "frost", Rect2(2500, 200, 220, 500))
		for frame: int in range(12):
			await physics_frame
		_check("frost preserves horizontal momentum", wet.velocity.x > dry.velocity.x + 40.0)
	dry.queue_free()
	wet.queue_free()
	await process_frame


func _test_gesture_controls() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	var guide_count: int = 0
	for child: Node in game.hud.help_page.find_children("*", "Control", true, false):
		if child is StitchfallGestureGuide:
			guide_count += 1
	_check("the guide illustrates all four phone gestures", guide_count == 4)
	game._on_begin()
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(500, 500)
	press.pressed = true
	game._unhandled_input(press)
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.index = 0
	release.position = Vector2(500, 500)
	release.pressed = false
	game._unhandled_input(release)
	_check("a playfield tap turns gravity once", game.gravity_direction == Vector2.LEFT)
	game.last_shift = -1.0
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._unhandled_input(click)
	_check("a synthetic mouse click after touch does not turn gravity", game.gravity_direction == Vector2.LEFT)
	_check("gravity shift has a keyboard action", InputMap.has_action("shift_gravity"))
	if InputMap.has_action("shift_gravity"):
		game.last_shift = -1.0
		var shift_key: InputEventKey = InputEventKey.new()
		shift_key.physical_keycode = KEY_SHIFT
		shift_key.pressed = true
		game._unhandled_input(shift_key)
		_check("Shift turns gravity", game.gravity_direction == Vector2.UP)
		game._unhandled_input(press)
		var inverted_jump: InputEventScreenDrag = InputEventScreenDrag.new()
		inverted_jump.index = 0
		inverted_jump.position = Vector2(500, 640)
		game._unhandled_input(inverted_jump)
		_check("a downward swipe jumps from the ceiling", game.pilot.touch_jump)
		release.position = inverted_jump.position
		game._unhandled_input(release)
		game.last_shift = -1.0
		game.last_touch_msec = -100000
		game.last_start_msec = -100000
		game._unhandled_input(click)
		_check("a mouse click turns gravity", game.gravity_direction == Vector2.RIGHT)
	game._unhandled_input(press)
	var slide: InputEventScreenDrag = InputEventScreenDrag.new()
	slide.index = 0
	slide.position = Vector2(660, 500)
	game._unhandled_input(slide)
	_check("a horizontal slide walks right", game.pilot.touch_axis == 1.0)
	release.position = slide.position
	game._unhandled_input(release)
	_check("lifting the finger stops walking", game.pilot.touch_axis == 0.0)
	game._unhandled_input(press)
	var upward: InputEventScreenDrag = InputEventScreenDrag.new()
	upward.index = 0
	upward.position = Vector2(500, 370)
	game._unhandled_input(upward)
	_check("an upward swipe queues a jump", game.pilot.touch_jump)
	release.position = upward.position
	game._unhandled_input(release)
	_check("the pilot supports a crouch action", game.pilot.has_method("set_touch_crouch"))
	if game.pilot.has_method("set_touch_crouch"):
		game._unhandled_input(press)
		var downward: InputEventScreenDrag = InputEventScreenDrag.new()
		downward.index = 0
		downward.position = Vector2(500, 640)
		game._unhandled_input(downward)
		release.position = downward.position
		game._unhandled_input(release)
		_check("a downward swipe leaves the pilot crouching", game.pilot.get("touch_crouch") == true)
		game.pilot.call("_set_crouch", true)
		var shape: CollisionShape2D = game.pilot.get_child(0) as CollisionShape2D
		_check("crouching lowers the collision shape", (shape.shape as CapsuleShape2D).height < 78.0)
		game.pilot.call("_set_crouch", false)
		_check("standing restores the collision shape", (shape.shape as CapsuleShape2D).height == 78.0)
	game.queue_free()
	await process_frame


func _test_room_clearance() -> void:
	for index: int in range(StitchfallLevels.count()):
		var level: Dictionary = StitchfallLevels.get_level(index)
		for point: Vector2 in [level["start"], level["exit"]] + level["shards"]:
			var blocked: bool = false
			for wall: Rect2 in level["walls"]:
				blocked = blocked or wall.grow(12.0).has_point(point)
			for spike: Dictionary in level["spikes"]:
				blocked = blocked or (spike["rect"] as Rect2).grow(12.0).has_point(point)
			_check("room %d keeps a goal point clear" % index, not blocked)


func _test_screen_routes() -> void:
	for id: String in StitchfallLevels.CHAPTER_IDS:
		var checks: Array[Array] = await StitchfallRoute.prove(self, id)
		for check: Array in checks:
			_check(check[0], check[1])


func _test_stitchfall_playthrough() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	_check("title opens with play disabled", not game.playing)
	game.progress.reset()
	game._load_level(0)
	game._on_begin()
	_check("start enables the pilot", game.playing and game.pilot.control_enabled)
	var start_x: float = game.pilot.position.x
	Input.action_press("move_right")
	for frame: int in range(22):
		await physics_frame
	Input.action_release("move_right")
	_check("the pilot runs across the floor", game.pilot.position.x > start_x + 45.0)
	game._shift(1)
	_check("a shift turns gravity and changes the light phase", game.gravity_direction == Vector2.LEFT and game.phase == 1)
	game._restart()
	# Dead Weight has moths, a flower, buttons and needles in one room.
	var flower_room: int = StitchfallLevels.room_of("patch", 4)
	for level_number: int in range(StitchfallLevels.count()):
		if level_number > 0:
			game._on_begin()
		if level_number == flower_room:
			var sentry_start: Vector2 = game.sentries[0].position
			for frame: int in range(12):
				await physics_frame
			_check("the needle moth patrols its track", game.sentries[0].position.distance_to(sentry_start) > 10.0)
			game.pilot.position = game.level["flowers"][0]["pos"]
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			_check("the flower blooms when the runner reaches it", game.flower_lit[0])
			game.last_shift = -1.0
			game._shift(1)
			await process_frame
			_check("shifting pauses the needle moth", game.sentries[0].freeze_remaining > 0.0 and not game.sentries[0].monitoring)
			game.pilot.position = game.level["shards"][0]
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			await physics_frame
			await physics_frame
			_check("a button is collected before a hazard hit", game.collected[0])
			game.pilot.position = game.level["spikes"][0]["rect"].get_center() + Vector2(0, -25)
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			_check("a hit scatters the fabric runner", game.respawning and not game.pilot.visible and is_instance_valid(game.unravel))
			for frame: int in range(45):
				await physics_frame
			_check("a hazard sends the runner to the flower", not game.respawning and game.pilot.visible and game.pilot.position.distance_to(game.respawn_position) < 30.0)
			_check("a loose button comes back after an unravel", not game.collected[0] and not game.banked[0])
			game.pilot.position = game.level["shards"][0]
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			game.pilot.position = game.level["flowers"][0]["pos"]
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			_check("touching the flower again banks the button", game.banked[0])
			game.pilot.position = game.level["spikes"][0]["rect"].get_center() + Vector2(0, -25)
			game.pilot.reset_physics_interpolation()
			for frame: int in range(50):
				await physics_frame
			_check("a banked button survives an unravel", game.collected[0] and game.room_deaths == 2)
		for spark: Vector2 in game.level["shards"]:
			game.pilot.position = spark
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
		_check("all buttons collect in room %d" % level_number, not game.collected.has(false))
		if game.level["pad"] != Vector2.ZERO:
			game._on_pad_body(game.cargo)
			_check("cargo plate arms in room %d" % level_number, game.pad_armed)
		_check("exit unlocks in room %d" % level_number, game.world.door_open)
		game.pilot.position = game.level["exit"]
		game.pilot.velocity = Vector2.ZERO
		game.pilot.reset_physics_interpolation()
		await physics_frame
		await physics_frame
		_check("room %d is cleared and saved" % level_number, game.cleared and game.progress.stars(level_number) > 0)
		game._on_next()
		if level_number + 1 < StitchfallLevels.count():
			_check("the next room opens after room %d" % level_number, game.level_index == level_number + 1)
	_check("the final seam ending follows the last room", game.finished)
	game.queue_free()
	await process_frame


# Stands in for AdMob with a video always ready, and an ad between rooms when asked to have one.
class _VideoAds extends StitchfallAdBackend:
	var interstitials: bool = false
	var presented: Array[StringName] = []

	func ready_to_show(kind: StringName) -> bool:
		return kind == REWARDED or interstitials

	func video_ready() -> bool:
		return true

	func present(kind: StringName) -> void:
		presented.append(kind)
		finished.emit.call_deferred(kind, true, true)


# Live, but with nothing to play: offline, no fill and no studio game to stand in.
class _NoAds extends StitchfallAdBackend:
	pass


# Whether any class in an Android library's classes.jar names `text`.
func _aar_has(path: String, text: String) -> bool:
	var aar: ZIPReader = ZIPReader.new()
	if aar.open(path) != OK:
		return false
	var jar_path: String = "user://test_classes.jar"
	var jar_file: FileAccess = FileAccess.open(jar_path, FileAccess.WRITE)
	jar_file.store_buffer(aar.read_file("classes.jar"))
	jar_file.close()
	aar.close()
	var jar: ZIPReader = ZIPReader.new()
	var found: bool = false
	if jar.open(jar_path) == OK:
		var needle: String = text.to_utf8_buffer().hex_encode()
		for name: String in jar.get_files():
			if name.ends_with(".class") and (name.contains(text) or jar.read_file(name).hex_encode().contains(needle)):
				found = true
				break
		jar.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(jar_path))
	return found


# Stands in for StitchfallPlayGames' backend, signed in, and remembers what the game asked of it.
class _PlayGamesStandIn extends Node:
	var signed_in: bool = true
	var heard: Array[String] = []
	var events: Array[Dictionary] = []

	func show_boards() -> void:
		heard.append("boards")

	func show_achievements() -> void:
		heard.append("achievements")

	func progressed() -> void:
		heard.append("progressed")

	func progress_reset() -> void:
		heard.append("reset")

	func record_event(name: String, properties: Dictionary) -> void:
		heard.append(name)
		events.append(properties)


# Stands in for the GodotPlayGameServices Android singleton: it signs nobody in by itself, and remembers each call.
class _FakePlayGames extends RefCounted:
	signal userAuthenticated(ok: bool)
	signal gameLoaded(json: String)

	var calls: Array[Array] = []

	func initialize() -> void:
		calls.append(["initialize"])

	func isAuthenticated() -> void:
		calls.append(["isAuthenticated"])

	func signIn() -> void:
		calls.append(["signIn"])

	func showAllLeaderboards() -> void:
		calls.append(["showAllLeaderboards"])

	func showAchievements() -> void:
		calls.append(["showAchievements"])

	func unlockAchievement(id: String) -> void:
		calls.append(["unlockAchievement", id])

	func setAchievementSteps(id: String, steps: int) -> void:
		calls.append(["setAchievementSteps", id, steps])

	func submitScore(id: String, score: int) -> void:
		calls.append(["submitScore", id, score])

	func recordGameEvent(name: String, properties: Dictionary) -> void:
		calls.append(["recordGameEvent", name, properties])

	func uploadGameEvents() -> void:
		calls.append(["uploadGameEvents"])

	func loadGame(name: String, create: bool) -> void:
		calls.append(["loadGame", name, create])

	func saveGame(name: String, description: String, data: PackedByteArray, played: int, progress: int) -> void:
		calls.append(["saveGame", name, description, data, played, progress])

	func named(method: String) -> int:
		return calls.filter(func(call: Array) -> bool: return call[0] == method).size()

	func named_with(method: String, id: String) -> bool:
		return calls.any(func(call: Array) -> bool: return call[0] == method and call.size() > 1 and call[1] == id)

	# Whether `method` went with this id, and with this value when one is given.
	func sent(method: String, id: String, value: int = -1) -> bool:
		return calls.any(func(call: Array) -> bool:
			return call[0] == method and call[1] == id and (value < 0 or int(call[2]) == value))

	# The properties of the last event of this name.
	func event(name: String) -> Dictionary:
		var found: Dictionary = {}
		for call: Array in calls:
			if call[0] == "recordGameEvent" and call[1] == name:
				found = call[2]
		return found

	func last(method: String) -> Array:
		var found: Array = []
		for call: Array in calls:
			if call[0] == method:
				found = call
		return found
