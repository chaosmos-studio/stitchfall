@tool
extends EditorPlugin

## Puts Google Play Games into Android builds once the game has its Play Games project (play_games.json): the
## GodotPlayGameServices library, built without its uncaught exception handler and with Game Stats (the Play
## Games plugin workflow in game-making-skills), the SDK it needs, and the project id the SDK reads from the
## manifest. Without the file a build carries none of it, since the SDK stops an app whose manifest names no
## project.

var _export: _PlayGamesBuild

func _enter_tree() -> void:
	_export = _PlayGamesBuild.new()
	add_export_plugin(_export)

func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class _PlayGamesBuild extends EditorExportPlugin:
	const IDS: String = "res://play_games.json"
	const LIBRARY: String = "GodotPlayGameServices"
	const DEPENDENCIES: PackedStringArray = [
		"com.google.code.gson:gson:2.11.0",
		"com.google.android.gms:play-services-games-v2:22.1.0",
	]
	const TEMPLATE: String = "res://android/build/build.gradle"
	## A file of its own, so the template's strings.xml stays as it is.
	const VALUES: String = "res://android/build/res/values/play_games.xml"

	func _get_name() -> String:
		return "PlayGamesBuild"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	static func app() -> String:
		if not FileAccess.file_exists(IDS):
			return ""
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(IDS))
		return String((data as Dictionary).get("app", "")) if data is Dictionary else ""

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if app() == "":
			return PackedStringArray()
		return PackedStringArray(["play_games/bin/%s-%s.aar" % [LIBRARY, "debug" if debug else "release"]])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return DEPENDENCIES if app() != "" else PackedStringArray()

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if app() == "":
			return ""
		return '<meta-data android:name="com.google.android.gms.games.APP_ID" android:value="@string/game_services_project_id" />\n'

	# Runs after --install-android-build-template has unpacked the template and before Gradle starts.
	func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android") or app() == "" or not FileAccess.file_exists(TEMPLATE):
			return
		var file: FileAccess = FileAccess.open(VALUES, FileAccess.WRITE)
		if file == null:
			push_error("PlayGamesBuild: cannot write %s" % VALUES)
			return
		file.store_string('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n\t<string translatable="false" name="game_services_project_id">%s</string>\n</resources>\n' % app())
		print("PlayGamesBuild: Play Games project %s" % app())
