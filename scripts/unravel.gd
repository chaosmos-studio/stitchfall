class_name StitchfallUnravel
extends Node2D

# The runner coming apart on a hit: the drawing splits into twelve patches that fly and fade, ringed by a burst
# in the wardrobe's unravel style (threads, buttons, petals, sequins or snippets).

const BITS: int = 14
const LIFE: float = 0.62

var shape: String = "thread"
var colours: Array = [Color("f6e6c9")]
var bits: Array[Dictionary] = []
var age: float = 0.0


func scatter(courier: StitchfallCourier, style: Dictionary = {}) -> void:
	position = courier.position
	z_index = 8
	shape = style.get("shape", "thread")
	colours = style.get("colours", [Color("f6e6c9")])
	var source: Texture2D = courier.sprite.sprite_frames.get_frame_texture(courier.sprite.animation, courier.sprite.frame)
	var tile: Vector2 = source.get_size() / Vector2(3, 4)
	for row: int in range(4):
		for column: int in range(3):
			var piece: Sprite2D = Sprite2D.new()
			var crop: AtlasTexture = AtlasTexture.new()
			crop.atlas = source
			crop.region = Rect2(Vector2(column, row) * tile, tile)
			piece.texture = crop
			piece.scale = courier.sprite.scale
			piece.material = courier.sprite.material
			piece.position = courier.sprite.position + (Vector2(column + 0.5, row + 0.5) * tile - source.get_size() * 0.5) * piece.scale
			piece.rotation = courier.sprite.rotation
			add_child(piece)
			var direction: Vector2 = Vector2(float(column - 1) * 41.0 + sin(float(row * 3 + column) * 2.0) * 16.0, -85.0 + float(row) * 12.0)
			var tween: Tween = create_tween().set_parallel(true)
			tween.tween_property(piece, "position", piece.position + direction, LIFE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(piece, "rotation", piece.rotation + float(column - 1) * 0.8 + float(row % 2) * 0.35, LIFE)
			tween.tween_property(piece, "modulate:a", 0.0, LIFE).set_delay(0.2)
	for index: int in range(BITS):
		var angle: float = float(index) * TAU / float(BITS) + sin(float(index) * 7.0) * 0.2
		bits.append({
			"angle": angle,
			"reach": 95.0 + float(index % 4) * 18.0,
			"spin": float(index % 5 - 2) * 3.0,
			"colour": colours[index % colours.size()],
		})


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _draw() -> void:
	var t: float = minf(age / LIFE, 1.0)
	var out: float = 1.0 - (1.0 - t) * (1.0 - t)
	var fade: float = clampf(1.0 - (t - 0.2) / 0.8, 0.0, 1.0)
	for bit: Dictionary in bits:
		var direction: Vector2 = Vector2.from_angle(bit["angle"])
		var centre: Vector2 = direction * float(bit["reach"]) * out
		var colour: Color = Color(bit["colour"], fade)
		var turn: float = float(bit["spin"]) * t
		match shape:
			"button":
				draw_circle(centre, 8.0, Color("493a37", fade))
				draw_circle(centre, 6.5, colour)
				draw_circle(centre + Vector2(-2, -2).rotated(turn), 1.3, Color("493a37", fade))
				draw_circle(centre + Vector2(2, 2).rotated(turn), 1.3, Color("493a37", fade))
			"petal":
				draw_set_transform(centre, bit["angle"] + turn, Vector2(1.0, 0.55))
				draw_circle(Vector2.ZERO, 9.0, colour)
				draw_set_transform(Vector2.ZERO)
			"star":
				StitchfallStarRow.draw_star(self, centre, 9.0, true, colour)
			"snip":
				draw_set_transform(centre, turn, Vector2.ONE)
				draw_rect(Rect2(-8, -3, 16, 6), colour)
				draw_set_transform(Vector2.ZERO)
			_:
				draw_line(centre - direction * (31.0 + float(int(bit["reach"]) % 3) * 8.0) * (1.0 - t * 0.5), centre, colour, 2.0, true)
