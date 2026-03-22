extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_replaying_old_level_uses_current_progress_plant_pool() or failed
	failed = not _test_seed_selection_starts_empty_for_manual_pick() or failed
	failed = not _test_special_modes_keep_their_curated_plant_pools() or failed
	failed = not _test_sparse_v2_save_data_backfills_near_end_progress() or failed
	failed = not _test_inconsistent_blank_save_data_recovers_from_last_level_index() or failed
	failed = not _test_loaded_campaign_init_does_not_force_immediate_autosave() or failed
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


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "1-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
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
	game.mowers = []
	for row in range(6):
		game.mowers.append({
			"row": row,
			"x": game.BOARD_ORIGIN.x - 56.0,
			"armed": true,
			"active": false,
		})
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


func _mark_all_levels_completed(game: Control) -> void:
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = true
	game.unlocked_levels = Defs.LEVELS.size()


func _test_replaying_old_level_uses_current_progress_plant_pool() -> bool:
	var level_index = _find_level_index("1-1")
	if not _assert_true(level_index != -1, "expected 1-1 to exist for replay plant pool checks"):
		return false
	var game = _make_game()
	_mark_all_levels_completed(game)
	var level = Defs.LEVELS[level_index]
	var requires_selection = bool(game.call("_requires_seed_selection", level))
	game.call("_enter_seed_selection", level_index)
	var passed = _assert_true(requires_selection, "replaying 1-1 with a full save should open the seed selection screen") \
		and _assert_true(game.selection_pool_cards.has("tallnut"), "replaying old levels should include late-game unlocked plants in the selection pool") \
		and _assert_true(game.selection_pool_cards.has("dream_drum"), "replaying old levels should include all currently obtained plants") \
		and _assert_true(not game.selection_pool_cards.has("wallnut_bowling"), "replayed standard levels should not leak special-only plants into the persistent collection")
	_free_game(game)
	return passed


func _test_seed_selection_starts_empty_for_manual_pick() -> bool:
	var level_index = _find_level_index("1-1")
	if not _assert_true(level_index != -1, "expected 1-1 to exist for manual selection checks"):
		return false
	var game = _make_game()
	_mark_all_levels_completed(game)
	game.call("_enter_seed_selection", level_index)
	var passed = _assert_true(game.selection_cards.is_empty(), "seed selection should start with no preselected plants so the player can choose manually")
	_free_game(game)
	return passed


func _test_special_modes_keep_their_curated_plant_pools() -> bool:
	var level_index = _find_level_index("2-9")
	if not _assert_true(level_index != -1, "expected 2-9 to exist for special-mode pool checks"):
		return false
	var game = _make_game()
	_mark_all_levels_completed(game)
	var level = Defs.LEVELS[level_index]
	var default_cards: Array = game.call("_default_level_cards", level)
	var passed = _assert_true(not bool(game.call("_requires_seed_selection", level)), "special modes should still skip normal seed selection") \
		and _assert_true(default_cards == ["grave_buster", "potato_mine", "cherry_bomb"], "whack levels should keep their curated plant pool instead of using the save-wide pool")
	_free_game(game)
	return passed


func _test_sparse_v2_save_data_backfills_near_end_progress() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_apply_loaded_save_data"), "expected _apply_loaded_save_data helper to exist for save repair"):
		_free_game(game)
		return false
	var index_1_17 = _find_level_index("1-17")
	var index_1_18 = _find_level_index("1-18")
	var index_3_10 = _find_level_index("3-10")
	var passed = _assert_true(index_1_17 != -1 and index_1_18 != -1 and index_3_10 != -1, "expected special chain levels to exist for save repair checks")
	if not passed:
		_free_game(game)
		return false
	var sparse_completed: Array = []
	sparse_completed.resize(Defs.LEVELS.size())
	for i in range(sparse_completed.size()):
		sparse_completed[i] = false
	sparse_completed[index_3_10] = true
	var save_data = {
		"version": 2,
		"unlocked_levels": max(1, Defs.LEVELS.size() - 1),
		"completed_levels": sparse_completed,
		"completed_level_ids": ["3-10"],
		"last_level_index": index_3_10,
		"current_world_key": "pool",
	}
	var migrated = bool(game.call("_apply_loaded_save_data", save_data))
	passed = _assert_true(migrated, "suspicious sparse v2 saves should trigger automatic progress repair") and passed
	passed = _assert_true(bool(game.completed_levels[index_1_17]), "repaired near-end saves should restore the 1-17 prerequisite chain") and passed
	passed = _assert_true(bool(game.call("_is_level_unlocked", index_1_17)), "repaired near-end saves should keep 1-17 unlocked") and passed
	passed = _assert_true(bool(game.call("_is_level_unlocked", index_1_18)), "repaired near-end saves should keep 1-18 unlocked") and passed
	_free_game(game)
	return passed


func _test_inconsistent_blank_save_data_recovers_from_last_level_index() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_apply_loaded_save_data"), "expected _apply_loaded_save_data helper to exist for blank save recovery"):
		_free_game(game)
		return false
	var index_1_17 = _find_level_index("1-17")
	var index_1_18 = _find_level_index("1-18")
	var passed = _assert_true(index_1_17 != -1 and index_1_18 != -1, "expected late special levels to exist for blank save recovery checks")
	if not passed:
		_free_game(game)
		return false
	var blank_completed: Array = []
	blank_completed.resize(Defs.LEVELS.size())
	for i in range(blank_completed.size()):
		blank_completed[i] = false
	var save_data = {
		"version": 2,
		"unlocked_levels": 1,
		"completed_levels": blank_completed,
		"completed_level_ids": [],
		"last_level_index": Defs.LEVELS.size() - 1,
		"current_world_key": "day",
	}
	var migrated = bool(game.call("_apply_loaded_save_data", save_data))
	passed = _assert_true(migrated, "a blank v2 save with a late last_level_index should be treated as corrupted progress and repaired") and passed
	passed = _assert_true(bool(game.completed_levels[index_1_17]), "blank corrupted saves should restore late prerequisite progress") and passed
	passed = _assert_true(bool(game.call("_is_level_unlocked", index_1_18)), "blank corrupted saves should keep the final special level unlocked") and passed
	passed = _assert_true(game.unlocked_levels >= Defs.LEVELS.size() - 1, "blank corrupted saves should recover the unlocked level count from the last played level") and passed
	_free_game(game)
	return passed


func _test_loaded_campaign_init_does_not_force_immediate_autosave() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_finalize_campaign_init"), "expected _finalize_campaign_init helper to exist for save init behavior"):
		_free_game(game)
		return false
	game.save_dirty = false
	game.autosave_timer = 0.0
	game.call("_finalize_campaign_init", true, false)
	var passed = _assert_true(not bool(game.save_dirty), "successfully loading a save should not immediately mark the campaign dirty again") \
		and _assert_true(is_zero_approx(float(game.autosave_timer)), "successfully loading a save should not schedule an autosave writeback")
	game.call("_finalize_campaign_init", false, false)
	passed = _assert_true(bool(game.save_dirty), "starting from no save should still mark the campaign dirty for the first save write") and passed
	_free_game(game)
	return passed
