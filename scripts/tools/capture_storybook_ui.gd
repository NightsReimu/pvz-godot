extends "res://scripts/tools/capture_ui_layout.gd"

class MotionPreview extends PreviewGame:
	var pointer := Vector2(-9999, -9999)
	func _pointer_local_position() -> Vector2:
		return pointer


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	if "modals" in OS.get_cmdline_user_args():
		await _capture_modals()
		quit()
		return
	var directory := "res://output/storybook-ui/motion"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var surface := SubViewport.new()
	surface.size = Vector2i(1600, 900)
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	var game := MotionPreview.new()
	game.size = Vector2(surface.size)
	surface.add_child(game)
	game.set_process_unhandled_input(false)
	game.completed_levels.resize(Defs.LEVELS.size())
	game.completed_levels.fill(true)
	game.unlocked_levels = Defs.LEVELS.size()
	game.coins_total = 12345
	game.current_world_key = "day"
	game.world_select_index = 0
	for page in ["home", "world_select", "minigames"]:
		game.mode = page
		game.pointer = Vector2(-9999, -9999)
		for frame in range(24):
			if frame == 5:
				game.pointer = Rect2(game._home_action_rects().daily).get_center() if page == "home" else (game._world_card_rect(2).get_center() if page == "world_select" else game.MinigameMenu.card_rect(0).get_center())
			if frame == 8 and page == "world_select":
				game.world_select_index = 2
			if frame == 16:
				game.storybook_ui.click(game.pointer)
				if page == "world_select":
					game.world_select_index = 6
			for tick in range(5):
				game.ui_time += 1.0 / 60.0
				game.storybook_ui.update(game, 1.0 / 60.0)
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "%s/%s-%02d.png" % [directory, page, frame]
			surface.get_texture().get_image().save_png(path)
	for index in range(7):
		game.mode = game.MODE_WORLD_SELECT
		game.world_select_index = index
		game.ui_time += 1.0
		game.storybook_ui.update(game, 1.0)
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		surface.get_texture().get_image().save_png("%s/world-%d.png" % [directory, index])
	game.completed_levels.fill(false)
	game.unlocked_levels = 1
	game.world_select_index = 6
	game.ui_time += 1
	game.storybook_ui.update(game, 1)
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	surface.get_texture().get_image().save_png(directory + "/world-locked.png")
	game.mode = game.MODE_HOME
	game._show_message("庭院守住了！\n获得 200 金币", "home", "返回庭院")
	await create_timer(0.35).timeout
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	surface.get_texture().get_image().save_png(directory + "/result-popup.png")
	game.message_panel.hide()
	game.save_dirty = false
	surface.free()
	await process_frame
	await process_frame
	print("Storybook native motion: 72 frames, seven world previews and locked state captured")
	quit()


func _capture_modals() -> void:
	var directory := "res://output/storybook-ui/modals"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := MotionPreview.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x < 1000 else 0
		surface.add_child(game)
		game.set_process_unhandled_input(false)
		game.completed_levels.resize(Defs.LEVELS.size())
		game.completed_levels.fill(true)
		game.current_world_key = "pool"
		game.current_level = Defs.LEVELS[0].duplicate(true)
		game.mode = game.MODE_MAP
		game.ui_time = 2
		for page in ["regular", "touhou", "result"]:
			game.level_difficulty_menu = game.LevelDifficultyMenu.new(game)
			game.touhou_difficulty_menu = game.TouhouDifficultyMenu.new(game)
			if page == "regular":
				game.level_difficulty_menu.open(0)
			elif page == "touhou":
				game.touhou_difficulty_menu.open(game._find_level_index_by_id("3-25"))
			else:
				game._show_message("庭院守住了！\n获得 200 金币", "home", "返回庭院")
				await create_timer(0.35).timeout
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			surface.get_texture().get_image().save_png("%s/%dx%d-%s.png" % [directory, viewport.x, viewport.y, page])
		game.save_dirty = false
		surface.free()
		await process_frame
		await process_frame
	print("Difficulty and result popup: six native desktop / mobile captures")
