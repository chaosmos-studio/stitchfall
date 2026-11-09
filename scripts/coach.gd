class_name StitchfallCoach
extends Control

# The first room's coach: one sewn card at a time over the room's empty top, teaching a control by having the player
# do it. A step ends when the game says the runner did it (done), never on a timer, so nobody is rushed. The card
# shows a gesture on a touch screen and the keys on a computer. The room's clock stands still while it coaches, so
# learning never costs the Quick star.

signal finished

const INK: Color = Color("493a37")
const ACCENT: Color = Color("a85648")
const FONT: FontFile = preload("res://assets/fonts/Darn-UI.ttf")
const BOLD: FontFile = preload("res://assets/fonts/Threadline-Satin.ttf")
const GESTURE_GUIDE: Script = preload("res://scripts/gesture_guide.gd")
const BORDER_SCRIPT: GDScript = preload("res://scripts/stitch_border.gd")
const SIZE: Vector2 = Vector2(1040, 220)
# The gesture is drawn this much larger than on the guide page, so a thumb reads it at a glance.
const GESTURE_SCALE: float = 1.3
# How long a done step shows its tick before the next card comes in, and how long the last card stays.
const PRAISE_SECONDS: float = 0.7
const GOAL_SECONDS: float = 4.0
# Each step: what ends it, the line on a touch screen, the line with keys, and the gesture drawn beside it.
const STEPS: Array[Dictionary] = [
	{"id": "move", "touch": "Hold and slide to run", "keys": "Hold A or D to run", "gesture": "move"},
	{"id": "jump", "touch": "Swipe up to jump", "keys": "Press W or Space to jump", "gesture": "jump"},
	{"id": "turn", "touch": "Tap to turn the room", "keys": "Press Shift to turn the room", "gesture": "shift"},
	{"id": "floor", "touch": "Tap until you're back on the floor", "keys": "Shift until you're back on the floor", "gesture": "shift"},
	{"id": "goal", "touch": "Gather the buttons, then slip out through the zipper", "keys": "Gather the buttons, then slip out through the zipper", "gesture": ""},
]
const PRAISE: PackedStringArray = ["Nice.", "Up you go.", "The whole room turns.", "Back on your feet."]

# Off in the capture tool unless it asks, so a room's pictures stay clean, and in a headless test run.
static var enabled: bool = true

var step: int = -1
# Steps already learned this session, so a coach that carries over into the next room skips them.
var learned: Dictionary[String, bool] = {}
var touch: bool = true
var card: Panel
var line: Label
var counter: Label
var tick: Label
var gesture: StitchfallGestureGuide
var motion: Tween
var waiting: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = SIZE
	pivot_offset = SIZE * 0.5
	card = Panel.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("f7edda", 0.96)
	style.border_color = Color("947a65")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.shadow_color = Color("45372f", 0.22)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border: Control = BORDER_SCRIPT.new() as Control
	card.add_child(border)
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gesture = GESTURE_GUIDE.new() as StitchfallGestureGuide
	gesture.size = Vector2(300, 150)
	gesture.pivot_offset = gesture.size * 0.5
	gesture.scale = Vector2.ONE * GESTURE_SCALE
	gesture.position = Vector2(46, (SIZE.y - gesture.size.y) * 0.5)
	card.add_child(gesture)
	# A small kicker (which lesson of how many), then the lesson in one or two lines under it.
	counter = _label(Vector2(400, 22), Vector2(600, 36), 26, ACCENT, BOLD)
	line = _label(Vector2(400, 60), Vector2(600, 136), 46, INK, FONT)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tick = _label(Vector2(0, 0), SIZE, 62, Color("5f8b5a"), BOLD)
	tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visible = false


func _label(at: Vector2, extent: Vector2, font_size: int, color: Color, font: FontFile) -> Label:
	var label: Label = Label.new()
	label.position = at
	label.size = extent
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	card.add_child(label)
	return label


func begin(on_touch: bool) -> void:
	touch = on_touch
	step = -1
	waiting = false
	visible = true
	_next()


func coaching() -> bool:
	return visible and step >= 0 and step < STEPS.size() - 1


# The lesson on the card now, or "" when none is.
func current() -> String:
	return String(STEPS[step]["id"]) if visible and not waiting and step >= 0 and step < STEPS.size() else ""


func stop() -> void:
	if motion != null:
		motion.kill()
	visible = false
	step = -1
	waiting = false


# The game tells the coach what the runner just did. Only the step on the card counts.
func done(id: String) -> void:
	if not visible or waiting or step < 0 or step >= STEPS.size() or STEPS[step]["id"] != id:
		return
	waiting = true
	learned[id] = true
	tick.text = PRAISE[mini(step, PRAISE.size() - 1)]
	_swap(true)
	if motion != null:
		motion.kill()
	motion = create_tween()
	motion.tween_interval(PRAISE_SECONDS)
	motion.tween_callback(_next)


func _next() -> void:
	step += 1
	while step < STEPS.size() - 1 and learned.has(String(STEPS[step]["id"])):
		step += 1
	waiting = false
	if step >= STEPS.size():
		_leave()
		return
	var data: Dictionary = STEPS[step]
	line.text = data["touch"] if touch else data["keys"]
	gesture.kind = data["gesture"]
	gesture.visible = touch and not String(data["gesture"]).is_empty()
	# Without a gesture the line takes the whole card.
	line.position.x = 400.0 if gesture.visible else 60.0
	line.size.x = 600.0 if gesture.visible else SIZE.x - 120.0
	counter.position.x = line.position.x
	var lessons: int = STEPS.size() - 1
	counter.text = "LESSON %d OF %d" % [step + 1, lessons] if step < lessons else "YOUR TURN"
	_swap(false)
	_arrive()
	if step == STEPS.size() - 1:
		motion.tween_interval(GOAL_SECONDS)
		motion.tween_callback(_leave)


# The tick replaces the lesson while a done step is praised.
func _swap(praising: bool) -> void:
	tick.visible = praising
	line.visible = not praising
	counter.visible = not praising
	gesture.visible = not praising and touch and step < STEPS.size() and not String(STEPS[step]["gesture"]).is_empty()


# A card arrives fast and settles, the way a patch is slapped down and smoothed.
func _arrive() -> void:
	if motion != null:
		motion.kill()
	scale = Vector2.ONE * 0.92
	modulate.a = 0.0
	motion = create_tween().set_parallel(true)
	motion.tween_property(self, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	motion.tween_property(self, "modulate:a", 1.0, 0.18)
	# Whatever the caller adds after this waits for the arrival.
	motion.set_parallel(false)


# And leaves accelerating, then tells the game the lessons are over.
func _leave() -> void:
	if motion != null:
		motion.kill()
	motion = create_tween().set_parallel(true)
	motion.tween_property(self, "scale", Vector2.ONE * 0.94, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	motion.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	motion.chain().tween_callback(func() -> void:
		visible = false
		step = -1
		finished.emit())
