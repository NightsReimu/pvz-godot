extends "res://scripts/tools/capture_touhou_spells.gd"


func _run() -> void:
	await process_frame
	for child in root.get_children():
		if child is GameScript:
			child.save_dirty = false
			child.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for viewport in [Vector2i(1600, 900), Vector2i(2000, 900)]:
		root.mode = Window.MODE_WINDOWED
		root.size = viewport
		root.content_scale_size = viewport
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x == 2000 else 0
		root.add_child(game)
		var level: Dictionary = GameScript.Defs.VolcanoLevelDefs.LEVELS.back().duplicate(true)
		level["mode"] = "normal"
		level.erase("conveyor_plants")
		level["custom_level"] = true
		level["start_sun"] = 850
		game._begin_level(-1, ["thermal_sunflower", "obsidian_artichoke", "steam_clover", "pumice_wall", "fumarole_melon", "magnet_orchid"], level)
		game.rng.seed = 906
		game.level_time = 12.0
		var runtime = game._ensure_volcano_expansion()
		for i in range(runtime.PLANTS.size()):
			var row = i / 2
			var col = 1 + i % 2
			var plant = game._create_plant(runtime.PLANTS[i], row, col)
			plant["spawn_time"] = 0.0
			plant["ultimate_charge"] = 1.0 if i % 2 == 0 else 0.48
			plant["geothermal_charge"] = 2
			game.grid[row][col] = plant
		for i in range(runtime.ZOMBIES.size()):
			var row = i % 5
			game._spawn_zombie_at(runtime.ZOMBIES[i], row, game._cell_center(row, 6 + i / 5).x, true)
			game.zombies.back()["spawn_time"] = 0.0
		game.banner_label.visible = false
		await _capture(game, "volcano-%dx%d-units" % [viewport.x, viewport.y])
		game._spawn_zombie_at("volcano_boss", 2, game._boss_anchor_x("volcano_boss"), true)
		var boss: Dictionary = game.zombies.back()
		boss["spawn_time"] = 0.0
		boss["boss_phase"] = 1
		boss["boss_skill_cycle"] = 0
		game._trigger_boss_skill(boss)
		game._update_effects(0.8)
		game._update_plants(0.15)
		game._update_projectiles(0.15)
		runtime.cool(Vector2i(2, 4), 0, 10)
		game.banner_label.visible = false
		await _capture(game, "volcano-%dx%d-meteors" % [viewport.x, viewport.y])
		game._update_effects(0.9)
		boss["boss_skill_cycle"] = 1
		game._trigger_boss_skill(boss)
		game._update_effects(0.8)
		game.banner_label.visible = false
		await _capture(game, "volcano-%dx%d-vents" % [viewport.x, viewport.y])
		game.save_dirty = false
		game.free()
	quit()
