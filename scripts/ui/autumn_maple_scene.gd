extends RefCounted

const SpriteDefs = preload("res://scripts/data/touhou_sprite_defs.gd")
const Leaves = preload("res://scripts/runtime/aki_danmaku.gd")
const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const BACKGROUND := "res://art/backgrounds/autumn_maple_4_19.png"
const LEAF_COLORS := [Color("d55232"), Color("bb382d"), Color("e9a84b")]

static func draw_background(game: Control) -> void:
	var texture: Texture2D = game._load_polished_texture(BACKGROUND)
	if texture != null:
		game.draw_texture_rect(texture, Rect2(Vector2.ZERO, game.size), false)
	else:
		game.draw_rect(Rect2(Vector2.ZERO, game.size), Color("b99b63"))
	var perimeter: Rect2 = Rect2(game.BOARD_ORIGIN, game.board_size).grow(9.0)
	game._draw_panel_shell(perimeter, Color("735744"), Color("debb83"), 0.10, 0.04)
	game._draw_panel_shell(game.COIN_METER_RECT, Color("f4d685"), Color("684025"), 0.12, 0.06)
	game._draw_coin_icon(game.COIN_METER_RECT.position + Vector2(22, 20), 1.0)
	ThemeLib.draw_label(game, game.ui_font, Rect2(game.COIN_METER_RECT.position + Vector2(44, 4), Vector2(game.COIN_METER_RECT.size.x - 52, game.COIN_METER_RECT.size.y - 8)), str(game.coins_total), 22, Color("51351d"))
	game._draw_fancy_button(game.BACK_BUTTON_RECT, "返回地图", Color("f0dfba"), Color("684025"), 18)

static func draw_board(game: Control) -> void:
	for row in range(game.board_rows):
		for col in range(game.COLS):
			var rect: Rect2 = game._cell_rect(row, col)
			var base := Color("bca270") if (row + col) % 2 == 0 else Color("af9365")
			game.draw_rect(rect, base)
			game.draw_rect(rect.grow(-2), Color("edd5a3"), false, 1.0)
			game.draw_line(rect.position + Vector2(4, rect.size.y - 3), rect.end - Vector2(4, 3), Color(0.38, 0.23, 0.13, 0.30), 2, true)
			for i in range(2):
				var point: Vector2 = rect.position + Vector2(rect.size.x * (0.18 + i * 0.63), rect.size.y * (0.78 - i * 0.56))
				Leaves.draw_leaf(game, point, maxf(2, game.CELL_SIZE.y * 0.045), float(row + col + i), Color(LEAF_COLORS[posmod(row + col + i, 3)], 0.32))

static func draw_ambient(game: Control) -> void:
	# Cosmetic movement uses the UI clock; no collision, terrain or visibility state.
	var extent: Vector2 = game.size
	var small_scale: float = minf(1, game.CELL_SIZE.y / 110.0)
	for i in range(18):
		var phase := float(i) * 2.39996
		var fall: float = fposmod(game.ui_time * (19.0 + i % 5 * 3.0) + i * 61.0, extent.y + 70.0) - 35.0
		var x: float = fposmod(i * 137.0 + sin(game.ui_time * 0.65 + phase) * 36.0 + game.ui_time * 10.0, extent.x)
		Leaves.draw_leaf(game, Vector2(x, fall), (5.0 + i % 3 * 2.0) * small_scale, phase + game.ui_time * 0.65, Color(LEAF_COLORS[i % 3], 0.35))

static func draw_boss(game: Control, center: Vector2, boss: Dictionary) -> void:
	var kind := String(boss.kind)
	var rt: RefCounted = game._ensure_aki_runtime()
	var texture: Texture2D = game._try_get_boss_frame_texture(kind, rt.frame_index(boss))
	var scale: float = game._touhou_boss_draw_scale(kind)
	var animation: float = game.level_time * 2.5 + float(boss.get("anim_phase", 0))
	var bob := sin(animation) * 3.0
	var tint := Color("ee6642") if kind == "shizuha_boss" else Color("f1c36b")
	game.draw_circle(center + Vector2(0, -24), 48.0, Color(tint, 0.10))
	if texture != null:
		var frame_size: Vector2 = texture.get_size() * scale
		game.draw_texture_rect(texture, Rect2(center + Vector2(-frame_size.x * 0.5, SpriteDefs.top_offset(kind) + 10.0 + bob), frame_size), false, Color(1, 1, 1, 1.0 - float(boss.get("flash", 0)) * 0.25))
	for i in range(5):
		var angle := animation * 0.65 + TAU * i / 5.0
		var point: Vector2 = center + Vector2(cos(angle) * 40.0, -22 + sin(angle) * 22.0)
		Leaves.draw_leaf(game, point, 5.0, angle, Color(tint, 0.55))
