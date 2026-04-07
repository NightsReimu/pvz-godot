extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_game_script_loads() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_game_script_loads() -> bool:
	var script = load("res://scripts/game.gd")
	var passed = _assert_true(script != null, "expected scripts/game.gd to load without parse errors during boot")
	if not passed:
		return false
	var game = script.new()
	passed = _assert_true(game.has_method("_draw_shovel_icon"), "expected game boot script to expose the shovel icon draw helper used by the seed bank") and passed
	passed = _assert_true(game.has_method("_draw_heather_shooter"), "expected game boot script to expose city plant draw helpers") and passed
	passed = _assert_true(game.has_method("_draw_wenjie_zombie"), "expected game boot script to expose city zombie draw helpers") and passed
	game.free()
	return passed
