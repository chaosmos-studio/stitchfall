extends Node

# This machine has no Xvfb, so it opens a window on the real display for a moment.
# Run: DISPLAY=:0 godot --path . res://tools/shotter.tscn -- <scene_path> <frames> <out_name>

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/game/game.tscn"
	var frames: int = int(args[1]) if args.size() > 1 else 120
	var out_name: String = args[2] if args.size() > 2 else "shot"
	# Google Play's build is staged with "play", and the menu banner as a phone would show it with "banner".
	StitchfallShop.on_play = args.has("play")
	StitchfallAds.preview = args.has("banner")
	# Play Games' buttons are staged with "games", by a stand-in that is signed in and sends nothing.
	if args.has("games"):
		StitchfallPlayGames.use(_SignedIn.new())
	var scene: Node = load(scene_path).instantiate()
	add_child(scene)
	if args.has("banner"):
		for room: int in range(3):
			scene.progress.best_stars[room] = maxi(scene.progress.stars(room), 1)
	if args.size() > 3:
		if args[3] == "start":
			scene._on_begin()
		elif args[3] == "levels":
			scene.hud.show_levels()
		elif args[3] == "help":
			scene.hud.show_help()
		elif args[3] == "pause":
			scene._on_begin()
			scene._on_pause()
		elif args[3].begins_with("room="):
			scene._load_level(int(args[3].trim_prefix("room=")))
			scene._on_begin()
		elif args[3] == "skip":
			scene._on_begin()
			scene.room_deaths = StitchfallAdPacing.SKIP_AFTER
			scene._on_pause()
		elif args[3].begins_with("show_"):
			scene.hud.call(args[3])
	for i: int in range(frames):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "user://%s.png" % out_name
	img.save_png(path)
	print("SHOT_SAVED ", ProjectSettings.globalize_path(path))
	get_tree().quit()


class _SignedIn extends Node:
	var signed_in: bool = true

	func show_boards() -> void:
		pass

	func show_achievements() -> void:
		pass

	func progressed() -> void:
		pass

	func progress_reset() -> void:
		pass

	func record_event(_name: String, _properties: Dictionary) -> void:
		pass
