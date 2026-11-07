@tool
extends EditorPlugin

## Turns on R8 for Android release builds, which Godot 4.7 has no export option for (4.8 adds
## gradle_build/minification). R8 strips and renames code nothing calls, and Godot and its plugins reach
## Java by name, through JNI, @UsedByGodot and JavaClassWrapper, so all of that is kept.

var _export: _ShrinkBuild

func _enter_tree() -> void:
	_export = _ShrinkBuild.new()
	add_export_plugin(_export)

func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class _ShrinkBuild extends EditorExportPlugin:
	const GRADLE: String = "res://android/build/build.gradle"
	const RULES: String = "res://android/build/proguard-rules.pro"
	const MARK: String = "minifyEnabled true"
	## Gradle merges a second android block into the template's, so the release build type only gains R8.
	const BLOCK: String = """
android {
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
"""
	## Godot's own rules as 4.8 ships them, then the kit's: PlayCore and the share sheet's FileProvider are
	## reached only through JavaClassWrapper, and the Firebase plugin by name from its GDScript.
	const KEEP: String = """-keep class com.godot.** { *; }
-keep class org.godotengine.** { *; }
-keep class ** extends org.godotengine.godot.plugin.GodotPlugin { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclassmembers class * { @org.godotengine.godot.plugin.UsedByGodot *; }
-keepclasseswithmembernames class * { native <methods>; }
-keep class studio.chaosmos.kit.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-keep class com.godotx.firebase.** { *; }
"""

	func _get_name() -> String:
		return "ShrinkBuild"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	# Runs after --install-android-build-template has unpacked the template and before Gradle starts, so a
	# fresh template is patched on its first build.
	func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android") or not FileAccess.file_exists(GRADLE):
			return
		var rules: FileAccess = FileAccess.open(RULES, FileAccess.WRITE)
		if rules == null:
			push_error("ShrinkBuild: cannot write %s" % RULES)
			return
		rules.store_string(KEEP)
		rules.close()
		var gradle: String = FileAccess.get_file_as_string(GRADLE)
		if gradle.contains(MARK):
			return
		var file: FileAccess = FileAccess.open(GRADLE, FileAccess.WRITE)
		if file == null:
			push_error("ShrinkBuild: cannot write %s" % GRADLE)
			return
		file.store_string(gradle + BLOCK)
		print("ShrinkBuild: turned on R8 for release builds of the Android build template")
