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


# A room for the tools: a room index, or a chapter's id and room number from 1, like "seams/2", which also
# plays a chapter still being built.
static func room_arg(arg: String) -> int:
	if arg.contains("/"):
		var parts: PackedStringArray = arg.split("/")
		return StitchfallLevels.room_of(parts[0], int(parts[1]) - 1)
	return int(arg)


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


# Plays one room by a route in a fresh game and reports whether it was finished, the unravels, the stars
# and the time.
static func replay(tree: SceneTree, room: int, script: String, frames: int = 900) -> Dictionary:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	tree.root.add_child(game)
	await tree.process_frame
	game._load_level(room)
	game._on_begin()
	var steps: Dictionary[int, PackedStringArray] = parse(script)
	var finished: bool = false
	var played: int = 0
	for frame: int in range(frames):
		apply(game, steps, frame)
		await tree.physics_frame
		played += 1
		if game.cleared:
			finished = true
			break
	release_all()
	var stars: int = game.last_result.get("stars", 0)
	# The route's time in physics frames, the same on every machine. The game's own room_time ticks with drawn
	# frames, which a headless replay does not keep in step with physics.
	var time: float = float(played) / float(Engine.physics_ticks_per_second)
	var result: Dictionary = {"finished": finished, "deaths": game.deaths, "stars": stars, "time": time}
	game.queue_free()
	await tree.process_frame
	return result


# Replays a chapter's proofs and returns each check as [name, passed]: every room is finished by its route
# without an unravel, with all three stars and a par about its time times 1.5, and from the second room on
# its prank catches the obvious run ("hit": the runner unravels, "stuck": the room is not finished).
static func prove(tree: SceneTree, id: String) -> Array[Array]:
	var checks: Array[Array] = []
	var chapter: GDScript = StitchfallLevels.chapter_script(id)
	var routes: Array[Dictionary] = chapter.ROUTES
	checks.append(["every room in %s has a route" % chapter.NAME, routes.size() == StitchfallLevels.CHAPTER_ROOMS])
	for number: int in range(routes.size()):
		var proof: Dictionary = routes[number]
		var room: int = StitchfallLevels.room_of(id, number)
		var label: String = "%s %d" % [chapter.NAME, number + 1]
		var solved: Dictionary = await replay(tree, room, proof["route"])
		checks.append(["%s is finished by its route without an unravel" % label, solved["finished"] and solved["deaths"] == 0])
		checks.append(["%s's route earns all three stars inside par" % label, solved["stars"] == 3])
		var par: float = StitchfallLevels.get_level(room)["par"]
		var target: float = float(solved["time"]) * 1.5
		checks.append(["%s's par %.0f is about its route's %.2f s times 1.5" % [label, par, solved["time"]], par >= target - 0.5 and par <= target + 1.5])
		if number > 0:
			checks.append(["%s gives its prank an obvious run to catch" % label, proof.has("naive")])
		if proof.has("naive"):
			var naive: Dictionary = await replay(tree, room, proof["naive"])
			var caught: bool = naive["deaths"] > 0 if proof["caught"] == "hit" else not naive["finished"]
			checks.append(["%s's prank catches the obvious run" % label, caught and not naive["finished"]])
	return checks
