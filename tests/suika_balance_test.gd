extends "res://tests/hina_balance_test.gd"

func _run() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := NativeRouteGame.new()
		game.size = Vector2(1600, 900)
		root.add_child(game)
		game.rng.seed = 905
		var level: Dictionary = GameScript.Defs.AncientLevelDefs.LEVELS.back().duplicate(true)
		level.custom_level = false
		level = game.TouhouDifficulty.build_level(level, choice)
		game._begin_level(-1, _manual_cards(level), level)
		game.hide()
		game.battle_intro_timer = 0.0
		game.next_event_index = game.current_level.events.size()
		game.frozen_branch_midboss_spawned = true
		game.frozen_branch_midboss_cleared = true
		game.frozen_branch_progress_locked = false
		# The boss-only diagnostic starts with a developed legal formation.
		# Conveyor tiers contain only real belt ingredients, including kernel
		# pults instead of the unavailable sunflowers used by the old fixture.
		var first := "sunflower" if choice == "lunatic" else "kernel_pult"
		var layout: Array = [first, "healing_gourd", "repeater", "repeater", "healing_gourd", "melon_pult", "torchwood", "wallnut"]
		for row in game.active_rows:
			for col in range(layout.size()): game.grid[row][col] = game._create_plant(layout[col], row, col)
			if choice == "lunatic":
				var fusion = game._ensure_plant_fusion()
				game.grid[row][2] = game._create_plant(fusion.Fusion.result("repeater", "wallnut"), row, 2)
				game.grid[row][5] = game._create_plant(fusion.Fusion.result("melon_pult", "jasmine_tea"), row, 5)
		game._spawn_zombie_at("suika_boss", 2, game._boss_anchor_x("suika_boss"), true)
		var boss: Dictionary = game.zombies.back()
		var peak := 0
		var passed := false
		var placements := 0
		for frame in range(16000):
			if frame % 30 == 0: await process_frame
			if frame % 10 == 0:
				# Use only actual deliveries or earned sun and normal cooldowns;
				# tea/milk are grafted through the same legal native belt policy.
				if choice == "lunatic": _paid_replant(game, layout)
				else: placements += _auto_belt(game)
				for row in game.active_rows:
					for col in range(game.COLS): game._try_activate_ultimate(row, col)
			game._process(0.05)
			peak = maxi(peak, game.zombies.size())
			if bool(boss.touhou_encounter.complete):
				passed = true
				break
			if game.battle_state == game.BATTLE_LOST: break
		if not passed:
			failures += 1
			push_error("%s: the prepared native defense must finish Suika with its real supplied repairs" % choice)
		print("Suika prepared defense %s: finished=%s, %.1fs, phase %d/%d, peak enemies=%d, boss health=%.0f, delivered placements=%d, final supports=%d/%d calls, lost plants=%d" % [choice, passed, game.level_time, int(boss.touhou_encounter.index) + 1, boss.touhou_encounter.phases.size(), peak, boss.health, placements, game.final_reinforcements, game.final_reinforcement_calls, game.lost_plants])
		await _release_game(game)
	call_deferred("quit", 1 if failures else 0)
