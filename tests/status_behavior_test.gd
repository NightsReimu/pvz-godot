extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


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
	failed = not _test_excavator_push_updates_support_plant_motion() or failed
	failed = not _test_kite_zombie_releases_a_conductive_kite_on_death() or failed
	failed = not _test_hive_zombie_summons_bees_when_bloodied() or failed
	failed = not _test_turret_zombie_launches_reinforcement_into_midfield() or failed
	failed = not _test_programmer_zombie_stacks_global_attack_slow() or failed
	failed = not _test_signal_ivy_blocks_programmer_attack_slow_for_nearby_plants() or failed
	failed = not _test_origami_blossom_launches_varied_magic_projectiles() or failed
	failed = not _test_tesla_tulip_chain_damage_scales_with_more_targets() or failed
	failed = not _test_roof_vane_continuous_wind_hits_front_arc() or failed
	failed = not _test_tornado_zombie_finishes_entry_and_slows_down() or failed
	failed = not _test_ice_shroom_permanently_slows_current_zombies() or failed
	failed = not _test_wake_support_plants_ignore_sleep_effects() or failed
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
	game.projectiles = []
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


func _test_excavator_push_updates_support_plant_motion() -> bool:
	var game = _make_game()
	var row := 2
	game.support_grid[row][3] = game._create_plant("lily_pad", row, 3)
	var moved = game._push_plant_chain_left(row, 3)
	var passed = _assert_true(moved, "expected support plant push setup to move the lily pad left")
	if passed:
		game._update_plants(0.3)
		var support = game.support_grid[row][2]
		var support_center = game._cell_center(row, 2) + Vector2(0.0, 16.0)
		var motion = game._plant_draw_motion(support, support_center)
		passed = _assert_true(float(support.get("push_timer", 0.0)) <= 0.0, "support plants should finish their push timer after plant updates") and passed
		passed = _assert_true(absf(Vector2(motion["center"]).x - support_center.x) < 0.5, "support plants should stop rendering at the old tile after the push animation finishes") and passed
	_free_game(game)
	return passed


func _test_kite_zombie_releases_a_conductive_kite_on_death() -> bool:
	var game = _make_game()
	var row := 2
	game.grid[row][1] = game._create_plant("peashooter", row, 1)
	game._spawn_zombie_at("kite_zombie", row, game._cell_center(row, 6).x)
	var kite = game.zombies[0]
	kite["health"] = 0.0
	game.zombies[0] = kite
	game._cleanup_dead_zombies()
	var detached_index := -1
	for i in range(game.zombies.size()):
		if String(game.zombies[i].get("kind", "")) == "kite_trap":
			detached_index = i
			break
	var passed = _assert_true(detached_index != -1, "kite zombie should release a detached kite after it dies") \
		and _assert_true(game.grid[row][1] != null, "kite release test should keep the attached target plant alive initially")
	if passed:
		var detached = game.zombies[detached_index]
		passed = _assert_true(bool(detached.get("balloon_flying", false)), "detached kite should behave like an airborne target") and passed
		passed = _assert_true(int(detached.get("kite_target_row", -1)) == row and int(detached.get("kite_target_col", -1)) == 1, "detached kite should bind to a plant in the left four columns") and passed
		var plant_before = float(game.grid[row][1].get("health", 0.0))
		game._strike_thunder_chain(detached_index, 30.0, 0.0, 0.0, 1)
		var plant_after = float(game.grid[row][1].get("health", 0.0))
		passed = _assert_true(plant_after < plant_before, "lightning striking the kite should conduct damage into the attached plant") and passed
	_free_game(game)
	return passed


func _test_hive_zombie_summons_bees_when_bloodied() -> bool:
	var game = _make_game()
	var row := 2
	game._spawn_zombie_at("hive_zombie", row, game._cell_center(row, 6).x)
	var hive = game.zombies[0]
	hive["health"] = float(hive.get("max_health", 0.0)) * 0.48
	hive["special_pause_timer"] = 0.0
	game.zombies[0] = hive
	game._update_zombies(0.2)
	var bee_count := 0
	var rows_ok := true
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) != "bee_minion":
			continue
		bee_count += 1
		if abs(int(zombie.get("row", row)) - row) > 1:
			rows_ok = false
	var passed = _assert_true(bee_count >= 3, "hive zombie should summon multiple bees after dropping below half health") \
		and _assert_true(rows_ok, "summoned bees should stay within the nearby three rows")
	_free_game(game)
	return passed


func _test_turret_zombie_launches_reinforcement_into_midfield() -> bool:
	var game = _make_game()
	var row := 2
	game._spawn_zombie_at("turret_zombie", row, game._cell_center(row, 8).x)
	var turret = game.zombies[0]
	turret["special_pause_timer"] = 0.0
	turret["launch_cooldown"] = 0.0
	game.zombies[0] = turret
	game._update_zombies(0.2)
	var launched_index := -1
	for i in range(game.zombies.size()):
		if i == 0:
			continue
		if String(game.zombies[i].get("kind", "")) == "normal":
			launched_index = i
			break
	var passed = _assert_true(launched_index != -1, "turret zombie should launch a reinforcement zombie when its cooldown expires")
	if passed:
		var launched = game.zombies[launched_index]
		var launched_col = game._zombie_cell_col(float(launched.get("x", 0.0)))
		passed = _assert_true(launched_col >= 4 and launched_col <= 6, "turret reinforcements should land in columns 4 through 6") and passed
		passed = _assert_true(float(launched.get("health", 0.0)) > float(Defs.ZOMBIES["conehead"].get("health", 370.0)), "turret reinforcements should be tougher than a conehead") and passed
	_free_game(game)
	return passed


func _test_programmer_zombie_stacks_global_attack_slow() -> bool:
	var game = _make_game()
	var base_scale = game._plant_attack_cadence_scale(2, 3)
	game._spawn_zombie_at("programmer_zombie", 1, game._cell_center(1, 7).x)
	var one_scale = game._plant_attack_cadence_scale(2, 3)
	game._spawn_zombie_at("programmer_zombie", 3, game._cell_center(3, 7).x)
	var two_scale = game._plant_attack_cadence_scale(2, 3)
	var passed = _assert_true(is_equal_approx(base_scale, 1.0), "plant cadence should start at the default scale in an unfrozen lane") \
		and _assert_true(is_equal_approx(one_scale, 2.0), "one programmer zombie should halve plant attack speed globally") \
		and _assert_true(is_equal_approx(two_scale, 4.0), "multiple programmer zombies should stack their plant attack slow")
	_free_game(game)
	return passed


func _test_signal_ivy_blocks_programmer_attack_slow_for_nearby_plants() -> bool:
	var game = _make_game()
	game.current_level = {"id": "5-test", "terrain": "roof", "events": []}
	var row := 2
	var col := 2
	game.grid[row][col] = game._create_plant("signal_ivy", row, col)
	game._spawn_zombie_at("programmer_zombie", 1, game._cell_center(1, 7).x)
	var protected_scale = game._plant_attack_cadence_scale(row, col + 1)
	var unprotected_scale = game._plant_attack_cadence_scale(row, col + 4)
	var passed = _assert_true(is_equal_approx(protected_scale, 1.0), "signal_ivy should shield nearby plants from programmer_zombie attack-speed debuffs") \
		and _assert_true(is_equal_approx(unprotected_scale, 2.0), "signal_ivy should not remove programmer_zombie attack-speed debuffs from faraway plants")
	_free_game(game)
	return passed


func _test_origami_blossom_launches_varied_magic_projectiles() -> bool:
	var game = _make_game()
	game.current_level = {"id": "5-test", "terrain": "roof", "events": []}
	game.rng.seed = 13579
	var row := 2
	var col := 2
	game.grid[row][col] = game._create_plant("origami_blossom", row, col)
	game.grid[row][col]["shot_cooldown"] = 0.0
	game._spawn_zombie_at("buckethead", row, game._cell_center(row, 6).x)
	var projectile_kinds := {}
	for _step in range(4):
		var before_count = game.projectiles.size()
		game._update_plants(1.05)
		for projectile_index in range(before_count, game.projectiles.size()):
			projectile_kinds[String(game.projectiles[projectile_index].get("kind", ""))] = true
		game._update_projectiles(0.08)
	var passed = _assert_true(String(Defs.PLANTS["origami_blossom"].get("name", "")) == "魔术花", "origami_blossom should expose its new display name 魔术花") \
		and _assert_true(is_equal_approx(float(Defs.PLANTS["origami_blossom"].get("shoot_interval", 0.0)), 1.0), "origami_blossom should now attack once every second") \
		and _assert_true(projectile_kinds.size() >= 3, "origami_blossom should cycle through multiple existing projectile types instead of always firing the same paper plane")
	_free_game(game)
	return passed


func _test_tesla_tulip_chain_damage_scales_with_more_targets() -> bool:
	var two_game = _make_game()
	two_game.current_level = {"id": "5-test", "terrain": "roof", "events": []}
	var row := 2
	var col := 2
	two_game.grid[row][col] = two_game._create_plant("tesla_tulip", row, col)
	two_game.grid[row][col]["attack_timer"] = 0.0
	two_game._spawn_zombie_at("normal", row, two_game._cell_center(row, 5).x)
	two_game._spawn_zombie_at("normal", row, two_game._cell_center(row, 5).x + 54.0)
	two_game._update_plants(0.2)
	var two_chain_damage = float(two_game.zombies[0].get("max_health", 0.0)) - float(two_game.zombies[0].get("health", 0.0))
	_free_game(two_game)

	var game = _make_game()
	game.current_level = {"id": "5-test", "terrain": "roof", "events": []}
	game.grid[row][col] = game._create_plant("tesla_tulip", row, col)
	game.grid[row][col]["attack_timer"] = 0.0
	game._spawn_zombie_at("normal", row, game._cell_center(row, 5).x)
	game._spawn_zombie_at("normal", row, game._cell_center(row, 5).x + 54.0)
	game._spawn_zombie_at("normal", row, game._cell_center(row, 6).x + 16.0)
	game._update_plants(0.2)
	var three_chain_damage = float(game.zombies[0].get("max_health", 0.0)) - float(game.zombies[0].get("health", 0.0))
	var passed = _assert_true(float(game.zombies[2].get("health", 0.0)) < float(game.zombies[2].get("max_health", 1.0)), "tesla_tulip should be able to chain into a third nearby target") \
		and _assert_true(three_chain_damage > two_chain_damage, "tesla_tulip should deal more damage when its lightning chains through more zombies") \
		and _assert_true(game.effects.any(func(effect): return String(effect.get("shape", "")) == "tesla_chain_arc"), "tesla_tulip should emit dedicated tesla_chain_arc effects instead of only the shared storm arc")
	_free_game(game)
	return passed


func _test_roof_vane_continuous_wind_hits_front_arc() -> bool:
	var game = _make_game()
	game.current_level = {"id": "5-test", "terrain": "roof", "events": []}
	var row := 2
	var col := 2
	game.grid[row][col] = game._create_plant("roof_vane", row, col)
	game.grid[row][col]["gust_timer"] = 0.0
	game._spawn_zombie_at("normal", row, game._cell_center(row, 4).x)
	game._spawn_zombie_at("normal", row, game._cell_center(row, 1).x)
	var front_before_x = float(game.zombies[0].get("x", 0.0))
	var front_before_health = float(game.zombies[0].get("health", 0.0))
	var rear_before_x = float(game.zombies[1].get("x", 0.0))
	game._update_plants(0.22)
	var front_after = game.zombies[0]
	var rear_after = game.zombies[1]
	var passed = _assert_true(float(front_after.get("x", 0.0)) > front_before_x, "roof_vane should continuously push enemies inside its forward wind arc") \
		and _assert_true(float(front_after.get("health", 0.0)) < front_before_health, "roof_vane should also damage enemies caught in its wind arc") \
		and _assert_true(is_equal_approx(float(rear_after.get("x", 0.0)), rear_before_x), "roof_vane should not hit zombies behind the plant") \
		and _assert_true(game.effects.any(func(effect): return String(effect.get("shape", "")) == "roof_vane_ring"), "roof_vane should use a dedicated circular wind effect instead of the old shared lane spray")
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


func _test_ice_shroom_permanently_slows_current_zombies() -> bool:
	var game = _make_game()
	game._spawn_zombie_at("normal", 1, game._cell_center(1, 4).x)
	game._spawn_zombie_at("conehead", 3, game._cell_center(3, 6).x)
	game._trigger_ice_shroom(2, 2, false)
	var passed := true
	for zombie in game.zombies:
		passed = _assert_true(float(zombie.get("slow_timer", 0.0)) >= 9999.0, "ice_shroom should permanently slow every zombie currently on the field") and passed
	_free_game(game)
	return passed


func _test_wake_support_plants_ignore_sleep_effects() -> bool:
	var game = _make_game()
	var row := 2
	game.grid[row][2] = game._create_plant("moon_lotus", row, 2)
	game.grid[row][3] = game._create_plant("dream_drum", row, 3)
	game.grid[row][4] = game._create_plant("puff_shroom", row, 4)
	var slept = int(game.call("_sleep_plants_in_radius", game._cell_center(row, 3), 180.0, 5.0))
	var moon_lotus = game.grid[row][2]
	var dream_drum = game.grid[row][3]
	var puff = game.grid[row][4]
	var passed = _assert_true(slept > 0, "sleep test setup should still affect at least one nearby plant") \
		and _assert_true(float(moon_lotus.get("sleep_timer", 0.0)) <= 0.0, "wake-support plants like moon_lotus should not be put to sleep") \
		and _assert_true(float(dream_drum.get("sleep_timer", 0.0)) <= 0.0, "wake-support plants like dream_drum should not be put to sleep") \
		and _assert_true(float(puff.get("sleep_timer", 0.0)) > 0.0, "non-wake plants should still be affected by sleep")
	_free_game(game)
	return passed
