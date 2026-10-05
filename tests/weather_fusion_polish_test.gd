extends "res://tests/ancient_world_test.gd"

const Ammo = preload("res://scripts/data/plant_ammo.gd")

func test_shared_weather() -> void:
	var g = make_game("1-1", "rain")
	var rt = g._ensure_ancient_expansion()
	check(rt.current() == "rain", "Explicit weather works outside ancient levels")
	var z = spawn(g, "buckethead", 2, 7.0)
	check(rt.speed_factor(z) < 1.0, "Rain slows ordinary armored enemies outside ancient world")
	check(rt.projectile_factor({"kind":"pea", "source_kind":"peashooter", "ammo_elements":["storm"]}) > 1.0, "Storm graft payload gains rain bonus on a pea source")
	check(is_equal_approx(rt.projectile_factor({"kind":"volcano_seed","volcano_seed":"caldera_lotus"}),0.6), "Rain identifies native volcano fire payloads")
	dispose(g)
	g = make_game("8-1", "snow")
	rt = g._ensure_ancient_expansion()
	check(rt.speed_factor(spawn(g,"normal",2,7.0)) < 0.9, "Snow slows ordinary zombies")
	check(rt.projectile_factor({"kind":"snow_pea", "source_kind":"snow_pea"}) > 1.0, "Snow boosts native frost projectiles")
	check(rt.projectile_factor({"kind":"pea", "ammo_elements":["frost"]}) > 1.0, "Snow boosts grafted frost payloads")
	dispose(g)
	g = make_game("8-1", "storm")
	var p = g._create_plant(Fusion.result("peashooter","thunder_pine"),2,1)
	check(g._ensure_ancient_expansion().cadence_factor(p) > 1.0, "Storm detects any electric fusion component")
	dispose(g)
	g = make_game("8-1", "hail")
	z = spawn(g,"buckethead",2,6.0)
	var hp = float(z.health) + float(z.shield_health)
	step(g,10.0,0.1)
	z = g.zombies[0]
	check(float(z.health) + float(z.shield_health) < hp, "Hail damages ordinary armor through the normal armor pipeline")
	dispose(g)
	g = make_game("8-1", "sandstorm")
	check(g._ensure_ancient_expansion().range_limit(9999.0) < g.CELL_SIZE.x*4.0, "Sandstorm limits direct sight")
	dispose(g)
	g = make_game("8-1", "rainbow")
	check(g._ensure_ancient_expansion().plant_sun_factor() > 1.0, "Rainbow boosts ordinary sun producers")
	check(g._ensure_ancient_expansion().cadence_factor(g._create_plant("peashooter",2,1)) > 1.0, "Rainbow accelerates ordinary plants")
	var charge = g._create_plant("peashooter",2,1)
	g.grid[2][1] = charge
	g._update_ultimate_charges(1.0)
	check(float(charge.ultimate_charge) > 1.0 / float(g._ultimate_profile_for_kind("peashooter").ultimate_charge_time), "Rainbow accelerates ultimate charging")
	dispose(g)

func test_ultimate_releases() -> void:
	var g = make_game("8-1", "clear")
	var id = Fusion.result("dandelion","wallnut")
	var p = g._create_plant(id,2,1)
	g.grid[2][1] = p
	spawn(g,"buckethead",2,6.0)
	g._ensure_plant_fusion().ultimate(p,2,1)
	check(int(p.fusion_skill_echoes) == 2, "Any ranged native chamber gets three ultimate releases")
	var first: int = g.projectiles.size()
	g._ensure_plant_fusion().update(p,0.5,2,1)
	check(g.projectiles.size() > first and int(p.fusion_skill_echoes) == 1, "Second ultimate release executes real attacks")
	p = g._create_plant(Fusion.result("electric_bonk_choy","wallnut"),2,5)
	g.grid[2][5] = p
	g._ensure_plant_fusion().ultimate(p,2,5)
	check(int(p.fusion_skill_echoes) == 2, "Melee lightning chambers also receive follow-up releases")
	dispose(g)

func test_ancient_payloads() -> void:
	var shot = {"kind":"pea", "damage":20.0, "position":Vector2(500,400)}
	Ammo.compose(shot,{"jasmine_tea":1,"golden_milk":1,"electric_bonk_choy":1},"peashooter")
	check("tea" in shot.ammo_elements and "milk" in shot.ammo_elements and "storm" in shot.ammo_elements, "Ancient materials contribute distinct tea, milk and storm payloads")
	var g = make_game("8-1", "clear")
	var z = spawn(g,"normal",2,5.0)
	var x = float(z.x)
	z = g._ensure_projectile_runtime().apply_ammo_status(z,shot)
	check(float(z.get("ancient_weak_until",0)) > g.level_time, "Tea payload weakens ordinary enemies")
	check(float(z.x) > x, "Milk payload knocks enemies back")
	var pushed_x = float(z.x)
	z = g._ensure_projectile_runtime().apply_ammo_status(z,shot)
	check(float(z.x) == pushed_x, "A volley cannot stack milk knockback repeatedly in the same moment")
	var friend = spawn(g,"normal",1,5.0)
	friend.hypnotized = true
	x = float(friend.x)
	friend = g._ensure_projectile_runtime().apply_ammo_status(friend,shot)
	check(float(friend.x) == x and float(friend.get("ancient_weak_until",0)) == 0, "Payloads spare hypnotized allies")
	dispose(g)

func test_direct_fire_weather() -> void:
	var damage: Array = []
	for weather in ["clear","rain"]:
		var g = make_game("8-1",weather)
		var z = spawn(g,"normal",2,6.0)
		z.health = 50000.0
		z.max_health = 50000.0
		g._trigger_jalapeno(2,1)
		damage.append(50000.0-float(g.zombies[0].health))
		dispose(g)
	check(is_equal_approx(float(damage[1]),float(damage[0])*0.6), "Rain weakens direct jalapeno fire as well as projectiles")
	var g = make_game("8-1","rain")
	var z = spawn(g,"normal",2,6.0)
	g._strike_thunder_chain(0,20,10,100,1)
	check(is_equal_approx(200.0-float(g.zombies[0].health),25.0), "Rain strengthens native thunder chain damage")
	z.health = 200.0
	g._strike_tesla_chain(g._cell_center(2,1),0,20,10,100,1)
	check(is_equal_approx(200.0-float(g.zombies[0].health),25.0), "Rain strengthens native tesla chain damage")
	dispose(g)

func test_weather_lifecycle() -> void:
	var g = make_game("8-1","rain")
	g.current_level.weather_schedule = [{"weather":"rain","duration":2.0},{"weather":"snow","duration":3.0},{"weather":"clear","duration":4.0}]
	var rt = g._ensure_ancient_expansion()
	rt.reset()
	rt.update_world(14.0)
	check(rt.current() == "clear" and is_equal_approx(rt.schedule_timer,0.0), "Large ticks traverse every elapsed weather span")
	g._begin_level(-1,["peashooter"],{"id":"weather-reset","title":"","terrain":"day","custom_level":true,"events":[],"start_sun":100})
	check(rt.current() == "clear" and not rt.active(), "Weather does not leak into a later ordinary battle")
	dispose(g)

func _run() -> void:
	test_shared_weather()
	test_ancient_payloads()
	test_ultimate_releases()
	test_direct_fire_weather()
	test_weather_lifecycle()
	print("Weather and ancient payloads: %d failures" % failures)
	quit(1 if failures else 0)
