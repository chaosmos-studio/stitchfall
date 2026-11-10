class_name ChaosmosIntro
extends Control

# The Chaosmos intro a game opens on: a style brings the wordmark in with its sting, holds it, and lets go. A tap
# or a key skips it. Add it full screen and wait for `finished`.
#
# It draws in two layers, the back (the sky, cloth or glass a style plays on) and the style over it. In a game the
# back goes first, so the game's Home shows through while the word falls a little way onto it, lands, and fades.
# On Android it opens on the mark the system's launch screen was showing, at the same place and size, so the
# launch goes from that mark straight into the beat.
#
# Only Pixel draws through a SubViewport, which it shrinks for big pixels: its stage renders at a fraction of the
# screen and is shown enlarged without smoothing.

signal finished
# Once, as it starts to let the game show: its back starts to fade into Home, or it was skipped. A game can bring
# back what it hid (a banner) here, so Home arrives whole while the word is still fading.
signal giving_way

# Loaded by path when asked for, so a game ships only the one style it uses.
const STYLES: Dictionary[String, String] = {
	"fill": "res://intro/styles/fill.gd",
	"cosmos": "res://intro/styles/cosmos.gd",
	"ink": "res://intro/styles/ink.gd",
	"pop": "res://intro/styles/pop.gd",
	"orbit": "res://intro/styles/orbit.gd",
	"snap": "res://intro/styles/snap.gd",
	"neon": "res://intro/styles/neon.gd",
	"pixel": "res://intro/styles/pixel.gd",
	"paper": "res://intro/styles/paper.gd",
	"mascot": "res://intro/styles/mascot.gd",
	"premiere": "res://intro/styles/premiere.gd",
}
# How long the finished word holds, and how long it takes to fade, in seconds.
const HOLD: float = 0.75
const FADE: float = 0.35
const SKIP_FADE: float = 0.18
# In a game the word holds less, then the back fades into Home over BACK_GO while the word falls FALL of the
# screen's height in FALL_TIME and lands with a bounce. WORD_GO_AT after the hold the word fades, over WORD_GO.
const REVEAL_HOLD: float = 0.5
const BACK_GO: float = 0.45
const FALL: float = 0.045
const FALL_TIME: float = 0.55
const WORD_GO_AT: float = 0.5
const WORD_GO: float = 0.3
# The launch screen's mark: the width of its ring in dp. Android draws a splash icon 288 dp square, and
# tools/make_splash.gd draws the mark this wide in it. It gives way to the style over LAUNCH_FADE, shrinking to
# LAUNCH_SHRINK of its size.
const LAUNCH_MARK_DP: float = 112.0
const LAUNCH_FADE: float = 0.3
const LAUNCH_SHRINK: float = 0.86
const PIXEL_SNAP: Shader = preload("res://intro/pixel_snap.gdshader")


# Named for the intro alone: a game's own global classes (Sunwise has a Stage) would hide a plainer name.
class ChaosmosStage extends Control:
	var intro: ChaosmosIntro

	func _draw() -> void:
		intro.draw_stage(self)


class ChaosmosBack extends Control:
	var intro: ChaosmosIntro

	func _draw() -> void:
		intro.style.draw_back(self, intro.clock, size)


class ChaosmosLaunch extends Control:
	var intro: ChaosmosIntro

	func _draw() -> void:
		intro.draw_launch(self)


@export var style_name: String = "fill"
@export var dark: bool = false
# Off in the preview renders, so a recording plays every frame of the style.
@export var skippable: bool = true
# In a game: the intro gives way to the screen under it (its Home), rather than fading to its own background.
@export var reveal: bool = false
# In a game with its sound off: no sting.
@export var muted: bool = false
# On a cold start on Android: open on the launch screen's mark, over the launch screen's colour.
@export var launch: bool = false
@export var launch_color: Color = ChaosmosWordmark.PAPER

var style: ChaosmosIntroStyle
var word: ChaosmosWordmark = ChaosmosWordmark.new()
var clock: float = 0.0
var ending: float = -1.0
var done: bool = false
var gave_way: bool = false
var sting: AudioStreamPlayer
var back: ChaosmosBack
# What the style draws: the stage itself, or for Pixel the SubViewport that holds it.
var front: Control
var frame: SubViewportContainer
var viewport: SubViewport
var stage: ChaosmosStage
var veil: ColorRect
var cover: ChaosmosLaunch


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# A name from STYLES, or the path of a game's own style script.
	var path: String = STYLES.get(style_name, style_name)
	if not ResourceLoader.exists(path):
		path = STYLES["fill"]
	style = (load(path) as Script).new() as ChaosmosIntroStyle
	style.word = word
	if dark:
		style.paper = ChaosmosWordmark.CHARCOAL
		style.ink = ChaosmosWordmark.LIGHT
	back = ChaosmosBack.new()
	back.intro = self
	_fill(back)
	stage = ChaosmosStage.new()
	stage.intro = self
	if style.pixel_art():
		frame = SubViewportContainer.new()
		frame.stretch = true
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var snapping: ShaderMaterial = ShaderMaterial.new()
		snapping.shader = PIXEL_SNAP
		snapping.set_shader_parameter("paper", style.background())
		snapping.set_shader_parameter("ink", style.ink)
		snapping.set_shader_parameter("coral", style.coral)
		frame.material = snapping
		_fill(frame)
		viewport = SubViewport.new()
		frame.add_child(viewport)
		viewport.add_child(stage)
		front = frame
	else:
		_fill(stage)
		front = stage
	veil = ColorRect.new()
	veil.color = Color(style.background(), 0.0)
	_fill(veil)
	if launch:
		cover = ChaosmosLaunch.new()
		cover.intro = self
		_fill(cover)
	sting = AudioStreamPlayer.new()
	add_child(sting)
	var sound: String = style.sting()
	if not muted and not sound.is_empty() and ResourceLoader.exists(sound):
		sting.stream = load(sound) as AudioStream
		sting.play()


func _fill(layer: Control) -> void:
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func hold() -> float:
	return REVEAL_HOLD if reveal else HOLD


func total() -> float:
	return style.settle() + hold() + (WORD_GO_AT + WORD_GO if reveal else FADE)


func _process(delta: float) -> void:
	if done:
		return
	clock += delta
	if frame != null:
		frame.stretch_shrink = maxi(style.pixel(clock), 1)
		(frame.material as ShaderMaterial).set_shader_parameter("snap", frame.stretch_shrink > 1)
		stage.size = Vector2(viewport.size)
	var over: float
	if ending >= 0.0:
		# Skipped: everything goes at once, quickly.
		var gone: float = ChaosmosIntroStyle.span(clock, ending, ending + SKIP_FADE)
		modulate.a = 1.0 - gone
		over = ending + SKIP_FADE
	elif reveal:
		var end: float = style.settle() + hold()
		var after: float = clock - end
		if after >= 0.0:
			_give_way()
		back.modulate.a = 1.0 - ChaosmosIntroStyle.out_cubic(ChaosmosIntroStyle.span(after, 0.0, BACK_GO))
		front.position.y = ChaosmosIntroStyle.out_bounce(ChaosmosIntroStyle.span(after, 0.0, FALL_TIME)) * FALL * size.y
		front.modulate.a = 1.0 - ChaosmosIntroStyle.span(after, WORD_GO_AT, WORD_GO_AT + WORD_GO)
		over = end + WORD_GO_AT + WORD_GO
	else:
		var end2: float = style.settle() + hold()
		veil.color = Color(style.background(), ChaosmosIntroStyle.span(clock, end2, end2 + FADE))
		over = end2 + FADE
	if cover != null:
		cover.visible = clock < LAUNCH_FADE
		cover.modulate.a = 1.0 - ChaosmosIntroStyle.span(clock, 0.0, LAUNCH_FADE)
		cover.queue_redraw()
	back.queue_redraw()
	stage.queue_redraw()
	if clock >= over:
		_give_way()
		done = true
		finished.emit()


func _give_way() -> void:
	if not gave_way:
		gave_way = true
		giving_way.emit()


func draw_stage(canvas: Control) -> void:
	# Pixel's SubViewport is opaque, so the back behind it never shows: its stage paints the background itself.
	if frame != null:
		canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), style.background())
	word.fit(canvas.size)
	style.draw(canvas, clock, canvas.size)


# The launch screen's colour with its mark in the middle, shrinking as it fades.
func draw_launch(canvas: Control) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), launch_color)
	var shrink: float = lerpf(1.0, LAUNCH_SHRINK, ChaosmosIntroStyle.out_cubic(ChaosmosIntroStyle.span(clock, 0.0, LAUNCH_FADE)))
	draw_mark(canvas, canvas.size * 0.5, launch_mark_width() * shrink)


# How wide the launch screen's mark is on this screen, in this canvas's units.
func launch_mark_width() -> float:
	var view: Vector2 = get_viewport_rect().size
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var dpi: float = float(DisplayServer.screen_get_dpi())
	if window.x <= 0.0 or dpi <= 0.0:
		return view.x * 0.26
	return LAUNCH_MARK_DP * dpi / 160.0 * view.x / window.x


# The studio's mark, the Filling ring: an ink ring half full of coral water, `width` across.
static func draw_mark(canvas: CanvasItem, centre: Vector2, width: float) -> void:
	var mark: ChaosmosWordmark = ChaosmosWordmark.new()
	mark.unit = width / (2.0 * ChaosmosWordmark.O_RADIUS)
	mark.draw_water(canvas, centre, ChaosmosWordmark.CORAL)
	mark.draw_ring(canvas, centre, ChaosmosWordmark.INK)


func _gui_input(event: InputEvent) -> void:
	if skippable and ending < 0.0 and event.is_pressed():
		skip()


func _unhandled_input(event: InputEvent) -> void:
	if skippable and ending < 0.0 and event is InputEventKey and event.is_pressed():
		skip()


func skip() -> void:
	ending = clock
	_give_way()
	create_tween().tween_property(sting, "volume_db", -40.0, SKIP_FADE)
