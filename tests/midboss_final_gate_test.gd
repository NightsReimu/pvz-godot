extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScript.new()
	game.current_level = {
		"id": "gate-test",
		"events": [{"time": 1.0, "kind": "remilia_boss", "row": 2}],
		"mid_boss_kind": "sakuya_boss",
		"row_count": 5,
	}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(882, 550)
	game.next_event_index = 1
	game.frozen_branch_progress_locked = true
	game.frozen_branch_midboss_cleared = false
	game.batch_spawn_queue = [{"kind": "remilia_boss", "row": 2}]
	game.batch_spawn_remaining = 1
	game.spawn_director_timer = 0.0
	game._update_spawn_director(1.0)
	var passed := game.zombies.is_empty() and game.batch_spawn_queue.size() == 1
	if not passed:
		push_error("Final boss must remain queued until the midboss is defeated")
	game.frozen_branch_midboss_cleared = true
	game._update_spawn_director(1.0)
	passed = passed and game.zombies.size() == 1 and game.batch_spawn_queue.is_empty()
	if not passed:
		push_error("Final boss should spawn after the midboss gate clears")
	game.free()
	quit(0 if passed else 1)
