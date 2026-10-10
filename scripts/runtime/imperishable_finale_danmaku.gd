extends RefCounted
# TH08 Stage 6 cards - Eirin Yagokoro and Kaguya Houraisan - rebuilt from the
# originals' bullet structure on the lawn (original "down" = towards the
# plants). Battlefield marks, treasures and medicine stay in their runtimes.

const Kit = preload("res://scripts/runtime/touhou_canon_kit.gd")
const Glyphs = preload("res://scripts/ui/touhou_glyphs.gd")
const KINDS := ["eirin_boss", "kaguya_boss"]
const PATTERNS := [
	"eirin_vessel", "nonspell_eirin_arrows", "eirin_memories", "eirin_genealogy", "eirin_life", "eirin_rising", "eirin_device", "eirin_brain", "eirin_apollo", "eirin_astronomical", "eirin_hourai",
	"nonspell_kaguya_jewels", "kaguya_dragon", "kaguya_bowl", "kaguya_robe", "kaguya_swallow", "kaguya_branch",
	"kaguya_night_0", "kaguya_night_1", "kaguya_night_2", "kaguya_night_3", "kaguya_night_4",
]
const TUNE := {"eirin_apollo": [2.003, 2.6, 2.6, 2.6], "eirin_astronomical": [1.556, 1.927, 2.6, 2.6], "eirin_brain": [1.0, 0.921, 0.856, 1.152], "eirin_device": [1.221, 1.435, 1.334, 1.019], "eirin_genealogy": [0.822, 0.696, 0.647, 0.794], "eirin_hourai": [0.456, 0.61, 0.622, 1.0], "eirin_life": [0.715, 1.0, 1.0, 1.0], "eirin_memories": [0.327, 0.615, 1.0, 1.0], "eirin_rising": [1.0, 0.899, 0.836, 1.0], "eirin_vessel": [0.125, 0.185, 0.203, 0.276], "kaguya_bowl": [1.0, 1.096, 1.019, 1.198], "kaguya_branch": [1.505, 1.683, 2.131, 2.6], "kaguya_dragon": [0.861, 1.0, 1.243, 1.487], "kaguya_night_0": [1.567, 1.489, 1.384, 1.287], "kaguya_night_1": [1.729, 1.464, 1.375, 1.856], "kaguya_night_2": [1.318, 1.112, 1.034, 1.0], "kaguya_night_3": [2.6, 2.239, 2.184, 2.6], "kaguya_night_4": [2.204, 2.098, 1.95, 2.6], "kaguya_robe": [0.265, 0.354, 0.329, 0.379], "kaguya_swallow": [1.493, 1.509, 1.403, 1.627], "nonspell_eirin_arrows": [0.289, 0.477, 0.447, 0.66], "nonspell_kaguya_jewels": [0.275, 0.491, 0.58, 1.0]}
const RATE := {"eirin_apollo": 1.6, "kaguya_night_0": 1.5, "kaguya_night_1": 1.4, "kaguya_night_2": 1.4, "kaguya_night_3": 1.6, "kaguya_night_4": 1.5}
const DURATIONS := {}
const RED := Color("ff6b88")
const BLUE := Color("82c8ff")
const GOLD := Color("ffe08a")
const LIFE_COLS := 8
const LIFE_ROWS := 5
const JEWELS := [Color("f7738f"), Color("7fd0f0"), Color("f6d66c"), Color("8fe08f"), Color("c7a2ef")]

static func owns(pattern: String) -> bool:
	return pattern in PATTERNS

static func duration(_card: Dictionary, pattern: String, fallback: float) -> float:
	return float(DURATIONS.get(pattern, fallback))

static func update_actors(_dm: RefCounted, _c: Dictionary) -> bool:
	return false

static func emit(dm: RefCounted, c: Dictionary) -> void:
	if not c.has("rate"): c["rate"] = float(RATE.get(String(c.pattern), 1.0))
	if String(c.kind) == "eirin_boss":
		_eirin(dm, c)
	else:
		_kaguya(dm, c)

static func _s(dm: RefCounted, c: Dictionary, from: Vector2, angle: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.shoot(dm, c, TUNE, from, angle, speed, color, shape, radius, extra)

static func _fan(dm: RefCounted, c: Dictionary, from: Vector2, n: int, angle: float, spread: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.fan(dm, c, TUNE, from, n, angle, spread, speed, color, shape, radius, extra)

static func _ring(dm: RefCounted, c: Dictionary, from: Vector2, n: int, rotation: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.ring(dm, c, TUNE, from, n, rotation, speed, color, shape, radius, extra)

# ------------------------------------------------------------------ Eirin

static func vessel_points(c: Dictionary, board: Rect2) -> Array:
	# The jar: a ring of familiars that creeps in on the lawn's centre.
	var centre := Vector2(board.position.x + board.size.x * 0.62, board.get_center().y)
	var shrink := clampf(1.0 - float(c.age) / 9.0, 0.6, 1.0)
	var points: Array = []
	for i in range(8):
		var a := TAU * i / 8.0 + float(c.age) * 0.35
		points.append(centre + Vector2(cos(a) * board.size.x * 0.28, sin(a) * board.size.y * 0.44) * shrink)
	return points

static func life_cell(board: Rect2, col: int, row: int) -> Vector2:
	return Vector2(board.position.x + board.size.x * (0.5 + 0.45 * (col + 0.5) / LIFE_COLS), board.position.y + board.size.y * (row + 0.5) / LIFE_ROWS)

static func life_step(cells: Array) -> Array:
	var next: Array = []
	for row in range(LIFE_ROWS):
		for col in range(LIFE_COLS):
			var around := 0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dy == 0: continue
					if cells.has(Vector2i(posmod(col + dx, LIFE_COLS), posmod(row + dy, LIFE_ROWS))): around += 1
			var alive := cells.has(Vector2i(col, row))
			if around == 3 or (alive and around == 2):
				next.append(Vector2i(col, row))
	return next

static func device_points(c: Dictionary) -> Array:
	var points: Array = []
	for i in range(4):
		points.append(Vector2(c.center) + Vector2.from_angle(float(c.age) * 0.8 + TAU * i / 4.0) * 70.0)
	return points

static func _eirin(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_eirin_arrows":
			_fan(dm, c, o, Kit.count(dm, c, 5 + r, true), aim, 0.9, 190.0, RED, "arrow", 5.5)
			if w % 2 == 1:
				_ring(dm, c, o, Kit.count(dm, c, 14), w * 0.2, 110.0, BLUE, "orb", 5.0)
			Kit.next(dm, c, 0.36)
		"eirin_vessel":
			# Heaven and Earth in a Jar: familiars ring the lawn and creep in,
			# loosing coarse aimed red and blue grains.
			var points := vessel_points(c, board)
			for i in range(points.size()):
				if (i + w) % 4 != 0: continue
				var p: Vector2 = points[i]
				_fan(dm, c, p, 3, Kit.aim(dm, p), 0.3, 120.0, RED if i % 2 else BLUE, "rice", 4.5, {"arming_time": 0.5})
			Kit.next(dm, c, 0.4)
		"eirin_memories", "eirin_genealogy":
			# Memories of the Age of the Gods / Genealogy of the Celestials:
			# coarse aimed rice and lasers that bracket the target.
			_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.5, 175.0, RED, "rice", 5.0)
			if w % 4 == 0:
				var offsets := [-0.22, 0.22] if String(c.pattern) == "eirin_memories" else [-0.42, -0.18, 0.18, 0.42]
				for off in offsets:
					Kit.ray(dm, c, TUNE, o, aim + float(off), BLUE, 1.0, 7.0, 0.5)
			Kit.next(dm, c, 0.3)
		"eirin_life", "eirin_rising":
			# Life Game / Rising Game: a colony of placed bullets grows on the
			# far lawn generation by generation, while scattered shots and
			# large bullets overtake it.
			if not c.has("life"):
				var seed: Array = [Vector2i(1, 1), Vector2i(2, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(5, 0), Vector2i(5, 1), Vector2i(5, 2), Vector2i(6, 3), Vector2i(7, 3)]
				c["life"] = seed
			var cells: Array = c.life
			for cell in cells:
				var p := life_cell(board, cell.x, cell.y)
				_s(dm, c, p, PI, 0.0, Color("9ff0a8"), "orb", 5.0, {"arming_time": 0.6, "speed_curve": [[0.0, 0.0], [1.2, 0.0], [2.2, 60.0]], "facing": PI + (Kit.noise(w, cell.x * 7 + cell.y) - 0.5) * 0.6})
			c["life"] = life_step(cells) if life_step(cells).size() >= 3 else [Vector2i(3, 1), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3)]
			var rising := String(c.pattern) == "eirin_rising"
			_ring(dm, c, o, Kit.count(dm, c, 12 + (4 if rising else 0)), Kit.noise(w, 3) * TAU, 120.0, GOLD, "orb", 5.0)
			if w % 2 == 1:
				_s(dm, c, o, aim + (Kit.noise(w, 5) - 0.5) * 0.4, 190.0, RED, "big", 10.0)
			Kit.next(dm, c, 0.55 if not rising else 0.45)
		"eirin_device", "eirin_brain":
			# Omoikane Device / Brain: fixed winders sway across the lawn while
			# full rings pass between them; the Brain adds device lasers.
			for side in [-1.0, 1.0]:
				_s(dm, c, o + Vector2(0, side * 30.0), PI + side * 0.35 + 0.45 * sin(t * 1.7 + side), 175.0, BLUE, "rice", 5.0)
			if w % 4 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 16 + r * 2), Kit.noise(w, 2) * TAU, 105.0, RED, "orb", 5.5)
			if String(c.pattern) == "eirin_brain" and w % 12 == 0:
				for p in device_points(c):
					Kit.ray(dm, c, TUNE, p, Kit.aim(dm, p), GOLD, 1.0, 6.0, 0.4)
			Kit.next(dm, c, 0.1)
		"eirin_apollo":
			# Apollo 13: two volleys of 6/11/13/15 ways at random angles,
			# mixed so their lanes never line up.
			var ways: int = [16, 20, 24, 28][r]
			for volley in range(2):
				var base := Kit.noise(w, volley) * TAU
				_ring(dm, c, o, Kit.count(dm, c, ways), base, 100.0 + volley * 35.0, RED if volley == 0 else GOLD, "orb" if volley == 0 else "rice", 5.5)
			Kit.next(dm, c, 0.3)
		"eirin_astronomical":
			# Astronomical Entombing: great bullets aimed right of, left of and
			# at the target in turn; four orbiting familiars spit faster and faster.
			if w % 2 == 0:
				var offsets := [0.22, -0.22, 0.0]
				var loop := (w / 2) % 3
				_s(dm, c, o, aim + float(offsets[loop]), 165.0, BLUE, "big", 11.0)
			for p in device_points(c):
				if true:
					_s(dm, c, p, Kit.aim(dm, p) + (Kit.noise(w, int(p.x)) - 0.5) * 1.2, 90.0 + t * 15.0, GOLD, "rice", 4.5)
			Kit.next(dm, c, lerpf(0.3, 0.18, clampf(t / 6.0, 0.0, 1.0)))
		"eirin_hourai":
			# Hourai Elixir: five movements in turn, under lasers that keep sweeping.
			var span := float(c.duration) / 5.0
			var act := mini(4, int(t / span))
			if w % 10 == 0:
				for side in [-1.0, 1.0]:
					Kit.ray(dm, c, TUNE, o, PI + side * 0.7, Color("f0a0c0"), 0.9, 6.0, 1.2, {"turn_rate": -side * 0.45})
			match act:
				0: _ring(dm, c, o, Kit.count(dm, c, 14), Kit.noise(w, 1) * TAU, 110.0, BLUE, "orb", 5.0)
				1:
					_s(dm, c, o, PI + 0.5 * sin(t * 1.4), 90.0, BLUE, "rice", 5.0)
					if w % 3 == 0: _fan(dm, c, o, 3, aim, 0.2, 170.0, BLUE, "orb", 5.5)
				2:
					_fan(dm, c, o, 3, aim + (Kit.noise(w, 2) - 0.5), 0.6, 220.0, RED, "orb", 5.5)
					_fan(dm, c, o, 3, aim + (Kit.noise(w, 4) - 0.5) * 1.6, 0.6, 85.0, RED, "big", 8.0)
				3:
					for side in [-1.0, 1.0]:
						_fan(dm, c, o + Vector2(0, side * board.size.y * 0.3), 4, PI - side * 0.4, 0.5, 130.0, Kit.GREEN, "rice", 5.0)
				4:
					_ring(dm, c, o, Kit.count(dm, c, 18), w * 0.31, 120.0, BLUE, "orb", 5.0)
					_s(dm, c, o, aim + (Kit.noise(w, 6) - 0.5) * 1.8, 150.0 + 60.0 * Kit.noise(w, 7), Color("a8d8ff"), "rice", 5.0)
			Kit.next(dm, c, 0.32 if act in [0, 4] else 0.2)

# ------------------------------------------------------------------ Kaguya

static func familiar_points(c: Dictionary, count: int, radius: float) -> Array:
	var points: Array = []
	for i in range(count):
		points.append(Vector2(c.center) + Vector2.from_angle(float(c.age) * 0.6 + TAU * i / count) * radius)
	return points

static func _kaguya(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	var p := String(c.pattern)
	match p:
		"nonspell_kaguya_jewels":
			for k in range(5):
				_fan(dm, c, o, 3, aim + (k - 2) * 0.32, 0.18, 165.0, JEWELS[k], "jewel", 5.5)
			Kit.next(dm, c, 0.42)
		"kaguya_dragon":
			# The Jewel from the Dragon's Neck: an aimed laser and five-coloured
			# bullets lobbed up and away, arcing back down onto the lawn.
			if w % 5 == 0:
				Kit.ray(dm, c, TUNE, o, aim, JEWELS[(w / 5) % 5], 1.0, 8.0, 0.45)
			for k in range(Kit.count(dm, c, 4 + r)):
				var a := (Kit.noise(w, k) - 0.5) * PI * 1.6
				_s(dm, c, o, a, 140.0 + 40.0 * Kit.noise(w, k + 5), JEWELS[(w + k) % 5], "orb", 6.5, {"gravity_vec": Vector2(-150.0, 0.0), "gravity_cap": 200.0})
			Kit.next(dm, c, 0.2)
		"kaguya_bowl":
			# The Buddha's Stone Bowl: random lasers wall off the lawn and
			# gently curving stars fall through; from Hard, aimed wedges.
			if w % 6 == 0:
				for k in range(3 + r):
					var from := Vector2(board.end.x - 4.0, board.position.y + board.size.y * Kit.noise(w, k))
					var to := Vector2(board.position.x - 4.0, board.position.y + board.size.y * Kit.noise(w, k + 11))
					Kit.beam(dm, c, TUNE, from, to, Color("e8e0ff"), 1.1, 7.0, 0.5)
			for k in range(2):
				var from := Vector2(board.end.x - 10.0, board.position.y + board.size.y * Kit.noise(w * 3 + k, 7))
				_s(dm, c, from, PI + (Kit.noise(w, k + 3) - 0.5) * 0.3, 110.0, GOLD, "star", 6.0, {"angular_speed": 0.12 if k else -0.12, "arming_time": 0.4})
			if r >= 2 and w % 3 == 0:
				_fan(dm, c, o, 3, aim, 0.2, 210.0, Color("c0e8ff"), "scale", 5.5)
			Kit.next(dm, c, 0.18)
		"kaguya_robe":
			# The Fire Rat's Robe: a fixed curtain of fire around her, and
			# familiars that aim lasers; Lunatic adds an aimed beam of its own.
			if w % 2 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 16), w * 0.11, 95.0, Color("ff8a4a"), "fire", 6.5)
			if w % 6 == 0:
				for f in familiar_points(c, 3, 80.0):
					Kit.ray(dm, c, TUNE, f, Kit.aim(dm, f), Color("ffb070"), 1.0, 6.0, 0.4)
			if r >= 3 and w % 9 == 0:
				Kit.ray(dm, c, TUNE, o, aim, Color("ffd090"), 1.1, 12.0, 0.5)
			Kit.next(dm, c, 0.24)
		"kaguya_swallow":
			# The Swallow's Cowrie Shell: slow-forming lasers from the familiars
			# and two counter-turning 8-way sets crossing between them.
			if w % 8 == 0:
				for side in [-1.0, 1.0]:
					Kit.ray(dm, c, TUNE, o + Vector2(-20.0, side * 70.0), PI + side * 0.25, Kit.GREEN, 1.4, 8.0, 0.6, {"turn_rate": -side * 0.2})
			for side in [-1.0, 1.0]:
				_ring(dm, c, o + Vector2(0, side * 40.0), Kit.count(dm, c, 8 + r * 2), t * 0.9 * side, 110.0, JEWELS[2] if side < 0 else JEWELS[3], "rice", 5.0)
			Kit.next(dm, c, 0.42)
		"kaguya_branch":
			# The Bullet Branch of Hourai: seven-coloured bullets rebound from
			# the lawn's edges; aimed shots follow each volley.
			for k in range(7 + r):
				_s(dm, c, o + Vector2(-10.0, (k - 3) * 14.0), PI + (k - 3) * 0.2 + sin(t) * 0.2, 150.0, Kit.RAINBOW[k % 7], "orb", 6.0, {"bounces": 1})
			if w % 2 == 1:
				_fan(dm, c, o, 3, aim, 0.25, 190.0, Color("ffffff"), "orb", 5.5)
			Kit.next(dm, c, 0.4)
		"kaguya_night_0":
			# Imperishable Night -crescent-: a 56-way ring that misses the
			# target, and two medium bullets flung up and down that later aim.
			if w % 3 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 32), aim + PI / 32.0, 120.0, Color("c7d8ff"), "orb", 4.5)
			for side in [-1.0, 1.0]:
				_s(dm, c, o, side * PI * 0.5, 120.0, GOLD, "big", 8.0, {"turns": [{"t": 0.8, "aim": true, "s": 180.0}]})
			Kit.next(dm, c, [0.5, 0.45, 0.4, 0.35][r])
		"kaguya_night_1":
			# -Hour of the Rat-: random crossing rings and aimed great bullets.
			for side in [-1.0, 1.0]:
				_ring(dm, c, o, Kit.count(dm, c, 12 if r == 0 else 16), Kit.noise(w, int(side + 2)) * TAU, 115.0, Color("9fb8ff") if side < 0 else Color("ffa0c0"), "rice", 4.5, {"angular_speed": 0.3 * side})
			if w % 3 == 0:
				_s(dm, c, o, aim, 160.0, RED, "big", 11.0)
			Kit.next(dm, c, 0.3)
		"kaguya_night_2":
			# -Hour of the Ox-: crossing streams of 8 to 15 ways.
			var ways: int = [8, 12, 14, 15][r]
			for side in [-1.0, 1.0]:
				_fan(dm, c, o + Vector2(0, side * 50.0), Kit.count(dm, c, ways * 0.6), PI - side * 0.5, 1.4, 130.0, Color("b0f0a0") if side < 0 else Color("f0e0a0"), "rice", 5.0)
			Kit.next(dm, c, 0.32)
		"kaguya_night_3":
			# -Hour of the Tiger-: slanted bullet lines of 48-64 ways that miss
			# the target, with aimed great bullets.
			var ways: int = [48, 56, 60, 64][r]
			var n := Kit.count(dm, c, ways * 0.75)
			for k in range(n):
				var a := aim + PI / n + TAU * k / n
				_s(dm, c, o, a + 0.06 * sin(w), 105.0 + (w % 4) * 12.0, Color("c8b0ff"), "rice", 4.5)
			if w % 3 == 1:
				_s(dm, c, o, aim, 165.0, RED, "big", 11.0)
			Kit.next(dm, c, 0.4)
		"kaguya_night_4":
			# -Morning Mist / Dawn-: unbroken fire whose bullet type changes,
			# each one curving the other way, then everything at once.
			var span := float(c.duration) / 7.0
			var step := mini(6, int(t / span))
			var kinds := [["butterfly", Color("8fc8ff"), 0.0], ["orb", Color("8ff0f0"), 0.35], ["knife", Color("8fe08f"), -0.35], ["star", Color("f6e070"), 0.35], ["rice", Color("ff8a8a"), -0.35], ["ofuda", Color("c8a0f0"), 0.35]]
			if step < 6:
				var kind: Array = kinds[step]
				for k in range(Kit.count(dm, c, 6)):
					_s(dm, c, o, PI + (Kit.noise(w, k) - 0.5) * PI * 1.5, 85.0 + 110.0 * Kit.noise(w, k + 9), kind[1], String(kind[0]), 5.5, {"angular_speed": float(kind[2])})
			else:
				for k in range(6):
					var kind: Array = kinds[k]
					_s(dm, c, o, Kit.noise(w, k) * TAU, 90.0 + 120.0 * Kit.noise(w, k + 9), kind[1], String(kind[0]), 5.5)
			Kit.next(dm, c, 0.09)

# ------------------------------------------------------------------ overlays

static func draw_cast(game: Control, c: Dictionary) -> void:
	var u := minf(game.CELL_SIZE.x / 135.0, game.CELL_SIZE.y / 127.0)
	var o := Vector2(c.center)
	var t := float(c.age)
	var fade := clampf(t / 0.4, 0.0, 1.0) * clampf((float(c.duration) - t) / 0.4, 0.0, 1.0)
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var p := String(c.pattern)
	if String(c.kind) == "eirin_boss":
		# Her bow drawn behind her during every card.
		game.draw_arc(o + Vector2(-26, -30) * u, 46.0 * u, PI * 0.6, PI * 1.4, 18, Color(0.95, 0.6, 0.7, 0.45 * fade), 3.0 * u, true)
		if p == "eirin_vessel":
			var points := vessel_points(c, board)
			for i in range(points.size()):
				var a: Vector2 = points[i]
				var b: Vector2 = points[(i + 1) % points.size()]
				game.draw_line(a, b, Color(0.7, 0.85, 1.0, 0.18 * fade), 2.0 * u, true)
				game.draw_circle(a, 9.0 * u, Color(1, 0.6, 0.7, 0.55 * fade))
				game.draw_circle(a, 4.0 * u, Color(1, 1, 1, 0.8 * fade))
		elif p in ["eirin_life", "eirin_rising"]:
			for col in range(LIFE_COLS + 1):
				var x := board.position.x + board.size.x * (0.5 + 0.45 * col / LIFE_COLS)
				game.draw_line(Vector2(x, board.position.y), Vector2(x, board.end.y), Color(0.6, 1.0, 0.7, 0.08 * fade), 1.0, true)
			for row in range(LIFE_ROWS + 1):
				var y := board.position.y + board.size.y * row / LIFE_ROWS
				game.draw_line(Vector2(board.position.x + board.size.x * 0.5, y), Vector2(board.position.x + board.size.x * 0.95, y), Color(0.6, 1.0, 0.7, 0.08 * fade), 1.0, true)
			if c.has("life"):
				for cell in c.life:
					var spot := life_cell(board, cell.x, cell.y)
					game.draw_rect(Rect2(spot - Vector2(10, 10) * u, Vector2(20, 20) * u), Color(0.6, 1.0, 0.7, 0.16 * fade), true)
		elif p in ["eirin_device", "eirin_brain", "eirin_astronomical"]:
			for spot in device_points(c):
				game.draw_circle(spot, 10.0 * u, Color(0.7, 0.85, 1.0, 0.25 * fade))
				Glyphs.draw(game, spot, 6.0 * u, "jewel" if p == "eirin_astronomical" else "element", t, Color(1, 1, 1, 0.75 * fade))
	else:
		# The five treasures orbit Kaguya while she declares her requests.
		for k in range(5):
			var a := t * 0.7 + TAU * k / 5.0
			var spot := o + Vector2(cos(a) * 58.0, sin(a) * 24.0 - 30.0) * u
			Glyphs.draw(game, spot, 6.5 * u, "jewel", a, Color(JEWELS[k], 0.75 * fade))
		if p == "kaguya_robe" or p == "kaguya_swallow":
			for f in familiar_points(c, 3 if p == "kaguya_robe" else 2, 80.0):
				game.draw_circle(f, 10.0 * u, Color(1, 0.7, 0.4, 0.3 * fade))
				game.draw_arc(f, 9.0 * u, t * 4.0, t * 4.0 + PI * 1.4, 14, Color(1, 0.9, 0.6, 0.8 * fade), 1.6 * u, true)
		if p.begins_with("kaguya_night_"):
			# The long night turns: a moon that wanes towards dawn.
			var night := int(p.trim_prefix("kaguya_night_"))
			var sky := o + Vector2(-40, -80) * u
			game.draw_circle(sky, 22.0 * u, Color(1, 0.95, 0.8, 0.12 * fade))
			Glyphs.draw(game, sky, 18.0 * u, "moon", -0.5 - night * 0.3, Color(1, 0.95, 0.75, (0.5 - night * 0.06) * fade))
