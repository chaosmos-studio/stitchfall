class_name StitchfallTrail
extends Node2D

# A length of thread paid out behind the runner, the wardrobe's trail. It keeps the last stretch of the
# runner's path and fades toward its tail.

const LENGTH: int = 28
const SPACING: float = 7.0
const WIDTH: float = 5.0

var follow: Node2D
var colours: Array = []
var dashed: bool = false
var points: PackedVector2Array = PackedVector2Array()


func configure(target: Node2D, style: Dictionary) -> void:
	follow = target
	colours = style.get("colours", [])
	dashed = style.get("dashed", false)
	z_index = 4
	visible = not colours.is_empty()


func clear() -> void:
	points.clear()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not visible or not is_instance_valid(follow) or not follow.visible:
		return
	var tip: Vector2 = follow.position + Vector2(0, 6).rotated(follow.rotation)
	if points.is_empty() or points[points.size() - 1].distance_to(tip) >= SPACING:
		points.append(tip)
		if points.size() > LENGTH:
			points.remove_at(0)
		queue_redraw()


func _draw() -> void:
	for index: int in range(points.size() - 1):
		if dashed and index % 2 == 1:
			continue
		var fade: float = float(index + 1) / float(points.size())
		var colour: Color = colours[index % colours.size()] if colours.size() > 1 else colours[0]
		draw_line(points[index], points[index + 1], Color(colour, fade * 0.9), WIDTH * (0.4 + fade * 0.6), true)
