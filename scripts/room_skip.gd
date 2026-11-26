class_name StitchfallSkip
extends RefCounted

# When the pause page offers to skip a room, as a plain rule tested on its edge. A skip is always free.

# Unravels in one room before the pause page offers to skip it.
const AFTER: int = 5


# A skip is offered once the runner has unravelled AFTER times in the room, when there is a next room that is not
# open yet. Skipping into a room already open would sell what the Levels page gives for nothing.
static func offered(unravels: int, has_next: bool, next_open: bool) -> bool:
	return unravels >= AFTER and has_next and not next_open
