class_name StitchfallStudioIntro
extends RefCounted

# A cold start opens on the studio's beat: the Chaosmos wordmark sewn onto the game's linen (res://intro/, made
# and previewed in studio/chaosmos-intro and copied here by its tools/install.sh, so never edited here). The
# banner stays covered while it plays, and a tap skips it. It plays once a launch, never headless (the tests and
# the route proofs) and never in the capture tool.

# The game's beat, at the one path the studio's install tool writes for every game.
const STYLE: String = "res://intro/beat.gd"
const LAYER: int = 100

static var enabled: bool = true
static var _played: bool = false


# Plays it over `host` and calls `done` once it has faded into Home, or at once when it does not play. `muted`
# when the player has the sound off.
static func play(host: Node, done: Callable, muted: bool = false) -> void:
	if _played or not enabled or DisplayServer.get_name() == "headless":
		done.call()
		return
	_played = true
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = LAYER
	host.add_child(layer)
	var intro: ChaosmosIntro = ChaosmosIntro.new()
	intro.style_name = STYLE
	intro.reveal = true
	intro.muted = muted
	# On Android it opens on the launch screen's mark, over the launch screen's colour (the boot splash's).
	intro.launch = OS.has_feature("android")
	intro.launch_color = ProjectSettings.get_setting("application/boot_splash/bg_color", Color.WHITE)
	layer.add_child(intro)
	intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	StitchfallAds.cover(true)
	# The banner comes back with Home, while the word is still fading over it.
	intro.giving_way.connect(func() -> void: StitchfallAds.cover(false))
	intro.finished.connect(func() -> void:
		layer.queue_free()
		print("STITCHFALL_INTRO_DONE")
		done.call())
