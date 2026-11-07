extends RefCounted

# The Weighted Patch: the zipper opens only once the patch has sat on its pad. The patch falls the way gravity
# points, so it is sent home by turning the room: it waits in the pit against a short lit seam, and a turn up lifts
# it to the pad on the roof, slowly, while the runner waits pinned under the sewn shelf on the left wall.

const NAME: String = "The Weighted Patch"
const LINE: String = "Some doors need a little weight."
# Every room ends the same way: fly right from under the shelf onto the seam, walk up it for the button, step
# off its top to the right wall and turn down. The naive runs send the patch before standing on it, turn off it
# into the wall's needles, fall the whole wall onto the door moths, and land beside the wall moth.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,100:-move_left,101:shift,185:shift,238:+move_right,262:-move_right,318:shift"},
	{
		"route": "0:+move_right,25:+jump,45:-jump,50:-move_right,66:shift,112:+move_left,156:-move_left,157:shift,240:shift,295:+move_right,323:-move_right,377:shift",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,100:-move_left,101:shift,185:shift,238:+move_right,262:-move_right,318:shift",
		"caught": "stuck",
	},
	{
		"route": "0:+move_right,25:+jump,45:-jump,50:-move_right,70:+jump,88:shift,89:-jump,130:+move_left,150:-move_left,152:shift,235:shift,290:+move_right,318:-move_right,372:shift",
		"naive": "0:+move_right,25:+jump,45:-jump,50:-move_right,66:shift,112:+move_left,156:-move_left,157:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,25:+jump,45:-jump,50:-move_right,70:+jump,88:shift,89:-jump,130:+move_left,150:-move_left,152:shift,235:shift,290:+move_right,318:-move_right,372:+move_left,402:-move_left,406:shift",
		"naive": "0:+move_right,25:+jump,45:-jump,50:-move_right,70:+jump,88:shift,89:-jump,130:+move_left,150:-move_left,152:shift,235:shift,290:+move_right,318:-move_right,372:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,25:+jump,45:-jump,50:-move_right,70:+jump,88:shift,89:-jump,118:shift,202:shift,256:+move_right,284:-move_right,340:+move_left,380:-move_left,384:shift",
		"naive": "0:+move_right,25:+jump,45:-jump,50:-move_right,70:+jump,88:shift,89:-jump,130:+move_left,150:-move_left",
		"caught": "hit",
	},
]
const PATCH_X: float = 780.0
# The post holds the patch against the first turn, which points left, and lets it go on the turn up. It is short
# enough for a runner standing on the patch to fly over it.
const POST: Rect2 = Rect2(718, 790, 28, 70)
const SHELF: Rect2 = Rect2(360, 492, 280, 28)
const SEAM: Rect2 = Rect2(1000, 440, 28, 200)
# The Needle Moths' door pair: one meets a runner falling onto the zipper, one a runner walking up to it.
const DOOR_MOTHS: Array[Dictionary] = [
	{"from": Vector2(1470, 715), "to": Vector2(1530, 715), "period": 1.0, "offset": PI},
	{"from": Vector2(1470, 776), "to": Vector2(1530, 776), "period": 1.0, "offset": 0.0},
]
# Hovers on the left wall just under the shelf, where the turn off the patch lands, and just clear of a runner
# pinned under the shelf.
const WALL_MOTH: Dictionary = {"from": Vector2(399, 640), "to": Vector2(399, 680), "period": 1.0, "offset": 0.0}


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	var pit: Dictionary = StitchfallLevels.floor_needles(600, 1200)
	var wall_needles: Dictionary = {"rect": Rect2(StitchfallLevels.LEFT_X, 700, 28, 100), "dir": Vector2.RIGHT}
	room.merge({
		"backdrop": 1,
		"spikes": [pit],
		"walls": StitchfallLevels.screen_frame() + [SHELF],
		"crate": Vector2(PATCH_X, 826),
		"pad": Vector2(PATCH_X, 307),
		"phase_walls": [POST, SEAM],
	}, true)
	match index:
		0:
			# The patch takes over a second to rise, so the turn on is only worth making once it is home.
			room.merge({
				"name": "Weighted",
				"par": 10.0,
				"accent": Color("b0845a"),
				"shards": [Vector2(399, 650), Vector2(961, 470)],
			}, true)
		1:
			# The button over the pit can only be reached standing on the patch. Turn first and it has gone.
			room.merge({
				"name": "Stepping Stone",
				"par": 11.0,
				"accent": Color("6f9a5b"),
				"shards": [Vector2(PATCH_X, 690), Vector2(961, 470)],
			}, true)
		2:
			# A turn off the patch throws the runner left at the patch's height, onto the wall's needles. Jump
			# first and turn at the top of the jump.
			room.merge({
				"name": "Pushover",
				"par": 11.0,
				"accent": Color("c0603f"),
				"spikes": [pit, wall_needles],
				"shards": [Vector2(PATCH_X, 690), Vector2(961, 470)],
			}, true)
		3:
			# The door moths wake before a fall from the top of the wall arrives. Walk down the wall first.
			room.merge({
				"name": "Hold the Door",
				"par": 11.0,
				"accent": Color("4f7fa8"),
				"spikes": [pit, wall_needles],
				"sentries": DOOR_MOTHS,
				"shards": [Vector2(PATCH_X, 690), Vector2(961, 470)],
			}, true)
		4:
			# Everything at once, and the wall moth waits where the turn off the patch lands. Turn up in the air
			# before landing: the one turn stills the moth, pins the runner under the shelf and sends the patch.
			room.merge({
				"name": "Dead Weight",
				"par": 11.0,
				"accent": Color("8a5a9e"),
				"spikes": [pit, wall_needles],
				"sentries": DOOR_MOTHS + [WALL_MOTH],
				"flowers": [{"pos": Vector2(440, 574), "gravity": Vector2.UP}],
				"shards": [Vector2(PATCH_X, 690), Vector2(961, 470)],
			}, true)
	return room
