class_name StitchfallWorldView
extends Node2D

const LINEN: Texture2D = preload("res://assets/art/linen_landscape.png")
const FELT: Texture2D = preload("res://assets/art/felt_tile.png")
const WATER_CLOTH: Texture2D = preload("res://assets/art/cloth_water.webp")
const DUNE_CLOTH: Texture2D = preload("res://assets/art/cloth_dunes.webp")
const FOREST_CLOTH: Texture2D = preload("res://assets/art/cloth_forest.webp")
const NIGHT_CLOTH: Texture2D = preload("res://assets/art/cloth_night.webp")
const RAIN_CLOTH: Texture2D = preload("res://assets/art/cloth_rain.webp")
const FROST_CLOTH: Texture2D = preload("res://assets/art/cloth_frost.webp")
const CHECKPOINT: Texture2D = preload("res://assets/art/sewn_checkpoint.png")
const NEEDLES_RAISED: Texture2D = preload("res://assets/art/props/needle_strip_raised.png")
const NEEDLES_FLAT: Texture2D = preload("res://assets/art/props/needle_strip_flat.png")
const ZIPPER_TRACK: Texture2D = preload("res://assets/art/props/zipper_track.png")
const NEEDLE_SCALE: float = 0.3
const NEEDLE_BAND_TOP: float = 112.0
const NEEDLE_BAND_BOTTOM: float = 152.0
const NEEDLE_SINK: float = 4.0
const NEEDLE_OUTLINE: float = 3.0
const TRACK_SCALE: float = 0.3
const TRACK_OVERHANG: float = 24.0
const FLOWER_POP_TIME: float = 0.55
const CONFETTI_COUNT: int = 70
const CONFETTI_LIFE: float = 1.8
const CONFETTI_FALL: float = 900.0
const INK: Color = Color("493a37")
const THREAD: Color = Color("f9e9ca")
const RUST: Color = Color("b45d4c")
const TEAL: Color = Color("618d86")

var level: Dictionary = {}
var phase: int = 0
var collected: Array[bool] = []
var pad_armed: bool = false
var door_open: bool = false
var time: float = 0.0
var gravity_direction: Vector2 = Vector2.DOWN
var shift_origin: Vector2 = Vector2.ZERO
var shift_age: float = 1.0
var door_progress: float = 0.0
var spark_bursts: Array[Dictionary] = []
var bloom_bursts: Array[Dictionary] = []
var exit_position: Vector2 = Vector2.ZERO
var popup_raised: Array[bool] = []
# The runner's rain clock, so the drawn rain leans with the gust the runner feels.
var gust_clock: float = 0.0
# Drawn positions, eased toward exit_position and the raised state so a move reads as motion.
var exit_drawn: Vector2 = Vector2.ZERO
var popup_rise: Array[float] = []
var flower_lit: Array[bool] = []
# Seconds since each flower bloomed, while its pop still plays.
var flower_bloom: Dictionary[int, float] = {}
# Thread snips and petals thrown up when the zipper takes the runner.
var confetti: Array[Dictionary] = []
# The wardrobe's button colour and room fabric. A fabric of -1 keeps each room's own cloth.
var button_colour: Color = Color("e4c77f")
var fabric_backdrop: int = -1


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _process(delta: float) -> void:
	time += delta
	shift_age += delta
	door_progress = move_toward(door_progress, 1.0 if door_open else 0.0, delta * 3.0)
	if exit_drawn == Vector2.ZERO or exit_drawn.distance_to(exit_position) > 900.0:
		exit_drawn = exit_position
	exit_drawn = exit_drawn.move_toward(exit_position, delta * 2200.0)
	for index: int in flower_bloom.keys():
		flower_bloom[index] += delta
		if flower_bloom[index] > FLOWER_POP_TIME:
			flower_bloom.erase(index)
	for bit: Dictionary in confetti:
		var velocity: Vector2 = bit["velocity"]
		bit["velocity"] = velocity * (1.0 - delta * 1.4) + gravity_direction * CONFETTI_FALL * delta
		bit["pos"] += velocity * delta
		bit["spin"] += float(bit["turn"]) * delta
		bit["age"] += delta
	confetti = confetti.filter(func(bit: Dictionary) -> bool: return float(bit["age"]) < CONFETTI_LIFE)
	popup_rise.resize(popup_raised.size())
	for index: int in range(popup_raised.size()):
		popup_rise[index] = move_toward(popup_rise[index], 1.0 if popup_raised[index] else 0.0, delta * 9.0)
	for index: int in range(spark_bursts.size() - 1, -1, -1):
		spark_bursts[index]["age"] += delta
		if spark_bursts[index]["age"] > 0.55:
			spark_bursts.remove_at(index)
	for index: int in range(bloom_bursts.size() - 1, -1, -1):
		bloom_bursts[index]["age"] += delta
		if bloom_bursts[index]["age"] > 0.55:
			bloom_bursts.remove_at(index)
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(_backdrop_texture(), Rect2(-330, -180, 2580, 1440), false)
	if level.is_empty():
		return
	_draw_chamber()
	_draw_environment()
	for wall: Rect2 in level["walls"]:
		_draw_wall(wall)
	for bridge: Rect2 in level["phase_walls"]:
		_draw_bridge(bridge)
	_draw_sentry_tracks()
	for spike: Dictionary in level["spikes"]:
		_draw_needles(spike["rect"], spike["dir"], 1.0)
	for index: int in range(level["popups"].size()):
		var popup: Dictionary = level["popups"][index]
		_draw_needles(popup["rect"], popup["dir"], popup_rise[index] if index < popup_rise.size() else 0.0)
	_draw_exit_track()
	for index: int in range(collected.size()):
		if not collected[index]:
			_draw_shard(level["shards"][index], index)
	if level["pad"] != Vector2.ZERO:
		_draw_pad(level["pad"])
	for index: int in range(level["flowers"].size()):
		_draw_flower(index)
	_draw_door(exit_drawn)
	_draw_loose_threads()
	_draw_spark_bursts()
	_draw_bloom_bursts()
	_draw_confetti()
	if shift_age < 0.68:
		_draw_shift_seam()


# A wardrobe fabric dresses the plain linen rooms. Rooms set in a world keep that world's cloth.
func _backdrop() -> int:
	var backdrop: int = int(level.get("backdrop", 0))
	return fabric_backdrop if fabric_backdrop >= 0 and backdrop < 4 else backdrop


func _backdrop_texture() -> Texture2D:
	match _backdrop():
		4:
			return WATER_CLOTH
		5:
			return DUNE_CLOTH
		6:
			return FOREST_CLOTH
		7:
			return NIGHT_CLOTH
		8:
			return RAIN_CLOTH
		9:
			return FROST_CLOTH
	return LINEN


func _cloth_color() -> Color:
	match _backdrop():
		4:
			return Color("85aeb0")
		5:
			return Color("c4a16c")
		6:
			return Color("809b73")
		7:
			return Color("8185a4")
		8:
			return Color("7fa8a1")
		9:
			return Color("aabec9")
	return Color("a1a88b")


func _draw_chamber() -> void:
	var chamber: Rect2 = level["chamber"]
	draw_rect(chamber.grow(12.0), Color("644f43", 0.15))
	draw_rect(chamber, Color("f7efdc", 0.2))


func _draw_environment() -> void:
	var kind: String = level.get("environment", "")
	var zone: Rect2 = level.get("environment_zone", Rect2())
	if not zone.has_area():
		return
	match kind:
		"water":
			draw_rect(zone, Color("3d7c90", 0.26))
			# A pool hanging from the ceiling shows its surface along its bottom edge, where it can be seen.
			var chamber: Rect2 = level["chamber"]
			var surface: float = zone.end.y if zone.end.y < chamber.end.y - 40.0 else zone.position.y
			for x: int in range(int(zone.position.x), int(zone.end.x), 30):
				var wave: float = sin(float(x) * 0.025 + time * 2.3) * 4.0
				draw_line(Vector2(x, surface + wave), Vector2(x + 15, surface + wave - 2), Color("f3f2d9", 0.85), 3.0, true)
			for index: int in range(11):
				var pos: Vector2 = Vector2(zone.position.x + fposmod(float(index * 93), zone.size.x), zone.end.y - fposmod(float(index * 113) + time * 15.0, zone.size.y))
				draw_arc(pos, 5.0 + float(index % 3) * 2.0, 0.0, TAU, 20, Color("d9e4cf", 0.55), 2.0, true)
		"dunes":
			draw_rect(zone, Color("e2b47b", 0.09))
			_draw_field_edge(zone, Color("b88961", 0.65))
			for index: int in range(23):
				var pos: Vector2 = Vector2(zone.position.x + fposmod(float(index * 101) + time * 35.0, zone.size.x), zone.position.y + fposmod(float(index * 127), zone.size.y))
				draw_line(pos, pos + Vector2(26, -4), Color("9e764d", 0.55), 2.0, true)
		"forest":
			draw_rect(zone, Color("829d72", 0.13))
			_draw_field_edge(zone, Color("708967", 0.7))
			for column: int in range(5):
				var x: float = zone.position.x + 65.0 + float(column) * (zone.size.x - 130.0) / 4.0
				var sway: float = sin(time * 1.1 + float(column)) * 11.0
				draw_line(Vector2(x, zone.end.y - 20.0), Vector2(x + sway, zone.position.y + 30.0), Color("e9e5b7", 0.24), 5.0, true)
			for index: int in range(16):
				var pos: Vector2 = Vector2(zone.position.x + fposmod(float(index * 79) + sin(time + index) * 9.0, zone.size.x), zone.end.y - fposmod(float(index * 109) + time * 15.0, zone.size.y))
				draw_circle(pos, 3.0 + float(index % 3), Color("e9dba8", 0.8))
				draw_line(pos + Vector2(-4, 8), pos + Vector2(2, -6), Color("748e69", 0.7), 2.0, true)
		"space":
			for index: int in range(18):
				var pos: Vector2 = Vector2(zone.position.x + fposmod(float(index * 157), zone.size.x), zone.position.y + fposmod(float(index * 97), zone.size.y))
				draw_line(pos + Vector2(-5, -5), pos + Vector2(5, 5), Color("e4d5ad", 0.7), 2.0, true)
				draw_line(pos + Vector2(5, -5), pos + Vector2(-5, 5), Color("e4d5ad", 0.7), 2.0, true)
		"rain":
			for index: int in range(38):
				var x: float = zone.position.x + fposmod(float(index * 61) + time * 105.0, zone.size.x)
				var y: float = zone.position.y + fposmod(float(index * 117) + time * 240.0, zone.size.y)
				var slant: float = (900.0 * sin(gust_clock * 1.7) + 360.0) * 0.02
				draw_line(Vector2(x, y), Vector2(x + slant, y + 22), Color("d8eeeb", 0.63), 2.0, true)
		"frost":
			for index: int in range(32):
				var x: float = zone.position.x + fposmod(float(index * 103) + sin(time * 0.7 + index) * 14.0, zone.size.x)
				var y: float = zone.position.y + fposmod(float(index * 149) + time * (22.0 + float(index % 4) * 5.0), zone.size.y)
				var pos: Vector2 = Vector2(x, y)
				draw_line(pos + Vector2(-3, -3), pos + Vector2(3, 3), Color("ffffff", 0.62), 1.5, true)
				draw_line(pos + Vector2(3, -3), pos + Vector2(-3, 3), Color("ffffff", 0.62), 1.5, true)


func _draw_field_edge(zone: Rect2, color: Color) -> void:
	for x: int in [int(zone.position.x), int(zone.end.x)]:
		for y: int in range(int(zone.position.y + 12.0), int(zone.end.y - 9.0), 22):
			draw_line(Vector2(x, y), Vector2(x, y + 10.0), color, 2.0, true)
	for x: int in range(int(zone.position.x + 12.0), int(zone.end.x - 9.0), 22):
		draw_line(Vector2(x, zone.position.y), Vector2(x + 10.0, zone.position.y), color, 2.0, true)


func _draw_wall(wall: Rect2) -> void:
	var fabric: Color = _cloth_color()
	draw_rect(wall.grow(8.0), Color("635347", 0.2))
	draw_rect(wall.grow(2.0), INK)
	draw_rect(wall, fabric)
	draw_texture_rect(FELT, wall.grow(-4.0), true, fabric.lightened(0.25))
	if wall.size.x > wall.size.y:
		for x: int in range(int(wall.position.x + 9), int(wall.end.x - 7), 15):
			draw_line(Vector2(x, wall.position.y + 4), Vector2(x + 7, wall.position.y + 4), THREAD, 2.0, true)
			draw_line(Vector2(x, wall.end.y - 4), Vector2(x + 7, wall.end.y - 4), Color("59473a", 0.7), 2.0, true)
		for x: int in range(int(wall.position.x + 18), int(wall.end.x - 8), 40):
			draw_line(Vector2(x, wall.position.y + 9), Vector2(x + 12, wall.end.y - 8), Color("eedec0", 0.31), 1.0, true)
	else:
		for y: int in range(int(wall.position.y + 9), int(wall.end.y - 7), 15):
			draw_line(Vector2(wall.position.x + 4, y), Vector2(wall.position.x + 4, y + 7), THREAD, 2.0, true)
			draw_line(Vector2(wall.end.x - 4, y), Vector2(wall.end.x - 4, y + 7), Color("59473a", 0.7), 2.0, true)


func _draw_bridge(bridge: Rect2) -> void:
	var opacity: float = 1.0 if phase == 1 else 0.33
	draw_rect(bridge.grow(3.0), Color("385e60", opacity))
	draw_texture_rect(FELT, bridge.grow(-3.0), true, Color(0.65, 0.84, 0.77, opacity))
	for x: int in range(int(bridge.position.x + 8), int(bridge.end.x - 7), 16):
		draw_line(Vector2(x, bridge.position.y + 5), Vector2(x + 7, bridge.position.y + 5), Color(1.0, 0.96, 0.82, opacity), 2.0, true)
		draw_line(Vector2(x, bridge.end.y - 5), Vector2(x + 7, bridge.end.y - 5), Color(0.2, 0.35, 0.34, opacity), 2.0, true)


# Steel needles sewn into a band, tips along dir. The art points up, so it is turned to face dir with its
# band sunk a little into the surface. A pop-up strip at rise 0 shows only its band with the needle eyes
# peeking through the cloth, the tell that the strip is there, and grows its needles out of it as it rises.
func _draw_needles(area: Rect2, dir: Vector2, rise: float) -> void:
	var length: float = area.size.dot(Vector2(-dir.y, dir.x).abs()) / NEEDLE_SCALE
	var surface: Vector2 = area.get_center() - dir * area.size.dot(dir.abs()) * 0.5
	var band_height: float = NEEDLE_BAND_BOTTOM - NEEDLE_BAND_TOP
	var band_y: float = NEEDLE_SINK / NEEDLE_SCALE - band_height
	draw_set_transform(surface, dir.angle() + PI * 0.5, Vector2.ONE * NEEDLE_SCALE)
	if rise > 0.02:
		var tall: float = NEEDLE_BAND_TOP * rise
		var src: Rect2 = Rect2(0, 0, NEEDLES_RAISED.get_width(), NEEDLE_BAND_TOP)
		var dest: Rect2 = Rect2(-length * 0.5, band_y - tall, length, tall)
		for side: float in [-NEEDLE_OUTLINE, NEEDLE_OUTLINE]:
			_tile(NEEDLES_RAISED, src, Rect2(dest.position + Vector2(side, 0), dest.size), false, Color(INK, 0.45))
		_tile(NEEDLES_RAISED, src, dest, false)
	var band: Texture2D = NEEDLES_RAISED if rise > 0.98 else NEEDLES_FLAT
	_tile(band, Rect2(0, NEEDLE_BAND_TOP, band.get_width(), band_height), Rect2(-length * 0.5, band_y, length, band_height), false)
	draw_set_transform(Vector2.ZERO)


# A zipper that can run is sewn on a track, drawn from where it starts through every point it runs to.
func _draw_exit_track() -> void:
	var points: Array = [level["exit"]] + level["exit_flee"]
	var width: float = ZIPPER_TRACK.get_width()
	for index: int in range(points.size() - 1):
		var from: Vector2 = points[index]
		var to: Vector2 = points[index + 1]
		var span: Vector2 = to - from
		var length: float = (span.length() + TRACK_OVERHANG * 2.0) / TRACK_SCALE
		draw_set_transform(from - span.normalized() * TRACK_OVERHANG, span.angle() - PI * 0.5, Vector2.ONE * TRACK_SCALE)
		_tile(ZIPPER_TRACK, Rect2(Vector2.ZERO, ZIPPER_TRACK.get_size()), Rect2(-width * 0.5, 0, width, length), true)
	draw_set_transform(Vector2.ZERO)


# Repeats a tileable strip of src over dest, along x or down y, cutting the last tile short.
func _tile(texture: Texture2D, src: Rect2, dest: Rect2, vertical: bool, tint: Color = Color.WHITE) -> void:
	var step: float = src.size.y if vertical else src.size.x
	var total: float = dest.size.y if vertical else dest.size.x
	var offset: float = 0.0
	while offset < total:
		var piece: float = minf(step, total - offset)
		if vertical:
			draw_texture_rect_region(texture, Rect2(dest.position + Vector2(0, offset), Vector2(dest.size.x, piece)), Rect2(src.position, Vector2(src.size.x, piece)), tint)
		else:
			draw_texture_rect_region(texture, Rect2(dest.position + Vector2(offset, 0), Vector2(piece, dest.size.y)), Rect2(src.position, Vector2(piece, src.size.y)), tint)
		offset += step


func _draw_sentry_tracks() -> void:
	for data: Dictionary in level["sentries"]:
		var from: Vector2 = data["from"]
		var to: Vector2 = data["to"]
		draw_line(from, to, Color("735c54", 0.27), 3.0, true)
		_draw_stitches(from, to, Color("b0826a", 0.65), 18.0)
		draw_circle(from, 5.0, RUST)
		draw_circle(to, 5.0, RUST)


# A flower stands on whichever surface its gravity points at. Unlit it is a faded, drooping bud; touched,
# it pops open, glows and sways.
func _draw_flower(index: int) -> void:
	var flower: Dictionary = level["flowers"][index]
	var gravity: Vector2 = flower["gravity"]
	var lit: bool = index < flower_lit.size() and flower_lit[index]
	var pop: float = 0.0
	if flower_bloom.has(index):
		var t: float = flower_bloom[index] / FLOWER_POP_TIME
		pop = sin(t * PI) * (1.0 - t) * 0.9
	var sway: float = sin(time * 1.8 + float(index)) * (0.05 if lit else 0.0) + (0.0 if lit else 0.12)
	var grow: float = (1.0 if lit else 0.86) + pop
	draw_set_transform(flower["pos"] + gravity * 54.0, gravity.angle() - PI * 0.5 + sway, Vector2.ONE * grow)
	if lit:
		draw_circle(Vector2(0, -92), 46.0 + sin(time * 3.0) * 3.0, Color("f6dda0", 0.22))
	draw_texture_rect(CHECKPOINT, Rect2(Vector2(-52, -130), Vector2(104, 130)), false, Color.WHITE if lit else Color("b9ad9b", 0.9))
	draw_set_transform(Vector2.ZERO)


func bloom_flower(index: int) -> void:
	flower_bloom[index] = 0.0
	var flower: Dictionary = level["flowers"][index]
	var gravity: Vector2 = flower["gravity"]
	burst_bloom(flower["pos"] - gravity * 38.0)


func celebrate(pos: Vector2) -> void:
	var colours: Array[Color] = [Color(level.get("accent", RUST)), Color("e7c785"), THREAD, RUST, TEAL]
	for index: int in range(CONFETTI_COUNT):
		var angle: float = (-gravity_direction).angle() + randf_range(-1.1, 1.1)
		confetti.append({
			"pos": pos,
			"velocity": Vector2.from_angle(angle) * randf_range(380.0, 900.0),
			"spin": randf() * TAU,
			"turn": randf_range(-9.0, 9.0),
			"age": randf_range(0.0, 0.3),
			"colour": colours[index % colours.size()],
			"petal": index % 3 == 0,
		})


func _draw_confetti() -> void:
	for bit: Dictionary in confetti:
		var fade: float = clampf((CONFETTI_LIFE - float(bit["age"])) / 0.5, 0.0, 1.0)
		var colour: Color = bit["colour"]
		draw_set_transform(bit["pos"], bit["spin"], Vector2.ONE)
		if bit["petal"]:
			draw_circle(Vector2.ZERO, 7.0, Color(colour, fade))
			draw_circle(Vector2(4, 0), 5.0, Color(colour.lightened(0.25), fade))
		else:
			draw_rect(Rect2(-9, -2, 18, 4), Color(colour, fade))
	draw_set_transform(Vector2.ZERO)


func _draw_shard(point: Vector2, index: int) -> void:
	var center: Vector2 = point + Vector2(0, sin(time * 4.4 + index * 1.7) * 3.0)
	draw_circle(center, 36.0, Color(button_colour, 0.25))
	for spoke: int in range(8):
		var angle: float = float(spoke) * TAU / 8.0 + time * 0.25
		draw_line(center + Vector2.from_angle(angle) * 27.0, center + Vector2.from_angle(angle) * 35.0, Color(button_colour, 0.78), 2.0, true)
	draw_circle(center, 18.0, INK)
	draw_circle(center, 15.0, button_colour)
	for hole: int in range(4):
		draw_circle(center + Vector2.from_angle(float(hole) * TAU / 4.0 + PI * 0.25) * 7.0, 2.2, INK)


func _draw_pad(pos: Vector2) -> void:
	var color: Color = TEAL if pad_armed else Color("b39475")
	draw_rect(Rect2(pos.x - 58, pos.y - 12, 116, 28), INK)
	draw_rect(Rect2(pos.x - 54, pos.y - 10, 108, 22), color)
	_draw_stitches(pos + Vector2(-49, -4), pos + Vector2(49, -4), THREAD, 12.0)
	for x: int in [-31, 0, 31]:
		draw_circle(pos + Vector2(x, 4), 3.0, Color("f3dfbb"))


func _draw_door(pos: Vector2) -> void:
	var outside: Rect2 = Rect2(pos - Vector2(58, 79), Vector2(116, 158))
	draw_rect(outside.grow(7), Color("6a5147", 0.24))
	draw_rect(outside, INK)
	draw_rect(outside.grow(-5), Color("b7aa8c"))
	var opening: Rect2 = Rect2(pos - Vector2(39, 58), Vector2(78, 123))
	draw_rect(opening, Color("524746"))
	draw_rect(opening.grow(-5), Color("5e8c81").lerp(Color("ecdfb2"), door_progress))
	for y: int in range(int(outside.position.y + 8), int(outside.end.y - 8), 14):
		draw_line(Vector2(outside.position.x + 9, y), Vector2(outside.position.x + 9, y + 7), THREAD, 2.0, true)
		draw_line(Vector2(outside.end.x - 9, y), Vector2(outside.end.x - 9, y + 7), THREAD, 2.0, true)
	# The pull slides up as the zipper opens and back down as it closes, with the teeth still shut below it.
	var pull_y: float = lerpf(60.0, -52.0, door_progress)
	for y: int in range(int(opening.position.y + 8), int(opening.end.y - 4), 12):
		if float(y) > pos.y + pull_y:
			draw_line(Vector2(pos.x - 3, y), Vector2(pos.x + 3, y + 5), Color("e8c989"), 3.0, true)
	draw_line(pos + Vector2(0, pull_y), pos + Vector2(0, pull_y + 16), INK, 4.0, true)
	draw_circle(pos + Vector2(0, pull_y + 16), 9.0, RUST)


func _draw_loose_threads() -> void:
	for index: int in range(15):
		var x: float = 176.0 + fposmod(float(index * 173) + time * (8.0 + float(index % 3) * 3.0), 1540.0)
		var y: float = 215.0 + float((index * 139) % 640) + sin(time * 0.7 + index) * 8.0
		draw_line(Vector2(x, y), Vector2(x + 10.0, y - 3.0), Color("8c7566", 0.25), 1.5, true)


func collect_spark(pos: Vector2) -> void:
	spark_bursts.append({"position": pos, "age": 0.0})


func burst_bloom(pos: Vector2) -> void:
	bloom_bursts.append({"position": pos, "age": 0.0})


func _draw_bloom_bursts() -> void:
	for burst: Dictionary in bloom_bursts:
		var age: float = burst["age"]
		var center: Vector2 = burst["position"] + Vector2(0, -16.0)
		var opacity: float = 1.0 - age / 0.55
		draw_arc(center, 34.0 + age * 135.0, PI, TAU, 32, Color("f0d7a5", opacity), 4.0, true)
		for petal: int in range(6):
			var outward: Vector2 = Vector2.from_angle(float(petal) * TAU / 6.0)
			draw_line(center + outward * (25.0 + age * 70.0), center + outward * (35.0 + age * 90.0), Color("f7e8c9", opacity), 3.0, true)


func _draw_spark_bursts() -> void:
	for burst: Dictionary in spark_bursts:
		var age: float = burst["age"]
		var center: Vector2 = burst["position"]
		var fade: float = 1.0 - age / 0.55
		for index: int in range(12):
			var direction: Vector2 = Vector2.from_angle(float(index) * TAU / 12.0)
			var start: Vector2 = center + direction * (17.0 + age * 105.0)
			draw_line(start, start + direction * 14.0, Color(0.7, 0.42, 0.25, fade), 3.0, true)


func _draw_shift_seam() -> void:
	var fade: float = 1.0 - shift_age / 0.68
	var radius: float = 25.0 + shift_age * 640.0
	draw_arc(shift_origin, radius, 0.0, TAU, 96, Color(0.35, 0.53, 0.49, fade * 0.65), 2.0, true)
	for index: int in range(32):
		var angle: float = float(index) * TAU / 32.0
		var direction: Vector2 = Vector2.from_angle(angle)
		var tangent: Vector2 = direction.rotated(PI * 0.5)
		var point: Vector2 = shift_origin + direction * radius
		draw_line(point - tangent * 6.0, point + tangent * 6.0, Color(0.32, 0.47, 0.43, fade), 2.0, true)


func _draw_stitches(from: Vector2, to: Vector2, color: Color, spacing: float) -> void:
	var length: float = from.distance_to(to)
	if length < 1.0:
		return
	var direction: Vector2 = (to - from) / length
	for index: int in range(int(length / spacing)):
		var start: Vector2 = from + direction * (float(index) * spacing)
		draw_line(start, start + direction * minf(spacing * 0.52, length - float(index) * spacing), color, 2.0, true)
