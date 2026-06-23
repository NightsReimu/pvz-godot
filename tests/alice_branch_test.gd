extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const AlmanacText = preload("res://scripts/data/almanac_text.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_2_27_unlocks_after_chen_and_uses_forest_branch() or failed
	failed = not _test_2_27_configures_alice_finale_without_midboss() or failed
	failed = not _test_alice_assets_and_bgm_are_present() or failed
	failed = not _test_alice_bgm_streams_loop() or failed
	failed = not _test_alice_boss_and_doll_definition_and_almanac_copy() or failed
	failed = not _test_alice_uses_prebaked_left_facing_frames() or failed
	failed = not _test_alice_finale_bgm_starts_only_for_alice() or failed
	failed = not _test_alice_doll_is_boss_exclusive_not_mainline_event() or failed
	failed = not _test_alice_skills_create_doll_magic_and_grave_pressure() or failed
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
	game.graves = []
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
	if game.is_inside_tree():
		game.get_parent().remove_child(game)
	game.free()


func _begin_level(game: Control, level_id: String) -> int:
	var level_index = _find_level_index(level_id)
	if level_index != -1:
		game.call("_begin_level", level_index, [])
	return level_index


func _test_2_27_unlocks_after_chen_and_uses_forest_branch() -> bool:
	var level_index = _find_level_index("2-27")
	var chen_index = _find_level_index("2-26")
	var passed = _assert_true(level_index != -1, "expected 2-27 to exist") \
		and _assert_true(chen_index != -1, "expected 2-26 to exist as the 2-27 unlock requirement")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	passed = _assert_true(String(level.get("world", "")) == "night", "2-27 should be explicitly attached to the night world") and passed
	passed = _assert_true(String(level.get("terrain", "")) == "forest_of_magic", "2-27 should use the forest_of_magic terrain") and passed
	passed = _assert_true(String(level.get("branch_from", "")) == "2-26", "2-27 should continue from 2-26") and passed
	var requirements = Array(level.get("unlock_requirements", []))
	passed = _assert_true(requirements.has("2-26"), "2-27 should unlock after Chen 2-26 is completed") and passed
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "2-27 should stay locked before 2-26 is completed") and passed
	game.completed_levels[chen_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "2-27 should unlock after 2-26 is completed") and passed
	_free_game(game)
	return passed


func _test_2_27_configures_alice_finale_without_midboss() -> bool:
	var level_index = _find_level_index("2-27")
	if not _assert_true(level_index != -1, "expected 2-27 to exist before checking wave structure"):
		return false
	var level = Defs.LEVELS[level_index]
	var has_final_boss := false
	var wave_count := 0
	for event in level.get("events", []):
		if bool(event.get("wave", false)):
			wave_count += 1
		if String(event.get("kind", "")) == "alice_boss":
			has_final_boss = true
	var conveyor_plants = Array(level.get("conveyor_plants", []))
	var available_plants = Array(level.get("available_plants", []))
	var passed = _assert_true(bool(level.get("boss_level", false)), "2-27 should be marked as a boss level") \
		and _assert_true(String(level.get("mode", "")) == "conveyor", "2-27 should be a conveyor level") \
		and _assert_true(String(level.get("mid_boss_kind", "")) == "", "2-27 should not configure a midboss") \
		and _assert_true(has_final_boss, "2-27 should include an alice_boss final event") \
		and _assert_true(wave_count >= 6, "2-27 should have enough wave markers for a boss branch stage") \
		and _assert_true(conveyor_plants.has("grave_buster"), "2-27 conveyor should include grave_buster for Alice's raised graves") \
		and _assert_true(conveyor_plants.has("origami_blossom"), "2-27 conveyor should include 魔术花 / origami_blossom") \
		and _assert_true(not conveyor_plants.has("moon_lotus"), "2-27 conveyor should not include moon_lotus") \
		and _assert_true(available_plants.has("grave_buster"), "2-27 available plants should include grave_buster") \
		and _assert_true(available_plants.has("origami_blossom"), "2-27 available plants should include origami_blossom") \
		and _assert_true(not available_plants.has("moon_lotus"), "2-27 available plants should not include moon_lotus")
	return passed


func _test_alice_assets_and_bgm_are_present() -> bool:
	var passed := true
	for path in ["res://audio/alice_intro.mp3", "res://audio/alice_boss.mp3"]:
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
	for frame_index in range(8):
		var path = "res://art/alice/frame_%02d.png" % frame_index
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if _assert_true(image != null and not image.is_empty(), "%s should load as an image" % path):
			var corner_alpha = image.get_pixel(0, 0).a + image.get_pixel(image.get_width() - 1, 0).a + image.get_pixel(0, image.get_height() - 1).a + image.get_pixel(image.get_width() - 1, image.get_height() - 1).a
			passed = _assert_true(corner_alpha <= 0.05, "%s should have transparent corners after white-background cleanup" % path) and passed
	return passed


func _test_alice_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/alice_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/alice_boss.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "alice intro BGM should load as AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "alice boss BGM should load as AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "alice intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "alice boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_alice_boss_and_doll_definition_and_almanac_copy() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("alice_boss"), "expected alice_boss zombie definition to exist") \
		and _assert_true(Defs.ZOMBIES.has("alice_doll_zombie"), "expected alice_doll_zombie definition to exist")
	if not passed:
		return false
	var data = Dictionary(Defs.ZOMBIES.get("alice_boss", {}))
	var doll = Dictionary(Defs.ZOMBIES.get("alice_doll_zombie", {}))
	passed = _assert_true(bool(data.get("boss", false)), "alice_boss should be marked as a boss") and passed
	passed = _assert_true(float(data.get("health", 0.0)) == 25200.0, "alice_boss should use the planned 25200 HP") and passed
	passed = _assert_true(int(data.get("skill_cycle_length", 0)) == 7, "alice_boss should have a seven-spell skill cycle") and passed
	passed = _assert_true(not bool(doll.get("boss", false)), "alice_doll_zombie should be a normal elite summon, not a boss") and passed
	var game = _make_game()
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("alice_boss"), "alice_boss should be visible in the zombie almanac") and passed
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("alice_doll_zombie"), "alice_doll_zombie should be visible in the zombie almanac") and passed
	var boss_lines = AlmanacText.zombie_lines("alice_boss")
	var doll_lines = AlmanacText.zombie_lines("alice_doll_zombie")
	var boss_joined = "\n".join(PackedStringArray(boss_lines))
	var doll_joined = "\n".join(PackedStringArray(doll_lines))
	passed = _assert_true(boss_joined.find("人偶") != -1 or boss_joined.find("魔法森林") != -1 or boss_joined.find("七色") != -1, "Alice almanac text should mention dolls, magic forest, or seven-color magic") and passed
	passed = _assert_true(doll_joined.find("爱丽丝") != -1 or doll_joined.find("人偶") != -1, "Alice doll almanac text should explain it is Alice's doll summon") and passed
	_free_game(game)
	return passed


func _test_alice_uses_prebaked_left_facing_frames() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_boss_frames_face_left"), "expected boss frame orientation helper to exist") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "alice_boss")), "Alice should use prebaked left-facing frames without runtime mirroring")
	_free_game(game)
	return passed


func _test_alice_finale_bgm_starts_only_for_alice() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-27")
	var passed = _assert_true(level_index != -1, "expected 2-27 to exist for BGM routing")
	if passed:
		get_root().add_child(game)
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "normal", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) != "res://audio/alice_boss.mp3" and String(game.current_bgm_path) != "res://audio/alice_boss.mp3", "2-27 normal enemies should not start Alice's finale BGM") and passed
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "alice_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) == "res://audio/alice_boss.mp3" or String(game.current_bgm_path) == "res://audio/alice_boss.mp3", "Alice final boss should start the finale BGM") and passed
	_free_game(game)
	return passed


func _test_alice_doll_is_boss_exclusive_not_mainline_event() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("alice_doll_zombie"), "alice doll summon should exist before checking level events")
	if not passed:
		return false
	for level in Defs.LEVELS:
		var level_id = String(Dictionary(level).get("id", ""))
		for event in Dictionary(level).get("events", []):
			var kind = String(Dictionary(event).get("kind", ""))
			if kind == "alice_doll_zombie":
				return _assert_true(level_id == "2-27", "alice_doll_zombie should not be placed in mainline or non-Alice event tables")
	return passed


func _test_alice_skills_create_doll_magic_and_grave_pressure() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-27")
	var passed = _assert_true(level_index != -1, "expected 2-27 to exist before exercising Alice skills") \
		and _assert_true(game.has_method("_trigger_alice_boss_skill"), "expected dedicated Alice skill trigger to exist")
	if passed:
		var plant = game.call("_create_plant", "tallnut", 2, 5)
		plant["health"] = 1400.0
		plant["shot_cooldown"] = 0.0
		game.grid[2][5] = plant
		var boss = {
			"kind": "alice_boss",
			"row": 2,
			"x": game.BOARD_ORIGIN.x + game.board_size.x - 24.0,
			"boss_phase": 1,
			"boss_skill_cycle": 0,
			"health": float(Defs.ZOMBIES.get("alice_boss", {}).get("health", 25200.0)),
			"max_health": float(Defs.ZOMBIES.get("alice_boss", {}).get("health", 25200.0)),
		}
		for cycle in range(7):
			boss["boss_skill_cycle"] = cycle
			boss = game.call("_trigger_alice_boss_skill", boss)
		var damaged_plant = Dictionary(game.grid[2][5])
		var has_doll_fx := false
		var has_magic_fx := false
		var has_grave_fx := false
		for effect in game.effects:
			var shape = String(Dictionary(effect).get("shape", ""))
			if shape.find("doll") != -1 or shape.find("marionette") != -1:
				has_doll_fx = true
			if shape.find("alice") != -1 or shape.find("magic") != -1 or shape.find("seven") != -1:
				has_magic_fx = true
			if shape.find("grave") != -1:
				has_grave_fx = true
		var summoned_doll := false
		for zombie in game.zombies:
			if String(Dictionary(zombie).get("kind", "")) == "alice_doll_zombie":
				summoned_doll = true
		passed = _assert_true(has_doll_fx, "Alice skills should create visible doll or marionette effects") and passed
		passed = _assert_true(has_magic_fx, "Alice skills should create visible magic forest / seven-color effects") and passed
		passed = _assert_true(has_grave_fx, "Alice grave raising should create a dedicated grave-rise animation effect") and passed
		passed = _assert_true(summoned_doll, "Alice skills should summon alice_doll_zombie units") and passed
		passed = _assert_true(game.graves.size() >= 1, "Alice skills should raise at least one grave") and passed
		passed = _assert_true(float(damaged_plant.get("health", 0.0)) > 0.0, "Alice skill cycle should pressure plants without instantly deleting a 1400 HP plant") and passed
	_free_game(game)
	return passed
