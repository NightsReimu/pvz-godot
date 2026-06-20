extends RefCounted
class_name GameTheme


static func ease_ui(value: float) -> float:
	var t = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func ease_out(value: float) -> float:
	var t = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


static func ease_in_out(value: float) -> float:
	var t = clampf(value, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


static func progress_fill_rect(rect: Rect2, ratio: float) -> Rect2:
	return Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y))


static func scroll_knob_rect(track_rect: Rect2, view_length: float, content_length: float, scroll: float, min_length: float = 46.0) -> Rect2:
	if content_length <= 0.0 or view_length <= 0.0 or content_length <= view_length:
		return track_rect
	var max_scroll = maxf(content_length - view_length, 0.001)
	var knob_length = maxf(min_length, track_rect.size.y * (view_length / content_length))
	var ratio = clampf(scroll / max_scroll, 0.0, 1.0)
	return Rect2(
		Vector2(track_rect.position.x, track_rect.position.y + (track_rect.size.y - knob_length) * ratio),
		Vector2(track_rect.size.x, knob_length)
	)


# --- Gradient & Color Helpers ---

static func draw_gradient_rect_v(canvas: CanvasItem, rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	canvas.draw_polygon(
		PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0.0), rect.position + rect.size, rect.position + Vector2(0.0, rect.size.y)]),
		PackedColorArray([top_color, top_color, bottom_color, bottom_color])
	)


static func draw_gradient_rect_h(canvas: CanvasItem, rect: Rect2, left_color: Color, right_color: Color) -> void:
	canvas.draw_polygon(
		PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0.0), rect.position + rect.size, rect.position + Vector2(0.0, rect.size.y)]),
		PackedColorArray([left_color, right_color, right_color, left_color])
	)


# --- Soft Shadow ---

static func draw_soft_shadow(canvas: CanvasItem, rect: Rect2, shadow_color: Color, layers: int = 3, spread: float = 8.0, offset_y: float = 6.0) -> void:
	for i in range(layers):
		var t = float(i + 1) / float(layers)
		var grow = spread * t
		var alpha = shadow_color.a * (1.0 - t * 0.6)
		var sr = Rect2(rect.position + Vector2(-grow * 0.5, offset_y * t), rect.size + Vector2(grow, grow * 0.6))
		canvas.draw_rect(sr, Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha), true)


# --- Glow Circle ---

static func draw_glow_circle(canvas: CanvasItem, center: Vector2, radius: float, color: Color, glow_layers: int = 3) -> void:
	for i in range(glow_layers, 0, -1):
		var t = float(i) / float(glow_layers)
		var r = radius * (1.0 + t * 0.8)
		canvas.draw_circle(center, r, Color(color.r, color.g, color.b, color.a * (1.0 - t) * 0.3))
	canvas.draw_circle(center, radius, color)
	canvas.draw_circle(center, radius * 0.6, Color(color.r * 0.5 + 0.5, color.g * 0.5 + 0.5, color.b * 0.5 + 0.5, color.a * 0.4))


# --- Rounded Panel (improved draw_panel_shell) ---

static func draw_rounded_panel(canvas: CanvasItem, rect: Rect2, fill_color: Color, border_color: Color, corner_radius: float = 12.0, shadow_alpha: float = 0.22, accent_alpha: float = 0.16) -> void:
	# Soft shadow
	draw_soft_shadow(canvas, rect, Color(0.0, 0.0, 0.0, shadow_alpha), 3, 12.0, 8.0)
	# Main fill with gradient
	var top_color = fill_color.lerp(Color.WHITE, 0.08)
	var bottom_color = fill_color.darkened(0.08)
	draw_gradient_rect_v(canvas, rect, top_color, bottom_color)
	# Top highlight band
	var highlight_rect = Rect2(rect.position + Vector2(3.0, 3.0), Vector2(maxf(0.0, rect.size.x - 6.0), maxf(6.0, rect.size.y * 0.12)))
	canvas.draw_rect(highlight_rect, Color(1.0, 1.0, 1.0, accent_alpha * 0.6), true)
	# Bottom darkened band
	var bottom_band = Rect2(rect.position + Vector2(0.0, rect.size.y * 0.78), Vector2(rect.size.x, rect.size.y * 0.22))
	canvas.draw_rect(bottom_band, Color(0.0, 0.0, 0.0, 0.06), true)
	# Inner glow line
	canvas.draw_rect(rect.grow(-2.0), Color(1.0, 1.0, 1.0, accent_alpha * 0.12), false, 1.0)
	# Border
	canvas.draw_rect(rect, border_color, false, 2.0)
	# Corner accents (simulate rounded feel with small circles at corners)
	var cr = minf(corner_radius, minf(rect.size.x, rect.size.y) * 0.3)
	if cr > 4.0:
		var corners = [
			rect.position + Vector2(cr, cr),
			rect.position + Vector2(rect.size.x - cr, cr),
			rect.position + Vector2(rect.size.x - cr, rect.size.y - cr),
			rect.position + Vector2(cr, rect.size.y - cr),
		]
		for c in corners:
			canvas.draw_circle(c, cr * 0.3, Color(1.0, 1.0, 1.0, accent_alpha * 0.08))


# --- Legacy panel shell (kept for compatibility, delegates to rounded) ---

static func draw_panel_shell(canvas: CanvasItem, rect: Rect2, fill_color: Color, border_color: Color, shadow_alpha: float = 0.22, accent_alpha: float = 0.16) -> void:
	draw_rounded_panel(canvas, rect, fill_color, border_color, 10.0, shadow_alpha, accent_alpha)


# --- Fancy Button (glossy, with hover/press states) ---

static func draw_fancy_button(canvas: CanvasItem, rect: Rect2, label: String, font: Font, fill_color: Color, border_color: Color, hovered: bool = false, pressed: bool = false, font_size: int = 22) -> void:
	# Subtle hover lift: grow slightly and brighten; pressed darkens.
	var draw_rect = rect
	var lift = 0.0
	if pressed:
		lift = -1.0
	elif hovered:
		lift = -2.0
		draw_rect = rect.grow_individual(1.0, 1.0, 1.0, 1.0)
	# Soft drop shadow (slightly stronger on hover)
	var shadow_offset_y = 6.0 - lift
	var shadow_alpha = 0.26 if hovered else 0.2
	draw_soft_shadow(canvas, draw_rect, Color(0.0, 0.0, 0.0, shadow_alpha), 4, 11.0, shadow_offset_y)
	# Hover halo glow ring
	if hovered:
		var glow_pulse = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.005)
		for gi in range(3):
			var gt = float(gi + 1) / 3.0
			canvas.draw_rect(draw_rect.grow(2.0 + gt * 4.0), Color(1.0, 0.96, 0.72, 0.05 * glow_pulse * (1.0 - gt)), false, 2.0)
	# Fill: vertical gradient (top brighter, bottom darker) — press darkens whole thing
	var bright = 0.14 if hovered else 0.08
	var dark_amt = 0.16 if not pressed else 0.28
	var top = fill_color.lerp(Color.WHITE, bright)
	var bottom = fill_color.darkened(dark_amt)
	draw_gradient_rect_v(canvas, draw_rect, top, bottom)
	# Top glossy highlight band (rounded feel)
	var gloss_h = maxf(8.0, draw_rect.size.y * 0.4)
	var gloss_rect = Rect2(draw_rect.position + Vector2(3.0, 2.0), Vector2(maxf(0.0, draw_rect.size.x - 6.0), gloss_h))
	canvas.draw_rect(gloss_rect, Color(1.0, 1.0, 1.0, 0.22 if hovered else 0.16), true)
	# Gloss fade line under highlight
	canvas.draw_line(
		draw_rect.position + Vector2(4.0, gloss_h + 2.0),
		draw_rect.position + Vector2(draw_rect.size.x - 4.0, gloss_h + 2.0),
		Color(1.0, 1.0, 1.0, 0.08), 1.0)
	# Inner highlight border (light, inset)
	canvas.draw_rect(draw_rect.grow(-1.0), Color(1.0, 1.0, 1.0, 0.14 if hovered else 0.1), false, 1.0)
	# Outer border
	var border_w = 2.4 if hovered else 2.0
	canvas.draw_rect(draw_rect, border_color, false, border_w)
	# Corner softening (simulate rounded corners with translucent discs)
	var cr = minf(8.0, minf(draw_rect.size.x, draw_rect.size.y) * 0.22)
	if cr > 3.0:
		for corner in [draw_rect.position + Vector2(cr, cr), draw_rect.position + Vector2(draw_rect.size.x - cr, cr), draw_rect.position + Vector2(draw_rect.size.x - cr, draw_rect.size.y - cr), draw_rect.position + Vector2(cr, draw_rect.size.y - cr)]:
			canvas.draw_circle(corner, cr * 0.5, Color(1.0, 1.0, 1.0, 0.05))
	# Centered label with shadow
	var text_color = Color(0.97, 0.97, 0.93) if fill_color.v < 0.6 else fill_color.darkened(0.62)
	var text_w = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
	var text_pos = draw_rect.position + Vector2((draw_rect.size.x - text_w) * 0.5, (draw_rect.size.y + font_size) * 0.5 - 2.0)
	# text shadow
	canvas.draw_string(font, text_pos + Vector2(1.0, 2.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.0, 0.0, 0.0, 0.34))
	canvas.draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_color)


# --- Grass Detail ---

static func draw_grass_tufts(canvas: CanvasItem, rect: Rect2, ui_time: float, density: int = 6, color: Color = Color(0.36, 0.62, 0.22)) -> void:
	var step = rect.size.x / float(maxf(density, 1))
	for i in range(density):
		var base_x = rect.position.x + step * (float(i) + 0.5) + sin(float(i) * 2.3) * step * 0.2
		var base_y = rect.position.y + rect.size.y
		var sway = sin(ui_time * 2.4 + float(i) * 1.7) * 3.0
		var h = 8.0 + float(i % 3) * 4.0
		canvas.draw_line(Vector2(base_x, base_y), Vector2(base_x + sway - 3.0, base_y - h), color, 2.0)
		canvas.draw_line(Vector2(base_x, base_y), Vector2(base_x + sway + 3.0, base_y - h * 0.8), color.lightened(0.1), 2.0)
		canvas.draw_line(Vector2(base_x, base_y), Vector2(base_x + sway, base_y - h * 1.1), color.darkened(0.08), 1.5)


# --- Water Surface ---

static func draw_water_surface(canvas: CanvasItem, rect: Rect2, ui_time: float, water_color: Color = Color(0.18, 0.58, 0.86), foam_alpha: float = 0.12) -> void:
	# Depth gradient
	draw_gradient_rect_v(canvas, rect, water_color.lightened(0.12), water_color.darkened(0.14))
	# Surface highlight
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 6.0)), Color(0.92, 0.98, 1.0, foam_alpha), true)
	# Animated ripples
	for i in range(8):
		var ripple_y = rect.position.y + 10.0 + float(i) * (rect.size.y / 8.0) + sin(ui_time * 1.6 + float(i) * 0.9) * 3.0
		var ripple_alpha = 0.08 - float(i) * 0.006
		canvas.draw_line(
			Vector2(rect.position.x + 8.0, ripple_y),
			Vector2(rect.position.x + rect.size.x - 8.0, ripple_y),
			Color(0.9, 0.98, 1.0, maxf(0.02, ripple_alpha)), 1.5
		)
	# Caustic light beams
	for i in range(5):
		var cx = rect.position.x - 60.0 + fmod(ui_time * (40.0 + float(i) * 8.0) + float(i) * 140.0, rect.size.x + 120.0)
		canvas.draw_line(
			Vector2(cx, rect.position.y + 4.0),
			Vector2(cx + 50.0, rect.position.y + rect.size.y - 4.0),
			Color(1.0, 1.0, 1.0, 0.04), 3.0
		)
	# Bottom shadow
	canvas.draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 8.0), Vector2(rect.size.x, 8.0)), Color(0.0, 0.12, 0.24, 0.1), true)


# --- Ambient Particles ---

static func draw_ambient_particles(canvas: CanvasItem, viewport_size: Vector2, ui_time: float, particle_type: String, count: int = 16) -> void:
	match particle_type:
		"leaves":
			for i in range(count):
				var seed_val = float(i) * 73.13
				var x = fmod(ui_time * (18.0 + fmod(seed_val, 12.0)) + seed_val * 7.3, viewport_size.x + 40.0) - 20.0
				var y = fmod(ui_time * (22.0 + fmod(seed_val * 0.7, 8.0)) + seed_val * 3.1, viewport_size.y + 40.0) - 20.0
				var rot = ui_time * (1.2 + fmod(seed_val, 1.5)) + seed_val
				var sz = 4.0 + fmod(seed_val, 3.0)
				var hue_shift = fmod(seed_val, 3.0)
				var leaf_color = Color(0.5 + hue_shift * 0.06, 0.7 - hue_shift * 0.04, 0.24, 0.22 + 0.08 * sin(ui_time + seed_val))
				# soft halo + pointed leaf (two triangles) + vein
				canvas.draw_circle(Vector2(x, y), sz * 1.6, Color(leaf_color.r, leaf_color.g, leaf_color.b, leaf_color.a * 0.25))
				var dir = Vector2(cos(rot), sin(rot))
				var perp = Vector2(-dir.y, dir.x)
				canvas.draw_polygon(
					PackedVector2Array([Vector2(x, y) + dir * sz, Vector2(x, y) - dir * sz + perp * sz * 0.6, Vector2(x, y) - dir * sz - perp * sz * 0.6]),
					PackedColorArray([leaf_color, leaf_color, leaf_color])
				)
				canvas.draw_line(Vector2(x, y) + dir * sz, Vector2(x, y) - dir * sz, leaf_color.darkened(0.18), 1.2)
		"fireflies":
			for i in range(count):
				var seed_val = float(i) * 47.7
				var x = viewport_size.x * 0.2 + fmod(seed_val * 11.3, viewport_size.x * 0.7)
				var y = viewport_size.y * 0.3 + fmod(seed_val * 7.1, viewport_size.y * 0.5)
				x += sin(ui_time * 0.8 + seed_val) * 30.0
				y += cos(ui_time * 0.6 + seed_val * 0.5) * 20.0
				var brightness = 0.4 + 0.6 * maxf(0.0, sin(ui_time * 2.8 + seed_val * 1.3))
				# layered warm glow
				canvas.draw_circle(Vector2(x, y), 11.0, Color(1.0, 0.95, 0.5, brightness * 0.05))
				canvas.draw_circle(Vector2(x, y), 6.0, Color(1.0, 0.95, 0.52, brightness * 0.1))
				canvas.draw_circle(Vector2(x, y), 2.6, Color(1.0, 0.98, 0.62, brightness * 0.6))
		"snowflakes":
			for i in range(count):
				var seed_val = float(i) * 61.9
				var x = fmod(ui_time * (14.0 + fmod(seed_val, 10.0)) + seed_val * 5.7, viewport_size.x + 30.0) - 15.0
				var y = fmod(ui_time * (28.0 + fmod(seed_val * 0.6, 6.0)) + seed_val * 2.9, viewport_size.y + 30.0) - 15.0
				var sz = 1.8 + fmod(seed_val, 2.4)
				var a = 0.28 + 0.1 * sin(ui_time * 1.4 + seed_val)
				canvas.draw_circle(Vector2(x, y), sz * 2.0, Color(1.0, 1.0, 1.0, a * 0.2))
				canvas.draw_circle(Vector2(x, y), sz, Color(1.0, 1.0, 1.0, a))
		"fog_wisps":
			for i in range(mini(count, 8)):
				var seed_val = float(i) * 53.3
				var x = fmod(ui_time * (6.0 + fmod(seed_val, 4.0)) + seed_val * 9.1, viewport_size.x + 200.0) - 100.0
				var y = viewport_size.y * 0.4 + fmod(seed_val * 3.7, viewport_size.y * 0.4) + sin(ui_time * 0.5 + seed_val) * 20.0
				var wisp_w = 90.0 + fmod(seed_val, 60.0)
				var wisp_h = 22.0 + fmod(seed_val * 0.5, 16.0)
				# soft layered wisp
				canvas.draw_circle(Vector2(x, y), wisp_h * 0.9, Color(0.74, 0.8, 0.84, 0.05 + 0.025 * sin(ui_time * 0.7 + seed_val)))
				canvas.draw_circle(Vector2(x + wisp_w * 0.3, y), wisp_h * 0.7, Color(0.78, 0.84, 0.88, 0.04 + 0.02 * sin(ui_time * 0.7 + seed_val)))
		"dust_motes":
			for i in range(count):
				var seed_val = float(i) * 37.1
				var x = fmod(ui_time * (8.0 + fmod(seed_val, 6.0)) + seed_val * 8.3, viewport_size.x + 20.0) - 10.0
				var y = fmod(seed_val * 4.7 + sin(ui_time * 0.4 + seed_val) * 40.0, viewport_size.y)
				var sz = 1.2 + fmod(seed_val, 2.0)
				var a = 0.16 + 0.07 * sin(ui_time * 1.8 + seed_val)
				canvas.draw_circle(Vector2(x, y), sz * 2.4, Color(1.0, 0.94, 0.78, a * 0.3))
				canvas.draw_circle(Vector2(x, y), sz, Color(1.0, 0.94, 0.78, a))


# --- Fluffy Cloud ---

static func draw_cloud(canvas: CanvasItem, center: Vector2, scale: float, alpha: float, tint: Color = Color(1.0, 1.0, 1.0)) -> void:
	# Soft multi-lobe cloud: faint base shadow, translucent body, bright top highlight.
	var s = scale
	# soft base shadow (sits slightly below the cloud)
	canvas.draw_circle(center + Vector2(3.0, 16.0) * s, 30.0 * s, Color(0.0, 0.0, 0.0, alpha * 0.05))
	canvas.draw_circle(center + Vector2(18.0, 19.0) * s, 22.0 * s, Color(0.0, 0.0, 0.0, alpha * 0.04))
	# body lobes
	for lobe in [[Vector2(0.0, 4.0), 30.0], [Vector2(27.0, 7.0), 24.0], [Vector2(-25.0, 9.0), 23.0], [Vector2(14.0, -11.0), 21.0], [Vector2(-11.0, -5.0), 17.0]]:
		canvas.draw_circle(center + Vector2(lobe[0]) * s, lobe[1] * s, Color(tint.r, tint.g, tint.b, alpha * 0.5))
	# shaded underside (cooler tint at bottom)
	for lobe in [[Vector2(8.0, 14.0), 22.0], [Vector2(-14.0, 12.0), 18.0], [Vector2(24.0, 12.0), 16.0]]:
		canvas.draw_circle(center + Vector2(lobe[0]) * s, lobe[1] * s, Color(tint.r * 0.82, tint.g * 0.84, tint.b * 0.9, alpha * 0.22))
	# bright top highlight
	for lobe in [[Vector2(-5.0, -9.0), 15.0], [Vector2(19.0, -5.0), 12.0], [Vector2(-19.0, -3.0), 11.0]]:
		canvas.draw_circle(center + Vector2(lobe[0]) * s, lobe[1] * s, Color(min(1.0, tint.r + 0.05), min(1.0, tint.g + 0.05), min(1.0, tint.b + 0.05), alpha * 0.26))


# --- Improved Sky ---

static func draw_world_sky(canvas: CanvasItem, viewport_size: Vector2, ui_time: float, is_night_world: bool) -> void:
	if is_night_world:
		# Night sky: 3-stop gradient (deep indigo -> midnight -> dark horizon)
		draw_gradient_rect_v(canvas, Rect2(Vector2.ZERO, Vector2(viewport_size.x, 130.0)), Color(0.03, 0.05, 0.14), Color(0.06, 0.1, 0.22))
		draw_gradient_rect_v(canvas, Rect2(Vector2(0.0, 110.0), Vector2(viewport_size.x, 110.0)), Color(0.06, 0.1, 0.22), Color(0.1, 0.15, 0.28))
		# Moon with layered glow
		draw_glow_circle(canvas, Vector2(118.0, 84.0), 50.0, Color(0.86, 0.9, 1.0), 5)
		canvas.draw_circle(Vector2(120.0, 84.0), 34.0, Color(0.95, 0.96, 1.0))
		canvas.draw_circle(Vector2(132.0, 76.0), 31.0, Color(0.08, 0.12, 0.22))  # crescent shadow
		# soft craters
		for crater in [[Vector2(112.0, 90.0), 5.0], [Vector2(116.0, 76.0), 3.5], [Vector2(104.0, 82.0), 4.0]]:
			canvas.draw_circle(Vector2(crater[0]), crater[1], Color(0.82, 0.86, 0.96, 0.5))
		# stars with twinkle (varied)
		for star_index in range(46):
			var seed_val = float(star_index) * 12.9898
			var sx = fmod(sin(seed_val) * 43758.5453, viewport_size.x - 40.0)
			if sx < 0.0:
				sx += viewport_size.x - 40.0
			var star_pos = Vector2(20.0 + sx, 16.0 + fmod(seed_val * 7.13, 150.0) + sin(ui_time * 0.8 + seed_val) * 2.0)
			var twinkle = 0.5 + 0.5 * sin(ui_time * (1.6 + fmod(seed_val, 2.0)) + seed_val * 1.3)
			var star_size = 0.9 + fmod(seed_val, 1.6)
			canvas.draw_circle(star_pos, star_size + twinkle * 0.7, Color(1.0, 1.0, 0.95, twinkle * 0.8))
			if star_index % 6 == 0:
				canvas.draw_circle(star_pos, star_size * 3.5, Color(0.8, 0.86, 1.0, twinkle * 0.08))
		# drifting dark clouds (distant)
		for cloud_index in range(3):
			var total_w = viewport_size.x + 360.0
			var cx = fmod(ui_time * (10.0 + cloud_index * 4.0) + cloud_index * 460.0, total_w) - 180.0
			var cy = 60.0 + cloud_index * 42.0 + sin(ui_time * 0.25 + cloud_index) * 5.0
			draw_cloud(canvas, Vector2(cx, cy), 0.7 + cloud_index * 0.12, 0.18, Color(0.5, 0.56, 0.72))
		# Ground
		draw_gradient_rect_v(canvas, Rect2(Vector2(0.0, 150.0), Vector2(viewport_size.x, viewport_size.y - 150.0)), Color(0.14, 0.18, 0.24), Color(0.08, 0.11, 0.16))
		# Far hills (hazy) + near hills
		canvas.draw_polygon(
			PackedVector2Array([Vector2(0.0, 248.0), Vector2(220.0, 214.0), Vector2(460.0, 250.0), Vector2(720.0, 216.0), Vector2(1000.0, 254.0), Vector2(1280.0, 220.0), Vector2(viewport_size.x, 248.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y)]),
			PackedColorArray([Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.09, 0.12, 0.17), Color(0.09, 0.12, 0.17)])
		)
		canvas.draw_polygon(
			PackedVector2Array([Vector2(0.0, 282.0), Vector2(170.0, 246.0), Vector2(380.0, 290.0), Vector2(620.0, 250.0), Vector2(880.0, 296.0), Vector2(1140.0, 254.0), Vector2(viewport_size.x, 286.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y)]),
			PackedColorArray([Color(0.09, 0.12, 0.16), Color(0.09, 0.12, 0.16), Color(0.09, 0.12, 0.16), Color(0.09, 0.12, 0.16), Color(0.09, 0.12, 0.16), Color(0.09, 0.12, 0.16), Color(0.09, 0.12, 0.16), Color(0.07, 0.09, 0.13), Color(0.07, 0.09, 0.13)])
		)
		# moonlight band + fireflies
		canvas.draw_rect(Rect2(Vector2(0.0, 300.0), Vector2(viewport_size.x, 130.0)), Color(0.7, 0.8, 1.0, 0.025), true)
		draw_ambient_particles(canvas, viewport_size, ui_time, "fireflies", 14)
	else:
		# Day sky: 3-stop gradient (deep blue -> sky -> warm horizon)
		draw_gradient_rect_v(canvas, Rect2(Vector2.ZERO, Vector2(viewport_size.x, 130.0)), Color(0.46, 0.74, 1.0), Color(0.66, 0.86, 1.0))
		draw_gradient_rect_v(canvas, Rect2(Vector2(0.0, 110.0), Vector2(viewport_size.x, 96.0)), Color(0.66, 0.86, 1.0), Color(0.86, 0.94, 0.98))
		# Sun with layered glow + soft rotating rays
		draw_glow_circle(canvas, Vector2(104.0, 84.0), 56.0, Color(1.0, 0.92, 0.5), 6)
		draw_glow_circle(canvas, Vector2(104.0, 84.0), 38.0, Color(1.0, 0.96, 0.66), 4)
		for ray_i in range(12):
			var angle = TAU * float(ray_i) / 12.0 + ui_time * 0.12
			var ray_from = Vector2(104.0, 84.0) + Vector2(cos(angle), sin(angle)) * 46.0
			var ray_to = Vector2(104.0, 84.0) + Vector2(cos(angle), sin(angle)) * (64.0 + sin(ui_time * 1.4 + float(ray_i)) * 7.0)
			canvas.draw_line(ray_from, ray_to, Color(1.0, 0.94, 0.56, 0.16), 2.2)
		# Parallax clouds at two depths (far = slow/small/faint, near = faster/bigger)
		for cloud_index in range(4):
			var total_w = viewport_size.x + 420.0
			var cx = fmod(ui_time * (7.0 + cloud_index * 2.2) + cloud_index * 380.0, total_w) - 210.0
			var cy = 40.0 + cloud_index * 30.0 + sin(ui_time * 0.3 + cloud_index * 1.7) * 5.0
			draw_cloud(canvas, Vector2(cx, cy), 0.62 + fmod(cloud_index, 2) * 0.16, 0.5)
		for cloud_index in range(3):
			var total_w = viewport_size.x + 520.0
			var cx = fmod(ui_time * (13.0 + cloud_index * 3.0) + cloud_index * 540.0 + 200.0, total_w) - 260.0
			var cy = 96.0 + cloud_index * 22.0 + sin(ui_time * 0.4 + cloud_index) * 6.0
			draw_cloud(canvas, Vector2(cx, cy), 1.0 + fmod(cloud_index, 2) * 0.2, 0.7)
		# Ground gradient
		draw_gradient_rect_v(canvas, Rect2(Vector2(0.0, 150.0), Vector2(viewport_size.x, viewport_size.y - 150.0)), Color(0.6, 0.78, 0.42), Color(0.46, 0.66, 0.3))
		# Far hills (hazy, lighter) + near hills (greener)
		canvas.draw_polygon(
			PackedVector2Array([Vector2(0.0, 244.0), Vector2(200.0, 206.0), Vector2(440.0, 246.0), Vector2(700.0, 210.0), Vector2(980.0, 250.0), Vector2(1260.0, 214.0), Vector2(viewport_size.x, 246.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y)]),
			PackedColorArray([Color(0.56, 0.74, 0.4), Color(0.56, 0.74, 0.4), Color(0.56, 0.74, 0.4), Color(0.56, 0.74, 0.4), Color(0.56, 0.74, 0.4), Color(0.56, 0.74, 0.4), Color(0.56, 0.74, 0.4), Color(0.5, 0.68, 0.34), Color(0.5, 0.68, 0.34)])
		)
		canvas.draw_polygon(
			PackedVector2Array([Vector2(0.0, 280.0), Vector2(180.0, 238.0), Vector2(400.0, 286.0), Vector2(640.0, 244.0), Vector2(900.0, 292.0), Vector2(1160.0, 248.0), Vector2(viewport_size.x, 282.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y)]),
			PackedColorArray([Color(0.42, 0.64, 0.26), Color(0.42, 0.64, 0.26), Color(0.42, 0.64, 0.26), Color(0.42, 0.64, 0.26), Color(0.42, 0.64, 0.26), Color(0.42, 0.64, 0.26), Color(0.42, 0.64, 0.26), Color(0.36, 0.56, 0.2), Color(0.36, 0.56, 0.2)])
		)
		# soft light bands + leaves
		canvas.draw_rect(Rect2(Vector2(0.0, 240.0), Vector2(viewport_size.x, 110.0)), Color(1.0, 1.0, 1.0, 0.05), true)
		canvas.draw_rect(Rect2(Vector2(0.0, 410.0), Vector2(viewport_size.x, 90.0)), Color(1.0, 0.98, 0.9, 0.03), true)
		draw_ambient_particles(canvas, viewport_size, ui_time, "leaves", 12)


# --- Scroll Mask ---

static func scroll_mask_fill_rects(_content_rect: Rect2, _view_rect: Rect2) -> Array:
	return []


static func draw_scroll_mask(canvas: CanvasItem, content_rect: Rect2, view_rect: Rect2, fill_color: Color, border_color: Color) -> void:
	for fill_rect_variant in scroll_mask_fill_rects(content_rect, view_rect):
		canvas.draw_rect(Rect2(fill_rect_variant), fill_color, true)
	# Top fade
	draw_gradient_rect_v(canvas, Rect2(view_rect.position, Vector2(view_rect.size.x, 16.0)), Color(1.0, 1.0, 1.0, 0.06), Color(1.0, 1.0, 1.0, 0.0))
	# Bottom fade
	draw_gradient_rect_v(canvas, Rect2(view_rect.position + Vector2(0.0, view_rect.size.y - 16.0), Vector2(view_rect.size.x, 16.0)), Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.1))
	canvas.draw_rect(view_rect.grow(1.0), border_color, false, 2.0)


# --- Text Shadow Helper ---

static func draw_text_with_shadow(canvas: CanvasItem, font: Font, pos: Vector2, text: String, font_size: int, color: Color, shadow_offset: Vector2 = Vector2(1.0, 2.0), shadow_alpha: float = 0.3) -> void:
	canvas.draw_string(font, pos + shadow_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.0, 0.0, 0.0, shadow_alpha))
	canvas.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
