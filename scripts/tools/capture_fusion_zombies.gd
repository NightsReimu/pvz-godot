extends "res://scripts/tools/capture_ui_layout.gd"

const Fusion = preload("res://scripts/data/fusion_zombie_defs.gd")
const Gear = preload("res://scripts/runtime/zombie_equipment.gd")
var failures := 0

class Gallery extends GameScript:
	var subjects: Array = []
	var stage := "intact"
	func _ready() -> void:
		_build_font(); set_process(false)
	func _save_game() -> void:
		pass
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#182a29"))
		draw_string(ui_font, Vector2(24,28), "融合僵尸 · " + stage, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#f2dba7"))
		for i in range(subjects.size()):
			var z: Dictionary = subjects[i]
			var tile := Rect2(Vector2(20 + (i % 6) * 260, 44 + (i / 6) * 206), Vector2(250,196))
			draw_rect(tile, Color("#e4ddc3"))
			draw_rect(tile.grow(-5), Color("#597363"), false, 1)
			draw_string(ui_font, tile.position + Vector2(12,23), Defs.ZOMBIES[z.fusion_kind].name, HORIZONTAL_ALIGNMENT_LEFT, 226, 14, Color("#243831"))
			_draw_zombie(tile.position + Vector2(119,124), z)
			var layers: Array = Gear.layers(z)
			for n in range(layers.size()):
				var layer: Dictionary = layers[n]
				_draw_health_bar(tile.position + Vector2(204,42+n*9), 48, float(z[layer.field])/float(z[layer.max_field]), Gear.bar_color(layer.slot))
			_draw_health_bar(tile.position + Vector2(204,42+layers.size()*9), 48, float(z.health)/float(z.max_health), ThemeLib.ZOMBIE_RED)

func _run() -> void:
	var directory := "res://output/fusion-zombies"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.mode = Window.MODE_WINDOWED
	var surface := SubViewport.new()
	surface.size = Vector2i(1600,900)
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	var gallery := Gallery.new()
	gallery.size = Vector2(surface.size)
	surface.add_child(gallery)
	gallery.current_level = {"id":"fusion-preview", "terrain":"day", "events":[]}
	gallery.active_rows = [0,1,2,3,4]; gallery.level_time = 5
	var ids: Array = Fusion.RECIPES.keys()
	for stage in ["intact", "worn", "removed"]:
		gallery.stage = stage
		for page in range(int(ceil(ids.size()/24.0))):
			gallery.subjects.clear()
			for id in ids.slice(page*24, mini((page+1)*24, ids.size())):
				gallery.zombies.clear()
				gallery.current_level.terrain = "pool" if gallery._is_water_zombie_kind(id) else "day"
				gallery.water_rows = [2,3] if gallery._is_water_zombie_kind(id) else []
				gallery._spawn_zombie_at(id, 2, 700)
				var z: Dictionary = gallery.zombies[0].duplicate(true)
				z.flash = 0; z.anim_phase = 0; z.impact_timer = 0; z.portrait = true
				for field in ["headgear_health", "handheld_health"]:
					z[field] *= 0.3 if stage == "worn" else (0 if stage == "removed" else 1)
				gallery.subjects.append(z)
			var before := [gallery.subjects.duplicate(true), gallery.rng.state]
			gallery.queue_redraw()
			await process_frame; await RenderingServer.frame_post_draw
			if before != [gallery.subjects, gallery.rng.state]: failures += 1
			var result := surface.get_texture().get_image().save_png("%s/%s-%02d.png" % [directory,stage,page])
			if result != OK: failures += 1
	surface.free()
	for viewport in [Vector2i(1600,900), Vector2i(844,390)]:
		var battle := SubViewport.new()
		battle.size = viewport; battle.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(battle)
		var game := PreviewGame.new()
		game.size = Vector2(viewport); game.mobile_runtime_override = 1 if viewport.y < 600 else 0
		battle.add_child(game)
		var level: Dictionary = Defs.LEVELS[game._find_level_index_by_id("1-10")].duplicate(true)
		level.events = []
		game._begin_level(-1,["sunflower","repeater","wallnut","fume_shroom","magnet_shroom"],level)
		game.level_time = 15; game.battle_intro_timer = 0
		var sample := ["cone_screen_door","football_screen_door","bucket_ninja_door","football_pole_vault","cone_newspaper","bucket_wizard_zombie","bucket_dancing_door","cone_basketball","bucket_shade_zombie","dark_football_ninja_door"]
		for i in range(sample.size()):
			game._spawn_zombie_at(sample[i],i%5, game._cell_center(i%5,5+i/5*2).x)
			game.zombies.back().spawn_time = 0
			if i == 2: game.zombies.back().headgear_health *= 0.3; game.zombies.back().handheld_health *= 0.3
		for row in range(5):
			game.grid[row][0] = game._create_plant("sunflower",row,0)
			game.grid[row][1] = game._create_plant("fume_shroom",row,1)
			game.grid[row][0].spawn_time = 0; game.grid[row][1].spawn_time = 0
		game.banner_label.hide(); game.toast_label.hide()
		var before := [game.zombies.duplicate(true),game.rng.state]
		game.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		if before != [game.zombies,game.rng.state]: failures += 1
		battle.get_texture().get_image().save_png("%s/battle-%dx%d.png" % [directory,viewport.x,viewport.y])
		game.save_dirty = false; battle.free()
	print("Native fusion gallery and battle capture: %d failure(s)" % failures)
	quit(1 if failures else 0)
