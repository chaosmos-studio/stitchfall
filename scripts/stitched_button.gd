class_name StitchedButton
extends Button

const FONT: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")
const BODY_FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const MENU_FONT: FontFile = preload("res://assets/fonts/Threadline-Woven.ttf")
const PLATE: Texture2D = preload("res://assets/art/linen_button_plate.png")
const ICON_PATCH: Texture2D = preload("res://assets/art/linen_icon_patch.png")
const ICONS: Texture2D = preload("res://assets/art/stitched_icons.png")
const WORLD_ICONS: Texture2D = preload("res://assets/art/stitched_world_icons.png")
# The icons added with the wardrobe and the fuller menus, a 4 by 3 sheet in this order.
const EXTRA_ICONS: Texture2D = preload("res://assets/art/stitched_icons_extra.png")
const EXTRA_GLYPHS: PackedStringArray = ["wardrobe", "music", "music_off", "shake", "shake_off", "stats", "credits", "star", "lock", "bag", "gift", "link"]

var caption: String = ""
var subcaption: String = ""
var glyph: String = ""
var cloth: Color = Color("f1e2c8")
var ink: Color = Color("493a37")
var home_link: bool = false
var pause_action: bool = false
var level_tile: bool = false
# A level tile shows its best stars, or none while it is -1, and fades out while locked.
var stars: int = -1
var locked: bool = false
# A caption's font size, or 0 to size it from the button.
var caption_size: int = 0
# A pack in the Shop: a tall felt patch with its icon, name, what it holds, and its price or that it is owned.
var shop_card: bool = false
var lines: PackedStringArray = PackedStringArray()
var price_tag: String = ""
var owned: bool = false


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
	if pause_action:
		_draw_pause_action(hovered)
		return
	if level_tile:
		_draw_level_tile(hovered)
		return
	if shop_card:
		_draw_shop_card(hovered)
		return
	var lift: float = -3.0 if hovered else 0.0
	var tint: Color = cloth.lightened(0.13) if hovered else cloth
	if caption.is_empty():
		draw_texture_rect(ICON_PATCH, Rect2(Vector2(0, lift), size), false, tint)
	else:
		_draw_plate(lift, tint)
	var icon_center: Vector2 = Vector2(size.x * (0.5 if caption.is_empty() else 0.18), size.y * 0.48 + lift)
	var icon_scale: float = minf(size.x, size.y) * (0.26 if caption.is_empty() else 0.19)
	if not glyph.is_empty():
		_draw_icon(icon_center, icon_scale)
	if not caption.is_empty():
		var font_size: int = caption_size if caption_size > 0 else (55 if size.x >= 680 else (44 if size.y > 110 else 38))
		var text_left: float = 18.0 if glyph.is_empty() else size.x * 0.33
		var baseline: float = size.y * (0.54 if subcaption.is_empty() else 0.42) + lift
		draw_string(FONT, Vector2(text_left, baseline), caption, HORIZONTAL_ALIGNMENT_CENTER if subcaption.is_empty() else HORIZONTAL_ALIGNMENT_LEFT, size.x - text_left * 2.0 if glyph.is_empty() else size.x - text_left - 34.0, font_size, ink)
		if not subcaption.is_empty():
			var small_size: int = 43 if size.x > 720 else 32
			draw_string(BODY_FONT, Vector2(text_left, size.y * 0.78 + lift), subcaption, HORIZONTAL_ALIGNMENT_LEFT, size.x - text_left - 34.0, small_size, ink)


func _draw_home_link(hovered: bool) -> void:
	var icon_size: float = 92.0 if glyph == "play" else 77.0
	var icon_position: Vector2 = Vector2(9.0, (size.y - icon_size) * 0.5)
	var tint: Color = cloth.lightened(0.1) if hovered else cloth
	draw_texture_rect(ICON_PATCH, Rect2(icon_position, Vector2.ONE * icon_size), false, tint)
	_draw_icon(icon_position + Vector2.ONE * icon_size * 0.5, icon_size * 0.24)
	var baseline: float = size.y * 0.68
	var font_size: int = 59 if glyph == "play" else 48
	var label_color: Color = ink.lightened(0.1) if hovered else ink
	draw_string(MENU_FONT, Vector2(121, baseline), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 135.0, font_size, label_color)


func _draw_pause_action(hovered: bool) -> void:
	var lift: float = -5.0 if hovered else 0.0
	var patch_size: float = minf(size.x - 20.0, size.y * 0.72)
	var patch_position: Vector2 = Vector2((size.x - patch_size) * 0.5, 0.0 + lift)
	var tint: Color = cloth.lightened(0.12) if hovered else cloth
	draw_texture_rect(ICON_PATCH, Rect2(patch_position, Vector2.ONE * patch_size), false, tint)
	_draw_icon(patch_position + Vector2.ONE * patch_size * 0.5, patch_size * 0.23)
	var font_size: int = caption_size if caption_size > 0 else (32 if caption.length() > 8 else (46 if size.x > 260.0 else 42))
	draw_string(MENU_FONT, Vector2(0, size.y - 8.0 + lift), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, ink)


func _draw_level_tile(hovered: bool) -> void:
	var lift: float = -4.0 if hovered and not locked else 0.0
	var tint: Color = cloth.lightened(0.1) if hovered and not locked else cloth
	if locked:
		tint = tint.darkened(0.25)
	var faded: Color = Color(ink, 0.45) if locked else ink
	draw_texture_rect(ICON_PATCH, Rect2(Vector2(12, lift), Vector2(size.x - 24.0, size.y - 42.0)), false, tint)
	draw_string(MENU_FONT, Vector2(0, size.y * 0.5 + lift), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 88, faded)
	if stars >= 0 and not locked:
		for index: int in range(3):
			StitchfallStarRow.draw_star(self, Vector2(size.x * 0.5 + float(index - 1) * 46.0, size.y * 0.66 + lift), 19.0, index < stars, StitchfallStarRow.GOLD)
	draw_string(BODY_FONT, Vector2(0, size.y - 1.0 + lift), "Locked" if locked else subcaption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, faded)


func _draw_shop_card(hovered: bool) -> void:
	var lift: float = -4.0 if hovered and not owned else 0.0
	var tint: Color = cloth.lightened(0.1) if hovered and not owned else cloth
	draw_texture_rect(ICON_PATCH, Rect2(Vector2(6, lift), Vector2(size.x - 12.0, size.y - 8.0)), false, tint)
	_draw_icon(Vector2(size.x * 0.5, 104.0 + lift), 44.0)
	draw_string(MENU_FONT, Vector2(0, 214.0 + lift), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, caption_size if caption_size > 0 else 40, ink)
	for index: int in range(lines.size()):
		draw_string(BODY_FONT, Vector2(20, 262.0 + float(index) * 38.0 + lift), lines[index], HORIZONTAL_ALIGNMENT_CENTER, size.x - 40.0, 26, ink)
	var status: String = "YOURS" if owned else price_tag
	draw_string(FONT, Vector2(0, size.y - 46.0 + lift), status, HORIZONTAL_ALIGNMENT_CENTER, size.x, 40, Color("5f8b5a") if owned else Color("a85648"))


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


func _draw_icon(center: Vector2, radius: float) -> void:
	var extra_index: int = EXTRA_GLYPHS.find(glyph)
	if extra_index >= 0:
		var extra_cell: Vector2 = Vector2(float(EXTRA_ICONS.get_width()) / 4.0, float(EXTRA_ICONS.get_height()) / 3.0)
		var extra_source: Rect2 = Rect2(Vector2(float(extra_index % 4) * extra_cell.x, float(extra_index / 4) * extra_cell.y), extra_cell)
		draw_texture_rect_region(EXTRA_ICONS, Rect2(center - Vector2.ONE * radius * 1.325, Vector2.ONE * radius * 2.65), extra_source)
		return
	var icon_index: int = ["play", "home", "help", "settings", "pause", "restart", "levels", "back", "next", "sound", "mute", "fullscreen"].find(glyph)
	if icon_index >= 0:
		var cell: Vector2 = Vector2(float(ICONS.get_width()) / 4.0, float(ICONS.get_height()) / 3.0)
		var source: Rect2 = Rect2(Vector2(float(icon_index % 4) * cell.x, float(icon_index / 4) * cell.y), cell)
		var extent: Vector2 = Vector2.ONE * radius * 2.65
		draw_texture_rect_region(ICONS, Rect2(center - extent * 0.5, extent), source)
		return
	var world_index: int = ["move", "jump", "crouch", "shift", "seam", "water", "dunes", "forest", "night", "rain", "frost", "knot"].find(glyph)
	if world_index >= 0:
		var world_cell: Vector2 = Vector2(float(WORLD_ICONS.get_width()) / 4.0, float(WORLD_ICONS.get_height()) / 3.0)
		var world_source: Rect2 = Rect2(Vector2(float(world_index % 4) * world_cell.x, float(world_index / 4) * world_cell.y), world_cell)
		var world_extent: Vector2 = Vector2.ONE * radius * 2.65
		draw_texture_rect_region(WORLD_ICONS, Rect2(center - world_extent * 0.5, world_extent), world_source)
