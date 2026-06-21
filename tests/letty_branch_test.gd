extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const AlmanacText = preload("res://scripts/data/almanac_text.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_2_25_unlocks_after_remilia_and_uses_winter_branch() or failed
	failed = not _test_2_25_configures_cirno_midboss_and_letty_finale() or failed
	failed = not _test_letty_assets_and_bgm_are_present() or failed
	failed = not _test_letty_bgm_streams_loop() or failed
	failed = not _test_letty_boss_definition_and_almanac_copy() or failed
	failed = not _test_letty_uses_prebaked_left_facing_frames() or failed
	failed = not _test_cirno_midboss_does_not_steal_letty_finale_bgm() or failed
	failed = not _test_letty_skills_create_bounded_winter_pressure() or failed
	failed = not _test_temporary_frozen_cells_restore_to_land() or failed
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
	game.current_level = {"id": "test", "terrain": "day", "events": []}
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
	if game.is_inside_tree():
		game.get_parent().remove_child(game)
	game.free()


func _begin_level(game: Control, level_id: String) -> int:
	var level_index = _find_level_index(level_id)
	if level_index != -1:
		game.call("_begin_level", level_index, [])
	return level_index


func _test_2_25_unlocks_after_remilia_and_uses_winter_branch() -> bool:
	var level_index = _find_level_index("2-25")
	var remilia_index = _find_level_index("1-22")
	var source_index = _find_level_index("2-17")
	var passed = _assert_true(level_index != -1, "expected 2-25 to exist") \
		and _assert_true(remilia_index != -1, "expected 1-22 to exist as the 2-25 unlock requirement") \
		and _assert_true(source_index != -1, "expected 2-17 to exist as the night branch source")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	passed = _assert_true(String(level.get("world", "")) == "night", "2-25 should be explicitly attached to the night world") and passed
	passed = _assert_true(String(level.get("terrain", "")) == "winter_forest", "2-25 should use the winter_forest terrain") and passed
	passed = _assert_true(String(level.get("branch_from", "")) == "2-17", "2-25 should branch from the end of chapter 2") and passed
	var requirements = Array(level.get("unlock_requirements", []))
	passed = _assert_true(requirements.has("1-22"), "2-25 should unlock only after Remilia 1-22 is completed") and passed
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "2-25 should stay locked before 1-22 is completed") and passed
	game.completed_levels[remilia_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "2-25 should unlock after 1-22 is completed") and passed
	_free_game(game)
	return passed


func _test_2_25_configures_cirno_midboss_and_letty_finale() -> bool:
	var level_index = _find_level_index("2-25")
	if not _assert_true(level_index != -1, "expected 2-25 to exist before checking wave structure"):
		return false
	var level = Defs.LEVELS[level_index]
	var has_final_boss := false
	var wave_count := 0
	for event in level.get("events", []):
		if bool(event.get("wave", false)):
			wave_count += 1
		if String(event.get("kind", "")) == "letty_boss":
			has_final_boss = true
	var conveyor_plants = Array(level.get("conveyor_plants", []))
	var passed = _assert_true(bool(level.get("boss_level", false)), "2-25 should be marked as a boss level") \
		and _assert_true(String(level.get("mode", "")) == "conveyor", "2-25 should be a conveyor level") \
		and _assert_true(String(level.get("mid_boss_kind", "")) == "cirno_boss", "2-25 should use Cirno as the half-way boss") \
		and _assert_true(has_final_boss, "2-25 should include a letty_boss final event") \
		and _assert_true(wave_count >= 6, "2-25 should have enough wave markers for a boss branch stage") \
		and _assert_true(not conveyor_plants.has("flower_pot"), "winter_forest conveyor should not require flower pots") \
		and _assert_true(not conveyor_plants.has("lily_pad"), "winter_forest conveyor should not include lily pads")
	return passed


func _test_letty_assets_and_bgm_are_present() -> bool:
	var passed := true
	for path in ["res://audio/letty_intro.mp3", "res://audio/letty_boss.mp3"]:
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
	for frame_index in range(8):
		var path = "res://art/letty/frame_%02d.png" % frame_index
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if _assert_true(image != null and not image.is_empty(), "%s should load as an image" % path):
			var corner_alpha = image.get_pixel(0, 0).a + image.get_pixel(image.get_width() - 1, 0).a + image.get_pixel(0, image.get_height() - 1).a + image.get_pixel(image.get_width() - 1, image.get_height() - 1).a
			passed = _assert_true(corner_alpha <= 0.05, "%s should have transparent corners after white-background cleanup" % path) and passed
	return passed


func _test_letty_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/letty_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/letty_boss.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "letty intro BGM should load as AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "letty boss BGM should load as AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "letty intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "letty boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_letty_boss_definition_and_almanac_copy() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("letty_boss"), "expected letty_boss zombie definition to exist")
	if not passed:
		return false
	var data = Dictionary(Defs.ZOMBIES.get("letty_boss", {}))
	passed = _assert_true(bool(data.get("boss", false)), "letty_boss should be marked as a boss") and passed
	passed = _assert_true(float(data.get("health", 0.0)) == 23200.0, "letty_boss should use the planned 23200 HP") and passed
	passed = _assert_true(int(data.get("skill_cycle_length", 0)) == 5, "letty_boss should have a five-spell skill cycle") and passed
	var game = _make_game()
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("letty_boss"), "letty_boss should be visible in the zombie almanac") and passed
	var text_lines = AlmanacText.zombie_lines("letty_boss")
	var joined = "\n".join(PackedStringArray(text_lines))
	passed = _assert_true(joined.find("冬") != -1 or joined.find("寒") != -1, "Letty almanac text should mention winter or cold pressure") and passed
	_free_game(game)
	return passed


func _test_letty_uses_prebaked_left_facing_frames() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_boss_frames_face_left"), "expected boss frame orientation helper to exist") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "letty_boss")), "Letty should use prebaked left-facing frames without runtime mirroring")
	_free_game(game)
	return passed


func _test_cirno_midboss_does_not_steal_letty_finale_bgm() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-25")
	var passed = _assert_true(level_index != -1, "expected 2-25 to exist for BGM routing")
	if passed:
		get_root().add_child(game)
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "cirno_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) != "res://audio/letty_boss.mp3" and String(game.current_bgm_path) != "res://audio/letty_boss.mp3", "2-25 Cirno midboss should not start Letty's finale BGM") and passed
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "letty_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) == "res://audio/letty_boss.mp3" or String(game.current_bgm_path) == "res://audio/letty_boss.mp3", "Letty final boss should start the finale BGM") and passed
	_free_game(game)
	return passed


func _test_letty_skills_create_bounded_winter_pressure() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-25")
	var passed = _assert_true(level_index != -1, "expected 2-25 to exist before exercising Letty skills") \
		and _assert_true(game.has_method("_trigger_letty_boss_skill"), "expected dedicated Letty skill trigger to exist")
	if passed:
		var plant = game.call("_create_plant", "repeater", 2, 5)
		plant["health"] = 900.0
		plant["shot_cooldown"] = 0.0
		game.grid[2][5] = plant
		var boss = {
			"kind": "letty_boss",
			"row": 2,
			"x": game.BOARD_ORIGIN.x + game.board_size.x - 24.0,
			"boss_phase": 1,
			"boss_skill_cycle": 0,
			"health": float(Defs.ZOMBIES.get("letty_boss", {}).get("health", 23200.0)),
			"max_health": float(Defs.ZOMBIES.get("letty_boss", {}).get("health", 23200.0)),
		}
		for cycle in range(5):
			boss["boss_skill_cycle"] = cycle
			boss = game.call("_trigger_letty_boss_skill", boss)
		var damaged_plant = Dictionary(game.grid[2][5])
		var has_winter_fx := false
		for effect in game.effects:
			var shape = String(Dictionary(effect).get("shape", ""))
			if shape.find("letty") != -1 or shape == "temporary_frozen_cell":
				has_winter_fx = true
		passed = _assert_true(has_winter_fx, "Letty skills should create visible winter-themed effects") and passed
		passed = _assert_true(float(damaged_plant.get("health", 0.0)) > 0.0, "Letty skill cycle should pressure plants without instantly deleting a 900 HP plant") and passed
		passed = _assert_true(float(damaged_plant.get("shot_cooldown", 0.0)) > 0.0, "Letty skills should apply a cold cadence/cooldown penalty") and passed
	_free_game(game)
	return passed


func _test_temporary_frozen_cells_restore_to_land() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-25")
	var passed = _assert_true(level_index != -1, "expected 2-25 to exist before checking temporary frozen cells") \
		and _assert_true(game.has_method("_create_temporary_frozen_cell"), "expected temporary frozen cell helper to exist")
	if passed:
		game.call("_create_temporary_frozen_cell", 2, 4, 0.2)
		passed = _assert_true(String(game.call("_cell_terrain_kind", 2, 4)) == "frozen", "temporary frozen helper should turn the target cell into frozen terrain") and passed
		game.call("_update_effects", 0.25)
		passed = _assert_true(String(game.call("_cell_terrain_kind", 2, 4)) == "land", "temporary frozen helper should restore the original terrain when the effect expires") and passed
	_free_game(game)
	return passed
