extends "res://scripts/tools/capture_battle_polish.gd"

# Run without --headless. Captures the Ancient World under every weather, the new
# units in action and the world journal page, without touching saves.
const ANCIENT_OUTPUT := "res://output/ancient"


func _shot(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	print("Capture %s: %s" % [label, error_string(image.save_png("%s/%s.png" % [ANCIENT_OUTPUT, label]))])


func _stage(viewport: Vector2i, weather: String) -> Control:
	root.size = viewport
	root.content_scale_size = viewport
	var game := PreviewGame.new()
	game.size = Vector2(viewport)
	game.mobile_runtime_override = 1 if viewport.y < 600 else 0
	root.add_child(game)
	var level: Dictionary = GameScript.Defs.AncientLevelDefs.LEVELS[4].duplicate(true)
	level["custom_level"] = true
	level["start_sun"] = 900
	level["weather_schedule"] = [{"weather": weather, "duration": 999.0}]
	game._begin_level(-1, ["dandelion", "jasmine_tea", "golden_milk", "samsara_eye", "electric_bonk_choy", "sunflower"], level)
	game.rng.seed = 808
	game.level_time = 10.0
	game.banner_timer = 0.0
	game.battle_intro_timer = 0.0
	game.banner_label.visible = false
	var runtime = game._ensure_ancient_expansion()
	runtime.weather_blend = 1.0
	var layout := [["sunflower", "dandelion", "jasmine_tea"], ["sunflower", "electric_bonk_choy", "dandelion"], ["sunflower", "jasmine_tea", "electric_bonk_choy"], ["sunflower", "dandelion", "samsara_eye"], ["sunflower", "golden_milk", "jasmine_tea"]]
	for row in range(5):
		for col in range(3):
			var plant: Dictionary = game._create_plant(layout[row][col], row, col)
			plant["spawn_time"] = 0.0
			game.grid[row][col] = plant
	return game


func _run() -> void:
	await process_frame
	for child in root.get_children():
		if child is GameScript:
			child.save_dirty = false
			child.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ANCIENT_OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		for weather in ["clear", "sunny", "rain", "storm", "wind", "fog"]:
			if viewport.x != 1600 and weather != "storm":
				continue
			var game := _stage(viewport, weather)
			var runtime = game._ensure_ancient_expansion()
			game._spawn_zombie_at("ancient_samurai", 0, game._cell_center(0, 4).x + 10.0, true)
			game._spawn_zombie_at("ancient_mage", 1, game._cell_center(1, 6).x, true)
			game._spawn_zombie_at("ancient_strategist", 2, game._cell_center(2, 7).x, true)
			game._spawn_zombie_at("conehead", 3, game._cell_center(3, 5).x, true)
			game._spawn_zombie_at("buckethead", 4, game._cell_center(4, 6).x, true)
			for z in game.zombies:
				z["spawn_time"] = 0.0
			game.zombies[2]["ancient_anim"] = 1.0
			game.zombies[1]["ancient_cast"] = 0.6
			game.zombies[0]["shield_health"] = 400.0
			runtime.corrode([Vector2i(0, 3), Vector2i(0, 4), Vector2i(1, 3), Vector2i(1, 4), Vector2i(2, 4)], 6.0)
			game.zombies[3]["ancient_weak_until"] = game.level_time + 5.0
			runtime.launch_spore(0, game._cell_center(0, 1) + Vector2(0, -42), int(game.zombies[0].uid), 38.0)
			runtime.launch_spore(3, game._cell_center(3, 1) + Vector2(0, -42), int(game.zombies[3].uid), 38.0)
			game.projectiles[0]["spore_phase"] = 0.7
			game.projectiles[1]["spore_phase"] = 1.0
			game.projectiles[1]["spore_dive"] = 0.4
			runtime.spawn_milk_wave(4, game._cell_center(4, 1).x, 1000.0)
			game.effects.back()["front_x"] = game._cell_center(4, 4).x
			game.grid[1][1]["ancient_punch_anim"] = 0.2
			game.grid[1][1]["ancient_punch_side"] = 1
			game.grid[2][2]["ancient_sheep_until"] = game.level_time + 10.0
			game.grid[3][2]["ancient_fuse"] = 0.4
			game.grid[3][2]["ancient_fuse_total"] = 1.0
			runtime.chain_lightning(1, 0.0, 2, game._cell_center(1, 1) + Vector2(18, -34))
			if weather == "storm":
				runtime.strike_zombie(0, 0.0, 0.0, true)
				runtime.resolve_effect(game.effects.back())
			game.effects.append({"shape": "ancient_tea_pour", "position": game._cell_center(0, 2), "radius": 98.0, "time": 0.4, "duration": 0.7, "color": Color.WHITE, "cells": [Vector2i(0, 3), Vector2i(0, 4), Vector2i(1, 3)], "row": 0, "col": 2})
			await _shot(game, "ancient-%s-%dx%d" % [weather, viewport.x, viewport.y])
			game.save_dirty = false
			game.free()
	# World journal page.
	root.size = Vector2i(1600, 900)
	root.content_scale_size = Vector2i(1600, 900)
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
	await _shot(menu, "ancient-world-select")
	menu.save_dirty = false
	menu.free()
	quit()
