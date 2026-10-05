extends "res://scripts/tools/capture_ancient_world.gd"

func _run() -> void:
	await process_frame
	for child in root.get_children():
		if child is GameScript:
			child.save_dirty = false
			child.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ANCIENT_OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		for pattern in ["suika_wine", "suika_giant", "suika_black_hole", "suika_million_oni"]:
			root.size = viewport
			root.content_scale_size = viewport
			var game := PreviewGame.new()
			game.size = Vector2(viewport)
			game.mobile_runtime_override = 1 if viewport.y < 600 else 0
			root.add_child(game)
			var level: Dictionary = GameScript.Defs.AncientLevelDefs.LEVELS.back().duplicate(true)
			level.custom_level = true
			level = game.TouhouDifficulty.build_level(level, "hard")
			game._begin_level(-1, ["repeater", "healing_gourd", "umbrella_leaf", "jasmine_tea", "golden_milk", "samsara_eye"], level)
			game._drain_asset_prewarm_queue()
			game.rng.seed = 806
			game.level_time = 88.0
			game.battle_intro_timer = 0
			for row in range(5):
				for col in range(4):
					game.grid[row][col] = game._create_plant(["repeater", "healing_gourd", "dandelion", "electric_bonk_choy"][col], row, col)
					game.grid[row][col].spawn_time = 0
			game.grid[0][1] = game._create_plant("jasmine_tea", 0, 1)
			game.grid[4][1] = game._create_plant("golden_milk", 4, 1)
			game._spawn_zombie_at("ancient_samurai", 1, game._cell_center(1, 5).x, true)
			game._spawn_zombie_at("buckethead", 3, game._cell_center(3, 6).x, true)
			for unit in game.zombies: unit.spawn_time = 0
			game._spawn_zombie_at("suika_boss", 2, game._boss_anchor_x("suika_boss"), true)
			var boss: Dictionary = game.zombies.back()
			boss.spawn_time = 0
			# Capture an actual spell segment, keeping the same phase state and HUD
			# as gameplay. Isolated card tests must never drive user-facing previews.
			var encounter: Dictionary = boss.touhou_encounter
			for phase in range(encounter.phases.size()):
				for attack in range(encounter.phases[phase].size()):
					if String(encounter.phases[phase][attack][2]) == pattern:
						encounter.index = phase
						encounter.attack = attack
			game.TouhouPhaseRuntime._set_bounds(boss)
			boss.health = encounter.ceiling
			game._trigger_boss_skill(boss)
			var duration := 3.0 if pattern == "suika_wine" else (3.6 if pattern == "suika_million_oni" else 1.8)
			for i in range(int(duration / 0.02)):
				game.level_time += 0.02
				game.suika_runtime.update(0.02)
				game.touhou_danmaku.update(0.02)
				game._update_effects(0.02)
			game.banner_timer = 0
			game.banner_label.visible = false
			game.toast_label.visible = false
			await _shot(game, "suika-%s-%dx%d" % [pattern, viewport.x, viewport.y])
			game.save_dirty = false
			game.free()
	quit()
