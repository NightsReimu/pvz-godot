extends SceneTree

const WindowModeScript = preload("res://scripts/system/window_mode.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_web_target_window_mode_stays_windowed() or failed
	failed = not _test_desktop_target_window_mode_stays_fullscreen() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_web_target_window_mode_stays_windowed() -> bool:
	var mode_helper := WindowModeScript.new()
	if not _assert_true(mode_helper.has_method("target_window_mode"), "expected WindowMode to expose a target_window_mode helper for platform-specific startup mode decisions"):
		return false
	return _assert_true(
		mode_helper.call("target_window_mode", true) == DisplayServer.WINDOW_MODE_WINDOWED,
		"web startup should avoid forcing browser fullscreen and stay windowed while the canvas fills the viewport"
	)


func _test_desktop_target_window_mode_stays_fullscreen() -> bool:
	var mode_helper := WindowModeScript.new()
	if not _assert_true(mode_helper.has_method("target_window_mode"), "expected WindowMode to expose a target_window_mode helper for platform-specific startup mode decisions"):
		return false
	return _assert_true(
		mode_helper.call("target_window_mode", false) == DisplayServer.WINDOW_MODE_FULLSCREEN,
		"desktop builds should continue to launch in fullscreen mode"
	)
