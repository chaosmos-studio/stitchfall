class_name StitchedButton
extends Button

const FONT: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")
const BODY_FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const MENU_FONT: FontFile = preload("res://assets/fonts/Threadline-Woven.ttf")
const ICON_PATCH: Texture2D = preload("res://assets/art/linen_icon_patch.png")
const ICONS: Texture2D = preload("res://assets/art/stitched_icons.png")
const WORLD_ICONS: Texture2D = preload("res://assets/art/stitched_world_icons.png")
# A 4 by 3 sheet whose icons run in this order.
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
# The room Play would open next: an accent ring and a NEXT tag, breathing slowly.
var next_up: bool = false
var age: float = 0.0
# A caption's font size, or 0 to size it from the button.
var caption_size: int = 0
# A pack in the Shop: a tall felt patch with its icon, name, what it holds, and its price or that it is owned.
var shop_card: bool = false
var lines: PackedStringArray = PackedStringArray()
var price_tag: String = ""
var owned: bool = false
# A Settings row's switch: -1 for none, else 0 off and 1 on. A row that opens a page shows a small arrow instead.
var switch_on: int = -1
var arrow: bool = false
var press: Tween

const PRESS_SCALE: float = 0.94
# The card's stitching: a dash this long every period, this far inside the edge.
const STITCH_DASH: float = 9.0
const STITCH_PERIOD: float = 16.0
const STITCH_INSET: float = 9.0
const CARD_EDGE: Color = Color("947a65")
const CARD_SHADOW: Color = Color("45372f", 0.2)
const CARD_DROP: float = 6.0
# The fonts' capital height as a share of their size (all three fonts' OS/2 tables say 700 of 1000).
const CAP_HEIGHT: float = 0.7
const SWITCH_SIZE: Vector2 = Vector2(96, 52)
const SWITCH_ON: Color = Color("6f9a64")
const SWITCH_OFF: Color = Color("cbbda6")


func _squeeze(to: float, seconds: float, trans: Tween.TransitionType, curve: Tween.EaseType) -> void:
	if press != null:
		press.kill()
	press = create_tween()
	press.tween_property(self, "scale", Vector2.ONE * to, seconds).set_trans(trans).set_ease(curve)


func _ready() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	resized.connect(func() -> void:
		pivot_offset = size * 0.5
		queue_redraw())
	pivot_offset = size * 0.5
	# A press squeezes the patch in fast and lets it spring back on release, so a thumb feels it land.
	button_down.connect(func() -> void: _squeeze(PRESS_SCALE, 0.07, Tween.TRANS_QUAD, Tween.EASE_OUT))
	button_up.connect(func() -> void: _squeeze(1.0, 0.22, Tween.TRANS_BACK, Tween.EASE_OUT))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _draw() -> void:
	var hovered: bool = is_hovered() or has_focus()
	if home_link:
		_draw_home_link(hovered)
	elif pause_action:
		_draw_pause_action(hovered)
	elif level_tile:
		_draw_level_tile(hovered)
	elif shop_card:
		_draw_shop_card(hovered)
	elif caption.is_empty():
		var lift: float = -3.0 if hovered else 0.0
		draw_texture_rect(ICON_PATCH, Rect2(Vector2(0, lift), size), false, cloth.lightened(0.13) if hovered else cloth)
		if not glyph.is_empty():
			_draw_icon(Vector2(size.x * 0.5, size.y * 0.48 + lift), minf(size.x, size.y) * 0.26)
	else:
		_draw_card(hovered)


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


# The card: a rounded felt patch with a stitched line inside its edge, the icon on a round patch at the left, a
# switch or an arrow at the right, and the caption with its line under it centred as one block between them. Each
# line shrinks until it fits its room, so a long word never runs into the stitching.
func _draw_card(hovered: bool) -> void:
	var lift: float = -3.0 if hovered else 0.0
	var body: Rect2 = Rect2(0, lift, size.x, size.y - CARD_DROP)
	var radius: float = minf(body.size.y * 0.26, 30.0)
	var tint: Color = cloth.lightened(0.08) if hovered else cloth
	_draw_rounded(Rect2(0, CARD_DROP, body.size.x, body.size.y), radius, CARD_SHADOW)
	_draw_rounded(body, radius, CARD_EDGE)
	_draw_rounded(body.grow(-2.5), radius - 2.5, tint)
	_draw_dashes(_rounded_outline(body.grow(-STITCH_INSET), maxf(radius - STITCH_INSET, 4.0)), Color("896b57", 0.7))
	var pad: float = clampf(body.size.y * 0.15, 12.0, 26.0)
	var left: float = STITCH_INSET + pad
	var right: float = body.size.x - STITCH_INSET - pad
	var middle: float = body.get_center().y
	# A card about as tall as it is wide stacks its icon over its word, as Home's tiles do.
	if not glyph.is_empty() and body.size.x < body.size.y * 1.6:
		var room_wide: float = body.size.x - (STITCH_INSET + 10.0) * 2.0
		var word: int = stacked_word_size()
		var word_height: float = word * CAP_HEIGHT
		var disc: float = minf(room_wide, body.size.y - (STITCH_INSET + pad) * 2.0 - word_height - pad * 0.8)
		var stack_top: float = middle - (disc + pad * 0.8 + word_height) * 0.5
		var disc_centre: Vector2 = Vector2(body.get_center().x, stack_top + disc * 0.5)
		draw_circle(disc_centre, disc * 0.5, tint.darkened(0.12), true, -1.0, true)
		_draw_dashes(_circle_outline(disc_centre, disc * 0.5 - 6.0), Color("896b57", 0.55))
		_draw_icon(disc_centre, disc * 0.29)
		draw_string(MENU_FONT, Vector2(STITCH_INSET + 10.0, stack_top + disc + pad * 0.8 + word_height), caption, HORIZONTAL_ALIGNMENT_CENTER, room_wide, word, ink)
		return
	if not glyph.is_empty():
		var patch: float = minf(body.size.y - (STITCH_INSET + pad * 0.7) * 2.0, 120.0)
		var centre: Vector2 = Vector2(left + patch * 0.5, middle)
		draw_circle(centre, patch * 0.5, tint.darkened(0.12), true, -1.0, true)
		_draw_dashes(_circle_outline(centre, patch * 0.5 - 6.0), Color("896b57", 0.55))
		_draw_icon(centre, patch * 0.29)
		left += patch + pad
	if switch_on >= 0:
		_draw_switch(Vector2(right - SWITCH_SIZE.x * 0.5, middle), switch_on == 1)
		right -= SWITCH_SIZE.x + pad
	elif arrow:
		var tip: Vector2 = Vector2(right - 6.0, middle)
		draw_polyline(PackedVector2Array([tip + Vector2(-13, -16), tip, tip + Vector2(-13, 16)]), Color(ink, 0.55), 5.0, true)
		right -= 34.0
	var room: float = right - left
	var caption_font: int = _fit(MENU_FONT, caption, caption_size if caption_size > 0 else int(body.size.y * 0.4), room)
	var small_font: int = _fit(BODY_FONT, subcaption, int(clampf(body.size.y * 0.22, 22.0, 32.0)), room)
	var caption_height: float = caption_font * CAP_HEIGHT
	var gap: float = caption_font * 0.36
	var block: float = caption_height + (gap + small_font * CAP_HEIGHT if not subcaption.is_empty() else 0.0)
	var top: float = middle - block * 0.5
	var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER if glyph.is_empty() and switch_on < 0 and not arrow else HORIZONTAL_ALIGNMENT_LEFT
	draw_string(MENU_FONT, Vector2(left, top + caption_height), caption, align, room, caption_font, ink)
	if not subcaption.is_empty():
		draw_string(BODY_FONT, Vector2(left, top + block), subcaption, align, room, small_font, Color(ink, 0.8))


# The size a stacked card's word is drawn at, so a row of them can share the smallest.
func stacked_word_size() -> int:
	var largest: int = caption_size if caption_size > 0 else int((size.y - CARD_DROP) * 0.18)
	return _fit(MENU_FONT, caption, largest, size.x - (STITCH_INSET + 10.0) * 2.0)


# The largest size, up to `largest`, at which `text` fits `room` wide.
func _fit(font: Font, text: String, largest: int, room: float) -> int:
	var font_size: int = largest
	while font_size > 16 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > room:
		font_size -= 1
	return font_size


func _draw_switch(centre: Vector2, on: bool) -> void:
	var track: Rect2 = Rect2(centre - SWITCH_SIZE * 0.5, SWITCH_SIZE)
	_draw_rounded(track, SWITCH_SIZE.y * 0.5, CARD_EDGE)
	_draw_rounded(track.grow(-2.5), SWITCH_SIZE.y * 0.5 - 2.5, SWITCH_ON if on else SWITCH_OFF)
	var knob_radius: float = SWITCH_SIZE.y * 0.5 - 7.0
	var knob: Vector2 = Vector2(track.end.x - SWITCH_SIZE.y * 0.5 if on else track.position.x + SWITCH_SIZE.y * 0.5, centre.y)
	draw_circle(knob + Vector2(0, 2), knob_radius, Color(CARD_SHADOW, 0.3), true, -1.0, true)
	draw_circle(knob, knob_radius, Color("f7edda"), true, -1.0, true)
	_draw_dashes(_circle_outline(knob, knob_radius - 4.0), Color("896b57", 0.5))


func _draw_rounded(rect: Rect2, radius: float, color: Color) -> void:
	draw_colored_polygon(_rounded_outline(rect, radius), color)


# The outline of a rounded rectangle, clockwise from the top right corner, closed.
func _rounded_outline(rect: Rect2, radius: float) -> PackedVector2Array:
	var corner: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var centres: Array[Vector2] = [
		Vector2(rect.end.x - corner, rect.position.y + corner),
		Vector2(rect.end.x - corner, rect.end.y - corner),
		Vector2(rect.position.x + corner, rect.end.y - corner),
		Vector2(rect.position.x + corner, rect.position.y + corner),
	]
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(4):
		for step: int in range(9):
			var angle: float = -PI * 0.5 + float(index) * PI * 0.5 + float(step) / 8.0 * PI * 0.5
			points.append(centres[index] + Vector2.from_angle(angle) * corner)
	return points


func _circle_outline(centre: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in range(33):
		points.append(centre + Vector2.from_angle(float(step) / 32.0 * TAU) * radius)
	return points


# Running stitches along a path: a dash, a gap, and on round the corners without starting over.
func _draw_dashes(points: PackedVector2Array, color: Color) -> void:
	var path: PackedVector2Array = points.duplicate()
	if path.size() > 1 and path[0] != path[path.size() - 1]:
		path.append(path[0])
	var walked: float = 0.0
	for index: int in range(path.size() - 1):
		var from: Vector2 = path[index]
		var to: Vector2 = path[index + 1]
		var length: float = from.distance_to(to)
		var at: float = 0.0
		while at < length:
			var into: float = fmod(walked + at, STITCH_PERIOD)
			if into < STITCH_DASH:
				var until: float = minf(length, at + STITCH_DASH - into)
				draw_line(from.lerp(to, at / length), from.lerp(to, until / length), color, 2.0, true)
				at = until
			else:
				at += STITCH_PERIOD - into
		walked += length


func _draw_pause_action(hovered: bool) -> void:
	var lift: float = -5.0 if hovered else 0.0
	var patch_size: float = minf(size.x - 20.0, size.y * 0.72)
	var patch_position: Vector2 = Vector2((size.x - patch_size) * 0.5, 0.0 + lift)
	var tint: Color = cloth.lightened(0.12) if hovered else cloth
	draw_texture_rect(ICON_PATCH, Rect2(patch_position, Vector2.ONE * patch_size), false, tint)
	_draw_icon(patch_position + Vector2.ONE * patch_size * 0.5, patch_size * 0.23)
	var font_size: int = caption_size if caption_size > 0 else (32 if caption.length() > 8 else (46 if size.x > 260.0 else 42))
	draw_string(MENU_FONT, Vector2(0, size.y - 8.0 + lift), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, ink)


func _process(delta: float) -> void:
	if level_tile and next_up and is_visible_in_tree():
		age += delta
		queue_redraw()


func _draw_level_tile(hovered: bool) -> void:
	var breath: float = sin(age * 2.6) * 3.0 if next_up else 0.0
	var lift: float = (-4.0 if hovered and not locked else 0.0) + breath
	var tint: Color = cloth.lightened(0.1) if hovered and not locked else cloth
	if locked:
		tint = tint.darkened(0.25)
	var faded: Color = Color(ink, 0.45) if locked else ink
	var patch: Rect2 = Rect2(Vector2(12, lift), Vector2(size.x - 24.0, size.y - 52.0))
	if next_up:
		# A terracotta patch behind the room to play next, showing round its edge.
		draw_texture_rect(ICON_PATCH, patch.grow(10.0), false, Color("e0a278"))
	draw_texture_rect(ICON_PATCH, patch, false, tint)
	draw_string(MENU_FONT, Vector2(0, patch.size.y * 0.5 + 22.0 + lift), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 88, faded)
	if locked:
		_draw_lock(Vector2(size.x * 0.5, patch.size.y * 0.78 + lift))
	elif stars >= 0:
		for index: int in range(3):
			StitchfallStarRow.draw_star(self, Vector2(size.x * 0.5 + float(index - 1) * 46.0, patch.size.y * 0.78 + lift), 19.0, index < stars, StitchfallStarRow.GOLD)
	draw_string(BODY_FONT, Vector2(0, size.y - 8.0 + breath), "Locked" if locked else subcaption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 32, faded)
	if next_up:
		var tag: Rect2 = Rect2(size.x * 0.5 - 52.0, lift - 14.0, 104.0, 36.0)
		draw_rect(tag, Color("a85648"))
		draw_string(FONT, Vector2(tag.position.x, tag.position.y + 28.0), "NEXT", HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, 26, Color("f7edda"))


# A small sewn padlock for a shut room.
func _draw_lock(center: Vector2) -> void:
	var body: Rect2 = Rect2(center + Vector2(-17, -6), Vector2(34, 26))
	draw_arc(center + Vector2(0, -6), 11.0, PI, TAU, 16, Color(ink, 0.55), 4.0, true)
	draw_rect(body, Color(ink, 0.55))
	draw_circle(center + Vector2(0, 6), 3.5, Color(cloth, 0.9))


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
