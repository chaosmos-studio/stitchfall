class_name PalewheelMechanism
extends Area2D

signal struck(body: Node2D)
signal launched(body: Node2D)

const INK: Color = Color("493a37")
const BRASS: Color = Color("b88052")
const THREAD: Color = Color("f6e6c9")
const CUTTER: Texture2D = preload("res://assets/art/props/rotary_cutter.png")
const WEIGHT: Texture2D = preload("res://assets/art/props/pulley_weight.png")
const SPRING: Texture2D = preload("res://assets/art/props/spring_pad.png")
const CHAIN: Texture2D = preload("res://assets/art/props/chain_cutter.png")

var kind: String = "cutter"
var start_point: Vector2
var end_point: Vector2
var anchor: Vector2
var period: float = 3.0
var elapsed: float = 0.0
var warning: float = 0.0
var active: bool = false
var shift_armed: bool = false
var trigger_point: Vector2 = Vector2.ZERO
var trigger_radius: float = 100.0
var trigger_armed: bool = false
var triggered: bool = false


func configure(data: Dictionary) -> void:
	kind = data["kind"]
	start_point = data["from"]
	end_point = data.get("to", start_point)
	anchor = data.get("anchor", start_point + Vector2(0, -220))
	period = float(data.get("period", 3.0))
	shift_armed = bool(data.get("shift_armed", false))
	trigger_point = data.get("trigger", Vector2.ZERO)
	trigger_radius = float(data.get("trigger_radius", 100.0))
	trigger_armed = trigger_point != Vector2.ZERO
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
	if trigger_armed:
		var trigger: Area2D = Area2D.new()
		trigger.position = trigger_point - start_point
		trigger.collision_layer = 0
		trigger.collision_mask = 2
		var trigger_shape: CollisionShape2D = CollisionShape2D.new()
		var trigger_circle: CircleShape2D = CircleShape2D.new()
		trigger_circle.radius = trigger_radius
		trigger_shape.shape = trigger_circle
		trigger.add_child(trigger_shape)
		add_child(trigger)
		trigger.body_entered.connect(_on_trigger_body)
	queue_redraw()


func arm() -> void:
	if shift_armed or (trigger_armed and not triggered):
		triggered = trigger_armed
		warning = 0.55
		elapsed = 0.0001
		queue_redraw()


func reset() -> void:
	elapsed = 0.0
	warning = 0.0
	triggered = false
	position = start_point
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active:
		return
	if warning > 0.0:
		warning = maxf(0.0, warning - delta)
		queue_redraw()
		return
	if (not shift_armed and not trigger_armed) or elapsed > 0.0:
		elapsed += delta
	if kind != "spring":
		var progress: float = (1.0 - cos(elapsed * TAU / period)) * 0.5
		position = start_point.lerp(end_point, progress)
	queue_redraw()


func _on_trigger_body(_body: Node2D) -> void:
	if active and not triggered:
		arm()


func _on_body_entered(body: Node2D) -> void:
	if not active or warning > 0.0:
		return
	if kind == "spring":
		launched.emit(body)
	elif (not shift_armed and not trigger_armed) or elapsed > 0.0:
		struck.emit(body)


func _draw() -> void:
	if trigger_armed:
		var mark: Vector2 = trigger_point - position
		draw_arc(mark, 25.0, 0.0, TAU, 18, Color("8e6954", 0.8), 3.0, true)
		draw_line(mark + Vector2(-11, -11), mark + Vector2(11, 11), THREAD, 3.0, true)
		draw_line(mark + Vector2(11, -11), mark + Vector2(-11, 11), THREAD, 3.0, true)
	if kind == "spring":
		_draw_spring()
		return
	var line_to_anchor: Vector2 = anchor - position
	if kind == "pulley":
		draw_line(Vector2(0, -47), line_to_anchor, INK, 7.0, true)
		draw_line(Vector2(0, -47), line_to_anchor, THREAD, 3.0, true)
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
	draw_set_transform(Vector2.ZERO, elapsed * TAU * 1.9)
	draw_texture_rect(CUTTER, Rect2(-52, -52, 104, 104), false)
	draw_set_transform(Vector2.ZERO)


func _draw_weight() -> void:
	draw_texture_rect(WEIGHT, Rect2(-55, -55, 110, 110), false)


func _draw_chain() -> void:
	draw_texture_rect(CHAIN, Rect2(-75, -34, 150, 68), false)


func _draw_spring() -> void:
	var bounce: float = sin(elapsed * 10.0) * 1.5
	draw_texture_rect(SPRING, Rect2(-70, -36 + bounce, 140, 70), false)
