extends Node

# Plays a room by a short script and saves one frame, for the website, the blog and the press kit.
# Run with --fixed-fps 60 so every frame steps the game by the same time:
#   DISPLAY=:0 godot --path . --fixed-fps 60 res://tools/gallery.tscn -- <name> <room> "<frame>:<step>,..."
# Steps: shift, +action and -action to hold and let go of an input action, and shot to save the frame.
# The PNG lands in user://gallery/<name>.png.

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_name: String = args[0]
	var room: int = int(args[1])
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
		for step: String in steps.get(frame, PackedStringArray()):
			if step == "shift":
				game._shift(1)
			elif step.begins_with("+"):
				Input.action_press(step.substr(1))
			elif step.begins_with("-"):
				Input.action_release(step.substr(1))
			elif step == "shot":
				await RenderingServer.frame_post_draw
				var img: Image = get_viewport().get_texture().get_image()
				DirAccess.make_dir_recursive_absolute("user://gallery")
				img.save_png("user://gallery/%s.png" % out_name)
				print("GALLERY_SAVED ", ProjectSettings.globalize_path("user://gallery/%s.png" % out_name))
		await get_tree().process_frame
	get_tree().quit()
