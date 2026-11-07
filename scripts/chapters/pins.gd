extends RefCounted

# Loose Pins: pincushions fall every time you turn, exactly as fast as you do, so a pin keeps its place in
# line with you through every turn.

const NAME: String = "Loose Pins"
const LINE: String = "Whatever you turn, falls with you."
# Where a pincushion rests on the floor or the ceiling, its centre one body radius off the surface.
const PIN_FLOOR: float = StitchfallLevels.FLOOR_Y - 30.0
const PIN_CEILING: float = StitchfallLevels.CEILING_Y + 30.0
# The naive runs are the habits the chapter punishes: flipping with a pin in line, and walking into one.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,80:+jump,100:-jump", "naive": "0:+move_right", "caught": "hit"},
	{
		"route": "0:+move_right,80:+jump,100:-jump,118:-move_right,119:shift,134:shift,190:+move_right,222:-move_right,223:shift,238:shift,300:+move_right",
		"naive": "0:+move_right,40:-move_right,41:shift,56:shift,120:+move_right",
		"caught": "hit",
	},
	{"route": "5:shift,20:+move_left,70:-move_left,95:shift,96:+move_right", "naive": "0:+move_right,40:-move_right,41:shift,56:shift,120:+move_right", "caught": "hit"},
	{
		"route": "5:shift,20:+move_left,70:-move_left,95:shift,96:+move_right,250:+jump,262:shift,263:-jump,264:-move_right,300:+move_left,350:shift",
		"naive": "5:shift,20:+move_left,70:-move_left,95:shift,96:+move_right,250:+jump,262:shift,263:-jump,264:-move_right,300:+move_left,333:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,30:-move_right,31:shift,46:shift,110:+move_right,124:+jump,144:-jump,170:-move_right,175:+jump,187:shift,188:-jump,230:+move_left,262:shift",
		"naive": "0:+move_right,30:-move_right,31:shift,46:shift,110:+move_right",
		"caught": "hit",
	},
]


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	room.merge({"backdrop": 1}, true)
	match index:
		0:
			room.merge({
				"name": "Mind the Pins",
				"par": 5.0,
				"accent": Color("d0563f"),
				"pins": [Vector2(1000, PIN_FLOOR)],
				"shards": [Vector2(680, StitchfallLevels.STAND_FLOOR), Vector2(1000, 690)],
			}, true)
		1:
			room.merge({
				"name": "Heads Up",
				"par": 8.0,
				"accent": Color("e07a3a"),
				"pins": [Vector2(1000, PIN_FLOOR)],
				"shards": [Vector2(680, StitchfallLevels.STAND_FLOOR), Vector2(1250, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
		2:
			room.merge({
				"name": "Clean Sweep",
				"par": 8.0,
				"accent": Color("c9a23a"),
				"pins": [Vector2(1530, PIN_FLOOR)],
				"exit": StitchfallLevels.ZIP_CEILING,
				"shards": [Vector2(400, 560), Vector2(1000, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
		3:
			room.merge({
				"name": "Company",
				"par": 12.0,
				"accent": Color("7a8ee8"),
				"pins": [Vector2(900, PIN_FLOOR), Vector2(1300, PIN_FLOOR)],
				"exit": Vector2(960, StitchfallLevels.ZIP_FLOOR.y),
				"flowers": [{"pos": Vector2(780, StitchfallLevels.STAND_CEILING - 10.0), "gravity": Vector2.UP}],
				"shards": [Vector2(400, 560), Vector2(1000, StitchfallLevels.STAND_CEILING + 6.0), Vector2(1521, 650)],
			}, true)
		4:
			room.merge({
				# Two pins wait on shelves over a needled floor, and any turn drops them. The way down ends in a
				# race: into the zipper before they land on it.
				"name": "Pin Drop",
				"par": 8.0,
				"accent": Color("b2524a"),
				"walls": StitchfallLevels.screen_frame() + [Rect2(760, 600, 120, 24), Rect2(1060, 600, 120, 24)],
				"spikes": [StitchfallLevels.floor_needles(700, 1320)],
				"exit": Vector2(1390, StitchfallLevels.ZIP_FLOOR.y),
				"pins": [Vector2(820, 570), Vector2(1120, 570)],
				"flowers": [{"pos": Vector2(560, StitchfallLevels.STAND_CEILING - 10.0), "gravity": Vector2.UP}],
				"shards": [Vector2(620, StitchfallLevels.STAND_FLOOR), Vector2(970, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
	return room
