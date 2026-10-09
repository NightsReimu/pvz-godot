extends RefCounted
# Shared emitters for the reworked TH06/TH07/TH08 cards. Patterns author their
# own emission clock ("own_clock"), shoot through the native swept collisions
# and scale their per-bullet damage by a per-card factor, calibrated so each
# reworked card keeps the pressure of the version it replaced.

const Motion = preload("res://scripts/runtime/touhou_canon_motion.gd")
const WindGodFX = preload("res://scripts/runtime/wind_god_fx.gd")
const RED := Color("ef5474")
const BLUE := Color("58b8f0")
const SKY := Color("7fd8ff")
const GOLD := Color("f6d66c")
const GREEN := Color("7ed870")
const VIOLET := Color("b88cf0")
const ORANGE := Color("f99b62")
const PINK := Color("f590c8")
const WHITE := Color("f4f8ff")
const RAINBOW := [Color("f05a5a"), Color("f6a24a"), Color("f6dc5a"), Color("6fd88a"), Color("5ac8f0"), Color("6f86f0"), Color("b48cf0")]

static func noise(a: int, b: int = 0) -> float:
	return WindGodFX.noise(a, b)

static func rank(dm: RefCounted) -> int:
	return int(dm.Difficulty.profile(dm.game.current_level).rank)

static func unit(dm: RefCounted) -> float:
	# 1.0 on the 1600x900 desktop lawn, smaller on phones.
	var cell: Vector2 = dm.game.CELL_SIZE
	return minf(cell.x / 135.0, cell.y / 127.0)

static func board(dm: RefCounted) -> Rect2:
	return Rect2(dm.game.BOARD_ORIGIN, dm.game.board_size)

static func density(dm: RefCounted, c: Dictionary) -> float:
	return dm._attack_density_for_cast(c)

static func count(dm: RefCounted, c: Dictionary, n: float, odd: bool = false) -> int:
	var result := maxi(1, ceili(n * density(dm, c)))
	if odd and result % 2 == 0:
		result += 1
	return result

static func aim(dm: RefCounted, from: Vector2) -> float:
	return (dm._target(from) - from).angle()

static func next(dm: RefCounted, c: Dictionary, seconds: float) -> void:
	# Absolute deadline on the cast clock, scaled by the difficulty cadence.
	# "rate" (per card) packs more volleys into rings that mostly face away.
	c.next_wave = float(c.age) + seconds / float(c.get("rate", 1.0)) * dm.Difficulty.attack_cadence(String(c.kind), dm.game.current_level)

static func at(c: Dictionary, time: float) -> void:
	# Absolute deadline for cards whose beats are fixed in the original.
	c.next_wave = time

static func damage(c: Dictionary, tune: Dictionary) -> float:
	var base: float = 32.0 + float(c.get("phase", 0)) * 6.0
	return base * float(tune.get(String(c.pattern), 1.0))

static func shoot(dm: RefCounted, c: Dictionary, tune: Dictionary, from: Vector2, angle: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	var u := unit(dm)
	var data := {"radius": radius * u, "damage": damage(c, tune) * float(extra.get("dmg", 1.0)), "cm": true, "facing": angle, "spin_phase": noise(int(c.wave) * 31 + dm.bullets.size(), 5) * TAU}
	for key in extra:
		if key != "dmg":
			data[key] = extra[key]
	if data.has("speed_curve"):
		var curve: Array = []
		for point in data.speed_curve:
			curve.append([float(point[0]), float(point[1]) * u])
		data.speed_curve = curve
	if data.has("turns"):
		var turns: Array = []
		for turn in data.turns:
			var copy: Dictionary = turn.duplicate()
			if copy.has("s"): copy.s = float(copy.s) * u
			turns.append(copy)
		data.turns = turns
	if data.has("gravity_vec"):
		data.gravity_vec = Vector2(data.gravity_vec) * u
	if data.has("gravity_cap"):
		data.gravity_cap = float(data.gravity_cap) * u
	dm._bullet(c, from, angle, speed * u, color, shape, data)

static func fan(dm: RefCounted, c: Dictionary, tune: Dictionary, from: Vector2, n: int, angle: float, spread: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	for i in range(n):
		var offset := 0.0 if n == 1 else (float(i) / (n - 1) - 0.5) * spread
		shoot(dm, c, tune, from, angle + offset, speed, color, shape, radius, extra)

static func ring(dm: RefCounted, c: Dictionary, tune: Dictionary, from: Vector2, n: int, rotation: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	# A ring fired from the lawn's far edge loses its outward half at once;
	# skip those few frames of bullets so the budget goes to the lawn.
	var edge := from.x > board(dm).end.x - board(dm).size.x * 0.1 and not extra.has("orbit_center") and not extra.has("turns") and float(extra.get("angular_speed", 0.0)) == 0.0
	for i in range(n):
		var a := rotation + TAU * i / n
		if edge and cos(a) > 0.45:
			continue
		shoot(dm, c, tune, from, a, speed, color, shape, radius, extra)

static func beam(dm: RefCounted, c: Dictionary, tune: Dictionary, from: Vector2, to: Vector2, color: Color, delay: float, width: float, duration: float = 0.4, extra: Dictionary = {}) -> void:
	var u := unit(dm)
	var data := {"damage": (68.0 + float(c.get("phase", 0)) * 8.0) * float(tune.get(String(c.pattern), 1.0)) * float(extra.get("dmg", 1.0)), "duration": duration, "cm": true}
	for key in extra:
		if key != "dmg":
			data[key] = extra[key]
	dm._beam(c, from, to, color, delay, width * u, data)

static func ray(dm: RefCounted, c: Dictionary, tune: Dictionary, from: Vector2, angle: float, color: Color, delay: float, width: float, duration: float = 0.4, extra: Dictionary = {}) -> void:
	var reach: float = dm.game.board_size.length() * 1.3
	beam(dm, c, tune, from, from + Vector2.from_angle(angle) * reach, color, delay, width, duration, extra)

static func lane_y(dm: RefCounted, row: int) -> float:
	return dm.game._row_center_y(row) - 12.0

static func rows(dm: RefCounted) -> Array:
	return dm.game.active_rows

static func point(dm: RefCounted, x: float, y: float) -> Vector2:
	return dm._point(x, y)

static func effect(dm: RefCounted, shape: String, position: Vector2, radius: float, time: float, color: Color, extra: Dictionary = {}) -> void:
	var data := {"shape": shape, "position": position, "radius": radius, "time": time, "duration": time, "color": color}
	data.merge(extra, true)
	dm.game.effects.append(data)
