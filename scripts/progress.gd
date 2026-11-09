class_name StitchfallProgress
extends RefCounted

# What the player has done and chosen, kept between visits on their own device: each room's best stars and
# best time, the rooms skipped, what they wear and own, their settings, lifetime stats and where Play's review
# card stands. A room opens once the room before it is sewn or skipped. Tests point path at a scratch file.

static var path: String = "user://progress.cfg"

const STAR_NAMES: PackedStringArray = ["Sewn", "Unbroken", "Quick"]

var best_stars: Dictionary[int, int] = {}
var best_time: Dictionary[int, float] = {}
# Rooms skipped without being sewn. Each still opens the room after it, and earns no stars.
var skipped: Dictionary[int, bool] = {}
# Rooms ever sewn without an unravel, and ever sewn inside their par time: the Unbroken and Quick stars, kept
# apart since a room's best stars alone cannot say which two of three it earned. Play Games' achievements read them.
var unbroken: Dictionary[int, bool] = {}
var quick: Dictionary[int, bool] = {}
var wear: Dictionary = StitchfallLooks.DEFAULTS.duplicate()
var owned: Dictionary = {}
var tips: int = 0
var sound: bool = true
var music: bool = true
var shake: bool = true
# The thread a sliding finger draws on the room (swipe_thread.gd), which a player may turn off.
var thread: bool = true
var unravels: int = 0
var turns: int = 0
var buttons: int = 0
# Buttons a flower has sewn on, so an unravel can no longer shake them loose.
var banked: int = 0
var play_time: float = 0.0
# The rooms sewn when Play's review card was last asked for, and whether Rate has opened the Play page.
var rate_asked: int = 0
var rated: bool = false
# Whether the first room's coach has taught the controls. Someone who sewed a room before it existed counts as
# taught.
var coached: bool = false


# One star for finishing, one for finishing without an unravel, one for beating the room's par time.
static func stars_for(time: float, unravel_count: int, par: float) -> int:
	return 1 + (1 if unravel_count == 0 else 0) + (1 if time <= par else 0)


static func star_earned(star: int, time: float, unravel_count: int, par: float) -> bool:
	match star:
		1:
			return unravel_count == 0
		2:
			return time <= par
	return true


func load_saved() -> void:
	best_stars.clear()
	best_time.clear()
	skipped.clear()
	unbroken.clear()
	quick.clear()
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return
	for key: String in _keys(file, "skipped"):
		skipped[key.to_int()] = true
	for key: String in _keys(file, "unbroken"):
		unbroken[key.to_int()] = true
	for key: String in _keys(file, "quick"):
		quick[key.to_int()] = true
	rate_asked = file.get_value("rating", "asked", 0)
	rated = file.get_value("rating", "rated", false)
	for key: String in _keys(file, "stars"):
		var stars: int = file.get_value("stars", key, 0)
		best_stars[key.to_int()] = stars
	for key: String in _keys(file, "time"):
		var time: float = file.get_value("time", key, 0.0)
		best_time[key.to_int()] = time
	for kind: String in StitchfallLooks.KINDS:
		var id: String = file.get_value("wear", kind, StitchfallLooks.DEFAULTS[kind])
		wear[kind] = id if not StitchfallLooks.find(id).is_empty() else StitchfallLooks.DEFAULTS[kind]
	for key: String in _keys(file, "owned"):
		owned[key] = true
	tips = file.get_value("stats", "tips", 0)
	unravels = file.get_value("stats", "unravels", 0)
	turns = file.get_value("stats", "turns", 0)
	buttons = file.get_value("stats", "buttons", 0)
	banked = file.get_value("stats", "banked", 0)
	play_time = file.get_value("stats", "play_time", 0.0)
	sound = file.get_value("settings", "sound", true)
	music = file.get_value("settings", "music", true)
	shake = file.get_value("settings", "shake", true)
	thread = file.get_value("settings", "thread", true)
	coached = file.get_value("settings", "coached", not best_stars.is_empty())


func _keys(file: ConfigFile, section: String) -> PackedStringArray:
	return file.get_section_keys(section) if file.has_section(section) else PackedStringArray()


func save() -> void:
	var file: ConfigFile = ConfigFile.new()
	for room: int in best_stars:
		file.set_value("stars", str(room), best_stars[room])
	for room: int in best_time:
		file.set_value("time", str(room), best_time[room])
	for room: int in skipped:
		file.set_value("skipped", str(room), true)
	for room: int in unbroken:
		file.set_value("unbroken", str(room), true)
	for room: int in quick:
		file.set_value("quick", str(room), true)
	file.set_value("rating", "asked", rate_asked)
	file.set_value("rating", "rated", rated)
	for kind: String in wear:
		file.set_value("wear", kind, wear[kind])
	for id: String in owned:
		file.set_value("owned", id, true)
	file.set_value("stats", "tips", tips)
	file.set_value("stats", "unravels", unravels)
	file.set_value("stats", "turns", turns)
	file.set_value("stats", "buttons", buttons)
	file.set_value("stats", "banked", banked)
	file.set_value("stats", "play_time", play_time)
	file.set_value("settings", "sound", sound)
	file.set_value("settings", "music", music)
	file.set_value("settings", "shake", shake)
	file.set_value("settings", "thread", thread)
	file.set_value("settings", "coached", coached)
	file.save(path)


# Records a cleared room and says what improved, so the clear card can call out a new best and what the new
# stars opened in the wardrobe.
func record(room: int, time: float, unravel_count: int, par: float) -> Dictionary:
	var stars_before: int = total_stars()
	var stars: int = stars_for(time, unravel_count, par)
	var old_stars: int = best_stars.get(room, 0)
	var old_time: float = best_time.get(room, INF)
	best_stars[room] = maxi(old_stars, stars)
	best_time[room] = minf(old_time, time)
	if star_earned(1, time, unravel_count, par):
		unbroken[room] = true
	if star_earned(2, time, unravel_count, par):
		quick[room] = true
	save()
	return {
		"stars": stars,
		"more_stars": stars > old_stars and old_stars > 0,
		"faster": time < old_time and old_time < INF,
		"first": old_stars == 0,
		"opened": StitchfallLooks.opened_between(stars_before, total_stars()),
	}


func stars(room: int) -> int:
	return best_stars.get(room, 0)


func is_open(room: int) -> bool:
	return room == 0 or stars(room - 1) > 0 or skipped.has(room - 1)


# A skip opens the next room and saves at once, with no stars for the room skipped.
func skip(room: int) -> void:
	skipped[room] = true
	save()


# Where Play picks up: the first room neither sewn nor skipped, then the first skipped room not yet sewn, or the
# first room once every room is sewn.
func continue_room(count: int) -> int:
	for room: int in range(count):
		if stars(room) == 0 and not skipped.has(room):
			return room
	for room: int in range(count):
		if stars(room) == 0:
			return room
	return 0


func total_stars() -> int:
	var total: int = 0
	for room: int in best_stars:
		total += best_stars[room]
	return total


func chapter_stars(first: int, rooms: int) -> int:
	var total: int = 0
	for room: int in range(first, first + rooms):
		total += stars(room)
	return total


# Clears rooms, stars, skips, stats and what is worn. Purchases and tips stay, since Google Play still has them.
func reset() -> void:
	best_stars.clear()
	best_time.clear()
	skipped.clear()
	unbroken.clear()
	quick.clear()
	wear = StitchfallLooks.DEFAULTS.duplicate()
	unravels = 0
	turns = 0
	buttons = 0
	banked = 0
	play_time = 0.0
	coached = false
	save()
