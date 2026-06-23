extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_shroom_ranges_gain_one_tile() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_shroom_ranges_gain_one_tile() -> bool:
	var puff_range = float(Defs.PLANTS["puff_shroom"].get("range", 0.0))
	var fume_range = float(Defs.PLANTS["fume_shroom"].get("range", 0.0))
	return _assert_true(is_equal_approx(puff_range, 450.0), "puff_shroom range should be increased by one tile to 450") \
		and _assert_true(is_equal_approx(fume_range, 460.0), "fume_shroom range should be increased by one tile to 460")
