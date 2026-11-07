extends StitchfallAdBackend

# AdMob, as the kit's android/admob.gd runs it, with the banner a 320 dp strip centred at the foot of a landscape
# screen. Debug builds always ask for Google's test units, so a phone under test never sees a real ad. Whenever
# AdMob has no banner or video to give (before the account is approved, offline, no fill), the studio's house ads
# fill in: the house banner holds the strip until a real one loads, and a quick game stands in for a video.
# Android only: the browser build leaves scripts/android/ out with the AdMob plugin it calls.

const TEST_BANNER: String = "ca-app-pub-3940256099942544/9214589741"
const TEST_INTERSTITIAL: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED: String = "ca-app-pub-3940256099942544/5224354917"
# Seconds before a failed load tries again, doubling each time up to the cap.
const RETRY_FIRST: float = 30.0
const RETRY_CAP: float = 600.0
# A loaded full-screen ad expires after an hour, so one older than this is loaded again rather than shown.
const STALE: float = 3300.0
# An ad that has neither shown nor failed this long after `present` is given up on.
const SHOW_TIMEOUT: float = 5.0

var _sdk_ready: bool = false
var _stopped: bool = false
var _sound_on: bool = true
var _banner: AdView
var _banner_on: bool = false
var _banner_loaded: bool = false
var _loaded: Dictionary = {}
var _loaded_at: Dictionary = {}
var _loading: Dictionary = {}
var _retry: Dictionary = {}
var _showing: StringName = &""
var _shown: bool = false
var _earned: bool = false
var _house: StitchfallHouseAds


func _ready() -> void:
	_sound_on = StitchfallAds.progress == null or StitchfallAds.progress.sound
	_house = StitchfallHouseAds.new()
	_house.consent = false
	add_child(_house)
	_house.banner_changed.connect(func(height: float) -> void:
		if not _banner_loaded:
			banner_changed.emit(height))
	if _banner_on:
		_house.set_banner(true)
	var request: ConsentRequestParameters = ConsentRequestParameters.new()
	# Named methods, never lambdas: the plugin keeps these callbacks in static variables, and a lambda freed with
	# them at exit, after its script, aborts the app (StitchfallConsent.forget).
	UserMessagingPlatform.consent_information.update(request, _on_consent_info, _on_form_error)


# Lets go of every callback the plugin keeps statically, before the engine frees its statics.
func _exit_tree() -> void:
	StitchfallConsent.forget()


func _on_consent_info() -> void:
	var info: ConsentInformation = UserMessagingPlatform.consent_information
	if info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED and info.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_form_loaded, _on_form_error)
	else:
		_start_sdk()


func _on_form_loaded(form: ConsentForm) -> void:
	form.show(_on_form_error)


func _on_form_error(_error: FormError) -> void:
	_start_sdk()


# UMP's canRequestAds(). After a failed update this is the choice kept from the last session.
func _can_request() -> bool:
	var status: int = UserMessagingPlatform.consent_information.get_consent_status()
	return status == ConsentInformation.ConsentStatus.OBTAINED or status == ConsentInformation.ConsentStatus.NOT_REQUIRED


# Every way through the consent message ends here, so Analytics learns each new answer.
func _start_sdk() -> void:
	StitchfallAnalytics.refresh()
	if _sdk_ready or _stopped or not _can_request():
		return
	var listener: OnInitializationCompleteListener = OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_initialized
	MobileAds.initialize(listener)


func _on_initialized(_status: InitializationStatus) -> void:
	if _sdk_ready:
		return
	_sdk_ready = true
	var config: RequestConfiguration = RequestConfiguration.new()
	config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_PG
	MobileAds.set_request_configuration(config)
	match_sound(_sound_on)
	_load(INTERSTITIAL)
	_load(REWARDED)
	if _banner_on:
		_make_banner()


# Ads start muted for a player who turned the game's sound off.
func match_sound(on: bool) -> void:
	_sound_on = on
	if _sdk_ready:
		MobileAds.set_app_muted(not on)


func _unit(kind: StringName) -> String:
	var debug: bool = OS.is_debug_build()
	match kind:
		INTERSTITIAL:
			return TEST_INTERSTITIAL if debug else StitchfallMonetize.INTERSTITIAL_ID
		REWARDED:
			return TEST_REWARDED if debug else StitchfallMonetize.REWARDED_ID
	return TEST_BANNER if debug else StitchfallMonetize.BANNER_ID


func _load(kind: StringName) -> void:
	if not _sdk_ready or _stopped or _loading.get(kind, false) or _loaded.has(kind):
		return
	_loading[kind] = true
	if kind == INTERSTITIAL:
		var callback: InterstitialAdLoadCallback = InterstitialAdLoadCallback.new()
		callback.on_ad_loaded = func(ad: InterstitialAd) -> void: _on_loaded(kind, ad)
		callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void: _on_failed(kind)
		InterstitialAdLoader.new().load(_unit(kind), AdRequest.new(), callback)
	else:
		var reward_callback: RewardedAdLoadCallback = RewardedAdLoadCallback.new()
		reward_callback.on_ad_loaded = func(ad: RewardedAd) -> void: _on_loaded(kind, ad)
		reward_callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void: _on_failed(kind)
		RewardedAdLoader.new().load(_unit(kind), AdRequest.new(), reward_callback)


func _on_loaded(kind: StringName, ad: Object) -> void:
	_loading[kind] = false
	_retry[kind] = RETRY_FIRST
	if _stopped:
		ad.call("destroy")
		return
	_loaded[kind] = ad
	_loaded_at[kind] = Time.get_ticks_msec() / 1000.0
	var callback: FullScreenContentCallback = ad.get("full_screen_content_callback")
	callback.on_ad_showed_full_screen_content = func() -> void: _shown = true
	callback.on_ad_dismissed_full_screen_content = func() -> void: _end(kind)
	callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void: _end(kind)


func _on_failed(kind: StringName) -> void:
	_loading[kind] = false
	var wait: float = _retry.get(kind, RETRY_FIRST)
	_retry[kind] = minf(wait * 2.0, RETRY_CAP)
	get_tree().create_timer(wait).timeout.connect(func() -> void: _load(kind))


func ready_to_show(kind: StringName) -> bool:
	return _admob_ready(kind) or (kind == REWARDED and _showing == &"" and _house.ready_to_show(kind))


func video_ready() -> bool:
	return _admob_ready(REWARDED)


func _admob_ready(kind: StringName) -> bool:
	if not _loaded.has(kind) or _showing != &"":
		return false
	var age: float = Time.get_ticks_msec() / 1000.0 - float(_loaded_at.get(kind, 0.0))
	if age > STALE:
		_drop(kind)
		_load(kind)
		return false
	return true


func present(kind: StringName) -> void:
	if not _admob_ready(kind):
		if kind == REWARDED and _showing == &"" and _house.ready_to_show(kind):
			_showing = kind
			_house.present(kind)
			var result: Array = await _house.finished
			_showing = &""
			finished.emit(result[0], result[1], result[2])
		else:
			finished.emit.call_deferred(kind, false, false)
		return
	_showing = kind
	_shown = false
	_earned = false
	var ad: Object = _loaded[kind]
	if kind == REWARDED:
		var listener: OnUserEarnedRewardListener = OnUserEarnedRewardListener.new()
		listener.on_user_earned_reward = func(_item: RewardedItem) -> void: _earned = true
		(ad as RewardedAd).show(listener)
	else:
		(ad as InterstitialAd).show()
	await get_tree().create_timer(SHOW_TIMEOUT).timeout
	if _showing == kind and not _shown:
		_end(kind)


# The reward callback can land just after the close, so this waits a frame before reporting.
func _end(kind: StringName) -> void:
	if _showing != kind:
		return
	_showing = &""
	_drop(kind)
	await get_tree().process_frame
	finished.emit(kind, _shown, _earned)
	_load(kind)


func _drop(kind: StringName) -> void:
	var ad: Object = _loaded.get(kind, null)
	_loaded.erase(kind)
	if ad != null:
		ad.call("destroy")


func set_banner(on: bool) -> void:
	_banner_on = on and not _stopped
	# Asked before _ready, in the frame before StitchfallAds attaches this node: _ready applies it.
	if _house == null:
		return
	_house.set_banner(_banner_on and not _banner_loaded)
	if _banner == null:
		if _banner_on:
			_make_banner()
		return
	if _banner_on and _banner_loaded:
		_banner.set_position(_clear_position(float(_banner.get_height())))
		_banner.show()
	else:
		_banner.hide()


func _make_banner() -> void:
	if not _sdk_ready or _banner != null:
		return
	var size: AdSize = AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(int(StitchfallAds.BANNER_WIDTH_DP))
	_banner = AdView.new(_unit(&"banner"), size, _clear_position(float(size.height)))
	_banner.hide()
	var listener: AdListener = AdListener.new()
	listener.on_ad_loaded = _on_banner_loaded
	listener.on_ad_failed_to_load = func(_error: LoadAdError) -> void: _on_banner_failed()
	_banner.ad_listener = listener
	_banner.load_ad(AdRequest.new())


func _on_banner_loaded() -> void:
	_retry[&"banner"] = RETRY_FIRST
	var first: bool = not _banner_loaded
	_banner_loaded = true
	set_banner(_banner_on)
	if first:
		banner_changed.emit(_design_height())


func _on_banner_failed() -> void:
	if _banner_loaded:
		return
	_banner.destroy()
	_banner = null
	var wait: float = _retry.get(&"banner", RETRY_FIRST)
	_retry[&"banner"] = minf(wait * 2.0, RETRY_CAP)
	get_tree().create_timer(wait).timeout.connect(func() -> void:
		if _banner_on:
			_make_banner())


# The banner `height_dp` tall and BANNER_WIDTH_DP wide, centred, sitting StitchfallAds.gap_dp above the system
# navigation inset. The plugin's custom position is dp from the top left of the full-screen view, with no inset
# added (its Banner.kt).
func _clear_position(height_dp: float) -> AdPosition:
	var density: float = DisplayServer.screen_get_dpi() / 160.0
	var screen_px: Vector2 = Vector2(DisplayServer.window_get_size())
	if density <= 0.0 or screen_px.y <= 0.0:
		return AdPosition.BOTTOM
	var inset: float = StitchfallAds.inset_dp()
	var left_dp: float = maxf(0.0, (screen_px.x / density - StitchfallAds.BANNER_WIDTH_DP) * 0.5)
	var top_dp: float = screen_px.y / density - inset - StitchfallAds.gap_dp(inset) - maxf(height_dp, StitchfallAds.BANNER_HEIGHT_DP)
	return AdPosition.custom(int(floorf(left_dp)), int(floorf(top_dp)))


# In design pixels. The laid-out view wins if it is taller than the dp size, so it is never underestimated.
func _design_height() -> float:
	var pixels: float = maxf(float(_banner.ad_size.height), StitchfallAds.BANNER_HEIGHT_DP) * DisplayServer.screen_get_dpi() / 160.0
	pixels = maxf(pixels, float(_banner.get_height_in_pixels()))
	var view: float = get_viewport().get_visible_rect().size.y
	var window: float = float(DisplayServer.window_get_size().y)
	return pixels * view / window if window > 0.0 else pixels


func privacy_required() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func open_privacy() -> void:
	UserMessagingPlatform.show_privacy_options_form(_on_form_error)


func stop() -> void:
	_stopped = true
	_banner_on = false
	_house.stop()
	if _banner != null:
		_banner.destroy()
		_banner = null
	if _banner_loaded:
		_banner_loaded = false
		banner_changed.emit(0.0)
	for kind: StringName in [INTERSTITIAL, REWARDED]:
		if _showing != kind:
			_drop(kind)


func resume() -> void:
	if not _stopped:
		return
	_stopped = false
	if _sdk_ready:
		_load(INTERSTITIAL)
		_load(REWARDED)
	else:
		_start_sdk()
