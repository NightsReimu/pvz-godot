extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_prism_grass_applies_slow() or failed
	failed = not _test_hypnotized_dancing_summons_hypnotized_backup() or failed
	failed = not _test_hypnotized_nether_sleeps_enemy_zombies() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_grid(rows: int, cols: int) -> Array:
	var result: Array = []
	for _row in range(rows):
		var row_data: Array = []
		for _col in range(cols):
			row_data.append(null)
		result.append(row_data)
	return result


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "2-test", "terrain": "night", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
	game.grid = _make_grid(6, 9)
	game.support_grid = _make_grid(6, 9)
	game.zombies = []
	game.weeds = []
	game.spears = []
	game.effects = []
	game.mowers = []
	for row in range(6):
		game.mowers.append({
			"row": row,
			"x": game.BOARD_ORIGIN.x - 56.0,
			"armed": true,
			"active": false,
		})
	game.toast_label = Label.new()
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	game.free()


func _test_prism_grass_applies_slow() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	game._spawn_zombie_at("normal", row, center.x + 120.0)
	var plant = game._create_plant("prism_grass", row, col)
	plant["attack_timer"] = 0.0
	game._update_prism_grass(plant, 0.1, row, col)
	var passed = _assert_true(float(game.zombies[0].get("slow_timer", 0.0)) > 0.0, "prism_grass should apply a slow effect when it hits")
	_free_game(game)
	return passed


func _test_hypnotized_dancing_summons_hypnotized_backup() -> bool:
	var game = _make_game()
	var row := 2
	var summon_x = game.BOARD_ORIGIN.x + game.board_size.x * 0.82
	game._spawn_zombie_at("dancing", row, summon_x)
	var dancing = game.zombies[0]
	dancing = game._hypnotize_zombie(dancing)
	dancing["summon_cooldown"] = 0.0
	dancing["dance_summoned"] = false
	game.zombies[0] = dancing
	game._update_zombies(0.1)
	var backup_count := 0
	var all_hypnotized := true
	for zombie in game.zombies:
		if String(zombie["kind"]) != "backup_dancer":
			continue
		backup_count += 1
		all_hypnotized = all_hypnotized and bool(zombie.get("hypnotized", false))
	var passed = _assert_true(backup_count > 0, "hypnotized dancing zombie should still summon backup dancers") \
		and _assert_true(all_hypnotized, "backup dancers summoned by a hypnotized dancing zombie should also be hypnotized")
	_free_game(game)
	return passed


func _test_hypnotized_nether_sleeps_enemy_zombies() -> bool:
	var game = _make_game()
	var row := 2
	var col := 3
	var center = game._cell_center(row, col)
	var plant = game._create_plant("puff_shroom", row, col)
	game.grid[row][col] = plant
	game._spawn_zombie_at("nether", row, center.x)
	game._spawn_zombie_at("normal", row, center.x + 72.0)
	var nether = game.zombies[0]
	nether = game._hypnotize_zombie(nether)
	nether["sleep_cooldown"] = 0.0
	game.zombies[0] = nether
	game._update_zombies(0.1)
	var updated_plant = game.grid[row][col]
	var enemy_zombie = game.zombies[1]
	var passed = _assert_true(float(enemy_zombie.get("special_pause_timer", 0.0)) > 0.0, "hypnotized nether should put enemy zombies to sleep") \
		and _assert_true(float(updated_plant.get("sleep_timer", 0.0)) <= 0.0, "hypnotized nether should not put allied plants to sleep")
	_free_game(game)
	return passed
