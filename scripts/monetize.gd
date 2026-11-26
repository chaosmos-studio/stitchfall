class_name StitchfallMonetize
extends RefCounted

# Each must match a one-time product in Play Console (Monetize with Play, Products, One-time products).
# The Complete pack holds the other three.
const SUPPORTER_ID: String = "supporter"
const LEVELS_ID: String = "all_levels"
const WARDROBE_ID: String = "wardrobe"
const COMPLETE_ID: String = "complete"
# Smallest first, and consumed after each purchase so they can be bought again. Named for their intended US
# prices: 0.99, 1.99, 4.99, 9.99, 19.99 and 49.99.
const TIP_IDS: PackedStringArray = ["tip_1", "tip_2", "tip_5", "tip_10", "tip_20", "tip_50"]
