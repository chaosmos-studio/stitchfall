extends Node2D

const PILOT_SCRIPT: Script = preload("res://scripts/player.gd")
const CARGO_SCRIPT: Script = preload("res://scripts/cargo.gd")
const WORLD_SCRIPT: Script = preload("res://scripts/world_view.gd")
const HUD_SCRIPT: Script = preload("res://scripts/hud.gd")
const SENTRY_SCRIPT: Script = preload("res://scripts/sentry.gd")
const FRAY_LEDGE_SCRIPT: Script = preload("res://scripts/fray_ledge.gd")
const UNRAVEL_SCRIPT: Script = preload("res://scripts/unravel.gd")
const PIN_SCRIPT: Script = preload("res://scripts/pincushion.gd")
# How hard the camera shakes for each kind of moment, in pixels, and how fast a shake dies away per second.
const SHAKE_HIT: float = 14.0
const SHAKE_PRANK: float = 8.0
const SHAKE_LAND: float = 5.0
const SHAKE_DECAY: float = 40.0
# How long the phone buzzes, in milliseconds.
const BUZZ_UNRAVEL: int = 70
const BUZZ_CLEAR: int = 30
const BUZZ_TAP: int = 15
const BACK_ONE_PRESS_MS: int = 250
const BILLING_SCRIPT: String = "res://scripts/android/play_billing.gd"
const MUSIC_STREAM: AudioStreamOggVorbis = preload("res://assets/audio/music/stitched_home.ogg")
const SEWING_CURSOR: Texture2D = preload("res://assets/art/sewing_cursor.png")

var level_index: int = 0
var level: Dictionary = {}
var gravity_direction: Vector2 = Vector2.DOWN
var phase: int = 0
var collected: Array[bool] = []
# A button is loose until the runner touches a flower with it, then it is banked and survives an unravel.
var banked: Array[bool] = []
var spark_areas: Array[Area2D] = []
var pad_armed: bool = false
var flower_lit: Array[bool] = []
var respawn_position: Vector2 = Vector2.ZERO
var respawn_gravity: Vector2 = Vector2.DOWN
var room_time: float = 0.0
var room_deaths: int = 0
var cleared: bool = false
var last_result: Dictionary = {}
var shake: float = 0.0
var pins: Array[StitchfallPin] = []
var progress: StitchfallProgress = StitchfallProgress.new()
var respawning: bool = false
var playing: bool = false
var finished: bool = false
var run_time: float = 0.0
var deaths: int = 0
var shifts: int = 0
var last_shift: float = -1.0
var touch_starts: Dictionary[int, Dictionary] = {}
var mobile_crouched: bool = false
# The keys' screen push away from the surface last frame, and a push away or into it that was already held when
# the room turned, which does nothing until it is let go.
var key_away_held: bool = false
var key_stale_away: bool = false
var key_stale_into: bool = false
var last_touch_msec: int = -1000
var last_back_msec: int = -1000
var last_start_msec: int = -1000
# Whether this room's run has begun since it loaded, so a resume is not counted as a start.
var room_begun: bool = false
# The room Play picked up at launch, so a cloud save arriving a moment later can move it on.
var launch_room: int = -1
# Set while Next or a skip is on its way to the next room, past an ad or Play's review card, so a second press
# does nothing.
var advancing: bool = false
var room: Node2D
var world: StitchfallWorldView
var pilot: StitchfallCourier
var cargo: StitchfallCargo
var bridges: Array[CollisionShape2D] = []
var sentries: Array[StitchfallWatcher] = []
var fray_ledges: Array[StitchfallFrayLedge] = []
# A pop-up strip's needles stay flat until the runner walks into its trigger.
var popup_areas: Array[Area2D] = []
var popup_raised: Array[bool] = []
# Where the zipper is now, and how many of its flee points it has already run to.
var exit_position: Vector2 = Vector2.ZERO
var exit_flees: int = 0
var unravel: StitchfallUnravel
var camera: Camera2D
# Where the camera looks and how near, from the room fitted into what the HUD leaves of the screen.
var fitted_zoom: float = 1.4
var fitted_centre: Vector2 = StitchfallLevels.INSIDE.get_center()
var hud: StitchfallHud
var step_sound: AudioStreamPlayer
var music: AudioStreamPlayer
var audio_enabled: bool = true
var step_streams: Array[AudioStream] = [
	preload("res://assets/audio/sfx/step_0.wav"),
	preload("res://assets/audio/sfx/step_1.wav"),
	preload("res://assets/audio/sfx/step_2.wav"),
]
var sound_names: PackedStringArray = [
	"shift", "jump", "spark", "door", "unravel", "sewn", "chapter", "bloom", "thud", "rip", "shing", "zip", "bank", "loose",
]
var sounds: Dictionary[String, AudioStream] = {}
# A few voices, so the unravel's sting and the room's prank can sound at once.
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var music_tween: Tween
var trail: StitchfallTrail
const MUSIC_DB: float = -17.0
const MUSIC_DUCK_DB: float = -32.0
const PULL_IN_TIME: float = 0.42
const CARD_DELAY: float = 0.95
# The coach comes in once the room's name has had its moment, and counts a run once the runner is this far from
# the start.
const COACH_DELAY: float = 1.1
const COACH_RUN: float = 140.0
# How near the runner's middle must be to a button's to take it: the button's trigger is 66 by 72 and the runner
# about 50 by 80, so any real touch is well inside this.
const SPARK_REACH: float = 100.0
# How much of a key or stick push must point away from the surface to jump, or into it to crouch. A diagonal is
# 0.71 each way, so up and right together on the floor still run and jump at once.
const KEY_ROLE: float = 0.5
# A slide must travel this far before it means anything, and be this much more along the surface than across it
# to run.
const SLIDE_MIN: float = 48.0
const SLIDE_RUN_BIAS: float = 1.15
# How far the view leans as the room turns, in radians, and where the runner's feet are from its middle.
const TURN_LEAN: float = 0.03
const FEET: float = 36.0


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		DisplayServer.cursor_set_custom_image(SEWING_CURSOR, DisplayServer.CURSOR_ARROW, Vector2(5, 5))
		DisplayServer.cursor_set_custom_image(SEWING_CURSOR, DisplayServer.CURSOR_POINTING_HAND, Vector2(5, 5))
	world = WORLD_SCRIPT.new() as StitchfallWorldView
	add_child(world)
	camera = Camera2D.new()
	camera.position = Vector2(960, 540)
	# It leans a little as the room turns (_shift).
	camera.ignore_rotation = false
	add_child(camera)
	camera.make_current()
	for name: String in sound_names:
		sounds[name] = load("res://assets/audio/sfx/%s.wav" % name) as AudioStream
	for index: int in range(4):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	step_sound = AudioStreamPlayer.new()
	add_child(step_sound)
	music = AudioStreamPlayer.new()
	music.stream = MUSIC_STREAM
	music.volume_db = MUSIC_DB
	add_child(music)
	progress.load_saved()
	StitchfallAds.progress = progress
	audio_enabled = audio_enabled and progress.sound
	music.stream_paused = not progress.music
	hud = HUD_SCRIPT.new() as StitchfallHud
	hud.progress = progress
	add_child(hud)
	hud.next_pressed.connect(_on_next)
	hud.levels_pressed.connect(_on_levels)
	hud.music_toggled.connect(_on_music_toggled)
	hud.wardrobe_changed.connect(_apply_wardrobe)
	hud.progress_reset.connect(_on_progress_reset)
	hud.chapter_done.connect(_on_begin)
	hud.begin_pressed.connect(_on_begin)
	hud.pause_pressed.connect(_on_pause)
	hud.restart_pressed.connect(_restart)
	hud.home_pressed.connect(_on_home)
	hud.level_selected.connect(_on_level_selected)
	hud.sound_toggled.connect(_on_sound_toggled)
	hud.skip_pressed.connect(_on_skip)
	hud.play_frame_changed.connect(_fit_camera)
	hud.coach.finished.connect(_on_coached)
	hud.practice_pressed.connect(_on_practice)
	_start_store()
	StitchfallAds.start()
	StitchfallAnalytics.start()
	StitchfallPlayCore.start(_offer_update)
	StitchfallPlayGames.start(progress, _on_cloud_restore)
	var initial_room: int = progress.continue_room(StitchfallLevels.count())
	if OS.has_feature("web"):
		var requested_room: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('room')")
		if requested_room != null:
			initial_room = clampi(str(requested_room).to_int(), 0, StitchfallLevels.count() - 1)
	_load_level(initial_room)
	launch_room = initial_room
	hud.show_home()
	# The studio's sewn beat first, with the music coming in after it.
	StitchfallStudioIntro.play(self, func() -> void:
		if DisplayServer.get_name() != "headless":
			music.play()
			music.stream_paused = not progress.music)


# The Android build sells its packs and takes tips through Google Play's billing plugin. The browser build has
# neither, so it loads none of it. Ads, Analytics, Play's review card and updates, and Play Games start after it,
# and each does nothing off Android.
func _start_store() -> void:
	if not OS.has_feature("android") or not Engine.has_singleton("GodotGooglePlayBilling"):
		return
	var store: Node = (load(BILLING_SCRIPT) as GDScript).new() as Node
	store.set("progress", progress)
	add_child(store)
	store.connect("said", hud._say)
	store.connect("changed", hud.refresh_store)
	StitchfallShop.backend = store


# A downloaded update is offered on a quiet page only: Home or Levels, never mid-room.
func _offer_update() -> bool:
	if hud.screen not in ["home", "levels"]:
		return false
	hud.show_update()
	return true


func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null


func _process(delta: float) -> void:
	if playing and not finished:
		run_time += delta
		# The room's clock stands still while the coach teaches, so learning never costs the Quick star.
		if not hud.coach.coaching():
			room_time += delta
		_update_hud()
	if is_instance_valid(pilot):
		camera.position = camera.position.lerp(_camera_target(), minf(delta * 4.0, 1.0))
	shake = move_toward(shake, 0.0, delta * SHAKE_DECAY)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake


func _shake(amount: float) -> void:
	if progress.shake:
		shake = maxf(shake, amount)


# The Shake setting covers the phone's buzz too. Desktops ignore it.
func _buzz(milliseconds: int) -> void:
	if progress.shake:
		Input.vibrate_handheld(milliseconds)


# Android's back gesture steps back one screen, and leaves the game from Home. One press can reach Godot as
# two requests about 50 ms apart (the kit games' GoBack), so requests closer than BACK_ONE_PRESS_MS are one.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or Time.get_ticks_msec() - last_back_msec < BACK_ONE_PRESS_MS:
		return
	last_back_msec = Time.get_ticks_msec()
	# The quick game standing in for a video closes first, and an ad on its way holds everything else.
	if StitchfallAds.back() or StitchfallAds.is_busy() or advancing:
		return
	if playing:
		_on_pause()
	elif hud.screen == "pause":
		_on_begin()
	elif hud.screen == "chapter":
		hud.skip_chapter()
	elif hud.screen in ["about", "credits", "stats"]:
		hud.show_settings()
	elif hud.screen == "shop":
		hud.leave_shop()
	elif hud.screen == "offer":
		hud.leave_offer()
	elif hud.screen == "update":
		hud.leave_update()
	elif hud.screen == "home":
		progress.save()
		get_tree().quit()
	elif hud.screen in ["clear", "finish"]:
		_on_levels()
	else:
		_on_home()


func _camera_target() -> Vector2:
	return fitted_centre


# Fits the room into the screen the HUD leaves free: called on every room and whenever the screen or the HUD's
# layout changes.
func _fit_camera() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	fitted_zoom = StitchfallLevels.fit_zoom(view, hud.play_reserve)
	fitted_centre = StitchfallLevels.fit_centre(fitted_zoom, hud.play_reserve)
	camera.zoom = Vector2.ONE * fitted_zoom
	camera.position = fitted_centre
	# The painting behind the room covers what the camera shows, with a little over for a shake or a punch.
	var seen: Vector2 = view / fitted_zoom
	world.view = Rect2(fitted_centre - seen * 0.5, seen).grow(seen.x * 0.04)


func _unhandled_input(event: InputEvent) -> void:
	if StitchfallAds.is_busy() or advancing:
		return
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
	if not playing and hud.screen == "chapter" and event.is_pressed() and not event.is_echo():
		hud.skip_chapter()
		return
	if not playing and hud.screen == "clear" and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_SPACE]:
			_on_next()
		elif event.is_action_pressed("retry"):
			_restart()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ENTER and not playing and hud.screen in ["home", "pause", "finish"]:
		_on_begin()
	elif not playing and event.is_action_pressed("pause"):
		if hud.screen == "pause":
			_on_begin()
		elif hud.screen in ["levels", "help", "settings", "wardrobe"]:
			hud.show_home()
		elif hud.screen in ["about", "credits", "stats"]:
			hud.show_settings()
		elif hud.screen == "shop":
			hud.leave_shop()
		elif hud.screen == "offer":
			hud.leave_offer()
		elif hud.screen == "update":
			hud.leave_update()
	elif playing and event.is_action_pressed("shift_gravity"):
		_shift(1)
	elif playing and event.is_action_pressed("retry"):
		_restart()
	elif playing and event.is_action_pressed("pause"):
		_on_pause()


func _handle_touch(event: InputEventScreenTouch) -> void:
	last_touch_msec = Time.get_ticks_msec()
	if event.pressed:
		touch_starts[event.index] = {"origin": event.position, "now": event.position, "offset": Vector2.ZERO, "mode": "", "axis": 0.0, "dragged": false}
		_sync_touch_controls()
		return
	if not touch_starts.has(event.index):
		return
	var touch: Dictionary = touch_starts[event.index]
	if not touch["dragged"] and event.position.distance_to(touch["origin"]) < SLIDE_MIN:
		_shift(1)
	touch_starts.erase(event.index)
	_sync_touch_controls()


func _handle_drag(event: InputEventScreenDrag) -> void:
	last_touch_msec = Time.get_ticks_msec()
	if not touch_starts.has(event.index):
		return
	var touch: Dictionary = touch_starts[event.index]
	touch["now"] = event.position
	var offset: Vector2 = event.position - touch["origin"]
	if offset.length() < SLIDE_MIN:
		_sync_touch_controls()
		return
	touch["dragged"] = true
	touch["offset"] = offset
	_read_slide(touch, true)
	_sync_touch_controls()


# A slide is read in screen directions against the surface the runner stands on: mostly along it runs that way,
# away from it jumps, and into it crouches. So on a wall a slide up runs up the wall and a slide off it jumps.
# acting is false when the room turned under a held finger: the slide takes its new meaning without jumping or
# crouching, so a run to the right does not become a jump off the left wall.
func _read_slide(touch: Dictionary, acting: bool) -> void:
	var offset: Vector2 = touch["offset"]
	var along: float = offset.dot(_run_direction())
	var away: float = offset.dot(-gravity_direction)
	var previous: String = touch["mode"]
	if absf(along) > absf(away) * SLIDE_RUN_BIAS:
		touch["mode"] = "move"
		touch["axis"] = signf(along)
		if acting:
			mobile_crouched = false
	elif away > 0.0:
		touch["mode"] = "jump"
		touch["axis"] = 0.0
		if acting and previous != "jump":
			mobile_crouched = false
			pilot.queue_touch_jump()
	else:
		touch["mode"] = "crouch"
		touch["axis"] = 0.0
		if acting and previous != "crouch":
			mobile_crouched = not mobile_crouched


# The screen direction the runner's +1 move takes it. The runner turns its own moves round on the ceiling, so this
# is screen right on the floor and the ceiling, down the left wall and up the right one.
func _run_direction() -> Vector2:
	var tangent: Vector2 = Vector2(gravity_direction.y, -gravity_direction.x)
	return -tangent if gravity_direction == Vector2.UP else tangent


# The arrows, WASD, the d-pad and the stick are screen directions, turned here into the runner's moves for the way
# gravity points, the same way a slide is read: the push along the surface runs, away from it jumps (once, as it is
# pressed) and into it crouches.
func _steer_from_keys() -> void:
	var push: Vector2 = Vector2(
		clampf(Input.get_axis("screen_left", "screen_right") + Input.get_axis("stick_left", "stick_right"), -1.0, 1.0),
		clampf(Input.get_axis("screen_up", "screen_down") + Input.get_axis("stick_up", "stick_down"), -1.0, 1.0))
	var away: bool = push.dot(-gravity_direction) > KEY_ROLE
	var into: bool = push.dot(gravity_direction) > KEY_ROLE
	key_stale_away = key_stale_away and away
	key_stale_into = key_stale_into and into
	pilot.key_axis = clampf(push.dot(_run_direction()), -1.0, 1.0)
	pilot.key_crouch = into and not key_stale_into
	var pushing_away: bool = away and not key_stale_away
	if pushing_away and not key_away_held:
		pilot.queue_touch_jump()
	elif key_away_held and not pushing_away:
		pilot.key_jump_released = true
	key_away_held = pushing_away


# After the room turns, every held key and finger is read against the new surface, but a push that now points
# away from it or into it waits to be let go before it jumps or crouches.
func _reread_held_controls() -> void:
	var push: Vector2 = Vector2(
		Input.get_axis("screen_left", "screen_right") + Input.get_axis("stick_left", "stick_right"),
		Input.get_axis("screen_up", "screen_down") + Input.get_axis("stick_up", "stick_down"))
	key_away_held = false
	key_stale_away = push.dot(-gravity_direction) > KEY_ROLE
	key_stale_into = push.dot(gravity_direction) > KEY_ROLE
	for touch: Dictionary in touch_starts.values():
		if touch["dragged"]:
			_read_slide(touch, false)
	_sync_touch_controls()


func _release_held_controls() -> void:
	touch_starts.clear()
	mobile_crouched = false
	key_away_held = false
	key_stale_away = false
	key_stale_into = false
	hud.swipe_thread.show_fingers([])
	if is_instance_valid(pilot):
		pilot.touch_axis = 0.0
		pilot.key_axis = 0.0
		pilot.key_crouch = false
		pilot.set_touch_crouch(false)


func _sync_touch_controls() -> void:
	hud.swipe_thread.show_fingers(touch_starts.values())
	if not is_instance_valid(pilot):
		return
	pilot.touch_axis = 0.0
	for touch: Dictionary in touch_starts.values():
		if touch["mode"] == "move":
			pilot.touch_axis = touch["axis"]
			break
	pilot.set_touch_crouch(mobile_crouched)


func _physics_process(_delta: float) -> void:
	if not playing or finished or not is_instance_valid(pilot):
		return
	_steer_from_keys()
	world.gust_clock = pilot.environment_clock
	_check_coach()
	if world.door_open and not respawning and pilot.position.distance_to(exit_position) < 65.0:
		_clear_room()
		return
	var flee: Array = level["exit_flee"]
	if world.door_open and exit_flees < flee.size() and pilot.position.distance_to(exit_position) < float(level["flee_radius"]):
		exit_position = flee[exit_flees]
		exit_flees += 1
		world.exit_position = exit_position
		world.surprise()
		_play_sound("zip")
		_shake(SHAKE_PRANK)
		print("STITCHFALL_FLEE ", level_index, " ", exit_flees)


# The lessons that are states rather than moments: a run away from the start, and standing on the floor again
# after turning the room all the way round.
func _check_coach() -> void:
	match hud.coach.current():
		"move":
			var start: Vector2 = level["start"]
			if absf(pilot.position.x - start.x) > COACH_RUN:
				hud.coach.done("move")
		"floor":
			if gravity_direction == Vector2.DOWN:
				hud.coach.done("floor")


func _wants_coach() -> bool:
	return StitchfallCoach.enabled and DisplayServer.get_name() != "headless" and not progress.coached and level_index <= 1


func _start_coach(index: int) -> void:
	if level_index == index and playing and not cleared and not hud.coach.visible:
		hud.coach.begin(StitchfallHud.touch())


func _on_coached() -> void:
	progress.coached = true
	progress.save()


# The guide's Practice: the first room from the start, with every lesson again.
func _on_practice() -> void:
	progress.coached = false
	hud.coach.learned.clear()
	finished = false
	_load_level(0)
	_on_begin()


func _load_level(index: int) -> void:
	hud.coach.stop()
	_release_held_controls()
	level_index = index
	level = StitchfallLevels.get_level(index)
	gravity_direction = Vector2.DOWN
	phase = 0
	pad_armed = false
	respawn_position = level["start"]
	respawn_gravity = Vector2.DOWN
	respawning = false
	last_shift = -1.0
	room_time = 0.0
	room_deaths = 0
	room_begun = false
	cleared = false
	collected.clear()
	banked.clear()
	for ignored: Vector2 in level["shards"]:
		collected.append(false)
		banked.append(false)
	flower_lit.clear()
	for ignored: Dictionary in level["flowers"]:
		flower_lit.append(false)
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
	_fit_camera()
	fray_ledges.clear()
	for data: Dictionary in level["fray_ledges"]:
		var ledge: StitchfallFrayLedge = FRAY_LEDGE_SCRIPT.new() as StitchfallFrayLedge
		ledge.configure(data)
		room.add_child(ledge)
		ledge.active = playing
		ledge.gave_way.connect(_on_patch_gave_way)
		fray_ledges.append(ledge)
	sentries.clear()
	for sentry_data: Dictionary in level["sentries"]:
		var sentry: StitchfallWatcher = SENTRY_SCRIPT.new() as StitchfallWatcher
		sentry.configure(sentry_data)
		room.add_child(sentry)
		sentry.body_entered.connect(_on_hazard_body)
		sentries.append(sentry)
	spark_areas.clear()
	for spark_index: int in range(collected.size()):
		_add_spark(level["shards"][spark_index], spark_index)
	for flower_index: int in range(level["flowers"].size()):
		var flower: Dictionary = level["flowers"][flower_index]
		var gravity: Vector2 = flower["gravity"]
		var extent: Vector2 = Vector2(88, 106) if gravity.x == 0.0 else Vector2(106, 88)
		var flower_area: Area2D = _make_area(flower["pos"], extent, 2)
		flower_area.body_entered.connect(_on_flower_body.bind(flower_index))
	pins.clear()
	for pin_start: Vector2 in level["pins"]:
		var pin: StitchfallPin = PIN_SCRIPT.new() as StitchfallPin
		pin.configure(pin_start)
		room.add_child(pin)
		pin.active = playing
		pin.struck.connect(_on_hazard_body)
		pin.landed.connect(_on_pin_landed)
		pins.append(pin)
	if level["pad"] != Vector2.ZERO:
		_add_pad(level["pad"])
		cargo = CARGO_SCRIPT.new() as StitchfallCargo
		cargo.position = level["crate"]
		cargo.start = level["crate"]
		room.add_child(cargo)
	else:
		cargo = null
	pilot = PILOT_SCRIPT.new() as StitchfallCourier
	pilot.position = level["start"]
	pilot.runner = progress.wear["runner"]
	room.add_child(pilot)
	trail = StitchfallTrail.new()
	room.add_child(trail)
	trail.configure(pilot, StitchfallLooks.find(progress.wear["trail"]))
	pilot.set_environment(level["environment"], level["environment_zone"])
	pilot.control_enabled = playing
	pilot.jumped.connect(_on_pilot_jumped)
	pilot.stepped.connect(func() -> void: _play_step(-17.0))
	pilot.landed.connect(func() -> void:
		_play_step(-11.0)
		world.puff(pilot.position + gravity_direction * FEET, gravity_direction))
	world.runner = pilot
	camera.position = _camera_target()
	world.level = level
	world.phase = phase
	world.collected = collected.duplicate()
	world.pad_armed = false
	world.flower_lit = flower_lit.duplicate()
	world.flower_bloom.clear()
	world.confetti.clear()
	_apply_wardrobe()
	world.door_open = false
	world.door_progress = 0.0
	world.spark_bursts.clear()
	world.bloom_bursts.clear()
	world.gravity_direction = gravity_direction
	world.exit_position = exit_position
	world.popup_raised = popup_raised.duplicate()
	hud.set_room_intro(level["name"])
	hud.set_room_label(StitchfallLevels.chapter_name(index / StitchfallLevels.CHAPTER_ROOMS), index % StitchfallLevels.CHAPTER_ROOMS + 1, level["name"])
	hud.set_next_room(index, level["name"])
	hud.set_unravels(0)
	hud.show_skip_hint(false)
	_update_hud()
	print("STITCHFALL_ROOM ", index)


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
	spark_areas.append(area)


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
		room_deaths += 1
		progress.unravels += 1
		_play_sound("unravel")
		_duck_music(0.9)
		_shake(SHAKE_HIT)
		_buzz(BUZZ_UNRAVEL)
		hud.flash()
		hud.set_unravels(room_deaths)
		hud.show_skip_hint(not _skip_line().is_empty())
		StitchfallAnalytics.unravelled(level_index, room_deaths)
		trail.clear()
		unravel = UNRAVEL_SCRIPT.new() as StitchfallUnravel
		room.add_child(unravel)
		unravel.scatter(pilot, StitchfallLooks.find(progress.wear["unravel"]))
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
	world.surprise()
	_shake(SHAKE_PRANK)
	_play_sound("shing")
	print("STITCHFALL_POPUP ", level_index, " ", index)


# Touching a flower banks every button the runner carries and makes it the place to come back to,
# facing the way its stem points. The first touch makes it bloom.
func _on_flower_body(body: Node2D, index: int) -> void:
	if body != pilot or not playing or respawning:
		return
	var flower: Dictionary = level["flowers"][index]
	respawn_position = flower["pos"]
	respawn_gravity = flower["gravity"]
	for pin: StitchfallPin in pins:
		pin.start = pin.position
	if is_instance_valid(cargo):
		cargo.start = cargo.position
	var newly_banked: int = 0
	for button: int in range(collected.size()):
		if collected[button] and not banked[button]:
			newly_banked += 1
		banked[button] = banked[button] or collected[button]
	progress.banked += newly_banked
	if newly_banked > 0:
		_play_sound("bank")
		_buzz(BUZZ_TAP)
		hud.bank_buttons()
		_update_hud()
	if flower_lit[index]:
		return
	flower_lit[index] = true
	world.flower_lit = flower_lit.duplicate()
	world.bloom_flower(index)
	_play_sound("bloom")
	print("STITCHFALL_BEACON ", level_index, " ", index)


func _on_patch_gave_way() -> void:
	world.surprise()
	_shake(SHAKE_LAND)
	_play_sound("rip")


func _on_pin_landed() -> void:
	_shake(SHAKE_LAND)
	_play_sound("thud", -4.0, randf_range(0.9, 1.1))


func _respawn() -> void:
	if not is_instance_valid(pilot):
		return
	gravity_direction = respawn_gravity
	phase = 0 if gravity_direction.x == 0.0 else 1
	pilot.set_gravity_direction(gravity_direction)
	pilot.position = respawn_position
	pilot.visible = true
	pilot.set_physics_process(true)
	pilot.velocity = Vector2.ZERO
	pilot.jump_buffer = 0.0
	pilot.touch_jump = false
	_reread_held_controls()
	mobile_crouched = false
	pilot.set_touch_crouch(false)
	pilot.touch_axis = 0.0
	pilot.reset_physics_interpolation()
	pilot.control_enabled = playing
	last_shift = -1.0
	if is_instance_valid(cargo):
		cargo.reset(gravity_direction)
	for bridge: CollisionShape2D in bridges:
		bridge.set_deferred("disabled", phase == 0)
	for pin: StitchfallPin in pins:
		pin.reset(gravity_direction)
	var lost: bool = false
	for button: int in range(collected.size()):
		if collected[button] and not banked[button]:
			collected[button] = false
			lost = true
			spark_areas[button].set_deferred("monitoring", true)
			world.collect_spark(level["shards"][button])
	if lost:
		_play_sound("loose")
	pilot.sprite.scale = Vector2.ONE * 0.18
	create_tween().tween_property(pilot.sprite, "scale", Vector2.ONE * StitchfallCourier.SPRITE_SCALE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	world.collected = collected.duplicate()
	world.door_open = not collected.has(false) and (level["pad"] == Vector2.ZERO or pad_armed)
	world.phase = phase
	world.gravity_direction = gravity_direction
	world.shift_origin = respawn_position
	world.shift_age = 0.0
	for sentry: StitchfallWatcher in sentries:
		sentry.freeze_for(0.7)
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
	if body != pilot or not playing or respawning or collected[index]:
		return
	# A button the runner unravelled on is put back as the runner comes back, and its trigger wakes while the physics
	# still has the body where it came apart, so it would be taken again at once. Only a runner really there takes it.
	if pilot.global_position.distance_to(area.global_position) > SPARK_REACH:
		return
	collected[index] = true
	print("STITCHFALL_SPARK ", level_index, " ", index)
	world.collected = collected.duplicate()
	world.collect_spark(level["shards"][index])
	area.set_deferred("monitoring", false)
	progress.buttons += 1
	_play_sound("spark", 0.0, 1.0 + float(collected.count(true) - 1) * 0.12)
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
	progress.turns += 1
	pilot.set_gravity_direction(gravity_direction)
	if is_instance_valid(cargo):
		cargo.gravity_direction = gravity_direction
		cargo.sleeping = false
	for sentry: StitchfallWatcher in sentries:
		sentry.freeze_for(0.55)
	for pin: StitchfallPin in pins:
		pin.gravity_direction = gravity_direction
	for bridge: CollisionShape2D in bridges:
		bridge.set_deferred("disabled", phase == 0)
	world.phase = phase
	world.gravity_direction = gravity_direction
	world.shift_origin = pilot.position
	world.shift_age = 0.0
	_reread_held_controls()
	# The view leans the way the room turns and springs back, so the turn is felt as well as seen.
	if progress.shake:
		var lean: Tween = create_tween()
		lean.tween_property(camera, "rotation", TURN_LEAN, 0.07).set_ease(Tween.EASE_OUT)
		lean.tween_property(camera, "rotation", 0.0, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	print("STITCHFALL_SHIFT ", gravity_direction)
	_play_sound("shift")
	hud.coach.done("turn")
	_update_hud()


# Starts or stops everything in the room that moves on its own.
func _set_running(running: bool) -> void:
	playing = running
	if running and not room_begun:
		room_begun = true
		StitchfallAnalytics.room_started(level_index)
	if is_instance_valid(pilot):
		pilot.control_enabled = running
	for sentry: StitchfallWatcher in sentries:
		sentry.active = running
	for ledge: StitchfallFrayLedge in fray_ledges:
		ledge.active = running
	for pin: StitchfallPin in pins:
		pin.active = running


# The zipper takes the runner: the room is sewn, scored and saved, and the clear card waits for Next.
func _clear_room() -> void:
	_set_running(false)
	cleared = true
	progress.play_time += room_time
	var par: float = level["par"]
	last_result = progress.record(level_index, room_time, room_deaths, par)
	StitchfallAnalytics.room_cleared(level_index, int(last_result["stars"]), room_deaths)
	StitchfallPlayGames.room_sewn(level_index, int(last_result["stars"]), room_deaths, room_time)
	StitchfallAds.room_cleared()
	print("STITCHFALL_CLEAR ", level_index, " ", last_result["stars"])
	_play_sound("zip")
	_buzz(BUZZ_CLEAR)
	_duck_music(2.4)
	pilot.set_physics_process(false)
	pilot.velocity = Vector2.ZERO
	trail.clear()
	var pull: Tween = create_tween().set_parallel(true)
	pull.tween_property(pilot, "position", exit_position, PULL_IN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pull.tween_property(pilot.sprite, "scale", Vector2.ONE * 0.03, PULL_IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	pull.tween_property(pilot.sprite, "rotation", pilot.sprite.rotation + TAU, PULL_IN_TIME)
	_sew_shut(level_index, par)


# Once the runner is in, the zipper closes behind them, the room throws up its confetti, and the card follows.
func _sew_shut(index: int, par: float) -> void:
	await get_tree().create_timer(PULL_IN_TIME).timeout
	if not cleared or level_index != index:
		return
	world.door_open = false
	world.celebrate(exit_position)
	_shake(SHAKE_PRANK)
	var punch: Tween = create_tween()
	punch.tween_property(camera, "zoom", Vector2.ONE * fitted_zoom * 1.06, 0.12).set_ease(Tween.EASE_OUT)
	punch.tween_property(camera, "zoom", Vector2.ONE * fitted_zoom, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(CARD_DELAY - PULL_IN_TIME).timeout
	if not cleared or level_index != index:
		return
	var chapter: int = index / StitchfallLevels.CHAPTER_ROOMS
	var chapter_end: bool = (index + 1) % StitchfallLevels.CHAPTER_ROOMS == 0
	_play_sound("chapter" if chapter_end else "sewn")
	var card: Dictionary = last_result.duplicate()
	card.merge({
		"name": level["name"],
		"time": room_time,
		"par": par,
		"unravels": room_deaths,
		"chapter_end": chapter_end,
		"chapter_name": StitchfallLevels.chapter_name(chapter),
		"chapter_stars": progress.chapter_stars(chapter * StitchfallLevels.CHAPTER_ROOMS, StitchfallLevels.CHAPTER_ROOMS),
	})
	hud.show_clear(card)


# Next on the clear card is the one place an ad between rooms may come, and only when the next room is not a
# chapter's first, whose title card no ad may stand beside. As Next leaves a chapter's last room past a
# milestone, Play's review card comes instead.
func _on_next() -> void:
	if advancing:
		return
	if level_index + 1 >= StitchfallLevels.count():
		finished = true
		print("STITCHFALL_WIN")
		hud.show_finish(_format_time(run_time), shifts, deaths)
		return
	var chapter_next: bool = (level_index + 1) % StitchfallLevels.CHAPTER_ROOMS == 0
	advancing = true
	var milestone: int = StitchfallPlayCore.review_due(progress) if chapter_next else 0
	if milestone > 0:
		StitchfallPlayCore.ask(progress, milestone, _advance)
	else:
		StitchfallAds.maybe_interstitial(_advance, chapter_next)


# Opens the room after this one, on its chapter's title card when it starts a chapter.
func _advance() -> void:
	advancing = false
	_load_level(level_index + 1)
	if level_index % StitchfallLevels.CHAPTER_ROOMS == 0:
		var chapter: int = level_index / StitchfallLevels.CHAPTER_ROOMS
		hud.show_chapter(chapter, StitchfallLevels.chapter_name(chapter), StitchfallLevels.chapter_line(chapter))
		return
	_on_begin()


func _on_levels() -> void:
	_set_running(false)
	hud.show_levels()


func _restart() -> void:
	_load_level(level_index)
	_set_running(true)
	hud.hide_panel()
	print("STITCHFALL_START ", level_index)


func _on_pause() -> void:
	if not playing:
		return
	_release_held_controls()
	_set_running(false)
	progress.save()
	StitchfallPlayGames.progressed()
	hud.show_pause(_skip_line())


# The pause page's offer to skip this room, saying what it costs, or "" while none is offered.
func _skip_line() -> String:
	var has_next: bool = level_index + 1 < StitchfallLevels.count()
	var next_open: bool = has_next and StitchfallShop.room_open(progress, level_index + 1)
	if not StitchfallAdPacing.skip_offered(room_deaths, has_next, next_open):
		return ""
	if _skip_cost() == StitchfallAdPacing.Skip.FREE:
		return "Stuck? You can skip this room."
	return "Stuck? %s to skip this room. Skips are free with the Supporter pack." % StitchfallAds.watch()


func _skip_cost() -> StitchfallAdPacing.Skip:
	return StitchfallAdPacing.skip_cost(StitchfallAds.supporter(), StitchfallAds.rewards())


# Skipping is the opt-in. A video, or the quick game standing in for one, plays first unless the skip is free,
# and with nothing to play the room stays as it is, Resume and Retry beside it.
func _on_skip() -> void:
	if advancing or hud.screen != "pause" or _skip_line().is_empty():
		return
	if _skip_cost() == StitchfallAdPacing.Skip.FREE:
		_skip_room("free")
		return
	advancing = true
	StitchfallAds.rewarded(func() -> void: _skip_room("video"), func() -> void:
		advancing = false
		hud._say("Nothing to play right now. Try again in a moment."))


# A skipped room keeps no stars, opens the next one and counts no clear, so it brings no ad between rooms.
func _skip_room(cost: String) -> void:
	advancing = false
	StitchfallAnalytics.skipped(level_index, room_deaths, cost)
	progress.play_time += room_time
	progress.skip(level_index)
	StitchfallPlayGames.progressed()
	print("STITCHFALL_SKIP ", level_index)
	_advance()


func _on_home() -> void:
	_release_held_controls()
	_set_running(false)
	progress.save()
	StitchfallPlayGames.progressed()
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
	progress.sound = enabled
	progress.save()
	StitchfallAds.match_sound()
	if not enabled:
		for voice: AudioStreamPlayer in voices:
			voice.stop()
		step_sound.stop()


func _on_music_toggled(enabled: bool) -> void:
	progress.music = enabled
	progress.save()
	music.stream_paused = not enabled


func _on_progress_reset() -> void:
	progress.reset()
	StitchfallPlayGames.progress_reset()
	_apply_wardrobe()
	_load_level(0)


# Play Games has folded the player's progress from their Google account into this phone's, a moment after launch
# while Home is usually up. The page on show redraws from it, and Play picks up past the rooms it brought, unless
# a room has already been played this session.
func _on_cloud_restore() -> void:
	if hud.screen == "home" and not room_begun and level_index == launch_room:
		launch_room = progress.continue_room(StitchfallLevels.count())
		_load_level(launch_room)
	if hud.screen == "stats":
		hud.show_stats()
	else:
		hud.refresh_store()


# Dresses the room in what the wardrobe has on: the runner, its trail, the buttons and the fabric.
func _apply_wardrobe() -> void:
	world.button_colour = StitchfallLooks.find(progress.wear["button"]).get("colour", Color("e4c77f"))
	var fabric: Dictionary = StitchfallLooks.find(progress.wear["fabric"])
	world.fabric_backdrop = -1 if progress.wear["fabric"] == StitchfallLooks.DEFAULTS["fabric"] else int(fabric.get("backdrop", 0))
	world.queue_redraw()
	if is_instance_valid(pilot) and pilot.runner != progress.wear["runner"]:
		pilot.runner = progress.wear["runner"]
		pilot.sprite.sprite_frames = pilot._build_frames()
	if is_instance_valid(trail):
		trail.configure(pilot, StitchfallLooks.find(progress.wear["trail"]))
		trail.clear()
	_update_hud()


func _on_begin() -> void:
	last_start_msec = Time.get_ticks_msec()
	if finished:
		finished = false
		run_time = 0.0
		deaths = 0
		shifts = 0
		_load_level(0)
	elif cleared:
		_load_level(level_index)
	_set_running(true)
	hud.hide_panel()
	hud.set_room_intro(level["name"])
	if _wants_coach() and not hud.coach.visible:
		get_tree().create_timer(COACH_DELAY).timeout.connect(_start_coach.bind(level_index))
	print("STITCHFALL_START ", level_index)


func _play_sound(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not audio_enabled or not sounds.has(name):
		return
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = sounds[name]
	voice.volume_db = volume_db
	voice.pitch_scale = pitch
	voice.play()


# Dips the music under a sting, then brings it back.
func _duck_music(hold: float) -> void:
	if music_tween and music_tween.is_running():
		music_tween.kill()
	music_tween = create_tween()
	music_tween.tween_property(music, "volume_db", MUSIC_DUCK_DB, 0.08)
	music_tween.tween_interval(hold)
	music_tween.tween_property(music, "volume_db", MUSIC_DB, 0.9)


func _on_pilot_jumped() -> void:
	print("STITCHFALL_JUMP")
	_play_sound("jump")
	hud.coach.done("jump")


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
	hud.meter.banked = banked.count(true)
	hud.set_status(collected.count(true), collected.size(), world._backdrop())
