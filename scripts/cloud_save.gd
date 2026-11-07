class_name StitchfallCloudSave
extends RefCounted

# Joins this phone's progress with the copy in the player's Google account, as the kit's CloudSave does, key by
# key, so progress made on either is never lost: each room's best stars and best time, every room skipped, sewn
# unbroken or sewn quick, and the larger of each lifetime count. Settings, what is worn and where Play's review card
# stands stay this phone's own, and purchases (the packs and the tips) come from Google Play itself, so none of
# them is copied. The copy is progress.cfg as text, in one Saved Games snapshot.

# A section of progress.cfg whose every key, one per room, joins by one rule.
const SECTIONS: Dictionary[String, StringName] = {
	"stars": &"most",
	"time": &"least",
	"skipped": &"either",
	"unbroken": &"either",
	"quick": &"either",
}
# Single keys, as "section/key".
const KEYS: Dictionary[String, StringName] = {
	"stats/unravels": &"most",
	"stats/turns": &"most",
	"stats/buttons": &"most",
	"stats/banked": &"most",
	"stats/play_time": &"most",
}


static func pack() -> String:
	var file: ConfigFile = ConfigFile.new()
	file.load(StitchfallProgress.path)
	return file.encode_to_text()


# Play keeps the copy with the most progress when two phones save at once, so this only ever grows with play.
static func progress_value(progress: StitchfallProgress) -> int:
	return progress.total_stars() * 1000 + mini(progress.best_stars.size(), 999)


# Folds a copy from the cloud into `progress` and its file, and says whether anything changed. Whatever this
# phone holds only in memory is saved first, so the merge starts from all of it.
static func absorb(text: String, progress: StitchfallProgress) -> bool:
	var theirs: ConfigFile = ConfigFile.new()
	if text.strip_edges().is_empty() or theirs.parse(text) != OK:
		return false
	progress.save()
	var mine: ConfigFile = ConfigFile.new()
	mine.load(StitchfallProgress.path)
	var before: String = mine.encode_to_text()
	merge(mine, theirs)
	if mine.encode_to_text() == before:
		return false
	mine.save(StitchfallProgress.path)
	progress.load_saved()
	return true


static func merge(mine: ConfigFile, theirs: ConfigFile) -> void:
	for section: String in SECTIONS:
		if not theirs.has_section(section):
			continue
		for key: String in theirs.get_section_keys(section):
			mine.set_value(section, key, join(SECTIONS[section], _value(mine, section, key), theirs.get_value(section, key)))
	for at: String in KEYS:
		var section: String = at.get_slice("/", 0)
		var key: String = at.get_slice("/", 1)
		if theirs.has_section_key(section, key):
			mine.set_value(section, key, join(KEYS[at], _value(mine, section, key), theirs.get_value(section, key)))


static func join(rule: StringName, a: Variant, b: Variant) -> Variant:
	if typeof(a) == TYPE_NIL:
		return b
	if typeof(b) == TYPE_NIL:
		return a
	match rule:
		&"most":
			if a is float or b is float:
				return maxf(float(a), float(b))
			return maxi(int(a), int(b))
		&"least":
			return minf(float(a), float(b))
		&"either":
			return bool(a) or bool(b)
	return a


# A key this phone lacks reads as none, without the error get_value logs for every missing key.
static func _value(file: ConfigFile, section: String, key: String) -> Variant:
	return file.get_value(section, key) if file.has_section_key(section, key) else null
