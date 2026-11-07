extends SceneTree

# The project settings the Android build needs, saved through ProjectSettings so each keeps its type:
#   godot --headless --path . -s res://tools/configure_android.gd
# The plugins add Google Play Billing, AdMob with Google's consent service, Firebase Analytics, Play's review
# card and in-app updates, R8, and Google Play Games to the Gradle build. Play Games' plugin adds nothing until
# play_games.json is at the root, so a build made before the console setup carries none of it. The AdMob plugin
# writes admob/general/android/app_id into the manifest, so it is set from StitchfallMonetize.APP_ID. Back no
# longer quits, because the game steps back a screen itself. The version lives in CHANGELOG.md, so project.godot
# no longer carries one.

const PLUGINS: PackedStringArray = [
	"res://addons/GodotGooglePlayBilling/plugin.cfg",
	"res://addons/admob/plugin.cfg",
	"res://addons/godotx_firebase/plugin.cfg",
	"res://addons/firebase_build/plugin.cfg",
	"res://addons/play_core/plugin.cfg",
	"res://addons/shrink_build/plugin.cfg",
	"res://addons/play_games/plugin.cfg",
]
const APP_ID_SETTING: String = "admob/general/android/app_id"


func _initialize() -> void:
	for plugin: String in PLUGINS:
		if not FileAccess.file_exists(plugin):
			print("missing %s: copy the whole addon in before enabling it" % plugin)
			quit(1)
			return
	ProjectSettings.set_setting("editor_plugins/enabled", PLUGINS)
	ProjectSettings.set_setting(APP_ID_SETTING, StitchfallMonetize.APP_ID)
	ProjectSettings.set_setting("application/config/quit_on_go_back", false)
	ProjectSettings.set_setting("application/config/version", null)
	var status: int = ProjectSettings.save()
	print("configured Android settings, save status %d" % status)
	quit(0 if status == OK else 1)
