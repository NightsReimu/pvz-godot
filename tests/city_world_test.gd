extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const WorldData = preload("res://scripts/data/world_data.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_city_world_metadata_exists() or failed
	failed = not _test_6x_levels_route_to_city_world() or failed
	failed = not _test_city_world_unlocks_after_5_17() or failed
	failed = not _test_city_level_data_matches_unlock_rhythm() or failed
	failed = not _test_city_blizzard_branch_data_exists() or failed
	failed = not _test_city_tile_and_rail_require_flower_pot_support() or failed
	failed = not _test_begin_city_levels_initializes_runtime_state() or failed
	failed = not _test_nether_shroom_summons_hypnotized_buckethead_in_its_column() or failed
	failed = not _test_mech_zombie_can_die_from_normal_damage() or failed
	failed = not _test_city_almanac_stats_cover_new_plants_and_zombies() or failed
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
	game.current_level = {"id": "6-test", "terrain": "city", "events": [], "row_count": 5}
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


func _test_city_world_metadata_exists() -> bool:
	var city_world = WorldData.by_key("city")
	return _assert_true(String(city_world.get("key", "")) == "city", "expected city world metadata to exist") \
		and _assert_true(String(city_world.get("title", "")) == "城市世界", "city world title should be 城市世界") \
		and _assert_true(String(city_world.get("subtitle", "")) == "Adventure 6-1 ~ 6-18", "city world subtitle should cover 6-1 to 6-18")


func _test_6x_levels_route_to_city_world() -> bool:
	var game = _make_game()
	var passed := true
	for level_id in ["6-1", "6-5", "6-9", "6-10", "6-11", "6-14", "6-18"]:
		passed = _assert_true(String(game.call("_world_key_for_level", {"id": level_id})) == "city", "%s should route to city world" % level_id) and passed
	_free_game(game)
	return passed


func _test_city_world_unlocks_after_5_17() -> bool:
	var game = _make_game()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	var index_5_17 = _find_level_index("5-17")
	var index_6_1 = _find_level_index("6-1")
	var passed = _assert_true(index_5_17 != -1, "expected 5-17 to exist for city unlock checks") \
		and _assert_true(index_6_1 != -1, "expected 6-1 to exist for city unlock checks")
	if passed:
		passed = _assert_true(not bool(game.call("_is_world_unlocked", "city")), "city world should stay locked before 5-17 is completed") and passed
		game.completed_levels[index_5_17] = true
		passed = _assert_true(bool(game.call("_is_world_unlocked", "city")), "city world should unlock after 5-17 is completed") and passed
	_free_game(game)
	return passed


func _test_city_level_data_matches_unlock_rhythm() -> bool:
	var expected_unlocks = {
		"6-1": "heather_shooter",
		"6-2": "leyline",
		"6-3": "holo_nut",
		"6-4": "healing_gourd",
		"6-5": "mango_bowling",
		"6-6": "snow_bloom",
		"6-7": "cluster_boomerang",
		"6-8": "glitch_walnut",
		"6-9": "",
		"6-10": "",
		"6-11": "nether_shroom",
		"6-12": "seraph_flower",
		"6-13": "magma_stream",
		"6-14": "orange_bloom",
		"6-15": "hive_flower",
		"6-16": "mamba_tree",
		"6-17": "chambord_sniper",
		"6-18": "dream_disc",
	}
	var passed := true
	for level_number in range(1, 19):
		var level_id = "6-%d" % level_number
		var level_index = _find_level_index(level_id)
		passed = _assert_true(level_index != -1, "expected %s to exist in city progression" % level_id) and passed
		if level_index == -1:
			continue
		var level = Defs.LEVELS[level_index]
		passed = _assert_true(String(level.get("terrain", "")) == "city", "%s should use city terrain" % level_id) and passed
		passed = _assert_true(int(level.get("row_count", 0)) == 5, "%s should use a 5-row city board" % level_id) and passed
		passed = _assert_true(String(level.get("unlock_plant", "")) == String(expected_unlocks[level_id]), "%s should unlock %s" % [level_id, expected_unlocks[level_id]]) and passed
	var level_6_10 = Defs.LEVELS[_find_level_index("6-10")]
	passed = _assert_true(String(level_6_10.get("mode", "")) == "conveyor", "6-10 should be the city conveyor special stage") and passed
	passed = _assert_true(level_6_10.get("available_plants", []).has("flower_pot"), "6-10 should include flower pots because city tiles require support") and passed
	return passed


func _test_city_blizzard_branch_data_exists() -> bool:
	var passed := true
	for level_number in range(11, 19):
		var level_id = "6-%d" % level_number
		var level_index = _find_level_index(level_id)
		passed = _assert_true(level_index != -1, "expected %s to exist before checking blizzard branch data" % level_id) and passed
		if level_index == -1:
			continue
		var level = Defs.LEVELS[level_index]
		var wave_count := 0
		for event in level.get("events", []):
			if bool(Dictionary(event).get("wave", false)):
				wave_count += 1
		passed = _assert_true(String(level.get("city_weather", "")) == "blizzard", "%s should enable the city blizzard weather" % level_id) and passed
		passed = _assert_true(wave_count >= 5, "%s should schedule at least 5 waves" % level_id) and passed
	return passed


func _test_city_tile_and_rail_require_flower_pot_support() -> bool:
	var game = _make_game()
	game.cell_terrain_mask = [
		["land", "city_tile", "rail", "snowfield", "land", "land", "land", "land", "land"],
		["land", "land", "land", "land", "land", "land", "land", "land", "land"],
		["land", "land", "land", "land", "land", "land", "land", "land", "land"],
		["land", "land", "land", "land", "land", "land", "land", "land", "land"],
		["land", "land", "land", "land", "land", "land", "land", "land", "land"],
		["void", "void", "void", "void", "void", "void", "void", "void", "void"],
	]
	var passed = _assert_true(String(game.call("_placement_error", "peashooter", 0, 0)) == "", "land cells should allow direct planting in the city world") \
		and _assert_true(String(game.call("_placement_error", "peashooter", 0, 1)).find("花盆") != -1, "city tiles should require flower pot support") \
		and _assert_true(String(game.call("_placement_error", "peashooter", 0, 2)).find("花盆") != -1, "rail cells should require flower pot support") \
		and _assert_true(String(game.call("_placement_error", "peashooter", 0, 3)).find("花盆") != -1, "snowfield cells should require flower pot support for normal plants")
	_free_game(game)
	return passed


func _test_begin_city_levels_initializes_runtime_state() -> bool:
	var passed := true
	var rail_game = _make_game()
	var level_6_7 = _find_level_index("6-7")
	passed = _assert_true(level_6_7 != -1, "expected 6-7 to exist for runtime initialization checks") and passed
	if level_6_7 != -1:
		rail_game._begin_level(level_6_7, ["flower_pot", "heather_shooter", "leyline", "holo_nut", "healing_gourd", "mango_bowling"])
		passed = _assert_true(String(rail_game.current_level.get("id", "")) == "6-7", "runtime should begin on 6-7") and passed
		passed = _assert_true(String(rail_game.cell_terrain_mask[0][3]) == "rail", "6-7 should materialize rail cells during runtime setup") and passed
	_free_game(rail_game)

	var conveyor_game = _make_game()
	var level_6_10 = _find_level_index("6-10")
	passed = _assert_true(level_6_10 != -1, "expected 6-10 to exist for conveyor initialization checks") and passed
	if level_6_10 != -1:
		conveyor_game._begin_level(level_6_10, [])
		passed = _assert_true(bool(conveyor_game.call("_is_conveyor_level")), "6-10 should initialize as a conveyor level") and passed
		passed = _assert_true(conveyor_game.conveyor_source_cards.has("flower_pot"), "6-10 runtime conveyor pool should contain flower pots for city supports") and passed
		passed = _assert_true(conveyor_game.active_cards[0] != "", "6-10 should prefill conveyor slots when the level begins") and passed
		passed = _assert_true(String(conveyor_game.cell_terrain_mask[0][1]) == "city_tile", "6-10 should materialize city tile cells during runtime setup") and passed
	_free_game(conveyor_game)
	return passed


func _test_nether_shroom_summons_hypnotized_buckethead_in_its_column() -> bool:
	var game = _make_game()
	var row := 2
	var col := 3
	var plant = game._create_plant("nether_shroom", row, col)
	plant["support_timer"] = 0.0
	game.grid[row][col] = plant
	game._update_plants(0.1)
	var expected_x = game._cell_center(row, col).x
	var summoned: Dictionary = {}
	var found := false
	for zombie_variant in game.zombies:
		var zombie = Dictionary(zombie_variant)
		if String(zombie.get("kind", "")) != "buckethead":
			continue
		if not bool(zombie.get("hypnotized", false)):
			continue
		summoned = zombie
		found = true
		break
	var passed = _assert_true(found, "nether shroom should summon a hypnotized buckethead when its timer is ready")
	if passed:
		passed = _assert_true(absf(float(summoned.get("x", -9999.0)) - expected_x) <= 28.0, "nether shroom summons should appear in the same column as the plant instead of the far-right spawn line") and passed
	_free_game(game)
	return passed


func _test_mech_zombie_can_die_from_normal_damage() -> bool:
	var game = _make_game()
	var row := 2
	var spawn_x = game._cell_center(row, 6).x
	game._spawn_zombie_at("mech_zombie", row, spawn_x)
	var passed = _assert_true(game.zombies.size() == 1, "expected a mech zombie to spawn for death-behavior checks")
	if passed:
		var zombie = game.zombies[0]
		zombie = game._apply_zombie_damage(zombie, float(zombie.get("health", 0.0)) + 500.0, 0.18)
		game.zombies[0] = zombie
		game._cleanup_dead_zombies()
		passed = _assert_true(game.zombies.is_empty(), "mech zombie should die from normal damage once its health is depleted instead of requiring ash hits") and passed
	_free_game(game)
	return passed


func _test_city_almanac_stats_cover_new_plants_and_zombies() -> bool:
	var game = _make_game()
	var passed := true
	var heather_stats: Array = game.call("_plant_almanac_stats", "heather_shooter")
	var glitch_stats: Array = game.call("_plant_almanac_stats", "glitch_walnut")
	var nether_shroom_stats: Array = game.call("_plant_almanac_stats", "nether_shroom")
	var dream_disc_stats: Array = game.call("_plant_almanac_stats", "dream_disc")
	var subway_stats: Array = game.call("_zombie_almanac_stats", "subway_zombie")
	var router_stats: Array = game.call("_zombie_almanac_stats", "router_zombie")
	var mech_stats: Array = game.call("_zombie_almanac_stats", "mech_zombie")
	var wither_stats: Array = game.call("_zombie_almanac_stats", "wither_zombie")
	passed = _assert_true(heather_stats.any(func(line): return String(line).find("腐蚀") != -1), "heather shooter almanac should mention corrosion output") and passed
	passed = _assert_true(glitch_stats.any(func(line): return String(line).find("机械") != -1 or String(line).find("异常") != -1), "glitch walnut almanac should mention random anomaly or mechanical disruption") and passed
	passed = _assert_true(nether_shroom_stats.any(func(line): return String(line).find("魅惑") != -1), "nether shroom almanac should mention summoning hypnotized bucket zombies") and passed
	passed = _assert_true(dream_disc_stats.any(func(line): return String(line).find("睡") != -1), "dream disc almanac should mention sleep control") and passed
	passed = _assert_true(subway_stats.any(func(line): return String(line).find("轨") != -1), "subway zombie almanac should mention rail rushing") and passed
	passed = _assert_true(router_stats.any(func(line): return String(line).find("增益") != -1), "router zombie almanac should mention team aura buff") and passed
	passed = _assert_true(mech_stats.any(func(line): return String(line).find("灰烬") != -1), "mech zombie almanac should mention needing ash damage to finish it") and passed
	passed = _assert_true(wither_stats.any(func(line): return String(line).find("腐化") != -1), "wither zombie almanac should mention corrupting the ground on death") and passed
	_free_game(game)
	return passed
