extends "res://scripts/tools/capture_ui_layout.gd"

# Run without --headless: home, map, selection and almanac pages for the Ancient World.
func _run() -> void:
	var directory := "res://output/ancient"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.mode = Window.MODE_WINDOWED
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x <= 1000 else 0
		surface.add_child(game)
		game.set_process_unhandled_input(false)
		game.completed_levels.resize(Defs.LEVELS.size())
		game.completed_levels.fill(true)
		game.unlocked_levels = Defs.LEVELS.size()
		game.ui_time = 2.0
		game.current_world_key = "ancient"
		game.world_select_index = 7
		game.world_select_scroll = 7.0
		for kind in Defs.PLANTS:
			if not bool(Defs.PLANTS[kind].get("fusion_only", false)):
				game.plant_stars[kind] = 5
		game.current_level = Defs.LEVELS[game._find_level_index_by_id("8-5")].duplicate(true)
		game.selection_cards = ["dandelion", "jasmine_tea", "golden_milk", "samsara_eye", "electric_bonk_choy", "sunflower"]
		game.selection_pool_cards = game._player_plant_collection()
		for page in ["home", "map", "selection", "almanac", "zombie_almanac", "almanac_mage", "almanac_strategist", "almanac_bonk"]:
			game.mode = page
			game.almanac_tab = "plants"
			game.almanac_selected_kind = "dandelion"
			if page.begins_with("almanac") or page == "zombie_almanac":
				game.mode = game.MODE_ALMANAC
			if page == "zombie_almanac":
				game.almanac_tab = "zombies"; game.almanac_selected_kind = "ancient_samurai"
			if page == "almanac_mage":
				game.almanac_tab = "zombies"; game.almanac_selected_kind = "ancient_mage"
			if page == "almanac_strategist":
				game.almanac_tab = "zombies"; game.almanac_selected_kind = "ancient_strategist"
			if page == "almanac_bonk":
				game.almanac_selected_kind = "electric_bonk_choy"
			game._ensure_almanac_selection()
			game.banner_label.hide()
			game.toast_label.hide()
			game.message_panel.hide()
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var image := surface.get_texture().get_image()
			print("Capture %s: %s" % [page, error_string(image.save_png("%s/ui-%s-%dx%d.png" % [directory, page, viewport.x, viewport.y]))])
		game.save_dirty = false
		surface.free()
	quit()
