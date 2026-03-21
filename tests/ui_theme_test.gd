extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_progress_fill_rect_clamps_ratio() or failed
	failed = not _test_scroll_knob_rect_tracks_viewport() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _assert_float_eq(actual: float, expected: float, message: String) -> bool:
	if is_equal_approx(actual, expected):
		return true
	push_error("%s | actual=%s expected=%s" % [message, actual, expected])
	return false


func _script_has_method(method_name: String) -> bool:
	var theme_script = load("res://scripts/ui/game_theme.gd")
	for method_data in theme_script.get_script_method_list():
		if String(method_data.get("name", "")) == method_name:
			return true
	return false


func _test_progress_fill_rect_clamps_ratio() -> bool:
	if not _assert_true(_script_has_method("progress_fill_rect"), "expected progress_fill_rect helper to exist"):
		return false
	var theme_script = load("res://scripts/ui/game_theme.gd")
	var fill_rect: Rect2 = theme_script.call("progress_fill_rect", Rect2(10.0, 20.0, 200.0, 18.0), 1.4)
	return _assert_float_eq(fill_rect.position.x, 10.0, "progress fill should keep origin") \
		and _assert_float_eq(fill_rect.size.x, 200.0, "progress fill width should clamp to the source rect")


func _test_scroll_knob_rect_tracks_viewport() -> bool:
	if not _assert_true(_script_has_method("scroll_knob_rect"), "expected scroll_knob_rect helper to exist"):
		return false
	var theme_script = load("res://scripts/ui/game_theme.gd")
	var knob_rect: Rect2 = theme_script.call("scroll_knob_rect", Rect2(6.0, 12.0, 12.0, 300.0), 120.0, 360.0, 120.0)
	return _assert_float_eq(knob_rect.position.y, 112.0, "scroll knob should move proportionally through the track") \
		and _assert_float_eq(knob_rect.size.y, 100.0, "scroll knob height should reflect visible fraction")
