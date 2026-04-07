extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_1_20_unlock_requires_1_19() or failed
	failed = not _test_1_20_sits_after_1_19_on_day_world() or failed
	failed = not _test_patchouli_branch_assets_and_bgm_are_present() or failed
	failed = not _test_patchouli_bgm_streams_loop() or failed
	failed = not _test_patchouli_health_is_high_and_midboss_is_configured() or failed
	failed = not _test_koakuma_midboss_locks_progress_until_defeated() or failed
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
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
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


func _begin_level(game: Control, level_id: String) -> int:
	var level_index = _find_level_index(level_id)
	if level_index != -1:
		game._begin_level(level_index, [])
	return level_index


func _test_1_20_unlock_requires_1_19() -> bool:
	var level_index = _find_level_index("1-20")
	var prerequisite_index = _find_level_index("1-19")
	var passed = _assert_true(level_index != -1, "expected 1-20 to exist") \
		and _assert_true(prerequisite_index != -1, "expected 1-19 to exist as the 1-20 prerequisite")
	if not passed:
		return false
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "1-20 should stay locked before 1-19 is completed") and passed
	game.completed_levels[prerequisite_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "1-20 should unlock after 1-19 is completed") and passed
	_free_game(game)
	return passed


func _test_1_20_sits_after_1_19_on_day_world() -> bool:
	var level_index = _find_level_index("1-20")
	var previous_index = _find_level_index("1-19")
	var passed = _assert_true(level_index != -1, "expected 1-20 to exist for order checks") \
		and _assert_true(previous_index != -1, "expected 1-19 to exist for order checks")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	var previous = Defs.LEVELS[previous_index]
	passed = _assert_true(level_index == previous_index + 1, "1-20 should be placed immediately after 1-19") and passed
	passed = _assert_true(String(level.get("terrain", "")) == "blood_library", "1-20 should use the blood_library terrain") and passed
	passed = _assert_true(Vector2(level.get("node_pos", Vector2.ZERO)).x > Vector2(previous.get("node_pos", Vector2.ZERO)).x, "1-20 should sit to the right of 1-19 on the day map") and passed
	return passed


func _test_patchouli_branch_assets_and_bgm_are_present() -> bool:
	var required_paths = [
		"res://audio/patchouli_intro.mp3",
		"res://audio/patchouli_boss.mp3",
	]
	for frame_index in range(8):
		required_paths.append("res://art/koakuma/frame_%02d.png" % frame_index)
		required_paths.append("res://art/patchouli/frame_%02d.png" % frame_index)
	var passed := true
	for path in required_paths:
		passed = _assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(path)), "expected 1-20 asset to exist: %s" % path) and passed
	return passed


func _test_patchouli_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/patchouli_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/patchouli_boss.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "patchouli intro BGM should load as AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "patchouli boss BGM should load as AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "patchouli intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "patchouli boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_patchouli_health_is_high_and_midboss_is_configured() -> bool:
	var level_index = _find_level_index("1-20")
	var passed = _assert_true(level_index != -1, "expected 1-20 to exist before checking the boss config") \
		and _assert_true(Defs.ZOMBIES.has("koakuma_boss"), "expected koakuma_boss zombie definition to exist") \
		and _assert_true(Defs.ZOMBIES.has("patchouli_boss"), "expected patchouli_boss zombie definition to exist")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	var patchouli_def = Dictionary(Defs.ZOMBIES.get("patchouli_boss", {}))
	var koakuma_def = Dictionary(Defs.ZOMBIES.get("koakuma_boss", {}))
	passed = _assert_true(String(level.get("mid_boss_kind", "")) == "koakuma_boss", "1-20 should use Koakuma as the half-way gate boss") and passed
	passed = _assert_true(float(patchouli_def.get("health", 0.0)) >= 15000.0, "Patchouli should have a high boss health pool") and passed
	passed = _assert_true(bool(koakuma_def.get("boss", false)), "Koakuma should be treated as a boss for hypnosis immunity and gating") and passed
	return passed


func _test_koakuma_midboss_locks_progress_until_defeated() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-20")
	if not _assert_true(level_index != -1, "expected 1-20 to exist before checking the midboss gate"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_update_frozen_branch_flow"), "expected shared midboss gate flow helper to exist"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_battle_progress_ratio"), "expected battle progress helper to exist"):
		_free_game(game)
		return false
	game.total_kills = 30
	game.expected_spawn_units = 50
	game.call("_update_frozen_branch_flow")
	var found_midboss := false
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) == "koakuma_boss":
			found_midboss = true
			break
	var passed = _assert_true(found_midboss, "Koakuma should appear once 1-20 reaches half progress") \
		and _assert_true(float(game.call("_battle_progress_ratio")) <= 0.5, "1-20 progress should lock at half while Koakuma is alive")
	if found_midboss:
		for i in range(game.zombies.size()):
			if String(game.zombies[i].get("kind", "")) != "koakuma_boss":
				continue
			var boss = game.zombies[i]
			boss["health"] = 0.0
			game.zombies[i] = boss
			break
		game.call("_update_frozen_branch_flow")
		passed = _assert_true(float(game.call("_battle_progress_ratio")) > 0.5, "1-20 progress should resume after Koakuma is defeated") and passed
	_free_game(game)
	return passed
