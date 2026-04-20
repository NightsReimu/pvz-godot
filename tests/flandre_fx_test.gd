extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_flandre_skill_cycle_uses_eleven_distinct_signature_effects() or failed
	failed = not _test_flandre_phase_shift_uses_dedicated_destroyer_field_effect() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "1-23", "terrain": "blood_toy_roof", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
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
	game.projectiles = []
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


func _effect_shapes(game: Control) -> Array:
	var shapes: Array = []
	for effect in game.effects:
		shapes.append(String(effect.get("shape", "")))
	return shapes


func _test_flandre_skill_cycle_uses_eleven_distinct_signature_effects() -> bool:
	var game = _make_game()
	var expected_shapes = [
		"flandre_laevatein",
		"flandre_four_of_a_kind",
		"flandre_kagome_ring",
		"flandre_starbow_break",
		"flandre_doll_box",
		"flandre_crystal_spike",
		"flandre_break_switch",
		"flandre_toy_storm",
		"flandre_secret_barrage",
		"flandre_judgement_grid",
		"flandre_cranberry_trap",
	]
	var seen := {}
	var passed = _assert_true(game.has_method("_trigger_flandre_boss_skill"), "expected dedicated Flandre skill trigger to exist")
	if passed:
		for cycle in range(expected_shapes.size()):
			game.effects.clear()
			var boss := {
				"kind": "flandre_boss",
				"row": 2,
				"x": game.BOARD_ORIGIN.x + game.board_size.x - 20.0,
				"boss_phase": 1,
				"boss_skill_cycle": cycle,
				"max_health": 24800.0,
				"health": 24800.0,
			}
			game.call("_trigger_flandre_boss_skill", boss)
			var shapes = _effect_shapes(game)
			seen[expected_shapes[cycle]] = shapes.has(expected_shapes[cycle])
		for shape in expected_shapes:
			passed = _assert_true(bool(seen.get(shape, false)), "Flandre skill cycle should emit dedicated effect shape %s" % shape) and passed
	_free_game(game)
	return passed


func _test_flandre_phase_shift_uses_dedicated_destroyer_field_effect() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_trigger_flandre_boss_phase_shift"), "expected dedicated Flandre phase shift handler to exist")
	if passed:
		var boss := {
			"kind": "flandre_boss",
			"row": 2,
			"x": game.BOARD_ORIGIN.x + game.board_size.x - 20.0,
			"boss_phase": 1,
			"max_health": 24800.0,
			"health": 18000.0,
		}
		game.call("_trigger_flandre_boss_phase_shift", boss, 1)
		var shapes = _effect_shapes(game)
		passed = _assert_true(shapes.has("flandre_destroyer_field"), "Flandre phase shift should create a dedicated destroyer field effect") and passed
		passed = _assert_true(shapes.has("flandre_phase_wings"), "Flandre phase shift should create a dedicated wing burst effect") and passed
	_free_game(game)
	return passed
