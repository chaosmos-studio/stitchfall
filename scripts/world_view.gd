class_name PalewheelWorldView
extends Node2D

const LINEN: Texture2D = preload("res://assets/art/linen_landscape.png")
const FELT: Texture2D = preload("res://assets/art/felt_tile.png")
const WATER_CLOTH: Texture2D = preload("res://assets/art/cloth_water.webp")
const DUNE_CLOTH: Texture2D = preload("res://assets/art/cloth_dunes.webp")
const FOREST_CLOTH: Texture2D = preload("res://assets/art/cloth_forest.webp")
const NIGHT_CLOTH: Texture2D = preload("res://assets/art/cloth_night.webp")
const RAIN_CLOTH: Texture2D = preload("res://assets/art/cloth_rain.webp")
const FROST_CLOTH: Texture2D = preload("res://assets/art/cloth_frost.webp")
const INK: Color = Color("493a37")
const THREAD: Color = Color("f9e9ca")
const RUST: Color = Color("b45d4c")
const TEAL: Color = Color("618d86")

var level: Dictionary = {}
var phase: int = 0
var collected: Array[bool] = []
var pad_armed: bool = false
var checkpoint_active: bool = false
var door_open: bool = false
var time: float = 0.0
var gravity_direction: Vector2 = Vector2.DOWN
var shift_origin: Vector2 = Vector2.ZERO
var shift_age: float = 1.0
var door_progress: float = 0.0
var spark_bursts: Array[Dictionary] = []


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _process(delta: float) -> void:
	time += delta
	shift_age += delta
	door_progress = move_toward(door_progress, 1.0 if door_open else 0.0, delta * 3.0)
	for index: int in range(spark_bursts.size() - 1, -1, -1):
		spark_bursts[index]["age"] += delta
		if spark_bursts[index]["age"] > 0.55:
			spark_bursts.remove_at(index)
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
	for hazard: Rect2 in level["hazards"]:
		_draw_hazard(hazard)
	for index: int in range(collected.size()):
		if not collected[index]:
			_draw_shard(level["shards"][index], index)
	if level["pad"] != Vector2.ZERO:
		_draw_pad(level["pad"])
	if level["checkpoint"] != Vector2.ZERO:
		_draw_checkpoint(level["checkpoint"])
	_draw_door(level["exit"])
	_draw_loose_threads()
	_draw_spark_bursts()
	if shift_age < 0.68:
		_draw_shift_seam()


func _backdrop_texture() -> Texture2D:
	match int(level.get("backdrop", 0)):
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
	match int(level.get("backdrop", 0)):
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
	var inset: Rect2 = Rect2(110, 168, 1700, 760)
	draw_rect(inset.grow(12.0), Color("644f43", 0.15))
	draw_rect(inset, Color("f7efdc", 0.2))
	for x: int in range(170, 1770, 48):
		var sway: float = sin(float(x) * 0.021 + time * 1.2) * 2.0
		draw_line(Vector2(x, 205 + sway), Vector2(x + 19, 198 + sway), Color("9c8471", 0.36), 2.0, true)


func _draw_environment() -> void:
	var kind: String = level.get("environment", "")
	var zone: Rect2 = level.get("environment_zone", Rect2())
	if not zone.has_area():
		return
	match kind:
		"water":
			draw_rect(zone, Color("86b6b5", 0.22))
			for x: int in range(int(zone.position.x), int(zone.end.x), 30):
				var wave: float = sin(float(x) * 0.025 + time * 2.3) * 4.0
				draw_line(Vector2(x, zone.position.y + wave), Vector2(x + 15, zone.position.y + wave - 2), Color("f3f2d9", 0.85), 3.0, true)
			for index: int in range(11):
				var pos: Vector2 = Vector2(zone.position.x + fposmod(float(index * 93), zone.size.x), zone.end.y - fposmod(float(index * 113) + time * 15.0, zone.size.y))
				draw_arc(pos, 5.0 + float(index % 3) * 2.0, 0.0, TAU, 20, Color("d9e4cf", 0.55), 2.0, true)
		"dunes":
			for index: int in range(23):
				var pos: Vector2 = Vector2(zone.position.x + fposmod(float(index * 101) + time * 35.0, zone.size.x), zone.position.y + fposmod(float(index * 127), zone.size.y))
				draw_line(pos, pos + Vector2(26, -4), Color("9e764d", 0.55), 2.0, true)
		"forest":
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
				var slant: float = 8.0 + sin(time * 1.7) * 6.0
				draw_line(Vector2(x, y), Vector2(x + slant, y + 22), Color("d8eeeb", 0.63), 2.0, true)
		"frost":
			for index: int in range(32):
				var x: float = zone.position.x + fposmod(float(index * 103) + sin(time * 0.7 + index) * 14.0, zone.size.x)
				var y: float = zone.position.y + fposmod(float(index * 149) + time * (22.0 + float(index % 4) * 5.0), zone.size.y)
				var pos: Vector2 = Vector2(x, y)
				draw_line(pos + Vector2(-3, -3), pos + Vector2(3, 3), Color("ffffff", 0.62), 1.5, true)
				draw_line(pos + Vector2(3, -3), pos + Vector2(-3, 3), Color("ffffff", 0.62), 1.5, true)


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


func _draw_hazard(area: Rect2) -> void:
	var base: float = area.position.y - 13.0
	draw_rect(Rect2(area.position.x - 7, base + 25, area.size.x + 14, 18), INK)
	draw_rect(Rect2(area.position.x - 5, base + 27, area.size.x + 10, 13), RUST)
	for x: int in range(int(area.position.x + 14), int(area.end.x - 4), 31):
		var tip: Vector2 = Vector2(x + 8, base - 15 + sin(time * 2.0 + x) * 1.5)
		draw_colored_polygon(PackedVector2Array([Vector2(x, base + 26), tip, Vector2(x + 16, base + 26)]), Color("5b5451"))
		draw_line(tip + Vector2(2, 8), Vector2(x + 8, base + 23), Color("f5ead5"), 2.0, true)
		draw_circle(Vector2(x + 8, base + 19), 2.0, Color("d5bf98"))
	_draw_stitches(Vector2(area.position.x, base + 34), Vector2(area.end.x, base + 34), THREAD, 17.0)


func _draw_sentry_tracks() -> void:
	for data: Dictionary in level["sentries"]:
		var from: Vector2 = data["from"]
		var to: Vector2 = data["to"]
		draw_line(from, to, Color("735c54", 0.27), 3.0, true)
		_draw_stitches(from, to, Color("b0826a", 0.65), 18.0)
		draw_circle(from, 5.0, RUST)
		draw_circle(to, 5.0, RUST)


func _draw_checkpoint(pos: Vector2) -> void:
	var color: Color = TEAL if checkpoint_active else Color("a9a18e")
	draw_line(pos + Vector2(0, 36), pos + Vector2(0, -47), INK, 4.0, true)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -48), pos + Vector2(53, -36), pos + Vector2(0, -15)]), color)
	_draw_stitches(pos + Vector2(4, -40), pos + Vector2(40, -33), THREAD, 13.0)
	draw_circle(pos + Vector2(0, 37), 8.0, Color("c4a67e"))


func _draw_shard(point: Vector2, index: int) -> void:
	var center: Vector2 = point + Vector2(0, sin(time * 4.4 + index * 1.7) * 3.0)
	var required_phases: Array = level.get("shard_phases", [])
	var required_phase: int = int(required_phases[index]) if index < required_phases.size() else -1
	var ready: bool = required_phase < 0 or required_phase == phase
	var tint: Color = Color("e4c77f") if required_phase < 0 else (Color("8cd1be") if required_phase == 1 else Color("d7a998"))
	draw_circle(center, 36.0, Color(tint, 0.25 if ready else 0.08))
	for spoke: int in range(8):
		var angle: float = float(spoke) * TAU / 8.0 + time * 0.25
		draw_line(center + Vector2.from_angle(angle) * 27.0, center + Vector2.from_angle(angle) * 35.0, Color(tint, 0.78 if ready else 0.28), 2.0, true)
	draw_circle(center, 18.0, INK)
	draw_circle(center, 15.0, tint.darkened(0.43) if not ready else tint)
	for hole: int in range(4):
		draw_circle(center + Vector2.from_angle(float(hole) * TAU / 4.0 + PI * 0.25) * 7.0, 2.2, INK)
	if required_phase >= 0:
		_draw_stitches(center + Vector2(-33, 42), center + Vector2(33, 42), tint, 11.0)


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
	if door_progress < 1.0:
		for y: int in range(int(opening.position.y + 8), int(opening.end.y - 4), 12):
			draw_line(Vector2(pos.x - 3, y), Vector2(pos.x + 3, y + 5), Color("e8c989", 1.0 - door_progress), 3.0, true)
		draw_circle(pos + Vector2(0, 60), 9.0, RUST)


func _draw_loose_threads() -> void:
	for index: int in range(15):
		var x: float = 176.0 + fposmod(float(index * 173) + time * (8.0 + float(index % 3) * 3.0), 1540.0)
		var y: float = 215.0 + float((index * 139) % 640) + sin(time * 0.7 + index) * 8.0
		draw_line(Vector2(x, y), Vector2(x + 10.0, y - 3.0), Color("8c7566", 0.25), 1.5, true)


func collect_spark(pos: Vector2) -> void:
	spark_bursts.append({"position": pos, "age": 0.0})


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
