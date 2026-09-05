extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_flandre_skill_cycle_uses_ten_distinct_patterns() or failed
	failed = not _test_flandre_declarations_allow_reaction_before_damage() or failed
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


func _test_flandre_skill_cycle_uses_ten_distinct_patterns() -> bool:
	var game = _make_game()
	var expected_shapes = [
		"cranberry", "laevatein", "four_of_a_kind", "kagome", "maze",
		"starbow", "catadioptric", "past_clock", "and_then_none", "qed",
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
			seen[expected_shapes[cycle]] = String(game.touhou_danmaku.casts.back().pattern) == expected_shapes[cycle] and (not game.touhou_danmaku.bullets.is_empty() or not game.touhou_danmaku.beams.is_empty())
		for shape in expected_shapes:
			passed = _assert_true(bool(seen.get(shape, false)), "Flandre skill cycle should emit dedicated effect shape %s" % shape) and passed
	_free_game(game)
	return passed


func _flandre_damage_for_cycle(cycle: int, row: int, col: int) -> float:
	var game = _make_game()
	game.rng.seed = 20260621
	game.grid[row][col] = game._create_plant("wallnut", row, col)
	var before = float(game.grid[row][col]["health"])
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
	var damage = before - float(game.grid[row][col]["health"])
	_free_game(game)
	return damage


func _test_flandre_declarations_allow_reaction_before_damage() -> bool:
	var passed = _assert_true(absf(_flandre_damage_for_cycle(1, 2, 3)) <= 0.01, "Laevatein must show a laser warning before impact") \
		and _assert_true(absf(_flandre_damage_for_cycle(3, 2, 3)) <= 0.01, "Kagome must emit moving bullets before impact") \
		and _assert_true(absf(_flandre_damage_for_cycle(9, 2, 2)) <= 0.01, "QED must emit expanding rings before impact")
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
