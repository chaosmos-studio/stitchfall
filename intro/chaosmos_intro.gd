class_name ChaosmosIntro
extends Control

# The Chaosmos intro a game opens on: a style brings the wordmark in with its sting, holds it, and lets go. A tap
# or a key skips it. Add it full screen and wait for `finished`.
#
# It draws in two layers, the back (the sky, cloth or glass a style plays on) and the style over it. In a game the
# word leaves first, on its own back: it swells, then spins and squeezes into the studio's mark until only a coral
# dot is left. The dot opens into a ring that grows across the screen, and the game's Home shows through the hole
# it cuts in the back. The word is never drawn over Home.
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
# In a game the word holds less, then swells by SWELL_BY over SWELL, and squeezes into the ring of its first o over
# COLLAPSE, turning by TWIST radians as it goes. The coral dot left behind grows to POP of the ring's size, then
# opens over OPEN into a coral ring EDGE of the screen's width thick, thinning as it grows past the corners, with
# Home showing inside it. A word left over a loaded Home reads as a stall, so the word is gone before Home shows.
const REVEAL_HOLD: float = 0.45
const SWELL: float = 0.1
const SWELL_BY: float = 0.06
const COLLAPSE: float = 0.22
const TWIST: float = -0.6
const POP: float = 0.55
const OPEN: float = 0.42
# The dot pops this long before it starts to open.
const POP_WAIT: float = 0.04
const EDGE: float = 0.05
# A skipped intro in a game collapses and opens this much faster, rather than fading over Home.
const SKIP_SPEED: float = 1.8
const IRIS: Shader = preload("res://intro/iris.gdshader")
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


class ChaosmosOpening extends Control:
	var intro: ChaosmosIntro

	func _draw() -> void:
		intro.draw_opening(self)


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
# In a game: the coral dot and ring the word leaves through, and where they are now, in this control's units.
var opening: ChaosmosOpening
var pivot: Vector2 = Vector2.ZERO
var dot: float = 0.0
var hole: float = 0.0
var rim: float = 0.0


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
	if reveal:
		var iris: ShaderMaterial = ShaderMaterial.new()
		iris.shader = IRIS
		back.material = iris
		opening = ChaosmosOpening.new()
		opening.intro = self
		_fill(opening)
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
	return style.settle() + hold() + (leaving() if reveal else FADE)


# How long a game's intro takes to leave once it has held: the collapse, then the opening.
static func leaving() -> float:
	return SWELL + COLLAPSE + POP_WAIT + OPEN


func _process(delta: float) -> void:
	if done:
		return
	clock += delta
	if frame != null:
		frame.stretch_shrink = maxi(style.pixel(clock), 1)
		(frame.material as ShaderMaterial).set_shader_parameter("snap", frame.stretch_shrink > 1)
		stage.size = Vector2(viewport.size)
	var over: float
	if reveal:
		# Skipped, it leaves at once, and quicker.
		var start: float = style.settle() + hold()
		var speed: float = 1.0
		if ending >= 0.0:
			start = minf(start, ending)
			speed = SKIP_SPEED
		_leave((clock - start) * speed)
		over = start + leaving() / speed
	elif ending >= 0.0:
		# Skipped: everything goes at once, quickly.
		var gone: float = ChaosmosIntroStyle.span(clock, ending, ending + SKIP_FADE)
		modulate.a = 1.0 - gone
		over = ending + SKIP_FADE
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


# A game's intro leaving, `after` seconds into it: the word collapses into the ring of its first o, a coral dot pops
# where it went, and opens into a ring with Home inside it.
func _leave(after: float) -> void:
	var mark: ChaosmosWordmark = ChaosmosWordmark.new()
	mark.fit(size)
	pivot = mark.ring_centre()
	var grow: float = 1.0 + SWELL_BY * ChaosmosIntroStyle.out_cubic(ChaosmosIntroStyle.span(after, 0.0, SWELL))
	var squeeze: float = ChaosmosIntroStyle.span(after, SWELL, SWELL + COLLAPSE)
	var pull: float = squeeze * squeeze * squeeze
	front.pivot_offset = pivot
	front.scale = Vector2.ONE * grow * (1.0 - pull)
	front.rotation = TWIST * pull
	front.visible = squeeze < 1.0
	var gone: float = SWELL + COLLAPSE
	dot = ChaosmosWordmark.O_RADIUS * mark.unit * POP * ChaosmosIntroStyle.out_back(
		ChaosmosIntroStyle.span(after, gone - 0.06, gone + 0.08))
	var open: float = ChaosmosIntroStyle.span(after, gone + POP_WAIT, gone + POP_WAIT + OPEN)
	if open > 0.0:
		_give_way()
	var reach: float = maxf(pivot.length(), (size - pivot).length())
	reach = maxf(reach, maxf(Vector2(size.x - pivot.x, pivot.y).length(), Vector2(pivot.x, size.y - pivot.y).length()))
	hole = ChaosmosIntroStyle.out_cubic(open) * (reach + EDGE * size.x)
	rim = maxf(dot, hole + EDGE * size.x * (1.0 - 0.7 * open))
	var iris: ShaderMaterial = back.material as ShaderMaterial
	iris.set_shader_parameter("centre", pivot)
	iris.set_shader_parameter("radius", hole)
	opening.queue_redraw()


# The coral dot, and once it opens, the coral band between the hole and the rim.
func draw_opening(canvas: Control) -> void:
	if rim <= 0.0:
		return
	if hole <= 0.5:
		canvas.draw_circle(pivot, rim, ChaosmosWordmark.CORAL, true, -1.0, true)
		return
	canvas.draw_arc(pivot, (hole + rim) * 0.5, 0.0, TAU, 160, ChaosmosWordmark.CORAL, rim - hole, true)


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
