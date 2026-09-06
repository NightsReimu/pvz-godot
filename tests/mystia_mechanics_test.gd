extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := _make_game()
	var passed := true
	var plant: Dictionary = game._create_plant("peashooter", 0, 0)
	game.grid[0][0] = plant
	passed = _assert_true(game._mystia_charm_plant_at_cell(0, 0), "Mystia song should charm a targetable plant") and passed
	game._update_charmed_plants(0.8)
	passed = _assert_true(bool(game.grid[0][0].get("mystia_charmed", false)), "Mystia charm should be permanent") and passed
	passed = _assert_true(game._plant_charm_blocks_actions(game.grid[0][0]), "Charmed plants should be blocked from normal actions") and passed

	game.grid[0][0] = game._create_plant("peashooter", 0, 0)
	game._spawn_zombie("normal", 0)
	var normal_base_health := float(game.zombies[0].get("max_health", 0.0))
	var boss := {"mystia_cooking_timer": 0.0, "mystia_cooking_row": -1, "mystia_cooking_col": -1, "boss_phase": 0}
	passed = _assert_true(game._mystia_start_cooking(boss, 0), "Mystia should start cooking an occupied cell") and passed
	var cooked_row := int(boss.get("mystia_cooking_row", -1))
	var cooked_col := int(boss.get("mystia_cooking_col", -1))
	boss["mystia_cooking_timer"] = 0.01
	game._update_mystia_cooking(boss, 0.1)
	passed = _assert_true(game._targetable_plant_at(cooked_row, cooked_col) == null, "Cooking completion should remove the plant") and passed
	var buffed := false
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) == "normal":
			buffed = float(zombie.get("mystia_food_buff_timer", 0.0)) > 0.0 and float(zombie.get("max_health", 0.0)) > float(zombie.get("mystia_food_base_max_health", 0.0))
	passed = _assert_true(buffed, "Cooking completion should buff ordinary enemy zombies") and passed
	game._update_mystia_food_buffs(20.0)
	var restored := false
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) == "normal":
			restored = float(zombie.get("mystia_food_buff_timer", 0.0)) == 0.0 and is_equal_approx(float(zombie.get("max_health", 0.0)), normal_base_health)
	passed = _assert_true(restored, "Food buff expiry should restore the zombie health cap") and passed
	game.free()
	quit(0 if passed else 1)


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "3-20", "terrain": "mystia_night_food_stand", "events": [], "row_count": 6}
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.board_rows = 6
	game.board_size = Vector2(882.0, 660.0)
	game.grid = _make_grid()
	game.support_grid = _make_grid()
	game.zombies = []
	game.effects = []
	return game


func _make_grid() -> Array:
	var result: Array = []
	for _row in range(6):
		result.append([null, null, null, null, null, null, null, null, null])
	return result


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
