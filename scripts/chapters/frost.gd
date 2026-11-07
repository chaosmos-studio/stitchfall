extends RefCounted

# Frost: the whole room is iced over, so the runner is slow to get going and slower to stop. A needle pit fills
# the floor between the start and the far side, a sewn step floats over it, and the way across is the ceiling.
# A turn of the room swings gravity through a side wall first, and on ice that matters: flipping off the floor
# while running right, or off the ceiling while running left, brakes you dead. The other way round, it throws you.

const NAME: String = "Frost"
const LINE: String = "Nothing here stops when you do."
const ZONE: Rect2 = Rect2(360, 280, 1200, 580)
const STEP: Rect2 = Rect2(880, 640, 200, 24)
const STAND_STEP: float = 601.0
# The naive runs: a jump at the pit, stopping above the step before turning, turning while running right over
# the step, gliding to a stop after the last strip, and waiting on the step for the zipper.
const ROUTES: Array[Dictionary] = [
	{
		"route": "0:shift,15:shift,50:+move_right,235:shift,250:shift,300:shift,300:-move_right,315:shift,370:+move_left,525:shift,540:shift",
		"naive": "0:+move_right,40:+jump",
		"caught": "hit",
	},
	{
		"route": "0:shift,15:shift,50:+move_right,300:-move_right,301:+move_left,416:shift,431:shift,440:-move_left,470:+move_left,470:shift,485:shift,566:shift,581:shift,590:-move_left",
		"naive": "0:shift,15:shift,50:+move_right,150:-move_right,230:shift,245:shift",
		"caught": "hit",
	},
	{
		"route": "0:shift,15:shift,50:+move_right,191:+jump,206:-jump,300:-move_right,301:+move_left,376:+jump,390:-jump,422:shift,437:shift,446:-move_left,476:+move_left,476:shift,491:shift,568:shift,583:shift,592:-move_left",
		"naive": "0:shift,15:shift,50:+move_right,180:shift,195:shift",
		"caught": "hit",
	},
	{
		"route": "0:shift,15:shift,40:+move_right,84:+jump,99:-jump,179:+jump,194:-jump,300:-move_right,301:+move_left,376:+jump,390:-jump,422:shift,437:shift,446:-move_left,476:+move_left,476:shift,491:shift,522:+jump,537:-jump,545:shift,560:shift",
		"naive": "0:shift,15:shift,40:+move_right,84:+jump,99:-jump,179:+jump,194:-jump,300:-move_right,301:+move_left,376:+jump,390:-jump,422:shift,437:shift,446:-move_left,476:+move_left,476:shift,491:shift,522:+jump,537:-jump",
		"caught": "hit",
	},
	{
		"route": "0:shift,15:shift,40:+move_right,84:+jump,99:-jump,179:+jump,194:-jump,300:-move_right,301:+move_left,376:+jump,390:-jump,422:shift,437:shift,446:-move_left,476:+move_left,476:shift,491:shift,522:+jump,537:-jump,545:shift,560:shift",
		"naive": "0:shift,15:shift,40:+move_right,84:+jump,99:-jump,179:+jump,194:-jump,300:-move_right,301:+move_left,376:+jump,390:-jump,422:shift,437:shift,446:-move_left",
		"caught": "stuck",
	},
]


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	var pit: Dictionary = StitchfallLevels.floor_needles(640, 1300)
	var home: Vector2 = Vector2(420, StitchfallLevels.ZIP_FLOOR.y)
	var near_strip: Dictionary = StitchfallLevels.ceiling_needles(540, 660)
	var far_strip: Dictionary = StitchfallLevels.ceiling_needles(1100, 1260)
	var corner: Dictionary = {"rect": Rect2(StitchfallLevels.LEFT_X, StitchfallLevels.CEILING_Y, 28.0, 140.0), "dir": Vector2.RIGHT}
	room.merge({
		"backdrop": 9,
		"environment": "frost",
		"environment_zone": ZONE,
		"walls": StitchfallLevels.screen_frame() + [STEP],
		"spikes": [pit],
		"exit": home,
	}, true)
	match index:
		0:
			room.merge({
				"name": "Black Ice",
				"par": 15.0,
				"accent": Color("7fb3c9"),
				"walls": StitchfallLevels.screen_frame(),
				"shards": [Vector2(960, 360), Vector2(1430, StitchfallLevels.STAND_FLOOR)],
			}, true)
		1:
			# Even standing still, a turn off the ceiling falls sideways first and throws you right, past the step.
			# Only running left onto it lands you on it.
			room.merge({
				"name": "Slip Up",
				"par": 16.0,
				"accent": Color("9a8fd0"),
				"shards": [Vector2(1420, 360), Vector2(980, STAND_STEP)],
			}, true)
		2:
			# Needles on the ceiling past the step. Running right over the step is the tempting time to turn, and
			# running right a turn throws you.
			room.merge({
				"name": "Wrong Way",
				"par": 16.0,
				"accent": Color("6fae8f"),
				"spikes": [pit, far_strip],
				"shards": [Vector2(1420, 360), Vector2(980, STAND_STEP)],
			}, true)
		3:
			# A strip across the ceiling on the way home and needles at the top of the left wall leave no room to
			# glide to a stop. Running left, a turn is the brake.
			room.merge({
				"name": "Hard Stop",
				"par": 16.0,
				"accent": Color("c98f6f"),
				"spikes": [pit, near_strip, far_strip, corner],
				"shards": [Vector2(600, 420), Vector2(1420, 360), Vector2(980, STAND_STEP)],
			}, true)
		4:
			# The zipper waits on the step and, once open, runs home across the ice the moment you land beside it.
			room.merge({
				"name": "Runaway",
				"par": 16.0,
				"accent": Color("c46f8a"),
				"exit": Vector2(980, STAND_STEP - 40.0),
				"exit_flee": [home],
				"flee_radius": 150.0,
				"spikes": [pit, near_strip, far_strip, corner],
				"flowers": [{"pos": Vector2(1040, STAND_STEP - 10.0), "gravity": Vector2.DOWN}],
				"shards": [Vector2(600, 420), Vector2(1420, 360)],
			}, true)
	return room
