extends SceneTree
const Game = preload("res://scripts/game.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	for scale in [1.0, 0.5]:
		var game := Game.new()
		game.CELL_SIZE = game.BASE_CELL_SIZE * scale
		game.current_level = {"id":"square-test", "terrain":"day", "events":[]}
		game.board_rows = 5
		game.board_size = Vector2(9,5) * game.CELL_SIZE
		game.active_rows = [0,1,2,3,4]
		game.toast_label = Label.new()
		for row in range(6):
			var cells: Array = []
			cells.resize(9)
			game.grid.append(cells)
			game.support_grid.append(cells.duplicate())
		var center := game._cell_center(2,4)
		game._spawn_zombie_at("normal",0,game._cell_center(0,2).x)
		game._spawn_zombie_at("normal",0,game._cell_center(0,1).x)
		var plant := game._create_plant("pulse_bulb",2,4)
		plant.pulse_timer = 0
		game.weeds = [{"x":game._cell_center(0,2).x,"row":0,"health":100.0}]
		var before := float(game.zombies[0].health)
		var outside := float(game.zombies[1].health)
		game._update_pulse_bulb(plant,.1,2,4)
		check(float(game.zombies[0].health)<before and float(game.zombies[1].health)==outside,"Pulse must hit its square corners and exclude the adjacent sixth cell")
		check(float(game.weeds[0].health)<100,"Obstacles at square corners must match the damage footprint")
		var area: Rect2 = game.effects.back().get("area_rect",Rect2())
		check(area.size.is_equal_approx(game.CELL_SIZE*5) and area.get_center().is_equal_approx(center),"Displayed pulse footprint must be the actual five-cell area, including non-square cell dimensions")
		game.zombies.clear()
		game._spawn_zombie_at("normal",2,game.BOARD_ORIGIN.x + game.board_size.x + 800)
		before = game.zombies[0].health
		game._damage_zombies_in_square(2,8,3,10)
		check(float(game.zombies[0].health)==before,"Off-board enemies cannot be clamped into an edge tile and hit from arbitrary distances")
		game.toast_label.free()
		game.free()
	print("Square area boundaries, obstacles and visuals at two scales: %d failures" % failures)
	quit(1 if failures else 0)
