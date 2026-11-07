extends RefCounted

# Blue Thread: a pool over a needle strip, a pin and a step by the zipper. In the water every fall is slow, so a
# jump hangs twice as long and carries across the strip and up the step where a dry jump falls short. Only the
# runner is slowed: pins and pop-up needles keep their own time.

const NAME: String = "Blue Thread"
const LINE: String = "Hold your breath."
# The naive runs are the dry habit of the room before: the jumps the pool made easy, now somewhere it is not.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,62:+jump,86:-jump,150:+jump,174:-jump,248:+jump,272:-jump"},
	{
		"route": "0:+move_right,62:+jump,86:-jump,150:+jump,174:-jump,248:+jump,272:-jump,300:+jump,324:-jump",
		"naive": "0:+move_right,62:+jump,86:-jump,150:+jump,174:-jump,248:+jump,272:-jump",
		"caught": "stuck",
	},
	{
		"route": "0:shift,15:shift,16:+move_right,88:+jump,112:-jump,184:+jump,208:-jump,278:+jump,302:-jump,330:+jump,354:-jump",
		"naive": "0:+move_right,62:+jump,86:-jump,150:+jump,174:-jump,248:+jump,272:-jump,300:+jump,324:-jump",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,62:+jump,86:-jump,96:-move_right,97:shift,112:shift,113:+move_right,150:-move_right,200:+move_right,218:+jump,238:-jump,262:-move_right,268:shift,283:shift,284:+move_right",
		"naive": "0:+move_right,62:+jump,86:-jump,150:+jump,174:-jump,248:+jump,272:-jump,300:+jump,324:-jump",
		"caught": "hit",
	},
	{
		"route": "0:shift,15:shift,16:+move_right,88:+jump,112:-jump,122:-move_right,123:shift,138:shift,139:+move_right,175:-move_right,222:+move_right,247:+jump,267:-jump,300:shift,315:shift",
		"naive": "0:shift,15:shift,16:+move_right,88:+jump,112:-jump,184:+jump,208:-jump,278:+jump,302:-jump,330:+jump,354:-jump",
		"caught": "hit",
	},
]
const POOL: Rect2 = Rect2(560, 500, 880, 360)
const HIGH_POOL: Rect2 = Rect2(560, 280, 880, 360)
const PIN_FLOOR: float = StitchfallLevels.FLOOR_Y - 30.0
# The strip is 220 wide: a dry jump clears about 180 of needles, a jump from the water about 265.
const STRIP_FROM: float = 760.0
const STRIP_TO: float = 980.0
# The steps by the zipper stand 125 and 250 high, and a dry jump rises 112, a jump from the water 135.
const STEP: Rect2 = Rect2(1320, 735, 240, 125)
const LOW_STEP: Rect2 = Rect2(1320, 735, 120, 125)
const HIGH_STEP: Rect2 = Rect2(1440, 610, 120, 250)
const HIGH_LOW_STEP: Rect2 = Rect2(1320, 280, 120, 125)
const HIGH_HIGH_STEP: Rect2 = Rect2(1440, 280, 120, 250)


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	room.merge({"backdrop": 4, "environment": "water", "environment_zone": POOL}, true)
	var strip: Dictionary = StitchfallLevels.floor_needles(STRIP_FROM, STRIP_TO)
	var high_strip: Dictionary = StitchfallLevels.ceiling_needles(STRIP_FROM, STRIP_TO)
	var frame: Array[Rect2] = StitchfallLevels.screen_frame()
	match index:
		0:
			room.merge({
				"name": "Deep End",
				"par": 8.0,
				"accent": Color("3f8fa8"),
				"walls": frame + [STEP],
				"exit": Vector2(1500, 656),
				"spikes": [strip],
				"pins": [Vector2(1180, PIN_FLOOR)],
				"shards": [Vector2(870, 690), Vector2(1300, 650)],
			}, true)
		1:
			room.merge({
				"name": "Step Up",
				"par": 9.0,
				"accent": Color("2f7f9a"),
				"walls": frame + [LOW_STEP, HIGH_STEP],
				"exit": Vector2(1500, 531),
				"spikes": [strip],
				"pins": [Vector2(1180, PIN_FLOOR)],
				"shards": [Vector2(870, 690), Vector2(1420, 560)],
			}, true)
		2:
			# The whole room hangs from the ceiling now, pool and all, and only the bare strip is left below.
			# The pin starts on the floor and falls up with the first turn.
			room.merge({
				"name": "High Water",
				"par": 10.0,
				"accent": Color("4a9fb5"),
				"environment_zone": HIGH_POOL,
				"walls": frame + [HIGH_LOW_STEP, HIGH_HIGH_STEP],
				"exit": Vector2(1500, 609),
				"spikes": [strip, high_strip],
				"pins": [Vector2(1225, PIN_FLOOR)],
				"shards": [Vector2(870, 450), Vector2(1420, 580)],
			}, true)
		3:
			# The landing raises its needles while the runner still hangs over the strip. Turning over at the top
			# of the jump floats out of the pool, but the pin, which water does not slow, gets to the ceiling first.
			room.merge({
				"name": "Slow Motion",
				"par": 8.0,
				"accent": Color("36748f"),
				"walls": frame + [LOW_STEP, HIGH_STEP],
				"exit": Vector2(1500, 531),
				"spikes": [strip],
				"popups": [{"rect": Rect2(STRIP_TO, StitchfallLevels.FLOOR_Y - 28.0, 340, 28.0), "dir": Vector2.UP, "trigger": Rect2(640, 700, 120, 160), "delay": 1.2}],
				"pins": [Vector2(1265, PIN_FLOOR)],
				"shards": [Vector2(870, 690), Vector2(1225, 440), Vector2(1515, 380)],
			}, true)
		4:
			# Slow Motion hung from the ceiling: the turn at the top of the jump sinks out of the pool, and the pin
			# is waiting on the floor where a held run comes down.
			room.merge({
				"name": "Hold Your Breath",
				"par": 9.0,
				"accent": Color("5a8fb0"),
				"environment_zone": HIGH_POOL,
				"walls": frame + [HIGH_LOW_STEP, HIGH_HIGH_STEP],
				"exit": Vector2(1500, 609),
				"spikes": [strip, high_strip],
				"popups": [{"rect": Rect2(STRIP_TO, StitchfallLevels.CEILING_Y, 340, 28.0), "dir": Vector2.DOWN, "trigger": Rect2(640, 280, 120, 160), "delay": 1.2}],
				"pins": [Vector2(1265, PIN_FLOOR)],
				"shards": [Vector2(870, 450), Vector2(1275, 700), Vector2(1515, 760)],
			}, true)
	return room
