extends "res://scripts/tools/capture_ui_layout.gd"

func _run() -> void:
	var directory := "res://output/spell-declarations"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.mode = Window.MODE_WINDOWED
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		for kind in ["reimu_boss", "marisa_boss", "sakuya_boss", "yuyuko_boss"]:
			var surface := SubViewport.new()
			surface.size = viewport
			surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(surface)
			var game := PreviewGame.new()
			game.size = Vector2(viewport)
			game.mobile_runtime_override = 1 if viewport.y < 600 else 0
			surface.add_child(game)
			game.set_process_unhandled_input(false)
			var id := "3-22-b" if kind == "marisa_boss" else "3-22-a"
			var level: Dictionary = GameScript.Defs.LEVELS[game._find_level_index_by_id(id)].duplicate(true)
			level.events = [{"time": 99999.0, "kind": kind, "row": 2}]
			level.touhou_difficulty = "normal"
			game._begin_level(-1, ["sunflower", "repeater", "snow_pea", "wallnut", "cherry_bomb"], level)
			game.level_time = 12.0
			game._queue_boss_frame_set_prewarm(kind)
			game._drain_asset_prewarm_queue()
			for row in game.active_rows:
				for col in range(4):
					game.grid[row][col] = game._create_plant(["sunflower", "repeater", "snow_pea", "wallnut"][col], row, col)
					game.grid[row][col].spawn_time = 0.0
			game._spawn_zombie_at(kind, 2, game._boss_anchor_x(kind), true)
			var boss: Dictionary = game.zombies.back()
			boss.spawn_time = 0.0
			boss.erase("touhou_encounter")
			boss.boss_skill_cycle = 0
			game._trigger_boss_skill(boss)
			var previous := 0.0
			for age in [0.15, 0.55, 1.4, 1.8]:
				game.touhou_danmaku.update(age - previous)
				game.level_time += age - previous
				previous = age
				game.effects.clear()
				game.banner_label.hide()
				game.toast_label.hide()
				game.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var path := "%s/%s-%dx%d-%.2f.png" % [directory, kind, viewport.x, viewport.y, age]
				var result := surface.get_texture().get_image().save_png(path)
				print("%s: %s" % [path, error_string(result)])
			game.save_dirty = false
			surface.free()
	quit()
