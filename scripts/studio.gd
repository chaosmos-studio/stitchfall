class_name StitchfallStudio
extends RefCounted

# The studio's other games, for the house ads, kept in step with kit/shell/studio.gd in the kit games. The icons
# in assets/studio/ are copies of the kit's.

const NAME: String = "Chaosmos"

const GAMES: Array[Dictionary] = [
	{
		"name": "Plumb",
		"line": "Tilt the board and every marble rolls at once.",
		"icon": "res://assets/studio/plumb.webp",
		"store": "https://play.google.com/store/apps/details?id=com.shravangoswami.plumb",
		"web": "https://chaosmos.studio/plumb/play/",
	},
	{
		"name": "Carillon",
		"line": "One tap, and the whole chain plays a tune.",
		"icon": "res://assets/studio/carillon.webp",
		"store": "https://play.google.com/store/apps/details?id=com.shravangoswami.carillon",
		"web": "https://chaosmos.studio/carillon/play/",
	},
	{
		"name": "Apsis",
		"line": "Send every arrow out of orbit, in the right order.",
		"icon": "res://assets/studio/apsis.webp",
		"store": "https://play.google.com/store/apps/details?id=com.shravangoswami.apsis",
		"web": "https://chaosmos.studio/apsis/play/",
	},
	{
		"name": "Pyxis",
		"line": "Pull the knots apart until no strands cross.",
		"icon": "res://assets/studio/pyxis.webp",
		"store": "https://play.google.com/store/apps/details?id=com.shravangoswami.pyxis",
		"web": "https://chaosmos.studio/pyxis/play/",
	},
]


# The games that are out, for the house ads. A game marked "live": false is still on closed testing.
static func others() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for game: Dictionary in GAMES:
		if bool(game.get("live", true)):
			out.append(game)
	return out


static func link(game: Dictionary) -> String:
	return String(game["store"] if StitchfallShop.on_play else game["web"])
