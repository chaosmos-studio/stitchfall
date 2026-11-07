extends RefCounted

# Night Quilt: the whole room is night quilt, where gravity is a quarter as strong. A sewn moon floats over a
# needle pit that only a night jump can reach, and every turn of the room is a long, slow float. Pins ignore
# the quilt and fall at their usual speed, so here they land long before you do.

const NAME: String = "Night Quilt"
const LINE: String = "Everything floats a little longer here."
const ZONE: Rect2 = Rect2(360, 280, 1200, 580)
const MOON: Rect2 = Rect2(860, 680, 200, 24)
# A cloud hung from the ceiling over the far side, needled underneath at the height a full night jump reaches.
const CLOUD: Rect2 = Rect2(1120, 280, 220, 140)
const PIN_FLOOR: float = StitchfallLevels.FLOOR_Y - 30.0
# The naive runs: a hop sized for any other room, the long floaty landing, a full jump under the cloud, the
# early flip that lets the pin get there first, and a rest on the moon.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,22:+jump,60:-jump,125:+jump,276:shift,291:shift", "naive": "0:+move_right,22:+jump,26:-jump", "caught": "hit"},
	{
		"route": "0:+move_right,22:+jump,60:-jump,125:+jump,150:shift,165:shift,200:-move_right,201:+move_left,400:shift,415:shift",
		"naive": "0:+move_right,22:+jump,60:-jump,125:+jump,276:shift,291:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,22:+jump,60:-jump,125:+jump,127:-jump,240:-move_right,241:+move_left,256:+jump,320:-jump,345:+jump,380:-jump",
		"naive": "0:+move_right,22:+jump,60:-jump,125:+jump,276:shift,291:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,22:+jump,60:-jump,125:+jump,190:-jump,207:shift,222:shift,320:-move_right,321:+move_left,340:+jump,342:-jump",
		"naive": "0:+move_right,22:+jump,60:-jump,125:+jump,150:shift,165:shift,200:-move_right,201:+move_left",
		"caught": "hit",
	},
	{
		"route": "0:shift,15:shift,100:+move_right,200:-move_right,205:shift,220:shift,296:+move_right,300:+jump,302:-jump,378:-move_right,378:shift,393:shift,394:+move_right,455:shift,470:shift",
		"naive": "0:shift,15:shift,100:+move_right,200:-move_right,205:shift,220:shift,340:+move_right,344:+jump,346:-jump",
		"caught": "hit",
	},
]


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	var pit: Dictionary = StitchfallLevels.floor_needles(640, 1240)
	# The far floor's needles lie flat until the runner reaches the moon, then rise while a night jump is
	# still floating down to them.
	var landing: Dictionary = {"rect": Rect2(1240, StitchfallLevels.FLOOR_Y - 28.0, 320, 28.0), "dir": Vector2.UP, "trigger": Rect2(860, 560, 200, 120), "delay": 0.9}
	var cloud_needles: Dictionary = {"rect": Rect2(CLOUD.position.x, CLOUD.end.y, CLOUD.size.x, 28.0), "dir": Vector2.DOWN}
	var home: Vector2 = Vector2(420, StitchfallLevels.ZIP_FLOOR.y)
	room.merge({
		"backdrop": 7,
		"environment": "space",
		"environment_zone": ZONE,
		"walls": StitchfallLevels.screen_frame() + [MOON],
		"spikes": [pit],
	}, true)
	match index:
		0:
			room.merge({
				"name": "Hang Time",
				"par": 10.0,
				"accent": Color("6f78c9"),
				"exit": StitchfallLevels.ZIP_CEILING,
				"pins": [Vector2(1420, PIN_FLOOR)],
				"shards": [Vector2(880, 640), Vector2(1330, 450)],
			}, true)
		1:
			room.merge({
				"name": "Soft Landing",
				"par": 13.0,
				"accent": Color("c9a24a"),
				"exit": home,
				"popups": [landing],
				"shards": [Vector2(880, 640), Vector2(1250, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
		2:
			# The habit's full jump off the moon floats straight into the cloud's needles. A hop passes under.
			room.merge({
				"name": "Mind Your Head",
				"par": 13.0,
				"accent": Color("9a6fc4"),
				"exit": home,
				"walls": StitchfallLevels.screen_frame() + [MOON, CLOUD],
				"spikes": [pit, cloud_needles],
				"pins": [Vector2(1360, PIN_FLOOR)],
				"shards": [Vector2(880, 640), Vector2(1250, 560)],
			}, true)
		3:
			# A turn sends the pin to the ceiling in a blink while the runner floats up behind it, so an early
			# flip finds the pin already waiting where it lands. Turn once past it.
			room.merge({
				"name": "After You",
				"par": 14.0,
				"accent": Color("5f8fc9"),
				"exit": Vector2(420, StitchfallLevels.ZIP_CEILING.y),
				"popups": [landing],
				"pins": [Vector2(1360, PIN_FLOOR)],
				"shards": [Vector2(880, 640), Vector2(1440, 440)],
			}, true)
		4:
			# The moon is only pinned, so there is no resting on it, and the zipper runs down its track into the
			# raised needles. A slow fall reaches it before the needles do.
			room.merge({
				"name": "Moonset",
				"par": 15.0,
				"accent": Color("c46f8a"),
				"walls": StitchfallLevels.screen_frame() + [CLOUD],
				"spikes": [pit, cloud_needles],
				"fray_ledges": [{"rect": MOON, "delay": 0.5}],
				"popups": [landing],
				"pins": [Vector2(1300, PIN_FLOOR)],
				"exit": StitchfallLevels.ZIP_CEILING,
				"exit_flee": [StitchfallLevels.ZIP_FLOOR],
				"flee_radius": 200.0,
				"shards": [Vector2(560, StitchfallLevels.STAND_CEILING + 6.0), Vector2(980, 520), Vector2(1250, 560)],
			}, true)
	return room
