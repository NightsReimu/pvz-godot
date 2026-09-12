extends "res://scripts/tools/capture_battle_polish.gd"

class Gallery extends PreviewGame:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("121f27"))
		_draw_text("东方 Boss · 统一人物高度 / 原始动作比例", Vector2(30, 34), 24, Color("e5dcc1"))
		var index := 0
		for kind in TouhouDifficulty.EXTENSIONS:
			var x := 135.0 + (index % 6) * 265.0
			var y := 242.0 + (index / 6) * 255.0
			var unit := {"kind": kind, "boss_phase": 0, "health": 100.0, "rumia_state": "idle", "animation_time": 0.0, "flash": 0.0, "anim_phase": 0.0, "slow_timer": 0.0}
			_draw_zombie(Vector2(x, y), unit)
			_draw_text(String(Defs.ZOMBIES[kind].name), Vector2(x - 85, y + 53), 18, Color("d5e5dd"))
			index += 1

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1100)
	root.content_scale_size = Vector2i(1600, 1100)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var game := Gallery.new()
	game.size = Vector2(1600, 1100)
	root.add_child(game)
	game.level_time = 0.0
	game._queue_almanac_boss_asset_prewarm("zombies")
	game._drain_asset_prewarm_queue()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://output/marisa/touhou-sizes.png"
	print("Touhou size gallery: ", error_string(root.get_texture().get_image().save_png(path)))
	game.free()
	quit()
