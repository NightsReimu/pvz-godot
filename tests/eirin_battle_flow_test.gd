extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0
const CAPTURE_DIR := "res://output/eirin"

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x == 844 else 0
		surface.add_child(game)
		for choice in ["easy", "normal", "hard", "lunatic"]:
			var base: Dictionary = {}
			for entry in GameScript.Defs.LEVELS:
				if entry.id == "3-24-a":
					base = entry.duplicate(true)
			base.custom_level = true
			var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
			game._begin_level(-1, ["sunflower", "repeater", "wallnut", "snow_pea", "healing_gourd", "cherry_bomb"], level)
			game.rng.seed = 924
			game._drain_asset_prewarm_queue()
			game._try_play_pending_bgm()
			check(game.board_rows == 6 and game.active_rows.size() == 6, "Six corridor lanes")
			for row in range(6):
				var wall: Dictionary = game._create_plant("wallnut", row, 0)
				wall.health = 100000
				wall.max_health = 100000
				game.grid[row][0] = wall
			game._spawn_frozen_branch_midboss()
			var road: Dictionary = game.zombies.back()
			var hp := float(road.health)
			check(road.kind == "eirin_boss" and road.touhou_final_preview, "Eirin is her own road encounter")
			var progress := float(game._battle_progress_ratio())
			var stable_cell := game._cell_center(2, 3)
			game.next_event_index = level.events.size()
			game.batch_spawn_queue = [{"kind": "eirin_boss", "row": 2, "progress_event": true}]
			game.batch_spawn_remaining = 1
			for frame in range(200):
				game._process(0.1)
			check(road.health == hp and game.zombies.size() > 1 and game.base_events_spawned == 0 and is_equal_approx(progress, game._battle_progress_ratio()), "Road minions spawn but waves stay frozen; no timed retreat")
			check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "Road retains supplied stage music")
			if capture and choice == "easy":
				await save_capture(game, "%d-corridor" % viewport.x)
			game._apply_zombie_damage(road, 1000000, 0, 0, true)
			game._process(0.1)
			game._process(0.1)
			check(game._find_alive_enemy_boss("eirin_boss").is_empty(), "Defeated road does not immediately become the finale")
			for frame in range(15):
				game._process(0.1)
			var rt = game._ensure_eirin_runtime()
			check(rt.exit_age > 0 and not rt.sky and game.current_bgm_path == level.boss_intro_bgm, "Corridor exit precedes finale and BGM switch")
			if capture and choice == "easy":
				await save_capture(game, "%d-exit" % viewport.x)
			for frame in range(40):
				game._process(0.1)
				if not game._find_alive_enemy_boss("eirin_boss").is_empty():
					break
			game._try_play_pending_bgm()
			var boss := game._find_alive_enemy_boss("eirin_boss")
			check(not boss.is_empty() and rt.sky and game.frozen_branch_midboss_cleared, "Exit opens the sky finale")
			if boss.is_empty():
				game.free()
				quit(1)
				return
			check(is_equal_approx(float(boss.max_health) * 0.12, hp) and game.current_bgm_path == level.boss_bgm and game.music_player.playing, "Finale has full HP and supplied boss music")
			game.zombies = [boss]
			game.touhou_danmaku.clear()
			for row in range(6):
				for col in range(4):
					var plant: Dictionary = game._create_plant(["cabbage_pult", "melon_pult", "healing_gourd", "pressure_bamboo"][col], row, col)
					plant.spawn_time = 0
					game.grid[row][col] = plant
			for item in [["kedama", 0], ["star_fairy", 1], ["moon_rabbit_guard", 2], ["rabbit_airship", 3], ["snorkel", 4], ["catapult_zombie", 5]]:
				game._spawn_zombie_at(item[0], item[1], game._cell_center(item[1], 6).x, true)
				game.zombies.back().spawn_time = 0
			boss.spawn_time = 0
			boss.rumia_state = "special"
			rt.world_timer = 100.0
			rt.switch_world(boss)
			for cell in [[Vector2i(0, 4), "water"], [Vector2i(2, 4), "lava"], [Vector2i(4, 4), "roof"]]:
				rt.queue_tile(boss, cell[0], cell[1])
			if capture and choice == "easy":
				await save_capture(game, "%d-warning" % viewport.x)
			rt.update(2.1)
			check(game._cell_center(2, 3) == stable_cell, "World changes never move the board's input coordinates")
			check(game.grid[2][2] != null, "Terrain changes do not delete existing plants")
			rt.start_medicine(boss, "suppression")
			rt.start_medicine(boss, "rage")
			rt.update(2.1)
			for z in game.zombies:
				z.spawn_time = 0.0
			boss.touhou_encounter.index = 3
			boss.touhou_encounter.attack = 1
			game._trigger_boss_skill(boss)
			game.touhou_danmaku.update(1.0)
			game.battle_paused = true
			var time := float(game.level_time)
			var age: float = rt.tiles[0].age
			game._process(2.0)
			check(game.level_time == time and rt.tiles[0].age == age, "Pause freezes new runtime and terrain expiry")
			game.battle_paused = false
			game.banner_timer = 0
			game.banner_label.visible = false
			if capture and choice in ["easy", "lunatic"]:
				await save_capture(game, "%d-moon-%s" % [viewport.x, choice])
			game._begin_level(-1, [], level)
			check(rt.tiles.is_empty() and rt.medicine.is_empty() and not rt.sky and game.zombies.is_empty(), "Retry restores corridor and removes all temporary state")
		game.save_dirty = false
		game.free()
		surface.free()
	await process_frame
	print("3-24-a live flow, music, four difficulties, pause, retry, and two screen sizes: %d failure(s)" % failures)
	quit(1 if failures else 0)

func save_capture(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var picture: Image = game.get_viewport().get_texture().get_image()
	check(picture.get_size() == Vector2i(game.size), "Capture uses the requested resolution")
	check(picture.save_png("%s/%s.png" % [CAPTURE_DIR, label]) == OK, "Capture saves")
