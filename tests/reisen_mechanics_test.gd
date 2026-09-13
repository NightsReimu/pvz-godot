extends "res://tests/touhou_encounter_test.gd"

func fixture(choice: String = "easy") -> EncounterGame:
	var game := make_game("reisen_boss")
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.current_level = {"id": "3-23", "terrain": "infinite_moon_corridor", "events": [], "touhou_difficulty": choice}
	game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
	game.zombies[0].erase("touhou_encounter")
	return game

func _run() -> void:
	var probe := fixture()
	check(probe.has_method("_ensure_reisen_runtime"), "Reisen must have an active battlefield runtime")
	release(probe)
	if failures:
		quit(1)
		return
	_test_fields()
	_test_damage_pressure()
	_test_portals()
	_test_illusion_collision()
	_test_final_spell_and_return()
	_test_cards_and_routes()
	print("Reisen: canonical routes, harmless illusions, eyes, healing-only gourd, portals and cleanup: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_fields() -> void:
	var game := fixture("hard")
	var boss: Dictionary = game.zombies[0]
	var runtime = game._ensure_reisen_runtime()
	game.grid[2][2] = game._create_plant("repeater", 2, 2)
	game.grid[4][2] = game._create_plant("repeater", 4, 2)
	game.grid[3][1] = game._create_plant("healing_gourd", 3, 1)
	runtime.queue_eye(boss, Vector2i(2, 2), 1.0)
	runtime.queue_eye(boss, Vector2i(4, 2), 1.0)
	runtime.update(0.9)
	check(not game.grid[2][2].get("reisen_dazed", false), "Eye warning must not apply effects early")
	runtime.update(0.2)
	check(game.grid[2][2].get("reisen_dazed", false) and game.grid[4][2].get("reisen_dazed", false), "Healing gourd must not protect a 3x3 area from eye interference")
	game.grid[3][1] = null
	runtime.update(0.1)
	check(game.grid[2][2].get("reisen_dazed", false) and game._plant_attack_cadence_scale(2, 2) > 1, "Eye fields disrupt actual attack cadence")
	game._spawn_projectile(2, game._cell_center(2, 2) + Vector2(20, -12), Color.GREEN, 20, 0)
	check(absf(game.projectiles.back().velocity_y) > 0 and game.projectiles.back().free_aim, "Red-eye confusion deflects friendly fire instead of permanently charming a plant")
	runtime.start_eclipse(boss)
	runtime.update(2.0)
	check(runtime.darkness > 0 and runtime.range_limit(2, game._cell_center(2, 2).x, 10000) < 10000, "Eclipse gradually dims the corridor and limits targeting")
	runtime.clear_owner(int(boss.uid))
	check(runtime.eyes.is_empty() and runtime.eclipse.is_empty() and not game.grid[2][2].has("reisen_dazed"), "Phase/death removes owner fields and plant marks immediately")
	check(runtime.range_limit(2, game._cell_center(2, 2).x, 10000) == 10000, "Eclipse range restores immediately on owner cleanup")
	game.grid[2][2] = game._create_plant("sunflower", 2, 2)
	game.grid[4][2] = game._create_plant("sunflower", 4, 2)
	game.grid[1][1] = game._create_plant("healing_gourd", 1, 1)
	var gourd: Dictionary = game.grid[1][1]
	var exposed_sun: Dictionary = game.grid[4][2]
	gourd.sun_timer = 10.0
	exposed_sun.sun_timer = 10.0
	var initial_health := float(exposed_sun.health)
	runtime.start_eclipse(boss, true)
	runtime.eclipse.cells = [Vector2i(1, 1), Vector2i(4, 2)]
	runtime.update(2.4)
	check(is_equal_approx(gourd.sun_timer, 10.84) and is_equal_approx(exposed_sun.sun_timer, 10.84), "Eclipse slows all sun production, including healing gourd")
	check(gourd.health == gourd.max_health and exposed_sun.health == initial_health, "Moonlight strike cannot damage plants before its 2.5 second warning")
	runtime.update(0.2)
	var damage: float = 110.0 * game.TouhouDifficulty.boss_damage_multiplier(game.current_level)
	check(is_equal_approx(initial_health - exposed_sun.health, damage) and is_equal_approx(gourd.max_health - gourd.health, damage), "Moonlight strike uses difficulty damage without gourd mitigation")
	check(runtime.range_limit(2, game._cell_center(2, 2).x, 10000) < 10000, "Eclipse range affects attackers regardless of healing gourd placement")
	release(game)

func _test_final_spell_and_return() -> void:
	var game := fixture("lunatic")
	var boss: Dictionary = game.zombies[0]
	Game.TouhouPhaseRuntime.start(boss, game.current_level)
	boss.touhou_encounter.index = boss.touhou_encounter.phases.size() - 1
	Game.TouhouPhaseRuntime._set_bounds(boss)
	boss.health = boss.touhou_encounter.ceiling
	game._trigger_boss_skill(boss)
	var hp := float(boss.health)
	game._apply_zombie_damage(boss, 1000000, 0, 0, true)
	check(boss.get("touhou_invulnerable", false) and boss.health == hp, "Reisen Last Spell is a timed survival finale, not a burstable health bar")
	game.touhou_danmaku.update(14.1)
	check(not boss.touhou_invulnerable and boss.touhou_encounter.depleted, "Surviving the original Last Spell completes its segment without further damage")
	game.touhou_danmaku.clear()
	Game.TouhouPhaseRuntime.start(boss, game.current_level)
	boss.touhou_encounter.index = boss.touhou_encounter.phases.size() - 2
	Game.TouhouPhaseRuntime._set_bounds(boss)
	boss.health = boss.touhou_encounter.ceiling
	game._trigger_boss_skill(boss)
	var returned_and_armed := false
	for frame in range(90):
		game.touhou_danmaku.update(0.1)
		returned_and_armed = returned_and_armed or game.touhou_danmaku.bullets.any(func(b): return b.get("reisen_returned", false) and float(b.age) >= float(b.get("arming_time", 0)) and not b.get("reisen_phantom", false))
	check(float(boss.touhou_cast_duration) >= 9 and returned_and_armed, "The live corridor spell gives bullets enough time to teleport, warn, and become harmful again")
	release(game)

func _test_damage_pressure() -> void:
	var game := fixture("hard")
	var boss: Dictionary = game.zombies[0]
	game.grid[2][2] = game._create_plant("wallnut", 2, 2)
	var initial := float(game.grid[2][2].health)
	Game.TouhouPhaseRuntime.start(boss, game.current_level)
	boss.touhou_encounter.index = 3
	Game.TouhouPhaseRuntime._set_bounds(boss)
	boss.touhou_encounter.attack = 0
	game._trigger_boss_skill(boss)
	var runtime = game._ensure_reisen_runtime()
	runtime.eyes.clear()
	runtime.queue_eye(boss, Vector2i(2, 2), 0.1)
	for frame in range(24):
		game.level_time += 0.1
		runtime.update(0.1)
		game.touhou_danmaku.update(0.1)
	check(game.grid[2][2].health < initial, "Reisen eye locks must create a real plant damage event")
	var probe := {}
	game.touhou_danmaku._bullet({"kind": "reisen_boss", "owner": 1, "phase": 0, "wave": 0}, Vector2.ZERO, 0, 100, Color.RED, "orb", {"damage": 20.0})
	probe = game.touhou_danmaku.bullets.back()
	check(is_equal_approx(float(probe.damage), 20.0 * 1.35 * 0.72), "Hard Reisen bullets must clear the upgraded damage floor")
	release(game)


func _test_illusion_collision() -> void:
	var game := fixture()
	var boss: Dictionary = game.zombies[0]
	game._trigger_boss_skill(boss)
	var dm = game.touhou_danmaku
	dm.clear()
	game.grid[2][3] = game._create_plant("wallnut", 2, 3)
	var initial := float(game.grid[2][3].health)
	var point: Vector2 = game._cell_center(2, 3) + Vector2(0, -12)
	var c := {"owner": int(boss.touhou_owner), "kind": "reisen_boss", "phase": 0, "wave": 0}
	dm._bullet(c, point, 0, 0, Color.RED, "rice", {"age": 0.8, "reisen_cycle": 2.6, "reisen_illusion": "tune", "damage": 100.0})
	dm.update(0.2)
	check(game.grid[2][3].health == initial and dm.bullets.size() == 1, "An illusion crossing a plant must not collide")
	dm.update(0.55)
	check(game.grid[2][3].health == initial, "Restored bullets allow a visible rearming warning")
	dm.update(0.5)
	check(game.grid[2][3].health < initial and dm.bullets.is_empty(), "A fully rearmed real bullet must hit through the shared collision system")
	var b := {"age": 2.0, "position": Vector2(10, 40), "velocity": Vector2(-100, 4), "reisen_illusion": "tune", "reisen_cycle": 2.6, "reisen_return_x": 20, "reisen_return_exit": 800, "reisen_mirror_y": 400}
	var before: Vector2 = dm.ReisenDanmaku.advance_bullet(b, Vector2(22, 40))
	check(before == Vector2(800, 360) and b.position == before and b.arming_time > b.age, "Corridor return resets sweep origin and rearms at the warned exit")
	release(game)

func _test_portals() -> void:
	var game := fixture("lunatic")
	var boss: Dictionary = game.zombies[0]
	var runtime = game._ensure_reisen_runtime()
	check(runtime.spawn_portal(boss, Vector2i(2, 6)), "Empty grass supports a destructible portal")
	var portal: Dictionary = game.zombies.back()
	var count := game.zombies.size()
	runtime.update(3.9)
	check(game.zombies.size() == count, "Portal countdown must not summon early")
	game._apply_zombie_damage(portal, 100000, 0, 0, true)
	runtime.update(0.2)
	check(game.zombies.size() == count, "Destroying the portal cancels its summon")
	check(runtime.spawn_portal(boss, Vector2i(3, 6)), "A second portal can open")
	runtime.update(4.1)
	check(game.zombies.any(func(z): return String(z.kind) == "moon_rabbit_guard"), "A completed high-difficulty portal must summon a lunar guard")
	check(runtime.spawn_portal(boss, Vector2i(4, 6)), "A third portal can open")
	game.grid[4][6] = game._create_plant("wallnut", 4, 6)
	count = game.zombies.size()
	runtime.update(4.1)
	check(game.zombies.size() == count and game.grid[4][6] != null, "Planting on a portal closes it without replacing the plant")
	for row in range(6):
		runtime.spawn_portal(boss, Vector2i(row, 7))
	check(game.zombies.filter(func(z): return String(z.kind) == "moon_portal" and float(z.health) > 0).size() <= runtime.MAX_PORTALS, "Portal cap bounds summon pressure")
	runtime.clear_owner(int(boss.uid))
	check(game.zombies.all(func(z): return String(z.kind) != "moon_portal" or float(z.health) <= 0), "Owner cleanup cancels all pending portals")
	check(game.zombies.any(func(z): return String(z.kind) == "moon_rabbit_guard" and float(z.health) > 0), "Already summoned enemies remain targetable")
	release(game)

func _test_cards_and_routes() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := fixture(choice)
		var boss: Dictionary = game.zombies[0]
		Game.TouhouPhaseRuntime.start(boss, game.current_level)
		var expected: Array = []
		for phase in boss.touhou_encounter.phases:
			for entry in phase:
				expected.append(entry[0])
		finish_encounter(game)
		check(game.declarations.map(func(c): return c.id) == expected, choice + " burst damage cannot skip attacks")
		game._cleanup_dead_zombies()
		check(game._ensure_reisen_runtime().eyes.is_empty(), "Defeat clears eyes")
		release(game)
		for card in Spells.cards_for("reisen_boss", {"touhou_difficulty": choice}):
			game = fixture(choice)
			boss = game.zombies[0]
			boss["touhou_encounter"] = {"phases": [[card]], "index": 0, "attack": 0, "casting": false}
			game._trigger_boss_skill(boss)
			var dm = game.touhou_danmaku
			var peak: int = dm.bullets.size()
			var phantom_seen := false
			for frame in range(55):
				dm.update(0.1)
				peak = maxi(peak, dm.bullets.size())
				phantom_seen = phantom_seen or dm.bullets.any(func(b): return bool(b.get("reisen_phantom", false)))
			check(peak > 0 and peak <= dm.MAX_BULLETS, "%s emits bounded live geometry" % card[0])
			check(phantom_seen, "%s distinguishes illusion intervals" % card[0])
			boss.erase("touhou_encounter")
			release(game)
