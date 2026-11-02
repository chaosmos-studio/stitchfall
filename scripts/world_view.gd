class_name PalewheelWorldView
extends Node2D

const BACKDROPS: Array = [
	preload("res://assets/art/station.webp"),
	preload("res://assets/art/station_sensor.webp"),
	preload("res://assets/art/station_freight.webp"),
	preload("res://assets/art/station_core.webp"),
]
const INK: Color = Color("18262c")
const BRASS: Color = Color("ef6a3d")
const PORCELAIN: Color = Color("f7f8f5")

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


func _process(delta: float) -> void:
	time += delta
	shift_age += delta
	queue_redraw()


func _draw() -> void:
	var backdrop_index: int = clampi(int(level.get("backdrop", 0)), 0, BACKDROPS.size() - 1)
	draw_texture_rect(BACKDROPS[backdrop_index] as Texture2D, Rect2(-330, -180, 2580, 1440), false)
	draw_rect(Rect2(-330, -180, 2580, 1440), Color("f5f7f4", 0.04))
	if level.is_empty():
		return
	_draw_chamber()
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
	_draw_motes()
	if shift_age < 0.62:
		var radius: float = 36.0 + shift_age * 710.0
		var opacity: float = (0.62 - shift_age) / 0.62
		draw_arc(shift_origin, radius, 0.0, TAU, 96, Color(0.03, 0.77, 0.88, opacity * 0.8), 10.0, true)
		draw_arc(shift_origin, radius + 26.0, 0.0, TAU, 96, Color(0.04, 0.12, 0.16, opacity * 0.5), 3.0, true)


func _draw_chamber() -> void:
	draw_rect(Rect2(110, 168, 1700, 760), Color("f5f8f6", 0.15))


func _draw_wall(wall: Rect2) -> void:
	draw_rect(wall.grow(6.0), Color("17252b", 0.3))
	draw_rect(wall.grow(2.0), INK)
	draw_rect(wall.grow(-3.0), Color("53646b"))
	var inset: Rect2 = wall.grow(-8.0)
	if inset.size.x > 0.0 and inset.size.y > 0.0:
		draw_rect(inset, Color("bdc8c8"))
		if wall.size.x >= wall.size.y:
			draw_line(inset.position + Vector2(5, 4), Vector2(inset.end.x - 5, inset.position.y + 4), PORCELAIN, 3.0)
			draw_line(Vector2(inset.position.x, inset.end.y - 4), Vector2(inset.end.x, inset.end.y - 4), Color("28393f"), 3.0)
		else:
			draw_line(inset.position + Vector2(4, 5), Vector2(inset.position.x + 4, inset.end.y - 5), PORCELAIN, 3.0)
	if wall.size.x > wall.size.y:
		for x: float in range(int(wall.position.x + 24), int(wall.end.x - 8), 78):
			draw_line(Vector2(x, inset.position.y + 4), Vector2(x - 7, inset.end.y - 4), Color("4b5c60", 0.7), 2.0)
			draw_circle(Vector2(x + 22, wall.get_center().y), 4.0, INK)
			draw_circle(Vector2(x + 22, wall.get_center().y), 2.0, BRASS)
			draw_line(Vector2(x + 37, wall.position.y + 6), Vector2(x + 51, wall.position.y + 6), Color("ef6a3d", 0.85), 3.0)
	else:
		for y: float in range(int(wall.position.y + 26), int(wall.end.y - 8), 78):
			draw_line(Vector2(inset.position.x + 4, y), Vector2(inset.end.x - 4, y - 7), Color("4b5c60", 0.7), 2.0)
			draw_circle(Vector2(wall.get_center().x, y + 22), 4.0, INK)
			draw_circle(Vector2(wall.get_center().x, y + 22), 2.0, BRASS)


func _draw_bridge(bridge: Rect2) -> void:
	var enabled: bool = phase == 1
	var opacity: float = 0.9 if enabled else 0.25
	draw_rect(bridge.grow(11.0), Color(0.02, 0.82, 0.93, 0.2 if enabled else 0.04))
	draw_rect(bridge.grow(2.0), Color("103e4b", opacity))
	draw_rect(bridge.grow(-4.0), Color("46d9e8", opacity))
	for x: float in range(int(bridge.position.x + 13), int(bridge.end.x), 34):
		draw_line(Vector2(x, bridge.position.y + 4), Vector2(x - 11, bridge.end.y - 4), Color(1.0, 1.0, 1.0, opacity), 3.0)


func _draw_hazard(area: Rect2) -> void:
	var glow: float = 0.12 + 0.06 * sin(time * 6.0)
	draw_rect(area.grow(9.0), Color(1.0, 0.31, 0.24, glow))
	draw_rect(area, Color("692d34"))
	for x: float in range(int(area.position.x + 15), int(area.end.x), 26):
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(x - 12, area.position.y), Vector2(x, area.position.y - 26), Vector2(x + 12, area.position.y),
		])
		draw_colored_polygon(points, Color("e96d52"))
		draw_line(Vector2(x, area.position.y - 20), Vector2(x, area.position.y - 4), Color("ffcf9b"), 2.0)


func _draw_sentry_tracks() -> void:
	for data: Dictionary in level["sentries"]:
		var from: Vector2 = data["from"]
		var to: Vector2 = data["to"]
		draw_line(from, to, Color("f7f8f5", 0.85), 8.0)
		draw_line(from, to, Color("1b3e47", 0.85), 3.0)
		draw_circle(from, 8.0, INK)
		draw_circle(to, 8.0, INK)


func _draw_checkpoint(pos: Vector2) -> void:
	var pulse: float = sin(time * 4.0) * 3.0
	var color: Color = Color("28cce4") if checkpoint_active else Color("84979a")
	draw_line(pos + Vector2(0, 24), pos + Vector2(0, 73), INK, 14.0)
	draw_rect(Rect2(pos.x - 34, pos.y + 65, 68, 11), BRASS)
	draw_circle(pos, 45.0 + pulse, Color(color, 0.18))
	draw_arc(pos, 32.0, 0.0, TAU, 40, INK, 8.0, true)
	draw_circle(pos, 25.0, Color("23464a"))
	var crystal: PackedVector2Array = PackedVector2Array([
		pos + Vector2(0, -23), pos + Vector2(15, 0), pos + Vector2(0, 23), pos + Vector2(-15, 0),
	])
	draw_colored_polygon(crystal, color)
	if checkpoint_active:
		draw_circle(pos, 8.0 + pulse * 0.3, Color("ffffff"))


func _draw_shard(point: Vector2, index: int) -> void:
	var bob: float = sin(time * 2.8 + index * 2.1) * 8.0
	var pos: Vector2 = point + Vector2(0, bob)
	draw_circle(pos, 46.0, Color("20cce4", 0.13))
	draw_circle(pos, 33.0, Color("20cce4", 0.19))
	var star: PackedVector2Array = PackedVector2Array([
		pos + Vector2(0, -28), pos + Vector2(9, -9), pos + Vector2(25, 0), pos + Vector2(9, 9),
		pos + Vector2(0, 28), pos + Vector2(-9, 9), pos + Vector2(-25, 0), pos + Vector2(-9, -9),
	])
	draw_colored_polygon(star, Color("13b8d0"))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -19), pos + Vector2(9, 0), pos, pos + Vector2(-9, 0)]), Color("ffffff"))


func _draw_pad(pos: Vector2) -> void:
	var color: Color = Color("28cce4") if pad_armed else Color("a1b0b4")
	draw_rect(Rect2(pos.x - 58, pos.y - 8, 116, 24), INK)
	draw_rect(Rect2(pos.x - 48, pos.y - 17, 96, 18), color)
	draw_line(pos + Vector2(-34, -11), pos + Vector2(34, -11), Color("ffffff"), 3.0)
	for x: float in [-28.0, 0.0, 28.0]:
		draw_circle(pos + Vector2(x, -8), 4.0, BRASS)


func _draw_door(pos: Vector2) -> void:
	var aperture: Color = Color("bdf8ff") if door_open else Color("56686c")
	var pulse: float = 4.0 * sin(time * 3.0)
	draw_circle(pos, 83.0 + pulse, Color(aperture, 0.18))
	draw_arc(pos, 66.0, 0.0, TAU, 64, INK, 17.0, true)
	draw_arc(pos, 55.0, 0.0, TAU, 64, Color("20cce4"), 9.0, true)
	draw_arc(pos, 47.0, 0.0, TAU, 64, Color("ffffff"), 2.5, true)
	for index: int in range(8):
		var angle: float = time * (0.4 if door_open else 0.08) + float(index) * TAU / 8.0
		var vector: Vector2 = Vector2.RIGHT.rotated(angle)
		draw_circle(pos + vector * 56.0, 4.0, Color("ef6a3d"))
	draw_circle(pos, 39.0, aperture)
	if door_open:
		draw_circle(pos, 25.0 + pulse, Color("ffffff"))
	else:
		draw_line(pos + Vector2(-14, -14), pos + Vector2(14, 14), Color("d6e6e8"), 6.0)
		draw_line(pos + Vector2(14, -14), pos + Vector2(-14, 14), Color("d6e6e8"), 6.0)


func _draw_motes() -> void:
	for index: int in range(18):
		var x: float = 170.0 + fposmod(float(index * 191) + time * (8.0 + float(index % 4) * 3.0), 1570.0)
		var y: float = 205.0 + float((index * 137) % 660) + sin(time * 0.9 + index) * 15.0
		draw_line(Vector2(x, y), Vector2(x + 11.0, y - 3.0), Color(0.08, 0.7, 0.78, 0.2), 2.0)
