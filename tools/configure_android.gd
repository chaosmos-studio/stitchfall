extends SceneTree

# The project settings the Android build needs, saved through ProjectSettings so each keeps its type:
#   godot --headless --path . -s res://tools/configure_android.gd
# The billing plugin adds Google Play Billing to the Gradle build. Back no longer quits, because the game
# steps back a screen itself. The version lives in CHANGELOG.md, so project.godot no longer carries one.

func _initialize() -> void:
	ProjectSettings.set_setting("editor_plugins/enabled", PackedStringArray(["res://addons/GodotGooglePlayBilling/plugin.cfg"]))
	ProjectSettings.set_setting("application/config/quit_on_go_back", false)
	ProjectSettings.set_setting("application/config/version", null)
	var status: int = ProjectSettings.save()
	print("configured Android settings, save status %d" % status)
	quit(0 if status == OK else 1)
