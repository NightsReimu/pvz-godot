extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_peashooter_click_ultimate_uses_its_own_plant_food_pattern() or failed
	failed = not _test_amber_shooter_click_ultimate_spawns_dedicated_amber_barrage() or failed
	failed = not _test_moonforge_click_ultimate_launches_moonfall_projectiles() or failed
	failed = not _test_flower_pot_click_ultimate_creates_supports_instead_of_generic_heal() or failed
	failed = not _test_pepper_mortar_click_ultimate_creates_front_fire_wall() or failed
	failed = not _test_pulse_bulb_click_ultimate_freezes_a_5x5_area() or failed
	failed = not _test_amber_shooter_plant_food_uses_dedicated_amber_projectiles() or failed
	failed = not _test_pepper_mortar_plant_food_creates_front_target_3x3_fire_zone() or failed
	failed = not _test_pulse_bulb_plant_food_pushes_nearby_zombies_in_5x5() or failed
	failed = not _test_prism_grass_click_ultimate_hits_three_lanes() or failed
	failed = not _test_lantern_bloom_click_ultimate_stuns_nearby_enemies() or failed
	failed = not _test_thunder_pine_click_ultimate_spawns_tracking_cloud() or failed
	failed = not _test_spikeweed_click_ultimate_pulls_row_targets_in_front() or failed
	failed = not _test_wind_orchid_click_ultimate_uses_dedicated_gust_effect() or failed
	failed = not _test_wind_orchid_plant_food_uses_dedicated_gust_effect() or failed
	failed = not _test_lotus_lancer_click_ultimate_spawns_converging_lotus_barrage() or failed
	failed = not _test_lotus_lancer_plant_food_matches_its_click_barrage() or failed
	failed = not _test_mirror_reed_click_ultimate_summons_sniper_support() or failed
	failed = not _test_magic_flower_click_ultimate_spawns_random_lane_barrage() or failed
	failed = not _test_tesla_tulip_click_ultimate_summons_model_y() or failed
	failed = not _test_brick_guard_click_ultimate_creates_column_wall() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_grid() -> Array:
	var result: Array = []
	for _row in range(6):
		var row_data: Array = []
		for _col in range(9):
			row_data.append(null)
		result.append(row_data)
	return result


func _make_game(terrain: String = "day") -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "test", "terrain": terrain, "events": [], "title": "test", "description": ""}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
	game.grid = _make_grid()
	game.support_grid = _make_grid()
	game.zombies = []
	game.weeds = []
	game.spears = []
	game.effects = []
	game.graves = []
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	game.call("_setup_cell_terrain_mask")
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


func _count_support_kind(game: Control, kind: String) -> int:
	var count := 0
	for row in range(game.ROWS):
		for col in range(game.COLS):
			var support = game.support_grid[row][col]
			if support != null and String(support.get("kind", "")) == kind:
				count += 1
	return count


func _count_effect_shape(game: Control, shape: String) -> int:
	var count := 0
	for effect_variant in game.effects:
		if String(Dictionary(effect_variant).get("shape", "")) == shape:
			count += 1
	return count


func _count_projectile_kind(game: Control, kind: String) -> int:
	var count := 0
	for projectile_variant in game.projectiles:
		if String(Dictionary(projectile_variant).get("kind", "")) == kind:
			count += 1
	return count


func _unique_projectile_kind_count(game: Control) -> int:
	var kinds := {}
	for projectile_variant in game.projectiles:
		kinds[String(Dictionary(projectile_variant).get("kind", ""))] = true
	return kinds.size()


func _test_peashooter_click_ultimate_uses_its_own_plant_food_pattern() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "peashooter", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, 6).x)
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var updated_plant: Dictionary = game.grid[row][col]
	var passed := _assert_true(activated, "peashooter should accept click ultimate activation when fully charged") \
		and _assert_true(String(updated_plant.get("plant_food_mode", "")) == "pea_storm", "peashooter click ultimate should trigger its own pea storm pattern instead of the generic lane burst template")
	_free_game(game)
	return passed


func _test_amber_shooter_click_ultimate_spawns_dedicated_amber_barrage() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "amber_shooter", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "buckethead", row, game.call("_cell_center", row, 4).x)
	game.call("_spawn_zombie_at", "buckethead", row, game.call("_cell_center", row, 7).x)
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var amber_projectiles := _count_projectile_kind(game, "amber_ultimate_shard")
	var generic_peas := _count_projectile_kind(game, "pea")
	var passed := _assert_true(activated, "amber_shooter should accept click ultimate activation when fully charged") \
		and _assert_true(amber_projectiles >= 4, "amber_shooter click ultimate should launch its dedicated amber_ultimate_shard barrage instead of reusing the generic shooter template") \
		and _assert_true(generic_peas == 0, "amber_shooter click ultimate should stop spawning generic pea projectiles") \
		and _assert_true(_count_effect_shape(game, "amber_prism_burst") > 0, "amber_shooter click ultimate should emit a dedicated amber_prism_burst effect")
	_free_game(game)
	return passed


func _test_moonforge_click_ultimate_launches_moonfall_projectiles() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "moonforge", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, 6).x)
	var before_projectiles: int = game.projectiles.size()
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var after_projectiles: int = game.projectiles.size()
	var passed := _assert_true(activated, "moonforge should accept click ultimate activation when fully charged") \
		and _assert_true(after_projectiles > before_projectiles, "moonforge click ultimate should launch visible moonfall projectiles instead of only using the generic barrage template")
	_free_game(game)
	return passed


func _test_flower_pot_click_ultimate_creates_supports_instead_of_generic_heal() -> bool:
	var game := _make_game("roof")
	var row := 2
	var col := 2
	var support = game.call("_create_plant", "flower_pot", row, col)
	support["ultimate_charge"] = 1.0
	game.support_grid[row][col] = support
	var before_count := _count_support_kind(game, "flower_pot")
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var after_count := _count_support_kind(game, "flower_pot")
	var passed := _assert_true(activated, "flower_pot should accept click ultimate activation when fully charged") \
		and _assert_true(after_count > before_count, "flower_pot click ultimate should create additional support pots instead of falling back to the generic support heal")
	_free_game(game)
	return passed


func _test_pepper_mortar_click_ultimate_creates_front_fire_wall() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var target_row := 1
	var target_col := 5
	var plant = game.call("_create_plant", "pepper_mortar", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	var target_x = game.call("_cell_center", target_row, target_col).x
	game.call("_spawn_zombie_at", "normal", 3, game.call("_cell_center", 3, 7).x)
	game.call("_spawn_zombie_at", "normal", target_row, target_x)
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var patch_count := 0
	var duration_ok := true
	for active_row in game.active_rows:
		var effect_index := int(game.call("_cell_effect_index", "magma_patch", int(active_row), target_col))
		if effect_index != -1:
			patch_count += 1
			duration_ok = duration_ok and is_equal_approx(float(game.effects[effect_index].get("duration", 0.0)), 10.0)
	return _assert_true(activated, "pepper_mortar should accept click ultimate activation when fully charged") \
		and _assert_true(patch_count == game.active_rows.size(), "pepper_mortar click ultimate should create a full fire wall on the frontmost zombie column") \
		and _assert_true(duration_ok, "pepper_mortar click ultimate fire wall should last 10 seconds")


func _test_pulse_bulb_click_ultimate_freezes_a_5x5_area() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "pulse_bulb", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", 0, game.call("_cell_center", 0, 0).x)
	game.call("_spawn_zombie_at", "normal", 4, game.call("_cell_center", 4, 4).x)
	game.call("_spawn_zombie_at", "normal", 2, game.call("_cell_center", 2, 6).x)
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var near_a = game.zombies[0]
	var near_b = game.zombies[1]
	var far = game.zombies[2]
	var passed := _assert_true(activated, "pulse_bulb should accept click ultimate activation when fully charged") \
		and _assert_true(float(near_a.get("special_pause_timer", 0.0)) > 0.0, "pulse_bulb click ultimate should freeze targets within its 5x5 field") \
		and _assert_true(float(near_b.get("special_pause_timer", 0.0)) > 0.0, "pulse_bulb click ultimate should reach the far corner of its 5x5 field") \
		and _assert_true(float(far.get("special_pause_timer", 0.0)) <= 0.0, "pulse_bulb click ultimate should not freeze zombies outside the 5x5 field")
	_free_game(game)
	return passed


func _test_pepper_mortar_plant_food_creates_front_target_3x3_fire_zone() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var target_row := 2
	var target_col := 4
	var plant = game.call("_create_plant", "pepper_mortar", row, col)
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", target_row, game.call("_cell_center", target_row, 7).x)
	game.call("_spawn_zombie_at", "normal", target_row, game.call("_cell_center", target_row, target_col).x)
	var activated := bool(game.call("_activate_plant_food", row, col))
	var patch_count := 0
	var duration_ok := true
	for patch_row in range(target_row - 1, target_row + 2):
		for patch_col in range(target_col - 1, target_col + 2):
			var effect_index := int(game.call("_cell_effect_index", "magma_patch", patch_row, patch_col))
			if effect_index != -1:
				patch_count += 1
				duration_ok = duration_ok and is_equal_approx(float(game.effects[effect_index].get("duration", 0.0)), 12.0)
	var passed := _assert_true(activated, "pepper_mortar plant food should activate on a planted mortar") \
		and _assert_true(patch_count == 9, "pepper_mortar plant food should create a 3x3 fire zone around the frontmost target") \
		and _assert_true(duration_ok, "pepper_mortar plant food fire zone should last 12 seconds")
	_free_game(game)
	return passed


func _test_amber_shooter_plant_food_uses_dedicated_amber_projectiles() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "amber_shooter", row, col)
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "buckethead", row, game.call("_cell_center", row, 4).x)
	var activated := bool(game.call("_activate_plant_food", row, col))
	game.call("_update_plants", 0.12)
	var amber_projectiles := _count_projectile_kind(game, "amber_ultimate_shard")
	var generic_peas := _count_projectile_kind(game, "pea")
	var passed := _assert_true(activated, "amber_shooter plant food should activate on a planted amber shooter") \
		and _assert_true(amber_projectiles >= 1, "amber_shooter plant food should fire dedicated amber ultimate shards instead of generic peas") \
		and _assert_true(generic_peas == 0, "amber_shooter plant food should stop reusing the generic pea_storm projectile")
	_free_game(game)
	return passed


func _test_pulse_bulb_plant_food_pushes_nearby_zombies_in_5x5() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "pulse_bulb", row, col)
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", 1, game.call("_cell_center", 1, 4).x)
	game.call("_spawn_zombie_at", "normal", 2, game.call("_cell_center", 2, 4).x)
	game.call("_spawn_zombie_at", "normal", 2, game.call("_cell_center", 2, 7).x)
	var near_before_a = float(game.zombies[0].get("x", 0.0))
	var near_before_b = float(game.zombies[1].get("x", 0.0))
	var far_before = float(game.zombies[2].get("x", 0.0))
	var activated := bool(game.call("_activate_plant_food", row, col))
	var near_after_a = float(game.zombies[0].get("x", 0.0))
	var near_after_b = float(game.zombies[1].get("x", 0.0))
	var far_after = float(game.zombies[2].get("x", 0.0))
	var passed := _assert_true(activated, "pulse_bulb plant food should activate on a planted pulse bulb") \
		and _assert_true(near_after_a > near_before_a and near_after_b > near_before_b, "pulse_bulb plant food should push zombies inside its 5x5 pulse field backward") \
		and _assert_true(is_equal_approx(far_after, far_before), "pulse_bulb plant food should not move zombies outside the 5x5 pulse field")
	_free_game(game)
	return passed


func _test_prism_grass_click_ultimate_hits_three_lanes() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "prism_grass", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	for lane in [1, 2, 3]:
		game.call("_spawn_zombie_at", "normal", lane, game.call("_cell_center", lane, 6).x)
	var before: Array = []
	for zombie in game.zombies:
		before.append(float(zombie.get("health", 0.0)))
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var passed := _assert_true(activated, "prism_grass should accept click ultimate activation when fully charged")
	for zombie_index in range(game.zombies.size()):
		passed = _assert_true(float(game.zombies[zombie_index].get("health", 0.0)) < before[zombie_index], "prism_grass click ultimate should damage each of the three covered lanes") and passed
	passed = _assert_true(_count_effect_shape(game, "rainbow_beam") >= 3, "prism_grass click ultimate should emit rainbow beams across three lanes") and passed
	_free_game(game)
	return passed


func _test_lantern_bloom_click_ultimate_stuns_nearby_enemies() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "lantern_bloom", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, 4).x)
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, 8).x)
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var near = game.zombies[0]
	var far = game.zombies[1]
	var passed := _assert_true(activated, "lantern_bloom should accept click ultimate activation when fully charged") \
		and _assert_true(float(near.get("special_pause_timer", 0.0)) > 0.0, "lantern_bloom click ultimate should stun nearby enemies") \
		and _assert_true(float(far.get("special_pause_timer", 0.0)) <= 0.0, "lantern_bloom click ultimate should not stun enemies outside its bloom radius")
	_free_game(game)
	return passed


func _test_thunder_pine_click_ultimate_spawns_tracking_cloud() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "thunder_pine", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, 4).x)
	game.call("_spawn_zombie_at", "normal", 4, game.call("_cell_center", 4, 8).x)
	var near_before = float(game.zombies[0].get("health", 0.0))
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	game.call("_update_effects", 0.6)
	var near_after = float(game.zombies[0].get("health", 0.0))
	var has_cloud := false
	var duration_ok := false
	for effect_variant in game.effects:
		var effect = Dictionary(effect_variant)
		if String(effect.get("shape", "")) != "thunder_cloud":
			continue
		has_cloud = true
		duration_ok = is_equal_approx(float(effect.get("duration", 0.0)), 8.0)
		break
	var passed := _assert_true(activated, "thunder_pine should accept click ultimate activation when fully charged") \
		and _assert_true(has_cloud, "thunder_pine click ultimate should create a persistent thunder_cloud effect") \
		and _assert_true(duration_ok, "thunder_pine click ultimate thunder_cloud should last 8 seconds") \
		and _assert_true(near_after < near_before, "thunder_pine click ultimate cloud should start striking the nearest zombie")
	_free_game(game)
	return passed


func _test_spikeweed_click_ultimate_pulls_row_targets_in_front() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "spikeweed", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	var plant_center: Vector2 = game.call("_cell_center", row, col)
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, 5).x)
	game.call("_spawn_zombie_at", "conehead", row, game.call("_cell_center", row, 6).x)
	game.call("_spawn_zombie_at", "buckethead", row, game.call("_cell_center", row, 7).x)
	var before_positions: Array = []
	var before_health: Array = []
	for zombie in game.zombies:
		before_positions.append(float(zombie.get("x", 0.0)))
		before_health.append(float(zombie.get("health", 0.0)))
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var pulled := true
	var damaged := true
	for zombie_index in range(3):
		var zombie = game.zombies[zombie_index]
		pulled = float(zombie.get("x", 0.0)) < before_positions[zombie_index] and float(zombie.get("x", 0.0)) <= plant_center.x + game.CELL_SIZE.x * 0.9 and pulled
		damaged = float(zombie.get("health", 0.0)) < before_health[zombie_index] and damaged
	var passed := _assert_true(activated, "spikeweed should accept click ultimate activation when fully charged") \
		and _assert_true(pulled, "spikeweed click ultimate should drag every zombie in its row to the space in front of the spike patch") \
		and _assert_true(damaged, "spikeweed click ultimate should hurt every dragged zombie") \
		and _assert_true(_count_effect_shape(game, "spike_dragline") > 0, "spikeweed click ultimate should emit a dedicated spike_dragline effect instead of the generic plant-food template")
	_free_game(game)
	return passed


func _test_wind_orchid_click_ultimate_uses_dedicated_gust_effect() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "wind_orchid", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	for lane in [row - 1, row, row + 1]:
		game.call("_spawn_zombie_at", "normal", lane, game.call("_cell_center", lane, 5).x)
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var gust_count := _count_effect_shape(game, "wind_gust_lane")
	var spray_count := _count_effect_shape(game, "lane_spray")
	var pushed := true
	for zombie in game.zombies:
		pushed = float(zombie.get("x", 0.0)) > float(game.call("_cell_center", int(zombie.get("row", 0)), 5).x) and pushed
	var passed := _assert_true(activated, "wind_orchid should accept click ultimate activation when fully charged") \
		and _assert_true(gust_count >= 3, "wind_orchid click ultimate should emit dedicated wind_gust_lane effects for the affected rows") \
		and _assert_true(spray_count == 0, "wind_orchid click ultimate should not fall back to the shared lane_spray effect") \
		and _assert_true(pushed, "wind_orchid click ultimate should still push zombies in its covered rows")
	_free_game(game)
	return passed


func _test_wind_orchid_plant_food_uses_dedicated_gust_effect() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "wind_orchid", row, col)
	game.grid[row][col] = plant
	for lane in game.active_rows:
		game.call("_spawn_zombie_at", "normal", int(lane), game.call("_cell_center", int(lane), 5).x)
	var activated := bool(game.call("_activate_plant_food", row, col))
	var gust_count := _count_effect_shape(game, "wind_gust_lane")
	var spray_count := _count_effect_shape(game, "lane_spray")
	var passed := _assert_true(activated, "wind_orchid plant food should activate on a planted wind orchid") \
		and _assert_true(gust_count >= game.active_rows.size(), "wind_orchid plant food should emit dedicated wind_gust_lane effects across the full board") \
		and _assert_true(spray_count == 0, "wind_orchid plant food should not fall back to the shared lane_spray effect")
	_free_game(game)
	return passed


func _test_lotus_lancer_click_ultimate_spawns_converging_lotus_barrage() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "lotus_lancer", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", 1, game.call("_cell_center", 1, 5).x)
	game.call("_spawn_zombie_at", "buckethead", 3, game.call("_cell_center", 3, 6).x)
	var strongest_before = float(game.zombies[1].get("health", 0.0))
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var barrage_count := 0
	for projectile in game.projectiles:
		if String(projectile.get("kind", "")) == "lotus_converge_shot":
			barrage_count += 1
	for _step in range(20):
		game.call("_update_projectiles", 0.08)
	var strongest_after = float(game.zombies[1].get("health", 0.0))
	var passed := _assert_true(activated, "lotus_lancer should accept click ultimate activation when fully charged") \
		and _assert_true(barrage_count >= 24, "lotus_lancer click ultimate should release a 24-shot lotus barrage around the highest-health enemy") \
		and _assert_true(strongest_after < strongest_before, "lotus_lancer click ultimate should converge onto the current highest-health zombie")
	_free_game(game)
	return passed


func _test_lotus_lancer_plant_food_matches_its_click_barrage() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "lotus_lancer", row, col)
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", 2, game.call("_cell_center", 2, 5).x)
	game.call("_spawn_zombie_at", "buckethead", 4, game.call("_cell_center", 4, 6).x)
	var strongest_before = float(game.zombies[1].get("health", 0.0))
	var activated := bool(game.call("_activate_plant_food", row, col))
	var barrage_count := 0
	for projectile in game.projectiles:
		if String(projectile.get("kind", "")) == "lotus_converge_shot":
			barrage_count += 1
	for _step in range(20):
		game.call("_update_projectiles", 0.08)
	var strongest_after = float(game.zombies[1].get("health", 0.0))
	var passed := _assert_true(activated, "lotus_lancer plant food should activate on a planted lotus_lancer") \
		and _assert_true(barrage_count >= 24, "lotus_lancer plant food should use the same 24-shot converge barrage as its click ultimate") \
		and _assert_true(strongest_after < strongest_before, "lotus_lancer plant food should also converge on the highest-health zombie")
	_free_game(game)
	return passed


func _test_mirror_reed_click_ultimate_summons_sniper_support() -> bool:
	var game := _make_game()
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "mirror_reed", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, 6).x)
	var before = float(game.zombies[0].get("health", 0.0))
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var after = float(game.zombies[0].get("health", 0.0))
	var summon_fx := _count_effect_shape(game, "mirror_sniper_call")
	var beam_fx := _count_effect_shape(game, "sniper_beam")
	var passed := _assert_true(activated, "mirror_reed should accept click ultimate activation when fully charged") \
		and _assert_true(summon_fx > 0, "mirror_reed click ultimate should summon a visible sniper support effect in front of itself") \
		and _assert_true(beam_fx > 0, "mirror_reed click ultimate should fire a sniper beam after the summon") \
		and _assert_true(after < before, "mirror_reed click ultimate should damage the target it snipes")
	_free_game(game)
	return passed


func _test_magic_flower_click_ultimate_spawns_random_lane_barrage() -> bool:
	var game := _make_game("roof")
	game.rng.seed = 24680
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "origami_blossom", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "buckethead", row, game.call("_cell_center", row, 6).x)
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var projectile_count: int = game.projectiles.size()
	var unique_kinds: int = _unique_projectile_kind_count(game)
	var passed := _assert_true(activated, "origami_blossom should accept click ultimate activation when fully charged") \
		and _assert_true(projectile_count >= 8, "魔术花 click ultimate should fire a full-lane random barrage instead of the old generic multi-lane burst template") \
		and _assert_true(unique_kinds >= 3, "魔术花 click ultimate should mix several existing projectile kinds in the barrage") \
		and _assert_true(_count_effect_shape(game, "magic_lane_barrage") > 0, "魔术花 click ultimate should emit a dedicated magic_lane_barrage effect")
	_free_game(game)
	return passed


func _test_tesla_tulip_click_ultimate_summons_model_y() -> bool:
	var game := _make_game("roof")
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "tesla_tulip", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	game.call("_spawn_zombie_at", "buckethead", row, game.call("_cell_center", row, 5).x)
	game.call("_spawn_zombie_at", "conehead", row, game.call("_cell_center", row, 7).x)
	game.call("_spawn_zombie_at", "normal", row - 1, game.call("_cell_center", row - 1, 5).x)
	var same_row_before = [
		float(game.zombies[0].get("health", 0.0)),
		float(game.zombies[1].get("health", 0.0)),
	]
	var other_row_before = float(game.zombies[2].get("health", 0.0))
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	for _step in range(16):
		game.call("_update_effects", 0.12)
	var same_row_damaged = float(game.zombies[0].get("health", 0.0)) < same_row_before[0] and float(game.zombies[1].get("health", 0.0)) < same_row_before[1]
	var other_row_unchanged = is_equal_approx(float(game.zombies[2].get("health", 0.0)), other_row_before)
	var passed := _assert_true(activated, "tesla_tulip should accept click ultimate activation when fully charged") \
		and _assert_true(_count_effect_shape(game, "tesla_model_y") > 0, "tesla_tulip click ultimate should summon a visible tesla_model_y sweep effect") \
		and _assert_true(same_row_damaged, "tesla_tulip click ultimate should heavily damage zombies in the Model Y lane") \
		and _assert_true(other_row_unchanged, "tesla_tulip click ultimate should not hit zombies outside the Model Y lane")
	_free_game(game)
	return passed


func _test_brick_guard_click_ultimate_creates_column_wall() -> bool:
	var game := _make_game("roof")
	var row := 2
	var col := 2
	var plant = game.call("_create_plant", "brick_guard", row, col)
	plant["ultimate_charge"] = 1.0
	game.grid[row][col] = plant
	var activated := bool(game.call("_try_activate_ultimate", row, col))
	var wall_count := 0
	for lane_variant in game.active_rows:
		var lane = int(lane_variant)
		var wall = game.grid[lane][col]
		if wall != null and String(wall.get("kind", "")) == "brick_guard":
			wall_count += 1
	var passed := _assert_true(activated, "brick_guard should accept click ultimate activation when fully charged") \
		and _assert_true(wall_count == game.active_rows.size(), "brick_guard click ultimate should create a full-column wall of brick guards") \
		and _assert_true(_count_effect_shape(game, "brick_column_wall") > 0, "brick_guard click ultimate should emit a dedicated brick_column_wall effect")
	_free_game(game)
	return passed
