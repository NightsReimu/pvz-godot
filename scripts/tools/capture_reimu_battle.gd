extends "res://scripts/tools/capture_battle_polish.gd"

const CAPTURE_PATH := "res://output/reimu"

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_PATH))
	var base: Dictionary = {}
	for level in GameScript.Defs.LEVELS:
		if level.id == "3-22-a":
			base = level.duplicate(true)
	base.custom_level = true
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		root.size = viewport
		root.content_scale_size = viewport
		await process_frame
		for choice in ["easy", "normal", "hard", "lunatic"]:
			var game := PreviewGame.new()
			game.size = Vector2(viewport)
			game.mobile_runtime_override = 1 if viewport.x < 1000 else 0
			root.add_child(game)
			game.rng.seed = 923
			game._begin_level(-1, ["sunflower", "repeater", "wallnut", "snow_pea", "cherry_bomb", "healing_gourd"], game.TouhouDifficulty.build_level(base, choice))
			game._drain_asset_prewarm_queue()
			game.level_time = 25.0
			game.banner_timer = 0
			game.banner_label.hide()
			for row in range(6):
				for col in range(4):
					game.grid[row][col] = game._create_plant(["sunflower", "repeater", "snow_pea", "wallnut"][col], row, col)
					game.grid[row][col].spawn_time = 0.0
				game._spawn_zombie_at("conehead" if row % 2 else "normal", row, game._cell_center(row, 6).x, true)
				game.zombies.back().spawn_time = 0.0
			var label := "%dx%d-%s" % [viewport.x, viewport.y, choice]
			if choice == "easy":
				await snapshot(game, label + "-road")
			game._spawn_zombie_at("reimu_boss", 2, game._boss_anchor_x("reimu_boss"), true)
			var boss: Dictionary = game.zombies.back()
			boss.spawn_time = 0.0
			game._ensure_reimu_runtime().update(3.0)
			var cards: Array = game.TouhouSpellDefs.cards_for("reimu_boss", game.current_level)
			for cycle in range(cards.size()):
				boss.touhou_encounter.index = cycle
				boss.touhou_encounter.attack = boss.touhou_encounter.phases[cycle].size() - 1
				boss.touhou_encounter.depleted = false
				game.TouhouPhaseRuntime._set_bounds(boss)
				boss.health = boss.touhou_encounter.ceiling
				game._trigger_boss_skill(boss)
				game.touhou_danmaku.update(1.65)
				game.reimu_runtime.update(1.1)
				game._update_effects(1.65)
				game.banner_timer = 0.0
				game.banner_label.hide()
				await snapshot(game, label + "-" + String(cards[cycle][0]))
			game.save_dirty = false
			game.free()
	quit()

func snapshot(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	var path := "%s/%s.png" % [CAPTURE_PATH, label]
	print("Reimu capture %s: %s" % [label, error_string(capture.save_png(path))])
