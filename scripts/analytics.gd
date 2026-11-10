class_name StitchfallAnalytics
extends RefCounted

# Google Analytics for Firebase, as the kit's Analytics counts, in Stitchfall's terms: where players get stuck and
# where they give up, from room starts, clears, unravels and skips. Android only, so the browser build counts
# nothing.
#
# Counting waits for Google's consent service (UMP) to say no consent is needed here, so the EEA, the UK and
# Switzerland are never counted. Nothing counted serves ads: every advertising signal stays denied, and
# addons/firebase_build keeps the advertising id out of the build. Debug builds never count.

const FIREBASE_CORE: String = "GodotxFirebaseCore"
const FIREBASE: String = "GodotxFirebaseAnalytics"
# Read from the AdMob plugin's singleton rather than its classes, which the browser build leaves out.
const CONSENT: String = "PoingGodotAdMobConsentInformation"
# UMP's ConsentStatus.NOT_REQUIRED.
const CONSENT_NOT_REQUIRED: int = 1

# For the robots: hears every event as (name, params), counted or not.
static var sink: Callable = Callable()

static var _firebase: Object
static var _counting: bool = false
static var _started_at: int = 0


static func start() -> void:
	if _firebase != null or not OS.has_feature("android") or not Engine.has_singleton(FIREBASE):
		return
	if Engine.has_singleton(FIREBASE_CORE):
		Engine.get_singleton(FIREBASE_CORE).call("initialize")
	_firebase = Engine.get_singleton(FIREBASE)
	_firebase.call("initialize")
	refresh()


# Firebase keeps the choice across launches, so it is set either way. Every way through the consent message calls
# this, from scripts/android/admob.gd or scripts/android/consent.gd.
static func refresh() -> void:
	if _firebase == null:
		return
	var status: int = 0
	if Engine.has_singleton(CONSENT):
		status = int(Engine.get_singleton(CONSENT).call("get_consent_status"))
	_counting = counts(status, OS.is_debug_build())
	_firebase.call("set_consent", {"analytics_storage": "granted" if _counting else "denied"})
	_firebase.call("set_analytics_collection_enabled", _counting)


static func counts(consent_status: int, debug: bool) -> bool:
	return consent_status == CONSENT_NOT_REQUIRED and not debug


static func counting() -> bool:
	return _counting


# GA4 limits: a short snake_case name and a few numbers or short strings.
static func event(name: StringName, params: Dictionary = {}) -> void:
	if sink.is_valid():
		sink.call(name, params)
	if _counting:
		_firebase.call("log_event", String(name), for_ga(params))


# Parameters GA4 reports as custom dimensions, which it fills only from text: sent as numbers they arrive as
# "(not set)". Stars, seconds and counts stay numbers, for their metrics.
const AS_TEXT: Array[String] = ["level", "success", "room"]


static func for_ga(params: Dictionary) -> Dictionary:
	var sent: Dictionary = params.duplicate()
	for key: String in AS_TEXT:
		if sent.has(key):
			sent[key] = str(sent[key])
	return sent


# Rooms reach Analytics numbered from 1, as players see them.
static func room_started(index: int) -> void:
	_started_at = Time.get_ticks_msec()
	event(&"room_start", {"room": index + 1})


static func room_cleared(index: int, stars: int, unravels: int) -> void:
	event(&"room_clear", {"room": index + 1, "stars": stars, "seconds": _seconds(), "unravels": unravels})


static func unravelled(index: int, count: int) -> void:
	event(&"room_unravel", {"room": index + 1, "count": count})


static func skipped(index: int, unravels: int, cost: String) -> void:
	event(&"room_skip", {"room": index + 1, "unravels": unravels, "seconds": _seconds(), "cost": cost})


# A pack or a tip that Google Play has confirmed. Play's own purchase events reach Firebase too, with the price.
static func bought(id: String) -> void:
	event(&"purchase_made", {"item": id})


static func screen(name: String) -> void:
	event(&"screen_view", {"screen_name": name, "screen_class": name})


static func _seconds() -> int:
	@warning_ignore("integer_division")
	return (Time.get_ticks_msec() - _started_at) / 1000
