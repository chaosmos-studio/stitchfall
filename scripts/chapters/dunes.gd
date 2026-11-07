extends RefCounted

# Sand Drift: a needle strip the wind carries you over, whichever way the room is turned. The wind blows to the
# right on the screen, so in the air it always wins: a jump with it goes half again as far, a jump against it
# falls short. Turned once, the wind pushes back against the fall and the runner drifts upwind, slowly. Turned
# the other way, it adds to the fall and throws the runner at the right wall.

const NAME: String = "Sand Drift"
const LINE: String = "The wind only knows one way."
# The naive runs trust the wind the way the room before taught: to carry a jump, or to bring the runner home.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,48:+jump,68:-jump,107:+jump,127:-jump,162:-move_right,164:shift,179:shift,230:+move_left,250:-move_left,254:shift,269:shift"},
	{
		"route": "0:+move_right,48:+jump,68:-jump,94:+jump,114:-jump,162:-move_right,164:shift,179:shift,230:+move_left,250:-move_left,254:shift,269:shift",
		"naive": "0:+move_right,48:+jump,68:-jump,107:+jump,127:-jump,162:-move_right,164:shift,179:shift,230:+move_left,250:-move_left,254:shift,269:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,40:+jump,60:-jump,148:-move_right,149:+move_left,240:+jump,250:-move_left,255:shift,260:-jump,330:+move_right",
		"naive": "0:+move_right,40:+jump,60:-jump,148:-move_right,149:+move_left,272:+jump,292:-jump",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,48:+jump,68:-jump,94:+jump,114:-jump,152:-move_right,153:+move_left,197:-move_left,203:shift,218:shift,257:+move_left,340:-move_left,344:shift,359:shift",
		"naive": "0:+move_right,48:+jump,68:-jump,94:+jump,114:-jump,162:-move_right,164:shift,179:shift,230:+move_left,250:-move_left,254:shift,269:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,40:+jump,60:-jump,86:+jump,106:-jump,144:-move_right,145:+move_left,189:-move_left,195:shift,210:shift,249:+move_left,332:-move_left,336:shift,351:shift,400:+move_left,448:+jump,462:shift,463:-move_left,468:-jump,540:+move_right",
		"naive": "0:+move_right,40:+jump,60:-jump,86:+jump,106:-jump,150:-move_right,152:shift,167:shift",
		"caught": "hit",
	},
]
# The wind starts a little past the start, so its dashed edge shows where it begins.
const WIND: Rect2 = Rect2(560, 280, 1000, 580)
const PIN_FLOOR: float = StitchfallLevels.FLOOR_Y - 30.0
# Upwind rooms put the zipper back by the start, which moves aside to make room for it.
const UPWIND_ZIP: Vector2 = Vector2(420, 781)
const UPWIND_START: Vector2 = Vector2(470, 821)


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	room.merge({"backdrop": 5, "environment": "dunes", "environment_zone": WIND}, true)
	# 230 wide: a jump with the wind clears about 235 of needles, a still one about 180, one into the wind 120.
	var strip: Dictionary = StitchfallLevels.floor_needles(760, 990)
	var far_strip: Dictionary = StitchfallLevels.floor_needles(1110, 1260)
	# Needles high on the right wall, where a turn down from the ceiling near the wall throws the runner.
	var wall: Dictionary = {"rect": Rect2(StitchfallLevels.RIGHT_X - 28.0, 280, 28, 150), "dir": Vector2.LEFT}
	match index:
		0:
			room.merge({
				"name": "Tailwind",
				"par": 8.0,
				"accent": Color("c98a3f"),
				"spikes": [strip],
				"pins": [Vector2(1230, PIN_FLOOR)],
				"shards": [Vector2(880, 700), Vector2(1240, 700), Vector2(1420, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
		1:
			# The landing is too short to stop on: the second jump has to leave as the first one lands.
			room.merge({
				"name": "Kite",
				"par": 8.0,
				"accent": Color("d49a4a"),
				"spikes": [strip, far_strip],
				"shards": [Vector2(880, 700), Vector2(1230, 700), Vector2(1420, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
		2:
			# The zipper is upwind, back past the strip. No jump makes it, but one turn at the top of a hop does.
			room.merge({
				"name": "Upwind",
				"par": 9.0,
				"accent": Color("b8743a"),
				"spikes": [strip],
				"start": UPWIND_START,
				"exit": UPWIND_ZIP,
				"shards": [Vector2(880, 700), Vector2(1490, 790)],
			}, true)
		3:
			room.merge({
				"name": "Crosswind",
				"par": 11.0,
				"accent": Color("a8663a"),
				"spikes": [strip, far_strip, wall],
				"shards": [Vector2(880, 700), Vector2(1230, 700), Vector2(1150, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
		4:
			room.merge({
				"name": "Sand Drift",
				"par": 15.0,
				"accent": Color("c4693f"),
				"spikes": [strip, far_strip, wall],
				"start": UPWIND_START,
				"exit": UPWIND_ZIP,
				"flowers": [{"pos": Vector2(1430, 806), "gravity": Vector2.DOWN}],
				"shards": [Vector2(880, 700), Vector2(1230, 700), Vector2(1150, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
	return room
