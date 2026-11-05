extends SceneTree

# Run: godot --headless --path . -s res://tests/run_tests.gd
# CI greps for "0 failed", so keep that wording.

const InputMapGen: GDScript = preload("res://tools/make_input_map.gd")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_input_map_is_wired()
	_test_orientation_is_an_int()
	await _test_movement_feel()
	await _test_environment_forces()
	await _test_gesture_controls()
	await _test_timed_gate_and_bloom()
	await _test_moving_ferry_lifecycle()
	await _test_proximity_pulley()
	await _test_fraying_ledge()
	await _test_phase_buttons()
	_test_room_clearance()
	await _test_cargo_route()
	await _test_opening_route()
	await _test_palewheel_playthrough()
	print("\n==== TESTS: %d passed, %d failed ====" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _check(name: String, cond: bool) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		print("  FAIL: ", name)

# An action can exist with zero events, and then every is_action_pressed() silently returns false.
func _test_input_map_is_wired() -> void:
	var table: Dictionary = InputMapGen.bindings()
	for action: String in table:
		_check("action %s exists, re-run tools/make_input_map.gd" % action, InputMap.has_action(action))
		if InputMap.has_action(action):
			_check("action %s has bindings" % action, InputMap.action_get_events(action).size() > 0)

# A string here converts to 0, which is Landscape, whatever the string said.
func _test_orientation_is_an_int() -> void:
	var value: Variant = ProjectSettings.get_setting("display/window/handheld/orientation")
	_check("handheld orientation is stored as an int, re-run tools/configure_project.gd",
		typeof(value) == TYPE_INT)


func _test_movement_feel() -> void:
	var pilot: PalewheelCourier = PalewheelCourier.new()
	pilot.control_enabled = false
	root.add_child(pilot)
	await process_frame
	var momentum: Vector2 = Vector2(120, -220)
	pilot.velocity = momentum
	pilot.set_gravity_direction(Vector2.LEFT)
	_check("gravity turns preserve incoming momentum", pilot.velocity.is_equal_approx(momentum))
	_check("the pilot art begins its turn from the previous world angle", absf(pilot.sprite.global_rotation) < 0.02)
	_check("touch jump supports a release", pilot.has_method("release_touch_jump"))
	if pilot.has_method("release_touch_jump"):
		pilot.set_gravity_direction(Vector2.DOWN)
		pilot.velocity = Vector2(0, -500)
		pilot.control_enabled = true
		pilot.release_touch_jump()
		await physics_frame
		await physics_frame
		_check("releasing jump reduces upward speed", pilot.velocity.y > -400.0)
	pilot.queue_free()
	await process_frame
	var inverted: PalewheelCourier = PalewheelCourier.new()
	inverted.position = Vector2(2200, 350)
	root.add_child(inverted)
	await process_frame
	inverted.set_gravity_direction(Vector2.UP)
	inverted.touch_axis = 1.0
	await physics_frame
	await physics_frame
	_check("a right slide moves right on the ceiling", inverted.velocity.x > 0.0)
	inverted.queue_free()
	await process_frame


func _test_moving_ferry_lifecycle() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game._load_level(3)
	game._on_begin()
	_check("the wide room starts its moving hem", game.ferries.size() == 1 and game.ferries[0].active)
	var start: Vector2 = game.ferries[0].position
	for frame: int in range(20):
		await physics_frame
	_check("the moving hem travels after play begins", game.ferries[0].position.distance_to(start) > 10.0)
	game.pilot.position = game.ferries[0].position + Vector2(0, -55)
	game.pilot.velocity = Vector2.ZERO
	game.pilot.reset_physics_interpolation()
	for frame: int in range(14):
		await physics_frame
	var rider_offset: float = game.pilot.position.x - game.ferries[0].position.x
	for frame: int in range(20):
		await physics_frame
	_check("the moving hem carries its rider", absf((game.pilot.position.x - game.ferries[0].position.x) - rider_offset) < 35.0)
	game._on_pause()
	_check("the moving hem stops while paused", not game.ferries[0].active)
	game._restart()
	_check("the moving hem restarts with the room", game.ferries[0].active)
	game.queue_free()
	await process_frame


func _test_proximity_pulley() -> void:
	var pulley: PalewheelMechanism = PalewheelMechanism.new()
	pulley.configure({
		"kind": "pulley",
		"from": Vector2(600, 280),
		"to": Vector2(600, 720),
		"anchor": Vector2(600, 210),
		"period": 3.0,
		"trigger": Vector2(400, 820),
		"trigger_radius": 110.0,
	})
	root.add_child(pulley)
	pulley.active = true
	for frame: int in range(10):
		await physics_frame
	_check("the marked pulley waits for the runner", pulley.position == Vector2(600, 280))
	var runner: PalewheelCourier = PalewheelCourier.new()
	runner.control_enabled = false
	runner.position = Vector2(400, 820)
	root.add_child(runner)
	for frame: int in range(3):
		await physics_frame
	_check("approaching the mark warns before the pulley falls", pulley.warning > 0.0)
	for frame: int in range(48):
		await physics_frame
	_check("the marked pulley moves after its warning", pulley.position.y > 300.0)
	runner.queue_free()
	await process_frame
	pulley.reset()
	_check("retry restores the marked pulley", pulley.position == Vector2(600, 280) and pulley.warning == 0.0)
	pulley.queue_free()
	await process_frame


func _test_fraying_ledge() -> void:
	var script: GDScript = load("res://scripts/fray_ledge.gd") as GDScript
	_check("a fraying ledge has a reusable physics body", script != null)
	if script == null:
		return
	var ledge: StaticBody2D = script.new() as StaticBody2D
	ledge.configure({"rect": Rect2(400, 650, 260, 28), "delay": 0.35})
	root.add_child(ledge)
	ledge.active = true
	var runner: PalewheelCourier = PalewheelCourier.new()
	runner.control_enabled = false
	runner.position = Vector2(500, 595)
	root.add_child(runner)
	for frame: int in range(5):
		await physics_frame
	_check("the fraying ledge warns before tearing", ledge.countdown > 0.0 and not ledge.collapsed)
	for frame: int in range(30):
		await physics_frame
	_check("the fraying ledge opens after its warning", ledge.collapsed and ledge.collision_shape.disabled)
	ledge.reset()
	await physics_frame
	_check("retry sews the fraying ledge closed", not ledge.collapsed and not ledge.collision_shape.disabled)
	runner.queue_free()
	ledge.queue_free()
	await process_frame


func _test_environment_forces() -> void:
	var dry: PalewheelCourier = PalewheelCourier.new()
	var wet: PalewheelCourier = PalewheelCourier.new()
	dry.position = Vector2(2200, 350)
	wet.position = Vector2(2600, 350)
	root.add_child(dry)
	root.add_child(wet)
	await process_frame
	_check("the pilot accepts an authored environment zone", wet.has_method("set_environment"))
	if wet.has_method("set_environment"):
		wet.call("set_environment", "water", Rect2(2500, 200, 220, 500))
		for frame: int in range(12):
			await physics_frame
		_check("water slows a fall", wet.velocity.y < dry.velocity.y * 0.55)
		wet.velocity = Vector2.ZERO
		dry.velocity = Vector2.ZERO
		wet.call("set_environment", "space", Rect2(2500, 200, 220, 500))
		for frame: int in range(12):
			await physics_frame
		_check("orbit gravity lengthens a fall", wet.velocity.y < dry.velocity.y * 0.45)
		wet.velocity = Vector2.ZERO
		dry.velocity = Vector2.ZERO
		wet.call("set_environment", "rain", Rect2(2500, 200, 220, 500))
		for frame: int in range(12):
			await physics_frame
		_check("rain gust pushes the pilot across the field", wet.velocity.x > dry.velocity.x + 35.0)
		wet.velocity = Vector2(300, 0)
		dry.velocity = Vector2(300, 0)
		wet.call("set_environment", "frost", Rect2(2500, 200, 220, 500))
		for frame: int in range(12):
			await physics_frame
		_check("frost preserves horizontal momentum", wet.velocity.x > dry.velocity.x + 40.0)
	dry.queue_free()
	wet.queue_free()
	await process_frame


func _test_gesture_controls() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	var guide_count: int = 0
	for child: Node in game.hud.help_page.find_children("*", "Control", true, false):
		if child is PalewheelGestureGuide:
			guide_count += 1
	_check("the guide illustrates all four phone gestures", guide_count == 4)
	game._on_begin()
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(500, 500)
	press.pressed = true
	game._unhandled_input(press)
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.index = 0
	release.position = Vector2(500, 500)
	release.pressed = false
	game._unhandled_input(release)
	_check("a playfield tap turns gravity once", game.gravity_direction == Vector2.LEFT)
	game.last_shift = -1.0
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._unhandled_input(click)
	_check("a synthetic mouse click after touch does not turn gravity", game.gravity_direction == Vector2.LEFT)
	_check("gravity shift has a keyboard action", InputMap.has_action("shift_gravity"))
	if InputMap.has_action("shift_gravity"):
		game.last_shift = -1.0
		var shift_key: InputEventKey = InputEventKey.new()
		shift_key.physical_keycode = KEY_SHIFT
		shift_key.pressed = true
		game._unhandled_input(shift_key)
		_check("Shift turns gravity", game.gravity_direction == Vector2.UP)
		game._unhandled_input(press)
		var inverted_jump: InputEventScreenDrag = InputEventScreenDrag.new()
		inverted_jump.index = 0
		inverted_jump.position = Vector2(500, 640)
		game._unhandled_input(inverted_jump)
		_check("a downward swipe jumps from the ceiling", game.pilot.touch_jump)
		release.position = inverted_jump.position
		game._unhandled_input(release)
		game.last_shift = -1.0
		game.last_touch_msec = -100000
		game.last_start_msec = -100000
		game._unhandled_input(click)
		_check("a mouse click turns gravity", game.gravity_direction == Vector2.RIGHT)
	game._unhandled_input(press)
	var slide: InputEventScreenDrag = InputEventScreenDrag.new()
	slide.index = 0
	slide.position = Vector2(660, 500)
	game._unhandled_input(slide)
	_check("a horizontal slide walks right", game.pilot.touch_axis == 1.0)
	release.position = slide.position
	game._unhandled_input(release)
	_check("lifting the finger stops walking", game.pilot.touch_axis == 0.0)
	game._unhandled_input(press)
	var upward: InputEventScreenDrag = InputEventScreenDrag.new()
	upward.index = 0
	upward.position = Vector2(500, 370)
	game._unhandled_input(upward)
	_check("an upward swipe queues a jump", game.pilot.touch_jump)
	release.position = upward.position
	game._unhandled_input(release)
	_check("the pilot supports a crouch action", game.pilot.has_method("set_touch_crouch"))
	if game.pilot.has_method("set_touch_crouch"):
		game._unhandled_input(press)
		var downward: InputEventScreenDrag = InputEventScreenDrag.new()
		downward.index = 0
		downward.position = Vector2(500, 640)
		game._unhandled_input(downward)
		release.position = downward.position
		game._unhandled_input(release)
		_check("a downward swipe leaves the pilot crouching", game.pilot.get("touch_crouch") == true)
		game.pilot.call("_set_crouch", true)
		var shape: CollisionShape2D = game.pilot.get_child(0) as CollisionShape2D
		_check("crouching lowers the collision shape", (shape.shape as CapsuleShape2D).height < 78.0)
		game.pilot.call("_set_crouch", false)
		_check("standing restores the collision shape", (shape.shape as CapsuleShape2D).height == 78.0)
	game.queue_free()
	await process_frame


func _test_timed_gate_and_bloom() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game._load_level(3)
	game._on_begin()
	_check("the timed seam begins closed", not game.timed_gate_shapes[0].disabled)
	game._shift(1)
	await physics_frame
	_check("a shift opens the timed seam", game.timed_gate_shapes[0].disabled and game.world.gate_open)
	game.pilot.position = Vector2(670, 815)
	game.pilot.velocity = Vector2.ZERO
	game.pilot.reset_physics_interpolation()
	game.last_shift = -1.0
	game._shift(1)
	game.pilot.touch_axis = 1.0
	for frame: int in range(75):
		await physics_frame
	_check("the runner crosses while the seam is open", game.pilot.position.x > 810.0)
	game.pilot.touch_axis = 0.0
	game.gate_remaining = 0.01
	for frame: int in range(3):
		await physics_frame
	_check("the timed seam closes after its window", not game.world.gate_open)
	game._load_level(8)
	game._on_begin()
	game.pilot.position = Vector2(390, 740)
	game.pilot.velocity = Vector2.ZERO
	game.pilot.reset_physics_interpolation()
	for frame: int in range(28):
		await physics_frame
	_check("the bloom launches the runner upward", game.pilot.velocity.y < -400.0 and not game.world.bloom_bursts.is_empty())
	game.queue_free()
	await process_frame


func _test_phase_buttons() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game._load_level(2)
	game._on_begin()
	var button: Area2D = Area2D.new()
	game.room.add_child(button)
	game._on_spark_body(game.pilot, 1, button)
	_check("mint button rejects the unlit seam", not game.collected[1])
	game._shift(1)
	game._on_spark_body(game.pilot, 1, button)
	_check("mint button collects in the lit seam", game.collected[1])
	game.queue_free()
	await process_frame


func _test_cargo_route() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game._load_level(4)
	game._on_begin()
	game.pilot.touch_axis = 1.0
	for frame: int in range(125):
		await physics_frame
	game.pilot.touch_axis = 0.0
	_check("the runner can move the weighted patch toward its mark", game.cargo.position.x > 720.0)
	game.last_shift = -1.0
	game._shift(1)
	game.last_shift = -1.0
	game._shift(1)
	for frame: int in range(95):
		await physics_frame
	_check("the upward pull seats the patch on the ceiling mark", game.pad_armed)
	game._load_level(9)
	game._on_begin()
	game.pilot.touch_axis = -1.0
	for frame: int in range(120):
		await physics_frame
	game.pilot.touch_axis = 0.0
	_check("the forest route seats the patch against the root", game.pad_armed)
	game.queue_free()
	await process_frame


func _test_room_clearance() -> void:
	for index: int in range(PalewheelLevels.count()):
		var level: Dictionary = PalewheelLevels.get_level(index)
		for point: Vector2 in [level["start"], level["exit"]] + level["shards"]:
			var blocked: bool = false
			for wall: Rect2 in level["walls"]:
				blocked = blocked or wall.grow(12.0).has_point(point)
			for hazard: Rect2 in level["hazards"]:
				blocked = blocked or hazard.grow(12.0).has_point(point)
			_check("room %d keeps a goal point clear" % index, not blocked)


func _test_opening_route() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game._on_begin()
	game.pilot.touch_axis = 1.0
	for frame: int in range(36):
		await physics_frame
	_check("the opening button can be collected while running", game.collected[0])
	game.last_shift = -1.0
	game._shift(1)
	game.last_shift = -1.0
	game._shift(1)
	for frame: int in range(180):
		await physics_frame
	_check("the ceiling route reaches its button without teleporting", game.collected[1])
	game.last_shift = -1.0
	game._shift(1)
	game.last_shift = -1.0
	game._shift(1)
	game.pilot.touch_axis = -1.0
	for frame: int in range(65):
		await physics_frame
	_check("the return to the floor reaches the last button", game.collected[2])
	game.pilot.touch_axis = 1.0
	for frame: int in range(100):
		await physics_frame
	_check("the opening route reaches the zipper without teleporting", game.level_index == 1)
	game.queue_free()
	await process_frame


func _test_palewheel_playthrough() -> void:
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate() as Node2D
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	_check("title opens with play disabled", not game.playing)
	game._on_begin()
	_check("start enables the pilot", game.playing and game.pilot.control_enabled)
	var start_x: float = game.pilot.position.x
	Input.action_press("move_right")
	for frame: int in range(22):
		await physics_frame
	Input.action_release("move_right")
	_check("the pilot runs across the floor", game.pilot.position.x > start_x + 45.0)
	game._shift(1)
	_check("a shift turns gravity and changes the light phase", game.gravity_direction == Vector2.LEFT and game.phase == 1)
	game._restart()
	for level_number: int in range(PalewheelLevels.count()):
		if level_number > 0:
			game._on_begin()
		if level_number == 3:
			var sentry_start: Vector2 = game.sentries[0].position
			for frame: int in range(12):
				await physics_frame
			_check("the needle moth patrols its track", game.sentries[0].position.distance_to(sentry_start) > 10.0)
			game.pilot.position = game.level["checkpoint"]
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			_check("the pin activates when the runner reaches it", game.checkpoint_active)
			game.last_shift = -1.0
			game._shift(1)
			await process_frame
			_check("shifting pauses the needle moth", game.sentries[0].freeze_remaining > 0.0 and not game.sentries[0].monitoring)
			game.pilot.position = game.level["shards"][0]
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			await physics_frame
			await physics_frame
			_check("a button is collected before a hazard hit", game.collected[0])
			game.pilot.position = game.level["hazards"][0].get_center() + Vector2(0, -25)
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
			_check("a hit scatters the fabric runner", game.respawning and not game.pilot.visible and is_instance_valid(game.unravel))
			for frame: int in range(45):
				await physics_frame
			_check("a hazard sends the runner to the pin and keeps buttons", not game.respawning and game.pilot.visible and game.pilot.position.distance_to(game.respawn_position) < 30.0 and game.collected[0])
		for spark_index: int in range(game.level["shards"].size()):
			var spark: Vector2 = game.level["shards"][spark_index]
			var required_phases: Array = game.level["shard_phases"]
			if spark_index < required_phases.size() and int(required_phases[spark_index]) >= 0 and game.phase != int(required_phases[spark_index]):
				game.last_shift = -1.0
				game._shift(1)
			game.pilot.position = spark
			game.pilot.velocity = Vector2.ZERO
			game.pilot.reset_physics_interpolation()
			await physics_frame
			await physics_frame
		_check("all buttons collect in room %d" % level_number, not game.collected.has(false))
		if game.level["pad"] != Vector2.ZERO:
			game._on_pad_body(game.cargo)
			_check("cargo plate arms in room %d" % level_number, game.pad_armed)
		_check("exit unlocks in room %d" % level_number, game.world.door_open)
		game.pilot.position = game.level["exit"]
		game.pilot.velocity = Vector2.ZERO
		game.pilot.reset_physics_interpolation()
		await physics_frame
		await physics_frame
		if level_number + 1 < PalewheelLevels.count():
			_check("the next room opens after room %d" % level_number, game.level_index == level_number + 1)
	_check("the final seam ending follows the last room", game.finished)
	game.queue_free()
	await process_frame
