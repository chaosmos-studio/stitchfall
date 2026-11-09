class_name StitchfallWorldView
extends Node2D

const FELT: Texture2D = preload("res://assets/art/felt_tile.png")
# Each chapter's painting, by chapter id. The first six are sewing-room scenes, the rest are worlds.
const BACKDROPS: Dictionary[String, Texture2D] = {
	"linen": preload("res://assets/art/backdrops/linen.webp"),
	"pins": preload("res://assets/art/backdrops/pins.webp"),
	"unpinned": preload("res://assets/art/backdrops/unpinned.webp"),
	"seams": preload("res://assets/art/backdrops/seams.webp"),
	"moths": preload("res://assets/art/backdrops/moths.webp"),
	"patch": preload("res://assets/art/backdrops/patch.webp"),
	"water": preload("res://assets/art/cloth_water.webp"),
	"dunes": preload("res://assets/art/cloth_dunes.webp"),
	"canopy": preload("res://assets/art/cloth_forest.webp"),
	"night": preload("res://assets/art/cloth_night.webp"),
	"rain": preload("res://assets/art/cloth_rain.webp"),
	"frost": preload("res://assets/art/cloth_frost.webp"),
}
# A wardrobe fabric (its backdrop number in looks.gd) dresses the sewing-room chapters as one of the worlds.
const FABRIC_ART: Dictionary[int, String] = {4: "water", 5: "dunes", 6: "canopy", 7: "night", 8: "rain", 9: "frost"}
const SEWING_ROOMS: PackedStringArray = ["linen", "pins", "unpinned", "seams", "moths", "patch"]
# The felt each chapter's ledges are cut from, as a tint on the cream felt, chosen to stand out on its painting.
const FELT_TINTS: Dictionary[String, Color] = {
	"linen": Color("8e9c72"), "pins": Color("c46a58"), "unpinned": Color("7590a3"), "seams": Color("4f7e7b"),
	"moths": Color("8b78a6"), "patch": Color("a7794c"), "water": Color("5f8f95"), "dunes": Color("b48552"),
	"canopy": Color("6d8a5c"), "night": Color("6c71a0"), "rain": Color("6a948c"), "frost": Color("8aa3b6"),
}
# The grass along a floor, tinted for the chapters that grow any.
const GRASS_TINTS: Dictionary[String, Color] = {
	"linen": Color.WHITE, "pins": Color.WHITE, "unpinned": Color.WHITE, "seams": Color("b9c9b8"),
	"moths": Color("c9bdd6"), "patch": Color("e8dcae"), "canopy": Color.WHITE, "rain": Color("d5e6dc"),
}
const LEDGE: Texture2D = preload("res://assets/art/props/felt_ledge.png")
const POCKET_SHUT: Texture2D = preload("res://assets/art/props/pocket_closed.png")
const POCKET_OPEN: Texture2D = preload("res://assets/art/props/pocket_open.png")
const BUTTONS: Texture2D = preload("res://assets/art/props/buttons.png")
const GRASS: Texture2D = preload("res://assets/art/props/grass_fringe.png")
# The felt ledge art: the whole strip, its square corners, and the tileable run in its middle, in its pixels.
const LEDGE_STRIP: Rect2 = Rect2(5, 27, 1014, 140)
const LEDGE_CORNER: float = 52.0
const LEDGE_RUN: Vector2 = Vector2(256, 768)
# How large a ledge's corner is drawn, as a share of its thickness and at most, and where its shadow falls.
const LEDGE_ROUND: float = 0.5
const LEDGE_ROUND_MOST: float = 26.0
const LEDGE_SHADOW: Vector2 = Vector2(4, 7)
# The grass art's blades (its pixel rows), how tall they are drawn and how far they sink into the felt.
const GRASS_ROWS: Vector2 = Vector2(67, 128)
const GRASS_HEIGHT: float = 24.0
const GRASS_SINK: float = 5.0
# The pocket art's opaque middle and height in its pixels, and how tall the pocket is drawn.
const POCKET_MIDDLE: Vector2 = Vector2(255, 361)
const POCKET_ART_HEIGHT: float = 534.0
const POCKET_HEIGHT: float = 176.0
# A button is the cream one in the sheet (the fourth cell), tinted the wardrobe's colour, drawn this wide.
const BUTTON_CELL: Rect2 = Rect2(768, 0, 256, 256)
const BUTTON_SIZE: float = 50.0
# How much more of the painting is cropped from its top than its foot, so its ground meets the room's floor.
const BACKDROP_TOP_CROP: float = 0.7
# A landing's fluff: how many bits and how long they last. How long a prank's "!" stays over the runner.
const FLUFF_COUNT: int = 8
const FLUFF_LIFE: float = 0.42
const SURPRISE_TIME: float = 0.8
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
# What the camera shows of the world when the room is fitted, which the painting covers.
var view: Rect2 = Rect2(0, 0, 1920, 1080)
# Bits of felt fluff kicked up by a landing, and the runner, whom the surprise bubble follows.
var fluff: Array[Dictionary] = []
var runner: Node2D
var surprise_age: float = 9.0


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
	for bit: Dictionary in fluff:
		var drift: Vector2 = bit["velocity"]
		bit["velocity"] = drift * (1.0 - delta * 5.0)
		bit["pos"] += drift * delta
		bit["age"] += delta
	fluff = fluff.filter(func(bit: Dictionary) -> bool: return float(bit["age"]) < FLUFF_LIFE)
	surprise_age += delta
	queue_redraw()


# A landing kicks felt fluff out either side along the surface, `feet` where the runner touched down.
func puff(feet: Vector2, pull: Vector2) -> void:
	var along: Vector2 = Vector2(pull.y, -pull.x)
	for index: int in range(FLUFF_COUNT):
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var speed: float = 70.0 + float(index) * 18.0
		fluff.append({"pos": feet, "velocity": along * side * speed - pull * (20.0 + float(index % 3) * 12.0), "age": 0.0, "size": 2.5 + float(index % 3) * 1.5})


# A prank just sprang: a stitched bubble with a "!" pops up over the runner's head.
func surprise() -> void:
	surprise_age = 0.0


func _draw_fluff() -> void:
	for bit: Dictionary in fluff:
		var fade: float = 1.0 - float(bit["age"]) / FLUFF_LIFE
		draw_circle(bit["pos"], float(bit["size"]) * (0.6 + fade * 0.4), Color(THREAD, 0.85 * fade))


func _draw_surprise() -> void:
	if surprise_age >= SURPRISE_TIME or not is_instance_valid(runner):
		return
	var grow: float = clampf(surprise_age / 0.16, 0.0, 1.0)
	var pop: float = 1.0 + 0.35 * sin(grow * PI) if grow < 1.0 else 1.0
	var fade: float = clampf((SURPRISE_TIME - surprise_age) / 0.2, 0.0, 1.0)
	var centre: Vector2 = runner.position - gravity_direction * 92.0
	var radius: float = 22.0 * grow * pop
	draw_circle(centre + Vector2(2, 3), radius, Color(0, 0, 0, 0.2 * fade))
	draw_circle(centre, radius, Color(Color("f7edda"), fade))
	draw_arc(centre, radius - 3.0, 0.0, TAU, 32, Color(RUST, 0.7 * fade), 2.0, true)
	draw_set_transform(centre, gravity_direction.angle() - PI * 0.5, Vector2.ONE * grow * pop)
	draw_line(Vector2(0, -11), Vector2(0, 3), Color(RUST, fade), 5.0, true)
	draw_circle(Vector2(0, 10), 3.2, Color(RUST, fade))
	draw_set_transform(Vector2.ZERO)


func _draw() -> void:
	_draw_backdrop()
	if level.is_empty():
		return
	_draw_chamber()
	_draw_environment()
	for wall: Rect2 in level["walls"]:
		_draw_felt(wall, Color(0, 0, 0, 0.22), LEDGE_SHADOW)
	for wall: Rect2 in level["walls"]:
		_draw_wall(wall)
	_draw_grass()
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
	_draw_fluff()
	_draw_surprise()
	if shift_age < 0.68:
		_draw_shift_seam()


# A wardrobe fabric dresses the plain linen rooms. Rooms set in a world keep that world's cloth.
func _backdrop() -> int:
	var backdrop: int = int(level.get("backdrop", 0))
	return fabric_backdrop if fabric_backdrop >= 0 and backdrop < 4 else backdrop


# Which painting and felt the room uses: its chapter's, unless a worn fabric dresses a sewing-room chapter.
func art_id() -> String:
	var chapter: String = level.get("art", "linen")
	if chapter in SEWING_ROOMS and FABRIC_ART.has(fabric_backdrop):
		return FABRIC_ART[fabric_backdrop]
	return chapter


# The painting covers what the camera shows, cropped more from its sky than its ground, so the whole picture is
# seen at its own sharpness instead of a magnified slice of its middle.
func _draw_backdrop() -> void:
	var painting: Texture2D = BACKDROPS.get(art_id(), BACKDROPS["linen"])
	var art: Vector2 = painting.get_size()
	var cover: float = maxf(view.size.x / art.x, view.size.y / art.y)
	var drawn: Vector2 = art * cover
	var spare: Vector2 = drawn - view.size
	# A wide margin first, in case the camera is ever off its fitted place, then the fitted picture.
	draw_texture_rect(painting, view.grow(view.size.x * 0.5), false, Color(1, 1, 1, 1))
	draw_texture_rect(painting, Rect2(view.position - Vector2(spare.x * 0.5, spare.y * BACKDROP_TOP_CROP), drawn), false)


func _draw_chamber() -> void:
	var chamber: Rect2 = level["chamber"]
	draw_rect(chamber.grow(12.0), Color("644f43", 0.12))
	draw_rect(chamber, Color("f7efdc", 0.07))


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
	_draw_felt(wall, FELT_TINTS.get(art_id(), FELT_TINTS["linen"]), Vector2.ZERO)


# A ledge or wall cut from the felt strip: its rounded, stitched corners kept square and its middle repeated along
# it, so the stitches keep their size however long the ledge is. A wall taller than it is wide is the strip
# turned on its side. `shift` moves it, for the shadow.
func _draw_felt(rect: Rect2, tint: Color, shift: Vector2) -> void:
	var upright: bool = rect.size.y > rect.size.x
	var length: float = rect.size.y if upright else rect.size.x
	var thick: float = rect.size.x if upright else rect.size.y
	var corner: float = minf(minf(thick * LEDGE_ROUND, LEDGE_ROUND_MOST), length * 0.5)
	var scale: float = corner / LEDGE_CORNER
	draw_set_transform(rect.get_center() + shift, PI * 0.5 if upright else 0.0)
	var local: Rect2 = Rect2(-length * 0.5, -thick * 0.5, length, thick)
	var rows: Array[float] = [local.position.y, local.position.y + corner, local.end.y - corner, local.end.y]
	var src_rows: Array[float] = [LEDGE_STRIP.position.y, LEDGE_STRIP.position.y + LEDGE_CORNER, LEDGE_STRIP.end.y - LEDGE_CORNER, LEDGE_STRIP.end.y]
	for row: int in range(3):
		var height: float = rows[row + 1] - rows[row]
		if height <= 0.01:
			continue
		var src_y: float = src_rows[row]
		var src_h: float = src_rows[row + 1] - src_rows[row]
		draw_texture_rect_region(LEDGE, Rect2(local.position.x, rows[row], corner, height), Rect2(LEDGE_STRIP.position.x, src_y, LEDGE_CORNER, src_h), tint)
		draw_texture_rect_region(LEDGE, Rect2(local.end.x - corner, rows[row], corner, height), Rect2(LEDGE_STRIP.end.x - LEDGE_CORNER, src_y, LEDGE_CORNER, src_h), tint)
		_run(LEDGE, Rect2(LEDGE_RUN.x, src_y, LEDGE_RUN.y - LEDGE_RUN.x, src_h), Rect2(local.position.x + corner, rows[row], local.size.x - corner * 2.0, height), scale, tint)
	draw_set_transform(Vector2.ZERO)


# Repeats `src` along x across `dest`, each copy `scale` times its size, cutting the last one short.
func _run(texture: Texture2D, src: Rect2, dest: Rect2, scale: float, tint: Color) -> void:
	var step: float = src.size.x * scale
	var offset: float = 0.0
	while offset < dest.size.x - 0.01 and step > 0.0:
		var piece: float = minf(step, dest.size.x - offset)
		draw_texture_rect_region(texture, Rect2(dest.position + Vector2(offset, 0), Vector2(piece, dest.size.y)), Rect2(src.position, Vector2(piece / scale, src.size.y)), tint)
		offset += step


# Embroidered grass along the top of every floor and ledge, in the chapters that grow any.
func _draw_grass() -> void:
	if not GRASS_TINTS.has(art_id()):
		return
	var tint: Color = GRASS_TINTS[art_id()]
	var scale: float = GRASS_HEIGHT / (GRASS_ROWS.y - GRASS_ROWS.x)
	var chamber: Rect2 = level["chamber"]
	for wall: Rect2 in level["walls"]:
		# Only tops the runner can stand on: wider than tall, and below the room's ceiling.
		if wall.size.x <= wall.size.y or wall.position.y <= chamber.position.y + 1.0:
			continue
		var strip: Rect2 = Rect2(wall.position.x + 6.0, wall.position.y - GRASS_HEIGHT + GRASS_SINK, wall.size.x - 12.0, GRASS_HEIGHT)
		_run(GRASS, Rect2(0, GRASS_ROWS.x, GRASS.get_width(), GRASS_ROWS.y - GRASS_ROWS.x), strip, scale, tint)


# A lit seam: solid, it is amber felt glowing along its middle thread. Unlit, only its stitched outline shows,
# dashes of light where it will be.
func _draw_bridge(bridge: Rect2) -> void:
	if phase == 1:
		_draw_felt(bridge, Color(0, 0, 0, 0.18), LEDGE_SHADOW)
		for ring: int in range(4):
			draw_rect(bridge.grow(4.0 + float(ring) * 5.0), Color(Color("ffcf7a"), 0.05))
		_draw_felt(bridge, Color("e8b45c"), Vector2.ZERO)
		var glow: float = 0.6 + 0.25 * sin(time * 4.0)
		var middle: Vector2 = bridge.get_center()
		var along: Vector2 = Vector2(bridge.size.x * 0.5 - 10.0, 0) if bridge.size.x > bridge.size.y else Vector2(0, bridge.size.y * 0.5 - 10.0)
		draw_line(middle - along, middle + along, Color(Color("fff2c8"), glow), 3.0, true)
	else:
		var dash: Color = Color(Color("e8b45c"), 0.55)
		_draw_stitches(bridge.position, Vector2(bridge.end.x, bridge.position.y), dash, 14.0)
		_draw_stitches(Vector2(bridge.position.x, bridge.end.y), bridge.end, dash, 14.0)
		_draw_stitches(bridge.position, Vector2(bridge.position.x, bridge.end.y), dash, 14.0)
		_draw_stitches(Vector2(bridge.end.x, bridge.position.y), bridge.end, dash, 14.0)


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
	# The cream button from the sheet, tinted the wardrobe's colour, the sheet's cell a little larger than the
	# button it holds.
	var cell: float = BUTTON_SIZE * BUTTON_CELL.size.x / 200.0
	draw_texture_rect_region(BUTTONS, Rect2(center - Vector2.ONE * cell * 0.5 + Vector2(2, 4), Vector2.ONE * cell), BUTTON_CELL, Color(0, 0, 0, 0.22))
	draw_texture_rect_region(BUTTONS, Rect2(center - Vector2.ONE * cell * 0.5, Vector2.ONE * cell), BUTTON_CELL, button_colour.lightened(0.15))


func _draw_pad(pos: Vector2) -> void:
	var color: Color = TEAL if pad_armed else Color("b39475")
	draw_rect(Rect2(pos.x - 58, pos.y - 12, 116, 28), INK)
	draw_rect(Rect2(pos.x - 54, pos.y - 10, 108, 22), color)
	_draw_stitches(pos + Vector2(-49, -4), pos + Vector2(49, -4), THREAD, 12.0)
	for x: int in [-31, 0, 31]:
		draw_circle(pos + Vector2(x, 4), 3.0, Color("f3dfbb"))


# The zipper pocket: shut while buttons are missing, then unzipped and glowing from inside, breathing a little so
# the eye finds it. It swells for a moment as it opens.
func _draw_door(pos: Vector2) -> void:
	var scale: float = POCKET_HEIGHT / POCKET_ART_HEIGHT
	var open: float = door_progress
	var swell: float = 1.0 + sin(open * PI) * 0.08 + (sin(time * 3.0) * 0.015 if door_open else 0.0)
	var size: Vector2 = POCKET_SHUT.get_size() * scale * swell
	var corner: Vector2 = pos - POCKET_MIDDLE * scale * swell
	draw_texture_rect(POCKET_SHUT, Rect2(corner + Vector2(4, 7), size), false, Color(0, 0, 0, 0.2))
	if open > 0.0:
		var glow: float = open * (0.55 + 0.15 * sin(time * 3.0))
		for ring: int in range(6):
			draw_circle(pos, POCKET_HEIGHT * (0.35 + float(ring) * 0.1), Color(Color("ffd27a"), glow * 0.06))
	if open < 1.0:
		draw_texture_rect(POCKET_SHUT, Rect2(corner, size), false, Color(1, 1, 1, 1.0 - open))
	if open > 0.0:
		draw_texture_rect(POCKET_OPEN, Rect2(corner, size), false, Color(1, 1, 1, open))


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
