extends "res://scripts/tools/capture_battle_polish.gd"

const Level = preload("res://scripts/data/mokou_level_defs.gd")
const CAPTURE_DIR := "res://output/mokou"
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var capture = OS.get_cmdline_user_args().has("--capture")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	for viewport in [Vector2i(1600,900),Vector2i(844,390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x==844 else 0
		surface.add_child(game)
		for choice in ["extra","extra_plus"]:
			var level: Dictionary = game.TouhouDifficulty.build_level(Level.LEVEL,choice)
			level.custom_level = true
			game._begin_level(-1,["sunflower","snow_pea","mirror_reed","wallnut","ice_shroom","pressure_bamboo"],level)
			game.rng.seed = 925
			game._drain_asset_prewarm_queue()
			game._try_play_pending_bgm()
			check(game.board_rows==6,"Six dry bamboo lanes")
			check(game.current_bgm_path==level.boss_intro_bgm,"Road plays supplied Extra music")
			if capture and choice=="extra": await save_capture(game,"%d-road" % viewport.x)
			for row in range(6):
				game.grid[row][0] = game._create_plant("wallnut",row,0)
				game.grid[row][0].health = 100000
				game.grid[row][0].max_health = 100000
			game._spawn_frozen_branch_midboss()
			var road: Dictionary = game._find_alive_enemy_boss("hakutaku_boss")
			check(not road.is_empty() and road.touhou_encounter.phases.size()==(3 if choice=="extra" else 4),"Half-beast Keine keeps full spell route")
			game.next_event_index = level.events.size()
			game.batch_spawn_queue = [{"kind":"mokou_boss","row":2,"progress_event":true}]
			game.batch_spawn_remaining = 1
			for frame in range(35): game._process(0.1)
			check(game._find_alive_enemy_boss("mokou_boss").is_empty() and game.frozen_branch_progress_locked,"Living Keine blocks pending finale")
			if capture and choice=="extra": await save_capture(game,"%d-keine" % viewport.x)
			for frame in range(800):
				game._apply_zombie_damage(road,1000000,0,0,true)
				game._process(0.1)
				if not game._find_alive_enemy_boss("mokou_boss").is_empty(): break
			game._try_play_pending_bgm()
			var boss: Dictionary = game._find_alive_enemy_boss("mokou_boss")
			check(not boss.is_empty() and game.frozen_branch_midboss_cleared,"Mokou enters after all Keine spells finish")
			if boss.is_empty():
				game.free()
				quit(1)
				return
			check(game.current_bgm_path==level.boss_bgm,"Finale switches to supplied Mokou track")
			game.zombies = [boss]
			game.touhou_danmaku.clear()
			var rt = game._ensure_mokou_runtime()
			for row in range(6):
				for col in range(4):
					game.grid[row][col] = game._create_plant(["snow_pea","pressure_bamboo","healing_gourd","wallnut"][col],row,col)
					game.grid[row][col].spawn_time = 0
			boss.spawn_time = 0
			boss.touhou_encounter.index = 3
			boss.touhou_encounter.attack = 0
			game._trigger_boss_skill(boss)
			rt.update(0.7)
			game.touhou_danmaku.update(0.7)
			game.banner_timer = 0
			game.banner_label.visible = false
			game._ensure_reimu_runtime().update(3)
			if capture: await save_capture(game,"%d-pingpong-%s" % [viewport.x,choice])
			var age = float(rt.rallies[0].age)
			game.battle_paused = true
			game._process(2)
			check(rt.rallies[0].age==age,"Game pause stops paddle mechanics")
			game.battle_paused = false
			boss.touhou_encounter.index = boss.touhou_encounter.phases.size()-1
			game._trigger_boss_skill(boss)
			game.touhou_danmaku.update(2.8)
			check(boss.touhou_invulnerable and rt.rallies.is_empty(),"Last spell is survival and clears previous gimmick")
			if capture: await save_capture(game,"%d-imperishable-%s" % [viewport.x,choice])
			game._begin_level(-1,[],level)
			check(rt.rallies.is_empty() and rt.marks.is_empty() and game.touhou_danmaku.casts.is_empty(),"Retry clears every encounter effect")
		game.save_dirty = false
		for child in game.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
		# Flush the stopped playback while its SubViewport still owns the audio bus.
		await create_timer(0.15).timeout
		game.free()
		surface.free()
	# Give the audio mixer a block to release the stopped MP3/SFX playbacks.
	await create_timer(0.2).timeout
	print("3-25 midboss gate, music, pause, restart and desktop/mobile: %d failure(s)" % failures)
	quit(1 if failures else 0)

func save_capture(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var im: Image = game.get_viewport().get_texture().get_image()
	check(im.save_png("%s/%s.png" % [CAPTURE_DIR,label])==OK,"Capture saved")
