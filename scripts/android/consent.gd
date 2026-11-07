class_name StitchfallConsent
extends Node

# The kit's consent.gd. With AdMob switched off, Google's consent service still says whether this phone needs
# consent, the answer Analytics waits on before it counts anything. No ads are loaded and no form is shown.
# Android only: the browser build leaves scripts/android/ out with the AdMob plugin it calls.

func _ready() -> void:
	var request: ConsentRequestParameters = ConsentRequestParameters.new()
	UserMessagingPlatform.consent_information.update(request, StitchfallAnalytics.refresh, _on_error)


func _on_error(_error: FormError) -> void:
	StitchfallAnalytics.refresh()


func _exit_tree() -> void:
	forget()


# The consent plugin keeps the callbacks it is given in static variables, which the engine frees at exit after
# the scripts that made them: a lambda among them then aborts the app on its way out ("pthread_mutex_lock called
# on a destroyed mutex"). Every user of the plugin passes named methods and calls this as it leaves the tree.
# MobileAds keeps its listeners the same way, and a new listener already holds the plugin's own default lambda,
# so those go too.
static func forget() -> void:
	MobileAds._current_on_ad_inspector_closed_listener = null
	UserMessagingPlatform.consent_information._on_consent_info_updated_success_callback = null
	UserMessagingPlatform.consent_information._on_consent_info_updated_failure_callback = null
	UserMessagingPlatform._on_consent_form_load_success_listener_callback = null
	UserMessagingPlatform._on_consent_form_load_failure_listener_callback = null
	UserMessagingPlatform._on_privacy_options_form_dismissed_callback = null
	UserMessagingPlatform.active_consent_form = null
	MobileAds._current_on_initialization_complete_listener = null
