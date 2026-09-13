extends RefCounted

const Visuals = preload("res://scripts/runtime/kaguya_visuals.gd")
const COLORS = [Color("eb739c"), Color("9fe5e8"), Color("ffd187"), Color("a8dea5"), Color("c3a5f4")]
var game: Control
var marks: Array[Dictionary] = []
var treasures: Array[Dictionary] = []
var rewind: Dictionary = {}
var flash = 0.0
var serial = 0
var night = -1

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	marks.clear()
	treasures.clear()
	rewind.clear()
	flash = 0.0
	serial = 0
	night = -1

func clear_owner(owner: int) -> void:
	marks = marks.filter(func(m): return int(m.owner) != owner)
	for treasure in treasures:
		if int(treasure.owner) == owner:
			treasure.unit.health = 0.0
	treasures = treasures.filter(func(t): return int(t.owner) != owner)
	if int(rewind.get("owner", -1)) == owner:
		rewind.clear()

func _ordinary(z: Dictionary) -> bool:
	return not game._is_boss_zombie(z) and not bool(game.Defs.ZOMBIES[String(z.kind)].get("boss_summon", false))

func claim_death(z: Dictionary) -> bool:
	# The marker travels with the entity's stable UID through every resurrection.
	if String(game.current_level.get("id", "")) != "3-24-b" or not _ordinary(z):
		return true
	if z.get("kaguya_death_paid", false):
		return false
	z["kaguya_death_paid"] = true
	return true

func begin_rewind(boss: Dictionary, seconds: float = 4.0, anchor: int = -1) -> void:
	if not rewind.is_empty():
		return
	var plants: Array = []
	for layer in range(2):
		var cells: Array = game.grid if layer == 0 else game.support_grid
		for row in game.active_rows:
			for col in range(game.COLS):
				var p = cells[row][col]
				if p != null and float(p.health) > 0:
					# Keep a reference to spent cooldowns/ultimates, restore only physical state.
					plants.append({"unit": p, "row": row, "col": col, "layer": layer, "health": float(p.health), "armor": float(p.get("armor_health", 0))})
	var enemies: Array = []
	for z in game.zombies:
		if _ordinary(z) and float(z.health) > 0 and enemies.size() < 65:
			enemies.append({"unit": z, "state": z.duplicate(true)})
	rewind = {"owner": int(boss.uid), "anchor": anchor, "age": 0.0, "duration": seconds, "plants": plants, "enemies": enemies, "cutoff": int(game.next_zombie_uid)}
	game._show_banner("时间已被记录 · %.0f 秒后回溯，期间新种植物会消失" % seconds, 2.5)

func apply_rewind() -> void:
	if rewind.is_empty():
		return
	var state = rewind
	rewind = {}
	for cells in [game.grid, game.support_grid]:
		for row in game.active_rows:
			for col in range(game.COLS):
				cells[row][col] = null
	for record in state.plants:
		var p: Dictionary = record.unit
		p.health = minf(float(record.health), float(p.max_health))
		p.armor_health = minf(float(record.armor), float(p.get("max_armor_health", 0)))
		p.row = record.row
		p.col = record.col
		p.flash = 0.3
		p.spawn_time = game.level_time
		# An already spent click ultimate, passive revival, food or cooldown stays spent.
		var cells: Array = game.grid if int(record.layer) == 0 else game.support_grid
		cells[record.row][record.col] = p
	var captured = {}
	for record in state.enemies:
		captured[int(record.state.uid)] = true
	game.zombies = game.zombies.filter(func(z): return not _ordinary(z) or (int(z.uid) < int(state.cutoff) and not captured.has(int(z.uid))))
	for record in state.enemies:
		if game.zombies.size() >= 70:
			break
		var z: Dictionary = record.state.duplicate(true)
		z["kaguya_death_paid"] = bool(record.unit.get("kaguya_death_paid", false))
		z.spawn_time = game.level_time
		z.flash = 0.28
		game.zombies.append(z)
	# Old target references and pre-rewind shots must not hit resurrected entities.
	game.projectiles.clear()
	game.rollers.clear()
	if game.touhou_danmaku != null:
		game.touhou_danmaku.bullets.clear()
		game.touhou_danmaku.beams.clear()
	for tile in game._ensure_eirin_runtime().tiles:
		if bool(tile.active) and String(tile.kind) == "lava":
			game._set_cell_terrain_kind(tile.cell.x, tile.cell.y, "lava")
			var base = game.support_grid[tile.cell.x][tile.cell.y]
			if base != null and String(base.kind) == "cork_plug":
				game._seal_lava_cell(tile.cell.x, tile.cell.y)
	flash = 0.8
	game._show_banner("须臾逆转 · 生死重映", 1.4)

func summon_treasure(boss: Dictionary, kind: String) -> int:
	if treasures.size() >= 3 or game._active_zombie_count() >= 65:
		return -1
	var row = int(game.active_rows[posmod(serial * 2 + treasures.size(), game.active_rows.size())])
	var count = game.zombies.size()
	game._spawn_zombie_at("kaguya_treasure", row, game._cell_center(row, 6).x, true)
	if game.zombies.size() == count:
		return -1
	var unit: Dictionary = game.zombies.back()
	unit["treasure_kind"] = kind
	treasures.append({"owner": int(boss.uid), "unit": unit, "age": 0.0, "tick": 2.0})
	return int(unit.uid)

func _near(z: Dictionary, treasure: Dictionary) -> bool:
	return absf(float(z.row) - float(treasure.unit.row)) <= 1 and absf(float(z.x) - float(treasure.unit.x)) <= game.CELL_SIZE.x * 2

func damage_factor(z: Dictionary) -> float:
	if not _ordinary(z) or not game._is_enemy_zombie(z):
		return 1.0
	for t in treasures:
		if float(t.age) >= 2 and float(t.unit.health) > 0 and game._is_enemy_zombie(t.unit) and String(t.unit.treasure_kind) == "bowl" and _near(z, t):
			return 0.5
	return 1.0

func plant_stilled(row: int, col: int) -> bool:
	return marks.any(func(m): return m.kind == "eternity" and m.cell == Vector2i(row, col) and float(m.age) >= 2 and float(m.age) < 5)

func speed_factor(z: Dictionary) -> float:
	if not _ordinary(z):
		return 1.0
	for m in marks:
		if m.kind == "eternity" and float(m.age) >= 2 and float(m.age) < 5 and int(z.row) == m.cell.x and absf(float(z.x) - game._cell_center(m.cell.x, m.cell.y).x) < game.CELL_SIZE.x * 0.55:
			return 0.0
	return 1.0

func mark(boss: Dictionary, cell: Vector2i, kind: String, damage: float, delay: float = 2.0) -> void:
	if marks.size() < 24:
		marks.append({"owner": int(boss.uid), "cell": cell, "kind": kind, "damage": damage, "delay": delay, "age": 0.0, "hit": false})

func cast(boss: Dictionary, pattern: String) -> void:
	serial += 1
	if pattern.begins_with("nonspell_"):
		return
	var rank = int(game.TouhouDifficulty.profile(game.current_level).rank)
	var occupied: Array[Vector2i] = []
	for row in game.active_rows:
		for col in range(game.COLS):
			if game._targetable_plant_at(row, col) != null:
				occupied.append(Vector2i(row, col))
	var targets: Array[Vector2i] = []
	for n in range(mini(3 + rank, occupied.size())):
		var index = posmod(serial * 7, occupied.size())
		targets.append(occupied[index])
		occupied.remove_at(index)
	match pattern:
		"kaguya_dragon":
			for cell in targets:
				mark(boss, cell, "dragon", 95 + rank * 17)
		"kaguya_bowl":
			summon_treasure(boss, "bowl")
			for cell in targets:
				mark(boss, cell, "bowl", 78 + rank * 15)
		"kaguya_robe":
			game._ensure_eirin_runtime().world = "lava"
			game._ensure_eirin_runtime().supply_terrain_tool("lava")
			for cell in targets:
				game._ensure_eirin_runtime().queue_tile(boss, cell, "lava")
				mark(boss, cell, "robe", 75 + rank * 15)
		"kaguya_swallow":
			var anchor = summon_treasure(boss, "swallow")
			if anchor >= 0:
				begin_rewind(boss, 5.0, anchor)
		"kaguya_branch":
			game._ensure_eirin_runtime().switch_world(boss)
			for cell in targets:
				for col in range(maxi(0, cell.y - 1), mini(game.COLS, cell.y + 2)):
					mark(boss, Vector2i(cell.x, col), "branch", 68 + rank * 13, 2.0 + abs(col - cell.y) * 0.45)
		"pressure_eternity":
			for cell in targets:
				mark(boss, cell, "eternity", 53 + rank * 12)
			game._show_banner("永恒花圃 · 两秒后标记格停长三秒，格内小怪也会停步", 2.5)
		"pressure_eternity_crossfire":
			for cell in targets:
				for beat in range(3):
					mark(boss, cell, "instant", 62 + rank * 10, 2.0 + beat * 0.55)
		"pressure_eternity_domain":
			begin_rewind(boss, 4.0)
			game._ensure_eirin_runtime().switch_world(boss)
			for cell in targets:
				mark(boss, cell, "branch", 105, 2.0)
		_:
			if pattern.begins_with("kaguya_night_"):
				night = int(pattern.get_slice("_", 2))
				if night in [0, 2, 4]:
					begin_rewind(boss, 4.0)
				else:
					game._ensure_eirin_runtime().switch_world(boss)
				for cell in targets:
					mark(boss, cell, "night", 88 + rank * 15, 2.0)

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0:
		return
	flash = maxf(0, flash - delta)
	var owners = {}
	for z in game.zombies:
		if String(z.kind) == "kaguya_boss" and float(z.health) > 0:
			owners[int(z.uid)] = true
	for i in range(treasures.size() - 1, -1, -1):
		var t = treasures[i]
		t.age += delta
		if not owners.has(int(t.owner)) or float(t.unit.health) <= 0 or not game._is_enemy_zombie(t.unit) or float(t.age) >= 10:
			if int(rewind.get("anchor", -1)) == int(t.unit.uid):
				rewind.clear()
			t.unit.health = 0.0
			treasures.remove_at(i)
			continue
		t.tick -= delta
		if float(t.tick) <= 0:
			t.tick += 1.0
			if String(t.unit.treasure_kind) == "swallow":
				for z in game.zombies:
					if _ordinary(z) and game._is_enemy_zombie(z) and float(z.health) > 0 and _near(z, t):
						z.health = minf(float(z.max_health), float(z.health) + 55)
	if not rewind.is_empty():
		if not owners.has(int(rewind.owner)):
			rewind.clear()
		else:
			rewind.age += delta
			if float(rewind.age) >= float(rewind.duration):
				apply_rewind()
	for i in range(marks.size() - 1, -1, -1):
		var m = marks[i]
		m.age += delta
		if not owners.has(int(m.owner)) or float(m.age) >= (5.0 if m.kind == "eternity" else float(m.delay) + 0.65):
			marks.remove_at(i)
			continue
		if float(m.age) >= float(m.delay) and not m.hit:
			m.hit = true
			game._damage_plant_cell(m.cell.x, m.cell.y, float(m.damage), 0.0)

func frame_index(boss: Dictionary) -> int:
	var pose = String(boss.get("rumia_state", "idle"))
	var age = float(boss.get("animation_time", game.level_time))
	if float(boss.get("health", 1)) <= 0:
		return 21
	if float(boss.get("flash", 0)) > 0.12 and float(boss.get("touhou_cast_remaining", 0)) <= 0:
		return [12, 13, 14][posmod(int(age * 6), 3)]
	var frames: Array = {"idle": [0,1,2,1], "shift": [3,4,5,4], "shot": [6,7,8,7], "special": [9,10,11,10], "phase": [15,16,17,16], "final": [18,19,20,23,20,19]}.get(pose, [0,1,2,1])
	return frames[posmod(int(age * 6), frames.size())]

func draw_boss(center: Vector2, boss: Dictionary) -> void:
	var texture: Texture2D = game._try_get_boss_frame_texture("kaguya_boss", frame_index(boss))
	if texture != null:
		var extent: Vector2 = texture.get_size() * game._touhou_boss_draw_scale("kaguya_boss")
		game.draw_texture_rect(texture, Rect2(center + Vector2(-extent.x / 2, game.TouhouSpriteDefs.top_offset("kaguya_boss")), extent), false)

func draw_treasure(center: Vector2, z: Dictionary) -> void:
	Visuals.treasure(game, center, String(z.get("treasure_kind", "bowl")), 1.0)

func draw_overlay() -> void:
	Visuals.overlay(self)
