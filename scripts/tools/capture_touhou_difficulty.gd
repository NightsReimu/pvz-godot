extends "res://scripts/tools/capture_battle_polish.gd"


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390), Vector2i(568, 320)]:
		root.size = viewport
		root.content_scale_size = viewport
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.y < 600 else 0
		root.add_child(game)
		game.completed_levels.resize(GameScript.Defs.LEVELS.size())
		game.completed_levels.fill(true)
		game.unlocked_levels = GameScript.Defs.LEVELS.size()
		for id in ["3-21", "1-23"]:
			var index := 0
			for candidate in range(GameScript.Defs.LEVELS.size()):
				if GameScript.Defs.LEVELS[candidate].id == id:
					index = candidate
			game.current_world_key = "pool" if id == "3-21" else "day"
			game._start_level(index)
			game._drain_asset_prewarm_queue()
			game.touhou_difficulty_menu.choice = "lunatic" if id == "3-21" else "extra_plus"
			await _capture(game, "difficulty-%s-%dx%d" % [id, viewport.x, viewport.y])
			game.touhou_difficulty_menu.click(game.touhou_difficulty_menu.start_rect().get_center())
			await _capture(game, "difficulty-seeds-%s-%dx%d" % [id, viewport.x, viewport.y])
			game.selection_cards = ["sunflower", "peashooter", "snow_pea", "repeater", "wallnut", "cherry_bomb", "healing_gourd", "sun_shroom", "flower_pot", "lily_pad"]
			game._handle_selection_click(game._selection_start_rect().get_center())
			game.level_time = 8.0
			for row in game.active_rows:
				for col in range(4):
					game.grid[row][col] = game._create_plant(["sunflower", "repeater", "snow_pea", "wallnut"][col], row, col)
					game.grid[row][col].spawn_time = 0.0
			var kind := "keine_boss" if id == "3-21" else "flandre_boss"
			game._spawn_zombie_at(kind, 2, game._boss_anchor_x(kind), true)
			var boss: Dictionary = game.zombies.back()
			boss.spawn_time = 0.0
			var encounter: Dictionary = boss.touhou_encounter
			for phase_index in range(encounter.phases.size()):
				if String(encounter.phases[phase_index][0][2]).begins_with("pressure_"):
					encounter.index = phase_index
					encounter.attack = 0
					break
			game._trigger_boss_skill(boss)
			game.touhou_danmaku.update(1.5)
			game.banner_label.visible = false
			await _capture(game, "difficulty-battle-%s-%dx%d" % [id, viewport.x, viewport.y])
		game.save_dirty = false
		game.free()
	quit()
