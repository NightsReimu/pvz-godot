extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

func _run() -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := PreviewGame.new()
		game.size = Vector2(1600, 900)
		root.add_child(game)
		game.rng.seed = 905
		var level: Dictionary = GameScript.Defs.AncientLevelDefs.LEVELS.back().duplicate(true)
		level.custom_level = true
		level = game.TouhouDifficulty.build_level(level, choice)
		game._begin_level(-1, ["sunflower", "repeater", "healing_gourd", "melon_pult", "torchwood", "wallnut", "jasmine_tea"], level)
		game.battle_intro_timer = 0
		game.next_event_index = game.current_level.events.size()
		game.frozen_branch_midboss_spawned = true
		game.frozen_branch_midboss_cleared = true
		game.frozen_branch_progress_locked = false
		# A developed defense, attainable through continued belt deliveries or
		# manual sun production; normal charge-based ultimates remain available.
		# No artificial health, damage, free plant food or direct boss damage.
		var layout := ["sunflower", "healing_gourd", "repeater", "repeater", "healing_gourd", "melon_pult", "torchwood", "wallnut"]
		for row in range(5):
			for col in range(layout.size()):
				game.grid[row][col] = game._create_plant(layout[col], row, col)
			if choice == "lunatic":
				# Manual selection can build durable pea grafts and use the tea
				# material to protect shooters from the cumulative wine mechanics.
				var fusion = game._ensure_plant_fusion()
				game.grid[row][2] = game._create_plant(fusion.Fusion.result("repeater", "wallnut"), row, 2)
				game.grid[row][5] = game._create_plant(fusion.Fusion.result("melon_pult", "jasmine_tea"), row, 5)
		game._spawn_zombie_at("suika_boss", 2, game._boss_anchor_x("suika_boss"), true)
		var boss: Dictionary = game.zombies.back()
		var peak := 0
		var passed := false
		for frame in range(16000):
			# Flush native engine/audio work while advancing simulated battle time.
			# Thousands of synchronous frames otherwise accumulate queued playbacks.
			if frame % 30 == 0: await process_frame
			if frame % 60 == 0:
				if choice == "lunatic": _replant(game, layout)
				for row in range(5):
					for col in range(layout.size()): game._try_activate_ultimate(row, col)
			game._process(0.05)
			peak = maxi(peak, game.zombies.size())
			if bool(boss.touhou_encounter.complete):
				passed = true
				break
			if game.battle_state == game.BATTLE_LOST: break
		if not passed:
			failures += 1
			push_error("%s: the prepared defense must be able to finish Suika's live fight" % choice)
		print("Suika prepared defense %s: finished=%s, %.1fs, phase %d/%d, peak enemies=%d, boss health=%.0f" % [choice, passed, game.level_time, int(boss.touhou_encounter.index) + 1, boss.touhou_encounter.phases.size(), peak, boss.health])
		game.save_dirty = false
		game.free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if failures else 0)

func _replant(game: Control, layout: Array) -> void:
	# Simulate manual repair using earned sun, normal seed cooldowns and the
	# actual board-click/fusion placement path. Never restore health directly.
	for row in range(5):
		for col in range(layout.size()):
			var plant = game.grid[row][col]
			var kind: String = layout[col] if plant == null else ""
			if plant != null and col == 2 and not plant.has("fusion_kind"): kind = "wallnut"
			if plant != null and col == 5 and not plant.has("fusion_kind"): kind = "jasmine_tea"
			if kind == "" or game.sun_points < game._endless_cost_for_kind(kind) or float(game.card_cooldowns.get(kind, 0)) > 0.01: continue
			game.selected_tool = kind
			game._handle_board_click(Vector2i(row, col))
