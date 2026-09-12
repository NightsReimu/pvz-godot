extends RefCounted

# Geometry follows the identifying behaviours described by TH08's spell
# comments. Counts, speed and timing are deliberately gentler TD adaptations.
const RED := Color("f04f68")
const BLUE := Color("72cdeb")
const PALETTE := [Color("f65a76"), Color("72cdeb"), Color("b594f3"), Color("f1cc70"), Color("87d6a4")]

static func emit(danmaku: RefCounted, c: Dictionary) -> void:
	var game: Control = danmaku.game
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var origin := Vector2(c.center)
	var target: Vector2 = danmaku._target(origin)
	var aim := (target - origin).angle()
	var wave := int(c.wave)
	var p := String(c.pattern)
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var scale := minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0)
	if p == "nonspell_reimu_amulets":
		# Aimed needles alternate with a wider ofuda fan, leaving readable lanes.
		danmaku._fan(c, origin, 7 + rank * 2, aim + sin(wave * 0.7) * 0.15, 1.25, 140 * scale, RED if wave % 2 == 0 else BLUE, "ofuda" if wave % 2 == 0 else "rice", {"radius": 4.5 * scale, "damage": 14.0})
		return
	match p:
		"reimu_duplex", "reimu_great_duplex":
			# Straight streams enter a pair of clearly marked boundary windows.
			# Crossing relocates the bullet, never sweeps damage through the gap.
			var count := 9 + rank * 3
			var high := p == "reimu_great_duplex"
			for i in range(count):
				var y := board.position.y + board.size.y * (0.09 + 0.82 * float(i) / maxf(1, count - 1))
				var start := Vector2(board.end.x - 15 * scale, y)
				var angle := PI + sin(wave * 0.7) * (0.16 if high else 0.09)
				danmaku._bullet(c, start, angle, (115 + rank * 7) * scale, RED if i % 2 == 0 else BLUE, "ofuda", {"radius": 4.5 * scale, "damage": 15.0, "boundary_x": board.position.x + board.size.x * 0.62, "boundary_top": board.position.y, "boundary_height": board.size.y, "boundary_shift": board.size.y * (0.32 if high else 0.20), "boundary_exit_x": board.position.x + board.size.x * 0.49})
		"reimu_spread", "reimu_worn":
			# Large coloured dream spheres expand in offset rings; Worn repeats
			# with a second, slower layer rather than reusing an aimed fan.
			var count := 12 + rank * 3 + mini(4, wave)
			for i in range(count):
				var angle := TAU * float(i) / count + wave * 0.21
				danmaku._bullet(c, origin, angle, (105 + wave * 3) * scale, PALETTE[(i + wave) % 5], "dream_orb", {"radius": 7.5 * scale, "damage": 16.0})
			if p == "reimu_worn" and wave % 2 == 1:
				danmaku._ring(c, origin, 13, -wave * 0.17, 73 * scale, PALETTE[wave % 5], "orb", {"radius": 4.0 * scale, "damage": 12.0})
		"reimu_sealing_circle", "reimu_binding_circle", "reimu_dragon_circle":
			# Ofuda form enclosing rings with an intentional escape sector.
			# Hard/Lunatic add eight radial arms, with a rotating second layer.
			var center := board.position + board.size * Vector2(0.46, 0.5)
			var radius := minf(board.size.x * 0.35, board.size.y * 0.43)
			var count := 18 + rank * 6
			var gap := wave * 0.38 + PI * 0.5
			for i in range(count):
				var angle := TAU * float(i) / count + wave * 0.07
				if absf(angle_difference(angle, gap)) < 0.36:
					continue
				var start := center + Vector2.from_angle(angle) * radius
				danmaku._bullet(c, start, angle + PI + (0.24 if rank == 3 else 0.0), 74 * scale, RED, "ofuda", {"radius": 4.0 * scale, "damage": 12.0, "arming_time": 0.65})
			if rank >= 2 and wave % 2 == 0:
				for arm in range(8):
					var angle := arm * TAU / 8.0 + wave * 0.13
					danmaku._fan(c, origin, 3 if rank == 3 else 2, angle, 0.14, 105 * scale, BLUE, "ofuda", {"radius": 3.8 * scale, "damage": 12.0})
		"reimu_concentrate", "reimu_returning":
			# Detached charms curve toward the snapshotted target. Returning
			# starts outward before turning back, unlike the expanding Spread.
			var count := 10 + rank * 3
			for i in range(count):
				var angle := TAU * float(i) / count + wave * 0.31
				var start := origin + Vector2.from_angle(angle) * 30 * scale
				danmaku._bullet(c, start, angle if p == "reimu_returning" else aim + (i - count * 0.5) * 0.20, 85 * scale, PALETTE[(i + wave) % 5], "ofuda", {"radius": 5.0 * scale, "damage": 14.0, "aim_point": target, "homing_after": 0.8 if p == "reimu_returning" else 0.35, "homing_rate": 1.65 if rank >= 2 else 0.85, "life": 6.0})
			if wave % 2 == 0:
				danmaku._fan(c, origin, 5, aim, 0.9, 115 * scale, PALETTE[wave % 5], "dream_orb", {"radius": 7 * scale, "damage": 16.0})
		"reimu_danmaku_barrier", "reimu_hakurei_barrier":
			# Nested rectangular borders emit perpendicular streams, alternately
			# inward and outward; the high variant counter-rotates the borders.
			var center := board.position + board.size * Vector2(0.53, 0.5)
			var count := 6 + rank * 2
			var rotation := sin(wave * 0.24) * (0.20 if rank >= 2 else 0.05)
			c["barrier_rotation"] = rotation
			for layer in range(2):
				var extent := board.size * (0.29 if layer == 0 else 0.18)
				for side in range(4):
					for i in range(count):
						if i == posmod(wave + side, count):
							continue
						var t := -1.0 + 2.0 * float(i) / maxf(1, count - 1)
						var local := Vector2(extent.x * t, -extent.y)
						var direction := Vector2.DOWN
						match side:
							1: local = Vector2(extent.x, extent.y * t); direction = Vector2.LEFT
							2: local = Vector2(-extent.x * t, extent.y); direction = Vector2.UP
							3: local = Vector2(-extent.x, -extent.y * t); direction = Vector2.RIGHT
						var turn := rotation * (1 if layer == 0 else -1)
						if layer == 1:
							direction = -direction
						danmaku._bullet(c, center + local.rotated(turn), direction.angle() + turn, (66 + rank * 6) * scale, RED if layer == 0 else BLUE, "ofuda", {"radius": 3.6 * scale, "damage": 10.0, "arming_time": 0.8, "life": 4.0})
		"reimu_blink":
			# Survival finale: dream spheres from successive afterimages with
			# short telegraphed delays before the amulets converge.
			var start := board.position + board.size * Vector2(0.77 + 0.10 * sin(wave * 1.9), 0.2 + 0.6 * (wave % 4) / 3.0)
			c["blink_position"] = start
			var count := 14 + rank * 3
			for i in range(count):
				var angle := TAU * float(i) / count + wave * 0.27
				danmaku._bullet(c, start, angle, 112 * scale, PALETTE[(i + wave) % 5], "dream_orb", {"radius": 6.0 * scale, "damage": 12.0, "arming_time": 0.35})
			if wave % 2 == 1:
				danmaku._fan(c, start, 7 + rank, (target - start).angle(), 0.95, 135 * scale, RED, "ofuda", {"radius": 3.8 * scale, "damage": 10.0, "arming_time": 0.6})

static func advance_bullet(b: Dictionary, before: Vector2, delta: float) -> Vector2:
	if b.has("homing_after") and float(b.age) >= float(b.homing_after):
		var velocity := Vector2(b.velocity)
		var target_angle := (Vector2(b.aim_point) - Vector2(b.position)).angle()
		var turn := clampf(angle_difference(velocity.angle(), target_angle), -float(b.homing_rate) * delta, float(b.homing_rate) * delta)
		b.velocity = velocity.rotated(turn)
	if b.has("boundary_x") and not bool(b.get("boundary_crossed", false)) and before.x > float(b.boundary_x) and Vector2(b.position).x <= float(b.boundary_x):
		b.position.x = float(b.boundary_exit_x)
		b.position.y = float(b.boundary_top) + fposmod(float(b.position.y) - float(b.boundary_top) + float(b.boundary_shift), float(b.boundary_height))
		b["boundary_crossed"] = true
		return Vector2(b.position)
	return before
