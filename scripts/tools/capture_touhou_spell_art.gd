extends "res://scripts/tools/capture_ui_layout.gd"

const Art = preload("res://scripts/ui/touhou_spell_art.gd")
var failures := 0

func _run() -> void:
	var directory := "res://output/touhou-spell-art/v156-native"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.mode = Window.MODE_WINDOWED
	for viewport in [Vector2i(1600, 900), Vector2i(844, 390)]:
		var specs: Array = []
		for kind in Art.KIND_ART:
			specs.append([kind, 0])
		for cycle in [1, 2, 3, 5]:
			specs.append(["prismriver_boss", cycle])
		for spec in specs:
			var kind: String = spec[0]
			var capture_name := "%s-card%d" % [kind, int(spec[1])]
			var surface := SubViewport.new()
			surface.size = viewport
			surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(surface)
			var game := PreviewGame.new()
			game.size = Vector2(viewport)
			game.mobile_runtime_override = 1 if viewport.y < 600 else 0
			surface.add_child(game)
			game.set_process_unhandled_input(false)
			var id := "3-22-a"
			for configured in GameScript.Defs.LEVELS:
				if configured.get("events", []).any(func(event): return String(event.get("kind", "")) == kind) or String(configured.get("mid_boss_kind", "")) == kind:
					id = String(configured.id)
					break
			var level: Dictionary = GameScript.Defs.LEVELS[game._find_level_index_by_id(id)].duplicate(true)
			level.events = [{"time": 99999.0, "kind": kind, "row": 2}]
			level.erase("mid_boss_kind")
			level.touhou_difficulty = "extra" if kind == "mokou_boss" else "normal"
			game._begin_level(-1, ["sunflower", "repeater", "snow_pea", "wallnut", "cherry_bomb"], level)
			game.rng.seed = 906
			game.level_time = 12.0
			game.battle_intro_timer = 0.0
			game._queue_boss_frame_set_prewarm(kind)
			game._drain_asset_prewarm_queue()
			for row in game.active_rows:
				for col in range(4):
					game.grid[row][col] = game._create_plant(["sunflower", "repeater", "snow_pea", "wallnut"][col], row, col)
					game.grid[row][col].spawn_time = 0.0
			game._spawn_zombie_at(kind, 2, game._boss_anchor_x(kind), true)
			var boss: Dictionary = game.zombies.back()
			boss.spawn_time = 0.0
			boss.erase("touhou_encounter")
			boss.boss_skill_cycle = int(spec[1])
			boss.hover_shift_timer = 100.0
			boss.boss_cast_pending = true
			boss.boss_skill_timer = game.ZombieRuntime.BOSS_WINDUP * 0.35
			await _capture_art(game, surface, directory, "%s-%dx%d-windup" % [capture_name, viewport.x, viewport.y])
			boss.boss_cast_pending = false
			game.zombies[0] = game._trigger_boss_skill(boss)
			if game.touhou_danmaku.casts.is_empty() or Art.state(game.touhou_danmaku.casts[0]).is_empty():
				push_error("Capture requires an actual illustrated named spell: " + kind)
				failures += 1
			var previous := 0.0
			for age in [0.20, 0.75, 2.1]:
				while previous + 0.0001 < age:
					var delta := minf(1.0 / 60.0, age - previous)
					game.level_time += delta
					if kind == "prismriver_boss":
						game.zombies[0] = game._update_prismriver_hovering_boss(game.zombies[0], delta)
					game.touhou_danmaku.update(delta)
					if game.reimu_runtime != null: game.reimu_runtime.update(delta)
					if game.marisa_runtime != null: game.marisa_runtime.update(delta)
					if game.mokou_runtime != null: game.mokou_runtime.update(delta)
					game._update_effects(delta)
					previous += delta
				await _capture_art(game, surface, directory, "%s-%dx%d-%.2f" % [capture_name, viewport.x, viewport.y, age])
			game.save_dirty = false
			surface.free()
	print("Native spell art and read-only draw passes: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _capture_art(game: Control, surface: SubViewport, directory: String, label: String) -> void:
	game.banner_label.hide()
	game.toast_label.hide()
	var before: Array = [game.zombies.duplicate(true), game.effects.duplicate(true), game.touhou_danmaku.casts.duplicate(true) if game.touhou_danmaku != null else [], game.touhou_danmaku.bullets.duplicate(true) if game.touhou_danmaku != null else [], game.rng.state]
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var after: Array = [game.zombies, game.effects, game.touhou_danmaku.casts if game.touhou_danmaku != null else [], game.touhou_danmaku.bullets if game.touhou_danmaku != null else [], game.rng.state]
	if before != after:
		failures += 1
		push_error("Drawing changed combat data: " + label)
	var result := surface.get_texture().get_image().save_png("%s/%s.png" % [directory, label])
	if result != OK:
		failures += 1
	print("%s: %s" % [label, error_string(result)])
