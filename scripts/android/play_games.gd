extends Node

# Google Play Games' side of StitchfallPlayGames, made only in the Android build of a game that has its
# play_games.json, the way the kit games' play_games.gd works. It talks to the GodotPlayGameServices Android plugin
# directly, rather than through its GDScript wrappers, whose autoload the browser build could not carry. Play Games
# signs a player in on its own at launch, and nothing here asks again unless the player taps Leaderboards or
# Achievements. Android only: the browser build leaves scripts/android/ out with the plugin it calls.

const SAVE_NAME: String = "progress"
# A burst of rooms becomes one cloud save.
const SAVE_DELAY: float = 15.0

var signed_in: bool = false
# The plugin's Android singleton, handed over by StitchfallPlayGames.start. The tests hand over a stand-in.
var plugin: Object
var progress: StitchfallProgress
# Called once a copy from the cloud has been folded into progress, so the page on show can redraw.
var restored: Callable = Callable()

# Achievement steps already sent this session, by key.
var _sent: Dictionary[String, int] = {}
# The score last sent to each leaderboard this session, by key. Scores made before sign-in wait in the progress
# itself, and sign-in sends them all.
var _scores: Dictionary[String, int] = {}
# Game Stats wants the player's progress at the start of each session and whenever it changes.
var _last_progress: int = -1
# The cloud copy is read and folded in once a session, before anything is written over it.
var _synced: bool = false
var _after_sign_in: Callable = Callable()
var _save_timer: Timer


func _ready() -> void:
	plugin.call("initialize")
	plugin.connect("userAuthenticated", _on_authenticated)
	plugin.connect("gameLoaded", _on_loaded)
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY
	_save_timer.timeout.connect(_save)
	add_child(_save_timer)
	plugin.call("isAuthenticated")


func sign_in(then: Callable = Callable()) -> void:
	_after_sign_in = then
	plugin.call("signIn")


func show_boards() -> void:
	if signed_in:
		plugin.call("showAllLeaderboards")
	else:
		sign_in(func() -> void: plugin.call("showAllLeaderboards"))


func show_achievements() -> void:
	if signed_in:
		plugin.call("showAchievements")
	else:
		sign_in(func() -> void: plugin.call("showAchievements"))


# Records a Game Stats event and asks for it to go up. Only a signed-in player has stats to add to.
func record_event(name: String, properties: Dictionary) -> void:
	if not signed_in:
		return
	plugin.call("recordGameEvent", name, properties)
	plugin.call("uploadGameEvents")


func progressed() -> void:
	if not signed_in or progress == null:
		return
	var steps: Dictionary[String, int] = StitchfallPlayGames.steps(StitchfallPlayGames.measures(progress))
	for entry: Variant in StitchfallPlayGames.catalog().get("achievements", []):
		var a: Dictionary = entry
		var key: String = String(a["key"])
		var id: String = StitchfallPlayGames.id_of("achievements", key)
		var done: int = steps.get(key, 0)
		var sent: int = _sent.get(key, 0)
		if id.is_empty() or done <= sent:
			continue
		_sent[key] = done
		if StitchfallPlayGames.goal(a) > 1:
			plugin.call("setAchievementSteps", id, done)
		else:
			plugin.call("unlockAchievement", id)
	var sewn: int = StitchfallPlayGames.rooms_sewn(progress)
	if sewn != _last_progress:
		_last_progress = sewn
		record_event("progressUpdate", {"currentProgress": sewn})
	var scores: Dictionary[String, int] = StitchfallPlayGames.scores(progress)
	for key: String in scores:
		var id: String = StitchfallPlayGames.id_of("leaderboards", key)
		var score: int = scores[key]
		var last: int = _scores.get(key, -1)
		if id.is_empty() or score <= 0 or score == last:
			continue
		_scores[key] = score
		plugin.call("submitScore", id, score)
	if _synced:
		_save_timer.start()


# Settings' Reset: the reset progress goes over the cloud copy at once, or the next sign-in would join the old
# progress back in.
func progress_reset() -> void:
	_save_timer.stop()
	_save()


func _on_authenticated(ok: bool) -> void:
	signed_in = ok
	if not ok:
		_after_sign_in = Callable()
		return
	if not _synced:
		plugin.call("loadGame", SAVE_NAME, false)
	progressed()
	if _after_sign_in.is_valid():
		var then: Callable = _after_sign_in
		_after_sign_in = Callable()
		then.call()


# The plugin sends the snapshot through Gson, whose bytes are signed, so each is masked back to 0 to 255.
func _on_loaded(json: String) -> void:
	_synced = true
	var data: Variant = JSON.parse_string(json)
	if data is Dictionary and (data as Dictionary).get("content") is Array:
		var bytes: PackedByteArray = PackedByteArray()
		for v: Variant in (data as Dictionary)["content"]:
			bytes.append(int(v) & 0xFF)
		# Both phones' progress joined can earn what neither had alone.
		if StitchfallCloudSave.absorb(bytes.get_string_from_utf8(), progress):
			if restored.is_valid():
				restored.call()
			progressed()
	_save_timer.stop()
	_save()


func _save() -> void:
	if not signed_in or not _synced or progress == null:
		return
	progress.save()
	plugin.call("saveGame", SAVE_NAME, "Stitchfall progress", StitchfallCloudSave.pack().to_utf8_buffer(), 0,
		StitchfallCloudSave.progress_value(progress))


# Whatever waits for the timer is saved before the app goes to the background, where it may be closed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and _save_timer != null and not _save_timer.is_stopped():
		_save_timer.stop()
		_save()
