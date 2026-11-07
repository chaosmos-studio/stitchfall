extends RefCounted

# Rainline: rain fills the room, pushing right in gusts that come and go on a steady beat, and the drops lean
# with it. Two needle strips cross the floor and two the ceiling, with a plain island between, so the way out
# runs with the wind and the way home runs into it. The rain only moves the runner in the air.

const NAME: String = "Rainline"
const LINE: String = "The rain keeps its own time."
const ZONE: Rect2 = Rect2(360, 280, 1200, 580)
const ISLAND_X: float = 830.0
const ISLAND_END: float = 1000.0
const PIN_FLOOR: float = StitchfallLevels.FLOOR_Y - 30.0
# The naive runs: the first jump in a gust, waiting out the gust on a patch, a calm jump at the wide strip, a
# calm leap off the wall, and waiting on the floor patch for the gust.
const ROUTES: Array[Dictionary] = [
	{
		"route": "60:+move_right,93:+jump,110:-jump,144:+jump,160:-jump,215:+jump,230:-jump,256:shift,271:shift,322:-move_right,323:+move_left,330:+jump,345:-jump,393:+jump,405:-jump,440:-move_left,560:+move_left,569:+jump,580:-jump",
		"naive": "0:+move_right,33:+jump",
		"caught": "hit",
	},
	{
		"route": "60:+move_right,93:+jump,110:-jump,144:+jump,160:-jump,215:+jump,230:-jump,256:shift,271:shift,322:-move_right,323:+move_left,330:+jump,345:-jump,377:-move_left,525:+move_left,546:+jump,560:-jump,598:+jump,610:-jump",
		"naive": "60:+move_right,93:+jump,110:-jump,144:+jump,160:-jump,215:+jump,230:-jump,256:shift,271:shift,322:-move_right,323:+move_left,330:+jump,345:-jump,393:+jump,405:-jump,440:-move_left,560:+move_left,569:+jump,580:-jump",
		"caught": "hit",
	},
	{
		"route": "60:+move_right,93:+jump,110:-jump,140:-move_right,141:+move_left,156:-move_left,229:+move_right,243:+jump,262:-jump,330:shift,345:shift,390:-move_right,391:+move_left,425:-move_left,525:+move_left,555:+jump,568:-jump,612:+jump,625:-jump",
		"naive": "60:+move_right,93:+jump,110:-jump,144:+jump,160:-jump",
		"caught": "hit",
	},
	{
		"route": "0:shift,10:+move_left,55:-move_left,278:+jump,325:-jump,340:shift,341:+move_right,398:+jump,415:-jump,450:-move_right,525:+move_left,545:+jump,560:-jump,617:+jump,630:-jump",
		"naive": "0:shift,10:+move_left,55:-move_left,150:+jump,190:shift,191:+move_right",
		"caught": "hit",
	},
	{
		"route": "150:+move_right,183:+jump,200:-jump,243:+jump,262:-jump,320:shift,335:shift,380:-move_right,381:+move_left,400:-move_left,525:+move_left,564:+jump,576:-jump,616:+jump,628:-jump",
		"naive": "60:+move_right,93:+jump,110:-jump,140:-move_right,141:+move_left,156:-move_left,229:+move_right,243:+jump,262:-jump",
		"caught": "hit",
	},
]


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	var floor_strips: Array[Dictionary] = [StitchfallLevels.floor_needles(660, ISLAND_X), StitchfallLevels.floor_needles(ISLAND_END, 1150)]
	var ceiling_strips: Array[Dictionary] = [StitchfallLevels.ceiling_needles(660, ISLAND_X), StitchfallLevels.ceiling_needles(ISLAND_END, 1150)]
	var home: Vector2 = Vector2(420, StitchfallLevels.ZIP_CEILING.y)
	room.merge({
		"backdrop": 8,
		"environment": "rain",
		"environment_zone": ZONE,
		"spikes": floor_strips + ceiling_strips,
	}, true)
	match index:
		0:
			# A gust carries a jump past the island into the next strip, and blows a jump home short of it.
			room.merge({
				"name": "Rain Check",
				"par": 17.0,
				"accent": Color("4f9aa8"),
				"exit": home,
				"pins": [Vector2(1440, PIN_FLOOR)],
				"shards": [Vector2(745, 715), Vector2(1080, 425)],
			}, true)
		1:
			# The ceiling island is only a pinned patch over the needles, so there is no waiting on it.
			room.merge({
				"name": "Don't Wait Up",
				"par": 17.0,
				"accent": Color("6aa86f"),
				"exit": home,
				"spikes": floor_strips + [StitchfallLevels.ceiling_needles(660, 1150)],
				"fray_ledges": [{"rect": Rect2(ISLAND_X, StitchfallLevels.CEILING_Y + 28.0, ISLAND_END - ISLAND_X, 28.0), "delay": 0.6}],
				"pins": [Vector2(1440, PIN_FLOOR)],
				"shards": [Vector2(745, 715), Vector2(1080, 440)],
			}, true)
		2:
			# The far floor strip is wider than any calm jump.
			room.merge({
				"name": "Second Wind",
				"par": 18.0,
				"accent": Color("c9a24a"),
				"exit": home,
				"spikes": [StitchfallLevels.floor_needles(660, ISLAND_X), StitchfallLevels.floor_needles(ISLAND_END, 1270)] + ceiling_strips,
				"shards": [Vector2(745, 715), Vector2(1080, 425)],
			}, true)
		3:
			# No floor to cross by, and a button only a long leap off the left wall reaches. Turned on its side,
			# the room's gusts push against its pull and hold the runner up.
			room.merge({
				"name": "Featherweight",
				"par": 18.0,
				"accent": Color("8a6fc4"),
				"exit": home,
				"spikes": [StitchfallLevels.floor_needles(660, 1560), StitchfallLevels.ceiling_needles(560, 740), StitchfallLevels.ceiling_needles(ISLAND_END, 1150)],
				"shards": [Vector2(700, 569), Vector2(1300, 340)],
			}, true)
		4:
			# Both islands are pinned patches and the far floor strip needs a gust, so the way out lands on the
			# patch just before a gust and leaves on it, and the way home crosses between gusts.
			room.merge({
				"name": "Cloudburst",
				"par": 18.0,
				"accent": Color("c46f6f"),
				"exit": home,
				"spikes": [StitchfallLevels.floor_needles(660, 1270), StitchfallLevels.ceiling_needles(660, 1150)],
				"fray_ledges": [
					{"rect": Rect2(ISLAND_X, 790, ISLAND_END - ISLAND_X, 28.0), "delay": 0.6},
					{"rect": Rect2(ISLAND_X, StitchfallLevels.CEILING_Y + 28.0, ISLAND_END - ISLAND_X, 28.0), "delay": 0.6},
				],
				"flowers": [{"pos": Vector2(1340, StitchfallLevels.STAND_FLOOR - 10.0), "gravity": Vector2.DOWN}],
				"shards": [Vector2(745, 700), Vector2(1150, 640), Vector2(1080, 440)],
			}, true)
	return room
