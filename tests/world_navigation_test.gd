extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_world_select_supports_screen_drag_and_snap() or failed
	failed = not _test_map_supports_screen_drag_scroll() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.size = Vector2(1600.0, 900.0)
	game.current_level = {"id": "ui-test", "terrain": "day", "events": [], "title": "test", "description": ""}
	game.active_rows = [0, 1, 2, 3, 4]
	game.water_rows = []
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	game.completed_levels.resize(GameScript.Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = true
	game.unlocked_levels = GameScript.Defs.LEVELS.size()
	game.current_world_key = "day"
	game.world_select_index = 0
	game.world_select_scroll = 0.0
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


func _screen_touch(position: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _screen_drag(position: Vector2, relative: Vector2, index: int = 0) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	return event


func _test_world_select_supports_screen_drag_and_snap() -> bool:
	var game := _make_game()
	game.mode = game.MODE_WORLD_SELECT
	var start = Vector2(800.0, 430.0)
	game._unhandled_input(_screen_touch(start, true))
	game._unhandled_input(_screen_drag(start + Vector2(-340.0, 8.0), Vector2(-340.0, 8.0)))
	var passed = _assert_true(float(game.world_select_scroll) > 0.35, "screen dragging on world select should move the carousel on mobile") \
		and _assert_true(float(game.world_select_scroll) < 1.4, "world drag should stay within a nearby snap range for a single swipe")
	game._unhandled_input(_screen_touch(start + Vector2(-340.0, 8.0), false))
	for _i in range(10):
		game._process(0.08)
	passed = _assert_true(int(game.world_select_index) == 1, "releasing a left swipe should snap the world selection to the next world") and passed
	passed = _assert_true(absf(float(game.world_select_scroll) - 1.0) < 0.15, "world selection should settle near the snapped world after release") and passed
	_free_game(game)
	return passed


func _test_map_supports_screen_drag_scroll() -> bool:
	var game := _make_game()
	game.mode = game.MODE_MAP
	var bounds: Vector2 = game.call("_map_scroll_bounds_for_world", "day")
	if not _assert_true(bounds.y > 0.0, "day world should have horizontal overflow so touch scroll can be tested"):
		_free_game(game)
		return false
	game.call("_set_map_scroll", "day", 0.0, true)
	var start = game.MAP_VIEW_RECT.get_center()
	game._unhandled_input(_screen_touch(start, true))
	game._unhandled_input(_screen_drag(start + Vector2(-260.0, 4.0), Vector2(-260.0, 4.0)))
	var target_scroll = float(game.call("_map_scroll_value", "day", true))
	var passed = _assert_true(target_scroll > 80.0, "screen dragging on the map should push the target scroll to the right on mobile") \
		and _assert_true(target_scroll <= bounds.y, "map drag target should remain clamped within world bounds")
	game._unhandled_input(_screen_touch(start + Vector2(-260.0, 4.0), false))
	game._process(0.12)
	var live_scroll = float(game.call("_map_scroll_value", "day", false))
	passed = _assert_true(live_scroll > 0.0, "map scroll should start animating after a mobile drag release") and passed
	_free_game(game)
	return passed
