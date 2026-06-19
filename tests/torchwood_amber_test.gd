extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")

const TEST_ROWS := 6
const TEST_COLS := 9


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_torchwood_ignores_plain_amber_without_a_torchwood() or failed
	failed = not _test_torchwood_transforms_amber_into_fire_amber() or failed
	failed = not _test_fire_amber_doubles_damage_and_marks_flags() or failed
	failed = not _test_fire_amber_keeps_armor_bonus_vs_armored_zombie() or failed
	failed = not _test_fire_amber_splashes_nearby_zombies_on_impact() or failed
	failed = not _test_torchwood_only_transforms_amber_once() or failed
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
	game.current_level = {"id": "1-test", "terrain": "day", "events": []}
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


# Spawns an amber_pea in the given row, then advances projectiles enough steps
# for apply_torchwood_to_projectile to run. Returns the projectile dict (or the
# last remaining one) for assertions.
func _spawn_amber_and_advance(game: Control, row: int, from_col: int, steps: int = 6) -> Dictionary:
	var spawn_x = game._cell_center(row, from_col).x + 32.0
	game._spawn_amber_projectile(row, Vector2(spawn_x, game._row_center_y(row) - 10.0), float(Defs.PLANTS["amber_shooter"]["damage"]))
	for _step in range(steps):
		game._update_projectiles(0.05)
		if game.projectiles.is_empty():
			break
	if game.projectiles.is_empty():
		return {}
	return game.projectiles[0]


func _test_torchwood_ignores_plain_amber_without_a_torchwood() -> bool:
	var game = _make_game()
	var row := 2
	var projectile = _spawn_amber_and_advance(game, row, 0)
	var passed = _assert_true(not projectile.is_empty(), "amber should exist after a step") \
		and _assert_true(not bool(projectile.get("fire", false)), "amber should not ignite without a torchwood present") \
		and _assert_true(not bool(projectile.get("amber_fire", false)), "amber should not gain amber_fire without a torchwood")
	_free_game(game)
	return passed


func _test_torchwood_transforms_amber_into_fire_amber() -> bool:
	var game = _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("torchwood", row, 1)
	var projectile = _spawn_amber_and_advance(game, row, 0)
	var passed = _assert_true(not projectile.is_empty(), "amber should exist after passing a torchwood") \
		and _assert_true(bool(projectile.get("fire", false)), "amber should gain the fire flag after passing a torchwood") \
		and _assert_true(bool(projectile.get("amber_fire", false)), "amber should gain the amber_fire flag so it renders as 烈焰琥珀")
	_free_game(game)
	return passed


func _test_fire_amber_doubles_damage_and_marks_flags() -> bool:
	# Plain amber (no torchwood) for the baseline damage.
	var plain_game = _make_game()
	var plain_row := 2
	var plain = _spawn_amber_and_advance(plain_game, plain_row, 0)
	var plain_damage = float(plain.get("damage", 0.0))
	_free_game(plain_game)
	# Fire amber (through a torchwood) on a fresh game.
	var game = _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("torchwood", row, 1)
	var base_damage = float(Defs.PLANTS["amber_shooter"]["damage"])
	var projectile = _spawn_amber_and_advance(game, row, 0)
	var fire_damage = float(projectile.get("damage", 0.0))
	var passed = _assert_true(not projectile.is_empty(), "fire amber should exist") \
		and _assert_true(is_equal_approx(fire_damage, plain_damage * 2.0), "fire amber damage should be doubled vs a plain amber (got %s vs %s)" % [fire_damage, plain_damage]) \
		and _assert_true(fire_damage > base_damage, "fire amber damage (%s) should clearly exceed the base amber def (%s)" % [fire_damage, base_damage]) \
		and _assert_true(bool(projectile.get("amber_fire", false)), "fire amber should carry the amber_fire marker")
	_free_game(game)
	return passed


func _test_fire_amber_keeps_armor_bonus_vs_armored_zombie() -> bool:
	var game = _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("torchwood", row, 1)
	var zombie_x = game._cell_center(row, 6).x
	game._spawn_zombie_at("buckethead", row, zombie_x)
	var armored_health = float(game.zombies[0]["health"])
	var armored_shield = float(game.zombies[0].get("shield_health", 0.0))
	# Spawn the amber back at column 0 so it crosses the torchwood naturally.
	game._spawn_amber_projectile(row, Vector2(game._cell_center(row, 0).x + 32.0, game._row_center_y(row) - 10.0), float(Defs.PLANTS["amber_shooter"]["damage"]))
	var ignited = false
	for _step in range(60):
		game._update_projectiles(0.05)
		if not game.projectiles.is_empty() and bool(game.projectiles[0].get("amber_fire", false)):
			ignited = true
		if game.projectiles.is_empty():
			break
	var total_after = float(game.zombies[0]["health"]) + float(game.zombies[0].get("shield_health", 0.0))
	var total_before = armored_health + armored_shield
	var passed = _assert_true(ignited, "amber should ignite into fire amber before hitting the armored zombie") \
		and _assert_true(total_after < total_before, "fire amber should still damage an armored zombie (and keep its armor bonus)")
	_free_game(game)
	return passed


func _test_fire_amber_splashes_nearby_zombies_on_impact() -> bool:
	var game = _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("torchwood", row, 1)
	var impact_x = game._cell_center(row, 6).x
	game._spawn_zombie_at("normal", row, impact_x)
	game._spawn_zombie_at("normal", row, impact_x + 30.0)
	var primary_before = float(game.zombies[0]["health"])
	var splash_before = float(game.zombies[1]["health"])
	game._spawn_amber_projectile(row, Vector2(game._cell_center(row, 0).x + 32.0, game._row_center_y(row) - 10.0), float(Defs.PLANTS["amber_shooter"]["damage"]))
	for _step in range(60):
		game._update_projectiles(0.05)
		if game.projectiles.is_empty():
			break
	var primary_after = float(game.zombies[0]["health"])
	var splash_after = float(game.zombies[1]["health"])
	var passed = _assert_true(primary_after < primary_before, "fire amber should damage its primary target") \
		and _assert_true(splash_after < splash_before, "fire amber should splash a nearby zombie on impact (烈焰琥珀 gains fire splash)")
	_free_game(game)
	return passed


func _test_torchwood_only_transforms_amber_once() -> bool:
	# Baseline: a single torchwood should produce exactly 2x damage.
	var baseline_game = _make_game()
	var baseline_row := 2
	baseline_game.grid[baseline_row][1] = baseline_game._create_plant("torchwood", baseline_row, 1)
	var baseline = _spawn_amber_and_advance(baseline_game, baseline_row, 0)
	var baseline_damage = float(baseline.get("damage", 0.0))
	_free_game(baseline_game)
	# Two torchwoods in the same lane; a guarded amber should still only double once.
	var game = _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("torchwood", row, 1)
	game.grid[row][3] = game._create_plant("torchwood", row, 3)
	var projectile = _spawn_amber_and_advance(game, row, 0, 10)
	var fire_damage = float(projectile.get("damage", 0.0))
	var passed = _assert_true(is_equal_approx(fire_damage, baseline_damage), "amber passing a second torchwood should not double again (got %s vs %s)" % [fire_damage, baseline_damage]) \
		and _assert_true(bool(projectile.get("amber_fire", false)), "amber should be marked fire after passing a torchwood")
	_free_game(game)
	return passed
