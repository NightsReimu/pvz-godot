extends "res://tests/volcano_world_test.gd"

const Expansion = preload("res://scripts/runtime/volcano_expansion_runtime.gd")


func _run() -> void:
	var failures := 0
	for test in [
		_test_expansion_progression, _test_cast_healing, _test_new_plant_attacks,
		_test_geothermal_and_cooling, _test_sulfur_and_ground_echo,
		_test_steam_cloud, _test_pressure_storage_and_counter,
		_test_magnet_recovery, _test_basalt_and_runner, _test_kiln_armor,
		_test_warning_interruptions, _test_shards_and_tunneling,
		_test_final_boss_and_pause, _test_charm_and_sleep, _test_rewards_save_and_restart,
	]:
		var passed = bool(test.call())
		print("%s: %s" % [test.get_method(), "PASS" if passed else "FAIL"])
		failures += 0 if passed else 1
	print("Volcano expansion: %d failure(s)" % failures)
	quit(1 if failures else 0)


func _plant(game: Control, kind: String, row: int = 2, col: int = 2) -> Dictionary:
	game.support_grid[row][col] = game._create_plant("flower_pot", row, col)
	game.grid[row][col] = game._create_plant(kind, row, col)
	return game.grid[row][col]


func _enemy(game: Control, kind: String = "normal", row: int = 2, col: int = 6) -> Dictionary:
	game._spawn_zombie_at(kind, row, game._cell_center(row, col).x, true)
	return game.zombies.back()


func _vents(game: Control) -> void:
	game.current_level["lava_cells"] = [Vector2i(2, 4), Vector2i(3, 6)]
	game._apply_lava_cells()


func _has_action(game: Control, action: String) -> bool:
	for effect in game.effects:
		if String(effect.get("action", "")) == action:
			return true
	return false


func _test_expansion_progression() -> bool:
	var game = _make_game()
	var passed = _test_volcano_level_data_matches_unlock_rhythm()
	var encountered := {}
	game.completed_levels.resize(Defs.LEVELS.size())
	game.completed_levels.fill(false)
	for i in range(10):
		var index = _find_level_index("7-%d" % (11 + i))
		var level = Defs.LEVELS[index]
		var reward: String = Expansion.PLANTS[i]
		passed = _assert_true(level.unlock_plant == reward, "each new level must have its own plant reward") and passed
		passed = _assert_true(Defs.PLANT_ORDER.has(reward) and Defs.PLANTS[reward].almanac.size() == 2, "reward must be visible in the collection and almanac") and passed
		if i < 9:
			passed = _assert_true(Defs.LEVELS[index + 1].available_plants.has(reward), "next stage must offer the earned plant") and passed
		for event in level.events:
			passed = _assert_true(Defs.ZOMBIES.has(event.kind), "wave enemy must exist") and passed
			encountered[event.kind] = true
		game.completed_levels[index] = true
	var finale = Defs.LEVELS[_find_level_index("7-20")]
	passed = _assert_true(finale.boss_kind == "volcano_boss" and finale.boss_level and finale.mode == "conveyor", "7-20 must be a conventional volcano boss fight") and passed
	for kind in Expansion.ZOMBIES:
		passed = _assert_true(encountered.has(kind) and game.ZOMBIE_ALMANAC_ORDER.has(kind), "all seven new enemies must appear in battle and the almanac") and passed
	for kind in Expansion.PLANTS:
		passed = _assert_true(game._player_plant_collection().has(kind), "completed stage must persist its plant reward, including 7-20") and passed
	_free_game(game)
	return passed


func _test_cast_healing() -> bool:
	var passed := true
	for kind in ["wallnut", "peashooter", "cabbage_pult", "thermal_sunflower", "pumice_wall"]:
		var game = _make_game()
		var p = _plant(game, kind)
		var neighbor = _plant(game, "sunflower", 1, 2)
		neighbor.health = 10.0
		p.health = 1.0
		p.ultimate_charge = 1.0
		passed = _assert_true(game._try_activate_ultimate(2, 2) and is_equal_approx(p.health, p.max_health), "click ultimate must restore %s to its enhanced max HP" % kind) and passed
		passed = _assert_true(neighbor.health == 10.0, "ultimate must heal the caster only") and passed
		p.health = 5.0
		passed = _assert_true(not game._try_activate_ultimate(2, 2) and p.health == 5.0, "rejected cooldown cast must not heal") and passed
		p.plant_food_mode = ""
		p.plant_food_timer = 0.0
		passed = _assert_true(game._activate_plant_food(2, 2) and is_equal_approx(p.health, p.max_health), "plant food must also restore %s" % kind) and passed
		p.health = 0.0
		p.ultimate_charge = 1.0
		p.ultimate_cooldown = 0.0
		passed = _assert_true(not game._try_activate_ultimate(2, 2) and not game._activate_plant_food(2, 2) and p.health == 0.0, "dead plants must not revive") and passed
		_free_game(game)
	var game = _make_game()
	var bomb = _plant(game, "cherry_bomb")
	game._activate_plant_food(2, 2)
	game._update_plants(2.0)
	passed = _assert_true(float(bomb.health) <= 0.0 or game.grid[2][2] == null, "consumed instant plants must remain consumed") and passed
	_free_game(game)
	return passed


func _test_new_plant_attacks() -> bool:
	var passed := true
	for kind in ["obsidian_artichoke", "sulfur_pod", "resonance_beet", "pressure_bamboo", "fumarole_melon", "caldera_lotus"]:
		var game = _make_game()
		var p = _plant(game, kind)
		var z = _enemy(game, "buckethead")
		p.geothermal_timer = 0.0
		var before = float(z.health) + float(z.shield_health)
		game._update_plants(0.1)
		passed = _assert_true(not game.projectiles.is_empty(), "%s must launch a visible projectile from the real update loop" % kind) and passed
		game._update_projectiles(0.6)
		passed = _assert_true(float(z.health) + float(z.shield_health) < before, "%s projectile must actually damage its target" % kind) and passed
		p.ultimate_charge = 1.0
		passed = _assert_true(game._try_activate_ultimate(2, 2), "%s must have a usable ultimate" % kind) and passed
		game._update_projectiles(1.2)
		game._update_effects(0.7)
		_free_game(game)
	return passed


func _test_geothermal_and_cooling() -> bool:
	var game = _make_game()
	_vents(game)
	var sunflower = _plant(game, "thermal_sunflower", 2, 3)
	var volcano = game._ensure_volcano_expansion()
	for i in range(5):
		volcano.on_eruption(2, 4)
	var passed = _assert_true(sunflower.geothermal_charge == 3, "geothermal charge must be bounded")
	sunflower.geothermal_timer = 0.0
	game._update_plants(0.1)
	passed = _assert_true(game.suns.size() == 1 and int(game.suns[0].value) == 100 and sunflower.geothermal_charge == 0, "three stored heat charges must yield 100 sun exactly once") and passed
	var clover = _plant(game, "steam_clover", 1, 3)
	clover.geothermal_timer = 0.0
	game._update_plants(0.1)
	passed = _assert_true(volcano.is_cooled(Vector2i(2, 4)) and game._cell_terrain_kind(2, 4) == "lava", "clover must cool without replacing terrain") and passed
	var health = sunflower.health
	game.lava_eruption_timers["2,4"] = 0.01
	game._update_lava_cells(0.1)
	passed = _assert_true(sunflower.health == health, "cooled vents must not erupt") and passed
	game._seal_lava_cell(2, 4)
	game.level_time += 15.0
	volcano.update_world(0.1)
	passed = _assert_true(game._cell_terrain_kind(2, 4) == "volcano_tile", "cooldown expiry must never undo cork sealing") and passed
	game.lava_eruption_timers["3,6"] = 1.0
	game._update_lava_cells(0.1)
	passed = _assert_true(_has_action(game, "vent_cue"), "active vents must warn before erupting") and passed
	volcano.reset()
	passed = _assert_true(volcano.cooling.is_empty() and volcano.warned.is_empty() and volcano.heat_until == 0.0, "new battles must not inherit heat or cooling") and passed
	_free_game(game)
	return passed


func _test_sulfur_and_ground_echo() -> bool:
	var game = _make_game()
	var z = _enemy(game, "buckethead")
	var volcano = game._ensure_volcano_expansion()
	var center = Vector2(z.x, game._row_center_y(2) - 10)
	volcano.impact({"volcano_seed": "sulfur_pod", "damage": 28.0}, center)
	var before = float(z.shield_health)
	game._apply_zombie_damage(z, 100)
	var passed = _assert_true(is_equal_approx(before - float(z.shield_health), 120), "sulfur must amplify follow-up damage by 20 percent")
	game.level_time = 5.0
	before = float(z.shield_health)
	game._apply_zombie_damage(z, 10)
	passed = _assert_true(is_equal_approx(before - float(z.shield_health), 10), "sulfur must expire") and passed
	var balloon = _enemy(game, "balloon_zombie")
	balloon.balloon_flying = true
	var flying_hp = balloon.health
	before = float(z.health) + float(z.shield_health)
	volcano.impact({"volcano_seed": "resonance_beet", "damage": 30.0}, center)
	game._update_effects(0.7)
	passed = _assert_true(is_equal_approx(before - float(z.health) - float(z.shield_health), 60), "echo must strike exactly twice") and passed
	passed = _assert_true(balloon.health == flying_hp, "ground resonance must not hit flying enemies") and passed
	_free_game(game)
	return passed


func _test_steam_cloud() -> bool:
	var game = _make_game()
	var z = _enemy(game, "buckethead")
	var before = float(z.health) + float(z.shield_health)
	game._ensure_volcano_expansion().impact({"volcano_seed": "fumarole_melon", "damage": 40.0}, Vector2(z.x, game._row_center_y(2) - 10))
	game._update_effects(0.5)
	game._update_effects(3.0)
	var passed = _assert_true(is_equal_approx(before - float(z.health) - float(z.shield_health), 76), "steam must apply impact plus exactly three seconds of damage, including final partial tick")
	passed = _assert_true(z.slow_timer > 0.0 and _count_effect_shape(game, "volcano_steam") == 0, "steam must slow and then expire") and passed
	_free_game(game)
	return passed


func _test_pressure_storage_and_counter() -> bool:
	var game = _make_game()
	var p = _plant(game, "pressure_bamboo")
	for i in range(5):
		game._update_plants(1.8)
	var passed = _assert_true(p.pressure_ammo == 3 and game.projectiles.is_empty(), "idle bamboo must store at most three rounds")
	_enemy(game)
	game._update_plants(1.8)
	passed = _assert_true(game.projectiles.size() == 3 and p.pressure_ammo == 0, "stored ammo must release as a three-shot burst") and passed
	var wall = _plant(game, "pumice_wall", 1, 2)
	wall.health -= 300.0
	wall.geothermal_timer = 0.0
	game._update_plants(0.1)
	passed = _assert_true(wall.pumice_pressure == 90, "wall must retain pressure until an enemy is close") and passed
	var z = _enemy(game, "buckethead", 1, 3)
	var before = z.shield_health
	game._update_plants(0.2)
	passed = _assert_true(wall.pumice_pressure == 0 and z.shield_health < before, "close enemy must trigger stored pressure counter") and passed
	_free_game(game)
	return passed


func _test_magnet_recovery() -> bool:
	var game = _make_game()
	var orchid = _plant(game, "magnet_orchid")
	var wall = _plant(game, "wallnut", 2, 3)
	orchid.armor_health = 240.0
	var z = _enemy(game, "buckethead")
	var before = z.shield_health
	orchid.geothermal_timer = 0.0
	game._update_plants(0.1)
	var passed = _assert_true(is_equal_approx(before - float(z.shield_health), 70) and wall.armor_health == 70, "orchid must convert shield into neighboring armor")
	for i in range(5):
		game._ensure_volcano_expansion().reclaim(2, 2, 1, 70)
	passed = _assert_true(wall.armor_health <= 240 and z.shield_health >= 0, "recovery must respect armor and shield bounds") and passed
	var neighbor = _plant(game, "cabbage_pult", 3, 3)
	_enemy(game, "buckethead", 3, 6)
	orchid.ultimate_charge = 1.0
	game._try_activate_ultimate(2, 2)
	passed = _assert_true(neighbor.armor_health == 240 and game.support_grid[3][3].armor_health == 0, "ultimate recovery must reinforce living plants without wasting armor on their flower pots") and passed
	_free_game(game)
	return passed


func _test_basalt_and_runner() -> bool:
	var game = _make_game()
	_vents(game)
	var z = _enemy(game, "basalt_guard")
	z.volcano_ability_timer = 0.0
	game._update_zombies(0.1)
	var before = z.shield_health
	game._apply_zombie_damage(z, 100)
	var passed = _assert_true(is_equal_approx(before - float(z.shield_health), 65) and game._current_zombie_speed(z) == 0, "basalt brace must reduce damage and stop walking")
	z.slow_timer = 1.0
	before = z.shield_health
	game._apply_zombie_damage(z, 100)
	passed = _assert_true(is_equal_approx(before - float(z.shield_health), 100), "slow must break the brace") and passed
	var runner = _enemy(game, "cinder_runner", 2, 5)
	passed = _assert_true(game._current_zombie_speed(runner) > runner.base_speed, "runner must sprint beside a hot vent") and passed
	game._ensure_volcano_expansion().cool(Vector2i(2, 4), 0, 10)
	passed = _assert_true(is_equal_approx(game._current_zombie_speed(runner), runner.base_speed), "local cooling must stop sprinting") and passed
	_free_game(game)
	return passed


func _test_kiln_armor() -> bool:
	var game = _make_game()
	var mason = _enemy(game, "kiln_mason")
	var ally = _enemy(game, "conehead", 2, 5)
	var foe = _enemy(game, "normal", 2, 5)
	foe.hypnotized = true
	var original = ally.shield_health
	var volcano = game._ensure_volcano_expansion()
	for i in range(4):
		mason.volcano_ability_timer = 0.0
		volcano.update_zombie(mason, 0.1)
	var passed = _assert_true(ally.shield_health == original + 180.0 and foe.shield_health == 0.0, "mason must cap temporary armor and respect allegiance")
	game._apply_zombie_damage(ally, 70)
	game.level_time = 9.0
	foe.row = 4
	mason.volcano_ability_timer = 100.0
	game._update_zombies(0.1)
	passed = _assert_true(is_equal_approx(ally.shield_health, original), "expiry removes only unspent temporary armor, preserving original shield") and passed
	_free_game(game)
	return passed


func _test_warning_interruptions() -> bool:
	var passed := true
	for interruption in ["none", "slow", "death", "charm", "holy"]:
		var game = _make_game()
		var p = _plant(game, "wallnut", 2, 4)
		var z = _enemy(game, "ash_bell", 2, 5)
		z.volcano_ability_timer = 0.0
		game._update_zombies(0.1)
		passed = _assert_true(_has_action(game, "ash") and p.sleep_timer == 0.0, "ash bell must warn before disabling a plant") and passed
		match interruption:
			"slow": z.slow_timer = 2.0
			"death": z.health = 0.0
			"charm": z.hypnotized = true
			"holy": p.holy_invincible_timer = 2.0
		game._update_effects(1.2)
		passed = _assert_true((p.sleep_timer > 0.0) == (interruption == "none"), "ash warning must respect %s interruption" % interruption) and passed
		_free_game(game)
	var game = _make_game()
	var wall = _plant(game, "wallnut", 2, 5)
	var carrier = _enemy(game, "sulfur_carrier", 2, 5)
	carrier.health *= 0.4
	carrier.volcano_ability_timer = 0.0
	game._update_zombies(0.1)
	var health = wall.health
	carrier.slow_timer = 0.2
	game._update_effects(0.1)
	carrier.slow_timer = 0.0
	game._update_effects(2.0)
	passed = _assert_true(wall.health == health, "brief control during windup must permanently cancel the one-use sulfur blast") and passed
	_free_game(game)
	return passed


func _test_shards_and_tunneling() -> bool:
	var game = _make_game()
	_vents(game)
	var crystal = _enemy(game, "geode_zombie", 2, 6)
	var p = _plant(game, "wallnut", 2, 5)
	crystal.shield_health = 0.0
	game._update_zombies(0.1)
	var before = p.health
	game._update_effects(1.1)
	var passed = _assert_true(crystal.geode_broken and crystal.base_speed > Defs.ZOMBIES.geode_zombie.speed and p.health < before, "broken geode must launch delayed shards and accelerate")
	var tunnel = _enemy(game, "vent_tunneler", 2, 8)
	tunnel.volcano_ability_timer = 0.0
	game._update_zombies(0.1)
	var origin = tunnel.x
	passed = _assert_true(_has_action(game, "tunnel"), "tunneler must show its destination") and passed
	game._ensure_volcano_expansion().cool(Vector2i(2, 4), 0, 5)
	game._update_effects(1.5)
	passed = _assert_true(tunnel.x == origin, "cooling the destination must cancel travel") and passed
	tunnel = _enemy(game, "vent_tunneler", 2, 8)
	tunnel.volcano_ability_timer = 0.0
	game._update_zombies(0.1)
	game._update_effects(1.5)
	passed = _assert_true(tunnel.row == 3 and tunnel.x >= game._cell_center(3, 4).x, "successful travel must remain in the right half of the board") and passed
	_free_game(game)
	return passed


func _test_final_boss_and_pause() -> bool:
	var game = _make_game()
	game.current_level = Defs.LEVELS[_find_level_index("7-20")].duplicate(true)
	game._setup_cell_terrain_mask()
	var p = _plant(game, "wallnut", 2, 3)
	var boss = _enemy(game, "volcano_boss", 2, 8)
	boss.boss_skill_cycle = 0
	game._trigger_boss_skill(boss)
	var before = p.health
	var passed = _assert_true(_has_action(game, "meteor") and p.health == before, "final boss meteors must be telegraphed")
	game.boss_time_stop_timer = 1.0
	game._update_effects(2.0)
	passed = _assert_true(p.health == before and _has_action(game, "meteor"), "time stop must pause delayed volcano attacks") and passed
	game.boss_time_stop_timer = 0.0
	game._update_effects(1.7)
	passed = _assert_true(p.health < before, "meteor must resolve after time resumes") and passed
	boss.boss_skill_cycle = 1
	game._trigger_boss_skill(boss)
	passed = _assert_true(_has_action(game, "eruption"), "boss must be able to command vents") and passed
	boss.boss_skill_cycle = 2
	var count = game.zombies.size()
	game._trigger_boss_skill(boss)
	passed = _assert_true(game.zombies.size() >= count + 3, "boss must summon the new volcano guard") and passed
	_free_game(game)
	return passed


func _test_charm_and_sleep() -> bool:
	var game = _make_game()
	var p = _plant(game, "pressure_bamboo")
	_enemy(game)
	p.geothermal_timer = 0.0
	p.youmu_charm_timer = 3.0
	game._update_plants(0.1)
	var passed = _assert_true(game.projectiles.is_empty(), "Youmu charm must block expansion plant attacks")
	p.youmu_charm_timer = 0.0
	p.sleep_timer = 2.0
	game._update_plants(0.1)
	passed = _assert_true(game.projectiles.is_empty(), "sleep must block expansion plant attacks") and passed
	game.boss_time_stop_timer = 1.0
	p.sleep_timer = 0.0
	game._update_plants(0.1)
	passed = _assert_true(game.projectiles.is_empty(), "time stop must block expansion plant attacks") and passed
	game.boss_time_stop_timer = 0.0
	game._set_cell_terrain_kind(2, 2, "frozen")
	p.geothermal_timer = 1.0
	game._update_plants(0.5)
	passed = _assert_true(is_equal_approx(p.geothermal_timer, 1.0 - 0.5 / 1.3), "frozen terrain must slow new plants through the existing attack cadence system") and passed
	_free_game(game)
	return passed


func _test_rewards_save_and_restart() -> bool:
	var game = _make_game()
	var old_count = _find_level_index("7-10") + 1
	var legacy_completed: Array = []
	legacy_completed.resize(old_count)
	legacy_completed.fill(true)
	game._apply_loaded_save_data({"version": 2, "completed_levels": legacy_completed, "unlocked_levels": old_count, "last_level_index": old_count - 1})
	var passed = _assert_true(game._is_level_unlocked(_find_level_index("7-11")) and not game._is_level_unlocked(_find_level_index("7-12")), "old 7-10 completion must unlock precisely the next new stage")
	var final_index = _find_level_index("7-20")
	game.current_level = Defs.LEVELS[final_index].duplicate(true)
	game.selected_level_index = final_index
	game.battle_state = game.BATTLE_PLAYING
	game._win_level()
	passed = _assert_true(game.message_label.text.contains("火山口莲") and game._player_plant_collection().has("caldera_lotus"), "the final stage must grant and show its plant reward without needing a next stage") and passed
	var coins = game.coins_total
	game._win_level()
	passed = _assert_true(game.coins_total == coins, "repeated win callbacks must not duplicate clear rewards") and passed
	var volcano = game._ensure_volcano_expansion()
	volcano.cooling[Vector2i(2, 4)] = 100.0
	volcano.heat_until = 100.0
	game.lava_eruption_timers["2,4"] = 0.01
	game._begin_level(_find_level_index("7-11"), ["sunflower", "cabbage_pult"])
	passed = _assert_true(volcano.cooling.is_empty() and volcano.heat_until == 0 and game.lava_eruption_timers.is_empty(), "restarting a stage must reset volcano timers and temporary cooling") and passed
	game.save_dirty = false
	_free_game(game)
	return passed
