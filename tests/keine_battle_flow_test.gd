extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var level: Dictionary = {}
	for item in GameScript.Defs.LEVELS:
		if item.id == "3-21":
			level = item.duplicate(true)
	level["custom_level"] = true
	var game := PreviewGame.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	game._begin_level(-1, [], level)
	game._drain_asset_prewarm_queue()
	game._try_play_pending_bgm()
	check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "Beginning the stage must play the supplied road music")
	check(game.water_rows.is_empty() and game.active_rows.size() == 6, "All six lanes must be grass")
	game.active_cards[0] = "repeater"
	game._handle_primary_click(game._card_rect(0).get_center())
	game._handle_primary_click(game._cell_center(5, 2))
	check(game.grid[5][2] != null and game.grid[5][2].kind == "repeater", "Conveyor card and cell clicks must plant in the sixth row")
	game._spawn_zombie_at("keine_boss", 2, game._boss_anchor_x("keine_boss"), true)
	check(game.current_bgm_path == level.boss_bgm and game.music_player.playing, "Entering the finale must actually play the boss track")
	check(not game.frozen_branch_midboss_spawned, "No separate road boss may appear")
	var boss: Dictionary = game.zombies.back()
	var runtime = game._ensure_keine_runtime()
	runtime.cast(boss, "keine_whip")
	runtime.queue_bamboo(boss, 4)
	game.battle_paused = true
	var time_before := game.level_time
	game._process(1.0)
	check(game.level_time == time_before and runtime.attacks[0].age == 0.0, "Pausing must freeze original attack warnings")
	game.battle_paused = false
	runtime.update(1.4)
	check(game.zombies.size() > 1, "Bamboo summons must enter the live enemy list")
	game._begin_level(-1, [], level)
	check(runtime.attacks.is_empty() and runtime.shots.is_empty() and game.zombies.is_empty(), "Restarting the stage must remove summons and pending attacks")
	check(game.grid[5][2] == null, "Restart must reset the board")
	check(game.current_bgm_path == level.boss_intro_bgm, "Restart must restore road music")
	game._spawn_zombie_at("keine_boss", 2, game._boss_anchor_x("keine_boss"), true)
	boss = game.zombies.back()
	boss.touhou_encounter.complete = true
	boss.health = 0.0
	game._cleanup_dead_zombies()
	game._check_end_state()
	check(game.battle_state == game.BATTLE_WON, "Defeating the completed final encounter must end the stage")
	game.save_dirty = false
	game.free()
	print("Keine live battle flow: %d failure(s)" % failures)
	quit(1 if failures else 0)
