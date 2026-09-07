extends "res://scripts/tools/capture_touhou_spells.gd"


func _run() -> void:
	await process_frame
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var level: Dictionary = {}
	for item in GameScript.Defs.LEVELS:
		if item.id == "3-21":
			level = item.duplicate(true)
	level["custom_level"] = true
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		root.size = viewport
		root.content_scale_size = viewport
		for cycle in [-1, 0, 4, 5, 6, 7]:
			var game := PreviewGame.new()
			game.size = Vector2(viewport)
			game.mobile_runtime_override = 1 if viewport.y < 600 else 0
			root.add_child(game)
			game.rng.seed = 921
			game._begin_level(-1, [], level)
			game._queue_boss_frame_set_prewarm("keine_boss")
			game._drain_asset_prewarm_queue()
			game.level_time = 35
			game.ui_time = 7
			game.active_cards = ["repeater", "wallnut", "spiral_bamboo", "healing_gourd", "cherry_bomb", "doom_shroom"]
			for row in range(6):
				for col in range(4):
					var kind: String = ["spiral_bamboo", "repeater", "snow_pea", "wallnut"][col]
					game.grid[row][col] = game._create_plant(kind, row, col)
					game.grid[row][col].spawn_time = 0.0
				game._spawn_zombie_at("conehead" if row % 2 == 0 else "screen_door", row, game._cell_center(row, 5 + row % 2).x, true)
				game.zombies.back().spawn_time = 0.0
			game._spawn_zombie_at("keine_boss", 2, game._boss_anchor_x("keine_boss"), true)
			var boss: Dictionary = game.zombies.back()
			boss.spawn_time = 0.0
			boss.rumia_reinforcement_timer = 100
			boss.hover_shift_timer = 100
			if cycle >= 0:
				_select_preview_card(game, boss, cycle)
				game._trigger_boss_skill(boss)
			for frame in range(108 if cycle == 7 else 75):
				game.level_time += 1.0 / 60.0
				game.ui_time += 1.0 / 60.0
				game._update_zombies(1.0 / 60.0)
				if game.touhou_danmaku != null:
					game.touhou_danmaku.update(1.0 / 60.0)
				game.keine_runtime.update(1.0 / 60.0)
				game._update_effects(1.0 / 60.0)
				if frame == 35 and cycle in [4, 5, 6, 7]:
					game.banner_label.visible = false
					await _capture(game, "keine-%dx%d-card%d-warning" % [viewport.x, viewport.y, cycle])
			game.banner_label.visible = false
			await _capture(game, "keine-%dx%d-card%d-active" % [viewport.x, viewport.y, cycle])
			game.save_dirty = false
			game.free()
	quit()
