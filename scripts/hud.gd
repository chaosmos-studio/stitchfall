class_name PalewheelHud
extends CanvasLayer

signal begin_pressed
signal pause_pressed
signal restart_pressed
signal home_pressed
signal level_selected(index: int)
signal sound_toggled(enabled: bool)

const INK: Color = Color("493a37")
const PAPER: Color = Color("f7edda")
const ACCENT: Color = Color("a85648")
const FONT: FontFile = preload("res://assets/fonts/BricolageGrotesque.ttf")
const DANCE_SHEET_1: Texture2D = preload("res://assets/art/seam_runner_dance_front_1.png")
const DANCE_SHEET_2: Texture2D = preload("res://assets/art/seam_runner_dance_front_2.png")
const DANCE_SHEET_3: Texture2D = preload("res://assets/art/seam_runner_dance_front_3.png")
const DANCE_SHEET_4: Texture2D = preload("res://assets/art/seam_runner_dance_front_4.png")
const BORDER_SCRIPT: GDScript = preload("res://scripts/stitch_border.gd")
const CLEANUP_SHADER: Shader = preload("res://shaders/runner_cleanup.gdshader")

var root: Control
var meter: ButtonMeter
var pause_button: StitchedButton
var hint_back: Panel
var hint_title: Label
var hint_body: Label
var panel: ColorRect
var fabric: TextureRect
var home_page: Control
var level_page: Control
var level_buttons: Array[StitchedButton] = []
var level_page_index: int = 0
var level_previous: StitchedButton
var level_next: StitchedButton
var help_page: Control
var about_page: Control
var pause_page: Control
var hero: AnimatedSprite2D
var pause_heading: Label
var pause_body: Label
var resume_button: StitchedButton
var restart_button: StitchedButton
var sound_buttons: Array[StitchedButton] = []
var regular_font: FontVariation
var heavy_font: FontVariation
var intro_tween: Tween
var current_biome: int = -1
var screen: String = "home"
var audio_enabled: bool = true
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
	pause_button = _tag(root, Rect2(0, 18, 112, 108), "", "pause", ACCENT)
	pause_button.tooltip_text = "Pause"
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	hint_back = _panel(root, Rect2(470, 112, 980, 126), Color("f5e8d1", 0.94))
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_title = _label(hint_back, Vector2(32, 6), Vector2(916, 52), 34, INK, true)
	hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body = _label(hint_back, Vector2(32, 57), Vector2(916, 56), 26, INK)
	hint_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_pages()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _layout() -> void:
	var mobile_scale: float = 1.2 if DisplayServer.is_touchscreen_available() else 1.0
	meter.scale = Vector2.ONE * mobile_scale
	pause_button.scale = Vector2.ONE * mobile_scale
	sound_buttons[0].scale = Vector2.ONE * mobile_scale
	pause_button.position.x = root.size.x - pause_button.size.x * mobile_scale - 28.0
	hint_back.position.x = (root.size.x - hint_back.size.x) * 0.5
	hero.position.x = root.size.x * 0.735
	level_page.position.x = (root.size.x - 1920.0) * 0.5
	help_page.position.x = (root.size.x - 1920.0) * 0.5
	about_page.position.x = (root.size.x - 1920.0) * 0.5
	pause_page.position.x = (root.size.x - 1920.0) * 0.5
	var sound_inset: float = 28.0
	if OS.has_feature("web"):
		var browser_width: float = float(JavaScriptBridge.eval("window.innerWidth"))
		if browser_width > 0.0:
			var fullscreen_width: float = clampf(browser_width * 0.056, 48.0, 72.0)
			sound_inset = (16.0 + fullscreen_width + 12.0) * root.size.x / browser_width
	sound_buttons[0].position.x = root.size.x - sound_buttons[0].size.x * mobile_scale - sound_inset


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


func _tag(parent: Control, rect: Rect2, caption: String, glyph: String, color: Color) -> StitchedButton:
	var value: StitchedButton = StitchedButton.new()
	value.position = rect.position
	value.size = rect.size
	value.caption = caption
	value.glyph = glyph
	value.cloth = color
	value.thread = Color("805d50")
	value.tooltip_text = glyph.capitalize() if caption.is_empty() else ""
	parent.add_child(value)
	return value


func _page() -> Control:
	var value: Control = Control.new()
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(value)
	value.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return value


func _build_pages() -> void:
	panel = ColorRect.new()
	panel.color = Color("f5ead5", 0.89)
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fabric = TextureRect.new()
	fabric.texture = preload("res://assets/art/linen_landscape.png")
	fabric.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fabric.stretch_mode = TextureRect.STRETCH_SCALE
	fabric.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fabric)
	fabric.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_home()
	_build_levels()
	_build_help()
	_build_about()
	_build_pause()
	show_home()


func _build_home() -> void:
	home_page = _page()
	var card: Panel = _panel(home_page, Rect2(75, 82, 1020, 920), Color("f7edda", 0.93))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var eyebrow: Label = _label(home_page, Vector2(136, 120), Vector2(850, 55), 31, ACCENT, true)
	eyebrow.text = "A STITCHED SHIFT ADVENTURE"
	var title: Label = _label(home_page, Vector2(128, 185), Vector2(870, 158), 105, INK, true)
	title.text = "PALEWHEEL"
	var line: Label = _label(home_page, Vector2(138, 340), Vector2(840, 84), 39, INK)
	line.text = "Find the buttons. Turn the pull.\nOpen the seam."
	_tag(home_page, Rect2(133, 475, 805, 117), "PLAY", "play", Color("e0a278")).pressed.connect(func() -> void: begin_pressed.emit())
	_tag(home_page, Rect2(133, 605, 805, 106), "LEVELS", "levels", Color("dbe5d1")).pressed.connect(show_levels)
	_tag(home_page, Rect2(133, 723, 805, 106), "HOW TO PLAY", "help", Color("e8d8bd")).pressed.connect(show_help)
	_tag(home_page, Rect2(133, 841, 805, 106), "ABOUT", "seam", Color("e4d0b1")).pressed.connect(show_about)
	var sound_button: StitchedButton = _tag(home_page, Rect2(1737, 35, 116, 104), "", "sound", Color("f1e2c8"))
	sound_buttons.append(sound_button)
	sound_button.pressed.connect(_toggle_sound)
	hero = AnimatedSprite2D.new()
	hero.sprite_frames = _dance_frames()
	hero.scale = Vector2.ONE * 2.0
	hero.position = Vector2(1410, 574)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CLEANUP_SHADER
	hero.material = material
	home_page.add_child(hero)
	hero.play("dance")


func _dance_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("dance")
	frames.set_animation_loop("dance", true)
	frames.set_animation_speed("dance", 24.0)
	var sheets: Array[Texture2D] = [DANCE_SHEET_1, DANCE_SHEET_2, DANCE_SHEET_3, DANCE_SHEET_4]
	for sheet: Texture2D in sheets:
		var cell: Vector2 = Vector2(float(sheet.get_width()) / 4.0, float(sheet.get_height()) / 4.0)
		for index: int in range(16):
			var frame: AtlasTexture = AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(Vector2(float(index % 4) * cell.x, float(index / 4) * cell.y), cell)
			frames.add_frame("dance", frame)
	return frames


func _build_levels() -> void:
	level_page = _page()
	var card: Panel = _panel(level_page, Rect2(69, 68, 1782, 944), Color("f7edda", 0.95))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading: Label = _label(level_page, Vector2(150, 99), Vector2(1230, 105), 77, INK, true)
	heading.text = "CHOOSE A SEAM"
	level_previous = _tag(level_page, Rect2(1460, 102, 100, 101), "", "back", Color("e5d5bc"))
	level_previous.pressed.connect(func() -> void: _set_level_page(level_page_index - 1))
	level_next = _tag(level_page, Rect2(1580, 102, 100, 101), "", "next", Color("e5d5bc"))
	level_next.pressed.connect(func() -> void: _set_level_page(level_page_index + 1))
	_tag(level_page, Rect2(1700, 102, 100, 101), "", "home", Color("e5d5bc")).pressed.connect(show_home)
	for slot: int in range(8):
		var column: int = slot % 2
		var row: int = slot / 2
		var button: StitchedButton = _tag(level_page, Rect2(145 + column * 835, 230 + row * 182, 785, 162), "", "seam", Color("f1e1c8"))
		button.pressed.connect(_select_visible_level.bind(slot))
		level_buttons.append(button)
	_set_level_page(0)


func _set_level_page(value: int) -> void:
	level_page_index = clampi(value, 0, floori(float(PalewheelLevels.count() - 1) / 8.0))
	level_previous.visible = level_page_index > 0
	level_next.visible = (level_page_index + 1) * 8 < PalewheelLevels.count()
	for slot: int in range(level_buttons.size()):
		var index: int = level_page_index * 8 + slot
		var button: StitchedButton = level_buttons[slot]
		button.visible = index < PalewheelLevels.count()
		if not button.visible:
			continue
		var data: Dictionary = PalewheelLevels.get_level(index)
		var biome: int = data["backdrop"]
		var palette: Array[Color] = _biome_palette(biome)
		button.caption = "%02d" % [index + 1]
		button.subcaption = data["name"]
		button.glyph = _biome_glyph(biome)
		button.cloth = palette[0]
		button.thread = palette[1]
		button.tooltip_text = ""
		button.queue_redraw()


func _build_help() -> void:
	help_page = _page()
	var card: Panel = _panel(help_page, Rect2(170, 95, 1580, 875), Color("f7edda", 0.96))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading: Label = _label(help_page, Vector2(260, 142), Vector2(1200, 104), 67, INK, true)
	heading.text = "HOW TO PLAY"
	_tag(help_page, Rect2(1560, 136, 112, 105), "", "back", Color("e5d5bc")).pressed.connect(show_home)
	var instructions: Array[PackedStringArray] = [
		PackedStringArray(["MOVE", "A / D  or  slide left / right", "move"]),
		PackedStringArray(["JUMP", "W / Space  or  swipe up", "jump"]),
		PackedStringArray(["CROUCH", "S  or  swipe down", "crouch"]),
		PackedStringArray(["SHIFT", "Shift / click  or  tap", "shift"]),
	]
	for index: int in range(instructions.size()):
		var column: int = index % 2
		var row: int = index / 2
		var instruction: PackedStringArray = instructions[index]
		var diagram: StitchedButton = _tag(help_page, Rect2(255 + column * 715, 310 + row * 245, 660, 200), instruction[0], instruction[2], Color("ecdfc7") if index != 3 else Color("e2b18f"))
		diagram.subcaption = instruction[1]
		diagram.focus_mode = Control.FOCUS_NONE
		diagram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var footer: Label = _label(help_page, Vector2(265, 839), Vector2(1300, 70), 31, ACCENT, true)
	footer.text = "On the ceiling, swipe down to jump. Collect the buttons to open the seam."


func _build_about() -> void:
	about_page = _page()
	var card: Panel = _panel(about_page, Rect2(210, 95, 1500, 875), Color("f7edda", 0.96))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading: Label = _label(about_page, Vector2(300, 145), Vector2(1110, 110), 78, INK, true)
	heading.text = "A WORLD IN THREAD"
	_tag(about_page, Rect2(1510, 138, 112, 105), "", "back", Color("e5d5bc")).pressed.connect(show_home)
	var note: Label = _label(about_page, Vector2(320, 310), Vector2(1260, 210), 48, INK)
	note.text = "A few brave steps can turn a whole world upside down."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var studio: Label = _label(about_page, Vector2(320, 565), Vector2(1250, 190), 38, INK)
	studio.text = "Made by Chaosmos, a small studio making calm, clever games, one at a time."
	studio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var signoff: Label = _label(about_page, Vector2(320, 805), Vector2(1100, 65), 34, ACCENT, true)
	signoff.text = "Thanks for spending a little time here."


func _build_pause() -> void:
	pause_page = _page()
	var card: Panel = _panel(pause_page, Rect2(485, 125, 950, 832), Color("f7edda", 0.96))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_heading = _label(pause_page, Vector2(550, 178), Vector2(820, 113), 74, INK, true)
	pause_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_body = _label(pause_page, Vector2(560, 300), Vector2(800, 100), 31, INK)
	pause_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_button = _tag(pause_page, Rect2(615, 430, 690, 122), "RESUME", "play", Color("e0a278"))
	resume_button.pressed.connect(func() -> void: begin_pressed.emit())
	restart_button = _tag(pause_page, Rect2(615, 574, 690, 111), "RESTART", "restart", Color("dbe5d1"))
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	_tag(pause_page, Rect2(615, 708, 690, 110), "HOME", "home", Color("e8d8bd")).pressed.connect(func() -> void: home_pressed.emit())
	var sound_button: StitchedButton = _tag(pause_page, Rect2(1274, 169, 106, 99), "", "sound", Color("f1e2c8"))
	sound_buttons.append(sound_button)
	sound_button.pressed.connect(_toggle_sound)


func _biome_palette(biome: int) -> Array[Color]:
	match biome:
		4: return [Color("d9e8e4"), Color("648b93")]
		5: return [Color("f1d7a8"), Color("ae754b")]
		6: return [Color("dfe8c8"), Color("6f8962")]
		7: return [Color("d8d3e3"), Color("79779d")]
		8: return [Color("dce8e2"), Color("6d9aa2")]
		9: return [Color("e9e9ec"), Color("91a5ba")]
	return [Color("f1e1c8"), Color("a47660")]


func _biome_glyph(biome: int) -> String:
	match biome:
		4: return "water"
		5: return "dunes"
		6: return "forest"
		7: return "night"
		8: return "rain"
		9: return "frost"
	return "seam"


func _select_visible_level(slot: int) -> void:
	level_selected.emit(level_page_index * 8 + slot)


func _toggle_sound() -> void:
	audio_enabled = not audio_enabled
	for button: StitchedButton in sound_buttons:
		button.glyph = "sound" if audio_enabled else "mute"
		button.tooltip_text = "Mute" if audio_enabled else "Unmute"
		button.queue_redraw()
	sound_toggled.emit(audio_enabled)


func _show_screen(name: String) -> void:
	screen = name
	panel.visible = true
	fabric.visible = name in ["home", "levels", "help", "about"]
	home_page.visible = name == "home"
	level_page.visible = name == "levels"
	help_page.visible = name == "help"
	about_page.visible = name == "about"
	pause_page.visible = name in ["pause", "finish"]
	meter.visible = false
	pause_button.visible = false
	hint_back.visible = false
	if name == "home":
		hero.play("dance")
	else:
		hero.stop()
	_set_browser_menu(name == "home")


func show_home() -> void:
	_show_screen("home")


func show_levels() -> void:
	_set_level_page(0)
	_show_screen("levels")


func show_help() -> void:
	_show_screen("help")


func show_about() -> void:
	_show_screen("about")


func show_pause() -> void:
	pause_heading.text = "PAUSED"
	pause_body.text = "The thread can wait."
	resume_button.caption = "RESUME"
	resume_button.queue_redraw()
	restart_button.visible = true
	_show_screen("pause")
	resume_button.grab_focus()


func show_finish(time_text: String, shift_count: int, hit_count: int) -> void:
	pause_heading.text = "THE SEAM HOLDS"
	pause_body.text = "Time %s     Shifts %d     Hits %d" % [time_text, shift_count, hit_count]
	resume_button.caption = "PLAY AGAIN"
	resume_button.queue_redraw()
	restart_button.visible = false
	_show_screen("finish")
	resume_button.grab_focus()


func hide_panel() -> void:
	screen = "game"
	panel.visible = false
	meter.visible = true
	pause_button.visible = true
	hero.stop()
	_set_browser_menu(false)


func _set_browser_menu(visible: bool) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.palewheelMenuState?.(%s)" % ["true" if visible else "false"])


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
	intro_tween.tween_interval(2.4)
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
	pause_button.cloth = palette[0]
	pause_button.thread = palette[1]
	pause_button.queue_redraw()
	hint_back.add_theme_stylebox_override("panel", _style(palette[0], palette[1], 2))
