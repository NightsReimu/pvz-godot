extends RefCounted

const RED := Color("fa668d")
const MOON := Color("c5dcf2")
const GREEN := Color("99e2c3")
const MAX_EYES := 8
const MAX_PORTALS := 4
const MAX_RABBITS := 18
var game: Control
var eyes: Array[Dictionary] = []
var eclipse: Dictionary = {}
var darkness := 0.0
var serial := 0

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	eyes.clear()
	eclipse.clear()
	darkness = 0.0
	serial = 0
	_clear_marks()
	for z in game.zombies:
		z.erase("tewi_luck_until")
		z.erase("tewi_luck_owner")
		if String(z.kind) == "moon_portal":
			z.health = 0.0

func clear_owner(owner: int) -> void:
	eyes = eyes.filter(func(e): return int(e.owner) != owner)
	if int(eclipse.get("owner", -1)) == owner:
		eclipse.clear()
		darkness = 0.0
	for z in game.zombies:
		if int(z.get("reisen_portal_owner", -1)) == owner:
			z.health = 0.0
		if int(z.get("tewi_luck_owner", -1)) == owner:
			z.erase("tewi_luck_until")
			z.erase("tewi_luck_owner")
	_clear_marks(owner)

func _clear_marks(owner: int = -1) -> void:
	for layer in [game.grid, game.support_grid]:
		for row in layer:
			for plant in row:
				if plant != null and (owner == -1 or int(plant.get("reisen_eye_owner", -2)) == owner):
					plant.erase("reisen_dazed")
					plant.erase("reisen_eye_owner")

func queue_eye(boss: Dictionary, cell: Vector2i, delay: float = 1.25) -> void:
	if eyes.size() >= MAX_EYES or not game._is_row_active(cell.x) or cell.y < 0 or cell.y >= game.COLS:
		return
	if eyes.any(func(e): return e.cell == cell):
		return
	eyes.append({"owner": int(boss.uid), "cell": cell, "age": 0.0, "delay": delay, "duration": 3.8})

func start_eclipse(boss: Dictionary, strike: bool = false) -> void:
	eclipse = {"owner": int(boss.uid), "age": 0.0, "duration": 7.0, "strike": strike, "struck": false, "cells": _target_cells(2)}

func _target_cells(count: int) -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []
	for row in game.active_rows:
		for col in range(game.COLS):
			var p = game._targetable_plant_at(row, col)
			if p != null and float(p.health) > 0:
				occupied.append(Vector2i(row, col))
	var selected: Array[Vector2i] = []
	for i in range(mini(count, occupied.size())):
		selected.append(occupied[posmod(serial * 3 + i * maxi(1, occupied.size() / count), occupied.size())])
	return selected

func spawn_portal(boss: Dictionary, cell: Vector2i) -> bool:
	if not game._is_row_active(cell.x) or cell.y < 4 or cell.y >= game.COLS or game._targetable_plant_at(cell.x, cell.y) != null:
		return false
	var portals: Array = game.zombies.filter(func(z): return String(z.kind) == "moon_portal" and float(z.health) > 0)
	if portals.size() >= MAX_PORTALS or portals.any(func(z): return Vector2i(z.get("portal_cell", Vector2i(-1, -1))) == cell):
		return false
	game._spawn_zombie_at("moon_portal", cell.x, game._cell_center(cell.x, cell.y).x, true)
	var portal: Dictionary = game.zombies.back()
	portal["reisen_portal_owner"] = int(boss.uid)
	portal["portal_cell"] = cell
	portal["portal_age"] = 0.0
	portal["portal_delay"] = 4.0
	portal["portal_rank"] = int(game.TouhouDifficulty.profile(game.current_level).rank)
	return true

func cast(boss: Dictionary, pattern: String) -> void:
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	serial += 1
	if String(boss.kind) == "tewi_boss":
		# Original lucky-foot support is modest, brief, and cancelled on her defeat.
		for z in game.zombies:
			if not game._is_boss_zombie(z) and game._is_enemy_zombie(z) and float(z.health) > 0:
				z["tewi_luck_until"] = game.level_time + 2.5
				z["tewi_luck_owner"] = int(boss.uid)
				break
		return
	if pattern.begins_with("nonspell_"):
		return
	for cell in _target_cells(2 + rank):
		queue_eye(boss, cell)
	if pattern in ["reisen_invisible_moon", "pressure_lunar_crossfire", "pressure_lunar_domain"]:
		start_eclipse(boss, pattern != "reisen_invisible_moon")
	if pattern in ["reisen_invisible_moon", "reisen_tele_mesmerism", "pressure_lunar", "pressure_lunar_domain"]:
		var remaining := 1 + rank / 2
		for row_offset in range(game.active_rows.size()):
			for col_offset in range(3):
				var row := int(game.active_rows[posmod(serial + row_offset, game.active_rows.size())])
				if remaining > 0 and spawn_portal(boss, Vector2i(row, 6 + col_offset)):
					remaining -= 1

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0:
		return
	delta = maxf(0, delta)
	var owners := {}
	for z in game.zombies:
		if float(z.get("tewi_luck_until", 0)) <= game.level_time:
			z.erase("tewi_luck_until")
			z.erase("tewi_luck_owner")
		if String(z.kind) in ["reisen_boss", "tewi_boss"] and float(z.health) > 0:
			owners[int(z.uid)] = true
	_clear_marks()
	for i in range(eyes.size() - 1, -1, -1):
		var eye: Dictionary = eyes[i]
		eye.age += delta
		if not owners.has(int(eye.owner)) or float(eye.age) >= float(eye.delay) + float(eye.duration):
			eyes.remove_at(i)
			continue
		var cell := Vector2i(eye.cell)
		if float(eye.age) < float(eye.delay):
			continue
		var plant = game._targetable_plant_at(cell.x, cell.y)
		if plant != null and float(plant.get("holy_invincible_timer", 0)) <= 0:
			plant["reisen_dazed"] = true
			plant["reisen_eye_owner"] = eye.owner
			if fposmod(float(eye.age) - float(eye.delay), 1.45) < delta:
				# The eye is a real pressure source in PvZ: every marked plant,
				# including a healing gourd, takes periodic damage.
				game._damage_plant_cell(cell.x, cell.y, 72.0, 0.0)
	if not eclipse.is_empty():
		eclipse.age += delta
		if not owners.has(int(eclipse.owner)) or float(eclipse.age) >= float(eclipse.duration):
			eclipse.clear()
		else:
			# Sun production is delayed, never deletes already earned sunlight.
			for row in game.active_rows:
				for col in range(game.COLS):
					var p = game._targetable_plant_at(row, col)
					if p != null and p.has("sun_timer"):
						p.sun_timer += delta * 0.35
			if bool(eclipse.strike) and not bool(eclipse.struck) and float(eclipse.age) >= 2.5:
				eclipse.struck = true
				for cell in eclipse.cells:
					game._damage_plant_cell(cell.x, cell.y, 110.0, 0.0)
	var target := 0.0 if eclipse.is_empty() else 0.8
	darkness = move_toward(darkness, target, delta * 0.4)
	# Iterate a snapshot: a portal may append a new zombie during this loop.
	for portal in game.zombies.duplicate():
		if String(portal.kind) != "moon_portal" or float(portal.health) <= 0:
			continue
		var cell := Vector2i(portal.get("portal_cell", Vector2i(-1, -1)))
		if not owners.has(int(portal.get("reisen_portal_owner", -1))) or not game._is_enemy_zombie(portal) or game._targetable_plant_at(cell.x, cell.y) != null:
			portal.health = 0.0
			continue
		portal.portal_age += delta
		if float(portal.portal_age) >= float(portal.portal_delay):
			portal.health = 0.0
			var rabbits: Array = game.zombies.filter(func(z): return String(z.kind) in ["moon_rabbit", "moon_rabbit_guard"] and float(z.health) > 0)
			if rabbits.size() < MAX_RABBITS:
				game._spawn_zombie_at("moon_rabbit_guard" if int(portal.portal_rank) >= 2 else "moon_rabbit", cell.x, float(portal.x), true)

func range_limit(row: int, plant_x: float, original: float) -> float:
	if eclipse.is_empty():
		return original
	var col := clampi(int((plant_x - game.BOARD_ORIGIN.x) / game.CELL_SIZE.x), 0, game.COLS - 1)
	return minf(original, game.CELL_SIZE.x * 5.5)

func deflect_shot(projectile: Dictionary, row: int, position: Vector2) -> void:
	for eye in eyes:
		var cell := Vector2i(eye.cell)
		if cell.x != row or absf(position.x - game._cell_center(cell.x, cell.y).x) > game.CELL_SIZE.x * 0.7:
			continue
		var p = game._targetable_plant_at(cell.x, cell.y)
		if p != null and bool(p.get("reisen_dazed", false)):
			# Friendly projectiles remain friendly, but a small angular error can miss.
			projectile.velocity_y = float(projectile.speed) * (0.16 if (cell.x + cell.y) % 2 == 0 else -0.16)
			projectile.free_aim = true
			return

func frame_index(boss: Dictionary) -> int:
	var pose := String(boss.get("rumia_state", "idle"))
	if float(boss.get("flash", 0)) > 0.10 and float(boss.get("touhou_cast_remaining", 0)) <= 0:
		pose = "hit"
	var offset: int = {"shift": 3, "shot": 6, "eye": 9, "luck": 9, "hit": 12, "phase": 15, "special": 18, "final": 18}.get(pose, 0)
	if float(boss.get("health", 1)) <= 0:
		return 21
	var elapsed := float(boss.get("animation_time", game.level_time))
	if float(boss.get("touhou_cast_remaining", 0)) > 0:
		elapsed = float(boss.get("touhou_cast_duration", 0)) - float(boss.touhou_cast_remaining)
	return offset + int([0, 1, 2, 1][posmod(int(elapsed * 6.5), 4)])

func draw_boss(center: Vector2, boss: Dictionary) -> void:
	var kind := String(boss.kind)
	var texture: Texture2D = game._try_get_boss_frame_texture(kind, frame_index(boss))
	if texture == null:
		return
	var scale: float = game._touhou_boss_draw_scale(kind)
	var extent := texture.get_size() * scale
	game.draw_texture_rect(texture, Rect2(center + Vector2(-extent.x * 0.5, game.TouhouSpriteDefs.top_offset(kind)), extent), false, Color(1, 0.87, 0.92) if float(boss.get("flash", 0)) > 0 else Color.WHITE)
	if kind == "reisen_boss" and float(boss.get("touhou_cast_remaining", 0)) > 0:
		var eye_pos := center + Vector2(-12, -73) * scale
		_draw_eye(eye_pos, 34 * scale, 0.78)
		for ring in range(3):
			var r := (24 + fposmod(game.level_time * 30 + ring * 24, 80)) * scale
			game.draw_arc(eye_pos, r, -0.6, PI + 0.6, 32, Color(RED, 0.27 * (1 - (r / scale - 24) / 80)), 1.5, true)

func _draw_eye(center: Vector2, radius: float, alpha: float) -> void:
	var outline := PackedVector2Array()
	for i in range(33):
		var angle := TAU * i / 32.0
		outline.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.4))
	game.draw_colored_polygon(outline, Color(RED, alpha * 0.13))
	game.draw_polyline(outline, Color(RED, alpha), 1.6, true)
	game.draw_circle(center, radius * 0.25, Color(RED, alpha))
	game.draw_line(center - Vector2(0, radius * 0.2), center + Vector2(0, radius * 0.2), Color("1f152e"), 2, true)

func draw_ground() -> void:
	# Sparse moonlit grass tufts keep the six stable lanes visibly plantable.
	for row in game.active_rows:
		for col in range(game.COLS):
			var rect: Rect2 = game._cell_rect(row, col)
			var tip := rect.position + rect.size * Vector2(0.16 + (col % 3) * 0.23, 0.86)
			var h := minf(7, rect.size.y * 0.12)
			game.draw_polyline(PackedVector2Array([tip + Vector2(-3, -h * 0.7), tip, tip + Vector2(1, -h), tip, tip + Vector2(4, -h * 0.6)]), Color(0.53, 0.67, 0.61, 0.13), 1, true)
	for eye in eyes:
		var cell := Vector2i(eye.cell)
		var rect: Rect2 = game._cell_rect(cell.x, cell.y).grow(-4)
		var warning := float(eye.age) < float(eye.delay)
		var color := RED
		game.draw_rect(rect, Color(color, 0.05 if warning else 0.13))
		game.draw_rect(rect, Color(color, 0.65), false, 1.5, true)
		_draw_eye(rect.get_center(), rect.size.x * 0.3, 0.45 if warning else 0.8)
	if not eclipse.is_empty() and bool(eclipse.strike) and float(eclipse.age) < 3.0:
		for cell in eclipse.cells:
			var rect: Rect2 = game._cell_rect(cell.x, cell.y).grow(-6)
			game.draw_rect(rect, Color(MOON, 0.15), true)
			game.draw_arc(rect.get_center(), rect.size.y * 0.35, -PI * 0.5, -PI * 0.5 + TAU * minf(1, float(eclipse.age) / 2.5), 32, MOON, 2, true)

func draw_overlay() -> void:
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	if darkness > 0:
		game.draw_rect(board, Color(0.07, 0.025, 0.12, darkness * 0.20))
	if game.touhou_danmaku != null:
		var return_active: bool = game.touhou_danmaku.casts.any(func(c): return String(c.pattern) == "pressure_lunar_domain") or game.touhou_danmaku.bullets.any(func(b): return b.has("reisen_return_x"))
		if return_active:
			for x in [0.2, 0.84]:
				var start := board.position + Vector2(board.size.x * x, 5)
				game.draw_line(start, start + Vector2(0, board.size.y - 10), Color(RED, 0.50), 2, true)
	# Keep guidance in the reserved side corridor, outside cards and boss HP.
	if game.ui_font != null:
		var x: float = board.end.x + 8
		var font_size := 11 if game.size.x < 1100 else 14
		var labels := ["红眼 · 攻速干扰", "空心弹 · 无伤幻视", "月门 · 击破阻援", "葫芦 · 持续回血"]
		for i in range(labels.size()):
			game._draw_text(labels[i], Vector2(x, board.end.y - 67 + i * 18), font_size, GREEN if i == 3 else MOON)

func draw_unit(center: Vector2, zombie: Dictionary) -> void:
	var kind := String(zombie.kind)
	if kind == "moon_portal":
		var age := float(zombie.get("portal_age", 0))
		var ratio := clampf(age / float(zombie.get("portal_delay", 4)), 0, 1)
		game.draw_circle(center - Vector2(0, 14), 31, Color("110d25"))
		for ring in range(3):
			game.draw_arc(center - Vector2(0, 14), 26 + ring * 4, age + ring, age + ring + TAU * 0.8, 32, Color(RED if ring == 1 else MOON, 0.7), 2, true)
		game.draw_arc(center - Vector2(0, 14), 36, -PI * 0.5, -PI * 0.5 + TAU * ratio, 40, RED, 3, true)
		if game.ui_font != null:
			game._draw_text(str(maxi(1, ceili(4 - age))), center + Vector2(-6, -8), 20, MOON)
		return
	var guard := kind == "moon_rabbit_guard"
	var armor := guard and float(zombie.get("shield_health", 0)) > 0
	var hop := maxf(0, sin(game.level_time * 5 + float(zombie.get("anim_phase", 0)))) * (2 if guard else 6)
	center.y -= hop
	game.draw_circle(center + Vector2(0, 22 + hop), 20, Color(0.025, 0.03, 0.06, 0.45))
	game.draw_rect(Rect2(center + Vector2(-13, -13), Vector2(26, 33)), Color("647b9a") if guard else Color("b6b0c6"))
	game.draw_line(center + Vector2(-8, 14), center + Vector2(-13, 30), Color("2c334a"), 10, true)
	game.draw_line(center + Vector2(7, 14), center + Vector2(14, 28), Color("2c334a"), 10, true)
	for side in [-1, 1]:
		var ear := center + Vector2(side * 10, -52)
		game.draw_line(ear + Vector2(0, 16), ear + Vector2(side * 5, -13), Color("d8e1d5"), 10, true)
		game.draw_line(ear + Vector2(0, 11), ear + Vector2(side * 5, -10), Color("d591af"), 4, true)
	game.draw_circle(center + Vector2(0, -24), 19, Color("a6b8ab"))
	game.draw_circle(center + Vector2(-10, -27), 5, Color("f8edf2"))
	game.draw_circle(center + Vector2(-11, -27), 2.8, RED)
	game.draw_circle(center + Vector2(5, -26), 4, Color("f8edf2"))
	game.draw_circle(center + Vector2(4, -26), 2.5, RED)
	game.draw_line(center + Vector2(-12, -12), center + Vector2(1, -10), Color("382f40"), 3, true)
	game.draw_line(center + Vector2(-12, -4), center + Vector2(-28, 8), Color("a6b8ab"), 8, true)
	if armor:
		game.draw_arc(center + Vector2(0, -24), 21, PI, TAU, 24, Color("dde5fa"), 9, true)
		game.draw_rect(Rect2(center + Vector2(7, -11), Vector2(14, 29)), Color("c1ccdf"))
		game.draw_arc(center + Vector2(14, 2), 5, 0, TAU, 16, RED, 2, true)
	if float(zombie.get("tewi_luck_until", 0)) > game.level_time:
		game.draw_arc(center + Vector2(0, -20), 32, game.level_time, game.level_time + TAU, 32, Color("f7cd82"), 2, true)

func lane_color(row: int) -> Color:
	return Color("233c3a") if row % 2 == 0 else Color("1d3435")

func draw_background() -> void:
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	game.ThemeLib.draw_gradient_rect_v(game, Rect2(Vector2.ZERO, game.size), Color("080b16"), Color("211b2d"))
	var vanishing := Vector2(board.end.x + (game.size.x - board.end.x) * 0.52, board.position.y + board.size.y * 0.32)
	var moon_radius := clampf((game.size.x - board.end.x) * 0.25, 18, 47)
	for halo in range(4, 0, -1):
		game.draw_circle(vanishing, moon_radius + halo * 11, Color(MOON, 0.025))
	game.draw_circle(vanishing, moon_radius, MOON)
	if darkness > 0:
		game.draw_circle(vanishing + Vector2(moon_radius * (1.8 - darkness * 2), 0), moon_radius * 0.98, Color("0b1020"))
	# Nested architectural frames move toward the viewer; only scenery rotates.
	for i in range(9):
		var depth := fposmod(i / 9.0 + game.level_time * 0.012, 1.0)
		var extent := Vector2(48, 70) + Vector2(game.size.x * 1.25, game.size.y * 0.95) * pow(depth, 2)
		var rotation := sin(game.level_time * 0.08) * 0.06 + (1 - depth) * 0.24
		var outline := PackedVector2Array()
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
			outline.append(vanishing + (extent * corner).rotated(rotation))
		game.draw_polyline(outline, Color("432e41"), 9 + depth * 12, true)
		game.draw_polyline(outline, Color("867081"), 1.5, true)
		# Crossbars and shoji lattice reveal actual doors inside the rotating frames.
		for divider in [-0.72, -0.36, 0.0, 0.36, 0.72]:
			for side in [-1, 1]:
				var inside := vanishing + Vector2(extent.x * 0.78 * side, extent.y * divider).rotated(rotation)
				var outside := vanishing + Vector2(extent.x * side, extent.y * divider).rotated(rotation)
				game.draw_line(inside, outside, Color(MOON, 0.10 + depth * 0.08), 1.2, true)
		for side in [-1, 1]:
			var a := vanishing + Vector2(extent.x * 0.78 * side, -extent.y).rotated(rotation)
			var b := vanishing + Vector2(extent.x * 0.78 * side, extent.y).rotated(rotation)
			game.draw_line(a, b, Color("574255"), 3 + depth * 3, true)
		for side in [-1, 1]:
			var lantern := vanishing + Vector2(side * extent.x, extent.y * 0.12).rotated(rotation)
			var lamp_scale := 0.5 + depth
			game.draw_line(lantern - Vector2(0, 28 * lamp_scale), lantern, Color("a88b94"), 1, true)
			game.draw_circle(lantern, 15 * lamp_scale, Color(RED, 0.045))
			game.draw_rect(Rect2(lantern - Vector2(5, 9) * lamp_scale, Vector2(10, 18) * lamp_scale), Color("cc8d9e"))
			for line in [-1, 0, 1]:
				game.draw_line(lantern + Vector2(-5, line * 7) * lamp_scale, lantern + Vector2(5, line * 7) * lamp_scale, Color("55344b"), 1.2, true)
	game.draw_rect(board.grow(7), Color("424759"), false, 5, true)
	game.draw_rect(board.grow(3), Color("a4b5b8"), false, 1, true)
