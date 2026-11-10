class_name StitchfallHouseAds
extends StitchfallAdBackend

# The studio's own ads, as the kit's HouseAds: a banner for another of its games where an ad's banner would be, and
# nothing else. No ad between rooms and no stand-in for a video: with no video to play, StitchfallAds gives the
# reward for nothing. The banner fills in under AdMob whenever it has none, and stands in for it while
# StitchfallMonetize.ADMOB is false. Standing in on Android, they still ask Google's consent service whether this
# phone needs consent, since Analytics waits on that answer.

const CONSENT_SCRIPT: String = "res://scripts/android/consent.gd"

# The game the next banner shows: they take turns.
static var _turn: int = 0

# False when filling in under AdMob, which asks for consent itself.
var consent: bool = true
var _layer: CanvasLayer
var _banner: StitchfallHouseBanner
var _pending: bool = false


func _ready() -> void:
	if consent and OS.has_feature("android") and Engine.has_singleton("PoingGodotAdMob"):
		add_child(load(CONSENT_SCRIPT).new() as Node)


static func next_game() -> Dictionary:
	var games: Array[Dictionary] = StitchfallStudio.others()
	var game: Dictionary = games[_turn % games.size()]
	_turn += 1
	return game


# Each page that shows the banner shows the next game.
func set_banner(on: bool) -> void:
	# The backend joins the tree a frame late, and the first page may ask for its banner in that frame.
	if not is_inside_tree():
		_pending = on
		if not tree_entered.is_connected(_enter_with_banner):
			tree_entered.connect(_enter_with_banner, CONNECT_ONE_SHOT)
		return
	if StitchfallStudio.others().is_empty() or (_layer == null and not on):
		return
	if _layer == null:
		_make_banner()
	elif on and not _layer.visible:
		_banner.show_game(next_game())
	var rect: Rect2 = StitchfallAds.banner_rect()
	_banner.position = rect.position
	_banner.size = rect.size
	_layer.visible = on


func _enter_with_banner() -> void:
	set_banner.call_deferred(_pending)


func stop() -> void:
	_pending = false
	if _layer != null:
		_layer.queue_free()
		_layer = null
		_banner = null
		banner_changed.emit(0.0)


func _make_banner() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = StitchfallAds.BANNER_LAYER
	add_child(_layer)
	_banner = StitchfallHouseBanner.new()
	_layer.add_child(_banner)
	_banner.show_game(next_game())
	banner_changed.emit(StitchfallAds.banner_rect().size.y)
