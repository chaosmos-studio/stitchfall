class_name StitchfallHouseGames
extends RefCounted

## The kit's tiny playable tastes of the studio's games (kit/monetize/house_games.gd), for the house ads: one
## board each, solved in a few moves, drawn in that game's own colours, since each advertises that game. Each is a
## Control with `solved`, emitted once the win has played out, `is_solved()` for the rules alone, and
## `play_through()`, which makes the winning moves at once, for tests. Only the sound and the buzz differ from the
## kit's copy, through the small Audio class at the end.

const SIZE: float = 560.0

## Each game's colours, its line for a banner and what its board asks of a player.
const STYLES: Dictionary = {
	"Plumb": {
		"bg": Color("f4efe7"), "ink": Color("2f333d"), "muted": Color("9b9384"), "accent": Color("ff6b6b"),
		"pieces": [Color("ff6b6b"), Color("22b5a6"), Color("ffb020")], "tag": "Roll every marble home",
		"ask": "Swipe to tilt. Roll each marble into its hole.",
	},
	"Carillon": {
		"bg": Color("0d1127"), "ink": Color("e8ebff"), "muted": Color("8a93c6"), "accent": Color("7fd0ff"),
		"pieces": [Color("6ec8ff"), Color("ffc866"), Color("6cf0c2"), Color("ff7b8e"), Color("b89dff")],
		"tag": "Every pop is a note", "ask": "Tap one dot and let the chain ring out.",
	},
	"Apsis": {
		"bg": Color("0f1330"), "ink": Color("e9ecff"), "muted": Color("8a93c4"), "accent": Color("ffb35c"),
		"pieces": [Color("ffc4a3"), Color("9cc9ff"), Color("9be7c4"), Color("ffb2d2")], "tag": "Launch every arrow out",
		"ask": "Tap an arrow to launch it. A blocked one bounces back.",
	},
	"Pyxis": {
		"bg": Color("f7f7f2"), "ink": Color("263238"), "muted": Color("59666d"), "accent": Color("236b8e"),
		"pieces": [Color("236b8e"), Color("a34b32"), Color("326c59")], "tag": "Untangle every strand",
		"ask": "Drag a knot until no strands cross.",
	},
}

static func make(game: String) -> Control:
	match game:
		"Plumb":
			return _Tilt.new()
		"Carillon":
			return _Chain.new()
		"Apsis":
			return _Arrows.new()
	return _Web.new()

static func style(game: String) -> Dictionary:
	var found: Dictionary = STYLES.get(game, STYLES["Pyxis"])
	return found


## What the four boards share: a rounded card in the game's colours, and the moment of winning.
class _Board extends Control:
	signal solved

	var look: Dictionary
	var _clock: float = 0.0
	var _won_at: float = -1.0

	func _init(game: String) -> void:
		look = StitchfallHouseGames.style(game)
		custom_minimum_size = Vector2(StitchfallHouseGames.SIZE, StitchfallHouseGames.SIZE)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func is_solved() -> bool:
		return false

	func play_through() -> void:
		pass

	func _process(delta: float) -> void:
		_clock += delta
		queue_redraw()

	## Called once the rules say the board is clear: the win plays, then `solved` goes out.
	func _win() -> void:
		if _won_at >= 0.0:
			return
		_won_at = _clock
		Audio.buzz(24, 0.8)
		get_tree().create_timer(0.7).timeout.connect(func() -> void: solved.emit())

	func _card() -> void:
		var box: StyleBoxFlat = StyleBoxFlat.new()
		box.bg_color = look["bg"]
		box.set_corner_radius_all(40)
		box.anti_aliasing = true
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		if _won_at >= 0.0:
			var t: float = clampf((_clock - _won_at) / 0.9, 0.0, 1.0)
			var glow: Color = Color(look["accent"], 0.35 * (1.0 - t))
			draw_arc(size * 0.5, size.x * (0.2 + 0.4 * t), 0.0, TAU, 96, glow, 10.0 * (1.0 - t) + 2.0, true)

	func _pieces(i: int) -> Color:
		var all: Array = look["pieces"]
		return all[i % all.size()]


## Plumb: tilt the board and every marble rolls at once, until a wall, another marble or its own hole.
class _Tilt extends _Board:
	const N: int = 5
	const START: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 2)]
	const HOLES: Array[Vector2i] = [Vector2i(4, 4), Vector2i(4, 2)]
	const BLOCKS: Array[Vector2i] = [Vector2i(1, 3), Vector2i(3, 1)]

	var marbles: Array[Vector2i] = []
	var home: Array[bool] = []
	var _shown: Array[Vector2] = []
	var _from: Vector2 = Vector2.ZERO
	var _moves: int = 0

	func _init() -> void:
		super("Plumb")
		_reset()

	func _reset() -> void:
		marbles = START.duplicate()
		home = [false, false]
		_shown = [Vector2(START[0]), Vector2(START[1])]
		_moves = 0

	func is_solved() -> bool:
		return home.all(func(h: bool) -> bool: return h)

	func play_through() -> void:
		tilt(Vector2i.RIGHT)
		tilt(Vector2i.DOWN)

	## Rolls every marble that way, the one nearest the far side first.
	func tilt(way: Vector2i) -> void:
		if is_solved():
			return
		var order: Array[int] = [0, 1]
		order.sort_custom(func(a: int, b: int) -> bool:
			return Vector2(marbles[a]).dot(Vector2(way)) > Vector2(marbles[b]).dot(Vector2(way)))
		var moved: bool = false
		for i: int in order:
			if home[i]:
				continue
			var at: Vector2i = marbles[i]
			while true:
				var next: Vector2i = at + way
				if next.x < 0 or next.y < 0 or next.x >= N or next.y >= N or BLOCKS.has(next) or _taken(next, i):
					break
				at = next
				if at == HOLES[i]:
					home[i] = true
					break
			moved = moved or at != marbles[i]
			marbles[i] = at
		if not moved:
			return
		_moves += 1
		Audio.play(&"tap", -6.0, 0.9 + 0.05 * _moves)
		Audio.buzz(10, 0.5)
		if is_solved():
			_win()
		elif _moves >= 6:
			get_tree().create_timer(0.6).timeout.connect(_reset)

	func _taken(cell: Vector2i, me: int) -> bool:
		for j: int in range(marbles.size()):
			if j != me and not home[j] and marbles[j] == cell:
				return true
		return false

	func _gui_input(event: InputEvent) -> void:
		var press: InputEventMouseButton = event as InputEventMouseButton
		if press == null or press.button_index != MOUSE_BUTTON_LEFT:
			return
		if press.pressed:
			_from = press.position
		else:
			var d: Vector2 = press.position - _from
			if d.length() > 30.0:
				tilt(Vector2i(signi(roundi(d.x)), 0) if absf(d.x) > absf(d.y) else Vector2i(0, signi(roundi(d.y))))
		accept_event()

	func _process(delta: float) -> void:
		for i: int in range(_shown.size()):
			_shown[i] = _shown[i].lerp(Vector2(marbles[i]), minf(1.0, delta * 14.0))
		super(delta)

	func _draw() -> void:
		_card()
		var cell: float = (size.x - 60.0) / N
		var origin: Vector2 = Vector2(30.0, 30.0)
		for y: int in range(N):
			for x: int in range(N):
				var r: Rect2 = Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)).grow(-5.0)
				var tile: StyleBoxFlat = StyleBoxFlat.new()
				tile.set_corner_radius_all(14)
				tile.anti_aliasing = true
				tile.bg_color = Color(look["ink"], 0.85) if BLOCKS.has(Vector2i(x, y)) else Color(look["muted"], 0.16)
				draw_style_box(tile, r)
		for i: int in range(HOLES.size()):
			var c: Vector2 = origin + (Vector2(HOLES[i]) + Vector2(0.5, 0.5)) * cell
			draw_circle(c, cell * 0.32, _pieces(i), true, -1.0, true)
			draw_circle(c, cell * 0.24, Color(look["ink"], 0.92), true, -1.0, true)
		for i: int in range(marbles.size()):
			if home[i] and _shown[i].distance_to(Vector2(marbles[i])) < 0.05:
				continue
			var c: Vector2 = origin + (_shown[i] + Vector2(0.5, 0.5)) * cell
			draw_circle(c + Vector2(0, 4), cell * 0.3, Color(0, 0, 0, 0.12), true, -1.0, true)
			draw_circle(c, cell * 0.3, _pieces(i), true, -1.0, true)
			draw_circle(c + Vector2(-cell * 0.09, -cell * 0.1), cell * 0.08, Color(1, 1, 1, 0.6), true, -1.0, true)


## Carillon: tap one dot, it rings out to everything within reach, and the chain plays a little tune.
class _Chain extends _Board:
	const REACH: float = 150.0
	const DOTS: Array[Vector2] = [Vector2(110, 140), Vector2(230, 110), Vector2(350, 150), Vector2(440, 250),
		Vector2(380, 370), Vector2(260, 420), Vector2(140, 360), Vector2(250, 270)]
	const STEP: float = 0.16

	## When each dot pops, counted from the tap, or -1 while it is waiting.
	var popped: Array[float] = []
	var _tapped_at: float = -1.0

	func _init() -> void:
		super("Carillon")
		popped.resize(DOTS.size())
		popped.fill(-1.0)

	func is_solved() -> bool:
		return not popped.has(-1.0)

	func play_through() -> void:
		tap(0)

	## Pops dot `first`, then every dot within reach of one that popped, a step later each.
	func tap(first: int) -> void:
		if _tapped_at >= 0.0:
			return
		_tapped_at = _clock
		popped[first] = 0.0
		var wave: Array[int] = [first]
		while not wave.is_empty():
			var k: int = wave.pop_front()
			for j: int in range(DOTS.size()):
				if popped[j] < 0.0 and DOTS[k].distance_to(DOTS[j]) <= REACH:
					popped[j] = popped[k] + STEP
					wave.append(j)
		var last: float = 0.0
		for t: float in popped:
			last = maxf(last, t)
		for j: int in range(DOTS.size()):
			var semitones: Array[int] = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]
			var pitch: float = pow(2.0, semitones[mini(int(popped[j] / STEP), semitones.size() - 1)] / 12.0)
			get_tree().create_timer(popped[j] + 0.001).timeout.connect(func() -> void:
				Audio.play(&"tap", -5.0, pitch)
				Audio.buzz(8, 0.4))
		get_tree().create_timer(last + 0.2).timeout.connect(_win)

	func _gui_input(event: InputEvent) -> void:
		var press: InputEventMouseButton = event as InputEventMouseButton
		if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
			var at: Vector2 = press.position * (StitchfallHouseGames.SIZE / maxf(size.x, 1.0))
			for j: int in range(DOTS.size()):
				if DOTS[j].distance_to(at) < 46.0:
					tap(j)
					break
			accept_event()

	func _draw() -> void:
		_card()
		var scale: float = size.x / StitchfallHouseGames.SIZE
		for j: int in range(DOTS.size()):
			var c: Vector2 = DOTS[j] * scale
			var colour: Color = _pieces(j)
			var age: float = _clock - _tapped_at - popped[j] if _tapped_at >= 0.0 and popped[j] >= 0.0 else -1.0
			if age < 0.0:
				var beat: float = 1.0 + 0.06 * sin(_clock * 3.0 + j)
				draw_circle(c, 30.0 * scale * beat, Color(colour, 0.18), true, -1.0, true)
				draw_circle(c, 18.0 * scale * beat, colour, true, -1.0, true)
				continue
			var t: float = clampf(age / 0.55, 0.0, 1.0)
			draw_arc(c, REACH * scale * t, 0.0, TAU, 64, Color(colour, 0.5 * (1.0 - t)), 3.0, true)
			draw_circle(c, 18.0 * scale * (1.0 - t) + 2.0, Color(colour, 1.0 - t), true, -1.0, true)


## Apsis: tap an arrow and it flies the way it points, out of the sky, unless another arrow is in its way.
class _Arrows extends _Board:
	const N: int = 4
	const CELLS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 3), Vector2i(3, 3), Vector2i(2, 2)]
	const WAYS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.LEFT]

	var gone: Array[bool] = []
	var _left_at: Array[float] = []
	var _bumped_at: Array[float] = []

	func _init() -> void:
		super("Apsis")
		for k: int in range(CELLS.size()):
			gone.append(false)
			_left_at.append(-1.0)
			_bumped_at.append(-1.0)

	func is_solved() -> bool:
		return not gone.has(false)

	func play_through() -> void:
		for k: int in [1, 0, 2, 3, 4]:
			launch(k)

	func free_to_go(k: int) -> bool:
		var at: Vector2i = CELLS[k] + WAYS[k]
		while at.x >= 0 and at.y >= 0 and at.x < N and at.y < N:
			for j: int in range(CELLS.size()):
				if j != k and not gone[j] and CELLS[j] == at:
					return false
			at += WAYS[k]
		return true

	func launch(k: int) -> void:
		if gone[k]:
			return
		if not free_to_go(k):
			_bumped_at[k] = _clock
			Audio.play(&"tap", -8.0, 0.6)
			Audio.buzz(14, 0.6)
			return
		gone[k] = true
		_left_at[k] = _clock
		Audio.play(&"tap", -4.0, 1.0 + 0.12 * gone.count(true))
		Audio.buzz(8, 0.4)
		if is_solved():
			get_tree().create_timer(0.35).timeout.connect(_win)

	func _gui_input(event: InputEvent) -> void:
		var press: InputEventMouseButton = event as InputEventMouseButton
		if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
			var cell: float = (size.x - 80.0) / N
			var at: Vector2 = (press.position - Vector2(40.0, 40.0)) / cell
			var hit: Vector2i = Vector2i(floori(at.x), floori(at.y))
			for k: int in range(CELLS.size()):
				if CELLS[k] == hit:
					launch(k)
			accept_event()

	func _draw() -> void:
		_card()
		var cell: float = (size.x - 80.0) / N
		var origin: Vector2 = Vector2(40.0, 40.0)
		for y: int in range(N):
			for x: int in range(N):
				draw_circle(origin + (Vector2(x, y) + Vector2(0.5, 0.5)) * cell, 3.0, Color(look["muted"], 0.5), true, -1.0, true)
		for k: int in range(CELLS.size()):
			var c: Vector2 = origin + (Vector2(CELLS[k]) + Vector2(0.5, 0.5)) * cell
			var way: Vector2 = Vector2(WAYS[k])
			var alpha: float = 1.0
			if gone[k]:
				var t: float = clampf((_clock - _left_at[k]) / 0.45, 0.0, 1.0)
				c += way * t * t * size.x
				alpha = 1.0 - t
				if alpha <= 0.0:
					continue
				draw_line(c - way * cell * 0.9, c, Color(_pieces(k), 0.35 * alpha), 6.0, true)
			elif _bumped_at[k] >= 0.0:
				var b: float = clampf((_clock - _bumped_at[k]) / 0.3, 0.0, 1.0)
				c += way * sin(b * PI) * cell * 0.22
			_chevron(c, way, cell * 0.3, Color(_pieces(k), alpha))

	func _chevron(c: Vector2, way: Vector2, r: float, colour: Color) -> void:
		var side: Vector2 = way.orthogonal()
		var tip: Vector2 = c + way * r
		draw_colored_polygon(PackedVector2Array([tip, c - way * r * 0.6 + side * r * 0.9, c - way * r * 0.2,
			c - way * r * 0.6 - side * r * 0.9]), colour)


## Pyxis: drag a knot anywhere, and the web is clear once no strand crosses another.
class _Web extends _Board:
	const SOLVED: Array[Vector2] = [Vector2(280, 90), Vector2(460, 220), Vector2(390, 450), Vector2(170, 450),
		Vector2(100, 220)]
	const EDGES: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 0),
		Vector2i(0, 2), Vector2i(0, 3)]
	const START: Array[Vector2] = [Vector2(280, 90), Vector2(170, 450), Vector2(390, 450), Vector2(460, 220),
		Vector2(100, 220)]

	var knots: Array[Vector2] = []
	var _held: int = -1

	func _init() -> void:
		super("Pyxis")
		knots = START.duplicate()

	func is_solved() -> bool:
		return crossings() == 0

	func play_through() -> void:
		knots = SOLVED.duplicate()
		if is_solved():
			_win()

	func crossings() -> int:
		var n: int = 0
		for i: int in range(EDGES.size()):
			for j: int in range(i + 1, EDGES.size()):
				var e: Vector2i = EDGES[i]
				var f: Vector2i = EDGES[j]
				if e.x == f.x or e.x == f.y or e.y == f.x or e.y == f.y:
					continue
				if Geometry2D.segment_intersects_segment(knots[e.x], knots[e.y], knots[f.x], knots[f.y]) != null:
					n += 1
		return n

	func _gui_input(event: InputEvent) -> void:
		var scale: float = StitchfallHouseGames.SIZE / maxf(size.x, 1.0)
		var press: InputEventMouseButton = event as InputEventMouseButton
		if press != null and press.button_index == MOUSE_BUTTON_LEFT:
			var at: Vector2 = press.position * scale
			if press.pressed and _won_at < 0.0:
				for k: int in range(knots.size()):
					if knots[k].distance_to(at) < 48.0:
						_held = k
						Audio.play(&"tap", -8.0)
						break
			elif not press.pressed and _held >= 0:
				_held = -1
				Audio.buzz(8, 0.4)
				if is_solved():
					_win()
			accept_event()
		elif event is InputEventMouseMotion and _held >= 0:
			knots[_held] = ((event as InputEventMouseMotion).position * scale).clamp(Vector2(40, 40), Vector2(520, 520))
			accept_event()

	func _draw() -> void:
		_card()
		var scale: float = size.x / StitchfallHouseGames.SIZE
		var clear: bool = is_solved()
		for i: int in range(EDGES.size()):
			var e: Vector2i = EDGES[i]
			var crossed: bool = false
			for j: int in range(EDGES.size()):
				var f: Vector2i = EDGES[j]
				if i == j or e.x == f.x or e.x == f.y or e.y == f.x or e.y == f.y:
					continue
				if Geometry2D.segment_intersects_segment(knots[e.x], knots[e.y], knots[f.x], knots[f.y]) != null:
					crossed = true
			var colour: Color = _pieces(2) if clear else (_pieces(1) if crossed else _pieces(0))
			draw_line(knots[e.x] * scale, knots[e.y] * scale, colour, 5.0, true)
		for k: int in range(knots.size()):
			var c: Vector2 = knots[k] * scale
			var r: float = 26.0 * scale * (1.15 if k == _held else 1.0)
			draw_circle(c + Vector2(0, 3), r, Color(0, 0, 0, 0.1), true, -1.0, true)
			draw_circle(c, r, Color.WHITE, true, -1.0, true)
			draw_arc(c, r - 2.0, 0.0, TAU, 40, _pieces(2) if clear else _pieces(0), 4.0, true)
			draw_circle(c, r * 0.28, _pieces(2) if clear else _pieces(0), true, -1.0, true)


## Stands in for the kit's Audio autoload, which Stitchfall has none of: the boards' taps play Stitchfall's own tap
## sound and buzz the phone, each only while its setting is on.
class Audio extends RefCounted:
	const TAP: AudioStream = preload("res://assets/audio/sfx/tap.wav")

	static var _voice: AudioStreamPlayer

	static func play(_name: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
		var progress: StitchfallProgress = StitchfallAds.progress
		if progress != null and not progress.sound:
			return
		if not is_instance_valid(_voice):
			_voice = AudioStreamPlayer.new()
			_voice.stream = TAP
			(Engine.get_main_loop() as SceneTree).root.add_child(_voice)
		_voice.volume_db = volume_db
		_voice.pitch_scale = pitch
		_voice.play()

	static func buzz(milliseconds: int, _strength: float = 1.0) -> void:
		var progress: StitchfallProgress = StitchfallAds.progress
		if progress == null or progress.shake:
			Input.vibrate_handheld(milliseconds)
