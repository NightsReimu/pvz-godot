extends "res://scripts/tools/capture_ui_layout.gd"
const Ammo = preload("res://scripts/data/plant_ammo.gd")
class AmmoGallery extends GameScript:
	var labels: Array = []
	func _ready():
		_build_font(); set_process(false)
	func _save_game(): pass
	func _draw():
		draw_rect(Rect2(Vector2.ZERO,size),Color("182b32"))
		draw_string(ui_font,Vector2(26,34),"融合弹药 · 保留弹体，叠加元素",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("f9e5b0"))
		for item in labels:
			draw_style_box(_ammo_panel(),item.rect)
			draw_string(ui_font,item.rect.position+Vector2(12,29),item.name,HORIZONTAL_ALIGNMENT_LEFT,168,16,Color("f5dfaa"))
			draw_string(ui_font,item.rect.position+Vector2(12,172),item.variant,HORIZONTAL_ALIGNMENT_LEFT,168,14,Color("a0d4d2"))
		_draw_projectiles()
	func _ammo_panel() -> StyleBoxFlat:
		var panel = StyleBoxFlat.new(); panel.bg_color = Color("253b40"); panel.border_color = Color("43605a")
		panel.set_border_width_all(1); panel.set_corner_radius_all(12)
		return panel
func _run():
	var surface := SubViewport.new(); surface.size = Vector2i(1600,900)
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(surface)
	var game := AmmoGallery.new(); game.size = Vector2(surface.size); surface.add_child(game)
	game.current_level = {"terrain":"day"}; game.active_rows = [0,1,2,3,4]
	for row in range(game.ROWS):
		var cells: Array = []; cells.resize(game.COLS)
		game.grid.append(cells); game.support_grid.append(cells.duplicate())
	var kinds = ["kernel","butter","cabbage","boomerang","sakura_petal","moonforge_shot","lotus_orbit_shot","prism_pea"]
	var names = ["玉米粒","黄油","卷心菜","回旋镖","樱花瓣","月炉流星","莲矛环弹","棱晶弹"]
	var variants = ["","flame","frost+storm","venom+dream+root"]
	var titles = ["原型弹药","烈焰 · 灼烧","寒霜 · 雷电","毒蚀 · 梦蝶 · 缠根"]
	for row in range(4):
		for col in range(8):
			var rect := Rect2(Vector2(16+col*198,62+row*204),Vector2(188,192))
			var at: Vector2 = rect.get_center()+Vector2(6,0)
			game.labels.append({"rect":rect,"name":names[col],"variant":titles[row]})
			var first: int = game.projectiles.size()
			game._spawn_magic_flower_projectile(2,game._cell_center(2,2),1.0,(variants[row]+":" if row > 0 else "")+kinds[col])
			for shot in game.projectiles.slice(first): shot.position = at; shot.radius = 19.0
	var directory = "res://output/plant-fusions-v162"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	for frame in range(3):
		game.level_time = 4.0+frame*0.12
		var before := [game.projectiles.duplicate(true),game.rng.state]
		game.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		assert(before == [game.projectiles,game.rng.state],"Rendering must not alter combat")
		surface.get_texture().get_image().save_png(directory+"/ammo-%d.png" % frame)
	surface.free(); print("Native ammunition capture: 32 payloads, 3 animation frames"); quit()
