extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")

const TEST_ROWS := 6
const TEST_COLS := 9


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_vine_lasher_emits_range_effect() or failed
	failed = not _test_prism_grass_effect_reaches_configured_range() or failed
	failed = not _test_wind_orchid_effect_reaches_lane_end() or failed
	failed = not _test_pepper_mortar_plant_food_effect_matches_damage_radius() or failed
	failed = not _test_threepeater_projectiles_follow_three_distinct_lanes() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _assert_float_gte(actual: float, expected: float, message: String) -> bool:
	if actual >= expected or is_equal_approx(actual, expected):
		return true
	push_error("%s | actual=%s expected_at_least=%s" % [message, actual, expected])
	return false


func _assert_float_eq(actual: float, expected: float, message: String) -> bool:
	if is_equal_approx(actual, expected):
		return true
	push_error("%s | actual=%s expected=%s" % [message, actual, expected])
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


func _effect_forward_extent(effect: Dictionary) -> float:
	var position = Vector2(effect["position"])
	if String(effect.get("shape", "circle")) == "lane_spray":
		return position.x + float(effect.get("length", 0.0))
	return position.x + float(effect.get("radius", 0.0))


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	game.free()


func _test_vine_lasher_emits_range_effect() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	var range_limit = float(Defs.PLANTS["vine_lasher"]["range"])
	game._spawn_zombie_at("normal", row, center.x + range_limit - 18.0)
	var plant = game._create_plant("vine_lasher", row, col)
	plant["attack_timer"] = 0.0
	game._update_vine_lasher(plant, 0.1, row, col)
	if not _assert_true(not game.effects.is_empty(), "vine_lasher should emit an attack effect when it lashes"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 1])
	var passed = _assert_true(String(effect.get("shape", "")) == "lane_spray", "vine_lasher effect should be directional along the lane") \
		and _assert_float_gte(_effect_forward_extent(effect), center.x + range_limit - 4.0, "vine_lasher effect should cover its configured attack range")
	_free_game(game)
	return passed


func _test_prism_grass_effect_reaches_configured_range() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	var range_limit = float(Defs.PLANTS["prism_grass"]["range"])
	game._spawn_zombie_at("normal", row, center.x + range_limit - 12.0)
	var plant = game._create_plant("prism_grass", row, col)
	plant["attack_timer"] = 0.0
	game._update_prism_grass(plant, 0.1, row, col)
	if not _assert_true(not game.effects.is_empty(), "prism_grass should emit an attack effect when it fires"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 1])
	var passed = _assert_float_gte(_effect_forward_extent(effect), center.x + range_limit - 4.0, "prism_grass effect should visually reach its configured range")
	_free_game(game)
	return passed


func _test_wind_orchid_effect_reaches_lane_end() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	game._spawn_zombie_at("normal", row, game.BOARD_ORIGIN.x + game.board_size.x - 20.0)
	var plant = game._create_plant("wind_orchid", row, col)
	plant["gust_timer"] = 0.0
	game._update_wind_orchid(plant, 0.1, row, col)
	if not _assert_true(not game.effects.is_empty(), "wind_orchid should emit a gust effect when it pushes a lane"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 1])
	var lane_end_x = game.BOARD_ORIGIN.x + game.board_size.x - 8.0
	var passed = _assert_true(String(effect.get("shape", "")) == "lane_spray", "wind_orchid effect should be a lane gust instead of a short circle pulse") \
		and _assert_float_gte(_effect_forward_extent(effect), lane_end_x, "wind_orchid gust effect should visually reach the end of the lane it affects")
	_free_game(game)
	return passed


func _test_pepper_mortar_plant_food_effect_matches_damage_radius() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var plant = game._create_plant("pepper_mortar", row, col)
	game.grid[row][col] = plant
	var activated = game._activate_plant_food(row, col)
	if not _assert_true(activated, "pepper_mortar plant food should activate on a planted mortar"):
		_free_game(game)
		return false
	if not _assert_true(not game.effects.is_empty(), "pepper_mortar plant food should emit an area effect"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 2])
	var passed = _assert_float_eq(float(effect.get("radius", 0.0)), 210.0, "pepper_mortar plant food effect radius should match its damage radius")
	_free_game(game)
	return passed


func _test_threepeater_projectiles_follow_three_distinct_lanes() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var plant = game._create_plant("threepeater", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	for lane in [1, 2, 3]:
		game._spawn_zombie_at("normal", lane, game.BOARD_ORIGIN.x + game.board_size.x - 40.0)
	game._update_threepeater(plant, 0.1, row, col)
	if not _assert_true(game.projectiles.size() == 3, "threepeater should spawn one projectile per covered lane"):
		_free_game(game)
		return false
	var passed := true
	for projectile in game.projectiles:
		var lane = int(projectile.get("row", -1))
		var projectile_pos = Vector2(projectile.get("position", Vector2.ZERO))
		var expected_y = game._cell_center(lane, col).y - 10.0
		passed = _assert_true(lane >= 1 and lane <= 3, "threepeater projectile should target one of the three covered lanes") and passed
		passed = _assert_float_eq(projectile_pos.y, expected_y, "threepeater projectile visual should originate on its own lane instead of stacking on the center lane") and passed
	_free_game(game)
	return passed
