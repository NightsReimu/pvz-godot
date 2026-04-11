extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")

const TEST_ROWS := 6
const TEST_COLS := 9


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_amber_shooter_doubles_damage_against_armored_zombies() or failed
	failed = not _test_amber_shooter_emits_amber_splash_on_hit() or failed
	failed = not _test_vine_lasher_reaches_an_extra_tile() or failed
	failed = not _test_vine_lasher_emits_range_effect() or failed
	failed = not _test_puff_shroom_reaches_an_extra_tile() or failed
	failed = not _test_prism_grass_effect_reaches_configured_range() or failed
	failed = not _test_lane_spray_visual_geometry_stays_at_configured_extent() or failed
	failed = not _test_circle_effect_visual_geometry_stays_at_configured_extent() or failed
	failed = not _test_pulse_bulb_emits_unique_pulse_wave() or failed
	failed = not _test_wind_orchid_effect_reaches_lane_end() or failed
	failed = not _test_pepper_mortar_locks_frontmost_zombie_with_beam() or failed
	failed = not _test_pepper_mortar_plant_food_effect_matches_damage_radius() or failed
	failed = not _test_threepeater_projectiles_follow_three_distinct_lanes() or failed
	failed = not _test_jalapeno_effect_is_a_full_lane_blast() or failed
	failed = not _test_torchwood_fire_pea_splashes_nearby_zombies() or failed
	failed = not _test_boomerang_shooter_fires_for_any_zombie_ahead() or failed
	failed = not _test_boomerang_shooter_does_not_double_hit_armored_targets() or failed
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
	failed = not _test_moon_lotus_produces_two_suns_at_night() or failed
	failed = not _test_fume_shroom_reaches_one_extra_tile() or failed
	failed = not _test_prism_grass_uses_rainbow_beam_and_extra_range() or failed
	failed = not _test_heather_shooter_fires_for_any_enemy_in_lane() or failed
	failed = not _test_meteor_gourd_targets_the_rearmost_enemy() or failed
	failed = not _test_thunder_pine_emits_a_sky_strike_effect() or failed
	failed = not _test_dream_drum_emits_a_unique_wave_effect() or failed
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
	var shape = String(effect.get("shape", "circle"))
	if shape == "lane_spray" or shape == "wind_gust_lane" or shape == "rainbow_beam":
		return position.x + float(effect.get("length", 0.0))
	return position.x + float(effect.get("radius", 0.0))


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	game.free()


func _advance_projectiles(game: Control, steps: int = 18, delta: float = 0.05) -> void:
	for _step in range(steps):
		if game.projectiles.is_empty():
			return
		game._update_projectiles(delta)


func _zombie_effective_health(zombie: Dictionary) -> float:
	return float(zombie.get("health", 0.0)) + float(zombie.get("shield_health", 0.0))


func _effect_log_contains_shape(game: Control, shape_name: String) -> bool:
	for effect_variant in game.effects:
		if String(Dictionary(effect_variant).get("shape", "")) == shape_name:
			return true
	return false


func _amber_shooter_damage_delta(zombie_kind: String) -> float:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	var plant = game._create_plant("amber_shooter", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at(zombie_kind, row, center.x + 132.0)
	var before = _zombie_effective_health(game.zombies[0])
	game._update_plants(0.1)
	_advance_projectiles(game)
	var after = _zombie_effective_health(game.zombies[0])
	_free_game(game)
	return before - after


func _test_amber_shooter_doubles_damage_against_armored_zombies() -> bool:
	var normal_delta = _amber_shooter_damage_delta("normal")
	var bucket_delta = _amber_shooter_damage_delta("buckethead")
	var screen_door_delta = _amber_shooter_damage_delta("screen_door")
	return _assert_true(normal_delta > 0.0, "amber_shooter should damage a normal zombie with a basic shot") \
		and _assert_float_gte(bucket_delta, normal_delta * 1.9, "amber_shooter should deal roughly double damage to buckethead armor targets") \
		and _assert_float_gte(screen_door_delta, normal_delta * 1.9, "amber_shooter should deal roughly double damage to shielded armor targets")


func _test_amber_shooter_emits_amber_splash_on_hit() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	var plant = game._create_plant("amber_shooter", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("buckethead", row, center.x + 128.0)
	game._update_plants(0.1)
	_advance_projectiles(game)
	var passed = _assert_true(_effect_log_contains_shape(game, "amber_splash"), "amber_shooter should emit an amber_splash impact effect when its shot lands")
	_free_game(game)
	return passed


func _test_vine_lasher_reaches_an_extra_tile() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	game._spawn_zombie_at("normal", row, center.x + 292.0)
	var before = float(game.zombies[0].get("health", 0.0))
	var plant = game._create_plant("vine_lasher", row, col)
	plant["attack_timer"] = 0.0
	game._update_vine_lasher(plant, 0.1, row, col)
	var after = float(game.zombies[0].get("health", 0.0))
	var passed = _assert_true(after < before, "vine_lasher should now hit one extra tile farther than before")
	_free_game(game)
	return passed


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


func _test_puff_shroom_reaches_an_extra_tile() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	var plant = game._create_plant("puff_shroom", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, center.x + 322.0)
	var before = float(game.zombies[0].get("health", 0.0))
	game._update_plants(0.1)
	_advance_projectiles(game)
	var after = float(game.zombies[0].get("health", 0.0))
	var passed = _assert_true(after < before, "puff_shroom should now fire one extra tile farther than before")
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
	var passed = _assert_true(String(effect.get("shape", "")) == "wind_gust_lane", "wind_orchid effect should use a dedicated wind_gust_lane effect instead of the shared lane_spray template") \
		and _assert_float_gte(_effect_forward_extent(effect), lane_end_x, "wind_orchid gust effect should visually reach the end of the lane it affects")
	_free_game(game)
	return passed


func _test_pulse_bulb_emits_unique_pulse_wave() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	game._spawn_zombie_at("normal", row, center.x + 64.0)
	var plant = game._create_plant("pulse_bulb", row, col)
	plant["pulse_timer"] = 0.0
	game._update_pulse_bulb(plant, 0.1, row, col)
	if not _assert_true(not game.effects.is_empty(), "pulse_bulb should emit an effect when it pulses"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 1])
	var passed = _assert_true(String(effect.get("shape", "")) == "pulse_bulb_wave", "pulse_bulb should use a dedicated pulse_bulb_wave effect instead of the default circle pulse")
	_free_game(game)
	return passed


func _test_pepper_mortar_locks_frontmost_zombie_with_beam() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var plant = game._create_plant("pepper_mortar", row, col)
	var front_x = game.BOARD_ORIGIN.x + game.board_size.x - 42.0
	var rear_x = front_x - 60.0
	game._spawn_zombie_at("normal", row, rear_x)
	game._spawn_zombie_at("normal", row, front_x)
	plant["attack_timer"] = 0.0
	var rear_before = float(game.zombies[0].get("health", 0.0))
	var front_before = float(game.zombies[1].get("health", 0.0))
	game._update_pepper_mortar(plant, 0.1, row, col)
	if not _assert_true(not game.effects.is_empty(), "pepper_mortar should emit an effect when it attacks"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 1])
	var rear_after = float(game.zombies[0].get("health", 0.0))
	var front_after = float(game.zombies[1].get("health", 0.0))
	var passed = _assert_true(String(effect.get("shape", "")) == "pepper_beam", "pepper_mortar should emit a dedicated pepper_beam effect instead of its old splash pulse") \
		and _assert_float_eq(Vector2(effect.get("target", Vector2.ZERO)).x, front_x, "pepper_mortar beam should visually end at the frontmost zombie") \
		and _assert_true(front_after < front_before, "pepper_mortar should damage the frontmost zombie in the lane") \
		and _assert_float_eq(rear_after, rear_before, "pepper_mortar should stop splashing the zombie behind the frontmost target")
	_free_game(game)
	return passed


func _test_pepper_mortar_plant_food_effect_matches_damage_radius() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var target_row := 2
	var target_col := 6
	var plant = game._create_plant("pepper_mortar", row, col)
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", target_row, game._cell_center(target_row, target_col).x)
	var activated = game._activate_plant_food(row, col)
	if not _assert_true(activated, "pepper_mortar plant food should activate on a planted mortar"):
		_free_game(game)
		return false
	if not _assert_true(not game.effects.is_empty(), "pepper_mortar plant food should emit magma ground effects"):
		_free_game(game)
		return false
	var patch_count := 0
	var duration_ok := true
	for patch_row in range(target_row - 1, target_row + 2):
		for patch_col in range(target_col - 1, target_col + 2):
			var effect_index := int(game._cell_effect_index("magma_patch", patch_row, patch_col))
			if effect_index == -1:
				continue
			patch_count += 1
			duration_ok = duration_ok and is_equal_approx(float(game.effects[effect_index].get("duration", 0.0)), 12.0)
	var passed = _assert_true(patch_count == 9, "pepper_mortar plant food should paint a 3x3 magma zone around the frontmost target") \
		and _assert_true(duration_ok, "pepper_mortar plant food magma zone should last 12 seconds")
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


func _test_boomerang_shooter_does_not_double_hit_armored_targets() -> bool:
	if not _assert_true(Defs.PLANTS.has("boomerang_shooter"), "expected boomerang_shooter plant definition to exist"):
		return false
	var game = _make_game()
	var row := 2
	var zombie_x = game._cell_center(row, 5).x
	game._spawn_zombie_at("screen_door", row, zombie_x)
	game.zombies[0]["shield_health"] = 8.0
	var shield_before = float(game.zombies[0].get("shield_health", 0.0))
	var health_before = float(game.zombies[0].get("health", 0.0))
	game._spawn_boomerang_projectile(row, Vector2(zombie_x - 8.0, game._row_center_y(row) - 10.0), zombie_x - 140.0, float(Defs.PLANTS["boomerang_shooter"]["damage"]), int(Defs.PLANTS["boomerang_shooter"]["max_targets"]))
	game._update_projectiles(0.05)
	var shield_after = float(game.zombies[0].get("shield_health", 0.0))
	var health_after = float(game.zombies[0].get("health", 0.0))
	var passed = _assert_true(shield_after < shield_before, "boomerang_shooter should still damage armored zombie shields") \
		and _assert_true(is_equal_approx(health_after, health_before), "boomerang_shooter should not spill the same hit from a nearly-broken shield onto the body")
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


func _test_moon_lotus_produces_two_suns_at_night() -> bool:
	var game = _make_game()
	game.current_level = {"id": "2-1", "terrain": "night", "events": []}
	var row := 2
	var col := 2
	var plant = game._create_plant("moon_lotus", row, col)
	plant["sun_timer"] = 0.0
	plant["support_timer"] = 999.0
	game.grid[row][col] = plant
	game._update_plants(0.1)
	var passed = _assert_true(game.suns.size() == 2, "moon_lotus should produce two suns per cycle at night")
	_free_game(game)
	return passed


func _test_fume_shroom_reaches_one_extra_tile() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	var extended_distance = float(Defs.PLANTS["fume_shroom"]["range"]) + game.CELL_SIZE.x - 12.0
	game._spawn_zombie_at("normal", row, center.x + extended_distance)
	var before = float(game.zombies[0].get("health", 0.0))
	var plant = game._create_plant("fume_shroom", row, col)
	plant["attack_timer"] = 0.0
	game._update_fume_shroom(plant, 0.1, row, col)
	if not _assert_true(not game.effects.is_empty(), "fume_shroom should emit an attack effect when it reaches its target"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 1])
	var after = float(game.zombies[0].get("health", 0.0))
	var passed = _assert_true(after < before, "fume_shroom should damage zombies one extra tile farther than before") \
		and _assert_float_gte(_effect_forward_extent(effect), center.x + extended_distance - 4.0, "fume_shroom effect should visually cover its extra tile of range")
	_free_game(game)
	return passed


func _test_prism_grass_uses_rainbow_beam_and_extra_range() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	var extended_distance = float(Defs.PLANTS["prism_grass"]["range"]) + game.CELL_SIZE.x - 10.0
	game._spawn_zombie_at("normal", row, center.x + extended_distance)
	var before = float(game.zombies[0].get("health", 0.0))
	var plant = game._create_plant("prism_grass", row, col)
	plant["attack_timer"] = 0.0
	game._update_prism_grass(plant, 0.1, row, col)
	if not _assert_true(not game.effects.is_empty(), "prism_grass should emit an attack effect when it fires"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 1])
	var after = float(game.zombies[0].get("health", 0.0))
	var passed = _assert_true(String(effect.get("shape", "")) == "rainbow_beam", "prism_grass should use a dedicated rainbow_beam effect instead of the generic lane spray") \
		and _assert_true(after < before, "prism_grass should damage targets one extra tile farther away") \
		and _assert_float_gte(_effect_forward_extent(effect), center.x + extended_distance - 4.0, "prism_grass rainbow beam should visually cover the extra tile of range")
	_free_game(game)
	return passed


func _test_heather_shooter_fires_for_any_enemy_in_lane() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var center = game._cell_center(row, col)
	var far_x = center.x + float(Defs.PLANTS["heather_shooter"]["range"]) + 150.0
	var plant = game._create_plant("heather_shooter", row, col)
	plant["shot_cooldown"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, far_x)
	game._update_plants(0.12)
	var passed = _assert_true(not game.projectiles.is_empty(), "heather_shooter should fire as long as any enemy exists ahead in its lane")
	_free_game(game)
	return passed


func _test_meteor_gourd_targets_the_rearmost_enemy() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var front_row := 1
	var rear_row := 3
	var front_x = game._cell_center(front_row, 7).x
	var rear_x = game._cell_center(rear_row, 2).x
	game._spawn_zombie_at("normal", front_row, front_x)
	game._spawn_zombie_at("normal", rear_row, rear_x)
	var front_before = float(game.zombies[0].get("health", 0.0))
	var rear_before = float(game.zombies[1].get("health", 0.0))
	var plant = game._create_plant("meteor_gourd", row, col)
	plant["attack_timer"] = 0.0
	game._update_meteor_gourd(plant, 0.1, row, col)
	if not _assert_true(not game.effects.is_empty(), "meteor_gourd should emit an impact effect when it fires"):
		_free_game(game)
		return false
	var effect = Dictionary(game.effects[game.effects.size() - 1])
	var front_after = float(game.zombies[0].get("health", 0.0))
	var rear_after = float(game.zombies[1].get("health", 0.0))
	var passed = _assert_float_eq(Vector2(effect.get("position", Vector2.ZERO)).x, rear_x, "meteor_gourd should impact the rearmost zombie position") \
		and _assert_true(rear_after < rear_before, "meteor_gourd should damage the rearmost zombie first") \
		and _assert_float_eq(front_after, front_before, "meteor_gourd should stop prioritizing the frontmost zombie")
	_free_game(game)
	return passed


func _test_thunder_pine_emits_a_sky_strike_effect() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var plant = game._create_plant("thunder_pine", row, col)
	plant["attack_timer"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, game._cell_center(row, 6).x)
	var before = float(game.zombies[0].get("health", 0.0))
	game._update_plants(0.12)
	var after = float(game.zombies[0].get("health", 0.0))
	var passed = _assert_true(after < before, "thunder_pine should still damage its target when striking") \
		and _assert_true(_effect_log_contains_shape(game, "sky_thunder_strike"), "thunder_pine should emit a dedicated sky_thunder_strike effect instead of a generic pulse")
	_free_game(game)
	return passed


func _test_dream_drum_emits_a_unique_wave_effect() -> bool:
	var game = _make_game()
	var row := 2
	var col := 2
	var plant = game._create_plant("dream_drum", row, col)
	plant["support_timer"] = 0.0
	game.grid[row][col] = plant
	game._spawn_zombie_at("normal", row, game._cell_center(row, 3).x)
	game._update_plants(0.12)
	var passed = _assert_true(_effect_log_contains_shape(game, "dream_drum_wave"), "dream_drum should emit its own dream_drum_wave effect instead of a generic circle pulse")
	_free_game(game)
	return passed
