extends "res://scripts/tools/capture_battle_polish.gd"

const SpriteDefs = preload("res://scripts/data/touhou_sprite_defs.gd")
const KINDS := ["rumia_boss", "daiyousei_boss", "cirno_boss", "meiling_boss", "koakuma_boss", "patchouli_boss", "sakuya_boss", "remilia_boss", "flandre_boss"]
const SPELLS := ["dark", "summon", "blizzard", "dragon", "summon", "flare", "time", "gungnir", "laevatein"]

class Gallery extends PreviewGame:
	var spell_mode := false
	var hit_mode := false
	var beam_mode := false

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("172531"))
		_draw_text("红魔乡 Boss · 新素材 / 统一人物高度", Vector2(32, 38), 26, Color("f4dfc4"))
		for i in range(KINDS.size()):
			var origin := Vector2(i % 3, i / 3) * Vector2(530, 320) + Vector2(8, 58)
			var center := origin + Vector2(260, 225)
			var state: String = SPELLS[i] if spell_mode else "idle"
			if beam_mode and i == 0:
				state = "beam"
			var unit := {"kind": KINDS[i], "rumia_state": state, "boss_state": state, "boss_phase": 0, "health": 100.0, "anim_phase": 0.0, "flash": 0.0, "slow_timer": 0.0, "impact_timer": 0.2 if hit_mode else 0.0}
			_draw_zombie(center, unit)
			_draw_text(String(Defs.ZOMBIES[KINDS[i]].name) + " · " + ("受击" if hit_mode else state), origin + Vector2(100, 298), 20, Color("e5dcc1"))
			_draw_zombie_icon(KINDS[i], origin + Vector2(450, 120), 0.72)

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1040)
	root.content_scale_size = Vector2i(1600, 1040)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var gallery := Gallery.new()
	var surface := SubViewport.new()
	surface.size = Vector2i(1600, 1040)
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	gallery.size = Vector2(surface.size)
	surface.add_child(gallery)
	for kind in KINDS:
		gallery._queue_boss_frame_set_prewarm(kind)
	gallery._drain_asset_prewarm_queue()
	for mode in ["idle", "spells", "hit", "beam"]:
		gallery.spell_mode = mode == "spells"
		gallery.hit_mode = mode == "hit"
		gallery.beam_mode = mode == "beam"
		for tick in range(3):
			gallery.level_time = 0.18 + tick * 0.22
			gallery.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://output/scarlet-refresh/native-%s-%d.png" % [mode, tick]
			print(path, ": ", error_string(surface.get_texture().get_image().save_png(path)))
	surface.free()
	quit()
