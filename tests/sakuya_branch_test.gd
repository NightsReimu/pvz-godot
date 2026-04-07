extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_1_21_unlock_requires_1_20() or failed
	failed = not _test_1_21_sits_after_1_20_on_day_world() or failed
	failed = not _test_1_21_has_eight_waves_and_sakuya_boss() or failed
	failed = not _test_sakuya_assets_and_bgm_are_present() or failed
	failed = not _test_sakuya_bgm_streams_loop() or failed
	failed = not _test_sakuya_health_is_high() or failed
	failed = not _test_sakuya_time_stop_starts_and_freezes_other_units() or failed
	failed = not _test_sakuya_time_stop_can_relocate_plants() or failed
	failed = not _test_mower_killing_sakuya_avoids_generic_boss_banner() or failed
	failed = not _test_sakuya_uses_prebaked_left_facing_frames() or failed
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
	game.projectiles = []
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


func _test_1_21_unlock_requires_1_20() -> bool:
	var level_index = _find_level_index("1-21")
	var prerequisite_index = _find_level_index("1-20")
	var passed = _assert_true(level_index != -1, "expected 1-21 to exist") \
		and _assert_true(prerequisite_index != -1, "expected 1-20 to exist as the 1-21 prerequisite")
	if not passed:
		return false
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "1-21 should stay locked before 1-20 is completed") and passed
	game.completed_levels[prerequisite_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "1-21 should unlock after 1-20 is completed") and passed
	_free_game(game)
	return passed


func _test_1_21_sits_after_1_20_on_day_world() -> bool:
	var level_index = _find_level_index("1-21")
	var previous_index = _find_level_index("1-20")
	var passed = _assert_true(level_index != -1, "expected 1-21 to exist for order checks") \
		and _assert_true(previous_index != -1, "expected 1-20 to exist for order checks")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	var previous = Defs.LEVELS[previous_index]
	passed = _assert_true(level_index == previous_index + 1, "1-21 should be placed immediately after 1-20") and passed
	passed = _assert_true(String(level.get("terrain", "")) == "scarlet_clocktower", "1-21 should use the scarlet_clocktower terrain") and passed
	passed = _assert_true(Vector2(level.get("node_pos", Vector2.ZERO)).x > Vector2(previous.get("node_pos", Vector2.ZERO)).x, "1-21 should sit to the right of 1-20 on the day map") and passed
	return passed


func _test_1_21_has_eight_waves_and_sakuya_boss() -> bool:
	var level_index = _find_level_index("1-21")
	if not _assert_true(level_index != -1, "expected 1-21 to exist before checking wave structure"):
		return false
	var level = Defs.LEVELS[level_index]
	var wave_count := 0
	var has_boss := false
	for event in level.get("events", []):
		if bool(event.get("wave", false)):
			wave_count += 1
		if String(event.get("kind", "")) == "sakuya_boss":
			has_boss = true
	var passed = _assert_true(bool(level.get("boss_level", false)), "1-21 should be marked as a boss level") \
		and _assert_true(String(level.get("mode", "")) == "conveyor", "1-21 should be a conveyor level") \
		and _assert_true(wave_count == 8, "1-21 should define exactly eight waves") \
		and _assert_true(has_boss, "1-21 should include a sakuya_boss event")
	return passed


func _test_sakuya_assets_and_bgm_are_present() -> bool:
	var required_paths = [
		"res://audio/sakuya_intro.mp3",
		"res://audio/sakuya_boss.mp3",
	]
	for frame_index in range(8):
		required_paths.append("res://art/sakuya/frame_%02d.png" % frame_index)
	var passed := true
	for path in required_paths:
		passed = _assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(path)), "expected Sakuya asset to exist: %s" % path) and passed
	return passed


func _test_sakuya_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/sakuya_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/sakuya_boss.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "sakuya intro BGM should load as AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "sakuya boss BGM should load as AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "sakuya intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "sakuya boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_sakuya_health_is_high() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("sakuya_boss"), "expected sakuya_boss zombie definition to exist")
	if not passed:
		return false
	var def = Dictionary(Defs.ZOMBIES.get("sakuya_boss", {}))
	passed = _assert_true(bool(def.get("boss", false)), "Sakuya should be treated as a boss unit") and passed
	passed = _assert_true(float(def.get("health", 0.0)) >= 18000.0, "Sakuya should have a high boss health pool") and passed
	return passed


func _test_sakuya_time_stop_starts_and_freezes_other_units() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-21")
	if not _assert_true(level_index != -1, "expected 1-21 to exist before checking time stop"):
		_free_game(game)
		return false
	var boss_row := 2
	var zombie_row := 1
	game._spawn_zombie_at("sakuya_boss", boss_row, game.BOARD_ORIGIN.x + game.board_size.x - 18.0)
	game._spawn_zombie_at("conehead", zombie_row, game._normal_zombie_spawn_x())
	var projectile_position = Vector2(game.BOARD_ORIGIN.x + 220.0, game._row_center_y(zombie_row) - 8.0)
	game.projectiles.append({
		"kind": "pea",
		"position": projectile_position,
		"row": zombie_row,
		"damage": 20.0,
		"speed": 220.0,
		"radius": 8.0,
		"color": Color(0.42, 0.88, 0.28, 1.0),
	})
	var boss_index := -1
	var enemy_index := -1
	for i in range(game.zombies.size()):
		var kind = String(game.zombies[i].get("kind", ""))
		if kind == "sakuya_boss":
			boss_index = i
		elif kind == "conehead":
			enemy_index = i
	if not _assert_true(boss_index != -1, "expected Sakuya to spawn for time stop tests"):
		_free_game(game)
		return false
	if not _assert_true(enemy_index != -1, "expected a normal zombie to spawn for time stop tests"):
		_free_game(game)
		return false
	var boss = game.zombies[boss_index]
	boss["boss_skill_cycle"] = 4
	game.zombies[boss_index] = boss
	boss = game.call("_trigger_sakuya_boss_skill", boss)
	game.zombies[boss_index] = boss
	var before_projectile = Vector2(game.projectiles[0]["position"])
	var before_enemy_x = float(game.zombies[enemy_index]["x"])
	game._update_projectiles(0.5)
	game._update_zombies(0.5)
	var passed = _assert_true(float(game.get("boss_time_stop_timer")) > 0.0, "Sakuya time stop should start a global battle freeze timer") \
		and _assert_true(Vector2(game.projectiles[0]["position"]).distance_to(before_projectile) < 0.01, "time stop should freeze existing projectiles in place") \
		and _assert_true(absf(float(game.zombies[enemy_index]["x"]) - before_enemy_x) < 0.01, "time stop should freeze non-boss zombies in place")
	_free_game(game)
	return passed


func _occupied_grid_cells(game: Control) -> Array:
	var cells: Array = []
	for row in range(game.ROWS):
		for col in range(game.COLS):
			if game.grid[row][col] == null:
				continue
			cells.append(Vector2i(row, col))
	return cells


func _test_sakuya_time_stop_can_relocate_plants() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-21")
	if not _assert_true(level_index != -1, "expected 1-21 to exist before checking Sakuya relocation"):
		_free_game(game)
		return false
	game.rng.seed = 20260406
	game.grid[1][2] = game._create_plant("repeater", 1, 2)
	game.grid[2][3] = game._create_plant("wallnut", 2, 3)
	game.grid[3][4] = game._create_plant("snow_pea", 3, 4)
	game._spawn_zombie_at("sakuya_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 18.0)
	var boss_index := -1
	for i in range(game.zombies.size()):
		if String(game.zombies[i].get("kind", "")) == "sakuya_boss":
			boss_index = i
			break
	if not _assert_true(boss_index != -1, "expected Sakuya to spawn before checking relocation"):
		_free_game(game)
		return false
	var before_cells = _occupied_grid_cells(game)
	var boss = game.zombies[boss_index]
	boss["boss_skill_cycle"] = 4
	game.zombies[boss_index] = boss
	boss = game.call("_trigger_sakuya_boss_skill", boss)
	game.zombies[boss_index] = boss
	for _step in range(6):
		game._update_zombies(0.18)
	var after_cells = _occupied_grid_cells(game)
	var passed = _assert_true(before_cells.size() == after_cells.size(), "Sakuya relocation should move plants instead of deleting them") \
		and _assert_true(not before_cells.hash() == after_cells.hash(), "Sakuya should be able to reposition plants while time stop is active")
	_free_game(game)
	return passed


func _test_mower_killing_sakuya_avoids_generic_boss_banner() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-21")
	if not _assert_true(level_index != -1, "expected 1-21 to exist before checking mower boss cleanup text"):
		_free_game(game)
		return false
	game.zombies.append({
		"kind": "sakuya_boss",
		"row": 2,
		"x": game.BOARD_ORIGIN.x + 180.0,
		"health": 1.0,
		"max_health": 18800.0,
		"boss_phase": 0,
		"flash": 0.0,
		"special_pause_timer": 0.0,
		"boss_pause_timer": 0.0,
		"weed_pause_timer": 0.0,
		"reflect_timer": 0.0,
	})
	game.mowers[2]["active"] = true
	game.mowers[2]["armed"] = false
	game.mowers[2]["x"] = game.BOARD_ORIGIN.x + 170.0
	game._update_mowers(0.05)
	game._cleanup_dead_zombies()
	var passed = _assert_true(game.banner_label.text.find("Boss") == -1, "mower cleanup text should not describe Sakuya as a generic boss") \
		and _assert_true(game.banner_label.text.find("大") != -1 or game.banner_label.text.find("目标") != -1 or game.banner_label.text == "", "mower cleanup text should switch to a neutral non-boss message")
	_free_game(game)
	return passed


func _test_sakuya_uses_prebaked_left_facing_frames() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_boss_frames_face_left"), "expected boss frame orientation helper to exist") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "sakuya_boss")), "Sakuya should use prebaked left-facing frames without a runtime flip")
	_free_game(game)
	return passed
