class_name StitchfallItemTile
extends Button

# One piece in the wardrobe: the painted felt patch with the piece on it as big as the patch's stitching allows, and
# its name under it. Instead of words, a worn piece gets a tick, a piece that stars open shows the stars it needs,
# and a Wardrobe pack piece shows a padlock. A fabric shows its whole scene, and an unravel plays its burst over and
# over, so a tile shows the piece as it looks in a room.

const PATCH: Texture2D = preload("res://assets/art/linen_icon_patch.png")
const NAME_FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const INK: Color = Color("493a37")
const STITCH: Color = Color("896b57")
const WORN: Color = Color("6f9a64")
const LOCK_PILL: Color = Color("a85648")
const BADGE_INK: Color = Color("fff6e6")
# The patch's painted edge and stitching, as a share of its side: a piece stays inside it.
const PATCH_BORDER: float = 0.15
# The name's size, a share of the tile's width, and its smallest and largest.
const NAME_SHARE: float = 0.125
const NAME_SIZES: Vector2i = Vector2i(30, 42)
# A piece that stars open shows this much of itself until then, so it reads but is plainly not yours yet. A
# Wardrobe pack piece shows in full colour, since the padlock already says it is locked and it is there to tempt.
const LOCKED_ALPHA: float = 0.6
# An unravel's burst on its tile: how long one takes in seconds (slower than in a room, so it reads), the pause
# before the next, how much of the patch it spreads over, how much bigger its bits are than a room's, and how far
# through it the bits start to fade. A locked one stands still at STILL of the way through.
const BURST_TIME: float = 1.5
const BURST_REST: float = 0.3
const BURST_SPREAD: float = 0.9
const BURST_GROW: float = 2.2
const BURST_HOLD: float = 0.55
const STILL: float = 0.6

var item: Dictionary = {}
var open: bool = true
var worn: bool = false
var picture: Texture2D
var bits: Array[Dictionary] = []
var clock: float = 0.0


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_process(false)


func show_item(piece: Dictionary, is_open: bool, is_worn: bool) -> void:
	item = piece
	open = is_open
	worn = is_worn
	picture = null
	bits = []
	match str(item["kind"]):
		"runner":
			picture = load(StitchfallLooks.runner_art(item["id"])["poses"][0]) as Texture2D
		"fabric":
			picture = load(item["art"]) as Texture2D
		"unravel":
			bits = StitchfallUnravel.make_bits(item["colours"])
	set_process(item["kind"] == "unravel" and open)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	clock += delta
	queue_redraw()


func name_size() -> int:
	var largest: int = clampi(int(size.x * NAME_SHARE), NAME_SIZES.x, NAME_SIZES.y)
	var font_size: int = largest
	while font_size > NAME_SIZES.x and NAME_FONT.get_string_size(str(item.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x * 0.94:
		font_size -= 1
	return font_size


func _draw() -> void:
	if item.is_empty():
		return
	var hovered: bool = is_hovered() or has_focus()
	var lift: float = -4.0 if hovered else 0.0
	var font_size: int = name_size()
	var side: float = minf(size.x, size.y - font_size * 1.35)
	var patch: Rect2 = Rect2(Vector2((size.x - side) * 0.5, lift), Vector2(side, side))
	var tint: Color = Color("f1e1c8") if open else Color("e2d5bf")
	draw_texture_rect(PATCH, patch, false, tint.lightened(0.08) if hovered else tint)
	var inner: Rect2 = patch.grow(-side * PATCH_BORDER)
	var alpha: float = 1.0 if open or bool(item["paid"]) else LOCKED_ALPHA
	match str(item["kind"]):
		"runner":
			var tall: float = inner.size.y * 1.08
			var wide: float = tall * float(picture.get_width()) / float(picture.get_height())
			draw_texture_rect(picture, Rect2(inner.get_center() - Vector2(wide, tall) * 0.5, Vector2(wide, tall)), false, Color(1, 1, 1, alpha))
		"fabric":
			_draw_fabric(inner, alpha)
		"trail":
			if item["colours"].is_empty():
				_draw_none(inner)
			else:
				StitchfallLooks.draw_trail_sample(self, Vector2(inner.position.x + inner.size.x * 0.08, inner.get_center().y), Vector2(inner.end.x - inner.size.x * 0.08, inner.get_center().y), item, inner.size.y * 0.14, maxf(6.0, inner.size.y * 0.045), alpha)
		"unravel":
			# The farthest bit flies 149 px in a room: the burst is scaled so it lands inside the stitching.
			var reach: float = inner.size.x * 0.5 * BURST_SPREAD / 149.0
			var phase: float = minf(fmod(clock, BURST_TIME + BURST_REST) / BURST_TIME, 1.0) if open else STILL
			StitchfallUnravel.draw_burst(self, inner.get_center(), item["shape"], bits, phase, reach, BURST_GROW, alpha, BURST_HOLD, true)
		"button":
			var tone: Color = item["colour"]
			StitchfallLooks.draw_button(self, inner.get_center(), inner.size.x * 0.3, Color(tone, alpha))
	if worn:
		_draw_worn(patch)
	elif not open:
		_draw_lock(patch)
	draw_string(NAME_FONT, Vector2(0, patch.end.y + font_size * 1.05), item["name"], HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, INK)


# The fabric's whole scene, cropped to the patch's shape, sewn on with a running stitch.
func _draw_fabric(inner: Rect2, alpha: float) -> void:
	var art: Vector2 = picture.get_size()
	var crop: Vector2 = art
	if art.x / art.y > inner.size.x / inner.size.y:
		crop.x = art.y * inner.size.x / inner.size.y
	else:
		crop.y = art.x * inner.size.y / inner.size.x
	draw_texture_rect_region(picture, inner, Rect2((art - crop) * Vector2(0.5, 0.6), crop), Color(1, 1, 1, alpha))
	var edge: Rect2 = inner.grow(-6.0)
	var corners: PackedVector2Array = PackedVector2Array([edge.position, Vector2(edge.end.x, edge.position.y), edge.end, Vector2(edge.position.x, edge.end.y), edge.position])
	for index: int in range(4):
		var from: Vector2 = corners[index]
		var to: Vector2 = corners[index + 1]
		var steps: int = int(from.distance_to(to) / 16.0)
		for step: int in range(steps):
			if step % 2 == 0:
				draw_line(from.lerp(to, float(step) / steps), from.lerp(to, float(step + 1) / steps), Color(BADGE_INK, 0.85 * alpha), 3.0, true)


# No trail: an empty spool's worth of nothing, a soft crossed circle.
func _draw_none(inner: Rect2) -> void:
	var centre: Vector2 = inner.get_center()
	var radius: float = inner.size.x * 0.24
	draw_arc(centre, radius, 0.0, TAU, 48, Color(INK, 0.35), 6.0, true)
	draw_line(centre + Vector2(-radius, radius) * 0.7, centre + Vector2(radius, -radius) * 0.7, Color(INK, 0.35), 6.0, true)


# Worn: a stitched ring round the patch and a green tick in its corner.
func _draw_worn(patch: Rect2) -> void:
	var ring: Rect2 = patch.grow(-patch.size.x * 0.035)
	draw_rect(ring, Color(WORN, 0.9), false, 6.0)
	var radius: float = patch.size.x * 0.12
	var centre: Vector2 = Vector2(patch.end.x - radius * 0.75, patch.position.y + radius * 0.75)
	draw_circle(centre, radius + 3.0, Color(INK, 0.25), true, -1.0, true)
	draw_circle(centre, radius, WORN, true, -1.0, true)
	var tick: PackedVector2Array = PackedVector2Array([centre + Vector2(-0.45, 0.02) * radius, centre + Vector2(-0.12, 0.36) * radius, centre + Vector2(0.48, -0.32) * radius])
	draw_polyline(tick, BADGE_INK, maxf(4.0, radius * 0.2), true)


# Locked: a pill at the patch's foot with a padlock, and the stars it needs when stars open it.
func _draw_lock(patch: Rect2) -> void:
	var height: float = patch.size.y * 0.21
	var stars: int = 0 if bool(item["paid"]) else int(item["stars"])
	var number: String = str(stars) if stars > 0 else ""
	var text_size: int = int(height * 0.66)
	var text_wide: float = NAME_FONT.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x if stars > 0 else 0.0
	var wide: float = height * 1.25 + (height * 0.95 + text_wide if stars > 0 else 0.0)
	var pill: Rect2 = Rect2(Vector2(patch.get_center().x - wide * 0.5, patch.end.y - height * 0.95), Vector2(wide, height))
	_draw_pill(Rect2(pill.position + Vector2(0, 3), pill.size), Color(INK, 0.25))
	_draw_pill(pill, LOCK_PILL)
	var lock: Vector2 = Vector2(pill.position.x + height * 0.62, pill.get_center().y + height * 0.06)
	var shackle: float = height * 0.2
	draw_arc(lock + Vector2(0, -height * 0.1), shackle, PI, TAU, 16, BADGE_INK, maxf(3.0, height * 0.08), true)
	draw_rect(Rect2(lock + Vector2(-height * 0.25, -height * 0.12), Vector2(height * 0.5, height * 0.36)), BADGE_INK)
	if stars > 0:
		var star: Vector2 = Vector2(pill.position.x + height * 1.25 + height * 0.38, pill.get_center().y)
		StitchfallStarRow.draw_star(self, star, height * 0.34, true, Color("f2c14e"))
		draw_string(NAME_FONT, Vector2(star.x + height * 0.48, pill.get_center().y + text_size * 0.36), number, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, BADGE_INK)


func _draw_pill(rect: Rect2, colour: Color) -> void:
	var radius: float = rect.size.y * 0.5
	draw_rect(Rect2(rect.position + Vector2(radius, 0), Vector2(rect.size.x - radius * 2.0, rect.size.y)), colour)
	draw_circle(rect.position + Vector2(radius, radius), radius, colour, true, -1.0, true)
	draw_circle(Vector2(rect.end.x - radius, rect.position.y + radius), radius, colour, true, -1.0, true)
