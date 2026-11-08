class_name StitchfallShop
extends RefCounted

# What is sold, and where. The browser build cannot take payments, so there it sells nothing, every piece of the
# Wardrobe is free and it has no ads. The Android build sells three packs and the Complete pack holding all three,
# and takes tips, through Google Play (the ids in StitchfallMonetize):
# - the Supporter pack turns the banner and the ads between rooms off for good and makes skipping a room free;
# - Every room opens every room at once;
# - the Wardrobe pack opens every runner and fabric.
# Play's Payments policy forbids pointing players to any other way to pay, so the Android build never links to
# GitHub Sponsors, and the web build's Support link opens it.
#
# The Google Play side is a backend node set into `backend` by the Android build (scripts/android/play_billing.gd),
# which calls `grant()` when Play confirms a purchase. Until it exists, buying says Play cannot be reached.

const SPONSOR: String = "https://github.com/sponsors/shravanngoswamii"
const WEBSITE: String = "https://chaosmos.studio/stitchfall/"
const SUPPORT: String = "https://chaosmos.studio/stitchfall/support/"
const PRIVACY: String = "https://chaosmos.studio/stitchfall/privacy/"
const MORE_GAMES: String = "https://chaosmos.studio/games/"
const STORE: String = "https://play.google.com/store/apps/details?id=com.shravangoswami.stitchfall"
const UNREACHABLE: String = "Google Play is not reachable right now."
const KEEP_ROW: String = "Yours to keep after one purchase"
# Google Play draws its payment sheet itself, and on many phones holds it upright even over a landscape game. No
# app can turn it, so the page before a purchase says so.
const PAYMENT_NOTE: String = "Google Play takes the payment. On some phones its sheet opens upright."

# Captures and tests set it to stage either build anywhere.
static var on_play: bool = OS.has_feature("android")
# Play's formatted price for each product, filled in by the backend.
static var prices: Dictionary = {}
# Play's price in millionths of its currency, and the currency's code, for the Complete pack's saving.
static var micros: Dictionary = {}
static var currencies: Dictionary = {}
static var backend: Node


# In the order the Shop page lists them.
static func one_time_ids() -> PackedStringArray:
	return PackedStringArray([StitchfallMonetize.COMPLETE_ID, StitchfallMonetize.SUPPORTER_ID,
		StitchfallMonetize.LEVELS_ID, StitchfallMonetize.WARDROBE_ID])


static func all_ids() -> PackedStringArray:
	return one_time_ids() + StitchfallMonetize.TIP_IDS


# What the Complete pack holds.
static func parts() -> PackedStringArray:
	return PackedStringArray([StitchfallMonetize.SUPPORTER_ID, StitchfallMonetize.LEVELS_ID, StitchfallMonetize.WARDROBE_ID])


static func is_tip(id: String) -> bool:
	return StitchfallMonetize.TIP_IDS.has(id)


static func owns(progress: StitchfallProgress, id: String) -> bool:
	return progress.owned.has(id)


static func has(progress: StitchfallProgress, id: String) -> bool:
	return owns(progress, id) or (parts().has(id) and owns(progress, StitchfallMonetize.COMPLETE_ID))


static func ads_off(progress: StitchfallProgress) -> bool:
	return has(progress, StitchfallMonetize.SUPPORTER_ID)


static func levels_open(progress: StitchfallProgress) -> bool:
	return has(progress, StitchfallMonetize.LEVELS_ID)


static func has_pack(progress: StitchfallProgress) -> bool:
	return has(progress, StitchfallMonetize.WARDROBE_ID)


# The Complete pack is offered only while none of it is owned, so it never sells a part twice.
static func offers_complete(progress: StitchfallProgress) -> bool:
	for id: String in parts() + PackedStringArray([StitchfallMonetize.COMPLETE_ID]):
		if owns(progress, id):
			return false
	return true


static func is_open(item: Dictionary, progress: StitchfallProgress) -> bool:
	return StitchfallLooks.is_open(item, progress.total_stars(), has_pack(progress), on_play)


# A room opens by sewing the one before it, or by skipping it, or with Every room.
static func room_open(progress: StitchfallProgress, room: int) -> bool:
	return progress.is_open(room) or (on_play and levels_open(progress))


# Asks Play to sell a product. Returns a line for the page to show when Play cannot be asked.
static func buy(id: String) -> String:
	if is_instance_valid(backend) and backend.has_method("buy"):
		backend.call("buy", id)
		return ""
	return UNREACHABLE


static func restore() -> String:
	if is_instance_valid(backend) and backend.has_method("restore"):
		backend.call("restore")
		return "Checking Google Play for your purchases."
	return UNREACHABLE


# A tip counts one more. A pack is kept or taken away, which is how a refund reaches the game. Turning the
# Supporter pack on or off stops or starts the game's ads.
static func grant(progress: StitchfallProgress, id: String, owned: bool) -> void:
	var quiet: bool = ads_off(progress)
	if is_tip(id):
		progress.tips += 1
	elif owned:
		progress.owned[id] = true
	else:
		progress.owned.erase(id)
	progress.save()
	if progress == StitchfallAds.progress and ads_off(progress) != quiet:
		if ads_off(progress):
			StitchfallAds.stop()
		else:
			StitchfallAds.start()


static func price(id: String) -> String:
	return str(prices.get(id, ""))


# How much less the Complete pack costs than its three parts bought apart, in whole percent rounded down. It is 0
# until Play has priced all four in one currency, so the page never guesses.
static func saving() -> int:
	var whole: int = int(micros.get(StitchfallMonetize.COMPLETE_ID, 0))
	var currency: String = str(currencies.get(StitchfallMonetize.COMPLETE_ID, ""))
	var apart: int = 0
	for id: String in parts():
		var part: int = int(micros.get(id, 0))
		if part <= 0 or str(currencies.get(id, "")) != currency:
			return 0
		apart += part
	if whole <= 0 or apart <= whole:
		return 0
	return floori(100.0 * float(apart - whole) / float(apart))


static func title(id: String) -> String:
	match id:
		StitchfallMonetize.COMPLETE_ID:
			return "Complete pack"
		StitchfallMonetize.SUPPORTER_ID:
			return "Supporter pack"
		StitchfallMonetize.LEVELS_ID:
			return "Every room"
		StitchfallMonetize.WARDROBE_ID:
			return "Wardrobe pack"
		"tip_1":
			return "Small tip"
		"tip_5":
			return "Big tip"
		"tip_10":
			return "Generous tip"
		"tip_20":
			return "Very generous tip"
		"tip_50":
			return "Huge thank you"
	return "Tip"


# The page before a purchase: one line on what it is for, then what it holds, a row each.
static func pitch(id: String) -> String:
	match id:
		StitchfallMonetize.COMPLETE_ID:
			return "Everything in the Shop, in one purchase."
		StitchfallMonetize.SUPPORTER_ID:
			return "One purchase that helps me make the next game."
		StitchfallMonetize.LEVELS_ID:
			return "Rooms open one by one. This opens them all now."
		StitchfallMonetize.WARDROBE_ID:
			return "Six runners and six fabrics only this pack opens."
	return "A thank-you to the maker of this game."


static func details(id: String) -> PackedStringArray:
	match id:
		StitchfallMonetize.COMPLETE_ID:
			return PackedStringArray(["The Supporter pack: no ads, free skips", "Every room, open now", "The Wardrobe pack: every runner and fabric", KEEP_ROW])
		StitchfallMonetize.SUPPORTER_ID:
			return PackedStringArray(["No banner on the menus", "No ads between rooms", "Skip any room for free", KEEP_ROW])
		StitchfallMonetize.LEVELS_ID:
			return PackedStringArray(["Every room open now", "Play them in any order", "Stars still earned by sewing each room", KEEP_ROW])
		StitchfallMonetize.WARDROBE_ID:
			return PackedStringArray(["Patch, Bobbin, Tam, Moth, Fennel and Indigo", "River, Dunes, Fern, Night quilt, Rain and Frost", "Worn from the Wardrobe any time", KEEP_ROW])
	return PackedStringArray(["Goes into making the next game", "Opens nothing new", "Give again whenever you like"])


# The page's button: what tapping it does, with Play's price once Play has given one.
static func buy_caption(id: String) -> String:
	var verb: String = "TIP" if is_tip(id) else ("SUPPORT" if id == StitchfallMonetize.SUPPORTER_ID else "BUY")
	return verb if price(id).is_empty() else "%s  %s" % [verb, price(id)]


# A pack's name on its Shop card, where the word "pack" would not fit.
static func card_title(id: String) -> String:
	return title(id).trim_suffix(" pack").to_upper()


# What each pack holds, a line each, as its card in the Shop lists it.
static func rows(id: String) -> PackedStringArray:
	match id:
		StitchfallMonetize.COMPLETE_ID:
			return PackedStringArray(["All three, for less", "Supporter pack", "Every room", "Wardrobe pack"])
		StitchfallMonetize.SUPPORTER_ID:
			return PackedStringArray(["No banner", "No ads between rooms", "Free room skips", "Helps the next game"])
		StitchfallMonetize.LEVELS_ID:
			return PackedStringArray(["Every room open now", "Play in any order", "Stars still earned"])
		StitchfallMonetize.WARDROBE_ID:
			return PackedStringArray(["Every runner", "Every room fabric", "Yours to keep"])
	return PackedStringArray()


static func glyph(id: String) -> String:
	match id:
		StitchfallMonetize.COMPLETE_ID:
			return "bag"
		StitchfallMonetize.SUPPORTER_ID:
			return "star"
		StitchfallMonetize.LEVELS_ID:
			return "levels"
		StitchfallMonetize.WARDROBE_ID:
			return "wardrobe"
	return "gift"


# What Play's answer to a purchase says, once it goes through.
static func thanks(id: String) -> String:
	match id:
		StitchfallMonetize.COMPLETE_ID:
			return "Everything is yours. Thank you!"
		StitchfallMonetize.SUPPORTER_ID:
			return "Thank you for supporting Stitchfall!"
		StitchfallMonetize.LEVELS_ID:
			return "Every room is open. Thank you!"
		StitchfallMonetize.WARDROBE_ID:
			return "Every runner and fabric is yours. Thank you!"
	return "Thank you for the tip! It keeps the next game coming."
