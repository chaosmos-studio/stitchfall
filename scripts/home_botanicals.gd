extends Control

const PAINTING_SIZE: Vector2 = Vector2(1672, 941)
const BLOSSOM_ATLAS: Texture2D = preload("res://assets/art/home_blossom_atlas.png")
const SECONDARY_ATLAS: Texture2D = preload("res://assets/art/home_secondary_atlas.png")
const RED_FLOWER: Texture2D = preload("res://assets/art/home_red_flower.png")
const PETAL_SHADER: Shader = preload("res://shaders/home_petal.gdshader")

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
