extends SceneTree

# Run with the display renderer. This tool never reads or writes player progress.
const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const UiPreview = preload("res://scripts/tools/capture_ui_layout.gd")

class Gallery extends GameScript:
	var entries: Array = []
	var category := "plants"
	var columns := 8
	var cell := Vector2(160, 160)

	func _ready() -> void:
		_build_font()
		set_process(false)
		set_process_unhandled_input(false)

	func _save_game() -> void:
		pass

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#edf2ee"))
		for i in range(entries.size()):
			var kind: String = entries[i]
			var origin := Vector2(i % columns, i / columns) * cell
			var center := origin + Vector2(cell.x * 0.5, cell.y * 0.53)
			if i % 2 == (i / columns) % 2:
				draw_rect(Rect2(origin, cell), Color("#e2e9e5"))
			if category == "plants":
				_draw_card_icon(kind, center - Vector2(0, 8), 2.1)
			else:
				_draw_zombie_icon(kind, center, 0.8 if category == "bosses" else 1.0)
			var label := String(Defs.PLANTS[kind].name if category == "plants" else Defs.ZOMBIES[kind].name)
			var label_width := ui_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			_draw_text(label, origin + Vector2((cell.x - label_width) * 0.5, cell.y - 14), 15, Color("#213b3a"))


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var label := args[0].validate_filename() if not args.is_empty() else "after"
	var directory := "res://output/unit-identity/%s" % label
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var surface := SubViewport.new()
	surface.size = Vector2i(1280, 960)
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	var game := Gallery.new()
	game.size = Vector2(surface.size)
	surface.add_child(game)
	game.current_level = {"id": "gallery", "terrain": "day", "events": []}
	game.level_time = 5.0
	game.ui_time = 5.0
	for category in ["plants", "zombies", "bosses"]:
		var kinds: Array = []
		for kind in (Defs.PLANTS if category == "plants" else Defs.ZOMBIES):
			var boss := game._boss_frame_count_for_kind(kind) > 0 if category != "plants" else false
			if category == "plants" or boss == (category == "bosses"):
				kinds.append(kind)
		game.category = category
		game.columns = 6 if category == "bosses" else 8
		game.cell = Vector2(1280.0 / game.columns, 240 if category == "bosses" else 160)
		var page_size := game.columns * (4 if category == "bosses" else 6)
		for start in range(0, kinds.size(), page_size):
			game.entries = kinds.slice(start, start + page_size)
			if category == "bosses":
				for kind in game.entries:
					game._queue_boss_frame_set_prewarm(kind)
				game._drain_asset_prewarm_queue()
			# Request a second frame so asynchronous boss textures can become visible.
			for frame in range(3):
				game.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
			var path := "%s/%s-%d.png" % [directory, category, start / page_size + 1]
			var result := surface.get_texture().get_image().save_png(path)
			print("%s: %s" % [path, error_string(result)])
	game.save_dirty = false
	surface.free()
	await _capture_battles(directory)
	quit()


func _capture_battles(directory: String) -> void:
	var plant_rows := [
		["sunflower", "peashooter", "wallnut"],
		["sun_shroom", "threepeater", "tallnut"],
		["thermal_sunflower", "snow_pea", "chomper"],
		["kernel_pult", "cabbage_pult", "potato_mine"],
		["magnet_shroom", "starfruit", "spikeweed"],
		["moon_lotus", "melon_pult", "torchwood"],
	]
	var enemies := ["conehead", "buckethead", "newspaper", "pole_vault", "football", "screen_door"]
	for viewport in [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(1000, 450), Vector2i(844, 390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := UiPreview.PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x <= 1000 else 0
		surface.add_child(game)
		var rows := 6 if viewport.x == 1280 else 5
		game._begin_level(-1, ["sunflower", "peashooter", "snow_pea", "threepeater", "wallnut", "chomper", "kernel_pult", "potato_mine", "starfruit", "thermal_sunflower"], {
			"id": "identity-preview", "title": "", "terrain": "day", "start_sun": 450,
			"events": [{"time": 999.0, "kind": "normal", "row": 2}], "row_count": rows, "custom_level": true,
		})
		game.rng.seed = 906
		game.level_time = 12.0
		game.banner_label.hide()
		game.toast_label.hide()
		for row in range(rows):
			for col in range(3):
				game.grid[row][col] = game._create_plant(plant_rows[row][col], row, col)
				game.grid[row][col]["spawn_time"] = 0.0
			game._spawn_zombie_at(enemies[row], row, game._cell_center(row, 5).x, true)
			game.zombies.back()["spawn_time"] = 0.0
		game.grid[0][2]["health"] = game.grid[0][2]["max_health"] * 0.3
		game.grid[1][1]["shell_kind"] = "pumpkin"
		game.grid[1][1]["armor_health"] = 300.0
		game.grid[1][1]["max_armor_health"] = 600.0
		for kind in ["youmu_boss", "cirno_boss"]:
			game._queue_boss_frame_set_prewarm(kind)
		game._drain_asset_prewarm_queue()
		game._spawn_zombie_at("youmu_boss", 2, game._boss_anchor_x("youmu_boss"), true)
		game.zombies.back()["spawn_time"] = 0.0
		await _save_view(surface, game, "%s/%dx%d-battle.png" % [directory, viewport.x, viewport.y])
		game.grid[2][2]["chew_timer"] = 6.0
		game.grid[3][2]["armed"] = true
		game.grid[3][2]["arm_timer"] = 0.0
		game.grid[2][1]["action_timer"] = 0.09
		game.grid[2][1]["action_duration"] = 0.18
		game.zombies[0]["shield_health"] = 0.0
		game.zombies[2]["shield_health"] = 0.0
		game.level_time += 0.2
		await _save_view(surface, game, "%s/%dx%d-states.png" % [directory, viewport.x, viewport.y])
		if viewport.x == 1280:
			game.mode = game.MODE_ALMANAC
			game.almanac_tab = "zombies"
			game.almanac_selected_kind = "cirno_boss"
			await _save_view(surface, game, "%s/boss-almanac.png" % directory)
		game.save_dirty = false
		surface.free()


func _save_view(surface: SubViewport, game: Control, path: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := surface.get_texture().get_image()
	var result := capture.save_png(path)
	print("%s: %s" % [path, error_string(result)])
