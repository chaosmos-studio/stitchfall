class_name StitchfallPageDots
extends Control

# A row of small sewn dots under the Levels page: which chapter is open, which are sewn through, and which are
# still shut. It only shows where you are; the arrows and a swipe turn the page.

const INK: Color = Color("493a37")
const ACCENT: Color = Color("a85648")
const STEP: float = 36.0

var count: int = 0
var current: int = 0
# 2 for a chapter with every room sewn, 1 for one begun or open, 0 for one still shut.
var states: PackedInt32Array = PackedInt32Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var left: float = (size.x - STEP * float(count - 1)) * 0.5
	for index: int in range(count):
		var center: Vector2 = Vector2(left + STEP * index, size.y * 0.5)
		var state: int = states[index] if index < states.size() else 0
		if index == current:
			draw_circle(center, 13.0, ACCENT)
			draw_circle(center, 6.0, Color("f7edda"))
		elif state == 2:
			draw_circle(center, 8.0, INK)
		elif state == 1:
			draw_arc(center, 8.0, 0.0, TAU, 20, INK, 2.5, true)
		else:
			draw_arc(center, 7.0, 0.0, TAU, 20, Color(INK, 0.35), 2.0, true)
