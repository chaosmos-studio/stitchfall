class_name PalewheelWatcher
extends Area2D

const MOTH: Texture2D = preload("res://assets/art/needle_moth.png")

var start_point: Vector2
var end_point: Vector2
var period: float = 3.0
var phase_offset: float = 0.0
var elapsed: float = 0.0
var freeze_remaining: float = 0.0
var active: bool = false
var wing_age: float = 0.0


func configure(data: Dictionary) -> void:
	start_point = data["from"]
	end_point = data["to"]
	period = data["period"]
	phase_offset = data["offset"]
	position = start_point.lerp(end_point, 0.5 + 0.5 * sin(phase_offset))


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 39.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active:
		return
	if freeze_remaining > 0.0:
		freeze_remaining = maxf(0.0, freeze_remaining - delta)
		if freeze_remaining == 0.0:
			set_deferred("monitoring", true)
	else:
		elapsed += delta
		position = start_point.lerp(end_point, 0.5 + 0.5 * sin(elapsed * TAU / period + phase_offset))
	if freeze_remaining <= 0.0:
		wing_age += delta
	queue_redraw()


func freeze_for(seconds: float) -> void:
	freeze_remaining = maxf(freeze_remaining, seconds)
	set_deferred("monitoring", false)
	queue_redraw()


func _draw() -> void:
	var flutter: float = sin(wing_age * 14.0)
	var tint: Color = Color("94bec1") if freeze_remaining > 0.0 else Color.WHITE
	draw_set_transform(Vector2(0, flutter * 1.5), flutter * 0.025, Vector2(1.0 + flutter * 0.035, 1.0 - flutter * 0.025))
	draw_texture_rect(MOTH, Rect2(-61, -48, 122, 96), false, tint)
	draw_set_transform(Vector2.ZERO)
	if freeze_remaining > 0.0:
		for index: int in range(5):
			var p: Vector2 = Vector2.from_angle(float(index) * TAU / 5.0) * 48.0
			draw_line(p + Vector2(-4, -4), p + Vector2(4, 4), Color("588d86", 0.75), 2.0, true)
