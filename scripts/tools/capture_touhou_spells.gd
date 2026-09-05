extends "res://scripts/tools/capture_battle_polish.gd"


func _run() -> void:
	await process_frame
	for child in root.get_children():
		if child is GameScript:
			child.save_dirty = false
			child.free()
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var cases := [
		["cirno_boss", 1], ["sakuya_boss", 2], ["flandre_boss", 2],
		["flandre_boss", 6], ["yukari_boss", 10], ["youmu_boss", 5], ["yuyuko_boss", 0],
		["patchouli_boss", 0, true], ["patchouli_boss", 1, true], ["patchouli_boss", 2, true], ["cirno_boss", 0, true],
		["youmu_boss", 1], ["youmu_boss", 3], ["youmu_boss", 4], ["youmu_boss", 0, true],
		["alice_boss", 3], ["ran_boss", 7], ["yukari_boss", 7], ["flandre_boss", 5],
	]
	for kind in GameScript.TouhouSpellDefs.CARDS:
		if not ["cirno_boss", "sakuya_boss", "flandre_boss", "yukari_boss", "youmu_boss", "yuyuko_boss"].has(kind):
			cases.append([kind, 0])
	for viewport in [Vector2i(1600, 900), Vector2i(1365, 768), Vector2i(2000, 900)]:
		root.size = viewport
		root.content_scale_size = viewport
		for spec in cases:
			if viewport.x != 1600 and not String(spec[0]) in ["flandre_boss", "yukari_boss", "youmu_boss", "alice_boss", "ran_boss", "prismriver_boss"]:
				continue
			root.mode = Window.MODE_WINDOWED
			root.size = viewport
			var game := PreviewGame.new()
			game.size = Vector2(viewport)
			game.mobile_runtime_override = 1 if viewport.x == 2000 else 0
			root.add_child(game)
			game._begin_level(-1, ["sunflower", "peashooter", "snow_pea", "repeater", "wallnut", "cherry_bomb"], {
				"id": "canon-preview", "title": "", "terrain": "day", "start_sun": 450,
				"events": [{"time": 999.0, "kind": "normal", "row": 2}],
				"row_count": 6 if viewport.x == 1365 else 5, "custom_level": true,
				"mid_boss_kind": String(spec[0]) if spec.size() > 2 else "",
			})
			game.rng.seed = 906
			for row in game.active_rows:
				for col in range(4):
					var kind: String = ["sunflower", "peashooter", "repeater", "wallnut"][col]
					game.grid[row][col] = game._create_plant(kind, row, col)
					game.grid[row][col]["spawn_time"] = 0.0
			for kind in [String(spec[0]), "chen_boss", "ran_boss"]:
				game._queue_boss_frame_set_prewarm(kind)
			game._drain_asset_prewarm_queue()
			game._spawn_zombie_at(String(spec[0]), 2, game._boss_anchor_x(String(spec[0])), true)
			var boss: Dictionary = game.zombies.back()
			boss["spawn_time"] = 0.0
			boss["boss_skill_cycle"] = int(spec[1])
			boss["boss_phase"] = 1
			boss["hover_shift_timer"] = 100.0
			boss["rumia_reinforcement_timer"] = 100.0
			game.level_time = 10.0
			boss = game._trigger_yuyuko_boss_revival(boss) if String(spec[0]) == "yuyuko_boss" else game._trigger_boss_skill(boss)
			game.zombies[0] = boss
			for frame in range(60):
				game.level_time += 1.0 / 60.0
				game.boss_time_stop_timer = maxf(0.0, game.boss_time_stop_timer - 1.0 / 60.0)
				game._update_zombies(1.0 / 60.0)
				game.touhou_danmaku.update(1.0 / 60.0)
				game._update_effects(1.0 / 60.0)
				if frame == 23 and String(spec[0]) == "youmu_boss" and int(spec[1]) == 1:
					game.banner_label.visible = false
					await _capture(game, "touhou-%dx%d-youmu-focus" % [viewport.x, viewport.y])
			game.banner_label.visible = false
			var suffix = "-midboss" if spec.size() > 2 else ""
			await _capture(game, "touhou-%dx%d-%s-%d%s" % [viewport.x, viewport.y, spec[0], spec[1], suffix])
			if String(spec[0]) == "youmu_boss" and int(spec[1]) == 5:
				game._charm_plant_at_cell(2, 2, 4.4)
				game._update_plants(0.2)
				await _capture(game, "touhou-%dx%d-youmu-charm" % [viewport.x, viewport.y])
			game.save_dirty = false
			game.free()
	quit()


func _capture(game: Control, label: String) -> void:
	var expected = Vector2i(game.size)
	for attempt in range(5):
		root.mode = Window.MODE_WINDOWED
		root.size = expected
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var capture = root.get_texture().get_image()
		if capture.get_size() != expected:
			continue
		var result = capture.save_png("%s/%s.png" % [OUTPUT_DIR, label])
		print("Capture %s: %s (%s)" % [label, error_string(result), capture.get_size()])
		return
	push_error("Capture viewport did not settle: %s" % label)
	quit(1)
