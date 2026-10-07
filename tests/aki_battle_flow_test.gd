extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var base: Dictionary = {}
	for level in GameScript.Defs.LEVELS:
		if level.id == "4-19": base = level.duplicate(true)
	check(not base.is_empty(), "4-19 must exist before exercising its actual battle flow")
	if base.is_empty():
		quit(1)
		return
	base.custom_level = true
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := PreviewGame.new()
		game.size = Vector2(1600, 900)
		root.add_child(game)
		var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
		game._begin_level(-1, ["sunflower", "repeater", "wallnut", "healing_gourd", "melon_pult", "torchwood", "jasmine_tea"], level)
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		check(game.active_rows == [0, 1, 2, 3, 4, 5] and game.water_rows.is_empty(), choice + ": all six active lanes are land")
		check(not game._is_fog_level() and not game._is_pool_level(), "Maple does not inherit world-four fog or pool rules")
		check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "The supplied road track is actually audible")
		if choice != "lunatic": game.active_cards[0] = "repeater"
		game._handle_primary_click(game._card_rect(0).get_center())
		game._handle_primary_click(game._cell_center(5, 1))
		check(game.grid[5][1] != null, choice + ": ordinary seed controls work on the sixth dry lane")
		game._spawn_frozen_branch_midboss()
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		var roads: Array = game.zombies.filter(func(z): return z.kind == "shizuha_boss")
		check(roads.size() == 1, "The actual road-flow spawner creates Shizuha")
		if roads.is_empty():
			await _release_game(game)
			continue
		var road: Dictionary = roads.back()
		check(bool(road.touhou_road_boss) and not bool(road.get("touhou_final_preview", false)), "The road has its own weaker Shizuha encounter")
		check(bool(road.get("touhou_road_nonspell", false)) == (choice in ["easy", "normal"]), "Only Hard and Lunatic require Shizuha's falling-leaf spell")
		check(game.current_bgm_path == level.boss_intro_bgm and game.pending_bgm_path != String(level.boss_bgm), "Road Shizuha never queues final music")
		check(game.music_player.stream == game._try_get_cached_audio_stream(String(level.boss_intro_bgm)), "The actual road playback stream remains the supplied road MP3")
		var road_uid := int(road.uid)
		var road_hp := float(road.max_health)
		# Exercise the real mandatory attack gates while isolating this flow
		# assertion from the separate four-difficulty native defense simulation.
		for frame in range(1200):
			game._apply_zombie_damage(road, 10000000, 0, 0, true)
			game.level_time += 0.1
			game._ensure_zombie_runtime().update_boss(road, 0.1)
			if game.touhou_danmaku != null: game.touhou_danmaku.update(0.1)
			game._ensure_aki_runtime().update(0.1)
			if bool(road.touhou_encounter.complete): break
		check(bool(road.touhou_encounter.complete), "The weak road encounter can finish and retreat")
		game._cleanup_dead_zombies()
		game._update_frozen_branch_flow()
		check(not game.zombies.any(func(z): return z.kind == "shizuha_boss" and z.health > 0), "Defeated road Shizuha retreats")
		game._spawn_zombie_at("minoriko_boss", 2, game._boss_anchor_x("minoriko_boss"), true)
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		var boss: Dictionary = game.zombies.filter(func(z): return z.kind == "minoriko_boss").back()
		check(int(boss.uid) != road_uid and boss.max_health > road_hp * 8 and boss.health == boss.max_health, "Minoriko is a fresh full-strength finale")
		check(game.current_bgm_path == level.boss_bgm and game.music_player.playing, "Minoriko's arrival starts audible final music")
		check(game.music_player.stream == game._try_get_cached_audio_stream(String(level.boss_bgm)), "The actual finale playback stream is the supplied final MP3")
		check(boss.has("touhou_encounter") and int(game._boss_health_bar_layout(boss).segments) == 1, "Minoriko uses the standard live per-phase Touhou health bar")
		check(game._boss_cast_status(boss).text.contains("非符"), "The finale begins with its readable nonspell declaration")
		var enemy_count := game.zombies.size()
		var existing_enemy_uids: Array = game.zombies.map(func(z): return int(z.uid))
		boss.rumia_reinforcement_timer = 0.0
		game._update_zombies(0.1)
		# Valid fusion reinforcements (including cone backup dancers) also count;
		# the RNG may pick two equipped enemies rather than the older small roster.
		check(game.zombies.size() > enemy_count and game.zombies.any(func(z): return not existing_enemy_uids.has(int(z.uid)) and not game._is_boss_zombie(z) and not bool(game.Defs.ZOMBIES[z.kind].get("boss_summon",false)) and z.health > 0), "Fresh ordinary/fusion enemies continue spawning while Minoriko casts")
		for kind in ["shizuha_boss", "minoriko_boss"]:
			for frame in range(24): check(game._try_get_boss_frame_texture(kind, frame) != null, kind + ": original supplied pose loads " + str(frame))
		var rt = game._ensure_aki_runtime()
		rt.queue_field(int(boss.uid), Vector2i(5, 1), "leaf_mat", 1.2)
		game.battle_paused = true
		game._process(1.0)
		check(float(rt.fields.back().age) == 0.0, "Battle pause freezes the leaf warning")
		game.battle_paused = false
		rt.update(1.3)
		check(rt.action_factor(5, 1) < 1.0, "The sixth-lane ordinary repeater is affected by settled leaves")
		# Activate the actual available plant-food action: the authored counter
		# belongs to the activation path, rather than a direct test-only cleanse.
		# The stronger road may kill the seed-control crop before this isolated
		# cleanse assertion; an actual living replacement is required to cast.
		if game.grid[5][1] == null or float(game.grid[5][1].health) <= 0.0: game.grid[5][1] = game._create_plant("repeater", 5, 1)
		check(game._ensure_plant_food_runtime().activate(5, 1), "A living replacement really activates plant food")
		check(rt.fields.is_empty(), "Actual plant-food activation clears its leaf lane")
		rt.queue_field(int(boss.uid), Vector2i(4, 1), "leaf_mat", 0.0)
		game._trigger_boss_phase_shift(boss, 1)
		check(rt.fields.is_empty(), "A real phase shift clears the previous leaf field")
		await _release_game(game)
	print("Aki actual road/finale, four modes, six-lane input, audible BGM, poses and counterplay: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _release_game(game: Control) -> void:
	game._stop_bgm()
	game.music_player.stream = null
	game.save_dirty = false
	await create_timer(0.15).timeout
	game.free()
	await process_frame
