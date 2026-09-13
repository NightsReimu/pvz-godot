extends "res://tests/click_ultimate_behavior_test.gd"

func _run() -> void:
	var passed := _test_passive_heals_health_only()
	passed = _test_ultimate_heals_and_shields() and passed
	passed = _test_touhou_conveyor_weight() and passed
	print("Healing gourd: healing passive, healing+shielding ultimate, support layers and Touhou weight: %s" % ("PASS" if passed else "FAIL"))
	quit(0 if passed else 1)

func _test_passive_heals_health_only() -> bool:
	var game := _make_game()
	var gourd: Dictionary = game._create_plant("healing_gourd", 2, 2)
	gourd.support_timer = 0.0
	game.grid[2][2] = gourd
	var neighbor: Dictionary = game._create_plant("repeater", 1, 1)
	neighbor.health = 10.0
	neighbor.armor_health = 5.0
	neighbor.max_armor_health = 100.0
	game.grid[1][1] = neighbor
	var outside: Dictionary = game._create_plant("repeater", 0, 2)
	outside.health = 10.0
	game.grid[0][2] = outside
	game._ensure_plant_runtime().update_healing_gourd(gourd, 0.1, 2, 2)
	var passed := _assert_true(neighbor.health > 10.0 and outside.health == 10.0, "Passive healing includes the 3x3 diagonal and excludes the next row")
	passed = _assert_true(neighbor.armor_health == 5.0, "Gourd passive must not restore armor") and passed
	_free_game(game)
	return passed

func _test_ultimate_heals_and_shields() -> bool:
	var game := _make_game()
	var gourd: Dictionary = game._create_plant("healing_gourd", 2, 2)
	gourd.ultimate_charge = 1.0
	game.grid[2][2] = gourd
	var neighbor: Dictionary = game._create_plant("repeater", 2, 3)
	neighbor.health = 10.0
	neighbor.armor_health = 5.0
	neighbor.max_armor_health = 100.0
	game.grid[2][3] = neighbor
	var support: Dictionary = game._create_plant("flower_pot", 1, 2)
	support.health = 10.0
	game.support_grid[1][2] = support
	game._spawn_zombie_at("normal", 2, game._cell_center(2, 3).x, true)
	var enemy: Dictionary = game.zombies.back()
	var enemy_health := float(enemy.health)
	var passed := _assert_true(game._try_activate_ultimate(2, 2), "Charged gourd ultimate must activate")
	passed = _assert_true(neighbor.health == neighbor.max_health and support.health == support.max_health, "Gourd ultimate restores plant and support health") and passed
	passed = _assert_true(neighbor.armor_health == 265.0 and neighbor.max_armor_health == 265.0, "Gourd ultimate stacks a shield on every plant") and passed
	passed = _assert_true(gourd.get("armor_health", 0.0) == 260.0 and String(gourd.get("shell_kind", "")) == "holy_shield", "Gourd ultimate shields the gourd itself") and passed
	passed = _assert_true(enemy.health == enemy_health, "Gourd ultimate cannot damage zombies") and passed
	passed = _assert_true(game.grid[1][2] == null and game.support_grid[1][2] == support, "Healing must not copy a support into the main plant layer") and passed
	_free_game(game)
	return passed

func _test_touhou_conveyor_weight() -> bool:
	var game := _make_game()
	game.conveyor_source_cards = ["repeater", "healing_gourd"]
	game.active_cards = [""]
	var passed := true
	for touhou in [false, true]:
		game.current_level.events = [{"kind": "reisen_boss"}] if touhou else []
		game.rng.seed = 924
		var gourds := 0
		for i in range(12000):
			if game._pick_conveyor_card_for_slot(0) == "healing_gourd":
				gourds += 1
		var share := float(gourds) / 12000.0
		passed = _assert_true(share > (0.37 if touhou else 0.46) and share < (0.45 if touhou else 0.54), "Gourd relative weight decreases only on Touhou conveyors; observed %.3f" % share) and passed
	_free_game(game)
	return passed
