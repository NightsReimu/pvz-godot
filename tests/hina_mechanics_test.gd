extends "res://tests/touhou_encounter_test.gd"

class NativeEmissionGame extends EncounterGame:
	func _ready() -> void:
		hide()
		set_process(false)

func _run() -> void:
	check(Game.Defs.ZOMBIES.has("hina_boss"), "Hina must be registered before exercising her actual mechanics")
	if not Game.Defs.ZOMBIES.has("hina_boss"):
		quit(1)
		return
	var game: Control = _make_forest_game()
	check(game.has_method("_ensure_hina_runtime"), "Hina needs a live curse and misfortune-doll runtime")
	if not game.has_method("_ensure_hina_runtime"):
		release(game)
		quit(1)
		return
	_test_action_clocks(game)
	_test_misfire(game)
	_test_dolls(game)
	_test_cleanup(game)
	release(game)
	_test_enemies()
	_test_live_cards()
	_test_routes()
	_test_short_six_row_collision()
	await _test_emission_contexts()
	print("Hina live clocks, misfire, shootable dolls, enemy fusions, cleanup, collisions and four spell routes: %d failure(s)" % failures)
	call_deferred("quit", 1 if failures else 0)

func _make_forest_game() -> Control:
	var game: Control = make_game("hina_boss")
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.current_level.terrain = "hina_mountain_forest"
	game.current_level.row_count = 6
	game.current_level.water_rows = []
	return game

func _test_action_clocks(game: Control) -> void:
	var rt = game._ensure_hina_runtime()
	var owner := int(game.zombies[0].uid)
	game.grid[5][1] = game._create_plant("sunflower", 5, 1)
	game.grid[4][1] = game._create_plant("sunflower", 4, 1)
	game.grid[5][1].sun_timer = 10.0
	game.grid[4][1].sun_timer = 10.0
	rt.queue_field(owner, Vector2i(5, 1), "curse", 0.0)
	rt.update(1.1)
	check(rt.action_factor(5, 1) == 1.0, "Even a zero-delay curse request preserves its 1.2-second warning")
	rt.update(0.2)
	check(is_equal_approx(rt.action_factor(5, 1), 0.72) and rt.action_factor(4, 1) == 1.0, "Active curses slow only the marked cell, including lane six")
	game._update_plants(1.0)
	check(is_equal_approx(float(game.grid[5][1].sun_timer), 9.28) and is_equal_approx(float(game.grid[4][1].sun_timer), 9.0), "Curses change actual native production clocks")
	game.boss_time_stop_timer = 1.0
	var age := float(rt.fields[0].age)
	rt.update(2.0)
	check(is_equal_approx(float(rt.fields[0].age), age), "Time stop freezes curse warning and expiry clocks")
	game.boss_time_stop_timer = 0.0
	rt.cleanse_row(5)
	check(rt.action_factor(5, 1) == 1.0, "Cleaning the lane restores its real clocks immediately")
	var fusion = game._ensure_plant_fusion()
	var kind: String = fusion.Fusion.result("sunflower", "peashooter")
	game.grid[5][3] = game._create_plant(kind, 5, 3)
	game.support_grid[5][5] = game._create_plant("holy_flower", 5, 5)
	game.support_grid[5][5].attached = true
	var state: Dictionary = fusion.NativeRuntime.new(game).state_for(game.grid[5][3], "sunflower", 5, 3)
	state.sun_timer = 10.0
	game.support_grid[5][5].support_timer = 10.0
	game.grid[5][3].fusion_haste_timer = 0.7
	rt.queue_field(owner, Vector2i(5, 3), "curse", 1.2)
	rt.queue_field(owner, Vector2i(5, 5), "curse", 1.2)
	rt.update(1.3)
	game._update_plants(1.0)
	check(is_equal_approx(float(state.sun_timer), 9.28), "A fusion's native component uses the live curse action factor")
	check(is_equal_approx(float(game.support_grid[5][5].support_timer), 9.28), "Bottom-layer support actions use the same curse factor")
	check(float(game.grid[5][3].fusion_haste_timer) == 0.0, "Temporary buff expiry still follows real time while actions slow")
	rt.update(6.0)
	check(rt.action_factor(5, 3) == 1.0 and rt.fields.is_empty(), "A curse ends after its six-second active lifetime")

func _test_misfire(game: Control) -> void:
	var rt = game._ensure_hina_runtime()
	var owner := int(game.zombies[0].uid)
	var cell := Vector2i(5, 2)
	game.grid[cell.x][cell.y] = game._create_plant("repeater", cell.x, cell.y)
	rt.queue_field(owner, cell, "misfire", 1.2)
	var position: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(30, -20)
	var warning: Dictionary = {"row": cell.x, "position": position, "damage": 100.0, "kind": "pea"}
	rt.modify_projectile(warning)
	check(warning.damage == 100.0, "A misfire warning cannot reduce the player's current shot")
	rt.update(1.3)
	for n in range(6):
		var shot: Dictionary = {"row": cell.x, "position": position, "damage": 100.0, "kind": "pea"}
		rt.modify_projectile(shot)
		var expected := 75.0 if n % 3 == 2 else 100.0
		check(shot.damage == expected, "Only every third newly born ordinary shot loses 25 percent damage")
		rt.modify_projectile(shot)
		check(shot.damage == expected, "Processing the same bullet twice cannot count or weaken it again")
	for flag in ["ultimate", "plant_food", "fusion_ultimate", "empowered", "reflected", "special"]:
		var shot: Dictionary = {"row": cell.x, "position": position, "damage": 100.0, "kind": "pea"}
		shot[flag] = true
		rt.modify_projectile(shot)
		check(shot.damage == 100.0, "Misfire preserves explicitly protected " + flag + " projectiles")
	check(int(rt.fields[0].shots) == 6, "Reflected, special and protected bullets never consume the ordinary third-shot counter")
	# Verify the production hook on native projectile births, rather than only
	# invoking the runtime helper directly.
	rt.clear_owner(owner)
	rt.queue_field(owner, cell, "misfire", 1.2)
	rt.update(1.3)
	game.projectiles.clear()
	for n in range(3): game._spawn_projectile(cell.x, position, Color.GREEN, 20.0, 0.0)
	game._update_projectiles(0.0)
	check(game.projectiles.size() == 3 and game.projectiles.filter(func(p): return p.damage == 15.0).size() == 1 and game.projectiles.filter(func(p): return p.damage == 20.0).size() == 2, "Actual ordinary native projectile births apply every-third-shot misfire")
	rt.clear_owner(owner)
	var fusion = game._ensure_plant_fusion()
	game.grid[cell.x][cell.y] = game._create_plant(fusion.Fusion.result("repeater", "wallnut"), cell.x, cell.y)
	rt.queue_field(owner, cell, "misfire", 1.2)
	rt.update(1.3)
	game.projectiles.clear()
	for n in range(3): game._spawn_projectile(cell.x, position, Color.GREEN, 20.0, 0.0)
	game._update_projectiles(0.0)
	check(game.projectiles.filter(func(p): return p.damage == 15.0).size() == 1, "Actual native shots born from a fused plant use the same misfire cell")
	rt.clear_owner(owner)
	game.projectiles.clear()

func _test_dolls(game: Control) -> void:
	var rt = game._ensure_hina_runtime()
	var boss: Dictionary = game.zombies[0]
	var owner := int(boss.uid)
	game.suns.clear()
	rt.queue_field(owner, Vector2i(3, 7), "doll", 0.0)
	rt.update(1.3)
	check(rt.dolls.is_empty(), "Misfortune dolls preserve a visible 1.4-second spawn warning")
	rt.update(0.2)
	var units: Array = game.zombies.filter(func(z): return z.kind == "hina_misfortune_doll" and z.health > 0)
	check(units.size() == 1 and rt.dolls.size() == 1, "A doll is an actual shootable body after its warning")
	if units.is_empty(): return
	var doll: Dictionary = units[0]
	check(game._is_enemy_zombie(doll) and int(doll.hina_parent) == owner and not game._is_boss_kind(String(doll.kind)), "Dolls participate in ordinary targeting with explicit owner identity")
	check(is_equal_approx(float(rt.dolls[0].age), 0.1), "A newborn doll ages only the part of a long tick after its warning")
	check(doll.max_health == 360.0 + 40.0 * int(game.TouhouDifficulty.profile(game.current_level).rank), "Each doll has its bounded difficulty-scaled health")
	var point := float(doll.x)
	game._spawn_zombie_at("buckethead", 3, point + 15.0, true)
	var near: Dictionary = game.zombies.back()
	var near_hp := float(near.health) + float(near.shield_health)
	game._spawn_zombie_at("normal", 0, point, true)
	var far: Dictionary = game.zombies.back()
	var far_hp := float(far.health)
	var boss_hp := float(boss.health)
	rt.queue_field(owner, Vector2i(3, 1), "curse", 1.2)
	rt.queue_field(owner, Vector2i(4, 1), "curse", 1.2)
	rt.update(1.3)
	var doll_age := float(rt.dolls[0].age)
	game.boss_time_stop_timer = 1.0
	rt.update(2.0)
	check(float(rt.dolls[0].age) == doll_age, "Time stop pauses the doll body's lifetime")
	game.boss_time_stop_timer = 0.0
	game.projectiles.clear()
	for shot in range(26):
		game._spawn_projectile(3, Vector2(point - 50.0, game._row_center_y(3) - 24.0), Color.GREEN, 20.0, 0.0)
		game._update_projectiles(0.05)
		game._update_projectiles(0.05)
		if float(doll.health) <= 0.0: break
	check(float(doll.health) <= 0.0, "Ordinary native peas can actually kill the doll")
	game._cleanup_dead_zombies()
	check(rt.action_factor(3, 1) == 1.0 and rt.action_factor(4, 1) == 0.72, "A real doll kill cleans its own lane while preserving another cursed lane")
	var near_remaining := float(near.health) + float(near.shield_health)
	check(is_equal_approx(near_remaining, near_hp - 180.0), "A destroyed doll releases exactly 180 damage into the nearby ordinary enemy and its equipment")
	check(far.health == far_hp and boss.health == boss_hp, "Doll revenge excludes distant enemies and the boss")
	check(game.suns.size() == 1 and int(game.suns[0].value) == 25, "A real doll kill yields exactly one 25-sun reward")
	rt.on_doll_death(doll)
	game._cleanup_dead_zombies()
	check(game.suns.size() == 1, "Repeated death callbacks cannot duplicate the doll reward")
	rt.clear_owner(owner)
	for row in range(6):
		for col in [6, 7]: rt.queue_field(owner, Vector2i(row, col), "doll", 1.4)
	rt.update(1.5)
	check(rt.dolls.size() <= 3 and game.zombies.filter(func(z): return z.kind == "hina_misfortune_doll" and z.health > 0).size() <= 3, "Overlapping offerings cannot exceed three living dolls")
	var reward_count: int = game.suns.size()
	rt.clear_owner(owner)
	game._cleanup_dead_zombies()
	check(rt.dolls.is_empty() and game.suns.size() == reward_count, "Owner cleanup grants no kill reward")
	rt.queue_field(owner, Vector2i(3, 7), "doll", 1.4)
	rt.update(1.5)
	rt.update(9.0)
	game._cleanup_dead_zombies()
	check(rt.dolls.is_empty() and game.suns.size() == reward_count, "Natural doll expiry grants no kill reward")

func _test_cleanup(game: Control) -> void:
	var rt = game._ensure_hina_runtime()
	var owner := int(game.zombies[0].uid)
	# The authored stage has serial incarnations. Isolate owner filtering with
	# a second valid Hina dictionary because the normal spawner rejects duplicates.
	var other: Dictionary = game.zombies[0].duplicate(true)
	other.uid = game.next_zombie_uid
	game.next_zombie_uid += 1
	game.zombies.append(other)
	rt.queue_field(owner, Vector2i(5, 2), "curse", 1.2)
	rt.queue_field(int(other.uid), Vector2i(4, 2), "curse", 1.2)
	rt.clear_owner(owner)
	check(rt.fields.size() == 1 and int(rt.fields[0].owner) == int(other.uid), "A phase transition clears only its own curse fields")
	other.touhou_encounter.complete = true
	other.health = 0.0
	rt.update(0.1)
	check(rt.fields.is_empty(), "A dead owner cannot leave curse fields behind")
	rt.queue_field(owner, Vector2i(5, 3), "curse", 1.2)
	rt.queue_field(owner, Vector2i(5, 7), "doll", 1.4)
	rt.update(1.5)
	var rewards: int = game.suns.size()
	rt.reset()
	game._cleanup_dead_zombies()
	check(rt.fields.is_empty() and rt.dolls.is_empty() and game.suns.size() == rewards, "Restart resets all fields and dolls without rewarding cleanup")
	for row in range(6):
		for col in range(9): rt.queue_field(owner, Vector2i(row, col), "curse", 1.2)
	check(rt.fields.size() <= 12, "Repeated casts respect the twelve visible-field cap")
	rt.reset()
	rt.queue_field(owner, Vector2i(6, 1), "curse", 1.2)
	rt.queue_field(owner, Vector2i(5, -1), "curse", 1.2)
	check(rt.fields.is_empty(), "Invalid cells never create hidden curses")

func _test_enemies() -> void:
	var fairies: Array = []
	var kedamas: Array = []
	for kind in Game.Defs.ZOMBIES:
		if String(kind).contains("star_fairy") and kind != "star_fairy": fairies.append(kind)
		if String(kind).contains("kedama") and kind not in ["kedama", "mini_kedama"]: kedamas.append(kind)
	check(fairies.size() == 4 and kedamas.size() == 4, "The forest supplies four headgear fusions for each native enemy")
	for kind in ["star_fairy"] + fairies:
		var game: Control = _make_forest_game()
		game.grid[5][6] = game._create_plant("wallnut", 5, 6)
		var hp := float(game.grid[5][6].health)
		game._spawn_zombie_at(kind, 5, game._cell_center(5, 8).x, true)
		var fairy: Dictionary = game.zombies.back()
		var rt = game._ensure_touhou_enemies()
		rt.update_unit(fairy, 4.9)
		check(game.grid[5][6].health == hp and float(fairy.get("fairy_warning", 0.0)) == 0.0, kind + ": fusion preserves the initial five-second attack cooldown")
		rt.update_unit(fairy, 0.2)
		check(game.grid[5][6].health == hp and float(fairy.get("fairy_warning", 0.0)) > 0.0, kind + ": targeting warns before fairy damage")
		rt.update_unit(fairy, 1.1)
		check(game.grid[5][6].health < hp, kind + ": fairy fusion preserves the actual warned plant hit")
		release(game)
	for kind in ["kedama"] + kedamas:
		for hypnotized in [false, true]:
			var game: Control = _make_forest_game()
			game._spawn_zombie_at(kind, 5, game._cell_center(5, 7).x, true)
			var fur: Dictionary = game.zombies.back()
			fur.hypnotized = hypnotized
			fur.health = 0.0
			var rt = game._ensure_touhou_enemies()
			rt.on_death(fur)
			rt.on_death(fur)
			var children: Array = game.zombies.filter(func(z): return z.kind == "mini_kedama")
			check(children.size() == 2, kind + ": fusion splits once into exactly two native children")
			check(children.all(func(z): return bool(z.get("hypnotized", false)) == hypnotized), kind + ": children retain the parent's hypnosis allegiance")
			release(game)
	var game: Control = _make_forest_game()
	for n in range(12): game._spawn_zombie_at("mini_kedama", 5, game._cell_center(5, 8).x, true)
	game._spawn_zombie_at("kedama", 5, game._cell_center(5, 8).x, true)
	var fur: Dictionary = game.zombies.back()
	fur.health = 0.0
	game._ensure_touhou_enemies().on_death(fur)
	check(game._count_alive_enemy_zombies_by_kind("mini_kedama") == 12, "Kedama splitting respects the global twelve-child cap")
	release(game)
	game = _make_forest_game()
	for n in range(64): game._spawn_zombie_at("normal", 5, game._cell_center(5, 8).x, true)
	game._spawn_zombie_at("kedama", 5, game._cell_center(5, 8).x, true)
	var capped_fur: Dictionary = game.zombies.back()
	capped_fur.health = 0.0
	game._ensure_touhou_enemies().on_death(capped_fur)
	check(game._count_alive_enemy_zombies_by_kind("mini_kedama") == 0, "Kedama spawning respects the global 65-body cap")
	release(game)

func _test_live_cards() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var cards: Array = Spells.cards_for("hina_boss", {"touhou_difficulty": choice})
		for cycle in range(cards.size()):
			var game: Control = _make_forest_game()
			game.current_level.touhou_difficulty = choice
			var boss: Dictionary = game.zombies[0]
			boss.erase("touhou_encounter")
			boss.boss_skill_cycle = cycle
			game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
			for row in range(6):
				for col in range(9): game.grid[row][col] = game._create_plant("wallnut", row, col)
			var hp := _health(game)
			game._trigger_boss_skill(boss)
			check(_health(game) == hp, "Every Hina declaration warns before damage: " + str(cards[cycle][0]))
			var peak := 0
			for frame in range(140):
				game.level_time += 0.1
				game._ensure_hina_runtime().update(0.1)
				game.touhou_danmaku.update(0.1)
				peak = maxi(peak, game.touhou_danmaku.bullets.size())
			check(peak > 0 and peak <= game.touhou_danmaku.MAX_BULLETS, "Hina cards produce bounded live danmaku: " + str(cards[cycle][0]))
			check(_health(game) < hp, "Hina cards have real swept plant collisions: " + str(cards[cycle][0]))
			game._ensure_hina_runtime().clear_owner(int(boss.uid))
			check(game._ensure_hina_runtime().fields.is_empty() and game._ensure_hina_runtime().dolls.is_empty(), "No curse fields or dolls leak between cards")
			release(game)

func _test_routes() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game: Control = _make_forest_game()
		game.current_level.touhou_difficulty = choice
		Game.TouhouPhaseRuntime.start(game.zombies[0], game.current_level)
		var expected: Array = []
		for phase in game.zombies[0].touhou_encounter.phases:
			for entry in phase: expected.append(entry[0])
		finish_encounter(game)
		check(game.declarations.map(func(d): return d.id) == expected, choice + ": burst damage cannot skip Hina's required nonspells or cards")
		game._cleanup_dead_zombies()
		check(game._ensure_hina_runtime().fields.is_empty() and game._ensure_hina_runtime().dolls.is_empty(), "Final death clears every curse and doll")
		release(game)

func _test_short_six_row_collision() -> void:
	for dimensions in [Vector2(76, 33), Vector2(52, 20)]:
		var game: Control = _make_forest_game()
		game.CELL_SIZE = dimensions
		game.BOARD_ORIGIN = Vector2(37, 129)
		game.board_size = dimensions * Vector2(9, 6)
		game.grid[5][4] = game._create_plant("wallnut", 5, 4)
		var center: Vector2 = game._cell_center(5, 4)
		check(game._cell_rect(5, 4).has_point(center), "The sixth mobile lane has a readable actual cell rectangle")
		var hp := float(game.grid[5][4].health)
		var hits: Array = []
		var hit: bool = Game.TouhouDanmakuRuntime.new(game)._hit_plant_segment(center + Vector2(-dimensions.x * 1.5, -12.0), center + Vector2(dimensions.x * 1.5, -12.0), 3.0, 10.0, hits)
		check(hit and game.grid[5][4].health < hp, "Fast Hina ribbons preserve swept collisions on short mobile cells")
		release(game)

func _health(game: Control) -> float:
	var hp := 0.0
	for row in game.grid:
		for plant in row:
			if plant != null: hp += float(plant.health)
	return hp

func _test_emission_contexts() -> void:
	var game := NativeEmissionGame.new()
	game.size = Vector2(844, 390)
	game.current_level = {"id": "native-emission-test", "terrain": "hina_mountain_forest", "row_count": 6, "water_rows": [], "events": []}
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.banner_label = Label.new()
	game.toast_label = Label.new()
	for row in range(6):
		var cells: Array = []
		cells.resize(9)
		game.grid.append(cells)
		game.support_grid.append(cells.duplicate())
	root.add_child(game)
	game.CELL_SIZE = Vector2(52, 20)
	game.BOARD_ORIGIN = Vector2(37, 129)
	game.board_size = game.CELL_SIZE * Vector2(9, 6)
	game._spawn_zombie_at("hina_boss", 2, game._boss_anchor_x("hina_boss"), true)
	game._spawn_zombie_at("normal", 4, game._cell_center(4, 8).x, true)
	var rt = game._ensure_hina_runtime()
	var owner := int(game.zombies[0].uid)
	var cell := Vector2i(4, 2)
	for route in ["native", "fusion", "support"]:
		for food in [false, true]:
			for row in range(6):
				for col in range(9):
					game.grid[row][col] = null
					game.support_grid[row][col] = null
			rt.clear_owner(owner)
			game.projectiles.clear()
			var fusion = game._ensure_plant_fusion()
			var kind: String = "threepeater" if route == "native" else fusion.Fusion.result("threepeater", "wallnut" if route == "fusion" else "holy_flower")
			var plant: Dictionary = game._create_plant(kind, cell.x, cell.y)
			if route == "support":
				plant.attached = true
				game.support_grid[cell.x][cell.y] = plant
			else: game.grid[cell.x][cell.y] = plant
			plant.shot_cooldown = 0.0
			if food:
				plant.plant_food_mode = "tri_storm"
				plant.plant_food_timer = 10.0
				plant.plant_food_interval = 0.0
			if plant.has("fusion_kind"):
				var state: Dictionary = fusion.NativeRuntime.new(game).state_for(plant, "threepeater", cell.x, cell.y)
				state.shot_cooldown = 0.0
			rt.queue_field(owner, cell, "misfire", 1.2)
			rt.update(1.3)
			game._update_plants(0.01)
			check(game.projectiles.size() >= 3, route + ": native actions emit a real three-line volley")
			if game.projectiles.size() < 3: continue
			check(game.projectiles.any(func(p): return int(p.row) != cell.x) and game.projectiles.all(func(p): return Vector2i(p.get("source_cell", Vector2i(-1,-1))) == cell), route + ": adjacent-lane shots preserve their originating plant's mobile cell")
			game._update_projectiles(0.0)
			if food:
				check(game.projectiles.all(func(p): return not bool(p.get("hina_misfire", false))) and int(rt.fields[0].shots) == 0, route + ": actual plant-food emissions preserve damage without consuming the misfire counter")
			else:
				check(game.projectiles.any(func(p): return bool(p.get("hina_misfire", false))), route + ": actual three-line emissions use their cursed source's third-shot penalty")
	for row in range(6):
		for col in range(9):
			game.grid[row][col] = null
			game.support_grid[row][col] = null
	rt.clear_owner(owner)
	game.projectiles.clear()
	game.grid[cell.x][cell.y] = game._create_plant("repeater", cell.x, cell.y)
	var tail: Dictionary = game.grid[cell.x][cell.y]
	tail.plant_food_mode = "double_storm"
	tail.plant_food_timer = 0.0
	tail.plant_food_charges = 1
	rt.queue_field(owner, cell, "misfire", 1.2)
	rt.update(1.3)
	rt.fields[0].shots = 2
	game._update_plants(0.01)
	check(game.projectiles.size() == 1 and game.projectiles[0].damage == 400.0 and tail.plant_food_mode == "" and tail.plant_food_charges == 0, "The native repeater emits its exact 400-damage final plant-food pea and clears its charges")
	game._update_projectiles(0.0)
	check(game.projectiles.size() == 1 and game.projectiles[0].damage == 400.0 and not bool(game.projectiles[0].get("hina_misfire", false)) and int(rt.fields[0].shots) == 2, "Clearing plant-food state during the final shot cannot misclassify or weaken the 400-damage tail")
	game._stop_bgm()
	if game.music_player != null: game.music_player.stream = null
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	await create_timer(0.3).timeout
	release(game)
	await create_timer(0.15).timeout
	await process_frame
