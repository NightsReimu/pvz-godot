extends RefCounted
# Shared motion and presentation for the Mountain of Faith bosses: bullet
# motions the original cards need (falling leaves, winders, morphing grains,
# slithering chains, lobbed shots, biorhythm speed), styled lasers with their
# warning lines, cast emitters, themed spell seals and boss auras.
# Everything here is deterministic and reads only the cast clock.

const KINDS := ["shizuha_boss", "minoriko_boss", "hina_boss", "nitori_boss", "momiji_boss", "aya_boss", "sanae_boss", "kanako_boss"]
const THEMES := {
	"shizuha_boss": {"main": Color("ef6a3f"), "accent": Color("f6c04e"), "glyph": "maple"},
	"minoriko_boss": {"main": Color("f2c35a"), "accent": Color("e5763b"), "glyph": "grain"},
	"hina_boss": {"main": Color("5fd6a4"), "accent": Color("e45a7c"), "glyph": "ribbon"},
	"nitori_boss": {"main": Color("5cc8ee"), "accent": Color("c8f1fb"), "glyph": "gear"},
	"momiji_boss": {"main": Color("ebe4d2"), "accent": Color("d0563f"), "glyph": "shield"},
	"aya_boss": {"main": Color("cfe8dc"), "accent": Color("d8574d"), "glyph": "feather"},
	"sanae_boss": {"main": Color("7fd7a8"), "accent": Color("6ac8ee"), "glyph": "star"},
	"kanako_boss": {"main": Color("ec4b5e"), "accent": Color("d9bd7a"), "glyph": "pillar"},
}
const BEAM_STYLES := {
	"harvest": [Color("f6c85a"), Color("fff3c4")],
	"crimson": [Color("ef5a4a"), Color("ffd9c8")],
	"jade": [Color("4fd39a"), Color("e6fff2")],
	"water": [Color("4cc3f0"), Color("e8fbff")],
	"wind": [Color("a9e3cf"), Color("ffffff")],
	"miracle": [Color("74d6f2"), Color("f4fff9")],
}
const INK := Color("1d1a24")
const CanonThemes = preload("res://scripts/data/touhou_fx_themes.gd")
const Glyphs = preload("res://scripts/ui/touhou_glyphs.gd")

static func theme(kind: String) -> Dictionary:
	return THEMES.get(kind, CanonThemes.CANON.get(kind, THEMES.sanae_boss))

static func has_theme(kind: String) -> bool:
	return THEMES.has(kind) or CanonThemes.CANON.has(kind)

static func noise(a: int, b: int = 0) -> float:
	var h: int = a * 374761393 + b * 668265263 + 1442695041
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(posmod(h, 100003)) / 100003.0

static func crowded(game: Control) -> bool:
	return game.touhou_danmaku != null and game.touhou_danmaku.bullets.size() >= 300

# ------------------------------------------------------------------ motion

static func advance_bullet(dm: RefCounted, b: Dictionary, before: Vector2, delta: float) -> Vector2:
	# Held (frozen) bullets keep still; nothing accumulates until they thaw.
	if bool(b.get("frozen", false)): return before
	var age := float(b.age)
	if b.has("snake_x0"):
		var s: float = maxf(0.0, float(b.snake_speed) * age - float(b.snake_lag))
		var k := float(b.snake_k)
		var amp := float(b.snake_amp)
		b.position = Vector2(float(b.snake_x0) - s, float(b.snake_y0) + amp * sin(k * s + float(b.snake_phase)))
		b.velocity = Vector2(-float(b.snake_speed), amp * k * float(b.snake_speed) * cos(k * s + float(b.snake_phase)))
		b["dormant"] = s <= 0.0 and int(b.get("segment", 0)) > 0
		return Vector2(b.position) if bool(b.dormant) else before
	if b.has("lob_from"):
		var duration: float = maxf(0.05, float(b.lob_time))
		var t := clampf(age / duration, 0.0, 1.0)
		var from := Vector2(b.lob_from)
		var to := Vector2(b.lob_to)
		var height := float(b.lob_height)
		b.position = from.lerp(to, t) - Vector2(0, height * 4.0 * t * (1.0 - t))
		b.velocity = (to - from) / duration - Vector2(0, height * 4.0 * (1.0 - 2.0 * t) / duration)
		if t >= 1.0:
			b.erase("lob_from")
			b["life"] = age + 0.06
		return before
	if b.has("gravity"):
		b.velocity = Vector2(b.velocity) + Vector2(0, float(b.gravity) * delta)
	if b.has("accel") and age >= float(b.get("accel_at", 0.0)):
		var speed := Vector2(b.velocity).length()
		var cap: float = float(b.get("accel_cap", speed * 4.0 + 1.0))
		if speed > 0.001 and speed < cap: b.velocity = Vector2(b.velocity) * minf(cap / speed, 1.0 + float(b.accel) * delta)
	if b.has("speed_wave"):
		# Hina's biorhythm: the same heading, a pulsing speed.
		if not b.has("base_speed"): b["base_speed"] = Vector2(b.velocity).length()
		var heading := Vector2(b.velocity).normalized()
		if not heading.is_zero_approx():
			b.velocity = heading * float(b.base_speed) * maxf(0.15, 1.0 + float(b.speed_wave) * sin(age * float(b.get("speed_freq", 4.0)) + float(b.get("speed_phase", 0.0))))
	if b.has("sway_amp"):
		# Fluttering leaves and undulating water drift across their heading.
		var heading := Vector2(b.velocity).normalized()
		if not heading.is_zero_approx():
			var offset := float(b.sway_amp) * sin(age * float(b.get("sway_freq", 4.0)) + float(b.get("sway_phase", 0.0)))
			b.position = Vector2(b.position) + heading.orthogonal() * (offset - float(b.get("sway_last", 0.0)))
			b["sway_last"] = offset
	if b.has("morph_at") and age >= float(b.morph_at) and not bool(b.get("morphed", false)):
		b["morphed"] = true
		b["morph_flash"] = age
		b.shape = String(b.morph_shape)
		b.velocity = dm._rotate_bullet_velocity(b, float(b.get("morph_turn", 0.0))) * float(b.get("morph_speed", 1.0))
		b["angular_speed"] = float(b.get("morph_angular", b.get("angular_speed", 0.0)))
		b.radius = float(b.radius) * float(b.get("morph_radius", 0.8))
		if b.has("morph_color"): b.color = Color(b.morph_color)
	return before

static func snake(dm: RefCounted, c: Dictionary, head: Vector2, segments: int, spacing: float, amp: float, wavelength: float, phase: float, tint: Color, body: String, head_shape: String, damage: float, scale: float, body_radius: float = 5.0) -> void:
	# Every segment follows one path with a fixed lag; until its turn a segment
	# waits hidden and harmless at the off-board head origin.
	var game: Control = dm.game
	var speed: float = game.CELL_SIZE.x * 1.05 * dm.Difficulty.attack_speed(String(c.kind), game.current_level)
	var crossing: float = game.board_size.x + spacing * segments + game.CELL_SIZE.x * 3.0
	for i in range(segments):
		var extra := {"arming_time": 0.0, "radius": maxf(2.0, (body_radius + (1.6 if i == 0 else 0.0)) * scale), "damage": damage + (3.0 if i == 0 else 0.0), "life": crossing / speed + 0.5,
			"snake_x0": head.x, "snake_y0": head.y, "snake_speed": speed, "snake_lag": spacing * i, "snake_amp": amp, "snake_k": TAU / maxf(1.0, wavelength), "snake_phase": phase, "segment": i, "dormant": i > 0}
		dm._bullet(c, Vector2(head.x, head.y + amp * sin(phase)), PI, speed, tint, head_shape if i == 0 else body, extra)

static func winder(dm: RefCounted, c: Dictionary, origin: Vector2, count: int, base: float, swing: float, phase: float, speed: float, step: float, tint: Color, shape: String, extra: Dictionary) -> void:
	# A winder: one emission frozen into a wavy line, nearest bullets slowest.
	count = maxi(2, ceili(count * dm._attack_density_for_cast(c)))
	for k in range(count):
		var angle := base + swing * sin(phase + k * 0.42)
		dm._bullet(c, origin, angle, speed + k * step, tint, shape, extra.duplicate())

static func lane_beam(dm: RefCounted, c: Dictionary, row: int, from_x: float, style: String, delay: float, width: float, damage: float, duration: float = 0.45) -> void:
	var game: Control = dm.game
	var y: float = game._row_center_y(row) - 12.0
	dm._beam(c, Vector2(from_x, y), Vector2(game.BOARD_ORIGIN.x - 8.0, y), BEAM_STYLES[style][0], delay, width, {"damage": damage, "duration": duration, "wg_style": style})

static func ray_beam(dm: RefCounted, c: Dictionary, from: Vector2, angle: float, style: String, delay: float, width: float, damage: float, reflect: bool = false, duration: float = 0.45) -> void:
	# A laser ray clipped to the lawn; with reflect it bounces once off the
	# lawn's top or bottom edge, as Sanae's brighter-night lasers do.
	var game: Control = dm.game
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var direction := Vector2.from_angle(angle)
	var reach := board.size.length() * 1.4
	var to := from + direction * reach
	if reflect and absf(direction.y) > 0.05:
		var edge_y: float = board.position.y if direction.y < 0 else board.end.y
		var t := (edge_y - from.y) / direction.y
		if t > 0.0 and t < reach:
			var bounce := from + direction * t
			if bounce.x > board.position.x:
				dm._beam(c, from, bounce, BEAM_STYLES[style][0], delay, width, {"damage": damage, "duration": duration, "wg_style": style})
				dm._beam(c, bounce, bounce + Vector2(direction.x, -direction.y) * reach, BEAM_STYLES[style][0], delay + 0.12, width, {"damage": damage, "duration": duration, "wg_style": style, "wg_bounce": true})
				return
	dm._beam(c, from, to, BEAM_STYLES[style][0], delay, width, {"damage": damage, "duration": duration, "wg_style": style})

const GUARDS := ["wallnut", "tallnut", "pumpkin"]

static func is_guard(game: Control, plant: Variant) -> bool:
	if plant == null: return false
	for component in GUARDS:
		if game._plant_has_component(plant, component): return true
	return false

static func hit_beam(dm: RefCounted, beam: Dictionary) -> void:
	# A Wind God laser pierces plants along its line, as in the originals, but
	# a nut-type plant (wall-nut, tall-nut, pumpkin or their fusions) takes the
	# hit and stops it: front walls still shelter the formation behind them.
	if beam.has("blocked_at"): return
	var game: Control = dm.game
	var from := Vector2(beam.from)
	var to := Vector2(beam.to)
	var length := from.distance_to(to)
	if length <= 0.5: return
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var reach: float = float(beam.width) * 0.5 + unit * 0.22
	var step: float = maxf(4.0, unit * 0.2)
	var hits: Array = beam.hits
	for i in range(int(length / step) + 1):
		var point := from.lerp(to, minf(1.0, i * step / length))
		var col := floori((point.x - game.BOARD_ORIGIN.x) / game.CELL_SIZE.x)
		var row := floori((point.y + 12.0 - game.BOARD_ORIGIN.y) / game.CELL_SIZE.y)
		if row < 0 or row >= game.ROWS or col < 0 or col >= game.COLS or not game._is_row_active(row): continue
		var cell := Vector2i(row, col)
		if hits.has(cell): continue
		var plant = game._targetable_plant_at(row, col)
		if plant == null or float(plant.get("health", 0.0)) <= 0.0: continue
		var center: Vector2 = game._cell_center(row, col) + Vector2(0, -12)
		if Geometry2D.get_closest_point_to_segment(center, from, to).distance_to(center) > reach: continue
		hits.append(cell)
		if String(plant.get("kind", "")) == "mirror_reed" and game._mirror_reed_reflect_boss_shot(cell, float(beam.damage)): continue
		game._damage_plant_cell(row, col, float(beam.damage), 0.0, true)
		if is_guard(game, plant):
			beam["blocked_at"] = Geometry2D.get_closest_point_to_segment(center, from, to)
			beam.to = beam.blocked_at
			return

# ------------------------------------------------------------------ drawing

static func halo(game: CanvasItem, p: Vector2, radius: float, tint: Color, strength: float = 1.0) -> void:
	game.draw_circle(p, radius * 2.0, Color(tint, tint.a * 0.10 * strength))
	game.draw_circle(p, radius * 1.45, Color(tint, tint.a * 0.18 * strength))

static func morph_flash(game: CanvasItem, b: Dictionary, p: Vector2, radius: float) -> void:
	if not b.has("morph_flash"): return
	var burst := (float(b.age) - float(b.morph_flash)) / 0.2
	if burst < 0.0 or burst > 1.0: return
	game.draw_arc(p, radius * (1.2 + burst * 1.8), 0, TAU, 12, Color(1, 1, 1, (1.0 - burst) * 0.85), 1.3, true)
	for k in range(4):
		var a := TAU * k / 4.0 + burst
		game.draw_line(p + Vector2.from_angle(a) * radius, p + Vector2.from_angle(a) * radius * (1.6 + burst * 2.0), Color(1, 1, 1, (1.0 - burst) * 0.6), 1.0, true)

static func draw_beam(game: Control, beam: Dictionary) -> void:
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var outline := PackedVector2Array([board.position, Vector2(board.end.x, board.position.y), board.end, Vector2(board.position.x, board.end.y)])
	var clipped: Array = Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([beam.from, beam.to]), outline)
	# Beams of the other Touhou bosses carry only their colour: derive a core.
	var style: Array = BEAM_STYLES.get(String(beam.get("wg_style", "")), [Color(beam.get("color", BEAM_STYLES.miracle[0])), Color(beam.get("color", BEAM_STYLES.miracle[0])).lerp(Color.WHITE, 0.78)])
	var tint: Color = style[0]
	var core: Color = style[1]
	var age := float(beam.age)
	var delay := maxf(0.01, float(beam.delay))
	var width := float(beam.width)
	var origin := Vector2(beam.from)
	if age < delay:
		# Warning line: flickering thin trace, travelling chevrons, a charging
		# origin flare. It never damages until the native delay expires.
		var progress := clampf(age / delay, 0.0, 1.0)
		var flare := width * (0.6 + progress * 1.4)
		if board.grow(30).has_point(origin):
			game.draw_circle(origin, flare, Color(tint, 0.12 + progress * 0.2))
			game.draw_circle(origin, flare * 0.45, Color(core, 0.35 + progress * 0.45))
		if clipped.is_empty() or clipped[0].size() < 2: return
		var a: Vector2 = clipped[0][0]
		var b: Vector2 = clipped[0][1]
		var flicker := 0.55 + 0.45 * sin(age * 38.0)
		game.draw_line(a, b, Color(INK, 0.25 + 0.2 * progress), maxf(2.0, width * 0.32), true)
		game.draw_line(a, b, Color(tint, (0.35 + 0.45 * progress) * flicker), maxf(1.2, width * 0.18), true)
		var length := a.distance_to(b)
		var axis := (b - a) / maxf(1.0, length)
		var side := axis.orthogonal()
		for k in range(int(length / maxf(18.0, width * 2.2))):
			var t := fposmod(k * 0.13 + age * 1.4, 1.0)
			var p := a.lerp(b, t)
			game.draw_line(p - axis * width * 0.3 + side * width * 0.32, p, Color(core, 0.35 * progress), 1.1, true)
			game.draw_line(p - axis * width * 0.3 - side * width * 0.32, p, Color(core, 0.35 * progress), 1.1, true)
		return
	if clipped.is_empty() or clipped[0].size() < 2: return
	var from: Vector2 = clipped[0][0]
	var to: Vector2 = clipped[0][1]
	var live := age - delay
	var fade := clampf((float(beam.duration) - live) / 0.18, 0.0, 1.0) * clampf(live / 0.06, 0.0, 1.0)
	var swell := 1.0 + 0.12 * sin(age * 30.0)
	game.draw_line(from, to, Color(INK, 0.35 * fade), width * 1.6 * swell, true)
	game.draw_line(from, to, Color(tint, 0.14 * fade), width * 2.6 * swell, true)
	game.draw_line(from, to, Color(tint, 0.5 * fade), width * 1.25 * swell, true)
	game.draw_line(from, to, Color(core, 0.92 * fade), maxf(1.5, width * 0.42), true)
	var length := from.distance_to(to)
	var axis := (to - from) / maxf(1.0, length)
	for k in range(int(length / maxf(14.0, width * 1.6))):
		var t := fposmod(k * 0.173 + live * 2.3, 1.0)
		var p := from.lerp(to, t) + axis.orthogonal() * sin(k * 2.1 + age * 9.0) * width * 0.6
		game.draw_circle(p, maxf(1.0, width * 0.14), Color(core, 0.7 * fade))
	game.draw_circle(from, width * 0.95, Color(tint, 0.35 * fade))
	game.draw_circle(from, width * 0.5, Color(core, 0.85 * fade))
	if beam.has("blocked_at"):
		var stop := Vector2(beam.blocked_at)
		game.draw_circle(stop, width * 1.3, Color(core, 0.45 * fade))
		for k in range(6):
			var a := axis.angle() + PI + (k - 2.5) * 0.35
			game.draw_line(stop, stop + Vector2.from_angle(a) * width * (1.6 + 0.5 * sin(age * 20.0 + k)), Color(core, 0.8 * fade), 1.4, true)
	if bool(beam.get("wg_bounce", false)):
		for k in range(5):
			var a := TAU * k / 5.0 + age * 6.0
			game.draw_line(from, from + Vector2.from_angle(a) * width * 1.4, Color(core, 0.6 * fade), 1.2, true)

static func glyph(game: CanvasItem, center: Vector2, radius: float, kind: String, angle: float, tint: Color) -> void:
	var axis := Vector2.from_angle(angle)
	var side := axis.orthogonal()
	match kind:
		"maple":
			var points := PackedVector2Array()
			for v in [Vector2(0, -1), Vector2(0.25, -0.35), Vector2(0.8, -0.65), Vector2(0.5, -0.1), Vector2(1, 0.2), Vector2(0.3, 0.35), Vector2(0.2, 0.8), Vector2(0, 0.6), Vector2(-0.2, 0.8), Vector2(-0.3, 0.35), Vector2(-1, 0.2), Vector2(-0.5, -0.1), Vector2(-0.8, -0.65), Vector2(-0.25, -0.35)]:
				points.append(center + Vector2(v).rotated(angle) * radius)
			game.draw_colored_polygon(points, tint)
		"grain":
			game.draw_line(center - axis * radius, center + axis * radius, tint, maxf(1.0, radius * 0.16), true)
			for i in range(3):
				var node := center + axis * radius * (i * 0.45 - 0.5)
				for sign in [-1, 1]:
					game.draw_line(node, node - axis * radius * 0.3 + side * sign * radius * 0.32, tint, maxf(1.0, radius * 0.2), true)
		"ribbon":
			for sign in [-1, 1]:
				game.draw_colored_polygon(PackedVector2Array([center, center + axis * radius + side * sign * radius * 0.55, center + axis * radius * 0.7 - side * sign * radius * 0.1]), tint)
			game.draw_circle(center, radius * 0.2, tint)
		"gear":
			game.draw_arc(center, radius * 0.62, 0, TAU, 14, tint, maxf(1.0, radius * 0.22), true)
			for i in range(6):
				var a := angle + TAU * i / 6.0
				game.draw_line(center + Vector2.from_angle(a) * radius * 0.7, center + Vector2.from_angle(a) * radius, tint, maxf(1.0, radius * 0.24), true)
		"shield":
			game.draw_colored_polygon(PackedVector2Array([center - axis * radius - side * radius * 0.7, center - axis * radius + side * radius * 0.7, center + axis * radius * 0.3 + side * radius * 0.6, center + axis * radius, center + axis * radius * 0.3 - side * radius * 0.6]), Color(tint, tint.a * 0.4))
			game.draw_line(center - axis * radius * 0.8, center + axis * radius * 0.8, tint, maxf(1.0, radius * 0.15), true)
		"feather":
			game.draw_colored_polygon(PackedVector2Array([center + axis * radius, center + axis * radius * 0.1 + side * radius * 0.5, center - axis * radius, center - axis * radius * 0.1 - side * radius * 0.42]), Color(tint, tint.a * 0.75))
			game.draw_line(center - axis * radius * 1.1, center + axis * radius, tint, maxf(1.0, radius * 0.12), true)
		"pillar":
			game.draw_line(center - axis * radius, center + axis * radius, tint, maxf(1.5, radius * 0.5), true)
			game.draw_line(center - axis * radius * 0.5 - side * radius * 0.4, center - axis * radius * 0.5 + side * radius * 0.4, Color(1, 0.9, 0.65, tint.a), maxf(1.0, radius * 0.18), true)
		_:
			if Glyphs.draw(game, center, radius, kind, angle, tint): return
			var points := PackedVector2Array()
			for i in range(10):
				points.append(center + Vector2.from_angle(angle - PI * 0.5 + TAU * i / 10.0) * radius * (1.0 if i % 2 == 0 else 0.45))
			game.draw_colored_polygon(points, tint)

static func magic_circle(game: CanvasItem, center: Vector2, radius: float, kind: String, turn: float, alpha: float, flatten: float = 1.0) -> void:
	# A themed sigil: two counter-rotating rings, an inscribed star and glyphs.
	var t: Dictionary = theme(kind)
	var main: Color = t.main
	var accent: Color = t.accent
	if alpha <= 0.01: return
	var ring := PackedVector2Array()
	for k in range(49):
		var a := TAU * k / 48.0 + turn
		ring.append(center + Vector2(cos(a) * radius, sin(a) * radius * flatten))
	game.draw_polyline(ring, Color(main, 0.55 * alpha), maxf(1.0, radius * 0.035), true)
	var inner := PackedVector2Array()
	for k in range(37):
		var a := TAU * k / 36.0 - turn * 1.6
		inner.append(center + Vector2(cos(a) * radius * 0.78, sin(a) * radius * 0.78 * flatten))
	game.draw_polyline(inner, Color(accent, 0.45 * alpha), maxf(1.0, radius * 0.022), true)
	var star := PackedVector2Array()
	for k in range(6):
		var a := -PI * 0.5 + TAU * (k * 2 % 5) / 5.0 + turn * 0.5
		star.append(center + Vector2(cos(a) * radius * 0.74, sin(a) * radius * 0.74 * flatten))
	game.draw_polyline(star, Color(main, 0.3 * alpha), maxf(1.0, radius * 0.018), true)
	for k in range(8):
		var a := TAU * k / 8.0 + turn
		var p := center + Vector2(cos(a) * radius * 0.89, sin(a) * radius * 0.89 * flatten)
		glyph(game, p, radius * 0.09, String(t.glyph), a + PI * 0.5, Color(accent if k % 2 else main, 0.85 * alpha))

static func draw_effect(game: Control, effect: Dictionary) -> bool:
	var shape := String(effect.get("shape", ""))
	if not shape.ends_with("_spell_seal"): return false
	var kind := shape.trim_suffix("_spell_seal") + "_boss"
	if not has_theme(kind) or kind == "kanako_boss": return false
	var ratio := clampf(float(effect.time) / maxf(0.01, float(effect.duration)), 0.0, 1.0)
	var grow := 1.0 - ratio
	var p := Vector2(effect.position)
	var radius := float(effect.get("radius", 72.0)) * (0.55 + grow * 0.8)
	magic_circle(game, p, radius, kind, grow * 1.6, ratio)
	var t: Dictionary = theme(kind)
	for k in range(12):
		var a := TAU * k / 12.0 + grow
		var d := radius * (0.9 + grow * 0.7)
		game.draw_line(p + Vector2.from_angle(a) * radius * 0.6, p + Vector2.from_angle(a) * d, Color(t.accent, ratio * 0.45), 1.4, true)
	return true

static func draw_boss_aura(game: Control, center: Vector2, boss: Dictionary, behind: bool) -> void:
	# Formal cards: a ground sigil, a declaration flash and rising motes.
	if bool(boss.get("portrait", false)): return
	var kind := String(boss.get("kind", ""))
	var card: Dictionary = boss.get("touhou_card", {})
	var remaining := float(boss.get("touhou_cast_remaining", 0.0))
	if remaining <= 0.0 or card.is_empty(): return
	var formal := String(card.get("origin", "")) != "nonspell"
	var duration := maxf(0.01, float(boss.get("touhou_cast_duration", remaining)))
	var elapsed := duration - remaining
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var t: Dictionary = theme(kind)
	var foot := center + Vector2(0, unit * 0.22)
	if behind:
		if formal:
			var appear := clampf(elapsed / 0.5, 0.0, 1.0)
			magic_circle(game, foot, unit * (0.62 + 0.08 * sin(elapsed * 2.0)), kind, elapsed * 0.9, appear, 0.32)
			game.draw_circle(center + Vector2(0, -unit * 0.45), unit * 0.62, Color(t.main, 0.07 + 0.05 * sin(elapsed * 4.0)))
			if bool(card.get("last_spell", false)):
				for k in range(3):
					game.draw_arc(center + Vector2(0, -unit * 0.45), unit * (0.7 + k * 0.16 + 0.05 * sin(elapsed * 3.0 + k)), elapsed * (1.2 - k * 0.5), elapsed * (1.2 - k * 0.5) + PI * 1.3, 32, Color(t.accent, 0.35 - k * 0.08), maxf(1.0, unit * 0.025), true)
		else:
			game.draw_arc(foot, unit * 0.42, 0, TAU, 28, Color(t.main, 0.25), maxf(1.0, unit * 0.02), true)
		return
	if not formal: return
	# Front layer: declaration burst and themed motes drifting upward.
	if elapsed < 0.6:
		var burst := elapsed / 0.6
		game.draw_arc(center + Vector2(0, -unit * 0.45), unit * (0.3 + burst * 1.4), 0, TAU, 36, Color(t.accent, (1.0 - burst) * 0.8), maxf(1.5, unit * 0.05 * (1.0 - burst)), true)
		for k in range(10):
			var a := TAU * k / 10.0 + burst
			var p := center + Vector2(0, -unit * 0.45) + Vector2.from_angle(a) * unit * (0.4 + burst * 1.2)
			game.draw_line(p, p + Vector2.from_angle(a) * unit * 0.22 * (1.0 - burst), Color(1, 1, 1, (1.0 - burst) * 0.7), 1.4, true)
	for k in range(6):
		var rise := fposmod(elapsed * 0.45 + k * 0.17, 1.0)
		var p := center + Vector2((noise(k, 7) - 0.5) * unit * 1.1, unit * 0.2 - rise * unit * 1.5)
		glyph(game, p, unit * 0.06 * (1.0 - rise * 0.4), String(t.glyph), elapsed * 2.0 + k, Color(t.accent if k % 2 else t.main, (1.0 - rise) * 0.7))

static func draw_sprite_glow(game: CanvasItem, texture: Texture2D, rect: Rect2, tint: Color, strength: float) -> void:
	if texture == null or strength <= 0.01: return
	var spread := maxf(2.0, rect.size.x * 0.012)
	for offset in [Vector2(spread, 0), Vector2(-spread, 0), Vector2(0, spread), Vector2(0, -spread)]:
		game.draw_texture_rect(texture, Rect2(rect.position + offset, rect.size), false, Color(tint, 0.16 * strength))
