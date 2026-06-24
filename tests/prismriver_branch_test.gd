extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const AlmanacText = preload("res://scripts/data/almanac_text.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_2_28_unlocks_after_alice_and_uses_cloud_branch() or failed
	failed = not _test_2_28_configures_lily_midboss_and_prismriver_finale() or failed
	failed = not _test_prismriver_assets_and_bgm_are_present() or failed
	failed = not _test_prismriver_bgm_streams_loop() or failed
	failed = not _test_lily_and_prismriver_definitions_and_almanac_copy() or failed
	failed = not _test_new_bosses_use_prebaked_left_facing_frames() or failed
	failed = not _test_cloud_sea_cells_drift_and_drop_unsupported_plants() or failed
	failed = not _test_prismriver_finale_bgm_starts_only_for_prismriver() or failed
	failed = not _test_lily_and_prismriver_skills_create_bounded_stage_four_pressure() or failed
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
	game.rng.seed = 2828
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


func _test_2_28_unlocks_after_alice_and_uses_cloud_branch() -> bool:
	var level_index = _find_level_index("2-28")
	var alice_index = _find_level_index("2-27")
	var passed = _assert_true(level_index != -1, "expected 2-28 to exist") \
		and _assert_true(alice_index != -1, "expected 2-27 to exist as the 2-28 unlock requirement")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	passed = _assert_true(String(level.get("world", "")) == "night", "2-28 should be explicitly attached to the night world") and passed
	passed = _assert_true(String(level.get("terrain", "")) == "cloud_sea", "2-28 should use the cloud_sea terrain") and passed
	passed = _assert_true(String(level.get("branch_from", "")) == "2-27", "2-28 should continue from 2-27") and passed
	var requirements = Array(level.get("unlock_requirements", []))
	passed = _assert_true(requirements.has("2-27"), "2-28 should unlock after Alice 2-27 is completed") and passed
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "2-28 should stay locked before 2-27 is completed") and passed
	game.completed_levels[alice_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "2-28 should unlock after 2-27 is completed") and passed
	_free_game(game)
	return passed


func _test_2_28_configures_lily_midboss_and_prismriver_finale() -> bool:
	var level_index = _find_level_index("2-28")
	if not _assert_true(level_index != -1, "expected 2-28 to exist before checking wave structure"):
		return false
	var level = Defs.LEVELS[level_index]
	var has_final_boss := false
	var final_boss_time := 0.0
	var wave_count := 0
	var last_wave_time := 0.0
	for event in level.get("events", []):
		if bool(event.get("wave", false)):
			wave_count += 1
			last_wave_time = maxf(last_wave_time, float(event.get("time", 0.0)))
		if String(event.get("kind", "")) == "prismriver_boss":
			has_final_boss = true
			final_boss_time = float(event.get("time", 0.0))
	var conveyor_plants = Array(level.get("conveyor_plants", []))
	var passed = _assert_true(bool(level.get("boss_level", false)), "2-28 should be marked as a boss level") \
		and _assert_true(String(level.get("mode", "")) == "conveyor", "2-28 should be a conveyor level") \
		and _assert_true(String(level.get("mid_boss_kind", "")) == "lily_white_boss", "2-28 should use Lily White as the half-way boss") \
		and _assert_true(has_final_boss, "2-28 should include a prismriver_boss final event") \
		and _assert_true(wave_count >= 9, "2-28 should have a long Stage 4-style route before the finale") \
		and _assert_true(last_wave_time >= 175.0, "2-28 should keep spawning route waves deep into the long mid-stage") \
		and _assert_true(final_boss_time >= 190.0, "2-28 Prismriver finale should not start until after a long cloud-sea route") \
		and _assert_true(not conveyor_plants.has("flower_pot"), "cloud_sea conveyor should not require flower pots") \
		and _assert_true(not conveyor_plants.has("lily_pad"), "cloud_sea conveyor should not include lily pads") \
		and _assert_true(not conveyor_plants.has("moon_lotus"), "cloud_sea conveyor should not include moon_lotus")
	return passed


func _test_prismriver_assets_and_bgm_are_present() -> bool:
	var passed := true
	for path in ["res://audio/prismriver_intro.mp3", "res://audio/prismriver_boss.mp3"]:
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
	for folder in ["lily_white", "prismriver"]:
		for frame_index in range(8):
			var path = "res://art/%s/frame_%02d.png" % [folder, frame_index]
			passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
			passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			if _assert_true(image != null and not image.is_empty(), "%s should load as an image" % path):
				var corner_alpha = image.get_pixel(0, 0).a + image.get_pixel(image.get_width() - 1, 0).a + image.get_pixel(0, image.get_height() - 1).a + image.get_pixel(image.get_width() - 1, image.get_height() - 1).a
				passed = _assert_true(corner_alpha <= 0.05, "%s should have transparent corners after white-background cleanup" % path) and passed
				if folder == "prismriver":
					passed = _assert_true(_edge_black_pixel_count(image) <= 6, "%s should not keep the source frame black border line" % path) and passed
	return passed


func _edge_black_pixel_count(image: Image) -> int:
	var count := 0
	var width = image.get_width()
	var height = image.get_height()
	for x in range(width):
		for y in [0, height - 1]:
			if _is_dark_solid_pixel(image.get_pixel(x, y)):
				count += 1
	for y in range(height):
		for x in [0, width - 1]:
			if _is_dark_solid_pixel(image.get_pixel(x, y)):
				count += 1
	return count


func _is_dark_solid_pixel(pixel: Color) -> bool:
	return pixel.a > 0.6 and pixel.r < 0.08 and pixel.g < 0.08 and pixel.b < 0.08


func _test_prismriver_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/prismriver_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/prismriver_boss.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "prismriver intro BGM should load as AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "prismriver boss BGM should load as AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "prismriver intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "prismriver boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_lily_and_prismriver_definitions_and_almanac_copy() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("lily_white_boss"), "expected lily_white_boss zombie definition to exist") \
		and _assert_true(Defs.ZOMBIES.has("prismriver_boss"), "expected prismriver_boss zombie definition to exist")
	if not passed:
		return false
	var lily = Dictionary(Defs.ZOMBIES.get("lily_white_boss", {}))
	var prismriver = Dictionary(Defs.ZOMBIES.get("prismriver_boss", {}))
	passed = _assert_true(bool(lily.get("boss", false)), "lily_white_boss should be marked as a boss") and passed
	passed = _assert_true(float(lily.get("health", 0.0)) == 16200.0, "lily_white_boss should use the planned 16200 HP") and passed
	passed = _assert_true(int(lily.get("skill_cycle_length", 0)) == 4, "lily_white_boss should have a four-spell skill cycle") and passed
	passed = _assert_true(bool(prismriver.get("boss", false)), "prismriver_boss should be marked as a boss") and passed
	passed = _assert_true(float(prismriver.get("health", 0.0)) == 28600.0, "prismriver_boss should use the planned 28600 HP") and passed
	passed = _assert_true(int(prismriver.get("skill_cycle_length", 0)) == 8, "prismriver_boss should have an eight-spell skill cycle") and passed
	var game = _make_game()
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("lily_white_boss"), "lily_white_boss should be visible in the zombie almanac") and passed
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("prismriver_boss"), "prismriver_boss should be visible in the zombie almanac") and passed
	var lily_joined = "\n".join(PackedStringArray(AlmanacText.zombie_lines("lily_white_boss")))
	var prism_joined = "\n".join(PackedStringArray(AlmanacText.zombie_lines("prismriver_boss")))
	passed = _assert_true(lily_joined.find("报春") != -1 or lily_joined.find("春") != -1, "Lily White almanac text should mention spring herald pressure") and passed
	passed = _assert_true(prism_joined.find("三姐妹") != -1 and (prism_joined.find("音乐") != -1 or prism_joined.find("合奏") != -1), "Prismriver almanac text should mention the three sisters and their music") and passed
	_free_game(game)
	return passed


func _test_new_bosses_use_prebaked_left_facing_frames() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_boss_frames_face_left"), "expected boss frame orientation helper to exist") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "lily_white_boss")), "Lily White should use prebaked left-facing frames without runtime mirroring") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "prismriver_boss")), "Prismriver should use prebaked left-facing frames without runtime mirroring")
	_free_game(game)
	return passed


func _test_cloud_sea_cells_drift_and_drop_unsupported_plants() -> bool:
	var game = _make_game()
	game.current_level = {"id": "cloud-test", "terrain": "cloud_sea", "events": [], "row_count": 5}
	var passed = _assert_true(game.has_method("_is_cloud_sea_level"), "expected cloud_sea terrain helper to exist") \
		and _assert_true(game.has_method("_initialize_cloud_sea_mask"), "expected cloud sea mask initializer to exist") \
		and _assert_true(game.has_method("_shift_cloud_sea_left"), "expected cloud sea shift helper to exist") \
		and _assert_true(game.has_method("_drop_plants_without_cloud"), "expected cloud plant drop helper to exist")
	if passed:
		game.call("_setup_cell_terrain_mask")
		game.call("_initialize_cloud_sea_mask")
		passed = _assert_true(String(game.call("_cell_terrain_kind", 2, 3)) == "cloud", "cloud_sea should initialize plantable cloud cells") and passed
		passed = _assert_true(String(game.call("_placement_error", "peashooter", 2, 3)) == "", "normal plants should be placeable on cloud cells") and passed
		game.call("_set_cell_terrain_kind", 2, 3, "sky_gap")
		passed = _assert_true(String(game.call("_placement_error", "peashooter", 2, 3)).find("云") != -1, "sky_gap cells should reject planting with a cloud-specific message") and passed
		game.call("_set_cell_terrain_kind", 2, 3, "cloud")
		game.grid[2][3] = game.call("_create_plant", "wallnut", 2, 3)
		game.call("_set_cell_terrain_kind", 2, 3, "sky_gap")
		game.call("_drop_plants_without_cloud")
		passed = _assert_true(game.grid[2][3] == null, "plants should fall when their cloud cell disappears") and passed
		var has_fall_fx := false
		for effect in game.effects:
			if String(Dictionary(effect).get("shape", "")) == "cloud_plant_fall":
				has_fall_fx = true
		passed = _assert_true(has_fall_fx, "falling cloud plants should create a cloud_plant_fall effect") and passed
		game.effects.clear()
		game.call("_initialize_cloud_sea_mask")
		var two_gap_columns := 0
		for seed in range(1, 21):
			var gap_rows = Array(game.call("_cloud_gap_rows_for_seed", seed))
			passed = _assert_true(gap_rows.size() <= 2, "cloud sea should never generate three gaps in one incoming column") and passed
			if gap_rows.size() == 2:
				two_gap_columns += 1
		passed = _assert_true(two_gap_columns <= 4, "cloud sea should generate two-gap columns only occasionally") and passed
		var before_col_1 = String(game.call("_cell_terrain_kind", 1, 1))
		game.call("_shift_cloud_sea_left")
		passed = _assert_true(String(game.call("_cell_terrain_kind", 1, 0)) == before_col_1, "cloud columns should drift left by one cell") and passed
		for _shift_index in range(14):
			game.call("_shift_cloud_sea_left")
		passed = _assert_true(_cloud_cell_ratio(game) >= 0.78, "cloud sea should keep at least 78 percent of cells plantable after repeated drifts") and passed
		passed = _assert_true(_max_horizontal_sky_gap_run(game) <= 1, "cloud sea should not create adjacent sky gaps in the same row") and passed
	_free_game(game)
	return passed


func _max_horizontal_sky_gap_run(game: Control) -> int:
	var longest := 0
	for row in game.active_rows:
		var current := 0
		for col in range(game.COLS):
			if String(game.call("_cell_terrain_kind", int(row), col)) == "sky_gap":
				current += 1
				longest = maxi(longest, current)
			else:
				current = 0
	return longest


func _cloud_cell_ratio(game: Control) -> float:
	var clouds := 0
	var total := 0
	for row in game.active_rows:
		for col in range(game.COLS):
			total += 1
			if String(game.call("_cell_terrain_kind", int(row), col)) == "cloud":
				clouds += 1
	return float(clouds) / maxf(1.0, float(total))


func _test_prismriver_finale_bgm_starts_only_for_prismriver() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-28")
	var passed = _assert_true(level_index != -1, "expected 2-28 to exist for BGM routing")
	if passed:
		get_root().add_child(game)
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "lily_white_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) != "res://audio/prismriver_boss.mp3" and String(game.current_bgm_path) != "res://audio/prismriver_boss.mp3", "2-28 Lily midboss should not start Prismriver's finale BGM") and passed
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "prismriver_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) == "res://audio/prismriver_boss.mp3" or String(game.current_bgm_path) == "res://audio/prismriver_boss.mp3", "Prismriver final boss should start the finale BGM") and passed
	_free_game(game)
	return passed


func _test_lily_and_prismriver_skills_create_bounded_stage_four_pressure() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-28")
	var passed = _assert_true(level_index != -1, "expected 2-28 to exist before exercising Stage 4 skills") \
		and _assert_true(game.has_method("_trigger_lily_white_boss_skill"), "expected dedicated Lily White skill trigger to exist") \
		and _assert_true(game.has_method("_trigger_prismriver_boss_skill"), "expected dedicated Prismriver skill trigger to exist") \
		and _assert_true(game.has_method("_prismriver_boss_bounds"), "expected Prismriver bounds helper to exist")
	if passed:
		var lily_plant = game.call("_create_plant", "tallnut", 2, 5)
		lily_plant["health"] = 900.0
		lily_plant["shot_cooldown"] = 0.0
		game.grid[2][5] = lily_plant
		var lily = {
			"kind": "lily_white_boss",
			"row": 2,
			"x": game.BOARD_ORIGIN.x + game.board_size.x - 24.0,
			"boss_phase": 1,
			"boss_skill_cycle": 0,
			"health": float(Defs.ZOMBIES.get("lily_white_boss", {}).get("health", 16200.0)),
			"max_health": float(Defs.ZOMBIES.get("lily_white_boss", {}).get("health", 16200.0)),
		}
		for cycle in range(4):
			lily["boss_skill_cycle"] = cycle
			lily = game.call("_trigger_lily_white_boss_skill", lily)
		var lily_damaged_plant = Dictionary(game.grid[2][5])
		var has_lily_fx := false
		for effect in game.effects:
			if String(Dictionary(effect).get("shape", "")).find("lily") != -1:
				has_lily_fx = true
		passed = _assert_true(has_lily_fx, "Lily White skills should create visible lily/spring effects") and passed
		passed = _assert_true(float(lily_damaged_plant.get("health", 0.0)) > 0.0, "Lily White skill cycle should pressure plants without instantly deleting a 900 HP plant") and passed
		game.effects.clear()
		var prism_plant = game.call("_create_plant", "tallnut", 2, 5)
		prism_plant["health"] = 1400.0
		prism_plant["shot_cooldown"] = 0.0
		game.grid[2][5] = prism_plant
		var bounds = Dictionary(game.call("_prismriver_boss_bounds"))
		var prismriver = {
			"kind": "prismriver_boss",
			"row": 2,
			"x": float(bounds.get("min_x", game.BOARD_ORIGIN.x)) - 120.0,
			"boss_phase": 1,
			"boss_skill_cycle": 0,
			"health": float(Defs.ZOMBIES.get("prismriver_boss", {}).get("health", 28600.0)),
			"max_health": float(Defs.ZOMBIES.get("prismriver_boss", {}).get("health", 28600.0)),
		}
		for cycle in range(8):
			prismriver["boss_skill_cycle"] = cycle
			prismriver = game.call("_trigger_prismriver_boss_skill", prismriver)
			passed = _assert_true(float(prismriver.get("x", 0.0)) >= float(bounds.get("min_x", 0.0)) and float(prismriver.get("x", 0.0)) <= float(bounds.get("max_x", 0.0)), "Prismriver boss should stay within the right five columns") and passed
		var prism_damaged_plant = Dictionary(game.grid[2][5])
		var has_prism_fx := false
		for effect in game.effects:
			if String(Dictionary(effect).get("shape", "")).find("prismriver") != -1:
				has_prism_fx = true
		passed = _assert_true(has_prism_fx, "Prismriver skills should create visible music/prism effects") and passed
		passed = _assert_true(float(prism_damaged_plant.get("health", 0.0)) > 0.0, "Prismriver skill cycle should pressure plants without instantly deleting a 1400 HP plant") and passed
	_free_game(game)
	return passed
