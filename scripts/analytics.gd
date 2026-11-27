class_name StitchfallAnalytics
extends RefCounted

# Google Analytics for Firebase, as the kit's Analytics counts, in Stitchfall's terms: where players get stuck and
# where they give up, from room starts, clears, unravels and skips. Android only, so the browser build counts
# nothing.
#
# Counting happens only where no consent is needed, and nothing is asked: the EEA, the UK and Switzerland are never
# counted. The region comes from the phone's time zone setting, never its location or its language: a zone of those
# countries counts nothing, and so does a phone whose zone cannot be read while its clock is on Europe's offsets.
# Firebase starts every launch with collection off and every consent signal denied (the godotx_firebase preset's
# privacy-safe defaults), and only a phone that counts turns collection and analytics storage on. Nothing counted
# serves ads: the ad signals stay denied, and addons/firebase_build keeps the advertising id and its permission out
# of the build. Debug builds never count. Firebase keeps the last launch's choice, so a phone that counted last time
# logs Firebase's own launch events (session_start, app_update) for a moment before this launch decides again: one
# launch's automatic events from a phone that has just come into Europe.

const FIREBASE_CORE: String = "GodotxFirebaseCore"
const FIREBASE: String = "GodotxFirebaseAnalytics"
# The time zones of the EEA (the EU, Iceland, Liechtenstein and Norway), the UK and Switzerland: tzdata's zone.tab
# entries for those countries and for the regions with codes of their own (Réunion, Mayotte, Guadeloupe, Martinique,
# French Guiana, Saint Martin, Svalbard, Åland), then the old and shared names tzdata links straight to one of them
# (GB, Eire, Poland, Portugal, Iceland, CET and the like, the Crown Dependencies, Monaco, San Marino and the Vatican).
const CONSENT_ZONES: PackedStringArray = [
	"Africa/Ceuta", "America/Cayenne", "America/Guadeloupe", "America/Marigot", "America/Martinique",
	"Arctic/Longyearbyen", "Asia/Famagusta", "Asia/Nicosia", "Atlantic/Azores", "Atlantic/Canary", "Atlantic/Madeira",
	"Atlantic/Reykjavik", "Europe/Amsterdam", "Europe/Athens", "Europe/Berlin", "Europe/Bratislava", "Europe/Brussels",
	"Europe/Bucharest", "Europe/Budapest", "Europe/Busingen", "Europe/Copenhagen", "Europe/Dublin", "Europe/Helsinki",
	"Europe/Lisbon", "Europe/Ljubljana", "Europe/London", "Europe/Luxembourg", "Europe/Madrid", "Europe/Malta",
	"Europe/Mariehamn", "Europe/Oslo", "Europe/Paris", "Europe/Prague", "Europe/Riga", "Europe/Rome", "Europe/Sofia",
	"Europe/Stockholm", "Europe/Tallinn", "Europe/Vaduz", "Europe/Vienna", "Europe/Vilnius", "Europe/Warsaw",
	"Europe/Zagreb", "Europe/Zurich", "Indian/Mayotte", "Indian/Reunion",
	"Atlantic/Jan_Mayen", "CET", "EET", "Eire", "Europe/Belfast", "Europe/Guernsey", "Europe/Isle_of_Man",
	"Europe/Jersey", "Europe/Monaco", "Europe/Nicosia", "Europe/San_Marino", "Europe/Vatican", "GB", "GB-Eire",
	"Iceland", "MET", "Poland", "Portugal", "WET",
]
# Europe's UTC offsets through the year, in minutes: the Azores in winter to Finland in summer. Used only when the
# phone's zone cannot be read.
const EUROPE_BIAS: Vector2i = Vector2i(-60, 180)

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
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var zone: String = zone_id()
	var needs_consent: bool = consent_needed(zone, bias)
	_counting = counts(needs_consent, OS.is_debug_build())
	if OS.is_debug_build():
		print("Analytics: zone \"%s\", bias %d, consent needed %s" % [zone, bias, needs_consent])
	# Firebase keeps the choice across launches, so both are set on every launch, either way.
	_firebase.call("set_consent", {"analytics_storage": "granted" if _counting else "denied"})
	_firebase.call("set_analytics_collection_enabled", _counting)


static func counts(needs_consent: bool, debug: bool) -> bool:
	return not needs_consent and not debug


# `zone` is an IANA time zone id such as "Asia/Kolkata", or "" when the phone's could not be read. A generic zone (UTC,
# Etc/GMT-1) says nothing about where the phone is, so it is judged by the clock alone, like an unread one.
static func consent_needed(zone: String, bias_minutes: int) -> bool:
	if CONSENT_ZONES.has(zone):
		return true
	if zone.contains("/") and not zone.begins_with("Etc/"):
		return false
	return bias_minutes >= EUROPE_BIAS.x and bias_minutes <= EUROPE_BIAS.y


# Android's own time zone id. Godot's Time gives only an offset and an abbreviation, and "IST" is India, Ireland and
# Israel alike.
static func zone_id() -> String:
	var zones: Object = JavaClassWrapper.wrap("java.util.TimeZone")
	if zones == null:
		return ""
	var zone: Object = zones.call("getDefault")
	if zone == null or JavaClassWrapper.get_exception() != null:
		return ""
	var id: Variant = zone.call("getID")
	return String(id) if id is String else ""


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


static func skipped(index: int, unravels: int) -> void:
	event(&"room_skip", {"room": index + 1, "unravels": unravels, "seconds": _seconds()})


# A pack or a tip that Google Play has confirmed. Play's own purchase events reach Firebase too, with the price.
static func bought(id: String) -> void:
	event(&"purchase_made", {"item": id})


static func screen(name: String) -> void:
	event(&"screen_view", {"screen_name": name, "screen_class": name})


static func _seconds() -> int:
	@warning_ignore("integer_division")
	return (Time.get_ticks_msec() - _started_at) / 1000
