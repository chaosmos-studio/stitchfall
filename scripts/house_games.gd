class_name StitchfallHouseGames
extends RefCounted

## How the house banner shows each of the studio's other games: its line, and its accent in a light and a dark
## look, taken from that game's own two palettes (its brand.gd). The banner is sewn on Stitchfall's linen, so only
## the thread and the GET patch take the other game's colour, in the look that matches Stitchfall's.

const STYLES: Dictionary = {
	"Plumb": {
		"tag": "Roll every marble home",
		"light": {"accent": Color("f05a5a")},
		"dark": {"accent": Color("ff7b7b")},
	},
	"Carillon": {
		"tag": "Every pop is a note",
		"light": {"accent": Color("1d5cb4")},
		"dark": {"accent": Color("7fd0ff")},
	},
	"Apsis": {
		"tag": "Launch every arrow out",
		"light": {"accent": Color("b84c00")},
		"dark": {"accent": Color("ffb35c")},
	},
	"Pyxis": {
		"tag": "Untangle every strand",
		"light": {"accent": Color("236b8e")},
		"dark": {"accent": Color("87c8e6")},
	},
}

## The game's line and its colours in the light or the dark look. A game missing from the table borrows Pyxis's.
static func style(game: String, dark: bool = false) -> Dictionary:
	var entry: Dictionary = STYLES.get(game, STYLES["Pyxis"])
	var variant: Dictionary = entry["dark"] if dark else entry["light"]
	var look: Dictionary = variant.duplicate()
	look["tag"] = entry["tag"]
	return look
