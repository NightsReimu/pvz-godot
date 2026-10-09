extends RefCounted
# Drawing for the shared Touhou bullet shapes (every boss outside Mountain of
# Faith). The look follows the originals: a coloured rim around a white core,
# a dark ink outline so bullets read on grass, a soft glow, and per-shape
# motion (spinning stars, flapping butterflies, flickering fire). Visuals are
# about 1.25x the collision radius; collisions are unchanged.

const INK := Color("1d1a24")
const WHITE := Color(1, 1, 1)
const VISUAL := 1.25
const SHAPES := ["orb", "big", "ring", "rice", "knife", "kunai", "ice", "ofuda", "star", "note", "butterfly", "moth", "petal", "dream_orb", "fire", "scale", "needle", "arrow", "drop", "leaf", "rock", "heart", "firefly", "ghost", "bat", "jewel"]

static func handles(shape: String) -> bool:
	return shape in SHAPES

static func _axis(b: Dictionary) -> Vector2:
	var v := Vector2(b.velocity)
	if v.length_squared() < 0.0001:
		return Vector2.from_angle(float(b.get("facing", PI)))
	return v.normalized()

static func _outline(game: CanvasItem, points: PackedVector2Array, fill: Color, edge: Color, width: float) -> void:
	game.draw_colored_polygon(points, fill)
	points.append(points[0])
	game.draw_polyline(points, edge, width, true)

static func _ellipse(center: Vector2, axis: Vector2, a: float, c: float, steps: int = 12) -> PackedVector2Array:
	var side := axis.orthogonal()
	var points := PackedVector2Array()
	for i in range(steps):
		var t := TAU * i / steps
		points.append(center + axis * cos(t) * a + side * sin(t) * c)
	return points

static func draw(game: CanvasItem, b: Dictionary, crowded: bool, time_stopped: bool) -> void:
	var shape := String(b.shape)
	var p := Vector2(b.position)
	var tint := Color(b.color)
	var r := float(b.radius) * VISUAL * float(b.get("visual_scale", 1.0))
	var age := float(b.age)
	var armed := age >= float(b.get("arming_time", 0.0))
	var frozen := bool(b.get("frozen", false)) or time_stopped
	if bool(b.get("whiten", false)) and frozen:
		tint = Color(0.93, 0.97, 1.0, tint.a)
	if not armed:
		# Harmless while appearing: a faint body inside a spawning ring.
		var grow := clampf(age / maxf(0.01, float(b.arming_time)), 0.0, 1.0)
		game.draw_arc(p, r * (2.2 - grow), 0, TAU, 12, Color(tint, 0.5 * (1.0 - grow) + 0.15), 1.2, true)
		tint.a *= 0.35 + 0.3 * grow
	var axis := _axis(b)
	var side := axis.orthogonal()
	if crowded:
		_draw_fast(game, shape, p, axis, side, r, tint)
	else:
		match shape:
			"orb", "big", "dream_orb":
				var big := shape == "big" or r >= 11.0
				game.draw_circle(p, r * (2.0 if big else 1.75), Color(tint, tint.a * (0.16 if big else 0.12)))
				game.draw_circle(p, r + 1.6, Color(INK, tint.a * 0.85))
				game.draw_circle(p, r, tint)
				if big:
					game.draw_circle(p, r * 0.78, tint.lerp(WHITE, 0.35))
				game.draw_circle(p, r * (0.5 if big else 0.56), Color(WHITE, tint.a * 0.95))
				game.draw_circle(p - Vector2(r, r) * 0.28, r * 0.16, Color(WHITE, tint.a))
			"ring":
				game.draw_circle(p, r * 1.7, Color(tint, tint.a * 0.12))
				game.draw_arc(p, r, 0, TAU, 16, Color(INK, tint.a * 0.85), r * 0.62, true)
				game.draw_arc(p, r, 0, TAU, 16, tint, r * 0.42, true)
				game.draw_arc(p, r, 0, TAU, 16, Color(WHITE, tint.a * 0.8), maxf(1.0, r * 0.14), true)
			"rice":
				game.draw_circle(p, r * 1.5, Color(tint, tint.a * 0.1))
				_outline(game, _ellipse(p, axis, r * 1.55, r * 0.68), tint, Color(INK, tint.a * 0.85), 1.3)
				game.draw_line(p - axis * r * 0.8, p + axis * r * 0.8, Color(WHITE, tint.a * 0.95), maxf(1.0, r * 0.32), true)
			"kunai":
				var body := PackedVector2Array([p + axis * r * 2.0, p + axis * r * 0.4 + side * r * 0.75, p - axis * r * 1.0 + side * r * 0.32, p - axis * r * 1.5, p - axis * r * 1.0 - side * r * 0.32, p + axis * r * 0.4 - side * r * 0.75])
				_outline(game, body, tint, Color(INK, tint.a * 0.85), 1.2)
				game.draw_line(p - axis * r * 0.9, p + axis * r * 1.5, Color(WHITE, tint.a * 0.9), maxf(1.0, r * 0.26), true)
			"knife":
				var blade := PackedVector2Array([p + axis * r * 2.3, p + axis * r * 0.2 + side * r * 0.52, p - axis * r * 0.5 + side * r * 0.42, p - axis * r * 0.5 - side * r * 0.42, p + axis * r * 0.2 - side * r * 0.22])
				_outline(game, blade, Color(0.9, 0.94, 1.0, tint.a), Color(tint.darkened(0.2), tint.a), 1.4)
				game.draw_line(p + axis * r * 1.9, p - axis * r * 0.3, Color(WHITE, tint.a), 1.0, true)
				game.draw_line(p - axis * r * 0.55 - side * r * 0.7, p - axis * r * 0.55 + side * r * 0.7, tint, maxf(1.2, r * 0.3), true)
				game.draw_line(p - axis * r * 0.6, p - axis * r * 1.5, tint.darkened(0.25), maxf(1.4, r * 0.38), true)
			"needle":
				game.draw_line(p - axis * r * 2.4, p + axis * r * 2.4, Color(INK, tint.a * 0.8), maxf(2.2, r * 0.7), true)
				game.draw_line(p - axis * r * 2.2, p + axis * r * 2.2, tint, maxf(1.3, r * 0.42), true)
				game.draw_line(p - axis * r * 1.2, p + axis * r * 2.0, Color(WHITE, tint.a * 0.9), 1.0, true)
			"ice":
				var shard := PackedVector2Array([p + axis * r * 1.9, p + axis * r * 0.3 + side * r * 0.85, p - axis * r * 1.3 + side * r * 0.45, p - axis * r * 1.6, p - axis * r * 1.3 - side * r * 0.45, p + axis * r * 0.3 - side * r * 0.85])
				game.draw_circle(p, r * 1.7, Color(tint, tint.a * 0.12))
				_outline(game, shard, tint.lerp(WHITE, 0.25), Color(INK, tint.a * 0.75), 1.2)
				game.draw_line(p - axis * r * 1.2, p + axis * r * 1.6, Color(WHITE, tint.a * 0.95), 1.1, true)
				game.draw_line(p + side * r * 0.6, p - side * r * 0.6 + axis * r * 0.2, Color(WHITE, tint.a * 0.6), 1.0, true)
			"ofuda":
				var paper := PackedVector2Array([p + axis * r * 1.5 + side * r * 0.72, p - axis * r * 1.5 + side * r * 0.72, p - axis * r * 1.5 - side * r * 0.72, p + axis * r * 1.5 - side * r * 0.72])
				_outline(game, paper, Color(1, 0.97, 0.9, tint.a), Color(tint, tint.a), maxf(1.4, r * 0.3))
				game.draw_line(p - axis * r * 0.8, p + axis * r * 0.8, Color(tint.darkened(0.15), tint.a), maxf(1.2, r * 0.3), true)
				game.draw_circle(p + axis * r * 0.15, r * 0.24, Color(tint, tint.a))
			"star":
				var spin := age * 3.2 + float(b.get("spin_phase", 0.0))
				var star := PackedVector2Array()
				for i in range(10):
					star.append(p + Vector2.from_angle(spin - PI * 0.5 + TAU * i / 10.0) * r * (1.6 if i % 2 == 0 else 0.72))
				game.draw_circle(p, r * 1.9, Color(tint, tint.a * 0.13))
				_outline(game, star, tint, Color(INK, tint.a * 0.8), 1.2)
				game.draw_circle(p, r * 0.42, Color(WHITE, tint.a * 0.95))
			"note":
				var bob := Vector2(0, sin(age * 7.0 + float(b.get("spin_phase", 0.0))) * r * 0.25)
				var head := p + bob
				var stem := head + Vector2(r * 0.85, -r * 2.1)
				game.draw_circle(head, r * 1.6, Color(tint, tint.a * 0.12))
				game.draw_line(head + Vector2(r * 0.85, 0), stem, Color(INK, tint.a), 3.6, true)
				game.draw_line(head + Vector2(r * 0.85, 0), stem, tint, 1.9, true)
				game.draw_line(stem, stem + Vector2(r * 0.95, r * 0.65), tint, 2.0, true)
				_outline(game, _ellipse(head, Vector2.from_angle(-0.45), r * 1.1, r * 0.78, 10), tint, Color(INK, tint.a * 0.9), 1.3)
				game.draw_circle(head - Vector2(r * 0.3, r * 0.2), r * 0.3, Color(WHITE, tint.a * 0.9))
			"butterfly", "moth":
				var flap := 0.55 + 0.45 * absf(sin(age * (11.0 if shape == "butterfly" else 7.0) + float(b.get("spin_phase", 0.0))))
				var wing_tint := tint.lerp(WHITE, 0.18)
				game.draw_circle(p, r * 2.0, Color(tint, tint.a * 0.12))
				for sign in [-1.0, 1.0]:
					var upper := PackedVector2Array([p + axis * r * 0.2, p + axis * r * 1.25 + side * sign * r * 1.5 * flap, p - axis * r * 0.15 + side * sign * r * 1.7 * flap])
					var lower := PackedVector2Array([p - axis * r * 0.1, p - axis * r * 0.4 + side * sign * r * 1.45 * flap, p - axis * r * 1.25 + side * sign * r * 0.7 * flap])
					_outline(game, upper, wing_tint, Color(INK, tint.a * 0.7), 1.0)
					_outline(game, lower, tint, Color(INK, tint.a * 0.7), 1.0)
				game.draw_line(p - axis * r * 0.9, p + axis * r * 0.8, Color(INK, tint.a), maxf(1.5, r * 0.32), true)
				game.draw_circle(p + axis * r * 0.15, r * 0.24, Color(WHITE, tint.a))
			"petal":
				var spin := age * 2.6 + float(b.get("spin_phase", 0.0))
				var petal_axis := Vector2.from_angle(spin)
				var petal_side := petal_axis.orthogonal()
				var leaf := PackedVector2Array([p + petal_axis * r * 1.5 + petal_side * r * 0.25, p + petal_axis * r * 1.15, p + petal_axis * r * 1.5 - petal_side * r * 0.25, p + petal_axis * r * 0.4 - petal_side * r * 0.8, p - petal_axis * r * 1.0 - petal_side * r * 0.3, p - petal_axis * r * 1.2, p - petal_axis * r * 1.0 + petal_side * r * 0.3, p + petal_axis * r * 0.4 + petal_side * r * 0.8])
				game.draw_circle(p, r * 1.7, Color(tint, tint.a * 0.12))
				_outline(game, leaf, tint.lerp(WHITE, 0.2), Color(tint.darkened(0.45), tint.a * 0.85), 1.1)
				game.draw_line(p - petal_axis * r * 0.8, p + petal_axis * r * 0.7, Color(WHITE, tint.a * 0.6), 1.0, true)
			"fire":
				var flicker := 0.85 + 0.15 * sin(age * 31.0 + float(b.get("spin_phase", 0.0)))
				var flame := PackedVector2Array([p + axis * r * 1.1, p + axis * r * 0.4 + side * r * 0.95, p - axis * r * 0.9 + side * r * 0.6, p - axis * r * 2.4 * flicker, p - axis * r * 0.9 - side * r * 0.6, p + axis * r * 0.4 - side * r * 0.95])
				game.draw_circle(p, r * 2.0, Color(tint, tint.a * 0.16))
				_outline(game, flame, tint, Color(tint.darkened(0.5), tint.a * 0.8), 1.2)
				game.draw_circle(p + axis * r * 0.2, r * 0.6, Color(1, 0.95, 0.7, tint.a * 0.95))
			"scale":
				var scale_shape := PackedVector2Array([p + axis * r * 1.5, p - axis * r * 1.0 + side * r * 1.0, p - axis * r * 0.55, p - axis * r * 1.0 - side * r * 1.0])
				_outline(game, scale_shape, tint, Color(INK, tint.a * 0.85), 1.2)
				game.draw_line(p + axis * r * 1.0, p - axis * r * 0.4, Color(WHITE, tint.a * 0.9), 1.1, true)
			"arrow":
				game.draw_line(p - axis * r * 2.6, p + axis * r * 0.6, Color(INK, tint.a * 0.8), maxf(2.4, r * 0.6), true)
				game.draw_line(p - axis * r * 2.5, p + axis * r * 0.6, tint.lerp(WHITE, 0.4), maxf(1.2, r * 0.32), true)
				_outline(game, PackedVector2Array([p + axis * r * 1.9, p + axis * r * 0.3 + side * r * 0.75, p + axis * r * 0.3 - side * r * 0.75]), tint, Color(INK, tint.a * 0.85), 1.1)
				for sign in [-1.0, 1.0]:
					game.draw_line(p - axis * r * 2.0, p - axis * r * 2.7 + side * sign * r * 0.6, tint, 1.4, true)
			"drop":
				var drop := PackedVector2Array()
				for i in range(14):
					var t := TAU * i / 14.0
					var swell := 1.0 - 0.6 * maxf(0.0, -cos(t))
					drop.append(p + axis * cos(t) * r * (1.0 if cos(t) > 0 else 1.7) + side * sin(t) * r * swell)
				game.draw_circle(p, r * 1.7, Color(tint, tint.a * 0.12))
				_outline(game, drop, tint, Color(INK, tint.a * 0.8), 1.2)
				game.draw_circle(p + axis * r * 0.2 - side * r * 0.3, r * 0.3, Color(WHITE, tint.a * 0.9))
			"leaf":
				var spin := age * 2.0 + float(b.get("spin_phase", 0.0))
				var leaf_axis := Vector2.from_angle(spin)
				_outline(game, _ellipse(p, leaf_axis, r * 1.6, r * 0.7, 10), tint, Color(tint.darkened(0.5), tint.a * 0.85), 1.1)
				game.draw_line(p - leaf_axis * r * 1.5, p + leaf_axis * r * 1.5, Color(tint.lightened(0.5), tint.a), 1.0, true)
			"rock":
				var spin := age * 1.4 + float(b.get("spin_phase", 0.0))
				var rock := PackedVector2Array()
				for i in range(7):
					rock.append(p + Vector2.from_angle(spin + TAU * i / 7.0) * r * (1.05 + 0.25 * sin(i * 2.7)))
				_outline(game, rock, tint, Color(INK, tint.a * 0.85), 1.3)
				game.draw_circle(p - Vector2(r, r) * 0.3, r * 0.3, Color(tint.lightened(0.45), tint.a))
			"heart":
				var heart := PackedVector2Array()
				for i in range(16):
					var t := TAU * i / 16.0
					var hx := 16.0 * pow(sin(t), 3)
					var hy := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
					heart.append(p + Vector2(hx, -hy) * r / 14.0)
				game.draw_circle(p, r * 1.7, Color(tint, tint.a * 0.12))
				_outline(game, heart, tint, Color(INK, tint.a * 0.85), 1.2)
				game.draw_circle(p + Vector2(-r * 0.35, -r * 0.3), r * 0.25, Color(WHITE, tint.a * 0.9))
			"firefly":
				var pulse := 0.6 + 0.4 * sin(age * 9.0 + float(b.get("spin_phase", 0.0)))
				game.draw_circle(p, r * (2.2 + pulse * 0.6), Color(tint, tint.a * 0.14 * pulse + 0.05))
				game.draw_circle(p, r * 1.05, Color(tint, tint.a))
				game.draw_circle(p, r * 0.55, Color(1, 1, 0.85, tint.a))
				for sign in [-1.0, 1.0]:
					game.draw_line(p - axis * r * 0.2, p - axis * r * 0.9 + side * sign * r * 1.1, Color(WHITE, tint.a * 0.45), 1.0, true)
			"ghost":
				var wave := sin(age * 8.0 + float(b.get("spin_phase", 0.0)))
				game.draw_circle(p, r * 2.0, Color(tint, tint.a * 0.15))
				var tail := PackedVector2Array([p + side * r * 0.9, p - axis * r * 1.6 + side * r * 0.4 * wave, p - axis * r * 2.6 - side * r * 0.2 * wave, p - axis * r * 1.4 - side * r * 0.5, p - side * r * 0.9])
				game.draw_colored_polygon(tail, Color(tint, tint.a * 0.55))
				game.draw_circle(p, r + 1.2, Color(INK, tint.a * 0.5))
				game.draw_circle(p, r, tint.lerp(WHITE, 0.3))
				game.draw_circle(p, r * 0.55, Color(WHITE, tint.a * 0.95))
			"bat":
				var flap := sin(age * 14.0 + float(b.get("spin_phase", 0.0)))
				var wing := PackedVector2Array([p + axis * r * 0.6, p + side * r * (1.9 + 0.3 * flap) + axis * r * 0.3, p + side * r * 1.4 - axis * r * 0.4, p + side * r * 0.6, p - axis * r * 0.7, p - side * r * 0.6, p - side * r * 1.4 - axis * r * 0.4, p - side * r * (1.9 + 0.3 * flap) + axis * r * 0.3])
				game.draw_circle(p, r * 1.8, Color(tint, tint.a * 0.14))
				_outline(game, wing, tint, Color(INK, tint.a * 0.9), 1.1)
				game.draw_circle(p + axis * r * 0.25, r * 0.22, Color(1, 0.9, 0.5, tint.a))
			"jewel":
				var spin := age * 2.2 + float(b.get("spin_phase", 0.0))
				var gem := PackedVector2Array()
				for i in range(6):
					gem.append(p + Vector2.from_angle(spin + TAU * i / 6.0) * r * 1.25)
				game.draw_circle(p, r * 2.0, Color(tint, tint.a * 0.16))
				_outline(game, gem, tint, Color(INK, tint.a * 0.85), 1.2)
				game.draw_colored_polygon(PackedVector2Array([gem[0], gem[1], p]), Color(WHITE, tint.a * 0.45))
				game.draw_circle(p, r * 0.35, Color(WHITE, tint.a * 0.9))
	if frozen:
		game.draw_arc(p, r + 3.0, 0, TAU, 12, Color(0.86, 0.98, 1.0, 0.7), 1.0, true)
	if b.has("morph_flash") or b.has("split_flash"):
		var burst := (age - float(b.get("split_flash", b.get("morph_flash", -9.0)))) / 0.22
		if burst >= 0.0 and burst <= 1.0:
			game.draw_arc(p, r * (1.3 + burst * 1.8), 0, TAU, 12, Color(1, 1, 1, (1.0 - burst) * 0.8), 1.3, true)

static func _draw_fast(game: CanvasItem, shape: String, p: Vector2, axis: Vector2, side: Vector2, r: float, tint: Color) -> void:
	# Dense volleys keep each silhouette with one or two draw calls.
	match shape:
		"orb", "big", "dream_orb", "ring", "firefly", "ghost", "jewel":
			game.draw_circle(p, r + 1.2, Color(INK, tint.a * 0.7))
			game.draw_circle(p, r, tint)
			game.draw_circle(p, r * 0.5, Color(WHITE, tint.a * 0.9))
		"ofuda":
			game.draw_colored_polygon(PackedVector2Array([p + axis * r * 1.45 + side * r * 0.7, p - axis * r * 1.45 + side * r * 0.7, p - axis * r * 1.45 - side * r * 0.7, p + axis * r * 1.45 - side * r * 0.7]), Color(1, 0.96, 0.9, tint.a))
			game.draw_line(p - axis * r, p + axis * r, tint, maxf(1.3, r * 0.4), true)
		"star", "note", "heart":
			game.draw_circle(p, r * 1.1, tint)
			game.draw_circle(p, r * 0.45, Color(WHITE, tint.a))
		"butterfly", "moth", "bat":
			game.draw_circle(p + side * r * 0.75, r * 0.85, tint)
			game.draw_circle(p - side * r * 0.75, r * 0.85, tint)
		_:
			game.draw_colored_polygon(PackedVector2Array([p + axis * r * 1.7, p + side * r * 0.62, p - axis * r * 1.3, p - side * r * 0.62]), tint)
			game.draw_line(p - axis * r * 0.6, p + axis * r * 0.9, Color(WHITE, tint.a * 0.85), 1.0, true)

static func draw_effect(game: CanvasItem, effect: Dictionary) -> void:
	# Short cast flourishes: blinks, warps, ripples and ground tremors.
	var ratio := clampf(float(effect.time) / maxf(0.01, float(effect.duration)), 0.0, 1.0)
	var grow := 1.0 - ratio
	var p := Vector2(effect.position)
	var radius := float(effect.get("radius", 50.0))
	var tint := Color(effect.get("color", Color.WHITE))
	match String(effect.shape):
		"canon_blink", "canon_warp":
			game.draw_circle(p, radius * (0.3 + grow * 0.5), Color(tint, tint.a * 0.25 * ratio))
			game.draw_arc(p, radius * (0.4 + grow * 0.8), 0, TAU, 24, Color(tint, tint.a * ratio), 2.0, true)
			for k in range(8):
				var a := TAU * k / 8.0 + grow * 2.0
				game.draw_line(p + Vector2.from_angle(a) * radius * 0.3, p + Vector2.from_angle(a) * radius * (0.5 + grow * 0.7), Color(1, 1, 1, ratio * 0.7), 1.4, true)
		"canon_ripple":
			for k in range(3):
				game.draw_arc(p, radius * (0.3 + grow * 1.3 + k * 0.25), 0, TAU, 32, Color(tint, tint.a * ratio * (1.0 - k * 0.3)), 1.6, true)
		"canon_quake":
			for k in range(6):
				var a := TAU * k / 6.0 + float(k) * 0.4
				var crack := p + Vector2.from_angle(a) * radius * (0.2 + grow * 0.8)
				game.draw_line(p + Vector2.from_angle(a) * radius * 0.15, crack, Color(tint, tint.a * ratio), 2.0, true)
			game.draw_arc(p, radius * (0.4 + grow), 0, TAU, 28, Color(tint, tint.a * ratio * 0.6), 2.5, true)
