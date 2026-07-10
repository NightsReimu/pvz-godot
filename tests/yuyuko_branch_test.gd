extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const AlmanacText = preload("res://scripts/data/almanac_text.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_2_30_unlocks_after_youmu_and_uses_sakura_branch() or failed
	failed = not _test_2_30_configures_youmu_midboss_and_yuyuko_revival_finale() or failed
	failed = not _test_yuyuko_assets_and_bgm_are_present() or failed
	failed = not _test_yuyuko_bgm_streams_loop() or failed
	failed = not _test_yuyuko_definition_and_almanac_copy() or failed
	failed = not _test_yuyuko_bgm_routing_and_revival_switch() or failed
	failed = not _test_yuyuko_graves_spirits_and_sakura_skill_fx() or failed
	failed = not _test_yuyuko_passive_graves_start_slowly_enough_for_grave_busters() or failed
	failed = not _test_yuyuko_uses_prebaked_left_facing_frames() or failed
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
	game.current_level = {"id": "test", "title": "测试关卡", "terrain": "day", "sky_sun_range": Vector2(999.0, 999.0), "events": []}
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
	game.rng.seed = 3030
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


func _test_2_30_unlocks_after_youmu_and_uses_sakura_branch() -> bool:
	var level_index = _find_level_index("2-30")
	var youmu_index = _find_level_index("2-29")
	var passed = _assert_true(level_index != -1, "expected 2-30 to exist") \
		and _assert_true(youmu_index != -1, "expected 2-29 to exist as the 2-30 unlock requirement")
	if not passed:
		return false
	var level = Defs.LEVELS[level_index]
	passed = _assert_true(String(level.get("world", "")) == "night", "2-30 should be explicitly attached to the night world") and passed
	passed = _assert_true(String(level.get("terrain", "")) == "saigyouji_sakura", "2-30 should use the saigyouji_sakura terrain") and passed
	passed = _assert_true(String(level.get("branch_from", "")) == "2-29", "2-30 should continue from 2-29") and passed
	var requirements = Array(level.get("unlock_requirements", []))
	passed = _assert_true(requirements.has("2-29"), "2-30 should unlock after Youmu 2-29 is completed") and passed
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "2-30 should stay locked before 2-29 is completed") and passed
	game.completed_levels[youmu_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "2-30 should unlock after 2-29 is completed") and passed
	_free_game(game)
	return passed


func _test_2_30_configures_youmu_midboss_and_yuyuko_revival_finale() -> bool:
	var level_index = _find_level_index("2-30")
	if not _assert_true(level_index != -1, "expected 2-30 to exist before checking wave structure"):
		return false
	var level = Defs.LEVELS[level_index]
	var has_yuyuko_finale := false
	var yuyuko_time := 0.0
	var wave_count := 0
	for event in Array(level.get("events", [])):
		var event_dict := Dictionary(event)
		if bool(event_dict.get("wave", false)):
			wave_count += 1
		if String(event_dict.get("kind", "")) == "yuyuko_boss":
			has_yuyuko_finale = true
			yuyuko_time = float(event_dict.get("time", 0.0))
	var conveyor_plants = Array(level.get("conveyor_plants", []))
	var passed = _assert_true(bool(level.get("boss_level", false)), "2-30 should be marked as a boss level") \
		and _assert_true(String(level.get("mode", "")) == "conveyor", "2-30 should be a conveyor level") \
		and _assert_true(String(level.get("mid_boss_kind", "")) == "youmu_boss", "2-30 should configure Youmu as the Stage 6 midboss") \
		and _assert_true(has_yuyuko_finale, "2-30 should include a yuyuko_boss final event") \
		and _assert_true(wave_count >= 6 and wave_count <= 8, "2-30 should have a compact Stage 6 route") \
		and _assert_true(yuyuko_time >= 126.0 and yuyuko_time <= 148.0, "2-30 Yuyuko finale should start after a not-too-long Stage 6 route") \
		and _assert_true(conveyor_plants.has("grave_buster"), "2-30 conveyor should include grave_buster for the growing graves") \
		and _assert_true(not conveyor_plants.has("flower_pot"), "sakura courtyard conveyor should not require flower pots") \
		and _assert_true(not conveyor_plants.has("lily_pad"), "sakura courtyard conveyor should not include lily pads") \
		and _assert_true(String(level.get("boss_intro_bgm", "")) == "res://audio/yuyuko_intro.mp3", "2-30 should use Yuyuko intro BGM for the route") \
		and _assert_true(String(level.get("boss_bgm", "")) == "res://audio/yuyuko_boss.mp3", "2-30 should switch to Yuyuko finale BGM") \
		and _assert_true(String(level.get("boss_revival_bgm", "")) == "res://audio/yuyuko_revival.mp3", "2-30 should switch BGM after Yuyuko revives")
	return passed


func _test_yuyuko_assets_and_bgm_are_present() -> bool:
	var passed := true
	for path in ["res://audio/yuyuko_intro.mp3", "res://audio/yuyuko_boss.mp3", "res://audio/yuyuko_revival.mp3"]:
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
	var game = _make_game()
	var frame_count := int(game.call("_boss_frame_count_for_kind", "yuyuko_boss"))
	passed = _assert_true(frame_count == 24, "Yuyuko should use the 24-frame Touhou boss animation pipeline") and passed
	_free_game(game)
	for frame_index in range(max(frame_count, 24)):
		var path = "res://art/yuyuko/frame_%02d.png" % frame_index
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
		if FileAccess.file_exists(path):
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			if _assert_true(image != null and not image.is_empty(), "%s should load as an image" % path):
				var corner_alpha = image.get_pixel(0, 0).a + image.get_pixel(image.get_width() - 1, 0).a + image.get_pixel(0, image.get_height() - 1).a + image.get_pixel(image.get_width() - 1, image.get_height() - 1).a
				passed = _assert_true(corner_alpha <= 0.05, "%s should have transparent corners after white-background cleanup" % path) and passed
	return passed


func _test_yuyuko_bgm_streams_loop() -> bool:
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/yuyuko_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/yuyuko_boss.mp3")
	var revival_stream = game._load_audio_stream("res://audio/yuyuko_revival.mp3")
	var passed = _assert_true(intro_stream is AudioStreamMP3, "yuyuko intro BGM should load as AudioStreamMP3") \
		and _assert_true(boss_stream is AudioStreamMP3, "yuyuko boss BGM should load as AudioStreamMP3") \
		and _assert_true(revival_stream is AudioStreamMP3, "yuyuko revival BGM should load as AudioStreamMP3")
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "yuyuko intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "yuyuko boss BGM should loop") and passed
	if revival_stream is AudioStreamMP3:
		passed = _assert_true(bool(revival_stream.loop), "yuyuko revival BGM should loop") and passed
	_free_game(game)
	return passed


func _test_yuyuko_definition_and_almanac_copy() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("yuyuko_boss"), "expected yuyuko_boss zombie definition to exist")
	if not passed:
		return false
	var data = Dictionary(Defs.ZOMBIES.get("yuyuko_boss", {}))
	passed = _assert_true(bool(data.get("boss", false)), "yuyuko_boss should be marked as a boss") and passed
	passed = _assert_true(float(data.get("health", 0.0)) >= 32000.0, "yuyuko_boss should be tougher than Youmu before revival pressure") and passed
	passed = _assert_true(int(data.get("skill_cycle_length", 0)) >= 9, "yuyuko_boss should have a broad Stage 6 spell cycle") and passed
	passed = _assert_true(bool(data.get("revive_once", false)), "yuyuko_boss should revive once") and passed
	passed = _assert_true(float(data.get("skill_interval_min", 0.0)) >= 4.6, "Yuyuko skill floor should preserve a reaction window") and passed
	var game = _make_game()
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("yuyuko_boss"), "yuyuko_boss should be visible in the zombie almanac") and passed
	var joined = "\n".join(PackedStringArray(AlmanacText.zombie_lines("yuyuko_boss")))
	passed = _assert_true(joined.find("幽幽子") != -1 and joined.find("樱花") != -1, "Yuyuko almanac text should mention Yuyuko and sakura pressure") and passed
	passed = _assert_true(joined.find("亡灵") != -1 and joined.find("西行妖") != -1, "Yuyuko almanac text should mention spirits and Saigyou Ayakashi") and passed
	_free_game(game)
	return passed


func _test_yuyuko_bgm_routing_and_revival_switch() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-30")
	var passed = _assert_true(level_index != -1, "expected 2-30 to exist for BGM routing") \
		and _assert_true(game.has_method("_trigger_yuyuko_boss_revival"), "expected dedicated Yuyuko revival helper to exist")
	if passed:
		get_root().add_child(game)
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "youmu_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) != "res://audio/yuyuko_boss.mp3" and String(game.current_bgm_path) != "res://audio/yuyuko_boss.mp3", "2-30 Youmu midboss should not start Yuyuko's finale BGM") and passed
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "yuyuko_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) == "res://audio/yuyuko_boss.mp3" or String(game.current_bgm_path) == "res://audio/yuyuko_boss.mp3", "Yuyuko final boss should start the finale BGM") and passed
		if not game.zombies.is_empty():
			var boss = Dictionary(game.zombies[game.zombies.size() - 1])
			boss["health"] = 0.0
			game.pending_bgm_path = ""
			game.current_bgm_path = ""
			boss = game.call("_trigger_yuyuko_boss_revival", boss)
			passed = _assert_true(bool(boss.get("yuyuko_revived", false)), "Yuyuko revival helper should mark the boss as revived") and passed
			passed = _assert_true(float(boss.get("health", 0.0)) > 0.0, "Yuyuko revival should restore health instead of removing the boss") and passed
			passed = _assert_true(String(game.pending_bgm_path) == "res://audio/yuyuko_revival.mp3" or String(game.current_bgm_path) == "res://audio/yuyuko_revival.mp3", "Yuyuko revival should switch to the post-revival BGM") and passed
	_free_game(game)
	return passed


func _test_yuyuko_graves_spirits_and_sakura_skill_fx() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-30")
	var passed = _assert_true(level_index != -1, "expected 2-30 to exist before exercising Yuyuko skills") \
		and _assert_true(game.has_method("_grow_yuyuko_graves"), "expected Yuyuko grave growth helper to exist") \
		and _assert_true(game.has_method("_trigger_yuyuko_boss_skill"), "expected dedicated Yuyuko skill trigger to exist") \
		and _assert_true(game.has_method("_spawn_yuyuko_grave_spirits"), "expected grave spirit spawn helper to exist")
	if passed:
		var plant = game.call("_create_plant", "tallnut", 2, 5)
		plant["health"] = 1400.0
		game.grid[2][5] = plant
		game.call("_grow_yuyuko_graves", 99.0)
		passed = _assert_true(game.graves.size() > 0, "Yuyuko stage should grow graves during battle") and passed
		var boss = {
			"kind": "yuyuko_boss",
			"row": 2,
			"x": game.BOARD_ORIGIN.x + game.board_size.x - 12.0,
			"boss_phase": 1,
			"boss_skill_cycle": 0,
			"health": float(Defs.ZOMBIES.get("yuyuko_boss", {}).get("health", 33000.0)),
			"max_health": float(Defs.ZOMBIES.get("yuyuko_boss", {}).get("health", 33000.0)),
		}
		for cycle in range(9):
			boss["boss_skill_cycle"] = cycle
			boss = game.call("_trigger_yuyuko_boss_skill", boss)
		game.call("_spawn_yuyuko_grave_spirits", 2)
		var has_sakura_fx := false
		var has_butterfly_fx := false
		var has_tree_fx := false
		var has_grave_fx := false
		for effect in game.effects:
			var shape = String(Dictionary(effect).get("shape", ""))
			if shape.find("yuyuko_sakura") != -1 or shape.find("yuyuko_full_bloom") != -1:
				has_sakura_fx = true
			if shape.find("yuyuko_butterfly") != -1:
				has_butterfly_fx = true
			if shape.find("yuyuko_saigyou_tree") != -1 or shape.find("yuyuko_resurrection") != -1:
				has_tree_fx = true
			if shape.find("yuyuko_grave") != -1 or shape.find("yuyuko_spirit") != -1:
				has_grave_fx = true
		var spirit_count := 0
		for z in game.zombies:
			if String(Dictionary(z).get("kind", "")) == "yuyuko_spirit":
				spirit_count += 1
		var damaged_plant = Dictionary(game.grid[2][5])
		passed = _assert_true(has_sakura_fx, "Yuyuko skills should create dedicated sakura effects") and passed
		passed = _assert_true(has_butterfly_fx, "Yuyuko skills should create dedicated butterfly effects") and passed
		passed = _assert_true(has_tree_fx, "Yuyuko skills should show Saigyou Ayakashi or resurrection tree effects") and passed
		passed = _assert_true(has_grave_fx, "Yuyuko skills and grave growth should create grave/spirit effects") and passed
		passed = _assert_true(spirit_count > 0, "Yuyuko grave death/revival pressure should spawn physical spirit enemies") and passed
		passed = _assert_true(float(damaged_plant.get("health", 0.0)) > 0.0, "Yuyuko skill cycle should pressure plants without instantly deleting a 1400 HP plant") and passed
	_free_game(game)
	return passed


func _test_yuyuko_passive_graves_start_slowly_enough_for_grave_busters() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-30")
	var passed = _assert_true(level_index != -1, "expected 2-30 to exist before checking passive grave pacing")
	if passed:
		passed = _assert_true(float(game.yuyuko_grave_timer) >= 22.0, "Yuyuko passive graves should not appear before the conveyor has time to offer grave_buster") and passed
		game.call("_grow_yuyuko_graves", 18.0)
		passed = _assert_true(game.graves.is_empty(), "Yuyuko passive graves should not spawn during the early no-grave-buster opening") and passed
		game.yuyuko_grave_timer = 0.0
		game.call("_grow_yuyuko_graves", 1.0)
		passed = _assert_true(game.graves.size() == 1, "Yuyuko passive grave growth should add only one grave at a time") and passed
		passed = _assert_true(float(game.yuyuko_grave_timer) >= 18.0, "Yuyuko passive grave interval should be slow enough for grave_buster counterplay") and passed
		game.active_cards = ["puff_shroom", "snow_pea", "wallnut", "repeater", "fume_shroom", "ice_shroom"]
		game.yuyuko_grave_timer = 0.0
		game.call("_grow_yuyuko_graves", 99.0)
		passed = _assert_true(game.graves.size() == 1, "Yuyuko should pause passive grave growth while no grave_buster is available for existing graves") and passed
		game.active_cards[0] = "grave_buster"
		game.yuyuko_grave_timer = 0.0
		game.call("_grow_yuyuko_graves", 99.0)
		passed = _assert_true(game.graves.size() == 2, "Yuyuko may continue passive grave growth once grave_buster counterplay is available") and passed
	_free_game(game)
	return passed


func _test_yuyuko_uses_prebaked_left_facing_frames() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_boss_frames_face_left"), "expected boss frame orientation helper to exist") \
		and _assert_true(not bool(game.call("_boss_frames_face_left", "yuyuko_boss")), "Yuyuko should use prebaked left-facing frames without runtime mirroring")
	_free_game(game)
	return passed
