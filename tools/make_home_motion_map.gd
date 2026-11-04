extends SceneTree

const OUTPUT: String = "res://assets/art/home_motion_map.png"
const PAINTING_SIZE: Vector2i = Vector2i(1672, 941)

const TREE_LEAVES: Array[Vector4] = [
	Vector4(30, 48, 24, 31), Vector4(65, 23, 27, 31), Vector4(128, 74, 23, 30),
	Vector4(605, 19, 34, 19), Vector4(660, 19, 30, 28), Vector4(725, 12, 34, 25),
	Vector4(813, 19, 30, 21), Vector4(839, 59, 28, 21), Vector4(866, 84, 37, 29),
	Vector4(849, 161, 24, 38), Vector4(890, 149, 23, 34), Vector4(931, 104, 23, 39),
	Vector4(979, 22, 26, 24), Vector4(1046, 22, 32, 29), Vector4(1082, 54, 27, 38),
	Vector4(1150, 14, 30, 27), Vector4(1208, 12, 31, 30), Vector4(1268, 15, 32, 31),
	Vector4(1336, 18, 34, 28), Vector4(1425, 20, 32, 31), Vector4(1503, 17, 24, 28),
	Vector4(1619, 25, 28, 30), Vector4(1664, 59, 24, 35),
	Vector4(1139, 64, 29, 23), Vector4(1217, 99, 38, 25), Vector4(1259, 162, 24, 38),
	Vector4(1299, 127, 23, 33), Vector4(1363, 98, 32, 29), Vector4(1450, 132, 23, 40),
	Vector4(1515, 116, 22, 35), Vector4(1562, 105, 19, 31),
	Vector4(1115, 165, 29, 18), Vector4(1160, 166, 27, 20), Vector4(1186, 184, 22, 31),
]

const FLOWERS: Array[Vector4] = [
	Vector4(79, 81, 47, 48), Vector4(85, 750, 57, 65),
	Vector4(831, 262, 20, 24), Vector4(877, 233, 18, 23), Vector4(916, 271, 20, 24),
	Vector4(827, 562, 39, 33), Vector4(876, 612, 22, 23), Vector4(923, 611, 24, 25),
	Vector4(950, 630, 22, 25), Vector4(974, 661, 22, 25), Vector4(1015, 695, 20, 24),
	Vector4(875, 762, 27, 29), Vector4(1114, 831, 31, 37),
	Vector4(1480, 337, 23, 39), Vector4(1537, 341, 22, 40), Vector4(1579, 373, 24, 42),
	Vector4(1541, 537, 20, 23), Vector4(1570, 558, 30, 25),
	Vector4(1424, 635, 20, 24), Vector4(1466, 593, 25, 27),
	Vector4(1527, 596, 20, 24), Vector4(1583, 612, 52, 53), Vector4(1631, 568, 25, 33),
	Vector4(1379, 662, 21, 26), Vector4(828, 460, 13, 20), Vector4(847, 487, 13, 20),
]

const GROUND_GROWTH: Array[Vector4] = [
	Vector4(806, 339, 27, 55), Vector4(873, 344, 32, 59), Vector4(941, 361, 24, 44),
	Vector4(988, 406, 21, 35), Vector4(1067, 440, 20, 31), Vector4(1130, 422, 20, 32),
	Vector4(1257, 400, 21, 35), Vector4(1328, 372, 19, 42), Vector4(1386, 344, 20, 36),
	Vector4(812, 710, 23, 44), Vector4(874, 691, 23, 44), Vector4(913, 711, 22, 43),
	Vector4(1058, 659, 21, 33), Vector4(1140, 644, 19, 32), Vector4(1263, 636, 20, 35),
	Vector4(1336, 612, 19, 34), Vector4(1374, 543, 20, 36), Vector4(1430, 565, 24, 45),
	Vector4(1608, 704, 29, 45), Vector4(1640, 514, 23, 51),
	Vector4(55, 639, 38, 62), Vector4(194, 793, 29, 42), Vector4(227, 837, 30, 43),
]


func _initialize() -> void:
	var image: Image = Image.create(PAINTING_SIZE.x, PAINTING_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_paint_group(image, TREE_LEAVES, 0.8, 0.46, 0)
	_paint_group(image, FLOWERS, 0.58, 0.47, TREE_LEAVES.size())
	_paint_group(image, GROUND_GROWTH, 0.7, 0.28, TREE_LEAVES.size() + FLOWERS.size())
	var result: Error = image.save_png(OUTPUT)
	if result != OK:
		push_error("Could not save the home motion map: %s" % error_string(result))
	quit(result)


func _paint_group(image: Image, shapes: Array[Vector4], horizontal: float, vertical: float, first_index: int) -> void:
	for index: int in range(shapes.size()):
		var shape: Vector4 = shapes[index]
		var phase: float = fposmod(float(index + first_index) * 0.6180339887, 1.0)
		_paint_shape(image, shape, horizontal, vertical, phase)


func _paint_shape(image: Image, shape: Vector4, horizontal: float, vertical: float, phase: float) -> void:
	var center: Vector2 = Vector2(shape.x, shape.y)
	var radius: Vector2 = Vector2(shape.z, shape.w)
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
			var weight: float = 1.0 - smoothstep(0.57, 1.0, distance)
			if weight > image.get_pixel(x, y).a:
				image.set_pixel(x, y, Color(horizontal, vertical, phase, weight))
