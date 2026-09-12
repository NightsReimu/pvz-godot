extends RefCounted

# Identifying TH08 geometries, rotated for a horizontal lawn. Damage is handled
# only by the shared swept collisions; these emitters never damage cells directly.
const COLORS := [Color("ffc85a"), Color("7cd6ff"), Color("d59afa"), Color("ff879f"), Color("94ecba")]

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	var profile: Dictionary = game.TouhouDifficulty.profile(game.current_level)
	var rank := int(profile.rank)
	var density: float = game.TouhouDifficulty.attack_density(String(c.kind), game.current_level)
	var p := String(c.pattern)
	var origin := Vector2(c.center)
	var target: Vector2 = dm._target(origin)
	var aim := (target - origin).angle()
	var wave := int(c.wave)
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var scale := minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0)
	if p == "nonspell_marisa_stars":
		dm._fan(c, origin, 9 + rank * 2, aim, 1.25, 157 * scale, COLORS[wave % 5], "star", {"radius": 4.8 * scale, "damage": 17.0})
		return
	match p:
		"marisa_milky_way", "marisa_asteroid":
			var count := ceili((14 + rank * 3) * density)
			for i in range(count):
				var y := 0.06 + 0.88 * float(i) / maxf(1, count - 1)
				var angle := PI + sin(i * 0.6 + wave * 0.55) * 0.21
				var start := board.position + board.size * Vector2(0.98, y)
				dm._bullet(c, start, angle, (128 + (i % 3) * 13) * scale, COLORS[(i + wave) % 5], "star", {"radius": (5.5 if p == "marisa_milky_way" else 7.0) * scale, "damage": 18.0})
			if p == "marisa_asteroid":
				# Large irregular asteroids cross the smaller, ordered star belt.
				for i in range(3 + rank):
					var start := board.position + board.size * Vector2(0.92, 0.1 + fposmod(i * 0.31 + wave * 0.173, 0.8))
					dm._bullet(c, start, PI + sin(i * 2.1 + wave) * 0.38, 103 * scale, COLORS[(i + 2) % 5], "star", {"radius": 9.0 * scale, "damage": 23.0, "arming_time": 0.4})
		"marisa_stardust", "marisa_event_horizon":
			var count := ceili((19 + rank * 3) * density)
			for i in range(count):
				var angle := TAU * float(i) / count + wave * 0.24
				if p == "marisa_stardust":
					dm._bullet(c, origin, angle, 105 * scale, COLORS[(i + wave) % 5], "star", {"angular_speed": 0.17, "radius": 5.5 * scale, "damage": 17.0})
				else:
					# Two counter-rotating horizons release tangential star streams.
					var center := board.position + board.size * Vector2(0.65, 0.5)
					var orbit_radius := minf(board.size.y * 0.26, board.size.x * 0.18) * (1.0 if i % 2 == 0 else 0.68)
					dm._bullet(c, center + Vector2.from_angle(angle) * orbit_radius, angle + PI * 0.5, 130 * scale, COLORS[(i + wave) % 5], "star", {"radius": 5 * scale, "damage": 17.0, "orbit_center": center, "orbit_radius": orbit_radius, "orbit_angle": angle, "orbit_turn": 1.25 if i % 2 == 0 else -1.25, "orbit_until": 1.05, "arming_time": 1.1})
		"marisa_non_directional", "marisa_typhoon":
			var high := p == "marisa_typhoon"
			dm._ring(c, origin, 14 + rank * 3, -wave * 0.21, 104 * scale, COLORS[wave % 5], "star", {"radius": 4.5 * scale, "damage": 15.0, "angular_speed": -0.23 if high else 0.0})
			if wave % 3 == 0:
				var count := 8 if high else 6
				for arm in range(count):
					var angle := TAU * arm / count + wave * 0.13
					var end := origin + Vector2.from_angle(angle) * board.size.length()
					dm._beam(c, origin, end, COLORS[arm % 5], 1.0, (10 + rank) * scale, {"duration": 1.25 if high else 0.7, "damage": 44.0, "turn_rate": 0.23 if high else 0.08})
		"marisa_master_spark", "marisa_double_spark", "marisa_final_spark", "marisa_final_master":
			var last := p in ["marisa_final_spark", "marisa_final_master"]
			var double := p in ["marisa_double_spark", "marisa_final_master"]
			dm._fan(c, origin, 7 + rank * 2, aim + sin(wave) * 0.24, 1.9, 117 * scale, COLORS[wave % 5], "star", {"radius": 4.5 * scale, "damage": 14.0})
			if wave % 5 == 0:
				var direction := aim
				if last:
					var sweep_target := board.position + board.size * Vector2(0.12, 0.2 + 0.6 * float((wave / 5) % 3) / 2.0)
					direction = (sweep_target - origin).angle()
				for ray in range(2 if double else 1):
					var angle := direction + ((-0.15 if ray == 0 else 0.15) if double else 0.0)
					var end := origin + Vector2.from_angle(angle) * board.size.length()
					var width: float = game.CELL_SIZE.y * (0.60 if last else (0.40 if double else 0.54))
					dm._beam(c, origin, end, COLORS[0 if ray == 0 else 1], 1.2, width, {"duration": 1.25, "damage": 102.0 if last else 88.0, "spark": true, "turn_rate": (0.14 if wave % 10 == 0 else -0.14) if last else 0.0})
		"marisa_earthlight", "marisa_shoot_moon":
			# Searchlights originate at the lawn's far edge and converge upward,
			# the horizontal equivalent of TH08's ground-to-sky light columns.
			if wave % 3 == 0:
				var count := 3 + rank
				for i in range(count):
					var start := board.position + board.size * Vector2(0.12 + 0.73 * float(i) / maxf(1, count - 1), 0.99)
					var end := board.position + board.size * Vector2(0.2 + 0.6 * fposmod(i * 0.27 + wave * 0.09, 1), 0.01)
					dm._beam(c, start, end, COLORS[i % 3], 1.1, (10 + rank * 2) * scale, {"duration": 0.8, "damage": 48.0, "turn_rate": 0.10 if p == "marisa_shoot_moon" else 0.0})
				dm._ring(c, origin, 15 + rank * 3, wave * 0.17, 119 * scale, COLORS[0], "star", {"radius": 4.5 * scale, "damage": 16.0})

static func advance_bullet(b: Dictionary, before: Vector2, delta: float) -> Vector2:
	if b.has("orbit_until") and float(b.age) < float(b.orbit_until):
		b.orbit_angle += float(b.orbit_turn) * delta
		var direction := Vector2.from_angle(float(b.orbit_angle))
		b.position = Vector2(b.orbit_center) + direction * float(b.orbit_radius)
		b.velocity = direction.rotated(signf(float(b.orbit_turn)) * PI * 0.5) * Vector2(b.velocity).length()
	return before

static func advance_beam(beam: Dictionary, delta: float) -> void:
	if beam.has("turn_rate"):
		beam.to = Vector2(beam.from) + (Vector2(beam.to) - Vector2(beam.from)).rotated(float(beam.turn_rate) * delta)
