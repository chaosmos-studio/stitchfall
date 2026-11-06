class_name StitchfallGestureGuide
extends Control

var kind: String = "move"
var time: float = 0.0

const INK: Color = Color("58483f")
const THREAD: Color = Color("a46f5b")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if visible:
		time += delta
		queue_redraw()


func _draw() -> void:
	var middle: Vector2 = size * 0.5
	var beat: float = fmod(time, 2.4) / 2.4
	var travel: float = sin(beat * TAU - PI * 0.5) * 0.5 + 0.5
	var hand: Vector2 = middle
	match kind:
		"move":
			_draw_path(middle + Vector2(-126, 22), middle + Vector2(126, 22))
			hand += Vector2(lerpf(-113.0, 113.0, travel), 23)
			_draw_arrow(middle + Vector2(141, 22), Vector2.RIGHT)
			_draw_arrow(middle + Vector2(-141, 22), Vector2.LEFT)
		"jump":
			_draw_path(middle + Vector2(0, 55), middle + Vector2(0, -45))
			hand += Vector2(0, lerpf(53.0, -43.0, travel))
			_draw_arrow(middle + Vector2(0, -61), Vector2.UP)
		"crouch":
			_draw_path(middle + Vector2(0, -46), middle + Vector2(0, 53))
			hand += Vector2(0, lerpf(-44.0, 51.0, travel))
			_draw_arrow(middle + Vector2(0, 67), Vector2.DOWN)
		"shift":
			var radius: float = 36.0 + 22.0 * (1.0 - absf(beat * 2.0 - 1.0))
			draw_arc(middle, radius, 0, TAU, 48, Color(THREAD, 0.6), 3.0, true)
			draw_arc(middle, 64.0, -PI * 0.45, PI * 0.03, 18, INK, 3.0, true)
			_draw_arrow(middle + Vector2(64, 0), Vector2.DOWN)
	_draw_hand(hand)


func _draw_path(start: Vector2, end: Vector2) -> void:
	var direction: Vector2 = (end - start).normalized()
	var length: float = start.distance_to(end)
	for step: int in range(int(length / 22.0)):
		var at: Vector2 = start + direction * float(step * 22)
		draw_line(at, at + direction * 12.0, Color(THREAD, 0.7), 3.0, true)


func _draw_arrow(point: Vector2, direction: Vector2) -> void:
	var sideways: Vector2 = direction.rotated(PI * 0.5)
	draw_colored_polygon(PackedVector2Array([
		point + direction * 12.0,
		point - direction * 11.0 + sideways * 8.0,
		point - direction * 11.0 - sideways * 8.0,
	]), THREAD)


func _draw_hand(point: Vector2) -> void:
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(-17, 31), Vector2(-24, 8), Vector2(-12, 2),
		Vector2(-8, 8), Vector2(-8, -29), Vector2(-3, -38),
		Vector2(6, -35), Vector2(8, -2), Vector2(17, -8),
		Vector2(25, -4), Vector2(26, 21), Vector2(16, 34),
	])
	var fill: PackedVector2Array = PackedVector2Array()
	for vertex: Vector2 in outline:
		fill.append(point + vertex)
	draw_colored_polygon(fill, INK)
	for vertex_index: int in range(fill.size()):
		fill[vertex_index] += (point - fill[vertex_index]).normalized() * 3.0
	draw_colored_polygon(fill, Color("f2d8bb"))
	draw_line(point + Vector2(-2, -28), point + Vector2(-2, 1), Color("fff1d8"), 2.0, true)
	draw_arc(point + Vector2(1, 11), 10.0, 0, PI, 12, THREAD, 2.0, true)
