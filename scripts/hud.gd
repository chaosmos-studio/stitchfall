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
# The HUD's corner of the screen changed, so the room is fitted again.
signal play_frame_changed
# The guide's Practice: the first room again, with its lessons.
signal practice_pressed

const INK: Color = Color("493a37")
const PAPER: Color = Color("f7edda")
const ACCENT: Color = Color("a85648")
const FONT_REGULAR: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const FONT_BOLD: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")
const FONT_DISPLAY: FontFile = preload("res://assets/fonts/Darn-Display.ttf")
const HOME_SCENE: Texture2D = preload("res://assets/art/home_woodland.webp")
const LOGO: Texture2D = preload("res://assets/art/logo_label.png")
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
# How long a toast (a line from Google Play on a page with no line of its own) stays before it fades.
const TOAST_SECONDS: float = 3.5
# Once a skip is on offer, the pause button carries this tag so a stuck player knows where the way out is.
const SKIP_HINT: String = "Stuck? Pause"
# The pause button's side, in view pixels: a thumb's width on a phone, smaller under a mouse.
const CHIP_TOUCH: float = 120.0
const CHIP_MOUSE: float = 100.0
# The gap between the HUD and the screen's edge, and between the HUD and the room.
const HUD_EDGE: float = 14.0
const HUD_GAP: float = 8.0
# How much larger the meter and its tags are drawn on a touch screen.
const TOUCH_SCALE: float = 1.2
# Home's pocket, in design pixels: the logo, the Play patch, and the row of tiles under it. The whole menu stays
# inside the part of the painted pocket a 16:9 and a 20:9 screen both show, and ends a banner's clearance above
# where the banner stands.
const HOME_LOGO: Rect2 = Rect2(20, 110, 600, 0)
const HOME_PLAY: Rect2 = Rect2(0, 270, 640, 186)
# The felt patches under Play (Levels, Wardrobe and Shop): how far down, their size, the gap between them and
# their cloth. Shravan chose icons alone over rows of words on 10 November 2026.
const HOME_PATCHES_Y: float = 490.0
const HOME_PATCH: float = 120.0
const HOME_PATCH_GAP: float = 36.0
const HOME_PATCH_CLOTH: Color = Color("ecdfc6")
# Each pack's one line in the Shop.
const SHOP_LINES: Dictionary[String, String] = {
	"complete": "All three, for less",
	"supporter": "No ads, free skips",
	"all_levels": "Every room, open now",
	"wardrobe": "Every runner and fabric",
}
# The Wardrobe fills the screen's safe part, above the banner while one is due, instead of shrinking a fixed page,
# so a wide phone's width goes to bigger pieces. Three columns: the heading over the kinds, the pieces, and the
# runner dancing over the Wardrobe pack's price. In view pixels: the cloth's margin from the screen's edge, how
# large its painted border is drawn, how far in from the cloth's edge the parts start, and the gap between them.
const WARDROBE_MARGIN: float = 16.0
const WARDROBE_CLOTH_SCALE: float = 0.6
const WARDROBE_CLOTH_EDGE: int = 190
const WARDROBE_INSET: Vector2 = Vector2(80, 62)
const WARDROBE_GAP: float = 24.0
# The kinds' column and the dancer's column, as shares of the cloth's inside, and their narrowest and widest.
const WARDROBE_KINDS: Vector3 = Vector3(0.18, 290.0, 400.0)
const WARDROBE_DANCER: Vector3 = Vector3(0.23, 300.0, 440.0)
# A piece's tile is never larger than this, and a kind has at most this many pieces.
const WARDROBE_TILE_LARGEST: float = 340.0
const WARDROBE_SLOTS: int = 8
# The heights of the heading's row, of a kind's tab at most, of the corner buttons and of the pack's price card.
const WARDROBE_HEAD: float = 96.0
const WARDROBE_TAB: float = 108.0
const WARDROBE_CORNER: float = 100.0
const WARDROBE_PACK: float = 190.0
# The Levels page's five room patches, from this x, one every step, and how far a sideways swipe must travel to
# turn the page.
const LEVEL_TILES_X: float = 222.0
const LEVEL_TILES_Y: float = 296.0
const LEVEL_TILE_HEIGHT: float = 360.0
const LEVEL_TILE_STEP: float = 302.0
const LEVEL_SWIPE: float = 110.0
# Settings' two columns of rows.
const SETTINGS_X: Array[float] = [350.0, 990.0]
const SETTINGS_Y: float = 262.0
const SETTINGS_STEP: float = 142.0
const SETTINGS_ROW: Vector2 = Vector2(580, 128)
# The painted pocket in the home painting's own pixels, which the menu centres in however the painting is cropped.
const HOME_POCKET: Rect2 = Rect2(20, 80, 780, 760)
# How much of the pocket's height the menu fills, the most it grows past its design size, and the least it keeps
# from the screen's top and foot.
const HOME_MENU_SHARE: float = 0.74
const HOME_MENU_LARGEST: float = 1.25
const HOME_MARGIN: float = 24.0
# Where the dancing runner stands across Home, as a share of the width. Home's banner stands under it.
const HOME_HERO_X: float = 0.735

var root: Control
var meter: ButtonMeter
var pause_button: StitchedButton
var hint_back: Panel
var hint_title: Label
var panel: ColorRect
var fabric: TextureRect
var home_page: Control
var home_menu: Control
# Where Home's last row ends, in the menu's own space, which depends on whether the Shop is there.
var home_menu_bottom: float = HOME_PLAY.end.y
var home_play: StitchedButton
var level_page: Control
var level_buttons: Array[StitchedButton] = []
var level_page_index: int = 0
var level_previous: StitchedButton
var level_next: StitchedButton
var level_heading: Label
var level_kicker: Label
var level_line: Label
var level_rooms: Control
var level_dots: StitchfallPageDots
var level_badge: TextureRect
var chapter_badge: TextureRect
var level_swipe_from: Vector2 = Vector2.INF
var level_tally: Label
var level_note: Label
var level_unlock: StitchedButton
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
var swipe_thread: StitchfallSwipeThread
var unravel_tag: Panel
var skip_hint: Panel
var skip_hint_label: Label
var skip_hint_tween: Tween
var coach: StitchfallCoach
var coach_holder: Control
var skip_ready: bool = false
var toast: Panel
var toast_label: Label
var toast_tween: Tween
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
var wardrobe_cloth: NinePatchRect
var wardrobe_heading: Label
var wardrobe_home: StitchedButton
var wardrobe_stars: StitchedButton
var wardrobe_buy: StitchedButton
var wardrobe_shop: StitchedButton
var shop_page: Control
var shop_line: Label
var shop_cards: Dictionary[String, StitchedButton] = {}
var shop_tips: Array[StitchedButton] = []
var shop_note: Label
# The page Back leads to from the Shop and from the update offer.
var shop_return: String = "home"
# The page before a purchase: which product, and the page it was opened from.
var offer_page: Control
var offer_id: String = ""
var offer_return: String = "shop"
var offer_patch: StitchedButton
var offer_badge: Panel
var offer_badge_label: Label
var offer_heading: Label
var offer_pitch: Label
var offer_rows: Array[Label] = []
var offer_dots: Array[ColorRect] = []
var offer_buy: StitchedButton
var offer_shop: StitchedButton
var offer_note: Label
var update_page: Control
var update_return: String = "home"
var skip_button: StitchedButton
var finish_shop: StitchedButton
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
# What the HUD keeps clear around the room (left, top, right, bottom, in view pixels), and whether it sits in two
# side rails (a wide phone, where the room is limited by its height) or a strip along the top.
var play_reserve: Vector4 = Vector4(HUD_GAP, 140.0, HUD_GAP, HUD_GAP)
var play_rails: bool = false
# The capture tool sets this to draw the HUD as a phone shows it.
static var touch_preview: bool = false


static func touch() -> bool:
	return touch_preview or DisplayServer.is_touchscreen_available()


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
	# Beside the pause button, only once a skip is on offer in this room. It is a hint, not a button: the pause
	# button stays the one way in, so it is never tapped by accident mid-jump.
	skip_hint = _panel(root, Rect2(0, 0, 252, 58), Color("f5e8d1", 0.94))
	skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_hint_label = _label(skip_hint, Vector2(8, 2), Vector2(236, 52), 30, ACCENT, true)
	skip_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_hint_label.text = SKIP_HINT
	skip_hint.visible = false
	# The thread a sliding finger draws, over the room and under the coach and the pages.
	swipe_thread = StitchfallSwipeThread.new()
	root.add_child(swipe_thread)
	swipe_thread.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	swipe_thread.visible = progress == null or progress.thread
	# The first room's coach, over the room and under every page, which hides it while open.
	coach_holder = Control.new()
	coach_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(coach_holder)
	coach = StitchfallCoach.new()
	coach_holder.add_child(coach)
	_build_pages()
	# Over every page, so Google Play's answers are seen wherever they arrive.
	toast = _panel(root, Rect2(0, 36, 1040, 96), Color("f5e8d1", 0.97))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label = _label(toast, Vector2(24, 6), Vector2(992, 84), 30, INK, true)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.visible = false
	StitchfallAds.listen(_on_banner_limit)
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")


func _layout() -> void:
	_layout_play()
	toast.position.x = (root.size.x - toast.size.x) * 0.5
	hero.position.x = root.size.x * HOME_HERO_X
	var safe: Vector4 = _safe_insets()
	_layout_home(safe)
	for page: Control in [level_page, help_page, about_page, settings_page, pause_page, clear_page, chapter_page, stats_page, credits_page, shop_page, offer_page, update_page]:
		var fit: float = page_fit(page)
		page.scale = Vector2.ONE * fit
		page.position.x = (root.size.x - 1920.0 * fit) * 0.5
		_trim_cloth(page, fit)
	_layout_wardrobe(safe)


# Home's menu is sized to the painted pocket as the painting covers the screen (wider screens crop its top and
# foot), HOME_MENU_SHARE of its height, and centred in it, inside the screen's safe part. Home's banner stands
# under the dancer, beside the menu, so the menu keeps the pocket's whole height. Only when a narrow screen puts
# the banner under the menu too does the menu end a banner's clearance above it.
func _layout_home(safe: Vector4) -> void:
	var art: Vector2 = HOME_SCENE.get_size()
	var cover: float = maxf(root.size.x / art.x, root.size.y / art.y)
	var origin: Vector2 = (root.size - art * cover) * 0.5
	var pocket: Rect2 = Rect2(origin + HOME_POCKET.position * cover, HOME_POCKET.size * cover)
	var top: float = maxf(pocket.position.y, safe.y + HOME_MARGIN)
	var bottom: float = minf(pocket.end.y, root.size.y - safe.w - HOME_MARGIN)
	var menu: Vector2 = Vector2(HOME_PLAY.size.x, home_menu_bottom - HOME_LOGO.position.y)
	var fit: float = clampf(minf((bottom - top) * HOME_MENU_SHARE / menu.y, pocket.size.x * 0.84 / menu.x), 0.6, HOME_MENU_LARGEST)
	var left: float = maxf(safe.x + 40.0, pocket.get_center().x - menu.x * 0.5 * fit)
	if StitchfallAds.banner_wanted() and StitchfallAds.banner_rect(HOME_HERO_X).position.x < left + menu.x * fit:
		bottom = minf(bottom, banner_limit)
		fit = minf(fit, clampf((bottom - top) / menu.y, 0.6, 1.0))
	home_menu.scale = Vector2.ONE * fit
	home_menu.position = Vector2(left, (top + bottom - menu.y * fit) * 0.5 - HOME_LOGO.position.y * fit)


# The HUD around a room. On a wide phone the room is limited by the screen's height, so the meter and the pause
# button stand in rails at its sides and the room fills the height. Otherwise they sit in a strip along the top.
# Whichever lets the room be drawn larger wins, and the room is fitted again.
func _layout_play() -> void:
	var chip: float = CHIP_TOUCH if touch() else CHIP_MOUSE
	var grow: float = TOUCH_SCALE if touch() else 1.0
	var safe: Vector4 = _safe_insets()
	var view: Vector2 = root.size
	var rail: float = HUD_EDGE + chip + HUD_GAP
	# One rail, on the right: the room keeps only a slim edge on the left, rather than a column of empty cloth.
	var rails: Vector4 = Vector4(safe.x + HUD_GAP, safe.y + HUD_GAP, safe.z + rail, safe.w + HUD_GAP)
	var band: Vector4 = Vector4(safe.x + HUD_GAP, safe.y + HUD_EDGE + chip + HUD_GAP * 0.5, safe.z + HUD_GAP, safe.w + HUD_GAP)
	var before: Vector4 = play_reserve
	play_rails = StitchfallLevels.fit_zoom(view, rails) > StitchfallLevels.fit_zoom(view, band) + 0.01
	play_reserve = rails if play_rails else band
	var left: float = safe.x + HUD_EDGE
	var top: float = safe.y + HUD_EDGE
	pause_button.size = Vector2.ONE * chip
	pause_button.position = Vector2(view.x - safe.z - HUD_EDGE - chip, top)
	meter.vertical = play_rails
	meter.scale = Vector2.ONE * grow
	unravel_tag.scale = Vector2.ONE * grow
	skip_hint.scale = Vector2.ONE * grow
	if play_rails:
		# The rail is one column under the pause button: the meter standing up, the unravel count, then the skip's
		# hint when there is one.
		var column: float = pause_button.position.x
		var below: float = top + chip + 14.0
		meter.size = Vector2(79, 205)
		meter.position = Vector2(column + (chip - 79.0 * grow) * 0.5, below)
		unravel_tag.size = Vector2(chip / grow, 58)
		unravel_tag.position = Vector2(column, below + 205.0 * grow + 12.0)
		skip_hint.size = Vector2(chip / grow, 92)
		skip_hint_label.size = Vector2(chip / grow - 16.0, 88)
		skip_hint_label.text = SKIP_HINT.replace(" ", "\n")
		skip_hint.position = Vector2(column, below + 205.0 * grow + 12.0 + 58.0 * grow + 12.0)
		room_label.position = Vector2((view.x - room_label.size.x) * 0.5, safe.y - 4.0)
		room_label.add_theme_font_size_override("font_size", 28)
		hint_back.position = Vector2((view.x - hint_back.size.x) * 0.5, safe.y + 54.0)
	else:
		meter.size = Vector2(205, 79)
		meter.position = Vector2(left, top + (chip - 79.0 * grow) * 0.5)
		unravel_tag.size = Vector2(150, 58)
		unravel_tag.position = Vector2(meter.position.x + 205.0 * grow + 14.0, top + (chip - 58.0 * grow) * 0.5)
		skip_hint.size = Vector2(252, 58)
		skip_hint_label.size = Vector2(236, 52)
		skip_hint_label.text = SKIP_HINT
		skip_hint.position = Vector2(pause_button.position.x - (252.0 * grow + 14.0), top + (chip - 58.0 * grow) * 0.5)
		room_label.position = Vector2((view.x - room_label.size.x) * 0.5, top + (chip - room_label.size.y) * 0.5)
		room_label.add_theme_font_size_override("font_size", 28)
		hint_back.position = Vector2((view.x - hint_back.size.x) * 0.5, play_reserve.y + 10.0)
	unravel_tag.pivot_offset = unravel_tag.size * 0.5
	unravel_label.size = Vector2(unravel_tag.size.x - 20.0, 52)
	# Over the room's empty top, under the room's name as it comes and goes.
	coach.position = Vector2((view.x - coach.size.x) * 0.5, play_reserve.y + 96.0)
	if play_reserve != before:
		play_frame_changed.emit()


# The screen's cutouts (a notch or a camera hole) as insets in view pixels. Only on a phone: a computer's safe area
# is its desktop, not the game's window.
func _safe_insets() -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	if window.x <= 0.0 or window.y <= 0.0 or safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return Vector4.ZERO
	var per: Vector2 = root.size / window
	return Vector4(safe.position.x * per.x, safe.position.y * per.y,
		maxf(window.x - safe.end.x, 0.0) * per.x, maxf(window.y - safe.end.y, 0.0) * per.y)


# The pages that may carry the banner: every page but play itself, Settings and About (where consent and privacy
# live), the Shop and its offers, a chapter's short title card and the update offer.
func _banner_page(page: Control) -> bool:
	return [level_page, wardrobe_page, credits_page, stats_page, help_page, pause_page, clear_page].has(page)


# A menu page that carries the banner shrinks from its top until everything on it ends BUTTON_GAP_DP above the
# banner, so no button sits near the ad. Every other page, and every page without a banner, keeps its size.
func page_fit(page: Control) -> float:
	# The Wardrobe lays itself out in the room it has (_layout_wardrobe), so it never shrinks.
	if not _banner_page(page) or page == wardrobe_page:
		return 1.0
	var bottom: float = 0.0
	# The clear card slides in as one piece, so its parts are measured inside it.
	var holder: Control = clear_card if page == clear_page else page
	for child: Node in holder.get_children():
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
	var holder: Control = clear_card if page == clear_page else page
	for child: Node in holder.get_children():
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
	_build_offer()
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
	# Everything in the pocket hangs from one menu, so it can shrink as a whole above a banner on a short phone.
	home_menu = Control.new()
	home_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_page.add_child(home_menu)
	# The logo's felt label, low enough that the pocket's stitched top edge passes above it, not through it.
	var title: TextureRect = TextureRect.new()
	title.texture = LOGO
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.position = HOME_LOGO.position
	title.size = Vector2(HOME_LOGO.size.x, HOME_LOGO.size.x * LOGO.get_height() / LOGO.get_width())
	home_menu.add_child(title)
	# One thing to do here: play. It names the room it picks up from, so a returning player knows where they are.
	home_play = _tag(home_menu, HOME_PLAY, "PLAY", "play", Color("e0a278"))
	home_play.caption_size = 72
	home_play.pressed.connect(_begin_from_home)
	# Under it, the other places as felt patches in a row, the icon alone, so Play is the only thing to read. One
	# linen for all of them, so only Play stands out. A computer names each one on hover.
	var places: Array[Array] = [
		["Levels", "levels", show_levels],
		["Wardrobe", "wardrobe", show_wardrobe],
	]
	# Google Play's build sells packs and takes tips. The browser build has no shop.
	if StitchfallShop.on_play:
		places.append(["Shop", "bag", show_shop])
	# Settings last, in the row where it is seen, not in a corner.
	places.append(["Settings", "settings", show_settings])
	var across: float = float(places.size()) * HOME_PATCH + float(places.size() - 1) * HOME_PATCH_GAP
	for index: int in range(places.size()):
		var place: Array = places[index]
		var spot: Rect2 = Rect2(HOME_PLAY.get_center().x - across * 0.5 + float(index) * (HOME_PATCH + HOME_PATCH_GAP), HOME_PATCHES_Y, HOME_PATCH, HOME_PATCH)
		var patch: StitchedButton = _tag(home_menu, spot, "", place[1], HOME_PATCH_CLOTH)
		patch.tooltip_text = place[0]
		var go: Callable = place[2]
		patch.pressed.connect(func() -> void: go.call())
		home_menu_bottom = spot.end.y
	hero = AnimatedSprite2D.new()
	hero.sprite_frames = _dance_frames()
	hero.scale = Vector2.ONE * 0.92
	# High enough that Home's banner, under it, keeps clear of its feet.
	hero.position = Vector2(1410, 524)
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


# One chapter a page. The header names it, with its line and its stars so far. Its five rooms are big patches, the
# next one to play ringed, and the chapter turns with the arrows at the card's edges or a swipe across the page.
func _build_levels() -> void:
	level_page = _page()
	_cloth_page(level_page, Rect2(60, 34, 1800, 820))
	# The card's scalloped edge runs about 80 px deep, so the header starts inside it.
	_tag(level_page, Rect2(150, 122, 104, 104), "", "back", Color("e5d5bc")).pressed.connect(show_home)
	level_kicker = _label(level_page, Vector2(284, 112), Vector2(900, 36), 28, ACCENT, true)
	level_heading = _label(level_page, Vector2(278, 140), Vector2(1000, 92), 74, INK, true)
	level_heading.add_theme_font_override("font", FONT_DISPLAY)
	level_line = _label(level_page, Vector2(284, 228), Vector2(1000, 44), 31, Color(INK, 0.8))
	# The chapter's stars, at the right of the header, level with its name.
	level_tally = _label(level_page, Vector2(1250, 150), Vector2(470, 70), 40, ACCENT, true)
	level_tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# The chapter's embroidered patch beside its name, once the art is in.
	level_badge = TextureRect.new()
	level_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	level_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_badge.position = Vector2(272, 98)
	level_badge.size = Vector2(170, 170)
	level_page.add_child(level_badge)
	level_previous = _tag(level_page, Rect2(78, 410, 112, 112), "", "back", Color("e5d5bc"))
	level_previous.pressed.connect(func() -> void: _turn_level_page(-1))
	level_next = _tag(level_page, Rect2(1730, 410, 112, 112), "", "next", Color("e5d5bc"))
	level_next.pressed.connect(func() -> void: _turn_level_page(1))
	# The rooms ride in one holder so a page turn slides them together. It is as tall as the rooms, since the page
	# shrinks above a banner by how far down its parts reach.
	level_rooms = Control.new()
	level_rooms.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_rooms.size = Vector2(1920, LEVEL_TILES_Y + LEVEL_TILE_HEIGHT)
	level_page.add_child(level_rooms)
	for slot: int in range(StitchfallLevels.CHAPTER_ROOMS):
		var button: StitchedButton = _tag(level_rooms, Rect2(LEVEL_TILES_X + slot * LEVEL_TILE_STEP, LEVEL_TILES_Y, LEVEL_TILE_STEP - 26.0, LEVEL_TILE_HEIGHT), "", "seam", Color("f1e1c8"))
		button.level_tile = true
		button.pressed.connect(_select_visible_level.bind(slot))
		level_buttons.append(button)
	level_dots = StitchfallPageDots.new()
	level_dots.position = Vector2(560, LEVEL_TILES_Y + LEVEL_TILE_HEIGHT + 14.0)
	level_dots.size = Vector2(800, 40)
	level_page.add_child(level_dots)
	# A shut room says what opens it when tapped: sewing the room before it, or in Google Play's build, Every room.
	level_note = _label(level_page, Vector2(230, 718), Vector2(1000, 60), 32, INK)
	level_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_unlock = _tag(level_page, Rect2(1250, 704, 470, 86), "EVERY ROOM", "levels", Color("dbe5d1"))
	level_unlock.caption_size = 30
	level_unlock.pressed.connect(func() -> void: show_offer(StitchfallMonetize.LEVELS_ID, "levels"))
	level_note.visible = false
	level_unlock.visible = false
	_set_level_page(0)


# A swipe across the Levels page turns it, the way the arrows do, as long as it is mostly sideways. It is read
# before the buttons see the touch, since most of the page is room patches, and a turn cancels the patch's press,
# or lifting the finger would open the new chapter's room under it.
func _input(event: InputEvent) -> void:
	if screen != "levels":
		return
	var press: InputEventScreenTouch = event as InputEventScreenTouch
	if press != null:
		level_swipe_from = press.position if press.pressed else Vector2.INF
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag == null or level_swipe_from == Vector2.INF:
		return
	var travel: Vector2 = drag.position - level_swipe_from
	if absf(travel.x) > LEVEL_SWIPE and absf(travel.x) > absf(travel.y) * 1.5:
		level_swipe_from = Vector2.INF
		for button: StitchedButton in level_buttons:
			button.disabled = true
		_turn_level_page(-1 if travel.x > 0.0 else 1)
		get_tree().create_timer(0.2).timeout.connect(func() -> void:
			for button: StitchedButton in level_buttons:
				button.disabled = false)


# One page is one chapter, with its name, its line, its stars so far, and its five rooms.
func _set_level_page(value: int) -> void:
	var from: int = level_page_index
	level_page_index = clampi(value, 0, StitchfallLevels.chapter_count() - 1)
	level_previous.visible = level_page_index > 0
	level_next.visible = level_page_index + 1 < StitchfallLevels.chapter_count()
	level_kicker.text = "CHAPTER %d" % (level_page_index + 1)
	level_heading.text = StitchfallLevels.chapter_name(level_page_index).to_upper()
	# The chapter's line is said on its title card. Here the name and the rooms are enough.
	level_line.text = ""
	var badge: Texture2D = StitchfallLevels.chapter_badge(level_page_index)
	level_badge.texture = badge
	level_badge.visible = badge != null
	var shift: float = 186.0 if badge != null else 0.0
	level_kicker.position.x = 284.0 + shift
	level_heading.position.x = 278.0 + shift
	level_line.position.x = 284.0 + shift
	var next_room: int = progress.continue_room(StitchfallLevels.count()) if progress != null else 0
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
		button.caption = "%02d" % [index + 1]
		button.subcaption = data["name"]
		button.glyph = _biome_glyph(biome)
		button.cloth = _biome_cloth(biome)
		button.stars = progress.stars(index) if progress != null else 0
		button.locked = progress != null and not StitchfallShop.room_open(progress, index)
		button.next_up = index == next_room and not button.locked and button.stars <= 0
		button.tooltip_text = ""
		earned += maxi(button.stars, 0)
		button.queue_redraw()
	level_tally.text = "%d of %d stars" % [earned, rooms * 3]
	_fill_level_dots()
	# The rooms slide in from the side the page turned toward, fast, and settle.
	if from != level_page_index and level_page.is_visible_in_tree():
		var side: float = 1.0 if level_page_index > from else -1.0
		level_rooms.position.x = 140.0 * side
		level_rooms.modulate.a = 0.0
		var slide: Tween = create_tween().set_parallel(true)
		slide.tween_property(level_rooms, "position:x", 0.0, 0.32).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		slide.tween_property(level_rooms, "modulate:a", 1.0, 0.16)


func _fill_level_dots() -> void:
	var count: int = StitchfallLevels.chapter_count()
	var states: PackedInt32Array = PackedInt32Array()
	for chapter: int in range(count):
		var first: int = chapter * StitchfallLevels.CHAPTER_ROOMS
		var sewn: int = 0
		for slot: int in range(StitchfallLevels.CHAPTER_ROOMS):
			if progress != null and progress.stars(first + slot) > 0:
				sewn += 1
		var open: bool = progress == null or StitchfallShop.room_open(progress, first)
		states.append(2 if sewn == StitchfallLevels.CHAPTER_ROOMS else (1 if open else 0))
	level_dots.count = count
	level_dots.current = level_page_index
	level_dots.states = states
	level_dots.queue_redraw()


# The moves, one card each with its gesture moving (or its keys on a computer), the goal above them, and a way to
# run the first room's lessons again.
func _build_help() -> void:
	help_page = _page()
	_cloth_page(help_page, Rect2(170, 40, 1580, 900))
	_tag(help_page, Rect2(262, 118, 104, 104), "", "back", Color("e5d5bc")).pressed.connect(show_settings)
	var heading: Label = _label(help_page, Vector2(394, 106), Vector2(1150, 96), 70, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "HOW TO PLAY"
	var goal: Label = _label(help_page, Vector2(400, 196), Vector2(1200, 50), 34, ACCENT)
	goal.text = "Gather every button, then slip out through the zipper."
	var keys: bool = not touch()
	# A few words each: the gesture beside it shows the rest.
	var moves: Array[PackedStringArray] = [
		PackedStringArray(["MOVE", "Slide", "Arrows or WASD", "move"]),
		PackedStringArray(["JUMP", "Swipe up", "W or Space", "jump"]),
		PackedStringArray(["TURN", "Tap", "Shift", "shift"]),
		PackedStringArray(["CROUCH", "Swipe down", "S", "crouch"]),
	]
	for index: int in range(moves.size()):
		var move: PackedStringArray = moves[index]
		var rect: Rect2 = Rect2(262 + (index % 2) * 712, 264 + (index / 2) * 214, 686, 196)
		var card: Panel = _panel(help_page, rect, Color("e2b18f") if move[0] == "TURN" else Color("ecdfc7"))
		var title: Label = _label(card, Vector2(28, 22), Vector2(330, 60), 46, INK, true)
		title.text = move[0]
		var line: Label = _label(card, Vector2(28, 84), Vector2(350, 92), 30, Color(INK, 0.85))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		line.text = move[2] if keys else move[1]
		var gesture: StitchfallGestureGuide = GESTURE_GUIDE.new() as StitchfallGestureGuide
		gesture.size = Vector2(300, 170)
		gesture.pivot_offset = gesture.size * 0.5
		gesture.scale = Vector2.ONE * 1.12
		gesture.position = Vector2(356, 13)
		gesture.kind = move[3]
		card.add_child(gesture)
	# The one rule the cards cannot show: on a wall or the ceiling, the moves follow the screen.
	var footer: Label = _label(help_page, Vector2(268, 726), Vector2(700, 48), 28, ACCENT)
	footer.text = "On a wall, push the way you want to go."
	var practice: StitchedButton = _tag(help_page, Rect2(1000, 696, 410, 108), "PRACTICE", "move", Color("dbe5d1"))
	practice.caption_size = 36
	practice.pressed.connect(func() -> void: practice_pressed.emit())
	var start: StitchedButton = _tag(help_page, Rect2(1430, 696, 240, 108), "PLAY", "play", Color("e0a278"))
	start.caption_size = 36
	start.pressed.connect(func() -> void: begin_pressed.emit())


func _build_about() -> void:
	about_page = _page()
	_cloth_page(about_page, Rect2(210, 90, 1500, 880))
	# The card's left knots sit at about x 290 to 345, so the column starts clear of them.
	var heading: Label = _label(about_page, Vector2(380, 135), Vector2(1080, 110), 78, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.text = "A WORLD IN THREAD"
	_tag(about_page, Rect2(1510, 138, 112, 105), "", "back", Color("e5d5bc")).pressed.connect(show_settings)
	var note: Label = _label(about_page, Vector2(380, 250), Vector2(790, 230), 33, INK)
	note.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	note.text = "Turn the room, gather the buttons, slip out through the zipper. Every room hides one trick."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var studio: Label = _label(about_page, Vector2(380, 505), Vector2(790, 80), 30, INK)
	studio.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	studio.text = "Made by Chaosmos."
	studio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var version: Label = _label(about_page, Vector2(380, 600), Vector2(790, 46), 28, ACCENT, true)
	version.text = "Version %s" % version_name()
	var links: Array = [["SUPPORT", "help", StitchfallShop.SUPPORT], ["PRIVACY", "seam", StitchfallShop.PRIVACY], ["GAMES", "play", StitchfallShop.MORE_GAMES]]
	# The browser build links the game's page and GitHub Sponsors. Play's Payments policy keeps the Android build
	# from leading anywhere one tap from another way to pay, and the game's page carries the studio's Sponsor link,
	# so it links only pages without one, and Rate, which opens the Play page: no button may call Play's own review
	# card.
	if not StitchfallShop.on_play:
		links.push_front(["WEBSITE", "link", StitchfallShop.WEBSITE])
		links.append(["SPONSOR", "gift", StitchfallShop.SPONSOR])
	else:
		links.append(["RATE", "star", StitchfallShop.STORE])
	for index: int in range(links.size()):
		var link: Array = links[index]
		var tag: StitchedButton = _tag(about_page, Rect2(360 + index * 165, 665, 162, 195), link[0], link[1], [Color("dbe5d1"), Color("e8d8bd"), Color("e4d0b1"), Color("efd3b8"), Color("e0a278")][index])
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


# Two columns of wide rows, each saying what it is and, for a switch, whether it is on: how the game sounds and
# feels on the left, and help and the game's pages on the right. Reset stands apart at the foot.
func _build_settings() -> void:
	settings_page = _page()
	_cloth_page(settings_page, Rect2(250, 40, 1420, 1000))
	_tag(settings_page, Rect2(338, 120, 104, 104), "", "back", Color("e5d5bc")).pressed.connect(show_home)
	var heading: Label = _label(settings_page, Vector2(560, 116), Vector2(800, 110), 72, INK, true)
	heading.add_theme_font_override("font", FONT_DISPLAY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.text = "SETTINGS"
	# Google Play's build has its Shop here too, as the kit games do.
	var bag: StitchedButton = _tag(settings_page, Rect2(1478, 120, 104, 104), "", "bag", Color("f0c9a8"))
	bag.tooltip_text = "Shop"
	bag.pressed.connect(func() -> void: show_shop("settings"))
	settings_tags["shop"] = bag
	var left: Array = [
		["sound", "SOUND", "sound", Color("e8d8bd"), _toggle_sound],
		["music", "MUSIC", "music", Color("dbe5d1"), _toggle_music],
		["shake", "SHAKE", "shake", Color("efd3b8"), _toggle_shake],
		["thread", "THREAD", "move", Color("e4d0b1"), _toggle_thread],
	]
	var right: Array = [
		["help", "HOW TO PLAY", "help", Color("e0a278"), show_help],
		["stats", "STATS", "stats", Color("dbe5d1"), show_stats],
		["credits", "CREDITS", "credits", Color("e8d8bd"), show_credits],
		["about", "ABOUT", "seam", Color("e4d0b1"), show_about],
	]
	for column: int in range(2):
		var entries: Array = left if column == 0 else right
		for index: int in range(entries.size()):
			var entry: Array = entries[index]
			var tag: StitchedButton = _tag(settings_page, Rect2(SETTINGS_X[column], SETTINGS_Y + index * SETTINGS_STEP, SETTINGS_ROW.x, SETTINGS_ROW.y), entry[1], entry[2], entry[3])
			tag.caption_size = 40
			# A switch on the left's settings, and an arrow on the right's rows, which each open a page.
			tag.arrow = column == 1
			tag.pressed.connect(entry[4])
			settings_tags[entry[0]] = tag
	sound_buttons.append(settings_tags["sound"])
	# Under the rows, a small card on the left: Fullscreen where there is a window to fill, or Privacy when
	# Google's consent service says a player must be able to change their ad consent. A phone has no window.
	var corner: Rect2 = Rect2(SETTINGS_X[0], SETTINGS_Y + 4 * SETTINGS_STEP + 30.0, 360, 96)
	var fullscreen: StitchedButton = _tag(settings_page, corner, "FULLSCREEN", "fullscreen", Color("e4d0b1"))
	fullscreen.caption_size = 32
	fullscreen.pressed.connect(_toggle_fullscreen)
	settings_tags["fullscreen"] = fullscreen
	var privacy: StitchedButton = _tag(settings_page, corner, "PRIVACY", "lock", Color("e4d0b1"))
	privacy.caption_size = 32
	privacy.pressed.connect(func() -> void: StitchfallAds.open_privacy_options())
	privacy.visible = false
	settings_tags["privacy"] = privacy
	# Reset asks twice and sits on its own, below the rest, so it is never a slip of the thumb.
	var reset: StitchedButton = _tag(settings_page, Rect2(SETTINGS_X[1] + SETTINGS_ROW.x - 320.0, SETTINGS_Y + 4 * SETTINGS_STEP + 30.0, 320, 96), "RESET", "restart", Color("e9c9bd"))
	reset.caption_size = 34
	reset.pressed.connect(_reset_progress)
	settings_tags["reset"] = reset


# Shows each switch's state on its row, and puts the reset back to asking once.
func _refresh_settings() -> void:
	if progress == null:
		return
	settings_tags["sound"].glyph = "sound" if audio_enabled else "mute"
	settings_tags["music"].glyph = "music" if progress.music else "music_off"
	settings_tags["shake"].glyph = "shake" if progress.shake else "shake_off"
	settings_tags["sound"].switch_on = 1 if audio_enabled else 0
	settings_tags["music"].switch_on = 1 if progress.music else 0
	settings_tags["shake"].switch_on = 1 if progress.shake else 0
	settings_tags["thread"].switch_on = 1 if progress.thread else 0
	swipe_thread.visible = progress.thread
	settings_tags["privacy"].visible = StitchfallAds.privacy_options_required()
	settings_tags["fullscreen"].visible = not OS.has_feature("android") and not settings_tags["privacy"].visible
	settings_tags["shop"].visible = StitchfallShop.on_play
	reset_armed = false
	settings_tags["reset"].caption = "RESET"
	settings_tags["reset"].subcaption = ""
	for tag: StitchedButton in settings_tags.values():
		tag.queue_redraw()


func _toggle_music() -> void:
	progress.music = not progress.music
	music_toggled.emit(progress.music)
	_refresh_settings()


func _toggle_thread() -> void:
	progress.thread = not progress.thread
	progress.save()
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
		settings_tags["reset"].subcaption = "Tap again to erase"
		settings_tags["reset"].queue_redraw()
		return
	progress_reset.emit()
	_refresh_settings()
	settings_tags["reset"].caption = "DONE"
	settings_tags["reset"].subcaption = ""
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
	skip_button = _tag(pause_page, Rect2(680, 728, 560, 104), "SKIP THIS ROOM", "next", Color("efd3b8"))
	skip_button.caption_size = 36
	skip_button.pressed.connect(func() -> void: skip_pressed.emit())
	skip_button.visible = false
	# The end of the campaign is the one place the game offers the Shop unasked, in Google Play's build, to a
	# player without the Supporter pack, as the kit games' ending does.
	finish_shop = _tag(pause_page, Rect2(680, 728, 560, 104), "THE SHOP", "bag", Color("f0c9a8"))
	finish_shop.caption_size = 36
	finish_shop.pressed.connect(func() -> void: show_shop("finish"))
	finish_shop.visible = false


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
	# The chapter's patch, sewn over the card's top edge, once the art is in.
	chapter_badge = TextureRect.new()
	chapter_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chapter_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chapter_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_badge.position = Vector2(860, 130)
	chapter_badge.size = Vector2(200, 200)
	chapter_badge.pivot_offset = chapter_badge.size * 0.5
	chapter_page.add_child(chapter_badge)


func show_chapter(chapter: int, chapter_title: String, line: String) -> void:
	chapter_number.text = "CHAPTER %d" % (chapter + 1)
	chapter_name_label.text = chapter_title.to_upper()
	chapter_line_label.text = line
	chapter_badge.texture = StitchfallLevels.chapter_badge(chapter)
	chapter_badge.visible = chapter_badge.texture != null
	_show_screen("chapter")
	if chapter_tween and chapter_tween.is_running():
		chapter_tween.kill()
	chapter_name_label.scale = Vector2.ONE * 0.6
	chapter_name_label.modulate.a = 0.0
	chapter_line_label.modulate.a = 0.0
	chapter_tween = create_tween()
	# The patch lands first, as if slapped on, then the name.
	chapter_badge.scale = Vector2.ONE * 1.4
	chapter_badge.modulate.a = 0.0
	chapter_tween.tween_property(chapter_badge, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chapter_tween.parallel().tween_property(chapter_badge, "modulate:a", 1.0, 0.15)
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
	# The words scroll inside the card, so however small a phone makes the page above its banner, nothing runs
	# out of the cloth. A finger drags them, and the bar stays hidden.
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.position = Vector2(320, 250)
	scroll.size = Vector2(1300, 640)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	credits_page.add_child(scroll)
	var body: Label = Label.new()
	body.custom_minimum_size = Vector2(1270, 0)
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_theme_font_override("font", regular_font)
	body.add_theme_font_size_override("font_size", 31)
	body.add_theme_color_override("font_color", INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 8)
	scroll.add_child(body)
	body.text = "\n".join([
		"Made by Shravan Goswami at Chaosmos, with the help of AI tools.",
		"",
		"Darn and Threadline are original Chaosmos fonts, and the opening's wordmark is Bricolage Grotesque, all under the SIL Open Font License.",
		"Built with the Godot Engine, under the MIT license. Copyright (c) 2014-present Godot Engine contributors, (c) 2007-2014 Juan Linietsky and Ariel Manzur.",
		"",
		"Thank you to everyone who plays, and to GitHub Game Off.",
	])
	if StitchfallShop.on_play and not StitchfallPlayGames.app_id().is_empty():
		body.text += "\n\n" + "In the Android app: the Godot AdMob Plugin by Poing Studios, Godot Google Play Billing by the Godot Engine contributors, Godotx Firebase by Paulo Coutinho and GodotPlayGameServices by Jacob Ibáñez Sánchez, each under the MIT license, and Google's Mobile Ads SDK, User Messaging Platform, Play Billing Library, Play In-App Review and Updates, Play Games Services and Analytics for Firebase, under Google's terms."
	elif StitchfallShop.on_play:
		body.text += "\n\n" + "In the Android app: the Godot AdMob Plugin by Poing Studios, Godot Google Play Billing by the Godot Engine contributors and Godotx Firebase by Paulo Coutinho, each under the MIT license, and Google's Mobile Ads SDK, User Messaging Platform, Play Billing Library, Play In-App Review and Updates and Analytics for Firebase, under Google's terms."


# The wardrobe: the heading over a tab per kind of piece, the pieces as tiles, and the runner dancing in what it
# wears over the Wardrobe pack's price. Its parts are placed by _layout_wardrobe.
func _build_wardrobe() -> void:
	wardrobe_page = _page()
	# The painted cloth as a nine-patch, so its knotted corners and border keep their shape at any size.
	wardrobe_cloth = NinePatchRect.new()
	wardrobe_cloth.texture = PAUSE_CLOTH
	wardrobe_cloth.patch_margin_left = WARDROBE_CLOTH_EDGE
	wardrobe_cloth.patch_margin_top = WARDROBE_CLOTH_EDGE
	wardrobe_cloth.patch_margin_right = WARDROBE_CLOTH_EDGE
	wardrobe_cloth.patch_margin_bottom = WARDROBE_CLOTH_EDGE
	wardrobe_cloth.scale = Vector2.ONE * WARDROBE_CLOTH_SCALE
	wardrobe_cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wardrobe_page.add_child(wardrobe_cloth)
	wardrobe_heading = _label(wardrobe_page, Vector2.ZERO, Vector2(WARDROBE_KINDS.z, WARDROBE_HEAD), 77, INK, true)
	wardrobe_heading.add_theme_font_override("font", FONT_DISPLAY)
	wardrobe_heading.text = "WARDROBE"
	wardrobe_home = _tag(wardrobe_page, Rect2(Vector2.ZERO, Vector2.ONE * WARDROBE_CORNER), "", "home", Color("e5d5bc"))
	wardrobe_home.pressed.connect(show_home)
	# The stars earned, which open trails, unravels and buttons: a felt chip, not a button.
	wardrobe_stars = _tag(wardrobe_page, Rect2(0, 0, 220, WARDROBE_CORNER - 8.0), "0", "star", Color("efe3cd"))
	wardrobe_stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wardrobe_stars.focus_mode = Control.FOCUS_NONE
	wardrobe_stars.caption_size = 46
	wardrobe_preview = AnimatedSprite2D.new()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CLEANUP_SHADER
	wardrobe_preview.material = material
	wardrobe_page.add_child(wardrobe_preview)
	for index: int in range(StitchfallLooks.KINDS.size()):
		var kind: String = StitchfallLooks.KINDS[index]
		var tab: StitchedButton = _tag(wardrobe_page, Rect2(0, 0, WARDROBE_KINDS.y, WARDROBE_TAB), StitchfallLooks.KIND_NAMES[index].to_upper(), "", Color("e5d5bc"))
		tab.pressed.connect(_show_kind.bind(kind))
		wardrobe_tabs[kind] = tab
	for slot: int in range(WARDROBE_SLOTS):
		var tile: StitchfallItemTile = StitchfallItemTile.new()
		tile.pressed.connect(_choose_piece.bind(slot))
		tile.pressed.connect(_tap)
		wardrobe_page.add_child(tile)
		wardrobe_tiles.append(tile)
	wardrobe_buy = _tag(wardrobe_page, Rect2(0, 0, WARDROBE_DANCER.y, WARDROBE_PACK), "WARDROBE PACK", "wardrobe", Color("f0dcc0"))
	wardrobe_buy.price_card = true
	wardrobe_buy.pressed.connect(func() -> void: show_offer(StitchfallMonetize.WARDROBE_ID, "wardrobe"))
	wardrobe_shop = _tag(wardrobe_page, Rect2(Vector2.ZERO, Vector2.ONE * WARDROBE_CORNER), "", "bag", Color("efd3b8"))
	wardrobe_shop.tooltip_text = "Shop"
	wardrobe_shop.pressed.connect(func() -> void: show_shop("wardrobe"))


# Places the Wardrobe's parts in the screen's safe part, above the banner while one is due (see WARDROBE_MARGIN).
func _layout_wardrobe(safe: Vector4) -> void:
	wardrobe_page.scale = Vector2.ONE
	wardrobe_page.position = Vector2.ZERO
	var view: Vector2 = root.size
	var banner: bool = StitchfallAds.banner_wanted()
	var cloth: Rect2 = Rect2(safe.x + WARDROBE_MARGIN, safe.y + WARDROBE_MARGIN, view.x - safe.x - safe.z - WARDROBE_MARGIN * 2.0, view.y - safe.y - safe.w - WARDROBE_MARGIN * 2.0)
	if banner:
		cloth.size.y = minf(cloth.size.y, StitchfallAds.banner_rect().position.y - CLOTH_GAP_DP * StitchfallAds.per_dp() - cloth.position.y)
	wardrobe_cloth.position = cloth.position
	wardrobe_cloth.size = cloth.size / WARDROBE_CLOTH_SCALE
	wardrobe_cloth.set_meta(&"cloth", cloth)
	var inner: Rect2 = cloth.grow_individual(-WARDROBE_INSET.x, -WARDROBE_INSET.y, -WARDROBE_INSET.x, -WARDROBE_INSET.y)
	if banner:
		inner.size.y = minf(inner.size.y, StitchfallAds.content_limit() - inner.position.y)
	# The kinds' column: the heading, as large as fits, then a tab for each kind.
	var kinds_wide: float = clampf(inner.size.x * WARDROBE_KINDS.x, WARDROBE_KINDS.y, WARDROBE_KINDS.z)
	var heading_size: int = 77
	while heading_size > 40 and FONT_DISPLAY.get_string_size(wardrobe_heading.text, HORIZONTAL_ALIGNMENT_LEFT, -1, heading_size).x > kinds_wide:
		heading_size -= 1
	wardrobe_heading.add_theme_font_size_override("font_size", heading_size)
	wardrobe_heading.position = inner.position
	wardrobe_heading.size = Vector2(kinds_wide, WARDROBE_HEAD)
	var count: int = StitchfallLooks.KINDS.size()
	var tab_gap: float = 14.0
	var tabs_top: float = inner.position.y + WARDROBE_HEAD + WARDROBE_GAP * 0.5
	var tab_high: float = minf(WARDROBE_TAB, (inner.end.y - tabs_top - tab_gap * (count - 1)) / count)
	for index: int in range(count):
		var tab: StitchedButton = wardrobe_tabs[StitchfallLooks.KINDS[index]]
		tab.position = Vector2(inner.position.x, tabs_top + index * (tab_high + tab_gap))
		tab.size = Vector2(kinds_wide, tab_high)
		tab.caption_size = int(minf(42.0, tab_high * 0.42))
	# The dancer's column: the stars, the Shop and Home along its top, the pack's price card at its foot, and the
	# runner dancing between them.
	var dancer_wide: float = clampf(inner.size.x * WARDROBE_DANCER.x, WARDROBE_DANCER.y, WARDROBE_DANCER.z)
	var column: float = inner.end.x - dancer_wide
	wardrobe_home.position = Vector2(inner.end.x - WARDROBE_CORNER, inner.position.y)
	wardrobe_home.size = Vector2.ONE * WARDROBE_CORNER
	wardrobe_shop.position = Vector2(wardrobe_home.position.x - WARDROBE_GAP * 0.5 - WARDROBE_CORNER, inner.position.y)
	wardrobe_shop.size = Vector2.ONE * WARDROBE_CORNER
	var stars_end: float = (wardrobe_shop.position.x if wardrobe_shop.visible else wardrobe_home.position.x) - WARDROBE_GAP * 0.5
	wardrobe_stars.position = Vector2(column, inner.position.y + 4.0)
	wardrobe_stars.size = Vector2(minf(stars_end - column, 230.0), WARDROBE_CORNER - 8.0)
	var dance_top: float = inner.position.y + WARDROBE_CORNER + WARDROBE_GAP * 0.5
	var dance_end: float = inner.end.y
	if wardrobe_buy.visible:
		wardrobe_buy.position = Vector2(column, inner.end.y - WARDROBE_PACK)
		wardrobe_buy.size = Vector2(dancer_wide, WARDROBE_PACK)
		dance_end = wardrobe_buy.position.y - WARDROBE_GAP * 0.5
	if wardrobe_preview.sprite_frames != null:
		var frame: Vector2 = wardrobe_preview.sprite_frames.get_frame_texture("dance", 0).get_size()
		wardrobe_preview.scale = Vector2.ONE * minf((dance_end - dance_top) / frame.y, dancer_wide / frame.x)
		wardrobe_preview.position = Vector2(column + dancer_wide * 0.5, (dance_top + dance_end) * 0.5)
	# The pieces between, in four columns or three, whichever lets this kind's tiles be larger.
	var grid: Rect2 = Rect2(inner.position.x + kinds_wide + WARDROBE_GAP, inner.position.y, column - inner.position.x - kinds_wide - WARDROBE_GAP * 2.0, inner.size.y)
	var pieces: int = clampi(StitchfallLooks.items(wardrobe_kind).size(), 1, WARDROBE_SLOTS)
	var columns: int = 4
	var tile: float = 0.0
	for across: int in [4, 3]:
		var rows: int = ceili(float(pieces) / float(across))
		var side: float = minf((grid.size.x - WARDROBE_GAP * (across - 1)) / across, (grid.size.y - WARDROBE_GAP * (rows - 1)) / rows)
		if side > tile + 0.5:
			tile = side
			columns = across
	tile = floorf(minf(tile, WARDROBE_TILE_LARGEST))
	var down: int = ceili(float(pieces) / float(columns))
	var block: Vector2 = Vector2(columns * tile + (columns - 1) * WARDROBE_GAP, down * tile + (down - 1) * WARDROBE_GAP)
	var corner: Vector2 = (grid.position + (grid.size - block) * 0.5).round()
	for slot: int in range(wardrobe_tiles.size()):
		wardrobe_tiles[slot].position = corner + Vector2(slot % columns, slot / columns) * (tile + WARDROBE_GAP)
		wardrobe_tiles[slot].size = Vector2(tile, tile)


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
		# One line each: what it is for. The offer page after it says the rest.
		card.lines = PackedStringArray([SHOP_LINES.get(id, "")])
		card.tooltip_text = ""
		card.pressed.connect(show_offer.bind(id, "shop"))
		shop_cards[id] = card
	var jar: Label = _label(shop_page, Vector2(176, 742), Vector2(1250, 50), 30, INK, true)
	jar.text = "Tip jar"
	for index: int in range(StitchfallMonetize.TIP_IDS.size()):
		var tip_id: String = StitchfallMonetize.TIP_IDS[index]
		var tip: StitchedButton = _tag(shop_page, Rect2(170 + index * 212, 800, 200, 82), "TIP", "", Color("e8d8bd"))
		tip.pressed.connect(func() -> void: show_offer(tip_id, "shop"))
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
	match shop_return:
		"wardrobe":
			show_wardrobe()
		"settings":
			show_settings()
		"levels":
			show_levels()
		_:
			show_home()


# The Complete pack shows only while none of it is owned, or once it is, and the cards centre on the cloth.
func _fill_shop() -> void:
	shop_line.text = "Thank you for supporting the next game." if StitchfallShop.ads_off(progress) else "Every room opens by playing too."
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


# The page before every purchase, as the kit games have it: what the product is for and holds, its price, the
# Complete pack's saving, and a note that Google Play's own sheet comes next. Nothing reaches Google Play without it.
func _build_offer() -> void:
	offer_page = _page()
	_cloth_page(offer_page, Rect2(65, 50, 1790, 970))
	_tag(offer_page, Rect2(1700, 100, 100, 101), "", "back", Color("e5d5bc")).pressed.connect(leave_offer)
	offer_patch = _tag(offer_page, Rect2(220, 270, 400, 400), "", "", Color("efd3b8"))
	offer_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	offer_patch.focus_mode = Control.FOCUS_NONE
	offer_badge = _panel(offer_page, Rect2(420, 236, 240, 84), ACCENT)
	offer_badge.pivot_offset = offer_badge.size * 0.5
	offer_badge.rotation = -0.12
	offer_badge_label = _label(offer_badge, Vector2.ZERO, offer_badge.size, 36, PAPER, true)
	offer_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_heading = _label(offer_page, Vector2(720, 130), Vector2(960, 110), 77, INK, true)
	offer_heading.add_theme_font_override("font", FONT_DISPLAY)
	offer_pitch = _label(offer_page, Vector2(726, 240), Vector2(960, 96), 31, ACCENT)
	offer_pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for index: int in range(4):
		var dot: ColorRect = ColorRect.new()
		dot.color = ACCENT
		dot.size = Vector2(16, 16)
		dot.pivot_offset = dot.size * 0.5
		dot.rotation = PI * 0.25
		dot.position = Vector2(740, 382 + index * 70)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		offer_page.add_child(dot)
		offer_dots.append(dot)
		offer_rows.append(_label(offer_page, Vector2(778, 362 + index * 70), Vector2(920, 56), 34, INK))
	offer_buy = _tag(offer_page, Rect2(720, 690, 600, 112), "BUY", "", Color("e0a278"))
	offer_buy.caption_size = 44
	offer_buy.pressed.connect(func() -> void: _say(StitchfallShop.buy(offer_id)))
	offer_shop = _tag(offer_page, Rect2(1350, 690, 330, 112), "THE SHOP", "bag", Color("efd3b8"))
	offer_shop.caption_size = 34
	offer_shop.pressed.connect(func() -> void: show_shop(offer_return))
	offer_note = _label(offer_page, Vector2(726, 836), Vector2(960, 96), 28, ACCENT)
	offer_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func show_offer(id: String, from: String) -> void:
	offer_id = id
	offer_return = from
	_fill_offer()
	offer_note.text = "%s is yours. Thank you!" % StitchfallShop.title(id) if StitchfallShop.has(progress, id) else StitchfallShop.PAYMENT_NOTE
	_show_screen("offer")
	StitchfallAnalytics.event(&"shop_offer", {"item": id, "from": from})


func _fill_offer() -> void:
	var owned: bool = StitchfallShop.has(progress, offer_id)
	offer_heading.text = StitchfallShop.title(offer_id).to_upper()
	offer_pitch.text = StitchfallShop.pitch(offer_id)
	offer_patch.glyph = StitchfallShop.glyph(offer_id)
	offer_patch.cloth = shop_cards[offer_id].cloth if shop_cards.has(offer_id) else Color("e8d8bd")
	offer_patch.queue_redraw()
	var rows: PackedStringArray = StitchfallShop.details(offer_id)
	for index: int in range(offer_rows.size()):
		offer_rows[index].text = rows[index] if index < rows.size() else ""
		offer_dots[index].visible = index < rows.size()
	var saving: int = StitchfallShop.saving() if offer_id == StitchfallMonetize.COMPLETE_ID else 0
	offer_badge.visible = saving > 0 and not owned
	offer_badge_label.text = "SAVE %d%%" % saving
	offer_buy.visible = not owned
	offer_buy.caption = StitchfallShop.buy_caption(offer_id)
	offer_buy.queue_redraw()
	offer_shop.visible = offer_return != "shop"


func leave_offer() -> void:
	match offer_return:
		"shop":
			_fill_shop()
			_show_screen("shop")
		"wardrobe":
			show_wardrobe()
		"levels":
			_hide_shut_room()
			_set_level_page(level_page_index)
			_show_screen("levels")
		_:
			show_home()


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
	wardrobe_buy.price_tag = StitchfallShop.price(StitchfallMonetize.WARDROBE_ID)
	wardrobe_buy.queue_redraw()
	wardrobe_stars.caption = str(progress.total_stars())
	wardrobe_stars.queue_redraw()
	_show_worn()
	_layout_wardrobe(_safe_insets())


func _show_worn() -> void:
	wardrobe_preview.sprite_frames = _dance_frames()
	wardrobe_preview.play("dance")


# A locked pack piece opens the pack's page, and a piece that stars open says how many.
func _choose_piece(slot: int) -> void:
	var item: Dictionary = StitchfallLooks.items(wardrobe_kind)[slot]
	if not StitchfallShop.is_open(item, progress):
		if bool(item["paid"]):
			show_offer(StitchfallMonetize.WARDROBE_ID, "wardrobe")
		else:
			_say("%s opens at %d stars." % [item["name"], int(item["stars"])])
		return
	progress.wear[wardrobe_kind] = item["id"]
	progress.save()
	wardrobe_changed.emit()
	_show_kind(wardrobe_kind)
	_dress_dancers()


# A line from the page or from Google Play, on the page it belongs to, or on any other page, a toast that fades.
func _say(text: String) -> void:
	if text.is_empty():
		return
	match screen:
		"shop":
			shop_note.text = text
		"offer":
			offer_note.text = text
		"pause":
			pause_body.text = text
		"levels":
			level_note.text = text
			level_note.visible = true
			_layout()
		_:
			_toast(text)


func _toast(text: String) -> void:
	toast_label.text = text
	toast.visible = true
	toast.modulate.a = 1.0
	if toast_tween != null:
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(TOAST_SECONDS)
	toast_tween.tween_property(toast, "modulate:a", 0.0, 0.6)
	toast_tween.tween_callback(func() -> void: toast.visible = false)


# Google Play's answers (prices, a purchase, a refund) redraw the page that shows them, keeping its note.
func refresh_store() -> void:
	match screen:
		"wardrobe":
			_show_kind(wardrobe_kind)
		"shop":
			_fill_shop()
		"offer":
			var said: String = offer_note.text
			_fill_offer()
			offer_note.text = said
		"levels":
			_set_level_page(level_page_index)
			level_unlock.visible = level_unlock.visible and not StitchfallShop.has(progress, StitchfallMonetize.LEVELS_ID)


# The version is the newest section of CHANGELOG.md, the file that also names every Android release.
static func version_name() -> String:
	var file: FileAccess = FileAccess.open("res://CHANGELOG.md", FileAccess.READ)
	if file == null:
		return "?"
	for line: String in file.get_as_text().split("\n"):
		if line.begins_with("## "):
			return line.substr(3).strip_edges().split(" ")[0]
	return "?"


func _biome_cloth(biome: int) -> Color:
	match biome:
		4: return Color("d9e8e4")
		5: return Color("f1d7a8")
		6: return Color("dfe8c8")
		7: return Color("d8d3e3")
		8: return Color("dce8e2")
		9: return Color("e9e9ec")
	return Color("f1e1c8")


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
	var index: int = level_page_index * StitchfallLevels.CHAPTER_ROOMS + slot
	if level_buttons[slot].locked:
		_show_shut_room(index)
		return
	level_selected.emit(index)


func _turn_level_page(step: int) -> void:
	_hide_shut_room()
	_set_level_page(level_page_index + step)


# Only a room after the first can be shut, and it opens once the room before it is sewn or skipped.
func _show_shut_room(index: int) -> void:
	var offer: bool = StitchfallShop.on_play and not StitchfallShop.has(progress, StitchfallMonetize.LEVELS_ID)
	var before: String = StitchfallLevels.get_level(index - 1)["name"]
	level_note.text = ("Sew %s first, or open every room at once." if offer else "Sew %s first to open this room.") % before
	level_note.visible = true
	var price: String = StitchfallShop.price(StitchfallMonetize.LEVELS_ID)
	level_unlock.caption = "EVERY ROOM" if price.is_empty() else "EVERY ROOM  %s" % price
	level_unlock.visible = offer
	level_unlock.queue_redraw()
	_layout()


func _hide_shut_room() -> void:
	level_note.visible = false
	level_unlock.visible = false
	_layout()


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
	fabric.visible = name in ["levels", "help", "about", "settings", "stats", "credits", "wardrobe", "shop", "offer"]
	shop_page.visible = name == "shop"
	offer_page.visible = name == "offer"
	update_page.visible = name == "update"
	StitchfallAds.want_banner(name in StitchfallAds.BANNER_SCREENS, HOME_HERO_X if name == "home" else 0.5)
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
	skip_hint.visible = false
	coach_holder.visible = false
	if name == "home":
		hero.play("dance")
	else:
		hero.stop()


func show_home() -> void:
	_dress_dancers()
	_show_screen("home")


func show_credits() -> void:
	_show_screen("credits")


# The first room's coach teaches the controls in play, so Play always plays.
func _begin_from_home() -> void:
	begin_pressed.emit()


func show_levels() -> void:
	_hide_shut_room()
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
	pause_body.position.y = 330.0 if offered else 355.0
	pause_body.size.y = 82.0 if offered else 95.0
	pause_body.add_theme_font_size_override("font_size", 28 if offered else 32)
	finish_shop.visible = false
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
	finish_shop.visible = StitchfallShop.on_play and progress != null and not StitchfallShop.ads_off(progress)
	# With the Shop under them, the two actions rise as they do for a skip.
	if finish_shop.visible:
		pause_body.position.y = 330.0
		resume_button.position.y = 412.0
		pause_home_button.position.y = 440.0
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
	skip_hint.visible = skip_ready
	coach_holder.visible = true
	hero.stop()


func set_room_label(chapter_title: String, number: int, room_name: String) -> void:
	room_label.text = "%s  %d   %s" % [chapter_title, number, room_name]
	home_play.queue_redraw()


# Home's Play leads to the room loaded now, so it names it the way the Levels page numbers it.
func set_next_room(index: int, room_name: String) -> void:
	home_play.subcaption = "Room %d   %s" % [index + 1, room_name]
	home_play.queue_redraw()


# Called as the room's unravels change: true once the pause page would offer a skip.
func show_skip_hint(ready: bool) -> void:
	var appears: bool = ready and not skip_ready
	skip_ready = ready
	skip_hint.visible = ready and screen == "game"
	if skip_hint_tween != null:
		skip_hint_tween.kill()
	skip_hint.modulate.a = 1.0
	if appears and screen == "game":
		# Three slow pulses as it appears, then it stays still, so it never nags.
		skip_hint_tween = create_tween().set_loops(3)
		skip_hint_tween.tween_property(skip_hint, "modulate:a", 0.35, 0.45)
		skip_hint_tween.tween_property(skip_hint, "modulate:a", 1.0, 0.45)


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


func set_status(sparks: int, total_sparks: int, biome: int) -> void:
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
	pause_button.queue_redraw()
	hint_back.add_theme_stylebox_override("panel", _style(palette[0], palette[1], 2))
