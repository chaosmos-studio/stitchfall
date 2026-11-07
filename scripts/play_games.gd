class_name StitchfallPlayGames
extends RefCounted

# Google Play Games, as the kit's PlayGames has it, in Stitchfall's terms: sign-in, the leaderboards, achievements
# and Game Stats in play_games/catalog.json, and progress kept in the player's Google account (StitchfallCloudSave),
# so a new phone picks up where the old one stopped. Off everywhere but an Android build that carries
# play_games.json, and nothing ever waits on it.
#
# play_games.json at the project's root is written by tools/play_games_ids.py once Stitchfall has its Play Games
# project: {"app": the project id, "leaderboards": {key: id}, "achievements": {key: id}}. Without it the Android
# build leaves the plugin out (addons/play_games), and the browser build never carries any of it.

const CATALOG: String = "res://play_games/catalog.json"
const IDS: String = "res://play_games.json"
const SINGLETON: String = "GodotPlayGameServices"
const BACKEND: String = "res://scripts/android/play_games.gd"
# What an achievement can count, each read from the player's progress by `measures`.
const MEASURES: PackedStringArray = ["sewn", "chapters", "three", "seamless", "quick", "banked", "turns", "unravels"]
# The most one room adds to the time spent in the rooms, so a room left open overnight counts as an hour.
const ROOM_SECONDS_CAP: float = 3600.0

static var _backend: Node
static var _catalog: Dictionary = {}
static var _ids: Dictionary = {}


# `restored` is called once a copy from the player's Google account has been folded into `progress`.
static func start(progress: StitchfallProgress, restored: Callable = Callable()) -> void:
	if is_instance_valid(_backend) or not OS.has_feature("android") or app_id().is_empty() \
			or not Engine.has_singleton(SINGLETON):
		return
	var backend: Node = (load(BACKEND) as GDScript).new() as Node
	backend.set("plugin", Engine.get_singleton(SINGLETON))
	backend.set("progress", progress)
	backend.set("restored", restored)
	_backend = backend
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(backend)


static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = _read(CATALOG)
	return _catalog


static func ids() -> Dictionary:
	if _ids.is_empty():
		_ids = _read(IDS)
	return _ids


static func app_id() -> String:
	return String(ids().get("app", ""))


static func id_of(kind: String, key: String) -> String:
	var table: Dictionary = ids().get(kind, {})
	return String(table.get(key, ""))


static func ready() -> bool:
	return is_instance_valid(_backend)


# The robots and the screenshot tool stage the signed-in pages with a stand-in that records what it is asked.
# Null takes it away again.
static func use(backend: Node) -> void:
	if is_instance_valid(_backend) and _backend != backend:
		_backend.queue_free()
	_backend = backend


static func signed_in() -> bool:
	return ready() and bool(_backend.get("signed_in"))


# Play Games' own pages. Each signs the player in first when they are not yet.
static func show_boards() -> void:
	if ready():
		_backend.call("show_boards")


static func show_achievements() -> void:
	if ready():
		_backend.call("show_achievements")


# After anything that changes progress: achievements, the boards, and the cloud save a little later.
static func progressed() -> void:
	if ready():
		_backend.call("progressed")


# A room sewn: its Game Stats event, then everything progressed sends. `room` counts from 0, as the game does.
static func room_sewn(room: int, stars: int, unravels: int, seconds: float) -> void:
	if not ready():
		return
	_backend.call("record_event", "roomCompleted", room_event(room, stars, unravels, seconds))
	_backend.call("progressed")


# Settings' Reset: the cloud copy is written over at once, or the next launch would bring the old progress back.
static func progress_reset() -> void:
	if ready():
		_backend.call("progress_reset")


# Game Stats: one room sewn as a roomCompleted event, its room numbered as players see it. The plugin sends
# {"seconds": n} as a duration.
static func room_event(room: int, stars: int, unravels: int, seconds: float) -> Dictionary:
	return {"room": room + 1, "stars": stars, "unravels": unravels,
		"time": {"seconds": snappedf(minf(seconds, ROOM_SECONDS_CAP), 0.1)}}


static func rooms_sewn(progress: StitchfallProgress) -> int:
	var sewn: int = 0
	for room: int in progress.best_stars:
		if progress.best_stars[room] > 0:
			sewn += 1
	return sewn


# The rooms of one chapter, five to a chapter, the last one cut short where the rooms run out.
static func chapter_rooms(chapter: int) -> Array[int]:
	var rooms: Array[int] = []
	var first: int = chapter * StitchfallLevels.CHAPTER_ROOMS
	for room: int in range(first, mini(first + StitchfallLevels.CHAPTER_ROOMS, StitchfallLevels.count())):
		rooms.append(room)
	return rooms


# The chapters whose every room passes `done`.
static func chapters_where(done: Callable) -> int:
	var whole: int = 0
	for chapter: int in range(StitchfallLevels.chapter_count()):
		var rooms: Array[int] = chapter_rooms(chapter)
		if not rooms.is_empty() and rooms.all(done):
			whole += 1
	return whole


# Each of MEASURES, from the player's progress.
static func measures(progress: StitchfallProgress) -> Dictionary[String, int]:
	var three: int = 0
	for room: int in progress.best_stars:
		if progress.best_stars[room] >= 3:
			three += 1
	var have: Dictionary[String, int] = {
		"sewn": rooms_sewn(progress),
		"chapters": chapters_where(func(room: int) -> bool: return progress.stars(room) > 0),
		"three": three,
		"seamless": chapters_where(func(room: int) -> bool: return progress.unbroken.has(room)),
		"quick": progress.quick.size(),
		"banked": progress.banked,
		"turns": progress.turns,
		"unravels": progress.unravels,
	}
	return have


# The steps an achievement takes: its threshold. One with more than one step is incremental in Play Games, so a
# player sees how far along it is.
static func goal(achievement: Dictionary) -> int:
	for measure: String in MEASURES:
		if achievement.has(measure):
			return int(achievement[measure])
	return 1


static func measure_of(achievement: Dictionary) -> String:
	for measure: String in MEASURES:
		if achievement.has(measure):
			return measure
	return ""


# Each achievement's steps done, by key, up to its goal.
static func steps(have: Dictionary[String, int]) -> Dictionary[String, int]:
	var out: Dictionary[String, int] = {}
	for entry: Variant in catalog().get("achievements", []):
		var a: Dictionary = entry
		var measure: String = measure_of(a)
		if not measure.is_empty():
			out[String(a["key"])] = mini(int(have.get(measure, 0)), goal(a))
	return out


# The achievements this progress has earned, by key.
static func earned(have: Dictionary[String, int]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var done: Dictionary[String, int] = steps(have)
	for entry: Variant in catalog().get("achievements", []):
		var a: Dictionary = entry
		if int(done.get(String(a["key"]), 0)) >= goal(a):
			out.append(String(a["key"]))
	return out


# Each leaderboard's score from progress, by key, or 0 where there is none yet to send.
static func scores(progress: StitchfallProgress) -> Dictionary[String, int]:
	var out: Dictionary[String, int] = {}
	for entry: Variant in catalog().get("leaderboards", []):
		var board: Dictionary = entry
		var key: String = String(board["key"])
		if board.has("chapter"):
			out[key] = speedrun_ms(progress, String(board["chapter"]))
		elif key == "stars":
			out[key] = progress.total_stars()
		elif key == "rooms":
			out[key] = rooms_sewn(progress)
	return out


# A chapter's speedrun: the sum of its rooms' best times in milliseconds, once every one of them is sewn.
static func speedrun_ms(progress: StitchfallProgress, chapter_id: String) -> int:
	var chapter: int = StitchfallLevels.chapter_ids.find(chapter_id)
	if chapter < 0:
		return 0
	var total: float = 0.0
	for room: int in chapter_rooms(chapter):
		if progress.stars(room) == 0 or not progress.best_time.has(room):
			return 0
		total += progress.best_time[room]
	return roundi(total * 1000.0)


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}
