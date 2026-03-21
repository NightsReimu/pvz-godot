extends RefCounted
class_name GameTheme


static func ease_ui(value: float) -> float:
	var t = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func ease_out(value: float) -> float:
	var t = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


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


static func draw_panel_shell(canvas: CanvasItem, rect: Rect2, fill_color: Color, border_color: Color, shadow_alpha: float = 0.22, accent_alpha: float = 0.16) -> void:
	var outer_glow = rect.grow(6.0)
	canvas.draw_rect(outer_glow, Color(border_color.r, border_color.g, border_color.b, accent_alpha * 0.22), true)
	var shadow_rect = rect.grow(10.0)
	shadow_rect.position += Vector2(0.0, 14.0)
	canvas.draw_rect(shadow_rect, Color(0.0, 0.0, 0.0, shadow_alpha * 0.72), true)
	canvas.draw_rect(Rect2(rect.position + Vector2(4.0, 6.0), rect.size), Color(0.0, 0.0, 0.0, shadow_alpha * 0.18), true)
	canvas.draw_rect(rect, fill_color, true)
	canvas.draw_rect(
		Rect2(rect.position + Vector2(2.0, 2.0), Vector2(maxf(0.0, rect.size.x - 4.0), maxf(10.0, rect.size.y * 0.16))),
		fill_color.lerp(Color.WHITE, 0.34),
		true
	)
	canvas.draw_rect(
		Rect2(rect.position + Vector2(4.0, rect.size.y * 0.26), Vector2(maxf(0.0, rect.size.x - 8.0), maxf(8.0, rect.size.y * 0.18))),
		fill_color.lerp(Color.WHITE, 0.12),
		true
	)
	canvas.draw_rect(
		Rect2(rect.position + Vector2(0.0, rect.size.y * 0.7), Vector2(rect.size.x, rect.size.y * 0.3)),
		fill_color.darkened(0.12),
		true
	)
	var stripe_step = maxf(48.0, rect.size.x * 0.12)
	var stripe_count = int(ceil((rect.size.x + rect.size.y) / stripe_step))
	for stripe_index in range(stripe_count + 1):
		var stripe_x = rect.position.x - rect.size.y * 0.24 + float(stripe_index) * stripe_step
		canvas.draw_line(
			Vector2(stripe_x, rect.position.y + rect.size.y - 4.0),
			Vector2(stripe_x + rect.size.y * 0.3, rect.position.y + 4.0),
			Color(1.0, 1.0, 1.0, accent_alpha * 0.14),
			2.0
		)
	canvas.draw_rect(Rect2(rect.position + Vector2(0.0, 14.0), Vector2(rect.size.x, 2.0)), Color(1.0, 1.0, 1.0, accent_alpha), true)
	canvas.draw_line(rect.position + Vector2(16.0, rect.size.y - 16.0), rect.position + Vector2(rect.size.x - 18.0, 14.0), Color(1.0, 1.0, 1.0, accent_alpha * 0.42), 3.0)
	canvas.draw_rect(rect.grow(-3.0), Color(1.0, 1.0, 1.0, accent_alpha * 0.18), false, 1.0)
	canvas.draw_line(rect.position + Vector2(0.0, rect.size.y - 1.0), rect.position + Vector2(rect.size.x, rect.size.y - 1.0), border_color.darkened(0.18), 3.0)
	canvas.draw_rect(rect, border_color, false, 2.0)


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
	canvas.draw_rect(Rect2(view_rect.position, Vector2(view_rect.size.x, 12.0)), Color(1.0, 1.0, 1.0, 0.05), true)
	canvas.draw_rect(Rect2(view_rect.position + Vector2(0.0, view_rect.size.y - 12.0), Vector2(view_rect.size.x, 12.0)), Color(0.0, 0.0, 0.0, 0.08), true)
	canvas.draw_rect(view_rect.grow(1.0), border_color, false, 2.0)


static func draw_world_sky(canvas: CanvasItem, viewport_size: Vector2, ui_time: float, is_night_world: bool) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.76, 0.9, 1.0), true)
	if is_night_world:
		canvas.draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.05, 0.09, 0.18), true)
		canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, 210.0)), Color(0.1, 0.16, 0.29), true)
		canvas.draw_circle(Vector2(122.0, 86.0), 60.0, Color(0.82, 0.86, 1.0, 0.12))
		canvas.draw_circle(Vector2(112.0, 92.0), 36.0, Color(0.94, 0.96, 1.0))
		canvas.draw_circle(Vector2(128.0, 82.0), 34.0, Color(0.08, 0.12, 0.22))
		for star_index in range(26):
			var drift = sin(ui_time * 0.8 + float(star_index) * 0.7) * 4.0
			var star_pos = Vector2(128.0 + float(star_index) * 58.0, 30.0 + float(star_index % 5) * 24.0 + drift)
			canvas.draw_circle(star_pos, 1.8 + float(star_index % 2), Color(1.0, 1.0, 0.9, 0.66 + 0.18 * sin(ui_time * 2.2 + float(star_index))))
		canvas.draw_rect(Rect2(Vector2(0.0, 164.0), Vector2(viewport_size.x, viewport_size.y - 164.0)), Color(0.18, 0.22, 0.28), true)
		canvas.draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 262.0), Vector2(150.0, 224.0), Vector2(320.0, 276.0),
				Vector2(500.0, 228.0), Vector2(760.0, 292.0), Vector2(980.0, 238.0),
				Vector2(1260.0, 304.0), Vector2(viewport_size.x, 272.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y),
			]),
			PackedColorArray([
				Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22),
				Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22),
				Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22), Color(0.12, 0.16, 0.22),
			])
		)
		canvas.draw_rect(Rect2(Vector2(0.0, 312.0), Vector2(viewport_size.x, 118.0)), Color(0.86, 0.92, 1.0, 0.025), true)
	else:
		canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, 192.0)), Color(0.88, 0.97, 1.0), true)
		canvas.draw_circle(Vector2(102.0, 86.0), 38.0, Color(1.0, 0.94, 0.56))
		canvas.draw_circle(Vector2(102.0, 86.0), 58.0, Color(1.0, 0.94, 0.56, 0.12))
		for cloud_index in range(5):
			var cloud_shift = fmod(ui_time * (10.0 + cloud_index * 2.0), 250.0)
			var cloud_pos = Vector2(150.0 + float(cloud_index) * 250.0 + cloud_shift, 66.0 + float(cloud_index % 2) * 34.0)
			canvas.draw_circle(cloud_pos, 26.0, Color(1.0, 1.0, 1.0, 0.56))
			canvas.draw_circle(cloud_pos + Vector2(26.0, 6.0), 22.0, Color(1.0, 1.0, 1.0, 0.62))
			canvas.draw_circle(cloud_pos + Vector2(-22.0, 10.0), 20.0, Color(1.0, 1.0, 1.0, 0.5))
		canvas.draw_rect(Rect2(Vector2(0.0, 164.0), Vector2(viewport_size.x, viewport_size.y - 164.0)), Color(0.65, 0.82, 0.48), true)
		canvas.draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 258.0), Vector2(180.0, 208.0), Vector2(340.0, 260.0),
				Vector2(540.0, 210.0), Vector2(760.0, 276.0), Vector2(980.0, 228.0),
				Vector2(1240.0, 284.0), Vector2(viewport_size.x, 252.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y),
			]),
			PackedColorArray([
				Color(0.52, 0.72, 0.34), Color(0.52, 0.72, 0.34), Color(0.52, 0.72, 0.34),
				Color(0.52, 0.72, 0.34), Color(0.52, 0.72, 0.34), Color(0.52, 0.72, 0.34),
				Color(0.52, 0.72, 0.34), Color(0.52, 0.72, 0.34), Color(0.52, 0.72, 0.34), Color(0.52, 0.72, 0.34),
			])
		)
		canvas.draw_rect(Rect2(Vector2(0.0, 248.0), Vector2(viewport_size.x, 96.0)), Color(1.0, 1.0, 1.0, 0.05), true)
		canvas.draw_rect(Rect2(Vector2(0.0, 418.0), Vector2(viewport_size.x, 84.0)), Color(1.0, 1.0, 1.0, 0.03), true)
