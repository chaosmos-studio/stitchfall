class_name StitchBorder
extends Control

var thread_color: Color = Color("896b57", 0.75)
var inset: float = 10.0
var spacing: float = 15.0


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
