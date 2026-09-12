extends "res://tests/touhou_encounter_test.gd"

const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")


func _run() -> void:
	_test_boss_damage_scaling()
	_test_level_overrides()
	for kind in Difficulty.EXTENSIONS:
		_test_higher_route(kind)
		_test_live_extensions(kind)
	_test_variants()
	_test_pressure_scaling()
	print("Touhou difficulty routes, immutable levels and live attacks: %d failure(s)" % failures)
	quit(1 if failures else 0)


func _test_boss_damage_scaling() -> void:
	var expected := {"easy": 0.45, "normal": 0.52, "hard": 0.62, "lunatic": 0.74, "extra": 0.45, "extra_plus": 0.70}
	for choice in expected:
		var level := {"events": [{"kind": "rumia_boss"}], "touhou_difficulty": choice}
		check(is_equal_approx(float(Difficulty.boss_damage_multiplier(level)), float(expected[choice])), "%s must use the reduced, displayed Touhou Boss damage multiplier" % choice)
	check(is_equal_approx(float(Difficulty.boss_damage_multiplier({"events": [{"kind": "basic"}]})), 1.0), "Non-Touhou levels must retain their damage values")


func _test_level_overrides() -> void:
	var regular := 0
	var extra := 0
	for base in Game.Defs.LEVELS:
		var before: Dictionary = base.duplicate(true)
		var options := Difficulty.options(base)
		if options.is_empty():
			check(Difficulty.build_level(base, "lunatic") == before, "Non-Touhou levels must not be changed")
			continue
		if Difficulty.is_extra(base):
			extra += 1
			check(options == ["extra", "extra_plus"], "EX stages have exactly two options")
		else:
			regular += 1
			check(options.size() == 4, "Regular Touhou stages have four options")
		var last_events := -1
		var last_health := 0.0
		for choice in options:
			var level := Difficulty.build_level(base, choice)
			check(level.events.size() > last_events, "Each higher tier must add road waves")
			check(float(Difficulty.profile(level).health) > last_health, "Boss health must increase monotonically")
			last_events = level.events.size()
			last_health = Difficulty.profile(level).health
			check(level.get("mid_boss_kind", "") == base.get("mid_boss_kind", ""), "Difficulty must preserve midboss routing")
			check(level.events.back().kind == base.events.back().kind, "Added road waves must precede the finale")
			if choice == options[0]:
				check(level.events == base.events and level.mode == base.mode and level.start_sun == base.start_sun, "Easy/EX must preserve current play")
			if choice == options.back():
				check(level.mode == "normal" and level.start_sun > 0 and not level.has("conveyor_plants"), "Highest tier must use funded manual planting")
		check(base == before, "Difficulty construction must never mutate registered levels")
	check(regular == 15 and extra == 2, "All 17 existing Touhou stages must expose the right selector")


func _difficulty_game(kind: String, choice: String) -> EncounterGame:
	var game := make_game(kind)
	game.zombies.clear()
	game.current_level["id"] = "1-23" if kind == "flandre_boss" else ("2-31" if kind in ["ran_boss", "yukari_boss"] else "difficulty-test")
	game.current_level["touhou_difficulty"] = choice
	game._spawn_zombie_at(kind, 2, game._boss_anchor_x(kind), true)
	game.zombies[0].rumia_reinforcement_timer = 10000
	game.zombies[0].hover_shift_timer = 10000
	return game


func tick(game: Control, dt: float = 0.1) -> void:
	super.tick(game, dt)
	if game.keine_runtime != null:
		game.keine_runtime.update(dt)


func _test_higher_route(kind: String) -> void:
	var choices: Array = ["extra", "extra_plus"] if kind in ["flandre_boss", "ran_boss", "yukari_boss"] else ["easy", "normal", "hard", "lunatic"]
	var previous := 0
	for choice in choices:
		var level := {"id": "1-23" if choices.size() == 2 else "test", "touhou_difficulty": choice}
		var phases := Spells.phases_for(kind, level)
		check(phases.size() > previous, "%s must gain phases at %s" % [kind, choice])
		previous = phases.size()
	var game := _difficulty_game(kind, choices.back())
	var boss: Dictionary = game.zombies[0]
	check(is_equal_approx(float(boss.max_health), float(Game.Defs.ZOMBIES[kind].health) * float(Difficulty.profile(game.current_level).health)), "Spawn must apply the chosen boss health once")
	var required := 0
	for phase in boss.touhou_encounter.phases:
		required += phase.size()
	finish_encounter(game)
	check(game.declarations.size() >= required, "%s must actually cast its additional attacks" % kind)
	release(game)


func _test_live_extensions(kind: String) -> void:
	var game := _difficulty_game(kind, "lunatic")
	game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
	for row in game.active_rows:
		for col in range(9):
			game.grid[row][col] = game._create_plant("wallnut", row, col)
			game.grid[row][col].health = 100000.0
	var boss: Dictionary = game.zombies[0]
	var phases: Array = boss.touhou_encounter.phases.duplicate(true)
	for phase in phases:
		for entry in phase:
			if not String(entry[2]).begins_with("pressure_"):
				continue
			boss.touhou_encounter.phases = [[entry]]
			boss.touhou_encounter.index = 0
			boss.touhou_encounter.attack = 0
			var before := _plant_health(game)
			game._trigger_boss_skill(boss)
			check(_plant_health(game) == before, "Extension cast must not cause invisible instant damage")
			game.touhou_danmaku.update(3.3)
			check(_plant_health(game) < before, "%s must have collision-bearing pressure attacks" % entry[0])
	release(game)


func _plant_health(game: Control) -> float:
	var total := 0.0
	for row in game.active_rows:
		for plant in game.grid[row]:
			if plant != null:
				total += float(plant.health)
	return total


func _test_variants() -> void:
	var hard := {"touhou_difficulty": "hard"}
	var lunatic := {"touhou_difficulty": "lunatic"}
	check(Spells.phases_for("remilia_boss", hard).back().back()[0] == "th06-51", "Hard Remilia must finish with Scarlet Gensokyo")
	check(Spells.phases_for("keine_boss", lunatic).back().size() == 1, "Hard Last Spells must not gain an opening nonspell")
	check(Spells.phases_for("keine_boss", lunatic).back()[0][0] == "th08-054", "Lunatic Keine must use the correct Last Spell variant")
	check(Spells.card_for({"kind": "yuyuko_boss", "yuyuko_revived": true}, lunatic).id == "th07-116", "Lunatic resurrection must retain the eight-part bloom")
	for kind in ["remilia_boss", "keine_boss"]:
		var game := _difficulty_game(kind, "lunatic")
		var boss: Dictionary = game.zombies[0]
		for phase in boss.touhou_encounter.phases.duplicate(true):
			for entry in phase:
				if not String(entry[0]).begins_with("th"):
					continue
				boss.touhou_encounter.phases = [[entry]]
				boss.touhou_encounter.index = 0
				boss.touhou_encounter.attack = 0
				game._trigger_boss_skill(boss)
				check(not game.touhou_danmaku.bullets.is_empty() or not game.touhou_danmaku.beams.is_empty(), "%s higher-difficulty variant must emit real attacks" % entry[0])
		release(game)


func _test_pressure_scaling() -> void:
	var previous_count := 0
	var previous_damage := 0.0
	var previous_speed := 0.0
	var previous_interval := 100.0
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := _difficulty_game("rumia_boss", choice)
		game._trigger_boss_skill(game.zombies[0])
		var bullet: Dictionary = game.touhou_danmaku.bullets[0]
		check(game.touhou_danmaku.bullets.size() > previous_count and float(bullet.damage) > previous_damage and Vector2(bullet.velocity).length() > previous_speed, "Higher tiers must increase actual bullet density, damage and speed")
		check(game._boss_reinforcement_interval("rumia_boss", 0) < previous_interval, "Boss reinforcements must accelerate at higher difficulty")
		previous_count = game.touhou_danmaku.bullets.size()
		previous_damage = bullet.damage
		previous_speed = Vector2(bullet.velocity).length()
		previous_interval = game._boss_reinforcement_interval("rumia_boss", 0)
		release(game)
