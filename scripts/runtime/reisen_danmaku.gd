extends RefCounted

const RED := Color("fa567f")
const BLUE := Color("8ce4f0")
const VIOLET := Color("b399ff")

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var scale := minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0)
	var origin := Vector2(c.center)
	var aim: float = (dm._target(origin) - origin).angle()
	var wave := int(c.wave)
	var p := String(c.pattern)
	var extra := {"damage": 19.0, "radius": 4.8 * scale, "arming_time": 0.65}
	if p == "nonspell_tewi_rings":
		# Tewi's unnamed ring/fan attack, with the spread alternating each volley.
		if wave % 2 == 0:
			dm._ring(c, origin, 15 + rank * 2, wave * 0.23, 102 * scale, Color("f9bacf"), "orb", {"damage": 12.0, "radius": 4 * scale})
		else:
			dm._fan(c, origin, 9, aim, 1.6, 120 * scale, BLUE, "rice", {"damage": 12.0, "radius": 4 * scale})
		return
	if p == "nonspell_reisen_fan":
		dm._fan(c, origin, 9 + rank * 2, aim, 1.15, 132 * scale, RED, "rice", extra)
		return
	extra["reisen_cycle"] = 2.6
	extra["reisen_offset"] = wave * 0.13
	match p:
		"reisen_mind_shaker", "reisen_mind_blowing":
			extra["reisen_illusion"] = "shift"
			dm._ring(c, origin, 18 + rank * 3, wave * 0.21, 120 * scale, RED, "rice", extra)
			if p == "reisen_mind_blowing":
				dm._fan(c, origin + Vector2(0, 40 * sin(wave) * scale), 7, aim, 1.1, 154 * scale, BLUE, "rice", extra)
		"reisen_visionary_tuning", "reisen_illusion_seeker":
			extra["reisen_illusion"] = "tune"
			extra.reisen_cycle = 2.0
			for side in [-1, 1]:
				var point := origin + Vector2(-15, side * (34 + wave * 4)) * scale
				dm._fan(c, point, 8 + rank * 2, aim + side * 0.18, 1.6, 125 * scale, BLUE if side < 0 else RED, "rice", extra)
		"reisen_idling_wave", "reisen_mind_stopper":
			extra["reisen_illusion"] = "idle"
			extra["freeze_at"] = 0.7
			extra["thaw_at"] = 1.8
			extra["thaw_angle"] = 0.16 if p == "reisen_mind_stopper" else 0.0
			dm._ring(c, origin, 22 + rank * 3, wave * 0.16, 140 * scale, VIOLET, "rice", extra)
		"reisen_invisible_moon":
			extra["reisen_illusion"] = "invisible"
			extra.reisen_cycle = 2.35
			var point: Vector2 = dm._point(0.76, 0.5 + sin(wave * 0.8) * 0.3)
			dm._ring(c, point, 24 + rank * 3, -wave * 0.19, 110 * scale, RED, "rice", extra)
		"reisen_tele_mesmerism":
			extra["reisen_illusion"] = "tune"
			# Remote moon emitters echo the Last Spell's external reinforcements.
			for side in [-1, 1]:
				var point: Vector2 = dm._point(0.64 + sin(wave * 0.47) * 0.15, 0.5 + side * 0.42)
				dm._fan(c, point, 9 + rank * 2, (dm._target(point) - point).angle(), 1.5, 118 * scale, RED if side < 0 else BLUE, "rice", extra)
		"pressure_lunar":
			extra["reisen_illusion"] = "shift"
			dm._fan(c, origin, 13 + rank * 2, aim, 1.6, 130 * scale, RED, "rice", extra)
		"pressure_lunar_crossfire":
			extra["reisen_illusion"] = "invisible"
			for side in [-1, 1]:
				dm._fan(c, dm._point(0.88, 0.5 + side * 0.3), 11, PI + side * 0.3, 1.1, 128 * scale, VIOLET, "rice", extra)
		"pressure_lunar_domain":
			extra["life"] = 12.0
			extra["reisen_illusion"] = "tune"
			extra["reisen_return_x"] = game.BOARD_ORIGIN.x + game.board_size.x * 0.2
			extra["reisen_return_exit"] = game.BOARD_ORIGIN.x + game.board_size.x * 0.84
			extra["reisen_mirror_y"] = game.BOARD_ORIGIN.y * 2 + game.board_size.y
			dm._fan(c, origin, 13 + rank, PI + sin(wave) * 0.3, 1.75, 132 * scale, RED, "rice", extra)

static func advance_bullet(b: Dictionary, before: Vector2) -> Vector2:
	if not b.has("reisen_illusion"):
		return before
	var phase := fposmod(float(b.age) + float(b.get("reisen_offset", 0)), float(b.reisen_cycle))
	var phantom := phase > 0.65 and phase < 1.45
	if String(b.reisen_illusion) == "idle":
		phantom = float(b.age) >= 0.7 and float(b.age) < 1.8
	if bool(b.get("reisen_phantom", false)) and not phantom:
		b["arming_time"] = maxf(float(b.get("arming_time", 0)), float(b.age) + 0.4)
	b["reisen_phantom"] = phantom
	if b.has("reisen_return_x") and not bool(b.get("reisen_returned", false)) and Vector2(b.position).x <= float(b.reisen_return_x):
		b.position = Vector2(float(b.reisen_return_exit), float(b.reisen_mirror_y) - Vector2(b.position).y)
		b.velocity.y *= -1.0
		b["reisen_returned"] = true
		b["arming_time"] = float(b.age) + 0.85
		return Vector2(b.position) # Never sweep collisions across a portal jump.
	return before
