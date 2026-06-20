extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_home_terminal_routes_mainline_to_world_select() or failed
	failed = not _test_home_terminal_mode_entries_are_inside_viewport() or failed
	failed = not _test_home_terminal_touch_targets_match_action_rects() or failed
	failed = not _test_world_select_supports_screen_drag_and_snap() or failed
	failed = not _test_world_select_home_button_returns_to_terminal() or failed
	failed = not _test_world_select_excludes_home_duplicate_mode_buttons() or failed
	failed = not _test_world_select_buttons_keep_tap_priority_during_small_touch_motion() or failed
	failed = not _test_world_select_command_dock_targets_are_unified() or failed
	failed = not _test_map_supports_screen_drag_scroll() or failed
	failed = not _test_selection_screen_supports_vertical_touch_drag_scroll() or failed
	failed = not _test_selection_cards_keep_tap_priority_during_small_touch_motion() or failed
	failed = not _test_selection_drag_does_not_trigger_card_click() or failed
	failed = not _test_selection_touch_does_not_toggle_back_off_from_delayed_mouse_emulation() or failed
	failed = not _test_battle_touch_can_select_card_and_place_plant() or failed
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
	game.save_dirty = false
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


func _prepare_selection_game() -> Control:
	var game := _make_game()
	game.mobile_runtime_override = 1
	game.mode = game.MODE_SELECTION
	game.current_level = {
		"id": "selection-touch-test",
		"terrain": "day",
		"events": [],
		"mode": "",
		"available_plants": game.call("_player_plant_collection"),
	}
	game.selection_pool_cards = game.call("_player_plant_collection")
	game.selection_cards = []
	game.selection_pool_scroll = 0.0
	return game


func _prepare_battle_game() -> Control:
	var game := _make_game()
	game.mobile_runtime_override = 1
	game.size = Vector2(896.0, 414.0)
	var level := {
		"id": "touch-battle-test",
		"terrain": "day",
		"events": [],
		"mode": "",
		"start_sun": 999,
		"title": "touch battle",
		"description": "",
		"available_plants": ["peashooter"],
	}
	game.call("_begin_level", -1, ["peashooter"], level)
	return game


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


func _mouse_button(position: Vector2, pressed: bool, button_index: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.pressed = pressed
	event.button_index = button_index
	return event


func _test_home_terminal_routes_mainline_to_world_select() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_action_rects"), "home terminal should expose one shared action layout helper") \
		and _assert_true(game.has_method("_handle_home_click"), "home terminal should handle its own mode clicks")
	if passed:
		game.mode = game.MODE_HOME
		var action_rects: Dictionary = game.call("_home_action_rects")
		passed = _assert_true(action_rects.has("mainline"), "home terminal should include a mainline campaign entry") and passed
		if action_rects.has("mainline"):
			game.call("_handle_home_click", Rect2(action_rects["mainline"]).get_center())
			passed = _assert_true(game.mode == game.MODE_WORLD_SELECT, "clicking 主线关卡 should open the old world selection screen") and passed
	_free_game(game)
	return passed


func _test_home_terminal_mode_entries_are_inside_viewport() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_action_rects"), "home terminal should expose action rects for layout tests")
	if passed:
		var viewport_rect := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
		var action_rects: Dictionary = game.call("_home_action_rects")
		for action_variant in ["mainline", "daily", "entertainment", "events", "base", "enhance", "gacha", "almanac"]:
			var action := String(action_variant)
			passed = _assert_true(action_rects.has(action), "home terminal should include %s entry" % action) and passed
			if action_rects.has(action):
				var rect := Rect2(action_rects[action])
				passed = _assert_true(viewport_rect.encloses(rect), "%s entry should stay inside the home viewport" % action) and passed
				passed = _assert_true(rect.size.x >= 150.0 and rect.size.y >= 58.0, "%s entry should keep a comfortable tap target" % action) and passed
		var keys := action_rects.keys()
		for i in range(keys.size()):
			var first_rect := Rect2(action_rects[keys[i]])
			for j in range(i + 1, keys.size()):
				var second_rect := Rect2(action_rects[keys[j]])
				passed = _assert_true(not first_rect.intersects(second_rect), "home terminal entries should not overlap: %s and %s" % [String(keys[i]), String(keys[j])]) and passed
	_free_game(game)
	return passed


func _test_home_terminal_touch_targets_match_action_rects() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_touch_target"), "home terminal should expose touch targets from its shared action rects")
	if passed:
		var action_rects: Dictionary = game.call("_home_action_rects")
		for action_variant in ["mainline", "daily", "entertainment", "events", "base", "enhance", "gacha", "almanac"]:
			var action := String(action_variant)
			var rect := Rect2(action_rects[action])
			var target: Dictionary = game.call("_home_touch_target", rect.get_center())
			passed = _assert_true(String(target.get("id", "")) == "home_%s" % action, "%s center should resolve to its home touch target" % action) and passed
	_free_game(game)
	return passed


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


func _test_world_select_home_button_returns_to_terminal() -> bool:
	var game := _make_game()
	game.mode = game.MODE_WORLD_SELECT
	var action_rects: Dictionary = game.call("_world_select_action_rects")
	var passed = _assert_true(action_rects.has("home"), "world select should expose a home return button in the command dock")
	if passed:
		game.call("_handle_world_select_click", Rect2(action_rects["home"]).get_center())
		passed = _assert_true(game.mode == game.MODE_HOME, "world select home button should return to the top-level terminal") and passed
	_free_game(game)
	return passed


func _test_world_select_excludes_home_duplicate_mode_buttons() -> bool:
	var game := _make_game()
	var action_rects: Dictionary = game.call("_world_select_action_rects")
	var passed := true
	for duplicate_variant in ["almanac", "gacha", "enhance", "base", "daily", "endless"]:
		var duplicate := String(duplicate_variant)
		passed = _assert_true(not action_rects.has(duplicate), "mainline world select should not duplicate the %s home entry" % duplicate) and passed
	_free_game(game)
	return passed


func _test_world_select_buttons_keep_tap_priority_during_small_touch_motion() -> bool:
	var game := _make_game()
	game.mode = game.MODE_WORLD_SELECT
	var action_rects: Dictionary = game.call("_world_select_action_rects")
	var tap_pos = Rect2(action_rects["home"]).get_center()
	game._unhandled_input(_screen_touch(tap_pos, true))
	game._unhandled_input(_screen_drag(tap_pos + Vector2(26.0, 4.0), Vector2(26.0, 4.0)))
	game._unhandled_input(_screen_touch(tap_pos + Vector2(26.0, 4.0), false))
	var passed = _assert_true(game.mode == game.MODE_HOME, "small touch motion on the world-select home button should still trigger the button instead of starting carousel drag")
	_free_game(game)
	return passed


func _test_world_select_command_dock_targets_are_unified() -> bool:
	var game := _make_game()
	game.mode = game.MODE_WORLD_SELECT
	game.world_select_index = 1
	game.world_select_scroll = 1.0
	var passed := _assert_true(game.has_method("_world_select_action_rects"), "world select should expose one shared command-dock layout helper")
	if passed:
		var action_rects: Dictionary = game.call("_world_select_action_rects")
		for action_variant in ["home", "update", "update_info", "enter"]:
			var action := String(action_variant)
			passed = _assert_true(action_rects.has(action), "world select command dock should include %s" % action) and passed
			if not action_rects.has(action):
				continue
			var rect := Rect2(action_rects[action])
			passed = _assert_true(rect.size.x > 0.0 and rect.size.y > 0.0, "%s command rect should have a visible size" % action) and passed
			var target: Dictionary = game.call("_world_select_touch_target", rect.get_center())
			passed = _assert_true(String(target.get("id", "")) == "world_%s" % action, "%s command center should resolve to its button target instead of a world card" % action) and passed
		var dock_rect: Rect2 = game.call("_world_select_command_dock_rect")
		for action_variant in action_rects.keys():
			var action_rect := Rect2(action_rects[action_variant])
			passed = _assert_true(dock_rect.encloses(action_rect), "%s command rect should stay inside the command dock" % String(action_variant)) and passed
		var keys := action_rects.keys()
		for i in range(keys.size()):
			var first_key := String(keys[i])
			var first_rect := Rect2(action_rects[first_key])
			for j in range(i + 1, keys.size()):
				var second_key := String(keys[j])
				var second_rect := Rect2(action_rects[second_key])
				passed = _assert_true(not first_rect.intersects(second_rect), "%s and %s command rects should not overlap" % [first_key, second_key]) and passed
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


func _test_selection_screen_supports_vertical_touch_drag_scroll() -> bool:
	var game := _prepare_selection_game()
	var max_scroll = float(game.call("_selection_pool_max_scroll"))
	if not _assert_true(max_scroll > 0.0, "selection plant pool should overflow so touch scrolling can be tested"):
		_free_game(game)
		return false
	var view_rect: Rect2 = game.call("_selection_pool_view_rect")
	var start = view_rect.get_center()
	game._unhandled_input(_screen_touch(start, true))
	game._unhandled_input(_screen_drag(start + Vector2(8.0, -260.0), Vector2(8.0, -260.0)))
	var passed = _assert_true(float(game.selection_pool_scroll) > 120.0, "dragging inside the selection pool viewport should vertically scroll the plant list on mobile") \
		and _assert_true(float(game.selection_pool_scroll) <= max_scroll, "selection pool touch scrolling should stay clamped within the available content")
	game._unhandled_input(_screen_touch(start + Vector2(8.0, -260.0), false))
	_free_game(game)
	return passed


func _test_selection_cards_keep_tap_priority_during_small_touch_motion() -> bool:
	var game := _prepare_selection_game()
	var card_rect: Rect2 = game.call("_selection_pool_rect", 0)
	var tap_pos = card_rect.get_center()
	var expected_kind = String(game.selection_pool_cards[0])
	game._unhandled_input(_screen_touch(tap_pos, true))
	game._unhandled_input(_screen_drag(tap_pos + Vector2(20.0, 4.0), Vector2(20.0, 4.0)))
	game._unhandled_input(_screen_touch(tap_pos + Vector2(20.0, 4.0), false))
	var passed = _assert_true(game.selection_cards.size() == 1, "small touch motion on a selection card should still count as a tap") \
		and _assert_true(String(game.selection_cards[0]) == expected_kind, "selection card tap priority should preserve the touched plant kind")
	_free_game(game)
	return passed


func _test_selection_drag_does_not_trigger_card_click() -> bool:
	var game := _prepare_selection_game()
	var card_rect: Rect2 = game.call("_selection_pool_rect", 0)
	var start = card_rect.get_center()
	game._unhandled_input(_screen_touch(start, true))
	game._unhandled_input(_screen_drag(start + Vector2(4.0, -220.0), Vector2(4.0, -220.0)))
	game._unhandled_input(_screen_touch(start + Vector2(4.0, -220.0), false))
	var passed = _assert_true(game.selection_cards.is_empty(), "dragging a selection card should scroll instead of accidentally selecting it") \
		and _assert_true(float(game.selection_pool_scroll) > 100.0, "dragging from a card should still move the selection pool when the gesture is vertical")
	_free_game(game)
	return passed


func _test_selection_touch_does_not_toggle_back_off_from_delayed_mouse_emulation() -> bool:
	var game := _prepare_selection_game()
	var card_rect: Rect2 = game.call("_selection_pool_rect", 0)
	var tap_pos = card_rect.get_center()
	game._unhandled_input(_screen_touch(tap_pos, true))
	game._unhandled_input(_screen_touch(tap_pos, false))
	game.touch_mouse_suppress_until_ms = 0
	game._unhandled_input(_mouse_button(tap_pos, true))
	var passed = _assert_true(game.selection_cards.size() == 1, "a touch-selected plant should not be toggled back off by a delayed emulated mouse click") \
		and _assert_true(String(game.selection_cards[0]) == String(game.selection_pool_cards[0]), "touch selection should preserve the touched card even if Android emits a follow-up mouse press")
	_free_game(game)
	return passed


func _test_battle_touch_can_select_card_and_place_plant() -> bool:
	var game := _prepare_battle_game()
	var card_rect: Rect2 = game.call("_card_rect", 0)
	var card_pos = card_rect.get_center()
	game._unhandled_input(_screen_touch(card_pos, true))
	game._unhandled_input(_screen_touch(card_pos, false))
	var selected_ok = _assert_true(String(game.selected_tool) == "peashooter", "touching a seed card in battle should select it on mobile")
	var cell = Vector2i(2, 2)
	var cell_pos: Vector2 = game.call("_cell_center", cell.x, cell.y)
	game._unhandled_input(_screen_touch(cell_pos, true))
	game._unhandled_input(_screen_touch(cell_pos, false))
	var planted = game.grid[cell.x][cell.y] != null and String(game.grid[cell.x][cell.y].get("kind", "")) == "peashooter"
	var passed = selected_ok \
		and _assert_true(planted, "after a mobile touch selects a card, a second touch on the lawn should plant it") \
		and _assert_true(String(game.selected_tool) == "", "successful touch planting should clear the selected tool")
	_free_game(game)
	return passed
