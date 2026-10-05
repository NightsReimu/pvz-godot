extends "res://scripts/tools/capture_battle_polish.gd"

const AKI_OUTPUT := "res://output/v172"

func _shot(game: Control, name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	print("Capture %s: %s" % [name, error_string(root.get_texture().get_image().save_png("%s/%s.png" % [AKI_OUTPUT, name]))])

func _run() -> void:
	await process_frame
	for child in root.get_children():
		if child is GameScript:
			child.save_dirty = false
			child.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AKI_OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		for pattern in ["aki_falling_leaves", "aki_grain_promise", "aki_ripening", "aki_feast"]:
			root.size = viewport
			root.content_scale_size = viewport
			var game := PreviewGame.new()
			game.size = Vector2(viewport)
			game.mobile_runtime_override = 1 if viewport.y < 600 else 0
			root.add_child(game)
			var base: Dictionary = {}
			for level in GameScript.Defs.LEVELS:
				if level.id == "4-19": base = level.duplicate(true)
			var level: Dictionary = game.TouhouDifficulty.build_level(base, "lunatic" if pattern == "aki_feast" else "hard")
			level.custom_level = true
			game._begin_level(-1, ["repeater", "melon_pult", "healing_gourd", "umbrella_leaf", "torchwood", "wallnut"], level)
			game._drain_asset_prewarm_queue()
			game.rng.seed = 419
			game.level_time = 148.0
			game.ui_time = 8.0
			game.battle_intro_timer = 0.0
			for row in range(6):
				for col in range(5):
					game.grid[row][col] = game._create_plant(["repeater", "healing_gourd", "melon_pult", "torchwood", "wallnut"][col], row, col)
					game.grid[row][col].spawn_time = 0.0
					game.grid[row][col].ultimate_charge = 0.75
			game._spawn_zombie_at("conehead", 0, game._cell_center(0, 7).x, true)
			game._spawn_zombie_at("newspaper", 5, game._cell_center(5, 7).x, true)
			game._spawn_zombie_at("buckethead", 3, game._cell_center(3, 6).x, true)
			var kind := "shizuha_boss" if pattern == "aki_falling_leaves" else "minoriko_boss"
			game._spawn_zombie_at(kind, 2, game._boss_anchor_x(kind), true)
			for z in game.zombies: z.spawn_time = 0.0
			var boss: Dictionary = game.zombies.back()
			var encounter: Dictionary = boss.touhou_encounter
			for phase in range(encounter.phases.size()):
				for attack in range(encounter.phases[phase].size()):
					if String(encounter.phases[phase][attack][2]) == pattern:
						encounter.index = phase
						encounter.attack = attack
			game.TouhouPhaseRuntime._set_bounds(boss)
			boss.health = encounter.ceiling
			game._trigger_boss_skill(boss)
			var duration := 6.5 if pattern == "aki_ripening" else 2.7
			for i in range(int(duration / 0.02)):
				game.level_time += 0.02
				game.aki_runtime.update(0.02)
				game.touhou_danmaku.update(0.02)
				game._update_effects(0.02)
			game.banner_timer = 0.0
			game.banner_label.visible = false
			game.toast_label.visible = false
			await _shot(game, "aki-%s-%dx%d" % [pattern, viewport.x, viewport.y])
			game._stop_bgm()
			if game.music_player != null: game.music_player.stream = null
			await create_timer(0.15).timeout
			game.save_dirty = false
			game.free()
	quit()
