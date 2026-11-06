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
const FONT_REGULAR: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const FONT_BOLD: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")
const FONT_DISPLAY: FontFile = preload("res://assets/fonts/Darn-Display.ttf")
const HOME_SCENE: Texture2D = preload("res://assets/art/home_woodland.webp")
const HOME_CLEAN_PLATE: Texture2D = preload("res://assets/art/home_clean_plate.png")
const HOME_REVEAL_MASK: Texture2D = preload("res://assets/art/home_reveal_mask.png")
const HOME_BOTANICALS: GDScript = preload("res://scripts/home_botanicals.gd")
const PAUSE_CLOTH: Texture2D = preload("res://assets/art/pause_cloth.webp")
const DANCE_POSES: Array[Texture2D] = [
	preload("res://assets/art/hero_pose_0.png"),
	preload("res://assets/art/hero_pose_1.png"),
	preload("res://assets/art/hero_pose_2.png"),
	preload("res://assets/art/hero_pose_3.png"),
]
const BORDER_SCRIPT: GDScript = preload("res://scripts/stitch_border.gd")
const CLEANUP_SHADER: Shader = preload("res://shaders/runner_cleanup.gdshader")
const HOME_REVEAL_SHADER: Shader = preload("res://shaders/home_reveal.gdshader")
const GESTURE_GUIDE: Script = preload("res://scripts/gesture_guide.gd")

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
var settings_page: Control
var pause_page: Control
var hero: AnimatedSprite2D
var pause_heading: Label
var pause_body: Label
var resume_button: StitchedButton
var restart_button: StitchedButton
var pause_home_button: StitchedButton
var sound_buttons: Array[StitchedButton] = []
var regular_font: FontFile
var heavy_font: FontFile
var intro_tween: Tween
var current_biome: int = -1
var screen: String = "home"
var guide_seen: bool = false
var audio_enabled: bool = true
var borders: Array[StitchBorder] = []


func _ready() -> void:
	layer = 1
	regular_font = FONT_REGULAR
	heavy_font = FONT_BOLD
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
	hint_back = _panel(root, Rect2(470, 102, 980, 154), Color("f5e8d1", 0.94))
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_title = _label(hint_back, Vector2(32, 6), Vector2(916, 52), 34, INK, true)
	hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body = _label(hint_back, Vector2(32, 57), Vector2(916, 80), 24, INK)
	hint_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_pages()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _layout() -> void:
	var mobile_scale: float = 1.2 if DisplayServer.is_touchscreen_available() else 1.0
	meter.scale = Vector2.ONE * mobile_scale
	pause_button.scale = Vector2.ONE * mobile_scale
	pause_button.position.x = root.size.x - pause_button.size.x * mobile_scale - 28.0
	hint_back.position.x = (root.size.x - hint_back.size.x) * 0.5
	hero.position.x = root.size.x * 0.735
	level_page.position.x = (root.size.x - 1920.0) * 0.5
	help_page.position.x = (root.size.x - 1920.0) * 0.5
	about_page.position.x = (root.size.x - 1920.0) * 0.5
	settings_page.position.x = (root.size.x - 1920.0) * 0.5
	pause_page.position.x = (root.size.x - 1920.0) * 0.5


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


func _cloth_page(parent: Control, rect: Rect2) -> void:
	var cloth: TextureRect = TextureRect.new()
	cloth.texture = PAUSE_CLOTH
	cloth.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cloth.stretch_mode = TextureRect.STRETCH_SCALE
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloth.position = rect.position
	cloth.size = rect.size
	parent.add_child(cloth)


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
	_build_settings()
	_build_pause()
	show_home()


func _build_home() -> void:
	home_page = _page()
	home_page.clip_contents = true
	var scene: TextureRect = TextureRect.new()
	scene.texture = HOME_SCENE
	scene.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reveal: ShaderMaterial = ShaderMaterial.new()
	reveal.shader = HOME_REVEAL_SHADER
	reveal.set_shader_parameter("clean_plate", HOME_CLEAN_PLATE)
	reveal.set_shader_parameter("reveal_mask", HOME_REVEAL_MASK)
	scene.material = reveal
	home_page.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var botanicals: Control = HOME_BOTANICALS.new() as Control
	home_page.add_child(botanicals)
	botanicals.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var eyebrow: Label = _label(home_page, Vector2(136, 120), Vector2(850, 55), 31, ACCENT, true)
	eyebrow.text = "A STITCHED SHIFT ADVENTURE"
	var title: Label = _label(home_page, Vector2(128, 185), Vector2(870, 158), 105, INK, true)
	title.add_theme_font_override("font", FONT_DISPLAY)
	title.text = "STITCHFALL"
	var line: Label = _label(home_page, Vector2(138, 340), Vector2(840, 84), 39, INK)
	line.text = "Find the buttons. Turn the pull.\nOpen the seam."
	var menu_items: Array[PackedStringArray] = [
		PackedStringArray(["PLAY", "play"]),
		PackedStringArray(["LEVELS", "levels"]),
		PackedStringArray(["GUIDE", "help"]),
		PackedStringArray(["SETTINGS", "settings"]),
	]
	for index: int in range(menu_items.size()):
		var item: PackedStringArray = menu_items[index]
		var button: StitchedButton = _tag(home_page, Rect2(146, 474 + index * 112, 560, 104), item[0], item[1], [Color("e0a278"), Color("dbe5d1"), Color("e8d8bd"), Color("e4d0b1")][index])
		button.home_link = true
		match index:
			0: button.pressed.connect(_begin_from_home)
			1: button.pressed.connect(show_levels)
			2: button.pressed.connect(show_help)
			3: button.pressed.connect(show_settings)
	hero = AnimatedSprite2D.new()
	hero.sprite_frames = _dance_frames()
	hero.scale = Vector2.ONE * 0.92
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
	frames.set_animation_speed("dance", 1.0)
	for pose: Texture2D in DANCE_POSES:
		frames.add_frame("dance", pose, 1.45)
	return frames


func _build_levels() -> void:
	level_page = _page()
	_cloth_page(level_page, Rect2(65, 50, 1790, 970))
	var heading: Label = _label(level_page, Vector2(290, 107), Vector2(1100, 105), 77, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "CHOOSE A SEAM"
	level_previous = _tag(level_page, Rect2(1460, 102, 100, 101), "", "back", Color("e5d5bc"))
	level_previous.pressed.connect(func() -> void: _set_level_page(level_page_index - 1))
	level_next = _tag(level_page, Rect2(1580, 102, 100, 101), "", "next", Color("e5d5bc"))
	level_next.pressed.connect(func() -> void: _set_level_page(level_page_index + 1))
	_tag(level_page, Rect2(1700, 102, 100, 101), "", "home", Color("e5d5bc")).pressed.connect(show_home)
	for slot: int in range(8):
		var column: int = slot % 4
		var row: int = slot / 4
		var button: StitchedButton = _tag(level_page, Rect2(165 + column * 405, 250 + row * 330, 385, 280), "", "seam", Color("f1e1c8"))
		button.level_tile = true
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
	_cloth_page(help_page, Rect2(170, 70, 1580, 910))
	var heading: Label = _label(help_page, Vector2(315, 135), Vector2(1150, 104), 67, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "HOW TO PLAY"
	_tag(help_page, Rect2(1560, 130, 112, 105), "", "back", Color("e5d5bc")).pressed.connect(show_home)
	var introduction: Label = _label(help_page, Vector2(266, 244), Vector2(1250, 60), 35, ACCENT)
	introduction.text = "Draw a gesture on the cloth to move the runner."
	var instructions: Array[PackedStringArray] = [
		PackedStringArray(["MOVE", "Slide left or right", "move"]),
		PackedStringArray(["JUMP", "Swipe up", "jump"]),
		PackedStringArray(["CROUCH", "Swipe down", "crouch"]),
		PackedStringArray(["SHIFT", "Tap the playfield", "shift"]),
	]
	for index: int in range(instructions.size()):
		var column: int = index % 2
		var row: int = index / 2
		var instruction: PackedStringArray = instructions[index]
		var card: Panel = _panel(help_page, Rect2(250 + column * 720, 335 + row * 250, 660, 185), Color("ecdfc7") if index != 3 else Color("e2b18f"))
		var title: Label = _label(card, Vector2(24, 24), Vector2(210, 60), 40, INK, true)
		title.text = instruction[0]
		var caption: Label = _label(card, Vector2(24, 107), Vector2(210, 58), 27, ACCENT)
		caption.text = instruction[1]
		var gesture: PalewheelGestureGuide = GESTURE_GUIDE.new() as PalewheelGestureGuide
		gesture.position = Vector2(240, 12)
		gesture.size = Vector2(405, 160)
		gesture.kind = instruction[2]
		card.add_child(gesture)
	var footer: Label = _label(help_page, Vector2(265, 800), Vector2(1300, 70), 31, ACCENT)
	footer.text = "Keyboard: A / D, W / Space, S, Shift. Esc pauses. R retries."
	var start: StitchedButton = _tag(help_page, Rect2(1490, 810, 145, 126), "", "play", Color("e0a278"))
	start.tooltip_text = "Start playing"
	start.pressed.connect(func() -> void: begin_pressed.emit())


func _build_about() -> void:
	about_page = _page()
	_cloth_page(about_page, Rect2(210, 90, 1500, 880))
	var heading: Label = _label(about_page, Vector2(355, 145), Vector2(1080, 110), 78, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "A WORLD IN THREAD"
	_tag(about_page, Rect2(1510, 138, 112, 105), "", "back", Color("e5d5bc")).pressed.connect(show_home)
	var note: Label = _label(about_page, Vector2(320, 305), Vector2(820, 210), 48, INK)
	note.text = "A few brave steps can turn a whole world upside down."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var studio: Label = _label(about_page, Vector2(320, 565), Vector2(790, 190), 38, INK)
	studio.text = "Made by Chaosmos, a small studio making calm, clever games, one at a time."
	studio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = DANCE_POSES[0]
	portrait.position = Vector2(1140, 300)
	portrait.size = Vector2(350, 560)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	about_page.add_child(portrait)
	var signoff: Label = _label(about_page, Vector2(320, 755), Vector2(790, 65), 34, ACCENT, true)
	signoff.text = "Thanks for spending a little time here."


func _build_settings() -> void:
	settings_page = _page()
	_cloth_page(settings_page, Rect2(425, 110, 1070, 825))
	var heading: Label = _label(settings_page, Vector2(570, 176), Vector2(780, 110), 72, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.text = "SETTINGS"
	_tag(settings_page, Rect2(1345, 181, 105, 105), "", "back", Color("e5d5bc")).pressed.connect(show_home)
	var sound_button: StitchedButton = _tag(settings_page, Rect2(540, 426, 260, 270), "SOUND", "sound", Color("e8d8bd"))
	sound_button.pause_action = true
	sound_buttons.append(sound_button)
	sound_button.pressed.connect(_toggle_sound)
	var fullscreen_button: StitchedButton = _tag(settings_page, Rect2(830, 426, 260, 270), "FULLSCREEN", "fullscreen", Color("dbe5d1"))
	fullscreen_button.pause_action = true
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	var about_button: StitchedButton = _tag(settings_page, Rect2(1120, 426, 260, 270), "ABOUT", "seam", Color("e4d0b1"))
	about_button.pause_action = true
	about_button.pressed.connect(show_about)
	var note: Label = _label(settings_page, Vector2(570, 774), Vector2(780, 55), 30, ACCENT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.text = "M changes sound. F goes fullscreen."


func _toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.stitchfallToggleFullscreen?.()")
	else:
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _build_pause() -> void:
	pause_page = _page()
	var cloth: TextureRect = TextureRect.new()
	cloth.texture = PAUSE_CLOTH
	cloth.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cloth.stretch_mode = TextureRect.STRETCH_SCALE
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloth.position = Vector2(500, 165)
	cloth.size = Vector2(920, 700)
	pause_page.add_child(cloth)
	pause_heading = _label(pause_page, Vector2(585, 230), Vector2(750, 125), 74, INK, true)
	pause_heading.add_theme_font_override("font", FONT_DISPLAY)
	pause_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_body = _label(pause_page, Vector2(600, 355), Vector2(720, 95), 32, INK)
	pause_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	restart_button = _tag(pause_page, Rect2(620, 500, 230, 255), "RETRY", "restart", Color("dbe5d1"))
	restart_button.pause_action = true
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	resume_button = _tag(pause_page, Rect2(850, 472, 270, 290), "RESUME", "play", Color("e0a278"))
	resume_button.pause_action = true
	resume_button.pressed.connect(func() -> void: begin_pressed.emit())
	pause_home_button = _tag(pause_page, Rect2(1120, 500, 230, 255), "HOME", "home", Color("e8d8bd"))
	pause_home_button.pause_action = true
	pause_home_button.pressed.connect(func() -> void: home_pressed.emit())


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
	panel.color = Color("3c342f", 0.52) if name in ["pause", "finish"] else Color("f5ead5", 0.89)
	fabric.visible = name in ["levels", "help", "about", "settings"]
	home_page.visible = name == "home"
	level_page.visible = name == "levels"
	help_page.visible = name == "help"
	about_page.visible = name == "about"
	settings_page.visible = name == "settings"
	pause_page.visible = name in ["pause", "finish"]
	meter.visible = false
	pause_button.visible = false
	hint_back.visible = false
	if name == "home":
		hero.play("dance")
	else:
		hero.stop()


func show_home() -> void:
	_show_screen("home")


func _begin_from_home() -> void:
	if DisplayServer.is_touchscreen_available() and not guide_seen:
		show_help()
	else:
		begin_pressed.emit()


func show_levels() -> void:
	_set_level_page(0)
	_show_screen("levels")


func show_help() -> void:
	guide_seen = true
	_show_screen("help")


func show_about() -> void:
	_show_screen("about")


func show_settings() -> void:
	_show_screen("settings")


func show_pause() -> void:
	pause_heading.text = "PAUSED"
	pause_heading.add_theme_font_size_override("font_size", 74)
	pause_body.text = ""
	resume_button.caption = "RESUME"
	resume_button.position.x = 850
	resume_button.queue_redraw()
	restart_button.visible = true
	pause_home_button.position.x = 1120
	_show_screen("pause")
	resume_button.grab_focus()


func show_finish(time_text: String, shift_count: int, hit_count: int) -> void:
	pause_heading.text = "THE SEAM HOLDS"
	pause_heading.add_theme_font_size_override("font_size", 51)
	pause_body.text = "Time %s     Shifts %d     Hits %d" % [time_text, shift_count, hit_count]
	resume_button.caption = "PLAY AGAIN"
	resume_button.position.x = 700
	resume_button.queue_redraw()
	restart_button.visible = false
	pause_home_button.position.x = 1040
	_show_screen("finish")
	resume_button.grab_focus()


func hide_panel() -> void:
	screen = "game"
	panel.visible = false
	meter.visible = true
	pause_button.visible = true
	hero.stop()


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
