extends SceneTree

# Verifies landscape mobile menus use UNIFORM scaling (no X/Y distortion) and are
# centered, after the FILL non-uniform scaling was removed. FILL stretched X and Y
# independently, distorting circles into ellipses and misaligning hit areas on
# non-16:9 phones.

const GameScript = preload("res://scripts/game.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failed := false
	failed = not _test_landscape_menus_scale_uniformly() or failed
	failed = not _test_menus_are_centered_on_widescreen() or failed
	failed = not _test_fill_scaling_is_disabled() or failed
	quit(1 if failed else 0)

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false

func _make_mobile_game(viewport: Vector2) -> Control:
	var game = GameScript.new()
	game.mobile_runtime_override = 1
	game.size = viewport
	return game

func _test_landscape_menus_scale_uniformly() -> bool:
	var passed := true
	# Common Android landscape aspect ratios that previously distorted under FILL.
	var resolutions = [Vector2(2400, 1080), Vector2(2340, 1080), Vector2(2160, 1080), Vector2(1920, 1080), Vector2(2560, 1080)]
	var menu_modes = ["world_select", "map", "almanac", "gacha", "enhance", "base"]
	for res in resolutions:
		var game = _make_mobile_game(res)
		for m in menu_modes:
			game.mode = m
			var s = game._ui_scale_vector(m)
			passed = _assert_true(absf(s.x - s.y) < 0.0001, "%s at %s should scale uniformly (x=%.4f y=%.4f)" % [m, str(res), s.x, s.y]) and passed
		game.free()
	return passed

func _test_menus_are_centered_on_widescreen() -> bool:
	var passed := true
	var game = _make_mobile_game(Vector2(2400, 1080))  # 20:9
	game.mode = "world_select"
	var off = game._ui_offset("world_select")
	# uniform scale = min(2400/1600, 1080/900) = min(1.5, 1.2) = 1.2
	# content width = 1600*1.2 = 1920; margin = (2400-1920)/2 = 240
	passed = _assert_true(off.x > 100.0, "widescreen menu should be horizontally centered with a left margin, got x=%.1f" % off.x) and passed
	passed = _assert_true(absf(off.y) < 1.0, "20:9 height fits exactly, y offset should be ~0, got %.1f" % off.y) and passed
	game.free()
	return passed

func _test_fill_scaling_is_disabled() -> bool:
	var passed := true
	var game = _make_mobile_game(Vector2(2400, 1080))
	game.mode = "world_select"
	passed = _assert_true(not game._uses_mobile_fill_ui_scaling("world_select"), "FILL scaling must stay disabled (it distorted non-16:9 menus)") and passed
	game.free()
	return passed
