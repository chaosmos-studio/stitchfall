@tool
extends EditorPlugin

## Does what the godotx_firebase plugin leaves to be done by hand in each Android build.

var _export: _FirebaseBuild

func _enter_tree() -> void:
	_export = _FirebaseBuild.new()
	add_export_plugin(_export)

func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class _FirebaseBuild extends EditorExportPlugin:
	const CONFIG: String = "res://google-services.json"
	const GRADLE: String = "res://android/build/build.gradle"
	const SERVICES: String = "com.google.gms.google-services"
	const SERVICES_CLASSPATH: String = "com.google.gms:google-services:4.4.4"
	## The kit's Analytics counts screens itself, since Firebase would only ever see Godot's one activity,
	## and no analytics reads the advertising id or Android's device id.
	const OFF: PackedStringArray = [
		"google_analytics_automatic_screen_reporting_enabled",
		"google_analytics_adid_collection_enabled",
		"google_analytics_ssaid_collection_enabled",
	]
	## Analytics' ad attribution through Android's Privacy Sandbox, which nothing here uses.
	const UNUSED_PERMISSIONS: PackedStringArray = [
		"android.permission.ACCESS_ADSERVICES_ATTRIBUTION",
		"android.permission.ACCESS_ADSERVICES_AD_ID",
	]

	func _get_name() -> String:
		return "FirebaseBuild"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	# Runs after --install-android-build-template has unpacked the template and before Gradle starts, so a
	# fresh template is patched on its first build.
	func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android") or not FileAccess.file_exists(CONFIG) or not FileAccess.file_exists(GRADLE):
			return
		var gradle: String = FileAccess.get_file_as_string(GRADLE)
		if gradle.contains(SERVICES):
			return
		# Gradle allows only a buildscript block above the template's plugins block.
		var head: String = "buildscript {\n    repositories {\n        google()\n        mavenCentral()\n    }\n" \
			+ "    dependencies {\n        classpath '%s'\n    }\n}\n\n" % SERVICES_CLASSPATH
		var file: FileAccess = FileAccess.open(GRADLE, FileAccess.WRITE)
		if file == null:
			push_error("FirebaseBuild: cannot write %s" % GRADLE)
			return
		file.store_string(head + gradle + "\napply plugin: '%s'\n" % SERVICES)
		print("FirebaseBuild: applied %s to the Android build template" % SERVICES)

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if not FileAccess.file_exists(CONFIG):
			return ""
		var contents: String = ""
		for key: String in OFF:
			contents += '<meta-data android:name="%s" android:value="false" />\n' % key
		return contents

	func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if not FileAccess.file_exists(CONFIG):
			return ""
		var contents: String = ""
		for permission: String in UNUSED_PERMISSIONS:
			contents += '<uses-permission android:name="%s" tools:node="remove" />\n' % permission
		return contents
