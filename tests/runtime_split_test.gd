extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const GameDefs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_split_data_modules_exist_and_match_game_defs() or failed
	failed = not _test_plant_food_runtime_covers_every_plant_kind() or failed
	failed = not _test_plant_update_runtime_exists_and_exposes_core_entrypoints() or failed
	failed = not _test_projectile_runtime_exists_and_exposes_core_entrypoints() or failed
	failed = not _test_every_defined_plant_supports_click_ultimate() or failed
	failed = not _test_every_defined_plant_can_trigger_plant_food_in_a_valid_scenario() or failed
	failed = not _test_bowling_plant_food_click_path_allows_empty_lane_activation() or failed
	failed = not _test_legacy_plants_can_charge_and_activate_click_ultimates() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_grid() -> Array:
	var result: Array = []
	for _row in range(6):
		var row_data: Array = []
		for _col in range(9):
			row_data.append(null)
		result.append(row_data)
	return result


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "1-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
	game.grid = _make_grid()
	game.support_grid = _make_grid()
	game.zombies = []
	game.weeds = []
	game.spears = []
	game.effects = []
	game.graves = []
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


func _plant_food_expected_kinds() -> Array:
	var result: Array = []
	for kind in GameDefs.PLANTS.keys():
		result.append(String(kind))
	result.sort()
	return result


func _test_split_data_modules_exist_and_match_game_defs() -> bool:
	var plant_defs = load("res://scripts/data/plant_defs.gd")
	var zombie_defs = load("res://scripts/data/zombie_defs.gd")
	var level_defs = load("res://scripts/data/level_defs.gd")
	var passed = _assert_true(plant_defs != null, "expected plant definition data to live in scripts/data/plant_defs.gd") \
		and _assert_true(zombie_defs != null, "expected zombie definition data to live in scripts/data/zombie_defs.gd") \
		and _assert_true(level_defs != null, "expected level definition data to live in scripts/data/level_defs.gd")
	if not passed:
		return false
	passed = _assert_true(GameDefs.PLANT_ORDER == plant_defs.ORDER, "GameDefs.PLANT_ORDER should be sourced from the split plant data module") and passed
	passed = _assert_true(GameDefs.PLANTS == plant_defs.PLANTS, "GameDefs.PLANTS should be sourced from the split plant data module") and passed
	passed = _assert_true(GameDefs.ZOMBIES == zombie_defs.ZOMBIES, "GameDefs.ZOMBIES should be sourced from the split zombie data module") and passed
	passed = _assert_true(GameDefs.LEVELS == level_defs.LEVELS, "GameDefs.LEVELS should be sourced from the split level data module") and passed
	return passed


func _test_plant_food_runtime_covers_every_plant_kind() -> bool:
	var runtime_script = load("res://scripts/runtime/plant_food_runtime.gd")
	if not _assert_true(runtime_script != null, "expected plant food runtime module to exist at scripts/runtime/plant_food_runtime.gd"):
		return false
	var expected = _plant_food_expected_kinds()
	var actual: Array = []
	if runtime_script.get_script_constant_map().has("SUPPORTED_KINDS"):
		actual = runtime_script.SUPPORTED_KINDS
	else:
		var runtime = runtime_script.new(_make_game())
		if runtime.has_method("supported_kinds"):
			actual = runtime.supported_kinds()
	var passed = _assert_true(not actual.is_empty(), "plant food runtime should expose a supported kind list")
	if not passed:
		return false
	var expected_sorted = expected.duplicate()
	var actual_sorted = actual.duplicate()
	expected_sorted.sort()
	actual_sorted.sort()
	return _assert_true(actual_sorted == expected_sorted, "plant food runtime should explicitly cover every defined plant kind")


func _test_plant_update_runtime_exists_and_exposes_core_entrypoints() -> bool:
	var runtime_script = load("res://scripts/runtime/plant_runtime.gd")
	var passed = _assert_true(runtime_script != null, "expected plant update runtime module to exist at scripts/runtime/plant_runtime.gd")
	if not passed:
		return false
	var runtime = runtime_script.new(_make_game())
	passed = _assert_true(runtime.has_method("update_plants"), "plant update runtime should expose the main update_plants entrypoint") and passed
	passed = _assert_true(runtime.has_method("update_threepeater"), "plant update runtime should expose threepeater updates for direct tests") and passed
	passed = _assert_true(runtime.has_method("update_fume_shroom"), "plant update runtime should expose fume shroom updates for direct tests") and passed
	passed = _assert_true(runtime.has_method("update_wind_orchid"), "plant update runtime should expose wind orchid updates for direct tests") and passed
	return passed


func _test_projectile_runtime_exists_and_exposes_core_entrypoints() -> bool:
	var runtime_script = load("res://scripts/runtime/projectile_runtime.gd")
	var passed = _assert_true(runtime_script != null, "expected projectile runtime module to exist at scripts/runtime/projectile_runtime.gd")
	if not passed:
		return false
	var runtime = runtime_script.new(_make_game())
	passed = _assert_true(runtime.has_method("spawn_projectile"), "projectile runtime should expose spawn_projectile") and passed
	passed = _assert_true(runtime.has_method("update_projectiles"), "projectile runtime should expose update_projectiles") and passed
	passed = _assert_true(runtime.has_method("update_rollers"), "projectile runtime should expose update_rollers") and passed
	passed = _assert_true(runtime.has_method("update_boomerang_projectile"), "projectile runtime should expose boomerang updates for direct tests") and passed
	return passed


func _prepare_scenario(game: Control, kind: String, row: int, col: int) -> void:
	if kind == "wallnut_bowling":
		game.current_level = {"id": "1-10", "terrain": "day", "mode": "bowling", "events": [], "available_plants": ["wallnut_bowling"]}
		return
	if kind == "lily_pad" or kind == "sea_shroom" or kind == "tangle_kelp":
		game.current_level["terrain"] = "pool"
		game.water_rows = [row]
	if kind == "grave_buster":
		game.graves.append({"row": row, "col": col})
	if kind == "squash" or kind == "hypno_shroom" or kind == "tangle_kelp" or kind == "root_snare":
		game._spawn_zombie_at("normal", row, game._cell_center(row, col).x + 84.0)


func _place_plant(game: Control, kind: String, row: int, col: int) -> void:
	if kind == "wallnut_bowling":
		return
	var plant = game._create_plant(kind, row, col)
	if kind == "lily_pad":
		game.support_grid[row][col] = plant
		return
	game.grid[row][col] = plant


func _test_every_defined_plant_can_trigger_plant_food_in_a_valid_scenario() -> bool:
	var passed := true
	for kind in _plant_food_expected_kinds():
		var game = _make_game()
		var row := 2
		var col := 2
		_prepare_scenario(game, kind, row, col)
		_place_plant(game, kind, row, col)
		var activated = bool(game._activate_plant_food(row, col))
		passed = _assert_true(activated, "%s should activate plant food in a valid scenario" % kind) and passed
		if kind == "wallnut_bowling":
			passed = _assert_true(game.rollers.size() == 1, "wallnut_bowling plant food should spawn a roller immediately") and passed
			if game.rollers.size() == 1:
				passed = _assert_true(bool(game.rollers[0].get("empowered", false)), "wallnut_bowling plant food should spawn an empowered roller") and passed
				passed = _assert_true(float(game.rollers[0].get("damage", 0.0)) > float(GameDefs.PLANTS["wallnut_bowling"]["damage"]), "wallnut_bowling plant food should boost roller damage") and passed
				passed = _assert_true(int(game.rollers[0].get("hits_left", 0)) > 4, "wallnut_bowling plant food should boost roller endurance") and passed
		_free_game(game)
	return passed


func _test_bowling_plant_food_click_path_allows_empty_lane_activation() -> bool:
	var game = _make_game()
	game.current_level = {"id": "1-10", "terrain": "day", "mode": "bowling", "events": [], "available_plants": ["wallnut_bowling"]}
	game.selected_tool = "plant_food"
	game.plant_food_count = 1
	game._handle_board_click(Vector2i(2, 3))
	var passed = _assert_true(game.rollers.size() == 1, "bowling levels should allow plant food on an empty lane tile to spawn a roller") \
		and _assert_true(game.plant_food_count == 0, "bowling lane activation should consume one plant food") \
		and _assert_true(String(game.selected_tool) == "", "bowling lane activation should clear the selected tool")
	if passed and game.rollers.size() == 1:
		passed = _assert_true(bool(game.rollers[0].get("empowered", false)), "bowling lane click activation should spawn an empowered roller") and passed
		passed = _assert_true(float(game.rollers[0].get("damage", 0.0)) > float(GameDefs.PLANTS["wallnut_bowling"]["damage"]), "bowling lane click activation should use the empowered damage profile") and passed
	_free_game(game)
	return passed


func _test_every_defined_plant_supports_click_ultimate() -> bool:
	var game = _make_game()
	var passed = _assert_true(game.has_method("_plant_supports_click_ultimate"), "game should expose a click-ultimate capability helper")
	if not passed:
		_free_game(game)
		return false
	for kind in _plant_food_expected_kinds():
		passed = _assert_true(bool(game.call("_plant_supports_click_ultimate", kind)), "%s should expose a click ultimate profile" % kind) and passed
	_free_game(game)
	return passed


func _test_legacy_plants_can_charge_and_activate_click_ultimates() -> bool:
	var passed := true
	var scenarios = [
		{"kind": "peashooter", "terrain": "day", "row": 2, "col": 2, "support": "", "expect_projectiles": true},
		{"kind": "sunflower", "terrain": "day", "row": 2, "col": 2, "support": "", "expect_suns": true},
		{"kind": "lily_pad", "terrain": "pool", "row": 2, "col": 2, "support": "support_only", "expect_effects": true},
	]
	for scenario_variant in scenarios:
		var scenario = Dictionary(scenario_variant)
		var game = _make_game()
		var row = int(scenario["row"])
		var col = int(scenario["col"])
		if String(scenario["terrain"]) == "pool":
			game.current_level["terrain"] = "pool"
			game.water_rows = [row]
		if String(scenario.get("support", "")) == "support_only":
			game.support_grid[row][col] = game._create_plant(String(scenario["kind"]), row, col)
		else:
			game.grid[row][col] = game._create_plant(String(scenario["kind"]), row, col)
			if bool(scenario.get("expect_projectiles", false)):
				game._spawn_zombie_at("normal", row, game._cell_center(row, col).x + 92.0)
		game.call("_update_ultimate_charges", 999.0)
		var targetable = game._targetable_plant_at(row, col)
		passed = _assert_true(targetable != null and float(targetable.get("ultimate_charge", 0.0)) >= 1.0, "%s should accumulate click-ultimate charge even without explicit plant defs fields" % String(scenario["kind"])) and passed
		var activated = bool(game.call("_try_activate_ultimate", row, col))
		passed = _assert_true(activated, "%s should activate its click ultimate when fully charged" % String(scenario["kind"])) and passed
		if bool(scenario.get("expect_projectiles", false)):
			passed = _assert_true(game.projectiles.size() > 0 or game.effects.size() > 0, "%s click ultimate should create an offensive effect" % String(scenario["kind"])) and passed
		if bool(scenario.get("expect_suns", false)):
			passed = _assert_true(game.suns.size() > 0, "%s click ultimate should create sun pickups" % String(scenario["kind"])) and passed
		if bool(scenario.get("expect_effects", false)):
			passed = _assert_true(game.effects.size() > 0, "%s click ultimate should create a visible support effect" % String(scenario["kind"])) and passed
		_free_game(game)
	return passed
