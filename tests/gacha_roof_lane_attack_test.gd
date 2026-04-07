extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_shadow_pea_attacks_full_row_on_roof() or failed
	failed = not _test_plasma_shooter_attacks_full_row_on_roof() or failed
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


func _make_roof_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "roof-test", "terrain": "roof", "events": [], "title": "roof-test", "description": ""}
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


func _place_roof_plant(game: Control, kind: String, row: int, col: int) -> void:
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	game.grid[row][col] = game._create_plant(kind, row, col)


func _spawn_far_lane_target(game: Control, row: int, col: int) -> void:
	var zombie_x = float(game._cell_center(row, col).x) + 12.0
	game._spawn_zombie_at("normal", row, zombie_x)


func _test_shadow_pea_attacks_full_row_on_roof() -> bool:
	var game := _make_roof_game()
	var row := 2
	_place_roof_plant(game, "shadow_pea", row, 1)
	_spawn_far_lane_target(game, row, 6)
	game._update_plants(2.0)
	var passed := _assert_true(game.projectiles.size() > 0, "shadow_pea should fire across the full roof lane instead of failing the roof blocker check")
	_free_game(game)
	return passed


func _test_plasma_shooter_attacks_full_row_on_roof() -> bool:
	var game := _make_roof_game()
	var row := 2
	_place_roof_plant(game, "plasma_shooter", row, 1)
	_spawn_far_lane_target(game, row, 6)
	var before_health := float(game.zombies[0].get("health", 0.0))
	game._update_plants(2.4)
	var after_health := float(game.zombies[0].get("health", 0.0))
	var passed := _assert_true(after_health < before_health or game.effects.size() > 0, "plasma_shooter should hit a same-lane roof target even beyond the low-roof cutoff")
	_free_game(game)
	return passed
