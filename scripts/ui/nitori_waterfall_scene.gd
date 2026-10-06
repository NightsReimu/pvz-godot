extends RefCounted

const SpriteDefs = preload("res://scripts/data/touhou_sprite_defs.gd")
const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const BACKGROUND := "res://art/backgrounds/nitori_waterfall_4_21.png"
const WATER := Color("6fd3f2")
const LANTERN := Color("ffd98a")
const TILE_A := Color("76858a")
const TILE_B := Color("6b7a80")

static func draw_preview(game: Control, rect: Rect2, alpha: float, show_label: bool) -> void:
	var texture: Texture2D = game._load_polished_texture(BACKGROUND)
	if texture != null: game.draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))
	else: game.draw_rect(rect, Color(0.30, 0.40, 0.44, alpha))
	var board := Rect2(rect.position + rect.size * Vector2(0.12, 0.36), rect.size * Vector2(0.70, 0.53))
	var size := board.size / Vector2(9, 6)
	for row in range(6):
		for col in range(9):
			var cell := Rect2(board.position + Vector2(col, row) * size, size)
			game.draw_rect(cell, Color(TILE_A if (row + col) % 2 == 0 else TILE_B, alpha * 0.94))
			game.draw_rect(cell.grow(-0.5), Color(0.78, 0.88, 0.90, alpha * 0.45), false, 0.8)
	for i in range(14):
		var x := rect.position.x + fposmod(i * 37.0 + game.ui_time * 30.0, rect.size.x)
		var y := rect.position.y + fposmod(i * 53.0 + game.ui_time * 90.0, rect.size.y)
		game.draw_line(Vector2(x, y), Vector2(x - 2.5, y + 9), Color(0.86, 0.94, 1.0, alpha * 0.5), 1.0, true)
	if show_label:
		ThemeLib.draw_label(game, game.ui_font, Rect2(rect.position + Vector2(8, 4), Vector2(rect.size.x - 16, 24)), "六行玄武岸台 · 雨中瀑布", 15, Color(0.92, 0.97, 1.0, alpha))

static func draw_background(game: Control) -> void:
	var texture: Texture2D = game._load_polished_texture(BACKGROUND)
	if texture != null:
		game.draw_texture_rect(texture, Rect2(Vector2.ZERO, game.size), false)
	else:
		game.draw_rect(Rect2(Vector2.ZERO, game.size), Color("4f6266"))
	# The fall's sheet keeps moving behind the boss lane.
	var fall_x: float = game.size.x * 0.852
	var fall_w: float = game.size.x * 0.096
	for i in range(9):
		var x: float = fall_x + fall_w * fposmod(i * 0.37, 1.0)
		var y: float = fposmod(game.ui_time * (220.0 + i * 13.0) + i * 97.0, game.size.y * 0.84)
		game.draw_line(Vector2(x, y), Vector2(x, y + game.size.y * 0.06), Color(1, 1, 1, 0.22), 2.0, true)
	var perimeter: Rect2 = Rect2(game.BOARD_ORIGIN, game.board_size).grow(9)
	game._draw_panel_shell(perimeter, Color("4d5a5e"), Color("9fc4cc"), 0.10, 0.04)
	game._draw_panel_shell(game.COIN_METER_RECT, Color("d4e6ea"), Color("2f4c56"), 0.12, 0.06)
	game._draw_coin_icon(game.COIN_METER_RECT.position + Vector2(22, 20), 1.0)
	ThemeLib.draw_label(game, game.ui_font, Rect2(game.COIN_METER_RECT.position + Vector2(44, 4), Vector2(game.COIN_METER_RECT.size.x - 52, game.COIN_METER_RECT.size.y - 8)), str(game.coins_total), 22, Color("2f4048"))
	game._draw_fancy_button(game.BACK_BUTTON_RECT, "返回地图", Color("dceaee"), Color("2f4c56"), 18)

static func draw_board(game: Control) -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	for row in range(game.board_rows):
		for col in range(game.COLS):
			var rect: Rect2 = game._cell_rect(row, col)
			var base := TILE_A if (row + col) % 2 == 0 else TILE_B
			game.draw_rect(rect, base)
			# A flattened basalt hexagon on every slab: the 玄武 terrace motif.
			var center := rect.get_center() + Vector2(0, unit * 0.04)
			var hex := PackedVector2Array()
			for i in range(7):
				var a := PI / 6 + TAU * i / 6.0
				hex.append(center + Vector2(cos(a) * rect.size.x * 0.40, sin(a) * rect.size.y * 0.36))
			game.draw_polyline(hex, Color(0.35, 0.42, 0.45, 0.55), maxf(1.0, unit * 0.014), true)
			game.draw_rect(rect.grow(-2), Color(0.80, 0.90, 0.93, 0.40), false, 1.0)
			# Rain sheen: a soft wet highlight along each slab's upper edge.
			game.draw_line(rect.position + Vector2(3, 3), Vector2(rect.end.x - 3, rect.position.y + 3), Color(0.86, 0.95, 1.0, 0.30), maxf(1.0, unit * 0.025), true)
			if posmod(row * 5 + col * 3, 7) == 0:
				var puddle := Rect2(rect.position + rect.size * Vector2(0.18, 0.62), rect.size * Vector2(0.38, 0.18))
				game.draw_rect(puddle, Color(0.62, 0.80, 0.88, 0.30))
			var edge: float = rect.end.y - unit * 0.06
			game.draw_line(Vector2(rect.position.x + 3, edge), Vector2(rect.end.x - 3, edge), Color("4d5b60"), unit * 0.06, true)

static func draw_ambient(game: Control) -> void:
	# Light rain: thin streaks and puddle rings, never a visibility veil.
	var count := 46 if game.size.x > 1000 else 28
	for i in range(count):
		var speed: float = 520.0 + float(i % 5) * 60.0
		var y: float = fposmod(game.ui_time * speed + i * 151.0, game.size.y + 60.0) - 30.0
		var x: float = fposmod(i * 97.3 - game.ui_time * speed * 0.22, game.size.x + 40.0) - 20.0
		var length: float = 14.0 + float(i % 4) * 4.0
		game.draw_line(Vector2(x, y), Vector2(x - length * 0.22, y + length), Color(0.86, 0.94, 1.0, 0.26), 1.2, true)
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	for i in range(10):
		var cycle: float = fposmod(game.ui_time * 0.9 + i * 0.37, 1.0)
		var row := posmod(i * 7 + int(floor(game.ui_time * 0.9 + i * 0.37)) * 3, maxi(1, game.board_rows))
		var col := posmod(i * 4 + int(floor(game.ui_time * 0.9 + i * 0.37)) * 5, game.COLS)
		var rect: Rect2 = game._cell_rect(row, col)
		var point := rect.position + rect.size * Vector2(0.25 + fposmod(i * 0.31, 0.5), 0.70)
		game.draw_arc(point, unit * (0.03 + cycle * 0.12), 0, TAU, 16, Color(0.88, 0.96, 1.0, 0.45 * (1.0 - cycle)), 1.0, true)

static func draw_boss(game: Control, center: Vector2, boss: Dictionary) -> void:
	var rt: RefCounted = game._ensure_nitori_runtime()
	var texture: Texture2D = game._try_get_boss_frame_texture("nitori_boss", rt.frame_index(boss))
	var scale: float = game._touhou_boss_draw_scale("nitori_boss")
	var t: float = float(boss.get("animation_time", game.level_time))
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var camouflaged: bool = rt.boss_camouflaged(boss) and not bool(boss.get("portrait", false))
	var revealed: bool = camouflaged and rt.boss_revealed(boss)
	var alpha := 1.0
	if camouflaged:
		# Optical camouflage: a faint bent-light silhouette until a lantern finds her.
		alpha = 0.78 if revealed else 0.20 + 0.08 * sin(t * 5.0)
	var anchor := center + Vector2(0, -unit * 0.34)
	if float(boss.get("touhou_cast_remaining", 0)) > 0 and not camouflaged:
		for i in range(2):
			var r := unit * (0.42 + i * 0.12) + sin(t * 4.0 + i) * unit * 0.03
			game.draw_arc(anchor, r, t * (1.6 if i == 0 else -1.2), t * (1.6 if i == 0 else -1.2) + PI * 1.4, 28, Color(WATER, 0.45 - i * 0.15), maxf(1.0, unit * 0.022), true)
	if texture != null:
		var size: Vector2 = texture.get_size() * scale
		var rect := Rect2(center + Vector2(-size.x * 0.5, SpriteDefs.top_offset("nitori_boss") + sin(t * 2.6) * 2.0), size)
		if camouflaged and not revealed:
			for offset in [-1, 1]:
				var shift := Vector2(offset * unit * 0.035 * (1.0 + sin(t * 7.0 + offset)), 0)
				game.draw_texture_rect(texture, Rect2(rect.position + shift, rect.size), false, Color(0.55, 0.95, 1.0, 0.10))
		game.draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha * (1 - float(boss.get("flash", 0)) * 0.25)))
	if camouflaged:
		var tint := LANTERN if revealed else WATER
		for i in range(3):
			var r := unit * (0.36 + i * 0.07)
			var wobble := sin(t * 6.0 + i * 1.7) * unit * 0.03
			game.draw_arc(anchor + Vector2(wobble, 0), r, -PI * 0.9 + i, PI * 0.2 + i, 18, Color(tint, 0.42 - i * 0.10), maxf(1.0, unit * 0.016), true)
