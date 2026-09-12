extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var base: Dictionary = {}
	for item in GameScript.Defs.LEVELS:
		if item.id == "3-22-b":
			base = item.duplicate(true)
	base["custom_level"] = true
	var game := PreviewGame.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
		game._begin_level(-1, ["sunflower", "repeater", "wallnut", "snow_pea", "cherry_bomb", "healing_gourd"], level)
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "Stage must actually play the supplied road music")
		check(game.active_rows.size() == 6 and game.water_rows.is_empty(), "Six plantable grass lanes")
		if choice != "lunatic":
			game.active_cards[0] = "repeater"
		game._handle_primary_click(game._card_rect(0).get_center())
		game._handle_primary_click(game._cell_center(5, 2))
		check(game.grid[5][2] != null, "Both conveyor and manual clicks must plant on row six")
		var runtime = game._ensure_marisa_runtime()
		var backdrop = game._ensure_reimu_runtime()
		runtime.update(0.5)
		backdrop.update(0.5)
		check(backdrop.light == 0.0, "Road lighting must stay dim")
		game._spawn_zombie_at("marisa_boss", 2, game._boss_anchor_x("marisa_boss"), true)
		var boss: Dictionary = game.zombies.back()
		check(game.current_bgm_path == level.boss_bgm and game.music_player.playing, "Marisa's entrance must play the supplied finale music")
		check(not game.frozen_branch_midboss_spawned, "There must be no midboss encounter")
		for frame in range(24):
			check(game._try_get_boss_frame_texture("marisa_boss", frame) != null, "Every supplied sprite frame must load")
		runtime.queue_tile(boss, Vector2i(5, 2), "glare")
		game.battle_paused = true
		var before := game.level_time
		game._process(1.0)
		check(game.level_time == before and runtime.tiles[0].age == 0.0 and backdrop.light == 0.0, "Pause must freeze tile warning and light transition")
		game.battle_paused = false
		runtime.update(1.2)
		backdrop.update(1.2)
		check(backdrop.light > 0.0 and backdrop.light < 1.0 and game.grid[5][2].get("marisa_glare", false), "Boss light must ramp gradually while seals activate")
		game._trigger_boss_phase_shift(boss, 1)
		check(runtime.tiles.is_empty() and not game.grid[5][2].has("marisa_glare"), "Stage change must release the sealed plant")
		var count := game.zombies.size()
		game._spawn_hover_boss_reinforcement("marisa_boss", 1)
		check(game.zombies.size() > count, "Marisa must retain supporting zombie pressure")
		game._begin_level(-1, [], level)
		check(runtime.tiles.is_empty() and backdrop.light == 0 and game.zombies.is_empty() and game.grid[5][2] == null, "Retry must reset tiles, marks, zombies, board and lighting")
		check(game.current_bgm_path == level.boss_intro_bgm and game.current_level.touhou_difficulty == choice, "Retry must keep difficulty and restore road music")
		game._spawn_zombie_at("marisa_boss", 2, game._boss_anchor_x("marisa_boss"), true)
		boss = game.zombies.back()
		boss.touhou_encounter.complete = true
		boss.health = 0.0
		game._cleanup_dead_zombies()
		game._check_end_state()
		check(game.battle_state == game.BATTLE_WON, "Completed finale must permit victory")
	game.save_dirty = false
	game.free()
	print("Marisa live flow: four modes, assets, planting, music, pause, phase, retry, reinforcement and victory: %d failure(s)" % failures)
	quit(1 if failures else 0)
