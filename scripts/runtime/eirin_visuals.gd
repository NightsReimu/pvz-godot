extends RefCounted

static func background(rt: RefCounted) -> void:
	var g: Control = rt.game
	var extent: Vector2 = g.size
	var blend = 1.0 if rt.sky else clampf(maxf(0.0, rt.exit_age) / 3.0, 0, 1)
	var colors = {"moon": Color("121d36"), "water": Color("123545"), "lava": Color("381c36"), "roof": Color("231d44")}
	var sky_color: Color = colors[rt.world]
	g.ThemeLib.draw_gradient_rect_v(g, Rect2(Vector2.ZERO, extent), Color("070b1c"), sky_color)
	var moon = Vector2(extent.x * 0.72, extent.y * 0.27)
	var radius = extent.y * 0.22
	for n in range(6, 0, -1):
		g.draw_circle(moon, radius * (1 + n * 0.085), Color(0.55, 0.75, 1, 0.014 * blend))
	g.draw_circle(moon, radius, Color(0.84, 0.92, 1, blend * 0.92))
	for n in range(12):
		var angle = n * 2.4
		var p = moon + Vector2(cos(angle), sin(angle)) * radius * (0.2 + (n % 4) * 0.17)
		g.draw_circle(p, radius * (0.035 + (n % 3) * 0.026), Color(0.34, 0.47, 0.68, 0.12 * blend))
	for n in range(60):
		var p = Vector2(fposmod(n * 173.1, extent.x), fposmod(n * 97.7, extent.y * 0.88))
		g.draw_circle(p, 0.8 + (n % 3) * 0.45, Color(0.77, 0.87, 1, 0.15 + blend * 0.35))
	if rt.sky:
		_world_horizon(g, rt.world)
	# Axial sliding gates distinguish this finite escape from Reisen's rotating rings.
	if blend < 1:
		var vanish = Vector2(extent.x * 0.58, extent.y * 0.39)
		var a = 1.0 - blend
		for n in range(10, -1, -1):
			var depth = fposmod(n / 11.0 + g.level_time * 0.035, 1.0)
			var scale = pow(depth, 2.0) * (1 + blend * 3)
			var half = Vector2(extent.x * 0.66, extent.y * 0.65) * scale
			var rect = Rect2(vanish - half, half * 2)
			g.draw_rect(rect, Color(0.24, 0.36, 0.49, a * (0.12 + depth * 0.3)), false, maxf(1.0, scale * 13))
			g.draw_line(rect.position + Vector2(0, half.y * 0.2), rect.position + Vector2(rect.size.x, half.y * 0.2), Color(0.62, 0.54, 0.45, a * depth * 0.3), maxf(1, scale * 4))
			for side in [-1, 1]:
				var lantern = vanish + Vector2(side * half.x * 0.82, -half.y * 0.65)
				g.draw_circle(lantern, maxf(1, scale * 13), Color(1, 0.71, 0.58, a * depth * 0.55))
		for corner in [Vector2.ZERO, Vector2(extent.x, 0), extent, Vector2(0, extent.y)]:
			g.draw_line(vanish, corner, Color(0.5, 0.59, 0.72, a * 0.15), 2)
		for side in [-1, 1]:
			var x = g.BOARD_ORIGIN.x * 0.38 if side < 0 else g.BOARD_ORIGIN.x + g.board_size.x + (extent.x - g.BOARD_ORIGIN.x - g.board_size.x) * 0.65
			for n in range(3):
				var lamp = Vector2(x, extent.y * (0.26 + n * 0.25))
				var h = extent.y * 0.025
				g.draw_circle(lamp, h * 2, Color(1, 0.6, 0.36, a * 0.05))
				g.draw_rect(Rect2(lamp - Vector2(h * 0.55, h), Vector2(h * 1.1, h * 2)), Color(0.95, 0.71, 0.49, a * 0.6))
				for line in range(4):
					g.draw_line(lamp + Vector2(-h * 0.65, -h + line * h * 0.67), lamp + Vector2(h * 0.65, -h + line * h * 0.67), Color(0.12, 0.15, 0.24, a), 2)
	# Moving cloud ribbons frame the board without obscuring plant silhouettes.
	for n in range(7):
		var y = extent.y * (0.16 + n * 0.125)
		var x = fposmod(g.level_time * (8 + n) + n * 179, extent.x + 500) - 250
		g.draw_line(Vector2(x, y), Vector2(x + 380, y + 7), Color(0.58, 0.72, 0.9, blend * 0.06), 12 + n * 2, true)

static func _world_horizon(g: Control, world: String) -> void:
	var size: Vector2 = g.size
	if world == "water":
		for n in range(9):
			var points = PackedVector2Array()
			for x in range(33):
				var xx = size.x * x / 32
				points.append(Vector2(xx, size.y * (0.65 + n * 0.043) + sin(x * 0.55 + g.level_time * 0.45 + n) * 6))
			g.draw_polyline(points, Color(0.35, 0.67, 0.79, 0.16), 3, true)
	elif world == "lava":
		for n in range(5):
			var x = size.x * n / 4
			var peak = Vector2(x, size.y * (0.52 + (n % 2) * 0.1))
			g.draw_colored_polygon(PackedVector2Array([Vector2(x - size.x * 0.2, size.y), peak, Vector2(x + size.x * 0.2, size.y)]), Color("281c34"))
			g.draw_polyline(PackedVector2Array([peak, peak + Vector2(15, size.y * 0.09), peak + Vector2(-8, size.y * 0.15), peak + Vector2(32, size.y * 0.27)]), Color(1, 0.29, 0.15, 0.5), 3, true)
	elif world == "roof":
		for n in range(6):
			var x = size.x * n / 5
			var y = size.y * (0.69 + (n % 2) * 0.1)
			g.draw_rect(Rect2(Vector2(x - size.x * 0.07, y), Vector2(size.x * 0.14, size.y - y)), Color("171c32"))
			for tier in range(2):
				var tip = Vector2(x, y - size.y * (0.05 + tier * 0.055))
				var pts = PackedVector2Array([tip + Vector2(-size.x * 0.09, size.y * 0.045), tip, tip + Vector2(size.x * 0.09, size.y * 0.045)])
				g.draw_colored_polygon(pts, Color("45425e"))
				g.draw_polyline(pts, Color(0.72, 0.68, 0.88, 0.4), 2, true)

static func ground(rt: RefCounted) -> void:
	var g: Control = rt.game
	g.draw_rect(Rect2(g.BOARD_ORIGIN - Vector2(6, 6), g.board_size + Vector2(12, 12)), Color(0.025, 0.04, 0.09, 0.72))
	g.draw_rect(Rect2(g.BOARD_ORIGIN - Vector2(6, 6), g.board_size + Vector2(12, 12)), Color(0.63, 0.7, 0.83, 0.5), false, 2)
	for row in g.active_rows:
		for col in range(g.COLS):
			var rect: Rect2 = g._cell_rect(row, col).grow(-2)
			var tint = Color("25394b") if (row + col) % 2 == 0 else Color("213244")
			if not rt.sky:
				tint = Color("383746") if (row + col) % 2 == 0 else Color("30333f")
			g.draw_rect(rect, Color(tint, 0.78))
			g.draw_rect(rect, Color(0.61, 0.76, 0.84, 0.13), false, 1)
			if not rt.sky:
				g.draw_line(rect.position + Vector2(4, rect.size.y * 0.72), rect.end - Vector2(4, rect.size.y * 0.28), Color(0.61, 0.52, 0.47, 0.12), 1)
	for t in rt.tiles:
		var rect: Rect2 = g._cell_rect(t.cell.x, t.cell.y).grow(-3)
		var color: Color = {"water": Color("53c6e4"), "lava": Color("ff7048"), "roof": Color("b094eb")}[t.kind]
		if not t.active:
			g.draw_rect(rect, Color(color, 0.08 + 0.1 * sin(t.age * 9)))
			g.draw_rect(rect, Color(color, 0.8), false, 2)
			g.draw_arc(rect.get_center(), rect.size.y * 0.25, -PI / 2, -PI / 2 + TAU * minf(1, t.age / 2), 28, color, 2, true)
			continue
		g.draw_rect(rect, Color(color.darkened(0.5), 0.94))
		if String(t.kind) == "lava" and g._cell_terrain_kind(t.cell.x, t.cell.y) != "lava":
			g.draw_rect(rect, Color("445b63"))
			continue
		match String(t.kind):
			"water":
				for n in range(4):
					var y = rect.position.y + rect.size.y * (n + 1) / 5
					g.draw_arc(Vector2(rect.get_center().x + sin(g.level_time * 2 + n) * 7, y), rect.size.x * 0.28, 0.1, PI - 0.1, 12, Color(color, 0.6), 1.5, true)
			"lava":
				for n in range(3):
					var start = rect.position + rect.size * Vector2(0.13 + n * 0.28, 0.16)
					g.draw_polyline(PackedVector2Array([start, start + Vector2(9, rect.size.y * 0.3), start + Vector2(-5, rect.size.y * 0.48), start + Vector2(12, rect.size.y * 0.65)]), Color(color, 0.7 + sin(g.level_time * 3) * 0.2), 3, true)
			"roof":
				for n in range(4):
					var start = rect.position + Vector2(0, rect.size.y * n / 4)
					g.draw_line(start, start + Vector2(rect.size.x, rect.size.y * 0.12), Color(color, 0.58), 2)
	for s in rt.strikes:
		var rect: Rect2 = g._cell_rect(s.cell.x, s.cell.y).grow(-5)
		g.draw_rect(rect, Color(1, 0.35, 0.46, 0.09 + sin(s.age * 10) * 0.04))
		g.draw_arc(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.38, -PI / 2, -PI / 2 + TAU * s.age / 1.8, 36, Color("ffbcc6"), 2.5, true)
		g.draw_line(rect.position, rect.end, Color(1, 0.4, 0.5, 0.5), 1)
		g.draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Color(1, 0.4, 0.5, 0.5), 1)

static func overlay(rt: RefCounted) -> void:
	var g: Control = rt.game
	if rt.exit_age >= 0 and rt.exit_age < 3:
		g.draw_rect(Rect2(Vector2.ZERO, g.size), Color(0.82, 0.9, 1, sin(rt.exit_age / 3 * PI) * 0.18))
	for z in g.zombies:
		if float(z.health) <= 0:
			continue
		if String(z.kind) == "star_fairy" and float(z.get("fairy_warning", 0)) > 0:
			var cell: Vector2i = z.fairy_target
			g.draw_line(Vector2(float(z.x), g._row_center_y(int(z.row)) - 20), g._cell_center(cell.x, cell.y), Color(0.83, 0.83, 1, 0.5), 1.2, true)
		if g._is_water_zombie_kind(String(z.kind)) and not g._is_water_cell(int(z.row), g._zombie_cell_col(float(z.x))):
			var pos = Vector2(float(z.x), g._row_center_y(int(z.row)))
			g.draw_arc(pos + Vector2(0, 15), g.CELL_SIZE.x * 0.3, 0.1, PI - 0.1, 16, Color(0.63, 0.89, 1, 0.7), 3, true)
		if rt.rage_multiplier(z) > 1:
			var pos = Vector2(float(z.x), g._row_center_y(int(z.row)))
			g.draw_arc(pos, g.CELL_SIZE.y * 0.37, PI, TAU, 20, Color(1, 0.24, 0.39, 0.6), 2.5, true)
	if rt.heal_factor() < 1:
		for row in g.active_rows:
			for col in range(g.COLS):
				if g._targetable_plant_at(row, col) != null:
					var p: Vector2 = g._cell_center(row, col) + Vector2(-g.CELL_SIZE.x * 0.29, -g.CELL_SIZE.y * 0.3)
					g.draw_line(p - Vector2(4, 0), p + Vector2(4, 0), Color("93aaff"), 2)
					g.draw_line(p - Vector2(0, 4), p + Vector2(0, 4), Color("93aaff"), 2)
					g.draw_line(p - Vector2(6, -6), p + Vector2(6, -6), Color("ff718a"), 1.5)
