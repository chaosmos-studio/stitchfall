class_name StitchfallRoute
extends RefCounted

# A route is a room played by a short script of physics frames and steps, written "frame:step,frame:step".
# Steps: shift, +action and -action to hold and let go of an input action. tests/run_tests.gd replays each
# screen room's route to prove it can be finished, and its naive route to prove its prank catches you.


static func parse(script: String) -> Dictionary[int, PackedStringArray]:
	var steps: Dictionary[int, PackedStringArray] = {}
	for entry: String in script.split(",", false):
		var parts: PackedStringArray = entry.strip_edges().split(":")
		var frame: int = int(parts[0])
		var list: PackedStringArray = steps.get(frame, PackedStringArray())
		list.append(parts[1])
		steps[frame] = list
	return steps


static func last_frame(steps: Dictionary[int, PackedStringArray]) -> int:
	var last: int = 0
	for frame: int in steps:
		last = maxi(last, frame)
	return last


# Applies one frame's steps to a running game. The shift cooldown is wall-clock time, so a replay clears it.
static func apply(game: Node, steps: Dictionary[int, PackedStringArray], frame: int) -> void:
	for step: String in steps.get(frame, PackedStringArray()):
		if step == "shift":
			game.last_shift = -1.0
			game._shift(1)
		elif step.begins_with("+"):
			Input.action_press(step.substr(1))
		elif step.begins_with("-"):
			Input.action_release(step.substr(1))


static func release_all() -> void:
	for action: String in ["move_left", "move_right", "jump", "crouch"]:
		Input.action_release(action)
