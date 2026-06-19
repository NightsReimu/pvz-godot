extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_firing_sfx_methods_exist() or failed
	failed = not _test_shoot_sfx_paths_resolve() or failed
	failed = not _test_pea_family_maps_to_pea_sound() or failed
	failed = not _test_ice_family_maps_to_ice_sound() or failed
	failed = not _test_fire_family_maps_to_fire_sound() or failed
	failed = not _test_lob_family_maps_to_lob_sound() or failed
	failed = not _test_energy_family_maps_to_energy_sound() or failed
	failed = not _test_spore_family_maps_to_spore_sound() or failed
	failed = not _test_unknown_kind_falls_back_to_pea_sound() or failed
	failed = not _test_firing_sfx_throttles_repeat_calls() or failed
	failed = not _test_basic_shooter_plays_firing_sfx_on_spawn() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


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


func _ensure_sound_nodes(game: Control) -> void:
	# The SFX pool + labels are normally built when the game enters the tree.
	# Tests run headless without a tree, so build them explicitly.
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	game._build_sfx_players()


func _test_firing_sfx_methods_exist() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_play_firing_sfx"), "game should expose _play_firing_sfx") \
		and _assert_true(game.has_method("_firing_sfx_path"), "game should expose _firing_sfx_path") \
		and _assert_true(game.has_method("_update_firing_sfx_throttle"), "game should expose _update_firing_sfx_throttle")
	_free_game(game)
	return passed


func _test_shoot_sfx_paths_resolve() -> bool:
	var game = _make_game()
	_ensure_sound_nodes(game)
	var paths := [
		game.SFX_SHOOT_PEA_PATH,
		game.SFX_SHOOT_ICE_PATH,
		game.SFX_SHOOT_FIRE_PATH,
		game.SFX_SHOOT_LOB_PATH,
		game.SFX_SHOOT_ENERGY_PATH,
		game.SFX_SHOOT_SPORE_PATH,
	]
	var passed := true
	for path in paths:
		var stream = game._load_sfx_stream(path)
		passed = _assert_true(stream != null, "shoot sfx should load: %s" % path) and passed
	_free_game(game)
	return passed


func _test_pea_family_maps_to_pea_sound() -> bool:
	var game = _make_game()
	var passed := true
	for kind in ["peashooter", "repeater", "threepeater", "split_pea", "puff_shroom", "sea_shroom", "cactus", "starfruit", "amber_shooter"]:
		passed = _assert_true(game._firing_sfx_path(kind) == game.SFX_SHOOT_PEA_PATH, "%s should map to the pea shoot sound" % kind) and passed
	_free_game(game)
	return passed


func _test_ice_family_maps_to_ice_sound() -> bool:
	var game = _make_game()
	var passed := true
	for kind in ["snow_pea", "ice_queen", "frost_fan", "frost_cypress", "aurora_orchid"]:
		passed = _assert_true(game._firing_sfx_path(kind) == game.SFX_SHOOT_ICE_PATH, "%s should map to the ice shoot sound" % kind) and passed
	_free_game(game)
	return passed


func _test_fire_family_maps_to_fire_sound() -> bool:
	var game = _make_game()
	var passed := true
	for kind in ["pepper_mortar", "chimney_pepper", "magma_stream", "phoenix_tree", "dragon_fruit"]:
		passed = _assert_true(game._firing_sfx_path(kind) == game.SFX_SHOOT_FIRE_PATH, "%s should map to the fire shoot sound" % kind) and passed
	_free_game(game)
	return passed


func _test_lob_family_maps_to_lob_sound() -> bool:
	var game = _make_game()
	var passed := true
	for kind in ["cabbage_pult", "kernel_pult", "melon_pult", "skylight_melon"]:
		passed = _assert_true(game._firing_sfx_path(kind) == game.SFX_SHOOT_LOB_PATH, "%s should map to the lob shoot sound" % kind) and passed
	_free_game(game)
	return passed


func _test_energy_family_maps_to_energy_sound() -> bool:
	var game = _make_game()
	var passed := true
	for kind in ["tesla_tulip", "thunder_pine", "thunder_god", "leyline", "laser_lily", "pulse_bulb"]:
		passed = _assert_true(game._firing_sfx_path(kind) == game.SFX_SHOOT_ENERGY_PATH, "%s should map to the energy shoot sound" % kind) and passed
	_free_game(game)
	return passed


func _test_spore_family_maps_to_spore_sound() -> bool:
	var game = _make_game()
	var passed := true
	for kind in ["fume_shroom", "mist_orchid", "glowvine", "moonforge", "echo_fern", "scaredy_shroom"]:
		passed = _assert_true(game._firing_sfx_path(kind) == game.SFX_SHOOT_SPORE_PATH, "%s should map to the spore shoot sound" % kind) and passed
	_free_game(game)
	return passed


func _test_unknown_kind_falls_back_to_pea_sound() -> bool:
	var game = _make_game()
	var passed = _assert_true(game._firing_sfx_path("totally_made_up_plant") == game.SFX_SHOOT_PEA_PATH, "an unmapped plant kind should fall back to the pea shoot sound")
	_free_game(game)
	return passed


func _test_firing_sfx_throttles_repeat_calls() -> bool:
	var game = _make_game()
	_ensure_sound_nodes(game)
	game.firing_sfx_throttle.clear()
	game._play_firing_sfx("peashooter")
	var first_path = game.SFX_SHOOT_PEA_PATH
	# Within the throttle window the same path should be blocked.
	var blocked_within_window = float(game.firing_sfx_throttle.get(first_path, 0.0)) > 0.0
	# Advance the throttle past the window, then it should be allowed again.
	game.firing_sfx_throttle[first_path] = 0.0
	game._update_firing_sfx_throttle(0.01)
	var cleared = not game.firing_sfx_throttle.has(first_path)
	var passed = _assert_true(blocked_within_window, "firing sfx should set a throttle entry right after playing") \
		and _assert_true(cleared, "firing sfx throttle should clear once its window elapses")
	_free_game(game)
	return passed


func _test_basic_shooter_plays_firing_sfx_on_spawn() -> bool:
	var game = _make_game()
	_ensure_sound_nodes(game)
	game.firing_sfx_throttle.clear()
	# Spawn a pea through the shared spawn path with a known source kind.
	game._spawn_projectile(2, Vector2(200.0, 200.0), Color(0.36, 0.86, 0.3), 20.0, 0.0, 460.0, 8.0, "peashooter")
	var spawned = _assert_true(not game.projectiles.is_empty(), "spawn_projectile should still create the pea") \
		and _assert_true(float(game.firing_sfx_throttle.get(game.SFX_SHOOT_PEA_PATH, 0.0)) > 0.0, "spawning a pea with a source kind should arm the firing sfx throttle")
	_free_game(game)
	return spawned
