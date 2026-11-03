class_name ButtonMeter
extends Control

var collected: int = 0
var total: int = 3
var biome: int = 0
var age: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _palette() -> Array[Color]:
	match biome:
		4:
			return [Color("d9e8e4"), Color("648b93"), Color("49727f")]
		5:
			return [Color("f1d7a8"), Color("ae754b"), Color("925745")]
		6:
			return [Color("dfe8c8"), Color("6f8962"), Color("536e54")]
		7:
			return [Color("d8d3e3"), Color("79779d"), Color("605a83")]
	return [Color("f1e1c8"), Color("a47660"), Color("8d6653")]


func _draw() -> void:
	var colors: Array[Color] = _palette()
	var patch: PackedVector2Array = PackedVector2Array([
		Vector2(5, 11), Vector2(18, 5), Vector2(size.x - 17, 7),
		Vector2(size.x - 5, 17), Vector2(size.x - 8, size.y - 12),
		Vector2(size.x - 20, size.y - 4), Vector2(14, size.y - 6),
		Vector2(5, size.y - 17),
	])
	draw_colored_polygon(patch, Color("463c36", 0.23))
	var front: PackedVector2Array = PackedVector2Array([
		Vector2(4, 6), Vector2(17, 1), Vector2(size.x - 18, 3),
		Vector2(size.x - 4, 12), Vector2(size.x - 8, size.y - 17),
		Vector2(size.x - 18, size.y - 8), Vector2(13, size.y - 9),
		Vector2(4, size.y - 20),
	])
	draw_colored_polygon(front, colors[0])
	draw_polyline(front, colors[1], 2.0, true)
	draw_line(front[7], front[0], colors[1], 2.0, true)
	for x: int in range(28, int(size.x - 17), 15):
		draw_line(Vector2(x, 11), Vector2(x + 7, 11), colors[1], 1.6, true)
		draw_line(Vector2(x, size.y - 18), Vector2(x + 7, size.y - 18), colors[1], 1.6, true)
	for index: int in range(total):
		var center: Vector2 = Vector2(45.0 + float(index) * 55.0, size.y * 0.49)
		var sewn: bool = index < collected
		var button_color: Color = Color("e7c785") if sewn else colors[1].lightened(0.38)
		var shimmer: float = sin(age * 2.8 + index * 0.7) * 0.7 if sewn else 0.0
		draw_circle(center + Vector2(2, 3), 17.0, Color("3e3533", 0.28))
		draw_circle(center, 16.0 + shimmer, Color("493b36"))
		draw_circle(center, 13.0 + shimmer, button_color)
		for hole: int in range(4):
			var offset: Vector2 = Vector2(-4 if hole % 2 == 0 else 4, -4 if hole < 2 else 4)
			draw_circle(center + offset, 2.2, Color("58443c"))
		if sewn:
			draw_line(center + Vector2(-4, -4), center + Vector2(4, 4), Color("f8e9c9"), 1.5, true)
			draw_line(center + Vector2(4, -4), center + Vector2(-4, 4), Color("f8e9c9"), 1.5, true)
