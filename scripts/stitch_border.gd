class_name StitchBorder
extends Control

var thread_color: Color = Color("896b57", 0.75)
var inset: float = 10.0
var spacing: float = 15.0
var biome: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var left: float = inset
	var top: float = inset
	var right: float = size.x - inset
	var bottom: float = size.y - inset
	if right <= left or bottom <= top:
		return
	for x: int in range(int(left + 7), int(right - 7), int(spacing)):
		draw_line(Vector2(x, top), Vector2(x + 7, top), thread_color, 1.5, true)
		draw_line(Vector2(x, bottom), Vector2(x + 7, bottom), thread_color, 1.5, true)
	for y: int in range(int(top + 7), int(bottom - 7), int(spacing)):
		draw_line(Vector2(left, y), Vector2(left, y + 7), thread_color, 1.5, true)
		draw_line(Vector2(right, y), Vector2(right, y + 7), thread_color, 1.5, true)
	for point: Vector2 in [Vector2(left, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]:
		draw_circle(point, 2.5, thread_color)
	_draw_motif(Vector2(right - 15.0, top + 12.0))


func _draw_motif(center: Vector2) -> void:
	match biome:
		4:
			for index: int in range(2):
				draw_arc(center + Vector2(index * 8.0, 0), 5.0, 0.0, PI, 12, thread_color, 1.5, true)
		5:
			draw_line(center + Vector2(-8, 3), center + Vector2(8, -4), thread_color, 1.5, true)
			draw_line(center + Vector2(-5, 7), center + Vector2(8, 1), thread_color, 1.5, true)
		6:
			draw_colored_polygon(PackedVector2Array([center + Vector2(-5, 5), center + Vector2(0, -6), center + Vector2(6, -2), center + Vector2(3, 5)]), thread_color)
			draw_line(center + Vector2(-4, 5), center + Vector2(4, -3), Color("f6ecd3"), 1.0, true)
		7:
			for angle: float in [0.0, PI * 0.5]:
				var d: Vector2 = Vector2.from_angle(angle) * 7.0
				draw_line(center - d, center + d, thread_color, 1.5, true)
		8:
			for index: int in range(3):
				var point: Vector2 = center + Vector2(index * 6.0 - 7.0, index % 2 * 3.0)
				draw_line(point, point + Vector2(3, 8), thread_color, 1.5, true)
		9:
			for angle: float in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
				var d: Vector2 = Vector2.from_angle(angle) * 7.0
				draw_line(center - d, center + d, thread_color, 1.5, true)
