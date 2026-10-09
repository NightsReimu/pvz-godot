extends "res://scripts/tools/capture_battle_polish.gd"
# Native rendered snapshots of every Mountain of Faith card (run without --headless):
# WG_STAGE=4-20 WG_TIER=lunatic godot --path . -s res://scripts/tools/capture_wind_god_cards.gd
const Phase = preload("res://scripts/runtime/touhou_phase_runtime.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const DIRECTORY := "res://output/wind-god-cards"
const STAGES := {
	"4-19": {"finale": "minoriko_boss", "road": "shizuha_boss"},
	"4-20": {"finale": "hina_boss", "road": "hina_boss"},
	"4-21": {"finale": "nitori_boss", "road": "nitori_boss"},
	"4-22": {"finale": "aya_boss", "road": "momiji_boss"},
	"4-23": {"finale": "sanae_boss", "road": "sanae_boss"},
}
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)

func _stage(id: String) -> Dictionary:
	for level in GameScript.Defs.LEVELS:
		if String(level.id) == id: return level.duplicate(true)
	return {}

func _road_entries(kind: String, level: Dictionary) -> Array:
	match kind:
		"hina_boss": return [Spells.Hina.road_card(level)]
		"nitori_boss": return Spells.Nitori.road_phases(level)[0]
		"sanae_boss": return Spells.Sanae.road_phases(level)[0] + Spells.Sanae.road_phases(level)[1]
	return Spells.phases_for(kind, level).reduce(func(all, phase): return all + phase, [])

func _shot(g: Control, surface: SubViewport, label: String) -> void:
	g.banner_label.hide(); g.toast_label.hide(); g.queue_redraw()
	await process_frame; await RenderingServer.frame_post_draw
	check(surface.get_texture().get_image().save_png(DIRECTORY + "/%dx%d-%s.png" % [surface.size.x, surface.size.y, label]) == OK, "Saves " + label)

func _step(g: Control, seconds: float) -> void:
	for frame in range(ceili(seconds / 0.05)):
		g.level_time += 0.05; g.ui_time += 0.05
		if g.touhou_danmaku != null: g.touhou_danmaku.update(0.05)
		g._update_effects(0.05)

func _play(g: Control, surface: SubViewport, b: Dictionary, entry: Array, label: String, times: Array) -> void:
	if b.has("touhou_owner"): g.touhou_danmaku.clear_owner(int(b.touhou_owner))
	b.touhou_cast_remaining = 0.0; b.touhou_invulnerable = false
	var e: Dictionary = b.touhou_encounter
	e.phases = [[entry]]; e.index = 0; e.attack = 0; e.completed = 0; e.complete = false; e.depleted = false
	Phase._set_bounds(b); b.health = e.ceiling
	g._trigger_boss_skill(b)
	var elapsed := 0.0
	for t in times:
		_step(g, float(t) - elapsed); elapsed = float(t)
		await _shot(g, surface, "%s-%.1fs" % [label, elapsed])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	var only_stage := OS.get_environment("WG_STAGE")
	var tier := OS.get_environment("WG_TIER")
	if tier.is_empty(): tier = "normal"
	var viewports := [Vector2i(1600, 900)] if OS.get_environment("WG_PHONE").is_empty() else [Vector2i(844, 390)]
	for viewport in viewports:
		var surface := SubViewport.new(); surface.size = viewport; surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(surface)
		for id in STAGES:
			if not only_stage.is_empty() and id != only_stage: continue
			var level: Dictionary = GameScript.TouhouDifficulty.build_level(_stage(id), tier)
			for role in ["road", "finale"]:
				var kind := String(STAGES[id][role])
				var g := PreviewGame.new(); g.size = Vector2(viewport); g.mobile_runtime_override = 1 if viewport.y < 600 else 0; surface.add_child(g); g.rng.seed = 905
				g._begin_level(-1, ["sunflower", "repeater", "wallnut", "healing_gourd", "melon_pult", "umbrella_leaf", "torchwood", "cherry_bomb", "plantern", "cactus"], level)
				g.battle_intro_timer = 0; g.level_time = 80; g.startup_loading_active = false; g.page_transition_active = false; g.selected_tool = ""
				if not g.water_rows.is_empty():
					for row in range(6):
						for col in range(4): g.support_grid[row][col] = g._create_plant("lily_pad", row, col)
				for row in range(6):
					for col in range(4):
						g.grid[row][col] = g._create_plant(["wallnut", Fusion.result("repeater", "wallnut") if row % 2 else "repeater", "melon_pult", "repeater"][col], row, col)
						g.grid[row][col].spawn_time = 0; g.grid[row][col].sleep_timer = 0
				g._spawn_zombie_at(kind, 2, g._boss_anchor_x(kind), true)
				var b: Dictionary = g.zombies.back()
				g._drain_asset_prewarm_queue()
				var entries: Array = _road_entries(kind, level) if role == "road" else Spells.phases_for(kind, level).reduce(func(all, phase): return all + phase, [])
				var seen := {}
				for entry in entries:
					var pattern := String(entry[2])
					if seen.has(pattern): continue
					seen[pattern] = true
					var label := "%s-%s-%s-%s" % [id, tier, role, pattern]
					var times: Array = [1.0, 2.6] if not pattern.begins_with("nonspell") else [1.8]
					if not OS.get_environment("WG_TIMES").is_empty(): times = Array(OS.get_environment("WG_TIMES").split(",")).map(func(v): return float(v))
					await _play(g, surface, b, entry, label, times)
				g.touhou_danmaku.clear(); g._stop_bgm(); g.music_player.stream = null
				for player in g.sfx_players: player.stop(); player.stream = null
				g.save_dirty = false; g.free(); await process_frame
		await create_timer(0.3).timeout; surface.free(); await process_frame
	print("Wind God card captures: %d failure(s)" % failures)
	call_deferred("quit", 1 if failures else 0)
