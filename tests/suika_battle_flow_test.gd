extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var base: Dictionary = GameScript.Defs.AncientLevelDefs.LEVELS.back().duplicate(true)
	base.custom_level = true
	var game := PreviewGame.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var level := game.TouhouDifficulty.build_level(base, choice)
		game._begin_level(-1, ["sunflower", "repeater", "wallnut", "jasmine_tea", "golden_milk", "healing_gourd"], level)
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "Road music is audible before Suika's finale")
		if choice != "lunatic": game.active_cards[0] = "repeater"
		game._handle_primary_click(game._card_rect(0).get_center())
		game._handle_primary_click(game._cell_center(4, 1))
		check(game.grid[4][1] != null, choice + ": seed controls must work on the fifth stone lane")
		game._spawn_frozen_branch_midboss()
		game._drain_asset_prewarm_queue()
		for frame in range(120):
			game._process(0.05)
			if frame % 30 == 0: await process_frame
		check(game.pending_bgm_path != String(level.boss_bgm), "Road must never queue the supplied final BGM")
		check(game.music_player.stream == game._try_get_cached_audio_stream(String(level.boss_intro_bgm)) and game.music_player.playing, "Road actual playback remains the existing night track")
		var road: Dictionary = game.zombies.filter(func(z): return z.kind == "suika_boss").back()
		check(road.touhou_final_preview and road.touhou_encounter.phases.size() == 1, "Road Suika only demonstrates a nonspell")
		check(game.current_bgm_path == level.boss_intro_bgm, "The road preview must not start final music")
		var road_uid := int(road.uid)
		var road_hp := float(road.max_health)
		game._apply_zombie_damage(road, 10000000, 0, 0, true)
		game._cleanup_dead_zombies()
		game._update_frozen_branch_flow()
		check(not game.zombies.any(func(z): return z.kind == "suika_boss" and z.health > 0), "Defeated road Suika retreats without requiring the whole finale")
		game._spawn_zombie_at("suika_boss", 2, game._boss_anchor_x("suika_boss"), true)
		game._try_play_pending_bgm()
		var boss: Dictionary = game.zombies.filter(func(z): return z.kind == "suika_boss").back()
		check(int(boss.uid) != road_uid and boss.max_health > road_hp * 8 and boss.health == boss.max_health, "Final Suika is a fresh full-health encounter")
		check(game.current_bgm_path == level.boss_bgm and game.music_player.playing, "Finale actually plays the supplied MP3")
		check(game.music_player.stream == game._try_get_cached_audio_stream(String(level.boss_bgm)), "Only full finale uses the supplied final BGM playback stream")
		check(boss.has("touhou_encounter") and int(game._boss_health_bar_layout(boss).segments) == 1, "Suika must use the same live per-phase blood bar as other Touhou bosses")
		check(game._boss_cast_status(boss).text.contains("非符"), "Suika must show her Touhou attack declaration before casting")
		var enemy_count := game.zombies.size()
		boss.rumia_reinforcement_timer = 0.0
		game._update_zombies(0.1)
		check(game.zombies.size() >= enemy_count + 2 and game.zombies.any(func(z): return not bool(GameScript.Defs.ZOMBIES[z.kind].get("boss", false)) and not bool(GameScript.Defs.ZOMBIES[z.kind].get("boss_summon", false)) and z.health > 0), "Live Suika finale continues spawning ordinary or armored fusion enemies in real support batches")
		for frame in range(24): check(game._try_get_boss_frame_texture("suika_boss", frame) != null, "Original pose loads " + str(frame))
		var rt = game._ensure_suika_runtime()
		rt.queue_pour(int(boss.uid), 4)
		game.battle_paused = true
		game._process(1.0)
		check(float(rt.pours[0].age) == 0.0, "Battle pause freezes the gourd warning")
		game.battle_paused = false
		rt.update(2.8)
		check(rt.action_factor(4, 1) == 0.55, "The ordinary repeater is affected by wine")
		game._ensure_plant_food_runtime().activate(4, 1)
		check(rt.pours.is_empty(), "Actual plant-food activation clears its wine lane")
		rt.spawn_mini(int(boss.uid), 0)
		game._trigger_boss_phase_shift(boss, 1)
		check(not game.zombies.any(func(z): return z.kind == "suika_mini" and z.health > 0), "A real phase shift clears miniature bodies")
	game.save_dirty = false
	game.free()
	await process_frame
	print("Suika four modes, road/finale, audible BGM, 24 poses, pause and counterplay: %d failure(s)" % failures)
	quit(1 if failures else 0)
