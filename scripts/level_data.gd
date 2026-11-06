class_name StitchfallLevels
extends RefCounted

const FRAME: Array[Rect2] = [
	Rect2(110, 168, 1700, 30),
	Rect2(110, 898, 1700, 30),
	Rect2(110, 168, 30, 760),
	Rect2(1780, 168, 30, 760),
]


# The chapters that open the campaign, built the way LEVELS.md describes: small rooms, seen whole, one prank
# each. Each chapter is one room played five times. The older wide rooms follow them, five to a page, until
# each is rebuilt.
const CHAPTERS: Array[String] = ["Plain Linen", "Loose Pins", "Unpinned"]
const CHAPTER_ROOMS: int = 5
const SCREEN_ROOMS: int = 15
const CLASSIC_ROOMS: int = 50
const CLASSIC_NAME: String = "Old Seams"
# Each screen room's par in seconds: the time of its proved route in tests/run_tests.gd times 1.5, rounded up.
const SCREEN_PARS: Array[float] = [5.0, 7.0, 8.0, 8.0, 10.0, 5.0, 8.0, 8.0, 12.0, 8.0, 5.0, 5.0, 5.0, 13.0, 10.0]

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
	return SCREEN_ROOMS + CLASSIC_ROOMS


static func chapter_count() -> int:
	return ceili(float(count()) / float(CHAPTER_ROOMS))


static func chapter_name(chapter: int) -> String:
	if chapter < CHAPTERS.size():
		return CHAPTERS[chapter]
	return "%s %d" % [CLASSIC_NAME, chapter - CHAPTERS.size() + 1]


static func get_level(index: int) -> Dictionary:
	var room: Dictionary
	match index / CHAPTER_ROOMS if index < SCREEN_ROOMS else -1:
		0:
			room = _linen(index)
		1:
			room = _pins(index - CHAPTER_ROOMS)
		2:
			room = _unpinned(index - CHAPTER_ROOMS * 2)
		_:
			room = _classic(index - SCREEN_ROOMS)
	if index < SCREEN_ROOMS:
		room["par"] = SCREEN_PARS[index]
	# The older rooms name one floor checkpoint. Every room now reads a list of flowers.
	if room["flowers"].is_empty() and room["checkpoint"] != Vector2.ZERO:
		room["flowers"] = [{"pos": room["checkpoint"], "gravity": Vector2.DOWN}]
	return room


# The time that earns a room's Quick star. A screen room states its own, measured from its route.
static func par(room: Dictionary) -> float:
	var stated: float = room["par"]
	if stated > 0.0:
		return stated
	return 25.0 + float(room["width"]) / 80.0


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


static func _screen_base() -> Dictionary:
	var base: Dictionary = _classic(-1)
	base.merge({
		"screen": true,
		"chamber": SCREEN,
		"backdrop": 0,
		"start": Vector2(430, STAND_FLOOR),
		"exit": ZIP_FLOOR,
		"walls": screen_frame(),
		"hint": "",
	}, true)
	return base


# Chapter one, Plain Linen: one room, five pranks. Each room's buttons sit on the route its prank asks for, so
# where the buttons are is the clue. The jump strip in the middle never changes.
static func _linen(index: int) -> Dictionary:
	var room: Dictionary = _screen_base()
	var strip: Dictionary = floor_needles(900, 1020)
	match index:
		0:
			room.merge({
				"name": "A Gentle Start",
				"accent": Color("18c9df"),
				"spikes": [strip],
				"shards": [Vector2(680, STAND_FLOOR), Vector2(960, 745)],
			}, true)
		1:
			# The landing pops up its needles as you jump, so the only way over is the ceiling.
			room.merge({
				"name": "Same Room",
				"accent": Color("f46b42"),
				"spikes": [strip],
				"popups": [{"rect": Rect2(1020, FLOOR_Y - 28.0, 300, 28.0), "dir": Vector2.UP, "trigger": Rect2(760, 640, 260, 220), "delay": 0.12}],
				"shards": [Vector2(680, STAND_FLOOR), Vector2(960, STAND_CEILING + 6.0)],
			}, true)
		2:
			# The zipper is sewn on a track up the right wall, and runs up it once it opens.
			room.merge({
				"name": "Almost There",
				"accent": Color("e9ab34"),
				"spikes": [strip],
				"exit_flee": [ZIP_CEILING],
				"flee_radius": 230.0,
				"shards": [Vector2(680, STAND_FLOOR), Vector2(960, 745)],
			}, true)
		3:
			# Both the floor and the ceiling are needled across the middle. Falling sideways is the way over.
			room.merge({
				"name": "Nothing New",
				"accent": Color("8e7ae8"),
				"spikes": [strip, floor_needles(1020, 1320), ceiling_needles(700, 1320)],
				"shards": [Vector2(680, STAND_FLOOR), Vector2(960, 510)],
			}, true)
		4:
			room.merge({
				"name": "One More Time",
				"accent": Color("b45d4c"),
				"spikes": [strip, ceiling_needles(700, 1320)],
				"popups": [{"rect": Rect2(1020, FLOOR_Y - 28.0, 300, 28.0), "dir": Vector2.UP, "trigger": Rect2(760, 640, 260, 220), "delay": 0.12}],
				"exit": ZIP_CEILING,
				"exit_flee": [ZIP_FLOOR],
				"flee_radius": 200.0,
				"shards": [Vector2(680, STAND_FLOOR), Vector2(960, 510), Vector2(1521, 640)],
			}, true)
	return room


# Where a pincushion rests on the floor or the ceiling, its centre one body radius off the surface.
const PIN_FLOOR: float = FLOOR_Y - 30.0
const PIN_CEILING: float = CEILING_Y + 30.0
# Patches and steps over the needle pit sit low enough to jump onto from the floor.
const PATCH_Y: float = 780.0


# Chapter two, Loose Pins: pincushions fall every time you turn, exactly as fast as you do.
static func _pins(index: int) -> Dictionary:
	var room: Dictionary = _screen_base()
	room.merge({"backdrop": 1}, true)
	match index:
		0:
			room.merge({
				"name": "Mind the Pins",
				"accent": Color("d0563f"),
				"pins": [Vector2(1000, PIN_FLOOR)],
				"shards": [Vector2(680, STAND_FLOOR), Vector2(1000, 690)],
			}, true)
		1:
			room.merge({
				"name": "Heads Up",
				"accent": Color("e07a3a"),
				"pins": [Vector2(1000, PIN_FLOOR)],
				"shards": [Vector2(680, STAND_FLOOR), Vector2(1250, STAND_CEILING + 6.0)],
			}, true)
		2:
			room.merge({
				"name": "Clean Sweep",
				"accent": Color("c9a23a"),
				"pins": [Vector2(1530, PIN_FLOOR)],
				"exit": ZIP_CEILING,
				"shards": [Vector2(400, 560), Vector2(1000, STAND_CEILING + 6.0)],
			}, true)
		3:
			room.merge({
				"name": "Company",
				"accent": Color("7a8ee8"),
				"pins": [Vector2(900, PIN_FLOOR), Vector2(1300, PIN_FLOOR)],
				"exit": Vector2(960, ZIP_FLOOR.y),
				"flowers": [{"pos": Vector2(780, STAND_CEILING - 10.0), "gravity": Vector2.UP}],
				"shards": [Vector2(400, 560), Vector2(1000, STAND_CEILING + 6.0), Vector2(1521, 650)],
			}, true)
		4:
			room.merge({
				# Two pins wait on shelves over a needled floor, and any turn drops them. The way down ends in a
				# race: into the zipper before they land on it.
				"name": "Pin Drop",
				"accent": Color("b2524a"),
				"walls": screen_frame() + [Rect2(760, 600, 120, 24), Rect2(1060, 600, 120, 24)],
				"spikes": [floor_needles(700, 1320)],
				"exit": Vector2(1390, ZIP_FLOOR.y),
				"pins": [Vector2(820, 570), Vector2(1120, 570)],
				"flowers": [{"pos": Vector2(560, STAND_CEILING - 10.0), "gravity": Vector2.UP}],
				"shards": [Vector2(620, STAND_FLOOR), Vector2(970, STAND_CEILING + 6.0)],
			}, true)
	return room


# Chapter three, Unpinned: patches that look sewn down are only pinned, and drop a moment after you stand on them.
static func _unpinned(index: int) -> Dictionary:
	var room: Dictionary = _screen_base()
	room.merge({"backdrop": 2}, true)
	var pit: Dictionary = floor_needles(640, 1260)
	match index:
		0:
			room.merge({
				"name": "Tacked On",
				"accent": Color("5f9b74"),
				"spikes": [pit],
				"fray_ledges": [{"rect": Rect2(780, PATCH_Y, 320, 28), "delay": 0.9}],
				"shards": [Vector2(560, STAND_FLOOR), Vector2(940, 700)],
			}, true)
		1:
			# A row of short patches, each holding only a moment: at a run each one lasts until the next takes
			# your weight, and stopping anywhere drops you in.
			room.merge({
				"name": "Keep Moving",
				"accent": Color("4f8f8a"),
				"spikes": [pit],
				"fray_ledges": [
					{"rect": Rect2(700, PATCH_Y, 140, 28), "delay": 0.45},
					{"rect": Rect2(840, PATCH_Y, 140, 28), "delay": 0.45},
					{"rect": Rect2(980, PATCH_Y, 140, 28), "delay": 0.45},
					{"rect": Rect2(1120, PATCH_Y, 140, 28), "delay": 0.45},
				],
				"shards": [Vector2(560, STAND_FLOOR), Vector2(1005, 640)],
			}, true)
		2:
			# Two steps are sewn on. The last only looks it, and goes the moment it is touched.
			room.merge({
				"name": "Last Step",
				"accent": Color("8aa04a"),
				"spikes": [pit],
				"walls": screen_frame() + [Rect2(700, PATCH_Y, 140, 28), Rect2(910, PATCH_Y, 140, 28)],
				"fray_ledges": [{"rect": Rect2(1120, PATCH_Y, 140, 28), "delay": 0.05}],
				"shards": [Vector2(560, STAND_FLOOR), Vector2(980, 700)],
			}, true)
		3:
			# The only bridge drops once it is crossed, and the zipper is back where you started.
			room.merge({
				"name": "No Way Back",
				"accent": Color("6a7fb0"),
				"spikes": [pit],
				"start": Vector2(470, STAND_FLOOR),
				"exit": Vector2(420, ZIP_FLOOR.y),
				"fray_ledges": [{"rect": Rect2(780, PATCH_Y, 320, 28), "delay": 0.9}],
				"shards": [Vector2(1430, STAND_FLOOR)],
			}, true)
		4:
			# A flower on a sewn island in the middle, a button above it between two needle strips, and a far
			# patch that drops the moment it is touched.
			room.merge({
				"name": "Hold On",
				"accent": Color("a8604a"),
				"spikes": [pit, ceiling_needles(680, 860), ceiling_needles(1100, 1320)],
				"walls": screen_frame() + [Rect2(900, 740, 160, 28)],
				"fray_ledges": [
					{"rect": Rect2(720, PATCH_Y, 140, 28), "delay": 0.35},
					{"rect": Rect2(1100, PATCH_Y, 160, 28), "delay": 0.05},
				],
				"flowers": [{"pos": Vector2(950, 686), "gravity": Vector2.DOWN}],
				"shards": [Vector2(560, STAND_FLOOR), Vector2(940, STAND_CEILING + 6.0)],
			}, true)
	return room


static func wide_frame(width: float) -> Array[Rect2]:
	return [
		Rect2(110, 168, width - 220, 30),
		Rect2(110, 898, width - 220, 30),
		Rect2(110, 168, 30, 760),
		Rect2(width - 140, 168, 30, 760),
	]


static func _classic(index: int) -> Dictionary:
	var base: Dictionary = {
		"width": 1920.0,
		"backdrop": mini(index, 3),
		"environment": "",
		"environment_zone": Rect2(),
		"start": Vector2(270, 822),
		"exit": Vector2(1705, 815),
		"walls": FRAME.duplicate(),
		"phase_walls": [],
		"timed_gates": [],
		"gate_window": 2.2,
		"bloom_pads": [],
		"ferries": [],
		"fray_ledges": [],
		"mechanisms": [],
		"hazards": [],
		"crate": Vector2.ZERO,
		"pad": Vector2.ZERO,
		"checkpoint": Vector2.ZERO,
		"sentries": [],
		"shards": [],
		"shard_phases": [],
		"screen": false,
		"chamber": Rect2(110, 168, 1700, 760),
		"spikes": [],
		"popups": [],
		"exit_flee": [],
		"flee_radius": 0.0,
		"flowers": [],
		"pins": [],
		"par": 0.0,
	}
	match index:
		0:
			base.merge({
				"name": "The First Stitch",
				"hint": "The high hem blocks the floor. Shift twice and run along the ceiling.",
				"accent": Color("18c9df"),
				"walls": FRAME + [Rect2(770, 600, 42, 298), Rect2(1170, 675, 42, 223)],
				"checkpoint": Vector2(1050, 260),
				"shards": [Vector2(445, 820), Vector2(965, 270), Vector2(1500, 750)],
			}, true)
		1:
			base.merge({
				"name": "Reverse Hem",
				"hint": "Turn the room over. The zipper waits at the far end of the ceiling.",
				"accent": Color("f46b42"),
				"start": Vector2(1630, 820),
				"exit": Vector2(310, 278),
				"walls": FRAME + [Rect2(1110, 540, 44, 358), Rect2(680, 635, 40, 263)],
				"checkpoint": Vector2(1030, 265),
				"shards": [Vector2(1490, 755), Vector2(930, 280), Vector2(490, 275)],
			}, true)
		2:
			base.merge({
				"name": "Loose Bridge",
				"hint": "The mint button needs a lit seam. Shift toward the wall and climb.",
				"accent": Color("e9ab34"),
				"walls": FRAME + [Rect2(780, 535, 40, 363), Rect2(1400, 665, 42, 233)],
				"phase_walls": [Rect2(1180, 360, 38, 420)],
				"checkpoint": Vector2(930, 275),
				"shards": [Vector2(460, 775), Vector2(1125, 485), Vector2(1570, 760)],
				"shard_phases": [-1, 1, -1],
			}, true)
		3:
			base.merge({
				"name": "Needle Clock",
				"hint": "Shift wakes the cutter. Ride the hem under its pass.",
				"accent": Color("8e7ae8"),
				"width": 2600.0,
				"start": Vector2(310, 822),
				"exit": Vector2(2430, 815),
				"walls": wide_frame(2600) + [Rect2(1150, 525, 280, 30), Rect2(2020, 510, 270, 28)],
				"timed_gates": [Rect2(740, 198, 36, 700), Rect2(2250, 198, 36, 700)],
				"gate_window": 3.0,
				"phase_walls": [Rect2(845, 515, 220, 28)],
				"hazards": [Rect2(915, 870, 150, 28), Rect2(1760, 870, 170, 28)],
				"checkpoint": Vector2(1530, 810),
				"sentries": [{"from": Vector2(1150, 715), "to": Vector2(1290, 715), "period": 3.2, "offset": 0.4}],
				"ferries": [{"from": Vector2(1630, 735), "to": Vector2(1990, 560), "size": Vector2(210, 28), "period": 4.8}],
				"mechanisms": [{"kind": "cutter", "from": Vector2(1560, 580), "to": Vector2(1980, 580), "period": 3.6, "shift_armed": true}],
				"shards": [Vector2(475, 770), Vector2(1990, 485), Vector2(2350, 755)],
			}, true)
		4:
			base.merge({
				"name": "The Weighted Patch",
				"hint": "Push the patch into the corner, then turn the pull upward.",
				"crate": Vector2(470, 835),
				"pad": Vector2(1025, 225),
				"walls": FRAME + [Rect2(1060, 560, 44, 338), Rect2(1380, 640, 38, 258)],
				"checkpoint": Vector2(970, 805),
				"shards": [Vector2(380, 755), Vector2(930, 285), Vector2(1530, 750)],
			}, true)
		5:
			base.merge({
				"name": "Blue Thread",
				"hint": "The flooded cloth slows your fall. Turn upward inside the pool.",
				"backdrop": 4,
				"environment": "water",
				"environment_zone": Rect2(570, 540, 770, 358),
				"exit": Vector2(1640, 295),
				"walls": FRAME + [Rect2(710, 555, 40, 343), Rect2(1305, 450, 34, 448)],
				"checkpoint": Vector2(1020, 790),
				"shards": [Vector2(425, 760), Vector2(925, 700), Vector2(1450, 295)],
			}, true)
		6:
			base.merge({
				"name": "Sand Drift",
				"hint": "Catch the moving hem while the hanging weight rises.",
				"backdrop": 5,
				"width": 2500.0,
				"environment": "dunes",
				"environment_zone": Rect2(540, 280, 1560, 618),
				"exit": Vector2(2310, 815),
				"walls": wide_frame(2500) + [Rect2(605, 700, 38, 198), Rect2(1140, 560, 44, 338), Rect2(2030, 550, 230, 28)],
				"hazards": [Rect2(1590, 870, 325, 28)],
				"ferries": [{"from": Vector2(1490, 720), "to": Vector2(1870, 560), "size": Vector2(205, 28), "period": 4.2}],
				"mechanisms": [{"kind": "pulley", "from": Vector2(1770, 280), "to": Vector2(1770, 720), "anchor": Vector2(1770, 210), "period": 4.1}],
				"checkpoint": Vector2(1270, 815),
				"shards": [Vector2(400, 755), Vector2(890, 525), Vector2(1840, 490)],
			}, true)
		7:
			base.merge({
				"name": "Against the Grain",
				"hint": "Travel left into the wind. A lit seam wakes the mint button.",
				"backdrop": 5,
				"environment": "dunes",
				"environment_zone": Rect2(510, 260, 1010, 638),
				"start": Vector2(1620, 820),
				"exit": Vector2(300, 815),
				"walls": FRAME + [Rect2(1180, 645, 38, 253), Rect2(710, 590, 38, 308)],
				"phase_walls": [Rect2(915, 410, 280, 28)],
				"checkpoint": Vector2(1060, 265),
				"shards": [Vector2(1500, 755), Vector2(1015, 280), Vector2(480, 745)],
				"shard_phases": [-1, 1, -1],
			}, true)
		8:
			base.merge({
				"name": "Green Canopy",
				"hint": "The copper spring skips the lower canopy.",
				"backdrop": 6,
				"width": 2850.0,
				"environment": "forest",
				"environment_zone": Rect2(450, 340, 1120, 558),
				"bloom_pads": [Vector2(390, 870), Vector2(1780, 870)],
				"exit": Vector2(2650, 290),
				"walls": wide_frame(2850) + [Rect2(760, 620, 315, 30), Rect2(1320, 420, 285, 30), Rect2(2350, 390, 310, 30)],
				"hazards": [Rect2(2040, 870, 190, 28)],
				"ferries": [{"from": Vector2(1860, 660), "to": Vector2(2240, 440), "size": Vector2(220, 28), "period": 5.0}],
				"mechanisms": [{"kind": "spring", "from": Vector2(1130, 850)}],
				"checkpoint": Vector2(1510, 510),
				"shards": [Vector2(385, 755), Vector2(1450, 340), Vector2(2470, 315)],
			}, true)
		9:
			base.merge({
				"name": "Rootwork",
				"hint": "Seat the patch, then catch the bloom on the return.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(700, 340, 470, 558),
				"bloom_pads": [Vector2(610, 870)],
				"start": Vector2(1650, 820),
				"exit": Vector2(310, 285),
				"crate": Vector2(1510, 835),
				"pad": Vector2(1300, 876),
				"walls": FRAME + [Rect2(1220, 680, 42, 218), Rect2(600, 420, 310, 30)],
				"checkpoint": Vector2(1080, 510),
				"shards": [Vector2(1530, 755), Vector2(970, 470), Vector2(470, 290)],
			}, true)
		10:
			base.merge({
				"name": "Night Quilt",
				"hint": "Catch the bloom on the first ledge to reach the stars.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"bloom_pads": [Vector2(735, 645)],
				"exit": Vector2(1650, 285),
				"walls": FRAME + [Rect2(520, 670, 290, 28), Rect2(925, 515, 280, 28), Rect2(1335, 365, 285, 28)],
				"checkpoint": Vector2(1030, 440),
				"shards": [Vector2(420, 765), Vector2(1045, 445), Vector2(1480, 290)],
			}, true)
		11:
			base.merge({
				"name": "Moon Hem",
				"hint": "Descend through the quilt. Light the seam at the middle ledge.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"start": Vector2(1650, 268),
				"exit": Vector2(310, 815),
				"walls": FRAME + [Rect2(1260, 390, 290, 28), Rect2(815, 540, 270, 28), Rect2(420, 680, 260, 28)],
				"phase_walls": [Rect2(1040, 365, 35, 300)],
				"hazards": [Rect2(700, 870, 175, 28)],
				"checkpoint": Vector2(885, 480),
				"shards": [Vector2(1490, 270), Vector2(1010, 465), Vector2(510, 745)],
				"shard_phases": [-1, 1, -1],
			}, true)
		12:
			base.merge({
				"name": "Rainline",
				"hint": "Shift starts the chain. Cross before the hanging weight falls.",
				"backdrop": 8,
				"width": 2800.0,
				"environment": "rain",
				"environment_zone": Rect2(430, 230, 2060, 668),
				"exit": Vector2(2600, 815),
				"walls": wide_frame(2800) + [Rect2(735, 640, 470, 28), Rect2(1240, 545, 245, 28), Rect2(2140, 500, 270, 28)],
				"timed_gates": [Rect2(1510, 198, 36, 700), Rect2(2420, 198, 36, 700)],
				"hazards": [Rect2(770, 870, 370, 28), Rect2(1850, 870, 220, 28)],
				"ferries": [{"from": Vector2(1700, 735), "to": Vector2(2150, 545), "size": Vector2(215, 28), "period": 5.2}],
				"mechanisms": [
					{"kind": "chain", "from": Vector2(1690, 600), "to": Vector2(2020, 600), "period": 4.6, "shift_armed": true},
					{"kind": "pulley", "from": Vector2(2290, 280), "to": Vector2(2290, 690), "anchor": Vector2(2290, 210), "period": 3.9},
				],
				"checkpoint": Vector2(1100, 565),
				"shards": [Vector2(410, 750), Vector2(965, 570), Vector2(2530, 755)],
			}, true)
		13:
			base.merge({
				"name": "Storm Stitch",
				"hint": "Travel against the storm. The mint button wakes on a wall turn.",
				"backdrop": 8,
				"environment": "rain",
				"environment_zone": Rect2(470, 215, 1130, 683),
				"start": Vector2(1630, 820),
				"exit": Vector2(315, 285),
				"walls": FRAME + [Rect2(1250, 595, 40, 303), Rect2(630, 540, 40, 358)],
				"phase_walls": [Rect2(975, 350, 36, 390)],
				"hazards": [Rect2(760, 870, 120, 28)],
				"checkpoint": Vector2(1090, 275),
				"sentries": [{"from": Vector2(710, 370), "to": Vector2(900, 370), "period": 3.2, "offset": 0.6}],
				"shards": [Vector2(1500, 755), Vector2(1030, 470), Vector2(470, 285)],
				"shard_phases": [-1, 1, -1],
			}, true)
		14:
			base.merge({
				"name": "Frostline",
				"hint": "Brake before the cutter reaches the safe strip.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"walls": FRAME + [Rect2(970, 580, 290, 28)],
				"hazards": [Rect2(710, 870, 220, 28), Rect2(1270, 870, 220, 28)],
				"checkpoint": Vector2(1090, 815),
				"mechanisms": [{"kind": "cutter", "from": Vector2(1050, 710), "to": Vector2(1400, 710), "period": 3.3}],
				"shards": [Vector2(430, 755), Vector2(1085, 755), Vector2(1630, 755)],
			}, true)
		15:
			base.merge({
				"name": "Cold Seam",
				"hint": "Bounce through the last seam before the chain wakes.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"start": Vector2(1640, 820),
				"exit": Vector2(300, 285),
				"walls": FRAME + [Rect2(1230, 570, 40, 328), Rect2(710, 630, 40, 268)],
				"phase_walls": [Rect2(950, 340, 40, 410)],
				"timed_gates": [Rect2(650, 198, 36, 700)],
				"gate_window": 1.7,
				"bloom_pads": [Vector2(1410, 870)],
				"hazards": [Rect2(1050, 870, 125, 28), Rect2(470, 870, 125, 28)],
				"checkpoint": Vector2(1040, 275),
				"sentries": [
					{"from": Vector2(780, 390), "to": Vector2(920, 390), "period": 3.4, "offset": 0.4},
					{"from": Vector2(1320, 680), "to": Vector2(1490, 680), "period": 2.9, "offset": 1.2},
				],
				"mechanisms": [
					{"kind": "spring", "from": Vector2(875, 850)},
					{"kind": "chain", "from": Vector2(790, 525), "to": Vector2(1110, 525), "period": 3.5, "shift_armed": true},
				],
				"shards": [Vector2(1510, 755), Vector2(1010, 475), Vector2(440, 285)],
				"shard_phases": [-1, 1, -1],
			}, true)
		16:
			base.merge({
				"name": "Threadfall",
				"hint": "Start at the high hem. Drop past the shelves, then turn the last fall.",
				"backdrop": 3,
				"start": Vector2(290, 275),
				"exit": Vector2(1610, 815),
				"walls": FRAME + [Rect2(280, 380, 300, 28), Rect2(810, 555, 305, 28), Rect2(1360, 705, 260, 28)],
				"checkpoint": Vector2(1010, 480),
				"shards": [Vector2(480, 300), Vector2(980, 485), Vector2(1480, 635)],
			}, true)
		17:
			base.merge({
				"name": "Backstitch",
				"hint": "The wall hides the button. Run past it on the ceiling, then come back.",
				"backdrop": 2,
				"start": Vector2(1595, 820),
				"exit": Vector2(1510, 285),
				"walls": FRAME + [Rect2(1180, 495, 42, 403), Rect2(670, 630, 42, 268), Rect2(850, 455, 235, 28)],
				"phase_walls": [Rect2(800, 305, 230, 28)],
				"checkpoint": Vector2(520, 285),
				"shards": [Vector2(1430, 755), Vector2(530, 750), Vector2(970, 275)],
			}, true)
		18:
			base.merge({
				"name": "Pond Stitch",
				"hint": "Sink for the low button. Turn the pull before you leave the water.",
				"backdrop": 4,
				"environment": "water",
				"environment_zone": Rect2(520, 500, 820, 398),
				"start": Vector2(310, 275),
				"exit": Vector2(1600, 815),
				"walls": FRAME + [Rect2(540, 420, 340, 28), Rect2(1240, 390, 42, 508)],
				"checkpoint": Vector2(1000, 765),
				"shards": [Vector2(460, 365), Vector2(930, 770), Vector2(1450, 280)],
			}, true)
		19:
			base.merge({
				"name": "Countercurrent",
				"hint": "Cross the pool against the pull. Catch the hem as it rises.",
				"backdrop": 4,
				"width": 2350.0,
				"environment": "water",
				"environment_zone": Rect2(625, 300, 1110, 598),
				"start": Vector2(2140, 820),
				"exit": Vector2(285, 285),
				"walls": wide_frame(2350) + [Rect2(1730, 570, 42, 328), Rect2(670, 480, 42, 418)],
				"ferries": [{"from": Vector2(1350, 730), "to": Vector2(1010, 390), "size": Vector2(210, 28), "period": 5.1}],
				"checkpoint": Vector2(1050, 825),
				"shards": [Vector2(1980, 750), Vector2(1250, 590), Vector2(440, 360)],
			}, true)
		20:
			base.merge({
				"name": "Kite Thread",
				"hint": "Let the warm gust carry you, then turn onto the upper ledge.",
				"backdrop": 5,
				"width": 2450.0,
				"environment": "dunes",
				"environment_zone": Rect2(425, 250, 1530, 648),
				"exit": Vector2(2220, 280),
				"walls": wide_frame(2450) + [Rect2(560, 700, 240, 28), Rect2(1130, 535, 300, 28), Rect2(1830, 385, 280, 28)],
				"bloom_pads": [Vector2(680, 870)],
				"checkpoint": Vector2(1350, 460),
				"shards": [Vector2(450, 750), Vector2(1230, 455), Vector2(2010, 310)],
			}, true)
		21:
			base.merge({
				"name": "Still Sand",
				"hint": "Move left against the gust. Shift to stop the cutter at the narrow hem.",
				"backdrop": 5,
				"environment": "dunes",
				"environment_zone": Rect2(430, 240, 1160, 658),
				"start": Vector2(1590, 265),
				"exit": Vector2(295, 815),
				"walls": FRAME + [Rect2(1220, 380, 290, 28), Rect2(730, 555, 305, 28)],
				"mechanisms": [{"kind": "cutter", "from": Vector2(690, 765), "to": Vector2(1050, 765), "period": 3.8, "shift_armed": true}],
				"checkpoint": Vector2(940, 480),
				"shards": [Vector2(1470, 275), Vector2(960, 485), Vector2(440, 755)],
			}, true)
		22:
			base.merge({
				"name": "Bloom Ladder",
				"hint": "Each flower lifts you one shelf. Turn at the top to reach the zipper.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(490, 290, 970, 608),
				"start": Vector2(940, 820),
				"exit": Vector2(300, 275),
				"walls": FRAME + [Rect2(520, 700, 280, 28), Rect2(1040, 525, 280, 28), Rect2(480, 355, 300, 28)],
				"bloom_pads": [Vector2(920, 870), Vector2(1160, 500)],
				"checkpoint": Vector2(1190, 460),
				"shards": [Vector2(1080, 765), Vector2(620, 625), Vector2(600, 280)],
			}, true)
		23:
			base.merge({
				"name": "Root Pocket",
				"hint": "The mint button hides below the root. Light the seam, then climb out.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(490, 290, 1000, 608),
				"start": Vector2(1590, 820),
				"exit": Vector2(335, 285),
				"walls": FRAME + [Rect2(1280, 585, 42, 313), Rect2(460, 500, 360, 28)],
				"phase_walls": [Rect2(900, 675, 350, 28)],
				"bloom_pads": [Vector2(650, 870)],
				"checkpoint": Vector2(1050, 775),
				"shards": [Vector2(1480, 755), Vector2(1040, 760), Vector2(565, 425)],
				"shard_phases": [-1, 1, -1],
			}, true)
		24:
			base.merge({
				"name": "Rain Reversal",
				"hint": "Cross the high seam before it closes. The storm pushes you back.",
				"backdrop": 8,
				"width": 2300.0,
				"environment": "rain",
				"environment_zone": Rect2(340, 210, 1650, 688),
				"start": Vector2(290, 275),
				"exit": Vector2(2060, 815),
				"walls": wide_frame(2300) + [Rect2(450, 400, 310, 28), Rect2(1250, 600, 290, 28)],
				"timed_gates": [Rect2(980, 198, 36, 700)],
				"gate_window": 2.5,
				"ferries": [{"from": Vector2(1580, 735), "to": Vector2(1830, 470), "size": Vector2(200, 28), "period": 4.7}],
				"checkpoint": Vector2(1380, 525),
				"shards": [Vector2(560, 325), Vector2(1130, 285), Vector2(1880, 745)],
			}, true)
		25:
			base.merge({
				"name": "Frost Brake",
				"hint": "Gather speed, then brake on the tiny dry patch before shifting up.",
				"backdrop": 9,
				"environment": "frost",
				"environment_zone": Rect2(600, 540, 1000, 358),
				"start": Vector2(1590, 820),
				"exit": Vector2(285, 280),
				"walls": FRAME + [Rect2(620, 545, 320, 28), Rect2(1100, 640, 235, 28)],
				"hazards": [Rect2(745, 870, 260, 28), Rect2(1170, 870, 170, 28)],
				"mechanisms": [{"kind": "cutter", "from": Vector2(970, 710), "to": Vector2(1250, 710), "period": 3.1}],
				"checkpoint": Vector2(1060, 470),
				"shards": [Vector2(1510, 750), Vector2(1090, 590), Vector2(480, 285)],
			}, true)
		26:
			base.merge({
				"name": "The Falling Bobbin",
				"hint": "The stitched circle winds a weight. Step in, then turn onto the upper path.",
				"backdrop": 2,
				"width": 2400.0,
				"exit": Vector2(2180, 815),
				"walls": wide_frame(2400) + [Rect2(1000, 620, 42, 278), Rect2(1460, 405, 310, 28)],
				"mechanisms": [{"kind": "pulley", "from": Vector2(1140, 275), "to": Vector2(1140, 770), "anchor": Vector2(1140, 210), "period": 3.2, "trigger": Vector2(780, 820), "trigger_radius": 115.0}],
				"checkpoint": Vector2(1460, 805),
				"shards": [Vector2(530, 755), Vector2(1250, 290), Vector2(1920, 755)],
			}, true)
		27:
			base.merge({
				"name": "Pull the Thread",
				"hint": "Wake the weight from above. Its sweep leaves a way through below.",
				"backdrop": 3,
				"start": Vector2(1600, 275),
				"exit": Vector2(300, 815),
				"walls": FRAME + [Rect2(1130, 400, 285, 28), Rect2(650, 600, 330, 28)],
				"mechanisms": [{"kind": "pulley", "from": Vector2(1060, 290), "to": Vector2(1060, 700), "anchor": Vector2(1060, 210), "period": 3.6, "trigger": Vector2(1410, 285), "trigger_radius": 95.0}],
				"checkpoint": Vector2(710, 525),
				"shards": [Vector2(1470, 285), Vector2(950, 490), Vector2(440, 750)],
			}, true)
		28:
			base.merge({
				"name": "Seam Countdown",
				"hint": "A turn unzips the first hem. Cross the lower slit before it closes.",
				"backdrop": 3,
				"width": 2550.0,
				"exit": Vector2(2300, 285),
				"walls": wide_frame(2550) + [Rect2(630, 600, 290, 28), Rect2(1650, 420, 300, 28)],
				"timed_gates": [Rect2(1020, 198, 36, 700), Rect2(1990, 198, 36, 700)],
				"gate_window": 2.7,
				"phase_walls": [Rect2(1260, 660, 275, 28)],
				"checkpoint": Vector2(1500, 805),
				"shards": [Vector2(510, 755), Vector2(1390, 590), Vector2(2200, 285)],
				"shard_phases": [-1, 1, -1],
			}, true)
		29:
			base.merge({
				"name": "Button Counterweight",
				"hint": "Seat the loose patch on the button. Then use the ceiling to cross.",
				"backdrop": 2,
				"start": Vector2(1550, 820),
				"exit": Vector2(290, 275),
				"walls": FRAME + [Rect2(1190, 540, 44, 358), Rect2(690, 580, 42, 318)],
				"crate": Vector2(1450, 835),
				"pad": Vector2(1320, 876),
				"checkpoint": Vector2(900, 275),
				"shards": [Vector2(1510, 755), Vector2(1050, 285), Vector2(470, 285)],
			}, true)
		30:
			base.merge({
				"name": "Slow Orbit",
				"hint": "In the night quilt, each turn hangs longer. Drift toward the next shelf.",
				"backdrop": 7,
				"width": 2650.0,
				"environment": "space",
				"environment_zone": Rect2(450, 220, 1750, 650),
				"start": Vector2(290, 275),
				"exit": Vector2(2390, 815),
				"walls": wide_frame(2650) + [Rect2(590, 390, 300, 28), Rect2(1130, 560, 310, 28), Rect2(1840, 705, 285, 28)],
				"checkpoint": Vector2(1280, 480),
				"shards": [Vector2(580, 305), Vector2(1260, 490), Vector2(2040, 630)],
			}, true)
		31:
			base.merge({
				"name": "Ice Weight",
				"hint": "The icy run is fast. Step on the mark and brake before the weight.",
				"backdrop": 9,
				"width": 2550.0,
				"environment": "frost",
				"environment_zone": Rect2(420, 560, 1750, 338),
				"exit": Vector2(2320, 815),
				"walls": wide_frame(2550) + [Rect2(1350, 520, 260, 28)],
				"hazards": [Rect2(1010, 870, 180, 28)],
				"mechanisms": [{"kind": "pulley", "from": Vector2(1250, 280), "to": Vector2(1250, 760), "anchor": Vector2(1250, 210), "period": 3.5, "trigger": Vector2(800, 820), "trigger_radius": 100.0}],
				"checkpoint": Vector2(1670, 810),
				"shards": [Vector2(460, 750), Vector2(1480, 445), Vector2(2150, 755)],
			}, true)
		32:
			base.merge({
				"name": "Canopy Relay",
				"hint": "Ride the moving hem, land on the flower, and spring to the zipper.",
				"backdrop": 6,
				"width": 2750.0,
				"environment": "forest",
				"environment_zone": Rect2(480, 280, 1800, 618),
				"exit": Vector2(2520, 285),
				"walls": wide_frame(2750) + [Rect2(600, 650, 250, 28), Rect2(1370, 485, 280, 28), Rect2(2250, 385, 280, 28)],
				"ferries": [{"from": Vector2(950, 710), "to": Vector2(1310, 560), "size": Vector2(210, 28), "period": 4.5}],
				"bloom_pads": [Vector2(1660, 870)],
				"checkpoint": Vector2(1450, 410),
				"shards": [Vector2(480, 755), Vector2(1250, 485), Vector2(2360, 315)],
			}, true)
		33:
			base.merge({
				"name": "The Storm Shuttle",
				"hint": "The rain pushes you toward the chain. Wait, turn, then ride the hem home.",
				"backdrop": 8,
				"width": 2700.0,
				"environment": "rain",
				"environment_zone": Rect2(380, 220, 1900, 678),
				"start": Vector2(2480, 820),
				"exit": Vector2(310, 285),
				"walls": wide_frame(2700) + [Rect2(2080, 600, 300, 28), Rect2(1050, 465, 280, 28)],
				"ferries": [{"from": Vector2(1760, 690), "to": Vector2(1370, 510), "size": Vector2(210, 28), "period": 4.7}],
				"mechanisms": [{"kind": "chain", "from": Vector2(1530, 580), "to": Vector2(1850, 580), "period": 3.6, "shift_armed": true}],
				"checkpoint": Vector2(1180, 390),
				"shards": [Vector2(2240, 760), Vector2(1510, 440), Vector2(500, 285)],
			}, true)
		34:
			base.merge({
				"name": "Drowned Stair",
				"hint": "Drop through the pool, light the lower seam, then climb the opposite bank.",
				"backdrop": 4,
				"width": 2450.0,
				"environment": "water",
				"environment_zone": Rect2(500, 430, 1450, 468),
				"start": Vector2(300, 275),
				"exit": Vector2(2220, 815),
				"walls": wide_frame(2450) + [Rect2(480, 385, 300, 28), Rect2(1050, 585, 300, 28), Rect2(1770, 690, 300, 28)],
				"phase_walls": [Rect2(1420, 590, 38, 308)],
				"fray_ledges": [{"rect": Rect2(1540, 680, 200, 28), "delay": 0.75}],
				"checkpoint": Vector2(1270, 805),
				"shards": [Vector2(560, 305), Vector2(1160, 510), Vector2(2000, 605)],
				"shard_phases": [-1, 1, -1],
			}, true)
		35:
			base.merge({
				"name": "Sunk Button",
				"hint": "The loose patch sinks slowly. Push it onto the button before turning upward.",
				"backdrop": 4,
				"environment": "water",
				"environment_zone": Rect2(430, 430, 1010, 468),
				"exit": Vector2(1630, 285),
				"walls": FRAME + [Rect2(750, 485, 40, 413), Rect2(1170, 385, 310, 28)],
				"crate": Vector2(460, 835),
				"pad": Vector2(630, 876),
				"checkpoint": Vector2(930, 285),
				"shards": [Vector2(450, 750), Vector2(970, 650), Vector2(1440, 310)],
			}, true)
		36:
			base.merge({
				"name": "Crosswind",
				"hint": "The dunes push right. Shift to the upper hem when the cutter turns back.",
				"backdrop": 5,
				"width": 2600.0,
				"environment": "dunes",
				"environment_zone": Rect2(390, 250, 1840, 648),
				"exit": Vector2(2350, 285),
				"walls": wide_frame(2600) + [Rect2(540, 700, 290, 28), Rect2(1230, 530, 320, 28), Rect2(1960, 380, 280, 28)],
				"mechanisms": [{"kind": "cutter", "from": Vector2(1020, 740), "to": Vector2(1420, 740), "period": 4.2}],
				"fray_ledges": [{"rect": Rect2(970, 575, 205, 28), "delay": 0.55}],
				"checkpoint": Vector2(1480, 455),
				"shards": [Vector2(480, 755), Vector2(1350, 450), Vector2(2110, 305)],
			}, true)
		37:
			base.merge({
				"name": "Sandglass",
				"hint": "Turn to open the hem, ride the moving ledge, and beat the falling sand.",
				"backdrop": 5,
				"width": 2450.0,
				"environment": "dunes",
				"environment_zone": Rect2(400, 260, 1660, 638),
				"start": Vector2(2210, 275),
				"exit": Vector2(290, 815),
				"walls": wide_frame(2450) + [Rect2(1760, 390, 290, 28), Rect2(650, 660, 300, 28)],
				"timed_gates": [Rect2(1270, 198, 36, 700)],
				"gate_window": 2.4,
				"ferries": [{"from": Vector2(1600, 610), "to": Vector2(1140, 430), "size": Vector2(205, 28), "period": 4.8}],
				"checkpoint": Vector2(960, 590),
				"shards": [Vector2(2050, 285), Vector2(1360, 500), Vector2(470, 755)],
			}, true)
		38:
			base.merge({
				"name": "Seed Vault",
				"hint": "Set the patch in its notch. The flower grows a route above the roots.",
				"backdrop": 6,
				"environment": "forest",
				"environment_zone": Rect2(380, 260, 1250, 638),
				"start": Vector2(1530, 820),
				"exit": Vector2(300, 285),
				"walls": FRAME + [Rect2(1240, 575, 40, 323), Rect2(590, 455, 325, 28)],
				"crate": Vector2(1430, 835),
				"pad": Vector2(1080, 876),
				"bloom_pads": [Vector2(730, 870)],
				"checkpoint": Vector2(990, 380),
				"shards": [Vector2(1480, 755), Vector2(870, 690), Vector2(510, 285)],
			}, true)
		39:
			base.merge({
				"name": "Branch Turn",
				"hint": "Circle the high branch. A falling stitch blocks the direct return.",
				"backdrop": 6,
				"width": 2400.0,
				"environment": "forest",
				"environment_zone": Rect2(420, 240, 1600, 658),
				"start": Vector2(2140, 285),
				"exit": Vector2(300, 815),
				"walls": wide_frame(2400) + [Rect2(1770, 410, 310, 28), Rect2(1040, 580, 320, 28)],
				"mechanisms": [{"kind": "pulley", "from": Vector2(950, 270), "to": Vector2(950, 720), "anchor": Vector2(950, 210), "period": 3.9, "trigger": Vector2(1490, 285), "trigger_radius": 100.0}],
				"checkpoint": Vector2(1110, 505),
				"shards": [Vector2(2010, 285), Vector2(1340, 490), Vector2(480, 755)],
			}, true)
		40:
			base.merge({
				"name": "Comet Seam",
				"hint": "The slow fall gives you one long jump across the unstitched gap.",
				"backdrop": 7,
				"width": 2850.0,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 2570, 700),
				"exit": Vector2(2610, 815),
				"walls": wide_frame(2850) + [Rect2(620, 680, 300, 28), Rect2(1330, 475, 310, 28), Rect2(2220, 555, 290, 28)],
				"hazards": [Rect2(970, 870, 250, 28), Rect2(1870, 870, 230, 28)],
				"fray_ledges": [{"rect": Rect2(960, 715, 235, 28), "delay": 0.9}],
				"ferries": [{"from": Vector2(1710, 600), "to": Vector2(2110, 440), "size": Vector2(210, 28), "period": 5.3}],
				"checkpoint": Vector2(1500, 400),
				"shards": [Vector2(490, 755), Vector2(1480, 400), Vector2(2300, 480)],
			}, true)
		41:
			base.merge({
				"name": "Moon Tether",
				"hint": "Turn to the ceiling while the chain sleeps. Return below its arc.",
				"backdrop": 7,
				"environment": "space",
				"environment_zone": Rect2(140, 198, 1640, 700),
				"start": Vector2(1600, 820),
				"exit": Vector2(300, 285),
				"walls": FRAME + [Rect2(1250, 575, 42, 323), Rect2(760, 390, 320, 28)],
				"phase_walls": [Rect2(960, 660, 280, 28)],
				"mechanisms": [{"kind": "chain", "from": Vector2(560, 530), "to": Vector2(880, 530), "period": 4.1, "shift_armed": true}],
				"checkpoint": Vector2(950, 285),
				"shards": [Vector2(1480, 755), Vector2(1020, 590), Vector2(490, 285)],
				"shard_phases": [-1, 1, -1],
			}, true)
		42:
			base.merge({
				"name": "Wet Stitch",
				"hint": "The rain drives you across the warning mark. Turn high before the bobbin drops.",
				"backdrop": 8,
				"width": 2550.0,
				"environment": "rain",
				"environment_zone": Rect2(400, 230, 1830, 668),
				"exit": Vector2(2310, 815),
				"walls": wide_frame(2550) + [Rect2(860, 605, 290, 28), Rect2(1650, 500, 300, 28)],
				"mechanisms": [{"kind": "pulley", "from": Vector2(1250, 270), "to": Vector2(1250, 745), "anchor": Vector2(1250, 210), "period": 3.1, "trigger": Vector2(720, 820), "trigger_radius": 100.0}],
				"checkpoint": Vector2(1540, 805),
				"shards": [Vector2(490, 755), Vector2(1330, 350), Vector2(2140, 755)],
			}, true)
		43:
			base.merge({
				"name": "Umbrella Run",
				"hint": "A turn opens the tall seams. Hide under the awning until the chain passes.",
				"backdrop": 8,
				"width": 2700.0,
				"environment": "rain",
				"environment_zone": Rect2(440, 215, 1900, 683),
				"start": Vector2(2480, 820),
				"exit": Vector2(300, 815),
				"walls": wide_frame(2700) + [Rect2(1790, 540, 350, 28), Rect2(750, 525, 350, 28)],
				"timed_gates": [Rect2(1460, 198, 36, 700), Rect2(580, 198, 36, 700)],
				"gate_window": 3.0,
				"mechanisms": [{"kind": "chain", "from": Vector2(1000, 690), "to": Vector2(1350, 690), "period": 3.8}],
				"checkpoint": Vector2(1240, 810),
				"shards": [Vector2(2300, 750), Vector2(1240, 440), Vector2(450, 755)],
			}, true)
		44:
			base.merge({
				"name": "Slip Knot",
				"hint": "Ice carries your speed. Catch the flower to clear the torn hem.",
				"backdrop": 9,
				"width": 2450.0,
				"environment": "frost",
				"environment_zone": Rect2(450, 520, 1540, 378),
				"exit": Vector2(2200, 285),
				"walls": wide_frame(2450) + [Rect2(650, 680, 290, 28), Rect2(1240, 480, 290, 28), Rect2(1880, 385, 250, 28)],
				"bloom_pads": [Vector2(930, 870)],
				"hazards": [Rect2(1060, 870, 180, 28)],
				"fray_ledges": [{"rect": Rect2(1050, 625, 200, 28), "delay": 0.45}],
				"checkpoint": Vector2(1470, 405),
				"shards": [Vector2(490, 755), Vector2(1360, 405), Vector2(2040, 310)],
			}, true)
		45:
			base.merge({
				"name": "Frozen Clock",
				"hint": "The cutter patrols a narrow lane. Turn the gate open only when it moves away.",
				"backdrop": 9,
				"width": 2600.0,
				"environment": "frost",
				"environment_zone": Rect2(400, 240, 1820, 658),
				"start": Vector2(2370, 275),
				"exit": Vector2(290, 815),
				"walls": wide_frame(2600) + [Rect2(1870, 405, 320, 28), Rect2(730, 600, 300, 28)],
				"timed_gates": [Rect2(1530, 198, 36, 700)],
				"gate_window": 2.0,
				"mechanisms": [{"kind": "cutter", "from": Vector2(1180, 695), "to": Vector2(1490, 695), "period": 3.0}],
				"checkpoint": Vector2(1090, 525),
				"shards": [Vector2(2160, 285), Vector2(1330, 600), Vector2(500, 755)],
			}, true)
		46:
			base.merge({
				"name": "Four Corners",
				"hint": "Each turn lands on another wall. Gather the corner buttons before the center zipper.",
				"backdrop": 2,
				"start": Vector2(960, 820),
				"exit": Vector2(960, 285),
				"walls": FRAME + [Rect2(680, 420, 35, 260), Rect2(1200, 420, 35, 260), Rect2(810, 540, 300, 28)],
				"phase_walls": [Rect2(760, 320, 400, 28)],
				"checkpoint": Vector2(1520, 540),
				"shards": [Vector2(360, 755), Vector2(1510, 755), Vector2(965, 385)],
				"shard_phases": [-1, -1, 1],
			}, true)
		47:
			base.merge({
				"name": "The Long Hem",
				"hint": "Ride one moving stitch to the next. The warning mark starts the final weight.",
				"backdrop": 6,
				"width": 3200.0,
				"environment": "forest",
				"environment_zone": Rect2(450, 260, 2430, 638),
				"exit": Vector2(2950, 285),
				"walls": wide_frame(3200) + [Rect2(630, 680, 270, 28), Rect2(1430, 500, 290, 28), Rect2(2520, 400, 280, 28)],
				"ferries": [
					{"from": Vector2(990, 740), "to": Vector2(1320, 560), "size": Vector2(200, 28), "period": 4.5},
					{"from": Vector2(1840, 640), "to": Vector2(2200, 450), "size": Vector2(200, 28), "period": 4.9},
				],
				"mechanisms": [{"kind": "pulley", "from": Vector2(2400, 270), "to": Vector2(2400, 720), "anchor": Vector2(2400, 210), "period": 3.6, "trigger": Vector2(2050, 500), "trigger_radius": 95.0}],
				"fray_ledges": [{"rect": Rect2(2290, 520, 200, 28), "delay": 0.65}],
				"checkpoint": Vector2(1690, 425),
				"shards": [Vector2(520, 755), Vector2(1590, 425), Vector2(2710, 325)],
			}, true)
		48:
			base.merge({
				"name": "Spool Maze",
				"hint": "Seat the patch, open the lit seam, then take the route across the ceiling.",
				"backdrop": 3,
				"width": 2450.0,
				"exit": Vector2(2190, 285),
				"walls": wide_frame(2450) + [Rect2(670, 575, 40, 323), Rect2(1490, 500, 42, 398), Rect2(1720, 390, 260, 28)],
				"phase_walls": [Rect2(1090, 410, 38, 400)],
				"crate": Vector2(440, 835),
				"pad": Vector2(580, 876),
				"checkpoint": Vector2(1240, 285),
				"shards": [Vector2(400, 755), Vector2(1270, 290), Vector2(1930, 320)],
				"shard_phases": [-1, 1, -1],
			}, true)
		49:
			base.merge({
				"name": "The Last Knot",
				"hint": "Read the marks, turn with the moving hems, and stitch the final zipper open.",
				"backdrop": 8,
				"width": 3400.0,
				"environment": "rain",
				"environment_zone": Rect2(520, 240, 2360, 658),
				"exit": Vector2(3150, 285),
				"walls": wide_frame(3400) + [Rect2(620, 650, 300, 28), Rect2(1450, 475, 310, 28), Rect2(2680, 380, 300, 28)],
				"phase_walls": [Rect2(1040, 485, 38, 360)],
				"fray_ledges": [{"rect": Rect2(1110, 635, 210, 28), "delay": 0.65}],
				"timed_gates": [Rect2(2020, 198, 36, 700)],
				"gate_window": 3.0,
				"bloom_pads": [Vector2(540, 870)],
				"ferries": [{"from": Vector2(2140, 650), "to": Vector2(2530, 455), "size": Vector2(210, 28), "period": 4.8}],
				"mechanisms": [{"kind": "pulley", "from": Vector2(1870, 270), "to": Vector2(1870, 740), "anchor": Vector2(1870, 210), "period": 3.6, "trigger": Vector2(1600, 400), "trigger_radius": 100.0}],
				"checkpoint": Vector2(1770, 395),
				"shards": [Vector2(460, 755), Vector2(1650, 400), Vector2(2840, 305)],
				"shard_phases": [-1, 1, -1],
			}, true)
	return base
