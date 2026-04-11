extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_6_19_has_exactly_one_city_boss_event() or failed
	failed = not _test_city_boss_cannot_duplicate_spawn() or failed
	failed = not _test_city_boss_skill_cycle_summons_mixed_citywide_roster() or failed
	failed = not _test_city_boss_reinforcement_timer_spawns_right_side_pressure() or failed
	failed = not _test_city_boss_health_bar_uses_five_segments_at_bottom() or failed
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


func _all_non_boss_zombies() -> Dictionary:
	var result := {}
	for kind_variant in Defs.ZOMBIES.keys():
		var kind = String(kind_variant)
		if bool(Defs.ZOMBIES.get(kind, {}).get("boss", false)):
			continue
		result[kind] = true
	return result


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "6-19", "terrain": "city", "boss_level": true, "boss_kind": "city_boss", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
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


func _test_6_19_has_exactly_one_city_boss_event() -> bool:
	var level = _find_level("6-19")
	if not _assert_true(not level.is_empty(), "expected 6-19 to exist before checking city boss events"):
		return false
	var boss_events := 0
	for event in level.get("events", []):
		if String(Dictionary(event).get("kind", "")) == "city_boss":
			boss_events += 1
	return _assert_true(boss_events == 1, "6-19 should schedule exactly one city_boss event")


func _test_city_boss_cannot_duplicate_spawn() -> bool:
	var game = _make_game()
	game._spawn_zombie("city_boss", 1)
	game._spawn_zombie("city_boss", 4)
	var passed = _assert_true(_count_alive_kind(game, "city_boss") == 1, "city_boss should not spawn a second copy while one is still alive")
	_free_game(game)
	return passed


func _test_city_boss_skill_cycle_summons_mixed_citywide_roster() -> bool:
	var game = _make_game()
	game._spawn_zombie("city_boss", 2)
	var boss = game.zombies[0]
	boss["boss_skill_cycle"] = 0
	game.zombies[0] = boss
	var before_count = game.zombies.size()
	game.zombies[0] = game._trigger_boss_skill(boss)
	var allowed = _all_non_boss_zombies()
	var passed = _assert_true(game.zombies.size() >= before_count + 4, "city_boss summon skill should add a large mixed reinforcement pack")
	for zombie_index in range(1, game.zombies.size()):
		var kind = String(game.zombies[zombie_index].get("kind", ""))
		passed = _assert_true(allowed.has(kind), "city_boss summon skill should only spawn non-boss reinforcements, got %s" % kind) and passed
	_free_game(game)
	return passed


func _test_city_boss_reinforcement_timer_spawns_right_side_pressure() -> bool:
	var game = _make_game()
	game._spawn_zombie("city_boss", 2)
	var boss = game.zombies[0]
	boss["rumia_reinforcement_timer"] = 0.0
	game.zombies[0] = boss
	game._update_zombies(0.2)
	var reinforcements: Array = []
	for zombie_index in range(1, game.zombies.size()):
		reinforcements.append(game.zombies[zombie_index])
	var passed = _assert_true(not reinforcements.is_empty(), "city_boss should keep spawning right-side pressure while alive")
	if not reinforcements.is_empty():
		var reinforcement = Dictionary(reinforcements[0])
		passed = _assert_true(float(reinforcement.get("x", 0.0)) >= game.BOARD_ORIGIN.x + game.board_size.x, "city_boss reinforcements should enter from the right edge") and passed
		passed = _assert_true(_all_non_boss_zombies().has(String(reinforcement.get("kind", ""))), "city_boss reinforcements should come from the mixed non-boss roster") and passed
	_free_game(game)
	return passed


func _test_city_boss_health_bar_uses_five_segments_at_bottom() -> bool:
	var game = _make_game()
	var boss = {
		"kind": "city_boss",
		"health": 16800.0,
		"max_health": 16800.0,
	}
	game.zombies = [boss]
	game.size = Vector2(1280.0, 960.0)
	var layout = game._boss_health_bar_layout(boss)
	var rect = Rect2(layout.get("rect", Rect2()))
	var board_bottom = game.BOARD_ORIGIN.y + game.board_size.y
	var passed = _assert_true(int(layout.get("segments", 0)) == 5, "boss health bar should stay at five segments for city_boss") \
		and _assert_true(rect.position.y >= board_bottom, "city_boss health bar should stay below the board") \
		and _assert_true(rect.position.y + rect.size.y <= game.size.y - 8.0, "city_boss health bar should stay locked near the bottom edge")
	_free_game(game)
	return passed
