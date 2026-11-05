class_name PalewheelFerry
extends AnimatableBody2D

const FELT: Texture2D = preload("res://assets/art/felt_tile.png")
const INK: Color = Color("493a37")

var start_point: Vector2
var end_point: Vector2
var platform_size: Vector2 = Vector2(220, 30)
var period: float = 4.0
var elapsed: float = 0.0
var active: bool = false


func configure(data: Dictionary) -> void:
	start_point = data["from"]
	end_point = data["to"]
	platform_size = data["size"]
	period = data["period"]
	position = start_point


func _ready() -> void:
	collision_layer = 1
	collision_mask = 6
	sync_to_physics = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = platform_size
	shape.shape = box
	add_child(shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var fraction: float = (1.0 - cos(elapsed * TAU / period)) * 0.5
	position = start_point.lerp(end_point, fraction)
	queue_redraw()


func _draw() -> void:
	var body: Rect2 = Rect2(-platform_size * 0.5, platform_size)
	draw_rect(body.grow(5), INK)
	draw_texture_rect(FELT, body, true, Color("a9bba6"))
	draw_line(body.position + Vector2(9, 7), Vector2(body.end.x - 9, body.position.y + 7), Color("f7e7cb"), 2.0, true)
	for x: int in range(int(body.position.x + 14), int(body.end.x - 8), 17):
		draw_line(Vector2(x, body.end.y - 7), Vector2(x + 7, body.end.y - 7), Color("675a4d"), 2.0, true)
	for side: float in [-1.0, 1.0]:
		var anchor: Vector2 = Vector2(side * (platform_size.x * 0.5 - 16), 0)
		draw_circle(anchor, 7.0, INK)
		draw_circle(anchor, 3.0, Color("d6b78d"))
