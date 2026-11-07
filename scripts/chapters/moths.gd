extends RefCounted

# Needle Moths: moths fly their stitched tracks, and every turn stills them all for about half a second, harmless.
# A turn is also a fall, so the turn that stills a moth throws the runner along the next surface: up the left
# wall, right along the roof, down the right wall. The way round the room is a lap of those falls.

const NAME: String = "Needle Moths"
const LINE: String = "Every turn holds its breath."
# Every room opens the same way: climb into the wall moth and turn up past it, then cross the roof. The naive
# runs ride the roof into the corner, turn when the near moth comes close, and reach the zipper while the door
# moths are awake.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,163:shift,164:-move_right,225:shift"},
	{
		"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,163:shift,164:-move_right,209:shift,258:+move_right",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,163:shift,164:-move_right,225:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,148:-move_right,210:+move_right,240:shift,241:-move_right,278:shift,328:+move_right",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,148:-move_right,174:shift,228:shift,270:+move_right",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,148:-move_right,210:+move_right,240:shift,241:-move_right,296:+move_left,340:-move_left,344:shift",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,148:-move_right,210:+move_right,240:shift,241:-move_right,278:shift,328:+move_right",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,148:-move_right,210:+move_right,240:shift,241:-move_right,285:+move_left,329:-move_left,360:shift",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,72:shift,73:-move_left,108:+move_right,148:-move_right,210:+move_right,240:shift,241:-move_right,278:shift,328:+move_right",
		"caught": "hit",
	},
]
const WALL_MOTH: Dictionary = {"from": Vector2(399, 380), "to": Vector2(399, 640), "period": 2.4, "offset": 0.0}
const ROOF_MOTH: Dictionary = {"from": Vector2(720, 330), "to": Vector2(1180, 330), "period": 3.0, "offset": 0.0}
# Two roof moths flying opposite ways, so they only bunch up once a beat.
const NEAR_MOTH: Dictionary = {"from": Vector2(720, 330), "to": Vector2(940, 330), "period": 2.4, "offset": 0.0}
const FAR_MOTH: Dictionary = {"from": Vector2(1000, 330), "to": Vector2(1220, 330), "period": 2.4, "offset": PI}
const CORNER_MOTH: Dictionary = {"from": Vector2(1505, 345), "to": Vector2(1505, 365), "period": 1.2, "offset": 0.0}
# Two moths on the zipper: the low one meets a runner walking up to it, the high one meets a runner falling onto
# it while they are still outside the zipper's reach.
const DOOR_MOTHS: Array[Dictionary] = [
	{"from": Vector2(1470, 715), "to": Vector2(1530, 715), "period": 1.0, "offset": PI},
	{"from": Vector2(1470, 776), "to": Vector2(1530, 776), "period": 1.0, "offset": 0.0},
]
const SEAM: Rect2 = Rect2(1380, 280, 28, 240)


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	room.merge({
		"backdrop": 0,
		"spikes": [StitchfallLevels.floor_needles(600, 1200)],
		"shards": [Vector2(399, 720), Vector2(1300, StitchfallLevels.STAND_CEILING)],
	}, true)
	match index:
		0:
			room.merge({
				"name": "Hush",
				"par": 7.0,
				"accent": Color("7c8bd6"),
				"sentries": [WALL_MOTH, ROOF_MOTH],
			}, true)
		1:
			# The roof ride ends in the corner moth, long after the turn that stilled it. Turn down again in
			# the air once past the pit: the turn stills it a second time and drops the runner clear.
			room.merge({
				"name": "Cornered",
				"par": 8.0,
				"accent": Color("d0763c"),
				"sentries": [WALL_MOTH, ROOF_MOTH, CORNER_MOTH],
			}, true)
		2:
			# One turn stills both roof moths, but only passes both when they have bunched up.
			room.merge({
				"name": "Out of Step",
				"par": 10.0,
				"accent": Color("c2a83e"),
				"sentries": [WALL_MOTH, NEAR_MOTH, FAR_MOTH, CORNER_MOTH],
			}, true)
		3:
			# The door moths wake long before a fall from the roof arrives. Ride the roof to the right wall,
			# walk down it sideways, and turn down only once the zipper is a short fall away.
			room.merge({
				"name": "Doorman",
				"par": 10.0,
				"accent": Color("5f9a8c"),
				"sentries": [WALL_MOTH, NEAR_MOTH, FAR_MOTH] + DOOR_MOTHS,
			}, true)
		4:
			# Everything at once. The corner moth closes the right wall's top, so a lit seam catches the roof
			# ride short of it, and the way down is off the seam's foot onto the wall below the moth.
			room.merge({
				"name": "Flutter By",
				"par": 10.0,
				"accent": Color("9b4f7a"),
				"sentries": [WALL_MOTH, NEAR_MOTH, FAR_MOTH, CORNER_MOTH] + DOOR_MOTHS,
				"phase_walls": [SEAM],
			}, true)
	return room
