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

# A screen room is always seen whole, so every trap is on screen from the first frame. It is fitted to the screen
# as large as the HUD's reserve allows (fit_zoom), so a wide phone shows it larger than a 16:9 monitor does.
const SCREEN: Rect2 = Rect2(330, 250, 1260, 640)
const WALL: float = 30.0
# The inside of a screen room, between its walls.
const FLOOR_Y: float = 860.0
const CEILING_Y: float = 280.0
const LEFT_X: float = 360.0
const RIGHT_X: float = 1560.0
const INSIDE: Rect2 = Rect2(LEFT_X, CEILING_Y, RIGHT_X - LEFT_X, FLOOR_Y - CEILING_Y)
# How much of the walls stays in view around the inside when a room is fitted, in room units.
const FIT_RIM: float = 16.0
# The largest a room is ever drawn, so a tablet does not blow it up past what its art holds.
const FIT_MOST: float = 2.0
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


# A chapter's embroidered patch (assets/art/chapters/<id>.png), or null while it has none, and the pages then go
# without it.
static func chapter_badge(chapter: int) -> Texture2D:
	var path: String = "res://assets/art/chapters/%s.png" % chapter_ids[chapter]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


# A room, with its chapter's id as "art": which painting and felt it is drawn with (world_view.gd).
static func get_level(index: int) -> Dictionary:
	var room: Dictionary = chapter_script(chapter_ids[index / CHAPTER_ROOMS]).build(index % CHAPTER_ROOMS)
	room["art"] = chapter_ids[index / CHAPTER_ROOMS]
	return room


# The zoom that shows a room's inside, with FIT_RIM of its walls, as large as `view` allows once `reserve` is kept
# clear for the HUD (left, top, right and bottom, in view pixels).
static func fit_zoom(view: Vector2, reserve: Vector4) -> float:
	var room: Vector2 = INSIDE.size + Vector2.ONE * FIT_RIM * 2.0
	var free: Vector2 = view - Vector2(reserve.x + reserve.z, reserve.y + reserve.w)
	return clampf(minf(free.x / room.x, free.y / room.y), 0.1, FIT_MOST)


# Where the camera looks so the room sits in the middle of what the reserve leaves free.
static func fit_centre(zoom: float, reserve: Vector4) -> Vector2:
	return INSIDE.get_center() - Vector2(reserve.x - reserve.z, reserve.y - reserve.w) * 0.5 / zoom


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
