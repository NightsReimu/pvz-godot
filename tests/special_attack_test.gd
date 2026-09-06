extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_squash_does_not_hit_on_lock() or failed
	failed = not _test_squash_slam_hits_multiple_zombies() or failed
	failed = not _test_chomper_does_not_instantly_defeat_bosses() or failed
	failed = not _test_fume_effect_is_directional() or failed
	failed = not _test_cherry_and_doom_use_grid_blast_sizes() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "1-test", "terrain": "day"}
	game.active_rows = [0, 1, 2, 3, 4]
	game.water_rows = []
	game.zombies = []
	game.effects = []
	return game


func _test_squash_does_not_hit_on_lock() -> bool:
	var game = _make_game()
	var center = game._cell_center(2, 2)
	game._spawn_zombie_at("normal", 2, center.x + 72.0)
	var target_health = float(game.zombies[0]["health"])
	var plant = game._create_plant("squash", 2, 2)
	var consumed = game._update_squash(plant, 2, 2)
	var passed = _assert_true(not consumed, "squash should not consume itself on initial lock") \
		and _assert_true(is_equal_approx(float(game.zombies[0]["health"]), target_health), "squash should not damage immediately on target acquisition")
	game.free()
	return passed


func _test_squash_slam_hits_multiple_zombies() -> bool:
	var game = _make_game()
	var center = game._cell_center(2, 2)
	game._spawn_zombie_at("normal", 2, center.x + 68.0)
	game._spawn_zombie_at("normal", 2, center.x + 92.0)
	game._spawn_zombie_at("normal", 2, center.x + 116.0)
	var plant = game._create_plant("squash", 2, 2)
	game._update_squash(plant, 2, 2, 0.0)
	game._update_squash(plant, 2, 2, 0.18)
	game._update_squash(plant, 2, 2, 0.13)
	var defeated := 0
	for zombie in game.zombies:
		if float(zombie["health"]) <= 0.0:
			defeated += 1
	var passed = _assert_true(defeated >= 2, "squash slam should crush multiple nearby zombies, not just one")
	game.free()
	return passed


func _test_chomper_does_not_instantly_defeat_bosses() -> bool:
	var game = _make_game()
	var center = game._cell_center(2, 2)
	game._spawn_zombie_at("day_boss", 2, center.x + 78.0)
	var boss_health = float(game.zombies[0]["health"])
	var plant = game._create_plant("chomper", 2, 2)
	plant["chew_timer"] = 0.0
	game.grid = []
	game.support_grid = []
	for row in range(6):
		var row_data: Array = []
		var support_row: Array = []
		for _col in range(9):
			row_data.append(null)
			support_row.append(null)
		game.grid.append(row_data)
		game.support_grid.append(support_row)
	game.grid[2][2] = plant
	game._update_plants(0.1)
	var updated_boss = game.zombies[0]
	var passed = _assert_true(float(updated_boss["health"]) > 0.0, "chomper should not instantly defeat bosses") \
		and _assert_true(float(updated_boss["health"]) < boss_health, "chomper should still damage bosses when it bites")
	game.free()
	return passed


func _test_fume_effect_is_directional() -> bool:
	var game = _make_game()
	var center = game._cell_center(2, 2)
	game._spawn_zombie_at("normal", 2, center.x + 120.0)
	var plant = game._create_plant("fume_shroom", 2, 2)
	plant["attack_timer"] = 0.0
	game._update_fume_shroom(plant, 0.1, 2, 2)
	if not _assert_true(not game.effects.is_empty(), "fume_shroom should create an effect when it fires"):
		game.free()
		return false
	var passed = _assert_true(String(game.effects[game.effects.size() - 1].get("shape", "")) == "fume_cloud", "fume_shroom effect should use its dedicated forward fume cloud")
	game.free()
	return passed


func _test_cherry_and_doom_use_grid_blast_sizes() -> bool:
	var game = _make_game()
	var center = game._cell_center(2, 2)
	game._spawn_zombie_at("normal", 2, game._cell_center(2, 3).x)
	game._spawn_zombie_at("normal", 2, game._cell_center(2, 4).x)
	var cherry_near = float(game.zombies[0]["health"])
	var cherry_far = float(game.zombies[1]["health"])
	game._explode_cherry(2, 2)
	var passed = _assert_true(float(game.zombies[0]["health"]) < cherry_near, "cherry bomb should hit the adjacent cell in its 3x3 area") \
		and _assert_true(is_equal_approx(float(game.zombies[1]["health"]), cherry_far), "cherry bomb should not hit two cells away")
	game.zombies.clear()
	game._spawn_zombie_at("normal", 0, game._cell_center(0, 0).x)
	game._spawn_zombie_at("normal", 2, game._cell_center(2, 8).x)
	var doom_near = float(game.zombies[0]["health"])
	var doom_far = float(game.zombies[1]["health"])
	game._trigger_doom_shroom(2, 2)
	passed = _assert_true(float(game.zombies[0]["health"]) < doom_near, "doom shroom should hit the corner of its 5x5 area") and passed
	passed = _assert_true(is_equal_approx(float(game.zombies[1]["health"]), doom_far), "doom shroom should not hit three cells away") and passed
	game.free()
	return passed
