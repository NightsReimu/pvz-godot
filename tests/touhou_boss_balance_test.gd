extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_touhou_boss_health_targets_are_set() or failed
	failed = not _test_touhou_boss_skill_and_reinforcement_cadence_is_capped() or failed
	failed = not _test_sakuya_time_stop_stays_reactive() or failed
	failed = not _test_remilia_crimson_drain_is_pressure_not_a_wipe() or failed
	failed = not _test_flandre_spell_cards_use_configured_damage_keys() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _assert_near(actual: float, expected: float, tolerance: float, message: String) -> bool:
	if absf(actual - expected) <= tolerance:
		return true
	push_error("%s expected %.3f got %.3f" % [message, expected, actual])
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "1-balance-test", "terrain": "blood_toy_roof", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.water_rows = []
	game.grid = []
	game.support_grid = []
	for _row in range(game.ROWS):
		var row_data: Array = []
		var support_row: Array = []
		for _col in range(game.COLS):
			row_data.append(null)
			support_row.append(null)
		game.grid.append(row_data)
		game.support_grid.append(support_row)
	game.zombies = []
	game.effects = []
	game.projectiles = []
	game.mowers = []
	for row in range(game.ROWS):
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


func _plant_health_after_flandre_cycle(cycle: int, row: int, col: int) -> Dictionary:
	var game = _make_game()
	game.rng.seed = 20260621
	var plant = game._create_plant("wallnut", row, col)
	game.grid[row][col] = plant
	var before = float(plant["health"])
	var boss := {
		"kind": "flandre_boss",
		"row": 2,
		"x": game.BOARD_ORIGIN.x + game.board_size.x - 20.0,
		"boss_phase": 0,
		"boss_skill_cycle": cycle,
		"max_health": float(Defs.ZOMBIES["flandre_boss"]["health"]),
		"health": float(Defs.ZOMBIES["flandre_boss"]["health"]),
	}
	game.call("_trigger_flandre_boss_skill", boss)
	var after = float(game.grid[row][col]["health"])
	var result := {"before": before, "after": after}
	_free_game(game)
	return result


func _test_touhou_boss_health_targets_are_set() -> bool:
	var expected := {
		"rumia_boss": 13800.0,
		"daiyousei_boss": 6400.0,
		"cirno_boss": 14500.0,
		"meiling_boss": 15600.0,
		"koakuma_boss": 7800.0,
		"patchouli_boss": 18600.0,
		"sakuya_boss": 20600.0,
		"remilia_boss": 25600.0,
		"flandre_boss": 27200.0,
	}
	var passed := true
	for kind in expected.keys():
		passed = _assert_near(float(Defs.ZOMBIES[kind]["health"]), float(expected[kind]), 0.01, "%s health should match the tuned Touhou target" % kind) and passed
	return passed


func _test_touhou_boss_skill_and_reinforcement_cadence_is_capped() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_boss_skill_cycle_length"), "expected boss skill cycle helper") \
		and _assert_true(game.has_method("_boss_skill_interval"), "expected boss skill interval helper") \
		and _assert_true(game.has_method("_boss_reinforcement_interval"), "expected boss reinforcement interval helper")
	if passed:
		passed = _assert_true(int(game.call("_boss_skill_cycle_length", "flandre_boss")) == 11, "Flandre should keep the full 11-card spell cycle") and passed
		passed = _assert_true(float(game.call("_boss_skill_interval", "flandre_boss", 3)) >= 4.9, "Flandre late-phase skills should not fire faster than the readable cap") and passed
		passed = _assert_true(float(game.call("_boss_skill_interval", "sakuya_boss", 3)) >= 5.3, "Sakuya late-phase skills should keep time-stop readable") and passed
		passed = _assert_true(float(game.call("_boss_skill_interval", "rumia_boss", 3)) >= 5.2, "Rumia should pressure through darkness, not high-frequency spam") and passed
		passed = _assert_true(float(game.call("_boss_reinforcement_interval", "flandre_boss", 3)) >= 3.4, "Flandre reinforcements should not flood faster than the cap") and passed
		passed = _assert_true(float(game.call("_boss_reinforcement_interval", "remilia_boss", 3)) >= 3.5, "Remilia reinforcements should leave counterplay windows") and passed
		passed = _assert_true(float(game.call("_boss_reinforcement_interval", "sakuya_boss", 3)) >= 3.7, "Sakuya reinforcements should not stack too hard with time stop") and passed
	_free_game(game)
	return passed


func _test_sakuya_time_stop_stays_reactive() -> bool:
	var game = _make_game()
	var boss := {
		"kind": "sakuya_boss",
		"row": 2,
		"x": game.BOARD_ORIGIN.x + game.board_size.x - 18.0,
		"boss_phase": 3,
		"boss_skill_cycle": 4,
		"max_health": float(Defs.ZOMBIES["sakuya_boss"]["health"]),
		"health": float(Defs.ZOMBIES["sakuya_boss"]["health"]),
	}
	game.call("_trigger_sakuya_boss_skill", boss)
	var passed = _assert_true(float(game.get("boss_time_stop_timer")) <= 2.35, "Sakuya time stop should stay capped for counterplay") \
		and _assert_true(int(boss.get("sakuya_relocations_remaining", 99)) <= 3, "Sakuya should not relocate too many plants during one time stop") \
		and _assert_true(game.zombies.size() <= 2, "Sakuya should not pair one time stop with excessive reinforcements")
	_free_game(game)
	return passed


func _test_remilia_crimson_drain_is_pressure_not_a_wipe() -> bool:
	var game = _make_game()
	game.grid[2][2] = game._create_plant("repeater", 2, 2)
	var before = float(game.grid[2][2]["health"])
	game.zombies.append({
		"kind": "remilia_boss",
		"row": 2,
		"x": game.BOARD_ORIGIN.x + game.board_size.x - 18.0,
		"health": float(Defs.ZOMBIES["remilia_boss"]["health"]),
		"max_health": float(Defs.ZOMBIES["remilia_boss"]["health"]),
		"boss_phase": 3,
		"flash": 0.0,
	})
	game.call("_update_remilia_crimson_drain", 5.0)
	var damage = before - float(game.grid[2][2]["health"])
	var passed = _assert_true(damage > 35.0, "Remilia crimson drain should still matter over time") \
		and _assert_true(damage <= 70.0, "Remilia crimson drain should pressure plants without acting like a board wipe")
	_free_game(game)
	return passed


func _test_flandre_spell_cards_use_configured_damage_keys() -> bool:
	var data = Dictionary(Defs.ZOMBIES["flandre_boss"])
	var laevatein = _plant_health_after_flandre_cycle(0, 2, 3)
	var kagome = _plant_health_after_flandre_cycle(2, 2, 3)
	var judgement = _plant_health_after_flandre_cycle(9, 2, 2)
	var passed = _assert_near(float(laevatein["before"]) - float(laevatein["after"]), float(data["laevatein_damage"]), 0.01, "Laevatein should use laevatein_damage") \
		and _assert_near(float(kagome["before"]) - float(kagome["after"]), float(data["kagome_damage"]), 0.01, "Kagome should use kagome_damage") \
		and _assert_near(float(judgement["before"]) - float(judgement["after"]), float(data["judgement_damage"]), 0.01, "Judgement Grid should use judgement_damage")
	return passed
