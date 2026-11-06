class_name StitchfallProgress
extends RefCounted

# What the player has done, kept between visits: each room's best stars and best time.
# A room opens once the room before it is sewn. Tests point path at a scratch file.

static var path: String = "user://progress.cfg"

const STAR_NAMES: PackedStringArray = ["Sewn", "Unbroken", "Quick"]

var best_stars: Dictionary[int, int] = {}
var best_time: Dictionary[int, float] = {}


# One star for finishing, one for finishing without an unravel, one for beating the room's par time.
static func stars_for(time: float, unravels: int, par: float) -> int:
	return 1 + (1 if unravels == 0 else 0) + (1 if time <= par else 0)


static func star_earned(star: int, time: float, unravels: int, par: float) -> bool:
	match star:
		1:
			return unravels == 0
		2:
			return time <= par
	return true


func load_saved() -> void:
	best_stars.clear()
	best_time.clear()
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return
	for key: String in file.get_section_keys("stars") if file.has_section("stars") else PackedStringArray():
		var stars: int = file.get_value("stars", key, 0)
		best_stars[key.to_int()] = stars
	for key: String in file.get_section_keys("time") if file.has_section("time") else PackedStringArray():
		var time: float = file.get_value("time", key, 0.0)
		best_time[key.to_int()] = time


func save() -> void:
	var file: ConfigFile = ConfigFile.new()
	for room: int in best_stars:
		file.set_value("stars", str(room), best_stars[room])
	for room: int in best_time:
		file.set_value("time", str(room), best_time[room])
	file.save(path)


# Records a cleared room and says what improved, so the clear card can call out a new best.
func record(room: int, time: float, unravels: int, par: float) -> Dictionary:
	var stars: int = stars_for(time, unravels, par)
	var old_stars: int = best_stars.get(room, 0)
	var old_time: float = best_time.get(room, INF)
	best_stars[room] = maxi(old_stars, stars)
	best_time[room] = minf(old_time, time)
	save()
	return {"stars": stars, "more_stars": stars > old_stars and old_stars > 0, "faster": time < old_time and old_time < INF, "first": old_stars == 0}


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


func reset() -> void:
	best_stars.clear()
	best_time.clear()
	save()
