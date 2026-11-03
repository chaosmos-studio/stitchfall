class_name StitchedActor
extends Node2D

const OUTLINE: Color = Color("493b37")
const CREAM: Color = Color("eee1c4")
const SHADOW: Color = Color("b89c78")
const COAT: Color = Color("ad654f")
const COAT_DARK: Color = Color("814a43")
const THREAD: Color = Color("f8e9ca")
const INK: Color = Color("312d2c")

var action: String = "idle"
var speed: float = 0.0
var facing: float = 1.0
var age: float = 0.0
var shift_age: float = 0.0


func _process(delta: float) -> void:
	age += delta * (1.0 + speed * 0.8)
	shift_age = maxf(0.0, shift_age - delta)
	queue_redraw()


func _draw() -> void:
	var stride: float = sin(age * 17.0) * speed
	var bounce: float = absf(sin(age * 17.0)) * speed * 3.0
	var crouch: float = 13.0 if action == "crouch" else 0.0
	var flight: float = -3.0 if action in ["takeoff", "rise", "apex"] else 0.0
	var squash: float = 4.0 if action == "land" else 0.0
	var bob: float = bounce + crouch + flight + squash + sin(age * 2.3) * 0.7
	var tilt: float = stride * 0.05
	var ear_sway: float = sin(age * 5.2) * 1.8 + stride * 2.0
	if shift_age > 0.0:
		tilt += sin((0.26 - shift_age) * 22.0) * 0.09
	_draw_tail(Vector2(-facing * 25.0, -3.0 + bob), stride)
	_draw_leg(-1.0, bob, stride, crouch)
	_draw_leg(1.0, bob, -stride, crouch)
	_draw_arm(-1.0, bob, -stride)
	_draw_arm(1.0, bob, stride)
	_draw_body(bob, tilt)
	_draw_head(bob, ear_sway)
	if shift_age > 0.0:
		var flash: float = shift_age / 0.26
		for index: int in range(5):
			var angle: float = float(index) * TAU / 5.0 + age * 2.0
			var from: Vector2 = Vector2.from_angle(angle) * (34.0 + (1.0 - flash) * 15.0)
			draw_line(from, from + Vector2.from_angle(angle) * 9.0, Color(0.99, 0.88, 0.67, flash), 2.0, true)


func _draw_tail(root: Vector2, stride: float) -> void:
	var tip: Vector2 = root + Vector2(-facing * (23.0 + sin(age * 4.0) * 3.0), -10.0 + stride * 3.0)
	var vertices: PackedVector2Array = PackedVector2Array([
		root + Vector2(0, -7), root + Vector2(-facing * 15, -9),
		tip + Vector2(0, -10), tip + Vector2(-facing * 10, 0),
		tip + Vector2(0, 9), root + Vector2(0, 6),
	])
	draw_colored_polygon(vertices, OUTLINE)
	draw_colored_polygon(PackedVector2Array([
		root + Vector2(-facing * 2, -5), tip + Vector2(0, -6),
		tip + Vector2(-facing * 6, 0), tip + Vector2(0, 5),
		root + Vector2(-facing * 2, 4),
	]), SHADOW)
	draw_line(root + Vector2(-facing * 8, -6), tip + Vector2(facing * 3, -3), THREAD, 2.0, true)


func _draw_leg(side: float, bob: float, swing: float, crouch: float) -> void:
	var hip: Vector2 = Vector2(side * 11.0, 11.0 + bob)
	var foot: Vector2 = Vector2(side * 13.0 + swing * 10.0, 35.0 + crouch * 0.2)
	if action in ["takeoff", "rise", "apex"]:
		foot.y = 27.0 + side * 5.0
	elif action == "fall":
		foot.y = 32.0 + side * 2.0
	draw_line(hip, foot + Vector2(0, -5), OUTLINE, 14.0, true)
	draw_line(hip, foot + Vector2(0, -5), COAT_DARK, 10.0, true)
	draw_circle(foot, 9.0, OUTLINE)
	draw_circle(foot + Vector2(1, -2), 6.0, SHADOW)
	draw_line(foot + Vector2(-4, -3), foot + Vector2(5, -3), THREAD, 1.5, true)


func _draw_arm(side: float, bob: float, swing: float) -> void:
	var shoulder: Vector2 = Vector2(side * 19.0, -12.0 + bob)
	var hand: Vector2 = Vector2(side * (26.0 + swing * 3.0), 8.0 + bob - swing * 8.0)
	if action in ["takeoff", "rise", "apex", "shift"]:
		hand = Vector2(side * 32.0, -20.0 + bob + side * 3.0)
	draw_line(shoulder, hand, OUTLINE, 14.0, true)
	draw_line(shoulder, hand, COAT, 10.0, true)
	draw_circle(hand, 7.0, OUTLINE)
	draw_circle(hand, 4.7, CREAM)
	draw_line(hand + Vector2(-3, 1), hand + Vector2(3, 1), SHADOW, 1.4, true)


func _draw_body(bob: float, tilt: float) -> void:
	var torso: PackedVector2Array = PackedVector2Array([
		Vector2(-21, -23 + bob), Vector2(0 + tilt * 20.0, -29 + bob),
		Vector2(21, -23 + bob), Vector2(27, 8 + bob),
		Vector2(19, 21 + bob), Vector2(-19, 21 + bob), Vector2(-27, 8 + bob),
	])
	draw_colored_polygon(torso, OUTLINE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -20 + bob), Vector2(0, -25 + bob), Vector2(18, -20 + bob),
		Vector2(23, 8 + bob), Vector2(17, 17 + bob),
		Vector2(-17, 17 + bob), Vector2(-23, 8 + bob),
	]), COAT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(2, -21 + bob), Vector2(17, -18 + bob),
		Vector2(20, 9 + bob), Vector2(5, 16 + bob),
	]), COAT_DARK)
	for y: int in [-12, -1, 10]:
		draw_line(Vector2(-19, y + bob), Vector2(-11, y + 2 + bob), THREAD, 2.0, true)
		draw_line(Vector2(12, y + 1 + bob), Vector2(19, y - 1 + bob), THREAD, 2.0, true)
	draw_circle(Vector2(0, 2 + bob), 8.0, OUTLINE)
	draw_circle(Vector2(0, 2 + bob), 6.0, Color("ddbd79"))
	for hole: int in range(4):
		draw_circle(Vector2.from_angle(float(hole) * TAU / 4.0 + PI * 0.25) * 3.0 + Vector2(0, 2 + bob), 1.3, OUTLINE)
	draw_line(Vector2(-7, -23 + bob), Vector2(9, -20 + bob), THREAD, 3.0, true)


func _draw_head(bob: float, ear_sway: float) -> void:
	var center: Vector2 = Vector2(0, -39 + bob)
	for side: float in [-1.0, 1.0]:
		var tip: Vector2 = center + Vector2(side * (16.0 + ear_sway * 0.25), -34.0 + ear_sway * side)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 7, -10), tip + Vector2(-side * 7, -4),
			tip, center + Vector2(side * 22, -7),
		]), OUTLINE)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 11, -11), tip + Vector2(-side * 3, -2),
			center + Vector2(side * 19, -8),
		]), Color("c99379"))
	draw_circle(center + Vector2(1, 2), 27.0, OUTLINE)
	draw_circle(center, 24.0, CREAM)
	draw_arc(center + Vector2(-8, 8), 12.0, PI * 0.3, PI * 1.1, 14, SHADOW, 2.0, true)
	draw_arc(center + Vector2(11, 5), 10.0, -0.3, PI * 0.8, 14, SHADOW, 1.6, true)
	var blink: bool = fposmod(age, 4.7) > 4.57
	var eye_offset: float = facing * 2.0
	for x: float in [-9.0, 9.0]:
		var eye: Vector2 = center + Vector2(x + eye_offset, -1)
		if blink:
			draw_line(eye + Vector2(-3, 0), eye + Vector2(3, 0), INK, 2.0, true)
		else:
			draw_circle(eye, 3.4, INK)
			draw_circle(eye + Vector2(-1, -1), 1.0, THREAD)
	draw_circle(center + Vector2(0, 10), 3.6, COAT_DARK)
	draw_line(center + Vector2(-3, 15), center + Vector2(3, 15), SHADOW, 1.6, true)
	for side: float in [-1.0, 1.0]:
		draw_line(center + Vector2(side * 22, 1), center + Vector2(side * 16, 3), SHADOW, 1.5, true)
		draw_line(center + Vector2(side * 20, 10), center + Vector2(side * 14, 12), SHADOW, 1.5, true)
