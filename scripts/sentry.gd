class_name PalewheelWatcher
extends Area2D

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
	var color: Color = Color("7ba49a") if freeze_remaining > 0.0 else Color("ad6654")
	var flutter: float = sin(wing_age * 16.0) * 8.0
	for side: float in [-1.0, 1.0]:
		var wing: PackedVector2Array = PackedVector2Array([
			Vector2(side * 6, -7), Vector2(side * 28, -30 - flutter),
			Vector2(side * 42, -32 - flutter), Vector2(side * 38, -2),
			Vector2(side * 23, 8), Vector2(side * 6, 4),
		])
		draw_colored_polygon(wing, Color("493a37"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 10, -7), Vector2(side * 30, -25 - flutter),
			Vector2(side * 37, -25 - flutter), Vector2(side * 33, -3),
			Vector2(side * 21, 4),
		]), color)
		draw_line(Vector2(side * 13, -7), Vector2(side * 35, -16 - flutter), Color("f3dfbd"), 2.0, true)
		draw_line(Vector2(side * 23, -5), Vector2(side * 28, 3), Color("f3dfbd"), 2.0, true)
		draw_line(Vector2(side * 4, 4), Vector2(side * 11, 33), Color("493a37"), 3.0, true)
		draw_line(Vector2(side * 11, 33), Vector2(side * 16, 39), Color("d0b69a"), 2.0, true)
	draw_circle(Vector2(0, -1), 19.0, Color("493a37"))
	draw_circle(Vector2(0, -2), 16.0, Color("d8c6a5"))
	draw_circle(Vector2(-6, -4), 2.5, Color("382f2f"))
	draw_circle(Vector2(6, -4), 2.5, Color("382f2f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-5, 10), Vector2(5, 10), Vector2(0, 37)]), Color("5b5651"))
	draw_line(Vector2(0, 17), Vector2(0, 32), Color("e8ded0"), 1.5, true)
	if freeze_remaining > 0.0:
		for index: int in range(5):
			var p: Vector2 = Vector2.from_angle(float(index) * TAU / 5.0) * 48.0
			draw_line(p + Vector2(-4, -4), p + Vector2(4, 4), Color("588d86", 0.75), 2.0, true)
