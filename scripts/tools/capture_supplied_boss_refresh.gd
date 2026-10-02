extends "res://scripts/tools/capture_battle_polish.gd"

const KINDS := ["wriggle_boss", "mystia_boss", "keine_boss", "rumia_boss", "daiyousei_boss", "cirno_boss", "meiling_boss", "koakuma_boss", "patchouli_boss", "sakuya_boss", "remilia_boss", "flandre_boss", "mokou_boss", "hakutaku_boss", "reimu_boss"]
const SPELLS := ["storm", "enraged", "emperor", "dark", "summon", "blizzard", "dragon", "summon", "flare", "time", "gungnir", "laevatein", "final", "special", "idle"]

class Gallery extends PreviewGame:
	var pose_mode := "idle"

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("172531"))
		_draw_text("东方 Boss · 新素材与上一批对照 / 统一人物高度", Vector2(32, 38), 26, Color("f4dfc4"))
		for i in range(KINDS.size()):
			var origin := Vector2(i % 3, i / 3) * Vector2(530, 320) + Vector2(8, 58)
			var center := origin + Vector2(260, 225)
			var state: String = SPELLS[i] if pose_mode == "spells" else ("shift" if pose_mode == "shift" else "idle")
			var unit := {"kind": KINDS[i], "rumia_state": state, "boss_state": state, "boss_phase": 0, "health": 100.0, "anim_phase": 0.0, "flash": 0.0, "slow_timer": 0.0, "impact_timer": 0.2 if pose_mode == "hit" else 0.0}
			if pose_mode == "hit" and KINDS[i] == "mokou_boss":
				unit.flash = 0.18
			_draw_zombie(center, unit)
			_draw_text(String(Defs.ZOMBIES[KINDS[i]].name) + " · " + ("受击" if pose_mode == "hit" else state), origin + Vector2(100, 298), 20, Color("e5dcc1"))
			_draw_zombie_icon(KINDS[i], origin + Vector2(450, 120), 0.72)


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1680)
	root.content_scale_size = Vector2i(1600, 1680)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var gallery := Gallery.new()
	var surface := SubViewport.new()
	surface.size = Vector2i(1600, 1680)
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	gallery.size = Vector2(surface.size)
	surface.add_child(gallery)
	for kind in KINDS:
		gallery._queue_boss_frame_set_prewarm(kind)
	gallery._drain_asset_prewarm_queue()
	for mode in ["idle", "spells", "hit", "shift"]:
		gallery.pose_mode = mode
		for tick in range(3):
			gallery.level_time = 0.18 + tick * 0.22
			gallery.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://output/imperishable-refresh/native-%s-%d.png" % [mode, tick]
			print(path, ": ", error_string(surface.get_texture().get_image().save_png(path)))
	surface.free()
	quit()
