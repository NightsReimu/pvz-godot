extends "res://tests/gacha_plant_food_test.gd"


func _run() -> void:
	var passed := true
	passed = _test_plasma_damage_and_expiry() and passed
	passed = _test_full_health_shields_at_all_scales() and passed
	passed = _test_rock_breaks_and_frost_sources() and passed
	passed = _test_mirror_and_meteor_targeting() and passed
	passed = _test_passive_death_recovery() and passed
	passed = _test_support_buffs_and_timers() and passed
	print("Gacha passive regressions: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)


func _place(game: Control, kind: String, row: int, col: int) -> Dictionary:
	var plant: Dictionary = game._create_plant(kind, row, col)
	game.grid[row][col] = plant
	return plant


func _test_plasma_damage_and_expiry() -> bool:
	var game = _make_game()
	_place(game, "plasma_shroom", 2, 3)
	_spawn_target_at_offset(game, 2, 3, 60.0)
	var hp = float(game.zombies[0].health)
	game._update_plants(0.1)
	game._update_effects(0.5)
	var passed = _assert_true(is_equal_approx(float(game.zombies[0].health), hp - 10.0), "Plasma must deal 20 damage per second without an ultimate")
	game.boss_time_stop_timer = 1.0
	game._update_effects(0.5)
	passed = _assert_true(is_equal_approx(float(game.zombies[0].health), hp - 10.0), "Plasma damage must pause during boss time stop") and passed
	game.boss_time_stop_timer = 0.0
	game._update_effects(5.0)
	passed = _assert_true(is_equal_approx(float(game.zombies[0].health), hp - 80.0), "Plasma must process its final partial tick without over-damaging") and passed
	_free_game(game)
	return passed


func _test_full_health_shields_at_all_scales() -> bool:
	var passed := true
	for cell_size in [Vector2(98, 110), Vector2(134, 127), Vector2(60, 70)]:
		var game = _make_game()
		game.CELL_SIZE = cell_size
		game.board_size = cell_size * Vector2(9, 5)
		_place(game, "bubble_lotus", 2, 3)
		var ally = _place(game, "peashooter", 1, 4)
		var far = _place(game, "peashooter", 2, 5)
		game._update_plants(0.1)
		passed = _assert_true(float(ally.armor_health) == 400.0, "Bubble lotus must shield a full-health diagonal neighbor at %s" % cell_size) and passed
		passed = _assert_true(float(far.armor_health) == 0.0, "Bubble lotus must respect its one-cell support range") and passed
		_free_game(game)
	return passed


func _test_rock_breaks_and_frost_sources() -> bool:
	var game = _make_game()
	var rock = _place(game, "rock_armor_fruit", 2, 3)
	_spawn_target_at_offset(game, 2, 3, 50.0)
	var hp = float(game.zombies[0].health)
	game._damage_plant_cell(2, 3, 1800.0)
	game._update_plants(0.1)
	var passed = _assert_true(float(game.zombies[0].health) <= hp - 80.0, "Rock armor must retaliate when its first layer breaks")
	passed = _assert_true(int(rock.armor_layer) == 2, "Rock must start with three unbroken layers") and passed
	_free_game(game)
	game = _make_game()
	_place(game, "frost_cypress", 2, 3)
	_place(game, "frost_cypress", 2, 8)
	_spawn_target_at_offset(game, 2, 3, 60.0)
	for _tick in range(32):
		game._update_plants(0.1)
	passed = _assert_true(float(game.zombies[0].get("frozen_timer", 0.0)) > 0.0, "A distant frost cypress must not erase another cypress's exposure") and passed
	_free_game(game)
	return passed


func _test_mirror_and_meteor_targeting() -> bool:
	var game = _make_game()
	_place(game, "mirror_shroom", 2, 3)
	_spawn_target_at_offset(game, 2, 3, 240.0)
	var hp = float(game.zombies[0].health)
	for _tick in range(40):
		game._update_plants(0.1)
		game._update_projectiles(0.1)
	var passed = _assert_true(float(game.zombies[0].health) < hp, "Mirror shroom must retain a basic attack without an offensive donor")
	_free_game(game)
	game = _make_game()
	_place(game, "meteor_flower", 2, 3)
	_spawn_target_at_offset(game, 0, 3, 200.0)
	hp = float(game.zombies[0].health)
	game._update_plants(0.1)
	game._update_projectiles(0.6)
	passed = _assert_true(float(game.zombies[0].health) < hp, "Meteor flower must attack other lanes without a same-lane enemy") and passed
	_free_game(game)
	return passed


func _test_passive_death_recovery() -> bool:
	var game = _make_game()
	var phoenix = _place(game, "phoenix_tree", 2, 3)
	game._damage_plant_cell(2, 3, 1000.0)
	game._remove_dead_plants()
	var passed = _assert_true(game.grid[2][3] != null and float(phoenix.health) == float(phoenix.max_health), "Phoenix must revive once without its ultimate")
	game._update_plants(1.0)
	game._damage_plant_cell(2, 3, 1000.0)
	game._remove_dead_plants()
	passed = _assert_true(game.grid[2][3] == null, "Phoenix passive revival must be limited to once per planting") and passed
	_free_game(game)
	game = _make_game()
	var lotus = _place(game, "holy_lotus", 2, 3)
	var ally = _place(game, "peashooter", 1, 4)
	game._damage_plant_cell(1, 4, 1000.0)
	game._remove_dead_plants()
	passed = _assert_true(game.grid[1][4] != null and float(ally.health) > 0.0, "Holy lotus must rescue a dying neighbor without an ultimate") and passed
	passed = _assert_true(float(lotus.health) == 20.0 and float(lotus.save_cooldown) > 0.0, "Holy rescue must pay its health cost and enter cooldown") and passed
	_free_game(game)
	return passed


func _test_support_buffs_and_timers() -> bool:
	var game = _make_game()
	game.CELL_SIZE = Vector2(134, 127)
	game.board_size = game.CELL_SIZE * Vector2(9, 5)
	_place(game, "galaxy_sunflower", 2, 3)
	var ally = _place(game, "peashooter", 1, 4)
	var passed = _assert_true(is_equal_approx(game._plant_enhance_multiplier_at_cell(1, 4), 1.2), "Galaxy sunflower must provide its normal 20% damage aura")
	game.grid[2][3].sleep_timer = 2.0
	passed = _assert_true(is_equal_approx(game._plant_enhance_multiplier_at_cell(1, 4), 1.0), "Sleeping sources must not provide passive auras") and passed
	game.grid[2][3] = null
	var aurora = _place(game, "aurora_orchid", 2, 3)
	game._update_plants(0.1)
	passed = _assert_true(is_equal_approx(game._plant_enhance_multiplier_at_cell(1, 4), 1.25), "Aurora buff must reach a diagonal neighbor at large layouts") and passed
	game._update_plants(1.0)
	passed = _assert_true(is_equal_approx(float(aurora.support_timer), 3.0), "Support cooldown must tick once, not twice per frame") and passed
	ally.aurora_buff_timer = 0.0
	game.grid[2][3] = null
	_place(game, "solar_emperor", 2, 3)
	game.suns = [{"position": game._sun_target(), "collecting": true, "life": 10.0, "value": 50}]
	game._update_suns(0.1)
	passed = _assert_true(is_equal_approx(game._plant_enhance_multiplier_at_cell(1, 4), 1.1), "Sun collection must trigger solar emperor's neighboring buff") and passed
	_free_game(game)
	return passed
