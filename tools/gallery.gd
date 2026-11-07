extends Node

# Plays a room by a short script and saves one frame, for the website, the blog and the press kit.
# Run with --fixed-fps 60 so every frame steps the game by the same time:
#   DISPLAY=:0 godot --path . --fixed-fps 60 res://tools/gallery.tscn -- <name> <room> "<frame>:<step>,..."
# The room is an index or a chapter room like "seams/2".
# Steps: a route's steps (shift, +action, -action), levels to open the level select, hud=<method>[/<arg>] to
# open a page, wear=<kind>/<piece> to dress the runner, and shot to save the frame.
# The PNG lands in user://gallery/<name>.png.

func _ready() -> void:
	StitchfallProgress.path = "user://gallery_progress.cfg"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_name: String = args[0]
	var room: int = StitchfallRoute.room_arg(args[1])
	var steps: Dictionary[int, PackedStringArray] = {}
	var last: int = 0
	for entry: String in args[2].split(","):
		var parts: PackedStringArray = entry.split(":")
		var frame: int = int(parts[0])
		var list: PackedStringArray = steps.get(frame, PackedStringArray())
		list.append(parts[1])
		steps[frame] = list
		last = maxi(last, frame)
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game._load_level(room)
	game._on_begin()
	for frame: int in range(last + 1):
		StitchfallRoute.apply(game, steps, frame)
		for step: String in steps.get(frame, PackedStringArray()):
			if step == "levels":
				game._on_levels()
			elif step.begins_with("hud="):
				# hud=<method>/<argument>/..., to open a page for its picture. Whole-number arguments pass as ints.
				var call: PackedStringArray = step.substr(4).split("/")
				var arguments: Array = []
				for argument: String in call.slice(1):
					arguments.append(argument.to_int() if argument.is_valid_int() else argument)
				game.hud.callv(call[0], arguments)
			elif step.begins_with("wear="):
				# wear=<kind>/<piece>, to dress the runner for a picture.
				var piece: PackedStringArray = step.substr(5).split("/")
				game.progress.wear[piece[0]] = piece[1]
				game._apply_wardrobe()
			elif step == "shot":
				await RenderingServer.frame_post_draw
				var img: Image = get_viewport().get_texture().get_image()
				DirAccess.make_dir_recursive_absolute("user://gallery")
				img.save_png("user://gallery/%s.png" % out_name)
				print("GALLERY_SAVED ", ProjectSettings.globalize_path("user://gallery/%s.png" % out_name))
		await get_tree().process_frame
	get_tree().quit()
