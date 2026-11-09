class_name StitchfallSwipeThread
extends Control

# While a finger slides on the room, a running stitch is drawn from where it landed to where it is, so the
# player sees the slide being read. It is faint until the slide means something, then takes the move's colour:
# cream to run, gold to jump, blue to crouch.

const KNOT: float = 10.0
const STITCH: float = 16.0
const SHADOW: Color = Color(0.16, 0.11, 0.08, 0.35)
const COLOURS: Dictionary[String, Color] = {
	"": Color(1.0, 0.97, 0.9, 0.45),
	"move": Color("fff4dc"),
	"jump": Color("f3c25a"),
	"crouch": Color("9cc4d6"),
}

# Each finger on the room: where it landed ("origin"), where it is ("now") and what its slide means ("mode").
var fingers: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_fingers(touches: Array) -> void:
	fingers.clear()
	for touch: Dictionary in touches:
		fingers.append(touch)
	queue_redraw()


func _draw() -> void:
	for finger: Dictionary in fingers:
		var origin: Vector2 = finger["origin"]
		var now: Vector2 = finger.get("now", origin)
		var mode: String = finger.get("mode", "")
		var colour: Color = COLOURS.get(mode, COLOURS[""])
		draw_circle(origin + Vector2(1, 2), KNOT, SHADOW)
		draw_circle(origin, KNOT, colour)
		var length: float = origin.distance_to(now)
		if length < KNOT:
			continue
		var direction: Vector2 = (now - origin) / length
		var at: float = KNOT + 4.0
		while at < length:
			var from: Vector2 = origin + direction * at
			var to: Vector2 = origin + direction * minf(at + STITCH * 0.55, length)
			draw_line(from + Vector2(1, 2), to + Vector2(1, 2), SHADOW, 6.0, true)
			draw_line(from, to, colour, 4.0, true)
			at += STITCH
		draw_circle(now, 6.0, colour)
