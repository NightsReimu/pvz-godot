extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_special_day_level_unlock_requires_2_10() or failed
	failed = not _test_winning_3_10_keeps_map_on_pool_world() or failed
	failed = not _test_rumia_level_is_conveyor_and_excludes_noncombat_plants() or failed
	failed = not _test_rumia_assets_present() or failed
	failed = not _test_rumia_bgm_streams_loop() or failed
	failed = not _test_rumia_draw_scale_is_compact() or failed
	failed = not _test_boss_health_bar_uses_five_segments_at_bottom() or failed
	failed = not _test_rumia_day_map_requires_horizontal_scroll() or failed
	failed = not _test_bosses_cannot_be_hypnotized() or failed
	failed = not _test_rumia_hover_cadence_is_randomized_and_not_too_fast() or failed
	failed = not _test_rumia_boss_hovers_without_advancing() or failed
	failed = not _test_rumia_boss_summon_skill_spawns_reinforcements() or failed
	failed = not _test_rumia_boss_keeps_spawning_right_side_pressure() or failed
	failed = not _test_rumia_row_shift_enters_motion_state() or failed
	failed = not _test_rumia_skill_effects_use_animated_shapes() or failed
	failed = not _test_rumia_idle_animation_stays_stable_without_skill_or_movement() or failed
	failed = not _test_legacy_save_data_migrates_sparse_progress_using_level_ids() or failed
	failed = not _test_touhou_boss_sprites_are_prebaked_left_without_runtime_flip() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _find_level_index(level_id: String) -> int:
	for i in range(Defs.LEVELS.size()):
		if String(Defs.LEVELS[i]["id"]) == level_id:
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


func _test_special_day_level_unlock_requires_2_10() -> bool:
	var day_special_index = _find_level_index("1-17")
	var prereq_index = _find_level_index("2-10")
	if not _assert_true(day_special_index != -1, "expected special level 1-17 to exist"):
		return false
	if not _assert_true(prereq_index != -1, "expected prerequisite level 2-10 to exist"):
		return false
	var game = _make_game()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	game.unlocked_levels = Defs.LEVELS.size()
	if not _assert_true(game.has_method("_is_level_unlocked"), "expected _is_level_unlocked helper to exist for special unlock rules"):
		game.free()
		return false
	var locked_before = bool(game.call("_is_level_unlocked", day_special_index))
	game.completed_levels[prereq_index] = true
	var unlocked_after = bool(game.call("_is_level_unlocked", day_special_index))
	var passed = _assert_true(not locked_before, "1-17 should stay locked before 2-10 is completed") \
		and _assert_true(unlocked_after, "1-17 should unlock after 2-10 is completed")
	_free_game(game)
	return passed


func _test_winning_3_10_keeps_map_on_pool_world() -> bool:
	var level_index = _find_level_index("3-10")
	if not _assert_true(level_index != -1, "expected pool level 3-10 to exist for map return regression"):
		return false
	var game = _make_game()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	game.selected_level_index = level_index
	game.current_level = Defs.LEVELS[level_index]
	game.current_world_key = "pool"
	game.unlocked_levels = level_index + 1
	game.battle_state = game.BATTLE_PLAYING
	game.call("_win_level")
	var passed = _assert_true(game.battle_state == game.BATTLE_WON, "winning 3-10 should still mark the battle as won") \
		and _assert_true(bool(game.completed_levels[level_index]), "winning 3-10 should mark the level as completed") \
		and _assert_true(game.current_world_key == "pool", "winning 3-10 should keep the player on the pool world map instead of jumping to day")
	_free_game(game)
	return passed


func _test_rumia_level_is_conveyor_and_excludes_noncombat_plants() -> bool:
	var day_special_index = _find_level_index("1-17")
	if not _assert_true(day_special_index != -1, "expected special level 1-17 to exist"):
		return false
	var level = Defs.LEVELS[day_special_index]
	var sun_producer_kinds := {}
	for kind in Defs.PLANTS.keys():
		if float(Defs.PLANTS[kind].get("sun_interval", 0.0)) > 0.0:
			sun_producer_kinds[String(kind)] = true
	var passed = _assert_true(String(level.get("mode", "")) == "conveyor", "1-17 should be a conveyor level") \
		and _assert_true(bool(level.get("boss_level", false)), "1-17 should be a boss level")
	for list_name in ["available_plants", "conveyor_plants"]:
		for kind in level.get(list_name, []):
			var plant_kind = String(kind)
			passed = _assert_true(plant_kind != "grave_buster", "1-17 should not include grave_buster in %s" % list_name) and passed
			passed = _assert_true(not sun_producer_kinds.has(plant_kind), "1-17 should not include sun producers in %s" % list_name) and passed
	return passed


func _test_rumia_assets_present() -> bool:
	var required_paths = [
		"res://audio/rumia_intro.mp3",
		"res://audio/rumia_boss.mp3",
	]
	for frame_index in range(8):
		required_paths.append("res://art/rumia/frame_%02d.png" % frame_index)
	var passed := true
	for path in required_paths:
		var absolute_path = ProjectSettings.globalize_path(path)
		passed = _assert_true(FileAccess.file_exists(absolute_path), "expected rumia asset to exist: %s" % path) and passed
	return passed


func _test_rumia_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/rumia_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/rumia_boss.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "rumia intro BGM should load as an AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "rumia boss BGM should load as an AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "rumia intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "rumia boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_rumia_draw_scale_is_compact() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_rumia_draw_scale"), "expected _rumia_draw_scale helper to exist"):
		_free_game(game)
		return false
	var scale = float(game.call("_rumia_draw_scale", 0))
	var late_phase_scale = float(game.call("_rumia_draw_scale", 3))
	var passed = _assert_true(scale > 0.0, "rumia draw scale should stay positive") \
		and _assert_true(scale <= 0.32, "rumia draw scale should stay compact enough to avoid covering the lane") \
		and _assert_true(late_phase_scale <= 0.32, "rumia late phase draw scale should still stay compact")
	_free_game(game)
	return passed


func _test_boss_health_bar_uses_five_segments_at_bottom() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_boss_health_bar_layout"), "expected _boss_health_bar_layout helper to exist"):
		_free_game(game)
		return false
	var boss = {
		"kind": "rumia_boss",
		"health": 12800.0,
		"max_health": 12800.0,
	}
	var layout = game.call("_boss_health_bar_layout", boss)
	var passed = _assert_true(layout is Dictionary, "boss health bar layout should be returned as a dictionary")
	if layout is Dictionary:
		passed = _assert_true(int(layout.get("segments", 0)) == 5, "boss health bar should use five segments") and passed
		passed = _assert_true(float(layout.get("rect_y", 0.0)) > game.BOARD_ORIGIN.y + game.board_size.y, "boss health bar should be drawn below the battlefield") and passed
		passed = _assert_true(float(layout.get("rect_y", 0.0)) <= game.BOARD_ORIGIN.y + game.board_size.y + 48.0, "boss health bar should stay close to the very bottom of the battlefield") and passed
	_free_game(game)
	return passed


func _test_rumia_day_map_requires_horizontal_scroll() -> bool:
	var game = _make_game()
	game.current_world_key = "day"
	var bounds = game.call("_map_scroll_bounds_for_world", "day")
	var passed = _assert_true(bounds is Vector2, "expected _map_scroll_bounds_for_world helper to return a Vector2") \
		and _assert_true(float(bounds.y) > 0.0, "day map should have positive horizontal scroll range for 1-17")
	_free_game(game)
	return passed


func _test_bosses_cannot_be_hypnotized() -> bool:
	var game = _make_game()
	var boss_kinds = ["day_boss", "night_boss", "rumia_boss"]
	var passed := true
	for kind in boss_kinds:
		passed = _assert_true(Defs.ZOMBIES.has(kind), "missing %s definition" % kind) and passed
		if not Defs.ZOMBIES.has(kind):
			continue
		var boss = {
			"kind": kind,
			"hypnotized": false,
			"submerged": false,
			"flash": 0.0,
			"special_pause_timer": 0.0,
			"bite_timer": 0.0,
		}
		var result = game._hypnotize_zombie(boss)
		passed = _assert_true(not bool(result.get("hypnotized", false)), "%s should be immune to hypnosis" % kind) and passed
	_free_game(game)
	return passed


func _test_rumia_hover_cadence_is_randomized_and_not_too_fast() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_roll_rumia_hover_interval"), "expected _roll_rumia_hover_interval helper to exist"):
		_free_game(game)
		return false
	game.rng.seed = 11
	var interval_a = float(game.call("_roll_rumia_hover_interval", 0))
	game.rng.seed = 19
	var interval_b = float(game.call("_roll_rumia_hover_interval", 0))
	var passed = _assert_true(interval_a >= 1.9, "rumia should not switch rows too quickly") \
		and _assert_true(interval_b >= 1.9, "rumia should keep a slower minimum hover cadence") \
		and _assert_true(absf(interval_a - interval_b) > 0.05, "rumia hover cadence should be randomized instead of fixed")
	_free_game(game)
	return passed


func _test_rumia_boss_hovers_without_advancing() -> bool:
	var game = _make_game()
	game.current_level = {
		"id": "1-17",
		"terrain": "blood_moon",
		"mode": "conveyor",
		"events": [],
	}
	var hover_x = game.BOARD_ORIGIN.x + game.board_size.x - 12.0
	game._spawn_zombie_at("rumia_boss", 2, hover_x)
	var boss = game.zombies[0]
	boss["hover_shift_timer"] = 0.0
	game.zombies[0] = boss
	var start_x = float(game.zombies[0]["x"])
	game._update_zombies(0.1)
	var updated = game.zombies[0]
	var passed = _assert_true(absf(float(updated["x"]) - start_x) < 0.1, "rumia boss should stay on the right side instead of advancing") \
		and _assert_true(int(updated["row"]) != 2, "rumia boss should shift rows while hovering")
	_free_game(game)
	return passed


func _test_rumia_boss_summon_skill_spawns_reinforcements() -> bool:
	var game = _make_game()
	game.current_level = {
		"id": "1-17",
		"terrain": "blood_moon",
		"mode": "conveyor",
		"events": [],
	}
	game._spawn_zombie_at("rumia_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 16.0)
	var boss = game.zombies[0]
	boss["boss_skill_cycle"] = 0
	game.zombies[0] = boss
	game._trigger_boss_skill(boss)
	var passed = _assert_true(game.zombies.size() > 1, "rumia summon skill should add reinforcements to the battlefield") \
		and _assert_true(not game.effects.is_empty(), "rumia summon skill should create a visible boss effect")
	_free_game(game)
	return passed


func _test_rumia_boss_keeps_spawning_right_side_pressure() -> bool:
	var game = _make_game()
	game.current_level = {
		"id": "1-17",
		"terrain": "blood_moon",
		"mode": "conveyor",
		"events": [],
	}
	game._spawn_zombie_at("rumia_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 16.0)
	var boss = game.zombies[0]
	boss["rumia_reinforcement_timer"] = 0.0
	game.zombies[0] = boss
	game._update_zombies(0.1)
	var reinforcement_found := false
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) == "rumia_boss":
			continue
		if float(zombie.get("x", 0.0)) >= game.BOARD_ORIGIN.x + game.board_size.x:
			reinforcement_found = true
			break
	var passed = _assert_true(reinforcement_found, "rumia should keep spawning right-side reinforcements while she is active")
	_free_game(game)
	return passed


func _test_rumia_row_shift_enters_motion_state() -> bool:
	var game = _make_game()
	game.current_level = {
		"id": "1-17",
		"terrain": "blood_moon",
		"mode": "conveyor",
		"events": [],
	}
	game._spawn_zombie_at("rumia_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 16.0)
	var boss = game.zombies[0]
	boss["hover_shift_timer"] = 0.0
	game.rng.seed = 3
	game.zombies[0] = boss
	game._update_zombies(0.1)
	var updated = game.zombies[0]
	var passed = _assert_true(String(updated.get("rumia_state", "")) == "shift", "rumia row changes should enter a shift animation state") \
		and _assert_true(float(updated.get("rumia_move_timer", 0.0)) > 0.0, "rumia row changes should keep a movement timer for animation") \
		and _assert_true(not is_equal_approx(float(updated.get("rumia_move_from_y", 0.0)), float(updated.get("rumia_move_to_y", 0.0))), "rumia shift animation should interpolate between different rows")
	_free_game(game)
	return passed


func _test_rumia_skill_effects_use_animated_shapes() -> bool:
	var game = _make_game()
	game.current_level = {
		"id": "1-17",
		"terrain": "blood_moon",
		"mode": "conveyor",
		"events": [],
	}
	game._spawn_zombie_at("rumia_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 16.0)
	var expectations = {
		1: "rumia_beam",
		2: "night_bird_swarm",
		3: "dark_orbit",
	}
	var passed := true
	for cycle in expectations.keys():
		game.effects.clear()
		var boss = game.zombies[0]
		boss["boss_skill_cycle"] = int(cycle)
		game.zombies[0] = boss
		game._trigger_boss_skill(boss)
		var found := false
		for effect in game.effects:
			if String(effect.get("shape", "")) == String(expectations[cycle]) and float(effect.get("anim_speed", 0.0)) > 0.0:
				found = true
				break
		passed = _assert_true(found, "rumia skill cycle %d should create an animated %s effect" % [int(cycle), String(expectations[cycle])]) and passed
	_free_game(game)
	return passed


func _test_rumia_idle_animation_stays_stable_without_skill_or_movement() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_rumia_frame_index"), "expected _rumia_frame_index helper to exist"):
		_free_game(game)
		return false
	var boss = {
		"kind": "rumia_boss",
		"rumia_state": "idle",
		"anim_phase": 0.0,
		"special_pause_timer": 0.0,
	}
	game.level_time = 0.1
	var first_frame = int(game.call("_rumia_frame_index", boss))
	game.level_time = 2.4
	var second_frame = int(game.call("_rumia_frame_index", boss))
	var passed = _assert_true(first_frame == second_frame, "rumia idle animation should stay stable until she moves or casts")
	_free_game(game)
	return passed


func _test_legacy_save_data_migrates_sparse_progress_using_level_ids() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_apply_loaded_save_data"), "expected _apply_loaded_save_data helper to exist for save migration"):
		_free_game(game)
		return false
	var sparse_completed: Array = []
	sparse_completed.resize(Defs.LEVELS.size())
	for i in range(sparse_completed.size()):
		sparse_completed[i] = false
	sparse_completed[sparse_completed.size() - 1] = true
	var save_data = {
		"version": 1,
		"unlocked_levels": Defs.LEVELS.size(),
		"completed_levels": sparse_completed,
		"last_level_index": Defs.LEVELS.size() - 1,
		"current_world_key": "day",
	}
	game.call("_apply_loaded_save_data", save_data)
	var index_2_10 = _find_level_index("2-10")
	var index_1_17 = _find_level_index("1-17")
	var index_1_18 = _find_level_index("1-18")
	var passed = _assert_true(index_2_10 != -1 and index_1_17 != -1 and index_1_18 != -1, "expected special unlock chain levels to exist for migration test")
	if passed:
		passed = _assert_true(bool(game.completed_levels[index_2_10]), "legacy sparse saves should backfill prerequisite completion from endgame unlocked progress") and passed
		passed = _assert_true(bool(game.call("_is_level_unlocked", index_1_17)), "legacy sparse saves should keep 1-17 unlocked after migration") and passed
		passed = _assert_true(bool(game.call("_is_level_unlocked", index_1_18)), "legacy sparse saves should keep 1-18 unlocked after migration") and passed
	_free_game(game)
	return passed


func _test_touhou_boss_sprites_are_prebaked_left_without_runtime_flip() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_boss_frames_face_left"), "expected _boss_frames_face_left helper to exist for Touhou boss orientation rules"):
		_free_game(game)
		return false
	var passed = _assert_true(not bool(game.call("_boss_frames_face_left", "rumia_boss")), "Rumia should use prebaked left-facing frames without an extra runtime flip") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "daiyousei_boss")), "Daiyousei should use prebaked left-facing frames without an extra runtime flip") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "cirno_boss")), "Cirno should use prebaked left-facing frames without an extra runtime flip") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "meiling_boss")), "Meiling should use prebaked left-facing frames without an extra runtime flip")
	_free_game(game)
	return passed
