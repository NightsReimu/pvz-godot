extends "res://scripts/tools/capture_ui_layout.gd"
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
var failures := 0
class Gallery extends GameScript:
	var subjects: Array = []
	func _ready():
		_build_font(); set_process(false)
	func _save_game(): pass
	func _draw():
		draw_rect(Rect2(Vector2.ZERO,size),Color("263d32"))
		draw_string(ui_font,Vector2(24,30),"融合花园 · 多阶进化",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("f5df9f"))
		for i in range(subjects.size()):
			var id: String = subjects[i]
			var d: Dictionary = Defs.PLANTS[id]
			var tile := Rect2(Vector2(20+(i%6)*260,44+(i/6)*206),Vector2(250,196))
			draw_rect(tile,Color("e7e0c4"))
			draw_string(ui_font,tile.position+Vector2(10,22),d.name,HORIZONTAL_ALIGNMENT_LEFT,230,15,Color("324b39"))
			_draw_plant_body(id,tile.position+Vector2(124,112),1.0,0)
			draw_string(ui_font,tile.position+Vector2(10,182),d.ultimate_name,HORIZONTAL_ALIGNMENT_LEFT,230,13,Color("526d4d"))
func _run():
	var directory := "res://output/plant-fusions"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var surface := SubViewport.new()
	surface.size = Vector2i(1600,900); surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	var gallery := Gallery.new(); gallery.size = Vector2(surface.size)
	surface.add_child(gallery); gallery.level_time = 6
	var ids: Array = Fusion.DEFINITIONS.keys()
	for page in range(int(ceil(ids.size()/24.0))):
		gallery.subjects = ids.slice(page*24,mini((page+1)*24,ids.size()))
		var before: int = gallery.rng.state
		gallery.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		if before != gallery.rng.state: failures += 1
		if surface.get_texture().get_image().save_png("%s/gallery-%02d.png" % [directory,page]) != OK: failures += 1
	surface.free()
	for viewport in [Vector2i(1600,900),Vector2i(844,390)]:
		var battle := SubViewport.new(); battle.size = viewport
		battle.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(battle)
		var game := PreviewGame.new(); game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.y < 600 else 0
		battle.add_child(game)
		var level: Dictionary = Defs.LEVELS[game._find_level_index_by_id("1-8")].duplicate(true)
		level.events = []
		game._begin_level(-1,["sunflower","peashooter","repeater","snow_pea","torchwood","boomerang_shooter","wallnut","melon_pult"],level)
		if not game._ensure_plant_fusion().enabled(): failures += 1
		game.level_time = 12; game.battle_intro_timer = 0; game.sun_points = 900
		var samples := [["twin_sunflower","gatling_pea","pea_bastion"],["triple_sunflower","steam_pea","winter_melon"],["solar_crown","eclipse_blade","prism_laser"],["sun_pea","gum_corn","life_bastion"],["hourglass_bloom","scrap_pult","phoenix_dragon"]]
		for row in range(5):
			for col in range(3):
				game.grid[row][col] = game._create_plant(samples[row][col],row,col)
				game.grid[row][col].sleep_timer = 0; game.grid[row][col].spawn_time = 0; game.grid[row][col].ultimate_charge = 1
			game._spawn_zombie_at("cone_screen_door",row,game._cell_center(row,7).x)
			game.zombies.back().spawn_time = 0
		game.banner_label.hide(); game.toast_label.hide(); game.selected_tool = "peashooter"
		game.hover_preview_cell = Vector2i(0,0); game.hover_preview_initialized = true
		for stage in ["garden","ultimate","tool","prepared","almanac"]:
			if stage == "ultimate":
				game.selected_tool = ""
				game._try_activate_ultimate(2,2); game._try_activate_ultimate(2,1)
				game._update_projectiles(0.15)
			elif stage == "tool":
				game.effects.clear(); game.selected_tool = "fusion"
				game._ensure_plant_fusion().source_cell = Vector2i(0,0)
				game.hover_preview_cell = Vector2i(1,0)
			elif stage == "prepared":
				game.selected_tool = "fusion"; game._ensure_plant_fusion().reset()
				game.active_cards = ["cherry_bomb","coffee_bean","sunflower","peashooter"]
				game._try_select_tool("cherry_bomb"); game._try_select_tool("cherry_bomb")
				if game._ensure_plant_fusion().prepared_result != "fusion_cherry_bomb": failures += 1
				game.hover_preview_cell = Vector2i(2,4)
			elif stage == "almanac":
				game.mode = game.MODE_ALMANAC; game.almanac_tab = "plants"
				game.almanac_selected_kind = "eclipse_blade"; game.almanac_scroll = 0
				for id in Defs.PLANT_ORDER: game.plant_stars[id] = 1
			var before := [game.grid.duplicate(true),game.zombies.duplicate(true),game.rng.state]
			game.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
			if before != [game.grid,game.zombies,game.rng.state]: failures += 1
			if battle.get_texture().get_image().save_png("%s/%s-%dx%d.png" % [directory,stage,viewport.x,viewport.y]) != OK: failures += 1
		game.save_dirty = false; battle.free()
	print("Native fusion plant art/battle capture: %d failure(s)" % failures)
	quit(1 if failures else 0)
