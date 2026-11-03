class_name PalewheelHud
extends CanvasLayer

signal begin_pressed
signal pause_pressed

const INK: Color = Color("493a37")
const PAPER: Color = Color("f7edda")
const ACCENT: Color = Color("a85648")
const FONT: FontFile = preload("res://assets/fonts/Baloo2.ttf")
const ACTION_SHEET: Texture2D = preload("res://assets/art/seam_runner_actions.png")
const BORDER_SCRIPT: GDScript = preload("res://scripts/stitch_border.gd")

var root: Control
var meter: ButtonMeter
var pause_button: Button
var hint_back: Panel
var hint_title: Label
var hint_body: Label
var panel: ColorRect
var panel_title: Label
var panel_body: Label
var guide_label: Label
var panel_button: Button
var portrait: TextureRect
var regular_font: FontVariation
var heavy_font: FontVariation
var intro_tween: Tween
var current_biome: int = -1
var borders: Array[StitchBorder] = []


func _ready() -> void:
	layer = 1
	regular_font = _font(600)
	heavy_font = _font(800)
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	meter = ButtonMeter.new()
	meter.position = Vector2(28, 19)
	meter.size = Vector2(205, 79)
	root.add_child(meter)
	pause_button = _button(root, Rect2(1134, 18, 116, 78), "PAUSE", ACCENT, PAPER, 23)
	if DisplayServer.is_touchscreen_available():
		pause_button.size = Vector2(148, 120)
		pause_button.add_theme_font_size_override("font_size", 28)
	pause_button.tooltip_text = "Pause"
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	hint_back = _panel(root, Rect2(280, 120, 720, 132), Color("f5e8d1", 0.96))
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_title = _label(hint_back, Vector2(28, 9), Vector2(664, 54), 36, INK, true)
	hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body = _label(hint_back, Vector2(28, 58), Vector2(664, 62), 27, INK)
	hint_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_panel()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _layout() -> void:
	var width: float = root.size.x
	pause_button.position.x = width - pause_button.size.x - 28.0
	hint_back.position.x = (width - hint_back.size.x) * 0.5
	portrait.position.x = width - portrait.size.x - 24.0


func _font(weight: int) -> FontVariation:
	var value: FontVariation = FontVariation.new()
	value.base_font = FONT
	value.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return value


func _style(color: Color, border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(16)
	style.shadow_color = Color("45372f", 0.18)
	style.shadow_size = 5
	style.shadow_offset = Vector2(4, 6)
	return style


func _sew(parent: Control) -> void:
	var border: StitchBorder = BORDER_SCRIPT.new() as StitchBorder
	parent.add_child(border)
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	borders.append(border)


func _panel(parent: Control, rect: Rect2, color: Color) -> Panel:
	var value: Panel = Panel.new()
	value.position = rect.position
	value.size = rect.size
	value.add_theme_stylebox_override("panel", _style(color, Color("947a65"), 2))
	parent.add_child(value)
	_sew(value)
	return value


func _label(parent: Control, pos: Vector2, extent: Vector2, size_px: int, color: Color, heavy: bool = false) -> Label:
	var value: Label = Label.new()
	value.position = pos
	value.size = extent
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_override("font", heavy_font if heavy else regular_font)
	value.add_theme_font_size_override("font_size", size_px)
	value.add_theme_color_override("font_color", color)
	parent.add_child(value)
	return value


func _button(parent: Control, rect: Rect2, caption: String, background: Color, foreground: Color, font_size: int) -> Button:
	var value: Button = Button.new()
	value.position = rect.position
	value.size = rect.size
	value.text = caption
	value.focus_mode = Control.FOCUS_ALL
	value.add_theme_font_override("font", heavy_font)
	value.add_theme_font_size_override("font_size", font_size)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		value.add_theme_color_override(state, foreground)
	value.add_theme_stylebox_override("normal", _style(background, INK, 3))
	value.add_theme_stylebox_override("hover", _style(background.lightened(0.1), INK, 3))
	value.add_theme_stylebox_override("pressed", _style(background.darkened(0.14), INK, 3))
	value.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, foreground, 2))
	parent.add_child(value)
	_sew(value)
	return value


func _build_panel() -> void:
	panel = ColorRect.new()
	panel.color = Color("f5ead5", 0.95)
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fabric: TextureRect = TextureRect.new()
	fabric.texture = preload("res://assets/art/linen_landscape.png")
	fabric.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fabric.stretch_mode = TextureRect.STRETCH_SCALE
	fabric.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fabric)
	fabric.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cloth_card: Panel = _panel(panel, Rect2(60, 62, 640, 582), Color("f5ead5", 0.96))
	cloth_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var edition: Label = _label(panel, Vector2(98, 92), Vector2(540, 40), 23, ACCENT, true)
	edition.text = "A HANDMADE SHIFT ADVENTURE"
	panel_title = _label(panel, Vector2(93, 149), Vector2(570, 108), 76, INK, true)
	panel_body = _label(panel, Vector2(101, 266), Vector2(552, 100), 29, INK)
	panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var guide_rule: ColorRect = ColorRect.new()
	guide_rule.position = Vector2(101, 384)
	guide_rule.size = Vector2(507, 2)
	guide_rule.color = Color("8e7769")
	panel.add_child(guide_rule)
	guide_label = _label(panel, Vector2(101, 404), Vector2(548, 100), 24, INK)
	guide_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	guide_label.text = "SLIDE  /  WALK      UP  /  JUMP\nDOWN  /  CROUCH      TAP  /  SHIFT" if DisplayServer.is_touchscreen_available() else "A / D  /  WALK      SPACE  /  JUMP\nS  /  CROUCH      SHIFT  /  TURN GRAVITY"
	panel_button = _button(panel, Rect2(101, 510, 340, 120), "BEGIN", ACCENT, PAPER, 32)
	panel_button.pressed.connect(func() -> void: begin_pressed.emit())
	portrait = TextureRect.new()
	var sprite_atlas: AtlasTexture = AtlasTexture.new()
	sprite_atlas.atlas = ACTION_SHEET
	sprite_atlas.region = Rect2(0, 0, ACTION_SHEET.get_width() / 4.0, ACTION_SHEET.get_height() / 3.0)
	portrait.texture = sprite_atlas
	portrait.position = Vector2(736, 78)
	portrait.size = Vector2(520, 540)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://shaders/runner_cleanup.gdshader")
	portrait.material = material
	panel.add_child(portrait)


func show_panel(title: String, body: String, button: String) -> void:
	panel.visible = true
	meter.visible = false
	pause_button.visible = false
	hint_back.visible = false
	panel_title.text = title
	panel_body.text = body
	guide_label.visible = title.begins_with("PALEWHEEL")
	panel_button.text = button
	panel_button.grab_focus()


func hide_panel() -> void:
	panel.visible = false
	meter.visible = true
	pause_button.visible = true


func set_room_intro(title: String, instruction: String) -> void:
	_show_intro(title, instruction)


func set_hint(instruction: String) -> void:
	_show_intro("", instruction)


func _show_intro(title: String, instruction: String) -> void:
	if intro_tween and intro_tween.is_running():
		intro_tween.kill()
	hint_title.text = title
	hint_body.text = instruction
	hint_title.visible = not title.is_empty()
	hint_body.position.y = 58 if not title.is_empty() else 35
	hint_back.visible = true
	hint_back.modulate.a = 1.0
	intro_tween = create_tween()
	intro_tween.tween_interval(3.3)
	intro_tween.tween_property(hint_back, "modulate:a", 0.0, 0.55)
	intro_tween.tween_callback(func() -> void: hint_back.visible = false)


func set_status(_index: int, _name: String, sparks: int, total_sparks: int, _cargo_needed: bool, _cargo_armed: bool, _time_text: String, _gravity: Vector2, biome: int) -> void:
	meter.collected = sparks
	meter.total = total_sparks
	meter.biome = biome
	if current_biome == biome:
		return
	current_biome = biome
	var palette: Array[Color] = meter._palette()
	for border: StitchBorder in borders:
		border.biome = biome
		border.thread_color = palette[1]
		border.queue_redraw()
	pause_button.add_theme_stylebox_override("normal", _style(palette[2], INK, 3))
	pause_button.add_theme_stylebox_override("hover", _style(palette[2].lightened(0.1), INK, 3))
	pause_button.add_theme_stylebox_override("pressed", _style(palette[2].darkened(0.14), INK, 3))
	hint_back.add_theme_stylebox_override("panel", _style(palette[0], palette[1], 2))
