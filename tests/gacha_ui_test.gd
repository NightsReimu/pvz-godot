extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_gacha_image2_asset_manifest_is_declared() or failed
	failed = not _test_gacha_layout_rects_stay_inside_viewport() or failed
	failed = not _test_gacha_image_panels_do_not_draw_rect_backings() or failed
	failed = not _test_gacha_click_targets_match_draw_button_rects() or failed
	failed = not _test_gacha_collection_grid_shows_complete_cards() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.size = GameScript.BASE_VIEWPORT_SIZE
	game.current_level = {"id": "gacha-ui-test", "terrain": "day", "events": []}
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	game.mode = game.MODE_GACHA
	game.coins_total = 380366
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


func _test_gacha_image2_asset_manifest_is_declared() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_gacha_ui_asset_paths"), "gacha screen should expose Image2 UI asset paths")
	if passed:
		var paths: Dictionary = game.call("_gacha_ui_asset_paths")
		for key_variant in ["background", "heroine", "title_frame", "back_button", "coin_chip", "button_common", "button_premium", "button_multi", "collection_panel", "card_back", "result_card"]:
			var key := String(key_variant)
			passed = _assert_true(paths.has(key), "gacha Image2 manifest should include %s" % key) and passed
			if paths.has(key):
				var path := String(paths[key])
				passed = _assert_true(path.begins_with("res://art/gacha_ui/"), "%s should live under art/gacha_ui" % key) and passed
				passed = _assert_true(path.ends_with(".png"), "%s should be a PNG asset" % key) and passed
				passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
				passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s should have a Godot import sidecar" % path) and passed
	_free_game(game)
	return passed


func _test_gacha_layout_rects_stay_inside_viewport() -> bool:
	var game := _make_game()
	var viewport := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
	var passed := true
	for method in ["_gacha_back_rect", "_gacha_coin_rect", "_gacha_title_rect", "_gacha_character_rect", "_gacha_collection_panel_rect", "_gacha_collection_view_rect", "_gacha_results_panel_rect"]:
		passed = _assert_true(game.has_method(method), "gacha UI should expose %s for layout tests" % method) and passed
	if passed:
		for method in ["_gacha_back_rect", "_gacha_coin_rect", "_gacha_title_rect", "_gacha_character_rect", "_gacha_collection_panel_rect", "_gacha_collection_view_rect", "_gacha_results_panel_rect"]:
			var rect := Rect2(game.call(method))
			passed = _assert_true(viewport.encloses(rect), "%s should stay inside the gacha viewport" % method) and passed
		var title_rect := Rect2(game.call("_gacha_title_rect"))
		var coin_rect := Rect2(game.call("_gacha_coin_rect"))
		var back_rect := Rect2(game.call("_gacha_back_rect"))
		passed = _assert_true(not title_rect.intersects(coin_rect), "gacha title should not overlap the coin chip") and passed
		passed = _assert_true(not title_rect.intersects(back_rect), "gacha title should not overlap the back button") and passed
	_free_game(game)
	return passed


func _test_gacha_image_panels_do_not_draw_rect_backings() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_gacha_image_panel_draw_style"), "gacha image panels should expose draw style for regression tests")
	if passed:
		for key_variant in ["coin_chip", "button_common", "button_premium", "button_multi", "collection_panel"]:
			var key := String(key_variant)
			var style: Dictionary = game.call("_gacha_image_panel_draw_style", key)
			passed = _assert_true(not bool(style.get("draw_rect_backing", true)), "%s should not draw a rectangular backing behind Image2 art" % key) and passed
			passed = _assert_true(not bool(style.get("draw_hover_frame", true)), "%s hover should tint/shift the image instead of drawing an extra frame" % key) and passed
	_free_game(game)
	return passed


func _test_gacha_click_targets_match_draw_button_rects() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_gacha_draw_button_rect"), "gacha draw buttons should use shared rect helpers")
	if passed:
		var button_ids := ["common_single", "premium_single", "premium_ten"]
		var rects: Array = []
		for id_variant in button_ids:
			var id := String(id_variant)
			var rect := Rect2(game.call("_gacha_draw_button_rect", id))
			rects.append(rect)
			passed = _assert_true(Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE).encloses(rect), "%s draw button should stay inside viewport" % id) and passed
			passed = _assert_true(rect.size.x >= 260.0 and rect.size.y >= 82.0, "%s draw button should remain easy to tap" % id) and passed
		for i in range(rects.size()):
			for j in range(i + 1, rects.size()):
				passed = _assert_true(not Rect2(rects[i]).intersects(Rect2(rects[j])), "gacha draw buttons should not overlap") and passed
	if passed:
		game.coins_total = 999999
		game.call("_handle_gacha_click", Rect2(game.call("_gacha_draw_button_rect", "premium_ten")).get_center())
		passed = _assert_true(game.gacha_draw_results.size() == 10, "clicking the premium-ten shared rect should trigger a ten draw") and passed
	_free_game(game)
	return passed


func _test_gacha_collection_grid_shows_complete_cards() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_gacha_collection_card_rect"), "gacha collection should expose card rects")
	if passed:
		var view_rect := Rect2(game.call("_gacha_collection_view_rect"))
		var previous_rect := Rect2()
		for index in range(36):
			var card_rect := Rect2(game.call("_gacha_collection_card_rect", index))
			passed = _assert_true(view_rect.encloses(card_rect), "visible gacha collection card %d should be fully inside the collection view" % index) and passed
			passed = _assert_true(card_rect.size.x >= 76.0 and card_rect.size.y >= 96.0, "gacha collection card %d should keep a readable card ratio" % index) and passed
			if index > 0:
				passed = _assert_true(not previous_rect.intersects(card_rect), "adjacent visible gacha collection cards should not overlap") and passed
			previous_rect = card_rect
	_free_game(game)
	return passed
