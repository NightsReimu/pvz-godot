extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

class ObservedGame extends PreviewGame:
	var declared: Array = []
	func _trigger_boss_skill(boss: Dictionary) -> Dictionary:
		declared.append(GameScript.TouhouSpellDefs.card_for(boss, current_level).id)
		return super._trigger_boss_skill(boss)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var base: Dictionary = {}
	for level in GameScript.Defs.LEVELS:
		if level.id == "4-21": base = level.duplicate(true)
	check(not base.is_empty(), "4-21 must exist before exercising its actual battle flow")
	if base.is_empty():
		quit(1)
		return
	base.custom_level = true
	for rank in range(4):
		var choice: String = ["easy", "normal", "hard", "lunatic"][rank]
		var game := ObservedGame.new()
		game.size = Vector2(1600, 900)
		root.add_child(game)
		var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
		game._begin_level(-1, ["sunflower", "repeater", "wallnut", "plantern", "umbrella_leaf", "melon_pult", "healing_gourd"], level)
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		check(game.active_rows == [0, 1, 2, 3, 4, 5] and game.water_rows.is_empty(), choice + ": all six terrace lanes are land")
		check(not game._is_fog_level() and not game._is_pool_level(), "The rainy ravine does not inherit fog or pool rules")
		check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "The supplied road track plays before either boss")
		var preview: Dictionary = game._selection_level_preview_style(level)
		check(int(preview.row_count) == 6 and preview.water_rows.is_empty() and String(preview.label).contains("玄武"), "The level preview identifies six dry basalt terraces")
		if choice != "lunatic": game.active_cards[0] = "repeater"
		game._handle_primary_click(game._card_rect(0).get_center())
		game._handle_primary_click(game._cell_center(5, 1))
		check(game.grid[5][1] != null, choice + ": real seed controls work on the sixth lane")
		game._spawn_frozen_branch_midboss()
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		var roads: Array = game.zombies.filter(func(z): return z.kind == "nitori_boss" and bool(z.get("touhou_final_preview", false)))
		check(roads.size() == 1, "The actual road-flow spawner creates Nitori's weaker incarnation")
		if roads.is_empty():
			await _release_game(game)
			continue
		var road: Dictionary = roads.back()
		var rt = game._ensure_nitori_runtime()
		check(bool(road.touhou_road_boss) and bool(road.get("touhou_road_spell", false)), "Road Nitori is a weaker same-character encounter with a mandatory spell")
		check(road.touhou_encounter.phases == game.TouhouSpellDefs.Nitori.road_phases(level), "The road keeps the camouflaged nonspell and one canonical card")
		check(rt.boss_camouflaged(road) and not rt.boss_revealed(road), "Road Nitori arrives inside optical camouflage")
		check(game._boss_health_bar_layout(road).segments == 1 and game.current_bgm_path == level.boss_intro_bgm, "Road Nitori keeps the stage track and a single live bar")
		var hp_before := float(road.health)
		game._apply_zombie_damage(road, 100.0, 0.0)
		check(is_equal_approx(hp_before - float(road.health), 70.0), "Unlit camouflage takes 70% damage")
		var lantern_col := 3
		game.grid[int(road.row)][lantern_col] = game._create_plant("plantern", int(road.row), lantern_col)
		hp_before = float(road.health)
		game._apply_zombie_damage(road, 100.0, 0.0)
		check(is_equal_approx(hp_before - float(road.health), 100.0) and rt.boss_revealed(road), "A plantern in her lane exposes the camouflage")
		game.grid[int(road.row)][lantern_col] = null
		var road_uid := int(road.uid)
		var road_hp := float(road.max_health)
		for frame in range(20):
			game.level_time += 0.1
			game._ensure_zombie_runtime().update_boss(road, 0.1)
			rt.update(0.1)
			if game.touhou_danmaku != null: game.touhou_danmaku.update(0.1)
		check(game.declared.size() >= 1 and String(game.declared[0]).ends_with("nonspell"), "Camouflaged Nitori strikes with her nonspell before declaring")
		check(game.touhou_danmaku != null and game.touhou_danmaku.bullets.size() > 0, "The hidden nonspell actually emits water shots")
		check(game._boss_cast_status(road).text.contains("光学迷彩"), "The HUD names the camouflage attack")
		game._apply_zombie_damage(road, 10000000, 0, 0, true)
		check(not bool(road.touhou_encounter.complete) and road.health > 0, "Burst damage cannot skip the road's declared card")
		for frame in range(1200):
			game._apply_zombie_damage(road, 10000000, 0, 0, true)
			game.level_time += 0.1
			game._ensure_zombie_runtime().update_boss(road, 0.1)
			if game.touhou_danmaku != null: game.touhou_danmaku.update(0.1)
			rt.update(0.1)
			game._update_effects(0.1)
			if bool(road.touhou_encounter.complete): break
		var road_card: Array = game.TouhouSpellDefs.Nitori.road_card(level)
		check(bool(road.touhou_encounter.complete), "The road card finishes and permits retreat")
		check(game.declared.has(road_card[0]) and game.declared.find(road_card[0]) > 0, "The road declares its canonical card after the camouflage attack")
		game._cleanup_dead_zombies()
		game._update_frozen_branch_flow()
		check(not game.zombies.any(func(z): return z.kind == "nitori_boss" and z.health > 0), "Defeated road Nitori retreats before her full incarnation")
		check(game.current_bgm_path == level.boss_intro_bgm, "The stage track continues after the road retreats")
		game._spawn_zombie_at("nitori_boss", 2, game._boss_anchor_x("nitori_boss"), true)
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		var boss: Dictionary = game.zombies.filter(func(z): return z.kind == "nitori_boss" and not bool(z.get("touhou_final_preview", false))).back()
		check(int(boss.uid) != road_uid and boss.max_health > road_hp * 8 and boss.health == boss.max_health, "Final Nitori has a fresh UID and full strengthened health")
		check(not bool(boss.touhou_road_boss) and not bool(boss.get("touhou_road_spell", false)) and not rt.boss_camouflaged(boss), "The finale inherits neither the road role nor permanent camouflage")
		check(boss.touhou_encounter.phases.size() == rank + 6, "The finale uses six through nine spell phases")
		check(game.current_bgm_path == level.boss_bgm and game.music_player.playing, "Only final Nitori starts the supplied ending track")
		check(game._boss_cast_status(boss).text.contains("非符"), "Final Nitori begins with her readable opening nonspell")
		var enemies_before: int = game.zombies.size()
		boss.rumia_reinforcement_timer = 0.0
		game._update_zombies(0.1)
		check(game.zombies.size() > enemies_before and game.zombies.any(func(z): return String(z.kind) in level.enemy_whitelist and z.health > 0), "Ravine enemies keep appearing during the live fight")
		for frame in range(24): check(game._try_get_boss_frame_texture("nitori_boss", frame) != null, "The supplied Nitori pose loads " + str(frame))
		_test_counters(game, boss, rank)
		await _release_game(game)
	print("Nitori real road/finale identities, camouflage road, four modes, six-row input, BGM and counterplay: %d failure(s)" % failures)
	call_deferred("quit", 1 if failures else 0)


func _test_counters(game: Control, boss: Dictionary, rank: int) -> void:
	var rt = game._ensure_nitori_runtime()
	var owner := int(boss.uid)
	for row in range(6):
		for col in range(9):
			game.grid[row][col] = null
	# Water cannon: damage and soak, the umbrella shelter and both cleanses.
	game.grid[4][2] = game._create_plant("repeater", 4, 2)
	# This fixture isolates soaking/cleansing, with enough HP to survive the
	# strengthened cannon on all four difficulties; real damage has its own suite.
	game.grid[4][2].health = 2000.0
	game.grid[4][2].max_health = 2000.0
	game.grid[4][6] = game._create_plant("wallnut", 4, 6)
	game.grid[1][3] = game._create_plant("repeater", 1, 3)
	game.grid[0][3] = game._create_plant("umbrella_leaf", 0, 3)
	rt.queue_jet(owner, 4)
	rt.queue_jet(owner, 1)
	var hp_repeater := float(game.grid[4][2].health)
	var hp_sheltered := float(game.grid[1][3].health)
	game.battle_paused = true
	game._process(1.0)
	check(float(rt.jets[0].age) == 0.0, "Battle pause freezes the water-cannon warning")
	game.battle_paused = false
	for i in range(30): rt.update(0.1)
	check(float(game.grid[4][2].health) < hp_repeater and rt.action_factor(4, 2) < 1.0, "An unsheltered plant is hit and soaked by the jet")
	check(is_equal_approx(float(game.grid[1][3].health), hp_sheltered) and rt.action_factor(1, 3) == 1.0, "A neighbouring umbrella leaf blocks the jet")
	# A soaked torchwood steams and cannot light peas until it dries.
	game.grid[3][4] = game._create_plant("torchwood", 3, 4)
	var pea := {"kind": "pea", "row": 3, "position": game._cell_center(3, 4), "previous_position": game._cell_center(3, 4) - Vector2(8, 0), "damage": 20.0, "speed": 300.0}
	rt.soaked[Vector2i(3, 4)] = rt.SOAK_DURATION
	game._ensure_projectile_runtime().apply_torchwood_to_projectile(pea)
	check(not bool(pea.get("fire", false)) and float(pea.damage) == 20.0, "A soaked torchwood cannot ignite peas")
	rt.soaked.erase(Vector2i(3, 4))
	game._ensure_projectile_runtime().apply_torchwood_to_projectile(pea)
	check(bool(pea.get("fire", false)), "A dry torchwood ignites peas again")
	game.grid[3][4] = null
	game._ensure_plant_food_runtime().activate(4, 2)
	check(rt.action_factor(4, 2) == 1.0, "Plant food clears its soaked row")
	rt.queue_jet(owner, 4)
	for i in range(30): rt.update(0.1)
	check(rt.action_factor(4, 6) < 1.0, "The jet soaks the next plant along its row again")
	game._update_ultimate_charges(120.0)
	check(game._try_activate_ultimate(4, 6) and rt.action_factor(4, 6) == 1.0, "An earned ultimate clears its soaked row")
	# Cucumber bait: plant kills pay sun once; an eater heals and hardens.
	rt.clear_owner(owner)
	rt.queue_bait(owner, Vector2i(2, 5))
	rt.queue_bait(owner, Vector2i(3, 5))
	rt.update(1.3)
	var baits: Array = game.zombies.filter(func(z): return z.kind == "nitori_cucumber" and z.health > 0)
	check(baits.size() == 2, "Warned cells grow two targetable cucumbers")
	check(game._find_lane_target_ignore_fog(2, game._cell_center(2, 0).x, 2000.0) >= 0, "A cucumber draws its lane's fire")
	var suns_before: int = game.suns.size()
	game._apply_zombie_damage(baits[0], 100000.0, 0.0)
	game._cleanup_dead_zombies()
	check(game.suns.size() == suns_before + 1 and int(game.suns.back().get("value", 0)) == 15, "A plant-broken cucumber returns 15 sun once")
	game._spawn_zombie_at("kedama", int(baits[1].row), float(baits[1].x) + 4.0, true)
	var eater: Dictionary = game.zombies.back()
	eater.health = float(eater.max_health) * 0.5
	rt.update(0.05)
	check(float(eater.health) > float(eater.max_health) * 0.7 and float(eater.get("nitori_power_until", 0.0)) > game.level_time, "A zombie that eats the cucumber heals and gains kappa power")
	suns_before = game.suns.size()
	game._cleanup_dead_zombies()
	check(game.suns.size() == suns_before, "An eaten cucumber never pays sun")
	var hp := float(eater.health)
	game._apply_zombie_damage(eater, 100.0, 0.0)
	check(is_equal_approx(hp - float(eater.health), 80.0), "Kappa power reduces incoming damage to 80%")
	# Camouflage squad: hidden from lane targeting until lit, hit or close.
	var count: int = rt.spawn_squad(owner, 2)
	var squad: Array = game.zombies.filter(func(z): return bool(z.get("nitori_camo", false)) and z.health > 0)
	check(count == 2 and squad.size() >= 2, "The camouflage card fields a fused squad")
	var unit: Dictionary = squad[0]
	check(game._is_hidden_from_lane_attacks(unit), "A camouflaged unit is hidden from lane targeting")
	game._apply_zombie_damage(unit, 1.0, 0.0)
	check(not game._is_hidden_from_lane_attacks(unit), "A hit briefly reveals the camouflage")
	unit.revealed_timer = 0.0
	check(game._is_hidden_from_lane_attacks(unit), "Camouflage resumes after the reveal fades")
	game.grid[int(unit.row)][1] = game._create_plant("plantern", int(unit.row), 1)
	check(not game._is_hidden_from_lane_attacks(unit), "A plantern lights the camouflaged lane")
	game.grid[int(unit.row)][1] = null
	unit.x = game._cell_center(int(unit.row), 2).x
	check(not game._is_hidden_from_lane_attacks(unit), "Rain breaks the camouflage near the house")
	rt.queue_jet(owner, 0)
	rt.queue_bait(owner, Vector2i(5, 6))
	game._trigger_boss_phase_shift(boss, 1)
	check(rt.jets.is_empty() and rt.baits.is_empty(), "A real phase shift clears queued jets and bait warnings")

func _release_game(game: Control) -> void:
	game._stop_bgm()
	game.music_player.stream = null
	game.save_dirty = false
	await create_timer(0.3).timeout
	game.free()
	await process_frame
