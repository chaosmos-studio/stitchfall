extends Node2D

const PILOT_SCRIPT: Script = preload("res://scripts/player.gd")
const CARGO_SCRIPT: Script = preload("res://scripts/cargo.gd")
const WORLD_SCRIPT: Script = preload("res://scripts/world_view.gd")
const HUD_SCRIPT: Script = preload("res://scripts/hud.gd")
const SENTRY_SCRIPT: Script = preload("res://scripts/sentry.gd")
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
var world: PalewheelWorldView
var pilot: PalewheelCourier
var cargo: PalewheelCargo
var bridges: Array[CollisionShape2D] = []
var sentries: Array[PalewheelWatcher] = []
var camera: Camera2D
var hud: PalewheelHud
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
	world = WORLD_SCRIPT.new() as PalewheelWorldView
	add_child(world)
	camera = Camera2D.new()
	camera.position = Vector2(960, 540)
	camera.zoom = Vector2.ONE * (2.0 if DisplayServer.is_touchscreen_available() else 1.6)
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
	hud = HUD_SCRIPT.new() as PalewheelHud
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
			initial_room = clampi(str(requested_room).to_int(), 0, PalewheelLevels.count() - 1)
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
		var target: Vector2 = Vector2(960, 540) + (pilot.position - Vector2(960, 540)) * 0.34
		camera.position = camera.position.lerp(target, minf(delta * 3.0, 1.0))


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


func _physics_process(_delta: float) -> void:
	if playing and not finished and is_instance_valid(pilot) and world.door_open:
		if pilot.position.distance_to(level["exit"]) < 65.0:
			_advance()


func _load_level(index: int) -> void:
	touch_starts.clear()
	mobile_crouched = false
	level_index = index
	level = PalewheelLevels.get_level(index)
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
	for wall: Rect2 in level["walls"]:
		_add_wall(wall, false)
	for bridge: Rect2 in level["phase_walls"]:
		_add_wall(bridge, true)
	for hazard: Rect2 in level["hazards"]:
		_add_hazard(hazard)
	sentries.clear()
	for sentry_data: Dictionary in level["sentries"]:
		var sentry: PalewheelWatcher = SENTRY_SCRIPT.new() as PalewheelWatcher
		sentry.configure(sentry_data)
		room.add_child(sentry)
		sentry.body_entered.connect(_on_hazard_body)
		sentries.append(sentry)
	for spark_index: int in range(collected.size()):
		_add_spark(level["shards"][spark_index], spark_index)
	if level["checkpoint"] != Vector2.ZERO:
		var checkpoint: Area2D = _make_area(level["checkpoint"], Vector2(88, 106), 2)
		checkpoint.body_entered.connect(_on_checkpoint_body)
	if level["pad"] != Vector2.ZERO:
		_add_pad(level["pad"])
		cargo = CARGO_SCRIPT.new() as PalewheelCargo
		cargo.position = level["crate"]
		room.add_child(cargo)
	else:
		cargo = null
	pilot = PILOT_SCRIPT.new() as PalewheelCourier
	pilot.position = level["start"]
	room.add_child(pilot)
	pilot.set_environment(level["environment"], level["environment_zone"])
	pilot.control_enabled = playing
	pilot.jumped.connect(_on_pilot_jumped)
	pilot.stepped.connect(func() -> void: _play_step(-17.0))
	pilot.landed.connect(func() -> void: _play_step(-11.0))
	world.level = level
	world.phase = phase
	world.collected = collected.duplicate()
	world.pad_armed = false
	world.checkpoint_active = false
	world.door_open = false
	world.door_progress = 0.0
	world.spark_bursts.clear()
	world.gravity_direction = gravity_direction
	hud.set_room_intro(level["name"], level["hint"])
	_update_hud()
	print("PALEWHEEL_ROOM ", index)


func _add_wall(rect: Rect2, is_bridge: bool) -> void:
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
		deaths += 1
		_play_sound("hit")
		call_deferred("_respawn")


func _on_checkpoint_body(body: Node2D) -> void:
	if body != pilot or not playing or checkpoint_active:
		return
	checkpoint_active = true
	respawn_position = level["checkpoint"]
	world.checkpoint_active = true
	hud.set_hint("Pin set. Your buttons stay sewn after a hit.")
	_play_sound("spark")
	print("PALEWHEEL_BEACON ", level_index)


func _respawn() -> void:
	if not is_instance_valid(pilot):
		return
	gravity_direction = Vector2.DOWN
	phase = 0
	pilot.set_gravity_direction(gravity_direction)
	pilot.position = respawn_position
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
	world.phase = phase
	world.gravity_direction = gravity_direction
	world.shift_origin = respawn_position
	world.shift_age = 0.0
	for sentry: PalewheelWatcher in sentries:
		sentry.freeze_for(0.7)
	respawning = false
	_update_hud()


func _on_spark_body(body: Node2D, index: int, area: Area2D) -> void:
	if body != pilot or not playing or collected[index]:
		return
	var required_phases: Array = level.get("shard_phases", [])
	if index < required_phases.size() and int(required_phases[index]) >= 0 and phase != int(required_phases[index]):
		return
	collected[index] = true
	print("PALEWHEEL_SPARK ", level_index, " ", index)
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
	for sentry: PalewheelWatcher in sentries:
		sentry.freeze_for(0.55)
	for bridge: CollisionShape2D in bridges:
		bridge.set_deferred("disabled", phase == 0)
	world.phase = phase
	world.gravity_direction = gravity_direction
	world.shift_origin = pilot.position
	world.shift_age = 0.0
	print("PALEWHEEL_SHIFT ", gravity_direction)
	_play_sound("shift")
	_update_hud()


func _advance() -> void:
	_play_sound("door")
	playing = false
	pilot.control_enabled = false
	for sentry: PalewheelWatcher in sentries:
		sentry.active = false
	if level_index + 1 >= PalewheelLevels.count():
		finished = true
		print("PALEWHEEL_WIN")
		hud.show_finish(_format_time(run_time), shifts, deaths)
		return
	_load_level(level_index + 1)
	playing = true
	pilot.control_enabled = true
	for sentry: PalewheelWatcher in sentries:
		sentry.active = true


func _restart() -> void:
	_load_level(level_index)
	playing = true
	pilot.control_enabled = true
	for sentry: PalewheelWatcher in sentries:
		sentry.active = true
	hud.hide_panel()
	print("PALEWHEEL_START ", level_index)


func _on_pause() -> void:
	if not playing:
		return
	touch_starts.clear()
	mobile_crouched = false
	pilot.touch_axis = 0.0
	pilot.set_touch_crouch(false)
	playing = false
	pilot.control_enabled = false
	for sentry: PalewheelWatcher in sentries:
		sentry.active = false
	hud.show_pause()


func _on_home() -> void:
	if is_instance_valid(pilot):
		pilot.control_enabled = false
		pilot.touch_axis = 0.0
		pilot.set_touch_crouch(false)
	for sentry: PalewheelWatcher in sentries:
		sentry.active = false
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
	for sentry: PalewheelWatcher in sentries:
		sentry.active = true
	hud.hide_panel()
	hud.set_room_intro(level["name"], level["hint"])
	print("PALEWHEEL_START ", level_index)


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
	print("PALEWHEEL_JUMP")
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
