extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")

const TEST_ROWS := 6
const TEST_COLS := 9


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_boomerang_stays_plain_without_torchwood() or failed
	failed = not _test_torchwood_ignites_boomerang_without_breaking_return_path() or failed
	failed = not _test_flame_boomerang_applies_burn_and_splash_on_hit() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_grid() -> Array:
	var result: Array = []
	for _row in range(TEST_ROWS):
		var row_data: Array = []
		for _col in range(TEST_COLS):
			row_data.append(null)
		result.append(row_data)
	return result


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "flame-boomerang-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(TEST_COLS * 98.0, 5.0 * 110.0)
	game.water_rows = []
	game.grid = _make_grid()
	game.support_grid = _make_grid()
	game.zombies = []
	game.weeds = []
	game.spears = []
	game.effects = []
	game.toast_label = Label.new()
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	game.free()


func _spawn_boomerang_and_advance(game: Control, row: int, steps: int = 10) -> Dictionary:
	game._spawn_boomerang_projectile(
		row,
		Vector2(game._cell_center(row, 0).x + 32.0, game._row_center_y(row) - 10.0),
		game._cell_center(row, 0).x + 8.0,
		float(Defs.PLANTS["boomerang_shooter"]["damage"]),
		int(Defs.PLANTS["boomerang_shooter"]["max_targets"])
	)
	for _step in range(steps):
		game._update_projectiles(0.05)
		if game.projectiles.is_empty():
			break
	if game.projectiles.is_empty():
		return {}
	return game.projectiles[0]


func _test_boomerang_stays_plain_without_torchwood() -> bool:
	var game := _make_game()
	var projectile := _spawn_boomerang_and_advance(game, 2)
	var passed := _assert_true(not projectile.is_empty(), "boomerang should exist after a step")
	passed = _assert_true(not bool(projectile.get("fire", false)), "boomerang should not ignite without torchwood") and passed
	passed = _assert_true(not bool(projectile.get("flame_boomerang", false)), "plain boomerang should not carry flame marker") and passed
	_free_game(game)
	return passed


func _test_torchwood_ignites_boomerang_without_breaking_return_path() -> bool:
	var game := _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("torchwood", row, 1)
	var projectile := _spawn_boomerang_and_advance(game, row)
	var passed := _assert_true(not projectile.is_empty(), "boomerang should survive passing torchwood")
	passed = _assert_true(bool(projectile.get("fire", false)), "torchwood should set the fire flag on a boomerang") and passed
	passed = _assert_true(bool(projectile.get("flame_boomerang", false)), "torchwood should mark a flame boomerang") and passed
	passed = _assert_true(float(projectile.get("burn_damage", 0.0)) > 0.0, "flame boomerang should carry burn damage") and passed
	passed = _assert_true(float(projectile.get("burn_duration", 0.0)) >= 2.0, "flame boomerang should carry a visible burn duration") and passed
	passed = _assert_true(bool(projectile.get("outbound", true)) or float(projectile.get("speed", 0.0)) < 0.0, "ignition must preserve the boomerang return state") and passed
	_free_game(game)
	return passed


func _test_flame_boomerang_applies_burn_and_splash_on_hit() -> bool:
	var game := _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("torchwood", row, 1)
	var impact_x: float = float(game._cell_center(row, 6).x)
	game._spawn_zombie_at("normal", row, impact_x)
	game._spawn_zombie_at("normal", row, impact_x + 30.0)
	var primary_before := float(game.zombies[0]["health"])
	var splash_before := float(game.zombies[1]["health"])
	game._spawn_boomerang_projectile(row, Vector2(game._cell_center(row, 0).x + 32.0, game._row_center_y(row) - 10.0), game._cell_center(row, 0).x + 8.0, float(Defs.PLANTS["boomerang_shooter"]["damage"]), 3)
	var ignited := false
	for _step in range(100):
		game._update_projectiles(0.05)
		if not game.projectiles.is_empty() and bool(game.projectiles[0].get("flame_boomerang", false)):
			ignited = true
		if game.projectiles.is_empty():
			break
	var primary_after := float(game.zombies[0]["health"])
	var splash_after := float(game.zombies[1]["health"])
	var passed := _assert_true(ignited, "boomerang should ignite before reaching its target")
	passed = _assert_true(primary_after < primary_before, "flame boomerang should damage its primary target") and passed
	passed = _assert_true(splash_after < splash_before, "flame boomerang should splash nearby zombies") and passed
	passed = _assert_true(float(game.zombies[0].get("corrode_timer", 0.0)) > 0.0, "flame boomerang should apply a burn timer") and passed
	passed = _assert_true(float(game.zombies[0].get("corrode_dps", 0.0)) > 0.0, "flame boomerang should apply burn damage over time") and passed
	_free_game(game)
	return passed
