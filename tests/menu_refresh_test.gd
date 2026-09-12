extends "res://tests/world_navigation_test.gd"

func _run() -> void:
	var passed := true
	var game := _make_game()
	game._build_font()
	var viewport := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
	var atlas_path: String = game._world_ui_asset_paths().scene_atlas
	var atlas: Texture2D = load(atlas_path)
	passed = _assert_true(atlas != null, "The shipped world scene atlas must load") and passed
	if atlas != null:
		var used := []
		for index in range(8):
			var region: Rect2 = GameScript.GardenMenus.scene_region(atlas.get_size(), index, 474.0 / 498.0)
			passed = _assert_true(Rect2(Vector2.ZERO, atlas.get_size()).encloses(region), "Every scene region must stay inside the shipped atlas") and passed
			for previous in used:
				passed = _assert_true(not region.intersects(previous), "World art must not sample neighbouring scenes") and passed
			used.append(region)
	var controls: Dictionary = game._world_select_action_rects()
	var rows := []
	for i in range(GameScript.WorldDataLib.all().size()):
		var row: Rect2 = game._world_card_rect(i)
		passed = _assert_true(viewport.encloses(row), "All seven world choices must be visible simultaneously") and passed
		for other in rows:
			passed = _assert_true(not row.intersects(other), "World choices must never overlap") and passed
		for control in controls.values():
			passed = _assert_true(not row.intersects(control), "World choices must leave header/footer controls clear") and passed
		rows.append(row)
		game.mode = game.MODE_WORLD_SELECT
		game._handle_world_select_click(row.get_center())
		passed = _assert_true(game.mode == game.MODE_WORLD_SELECT and game.world_select_index == i, "Choosing a world must preview it before entering") and passed
		passed = _assert_true(game._world_select_touch_target(row.get_center()).id == "world_card_%d" % i, "Visual navigation rows must match touch targets") and passed
		game._handle_world_select_click(Rect2(controls.enter).get_center())
		game._update_page_transition(0.4)
		passed = _assert_true(game.mode == game.MODE_MAP and game.current_world_key == GameScript.WorldDataLib.all()[i].key, "Enter must open the previewed world's map") and passed
	game.completed_levels.fill(false)
	game.unlocked_levels = 1
	game.mode = game.MODE_WORLD_SELECT
	game._handle_world_select_click(Rect2(rows.back()).get_center())
	passed = _assert_true(game.world_select_index == 6, "Locked worlds remain previewable") and passed
	game._handle_world_select_click(Rect2(controls.enter).get_center())
	passed = _assert_true(game.mode == game.MODE_WORLD_SELECT, "Previewing a locked world must not bypass its progression gate") and passed
	var progress: Vector2i = GameScript.GardenMenus.world_progress(game, "volcano")
	passed = _assert_true(progress.x == 0 and progress.y == game._visible_level_indices("volcano").size(), "Progress must reflect real saves and current level definitions") and passed
	passed = _assert_true(viewport.encloses(GameScript.ALMANAC_BOOK_RECT) and GameScript.ALMANAC_BOOK_RECT.encloses(GameScript.ALMANAC_DETAIL_RECT), "Expanded almanac must fit the viewport") and passed
	var summary_line := Rect2(game._base_detail_rect().position + Vector2(30, 390), Vector2(400, 24))
	passed = _assert_true(not summary_line.intersects(game._base_upgrade_rect()), "Base income summary must stay above the upgrade action") and passed
	_free_game(game)
	print("Garden navigation, preview/enter, locked worlds, progress and content bounds: %s" % ("PASS" if passed else "FAIL"))
	quit(0 if passed else 1)
