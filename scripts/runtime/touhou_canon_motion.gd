extends RefCounted
# Bullet and beam motions the original Touhou cards need, for every boss outside
# Mountain of Faith: timed turns (absolute, relative or re-aimed), authored speed
# curves, gravity, homing, orbits, rotation reversal, trails and splitting.
# A bullet opts in with "cm": true. Everything reads the bullet's own clock, so
# time stop and the shared freeze/thaw keep working unchanged.

const WindGodFX = preload("res://scripts/runtime/wind_god_fx.gd")
const MOTION_KEYS := ["turns", "speed_curve", "gravity_vec", "home_rate", "orbit_center", "spin_flip_at", "trail_every", "split_at", "sway_amp", "speed_wave", "accel", "morph_at"]

static func advance(dm: RefCounted, b: Dictionary, before: Vector2, delta: float) -> Vector2:
	if bool(b.get("frozen", false)):
		return before
	var age := float(b.age)
	var factor := float(b.get("speed_factor", 1.0))
	if b.has("orbit_center") and age < float(b.get("orbit_until", 0.0)):
		# Bullets riding a turning circle (cages, clock faces, revolving rings).
		b.orbit_angle = float(b.orbit_angle) + float(b.orbit_turn) * delta
		b.orbit_radius = float(b.orbit_radius) + float(b.get("orbit_grow", 0.0)) * delta * factor
		var heading := Vector2.from_angle(float(b.orbit_angle))
		b.position = Vector2(b.orbit_center) + heading * float(b.orbit_radius)
		b.velocity = heading.rotated(signf(float(b.orbit_turn)) * PI * 0.5) * maxf(1.0, absf(float(b.orbit_turn)) * float(b.orbit_radius))
		if age + delta >= float(b.orbit_until):
			# Leave the orbit along the authored release heading.
			var release := float(b.get("orbit_release", 0.0))
			var speed := float(b.get("orbit_release_speed", 80.0)) * factor
			b.velocity = (heading.rotated(release)) * speed
		return Vector2(b.position) if age <= delta * 1.5 else before
	if b.has("speed_curve") and age <= float(b.speed_curve[b.speed_curve.size() - 1][0]):
		# [[age, speed], ...] piecewise linear speed; direction is kept. After
		# the last point the bullet keeps its speed, so later turns may set one.
		var curve: Array = b.speed_curve
		var speed := float(curve[curve.size() - 1][1])
		for i in range(curve.size() - 1):
			if age < float(curve[i + 1][0]):
				var t := clampf((age - float(curve[i][0])) / maxf(0.001, float(curve[i + 1][0]) - float(curve[i][0])), 0.0, 1.0)
				speed = lerpf(float(curve[i][1]), float(curve[i + 1][1]), t)
				break
		var heading := Vector2(b.velocity).normalized()
		if heading.is_zero_approx():
			heading = Vector2.from_angle(float(b.get("facing", PI)))
		elif speed > 0.001:
			b["facing"] = heading.angle()
		b.velocity = heading * speed * factor
	if b.has("turns"):
		var turns: Array = b.turns
		var index := int(b.get("turn_i", 0))
		while index < turns.size() and age >= float(turns[index].t):
			var turn: Dictionary = turns[index]
			var speed := Vector2(b.velocity).length()
			if turn.has("s"):
				speed = float(turn.s) * factor
			var heading := Vector2(b.velocity).angle() if Vector2(b.velocity).length_squared() > 0.0001 else float(b.get("facing", PI))
			if turn.has("aim"):
				var aim_point: Vector2 = dm._target(Vector2(b.position))
				heading = (aim_point - Vector2(b.position)).angle() + float(turn.get("aim_offset", 0.0))
			elif turn.has("a"):
				heading = float(turn.a)
			elif turn.has("r"):
				heading += float(turn.r)
			b.velocity = Vector2.from_angle(heading) * speed
			b["facing"] = heading
			if turn.has("angular"):
				b["angular_speed"] = float(turn.angular)
			if turn.has("color"):
				b.color = Color(turn.color)
			if turn.has("shape"):
				b.shape = String(turn.shape)
				b["split_flash"] = age
			index += 1
		b["turn_i"] = index
	if b.has("gravity_vec") and age >= float(b.get("gravity_at", 0.0)):
		b.velocity = Vector2(b.velocity) + Vector2(b.gravity_vec) * factor * delta
		var cap := float(b.get("gravity_cap", 0.0)) * factor
		if cap > 0.0 and Vector2(b.velocity).length() > cap:
			b.velocity = Vector2(b.velocity).normalized() * cap
	if b.has("home_rate") and age >= float(b.get("home_at", 0.0)) and age < float(b.get("home_until", 99.0)):
		var aim: Vector2 = dm._target(Vector2(b.position)) if bool(b.get("home_live", false)) else Vector2(b.get("aim_point", dm._target(Vector2(b.position))))
		var velocity := Vector2(b.velocity)
		var wanted := (aim - Vector2(b.position)).angle()
		var step := clampf(angle_difference(velocity.angle(), wanted), -float(b.home_rate) * delta, float(b.home_rate) * delta)
		b.velocity = velocity.rotated(step)
	if b.has("spin_flip_at") and age >= float(b.spin_flip_at) and not bool(b.get("spin_flipped", false)):
		b["spin_flipped"] = true
		b["angular_speed"] = -float(b.get("angular_speed", 0.0)) * float(b.get("spin_flip_gain", 1.0))
	if b.has("angular_stop_at") and age >= float(b.angular_stop_at):
		b["angular_speed"] = 0.0
	if b.has("trail_every") and age >= float(b.get("trail_at", 0.0)):
		var next := float(b.get("trail_next", float(b.get("trail_at", 0.0))))
		if age >= next and int(b.get("trail_left", 99)) > 0:
			b["trail_next"] = next + float(b.trail_every)
			b["trail_left"] = int(b.get("trail_left", 99)) - 1
			var spec: Dictionary = b.trail
			var count := int(spec.get("count", 1))
			var heading := Vector2(b.velocity).angle()
			for k in range(count):
				var angle := heading + float(spec.get("turn", PI)) + (0.0 if count == 1 else (float(k) / (count - 1) - 0.5) * float(spec.get("spread", 0.0)))
				if bool(spec.get("random", false)):
					angle = WindGodFX.noise(int(Vector2(b.position).x * 13.0 + Vector2(b.position).y * 7.0) + int(b.trail_left) * 7, k) * TAU
				spawn(dm, b, Vector2(b.position), angle, float(spec.get("speed", 30.0)), String(spec.get("shape", "orb")), Color(spec.get("color", b.color)), spec.get("extra", {}))
	if b.has("split_at") and age >= float(b.split_at) and not bool(b.get("split_done", false)):
		b["split_done"] = true
		var spec: Dictionary = b.split
		var count := int(spec.get("count", 8))
		var base := Vector2(b.velocity).angle() + float(spec.get("offset", 0.0))
		if bool(spec.get("aim", false)):
			base = (dm._target(Vector2(b.position)) - Vector2(b.position)).angle()
		var spread := float(spec.get("spread", TAU))
		var full := is_equal_approx(spread, TAU)
		for k in range(count):
			var angle := base + (TAU * k / count if full else (0.0 if count == 1 else (float(k) / (count - 1) - 0.5) * spread))
			spawn(dm, b, Vector2(b.position), angle, float(spec.get("speed", 90.0)) * (1.0 + float(spec.get("layer_gain", 0.0)) * (k % 2)), String(spec.get("shape", "orb")), Color(spec.get("color", b.color)), spec.get("extra", {}))
		if not bool(spec.get("keep", false)):
			b["life"] = age
	return WindGodFX.advance_bullet(dm, b, before, delta)

static func spawn(dm: RefCounted, parent: Dictionary, position: Vector2, angle: float, speed: float, shape: String, color: Color, extra: Dictionary = {}) -> void:
	# Children carry the parent's already-scaled damage and speed factor, so
	# difficulty and character tuning are never applied twice.
	if dm.bullets.size() >= dm.MAX_BULLETS:
		return
	var factor := float(parent.get("speed_factor", 1.0))
	var child := {"owner": int(parent.owner), "kind": String(parent.kind), "position": position, "velocity": Vector2.from_angle(angle) * speed * factor, "age": 0.0, "life": 7.0,
		"radius": float(extra.get("radius", parent.radius)), "damage": float(parent.damage) * float(extra.get("damage_scale", 1.0)), "color": color, "shape": shape, "speed_factor": factor, "cm": true, "facing": angle,
		"arming_time": float(extra.get("arming_time", 0.0))}
	for key in extra:
		if key not in ["damage_scale", "radius", "arming_time"]:
			child[key] = extra[key]
	dm.bullets.append(child)

static func advance_beam(beam: Dictionary, delta: float) -> void:
	# The warning line shows where the sweep starts; motion begins when it fires.
	if float(beam.age) < float(beam.delay):
		return
	if beam.has("turn_rate") and float(beam.age) < float(beam.get("turn_until", 99.0)):
		beam.to = Vector2(beam.from) + (Vector2(beam.to) - Vector2(beam.from)).rotated(float(beam.turn_rate) * delta)
	if beam.has("pivot"):
		# Clock hands and revolving bars: both ends turn about a fixed pivot.
		var pivot := Vector2(beam.pivot)
		var step := float(beam.pivot_rate) * delta
		beam.from = pivot + (Vector2(beam.from) - pivot).rotated(step)
		beam.to = pivot + (Vector2(beam.to) - pivot).rotated(step)
