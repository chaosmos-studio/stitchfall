class_name PalewheelMechanism
extends Area2D

signal struck(body: Node2D)
signal launched(body: Node2D)

const INK: Color = Color("493a37")
const BRASS: Color = Color("b88052")
const THREAD: Color = Color("f6e6c9")

var kind: String = "cutter"
var start_point: Vector2
var end_point: Vector2
var anchor: Vector2
var period: float = 3.0
var elapsed: float = 0.0
var warning: float = 0.0
var active: bool = false
var shift_armed: bool = false


func configure(data: Dictionary) -> void:
	kind = data["kind"]
	start_point = data["from"]
	end_point = data.get("to", start_point)
	anchor = data.get("anchor", start_point + Vector2(0, -220))
	period = float(data.get("period", 3.0))
	shift_armed = bool(data.get("shift_armed", false))
	position = start_point


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 46.0 if kind == "pulley" else 39.0
	if kind == "spring":
		circle.radius = 52.0
	elif kind == "chain":
		circle.radius = 62.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func arm() -> void:
	if shift_armed:
		warning = 0.55
		elapsed = 0.0001
		queue_redraw()


func reset() -> void:
	elapsed = 0.0
	warning = 0.0
	position = start_point
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active:
		return
	if warning > 0.0:
		warning = maxf(0.0, warning - delta)
		queue_redraw()
		return
	if not shift_armed or elapsed > 0.0:
		elapsed += delta
	if kind != "spring":
		var progress: float = (1.0 - cos(elapsed * TAU / period)) * 0.5
		position = start_point.lerp(end_point, progress)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not active or warning > 0.0:
		return
	if kind == "spring":
		launched.emit(body)
	elif not shift_armed or elapsed > 0.0:
		struck.emit(body)


func _draw() -> void:
	if kind == "spring":
		_draw_spring()
		return
	var line_to_anchor: Vector2 = anchor - position
	if kind == "pulley":
		draw_line(Vector2.ZERO, line_to_anchor, INK, 7.0, true)
		draw_line(Vector2.ZERO, line_to_anchor, THREAD, 3.0, true)
		draw_circle(line_to_anchor, 16.0, INK)
		draw_circle(line_to_anchor, 10.0, BRASS)
		_draw_weight()
	elif kind == "chain":
		draw_line(start_point - position, end_point - position, Color("876c5c", 0.68), 3.0, true)
		_draw_chain()
	else:
		draw_line(start_point - position, end_point - position, Color("876c5c", 0.68), 3.0, true)
		_draw_cutter()
	if warning > 0.0:
		draw_arc(Vector2.ZERO, 58.0, -PI * 0.75, PI * 0.75, 24, Color("d46546"), 5.0, true)
		draw_circle(Vector2.ZERO, 5.0, Color("d46546"))


func _draw_cutter() -> void:
	var angle: float = elapsed * TAU * 1.9
	draw_circle(Vector2.ZERO, 38.0, INK)
	for index: int in range(12):
		var a: float = angle + float(index) * TAU / 12.0
		var root: Vector2 = Vector2.from_angle(a) * 34.0
		var tip: Vector2 = Vector2.from_angle(a + 0.12) * 50.0
		draw_colored_polygon(PackedVector2Array([root, tip, Vector2.from_angle(a + 0.37) * 35.0]), Color("a4a9a0"))
		draw_line(root, tip, THREAD, 1.5, true)
	draw_circle(Vector2.ZERO, 27.0, BRASS)
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, THREAD, 2.0, true)
	draw_circle(Vector2.ZERO, 8.0, INK)
	draw_circle(Vector2.ZERO, 4.0, THREAD)


func _draw_weight() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-44, -32), Vector2(44, -32), Vector2(39, 36), Vector2(-39, 36)]), INK)
	draw_colored_polygon(PackedVector2Array([Vector2(-38, -27), Vector2(38, -27), Vector2(33, 29), Vector2(-33, 29)]), Color("af8b70"))
	for x: int in [-24, 0, 24]:
		draw_line(Vector2(x, -22), Vector2(x, 23), Color("d7ba95"), 2.0, true)
	draw_circle(Vector2.ZERO, 8.0, INK)
	draw_circle(Vector2.ZERO, 4.0, THREAD)


func _draw_chain() -> void:
	draw_rect(Rect2(-62, -25, 124, 50), INK)
	draw_rect(Rect2(-55, -18, 110, 36), BRASS)
	for index: int in range(8):
		var x: float = -52.0 + float(index) * 15.0
		var move: float = fmod(elapsed * 38.0, 15.0)
		draw_arc(Vector2(x + move, -21), 6.0, PI, TAU, 7, Color("a6aca5"), 5.0, true)
		draw_arc(Vector2(x - move, 21), 6.0, 0.0, PI, 7, Color("a6aca5"), 5.0, true)
	draw_circle(Vector2(-40, 0), 12.0, INK)
	draw_circle(Vector2(40, 0), 12.0, INK)
	draw_circle(Vector2(-40, 0), 5.0, THREAD)
	draw_circle(Vector2(40, 0), 5.0, THREAD)


func _draw_spring() -> void:
	draw_rect(Rect2(-53, 8, 106, 18), INK)
	draw_rect(Rect2(-48, 10, 96, 12), BRASS)
	var top: float = 1.5 + sin(elapsed * 11.0) * 1.5
	for index: int in range(5):
		var x: float = -43.0 + float(index) * 21.0
		draw_polyline(PackedVector2Array([Vector2(x, 9), Vector2(x + 6, -10 + top), Vector2(x + 13, 8)]), INK, 4.0, true)
	draw_rect(Rect2(-58, -17 + top, 116, 12), INK)
	draw_rect(Rect2(-52, -15 + top, 104, 7), Color("d9a983"))
	for x: int in range(-43, 48, 18):
		draw_line(Vector2(x, -10 + top), Vector2(x + 7, -10 + top), THREAD, 1.5, true)
