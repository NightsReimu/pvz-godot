extends SceneTree

const Game = preload("res://scripts/game.gd")
var failures := 0

class CollisionGame extends Game:
	var hit_log: Array = []
	func _damage_plant_cell(row: int, col: int, _damage: float, _extra: float = 0, _scaled: bool = false) -> bool:
		hit_log.append(Vector2i(row, col))
		return true

# Frozen pre-change broad phase, for a reproducible comparison with 4f0ba43.
class Previous extends Game.TouhouDanmakuRuntime:
	func _hit_plant_segment(from: Vector2, to: Vector2, radius: float, damage: float, hit_cells: Array, stop_at_first: bool = true) -> bool:
		var nearest := Vector2i(-1, -1)
		var distance := INF
		# Most bullets travel only a few pixels per tick. Restrict collision checks to
		# cells intersecting the swept segment instead of scanning the whole board.
		var padding := radius + minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 0.22
		var min_x := minf(from.x, to.x) - padding
		var max_x := maxf(from.x, to.x) + padding
		var min_y := minf(from.y, to.y) - padding
		var max_y := maxf(from.y, to.y) + padding
		var min_col := clampi(int(floor((min_x - game.BOARD_ORIGIN.x) / game.CELL_SIZE.x)), 0, game.COLS - 1)
		var max_col := clampi(int(floor((max_x - game.BOARD_ORIGIN.x) / game.CELL_SIZE.x)), 0, game.COLS - 1)
		var min_row := clampi(int(floor((min_y - game.BOARD_ORIGIN.y) / game.CELL_SIZE.y)), 0, game.ROWS - 1)
		var max_row := clampi(int(floor((max_y - game.BOARD_ORIGIN.y) / game.CELL_SIZE.y)), 0, game.ROWS - 1)
		for row in range(min_row, max_row + 1):
			if not game._is_row_active(row):
				continue
			for col in range(min_col, max_col + 1):
				var cell := Vector2i(int(row), col)
				if hit_cells.has(cell):
					continue
				var plant = game._targetable_plant_at(cell.x, cell.y)
				if plant == null or float(plant.get("health", 0.0)) <= 0.0:
					continue
				var center: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, -12)
				var closest = Geometry2D.get_closest_point_to_segment(center, from, to)
				if closest.distance_squared_to(center) > padding * padding:
					continue
				if not stop_at_first:
					game._damage_plant_cell(cell.x, cell.y, damage, 0.0, true)
					hit_cells.append(cell)
				elif from.distance_squared_to(center) < distance:
					distance = from.distance_squared_to(center)
					nearest = cell
		if nearest.x >= 0:
			game._damage_plant_cell(nearest.x, nearest.y, damage, 0.0, true)
			return true
		return not hit_cells.is_empty()

class BruteForce extends Game.TouhouDanmakuRuntime:
	func _hit_plant_segment(from: Vector2, to: Vector2, radius: float, damage: float, hit_cells: Array, stop_at_first: bool = true) -> bool:
		var nearest := Vector2i(-1, -1)
		var distance := INF
		# Most bullets travel only a few pixels per tick. Restrict collision checks to
		# cells intersecting the swept segment instead of scanning the whole board.
		var padding := radius + minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 0.22
		for row in range(game.ROWS):
			if not game._is_row_active(row):
				continue
			for col in range(game.COLS):
				var cell := Vector2i(int(row), col)
				if hit_cells.has(cell):
					continue
				var plant = game._targetable_plant_at(cell.x, cell.y)
				if plant == null or float(plant.get("health", 0.0)) <= 0.0:
					continue
				var center: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, -12)
				var closest = Geometry2D.get_closest_point_to_segment(center, from, to)
				if closest.distance_squared_to(center) > padding * padding:
					continue
				if not stop_at_first:
					game._damage_plant_cell(cell.x, cell.y, damage, 0.0, true)
					hit_cells.append(cell)
				elif from.distance_squared_to(center) < distance:
					distance = from.distance_squared_to(center)
					nearest = cell
		if nearest.x >= 0:
			game._damage_plant_cell(nearest.x, nearest.y, damage, 0.0, true)
			return true
		return not hit_cells.is_empty()

func _initialize() -> void:
	var game := CollisionGame.new()
	game.active_rows = [0, 1, 2, 3, 4, 5]
	for row in range(6):
		var cells: Array = []
		cells.resize(9)
		game.grid.append(cells)
		game.support_grid.append(cells.duplicate())
	var rng := RandomNumberGenerator.new()
	rng.seed = 322055
	var current := Game.TouhouDanmakuRuntime.new(game)
	var reference := BruteForce.new(game)
	var previous := Previous.new(game)
	for dimensions in [Vector2(135, 110), Vector2(76, 33), Vector2(52, 20)]:
		game.CELL_SIZE = dimensions
		game.BOARD_ORIGIN = Vector2(37, 129)
		game.board_size = dimensions * Vector2(9, 6)
		for row in range(6):
			for col in range(9):
				game.grid[row][col] = {"health": 100} if rng.randf() < 0.65 else null
		for case in range(3000):
			var from := game.BOARD_ORIGIN + Vector2(rng.randf_range(-80, game.board_size.x + 80), rng.randf_range(-80, game.board_size.y + 80))
			var to := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0, 900 if case % 5 == 0 else 20)
			var radius := rng.randf_range(1, 25)
			var first := case % 2 == 0
			var exclusions: Array = [Vector2i(case % 6, case % 9)]
			game.hit_log.clear()
			reference._hit_plant_segment(from, to, radius, 1, exclusions.duplicate(), first)
			var expected := game.hit_log.duplicate()
			game.hit_log.clear()
			current._hit_plant_segment(from, to, radius, 1, exclusions.duplicate(), first)
			if game.hit_log != expected:
				failures += 1
				push_error("Broad phase differs from brute force at %s, case %d" % [dimensions, case])
	print("Swept collision: 9,000 random cases across desktop and short six-row boards: %d failure(s)" % failures)
	game.CELL_SIZE = Vector2(135, 110)
	game.board_size = game.CELL_SIZE * Vector2(9, 6)
	for row in range(6):
		for col in range(9):
			game.grid[row][col] = {"health": 100}
	var shots: Array = []
	for index in range(480):
		var from := game.BOARD_ORIGIN + Vector2(rng.randf_range(-40, game.board_size.x + 40), rng.randf_range(-40, game.board_size.y + 40))
		shots.append([from, from + Vector2.from_angle(rng.randf() * TAU) * 4, 6.0])
	var readings := {"previous": [], "current": []}
	for trial in range(7):
		for key in (["current", "previous"] if trial % 2 else ["previous", "current"]):
			var runtime = current if key == "current" else previous
			var start := Time.get_ticks_usec()
			for frame in range(120):
				for shot in shots:
					runtime._hit_plant_segment(shot[0], shot[1], shot[2], 1, [])
				game.hit_log.clear()
			readings[key].append((Time.get_ticks_usec() - start) / 120.0 / 1000.0)
	for key in readings:
		readings[key].sort()
	print("Collision benchmark (480 segments / full 54-cell board / 120 frames / median 7 alternating trials): previous %.3f ms, current %.3f ms, %.1f%% less CPU time" % [readings.previous[3], readings.current[3], (1.0 - readings.current[3] / readings.previous[3]) * 100])
	game.save_dirty = false
	game.free()
	quit(1 if failures else 0)
