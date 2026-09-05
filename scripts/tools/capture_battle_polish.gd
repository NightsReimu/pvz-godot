extends SceneTree

# Run without --headless; captures deterministic battle states without touching saves.
const GameScript = preload("res://scripts/game.gd")
const OUTPUT_DIR := "res://output/battle-polish"

class PreviewGame extends GameScript:
	func _ready() -> void:
		_build_font()
		_build_overlay_ui()
		set_process(false)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_refresh_battle_layout()

	func _update_autosave(_delta: float) -> void:
		pass

	func _save_game() -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for viewport in [Vector2i(1600, 900), Vector2i(1365, 768), Vector2i(2000, 900)]:
		root.size = viewport
		root.content_scale_size = viewport
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x == 2000 else 0
		root.add_child(game)
		game.rng.seed = 905
		var row_count := 6 if viewport.x == 1365 else 5
		game._begin_level(-1, ["sunflower", "peashooter", "snow_pea", "repeater", "wallnut", "cherry_bomb"], {
			"id": "2-31", "title": "", "terrain": "hakugyokurou_border", "start_sun": 450,
			"events": [{"time": 999.0, "kind": "normal", "row": 2}], "row_count": row_count, "custom_level": true,
		})
		game.level_time = 12.0
		game.banner_timer = 0.0
		game.banner_label.visible = false
		game._queue_boss_frame_set_prewarm("yukari_boss")
		game._drain_asset_prewarm_queue()
		for row in range(row_count):
			for col in range(4):
				var kind: String = ["sunflower", "peashooter", "repeater", "wallnut"][col]
				var plant: Dictionary = game._create_plant(kind, row, col)
				plant["ultimate_charge"] = 1.0 if col == 2 else 0.4
				plant["spawn_time"] = 0.0
				game.grid[row][col] = plant
			game._spawn_zombie_at("conehead" if row % 2 == 0 else "buckethead", row, game._cell_center(row, 6).x, true)
			game.zombies.back()["spawn_time"] = 0.0
		game._spawn_zombie_at("yukari_boss", 2, game._boss_anchor_x("yukari_boss"), true)
		var boss: Dictionary = game.zombies.back()
		boss["spawn_time"] = 0.0
		boss["health"] = float(boss["max_health"]) * 0.62
		boss["boss_hud_trail"] = 0.79
		boss["boss_phase"] = 1
		boss["boss_cast_pending"] = true
		boss["boss_skill_timer"] = 0.32
		boss["boss_skill_cycle"] = 3
		boss["boss_pause_timer"] = 0.0
		boss["rumia_state"] = "idle"
		boss["rumia_state_timer"] = 0.0
		boss["rumia_reinforcement_timer"] = 100.0
		game.zombies[game.zombies.size() - 1] = boss
		game._try_activate_ultimate(2, 2)
		game._update_projectiles(0.1)
		await _capture(game, "%dx%d-windup" % [viewport.x, viewport.y])
		game._update_zombies(0.4)
		game.level_time += 0.4
		await _capture(game, "%dx%d-release" % [viewport.x, viewport.y])
		game.save_dirty = false
		game.free()
	quit()


func _capture(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, label]
	var result := capture.save_png(path)
	print("Capture %s: %s (%s)" % [label, error_string(result), capture.get_size()])
