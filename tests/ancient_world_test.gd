extends SceneTree
# Ancient World: progression, weather, the five plants, three zombies and fusions.
const Game = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const Worlds = preload("res://scripts/data/world_data.gd")
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


func make_game(id: String = "8-1", weather: String = "") -> Control:
	var g = Game.new()
	g.size = Vector2(1600, 900)
	root.add_child(g)
	g.set_process(false)
	g.completed_levels.resize(Defs.LEVELS.size())
	g.completed_levels.fill(false)
	var level: Dictionary = Defs.LEVELS[level_index(id)].duplicate(true)
	level["custom_level"] = true
	level["events"] = [{"time": 999.0, "kind": "normal", "row": 2}]
	if not weather.is_empty():
		level["weather_schedule"] = [{"weather": weather, "duration": 999.0}]
	g._begin_level(-1, ["dandelion", "jasmine_tea", "golden_milk", "samsara_eye", "electric_bonk_choy"], level)
	g.battle_paused = false
	g.startup_loading_active = false
	g.page_transition_active = false
	g.sun_points = 9999
	return g


func dispose(g) -> void:
	g.save_dirty = false
	g.free()


func spawn(g, kind: String, row: int, col: float) -> Dictionary:
	g._spawn_zombie_at(kind, row, g.BOARD_ORIGIN.x + g.CELL_SIZE.x * col)
	return g.zombies.back()


func step(g, seconds: float, frame: float = 1.0 / 30.0) -> void:
	var t := 0.0
	while t < seconds:
		g._process(frame)
		t += frame


func test_progression() -> void:
	var world: Dictionary = Worlds.by_key("ancient")
	check(String(world.key) == "ancient" and Worlds.index_of("ancient") == 7, "Ancient World is the eighth destination")
	var ids := ["8-1", "8-2", "8-3", "8-4", "8-5"]
	var rewards := ["dandelion", "jasmine_tea", "golden_milk", "samsara_eye", "electric_bonk_choy"]
	var previous := level_index("7-20")
	for i in range(ids.size()):
		var index := level_index(ids[i])
		check(index == previous + 1, "Ancient stages follow 7-20 in campaign order: " + ids[i])
		previous = index
		var level: Dictionary = Defs.LEVELS[index]
		check(String(level.terrain) == "ancient" and String(level.unlock_plant) == rewards[i], "Each stage introduces one new plant: " + ids[i])
		check(rewards[i] in level.available_plants, "The new plant is usable in its own stage: " + ids[i])
		check(not Array(level.get("weather_schedule", [])).is_empty(), "Every ancient stage has a weather schedule: " + ids[i])
		check(bool(Defs.PLANTS[rewards[i]].get("ancient_expansion", false)) and FileAccess.file_exists("res://art/vector/plants/%s.svg" % rewards[i]), "New plant has data and an SVG model: " + rewards[i])
	var g = Game.new()
	g.completed_levels.resize(Defs.LEVELS.size())
	g.completed_levels.fill(false)
	check(not g._is_world_unlocked("ancient"), "Ancient World starts locked")
	g.completed_levels[level_index("7-20")] = true
	g.unlocked_levels = level_index("8-1") + 1
	check(g._is_world_unlocked("ancient"), "Clearing 7-20 opens the Ancient World")
	check(g._world_key_for_level(Defs.LEVELS[level_index("8-3")]) == "ancient", "8-x levels belong to the ancient world")
	g.free()
	for kind in ["ancient_samurai", "ancient_mage", "ancient_strategist"]:
		check(Defs.ZOMBIES.has(kind) and kind in Game.ZOMBIE_ALMANAC_ORDER, "Ancient zombie is defined and in the almanac: " + kind)
	var samurai: Dictionary = Defs.ZOMBIES.ancient_samurai
	check(is_equal_approx(float(samurai.health) + float(samurai.shield_health), 2100.0), "Samurai durability is 2100")


func test_weather_schedule_and_effects() -> void:
	var g = make_game("8-2")
	var rt = g._ensure_ancient_expansion()
	check(rt.weather == "clear", "8-2 opens in clear weather")
	step(g, 25.0, 0.25)
	check(rt.weather == "rain", "The schedule turns to rain after its clear span")
	var z := spawn(g, "normal", 2, 6.0)
	check(rt.speed_factor(z) < 1.0, "Rain slows zombies")
	check(is_equal_approx(rt.element_factor("torchwood", true), 0.6), "Rain weakens fire")
	check(rt.element_factor("electric_bonk_choy", false) > 1.0, "Rain strengthens lightning")
	dispose(g)
	g = make_game("8-1", "fog")
	spawn(g, "normal", 2, 7.5)
	check(not g._has_zombie_ahead(2, g._cell_center(2, 0).x), "Fog limits straight shooters to four cells")
	g.zombies[0].x = g._cell_center(2, 3).x
	check(g._has_zombie_ahead(2, g._cell_center(2, 0).x), "Fog still reveals nearby enemies")
	dispose(g)
	g = make_game("8-1", "wind")
	z = spawn(g, "normal", 1, 7.0)
	check(g._current_zombie_speed(z) > float(z.base_speed) * 1.1, "East wind speeds zombies")
	dispose(g)
	g = make_game("8-1", "sunny")
	var before: int = g.sun_points
	g._spawn_sun(Vector2(400, 300), 300, "plant", 50)
	check(int(g.suns.back().value) > 50, "Sunny weather boosts plant sunlight")
	z = spawn(g, "ancient_samurai", 3, 7.0)
	check(g._ensure_ancient_expansion().speed_factor(z) < 1.0, "Samurai swelter in their armor under the sun")
	dispose(g)
	g = make_game("8-1", "storm")
	z = spawn(g, "ancient_samurai", 2, 6.0)
	var armor := float(z.shield_health)
	g._ensure_ancient_expansion().lightning_timer = 0.0
	step(g, 1.2)
	check(float(g.zombies[0].shield_health) < armor, "Storm lightning seeks the samurai's iron armor")
	dispose(g)


func test_dandelion() -> void:
	var g = make_game("8-1", "clear")
	g.grid[2][1] = g._create_plant("dandelion", 2, 1)
	var door := spawn(g, "screen_door", 2, 6.0)
	var health := float(door.health)
	var shield := float(door.get("shield_health", 0.0)) + float(door.get("handheld_health", 0.0))
	step(g, 4.0)
	var hit: Dictionary = g.zombies[0]
	check(float(hit.health) < health, "Spores fall from the sky past the screen door")
	check(is_equal_approx(float(hit.get("shield_health", 0.0)) + float(hit.get("handheld_health", 0.0)), shield), "Spores ignore the handheld shield")
	dispose(g)
	g = make_game("8-1", "clear")
	g.grid[1][1] = g._create_plant("dandelion", 1, 1)
	var balloon := spawn(g, "balloon_zombie", 1, 7.0)
	balloon["balloon_flying"] = true
	step(g, 3.0)
	check(not bool(g.zombies[0].get("balloon_flying", false)) or float(g.zombies[0].health) < float(Defs.ZOMBIES.balloon_zombie.health), "Spores reach flying enemies")
	dispose(g)
	g = make_game("8-1", "wind")
	g.grid[0][1] = g._create_plant("dandelion", 0, 1)
	spawn(g, "normal", 0, 7.0)
	g.grid[0][1].shot_cooldown = 0.0
	g._update_plants(0.05)
	var spores := 0
	for shot in g.projectiles:
		if String(shot.kind) == "ancient_spore": spores += 1
	check(spores == 2, "East wind carries a second spore")
	dispose(g)


func test_jasmine_tea() -> void:
	var g = make_game("8-1", "clear")
	g.grid[2][1] = g._create_plant("jasmine_tea", 2, 1)
	var a := spawn(g, "normal", 1, 3.5)
	var b := spawn(g, "normal", 3, 4.5)
	var far := spawn(g, "normal", 2, 7.5)
	for z in g.zombies: z.base_speed = 0.0
	g.grid[2][1].shot_cooldown = 0.0
	g._update_plants(0.05)
	check(float(g.zombies[0].health) < 200.0 and float(g.zombies[1].health) < 200.0, "Tea reaches the 3x3 block ahead")
	check(is_equal_approx(float(g.zombies[2].health), 200.0), "Tea does not reach beyond three columns")
	var rt = g._ensure_ancient_expansion()
	check(rt.is_corroded(Vector2i(1, g._zombie_cell_col(float(a.x)))), "Poured lawn is corroded")
	step(g, 0.1)
	var weak: Dictionary = g.zombies[0]
	check(float(weak.get("ancient_weak_until", 0.0)) > g.level_time, "Zombies on corroded lawn are weakened")
	var hp := float(weak.health)
	weak = g._apply_zombie_damage(weak, 10.0)
	check(is_equal_approx(hp - float(weak.health), 13.0), "Weakened zombies take 30% more damage")
	dispose(g)


func test_golden_milk() -> void:
	var g = make_game("8-1", "clear")
	g.grid[3][1] = g._create_plant("golden_milk", 3, 1)
	var z := spawn(g, "buckethead", 3, 5.0)
	var start_x := float(z.x)
	var other := spawn(g, "normal", 2, 5.0)
	for zz in g.zombies: zz.base_speed = 0.0
	step(g, 2.0)
	check(g.grid[3][1] == null, "Golden milk is used up after pouring")
	var hit: Dictionary = g.zombies[0]
	var total := float(hit.health) + float(hit.get("shield_health", 0.0)) + float(hit.get("headgear_health", 0.0))
	var full := float(Defs.ZOMBIES.buckethead.health) + float(Defs.ZOMBIES.buckethead.get("shield_health", 0.0))
	check(full - total >= 999.0 or float(hit.health) <= 0.0, "Milk deals 1000 damage along the row")
	check(float(hit.x) > start_x + 60.0, "Milk knocks zombies back")
	check(is_equal_approx(float(g.zombies[1].health), 200.0), "Milk stays in its own row")
	dispose(g)


func test_samsara_eye() -> void:
	var g = make_game("8-1", "clear")
	g.grid[1][2] = g._create_plant("wallnut", 1, 2)
	g.grid[1][2].health = 0.0
	g._remove_dead_plants()
	check(g.grid[1][2] == null, "The wall-nut fell")
	g.grid[3][4] = g._create_plant("peashooter", 3, 4)
	g.grid[3][4].health = 0.0
	g._remove_dead_plants()
	g.grid[3][4] = g._create_plant("sunflower", 3, 4)
	step(g, 2.0)
	g.grid[0][4] = g._create_plant("tallnut", 0, 4)
	g.grid[0][4].health = 0.0
	g._remove_dead_plants()
	g.grid[0][4] = g._create_plant("samsara_eye", 0, 4)
	step(g, 1.5)
	check(g.grid[0][4] != null and String(g.grid[0][4].kind) == "tallnut", "A plant that fell on the eye's own cell returns there")
	var nut = g.grid[1][2]
	check(nut != null and String(nut.kind) == "wallnut" and is_equal_approx(float(nut.health), float(nut.max_health)), "A fallen plant returns at full health")
	var merged = g.grid[3][4]
	check(merged != null and String(merged.get("fusion_kind", "")) == Fusion.result("sunflower", "peashooter"), "A revived plant fuses with the plant now on its cell")
	for r in range(5):
		for c in range(9):
			check(g.grid[r][c] == null or String(g.grid[r][c].kind) != "samsara_eye", "The samsara eye closes after its vision")
	dispose(g)
	g = make_game("8-1", "clear")
	g.grid[2][2] = g._create_plant("wallnut", 2, 2)
	g.grid[2][2].health = 0.0
	g._remove_dead_plants()
	step(g, 11.0, 0.25)
	g.grid[0][0] = g._create_plant("samsara_eye", 0, 0)
	step(g, 1.5)
	check(g.grid[2][2] == null, "Plants that fell more than ten seconds ago stay gone")
	dispose(g)


func test_bonk_choy() -> void:
	var g = make_game("8-1", "clear")
	g.grid[2][4] = g._create_plant("electric_bonk_choy", 2, 4)
	var front := spawn(g, "normal", 2, 4.9)
	var back := spawn(g, "normal", 2, 3.9)
	var bystander := spawn(g, "normal", 1, 5.6)
	for z in g.zombies:
		z.base_speed = 0.0
		z.health = 5000.0
		z.max_health = 5000.0
	step(g, 2.2)
	check(float(g.zombies[0].health) < 5000.0 and float(g.zombies[1].health) < 5000.0, "Bonk choy punches both in front and behind")
	check(float(g.zombies[2].health) < 5000.0, "Every fourth punch releases chain lightning")
	dispose(g)


func test_zombies() -> void:
	var g = make_game("8-1", "clear")
	g.grid[2][2] = g._create_plant("tallnut", 2, 2)
	var hp := float(g.grid[2][2].health)
	var samurai := spawn(g, "ancient_samurai", 2, 2.75)
	step(g, 0.1)
	check(hp - float(g.grid[2][2].health) >= 250.0, "Samurai iaido strikes the first plant it meets")
	dispose(g)
	g = make_game("8-1", "clear")
	for col in range(3):
		g.grid[1][col] = g._create_plant("peashooter", 1, col)
	var mage := spawn(g, "ancient_mage", 1, 6.0)
	mage.base_speed = 0.0
	mage["ancient_mage_timer"] = 0.0
	step(g, 1.5)
	var sheep := 0
	for col in range(3):
		if g._ensure_ancient_expansion().is_sheep(g.grid[1][col]): sheep += 1
	check(sheep == 2, "The mage turns two plants ahead into sheep")
	for col in range(3):
		if g._ensure_ancient_expansion().is_sheep(g.grid[1][col]):
			check(g._plant_charm_blocks_actions(g.grid[1][col]), "Sheep cannot act")
	g.zombies[0].health = 0.0
	g._cleanup_dead_zombies()
	step(g, 0.1)
	sheep = 0
	for col in range(3):
		if g._ensure_ancient_expansion().is_sheep(g.grid[1][col]): sheep += 1
	check(sheep == 0, "Defeating the mage lifts the curse")
	dispose(g)
	g = make_game("8-3", "clear")
	var rt = g._ensure_ancient_expansion()
	var strategist := spawn(g, "ancient_strategist", 2, 6.0)
	var ally := spawn(g, "normal", 2, 6.4)
	strategist["ancient_weather_timer"] = 0.0
	step(g, 0.2)
	check(not rt.override_weather.is_empty() and rt.weather == rt.override_weather, "The strategist borrows a new weather")
	check(rt.speed_factor(g.zombies[0]) == 0.0, "The strategist holds back while allies fight")
	for col in range(5):
		g.grid[2][col] = g._create_plant("wallnut", 2, col)
	g.zombies[1].x = g._cell_center(2, 6).x
	g.zombies[0]["ancient_command_timer"] = 0.0
	step(g, 0.1)
	check(bool(g.zombies[1].get("jumping", false)) or int(g.zombies[1].row) != 2 or float(g.zombies[1].get("ancient_command_until", 0.0)) > g.level_time, "The strategist orders allies toward weaker lanes")
	g.zombies[0].health = 0.0
	g._cleanup_dead_zombies()
	step(g, 0.2)
	check(rt.override_weather.is_empty(), "Borrowed weather fades when the strategist falls")
	dispose(g)


func test_fusions() -> void:
	for pair in [["jasmine_tea", "golden_milk", "jasmine_milk_tea"], ["electric_bonk_choy", "thunder_pine", "thunder_bonk_choy"], ["dandelion", "blover", "breeze_dandelion"], ["samsara_eye", "phoenix_tree", "samsara_phoenix"], ["golden_milk", "coffee_bean", "golden_latte"]]:
		check(Fusion.result(pair[0], pair[1]) == pair[2], "Named ancient recipe: " + pair[2])
	for kind in ["dandelion", "jasmine_tea", "golden_milk", "samsara_eye", "electric_bonk_choy"]:
		check(not Fusion.result(kind, "peashooter").is_empty() and not Fusion.result(kind, kind).is_empty(), "Ancient plant fuses: " + kind)
	check(String(Defs.PLANTS[Fusion.result("golden_milk", "peashooter")].fusion_base) == "peashooter", "One-shot milk never becomes the rootstock")
	var g = make_game("8-1", "clear")
	var id: String = Fusion.result("golden_milk", "wallnut")
	g.grid[2][1] = g._create_plant(id, 2, 1)
	spawn(g, "buckethead", 2, 6.0)
	spawn(g, "buckethead", 1, 6.0)
	for z in g.zombies: z.base_speed = 0.0
	var start_x := float(g.zombies[0].x)
	g.grid[2][1].fusion_channel_timers["golden_milk"] = 0.0
	step(g, 1.5)
	check(float(g.zombies[0].x) > start_x + 40.0, "A milk chamber pours a knockback wave in fusion")
	check(is_equal_approx(float(g.zombies[1].health), float(Defs.ZOMBIES.buckethead.health)) and float(g.zombies[1].get("shield_health", 0.0)) >= float(Defs.ZOMBIES.buckethead.get("shield_health", 0.0)) - 1.0, "The fused milk tide stays in its own row")
	dispose(g)


func test_rootstock_fix() -> void:
	check(String(Defs.PLANTS.thorn_nut.fusion_base) == "wallnut", "Thorn nut is a bitable wall-nut body")
	var spiky: String = Fusion.result("spikeweed", "sunflower")
	check(String(Defs.PLANTS[spiky].fusion_base) == "sunflower", "Spikeweed grafts do not make sun producers unbitable")
	check(String(Defs.PLANTS[Fusion.result("cotton_candy", "peashooter")].fusion_base) == "peashooter", "Cloud-only candy no longer locks a shooter to clouds")
	check(Fusion.result("wallnut_bowling", "peashooter").is_empty(), "The bowling-only nut has no unreachable recipes")
	check(String(Defs.PLANTS[Fusion.result("spikeweed", "spikeweed")].fusion_base) == "spikeweed", "A pure spikeweed hybrid stays low")


func _run() -> void:
	test_progression()
	test_weather_schedule_and_effects()
	test_dandelion()
	test_jasmine_tea()
	test_golden_milk()
	test_samsara_eye()
	test_bonk_choy()
	test_zombies()
	test_fusions()
	test_rootstock_fix()
	print("Ancient world: %d failure(s)" % failures)
	await process_frame # Flush freed audio players before the audio server exits.
	quit(1 if failures else 0)
