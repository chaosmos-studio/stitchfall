extends Node2D

const PILOT_SCRIPT: Script = preload("res://scripts/player.gd")
const CARGO_SCRIPT: Script = preload("res://scripts/cargo.gd")
const WORLD_SCRIPT: Script = preload("res://scripts/world_view.gd")
const HUD_SCRIPT: Script = preload("res://scripts/hud.gd")
const SENTRY_SCRIPT: Script = preload("res://scripts/sentry.gd")
const FERRY_SCRIPT: Script = preload("res://scripts/ferry.gd")
const FRAY_LEDGE_SCRIPT: Script = preload("res://scripts/fray_ledge.gd")
const MECHANISM_SCRIPT: Script = preload("res://scripts/mechanism.gd")
const UNRAVEL_SCRIPT: Script = preload("res://scripts/unravel.gd")
const MUSIC_STREAM: AudioStreamOggVorbis = preload("res://assets/audio/music/stitched_home.ogg")
const SEWING_CURSOR: Texture2D = preload("res://assets/art/sewing_cursor.png")

var level_index: int = 0
var level: Dictionary = {}
var gravity_direction: Vector2 = Vector2.DOWN
var phase: int = 0
var collected: Array[bool] = []
var pad_armed: bool = false
var checkpoint_active: bool = false
var respawn_position: Vector2 = Vector2.ZERO
var respawning: bool = false
var playing: bool = false
var finished: bool = false
var run_time: float = 0.0
var deaths: int = 0
var shifts: int = 0
var last_shift: float = -1.0
var touch_starts: Dictionary[int, Dictionary] = {}
var mobile_crouched: bool = false
var last_touch_msec: int = -1000
var last_start_msec: int = -1000
var room: Node2D
var world: StitchfallWorldView
var pilot: StitchfallCourier
var cargo: StitchfallCargo
var bridges: Array[CollisionShape2D] = []
var timed_gate_shapes: Array[CollisionShape2D] = []
var gate_remaining: float = 0.0
var gates_open: bool = false
var sentries: Array[StitchfallWatcher] = []
var ferries: Array[StitchfallFerry] = []
var fray_ledges: Array[StitchfallFrayLedge] = []
var mechanisms: Array[StitchfallMechanism] = []
# A pop-up strip's needles stay flat until the runner walks into its trigger.
var popup_areas: Array[Area2D] = []
var popup_raised: Array[bool] = []
# Where the zipper is now, and how many of its flee points it has already run to.
var exit_position: Vector2 = Vector2.ZERO
var exit_flees: int = 0
var unravel: StitchfallUnravel
var camera: Camera2D
var default_zoom: Vector2 = Vector2.ONE
var hud: StitchfallHud
var sound: AudioStreamPlayer
var step_sound: AudioStreamPlayer
var music: AudioStreamPlayer
var audio_enabled: bool = true
var step_streams: Array[AudioStream] = [
	preload("res://assets/audio/sfx/step_0.wav"),
	preload("res://assets/audio/sfx/step_1.wav"),
	preload("res://assets/audio/sfx/step_2.wav"),
]
var sound_paths: Dictionary = {
	"shift": "res://assets/audio/sfx/shift.wav",
	"jump": "res://assets/audio/sfx/jump.wav",
	"spark": "res://assets/audio/sfx/spark.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"door": "res://assets/audio/sfx/door.wav",
}


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		DisplayServer.cursor_set_custom_image(SEWING_CURSOR, DisplayServer.CURSOR_ARROW, Vector2(5, 5))
		DisplayServer.cursor_set_custom_image(SEWING_CURSOR, DisplayServer.CURSOR_POINTING_HAND, Vector2(5, 5))
	world = WORLD_SCRIPT.new() as StitchfallWorldView
	add_child(world)
	camera = Camera2D.new()
	camera.position = Vector2(960, 540)
	default_zoom = Vector2.ONE * (2.0 if DisplayServer.is_touchscreen_available() else 1.6)
	camera.zoom = default_zoom
	add_child(camera)
	camera.make_current()
	sound = AudioStreamPlayer.new()
	add_child(sound)
	step_sound = AudioStreamPlayer.new()
	add_child(step_sound)
	music = AudioStreamPlayer.new()
	music.stream = MUSIC_STREAM
	music.volume_db = -17.0
	add_child(music)
	if DisplayServer.get_name() != "headless":
		music.play()
	hud = HUD_SCRIPT.new() as StitchfallHud
	add_child(hud)
	hud.begin_pressed.connect(_on_begin)
	hud.pause_pressed.connect(_on_pause)
	hud.restart_pressed.connect(_restart)
	hud.home_pressed.connect(_on_home)
	hud.level_selected.connect(_on_level_selected)
	hud.sound_toggled.connect(_on_sound_toggled)
	var initial_room: int = 0
	if OS.has_feature("web"):
		var requested_room: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('room')")
		if requested_room != null:
			initial_room = clampi(str(requested_room).to_int(), 0, StitchfallLevels.count() - 1)
	_load_level(initial_room)
	hud.show_home()


func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null


func _process(delta: float) -> void:
	if playing and not finished:
		run_time += delta
		_update_hud()
	if is_instance_valid(pilot):
		camera.position = camera.position.lerp(_camera_target(), minf(delta * 4.0, 1.0))


func _camera_target() -> Vector2:
	if bool(level["screen"]):
		var chamber: Rect2 = level["chamber"]
		return chamber.get_center()
	if float(level.get("width", 1920.0)) <= 1920.0:
		return Vector2(960, 540) + (pilot.position - Vector2(960, 540)) * 0.34
	var half_view: Vector2 = get_viewport_rect().size / camera.zoom * 0.5
	var ahead: float = clampf(pilot.velocity.x * 0.22, -120.0, 120.0)
	return Vector2(
		clampf(pilot.position.x + ahead, half_view.x, float(level["width"]) - half_view.x),
		clampf(540.0 + (pilot.position.y - 540.0) * 0.6, half_view.y, 1080.0 - half_view.y)
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			hud._toggle_sound()
			return
		if event.physical_keycode == KEY_F:
			hud._toggle_fullscreen()
			return
	if event is InputEventScreenTouch and playing:
		_handle_touch(event)
		return
	if event is InputEventScreenDrag and playing:
		_handle_drag(event)
		return
	if event is InputEventMouseButton:
		if playing and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not DisplayServer.is_touchscreen_available() and Time.get_ticks_msec() - last_touch_msec > 2000 and Time.get_ticks_msec() - last_start_msec > 150:
				_shift(1)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ENTER and not playing and hud.screen in ["home", "pause", "finish"]:
		_on_begin()
	elif not playing and event.is_action_pressed("pause"):
		if hud.screen == "pause":
			_on_begin()
		elif hud.screen in ["levels", "help", "about", "settings"]:
			hud.show_home()
	elif playing and event.is_action_pressed("shift_gravity"):
		_shift(1)
	elif playing and event.is_action_pressed("retry"):
		_restart()
	elif playing and event.is_action_pressed("pause"):
		_on_pause()


func _handle_touch(event: InputEventScreenTouch) -> void:
	last_touch_msec = Time.get_ticks_msec()
	if event.pressed:
		touch_starts[event.index] = {"origin": event.position, "mode": "", "axis": 0.0, "dragged": false}
		return
	if not touch_starts.has(event.index):
		return
	var touch: Dictionary = touch_starts[event.index]
	if not touch["dragged"] and event.position.distance_to(touch["origin"]) < 64.0:
		_shift(1)
	touch_starts.erase(event.index)
	_sync_touch_controls()


func _handle_drag(event: InputEventScreenDrag) -> void:
	last_touch_msec = Time.get_ticks_msec()
	if not touch_starts.has(event.index):
		return
	var touch: Dictionary = touch_starts[event.index]
	var offset: Vector2 = event.position - touch["origin"]
	if offset.length() < 64.0:
		return
	touch["dragged"] = true
	var previous: String = touch["mode"]
	if absf(offset.x) > absf(offset.y) * 1.15:
		touch["mode"] = "move"
		touch["axis"] = signf(offset.x)
		mobile_crouched = false
	elif (offset.y < 0.0) != (gravity_direction == Vector2.UP):
		touch["mode"] = "jump"
		touch["axis"] = 0.0
		mobile_crouched = false
		if previous != "jump":
			pilot.queue_touch_jump()
	else:
		touch["mode"] = "crouch"
		touch["axis"] = 0.0
		if previous != "crouch":
			mobile_crouched = not mobile_crouched
	touch_starts[event.index] = touch
	_sync_touch_controls()


func _sync_touch_controls() -> void:
	if not is_instance_valid(pilot):
		return
	pilot.touch_axis = 0.0
	for touch: Dictionary in touch_starts.values():
		if touch["mode"] == "move":
			pilot.touch_axis = touch["axis"]
			break
	pilot.set_touch_crouch(mobile_crouched)


func _physics_process(delta: float) -> void:
	if not playing or finished or not is_instance_valid(pilot):
		return
	if gates_open:
		gate_remaining = maxf(0.0, gate_remaining - delta)
		world.gate_fraction = gate_remaining / float(level["gate_window"])
		if gate_remaining == 0.0:
			var occupied: bool = false
			for gate: Rect2 in level["timed_gates"]:
				occupied = occupied or gate.grow(48.0).has_point(pilot.position)
			if not occupied:
				_close_timed_gates()
	if world.door_open and pilot.position.distance_to(exit_position) < 65.0:
		_advance()
		return
	var flee: Array = level["exit_flee"]
	if world.door_open and exit_flees < flee.size() and pilot.position.distance_to(exit_position) < float(level["flee_radius"]):
		exit_position = flee[exit_flees]
		exit_flees += 1
		world.exit_position = exit_position
		_play_sound("door")
		print("STITCHFALL_FLEE ", level_index, " ", exit_flees)


func _load_level(index: int) -> void:
	touch_starts.clear()
	mobile_crouched = false
	level_index = index
	level = StitchfallLevels.get_level(index)
	gravity_direction = Vector2.DOWN
	phase = 0
	pad_armed = false
	checkpoint_active = false
	respawn_position = level["start"]
	respawning = false
	last_shift = -1.0
	collected.clear()
	for ignored: Vector2 in level["shards"]:
		collected.append(false)
	if is_instance_valid(room):
		remove_child(room)
		room.queue_free()
	room = Node2D.new()
	room.name = "Compartment"
	add_child(room)
	bridges.clear()
	timed_gate_shapes.clear()
	gate_remaining = 0.0
	gates_open = false
	for wall: Rect2 in level["walls"]:
		_add_wall(wall, false)
	for bridge: Rect2 in level["phase_walls"]:
		_add_wall(bridge, true)
	for gate: Rect2 in level["timed_gates"]:
		timed_gate_shapes.append(_add_wall(gate, false))
	for hazard: Rect2 in level["hazards"]:
		_add_hazard(hazard)
	for spike: Dictionary in level["spikes"]:
		_add_hazard(spike["rect"])
	popup_areas.clear()
	popup_raised.clear()
	for popup_index: int in range(level["popups"].size()):
		var popup: Dictionary = level["popups"][popup_index]
		var rect: Rect2 = popup["rect"]
		var needles: Area2D = _make_area(rect.get_center(), rect.size + Vector2(0, 14), 2)
		needles.monitoring = false
		needles.body_entered.connect(_on_hazard_body)
		popup_areas.append(needles)
		popup_raised.append(false)
		var trigger: Rect2 = popup["trigger"]
		var tripwire: Area2D = _make_area(trigger.get_center(), trigger.size, 2)
		tripwire.body_entered.connect(_on_popup_tripped.bind(popup_index))
	exit_position = level["exit"]
	exit_flees = 0
	camera.zoom = Vector2.ONE * StitchfallLevels.SCREEN_ZOOM if bool(level["screen"]) else default_zoom
	fray_ledges.clear()
	for data: Dictionary in level["fray_ledges"]:
		var ledge: StitchfallFrayLedge = FRAY_LEDGE_SCRIPT.new() as StitchfallFrayLedge
		ledge.configure(data)
		room.add_child(ledge)
		ledge.active = playing
		fray_ledges.append(ledge)
	sentries.clear()
	for sentry_data: Dictionary in level["sentries"]:
		var sentry: StitchfallWatcher = SENTRY_SCRIPT.new() as StitchfallWatcher
		sentry.configure(sentry_data)
		room.add_child(sentry)
		sentry.body_entered.connect(_on_hazard_body)
		sentries.append(sentry)
	ferries.clear()
	for data: Dictionary in level["ferries"]:
		var ferry: StitchfallFerry = FERRY_SCRIPT.new() as StitchfallFerry
		ferry.configure(data)
		room.add_child(ferry)
		ferry.active = playing
		ferries.append(ferry)
	mechanisms.clear()
	for data: Dictionary in level["mechanisms"]:
		var mechanism: StitchfallMechanism = MECHANISM_SCRIPT.new() as StitchfallMechanism
		mechanism.configure(data)
		room.add_child(mechanism)
		mechanism.active = playing
		mechanism.struck.connect(_on_hazard_body)
		mechanism.launched.connect(_on_mechanism_launch)
		mechanisms.append(mechanism)
	for spark_index: int in range(collected.size()):
		_add_spark(level["shards"][spark_index], spark_index)
	for bloom: Vector2 in level["bloom_pads"]:
		var bloom_area: Area2D = _make_area(bloom + Vector2(0, -9), Vector2(112, 45), 2)
		bloom_area.body_entered.connect(_on_bloom_body.bind(bloom))
	if level["checkpoint"] != Vector2.ZERO:
		var checkpoint: Area2D = _make_area(level["checkpoint"], Vector2(88, 106), 2)
		checkpoint.body_entered.connect(_on_checkpoint_body)
	if level["pad"] != Vector2.ZERO:
		_add_pad(level["pad"])
		cargo = CARGO_SCRIPT.new() as StitchfallCargo
		cargo.position = level["crate"]
		room.add_child(cargo)
	else:
		cargo = null
	pilot = PILOT_SCRIPT.new() as StitchfallCourier
	pilot.position = level["start"]
	room.add_child(pilot)
	pilot.set_environment(level["environment"], level["environment_zone"])
	pilot.control_enabled = playing
	pilot.jumped.connect(_on_pilot_jumped)
	pilot.stepped.connect(func() -> void: _play_step(-17.0))
	pilot.landed.connect(func() -> void: _play_step(-11.0))
	camera.position = _camera_target()
	world.level = level
	world.phase = phase
	world.collected = collected.duplicate()
	world.pad_armed = false
	world.checkpoint_active = false
	world.door_open = false
	world.door_progress = 0.0
	world.spark_bursts.clear()
	world.bloom_bursts.clear()
	world.gate_open = false
	world.gate_fraction = 0.0
	world.gravity_direction = gravity_direction
	world.exit_position = exit_position
	world.popup_raised = popup_raised.duplicate()
	hud.set_room_intro(level["name"], level["hint"])
	_update_hud()
	print("STITCHFALL_ROOM ", index)


func _add_wall(rect: Rect2, is_bridge: bool) -> CollisionShape2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 6
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.disabled = is_bridge
	body.add_child(shape)
	room.add_child(body)
	if is_bridge:
		bridges.append(shape)
	return shape


func _add_hazard(rect: Rect2) -> void:
	var area: Area2D = _make_area(rect.get_center(), rect.size + Vector2(0, 14), 2)
	area.body_entered.connect(_on_hazard_body)


func _add_spark(pos: Vector2, index: int) -> void:
	var area: Area2D = _make_area(pos, Vector2(66, 72), 2)
	area.body_entered.connect(_on_spark_body.bind(index, area))


func _add_pad(pos: Vector2) -> void:
	var area: Area2D = _make_area(pos + Vector2(0, -15), Vector2(106, 56), 4)
	area.body_entered.connect(_on_pad_body)


func _make_area(pos: Vector2, size: Vector2, mask: int) -> Area2D:
	var area: Area2D = Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = mask
	area.monitoring = true
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	room.add_child(area)
	return area


func _on_hazard_body(body: Node2D) -> void:
	if body == pilot and playing and not respawning:
		respawning = true
		pilot.control_enabled = false
		pilot.velocity = Vector2.ZERO
		pilot.set_physics_process(false)
		pilot.visible = false
		deaths += 1
		_play_sound("hit")
		unravel = UNRAVEL_SCRIPT.new() as StitchfallUnravel
		room.add_child(unravel)
		unravel.scatter(pilot)
		_respawn_after_unravel(pilot, room)


func _respawn_after_unravel(hit_pilot: StitchfallCourier, hit_room: Node2D) -> void:
	await get_tree().create_timer(0.68).timeout
	if pilot != hit_pilot or room != hit_room:
		return
	if is_instance_valid(unravel):
		unravel.queue_free()
	_respawn()


func _on_popup_tripped(body: Node2D, index: int) -> void:
	if body != pilot or not playing or respawning or popup_raised[index]:
		return
	popup_raised[index] = true
	var tripped_room: Node2D = room
	await get_tree().create_timer(float(level["popups"][index]["delay"])).timeout
	if room != tripped_room or not popup_raised[index]:
		return
	popup_areas[index].monitoring = true
	world.popup_raised = popup_raised.duplicate()
	print("STITCHFALL_POPUP ", level_index, " ", index)


func _on_mechanism_launch(body: Node2D) -> void:
	if body != pilot or not playing or respawning:
		return
	pilot.velocity = pilot.velocity.slide(gravity_direction) - gravity_direction * 1040.0
	pilot.coyote = 0.0
	pilot.jump_buffer = 0.0
	pilot.takeoff_time = 0.18
	_play_sound("jump")


func _on_checkpoint_body(body: Node2D) -> void:
	if body != pilot or not playing or checkpoint_active:
		return
	checkpoint_active = true
	respawn_position = level["checkpoint"]
	world.checkpoint_active = true
	hud.set_hint("Pin set. Your buttons stay sewn after a hit.")
	_play_sound("spark")
	print("STITCHFALL_BEACON ", level_index)


func _respawn() -> void:
	if not is_instance_valid(pilot):
		return
	gravity_direction = Vector2.DOWN
	phase = 0
	pilot.set_gravity_direction(gravity_direction)
	pilot.position = respawn_position
	pilot.visible = true
	pilot.set_physics_process(true)
	pilot.velocity = Vector2.ZERO
	pilot.jump_buffer = 0.0
	pilot.jump_cut_requested = false
	pilot.touch_jump = false
	pilot.set_touch_crouch(false)
	pilot.touch_axis = 0.0
	pilot.reset_physics_interpolation()
	pilot.control_enabled = playing
	last_shift = -1.0
	if is_instance_valid(cargo):
		cargo.gravity_direction = gravity_direction
	for bridge: CollisionShape2D in bridges:
		bridge.set_deferred("disabled", true)
	gate_remaining = 0.0
	_close_timed_gates()
	world.phase = phase
	world.gravity_direction = gravity_direction
	world.shift_origin = respawn_position
	world.shift_age = 0.0
	for sentry: StitchfallWatcher in sentries:
		sentry.freeze_for(0.7)
	for mechanism: StitchfallMechanism in mechanisms:
		mechanism.reset()
	for ledge: StitchfallFrayLedge in fray_ledges:
		ledge.reset()
	for popup_index: int in range(popup_areas.size()):
		popup_raised[popup_index] = false
		popup_areas[popup_index].set_deferred("monitoring", false)
	world.popup_raised = popup_raised.duplicate()
	exit_position = level["exit"]
	exit_flees = 0
	world.exit_position = exit_position
	respawning = false
	_update_hud()


func _on_spark_body(body: Node2D, index: int, area: Area2D) -> void:
	if body != pilot or not playing or collected[index]:
		return
	var required_phases: Array = level.get("shard_phases", [])
	if index < required_phases.size() and int(required_phases[index]) >= 0 and phase != int(required_phases[index]):
		return
	collected[index] = true
	print("STITCHFALL_SPARK ", level_index, " ", index)
	world.collected = collected.duplicate()
	world.collect_spark(level["shards"][index])
	area.set_deferred("monitoring", false)
	_play_sound("spark")
	_update_door()
	_update_hud()


func _on_pad_body(body: Node2D) -> void:
	if body != cargo or pad_armed:
		return
	pad_armed = true
	world.pad_armed = true
	_play_sound("spark")
	_update_door()
	_update_hud()


func _on_bloom_body(body: Node2D, bloom: Vector2) -> void:
	if body != pilot or not playing or respawning:
		return
	pilot.velocity = pilot.velocity.slide(gravity_direction) - gravity_direction * 870.0
	pilot.coyote = 0.0
	pilot.jump_buffer = 0.0
	pilot.takeoff_time = 0.18
	pilot.landing_time = 0.0
	world.burst_bloom(bloom)
	_play_sound("jump")
	print("STITCHFALL_BLOOM ", level_index)


func _close_timed_gates() -> void:
	gates_open = false
	world.gate_open = false
	world.gate_fraction = 0.0
	for shape: CollisionShape2D in timed_gate_shapes:
		shape.set_deferred("disabled", false)


func _update_door() -> void:
	world.door_open = not collected.has(false) and (level["pad"] == Vector2.ZERO or pad_armed)
	if world.door_open:
		_play_sound("door")


func _shift(step: int) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if not playing or finished or now - last_shift < 0.24:
		return
	last_shift = now
	gravity_direction = gravity_direction.rotated(step * PI * 0.5).round()
	phase = 1 - phase
	shifts += 1
	pilot.set_gravity_direction(gravity_direction)
	if is_instance_valid(cargo):
		cargo.gravity_direction = gravity_direction
		cargo.sleeping = false
	for sentry: StitchfallWatcher in sentries:
		sentry.freeze_for(0.55)
	for mechanism: StitchfallMechanism in mechanisms:
		mechanism.arm()
	for bridge: CollisionShape2D in bridges:
		bridge.set_deferred("disabled", phase == 0)
	if not timed_gate_shapes.is_empty():
		gate_remaining = float(level["gate_window"])
		gates_open = true
		world.gate_open = true
		world.gate_fraction = 1.0
		for shape: CollisionShape2D in timed_gate_shapes:
			shape.set_deferred("disabled", true)
	world.phase = phase
	world.gravity_direction = gravity_direction
	world.shift_origin = pilot.position
	world.shift_age = 0.0
	print("STITCHFALL_SHIFT ", gravity_direction)
	_play_sound("shift")
	_update_hud()


func _advance() -> void:
	_play_sound("door")
	playing = false
	pilot.control_enabled = false
	for sentry: StitchfallWatcher in sentries:
		sentry.active = false
	if level_index + 1 >= StitchfallLevels.count():
		finished = true
		print("STITCHFALL_WIN")
		hud.show_finish(_format_time(run_time), shifts, deaths)
		return
	_load_level(level_index + 1)
	playing = true
	pilot.control_enabled = true
	for sentry: StitchfallWatcher in sentries:
		sentry.active = true
	for ferry: StitchfallFerry in ferries:
		ferry.active = true
	for mechanism: StitchfallMechanism in mechanisms:
		mechanism.active = true
	for ledge: StitchfallFrayLedge in fray_ledges:
		ledge.active = true


func _restart() -> void:
	_load_level(level_index)
	playing = true
	pilot.control_enabled = true
	for sentry: StitchfallWatcher in sentries:
		sentry.active = true
	for ferry: StitchfallFerry in ferries:
		ferry.active = true
	for mechanism: StitchfallMechanism in mechanisms:
		mechanism.active = true
	for ledge: StitchfallFrayLedge in fray_ledges:
		ledge.active = true
	hud.hide_panel()
	print("STITCHFALL_START ", level_index)


func _on_pause() -> void:
	if not playing:
		return
	touch_starts.clear()
	mobile_crouched = false
	pilot.touch_axis = 0.0
	pilot.set_touch_crouch(false)
	playing = false
	pilot.control_enabled = false
	for sentry: StitchfallWatcher in sentries:
		sentry.active = false
	for ferry: StitchfallFerry in ferries:
		ferry.active = false
	for mechanism: StitchfallMechanism in mechanisms:
		mechanism.active = false
	for ledge: StitchfallFrayLedge in fray_ledges:
		ledge.active = false
	hud.show_pause()


func _on_home() -> void:
	if is_instance_valid(pilot):
		pilot.control_enabled = false
		pilot.touch_axis = 0.0
		pilot.set_touch_crouch(false)
	for sentry: StitchfallWatcher in sentries:
		sentry.active = false
	for ferry: StitchfallFerry in ferries:
		ferry.active = false
	for mechanism: StitchfallMechanism in mechanisms:
		mechanism.active = false
	for ledge: StitchfallFrayLedge in fray_ledges:
		ledge.active = false
	playing = false
	touch_starts.clear()
	mobile_crouched = false
	hud.show_home()


func _on_level_selected(index: int) -> void:
	finished = false
	run_time = 0.0
	deaths = 0
	shifts = 0
	_load_level(index)
	_on_begin()


func _on_sound_toggled(enabled: bool) -> void:
	audio_enabled = enabled
	music.stream_paused = not enabled
	if not enabled:
		sound.stop()
		step_sound.stop()


func _on_begin() -> void:
	last_start_msec = Time.get_ticks_msec()
	if finished:
		finished = false
		run_time = 0.0
		deaths = 0
		shifts = 0
		_load_level(0)
	playing = true
	pilot.control_enabled = true
	for sentry: StitchfallWatcher in sentries:
		sentry.active = true
	for ferry: StitchfallFerry in ferries:
		ferry.active = true
	for mechanism: StitchfallMechanism in mechanisms:
		mechanism.active = true
	for ledge: StitchfallFrayLedge in fray_ledges:
		ledge.active = true
	hud.hide_panel()
	hud.set_room_intro(level["name"], level["hint"])
	print("STITCHFALL_START ", level_index)


func _play_sound(name: String) -> void:
	if not audio_enabled:
		return
	var stream: AudioStream = load(sound_paths[name]) as AudioStream
	if stream == null:
		return
	sound.stop()
	sound.stream = stream
	sound.play()


func _on_pilot_jumped() -> void:
	print("STITCHFALL_JUMP")
	_play_sound("jump")


func _play_step(volume: float) -> void:
	if not audio_enabled or not playing:
		return
	step_sound.stream = step_streams.pick_random()
	step_sound.volume_db = volume
	step_sound.pitch_scale = randf_range(0.94, 1.06)
	step_sound.play()


func _format_time(value: float) -> String:
	var seconds: int = int(value)
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _update_hud() -> void:
	if level.is_empty():
		return
	hud.set_status(level_index, level["name"], collected.count(true), collected.size(), level["pad"] != Vector2.ZERO, pad_armed, _format_time(run_time), gravity_direction, level["backdrop"])
