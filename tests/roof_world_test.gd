extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const WorldData = preload("res://scripts/data/world_data.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_roof_world_metadata_exists() or failed
	failed = not _test_5x_levels_route_to_roof_world() or failed
	failed = not _test_roof_world_unlocks_after_4_18() or failed
	failed = not _test_roof_level_data_matches_original_unlock_rhythm() or failed
	failed = not _test_roof_extension_levels_exist() or failed
	failed = not _test_5_1_begins_with_front_flower_pots_and_roof_cleaners() or failed
	failed = not _test_5_5_begins_with_full_flower_pots() or failed
	failed = not _test_5_15_begins_with_full_flower_pots() or failed
	failed = not _test_roof_levels_reuse_all_previously_seen_non_boss_zombies() or failed
	failed = not _test_roof_units_have_runtime_definitions() or failed
	failed = not _test_roof_original_zombies_appear_in_almanac() or failed
	failed = not _test_roof_requires_flower_pot_support() or failed
	failed = not _test_coffee_bean_wakes_sleeping_roof_mushroom() or failed
	failed = not _test_roof_direct_fire_cannot_target_far_slope() or failed
	failed = not _test_cabbage_pult_can_target_far_roof_lane() or failed
	failed = not _test_bungee_steals_unprotected_plant_and_umbrella_blocks() or failed
	failed = not _test_ladder_zombie_marks_barrier_for_climb() or failed
	failed = not _test_catapult_targets_rightmost_plant_and_umbrella_blocks() or failed
	failed = not _test_garlic_redirects_zombies() or failed
	failed = not _test_gargantuar_throws_imp() or failed
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


func _make_roof_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "5-test", "terrain": "roof", "events": [], "row_count": 5}
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


func _begin_level(game: Control, level_id: String, chosen_cards: Array = []) -> int:
	var level_index = _find_level_index(level_id)
	if level_index != -1:
		game._begin_level(level_index, chosen_cards)
	return level_index


func _prepare_potted_plant(game: Control, kind: String, row: int, col: int) -> Dictionary:
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	var plant = game._create_plant(kind, row, col)
	game.grid[row][col] = plant
	return plant


func _test_roof_world_metadata_exists() -> bool:
	var roof_world = WorldData.by_key("roof")
	return _assert_true(String(roof_world.get("key", "")) == "roof", "expected roof world metadata to exist") \
		and _assert_true(String(roof_world.get("subtitle", "")) == "Adventure 5-1 ~ 5-17", "roof world subtitle should cover 5-1 to 5-17")


func _test_5x_levels_route_to_roof_world() -> bool:
	var game = _make_roof_game()
	var passed := true
	for level_id in ["5-1", "5-5", "5-10", "5-16", "5-17"]:
		passed = _assert_true(String(game.call("_world_key_for_level", {"id": level_id})) == "roof", "%s should route to roof world" % level_id) and passed
	_free_game(game)
	return passed


func _test_roof_world_unlocks_after_4_18() -> bool:
	var game = _make_roof_game()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	var index_4_18 = _find_level_index("4-18")
	var index_5_1 = _find_level_index("5-1")
	var passed = _assert_true(index_4_18 != -1, "expected 4-18 to exist for roof unlock checks") \
		and _assert_true(index_5_1 != -1, "expected 5-1 to exist for roof unlock checks")
	if passed:
		passed = _assert_true(not bool(game.call("_is_world_unlocked", "roof")), "roof world should stay locked before 4-18 is completed") and passed
		game.completed_levels[index_4_18] = true
		passed = _assert_true(bool(game.call("_is_world_unlocked", "roof")), "roof world should unlock after 4-18 is completed") and passed
	_free_game(game)
	return passed


func _test_roof_level_data_matches_original_unlock_rhythm() -> bool:
	var expected_unlocks = {
		"5-1": "flower_pot",
		"5-2": "kernel_pult",
		"5-3": "coffee_bean",
		"5-4": "",
		"5-5": "garlic",
		"5-6": "umbrella_leaf",
		"5-7": "marigold",
		"5-8": "melon_pult",
		"5-9": "",
		"5-10": "origami_blossom",
		"5-11": "chimney_pepper",
		"5-12": "tesla_tulip",
		"5-13": "brick_guard",
		"5-14": "signal_ivy",
		"5-15": "roof_vane",
		"5-16": "skylight_melon",
		"5-17": "",
	}
	var passed := true
	for number in range(1, 18):
		var level_id = "5-%d" % number
		var level_index = _find_level_index(level_id)
		passed = _assert_true(level_index != -1, "expected %s to exist in roof progression" % level_id) and passed
		if level_index == -1:
			continue
		var level = Defs.LEVELS[level_index]
		passed = _assert_true(String(level.get("terrain", "")) == "roof", "%s should use roof terrain" % level_id) and passed
		passed = _assert_true(int(level.get("row_count", 0)) == 5, "%s should use a 5-row roof board" % level_id) and passed
		passed = _assert_true(String(level.get("unlock_plant", "")) == String(expected_unlocks[level_id]), "%s should unlock %s" % [level_id, expected_unlocks[level_id]]) and passed
		if level_id == "5-1":
			passed = _assert_true(level.get("available_plants", []).has("cabbage_pult"), "5-1 should already provide cabbage_pult at the start of the roof world") and passed
	var level_5_5 = Defs.LEVELS[_find_level_index("5-5")]
	passed = _assert_true(String(level_5_5.get("mode", "")) == "conveyor", "5-5 should be the roof conveyor special stage") and passed
	var level_5_15 = Defs.LEVELS[_find_level_index("5-15")]
	passed = _assert_true(String(level_5_15.get("mode", "")) == "conveyor", "5-15 should be the roof extension conveyor special stage") and passed
	var level_5_17 = Defs.LEVELS[_find_level_index("5-17")]
	passed = _assert_true(String(level_5_17.get("mode", "")) == "conveyor", "5-17 should be the roof boss conveyor stage") and passed
	passed = _assert_true(bool(level_5_17.get("boss_level", false)), "5-17 should be marked as the roof-world boss stage") and passed
	passed = _assert_true(not level_5_17.get("available_plants", []).has("coffee_bean"), "5-17 should not offer coffee_bean in the boss conveyor pool") and passed
	passed = _assert_true(not level_5_17.get("conveyor_plants", []).has("coffee_bean"), "5-17 conveyor drops should not contain coffee_bean") and passed
	return passed


func _test_roof_extension_levels_exist() -> bool:
	var passed := true
	for level_id in ["5-10", "5-11", "5-12", "5-13", "5-14", "5-15", "5-16", "5-17"]:
		var level_index = _find_level_index(level_id)
		passed = _assert_true(level_index != -1, "expected %s to exist in the extended roof world" % level_id) and passed
		if level_index == -1:
			continue
		var level = Defs.LEVELS[level_index]
		passed = _assert_true(String(level.get("terrain", "")) == "roof", "%s should stay on roof terrain" % level_id) and passed
		passed = _assert_true(int(level.get("row_count", 0)) == 5, "%s should use the 5-row roof board" % level_id) and passed
	return passed


func _test_5_1_begins_with_front_flower_pots_and_roof_cleaners() -> bool:
	var game = _make_roof_game()
	var level_index = _begin_level(game, "5-1", ["cabbage_pult"])
	var passed = _assert_true(level_index != -1, "expected 5-1 to exist for roof setup checks")
	if passed:
		for row in range(5):
			for col in range(5):
				var support = game.support_grid[row][col]
				passed = _assert_true(support != null and String(support.get("kind", "")) == "flower_pot", "5-1 should begin with preplaced flower pots on the first five roof columns") and passed
		for row in range(5):
			passed = _assert_true(String(game.mowers[row].get("kind", "")) == "roof_cleaner", "roof rows should initialize with roof cleaners instead of lawn mowers") and passed
	_free_game(game)
	return passed


func _test_5_5_begins_with_full_flower_pots() -> bool:
	var game = _make_roof_game()
	var level_index = _begin_level(game, "5-5", [])
	var passed = _assert_true(level_index != -1, "expected 5-5 to exist for full flower pot setup checks")
	if passed:
		for row in range(5):
			for col in range(9):
				var support = game.support_grid[row][col]
				passed = _assert_true(support != null and String(support.get("kind", "")) == "flower_pot", "5-5 should begin with flower pots covering the full roof board") and passed
	_free_game(game)
	return passed


func _test_5_15_begins_with_full_flower_pots() -> bool:
	var game = _make_roof_game()
	var level_index = _begin_level(game, "5-15", [])
	var passed = _assert_true(level_index != -1, "expected 5-15 to exist for full flower pot setup checks")
	if passed:
		for row in range(5):
			for col in range(9):
				var support = game.support_grid[row][col]
				passed = _assert_true(support != null and String(support.get("kind", "")) == "flower_pot", "5-15 should begin with flower pots covering the full roof board") and passed
	_free_game(game)
	return passed


func _test_roof_levels_reuse_all_previously_seen_non_boss_zombies() -> bool:
	var roof_start_index = _find_level_index("5-1")
	var passed = _assert_true(roof_start_index != -1, "expected 5-1 to exist before checking roof zombie coverage")
	if not passed:
		return false
	var prior_seen := {}
	var roof_seen := {}
	for i in range(roof_start_index):
		for event in Defs.LEVELS[i].get("events", []):
			var kind = String(event.get("kind", ""))
			if kind == "" or not Defs.ZOMBIES.has(kind):
				continue
			if bool(Defs.ZOMBIES[kind].get("boss", false)):
				continue
			prior_seen[kind] = true
	for i in range(roof_start_index, Defs.LEVELS.size()):
		var level = Defs.LEVELS[i]
		if String(level.get("terrain", "")) != "roof":
			continue
		for event in level.get("events", []):
			var kind = String(event.get("kind", ""))
			if kind == "":
				continue
			roof_seen[kind] = true
	for kind in prior_seen.keys():
		passed = _assert_true(roof_seen.has(kind), "roof levels should be able to revisit previously seen zombie kind %s" % kind) and passed
	return passed


func _test_roof_units_have_runtime_definitions() -> bool:
	var passed := true
	for plant_kind in ["cabbage_pult", "flower_pot", "kernel_pult", "coffee_bean", "garlic", "umbrella_leaf", "marigold", "melon_pult", "origami_blossom", "chimney_pepper", "tesla_tulip", "brick_guard", "signal_ivy", "roof_vane", "skylight_melon"]:
		passed = _assert_true(Defs.PLANTS.has(plant_kind), "%s should exist in plant definitions" % plant_kind) and passed
	for zombie_kind in ["bungee_zombie", "ladder_zombie", "catapult_zombie", "gargantuar", "imp", "kite_zombie", "hive_zombie", "turret_zombie", "programmer_zombie", "roof_boss"]:
		passed = _assert_true(Defs.ZOMBIES.has(zombie_kind), "%s should exist in zombie definitions" % zombie_kind) and passed
	return passed


func _test_roof_original_zombies_appear_in_almanac() -> bool:
	var game = _make_roof_game()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = true
	var entries: Array = game.call("_visible_almanac_zombies")
	var passed := true
	for zombie_kind in ["bungee_zombie", "ladder_zombie", "catapult_zombie", "gargantuar", "imp"]:
		passed = _assert_true(entries.has(zombie_kind), "%s should appear in the zombie almanac once roof content is unlocked" % zombie_kind) and passed
	_free_game(game)
	return passed


func _test_roof_requires_flower_pot_support() -> bool:
	var game = _make_roof_game()
	var passed = _assert_true(game._placement_error("peashooter", 2, 3).find("花盆") != -1, "roof land should require a flower pot before planting a normal plant") \
		and _assert_true(game._placement_error("flower_pot", 2, 3) == "", "flower pot should be placeable directly on roof tiles")
	game.support_grid[2][3] = game._create_plant("flower_pot", 2, 3)
	passed = _assert_true(game._placement_error("peashooter", 2, 3) == "", "a flower pot should allow normal plants to be planted on roof tiles") and passed
	_free_game(game)
	return passed


func _test_coffee_bean_wakes_sleeping_roof_mushroom() -> bool:
	var game = _make_roof_game()
	_prepare_potted_plant(game, "fume_shroom", 2, 3)
	var before_sleep = float(game.grid[2][3].get("sleep_timer", 0.0))
	game.selected_tool = "coffee_bean"
	game.sun_points = 999
	game.card_cooldowns["coffee_bean"] = 0.0
	game._handle_board_click(Vector2i(2, 3))
	var after_sleep = float(game.grid[2][3].get("sleep_timer", 0.0))
	var passed = _assert_true(before_sleep > 999.0, "roof mushrooms should begin asleep during daytime roof stages") \
		and _assert_true(after_sleep <= 0.0, "coffee bean should wake a sleeping mushroom immediately on roof levels")
	_free_game(game)
	return passed


func _test_roof_direct_fire_cannot_target_far_slope() -> bool:
	var game = _make_roof_game()
	_prepare_potted_plant(game, "peashooter", 2, 0)
	game._spawn_zombie_at("normal", 2, game._cell_center(2, 7).x)
	var passed = _assert_true(not bool(game._has_zombie_ahead(2, game._cell_center(2, 0).x)), "direct-fire plants on roof should not target zombies too far up the roof slope")
	_free_game(game)
	return passed


func _test_cabbage_pult_can_target_far_roof_lane() -> bool:
	var game = _make_roof_game()
	var plant = _prepare_potted_plant(game, "cabbage_pult", 2, 0)
	plant["shot_cooldown"] = 0.0
	game.grid[2][0] = plant
	game._spawn_zombie_at("normal", 2, game._cell_center(2, 7).x)
	game._update_plants(0.2)
	var found_cabbage := false
	for projectile in game.projectiles:
		if String(projectile.get("kind", "")) == "cabbage":
			found_cabbage = true
			break
	var passed = _assert_true(found_cabbage, "cabbage_pult should still fire at far roof targets that straight shooters cannot reach")
	_free_game(game)
	return passed


func _test_ladder_zombie_marks_barrier_for_climb() -> bool:
	var game = _make_roof_game()
	_prepare_potted_plant(game, "tallnut", 2, 4)
	game._spawn_zombie_at("ladder_zombie", 2, game._cell_center(2, 4).x + 12.0)
	var ladder = game.zombies[0]
	ladder["special_pause_timer"] = 0.0
	game.zombies[0] = ladder
	for _step in range(4):
		game._update_zombies(0.15)
	var plant = game.grid[2][4]
	var passed = _assert_true(plant != null and bool(plant.get("laddered", false)), "ladder zombie should place a ladder onto a blocking roof barrier") \
		and _assert_true(float(game.zombies[0].get("shield_health", 0.0)) <= 0.0, "ladder zombie should spend its ladder shield after placing it")
	_free_game(game)
	return passed


func _test_bungee_steals_unprotected_plant_and_umbrella_blocks() -> bool:
	var unprotected = _make_roof_game()
	_prepare_potted_plant(unprotected, "peashooter", 2, 4)
	unprotected._spawn_zombie_at("bungee_zombie", 2, unprotected._cell_center(2, 4).x)
	var bungee = unprotected.zombies[0]
	bungee["bungee_target_row"] = 2
	bungee["bungee_target_col"] = 4
	bungee["special_pause_timer"] = 0.0
	bungee["bungee_timer"] = 0.0
	unprotected.zombies[0] = bungee
	unprotected._update_zombies(0.2)
	var stolen = unprotected._targetable_plant_at(2, 4) == null
	_free_game(unprotected)

	var protected_game = _make_roof_game()
	_prepare_potted_plant(protected_game, "peashooter", 2, 4)
	_prepare_potted_plant(protected_game, "umbrella_leaf", 2, 3)
	protected_game._spawn_zombie_at("bungee_zombie", 2, protected_game._cell_center(2, 4).x)
	var protected_bungee = protected_game.zombies[0]
	protected_bungee["bungee_target_row"] = 2
	protected_bungee["bungee_target_col"] = 4
	protected_bungee["special_pause_timer"] = 0.0
	protected_bungee["bungee_timer"] = 0.0
	protected_game.zombies[0] = protected_bungee
	protected_game._update_zombies(0.2)
	var saved = protected_game._targetable_plant_at(2, 4) != null
	_free_game(protected_game)
	return _assert_true(stolen, "bungee zombie should steal an unprotected roof plant") \
		and _assert_true(saved, "umbrella leaf should block nearby bungee thefts on the roof")


func _test_catapult_targets_rightmost_plant_and_umbrella_blocks() -> bool:
	var game = _make_roof_game()
	game.support_grid[2][2] = game._create_plant("flower_pot", 2, 2)
	game.grid[2][2] = game._create_plant("peashooter", 2, 2)
	game.support_grid[2][6] = game._create_plant("flower_pot", 2, 6)
	game.grid[2][6] = game._create_plant("peashooter", 2, 6)
	game._spawn_zombie_at("catapult_zombie", 2, game.BOARD_ORIGIN.x + game.board_size.x - 20.0)
	var catapult = game.zombies[0]
	catapult["catapult_cooldown"] = 0.0
	game.zombies[0] = catapult
	var left_before = float(game.grid[2][2]["health"])
	var right_before = float(game.grid[2][6]["health"])
	for _step in range(10):
		game._update_zombies(0.1)
		game._update_projectiles(0.1)
	var left_after = float(game.grid[2][2]["health"])
	var right_after = float(game.grid[2][6]["health"])
	var passed = _assert_true(left_after < left_before, "catapult zombie should target the plant closest to the house first") \
		and _assert_true(is_equal_approx(right_after, right_before), "catapult zombie should not skip the back-most roof plant to hit a nearer front plant")
	_free_game(game)

	var blocked = _make_roof_game()
	_prepare_potted_plant(blocked, "peashooter", 2, 6)
	_prepare_potted_plant(blocked, "umbrella_leaf", 2, 5)
	blocked._spawn_zombie_at("catapult_zombie", 2, blocked.BOARD_ORIGIN.x + blocked.board_size.x - 20.0)
	var blocked_catapult = blocked.zombies[0]
	blocked_catapult["catapult_cooldown"] = 0.0
	blocked.zombies[0] = blocked_catapult
	var guarded_before = float(blocked.grid[2][6]["health"])
	for _step in range(10):
		blocked._update_zombies(0.1)
		blocked._update_projectiles(0.1)
	var guarded_after = float(blocked.grid[2][6]["health"])
	var blocked_passed = _assert_true(is_equal_approx(guarded_after, guarded_before), "umbrella leaf should block nearby catapult shots")
	_free_game(blocked)
	return passed and blocked_passed


func _test_garlic_redirects_zombies() -> bool:
	var game = _make_roof_game()
	_prepare_potted_plant(game, "garlic", 2, 4)
	game._spawn_zombie_at("normal", 2, game._cell_center(2, 4).x)
	game._update_zombies(0.2)
	var new_row = int(game.zombies[0].get("row", 2))
	var passed = _assert_true(new_row != 2, "garlic should redirect a biting zombie into a neighboring lane on roof levels")
	_free_game(game)
	return passed


func _test_gargantuar_throws_imp() -> bool:
	var game = _make_roof_game()
	game._spawn_zombie_at("gargantuar", 2, game._cell_center(2, 7).x)
	var garg = game.zombies[0]
	var garg_data = Dictionary(Defs.ZOMBIES.get("gargantuar", {}))
	garg["health"] = float(garg_data.get("health", 0.0)) * 0.45
	garg["imp_throw_cooldown"] = 0.0
	game.zombies[0] = garg
	game._update_zombies(0.2)
	var found_imp := false
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) == "imp":
			found_imp = true
			break
	var passed = _assert_true(found_imp, "gargantuar should throw an imp once it reaches its throw condition")
	_free_game(game)
	return passed
