extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0
const CAPTURE_DIR := "res://output/kaguya"

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	for viewport in [Vector2i(1600,900),Vector2i(844,390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x == 844 else 0
		surface.add_child(game)
		for choice in ["easy","normal","hard","lunatic"]:
			var base: Dictionary = {}
			for entry in GameScript.Defs.LEVELS:
				if entry.id == "3-24-b": base = entry.duplicate(true)
			base.custom_level = true
			var level: Dictionary = game.TouhouDifficulty.build_level(base,choice)
			game._begin_level(-1,["sunflower","repeater","wallnut","healing_gourd","cherry_bomb","lily_pad","flower_pot","cork_plug"],level)
			game.rng.seed = 924
			game._drain_asset_prewarm_queue()
			game._try_play_pending_bgm()
			check(game.board_rows == 6,"Six corridor lanes")
			for row in range(6):
				var wall: Dictionary = game._create_plant("wallnut",row,0)
				wall.health = 100000
				wall.max_health = 100000
				game.grid[row][0] = wall
			game._spawn_frozen_branch_midboss()
			var road: Dictionary = game.zombies.back()
			var hp := float(road.health)
			check(road.kind == "eirin_boss" and road.touhou_final_preview,"6B reuses Eirin's short road encounter")
			var progress := float(game._battle_progress_ratio())
			game.next_event_index = level.events.size()
			game.batch_spawn_queue = [{"kind":"kaguya_boss","row":2,"progress_event":true}]
			game.batch_spawn_remaining = 1
			for frame in range(200): game._process(0.1)
			check(road.health == hp and game.zombies.size()>1 and game.base_events_spawned == 0 and is_equal_approx(progress,game._battle_progress_ratio()),"Road waits for defeat, spawns minions, freezes wave progress")
			check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing,"Road music is 6A's supplied BGM")
			check(game._find_alive_enemy_boss("kaguya_boss").is_empty(),"Finale cannot overlap living Eirin")
			if capture and choice == "easy": await save_capture(game,"%d-corridor" % viewport.x)
			game._apply_zombie_damage(road,1000000,0,0,true)
			for frame in range(17): game._process(0.1)
			var world = game._ensure_eirin_runtime()
			check(world.exit_age>0 and not world.sky and game.current_bgm_path == level.boss_intro_bgm,"Corridor exit retains road music")
			for frame in range(40):
				game._process(0.1)
				if not game._find_alive_enemy_boss("kaguya_boss").is_empty(): break
			game._try_play_pending_bgm()
			var boss := game._find_alive_enemy_boss("kaguya_boss")
			check(not boss.is_empty() and world.sky and game.frozen_branch_midboss_cleared,"Kaguya enters only after Eirin's defeat and corridor exit")
			if boss.is_empty():
				game.free()
				quit(1)
				return
			check(game.current_bgm_path == level.boss_bgm and game.music_player.playing,"Finale switches to supplied Kaguya BGM")
			check(is_equal_approx(hp,float(boss.max_health)*42000/44000*0.12),"Eirin road HP remains identical to A despite another finale")
			game.zombies = [boss]
			game.touhou_danmaku.clear()
			for row in range(6):
				for col in range(4):
					game.grid[row][col] = game._create_plant(["cabbage_pult","melon_pult","healing_gourd","pressure_bamboo"][col],row,col)
					game.grid[row][col].spawn_time = 0
			for item in [["star_fairy",0],["moon_rabbit_guard",1],["rabbit_airship",3],["kedama",4],["snorkel",5]]:
				game._spawn_zombie_at(item[0],item[1],game._cell_center(item[1],6).x,true)
				game.zombies.back().spawn_time = 0
			boss.spawn_time = 0
			world.world_timer = 100
			var rt = game._ensure_kaguya_runtime()
			world.switch_world(boss)
			world.update(2.1)
			boss.touhou_encounter.index = 3
			boss.touhou_encounter.attack = 1
			game._trigger_boss_skill(boss)
			game.touhou_danmaku.update(1.7)
			rt.update(2.1)
			for z in game.zombies: z.spawn_time = 0
			rt.cast(boss,"kaguya_dragon")
			rt.update(0.8)
			game.banner_timer = 0
			game.banner_label.visible = false
			game.battle_paused = true
			var age := float(rt.rewind.age)
			game._process(1)
			check(rt.rewind.age == age,"Pause freezes rewind and hazards")
			game.battle_paused = false
			if capture and choice in ["easy","lunatic"]: await save_capture(game,"%d-moon-%s" % [viewport.x,choice])
			game._begin_level(-1,[],level)
			check(rt.rewind.is_empty() and rt.treasures.is_empty() and world.tiles.is_empty() and not world.sky,"Retry clears time, treasures and terrain")
		game.save_dirty = false
		game.music_player.stop()
		game.music_player.stream = null
		for child in game.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
		await create_timer(0.1).timeout
		game.free()
		surface.free()
	await process_frame
	print("6B road/finale/music, four difficulties, pause, retry and two resolutions: %d failure(s)" % failures)
	quit(1 if failures else 0)

func save_capture(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var im: Image = game.get_viewport().get_texture().get_image()
	check(im.get_size() == Vector2i(game.size),"Requested screenshot resolution")
	check(im.save_png("%s/%s.png" % [CAPTURE_DIR,label]) == OK,"Capture saved")
