class_name StitchfallItemTile
extends Button

# One piece in the wardrobe: a felt patch with a preview of the piece, its name, and whether it is worn,
# open to wear, or what opens it.

const PATCH: Texture2D = preload("res://assets/art/linen_icon_patch.png")
const NAME_FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const STATUS_FONT: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")
const INK: Color = Color("493a37")
const ACCENT: Color = Color("a85648")

var item: Dictionary = {}
var open: bool = true
var worn: bool = false
var picture: Texture2D


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func show_item(piece: Dictionary, is_open: bool, is_worn: bool) -> void:
	item = piece
	open = is_open
	worn = is_worn
	picture = null
	if item["kind"] == "runner":
		picture = load(StitchfallLooks.runner_art(item["id"])["poses"][0]) as Texture2D
	elif item["kind"] == "fabric":
		picture = load(item["art"]) as Texture2D
	queue_redraw()


func _draw() -> void:
	if item.is_empty():
		return
	var hovered: bool = is_hovered() or has_focus()
	var lift: float = -4.0 if hovered else 0.0
	var tint: Color = Color("f1e1c8") if open else Color("cdbfa8")
	draw_texture_rect(PATCH, Rect2(Vector2(6, lift), Vector2(size.x - 12.0, size.y - 70.0)), false, tint.lightened(0.08) if hovered else tint)
	if worn:
		draw_rect(Rect2(Vector2(14, 8 + lift), Vector2(size.x - 28.0, size.y - 86.0)), Color("e0a278"), false, 5.0)
	var centre: Vector2 = Vector2(size.x * 0.5, (size.y - 70.0) * 0.5 + lift)
	var faded: Color = Color(1, 1, 1, 1.0 if open else 0.45)
	match str(item["kind"]):
		"runner":
			var tall: float = size.y - 100.0
			var wide: float = tall * float(picture.get_width()) / float(picture.get_height())
			draw_texture_rect(picture, Rect2(centre - Vector2(wide, tall) * 0.5, Vector2(wide, tall)), false, faded)
		"fabric":
			draw_texture_rect_region(picture, Rect2(centre - Vector2(80, 60), Vector2(160, 120)), Rect2(Vector2(picture.get_width() * 0.3, picture.get_height() * 0.35), Vector2(picture.get_width() * 0.4, picture.get_height() * 0.3)), faded)
		"trail":
			if item["colours"].is_empty():
				draw_string(NAME_FONT, centre + Vector2(-80, 12), "none", HORIZONTAL_ALIGNMENT_CENTER, 160, 30, Color(INK, 0.5))
			else:
				StitchfallLooks.draw_trail_sample(self, centre - Vector2(80, 0), centre + Vector2(80, 0), item)
		"unravel":
			_draw_burst(centre, item)
		"button":
			StitchfallLooks.draw_button(self, centre, 40.0, item["colour"])
	draw_string(NAME_FONT, Vector2(0, size.y - 38.0 + lift), item["name"], HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, INK)
	var status: String = "Wearing" if worn else ("Wear" if open else StitchfallLooks.price_text(item))
	draw_string(STATUS_FONT, Vector2(0, size.y - 4.0 + lift), status, HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, ACCENT if not open else INK)


func _draw_burst(centre: Vector2, piece: Dictionary) -> void:
	var colours: Array = piece["colours"]
	for index: int in range(10):
		var angle: float = float(index) * TAU / 10.0
		var at: Vector2 = centre + Vector2.from_angle(angle) * 48.0
		var colour: Color = colours[index % colours.size()]
		match str(piece["shape"]):
			"button":
				draw_circle(at, 9.0, INK)
				draw_circle(at, 7.5, colour)
			"petal":
				draw_set_transform(at, angle, Vector2(1.0, 0.55))
				draw_circle(Vector2.ZERO, 11.0, colour)
				draw_set_transform(Vector2.ZERO)
			"star":
				StitchfallStarRow.draw_star(self, at, 11.0, true, colour)
			"snip":
				draw_set_transform(at, angle * 2.0, Vector2.ONE)
				draw_rect(Rect2(-10, -3, 20, 6), colour)
				draw_set_transform(Vector2.ZERO)
			_:
				draw_line(centre + Vector2.from_angle(angle) * 22.0, at, colour.darkened(0.25), 3.0, true)
