extends RefCounted

const COLORS = [Color("f783a6"), Color("8ddfed"), Color("f6d979"), Color("a8e7a1"), Color("c7a2ef")]

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var g: Control = dm.game
	var rank = int(g.TouhouDifficulty.profile(g.current_level).rank)
	var s = minf(g.CELL_SIZE.x / 100.0, g.CELL_SIZE.y / 110.0)
	var o = Vector2(c.center)
	var wave = int(c.wave)
	var aim: float = (dm._target(o) - o).angle()
	var p = String(c.pattern)
	var extra = {"damage": 22.0, "radius": 5 * s, "arming_time": 0.7}
	match p:
		"nonspell_kaguya_jewels":
			dm._fan(c, o, 7 + rank * 2, aim, 1.1, 160 * s, COLORS[wave % 5], "orb", extra)
		"kaguya_dragon":
			for n in range(5):
				var point = o + Vector2.from_angle(n * TAU / 5 + wave * 0.22) * 65 * s
				dm._fan(c, point, 4 + rank, aim + sin(wave * 0.35 + n) * 0.4, 0.62, (125 + n * 12) * s, COLORS[n], "orb", extra)
		"kaguya_bowl":
			for n in range(4):
				var point: Vector2 = dm._point(0.67, 0.15 + n * 0.23)
				dm._fan(c, point, 5 + rank, PI + sin(wave * 0.32 + n) * 0.4, 0.8, 125 * s, COLORS[3], "rice", extra)
		"kaguya_robe":
			extra["angular_speed"] = -0.24 if wave % 2 == 0 else 0.24
			dm._ring(c, o, 22 + rank * 3, wave * 0.22, 145 * s, COLORS[0] if wave % 2 else COLORS[2], "rice", extra)
		"kaguya_swallow":
			for side in [-1, 1]:
				var start: Vector2 = dm._point(0.9, 0.5 + side * 0.38)
				var end: Vector2 = dm._point(0.06, 0.5 - side * sin(wave * 0.4) * 0.35)
				dm._beam(c, start, end, COLORS[3], 1.3, 7 * s, {"damage": 66.0})
				dm._fan(c, start, 5 + rank, (end - start).angle(), 0.6, 160 * s, COLORS[2], "rice", extra)
		"kaguya_branch":
			for n in range(7):
				var point: Vector2 = dm._point(0.72 - (n % 2) * 0.12, (n + 0.5) / 7)
				dm._fan(c, point, 4 + rank, PI + sin(wave * 0.28 + n) * 0.5, 0.75, 132 * s, COLORS[n % 5], "orb", extra)
		_:
			if p.begins_with("kaguya_night_"):
				var night = int(p.get_slice("_", 2))
				var turn = wave * (0.23 if night % 2 else -0.23)
				var point: Vector2 = dm._point(0.72, 0.5 + sin(wave * 0.28) * 0.25)
				dm._ring(c, point, 20 + rank * 3 + night * 2, turn, (105 + night * 15) * s, COLORS[night], "rice", extra)
				if night >= 3:
					dm._fan(c, o, 7 + rank, aim, 1.05, 195 * s, COLORS[(night + 2) % 5], "orb", extra)
			elif p == "pressure_eternity":
				dm._ring(c, o, 18 + rank * 2, -wave * 0.26, 120 * s, COLORS[4], "rice", extra)

			elif p == "pressure_eternity_crossfire":
				for side in [-1, 1]:
					var point: Vector2 = dm._point(0.83, 0.5 + side * 0.42)
					var end: Vector2 = dm._point(0.18, 0.5 - side * 0.3)
					dm._beam(c, point, end, COLORS[2], 1.25, 7 * s, {"damage": 54.0})
					dm._fan(c, point, 6 + rank, (end-point).angle(), 0.65, 145 * s, COLORS[3], "orb", extra)
			elif p == "pressure_eternity_domain":
				for node in range(4):
					var point: Vector2 = dm._point(0.44 + 0.16 * (node % 2), 0.16 + node * 0.22)
					var eternity := extra.duplicate()
					eternity["angular_speed"] = 0.38 if node % 2 else -0.38
					dm._ring(c, point, 8 + rank, node * 0.4 + wave * 0.2, 95 * s, COLORS[node], "rice", eternity)
