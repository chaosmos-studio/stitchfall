class_name StitchfallAdBackend
extends Node

# A Node that lives in the tree for as long as the app runs, since the plugin calls back into it. AdMob's
# backend (scripts/android/admob.gd) and the house ads both answer to this.

# In design pixels, and 0 once there is no banner.
signal banner_changed(height: float)
# Emitted once for every `present`, and never from inside it.
signal finished(kind: StringName, shown: bool, earned: bool)

const INTERSTITIAL: StringName = &"interstitial"
const REWARDED: StringName = &"rewarded"


func ready_to_show(_kind: StringName) -> bool:
	return false


func present(kind: StringName) -> void:
	finished.emit.call_deferred(kind, false, false)


func set_banner(_on: bool) -> void:
	pass


# Whether a rewarded video is loaded and would play now. Without one, StitchfallAds gives the reward for nothing.
func video_ready() -> bool:
	return false


func privacy_required() -> bool:
	return false


func open_privacy() -> void:
	pass


func match_sound(_on: bool) -> void:
	pass


func stop() -> void:
	pass


func resume() -> void:
	pass
