extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_prism_grass_applies_slow() or failed
	failed = not _test_hypnotized_dancing_summons_hypnotized_backup() or failed
	failed = not _test_hypnotized_nether_sleeps_enemy_zombies() or failed
	failed = not _test_magnet_shroom_strips_fog_zombie_equipment() or failed
	failed = not _test_pogo_zombie_stops_at_tallnut() or failed
	failed = not _test_jack_in_the_box_explodes_nearby_plants() or failed
	failed = not _test_anchor_fern_roots_nearby_plants_against_push() or failed
	failed = not _test_excavator_zombie_pushes_a_plant_chain_left() or failed
	failed = not _test_tornado_zombie_finishes_entry_and_slows_down() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_grid(rows: int, cols: int) -> Array:
	var result: Array = []
	for _row in range(rows):
		var row_data: Array = []
		for _col in range(cols):
			row_data.append(null)
		result.append(row_data)
	return result


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "2-test", "terrain": "night", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
	game.grid = _make_grid(6, 9)
	game.support_grid = _make_grid(6, 9)
	game.zombies = []
	game.weeds = []
	game.spears = []
	game.effects = []
	game.mowers = []
	for row in range(6):
		game.mowers.append({
			"row": row,
			"x": game.BOARD_ORIGIN.x - 56.0,
			"armed": true,
			"active": false,
		})
	game.toast_label = Label.new()
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	game.free()


func _test_prism_grass_applies_slow() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	game._spawn_zombie_at("normal", row, center.x + 120.0)
	var plant = game._create_plant("prism_grass", row, col)
	plant["attack_timer"] = 0.0
	game._update_prism_grass(plant, 0.1, row, col)
	var passed = _assert_true(float(game.zombies[0].get("slow_timer", 0.0)) > 0.0, "prism_grass should apply a slow effect when it hits")
	_free_game(game)
	return passed


func _test_hypnotized_dancing_summons_hypnotized_backup() -> bool:
	var game = _make_game()
	var row := 2
	var summon_x = game.BOARD_ORIGIN.x + game.board_size.x * 0.82
	game._spawn_zombie_at("dancing", row, summon_x)
	var dancing = game.zombies[0]
	dancing = game._hypnotize_zombie(dancing)
	dancing["summon_cooldown"] = 0.0
	dancing["dance_summoned"] = false
	game.zombies[0] = dancing
	game._update_zombies(0.1)
	var backup_count := 0
	var all_hypnotized := true
	for zombie in game.zombies:
		if String(zombie["kind"]) != "backup_dancer":
			continue
		backup_count += 1
		all_hypnotized = all_hypnotized and bool(zombie.get("hypnotized", false))
	var passed = _assert_true(backup_count > 0, "hypnotized dancing zombie should still summon backup dancers") \
		and _assert_true(all_hypnotized, "backup dancers summoned by a hypnotized dancing zombie should also be hypnotized")
	_free_game(game)
	return passed


func _test_hypnotized_nether_sleeps_enemy_zombies() -> bool:
	var game = _make_game()
	var row := 2
	var col := 3
	var center = game._cell_center(row, col)
	var plant = game._create_plant("puff_shroom", row, col)
	game.grid[row][col] = plant
	game._spawn_zombie_at("nether", row, center.x)
	game._spawn_zombie_at("normal", row, center.x + 72.0)
	var nether = game.zombies[0]
	nether = game._hypnotize_zombie(nether)
	nether["sleep_cooldown"] = 0.0
	game.zombies[0] = nether
	game._update_zombies(0.1)
	var updated_plant = game.grid[row][col]
	var enemy_zombie = game.zombies[1]
	var passed = _assert_true(float(enemy_zombie.get("special_pause_timer", 0.0)) > 0.0, "hypnotized nether should put enemy zombies to sleep") \
		and _assert_true(float(updated_plant.get("sleep_timer", 0.0)) <= 0.0, "hypnotized nether should not put allied plants to sleep")
	_free_game(game)
	return passed


func _test_magnet_shroom_strips_fog_zombie_equipment() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var plant = game._create_plant("magnet_shroom", row, col)
	plant["support_timer"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("digger_zombie", row, game._cell_center(row, 5).x)
	game._spawn_zombie_at("pogo_zombie", row, game._cell_center(row, 6).x)
	game._update_plants(0.12)
	var digger = game.zombies[0]
	var pogo = game.zombies[1]
	var passed = _assert_true(not bool(digger.get("digger_tunneling", true)), "magnet_shroom should pull the digger gear off a digger zombie") \
		and _assert_true(not bool(pogo.get("pogo_active", true)), "magnet_shroom should remove the pogo stick and disable repeated jumps")
	_free_game(game)
	return passed


func _test_pogo_zombie_stops_at_tallnut() -> bool:
	var game = _make_game()
	var row := 2
	var tallnut_col := 3
	game.grid[row][tallnut_col] = game._create_plant("tallnut", row, tallnut_col)
	game._spawn_zombie_at("pogo_zombie", row, game._cell_center(row, tallnut_col).x + 50.0)
	var pogo = game.zombies[0]
	pogo["special_pause_timer"] = 0.0
	game.zombies[0] = pogo
	game._update_zombies(0.12)
	var updated = game.zombies[0]
	var passed = _assert_true(not bool(updated.get("pogo_active", true)), "tallnut should stop a pogo zombie instead of letting it keep bouncing")
	_free_game(game)
	return passed


func _test_jack_in_the_box_explodes_nearby_plants() -> bool:
	var game = _make_game()
	var row := 2
	var col := 3
	game.grid[row][col] = game._create_plant("wallnut", row, col)
	game._spawn_zombie_at("jack_in_the_box_zombie", row, game._cell_center(row, col).x + 18.0)
	var jack = game.zombies[0]
	jack["jack_timer"] = 0.05
	game.zombies[0] = jack
	game._update_zombies(0.12)
	var passed = _assert_true(float(game.grid[row][col].get("health", 1.0)) <= 0.0, "jack_in_the_box explosion should destroy nearby plants")
	_free_game(game)
	return passed


func _test_anchor_fern_roots_nearby_plants_against_push() -> bool:
	var game = _make_game()
	var row := 2
	var col := 3
	if not _assert_true(game.has_method("_update_anchor_fern"), "expected anchor fern update helper to exist"):
		_free_game(game)
		return false
	game.grid[row][col - 1] = game._create_plant("peashooter", row, col - 1)
	var plant = game._create_plant("anchor_fern", row, col)
	plant["support_timer"] = 0.0
	game.grid[row][col] = plant
	game._update_anchor_fern(plant, 0.12, row, col)
	var ally = game.grid[row][col - 1]
	var passed = _assert_true(float(ally.get("rooted_timer", 0.0)) > 0.0, "anchor_fern should grant a rooted timer to adjacent allies")
	_free_game(game)
	return passed


func _test_excavator_zombie_pushes_a_plant_chain_left() -> bool:
	var game = _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("peashooter", row, 1)
	game.grid[row][2] = game._create_plant("wallnut", row, 2)
	game.grid[row][3] = game._create_plant("sunflower", row, 3)
	game._spawn_zombie_at("excavator_zombie", row, game._cell_center(row, 3).x + 22.0)
	var excavator = game.zombies[0]
	excavator["special_pause_timer"] = 0.0
	game.zombies[0] = excavator
	game._update_zombies(0.18)
	var passed = _assert_true(game.grid[row][0] != null and String(game.grid[row][0].get("kind", "")) == "peashooter", "excavator push should move the leftmost plant into column 0") \
		and _assert_true(game.grid[row][1] != null and String(game.grid[row][1].get("kind", "")) == "wallnut", "excavator push should shift the middle plant left by one tile") \
		and _assert_true(game.grid[row][2] != null and String(game.grid[row][2].get("kind", "")) == "sunflower", "excavator push should move the contacted plant into the previous tile")
	_free_game(game)
	return passed


func _test_tornado_zombie_finishes_entry_and_slows_down() -> bool:
	var game = _make_game()
	game.current_level = {"id": "4-test", "terrain": "fog", "events": []}
	var row := 2
	game._spawn_zombie("tornado_zombie", row)
	var tornado = game.zombies[0]
	var spawn_x = float(tornado["x"])
	game._update_zombies(0.2)
	tornado = game.zombies[0]
	var entered_midfield = float(tornado["x"]) < spawn_x - 40.0
	for _step in range(12):
		game._update_zombies(0.12)
	tornado = game.zombies[0]
	var passed = _assert_true(entered_midfield, "tornado_zombie should rapidly relocate inward during its entry phase") \
		and _assert_true(not bool(tornado.get("tornado_entry", true)), "tornado_zombie should finish its whirlwind entry state") \
		and _assert_true(float(tornado.get("base_speed", 0.0)) <= 18.0, "tornado_zombie should slow down to a normal walking pace after entry")
	_free_game(game)
	return passed
