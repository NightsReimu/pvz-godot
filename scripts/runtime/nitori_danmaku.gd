extends RefCounted
const WindGodFX = preload("res://scripts/runtime/wind_god_fx.gd")

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
				var spokes: int=ceili(6*dm._attack_density_for_cast(c))
				for i in range(spokes):
					var spoke: float=5.0*i/maxi(1,spokes-1)
					var angle: float = PI + side * (0.22 + spoke * 0.09)
					dm._bullet(c, origin, angle, (96.0 + spoke * 6.0) * scale, WATER, "nitori_drop", {"arming_time": 1.05, "radius": 4.0 * scale, "angular_speed": -side * (0.20 + spoke * 0.015), "damage": 25.0})
			dm._ring(c, origin, 6, turn, 70.0 * scale, FOAM, "nitori_bubble", {"arming_time": 1.1, "radius": 5.0 * scale, "damage": 22.0})
			cadence = 1.6
		"nitori_hydro_camouflage":
			for lane in [posmod(wave, game.active_rows.size()), posmod(wave + 3, game.active_rows.size())]:
				var start := Vector2(origin.x, game._row_center_y(int(game.active_rows[lane])) - 12.0)
				var stream: int=ceili(3*dm._attack_density_for_cast(c))
				for k in range(stream): dm._bullet(c, start + Vector2(44.0*k/maxi(1,stream-1) * scale, 0), PI, 165.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.0, "radius": 4.0 * scale, "damage": 27.0})
			_wall(dm, c, origin.x, posmod(wave * 2 + 1, game.active_rows.size()), 70.0 * scale, FOAM, "nitori_bubble", {"arming_time": 1.15, "radius": 5.0 * scale, "damage": 24.0, "life": 9.0})
			cadence = 1.7
		"nonspell_nitori_jet":
			dm._fan(c, origin, 3, aim, 0.18, 150.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.0, "radius": 4.5 * scale, "damage": 28.0})
			dm._ring(c, origin, 10, turn, 98.0 * scale, WATER, "nitori_drop", {"arming_time": 1.1, "radius": 3.8 * scale, "damage": 24.0})
			cadence = 1.5
		"nitori_ooze_flooding":
			# Hashed fixed ooze from both banks plus an aimed odd-way burst.
			_flood(dm, c, 3, 82.0 * scale, 0.0, OOZE, scale)
			dm._fan(c, origin, 1, aim, 0.22, 128.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.05, "radius": 4.2 * scale, "damage": 26.0})
			cadence = 1.8
		"nitori_diluvial_mare":
			# Hard: the fixed ooze now undulates as it flows.
			_flood(dm, c, 5, 98.0 * scale, 0.22, OOZE, scale, 9.0 * scale)
			dm._fan(c, origin, 3, aim, 0.24, 132.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.05, "radius": 4.2 * scale, "damage": 27.0})
			cadence = 1.65
		"nitori_glimmering_trauma":
			# Glimmers surface across the riverbed, hold, then drift out together.
			_flood(dm, c, 1, 90.0 * scale, 0.18, Color("6f8fb0"), scale, 11.0 * scale)
			for i in range(4 + wave % 2):
				var u := fposmod(0.42 + i * 0.137 + wave * 0.29, 0.52)
				var v := fposmod(0.08 + i * 0.211 + wave * 0.17, 0.86)
				var spot: Vector2 = dm._point(0.45 + u, 0.07 + v)
				dm._ring(c, spot, 4, turn + i, 62.0 * scale, FOAM, "nitori_bubble", {"arming_time": 1.2, "radius": 4.6 * scale, "freeze_at": 0.0, "thaw_at": 1.2, "thaw_angle": 0.0, "angular_speed": 0.18 * (-1 if i % 2 else 1), "damage": 26.0})
			dm._fan(c, origin, 5, aim, 0.6, 118.0 * scale, WATER, "nitori_drop", {"arming_time": 1.1, "radius": 4.0 * scale, "damage": 26.0})
			cadence = 1.6
		"nitori_pororoca":
			# The tidal bore: a slanted front of light bullets runs upstream
			# across several lanes at once, alternating its slant.
			_bore(dm, c, 1 if wave % 2 == 0 else -1, 6 if rank > 0 else 5, (74.0 if rank == 1 else 88.0) * scale, WATER, scale)
			cadence = 1.5
		"nitori_flash_flood":
			# Two fronts of opposite slant cross mid-lawn, faster than Pororoca.
			_bore(dm, c, 1, 7, 108.0 * scale, DEEP, scale)
			if wave % 2 == 1: _bore(dm, c, -1, 6, 96.0 * scale, WATER, scale)
			cadence = 1.6
		"nitori_great_waterfall":
			# Columns pour down the board, the full jet answers from the right.
			for k in range(2 + wave % 2):
				var x := 0.30 + fposmod(0.17 * wave + k * 0.23, 0.62)
				var top: Vector2 = dm._point(x, 0.0) + Vector2(0, -6)
				var drops: int=ceili(4*dm._attack_density_for_cast(c))
				for drop in range(drops):
					dm._bullet(c, top, PI / 2 + 0.22, (78.0 + 45.0*drop/maxi(1,drops-1)) * scale, WATER if drop % 2 else FOAM, "nitori_drop", {"arming_time": 1.05, "radius": 4.2 * scale, "damage": 27.0})
			dm._fan(c, origin, 5, aim, 0.40, 140.0 * scale, DEEP, "nitori_drop", {"arming_time": 1.05, "radius": 4.2 * scale, "damage": 28.0})
			if wave % 2 == 1: _bore(dm, c, 1 if wave % 4 == 1 else -1, 3, 92.0 * scale, FOAM, scale)
			cadence = 1.5
		"nitori_spook_cucumber":
			# Two lasers from her arms cross on the line to the targeted plant;
			# odd volleys fire while she drifts, so their crossing slides.
			_cross_lasers(dm, c, origin, target, 0.0 if wave % 2 == 0 else game.CELL_SIZE.y * 0.5 * sin(wave * 1.3), 1.1)
			dm._fan(c, origin, 2, PI + sin(turn) * 0.18, 1.0, 84.0 * scale, CUCUMBER, "nitori_cucumber", {"arming_time": 1.1, "radius": 6.5 * scale, "redirect_at": 1.35, "aim_point": target, "damage": 32.0})
			dm._ring(c, origin, 10, turn, 96.0 * scale, FOAM, "nitori_pearl", {"arming_time": 1.1, "radius": 3.8 * scale, "damage": 23.0})
			cadence = 1.8
		"nitori_extend_arm":
			var lanes := _busy_rows(game, 1 + mini(1, wave % 2))
			for row in lanes:
				WindGodFX.lane_beam(dm, c, row, origin.x - 20.0 * scale, "water", 1.2, 10.0 * scale, 54.0, 0.36)
			if wave % 2 == 0: _cross_lasers(dm, c, origin, target, 0.0, 1.0)
			dm._fan(c, origin, 9, aim, 0.9, 112.0 * scale, FOAM, "nitori_pearl", {"arming_time": 1.1, "radius": 4.0 * scale, "damage": 25.0})
			cadence = 1.6
		"nitori_cephalic_plate":
			for layer in range(2):
				var spin := 0.42 * (-1 if layer else 1)
				dm._ring(c, origin, 8 + layer * 2, turn * (1 + layer), (88.0 + layer * 18.0) * scale, PLATE, "nitori_plate", {"arming_time": 1.1, "radius": 5.2 * scale, "angular_speed": spin, "damage": 27.0})
			# Lunatic: the plates are joined by an aimed scatter of small shots.
			dm._fan(c, origin, 3, aim, 0.7, 150.0 * scale, FOAM, "nitori_pearl", {"arming_time": 1.0, "radius": 3.2 * scale, "damage": 24.0})
			if wave % 2 == 1:
				var row: int = _busy_rows(game, 1)[0]
				WindGodFX.lane_beam(dm, c, row, origin.x, "water", 1.25, 9.0 * scale, 50.0, 0.34)
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

static func _cross_lasers(dm: RefCounted, c: Dictionary, origin: Vector2, target: Vector2, drift: float, delay: float) -> void:
	var game: Control = dm.game
	var width: float = maxf(3.0, game.CELL_SIZE.y * 0.09)
	for side in [-1, 1]:
		var arm: Vector2 = origin + Vector2(-game.CELL_SIZE.x * 0.1, side * game.CELL_SIZE.y * 0.9 + drift)
		WindGodFX.ray_beam(dm, c, arm, (target - arm).angle(), "water", delay, width, 40.0, false, 0.4)

static func _bore(dm: RefCounted, c: Dictionary, slant: int, base_count: int, speed: float, tint: Color, scale: float) -> void:
	# A slanted line of light bullets spanning the lawn's height, all moving
	# together, so every lane meets the front at a different moment.
	var game: Control = dm.game
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var count: int = maxi(4, ceili(base_count * 2 * dm._attack_density_for_cast(c)))
	for k in range(count):
		var t := float(k) / float(count - 1)
		var y: float = lerpf(board.position.y + 6.0, board.end.y - 6.0, t)
		var x: float = board.end.x + game.CELL_SIZE.x * (0.2 + (t if slant > 0 else 1.0 - t) * 1.4)
		dm._bullet(c, Vector2(x, y), PI - slant * 0.18, speed, tint, "nitori_light", {"arming_time": 1.0, "radius": 5.4 * scale, "damage": 27.0, "life": 11.0, "sway_amp": 3.0 * scale, "sway_freq": 6.0, "sway_phase": t * 6.0})

static func _wall(dm: RefCounted, c: Dictionary, x: float, gap: int, speed: float, tint: Color, shape: String, extra: Dictionary) -> void:
	# A tidal wall across every lane, with one open lane to read and plan around.
	var game: Control = dm.game
	for i in range(game.active_rows.size()):
		if i == gap: continue
		var y: float = game._row_center_y(int(game.active_rows[i])) - 12.0
		var columns: int=maxi(2,ceili(2*dm._attack_density_for_cast(c)))
		for column in range(columns):
			var offset: float=lerpf(-.22,.22,float(column)/float(columns-1))
			dm._bullet(c, Vector2(x, y + game.CELL_SIZE.y * offset), PI, speed, tint, shape, extra)

static func _flood(dm: RefCounted, c: Dictionary, count: int, speed: float, bend: float, tint: Color, scale: float, undulate: float = 0.0) -> void:
	var wave := int(c.wave)
	count=ceili(count*dm._attack_density_for_cast(c))
	for side in [-1, 1]:
		for i in range(count):
			var x := 0.50 + fposmod(i * 0.115 + wave * 0.061 + (0.05 if side > 0 else 0.0), 0.48)
			var edge: Vector2 = dm._point(x, 0.0 if side < 0 else 1.0) + Vector2(0, side * 6.0)
			# Both floods bend toward the house rather than straight across lanes.
			var angle := PI * 0.80 if side < 0 else PI * 1.20
			var extra := {"arming_time": 1.1, "radius": 5.8 * scale, "angular_speed": -side * bend, "damage": 27.0, "life": 8.0}
			if undulate > 0.0: extra.merge({"sway_amp": undulate, "sway_freq": 3.2, "sway_phase": i * 0.9}, true)
			dm._bullet(c, edge, angle, speed, tint, "nitori_ooze", extra)

static func draw_bullet(game: Control, b: Dictionary) -> void:
	var center := Vector2(b.position)
	# Drawn larger than the collision radius so shapes read on the lawn.
	var radius := float(b.radius) * 1.3
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
		"nitori_light":
			var pulse := 0.85 + 0.15 * sin(float(b.age) * 10.0)
			game.draw_circle(center, radius * 2.2 * pulse, Color(tint, tint.a * 0.14))
			game.draw_circle(center, radius * 1.35, Color(tint, tint.a * 0.5))
			game.draw_circle(center, radius * 0.8, Color(1, 1, 1, tint.a))
		"nitori_pearl":
			game.draw_circle(center, radius + 1.4, Color(WindGodFX.INK, tint.a * 0.7))
			game.draw_circle(center, radius, tint)
			game.draw_circle(center - Vector2(radius, radius) * 0.3, radius * 0.35, Color(1, 1, 1, tint.a))
		"nitori_drop":
			game.draw_circle(center - axis * radius * 0.6, radius * 1.3, Color(tint, tint.a * 0.12))
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

static func draw_cast(game: Control, c: Dictionary) -> void:
	var pattern := String(c.pattern)
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var origin := Vector2(c.center)
	var age := float(c.age)
	match pattern:
		"nitori_spook_cucumber", "nitori_extend_arm":
			# Mechanical arms unfold from her backpack and a reticle tracks the
			# plant the crossing lasers converge on.
			for side in [-1, 1]:
				var hand: Vector2 = origin + Vector2(-game.CELL_SIZE.x * 0.1, side * game.CELL_SIZE.y * 0.9)
				game.draw_line(origin + Vector2(unit * 0.15, -unit * 0.2), hand, Color(PLATE, 0.8), maxf(2.0, unit * 0.06), true)
				game.draw_circle(hand, unit * 0.1, Color(DEEP, 0.85))
				game.draw_arc(hand, unit * 0.16, age * 4.0 * side, age * 4.0 * side + PI * 1.4, 16, Color(FOAM, 0.8), 1.5, true)
			var aim_at := Vector2(game.touhou_danmaku._target(origin)) if game.touhou_danmaku != null else origin
			game.draw_arc(aim_at, unit * (0.32 + 0.04 * sin(age * 8.0)), 0, TAU, 24, Color(WATER, 0.55), 1.5, true)
			for k in range(4):
				var a := TAU * k / 4.0 + age
				game.draw_line(aim_at + Vector2.from_angle(a) * unit * 0.2, aim_at + Vector2.from_angle(a) * unit * 0.42, Color(WATER, 0.7), 1.5, true)
		"nitori_cephalic_plate":
			for k in range(2):
				var r := unit * (0.5 + k * 0.18)
				game.draw_arc(origin, r, age * (3.0 if k == 0 else -2.2), age * (3.0 if k == 0 else -2.2) + PI * 1.6, 28, Color(PLATE, 0.6 - k * 0.2), maxf(1.5, unit * 0.04), true)
		"nitori_pororoca", "nitori_flash_flood", "nitori_great_waterfall":
			var board := Rect2(game.BOARD_ORIGIN, game.board_size)
			for k in range(6):
				var y := board.position.y + board.size.y * (k + 0.5) / 6.0
				var x := board.end.x + unit * (0.15 + 0.1 * sin(age * 3.0 + k))
				game.draw_arc(Vector2(x, y), unit * 0.18, PI * 0.5, PI * 1.5, 12, Color(FOAM, 0.45), 1.5, true)
