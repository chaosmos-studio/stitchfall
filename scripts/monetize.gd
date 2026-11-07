class_name StitchfallMonetize
extends RefCounted

# Ids ship inside the app, so none of them is a secret. Debug builds load Google's test units instead.
# Keep the project setting admob/general/android/app_id equal to APP_ID: the AdMob plugin writes that setting
# into the manifest, tools/configure_android.gd sets it from here, and a test checks the two agree.

# AdMob's ads, with the studio's own house ads (a banner for another of its games, and a card for one in place of
# a video) filling in whenever AdMob has nothing to give, as before the account is approved. With false, house
# ads alone.
const ADMOB: bool = true
const APP_ID: String = "ca-app-pub-3135321730568420~7142610841"
const BANNER_ID: String = "ca-app-pub-3135321730568420/1826704985"
const INTERSTITIAL_ID: String = "ca-app-pub-3135321730568420/5268302721"
const REWARDED_ID: String = "ca-app-pub-3135321730568420/7089630792"

# Each must match a one-time product in Play Console (Monetize with Play, Products, One-time products).
# The Complete pack holds the other three.
const SUPPORTER_ID: String = "supporter"
const LEVELS_ID: String = "all_levels"
const WARDROBE_ID: String = "wardrobe"
const COMPLETE_ID: String = "complete"
# Smallest first, and consumed after each purchase so they can be bought again. Named for their intended US
# prices: 0.99, 1.99, 4.99, 9.99, 19.99 and 49.99.
const TIP_IDS: PackedStringArray = ["tip_1", "tip_2", "tip_5", "tip_10", "tip_20", "tip_50"]
