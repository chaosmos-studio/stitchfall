class_name ChaosmosIntroStyle
extends RefCounted

# One way of bringing the wordmark in. A style draws the whole frame at time `t` (seconds from the start) and
# says how long it runs and which sting plays with it. The intro fades it out at the end.

var word: ChaosmosWordmark
# The colours of the light or dark version: background, ink and coral.
var paper: Color = ChaosmosWordmark.PAPER
var ink: Color = ChaosmosWordmark.INK
var coral: Color = ChaosmosWordmark.CORAL


func title() -> String:
	return ""


# Seconds until the word stands complete and still. The intro holds it, then fades.
func settle() -> float:
	return 1.8


func sting() -> String:
	return ""


# The colour behind everything, which the intro also fades to.
func background() -> Color:
	return paper


# True for a style that draws in big pixels at some point (Pixel), which the intro then draws through a
# SubViewport it can shrink.
func pixel_art() -> bool:
	return false


# How many screen pixels make one of the stage's pixels at time `t`. Only Pixel asks for more than one.
func pixel(_t: float) -> int:
	return 1


# What the style plays on: its sky, cloth or glass, behind everything `draw` adds. In a game the intro lets this go
# first, so the game's Home shows through while the word stays a moment longer. A style that draws its own
# background here leaves it out of `draw`.
func draw_back(canvas: CanvasItem, _t: float, view: Vector2) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, view), background())


func draw(_canvas: CanvasItem, _t: float, _view: Vector2) -> void:
	pass


# The whole word at rest, which every style ends on.
func draw_rest(canvas: CanvasItem, phase: float = 0.0) -> void:
	for index: int in range(ChaosmosWordmark.LETTERS.size()):
		word.draw_letter(canvas, index, word.letter_centre(index), ink)
	word.draw_water(canvas, word.ring_centre(), coral, 1.0, 1.0, phase)
	word.draw_ring(canvas, word.ring_centre(), ink)
	word.draw_disc(canvas, word.disc_centre(), coral)


# A soft round light, white in the middle and clear at the edge, for glows, flares and vignettes.
static var _glow: GradientTexture2D


static func glow() -> GradientTexture2D:
	if _glow == null:
		var gradient: Gradient = Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.35, Color(1, 1, 1, 0.45))
		_glow = GradientTexture2D.new()
		_glow.gradient = gradient
		_glow.fill = GradientTexture2D.FILL_RADIAL
		_glow.fill_from = Vector2(0.5, 0.5)
		_glow.fill_to = Vector2(1.0, 0.5)
		_glow.width = 256
		_glow.height = 256
	return _glow


static func draw_glow(canvas: CanvasItem, centre: Vector2, size: Vector2, color: Color) -> void:
	canvas.draw_texture_rect(glow(), Rect2(centre - size * 0.5, size), false, color)


# 0 before `from`, 1 after `to`, and straight between.
static func span(t: float, from: float, to: float) -> float:
	return clampf((t - from) / (to - from), 0.0, 1.0)


static func out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


static func in_out_cubic(x: float) -> float:
	return 4.0 * x * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 3.0) * 0.5


static func out_back(x: float, overshoot: float = 1.70158) -> float:
	var c3: float = overshoot + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + overshoot * pow(x - 1.0, 2.0)


static func out_bounce(x: float) -> float:
	var n: float = 7.5625
	var d: float = 2.75
	if x < 1.0 / d:
		return n * x * x
	if x < 2.0 / d:
		x -= 1.5 / d
		return n * x * x + 0.75
	if x < 2.5 / d:
		x -= 2.25 / d
		return n * x * x + 0.9375
	x -= 2.625 / d
	return n * x * x + 0.984375


static func out_elastic(x: float) -> float:
	if x <= 0.0 or x >= 1.0:
		return clampf(x, 0.0, 1.0)
	return pow(2.0, -10.0 * x) * sin((x * 10.0 - 0.75) * TAU / 3.0) + 1.0


static func in_out_expo(x: float) -> float:
	if x <= 0.0 or x >= 1.0:
		return clampf(x, 0.0, 1.0)
	return pow(2.0, 20.0 * x - 10.0) * 0.5 if x < 0.5 else (2.0 - pow(2.0, -20.0 * x + 10.0)) * 0.5
