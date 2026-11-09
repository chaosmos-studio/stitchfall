extends ChaosmosIntroStyle

# Stitchfall's beat: the word is sewn onto the game's linen. A needle runs a stitch round each letter in turn,
# the letters fill in as felt under their stitches, the ring is stitched round and coral felt rises in it like
# water, and the second o is one of the game's own coral buttons, dropped on and bouncing into place.

const LINEN: Texture2D = preload("res://intro/games/stitchfall/linen.webp")
const BUTTONS: Texture2D = preload("res://intro/games/stitchfall/buttons.png")
# The coral button's cell in the sheet, and how much of the cell the button fills.
const CORAL_BUTTON: Rect2 = Rect2(256, 0, 256, 256)
const BUTTON_SHARE: float = 200.0 / 256.0
# Stitchfall's ink and thread.
const FELT_INK: Color = Color("493a37")
const THREAD: Color = Color("f7edda")
const THREAD_SHADOW: Color = Color(0.18, 0.12, 0.09, 0.4)
const STEEL: Color = Color("c9ccd1")
# A running stitch, in font units: how far in from the letter's edge, each stitch's length, and the step.
const INSET: float = 34.0
const STITCH: float = 30.0
const STEP: float = 52.0
const THREAD_WIDTH: float = 13.0
# The smallest piece of an inset outline worth a stitch, in square font units.
const CRUMB: float = 6000.0
# When each piece is sewn: the letters and the ring in order across the word, each taking SEW seconds.
const SEW_FROM: float = 0.12
const SEW_STAGGER: float = 0.13
const SEW: float = 0.62
const FILL: float = 0.35
const RING_ORDER: float = 2.5
const WATER: Vector2 = Vector2(1.15, 1.55)
const DROP: Vector2 = Vector2(1.2, 1.75)

# Each letter's stitch lines in font units (y up), made once from the font's outlines.
var lines: Array[Array] = []


func title() -> String:
	return "Stitchfall"


func settle() -> float:
	return 1.95


func sting() -> String:
	return "res://intro/sounds/stitchfall.wav"


func background() -> Color:
	return Color("efe4cf")


func _sew_start(order: float) -> float:
	return SEW_FROM + SEW_STAGGER * order


# The order across the word: c h a, then the ring, then s m s.
func _order(index: int) -> float:
	return float(index) if index < 3 else float(index) + 1.0


func draw(canvas: CanvasItem, t: float, view: Vector2) -> void:
	if lines.is_empty():
		_make_lines()
	var art: Vector2 = LINEN.get_size()
	var cover: float = maxf(view.x / art.x, view.y / art.y)
	canvas.draw_texture_rect(LINEN, Rect2((view - art * cover) * Vector2(0.5, 0.85), art * cover), false)
	var needle_at: Vector2 = Vector2.INF
	var needle_along: Vector2 = Vector2.RIGHT
	for index: int in range(ChaosmosWordmark.LETTERS.size()):
		var start: float = _sew_start(_order(index))
		var sewn: float = span(t, start, start + SEW)
		if sewn <= 0.0:
			continue
		var filled: float = out_cubic(span(t, start + SEW * 0.55, start + SEW * 0.55 + FILL))
		if filled > 0.0:
			word.draw_letter(canvas, index, word.letter_centre(index), Color(FELT_INK, filled))
		var front: Array = _draw_stitches(canvas, lines[index], sewn)
		if sewn < 1.0 and not front.is_empty():
			needle_at = front[0]
			needle_along = front[1]
	_draw_ring(canvas, t)
	_draw_button(canvas, t)
	if needle_at != Vector2.INF:
		_draw_needle(canvas, needle_at, needle_along)


func _draw_ring(canvas: CanvasItem, t: float) -> void:
	var start: float = _sew_start(RING_ORDER)
	var sewn: float = span(t, start, start + SEW)
	if sewn <= 0.0:
		return
	var centre: Vector2 = word.ring_centre()
	var rise: float = out_cubic(span(t, WATER.x, WATER.y))
	word.draw_water(canvas, centre, coral, 1.0, rise, t * 0.35, 1.0 + 1.2 * (1.0 - span(t, WATER.x, 2.0)))
	word.draw_ring(canvas, centre, Color(FELT_INK, out_cubic(span(t, start + SEW * 0.5, start + SEW * 0.5 + FILL))))
	# Two rings of stitches, inside the ring's outer and inner edge, sewn round from the top.
	for radius: float in [ChaosmosWordmark.O_RADIUS - INSET, ChaosmosWordmark.O_RADIUS - ChaosmosWordmark.RING_STROKE + INSET]:
		var path: PackedVector2Array = PackedVector2Array()
		for step: int in range(73):
			var angle: float = -PI * 0.5 + float(step) / 72.0 * TAU
			path.append(Vector2(ChaosmosWordmark.RING_X, ChaosmosWordmark.O_Y) + Vector2(cos(angle), -sin(angle)) * radius)
		_draw_stitches(canvas, [path], sewn)


# The button falls onto its place, squashes as it lands and springs back.
func _draw_button(canvas: CanvasItem, t: float) -> void:
	var fall: float = span(t, DROP.x, DROP.y)
	if fall <= 0.0:
		return
	var rest: Vector2 = word.disc_centre()
	var radius: float = ChaosmosWordmark.O_RADIUS * word.unit
	var y: float = lerpf(rest.y - radius * 4.0, rest.y, out_bounce(fall))
	var squash: float = 0.0
	for landing: Vector2 in [Vector2(0.364, 0.16), Vector2(0.727, 0.07)]:
		var since: float = (fall - landing.x) / 0.1
		if since >= 0.0 and since < 1.0:
			squash = landing.y * sin(since * PI)
	var cell: float = radius * 2.0 / BUTTON_SHARE
	var size: Vector2 = Vector2(cell * (1.0 + squash), cell * (1.0 - squash))
	var centre: Vector2 = Vector2(rest.x, y + radius * squash)
	canvas.draw_texture_rect_region(BUTTONS, Rect2(centre - size * 0.5 + Vector2(4, 8) * word.unit * 10.0, size), CORAL_BUTTON, Color(0, 0, 0, 0.25))
	canvas.draw_texture_rect_region(BUTTONS, Rect2(centre - size * 0.5, size), CORAL_BUTTON)


# Draws the first `sewn` share of each path's running stitch, and answers where the stitching has got to and
# which way it is going, for the needle.
func _draw_stitches(canvas: CanvasItem, paths: Array, sewn: float) -> Array:
	var total: float = 0.0
	for path: PackedVector2Array in paths:
		total += _length(path)
	var budget: float = total * sewn
	var front: Array = []
	for path: PackedVector2Array in paths:
		var walked: float = 0.0
		for index: int in range(path.size() - 1):
			var from: Vector2 = path[index]
			var to: Vector2 = path[index + 1]
			var piece: float = from.distance_to(to)
			if budget <= 0.0:
				break
			var shown: float = minf(piece, budget)
			_dash(canvas, from, to, piece, shown, walked)
			if shown < piece:
				front = [word.at(from.lerp(to, shown / piece).x, from.lerp(to, shown / piece).y), Vector2(to.x - from.x, from.y - to.y).normalized()]
			walked += piece
			budget -= piece
	return front


# The stitches along one segment of a path, `walked` font units into it, as far as `shown` of its `piece`.
func _dash(canvas: CanvasItem, from: Vector2, to: Vector2, piece: float, shown: float, walked: float) -> void:
	if piece <= 0.0:
		return
	var at: float = 0.0
	while at < shown:
		var into: float = fmod(walked + at, STEP)
		if into < STITCH:
			var until: float = minf(shown, at + STITCH - into)
			var a: Vector2 = word.at(from.lerp(to, at / piece).x, from.lerp(to, at / piece).y)
			var b: Vector2 = word.at(from.lerp(to, until / piece).x, from.lerp(to, until / piece).y)
			canvas.draw_line(a + Vector2(1, 2), b + Vector2(1, 2), THREAD_SHADOW, THREAD_WIDTH * word.unit * 1.3, true)
			canvas.draw_line(a, b, THREAD, THREAD_WIDTH * word.unit, true)
			at = until
		else:
			at += STEP - into


func _draw_needle(canvas: CanvasItem, tip: Vector2, along: Vector2) -> void:
	var length: float = 260.0 * word.unit
	var back: Vector2 = tip - along * length
	canvas.draw_line(back + Vector2(2, 3), tip + Vector2(2, 3), Color(0, 0, 0, 0.25), 9.0 * word.unit * 1.4, true)
	canvas.draw_line(back, tip, STEEL, 9.0 * word.unit * 1.4, true)
	canvas.draw_line(back + along * length * 0.1, tip - along * length * 0.15, Color.WHITE, 3.0 * word.unit, true)
	canvas.draw_arc(back + along * 22.0 * word.unit, 9.0 * word.unit, 0.0, TAU, 12, Color(FELT_INK, 0.6), 3.0 * word.unit, true)
	canvas.draw_line(back + along * 22.0 * word.unit, back - along * 120.0 * word.unit + Vector2(0, 60.0 * word.unit), THREAD, THREAD_WIDTH * word.unit * 0.8, true)


static func _length(path: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in range(path.size() - 1):
		total += path[index].distance_to(path[index + 1])
	return total


# Each letter's outline from the font, its curves flattened, moved INSET into the letter: the outer edge shrunk
# and a hole (the a's) grown, so the stitches sit on the felt rather than its edge. In font units, y up, placed
# at the letter's pen position.
func _make_lines() -> void:
	var server: TextServer = TextServerManager.get_primary_interface()
	var rid: RID = ChaosmosWordmark.FONT.get_rids()[0]
	for letter: Dictionary in ChaosmosWordmark.LETTERS:
		var glyph: int = server.font_get_glyph_index(rid, 1000, String(letter["char"]).unicode_at(0), 0)
		var shape: Dictionary = server.font_get_glyph_contours(rid, 1000, glyph)
		var points: PackedVector3Array = shape["points"]
		var ends: PackedInt32Array = shape["contours"]
		var contours: Array[PackedVector2Array] = []
		var first: int = 0
		for last: int in ends:
			var piece: Array[Vector3] = []
			for index: int in range(first, last + 1):
				piece.append(points[index])
			contours.append(_flatten(piece, float(letter["x"])))
			first = last + 1
		var biggest: float = 0.0
		for contour: PackedVector2Array in contours:
			biggest = maxf(biggest, absf(_area(contour)))
		var sewn: Array = []
		for contour: PackedVector2Array in contours:
			var outer: bool = absf(_area(contour)) >= biggest
			for delta: float in [-INSET, INSET]:
				for moved: PackedVector2Array in Geometry2D.offset_polygon(contour, delta, Geometry2D.JOIN_ROUND):
					var shrank: bool = absf(_area(moved)) < absf(_area(contour))
					# Moving in can pinch a narrow part into a crumb of its own, too small to sew.
					if shrank == outer and absf(_area(moved)) > CRUMB:
						moved.append(moved[0])
						sewn.append(moved)
		lines.append(sewn)


# A TrueType contour (on-curve points and quadratic control points between them) as a closed polyline, in font
# units with y up, shifted along by `pen`.
static func _flatten(points: Array[Vector3], pen: float) -> PackedVector2Array:
	var count: int = points.size()
	var start: int = 0
	while start < count and int(points[start].z) != 1:
		start += 1
	var out: PackedVector2Array = PackedVector2Array()
	if start == count:
		return out
	var previous: Vector2 = Vector2(points[start].x, points[start].y)
	out.append(previous)
	var step: int = 1
	while step <= count:
		var point: Vector3 = points[(start + step) % count]
		var here: Vector2 = Vector2(point.x, point.y)
		if int(point.z) == 1:
			out.append(here)
			previous = here
		else:
			var next_point: Vector3 = points[(start + step + 1) % count]
			var next: Vector2 = Vector2(next_point.x, next_point.y)
			var end: Vector2 = next if int(next_point.z) == 1 else (here + next) * 0.5
			for part: int in range(1, 9):
				var u: float = float(part) / 8.0
				out.append(previous.lerp(here, u).lerp(here.lerp(end, u), u))
			previous = end
			if int(next_point.z) == 1:
				step += 1
		step += 1
	var placed: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in out:
		placed.append(Vector2(point.x + pen, -point.y))
	return placed


static func _area(polygon: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in range(polygon.size()):
		var a: Vector2 = polygon[index]
		var b: Vector2 = polygon[(index + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5
