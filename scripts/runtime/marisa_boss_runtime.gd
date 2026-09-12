extends RefCounted

const KIND := "marisa_boss"
const MUSHROOM := "marisa_mushroom"
const GOLD := Color("ffd275")
const BLUE := Color("8cdcf4")
const VIOLET := Color("d69bef")
const MAX_TILES := 6
const MAX_MUSHROOMS := 6

var game: Control
var tiles: Array[Dictionary] = []
var serial := 0

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	tiles.clear()
	serial = 0
	_clear_marks()
	for unit in game.zombies:
		if String(unit.kind) == MUSHROOM:
			unit.health = 0.0

func _clear_marks() -> void:
	for layer in [game.grid, game.support_grid]:
		for row in layer:
			for plant in row:
				if plant != null:
					plant.erase("marisa_glare")
					plant.erase("marisa_prism")

func clear_owner(uid: int) -> void:
	tiles = tiles.filter(func(t): return int(t.owner) != uid)
	_clear_marks()
	for unit in game.zombies:
		if String(unit.kind) == MUSHROOM and int(unit.get("marisa_owner", -1)) == uid:
			unit.health = 0.0

func queue_tile(boss: Dictionary, cell: Vector2i, kind: String, delay: float = 1.1) -> void:
	if tiles.size() >= MAX_TILES or kind not in ["glare", "prism", "mushroom"] or cell.x < 0 or cell.x >= game.ROWS or cell.y < 0 or cell.y >= game.COLS or not game._is_row_active(cell.x):
		return
	if tiles.any(func(t): return t.cell == cell):
		return
	if kind == "mushroom":
		var count := tiles.filter(func(t): return t.kind == "mushroom").size()
		for unit in game.zombies:
			if String(unit.kind) == MUSHROOM and float(unit.health) > 0:
				count += 1
				if int(unit.row) == cell.x and game._zombie_cell_col(float(unit.x)) == cell.y:
					return
		if count >= MAX_MUSHROOMS:
			return
	tiles.append({"owner": int(boss.uid), "cell": cell, "kind": kind, "age": 0.0, "delay": delay, "duration": 5.0, "variant": serial % 2})

func cast(boss: Dictionary, pattern: String) -> void:
	clear_owner(int(boss.uid))
	if pattern.begins_with("nonspell_") or game.active_rows.is_empty():
		return
	serial += 1
	var rank := int(game.TouhouDifficulty.profile(game.current_level).rank)
	var row_count: int = game.active_rows.size()
	var row := int(game.active_rows[posmod(serial * 2, row_count)])
	if pattern in ["pressure_stars_crossfire", "pressure_stars_domain"]:
		var domain := pattern.ends_with("_domain")
		queue_tile(boss, Vector2i(row, 3), "glare", 1.2)
		queue_tile(boss, Vector2i(int(game.active_rows[posmod(serial * 2 + 3, row_count)]), 3), "glare", 1.2)
		queue_tile(boss, Vector2i(row, 2), "prism", 1.2)
		if not domain:
			queue_tile(boss, Vector2i(int(game.active_rows[posmod(serial * 2 + 3, row_count)]), 2), "prism", 1.2)
		for index in range(3 if domain else 2):
			var cell := Vector2i(int(game.active_rows[posmod(serial + index * 2, row_count)]), 5 + index % 2)
			if game._targetable_plant_at(cell.x, cell.y) == null:
				queue_tile(boss, cell, "mushroom", 1.4)
		return
	queue_tile(boss, Vector2i(row, 2 + serial % 3), "glare")
	queue_tile(boss, Vector2i(int(game.active_rows[posmod(serial * 2 + 3, row_count)]), 2), "prism")
	for index in range(2 + mini(rank, 2)):
		var cell := Vector2i(int(game.active_rows[posmod(serial + index, row_count)]), 5 + (serial + index) % 3)
		if game._targetable_plant_at(cell.x, cell.y) == null:
			queue_tile(boss, cell, "mushroom", 1.3)

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0:
		return
	var remaining := maxf(0, delta)
	while remaining > 0.00001:
		var step := minf(remaining, 1.0 / 60.0)
		_tick(step)
		remaining -= step

func _tick(delta: float) -> void:
	var owners := {}
	for unit in game.zombies:
		if String(unit.kind) == KIND and float(unit.health) > 0:
			owners[int(unit.uid)] = unit
	_clear_marks()
	for index in range(tiles.size() - 1, -1, -1):
		var tile := tiles[index]
		var before := float(tile.age)
		tile.age += delta
		if not owners.has(int(tile.owner)) or float(tile.age) >= float(tile.delay) + float(tile.duration):
			tiles.remove_at(index)
			continue
		if float(tile.age) < float(tile.delay):
			continue
		var cell := Vector2i(tile.cell)
		var plant = game._targetable_plant_at(cell.x, cell.y)
		var active_delta := maxf(0, float(tile.age) - maxf(before, float(tile.delay)))
		match String(tile.kind):
			"mushroom":
				# Recheck occupancy at the end of the warning, including supports.
				if plant == null and game.support_grid[cell.x][cell.y] == null:
					game._spawn_zombie_at(MUSHROOM, cell.x, game._cell_center(cell.x, cell.y).x, true)
					var unit: Dictionary = game.zombies.back()
					unit["marisa_owner"] = tile.owner
					unit["mushroom_life"] = 16.0
					unit["mushroom_cooldown"] = 1.5
					unit["mushroom_variant"] = tile.variant
				tiles.remove_at(index)
			"glare":
				if plant != null and float(plant.get("holy_invincible_timer", 0)) <= 0:
					plant["marisa_glare"] = true
					game._damage_plant_cell(cell.x, cell.y, 10.0 * active_delta * game.TouhouDifficulty.boss_damage_multiplier(game.current_level), 0, true)
			"prism":
				if plant != null:
					plant["marisa_prism"] = 0.7
	var live_sources := {}
	for unit in game.zombies:
		if String(unit.kind) != MUSHROOM:
			continue
		if not owners.has(int(unit.get("marisa_owner", -1))):
			unit.health = 0.0
		if float(unit.health) <= 0.0:
			continue
		unit["mushroom_life"] = float(unit.get("mushroom_life", 16.0)) - delta
		if float(unit.mushroom_life) <= 0:
			unit.health = 0.0
			continue
		if not game._is_enemy_zombie(unit):
			continue
		live_sources[int(unit.uid)] = true
		if float(unit.get("special_pause_timer", 0)) > 0 or float(unit.get("rooted_timer", 0)) > 0:
			continue
		unit["mushroom_cooldown"] = float(unit.get("mushroom_cooldown", 1.5)) - delta * (0.5 if float(unit.get("slow_timer", 0)) > 0 else 1.0)
		if float(unit.mushroom_cooldown) <= 0:
			_fire_mushroom(unit, owners[int(unit.marisa_owner)])
	if game.touhou_danmaku != null:
		game.touhou_danmaku.bullets = game.touhou_danmaku.bullets.filter(func(b): return not b.has("marisa_source") or live_sources.has(int(b.marisa_source)))
		game.touhou_danmaku.beams = game.touhou_danmaku.beams.filter(func(b): return not b.has("marisa_source") or live_sources.has(int(b.marisa_source)))

func _fire_mushroom(unit: Dictionary, boss: Dictionary) -> void:
	var dm = game.touhou_danmaku
	if dm == null or not boss.has("touhou_owner"):
		return
	var scale := minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0)
	var origin := Vector2(float(unit.x), game._row_center_y(int(unit.row)) - 12.0)
	var c := {"owner": int(boss.touhou_owner), "kind": KIND, "phase": int(boss.get("boss_phase", 0)), "wave": 0}
	var extra := {"marisa_source": int(unit.uid), "damage": 32.0, "radius": 6.0 * scale}
	if int(unit.get("mushroom_variant", 0)) == 1:
		dm._beam(c, origin, origin + Vector2(-game.CELL_SIZE.x * 3.5, 0), VIOLET, 0.9, 9.0 * scale, extra)
		unit.mushroom_cooldown = 3.3
	else:
		dm._bullet(c, origin, PI, 155 * scale, VIOLET, "star", extra)
		unit.mushroom_cooldown = 2.3

func frame_index(boss: Dictionary) -> int:
	var pose := String(boss.get("rumia_state", "idle"))
	if float(boss.get("flash", 0)) > 0.1 and float(boss.get("touhou_cast_remaining", 0)) <= 0:
		pose = "hit"
	var sequence: Array = [0, 1, 2, 1]
	match pose:
		"shift": sequence = [3, 4, 5, 4]
		"laser", "light": sequence = [6, 7, 8, 7]
		"stars": sequence = [9, 10, 11, 10]
		"hit": sequence = [12, 13, 14, 13]
		"phase": sequence = [15, 16, 17, 16]
		"orbit", "spark": sequence = [18, 19, 20, 19]
		"final": sequence = [21, 22, 23, 22]
	var elapsed := float(boss.get("animation_time", game.level_time))
	if pose != "idle" and float(boss.get("touhou_cast_remaining", 0)) > 0:
		elapsed = float(boss.get("touhou_cast_duration", 0)) - float(boss.touhou_cast_remaining)
	return int(sequence[posmod(int(elapsed * 7), sequence.size())])

func draw_boss(center: Vector2, boss: Dictionary) -> void:
	var texture: Texture2D = game._try_get_boss_frame_texture(KIND, frame_index(boss))
	if texture == null:
		return
	var extent: Vector2 = texture.get_size() * game._touhou_boss_draw_scale(KIND)
	game.draw_texture_rect(texture, Rect2(center + Vector2(-extent.x * 0.5, game.TouhouSpriteDefs.top_offset(KIND)), extent), false, Color(1, 0.95, 0.84) if float(boss.get("flash", 0)) > 0 else Color.WHITE)

func draw_mushroom(center: Vector2, unit: Dictionary) -> void:
	var laser := int(unit.get("mushroom_variant", 0)) == 1
	game._draw_plant_body("fume_shroom" if laser else "puff_shroom", center, 0.95, float(unit.get("flash", 0)), 1.0)
	game.draw_arc(center + Vector2(0, -16), 28, 0, TAU, 24, Color(VIOLET, 0.8), 2, true)
	for i in range(3):
		game.draw_circle(center + Vector2(-8 + i * 8, -39), 2.0, VIOLET)

func draw_ground() -> void:
	for tile in tiles:
		var rect: Rect2 = game._cell_rect(int(tile.cell.x), int(tile.cell.y)).grow(-4)
		var color: Color = {"glare": GOLD, "prism": BLUE, "mushroom": VIOLET}[tile.kind]
		var warning := float(tile.age) < float(tile.delay)
		game.draw_rect(rect, Color(color, 0.06 if warning else 0.16))
		game.draw_rect(rect, Color(color, 0.5 if warning else 0.8), false, 1.5, true)
		var center := rect.get_center()
		var radius := minf(rect.size.x, rect.size.y) * 0.32
		game.draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(tile.age) / float(tile.delay), 0, 1), 24, color, 1.5, true)
		game._draw_text({"glare": "光", "prism": "棱", "mushroom": "菇"}[tile.kind], center + Vector2(-7, 5), 14, color)

func draw_overlay() -> void:
	if tiles.is_empty() or game.ui_font == null:
		return
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var pos := Vector2(board.end.x + 10, board.end.y - 46)
	var font_size := 12 if game.size.x < 1100 else 15
	game.draw_rect(Rect2(pos - Vector2(4, font_size), Vector2(game.size.x - pos.x - 4, 62)), Color(0.02, 0.04, 0.09, 0.82))
	var labels := ["金光·灼伤减速", "蓝棱·植物减伤", "紫菇·抢种阻止"]
	for i in range(3):
		game._draw_text(labels[i], pos + Vector2(0, i * 19), font_size, [GOLD, BLUE, VIOLET][i])
