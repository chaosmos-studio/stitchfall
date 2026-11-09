class_name ChaosmosWordmark
extends RefCounted

# The Chaosmos wordmark as tools/brand.py in the studio site draws it: "chaosmos" in Bricolage Grotesque
# ExtraBold, its first o the Filling ring (an ink ring half full of coral water) and its second a full coral
# disc. Everything is in font units (1000 to the em), y up from the baseline, measured from the font.

const FONT: FontFile = preload("res://intro/fonts/BricolageGrotesque-ExtraBold.ttf")
const INK: Color = Color("141414")
const CORAL: Color = Color("ff6b6b")
const PAPER: Color = Color("fbfbfd")
const CHARCOAL: Color = Color("121212")
const LIGHT: Color = Color("ececec")
# The studio's ball colours, from brand.py.
const BALLS: Array[Color] = [Color("ff6b6b"), Color("22b5a6"), Color("ffb020"), Color("7b6cf6"), Color("6ec8ff")]

# Each letter's pen position and its ink's left and right edge.
const LETTERS: Array[Dictionary] = [
	{"char": "c", "x": 0.0, "left": 22.0, "right": 525.0},
	{"char": "h", "x": 499.0, "left": 36.0, "right": 531.0},
	{"char": "a", "x": 1021.0, "left": 17.0, "right": 513.0},
	{"char": "s", "x": 2051.0, "left": 23.5, "right": 501.0},
	{"char": "m", "x": 2528.0, "left": 36.0, "right": 829.0},
	{"char": "s", "x": 3875.0, "left": 23.5, "right": 501.0},
]
const X_HEIGHT: float = 542.0
# The two o's: their middles, the height of their middles and their radius. The ring's stroke.
const RING_X: float = 1807.5
const DISC_X: float = 3631.5
const O_Y: float = 264.0
const O_RADIUS: float = 270.0
const RING_STROKE: float = 112.0
# The water's surface: its level, its height either side of it, its length and where its crest is.
const WATER_LEVEL: float = 249.4
const WATER_AMP: float = 43.8
const WATER_LENGTH: float = 583.8
const WATER_CREST: float = 1676.0
# The ink's edges and its middle, for centring.
const INK_LEFT: float = 22.0
const INK_RIGHT: float = 4376.0
const INK_MIDDLE: float = 2199.0

# Where font unit (0, 0) lands on screen and how many pixels a font unit is.
var origin: Vector2 = Vector2.ZERO
var unit: float = 0.2


# Fits the word `share` of the view's width (or less on a short view) with the o's middles on the view's middle.
func fit(view: Vector2, share: float = 0.7) -> void:
	var wide: float = minf(view.x * share, view.y * 0.85)
	unit = wide / (INK_RIGHT - INK_LEFT)
	origin = Vector2(view.x * 0.5 - INK_MIDDLE * unit, view.y * 0.5 + O_Y * unit)


func at(x: float, y: float) -> Vector2:
	return origin + Vector2(x, -y) * unit


func ring_centre() -> Vector2:
	return at(RING_X, O_Y)


func disc_centre() -> Vector2:
	return at(DISC_X, O_Y)


# A letter's middle at the x-height's half, which a letter turns and scales about.
func letter_centre(index: int) -> Vector2:
	var letter: Dictionary = LETTERS[index]
	return at(float(letter["x"]) + (float(letter["left"]) + float(letter["right"])) * 0.5, X_HEIGHT * 0.5)


# Draws letter `index` with its middle moved to `centre`, turned and scaled about it.
func draw_letter(canvas: CanvasItem, index: int, centre: Vector2, color: Color, angle: float = 0.0, scale: Vector2 = Vector2.ONE) -> void:
	var letter: Dictionary = LETTERS[index]
	var pen: Vector2 = Vector2(-(float(letter["left"]) + float(letter["right"])) * 0.5, X_HEIGHT * 0.5) * unit
	canvas.draw_set_transform(centre, angle, scale)
	canvas.draw_char(FONT, pen, letter["char"], int(round(1000.0 * unit)), color)
	canvas.draw_set_transform(Vector2.ZERO)


# Only the letter's outline, `width` font units wide.
func draw_letter_outline(canvas: CanvasItem, index: int, centre: Vector2, color: Color, width: float, angle: float = 0.0, scale: Vector2 = Vector2.ONE) -> void:
	var letter: Dictionary = LETTERS[index]
	var pen: Vector2 = Vector2(-(float(letter["left"]) + float(letter["right"])) * 0.5, X_HEIGHT * 0.5) * unit
	canvas.draw_set_transform(centre, angle, scale)
	canvas.draw_char_outline(FONT, pen, letter["char"], int(round(1000.0 * unit)), maxi(int(round(width * unit)), 1), color)
	canvas.draw_set_transform(Vector2.ZERO)


# The ring around `centre`, `sweep` of the way round from the top, `radius` scaled by `size`.
func draw_ring(canvas: CanvasItem, centre: Vector2, color: Color, size: float = 1.0, sweep: float = 1.0, stroke: float = 1.0) -> void:
	if sweep <= 0.0:
		return
	var radius: float = (O_RADIUS - RING_STROKE * 0.5) * unit * size
	canvas.draw_arc(centre, radius, -PI * 0.5, -PI * 0.5 + TAU * minf(sweep, 1.0), 96, color, RING_STROKE * unit * size * stroke, true)


# The water inside the ring: its level raised by `fill` from empty (0) to the brand's level (1), its wave moved
# along by `phase` (in wave lengths), `wobble` times as tall and tipped by `tilt` radians.
func draw_water(canvas: CanvasItem, centre: Vector2, color: Color, size: float = 1.0, fill: float = 1.0, phase: float = 0.0, wobble: float = 1.0, tilt: float = 0.0) -> void:
	if fill <= 0.0:
		return
	var inner: float = (O_RADIUS - RING_STROKE) * unit * size + 1.5
	var bottom: float = -inner
	var level: float = lerpf(bottom, (WATER_LEVEL - O_Y) * unit * size, clampf(fill, 0.0, 1.0))
	var surface: PackedVector2Array = PackedVector2Array()
	var steps: int = 48
	for step: int in range(steps + 1):
		var x: float = lerpf(-inner, inner, float(step) / float(steps))
		var font_x: float = RING_X + x / (unit * size)
		var wave: float = WATER_AMP * wobble * sin(TAU * ((font_x - WATER_CREST + WATER_LENGTH * 0.25) / WATER_LENGTH - phase))
		var y: float = level + wave * unit * size + x * tan(tilt)
		surface.append(centre + Vector2(x, -y))
	var region: PackedVector2Array = surface.duplicate()
	region.append(centre + Vector2(inner, inner * 2.0))
	region.append(centre + Vector2(-inner, inner * 2.0))
	var circle: PackedVector2Array = PackedVector2Array()
	for step: int in range(64):
		circle.append(centre + Vector2.from_angle(float(step) / 64.0 * TAU) * inner)
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(circle, region):
		canvas.draw_colored_polygon(piece, color)


func draw_disc(canvas: CanvasItem, centre: Vector2, color: Color, size: float = 1.0, squash: Vector2 = Vector2.ONE) -> void:
	var radius: float = O_RADIUS * unit * size
	if radius <= 0.0:
		return
	canvas.draw_set_transform(centre, 0.0, squash)
	canvas.draw_circle(Vector2.ZERO, radius, color, true, -1.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
