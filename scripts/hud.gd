class_name StitchfallHud
extends CanvasLayer

signal begin_pressed
signal pause_pressed
signal restart_pressed
signal home_pressed
signal level_selected(index: int)
signal sound_toggled(enabled: bool)
signal next_pressed
signal levels_pressed
signal music_toggled(enabled: bool)
signal wardrobe_changed
signal progress_reset
signal chapter_done

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
const STAR_SOUND: AudioStream = preload("res://assets/audio/sfx/star.wav")
const STAR_MISS_SOUND: AudioStream = preload("res://assets/audio/sfx/star_miss.wav")

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
var level_heading: Label
var level_tally: Label
var progress: StitchfallProgress
var clear_page: Control
var clear_name: Label
var clear_stars: StitchfallStarRow
var clear_time: Label
var clear_quip: Label
var clear_best: Label
var clear_next: StitchedButton
var clear_hero: AnimatedSprite2D
var clear_tween: Tween
var star_sound: AudioStreamPlayer
var tap_sound: AudioStreamPlayer
var clear_heading: Label
var clear_card: Control
var clear_opened: Label
var room_label: Label
var unravel_tag: Panel
var unravel_label: Label
var flash_rect: ColorRect
var chapter_page: Control
var chapter_number: Label
var chapter_name_label: Label
var chapter_line_label: Label
var chapter_tween: Tween
var settings_tags: Dictionary[String, StitchedButton] = {}
var reset_armed: bool = false
var stats_page: Control
var stats_lines: Label
var credits_page: Control
var wardrobe_page: Control
var wardrobe_kind: String = "runner"
var wardrobe_tabs: Dictionary[String, StitchedButton] = {}
var wardrobe_tiles: Array[StitchfallItemTile] = []
var wardrobe_preview: AnimatedSprite2D
var wardrobe_name: Label
var wardrobe_line: Label
var wardrobe_note: Label
var wardrobe_buy: StitchedButton
var wardrobe_restore: StitchedButton
var wardrobe_tip: StitchedButton
var unravel_count: int = 0
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
	if progress != null:
		audio_enabled = progress.sound
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
	# The chapter and room you are in, small and steady at the top, above a screen room's ceiling.
	room_label = _label(root, Vector2(560, 22), Vector2(800, 44), 28, INK, true)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.add_theme_color_override("font_outline_color", Color("f7edda"))
	room_label.add_theme_constant_override("outline_size", 8)
	# Level Devil keeps a count of your deaths in plain sight, and so does this: unravels in this room.
	unravel_tag = _panel(root, Rect2(250, 30, 150, 58), Color("f5e8d1", 0.94))
	unravel_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unravel_label = _label(unravel_tag, Vector2(10, 2), Vector2(130, 52), 30, ACCENT, true)
	unravel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unravel_tag.pivot_offset = Vector2(75, 29)
	hint_back = _panel(root, Rect2(470, 102, 980, 154), Color("f5e8d1", 0.94))
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_title = _label(hint_back, Vector2(32, 6), Vector2(916, 52), 34, INK, true)
	hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body = _label(hint_back, Vector2(32, 57), Vector2(916, 80), 24, INK)
	hint_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flash_rect = ColorRect.new()
	flash_rect.color = Color("fff3e0", 0.0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash_rect)
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_sound = AudioStreamPlayer.new()
	tap_sound.stream = preload("res://assets/audio/sfx/tap.wav")
	tap_sound.volume_db = -6.0
	add_child(tap_sound)
	_build_pages()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _layout() -> void:
	var mobile_scale: float = 1.2 if DisplayServer.is_touchscreen_available() else 1.0
	meter.scale = Vector2.ONE * mobile_scale
	pause_button.scale = Vector2.ONE * mobile_scale
	pause_button.position.x = root.size.x - pause_button.size.x * mobile_scale - 28.0
	hint_back.position.x = (root.size.x - hint_back.size.x) * 0.5
	room_label.position.x = (root.size.x - room_label.size.x) * 0.5
	unravel_tag.scale = Vector2.ONE * mobile_scale
	unravel_tag.position.x = meter.position.x + meter.size.x * mobile_scale + 14.0
	hero.position.x = root.size.x * 0.735
	level_page.position.x = (root.size.x - 1920.0) * 0.5
	help_page.position.x = (root.size.x - 1920.0) * 0.5
	about_page.position.x = (root.size.x - 1920.0) * 0.5
	settings_page.position.x = (root.size.x - 1920.0) * 0.5
	for page: Control in [pause_page, clear_page, chapter_page, stats_page, credits_page, wardrobe_page]:
		page.position.x = (root.size.x - 1920.0) * 0.5


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
	value.pressed.connect(_tap)
	parent.add_child(value)
	return value


func _tap() -> void:
	if audio_enabled:
		tap_sound.play()


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
	_build_clear()
	_build_chapter()
	_build_stats()
	_build_credits()
	_build_wardrobe()
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
	var title: Label = _label(home_page, Vector2(128, 172), Vector2(870, 158), 105, INK, true)
	title.add_theme_font_override("font", FONT_DISPLAY)
	title.text = "STITCHFALL"
	var line: Label = _label(home_page, Vector2(138, 316), Vector2(840, 84), 39, INK)
	line.text = "Find the buttons. Turn the pull.\nOpen the seam."
	var menu_items: Array[PackedStringArray] = [
		PackedStringArray(["PLAY", "play"]),
		PackedStringArray(["LEVELS", "levels"]),
		PackedStringArray(["WARDROBE", "wardrobe"]),
		PackedStringArray(["GUIDE", "help"]),
		PackedStringArray(["SETTINGS", "settings"]),
	]
	for index: int in range(menu_items.size()):
		var item: PackedStringArray = menu_items[index]
		var button: StitchedButton = _tag(home_page, Rect2(146, 420 + index * 88, 560, 82), item[0], item[1], [Color("e0a278"), Color("dbe5d1"), Color("efd3b8"), Color("e8d8bd"), Color("e4d0b1")][index])
		button.home_link = true
		match index:
			0: button.pressed.connect(_begin_from_home)
			1: button.pressed.connect(show_levels)
			2: button.pressed.connect(show_wardrobe)
			3: button.pressed.connect(show_help)
			4: button.pressed.connect(show_settings)
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
	return StitchfallLooks.dance_frames(_runner())


func _runner() -> String:
	var runner: String = progress.wear["runner"] if progress != null else "seam"
	return runner if StitchfallLooks.has_art(runner) else "seam"


# The home and clear-card dancers follow the runner the wardrobe has on. A dance sheet's frames are cut from a
# 4 by 2 grid, so they are scaled to stand as tall as the poses.
func _dress_dancers() -> void:
	for dancer: AnimatedSprite2D in [hero, clear_hero]:
		if dancer == null:
			continue
		var playing_now: bool = dancer.is_playing()
		dancer.sprite_frames = _dance_frames()
		var height: float = dancer.sprite_frames.get_frame_texture("dance", 0).get_size().y
		dancer.scale = Vector2.ONE * (0.92 if dancer == hero else 0.6) * 650.0 / height
		if playing_now:
			dancer.play("dance")


func _build_levels() -> void:
	level_page = _page()
	_cloth_page(level_page, Rect2(65, 50, 1790, 970))
	level_heading = _label(level_page, Vector2(200, 100), Vector2(1200, 105), 77, INK, true)
	level_heading.add_theme_font_override("font", FONT_DISPLAY)
	level_tally = _label(level_page, Vector2(206, 200), Vector2(1100, 60), 36, ACCENT)
	level_previous = _tag(level_page, Rect2(1460, 102, 100, 101), "", "back", Color("e5d5bc"))
	level_previous.pressed.connect(func() -> void: _set_level_page(level_page_index - 1))
	level_next = _tag(level_page, Rect2(1580, 102, 100, 101), "", "next", Color("e5d5bc"))
	level_next.pressed.connect(func() -> void: _set_level_page(level_page_index + 1))
	_tag(level_page, Rect2(1700, 102, 100, 101), "", "home", Color("e5d5bc")).pressed.connect(show_home)
	for slot: int in range(StitchfallLevels.CHAPTER_ROOMS):
		var button: StitchedButton = _tag(level_page, Rect2(150 + slot * 330, 330, 310, 360), "", "seam", Color("f1e1c8"))
		button.level_tile = true
		button.pressed.connect(_select_visible_level.bind(slot))
		level_buttons.append(button)
	_set_level_page(0)


# One page is one chapter, with its name, its stars so far, and its five rooms.
func _set_level_page(value: int) -> void:
	level_page_index = clampi(value, 0, StitchfallLevels.chapter_count() - 1)
	level_previous.visible = level_page_index > 0
	level_next.visible = level_page_index + 1 < StitchfallLevels.chapter_count()
	level_heading.text = StitchfallLevels.chapter_name(level_page_index).to_upper()
	var earned: int = 0
	var rooms: int = 0
	for slot: int in range(level_buttons.size()):
		var index: int = level_page_index * StitchfallLevels.CHAPTER_ROOMS + slot
		var button: StitchedButton = level_buttons[slot]
		button.visible = index < StitchfallLevels.count()
		if not button.visible:
			continue
		rooms += 1
		var data: Dictionary = StitchfallLevels.get_level(index)
		var biome: int = data["backdrop"]
		var palette: Array[Color] = _biome_palette(biome)
		button.caption = "%02d" % [index + 1]
		button.subcaption = data["name"]
		button.glyph = _biome_glyph(biome)
		button.cloth = palette[0]
		button.thread = palette[1]
		button.stars = progress.stars(index) if progress != null else 0
		button.locked = progress != null and not progress.is_open(index)
		button.disabled = button.locked
		button.tooltip_text = ""
		earned += maxi(button.stars, 0)
		button.queue_redraw()
	level_tally.text = "Chapter %d     %d of %d stars" % [level_page_index + 1, earned, rooms * 3]


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
		var gesture: StitchfallGestureGuide = GESTURE_GUIDE.new() as StitchfallGestureGuide
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
	var heading: Label = _label(about_page, Vector2(320, 135), Vector2(1080, 110), 78, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "A WORLD IN THREAD"
	_tag(about_page, Rect2(1510, 138, 112, 105), "", "back", Color("e5d5bc")).pressed.connect(show_settings)
	var note: Label = _label(about_page, Vector2(320, 250), Vector2(840, 230), 33, INK)
	note.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	note.text = "Stitchfall is a platformer sewn from cloth. Turn the whole room a quarter at a time, gather its buttons, and slip out through the zipper. Every room hides one trick, so look twice."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var studio: Label = _label(about_page, Vector2(320, 505), Vector2(840, 80), 30, INK)
	studio.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	studio.text = "Made by Chaosmos, a small studio making clever little games, one at a time."
	studio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var version: Label = _label(about_page, Vector2(320, 600), Vector2(820, 46), 28, ACCENT, true)
	version.text = "Version %s" % version_name()
	var links: Array = [["WEBSITE", "link", StitchfallShop.WEBSITE], ["SUPPORT", "help", StitchfallShop.SUPPORT], ["PRIVACY", "seam", StitchfallShop.PRIVACY], ["GAMES", "play", StitchfallShop.MORE_GAMES]]
	# The browser build can point to GitHub Sponsors. The Android build never may, by Play's Payments policy.
	if not StitchfallShop.on_play:
		links.append(["SPONSOR", "gift", StitchfallShop.SPONSOR])
	for index: int in range(links.size()):
		var link: Array = links[index]
		var tag: StitchedButton = _tag(about_page, Rect2(300 + index * 172, 665, 162, 195), link[0], link[1], [Color("dbe5d1"), Color("e8d8bd"), Color("e4d0b1"), Color("efd3b8"), Color("e0a278")][index])
		tag.pause_action = true
		tag.caption_size = 26
		var url: String = link[2]
		tag.pressed.connect(func() -> void: OS.shell_open(url))
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = DANCE_POSES[0]
	portrait.position = Vector2(1180, 260)
	portrait.size = Vector2(330, 540)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	about_page.add_child(portrait)


func _build_settings() -> void:
	settings_page = _page()
	_cloth_page(settings_page, Rect2(330, 70, 1260, 940))
	var heading: Label = _label(settings_page, Vector2(560, 120), Vector2(800, 110), 72, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.text = "SETTINGS"
	_tag(settings_page, Rect2(1420, 125, 105, 105), "", "back", Color("e5d5bc")).pressed.connect(show_home)
	var entries: Array = [
		["sound", "SOUND", "sound", Color("e8d8bd"), _toggle_sound],
		["music", "MUSIC", "music", Color("dbe5d1"), _toggle_music],
		["shake", "SHAKE", "shake", Color("efd3b8"), _toggle_shake],
		["fullscreen", "FULLSCREEN", "fullscreen", Color("e4d0b1"), _toggle_fullscreen],
		["stats", "STATS", "stats", Color("dbe5d1"), show_stats],
		["credits", "CREDITS", "credits", Color("e8d8bd"), show_credits],
		["about", "ABOUT", "help", Color("e4d0b1"), show_about],
		["reset", "RESET", "restart", Color("e9c9bd"), _reset_progress],
	]
	for index: int in range(entries.size()):
		var entry: Array = entries[index]
		var tag: StitchedButton = _tag(settings_page, Rect2(420 + (index % 4) * 275, 250 + (index / 4) * 300, 255, 270), entry[1], entry[2], entry[3])
		tag.pause_action = true
		tag.pressed.connect(entry[4])
		settings_tags[entry[0]] = tag
	sound_buttons.append(settings_tags["sound"])
	settings_tags["fullscreen"].visible = not OS.has_feature("android")
	var note: Label = _label(settings_page, Vector2(480, 845), Vector2(960, 50), 28, ACCENT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.text = "M changes sound. F goes fullscreen."


# Shows each switch's state in its icon, and puts the reset back to asking once.
func _refresh_settings() -> void:
	if progress == null:
		return
	settings_tags["sound"].glyph = "sound" if audio_enabled else "mute"
	settings_tags["music"].glyph = "music" if progress.music else "music_off"
	settings_tags["shake"].glyph = "shake" if progress.shake else "shake_off"
	settings_tags["sound"].caption = "SOUND" if audio_enabled else "NO SOUND"
	settings_tags["music"].caption = "MUSIC" if progress.music else "NO MUSIC"
	settings_tags["shake"].caption = "SHAKE" if progress.shake else "NO SHAKE"
	reset_armed = false
	settings_tags["reset"].caption = "RESET"
	for tag: StitchedButton in settings_tags.values():
		tag.queue_redraw()


func _toggle_music() -> void:
	progress.music = not progress.music
	music_toggled.emit(progress.music)
	_refresh_settings()


func _toggle_shake() -> void:
	progress.shake = not progress.shake
	progress.save()
	_refresh_settings()


# Reset asks twice: the first press turns the tag into a question.
func _reset_progress() -> void:
	if not reset_armed:
		reset_armed = true
		settings_tags["reset"].caption = "SURE?"
		settings_tags["reset"].queue_redraw()
		return
	progress_reset.emit()
	_refresh_settings()
	settings_tags["reset"].caption = "DONE"
	settings_tags["reset"].queue_redraw()
	_dress_dancers()


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


# The card that closes a room: its stars pop in one by one, then the time against par and a line about how
# many times the runner came apart.
func _build_clear() -> void:
	clear_page = _page()
	clear_card = Control.new()
	clear_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear_page.add_child(clear_card)
	clear_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cloth_page(clear_card, Rect2(380, 100, 1160, 880))
	clear_heading = _label(clear_card, Vector2(450, 130), Vector2(800, 120), 92, INK, true)
	clear_heading.add_theme_font_override("font", FONT_DISPLAY)
	clear_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_name = _label(clear_card, Vector2(450, 240), Vector2(800, 56), 38, ACCENT, true)
	clear_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_stars = StitchfallStarRow.new()
	clear_stars.position = Vector2(470, 295)
	clear_stars.size = Vector2(760, 220)
	clear_card.add_child(clear_stars)
	clear_time = _label(clear_card, Vector2(450, 500), Vector2(800, 50), 34, INK)
	clear_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_quip = _label(clear_card, Vector2(450, 542), Vector2(800, 46), 30, ACCENT)
	clear_quip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_best = _label(clear_card, Vector2(450, 584), Vector2(800, 42), 29, Color("b8862a"), true)
	clear_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_opened = _label(clear_card, Vector2(450, 622), Vector2(800, 42), 29, Color("5f8b5a"), true)
	clear_opened.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var replay: StitchedButton = _tag(clear_card, Rect2(490, 676, 205, 210), "REPLAY", "restart", Color("dbe5d1"))
	replay.pause_action = true
	replay.pressed.connect(func() -> void: restart_pressed.emit())
	var levels: StitchedButton = _tag(clear_card, Rect2(715, 676, 205, 210), "LEVELS", "levels", Color("e8d8bd"))
	levels.pause_action = true
	levels.pressed.connect(func() -> void: levels_pressed.emit())
	clear_next = _tag(clear_card, Rect2(950, 656, 240, 240), "NEXT", "play", Color("e0a278"))
	clear_next.pause_action = true
	clear_next.pressed.connect(func() -> void: next_pressed.emit())
	clear_hero = AnimatedSprite2D.new()
	clear_hero.sprite_frames = _dance_frames()
	clear_hero.scale = Vector2.ONE * 0.6
	clear_hero.position = Vector2(1385, 560)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CLEANUP_SHADER
	clear_hero.material = material
	clear_card.add_child(clear_hero)
	star_sound = AudioStreamPlayer.new()
	add_child(star_sound)


# Shows the clear card for a room. `card` carries the result from StitchfallProgress.record plus the room's
# name, time, par and unravels, and whether it closed a chapter.
func show_clear(card: Dictionary) -> void:
	var time: float = card["time"]
	var par: float = card["par"]
	var unravels: int = card["unravels"]
	var chapter_end: bool = card["chapter_end"]
	clear_heading.text = "CHAPTER SEWN!" if chapter_end else "SEWN!"
	clear_heading.add_theme_font_size_override("font_size", 74 if chapter_end else 92)
	clear_name.text = "%s     %d of %d stars" % [card["chapter_name"], int(card["chapter_stars"]), StitchfallLevels.CHAPTER_ROOMS * 3] if chapter_end else str(card["name"])
	clear_time.text = "%.1f s     par %d s" % [time, ceili(par)]
	clear_quip.text = _quip(unravels)
	clear_best.text = "New best time" if card["faster"] else ("More stars than last time" if card["more_stars"] else "")
	var opened: Array = card.get("opened", [])
	var names: PackedStringArray = PackedStringArray()
	for item: Dictionary in opened:
		names.append(item["name"])
	clear_opened.text = "New in the wardrobe: %s" % ", ".join(names) if not names.is_empty() else ""
	for star: int in range(3):
		clear_stars.earned[star] = StitchfallProgress.star_earned(star, time, unravels, par)
		clear_stars.pop[star] = 0.0
	clear_stars.queue_redraw()
	_show_screen("clear")
	clear_hero.play("dance")
	clear_next.grab_focus()
	if clear_tween and clear_tween.is_running():
		clear_tween.kill()
	clear_card.position.y = 760.0
	clear_tween = create_tween()
	clear_tween.tween_property(clear_card, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	clear_tween.tween_interval(0.1)
	for star: int in range(3):
		clear_tween.tween_callback(_star_chime.bind(star))
		clear_tween.tween_method(clear_stars.set_pop.bind(star), 0.0, 1.0, 0.38)


func _star_chime(star: int) -> void:
	if not audio_enabled:
		return
	var earned: bool = clear_stars.earned[star]
	star_sound.stream = STAR_SOUND if earned else STAR_MISS_SOUND
	star_sound.pitch_scale = 1.0 + float(star) * 0.19 if earned else 1.0
	star_sound.play()


# A line for the clear card, from how many times the runner unravelled in the room.
func _quip(unravels: int) -> String:
	if unravels == 0:
		return "Not a thread out of place."
	if unravels <= 2:
		return "Unravelled %d %s. A little frayed, still standing." % [unravels, "time" if unravels == 1 else "times"]
	if unravels <= 6:
		return "Unravelled %d times. Worth it." % unravels
	if unravels <= 14:
		return "Unravelled %d times. The room enjoyed that." % unravels
	return "Unravelled %d times. Stubborn as a knot." % unravels


# A chapter's title card: its number, its name and a line, before its first room. Any tap or key moves on.
func _build_chapter() -> void:
	chapter_page = _page()
	chapter_page.mouse_filter = Control.MOUSE_FILTER_STOP
	chapter_page.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_pressed():
			skip_chapter())
	_cloth_page(chapter_page, Rect2(360, 250, 1200, 580))
	chapter_number = _label(chapter_page, Vector2(460, 330), Vector2(1000, 60), 40, ACCENT, true)
	chapter_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_name_label = _label(chapter_page, Vector2(460, 400), Vector2(1000, 170), 118, INK, true)
	chapter_name_label.add_theme_font_override("font", FONT_DISPLAY)
	chapter_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_name_label.pivot_offset = Vector2(500, 85)
	chapter_line_label = _label(chapter_page, Vector2(460, 600), Vector2(1000, 70), 38, INK)
	chapter_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func show_chapter(chapter: int, chapter_title: String, line: String) -> void:
	chapter_number.text = "CHAPTER %d" % (chapter + 1)
	chapter_name_label.text = chapter_title.to_upper()
	chapter_line_label.text = line
	_show_screen("chapter")
	if chapter_tween and chapter_tween.is_running():
		chapter_tween.kill()
	chapter_name_label.scale = Vector2.ONE * 0.6
	chapter_name_label.modulate.a = 0.0
	chapter_line_label.modulate.a = 0.0
	chapter_tween = create_tween()
	chapter_tween.tween_property(chapter_name_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chapter_tween.parallel().tween_property(chapter_name_label, "modulate:a", 1.0, 0.25)
	chapter_tween.tween_property(chapter_line_label, "modulate:a", 1.0, 0.35)
	chapter_tween.tween_interval(1.7)
	chapter_tween.tween_callback(skip_chapter)


func skip_chapter() -> void:
	if screen != "chapter":
		return
	if chapter_tween and chapter_tween.is_running():
		chapter_tween.kill()
	hide_panel()
	chapter_done.emit()


func _build_stats() -> void:
	stats_page = _page()
	_cloth_page(stats_page, Rect2(330, 70, 1260, 940))
	var heading: Label = _label(stats_page, Vector2(560, 120), Vector2(800, 110), 72, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.text = "YOUR STITCHES"
	_tag(stats_page, Rect2(1420, 125, 105, 105), "", "back", Color("e5d5bc")).pressed.connect(show_settings)
	stats_lines = _label(stats_page, Vector2(500, 270), Vector2(920, 620), 38, INK)
	stats_lines.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stats_lines.add_theme_constant_override("line_spacing", 22)


func show_stats() -> void:
	var minutes: int = int(progress.play_time / 60.0)
	var open_pieces: int = 0
	var all_pieces: int = 0
	for kind: String in StitchfallLooks.KINDS:
		for item: Dictionary in StitchfallLooks.items(kind):
			all_pieces += 1
			open_pieces += 1 if StitchfallShop.is_open(item, progress) else 0
	var rows: Array[String] = [
		"Rooms sewn:  %d of %d" % [progress.best_stars.size(), StitchfallLevels.count()],
		"Stars:  %d of %d" % [progress.total_stars(), StitchfallLevels.count() * 3],
		"Times unravelled:  %d" % progress.unravels,
		"Turns of the room:  %d" % progress.turns,
		"Buttons gathered:  %d" % progress.buttons,
		"Time in the rooms:  %d h %02d m" % [minutes / 60, minutes % 60],
		"Wardrobe open:  %d of %d" % [open_pieces, all_pieces],
	]
	stats_lines.text = "\n".join(rows)
	_show_screen("stats")


func _build_credits() -> void:
	credits_page = _page()
	_cloth_page(credits_page, Rect2(210, 70, 1500, 940))
	var heading: Label = _label(credits_page, Vector2(370, 120), Vector2(1030, 110), 72, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "CREDITS"
	_tag(credits_page, Rect2(1510, 125, 112, 105), "", "back", Color("e5d5bc")).pressed.connect(show_settings)
	var body: Label = _label(credits_page, Vector2(320, 250), Vector2(1280, 690), 31, INK)
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 8)
	body.text = "\n".join([
		"Made by Shravan Goswami at Chaosmos, with the help of AI tools.",
		"",
		"The stitched world, the runners, the props and the icons were made for this game.",
		"The sound effects and the music were synthesized for this game.",
		"Darn and Threadline are original Chaosmos fonts, under the SIL Open Font License.",
		"Built with the Godot Engine, under the MIT license. Copyright (c) 2014-present Godot Engine contributors, (c) 2007-2014 Juan Linietsky and Ariel Manzur.",
		"",
		"Thank you to everyone who plays, and to GitHub Game Off.",
	])


# The wardrobe: a dancing preview on the left, a tab per kind of piece, and the pieces as tiles.
func _build_wardrobe() -> void:
	wardrobe_page = _page()
	_cloth_page(wardrobe_page, Rect2(65, 50, 1790, 970))
	var heading: Label = _label(wardrobe_page, Vector2(170, 95), Vector2(700, 105), 77, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "WARDROBE"
	_tag(wardrobe_page, Rect2(1700, 100, 100, 101), "", "home", Color("e5d5bc")).pressed.connect(show_home)
	wardrobe_preview = AnimatedSprite2D.new()
	wardrobe_preview.position = Vector2(390, 520)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CLEANUP_SHADER
	wardrobe_preview.material = material
	wardrobe_page.add_child(wardrobe_preview)
	wardrobe_name = _label(wardrobe_page, Vector2(160, 760), Vector2(470, 56), 40, INK, true)
	wardrobe_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wardrobe_line = _label(wardrobe_page, Vector2(160, 815), Vector2(470, 100), 28, ACCENT)
	wardrobe_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wardrobe_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for index: int in range(StitchfallLooks.KINDS.size()):
		var kind: String = StitchfallLooks.KINDS[index]
		var tab: StitchedButton = _tag(wardrobe_page, Rect2(680 + index * 225, 205, 215, 84), StitchfallLooks.KIND_NAMES[index].to_upper(), "", Color("e5d5bc"))
		tab.caption_size = 30
		tab.pressed.connect(_show_kind.bind(kind))
		wardrobe_tabs[kind] = tab
	for slot: int in range(8):
		var tile: StitchfallItemTile = StitchfallItemTile.new()
		tile.position = Vector2(690 + (slot % 4) * 275, 305 + (slot / 4) * 268)
		tile.size = Vector2(255, 255)
		tile.pressed.connect(_choose_piece.bind(slot))
		tile.pressed.connect(_tap)
		wardrobe_page.add_child(tile)
		wardrobe_tiles.append(tile)
	wardrobe_note = _label(wardrobe_page, Vector2(690, 838), Vector2(600, 72), 27, ACCENT)
	wardrobe_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wardrobe_buy = _tag(wardrobe_page, Rect2(1300, 836, 270, 78), "WARDROBE PACK", "", Color("e0a278"))
	wardrobe_buy.caption_size = 28
	wardrobe_buy.pressed.connect(func() -> void: _say(StitchfallShop.buy(StitchfallShop.WARDROBE_ID)))
	wardrobe_restore = _tag(wardrobe_page, Rect2(1580, 832, 90, 86), "", "restart", Color("e5d5bc"))
	wardrobe_restore.tooltip_text = "Restore purchases"
	wardrobe_restore.pressed.connect(func() -> void: _say(StitchfallShop.restore()))
	wardrobe_tip = _tag(wardrobe_page, Rect2(1680, 832, 90, 86), "", "gift", Color("efd3b8"))
	wardrobe_tip.tooltip_text = "Leave a tip"
	wardrobe_tip.pressed.connect(func() -> void: _say(StitchfallShop.buy(StitchfallShop.TIP_ID)))


func show_wardrobe() -> void:
	_show_screen("wardrobe")
	_show_kind(wardrobe_kind)


func _show_kind(kind: String) -> void:
	wardrobe_kind = kind
	for key: String in wardrobe_tabs:
		wardrobe_tabs[key].cloth = Color("e0a278") if key == kind else Color("e5d5bc")
		wardrobe_tabs[key].queue_redraw()
	var pieces: Array[Dictionary] = StitchfallLooks.items(kind)
	for slot: int in range(wardrobe_tiles.size()):
		var tile: StitchfallItemTile = wardrobe_tiles[slot]
		tile.visible = slot < pieces.size()
		if tile.visible:
			var item: Dictionary = pieces[slot]
			tile.show_item(item, StitchfallShop.is_open(item, progress), progress.wear[kind] == item["id"])
	var on_play: bool = StitchfallShop.on_play
	wardrobe_buy.visible = on_play and not StitchfallShop.has_pack(progress)
	wardrobe_restore.visible = on_play
	wardrobe_tip.visible = on_play
	var price: String = StitchfallShop.price(StitchfallShop.WARDROBE_ID)
	wardrobe_buy.caption = "WARDROBE PACK" if price.is_empty() else "WARDROBE  %s" % price
	wardrobe_buy.queue_redraw()
	_say("You have %d stars. Every piece is free here in the browser." % progress.total_stars() if not on_play else "You have %d stars. Stars open trails, unravels and buttons." % progress.total_stars())
	_show_worn()


func _show_worn() -> void:
	var runner: Dictionary = StitchfallLooks.find(_runner())
	wardrobe_name.text = runner["name"]
	wardrobe_line.text = runner["line"]
	wardrobe_preview.sprite_frames = _dance_frames()
	var height: float = wardrobe_preview.sprite_frames.get_frame_texture("dance", 0).get_size().y
	wardrobe_preview.scale = Vector2.ONE * 0.7 * 650.0 / height
	wardrobe_preview.play("dance")


func _choose_piece(slot: int) -> void:
	var item: Dictionary = StitchfallLooks.items(wardrobe_kind)[slot]
	if not StitchfallShop.is_open(item, progress):
		_say("%s comes with the Wardrobe pack." % item["name"] if bool(item["paid"]) else "%s opens at %d stars. You have %d." % [item["name"], int(item["stars"]), progress.total_stars()])
		return
	progress.wear[wardrobe_kind] = item["id"]
	progress.save()
	wardrobe_changed.emit()
	_show_kind(wardrobe_kind)
	_dress_dancers()
	if wardrobe_kind != "runner":
		_say("Wearing %s." % item["name"])


func _say(text: String) -> void:
	if not text.is_empty():
		wardrobe_note.text = text


# Google Play's answers (prices, a purchase, a refund) redraw the wardrobe if it is open, keeping its note.
func refresh_wardrobe() -> void:
	if screen != "wardrobe":
		return
	var note: String = wardrobe_note.text
	_show_kind(wardrobe_kind)
	wardrobe_note.text = note


# The version is the newest section of CHANGELOG.md, the file that also names every Android release.
static func version_name() -> String:
	var file: FileAccess = FileAccess.open("res://CHANGELOG.md", FileAccess.READ)
	if file == null:
		return "?"
	for line: String in file.get_as_text().split("\n"):
		if line.begins_with("## "):
			return line.substr(3).strip_edges().split(" ")[0]
	return "?"


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
	level_selected.emit(level_page_index * StitchfallLevels.CHAPTER_ROOMS + slot)


func _toggle_sound() -> void:
	audio_enabled = not audio_enabled
	for button: StitchedButton in sound_buttons:
		button.glyph = "sound" if audio_enabled else "mute"
		button.tooltip_text = "Mute" if audio_enabled else "Unmute"
		button.queue_redraw()
	sound_toggled.emit(audio_enabled)
	_refresh_settings()


func _show_screen(name: String) -> void:
	screen = name
	panel.visible = true
	panel.color = Color("3c342f", 0.52) if name in ["pause", "finish", "clear", "chapter"] else Color("f5ead5", 0.89)
	clear_page.visible = name == "clear"
	if name != "clear":
		clear_hero.stop()
	fabric.visible = name in ["levels", "help", "about", "settings", "stats", "credits", "wardrobe"]
	home_page.visible = name == "home"
	level_page.visible = name == "levels"
	help_page.visible = name == "help"
	about_page.visible = name == "about"
	settings_page.visible = name == "settings"
	stats_page.visible = name == "stats"
	credits_page.visible = name == "credits"
	wardrobe_page.visible = name == "wardrobe"
	chapter_page.visible = name == "chapter"
	pause_page.visible = name in ["pause", "finish"]
	if name != "wardrobe":
		wardrobe_preview.stop()
	meter.visible = false
	pause_button.visible = false
	hint_back.visible = false
	room_label.visible = false
	unravel_tag.visible = false
	if name == "home":
		hero.play("dance")
	else:
		hero.stop()


func show_home() -> void:
	_dress_dancers()
	_show_screen("home")


func show_credits() -> void:
	_show_screen("credits")


func _begin_from_home() -> void:
	if DisplayServer.is_touchscreen_available() and not guide_seen:
		show_help()
	else:
		begin_pressed.emit()


func show_levels() -> void:
	var resume: int = progress.continue_room(StitchfallLevels.count()) if progress != null else 0
	_set_level_page(resume / StitchfallLevels.CHAPTER_ROOMS)
	_show_screen("levels")


func show_help() -> void:
	guide_seen = true
	_show_screen("help")


func show_about() -> void:
	_show_screen("about")


func show_settings() -> void:
	_refresh_settings()
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
	room_label.visible = true
	unravel_tag.visible = unravel_count > 0
	hero.stop()


func set_room_label(chapter_title: String, number: int, room_name: String) -> void:
	room_label.text = "%s  %d   %s" % [chapter_title, number, room_name]


func set_unravels(count: int) -> void:
	unravel_count = count
	unravel_label.text = "x %d" % count
	unravel_tag.visible = count > 0 and screen == "game"
	if count > 0:
		var pop: Tween = create_tween()
		unravel_tag.scale = Vector2.ONE * 1.5 * meter.scale.x
		pop.tween_property(unravel_tag, "scale", meter.scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# A pale flash over the room when the runner comes apart.
func flash() -> void:
	flash_rect.color.a = 0.45
	create_tween().tween_property(flash_rect, "color:a", 0.0, 0.28)


# The meter's loose buttons pull tight as a flower sews them on.
func bank_buttons() -> void:
	meter.pulse = 1.0


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
	# A name alone is a slim strip that leaves quickly, since a screen room's ceiling sits right under it.
	var name_only: bool = instruction.is_empty()
	hint_back.size.y = 66.0 if name_only else 154.0
	hint_body.visible = not name_only
	hint_back.visible = true
	hint_back.modulate.a = 1.0
	intro_tween = create_tween()
	intro_tween.tween_interval(1.4 if name_only else 2.4)
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
