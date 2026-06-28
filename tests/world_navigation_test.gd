extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_home_terminal_routes_mainline_to_world_select() or failed
	failed = not _test_home_terminal_mode_entries_are_inside_viewport() or failed
	failed = not _test_home_image2_layout_exposes_text_safe_areas() or failed
	failed = not _test_home_image2_text_stays_on_visible_boards() or failed
	failed = not _test_home_image2_decorative_layout_is_reserved() or failed
	failed = not _test_home_image2_asset_manifest_is_declared() or failed
	failed = not _test_home_image2_asset_helpers_exist() or failed
	failed = not _test_home_image2_asset_shadow_helper_exists() or failed
	failed = not _test_home_image2_hover_uses_asset_shape() or failed
	failed = not _test_home_image2_title_asset_is_declared_and_positioned() or failed
	failed = not _test_home_resource_text_stays_on_visible_bar() or failed
	failed = not _test_home_resource_status_text_fits_panel() or failed
	failed = not _test_home_terminal_touch_targets_match_action_rects() or failed
	failed = not _test_daily_terminal_stage_layout_stays_inside_viewport() or failed
	failed = not _test_world_select_supports_screen_drag_and_snap() or failed
	failed = not _test_world_select_home_button_returns_to_terminal() or failed
	failed = not _test_world_select_excludes_home_duplicate_mode_buttons() or failed
	failed = not _test_world_select_image2_asset_manifest_is_declared() or failed
	failed = not _test_world_select_image2_layout_keeps_text_on_boards() or failed
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


func _test_home_image2_layout_exposes_text_safe_areas() -> bool:
	var game := _make_game()
	game.call("_build_font")
	var passed := _assert_true(game.has_method("_home_action_rects"), "home terminal should expose action rects for image2 layout tests") \
		and _assert_true(game.has_method("_home_entry_text_rect"), "home image2 entries should expose text-safe rects")
	if passed:
		var action_rects: Dictionary = game.call("_home_action_rects")
		var mainline_rect := Rect2(action_rects["mainline"])
		passed = _assert_true(mainline_rect.size.x >= 500.0 and mainline_rect.size.y >= 320.0, "mainline Image2 board should be large enough for title, copy, chips, and progress") and passed
		var ui_font: Font = game.ui_font
		var titles := {
			"mainline": "主线关卡",
			"daily": "每日关卡",
			"entertainment": "娱乐关卡",
			"events": "活动关卡",
			"base": "基建",
			"enhance": "植物强化",
			"gacha": "抽卡",
			"almanac": "图鉴",
		}
		for action_variant in titles.keys():
			var action := String(action_variant)
			var text_rect: Rect2 = game.call("_home_entry_text_rect", action)
			var title_width := ui_font.get_string_size(String(titles[action]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 34 if action == "mainline" else 26).x
			passed = _assert_true(Rect2(action_rects[action]).encloses(text_rect), "%s text-safe rect should stay inside its card" % action) and passed
			passed = _assert_true(text_rect.size.x >= title_width, "%s text-safe rect should fit its title" % action) and passed
			passed = _assert_true(text_rect.size.y >= (120.0 if action == "mainline" else 54.0), "%s text-safe rect should leave room for copy" % action) and passed
	_free_game(game)
	return passed


func _test_home_image2_text_stays_on_visible_boards() -> bool:
	var game := _make_game()
	game.call("_build_font")
	var passed := _assert_true(game.has_method("_home_entry_board_safe_rect"), "home Image2 entries should expose visible board safe rects") \
		and _assert_true(game.has_method("_home_entry_text_rect"), "home Image2 entries should expose text-safe rects")
	if passed:
		var ui_font: Font = game.ui_font
		var titles := {
			"mainline": "主线关卡",
			"daily": "每日关卡",
			"entertainment": "娱乐关卡",
			"events": "活动关卡",
			"base": "基建",
			"enhance": "植物强化",
			"gacha": "抽卡",
			"almanac": "图鉴",
		}
		var subtitles := {
			"mainline": "进入世界选择，推进地图与首领关卡。当前世界：白天冒险",
			"daily": "今日修饰挑战，奖励金币和强化材料。",
			"entertainment": "无尽模式入口，尸潮会持续变强。",
			"events": "限时活动入口已预留，后续版本开放。",
			"base": "生产金币、材料、碎片，并管理植物心情。",
			"enhance": "按植物类型提升属性，消耗材料与金币。",
			"gacha": "获取稀有植物、碎片和强化材料。",
			"almanac": "查看植物、僵尸和 Boss 资料。",
		}
		for action_variant in titles.keys():
			var action := String(action_variant)
			var board_rect: Rect2 = game.call("_home_entry_board_safe_rect", action)
			var text_rect: Rect2 = game.call("_home_entry_text_rect", action)
			var title_size := 34 if action == "mainline" else 26
			var subtitle_size := 18 if action == "mainline" else 16
			var title_width := ui_font.get_string_size(String(titles[action]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_size).x
			var subtitle_lines: Array = game.call("_wrap_text_lines", String(subtitles[action]), text_rect.size.x, subtitle_size)
			var line_count: int = mini(subtitle_lines.size(), 3 if action == "mainline" else 2)
			var subtitle_height := float(subtitle_size) + maxf(0.0, float(line_count - 1) * (float(subtitle_size) + 5.0))
			var content_rect := Rect2(text_rect.position, Vector2(maxf(title_width, text_rect.size.x), float(title_size) + 14.0 + subtitle_height))
			passed = _assert_true(board_rect.encloses(text_rect), "%s text rect should sit on the visible board, not the transparent PNG margin" % action) and passed
			passed = _assert_true(board_rect.encloses(content_rect), "%s rendered title/subtitle should fit fully inside the board background" % action) and passed
	_free_game(game)
	return passed


func _test_home_image2_decorative_layout_is_reserved() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_logo_rect"), "home Image2 layout should expose a logo plate rect") \
		and _assert_true(game.has_method("_home_mainline_chip_rects"), "home Image2 layout should expose mainline chip rects") \
		and _assert_true(game.has_method("_home_mainline_progress_rect"), "home Image2 layout should expose a mainline progress rect")
	if passed:
		var viewport_rect := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
		var action_rects: Dictionary = game.call("_home_action_rects")
		var mainline_rect := Rect2(action_rects["mainline"])
		var logo_rect: Rect2 = game.call("_home_logo_rect")
		var resource_rect: Rect2 = game.call("_home_resource_rect")
		var chip_rects: Array = game.call("_home_mainline_chip_rects")
		var progress_rect: Rect2 = game.call("_home_mainline_progress_rect")
		passed = _assert_true(viewport_rect.encloses(logo_rect), "home logo plate should stay inside viewport") and passed
		passed = _assert_true(not logo_rect.intersects(resource_rect), "home logo plate should not overlap the resource bar") and passed
		passed = _assert_true(chip_rects.size() == 5, "home mainline preview should reserve five world chips") and passed
		for chip_variant in chip_rects:
			var chip_rect := Rect2(chip_variant)
			passed = _assert_true(mainline_rect.encloses(chip_rect), "home mainline world chip should stay inside the main board") and passed
			passed = _assert_true(chip_rect.size.x >= 58.0 and chip_rect.size.y >= 58.0, "home mainline world chip should keep a comfortable tap size") and passed
			passed = _assert_true(not chip_rect.intersects(progress_rect), "home mainline world chips should not overlap the progress bar") and passed
		passed = _assert_true(mainline_rect.encloses(progress_rect), "home mainline progress bar should stay inside the main board") and passed
		passed = _assert_true(progress_rect.size.x >= 320.0 and progress_rect.size.y >= 14.0, "home mainline progress bar should be readable") and passed
	_free_game(game)
	return passed


func _test_home_image2_asset_manifest_is_declared() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_ui_asset_paths"), "home screen should expose Image2 UI asset paths")
	if passed:
		var paths: Dictionary = game.call("_home_ui_asset_paths")
		for key_variant in ["logo", "title_text", "main_board", "card_daily", "card_entertainment", "card_base", "card_enhance", "card_gacha", "card_almanac", "card_locked", "resource_bar", "lock_badge"]:
			var key := String(key_variant)
			passed = _assert_true(paths.has(key), "home Image2 manifest should include %s" % key) and passed
			if paths.has(key):
				var path := String(paths[key])
				passed = _assert_true(path.begins_with("res://art/home_ui/"), "%s should live under art/home_ui" % key) and passed
				passed = _assert_true(path.ends_with(".png") or path.ends_with(".webp"), "%s should be a PNG or WebP asset" % key) and passed
	_free_game(game)
	return passed


func _test_home_image2_asset_helpers_exist() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_ui_texture"), "home screen should load Image2 UI textures through a helper") \
		and _assert_true(game.has_method("_draw_home_asset_panel"), "home screen should draw Image2 panels through a helper")
	_free_game(game)
	return passed


func _test_home_image2_asset_shadow_helper_exists() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_draw_home_asset_shadow"), "home Image2 panels should use alpha-shaped texture shadows instead of rectangular soft shadows")
	_free_game(game)
	return passed


func _test_home_image2_hover_uses_asset_shape() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_image_panel_draw_style"), "home Image2 panels should expose draw style for regression tests")
	if passed:
		for key_variant in ["main_board", "card_daily", "card_gacha", "card_base", "resource_bar"]:
			var key := String(key_variant)
			var style: Dictionary = game.call("_home_image_panel_draw_style", key)
			passed = _assert_true(not bool(style.get("draw_rect_backing", true)), "%s should not draw a rectangular backing behind Image2 art" % key) and passed
			passed = _assert_true(not bool(style.get("draw_hover_frame", true)), "%s hover should tint/shift the image instead of drawing an extra frame" % key) and passed
	_free_game(game)
	return passed


func _test_home_image2_title_asset_is_declared_and_positioned() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_home_ui_asset_paths"), "home should expose Image2 UI asset paths") \
		and _assert_true(game.has_method("_home_title_text_rect"), "home title should have a dedicated Image2 title rect")
	if passed:
		var paths: Dictionary = game.call("_home_ui_asset_paths")
		var title_path := String(paths.get("title_text", ""))
		var logo_rect: Rect2 = game.call("_home_logo_rect")
		var title_rect: Rect2 = game.call("_home_title_text_rect")
		passed = _assert_true(title_path == "res://art/home_ui/home_title_text.png", "home title text should use the generated Image2 title asset") and passed
		passed = _assert_true(FileAccess.file_exists(title_path), "home Image2 title asset should exist") and passed
		passed = _assert_true(FileAccess.file_exists("%s.import" % title_path), "home Image2 title asset should have a Godot import sidecar") and passed
		passed = _assert_true(logo_rect.encloses(title_rect), "home Image2 title should sit inside the logo plate") and passed
		passed = _assert_true(title_rect.size.x >= 330.0 and title_rect.size.y >= 64.0, "home Image2 title should be large enough to replace the drawn font") and passed
	_free_game(game)
	return passed


func _test_home_resource_text_stays_on_visible_bar() -> bool:
	var game := _make_game()
	game.call("_build_font")
	var passed := _assert_true(game.has_method("_home_resource_board_safe_rect"), "home resource bar should expose its visible board rect") \
		and _assert_true(game.has_method("_home_resource_coin_text_rect"), "home resource bar should expose a coin text rect") \
		and _assert_true(game.has_method("_home_resource_drone_text_rect"), "home resource bar should expose a drone text rect") \
		and _assert_true(game.has_method("_home_resource_status_rect"), "home resource bar should expose a status text rect")
	if passed:
		var ui_font: Font = game.ui_font
		var safe_rect: Rect2 = game.call("_home_resource_board_safe_rect")
		var coin_rect: Rect2 = game.call("_home_resource_coin_text_rect")
		var drone_rect: Rect2 = game.call("_home_resource_drone_text_rect")
		var status_rect: Rect2 = game.call("_home_resource_status_rect")
		var coin_text := "金币 372288"
		var drone_text := "基建无人机 1120"
		game.update_state = "latest"
		var status_text := String(game.call("_home_update_status_line"))
		passed = _assert_true(safe_rect.encloses(coin_rect), "home coin text should sit on the visible resource board") and passed
		passed = _assert_true(safe_rect.encloses(drone_rect), "home drone text should sit on the visible resource board") and passed
		passed = _assert_true(safe_rect.encloses(status_rect), "home update status should sit on the visible resource board") and passed
		passed = _assert_true(coin_rect.size.x >= ui_font.get_string_size(coin_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20).x, "home coin text rect should fit the current coin string") and passed
		passed = _assert_true(drone_rect.size.x >= ui_font.get_string_size(drone_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 19).x, "home drone text rect should fit the current drone string") and passed
		passed = _assert_true(status_rect.size.x >= ui_font.get_string_size(status_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x, "home update status rect should fit its version text") and passed
		passed = _assert_true(not coin_rect.intersects(drone_rect), "home coin and drone text rects should not overlap") and passed
		passed = _assert_true(not drone_rect.intersects(status_rect), "home drone and update status text rects should not overlap") and passed
	_free_game(game)
	return passed


func _test_home_resource_status_text_fits_panel() -> bool:
	var game := _make_game()
	game.call("_build_font")
	var resource_rect := Rect2(GameScript.BASE_VIEWPORT_SIZE.x - 484.0, 24.0, 460.0, 56.0)
	var status_rect := Rect2(resource_rect.position + Vector2(350.0, 18.0), Vector2(resource_rect.size.x - 364.0, 26.0))
	if game.has_method("_home_resource_rect"):
		resource_rect = Rect2(game.call("_home_resource_rect"))
	if game.has_method("_home_resource_status_rect"):
		status_rect = Rect2(game.call("_home_resource_status_rect"))
	var ui_font: Font = game.ui_font
	var status_cases := [
		{"state": "idle", "release_info": {}},
		{"state": "checking", "release_info": {}},
		{"state": "latest", "release_info": {}},
		{"state": "available", "release_info": {"latest_version": "1.0.66"}},
	]
	var passed := _assert_true(resource_rect.encloses(status_rect), "home update status rect should stay inside the resource panel")
	for case_variant in status_cases:
		var status_case := Dictionary(case_variant)
		game.update_state = String(status_case.get("state", "idle"))
		game.update_release_info = Dictionary(status_case.get("release_info", {}))
		game.update_status_text = ""
		var status_text := String(game.call("_home_update_status_line")) if game.has_method("_home_update_status_line") else String(game.call("_update_status_line"))
		var status_width := ui_font.get_string_size(status_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
		passed = _assert_true(status_rect.size.x >= status_width, "home update status text should fit inside its own panel area; width %.1f needs %.1f for '%s'" % [status_rect.size.x, status_width, status_text]) and passed
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


func _test_daily_terminal_stage_layout_stays_inside_viewport() -> bool:
	var game := _make_game()
	var viewport_rect := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
	var passed := _assert_true(game.has_method("_daily_series_defs"), "daily terminal should expose series definitions for layout validation") \
		and _assert_true(game.has_method("_daily_series_card_rect"), "daily terminal should expose series card rects") \
		and _assert_true(game.has_method("_daily_stage_rect"), "daily terminal should expose stage card rects")
	if passed:
		var series_defs: Array = game.call("_daily_series_defs")
		for i in range(series_defs.size()):
			var series_rect: Rect2 = game.call("_daily_series_card_rect", i)
			passed = _assert_true(viewport_rect.encloses(series_rect), "daily series card %d should stay inside the viewport" % i) and passed
			for j in range(i + 1, series_defs.size()):
				var next_series_rect: Rect2 = game.call("_daily_series_card_rect", j)
				passed = _assert_true(not series_rect.intersects(next_series_rect), "daily series cards should not overlap") and passed
		var first_series := Dictionary(series_defs[0])
		var stages: Array = game.call("_daily_stage_defs_for_series", first_series)
		for i in range(stages.size()):
			var stage_rect: Rect2 = game.call("_daily_stage_rect", i)
			passed = _assert_true(viewport_rect.encloses(stage_rect), "daily stage card %d should stay inside the viewport" % i) and passed
			for j in range(i + 1, stages.size()):
				var next_stage_rect: Rect2 = game.call("_daily_stage_rect", j)
				passed = _assert_true(not stage_rect.intersects(next_stage_rect), "daily stage cards should not overlap") and passed
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


func _test_world_select_image2_asset_manifest_is_declared() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_world_ui_asset_paths"), "world select should expose Image2 UI asset paths")
	if passed:
		var paths: Dictionary = game.call("_world_ui_asset_paths")
		for key_variant in ["background", "title_panel", "dock_panel", "button_primary", "button_blue", "arrow_left", "plant_slot"]:
			var key := String(key_variant)
			passed = _assert_true(paths.has(key), "world Image2 manifest should include %s" % key) and passed
		for world_variant in GameScript.WorldDataLib.all():
			var world := Dictionary(world_variant)
			var world_key := String(world.get("key", ""))
			var card_key := "card_%s" % world_key
			passed = _assert_true(paths.has(card_key), "world Image2 manifest should include %s" % card_key) and passed
		for key_variant in paths.keys():
			var path := String(paths[key_variant])
			passed = _assert_true(path.begins_with("res://art/world_ui/"), "%s should live under art/world_ui" % String(key_variant)) and passed
			passed = _assert_true(path.ends_with(".png"), "%s should be a PNG asset" % String(key_variant)) and passed
			passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
			passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
	_free_game(game)
	return passed


func _test_world_select_image2_layout_keeps_text_on_boards() -> bool:
	var game := _make_game()
	var viewport := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
	var passed := _assert_true(game.has_method("_world_select_title_panel_rect"), "world select should expose a title panel rect") \
		and _assert_true(game.has_method("_world_select_card_text_rect"), "world select should expose card text safe rects") \
		and _assert_true(game.has_method("_world_select_card_preview_grid_rect"), "world select should expose card preview grid rects")
	if passed:
		var title_rect := Rect2(game.call("_world_select_title_panel_rect"))
		var dock_rect: Rect2 = game.call("_world_select_command_dock_rect")
		passed = _assert_true(viewport.encloses(title_rect), "world title panel should stay inside the viewport") and passed
		passed = _assert_true(viewport.encloses(dock_rect), "world command dock should stay inside the viewport") and passed
		for i in range(GameScript.WorldDataLib.all().size()):
			game.world_select_scroll = float(i)
			var card_rect := Rect2(game.call("_world_card_rect", i))
			var text_rect := Rect2(game.call("_world_select_card_text_rect", i))
			var grid_rect := Rect2(game.call("_world_select_card_preview_grid_rect", i))
			passed = _assert_true(card_rect.encloses(text_rect), "world card %d should contain its text safe area" % i) and passed
			passed = _assert_true(card_rect.encloses(grid_rect), "world card %d should contain its plant preview grid" % i) and passed
			passed = _assert_true(not text_rect.intersects(grid_rect), "world card %d text and preview grid should not overlap" % i) and passed
			passed = _assert_true(text_rect.size.x >= 300.0 and text_rect.size.y >= 150.0, "world card %d text safe area should remain readable" % i) and passed
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
