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
				var sz = 3.0 + fmod(seed_val, 3.0)
				var leaf_color = Color(0.42, 0.68, 0.26, 0.18 + 0.06 * sin(ui_time + seed_val))
				canvas.draw_circle(Vector2(x, y), sz, leaf_color)
				canvas.draw_line(Vector2(x - sz * cos(rot), y - sz * sin(rot)), Vector2(x + sz * cos(rot), y + sz * sin(rot)), leaf_color.darkened(0.1), 1.5)
		"fireflies":
			for i in range(count):
				var seed_val = float(i) * 47.7
				var x = viewport_size.x * 0.2 + fmod(seed_val * 11.3, viewport_size.x * 0.7)
				var y = viewport_size.y * 0.3 + fmod(seed_val * 7.1, viewport_size.y * 0.5)
				x += sin(ui_time * 0.8 + seed_val) * 30.0
				y += cos(ui_time * 0.6 + seed_val * 0.5) * 20.0
				var brightness = 0.4 + 0.6 * maxf(0.0, sin(ui_time * 2.8 + seed_val * 1.3))
				canvas.draw_circle(Vector2(x, y), 6.0, Color(0.98, 0.96, 0.5, brightness * 0.08))
				canvas.draw_circle(Vector2(x, y), 2.5, Color(0.98, 0.96, 0.5, brightness * 0.5))
		"snowflakes":
			for i in range(count):
				var seed_val = float(i) * 61.9
				var x = fmod(ui_time * (14.0 + fmod(seed_val, 10.0)) + seed_val * 5.7, viewport_size.x + 30.0) - 15.0
				var y = fmod(ui_time * (28.0 + fmod(seed_val * 0.6, 6.0)) + seed_val * 2.9, viewport_size.y + 30.0) - 15.0
				var sz = 1.5 + fmod(seed_val, 2.5)
				canvas.draw_circle(Vector2(x, y), sz, Color(1.0, 1.0, 1.0, 0.24 + 0.08 * sin(ui_time * 1.4 + seed_val)))
		"fog_wisps":
			for i in range(mini(count, 8)):
				var seed_val = float(i) * 53.3
				var x = fmod(ui_time * (6.0 + fmod(seed_val, 4.0)) + seed_val * 9.1, viewport_size.x + 200.0) - 100.0
				var y = viewport_size.y * 0.4 + fmod(seed_val * 3.7, viewport_size.y * 0.4) + sin(ui_time * 0.5 + seed_val) * 20.0
				var wisp_w = 80.0 + fmod(seed_val, 60.0)
				var wisp_h = 20.0 + fmod(seed_val * 0.5, 16.0)
				canvas.draw_rect(Rect2(Vector2(x - wisp_w * 0.5, y - wisp_h * 0.5), Vector2(wisp_w, wisp_h)), Color(0.7, 0.78, 0.82, 0.04 + 0.02 * sin(ui_time * 0.7 + seed_val)), true)
		"dust_motes":
			for i in range(count):
				var seed_val = float(i) * 37.1
				var x = fmod(ui_time * (8.0 + fmod(seed_val, 6.0)) + seed_val * 8.3, viewport_size.x + 20.0) - 10.0
				var y = fmod(seed_val * 4.7 + sin(ui_time * 0.4 + seed_val) * 40.0, viewport_size.y)
				var sz = 1.0 + fmod(seed_val, 2.0)
				canvas.draw_circle(Vector2(x, y), sz, Color(0.92, 0.86, 0.72, 0.14 + 0.06 * sin(ui_time * 1.8 + seed_val)))


# --- Improved Sky ---

static func draw_world_sky(canvas: CanvasItem, viewport_size: Vector2, ui_time: float, is_night_world: bool) -> void:
	if is_night_world:
		# Night sky gradient
		draw_gradient_rect_v(canvas, Rect2(Vector2.ZERO, Vector2(viewport_size.x, 210.0)), Color(0.02, 0.04, 0.12), Color(0.08, 0.14, 0.28))
		# Moon with glow
		draw_glow_circle(canvas, Vector2(122.0, 86.0), 36.0, Color(0.94, 0.96, 1.0), 4)
		canvas.draw_circle(Vector2(134.0, 78.0), 32.0, Color(0.04, 0.08, 0.18))
		# Stars with twinkle
		for star_index in range(36):
			var drift = sin(ui_time * 0.8 + float(star_index) * 0.7) * 3.0
			var star_pos = Vector2(128.0 + float(star_index) * 42.0, 18.0 + float(star_index % 7) * 22.0 + drift)
			var twinkle = 0.5 + 0.5 * sin(ui_time * (2.0 + float(star_index % 4) * 0.4) + float(star_index) * 1.3)
			var star_size = 1.2 + float(star_index % 3) * 0.8
			canvas.draw_circle(star_pos, star_size + twinkle * 0.6, Color(1.0, 1.0, 0.92, twinkle * 0.7))
			if star_index % 5 == 0:
				canvas.draw_circle(star_pos, star_size * 3.0, Color(1.0, 1.0, 0.92, twinkle * 0.06))
		# Ground
		draw_gradient_rect_v(canvas, Rect2(Vector2(0.0, 164.0), Vector2(viewport_size.x, viewport_size.y - 164.0)), Color(0.16, 0.2, 0.26), Color(0.1, 0.14, 0.2))
		# Hills
		canvas.draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 262.0), Vector2(150.0, 224.0), Vector2(320.0, 276.0),
				Vector2(500.0, 228.0), Vector2(760.0, 292.0), Vector2(980.0, 238.0),
				Vector2(1260.0, 304.0), Vector2(viewport_size.x, 272.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y),
			]),
			PackedColorArray([
				Color(0.1, 0.14, 0.2), Color(0.1, 0.14, 0.2), Color(0.1, 0.14, 0.2),
				Color(0.1, 0.14, 0.2), Color(0.1, 0.14, 0.2), Color(0.1, 0.14, 0.2),
				Color(0.1, 0.14, 0.2), Color(0.1, 0.14, 0.2), Color(0.08, 0.12, 0.18), Color(0.08, 0.12, 0.18),
			])
		)
		# Moonlight band
		canvas.draw_rect(Rect2(Vector2(0.0, 312.0), Vector2(viewport_size.x, 118.0)), Color(0.86, 0.92, 1.0, 0.02), true)
		draw_ambient_particles(canvas, viewport_size, ui_time, "fireflies", 12)
	else:
		# Day sky gradient
		draw_gradient_rect_v(canvas, Rect2(Vector2.ZERO, Vector2(viewport_size.x, 192.0)), Color(0.56, 0.82, 1.0), Color(0.88, 0.96, 1.0))
		# Sun with glow
		draw_glow_circle(canvas, Vector2(102.0, 86.0), 34.0, Color(1.0, 0.94, 0.56), 5)
		# Sun rays
		for ray_i in range(12):
			var angle = TAU * float(ray_i) / 12.0 + ui_time * 0.15
			var ray_from = Vector2(102.0, 86.0) + Vector2(cos(angle), sin(angle)) * 42.0
			var ray_to = Vector2(102.0, 86.0) + Vector2(cos(angle), sin(angle)) * (58.0 + sin(ui_time * 1.5 + float(ray_i)) * 6.0)
			canvas.draw_line(ray_from, ray_to, Color(1.0, 0.94, 0.56, 0.14), 2.0)
		# Clouds (more volumetric)
		for cloud_index in range(6):
			var cloud_shift = fmod(ui_time * (8.0 + cloud_index * 1.6), 300.0)
			var cloud_pos = Vector2(120.0 + float(cloud_index) * 220.0 + cloud_shift, 56.0 + float(cloud_index % 3) * 28.0)
			# Cloud shadow
			canvas.draw_circle(cloud_pos + Vector2(2.0, 4.0), 28.0, Color(0.0, 0.0, 0.0, 0.03))
			# Cloud body
			canvas.draw_circle(cloud_pos, 28.0, Color(1.0, 1.0, 1.0, 0.52))
			canvas.draw_circle(cloud_pos + Vector2(24.0, 4.0), 22.0, Color(1.0, 1.0, 1.0, 0.58))
			canvas.draw_circle(cloud_pos + Vector2(-20.0, 6.0), 20.0, Color(1.0, 1.0, 1.0, 0.46))
			canvas.draw_circle(cloud_pos + Vector2(10.0, -8.0), 18.0, Color(1.0, 1.0, 1.0, 0.42))
			# Cloud highlight
			canvas.draw_circle(cloud_pos + Vector2(-6.0, -6.0), 12.0, Color(1.0, 1.0, 1.0, 0.18))
		# Ground gradient
		draw_gradient_rect_v(canvas, Rect2(Vector2(0.0, 164.0), Vector2(viewport_size.x, viewport_size.y - 164.0)), Color(0.62, 0.8, 0.44), Color(0.48, 0.68, 0.32))
		# Hills with gradient colors
		canvas.draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 258.0), Vector2(180.0, 208.0), Vector2(340.0, 260.0),
				Vector2(540.0, 210.0), Vector2(760.0, 276.0), Vector2(980.0, 228.0),
				Vector2(1240.0, 284.0), Vector2(viewport_size.x, 252.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y),
			]),
			PackedColorArray([
				Color(0.48, 0.7, 0.3), Color(0.5, 0.72, 0.32), Color(0.46, 0.68, 0.28),
				Color(0.5, 0.72, 0.32), Color(0.44, 0.66, 0.26), Color(0.48, 0.7, 0.3),
				Color(0.44, 0.66, 0.26), Color(0.46, 0.68, 0.28), Color(0.4, 0.6, 0.24), Color(0.4, 0.6, 0.24),
			])
		)
		# Light bands
		canvas.draw_rect(Rect2(Vector2(0.0, 248.0), Vector2(viewport_size.x, 96.0)), Color(1.0, 1.0, 1.0, 0.04), true)
		canvas.draw_rect(Rect2(Vector2(0.0, 418.0), Vector2(viewport_size.x, 84.0)), Color(1.0, 1.0, 1.0, 0.025), true)
		draw_ambient_particles(canvas, viewport_size, ui_time, "leaves", 10)


# --- Scroll Mask ---

static func draw_scroll_mask(canvas: CanvasItem, content_rect: Rect2, view_rect: Rect2, fill_color: Color, border_color: Color) -> void:
	if view_rect.position.y > content_rect.position.y:
		canvas.draw_rect(Rect2(content_rect.position, Vector2(content_rect.size.x, view_rect.position.y - content_rect.position.y)), fill_color, true)
	if view_rect.position.x > content_rect.position.x:
		canvas.draw_rect(Rect2(Vector2(content_rect.position.x, view_rect.position.y), Vector2(view_rect.position.x - content_rect.position.x, view_rect.size.y)), fill_color, true)
	var right_x = view_rect.position.x + view_rect.size.x
	var content_end_x = content_rect.position.x + content_rect.size.x
	if content_end_x > right_x:
		canvas.draw_rect(Rect2(Vector2(right_x, view_rect.position.y), Vector2(content_end_x - right_x, view_rect.size.y)), fill_color, true)
	var bottom_y = view_rect.position.y + view_rect.size.y
	var content_end_y = content_rect.position.y + content_rect.size.y
	if content_end_y > bottom_y:
		canvas.draw_rect(Rect2(Vector2(content_rect.position.x, bottom_y), Vector2(content_rect.size.x, content_end_y - bottom_y)), fill_color, true)
	# Top fade
	draw_gradient_rect_v(canvas, Rect2(view_rect.position, Vector2(view_rect.size.x, 16.0)), Color(1.0, 1.0, 1.0, 0.06), Color(1.0, 1.0, 1.0, 0.0))
	# Bottom fade
	draw_gradient_rect_v(canvas, Rect2(view_rect.position + Vector2(0.0, view_rect.size.y - 16.0), Vector2(view_rect.size.x, 16.0)), Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.1))
	canvas.draw_rect(view_rect.grow(1.0), border_color, false, 2.0)


# --- Text Shadow Helper ---

static func draw_text_with_shadow(canvas: CanvasItem, font: Font, pos: Vector2, text: String, font_size: int, color: Color, shadow_offset: Vector2 = Vector2(1.0, 2.0), shadow_alpha: float = 0.3) -> void:
	canvas.draw_string(font, pos + shadow_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.0, 0.0, 0.0, shadow_alpha))
	canvas.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
