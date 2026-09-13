extends RefCounted

const Visuals = preload("res://scripts/runtime/eirin_visuals.gd")
const RED = Color("ff6b88")
const MOON = Color("c7e8ff")
var game: Control
var sky = false
var exit_age = -1.0
var world = "moon"
var world_timer = 6.0
var tiles: Array[Dictionary] = []
var strikes: Array[Dictionary] = []
var medicine: Array[Dictionary] = []
var serial = 0
var roster: Array[String] = []

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	for tile in tiles:
		_restore_tile(tile)
	tiles.clear()
	strikes.clear()
	medicine.clear()
	sky = false
	exit_age = -1.0
	world = "moon"
	world_timer = 6.0
	serial = 0
	roster.clear()

func hold_finale() -> bool:
	if sky:
		return false
	if exit_age < 0:
		exit_age = 0.0
		game._show_banner("回廊已至尽头——虚假的月亮显现", 3.0)
	return true

func clear_owner(owner: int) -> void:
	for tile in tiles:
		if int(tile.owner) == owner:
			_restore_tile(tile)
	tiles = tiles.filter(func(t): return int(t.owner) != owner)
	strikes = strikes.filter(func(t): return int(t.owner) != owner)
	medicine = medicine.filter(func(t): return int(t.owner) != owner)
	for z in game.zombies:
		if int(z.get("eirin_owner", -1)) == owner:
			z.health = 0.0

func queue_tile(boss: Dictionary, cell: Vector2i, terrain: String) -> void:
	if tiles.size() >= 12 or tiles.any(func(t): return t.cell == cell):
		return
	tiles.append({"owner": int(boss.uid), "cell": cell, "kind": terrain, "old": game._cell_terrain_kind(cell.x, cell.y), "age": 0.0, "active": false, "tick": 1.0})

func _restore_tile(tile: Dictionary) -> void:
	if bool(tile.active):
		game._set_cell_terrain_kind(tile.cell.x, tile.cell.y, String(tile.old))
	game.current_level["lava_cells"] = game.current_level.get("lava_cells", []).filter(func(c): return c != tile.cell)

func switch_world(boss: Dictionary) -> void:
	var choices = ["water", "lava", "roof"]
	choices.erase(world)
	world = choices[game.rng.randi_range(0, choices.size() - 1)]
	var rank = int(game.TouhouDifficulty.profile(game.current_level).rank)
	var candidates: Array[Vector2i] = []
	for row in game.active_rows:
		for col in range(game.COLS):
			candidates.append(Vector2i(row, col))
	for n in range(4 + rank * 2):
		var index = game.rng.randi_range(0, candidates.size() - 1)
		var cell = candidates[index]
		candidates.remove_at(index)
		queue_tile(boss, cell, choices[n % choices.size()] if rank == 3 else world)
	game._show_banner({"water": "虚月映海 · 蓝格即将化水", "lava": "虚月映火 · 红格即将熔化", "roof": "虚月映檐 · 紫格即将化为屋顶"}[world], 2.0)
	supply_terrain_tool(world)

func supply_terrain_tool(terrain: String) -> void:
	# Guarantee a usable counter during the warning, while retaining random draws.
	if game._is_conveyor_level() and not game.active_cards.is_empty():
		var tool: String = {"water": "lily_pad", "lava": "cork_plug", "roof": "flower_pot"}[terrain]
		var slot = game.active_cards.find("")
		if slot < 0:
			slot = game.active_cards.size() - 1
		game.active_cards[slot] = tool
		game.queue_redraw()

func queue_strike(boss: Dictionary, cell: Vector2i, damage: float, pattern: String) -> void:
	if strikes.size() >= 18 or strikes.any(func(s): return s.cell == cell):
		return
	strikes.append({"owner": int(boss.uid), "cell": cell, "damage": damage, "age": 0.0, "pattern": pattern})

func cast(boss: Dictionary, pattern: String) -> void:
	serial += 1
	if pattern.begins_with("nonspell_") or pattern == "eirin_vessel":
		return
	var rank = int(game.TouhouDifficulty.profile(game.current_level).rank)
	var occupied: Array[Vector2i] = []
	for row in game.active_rows:
		for col in range(game.COLS):
			if game._targetable_plant_at(row, col) != null:
				occupied.append(Vector2i(row, col))
	var count = 2 + rank
	for n in range(mini(count, occupied.size())):
		var index = posmod(serial * 5 + n * maxi(1, occupied.size() / count), occupied.size())
		queue_strike(boss, occupied[index], 62.0 + rank * 16.0, pattern)
	match pattern:
		"eirin_life", "eirin_rising":
			# The cellular grid blooms into neighboring cells after a visible warning.
			if not occupied.is_empty():
				var seed_cell: Vector2i = occupied[serial % occupied.size()]
				for r in range(maxi(0, seed_cell.x - 1), mini(game.ROWS, seed_cell.x + 2)):
					queue_strike(boss, Vector2i(r, seed_cell.y), 75.0 + rank * 13.0, pattern)
		"pressure_medicine":
			start_medicine(boss, "rage")
		"pressure_medicine_crossfire":
			start_medicine(boss, "suppression")
		"pressure_medicine_domain":
			start_medicine(boss, "rage")
			start_medicine(boss, "suppression")
			switch_world(boss)
		"eirin_astronomical":
			if sky:
				switch_world(boss)

func start_medicine(boss: Dictionary, kind: String) -> void:
	if medicine.size() >= 3:
		return
	var row = int(game.active_rows[posmod(serial + medicine.size(), game.active_rows.size())])
	var before = game.zombies.size()
	game._spawn_zombie_at("eirin_medicine", row, game._cell_center(row, 7).x, true)
	if game.zombies.size() == before:
		return
	var bottle: Dictionary = game.zombies.back()
	bottle["eirin_owner"] = int(boss.uid)
	bottle["medicine_kind"] = kind
	medicine.append({"owner": int(boss.uid), "bottle": int(bottle.uid), "kind": kind, "age": 0.0})
	game._show_banner("月都处方：两秒后抑制治疗，击碎蓝药瓶解除" if kind == "suppression" else "朱月狂剂：两秒后强化僵尸，击碎红药瓶解除", 2.0)

func heal_factor() -> float:
	for m in medicine:
		if String(m.kind) == "suppression" and float(m.age) >= 2.0 and _bottle_alive(int(m.bottle)):
			return 0.25
	return 1.0

func rage_multiplier(zombie: Dictionary, attack: bool = false) -> float:
	if game._is_boss_zombie(zombie) or not game._is_enemy_zombie(zombie) or String(zombie.kind) in ["rabbit_airship", "eirin_medicine"]:
		return 1.0
	for m in medicine:
		if String(m.kind) == "rage" and float(m.age) >= 2.0 and _bottle_alive(int(m.bottle)):
			return 1.8 if attack else 1.45
	return 1.0

func _bottle_alive(uid: int) -> bool:
	return game.zombies.any(func(z): return int(z.uid) == uid and float(z.health) > 0 and game._is_enemy_zombie(z))

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0:
		return
	if exit_age >= 0 and not sky:
		exit_age += delta
		if exit_age >= 3.0:
			sky = true
	var owners = {}
	var final_boss: Dictionary = {}
	for z in game.zombies:
		if String(z.kind) in ["eirin_boss", "kaguya_boss"] and float(z.health) > 0:
			owners[int(z.uid)] = true
			if not bool(z.get("touhou_final_preview", false)):
				final_boss = z
	if sky and not final_boss.is_empty():
		world_timer -= delta
		if world_timer <= 0:
			world_timer = 16.0
			switch_world(final_boss)
	for i in range(tiles.size() - 1, -1, -1):
		var t: Dictionary = tiles[i]
		t.age += delta
		if not owners.has(int(t.owner)) or float(t.age) >= 12.0:
			_restore_tile(t)
			tiles.remove_at(i)
			continue
		if float(t.age) < 2.0:
			continue
		if not bool(t.active):
			t.active = true
			game._set_cell_terrain_kind(t.cell.x, t.cell.y, String(t.kind))
			if String(t.kind) == "lava":
				if not game.current_level.has("lava_cells"):
					game.current_level["lava_cells"] = []
				game.current_level.lava_cells.append(t.cell)
		if String(t.kind) == "lava" and game._cell_terrain_kind(t.cell.x, t.cell.y) == "lava":
			t.tick -= minf(delta, maxf(0.0, float(t.age) - 2.0))
			if float(t.tick) <= 0:
				t.tick += 1.0
				var p = game._targetable_plant_at(t.cell.x, t.cell.y)
				var cooled: bool = game.volcano_expansion != null and game.volcano_expansion.is_cooled(t.cell)
				if p != null and String(p.kind) != "cork_plug" and not cooled:
					game._damage_plant_cell(t.cell.x, t.cell.y, 55.0, 0.0)
	for i in range(strikes.size() - 1, -1, -1):
		var s: Dictionary = strikes[i]
		s.age += delta
		if not owners.has(int(s.owner)):
			strikes.remove_at(i)
		elif float(s.age) >= 1.8:
			game._damage_plant_cell(s.cell.x, s.cell.y, float(s.damage), 0.0)
			game.effects.append({"position": game._cell_center(s.cell.x, s.cell.y), "radius": game.CELL_SIZE.x * 0.43, "time": 0.45, "duration": 0.45, "color": Color(RED, 0.5)})
			strikes.remove_at(i)
	for i in range(medicine.size() - 1, -1, -1):
		var m: Dictionary = medicine[i]
		m.age += delta
		if not owners.has(int(m.owner)) or not _bottle_alive(int(m.bottle)) or float(m.age) >= 10.0:
			for z in game.zombies:
				if int(z.uid) == int(m.bottle):
					z.health = 0.0
			medicine.remove_at(i)

func reinforcement_kind() -> String:
	if roster.is_empty():
		for key in game.Defs.ZOMBIES:
			var data: Dictionary = game.Defs.ZOMBIES[key]
			# zomboni is excluded: its board-wide ice trail has no counterplay on this stage.
			if String(key) not in ["mech_zombie", "flywheel_zombie", "zomboni"] and not bool(data.get("boss", false)) and not bool(data.get("boss_summon", false)) and not bool(data.get("non_mainline_special", false)):
				roster.append(String(key))
		roster.append_array(["star_fairy", "kedama", "rabbit_airship", "moon_rabbit", "moon_rabbit_guard"])
	var kind = roster[game.rng.randi_range(0, roster.size() - 1)]
	if kind == "rabbit_airship" and game._count_alive_enemy_zombies_by_kind(kind) >= 2:
		return "star_fairy"
	return kind

func terrain_tool_useful(kind: String) -> bool:
	var terrain: String = {"lily_pad": "water", "flower_pot": "roof", "cork_plug": "lava"}.get(kind, "")
	return terrain == "" or tiles.any(func(t): return String(t.kind) == terrain)

func draw_background() -> void:
	Visuals.background(self)

func draw_ground() -> void:
	Visuals.ground(self)

func draw_overlay() -> void:
	Visuals.overlay(self)

func frame_index(boss: Dictionary) -> int:
	var pose = String(boss.get("rumia_state", "idle"))
	if float(boss.get("flash", 0)) > 0.1 and float(boss.get("touhou_cast_remaining", 0)) <= 0:
		pose = "hit"
	var offset: int = {"shift": 3, "shot": 6, "hit": 12, "phase": 15, "special": 18, "final": 18}.get(pose, 0)
	if pose == "special" and String(boss.get("touhou_card", {}).get("pattern", "")) == "eirin_vessel":
		offset = 9
	if float(boss.get("health", 1)) <= 0:
		return 21
	return offset + int([0, 1, 2, 1][posmod(int(float(boss.get("animation_time", game.level_time)) * 6.0), 4)])

func draw_boss(center: Vector2, boss: Dictionary) -> void:
	var texture: Texture2D = game._try_get_boss_frame_texture("eirin_boss", frame_index(boss))
	if texture == null:
		return
	var extent: Vector2 = texture.get_size() * game._touhou_boss_draw_scale("eirin_boss")
	game.draw_texture_rect(texture, Rect2(center + Vector2(-extent.x * 0.5, game.TouhouSpriteDefs.top_offset("eirin_boss")), extent), false)
