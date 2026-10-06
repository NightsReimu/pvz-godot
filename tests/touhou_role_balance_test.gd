extends "res://tests/touhou_encounter_test.gd"
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")

func _run() -> void:
	var variants := 0
	for base in Game.Defs.LEVELS:
		if not Difficulty.is_touhou(base): continue
		for choice in Difficulty.options(base):
			var level := Difficulty.build_level(base, choice)
			var finale_kind := ""
			for event in level.events:
				if String(event.kind) in Difficulty.boss_kinds(): finale_kind = event.kind
			check(not finale_kind.is_empty(), "Every Touhou route has a finale")
			if finale_kind.is_empty(): continue
			var game := make_game(finale_kind)
			game.zombies.clear()
			game.current_level = level
			game._spawn_zombie_at(finale_kind, 2, game._boss_anchor_x(finale_kind), true)
			var finale: Dictionary = game.zombies.back()
			var old_final_hp := float(Game.Defs.ZOMBIES[finale_kind].health) * float(Difficulty.profile(level).health)
			check(is_equal_approx(float(finale.max_health), old_final_hp * 1.95), "%s/%s finale receives 34.5%% more health than v174" % [level.id, choice])
			check(finale.health == finale.max_health, "Finale enters with fresh full HP")
			check(finale.touhou_encounter.phases == Spells.phases_for(finale_kind, level), "Finale retains every canonical and difficulty spell")
			var mid := String(level.get("mid_boss_kind", ""))
			if not mid.is_empty():
				game.zombies.clear()
				game._spawn_frozen_branch_midboss()
				var road: Dictionary = game.zombies.filter(func(z): return String(z.kind) == mid and z != finale).back()
				var old_road_hp := float(Game.Defs.ZOMBIES[mid].health) * float(Difficulty.profile(level).health)
				var self_road := bool(level.get("mid_boss_final_preview", false))
				var limit := old_road_hp * (0.09 if self_road else 0.18)
				check(float(road.max_health) <= limit + 0.1, "%s/%s road is an incomplete form" % [level.id, choice])
				check(float(road.max_health) <= old_final_hp * 0.10 + 0.1, "Every road is at most 10% of its old finale HP")
				check(not game._is_stage_ending_boss(road), "Road defeat cannot finish the level")
				var hp := float(road.health)
				game._spawn_frozen_branch_midboss()
				check(float(road.health) == hp, "Health scaling is applied exactly once")
			variants += 1
			release(game)
	for choice in ["extra", "extra_plus"]:
		var game := make_game("ran_boss")
		game.current_level.touhou_difficulty = choice
		var successor: Dictionary = game._trigger_ran_boss_successor(game.zombies[0])
		var expected := float(Game.Defs.ZOMBIES.yukari_boss.health) * float(Difficulty.profile(game.current_level).health) * 1.95
		check(is_equal_approx(float(successor.max_health),expected), "Ran successor Yukari retains finale scaling in both EX tiers")
		check(successor.health == successor.max_health, "Successor enters with full health")
		release(game)
	print("Touhou role balance: %d stage/tier variants; %d failure(s)" % [variants, failures])
	quit(1 if failures else 0)
