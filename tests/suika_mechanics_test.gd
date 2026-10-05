extends "res://tests/touhou_encounter_test.gd"

func _run() -> void:
	var game := make_game("suika_boss")
	check(game.has_method("_ensure_suika_runtime"), "Suika needs live wine, impact and miniature runtime")
	if not game.has_method("_ensure_suika_runtime"):
		release(game)
		quit(1)
		return
	_test_wine(game)
	_test_impacts(game)
	_test_capture(game)
	_test_live_cards()
	_test_routes()
	release(game)
	print("Suika actual action clocks, warning damage, capture and four routes: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_wine(game: Control) -> void:
	var rt = game._ensure_suika_runtime()
	var boss: Dictionary = game.zombies[0]
	game.grid[2][1] = game._create_plant("sunflower", 2, 1)
	game.grid[1][1] = game._create_plant("sunflower", 1, 1)
	game.grid[2][1].sun_timer = 10.0
	game.grid[1][1].sun_timer = 10.0
	rt.queue_pour(int(boss.uid), 2, 1.2)
	rt.update(1.1)
	check(is_equal_approx(rt.action_factor(2, 1), 1.0), "Gold warning cannot already slow a plant")
	rt.update(1.6)
	check(is_equal_approx(rt.action_factor(2, 1), 0.55) and is_equal_approx(rt.action_factor(1, 1), 1.0), "Wine advances across one lane and leaves other lanes dry")
	game._update_plants(1.0)
	check(is_equal_approx(float(game.grid[2][1].sun_timer), 9.45) and is_equal_approx(float(game.grid[1][1].sun_timer), 9.0), "Wine must slow actual sunflower production, not just animation")
	game.grid[2][2] = game._create_plant("jasmine_tea", 2, 2)
	check(is_equal_approx(rt.action_factor(2, 1), 1.0), "Tea protects its surrounding cells from intoxication")
	game.grid[2][2] = null
	game.boss_time_stop_timer = 1.0
	var age := float(rt.pours[0].age)
	rt.update(2.0)
	check(is_equal_approx(float(rt.pours[0].age), age), "Time stop pauses field expiry and wavefronts")
	game.boss_time_stop_timer = 0.0
	rt.cleanse_row(2)
	check(is_equal_approx(rt.action_factor(2, 1), 1.0), "A lane cleanse must immediately restore its action clocks")
	rt.queue_pour(int(boss.uid), 2, 0.0)
	rt.update(2.0)
	rt.clear_owner(int(boss.uid))
	check(rt.pours.is_empty() and is_equal_approx(rt.action_factor(2, 1), 1.0), "Phase cleanup must remove every wine effect")
	var fusion = game._ensure_plant_fusion()
	var id: String = fusion.Fusion.result("sunflower", "peashooter")
	game.grid[2][3] = game._create_plant(id, 2, 3)
	game.support_grid[2][5] = game._create_plant("holy_flower", 2, 5)
	game.support_grid[2][5].attached = true
	var state: Dictionary = fusion.NativeRuntime.new(game).state_for(game.grid[2][3], "sunflower", 2, 3)
	state.sun_timer = 10.0
	game.support_grid[2][5].support_timer = 10.0
	game.grid[2][3].fusion_haste_timer = 0.7
	rt.queue_pour(int(boss.uid), 2, 0.0)
	rt.update(2.0)
	game._update_plants(1.0)
	check(is_equal_approx(float(state.sun_timer), 9.45), "Fused sunflower retains a genuinely slowed native production clock")
	check(is_equal_approx(float(game.support_grid[2][5].support_timer), 9.45), "Bottom-layer support behavior uses the same wine action factor")
	check(float(game.grid[2][3].fusion_haste_timer) == 0.0, "Buff expiry stays on real time while actions are slowed")
	var tea_id: String = fusion.Fusion.result("jasmine_tea", "wallnut")
	game.grid[2][4] = game._create_plant(tea_id, 2, 4)
	check(rt.action_factor(2, 3) == 1.0, "Fused tea material still protects its neighbors")
	game.grid[2][4] = null
	rt.update(6.0)
	check(rt.pours.is_empty() and rt.action_factor(2, 3) == 1.0, "Wine expires naturally without waiting for a boss transition")

func _test_impacts(game: Control) -> void:
	var rt = game._ensure_suika_runtime()
	var boss: Dictionary = game.zombies[0]
	game.grid[3][4] = game._create_plant("wallnut", 3, 4)
	var hp := float(game.grid[3][4].health)
	rt.queue_impact(int(boss.uid), Vector2i(3, 4), "rock", 1.2)
	rt.update(1.1)
	check(game.grid[3][4].health == hp, "Rock cannot damage before its landing warning")
	rt.update(0.2)
	check(game.grid[3][4].health < hp, "Rock landing applies real localized damage")
	var hit_hp := float(game.grid[3][4].health)
	rt.update(0.1)
	check(game.grid[3][4].health == hit_hp, "A rock must not deal its impact damage twice")
	rt.spawn_mini(int(boss.uid), 4)
	check(game.zombies.any(func(z): return z.kind == "suika_mini" and z.health > 0), "Density creates actual targetable small Suikas")
	rt.clear_owner(int(boss.uid))
	check(not game.zombies.any(func(z): return z.kind == "suika_mini" and z.health > 0), "Owner transition removes mini bodies")

func _test_capture(game: Control) -> void:
	var rt = game._ensure_suika_runtime()
	var boss: Dictionary = game.zombies[0]
	game.projectiles.clear()
	rt.cast(boss, "suika_pea_knot")
	check(not rt.knots.is_empty(), "Original density card needs a shootable knot")
	var knot: Dictionary = rt.knots[0]
	var point: Vector2 = knot.position
	for i in range(12):
		game.projectiles.append({"position": point, "velocity": Vector2(100, 0), "shape": "pea", "damage": 20.0, "row": int(knot.row)})
	game.projectiles.append({"position": point, "velocity": Vector2(100, 0), "shape": "pea", "damage": 20.0, "row": int(knot.row), "ultimate": true})
	rt.update(1.5)
	check(int(knot.captured) == 8 and game.projectiles.size() == 5, "Capture is bounded to eight ordinary peas and preserves ultimate shots")
	game.grid[int(knot.row)][1] = game._create_plant("peashooter", int(knot.row), 1)
	game.grid[int(knot.row)][1].plant_food_timer = 2.0
	game._spawn_projectile(int(knot.row), game._cell_center(int(knot.row), 1), Color.GREEN, 20, 0, 400, 8, "peashooter")
	check(bool(game.projectiles.back().get("plant_food", false)), "Actual native plant-food pea volleys must be marked as uncapturable")
	for z in game.zombies:
		if int(z.uid) == int(knot.unit): z.health = 0.0
	var count: int = game.touhou_danmaku.bullets.size()
	rt.update(5.0)
	check(game.touhou_danmaku.bullets.size() == count and rt.knots.is_empty(), "Destroying a knot cancels its release")

func _test_routes() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := make_game("suika_boss")
		game.current_level.touhou_difficulty = choice
		Game.TouhouPhaseRuntime.start(game.zombies[0], game.current_level)
		var expected: Array = []
		for phase in game.zombies[0].touhou_encounter.phases:
			for entry in phase: expected.append(entry[0])
		finish_encounter(game)
		check(game.declarations.map(func(d): return d.id) == expected, choice + ": no burst damage may skip a declaration")
		check(expected.back() == "th075-suika-6", "Million Oni ends every route")
		game._cleanup_dead_zombies()
		check(game._ensure_suika_runtime().pours.is_empty(), "Victory clears wine")
		release(game)

func _test_live_cards() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var cards: Array = Spells.cards_for("suika_boss", {"touhou_difficulty": choice})
		for cycle in range(cards.size()):
			var game := make_game("suika_boss")
			game.current_level.touhou_difficulty = choice
			var boss: Dictionary = game.zombies[0]
			boss.erase("touhou_encounter")
			boss.boss_skill_cycle = cycle
			game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
			for row in range(5):
				for col in range(9): game.grid[row][col] = game._create_plant("wallnut", row, col)
			var hp := _health(game)
			game._trigger_boss_skill(boss)
			check(_health(game) == hp, "Declaration must warn before damage: " + str(cards[cycle][0]))
			var peak := 0
			for frame in range(140):
				game.level_time += 0.1
				game._ensure_suika_runtime().update(0.1)
				game.touhou_danmaku.update(0.1)
				peak = maxi(peak, game.touhou_danmaku.bullets.size())
			check(peak > 0 and peak <= game.touhou_danmaku.MAX_BULLETS, "Bounded live danmaku: " + str(cards[cycle][0]))
			check(_health(game) < hp, "Real collisions and impacts: " + str(cards[cycle][0]))
			game._ensure_suika_runtime().clear_owner(int(boss.uid))
			check(game._ensure_suika_runtime().pours.is_empty() and game._ensure_suika_runtime().knots.is_empty(), "No owner fields leak after a card")
			release(game)

func _health(game: Control) -> float:
	var hp := 0.0
	for row in game.grid:
		for plant in row:
			if plant != null: hp += float(plant.health)
	return hp
