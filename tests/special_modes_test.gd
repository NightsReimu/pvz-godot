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
	failed = not _test_endless_bonus_offer_after_wave_clear_and_pauses_next_wave() or failed
	failed = not _test_endless_bonus_click_applies_choice_and_resumes_countdown() or failed
	failed = not _test_endless_bonus_resets_between_runs_and_fits_overlay() or failed
	failed = not _test_endless_bonus_does_not_affect_non_endless_levels() or failed
	failed = not _test_daily_mode_lists_weekday_series_and_many_stages() or failed
	failed = not _test_daily_home_opens_daily_terminal() or failed
	failed = not _test_daily_series_open_schedule_blocks_closed_stages() or failed
	failed = not _test_daily_open_stage_enters_selection() or failed
	failed = not _test_daily_challenge_enters_selection_and_waits_for_spawns() or failed
	failed = not _test_daily_challenge_supports_manual_card_clicks_before_start() or failed
	failed = not _test_daily_challenge_selection_preview_uses_valid_zombie_keys() or failed
	failed = not _test_special_zombies_are_cataloged_but_not_mainline() or failed
	failed = not _test_special_zombies_join_non_mainline_candidate_pools() or failed
	failed = not _test_selection_buttons_stay_visible_on_smaller_viewports() or failed
	failed = not _test_selection_pool_uses_wide_desktop_rows() or failed
	failed = not _test_selection_layout_keeps_two_rows_visible_on_768p() or failed
	failed = not _test_selection_third_row_right_card_does_not_trigger_legacy_back() or failed
	failed = not _test_almanac_plant_grid_fits_four_rows_without_clipping() or failed
	failed = not _test_mobile_selection_layout_stays_inside_small_landscape_viewport() or failed
	failed = not _test_mobile_selection_scene_skips_legacy_global_ui_scaling() or failed
	failed = not _test_mobile_portrait_world_select_shows_rotate_prompt() or failed
	failed = not _test_mobile_landscape_world_select_hides_rotate_prompt() or failed
	failed = not _test_mobile_landscape_world_select_uses_full_width_scaling() or failed
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
	game.save_dirty = false
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


func _click_selection_start(game: Control) -> void:
	var start_rect: Rect2 = game.call("_selection_start_rect")
	game.call("_handle_selection_click", start_rect.get_center())


func _first_open_daily_pick(game: Control) -> Dictionary:
	var weekday = int(game.call("_current_weekday"))
	var series_defs: Array = game.call("_daily_series_defs")
	for series_variant in series_defs:
		var series := Dictionary(series_variant)
		if bool(game.call("_daily_series_open_on_weekday", series, weekday)):
			return {"series_id": String(series.get("id", "")), "stage_index": 0}
	return {"series_id": String(Dictionary(series_defs[0]).get("id", "")), "stage_index": 0}


func _special_non_mainline_zombie_kinds() -> Array[String]:
	return [
		"medic_zombie",
		"shieldbearer_zombie",
		"saboteur_zombie",
		"rift_zombie",
		"bomber_zombie",
	]


func _events_contain_any_kind(events: Array, kinds: Array[String]) -> bool:
	for event_variant in events:
		var event := Dictionary(event_variant)
		var kind = String(event.get("kind", ""))
		if kinds.has(kind):
			return true
	return false


func _test_endless_mode_preserves_custom_level_on_selection_start() -> bool:
	var game := _make_game()
	game.call("_enter_endless_mode")
	var selection_pool: Array = game.selection_pool_cards.duplicate()
	if selection_pool.is_empty():
		selection_pool = game.call("_player_plant_collection")
		game.selection_pool_cards = selection_pool.duplicate()
	var required_count = int(game.call("_required_seed_count", game.current_level))
	game.selection_cards = selection_pool.slice(0, max(required_count, 1))
	_click_selection_start(game)
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
	_click_selection_start(game)
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
	_click_selection_start(game)
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


func _prepare_endless_bonus_clear_state(game: Control) -> void:
	game.mode = game.MODE_BATTLE
	game.current_level = {"id": "无尽", "terrain": "day", "events": [], "title": "无尽", "start_sun": 250, "sky_sun_range": Vector2(999.0, 999.0)}
	game.battle_state = game.BATTLE_PLAYING
	game.endless_wave = 1
	game.endless_wave_active = true
	game.endless_wave_timer = 0.0
	game.zombies = []


func _test_endless_bonus_offer_after_wave_clear_and_pauses_next_wave() -> bool:
	var game := _make_game()
	_prepare_endless_bonus_clear_state(game)
	var passed = _assert_true(game.has_method("_endless_bonus_defs"), "endless mode should expose bonus definitions for tests and UI") \
		and _assert_true(game.has_method("_offer_endless_bonus_choices"), "endless mode should expose a helper that offers three bonus choices")
	game.call("_update_endless", 0.1)
	passed = _assert_true(game.endless_bonus_pending, "clearing an endless wave should pause on a pending bonus choice") and passed
	var choices: Array = game.endless_bonus_choices
	passed = _assert_true(choices.size() == 3, "endless wave clear should offer exactly three bonus choices") and passed
	var seen := {}
	var defs := Dictionary(game.call("_endless_bonus_defs")) if game.has_method("_endless_bonus_defs") else {}
	for choice_variant in choices:
		var choice = String(choice_variant)
		passed = _assert_true(defs.has(choice), "endless bonus choice %s should exist in the bonus definition table" % choice) and passed
		passed = _assert_true(not seen.has(choice), "endless bonus choices should not repeat within one offer") and passed
		seen[choice] = true
	var wave_before = int(game.endless_wave)
	game.call("_update_endless", 10.0)
	passed = _assert_true(int(game.endless_wave) == wave_before, "pending endless bonus choices should stop the next wave countdown") and passed
	passed = _assert_true(not game.endless_wave_active, "pending endless bonus choices should keep the next wave inactive") and passed
	_free_game(game)
	return passed


func _test_endless_bonus_click_applies_choice_and_resumes_countdown() -> bool:
	var game := _make_game()
	_prepare_endless_bonus_clear_state(game)
	game.call("_update_endless", 0.1)
	var choices: Array = game.endless_bonus_choices
	var passed = _assert_true(choices.size() == 3, "test setup should have three endless bonus choices to click")
	if passed:
		game.endless_bonus_choices = ["plant_damage", "instant_sun", "plant_food"]
		var first_rect: Rect2 = game.call("_endless_bonus_card_rect", 0)
		game.call("_handle_endless_bonus_click", first_rect.get_center())
		passed = _assert_true(not game.endless_bonus_pending, "clicking an endless bonus should clear the pending choice state") and passed
		passed = _assert_true(int(game.endless_bonus_levels.get("plant_damage", 0)) == 1, "clicking plant damage should add one run-local bonus stack") and passed
		passed = _assert_true(float(game.call("_endless_bonus_value", "plant_damage")) > 0.0, "stacked plant damage should produce a positive multiplier contribution") and passed
		game.call("_update_endless", 6.1)
		passed = _assert_true(int(game.endless_wave) == 2, "after selecting a bonus, the next endless wave countdown should resume") and passed
	_prepare_endless_bonus_clear_state(game)
	game.endless_bonus_choices = ["instant_sun", "plant_food", "plant_damage"]
	game.endless_bonus_pending = true
	game.sun_points = 25
	game.call("_handle_endless_bonus_click", game.call("_endless_bonus_card_rect", 0).get_center())
	passed = _assert_true(game.sun_points > 25, "instant sun endless bonus should grant sun immediately") and passed
	_free_game(game)
	return passed


func _test_endless_bonus_resets_between_runs_and_fits_overlay() -> bool:
	var game := _make_game()
	game.endless_bonus_levels = {"plant_damage": 2, "attack_speed": 1}
	game.endless_bonus_choices = ["plant_damage", "instant_sun", "plant_food"]
	game.endless_bonus_pending = true
	game.call("_enter_endless_mode")
	var passed = _assert_true(game.endless_bonus_levels.is_empty(), "entering endless mode should reset run-local bonus stacks") \
		and _assert_true(game.endless_bonus_choices.is_empty(), "entering endless mode should clear stale bonus choices") \
		and _assert_true(not game.endless_bonus_pending, "entering endless mode should clear pending bonus state")
	game.size = Vector2(1600.0, 900.0)
	var viewport_rect := Rect2(Vector2.ZERO, game.size)
	var previous_rect := Rect2()
	for index in range(3):
		var rect: Rect2 = game.call("_endless_bonus_card_rect", index)
		passed = _assert_true(viewport_rect.encloses(rect), "endless bonus card %d should fit inside the viewport" % index) and passed
		if index > 0:
			passed = _assert_true(not previous_rect.intersects(rect), "endless bonus cards should not overlap each other") and passed
		previous_rect = rect
	_free_game(game)
	return passed


func _test_endless_bonus_does_not_affect_non_endless_levels() -> bool:
	var game := _make_game()
	game.mode = game.MODE_BATTLE
	game.current_level = {"id": "1-test", "terrain": "day", "events": [], "title": "主线", "start_sun": 250, "sky_sun_range": Vector2(999.0, 999.0)}
	game.endless_bonus_levels = {"plant_damage": 3, "attack_speed": 2, "cheap_seeds": 2}
	var base_damage = float(GameScript.Defs.PLANTS["peashooter"].get("damage", 20.0))
	var stats: Dictionary = game.call("_enhanced_plant_stats", "peashooter")
	var passed = _assert_true(is_equal_approx(float(stats.get("damage", 0.0)), base_damage), "run-local endless bonuses should not change plant stats outside endless mode")
	_free_game(game)
	return passed


func _test_daily_mode_lists_weekday_series_and_many_stages() -> bool:
	var game := _make_game()
	var series_defs: Array = game.call("_daily_series_defs")
	var passed = _assert_true(series_defs.size() >= 5, "daily terminal should expose multiple resource series") \
		and _assert_true(game.has_method("_daily_stage_defs_for_series"), "daily terminal should expose stage definitions per series") \
		and _assert_true(game.has_method("_daily_series_open_on_weekday"), "daily terminal should expose weekday availability checks")
	for series_variant in series_defs:
		var series := Dictionary(series_variant)
		var stages: Array = game.call("_daily_stage_defs_for_series", series)
		passed = _assert_true(stages.size() >= 5, "daily series %s should contain a stack of stages" % String(series.get("id", ""))) and passed
		passed = _assert_true(Array(series.get("open_days", [])).size() >= 3, "daily series %s should list weekday openings" % String(series.get("id", ""))) and passed
		passed = _assert_true(not String(series.get("reward", "")).is_empty(), "daily series %s should declare its reward identity" % String(series.get("id", ""))) and passed
	_free_game(game)
	return passed


func _test_daily_home_opens_daily_terminal() -> bool:
	var game := _make_game()
	var daily_rect: Rect2 = Dictionary(game.call("_home_action_rects"))["daily"]
	game.call("_handle_home_click", daily_rect.get_center())
	var passed = _assert_true(game.mode == game.MODE_DAILY, "home daily entry should open the daily terminal instead of immediately starting a random fight")
	_free_game(game)
	return passed


func _test_daily_series_open_schedule_blocks_closed_stages() -> bool:
	var game := _make_game()
	var series_defs: Array = game.call("_daily_series_defs")
	var series := Dictionary(series_defs[0])
	var open_days: Array = Array(series.get("open_days", []))
	var open_weekday := int(open_days[0])
	var closed_weekday := -1
	for weekday in range(7):
		if not open_days.has(weekday):
			closed_weekday = weekday
			break
	var passed = _assert_true(closed_weekday != -1, "daily series should have at least one closed weekday") \
		and _assert_true(bool(game.call("_daily_series_open_on_weekday", series, open_weekday)), "daily series should be open on configured weekdays") \
		and _assert_true(not bool(game.call("_daily_series_open_on_weekday", series, closed_weekday)), "daily series should block non-configured weekdays")
	if passed:
		var started_closed = bool(game.call("_try_enter_daily_challenge", String(series.get("id", "")), 0, closed_weekday))
		passed = _assert_true(not started_closed, "closed daily stages should not enter seed selection") and passed
		passed = _assert_true(game.mode != game.MODE_SELECTION, "closed daily stages should keep the player in the terminal") and passed
	_free_game(game)
	return passed


func _test_daily_open_stage_enters_selection() -> bool:
	var game := _make_game()
	var series_defs: Array = game.call("_daily_series_defs")
	var series := Dictionary(series_defs[0])
	var open_weekday := int(Array(series.get("open_days", []))[0])
	var started = bool(game.call("_try_enter_daily_challenge", String(series.get("id", "")), 1, open_weekday))
	var passed = _assert_true(started, "open daily stages should be launchable") \
		and _assert_true(game.mode == game.MODE_SELECTION, "open daily stages should enter seed selection") \
		and _assert_true(bool(game.current_level.get("daily_level", false)), "daily stage level data should be marked as daily") \
		and _assert_true(String(game.current_level.get("daily_series_id", "")) == String(series.get("id", "")), "daily stage should remember its series id") \
		and _assert_true(int(game.current_level.get("daily_stage_index", -1)) == 1, "daily stage should remember its stage index")
	_free_game(game)
	return passed


func _test_daily_challenge_enters_selection_and_waits_for_spawns() -> bool:
	var game := _make_game()
	var pick := _first_open_daily_pick(game)
	game.call("_enter_daily_challenge", String(pick["series_id"]), int(pick["stage_index"]))
	var passed = _assert_true(game.mode == game.MODE_SELECTION, "daily challenge should open the seed selection screen") \
		and _assert_true(bool(game.current_level.get("daily_level", false)), "daily challenge should build a custom daily level") \
		and _assert_true(String(game.current_level.get("id", "")).begins_with("daily:"), "daily challenge should use a stable daily id") \
		and _assert_true(game.selection_pool_cards.size() > 0, "daily challenge should expose a usable plant pool")
	if passed:
		var required_count = int(game.call("_required_seed_count", game.current_level))
		game.selection_cards = game.selection_pool_cards.slice(0, max(required_count, 1))
		_click_selection_start(game)
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
	var pick := _first_open_daily_pick(game)
	game.call("_enter_daily_challenge", String(pick["series_id"]), int(pick["stage_index"]))
	var required_count = int(game.call("_required_seed_count", game.current_level))
	_click_selection_pool_cards(game, max(required_count, 1))
	var passed = _assert_true(game.selection_cards.size() == max(required_count, 1), "daily challenge manual clicks should populate the selected seed slots") \
		and _assert_true(String(game.selection_cards[0]) == String(game.selection_pool_cards[0]), "manual selection should preserve the clicked pool card kind")
	if passed:
		_click_selection_start(game)
		passed = _assert_true(game.mode == game.MODE_BATTLE, "daily challenge should enter battle mode after manually clicking cards and pressing start") and passed
		passed = _assert_true(game.active_cards.size() > 0 and String(game.active_cards[0]) != "", "daily challenge should carry the manually selected cards into battle") and passed
	_free_game(game)
	return passed


func _test_daily_challenge_selection_preview_uses_valid_zombie_keys() -> bool:
	var game := _make_game()
	var pick := _first_open_daily_pick(game)
	game.call("_enter_daily_challenge", String(pick["series_id"]), int(pick["stage_index"]))
	var passed := true
	for kind_variant in game.call("_selection_zombie_kinds"):
		var kind = String(kind_variant)
		passed = _assert_true(GameScript.Defs.ZOMBIES.has(kind), "daily challenge selection preview should only list zombies that exist in Defs.ZOMBIES, got %s" % kind) and passed
	_free_game(game)
	return passed


func _test_special_zombies_are_cataloged_but_not_mainline() -> bool:
	var game := _make_game()
	var special_kinds := _special_non_mainline_zombie_kinds()
	var almanac_order: Array = game.ZOMBIE_ALMANAC_ORDER
	var expected_keywords := {
		"medic_zombie": ["治疗", "回复"],
		"shieldbearer_zombie": ["护盾", "盾"],
		"saboteur_zombie": ["破坏", "啃咬"],
		"rift_zombie": ["闪现", "裂隙"],
		"bomber_zombie": ["爆炸", "范围"],
	}
	var passed := true
	for kind in special_kinds:
		passed = _assert_true(GameScript.Defs.ZOMBIES.has(kind), "special zombie %s should exist in Defs.ZOMBIES" % kind) and passed
		passed = _assert_true(almanac_order.has(kind), "special zombie %s should appear in the zombie almanac order" % kind) and passed
		var stats: Array = game.call("_zombie_almanac_stats", kind)
		var joined := " ".join(stats)
		var has_keyword := false
		for keyword in Array(expected_keywords[kind]):
			if joined.find(String(keyword)) != -1:
				has_keyword = true
				break
		passed = _assert_true(has_keyword, "special zombie %s almanac stats should describe its mechanic, got: %s" % [kind, joined]) and passed
	for level_variant in GameScript.Defs.LEVELS:
		var level := Dictionary(level_variant)
		var events: Array = Array(level.get("events", []))
		passed = _assert_true(not _events_contain_any_kind(events, special_kinds), "mainline level %s should not schedule non-mainline special zombies" % String(level.get("id", ""))) and passed
	_free_game(game)
	return passed


func _test_special_zombies_join_non_mainline_candidate_pools() -> bool:
	var game := _make_game()
	var special_kinds := _special_non_mainline_zombie_kinds()
	var passed := true
	var endless_kinds: Array = game.call("_endless_spawn_candidate_kinds")
	for kind in special_kinds:
		passed = _assert_true(endless_kinds.has(kind), "endless candidate pool should include special zombie %s" % kind) and passed
	passed = _assert_true(not endless_kinds.has("day_boss") and not endless_kinds.has("city_boss"), "endless candidate pool should still exclude boss zombies") and passed

	var found_daily_special := false
	for series_variant in game.call("_daily_series_defs"):
		var series := Dictionary(series_variant)
		var stages: Array = game.call("_daily_stage_defs_for_series", series)
		for stage_variant in stages:
			var stage := Dictionary(stage_variant)
			if int(stage.get("difficulty", 1)) < 4:
				continue
			var events: Array = game.call("_build_daily_stage_events", series, stage, 20260620)
			if _events_contain_any_kind(events, special_kinds):
				found_daily_special = true
				break
		if found_daily_special:
			break
	passed = _assert_true(found_daily_special, "daily high difficulty stages should be able to schedule non-mainline special zombies") and passed
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


func _test_selection_pool_uses_wide_desktop_rows() -> bool:
	var game := _make_game()
	game.size = Vector2(1600.0, 900.0)
	game.mode = game.MODE_SELECTION
	game.current_level = {"id": "wide-layout-test", "terrain": "day", "events": [], "mode": ""}
	game.selection_pool_cards = game.call("_player_plant_collection")
	var columns = int(game.call("_selection_pool_columns"))
	var passed = _assert_true(columns >= 8, "wide desktop selection pool should use more cards per row instead of leaving a large blank area on the right; got %d columns" % columns)
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


func _test_selection_third_row_right_card_does_not_trigger_legacy_back() -> bool:
	var game := _make_game()
	game.size = Vector2(1600.0, 900.0)
	game.mode = game.MODE_SELECTION
	game.current_level = {"id": "legacy-hit-test", "terrain": "day", "events": [], "mode": ""}
	game.selection_pool_cards = [
		"peashooter", "sunflower", "cherry_bomb", "wallnut", "potato_mine", "snow_pea",
		"chomper", "repeater", "puff_shroom", "sun_shroom", "fume_shroom", "grave_buster",
		"hypno_shroom", "scaredy_shroom", "ice_shroom", "doom_shroom", "moon_lotus", "prism_grass",
		"lantern_bloom", "meteor_gourd", "root_snare", "thunder_pine", "dream_drum", "lily_pad",
		"squash", "threepeater", "tangle_kelp", "jalapeno", "spikeweed", "torchwood",
	]
	game.selection_cards = []
	var columns = int(game.call("_selection_pool_columns"))
	var legacy_buttons = [game.PREP_BACK_RECT, game.PREP_START_RECT]
	var target_index := -1
	var click_pos := Vector2.ZERO
	for index in range(game.selection_pool_cards.size()):
		var row = int(floor(float(index) / float(max(columns, 1))))
		if row != 2:
			continue
		var card_rect: Rect2 = game.call("_selection_pool_rect", index)
		for legacy_rect in legacy_buttons:
			var x1 = maxf(card_rect.position.x, Rect2(legacy_rect).position.x)
			var y1 = maxf(card_rect.position.y, Rect2(legacy_rect).position.y)
			var x2 = minf(card_rect.end.x, Rect2(legacy_rect).end.x)
			var y2 = minf(card_rect.end.y, Rect2(legacy_rect).end.y)
			if x2 > x1 and y2 > y1:
				target_index = index
				click_pos = Vector2((x1 + x2) * 0.5, (y1 + y2) * 0.5)
				break
		if target_index != -1:
			break
	var passed = _assert_true(target_index != -1, "test setup should find a third-row card overlapping the old legacy button band")
	if passed:
		var expected_kind = String(game.selection_pool_cards[target_index])
		game.call("_handle_selection_click", click_pos)
		passed = _assert_true(game.mode == game.MODE_SELECTION, "clicking a third-row card near the right side should stay on the selection screen instead of returning to the map") and passed
		passed = _assert_true(game.selection_cards.has(expected_kind), "clicking the third-row card should select that plant instead of hitting a hidden legacy button") and passed
	_free_game(game)
	return passed


func _test_almanac_plant_grid_fits_four_rows_without_clipping() -> bool:
	var game := _make_game()
	game.mode = game.MODE_WORLD_SELECT
	game.plant_stars = {}
	for i in range(16):
		game.plant_stars[String(GameScript.Defs.PLANT_ORDER[i])] = 1
	game.call("_enter_almanac_mode", "plants")
	var view_rect: Rect2 = game.call("_almanac_list_view_rect")
	var fourth_row_last_card: Rect2 = game.call("_almanac_item_rect", 15)
	var passed = _assert_true(view_rect.encloses(fourth_row_last_card), "plant almanac should fit four complete rows in the list view without clipping the last row") \
		and _assert_true(float(game.call("_almanac_max_scroll")) == 0.0, "exactly four almanac rows should not require scrolling")
	_free_game(game)
	return passed


func _test_mobile_selection_layout_stays_inside_small_landscape_viewport() -> bool:
	var game := _make_game()
	game.mobile_runtime_override = 1
	game.size = Vector2(896.0, 414.0)
	game.mode = game.MODE_SELECTION
	game.current_level = {"id": "mobile-layout-test", "terrain": "day", "events": [], "mode": ""}
	game.selection_pool_cards = game.call("_player_plant_collection")
	var viewport_rect := Rect2(Vector2.ZERO, game.size)
	var selected_rect: Rect2 = game.call("_selection_selected_panel_rect")
	var zombie_rect: Rect2 = game.call("_selection_zombie_panel_rect")
	var pool_rect: Rect2 = game.call("_selection_pool_panel_rect")
	var back_rect: Rect2 = game.call("_selection_back_rect")
	var start_rect: Rect2 = game.call("_selection_start_rect")
	var second_row_card_rect: Rect2 = game.call("_selection_pool_rect", 4)
	var pool_view_rect: Rect2 = game.call("_selection_pool_view_rect")
	var passed = _assert_true(viewport_rect.encloses(selected_rect), "mobile selection top panel should stay inside a short landscape viewport") \
		and _assert_true(viewport_rect.encloses(zombie_rect), "mobile selection zombie preview should stay inside a short landscape viewport") \
		and _assert_true(viewport_rect.encloses(pool_rect), "mobile selection plant pool should stay inside a short landscape viewport") \
		and _assert_true(viewport_rect.encloses(back_rect), "mobile selection back button should stay inside a short landscape viewport") \
		and _assert_true(viewport_rect.encloses(start_rect), "mobile selection start button should stay inside a short landscape viewport") \
		and _assert_true(pool_view_rect.intersects(second_row_card_rect), "mobile selection should still expose more than one row of cards on a short landscape screen")
	_free_game(game)
	return passed


func _test_mobile_selection_scene_skips_legacy_global_ui_scaling() -> bool:
	var game := _make_game()
	game.mobile_runtime_override = 1
	game.size = Vector2(896.0, 414.0)
	game.mode = game.MODE_SELECTION
	var sample = Vector2(240.0, 160.0)
	var local = Vector2(game.call("_scene_local_position", sample))
	var passed = _assert_true(local.is_equal_approx(sample), "mobile selection should use viewport-space coordinates directly instead of applying the desktop global UI scale a second time")
	_free_game(game)
	return passed


func _test_mobile_portrait_world_select_shows_rotate_prompt() -> bool:
	var game := _make_game()
	game.mobile_runtime_override = 1
	game.size = Vector2(390.0, 844.0)
	game.mode = game.MODE_WORLD_SELECT
	var passed = _assert_true(bool(game.call("_should_show_mobile_rotate_prompt", game.MODE_WORLD_SELECT)), "portrait mobile world select should show a rotate-device prompt instead of rendering the desktop layout shrunken at the bottom")
	_free_game(game)
	return passed


func _test_mobile_landscape_world_select_hides_rotate_prompt() -> bool:
	var game := _make_game()
	game.mobile_runtime_override = 1
	game.size = Vector2(844.0, 390.0)
	game.mode = game.MODE_WORLD_SELECT
	var passed = _assert_true(not bool(game.call("_should_show_mobile_rotate_prompt", game.MODE_WORLD_SELECT)), "landscape mobile world select should render normally without the rotate-device prompt")
	_free_game(game)
	return passed


func _test_mobile_landscape_world_select_uses_full_width_scaling() -> bool:
	# v1.0.28: FILL non-uniform scaling was removed because it distorted menus on
	# non-16:9 phones (a 20:9 screen stretched X ~25% more than Y). Landscape menus
	# now scale UNIFORMLY (no distortion) and center; widescreen sides are covered
	# by the full-viewport backdrop, not by stretching content.
	var game := _make_game()
	game.mobile_runtime_override = 1
	game.size = Vector2(844.0, 390.0)  # ~19.5:9 landscape phone
	game.mode = game.MODE_WORLD_SELECT
	var scale = Vector2(game.call("_ui_scale_vector", game.MODE_WORLD_SELECT))
	var passed = _assert_true(absf(scale.x - scale.y) < 0.0001, "landscape mobile world select must scale uniformly (no X/Y distortion); got x=%.4f y=%.4f" % [scale.x, scale.y])
	passed = _assert_true(not bool(game.call("_uses_mobile_fill_ui_scaling", game.MODE_WORLD_SELECT)), "FILL non-uniform scaling must stay disabled") and passed
	var offset = Vector2(game.call("_ui_offset"))
	# 844/1600=0.5275, 390/900=0.4333 → uniform=0.4333; content width=1600*0.4333=693 → left margin=(844-693)/2≈75
	passed = _assert_true(offset.x > 1.0, "uniformly-scaled menu should be horizontally centered (positive margin), got x=%.2f" % offset.x) and passed
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
	var profile: Dictionary = game.call("_plant_enhance_profile", "peashooter")
	game.enhance_materials = {String(profile.get("material", "")): 1}
	var button_center: Vector2 = game.call("_enhance_button_rect").get_center()
	game.call("_handle_enhance_click", button_center)
	var passed = _assert_true(String(game.enhance_selected_plant) == "peashooter", "clicking the enhance button should not select an invisible plant cell underneath the side panel") \
		and _assert_true(int(game.plant_enhance_levels.get("peashooter", 0)) == 1, "clicking the enhance button should actually enhance the selected plant")
	_free_game(game)
	return passed
