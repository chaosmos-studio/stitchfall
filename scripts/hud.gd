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
signal skip_pressed

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
# The linen kept between a menu page's cloth and the banner below it, in dp.
const CLOTH_GAP_DP: float = 12.0

var root: Control
var meter: ButtonMeter
var pause_button: StitchedButton
var hint_back: Panel
var hint_title: Label
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
var stats_boards: StitchedButton
var stats_achievements: StitchedButton
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
var wardrobe_shop: StitchedButton
var shop_page: Control
var shop_line: Label
var shop_cards: Dictionary[String, StitchedButton] = {}
var shop_tips: Array[StitchedButton] = []
var shop_note: Label
# The page Back leads to from the Shop and from the update offer.
var shop_return: String = "home"
var update_page: Control
var update_return: String = "home"
var skip_button: StitchedButton
# How far down a menu page may reach while the banner is on screen, from StitchfallAds.
var banner_limit: float = INF
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
	hint_back = _panel(root, Rect2(470, 102, 980, 66), Color("f5e8d1", 0.94))
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_title = _label(hint_back, Vector2(32, 6), Vector2(916, 52), 34, INK, true)
	hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	StitchfallAds.listen(_on_banner_limit)
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
	for page: Control in [level_page, help_page, about_page, settings_page, pause_page, clear_page, chapter_page, stats_page, credits_page, wardrobe_page, shop_page, update_page]:
		var fit: float = page_fit(page)
		page.scale = Vector2.ONE * fit
		page.position.x = (root.size.x - 1920.0 * fit) * 0.5
		_trim_cloth(page, fit)


func _banner_page(page: Control) -> bool:
	return [level_page, wardrobe_page, settings_page, about_page, credits_page, stats_page].has(page)


# A menu page that carries the banner shrinks from its top until everything on it ends BUTTON_GAP_DP above the
# banner, so no button sits near the ad. Every other page, and every page without a banner, keeps its size.
func page_fit(page: Control) -> float:
	if not _banner_page(page):
		return 1.0
	var bottom: float = 0.0
	for child: Node in page.get_children():
		var part: Control = child as Control
		if part != null and part.visible and not part.has_meta(&"cloth"):
			bottom = maxf(bottom, part.position.y + part.size.y)
	return clampf(banner_limit / bottom, 0.5, 1.0) if bottom > 0.0 else 1.0


# The cloth behind a page ends CLOTH_GAP_DP above the banner rather than running under it, so the ad never sits
# on the page.
func _trim_cloth(page: Control, fit: float) -> void:
	var end: float = INF
	if _banner_page(page) and StitchfallAds.banner_wanted():
		end = (StitchfallAds.banner_rect().position.y - CLOTH_GAP_DP * StitchfallAds.per_dp()) / fit
	for child: Node in page.get_children():
		if child.has_meta(&"cloth"):
			var cloth: Control = child as Control
			var rest: Rect2 = cloth.get_meta(&"cloth")
			cloth.size.y = minf(rest.size.y, end - rest.position.y)


func _on_banner_limit(limit: float) -> void:
	banner_limit = limit
	_layout()


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
	cloth.set_meta(&"cloth", rect)
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
	_build_shop()
	_build_update()
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
	# Low enough that the pocket's stitched top edge passes above it, not through it.
	var eyebrow: Label = _label(home_page, Vector2(136, 144), Vector2(850, 55), 31, ACCENT, true)
	eyebrow.text = "A STITCHED SHIFT ADVENTURE"
	var title: Label = _label(home_page, Vector2(128, 172), Vector2(870, 158), 105, INK, true)
	title.add_theme_font_override("font", FONT_DISPLAY)
	title.text = "STITCHFALL"
	var line: Label = _label(home_page, Vector2(138, 306), Vector2(840, 84), 36, INK)
	line.text = "Find the buttons. Turn the pull.\nOpen the seam."
	var menu_items: Array[Array] = [
		["PLAY", "play", Color("e0a278"), _begin_from_home],
		["LEVELS", "levels", Color("dbe5d1"), show_levels],
		["WARDROBE", "wardrobe", Color("efd3b8"), show_wardrobe],
		["GUIDE", "help", Color("e8d8bd"), show_help],
		["SETTINGS", "settings", Color("e4d0b1"), show_settings],
	]
	# Google Play's build sells packs and takes tips. The browser build has no shop.
	if StitchfallShop.on_play:
		menu_items.insert(3, ["SHOP", "bag", Color("f0c9a8"), show_shop])
	# Six rows (with the shop) sit a little closer, so the last stays inside the pocket.
	var row_step: float = 84.0 if menu_items.size() > 5 else 88.0
	for index: int in range(menu_items.size()):
		var item: Array = menu_items[index]
		var button: StitchedButton = _tag(home_page, Rect2(146, 428 + index * row_step, 560, row_step - 6.0), item[0], item[1], item[2])
		button.home_link = true
		var open: Callable = item[3]
		button.pressed.connect(func() -> void: open.call())
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
	# The wide card's corner knot sits at x 160 to 240, so a heading starts clear of it.
	level_heading = _label(level_page, Vector2(255, 100), Vector2(1200, 105), 77, INK, true)
	level_heading.add_theme_font_override("font", FONT_DISPLAY)
	level_tally = _label(level_page, Vector2(261, 200), Vector2(1100, 60), 36, ACCENT)
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
		button.locked = progress != null and not StitchfallShop.room_open(progress, index)
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
	# The browser build can point to GitHub Sponsors. The Android build never may, by Play's Payments policy, and
	# has Rate there instead, which opens the Play page: no button may call Play's own review card.
	if not StitchfallShop.on_play:
		links.append(["SPONSOR", "gift", StitchfallShop.SPONSOR])
	else:
		links.append(["RATE", "star", StitchfallShop.STORE])
	for index: int in range(links.size()):
		var link: Array = links[index]
		var tag: StitchedButton = _tag(about_page, Rect2(300 + index * 172, 665, 162, 195), link[0], link[1], [Color("dbe5d1"), Color("e8d8bd"), Color("e4d0b1"), Color("efd3b8"), Color("e0a278")][index])
		tag.pause_action = true
		tag.caption_size = 26
		var url: String = link[2]
		if url == StitchfallShop.STORE:
			tag.pressed.connect(func() -> void: StitchfallPlayCore.rate(progress))
		else:
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
	# Google's consent service says when a player must be able to change their ad consent, and then this takes
	# the place a phone has no Fullscreen for.
	var privacy: StitchedButton = _tag(settings_page, Rect2(420 + 3 * 275, 250, 255, 270), "PRIVACY", "lock", Color("e4d0b1"))
	privacy.pause_action = true
	privacy.pressed.connect(func() -> void: StitchfallAds.open_privacy_options())
	privacy.visible = false
	settings_tags["privacy"] = privacy
	var note: Label = _label(settings_page, Vector2(480, 845), Vector2(960, 50), 28, ACCENT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.text = "M changes sound. F goes fullscreen."
	# A phone has no keys to name, and this way its banner needs less room.
	note.visible = not OS.has_feature("android")


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
	settings_tags["privacy"].visible = StitchfallAds.privacy_options_required()
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
	# Offered only after the runner keeps coming apart in one room. Resume and Retry stay beside it, so passing it
	# by costs nothing.
	skip_button = _tag(pause_page, Rect2(705, 742, 510, 84), "SKIP THIS ROOM", "next", Color("efd3b8"))
	skip_button.caption_size = 34
	skip_button.pressed.connect(func() -> void: skip_pressed.emit())
	skip_button.visible = false


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
	# Google Play Games' own pages, beside the stitches they count, in the Android build once Stitchfall has its Play
	# Games project. Each signs the player in first when they are not yet. Both end above the lines' foot, so the
	# page shrinks no further for the banner.
	stats_boards = _tag(stats_page, Rect2(1150, 285, 290, 280), "LEADERBOARDS", "stats", Color("efd3b8"))
	stats_boards.pause_action = true
	# Twelve letters in the usual hand would run past the patch's width and lose their last.
	stats_boards.caption_size = 28
	stats_boards.pressed.connect(func() -> void: StitchfallPlayGames.show_boards())
	stats_achievements = _tag(stats_page, Rect2(1150, 585, 290, 280), "ACHIEVEMENTS", "star", Color("dbe5d1"))
	stats_achievements.pause_action = true
	stats_achievements.caption_size = 28
	stats_achievements.pressed.connect(func() -> void: StitchfallPlayGames.show_achievements())


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
	if not progress.skipped.is_empty():
		rows.insert(1, "Rooms skipped:  %d" % progress.skipped.size())
	stats_lines.text = "\n".join(rows)
	var games: bool = StitchfallPlayGames.ready()
	stats_boards.visible = games
	stats_achievements.visible = games
	stats_lines.size.x = 620.0 if games else 920.0
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
	if StitchfallShop.on_play and not StitchfallPlayGames.app_id().is_empty():
		body.text += "\n\n" + "In the Android app: the Godot AdMob Plugin by Poing Studios, Godot Google Play Billing by the Godot Engine contributors, Godotx Firebase by Paulo Coutinho and GodotPlayGameServices by Jacob Ibáñez Sánchez, each under the MIT license, and Google's Mobile Ads SDK, User Messaging Platform, Play Billing Library, Play In-App Review and Updates, Play Games Services and Analytics for Firebase, under Google's terms."
	elif StitchfallShop.on_play:
		body.text += "\n\n" + "In the Android app: the Godot AdMob Plugin by Poing Studios, Godot Google Play Billing by the Godot Engine contributors and Godotx Firebase by Paulo Coutinho, each under the MIT license, and Google's Mobile Ads SDK, User Messaging Platform, Play Billing Library, Play In-App Review and Updates and Analytics for Firebase, under Google's terms."


# The wardrobe: a dancing preview on the left, a tab per kind of piece, and the pieces as tiles.
func _build_wardrobe() -> void:
	wardrobe_page = _page()
	_cloth_page(wardrobe_page, Rect2(65, 50, 1790, 970))
	var heading: Label = _label(wardrobe_page, Vector2(255, 95), Vector2(700, 105), 77, INK, true)
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
	wardrobe_buy.pressed.connect(func() -> void: _say(StitchfallShop.buy(StitchfallMonetize.WARDROBE_ID)))
	wardrobe_shop = _tag(wardrobe_page, Rect2(1600, 832, 90, 86), "", "bag", Color("efd3b8"))
	wardrobe_shop.tooltip_text = "Shop"
	wardrobe_shop.pressed.connect(func() -> void: show_shop("wardrobe"))


# The Shop, Google Play's build only: the packs as felt cards with Play's prices, the tip jar and Restore.
func _build_shop() -> void:
	shop_page = _page()
	_cloth_page(shop_page, Rect2(65, 50, 1790, 970))
	var heading: Label = _label(shop_page, Vector2(255, 95), Vector2(700, 105), 77, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "SHOP"
	_tag(shop_page, Rect2(1700, 100, 100, 101), "", "back", Color("e5d5bc")).pressed.connect(leave_shop)
	shop_line = _label(shop_page, Vector2(261, 196), Vector2(1400, 52), 31, ACCENT)
	var cloths: Array[Color] = [Color("e0a278"), Color("efd3b8"), Color("dbe5d1"), Color("e8d8bd")]
	var ids: PackedStringArray = StitchfallShop.one_time_ids()
	for index: int in range(ids.size()):
		var id: String = ids[index]
		var card: StitchedButton = _tag(shop_page, Rect2(0, 258, 400, 470), StitchfallShop.card_title(id), StitchfallShop.glyph(id), cloths[index])
		card.shop_card = true
		card.lines = StitchfallShop.rows(id)
		card.tooltip_text = ""
		card.pressed.connect(_buy_pack.bind(id))
		shop_cards[id] = card
	var jar: Label = _label(shop_page, Vector2(176, 742), Vector2(1250, 50), 30, INK, true)
	jar.text = "Tip jar. Say thanks as often as you like. A tip opens nothing new."
	for index: int in range(StitchfallMonetize.TIP_IDS.size()):
		var tip_id: String = StitchfallMonetize.TIP_IDS[index]
		var tip: StitchedButton = _tag(shop_page, Rect2(170 + index * 212, 800, 200, 82), "TIP", "", Color("e8d8bd"))
		tip.pressed.connect(func() -> void: _say(StitchfallShop.buy(tip_id)))
		shop_tips.append(tip)
	var again: StitchedButton = _tag(shop_page, Rect2(1460, 800, 290, 82), "RESTORE", "restart", Color("dbe5d1"))
	again.caption_size = 30
	again.pressed.connect(func() -> void: _say(StitchfallShop.restore()))
	shop_note = _label(shop_page, Vector2(176, 900), Vector2(1560, 56), 28, ACCENT)


func show_shop(from: String = "home") -> void:
	shop_return = from
	_fill_shop()
	shop_note.text = "Thank you for your %s." % ("tip" if progress.tips == 1 else "%d tips" % progress.tips) if progress.tips > 0 else ""
	_show_screen("shop")
	StitchfallAnalytics.event(&"shop_open", {"from": from})


func leave_shop() -> void:
	if shop_return == "wardrobe":
		show_wardrobe()
	else:
		show_home()


# The Complete pack shows only while none of it is owned, or once it is, and the cards centre on the cloth.
func _fill_shop() -> void:
	shop_line.text = "You are a Supporter. Thank you for helping me make the next game." if StitchfallShop.ads_off(progress) else "Every room opens by playing. These help me make the next game."
	var shown: Array[StitchedButton] = []
	for id: String in shop_cards:
		var card: StitchedButton = shop_cards[id]
		card.visible = id != StitchfallMonetize.COMPLETE_ID or StitchfallShop.offers_complete(progress) or StitchfallShop.owns(progress, id)
		card.owned = StitchfallShop.has(progress, id)
		card.price_tag = StitchfallShop.price(id)
		card.queue_redraw()
		if card.visible:
			shown.append(card)
	var left: float = (1920.0 - shown.size() * 400.0 - (shown.size() - 1) * 22.0) * 0.5
	for index: int in range(shown.size()):
		shown[index].position.x = left + index * 422.0
	for index: int in range(shop_tips.size()):
		var price: String = StitchfallShop.price(StitchfallMonetize.TIP_IDS[index])
		shop_tips[index].caption = "TIP" if price.is_empty() else price
		shop_tips[index].caption_size = 30 if price.length() <= 9 else 22
		shop_tips[index].queue_redraw()


func _buy_pack(id: String) -> void:
	if StitchfallShop.has(progress, id):
		_say("%s is yours. Thank you!" % StitchfallShop.title(id))
		return
	_say(StitchfallShop.buy(id))


# Offered once a session when Google Play has downloaded an update, on Home or the Levels page.
func _build_update() -> void:
	update_page = _page()
	_cloth_page(update_page, Rect2(500, 165, 920, 700))
	var heading: Label = _label(update_page, Vector2(560, 235), Vector2(800, 110), 60, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.text = "AN UPDATE IS READY"
	var body: Label = _label(update_page, Vector2(600, 350), Vector2(720, 110), 32, INK)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "Restart Stitchfall to finish updating. Your rooms and stars stay as they are."
	var restart: StitchedButton = _tag(update_page, Rect2(680, 500, 270, 290), "RESTART", "restart", Color("e0a278"))
	restart.pause_action = true
	restart.pressed.connect(func() -> void:
		StitchfallPlayCore.restart_into_update()
		leave_update())
	var later: StitchedButton = _tag(update_page, Rect2(990, 520, 230, 255), "LATER", "back", Color("e8d8bd"))
	later.pause_action = true
	later.pressed.connect(leave_update)


func show_update() -> void:
	update_return = screen
	_show_screen("update")
	StitchfallAnalytics.event(&"update_offer")


func leave_update() -> void:
	if update_return == "levels":
		show_levels()
	else:
		show_home()


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
	wardrobe_shop.visible = on_play
	var price: String = StitchfallShop.price(StitchfallMonetize.WARDROBE_ID)
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


# A line from the page or from Google Play, on the page it belongs to.
func _say(text: String) -> void:
	if text.is_empty():
		return
	if screen == "shop":
		shop_note.text = text
	elif screen == "pause":
		pause_body.text = text
	else:
		wardrobe_note.text = text


# Google Play's answers (prices, a purchase, a refund) redraw the page that shows them, keeping its note.
func refresh_store() -> void:
	match screen:
		"wardrobe":
			var note: String = wardrobe_note.text
			_show_kind(wardrobe_kind)
			wardrobe_note.text = note
		"shop":
			_fill_shop()
		"levels":
			_set_level_page(level_page_index)


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
	panel.color = Color("3c342f", 0.52) if name in ["pause", "finish", "clear", "chapter", "update"] else Color("f5ead5", 0.89)
	clear_page.visible = name == "clear"
	if name != "clear":
		clear_hero.stop()
	fabric.visible = name in ["levels", "help", "about", "settings", "stats", "credits", "wardrobe", "shop"]
	shop_page.visible = name == "shop"
	update_page.visible = name == "update"
	StitchfallAds.want_banner(name in StitchfallAds.BANNER_SCREENS)
	if name in ["home", "levels", "wardrobe", "shop", "help", "settings", "about", "credits", "stats"]:
		StitchfallAnalytics.screen(name)
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


# `skip_line` offers to skip the room, saying what it costs, or is empty when no skip is offered.
func show_pause(skip_line: String = "") -> void:
	pause_heading.text = "PAUSED"
	pause_heading.add_theme_font_size_override("font_size", 74)
	_offer_skip(skip_line)
	resume_button.caption = "RESUME"
	resume_button.position.x = 850
	resume_button.queue_redraw()
	restart_button.visible = true
	pause_home_button.position.x = 1120
	_show_screen("pause")
	resume_button.grab_focus()


# With a skip on offer, the three actions rise to make room for it under them.
func _offer_skip(skip_line: String) -> void:
	var offered: bool = not skip_line.is_empty()
	var rise: float = 60.0 if offered else 0.0
	pause_body.text = skip_line
	pause_body.position.y = 338.0 if offered else 355.0
	pause_body.size.y = 70.0 if offered else 95.0
	restart_button.position.y = 500.0 - rise
	resume_button.position.y = 472.0 - rise
	pause_home_button.position.y = 500.0 - rise
	skip_button.visible = offered


func show_finish(time_text: String, shift_count: int, hit_count: int) -> void:
	pause_heading.text = "THE SEAM HOLDS"
	pause_heading.add_theme_font_size_override("font_size", 51)
	_offer_skip("")
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
	StitchfallAds.want_banner(false)
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


# The room's name, in a slim strip that leaves quickly, since the room's ceiling sits right under it.
func set_room_intro(title: String) -> void:
	if intro_tween and intro_tween.is_running():
		intro_tween.kill()
	hint_title.text = title
	hint_back.visible = true
	hint_back.modulate.a = 1.0
	intro_tween = create_tween()
	intro_tween.tween_interval(1.4)
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
