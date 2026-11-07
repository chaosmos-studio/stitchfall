class_name StitchfallHouseAds
extends StitchfallAdBackend

# The studio's own ads, as the kit's HouseAds: a banner for another of its games where an ad's banner would be, a
# quick game of one in place of a rewarded video, which the player may close at once and still earns the reward,
# and no interstitials at all. Nothing is fetched, so both are always ready. They fill in under AdMob whenever it
# has nothing to give, and stand in for it while StitchfallMonetize.ADMOB is false. Standing in on Android, they
# still ask Google's consent service whether this phone needs consent, since Analytics waits on that answer.

const CONSENT_SCRIPT: String = "res://scripts/android/consent.gd"

# The game the next banner or quick game shows: they take turns.
static var _turn: int = 0
static var _card: StitchfallHouseCard

# False when filling in under AdMob, which asks for consent itself.
var consent: bool = true
var _layer: CanvasLayer
var _banner: StitchfallHouseBanner
var _pending: bool = false


func _ready() -> void:
	if consent and OS.has_feature("android") and Engine.has_singleton("PoingGodotAdMob"):
		add_child(load(CONSENT_SCRIPT).new() as Node)


func ready_to_show(kind: StringName) -> bool:
	return kind == REWARDED and not StitchfallStudio.others().is_empty() and not is_instance_valid(_card)


func present(kind: StringName) -> void:
	if not ready_to_show(kind):
		finished.emit.call_deferred(kind, false, false)
		return
	var card: StitchfallHouseCard = open_card(next_game())
	await card.closed
	finished.emit(kind, true, true)


static func next_game() -> Dictionary:
	var games: Array[Dictionary] = StitchfallStudio.others()
	var game: Dictionary = games[_turn % games.size()]
	_turn += 1
	return game


static func open_card(game: Dictionary) -> StitchfallHouseCard:
	_card = StitchfallHouseCard.new()
	_card.game = game
	_card.closed.connect(func() -> void: StitchfallAds.cover(false), CONNECT_ONE_SHOT)
	StitchfallAds.cover(true)
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_card)
	return _card


static func close_card() -> bool:
	if not is_instance_valid(_card) or _card.is_queued_for_deletion():
		return false
	_card.close()
	return true


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
