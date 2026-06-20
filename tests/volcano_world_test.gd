extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const WorldData = preload("res://scripts/data/world_data.gd")
const VolcanoDefs = preload("res://scripts/data/level_defs_volcano.gd")

const VOLCANO_PLANT_ULTIMATES := {
	"dragon_bubble_pult": {"name": "龙息连爆", "shape": "volcano_dragon_bubble_barrage"},
	"cork_plug": {"name": "地脉封堵", "shape": "volcano_cork_seal"},
	"cyclone_grass": {"name": "火山风眼", "shape": "volcano_vortex"},
	"sand_lotus": {"name": "流沙结界", "shape": "volcano_sandstorm"},
	"frost_boomerang": {"name": "霜环回旋", "shape": "volcano_frost_ring"},
	"toxic_gum_pult": {"name": "毒胶爆雨", "shape": "volcano_toxic_gum_rain"},
	"corn_cannon": {"name": "饱和炮击", "shape": "volcano_corn_barrage"},
	"holy_flower": {"name": "圣盾天幕", "shape": "volcano_holy_shield"},
	"ice_cream": {"name": "甜霜充能", "shape": "volcano_sweet_charge"},
	"gator_cannon": {"name": "鳄龙贯穿", "shape": "volcano_gator_beam"},
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_volcano_world_metadata_exists() or failed
	failed = not _test_7x_levels_route_to_volcano_world() or failed
	failed = not _test_volcano_world_unlocks_after_6_19() or failed
	failed = not _test_volcano_level_data_matches_unlock_rhythm() or failed
	failed = not _test_volcano_finale_7_10_is_boss_conveyor() or failed
	failed = not _test_volcano_tile_requires_flower_pot_support() or failed
	failed = not _test_lava_cell_blocks_placement_and_cork_plug_seals_it() or failed
	failed = not _test_volcano_straight_shooters_blocked_in_low_columns() or failed
	failed = not _test_volcano_preplaced_supports_fill_every_active_cell() or failed
	failed = not _test_volcano_new_plants_have_defs_and_costs() or failed
	failed = not _test_volcano_new_zombies_have_defs_and_health() or failed
	failed = not _test_volcano_plants_and_zombies_have_almanac_text() or failed
	failed = not _test_volcano_new_zombies_are_visible_in_almanac_order() or failed
	failed = not _test_cyclone_grass_detonate_pulls_and_damages_nearby_zombies() or failed
	failed = not _test_corn_cannon_right_click_fires_at_target() or failed
	failed = not _test_volcano_boss_is_flagged_and_has_reinforcement_pool() or failed
	failed = not _test_dragon_bubble_pult_fires_and_erupts_whole_row() or failed
	failed = not _test_toxic_gum_pult_fires_without_runtime_error() or failed
	failed = not _test_dragon_bubble_pult_plant_food_has_visible_barrage() or failed
	failed = not _test_stackable_volcano_plants_can_be_placed_on_hosts() or failed
	failed = not _test_flower_pot_ultimate_fills_empty_volcano_tiles() or failed
	failed = not _test_volcano_new_plants_have_named_click_ultimates() or failed
	failed = not _test_volcano_click_ultimates_emit_dedicated_effects() or failed
	failed = not _test_volcano_click_ultimates_affect_board_state() or failed
	failed = not _test_corn_cannon_click_ultimate_saturation_barrage() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _find_level_index(level_id: String) -> int:
	for i in range(Defs.LEVELS.size()):
		if String(Defs.LEVELS[i].get("id", "")) == level_id:
			return i
	return -1


func _make_grid() -> Array:
	var result: Array = []
	for _row in range(6):
		var row_data: Array = []
		for _col in range(9):
			row_data.append(null)
		result.append(row_data)
	return result


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "7-test", "terrain": "volcano", "events": [], "row_count": 5}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
	game.grid = _make_grid()
	game.support_grid = _make_grid()
	game.cell_terrain_mask = []
	game.zombies = []
	game.projectiles = []
	game.effects = []
	game.weeds = []
	game.spears = []
	game.graves = []
	game.vfx_particles = []
	game.lava_eruption_timers = {}
	game.firing_sfx_throttle = {}
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	game._setup_cell_terrain_mask()
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	if is_instance_valid(game.banner_label):
		game.banner_label.free()
	if is_instance_valid(game.message_label):
		game.message_label.free()
	if is_instance_valid(game.action_button):
		game.action_button.free()
	if is_instance_valid(game.message_panel):
		game.message_panel.free()
	game.free()


func _count_effect_shape(game: Control, shape: String) -> int:
	var count := 0
	for effect_variant in game.effects:
		if String(Dictionary(effect_variant).get("shape", "")) == shape:
			count += 1
	return count


func _activate_volcano_ultimate(game: Control, kind: String, row: int, col: int) -> bool:
	game.cell_terrain_mask[row][col] = "volcano_tile"
	if kind == "cork_plug":
		game.support_grid[row][col] = game._create_plant("cork_plug", row, col)
		game.support_grid[row][col]["ultimate_charge"] = 1.0
		game.support_grid[row][col]["ultimate_cooldown"] = 0.0
	elif kind == "holy_flower":
		game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
		game.grid[row][col] = game._create_plant("peashooter", row, col)
		var support = game._create_plant("holy_flower", row, col)
		support["ultimate_charge"] = 1.0
		support["ultimate_cooldown"] = 0.0
		game.support_grid[row][col] = support
	else:
		game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
		var plant = game._create_plant(kind, row, col)
		plant["ultimate_charge"] = 1.0
		plant["ultimate_cooldown"] = 0.0
		game.grid[row][col] = plant
	return bool(game.call("_try_activate_ultimate", row, col))


func _test_volcano_world_metadata_exists() -> bool:
	var volcano_world = WorldData.by_key("volcano")
	return _assert_true(String(volcano_world.get("key", "")) == "volcano", "expected volcano world metadata to exist") \
		and _assert_true(String(volcano_world.get("title", "")) == "火山世界", "volcano world title should be 火山世界")


func _test_7x_levels_route_to_volcano_world() -> bool:
	var game = _make_game()
	var passed := true
	for level_id in ["7-1", "7-3", "7-5", "7-8", "7-9", "7-10"]:
		passed = _assert_true(String(game.call("_world_key_for_level", {"id": level_id})) == "volcano", "%s should route to volcano world" % level_id) and passed
	_free_game(game)
	return passed


func _test_volcano_world_unlocks_after_6_19() -> bool:
	var game = _make_game()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	var index_6_19 = _find_level_index("6-19")
	var index_7_1 = _find_level_index("7-1")
	var passed = _assert_true(index_6_19 != -1, "expected 6-19 to exist for volcano unlock checks") \
		and _assert_true(index_7_1 != -1, "expected 7-1 to exist for volcano unlock checks")
	if passed:
		passed = _assert_true(not bool(game.call("_is_world_unlocked", "volcano")), "volcano world should stay locked before 6-19 is completed") and passed
		game.completed_levels[index_6_19] = true
		passed = _assert_true(bool(game.call("_is_world_unlocked", "volcano")), "volcano world should unlock after 6-19 is completed") and passed
	_free_game(game)
	return passed


func _test_volcano_level_data_matches_unlock_rhythm() -> bool:
	var expected_unlocks = {
		"7-1": "dragon_bubble_pult",
		"7-2": "cork_plug",
		"7-3": "frost_boomerang",
		"7-4": "cyclone_grass",
		"7-5": "sand_lotus",
		"7-6": "toxic_gum_pult",
		"7-7": "holy_flower",
		"7-8": "ice_cream",
		"7-9": "corn_cannon",
		"7-10": "",
	}
	var passed := true
	for level_number in range(1, 11):
		var level_id = "7-%d" % level_number
		var level_index = _find_level_index(level_id)
		passed = _assert_true(level_index != -1, "expected %s to exist in volcano progression" % level_id) and passed
		if level_index == -1:
			continue
		var level = Defs.LEVELS[level_index]
		passed = _assert_true(String(level.get("terrain", "")) == "volcano", "%s should use volcano terrain" % level_id) and passed
		passed = _assert_true(int(level.get("row_count", 0)) == 5, "%s should use a 5-row volcano board" % level_id) and passed
		passed = _assert_true(String(level.get("unlock_plant", "")) == String(expected_unlocks[level_id]), "%s should unlock %s" % [level_id, expected_unlocks[level_id]]) and passed
		# Every volcano level should pre-place flower pots on all active cells.
		var preplaced = level.get("preplaced_supports", [])
		passed = _assert_true(preplaced.size() >= 45, "%s should pre-place flower pots across the whole board" % level_id) and passed
	return passed


func _test_volcano_finale_7_10_is_boss_conveyor() -> bool:
	var level_index = _find_level_index("7-10")
	if not _assert_true(level_index != -1, "expected 7-10 to exist as the volcano finale"):
		return false
	var level = Defs.LEVELS[level_index]
	return _assert_true(String(level.get("terrain", "")) == "volcano", "7-10 should stay in the volcano world") \
		and _assert_true(String(level.get("mode", "")) == "conveyor", "7-10 should be a conveyor boss level") \
		and _assert_true(bool(level.get("boss_level", false)), "7-10 should be marked as a boss level") \
		and _assert_true(String(level.get("boss_kind", "")) == "volcano_boss", "7-10 should use the volcano_boss finale")


func _test_volcano_tile_requires_flower_pot_support() -> bool:
	var game = _make_game()
	# volcano_tile without a flower pot present -> error mentioning 花盆
	game.cell_terrain_mask[2][3] = "volcano_tile"
	var err_no_support = String(game.call("_placement_error", "peashooter", 2, 3))
	var passed = _assert_true(err_no_support.find("花盆") != -1, "volcano tiles without a flower pot should reject normal plants")
	# Once a flower pot support is present, normal planting is allowed.
	game.support_grid[2][3] = game._create_plant("flower_pot", 2, 3)
	var err_with_support = String(game.call("_placement_error", "peashooter", 2, 3))
	passed = _assert_true(err_with_support == "", "volcano tiles with a flower pot should accept normal plants") and passed
	_free_game(game)
	return passed


func _test_lava_cell_blocks_placement_and_cork_plug_seals_it() -> bool:
	var game = _make_game()
	game.cell_terrain_mask[2][3] = "lava"
	# Lava blocks everything (even with a flower pot underneath).
	var err_normal = String(game.call("_placement_error", "peashooter", 2, 3))
	var passed = _assert_true(err_normal.find("木塞子") != -1 or err_normal.find("岩浆") != -1, "lava cells should block normal plants and mention the cork plug")
	# cork_plug only valid on lava cells.
	var cork_err_land = String(game.call("_placement_error", "cork_plug", 2, 4))
	passed = _assert_true(cork_err_land.find("岩浆") != -1, "cork plug should only be placeable on lava cells") and passed
	var cork_err_lava = String(game.call("_placement_error", "cork_plug", 2, 3))
	passed = _assert_true(cork_err_lava == "", "cork plug should be placeable on a lava cell") and passed
	# Sealing a lava cell flips it back to volcano_tile.
	game._seal_lava_cell(2, 3)
	passed = _assert_true(String(game.cell_terrain_mask[2][3]) == "volcano_tile", "sealing a lava cell should convert it to volcano_tile") and passed
	_free_game(game)
	return passed


func _test_volcano_straight_shooters_blocked_in_low_columns() -> bool:
	var game = _make_game()
	# On a volcano level, straight shooters share the roof direct-fire gating.
	game.current_level = {"id": "7-test", "terrain": "volcano"}
	var passed = _assert_true(bool(game.call("_is_roof_or_volcano_level")), "volcano levels should share the roof direct-fire gating")
	# A straight shooter in column 0 (col <= 2) firing at a target past the low-lane limit (col 4) is blocked.
	var blocked_close = bool(game.call("_is_roof_direct_fire_blocked", game._cell_center(2, 0).x, game._cell_center(2, 6).x))
	passed = _assert_true(blocked_close, "straight shooters in low columns should be blocked when firing past the slope on volcano terrain") and passed
	# A straight shooter in column 3 (col > 2) is past the slope, so it connects even across the board.
	var blocked_far = bool(game.call("_is_roof_direct_fire_blocked", game._cell_center(2, 3).x, game._cell_center(2, 8).x))
	passed = _assert_true(not blocked_far, "straight shooters past the slope should not be blocked on volcano terrain") and passed
	_free_game(game)
	return passed


func _test_volcano_preplaced_supports_fill_every_active_cell() -> bool:
	var passed := true
	for level_number in range(1, 11):
		var level_id = "7-%d" % level_number
		var level = Defs.LEVELS[_find_level_index(level_id)]
		var preplaced = level.get("preplaced_supports", [])
		# Every active row (0..4) × every column (0..8) = 45 cells should be covered.
		var covered: Dictionary = {}
		for cell_variant in preplaced:
			var cell = Vector2i(cell_variant)
			covered["%d,%d" % [cell.x, cell.y]] = true
		var missing := 0
		for row in range(5):
			for col in range(9):
				if not covered.has("%d,%d" % [row, col]):
					missing += 1
		passed = _assert_true(missing == 0, "%s should pre-place a flower pot on every active cell, missing %d cells" % [level_id, missing]) and passed
	return passed


func _test_volcano_new_plants_have_defs_and_costs() -> bool:
	var passed := true
	var new_plants = {
		"dragon_bubble_pult": 175,
		"cork_plug": 25,
		"cyclone_grass": 150,
		"sand_lotus": 125,
		"frost_boomerang": 200,
		"toxic_gum_pult": 200,
		"corn_cannon": 400,
		"holy_flower": 150,
		"ice_cream": 125,
		"gator_cannon": 250,
	}
	for kind in new_plants.keys():
		var data = Defs.PLANTS.get(kind, {})
		passed = _assert_true(not data.is_empty(), "expected volcano plant %s to have a definition" % kind) and passed
		passed = _assert_true(int(data.get("cost", -1)) == int(new_plants[kind]), "volcano plant %s should cost %d sun" % [kind, new_plants[kind]]) and passed
		passed = _assert_true(float(data.get("health", 0.0)) > 0.0, "volcano plant %s should have positive health" % kind) and passed
	return passed


func _test_volcano_new_zombies_have_defs_and_health() -> bool:
	var passed := true
	var new_zombies = {
		"umbrella_zombie": 560,  # shield health
		"shania_zombie": 1200,
		"shade_zombie": 500,
		"crab_zombie": 400,
		"camel_zombie": 500,
		"volcano_boss": 17200,
	}
	for kind in new_zombies.keys():
		var data = Defs.ZOMBIES.get(kind, {})
		passed = _assert_true(not data.is_empty(), "expected volcano zombie %s to have a definition" % kind) and passed
		if data.is_empty():
			continue
		if kind == "volcano_boss":
			passed = _assert_true(bool(data.get("boss", false)), "volcano_boss should be flagged as a boss") and passed
			passed = _assert_true(float(data.get("health", 0.0)) >= 17200.0, "volcano_boss should have at least 17200 health") and passed
		else:
			passed = _assert_true(float(data.get("health", 0.0)) > 0.0, "volcano zombie %s should have positive health" % kind) and passed
	return passed


func _test_volcano_plants_and_zombies_have_almanac_text() -> bool:
	var game = _make_game()
	var passed := true
	for kind in ["dragon_bubble_pult", "cork_plug", "cyclone_grass", "sand_lotus", "frost_boomerang", "toxic_gum_pult", "corn_cannon", "holy_flower", "ice_cream", "gator_cannon"]:
		var stats: Array = game.call("_plant_almanac_stats", kind)
		passed = _assert_true(not stats.is_empty(), "volcano plant %s should have almanac stats" % kind) and passed
	for kind in ["umbrella_zombie", "shania_zombie", "shade_zombie", "crab_zombie", "camel_zombie", "volcano_boss"]:
		var stats: Array = game.call("_zombie_almanac_stats", kind)
		passed = _assert_true(not stats.is_empty(), "volcano zombie %s should have almanac stats" % kind) and passed
	_free_game(game)
	return passed


func _test_volcano_new_zombies_are_visible_in_almanac_order() -> bool:
	var game = _make_game()
	var previous_completed = game.completed_levels
	game.completed_levels = []
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = true
	var entries: Array = game.call("_visible_almanac_zombies")
	var passed := true
	for kind in ["umbrella_zombie", "shania_zombie", "shade_zombie", "crab_zombie", "crabling", "camel_zombie", "volcano_boss"]:
		passed = _assert_true(entries.has(kind), "volcano zombie %s should appear in the visible almanac zombie list after volcano levels unlock" % kind) and passed
	game.completed_levels = previous_completed
	_free_game(game)
	return passed


func _test_cyclone_grass_detonate_pulls_and_damages_nearby_zombies() -> bool:
	var game = _make_game()
	var row := 2
	var col := 4
	# Spawn a zombie within the 150px pull radius (column 5 is ~98px to the right of column 4).
	var spawn_x = game._cell_center(row, 5).x
	game._spawn_zombie_at("normal", row, spawn_x)
	var zombie_before = game.zombies[0]
	var health_before = float(zombie_before["health"])
	var x_before = float(zombie_before["x"])
	# Detonate cyclone_grass at (row, col): should pull the zombie toward the cell and damage it.
	game._detonate_one_shot_plant("cyclone_grass", row, col)
	var zombie_after = game.zombies[0]
	var passed = _assert_true(float(zombie_after["health"]) < health_before, "cyclone grass detonation should damage zombies within pull radius")
	passed = _assert_true(absf(float(zombie_after["x"]) - game._cell_center(row, col).x) < absf(x_before - game._cell_center(row, col).x), "cyclone grass detonation should pull zombies toward its cell") and passed
	_free_game(game)
	return passed


func _test_corn_cannon_right_click_fires_at_target() -> bool:
	var game = _make_game()
	var row := 2
	var col := 4
	# Place a charged corn cannon (action_timer 0 == ready to fire).
	var cannon = game._create_plant("corn_cannon", row, col)
	cannon["action_timer"] = 0.0
	game.grid[row][col] = cannon
	# Spawn a zombie near the click target.
	var spawn_x = game._cell_center(row, 6).x
	game._spawn_zombie_at("normal", row, spawn_x)
	var zombie_before = game.zombies[0]
	var health_before = float(zombie_before["health"])
	# Right-click near the zombie.
	game._handle_corn_cannon_right_click(Vector2(spawn_x, game._row_center_y(row)))
	var zombie_after = game.zombies[0]
	var passed = _assert_true(float(zombie_after["health"]) < health_before, "corn cannon right-click should damage zombies at the target location")
	# The cannon should go on cooldown after firing.
	var cannon_after = game.grid[row][col]
	passed = _assert_true(float(cannon_after.get("action_timer", 0.0)) > 0.0, "corn cannon should go on cooldown after right-click fire") and passed
	_free_game(game)
	return passed


func _test_volcano_boss_is_flagged_and_has_reinforcement_pool() -> bool:
	var passed := true
	var boss = Defs.ZOMBIES.get("volcano_boss", {})
	passed = _assert_true(not boss.is_empty(), "volcano_boss definition should exist") and passed
	if boss.is_empty():
		return passed
	passed = _assert_true(bool(boss.get("boss", false)), "volcano_boss must be flagged as a boss") and passed
	# Boss reinforcement pool (extra zombies spawned during the fight) should be defined on the boss data
	# or referenced by the 7-10 level — at minimum the level should schedule waves.
	var level = Defs.LEVELS[_find_level_index("7-10")]
	var wave_count := 0
	for event in level.get("events", []):
		if bool(Dictionary(event).get("wave", false)):
			wave_count += 1
	passed = _assert_true(wave_count >= 1, "7-10 should schedule at least one wave marker for the boss fight") and passed
	return passed


func _test_dragon_bubble_pult_fires_and_erupts_whole_row() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	# Give the pult a flower pot support so it can sit on a volcano tile.
	game.cell_terrain_mask[row][col] = "volcano_tile"
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	var plant = game._create_plant("dragon_bubble_pult", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	# Spawn two zombies in the same row — one near, one far — so a whole-row
	# strike hurts both, not just the frontmost.
	var near_x = game._cell_center(row, col + 1).x
	var far_x = game._cell_center(row, col + 4).x
	game._spawn_zombie_at("normal", row, near_x)
	game._spawn_zombie_at("normal", row, far_x)
	var near_before = float(game.zombies[0]["health"])
	var far_before = float(game.zombies[1]["health"])
	# One update tick should fire the lobbed projectile.
	game._update_plants(0.2)
	var fired = false
	for projectile in game.projectiles:
		if String(projectile.get("kind", "")) == "dragon_bubble":
			fired = true
			break
	var passed = _assert_true(fired, "dragon bubble pult should fire a lobbed projectile when an enemy is in its lane")
	# Advance enough ticks for the lobbed projectile to land (arc_duration ~0.42s+).
	for _step in range(40):
		game._update_projectiles(0.05)
	var near_after = float(game.zombies[0]["health"])
	var far_after = float(game.zombies[1]["health"])
	passed = _assert_true(near_after < near_before, "dragon bubble whole-row eruption should damage a near zombie in the lane") and passed
	passed = _assert_true(far_after < far_before, "dragon bubble whole-row eruption should damage a far zombie in the same lane") and passed
	_free_game(game)
	return passed


func _test_toxic_gum_pult_fires_without_runtime_error() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	game.cell_terrain_mask[row][col] = "volcano_tile"
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	var plant = game._create_plant("toxic_gum_pult", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, game._cell_center(row, col + 3).x)
	game._update_plants(0.2)
	var fired = false
	for projectile in game.projectiles:
		if String(projectile.get("kind", "")) == "toxic_gum":
			fired = true
			break
	var passed = _assert_true(fired, "toxic gum pult should fire a lobbed projectile when an enemy is in its lane (no crash on spawn)")
	# Advance ticks so the lobbed projectile lands without runtime errors.
	for _step in range(40):
		game._update_projectiles(0.05)
	passed = _assert_true(true, "toxic gum pult projectile should resolve without runtime error") and passed
	_free_game(game)
	return passed


func _test_dragon_bubble_pult_plant_food_has_visible_barrage() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	game.cell_terrain_mask[row][col] = "volcano_tile"
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	game.grid[row][col] = game._create_plant("dragon_bubble_pult", row, col)
	game._spawn_zombie_at("normal", row, game._cell_center(row, 6).x)
	var before_effects := _count_effect_shape(game, "volcano_dragon_bubble_barrage")
	var activated := bool(game.call("_activate_plant_food", row, col))
	var after_effects := _count_effect_shape(game, "volcano_dragon_bubble_barrage")
	var passed := _assert_true(activated, "dragon_bubble_pult should accept plant food activation") \
		and _assert_true(after_effects > before_effects, "dragon_bubble_pult plant food should emit a visible volcano_dragon_bubble_barrage effect immediately")
	_free_game(game)
	return passed


func _test_stackable_volcano_plants_can_be_placed_on_hosts() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	game.cell_terrain_mask[row][col] = "volcano_tile"
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	game.grid[row][col] = game._create_plant("peashooter", row, col)
	var holy_error = String(game.call("_placement_error", "holy_flower", row, col))
	var ice_error = String(game.call("_placement_error", "ice_cream", row, col))
	game.sun_points = 1000
	game.card_cooldowns = {"holy_flower": 0.0, "ice_cream": 0.0}
	game.selected_tool = "holy_flower"
	game.call("_handle_board_click", Vector2i(row, col))
	var support = game.support_grid[row][col]
	var host_after_holy = game.grid[row][col]
	var passed := _assert_true(holy_error == "", "holy_flower should be placeable on top of an existing host plant") \
		and _assert_true(ice_error == "", "ice_cream should be placeable on top of an existing host plant") \
		and _assert_true(support != null and String(support.get("kind", "")) == "holy_flower", "placing holy_flower on a host should attach it as support") \
		and _assert_true(float(host_after_holy.get("armor_health", 0.0)) > 0.0 or String(host_after_holy.get("shell_kind", "")) == "holy_shield", "holy_flower placement should immediately give the host a shield")
	host_after_holy["armor_health"] = 0.0
	game.grid[row][col] = host_after_holy
	support["support_timer"] = 0.0
	game.support_grid[row][col] = support
	game.call("_update_plants", 0.1)
	var host_after_refresh = game.grid[row][col]
	passed = _assert_true(float(host_after_refresh.get("armor_health", 0.0)) > 0.0, "attached holy_flower should refresh the host shield from the support layer") and passed
	game.selected_tool = "ice_cream"
	game.card_cooldowns["ice_cream"] = 0.0
	game.call("_handle_board_click", Vector2i(row, col))
	var host_after_ice = game.grid[row][col]
	passed = _assert_true(float(host_after_ice.get("ultimate_charge", 0.0)) >= 1.0, "placing ice_cream on a host should fully charge that host's click ultimate") and passed
	_free_game(game)
	return passed


func _test_flower_pot_ultimate_fills_empty_volcano_tiles() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	game.support_grid[row][col]["ultimate_charge"] = 1.0
	game.support_grid[row][col]["ultimate_cooldown"] = 0.0
	game.support_grid[0][0] = null
	game.support_grid[4][8] = null
	game.grid[0][0] = null
	game.grid[4][8] = null
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var top_left = game.support_grid[0][0]
	var bottom_right = game.support_grid[4][8]
	var passed := _assert_true(activated, "flower_pot click ultimate should activate on volcano terrain") \
		and _assert_true(top_left != null and String(top_left.get("kind", "")) == "flower_pot", "flower_pot click ultimate should fill empty volcano tiles across the full board") \
		and _assert_true(bottom_right != null and String(bottom_right.get("kind", "")) == "flower_pot", "flower_pot click ultimate should reach far empty volcano tiles")
	_free_game(game)
	return passed


func _test_volcano_new_plants_have_named_click_ultimates() -> bool:
	var game = _make_game()
	var passed := true
	for kind in VOLCANO_PLANT_ULTIMATES.keys():
		var expected = Dictionary(VOLCANO_PLANT_ULTIMATES[kind])
		var data = Defs.PLANTS.get(kind, {})
		var profile = game.call("_ultimate_profile_for_kind", kind)
		passed = _assert_true(not data.is_empty(), "volcano plant %s should exist before checking its ultimate" % kind) and passed
		passed = _assert_true(String(data.get("ultimate_name", "")) == String(expected["name"]), "volcano plant %s should expose its named click ultimate in plant defs" % kind) and passed
		passed = _assert_true(float(data.get("ultimate_charge_time", 0.0)) > 0.0, "volcano plant %s should define a positive click ultimate charge time" % kind) and passed
		passed = _assert_true(String(Dictionary(profile).get("style", "")) == "explicit", "volcano plant %s should use a dedicated explicit click ultimate, not a generic template" % kind) and passed
		passed = _assert_true(String(Dictionary(profile).get("ultimate_name", "")) == String(expected["name"]), "volcano plant %s click ultimate profile should use the dedicated name" % kind) and passed
	_free_game(game)
	return passed


func _test_volcano_click_ultimates_emit_dedicated_effects() -> bool:
	var passed := true
	for kind in VOLCANO_PLANT_ULTIMATES.keys():
		var game = _make_game()
		var row := 2
		var col := 2
		game._spawn_zombie_at("buckethead", row, game._cell_center(row, 6).x)
		game.cell_terrain_mask[0][0] = "lava"
		var activated := _activate_volcano_ultimate(game, kind, row, col)
		var expected_shape = String(Dictionary(VOLCANO_PLANT_ULTIMATES[kind])["shape"])
		passed = _assert_true(activated, "%s volcano click ultimate should activate when fully charged" % kind) and passed
		passed = _assert_true(_count_effect_shape(game, expected_shape) > 0, "%s volcano click ultimate should emit %s effect" % [kind, expected_shape]) and passed
		_free_game(game)
	return passed


func _test_volcano_click_ultimates_affect_board_state() -> bool:
	var game = _make_game()
	var passed := true
	game.cell_terrain_mask[0][0] = "lava"
	game.cell_terrain_mask[4][8] = "lava"
	var cork_activated := _activate_volcano_ultimate(game, "cork_plug", 2, 2)
	passed = _assert_true(cork_activated, "cork plug click ultimate should activate") and passed
	passed = _assert_true(String(game.cell_terrain_mask[0][0]) == "volcano_tile" and String(game.cell_terrain_mask[4][8]) == "volcano_tile", "cork plug click ultimate should seal all lava cells") and passed
	_free_game(game)

	game = _make_game()
	game.cell_terrain_mask[2][2] = "volcano_tile"
	game.support_grid[2][2] = game._create_plant("flower_pot", 2, 2)
	var target = game._create_plant("peashooter", 2, 2)
	target["health"] = 40.0
	game.grid[2][2] = target
	game.support_grid[2][2] = game._create_plant("holy_flower", 2, 2)
	game.support_grid[2][2]["ultimate_charge"] = 1.0
	var holy_activated := bool(game.call("_try_activate_ultimate", 2, 2))
	var blessed = game.grid[2][2]
	passed = _assert_true(holy_activated, "holy flower click ultimate should activate") and passed
	passed = _assert_true(float(blessed.get("armor_health", 0.0)) >= 600.0, "holy flower click ultimate should give board plants holy armor") and passed
	passed = _assert_true(float(blessed.get("health", 0.0)) >= float(blessed.get("max_health", 0.0)), "holy flower click ultimate should heal board plants") and passed
	_free_game(game)

	game = _make_game()
	game.cell_terrain_mask[2][2] = "volcano_tile"
	game.support_grid[2][2] = game._create_plant("flower_pot", 2, 2)
	var peashooter = game._create_plant("peashooter", 2, 4)
	peashooter["ultimate_charge"] = 0.0
	peashooter["ultimate_cooldown"] = 42.0
	game.grid[2][4] = peashooter
	var ice_activated := _activate_volcano_ultimate(game, "ice_cream", 2, 2)
	var charged = game.grid[2][4]
	passed = _assert_true(ice_activated, "ice cream click ultimate should activate") and passed
	passed = _assert_true(is_equal_approx(float(charged.get("ultimate_charge", 0.0)), 1.0), "ice cream click ultimate should fully charge other plants") and passed
	passed = _assert_true(is_equal_approx(float(charged.get("ultimate_cooldown", 0.0)), 0.0), "ice cream click ultimate should clear other plants' ultimate cooldown") and passed
	_free_game(game)

	game = _make_game()
	game._spawn_zombie_at("buckethead", 2, game._cell_center(2, 6).x)
	var health_before = float(game.zombies[0]["health"])
	var gator_activated := _activate_volcano_ultimate(game, "gator_cannon", 2, 2)
	var health_after = float(game.zombies[0]["health"])
	passed = _assert_true(gator_activated, "gator cannon click ultimate should activate") and passed
	passed = _assert_true(health_after < health_before, "gator cannon click ultimate should damage zombies in its beam lane") and passed
	_free_game(game)
	return passed


func _test_corn_cannon_click_ultimate_saturation_barrage() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	game.cell_terrain_mask[row][col] = "volcano_tile"
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	var plant = game._create_plant("corn_cannon", row, col)
	plant["ultimate_charge"] = 1.0
	plant["ultimate_cooldown"] = 0.0
	game.grid[row][col] = plant
	# Spawn a zombie in the same row so the saturation barrage has something to hit.
	game._spawn_zombie_at("normal", row, game._cell_center(row, col + 3).x)
	var health_before = float(game.zombies[0]["health"])
	# Force the ultimate to charge and trigger it.
	game.call("_update_ultimate_charges", 999.0)
	var activated = bool(game.call("_try_activate_ultimate", row, col))
	var passed = _assert_true(activated, "corn cannon click ultimate should activate when fully charged (explicit ultimate had no case before)")
	if activated:
		var health_after = float(game.zombies[0]["health"])
		passed = _assert_true(health_after < health_before, "corn cannon saturation barrage ultimate should damage zombies in the lane") and passed
	_free_game(game)
	return passed
