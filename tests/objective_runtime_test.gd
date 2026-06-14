extends SceneTree

# Unit tests for ObjectiveRuntime: setup, fail_check, win_check, status_text for
# each objective type. Spawns a minimal mock game Control to satisfy the runtime's
# owner dependency.

const ObjectiveRuntime = preload("res://scripts/runtime/objective_runtime.gd")

class MockGame extends Control:
	var level_time := 0.0
	var sun_points := 0
	var zombies := []
	var grid := []
	var support_grid := []
	const ROWS := 5
	const COLS := 9
	const BOARD_ORIGIN := Vector2(240.0, 80.0)
	const CELL_SIZE := Vector2(80.0, 96.0)
	func _init():
		for r in range(ROWS):
			grid.append([])
			support_grid.append([])
			for c in range(COLS):
				grid[r].append(null)
				support_grid[r].append(null)
	func _create_plant(kind: String, row: int, col: int) -> Dictionary:
		return {"kind": kind, "health": 300.0, "row": row, "col": col}
	func _is_enemy_zombie(z) -> bool:
		return bool(z.get("enemy", true))

func _initialize():
	print("objective_runtime_test start")
	var game = MockGame.new()
	var runtime = ObjectiveRuntime.new(game)

	# Test 1: protect_plants setup + fail on endangered death
	var level1 = {
		"objective": {
			"type": "protect_plants",
			"title": "保护向日葵",
			"preplaced": [
				{"kind": "sunflower", "row": 1, "col": 2},
				{"kind": "sunflower", "row": 2, "col": 3},
			],
			"max_loss": 0,
		}
	}
	runtime.setup(level1)
	assert(runtime.active, "protect_plants should be active")
	assert(runtime.endangered_expected == 2, "should preplace 2 endangered")
	assert(game.grid[1][2] != null, "sunflower at [1][2]")
	assert(bool(game.grid[1][2].get("endangered", false)), "should be marked endangered")
	var status = runtime.status_text()
	assert(status["label"] == "保护向日葵", "status label")
	assert(status["progress"].contains("2/2"), "progress shows 2/2")
	assert(status["danger"] == false, "no danger yet")
	assert(runtime.fail_check() == "", "no fail yet")
	runtime.notify_plant_removed(game.grid[1][2])
	assert(runtime.endangered_lost == 1, "lost one endangered")
	assert(runtime.fail_check() != "", "should fail after losing endangered")

	# Test 2: no_mower
	var level2 = {"objective": {"type": "no_mower", "title": "不丢除草机"}}
	runtime.setup(level2)
	assert(runtime.active, "no_mower active")
	assert(runtime.fail_check() == "", "no mower used yet")
	runtime.notify_mower_activated()
	assert(runtime.mowers_used == 1, "mower count")
	assert(runtime.fail_check() != "", "should fail after mower")

	# Test 3: column_defense (zombie breach)
	var level3 = {"objective": {"type": "column_defense", "title": "守住防线", "guard_column": 2}}
	runtime.setup(level3)
	game.zombies = [{"x": 400.0, "row": 1, "enemy": true}]
	assert(runtime.fail_check() == "", "zombie at x=400 (col 2+) is safe")
	game.zombies = [{"x": 250.0, "row": 1, "enemy": true}]  # just past BOARD_ORIGIN (240) + 2*80 = 400, so 250 < guard_x
	assert(runtime.fail_check() != "", "zombie at x=250 breaches col 2")

	# Test 4: max_plant_loss
	var level4 = {"objective": {"type": "max_plant_loss", "title": "植物学家", "max_loss": 2}}
	runtime.setup(level4)
	assert(runtime.fail_check() == "", "no plants lost")
	runtime.notify_plant_removed({"kind": "peashooter"})
	runtime.notify_plant_removed({"kind": "sunflower"})
	assert(runtime.plants_lost == 2, "lost 2")
	assert(runtime.fail_check() == "", "at limit, not over")
	runtime.notify_plant_removed({"kind": "wallnut"})
	assert(runtime.fail_check() != "", "over limit")

	# Test 5: time_limit win
	var level5 = {"objective": {"type": "time_limit", "title": "限时坚守", "time_limit": 60.0}}
	runtime.setup(level5)
	game.level_time = 30.0
	assert(runtime.win_check() == false, "30s not enough")
	game.level_time = runtime.start_time + 60.0
	assert(runtime.win_check() == true, "60s reached")

	# Test 6: sun_budget (no fail, just constraint)
	var level6 = {"objective": {"type": "sun_budget", "title": "最后防线"}}
	runtime.setup(level6)
	assert(runtime.active, "sun_budget active")
	assert(runtime.fail_check() == "", "sun_budget has no fail condition")
	game.sun_points = 50
	status = runtime.status_text()
	assert(status["progress"].contains("50"), "shows sun")

	# Test 7: no objective (inactive)
	runtime.setup({})
	assert(not runtime.active, "should be inactive")
	assert(runtime.fail_check() == "", "inactive never fails")
	runtime.notify_plant_removed({"kind": "x"})
	runtime.notify_mower_activated()
	assert(runtime.fail_check() == "", "inactive ignores notifications")

	print("objective_runtime_test PASS")
	quit(0)
