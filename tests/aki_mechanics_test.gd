extends "res://tests/touhou_encounter_test.gd"

func _run() -> void:
	check(Game.Defs.ZOMBIES.has("minoriko_boss"), "Minoriko must be registered before running her actual mechanics")
	if not Game.Defs.ZOMBIES.has("minoriko_boss"):
		quit(1)
		return
	var game: Control = _make_maple_game()
	check(game.has_method("_ensure_aki_runtime"), "The Aki sisters need a live leaf/harvest runtime")
	if not game.has_method("_ensure_aki_runtime"):
		release(game)
		quit(1)
		return
	_test_action_clocks(game)
	_test_harvest_warning(game)
	_test_baskets(game)
	_test_basket_birth_time(game)
	_test_owner_cleanup(game)
	release(game)
	_test_live_cards()
	_test_routes()
	_test_short_six_row_collision()
	print("Aki native/fusion/support clocks, harvest warnings, shootable baskets, bounded healing, cleanup and four routes: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _make_maple_game() -> Control:
	var game: Control = make_game("minoriko_boss")
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.current_level.terrain = "autumn_maple"
	game.current_level.row_count = 6
	game.current_level.water_rows = []
	return game

func _test_action_clocks(game: Control) -> void:
	var rt = game._ensure_aki_runtime()
	var owner := int(game.zombies[0].uid)
	game.grid[5][1] = game._create_plant("sunflower", 5, 1)
	game.grid[4][1] = game._create_plant("sunflower", 4, 1)
	game.grid[5][1].sun_timer = 10.0
	game.grid[4][1].sun_timer = 10.0
	rt.queue_field(owner, Vector2i(5, 1), "leaf_mat", 1.2)
	rt.update(1.1)
	check(rt.action_factor(5, 1) == 1.0, "A leaf warning cannot already slow the marked plant")
	rt.update(0.2)
	var leaf_factor: float = rt.action_factor(5, 1)
	check(leaf_factor > 0.0 and leaf_factor < 1.0 and rt.action_factor(4, 1) == 1.0, "Settled leaves slow only the marked cell on the sixth lane")
	game._update_plants(1.0)
	check(is_equal_approx(float(game.grid[5][1].sun_timer), 10.0 - leaf_factor) and is_equal_approx(float(game.grid[4][1].sun_timer), 9.0), "Leaves change actual sunflower production clocks")
	game.boss_time_stop_timer = 1.0
	var age := float(rt.fields[0].age)
	rt.update(2.0)
	check(is_equal_approx(float(rt.fields[0].age), age), "Time stop freezes field warnings, harvest timers and expiry")
	game.boss_time_stop_timer = 0.0
	rt.cleanse_row(5)
	check(rt.action_factor(5, 1) == 1.0, "Cleaning the lane restores its clocks immediately")
	var fusion = game._ensure_plant_fusion()
	var kind: String = fusion.Fusion.result("sunflower", "peashooter")
	game.grid[5][3] = game._create_plant(kind, 5, 3)
	game.support_grid[5][5] = game._create_plant("holy_flower", 5, 5)
	game.support_grid[5][5].attached = true
	var state: Dictionary = fusion.NativeRuntime.new(game).state_for(game.grid[5][3], "sunflower", 5, 3)
	state.sun_timer = 10.0
	game.support_grid[5][5].support_timer = 10.0
	game.grid[5][3].fusion_haste_timer = 0.7
	rt.queue_field(owner, Vector2i(5, 3), "leaf_mat", 1.2)
	rt.queue_field(owner, Vector2i(5, 5), "leaf_mat", 1.2)
	rt.update(1.3)
	game._update_plants(1.0)
	check(is_equal_approx(float(state.sun_timer), 10.0 - leaf_factor), "A fused sunflower's native component uses the actual leaf action factor")
	check(is_equal_approx(float(game.support_grid[5][5].support_timer), 10.0 - leaf_factor), "Bottom-layer support actions use the same leaf factor")
	check(float(game.grid[5][3].fusion_haste_timer) == 0.0, "Buff lifetime continues on real time while actions slow")
	rt.clear_owner(owner)
	game.grid[4][1].sun_timer = 10.0
	rt.queue_field(owner, Vector2i(4, 1), "ripening", 1.2)
	rt.update(1.3)
	var harvest_factor: float = rt.action_factor(4, 1)
	check(harvest_factor > 1.0, "Ripening gives the player a real temporary production benefit")
	game._update_plants(1.0)
	check(is_equal_approx(float(game.grid[4][1].sun_timer), 10.0 - harvest_factor), "The ripening benefit changes native sunflower output rather than only its visuals")
	rt.clear_owner(owner)

func _test_harvest_warning(game: Control) -> void:
	var rt = game._ensure_aki_runtime()
	var owner := int(game.zombies[0].uid)
	game.grid[3][4] = game._create_plant("wallnut", 3, 4)
	var hp := float(game.grid[3][4].health)
	rt.queue_field(owner, Vector2i(3, 4), "ripening", 1.2)
	rt.update(1.1)
	check(game.grid[3][4].health == hp and rt.action_factor(3, 4) == 1.0, "Ripening warns before either damage or acceleration")
	rt.update(0.2)
	check(game.grid[3][4].health == hp and rt.action_factor(3, 4) > 1.0, "The beneficial ripe interval precedes the localized harvest hit")
	rt.update(5.8)
	check(game.grid[3][4].health == hp, "The final harvest countdown remains a genuine warning")
	rt.update(0.2)
	check(game.grid[3][4].health < hp, "Only the marked cell takes the end-of-harvest damage")
	var hit_hp := float(game.grid[3][4].health)
	rt.update(0.5)
	check(game.grid[3][4].health == hit_hp and rt.fields.is_empty(), "Harvest applies its impact only once and releases its field")
	rt.queue_field(owner, Vector2i(3, 4), "ripening", 1.2)
	rt.update(1.3)
	rt.cleanse_row(3)
	rt.update(8.0)
	check(game.grid[3][4].health == hit_hp, "Cleaning a ripe field cancels its future harvest damage")
	rt.queue_field(owner, Vector2i(6, 1), "leaf_mat", 1.2)
	rt.queue_field(owner, Vector2i(5, -1), "leaf_mat", 1.2)
	check(rt.fields.is_empty(), "Invalid board cells never create invisible harvest hazards")

func _test_baskets(game: Control) -> void:
	var rt = game._ensure_aki_runtime()
	var boss: Dictionary = game.zombies[0]
	var owner := int(boss.uid)
	game.suns.clear()
	rt.queue_field(owner, Vector2i(3, 7), "basket", 1.2)
	rt.update(1.1)
	check(not game.zombies.any(func(z): return z.kind == "aki_harvest_basket" and z.health > 0), "An offering basket remains a warning until its announced arrival")
	rt.update(0.2)
	var units: Array = game.zombies.filter(func(z): return z.kind == "aki_harvest_basket" and z.health > 0)
	check(units.size() == 1 and rt.baskets.size() == 1, "The offering becomes one actual shootable enemy")
	if units.is_empty(): return
	var basket: Dictionary = units[0]
	check(game._is_enemy_zombie(basket) and int(basket.aki_parent) == owner and not game._is_boss_kind(String(basket.kind)), "The basket is an ordinary target with explicit encounter ownership")
	var point := float(basket.x)
	game._spawn_zombie_at("normal", 3, point, true)
	var near: Dictionary = game.zombies.back()
	near.health = 10.0
	game._spawn_zombie_at("normal", 0, point, true)
	var far: Dictionary = game.zombies.back()
	far.health = 10.0
	var boss_hp := float(boss.health) - 100.0
	boss.health = boss_hp
	var before_first_pulse: float = 3.9 - float(rt.baskets[0].age)
	rt.update(before_first_pulse)
	check(near.health == 10.0, "Baskets cannot heal during their first four seconds")
	rt.update(0.2)
	check(near.health > 10.0 and near.health <= 40.0 and near.health <= near.max_health, "The announced basket pulse offers bounded healing to nearby ordinary enemies")
	check(far.health == 10.0 and boss.health == boss_hp, "Basket healing neither reaches distant lanes nor heals the boss")
	var basket_age := float(rt.baskets[0].age)
	game.boss_time_stop_timer = 1.0
	rt.update(2.0)
	check(float(rt.baskets[0].age) == basket_age, "Time stop also pauses basket lifetime and healing pulses")
	game.boss_time_stop_timer = 0.0
	# Kill the actual body with ordinary native pea projectiles, so its reward
	# proves it participates in the game's targeting/collision/death paths.
	near.x += game.CELL_SIZE.x * 2.0
	game.projectiles.clear()
	for shot in range(24):
		game._spawn_projectile(3, Vector2(point - 50.0, game._row_center_y(3) - 24.0), Color.GREEN, 20.0, 0.0, 460.0, 8.0)
		game._update_projectiles(0.05)
		game._update_projectiles(0.05)
		if float(basket.health) <= 0.0: break
	check(float(basket.health) <= 0.0, "Ordinary native peas can destroy the offering body")
	game._cleanup_dead_zombies()
	check(game.suns.size() == 1 and int(game.suns[0].value) == 25, "A real basket kill drops exactly one 25-sun reward")
	game._cleanup_dead_zombies()
	rt.on_basket_death(basket)
	check(game.suns.size() == 1, "Repeated cleanup and callbacks cannot duplicate the basket reward")
	rt.clear_owner(owner)
	for row in range(6):
		for col in [6, 7]: rt.queue_field(owner, Vector2i(row, col), "basket", 1.2)
	rt.update(1.3)
	check(rt.baskets.size() <= 3 and game.zombies.filter(func(z): return z.kind == "aki_harvest_basket" and z.health > 0).size() <= 3, "Even overlapping offering waves obey the three-body cap")
	var reward_count: int = game.suns.size()
	rt.clear_owner(owner)
	game._cleanup_dead_zombies()
	check(game.suns.size() == reward_count and rt.baskets.is_empty(), "Phase cleanup erases offering bodies without paying kill sunshine")
	rt.queue_field(owner, Vector2i(3, 7), "basket", 1.2)
	rt.update(1.3)
	rt.update(9.0)
	game._cleanup_dead_zombies()
	check(game.suns.size() == reward_count and rt.baskets.is_empty(), "Natural offering expiry also grants no kill reward")

func _test_owner_cleanup(game: Control) -> void:
	var rt = game._ensure_aki_runtime()
	var owner := int(game.zombies[0].uid)
	game._spawn_zombie_at("shizuha_boss", 1, game._boss_anchor_x("shizuha_boss"), true)
	var other: Dictionary = game.zombies.back()
	rt.queue_field(owner, Vector2i(5, 2), "leaf_mat", 1.2)
	rt.queue_field(int(other.uid), Vector2i(4, 2), "leaf_mat", 1.2)
	rt.clear_owner(owner)
	check(rt.fields.size() == 1 and int(rt.fields[0].owner) == int(other.uid), "A phase transition removes only its own leaf fields")
	other.health = 0.0
	rt.update(0.1)
	check(rt.fields.is_empty(), "Dead encounter owners cannot leave active leaf hazards")
	rt.queue_field(owner, Vector2i(5, 3), "leaf_mat", 1.2)
	rt.queue_field(owner, Vector2i(5, 7), "basket", 1.2)
	rt.update(1.3)
	var reward_count: int = game.suns.size()
	rt.reset()
	game._cleanup_dead_zombies()
	check(rt.fields.is_empty() and rt.baskets.is_empty() and game.suns.size() == reward_count, "Restart resets every field and basket without rewarding cleanup")
	for row in range(6):
		for col in range(9): rt.queue_field(owner, Vector2i(row, col), "leaf_mat", 1.2)
	check(rt.fields.size() <= 12, "Even repeated overlapping casts have a bounded visible hazard budget")
	rt.reset()

func _test_basket_birth_time(game: Control) -> void:
	var rt = game._ensure_aki_runtime()
	var owner := int(game.zombies[0].uid)
	rt.clear_owner(owner)
	game._cleanup_dead_zombies()
	game._spawn_zombie_at("normal", 2, game._cell_center(2, 6).x, true)
	var nearby: Dictionary = game.zombies.back()
	nearby.health = 10.0
	rt.queue_field(owner, Vector2i(2, 6), "basket", 1.2)
	rt.update(1.3)
	check(rt.baskets.size() == 1, "One delayed offering appears across a single long step")
	if rt.baskets.is_empty(): return
	check(is_equal_approx(float(rt.baskets[0].age), 0.1), "A single 1.3-second step across a 1.2-second warning ages the newborn basket by only 0.1 seconds")
	check(nearby.health == 10.0, "Warning time never counts toward a newborn basket's healing pulse")
	rt.update(3.8)
	check(nearby.health == 10.0, "The new basket cannot heal before four seconds of actual body lifetime")
	rt.update(0.2)
	check(nearby.health > 10.0 and nearby.health <= 40.0, "The basket heals only after crossing its own four-second lifetime")
	rt.clear_owner(owner)
	game._cleanup_dead_zombies()

func _test_short_six_row_collision() -> void:
	for dimensions in [Vector2(76, 33), Vector2(52, 20)]:
		var game: Control = _make_maple_game()
		game.CELL_SIZE = dimensions
		game.BOARD_ORIGIN = Vector2(37, 129)
		game.board_size = dimensions * Vector2(9, 6)
		game.grid[5][4] = game._create_plant("wallnut", 5, 4)
		var center: Vector2 = game._cell_center(5, 4)
		check(game._cell_rect(5, 4).has_point(center), "The sixth mobile lane has a readable real cell rectangle")
		var runtime = Game.TouhouDanmakuRuntime.new(game)
		var hp := float(game.grid[5][4].health)
		var hits: Array = []
		var hit: bool = runtime._hit_plant_segment(center + Vector2(-dimensions.x * 1.5, -12.0), center + Vector2(dimensions.x * 1.5, -12.0), 3.0, 10.0, hits)
		check(hit and game.grid[5][4].health < hp, "Fast leaf danmaku keeps swept collisions on short six-row mobile boards")
		release(game)

func _test_routes() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game: Control = _make_maple_game()
		game.current_level.touhou_difficulty = choice
		Game.TouhouPhaseRuntime.start(game.zombies[0], game.current_level)
		var expected: Array = []
		for phase in game.zombies[0].touhou_encounter.phases:
			for entry in phase: expected.append(entry[0])
		finish_encounter(game)
		check(game.declarations.map(func(d): return d.id) == expected, choice + ": burst damage cannot skip any Aki spell or nonspell declaration")
		game._cleanup_dead_zombies()
		check(game._ensure_aki_runtime().fields.is_empty() and game._ensure_aki_runtime().baskets.is_empty(), "Victory clears every Aki gameplay field")
		release(game)

func _test_live_cards() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var cards: Array = Spells.cards_for("minoriko_boss", {"touhou_difficulty": choice})
		for cycle in range(cards.size()):
			var game: Control = _make_maple_game()
			game.current_level.touhou_difficulty = choice
			var boss: Dictionary = game.zombies[0]
			boss.erase("touhou_encounter")
			boss.boss_skill_cycle = cycle
			game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
			for row in range(6):
				for col in range(9): game.grid[row][col] = game._create_plant("wallnut", row, col)
			var hp := _health(game)
			game._trigger_boss_skill(boss)
			check(_health(game) == hp, "Every Aki declaration warns before doing damage: " + str(cards[cycle][0]))
			var peak := 0
			for frame in range(140):
				game.level_time += 0.1
				game._ensure_aki_runtime().update(0.1)
				game.touhou_danmaku.update(0.1)
				peak = maxi(peak, game.touhou_danmaku.bullets.size())
			check(peak > 0 and peak <= game.touhou_danmaku.MAX_BULLETS, "Aki cards produce bounded live danmaku: " + str(cards[cycle][0]))
			check(_health(game) < hp, "Aki patterns have real swept plant collisions or harvest damage: " + str(cards[cycle][0]))
			game._ensure_aki_runtime().clear_owner(int(boss.uid))
			check(game._ensure_aki_runtime().fields.is_empty() and game._ensure_aki_runtime().baskets.is_empty(), "No fields or baskets leak between Aki cards")
			release(game)

func _health(game: Control) -> float:
	var hp := 0.0
	for row in game.grid:
		for plant in row:
			if plant != null: hp += float(plant.health)
	return hp
