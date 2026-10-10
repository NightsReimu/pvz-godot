extends RefCounted
# TH06 (Embodiment of Scarlet Devil) cards rebuilt from the originals' bullet
# structure, rotated onto the lawn: the original "down towards the player" is
# "left towards the plants"; the original left/right walls are the lawn's top
# and bottom edges. Card notes: docs/plans/2026-10-09-touhou-canon-rework.md.

const Kit = preload("res://scripts/runtime/touhou_canon_kit.gd")
const Glyphs = preload("res://scripts/ui/touhou_glyphs.gd")
const KINDS := ["rumia_boss", "daiyousei_boss", "cirno_boss", "meiling_boss", "koakuma_boss", "patchouli_boss", "sakuya_boss", "remilia_boss", "flandre_boss"]
const PATTERNS := [
	"nonspell_dark_fan", "moonlight_ray", "night_bird", "demarcation",
	"fairy_aim",
	"nonspell_ice_fan", "icicle", "hailstorm", "perfect_freeze", "blizzard",
	"nonspell_rainbow_spiral", "flower", "selaginella", "rainbow", "kasou_mukatsu", "rainbow_rain", "saikou_ranbu", "typhoon",
	"library_orbs",
	"nonspell_element_orbits", "agni", "trilithon", "trilithon_shake", "cromlech", "mercury", "forest_blaze", "silent_selene", "royal_flare", "philosophers_stone",
	"nonspell_knife_fan", "misdirection", "clock_corpse", "luna_clock", "marionette", "eternal_meek",
	"nonspell_scarlet_crossfire", "david", "young_demon_lord", "scarlet_nether", "thousand_needles", "vlad", "vampire_illusion", "scarlet_shoot", "scarlet_meister", "red_magic", "scarlet_gensokyo",
	"nonspell_crystal_fan", "cranberry", "laevatein", "four_of_a_kind", "kagome", "maze", "starbow", "catadioptric", "past_clock", "and_then_none", "qed",
]
# Per-card damage factors keep each reworked card at the pressure of the
# version it replaced (fixed-formation probe against v1.0.184).
const TUNE := {"agni": [2.063, 1.713, 1.577, 1.206], "and_then_none": [1.5, 1.5, 1.5, 1.752], "blizzard": [1.739, 1.473, 1.369, 1.745], "catadioptric": 0.658, "clock_corpse": [0.437, 0.455, 0.423, 0.437], "cranberry": 1.172, "cromlech": [2.28, 1.931, 1.931, 1.931], "david": 1.767, "demarcation": [1.5, 1.5, 1.5, 1.154], "eternal_meek": 1.603, "fairy_aim": [0.7, 0.593, 0.73, 0.73], "flower": [1.913, 1.664, 1.664, 1.664], "forest_blaze": [2.543, 2.543, 2.6, 2.543], "four_of_a_kind": [1.298, 1.298, 1.298, 1.708], "hailstorm": [0.376, 0.376, 0.417, 0.319], "icicle": [1.415, 1.198, 1.176, 1.176], "kagome": 2.6, "kasou_mukatsu": 0.609, "laevatein": [0.15, 0.141, 0.131, 0.1], "library_orbs": [0.413, 0.35, 0.399, 0.399], "luna_clock": 0.445, "marionette": 2.022, "maze": 2.6, "mercury": [2.6, 2.513, 2.336, 2.109], "misdirection": [1.0, 1.0, 1.0, 0.847], "moonlight_ray": 0.835, "night_bird": [1.622, 1.414, 1.31, 1.002], "nonspell_crystal_fan": [1.655, 1.655, 1.655, 1.927], "nonspell_dark_fan": [1.441, 1.221, 1.301, 1.301], "nonspell_element_orbits": [1.569, 1.817, 2.241, 1.817], "nonspell_ice_fan": [1.007, 0.853, 0.792, 0.803], "nonspell_knife_fan": [1.284, 1.091, 1.667, 1.284], "nonspell_rainbow_spiral": [0.747, 0.632, 0.587, 0.537], "nonspell_scarlet_crossfire": [0.811, 0.811, 0.918, 0.702], "past_clock": 0.293, "perfect_freeze": [0.949, 1.592, 1.48, 2.167], "philosophers_stone": [2.031, 1.72, 1.72, 1.486], "qed": [1.0, 1.0, 1.0, 0.861], "rainbow": [0.982, 1.013, 0.941, 1.0], "rainbow_rain": 0.541, "red_magic": 0.631, "royal_flare": [2.059, 1.744, 1.744, 1.451], "saikou_ranbu": 0.446, "scarlet_gensokyo": 0.947, "scarlet_meister": [1.78, 1.565, 1.455, 1.78], "scarlet_nether": 0.739, "scarlet_shoot": 1.188, "selaginella": [1.0, 1.0, 1.0, 1.2], "silent_selene": [0.925, 0.785, 0.785, 0.682], "starbow": 1.5, "thousand_needles": [1.303, 1.303, 1.303, 1.53], "trilithon": [1.537, 1.302, 1.302, 1.302], "trilithon_shake": [1.296, 1.296, 1.533, 1.296], "typhoon": [1.298, 1.123, 1.298, 1.298], "vampire_illusion": 2.197, "vlad": [1.0, 1.076, 1.0, 1.0], "young_demon_lord": 0.676}
const RATE := {"agni": 1.73, "cromlech": 2.0, "demarcation": 2.0, "forest_blaze": 2.0, "four_of_a_kind": 1.61, "kagome": 2.0, "maze": 1.3, "mercury": 1.2, "nonspell_dark_fan": 1.75, "nonspell_element_orbits": 2.0, "starbow": 2.0, "thousand_needles": 1.48, "trilithon": 1.51, "trilithon_shake": 1.64, "typhoon": 1.75, "vampire_illusion": 1.2}
const DURATIONS := {}

static func owns(pattern: String) -> bool:
	return pattern in PATTERNS

static func duration(_card: Dictionary, pattern: String, fallback: float) -> float:
	return float(DURATIONS.get(pattern, fallback))

static func update_actors(_dm: RefCounted, _c: Dictionary) -> bool:
	# Four of a Kind keeps the shared clone actors.
	return false

static func emit(dm: RefCounted, c: Dictionary) -> void:
	if not c.has("rate"): c["rate"] = float(RATE.get(String(c.pattern), 1.0))
	match String(c.kind):
		"rumia_boss": _rumia(dm, c)
		"daiyousei_boss": _daiyousei(dm, c)
		"cirno_boss": _cirno(dm, c)
		"meiling_boss": _meiling(dm, c)
		"koakuma_boss": _koakuma(dm, c)
		"patchouli_boss": _patchouli(dm, c)
		"sakuya_boss": _sakuya(dm, c)
		"remilia_boss": _remilia(dm, c)
		"flandre_boss": _flandre(dm, c)

static func _s(dm: RefCounted, c: Dictionary, from: Vector2, angle: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.shoot(dm, c, TUNE, from, angle, speed, color, shape, radius, extra)

static func _fan(dm: RefCounted, c: Dictionary, from: Vector2, n: int, angle: float, spread: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.fan(dm, c, TUNE, from, n, angle, spread, speed, color, shape, radius, extra)

static func _ring(dm: RefCounted, c: Dictionary, from: Vector2, n: int, rotation: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.ring(dm, c, TUNE, from, n, rotation, speed, color, shape, radius, extra)

# ------------------------------------------------------------------ Rumia

static func _rumia(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	match String(c.pattern):
		"nonspell_dark_fan":
			# Her four nonspell volleys in turn: a red aimed stream that slows
			# shot by shot, green parabolas, a blue odd-way and red n-way + ring.
			match w % 4:
				0:
					for k in range(5):
						_s(dm, c, o, aim, 215.0 - k * 22.0, Kit.RED, "orb", 6.0)
				1:
					for k in range(Kit.count(dm, c, 6)):
						var a := (k / 5.0 - 0.5) * 1.8
						_s(dm, c, o, a, 150.0, Kit.GREEN, "orb", 6.0, {"gravity_vec": Vector2(-230, 0)})
				2:
					_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.5, 170.0, Kit.BLUE, "orb", 6.0)
				3:
					var ways: int = [2, 3, 5, 5][r]
					_fan(dm, c, o, ways, aim + (0.18 if ways == 2 else 0.0), 0.45 if ways > 2 else 0.36, 190.0, Kit.RED, "orb", 7.0)
					if r >= 1:
						_ring(dm, c, o, Kit.count(dm, c, 16), w * 0.2, 120.0, Kit.BLUE, "orb", 5.5)
			Kit.next(dm, c, 0.5)
		"night_bird":
			# Wings of aimed shots spreading to one side, then the other;
			# Hard and Lunatic beat two and three wings at once.
			var side := -1.0 if w % 2 == 0 else 1.0
			for layer in range([1, 1, 2, 3][r]):
				var n := Kit.count(dm, c, 12)
				for i in range(n):
					var t := float(i) / maxf(1.0, n - 1)
					_s(dm, c, o, aim + side * (0.08 + t * 1.25) + layer * 0.06 * side, 215.0 - t * 95.0 - layer * 25.0, Kit.BLUE if side < 0 else Kit.VIOLET, "orb", 5.5)
			Kit.next(dm, c, 0.48 if r < 2 else 0.42)
		"demarcation":
			# Three coloured rings that curl apart into a crossing lattice,
			# then four aimed volleys. Lunatic doubles the crossing rings.
			var step := w % 7
			if step < 3:
				var colors := [Kit.BLUE, Kit.GREEN, Kit.RED]
				var spin: float = [0.62, -0.62, 0.0][step]
				for layer in range(2 if r >= 3 else 1):
					_ring(dm, c, o, Kit.count(dm, c, 20), w * 0.37 + layer * 0.16, 105.0 + layer * 30.0, colors[step], "orb", 5.5, {"angular_speed": spin, "angular_stop_at": 1.3})
				Kit.next(dm, c, 0.22 if step < 2 else 0.7)
			else:
				_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.42, 200.0, Kit.RED, "orb", 6.5)
				Kit.next(dm, c, 0.24 if step < 6 else 0.6)
		"moonlight_ray":
			# Aimed all-direction ring and two lasers closing in on the target.
			_ring(dm, c, o, Kit.count(dm, c, 28 if r < 3 else 32), aim, 150.0, Kit.BLUE, "orb", 5.0)
			if w % 4 == 0:
				for side in [-1.0, 1.0]:
					Kit.ray(dm, c, TUNE, o, aim + side * 0.95, Kit.GOLD, 1.0, 9.0, 1.6, {"turn_rate": -side * 0.5, "turn_until": 2.5})
			Kit.next(dm, c, 0.45)

# ------------------------------------------------------------------ Daiyousei

static func _daiyousei(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	# Two fixed all-direction rings, then aimed streams; she blinks between them.
	if w % 4 < 2:
		_ring(dm, c, o, Kit.count(dm, c, 22), (w % 2) * PI / 22.0, 120.0, Kit.GREEN, "orb", 5.5)
		Kit.next(dm, c, 0.32)
	else:
		_fan(dm, c, o, Kit.count(dm, c, 7, true), Kit.aim(dm, o), 0.8, 175.0, Kit.SKY, "rice", 5.5)
		if w % 4 == 3:
			Kit.effect(dm, "canon_blink", o, 46.0, 0.35, Color(0.6, 1, 0.75, 0.6))
		Kit.next(dm, c, 0.36)

# ------------------------------------------------------------------ Cirno

static func _cirno(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_ice_fan":
			if w < 3:
				_fan(dm, c, o, Kit.count(dm, c, 11, true), aim, 2.0, 230.0, Kit.SKY, "ice", 5.5)
				if r >= 2:
					_ring(dm, c, o, Kit.count(dm, c, 14), w * 0.3, 140.0, Kit.WHITE, "ice", 5.0)
			else:
				_fan(dm, c, o, 3, aim, 0.3, 200.0, Kit.BLUE, "ice", 6.0)
				_ring(dm, c, o, Kit.count(dm, c, 12), w * 0.27, 120.0, Kit.SKY, "orb", 5.0)
			Kit.next(dm, c, 0.32)
		"icicle":
			# Icicle Fall: two streams climb to the lawn's edges and fall towards
			# the plants as diagonal walls; the lane straight ahead stays clear
			# on Easy, Normal tilts the walls inwards and adds yellow 5-way shots.
			var tilt := 0.07 if r == 0 else 0.17
			for side in [-1.0, 1.0]:
				var hold := 0.32 + 0.06 * (w % 9)
				_s(dm, c, o, side * (PI * 0.5 + 0.22), 190.0, Kit.SKY, "ice", 5.5, {"turns": [{"t": hold, "a": PI + side * tilt, "s": 125.0}]})
			if r >= 1 and w % 5 == 4:
				_fan(dm, c, o, 5, aim, 0.5, 165.0, Kit.GOLD, "orb", 6.0)
			Kit.next(dm, c, 0.11)
		"hailstorm":
			# Hailstorm: clumps of three-layer rings that fall as a body; every
			# few volleys she moves and the clumps grow wider and faster.
			var grow := w / 4
			var anchor := o + Vector2(-Kit.noise(grow, 3) * 60.0, (Kit.noise(grow, 4) - 0.5) * board.size.y * 0.55)
			var ways := Kit.count(dm, c, (6 if r < 3 else 9) + grow)
			var drift := Vector2.from_angle(Kit.aim(dm, anchor)) * (95.0 + grow * 8.0)
			for layer in range(3):
				for k in range(ways):
					var v := Vector2.from_angle(TAU * k / ways + w * 0.4) * (28.0 + layer * 20.0) + drift
					_s(dm, c, anchor, v.angle(), v.length(), Kit.SKY if layer % 2 == 0 else Kit.WHITE, "ice", 5.0)
			Kit.next(dm, c, 0.38)
		"perfect_freeze":
			# Scatter, freeze (the bullets turn white), aimed shots while time
			# is held, then the frozen field resumes in new directions.
			var cycle := 0 if t < 1.7 else 1
			var start := 0.0 if cycle == 0 else 1.8
			var freeze := 0.55 if cycle == 0 else 2.35
			var thaw := 1.5 if cycle == 0 else 3.25
			if t < freeze - 0.05:
				for k in range(Kit.count(dm, c, 11)):
					var a := Kit.noise(w * 37 + k, 1) * TAU
					var speed := 80.0 + 130.0 * Kit.noise(w * 37 + k, 2)
					_s(dm, c, o, a, speed, Kit.RAINBOW[(w + k) % Kit.RAINBOW.size()], "orb", 5.5, {"freeze_at": freeze - t, "thaw_at": thaw - t, "thaw_angle": (Kit.noise(w * 37 + k, 3) - 0.5) * TAU, "whiten": true, "speed_curve": [[0.0, speed], [thaw - t, 18.0], [thaw - t + 1.1, 120.0]]})
				Kit.at(c, t + 0.12 if t + 0.12 < freeze - 0.05 else freeze + 0.25)
			else:
				_fan(dm, c, o, (4 if r % 2 == 1 else 5), aim, 0.55, 170.0, Kit.BLUE, "ice", 6.0)
				Kit.at(c, t + 0.25 if t + 0.25 < thaw - 0.1 else (1.8 if cycle == 0 else 9.0))
		"blizzard":
			# Diamond Blizzard: a wandering spray of slow and fast ice chips.
			for k in range(Kit.count(dm, c, 9)):
				var seed := w * 53 + k
				var from := o + Vector2.from_angle(Kit.noise(seed, 1) * TAU) * 55.0 * Kit.noise(seed, 2)
				_s(dm, c, from, PI + (Kit.noise(seed, 3) - 0.5) * 2.6, 55.0 + 190.0 * pow(Kit.noise(seed, 4), 1.6), Kit.WHITE if k % 3 == 0 else Kit.SKY, "ice", 4.5)
			Kit.next(dm, c, 0.14)

# ------------------------------------------------------------------ Meiling

static func _flower_ring(dm: RefCounted, c: Dictionary, from: Vector2, n: int, lobes: int, rotation: float, speed: float, color: Color, shape: String = "orb") -> void:
	# Speed varies with angle so the expanding ring draws a flower outline.
	for k in range(n):
		var a := rotation + TAU * k / n
		_s(dm, c, from, a, speed * (1.0 + 0.42 * cos(lobes * (a - rotation))), color, shape, 5.5)

static func _meiling(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_rainbow_spiral":
			# Rotating rainbow arms whose way count grows with each volley.
			var arms: int = [4, 5, 7, 10][r] + mini(3, w / 6)
			for arm in range(arms):
				_s(dm, c, o, aim + t * 1.7 + TAU * arm / arms, 145.0, Kit.RAINBOW[arm % Kit.RAINBOW.size()], "orb", 5.5)
			Kit.next(dm, c, 0.11)
		"flower":
			# Fragrant flowers: five-petal outlines bloom one after another.
			_flower_ring(dm, c, o, Kit.count(dm, c, 30), 5, w * 0.45, 92.0, Kit.RAINBOW[w % Kit.RAINBOW.size()])
			_ring(dm, c, o, Kit.count(dm, c, 10), -w * 0.3, 60.0, Kit.GOLD, "orb", 5.0)
			Kit.next(dm, c, 0.46)
		"selaginella":
			# Selaginella 9: nine-lobed blooms with a counter-turning second layer.
			_flower_ring(dm, c, o, Kit.count(dm, c, 36), 9, w * 0.33, 100.0, Kit.GREEN)
			_flower_ring(dm, c, o, Kit.count(dm, c, 27), 9, -w * 0.33 + 0.17, 72.0, Kit.PINK, "rice")
			Kit.next(dm, c, 0.4)
		"rainbow":
			# Rainbow Wind Chime: seven fixed-angle colour arms turning slowly,
			# a curtain of chimes that she lowers towards the lawn.
			for arm in range(7):
				var a := t * 0.42 + TAU * arm / 7.0
				_s(dm, c, o, a, 150.0, Kit.RAINBOW[arm], "orb", 5.5)
				if r >= 2:
					_s(dm, c, o, -a + 0.4, 120.0, Kit.RAINBOW[6 - arm], "rice", 5.0)
			Kit.next(dm, c, 0.1)
		"kasou_mukatsu":
			# Flower-thought dream vine: scattered clumps, dense here, sparse there.
			var clump := (w / 4) * 2
			for k in range(Kit.count(dm, c, 8)):
				var seed := w * 41 + k
				var centre := PI + (Kit.noise(clump + k % 2, 7) - 0.5) * 2.4
				var speed := (70.0 if r == 2 else 105.0) + 70.0 * Kit.noise(seed, 2)
				_s(dm, c, o, centre + (Kit.noise(seed, 1) - 0.5) * 0.7, speed, [Kit.VIOLET, Kit.PINK, Kit.BLUE][k % 3], "orb", 5.5)
			Kit.next(dm, c, 0.13)
		"rainbow_rain", "saikou_ranbu":
			# Coloured rain: shots thrown towards the lawn's edges fall back
			# across it diagonally. Saikou Ranbu adds a heavier far-side shower.
			var high := String(c.pattern) == "saikou_ranbu"
			for k in range(Kit.count(dm, c, 5)):
				var seed := w * 29 + k
				var side := -1.0 if (k + w) % 2 == 0 else 1.0
				_s(dm, c, o, side * (PI * 0.5 + 0.15 + 0.5 * Kit.noise(seed, 1)), 120.0 + 60.0 * Kit.noise(seed, 2), Kit.RAINBOW[seed % 7], "orb", 5.5, {"gravity_vec": Vector2(-150.0, -side * 40.0), "gravity_cap": 190.0})
			if high:
				for k in range(Kit.count(dm, c, 3)):
					var seed := w * 17 + k
					var y := board.position.y + board.size.y * (0.05 if k % 2 == 0 else 0.95)
					var from := Vector2(board.end.x - board.size.x * 0.12 * Kit.noise(seed, 3), y)
					_s(dm, c, from, PI + (0.35 if k % 2 == 0 else -0.35) + (Kit.noise(seed, 4) - 0.5) * 0.3, 150.0, Kit.RAINBOW[(seed + 3) % 7], "rice", 5.0, {"arming_time": 0.6})
			Kit.next(dm, c, 0.16)
		"typhoon":
			# Extreme-colour typhoon: a fast random spiral of every colour.
			for k in range(Kit.count(dm, c, 4)):
				var seed := w * 23 + k
				_s(dm, c, o, t * 2.3 + TAU * k / 4.0 + (Kit.noise(seed, 1) - 0.5) * 0.7, 80.0 + 130.0 * Kit.noise(seed, 2), Kit.RAINBOW[seed % 7], "orb" if k % 2 else "rice", 5.5)
			Kit.next(dm, c, 0.075)

# ------------------------------------------------------------------ Koakuma

static func _koakuma(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	# Two floating book emitters above and below her: red aimed arcs and
	# a slower blue ring between them.
	for side in [-1.0, 1.0]:
		var book := o + Vector2(-20.0, side * 62.0)
		_fan(dm, c, book, Kit.count(dm, c, 5, true), Kit.aim(dm, book), 0.55, 175.0, Kit.RED, "heart" if w % 2 else "orb", 5.5)
	if w % 2 == 1:
		_ring(dm, c, o, Kit.count(dm, c, 16), w * 0.2, 118.0, Kit.BLUE, "orb", 5.0)
	Kit.next(dm, c, 0.36)

# ------------------------------------------------------------------ Patchouli

const ELEMENTS := [["fire", Color("f26a3e")], ["drop", Color("5ab8f0")], ["leaf", Color("6ad070")], ["scale", Color("e6e0d0")], ["rock", Color("d0a060")]]

static func element_point(c: Dictionary, index: int) -> Vector2:
	return Vector2(c.center) + Vector2.from_angle(float(c.age) * 1.3 + TAU * index / 5.0) * 58.0

static func _patchouli(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_element_orbits":
			# The five elements orbit her; each fires its own shape in turn.
			var e := (w * 2) % 5
			var from := element_point(c, e)
			_s(dm, c, element_point(c, (e + 1) % 5), Kit.aim(dm, from), 180.0, ELEMENTS[(e + 1) % 5][1], String(ELEMENTS[(e + 1) % 5][0]), 6.0)
			match e:
				0: _fan(dm, c, from, 3, Kit.aim(dm, from), 0.3, 165.0, ELEMENTS[0][1], "fire", 6.5)
				1: _ring(dm, c, from, Kit.count(dm, c, 10), w * 0.3, 95.0, ELEMENTS[1][1], "drop", 5.5)
				2: _fan(dm, c, from, Kit.count(dm, c, 5), PI, 1.0, 120.0, ELEMENTS[2][1], "leaf", 6.0, {"angular_speed": 0.4})
				3: _fan(dm, c, from, Kit.count(dm, c, 4), Kit.aim(dm, from), 0.4, 210.0, ELEMENTS[3][1], "scale", 5.5)
				4: _fan(dm, c, from, 3, Kit.aim(dm, from), 0.6, 105.0, ELEMENTS[4][1], "rock", 8.0)
			Kit.next(dm, c, 0.32)
		"agni":
			# Agni Shine: rings of large fire bullets that bend as they spread;
			# the upper grade fires denser, quicker rings.
			var n := Kit.count(dm, c, 9 + (3 if r >= 2 else 0))
			_ring(dm, c, o, n, w * 0.29, 92.0 + (14.0 if r >= 2 else 0.0), Color("f26a3e"), "fire", 8.0, {"angular_speed": 0.42 if w % 2 == 0 else -0.42, "speed_curve": [[0.0, 125.0], [1.0, 80.0], [3.0, 105.0]]})
			Kit.next(dm, c, 0.38 if r < 2 else 0.32)
		"trilithon":
			# Lazy Trilithon: three stone columns whose shots wander off course
			# as they approach the plants.
			for i in range(3):
				var pillar := o + Vector2(-25.0, (i - 1) * board.size.y * 0.24)
				for k in range(Kit.count(dm, c, 3)):
					var seed := w * 19 + i * 5 + k
					_s(dm, c, pillar, PI + (k - 1) * 0.22, 125.0, Color("d6b06a"), "rock", 6.5, {"turns": [{"t": 1.5 + Kit.noise(seed, 1) * 1.0, "r": (Kit.noise(seed, 2) - 0.5) * 1.6, "s": 150.0}]})
			Kit.next(dm, c, 0.5)
		"trilithon_shake":
			# Trilithon Shake: the ground trembles and stones tumble in on every row.
			for k in range(Kit.count(dm, c, 5)):
				var seed := w * 31 + k
				var from := Vector2(board.end.x - 6.0, board.position.y + board.size.y * Kit.noise(seed, 1))
				_s(dm, c, from, PI + (Kit.noise(seed, 2) - 0.5) * 0.3, 115.0 + 55.0 * Kit.noise(seed, 3), Color("d6b06a"), "rock", 6.5, {"sway_amp": 9.0, "sway_freq": 9.0, "arming_time": 0.5})
			if w % 3 == 0:
				_fan(dm, c, o, 3, aim, 0.5, 120.0, Color("b07a40"), "rock", 10.0)
				Kit.effect(dm, "canon_quake", o, 140.0, 0.4, Color(0.85, 0.7, 0.45, 0.5))
			Kit.next(dm, c, 0.28)
		"cromlech":
			# Lava Cromlech: a double ring of fire plus wandering earth shots.
			var n := Kit.count(dm, c, [8, 12, 16, 20][r] * 0.8)
			var spin := Kit.noise(w, 5) * TAU
			_ring(dm, c, o, n, spin, 95.0, Color("f26a3e"), "fire", 7.0)
			_ring(dm, c, o, n, spin + PI / n, 130.0, Color("ffa040"), "fire", 6.5)
			for k in range(3):
				_s(dm, c, o, PI + (k - 1) * 0.5, 115.0, Color("d6b06a"), "rock", 5.5, {"turns": [{"t": 1.0 + 0.2 * k, "r": (Kit.noise(w * 3 + k, 6) - 0.5) * 1.4}]})
			Kit.next(dm, c, 0.48)
		"mercury":
			# Mercury Poison: two emitters spin opposite rings that cross into a
			# lattice; the way count grows as the card goes on.
			var n := Kit.count(dm, c, 9 + r * 3 + mini(6, w / 3))
			for side in [-1.0, 1.0]:
				var from := o + Vector2(-10.0, side * board.size.y * 0.2)
				_ring(dm, c, from, n, w * 0.21 * side, 105.0, Color("5ab8f0") if side < 0 else Color("f0d060"), "orb", 5.5, {"angular_speed": 0.38 * side})
			Kit.next(dm, c, 0.32)
		"forest_blaze":
			# Forest Blaze: curling leaf arms and bursts of fire.
			for arm in range(3):
				_s(dm, c, o, t * 1.9 + TAU * arm / 3.0, 125.0, Color("6ad070"), "leaf", 6.0, {"angular_speed": 0.45})
			if w % 5 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 12), w * 0.1, 105.0, Color("f26a3e"), "fire", 7.0)
			Kit.next(dm, c, 0.12)
		"silent_selene":
			# Silent Selene: pale rice rings that grow to 24 ways, and a steady
			# shower of blue rice towards the lawn.
			_ring(dm, c, o, mini(24, 12 + w), w * 0.13, 118.0, Color("bfe8ff"), "rice", 5.0)
			for k in range(Kit.count(dm, c, 5)):
				_s(dm, c, o, aim + (Kit.noise(w * 13 + k, 1) - 0.5) * 1.3, 160.0 + 60.0 * Kit.noise(w * 13 + k, 2), Kit.BLUE, "rice", 5.0)
			Kit.next(dm, c, 0.32)
		"royal_flare":
			# Royal Flare: great concentric suns, each ring curling slightly.
			_ring(dm, c, o, Kit.count(dm, c, 16), w * 0.19, 95.0, Color("ff9a40"), "big", 9.5, {"angular_speed": 0.14 if w % 2 == 0 else -0.14})
			_ring(dm, c, o, Kit.count(dm, c, 24), -w * 0.19, 135.0, Color("ffd060"), "orb", 5.5)
			Kit.next(dm, c, 0.55)
		"philosophers_stone":
			# Philosopher's Stone: five orbiting crystals, each with its element.
			var e := w % 5
			var from := element_point(c, e)
			match e:
				0:
					for k in range(2):
						_ring(dm, c, from, Kit.count(dm, c, 12), Kit.noise(w, k) * TAU, 85.0 + k * 35.0, ELEMENTS[0][1], "orb", 5.5)
				1: _fan(dm, c, from, 3, Kit.aim(dm, from), 0.18, 230.0, ELEMENTS[1][1], "rice", 5.5)
				2: _fan(dm, c, from, Kit.count(dm, c, 6), PI, 1.6, 110.0, ELEMENTS[2][1], "leaf", 6.0, {"angular_speed": -0.5})
				3:
					for k in range(Kit.count(dm, c, 6)):
						_s(dm, c, from, Kit.aim(dm, from) + (Kit.noise(w, k + 3) - 0.5) * 1.2, 140.0, Color("f6d66c"), "orb", 5.5, {"turns": [{"t": 0.8, "r": (Kit.noise(w, k + 9) - 0.5) * 2.4}]})
				4: _fan(dm, c, from, 3, Kit.aim(dm, from), 0.5, 100.0, ELEMENTS[4][1], "rock", 9.0)
			Kit.next(dm, c, 0.22)

# ------------------------------------------------------------------ Sakuya

static func _stop_time(dm: RefCounted, seconds: float) -> void:
	dm.game.boss_time_stop_timer = maxf(float(dm.game.boss_time_stop_timer), seconds)
	dm.game.boss_time_stop_flash_timer = 0.5

static func warp_point(c: Dictionary, board: Rect2, step: int) -> Vector2:
	# Misdirection's warps: one side, the other side, then centre.
	var y: float = [0.22, 0.78, 0.5][posmod(step, 3)]
	return Vector2(Vector2(c.center).x - 20.0, board.position.y + board.size.y * y)

static func _sakuya(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	var knife := Color("9fd8f0")
	match String(c.pattern):
		"nonspell_knife_fan":
			# Knives fan out, stall, then all turn on the nearest plant.
			_fan(dm, c, o, Kit.count(dm, c, 9, true), aim, 1.9, 175.0, knife, "knife", 5.5, {"speed_curve": [[0.0, 175.0], [0.55, 10.0], [0.65, 10.0]], "turns": [{"t": 0.65, "aim": true, "s": 235.0}]})
			Kit.next(dm, c, 0.42)
		"misdirection":
			# Misdirection: a kunai ring that doubles back at the target, then
			# three 11-way knife volleys from the side she warps to. The
			# illusory grade's kunai also rebound from the lawn's edges.
			var step := w % 6
			var from := warp_point(c, board, w / 6 + (0 if step == 0 else 1))
			c["warp"] = from
			if step == 0:
				Kit.effect(dm, "canon_warp", from, 54.0, 0.35, Color(0.75, 0.92, 1, 0.7))
				var extra := {"turns": [{"t": 0.6, "aim": true, "s": 205.0}]}
				if r >= 2: extra["bounces"] = 1
				_ring(dm, c, from, Kit.count(dm, c, 20), w * 0.11, 150.0, Kit.BLUE, "kunai", 5.0, extra)
				Kit.next(dm, c, 0.75)
			elif step < 4:
				if step == 1: Kit.effect(dm, "canon_warp", from, 54.0, 0.35, Color(0.75, 0.92, 1, 0.7))
				_fan(dm, c, from, Kit.count(dm, c, 11, true), Kit.aim(dm, from), 1.0, 215.0, Kit.RED, "knife", 5.5)
				Kit.next(dm, c, 0.2 if step < 3 else 0.55)
			else:
				_fan(dm, c, from, Kit.count(dm, c, 7, true), Kit.aim(dm, from), 0.7, 190.0, knife, "knife", 5.5)
				Kit.next(dm, c, 0.3)
		"clock_corpse":
			# Clock Corpse (Jack the Ludo Bile): a scatter, then time stops while
			# she lays aimed knife lines and loose blue knives; time resumes.
			if t < 0.85:
				for k in range(Kit.count(dm, c, 9)):
					var seed := w * 47 + k
					_s(dm, c, o, PI + (Kit.noise(seed, 1) - 0.5) * 2.8, 110.0 + 80.0 * Kit.noise(seed, 2), Kit.RED if k % 2 else Kit.BLUE, "orb", 5.5)
				Kit.at(c, t + 0.2 if t + 0.2 < 0.85 else 0.95)
			elif w < 30:
				if not bool(c.get("stopped", false)):
					c["stopped"] = true
					_stop_time(dm, 1.15)
				var target: Vector2 = dm._target(o)
				var lines := 1 if r < 2 else 3
				for line in range(lines):
					var a := (target - o).angle() + (line - (lines - 1) * 0.5) * 0.16
					for k in range(4):
						_s(dm, c, o + Vector2.from_angle(a) * (40.0 + k * 34.0), a, 190.0, knife, "knife", 5.5)
				for k in range(Kit.count(dm, c, 6 + r * 2)):
					var seed := w * 59 + k
					var p := target + Vector2.from_angle(Kit.noise(seed, 1) * TAU) * (150.0 + 70.0 * Kit.noise(seed, 2))
					p = p.clamp(board.position, board.end)
					_s(dm, c, p, (target - p).angle() + (Kit.noise(seed, 3) - 0.5) * 0.5, 150.0, Kit.BLUE, "knife", 5.0, {"arming_time": 0.4})
				Kit.at(c, t + 0.3 if t + 0.3 < 1.9 else 99.0)
		"luna_clock":
			# Luna Clock (The World): time is already stopped; knives close in on
			# the plants from every side. When time resumes, a fixed ring
			# follows (rice on Normal, fire from Hard; Lunatic doubles it).
			var target: Vector2 = dm._target(o)
			if t < 2.0:
				var n := Kit.count(dm, c, 7 + r)
				var radius := 170.0 + 30.0 * (w % 2)
				for k in range(n):
					var a := TAU * k / n + w * 0.37
					var p := (target + Vector2.from_angle(a) * radius).clamp(board.position, board.end)
					_s(dm, c, p, (target - p).angle(), 165.0, Color("8fe08f") if k % 2 else knife, "knife", 5.5, {"arming_time": 0.3})
				_fan(dm, c, o, 3, (target - o).angle(), 0.12, 210.0, knife, "knife", 5.5)
				if w == 0 and r >= 2:
					_ring(dm, c, o, Kit.count(dm, c, 12), 0.0, 110.0, Color("f26a3e"), "fire", 7.0, {"turns": [{"t": 0.05, "r": 0.7}]})
				Kit.at(c, t + 0.4 if t + 0.4 < 2.0 else 2.3)
			else:
				if r < 2:
					_ring(dm, c, o, Kit.count(dm, c, 24), w * 0.2, 125.0, knife, "rice", 5.0)
				else:
					_ring(dm, c, o, Kit.count(dm, c, 12), w * 0.2, 115.0, Color("f26a3e"), "fire", 7.0)
					if r >= 3: _ring(dm, c, o, Kit.count(dm, c, 14), -w * 0.2, 90.0, Color("ffa040"), "fire", 6.5)
				Kit.next(dm, c, 0.45)
		"marionette":
			# Marionette (Killing Doll): blue knife volleys and a narrower red fan,
			# a short time stop scattering green knives, some of which rebound.
			if t < 1.3:
				_fan(dm, c, o, [3, 4, 5, 5][r], aim, 0.36, 225.0, Kit.BLUE, "knife", 5.5)
				if w % 2 == 1:
					_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.16, 250.0, Kit.RED, "knife", 5.0)
				Kit.at(c, t + 0.15 if t + 0.15 < 1.3 else 1.35)
			elif t < 2.3:
				if not bool(c.get("stopped", false)):
					c["stopped"] = true
					_stop_time(dm, 0.9)
				for k in range(Kit.count(dm, c, 7 + r * 2)):
					var seed := w * 67 + k
					var p := o + Vector2.from_angle(Kit.noise(seed, 1) * TAU) * (60.0 + 220.0 * Kit.noise(seed, 2))
					var extra := {"arming_time": 0.3}
					if k % 3 == 0: extra["bounces"] = 1
					_s(dm, c, p.clamp(board.position, board.end), PI + (Kit.noise(seed, 3) - 0.5) * 2.2, 165.0, Color("8fe08f"), "knife", 5.5, extra)
				Kit.at(c, t + 0.3 if t + 0.3 < 2.3 else 99.0)
		"eternal_meek":
			# Eternal Meek: one source spraying blue orbs at every speed.
			for k in range(Kit.count(dm, c, 4)):
				var seed := w * 71 + k
				_s(dm, c, o, Kit.noise(seed, 1) * TAU, 70.0 + 260.0 * pow(Kit.noise(seed, 2), 1.3), Kit.BLUE, "orb", 5.5)
			Kit.next(dm, c, 0.055)

# ------------------------------------------------------------------ Remilia

static func hexagram(c: Dictionary, board: Rect2, turn: float) -> Array:
	var centre := Vector2(board.position.x + board.size.x * 0.64, board.get_center().y)
	var radius := board.size.y * 0.46
	var points: Array = []
	for i in range(6):
		points.append(centre + Vector2.from_angle(-PI * 0.5 + TAU * i / 6.0 + turn) * radius)
	return points

static func _scarlet_cluster(dm: RefCounted, c: Dictionary, from: Vector2, a: float, big_speed: float, scale: float) -> void:
	# A Scarlet Shoot round: the large bullet leads, medium and small
	# bullets scatter in its wake.
	_s(dm, c, from, a, big_speed, Kit.RED, "big", 11.0 * scale)
	for k in range(Kit.count(dm, c, 4)):
		var seed := int(c.wave) * 83 + k + int(a * 100.0)
		_s(dm, c, from, a + (Kit.noise(seed, 1) - 0.5) * 0.3, big_speed * (0.7 + 0.2 * Kit.noise(seed, 2)), Color("f5707a"), "orb", 7.0)
	for k in range(Kit.count(dm, c, 6)):
		var seed := int(c.wave) * 89 + k + int(a * 100.0)
		_s(dm, c, from, a + (Kit.noise(seed, 3) - 0.5) * 0.6, big_speed * (0.45 + 0.35 * Kit.noise(seed, 4)), Color("ff9aa0"), "orb", 4.5)

static func _remilia(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_scarlet_crossfire":
			# Bat-wing emitters cross red streams; every other beat a large
			# bullet heads a swarm of small bats.
			for side in [-1.0, 1.0]:
				var wing := o + Vector2(-30.0, side * 70.0)
				_fan(dm, c, wing, Kit.count(dm, c, 5, true), Kit.aim(dm, wing), 0.7, 175.0, Kit.RED, "orb", 6.0)
			if w % 2 == 1:
				_s(dm, c, o, aim, 150.0, Kit.RED, "big", 11.0)
				_ring(dm, c, o, Kit.count(dm, c, 10), w * 0.3, 105.0, Color("c04060"), "bat", 5.5)
			Kit.next(dm, c, 0.36)
		"david":
			# Star of David: two triangles of lasers across the lawn while
			# round bullets and ring bullets fly from her.
			if w % 6 == 0:
				var points := hexagram(c, board, w * 0.09)
				c["hexagram"] = points
				for i in range(6):
					Kit.beam(dm, c, TUNE, points[i], points[(i + 2) % 6], Kit.RED, 1.05, 8.0, 0.45)
			if w % 2 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 20), w * 0.17, 115.0, Kit.RED, "orb", 6.0)
			else:
				_fan(dm, c, o, 5, aim, 0.7, 150.0, Kit.BLUE, "ring", 6.5)
			Kit.next(dm, c, 0.32)
		"young_demon_lord":
			# Young Demon Lord: a fan of lasers sweeping across her front and
			# large bullets with rice between them.
			if w % 6 == 0:
				for k in range(5):
					Kit.ray(dm, c, TUNE, o, PI + (k - 2) * 0.32, Kit.RED, 1.0, 8.0, 1.0, {"turn_rate": 0.3 if (w / 6) % 2 == 0 else -0.3})
			_ring(dm, c, o, Kit.count(dm, c, 10), w * 0.23, 95.0, Kit.RED, "big", 9.5)
			_fan(dm, c, o, Kit.count(dm, c, 9, true), aim, 1.2, 165.0, Color("ff9aa0"), "rice", 5.0)
			Kit.next(dm, c, 0.4)
		"scarlet_nether":
			# Scarlet Netherworld: a 16-way shower falling across the far lawn
			# and two counter-turning 24-way rings, at a random first angle.
			for k in range(Kit.count(dm, c, 8)):
				var from := Vector2(board.end.x - 8.0, board.position.y + board.size.y * (k + 0.5) / 8.0 + (Kit.noise(w, k) - 0.5) * 30.0)
				_s(dm, c, from, PI, 120.0, Color("d04060"), "orb", 5.5, {"arming_time": 0.5})
			var spin := Kit.noise(w, 77) * TAU
			for side in [-1.0, 1.0]:
				_ring(dm, c, o, Kit.count(dm, c, 12), spin, 110.0, Kit.RED if side < 0 else Color("f590b0"), "orb", 5.5, {"angular_speed": 0.35 * side, "angular_stop_at": 1.6})
			Kit.next(dm, c, 0.55)
		"thousand_needles":
			# Needle Mountain: rows of red needles raining in, gaps shifting.
			var gap := w % 6
			for k in range(6):
				if k == gap: continue
				var y := board.position.y + board.size.y * (k + 0.5) / 6.0 + (Kit.noise(w, k) - 0.5) * 40.0
				_s(dm, c, Vector2(board.end.x - 4.0, y), PI + (Kit.noise(w, k + 9) - 0.5) * 0.12, 245.0, Kit.RED, "needle", 4.5, {"arming_time": 0.35})
			if w % 5 == 0:
				_fan(dm, c, o, 5, aim, 0.5, 170.0, Color("f590b0"), "orb", 6.5)
			Kit.next(dm, c, 0.13)
		"vlad":
			# Vlad Tepes' Curse: a spiral of blue knives (13 growing to 18 ways)
			# whose paths leave red bullets that slowly spread.
			var n := Kit.count(dm, c, mini(18, 13 + w))
			_ring(dm, c, o, n, w * 0.31, 135.0, Kit.BLUE, "knife", 5.5, {"angular_speed": 0.55, "trail_every": 0.22, "trail_at": 0.25, "trail_left": 6, "trail": {"count": 1, "turn": PI * 0.5, "speed": 6.0, "color": Kit.RED, "shape": "orb", "extra": {"radius": 4.5, "gravity_vec": Vector2(-70.0, 0.0), "gravity_at": 0.8, "gravity_cap": 110.0}}})
			Kit.next(dm, c, 0.62)
		"vampire_illusion":
			# Vampire Illusion: large blue bullets ricochet off the lawn edges,
			# shedding red bullets along the way.
			_fan(dm, c, o, Kit.count(dm, c, 6), PI, 2.0, 125.0, Kit.BLUE, "big", 9.0, {"bounces": 2, "trail_every": 0.25, "trail_left": 8, "trail": {"count": 2, "turn": PI * 0.5, "spread": PI, "speed": 30.0, "color": Kit.RED, "shape": "orb", "extra": {"radius": 4.5, "damage_scale": 0.5}}})
			Kit.next(dm, c, 0.55)
		"scarlet_shoot", "scarlet_meister":
			# Scarlet Shoot: aimed great bullets in 5-way (half circle), 3-way,
			# 5-way rounds; Scarlet Meister widens it and adds a ring.
			var meister := String(c.pattern) == "scarlet_meister"
			var ways := 3 if w % 3 == 1 else (7 if meister else 5)
			var spread := PI * (0.55 if ways == 3 else (1.1 if meister else 1.0))
			for k in range(ways):
				_scarlet_cluster(dm, c, o, aim + (float(k) / (ways - 1) - 0.5) * spread, 165.0, 1.15 if meister else 1.0)
			if meister and w % 2 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 20), w * 0.2, 120.0, Kit.RED, "orb", 5.5)
			Kit.next(dm, c, 0.55)
		"red_magic", "scarlet_gensokyo":
			# Red Magic: great bullets in every direction, each shedding small
			# bullets from its path; they rebound from the edges once. The
			# Scarlet Gensokyo opens each loop with a 56-way ring.
			var gensokyo := String(c.pattern) == "scarlet_gensokyo"
			if gensokyo and w % 2 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 36), w * 0.11, 150.0, Kit.RED, "orb", 5.0)
				Kit.next(dm, c, 0.6)
				return
			_ring(dm, c, o, Kit.count(dm, c, 7), w * 0.43, 80.0, Kit.RED, "big", 12.0, {"bounces": 1, "trail_every": 0.17, "trail_left": 14, "trail": {"count": 1, "random": true, "speed": 22.0, "color": Color("ff8090"), "shape": "orb", "extra": {"radius": 4.5, "gravity_vec": Vector2(-55.0, 0.0), "gravity_at": 0.6, "gravity_cap": 100.0}}, "uid_seed": w * 97})
			Kit.next(dm, c, 1.2 if not gensokyo else 0.8)

# ------------------------------------------------------------------ Flandre

static func familiar_points(c: Dictionary, board: Rect2, count: int, radius_scale: float = 0.36) -> Array:
	var centre := Vector2(board.position.x + board.size.x * 0.66, board.get_center().y)
	var points: Array = []
	for i in range(count):
		var a := float(c.age) * 0.55 + TAU * i / count
		points.append(centre + Vector2(cos(a) * board.size.x * radius_scale * 0.62, sin(a) * board.size.y * radius_scale))
	return points

static func clock_pivot(board: Rect2) -> Vector2:
	return Vector2(board.position.x + board.size.x * 0.66, board.get_center().y)

static func _flandre(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_crystal_fan":
			# Her wings' seven crystal colours, each a short aimed line.
			for k in range(7):
				_s(dm, c, o, aim + (k - 3) * 0.2, 190.0 - absf(k - 3) * 14.0, Kit.RAINBOW[k], "star" if w % 2 else "orb", 6.0)
			Kit.next(dm, c, 0.3)
		"cranberry":
			# Cranberry Trap: four familiars circle the lawn firing fixed purple
			# lines inward; Flandre adds aimed blue bullets.
			var points := familiar_points(c, board, 4)
			var centre := Vector2(board.position.x + board.size.x * 0.66, board.get_center().y)
			for p in points:
				_fan(dm, c, p, 3, (centre - p).angle() + 0.55, 0.5, 115.0, Kit.VIOLET, "orb", 5.5, {"arming_time": 0.35})
			if w % 3 == 0:
				_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.45, 185.0, Kit.BLUE, "orb", 6.0)
			Kit.next(dm, c, 0.26)
		"laevatein":
			# Laevatein: a flame blade swept across the whole lawn, scattering
			# embers from its edge; the second swing returns the other way.
			var swing := w % 6
			if swing == 0:
				var dir := 1.0 if (w / 6) % 2 == 0 else -1.0
				Kit.ray(dm, c, TUNE, o, PI - dir * 1.1, Color("ff6a3a"), 0.85, 12.0, 1.55, {"turn_rate": dir * 1.42, "laevatein": true})
				c["swing_dir"] = dir
				c["swing_start"] = t
			elif swing < 5:
				var dir := float(c.get("swing_dir", 1.0))
				var blade := PI - dir * 1.1 + dir * 1.42 * maxf(0.0, t - float(c.get("swing_start", 0.0)) - 0.85)
				for k in range(Kit.count(dm, c, 3)):
					var reach := 120.0 + 170.0 * k
					_s(dm, c, o + Vector2.from_angle(blade) * reach, blade - dir * PI * 0.5, 60.0, Color("ff9a5a"), "rice", 5.0, {"speed_curve": [[0.0, 30.0], [1.0, 110.0]]})
			Kit.next(dm, c, 0.85 if swing == 0 else (0.28 if swing < 5 else 0.3))
		"four_of_a_kind":
			# Four of a Kind: all four Flandres open with thin aimed volleys,
			# then each one fires medium bullets in her own colour.
			var bodies: Array = [o]
			for actor in c.actors: bodies.append(Vector2(actor.position))
			var colors := [Kit.RED, Kit.BLUE, Kit.GREEN, Kit.GOLD]
			for i in range(bodies.size()):
				var from: Vector2 = bodies[i]
				if t < 1.4:
					_fan(dm, c, from, 3, Kit.aim(dm, from), 0.35, 175.0, colors[i], "rice", 5.0)
				else:
					_ring(dm, c, from, Kit.count(dm, c, 8), w * 0.3 + i, 105.0, colors[i], "orb", 7.0)
			Kit.next(dm, c, 0.32)
		"kagome":
			# Kagome Kagome: a lattice of green bullets closes over the lawn and
			# drifts in slowly while great yellow bullets roll through it.
			if w == 0 or w == 9:
				var centre := Vector2(board.position.x + board.size.x * 0.6, board.get_center().y)
				var step := minf(board.size.y, board.size.x) * 0.1
				var span := 7
				for i in range(-span, span + 1):
					for j in range(-span, span + 1):
						if (i + j) % 2 != 0: continue
						var p := centre + Vector2(i * step * 1.05, j * step * 0.62).rotated(0.0)
						# The cage closes over the far lawn, never on top of plants.
						if not board.has_point(p) or p.x > board.end.x - 30.0 or p.x < board.position.x + board.size.x * 0.42: continue
						_s(dm, c, p, PI, 0.0, Kit.GREEN, "orb", 5.0, {"arming_time": 0.9, "speed_curve": [[0.0, 0.0], [1.2, 0.0], [2.2, 30.0]], "facing": PI, "life": 9.0})
			for k in range(2):
				_s(dm, c, o, aim + (k - 0.5) * 0.35 + (Kit.noise(w, 3) - 0.5) * 0.3, 115.0, Kit.GOLD, "big", 12.0)
			Kit.next(dm, c, 0.36)
		"maze":
			# Maze of Love: rice walls with one wide gap; blue gaps turn one way,
			# red the other, and both reverse partway through.
			var blue := w % 2 == 0
			var flip := -1.0 if t > 1.7 else 1.0
			var gap := (t * 1.0 if blue else -t * 1.0 + 1.3) * flip
			var n := Kit.count(dm, c, 34)
			for k in range(n):
				var a := TAU * k / n
				if absf(angle_difference(a, gap)) < 0.42: continue
				_s(dm, c, o, a, 105.0, Kit.BLUE if blue != (flip < 0) else Kit.RED, "rice", 5.0)
			Kit.next(dm, c, 0.3)
		"starbow":
			# Starbow Break: rainbow bullets flung everywhere fall back across
			# the lawn like rain.
			for k in range(Kit.count(dm, c, 4)):
				var seed := w * 43 + k
				_s(dm, c, o, (Kit.noise(seed, 1) - 0.5) * PI * 1.8, 120.0 + 60.0 * Kit.noise(seed, 2), Kit.RAINBOW[seed % 7], "star", 6.5, {"gravity_vec": Vector2(-120.0, 0.0), "gravity_cap": 170.0})
			Kit.next(dm, c, 0.11)
		"catadioptric":
			# Catadioptric: large bullets leave towards the lawn edges and
			# rebound twice, followed by trains of smaller bullets.
			var side := 1.0 if w % 2 == 0 else -1.0
			var n := Kit.count(dm, c, 4)
			for k in range(n):
				var a := PI + side * (0.45 + 0.5 * k / maxf(1.0, n - 1))
				_s(dm, c, o, a, 210.0, Kit.BLUE, "big", 10.0, {"bounces": 2})
				for f in range(3):
					_s(dm, c, o, a, 170.0 - f * 26.0, Color("8ac8f8"), "orb", 5.0, {"bounces": 2})
			Kit.next(dm, c, 0.48)
		"past_clock":
			# Clock that Ticks Away the Past: a clock of crossed laser hands turns
			# over the lawn while aimed bullets stream from Flandre.
			if w == 0:
				var pivot := clock_pivot(board)
				var reach := board.size.y * 0.62
				for hand in range(2):
					var a := hand * PI * 0.5 + 0.3
					Kit.beam(dm, c, TUNE, pivot - Vector2.from_angle(a) * reach, pivot + Vector2.from_angle(a) * reach, Color("ff6a5a") if hand == 0 else Color("6ab0ff"), 1.0, 9.0, 2.3, {"pivot": pivot, "pivot_rate": 0.62})
			_fan(dm, c, o, 3, aim, 0.24, 200.0, Kit.BLUE, "orb", 5.5)
			Kit.next(dm, c, 0.25)
		"and_then_none":
			# And Then There Were None?: Flandre fades out; her familiars first
			# send homing bullets, then fixed rotating rings.
			var points := familiar_points(c, board, 4, 0.4)
			if t < 4.5:
				for p in points:
					_s(dm, c, p, Kit.aim(dm, p) + (Kit.noise(w, 1) - 0.5) * 1.2, 95.0, Kit.BLUE, "orb", 5.5, {"home_rate": 0.9, "home_live": true, "home_until": 2.5})
				Kit.next(dm, c, 0.45)
			else:
				for i in range(points.size()):
					_ring(dm, c, points[i], Kit.count(dm, c, 9), w * 0.17 * (1 if i % 2 else -1), 95.0, Color("ff8a4a"), "orb", 5.5)
				Kit.next(dm, c, 0.55)
		"qed":
			# QED "Ripples of 495 Years": rings ripple out from points around
			# her and rebound from the lawn edges, coming faster and denser.
			var centre := o + Vector2(-board.size.x * 0.12, (Kit.noise(w, 1) - 0.5) * board.size.y * 0.7)
			_ring(dm, c, centre, Kit.count(dm, c, mini(40, 20 + w)), w * 0.2, 95.0 + w * 2.0, Kit.BLUE if w % 2 else Color("6a8af8"), "orb", 5.5, {"bounces": 1, "arming_time": 0.2})
			Kit.effect(dm, "canon_ripple", centre, 60.0, 0.5, Color(0.6, 0.75, 1, 0.6))
			Kit.next(dm, c, lerpf(0.68, 0.26, clampf(t / 3.4, 0.0, 1.0)))

# ------------------------------------------------------------------ cast overlays

static func _clock_face(game: Control, centre: Vector2, radius: float, time: float, alpha: float, tint: Color) -> void:
	game.draw_circle(centre, radius, Color(tint, 0.06 * alpha))
	game.draw_arc(centre, radius, 0, TAU, 48, Color(tint, 0.55 * alpha), 2.0, true)
	game.draw_arc(centre, radius * 0.86, 0, TAU, 48, Color(tint, 0.3 * alpha), 1.2, true)
	for i in range(12):
		var a := TAU * i / 12.0
		game.draw_line(centre + Vector2.from_angle(a) * radius * 0.86, centre + Vector2.from_angle(a) * radius * (0.74 if i % 3 == 0 else 0.8), Color(tint, 0.7 * alpha), 2.0 if i % 3 == 0 else 1.0, true)
	game.draw_line(centre, centre + Vector2.from_angle(-PI * 0.5 + time * 0.5) * radius * 0.55, Color(tint, 0.8 * alpha), 3.0, true)
	game.draw_line(centre, centre + Vector2.from_angle(-PI * 0.5 + time * 3.0) * radius * 0.78, Color(tint, 0.8 * alpha), 1.8, true)
	game.draw_circle(centre, radius * 0.05, Color(tint, 0.9 * alpha))

static func draw_cast(game: Control, c: Dictionary) -> void:
	var u := minf(game.CELL_SIZE.x / 135.0, game.CELL_SIZE.y / 127.0)
	var o := Vector2(c.center)
	var t := float(c.age)
	var fade := clampf(t / 0.4, 0.0, 1.0) * clampf((float(c.duration) - t) / 0.4, 0.0, 1.0)
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var p := String(c.pattern)
	match String(c.kind):
		"rumia_boss":
			# The sphere of darkness she wraps herself in.
			for k in range(4):
				game.draw_circle(o + Vector2(0, -20 * u), (70.0 - k * 12.0) * u * (1.0 + 0.04 * sin(t * 3.0 + k)), Color(0.06, 0.02, 0.1, 0.1 * fade))
			if p == "night_bird":
				for side in [-1.0, 1.0]:
					var wing := PackedVector2Array()
					for i in range(9):
						var a: float = PI + side * (0.2 + i * 0.16)
						wing.append(o + Vector2.from_angle(a) * (40.0 + i * 9.0) * u * (1.0 + 0.15 * sin(t * 6.0)))
					game.draw_polyline(wing, Color(0.55, 0.45, 0.95, 0.5 * fade), 2.5 * u, true)
		"cirno_boss":
			if p == "perfect_freeze":
				var frozen := (t > 0.55 and t < 1.5) or (t > 2.35 and t < 3.25)
				if frozen:
					game.draw_rect(board, Color(0.75, 0.92, 1.0, 0.09), true)
					for k in range(14):
						var flake := board.position + board.size * Vector2(Kit.noise(k, 1), Kit.noise(k, 2))
						Glyphs.draw(game, flake, 9.0 * u, "snow", t * 0.5 + k, Color(0.9, 0.98, 1.0, 0.45))
			for k in range(6):
				var a := t * 1.5 + TAU * k / 6.0
				Glyphs.draw(game, o + Vector2(cos(a) * 46.0, sin(a) * 20.0 - 26.0) * u, 6.0 * u, "snow", a, Color(0.85, 0.97, 1.0, 0.7 * fade))
		"meiling_boss":
			for k in range(7):
				game.draw_arc(o + Vector2(0, -24 * u), (52.0 + k * 4.0) * u, t * 0.8 + k * 0.3, t * 0.8 + k * 0.3 + PI * 0.7, 18, Color(Kit.RAINBOW[k], 0.45 * fade), 2.0 * u, true)
		"koakuma_boss", "daiyousei_boss":
			for side in [-1.0, 1.0]:
				var spot := o + Vector2(-20.0, side * 62.0) * u
				Glyphs.draw(game, spot + Vector2(0, sin(t * 4.0 + side) * 4.0 * u), 10.0 * u, "book" if String(c.kind) == "koakuma_boss" else "flower", t * 0.4, Color(Kit.PINK if String(c.kind) == "koakuma_boss" else Kit.GREEN, 0.7 * fade))
		"patchouli_boss":
			for i in range(5):
				var spot := element_point(c, i)
				var tint: Color = ELEMENTS[i][1]
				game.draw_circle(spot, 11.0 * u, Color(tint, 0.18 * fade))
				game.draw_circle(spot, 6.0 * u, Color(tint, 0.85 * fade))
				game.draw_circle(spot, 2.6 * u, Color(1, 1, 1, 0.9 * fade))
			if p == "royal_flare":
				for k in range(10):
					var a := TAU * k / 10.0 + t * 0.4
					game.draw_line(o + Vector2.from_angle(a) * 40.0 * u, o + Vector2.from_angle(a) * (70.0 + 10.0 * sin(t * 5.0 + k)) * u, Color(1, 0.75, 0.35, 0.5 * fade), 3.0 * u, true)
				game.draw_circle(o, 38.0 * u, Color(1, 0.7, 0.3, 0.15 * fade))
			elif p == "silent_selene":
				Glyphs.draw(game, o + Vector2(10, -60) * u, 26.0 * u, "moon", -0.4, Color(0.8, 0.92, 1.0, 0.35 * fade))
		"sakuya_boss":
			if p in ["luna_clock", "clock_corpse", "marionette"] and float(game.boss_time_stop_timer) > 0.0:
				_clock_face(game, Vector2(board.position.x + board.size.x * 0.55, board.get_center().y), board.size.y * 0.42, t, 1.0, Color(0.8, 0.9, 1.0))
			if c.has("warp"):
				var spot := Vector2(c.warp)
				game.draw_arc(spot, 30.0 * u, t * 3.0, t * 3.0 + PI * 1.5, 24, Color(0.7, 0.9, 1.0, 0.5 * fade), 2.0 * u, true)
		"remilia_boss":
			game.draw_circle(o + Vector2(10, -70) * u, 30.0 * u, Color(0.95, 0.15, 0.25, 0.12 * fade))
			game.draw_arc(o + Vector2(10, -70) * u, 30.0 * u, 0, TAU, 32, Color(1, 0.3, 0.35, 0.35 * fade), 1.5 * u, true)
			if p == "david" and c.has("hexagram"):
				var points: Array = c.hexagram
				for i in range(6):
					game.draw_line(points[i], points[(i + 2) % 6], Color(1, 0.3, 0.4, 0.18 * fade), 2.0 * u, true)
				for spot in points:
					game.draw_circle(spot, 8.0 * u, Color(1, 0.4, 0.45, 0.45 * fade))
		"flandre_boss":
			if p in ["cranberry", "and_then_none"]:
				for spot in familiar_points(c, board, 4, 0.36 if p == "cranberry" else 0.4):
					game.draw_circle(spot, 14.0 * u, Color(0.75, 0.4, 0.95, 0.18 * fade))
					game.draw_arc(spot, 12.0 * u, t * 4.0, t * 4.0 + TAU, 16, Color(0.9, 0.6, 1.0, 0.7 * fade), 1.6 * u, true)
					Glyphs.draw(game, spot, 6.0 * u, "crystal", t, Color(1, 1, 1, 0.8 * fade))
			elif p == "past_clock":
				_clock_face(game, clock_pivot(board), board.size.y * 0.62, t, fade, Color(1.0, 0.75, 0.6))
			elif p == "laevatein" and c.has("swing_start"):
				var live := t - float(c.swing_start) - 0.85
				if live > 0.0 and live < 1.55:
					var dir := float(c.get("swing_dir", 1.0))
					var blade := PI - dir * 1.1 + dir * 1.42 * live
					var axis := Vector2.from_angle(blade)
					var reach := board.size.length()
					# The flame sword: a burning band with a white-hot edge and
					# tongues of fire licking off the trailing side.
					game.draw_line(o, o + axis * reach, Color(1, 0.35, 0.15, 0.22), 34.0 * u, true)
					game.draw_line(o, o + axis * reach, Color(1, 0.6, 0.25, 0.35), 18.0 * u, true)
					for k in range(16):
						var spot := o + axis * (50.0 + k * 62.0) * u - axis.orthogonal() * dir * (8.0 + 6.0 * sin(t * 18.0 + k)) * u
						Glyphs.draw(game, spot, (15.0 - k * 0.5) * u, "flame", blade - dir * PI * 0.5, Color(1, 0.5 + 0.025 * k, 0.2, 0.75))
