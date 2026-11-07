class_name StitchfallLevels
extends RefCounted

# The campaign's chapters in order, built the way LEVELS.md describes: small rooms, seen whole, one prank
# each, five rooms a chapter. Each is a script in scripts/chapters/ with its name, its line, its rooms and the
# routes that prove them.
const CHAPTER_IDS: PackedStringArray = ["linen", "pins", "unpinned", "seams", "moths", "patch", "water", "dunes", "canopy", "night", "rain", "frost"]
const CHAPTER_ROOMS: int = 5
# The chapters in play. Tools add a chapter still being built, so it can be played and proved before it
# joins the campaign.
static var chapter_ids: PackedStringArray = CHAPTER_IDS

# A screen room is seen whole at a fixed zoom, so every trap is on screen from the first frame.
const SCREEN: Rect2 = Rect2(330, 250, 1260, 640)
const SCREEN_ZOOM: float = 1.4
const WALL: float = 30.0
# The inside of a screen room, between its walls.
const FLOOR_Y: float = 860.0
const CEILING_Y: float = 280.0
const LEFT_X: float = 360.0
const RIGHT_X: float = 1560.0
# Where the runner's centre is when standing on the floor or the ceiling.
const STAND_FLOOR: float = 821.0
const STAND_CEILING: float = 319.0
# The zipper in the bottom and top right corners: it is drawn 158 tall around its point.
const ZIP_FLOOR: Vector2 = Vector2(1500, 781)
const ZIP_CEILING: Vector2 = Vector2(1500, 359)


static func count() -> int:
	return chapter_ids.size() * CHAPTER_ROOMS


static func chapter_count() -> int:
	return chapter_ids.size()


static func chapter_script(id: String) -> GDScript:
	return load("res://scripts/chapters/%s.gd" % id) as GDScript


# The room a chapter's room number lands on, adding the chapter to play if it is still being built.
static func room_of(id: String, number: int) -> int:
	if not chapter_ids.has(id):
		chapter_ids.append(id)
	return chapter_ids.find(id) * CHAPTER_ROOMS + number


static func chapter_name(chapter: int) -> String:
	return chapter_script(chapter_ids[chapter]).NAME


# The line under a chapter's name on its title card: a mood, never an instruction.
static func chapter_line(chapter: int) -> String:
	return chapter_script(chapter_ids[chapter]).LINE


static func get_level(index: int) -> Dictionary:
	return chapter_script(chapter_ids[index / CHAPTER_ROOMS]).build(index % CHAPTER_ROOMS)


static func screen_frame() -> Array[Rect2]:
	return [
		Rect2(SCREEN.position.x, SCREEN.position.y, SCREEN.size.x, WALL),
		Rect2(SCREEN.position.x, SCREEN.end.y - WALL, SCREEN.size.x, WALL),
		Rect2(SCREEN.position.x, SCREEN.position.y, WALL, SCREEN.size.y),
		Rect2(SCREEN.end.x - WALL, SCREEN.position.y, WALL, SCREEN.size.y),
	]


# A needle strip lying on a surface, its tips pointing away from it.
static func floor_needles(from_x: float, to_x: float) -> Dictionary:
	return {"rect": Rect2(from_x, FLOOR_Y - 28.0, to_x - from_x, 28.0), "dir": Vector2.UP}


static func ceiling_needles(from_x: float, to_x: float) -> Dictionary:
	return {"rect": Rect2(from_x, CEILING_Y, to_x - from_x, 28.0), "dir": Vector2.DOWN}


# An empty room with every part a room can have. A chapter's room merges its own name, par, accent and parts
# over it.
static func screen_base() -> Dictionary:
	return {
		"chamber": SCREEN,
		"backdrop": 0,
		"environment": "",
		"environment_zone": Rect2(),
		"start": Vector2(430, STAND_FLOOR),
		"exit": ZIP_FLOOR,
		"walls": screen_frame(),
		"phase_walls": [],
		"fray_ledges": [],
		"crate": Vector2.ZERO,
		"pad": Vector2.ZERO,
		"sentries": [],
		"shards": [],
		"spikes": [],
		"popups": [],
		"exit_flee": [],
		"flee_radius": 0.0,
		"flowers": [],
		"pins": [],
	}
