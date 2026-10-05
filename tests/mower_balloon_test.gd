extends "res://tests/fog_world_test.gd"


func _run() -> void:
	var failed := false
	for board in [
		{"terrain": "day", "row": 2, "kind": "lawn_mower"},
		{"terrain": "pool", "row": 2, "kind": "pool_cleaner"},
		{"terrain": "fog", "row": 5, "kind": "lawn_mower"},
		{"terrain": "roof", "row": 2, "kind": "roof_cleaner"},
	]:
		failed = not _test_balloon_starts_mower(board) or failed
	failed = not _test_balloon_waits_for_active_mower() or failed
	failed = not _test_balloon_loses_when_mower_is_spent() or failed
	failed = not _test_mower_sweeps_only_its_lane() or failed
	failed = not _test_ground_zombie_still_starts_mower() or failed
	print("Balloon mower regression: 8 scenarios, %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)


func _mower_game(terrain: String = "day") -> Control:
	var game = _make_game()
	game.current_level = {"id": "mower-test", "title": "小推车回归", "terrain": terrain, "events": []}
	game.battle_state = game.BATTLE_PLAYING
	game.board_rows = 6 if terrain in ["pool", "fog"] else 5
	game.active_rows = [0, 1, 2, 3, 4, 5] if game.board_rows == 6 else [0, 1, 2, 3, 4]
	game.water_rows = [2, 3] if game.board_rows == 6 else []
	game.board_size = Vector2(game.CELL_SIZE.x * 9.0, game.CELL_SIZE.y * game.board_rows)
	for mower in game.mowers:
		mower.x = game.BOARD_ORIGIN.x - 64.0
	return game


func _test_balloon_starts_mower(board: Dictionary) -> bool:
	var game = _mower_game(String(board.terrain))
	var row := int(board.row)
	game.mowers[row].kind = String(board.kind)
	game.current_level.objective = {"type": "no_mower"}
	game._ensure_objective_runtime().setup(game.current_level)
	game._spawn_zombie_at("balloon_zombie", row, game.BOARD_ORIGIN.x - 23.0)
	game._update_zombies(0.1)
	var passed = _assert_true(game.battle_state == game.BATTLE_PLAYING, "%s: flying balloon must trigger the mower before defeat" % board.terrain)
	passed = _assert_true(bool(game.mowers[row].active) and not bool(game.mowers[row].armed), "%s: mower should activate and consume its charge" % board.terrain) and passed
	passed = _assert_true(game.objective_runtime.mowers_used == 1, "Balloon-triggered mower must count for no-mower objectives") and passed
	game._update_zombies(0.016)
	passed = _assert_true(game.objective_runtime.mowers_used == 1, "An active mower must not be counted twice") and passed
	game._update_mowers(0.1)
	passed = _assert_true(float(game.zombies[0].health) <= 0.0 and bool(game.zombies[0].get("killed_by_mower", false)), "%s: mower should clear the flying balloon" % board.terrain) and passed
	_free_game(game)
	return passed


func _test_balloon_waits_for_active_mower() -> bool:
	var game = _mower_game()
	game.mowers[2].armed = false
	game.mowers[2].active = true
	game._spawn_zombie_at("balloon_zombie", 2, game.BOARD_ORIGIN.x - 24.0)
	game._update_zombies(0.016)
	var passed = _assert_true(game.battle_state == game.BATTLE_PLAYING, "A flying balloon must not bypass an already active mower")
	game._update_mowers(0.016)
	passed = _assert_true(float(game.zombies[0].health) <= 0.0, "The active mower should clear the balloon in the same tick") and passed
	_free_game(game)
	return passed


func _test_balloon_loses_when_mower_is_spent() -> bool:
	var game = _mower_game()
	game.mowers[2].armed = false
	game.mowers[2].active = false
	game._spawn_zombie_at("balloon_zombie", 2, game.BOARD_ORIGIN.x - 24.0)
	game._update_zombies(0.016)
	var passed = _assert_true(game.battle_state == game.BATTLE_LOST, "A flying balloon must still cause defeat after the mower is spent")
	_free_game(game)
	return passed


func _test_mower_sweeps_only_its_lane() -> bool:
	var game = _mower_game()
	game.mowers[2].armed = false
	game.mowers[2].active = true
	game.mowers[2].x = game.BOARD_ORIGIN.x + 100.0
	for row in [2, 3]:
		game._spawn_zombie_at("balloon_zombie", row, game.BOARD_ORIGIN.x + 260.0)
	game._spawn_zombie_at("normal", 2, game.BOARD_ORIGIN.x + 320.0)
	game._update_mowers(0.5)
	var passed = _assert_true(float(game.zombies[0].health) <= 0.0, "Mower sweep must catch balloons between ticks")
	passed = _assert_true(float(game.zombies[1].health) > 0.0, "Mower must leave adjacent-lane balloons alone") and passed
	passed = _assert_true(float(game.zombies[2].health) <= 0.0, "Mower must still clear ground zombies") and passed
	_free_game(game)
	return passed


func _test_ground_zombie_still_starts_mower() -> bool:
	var game = _mower_game()
	game._spawn_zombie_at("normal", 2, game.BOARD_ORIGIN.x - 24.0)
	game._update_zombies(0.016)
	var passed = _assert_true(game.battle_state == game.BATTLE_PLAYING and bool(game.mowers[2].active), "Ground zombies must still activate the mower before defeat")
	game._update_mowers(0.016)
	passed = _assert_true(float(game.zombies[0].health) <= 0.0, "The mower must still clear ground zombies at the home boundary") and passed
	_free_game(game)
	return passed
