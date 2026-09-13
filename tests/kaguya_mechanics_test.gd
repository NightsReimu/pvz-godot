extends "res://tests/touhou_encounter_test.gd"

func fixture(choice: String = "easy") -> EncounterGame:
	var game := make_game("kaguya_boss")
	game.active_rows = [0,1,2,3,4,5]
	game.current_level = {"id": "3-24-b", "terrain": "eirin_eternal_corridor", "events": [{"kind": "kaguya_boss"}], "touhou_difficulty": choice}
	game._setup_cell_terrain_mask()
	Game.TouhouPhaseRuntime.start(game.zombies[0],game.current_level)
	return game

func tick(game: Control, dt: float = 0.1) -> void:
	super.tick(game, dt)
	game._ensure_eirin_runtime().update(dt)
	game._ensure_kaguya_runtime().update(dt)

func _run() -> void:
	_test_rewind()
	_test_treasures()
	_test_damage_and_cleanup()
	_test_rosters()
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := fixture(choice)
		finish_encounter(game)
		check(game.zombies[0].touhou_encounter.complete, "Full Kaguya route: " + choice)
		release(game)
	print("Kaguya rewind, rewards, layers, treasures, hazards and four full routes: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_rewind() -> void:
	var game := fixture()
	var rt = game._ensure_kaguya_runtime()
	var boss: Dictionary = game.zombies[0]
	game.grid[2][2] = game._create_plant("repeater",2,2)
	game.support_grid[2][2] = game._create_plant("flower_pot",2,2)
	var p: Dictionary = game.grid[2][2]
	var pot: Dictionary = game.support_grid[2][2]
	p.ultimate_charge = 1.0
	game._spawn_zombie_at("normal",1,game._cell_center(1,4).x,true)
	var dead: Dictionary = game.zombies.back()
	game._spawn_zombie_at("rabbit_airship",4,game._cell_center(4,7).x,true)
	var ship: Dictionary = game.zombies.back()
	game._ensure_touhou_enemies().update_unit(ship,0.01)
	var ship_state := ship.duplicate(true)
	var boss_hp := float(boss.health)
	var phase: Dictionary = boss.touhou_encounter.duplicate(true)
	var event := int(game.next_event_index)
	rt.begin_rewind(boss,4)
	p.health = 0
	pot.health = 0
	p.ultimate_charge = 0
	p.shot_cooldown = 1.7
	game.grid[2][2] = null
	game.support_grid[2][2] = null
	game.grid[2][3] = game._create_plant("wallnut",2,3)
	dead.health = 0
	game._cleanup_dead_zombies()
	var kills := int(game.total_kills)
	var coins := game.coins.size()
	game._ensure_touhou_enemies().update_unit(ship,3)
	game._spawn_zombie("buckethead",5,true)
	var newcomer := int(game.zombies.back().uid)
	var counter := int(game.next_zombie_uid)
	rt.update(3.9)
	check(game.grid[2][2] == null and game.grid[2][3] != null, "Rewind waits for full telegraph")
	rt.update(0.11)
	check(game.grid[2][2] == p and game.support_grid[2][2] == pot and p.health > 0 and pot.health > 0, "Both dead layers revive at their original cell")
	check(p.ultimate_charge == 0 and p.shot_cooldown == 1.7, "Spent ultimate and current cooldown cannot be refunded")
	check(game.grid[2][3] == null and not game.zombies.any(func(z): return int(z.uid) == newcomer), "New plants and zombies disappear")
	var revived: Dictionary = {}
	for z in game.zombies:
		if int(z.uid) == int(dead.uid): revived = z
		if int(z.uid) == int(ship.uid):
			check(z.x == ship_state.x and z.airship_next_col == ship_state.airship_next_col and z.airship_drops == ship_state.airship_drops, "Airship path/drop state rewinds with its guards")
	check(not revived.is_empty() and revived.health > 0, "Dead ordinary enemy revives with stable identity")
	check(game.next_zombie_uid == counter and game.next_event_index == event and boss.health == boss_hp and boss.touhou_encounter == phase, "World progress, UID counter, boss health and phase are untouched")
	check(rt.rewind.is_empty(), "Snapshot consumed exactly once")
	if not revived.is_empty():
		revived.health = 0
		game._cleanup_dead_zombies()
	check(game.total_kills == kills and game.coins.size() == coins, "Resurrection cannot farm duplicate kills or coins")
	# A later snapshot must preserve the settled marker as well.
	rt.begin_rewind(boss,4)
	game.boss_time_stop_timer = 1
	rt.update(1)
	check(rt.rewind.age == 0, "External time stop freezes the rewind clock")
	game.boss_time_stop_timer = 0
	rt.clear_owner(int(boss.uid))
	check(rt.rewind.is_empty(), "Phase/death cleanup cancels pending resurrection")
	release(game)

func _test_treasures() -> void:
	var game := fixture()
	var rt = game._ensure_kaguya_runtime()
	var boss: Dictionary = game.zombies[0]
	var uid = rt.summon_treasure(boss,"bowl")
	var bowl: Dictionary = game.zombies.back()
	game._spawn_zombie_at("normal",int(bowl.row),float(bowl.x)-game.CELL_SIZE.x,true)
	var z: Dictionary = game.zombies.back()
	check(rt.damage_factor(z) == 1, "Bowl has a two-second activation warning")
	rt.update(2.1)
	var hp := float(z.health)
	game._apply_zombie_damage(z,100,0,0,false)
	check(is_equal_approx(hp-float(z.health),50), "Live bowl halves actual ordinary damage")
	check(rt.damage_factor(bowl) == 1 and rt.damage_factor(boss) == 1, "Bowl and boss never protect themselves")
	bowl.health = 0
	rt.update(0.1)
	check(rt.damage_factor(z) == 1, "Destroying bowl removes protection")
	uid = rt.summon_treasure(boss,"swallow")
	var shell: Dictionary = game.zombies.back()
	z.row = shell.row
	z.x = shell.x - 40
	z.health = 20
	rt.begin_rewind(boss,5,uid)
	rt.update(2.1)
	check(z.health > 20, "Swallow life line heals ordinary zombies")
	shell.health = 0
	rt.update(0.1)
	check(rt.rewind.is_empty(), "Breaking the shell cancels life-line rewind")
	release(game)

func _test_damage_and_cleanup() -> void:
	var game := fixture("hard")
	var rt = game._ensure_kaguya_runtime()
	var boss: Dictionary = game.zombies[0]
	game.grid[1][2] = game._create_plant("repeater",1,2)
	var p: Dictionary = game.grid[1][2]
	var hp := float(p.health)
	rt.mark(boss,Vector2i(1,2),"instant",200,2)
	rt.update(1.99)
	check(p.health == hp,"Direct strike never hits before warning")
	rt.update(0.02)
	check(p.health < hp,"Strike causes actual plant damage")
	rt.mark(boss,Vector2i(1,2),"eternity",0,2)
	rt.update(2.01)
	check(rt.plant_stilled(1,2) and not rt.plant_stilled(1,3),"Eternal garden only freezes marked cells")
	game._spawn_zombie_at("normal",1,game._cell_center(1,2).x,true)
	check(game._current_zombie_speed(game.zombies.back()) == 0,"Eternity also arrests local zombie movement")
	rt.clear_owner(int(boss.uid))
	check(not rt.plant_stilled(1,2),"Owner cleanup restores normal plant actions")
	for card in Spells.cards_for("kaguya_boss",game.current_level):
		rt.cast(boss,card[2])
		game._ensure_eirin_runtime().update(0.1)
		rt.update(0.1)
	check(rt.marks.size() <= 24 and rt.treasures.size() <= 3,"Effects and attackable treasures remain bounded")
	release(game)

func _test_rosters() -> void:
	var game := fixture()
	var rt = game._ensure_eirin_runtime()
	rt.reinforcement_kind()
	check(not rt.roster.has("mech_zombie") and not rt.roster.has("flywheel_zombie"),"All-world pool excludes unbalanced enemies")
	for forbidden in ["mech_zombie","flywheel_zombie"]:
		game._spawn_zombie(forbidden,2)
		check(game.zombies.back().kind != forbidden,"Central spawn gate blocks every Touhou summon source")
	game.current_level = {"terrain":"city", "events":[]}
	game._spawn_zombie("mech_zombie",2)
	check(game.zombies.back().kind == "mech_zombie","Other worlds keep their original enemy roster")
	release(game)
