extends "res://scripts/tools/capture_ancient_world.gd"


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ANCIENT_OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for viewport in [Vector2i(1600, 900), Vector2i(1365, 768), Vector2i(844, 390)]:
		for weather in ["clear", "rain", "snow"]:
			if viewport.x == 1365 and weather != "clear": continue
			var game := _stage(viewport, weather)
			game._spawn_zombie_at("ancient_samurai", 1, game._cell_center(1, 5).x, true)
			game._spawn_zombie_at("ancient_mage", 3, game._cell_center(3, 7).x, true)
			for zombie in game.zombies: zombie.spawn_time = 0.0
			await _shot(game, "ancient-city-%s-%dx%d" % [weather, viewport.x, viewport.y])
			game.save_dirty = false
			game.free()
	root.size = Vector2i(1600, 900)
	root.content_scale_size = root.size
	var menu := PreviewGame.new()
	menu.size = Vector2(1600, 900)
	root.add_child(menu)
	menu.completed_levels.resize(GameScript.Defs.LEVELS.size())
	menu.completed_levels.fill(true)
	menu.unlocked_levels = GameScript.Defs.LEVELS.size()
	menu.mode = menu.MODE_WORLD_SELECT
	menu.world_select_index = GameScript.WorldDataLib.index_of("ancient")
	menu.world_select_scroll = float(menu.world_select_index)
	menu.current_world_key = "ancient"
	await _shot(menu, "ancient-city-world-select")
	menu.current_level = GameScript.Defs.AncientLevelDefs.LEVELS[4].duplicate(true)
	menu.selection_cards = ["dandelion", "jasmine_tea", "golden_milk", "samsara_eye", "electric_bonk_choy", "sunflower"]
	menu.selection_pool_cards = menu._player_plant_collection()
	menu.mode = "selection"
	await _shot(menu, "ancient-city-selection")
	menu.selection_background_preview_open = true
	await _shot(menu, "ancient-city-selection-preview")
	menu.save_dirty = false
	menu.free()
	quit()
