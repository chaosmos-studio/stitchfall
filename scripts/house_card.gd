class_name StitchfallHouseCard
extends CanvasLayer

# The house ads' stand-in for a video: a cloth card with a tiny playable taste of another of the studio's games,
# its name and icon, GET and CONTINUE. There is no timer, and the reward comes when the card closes, played or
# not, as the kit's quick game gives it.

signal closed

const LAYER: int = 6
const INK: Color = Color("493a37")
const ACCENT: Color = Color("a85648")
const CLOTH: Texture2D = preload("res://assets/art/pause_cloth.webp")
const NAME_FONT: FontFile = preload("res://assets/fonts/Darn-Display.ttf")
const BODY_FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const TAG_FONT: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")

var game: Dictionary = {}
var board: Control
var get_button: StitchedButton
var continue_button: StitchedButton
var _page: Control
var _ask: Label
var _closing: bool = false


func _ready() -> void:
	layer = LAYER
	var name_text: String = String(game["name"])
	var shade: ColorRect = ColorRect.new()
	shade.color = Color("3c342f", 0.6)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page = Control.new()
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.size = Vector2(1920, 1080)
	add_child(_page)
	var cloth: TextureRect = TextureRect.new()
	cloth.texture = CLOTH
	cloth.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cloth.stretch_mode = TextureRect.STRETCH_SCALE
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloth.position = Vector2(300, 100)
	cloth.size = Vector2(1320, 880)
	_page.add_child(cloth)
	board = StitchfallHouseGames.make(name_text)
	board.position = Vector2(400, 210)
	board.size = Vector2(StitchfallHouseGames.SIZE, StitchfallHouseGames.SIZE)
	_page.add_child(board)
	board.connect("solved", _on_solved)
	var icon: TextureRect = TextureRect.new()
	icon.texture = load(String(game["icon"])) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(1030, 220)
	icon.size = Vector2(118, 118)
	_page.add_child(icon)
	var title: Label = _label(Vector2(1170, 212), Vector2(380, 92), NAME_FONT, 70, INK)
	title.text = name_text.to_upper()
	var by: Label = _label(Vector2(1030, 346), Vector2(510, 44), TAG_FONT, 28, ACCENT)
	by.text = "Another game from %s" % StitchfallStudio.NAME
	_ask = _label(Vector2(1030, 398), Vector2(500, 140), BODY_FONT, 33, INK)
	_ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ask.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_ask.text = String(StitchfallHouseGames.style(name_text)["ask"])
	get_button = _action(Rect2(1020, 560, 240, 260), "GET", "link", Color("dbe5d1"))
	get_button.pressed.connect(_on_get)
	continue_button = _action(Rect2(1290, 545, 260, 280), "CONTINUE", "next", Color("e0a278"))
	continue_button.pressed.connect(close)
	get_viewport().size_changed.connect(_layout)
	_layout()
	StitchfallAnalytics.event(&"house_ad", {"game": name_text, "what": "play"})


func close() -> void:
	if _closing:
		return
	_closing = true
	closed.emit()
	queue_free()


func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var fit: float = minf(1.0, minf(view.x / 1920.0, view.y / 1080.0))
	_page.scale = Vector2.ONE * fit
	_page.position = (view - Vector2(1920, 1080) * fit) * 0.5


func _on_solved() -> void:
	_ask.text = "Nicely done. There's plenty more where that came from."
	StitchfallAnalytics.event(&"house_ad", {"game": String(game["name"]), "what": "solved"})


func _on_get() -> void:
	StitchfallAnalytics.event(&"house_ad", {"game": String(game["name"]), "what": "get"})
	OS.shell_open(StitchfallStudio.link(game))


func _label(at: Vector2, extent: Vector2, font: FontFile, font_size: int, colour: Color) -> Label:
	var value: Label = Label.new()
	value.position = at
	value.size = extent
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_override("font", font)
	value.add_theme_font_size_override("font_size", font_size)
	value.add_theme_color_override("font_color", colour)
	_page.add_child(value)
	return value


func _action(rect: Rect2, caption: String, glyph: String, colour: Color) -> StitchedButton:
	var value: StitchedButton = StitchedButton.new()
	value.position = rect.position
	value.size = rect.size
	value.caption = caption
	value.glyph = glyph
	value.cloth = colour
	value.pause_action = true
	_page.add_child(value)
	return value
