extends RefCounted

# Unpinned: the same needle pit five times, crossed on patches that look sewn down but are only pinned, and
# drop a moment after you stand on them.

const NAME: String = "Unpinned"
const LINE: String = "Not everything sewn is sewn."
# Patches and steps over the needle pit sit low enough to jump onto from the floor.
const PATCH_Y: float = 780.0
# The naive runs stop on a patch, trust the last step, or walk back the way they came.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,26:+jump,46:-jump,110:+jump,130:-jump", "naive": "0:+move_right,26:+jump,46:-jump,75:-move_right", "caught": "hit"},
	{"route": "0:+move_right,26:+jump,40:-jump,78:+jump,98:-jump", "naive": "0:+move_right,26:+jump,40:-jump,85:-move_right", "caught": "hit"},
	{
		"route": "0:+move_right,26:+jump,40:-jump,74:+jump,90:-jump,120:+jump,140:-jump",
		"naive": "0:+move_right,26:+jump,40:-jump,74:+jump,90:-jump,104:+jump,110:-jump",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,20:+jump,40:-jump,100:+jump,120:-jump,165:-move_right,166:shift,181:shift,240:+move_left,400:-move_left,401:shift,416:shift,470:+move_left",
		"naive": "0:+move_right,20:+jump,40:-jump,100:+jump,120:-jump,165:-move_right,170:+move_left,200:+jump,220:-jump",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,26:+jump,40:-jump,62:+jump,80:-jump,100:-move_right,125:shift,140:shift,210:shift,225:shift,280:+move_right,284:+jump,306:-jump",
		"naive": "0:+move_right,26:+jump,40:-jump,62:+jump,80:-jump",
		"caught": "hit",
	},
]


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	room.merge({"backdrop": 2}, true)
	var pit: Dictionary = StitchfallLevels.floor_needles(640, 1260)
	match index:
		0:
			room.merge({
				"name": "Tacked On",
				"par": 5.0,
				"accent": Color("5f9b74"),
				"spikes": [pit],
				"fray_ledges": [{"rect": Rect2(780, PATCH_Y, 320, 28), "delay": 0.9}],
				"shards": [Vector2(560, StitchfallLevels.STAND_FLOOR), Vector2(940, 700)],
			}, true)
		1:
			# A row of short patches, each holding only a moment: at a run each one lasts until the next takes
			# your weight, and stopping anywhere drops you in.
			room.merge({
				"name": "Keep Moving",
				"par": 5.0,
				"accent": Color("4f8f8a"),
				"spikes": [pit],
				"fray_ledges": [
					{"rect": Rect2(700, PATCH_Y, 140, 28), "delay": 0.45},
					{"rect": Rect2(840, PATCH_Y, 140, 28), "delay": 0.45},
					{"rect": Rect2(980, PATCH_Y, 140, 28), "delay": 0.45},
					{"rect": Rect2(1120, PATCH_Y, 140, 28), "delay": 0.45},
				],
				"shards": [Vector2(560, StitchfallLevels.STAND_FLOOR), Vector2(1005, 640)],
			}, true)
		2:
			# Two steps are sewn on. The last only looks it, and goes the moment it is touched.
			room.merge({
				"name": "Last Step",
				"par": 5.0,
				"accent": Color("8aa04a"),
				"spikes": [pit],
				"walls": StitchfallLevels.screen_frame() + [Rect2(700, PATCH_Y, 140, 28), Rect2(910, PATCH_Y, 140, 28)],
				"fray_ledges": [{"rect": Rect2(1120, PATCH_Y, 140, 28), "delay": 0.05}],
				"shards": [Vector2(560, StitchfallLevels.STAND_FLOOR), Vector2(980, 700)],
			}, true)
		3:
			# The only bridge drops once it is crossed, and the zipper is back where you started.
			room.merge({
				"name": "No Way Back",
				"par": 13.0,
				"accent": Color("6a7fb0"),
				"spikes": [pit],
				"start": Vector2(470, StitchfallLevels.STAND_FLOOR),
				"exit": Vector2(420, StitchfallLevels.ZIP_FLOOR.y),
				"fray_ledges": [{"rect": Rect2(780, PATCH_Y, 320, 28), "delay": 0.9}],
				"shards": [Vector2(1430, StitchfallLevels.STAND_FLOOR)],
			}, true)
		4:
			# A flower on a sewn island in the middle, a button above it between two needle strips, and a far
			# patch that drops the moment it is touched.
			room.merge({
				"name": "Hold On",
				"par": 10.0,
				"accent": Color("a8604a"),
				"spikes": [pit, StitchfallLevels.ceiling_needles(680, 860), StitchfallLevels.ceiling_needles(1100, 1320)],
				"walls": StitchfallLevels.screen_frame() + [Rect2(900, 740, 160, 28)],
				"fray_ledges": [
					{"rect": Rect2(720, PATCH_Y, 140, 28), "delay": 0.35},
					{"rect": Rect2(1100, PATCH_Y, 160, 28), "delay": 0.05},
				],
				"flowers": [{"pos": Vector2(950, 686), "gravity": Vector2.DOWN}],
				"shards": [Vector2(560, StitchfallLevels.STAND_FLOOR), Vector2(940, StitchfallLevels.STAND_CEILING + 6.0)],
			}, true)
	return room
