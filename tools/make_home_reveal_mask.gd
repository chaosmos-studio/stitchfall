extends SceneTree

const OUTPUT: String = "res://assets/art/home_reveal_mask.png"
const PAINTING_SIZE: Vector2i = Vector2i(1672, 941)
const BOTANICALS: GDScript = preload("res://scripts/home_botanicals.gd")


func _initialize() -> void:
	var image: Image = Image.create(PAINTING_SIZE.x, PAINTING_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_paint_group(image, BOTANICALS.WHITE_FLOWERS, 1.0)
	_paint_group(image, BOTANICALS.BLUE_FLOWERS, 1.0)
	_paint_group(image, BOTANICALS.CREAM_FLOWERS, 1.0)
	_paint_group(image, BOTANICALS.LARGE_CREAM_FLOWERS, 1.0)
	_paint_group(image, BOTANICALS.HANGING_BELLS, 1.0)
	_paint_shape(image, BOTANICALS.RED_BLOOM, 1.0)
	var result: Error = image.save_png(OUTPUT)
	if result != OK:
		push_error("Could not save the home reveal mask: %s" % error_string(result))
	quit(result)


func _paint_group(image: Image, shapes: Array[Vector4], expansion: float) -> void:
	for shape: Vector4 in shapes:
		_paint_shape(image, shape, expansion)


func _paint_shape(image: Image, shape: Vector4, expansion: float) -> void:
	var center: Vector2 = Vector2(shape.x, shape.y)
	var radius: Vector2 = Vector2(shape.z, shape.w) * expansion
	var left: int = maxi(0, int(center.x - radius.x))
	var right: int = mini(PAINTING_SIZE.x - 1, int(center.x + radius.x))
	var top: int = maxi(0, int(center.y - radius.y))
	var bottom: int = mini(PAINTING_SIZE.y - 1, int(center.y + radius.y))
	for y: int in range(top, bottom + 1):
		for x: int in range(left, right + 1):
			var local: Vector2 = (Vector2(x, y) - center) / radius
			var distance: float = local.length()
			if distance >= 1.0:
				continue
			var weight: float = 1.0 - smoothstep(0.72, 1.0, distance)
			if weight > image.get_pixel(x, y).a:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, weight))
