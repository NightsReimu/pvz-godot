extends RefCounted

const KIND := "reimu_boss"
const RED := Color("f56878")
const BLUE := Color("78d4e8")
const GOLD := Color("efce86")
const MAX_TILES := 6

var game: Control
var tiles: Array[Dictionary] = []
var light := 0.0
var serial := 0

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	tiles.clear()
	light = 0.0
	serial = 0
	_clear_marks()

func clear_owner(owner: int) -> void:
	tiles = tiles.filter(func(t): return int(t.owner) != owner)
	_clear_marks()

func _clear_marks() -> void:
	for layer in [game.grid, game.support_grid]:
		for row in layer:
			for plant in row:
				if plant != null:
					plant.erase("reimu_sealed")
					plant.erase("reimu_guard")
	for zombie in game.zombies:
		zombie.erase("reimu_purified")

func queue_tile(boss: Dictionary, cell: Vector2i, kind: String, delay: float = 1.0) -> void:
	if tiles.size() >= MAX_TILES or cell.x < 0 or cell.x >= game.ROWS or cell.y < 0 or cell.y >= game.COLS or not game._is_row_active(cell.x):
		return
	if kind not in ["seal", "purify", "guard"]:
		return
	if tiles.any(func(t): return t.cell == cell):
		return
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var duration := 1.6 + rank * 0.2 if kind == "seal" else 5.5
	tiles.append({"owner": int(boss.uid), "cell": cell, "kind": kind, "age": 0.0, "delay": delay, "duration": duration})

func cast(boss: Dictionary, pattern: String) -> void:
	clear_owner(int(boss.uid))
	if pattern.begins_with("nonspell_"):
		return
	serial += 1
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var row_count: int = game.active_rows.size()
	if row_count == 0:
		return
	var row := int(game.active_rows[posmod(serial * 2, row_count)])
	var other := int(game.active_rows[posmod(serial * 2 + 3, row_count)])
	if pattern == "pressure_ofuda_domain":
		# Three alternating pairs leave protected cells beside the sealed cells.
		for index in range(3):
			var lane := int(game.active_rows[posmod(serial + index * 2, row_count)])
			queue_tile(boss, Vector2i(lane, 2 + index), "seal" if index < 2 else "purify", 1.2)
			queue_tile(boss, Vector2i(lane, 3 + index), "guard" if index < 2 else "purify", 1.45)
		return
	if pattern == "pressure_ofuda_crossfire":
		for lane in [row, other]:
			queue_tile(boss, Vector2i(lane, 3), "seal", 1.2)
			queue_tile(boss, Vector2i(lane, 2), "guard", 1.2)
		queue_tile(boss, Vector2i(row, 6), "purify", 1.2)
		return
	queue_tile(boss, Vector2i(row, 2 + serial % 3), "seal")
	queue_tile(boss, Vector2i(other, 4 + serial % 3), "purify")
	queue_tile(boss, Vector2i(other, 1 + serial % 2), "guard")
	if rank >= 2 or pattern == "pressure_ofuda":
		queue_tile(boss, Vector2i(int(game.active_rows[posmod(serial + 1, row_count)]), 3 + serial % 3), "seal", 1.3)

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0:
		return
	var owners := {}
	var backdrop_active := false
	for zombie in game.zombies:
		if String(zombie.kind) in [KIND, "marisa_boss", "hakutaku_boss", "mokou_boss"] and float(zombie.health) > 0:
			backdrop_active = true
		if String(zombie.kind) == KIND and float(zombie.health) > 0.0:
			owners[int(zombie.uid)] = true
	light = move_toward(light, 1.0 if backdrop_active else 0.0, maxf(0, delta) * 0.38)
	_clear_marks()
	for index in range(tiles.size() - 1, -1, -1):
		var tile: Dictionary = tiles[index]
		var before := float(tile.age)
		tile.age += maxf(0, delta)
		if not owners.has(int(tile.owner)) or float(tile.age) >= float(tile.delay) + float(tile.duration):
			tiles.remove_at(index)
			continue
		if float(tile.age) < float(tile.delay):
			continue
		var active_delta := maxf(0, float(tile.age) - maxf(before, float(tile.delay)))
		var cell := Vector2i(tile.cell)
		var plant = game._targetable_plant_at(cell.x, cell.y)
		match String(tile.kind):
			"seal":
				for layer in [game.grid, game.support_grid]:
					var occupant = layer[cell.x][cell.y]
					if occupant != null and float(occupant.get("holy_invincible_timer", 0.0)) <= 0.0:
						occupant["reimu_sealed"] = true
			"guard":
				if plant != null:
					plant["reimu_guard"] = 0.55
					game._heal_targetable_plant_cell(cell.x, cell.y, 6.0 * active_delta, 0.0)
			"purify":
				var rect: Rect2 = game._cell_rect(cell.x, cell.y)
				for zombie in game.zombies:
					if game._is_boss_zombie(zombie) or not game._is_enemy_zombie(zombie) or float(zombie.health) <= 0:
						continue
					if int(zombie.row) == cell.x and float(zombie.x) >= rect.position.x and float(zombie.x) <= rect.end.x:
						zombie["reimu_purified"] = true
						zombie.health -= 12.0 * active_delta

func frame_index(boss: Dictionary) -> int:
	var pose := String(boss.get("rumia_state", "idle"))
	if float(boss.get("flash", 0.0)) > 0.10 and float(boss.get("touhou_cast_remaining", 0.0)) <= 0.0:
		pose = "hit"
	var sequence: Array = [0, 1, 2, 1]
	match pose:
		"shift": sequence = [3, 4, 5, 4]
		"ofuda", "seal": sequence = [6, 7, 8, 7]
		"dream": sequence = [9, 10, 11, 10]
		"hit": sequence = [12, 13, 14, 13]
		"phase": sequence = [15, 16, 17, 16]
		"barrier": sequence = [18, 19, 20, 19]
		"final": sequence = [21, 22, 23, 22]
	var elapsed := float(boss.get("animation_time", game.level_time))
	if pose != "idle" and float(boss.get("touhou_cast_remaining", 0.0)) > 0.0:
		elapsed = float(boss.get("touhou_cast_duration", 0.0)) - float(boss.touhou_cast_remaining)
	return int(sequence[posmod(int(elapsed * 7), sequence.size())])

func draw_boss(center: Vector2, boss: Dictionary) -> void:
	var texture: Texture2D = game._try_get_boss_frame_texture(KIND, frame_index(boss))
	if texture == null:
		return
	# The caller already applies the responsive battle unit scale.
	var scale: float = game._touhou_boss_draw_scale(KIND)
	var extent := texture.get_size() * scale
	var position := center + Vector2(-extent.x * 0.5, game.TouhouSpriteDefs.top_offset(KIND))
	game.draw_texture_rect(texture, Rect2(position, extent), false, Color(1, 0.88, 0.88) if float(boss.get("flash", 0)) > 0 else Color.WHITE)
	var seal_center := center + Vector2(0, -35 * scale)
	if String(boss.get("rumia_state", "idle")) in ["barrier", "phase", "final"]:
		game.draw_arc(seal_center, 78 * scale, game.level_time * 0.35, game.level_time * 0.35 + TAU, 48, Color(RED, 0.35), 1.5, true)

func draw_ground() -> void:
	for tile in tiles:
		var cell := Vector2i(tile.cell)
		var rect: Rect2 = game._cell_rect(cell.x, cell.y).grow(-5)
		var color: Color = {"seal": RED, "purify": BLUE, "guard": GOLD}[tile.kind]
		var warning := float(tile.age) < float(tile.delay)
		var pulse := 0.5 + sin(float(tile.age) * 7) * 0.5
		game.draw_rect(rect, Color(color, 0.045 + pulse * 0.03 if warning else 0.13))
		game.draw_rect(rect, Color(color, 0.45 if warning else 0.78), false, 1.5, true)
		var center := rect.get_center()
		var radius := minf(rect.size.x, rect.size.y) * 0.32
		for side in [-1, 1]:
			var pos := center + Vector2(side * radius * 0.65, 0)
			game.draw_rect(Rect2(pos - Vector2(5, 12), Vector2(10, 24)), Color(color, 0.25 if warning else 0.6), false, 1.0)
			game.draw_line(pos - Vector2(2, 8), pos + Vector2(2, 8), Color(color, 0.65), 1.2, true)
		game.draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * (clampf(float(tile.age) / float(tile.delay), 0, 1) if warning else 1.0), 32, Color(color, 0.65), 1.5, true)

func draw_overlay() -> void:
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	for tile in tiles:
		if float(tile.age) < float(tile.delay):
			continue
		var cell := Vector2i(tile.cell)
		var plant = game._targetable_plant_at(cell.x, cell.y)
		if plant == null:
			continue
		var mark_scale: float = game._battle_unit_scale()
		var center: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, -20 * mark_scale)
		if String(tile.kind) == "seal" and bool(plant.get("reimu_sealed", false)):
			game.draw_line(center + Vector2(-17, -18) * mark_scale, center + Vector2(17, 18) * mark_scale, Color(RED, 0.85), maxf(1.5, 2.5 * mark_scale), true)
			game.draw_line(center + Vector2(17, -18) * mark_scale, center + Vector2(-17, 18) * mark_scale, Color(RED, 0.85), maxf(1.5, 2.5 * mark_scale), true)
		elif String(tile.kind) == "guard":
			game.draw_arc(center, minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 0.37, 0, TAU, 32, Color(GOLD, 0.65), 2, true)
	if game.touhou_danmaku != null:
		for c in game.touhou_danmaku.casts:
			if String(c.kind) != KIND:
				continue
			var p := String(c.pattern)
			if p in ["reimu_duplex", "reimu_great_duplex"]:
				for x in [0.62, 0.49]:
					var rect := Rect2(board.position + Vector2(board.size.x * x - 7, 6), Vector2(14, board.size.y - 12))
					game.draw_rect(rect, Color(BLUE if x < 0.5 else RED, 0.10))
					game.draw_rect(rect, Color(BLUE if x < 0.5 else RED, 0.58), false, 1.5)
			elif p in ["reimu_danmaku_barrier", "reimu_hakurei_barrier"]:
				var center := board.position + board.size * Vector2(0.53, 0.5)
				for factor in [0.29, 0.18]:
					var extent: Vector2 = board.size * float(factor)
					var rotation := float(c.get("barrier_rotation", 0)) * (1 if factor > 0.2 else -1)
					var outline := PackedVector2Array()
					for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
						outline.append(center + (extent * corner).rotated(rotation))
					game.draw_polyline(outline, Color(RED if factor > 0.2 else BLUE, 0.36), 1.5, true)
			elif p == "reimu_blink" and c.has("blink_position"):
				var point := Vector2(c.blink_position)
				game.draw_arc(point, (24 + fposmod(float(c.age) * 24, 30)) * game._battle_unit_scale(), 0, TAU, 32, Color(GOLD, 0.48), 1.5, true)
	# Use the reserved bamboo path; the bottom strip belongs to the boss HUD.
	if light > 0.1 and game.ui_font != null and game.zombies.any(func(b): return String(b.kind) == KIND and float(b.health) > 0):
		var font_size := 12 if game.size.x < 1100 else 15
		var labels := ["赤符·短暂封印", "蓝符·净化僵尸", "金符·恢复减伤"]
		var pos := Vector2(board.end.x + 10, board.end.y - 46)
		game.draw_rect(Rect2(pos - Vector2(4, font_size), Vector2(game.size.x - pos.x - 4, 62)), Color(0.02, 0.06, 0.08, 0.8))
		for index in range(3):
			game._draw_text(labels[index], pos + Vector2(0, index * 19), font_size, [RED, BLUE, GOLD][index])

func lane_color(row: int) -> Color:
	return (Color("1d342f") if row % 2 == 0 else Color("192e2a")).lerp(Color("304c3d") if row % 2 == 0 else Color("284334"), light * 0.75)

func draw_background() -> void:
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	game.draw_rect(Rect2(Vector2.ZERO, game.size), Color("060d15").lerp(Color("101921"), light * 0.7))
	game.draw_rect(Rect2(Vector2(0, board.position.y - 18), Vector2(game.size.x, game.size.y)), Color("0b1b1c"))
	var moon := Vector2(board.end.x + maxf(45, (game.size.x - board.end.x) * 0.54), board.position.y + 42)
	var radius := clampf((game.size.x - board.end.x) * 0.2, 16, 40)
	for halo in range(4, 0, -1):
		game.draw_circle(moon, radius + halo * 11, Color(0.67, 0.77, 0.81, (0.005 + light * 0.005) * (5 - halo)))
	game.draw_circle(moon, radius, Color("899aab").lerp(Color("c8d5d5"), light))
	game.draw_circle(moon + Vector2(radius * 0.4, -radius * 0.20), radius * 0.90, Color("09131c"))
	# Three sparse bamboo layers. Brighter joints appear only with boss light.
	for layer in range(3):
		var count := 17 if layer == 0 else 10
		for stalk in range(count):
			var x := fposmod(stalk * 143.0 + layer * 57, game.size.x + 90) - 35
			if layer > 0 and x > board.position.x - 28 and x < board.end.x + 26:
				continue
			var bottom := Vector2(x, game.size.y + 20)
			var top := Vector2(x + sin(stalk * 1.7) * 26, 22 + stalk % 3 * 24)
			var color: Color = [Color("102127"), Color("15312e"), Color("1b3b31")][layer]
			var width := 6.0 + layer * 3.0
			game.draw_line(bottom, top, color, width, true)
			game.draw_line(bottom + Vector2(2, 0), top + Vector2(2, 0), Color("48694c"), 1, true)
			for joint in range(1, 9):
				var point := bottom.lerp(top, joint / 9.0)
				game.draw_line(point - Vector2(width * 0.6, 0), point + Vector2(width * 0.6, 0), Color(color.lightened(0.10 + light * 0.10), 0.8), 2, true)
				if joint % 2 == 0:
					for leaf in range(3):
						var tip := point + Vector2((25 + leaf * 12) * (-1 if joint % 4 == 0 else 1), -10 - leaf * 7)
						game.draw_colored_polygon(PackedVector2Array([point, tip + Vector2(0, -5), tip + Vector2(4, 2)]), color.lightened(0.04))
	# Low mist stays around the outer path, with no bright full-screen bloom.
	for mist in range(6):
		var y := board.end.y + 12 + mist * 5
		game.draw_line(Vector2(board.position.x - 20, y), Vector2(board.end.x + 30, y + sin(game.level_time * 0.2 + mist) * 5), Color(0.49, 0.61, 0.65, 0.025), 7, true)
	for leaf in range(15):
		var point := Vector2(fposmod(leaf * 109 + game.level_time * (5 + leaf % 3), game.size.x), board.position.y + fposmod(leaf * 53 + game.level_time * 4, board.size.y + 20))
		game.draw_line(point, point + Vector2(6, -2), Color(0.55, 0.66, 0.48, 0.15 + light * 0.10), 1.5, true)
