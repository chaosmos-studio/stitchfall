class_name StitchfallHouseBanner
extends Control

# The house ads' banner, sewn like the rest of Stitchfall: a linen strip stitched in the other game's colour, its
# icon, name and line, and a GET patch. A tap opens its store page. It moves on to the next game every so often.

const PATCH: Texture2D = preload("res://assets/art/linen_icon_patch.png")
const NAME_FONT: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")
const LINE_FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const TAG_FONT: FontFile = preload("res://assets/fonts/Threadline-Woven.ttf")
const INK: Color = Color("493a37")
const CLOTH: Color = Color("f5e8d1")
const EDGE: Color = Color("947a65")
# Stitchfall has one look, light linen, so the other games come in their light colours.
const DARK: bool = false
# Seconds before the next game, while the banner stays on screen.
const TURN: float = 24.0
# How far a press may move and still be a tap.
const SLOP: float = 18.0

var game: Dictionary = {}
var _icon: Texture2D
var _thread: Color = EDGE
var _tag: String = ""
var _shown_at: float = 0.0
var _clock: float = 0.0
var _from: Vector2 = Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func show_game(next: Dictionary) -> void:
	game = next
	_icon = load(String(next["icon"])) as Texture2D
	var look: Dictionary = StitchfallHouseGames.style(String(next["name"]), DARK)
	_thread = look["accent"]
	_tag = look["tag"]
	_shown_at = _clock
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	if is_visible_in_tree() and _clock - _shown_at > TURN:
		show_game(StitchfallHouseAds.next_game())


func _gui_input(event: InputEvent) -> void:
	var press: InputEventMouseButton = event as InputEventMouseButton
	if press == null or press.button_index != MOUSE_BUTTON_LEFT:
		return
	if press.pressed:
		_from = press.position
	elif press.position.distance_to(_from) < SLOP and not game.is_empty():
		StitchfallAnalytics.event(&"house_ad", {"game": String(game["name"]), "what": "banner"})
		OS.shell_open(StitchfallStudio.link(game))
	accept_event()


func _draw() -> void:
	if game.is_empty():
		return
	var h: float = size.y
	var w: float = size.x
	var cloth: StyleBoxFlat = StyleBoxFlat.new()
	cloth.bg_color = CLOTH
	cloth.border_color = EDGE
	cloth.set_border_width_all(2)
	cloth.set_corner_radius_all(int(h * 0.16))
	draw_style_box(cloth, Rect2(Vector2.ZERO, size))
	var inset: float = h * 0.1
	var dash: float = maxf(4.0, h * 0.06)
	var thread: Color = Color(_thread, 0.85)
	var x: float = inset + dash
	while x < w - inset - dash:
		draw_line(Vector2(x, inset), Vector2(x + dash, inset), thread, 2.0, true)
		draw_line(Vector2(x, h - inset), Vector2(x + dash, h - inset), thread, 2.0, true)
		x += dash * 2.0
	var side: float = h * 0.62
	var at: Vector2 = Vector2(h * 0.24, (h - side) * 0.5)
	draw_texture_rect(_icon, Rect2(at, Vector2(side, side)), false)
	var text_x: float = at.x + side + h * 0.2
	var tag: Rect2 = Rect2(Vector2(w - h * 1.55, h * 0.18), Vector2(h * 1.3, h * 0.64))
	var room: float = tag.position.x - text_x - h * 0.15
	draw_string(NAME_FONT, Vector2(text_x, h * 0.47), String(game["name"]), HORIZONTAL_ALIGNMENT_LEFT, room, int(h * 0.34), INK)
	draw_string(LINE_FONT, Vector2(text_x, h * 0.78), _tag, HORIZONTAL_ALIGNMENT_LEFT, room, int(h * 0.22), Color(INK, 0.75))
	draw_texture_rect(PATCH, tag, false, _thread.lightened(0.35))
	draw_string(TAG_FONT, Vector2(tag.position.x, tag.get_center().y + h * 0.11), "GET", HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, int(h * 0.3), INK)
