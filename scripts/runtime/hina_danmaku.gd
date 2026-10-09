extends RefCounted
# TH10 stage 2 on six lanes. Bad Fortune spins a cursed ring and Biorhythm
# pulses its bullets' speed; Broken/Damaged Amulet throws angle-hashed clumps
# from the upper and lower right that cross the lanes (damaged amulets crack
# into rice); the Wheel of Misfortune / Ooganebaba's Fire are real winders
# (needles on E/N, fire on H/L); Pain Flow's neat rings loosen over time and
# the Exiled Doll adds homing "virus" shots as the card goes on.
const WindGodFX = preload("res://scripts/runtime/wind_god_fx.gd")
const GREEN := Color("95e6b5")
const DARK_GREEN := Color("54b891")
const RED := Color("ec7391")
const CRIMSON := Color("d9465f")
const GOLD := Color("f0d090")
const VIOLET := Color("b58ae6")

static func _x(scale: float, damage: float, radius: float = 4.5, more: Dictionary = {}) -> Dictionary:
	var extra := {"arming_time": 1.05, "radius": radius * scale, "damage": damage}
	extra.merge(more, true)
	return extra

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	if game.active_rows.is_empty(): return
	var wave := int(c.wave)
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var origin := Vector2(c.center)
	var scale: float = minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var aim: float = (Vector2(dm._target(origin)) - origin).angle()
	var turn := wave * 0.37
	var cadence := 1.4
	match String(c.pattern):
		"nonspell_hina_spiral":
			for arm in range(3):
				dm._fan(c, origin, 1, PI + (arm - 1) * 0.4 + sin(turn + arm) * 0.25, 0.0, 116.0 * scale, GREEN if arm % 2 else DARK_GREEN, "hina_ofuda", _x(scale, 25.0, 4.5, {"angular_speed": 0.14 * (-1 if wave % 2 else 1)}))
			dm._fan(c, origin, 3, aim, 0.24, 140.0 * scale, GOLD, "hina_rice", _x(scale, 24.0, 3.8))
			cadence = 1.6
		"hina_bad_fortune":
			# Hina's spin flings a cursed ring whose arms curl alternately.
			var count := ceili(16 * dm._attack_density_for_cast(c))
			for i in range(count):
				dm._bullet(c, origin, turn + TAU * i / count, 102.0 * scale, GREEN if i % 2 else DARK_GREEN, "hina_ofuda", _x(scale, 25.0, 4.3, {"angular_speed": 0.16 if i % 2 else -0.16}))
			dm._fan(c, origin, 3, aim, 0.3, 132.0 * scale, GOLD, "hina_rice", _x(scale, 24.0, 3.8))
			cadence = 1.3
		"hina_biorhythm":
			# Two counter-turning spirals whose speed rises and falls together.
			for direction in [-1, 1]:
				var count := ceili(14 * dm._attack_density_for_cast(c))
				for i in range(count):
					dm._bullet(c, origin, direction * turn + TAU * i / count, 112.0 * scale, GREEN if direction > 0 else RED, "hina_ofuda", _x(scale, 29.0, 4.5, {"angular_speed": direction * 0.12, "speed_wave": 0.55, "speed_freq": 3.2, "speed_phase": wave * 0.6}))
			cadence = 0.9
		"hina_broken_amulet", "hina_damaged_amulet":
			var damaged := String(c.pattern) == "hina_damaged_amulet"
			# Clumps at hashed angles enter from the upper and lower right corners.
			for side in [-1, 1]:
				var corner := Vector2(board.end.x + game.CELL_SIZE.x * 0.2, board.position.y if side < 0 else board.end.y)
				var angle: float = PI + side * (0.62 + (WindGodFX.noise(wave, side + 3) - 0.5) * 0.36)
				var clump := ceili((6 if damaged else 4) * dm._attack_density_for_cast(c))
				for k in range(clump):
					var extra := _x(scale, 31.0 if damaged else 29.0, 4.5, {"arming_time": 1.0})
					if damaged: extra.merge({"morph_at": 1.15 + k * 0.03, "morph_shape": "hina_rice", "morph_speed": 1.2, "morph_turn": (WindGodFX.noise(wave * 9 + k, side) - 0.5) * 0.5, "morph_color": RED}, true)
					dm._bullet(c, corner, angle + (k % 3 - 1) * 0.07, (108.0 + k * 9.0) * scale, GREEN if side < 0 else (RED if damaged else DARK_GREEN), "hina_ofuda", extra)
			cadence = 1.7 if not damaged else 1.45
		"hina_misfortune_wheel", "hina_bell_fire":
			var fire := String(c.pattern) == "hina_bell_fire"
			# Spokes of a slowly rocking wheel, each a winding bullet line.
			var spokes: int = [2, 3, 3, 4][rank]
			var shape := "hina_fire" if fire else "hina_needle"
			for i in range(spokes):
				var base: float = PI + (i - (spokes - 1) * 0.5) * 0.46 + sin(wave * 0.3) * 0.18
				WindGodFX.winder(dm, c, origin, 4 if fire else 3, base, 0.26, wave * 0.9 + i * 1.7, (90.0 if fire else 98.0) * scale, 9.0 * scale, (GREEN if i % 2 else RED) if fire else (GREEN if i % 2 else DARK_GREEN), shape, _x(scale, 33.0 if fire else 29.0, 4.4 if fire else 3.4))
			cadence = 2.0 if rank > 0 else 1.55
		"hina_pain_flow":
			_pain_ring(dm, c, origin, scale, false)
			cadence = 1.65
		"hina_exiled_doll":
			_pain_ring(dm, c, origin, scale, true)
			# Virus shots grow in number as the card runs; each bends once onto
			# the nearest plant, like the original's late homing penalty.
			var progress := clampf(float(c.age) / maxf(1.0, float(c.duration)), 0.0, 1.0)
			if progress >= 0.3:
				for i in range(1 + int(progress * (3.0 if rank < 3 else 1.5))):
					var start := origin + Vector2(0, (i - 1) * game.CELL_SIZE.y * 0.45)
					dm._fan(c, start, 1, PI + (WindGodFX.noise(wave, i) - 0.5) * 1.2, 0.0, 120.0 * scale, VIOLET, "hina_virus", _x(scale, 22.0, 3.4, {"redirect_at": 0.9, "aim_point": dm._target(start)}))
			cadence = 1.65
		"hina_delayed", "hina_doll_offering", "hina_misfire":
			if bool(c.get("autumn_full", false)):
				_field_ofuda(dm, c, origin, scale)
			else:
				dm._fan(c, origin, 3, PI + sin(turn) * 0.18, 0.8, 113.0 * scale, GREEN, "hina_ofuda", _x(scale, 24.0, 4.0, {"arming_time": 1.2, "angular_speed": 0.08}))
			cadence = 2.2
		"hina_festival":
			dm._fan(c, origin, 5 + rank, PI + sin(turn) * 0.24, 1.40, 119.0 * scale, GREEN if wave % 2 else RED, "hina_doll" if wave % 2 else "hina_ofuda", _x(scale, 29.0, 4.5, {"arming_time": 1.2, "angular_speed": 0.12 * (-1 if wave % 2 else 1)}))
			cadence = 1.9
	_cross_lane(dm, c, origin, scale, RED if String(c.pattern) in ["hina_bell_fire", "hina_exiled_doll"] else GREEN, "hina_fire" if String(c.pattern) == "hina_bell_fire" else "hina_ofuda", 29.0)
	c.next_wave = float(c.age) + cadence * game.TouhouDifficulty.attack_cadence(String(c.kind), game.current_level)

static func _field_ofuda(dm: RefCounted, c: Dictionary, origin: Vector2, scale: float) -> void:
	var game: Control = dm.game
	var counts := [3, 2, 1]
	for branch in range(3):
		var row := int(game.active_rows[posmod(int(c.stage) + int(c.wave) + branch * 2, game.active_rows.size())])
		var point := Vector2(origin.x, game._row_center_y(row) - 12.0)
		dm._fan(c, point, counts[branch], PI + sin(int(c.wave) * 0.55 + branch) * 0.05, 0.34, 113.0 * scale, GREEN if branch % 2 == 0 else RED, "hina_ofuda", {"arming_time": 1.2, "radius": 4.0 * scale, "angular_speed": 0.08, "damage": 24.0})

static func _cross_lane(dm: RefCounted, c: Dictionary, origin: Vector2, scale: float, tint: Color, shape: String, damage: float) -> void:
	if not bool(c.get("autumn_full", false)) or int(c.wave) % 2 == 0: return
	if not String(c.pattern) in ["hina_misfortune_wheel", "hina_bell_fire", "hina_pain_flow", "hina_exiled_doll"]: return
	var game: Control = dm.game
	var row := int(game.active_rows[posmod(int(c.stage) + int(c.wave) + 3, game.active_rows.size())])
	var point := Vector2(origin.x, game._row_center_y(row) - 12.0)
	# A narrow fan carries the card's needles, fire or dolls into a planting
	# lane the full-direction pattern would otherwise skim past.
	dm._fan(c, point, 3, PI, 0.35, 108.0 * scale, tint, shape, {"arming_time": 1.2, "radius": 3.5 * scale, "damage": damage})

static func accompany_finale(dm: RefCounted, c: Dictionary) -> void:
	if int(c.card.finale_move) != 0: return
	var game: Control = dm.game
	if game.active_rows.is_empty(): return
	var scale := minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))
	var row := int(game.active_rows[posmod(int(c.stage) + int(c.wave) + 3, game.active_rows.size())])
	if int(c.wave) % 2 == 1:
		dm._fan(c, Vector2(Vector2(c.center).x, game._row_center_y(row) - 12.0), 3, PI, 0.35, 108.0 * scale, GREEN, "hina_ofuda", {"arming_time": 1.2, "radius": 3.5 * scale, "damage": 28.0})

static func _pain_ring(dm: RefCounted, c: Dictionary, center: Vector2, scale: float, exiled: bool) -> void:
	var game: Control = dm.game
	var wave := int(c.wave)
	var scatter := clampf(float(c.age) / maxf(1.0, float(c.duration)), 0.0, 1.0)
	var damage := 32.0 if exiled else 29.0
	var shape := "hina_doll" if exiled else "hina_orb"
	var tint := RED if exiled else GREEN
	var count := 18 if exiled else 14
	if wave == 0:
		# The first all-direction ring is regular; each later ring loosens into
		# a bounded deterministic scatter instead of adding an unseen random aim.
		dm._ring(c, center, count, PI / 12, 108.0 * scale, tint, shape, {"arming_time": 1.15, "radius": 4.5 * scale, "damage": damage})
		return
	count = ceili(count * dm._attack_density_for_cast(c))
	for i in range(count):
		var wobble := sin(i * 2.39996 + wave * 0.9)
		var angle := TAU * i / count + PI / 12 + wave * 0.08 + wobble * scatter * 0.34
		var speed := (108.0 + sin(i * 1.7 + wave) * scatter * 22.0) * scale
		dm._bullet(c, center, angle, speed, tint, shape, {"arming_time": 1.15, "radius": 4.5 * scale, "angular_speed": wobble * scatter * 0.11, "damage": damage})

static func draw_ofuda(game: CanvasItem, center: Vector2, radius: float, angle: float, color: Color) -> void:
	var axis := Vector2.from_angle(angle) * radius * 1.5
	var side := axis.orthogonal().normalized() * radius * 0.55
	var vertices := PackedVector2Array([center - axis - side, center + axis - side, center + axis + side, center - axis + side])
	game.draw_colored_polygon(vertices, color)
	vertices.append(vertices[0])
	game.draw_polyline(vertices, Color(0.12, 0.30, 0.24, color.a * 0.85), maxf(0.8, radius * 0.12), true)
	game.draw_line(center - axis * 0.60, center + axis * 0.55, Color(0.16, 0.24, 0.25, color.a), maxf(0.7, radius * 0.14), true)
	for shift in [-0.25, 0.20]: game.draw_line(center + axis * shift - side * 0.45, center + axis * shift + side * 0.45, Color(0.16, 0.24, 0.25, color.a), maxf(0.7, radius * 0.12), true)

static func draw_doll(game: CanvasItem, center: Vector2, radius: float, angle: float, tint: Color) -> void:
	# A nagashi-bina paper doll: round head, flared kimono, red sash.
	var up := Vector2.from_angle(angle - PI * 0.5)
	var side := up.orthogonal()
	game.draw_colored_polygon(PackedVector2Array([center + up * radius * 0.2 - side * radius * 0.35, center + up * radius * 0.2 + side * radius * 0.35, center - up * radius * 1.0 + side * radius * 0.85, center - up * radius * 1.0 - side * radius * 0.85]), tint)
	game.draw_line(center - side * radius * 0.6 - up * radius * 0.35, center + side * radius * 0.6 - up * radius * 0.35, Color(CRIMSON, tint.a), maxf(1.0, radius * 0.25), true)
	game.draw_circle(center + up * radius * 0.55, radius * 0.42, Color(1, 0.96, 0.9, tint.a))
	game.draw_circle(center + up * radius * 0.62, radius * 0.18, Color(0.2, 0.18, 0.22, tint.a))

static func draw_bullet(game: Control, b: Dictionary) -> void:
	var center := Vector2(b.position)
	# Drawn larger than the collision radius so shapes read on the lawn.
	var radius := float(b.radius) * 1.35
	var tint := Color(b.color)
	if float(b.age) < float(b.get("arming_time", 0.0)): tint.a *= 0.42
	var heading := Vector2(b.velocity).angle()
	var axis := Vector2.from_angle(heading)
	var side := axis.orthogonal()
	if WindGodFX.crowded(game):
		game.draw_circle(center, radius * 1.1, Color(WindGodFX.INK, tint.a * 0.6))
		game.draw_circle(center, radius * 0.85, tint)
		return
	match String(b.shape):
		"hina_ofuda":
			game.draw_circle(center, radius * 1.6, Color(tint, tint.a * 0.12))
			draw_ofuda(game, center, radius * 1.05, heading + sin(float(b.age) * 3.0) * 0.25, tint)
		"hina_fire":
			var flick := 1.0 + 0.18 * sin(float(b.age) * 23.0)
			game.draw_colored_polygon(PackedVector2Array([center + axis * radius, center + side * radius, center - axis * radius * 2.4 * flick + side * radius * 0.35, center - axis * radius * 1.3, center - axis * radius * 2.4 * flick - side * radius * 0.35, center - side * radius]), Color(tint, tint.a * 0.55))
			game.draw_circle(center, radius * 1.4, Color(tint, tint.a * 0.15))
			game.draw_circle(center, radius * 0.75, tint)
			game.draw_circle(center + axis * radius * 0.12, radius * 0.36, Color(1, 0.96, 0.8, tint.a))
		"hina_needle":
			game.draw_line(center - axis * radius * 2.3, center + axis * radius * 2.3, Color(WindGodFX.INK, tint.a * 0.6), maxf(1.6, radius * 0.9), true)
			game.draw_line(center - axis * radius * 2.1, center + axis * radius * 2.1, tint, maxf(1.0, radius * 0.6), true)
			game.draw_line(center - axis * radius * 1.4, center + axis * radius * 1.6, Color(1, 1, 1, tint.a * 0.9), 1.0, true)
		"hina_rice":
			var grain := PackedVector2Array()
			for i in range(10):
				var t := TAU * i / 10.0
				grain.append(center + axis * cos(t) * radius * 1.7 + side * sin(t) * radius * 0.62)
			game.draw_colored_polygon(grain, tint)
			game.draw_line(center - axis * radius * 0.8, center + axis * radius * 0.8, Color(1, 1, 1, tint.a * 0.85), 1.0, true)
		"hina_orb":
			WindGodFX.halo(game, center, radius, tint, 0.7)
			game.draw_circle(center, radius + 1.5, Color(WindGodFX.INK, tint.a * 0.8))
			game.draw_circle(center, radius, tint)
			game.draw_circle(center, radius * 0.5, Color(1, 1, 1, tint.a * 0.85))
		"hina_virus":
			var spin := float(b.age) * 6.0
			game.draw_circle(center, radius * 1.1, tint)
			for k in range(6):
				var a := spin + TAU * k / 6.0
				game.draw_line(center + Vector2.from_angle(a) * radius, center + Vector2.from_angle(a) * radius * 1.9, tint, maxf(1.0, radius * 0.3), true)
			game.draw_circle(center, radius * 0.45, Color(1, 0.9, 1, tint.a))
		"hina_doll":
			game.draw_circle(center, radius * 1.7, Color(tint, tint.a * 0.12))
			draw_doll(game, center, radius * 1.35, sin(float(b.age) * 4.0) * 0.4 + float(b.age) * 1.5, tint)
		_:
			var turn := float(b.age) * 3.0 + heading
			var wheel := Vector2.from_angle(turn)
			game.draw_circle(center - wheel * radius * 0.72, radius * 0.36, GOLD)
			game.draw_line(center - wheel * radius * 0.25, center + wheel * radius * 0.95, tint, maxf(1.0, radius * 0.58), true)
			game.draw_line(center - wheel.orthogonal() * radius * 0.72, center + wheel.orthogonal() * radius * 0.72, tint, maxf(1.0, radius * 0.32), true)
	WindGodFX.morph_flash(game, b, center, radius)

static func draw_cast(game: Control, c: Dictionary) -> void:
	var pattern := String(c.pattern)
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var origin := Vector2(c.center)
	var age := float(c.age)
	match pattern:
		"hina_misfortune_wheel", "hina_bell_fire":
			# The wheel of misfortune turns behind her, rim and spokes.
			var rim := unit * 0.62
			game.draw_arc(origin, rim, age * 1.3, age * 1.3 + TAU, 40, Color(GREEN, 0.45), maxf(1.5, unit * 0.04), true)
			game.draw_arc(origin, rim * 0.8, -age * 2.0, -age * 2.0 + TAU, 32, Color(RED, 0.35), maxf(1.0, unit * 0.025), true)
			for k in range(8):
				var a := age * 1.3 + TAU * k / 8.0
				game.draw_line(origin + Vector2.from_angle(a) * rim * 0.2, origin + Vector2.from_angle(a) * rim, Color(GREEN if k % 2 else RED, 0.4), maxf(1.0, unit * 0.02), true)
				if String(c.pattern) == "hina_bell_fire" and k % 2 == 0:
					var flame := origin + Vector2.from_angle(a) * rim
					game.draw_circle(flame, unit * (0.06 + 0.02 * sin(age * 12.0 + k)), Color(RED, 0.7))
		"hina_pain_flow", "hina_exiled_doll":
			for k in range(6):
				var a := -age * 0.8 + TAU * k / 6.0
				draw_doll(game, origin + Vector2(cos(a) * unit * 0.7, sin(a) * unit * 0.35 - unit * 0.3), unit * 0.09, sin(age * 3.0 + k) * 0.3, Color(RED if k % 2 else GREEN, 0.7))
		"hina_biorhythm", "hina_bad_fortune":
			var wave := PackedVector2Array()
			for k in range(25):
				var t := k / 24.0
				wave.append(origin + Vector2(-unit * 0.8 + unit * 1.6 * t, -unit * 0.95 + sin(t * TAU * 2.0 + age * 4.0) * unit * 0.12))
			game.draw_polyline(wave, Color(GREEN, 0.55), maxf(1.0, unit * 0.025), true)
		"hina_broken_amulet", "hina_damaged_amulet":
			var board := Rect2(game.BOARD_ORIGIN, game.board_size)
			for corner in [Vector2(board.end.x, board.position.y), Vector2(board.end.x, board.end.y)]:
				game.draw_circle(corner, unit * (0.2 + 0.05 * sin(age * 6.0)), Color(GREEN, 0.18))
				draw_ofuda(game, corner, unit * 0.08, age * 2.0, Color(GREEN, 0.8))
