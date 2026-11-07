class_name StitchfallAdPacing
extends RefCounted

# When an ad may show, as plain rules with the kit's numbers (kit/monetize/pacing.gd in the kit games), so each is
# tested on its edge. "Sewn" counts the rooms with stars, the way the kit counts solved levels.

# The banner on the menu pages waits until this many rooms are sewn.
const BANNER_AFTER: int = 3
# No ad between rooms until this many rooms are sewn in all.
const INTERSTITIAL_AFTER: int = 12
# Rooms cleared this session before an ad between rooms, counted again after each one.
const INTERSTITIAL_EVERY: int = 4
# Seconds after any full-screen ad, between rooms or a video, before the next ad between rooms.
const FULLSCREEN_GAP: float = 240.0
# Seconds after the app starts before the first ad between rooms.
const LAUNCH_GAP: float = 180.0
# Unravels in one room before the pause page offers to skip it.
const SKIP_AFTER: int = 5

enum Skip { FREE, VIDEO }


static func banner_due(sewn: int, supporter: bool) -> bool:
	return not supporter and sewn >= BANNER_AFTER


# `since` counts rooms cleared since the last ad between rooms. `now` and `last_fullscreen` are seconds since the
# app started, and `last_fullscreen` is negative until a full-screen ad has shown.
static func interstitial_due(sewn: int, since: int, now: float, last_fullscreen: float, supporter: bool) -> bool:
	if supporter or sewn < INTERSTITIAL_AFTER or since < INTERSTITIAL_EVERY or now < LAUNCH_GAP:
		return false
	return last_fullscreen < 0.0 or now - last_fullscreen >= FULLSCREEN_GAP


# A skip is offered once the runner has unravelled SKIP_AFTER times in the room, when there is a next room that
# is not open yet. Skipping into a room already open would sell what the Levels page gives for nothing.
static func skip_offered(unravels: int, has_next: bool, next_open: bool) -> bool:
	return unravels >= SKIP_AFTER and has_next and not next_open


# A Supporter skips free, and so does anyone with no ads to watch (the browser, a phone without the plugin).
static func skip_cost(supporter: bool, rewards: bool) -> Skip:
	return Skip.FREE if supporter or not rewards else Skip.VIDEO
