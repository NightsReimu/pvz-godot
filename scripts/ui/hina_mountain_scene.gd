extends RefCounted
const WindGodFX = preload("res://scripts/runtime/wind_god_fx.gd")

const SpriteDefs = preload("res://scripts/data/touhou_sprite_defs.gd")
const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const BACKGROUND := "res://art/backgrounds/hina_mountain_4_20.png"
const JADE := Color("50dcc2")

static func draw_preview(game: Control, rect: Rect2, alpha: float, show_label: bool) -> void:
	var texture: Texture2D = game._load_polished_texture(BACKGROUND)
	if texture != null: game.draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))
	else: game.draw_rect(rect, Color(0.25, 0.40, 0.31, alpha))
	var board := Rect2(rect.position + rect.size * Vector2(0.10, 0.36), rect.size * Vector2(0.80, 0.53))
	for row in range(6):
		for col in range(9):
			var size := board.size / Vector2(9, 6)
			var cell := Rect2(board.position + Vector2(col, row) * size, size)
			var tint := Color("969469") if (row + col) % 2 == 0 else Color("89865e")
			game.draw_rect(cell, Color(tint, alpha * 0.94))
			game.draw_rect(cell.grow(-0.5), Color(0.80, 0.88, 0.69, alpha * 0.50), false, 0.8)
			game.draw_line(cell.position + Vector2(1, size.y - 2), cell.end - Vector2(1, 2), Color(0.37, 0.43, 0.31, alpha), 1.4, true)
	if show_label:
		ThemeLib.draw_label(game, game.ui_font, Rect2(rect.position + Vector2(8, 4), Vector2(rect.size.x - 16, 24)), "六行山麓梯田 · 旱地", 15, Color(0.92, 0.97, 0.84, alpha))

static func draw_background(game: Control) -> void:
	var texture: Texture2D = game._load_polished_texture(BACKGROUND)
	if texture != null:
		game.draw_texture_rect(texture, Rect2(Vector2.ZERO, game.size), false)
	else:
		game.draw_rect(Rect2(Vector2.ZERO, game.size), Color("496b54"))
	var perimeter: Rect2 = Rect2(game.BOARD_ORIGIN, game.board_size).grow(9)
	game._draw_panel_shell(perimeter, Color("555e47"), Color("a6b79b"), 0.10, 0.04)
	game._draw_panel_shell(game.COIN_METER_RECT, Color("d9e2ab"), Color("354e42"), 0.12, 0.06)
	game._draw_coin_icon(game.COIN_METER_RECT.position + Vector2(22, 20), 1.0)
	ThemeLib.draw_label(game, game.ui_font, Rect2(game.COIN_METER_RECT.position + Vector2(44, 4), Vector2(game.COIN_METER_RECT.size.x - 52, game.COIN_METER_RECT.size.y - 8)), str(game.coins_total), 22, Color("344435"))
	game._draw_fancy_button(game.BACK_BUTTON_RECT, "返回地图", Color("e0e7c9"), Color("354e42"), 18)

static func draw_board(game: Control) -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	for row in range(game.board_rows):
		for col in range(game.COLS):
			var rect: Rect2 = game._cell_rect(row, col)
			var base := Color("969469") if (row + col) % 2 == 0 else Color("89865e")
			game.draw_rect(rect, base)
			game.draw_rect(rect.grow(-2), Color(0.82, 0.87, 0.65, 0.48), false, 1.0)
			# Quiet earth texture; all marks stay within the cell's usable area.
			for i in range(3):
				var seed := float(row * 47 + col * 31 + i * 19)
				var point: Vector2 = rect.position + Vector2(rect.size.x * (0.15 + fposmod(seed * 0.213, 0.70)), rect.size.y * (0.20 + fposmod(seed * 0.151, 0.57)))
				game.draw_line(point, point + Vector2(unit * 0.05, unit * 0.014), Color(0.29, 0.35, 0.23, 0.25), maxf(1, unit * 0.012), true)
			var edge: float = rect.end.y - unit * 0.065
			game.draw_line(Vector2(rect.position.x + 3, edge), Vector2(rect.end.x - 3, edge), Color("656e51"), unit * 0.07, true)
			for i in range(3):
				var stone := Rect2(rect.position.x + rect.size.x * i / 3.0 + 3, edge - unit * 0.017, rect.size.x / 3.0 - 6, unit * 0.04)
				game.draw_rect(stone, Color("a2a48c") if i % 2 else Color("929b81"))
			game.draw_line(rect.position + Vector2(2, 2), rect.position + Vector2(unit * 0.14, 2), Color(0.37, 0.50, 0.27, 0.55), unit * 0.035, true)

static func draw_ambient(game: Control) -> void:
	# Sparse drifting foliage, never a screen-filling visibility veil.
	for i in range(10):
		var y: float = fposmod(game.ui_time * (9 + i % 3 * 2) + i * 79, game.size.y + 30) - 15
		var x: float = fposmod(i * 193 + game.ui_time * 5 + sin(game.ui_time * 0.8 + i) * 16, game.size.x)
		var stem := Vector2(3, 0).rotated(game.ui_time * 0.4 + i)
		game.draw_line(Vector2(x, y) - stem, Vector2(x, y) + stem, Color(0.78, 0.83, 0.52, 0.28), 2, true)

static func draw_boss(game: Control, center: Vector2, boss: Dictionary) -> void:
	var rt: RefCounted = game._ensure_hina_runtime()
	var texture: Texture2D = game._try_get_boss_frame_texture("hina_boss", rt.frame_index(boss))
	var scale: float = game._touhou_boss_draw_scale("hina_boss")
	var t: float = float(boss.get("animation_time", game.level_time))
	var age := float(boss.get("hina_arrival_age", 4.0))
	var road := bool(boss.get("touhou_road_spell", false)) and not bool(boss.get("portrait", false))
	var prelude := road and age < 3.2
	var alpha := 1.0
	if prelude:
		alpha = 0.25 + 0.75 * absf(cos(age * PI / 1.6))
	var anchor := center + Vector2(0, -36)
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var radius := unit * 0.44
	game.draw_circle(anchor, radius, Color(JADE, 0.075))
	if not prelude: WindGodFX.draw_boss_aura(game, center, boss, true)
	for arm in range(3):
		var trail := PackedVector2Array()
		for i in range(18):
			var fraction := float(i) / 17
			var angle := t * 2.8 + arm * TAU / 3 + fraction * TAU * 0.65
			trail.append(anchor + Vector2(cos(angle) * radius * fraction, sin(angle) * radius * fraction * 0.43))
		game.draw_polyline(trail, Color(JADE, 0.50 if prelude else 0.28), maxf(1.0, unit * 0.018), true)
	if texture != null:
		var size: Vector2 = texture.get_size() * scale
		var width: float = 0.90 + absf(cos(t * 3.1)) * 0.10
		var rect := Rect2(center + Vector2(-size.x * width * 0.5, SpriteDefs.top_offset("hina_boss") + sin(t * 3) * 2), Vector2(size.x * width, size.y))
		if float(boss.get("touhou_cast_remaining", 0)) > 0:
			game.draw_texture_rect(texture, Rect2(rect.position + Vector2(-unit * 0.05, 0), rect.size), false, Color(0.3, 1.0, 0.86, 0.10))
			if not prelude: WindGodFX.draw_sprite_glow(game, texture, rect, JADE, 1.0)
		game.draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha * (1 - float(boss.get("flash", 0)) * 0.25)))
	# The spiral position marker remains readable during both cosmetic fades.
	for i in range(4):
		var angle := -t * 2.2 + i * TAU / 4
		var point := anchor + Vector2(cos(angle) * radius * 1.05, sin(angle) * radius * 0.46)
		game.draw_circle(point, maxf(1.6, unit * 0.026), Color(JADE, 0.7))
	if not prelude: WindGodFX.draw_boss_aura(game, center, boss, false)
