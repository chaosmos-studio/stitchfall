class_name StitchfallFrayLedge
extends StaticBody2D

signal gave_way

const PATCH: Texture2D = preload("res://assets/art/props/unpinned_patch.png")
# The rows of the patch art that are the patch itself, above its hanging threads.
const PATCH_BODY_TOP: float = 22.0
const PATCH_BODY_BOTTOM: float = 68.0
const DROP_TIME: float = 0.6
const THREAD: Color = Color("f6e6c9")

var size: Vector2 = Vector2(260, 28)
var delay: float = 0.6
var countdown: float = 0.0
var collapsed: bool = false
var dropped: float = 0.0
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
		gave_way.emit()
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
	dropped = 0.0
	collision_shape.set_deferred("disabled", false)
	detector.set_deferred("monitoring", true)
	queue_redraw()


func _process(delta: float) -> void:
	if collapsed and dropped < DROP_TIME:
		dropped += delta
		queue_redraw()


# The patch art is only pinned on, which is the tell. Once stood on it shivers harder and harder, then drops
# away, leaving its tacking stitches behind so you can see where it was.
func _draw() -> void:
	var fabric: Rect2 = Rect2(-size * 0.5, size)
	if collapsed and dropped >= DROP_TIME:
		_draw_tacking(fabric)
		return
	var offset: Vector2 = Vector2.ZERO
	var alpha: float = 1.0
	if collapsed:
		offset.y = 0.5 * 1550.0 * dropped * dropped
		alpha = 1.0 - dropped / DROP_TIME
	elif countdown > 0.0:
		var strain: float = 1.0 - countdown / delay
		offset = Vector2(sin(countdown * 90.0), cos(countdown * 70.0)) * (1.0 + strain * 3.0)
	var scale_y: float = size.y / (PATCH_BODY_BOTTOM - PATCH_BODY_TOP)
	var art_width: float = size.x / scale_y
	draw_set_transform(fabric.position + offset - Vector2(0, PATCH_BODY_TOP * scale_y), 0.0, Vector2.ONE * scale_y)
	var drawn: float = 0.0
	while drawn < art_width:
		var piece: float = minf(PATCH.get_width(), art_width - drawn)
		draw_texture_rect_region(PATCH, Rect2(drawn, 0, piece, PATCH.get_height()), Rect2(0, 0, piece, PATCH.get_height()), Color(1, 1, 1, alpha))
		drawn += piece
	draw_set_transform(Vector2.ZERO)


func _draw_tacking(fabric: Rect2) -> void:
	var y: float = fabric.get_center().y
	var x: float = fabric.position.x + 6.0
	while x < fabric.end.x - 6.0:
		draw_line(Vector2(x, y), Vector2(minf(x + 9.0, fabric.end.x - 6.0), y), Color(THREAD, 0.55), 2.0, true)
		x += 17.0
