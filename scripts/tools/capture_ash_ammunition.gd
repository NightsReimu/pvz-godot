extends "res://scripts/tools/capture_battle_polish.gd"

func _run() -> void:
	for viewport in [Vector2i(1600,900),Vector2i(2000,900)]:
		root.mode = Window.MODE_WINDOWED
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.size = viewport; root.content_scale_size = viewport
		var game := PreviewGame.new(); game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x == 2000 else 0
		root.add_child(game)
		game.rng.seed = 905
		game._begin_level(-1,["peashooter","cherry_bomb","jalapeno","doom_shroom","wallnut","snow_pea"],{"id":"ash-preview","title":"灰烬弹头试验庭院","terrain":"ancient","world":"ancient","events":[{"time":999.0,"kind":"normal"}],"row_count":5,"custom_level":true,"start_sun":500})
		game.battle_intro_timer = 0; game.level_time = 10; game.banner_timer = 0
		game.banner_label.visible = false
		var fusion = game._ensure_plant_fusion()
		for row in range(1,4):
			var source: String = ["cherry_bomb","jalapeno","doom_shroom"][row-1]
			game.grid[row][2] = game._create_plant(fusion.Fusion.result(source,"peashooter"),row,2)
			game.grid[row][0] = game._create_plant("sunflower",row,0)
			game.grid[row][3] = game._create_plant("wallnut",row,3)
			game._spawn_zombie_at("conehead",row,game._cell_center(row,5).x,true)
			game._spawn_zombie_at("normal",row,game._cell_center(row,5).x+30,true)
			game.zombies.back().health = 10000
		for row in range(1,4):
			for col in [0,2,3]: game.grid[row][col].spawn_time = 0.0
		for z in game.zombies: z.spawn_time = 0.0
		game._drain_asset_prewarm_queue()
		await create_timer(0.4).timeout
		game._update_plants(1)
		for frame in range(18): game._update_projectiles(0.02)
		await _save(game,"%d-ammunition" % viewport.x)
		for frame in range(45): game._update_projectiles(0.02)
		await _save(game,"%d-impact" % viewport.x)
		game.save_dirty = false; game._stop_bgm(); game.music_player.stream = null
		game.free()
	await create_timer(0.15).timeout
	quit()

func _save(game: Control,label: String) -> void:
	game.queue_redraw()
	await process_frame; await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://output/v170/%s.png" % label)
