extends "res://tests/touhou_encounter_test.gd"

const Level = preload("res://scripts/data/mokou_level_defs.gd")

func fixture(kind: String = "mokou_boss", choice: String = "extra") -> EncounterGame:
	var game := make_game(kind)
	game.active_rows = [0,1,2,3,4,5]
	game.current_level = game.TouhouDifficulty.build_level(Level.LEVEL,choice)
	game._setup_cell_terrain_mask()
	Game.TouhouPhaseRuntime.start(game.zombies[0],game.current_level)
	return game

func tick(game: Control, dt: float = 0.1) -> void:
	super.tick(game,dt)
	game._ensure_mokou_runtime().update(dt)

func _run() -> void:
	for kind in ["hakutaku_boss","mokou_boss"]:
		for choice in ["extra","extra_plus"]:
			var game := fixture(kind,choice)
			var expected: Array = []
			for index in range(game.zombies[0].touhou_encounter.phases.size()):
				for entry in game.zombies[0].touhou_encounter.phases[index]: expected.append({"id":entry[0],"stage":index})
			finish_encounter(game)
			check(game.declarations==expected,"Full %s %s route preserves order under lethal burst damage" % [kind,choice])
			release(game)
	_test_mechanics(false)
	_test_mechanics(true)
	_test_patterns()
	_test_roster()
	print("EX routes, spell identities, hazard timing, cooling, reflection and roster: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_mechanics(mobile: bool) -> void:
	var game := fixture()
	game.size = Vector2(844,390) if mobile else Vector2(1600,900)
	game.mobile_runtime_override = 1 if mobile else 0
	game.board_rows = 6
	game.mode = game.MODE_BATTLE
	game._refresh_battle_layout()
	# Use real collision for mechanics; sequence fixtures deliberately skip it.
	game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
	var boss: Dictionary = game.zombies[0]
	game._trigger_boss_skill(boss)
	game.touhou_danmaku.clear()
	var rt = game._ensure_mokou_runtime()
	game.grid[2][2] = game._create_plant("wallnut",2,2)
	var plant: Dictionary = game.grid[2][2]
	var hp := float(plant.health)
	rt.mark(boss,Vector2i(2,2),"ember",2)
	rt.update(1.99)
	check(plant.health==hp,"Embers have a complete warning before damage")
	rt.update(0.02)
	check(plant.health<hp,"Active ember damages its plant")
	game.projectiles.append({"position":game._cell_center(2,1),"speed":game.CELL_SIZE.x*10,"slow_duration":3.0})
	rt.update(0.15)
	check(rt.marks.is_empty(),"Fast ice projectile sweeps through and extinguishes the ember (mobile=%s)" % mobile)
	game.projectiles.clear()
	rt.mark(boss,Vector2i(2,2),"archive",2)
	rt.update(1.99)
	check(not rt.plant_stilled(2,2),"Archive never seals before warning")
	rt.update(0.02)
	check(rt.plant_stilled(2,2) and not rt.plant_stilled(2,3),"Archive seals only marked cells")
	rt.update(3.0)
	check(not rt.plant_stilled(2,2),"History seal expires")
	for side in [-1,1]:
		rt.reset()
		rt.rally(boss,2,side)
		var initial = Vector2(rt.rallies[0].position)
		hp = float(plant.health)
		rt.update(1.59)
		check(rt.rallies[0].position==initial and plant.health==hp,"Rally waits for route preview")
		rt.update(2.5)
		check(plant.health<hp and rt.rallies[0].leg==1,"Both directions use swept collision and bounce at paddle")
		hp = float(plant.health)
		rt.update(0.4)
		check(plant.health==hp,"Bounce has another warning before returning")
	rt.reset()
	game.grid[2][1] = game._create_plant("mirror_reed",2,1)
	rt.rally(boss,2,-1)
	rt.update(2.2)
	check(rt.rallies.is_empty() and game.touhou_danmaku.bullets.any(func(b):return b.get("reflected",false)),"Mirror returns an actual damaging projectile")
	rt.rally(boss,2,1)
	rt.mark(boss,Vector2i(2,2),"ember")
	game.battle_paused = true
	rt.update(3)
	check(rt.rallies[0].age==0 and rt.marks[0].age==0,"Pause freezes both hazard clocks")
	game.battle_paused = false
	game.boss_time_stop_timer = 1
	rt.update(3)
	check(rt.rallies[0].age==0,"Time stop freezes rally")
	game.boss_time_stop_timer = 0
	game._trigger_ice_shroom(2,2)
	check(rt.rallies.is_empty() and rt.marks.is_empty(),"Actual Ice-shroom clears the fire hazards")
	rt.cast(boss,"mokou_double_rally")
	check(rt.rallies.size()==2 and rt.rallies[0].side == -rt.rallies[1].side,"EX+ double rally starts from opposing sides")
	rt.clear_owner(int(boss.uid))
	check(rt.rallies.is_empty(),"Phase/death cleanup clears paddles")
	release(game)

func _test_patterns() -> void:
	var game := fixture()
	var dm = game.touhou_danmaku
	var signatures: Array = []
	for entry in Spells.Mokou.MOKOU:
		dm.clear()
		var c = {"owner":1,"kind":"mokou_boss","pattern":entry[2],"center":game._cell_center(2,7),"wave":0,"phase":0,"age":0.0,"duration":18.0}
		dm.MokouDanmaku.emit(dm,c)
		var signature: Array = []
		for b in dm.bullets: signature.append([b.position,b.velocity,b.shape,b.get("freeze_at",-1),b.get("bounces",0)])
		check(not signature.is_empty() and not signatures.has(signature),"Distinct original geometry: "+entry[2])
		signatures.append(signature)
		check(dm.bullets.size()<=dm.MAX_BULLETS and dm.beams.size()<=dm.MAX_BEAMS,"Bounded pattern budget")
	var ball = {"imperishable":true,"velocity":Vector2(100,0),"age":0.6}
	dm.MokouDanmaku.advance_bullet(ball,0.1)
	check(ball.velocity.x<0,"Imperishable contracts before release")
	ball.age = 1.3
	dm.MokouDanmaku.advance_bullet(ball,0.1)
	check(ball.velocity.x>0 and ball.released,"Imperishable releases after convergence")
	release(game)

func _test_roster() -> void:
	var game := fixture("mokou_boss","extra_plus")
	for enemy in ["balloon_zombie","digger_zombie","star_fairy","rabbit_airship","catapult_zombie","basketball","wizard_zombie"]:
		var count = game.zombies.size()
		game._spawn_zombie(enemy,2,true)
		check(game.zombies.size()==count,"Central gate rejects "+enemy)
	for n in range(30):
		check(game._support_spawn_kind("flag",n,n*3) in Level.ENEMIES,"Extra/support wave respects roster")
		game._spawn_hover_boss_reinforcement("mokou_boss",3)
	check(game.zombies.all(func(z):return z.kind=="mokou_boss" or z.kind in Level.ENEMIES),"Boss reinforcement respects roster")
	release(game)
