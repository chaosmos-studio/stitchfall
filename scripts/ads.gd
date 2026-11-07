class_name StitchfallAds
extends RefCounted

# The kit's ads (kit/monetize/ads.gd in the kit games), placed for a landscape platformer. An ad that is not
# loaded simply does not show, so the game never waits for one, and nothing ever shows during play.
#
# - A banner only on the menu pages (BANNER_SCREENS), once StitchfallAdPacing.BANNER_AFTER rooms are sewn: a
#   320 dp strip centred at the foot of the screen, clear of Android's gesture area. The page it sits under
#   shrinks until every button keeps BUTTON_GAP_DP above it, by AdMob's accidental-click guidance.
# - An ad between rooms only from Next on the clear card (maybe_interstitial), paced by StitchfallAdPacing.
# - A rewarded video for one thing, skipping a room the runner keeps unravelling in (rewarded).
# Android only. Debug builds always ask for Google's test units (scripts/android/admob.gd). The Supporter pack
# turns all of it off for good. The studio's house ads fill in whenever AdMob has nothing to give.

const ADMOB_SCRIPT: String = "res://scripts/android/admob.gd"
const BANNER_WIDTH_DP: float = 320.0
const BANNER_HEIGHT_DP: float = 50.0
# Clear space between the banner and the system navigation, in dp, so a swipe home never starts on the ad.
# AdMob counts a tap made while leaving the app as invalid.
const EDGE_DP: float = 24.0
# The least the banner's bottom ever sits above the screen's edge, in dp. Full screen, the inset is 0 but
# Android still keeps a 32 dp strip at the bottom for the swipe home (the kit measured it on a Nothing phone).
const FLOOR_DP: float = 48.0
# The space kept between the banner's top and the lowest button or line of a page, in dp.
const BUTTON_GAP_DP: float = 40.0
# A desktop preview has no density to read, so it draws the banner as a landscape phone this tall would.
const PREVIEW_HEIGHT_DP: float = 400.0
# Above the hud, as AdMob's own view is above the game.
const BANNER_LAYER: int = 4
const BANNER_SCREENS: PackedStringArray = ["levels", "wardrobe", "settings", "about", "credits", "stats"]

# The game's progress, set at launch, which says how many rooms are sewn and whether the Supporter pack is owned.
static var progress: StitchfallProgress
# Desktop captures only: shows the house banner where a phone's banner would be.
static var preview: bool = false
# Lets a robot skip the pacing gaps without waiting.
static var skew: float = 0.0
# The hud hears here how far down its menu pages may reach, in design pixels, whenever that changes.
static var on_limit: Callable = Callable()

static var _backend: StitchfallAdBackend
static var _since: int = 0
static var _last_fullscreen: float = -1.0
static var _busy: bool = false
static var _page: bool = false
static var _covers: int = 0
# The banner's own height in design pixels once one is loaded, else 0.
static var _height: float = 0.0
static var _wanted: bool = false
static var _showing: bool = false
static var _told: float = -1.0
static var _stand_in: CanvasLayer


# Called at launch once progress is loaded, and again when Play says the Supporter pack is no longer owned.
static func start() -> void:
	if supporter():
		return
	if is_instance_valid(_backend):
		_backend.resume()
		refresh()
		return
	if not OS.has_feature("android"):
		return
	if not StitchfallMonetize.ADMOB:
		_attach(StitchfallHouseAds.new(), true)
		return
	if not Engine.has_singleton("PoingGodotAdMob"):
		return
	var admob: GDScript = load(ADMOB_SCRIPT)
	_attach(admob.new() as StitchfallAdBackend, true)


static func use(backend: StitchfallAdBackend) -> void:
	if is_instance_valid(_backend):
		_backend.queue_free()
	_backend = null
	_since = 0
	_last_fullscreen = -1.0
	_busy = false
	_height = 0.0
	if backend != null:
		_attach(backend, false)


static func supporter() -> bool:
	return progress != null and StitchfallShop.ads_off(progress)


static func live() -> bool:
	return is_instance_valid(_backend) and not supporter()


static func rewards() -> bool:
	return live()


static func video_ready() -> bool:
	return live() and _backend.video_ready()


# How a reward is earned, for the line that offers one: a video when AdMob has one ready, and otherwise a quick
# game of the studio's.
static func watch() -> String:
	return "Watch a video" if video_ready() else "Try a quick game"


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0 + skew


static func sewn() -> int:
	return progress.best_stars.size() if progress != null else 0


static func is_busy() -> bool:
	return _busy


# The hud hears how far down its menu pages may reach, now and on every change.
static func listen(callback: Callable) -> void:
	on_limit = callback
	_told = -1.0
	_tell()


# The hud says whether the page now open is one that carries the banner.
static func want_banner(on: bool) -> void:
	_page = on
	refresh()


# Works out from scratch whether the banner is on screen, and tells the backend and the hud. Everything that can
# change the answer calls this: a page opening, a full-screen moment, a banner loading, the Supporter pack.
static func refresh() -> void:
	_wanted = _page and StitchfallAdPacing.banner_due(sewn(), supporter()) and (preview or live())
	_showing = _wanted and _covers == 0
	if preview:
		_place_stand_in()
	elif is_instance_valid(_stand_in):
		_stand_in.visible = false
	if not preview and live() and _backend.is_inside_tree():
		_backend.set_banner(_showing)
	_tell()


static func banner_wanted() -> bool:
	return _wanted


# A full-screen moment (the house ads' quick game) hides the banner while it is open.
static func cover(on: bool) -> void:
	_covers = maxi(_covers + (1 if on else -1), 0)
	refresh()


# Design pixels per dp. A phone reports its density, and a desktop preview assumes a landscape phone.
static func per_dp() -> float:
	var view: Vector2 = _view()
	var dpi: float = float(DisplayServer.screen_get_dpi())
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	if OS.has_feature("android") and dpi > 0.0 and window.x > 0.0:
		return view.x / (window.x * 160.0 / dpi)
	return view.y / PREVIEW_HEIGHT_DP


# The gap in dp above a system navigation inset `inset_dp` tall, which AdMob's own banner keeps too.
static func gap_dp(inset_dp: float) -> float:
	return maxf(EDGE_DP, FLOOR_DP - inset_dp)


# Where the banner stands, in design pixels of the root viewport: centred, its foot clear of the navigation.
static func banner_rect() -> Rect2:
	var view: Vector2 = _view()
	var unit: float = per_dp()
	var inset: float = inset_dp()
	var high: float = maxf(_height, BANNER_HEIGHT_DP * unit)
	var wide: float = BANNER_WIDTH_DP * unit
	var bottom: float = view.y - (inset + gap_dp(inset)) * unit
	return Rect2((view.x - wide) * 0.5, bottom - high, wide, high)


# How far down a menu page may reach: BUTTON_GAP_DP above the banner while one is due, else the screen's foot.
static func content_limit() -> float:
	if not _wanted:
		return _view().y
	return banner_rect().position.y - BUTTON_GAP_DP * per_dp()


# The system navigation inset at the screen's foot, in dp, which AdMob's custom position leaves out.
static func inset_dp() -> float:
	if not OS.has_feature("android"):
		return 0.0
	var dpi: float = float(DisplayServer.screen_get_dpi())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var screen: Vector2i = DisplayServer.screen_get_size()
	return maxf(0.0, float(screen.y - safe.end.y)) * 160.0 / dpi if dpi > 0.0 else 0.0


# `quiet` is true when Next leads into a chapter's title card, which no ad may stand beside.
static func maybe_interstitial(on_done: Callable, quiet: bool = false) -> void:
	if quiet or _busy or not live() or not interstitial_due() or not _backend.ready_to_show(StitchfallAdBackend.INTERSTITIAL):
		on_done.call()
		return
	_busy = true
	_backend.present(StitchfallAdBackend.INTERSTITIAL)
	var result: Array = await _backend.finished
	_busy = false
	if bool(result[1]):
		_last_fullscreen = now()
		_since = 0
		StitchfallAnalytics.event(&"ad_shown", {"kind": "interstitial", "place": "next"})
	if on_done.is_valid():
		on_done.call()


static func interstitial_due() -> bool:
	return StitchfallAdPacing.interstitial_due(sewn(), _since, now(), _last_fullscreen, supporter())


# Every cleared room counts toward the next ad between rooms, replays included, as the kit counts solves.
static func room_cleared() -> void:
	_since += 1


# `on_unavailable` runs when nothing can play (offline, no fill, consent refused, no game to show). An ad closed
# early runs neither callback.
static func rewarded(on_reward: Callable, on_unavailable: Callable, place: String = "skip") -> void:
	if _busy or not live() or not _backend.ready_to_show(StitchfallAdBackend.REWARDED):
		on_unavailable.call()
		return
	_busy = true
	var kind: String = "video" if _backend.video_ready() else "quick_game"
	_backend.present(StitchfallAdBackend.REWARDED)
	var result: Array = await _backend.finished
	_busy = false
	var shown: bool = result[1]
	if shown:
		_last_fullscreen = now()
		StitchfallAnalytics.event(&"ad_shown", {"kind": kind, "place": place})
	if bool(result[2]):
		if on_reward.is_valid():
			on_reward.call()
	elif not shown and on_unavailable.is_valid():
		on_unavailable.call()


# UMP says whether the player must be able to change their consent. Settings shows Privacy choices only then.
static func privacy_options_required() -> bool:
	return live() and _backend.privacy_required()


static func open_privacy_options() -> void:
	if live():
		_backend.open_privacy()


static func match_sound() -> void:
	if live():
		_backend.match_sound(progress == null or progress.sound)


# Android's back closes the quick game standing in for a video, if one is open, and says so.
static func back() -> bool:
	return StitchfallHouseAds.close_card()


static func stop() -> void:
	if is_instance_valid(_backend):
		_backend.stop()
	_height = 0.0
	refresh()


# A backend is added to the tree a frame late, while the first page may already ask for the banner: the banner
# is applied once the backend is there to take it.
static func _attach(backend: StitchfallAdBackend, deferred: bool) -> void:
	_backend = backend
	backend.banner_changed.connect(_on_banner)
	backend.ready.connect(refresh, CONNECT_ONE_SHOT)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if deferred:
		tree.root.add_child.call_deferred(backend)
	else:
		tree.root.add_child(backend)


static func _on_banner(height: float) -> void:
	_height = height
	_tell()


static func _view() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size


# Only a change is told, since the hud lays its pages out again when it hears.
static func _tell() -> void:
	var limit: float = content_limit()
	if is_equal_approx(limit, _told):
		return
	_told = limit
	if on_limit.is_valid():
		on_limit.call(limit)


# Desktop captures: the house banner, where and as large as a phone would show the strip. It is made once, added
# a frame late since a page may open while the tree is still setting up, and only hidden after that.
static func _place_stand_in() -> void:
	if is_instance_valid(_stand_in):
		_stand_in.visible = _showing
	if not _showing or StitchfallStudio.others().is_empty():
		return
	if not is_instance_valid(_stand_in):
		_stand_in = CanvasLayer.new()
		_stand_in.layer = BANNER_LAYER
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_stand_in)
		var strip: StitchfallHouseBanner = StitchfallHouseBanner.new()
		_stand_in.add_child(strip)
		strip.show_game(StitchfallHouseAds.next_game())
	var box: Control = _stand_in.get_child(0) as Control
	var rect: Rect2 = banner_rect()
	box.position = rect.position
	box.size = rect.size
