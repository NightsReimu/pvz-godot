extends SceneTree

# Deterministic visual check for the Torchwood interaction. The output is kept
# under res://output (ignored) so this helper never changes player saves.
const GameScript = preload("res://scripts/game.gd")
const OUTPUT_PATH := "res://output/flame-boomerang/torchwood-ignition.png"


class PreviewGame extends GameScript:
	func _ready() -> void:
		_build_font()
		_build_overlay_ui()
		set_process(false)

	func _update_autosave(_delta: float) -> void:
		pass

	func _save_game() -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size = Vector2i(1600, 900)
	root.content_scale_size = Vector2i(1600, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/flame-boomerang"))
	var game := PreviewGame.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	game._begin_level(-1, ["boomerang_shooter", "torchwood", "wallnut", "sunflower"], {
		"id": "flame-boomerang-preview",
		"title": "",
		"terrain": "night",
		"start_sun": 450,
		"events": [],
		"row_count": 5,
		"custom_level": true,
	})
	game.level_time = 14.0
	game.banner_timer = 0.0
	game.banner_label.visible = false
	var row := 2
	for col in range(4):
		var kind: String = ["boomerang_shooter", "torchwood", "wallnut", "sunflower"][col]
		var plant: Dictionary = game._create_plant(kind, row, col)
		plant["spawn_time"] = 0.0
		game.grid[row][col] = plant
	game._spawn_boomerang_projectile(
		row,
		game._cell_center(row, 0) + Vector2(32.0, -10.0),
		game._cell_center(row, 0).x + 8.0,
		26.0,
		4
	)
	game._spawn_zombie_at("normal", row, game._cell_center(row, 7).x, true)
	game.zombies.back()["spawn_time"] = 0.0
	for _step in range(8):
		game._update_projectiles(0.05)
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	var result := capture.save_png(OUTPUT_PATH)
	print("Capture flame boomerang: %s (%s)" % [error_string(result), capture.get_size()])
	game.free()
	quit()
