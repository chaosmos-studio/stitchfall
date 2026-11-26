class_name StitchfallAnalytics
extends RefCounted

# Google Analytics for Firebase, as the kit's Analytics counts, in Stitchfall's terms: where players get stuck and
# where they give up, from room starts, clears, unravels and skips. Android only, so the browser build counts
# nothing.
#
# Counting happens only where no consent is needed, and nothing is asked: the EEA, the UK and Switzerland are never
# counted. The region is a guess from the phone's own settings, never its location: a clock on Europe's time zones,
# with a locale that names a European country, no country, or the US English many phones keep. So a European phone
# set to US English is not counted, and an Indian phone set to UK English is. Nothing counted serves ads: every
# advertising signal stays denied, and addons/firebase_build keeps the advertising id and its permission out of the
# build. Debug builds never count.

const FIREBASE_CORE: String = "GodotxFirebaseCore"
const FIREBASE: String = "GodotxFirebaseAnalytics"
# The EEA (the EU, Iceland, Liechtenstein and Norway), the UK and Switzerland, as ISO 3166 codes.
const CONSENT_REGIONS: PackedStringArray = [
	"AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT",
	"NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO", "GB", "CH",
]
# Europe's UTC offsets through the year, in minutes: the Azores in winter to Finland in summer.
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
	_counting = counts(consent_needed(OS.get_locale(), bias), OS.is_debug_build())
	# Firebase keeps the choice across launches, so it is set either way.
	_firebase.call("set_consent", {"analytics_storage": "granted" if _counting else "denied"})
	_firebase.call("set_analytics_collection_enabled", _counting)


static func counts(needs_consent: bool, debug: bool) -> bool:
	return not needs_consent and not debug


static func consent_needed(locale: String, bias_minutes: int) -> bool:
	if bias_minutes < EUROPE_BIAS.x or bias_minutes > EUROPE_BIAS.y:
		return false
	var region: String = country(locale)
	return region == "" or region == "US" or CONSENT_REGIONS.has(region)


# The region of a locale such as "en_GB" or "sr_Latn_RS", or "" when it names none.
static func country(locale: String) -> String:
	var parts: PackedStringArray = locale.split("_")
	for i: int in range(parts.size() - 1, 0, -1):
		if parts[i].length() == 2:
			return parts[i].to_upper()
	return ""


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
