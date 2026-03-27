extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_endless_mode_preserves_custom_level_on_selection_start() or failed
	failed = not _test_endless_mode_does_not_autowin_before_spawning_waves() or failed
	failed = not _test_enhance_button_click_is_not_shadowed_by_hidden_grid_cells() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.size = Vector2(1600.0, 900.0)
	game.current_level = {"id": "1-test", "terrain": "day", "events": [], "title": "test", "description": ""}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
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
	game.weeds = []
	game.spears = []
	game.effects = []
	game.graves = []
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	game.completed_levels.resize(GameScript.Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
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


func _test_endless_mode_preserves_custom_level_on_selection_start() -> bool:
	var game := _make_game()
	game.call("_enter_endless_mode")
	var selection_pool: Array = game.selection_pool_cards.duplicate()
	if selection_pool.is_empty():
		selection_pool = game.call("_player_plant_collection")
		game.selection_pool_cards = selection_pool.duplicate()
	var required_count = int(game.call("_required_seed_count", game.current_level))
	game.selection_cards = selection_pool.slice(0, max(required_count, 1))
	game.call("_handle_selection_click", game.PREP_START_RECT.position + game.PREP_START_RECT.size * 0.5)
	var passed = _assert_true(game.mode == game.MODE_BATTLE, "endless mode should start a battle from the selection screen") \
		and _assert_true(String(game.current_level.get("id", "")) == "无尽", "starting endless mode should keep the custom endless level instead of replacing it with a campaign stage") \
		and _assert_true(game.selected_level_index == -1, "endless mode should not bind itself to a campaign level index")
	_free_game(game)
	return passed


func _test_endless_mode_does_not_autowin_before_spawning_waves() -> bool:
	var game := _make_game()
	game.call("_enter_endless_mode")
	var selection_pool: Array = game.selection_pool_cards.duplicate()
	if selection_pool.is_empty():
		selection_pool = game.call("_player_plant_collection")
		game.selection_pool_cards = selection_pool.duplicate()
	game.selection_cards = selection_pool.slice(0, 1)
	game.call("_handle_selection_click", game.PREP_START_RECT.position + game.PREP_START_RECT.size * 0.5)
	game.call("_check_end_state")
	var passed = _assert_true(game.battle_state == game.BATTLE_PLAYING, "endless mode should not instantly clear itself before the first wave starts")
	_free_game(game)
	return passed


func _test_enhance_button_click_is_not_shadowed_by_hidden_grid_cells() -> bool:
	var game := _make_game()
	game.coins_total = 99999
	game.plant_enhance_levels = {}
	game.enhance_selected_plant = "peashooter"
	game.call("_enter_enhance_mode")
	game.enhance_selected_plant = "peashooter"
	var button_center = Vector2(1390.0, 518.0)
	game.call("_handle_enhance_click", button_center)
	var passed = _assert_true(String(game.enhance_selected_plant) == "peashooter", "clicking the enhance button should not select an invisible plant cell underneath the side panel") \
		and _assert_true(int(game.plant_enhance_levels.get("peashooter", 0)) == 1, "clicking the enhance button should actually enhance the selected plant")
	_free_game(game)
	return passed
