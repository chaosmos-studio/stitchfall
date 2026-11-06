class_name StitchfallShop
extends RefCounted

# What is sold, and where. The browser build cannot take payments, so there every piece is free.
# The Android build sells the Wardrobe pack (every runner and fabric, once) and a tip, through Google Play.
# Play's Payments policy forbids pointing players to any other way to pay, so the Android build never links
# to GitHub Sponsors, and the web build's Support link opens it.
#
# The Google Play side is a backend node set into `backend` by the Android build, which calls `grant()`
# when Play confirms a purchase. Until it exists, buying says Play cannot be reached.

const WARDROBE_ID: String = "wardrobe"
const TIP_ID: String = "tip"
const SPONSOR: String = "https://github.com/sponsors/shravanngoswamii"
const WEBSITE: String = "https://chaosmos.studio/stitchfall/"
const SUPPORT: String = "https://chaosmos.studio/stitchfall/support/"
const PRIVACY: String = "https://chaosmos.studio/stitchfall/privacy/"
const TERMS: String = "https://chaosmos.studio/stitchfall/terms/"
const MORE_GAMES: String = "https://chaosmos.studio/games/"

# Captures and tests set it to stage either build anywhere.
static var on_play: bool = OS.has_feature("android")
# Play's formatted price for each product, filled in by the backend.
static var prices: Dictionary = {}
static var backend: Node


static func has_pack(progress: StitchfallProgress) -> bool:
	return progress.owned.has(WARDROBE_ID)


static func is_open(item: Dictionary, progress: StitchfallProgress) -> bool:
	return StitchfallLooks.is_open(item, progress.total_stars(), has_pack(progress), on_play)


# Asks Play to sell a product. Returns a line for the wardrobe to show when Play cannot be asked.
static func buy(id: String) -> String:
	if is_instance_valid(backend) and backend.has_method("buy"):
		backend.call("buy", id)
		return ""
	return "Google Play is not reachable right now."


static func restore() -> String:
	if is_instance_valid(backend) and backend.has_method("restore"):
		backend.call("restore")
		return "Checking Google Play for your purchases."
	return "Google Play is not reachable right now."


static func grant(progress: StitchfallProgress, id: String, owned: bool) -> void:
	if id == TIP_ID:
		progress.tips += 1
	elif owned:
		progress.owned[id] = true
	else:
		progress.owned.erase(id)
	progress.save()


static func price(id: String) -> String:
	return str(prices.get(id, ""))
