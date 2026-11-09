extends SceneTree

# The painted art (backdrops, runner sheets, home plates) is large, and stored lossless it made the Android
# download about 100 MB. Lossy WebP keeps the cloth and the drawing and is several times smaller. This sets
# every texture under assets/art bigger than MIN_BYTES to it, then a reimport applies it:
#   godot --headless --path . -s res://tools/compress_art.gd && godot --headless --path . --import

const MIN_BYTES: int = 300000
const QUALITY: float = 0.85
# Folders whose art is drawn far smaller than it is painted: their textures are scaled down to this many pixels on
# their longest side as they import, while the full-size source stays in git. The chapter patches are painted at
# 1024 and never drawn above about 200.
const SIZE_LIMITS: Dictionary[String, int] = {"res://assets/art/chapters": 512}


func _initialize() -> void:
	var changed: int = 0
	for path: String in _imports("res://assets/art"):
		var config: ConfigFile = ConfigFile.new()
		if config.load(path) != OK or config.get_value("remap", "importer", "") != "texture":
			continue
		var source: String = path.trim_suffix(".import")
		if FileAccess.open(source, FileAccess.READ).get_length() < MIN_BYTES:
			continue
		var limit: int = SIZE_LIMITS.get(source.get_base_dir(), 0)
		if int(config.get_value("params", "compress/mode", 0)) == 1 and is_equal_approx(float(config.get_value("params", "compress/lossy_quality", 0.0)), QUALITY) and int(config.get_value("params", "process/size_limit", 0)) == limit:
			continue
		config.set_value("params", "compress/mode", 1)
		config.set_value("params", "compress/lossy_quality", QUALITY)
		config.set_value("params", "process/size_limit", limit)
		config.save(path)
		changed += 1
	print("set %d textures to lossy WebP at %.2f, with their folder's size limit" % [changed, QUALITY])
	quit()


func _imports(folder: String) -> PackedStringArray:
	var found: PackedStringArray = []
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".import"):
			found.append(folder.path_join(file))
	for child: String in DirAccess.get_directories_at(folder):
		found.append_array(_imports(folder.path_join(child)))
	return found
