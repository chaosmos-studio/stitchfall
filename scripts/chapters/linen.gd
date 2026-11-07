extends RefCounted

# Plain Linen: one room, five pranks. Each room's buttons sit on the route its prank asks for, so where the
# buttons are is the clue. The jump strip in the middle never changes.

const NAME: String = "Plain Linen"
const LINE: String = "The same room, never the same twice."
# Each room's proof, replayed by tests/run_tests.gd: a route that finishes it with all three stars, and the
# obvious run its prank is built to catch ("hit": the runner unravels, "stuck": the room is not finished).
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,66:+jump,86:-jump"},
	{"route": "0:+move_right,45:shift,60:shift,200:shift,215:shift", "naive": "0:+move_right,66:+jump,86:-jump", "caught": "hit"},
	{
		"route": "0:+move_right,66:+jump,86:-jump,150:-move_right,152:+move_left,170:-move_left,172:+jump,182:shift,197:shift,210:-jump,215:+move_right",
		"naive": "0:+move_right,66:+jump,86:-jump",
		"caught": "stuck",
	},
	{"route": "0:+move_right,45:-move_right,46:shift,90:+move_left,125:-move_left,140:shift,155:shift,250:shift", "naive": "0:+move_right,66:+jump,86:-jump", "caught": "hit"},
	{
		"route": "0:+move_right,45:-move_right,46:shift,90:+move_left,125:-move_left,140:shift,155:shift,260:+move_left,285:-move_left,290:+move_right,330:-move_right,335:shift",
		"naive": "0:+move_right,66:+jump,86:-jump",
		"caught": "hit",
	},
]


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	var strip: Dictionary = StitchfallLevels.floor_needles(900, 1020)
	match index:
		0:
			room.merge({
				"name": "A Gentle Start",
				"par": 5.0,
				"accent": Color("18c9df"),
				"spikes": [strip],
				"shards": [Vector2(680, StitchfallLevels.STAND_FLOOR), Vector2(960, 745)],
			}, true)
		1:
			# The landing pops up its needles as you jump, so the only way over is the ceiling.
			room.merge({
				"name": "Same Room",
				"par": 7.0,
				"accent": Color("f46b42"),
				"spikes": [strip],
				"popups": [{"rect": Rect2(1020, StitchfallLevels.FLOOR_Y - 28.0, 300, 28.0), "dir": Vector2.UP, "trigger": Rect2(760, 640, 260, 220), "delay": 0.12}],
				"shards": [Vector2(680, StitchfallLevels.STAND_FLOOR), Vector2(960, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
		2:
			# The zipper is sewn on a track up the right wall, and runs up it once it opens.
			room.merge({
				"name": "Almost There",
				"par": 8.0,
				"accent": Color("e9ab34"),
				"spikes": [strip],
				"exit_flee": [StitchfallLevels.ZIP_CEILING],
				"flee_radius": 230.0,
				"shards": [Vector2(680, StitchfallLevels.STAND_FLOOR), Vector2(960, 745)],
			}, true)
		3:
			# Both the floor and the ceiling are needled across the middle. Falling sideways is the way over.
			room.merge({
				"name": "Nothing New",
				"par": 8.0,
				"accent": Color("8e7ae8"),
				"spikes": [strip, StitchfallLevels.floor_needles(1020, 1320), StitchfallLevels.ceiling_needles(700, 1320)],
				"shards": [Vector2(680, StitchfallLevels.STAND_FLOOR), Vector2(960, 510)],
			}, true)
		4:
			room.merge({
				"name": "One More Time",
				"par": 10.0,
				"accent": Color("b45d4c"),
				"spikes": [strip, StitchfallLevels.ceiling_needles(700, 1320)],
				"popups": [{"rect": Rect2(1020, StitchfallLevels.FLOOR_Y - 28.0, 300, 28.0), "dir": Vector2.UP, "trigger": Rect2(760, 640, 260, 220), "delay": 0.12}],
				"exit": StitchfallLevels.ZIP_CEILING,
				"exit_flee": [StitchfallLevels.ZIP_FLOOR],
				"flee_radius": 200.0,
				"shards": [Vector2(680, StitchfallLevels.STAND_FLOOR), Vector2(960, 510), Vector2(1521, 640)],
			}, true)
	return room
