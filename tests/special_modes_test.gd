extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_endless_mode_preserves_custom_level_on_selection_start() or failed
	failed = not _test_endless_mode_does_not_autowin_before_spawning_waves() or failed
	failed = not _test_endless_mode_spawns_runtime_ready_zombies_after_warmup() or failed
	failed = not _test_endless_mode_uses_full_non_boss_zombie_pool_and_normal_spawn_edge() or failed
	failed = not _test_daily_challenge_enters_selection_and_waits_for_spawns() or failed
	failed = not _test_daily_challenge_supports_manual_card_clicks_before_start() or failed
	failed = not _test_daily_challenge_selection_preview_uses_valid_zombie_keys() or failed
	failed = not _test_selection_buttons_stay_visible_on_smaller_viewports() or failed
	failed = not _test_selection_layout_keeps_two_rows_visible_on_768p() or failed
	failed = not _test_selection_pool_recovery_uses_player_collection_fallback() or failed
	failed = not _test_custom_daily_levels_do_not_inherit_stage_specific_template_fields() or failed
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


func _click_selection_pool_cards(game: Control, count: int) -> void:
	for index in range(min(count, game.selection_pool_cards.size())):
		var card_rect: Rect2 = game.call("_selection_pool_rect", index)
		game.call("_handle_selection_click", card_rect.position + card_rect.size * 0.5)


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


func _test_endless_mode_spawns_runtime_ready_zombies_after_warmup() -> bool:
	var game := _make_game()
	game.call("_enter_endless_mode")
	var selection_pool: Array = game.selection_pool_cards.duplicate()
	if selection_pool.is_empty():
		selection_pool = game.call("_player_plant_collection")
		game.selection_pool_cards = selection_pool.duplicate()
	game.selection_cards = selection_pool.slice(0, 1)
	game.call("_handle_selection_click", game.PREP_START_RECT.position + game.PREP_START_RECT.size * 0.5)
	game._process(6.1)
	game._process(0.2)
	var passed = _assert_true(game.zombies.size() > 0, "endless mode should spawn zombies after the 6 second warmup") \
		and _assert_true(int(game.call("_enemy_zombie_count")) > 0, "spawned endless zombies should count as active enemies") \
		and _assert_true(int(game.zombies[0].get("uid", -1)) > 0, "endless zombies should use the full runtime spawn path and receive stable ids") \
		and _assert_true(float(game.zombies[0].get("base_speed", 0.0)) > 0.0, "endless zombies should include runtime speed data for movement")
	_free_game(game)
	return passed


func _test_endless_mode_uses_full_non_boss_zombie_pool_and_normal_spawn_edge() -> bool:
	var game := _make_game()
	var has_pool_helper = game.has_method("_endless_spawn_candidate_kinds")
	var has_spawn_helper = game.has_method("_normal_zombie_spawn_x")
	var passed = _assert_true(has_pool_helper, "endless mode should expose a helper for its candidate zombie pool so the full roster can be validated") \
		and _assert_true(has_spawn_helper, "endless mode should expose a helper for its normal spawn edge so custom waves do not drift off-screen")
	if passed:
		var kinds: Array = game.call("_endless_spawn_candidate_kinds")
		passed = _assert_true(kinds.has("dragon_boat"), "endless mode should include later-world custom zombies in its candidate roster") and passed
		passed = _assert_true(kinds.has("programmer_zombie"), "endless mode should include city-world zombies in its candidate roster") and passed
		passed = _assert_true(not kinds.has("rumia_boss") and not kinds.has("cirno_boss"), "endless mode should exclude boss units from the generic endless spawn roster") and passed
		var spawn_x = float(game.call("_normal_zombie_spawn_x"))
		var max_expected_x = game.BOARD_ORIGIN.x + game.board_size.x + 120.0
		passed = _assert_true(spawn_x <= max_expected_x, "endless mode should spawn near the regular right edge instead of far beyond the screen") and passed
	_free_game(game)
	return passed


func _test_daily_challenge_enters_selection_and_waits_for_spawns() -> bool:
	var game := _make_game()
	game.daily_challenge_date = game.call("_today_string")
	game.call("_enter_daily_challenge")
	var passed = _assert_true(game.mode == game.MODE_SELECTION, "daily challenge should open the seed selection screen") \
		and _assert_true(String(game.current_level.get("id", "")) == "每日", "daily challenge should build a custom level tagged as 每日") \
		and _assert_true(game.selection_pool_cards.size() > 0, "daily challenge should expose a usable plant pool") \
		and _assert_true(bool(game.daily_completed_today), "re-entering a finished daily challenge should mark the reward as already claimed instead of blocking entry")
	if passed:
		var required_count = int(game.call("_required_seed_count", game.current_level))
		game.selection_cards = game.selection_pool_cards.slice(0, max(required_count, 1))
		game.call("_handle_selection_click", game.PREP_START_RECT.position + game.PREP_START_RECT.size * 0.5)
		game.call("_check_end_state")
		game._process(2.3)
		game._process(0.1)
		passed = _assert_true(game.mode == game.MODE_BATTLE, "starting the daily challenge should enter battle mode") and passed
		passed = _assert_true(game.battle_state == game.BATTLE_PLAYING, "daily challenge should remain active instead of instantly auto-clearing before the first spawn batch") and passed
		passed = _assert_true(game.cell_terrain_mask.size() == game.ROWS, "daily challenge should initialize a visible board terrain mask before battle begins") and passed
		passed = _assert_true(game.zombies.size() > 0, "daily challenge should start spawning zombies once the battle clock advances") and passed
	_free_game(game)
	return passed


func _test_daily_challenge_supports_manual_card_clicks_before_start() -> bool:
	var game := _make_game()
	game.daily_challenge_date = game.call("_today_string")
	game.call("_enter_daily_challenge")
	var required_count = int(game.call("_required_seed_count", game.current_level))
	_click_selection_pool_cards(game, max(required_count, 1))
	var passed = _assert_true(game.selection_cards.size() == max(required_count, 1), "daily challenge manual clicks should populate the selected seed slots") \
		and _assert_true(String(game.selection_cards[0]) == String(game.selection_pool_cards[0]), "manual selection should preserve the clicked pool card kind")
	if passed:
		game.call("_handle_selection_click", game.PREP_START_RECT.position + game.PREP_START_RECT.size * 0.5)
		passed = _assert_true(game.mode == game.MODE_BATTLE, "daily challenge should enter battle mode after manually clicking cards and pressing start") and passed
		passed = _assert_true(game.active_cards.size() > 0 and String(game.active_cards[0]) != "", "daily challenge should carry the manually selected cards into battle") and passed
	_free_game(game)
	return passed


func _test_daily_challenge_selection_preview_uses_valid_zombie_keys() -> bool:
	var game := _make_game()
	game.daily_challenge_date = game.call("_today_string")
	game.call("_enter_daily_challenge")
	var passed := true
	for kind_variant in game.call("_selection_zombie_kinds"):
		var kind = String(kind_variant)
		passed = _assert_true(GameScript.Defs.ZOMBIES.has(kind), "daily challenge selection preview should only list zombies that exist in Defs.ZOMBIES, got %s" % kind) and passed
	_free_game(game)
	return passed


func _test_selection_buttons_stay_visible_on_smaller_viewports() -> bool:
	var game := _make_game()
	game.size = Vector2(1024.0, 620.0)
	var viewport_rect = Rect2(Vector2.ZERO, game.size)
	var passed = _assert_true(game.has_method("_selection_back_rect"), "selection scene should expose a back-button layout helper") \
		and _assert_true(game.has_method("_selection_start_rect"), "selection scene should expose a start-button layout helper")
	if passed:
		var back_rect: Rect2 = game.call("_selection_back_rect")
		var start_rect: Rect2 = game.call("_selection_start_rect")
		passed = _assert_true(viewport_rect.encloses(back_rect), "selection back button should stay inside the current viewport") and passed
		passed = _assert_true(viewport_rect.encloses(start_rect), "selection start button should stay inside the current viewport") and passed
		passed = _assert_true(start_rect.position.x > back_rect.position.x, "selection start button should remain to the right of the back button") and passed
	_free_game(game)
	return passed


func _test_selection_layout_keeps_two_rows_visible_on_768p() -> bool:
	var game := _make_game()
	game.size = Vector2(1365.0, 768.0)
	game.mode = game.MODE_SELECTION
	game.current_level = {"id": "layout-test", "terrain": "day", "events": [], "mode": ""}
	game.selection_pool_cards = [
		"peashooter", "sunflower", "cherry_bomb", "wallnut", "potato_mine", "snow_pea",
		"chomper", "repeater", "puff_shroom", "sun_shroom", "fume_shroom", "grave_buster",
	]
	var view_rect: Rect2 = game.call("_selection_pool_view_rect")
	var second_row_card_rect: Rect2 = game.call("_selection_pool_rect", 6)
	var passed = _assert_true(view_rect.encloses(second_row_card_rect), "selection layout should keep the second card row fully visible on a 1365x768 window")
	_free_game(game)
	return passed


func _test_selection_pool_recovery_uses_player_collection_fallback() -> bool:
	var game := _make_game()
	game.completed_levels[0] = true
	game.unlocked_levels = 2
	var level := {"id": "每日", "terrain": "day", "events": [], "mode": "", "available_plants": []}
	var passed = _assert_true(game.has_method("_resolved_selection_pool_for_level"), "selection flow should expose a pool recovery helper")
	if passed:
		var pool: Array = game.call("_resolved_selection_pool_for_level", level)
		passed = _assert_true(pool.size() > 0, "selection pool recovery should never leave the selection screen empty") and passed
		passed = _assert_true(String(pool[0]) == "peashooter", "selection pool recovery should at least fall back to the player's unlocked peashooter") and passed
	_free_game(game)
	return passed


func _test_custom_daily_levels_do_not_inherit_stage_specific_template_fields() -> bool:
	var game := _make_game()
	var roof_daily: Dictionary = game.call("_build_custom_level", "roof", "daily-roof-test", "Roof Daily", "desc", {})
	var fog_daily: Dictionary = game.call("_build_custom_level", "fog", "daily-fog-test", "Fog Daily", "desc", {})
	var passed = _assert_true(String(roof_daily.get("mode", "")) == "", "custom daily/endless levels should not inherit a stage mode from a campaign template") \
		and _assert_true(not roof_daily.has("preplaced_supports"), "custom daily/endless levels should not inherit pre-placed supports from campaign templates") \
		and _assert_true(not roof_daily.has("conveyor_plants"), "custom daily/endless levels should not inherit conveyor plant lists from campaign templates") \
		and _assert_true(not roof_daily.has("boss_kind"), "custom daily/endless levels should not inherit boss metadata from campaign templates") \
		and _assert_true(float(fog_daily.get("fog_columns", 0.0)) > 0.0, "fog custom levels should still preserve world-level fog density defaults after sanitization")
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
