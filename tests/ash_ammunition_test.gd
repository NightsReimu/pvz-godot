extends "res://tests/plant_fusion_test.gd"

func test_embedded(pair: String, radius: float) -> void:
	var g = make_game()
	var id: String = Fusion.result(pair,"peashooter")
	var p: Dictionary = g._create_plant(id,2,2); g.grid[2][2] = p
	var center: Vector2 = g._cell_center(2,2)
	for offset in [180,210,300]:
		g._spawn_zombie_at("normal",2,center.x+offset)
		g.zombies.back().health = 10000
	g._spawn_zombie_at("normal",2,center.x+200)
	g.zombies.back().health = 10000; g.zombies[3] = g._hypnotize_zombie(g.zombies[3])
	ready_weapons(g,2,2,true); g._update_plants(0.1)
	check(g.projectiles.size() == 1 and g.projectiles[0].kind == "pea", pair+" is embedded in the native pea, without a separate bomb")
	if not g.projectiles.is_empty():
		var shot: Dictionary = g.projectiles[0]
		check(float(shot.damage) <= 44, "Ash bonus is bounded instead of copying a one-shot")
		check(is_equal_approx(float(shot.get("ash_radius",0)),radius),pair+" uses its own small payload radius")
	for n in range(80): g._update_projectiles(0.02)
	check(float(g.zombies[0].health) < 10000,"Payload hits its primary target")
	if radius > 0: check(float(g.zombies[1].health) < 10000,"Small blast hits a nearby enemy")
	else: check(float(g.zombies[0].get("corrode_dps",0)) > 0,"Pepper ammunition applies real burning")
	check(float(g.zombies[2].health) == 10000 and float(g.zombies[3].health) == 10000,"Payload respects reach and hypnotized allies")
	g.projectiles.clear(); g._ensure_plant_fusion().ultimate(p,2,2)
	check(not g.projectiles.any(func(s): return s.has("fusion_blast")),"Embedded ash ultimate strengthens the native ammunition without a charged bomb")
	dispose(g)

func test_lob_and_volley() -> void:
	var g = make_game()
	var center: Vector2 = g._cell_center(2,2)
	g.grid[2][2] = g._create_plant(Fusion.result("cherry_bomb","cabbage_pult"),2,2)
	for offset in [220,248]:
		g._spawn_zombie_at("normal",2,center.x+offset); g.zombies.back().health = 10000
	ready_weapons(g,2,2,true); g._update_plants(0.1)
	check(g.projectiles.size() == 1 and g.projectiles[0].has("arc_target"),"Cherry cabbage keeps its original arc")
	for n in range(150): g._update_projectiles(0.02)
	check(g.zombies[1].health < 10000,"Native lob landing triggers a small ash splash")
	g.projectiles.clear(); g.grid[2][2] = g._create_plant(Fusion.result("cherry_bomb","gatling_pea"),2,2)
	ready_weapons(g,2,2,true); g._update_plants(0.1)
	check(g.projectiles.size() == 4,"Gatling retains its four heads")
	var damage := 0.0
	for shot in g.projectiles: damage += float(shot.damage)
	check(damage <= 104,"Four heads share a bounded ash bonus instead of four bombs")
	check(float(Native.PLANTS.cherry_bomb.damage) == 1800,"Unfused disposable cherry keeps its original damage")
	dispose(g)

func test_armor_hidden_and_recursive() -> void:
	var g = make_game()
	var center: Vector2 = g._cell_center(2,2)
	g._spawn_zombie_at("screen_door",2,center.x+170)
	g._spawn_zombie_at("digger_zombie",2,center.x+180)
	var door: Dictionary = g.zombies[0]
	var door_hp := float(door.health)
	var shield_hp := float(door.shield_health)
	var hidden_hp := float(g.zombies[1].health)
	var runtime = g._ensure_projectile_runtime()
	var shot := {"ash_radius":48.0,"ash_damage":12.0,"ash_hits":[]}
	var hit: Vector2 = g._zombie_target_point(door,center)
	runtime.ash_impact(shot,hit)
	check(float(door.health) == door_hp and float(door.shield_health) < shield_hp,"Ash splash obeys native shield damage instead of bypassing armor")
	check(float(g.zombies[1].health) == hidden_hp,"Ash splash cannot uncover a tunneling digger")
	var after := float(door.shield_health)
	runtime.ash_impact(shot,hit)
	check(float(door.shield_health) == after,"Returning/piercing projectile cannot repeat its splash on the same enemy")
	var id: String = Fusion.result(Fusion.result("cherry_bomb","peashooter"),"doom_shroom")
	var p: Dictionary = g._create_plant(id,2,2); g.grid[2][2] = p
	ready_weapons(g,2,2,true); g._update_plants(0.1)
	check(g.projectiles.size() == 1 and float(g.projectiles[0].damage) <= 44,"Recursive ash ingredients share the capped payload budget")
	check(not g.projectiles.any(func(s): return s.has("fusion_blast")),"Recursive fusion does not restore a suppressed bomb channel")
	dispose(g)

func _run() -> void:
	test_embedded("cherry_bomb",48)
	test_embedded("doom_shroom",64)
	test_embedded("jalapeno",0)
	test_lob_and_volley()
	test_armor_hidden_and_recursive()
	print("Ash ammunition: %d failure(s)" % failures)
	quit(1 if failures else 0)
