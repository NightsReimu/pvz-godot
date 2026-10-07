extends RefCounted

# Dedicated courtyard scenery, carved stone board, living weather, ancient
# zombies and combat effects. Plants retain the shared SVG models.
const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const Details = preload("res://scripts/ui/combat_details.gd")
const UnitArt = preload("res://scripts/ui/vector_unit_art.gd")
const INK := Color("#283d37")

const SKY := {
	"clear": [Color("#9fcfe8"), Color("#f6e7c8")],
	"sunny": [Color("#ffcf7a"), Color("#fff1c6")],
	"rain": [Color("#5d7286"), Color("#9eadb5")],
	"storm": [Color("#262b45"), Color("#55607a")],
	"wind": [Color("#8fd1c6"), Color("#e9f2d7")],
	"fog": [Color("#b7c1c4"), Color("#e4e7e2")],
	"snow": [Color("#8eaec7"), Color("#e1eff4")],
	"hail": [Color("#50667f"), Color("#b5cadb")],
	"sandstorm": [Color("#b38c5c"), Color("#ebcf9a")],
	"rainbow": [Color("#91cddf"), Color("#fff0ce")],
}
const GRADE := {
	"clear": Color(1, 1, 1, 0.0), "sunny": Color(1.0, 0.82, 0.42, 0.10), "rain": Color(0.24, 0.34, 0.46, 0.16),
	"storm": Color(0.1, 0.1, 0.26, 0.26), "wind": Color(0.6, 0.92, 0.82, 0.06), "fog": Color(0.86, 0.9, 0.9, 0.10),
	"snow": Color(0.8, 0.9, 1, 0.16), "hail": Color(0.3, 0.46, 0.64, 0.14),
	"sandstorm": Color(0.78, 0.58, 0.3, 0.18), "rainbow": Color(1, 0.9, 0.7, 0.04),
}
static var stone_texture: Texture2D
static var courtyard_texture: Texture2D
static var slab_textures: Array[Texture2D] = []
const COURTYARD_PATH := "res://art/ancient/city_courtyard.png"


static func _mix(rt, table: Dictionary) -> Variant:
	var a = table.get(rt.previous_weather, table.clear)
	var b = table.get(rt.weather, table.clear)
	var t: float = ThemeLib.ease_in_out(clampf(rt.weather_blend, 0.0, 1.0))
	if a is Array:
		return [Color(a[0]).lerp(b[0], t), Color(a[1]).lerp(b[1], t)]
	return Color(a).lerp(b, t)


static func _weight(rt, kind: String) -> float:
	var t: float = ThemeLib.ease_in_out(clampf(rt.weather_blend, 0.0, 1.0))
	var w = 0.0
	if rt.weather == kind: w += t
	if rt.previous_weather == kind: w += 1.0 - t
	if kind == "rain":
		w = maxf(w, _weight_raw(rt, "storm", t))
	return clampf(w, 0.0, 1.0)


static func _weight_raw(rt, kind: String, t: float) -> float:
	var w = 0.0
	if rt.weather == kind: w += t
	if rt.previous_weather == kind: w += 1.0 - t
	return w


static func poly(canvas: CanvasItem, points: Array, color: Color, outline: float = 0.0, ink: Color = INK) -> void:
	var packed = PackedVector2Array(points)
	canvas.draw_colored_polygon(packed, color)
	if outline > 0.0:
		packed.append(packed[0])
		canvas.draw_polyline(packed, Color(ink, ink.a * color.a), outline, true)


static func oval(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, outline: float = 0.0, rotation: float = 0.0) -> void:
	var points: Array = []
	for i in range(28):
		points.append(center + Vector2(cos(i * TAU / 28.0) * radii.x, sin(i * TAU / 28.0) * radii.y).rotated(rotation))
	poly(canvas, points, color, outline)


# ---------------------------------------------------------------- scenery

static func lane_color(game: Control, rt, row: int) -> Color:
	var base = Color("#a3b0b1") if row % 2 == 0 else Color("#98a6a9")
	if rt.active():
		var grade: Color = _mix(rt, GRADE)
		base = base.lerp(Color(grade.r, grade.g, grade.b), grade.a * 1.6)
		if rt.weather in ["rain", "storm"]:
			base = base.darkened(0.12 * rt.weather_blend)
	return base


static func courtyard() -> Texture2D:
	if courtyard_texture == null and ResourceLoader.exists(COURTYARD_PATH):
		courtyard_texture = load(COURTYARD_PATH)
	return courtyard_texture


static func draw_background(game: Control, rt) -> void:
	courtyard()
	if courtyard_texture == null:
		_draw_fallback_background(game, rt)
		return
	var grade: Color = _mix(rt, GRADE)
	var tint = Color.WHITE.lerp(Color(grade.r, grade.g, grade.b), grade.a * 1.5)
	if bool(game.current_level.get("suika_banquet", false)):
		tint = Color(0.53, 0.43, 0.69)
	var tex: Vector2 = courtyard_texture.get_size()
	var origin: Vector2 = game.BOARD_ORIGIN
	var bottom: float = origin.y + game.board_size.y
	var right: float = origin.x + game.board_size.x
	# Four architectural bands meet the real board edges instead of being hidden
	# behind the HUD or stretched into the lanes on different aspect ratios.
	game.draw_texture_rect(courtyard_texture, Rect2(Vector2.ZERO, game.size), false, tint)
	_draw_city_region(game, Rect2(0, 0, game.size.x, origin.y), Rect2(0, 0, tex.x, tex.y * 0.31), tint)
	_draw_city_region(game, Rect2(0, origin.y, origin.x, game.board_size.y), Rect2(0, tex.y * 0.31, tex.x * 0.12, tex.y * 0.58), tint)
	_draw_city_region(game, Rect2(right, origin.y, game.size.x - right, game.board_size.y), Rect2(tex.x * 0.87, tex.y * 0.31, tex.x * 0.13, tex.y * 0.58), tint)
	_draw_city_region(game, Rect2(0, bottom, game.size.x, game.size.y - bottom), Rect2(0, tex.y * 0.89, tex.x, tex.y * 0.11), tint)
	# Lantern illumination gets warmer as the courtyard darkens.
	var dusk = maxf(_weight(rt, "storm"), maxf(_weight(rt, "rain"), _weight(rt, "fog")))
	for side in [-1, 1]:
		var lamp = Vector2(origin.x * 0.58 if side < 0 else right + (game.size.x - right) * 0.42, origin.y + game.board_size.y * 0.32)
		var pulse = 0.75 + sin(game.ui_time * 2.2 + side) * 0.15
		game.draw_circle(lamp, minf(30.0, origin.x * 0.2), Color(1, 0.68, 0.25, 0.055 * pulse * (0.5 + dusk)))


static func _draw_city_region(game: Control, destination: Rect2, source: Rect2, tint: Color) -> void:
	if destination.size.x > 0 and destination.size.y > 0:
		game.draw_texture_rect_region(courtyard_texture, destination, source, tint)


static func slab_rect(game: Control, row: int, col: int) -> Rect2:
	return game._cell_rect(row, col).grow(-maxf(1.1, minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 0.022))


static func slab_texture(row: int, col: int) -> Texture2D:
	if slab_textures.is_empty():
		for variant in range(3):
			var path = "res://art/vector/ancient/courtyard_slab_%d.svg" % variant
			if ResourceLoader.exists(path): slab_textures.append(load(path))
	return null if slab_textures.is_empty() else slab_textures[(row * 13 + col * 7) % slab_textures.size()]


static func draw_board(game: Control, rt) -> void:
	var grade: Color = _mix(rt, GRADE)
	var wet = maxf(_weight(rt, "rain"), _weight(rt, "storm"))
	var tint = Color.WHITE.lerp(Color(grade.r, grade.g, grade.b), grade.a * 1.2).darkened(wet * 0.12)
	var board = Rect2(game.BOARD_ORIGIN, game.board_size)
	var rim = maxf(4.0, minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 0.08)
	game.draw_rect(board.grow(rim + 3), Color("#3f5055") * tint, true)
	game.draw_rect(board.grow(rim), Color("#869698") * tint, true)
	game.draw_rect(board.grow(rim * 0.4), Color("#c1b18e") * tint, false, maxf(1.0, rim * 0.3))
	game.draw_rect(board, Color("#4f6468") * tint, true)
	for row in range(game.board_rows):
		for col in range(game.COLS):
			var slab = slab_rect(game, row, col)
			var tone = tint.darkened(0.025 * ((row * 7 + col * 3) % 3))
			if not game._is_row_active(row): tone = tone.darkened(0.5)
			var texture = slab_texture(row, col)
			if texture == null:
				game.draw_rect(slab, Color("#a3afb2") * tone, true)
			else:
				game.draw_texture_rect(texture, slab, false, tone)
			# Only the joints grow moss; the slab face stays clear for the units.
			if (row + col) % 3 == 0:
				var p = slab.position + Vector2(slab.size.x * 0.82, slab.size.y + 1)
				oval(game, p, Vector2(slab.size.x * 0.09, maxf(1.0, rim * 0.16)), Color(0.26, 0.37, 0.29, 0.55))
			if wet > 0.01:
				game.draw_line(slab.position + Vector2(8, 6), slab.position + Vector2(slab.size.x - 8, 6), Color(0.83, 0.91, 0.96, 0.2 * wet), 1, true)
	# Carved bronze corner keys tie the planting platform to the ancient walls.
	for corner in [board.position, Vector2(board.end.x, board.position.y), board.end, Vector2(board.position.x, board.end.y)]:
		game.draw_circle(corner, rim * 0.56, Color("#c7a66a") * tint)
		game.draw_circle(corner, rim * 0.24, Color("#677577") * tint)
	if game.size.y >= 500:
		var numerals = ["壹", "贰", "叁", "肆", "伍", "陆"]
		for row in game.active_rows:
			var c = Vector2(game.BOARD_ORIGIN.x - rim - 18, game._row_center_y(int(row)))
			oval(game, c, Vector2(12, 19), Color("#56686a"), 1, 0)
			ThemeLib.draw_label(game, game.ui_font, Rect2(c - Vector2(10, 16), Vector2(20, 32)), numerals[int(row)], 14, Color("#d6c49c"))


static func _draw_fallback_background(game: Control, rt) -> void:
	var size: Vector2 = game.size
	var origin: Vector2 = game.BOARD_ORIGIN
	var board: Vector2 = game.board_size
	var horizon = origin.y - 8.0
	var sky: Array = _mix(rt, SKY)
	var grade: Color = _mix(rt, GRADE)
	var time: float = game.ui_time
	ThemeLib.draw_gradient_rect_v(game, Rect2(Vector2.ZERO, Vector2(size.x, horizon + 40.0)), sky[0], sky[1])
	var sun_w = maxf(_weight(rt, "sunny"), maxf(_weight(rt, "clear") * 0.6, _weight(rt,"rainbow")*0.5))
	var sun = Vector2(size.x * 0.83, horizon * 0.35)
	for i in range(4):
		game.draw_circle(sun, 22.0 + i * 14.0, Color(1.0, 0.92, 0.6, 0.07 * sun_w))
	game.draw_circle(sun, 22.0, Color(1.0, 0.95, 0.74, sun_w))
	# Low cloud banks and three ink-wash ridges keep the skyline behind the HUD.
	for layer in range(3):
		var points: Array = [Vector2(0,horizon+40)]
		for i in range(49):
			var x = size.x*i/48.0
			var y = horizon*(0.65+layer*0.12)-absf(sin(x*(0.003+layer*0.002)+layer*3.7))*horizon*(0.28-layer*0.06)
			points.append(Vector2(x,y))
		points.append(Vector2(size.x,horizon+40))
		var color = Color("#a6bec2").lerp(Color("#4c776d"), layer/2.0)
		poly(game,points,color.lerp(Color(grade.r,grade.g,grade.b),grade.a))
	for i in range(6):
		var drift = fmod(time*(3.0+i)+i*270.0,size.x+400)-200
		oval(game,Vector2(drift,horizon*(0.52+(i%3)*0.15)),Vector2(170,8),Color(1,1,1,0.13))
	var cloud_tint = Color("#f5f1e4").lerp(Color("#445063"),maxf(_weight(rt,"storm"),_weight(rt,"hail")))
	for i in range(5):
		var x = fmod(i*369.0+time*9.0,size.x+300)-150
		var c = Vector2(x,horizon*0.22+(i%2)*13)
		for k in range(3):
			oval(game,c+Vector2(k*42-42,sin(k*1.7)*9),Vector2(58,17),Color(cloud_tint,0.3))
	# Cached, hand-authored stone texture replaces repeated gravel linework.
	var stone_color = Color.WHITE.lerp(Color(grade.r,grade.g,grade.b),grade.a*1.4)
	game.draw_rect(Rect2(Vector2(0,horizon),Vector2(size.x,size.y-horizon)),Color("#aeb18e").lerp(Color(grade.r,grade.g,grade.b),grade.a))
	if stone_texture == null: stone_texture = load("res://art/vector/ancient/courtyard_stone.svg")
	if stone_texture != null:
		_stone_patch(game,Rect2(Vector2(0,horizon),Vector2(origin.x,size.y-horizon)),stone_color)
		_stone_patch(game,Rect2(Vector2(origin.x+board.x,horizon),Vector2(maxf(0,size.x-origin.x-board.x),size.y-horizon)),stone_color)
		_stone_patch(game,Rect2(Vector2(origin.x,origin.y+board.y),Vector2(board.x,maxf(0,size.y-origin.y-board.y))),stone_color)
	# Shrine roofs, a garden wall and carved stone rails frame the playing lawn.
	var scenery_scale = clampf(horizon/170.0,0.38,1.0)
	_draw_pagoda(game,Vector2(size.x-170.0*scenery_scale,horizon+5),scenery_scale,grade)
	if size.y >= 500: _draw_temple_hall(game,Vector2(65,horizon+6),grade)
	for x in range(int(origin.x),int(origin.x+board.x),72):
		game.draw_rect(Rect2(x,horizon-16,68,18),Color("#eee2bd").lerp(Color(grade.r,grade.g,grade.b),grade.a))
		game.draw_line(Vector2(x,horizon-17),Vector2(x+68,horizon-17),Color("#617e65"),4,true)
		game.draw_rect(Rect2(x+10,horizon-11,48,7),Color("#a5b598"),false,1)
	var right = origin.x+board.x
	_draw_torii(game,Vector2(right+maxf(35,(size.x-right)*0.48),horizon+20),scenery_scale,grade)
	for side in [-1,1]:
		var x = origin.x-16 if side < 0 else right+10
		game.draw_rect(Rect2(x,origin.y-5,6,board.y+10),Color("#526b48"),true)
		for row in game.active_rows:
			var y: float = game._row_center_y(int(row))
			oval(game,Vector2(x+3,y),Vector2(9,28),Color("#92a77b"),1.4)
			game.draw_line(Vector2(x-2,y-14),Vector2(x+7,y-14),Color("#d9d3aa"),1.5,true)
	for i in range(5):
		_draw_lantern(game,Vector2(origin.x+50+i*board.x/4.4,horizon),scenery_scale*0.62,rt)
	_draw_maple(game,Vector2(origin.x-25,horizon-8),time,rt)
	# Low bushes and scattered autumn leaves soften the stone path below the board.
	for i in range(16):
		var p = Vector2(origin.x+i*board.x/15.0,origin.y+board.y+14)
		oval(game,p,Vector2(26,9),Color("#597847"),1.0)
		oval(game,p+Vector2(5,-3),Vector2(17,5),Color("#81934f"))
		for k in range(2):
			oval(game,p+Vector2(k*16-5,18+sin(i+k)*7),Vector2(5,2),Color("#b6814e"),0,i)


static func _stone_patch(game: Control, rect: Rect2, color: Color) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0: return
	game.draw_texture_rect(stone_texture,rect,true,color)


static func _draw_pagoda(game: Control, base: Vector2, s: float, grade: Color) -> void:
	var wall = Color("#7d4a3a").lerp(Color(grade.r, grade.g, grade.b), grade.a * 1.5)
	var roof = Color("#3e4a52").lerp(Color(grade.r, grade.g, grade.b), grade.a * 1.5)
	for tier in range(5):
		var w = (64.0 - tier * 9.0) * s
		var y = base.y - tier * 26.0 * s
		game.draw_rect(Rect2(Vector2(base.x - w * 0.36, y - 20.0 * s), Vector2(w * 0.72, 18.0 * s)), wall, true)
		poly(game, [Vector2(base.x - w * 0.7, y - 18.0 * s), Vector2(base.x - w * 0.42, y - 27.0 * s), Vector2(base.x + w * 0.42, y - 27.0 * s), Vector2(base.x + w * 0.7, y - 18.0 * s), Vector2(base.x + w * 0.5, y - 21.0 * s), Vector2(base.x - w * 0.5, y - 21.0 * s)], roof)
	game.draw_line(Vector2(base.x, base.y - 130.0 * s), Vector2(base.x, base.y - 160.0 * s), roof, 3.0 * s)
	for i in range(4):
		game.draw_circle(Vector2(base.x, base.y - (136.0 + i * 6.0) * s), 3.2 * s, roof)


static func _draw_temple_hall(game: Control, base: Vector2, grade: Color) -> void:
	var tone = Color(grade.r, grade.g, grade.b)
	var pillar = Color("#c8432f").lerp(tone, grade.a)
	var roof = Color("#3b4954").lerp(tone, grade.a)
	game.draw_rect(Rect2(base + Vector2(-110, -80), Vector2(200, 80)), Color("#efe2c4").lerp(tone, grade.a), true)
	for i in range(5):
		game.draw_rect(Rect2(base + Vector2(-104 + i * 46, -80), Vector2(9, 80)), pillar, true)
	for i in range(4):
		var panel = Rect2(base + Vector2(-92 + i * 46, -70), Vector2(34, 52))
		game.draw_rect(panel, Color("#f8f0da").lerp(tone, grade.a), true)
		for k in range(1, 3):
			game.draw_line(panel.position + Vector2(panel.size.x * k / 3.0, 0), panel.position + Vector2(panel.size.x * k / 3.0, panel.size.y), Color("#a88b62", 0.7), 1.0)
		game.draw_line(panel.position + Vector2(0, panel.size.y * 0.5), panel.position + Vector2(panel.size.x, panel.size.y * 0.5), Color("#a88b62", 0.7), 1.0)
	poly(game, [base + Vector2(-150, -78), base + Vector2(-120, -96), base + Vector2(-70, -132), base + Vector2(50, -132), base + Vector2(100, -96), base + Vector2(130, -78), base + Vector2(100, -86), base + Vector2(-120, -86)], roof, 2.0)
	game.draw_line(base + Vector2(-70, -132), base + Vector2(50, -132), Color("#d8b25c"), 3.0)
	poly(game, [base + Vector2(-160, -76), base + Vector2(-146, -86), base + Vector2(-138, -78)], roof)
	poly(game, [base + Vector2(140, -76), base + Vector2(126, -86), base + Vector2(118, -78)], roof)


static func _draw_torii(game: Control, base: Vector2, s: float, grade: Color) -> void:
	var red = Color("#d6402d").lerp(Color(grade.r, grade.g, grade.b), grade.a)
	var dark = Color("#2d2a2a")
	for side in [-1.0, 1.0]:
		game.draw_rect(Rect2(base + Vector2(side * 46.0 - 6.0, 0.0) * s, Vector2(12.0, 150.0) * s), red, true)
		game.draw_rect(Rect2(base + Vector2(side * 46.0 - 8.0, 138.0) * s, Vector2(16.0, 14.0) * s), dark, true)
	game.draw_rect(Rect2(base + Vector2(-62.0, 18.0) * s, Vector2(124.0, 10.0) * s), red, true)
	poly(game, [base + Vector2(-82, -10) * s, base + Vector2(82, -10) * s, base + Vector2(72, 2) * s, base + Vector2(-72, 2) * s], dark)
	poly(game, [base + Vector2(-74, 2) * s, base + Vector2(74, 2) * s, base + Vector2(68, 9) * s, base + Vector2(-68, 9) * s], red)
	game.draw_rect(Rect2(base + Vector2(-6.0, 9.0) * s, Vector2(12.0, 12.0) * s), red, true)


static func _draw_lantern(game: Control, base: Vector2, s: float, rt) -> void:
	var stone = Color("#a4a39a")
	game.draw_rect(Rect2(base + Vector2(-5, -6) * s, Vector2(10, 26) * s), stone.darkened(0.08), true)
	poly(game, [base + Vector2(-14, -6) * s, base + Vector2(14, -6) * s, base + Vector2(10, 0) * s, base + Vector2(-10, 0) * s], stone.darkened(0.2))
	game.draw_rect(Rect2(base + Vector2(-9, -24) * s, Vector2(18, 18) * s), stone, true)
	var glow = 0.35 + 0.25 * sin(game.ui_time * 2.4 + base.x)
	if rt.weather in ["rain", "storm", "fog"]:
		glow += 0.25
	game.draw_rect(Rect2(base + Vector2(-5, -20) * s, Vector2(10, 10) * s), Color(1.0, 0.82, 0.42, glow), true)
	game.draw_circle(base + Vector2(0, -15) * s, 16.0 * s, Color(1.0, 0.82, 0.42, glow * 0.15))
	poly(game, [base + Vector2(-17, -24) * s, base + Vector2(0, -36) * s, base + Vector2(17, -24) * s], stone.darkened(0.15), 1.2)
	game.draw_circle(base + Vector2(0, -38) * s, 3.0 * s, stone.darkened(0.2))


static func _draw_maple(game: Control, base: Vector2, time: float, rt) -> void:
	game.draw_line(base + Vector2(-30, 40), base + Vector2(-6, -40), Color("#5a3a26"), 9.0, true)
	game.draw_line(base + Vector2(-12, -18), base + Vector2(36, -50), Color("#5a3a26"), 5.0, true)
	var sway = sin(time * 1.3) * 3.0
	for i in range(14):
		var p = base + Vector2(-40 + (i * 37) % 100, -60 + (i * 23) % 44) + Vector2(sway, 0)
		game.draw_circle(p, 16.0 + (i % 3) * 4.0, Color("#d9573b").lerp(Color("#f0a04a"), (i % 4) / 4.0) * Color(1, 1, 1, 0.82))


static func draw_ground(game: Control, rt) -> void:
	var time: float = game.ui_time
	var wet = maxf(_weight(rt, "rain"), _weight(rt, "storm"))
	if wet > 0.01:
		for i in range(18):
			var phase = fposmod(time * 1.6 + i * 0.37, 1.0)
			var p = Vector2(game.BOARD_ORIGIN.x + fposmod(i * 197.3, game.board_size.x), game.BOARD_ORIGIN.y + fposmod(i * 131.7, game.board_size.y))
			oval(game, p, Vector2(14.0 + phase * 8.0, 3.0 + phase * 2.0), Color(0.7, 0.84, 0.91, 0.07 * wet))
			game.draw_arc(p, 3.0 + phase * 12.0, 0.0, TAU, 18, Color(0.85, 0.95, 1.0, (1.0 - phase) * 0.3 * wet), 1.0, true)
	var snow = maxf(_weight(rt, "snow"), _weight(rt, "hail") * 0.5)
	if snow > 0.01:
		for row in game.active_rows:
			for col in range(game.COLS):
				var cell = slab_rect(game, int(row), col)
				oval(game, cell.position + Vector2(cell.size.x * 0.5, cell.size.y - 5), Vector2(cell.size.x * 0.42, minf(5.0, cell.size.y * 0.06)), Color(0.92, 0.97, 1.0, 0.62 * snow))
				oval(game, cell.position + Vector2(cell.size.x * 0.15, 4), Vector2(cell.size.x * 0.1, 2), Color(1, 1, 1, 0.55 * snow))


static func draw_corrosion(game: Control, rt) -> void:
	for cell in rt.corroded:
		if not rt.is_corroded(cell):
			continue
		var c: Vector2 = game._cell_center(cell.x, cell.y)
		var remaining: float = float(rt.corroded[cell]) - game.level_time
		var fade = clampf(remaining / 1.2, 0.0, 1.0)
		var cell_rect = Rect2(c - game.CELL_SIZE * 0.46, game.CELL_SIZE * 0.92)
		game.draw_rect(cell_rect, Color(0.62, 0.52, 0.2, 0.18 * fade), true)
		for k in range(4):
			var blot = c + Vector2(sin(cell.x * 3.1 + k * 1.7) * 26.0, cos(cell.y * 2.3 + k * 2.1) * 22.0 + 10.0)
			oval(game, blot, Vector2(16.0 - k * 2.0, 8.0 - k), Color(0.74, 0.6, 0.22, 0.22 * fade))
		var petal = c + Vector2(sin(game.level_time + cell.y) * 12.0, 18.0)
		for p in range(5):
			oval(game, petal + Vector2.from_angle(p * TAU / 5.0) * 4.0, Vector2(3.4, 2.2), Color(1, 1, 0.96, 0.7 * fade), 0.0, p * TAU / 5.0)
		game.draw_circle(petal, 1.8, Color(1.0, 0.86, 0.42, fade))
		for k in range(2):
			var rise = fmod(game.level_time * 18.0 + k * 22.0 + cell.y * 9.0, 40.0)
			var wisp = c + Vector2(-14 + k * 26, 24 - rise)
			game.draw_arc(wisp, 6.0, PI * 0.2, PI * 1.3, 10, Color(0.95, 0.92, 0.82, (1.0 - rise / 40.0) * 0.4 * fade), 1.6, true)


static func draw_wave(game: Control, wave: Dictionary) -> void:
	var time: float = game.level_time
	if true:
		var base: float = game._row_center_y(int(wave.row)) + 32.0
		var start: float = float(wave.start_x)
		var front: float = float(wave.front_x)
		var fade = clampf(float(wave.time) / 0.6, 0.0, 1.0)
		var span = maxf(1.0, front - start)
		var top = PackedVector2Array()
		for i in range(25):
			var t = i / 24.0
			var h = 8.0 + 46.0 * t * t + sin(i * 0.9 + time * 12.0) * 3.0 * t
			top.append(Vector2(start + span * t, base - h))
		var body = top.duplicate()
		body.append(Vector2(front + 14.0, base))
		body.append(Vector2(start, base))
		game.draw_colored_polygon(body, Color(0.98, 0.96, 0.9, 0.82 * fade))
		var shade = PackedVector2Array()
		for i in range(25):
			shade.append(Vector2(top[i].x, minf(top[i].y + 10.0 + 6.0 * i / 24.0, base - 2.0)))
		shade.append(Vector2(front + 10.0, base))
		shade.append(Vector2(start, base))
		game.draw_colored_polygon(shade, Color(0.9, 0.86, 0.74, 0.5 * fade))
		game.draw_polyline(top, Color(0.68, 0.62, 0.5, fade), 2.0, true)
		# Curling crest breaking forward over the zombies.
		var crest = Vector2(front - 2.0, base - 56.0)
		var curl = PackedVector2Array()
		for k in range(13):
			var a = PI + k * PI / 12.0
			curl.append(crest + Vector2(cos(a) * 24.0, sin(a) * 18.0))
		curl.append(crest + Vector2(22.0, 14.0))
		curl.append(crest + Vector2(-24.0, 14.0))
		game.draw_colored_polygon(curl, Color(1.0, 0.99, 0.95, 0.95 * fade))
		game.draw_polyline(curl, Color(0.68, 0.62, 0.5, fade), 2.0, true)
		game.draw_arc(crest + Vector2(2, 3), 7.0, PI * 0.9, PI * 2.2, 14, Color(0.86, 0.8, 0.66, fade), 1.6, true)
		game.draw_line(Vector2(start + 6.0, base - 8.0), Vector2(front - 10.0, base - 30.0), Color(1.0, 0.86, 0.42, 0.45 * fade), 2.0, true)
		for k in range(9):
			var arc = fmod(time * 2.4 + k * 0.11, 1.0)
			var drop = crest + Vector2(6.0 + arc * 34.0 + sin(k * 2.3) * 6.0, -10.0 - sin(arc * PI) * 26.0 + k % 3 * 3.0)
			game.draw_circle(drop, 3.2 - (k % 3) * 0.6, Color(1, 1, 0.97, 0.9 * fade * (1.0 - arc * 0.6)))
		if bool(wave.get("empowered", false)):
			game.draw_line(Vector2(start, base - 4), Vector2(front, base - 4), Color(1.0, 0.82, 0.32, 0.6 * fade), 3.0, true)


static func draw_hex(game: Control, hex: Dictionary) -> void:
	if true:
		var t = 1.0 - clampf(float(hex.time) / float(hex.duration), 0.0, 1.0)
		var to: Vector2 = game._cell_center(hex.cell.x, hex.cell.y) + Vector2(0, -16)
		var from: Vector2 = hex.from
		var p = from.lerp(to, t) + Vector2(0, -sin(t * PI) * 60.0)
		for k in range(5):
			var trail = from.lerp(to, maxf(0.0, t - k * 0.04)) + Vector2(0, -sin(maxf(0.0, t - k * 0.04) * PI) * 60.0)
			game.draw_circle(trail, 7.0 - k, Color(0.78, 0.6, 1.0, 0.5 - k * 0.09))
		game.draw_circle(p, 6.0, Color(0.98, 0.9, 1.0, 0.95))
		for k in range(4):
			var a = game.level_time * 6.0 + k * TAU / 4.0
			game.draw_line(p + Vector2.from_angle(a) * 8.0, p + Vector2.from_angle(a) * 13.0, Color(0.86, 0.72, 1.0, 0.8), 1.6, true)
		game.draw_arc(to, 28.0 * t + 6.0, 0.0, TAU, 28, Color(0.78, 0.6, 1.0, 0.45 * t), 2.0, true)


static func draw_strike_cue(game: Control, strike: Dictionary) -> void:
	if true:
		var p: Vector2 = strike.position
		var pulse: float = 0.5 + 0.5 * sin(game.level_time * 30.0)
		game.draw_arc(p + Vector2(0, 30), 26.0, 0.0, TAU, 24, Color(1.0, 0.96, 0.6, 0.35 + pulse * 0.4), 2.5, true)
		game.draw_line(p + Vector2(0, -140), p + Vector2(0, 20), Color(0.9, 0.9, 1.0, 0.12 + pulse * 0.1), 3.0, true)


# ---------------------------------------------------------------- weather overlays

static func draw_weather(game: Control, rt) -> void:
	var size: Vector2 = game.size
	var time: float = game.level_time
	var grade: Color = _mix(rt, GRADE)
	if grade.a > 0.0:
		game.draw_rect(Rect2(Vector2.ZERO, size), Color(grade, grade.a * 0.35), true)
	var rain = _weight(rt, "rain")
	var storm_w: float = _weight_raw(rt, "storm", ThemeLib.ease_in_out(clampf(rt.weather_blend, 0.0, 1.0)))
	if rain > 0.01:
		var drops = int(70 + storm_w * 70)
		for i in range(drops):
			var x = fmod(i * 97.13 + time * (180.0 + storm_w * 120.0), size.x + 120.0) - 60.0
			var y = fmod(i * 53.71 + time * (720.0 + (i % 5) * 40.0), size.y + 80.0) - 40.0
			var length = 14.0 + (i % 4) * 4.0 + storm_w * 8.0
			game.draw_line(Vector2(x, y), Vector2(x - length * 0.32, y + length), Color(0.82, 0.9, 1.0, (0.22 + (i % 3) * 0.06) * rain), 1.3, true)
	if storm_w > 0.01:
		var flash = 0.0
		for effect in game.effects:
			if String(effect.get("shape", "")) == "ancient_lightning":
				flash = maxf(flash, float(effect.time) / float(effect.duration))
		if flash > 0.0:
			game.draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.92, 1.0, 0.22 * flash * flash), true)
	var wind = _weight(rt, "wind")
	if wind > 0.01:
		for i in range(26):
			var y = 40.0 + fmod(i * 41.3, size.y - 60.0)
			var x = size.x - fmod(i * 173.1 + time * (420.0 + (i % 4) * 70.0), size.x + 400.0) + 200.0
			var curve = PackedVector2Array()
			var length = 10 + i % 4 * 3
			for k in range(length):
				curve.append(Vector2(x + k * 12.0, y + sin(time * 3.0 + i + k * 0.5) * 5.0))
			for k in range(length - 1):
				var fade_in = sin(PI * float(k) / float(length - 1))
				game.draw_line(curve[k], curve[k + 1], Color(1, 1, 1, 0.42 * wind * fade_in), 2.4, true)
			if i % 5 == 0:
				game.draw_arc(curve[0] + Vector2(-8, -6), 8.0, PI * 0.5, PI * 1.9, 12, Color(1, 1, 1, 0.35 * wind), 2.0, true)
		for i in range(20):
			var p = Vector2(size.x - fmod(i * 211.0 + time * 330.0, size.x + 120.0) + 60.0, 80.0 + fmod(i * 67.0 + sin(time + i) * 30.0, size.y - 120.0))
			var tint = Color("#f2a8b8") if i % 3 else Color("#e9884e")
			oval(game, p, Vector2(6.0, 3.0), Color(tint, 0.9 * wind), 0.8, time * 4.0 + i)
	var fog = _weight(rt, "fog")
	if fog > 0.01:
		var origin: Vector2 = game.BOARD_ORIGIN
		var board: Vector2 = game.board_size
		for i in range(9):
			var drift = fmod(time * (10.0 + i * 3.0) + i * 180.0, board.x + 400.0) - 200.0
			var y = origin.y + 30.0 + i * board.y / 8.5
			for layer in range(3):
				oval(game, Vector2(origin.x + board.x - drift, y), Vector2(260.0 - layer * 60.0, 54.0 - layer * 14.0), Color(0.93, 0.95, 0.94, 0.09 * fog))
		var edge = origin.x + game.CELL_SIZE.x * 5.0
		ThemeLib.draw_gradient_rect_h(game, Rect2(Vector2(edge, origin.y - 20.0), Vector2(size.x - edge, board.y + 40.0)), Color(0.92, 0.94, 0.93, 0.0), Color(0.92, 0.94, 0.93, 0.5 * fog))
	var sunny = _weight(rt, "sunny")
	if sunny > 0.01:
		for i in range(5):
			var x = size.x * 0.82 - i * 210.0
			poly(game, [Vector2(x - 20.0, 0.0), Vector2(x + 30.0, 0.0), Vector2(x - 260.0, size.y), Vector2(x - 380.0, size.y)], Color(1.0, 0.94, 0.7, 0.05 * sunny))
	var snow = _weight(rt,"snow")
	var hail = _weight(rt,"hail")
	if maxf(snow,hail) > 0.01:
		for i in range(70):
			var weight = hail if i % 3 == 0 and hail > 0.01 else maxf(snow,hail*0.4)
			var p = Vector2(fposmod(i*113.7-time*30+sin(time+i)*14,size.x),fposmod(i*59.3+time*(410 if hail > 0.2 else 70+(i%4)*16),size.y))
			var r = 1.7+(i%3)*0.9
			game.draw_circle(p,r,Color(0.9,0.97,1,0.75*weight))
			if i % 7 == 0 and snow > 0.1:
				for k in range(3):
					var ray = Vector2.from_angle(k*PI/3)*4
					game.draw_line(p-ray,p+ray,Color(1,1,1,0.6*snow),1.0,true)
	var sand = _weight(rt,"sandstorm")
	if sand > 0.01:
		for i in range(18):
			var p = Vector2(size.x-fposmod(i*159+time*(110+(i%4)*30),size.x+300)+150,game.BOARD_ORIGIN.y+fposmod(i*61.3,game.board_size.y))
			oval(game,p,Vector2(140,18+(i%3)*8),Color(0.8,0.67,0.42,0.09*sand))
		for i in range(60):
			var p = Vector2(fposmod(i*199-time*280,size.x),fposmod(i*47+sin(time+i)*6,size.y))
			game.draw_line(p,p+Vector2(9,-2),Color(0.99,0.86,0.61,0.4*sand),1.2,true)
	var rainbow = _weight(rt,"rainbow")
	if rainbow > 0.01:
		var palette = [Color("#f5a5a4"),Color("#f5c27d"),Color("#f2e2a3"),Color("#a7d697"),Color("#8bcbdc"),Color("#b9a4da")]
		var c = Vector2(game.BOARD_ORIGIN.x+game.board_size.x*0.65,game.BOARD_ORIGIN.y+game.board_size.y*0.25)
		for k in range(6):
			game.draw_arc(c,game.board_size.x*0.42+k*7,PI*1.03,PI*1.97,72,Color(palette[k],0.24*rainbow),6.5,true)
		for i in range(24):
			var p = game.BOARD_ORIGIN+Vector2(fposmod(i*109.3,game.board_size.x),fposmod(i*51.7-time*16,game.board_size.y))
			var alpha = (0.4+sin(time*2+i)*0.3)*rainbow
			game.draw_circle(p,1.6,Color(palette[i%6],alpha))


static func draw_weather_chip(game: Control, rt) -> void:
	var rect = Rect2(game.BOARD_ORIGIN.x + game.board_size.x - 380.0, game.SEED_BANK_RECT.end.y + 6.0, 380.0, 34.0)
	var compact: bool = game._is_mobile_runtime()
	if compact:
		# Phone HUDs fill the top row; the forecast hangs under the lawn instead.
		rect = Rect2(game.BOARD_ORIGIN.x + game.board_size.x - 300.0, game.BOARD_ORIGIN.y + game.board_size.y + 4.0, 300.0, 28.0)
		if game._is_minigame(): rect.position = Vector2(game.SEED_BANK_RECT.end.x-310,game.SEED_BANK_RECT.position.y+14)
		if bool(game.current_level.get("suika_banquet", false)) or String(game.current_level.get("id", "")) == "4-23":
			# Touhou phase names occupy the space below the board on phones.
			rect = Rect2(game.BOARD_ORIGIN.x + game.board_size.x - 260.0, game.BOARD_ORIGIN.y - 27.0, 260.0, 24.0)
			if String(game.current_level.get("id", "")) == "4-23": rect.position.x = game.BOARD_ORIGIN.x
	elif game.SEED_BANK_RECT.end.y + 46.0 > game.BOARD_ORIGIN.y:
		rect.position.y = game.BOARD_ORIGIN.y - 40.0
	if String(game.current_level.get("id", "")) == "4-23": rect.position.x = game.BOARD_ORIGIN.x
	var info: Dictionary = rt.weather_info().duplicate()
	var clear_night: bool = bool(game.current_level.get("suika_banquet", false)) and String(rt.weather) == "clear"
	if clear_night:
		info.name = "晴夜"
		info.summary = "酒宴庭院 · 无天气修正"
		info.color = Color("c7a6e7")
	var accent: Color = info.color
	ThemeLib.draw_rounded_panel(game, rect, Color(0.12, 0.14, 0.16, 0.86), accent.darkened(0.2), 10.0, 0.18, 0.08)
	var icon = rect.position + Vector2(20.0, 17.0)
	if clear_night:
		game.draw_circle(icon, 7, Color("f4d597"))
		game.draw_circle(icon + Vector2(3, -2), 6, Color("393345"))
	else:
		draw_weather_icon(game, icon, rt.weather, 1.0, game.ui_time)
	var overridden: bool = not rt.override_weather.is_empty()
	var owner_name := "早苗" if String(game.current_level.get("id", "")) == "4-23" and game.zombies.any(func(z): return int(z.get("uid", -2)) == int(rt.override_owner) and String(z.kind) == "sanae_boss") else "军师"
	var title = "%s%s" % [String(info.name), "  · " + owner_name if overridden else ""]
	var summary_offset: float = 132.0 if not compact else 112.0
	if String(game.current_level.get("id", "")) == "4-23" and overridden:
		summary_offset = maxf(summary_offset, 40.0 + game.ui_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 12.0)
	ThemeLib.draw_label(game, game.ui_font, Rect2(rect.position + Vector2(40, 2), Vector2(maxf(96.0, summary_offset - 48.0), 30)), title, 16, accent.lightened(0.3) if not overridden else Color("#ff9d8a"))
	ThemeLib.draw_label(game, game.ui_font, Rect2(rect.position + Vector2(summary_offset, 2), Vector2(rect.size.x - summary_offset - 8.0, rect.size.y - 4)), String(info.summary), 12 if not compact else 10, Color(0.9, 0.93, 0.9, 0.86))
	var remaining: float = rt.schedule_remaining()
	var schedule: Array = game.current_level.get("weather_schedule", [])
	var total = 30.0
	if overridden:
		total = 12.0
	elif not schedule.is_empty():
		total = float(schedule[rt.schedule_index % schedule.size()].get("duration", 30.0))
	var ratio = clampf(remaining / maxf(1.0, total), 0.0, 1.0)
	game.draw_rect(Rect2(rect.position + Vector2(10, rect.size.y - 5), Vector2((rect.size.x - 20) * ratio, 3)), Color(accent, 0.85), true)


static func draw_weather_icon(canvas: CanvasItem, c: Vector2, kind: String, s: float, time: float) -> void:
	match kind:
		"sunny", "clear":
			var sun = Color("#ffd35a") if kind == "sunny" else Color("#ffe9a3")
			for i in range(8):
				var dir = Vector2.from_angle(i * TAU / 8.0 + time * 0.6)
				canvas.draw_line(c + dir * 8.0 * s, c + dir * 12.0 * s, sun, 2.0 * s, true)
			canvas.draw_circle(c, 6.5 * s, sun)
			if kind == "clear":
				oval(canvas, c + Vector2(5, 4) * s, Vector2(7, 4) * s, Color(1, 1, 1, 0.95))
		"rain", "storm":
			oval(canvas, c + Vector2(0, -3) * s, Vector2(11, 6) * s, Color("#d8e2ea") if kind == "rain" else Color("#8c90b4"))
			oval(canvas, c + Vector2(-5, -6) * s, Vector2(6, 5) * s, Color("#e6edf2") if kind == "rain" else Color("#9fa2c4"))
			if kind == "rain":
				for i in range(3):
					var y = fmod(time * 20.0 + i * 4.0, 10.0)
					canvas.draw_line(c + Vector2(-6 + i * 6, 3 + y * 0.6) * s, c + Vector2(-8 + i * 6, 7 + y * 0.6) * s, Color("#8cc8ff"), 1.6 * s, true)
			else:
				poly(canvas, [c + Vector2(1, 1) * s, c + Vector2(-4, 9) * s, c + Vector2(0, 9) * s, c + Vector2(-3, 15) * s, c + Vector2(5, 5) * s, c + Vector2(1, 5) * s], Color("#ffe86a"))
		"wind":
			for i in range(3):
				var curve = PackedVector2Array()
				for k in range(7):
					curve.append(c + Vector2(-10 + k * 3.5, -6 + i * 6 + sin(time * 4.0 + k + i) * 1.4) * s)
				canvas.draw_polyline(curve, Color("#c9f3e6"), 1.8 * s, true)
		"fog":
			for i in range(3):
				canvas.draw_line(c + Vector2(-10 + (i % 2) * 3, -5 + i * 5) * s, c + Vector2(10 - (i % 2) * 3, -5 + i * 5) * s, Color("#e8eeee"), 2.4 * s, true)
		"snow", "hail":
			oval(canvas,c+Vector2(0,-5)*s,Vector2(11,5)*s,Color("#d5e8f1"))
			for i in range(3):
				var p = c+Vector2((i-1)*7,4+sin(time*3+i)*2)*s
				canvas.draw_circle(p,(2.4 if kind == "hail" else 1.5)*s,Color("#f3fcff"))
				if kind == "snow":
					canvas.draw_line(p-Vector2(3,0)*s,p+Vector2(3,0)*s,Color.WHITE,s,true)
		"sandstorm":
			for i in range(3):
				canvas.draw_line(c+Vector2(-11,-6+i*6)*s,c+Vector2(9,-8+i*6)*s,Color("#e7c48d"),2*s,true)
		"rainbow":
			var colors = [Color("#f6b2b6"),Color("#f4dc92"),Color("#a4d59e"),Color("#a8cdec")]
			for i in range(4): canvas.draw_arc(c+Vector2(0,5)*s,(11-i*2)*s,PI,TAU,16,colors[i],2*s,true)


# ---------------------------------------------------------------- plants

static func draw_plant(game: Control, kind: String, center: Vector2, scale: float, flash: float, alpha: float, plant: Dictionary) -> void:
	var time: float = float(game.get("level_time")) if plant.size() > 0 else float(game.get("ui_time"))
	var state = ""
	match kind:
		"golden_milk":
			if plant.has("ancient_fuse") and float(plant.ancient_fuse) < float(plant.get("ancient_fuse_total", 0.65)) * 0.55:
				state = "pour"
		"samsara_eye":
			if plant.has("ancient_fuse"):
				state = "open"
		"electric_bonk_choy":
			if float(plant.get("ancient_punch_anim", 0.0)) > 0.0 or float(plant.get("ancient_rush", 0.0)) > 0.0:
				state = "punch" if int(plant.get("ancient_punch_side", 1)) > 0 else "punch_back"
	if kind == "samsara_eye" and state == "open":
		var progress = 1.0 - clampf(float(plant.ancient_fuse) / maxf(0.01, float(plant.get("ancient_fuse_total", 1.0))), 0.0, 1.0)
		for i in range(3):
			var r = fmod(progress * 3.0 + i / 3.0, 1.0)
			game.draw_arc(center + Vector2(0, -16) * scale, (14.0 + r * 50.0) * scale, 0.0, TAU, 40, Color(0.74, 0.56, 1.0, (1.0 - r) * 0.7 * alpha), 2.4 * scale, true)
	if kind == "electric_bonk_choy" and plant.size() > 0:
		var charge = int(plant.get("ancient_punches", 0)) % 4
		if charge == 3 or float(plant.get("ancient_rush", 0.0)) > 0.0:
			for i in range(3):
				var a = time * 9.0 + i * TAU / 3.0
				var p = center + (Vector2(0, -20) + Vector2.from_angle(a) * 30.0) * scale
				_bolt(game, p, p + Vector2.from_angle(a + 1.2) * 12.0 * scale, Color(0.6, 0.9, 1.0, 0.8 * alpha), 1.6 * scale, i)
	UnitArt.draw_plant(game, kind, center, scale, flash, alpha, state)
	if plant.is_empty():
		return
	match kind:
		"dandelion":
			for i in range(3):
				var t = fmod(time * 0.35 + i * 0.33 + float(plant.get("anim_phase", 0.0)), 1.0)
				var p = center + (Vector2(-6 + i * 8, -40) + Vector2(sin(time * 2.0 + i) * 10.0 + t * 26.0, -t * 46.0)) * scale
				_seed(game, p, 0.8 * scale, Color(1, 1, 1, (1.0 - t) * 0.85 * alpha), time + i)
		"jasmine_tea":
			for i in range(3):
				var rise = fmod(time * 16.0 + i * 13.0, 38.0)
				var p = center + Vector2(-8 + i * 8 + sin(time * 2.0 + i) * 3.0, -24.0 - rise) * scale
				game.draw_arc(p, 5.0 * scale, PI * 0.2, PI * 1.25, 10, Color(1, 1, 1, (1.0 - rise / 38.0) * 0.55 * alpha), 1.6 * scale, true)
		"electric_bonk_choy":
			var eye_glow = 0.5 + 0.5 * sin(time * 7.0)
			for side in [-1.0, 1.0]:
				game.draw_circle(center + Vector2(side * 6.5 + 1.0, -21.0) * scale, (4.0 + eye_glow * 2.0) * scale, Color(0.5, 0.92, 1.0, 0.25 * alpha))
		"golden_milk":
			if state == "pour":
				for i in range(6):
					var d = fmod(time * 3.0 + i * 0.16, 1.0)
					game.draw_circle(center + Vector2(34 + d * 30.0, 8 + d * d * 30.0) * scale, (3.4 - d * 1.6) * scale, Color(1, 1, 0.97, alpha * (1.0 - d)))


static func _seed(canvas: CanvasItem, p: Vector2, s: float, color: Color, phase: float) -> void:
	canvas.draw_line(p, p + Vector2(0, 7) * s, Color(color.r * 0.7, color.g * 0.6, color.b * 0.4, color.a), 1.2 * s, true)
	canvas.draw_circle(p + Vector2(0, 8) * s, 1.2 * s, Color(0.52, 0.38, 0.2, color.a))
	for k in range(7):
		var a = -PI * 0.5 + (k - 3) * 0.32 + sin(phase * 2.0) * 0.05
		canvas.draw_line(p, p + Vector2.from_angle(a) * 6.0 * s, color, 0.9 * s, true)


static func draw_spore(game: Control, shot: Dictionary) -> void:
	if float(shot.get("spore_delay", 0.0)) > 0.0:
		return
	var p: Vector2 = shot.position
	var s = 1.4 if bool(shot.get("empowered", false)) else 1.0
	var phase = float(shot.get("spore_seed", 0.0)) + game.level_time
	game.draw_circle(p, 13.0 * s, Color(1.0, 1.0, 0.94, 0.12))
	for k in range(13):
		var a = k * TAU / 13.0 + sin(phase * 2.0) * 0.08
		var tip = p + Vector2.from_angle(a) * 10.0 * s
		game.draw_line(p, tip, Color(1, 1, 0.98, 0.9), 1.0 * s, true)
		game.draw_circle(tip, 1.3 * s, Color(1, 1, 1, 0.95))
	game.draw_circle(p, 2.6 * s, Color("#a8794a"))
	if float(shot.get("spore_dive", 0.0)) > 0.0:
		var trail: Vector2 = Vector2(shot.spore_apex)
		game.draw_line(trail.lerp(p, 0.6), p, Color(1, 1, 0.95, 0.35), 3.0 * s, true)
	game.glow_primitives.append({"pos": p, "radius": 6.0 * s, "color": Color(1.0, 0.96, 0.8, 0.22)})


static func draw_sheep(game: Control, center: Vector2, scale: float, alpha: float, plant: Dictionary) -> void:
	var t: float = game.level_time + float(plant.get("anim_phase", 0.0))
	var bob = absf(sin(t * 3.0)) * 2.0
	var c = center + Vector2(0, 8.0 - bob) * scale
	oval(game, center + Vector2(0, 34) * scale, Vector2(24, 4) * scale, Color(0.1, 0.16, 0.12, 0.18 * alpha))
	for leg in [-12.0, -4.0, 6.0, 13.0]:
		game.draw_line(c + Vector2(leg, 12) * scale, c + Vector2(leg, 25) * scale, Color(0.2, 0.18, 0.22, alpha), 3.4 * scale, true)
	for i in range(9):
		var a = i * TAU / 9.0
		oval(game, c + Vector2(cos(a) * 15.0, sin(a) * 9.0) * scale, Vector2(9.0, 8.0) * scale, Color(0.98, 0.97, 0.93, alpha), 1.4 * scale)
	oval(game, c, Vector2(17, 11) * scale, Color(1, 1, 0.97, alpha))
	oval(game, c + Vector2(17, -6) * scale, Vector2(8, 9) * scale, Color(0.27, 0.24, 0.3, alpha), 1.4 * scale)
	oval(game, c + Vector2(12, -10) * scale, Vector2(5, 3) * scale, Color(0.27, 0.24, 0.3, alpha), 0.0, -0.6)
	game.draw_circle(c + Vector2(19, -8) * scale, 1.6 * scale, Color(1, 1, 1, alpha))
	game.draw_circle(c + Vector2(19.5, -8) * scale, 0.8 * scale, Color(0, 0, 0, alpha))
	for i in range(3):
		var rise = fmod(t * 1.2 + i * 0.33, 1.0)
		var star = c + Vector2(-10 + i * 10, -18 - rise * 18.0) * scale
		game.draw_circle(star, 2.0 * scale, Color(0.8, 0.66, 1.0, (1.0 - rise) * alpha))
	var remaining = float(plant.get("ancient_sheep_until", 0.0)) - game.level_time
	if remaining > 0.0:
		game.draw_arc(c + Vector2(0, -26) * scale, 6.0 * scale, -PI * 0.5, -PI * 0.5 + TAU * clampf(remaining / 18.0, 0.0, 1.0), 20, Color(0.8, 0.66, 1.0, 0.9 * alpha), 2.0 * scale, true)


# ---------------------------------------------------------------- zombies

static func _skin(z: Dictionary) -> Color:
	var skin = Color("#9fb592")
	if bool(z.get("hypnotized", false)):
		skin = Color("#d7a9ed")
	if float(z.get("slow_timer", 0.0)) > 0.0:
		skin = skin.lerp(Color("#b1e9ff"), 0.5)
	return skin.lerp(Color.WHITE, clampf(float(z.get("flash", 0.0)) * 3.0, 0.0, 1.0))


static func draw_zombie(game: Control, center: Vector2, z: Dictionary) -> void:
	var kind = String(z.kind)
	var time: float = game.level_time + float(z.get("anim_phase", 0.0))
	var step = sin(time * 5.2) * 4.0
	if float(z.get("special_pause_timer", 0.0)) > 0.0 or float(z.get("frozen_timer", 0.0)) > 0.0:
		step = 0.0
	var weak = float(z.get("ancient_weak_until", 0.0)) > game.level_time
	game._draw_ground_shadow(center, 18.0, 1.0, 46.0)
	match kind:
		"ancient_samurai": _draw_samurai(game, center, z, step, time)
		"ancient_mage": _draw_mage(game, center, z, step, time)
		"ancient_strategist": _draw_strategist(game, center, z, step, time)
	if weak:
		for i in range(3):
			var rise = fmod(time * 0.9 + i * 0.33, 1.0)
			var p = center + Vector2(-12 + i * 12, -70 - rise * 16.0)
			game.draw_arc(p, 4.0, PI * 0.15, PI * 1.2, 10, Color(0.76, 0.66, 0.3, (1.0 - rise) * 0.8), 1.8, true)
		game.draw_arc(center + Vector2(0, -12), 30.0, 0.3, PI - 0.3, 20, Color(0.82, 0.68, 0.28, 0.6), 2.0, true)
	if float(z.get("ancient_command_until", 0.0)) > game.level_time and kind != "ancient_strategist":
		poly(game, [center + Vector2(14, -78), center + Vector2(14, -60), center + Vector2(28, -72)], Color("#d94a3a"), 1.2)
		game.draw_line(center + Vector2(14, -80), center + Vector2(14, -54), Color("#5a3a26"), 1.6, true)


static func _draw_samurai(game: Control, c: Vector2, z: Dictionary, step: float, time: float) -> void:
	var skin = _skin(z)
	var ratio = clampf(float(z.get("shield_health", 0.0)) / maxf(1.0, float(z.get("max_shield_health", 900.0))), 0.0, 1.0)
	var flash = clampf(float(z.get("flash", 0.0)) * 3.0, 0.0, 1.0)
	var lacquer = Color("#9b2a24").lerp(Color.WHITE, flash * 0.6)
	var black = Color("#2a2a30").lerp(Color.WHITE, flash * 0.5)
	var gold = Color("#e5b24c")
	var swing = clampf(float(z.get("ancient_anim", 0.0)) / 0.55, 0.0, 1.0)
	var biting = float(z.get("bite_timer", 0.0)) > 0.0
	Details.zombie_body(game, c, Color("#3b3550"), Color("#2f3a44"), skin, step, step * 0.3, 0.6 if biting else 0.0)
	# Hakama flare.
	poly(game, [c + Vector2(-17, 16), c + Vector2(17, 16), c + Vector2(22 + step * 0.5, 38), c + Vector2(-22 - step * 0.5, 38)], Color("#40394f"), 1.4)
	for x in [-10.0, 0.0, 10.0]:
		game.draw_line(c + Vector2(x, 18), c + Vector2(x * 1.3, 36), Color("#2a2534"), 1.2, true)
	if ratio > 0.0:
		# Dō: lamellar cuirass laced in gold.
		poly(game, [c + Vector2(-17, -10), c + Vector2(17, -10), c + Vector2(19, 16), c + Vector2(-19, 16)], lacquer, 1.8)
		for row in range(4):
			var y = -6.0 + row * 6.0
			game.draw_line(c + Vector2(-17, y), c + Vector2(17, y), black, 1.4, true)
			for k in range(6):
				game.draw_circle(c + Vector2(-14 + k * 5.6, y + 3.0), 0.9, gold)
		if ratio <= 0.5:
			game.draw_polyline(PackedVector2Array([c + Vector2(4, -10), c + Vector2(0, -2), c + Vector2(6, 4), c + Vector2(1, 12)]), Color("#1d1a1d"), 2.0, true)
		# Sode: shoulder plates (the far one falls off when damaged).
		var plates = [-1.0] if ratio <= 0.5 else [-1.0, 1.0]
		for side in plates:
			var s: float = side
			poly(game, [c + Vector2(s * 15, -12), c + Vector2(s * 27, -8), c + Vector2(s * 25, 10), c + Vector2(s * 13, 6)], lacquer.darkened(0.08), 1.6)
			for k in range(3):
				game.draw_line(c + Vector2(s * 14, -6 + k * 5), c + Vector2(s * 26, -3 + k * 5), gold, 1.0, true)
		# Kusazuri skirt plates.
		for k in range(4):
			var x = -16.0 + k * 9.0
			poly(game, [c + Vector2(x, 15), c + Vector2(x + 8, 15), c + Vector2(x + 9, 26), c + Vector2(x - 1, 26)], lacquer.darkened(0.15), 1.2)
	# Head, then kabuto and menpō.
	var head = c + Vector2(0, -28)
	if ratio > 0.0:
		oval(game, head + Vector2(0, -6), Vector2(19, 13), black, 1.8)
		poly(game, [head + Vector2(-22, -2), head + Vector2(-26, 8), head + Vector2(-12, 4)], black, 1.4)
		poly(game, [head + Vector2(22, -2), head + Vector2(26, 8), head + Vector2(12, 4)], black, 1.4)
		game.draw_line(head + Vector2(-18, 0), head + Vector2(18, 0), gold, 2.0, true)
		var horn = 1.0 if ratio > 0.5 else 0.45
		for side in [-1.0, 1.0]:
			var tip = head + Vector2(side * 18.0 * horn, -36.0 * horn)
			poly(game, [head + Vector2(side * 3, -14), tip, head + Vector2(side * 9, -16)], gold, 1.4)
		game.draw_circle(head + Vector2(0, -15), 4.0, Color("#d94a3a"))
		# Menpō covers the lower face; red lacquer with white whiskers.
		poly(game, [head + Vector2(-14, 4), head + Vector2(12, 4), head + Vector2(10, 14), head + Vector2(0, 18), head + Vector2(-12, 14)], lacquer.darkened(0.2), 1.4)
		for k in range(3):
			game.draw_line(head + Vector2(-8 + k * 6, 8), head + Vector2(-9 + k * 6, 14), Color("#f2ead2"), 1.0, true)
	else:
		# Exposed topknot after the armor is shattered.
		oval(game, head + Vector2(2, -17), Vector2(5, 4), Color("#262226"), 1.0)
		game.draw_line(head + Vector2(2, -18), head + Vector2(10, -24), Color("#262226"), 3.0, true)
		game.draw_line(head + Vector2(-14, -8), head + Vector2(14, -8), Color("#f4f0e4"), 3.0, true)
	# Katana: raised over the head during the iaido draw, forward when guarding.
	var hand = c + Vector2(-25, 10)
	var angle = lerpf(-0.35, -2.2, swing) if swing > 0.0 else (-0.35 + sin(time * 2.0) * 0.06)
	var blade_dir = Vector2.from_angle(PI + angle)
	game.draw_line(hand, hand + blade_dir * 10.0, Color("#1f1c22"), 4.5, true)
	game.draw_line(hand + blade_dir * 10.0, hand + blade_dir * 48.0, Color("#d8e1e6"), 3.0, true)
	game.draw_line(hand + blade_dir * 11.0, hand + blade_dir * 46.0, Color("#ffffff", 0.7), 1.0, true)
	game.draw_line(hand + blade_dir * 9.0 + blade_dir.orthogonal() * 4.0, hand + blade_dir * 9.0 - blade_dir.orthogonal() * 4.0, gold, 3.0, true)
	if swing > 0.2:
		game.draw_arc(hand, 46.0, PI + angle - 0.2, PI + angle + 1.4 * swing, 18, Color(1, 1, 1, 0.5 * swing), 4.0, true)


static func _draw_mage(game: Control, c: Vector2, z: Dictionary, step: float, time: float) -> void:
	var skin = _skin(z)
	var flash = clampf(float(z.get("flash", 0.0)) * 3.0, 0.0, 1.0)
	var robe = Color("#4a2f7a").lerp(Color.WHITE, flash * 0.6)
	var trim = Color("#e3c56a")
	var cast = clampf(float(z.get("ancient_cast", 0.0)), 0.0, 1.0)
	var body = c + Vector2(0, -absf(step) * 0.4)
	# Long robe hides the legs; it sways while walking.
	poly(game, [body + Vector2(-15, -12), body + Vector2(15, -12), body + Vector2(22 + step, 40), body + Vector2(-22 + step, 40)], robe, 1.8)
	poly(game, [body + Vector2(-2, -10), body + Vector2(2, -10), body + Vector2(5 + step * 0.5, 40), body + Vector2(-5 + step * 0.5, 40)], robe.lightened(0.12), 0.0)
	game.draw_line(body + Vector2(-22 + step, 39), body + Vector2(22 + step, 39), trim, 2.4, true)
	for k in range(3):
		var star = body + Vector2(-10 + k * 9, 6 + (k % 2) * 14)
		poly(game, [star + Vector2(0, -3), star + Vector2(1, -1), star + Vector2(3, 0), star + Vector2(1, 1), star + Vector2(0, 3), star + Vector2(-1, 1), star + Vector2(-3, 0), star + Vector2(-1, -1)], trim)
	game.draw_arc(body + Vector2(8, 26), 4.0, -1.0, 2.2, 10, trim, 1.4, true)
	# Sleeves and hands.
	for side in [-1.0, 1.0]:
		poly(game, [body + Vector2(side * 12, -10), body + Vector2(side * 24, 2), body + Vector2(side * 22, 12), body + Vector2(side * 12, 6)], robe.darkened(0.1), 1.4)
	Details.zombie_head(game, body + Vector2(0, -28), 15.0, skin)
	# Beard.
	poly(game, [body + Vector2(-9, -17), body + Vector2(7, -17), body + Vector2(3, -2), body + Vector2(-1, 4), body + Vector2(-6, -4)], Color("#d9d6cf"), 1.2)
	# Tall hat with a crescent.
	var hat = body + Vector2(0, -44)
	poly(game, [hat + Vector2(-22, 2), hat + Vector2(22, 2), hat + Vector2(14, -2), hat + Vector2(6, -30), hat + Vector2(-2, -46), hat + Vector2(-6, -30), hat + Vector2(-14, -2)], robe.darkened(0.15), 1.8)
	game.draw_line(hat + Vector2(-14, -3), hat + Vector2(14, -3), trim, 2.6, true)
	game.draw_arc(hat + Vector2(0, -20), 5.0, -2.2, 1.0, 12, trim, 2.0, true)
	# Staff with a crystal orb; it flares while casting.
	var hand = body + Vector2(-26, 8)
	var top = hand + Vector2(-4, -54)
	game.draw_line(hand + Vector2(2, 30), top, Color("#6d4a2c"), 3.4, true)
	game.draw_arc(top + Vector2(0, -2), 8.0, PI * 0.9, PI * 2.1, 14, Color("#6d4a2c"), 2.4, true)
	var glow = 0.5 + 0.5 * sin(time * 5.0)
	game.draw_circle(top + Vector2(0, -6), 6.5 + cast * 4.0, Color(0.74, 0.58, 1.0, 0.95))
	game.draw_circle(top + Vector2(-2, -8), 2.4, Color(1, 1, 1, 0.9))
	if cast > 0.0:
		for i in range(6):
			var a = time * 4.0 + i * TAU / 6.0
			var rune = top + Vector2(0, -6) + Vector2.from_angle(a) * (20.0 + cast * 12.0)
			game.draw_line(rune + Vector2(-3, -3), rune + Vector2(3, 3), Color(0.9, 0.8, 1.0, cast), 1.6, true)
			game.draw_line(rune + Vector2(3, -3), rune + Vector2(-3, 3), Color(0.9, 0.8, 1.0, cast), 1.6, true)
		game.draw_arc(top + Vector2(0, -6), 26.0 + glow * 6.0, 0.0, TAU, 32, Color(0.8, 0.66, 1.0, 0.6 * cast), 2.0, true)


static func _draw_strategist(game: Control, c: Vector2, z: Dictionary, step: float, time: float) -> void:
	var skin = _skin(z)
	var flash = clampf(float(z.get("flash", 0.0)) * 3.0, 0.0, 1.0)
	var robe = Color("#e9eef2").lerp(Color.WHITE, flash * 0.5)
	var blue = Color("#4f6f95")
	var wave = clampf(float(z.get("ancient_anim", 0.0)), 0.0, 1.2)
	var body = c + Vector2(0, -absf(step) * 0.3)
	# Crane cloak (鹤氅) with dark hems.
	poly(game, [body + Vector2(-16, -12), body + Vector2(16, -12), body + Vector2(24 + step * 0.6, 40), body + Vector2(-24 + step * 0.6, 40)], robe, 1.8)
	game.draw_line(body + Vector2(-24 + step * 0.6, 38), body + Vector2(24 + step * 0.6, 38), blue, 4.0, true)
	poly(game, [body + Vector2(-4, -12), body + Vector2(4, -12), body + Vector2(2, 38), body + Vector2(-2, 38)], blue.lightened(0.2), 0.0)
	game.draw_line(body + Vector2(-16, 10), body + Vector2(16, 10), blue, 3.0, true)
	game.draw_rect(Rect2(body + Vector2(8, 12), Vector2(5, 14)), Color("#d8c48c"), true)
	for side in [-1.0, 1.0]:
		poly(game, [body + Vector2(side * 13, -10), body + Vector2(side * 27, 4), body + Vector2(side * 24, 14), body + Vector2(side * 12, 6)], robe.darkened(0.05), 1.4)
		game.draw_line(body + Vector2(side * 27, 4), body + Vector2(side * 24, 14), blue, 2.4, true)
	Details.zombie_head(game, body + Vector2(0, -28), 15.0, skin)
	# Long goatee and a 纶巾 cap with trailing ribbons.
	game.draw_polyline(PackedVector2Array([body + Vector2(-3, -15), body + Vector2(-5, -4), body + Vector2(-2, 4)]), Color("#2a2a2a"), 2.0, true)
	var cap = body + Vector2(0, -44)
	poly(game, [cap + Vector2(-15, 4), cap + Vector2(13, 4), cap + Vector2(11, -10), cap + Vector2(0, -16), cap + Vector2(-13, -10)], Color("#2e3a46"), 1.6)
	game.draw_line(cap + Vector2(-12, -1), cap + Vector2(12, -1), Color("#6f8aa8"), 2.0, true)
	for k in range(2):
		var ribbon = PackedVector2Array()
		for i in range(6):
			ribbon.append(cap + Vector2(12 + i * 3.4, 2 + i * 2.6 + sin(time * 3.0 + i + k) * 2.2 + k * 4))
		game.draw_polyline(ribbon, Color("#2e3a46"), 2.2, true)
	# Feather fan (羽扇): sweeps while changing the weather.
	var hand = body + Vector2(-26, 6)
	var swing = sin(time * 2.0) * 0.12 + (sin(wave * 9.0) * 0.6 if wave > 0.0 else 0.0)
	var dir = Vector2.from_angle(-PI * 0.62 + swing)
	game.draw_line(hand, hand + dir * 12.0, Color("#6d4a2c"), 3.0, true)
	var root = hand + dir * 12.0
	var feathers: Array = [root]
	for i in range(9):
		var a = -PI * 0.62 + swing + (i - 4) * 0.13
		feathers.append(root + Vector2.from_angle(a) * (26.0 + (4 - absi(i - 4)) * 1.6))
	poly(game, feathers, Color("#fbfaf4"), 1.4)
	for i in range(1, 9, 2):
		game.draw_line(root, feathers[i], Color("#c9c3b4"), 1.0, true)
	game.draw_circle(root, 3.0, Color("#d6402d"))
	if wave > 0.0:
		for i in range(4):
			var curve = PackedVector2Array()
			for k in range(6):
				curve.append(root + dir * (30.0 + k * 9.0) + dir.orthogonal() * sin(time * 8.0 + k + i) * (4.0 + i * 3.0))
			game.draw_polyline(curve, Color(0.82, 0.96, 0.9, 0.7 * minf(1.0, wave)), 1.6, true)


# ---------------------------------------------------------------- effects

static func _bolt(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float, seed: int) -> void:
	var points = PackedVector2Array([a])
	var normal = (b - a).normalized().orthogonal()
	for k in range(1, 6):
		var t = k / 6.0
		points.append(a.lerp(b, t) + normal * sin(seed * 12.9 + k * 7.3 + Time.get_ticks_msec() * 0.03) * a.distance_to(b) * 0.09)
	points.append(b)
	canvas.draw_polyline(points, Color(color, color.a * 0.35), width * 3.2, true)
	canvas.draw_polyline(points, color, width, true)
	canvas.draw_polyline(points, Color(1, 1, 1, color.a), maxf(0.8, width * 0.4), true)


static func draw_effect(game: Control, effect: Dictionary) -> bool:
	var shape = String(effect.get("shape", ""))
	if not shape.begins_with("ancient_"):
		return false
	var ratio = clampf(float(effect.time) / maxf(0.01, float(effect.duration)), 0.0, 1.0)
	var progress = 1.0 - ratio
	var c: Vector2 = effect.position
	var radius = float(effect.radius)
	match shape:
		"ancient_hail_hit":
			for k in range(7):
				var dir = Vector2.from_angle(k*TAU/7+0.4)
				var p = c+dir*radius*progress
				poly(game,[p+Vector2(0,-4),p+Vector2(4,0),p+Vector2(0,4),p+Vector2(-4,0)],Color(0.85,0.96,1,ratio))
			game.draw_arc(c,radius*progress,0,TAU,24,Color(0.7,0.9,1,ratio*0.6),1.5,true)
		"ancient_milk_wave":
			draw_wave(game, effect)
		"ancient_hex":
			draw_hex(game, effect)
		"ancient_strike":
			draw_strike_cue(game, effect)
		"ancient_spore_burst":
			for k in range(10):
				var dir = Vector2.from_angle(k * TAU / 10.0 + 0.3)
				var p = c + dir * radius * (0.3 + progress * 0.8)
				_seed(game, p, 0.9, Color(1, 1, 1, ratio), k)
			game.draw_arc(c, radius * progress, 0.0, TAU, 32, Color(1.0, 0.98, 0.86, ratio * 0.7), 2.0, true)
			game.glow_primitives.append({"pos": c, "radius": radius * 0.5 * ratio, "color": Color(1.0, 0.96, 0.8, 0.25 * ratio)})
		"ancient_dandelion_gust":
			for k in range(18):
				var a = k * TAU / 18.0 + progress * 2.0
				var p = c + Vector2.from_angle(a) * radius * progress
				_seed(game, p, 1.1, Color(1, 1, 1, ratio), k)
		"ancient_tea_pour":
			var origin = c + Vector2(18, -26)
			var cells: Array = effect.get("cells", [])
			var far: Vector2 = origin + Vector2(game.CELL_SIZE.x * 2.0, 20.0)
			if not cells.is_empty():
				far = game._cell_center(int(effect.row), mini(game.COLS - 1, int(effect.col) + 2)) + Vector2(0, 10)
			var stream = PackedVector2Array()
			for k in range(16):
				var t = k / 15.0
				stream.append(origin.lerp(far, t) + Vector2(0, -sin(t * PI) * 46.0))
			game.draw_polyline(stream, Color(0.86, 0.66, 0.26, 0.55 * ratio), 9.0 * ratio + 2.0, true)
			game.draw_polyline(stream, Color(1.0, 0.88, 0.56, 0.8 * ratio), 3.0, true)
			for cell in cells:
				var p: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, 18)
				game.draw_arc(p, 10.0 + progress * 30.0, 0.0, TAU, 24, Color(0.94, 0.8, 0.42, 0.6 * ratio), 2.0, true)
				for k in range(4):
					var drop = p + Vector2.from_angle(-PI * 0.5 + (k - 1.5) * 0.6) * progress * 26.0
					game.draw_circle(drop, 2.4 * ratio + 0.6, Color(0.96, 0.8, 0.4, ratio))
		"ancient_tea_bloom":
			for cell in effect.get("cells", []):
				var p: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, 12)
				for k in range(5):
					var petal = p + Vector2.from_angle(k * TAU / 5.0 + progress * 2.0) * (6.0 + progress * 16.0)
					oval(game, petal, Vector2(5, 3), Color(1, 1, 0.96, ratio), 0.0, k * TAU / 5.0)
				game.draw_circle(p, 3.0, Color(1.0, 0.84, 0.4, ratio))
		"ancient_samsara":
			var burst = bool(effect.get("burst", false))
			for k in range(4):
				var r = radius * fmod(progress + k * 0.25, 1.0)
				game.draw_arc(c, r, 0.0, TAU, 48, Color(0.72, 0.52, 1.0, ratio * (1.0 - r / radius) * 0.9), 3.0, true)
			if burst:
				for k in range(12):
					var dir = Vector2.from_angle(k * TAU / 12.0)
					game.draw_line(c + dir * radius * progress * 0.3, c + dir * radius * progress, Color(0.88, 0.8, 1.0, ratio * 0.7), 2.0, true)
			game.glow_primitives.append({"pos": c, "radius": radius * 0.35 * ratio, "color": Color(0.7, 0.5, 1.0, 0.3 * ratio)})
		"ancient_revive":
			var fused = bool(effect.get("fused", false))
			var tint = Color(1.0, 0.86, 0.5) if fused else Color(0.78, 0.66, 1.0)
			for k in range(8):
				var rise = fmod(progress + k * 0.125, 1.0)
				var p = c + Vector2(sin(k * 2.4) * 22.0, 30.0 - rise * 80.0)
				game.draw_circle(p, 3.0 * (1.0 - rise) + 1.0, Color(tint, ratio))
			game.draw_arc(c + Vector2(0, 30), radius * (0.4 + progress * 0.6), 0.0, TAU, 32, Color(tint, ratio * 0.8), 2.4, true)
			game.draw_rect(Rect2(c + Vector2(-radius * 0.4, -60), Vector2(radius * 0.8, 90)), Color(tint, ratio * 0.12), true)
		"ancient_punch":
			var side = float(effect.get("side", 1))
			for k in range(6):
				var dir = Vector2.from_angle(k * TAU / 6.0 + 0.2)
				game.draw_line(c + dir * radius * 0.3, c + dir * radius * (0.6 + progress * 0.5), Color(1.0, 0.96, 0.7, ratio), 2.6, true)
			poly(game, [c + Vector2(-side * 10, -8), c + Vector2(side * 6, -10), c + Vector2(side * 12, 0), c + Vector2(side * 6, 10), c + Vector2(-side * 10, 8)], Color(0.6, 0.92, 1.0, 0.5 * ratio))
		"ancient_chain":
			var points: PackedVector2Array = effect.get("points", PackedVector2Array())
			for k in range(points.size() - 1):
				_bolt(game, points[k], points[k + 1], Color(0.62, 0.9, 1.0, ratio), 2.4, k + int(effect.time * 30.0))
				game.draw_circle(points[k + 1], 10.0 * ratio, Color(0.8, 0.96, 1.0, 0.4 * ratio))
				game.glow_primitives.append({"pos": points[k + 1], "radius": 9.0 * ratio, "color": Color(0.5, 0.86, 1.0, 0.35 * ratio)})
		"ancient_thunder_fists":
			for k in range(8):
				var a = k * TAU / 8.0 + progress * 6.0
				_bolt(game, c, c + Vector2.from_angle(a) * radius * (0.4 + 0.3 * sin(progress * 20.0 + k)), Color(0.6, 0.9, 1.0, ratio * 0.8), 2.0, k)
		"ancient_strike_warning":
			game.draw_arc(c, radius * (0.6 + 0.4 * ratio), 0.0, TAU, 24, Color(1.0, 0.94, 0.5, 0.75 * (1.0 - ratio) + 0.2), 2.4, true)
		"ancient_lightning":
			var natural = bool(effect.get("natural", false))
			var top = c + Vector2(sin(c.x) * 30.0, -c.y - 20.0)
			_bolt(game, top, c, Color(0.86, 0.9, 1.0, ratio), 4.5 if natural else 3.0, int(c.x))
			_bolt(game, top.lerp(c, 0.4), c + Vector2(34, -40), Color(0.7, 0.8, 1.0, ratio * 0.7), 2.0, int(c.y))
			game.draw_arc(c, radius * (0.4 + progress * 0.8), 0.0, TAU, 32, Color(0.9, 0.94, 1.0, 0.7 * ratio), 3.0, true)
			game.draw_circle(c, radius * 0.25 * ratio, Color(1.0, 1.0, 1.0, 0.45 * ratio))
			game.glow_primitives.append({"pos": c, "radius": radius * 0.4 * ratio, "color": Color(0.7, 0.8, 1.0, 0.28 * ratio)})
		"ancient_iaido":
			for k in range(2):
				var a = -0.9 + k * 0.5
				game.draw_arc(c, radius - k * 8.0, a, a + PI * 0.9 * (0.3 + progress), 20, Color(1, 1, 1, ratio * (0.9 - k * 0.3)), 4.0 - k, true)
			game.draw_line(c + Vector2(-radius, radius * 0.4), c + Vector2(radius, -radius * 0.5), Color(1.0, 0.36, 0.3, ratio * 0.7), 2.0, true)
		"ancient_poof":
			var tint: Color = effect.get("color", Color.WHITE)
			for k in range(9):
				var dir = Vector2.from_angle(k * TAU / 9.0)
				oval(game, c + dir * radius * (0.2 + progress * 0.6), Vector2(10, 9) * (1.0 - progress * 0.5), Color(tint, ratio * 0.8))
		"ancient_hex_fizzle":
			game.draw_arc(c, radius * progress, 0.0, TAU, 24, Color(1.0, 0.94, 0.7, ratio), 2.0, true)
		"ancient_fan_gust":
			for k in range(5):
				var curve = PackedVector2Array()
				for i in range(10):
					curve.append(c + Vector2(-i * radius / 10.0 * (0.4 + progress), sin(i * 0.8 + k + progress * 10.0) * 10.0 + (k - 2) * 12.0))
				game.draw_polyline(curve, Color(0.86, 0.98, 0.92, ratio * 0.8), 2.0, true)
		"ancient_command":
			var target: Vector2 = effect.get("target", c)
			var p = c.lerp(target, minf(1.0, progress * 1.6))
			poly(game, [p + Vector2(-6, -3), p + Vector2(6, 0), p + Vector2(-6, 3)], Color(0.98, 0.98, 0.94, ratio))
			game.draw_line(c, p, Color(0.86, 0.3, 0.24, 0.35 * ratio), 1.4, true)
		_:
			return false
	return true
