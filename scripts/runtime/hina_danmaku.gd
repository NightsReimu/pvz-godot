extends RefCounted

const GREEN := Color("95e6b5")
const DARK_GREEN := Color("54b891")
const RED := Color("ec7391")
const GOLD := Color("f0d090")

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	if game.active_rows.is_empty(): return
	var wave := int(c.wave)
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var origin := Vector2(c.center)
	var scale: float = minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))
	var turn := wave * 0.37
	var cadence := 1.4
	match String(c.pattern):
		"nonspell_hina_spiral":
			dm._fan(c, origin, 5, PI + sin(turn) * 0.22, 0.90, 118.0 * scale, GREEN, "hina_ofuda", {"arming_time": 1.0, "radius": 4.5 * scale, "angular_speed": 0.13 * (-1 if wave % 2 else 1), "damage": 25.0})
			cadence = 1.75
		"hina_bad_fortune":
			# Four loose winding spokes: the early encounter stays weaker and readable.
			for i in range(4):
				var angle := PI + (i - 1.5) * 0.32 + sin(turn) * 0.26
				dm._fan(c, origin, 3, angle, 0.20, (104.0 + i * 8.0) * scale, GREEN if i % 2 else DARK_GREEN, "hina_ofuda", {"arming_time": 1.05, "radius": 4.3 * scale, "angular_speed": 0.15, "damage": 25.0})
			cadence = 1.6
		"hina_biorhythm":
			for direction in [-1, 1]:
				var center := origin + Vector2(0, direction * game.CELL_SIZE.y * 0.20)
				dm._fan(c, center, 7, PI + direction * sin(turn) * 0.26, 1.15, 122.0 * scale, GREEN if direction == 1 else RED, "hina_ofuda", {"arming_time": 1.1, "radius": 4.5 * scale, "angular_speed": direction * 0.18, "damage": 29.0})
			cadence = 1.5
		"hina_broken_amulet":
			for branch in range(2):
				var direction := branch * 2 - 1
				var center := origin + Vector2(0, direction * game.CELL_SIZE.y * 0.32)
				dm._fan(c, center, 5, PI + direction * 0.24, 1.05, 127.0 * scale, GREEN if branch == 0 else RED, "hina_ofuda", {"arming_time": 1.1, "radius": 4.5 * scale, "angular_speed": direction * 0.06, "damage": 29.0})
			cadence = 1.6
		"hina_damaged_amulet":
			for branch in range(2):
				var center := origin + Vector2(0, (branch * 2 - 1) * game.CELL_SIZE.y * 0.35)
				dm._fan(c, center, 9, PI + (branch * 2 - 1) * sin(turn) * 0.35, 1.40, 136.0 * scale, GREEN if branch == 0 else RED, "hina_ofuda", {"arming_time": 1.1, "radius": 4.5 * scale, "angular_speed": (branch * 2 - 1) * 0.11, "damage": 31.0})
			cadence = 1.5
		"hina_misfortune_wheel":
			# The original E/N wheel is a rotating needle pattern, not an ofuda fan.
			dm._ring(c, origin, 14, turn, 102.0 * scale, GREEN, "needle", {"arming_time": 1.15, "radius": 3.2 * scale, "angular_speed": 0.12, "damage": 29.0})
			dm._fan(c, origin, 3, PI - sin(turn) * 0.18, 0.5, 145.0 * scale, GOLD, "needle", {"arming_time": 1.1, "radius": 3.0 * scale, "damage": 28.0})
			cadence = 1.6
		"hina_bell_fire":
			dm._ring(c, origin, 18, -turn, 111.0 * scale, GREEN if wave % 2 else RED, "hina_fire", {"arming_time": 1.2, "radius": 5.0 * scale, "angular_speed": -0.14, "damage": 35.0})
			dm._fan(c, origin, 5, PI + sin(turn) * 0.24, 0.78, 151.0 * scale, GOLD, "hina_fire", {"arming_time": 1.2, "radius": 3.8 * scale, "damage": 31.0})
			cadence = 1.6
		"hina_pain_flow":
			_pain_ring(dm, c, origin, scale, false)
			cadence = 1.65
		"hina_exiled_doll":
			_pain_ring(dm, c, origin, scale, true)
			if float(c.age) >= float(c.duration) * 0.45:
				dm._fan(c, origin, 5, PI + sin(turn) * 0.22, 1.20, 134.0 * scale, GREEN, "hina_ofuda", {"arming_time": 1.15, "radius": 2.8 * scale, "angular_speed": -0.12, "damage": 22.0})
			cadence = 1.65
		"hina_delayed", "hina_doll_offering", "hina_misfire":
			# Original fields remain legible under a deliberately sparse green spiral.
			dm._fan(c, origin, 3, PI + sin(turn) * 0.18, 0.8, 113.0 * scale, GREEN, "hina_ofuda", {"arming_time": 1.2, "radius": 4.0 * scale, "angular_speed": 0.08, "damage": 24.0})
			cadence = 2.2
		"hina_festival":
			dm._fan(c, origin, 5 + rank, PI + sin(turn) * 0.24, 1.40, 119.0 * scale, GREEN if wave % 2 else RED, "hina_doll" if wave % 2 else "hina_ofuda", {"arming_time": 1.2, "radius": 4.5 * scale, "angular_speed": 0.12 * (-1 if wave % 2 else 1), "damage": 29.0})
			cadence = 1.9
	c.next_wave = float(c.age) + cadence * game.TouhouDifficulty.attack_cadence(String(c.kind), game.current_level)

static func _pain_ring(dm: RefCounted, c: Dictionary, center: Vector2, scale: float, exiled: bool) -> void:
	var game: Control = dm.game
	var wave := int(c.wave)
	var scatter := clampf(float(c.age) / maxf(1.0, float(c.duration)), 0.0, 1.0)
	var damage := 32.0 if exiled else 29.0
	var shape := "hina_doll" if exiled else "orb"
	var tint := RED if exiled else GREEN
	var count := 18 if exiled else 14
	if wave == 0:
		# The first all-direction ring is regular; each later ring loosens into
		# a bounded deterministic scatter instead of adding an unseen random aim.
		dm._ring(c, center, count, PI / 12, 108.0 * scale, tint, shape, {"arming_time": 1.15, "radius": 4.5 * scale, "damage": damage})
		return
	count = ceili(count * game.TouhouDifficulty.attack_density(String(c.kind), game.current_level))
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

static func draw_bullet(game: Control, b: Dictionary) -> void:
	var center := Vector2(b.position)
	var radius := float(b.radius)
	var tint := Color(b.color)
	if float(b.age) < float(b.get("arming_time", 0.0)): tint.a *= 0.42
	var heading := Vector2(b.velocity).angle()
	if String(b.shape) == "hina_ofuda":
		draw_ofuda(game, center, radius, heading + sin(float(b.age) * 3.0) * 0.25, tint)
	elif String(b.shape) == "hina_fire":
		var axis := Vector2.from_angle(heading)
		var side := axis.orthogonal()
		game.draw_colored_polygon(PackedVector2Array([center + axis * radius, center + side * radius, center - axis * radius * 2.0 + side * radius * 0.3, center - axis * radius * 1.1, center - axis * radius * 2.0 - side * radius * 0.3, center - side * radius]), Color(tint, tint.a * 0.60))
		game.draw_circle(center, radius * 0.70, tint)
		game.draw_circle(center + axis * radius * 0.10, radius * 0.32, Color(1, 0.95, 0.78, tint.a))
	else:
		var turn := float(b.age) * 3.0 + heading
		var axis := Vector2.from_angle(turn)
		var side := axis.orthogonal()
		game.draw_circle(center - axis * radius * 0.72, radius * 0.36, GOLD)
		game.draw_line(center - axis * radius * 0.25, center + axis * radius * 0.95, tint, maxf(1.0, radius * 0.58), true)
		game.draw_line(center - side * radius * 0.72, center + side * radius * 0.72, tint, maxf(1.0, radius * 0.32), true)
