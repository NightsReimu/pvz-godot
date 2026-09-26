extends SceneTree

# Display-renderer preview; never load or save player progress.
const Game = preload("res://scripts/game.gd")
const Preview = preload("res://scripts/tools/capture_ui_layout.gd")

class BattlePreview extends Preview.PreviewGame:
	func _pointer_local_position() -> Vector2:
		return Vector2(-200, -200)


class DetailSheet extends Game:
	func _ready() -> void:
		_build_font()
		set_process(false)
		set_process_unhandled_input(false)

	func _save_game() -> void:
		pass

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#edf2ee"))
		_draw_text("植物轮廓 · 护甲破损 · 元素命中", Vector2(40, 44), 26, Color("#283d37"))
		var plants := ["puff_shroom", "sun_shroom", "fume_shroom", "torchwood"]
		for i in range(plants.size()):
			var c := Vector2(100 + i * 180, 150)
			_draw_plant_body(plants[i], c, 1.4)
			_draw_text(Defs.PLANTS[plants[i]].name, c + Vector2(-35, 82), 17, Color("#283d37"))
		_draw_plant_body("sun_shroom", Vector2(840, 150), 1.4, 0, 1, {"mature": false})
		_draw_text("幼年阳光菇", Vector2(795, 232), 17, Color("#283d37"))
		for row in range(3):
			var kind: String = ["conehead", "buckethead", "newspaper"][row]
			for col in range(3):
				var c := Vector2(120 + col * 155, 332 + row * 128)
				_draw_zombie(c, {"kind": kind, "flash": 0.0, "slow_timer": 0.0, "shield_health": [100, 35, 0][col], "max_shield_health": 100, "portrait": true})
				_draw_text(["完好", "破损", "脱落"][col], c+Vector2(-16, 63), 14, Color("#576c60"))
		for i in range(4):
			var style: String = ["leaf", "ice", "fire", "armor"][i]
			var c := Vector2(620 + i % 2 * 200, 355 + i / 2 * 168)
			for frame in range(3):
				CombatDetails.impact(self, c+Vector2(frame*42,0), 26, 0.9-frame*0.3, Color("#76b64d"), style)
			_draw_text(["豌豆命中", "冰晶命中", "火焰命中", "护甲火花"][i], c+Vector2(0, 52), 17, Color("#283d37"))


func _initialize() -> void:
	call_deferred("_run")


func save_view(surface: SubViewport, game: Control, path: String) -> void:
	game.queue_redraw()
	if is_instance_valid(game.glow_layer):
		game.glow_layer.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := surface.get_texture().get_image().save_png(path)
	print("%s: %s" % [path, error_string(error)])


func _run() -> void:
	var directory := "res://output/combat-details/v123"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var sheet := SubViewport.new()
	sheet.size = Vector2i(1024, 720)
	sheet.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sheet)
	var gallery := DetailSheet.new()
	gallery.size = Vector2(sheet.size)
	sheet.add_child(gallery)
	gallery.level_time = 3.4
	await save_view(sheet, gallery, directory+"/details.png")
	sheet.free()
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := BattlePreview.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x < 1000 else 0
		surface.add_child(game)
		var cards := ["sun_shroom", "puff_shroom", "fume_shroom", "torchwood", "boomerang_shooter", "snow_pea", "wallnut", "cherry_bomb", "potato_mine", "peashooter"]
		game._begin_level(-1, cards, {"id":"detail-preview", "title":"夜间花园", "description":"选择植物，守住夜间花园。", "terrain":"night", "start_sun":200, "row_count":5, "custom_level":true, "events":[{"time":999,"kind":"normal","row":2}]})
		game.rng.seed = 906
		game.level_time = 12
		game.selected_tool = "torchwood"
		for i in range(cards.size()):
			game.plant_stars[cards[i]] = 5
			game.plant_enhance_levels[cards[i]] = 6
			game.card_cooldowns[cards[i]] = game._endless_cooldown_for_kind(cards[i]) * (0.65 if i%3==0 else 0)
		for row in range(5):
			for col in range(3):
				var kind: String = ["sun_shroom", "fume_shroom", "torchwood"][col]
				game.grid[row][col] = game._create_plant(kind, row, col)
				game.grid[row][col]["spawn_time"] = 0.0
				game.grid[row][col]["mature"] = row%2==0
			var kind: String = ["conehead", "buckethead", "newspaper"][row%3]
			game._spawn_zombie_at(kind, row, game._cell_center(row, 5).x, true)
			game.zombies.back()["spawn_time"] = 0.0
			game.zombies.back()["shield_health"] *= 0.35
			var hit := {"kind":"pea", "damage":20, "fire":row%3==0, "slow_duration":2 if row%3==1 else 0}
			game._emit_projectile_impact_feedback(game._cell_center(row, 5),hit,game.zombies.back())
		game.banner_label.hide()
		game.toast_label.hide()
		await save_view(surface, game, "%s/%dx%d-cooldown.png" % [directory,viewport.x,viewport.y])
		game.selected_tool = ""
		game.mode = game.MODE_SELECTION
		game.selection_cards = cards
		game.selection_pool_cards = cards
		await save_view(surface, game, "%s/%dx%d-selection.png" % [directory,viewport.x,viewport.y])
		game.save_dirty = false
		surface.free()
	quit()
