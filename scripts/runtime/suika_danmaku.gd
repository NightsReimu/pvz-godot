extends RefCounted

const PURPLE := Color("d49aef")
const FIRE := Color("ef9276")
const GOLD := Color("f6c974")

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	var rt = game._ensure_suika_runtime()
	var owner := int(c.get("boss_uid", -1))
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var wave := int(c.wave)
	var origin := Vector2(c.center)
	var scale: float = minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))
	var row := int(game.active_rows[posmod(wave * 2 + int(c.stage), game.active_rows.size())])
	var col := 1 + posmod(wave * 3 + int(c.stage), game.COLS - 2)
	var warning := maxf(0.9, 1.4 - rank * 0.12)
	var cadence := 1.1
	match String(c.pattern):
		"nonspell_suika_density":
			dm._fan(c, origin, 5 + rank, PI + sin(wave * 0.6) * 0.20, 0.65, 150.0 * scale, GOLD, "orb", {"arming_time": 0.30})
			cadence = 0.92
		"suika_rocks":
			rt.queue_impact(owner, Vector2i(row, col), "rock", warning)
			if rank >= 2: rt.queue_impact(owner, Vector2i(int(game.active_rows[posmod(row + 2, game.active_rows.size())]), mini(game.COLS - 1, col + 1)), "rock", warning + 0.3)
			dm._fan(c, origin, 5, PI, 0.95, 132.0 * scale, GOLD, "suika_stone", {"arming_time": 0.45, "radius": 5.0 * scale})
			cadence = 1.4
		"suika_giant":
			rt.queue_impact(owner, Vector2i(row, col), "stomp", warning + 0.15)
			dm._fan(c, Vector2(origin.x, game._row_center_y(row) - 12), 5 + rank, PI, 0.85, 158.0 * scale, PURPLE, "suika_stone", {"arming_time": 0.4, "radius": 7.0 * scale})
			cadence = 1.55
		"suika_black_hole":
			var center: Vector2 = game._cell_center(row, game.COLS - 3) + Vector2(0, -12)
			for i in range(12 + rank * 3):
				var angle := TAU * i / (12 + rank * 3)
				dm._bullet(c, center + Vector2.from_angle(angle) * 90.0 * scale, PI + (i % 5 - 2) * 0.17 + wave * 0.05, 150.0 * scale, PURPLE, "orb", {"suika_orbit": center, "orbit_angle": angle, "orbit_radius": 90.0 * scale, "release_at": 1.3, "arming_time": 1.3, "radius": 5.0 * scale})
			cadence = 1.65
		"suika_dense_fire":
			var center: Vector2 = game._cell_center(row, game.COLS - 2) + Vector2(0, -12)
			dm._fan(c, center, 3 + rank, PI, 0.9, 104.0 * scale, FIRE, "suika_fire", {"split_at": 1.3, "arming_time": 0.45, "radius": 9.0 * scale, "suika_scale": scale})
			cadence = 1.35
		"suika_mist":
			rt.queue_impact(owner, Vector2i(row, game.COLS - 1), "mini", warning)
			dm._fan(c, origin, 5 + rank, PI + sin(wave) * 0.3, 1.05, 117.0 * scale, PURPLE, "orb", {"radius": 4.0 * scale, "arming_time": 0.6})
			cadence = 1.4
		"suika_million_oni":
			rt.queue_impact(owner, Vector2i(row, game.COLS - 1), "mini", warning)
			if wave % 2 == 1: rt.queue_impact(owner, Vector2i(int(game.active_rows[posmod(row + 2, game.active_rows.size())]), game.COLS - 1), "mini", warning + 0.25)
			dm._fan(c, Vector2(origin.x, game._row_center_y(row) - 12), 7 + rank * 2, PI + sin(wave * 0.8) * 0.2, 1.15, 148.0 * scale, PURPLE if wave % 2 else FIRE, "suika_fire", {"arming_time": 0.5, "radius": 5.0 * scale})
			cadence = 1.25
		"suika_wine", "suika_pea_knot":
			# Original board mechanics have room to read; a sparse fan keeps battle active.
			dm._fan(c, origin, 3, PI, 0.7, 126.0 * scale, GOLD, "orb", {"arming_time": 0.5, "radius": 4.5 * scale})
			cadence = 2.3
		"suika_chain_banquet":
			if wave > 0:
				dm._fan(c, origin, 5, PI + sin(wave) * 0.15, 1.2, 140.0 * scale, GOLD, "suika_stone", {"arming_time": 0.6})
			cadence = 1.75
		"suika_hundred_feasts":
			rt.queue_impact(owner, Vector2i(row, game.COLS - 1), "mini", warning + 0.2)
			dm._fan(c, origin, 7, PI, 1.4, 142.0 * scale, PURPLE, "orb", {"arming_time": 0.6})
			cadence = 1.5
	c.next_wave = float(c.age) + cadence * game.TouhouDifficulty.attack_cadence("suika_boss", game.current_level)

static func advance_bullet(dm: RefCounted, bullet: Dictionary, before: Vector2) -> Vector2:
	if bool(bullet.get("reflected", false)): return before
	if bullet.has("suika_orbit"):
		var release := float(bullet.release_at)
		if float(bullet.age) < release:
			var t := float(bullet.age) / release
			var radius := float(bullet.orbit_radius) * lerpf(1, 0.15, t)
			bullet.position = Vector2(bullet.suika_orbit) + Vector2.from_angle(float(bullet.orbit_angle) + float(bullet.age) * 3) * radius
			return Vector2(bullet.position)
		if not bool(bullet.get("suika_released", false)):
			bullet.suika_released = true
			# Do not sweep a held orbit across a row when releasing it.
			return Vector2(bullet.position)
	if float(bullet.get("split_at", 0.0)) > 0 and float(bullet.age) >= float(bullet.split_at) and not bool(bullet.get("split", false)):
		bullet.split = true
		var c := {"owner": int(bullet.owner), "kind": "suika_boss", "phase": 0, "wave": 0}
		var scale := float(bullet.get("suika_scale", 1.0))
		dm._fan(c, bullet.position, 5, PI, 1.6, 159.0 * scale, FIRE, "suika_fire", {"damage": 22.0, "radius": 4.5 * scale, "arming_time": 0.25})
		bullet.life = float(bullet.age)
	return before

static func draw_bullet(game: Control, b: Dictionary) -> void:
	var point := Vector2(b.position)
	var radius := float(b.radius)
	var color := Color(b.color)
	if float(b.age) < float(b.get("arming_time", 0)): color.a = 0.4
	if String(b.shape) == "suika_stone":
		var p := PackedVector2Array([point + Vector2(-radius, -radius * 0.3), point + Vector2(-radius * 0.4, -radius), point + Vector2(radius * 0.7, -radius * 0.7), point + Vector2(radius, radius * 0.4), point + Vector2(-radius * 0.4, radius)])
		game.draw_colored_polygon(p, Color("9a8aa6"))
		game.draw_line(point - Vector2(radius * 0.45, radius * 0.7), point + Vector2(radius * 0.4, radius * 0.3), color, 1.2, true)
	else:
		var tail := Vector2(b.velocity).normalized() * radius * -2.0
		var side := Vector2(b.velocity).normalized().orthogonal() * radius
		game.draw_colored_polygon(PackedVector2Array([point + tail, point + side, point - tail * 0.4, point - side]), Color(color, color.a * 0.45))
		game.draw_circle(point, radius, color)
		game.draw_circle(point + Vector2(-radius * 0.2, -radius * 0.2), radius * 0.4, Color(1, 0.93, 0.75, color.a))
