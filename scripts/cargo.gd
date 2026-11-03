class_name PalewheelCargo
extends RigidBody2D

var gravity_direction: Vector2 = Vector2.DOWN
var glow_time: float = 0.0


func _ready() -> void:
	gravity_scale = 0.0
	mass = 3.0
	linear_damp = 1.5
	angular_damp = 5.0
	lock_rotation = true
	collision_layer = 4
	collision_mask = 3
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(68, 68)
	shape.shape = box
	add_child(shape)
	can_sleep = false
	queue_redraw()


func _physics_process(delta: float) -> void:
	apply_central_force(gravity_direction * 1050.0 * mass)
	glow_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-42, -39, 84, 84), Color("5d4b40", 0.22))
	draw_rect(Rect2(-39, -39, 78, 78), Color("493a37"))
	draw_rect(Rect2(-35, -35, 70, 70), Color("bd9778"))
	draw_rect(Rect2(-29, -29, 58, 58), Color("cba98b"))
	for x: int in range(-26, 28, 13):
		draw_line(Vector2(x, -32), Vector2(x + 6, -32), Color("f7e8c9"), 2.0, true)
		draw_line(Vector2(x, 32), Vector2(x + 6, 32), Color("f7e8c9"), 2.0, true)
	for y: int in range(-25, 28, 13):
		draw_line(Vector2(-32, y), Vector2(-32, y + 6), Color("f7e8c9"), 2.0, true)
		draw_line(Vector2(32, y), Vector2(32, y + 6), Color("f7e8c9"), 2.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -22), Vector2(17, -22), Vector2(21, 0), Vector2(0, 22), Vector2(-21, 0)]), Color("ad6654"))
	draw_line(Vector2(-12, -15), Vector2(11, 14), Color("f7e8c9"), 2.0, true)
	draw_line(Vector2(11, -15), Vector2(-12, 14), Color("f7e8c9"), 2.0, true)
	draw_circle(Vector2.ZERO, 5.0, Color("e4c883"))
