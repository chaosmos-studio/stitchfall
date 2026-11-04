extends Control

const PAINTING_SIZE: Vector2 = Vector2(1672, 941)
const LEAF_ATLAS: Texture2D = preload("res://assets/art/home_leaf_atlas.png")
const BLOSSOM_ATLAS: Texture2D = preload("res://assets/art/home_blossom_atlas.png")
const SECONDARY_ATLAS: Texture2D = preload("res://assets/art/home_secondary_atlas.png")
const RED_FLOWER: Texture2D = preload("res://assets/art/home_red_flower.png")
const PETAL_SHADER: Shader = preload("res://shaders/home_petal.gdshader")

const LEAF_REVEAL_SHAPES: Array[Vector4] = [
	Vector4(876, 81, 49, 29), Vector4(931, 114, 32, 49), Vector4(854, 175, 34, 47),
	Vector4(895, 153, 24, 42), Vector4(1016, 59, 33, 42), Vector4(1149, 109, 47, 31),
	Vector4(1227, 155, 29, 49), Vector4(1110, 201, 42, 29), Vector4(1155, 199, 32, 25),
	Vector4(1182, 180, 20, 32), Vector4(1300, 111, 31, 40), Vector4(1351, 158, 30, 49),
	Vector4(1380, 111, 27, 39), Vector4(1475, 108, 29, 37),
]

const LEAVES: Array[Vector4] = [
	Vector4(876, 92, 49, 29), Vector4(925, 75, 32, 49), Vector4(854, 165, 34, 47),
	Vector4(898, 128, 24, 42), Vector4(1016, 50, 33, 42), Vector4(1150, 154, 47, 31),
	Vector4(1227, 122, 29, 49), Vector4(1110, 192, 42, 29), Vector4(1155, 164, 32, 25),
	Vector4(1182, 145, 20, 32), Vector4(1300, 107, 31, 40), Vector4(1351, 112, 30, 49),
	Vector4(1380, 110, 27, 39), Vector4(1475, 108, 29, 37),
]

const LEAF_ATTACHMENTS: Array[Vector2] = [
	Vector2(906, 67), Vector2(930, 47), Vector2(849, 146),
	Vector2(890, 110), Vector2(1016, 20), Vector2(1150, 138),
	Vector2(1228, 91), Vector2(1110, 169), Vector2(1156, 136),
	Vector2(1182, 115), Vector2(1300, 78), Vector2(1351, 80),
	Vector2(1380, 85), Vector2(1451, 106),
]

const WHITE_FLOWERS: Array[Vector4] = [
	Vector4(831, 260, 23, 25), Vector4(908, 230, 22, 26), Vector4(919, 280, 23, 25),
	Vector4(897, 616, 25, 27), Vector4(927, 595, 24, 28), Vector4(936, 642, 25, 28),
	Vector4(958, 616, 24, 26), Vector4(875, 759, 29, 32), Vector4(1379, 660, 23, 28),
	Vector4(1495, 585, 24, 27),
]

const BLUE_FLOWERS: Array[Vector4] = [
	Vector4(974, 663, 24, 26), Vector4(1008, 695, 23, 25), Vector4(1424, 636, 22, 26),
	Vector4(1466, 595, 25, 28),
]

const CREAM_FLOWERS: Array[Vector4] = [
	Vector4(831, 562, 42, 34), Vector4(1542, 536, 24, 26), Vector4(1567, 556, 26, 28),
]

const LARGE_CREAM_FLOWERS: Array[Vector4] = [
	Vector4(83, 49, 74, 64),
]

const HANGING_BELLS: Array[Vector4] = [
	Vector4(1418, 365, 35, 56), Vector4(1473, 347, 35, 58), Vector4(1525, 382, 34, 55),
]

const RED_BLOOM: Vector4 = Vector4(1563, 617, 69, 66)

var art_root: Node2D
var leaf_holders: Array[Node2D] = []
var flower_holders: Array[Node2D] = []
var petal_sprites: Array[Sprite2D] = []
var petal_scales: Array[Vector2] = []
var petal_cycles: Array[float] = []
var petal_initial_sizes: Array[float] = []
var flower_centers: Array[Sprite2D] = []
var center_scales: Array[Vector2] = []
var center_cycles: Array[float] = []
var center_initial_sizes: Array[float] = []
var bloom_count: int = 0
var elapsed: float = 0.0
var motion_enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if OS.has_feature("web"):
		motion_enabled = not bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	art_root = Node2D.new()
	add_child(art_root)
	_build_leaves()
	_build_flowers()
	_build_red_bloom()
	resized.connect(_fit_painting)
	_fit_painting()
	if not motion_enabled:
		elapsed = 5.0
		_animate_pieces()
		set_process(false)


func _fit_painting() -> void:
	var factor: float = maxf(size.x / PAINTING_SIZE.x, size.y / PAINTING_SIZE.y)
	art_root.scale = Vector2.ONE * factor
	art_root.position = (size - PAINTING_SIZE * factor) * 0.5


func _atlas_region(source: Texture2D, area: Rect2) -> AtlasTexture:
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = source
	texture.region = area
	return texture


func _piece(parent: Node2D, texture: Texture2D, extent: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = extent / texture.get_size()
	parent.add_child(sprite)
	return sprite


func _build_leaves() -> void:
	var types: Array[AtlasTexture] = [
		_atlas_region(LEAF_ATLAS, Rect2(80, 50, 950, 620)),
		_atlas_region(LEAF_ATLAS, Rect2(1050, 50, 450, 620)),
		_atlas_region(LEAF_ATLAS, Rect2(1560, 150, 570, 450)),
	]
	assert(LEAVES.size() == LEAF_ATTACHMENTS.size())
	for index: int in range(LEAVES.size()):
		var shape: Vector4 = LEAVES[index]
		var attachment: Vector2 = LEAF_ATTACHMENTS[index]
		var direction: Vector2 = (Vector2(shape.x, shape.y) - attachment).normalized()
		var stem_length: float = 15.0
		var holder: Node2D = Node2D.new()
		holder.position = attachment
		art_root.add_child(holder)
		var stalk: Line2D = Line2D.new()
		stalk.width = 4.0
		stalk.default_color = Color("76523a")
		stalk.antialiased = true
		stalk.add_point(Vector2.ZERO)
		var bend: Vector2 = Vector2(-direction.y, direction.x) * (2.0 if index % 2 == 0 else -2.0)
		stalk.add_point(direction * (stem_length * 0.5) + bend)
		stalk.add_point(direction * (stem_length + shape.z * 0.12))
		holder.add_child(stalk)
		var variant: int = 2 if index % 4 == 0 else 0
		var extent: Vector2 = Vector2(shape.z * 2.0, shape.w * 2.0)
		var sprite: Sprite2D = _piece(holder, types[variant], extent)
		sprite.position = direction * (shape.z + stem_length)
		sprite.rotation = direction.angle()
		leaf_holders.append(holder)


func _build_flowers() -> void:
	_add_flower_group(WHITE_FLOWERS, BLOSSOM_ATLAS, Rect2i(80, 80, 570, 550), 6)
	_add_flower_group(BLUE_FLOWERS, BLOSSOM_ATLAS, Rect2i(790, 100, 570, 540), 5)
	_add_flower_group(CREAM_FLOWERS, BLOSSOM_ATLAS, Rect2i(1480, 100, 640, 530))
	_add_flower_group(LARGE_CREAM_FLOWERS, SECONDARY_ATLAS, Rect2i(35, 55, 660, 620), 4)
	_add_flower_group(HANGING_BELLS, SECONDARY_ATLAS, Rect2i(875, 215, 390, 410))


func _add_flower_group(shapes: Array[Vector4], source: Texture2D, region: Rect2i, petal_count: int = 0) -> void:
	var texture: Texture2D
	if petal_count > 0:
		texture = ImageTexture.create_from_image(source.get_image().get_region(region))
	else:
		texture = _atlas_region(source, Rect2(region))
	for index: int in range(shapes.size()):
		var shape: Vector4 = shapes[index]
		var hanging: bool = source == SECONDARY_ATLAS and petal_count == 0
		var holder: Node2D = Node2D.new()
		holder.position = Vector2(shape.x, shape.y - shape.w * 0.7 if hanging else shape.y + shape.w * 0.7)
		art_root.add_child(holder)
		var bloom: Node2D = Node2D.new()
		bloom.position.y = shape.w * 0.7 if hanging else -shape.w * 0.7
		holder.add_child(bloom)
		var extent: Vector2 = Vector2(shape.z * 2.2, shape.w * 2.2)
		if source == SECONDARY_ATLAS:
			extent *= 0.65 if hanging else 1.15
		if petal_count > 0:
			_build_petals(bloom, texture, extent, petal_count)
		else:
			_piece(bloom, texture, extent)
		flower_holders.append(holder)


func _build_petals(parent: Node2D, texture: Texture2D, extent: Vector2, count: int) -> void:
	var red: bool = texture == RED_FLOWER
	var cycle: float = 0.35 if red else fposmod(float(bloom_count) * 2.17 + 1.4, 9.0)
	bloom_count += 1
	for index: int in range(count):
		var petal: Sprite2D = _piece(parent, texture, extent)
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = PETAL_SHADER
		material.set_shader_parameter("petal_index", float(index))
		material.set_shader_parameter("petal_count", float(count))
		material.set_shader_parameter("aspect_ratio", float(texture.get_width()) / float(texture.get_height()))
		petal.material = material
		petal_sprites.append(petal)
		petal_scales.append(petal.scale)
		petal_cycles.append(cycle - float(index) * 0.11)
		petal_initial_sizes.append(0.56 if red else 0.72)
	var center: Sprite2D = _piece(parent, texture, extent)
	var center_material: ShaderMaterial = ShaderMaterial.new()
	center_material.shader = PETAL_SHADER
	center_material.set_shader_parameter("center_only", true)
	center_material.set_shader_parameter("aspect_ratio", float(texture.get_width()) / float(texture.get_height()))
	center.material = center_material
	flower_centers.append(center)
	center_scales.append(center.scale)
	center_cycles.append(cycle)
	center_initial_sizes.append(0.66 if red else 0.82)


func _build_red_bloom() -> void:
	var holder: Node2D = Node2D.new()
	holder.position = Vector2(RED_BLOOM.x, RED_BLOOM.y + RED_BLOOM.w * 0.75)
	art_root.add_child(holder)
	var bloom: Node2D = Node2D.new()
	bloom.position.y = -RED_BLOOM.w * 0.75
	holder.add_child(bloom)
	flower_holders.append(holder)
	var extent: Vector2 = Vector2(RED_BLOOM.z * 3.1, RED_BLOOM.w * 2.5)
	_build_petals(bloom, RED_FLOWER, extent, 6)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += delta
	_animate_pieces()


func _bloom_open(phase: float) -> float:
	return smoothstep(0.35, 2.2, phase) * (1.0 - smoothstep(6.3, 8.6, phase))


func _animate_pieces() -> void:
	for index: int in range(leaf_holders.size()):
		var phase: float = float(index) * 1.73
		var branch_breath: float = 0.65 * sin(elapsed * 0.83 + phase * 0.12) + 0.35 * sin(elapsed * (1.13 + float(index % 4) * 0.05) + phase)
		leaf_holders[index].rotation = deg_to_rad((13.5 + float(index % 4) * 1.1) * branch_breath)
	for index: int in range(flower_holders.size()):
		var phase: float = float(index) * 2.17
		var flower_breath: float = 0.7 * sin(elapsed * 0.64 + phase * 0.15) + 0.3 * sin(elapsed * (1.02 + float(index % 4) * 0.07) + phase)
		flower_holders[index].rotation = deg_to_rad(8.0 * flower_breath)
	for index: int in range(petal_sprites.size()):
		var petal: Sprite2D = petal_sprites[index]
		var phase: float = fposmod(elapsed + petal_cycles[index], 9.0)
		var open: float = _bloom_open(phase)
		petal.scale = petal_scales[index] * lerpf(petal_initial_sizes[index], 1.02, open)
		petal.rotation = deg_to_rad(4.0 * sin(elapsed * 0.92 + float(index) * 0.68)) * open
	for index: int in range(flower_centers.size()):
		var phase: float = fposmod(elapsed + center_cycles[index], 9.0)
		flower_centers[index].scale = center_scales[index] * lerpf(center_initial_sizes[index], 1.0, _bloom_open(phase))
