extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_sakuya_knife_skills_use_distinct_effect_shapes() or failed
	failed = not _test_remilia_skills_use_crimson_signature_effects() or failed
	failed = not _test_scarlet_clocktower_floor_is_tiled() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game(terrain: String = "scarlet_clocktower") -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "fx-test", "terrain": terrain, "events": []}
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


func _test_sakuya_knife_skills_use_distinct_effect_shapes() -> bool:
	var game = _make_game()
	var boss := {
		"kind": "sakuya_boss",
		"row": 2,
		"x": game.BOARD_ORIGIN.x + game.board_size.x - 20.0,
		"boss_phase": 1,
		"boss_skill_cycle": 0,
	}
	game.call("_trigger_sakuya_boss_skill", boss)
	boss["boss_skill_cycle"] = 1
	game.call("_trigger_sakuya_boss_skill", boss)
	var shapes = _effect_shapes(game)
	var passed = _assert_true(shapes.has("sakuya_knife_fan"), "Sakuya knife fan should use a dedicated fan-shaped knife effect") \
		and _assert_true(shapes.has("sakuya_knife_rain"), "Sakuya knife rain should use a dedicated falling knife effect")
	_free_game(game)
	return passed


func _test_remilia_skills_use_crimson_signature_effects() -> bool:
	var game = _make_game("blood_moon")
	var boss := {
		"kind": "remilia_boss",
		"row": 2,
		"x": game.BOARD_ORIGIN.x + game.board_size.x - 20.0,
		"boss_phase": 1,
		"boss_skill_cycle": 4,
		"max_health": 24000.0,
		"health": 24000.0,
	}
	game.call("_trigger_remilia_boss_skill", boss)
	game.call("_trigger_remilia_boss_phase_shift", boss, 1)
	var shapes = _effect_shapes(game)
	var passed = _assert_true(shapes.has("remilia_gungnir_lance"), "Remilia Gungnir should use a dedicated crimson lance effect") \
		and _assert_true(shapes.has("remilia_crimson_field"), "Remilia phase shift should create a dedicated crimson field effect")
	_free_game(game)
	return passed


func _test_scarlet_clocktower_floor_is_tiled() -> bool:
	var game = _make_game()
	var style = game.call("_scarlet_clocktower_floor_style")
	var passed = _assert_true(style is Dictionary, "clocktower floor style helper should return a dictionary") \
		and _assert_true(String(style.get("tile_mode", "")) == "ceramic", "clocktower floor should expose a ceramic tile mode") \
		and _assert_true(float(style.get("tile_inset", 0.0)) >= 8.0, "clocktower floor should use inset tiled borders")
	_free_game(game)
	return passed
