extends SceneTree


func _initialize() -> void:
	ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
	var result: Error = ProjectSettings.save()
	print("Stitchfall layout saved: ", result)
	quit(result)
