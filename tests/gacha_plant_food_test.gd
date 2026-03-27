extends SceneTree

const GameScript = preload("res://scripts/game.gd")

const GACHA_PLANTS = [
	"shadow_pea",
	"ice_queen",
	"vine_emperor",
	"soul_flower",
	"plasma_shooter",
	"crystal_nut",
	"dragon_fruit",
	"time_rose",
	"galaxy_sunflower",
	"void_shroom",
	"phoenix_tree",
	"thunder_god",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_every_gacha_plant_can_activate_plant_food() or failed
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
	game.current_level = {"id": "test", "terrain": "day", "events": [], "title": "test", "description": ""}
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


func _spawn_target(game: Control, row: int, col: int) -> void:
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, col).x + 84.0)


func _test_every_gacha_plant_can_activate_plant_food() -> bool:
	var passed := true
	for kind in GACHA_PLANTS:
		var game := _make_game()
		var row := 2
		var col := 2
		var plant = game.call("_create_plant", kind, row, col)
		game.grid[row][col] = plant
		_spawn_target(game, row, col)
		var activated = bool(game.call("_activate_plant_food", row, col))
		passed = _assert_true(activated, "%s should activate a plant food power instead of failing silently" % kind) and passed
		_free_game(game)
	return passed
