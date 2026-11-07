class_name StitchfallPlayCore
extends RefCounted

# Google Play's in-app review card and in-app updates, as the kit's PlayCore and RatePrompt work, through the Java
# helper that addons/play_core builds into the Android app. Without it (the browser, the desktop, a robot) every
# call does nothing, and `review` goes straight on.
#
# The review card: Google's rules say nothing of the game's may come before the card or ask whether the game is
# liked, and no button may call it, since Play shows it only so often. So it comes unasked as Next leaves the clear
# card of a chapter's last room, once MILESTONES rooms are sewn, and About's Rate opens the Play page instead.
# Play never says whether a rating came, so the game goes on the same either way.
#
# Updates are flexible: Play asks once whether to download, the game goes on meanwhile, and once the update is in,
# Home or the Levels page offers to restart into it. Never mid-room.

const HELPER: String = "studio.chaosmos.kit.PlayCore"
# Rooms sewn before each ask, each at the next chapter's end.
const MILESTONES: Array[int] = [10, 25]
# Play's own auto-update reaches most phones within a day or two of a release, so the game offers an update only
# once it has been out this long, and after one offer stays quiet for QUIET_DAYS whatever the answer.
const STALE_DAYS: int = 2
const QUIET_DAYS: int = 7
# Seconds after launch before looking for an update, so Play's dialog never lands on the splash.
const UPDATE_AFTER: float = 2.0
# How long Next waits for Play to start the review card before it goes on without it.
const REVIEW_WAIT: float = 3.0
const POLL: float = 0.1

static var _helper: Object
static var _watch: _Watch
static var _offered: bool = false


# `offer` is asked once a second, after an update has downloaded, to offer the restart: it returns whether it did.
static func start(offer: Callable) -> void:
	if is_instance_valid(_watch) or not available():
		return
	_watch = _Watch.new()
	_watch.offer = offer
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_watch)


static func available() -> bool:
	if _helper == null and StitchfallShop.on_play and Engine.has_singleton("AndroidRuntime"):
		_helper = JavaClassWrapper.wrap(HELPER)
	return _helper != null


# The milestone reached and not yet asked at, or 0. Only Google Play's build asks, and never after Rate.
static func review_due(progress: StitchfallProgress) -> int:
	if not StitchfallShop.on_play or progress.rated:
		return 0
	var sewn: int = progress.best_stars.size()
	var reached: int = 0
	for milestone: int in MILESTONES:
		if sewn >= milestone and milestone > progress.rate_asked:
			reached = milestone
	return reached


static func ask(progress: StitchfallProgress, milestone: int, then: Callable) -> void:
	progress.rate_asked = milestone
	progress.save()
	StitchfallAnalytics.event(&"review_ask", {"sewn": milestone})
	review(then)


# Play's review card, then `then`. Play decides whether the card shows at all.
static func review(then: Callable = Callable()) -> void:
	if not available():
		_go(then)
		return
	_helper.call("requestReview", _activity())
	_await_review(then, REVIEW_WAIT)


# About's Rate button. Play never says whether a rating came of it, so the card stops after this.
static func rate(progress: StitchfallProgress) -> void:
	progress.rated = true
	progress.save()
	OS.shell_open(StitchfallShop.STORE)


static func update_ready() -> bool:
	return available() and String(_helper.call("updateState")) == "downloaded"


static func restart_into_update() -> void:
	if available():
		_helper.call("completeUpdate")


static func _activity() -> Object:
	return Engine.get_singleton("AndroidRuntime").call("getActivity")


static func _await_review(then: Callable, left: float) -> void:
	if String(_helper.call("reviewState")) != "asking" or left <= 0.0:
		_go(then)
		return
	(Engine.get_main_loop() as SceneTree).create_timer(POLL).timeout.connect(
		func() -> void: _await_review(then, left - POLL))


static func _go(then: Callable) -> void:
	if then.is_valid():
		then.call()


static func _check_update() -> void:
	if available():
		_helper.call("checkForUpdate", _activity(), STALE_DAYS, QUIET_DAYS)


static func _maybe_offer(offer: Callable) -> void:
	if _offered or not update_ready() or not offer.is_valid():
		return
	_offered = bool(offer.call())


class _Watch extends Node:
	var offer: Callable

	func _ready() -> void:
		get_tree().create_timer(StitchfallPlayCore.UPDATE_AFTER).timeout.connect(StitchfallPlayCore._check_update)
		var timer: Timer = Timer.new()
		timer.wait_time = 1.0
		timer.timeout.connect(func() -> void: StitchfallPlayCore._maybe_offer(offer))
		add_child(timer)
		timer.start()
