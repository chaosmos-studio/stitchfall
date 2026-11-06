class_name StitchfallPin
extends CharacterBody2D

# A loose pincushion. It always falls the way gravity points, so every turn drops it onto a new floor,
# and it is all pins, so touching it from any side unravels the runner.

signal struck(body: Node2D)
signal landed

const ART: Texture2D = preload("res://assets/art/props/pincushion.png")
# The cushion's body, which rests on walls, and the reach of its pins, which is what hurts.
const BODY_RADIUS: float = 30.0
const PIN_RADIUS: float = 34.0
const DRAWN_SIZE: float = 96.0
const FALL_ACCELERATION: float = 1550.0
const MAX_FALL_SPEED: float = 1100.0
# A landing faster than this shakes the room.
const THUD_SPEED: float = 260.0
# How fast it tumbles while falling, in turns per second.
const TUMBLE: float = 1.6

var gravity_direction: Vector2 = Vector2.DOWN
# Where an unravel puts it back: its start, until a flower saves where it is now.
var start: Vector2 = Vector2.ZERO
var active: bool = false
var spin: float = 0.0


func configure(pos: Vector2) -> void:
	start = pos
	position = pos


func _ready() -> void:
	# Pins rest on walls and on each other, and pass through the runner, whom they hurt instead.
	collision_layer = 8
	collision_mask = 1 | 8
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = BODY_RADIUS
	shape.shape = circle
	add_child(shape)
	var pins: Area2D = Area2D.new()
	pins.collision_layer = 0
	pins.collision_mask = 2
	var reach: CollisionShape2D = CollisionShape2D.new()
	var reach_circle: CircleShape2D = CircleShape2D.new()
	reach_circle.radius = PIN_RADIUS
	reach.shape = reach_circle
	pins.add_child(reach)
	add_child(pins)
	pins.body_entered.connect(func(body: Node2D) -> void: struck.emit(body))


func _physics_process(delta: float) -> void:
	if not active:
		return
	velocity += gravity_direction * FALL_ACCELERATION * delta
	var along: float = minf(velocity.dot(gravity_direction), MAX_FALL_SPEED)
	velocity = gravity_direction * along
	var speed: float = velocity.length()
	var hit: KinematicCollision2D = move_and_collide(velocity * delta)
	if hit != null and hit.get_normal().dot(gravity_direction) < -0.5:
		velocity = Vector2.ZERO
		if speed > THUD_SPEED:
			landed.emit()
	if speed > 40.0:
		spin += TUMBLE * TAU * delta
	queue_redraw()


func reset(gravity: Vector2) -> void:
	position = start
	velocity = Vector2.ZERO
	gravity_direction = gravity
	spin = 0.0
	reset_physics_interpolation()
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
	draw_texture_rect(ART, Rect2(Vector2.ONE * -DRAWN_SIZE * 0.5, Vector2.ONE * DRAWN_SIZE), false)
	draw_set_transform(Vector2.ZERO)
