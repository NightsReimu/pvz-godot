extends RefCounted

const RED = Color("ff6b88")
const BLUE = Color("92ddff")
const GOLD = Color("ffe0aa")

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var g: Control = dm.game
	var rank = int(g.TouhouDifficulty.profile(g.current_level).rank)
	var scale = minf(g.CELL_SIZE.x / 100.0, g.CELL_SIZE.y / 110.0)
	var origin = Vector2(c.center)
	var aim: float = (dm._target(origin) - origin).angle()
	var wave = int(c.wave)
	var p = String(c.pattern)
	var extra = {"damage": 22.0, "radius": 5.0 * scale, "arming_time": 0.65}
	match p:
		"eirin_vessel":
			# Encircling heavenly spheres, with a quiet center and rotating openings.
			dm._ring(c, origin, 16 + rank * 2, wave * 0.17, 100 * scale, BLUE, "orb", {"damage": 12.0, "radius": 5 * scale, "arming_time": 0.7})
		"nonspell_eirin_arrows":
			dm._fan(c, origin, 7 + rank * 2, aim, 1.1, 165 * scale, RED, "rice", extra)
		"eirin_memories", "eirin_genealogy":
			# Branching genealogy: each generation forks at a progressively wider node.
			for side in [-1, 1]:
				var fork: Vector2 = dm._point(0.68 - (wave % 3) * 0.12, 0.5 + side * (0.1 + (wave % 3) * 0.12))
				dm._beam(c, origin, fork, BLUE, 0.9, 6 * scale, {"damage": 40.0})
				dm._fan(c, fork, 5 + rank * 2, PI + side * 0.22, 0.9, 125 * scale, RED, "rice", extra)
		"eirin_life", "eirin_rising":
			for row in range(6):
				if (row + wave) % 2 == 0:
					var point: Vector2 = dm._point(0.75 - (wave % 3) * 0.13, (row + 0.5) / 6)
					dm._ring(c, point, 8 + rank * 2, wave * 0.2, 92 * scale, GOLD, "orb", extra)
		"eirin_device", "eirin_brain":
			for n in range(3 + rank):
				var point: Vector2 = dm._point(0.55 + 0.23 * cos(wave * 0.42 + n * TAU / (3 + rank)), 0.5 + 0.4 * sin(wave * 0.42 + n * TAU / (3 + rank)))
				dm._beam(c, point, dm._target(point), BLUE, 1.15, 6 * scale, {"damage": 56.0})
				dm._fan(c, point, 5, (dm._target(point) - point).angle(), 0.7, 112 * scale, GOLD, "rice", extra)
		"eirin_apollo":
			for n in range(3 + rank):
				var point: Vector2 = dm._point(0.16 + fposmod(wave * 0.19 + n * 0.23, 0.78), 0.02)
				dm._beam(c, point, point + Vector2(-g.CELL_SIZE.x * 0.6, g.board_size.y), RED, 1.25, 9 * scale, {"damage": 80.0})
				dm._fan(c, origin, 7, aim, 1.3, 148 * scale, GOLD, "rice", extra)
		"eirin_astronomical":
			for side in [-1, 1]:
				var point: Vector2 = dm._point(0.82, 0.5 + side * 0.43)
				dm._fan(c, point, 12 + rank * 2, PI + side * sin(wave * 0.4) * 0.4, 1.4, 125 * scale, BLUE if side < 0 else RED, "rice", extra)
		"eirin_hourai":
			extra["angular_speed"] = 0.2 if wave % 2 == 0 else -0.2
			dm._ring(c, dm._point(0.72, 0.5), 24 + rank * 3, wave * 0.22, 130 * scale, RED if wave % 2 == 0 else BLUE, "rice", extra)
			if wave % 2 == 0:
				dm._fan(c, origin, 9, aim, 1.1, 190 * scale, GOLD, "rice", extra)
		"pressure_medicine", "pressure_medicine_crossfire", "pressure_medicine_domain":
			for side in [-1, 1]:
				var point: Vector2 = dm._point(0.83, 0.5 + side * 0.28)
				dm._fan(c, point, 9 + rank, PI + sin(wave * 0.65) * 0.3, 1.2, 155 * scale, RED if side < 0 else BLUE, "rice", extra)
