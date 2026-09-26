extends "res://scripts/tools/capture_battle_polish.gd"

const CAPTURE_DIR := "res://output/touhou-self-midboss"
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		root.size = viewport
		root.content_scale_size = viewport
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x == 844 else 0
		root.add_child(game)
		for id in ["1-21", "3-19", "3-22-b"]:
			var base: Dictionary = {}
			for level in GameScript.Defs.LEVELS:
				if level.id == id:
					base = level.duplicate(true)
			base.custom_level = true
			var level: Dictionary = game.TouhouDifficulty.build_level(base, "easy")
			game._begin_level(-1, [], level)
			game._drain_asset_prewarm_queue()
			game._try_play_pending_bgm()
			game.rng.seed = 913
			# Clocktower strikes legitimately damage both sides; isolate boss timer HP here.
			game.scarlet_clock_hazard_timer = 1000.0
			# Keep the battle alive while exercising the real frame loop and director.
			for row in game.active_rows:
				var blocker: Dictionary = game._create_plant("wallnut", row, 0)
				blocker.health = 100000
				blocker.max_health = 100000
				game.grid[row][0] = blocker
			game._spawn_frozen_branch_midboss()
			var road: Dictionary = game.zombies.back()
			var health := float(road.health)
			var progress := float(game._battle_progress_ratio())
			game.next_event_index = 1
			game.batch_spawn_queue = [{"kind": "normal", "row": 0, "progress_event": true}]
			game.batch_spawn_remaining = 1
			for frame in range(200):
				game._process(0.1)
			check(game.zombies.size() > 1 and game.zombies.has(road), "%s live road must have minions and survive 20 seconds without player damage" % id)
			check(is_equal_approx(float(road.health), health), "%s live road must not lose HP on a timer" % id)
			check(game.next_event_index == 1 and game.base_events_spawned == 0 and is_equal_approx(game._battle_progress_ratio(), progress), "%s live frame loop must freeze waves and progress" % id)
			check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "%s road must actually play stage music" % id)
			game.battle_paused = true
			var time := float(game.level_time)
			var timer := float(road.rumia_reinforcement_timer)
			game._process(1.0)
			check(game.level_time == time and road.rumia_reinforcement_timer == timer, "Pause must freeze the road fight and its reinforcements")
			game.battle_paused = false
			if capture:
				await _save_capture(game, "%s-%d-road" % [id, viewport.x])
			var minions := game.zombies.size() - 1
			game._apply_zombie_damage(road, 1000000, 0, 0, true)
			game._process(0.1)
			for frame in range(60):
				game._process(0.1)
				if game.base_events_spawned == 1:
					break
			check(game.frozen_branch_midboss_cleared and not game.zombies.has(road), "%s player damage must clear the road gate" % id)
			check(game.base_events_spawned == 1 and game.zombies.size() >= minions, "%s queued wave must resume with surviving minions" % id)
			check(game.current_bgm_path == level.boss_intro_bgm, "%s road defeat must keep stage music" % id)
			game.batch_spawn_queue = [{"kind": level.mid_boss_kind, "row": 2}]
			game.batch_spawn_remaining = 1
			game.spawn_director_timer = 0
			game._update_spawn_director(1.0)
			game._try_play_pending_bgm()
			var finale: Dictionary = game.zombies.back()
			check(game._is_stage_ending_boss(finale) and float(finale.max_health) > health * 6, "%s finale must have fresh identity and substantially more HP" % id)
			check(game.current_bgm_path == level.boss_bgm and game.music_player.playing, "%s finale must actually switch the music" % id)
			if capture:
				await _save_capture(game, "%s-%d-finale" % [id, viewport.x])
		game.save_dirty = false
		for child in game.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
		game.free()
	# Audio mixing releases stopped playback handles asynchronously.
	await create_timer(0.2).timeout
	print("Self-midboss live frames: road minions, fixed waves, damage defeat, resumed events, music and desktop/mobile HUD; %d failure(s)" % failures)
	quit(1 if failures else 0)


func _save_capture(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	check(capture.save_png("%s/%s.png" % [CAPTURE_DIR, label]) == OK, "Battle capture must save")
