extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_3_19_uses_rumia_midboss_and_wriggle_finale() or failed
	failed = not _test_final_boss_waits_for_rumia_gate() or failed
	failed = not _test_final_boss_forces_gate_before_midboss_lock() or failed
	failed = not _test_wriggle_entry_switches_to_boss_bgm() or failed
	failed = not _test_wriggle_reinforcements_spawn_night_bugs() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _find_level(level_id: String) -> Dictionary:
	for level in Defs.LEVELS:
		if String(level.get("id", "")) == level_id:
			return Dictionary(level)
	return {}


func _test_3_19_uses_rumia_midboss_and_wriggle_finale() -> bool:
	var level = _find_level("3-19")
	var passed := _assert_true(not level.is_empty(), "3-19 should exist")
	passed = _assert_true(String(level.get("mid_boss_kind", "")) == "rumia_boss", "3-19 should use Rumia as the road boss") and passed
	var finale_count := 0
	for event in level.get("events", []):
		if String(event.get("kind", "")) == "wriggle_boss":
			finale_count += 1
	passed = _assert_true(finale_count == 1, "3-19 should schedule exactly one Wriggle finale event") and passed
	return passed


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "3-19", "events": [], "mid_boss_kind": "rumia_boss", "boss_bgm": "res://audio/th08_wriggle_boss.mp3"}
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.board_rows = 6
	game.board_size = Vector2(882, 550)
	game.grid = []
	game.support_grid = []
	for _row in range(6):
		game.grid.append([null, null, null, null, null, null, null, null, null])
		game.support_grid.append([null, null, null, null, null, null, null, null, null])
	game.zombies = []
	game.effects = []
	return game


func _test_final_boss_waits_for_rumia_gate() -> bool:
	var game = _make_game()
	game.next_event_index = 1
	game.frozen_branch_progress_locked = true
	game.frozen_branch_midboss_spawned = true
	game.frozen_branch_midboss_cleared = false
	game.batch_spawn_queue = [{"kind": "wriggle_boss", "row": 2}]
	game.batch_spawn_remaining = 1
	game.spawn_director_timer = 0.0
	game._update_spawn_director(1.0)
	var passed := _assert_true(game.zombies.is_empty(), "Wriggle must remain queued while Rumia is alive")
	passed = _assert_true(game.batch_spawn_queue.size() == 1, "Wriggle queue entry must remain pending at the midboss gate") and passed
	game.frozen_branch_midboss_cleared = true
	game._update_spawn_director(1.0)
	passed = _assert_true(game.zombies.size() == 1 and String(game.zombies[0].get("kind", "")) == "wriggle_boss", "Wriggle should spawn after the Rumia gate clears") and passed
	game.free()
	return passed


func _test_final_boss_forces_gate_before_midboss_lock() -> bool:
	var game = _make_game()
	game.next_event_index = 1
	game.frozen_branch_progress_locked = false
	game.frozen_branch_midboss_spawned = false
	game.frozen_branch_midboss_cleared = false
	game.batch_spawn_queue = [{"kind": "wriggle_boss", "row": 2}]
	game.batch_spawn_remaining = 1
	game.spawn_director_timer = 0.0
	game._update_spawn_director(1.0)
	var passed := _assert_true(String(game.zombies[0].get("kind", "")) == "rumia_boss", "a queued finale should force the Rumia road boss to spawn first") if not game.zombies.is_empty() else false
	if game.zombies.is_empty():
		push_error("a queued finale should not spawn before the forced road boss")
	passed = _assert_true(game.batch_spawn_queue.size() == 1, "the finale queue entry must wait while the forced road boss is alive") and passed
	game.free()
	return passed


func _test_wriggle_entry_switches_to_boss_bgm() -> bool:
	var game = _make_game()
	get_root().add_child(game)
	game.frozen_branch_midboss_spawned = true
	game.frozen_branch_midboss_cleared = true
	game.current_bgm_path = ""
	game.pending_bgm_path = ""
	game._spawn_zombie("wriggle_boss", 2)
	var passed := _assert_true(String(game.pending_bgm_path) == "res://audio/th08_wriggle_boss.mp3" or String(game.current_bgm_path) == "res://audio/th08_wriggle_boss.mp3", "Wriggle entry should switch to the finale BGM")
	game.queue_free()
	return passed


func _test_wriggle_reinforcements_spawn_night_bugs() -> bool:
	var game = _make_game()
	game.frozen_branch_midboss_spawned = true
	game.frozen_branch_midboss_cleared = true
	game._spawn_zombie("wriggle_boss", 2)
	var boss = game.zombies[0]
	boss["rumia_reinforcement_timer"] = 0.0
	game.zombies[0] = boss
	game._update_zombies(0.2)
	var bug_count := 0
	for zombie in game.zombies:
		var kind = String(zombie.get("kind", ""))
		if kind == "bee_minion" or kind == "hive_zombie":
			bug_count += 1
	var passed := _assert_true(bug_count > 0, "Wriggle should keep spawning bee or hive reinforcements during the boss fight")
	game.free()
	return passed
