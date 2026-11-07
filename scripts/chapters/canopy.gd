extends RefCounted

# Green Canopy: a column of rising air over a needle pit, the only way across and back. Inside it the runner
# floats up whichever way the room is turned. Turned over inside it, the runner is pressed to the ceiling twice
# as hard, too hard to jump. Turned back down, the runner floats, but a pin, which the canopy does not lift,
# drops away.

const NAME: String = "Green Canopy"
const LINE: String = "Up is where the leaves go."
# The naive runs ride the canopy the way the room before taught: up to the ceiling and along it.
const ROUTES: Array[Dictionary] = [
	{"route": "0:+move_right,52:+jump,60:-move_right,90:-jump,100:+move_right,226:-move_right,227:+move_left,248:+jump,268:-jump,288:+jump,312:-jump"},
	{
		"route": "0:+move_right,52:+jump,60:-move_right,90:-jump,110:shift,125:shift,126:+move_right,203:+jump,223:-jump,262:-move_right,263:+move_left,300:+jump,320:-jump,421:shift,436:shift",
		"naive": "0:+move_right,52:+jump,60:-move_right,90:-jump,100:+move_right,226:-move_right,227:+move_left,248:+jump,268:-jump,288:+jump,312:-jump",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,52:+jump,90:-jump,124:shift,139:shift,186:-move_right,187:shift,202:shift,240:+move_left,258:+jump,278:-jump,298:+jump,322:-jump",
		"naive": "0:+move_right,52:+jump,60:-move_right,90:-jump,110:shift,125:shift,126:+move_right,203:+jump,223:-jump,262:-move_right,263:+move_left,300:+jump,320:-jump,421:shift,436:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,52:+jump,60:-move_right,90:-jump,110:shift,125:shift,126:+move_right,155:-move_right,165:shift,180:shift,185:+move_right,214:shift,229:shift,290:-move_right,291:shift,306:shift,307:+move_left,368:+jump,392:-jump",
		"naive": "0:+move_right,52:+jump,60:-move_right,90:-jump,110:shift,125:shift,126:+move_right,203:+jump,223:-jump,262:-move_right,263:+move_left,300:+jump,320:-jump,421:shift,436:shift",
		"caught": "hit",
	},
	{
		"route": "0:+move_right,52:+jump,87:-move_right,90:-jump,120:shift,135:shift,150:shift,165:shift,170:+move_right,199:shift,214:shift,275:-move_right,276:shift,291:shift,292:+move_left,353:+jump,377:-jump",
		"naive": "0:+move_right,52:+jump,60:-move_right,90:-jump,110:shift,125:shift,126:+move_right,155:-move_right,165:shift,180:shift,185:+move_right,214:shift,229:shift,290:-move_right,291:shift,306:shift,307:+move_left,368:+jump,392:-jump",
		"caught": "hit",
	},
]
const DRAFT: Rect2 = Rect2(800, 280, 300, 580)
const PIN_FLOOR: float = StitchfallLevels.FLOOR_Y - 30.0
# Every room ends back home: the zipper waits by the start, which moves aside for it.
const HOME_ZIP: Vector2 = Vector2(420, 781)
const HOME_START: Vector2 = Vector2(470, 821)
const CEILING_BUTTON: float = StitchfallLevels.STAND_CEILING + 6.0


static func build(index: int) -> Dictionary:
	var room: Dictionary = StitchfallLevels.screen_base()
	room.merge({"backdrop": 6, "environment": "forest", "environment_zone": DRAFT, "start": HOME_START, "exit": HOME_ZIP}, true)
	var pit: Dictionary = StitchfallLevels.floor_needles(830, 1070)
	match index:
		0:
			# Ridden slowly the canopy delivers the runner to the ceiling. Jumped into at a run, it carries
			# the runner over the pit in an arch.
			room.merge({
				"name": "Updraft",
				"par": 11.0,
				"accent": Color("5f9b5a"),
				"spikes": [pit],
				"pins": [Vector2(1330, PIN_FLOOR)],
				"shards": [Vector2(950, CEILING_BUTTON), Vector2(1490, 790)],
			}, true)
		1:
			# The far floor is needled, so the way over and back is along the ceiling: turned over inside the
			# canopy, the runner stays pressed to the ceiling and walks it.
			room.merge({
				"name": "Treetops",
				"par": 13.0,
				"accent": Color("4f8a50"),
				"spikes": [pit, StitchfallLevels.floor_needles(1140, 1560)],
				"pins": [Vector2(1330, PIN_FLOOR)],
				"shards": [Vector2(950, CEILING_BUTTON), Vector2(1470, CEILING_BUTTON)],
			}, true)
		2:
			# The canopy now delivers the runner into needles. Crossed at a run, it lifts only part way.
			room.merge({
				"name": "Thorns",
				"par": 12.0,
				"accent": Color("6a8f3c"),
				"spikes": [pit, StitchfallLevels.ceiling_needles(830, 1070)],
				"pins": [Vector2(1330, PIN_FLOOR)],
				"shards": [Vector2(950, 600), Vector2(1400, CEILING_BUTTON)],
			}, true)
		3:
			# Turning over inside the canopy brings the pin up beside the runner, who is pressed to the ceiling
			# too hard to jump it. Turning back down drops the pin and leaves the runner floating past.
			room.merge({
				"name": "Pin Drop",
				"par": 13.0,
				"accent": Color("3f7f5a"),
				"spikes": [pit],
				"pins": [Vector2(1105, PIN_FLOOR)],
				"shards": [Vector2(950, CEILING_BUTTON), Vector2(1400, CEILING_BUTTON)],
			}, true)
		4:
			# Pin Drop with needles at the near end of the canopy's ceiling, so the ride up starts further in,
			# between the needles and where the pin comes up.
			room.merge({
				"name": "Green Canopy",
				"par": 13.0,
				"accent": Color("7a9a4a"),
				"spikes": [pit, StitchfallLevels.ceiling_needles(830, 880)],
				"pins": [Vector2(1105, PIN_FLOOR)],
				"shards": [Vector2(1000, CEILING_BUTTON), Vector2(1400, CEILING_BUTTON)],
			}, true)
	return room
