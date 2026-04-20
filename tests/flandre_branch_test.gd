extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_1_23_unlock_requires_1_22() or failed
	failed = not _test_1_23_sits_after_1_22_on_day_world() or failed
	failed = not _test_1_23_configures_patchouli_midboss_flandre_boss_and_mixed_roof_mask() or failed
	failed = not _test_1_23_excludes_dragon_boat_from_events_and_flandre_support_spawns() or failed
	failed = not _test_1_23_excludes_basketball_and_mech_from_flandre_spawns() or failed
	failed = not _test_1_23_far_right_column_stays_directly_plantable() or failed
	failed = not _test_flandre_assets_and_bgm_are_present() or failed
	failed = not _test_flandre_bgm_streams_loop() or failed
	failed = not _test_flandre_health_is_high_and_uses_prebaked_left_facing_frames() or failed
	failed = not _test_patchouli_remilia_and_flandre_draw_large_enough() or failed
	failed = not _test_patchouli_midboss_locks_progress_until_defeated_in_1_23() or failed
	failed = not _test_flandre_health_bar_uses_five_segments_at_bottom() or failed
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


func _begin_level(game: Control, level_id: String) -> int:
	var level_index = _find_level_index(level_id)
	if level_index != -1:
		game._begin_level(level_index, [])
	return level_index


func _test_1_23_unlock_requires_1_22() -> bool:
	var level_index = _find_level_index("1-23")
	var prerequisite_index = _find_level_index("1-22")
	var passed = _assert_true(level_index != -1, "expected 1-23 to exist") \
		and _assert_true(prerequisite_index != -1, "expected 1-22 to exist as the 1-23 prerequisite")
	if not passed:
		return false
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "1-23 should stay locked before 1-22 is completed") and passed
	game.completed_levels[prerequisite_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "1-23 should unlock after 1-22 is completed") and passed
	_free_game(game)
	return passed


func _test_1_23_sits_after_1_22_on_day_world() -> bool:
	var level_index = _find_level_index("1-23")
	var previous_index = _find_level_index("1-22")
	var passed = _assert_true(level_index != -1, "expected 1-23 to exist for order checks") \
		and _assert_true(previous_index != -1, "expected 1-22 to exist for order checks")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	var previous = Defs.LEVELS[previous_index]
	passed = _assert_true(level_index == previous_index + 1, "1-23 should be placed immediately after 1-22") and passed
	passed = _assert_true(Vector2(level.get("node_pos", Vector2.ZERO)).x > Vector2(previous.get("node_pos", Vector2.ZERO)).x, "1-23 should sit to the right of 1-22 on the day map") and passed
	return passed


func _test_1_23_configures_patchouli_midboss_flandre_boss_and_mixed_roof_mask() -> bool:
	var level_index = _find_level_index("1-23")
	if not _assert_true(level_index != -1, "expected 1-23 to exist before checking wave structure"):
		return false
	var level = Defs.LEVELS[level_index]
	var wave_count := 0
	var has_boss := false
	var roof_tiles := 0
	var land_tiles := 0
	for event in level.get("events", []):
		if bool(event.get("wave", false)):
			wave_count += 1
		if String(event.get("kind", "")) == "flandre_boss":
			has_boss = true
	var level_mask = Array(level.get("cell_terrain_mask", []))
	for row_variant in level_mask:
		var row_data = Array(row_variant)
		for terrain_variant in row_data:
			var terrain = String(terrain_variant)
			if terrain == "roof":
				roof_tiles += 1
			elif terrain == "land":
				land_tiles += 1
	var conveyor_plants = Array(level.get("conveyor_plants", []))
	var passed = _assert_true(bool(level.get("boss_level", false)), "1-23 should be marked as a boss level") \
		and _assert_true(String(level.get("mode", "")) == "conveyor", "1-23 should be a conveyor level") \
		and _assert_true(String(level.get("mid_boss_kind", "")) == "patchouli_boss", "1-23 should use Patchouli as the half-way gate boss") \
		and _assert_true(String(level.get("terrain", "")) == "blood_toy_roof", "1-23 should use the dedicated blood_toy_roof terrain tag") \
		and _assert_true(wave_count == 9, "1-23 should define exactly nine waves") \
		and _assert_true(has_boss, "1-23 should include a flandre_boss event") \
		and _assert_true(conveyor_plants.has("flower_pot"), "1-23 conveyor should include flower_pot for mixed roof tiles") \
		and _assert_true(roof_tiles > 0, "1-23 should contain pot-required roof tiles in its terrain mask") \
		and _assert_true(land_tiles > 0, "1-23 should contain normal non-pot land tiles in its terrain mask")
	return passed


func _test_1_23_far_right_column_stays_directly_plantable() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-23")
	var passed := _assert_true(level_index != -1, "expected 1-23 to exist for far-right terrain checks")
	if passed:
		passed = _assert_true(String(game.call("_cell_terrain_kind", 0, 8)) == "land", "1-23 top-right cell should stay land instead of requiring a flower pot") and passed
		passed = _assert_true(String(game.call("_cell_terrain_kind", 4, 8)) == "land", "1-23 bottom-right cell should stay land instead of requiring a flower pot") and passed
		passed = _assert_true(String(game.call("_placement_error", "peashooter", 2, 8)) == "", "1-23 far-right column should allow direct planting without a flower pot") and passed
	_free_game(game)
	return passed


func _test_1_23_excludes_dragon_boat_from_events_and_flandre_support_spawns() -> bool:
	var level_index = _find_level_index("1-23")
	if not _assert_true(level_index != -1, "expected 1-23 to exist before checking dragon boat exclusions"):
		return false
	var level = Defs.LEVELS[level_index]
	var passed := true
	for event in level.get("events", []):
		passed = _assert_true(String(event.get("kind", "")) != "dragon_boat", "1-23 should not list dragon_boat in its event table") and passed
	var game = _make_game()
	game.current_level = level
	passed = _assert_true(String(game.call("_support_spawn_kind", "flandre_boss", 0, 0)) != "dragon_boat", "Flandre support spawns in 1-23 should not resolve to dragon_boat early in the fight") and passed
	passed = _assert_true(String(game.call("_support_spawn_kind", "flandre_boss", 4, 0)) != "dragon_boat", "Flandre support spawns in 1-23 should not resolve to dragon_boat mid-fight") and passed
	passed = _assert_true(String(game.call("_support_spawn_kind", "flandre_boss", 8, 0)) != "dragon_boat", "Flandre support spawns in 1-23 should not resolve to dragon_boat late in the fight") and passed
	_free_game(game)
	return passed


func _test_1_23_excludes_basketball_and_mech_from_flandre_spawns() -> bool:
	var level_index = _find_level_index("1-23")
	if not _assert_true(level_index != -1, "expected 1-23 to exist before checking basketball and mech exclusions"):
		return false
	var level = Defs.LEVELS[level_index]
	var disallowed := {
		"dragon_boat": true,
		"basketball": true,
		"mech_zombie": true,
		"catapult_zombie": true,
	}
	var passed := true
	for event in level.get("events", []):
		var kind = String(event.get("kind", ""))
		passed = _assert_true(not disallowed.has(kind), "1-23 should not list %s in its event table" % kind) and passed
	var game = _make_game()
	game.current_level = level
	for event_index in [0, 4, 8]:
		for extra_index in [0, 1]:
			var patchouli_support = String(game.call("_support_spawn_kind", "patchouli_boss", event_index, extra_index))
			passed = _assert_true(not disallowed.has(patchouli_support), "Patchouli support spawns in 1-23 should not resolve to %s" % patchouli_support) and passed
	for event_index in [0, 4, 8]:
		for extra_index in [0, 1]:
			var support_kind = String(game.call("_support_spawn_kind", "flandre_boss", event_index, extra_index))
			passed = _assert_true(not disallowed.has(support_kind), "Flandre support spawns in 1-23 should not resolve to %s" % support_kind) and passed
	for phase in range(3):
		for seed in range(24):
			game.zombies.clear()
			game.rng.seed = int(phase * 100 + seed + 700)
			game.call("_spawn_hover_boss_reinforcement", "patchouli_boss", phase)
			if game.zombies.is_empty():
				passed = _assert_true(false, "Patchouli reinforcement sampling should spawn a zombie for phase %d" % phase) and passed
				continue
			var patchouli_spawn = String(game.zombies[game.zombies.size() - 1].get("kind", ""))
			passed = _assert_true(not disallowed.has(patchouli_spawn), "Patchouli reinforcement pool in 1-23 should not spawn %s" % patchouli_spawn) and passed
	for phase in range(3):
		for seed in range(24):
			game.zombies.clear()
			game.rng.seed = int(phase * 100 + seed + 1)
			game.call("_spawn_hover_boss_reinforcement", "flandre_boss", phase)
			if game.zombies.is_empty():
				passed = _assert_true(false, "Flandre reinforcement sampling should spawn a zombie for phase %d" % phase) and passed
				continue
			var spawn_kind = String(game.zombies[game.zombies.size() - 1].get("kind", ""))
			passed = _assert_true(not disallowed.has(spawn_kind), "Flandre reinforcement pool in 1-23 should not spawn %s" % spawn_kind) and passed
	_free_game(game)
	return passed


func _test_flandre_assets_and_bgm_are_present() -> bool:
	var required_paths = [
		"res://audio/flandre_intro.mp3",
		"res://audio/flandre_boss.mp3",
	]
	for frame_index in range(8):
		required_paths.append("res://art/flandre/frame_%02d.png" % frame_index)
	var passed := true
	for path in required_paths:
		passed = _assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(path)), "expected 1-23 asset to exist: %s" % path) and passed
	return passed


func _test_flandre_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/flandre_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/flandre_boss.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "flandre intro BGM should load as AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "flandre boss BGM should load as AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "flandre intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "flandre boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_flandre_health_is_high_and_uses_prebaked_left_facing_frames() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("flandre_boss"), "expected flandre_boss zombie definition to exist")
	if not passed:
		return false
	var game = _make_game()
	var flandre_def = Dictionary(Defs.ZOMBIES.get("flandre_boss", {}))
	passed = _assert_true(bool(flandre_def.get("boss", false)), "Flandre should be marked as a boss") and passed
	passed = _assert_true(float(flandre_def.get("health", 0.0)) >= 24000.0, "Flandre should have a high boss health pool") and passed
	passed = _assert_true(game.has_method("_boss_frames_face_left"), "expected boss frame orientation helper to exist") and passed
	if game.has_method("_boss_frames_face_left"):
		passed = _assert_true(not bool(game.call("_boss_frames_face_left", "flandre_boss")), "Flandre should use prebaked left-facing frames without runtime flip") and passed
	_free_game(game)
	return passed


func _scaled_frame_height(path: String, draw_scale: float) -> float:
	var image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return 0.0
	return image.get_height() * draw_scale


func _test_patchouli_remilia_and_flandre_draw_large_enough() -> bool:
	var game = _make_game()
	var patchouli_height = _scaled_frame_height("res://art/patchouli/frame_00.png", float(game.call("_patchouli_draw_scale", 0)))
	var remilia_height = _scaled_frame_height("res://art/remilia/frame_00.png", float(game.call("_remilia_draw_scale", 0)))
	var flandre_height = _scaled_frame_height("res://art/flandre/frame_00.png", float(game.call("_flandre_draw_scale", 0)))
	var passed = _assert_true(patchouli_height >= 160.0, "Patchouli should render at a boss-sized height after scaling") \
		and _assert_true(remilia_height >= 175.0, "Remilia should render at a boss-sized height after scaling") \
		and _assert_true(flandre_height >= 175.0, "Flandre should render at a boss-sized height after scaling")
	_free_game(game)
	return passed


func _test_patchouli_midboss_locks_progress_until_defeated_in_1_23() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-23")
	if not _assert_true(level_index != -1, "expected 1-23 to exist before checking the midboss gate"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_update_frozen_branch_flow"), "expected shared midboss gate flow helper to exist"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_battle_progress_ratio"), "expected battle progress helper to exist"):
		_free_game(game)
		return false
	game.total_kills = 28
	game.expected_spawn_units = 40
	game.call("_update_frozen_branch_flow")
	var found_midboss := false
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) == "patchouli_boss":
			found_midboss = true
			break
	var passed = _assert_true(found_midboss, "Patchouli should appear once 1-23 reaches half progress") \
		and _assert_true(float(game.call("_battle_progress_ratio")) <= 0.5, "1-23 progress should lock at half while Patchouli is alive")
	if found_midboss:
		for i in range(game.zombies.size()):
			if String(game.zombies[i].get("kind", "")) != "patchouli_boss":
				continue
			var boss = game.zombies[i]
			boss["health"] = 0.0
			game.zombies[i] = boss
			break
		game.call("_update_frozen_branch_flow")
		passed = _assert_true(float(game.call("_battle_progress_ratio")) > 0.5, "1-23 progress should resume after Patchouli is defeated") and passed
	_free_game(game)
	return passed


func _test_flandre_health_bar_uses_five_segments_at_bottom() -> bool:
	var game = _make_game()
	var boss = {
		"kind": "flandre_boss",
		"health": 24800.0,
		"max_health": 24800.0,
	}
	game.zombies = [boss]
	game.size = Vector2(1280.0, 960.0)
	var layout = game._boss_health_bar_layout(boss)
	var rect = Rect2(layout.get("rect", Rect2()))
	var board_bottom = game.BOARD_ORIGIN.y + game.board_size.y
	var passed = _assert_true(int(layout.get("segments", 0)) == 5, "boss health bar should stay at five segments for flandre_boss") \
		and _assert_true(rect.position.y >= board_bottom, "flandre_boss health bar should stay below the board") \
		and _assert_true(rect.position.y + rect.size.y <= game.size.y - 8.0, "flandre_boss health bar should stay locked near the bottom edge")
	_free_game(game)
	return passed
