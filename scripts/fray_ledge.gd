class_name StitchfallFrayLedge
extends StaticBody2D

const FELT: Texture2D = preload("res://assets/art/felt_tile.png")
const INK: Color = Color("493a37")
const THREAD: Color = Color("f6e6c9")

var size: Vector2 = Vector2(260, 28)
var delay: float = 0.6
var countdown: float = 0.0
var collapsed: bool = false
var active: bool = false
var collision_shape: CollisionShape2D
var detector: Area2D


func configure(data: Dictionary) -> void:
	var rect: Rect2 = data["rect"]
	position = rect.get_center()
	size = rect.size
	delay = float(data.get("delay", 0.6))


func _ready() -> void:
	collision_layer = 1
	collision_mask = 6
	collision_shape = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = size
	collision_shape.shape = box
	add_child(collision_shape)
	detector = Area2D.new()
	detector.collision_layer = 0
	detector.collision_mask = 2
	var sensing_shape: CollisionShape2D = CollisionShape2D.new()
	var sensing_box: RectangleShape2D = RectangleShape2D.new()
	sensing_box.size = size + Vector2(0, 44)
	sensing_shape.shape = sensing_box
	detector.add_child(sensing_shape)
	add_child(detector)
	detector.body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active or collapsed or countdown <= 0.0:
		return
	countdown = maxf(0.0, countdown - delta)
	if countdown == 0.0:
		collapsed = true
		collision_shape.set_deferred("disabled", true)
		detector.set_deferred("monitoring", false)
	queue_redraw()


func _on_body_entered(_body: Node2D) -> void:
	if active and not collapsed and countdown == 0.0:
		countdown = delay
		queue_redraw()


func reset() -> void:
	countdown = 0.0
	collapsed = false
	collision_shape.set_deferred("disabled", false)
	detector.set_deferred("monitoring", true)
	queue_redraw()


func _draw() -> void:
	var fabric: Rect2 = Rect2(-size * 0.5, size)
	var opacity: float = 0.3 if collapsed else 1.0
	draw_rect(fabric.grow(5.0), Color("5f4b40", opacity))
	draw_texture_rect(FELT, fabric, true, Color("d9aa82", opacity))
	var stitch_count: int = maxi(2, int(size.x / 17.0))
	for stitch: int in range(stitch_count):
		var x: float = fabric.position.x + 11.0 + float(stitch) * (size.x - 20.0) / float(stitch_count - 1)
		var upper: Vector2 = Vector2(x, fabric.position.y + 5.0)
		var lower: Vector2 = Vector2(x + 7.0, fabric.end.y - 5.0)
		var loosen: float = 0.0 if countdown == 0.0 else (1.0 - countdown / delay) * 16.0
		draw_line(upper, lower + Vector2(0, loosen), THREAD * Color(1, 1, 1, opacity), 2.0, true)
		if countdown > 0.0 and stitch % 3 == 0:
			draw_circle(lower + Vector2(0, loosen), 2.5, INK)
	if countdown > 0.0:
		draw_line(fabric.position + Vector2(4, -9), fabric.position + Vector2(4 + (size.x - 8.0) * countdown / delay, -9), Color("c75843"), 5.0, true)
