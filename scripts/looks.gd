class_name StitchfallLooks
extends RefCounted

# Everything in the wardrobe, and how each piece opens.
# On the web every piece is open. On Android, trails, unravels and buttons open with stars earned in the rooms,
# while runners and fabrics come with the Wardrobe pack bought through Google Play.
# A runner shows up only once its art is in assets/art/runners/<id>/, so new runners need no code.

const KINDS: PackedStringArray = ["runner", "trail", "unravel", "button", "fabric"]
const KIND_NAMES: PackedStringArray = ["Runners", "Trails", "Unravels", "Buttons", "Fabrics"]
const DEFAULTS: Dictionary = {
	"runner": "seam",
	"trail": "trail_none",
	"unravel": "unravel_threads",
	"button": "button_brass",
	"fabric": "fabric_linen",
}

const ITEMS: Array[Dictionary] = [
	{"id": "seam", "kind": "runner", "name": "Seam Runner", "line": "Scarf, satchel, and no fear of falling.", "stars": 0, "paid": false},
	{"id": "patch", "kind": "runner", "name": "Patch", "line": "A rag doll with button eyes.", "stars": 0, "paid": true},
	{"id": "bobbin", "kind": "runner", "name": "Bobbin", "line": "Mustard raincoat, spool in pocket.", "stars": 0, "paid": true},
	{"id": "tam", "kind": "runner", "name": "Tam", "line": "A tailor's apprentice, tape round the neck.", "stars": 0, "paid": true},
	{"id": "moth", "kind": "runner", "name": "Moth", "line": "Felt wings, follows the light.", "stars": 0, "paid": true},
	{"id": "fennel", "kind": "runner", "name": "Fennel", "line": "A knitted fox, quick on the turn.", "stars": 0, "paid": true},
	{"id": "indigo", "kind": "runner", "name": "Indigo", "line": "Patched denim, all knees and elbows.", "stars": 0, "paid": true},
	{"id": "trail_none", "kind": "trail", "name": "No trail", "stars": 0, "paid": false, "colours": []},
	{"id": "trail_cream", "kind": "trail", "name": "Cream thread", "stars": 3, "paid": false, "colours": [Color("f6e6c9")]},
	{"id": "trail_rust", "kind": "trail", "name": "Rust thread", "stars": 8, "paid": false, "colours": [Color("b45d4c")]},
	{"id": "trail_gold", "kind": "trail", "name": "Gold thread", "stars": 15, "paid": false, "colours": [Color("e7b84f")]},
	{"id": "trail_stitch", "kind": "trail", "name": "Running stitch", "stars": 24, "paid": false, "colours": [Color("493a37")], "dashed": true},
	{"id": "trail_rainbow", "kind": "trail", "name": "Rainbow yarn", "stars": 40, "paid": false, "colours": [Color("e06b5a"), Color("e7b84f"), Color("7bb07a"), Color("6f9bd1"), Color("9a7bc8")]},
	{"id": "unravel_threads", "kind": "unravel", "name": "Loose threads", "stars": 0, "paid": false, "colours": [Color("f6e6c9")], "shape": "thread"},
	{"id": "unravel_buttons", "kind": "unravel", "name": "Button burst", "stars": 6, "paid": false, "colours": [Color("e4c77f"), Color("d7a998"), Color("8cd1be")], "shape": "button"},
	{"id": "unravel_petals", "kind": "unravel", "name": "Petals", "stars": 18, "paid": false, "colours": [Color("e88a7a"), Color("f3c1b4"), Color("f6e6c9")], "shape": "petal"},
	{"id": "unravel_stars", "kind": "unravel", "name": "Star sequins", "stars": 30, "paid": false, "colours": [Color("e7b84f"), Color("fff3d6")], "shape": "star"},
	{"id": "unravel_snips", "kind": "unravel", "name": "Snippets", "stars": 45, "paid": false, "colours": [Color("e06b5a"), Color("7bb07a"), Color("6f9bd1"), Color("e7b84f")], "shape": "snip"},
	{"id": "button_brass", "kind": "button", "name": "Brass", "stars": 0, "paid": false, "colour": Color("e4c77f")},
	{"id": "button_pearl", "kind": "button", "name": "Pearl", "stars": 5, "paid": false, "colour": Color("efe9f2")},
	{"id": "button_wood", "kind": "button", "name": "Walnut", "stars": 12, "paid": false, "colour": Color("a8774f")},
	{"id": "button_rose", "kind": "button", "name": "Rose", "stars": 21, "paid": false, "colour": Color("e88a96")},
	{"id": "button_jade", "kind": "button", "name": "Jade", "stars": 33, "paid": false, "colour": Color("6fbf9a")},
	{"id": "button_night", "kind": "button", "name": "Midnight", "stars": 50, "paid": false, "colour": Color("5e6aa8")},
	{"id": "fabric_linen", "kind": "fabric", "name": "Linen", "stars": 0, "paid": false, "backdrop": 0, "art": "res://assets/art/linen_landscape.png"},
	{"id": "fabric_water", "kind": "fabric", "name": "River", "stars": 0, "paid": true, "backdrop": 4, "art": "res://assets/art/cloth_water.webp"},
	{"id": "fabric_dunes", "kind": "fabric", "name": "Dunes", "stars": 0, "paid": true, "backdrop": 5, "art": "res://assets/art/cloth_dunes.webp"},
	{"id": "fabric_forest", "kind": "fabric", "name": "Fern", "stars": 0, "paid": true, "backdrop": 6, "art": "res://assets/art/cloth_forest.webp"},
	{"id": "fabric_night", "kind": "fabric", "name": "Night quilt", "stars": 0, "paid": true, "backdrop": 7, "art": "res://assets/art/cloth_night.webp"},
	{"id": "fabric_rain", "kind": "fabric", "name": "Rain", "stars": 0, "paid": true, "backdrop": 8, "art": "res://assets/art/cloth_rain.webp"},
	{"id": "fabric_frost", "kind": "fabric", "name": "Frost", "stars": 0, "paid": true, "backdrop": 9, "art": "res://assets/art/cloth_frost.webp"},
]

const SEAM_ART: Dictionary = {
	"run": "res://assets/art/seam_runner_run.png",
	"actions": "res://assets/art/seam_runner_actions.png",
	"poses": ["res://assets/art/hero_pose_0.png", "res://assets/art/hero_pose_1.png", "res://assets/art/hero_pose_2.png", "res://assets/art/hero_pose_3.png"],
	"dance": "res://assets/art/runners/seam/dance.png",
}


static func find(id: String) -> Dictionary:
	for item: Dictionary in ITEMS:
		if item["id"] == id:
			return item
	return {}


# A kind's pieces in wardrobe order, leaving out runners whose art has not arrived.
static func items(kind: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for item: Dictionary in ITEMS:
		if item["kind"] == kind and (kind != "runner" or has_art(item["id"])):
			found.append(item)
	return found


static func has_art(runner: String) -> bool:
	return ResourceLoader.exists(runner_art(runner)["run"])


static func runner_art(runner: String) -> Dictionary:
	if runner == "seam":
		return SEAM_ART
	var folder: String = "res://assets/art/runners/%s/" % runner
	return {
		"run": folder + "run.png",
		"actions": folder + "actions.png",
		"poses": [folder + "pose_0.png", folder + "pose_1.png", folder + "pose_2.png", folder + "pose_3.png"],
		"dance": folder + "dance.png",
	}


static func is_open(item: Dictionary, stars: int, has_pack: bool, on_play: bool) -> bool:
	if not on_play:
		return true
	if bool(item["paid"]):
		return has_pack
	return stars >= int(item["stars"])


# What a locked piece asks for, as the wardrobe tile shows it.
static func price_text(item: Dictionary) -> String:
	return "Wardrobe pack" if bool(item["paid"]) else "%d stars" % int(item["stars"])


# The pieces that a gain from `before` to `after` stars opens, for the clear card to call out.
static func opened_between(before: int, after: int) -> Array[Dictionary]:
	var opened: Array[Dictionary] = []
	for item: Dictionary in ITEMS:
		var need: int = int(item["stars"])
		if not bool(item["paid"]) and need > before and need <= after:
			opened.append(item)
	return opened


# The frames the runner dances to on Home and the clear card: its dance sheet of eight frames in a 4 by 2 grid
# once it arrives, or its four poses until then.
static func dance_frames(runner: String) -> SpriteFrames:
	var art: Dictionary = runner_art(runner)
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("dance")
	frames.set_animation_loop("dance", true)
	if ResourceLoader.exists(art["dance"]):
		var sheet: Texture2D = load(art["dance"]) as Texture2D
		var cell: Vector2 = Vector2(sheet.get_width() / 4.0, sheet.get_height() / 2.0)
		frames.set_animation_speed("dance", 8.0)
		for index: int in range(8):
			var frame: AtlasTexture = AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(Vector2(float(index % 4) * cell.x, float(index / 4) * cell.y), cell)
			frames.add_frame("dance", frame)
		return frames
	frames.set_animation_speed("dance", 1.0)
	for path: String in art["poses"]:
		frames.add_frame("dance", load(path) as Texture2D, 1.45)
	return frames


static func draw_button(canvas: CanvasItem, center: Vector2, radius: float, colour: Color) -> void:
	var ink: Color = Color("493a37")
	canvas.draw_circle(center + Vector2(2, 3) * radius / 18.0, radius, Color(ink, 0.25))
	canvas.draw_circle(center, radius, ink)
	canvas.draw_circle(center, radius * 0.83, colour)
	canvas.draw_arc(center, radius * 0.62, 0.0, TAU, 24, colour.darkened(0.18), maxf(1.0, radius * 0.08), true)
	for hole: int in range(4):
		canvas.draw_circle(center + Vector2.from_angle(float(hole) * TAU / 4.0 + PI * 0.25) * radius * 0.39, radius * 0.12, ink)


# A short wavy length of a trail's thread, for its wardrobe tile.
static func draw_trail_sample(canvas: CanvasItem, from: Vector2, to: Vector2, item: Dictionary) -> void:
	var colours: Array = item["colours"]
	if colours.is_empty():
		return
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in range(25):
		var t: float = float(step) / 24.0
		points.append(from.lerp(to, t) + Vector2(0, sin(t * TAU * 1.5) * 14.0))
	for index: int in range(points.size() - 1):
		if bool(item.get("dashed", false)) and index % 2 == 1:
			continue
		var colour: Color = colours[index * colours.size() / (points.size() - 1)]
		canvas.draw_line(points[index], points[index + 1], colour, 5.0, true)
