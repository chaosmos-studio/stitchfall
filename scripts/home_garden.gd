class_name PalewheelHomeGarden
extends Control

const LEAF: Texture2D = preload("res://assets/art/home_leaf.png")
const FLOWER_BUD: Texture2D = preload("res://assets/art/home_flower_bud.png")
const FLOWER_OPEN: Texture2D = preload("res://assets/art/home_flower_open.png")
const PAINTING_SIZE: Vector2 = Vector2(1672, 941)
const FLOWER_POSITIONS: Array[Vector2] = [Vector2(1025, 635), Vector2(1260, 560), Vector2(1440, 680)]

var elapsed: float = 0.0
var motion_enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if motion_enabled:
		elapsed += delta
		queue_redraw()


func _draw() -> void:
	var fit: float = maxf(size.x / PAINTING_SIZE.x, size.y / PAINTING_SIZE.y)
	var origin: Vector2 = (size - PAINTING_SIZE * fit) * 0.5
	for index: int in range(FLOWER_POSITIONS.size()):
		var phase: float = 1.0 if not motion_enabled else clampf((elapsed - 1.0 - float(index) * 2.6) / 5.0, 0.0, 1.0)
		phase = phase * phase * (3.0 - 2.0 * phase)
		var flower_position: Vector2 = origin + (FLOWER_POSITIONS[index] + Vector2(sin(elapsed * 0.72 + float(index) * 1.7) * 3.0, 0)) * fit
		var bloom_size: Vector2 = Vector2.ONE * (78.0 + phase * 17.0) * fit
		var bloom_rect: Rect2 = Rect2(flower_position - bloom_size * 0.5, bloom_size)
		if phase < 1.0:
			draw_texture_rect(FLOWER_BUD, bloom_rect, false, Color(1, 1, 1, 1.0 - phase))
		if phase > 0.0:
			draw_texture_rect(FLOWER_OPEN, bloom_rect, false, Color(1, 1, 1, phase))
	if not motion_enabled:
		return
	for index: int in range(4):
		var drift: float = fposmod(elapsed * (10.0 + float(index) * 2.5) + float(index) * 67.0, 370.0)
		var source_position: Vector2 = Vector2(1050.0 + float(index) * 160.0 - drift, 155.0 + float(index % 3) * 63.0 + sin(elapsed * 0.9 + float(index)) * 8.0)
		var leaf_position: Vector2 = origin + source_position * fit
		var leaf_size: Vector2 = Vector2.ONE * (66.0 + float(index % 2) * 18.0) * fit
		var angle: float = sin(elapsed * 1.1 + float(index) * 1.8) * 0.16 + float(index - 2) * 0.2
		draw_set_transform(leaf_position, angle)
		draw_texture_rect(LEAF, Rect2(-leaf_size * 0.5, leaf_size), false, Color(1, 1, 1, 0.86))
		draw_set_transform(Vector2.ZERO)
