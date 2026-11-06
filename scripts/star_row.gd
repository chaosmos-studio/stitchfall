class_name StitchfallStarRow
extends Control

# A row of three embroidered stars with their names under them. The clear card pops them in one by one by
# raising each one's pop from 0 to 1.

const GOLD: Color = Color("e7b84f")
const EMPTY: Color = Color("cbbca5")
const INK: Color = Color("493a37")
const THREAD: Color = Color("fff3d6")
const FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")

var earned: Array[bool] = [false, false, false]
var pop: Array[float] = [0.0, 0.0, 0.0]
var names: PackedStringArray = StitchfallProgress.STAR_NAMES
var radius: float = 62.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_pop(value: float, index: int) -> void:
	pop[index] = value
	queue_redraw()


func _draw() -> void:
	var gap: float = size.x / 3.0
	for index: int in range(3):
		var center: Vector2 = Vector2(gap * (float(index) + 0.5), radius + 10.0)
		var t: float = pop[index]
		# An earned star overshoots and settles. A missed one just fades in, empty.
		var grow: float = 1.0 + sin(t * PI) * 0.35 if earned[index] else 1.0
		var shown: bool = t > 0.0
		if earned[index] and t > 0.0 and t < 1.0:
			for ray: int in range(10):
				var direction: Vector2 = Vector2.from_angle(float(ray) * TAU / 10.0 + 0.3)
				draw_line(center + direction * radius * (0.9 + t * 0.6), center + direction * radius * (1.1 + t * 0.9), Color(GOLD, 1.0 - t), 4.0, true)
		draw_star(self, center, radius * (grow if shown else 1.0), earned[index] and shown, GOLD)
		draw_string(FONT, Vector2(gap * float(index), center.y + radius + 52.0), names[index], HORIZONTAL_ALIGNMENT_CENTER, gap, 30, Color(INK, 1.0 if earned[index] and shown else 0.45))


# A five-pointed star with an ink edge and a running stitch inside it, filled when earned.
static func draw_star(canvas: CanvasItem, center: Vector2, outer: float, filled: bool, colour: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var stitches: PackedVector2Array = PackedVector2Array()
	for corner: int in range(10):
		var angle: float = -PI * 0.5 + float(corner) * PI / 5.0
		var reach: float = outer if corner % 2 == 0 else outer * 0.46
		points.append(center + Vector2.from_angle(angle) * reach)
		stitches.append(center + Vector2.from_angle(angle) * reach * 0.72)
	var shadow: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		shadow.append(point + Vector2(3, 5))
	canvas.draw_colored_polygon(shadow, Color(INK, 0.22))
	canvas.draw_colored_polygon(points, colour if filled else EMPTY)
	points.append(points[0])
	canvas.draw_polyline(points, INK, maxf(2.0, outer * 0.06), true)
	stitches.append(stitches[0])
	for index: int in range(stitches.size() - 1):
		var from: Vector2 = stitches[index]
		var to: Vector2 = stitches[index + 1]
		canvas.draw_line(from, from.lerp(to, 0.55), Color(THREAD, 0.9 if filled else 0.5), maxf(1.2, outer * 0.035), true)
