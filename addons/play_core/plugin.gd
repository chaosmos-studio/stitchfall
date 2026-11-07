@tool
extends EditorPlugin

## The kit's PlayCore reaches Google Play's review card and in-app updates through PlayCore.java, which
## this puts into the Android build with the two libraries it needs.

var _export: _PlayCoreBuild

func _enter_tree() -> void:
	_export = _PlayCoreBuild.new()
	add_export_plugin(_export)

func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class _PlayCoreBuild extends EditorExportPlugin:
	const DEPENDENCIES: PackedStringArray = [
		"com.google.android.play:review:2.0.2",
		"com.google.android.play:app-update:2.1.0",
	]
	const SOURCE: String = "res://addons/play_core/PlayCore.java"
	const TEMPLATE: String = "res://android/build/build.gradle"
	## The template compiles every Java file under src/main/java, beside its own GodotApp.
	const TARGET: String = "res://android/build/src/main/java/studio/chaosmos/kit/PlayCore.java"

	func _get_name() -> String:
		return "PlayCoreBuild"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return DEPENDENCIES

	# Runs after --install-android-build-template has unpacked the template and before Gradle starts.
	func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android") or not FileAccess.file_exists(TEMPLATE):
			return
		var source: String = FileAccess.get_file_as_string(SOURCE)
		if FileAccess.file_exists(TARGET) and FileAccess.get_file_as_string(TARGET) == source:
			return
		DirAccess.make_dir_recursive_absolute(TARGET.get_base_dir())
		var file: FileAccess = FileAccess.open(TARGET, FileAccess.WRITE)
		if file == null:
			push_error("PlayCoreBuild: cannot write %s" % TARGET)
			return
		file.store_string(source)
		print("PlayCoreBuild: added %s to the Android build template" % TARGET.get_file())
