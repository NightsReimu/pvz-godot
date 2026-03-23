extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const WorldData = preload("res://scripts/data/world_data.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_fog_world_metadata_exists() or failed
	failed = not _test_4x_levels_route_to_fog_world() or failed
	failed = not _test_fog_world_unlocks_after_3_18() or failed
	failed = not _test_fog_level_data_matches_original_unlock_rhythm() or failed
	failed = not _test_fog_endgame_map_nodes_do_not_overlap() or failed
	failed = not _test_fog_units_have_runtime_definitions() or failed
	failed = not _test_fog_world_map_title_is_not_day_adventure() or failed
	failed = not _test_fog_cells_start_hidden_on_the_right_side() or failed
	failed = not _test_plantern_reveals_a_persistent_radius() or failed
	failed = not _test_sea_shroom_is_water_only() or failed
	failed = not _test_cactus_can_pop_balloon_zombies() or failed
	failed = not _test_blover_removes_balloon_zombies() or failed
	failed = not _test_blover_temporarily_clears_all_fog() or failed
	failed = not _test_fog_plant_food_activation_matrix() or failed
	failed = not _test_plantern_plant_food_reveals_full_board_temporarily() or failed
	failed = not _test_starfruit_plant_food_spawns_extra_volley() or failed
	failed = not _test_magnet_shroom_plant_food_strips_all_metal_targets() or failed
	failed = not _test_pumpkin_can_shell_existing_plant() or failed
	failed = not _test_vasebreaker_stage_builds_hidden_vases() or failed
	failed = not _test_unopened_zombie_vases_block_vasebreaker_victory() or failed
	failed = not _test_storm_lightning_temporarily_reveals_the_board() or failed
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


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "1-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.water_rows = []
	game.grid = []
	game.support_grid = []
	for _row in range(6):
		var row_data: Array = []
		var support_row: Array = []
		for _col in range(9):
			row_data.append(null)
			support_row.append(null)
		game.grid.append(row_data)
		game.support_grid.append(support_row)
	game.zombies = []
	game.mowers = []
	for row in range(6):
		game.mowers.append({
			"row": row,
			"x": game.BOARD_ORIGIN.x - 56.0,
			"armed": true,
			"active": false,
		})
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
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


func _test_fog_world_metadata_exists() -> bool:
	var fog_world = WorldData.by_key("fog")
	var passed = _assert_true(String(fog_world.get("key", "")) == "fog", "expected fog world metadata to exist") \
		and _assert_true(String(fog_world.get("subtitle", "")) == "Adventure 4-1 ~ 4-18", "fog world subtitle should cover the full 4-1 to 4-18 expansion") \
		and _assert_true(String(fog_world.get("description", "")).find("4-18") != -1 or String(fog_world.get("description", "")).find("18") != -1, "fog world description should reflect the expanded mainline")
	return passed


func _test_4x_levels_route_to_fog_world() -> bool:
	var game = _make_game()
	var passed := true
	for level_id in ["4-1", "4-5", "4-10", "4-11", "4-16", "4-17", "4-18"]:
		passed = _assert_true(String(game.call("_world_key_for_level", {"id": level_id})) == "fog", "%s should route to fog world" % level_id) and passed
	_free_game(game)
	return passed


func _test_fog_world_unlocks_after_3_18() -> bool:
	var game = _make_game()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	var index_3_18 = _find_level_index("3-18")
	var index_4_1 = _find_level_index("4-1")
	var passed = _assert_true(index_3_18 != -1, "expected 3-18 to exist for fog unlock checks") \
		and _assert_true(index_4_1 != -1, "expected 4-1 to exist for fog unlock checks")
	if passed:
		passed = _assert_true(not bool(game.call("_is_world_unlocked", "fog")), "fog world should stay locked before 3-18 is completed") and passed
		game.completed_levels[index_3_18] = true
		passed = _assert_true(bool(game.call("_is_world_unlocked", "fog")), "fog world should unlock after 3-18 is completed") and passed
	_free_game(game)
	return passed


func _test_fog_level_data_matches_original_unlock_rhythm() -> bool:
	var expected_unlocks = {
		"4-1": "plantern",
		"4-2": "cactus",
		"4-3": "blover",
		"4-4": "",
		"4-5": "split_pea",
		"4-6": "starfruit",
		"4-7": "pumpkin",
		"4-8": "magnet_shroom",
		"4-11": "mist_orchid",
		"4-12": "anchor_fern",
		"4-13": "glowvine",
		"4-14": "brine_pot",
		"4-15": "storm_reed",
		"4-16": "moonforge",
		"4-17": "",
		"4-18": "",
	}
	var passed := true
	for level_number in range(1, 19):
		var level_id = "4-%d" % level_number
		var level_index = _find_level_index(level_id)
		passed = _assert_true(level_index != -1, "expected %s to exist in fog progression" % level_id) and passed
		if level_index == -1:
			continue
		passed = _assert_true(String(Defs.LEVELS[level_index].get("id", "")) == level_id, "%s should keep its mainline order" % level_id) and passed
	for level_id in expected_unlocks.keys():
		var level_index = _find_level_index(level_id)
		if level_index == -1:
			continue
		passed = _assert_true(String(Defs.LEVELS[level_index].get("unlock_plant", "")) == String(expected_unlocks[level_id]), "%s should unlock %s" % [level_id, expected_unlocks[level_id]]) and passed
	var vase_level = Defs.LEVELS[_find_level_index("4-5")]
	var storm_level = Defs.LEVELS[_find_level_index("4-10")]
	passed = _assert_true(String(vase_level.get("terrain", "")) == "vasebreaker_night", "4-5 should use the vasebreaker backyard terrain") and passed
	passed = _assert_true(String(vase_level.get("mode", "")) == "vasebreaker", "4-5 should use vasebreaker mode") and passed
	passed = _assert_true(String(storm_level.get("terrain", "")) == "storm_fog", "4-10 should use storm fog terrain") and passed
	passed = _assert_true(String(storm_level.get("mode", "")) == "conveyor", "4-10 should be a conveyor special stage") and passed
	var level_4_16 = Defs.LEVELS[_find_level_index("4-16")]
	var level_4_17 = Defs.LEVELS[_find_level_index("4-17")]
	var level_4_18 = Defs.LEVELS[_find_level_index("4-18")]
	passed = _assert_true(String(level_4_16.get("terrain", "")) == "fog", "4-16 should stay inside the normal fog battlefield") and passed
	passed = _assert_true(not bool(level_4_16.get("boss_level", false)), "4-16 should remain a high-pressure mainline stage instead of a boss branch") and passed
	passed = _assert_true(String(level_4_17.get("terrain", "")) == "clear_backyard", "4-17 should use the no-fog backyard terrain") and passed
	passed = _assert_true(String(level_4_17.get("mode", "")) == "conveyor", "4-17 should be a conveyor special stage") and passed
	passed = _assert_true(not bool(level_4_17.get("boss_level", false)), "4-17 should be a special conveyor gauntlet instead of a boss stage") and passed
	passed = _assert_true(String(level_4_18.get("terrain", "")) == "fog", "4-18 should return to the normal fog battlefield") and passed
	passed = _assert_true(String(level_4_18.get("mode", "")) == "conveyor", "4-18 should be a conveyor boss stage") and passed
	passed = _assert_true(bool(level_4_18.get("boss_level", false)), "4-18 should be marked as the fog-world boss stage") and passed
	return passed


func _test_fog_endgame_map_nodes_do_not_overlap() -> bool:
	var late_ids = ["4-14", "4-15", "4-16", "4-17", "4-18"]
	var nodes := {}
	var passed := true
	for level_id in late_ids:
		var level_index = _find_level_index(level_id)
		passed = _assert_true(level_index != -1, "expected %s to exist before checking node layout" % level_id) and passed
		if level_index != -1:
			nodes[level_id] = Vector2(Defs.LEVELS[level_index].get("node_pos", Vector2.ZERO))
	if not passed:
		return false
	var critical_pairs = [
		["4-15", "4-17"],
		["4-14", "4-18"],
		["4-17", "4-18"],
	]
	for pair in critical_pairs:
		var a = String(pair[0])
		var b = String(pair[1])
		var distance = Vector2(nodes[a]).distance_to(Vector2(nodes[b]))
		passed = _assert_true(distance >= 96.0, "%s and %s node positions should stay visually separated on the fog map" % [a, b]) and passed
	return passed


func _test_fog_units_have_runtime_definitions() -> bool:
	var passed := true
	for plant_kind in ["sea_shroom", "plantern", "cactus", "blover", "split_pea", "starfruit", "pumpkin", "magnet_shroom", "mist_orchid", "anchor_fern", "glowvine", "brine_pot", "storm_reed", "moonforge"]:
		passed = _assert_true(Defs.PLANTS.has(plant_kind), "%s should exist in plant definitions" % plant_kind) and passed
	for zombie_kind in ["balloon_zombie", "digger_zombie", "pogo_zombie", "jack_in_the_box_zombie", "squash_zombie", "excavator_zombie", "barrel_screen_zombie", "tornado_zombie", "wolf_knight_zombie", "fog_boss"]:
		passed = _assert_true(Defs.ZOMBIES.has(zombie_kind), "%s should exist in zombie definitions" % zombie_kind) and passed
	return passed


func _test_fog_world_map_title_is_not_day_adventure() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_map_mode_title_for_world"), "expected map title helper to exist for world-specific map labels")
	if passed:
		passed = _assert_true(String(game.call("_map_mode_title_for_world", "fog")) == "浓雾冒险", "fog world map title should display as 浓雾冒险 instead of 白天冒险") and passed
		passed = _assert_true(String(game.call("_map_mode_title_for_world", "pool")) == "泳池冒险", "pool world map title should use its own world label") and passed
		passed = _assert_true(String(game.call("_map_mode_title_for_world", "night")) == "夜晚冒险", "night world map title should stay unchanged") and passed
	_free_game(game)
	return passed


func _begin_fog_game(level_id: String) -> Control:
	var game = _make_game()
	var level_index = _find_level_index(level_id)
	if level_index != -1:
		game.call("_begin_level", level_index, [])
	return game


func _test_fog_cells_start_hidden_on_the_right_side() -> bool:
	var game = _begin_fog_game("4-3")
	if not _assert_true(game.has_method("_is_cell_revealed"), "expected fog reveal helper to exist"):
		_free_game(game)
		return false
	var passed = _assert_true(bool(game.call("_is_cell_revealed", 2, 1)), "near-left cells should start visible in fog levels") \
		and _assert_true(not bool(game.call("_is_cell_revealed", 2, 8)), "far-right cells should start hidden by fog")
	_free_game(game)
	return passed


func _test_plantern_reveals_a_persistent_radius() -> bool:
	var game = _begin_fog_game("4-3")
	if not _assert_true(game.has_method("_refresh_fog_visibility_state"), "expected fog refresh helper to exist"):
		_free_game(game)
		return false
	game.grid[2][5] = game._create_plant("plantern", 2, 5)
	game.call("_refresh_fog_visibility_state")
	var passed = _assert_true(bool(game.call("_is_cell_revealed", 2, 7)), "plantern should reveal nearby fogged cells") \
		and _assert_true(bool(game.call("_is_cell_revealed", 1, 6)), "plantern reveal should extend in a radius, not only straight ahead")
	_free_game(game)
	return passed


func _test_sea_shroom_is_water_only() -> bool:
	var game = _begin_fog_game("4-1")
	var water_ok = String(game.call("_placement_error", "sea_shroom", 2, 2)) == ""
	var land_blocked = String(game.call("_placement_error", "sea_shroom", 1, 2)) != ""
	var passed = _assert_true(water_ok, "sea_shroom should be placeable directly on water cells") \
		and _assert_true(land_blocked, "sea_shroom should not be placeable on land cells")
	_free_game(game)
	return passed


func _test_cactus_can_pop_balloon_zombies() -> bool:
	var game = _begin_fog_game("4-2")
	var row := 2
	var col := 2
	var plant = game._create_plant("cactus", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("balloon_zombie", row, game._cell_center(row, 6).x)
	for _step in range(24):
		game._update_plants(0.12)
		game._update_projectiles(0.08)
		if not bool(game.zombies[0].get("balloon_flying", true)):
			break
	var passed = _assert_true(not bool(game.zombies[0].get("balloon_flying", true)), "cactus shots should pop balloon zombies out of the air")
	_free_game(game)
	return passed


func _test_blover_removes_balloon_zombies() -> bool:
	var game = _begin_fog_game("4-3")
	game._spawn_zombie_at("balloon_zombie", 2, game._cell_center(2, 6).x)
	game.grid[2][2] = game._create_plant("blover", 2, 2)
	game._update_plants(0.12)
	var passed = _assert_true(game.zombies.is_empty(), "blover should blow balloon zombies off the lawn when it activates")
	_free_game(game)
	return passed


func _test_blover_temporarily_clears_all_fog() -> bool:
	var game = _begin_fog_game("4-3")
	if not _assert_true(game.has_method("_trigger_blover_fog_clear"), "expected blover fog-clear helper to exist"):
		_free_game(game)
		return false
	var hidden_before = not bool(game.call("_is_cell_revealed", 2, 8))
	game.call("_trigger_blover_fog_clear")
	var visible_during = bool(game.call("_is_cell_revealed", 2, 8))
	game.call("_update_fog_state", 6.0)
	var hidden_after = not bool(game.call("_is_cell_revealed", 2, 8))
	var passed = _assert_true(hidden_before, "right-edge cells should begin hidden before Blover is used") \
		and _assert_true(visible_during, "Blover should temporarily clear fog across the whole board") \
		and _assert_true(hidden_after, "fog should reform after the Blover clear window ends")
	_free_game(game)
	return passed


func _test_fog_plant_food_activation_matrix() -> bool:
	var game = _begin_fog_game("4-8")
	var scenarios = [
		{
			"kind": "sea_shroom",
			"row": 2,
			"col": 1,
			"spawns": [{"kind": "ducky_tube", "row": 2, "col": 6}],
		},
		{
			"kind": "cactus",
			"row": 1,
			"col": 1,
			"spawns": [{"kind": "balloon_zombie", "row": 1, "col": 7}],
		},
		{
			"kind": "blover",
			"row": 0,
			"col": 1,
			"spawns": [{"kind": "balloon_zombie", "row": 0, "col": 7}],
		},
		{
			"kind": "split_pea",
			"row": 2,
			"col": 4,
			"spawns": [
				{"kind": "normal", "row": 2, "col": 1},
				{"kind": "normal", "row": 2, "col": 7},
			],
		},
	]
	var passed := true
	for scenario in scenarios:
		game.zombies.clear()
		for row in range(game.grid.size()):
			for col in range(game.grid[row].size()):
				game.grid[row][col] = null
		var row := int(scenario["row"])
		var col := int(scenario["col"])
		game.grid[row][col] = game._create_plant(String(scenario["kind"]), row, col)
		for spawn_data in scenario["spawns"]:
			game._spawn_zombie_at(String(spawn_data["kind"]), int(spawn_data["row"]), game._cell_center(int(spawn_data["row"]), int(spawn_data["col"])).x)
		passed = _assert_true(bool(game.call("_activate_plant_food", row, col)), "%s should support plant food activation" % String(scenario["kind"])) and passed
	_free_game(game)
	return passed


func _test_plantern_plant_food_reveals_full_board_temporarily() -> bool:
	var game = _begin_fog_game("4-7")
	var row := 2
	var col := 4
	game.grid[row][col] = game._create_plant("plantern", row, col)
	var hidden_before = not bool(game.call("_is_cell_revealed", 2, 8))
	var activated = bool(game.call("_activate_plant_food", row, col))
	var visible_during = bool(game.call("_is_cell_revealed", 2, 8))
	game.call("_update_fog_state", 9.0)
	var hidden_after = not bool(game.call("_is_cell_revealed", 2, 8))
	var passed = _assert_true(hidden_before, "plantern plant food should start from a hidden far-right cell") \
		and _assert_true(activated, "plantern plant food should activate successfully") \
		and _assert_true(visible_during, "plantern plant food should reveal the entire board temporarily") \
		and _assert_true(hidden_after, "plantern plant food reveal should expire after its timer")
	_free_game(game)
	return passed


func _test_starfruit_plant_food_spawns_extra_volley() -> bool:
	var game = _begin_fog_game("4-8")
	var row := 2
	var col := 4
	game.grid[row][col] = game._create_plant("starfruit", row, col)
	game._spawn_zombie_at("normal", row, game._cell_center(row, 7).x)
	var activated = bool(game.call("_activate_plant_food", row, col))
	game._update_plants(0.18)
	var passed = _assert_true(activated, "starfruit plant food should activate successfully") \
		and _assert_true(game.projectiles.size() >= 10, "starfruit plant food should fire a denser multi-direction volley than the base 5-shot attack")
	_free_game(game)
	return passed


func _test_magnet_shroom_plant_food_strips_all_metal_targets() -> bool:
	var game = _begin_fog_game("4-9")
	var row := 2
	var col := 3
	game.grid[row][col] = game._create_plant("magnet_shroom", row, col)
	game._spawn_zombie_at("screen_door", row, game._cell_center(row, 6).x)
	game._spawn_zombie_at("pogo_zombie", row, game._cell_center(row, 7).x)
	game._spawn_zombie_at("jack_in_the_box_zombie", row, game._cell_center(row, 8).x)
	var activated = bool(game.call("_activate_plant_food", row, col))
	var screen_door = game.zombies[0]
	var pogo = game.zombies[1]
	var jack = game.zombies[2]
	var passed = _assert_true(activated, "magnet shroom plant food should activate successfully") \
		and _assert_true(float(screen_door.get("shield_health", 1.0)) <= 0.0, "magnet shroom plant food should rip off metal shields in range") \
		and _assert_true(not bool(pogo.get("pogo_active", true)), "magnet shroom plant food should disable pogo sticks in range") \
		and _assert_true(not bool(jack.get("jack_armed", true)), "magnet shroom plant food should disarm jack-in-the-box zombies in range")
	_free_game(game)
	return passed


func _test_pumpkin_can_shell_existing_plant() -> bool:
	var game = _begin_fog_game("4-7")
	var row := 1
	var col := 3
	game.grid[row][col] = game._create_plant("peashooter", row, col)
	game.sun_points = 500
	game.card_cooldowns["pumpkin"] = 0.0
	game.selected_tool = "pumpkin"
	game._handle_board_click(Vector2i(row, col))
	var plant = game.grid[row][col]
	var passed = _assert_true(String(plant.get("kind", "")) == "peashooter", "placing pumpkin on an occupied tile should keep the underlying plant") \
		and _assert_true(float(plant.get("armor_health", 0.0)) >= float(Defs.PLANTS["pumpkin"]["shell_health"]), "pumpkin should add a protective shell to an existing plant instead of being blocked")
	_free_game(game)
	return passed


func _test_vasebreaker_stage_builds_hidden_vases() -> bool:
	var game = _begin_fog_game("4-5")
	var passed = _assert_true(game.get("vases").size() > 0, "4-5 should initialize vase data for the vasebreaker stage")
	_free_game(game)
	return passed


func _test_unopened_zombie_vases_block_vasebreaker_victory() -> bool:
	var game = _begin_fog_game("4-5")
	var passed = _assert_true(not bool(game.call("_can_finish_level_ignoring_obstacles")), "unopened zombie vases should keep vasebreaker from ending early")
	_free_game(game)
	return passed


func _test_storm_lightning_temporarily_reveals_the_board() -> bool:
	var game = _begin_fog_game("4-10")
	if not _assert_true(game.has_method("_trigger_storm_lightning_flash"), "expected storm lightning helper to exist"):
		_free_game(game)
		return false
	var hidden_before = not bool(game.call("_is_cell_revealed", 2, 8))
	game.call("_trigger_storm_lightning_flash")
	var visible_during = bool(game.call("_is_cell_revealed", 2, 8))
	game.call("_update_fog_state", 2.0)
	var hidden_after = not bool(game.call("_is_cell_revealed", 2, 8))
	var passed = _assert_true(hidden_before, "storm-fog cells should begin hidden before lightning flashes") \
		and _assert_true(visible_during, "storm lightning should temporarily reveal the entire board") \
		and _assert_true(hidden_after, "storm lightning should not permanently disable fog")
	_free_game(game)
	return passed
