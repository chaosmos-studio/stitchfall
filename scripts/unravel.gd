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
	bits = make_bits(colours)


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _draw() -> void:
	draw_burst(self, Vector2.ZERO, shape, bits, minf(age / LIFE, 1.0))


# The burst's bits, the same for every unravel in a style: the way each flies, how far, its spin and its colour.
static func make_bits(palette: Array) -> Array[Dictionary]:
	var made: Array[Dictionary] = []
	for index: int in range(BITS):
		var angle: float = float(index) * TAU / float(BITS) + sin(float(index) * 7.0) * 0.2
		made.append({
			"angle": angle,
			"reach": 95.0 + float(index % 4) * 18.0,
			"spin": float(index % 5 - 2) * 3.0,
			"colour": palette[index % palette.size()],
		})
	return made


# The burst `t` of the way through its life (0 to 1) around `centre`, fading from `hold` of the way on. The
# wardrobe's tiles draw it with the bits flying `reach` times as far and `grow` times as big as in a room, `alpha`
# faded, and `outlined` in ink so pale bits still read on the pale felt.
static func draw_burst(canvas: CanvasItem, centre: Vector2, style_shape: String, burst: Array[Dictionary], t: float, reach: float = 1.0, grow: float = 1.0, alpha: float = 1.0, hold: float = 0.2, outlined: bool = false) -> void:
	var out: float = 1.0 - (1.0 - t) * (1.0 - t)
	var fade: float = clampf(1.0 - (t - hold) / (1.0 - hold), 0.0, 1.0) * alpha
	var ink: Color = Color("493a37", fade)
	var edge: Color = Color("493a37", fade * 0.55)
	for bit: Dictionary in burst:
		var direction: Vector2 = Vector2.from_angle(bit["angle"])
		var at: Vector2 = centre + direction * float(bit["reach"]) * reach * out
		var colour: Color = Color(bit["colour"], fade)
		var turn: float = float(bit["spin"]) * t
		match style_shape:
			"button":
				canvas.draw_circle(at, 8.0 * grow, ink)
				canvas.draw_circle(at, 6.5 * grow, colour)
				canvas.draw_circle(at + Vector2(-2, -2).rotated(turn) * grow, 1.3 * grow, ink)
				canvas.draw_circle(at + Vector2(2, 2).rotated(turn) * grow, 1.3 * grow, ink)
			"petal":
				canvas.draw_set_transform(at, float(bit["angle"]) + turn, Vector2(1.0, 0.55))
				if outlined:
					canvas.draw_circle(Vector2.ZERO, 9.0 * grow + 3.0, edge)
				canvas.draw_circle(Vector2.ZERO, 9.0 * grow, colour)
				canvas.draw_set_transform(Vector2.ZERO)
			"star":
				if outlined:
					StitchfallStarRow.draw_star(canvas, at, 9.0 * grow + 3.0, true, edge)
				StitchfallStarRow.draw_star(canvas, at, 9.0 * grow, true, colour)
			"snip":
				canvas.draw_set_transform(at, turn, Vector2.ONE * grow)
				if outlined:
					canvas.draw_rect(Rect2(-9.5, -4.5, 19, 9), edge)
				canvas.draw_rect(Rect2(-8, -3, 16, 6), colour)
				canvas.draw_set_transform(Vector2.ZERO)
			_:
				var tail: float = (31.0 + float(int(bit["reach"]) % 3) * 8.0) * (1.0 - t * 0.5) * reach
				if outlined:
					canvas.draw_line(at - direction * tail, at, edge, 2.0 * grow + 3.0, true)
				canvas.draw_line(at - direction * tail, at, colour, 2.0 * grow, true)
