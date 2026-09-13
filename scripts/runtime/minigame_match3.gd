extends RefCounted

const KINDS := ["peashooter", "snow_pea", "repeater", "wallnut", "starfruit"]
const HEIGHT := 5
const WIDTH := 8
const TARGET := 50
var game: Control
var selected := Vector2i(-1,-1)
var hint: Array = []
var pending: Array = []
var timer := 0.0
var idle := 0.0
var score := 0
var combo := 0

func _init(owner_game: Control) -> void:
	game = owner_game
	fill_board()

func valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < HEIGHT and cell.y >= 0 and cell.y < WIDTH

func kind(cell: Vector2i) -> String:
	if not valid(cell) or game.grid[cell.x][cell.y] == null: return ""
	return String(game.grid[cell.x][cell.y].kind)

func refill(cell: Vector2i) -> void:
	game.grid[cell.x][cell.y] = game._create_plant(KINDS[game.rng.randi_range(0,KINDS.size()-1)],cell.x,cell.y)

func fill_board() -> void:
	# Bounded rejection; each cell has at least three legal plant choices.
	for row in range(HEIGHT):
		for col in range(WIDTH):
			var allowed := KINDS.duplicate()
			if col >= 2 and kind(Vector2i(row,col-1)) == kind(Vector2i(row,col-2)): allowed.erase(kind(Vector2i(row,col-1)))
			if row >= 2 and kind(Vector2i(row-1,col)) == kind(Vector2i(row-2,col)): allowed.erase(kind(Vector2i(row-1,col)))
			game.grid[row][col] = game._create_plant(allowed[game.rng.randi_range(0,allowed.size()-1)],row,col)
	ensure_move()

func groups() -> Array:
	var found: Array = []
	for axis in range(2):
		for line in range(HEIGHT if axis == 0 else WIDTH):
			var run: Array = []
			var previous := ""
			for offset in range((WIDTH if axis == 0 else HEIGHT) + 1):
				var cell := Vector2i(line,offset) if axis == 0 else Vector2i(offset,line)
				var current := kind(cell)
				if current != previous or current == "":
					if run.size() >= 3: found.append(run.duplicate())
					run.clear()
				run.append(cell)
				previous = current
	return found

func exchange(a: Vector2i, b: Vector2i) -> void:
	var old = game.grid[a.x][a.y]
	game.grid[a.x][a.y] = game.grid[b.x][b.y]
	game.grid[b.x][b.y] = old
	for cell in [a,b]:
		if game.grid[cell.x][cell.y] != null:
			game.grid[cell.x][cell.y].row = cell.x
			game.grid[cell.x][cell.y].col = cell.y

func find_move() -> Array:
	for row in range(HEIGHT):
		for col in range(WIDTH):
			var a := Vector2i(row,col)
			for offset in [Vector2i(1,0),Vector2i(0,1)]:
				var b: Vector2i = a + offset
				if not valid(b) or kind(a) == "" or kind(b) == "" or kind(a) == kind(b): continue
				exchange(a,b)
				var matched := not groups().is_empty()
				exchange(a,b)
				if matched: return [a,b]
	return []

func ensure_move() -> void:
	if not find_move().is_empty(): return
	# Install a known A B A / C A C move, avoiding unbounded random reshuffles.
	var pattern := [["peashooter","snow_pea","peashooter"],["wallnut","peashooter","wallnut"]]
	for row in range(2):
		for col in range(3):
			game.grid[row][col] = game._create_plant(pattern[row][col],row,col)
	game._show_toast("没有可交换组合，已补入一组新苗")

func click(cell: Vector2i) -> void:
	if not valid(cell) or not pending.is_empty(): return
	if selected == cell:
		selected = Vector2i(-1,-1)
		return
	if not valid(selected) or absi(cell.x-selected.x)+absi(cell.y-selected.y) != 1:
		selected = cell
		return
	var a := selected
	selected = Vector2i(-1,-1)
	hint.clear()
	idle = 0
	exchange(a,cell)
	pending = groups()
	if pending.is_empty():
		exchange(a,cell)
		game._show_toast("交换后需要三个同类成线")
		return
	for destination in [a,cell]:
		var plant = game.grid[destination.x][destination.y]
		plant.mini_swap_from = cell if destination == a else a
		plant.mini_swap_time = game.level_time
	combo = 0
	timer = 0.28

func update(delta: float) -> void:
	idle += delta
	if not pending.is_empty():
		timer -= delta
		if timer > 0: return
		var cleared := {}
		for group in pending:
			for cell in group: cleared[cell] = true
		score += pending.size()
		combo += 1
		for cell in cleared:
			game.effects.append({"position":game._cell_center(cell.x,cell.y), "radius":game.CELL_SIZE.x*0.48, "time":0.4, "duration":0.4, "color":Color(0.8,0.95,0.45,0.6)})
			refill(cell)
		pending = groups() if combo < 12 else []
		timer = 0.32
		if pending.is_empty():
			# Prevent accidental matches from the capped cascade from granting free swaps.
			if combo >= 12: fill_board()
			ensure_move()
		return
	var holes := false
	for row in range(HEIGHT):
		for col in range(WIDTH):
			if game.grid[row][col] == null or float(game.grid[row][col].health) <= 0:
				refill(Vector2i(row,col))
				holes = true
	if holes:
		pending = groups()
		timer = 0.3
		ensure_move()
	if idle > 6 and hint.is_empty(): hint = find_move()
