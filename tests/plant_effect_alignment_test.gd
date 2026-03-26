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
	failed = not _test_lane_spray_visual_geometry_stays_at_configured_extent() or failed
	failed = not _test_circle_effect_visual_geometry_stays_at_configured_extent() or failed
	failed = not _test_wind_orchid_effect_reaches_lane_end() or failed
	failed = not _test_pepper_mortar_plant_food_effect_matches_damage_radius() or failed
	failed = not _test_threepeater_projectiles_follow_three_distinct_lanes() or failed
	failed = not _test_jalapeno_effect_is_a_full_lane_blast() or failed
	failed = not _test_torchwood_fire_pea_splashes_nearby_zombies() or failed
	failed = not _test_boomerang_shooter_fires_for_any_zombie_ahead() or failed
	failed = not _test_boomerang_shooter_hits_three_targets_then_returns() or failed
	failed = not _test_sakura_shooter_fires_for_any_zombie_ahead() or failed
	failed = not _test_sakura_shooter_petals_split_on_hit() or failed
	failed = not _test_split_pea_fires_forward_and_backward() or failed
	failed = not _test_starfruit_spawns_five_distinct_vectors() or failed
	failed = not _test_lotus_lancer_pierces_an_entire_lane() or failed
	failed = not _test_mirror_reed_reveals_hidden_shouyue() or failed
	failed = not _test_frost_fan_spreads_slow_across_three_lanes() or failed
	failed = not _test_mist_orchid_fires_for_any_zombie_ahead() or failed
	failed = not _test_storm_reed_hits_midfield_intruders() or failed
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


func _test_lane_spray_visual_geometry_stays_at_configured_extent() -> bool:
	var game = _make_game()
	var effect := {
		"shape": "lane_spray",
		"position": Vector2(320.0, 240.0),
		"length": 390.0,
		"width": 42.0,
		"radius": 195.0,
		"time": 0.18,
		"duration": 0.18,
		"color": Color(0.68, 0.9, 1.0, 0.28),
	}
	if not _assert_true(game.has_method("_effect_visual_length"), "game should expose a helper for the rendered lane_spray length"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_effect_visual_width"), "game should expose a helper for the rendered lane_spray width"):
		_free_game(game)
		return false
	var passed = _assert_float_eq(float(game.call("_effect_visual_length", effect, 1.0)), 390.0, "lane_spray should render at full configured length at the start of the effect") \
		and _assert_float_eq(float(game.call("_effect_visual_length", effect, 0.35)), 390.0, "lane_spray should keep rendering at the configured length throughout the effect") \
		and _assert_float_eq(float(game.call("_effect_visual_width", effect, 1.0)), 42.0, "lane_spray should render at its configured width at the start of the effect") \
		and _assert_float_eq(float(game.call("_effect_visual_width", effect, 0.35)), 42.0, "lane_spray should keep rendering at the configured width throughout the effect")
	_free_game(game)
	return passed


func _test_circle_effect_visual_geometry_stays_at_configured_extent() -> bool:
	var game = _make_game()
	var effect := {
		"position": Vector2(320.0, 240.0),
		"radius": 210.0,
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.42, 0.12, 0.56),
	}
	if not _assert_true(game.has_method("_effect_visual_radius"), "game should expose a helper for the rendered circle effect radius"):
		_free_game(game)
		return false
	var passed = _assert_float_eq(float(game.call("_effect_visual_radius", effect, 1.0)), 210.0, "circle effects should render at full configured radius at the start of the effect") \
		and _assert_float_eq(float(game.call("_effect_visual_radius", effect, 0.35)), 210.0, "circle effects should keep rendering at the configured radius throughout the effect")
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


func _test_jalapeno_effect_is_a_full_lane_blast() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	game._trigger_jalapeno(row, col)
	if not _assert_true(not game.effects.is_empty(), "jalapeno should emit an effect when it detonates"):
		_free_game(game)
		return false
	var lane_effect := {}
	for effect_variant in game.effects:
		var effect = Dictionary(effect_variant)
		if String(effect.get("shape", "")) == "lane_spray":
			lane_effect = effect
			break
	var passed = _assert_true(not lane_effect.is_empty(), "jalapeno should draw a directional lane blast instead of only a circle pulse") \
		and _assert_float_gte(float(lane_effect.get("length", 0.0)), game.board_size.x - 12.0, "jalapeno lane blast effect should cover the full board width")
	_free_game(game)
	return passed


func _test_torchwood_fire_pea_splashes_nearby_zombies() -> bool:
	var game = _make_game()
	var row := 2
	var pea_row: Array = []
	for _col in range(TEST_COLS):
		pea_row.append(null)
	game.grid[row][0] = game._create_plant("peashooter", row, 0)
	game.grid[row][1] = game._create_plant("torchwood", row, 1)
	game._spawn_zombie_at("normal", row, game._cell_center(row, 3).x)
	game._spawn_zombie_at("normal", row, game._cell_center(row, 3).x + 28.0)
	var front_health = float(game.zombies[0]["health"])
	var splash_health = float(game.zombies[1]["health"])
	game._spawn_projectile(row, game._cell_center(row, 0) + Vector2(32.0, -10.0), Color(0.36, 0.86, 0.3), 20.0, 0.0, 520.0, 8.0)
	for _step in range(12):
		game._update_projectiles(0.08)
		if game.projectiles.is_empty():
			break
	var passed = _assert_true(float(game.zombies[0]["health"]) < front_health, "torchwood fire pea should still damage its primary target") \
		and _assert_true(float(game.zombies[1]["health"]) < splash_health, "torchwood fire pea should splash nearby zombies on impact")
	_free_game(game)
	return passed


func _test_boomerang_shooter_fires_for_any_zombie_ahead() -> bool:
	if not _assert_true(Defs.PLANTS.has("boomerang_shooter"), "expected boomerang_shooter plant definition to exist"):
		return false
	var game = _make_game()
	var row := 2
	var col := 1
	var plant = game._create_plant("boomerang_shooter", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, game.BOARD_ORIGIN.x + game.board_size.x - 18.0)
	game._update_boomerang_shooter(plant, 0.1, row, col)
	var passed = _assert_true(not game.projectiles.is_empty(), "boomerang_shooter should fire when any zombie exists anywhere ahead in its lane")
	_free_game(game)
	return passed


func _test_boomerang_shooter_hits_three_targets_then_returns() -> bool:
	if not _assert_true(Defs.PLANTS.has("boomerang_shooter"), "expected boomerang_shooter plant definition to exist"):
		return false
	var game = _make_game()
	var row := 2
	var col := 1
	var plant = game._create_plant("boomerang_shooter", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	for offset in [0.0, 36.0, 72.0, 108.0]:
		game._spawn_zombie_at("normal", row, game._cell_center(row, 5).x + offset)
	var before: Array = []
	for zombie in game.zombies:
		before.append(float(zombie["health"]))
	game._update_plants(0.1)
	for _step in range(60):
		game._update_projectiles(0.08)
	var passed := true
	for zombie_index in range(3):
		passed = _assert_true(float(game.zombies[zombie_index]["health"]) <= before[zombie_index] - 35.0, "boomerang_shooter should hit each of the first three zombies twice") and passed
	passed = _assert_true(is_equal_approx(float(game.zombies[3]["health"]), before[3]), "boomerang_shooter should ignore the fourth zombie on a single throw") and passed
	_free_game(game)
	return passed


func _test_sakura_shooter_fires_for_any_zombie_ahead() -> bool:
	if not _assert_true(Defs.PLANTS.has("sakura_shooter"), "expected sakura_shooter plant definition to exist"):
		return false
	var game = _make_game()
	var row := 2
	var col := 1
	var plant = game._create_plant("sakura_shooter", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, game.BOARD_ORIGIN.x + game.board_size.x - 18.0)
	game._update_sakura_shooter(plant, 0.1, row, col)
	var passed = _assert_true(not game.projectiles.is_empty(), "sakura_shooter should fire when any zombie exists anywhere ahead in its lane")
	_free_game(game)
	return passed


func _test_split_pea_fires_forward_and_backward() -> bool:
	var game = _make_game()
	var row := 2
	var col := 3
	var center = game._cell_center(row, col)
	var plant = game._create_plant("split_pea", row, col)
	plant["shot_cooldown"] = 0.0
	plant["attack_timer"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, center.x + 180.0)
	game._spawn_zombie_at("normal", row, center.x - 180.0)
	game._update_plants(0.12)
	var forward_count := 0
	var backward_count := 0
	for projectile in game.projectiles:
		if float(projectile.get("speed", 0.0)) > 0.0:
			forward_count += 1
		elif float(projectile.get("speed", 0.0)) < 0.0:
			backward_count += 1
	var passed = _assert_true(forward_count > 0, "split_pea should fire forward when zombies are ahead") \
		and _assert_true(backward_count > 0, "split_pea should also fire backward when zombies are behind it")
	_free_game(game)
	return passed


func _test_starfruit_spawns_five_distinct_vectors() -> bool:
	var game = _make_game()
	var row := 2
	var col := 3
	var plant = game._create_plant("starfruit", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, game._cell_center(row, 7).x)
	game._update_plants(0.12)
	if not _assert_true(game.projectiles.size() == 5, "starfruit should launch five projectiles per volley"):
		_free_game(game)
		return false
	var velocity_signatures := {}
	for projectile in game.projectiles:
		var signature = "%d:%d" % [signi(int(round(float(projectile.get("speed", 0.0))))), signi(int(round(float(projectile.get("velocity_y", 0.0)))))]
		velocity_signatures[signature] = true
	var passed = _assert_true(velocity_signatures.size() == 5, "starfruit volley should contain five distinct travel vectors")
	_free_game(game)
	return passed


func _test_sakura_shooter_petals_split_on_hit() -> bool:
	if not _assert_true(Defs.PLANTS.has("sakura_shooter"), "expected sakura_shooter plant definition to exist"):
		return false
	var game = _make_game()
	var row := 2
	var col := 1
	var plant = game._create_plant("sakura_shooter", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, game._cell_center(row, 4).x)
	game._update_plants(0.1)
	var had_split := false
	for _step in range(32):
		game._update_projectiles(0.08)
		for projectile in game.projectiles:
			if String(projectile.get("kind", "")) == "sakura_petal" and absf(float(projectile.get("velocity_y", 0.0))) > 0.1:
				had_split = true
				break
		if had_split:
			break
	var passed = _assert_true(had_split, "sakura_shooter should split into diagonal child petals after hitting a zombie")
	_free_game(game)
	return passed


func _test_lotus_lancer_pierces_an_entire_lane() -> bool:
	if not _assert_true(Defs.PLANTS.has("lotus_lancer"), "expected lotus_lancer plant definition to exist"):
		return false
	var game = _make_game()
	var row := 2
	var col := 1
	var plant = game._create_plant("lotus_lancer", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	for target_col in [4, 5, 6]:
		game._spawn_zombie_at("normal", row, game._cell_center(row, target_col).x)
	var before: Array = []
	for zombie in game.zombies:
		before.append(float(zombie["health"]))
	game._update_plants(0.1)
	var passed := true
	for zombie_index in range(game.zombies.size()):
		passed = _assert_true(float(game.zombies[zombie_index]["health"]) < before[zombie_index], "lotus_lancer should pierce through every zombie in its lane") and passed
	_free_game(game)
	return passed


func _test_mirror_reed_reveals_hidden_shouyue() -> bool:
	if not _assert_true(Defs.PLANTS.has("mirror_reed"), "expected mirror_reed plant definition to exist"):
		return false
	var game = _make_game()
	game.current_level = {"id": "3-test", "terrain": "pool", "events": []}
	game.water_rows = [2, 3]
	var row := 1
	var col := 3
	var plant = game._create_plant("mirror_reed", row, col)
	plant["support_timer"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("shouyue", 2, game._cell_center(2, 6).x)
	var hidden_before = bool(game._is_hidden_from_lane_attacks(game.zombies[0]))
	var health_before = float(game.zombies[0]["health"])
	game._update_plants(0.1)
	var hidden_after = bool(game._is_hidden_from_lane_attacks(game.zombies[0]))
	var health_after = float(game.zombies[0]["health"])
	var passed = _assert_true(hidden_before, "shouyue should begin hidden before mirror_reed pulses") \
		and _assert_true(not hidden_after, "mirror_reed pulse should reveal nearby hidden zombies") \
		and _assert_true(health_after < health_before, "mirror_reed pulse should damage the revealed shouyue")
	_free_game(game)
	return passed


func _test_frost_fan_spreads_slow_across_three_lanes() -> bool:
	if not _assert_true(Defs.PLANTS.has("frost_fan"), "expected frost_fan plant definition to exist"):
		return false
	var game = _make_game()
	var row := 2
	var col := 1
	var plant = game._create_plant("frost_fan", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	for lane in [1, 2, 3]:
		game._spawn_zombie_at("normal", lane, game._cell_center(lane, 5).x)
	var before: Array = []
	for zombie in game.zombies:
		before.append(float(zombie["health"]))
	game._update_plants(0.1)
	var passed := true
	for zombie_index in range(3):
		passed = _assert_true(float(game.zombies[zombie_index]["health"]) < before[zombie_index], "frost_fan should damage each covered lane") and passed
		passed = _assert_true(float(game.zombies[zombie_index].get("slow_timer", 0.0)) > 0.0, "frost_fan should slow each covered lane") and passed
	_free_game(game)
	return passed


func _test_mist_orchid_fires_for_any_zombie_ahead() -> bool:
	if not _assert_true(Defs.PLANTS.has("mist_orchid"), "expected mist_orchid plant definition to exist"):
		return false
	var game = _make_game()
	game.current_level = {"id": "4-test", "terrain": "fog", "events": []}
	var row := 2
	var col := 2
	var plant = game._create_plant("mist_orchid", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, game._cell_center(row, 7).x)
	game._update_plants(0.12)
	var passed = _assert_true(not game.projectiles.is_empty(), "mist_orchid should fire when a zombie exists ahead in its lane")
	_free_game(game)
	return passed


func _test_storm_reed_hits_midfield_intruders() -> bool:
	if not _assert_true(Defs.PLANTS.has("storm_reed"), "expected storm_reed plant definition to exist"):
		return false
	var game = _make_game()
	game.current_level = {"id": "4-test", "terrain": "fog", "events": []}
	var row := 2
	var col := 1
	var plant = game._create_plant("storm_reed", row, col)
	plant["support_timer"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("tornado_zombie", row, game._cell_center(row, 6).x)
	var before = float(game.zombies[0]["health"])
	game._update_plants(0.12)
	var passed = _assert_true(float(game.zombies[0]["health"]) < before, "storm_reed should immediately strike zombies that enter the right-side trigger zone") \
		and _assert_true(not game.effects.is_empty(), "storm_reed should emit a visible strike effect when it fires")
	_free_game(game)
	return passed
