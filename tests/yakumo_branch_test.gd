extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const AlmanacText = preload("res://scripts/data/almanac_text.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_2_31_unlock_and_route_configuration() or failed
	failed = not _test_2_31_enemy_and_conveyor_pools() or failed
	failed = not _test_yakumo_definitions_and_almanac() or failed
	failed = not _test_yakumo_assets_and_audio() or failed
	failed = not _test_yakumo_bgm_routing_and_successor_transition() or failed
	failed = not _test_yakumo_spell_effects_and_bounds() or failed
	failed = not _test_yakumo_phase_pressure_and_render_scale() or failed
	failed = not _test_hakugyokurou_preview_style() or failed
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
	game.effects = []
	game.graves = []
	game.mowers = []
	for row in range(6):
		game.mowers.append({"row": row, "x": game.BOARD_ORIGIN.x - 56.0, "armed": true, "active": false})
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	game.rng.seed = 2031
	return game


func _free_game(game: Control) -> void:
	for node in [game.toast_label, game.banner_label, game.message_label, game.action_button, game.message_panel]:
		if is_instance_valid(node):
			node.free()
	if game.is_inside_tree():
		game.get_parent().remove_child(game)
	game.free()


func _begin_level(game: Control, level_id: String) -> int:
	var index = _find_level_index(level_id)
	if index != -1:
		game.call("_begin_level", index, [])
	return index


func _test_2_31_unlock_and_route_configuration() -> bool:
	var level_index = _find_level_index("2-31")
	var previous_index = _find_level_index("2-30")
	var passed = _assert_true(level_index != -1, "expected 2-31 to exist") \
		and _assert_true(previous_index != -1, "expected 2-30 to exist as the unlock requirement")
	if not passed:
		return false
	var level = Dictionary(Defs.LEVELS[level_index])
	var has_ran_finale := false
	var final_time := 0.0
	var wave_count := 0
	for event_variant in Array(level.get("events", [])):
		var event = Dictionary(event_variant)
		if bool(event.get("wave", false)):
			wave_count += 1
		if String(event.get("kind", "")) == "ran_boss":
			has_ran_finale = true
			final_time = float(event.get("time", 0.0))
	passed = _assert_true(String(level.get("world", "")) == "night", "2-31 should belong to the night chapter") and passed
	passed = _assert_true(String(level.get("terrain", "")) == "hakugyokurou_border", "2-31 should use the Netherworld cherry-tree terrain") and passed
	passed = _assert_true(String(level.get("mode", "")) == "conveyor", "2-31 should be a conveyor level") and passed
	passed = _assert_true(bool(level.get("boss_level", false)), "2-31 should be marked as a boss level") and passed
	passed = _assert_true(String(level.get("branch_from", "")) == "2-30", "2-31 should continue after 2-30") and passed
	passed = _assert_true(Array(level.get("unlock_requirements", [])).has("2-30"), "2-31 should unlock after 2-30") and passed
	passed = _assert_true(String(level.get("mid_boss_kind", "")) == "chen_boss", "2-31 should use Chen as the Extra-stage midboss") and passed
	passed = _assert_true(has_ran_finale, "2-31 should spawn Ran as the finale entry boss") and passed
	passed = _assert_true(final_time >= 118.0 and final_time <= 142.0, "2-31 route should be substantial but not excessively long") and passed
	passed = _assert_true(wave_count >= 5 and wave_count <= 7, "2-31 should use a compact Extra-stage route") and passed
	var game = _make_game()
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "2-31 should stay locked before 2-30 is completed") and passed
	game.completed_levels[previous_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "2-31 should unlock after 2-30 is completed") and passed
	_free_game(game)
	return passed


func _test_2_31_enemy_and_conveyor_pools() -> bool:
	var level_index = _find_level_index("2-31")
	if not _assert_true(level_index != -1, "expected 2-31 before checking its pools"):
		return false
	var level = Dictionary(Defs.LEVELS[level_index])
	var event_kinds: Array = []
	for event_variant in Array(level.get("events", [])):
		event_kinds.append(String(Dictionary(event_variant).get("kind", "")))
	var conveyor = Array(level.get("conveyor_plants", []))
	var passed = _assert_true(not event_kinds.has("flywheel_zombie"), "2-31 must exclude flywheel zombies") \
		and _assert_true(not event_kinds.has("programmer_zombie"), "2-31 must exclude programmer zombies") \
		and _assert_true(event_kinds.has("nether") and event_kinds.has("digger_zombie"), "2-31 should use Netherworld and underground pressure enemies") \
		and _assert_true(conveyor.has("grave_buster"), "2-31 conveyor should retain grave counterplay") \
		and _assert_true(conveyor.has("blover") and conveyor.has("cactus"), "2-31 conveyor should answer aerial pressure") \
		and _assert_true(not conveyor.has("moon_lotus"), "2-31 conveyor should not use moon lotus") \
		and _assert_true(not conveyor.has("flower_pot") and not conveyor.has("lily_pad"), "2-31 land terrain should not include support-planter cards")
	return passed


func _test_yakumo_definitions_and_almanac() -> bool:
	var passed = _assert_true(Defs.ZOMBIES.has("ran_boss"), "expected ran_boss definition") \
		and _assert_true(Defs.ZOMBIES.has("yukari_boss"), "expected yukari_boss definition")
	if not passed:
		return false
	var ran = Dictionary(Defs.ZOMBIES.get("ran_boss", {}))
	var yukari = Dictionary(Defs.ZOMBIES.get("yukari_boss", {}))
	passed = _assert_true(bool(ran.get("boss", false)) and bool(yukari.get("boss", false)), "both Yakumo characters should be bosses") and passed
	passed = _assert_true(String(ran.get("successor_kind", "")) == "yukari_boss", "Ran should transition into Yukari on defeat") and passed
	passed = _assert_true(int(ran.get("skill_cycle_length", 0)) >= 8, "Ran should have a broad Extra-stage spell cycle") and passed
	passed = _assert_true(int(yukari.get("skill_cycle_length", 0)) >= 10, "Yukari should have an expanded gap-youkai spell cycle") and passed
	passed = _assert_true(float(ran.get("skill_interval_min", 0.0)) >= 4.5 and float(yukari.get("skill_interval_min", 0.0)) >= 4.5, "Yakumo spell cards should preserve reaction windows") and passed
	var game = _make_game()
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("ran_boss"), "Ran should appear in the almanac") and passed
	passed = _assert_true(Array(game.ZOMBIE_ALMANAC_ORDER).has("yukari_boss"), "Yukari should appear in the almanac") and passed
	var ran_text = "\n".join(PackedStringArray(AlmanacText.zombie_lines("ran_boss")))
	var yukari_text = "\n".join(PackedStringArray(AlmanacText.zombie_lines("yukari_boss")))
	passed = _assert_true(ran_text.find("八云蓝") != -1 and ran_text.find("式神") != -1, "Ran almanac copy should mention her identity and shikigami spells") and passed
	passed = _assert_true(yukari_text.find("八云紫") != -1 and yukari_text.find("隙间") != -1, "Yukari almanac copy should describe her as a gap youkai") and passed
	_free_game(game)
	return passed


func _test_yakumo_assets_and_audio() -> bool:
	var passed := true
	for path in ["res://audio/yakumo_intro.mp3", "res://audio/ran_boss.mp3", "res://audio/yukari_boss.mp3"]:
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have an import sidecar" % path) and passed
	var game = _make_game()
	for kind in ["ran_boss", "yukari_boss"]:
		var count := int(game.call("_boss_frame_count_for_kind", kind))
		passed = _assert_true(count == 24, "%s should use 24 animation frames" % kind) and passed
		passed = _assert_true(not bool(game.call("_boss_frames_face_left", kind)), "%s should use prebaked left-facing frames" % kind) and passed
		var folder = "ran" if kind == "ran_boss" else "yukari"
		for frame_index in range(24):
			var path = "res://art/%s/frame_%02d.png" % [folder, frame_index]
			passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
			passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have an import sidecar" % path) and passed
			if FileAccess.file_exists(path):
				var image := Image.load_from_file(ProjectSettings.globalize_path(path))
				if image != null and not image.is_empty():
					var alpha_sum = image.get_pixel(0, 0).a + image.get_pixel(image.get_width() - 1, 0).a + image.get_pixel(0, image.get_height() - 1).a + image.get_pixel(image.get_width() - 1, image.get_height() - 1).a
					passed = _assert_true(alpha_sum <= 0.05, "%s should have transparent corners" % path) and passed
	for path in ["res://audio/yakumo_intro.mp3", "res://audio/ran_boss.mp3", "res://audio/yukari_boss.mp3"]:
		var stream = game._load_audio_stream(path)
		passed = _assert_true(stream is AudioStreamMP3 and bool(stream.loop), "%s should load as looping MP3" % path) and passed
	_free_game(game)
	return passed


func _test_yakumo_bgm_routing_and_successor_transition() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-31")
	var passed = _assert_true(level_index != -1, "expected 2-31 for BGM routing") \
		and _assert_true(game.has_method("_trigger_ran_boss_successor"), "expected a dedicated Ran-to-Yukari transition helper")
	if passed:
		get_root().add_child(game)
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "chen_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) != "res://audio/ran_boss.mp3" and String(game.current_bgm_path) != "res://audio/ran_boss.mp3", "Chen midboss should keep route music") and passed
		game.pending_bgm_path = ""
		game.current_bgm_path = ""
		game.call("_spawn_zombie_at", "ran_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
		passed = _assert_true(String(game.pending_bgm_path) == "res://audio/ran_boss.mp3" or String(game.current_bgm_path) == "res://audio/ran_boss.mp3", "Ran should start her boss music") and passed
		if not game.zombies.is_empty():
			var ran = Dictionary(game.zombies[game.zombies.size() - 1])
			var successor = Dictionary(game.call("_trigger_ran_boss_successor", ran))
			passed = _assert_true(String(successor.get("kind", "")) == "yukari_boss", "defeating Ran should create Yukari") and passed
			passed = _assert_true(float(successor.get("health", 0.0)) > 0.0, "Yukari successor should start alive") and passed
			passed = _assert_true(String(game.pending_bgm_path) == "res://audio/yukari_boss.mp3" or String(game.current_bgm_path) == "res://audio/yukari_boss.mp3", "Yukari transition should switch BGM") and passed
	_free_game(game)
	return passed


func _test_yakumo_spell_effects_and_bounds() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "2-31")
	var passed = _assert_true(level_index != -1, "expected 2-31 before exercising Yakumo skills") \
		and _assert_true(game.has_method("_trigger_ran_boss_skill"), "expected dedicated Ran skill helper") \
		and _assert_true(game.has_method("_trigger_yukari_boss_skill"), "expected dedicated Yukari skill helper")
	if passed:
		var plant = game.call("_create_plant", "tallnut", 2, 5)
		plant["health"] = 1600.0
		game.grid[2][5] = plant
		for kind in ["ran_boss", "yukari_boss"]:
			var data = Dictionary(Defs.ZOMBIES.get(kind, {}))
			var boss = {"kind": kind, "row": 2, "x": game.BOARD_ORIGIN.x + game.board_size.x - 36.0, "boss_phase": 1, "boss_skill_cycle": 0, "health": float(data.get("health", 1.0)), "max_health": float(data.get("health", 1.0))}
			for cycle in range(int(data.get("skill_cycle_length", 1))):
				boss["boss_skill_cycle"] = cycle
				boss = game.call("_trigger_ran_boss_skill" if kind == "ran_boss" else "_trigger_yukari_boss_skill", boss)
			var prefix = "ran_" if kind == "ran_boss" else "yukari_"
			var effect_count := 0
			for effect_variant in game.effects:
				if String(Dictionary(effect_variant).get("shape", "")).begins_with(prefix):
					effect_count += 1
			passed = _assert_true(effect_count >= int(data.get("skill_cycle_length", 1)), "%s should use dedicated spell-card effects" % kind) and passed
			passed = _assert_true(float(boss.get("x", 0.0)) >= game.BOARD_ORIGIN.x and float(boss.get("x", 0.0)) <= game.BOARD_ORIGIN.x + game.board_size.x, "%s should remain inside the board" % kind) and passed
		var damaged = Dictionary(game.grid[2][5])
		passed = _assert_true(float(damaged.get("health", 0.0)) > 0.0, "full Yakumo skill sampling should not instantly delete a 1600 HP plant") and passed
	_free_game(game)
	return passed


func _test_yakumo_phase_pressure_and_render_scale() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_trigger_ran_boss_phase_shift"), "Ran should expose a dedicated phase-shift helper") \
		and _assert_true(game.has_method("_trigger_yukari_boss_phase_shift"), "Yukari should expose a dedicated phase-shift helper") \
		and _assert_true(game.has_method("_ran_draw_scale"), "Ran should expose a compact render-scale helper") \
		and _assert_true(game.has_method("_yukari_draw_scale"), "Yukari should expose a compact render-scale helper")
	if passed:
		var ran = {"kind": "ran_boss", "row": 2, "x": game.BOARD_ORIGIN.x + game.board_size.x - 32.0}
		var yukari = {"kind": "yukari_boss", "row": 2, "x": game.BOARD_ORIGIN.x + game.board_size.x - 32.0}
		game.call("_trigger_ran_boss_phase_shift", ran, 1)
		game.call("_trigger_yukari_boss_phase_shift", yukari, 2)
		var has_ran_phase_fx := false
		var has_yukari_phase_fx := false
		for effect_variant in game.effects:
			var shape = String(Dictionary(effect_variant).get("shape", ""))
			has_ran_phase_fx = has_ran_phase_fx or shape.begins_with("ran_")
			has_yukari_phase_fx = has_yukari_phase_fx or shape.begins_with("yukari_")
		passed = _assert_true(has_ran_phase_fx, "Ran phase shifts should produce dedicated fox-shikigami FX") and passed
		passed = _assert_true(has_yukari_phase_fx, "Yukari phase shifts should produce dedicated boundary FX") and passed
		passed = _assert_true(float(game.call("_ran_draw_scale", 3)) <= 0.66, "Ran render scale should remain compact") and passed
		passed = _assert_true(float(game.call("_yukari_draw_scale", 3)) <= 0.62, "Yukari render scale should remain compact") and passed
	_free_game(game)
	return passed


func _test_hakugyokurou_preview_style() -> bool:
	var level_index = _find_level_index("2-31")
	if not _assert_true(level_index != -1, "expected 2-31 before checking preview style"):
		return false
	var game = _make_game()
	var level = Dictionary(Defs.LEVELS[level_index])
	var style = Dictionary(game.call("_selection_level_preview_style", level))
	var passed = _assert_true(String(style.get("terrain_key", "")) == "hakugyokurou_border", "2-31 preview should preserve its terrain key") \
		and _assert_true(Color(style.get("sky_color", Color.BLACK)).get_luminance() > 0.02, "2-31 preview should have a visible moonlit sky") \
		and _assert_true(game.has_method("_is_hakugyokurou_border_level"), "expected a dedicated terrain helper")
	_free_game(game)
	return passed
