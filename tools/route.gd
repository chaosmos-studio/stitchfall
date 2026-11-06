extends SceneTree

# Replays a route in one room and prints where the runner goes, for designing rooms against the real physics:
#   godot --headless --path . -s res://tools/route.gd -- <room> "<frame>:<step>,..." [frames]
# Prints the runner every 15 frames, every button, pop-up, flee and hit, and whether the room was finished.

func _initialize() -> void:
	_run()


func _run() -> void:
	StitchfallProgress.path = "user://route_progress.cfg"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var room: int = int(args[0])
	var steps: Dictionary[int, PackedStringArray] = StitchfallRoute.parse(args[1] if args.size() > 1 else "")
	var frames: int = int(args[2]) if args.size() > 2 else StitchfallRoute.last_frame(steps) + 240
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game._load_level(room)
	game._on_begin()
	var deaths: int = game.deaths
	for frame: int in range(frames):
		StitchfallRoute.apply(game, steps, frame)
		await physics_frame
		if game.cleared:
			print("ROUTE finished room %d at frame %d, %.2f s, stars %d" % [room, frame, game.room_time, game.last_result["stars"]])
			break
		if game.deaths != deaths:
			deaths = game.deaths
			print("ROUTE hit at frame %d near %s" % [frame, game.pilot.position.round()])
		if frame % 15 == 0:
			var pins: Array[Vector2] = []
			for pin: StitchfallPin in game.pins:
				pins.append(pin.position.round())
			print("ROUTE f%d pos %s g %s buttons %s pins %s" % [frame, game.pilot.position.round(), game.gravity_direction, game.collected, pins])
	StitchfallRoute.release_all()
	print("ROUTE done: room %d, deaths %d, level now %d" % [room, game.deaths, game.level_index])
	quit()
