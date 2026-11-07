extends Node

# Google Play's side of the Wardrobe, made only in the Android build, the way the kit games' play_billing.gd
# works. Play refunds a one-time product left unacknowledged for three days, so the Wardrobe pack is
# acknowledged, and a tip is consumed so it can be given again.

signal said(line: String)
signal changed

const PURCHASED: int = 1
const PENDING: int = 2
const PRODUCTS: PackedStringArray = [StitchfallShop.WARDROBE_ID, StitchfallShop.TIP_ID]

var progress: StitchfallProgress
var _client: BillingClient
var _listed: Dictionary = {}
var _loud_restore: bool = false
# Product ids by purchase token, so each tip sent to be consumed is counted once.
var _consuming: Dictionary = {}


func _ready() -> void:
	_client = BillingClient.new()
	add_child(_client)
	_client.connected.connect(_on_connected)
	_client.query_product_details_response.connect(_on_details)
	_client.query_purchases_response.connect(_on_purchases)
	_client.on_purchase_updated.connect(_on_purchase_updated)
	_client.consume_purchase_response.connect(_on_consumed)
	_client.start_connection()


func _on_connected() -> void:
	_client.query_purchases(BillingClient.ProductType.INAPP)
	_ask_prices()


# A promo code redeemed in the Play Store while the game waits in the background is a purchase made outside
# it, which only a fresh query sees, so coming back asks again.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and _client != null:
		restore(true)


func _ask_prices() -> void:
	_client.query_product_details(PRODUCTS, BillingClient.ProductType.INAPP)


func _on_details(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return
	for entry: Variant in response.get("product_details", []):
		var details: Dictionary = entry
		var id: String = String(details.get("product_id", ""))
		var offer: Variant = details.get("one_time_purchase_offer_details")
		if PRODUCTS.has(id) and offer is Dictionary:
			StitchfallShop.prices[id] = String((offer as Dictionary).get("formatted_price", ""))
			_listed[id] = true
	changed.emit()


func buy(id: String) -> void:
	if not _client.is_ready():
		_client.start_connection()
		said.emit("Google Play is not reachable right now.")
		return
	if not _listed.has(id):
		_ask_prices()
		said.emit("That is not in the store yet. Try again in a moment.")
		return
	var result: Dictionary = _client.purchase(id)
	var code: int = int(result.get("response_code", -1))
	if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
		restore(false)
	elif code != BillingClient.BillingResponseCode.OK:
		said.emit("Google Play could not start the purchase.")


func restore(quiet: bool = false) -> void:
	_loud_restore = not quiet
	if not _client.is_ready():
		_client.start_connection()
		if not quiet:
			said.emit("Google Play is not reachable right now.")
		return
	_client.query_purchases(BillingClient.ProductType.INAPP)


func _on_purchase_updated(response: Dictionary) -> void:
	match int(response.get("response_code", -1)):
		BillingClient.BillingResponseCode.OK:
			var states: Dictionary = _take(response.get("purchases", []))
			if int(states.get(StitchfallShop.WARDROBE_ID, 0)) == PURCHASED:
				StitchfallShop.grant(progress, StitchfallShop.WARDROBE_ID, true)
				changed.emit()
				said.emit("Every runner and fabric is yours. Thank you!")
			elif states.values().has(PENDING):
				said.emit("The purchase is pending. It opens once it goes through.")
		BillingClient.BillingResponseCode.USER_CANCELED:
			pass
		BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			restore(false)
		_:
			said.emit("The purchase did not go through.")


# A clean answer without the pack takes it away again, which is how a refund reaches the game.
func _on_purchases(response: Dictionary) -> void:
	var loud: bool = _loud_restore
	_loud_restore = false
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		if loud:
			said.emit("Google Play is not reachable right now.")
		return
	var states: Dictionary = _take(response.get("purchases", []))
	var owned: bool = int(states.get(StitchfallShop.WARDROBE_ID, 0)) == PURCHASED
	StitchfallShop.grant(progress, StitchfallShop.WARDROBE_ID, owned)
	changed.emit()
	if loud:
		said.emit("The Wardrobe pack is back. Thank you!" if owned else "This Google account has no Wardrobe pack yet.")


func _take(purchases: Variant) -> Dictionary:
	var states: Dictionary = {}
	if not purchases is Array:
		return states
	for entry: Variant in purchases:
		var purchase: Dictionary = entry
		var state: int = int(purchase.get("purchase_state", 0))
		var token: String = String(purchase.get("purchase_token", ""))
		for product: Variant in Array(purchase.get("product_ids", [])):
			var id: String = String(product)
			if not PRODUCTS.has(id):
				continue
			if state == PURCHASED:
				states[id] = PURCHASED
				if id == StitchfallShop.TIP_ID:
					if not _consuming.has(token):
						_consuming[token] = id
						_client.consume_purchase(token)
				elif not bool(purchase.get("is_acknowledged", false)):
					_client.acknowledge_purchase(token)
			elif state == PENDING and int(states.get(id, 0)) != PURCHASED:
				states[id] = PENDING
	return states


# A tip counts only once Play confirms it is consumed.
func _on_consumed(response: Dictionary) -> void:
	var token: String = String(response.get("purchase_token", ""))
	var id: String = String(_consuming.get(token, ""))
	_consuming.erase(token)
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK or id != StitchfallShop.TIP_ID:
		return
	StitchfallShop.grant(progress, StitchfallShop.TIP_ID, true)
	changed.emit()
	said.emit("Thank you for the tip! It keeps the next game coming.")
