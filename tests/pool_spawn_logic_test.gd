extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_spawn_row_partition() or failed
	failed = not _test_fixed_row_events_still_spread_support_spawns() or failed
	failed = not _test_lifebuoy_variants_exist() or failed
	failed = not _test_custom_pool_zombie_spawn_rules() or failed
	failed = not _test_qinghua_shards_block_planting_after_shield_break() or failed
	failed = not _test_shouyue_stays_hidden_until_revealed() or failed
	failed = not _test_shouyue_aims_before_firing() or failed
	failed = not _test_shouyue_fires_sniper_beam_after_charge() or failed
	failed = not _test_shouyue_snipes_the_front_plant() or failed
	failed = not _test_ice_block_leaves_ice_tile_after_skill_cycle() or failed
	failed = not _test_dragon_boat_glides_instead_of_teleporting() or failed
	failed = not _test_dragon_boat_crushes_plants_in_water_lane() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _assert_array_eq(actual: Array, expected: Array, message: String) -> bool:
	if actual == expected:
		return true
	push_error("%s | actual=%s expected=%s" % [message, actual, expected])
	return false


func _has_effect_shape(game: Control, shape_name: String) -> bool:
	for effect_variant in game.effects:
		if String(effect_variant.get("shape", "")) == shape_name:
			return true
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "3-test", "terrain": "pool"}
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.water_rows = [2, 3]
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
			"x": game.BOARD_ORIGIN.x - 64.0,
			"armed": true,
			"active": false,
		})
	return game


func _test_spawn_row_partition() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_eligible_spawn_rows_for_kind"), "expected _eligible_spawn_rows_for_kind helper to exist"):
		game.free()
		return false
	var land_rows: Array = game._eligible_spawn_rows_for_kind("normal")
	var water_rows: Array = game._eligible_spawn_rows_for_kind("lifebuoy_normal")
	var passed = _assert_array_eq(land_rows, [0, 1, 4, 5], "land zombies should stay on land rows") \
		and _assert_array_eq(water_rows, [2, 3], "lifebuoy zombies should stay on water rows")
	game.free()
	return passed


func _test_fixed_row_events_still_spread_support_spawns() -> bool:
	var game = _make_game()
	game.current_level = {
		"id": "3-test",
		"terrain": "pool",
		"row_count": 6,
		"events": [
			{"time": 6.0, "kind": "conehead", "row": 2, "wave": true},
		],
	}
	game.call("_begin_next_batch")
	var support_kept_same_row := true
	for i in range(1, game.batch_spawn_queue.size()):
		if int(game.batch_spawn_queue[i].get("row", -1)) != 2:
			support_kept_same_row = false
			break
	var passed = _assert_true(game.batch_spawn_queue.size() > 1, "fixed-row event should enqueue support spawns for spread checks") \
		and _assert_true(not support_kept_same_row, "support spawns should not all inherit a fixed event row, or each wave collapses into one lane")
	game.free()
	return passed


func _test_lifebuoy_variants_exist() -> bool:
	return _assert_true(Defs.ZOMBIES.has("lifebuoy_normal"), "missing lifebuoy_normal definition") \
		and _assert_true(Defs.ZOMBIES.has("lifebuoy_cone"), "missing lifebuoy_cone definition") \
		and _assert_true(Defs.ZOMBIES.has("lifebuoy_bucket"), "missing lifebuoy_bucket definition")


func _test_custom_pool_zombie_spawn_rules() -> bool:
	var game = _make_game()
	var dragon_boat_rows: Array = game._eligible_spawn_rows_for_kind("dragon_boat")
	var dragon_dance_rows: Array = game._eligible_spawn_rows_for_kind("dragon_dance")
	var qinghua_rows: Array = game._eligible_spawn_rows_for_kind("qinghua")
	var passed = _assert_array_eq(dragon_boat_rows, [2, 3], "dragon_boat should stay on water rows") \
		and _assert_array_eq(dragon_dance_rows, [0, 1, 4, 5], "dragon_dance should stay on land rows") \
		and _assert_array_eq(qinghua_rows, [0, 1, 2, 3, 4, 5], "qinghua should be able to appear on both land and water rows")
	game.free()
	return passed


func _test_qinghua_shards_block_planting_after_shield_break() -> bool:
	var game = _make_game()
	if not _assert_true(Defs.ZOMBIES.has("qinghua"), "expected qinghua zombie definition to exist"):
		game.free()
		return false
	game._spawn_zombie_at("qinghua", 2, game._cell_center(2, 4).x)
	var zombie = game.zombies[0]
	zombie = game._apply_zombie_damage(zombie, float(zombie.get("shield_health", 0.0)) + 12.0, 0.1)
	game.zombies[0] = zombie
	var passed = _assert_true(game._placement_error("peashooter", 2, 4) != "", "qinghua shield break should leave temporary shards that block planting")
	game.free()
	return passed


func _test_shouyue_stays_hidden_until_revealed() -> bool:
	var game = _make_game()
	if not _assert_true(Defs.ZOMBIES.has("shouyue"), "expected shouyue zombie definition to exist"):
		game.free()
		return false
	game._spawn_zombie_at("shouyue", 2, game._cell_center(2, 6).x)
	var hidden_before = bool(game._is_hidden_from_lane_attacks(game.zombies[0]))
	game.grid[2][2] = game._create_plant("wallnut", 2, 2)
	var hidden_after = bool(game._is_hidden_from_lane_attacks(game.zombies[0]))
	var passed = _assert_true(hidden_before, "shouyue should begin hidden from lane attacks") \
		and _assert_true(not hidden_after, "a plant standing in front of shouyue should reveal it")
	game.free()
	return passed


func _test_shouyue_aims_before_firing() -> bool:
	var game = _make_game()
	game.grid[2][5] = game._create_plant("wallnut", 2, 5)
	game._spawn_zombie_at("shouyue", 2, game._cell_center(2, 7).x)
	var zombie = game.zombies[0]
	zombie["snipe_cooldown"] = 0.0
	game.zombies[0] = zombie
	var start_x = float(game.zombies[0]["x"])
	var front_before = float(game.grid[2][5]["health"])
	game._update_zombies(0.1)
	var passed = _assert_true(is_equal_approx(float(game.zombies[0]["x"]), start_x), "shouyue should stop moving as soon as it starts aiming at a plant in its lane") \
		and _assert_true(is_equal_approx(float(game.grid[2][5]["health"]), front_before), "shouyue should spend a short charge time aiming before the sniper shot lands") \
		and _assert_true(_has_effect_shape(game, "sniper_focus"), "shouyue aiming should create a converging laser focus effect")
	game.free()
	return passed


func _test_shouyue_fires_sniper_beam_after_charge() -> bool:
	var game = _make_game()
	game.grid[2][5] = game._create_plant("wallnut", 2, 5)
	game._spawn_zombie_at("shouyue", 2, game._cell_center(2, 7).x)
	var zombie = game.zombies[0]
	zombie["snipe_cooldown"] = 0.0
	game.zombies[0] = zombie
	var front_before = float(game.grid[2][5]["health"])
	for _step in range(8):
		game._update_zombies(0.1)
		game._update_effects(0.1)
	var passed = _assert_true(float(game.grid[2][5]["health"]) < front_before, "shouyue should still land the sniper shot after charging") \
		and _assert_true(_has_effect_shape(game, "sniper_beam"), "shouyue shot should emit a visible sniper beam effect")
	game.free()
	return passed


func _test_shouyue_snipes_the_front_plant() -> bool:
	var game = _make_game()
	game.grid[2][1] = game._create_plant("peashooter", 2, 1)
	game.grid[2][5] = game._create_plant("wallnut", 2, 5)
	game._spawn_zombie_at("shouyue", 2, game._cell_center(2, 7).x)
	var zombie = game.zombies[0]
	zombie["snipe_cooldown"] = 0.0
	game.zombies[0] = zombie
	var back_before = float(game.grid[2][1]["health"])
	var front_before = float(game.grid[2][5]["health"])
	game._update_zombies(0.2)
	var back_after = float(game.grid[2][1]["health"])
	var front_after = float(game.grid[2][5]["health"])
	var passed = _assert_true(front_after < front_before, "shouyue should snipe the front-most plant in its lane") \
		and _assert_true(is_equal_approx(back_after, back_before), "shouyue should not skip the front plant to hit a farther target")
	game.free()
	return passed


func _test_ice_block_leaves_ice_tile_after_skill_cycle() -> bool:
	var game = _make_game()
	game._spawn_zombie_at("ice_block", 2, game._cell_center(2, 6).x)
	var zombie = game.zombies[0]
	zombie["ice_drop_cooldown"] = 0.0
	game.zombies[0] = zombie
	game._update_zombies(0.2)
	var ice_col = game._zombie_cell_col(float(game.zombies[0]["x"]))
	var passed = _assert_true(game._has_ice_tile(2, ice_col), "ice_block should leave an ice tile under itself when its skill triggers")
	game.free()
	return passed


func _test_dragon_boat_glides_instead_of_teleporting() -> bool:
	var game = _make_game()
	game._spawn_zombie_at("dragon_boat", 2, game._cell_center(2, 7).x)
	var zombie = game.zombies[0]
	zombie["boat_stride_timer"] = 0.0
	game.zombies[0] = zombie
	var start_x = float(game.zombies[0]["x"])
	game._update_zombies(0.2)
	var current_x = float(game.zombies[0]["x"])
	var passed = _assert_true(current_x < start_x, "dragon_boat should still start advancing when a stroke begins") \
		and _assert_true(current_x > start_x - game.CELL_SIZE.x * 0.8, "dragon_boat should glide through a stroke instead of teleporting a full tile in one frame")
	game.free()
	return passed


func _test_dragon_boat_crushes_plants_in_water_lane() -> bool:
	var game = _make_game()
	game.grid[2][6] = game._create_plant("wallnut", 2, 6)
	game.support_grid[2][6] = game._create_plant("lily_pad", 2, 6)
	game._spawn_zombie_at("dragon_boat", 2, game._cell_center(2, 7).x)
	var zombie = game.zombies[0]
	zombie["boat_stride_timer"] = 0.0
	game.zombies[0] = zombie
	game._update_zombies(0.2)
	var passed = _assert_true(game.grid[2][6] == null and game.support_grid[2][6] == null, "dragon_boat should crush plants it paddles into on water rows")
	game.free()
	return passed
