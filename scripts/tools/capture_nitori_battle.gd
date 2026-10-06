extends "res://scripts/tools/capture_battle_polish.gd"

const NITORI_OUTPUT := "res://output/nitori-capture"

func _shot(game: Control, name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	if screenshot.get_size() != root.content_scale_size: screenshot.resize(root.content_scale_size.x, root.content_scale_size.y, Image.INTERPOLATE_LANCZOS)
	print("Capture %s: %s" % [name, error_string(screenshot.save_png("%s/%s.png" % [NITORI_OUTPUT, name]))])

func _run() -> void:
	await process_frame
	for child in root.get_children():
		if child is GameScript:
			child.save_dirty = false
			child.free()
	var base: Dictionary = {}
	var level_index := -1
	for i in range(GameScript.Defs.LEVELS.size()):
		if GameScript.Defs.LEVELS[i].id == "4-21":
			base = GameScript.Defs.LEVELS[i].duplicate(true)
			level_index = i
	if base.is_empty():
		push_error("Nitori's stage is required for actual native desktop/mobile captures")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(NITORI_OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var shots := [
		["road", "easy", "nonspell_nitori_camouflage"], ["road", "hard", "nitori_hydro_camouflage"],
		["finale", "normal", "nitori_ooze_flooding"], ["finale", "lunatic", "nitori_great_waterfall"],
		["finale", "hard", "nitori_extend_arm"], ["finale", "lunatic", "nitori_cephalic_plate"],
		["finale", "normal", "nitori_cucumber_bait"], ["finale", "hard", "nitori_water_cannon"],
		["finale", "lunatic", "nitori_workshop"],
	]
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		root.size = viewport
		root.content_scale_size = viewport
		for shot in shots:
			var road: bool = shot[0] == "road"
			var pattern: String = shot[2]
			var game := PreviewGame.new()
			game.size = Vector2(viewport)
			game.mobile_runtime_override = 1 if viewport.y < 600 else 0
			root.add_child(game)
			var level: Dictionary = game.TouhouDifficulty.build_level(base, String(shot[1]))
			level.custom_level = true
			game._begin_level(-1, ["repeater", "melon_pult", "healing_gourd", "plantern", "umbrella_leaf", "wallnut"], level)
			game._drain_asset_prewarm_queue()
			game.rng.seed = 421
			game.level_time = 176.0
			game.ui_time = 8.0
			game.battle_intro_timer = 0.0
			for row in range(6):
				for col in range(6):
					game.grid[row][col] = game._create_plant(["repeater", "healing_gourd", "melon_pult", "plantern" if row % 3 == 1 else "repeater", "umbrella_leaf" if row % 2 == 0 else "repeater", "wallnut"][col], row, col)
					game.grid[row][col].spawn_time = 0.0
			game._spawn_zombie_at("cone_kedama", 0, game._cell_center(0, 7).x, true)
			game._spawn_zombie_at("bucket_umbrella_zombie", 5, game._cell_center(5, 7).x, true)
			game._spawn_zombie_at("kabuto_star_fairy", 3, game._cell_center(3, 6).x, true)
			game._spawn_zombie_at("nitori_boss", 2, game._boss_anchor_x("nitori_boss"), true, road)
			for z in game.zombies: z.spawn_time = 0.0
			var boss: Dictionary = game.zombies.back()
			var encounter: Dictionary = boss.touhou_encounter
			for phase in range(encounter.phases.size()):
				for attack in range(encounter.phases[phase].size()):
					if String(encounter.phases[phase][attack][2]) == pattern:
						encounter.index = phase
						encounter.attack = attack
						encounter.completed = attack
			game.TouhouPhaseRuntime._set_bounds(boss)
			boss.health = encounter.ceiling
			game._trigger_boss_skill(boss)
			for frame in range(150):
				game.level_time += 0.02
				game.ui_time += 0.02
				game._ensure_nitori_runtime().update(0.02)
				game.touhou_danmaku.update(0.02)
				game._update_effects(0.02)
			game.banner_timer = 0.0
			game.banner_label.visible = false
			game.toast_label.visible = false
			await _shot(game, "nitori-%s-%dx%d" % [pattern, viewport.x, viewport.y])
			await _release(game)
		var preview_game := PreviewGame.new()
		preview_game.size = Vector2(viewport)
		preview_game.mobile_runtime_override = 1 if viewport.y < 600 else 0
		root.add_child(preview_game)
		preview_game.current_level = GameScript.TouhouDifficulty.build_level(base, "lunatic")
		preview_game.selected_level_index = level_index
		preview_game.mode = preview_game.MODE_SELECTION
		preview_game.selection_background_preview_open = true
		preview_game._drain_asset_prewarm_queue()
		await _shot(preview_game, "nitori-selection-preview-%dx%d" % [viewport.x, viewport.y])
		await _release(preview_game)
		var map_game := PreviewGame.new()
		map_game.size = Vector2(viewport)
		map_game.mobile_runtime_override = 1 if viewport.y < 600 else 0
		root.add_child(map_game)
		map_game.completed_levels.resize(GameScript.Defs.LEVELS.size())
		map_game.completed_levels.fill(true)
		map_game.unlocked_levels = GameScript.Defs.LEVELS.size()
		map_game.current_world_key = map_game._world_key_for_level(base)
		map_game.selected_level_index = level_index
		map_game._enter_map_mode()
		map_game._set_map_scroll(map_game.current_world_key, map_game._map_scroll_value(map_game.current_world_key, true), true)
		map_game._drain_asset_prewarm_queue()
		await _shot(map_game, "nitori-map-node-%dx%d" % [viewport.x, viewport.y])
		await _release(map_game)
	call_deferred("quit")

func _release(game: Control) -> void:
	game._stop_bgm()
	if game.music_player != null: game.music_player.stream = null
	await create_timer(0.15).timeout
	game.save_dirty = false
	game.free()
	await process_frame
