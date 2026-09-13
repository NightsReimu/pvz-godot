extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0
const CAPTURE_DIR := "res://output/reisen"

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		root.size = viewport
		root.content_scale_size = viewport
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x == 844 else 0
		root.add_child(game)
		for choice in ["easy", "normal", "hard", "lunatic"]:
			var base: Dictionary = {}
			for entry in GameScript.Defs.LEVELS:
				if entry.id == "3-23":
					base = entry.duplicate(true)
			base.custom_level = true
			var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
			game._begin_level(-1, ["sunflower", "repeater", "wallnut", "snow_pea", "healing_gourd", "cherry_bomb"], level)
			game.rng.seed = 923
			game._drain_asset_prewarm_queue()
			game._try_play_pending_bgm()
			check(game.board_rows == 6 and game.active_rows.size() == 6, "All six grass lanes must be active")
			for row in range(6):
				for col in range(9):
					check(game._cell_terrain_kind(row, col) == "land", "No corridor square can become water or void")
				var plant: Dictionary = game._create_plant("wallnut", row, 0)
				plant.health = 100000
				plant.max_health = 100000
				game.grid[row][0] = plant
			game._spawn_frozen_branch_midboss()
			var road: Dictionary = game.zombies.back()
			check(road.kind == "tewi_boss" and road.get("touhou_road_nonspell", false), "The road boss must be Tewi with her own identity")
			check(not road.get("touhou_final_preview", false), "Tewi must not use same-character preview HP scaling")
			var road_health := float(road.health)
			var progress := float(game._battle_progress_ratio())
			var stable_cell := game._cell_center(2, 3)
			game.next_event_index = level.events.size()
			game.batch_spawn_queue = [{"kind": "reisen_boss", "row": 2, "progress_event": true}]
			game.batch_spawn_remaining = 1
			for frame in range(200):
				game._process(0.1)
			check(game.zombies.size() > 1 and game._find_alive_enemy_boss("reisen_boss").is_empty(), "Road minions spawn while the finale remains gated")
			check(road.health == road_health and game.base_events_spawned == 0 and is_equal_approx(progress, game._battle_progress_ratio()), "Twenty seconds cannot withdraw the road boss or advance waves")
			check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "Tewi retains the supplied stage BGM")
			check(game._cell_center(2, 3) == stable_cell, "Rotating background cannot change combat coordinates")
			if capture and choice == "easy":
				await save_capture(game, "%d-tewi" % viewport.x)
			game._apply_zombie_damage(road, 1000000, 0, 0, true)
			for frame in range(30):
				game._process(0.1)
				if not game._find_alive_enemy_boss("reisen_boss").is_empty():
					break
			game._try_play_pending_bgm()
			var boss := game._find_alive_enemy_boss("reisen_boss")
			check(not boss.is_empty() and game.frozen_branch_midboss_cleared, "Player defeat opens the gate and spawns Reisen")
			check(float(boss.max_health) > road_health * 6 and game.current_bgm_path == level.boss_bgm and game.music_player.playing, "Finale has substantially more HP and actually switches BGM")
			check(game.zombies.all(func(z): return not z.has("tewi_luck_until")), "Tewi's buff must end on defeat")
			var runtime = game._ensure_reisen_runtime()
			for row in range(6):
				for col in range(1, 4):
					var plant: Dictionary = game._create_plant(["repeater", "snow_pea", "wallnut"][col - 1], row, col)
					plant.spawn_time = 0
					plant.health = 100000
					plant.max_health = 100000
					game.grid[row][col] = plant
			game.grid[2][2] = game._create_plant("healing_gourd", 2, 2)
			game.zombies = game.zombies.filter(func(z): return String(z.kind) == "reisen_boss")
			for row in range(6):
				game._spawn_zombie_at("moon_rabbit_guard" if row % 2 == 0 else "moon_rabbit", row, game._cell_center(row, 7).x, true)
				game.zombies.back().spawn_time = 0
			boss.spawn_time = 0
			var phases: Array = boss.touhou_encounter.phases
			boss.touhou_encounter.index = 3 if choice == "easy" else phases.size() - 2
			boss.touhou_encounter.attack = 1 if choice == "easy" else 0
			game._trigger_boss_skill(boss)
			for frame in range(18):
				game.level_time += 0.1
				runtime.update(0.1)
				game.touhou_danmaku.update(0.1)
			game.battle_paused = true
			var time := float(game.level_time)
			var eye_age: float = runtime.eyes[0].age if not runtime.eyes.is_empty() else -1.0
			game._process(2.0)
			check(game.level_time == time and (runtime.eyes.is_empty() or runtime.eyes[0].age == eye_age), "Pause freezes corridor effects and timers")
			game.battle_paused = false
			game.banner_timer = 0
			game.banner_label.visible = false
			if capture and choice in ["easy", "lunatic"]:
				await save_capture(game, "%d-reisen-%s" % [viewport.x, choice])
			game._begin_level(-1, [], level)
			check(runtime.eyes.is_empty() and runtime.eclipse.is_empty() and runtime.darkness == 0 and game.zombies.is_empty(), "Retry removes temporary fields, portals and enemies")
		game.save_dirty = false
		game.free()
	await process_frame
	print("3-23 live road/finale, four difficulties, stage/boss BGM, grass grid, pause, retry and two screen sizes: %d failure(s)" % failures)
	quit(1 if failures else 0)

func save_capture(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("%s/%s.png" % [CAPTURE_DIR, label]) == OK, "Native battle capture must save")
