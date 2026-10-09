extends RefCounted
# TH10 stage 1 on six horizontal lanes. Shizuha's turret first aims exactly
# and then lags (the original's even-way rotation); Falling Frenzy rains
# fluttering leaves over the whole lawn. Minoriko's Autumn Sky crosses two
# streams, Maiden's Heart adds long/short rows with stray orbs, and the
# Harvester/Promise cards fire warned harvest lasers through lanes while rice
# falls between them (Lunatic adds approaching red column lasers).
const WindGodFX = preload("res://scripts/runtime/wind_god_fx.gd")
const RED := Color("eb6248")
const GOLD := Color("f3cc71")
const ORANGE := Color("f09a46")
const CRIMSON := Color("c8432f")
const AMBER := Color("ffb347")
const BROWN := Color("7a4a2a")

static func _x(scale: float, damage: float, radius: float = 4.6, more: Dictionary = {}) -> Dictionary:
	var extra := {"arming_time": 1.0, "radius": radius * scale, "damage": damage}
	extra.merge(more, true)
	return extra

static func _leaf(scale: float, damage: float, index: int, turn: float = 0.0) -> Dictionary:
	return _x(scale, damage, 5.0, {"angular_speed": turn, "sway_amp": 7.0 * scale, "sway_freq": 4.2 + posmod(index, 3) * 0.7, "sway_phase": index * 1.37})

static func _count(dm: RefCounted, c: Dictionary, base: int) -> int:
	return maxi(1, ceili(base * dm._attack_density_for_cast(c)))

static func _row(game: Control, index: int) -> int:
	return int(game.active_rows[posmod(index, game.active_rows.size())])

static func _rice_rain(dm: RefCounted, c: Dictionary, count: int, scale: float, damage: float, tint: Color) -> void:
	var game: Control = dm.game
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var wave := int(c.wave)
	for i in range(_count(dm, c, count)):
		var x := board.position.x + board.size.x * (0.12 + 0.86 * WindGodFX.noise(wave, 30 + i))
		dm._bullet(c, Vector2(x, board.position.y - game.CELL_SIZE.y * 0.3), PI * 0.58 + (WindGodFX.noise(wave, 50 + i) - 0.5) * 0.3, 70.0 * scale, tint, "aki_grain", _x(scale, damage, 4.2, {"arming_time": 1.0, "gravity": game.CELL_SIZE.y * 0.45}))

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	if game.active_rows.is_empty(): return
	var r := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var wave := int(c.wave)
	var origin := Vector2(c.center)
	var scale: float = minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var cell: Vector2 = game.CELL_SIZE
	var aim: float = (Vector2(dm._target(origin)) - origin).angle()
	var cadence := 1.4
	match String(c.pattern):
		"nonspell_aki_leaves":
			# The turret aims exactly once, then turns at a limited rate.
			var turret: float = aim if wave == 0 else float(c.get("aki_turret", aim))
			turret += clampf(angle_difference(turret, aim), -0.16, 0.16)
			c["aki_turret"] = turret
			dm._fan(c, origin, 1 if wave == 0 else 2, turret, 0.2, 136.0 * scale, CRIMSON, "aki_leaf", _x(scale, 24.0, 4.8))
			for arm in range(2):
				var base := PI + sin(wave * 0.5 + arm * PI) * 0.45
				dm._fan(c, origin, 2, base, 0.3, 104.0 * scale, ORANGE if arm else GOLD, "aki_leaf", _leaf(scale, 24.0, wave + arm, 0.12 * (arm * 2 - 1)))
			cadence = 1.7
		"aki_falling_leaves":
			# 狂乱的落叶: leaves rain over the whole lawn in a frenzy.
			for i in range(_count(dm, c, 3 + r - 2)):
				var x := board.position.x + board.size.x * (0.15 + 0.85 * WindGodFX.noise(wave, i))
				var tint: Color = [RED, ORANGE, GOLD][posmod(wave + i, 3)]
				var extra := _leaf(scale, 29.0, wave * 7 + i)
				extra.merge({"arming_time": 1.0, "gravity": cell.y * 0.18}, true)
				dm._bullet(c, Vector2(x, board.position.y - cell.y * 0.3), PI * 0.62 + (WindGodFX.noise(wave, 20 + i) - 0.5) * 0.5, (52.0 + 30.0 * WindGodFX.noise(wave, 40 + i)) * scale, tint, "aki_leaf", extra)
			dm._fan(c, origin, 5, PI + sin(wave * 0.8) * 0.3, 1.3, 104.0 * scale, RED if wave % 2 else ORANGE, "aki_leaf", _leaf(scale, 29.0, wave, 0.18 * (-1 if wave % 2 else 1)))
			cadence = 1.4
		"nonspell_aki_grain":
			dm._fan(c, origin, 3, aim, 0.26, 146.0 * scale, GOLD, "aki_grain", _x(scale, 26.0, 4.2))
			dm._fan(c, origin, 3, PI + sin(wave * 0.55) * 0.2, 0.9, 116.0 * scale, ORANGE, "aki_grain", _x(scale, 26.0, 4.2))
			if r >= 2 and wave % 2 == 1:
				# Hard/Lunatic second nonspell: fast shots from the upper right.
				var corner := Vector2(board.end.x, board.position.y)
				dm._fan(c, corner, 1, (Vector2(dm._target(corner)) - corner).angle(), 0.2, 190.0 * scale, AMBER, "aki_grain", _x(scale, 26.0, 4.0, {"arming_time": 1.0}))
			cadence = 1.7
		"aki_autumn_sky":
			# Two streams sweep in opposite senses and keep crossing.
			for side in [-1, 1]:
				var source: Vector2 = origin + Vector2(-cell.x * 0.15, side * cell.y * 0.55)
				var angle: float = PI - side * 0.25 + side * 0.55 * sin(wave * 0.38)
				dm._fan(c, source, 3, angle, 0.14, 124.0 * scale, RED if side < 0 else GOLD, "aki_leaf", _leaf(scale, 30.0, wave + side))
			cadence = 1.25
		"aki_maidens_heart":
			for side in [-1, 1]:
				var source: Vector2 = origin + Vector2(-cell.x * 0.15, side * cell.y * 0.55)
				var angle: float = PI - side * 0.25 + side * 0.6 * sin(wave * 0.42)
				dm._fan(c, source, 3, angle, 0.12, 132.0 * scale, RED if side < 0 else GOLD, "aki_grain", _x(scale, 30.0, 4.2))
			# Odd waves: a long aimed rice row with a stray orb; even: a short row.
			var length := 6 if wave % 2 == 0 else 3
			for k in range(_count(dm, c, length)):
				dm._bullet(c, origin, aim, (112.0 + k * 13.0) * scale, AMBER, "aki_grain", _x(scale, 31.0, 4.0))
			if wave % 2 == 0:
				dm._bullet(c, origin, aim + (WindGodFX.noise(wave, 3) - 0.5) * 0.3, 98.0 * scale, CRIMSON, "aki_persimmon", _x(scale, 34.0, 6.4))
			cadence = 1.15
		"aki_otoshi_harvester", "aki_grain_promise":
			var promise := String(c.pattern) == "aki_grain_promise"
			# Warned harvest lasers cut whole lanes; their rows are drawn by lot.
			var lanes := (1 if r == 0 else 2) if not promise else (2 if r == 2 else 3)
			var used := {}
			for i in range(lanes):
				var row := _row(game, int(WindGodFX.noise(wave, 60 + i) * 6.0) + i * 2)
				if used.has(row): continue
				used[row] = true
				WindGodFX.lane_beam(dm, c, row, origin.x - cell.x * 0.25, "harvest", 1.35 if not promise else 1.15, maxf(3.0, cell.y * 0.2), 22.0, 0.5)
			if promise and r >= 3:
				# Lunatic: red column lasers step in towards the house.
				var col: int = game.COLS - 2 - posmod(wave, game.COLS - 2)
				var x: float = board.position.x + cell.x * (col + 0.5)
				dm._beam(c, Vector2(x, board.position.y - 2.0), Vector2(x, board.end.y + 2.0), WindGodFX.BEAM_STYLES.crimson[0], 1.1, maxf(3.0, cell.x * 0.16), {"damage": 20.0, "duration": 0.45, "wg_style": "crimson"})
			_rice_rain(dm, c, 2 if not promise else 5, scale, 28.0, GOLD)
			dm._fan(c, origin, 5 if not promise else 7, aim, 0.6, 132.0 * scale, ORANGE, "aki_grain", _x(scale, 30.0, 4.2))
			if wave % 3 == 2: dm._fan(c, origin, 3, PI, 0.7, 88.0 * scale, ORANGE, "aki_potato", _x(scale, 40.0, 7.0, {"arming_time": 1.2}))
			cadence = 1.7 if not promise else 1.3
		"aki_ripening", "aki_offering":
			if bool(c.get("autumn_full", false)):
				# Three staggered furrows alternate parity each wave. The small
				# grain fans leave the marked harvest squares readable.
				_field_grains(dm, c, origin, scale)
			else:
				dm._fan(c, origin, 3, PI + sin(wave) * 0.16, 0.8, 114.0 * scale, GOLD, "aki_grain", _x(scale, 24.0, 4.0))
			cadence = 2.3
		"aki_six_furrows":
			dm._fan(c, origin, 5, PI + sin(wave * 0.7) * 0.15, 1.20, 115.0 * scale, RED, "aki_leaf", _leaf(scale, 27.0, wave, 0.08))
			cadence = 1.85
		"aki_feast":
			dm._fan(c, origin, 5 + r, PI + sin(wave * 0.8) * 0.24, 1.38, 123.0 * scale, RED if wave % 2 else GOLD, "aki_leaf" if wave % 2 else "aki_grain", _leaf(scale, 30.0, wave) if wave % 2 else _x(scale, 30.0, 4.6, {"arming_time": 1.1}))
			if wave % 3 == 0: dm._fan(c, origin, 3, PI, 0.9, 92.0 * scale, CRIMSON, "aki_persimmon", _x(scale, 32.0, 6.2, {"arming_time": 1.1}))
			cadence = 1.9
	c.next_wave = float(c.age) + cadence * game.TouhouDifficulty.attack_cadence(String(c.kind), game.current_level)

static func _field_grains(dm: RefCounted, c: Dictionary, origin: Vector2, scale: float) -> void:
	var game: Control = dm.game
	var counts := [3, 2, 1]
	for branch in range(3):
		var row := int(game.active_rows[posmod(int(c.stage) + int(c.wave) + branch * 2, game.active_rows.size())])
		var stalk := Vector2(origin.x, game._row_center_y(row) - 12.0)
		dm._fan(c, stalk, counts[branch], PI + sin(int(c.wave) * 0.65 + branch) * 0.05, 0.34, 114.0 * scale, GOLD if branch % 2 == 0 else ORANGE, "aki_grain", {"arming_time": 1.0, "radius": 4.0 * scale, "damage": 24.0})

static func draw_leaf(game: CanvasItem, center: Vector2, radius: float, angle: float, color: Color) -> void:
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
	if WindGodFX.crowded(game):
		game.draw_circle(point, radius * 1.1, Color(WindGodFX.INK, tint.a * 0.6))
		game.draw_circle(point, radius * 0.85, tint)
		return
	match String(b.shape):
		"aki_leaf":
			# A two-tone maple leaf that tumbles as it flutters.
			var spin := angle + sin(float(b.age) * 4.0 + float(b.get("sway_phase", 0.0))) * 0.6
			draw_leaf(game, point, radius * 2.25, spin, Color(WindGodFX.INK, tint.a * 0.75))
			draw_leaf(game, point, radius * 1.95, spin, tint)
			draw_leaf(game, point, radius * 0.95, spin, Color(tint.lightened(0.45), tint.a * 0.8))
		"aki_potato":
			var outline := PackedVector2Array()
			for i in range(12): outline.append(point + Vector2(cos(TAU * i / 12.0) * radius * 1.35, sin(TAU * i / 12.0) * radius * 0.85).rotated(angle))
			game.draw_colored_polygon(outline, Color("9a4a7a", tint.a))
			game.draw_colored_polygon(outline, Color(tint, tint.a * 0.35))
			game.draw_line(point - Vector2.from_angle(angle) * radius * 0.7, point + Vector2.from_angle(angle) * radius * 0.7, Color(0.95, 0.75, 0.45, tint.a), maxf(1.0, radius * 0.14), true)
		"aki_persimmon":
			WindGodFX.halo(game, point, radius, tint, 0.8)
			game.draw_circle(point, radius + 1.4, Color(WindGodFX.INK, tint.a * 0.75))
			game.draw_circle(point, radius, Color("f07a2c", tint.a))
			game.draw_circle(point + Vector2(-radius * 0.3, -radius * 0.25), radius * 0.32, Color(1, 0.9, 0.7, tint.a * 0.8))
			for k in range(4):
				var a := TAU * k / 4.0 + float(b.age)
				game.draw_line(point - Vector2(0, radius * 0.75), point - Vector2(0, radius * 0.75) + Vector2.from_angle(a) * radius * 0.45, Color("4f7a3a", tint.a), maxf(1.0, radius * 0.18), true)
		_:
			var long_axis := Vector2.from_angle(angle) * radius * 2.15
			var side := long_axis.orthogonal().normalized() * radius * 0.8
			game.draw_colored_polygon(PackedVector2Array([point - long_axis * 1.12, point - side * 1.3, point + long_axis * 1.12, point + side * 1.3]), Color(WindGodFX.INK, tint.a * 0.8))
			game.draw_colored_polygon(PackedVector2Array([point - long_axis, point - side, point + long_axis, point + side]), tint)
			game.draw_line(point - long_axis * 0.6, point + long_axis * 0.55, Color(1, 0.98, 0.82, tint.a), maxf(0.8, radius * 0.24), true)
	WindGodFX.morph_flash(game, b, point, radius)

static func draw_cast(game: Control, c: Dictionary) -> void:
	var pattern := String(c.pattern)
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var origin := Vector2(c.center)
	var age := float(c.age)
	if pattern in ["aki_otoshi_harvester", "aki_grain_promise"]:
		# A golden sheaf blazes above Minoriko while the harvest lasers charge.
		var top := origin + Vector2(-unit * 0.2, -unit * 0.95)
		game.draw_circle(top, unit * (0.3 + 0.04 * sin(age * 5.0)), Color(GOLD, 0.18))
		for k in range(7):
			var a := -PI * 0.5 + (k - 3) * 0.18 + sin(age * 2.0 + k) * 0.04
			var tip := top + Vector2.from_angle(a) * unit * 0.42
			game.draw_line(top + Vector2(0, unit * 0.25), tip, Color(GOLD, 0.85), maxf(1.0, unit * 0.025), true)
			WindGodFX.glyph(game, tip, unit * 0.06, "grain", a + PI * 0.5, Color(AMBER, 0.9))
	elif pattern in ["aki_autumn_sky", "aki_maidens_heart"]:
		for side in [-1, 1]:
			var source: Vector2 = origin + Vector2(-game.CELL_SIZE.x * 0.15, side * game.CELL_SIZE.y * 0.55)
			game.draw_circle(source, unit * 0.12, Color(RED if side < 0 else GOLD, 0.3))
			draw_leaf(game, source, unit * 0.09, age * 3.0 * side, Color(RED if side < 0 else GOLD, 0.9))
	elif pattern == "aki_falling_leaves":
		for k in range(8):
			var a := age * 1.6 + TAU * k / 8.0
			draw_leaf(game, origin + Vector2(cos(a) * unit * 0.55, -unit * 0.4 + sin(a) * unit * 0.22), unit * 0.07, a, Color([RED, ORANGE, GOLD][k % 3], 0.8))
