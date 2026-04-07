extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_peashooter_click_ultimate_uses_its_own_plant_food_pattern() or failed
	failed = not _test_moonforge_click_ultimate_launches_moonfall_projectiles() or failed
	failed = not _test_flower_pot_click_ultimate_creates_supports_instead_of_generic_heal() or failed
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
