extends "res://scripts/tools/capture_ui_layout.gd"

func _run() -> void:
	var directory := "res://output/garden-navigation"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.mode = Window.MODE_WINDOWED
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.y < 600 else 0
		surface.add_child(game)
		game.set_process_unhandled_input(false)
		game.current_level = GameScript.Defs.LEVELS[0].duplicate(true)
		game.completed_levels.resize(GameScript.Defs.LEVELS.size())
		game.completed_levels.fill(true)
		game.unlocked_levels = GameScript.Defs.LEVELS.size()
		game.coins_total = 987654321
		game.ui_time = 2.0
		game.mode = game.MODE_WORLD_SELECT
		for i in range(GameScript.WorldDataLib.all().size()):
			game.world_select_index = i
			game.world_select_scroll = float(i)
			await save_frame(game, surface, "%s/%dx%d-%s.png" % [directory, viewport.x, viewport.y, GameScript.WorldDataLib.all()[i].key])
		game.completed_levels.fill(false)
		game.unlocked_levels = 1
		await save_frame(game, surface, "%s/%dx%d-locked.png" % [directory, viewport.x, viewport.y])
		game.mode = game.MODE_BASE
		for room in ["factory", "training"]:
			game.base_selected_room = room
			await save_frame(game, surface, "%s/%dx%d-base-%s.png" % [directory, viewport.x, viewport.y, room])
		game.save_dirty = false
		surface.free()
	quit()

func save_frame(game: Control, surface: SubViewport, path: String) -> void:
	game.banner_label.hide()
	game.toast_label.hide()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := surface.get_texture().get_image().save_png(path)
	print("%s: %s" % [path, error_string(result)])
