class_name PalewheelWorldView
extends Node2D

const BACKDROPS: Array = [
	preload("res://assets/art/station.webp"),
	preload("res://assets/art/station_sensor.webp"),
	preload("res://assets/art/station_freight.webp"),
	preload("res://assets/art/station_core.webp"),
	preload("res://assets/art/station_water.webp"),
	preload("res://assets/art/station_dunes.webp"),
	preload("res://assets/art/station_forest.webp"),
	preload("res://assets/art/station_space.webp"),
]
const AIRLOCK_CLOSED: Texture2D = preload("res://assets/art/airlock_closed.png")
const AIRLOCK_OPEN: Texture2D = preload("res://assets/art/airlock_open.png")
const LIGHT_CELL: Texture2D = preload("res://assets/art/light_cell.png")
const BEACON: Texture2D = preload("res://assets/art/beacon.png")
const EXHAUST_VENT: Texture2D = preload("res://assets/art/exhaust_vent.png")
const CELL_OFFSETS: Array[float] = [0.0, -1.0, -2.0, -3.0, -3.0, -2.0, -1.0, 0.0]
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
var door_progress: float = 0.0
var spark_bursts: Array[Dictionary] = []


func _process(delta: float) -> void:
	time += delta
	shift_age += delta
	door_progress = move_toward(door_progress, 1.0 if door_open else 0.0, delta * 3.5)
	for index: int in range(spark_bursts.size() - 1, -1, -1):
		spark_bursts[index]["age"] += delta
		if spark_bursts[index]["age"] > 0.48:
			spark_bursts.remove_at(index)
	queue_redraw()


func _draw() -> void:
	var backdrop_index: int = clampi(int(level.get("backdrop", 0)), 0, BACKDROPS.size() - 1)
	draw_texture_rect(BACKDROPS[backdrop_index] as Texture2D, Rect2(-330, -180, 2580, 1440), false)
	draw_rect(Rect2(-330, -180, 2580, 1440), Color("f5f7f4", 0.04))
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
	_draw_motes()
	_draw_spark_bursts()
	if shift_age < 0.62:
		var radius: float = 36.0 + shift_age * 710.0
		var opacity: float = (0.62 - shift_age) / 0.62
		draw_arc(shift_origin, radius, 0.0, TAU, 96, Color(0.03, 0.77, 0.88, opacity * 0.8), 10.0, true)
		draw_arc(shift_origin, radius + 26.0, 0.0, TAU, 96, Color(0.04, 0.12, 0.16, opacity * 0.5), 3.0, true)


func _draw_chamber() -> void:
	draw_rect(Rect2(110, 168, 1700, 760), Color("f5f8f6", 0.15))


func _draw_environment() -> void:
	var kind: String = level.get("environment", "")
	var zone: Rect2 = level.get("environment_zone", Rect2())
	if zone.has_area() == false:
		return
	match kind:
		"water":
			draw_rect(zone, Color("348da9", 0.23))
			for x: int in range(int(zone.position.x), int(zone.end.x), 20):
				var ripple: float = sin(float(x) * 0.025 + time * 2.8) * 5.0
				var next_ripple: float = sin(float(x + 20) * 0.025 + time * 2.8) * 5.0
				draw_line(Vector2(x, zone.position.y + ripple), Vector2(x + 20, zone.position.y + next_ripple), Color("d4f9f3", 0.88), 3.0)
			for index: int in range(18):
				var x: float = zone.position.x + fposmod(float(index * 79), zone.size.x)
				var y: float = zone.end.y - fposmod(float(index * 131) + time * (16.0 + float(index % 4) * 5.0), zone.size.y)
				draw_arc(Vector2(x, y), 3.0 + float(index % 3) * 2.0, 0.0, TAU, 12, Color("d4f9f3", 0.53), 2.0)
		"dunes":
			for index: int in range(22):
				var x: float = zone.position.x + fposmod(float(index * 103) + time * (95.0 + float(index % 4) * 18.0), zone.size.x)
				var y: float = zone.position.y + fposmod(float(index * 139), zone.size.y)
				draw_line(Vector2(x, y), Vector2(x + 43.0, y - 7.0), Color("f1cb88", 0.56), 2.0)
				draw_circle(Vector2(x + 49.0, y - 8.0), 2.0, Color("f1cb88", 0.62))
		"forest":
			for index: int in range(18):
				var x: float = zone.position.x + fposmod(float(index * 83) + sin(time * 1.3 + float(index)) * 22.0, zone.size.x)
				var y: float = zone.end.y - fposmod(float(index * 117) + time * (22.0 + float(index % 3) * 7.0), zone.size.y)
				draw_circle(Vector2(x, y), 3.0 + float(index % 3), Color("c9e9b5", 0.6))
				draw_line(Vector2(x - 8.0, y + 10.0), Vector2(x + 4.0, y - 8.0), Color("b6dc96", 0.32), 2.0)
		"space":
			for index: int in range(16):
				var x: float = zone.position.x + fposmod(float(index * 167), zone.size.x)
				var y: float = zone.position.y + fposmod(float(index * 107), zone.size.y)
				var shimmer: float = 0.25 + 0.25 * sin(time * 1.8 + float(index) * 1.6)
				draw_circle(Vector2(x, y), 2.0 + float(index % 3), Color(0.84, 0.94, 1.0, shimmer))


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
	var glow: float = 0.1 + 0.04 * sin(time * 5.0)
	draw_rect(area.grow(7.0), Color(1.0, 0.31, 0.19, glow))
	draw_texture_rect(EXHAUST_VENT, Rect2(area.position + Vector2(-7, -23), Vector2(area.size.x + 14, 52)), false)


func _draw_sentry_tracks() -> void:
	for data: Dictionary in level["sentries"]:
		var from: Vector2 = data["from"]
		var to: Vector2 = data["to"]
		draw_line(from, to, Color("f7f8f5", 0.85), 8.0)
		draw_line(from, to, Color("1b3e47", 0.85), 3.0)
		draw_circle(from, 8.0, INK)
		draw_circle(to, 8.0, INK)


func _draw_checkpoint(pos: Vector2) -> void:
	var color: Color = Color("28cce4", 0.22) if checkpoint_active else Color("17262d", 0.14)
	draw_circle(pos + Vector2(0, 6), 53.0, color)
	draw_texture_rect(BEACON, Rect2(pos + Vector2(-49, -65), Vector2(98, 140)), false, Color.WHITE if checkpoint_active else Color("77858a"))


func _draw_shard(point: Vector2, index: int) -> void:
	var frame: int = int(time * 6.0 + float(index) * 2.0) % 8
	var offset: float = CELL_OFFSETS[frame]
	var pos: Vector2 = point + Vector2(0, offset)
	draw_circle(pos, 49.0, Color("20cce4", 0.11))
	draw_texture_rect(LIGHT_CELL, Rect2(pos - Vector2(39, 43), Vector2(78, 86)), false)


func _draw_pad(pos: Vector2) -> void:
	var color: Color = Color("28cce4") if pad_armed else Color("a1b0b4")
	draw_rect(Rect2(pos.x - 58, pos.y - 8, 116, 24), INK)
	draw_rect(Rect2(pos.x - 48, pos.y - 17, 96, 18), color)
	draw_line(pos + Vector2(-34, -11), pos + Vector2(34, -11), Color("ffffff"), 3.0)
	for x: float in [-28.0, 0.0, 28.0]:
		draw_circle(pos + Vector2(x, -8), 4.0, BRASS)


func _draw_door(pos: Vector2) -> void:
	var rect: Rect2 = Rect2(pos - Vector2(93, 93), Vector2(186, 186))
	if door_progress > 0.0:
		draw_circle(pos, 88.0, Color("20cce4", door_progress * 0.18))
	draw_texture_rect(AIRLOCK_CLOSED, rect, false, Color(1.0, 1.0, 1.0, 1.0 - door_progress))
	if door_progress > 0.0:
		draw_texture_rect(AIRLOCK_OPEN, rect, false, Color(1.0, 1.0, 1.0, door_progress))


func collect_spark(pos: Vector2) -> void:
	spark_bursts.append({"position": pos, "age": 0.0})


func _draw_spark_bursts() -> void:
	for burst: Dictionary in spark_bursts:
		var age: float = burst["age"]
		var center: Vector2 = burst["position"]
		var reach: float = 20.0 + age * 170.0
		var fade: float = 1.0 - age / 0.48
		for index: int in range(10):
			var ray: Vector2 = Vector2.RIGHT.rotated(float(index) * TAU / 10.0)
			draw_line(center + ray * (reach - 13.0), center + ray * reach, Color(0.89, 1.0, 1.0, fade), 3.0 * fade)


func _draw_motes() -> void:
	var backdrop_index: int = int(level.get("backdrop", 0))
	var mote_color: Color = Color(0.08, 0.7, 0.78, 0.2)
	var drift: Vector2 = Vector2(11.0, -3.0)
	if backdrop_index == 4:
		mote_color = Color(0.74, 0.95, 0.96, 0.29)
		drift = Vector2(3.0, -9.0)
	elif backdrop_index == 5:
		mote_color = Color(0.85, 0.59, 0.27, 0.27)
		drift = Vector2(14.0, 2.0)
	elif backdrop_index == 6:
		mote_color = Color(0.9, 0.86, 0.52, 0.25)
		drift = Vector2(4.0, -4.0)
	elif backdrop_index == 7:
		mote_color = Color(0.77, 0.88, 1.0, 0.4)
		drift = Vector2(-2.0, 0.0)
	for index: int in range(18):
		var x: float = 170.0 + fposmod(float(index * 191) + time * (8.0 + float(index % 4) * 3.0), 1570.0)
		var y: float = 205.0 + float((index * 137) % 660) + sin(time * 0.9 + index) * 15.0
		draw_line(Vector2(x, y), Vector2(x, y) + drift, mote_color, 2.0)
