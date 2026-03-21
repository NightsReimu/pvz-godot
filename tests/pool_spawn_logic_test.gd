extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_spawn_row_partition() or failed
	failed = not _test_lifebuoy_variants_exist() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _assert_array_eq(actual: Array, expected: Array, message: String) -> bool:
	if actual == expected:
		return true
	push_error("%s | actual=%s expected=%s" % [message, actual, expected])
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "3-test", "terrain": "pool"}
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.water_rows = [2, 3]
	game.zombies = []
	return game


func _test_spawn_row_partition() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_eligible_spawn_rows_for_kind"), "expected _eligible_spawn_rows_for_kind helper to exist"):
		game.free()
		return false
	var land_rows: Array = game._eligible_spawn_rows_for_kind("normal")
	var water_rows: Array = game._eligible_spawn_rows_for_kind("lifebuoy_normal")
	var passed = _assert_array_eq(land_rows, [0, 1, 4, 5], "land zombies should stay on land rows") \
		and _assert_array_eq(water_rows, [2, 3], "lifebuoy zombies should stay on water rows")
	game.free()
	return passed


func _test_lifebuoy_variants_exist() -> bool:
	return _assert_true(Defs.ZOMBIES.has("lifebuoy_normal"), "missing lifebuoy_normal definition") \
		and _assert_true(Defs.ZOMBIES.has("lifebuoy_cone"), "missing lifebuoy_cone definition") \
		and _assert_true(Defs.ZOMBIES.has("lifebuoy_bucket"), "missing lifebuoy_bucket definition")
