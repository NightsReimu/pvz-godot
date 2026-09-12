extends "res://tests/touhou_difficulty_test.gd"

func _run() -> void:
	for kind in Difficulty.EXTENSIONS:
		_test_distinct_geometry(kind)
	for kind in ["patchouli_boss", "cirno_boss", "sakuya_boss", "chen_boss", "youmu_boss"]:
		_test_midboss_moves(kind)
	_test_character_tuning()
	_test_original_tiles()
	print("Distinct original moves for 23 bosses, five midboss routes, 4A/B strength and tile formations: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_distinct_geometry(kind: String) -> void:
	var game := _difficulty_game(kind, "lunatic")
	var boss: Dictionary = game.zombies[0]
	boss.boss_phase = 0
	var phases: Array = boss.touhou_encounter.phases.duplicate(true)
	var signatures := []
	for phase in phases:
		for entry in phase:
			if not String(entry[0]).begins_with("original-difficulty-"):
				continue
			boss.touhou_encounter.phases = [[entry]]
			boss.touhou_encounter.index = 0
			boss.touhou_encounter.attack = 0
			game._trigger_boss_skill(boss)
			var dm = game.touhou_danmaku
			check(dm.casts[0].card.origin == "original" and String(dm.casts[0].card.name).begins_with("原创"), "New moves must be presented as original")
			# Ignore name, damage, count and colour: different moves must change
			# emission positions, trajectories or delayed movement, not only stats.
			var geometry := {}
			for bullet in dm.bullets:
				var motion := []
				for key in ["freeze_at", "thaw_at", "redirect_at", "angular_speed", "bounces", "homing_after", "orbit_until"]:
					if bullet.has(key):
						motion.append([key, bullet[key]])
				geometry[str([Vector2(bullet.position).snapped(Vector2.ONE), snappedf(Vector2(bullet.velocity).angle(), 0.01), bullet.shape, motion])] = true
			for beam in dm.beams:
				check(float(beam.delay) >= 0.9, "Original lasers must have readable warnings")
				geometry[str([beam.from, beam.to, beam.get("turn_rate", 0)])] = true
			var signature: Array = geometry.keys()
			signature.sort()
			check(not signature.is_empty() and not signatures.has(signature), "%s needs a distinct live geometry for every added move" % kind)
			signatures.append(signature)
			if kind == "alice_boss":
				check(dm.casts[0].actors.size() == 5, "Every doll move needs visible emitters")
				if not dm.beams.is_empty():
					dm.update(0.3)
					for beam in dm.beams:
						check(beam.has("actor_index") and Vector2(beam.from).is_equal_approx(dm.casts[0].actors[int(beam.actor_index)].position), "New doll lasers must follow their visible emitter")
	check(signatures.size() == 3, "%s needs three independently implemented original moves" % kind)
	release(game)

func _test_midboss_moves(kind: String) -> void:
	var previous := 0
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var phases := Spells.phases_for(kind, {"mid_boss_kind": kind, "touhou_difficulty": choice})
		var patterns := {}
		for phase in phases:
			for entry in phase:
				patterns[entry[2]] = true
		check(patterns.size() > previous, "%s midboss route must also gain new moves" % kind)
		previous = patterns.size()

func _test_character_tuning() -> void:
	for kind in ["reimu_boss", "marisa_boss"]:
		check(float(Game.Defs.ZOMBIES[kind].health) >= 28500, "TH08 4A/B health must support their longer routes")
		for choice in ["easy", "normal", "hard", "lunatic"]:
			var game := _difficulty_game(kind, choice)
			var dm = game.touhou_danmaku
			var base_damage := 1.45 if kind == "reimu_boss" else 1.35
			var base_beam := 1.35 if kind == "reimu_boss" else 1.22
			for phase in [0, 3, 30]:
				var c := {"kind": kind, "owner": 1, "phase": phase, "wave": 0}
				var growth := 1.0 if phase == 0 else 1.36
				dm._bullet(c, Vector2.ZERO, PI, 100, Color.WHITE, "orb", {"damage": 20.0})
				dm._beam(c, Vector2.ZERO, Vector2(100, 0), Color.WHITE, 1.0, 10, {"damage": 100.0})
				var difficulty := Difficulty.boss_damage_multiplier(game.current_level)
				check(is_equal_approx(float(dm.bullets.back().damage), 20 * base_damage * growth * difficulty), "Character, bounded phase growth and difficulty apply once per bullet")
				check(is_equal_approx(float(dm.beams.back().damage), 100 * base_beam * growth * difficulty), "Laser tuning applies once and remains bounded at later stages")
			check(Difficulty.attack_speed(kind, game.current_level) > float(Difficulty.profile(game.current_level).speed), "4A/B projectile speed must be strengthened")
			check(Difficulty.attack_density(kind, game.current_level) > float(Difficulty.profile(game.current_level).density), "4A/B projectile density must be strengthened")
			check(Difficulty.attack_cadence(kind, game.current_level) < float(Difficulty.profile(game.current_level).cadence), "4A/B emission cadence must be faster")
			release(game)
	var other := {"touhou_difficulty": "normal"}
	check(is_equal_approx(Difficulty.attack_damage("keine_boss", other, 3), Difficulty.boss_damage_multiplier(other)), "Character tuning must preserve other bosses' damage")

func _test_original_tiles() -> void:
	for kind in ["reimu_boss", "marisa_boss"]:
		var game := _difficulty_game(kind, "lunatic")
		game.active_rows = [0, 1, 2, 3, 4, 5]
		var boss: Dictionary = game.zombies[0]
		var runtime = game._ensure_reimu_runtime() if kind == "reimu_boss" else game._ensure_marisa_runtime()
		var family := "ofuda" if kind == "reimu_boss" else "stars"
		var formations := []
		for suffix in ["", "_crossfire", "_domain"]:
			runtime.serial = 0
			runtime.cast(boss, "pressure_" + family + suffix)
			check(runtime.tiles.size() <= 6 and runtime.tiles.size() >= 4, "Original field effects must stay bounded")
			var formation: Array = runtime.tiles.map(func(t): return str([t.cell, t.kind]))
			formation.sort()
			check(not formations.has(formation), "New 4A/B moves must use distinct tile formations")
			formations.append(formation)
			check(runtime.tiles.all(func(t): return float(t.delay) >= 1.0), "Every original tile effect must warn before activation")
			runtime.clear_owner(int(boss.uid))
			check(runtime.tiles.is_empty(), "Original tiles must clear on phase change")
		release(game)
