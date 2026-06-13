extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const ZombieRuntimeScript = preload("res://scripts/runtime/zombie_runtime.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_module_loads_and_classifies() or failed
	failed = not _test_shims_delegate_to_runtime() or failed
	failed = not _test_spawn_row_selection() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_module_loads_and_classifies() -> bool:
	var passed := true
	passed = _assert_true(ZombieRuntimeScript != null, "zombie_runtime.gd should load") and passed
	var game := GameScript.new()
	var runtime = ZombieRuntimeScript.new(game)
	passed = _assert_true(runtime != null, "ZombieRuntime should instantiate with a game owner") and passed
	passed = _assert_true(runtime.is_water_zombie_kind("snorkel"), "snorkel is a water zombie") and passed
	passed = _assert_true(runtime.is_water_zombie_kind("dragon_boat"), "dragon_boat is a water zombie") and passed
	passed = _assert_true(not runtime.is_water_zombie_kind("normal"), "normal is not a water zombie") and passed
	passed = _assert_true(runtime.is_dual_terrain_zombie_kind("qinghua"), "qinghua is dual-terrain") and passed
	passed = _assert_true(runtime.is_mechanical_zombie_kind("zomboni"), "zomboni is mechanical") and passed
	passed = _assert_true(runtime.is_mechanical_zombie_kind("turret_zombie"), "turret_zombie is mechanical") and passed
	passed = _assert_true(not runtime.is_mechanical_zombie_kind("normal"), "normal is not mechanical") and passed
	game.free()
	return passed


func _test_shims_delegate_to_runtime() -> bool:
	# The game.gd helpers must remain as thin shims so existing callers and the
	# has_method-locked test surface keep working.
	var game := GameScript.new()
	var passed := true
	for name in ["_is_water_zombie_kind", "_is_dual_terrain_zombie_kind", "_is_mechanical_zombie_kind", "_is_row_valid_for_spawn_kind", "_eligible_spawn_rows_for_kind", "_choose_spawn_row_for_kind", "_choose_spawn_row", "_normal_zombie_spawn_x", "_random_normal_zombie_spawn_x"]:
		passed = _assert_true(game.has_method(name), "game should keep shim %s" % name) and passed
	passed = _assert_true(game._is_water_zombie_kind("snorkel") == true, "shim _is_water_zombie_kind should delegate") and passed
	passed = _assert_true(game._is_mechanical_zombie_kind("zomboni") == true, "shim _is_mechanical_zombie_kind should delegate") and passed
	game.free()
	return passed


func _test_spawn_row_selection() -> bool:
	var game := GameScript.new()
	# Minimal state the spawn-row logic reads.
	game.active_rows = [0, 1, 2, 3, 4]
	game.zombies = []
	game.rng = RandomNumberGenerator.new()
	game.current_level = {"terrain": "day"}
	# On a non-pool level every active row is eligible.
	var passed := true
	var rows = game._eligible_spawn_rows_for_kind("normal")
	rows.sort()
	passed = _assert_true(rows == [0, 1, 2, 3, 4], "non-pool normal zombie should be eligible for all active rows, got %s" % str(rows)) and passed
	# Choosing a row should return one of the active rows.
	var chosen = game._choose_spawn_row_for_kind("normal")
	passed = _assert_true(chosen >= 0 and chosen <= 4, "chosen spawn row should be an active row, got %d" % chosen) and passed
	# Spawn x should sit past the board's right edge.
	game.BOARD_ORIGIN = Vector2(250.0, 160.0)
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	var spawn_x = game._normal_zombie_spawn_x()
	passed = _assert_true(spawn_x > game.BOARD_ORIGIN.x + game.board_size.x, "normal spawn x should be past the board right edge") and passed
	game.free()
	return passed
