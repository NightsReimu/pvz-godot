extends "res://tests/plant_fusion_test.gd"
const Art = preload("res://scripts/ui/fusion_plant_art.gd")
const Visuals = preload("res://scripts/ui/plant_fusion_visuals.gd")

func test_weapon_and_skill_contracts():
	var g = make_game()
	for passive in ["wallnut","coffee_bean","sunflower","plantern","pumpkin"]:
		var id: String = g._fusion_result(passive,"peashooter")
		g.grid[2][2] = g._create_plant(id,2,2)
		ready_weapons(g,2,2)
		g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+300)
		g._update_plants(0.1)
		check(not g.projectiles.is_empty(),"A passive base cannot shorten a ranged hybrid's range: "+passive)
		for frame in range(40): g._update_projectiles(0.05)
		check(float(g.zombies[0].health) < float(g.zombies[0].max_health),"Ranged fusion projectiles actually hit: "+passive)
		g.zombies.clear(); g.projectiles.clear()
	g.grid[2][2] = g._create_plant("fusion_healing_gourd",2,2)
	g.grid[2][1] = g._create_plant("peashooter",2,1)
	g._ensure_plant_fusion().ultimate(g.grid[2][2],2,2)
	check(g._plant_cadence_delta(1,2,1) > 1,"Support ultimate accelerates native attacks")
	g._update_plants(12)
	check(float(g.grid[2][1].fusion_haste_timer) == 0 and is_equal_approx(g._plant_cadence_delta(1,2,1),1),"Native haste expires instead of remaining permanent")
	dispose(g)

func test_skill_payloads():
	var g = make_game()
	var representatives := {}
	for id in Fusion.DEFINITIONS:
		for skill in Fusion.DEFINITIONS[id].fusion_skills:
			if not representatives.has(skill): representatives[skill] = id
	for skill in Fusion.skill_names():
		check(representatives.has(skill),"Each designed skill has an actual fusion: "+skill)
		if not representatives.has(skill): continue
		var id: String = representatives[skill]
		g.zombies.clear(); g.effects.clear(); g.projectiles.clear(); g.rollers.clear(); g.suns.clear()
		var p: Dictionary = g._create_plant(id,2,2)
		p.sleep_timer = 0; p.health *= 0.5
		g.grid[2][2] = p; g.grid[2][1] = g._create_plant("fume_shroom",2,1)
		g.grid[2][1].sleep_timer = 10; g.grid[2][1].health *= 0.3
		g._spawn_zombie_at("bucket_screen_door",2,g._cell_center(2,2).x+100)
		g.zombies[0].health = 10000
		var enemy_before: Dictionary = g.zombies[0].duplicate(true)
		g._ensure_plant_fusion().ultimate(p,2,2)
		var skills_drawn := {}
		for e in g.effects:
			if e.get("shape","") == "fusion_skill": skills_drawn[e.skill] = true
		check(skills_drawn.has(skill),"Ultimate animation matches its skill payload: "+skill)
		if skill == "solar": check(g.suns.size() >= 3,"Solar ultimate creates collectible sunlight")
		if skill in ["garden","renewal","awakening","bastion","spring"]: check(g.grid[2][1].health > g.grid[2][1].max_health*0.3 and g.grid[2][1].fusion_haste_timer > 0,"Garden skills improve nearby native plants: "+skill)
		if skill == "awakening": check(g.grid[2][1].sleep_timer == 0,"Awakening wakes the sleeping mushroom")
		if skill in ["magnetic","rail_storm"]: check(g.zombies[0].headgear_health == 0 and g.zombies[0].handheld_health == 0,"Magnetic ultimate strips both metal layers")
		if skill == "dream": check(not g._is_enemy_zombie(g.zombies[0]),"Dream ultimate actually recruits a living zombie")
		if skill == "spirits": check(g.zombies.size() >= 4,"Ghost parade calls its three available friendly spirits")
		if skill == "blizzard": check(float(g.zombies[0].frozen_timer) >= 1,"Blizzard freezes the enemy")
		if skill in ["inferno","miasma","steam"]: check(float(g.zombies[0].corrode_timer) >= 8,"Elemental ultimate leaves real damage over time: "+skill)
		if skill == "lightning": check(float(g.zombies[0].frozen_timer) > 0,"Lightning stuns the enemy")
		if skill == "beacon": check(float(g.zombies[0].revealed_timer) >= 10,"Beacon reveals enemies across the board")
		if skill == "constellation":
			check(g.projectiles.any(func(shot): return bool(shot.get("fusion_ultimate",false))),"Spread ultimate preserves real native projectiles")
		if skill == "meteor": check(g.projectiles.any(func(shot): return shot.has("arc_target") or shot.get("kind","") == "moon_meteor") or g.zombies[0] != enemy_before,"Lobbed ultimate preserves the native delivery path: "+id)
	g.zombies.clear()
	var wind: String = g._fusion_result("blover","peashooter")
	var plant: Dictionary = g._create_plant(wind,2,2)
	g._spawn_zombie_at("balloon_zombie",2,g._cell_center(2,2).x+400)
	g._ensure_plant_fusion().ultimate(plant,2,2)
	check(not bool(g.zombies[0].get("balloon_flying",false)),"Wind ultimate reaches and grounds flying enemies")
	g.zombies.clear()
	var roots: String = g._fusion_result("root_snare","root_snare")
	plant = g._create_plant(roots,2,2)
	g._spawn_zombie_at("normal",0,g._cell_center(0,8).x)
	g._ensure_plant_fusion().ultimate(plant,2,2)
	check(float(g.zombies[0].get("rooted_timer",0)) >= 4,"Root net controls distant lanes as described")
	dispose(g)

func test_recursive_art():
	var g = make_game()
	var id: String = g._fusion_result("pea_bastion","winter_melon")
	for ingredient in ["coffee_bean","torchwood","hypno_shroom","healing_gourd"]:
		var previous: String = id
		id = g._fusion_result(id,ingredient)
		check(not id.is_empty() and Defs.PLANTS.has(id),"Runtime-grown fusion is registered for normal game use")
		if id.is_empty(): continue
		var svg: String = Art.svg_for(id,Defs.PLANTS[id])
		var pixels := Image.new()
		check(pixels.load_svg_from_string(svg) == OK and not pixels.is_empty(),"Recursive fusion has a rasterizable independent SVG")
		check(svg != Art.svg_for(previous,Defs.PLANTS[previous]),"Each recursive stage changes its model geometry")
		check(Visuals.texture_for(id) != null,"Runtime-grown SVG is usable by preview and board")
	check(Visuals.textures.size() <= Visuals.MAX_TEXTURES,"Fusion texture cache is bounded")
	check(not g._visible_almanac_plants().has(id),"A grown fusion never enters the seed almanac")
	g.almanac_tab = "plants"; g.almanac_selected_kind = id
	g._ensure_almanac_selection()
	check(not bool(Defs.PLANTS[g.almanac_selected_kind].get("fusion_only",false)),"Old fusion detail selection repairs to a native seed")
	check(not Defs.PLANTS[id].fusion_skills.is_empty(),"Inherited ultimates remain registered independently of the almanac")
	var support: String = g._fusion_result("healing_gourd","peashooter")
	g.grid[2][2] = g._create_plant("peashooter",2,2)
	g.support_grid[2][2] = g._create_plant("flower_pot",2,2)
	g.grid[2][3] = g._create_plant(support,2,3)
	check(g._ensure_plant_fusion().merge_cells(Vector2i(2,3),Vector2i(2,2)),"A base fusion can join a plant on an existing pot")
	check(g.support_grid[2][2] != null and g.grid[2][2] != null,"Merging preserves the native supporting pot")
	dispose(g)

func _run():
	var g = make_game()
	var absent := 0
	for a in Native.PLANTS:
		for b in Native.PLANTS:
			if String(a) > String(b) or a in Fusion.EXCLUDED or b in Fusion.EXCLUDED or a in Fusion.UNOBTAINABLE or b in Fusion.UNOBTAINABLE: continue
			if g._fusion_result(a,b).is_empty(): absent += 1
	check(absent == 0,"Any two native plants must fuse; missing pairs: %d" % absent)
	var grown: String = g._fusion_result("pea_bastion","winter_melon")
	check(not grown.is_empty(),"Two distinct fusion forms must combine")
	if not grown.is_empty():
		check(not g._fusion_result(grown,"coffee_bean").is_empty(),"A mixed grown form can keep fusing")
		check(g._fusion_result("winter_melon","pea_bastion") == grown,"Recursive mixed forms are symmetric")
	dispose(g)
	for id in ["fusion_healing_gourd","fusion_coffee_bean","fusion_torchwood","sun_pea"]:
		g = make_game()
		var p: Dictionary = g._create_plant(id,2,2)
		p.sleep_timer = 0; p.health *= 0.5; p.ultimate_charge = 1
		if String(p.kind) in Fusion.SUPPORTS: g.support_grid[2][2] = p
		else: g.grid[2][2] = p
		g.grid[2][1] = g._create_plant("peashooter",2,1); g.grid[2][1].health *= 0.25
		g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+260)
		var before := [p.health,g.grid[2][1].health,g.zombies[0].health,g.suns.size()]
		check(g._try_activate_ultimate(2,2),"Actual ultimate activation: "+id)
		g._update_plants(0.2); g._update_projectiles(2.0)
		var result := [p.health,g.grid[2][1].health,g.zombies[0].health,g.suns.size()]
		check(result != before or float(g.grid[2][1].get("fusion_haste_timer",0)) > 0,"Ultimate must change actual gameplay, not only draw a ring: "+id)
		if id == "sun_pea": check(g.suns.size() > 0,"An attacking sunlight hybrid still produces sunlight in its ultimate")
		dispose(g)
	g = make_game()
	g.grid[2][2] = g._ensure_plant_fusion().combined("holy_pumpkin",g._create_plant("holy_flower",2,2))
	g._update_plants(0.1)
	check(g.grid[2][2] != null,"A pumpkin-based fusion must not vanish because the input has no shell armor")
	dispose(g)
	test_weapon_and_skill_contracts()
	test_skill_payloads()
	test_recursive_art()
	print("Universal fusion behavior: %d failure(s)" % failures)
	quit(1 if failures else 0)
