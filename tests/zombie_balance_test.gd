extends SceneTree
# Balance pass: tougher lawn zombies, fused gear in the campaign, stronger Touhou
# bosses, and fusion ultimates that always land an opening strike.
const Game = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const Native = preload("res://scripts/data/zombie_defs.gd")
const FusionZombies = preload("res://scripts/data/fusion_zombie_defs.gd")
const Balance = preload("res://scripts/data/zombie_balance.gd")
const Equipment = preload("res://scripts/runtime/zombie_equipment.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
var failures := 0


func _initialize():
	call_deferred("_run")


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func level_index(id: String) -> int:
	for i in range(Defs.LEVELS.size()):
		if String(Defs.LEVELS[i].id) == id:
			return i
	return -1


func make_game(index: int = -1, level: Dictionary = {}) -> Control:
	var g = Game.new()
	g.size = Vector2(1600, 900)
	root.add_child(g)
	g.set_process(false)
	if index < 0:
		var base: Dictionary = Defs.LEVELS[0].duplicate(true)
		base.merge({"custom_level": true, "row_count": 5, "events": [{"time": 999.0, "kind": "normal", "row": 2}]}, true)
		base.merge(level, true)
		level = base
	g._begin_level(index, ["peashooter"], level)
	g.battle_paused = false
	g.startup_loading_active = false
	g.page_transition_active = false
	return g


func dispose(g) -> void:
	g.save_dirty = false
	g.free()


func test_stats() -> void:
	var native: Dictionary = Native.ZOMBIES.normal
	check(is_equal_approx(float(Defs.ZOMBIES.normal.health), float(native.health) * Balance.HEALTH), "Lawn zombies endure longer")
	check(is_equal_approx(float(Defs.ZOMBIES.normal.attack_dps), float(native.attack_dps) * Balance.ATTACK), "Lawn zombies bite harder")
	check(is_equal_approx(float(Defs.ZOMBIES.suika_boss.health), float(Native.ZOMBIES.suika_boss.health)), "Bosses keep their own tuning")
	check(float(Defs.ZOMBIES.normal.attack_dps) * 7.5 >= float(Defs.PLANTS.peashooter.health), "A plain zombie finishes a peashooter within about seven seconds")


func test_fusion_catalogue() -> void:
	check(FusionZombies.RECIPES.size() >= 280, "Fused gear catalogue grew: %d" % FusionZombies.RECIPES.size())
	for id in ["brick_flag", "kabuto_newspaper", "brick_ancient_mage", "kabuto_ancient_strategist"]:
		check(FusionZombies.RECIPES.has(id) and Defs.ZOMBIES.has(id), "New helmet recipe exists: " + id)
	var g = make_game()
	for id in ["brick_flag", "kabuto_flag"]:
		g.zombies.clear()
		g._spawn_zombie_at(id, 2, g._cell_center(2, 6).x)
		var z: Dictionary = g.zombies[0]
		check(float(z.headgear_health) == float(FusionZombies.HEADS[z.headgear_kind].health), "Helmet durability applies: " + id)
		check((Equipment.metal_field(z) == "headgear_health") == (id == "kabuto_flag"), "Only the samurai helmet is magnetic: " + id)
	check(not g._visible_almanac_zombies().any(func(kind): return FusionZombies.RECIPES.has(kind)), "Fused gear zombies stay out of the almanac")
	dispose(g)


func fused_share(id: String, hard: bool = false) -> int:
	var level: Dictionary = Defs.LEVELS[level_index(id)].duplicate(true)
	if hard:
		level["hard_mode"] = true
	var g = make_game(level_index(id), level)
	var fused := 0
	for n in range(300):
		if FusionZombies.RECIPES.has(g._campaign_fusion_variant(["normal", "conehead", "buckethead", "flag", "newspaper", "pole_vault"][n % 6])):
			fused += 1
	dispose(g)
	return fused


func test_campaign() -> void:
	check(fused_share("1-5") == 0, "The first world teaches the lawn without fused gear")
	var second := fused_share("2-5")
	var seventh := fused_share("7-5")
	check(second > 0 and seventh > second, "Fused gear grows with the worlds: %d / %d" % [second, seventh])
	check(fused_share("5-6", true) > fused_share("5-6"), "Hard mode brings more fused gear")
	var custom := make_game(-1, {"id": "5-6", "custom_level": true, "events": [{"time": 999.0, "kind": "normal", "row": 2}]})
	check(custom._campaign_fusion_variant("buckethead") == "buckethead", "Custom drills keep their exact zombies")
	dispose(custom)


func test_touhou() -> void:
	# Every tier hits at least 15% harder than before and stays ordered by difficulty.
	var before := {"easy": 0.5, "normal": 0.6, "hard": 0.72, "lunatic": 0.86}
	var last := 0.0
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var now := Difficulty.boss_damage_multiplier({"touhou_difficulty": choice, "events": [{"kind": "reimu_boss"}]})
		check(now >= float(before[choice]) * 1.15 and now > last, "Touhou %s danmaku hits harder and in order (%.2f)" % [choice, now])
		last = now


func test_strike() -> void:
	var g = make_game(-1, {"id": "1-9", "custom_level": true, "row_count": 5, "events": [{"time": 999.0, "kind": "normal", "row": 2}]})
	# Short-ranged pulses cannot reach the far lane; the opening strike still lands.
	var id: String = Fusion.result("echo_fern", "dream_drum")
	var plant: Dictionary = g._create_plant(id, 2, 1)
	plant.sleep_timer = 0
	g.grid[2][1] = plant
	g._spawn_zombie_at("buckethead", 2, g._cell_center(2, 8).x)
	g.zombies[0].base_speed = 0.0
	var before: float = float(g.zombies[0].health) + float(g.zombies[0].get("shield_health", 0.0)) + float(g.zombies[0].get("headgear_health", 0.0))
	g._ensure_plant_fusion().ultimate(plant, 2, 1)
	var after: float = float(g.zombies[0].health) + float(g.zombies[0].get("shield_health", 0.0)) + float(g.zombies[0].get("headgear_health", 0.0))
	check(before - after >= 140.0, "A fusion ultimate always lands its opening strike (%.0f)" % (before - after))
	dispose(g)


func _run() -> void:
	test_stats()
	test_fusion_catalogue()
	test_campaign()
	test_touhou()
	test_strike()
	print("Zombie balance: %d failure(s)" % failures)
	quit(1 if failures else 0)
