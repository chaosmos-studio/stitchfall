class_name StitchfallProgress
extends RefCounted

# What the player has done and chosen, kept between visits on their own device: each room's best stars and
# best time, what they wear and own, their settings, and lifetime stats. Nothing leaves the device.
# A room opens once the room before it is sewn. Tests point path at a scratch file.

static var path: String = "user://progress.cfg"

const STAR_NAMES: PackedStringArray = ["Sewn", "Unbroken", "Quick"]

var best_stars: Dictionary[int, int] = {}
var best_time: Dictionary[int, float] = {}
var wear: Dictionary = StitchfallLooks.DEFAULTS.duplicate()
var owned: Dictionary = {}
var tips: int = 0
var sound: bool = true
var music: bool = true
var shake: bool = true
var unravels: int = 0
var turns: int = 0
var buttons: int = 0
var play_time: float = 0.0


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
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return
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
	play_time = file.get_value("stats", "play_time", 0.0)
	sound = file.get_value("settings", "sound", true)
	music = file.get_value("settings", "music", true)
	shake = file.get_value("settings", "shake", true)


func _keys(file: ConfigFile, section: String) -> PackedStringArray:
	return file.get_section_keys(section) if file.has_section(section) else PackedStringArray()


func save() -> void:
	var file: ConfigFile = ConfigFile.new()
	for room: int in best_stars:
		file.set_value("stars", str(room), best_stars[room])
	for room: int in best_time:
		file.set_value("time", str(room), best_time[room])
	for kind: String in wear:
		file.set_value("wear", kind, wear[kind])
	for id: String in owned:
		file.set_value("owned", id, true)
	file.set_value("stats", "tips", tips)
	file.set_value("stats", "unravels", unravels)
	file.set_value("stats", "turns", turns)
	file.set_value("stats", "buttons", buttons)
	file.set_value("stats", "play_time", play_time)
	file.set_value("settings", "sound", sound)
	file.set_value("settings", "music", music)
	file.set_value("settings", "shake", shake)
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
	return room == 0 or stars(room - 1) > 0


# Where Play picks up: the first open room not yet sewn, or the first room once every room is.
func continue_room(count: int) -> int:
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


# Clears rooms, stars, stats and what is worn. Purchases stay, since Google Play still has them.
func reset() -> void:
	best_stars.clear()
	best_time.clear()
	wear = StitchfallLooks.DEFAULTS.duplicate()
	unravels = 0
	turns = 0
	buttons = 0
	play_time = 0.0
	save()
