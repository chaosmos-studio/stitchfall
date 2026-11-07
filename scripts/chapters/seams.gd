extends RefCounted

# Lit Seams: a lit seam is solid only while gravity points sideways, after an odd number of turns, and a
# ghost while it points down or up. So a seam is a floor you can only land on by falling sideways, and
# nothing at all to anything falling up or down.

const NAME: String = "Lit Seams"
const LINE: String = "Some floors only hold you sideways."
# Every room opens the same way: climb the left wall, flip to fall right onto the seam, walk up it for the
# button. The naive runs trust the shelf, trust the wall seam, stop at the zipper, and turn up into the roof.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,184:shift,208:+move_right,238:+jump,258:-jump"},
	{
		"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,180:+move_left,232:-move_left,290:shift",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,184:shift,208:+move_right,238:+jump,258:-jump",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,180:+move_left,232:-move_left,256:shift,257:+move_right",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,180:+move_left,232:-move_left,290:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,180:+move_left,232:-move_left,256:shift,257:+move_right,288:-move_right,290:shift,310:+move_left",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,180:+move_left,232:-move_left,256:shift,257:+move_right",
		"caught": "stuck",
	},
	{
		"route": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,180:+move_left,232:-move_left,256:shift,257:+move_right,300:-move_right,301:shift,320:+move_left,350:-move_left,351:+jump,370:shift,371:-jump,400:+move_right",
		"naive": "0:+move_right,20:-move_right,21:shift,45:+move_left,70:-move_left,85:shift,100:shift,152:+move_right,176:-move_right,180:+move_left,232:-move_left,256:shift,257:+move_right,288:-move_right,290:shift,310:+move_left,365:-move_left,370:shift",
		"caught": "hit",
	},
]
# The seam hanging over the middle of the pit, the shelf under it, and the wall seam that later closes off
# the zipper's corner, wide enough that its button can only be touched from inside it.
const SEAM: Rect2 = Rect2(946, 340, 28, 280)
const SHELF: Rect2 = Rect2(840, 700, 240, 28)
const WALL_SEAM: Rect2 = Rect2(1220, 280, 80, 580)
# Where a zipper sewn on the back of the wall seam hangs, its frame touching the seam.
const BACK_X: float = 1358.0


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	room.merge({"backdrop": 3}, true)
	var pit: Dictionary = StitchfallLevels.floor_needles(600, 1340)
	var roof: Dictionary = StitchfallLevels.ceiling_needles(600, 1340)
	# Once the wall seam stands at its end, the pit stops at the seam.
	var walled_pit: Dictionary = StitchfallLevels.floor_needles(600, WALL_SEAM.position.x)
	match index:
		0:
			# The shelf under the seam is sewn on, so the turn down from the seam lands on it.
			room.merge({
				"name": "Lights On",
				"par": 8.0,
				"accent": Color("4fa7a0"),
				"spikes": [pit, roof],
				"walls": StitchfallLevels.screen_frame() + [SHELF],
				"phase_walls": [SEAM],
				"shards": [Vector2(399, 640), Vector2(907, 440)],
			}, true)
		1:
			# The shelf is a seam now: lit while you stand sideways on the seam above it, gone the moment you
			# turn down onto it. The way on is off the seam's foot and sideways over the shelf.
			room.merge({
				"name": "Lights Out",
				"par": 8.0,
				"accent": Color("5b86c9"),
				"spikes": [pit, roof],
				"phase_walls": [SEAM, SHELF],
				"shards": [Vector2(907, 440), Vector2(1100, 650)],
			}, true)
		2:
			# A wall seam from roof to floor catches the sideways fall over the pit. Turned down just before it,
			# the runner is upright as it reaches the seam and slides through, past the button sewn inside it.
			room.merge({
				"name": "See Through",
				"par": 8.0,
				"accent": Color("c98a3e"),
				"spikes": [walled_pit, roof],
				"phase_walls": [SEAM, SHELF, WALL_SEAM],
				"shards": [Vector2(907, 440), Vector2(1260, 680)],
			}, true)
		3:
			# The zipper waits at the wall seam's foot and runs up its back, where only a sideways runner can stand.
			room.merge({
				"name": "Round the Back",
				"par": 10.0,
				"accent": Color("a35d8f"),
				"spikes": [walled_pit, roof],
				"phase_walls": [SEAM, SHELF, WALL_SEAM],
				"exit": Vector2(BACK_X, StitchfallLevels.ZIP_FLOOR.y),
				"exit_flee": [Vector2(BACK_X, 480)],
				"flee_radius": 200.0,
				"shards": [Vector2(907, 440), Vector2(1260, 680)],
			}, true)
		4:
			# Everything at once, and the zipper starts on the seam's back and runs to the roof's corner. Turning
			# up off the seam lands in the roof's needles, so jump clear of them first and turn in the air.
			room.merge({
				"name": "Seam Ripper",
				"par": 11.0,
				"accent": Color("b5534a"),
				"spikes": [walled_pit, roof],
				"phase_walls": [SEAM, SHELF, WALL_SEAM],
				"exit": Vector2(BACK_X, 480),
				"exit_flee": [StitchfallLevels.ZIP_CEILING],
				"flee_radius": 200.0,
				"flowers": [{"pos": Vector2(1440, 806), "gravity": Vector2.DOWN}],
				"shards": [Vector2(907, 440), Vector2(1260, 680)],
			}, true)
	return room
