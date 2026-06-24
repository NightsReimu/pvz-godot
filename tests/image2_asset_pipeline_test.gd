extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_image2_asset_paths_are_data_driven() or failed
	failed = not _test_existing_image2_combat_assets_load_from_unified_paths() or failed
	failed = not _test_touhou_bosses_are_not_overridden_by_image2_zombie_assets() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	return game


func _free_game(game: Control) -> void:
	game.free()


func _test_image2_asset_paths_are_data_driven() -> bool:
	var game = _make_game()
	var passed := _assert_true(game.has_method("_image2_asset_path"), "game should expose data-driven image2 asset paths")
	if passed:
		passed = _assert_true(game.call("_image2_asset_path", "plants", "peashooter") == "res://art/image2/plants/peashooter.png", "plants should resolve to art/image2/plants/<kind>.png") and passed
		passed = _assert_true(game.call("_image2_asset_path", "zombies", "normal") == "res://art/image2/zombies/normal.png", "zombies should resolve to art/image2/zombies/<kind>.png") and passed
		passed = _assert_true(game.call("_image2_asset_path", "projectiles", "pea") == "res://art/image2/projectiles/pea.png", "projectiles should resolve to art/image2/projectiles/<kind>.png") and passed
		passed = _assert_true(game.call("_image2_asset_path", "effects", "projectile_impact") == "res://art/image2/effects/projectile_impact.png", "effects should resolve to art/image2/effects/<shape>.png") and passed
	_free_game(game)
	return passed


func _test_existing_image2_combat_assets_load_from_unified_paths() -> bool:
	var game = _make_game()
	var passed := _assert_true(game.has_method("_image2_texture"), "game should expose cached image2 texture loading")
	if passed:
		passed = _assert_true(game.call("_image2_texture", "plants", "peashooter") is Texture2D, "image2 peashooter should load from unified plants path") and passed
		passed = _assert_true(game.call("_image2_texture", "plants", "sunflower") is Texture2D, "image2 sunflower should load from unified plants path") and passed
		passed = _assert_true(game.call("_image2_texture", "plants", "wallnut") is Texture2D, "image2 wallnut should load from unified plants path") and passed
		passed = _assert_true(game.call("_image2_texture", "projectiles", "pea") is Texture2D, "image2 pea projectile should load from unified projectiles path") and passed
		passed = _assert_true(game.call("_image2_texture", "plants", "missing_test_asset") == null, "missing image2 assets should fall back without creating a texture") and passed
	_free_game(game)
	return passed


func _test_touhou_bosses_are_not_overridden_by_image2_zombie_assets() -> bool:
	var game = _make_game()
	var passed := _assert_true(game.has_method("_should_use_image2_zombie_texture"), "game should expose the image2 zombie override gate")
	if passed:
		# v1.0.26: image2 zombie art was reverted to procedural drawing everywhere.
		# Touhou bosses use their own multi-frame pipeline; no zombie uses image2.
		for kind in ["rumia_boss", "daiyousei_boss", "cirno_boss", "meiling_boss", "koakuma_boss", "patchouli_boss", "sakuya_boss", "remilia_boss", "letty_boss", "chen_boss", "alice_boss", "lily_white_boss", "prismriver_boss", "youmu_boss", "flandre_boss"]:
			passed = _assert_true(not bool(game.call("_should_use_image2_zombie_texture", kind)), "%s should keep the Touhou boss frame pipeline (not image2)" % kind) and passed
		passed = _assert_true(not bool(game.call("_should_use_image2_zombie_texture", "normal")), "normal zombies should use procedural drawing (v1.0.26)") and passed
		passed = _assert_true(not bool(game.call("_should_use_image2_zombie_texture", "day_boss")), "non-Touhou bosses should use procedural drawing (v1.0.26)") and passed
	_free_game(game)
	return passed
