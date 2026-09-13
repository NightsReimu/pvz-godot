extends "res://tests/touhou_encounter_test.gd"

func fixture(choice: String = "easy") -> EncounterGame:
	var game := make_game("eirin_boss")
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.current_level = {"id": "3-24-a", "terrain": "eirin_eternal_corridor", "events": [], "touhou_difficulty": choice}
	game._setup_cell_terrain_mask()
	return game

func _run() -> void:
	var probe := fixture()
	check(probe.has_method("_ensure_eirin_runtime"), "Eirin needs a battlefield runtime")
	release(probe)
	if failures:
		quit(1)
		return
	_test_transition_and_tiles()
	_test_medicine()
	_test_gourd_and_damage()
	_test_roster_and_terrain()
	_test_enemies()
	_test_routes()
	print("Eirin gameplay contracts: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_transition_and_tiles() -> void:
	var game := fixture()
	var rt = game._ensure_eirin_runtime()
	check(rt.hold_finale(), "Finale waits for the corridor exit")
	rt.update(2.9)
	check(rt.hold_finale(), "Finale cannot enter before the three-second transition")
	rt.update(0.2)
	check(not rt.hold_finale() and rt.sky, "Finale enters moon sky after exit")
	var boss: Dictionary = game.zombies[0]
	game.grid[2][2] = game._create_plant("repeater", 2, 2)
	var plant: Dictionary = game.grid[2][2]
	var initial := float(plant.health)
	rt.queue_tile(boss, Vector2i(2, 2), "lava")
	rt.update(1.9)
	check(game._cell_terrain_kind(2, 2) == "land" and plant.health == initial, "Terrain warning is harmless")
	rt.update(0.2)
	check(game._cell_terrain_kind(2, 2) == "lava" and game.grid[2][2] == plant, "Changing terrain preserves planted units")
	rt.update(1.1)
	check(plant.health < initial, "Active lava damages ordinary plants")
	rt.clear_owner(int(boss.uid))
	check(game._cell_terrain_kind(2, 2) == "land", "Owner cleanup restores original terrain")
	release(game)

func _test_medicine() -> void:
	var game := fixture("hard")
	var rt = game._ensure_eirin_runtime()
	var boss: Dictionary = game.zombies[0]
	game.grid[2][2] = game._create_plant("wallnut", 2, 2)
	var p: Dictionary = game.grid[2][2]
	p.health = 10.0
	game._spawn_zombie("normal", 2)
	var z: Dictionary = game.zombies.back()
	var speed := float(game._current_zombie_speed(z))
	var bite := float(game._zombie_attack_dps(z))
	rt.start_medicine(boss, "suppression")
	rt.update(2.1)
	game._restore_plant_health(p, 100.0)
	check(p.health > 10.0 and p.health < 60.0, "Medicine suppresses healing instead of granting immunity")
	game._restore_plant_health(p, 999999.0, true)
	check(p.health == p.max_health, "Ultimate self-heal remains full")
	rt.start_medicine(boss, "rage")
	rt.update(2.1)
	check(game._current_zombie_speed(z) > speed and game._zombie_attack_dps(z) > bite, "Rage affects actual movement and bites")
	for bottle in game.zombies:
		if String(bottle.kind) == "eirin_medicine":
			bottle.health = 0.0
	rt.update(0.1)
	check(game._current_zombie_speed(z) == speed and game._zombie_attack_dps(z) == bite and rt.heal_factor() == 1.0, "Destroying bottles cancels all temporary modifiers")
	release(game)

func _test_enemies() -> void:
	for dt in [0.05, 10.0]:
		var game := fixture()
		game._spawn_zombie("rabbit_airship", 2)
		var ship: Dictionary = game.zombies.back()
		var rt = game._ensure_touhou_enemies()
		for n in range(1500):
			rt.update_unit(ship, dt)
			if ship.health <= 0:
				break
		check(ship.get("airship_departed", false), "Airship must return and exit even with coarse delta")
		check(ship.get("airship_drops", []).size() == 13, "Airship drops at columns 9..3, then 4..9 without repeating turn cell")
		check(not ship.get("balloon_flying", false), "Ground plants can target the airship")
		game._spawn_zombie("kedama", 1)
		var fur: Dictionary = game.zombies.back()
		fur.health = 0
		rt.on_death(fur)
		rt.on_death(fur)
		check(game.zombies.filter(func(z): return String(z.kind) == "mini_kedama").size() == 2, "Kedama splits once, into two bounded children")
		release(game)

func _test_gourd_and_damage() -> void:
	var game := fixture("hard")
	var boss: Dictionary = game.zombies[0]
	var rt = game._ensure_eirin_runtime()
	game.grid[2][2] = game._create_plant("healing_gourd", 2, 2)
	var gourd: Dictionary = game.grid[2][2]
	game.grid[2][3] = game._create_plant("repeater", 2, 3)
	var plant: Dictionary = game.grid[2][3]
	plant.health = 10.0
	rt.start_medicine(boss, "suppression")
	rt.update(2.1)
	gourd.support_timer = 0
	game._ensure_plant_runtime().update_healing_gourd(gourd, 0.1, 2, 2)
	check(is_equal_approx(plant.health, 10 + 65 * 0.25), "Actual gourd passive obeys the medical suppression")
	gourd.health = 10
	gourd.ultimate_charge = 1
	check(game._try_activate_ultimate(2, 2), "Gourd ultimate remains usable under suppression")
	check(gourd.health == gourd.max_health and plant.health < plant.max_health, "Ultimate fully heals its owner; allied healing remains reduced")
	rt.clear_owner(int(boss.uid))
	plant.health = plant.max_health
	var initial := float(plant.health)
	rt.queue_strike(boss, Vector2i(2, 3), 175, "eirin_apollo")
	rt.update(1.79)
	check(plant.health == initial, "Apollo target never damages before its warning")
	rt.update(0.02)
	check(plant.health < initial, "Apollo deals real difficulty-scaled damage")
	game._spawn_zombie_at("rabbit_airship", 4, game._cell_center(4, 4).x, true)
	var ship: Dictionary = game.zombies.back()
	var hp := float(ship.health)
	check(game._has_zombie_ahead(4, game._cell_center(4, 1).x), "A normal ground shooter detects the airship")
	game._spawn_projectile(4, Vector2(ship.x - 30, game._row_center_y(4) - 12), Color.GREEN, 50, 0)
	for frame in range(10):
		game._update_projectiles(0.015)
	check(ship.health < hp, "A real ground pea collides with the airship")
	ship.health = 0
	var total := game.zombies.size()
	game._ensure_touhou_enemies().update_unit(ship, 50)
	check(game.zombies.size() == total, "Destroyed airships stop all future drops")
	release(game)

func _test_roster_and_terrain() -> void:
	var game := fixture()
	var boss: Dictionary = game.zombies[0]
	var rt = game._ensure_eirin_runtime()
	rt.reinforcement_kind()
	for kind in ["snorkel", "dragon_boat", "bobsled_team", "gargantuar", "catapult_zombie", "mech_zombie", "basalt_guard", "star_fairy", "kedama", "rabbit_airship"]:
		check(rt.roster.has(kind), "All-world roster includes " + kind)
		game._spawn_zombie(kind, 1)
		check(String(game.zombies.back().kind) == kind, "Cross-world enemy actually spawns: " + kind)
	game._update_zombies(0.1)
	check(game.zombies.all(func(z): return String(z.kind) != "snorkel" or not z.submerged), "Snorkels cannot stay untargetable on dry corridor cells")
	rt.queue_tile(boss, Vector2i(3, 2), "water")
	rt.queue_tile(boss, Vector2i(4, 2), "roof")
	rt.queue_tile(boss, Vector2i(5, 2), "lava")
	rt.update(2.1)
	check(game._placement_error("repeater", 3, 2) != "" and game._placement_error("lily_pad", 3, 2) == "", "Water requires a lily pad")
	check(game._placement_error("repeater", 4, 2) != "" and game._placement_error("flower_pot", 4, 2) == "", "Roof requires a pot")
	check(game._is_roof_direct_fire_blocked(game._cell_center(4, 2).x, game._cell_center(4, 8).x, 4), "Temporary roof limits long straight fire in its own row")
	check(not game._is_roof_direct_fire_blocked(game._cell_center(2, 2).x, game._cell_center(2, 8).x, 2), "Other lanes retain normal straight fire")
	game.support_grid[5][2] = game._create_plant("cork_plug", 5, 2)
	game._seal_lava_cell(5, 2)
	game.grid[5][2] = game._create_plant("repeater", 5, 2)
	var plant: Dictionary = game.grid[5][2]
	var hp := float(plant.health)
	rt.update(2.0)
	check(plant.health == hp, "Sealing temporary lava actually stops its damage")
	rt.update(8.0)
	check(game._cell_terrain_kind(3, 2) == "land" and game._cell_terrain_kind(5, 2) == "land" and rt.tiles.is_empty(), "All temporary terrain expires and restores normally")
	release(game)

func _test_routes() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := fixture(choice)
		var boss: Dictionary = game.zombies[0]
		Game.TouhouPhaseRuntime.start(boss, game.current_level)
		finish_encounter(game)
		check(boss.touhou_encounter.complete, choice + " Eirin route finishes")
		boss.touhou_final_preview = true
		boss.max_health = 42000.0
		Game.TouhouPhaseRuntime.start(boss, game.current_level)
		check(boss.health == 5040.0 and Spells.card_for(boss, game.current_level).pattern == "eirin_vessel", "Road uses low HP and its canonical vessel spell")
		release(game)
