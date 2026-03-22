extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_3_18_has_exactly_one_pool_boss_event() or failed
	failed = not _test_pool_boss_cannot_duplicate_spawn() or failed
	failed = not _test_pool_boss_skill_cycle_summons_pool_roster() or failed
	failed = not _test_pool_boss_reinforcement_timer_spawns_right_side_pressure() or failed
	failed = not _test_pool_boss_health_bar_uses_five_segments_at_bottom() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _find_level(level_id: String) -> Dictionary:
	for level in Defs.LEVELS:
		if String(level.get("id", "")) == level_id:
			return level
	return {}


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "3-18", "terrain": "pool", "events": [], "boss_level": true}
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.water_rows = [2, 3]
	game.board_rows = 6
	game.board_size = Vector2(9.0 * 98.0, 6.0 * 110.0)
	game.grid = []
	game.support_grid = []
	for _row in range(6):
		var row_data: Array = []
		var support_row: Array = []
		for _col in range(9):
			row_data.append(null)
			support_row.append(null)
		game.grid.append(row_data)
		game.support_grid.append(support_row)
	game.zombies = []
	game.effects = []
	game.mowers = []
	for row in range(6):
		game.mowers.append({
			"row": row,
			"x": game.BOARD_ORIGIN.x - 56.0,
			"armed": true,
			"active": false,
		})
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	if is_instance_valid(game.banner_label):
		game.banner_label.free()
	if is_instance_valid(game.message_label):
		game.message_label.free()
	if is_instance_valid(game.action_button):
		game.action_button.free()
	if is_instance_valid(game.message_panel):
		game.message_panel.free()
	game.free()


func _count_alive_kind(game: Control, kind: String) -> int:
	var count := 0
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) != kind:
			continue
		if float(zombie.get("health", 0.0)) <= 0.0:
			continue
		count += 1
	return count


func _test_3_18_has_exactly_one_pool_boss_event() -> bool:
	var level = _find_level("3-18")
	if not _assert_true(not level.is_empty(), "expected 3-18 to exist before checking boss events"):
		return false
	var boss_events := 0
	for event in level.get("events", []):
		if String(event.get("kind", "")) == "pool_boss":
			boss_events += 1
	return _assert_true(boss_events == 1, "3-18 should schedule exactly one pool_boss event")


func _test_pool_boss_cannot_duplicate_spawn() -> bool:
	var game = _make_game()
	game._spawn_zombie("pool_boss", 1)
	game._spawn_zombie("pool_boss", 4)
	var passed = _assert_true(_count_alive_kind(game, "pool_boss") == 1, "pool_boss should not spawn a second copy while one is still alive")
	_free_game(game)
	return passed


func _test_pool_boss_skill_cycle_summons_pool_roster() -> bool:
	var game = _make_game()
	game._spawn_zombie("pool_boss", 1)
	var boss = game.zombies[0]
	boss["boss_skill_cycle"] = 0
	game.zombies[0] = boss
	var before_count = game.zombies.size()
	game.zombies[0] = game._trigger_boss_skill(boss)
	var allowed = {
		"dragon_boat": true,
		"qinghua": true,
		"shouyue": true,
		"ice_block": true,
		"dragon_dance": true,
	}
	var passed = _assert_true(game.zombies.size() >= before_count + 3, "pool_boss summon skill should add a pool-era reinforcement pack")
	for zombie_index in range(1, game.zombies.size()):
		var kind = String(game.zombies[zombie_index].get("kind", ""))
		passed = _assert_true(allowed.has(kind), "pool_boss summon skill should only spawn pool-era reinforcements, got %s" % kind) and passed
	_free_game(game)
	return passed


func _test_pool_boss_reinforcement_timer_spawns_right_side_pressure() -> bool:
	var game = _make_game()
	game._spawn_zombie("pool_boss", 1)
	var boss = game.zombies[0]
	boss["rumia_reinforcement_timer"] = 0.0
	game.zombies[0] = boss
	game._update_zombies(0.2)
	var allowed = {
		"dragon_boat": true,
		"qinghua": true,
		"shouyue": true,
		"ice_block": true,
		"dragon_dance": true,
		"lifebuoy_normal": true,
		"lifebuoy_cone": true,
		"lifebuoy_bucket": true,
	}
	var reinforcements: Array = []
	for zombie_index in range(1, game.zombies.size()):
		reinforcements.append(game.zombies[zombie_index])
	var passed = _assert_true(not reinforcements.is_empty(), "pool_boss should keep spawning right-side pressure while alive")
	if not reinforcements.is_empty():
		var reinforcement = Dictionary(reinforcements[0])
		passed = _assert_true(float(reinforcement.get("x", 0.0)) >= game.BOARD_ORIGIN.x + game.board_size.x, "pool_boss reinforcements should enter from the right edge") and passed
		passed = _assert_true(allowed.has(String(reinforcement.get("kind", ""))), "pool_boss reinforcements should come from the pool roster") and passed
	_free_game(game)
	return passed


func _test_pool_boss_health_bar_uses_five_segments_at_bottom() -> bool:
	var game = _make_game()
	var boss = {
		"kind": "pool_boss",
		"health": float(Defs.ZOMBIES["pool_boss"]["health"]),
		"max_health": float(Defs.ZOMBIES["pool_boss"]["health"]),
	}
	var layout = game._boss_health_bar_layout(boss)
	var passed = _assert_true(layout is Dictionary, "pool_boss health bar layout should be a dictionary")
	if layout is Dictionary:
		passed = _assert_true(int(layout.get("segments", 0)) == 5, "pool_boss health bar should use five segments") and passed
		passed = _assert_true(float(layout.get("rect_y", 0.0)) > game.BOARD_ORIGIN.y + game.board_size.y, "pool_boss health bar should sit below the battlefield") and passed
	_free_game(game)
	return passed
