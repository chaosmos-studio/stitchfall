class_name ChaosmosIntro
extends Control

# The Chaosmos intro a game opens on: a style brings the wordmark in with its sting, holds it, and fades to
# the game. A tap or a key skips it. Add it full screen and wait for `finished`.
#
# The style draws into a SubViewport, so a style can ask for big pixels (Pixel) by shrinking it: the stage
# renders at a fraction of the screen and is shown enlarged without smoothing.

signal finished

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
const PIXEL_SNAP: Shader = preload("res://intro/pixel_snap.gdshader")


class Stage extends Control:
	var intro: ChaosmosIntro

	func _draw() -> void:
		intro.draw_stage(self)


@export var style_name: String = "fill"
@export var dark: bool = false
# Off in the preview renders, so a recording plays every frame of the style.
@export var skippable: bool = true

var style: ChaosmosIntroStyle
var word: ChaosmosWordmark = ChaosmosWordmark.new()
var clock: float = 0.0
var ending: float = -1.0
var done: bool = false
var sting: AudioStreamPlayer
var frame: SubViewportContainer
var viewport: SubViewport
var stage: Stage
var veil: ColorRect


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
	frame = SubViewportContainer.new()
	frame.stretch = true
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var snapping: ShaderMaterial = ShaderMaterial.new()
	snapping.shader = PIXEL_SNAP
	snapping.set_shader_parameter("paper", style.background())
	snapping.set_shader_parameter("ink", style.ink)
	snapping.set_shader_parameter("coral", style.coral)
	frame.material = snapping
	add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport = SubViewport.new()
	frame.add_child(viewport)
	stage = Stage.new()
	stage.intro = self
	viewport.add_child(stage)
	veil = ColorRect.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color(style.background(), 0.0)
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sting = AudioStreamPlayer.new()
	add_child(sting)
	var sound: String = style.sting()
	if not sound.is_empty() and ResourceLoader.exists(sound):
		sting.stream = load(sound) as AudioStream
		sting.play()


func total() -> float:
	return style.settle() + HOLD + FADE


func _process(delta: float) -> void:
	if done:
		return
	clock += delta
	var end: float = ending if ending >= 0.0 else style.settle() + HOLD
	var fade: float = SKIP_FADE if ending >= 0.0 else FADE
	veil.color = Color(style.background(), clampf((clock - end) / fade, 0.0, 1.0))
	frame.stretch_shrink = maxi(style.pixel(clock), 1)
	(frame.material as ShaderMaterial).set_shader_parameter("snap", frame.stretch_shrink > 1)
	stage.size = Vector2(viewport.size)
	stage.queue_redraw()
	if clock >= end + fade:
		done = true
		finished.emit()


func draw_stage(canvas: Control) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), style.background())
	word.fit(canvas.size)
	style.draw(canvas, clock, canvas.size)


func _gui_input(event: InputEvent) -> void:
	if skippable and ending < 0.0 and event.is_pressed():
		skip()


func _unhandled_input(event: InputEvent) -> void:
	if skippable and ending < 0.0 and event is InputEventKey and event.is_pressed():
		skip()


func skip() -> void:
	ending = clock
	create_tween().tween_property(sting, "volume_db", -40.0, SKIP_FADE)
