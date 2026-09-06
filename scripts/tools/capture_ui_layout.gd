extends SceneTree

# Run without --headless. Preview state is isolated from the player's save.
const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")

class PreviewGame extends GameScript:
	func _ready() -> void:
		_build_font()
		_build_overlay_ui()
		_init_base_defaults()
		set_process(false)

	func _save_game() -> void:
		pass

	func _apply_display_mode() -> void:
		pass

	func _viewport_safe_rect() -> Rect2:
		return Rect2(Vector2.ZERO, size)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_refresh_battle_layout()


func _initialize() -> void:
	ProjectSettings.set_setting("application/run/main_scene", "")
	call_deferred("_run")


func _run() -> void:
	var label := "after"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		label = args[0].validate_filename()
	var directory := "res://output/ui-layout/%s" % label
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.mode = Window.MODE_WINDOWED
	for viewport in [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(1000, 450), Vector2i(844, 390), Vector2i(390, 844)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x <= 1000 else 0
		surface.add_child(game)
		game.set_process_unhandled_input(false)
		game.current_level = Defs.LEVELS[game._find_level_index_by_id("7-20")].duplicate(true)
		game.completed_levels.resize(Defs.LEVELS.size())
		game.completed_levels.fill(true)
		game.coins_total = 987654321
		game.base_drones = 1234567
		game.enhance_stones = 999999
		game.ui_time = 2.0
		game.current_world_key = "volcano"
		game.world_select_index = 6
		game.world_select_scroll = 6.0
		for kind in Defs.PLANTS:
			game.plant_stars[kind] = 5
		game.selection_cards = Defs.PLANTS.keys().slice(0, 10)
		game.selection_pool_cards = Defs.PLANTS.keys()
		game.almanac_selected_kind = "thermal_sunflower"
		game.enhance_selected_plant = "caldera_lotus"
		game.banner_label.hide()
		game.toast_label.hide()
		game.message_panel.hide()
		for page in ["home", "world_select", "map", "selection", "selection_scrolled", "selection_preview", "almanac", "almanac_scrolled", "zombie_almanac", "gacha", "gacha_results", "enhance", "base", "daily", "battle", "pause", "endless_bonus", "loading"]:
			game.mode = page
			if page == "zombie_almanac":
				game.mode = game.MODE_ALMANAC
			elif page.begins_with("selection_") or page == "gacha_results" or page == "almanac_scrolled":
				game.mode = page.get_slice("_", 0)
			game.almanac_tab = "zombies" if page == "zombie_almanac" else "plants"
			game.almanac_selected_kind = "yukari_boss" if page == "zombie_almanac" else "thermal_sunflower"
			game.almanac_scroll = 136.0 if page == "almanac_scrolled" else 0.0
			if page == "almanac_scrolled":
				game.almanac_selected_kind = "solar_emperor"
			game.selection_pool_scroll = 283.0 if page == "selection_scrolled" else 0.0
			if page.begins_with("selection"):
				game.current_level = Defs.LEVELS[game._find_level_index_by_id("7-19")].duplicate(true)
			game.selection_background_preview_open = page == "selection_preview"
			game.gacha_draw_results = []
			if page == "gacha_results":
				for i in range(10):
					game.gacha_draw_results.append({"type": "plant", "kind": "thermal_sunflower", "rarity": "rare", "is_new": i % 2 == 0})
				game.gacha_reveal_index = 10
			if page == "battle":
				game._begin_level(-1, ["sunflower", "peashooter", "snow_pea", "repeater", "wallnut", "cherry_bomb"], {
					"id": "7-19", "title": "火山防线", "terrain": "volcano", "start_sun": 999999,
					"events": [{"time": 999.0, "kind": "normal", "row": 2}], "row_count": 5, "custom_level": true,
				})
				game.level_time = 12.0
				for row in range(5):
					game.grid[row][2] = game._create_plant("peashooter", row, 2)
					game.grid[row][2]["spawn_time"] = 0.0
					game._spawn_zombie_at("conehead", row, game._cell_center(row, 6).x, true)
					game.zombies.back()["spawn_time"] = 0.0
			if page == "pause":
				game.mode = game.MODE_BATTLE
				game.battle_paused = true
			if page == "endless_bonus":
				game.mode = game.MODE_BATTLE
				game.battle_paused = false
				game.endless_bonus_pending = true
				game.endless_bonus_choices = game.ENDLESS_BONUS_DEFS.keys().slice(0, 3)
			game.startup_loading_active = page == "loading"
			game.banner_label.hide()
			game.toast_label.hide()
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var capture := surface.get_texture().get_image()
			if capture.get_size() != viewport:
				push_error("Capture viewport changed unexpectedly: %s" % capture.get_size())
				quit(1)
				return
			var path := "%s/%dx%d-%s.png" % [directory, viewport.x, viewport.y, page]
			var result := capture.save_png(path)
			print("%s: %s, actual %s" % [path, error_string(result), capture.get_size()])
		game.save_dirty = false
		surface.free()
	quit()
