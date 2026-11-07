extends SceneTree

# Replays one chapter's proofs, the same checks tests/run_tests.gd makes for the chapters in the campaign, so a
# chapter can be proved while it is still being built:
#   godot --headless --path . -s res://tools/prove.gd -- <chapter id>
# Prints each check and ends with "PROVE <id>: N passed, M failed".

func _initialize() -> void:
	_run()


func _run() -> void:
	StitchfallProgress.path = "user://prove_progress.cfg"
	var id: String = OS.get_cmdline_user_args()[0]
	var checks: Array[Array] = await StitchfallRoute.prove(self, id)
	var failed: int = 0
	for check: Array in checks:
		print("%s %s" % ["  ok  " if check[1] else "  FAIL", check[0]])
		if not check[1]:
			failed += 1
	print("PROVE %s: %d passed, %d failed" % [id, checks.size() - failed, failed])
	quit()
