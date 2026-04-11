extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_replaying_old_level_uses_current_progress_plant_pool() or failed
	failed = not _test_gacha_owned_plants_enter_persistent_plant_pool() or failed
	failed = not _test_gacha_owned_plants_enter_almanac() or failed
	failed = not _test_seed_selection_starts_empty_for_manual_pick() or failed
	failed = not _test_special_modes_keep_their_curated_plant_pools() or failed
	failed = not _test_branch_progress_does_not_unlock_future_pool_levels() or failed
	failed = not _test_sparse_v2_save_data_backfills_near_end_progress() or failed
	failed = not _test_inconsistent_blank_save_data_recovers_from_last_level_index() or failed
	failed = not _test_save_merge_preserves_stronger_existing_progress() or failed
	failed = not _test_save_merge_preserves_stronger_enhancement_progress() or failed
	failed = not _test_save_merge_preserves_gacha_collection_progress() or failed
	failed = not _test_loaded_enhance_progress_persists_into_battle_stats() or failed
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


func _completed_ids_for_user_progress() -> Array:
	var result: Array = []
	for level in Defs.LEVELS:
		var level_id = String(level.get("id", ""))
		if level_id.begins_with("1-") or level_id.begins_with("2-"):
			result.append(level_id)
			continue
		if level_id.begins_with("3-") and int(level_id.get_slice("-", 1)) <= 10:
			result.append(level_id)
	return result


func _completed_ids_through(level_id: String) -> Array:
	var result: Array = []
	for level in Defs.LEVELS:
		var current_id = String(level.get("id", ""))
		result.append(current_id)
		if current_id == level_id:
			break
	return result


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


func _test_gacha_owned_plants_enter_persistent_plant_pool() -> bool:
	var game = _make_game()
	game.plant_stars = {
		"shadow_pea": 1,
		"ice_queen": 2,
	}
	var collection: Array = game.call("_player_plant_collection")
	var passed = _assert_true(collection.has("shadow_pea"), "gacha-owned shadow_pea should enter the persistent plant pool") \
		and _assert_true(collection.has("ice_queen"), "gacha-owned ice_queen should enter the persistent plant pool") \
		and _assert_true(collection.has("peashooter"), "base peashooter should remain available alongside gacha plants")
	_free_game(game)
	return passed


func _test_gacha_owned_plants_enter_almanac() -> bool:
	var game = _make_game()
	game.plant_stars = {
		"shadow_pea": 1,
		"ice_queen": 2,
		"moonforge": 1,
	}
	var almanac_plants: Array = game.call("_visible_almanac_plants")
	var passed = _assert_true(almanac_plants.has("shadow_pea"), "gacha-owned shadow_pea should appear in the almanac plant list") \
		and _assert_true(almanac_plants.has("ice_queen"), "gacha-owned ice_queen should appear in the almanac plant list") \
		and _assert_true(almanac_plants.has("moonforge"), "gacha-owned moonforge should appear in the almanac plant list")
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


func _test_branch_progress_does_not_unlock_future_pool_levels() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_apply_loaded_save_data"), "expected _apply_loaded_save_data helper to exist for branch progress checks"):
		_free_game(game)
		return false
	var index_1_18 = _find_level_index("1-18")
	var index_3_11 = _find_level_index("3-11")
	var index_3_12 = _find_level_index("3-12")
	var passed = _assert_true(index_1_18 != -1 and index_3_11 != -1 and index_3_12 != -1, "expected 1-18, 3-11 and 3-12 to exist for branch progress checks")
	if not passed:
		_free_game(game)
		return false
	var migrated = bool(game.call("_apply_loaded_save_data", {
		"version": 2,
		"unlocked_levels": Defs.LEVELS.size(),
		"completed_level_ids": _completed_ids_for_user_progress(),
		"last_level_index": index_1_18,
		"current_world_key": "pool",
	}))
	var collection: Array = game.call("_player_plant_collection")
	passed = _assert_true(not migrated, "well-formed user progress should not trigger save migration") and passed
	passed = _assert_true(bool(game.call("_is_level_unlocked", index_3_11)), "completing 3-10 should unlock 3-11") and passed
	passed = _assert_true(not bool(game.call("_is_level_unlocked", index_3_12)), "completing 1-18 should not accidentally unlock 3-12") and passed
	passed = _assert_true(collection.has("moon_lotus"), "night-introduced moon_lotus should remain available in the persistent plant collection") and passed
	passed = _assert_true(not collection.has("boomerang_shooter"), "3-11 reward plants should stay locked until 3-11 is cleared") and passed
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


func _test_save_merge_preserves_stronger_existing_progress() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_merge_save_data_preserving_progress"), "expected save merge helper to exist for regression protection"):
		_free_game(game)
		return false
	var index_4_16 = _find_level_index("4-16")
	var index_4_17 = _find_level_index("4-17")
	var passed = _assert_true(index_4_16 != -1 and index_4_17 != -1, "expected late fog levels to exist for save merge checks")
	if not passed:
		_free_game(game)
		return false
	var existing_save = {
		"version": 2,
		"unlocked_levels": index_4_17 + 1,
		"completed_level_ids": _completed_ids_through("4-16"),
		"coins_total": 2500,
		"last_level_index": index_4_17,
		"current_world_key": "fog",
	}
	var stale_blank_save = {
		"version": 2,
		"unlocked_levels": 1,
		"completed_level_ids": [],
		"coins_total": 0,
		"last_level_index": _find_level_index("3-18"),
		"current_world_key": "day",
	}
	var merged: Dictionary = game.call("_merge_save_data_preserving_progress", existing_save, stale_blank_save)
	var merged_ids = merged.get("completed_level_ids", [])
	passed = _assert_true(merged_ids is Array and merged_ids.has("4-16"), "merged save should preserve existing completed progress up to 4-16") and passed
	passed = _assert_true(not merged_ids.has("4-17"), "merged save should keep 4-17 unfinished when only 4-16 was completed") and passed
	passed = _assert_true(int(merged.get("unlocked_levels", 0)) >= index_4_17 + 1, "merged save should keep 4-17 unlocked") and passed
	passed = _assert_true(String(merged.get("current_world_key", "")) == "fog", "merged save should keep the stronger world's map focus") and passed
	passed = _assert_true(int(merged.get("last_level_index", -1)) >= index_4_17, "merged save should keep the stronger last level index") and passed
	_free_game(game)
	return passed


func _test_save_merge_preserves_stronger_enhancement_progress() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_merge_save_data_preserving_progress"), "expected save merge helper to exist for enhancement merge checks"):
		_free_game(game)
		return false
	var existing_save = {
		"version": 2,
		"unlocked_levels": 12,
		"completed_level_ids": _completed_ids_through("1-10"),
		"coins_total": 1200,
		"last_level_index": _find_level_index("1-10"),
		"current_world_key": "day",
		"plant_enhance_levels": {"peashooter": 3, "wallnut": 1},
		"enhance_stones": 5,
	}
	var stale_candidate = {
		"version": 2,
		"unlocked_levels": 12,
		"completed_level_ids": _completed_ids_through("1-10"),
		"coins_total": 1200,
		"last_level_index": _find_level_index("1-10"),
		"current_world_key": "day",
		"plant_enhance_levels": {"peashooter": 1},
		"enhance_stones": 2,
	}
	var merged: Dictionary = game.call("_merge_save_data_preserving_progress", existing_save, stale_candidate)
	var merged_levels = merged.get("plant_enhance_levels", {})
	var passed = _assert_true(merged_levels is Dictionary and int(merged_levels.get("peashooter", 0)) == 3, "save merge should keep the stronger existing peashooter enhancement") \
		and _assert_true(int(merged_levels.get("wallnut", 0)) == 1, "save merge should keep enhancement entries missing from the stale candidate") \
		and _assert_true(int(merged.get("enhance_stones", 0)) == 5, "save merge should keep the stronger enhancement stone count")
	_free_game(game)
	return passed


func _test_save_merge_preserves_gacha_collection_progress() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_merge_save_data_preserving_progress"), "expected save merge helper to exist for gacha collection merge checks"):
		_free_game(game)
		return false
	var existing_save = {
		"version": 2,
		"unlocked_levels": 24,
		"completed_level_ids": _completed_ids_through("2-10"),
		"plant_stars": {"shadow_pea": 2, "ice_queen": 1},
		"plant_fragments": {"shadow_pea": 18, "ice_queen": 6},
		"gacha_pity_counter": 37,
		"endless_best_wave": 12,
	}
	var stale_candidate = {
		"version": 2,
		"unlocked_levels": 1,
		"completed_level_ids": [],
		"plant_stars": {"shadow_pea": 1},
		"plant_fragments": {"shadow_pea": 3},
		"gacha_pity_counter": 2,
		"endless_best_wave": 1,
	}
	var merged: Dictionary = game.call("_merge_save_data_preserving_progress", existing_save, stale_candidate)
	var merged_stars = merged.get("plant_stars", {})
	var merged_fragments = merged.get("plant_fragments", {})
	var passed = _assert_true(merged_stars is Dictionary and int(merged_stars.get("shadow_pea", 0)) == 2, "save merge should keep the stronger shadow_pea star count") \
		and _assert_true(int(merged_stars.get("ice_queen", 0)) == 1, "save merge should preserve owned gacha plants missing from the stale candidate") \
		and _assert_true(merged_fragments is Dictionary and int(merged_fragments.get("shadow_pea", 0)) == 18, "save merge should keep the stronger fragment count") \
		and _assert_true(int(merged_fragments.get("ice_queen", 0)) == 6, "save merge should preserve fragment entries missing from the stale candidate") \
		and _assert_true(int(merged.get("gacha_pity_counter", 0)) == 37, "save merge should keep the stronger pity counter") \
		and _assert_true(int(merged.get("endless_best_wave", 0)) == 12, "save merge should keep the stronger endless record")
	_free_game(game)
	return passed


func _test_loaded_enhance_progress_persists_into_battle_stats() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_apply_loaded_save_data"), "expected _apply_loaded_save_data helper to exist for enhancement persistence checks"):
		_free_game(game)
		return false
	game.call("_apply_loaded_save_data", {
		"version": 2,
		"unlocked_levels": 1,
		"completed_level_ids": [],
		"last_level_index": 0,
		"current_world_key": "day",
		"plant_enhance_levels": {"peashooter": 2},
		"enhance_stones": 4,
	})
	var plant: Dictionary = game.call("_create_plant", "peashooter", 2, 2)
	game.grid[2][2] = plant
	game.call("_spawn_zombie_at", "normal", 2, game._cell_center(2, 6).x)
	game.call("_update_plants", 0.6)
	var base_health = float(Defs.PLANTS["peashooter"]["health"])
	var base_damage = float(Defs.PLANTS["peashooter"]["damage"])
	var passed = _assert_true(int(game.plant_enhance_levels.get("peashooter", 0)) == 2, "loaded save data should keep peashooter enhancement levels") \
		and _assert_true(int(game.enhance_stones) == 4, "loaded save data should keep enhancement stones") \
		and _assert_true(float(game.grid[2][2]["max_health"]) > base_health, "loaded enhancement levels should permanently increase created plant health") \
		and _assert_true(game.projectiles.size() == 1, "enhanced peashooter should still fire normally after loading save data")
	if passed:
		passed = _assert_true(float(game.projectiles[0].get("damage", 0.0)) > base_damage, "loaded enhancement levels should permanently increase projectile damage in battle") and passed
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
