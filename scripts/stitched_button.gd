class_name StitchedButton
extends Button

const FONT: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")
const BODY_FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const PLATE: Texture2D = preload("res://assets/art/linen_button_plate.png")
const ICON_PATCH: Texture2D = preload("res://assets/art/linen_icon_patch.png")

var caption: String = ""
var subcaption: String = ""
var glyph: String = ""
var cloth: Color = Color("f1e2c8")
var thread: Color = Color("8f6758")
var ink: Color = Color("493a37")
var compact: bool = false
var home_link: bool = false


func _ready() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	resized.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _draw() -> void:
	var hovered: bool = is_hovered() or has_focus()
	if home_link:
		_draw_home_link(hovered)
		return
	var lift: float = -3.0 if hovered else 0.0
	var tint: Color = cloth.lightened(0.13) if hovered else cloth
	if caption.is_empty():
		draw_texture_rect(ICON_PATCH, Rect2(Vector2(0, lift), size), false, tint)
	else:
		_draw_plate(lift, tint)
	var icon_center: Vector2 = Vector2(size.x * (0.5 if caption.is_empty() or compact else 0.18), size.y * (0.29 if compact else 0.48) + lift)
	var icon_scale: float = minf(size.x, size.y) * (0.15 if compact else (0.26 if caption.is_empty() else 0.19))
	if not glyph.is_empty():
		_draw_icon(icon_center, icon_scale, ink)
	if not caption.is_empty():
		var font_size: int = 43 if compact else (55 if size.x >= 680 else (44 if size.y > 110 else 38))
		var text_left: float = 18.0 if compact else (40.0 if glyph.is_empty() else size.x * 0.33)
		var baseline: float = size.y * (0.74 if compact else (0.54 if subcaption.is_empty() else 0.42)) + lift
		draw_string(FONT, Vector2(text_left, baseline), caption, HORIZONTAL_ALIGNMENT_CENTER if compact or subcaption.is_empty() else HORIZONTAL_ALIGNMENT_LEFT, size.x - text_left * 2.0 if compact else size.x - text_left - 34.0, font_size, ink)
		if not subcaption.is_empty():
			var small_size: int = 43 if size.x > 720 else 32
			draw_string(BODY_FONT, Vector2(text_left, size.y * 0.78 + lift), subcaption, HORIZONTAL_ALIGNMENT_LEFT, size.x - text_left - 34.0, small_size, ink)


func _draw_home_link(hovered: bool) -> void:
	var icon_size: float = 92.0 if glyph == "play" else 77.0
	var icon_position: Vector2 = Vector2(9.0, (size.y - icon_size) * 0.5)
	var tint: Color = cloth.lightened(0.1) if hovered else cloth
	draw_texture_rect(ICON_PATCH, Rect2(icon_position, Vector2.ONE * icon_size), false, tint)
	_draw_icon(icon_position + Vector2.ONE * icon_size * 0.5, icon_size * 0.24, ink)
	var baseline: float = size.y * 0.68
	var font_size: int = 62 if glyph == "play" else 50
	var label_color: Color = ink.lightened(0.1) if hovered else ink
	draw_string(FONT, Vector2(121, baseline), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 135.0, font_size, label_color)
	if hovered or glyph == "play":
		var line_y: float = size.y - 12.0
		var line_end: float = minf(size.x - 21.0, 145.0 + FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		for step: int in range(int((line_end - 122.0) / 16.0) + 1):
			var x: float = 122.0 + float(step) * 16.0
			draw_line(Vector2(x, line_y), Vector2(minf(x + 8.0, line_end), line_y), thread, 2.0, true)


func _draw_plate(lift: float, tint: Color) -> void:
	var source_x: Array[float] = [20.0, 430.0, float(PLATE.get_width()) - 430.0, float(PLATE.get_width()) - 20.0]
	var source_y: Array[float] = [110.0, 250.0, float(PLATE.get_height()) - 250.0, float(PLATE.get_height()) - 110.0]
	var horizontal: float = minf(size.y * 0.48, size.x * 0.22)
	var vertical: float = size.y * 0.34
	var dest_x: Array[float] = [0.0, horizontal, size.x - horizontal, size.x]
	var dest_y: Array[float] = [lift, lift + vertical, lift + size.y - vertical, lift + size.y]
	for row: int in range(3):
		for column: int in range(3):
			var destination: Rect2 = Rect2(dest_x[column], dest_y[row], dest_x[column + 1] - dest_x[column], dest_y[row + 1] - dest_y[row])
			var source: Rect2 = Rect2(source_x[column], source_y[row], source_x[column + 1] - source_x[column], source_y[row + 1] - source_y[row])
			draw_texture_rect_region(PLATE, destination, source, tint)


func _draw_icon(center: Vector2, radius: float, color: Color) -> void:
	var p: Vector2 = center
	var r: float = radius
	match glyph:
		"pause":
			draw_line(p + Vector2(-r * 0.34, -r * 0.62), p + Vector2(-r * 0.34, r * 0.62), color, 7.0, true)
			draw_line(p + Vector2(r * 0.34, -r * 0.62), p + Vector2(r * 0.34, r * 0.62), color, 7.0, true)
		"play":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.5, -r * 0.72), p + Vector2(r * 0.7, 0), p + Vector2(-r * 0.5, r * 0.72)]), color)
		"home":
			draw_polyline(PackedVector2Array([p + Vector2(-r * 0.78, -r * 0.08), p + Vector2(0, -r * 0.75), p + Vector2(r * 0.78, -r * 0.08)]), color, 5.0, true)
			draw_rect(Rect2(p + Vector2(-r * 0.54, -r * 0.05), Vector2(r * 1.08, r * 0.78)), color, false, 4.0, true)
			draw_line(p + Vector2(0, r * 0.7), p + Vector2(0, r * 0.2), color, 3.0, true)
		"back":
			draw_line(p + Vector2(r * 0.62, 0), p + Vector2(-r * 0.62, 0), color, 5.0, true)
			draw_polyline(PackedVector2Array([p + Vector2(-r * 0.1, -r * 0.55), p + Vector2(-r * 0.7, 0), p + Vector2(-r * 0.1, r * 0.55)]), color, 5.0, true)
		"next":
			draw_line(p + Vector2(-r * 0.62, 0), p + Vector2(r * 0.62, 0), color, 5.0, true)
			draw_polyline(PackedVector2Array([p + Vector2(r * 0.1, -r * 0.55), p + Vector2(r * 0.7, 0), p + Vector2(r * 0.1, r * 0.55)]), color, 5.0, true)
		"levels":
			for x: int in range(2):
				for y: int in range(2):
					var q: Vector2 = p + Vector2((float(x) - 0.5) * r * 0.82, (float(y) - 0.5) * r * 0.82)
					draw_rect(Rect2(q - Vector2.ONE * r * 0.27, Vector2.ONE * r * 0.54), color, false, 3.0, true)
		"restart":
			draw_arc(p, r * 0.64, -PI * 0.65, PI * 0.85, 20, color, 5.0, true)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.67, -r * 0.12), p + Vector2(-r * 0.78, -r * 0.7), p + Vector2(-r * 0.15, -r * 0.51)]), color)
		"help":
			draw_arc(p + Vector2(0, -r * 0.18), r * 0.36, PI * 1.12, TAU * 1.08, 16, color, 4.0, true)
			draw_line(p + Vector2(r * 0.2, r * 0.05), p + Vector2(0, r * 0.36), color, 4.0, true)
			draw_circle(p + Vector2(0, r * 0.64), 3.5, color)
		"sound":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.74, -r * 0.27), p + Vector2(-r * 0.38, -r * 0.27), p + Vector2(0, -r * 0.6), p + Vector2(0, r * 0.6), p + Vector2(-r * 0.38, r * 0.27), p + Vector2(-r * 0.74, r * 0.27)]), color)
			draw_arc(p, r * 0.49, -PI * 0.34, PI * 0.34, 12, color, 3.5, true)
		"mute":
			_draw_icon_speaker(p, r, color)
			draw_line(p + Vector2(r * 0.28, -r * 0.44), p + Vector2(r * 0.83, r * 0.44), color, 4.0, true)
		"settings":
			draw_arc(p, r * 0.58, 0, TAU, 24, color, 4.0, true)
			draw_circle(p, r * 0.18, color)
			for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
				var q: Vector2 = p + Vector2.from_angle(angle) * r * 0.73
				draw_line(q - Vector2.from_angle(angle) * r * 0.12, q + Vector2.from_angle(angle) * r * 0.12, color, 5.0, true)
		"fullscreen":
			for side_x: float in [-1.0, 1.0]:
				for side_y: float in [-1.0, 1.0]:
					var corner: Vector2 = p + Vector2(side_x, side_y) * r * 0.65
					draw_line(corner, corner - Vector2(side_x * r * 0.37, 0), color, 5.0, true)
					draw_line(corner, corner - Vector2(0, side_y * r * 0.37), color, 5.0, true)
		"seam":
			draw_arc(p, r * 0.52, 0, TAU, 24, color, 3.0, true)
			for angle: float in [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]:
				draw_circle(p + Vector2.from_angle(angle) * r * 0.29, 2.5, color)
		"move":
			draw_line(p + Vector2(-r * 0.65, 0), p + Vector2(r * 0.65, 0), color, 4.0, true)
			for side: float in [-1.0, 1.0]:
				var tip: Vector2 = p + Vector2(side * r * 0.74, 0)
				draw_polyline(PackedVector2Array([tip - Vector2(side * r * 0.3, r * 0.3), tip, tip - Vector2(side * r * 0.3, -r * 0.3)]), color, 4.0, true)
		"jump":
			draw_line(p + Vector2(0, r * 0.7), p + Vector2(0, -r * 0.6), color, 4.0, true)
			draw_polyline(PackedVector2Array([p + Vector2(-r * 0.34, -r * 0.22), p + Vector2(0, -r * 0.7), p + Vector2(r * 0.34, -r * 0.22)]), color, 4.0, true)
			draw_arc(p + Vector2(0, r * 0.58), r * 0.42, PI, TAU, 14, color, 2.0, true)
		"crouch":
			draw_line(p + Vector2(0, -r * 0.65), p + Vector2(0, r * 0.28), color, 4.0, true)
			draw_polyline(PackedVector2Array([p + Vector2(-r * 0.32, 0), p + Vector2(0, r * 0.4), p + Vector2(r * 0.32, 0)]), color, 4.0, true)
			draw_line(p + Vector2(-r * 0.65, r * 0.68), p + Vector2(r * 0.65, r * 0.68), color, 4.0, true)
		"shift":
			draw_arc(p, r * 0.62, -PI * 0.72, PI * 0.28, 18, color, 4.0, true)
			draw_arc(p, r * 0.62, PI * 0.28, PI * 1.28, 18, color, 4.0, true)
			draw_colored_polygon(PackedVector2Array([p + Vector2(r * 0.51, -r * 0.47), p + Vector2(r * 0.8, -r * 0.47), p + Vector2(r * 0.68, -r * 0.07)]), color)
		"water":
			for row: int in range(2):
				for column: int in range(2):
					var q: Vector2 = p + Vector2((float(column) - 0.5) * r * 0.95, (float(row) - 0.5) * r * 0.6)
					draw_arc(q, r * 0.32, 0, PI, 12, color, 3.0, true)
		"dunes":
			draw_polyline(PackedVector2Array([p + Vector2(-r * 0.78, r * 0.45), p + Vector2(-r * 0.12, -r * 0.36), p + Vector2(r * 0.72, r * 0.45)]), color, 3.0, true)
			draw_line(p + Vector2(-r * 0.4, r * 0.57), p + Vector2(r * 0.7, r * 0.57), color, 2.0, true)
		"forest":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.5, r * 0.5), p + Vector2(-r * 0.28, -r * 0.5), p + Vector2(r * 0.5, -r * 0.42), p + Vector2(r * 0.32, r * 0.4)]), color)
			draw_line(p + Vector2(-r * 0.64, r * 0.7), p + Vector2(r * 0.32, -r * 0.31), Color("f4ead4"), 2.0, true)
		"night":
			for q: Vector2 in [p, p + Vector2(-r * 0.5, -r * 0.3), p + Vector2(r * 0.48, r * 0.25)]:
				draw_line(q + Vector2(0, -r * 0.23), q + Vector2(0, r * 0.23), color, 2.0, true)
				draw_line(q + Vector2(-r * 0.23, 0), q + Vector2(r * 0.23, 0), color, 2.0, true)
		"rain":
			for column: int in range(3):
				var q: Vector2 = p + Vector2((float(column) - 1.0) * r * 0.5, (float(column % 2) - 0.5) * r * 0.3)
				draw_line(q + Vector2(3, -r * 0.36), q + Vector2(-3, r * 0.37), color, 3.0, true)
		"frost":
			for angle: float in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
				var d: Vector2 = Vector2.from_angle(angle) * r * 0.72
				draw_line(p - d, p + d, color, 3.0, true)


func _draw_icon_speaker(p: Vector2, r: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.74, -r * 0.27), p + Vector2(-r * 0.38, -r * 0.27), p + Vector2(0, -r * 0.6), p + Vector2(0, r * 0.6), p + Vector2(-r * 0.38, r * 0.27), p + Vector2(-r * 0.74, r * 0.27)]), color)
