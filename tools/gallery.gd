extends Node

# Plays a room by a short script and saves one frame, for the website, the blog and the press kit.
# Run with --fixed-fps 60 so every frame steps the game by the same time:
#   DISPLAY=:0 godot --path . --fixed-fps 60 res://tools/gallery.tscn -- <name> <room> "<frame>:<step>,..."
# The room is an index or a chapter room like "seams/2". A fourth argument, hd, renders offscreen at the
# game's full 1920 by 1080 whatever the window's size, for store images.
# Steps: a route's steps (shift, +action, -action), levels to open the level select, hud=<method>[/<arg>] to
# open a page, wear=<kind>/<piece> to dress the runner, 0:play to show the Google Play build's pages, 0:touch to
# draw the HUD as a phone does (run with --resolution at a phone's shape, such as 1200x540 for 20:9), 0:coach to
# let the first room's coach teach (it is off otherwise), 0:banner to draw the banner's stand-in, 0:sewn=N to
# start with the first N rooms sewn, shot to
# save the frame, and snap to save it as <name>_<frame>, for choosing a moment among several.
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
	var host: Node = self
	if args.size() > 3 and args[3] == "hd":
		var view: SubViewport = SubViewport.new()
		view.size = Vector2i(1920, 1080)
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(view)
		host = view
	# Pages are built as the game loads, so the Play build's pages need the switch before it, and so does a phone's
	# HUD (0:touch).
	StitchfallShop.on_play = args[2].split(",").has("0:play")
	StitchfallHud.touch_preview = args[2].split(",").has("0:touch")
	# The first room's coach only when a picture is of it (0:coach), so other pictures of the room stay clean.
	StitchfallCoach.enabled = args[2].split(",").has("0:coach")
	StitchfallStudioIntro.enabled = false
	# 0:banner draws the banner's stand-in where a phone's banner would be, and 0:sewn=N starts with the first N
	# rooms sewn, so the pages show the banner (it waits for a few sewn rooms) and some stars.
	StitchfallAds.preview = args[2].split(",").has("0:banner")
	for token: String in args[2].split(","):
		if token.begins_with("0:sewn="):
			var seeded: StitchfallProgress = StitchfallProgress.new()
			seeded.coached = true
			for sewn_room: int in range(token.substr(7).to_int()):
				seeded.best_stars[sewn_room] = 3 if sewn_room % 4 != 2 else 2
			seeded.save()
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	host.add_child(game)
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
				var piece: PackedStringArray = step.substr(5).split("/")
				game.progress.wear[piece[0]] = piece[1]
				game._apply_wardrobe()
			elif step == "shot" or step == "snap":
				await RenderingServer.frame_post_draw
				var img: Image = game.get_viewport().get_texture().get_image()
				DirAccess.make_dir_recursive_absolute("user://gallery")
				var file: String = out_name if step == "shot" else "%s_%d" % [out_name, frame]
				img.save_png("user://gallery/%s.png" % file)
				print("GALLERY_SAVED ", ProjectSettings.globalize_path("user://gallery/%s.png" % file))
		await get_tree().process_frame
	get_tree().quit()
