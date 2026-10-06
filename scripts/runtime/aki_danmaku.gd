extends RefCounted

const RED := Color("eb6248")
const GOLD := Color("f3cc71")
const ORANGE := Color("f09a46")

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	if game.active_rows.is_empty(): return
	var r := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var wave := int(c.wave)
	var origin := Vector2(c.center)
	var scale: float = minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))
	var row := int(game.active_rows[posmod(wave * 2 + int(c.stage), game.active_rows.size())])
	var cadence := 1.3
	match String(c.pattern):
		"nonspell_aki_leaves":
			dm._fan(c, origin, 5, PI + sin(wave * 0.65) * 0.20, 0.72, 120.0 * scale, RED, "aki_leaf", {"arming_time": 1.0, "radius": 5.0 * scale, "angular_speed": 0.07 * (-1 if wave % 2 else 1), "damage": 24.0})
			cadence = 1.8
		"nonspell_aki_grain":
			dm._fan(c, origin, 5, PI + sin(wave * 0.55) * 0.18, 0.88, 132.0 * scale, GOLD, "aki_grain", {"arming_time": 1.0, "radius": 4.2 * scale, "damage": 26.0})
			cadence = 1.75
		"aki_falling_leaves":
			# Loose alternating curls retain the slow, drifting leaf character.
			dm._fan(c, origin, 9, PI + sin(wave * 0.8) * 0.26, 1.48, 106.0 * scale, RED if wave % 2 else ORANGE, "aki_leaf", {"arming_time": 1.0, "angular_speed": 0.18 * (-1 if wave % 2 else 1), "radius": 6.0 * scale, "damage": 31.0})
			if wave % 2 == 1:
				var branch := origin + Vector2(-game.CELL_SIZE.x * 0.30, game.CELL_SIZE.y * 0.48)
				dm._fan(c, branch, 5, PI - 0.3, 0.85, 91.0 * scale, GOLD, "aki_leaf", {"arming_time": 1.15, "angular_speed": -0.14, "radius": 4.0 * scale, "damage": 25.0})
			cadence = 1.45
		"aki_autumn_sky":
			var sweep := PI + sin(wave * 0.70) * 0.38
			dm._fan(c, origin, 7, sweep, 1.25, 131.0 * scale, RED, "aki_leaf", {"arming_time": 1.0, "radius": 5.0 * scale, "angular_speed": 0.045, "damage": 30.0})
			if wave % 2 == 1: dm._fan(c, origin + Vector2(0, -game.CELL_SIZE.y * 0.3), 3, PI - 0.18, 0.55, 100.0 * scale, GOLD, "aki_grain", {"arming_time": 1.0, "radius": 4.0 * scale, "damage": 24.0})
			cadence = 1.45
		"aki_maidens_heart":
			for branch in range(2):
				var point := origin + Vector2(0, (branch * 2 - 1) * game.CELL_SIZE.y * 0.28)
				dm._fan(c, point, 7, PI + sin(wave * 0.75 + branch * PI) * 0.3, 1.32, 124.0 * scale, RED if branch == 0 else GOLD, "aki_leaf", {"arming_time": 1.0, "radius": 4.8 * scale, "angular_speed": 0.12 * (branch * 2 - 1), "damage": 31.0})
			cadence = 1.35
		"aki_otoshi_harvester":
			var stalk := Vector2(origin.x, game._row_center_y(row) - 12.0)
			dm._fan(c, stalk, 7, PI + sin(wave * 0.6) * 0.16, 1.15, 136.0 * scale, GOLD, "aki_grain", {"arming_time": 1.0, "radius": 4.4 * scale, "damage": 31.0})
			if wave % 3 == 0: dm._fan(c, stalk, 3, PI, 0.7, 87.0 * scale, ORANGE, "aki_potato", {"arming_time": 1.2, "radius": 7.0 * scale, "damage": 43.0})
			cadence = 1.4
		"aki_grain_promise":
			for branch in range(2):
				var lane := int(game.active_rows[posmod(wave + branch * 3, game.active_rows.size())])
				var stalk := Vector2(origin.x, game._row_center_y(lane) - 12.0)
				dm._fan(c, stalk, 7, PI + (branch * 2 - 1) * 0.16, 0.98, 143.0 * scale, GOLD if branch == 0 else ORANGE, "aki_grain", {"arming_time": 1.0, "radius": 4.5 * scale, "angular_speed": 0.08 * (branch * 2 - 1), "damage": 34.0})
			if wave % 3 == 1: dm._fan(c, origin, 5, PI, 1.5, 91.0 * scale, RED, "aki_leaf", {"arming_time": 1.2, "radius": 5.5 * scale, "damage": 27.0})
			cadence = 1.35
		"aki_ripening", "aki_offering":
			if bool(c.get("autumn_full", false)):
				# Three staggered furrows alternate parity each wave. The small
				# grain fans leave the marked harvest squares readable.
				_field_grains(dm, c, origin, scale)
			else:
				dm._fan(c, origin, 3, PI + sin(wave) * 0.16, 0.8, 114.0 * scale, GOLD, "aki_grain", {"arming_time": 1.0, "radius": 4.0 * scale, "damage": 24.0})
			cadence = 2.3
		"aki_six_furrows":
			dm._fan(c, origin, 5, PI + sin(wave * 0.7) * 0.15, 1.20, 115.0 * scale, RED, "aki_leaf", {"arming_time": 1.1, "radius": 4.6 * scale, "angular_speed": 0.08, "damage": 27.0})
			cadence = 1.85
		"aki_feast":
			dm._fan(c, origin, 5 + r, PI + sin(wave * 0.8) * 0.24, 1.38, 123.0 * scale, RED if wave % 2 else GOLD, "aki_leaf" if wave % 2 else "aki_grain", {"arming_time": 1.1, "radius": 4.6 * scale, "damage": 30.0})
			cadence = 1.9
	c.next_wave = float(c.age) + cadence * game.TouhouDifficulty.attack_cadence(String(c.kind), game.current_level)

static func _field_grains(dm: RefCounted, c: Dictionary, origin: Vector2, scale: float) -> void:
	var game: Control = dm.game
	var counts := [3, 2, 1]
	for branch in range(3):
		var row := int(game.active_rows[posmod(int(c.stage) + int(c.wave) + branch * 2, game.active_rows.size())])
		var stalk := Vector2(origin.x, game._row_center_y(row) - 12.0)
		dm._fan(c, stalk, counts[branch], PI + sin(int(c.wave) * 0.65 + branch) * 0.05, 0.34, 114.0 * scale, GOLD if branch % 2 == 0 else ORANGE, "aki_grain", {"arming_time": 1.0, "radius": 4.0 * scale, "damage": 24.0})

static func draw_leaf(game: Control, center: Vector2, radius: float, angle: float, color: Color) -> void:
	var outline := PackedVector2Array()
	for point in [Vector2(0, -1.0), Vector2(0.24, -0.40), Vector2(0.80, -0.72), Vector2(0.57, -0.18), Vector2(1.0, 0.18), Vector2(0.38, 0.35), Vector2(0.22, 0.88), Vector2(0, 0.58), Vector2(-0.22, 0.88), Vector2(-0.38, 0.35), Vector2(-1.0, 0.18), Vector2(-0.57, -0.18), Vector2(-0.80, -0.72), Vector2(-0.24, -0.40)]:
		outline.append(center + Vector2(point).rotated(angle) * radius)
	game.draw_colored_polygon(outline, color)
	game.draw_line(center + Vector2(0, -radius * 0.78).rotated(angle), center + Vector2(0, radius * 1.1).rotated(angle), Color(1.0, 0.78, 0.44, color.a * 0.85), maxf(0.8, radius * 0.12), true)

static func draw_bullet(game: Control, b: Dictionary) -> void:
	var point := Vector2(b.position)
	var radius := float(b.radius)
	var tint := Color(b.color)
	if float(b.age) < float(b.get("arming_time", 0.0)): tint.a *= 0.45
	var angle := Vector2(b.velocity).angle() + PI * 0.5
	if String(b.shape) == "aki_leaf":
		draw_leaf(game, point, radius * 1.55, angle + sin(float(b.age) * 4.0) * 0.25, tint)
	elif String(b.shape) == "aki_potato":
		var outline := PackedVector2Array()
		for i in range(12): outline.append(point + Vector2(cos(TAU * i / 12.0) * radius * 1.35, sin(TAU * i / 12.0) * radius * 0.85).rotated(angle))
		game.draw_colored_polygon(outline, tint)
		game.draw_line(point - Vector2.from_angle(angle) * radius * 0.7, point + Vector2.from_angle(angle) * radius * 0.7, Color(0.75, 0.28, 0.17, tint.a), maxf(1.0, radius * 0.14), true)
	else:
		var long_axis := Vector2.from_angle(angle) * radius * 1.65
		var side := long_axis.orthogonal().normalized() * radius * 0.64
		game.draw_colored_polygon(PackedVector2Array([point - long_axis, point - side, point + long_axis, point + side]), tint)
		game.draw_line(point - long_axis * 0.6, point + long_axis * 0.55, Color(1, 0.96, 0.73, tint.a), maxf(0.8, radius * 0.22), true)
