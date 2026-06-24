extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const AlmanacText = preload("res://scripts/data/almanac_text.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_2_29_unlocks_after_prismriver_and_uses_stair_branch() or failed
	failed = not _test_2_29_configures_youmu_finale_without_midboss() or failed
	failed = not _test_youmu_assets_and_bgm_are_present() or failed
	failed = not _test_youmu_bgm_streams_loop() or failed
	failed = not _test_youmu_definition_and_almanac_copy() or failed
	failed = not _test_youmu_uses_prebaked_left_facing_frames() or failed
	failed = not _test_youmu_finale_bgm_starts_only_for_youmu() or failed
	failed = not _test_youmu_skills_create_slash_ghost_and_charm_pressure() or failed
	failed = not _test_youmu_first_column_dash_does_not_trigger_mowers_or_loss() or failed
	failed = not _test_youmu_charm_state_decays_and_makes_plants_attack_plants() or failed
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
	game.rng.seed = 2929
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


func _test_2_29_unlocks_after_prismriver_and_uses_stair_branch() -> bool:
	var level_index = _find_level_index("2-29")
	var prismriver_index = _find_level_index("2-28")
	var passed = _assert_true(level_index != -1, "expected 2-29 to exist") \
		and _assert_true(prismriver_index != -1, "expected 2-28 to exist as the 2-29 unlock requirement")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	passed = _assert_true(String(level.get("world", "")) == "night", "2-29 should be explicitly attached to the night world") and passed
	passed = _assert_true(String(level.get("terrain", "")) == "spiral_staircase", "2-29 should use the spiral_staircase terrain") and passed
	passed = _assert_true(String(level.get("branch_from", "")) == "2-28", "2-29 should continue from 2-28") and passed
	var requirements = Array(level.get("unlock_requirements", []))
	passed = _assert_true(requirements.has("2-28"), "2-29 should unlock after Prismriver 2-28 is completed") and passed
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "2-29 should stay locked before 2-28 is completed") and passed
	game.completed_levels[prismriver_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "2-29 should unlock after 2-28 is completed") and passed
	_free_game(game)
	return passed


func _test_2_29_configures_youmu_finale_without_midboss() -> bool:
	var level_index = _find_level_index("2-29")
	var prismriver_index = _find_level_index("2-28")
	if not _assert_true(level_index != -1, "expected 2-29 to exist before checking wave structure") or not _assert_true(prismriver_index != -1, "expected 2-28 to exist before comparing route length"):
		return false
	var level = Defs.LEVELS[level_index]
	var prismriver_level = Defs.LEVELS[prismriver_index]
	var has_final_boss := false
	var final_boss_time := 0.0
	var wave_count := 0
	var prismriver_finale_time := 0.0
	for event in level.get("events", []):
		if bool(event.get("wave", false)):
			wave_count += 1
		if String(event.get("kind", "")) == "youmu_boss":
			has_final_boss = true
			final_boss_time = float(event.get("time", 0.0))
	for event in prismriver_level.get("events", []):
		if String(event.get("kind", "")) == "prismriver_boss":
			prismriver_finale_time = float(event.get("time", 0.0))
	var conveyor_plants = Array(level.get("conveyor_plants", []))
	var passed = _assert_true(bool(level.get("boss_level", false)), "2-29 should be marked as a boss level") \
		and _assert_true(String(level.get("mode", "")) == "conveyor", "2-29 should be a conveyor level") \
		and _assert_true(String(level.get("mid_boss_kind", "")) == "", "2-29 should not configure a midboss") \
		and _assert_true(has_final_boss, "2-29 should include a youmu_boss final event") \
		and _assert_true(wave_count >= 6 and wave_count <= 8, "2-29 should have a compact Stage 5 route, not a Stage 4-length route") \
		and _assert_true(final_boss_time >= 120.0 and final_boss_time <= 135.0, "2-29 Youmu finale should start after a medium-length route") \
		and _assert_true(final_boss_time < prismriver_finale_time - 50.0, "2-29 route should be much shorter than 2-28") \
		and _assert_true(not conveyor_plants.has("flower_pot"), "spiral staircase conveyor should not require flower pots") \
		and _assert_true(not conveyor_plants.has("lily_pad"), "spiral staircase conveyor should not include lily pads")
	return passed


func _test_youmu_assets_and_bgm_are_present() -> bool:
	var passed := true
	for path in ["res://audio/youmu_intro.mp3", "res://audio/youmu_boss.mp3"]:
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
	for frame_index in range(8):
		var path = "res://art/youmu/frame_%02d.png" % frame_index
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if _assert_true(image != null and not image.is_empty(), "%s should load as an image" % path):
			var corner_alpha = image.get_pixel(0, 0).a + image.get_pixel(image.get_width() - 1, 0).a + image.get_pixel(0, image.get_height() - 1).a + image.get_pixel(image.get_width() - 1, image.get_height() - 1).a
			passed = _assert_true(corner_alpha <= 0.05, "%s should have transparent corners after white-background cleanup" % path) and passed
	return passed


func _test_youmu_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/youmu_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/youmu_boss.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "youmu intro BGM should load as AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "youmu boss BGM should load as AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "youmu intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "youmu boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_youmu_definition_and_almanac_copy() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("youmu_boss"), "expected youmu_boss zombie definition to exist")
	if not passed:
		return false
	var data = Dictionary(Defs.ZOMBIES.get("youmu_boss", {}))
	passed = _assert_true(bool(data.get("boss", false)), "youmu_boss should be marked as a boss") and passed
	passed = _assert_true(float(data.get("health", 0.0)) == 30400.0, "youmu_boss should use the planned 30400 HP") and passed
	passed = _assert_true(int(data.get("skill_cycle_length", 0)) == 8, "youmu_boss should have an eight-spell skill cycle") and passed
	passed = _assert_true(float(data.get("skill_interval_min", 0.0)) >= 4.8, "youmu skill floor should preserve a reaction window") and passed
	var game = _make_game()
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("youmu_boss"), "youmu_boss should be visible in the zombie almanac") and passed
	var joined = "\n".join(PackedStringArray(AlmanacText.zombie_lines("youmu_boss")))
	passed = _assert_true(joined.find("妖梦") != -1 and joined.find("剑") != -1, "Youmu almanac text should mention Youmu and sword pressure") and passed
	passed = _assert_true(joined.find("半灵") != -1 or joined.find("怨灵") != -1, "Youmu almanac text should mention half-phantom or wraith mechanics") and passed
	_free_game(game)
	return passed


func _test_youmu_uses_prebaked_left_facing_frames() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_boss_frames_face_left"), "expected boss frame orientation helper to exist") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "youmu_boss")), "Youmu should use prebaked left-facing frames without runtime mirroring")
	_free_game(game)
	return passed


func _test_youmu_finale_bgm_starts_only_for_youmu() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-29")
	var passed = _assert_true(level_index != -1, "expected 2-29 to exist for BGM routing")
	if passed:
		get_root().add_child(game)
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "normal", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) != "res://audio/youmu_boss.mp3" and String(game.current_bgm_path) != "res://audio/youmu_boss.mp3", "2-29 normal enemies should not start Youmu's finale BGM") and passed
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "youmu_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) == "res://audio/youmu_boss.mp3" or String(game.current_bgm_path) == "res://audio/youmu_boss.mp3", "Youmu final boss should start the finale BGM") and passed
	_free_game(game)
	return passed


func _test_youmu_skills_create_slash_ghost_and_charm_pressure() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-29")
	var passed = _assert_true(level_index != -1, "expected 2-29 to exist before exercising Youmu skills") \
		and _assert_true(game.has_method("_trigger_youmu_boss_skill"), "expected dedicated Youmu skill trigger to exist") \
		and _assert_true(game.has_method("_youmu_boss_bounds"), "expected Youmu board bounds helper to exist")
	if passed:
		var plant = game.call("_create_plant", "tallnut", 2, 5)
		plant["health"] = 1400.0
		plant["shot_cooldown"] = 0.0
		game.grid[2][5] = plant
		var support = game.call("_create_plant", "wallnut", 2, 4)
		support["health"] = 1400.0
		game.grid[2][4] = support
		var bounds = Dictionary(game.call("_youmu_boss_bounds"))
		var boss = {
			"kind": "youmu_boss",
			"row": 2,
			"x": float(bounds.get("max_x", game.BOARD_ORIGIN.x + game.board_size.x - 24.0)),
			"boss_phase": 1,
			"boss_skill_cycle": 0,
			"health": float(Defs.ZOMBIES.get("youmu_boss", {}).get("health", 30400.0)),
			"max_health": float(Defs.ZOMBIES.get("youmu_boss", {}).get("health", 30400.0)),
		}
		for cycle in range(8):
			boss["boss_skill_cycle"] = cycle
			boss = game.call("_trigger_youmu_boss_skill", boss)
			passed = _assert_true(float(boss.get("x", 0.0)) >= float(bounds.get("min_x", 0.0)) and float(boss.get("x", 0.0)) <= float(bounds.get("max_x", 0.0)), "Youmu boss should stay inside the board bounds while dashing") and passed
		var damaged_plant = Dictionary(game.grid[2][5])
		var has_slash_fx := false
		var has_ghost_fx := false
		var has_charm_fx := false
		for effect in game.effects:
			var shape = String(Dictionary(effect).get("shape", ""))
			if shape.find("youmu") != -1 and (shape.find("slash") != -1 or shape.find("sword") != -1):
				has_slash_fx = true
			if shape.find("youmu") != -1 and (shape.find("ghost") != -1 or shape.find("wraith") != -1):
				has_ghost_fx = true
			if shape.find("charm") != -1:
				has_charm_fx = true
		passed = _assert_true(has_slash_fx, "Youmu skills should create visible sword/slash effects") and passed
		passed = _assert_true(has_ghost_fx, "Youmu skills should create visible half-phantom or wraith effects") and passed
		passed = _assert_true(has_charm_fx, "Youmu skills should create visible charm effects") and passed
		passed = _assert_true(float(damaged_plant.get("health", 0.0)) > 0.0, "Youmu skill cycle should pressure plants without instantly deleting a 1400 HP plant") and passed
	_free_game(game)
	return passed


func _test_youmu_first_column_dash_does_not_trigger_mowers_or_loss() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-29")
	var passed = _assert_true(level_index != -1, "expected 2-29 to exist before checking first-column dash safety") \
		and _assert_true(game.has_method("_youmu_dash_to_cell"), "expected Youmu dash helper to exist")
	if passed:
		game.battle_state = game.BATTLE_PLAYING
		var bounds = Dictionary(game.call("_youmu_boss_bounds"))
		var boss = {
			"kind": "youmu_boss",
			"row": 2,
			"x": float(bounds.get("max_x", game.BOARD_ORIGIN.x + game.board_size.x - 24.0)),
			"boss_phase": 1,
			"health": 30400.0,
			"max_health": 30400.0,
		}
		boss = game.call("_youmu_dash_to_cell", boss, 2, 0, "test_first_column")
		passed = _assert_true(int(boss.get("row", -1)) == 2, "Youmu first-column dash should preserve the target row") and passed
		passed = _assert_true(float(boss.get("x", 0.0)) >= float(bounds.get("min_x", 0.0)), "Youmu first-column dash should clamp inside the board, not into the home/mower trigger zone") and passed
		passed = _assert_true(String(game.battle_state) == game.BATTLE_PLAYING, "Youmu first-column dash should not cause a level loss") and passed
		for mower in game.mowers:
			passed = _assert_true(not bool(Dictionary(mower).get("active", false)), "Youmu first-column dash should not activate lawn mowers") and passed
	_free_game(game)
	return passed


func _test_youmu_charm_state_decays_and_makes_plants_attack_plants() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_charm_plant_at_cell"), "expected plant charm helper to exist") \
		and _assert_true(game.has_method("_update_charmed_plants"), "expected plant charm update helper to exist")
	if passed:
		var charmed = game.call("_create_plant", "peashooter", 2, 4)
		charmed["health"] = 300.0
		game.grid[2][4] = charmed
		var target = game.call("_create_plant", "wallnut", 2, 5)
		target["health"] = 800.0
		game.grid[2][5] = target
		game.call("_charm_plant_at_cell", 2, 4, 1.2)
		var charmed_after = Dictionary(game.grid[2][4])
		passed = _assert_true(float(charmed_after.get("youmu_charm_timer", 0.0)) > 0.0, "Youmu charm should mark the plant with a temporary charm timer") and passed
		var target_health_before = float(Dictionary(game.grid[2][5]).get("health", 0.0))
		game.call("_update_charmed_plants", 0.7)
		var target_health_after = float(Dictionary(game.grid[2][5]).get("health", 0.0))
		passed = _assert_true(target_health_after < target_health_before, "A charmed plant should damage a nearby plant instead of attacking zombies") and passed
		game.call("_update_charmed_plants", 2.0)
		var recovered = Dictionary(game.grid[2][4])
		passed = _assert_true(float(recovered.get("youmu_charm_timer", 0.0)) <= 0.0, "Youmu charm should decay and let the plant recover") and passed
	_free_game(game)
	return passed
