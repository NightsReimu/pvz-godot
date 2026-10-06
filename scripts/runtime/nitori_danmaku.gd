extends RefCounted

# Board-space adaptations of TH10 stage 3. Boss origins stay on the right;
# "from the sides" floods enter from the top and bottom board edges.
const WATER := Color("6fd3f2")
const DEEP := Color("3a9ad6")
const FOAM := Color("dff6ff")
const OOZE := Color("8d9a5a")
const CUCUMBER := Color("6cc04f")
const GOLD := Color("f2d27a")
const PLATE := Color("b9e6f5")

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	if game.active_rows.is_empty(): return
	var wave := int(c.wave)
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var origin := Vector2(c.center)
	var scale: float = minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))
	var turn := wave * 0.41
	var target: Vector2 = dm._target(origin)
	var aim := (target - origin).angle()
	var cadence := 1.5
	match String(c.pattern):
		"nonspell_nitori_camouflage":
			# Shots leave from refracted points around the hidden kappa.
			var ghost := origin + Vector2(0, sin(wave * 1.7) * game.CELL_SIZE.y * 0.7)
			dm._fan(c, ghost, 3, (target - ghost).angle(), 0.30, 118.0 * scale, WATER, "nitori_drop", {"arming_time": 1.0, "radius": 4.2 * scale, "damage": 24.0})
			dm._fan(c, ghost, 5, PI + sin(turn) * 0.2, 0.9, 104.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.05, "radius": 4.0 * scale, "damage": 22.0})
			cadence = 1.45
		"nitori_optical_camouflage":
			# Two curving walls close into an eye; a slow pupil marks the middle.
			for side in [-1, 1]:
				for i in range(6):
					var angle: float = PI + side * (0.22 + i * 0.09)
					dm._bullet(c, origin, angle, (96.0 + i * 6.0) * scale, WATER, "nitori_drop", {"arming_time": 1.05, "radius": 4.0 * scale, "angular_speed": -side * (0.20 + i * 0.015), "damage": 25.0})
			dm._ring(c, origin, 6, turn, 70.0 * scale, FOAM, "nitori_bubble", {"arming_time": 1.1, "radius": 5.0 * scale, "damage": 22.0})
			cadence = 1.6
		"nitori_hydro_camouflage":
			for lane in [posmod(wave, game.active_rows.size()), posmod(wave + 3, game.active_rows.size())]:
				var start := Vector2(origin.x, game._row_center_y(int(game.active_rows[lane])) - 12.0)
				for k in range(3): dm._bullet(c, start + Vector2(k * 22.0 * scale, 0), PI, 165.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.0, "radius": 4.0 * scale, "damage": 27.0})
			_wall(dm, c, origin.x, posmod(wave * 2 + 1, game.active_rows.size()), 70.0 * scale, FOAM, "nitori_bubble", {"arming_time": 1.15, "radius": 5.0 * scale, "damage": 24.0, "life": 9.0})
			cadence = 1.7
		"nonspell_nitori_jet":
			dm._fan(c, origin, 3, aim, 0.18, 150.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.0, "radius": 4.5 * scale, "damage": 28.0})
			dm._ring(c, origin, 10, turn, 98.0 * scale, WATER, "nitori_drop", {"arming_time": 1.1, "radius": 3.8 * scale, "damage": 24.0})
			cadence = 1.5
		"nitori_ooze_flooding":
			_flood(dm, c, 4, 82.0 * scale, 0.0, OOZE, scale)
			cadence = 1.75
		"nitori_diluvial_mare":
			_flood(dm, c, 5, 98.0 * scale, 0.22, OOZE, scale)
			dm._fan(c, origin, 3, aim, 0.24, 132.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.05, "radius": 4.2 * scale, "damage": 27.0})
			cadence = 1.65
		"nitori_glimmering_trauma":
			# Glimmers surface across the riverbed, hold, then drift out together.
			for i in range(4 + wave % 2):
				var u := fposmod(0.42 + i * 0.137 + wave * 0.29, 0.52)
				var v := fposmod(0.08 + i * 0.211 + wave * 0.17, 0.86)
				var spot: Vector2 = dm._point(0.45 + u, 0.07 + v)
				dm._ring(c, spot, 4, turn + i, 62.0 * scale, FOAM, "nitori_bubble", {"arming_time": 1.2, "radius": 4.6 * scale, "freeze_at": 0.0, "thaw_at": 1.2, "thaw_angle": 0.0, "angular_speed": 0.18 * (-1 if i % 2 else 1), "damage": 26.0})
			dm._fan(c, origin, 5, aim, 0.6, 118.0 * scale, WATER, "nitori_drop", {"arming_time": 1.1, "radius": 4.0 * scale, "damage": 26.0})
			cadence = 1.6
		"nitori_pororoca":
			_wall(dm, c, origin.x, posmod(wave, game.active_rows.size()), 92.0 * scale, WATER, "nitori_drop", {"arming_time": 1.1, "radius": 4.2 * scale, "angular_speed": 0.10 * (-1 if wave % 2 else 1), "damage": 26.0})
			cadence = 1.7
		"nitori_flash_flood":
			_wall(dm, c, origin.x, posmod(wave * 2, game.active_rows.size()), 120.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.05, "radius": 4.2 * scale, "damage": 28.0})
			if wave % 2 == 1:
				_wall(dm, c, origin.x + 40.0 * scale, posmod(wave * 2 + 3, game.active_rows.size()), 104.0 * scale, WATER, "nitori_drop", {"arming_time": 1.15, "radius": 4.0 * scale, "angular_speed": 0.12, "damage": 26.0})
			cadence = 1.6
		"nitori_great_waterfall":
			# Columns pour down the board, the full jet answers from the right.
			for k in range(2 + wave % 2):
				var x := 0.30 + fposmod(0.17 * wave + k * 0.23, 0.62)
				var top: Vector2 = dm._point(x, 0.0) + Vector2(0, -6)
				for drop in range(4):
					dm._bullet(c, top, PI / 2 + 0.22, (78.0 + drop * 15.0) * scale, WATER if drop % 2 else FOAM, "nitori_drop", {"arming_time": 1.05, "radius": 4.2 * scale, "damage": 27.0})
			dm._fan(c, origin, 5, aim, 0.40, 140.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.05, "radius": 4.2 * scale, "damage": 28.0})
			cadence = 1.5
		"nitori_spook_cucumber":
			dm._fan(c, origin, 5, PI + sin(turn) * 0.18, 1.1, 84.0 * scale, CUCUMBER, "nitori_cucumber", {"arming_time": 1.1, "radius": 6.5 * scale, "redirect_at": 1.35, "aim_point": target, "damage": 32.0})
			dm._ring(c, origin, 12, turn, 96.0 * scale, WATER, "nitori_drop", {"arming_time": 1.1, "radius": 3.6 * scale, "damage": 23.0})
			cadence = 1.75
		"nitori_extend_arm":
			var lanes := _busy_rows(game, 1 + mini(1, wave % 2))
			for row in lanes:
				var start := Vector2(origin.x - 20.0 * scale, game._row_center_y(row) - 12.0)
				dm._beam(c, start, Vector2(game.BOARD_ORIGIN.x, start.y), WATER, 1.2, 10.0 * scale, {"damage": 54.0, "duration": 0.36})
			dm._fan(c, origin, 7, aim, 0.9, 112.0 * scale, GOLD, "nitori_drop", {"arming_time": 1.1, "radius": 4.0 * scale, "damage": 25.0})
			cadence = 1.8
		"nitori_cephalic_plate":
			for layer in range(2):
				var spin := 0.42 * (-1 if layer else 1)
				dm._ring(c, origin, 10 + layer * 2, turn * (1 + layer), (88.0 + layer * 18.0) * scale, PLATE, "nitori_plate", {"arming_time": 1.1, "radius": 5.2 * scale, "angular_speed": spin, "damage": 27.0})
			if wave % 2 == 1:
				var row: int = _busy_rows(game, 1)[0]
				dm._beam(c, origin, Vector2(game.BOARD_ORIGIN.x, game._row_center_y(row) - 12.0), FOAM, 1.25, 9.0 * scale, {"damage": 50.0, "duration": 0.34})
			cadence = 1.7
		"nitori_camo_squad", "nitori_cucumber_bait", "nitori_water_cannon":
			# Board mechanics remain readable under a moderate cross-lane rain.
			for branch in range(3):
				var row := int(game.active_rows[posmod(wave + branch * 2, game.active_rows.size())])
				var point := Vector2(origin.x, game._row_center_y(row) - 12.0)
				var shape := "nitori_cucumber" if String(c.pattern) == "nitori_cucumber_bait" and branch == 1 else "nitori_drop"
				dm._fan(c, point, 2, PI, 0.22, 112.0 * scale, CUCUMBER if shape == "nitori_cucumber" else WATER, shape, {"arming_time": 1.15, "radius": (6.0 if shape == "nitori_cucumber" else 4.0) * scale, "damage": 25.0})
			cadence = 2.0
		"nitori_workshop":
			dm._fan(c, origin, 5 + rank, aim, 1.2, 112.0 * scale, CUCUMBER if wave % 2 else WATER, "nitori_cucumber" if wave % 2 else "nitori_drop", {"arming_time": 1.15, "radius": (6.0 if wave % 2 else 4.2) * scale, "damage": 28.0})
			dm._ring(c, origin, 8, turn, 80.0 * scale, PLATE, "nitori_plate", {"arming_time": 1.2, "radius": 4.8 * scale, "angular_speed": 0.3, "damage": 24.0})
			cadence = 1.85
	c.next_wave = float(c.age) + cadence * game.TouhouDifficulty.attack_cadence(String(c.kind), game.current_level)

static func _busy_rows(game: Control, count: int) -> Array[int]:
	var scored: Array = []
	for i in range(game.active_rows.size()):
		var row := int(game.active_rows[i])
		var plants := 0
		for col in range(game.COLS):
			if game._targetable_plant_at(row, col) != null: plants += 1
		scored.append([plants, -i, row])
	scored.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] > b[1]))
	var result: Array[int] = []
	for i in range(mini(count, scored.size())): result.append(int(scored[i][2]))
	return result

static func _wall(dm: RefCounted, c: Dictionary, x: float, gap: int, speed: float, tint: Color, shape: String, extra: Dictionary) -> void:
	# A tidal wall across every lane, with one open lane to read and plan around.
	var game: Control = dm.game
	for i in range(game.active_rows.size()):
		if i == gap: continue
		var y: float = game._row_center_y(int(game.active_rows[i])) - 12.0
		for offset in [-0.22, 0.22]:
			dm._bullet(c, Vector2(x, y + game.CELL_SIZE.y * offset), PI, speed, tint, shape, extra)

static func _flood(dm: RefCounted, c: Dictionary, count: int, speed: float, bend: float, tint: Color, scale: float) -> void:
	var wave := int(c.wave)
	for side in [-1, 1]:
		for i in range(count):
			var x := 0.50 + fposmod(i * 0.115 + wave * 0.061 + (0.05 if side > 0 else 0.0), 0.48)
			var edge: Vector2 = dm._point(x, 0.0 if side < 0 else 1.0) + Vector2(0, side * 6.0)
			# Both floods bend toward the house rather than straight across lanes.
			var angle := PI * 0.80 if side < 0 else PI * 1.20
			dm._bullet(c, edge, angle, speed, tint, "nitori_ooze", {"arming_time": 1.1, "radius": 5.8 * scale, "angular_speed": -side * bend, "damage": 27.0, "life": 8.0})

static func draw_bullet(game: Control, b: Dictionary) -> void:
	var center := Vector2(b.position)
	var radius := float(b.radius)
	var tint := Color(b.color)
	if float(b.age) < float(b.get("arming_time", 0.0)): tint.a *= 0.42
	var heading := Vector2(b.velocity).angle()
	var axis := Vector2.from_angle(heading)
	var side := axis.orthogonal()
	match String(b.shape):
		"nitori_drop":
			game.draw_colored_polygon(PackedVector2Array([center + axis * radius * 1.25, center + side * radius * 0.8, center - axis * radius * 1.6, center - side * radius * 0.8]), tint)
			game.draw_circle(center + axis * radius * 0.15, radius * 0.78, tint)
			game.draw_circle(center + axis * radius * 0.35 - side * radius * 0.25, radius * 0.26, Color(1, 1, 1, tint.a * 0.85))
		"nitori_bubble":
			game.draw_circle(center, radius, Color(tint, tint.a * 0.30))
			game.draw_arc(center, radius, 0, TAU, 16, tint, maxf(1.0, radius * 0.22), true)
			game.draw_circle(center + Vector2(-radius * 0.35, -radius * 0.35), radius * 0.22, Color(1, 1, 1, tint.a))
			if bool(b.get("frozen", false)):
				var glint := absf(sin(float(b.age) * 9.0))
				game.draw_line(center - Vector2(radius * 1.4, 0), center + Vector2(radius * 1.4, 0), Color(1, 1, 1, tint.a * glint), 1.0, true)
				game.draw_line(center - Vector2(0, radius * 1.4), center + Vector2(0, radius * 1.4), Color(1, 1, 1, tint.a * glint), 1.0, true)
		"nitori_ooze":
			var wobble := sin(float(b.age) * 7.0) * radius * 0.12
			game.draw_circle(center - axis * radius * 0.7, radius * 0.7, Color(tint, tint.a * 0.55))
			game.draw_circle(center, radius + wobble, tint)
			game.draw_circle(center + axis * radius * 0.25 - side * radius * 0.3, radius * 0.28, Color(0.86, 0.90, 0.66, tint.a))
		"nitori_cucumber":
			var spin := heading + sin(float(b.age) * 5.0) * 0.35
			var long := Vector2.from_angle(spin) * radius * 1.55
			var wide := long.orthogonal().normalized() * radius * 0.62
			var body := PackedVector2Array()
			body.append(center - long)
			for i in range(1, 9):
				var t := float(i) / 9.0
				body.append(center - long + long * 2.0 * t + wide * sin(t * PI))
			body.append(center + long)
			for i in range(8, 0, -1):
				var t := float(i) / 9.0
				body.append(center - long + long * 2.0 * t - wide * sin(t * PI))
			game.draw_colored_polygon(body, tint)
			game.draw_line(center - long * 0.55, center + long * 0.55, Color(0.85, 0.95, 0.62, tint.a * 0.8), maxf(1.0, radius * 0.18), true)
			game.draw_circle(center + long, radius * 0.18, Color(0.55, 0.40, 0.20, tint.a))
		"nitori_plate":
			var turn := float(b.age) * 8.0
			var rim := Vector2.from_angle(turn) * radius
			game.draw_circle(center, radius, Color(tint, tint.a * 0.85))
			game.draw_arc(center, radius, 0, TAU, 16, Color(0.20, 0.45, 0.62, tint.a), maxf(1.0, radius * 0.2), true)
			game.draw_line(center - rim * 0.7, center + rim * 0.7, Color(1, 1, 1, tint.a * 0.75), maxf(1.0, radius * 0.18), true)
		_:
			game.draw_circle(center, radius, tint)
