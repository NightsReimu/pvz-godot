extends "res://scripts/game.gd"

var legacy_food_path := false

func _plant_food_uses_click_ultimate(kind: String) -> bool:
	return false if legacy_food_path else super._plant_food_uses_click_ultimate(kind)

# Native damage/collision fixture: UI/save callbacks are suppressed.
# The optional legacy-food flag selects the retained native activation branch;
# damage, charge, collisions, equipment and difficulty are never overridden.
func _ready() -> void: pass
func _show_banner(_text: String, _duration: float = 2.0) -> void: pass
func _show_toast(_text: String) -> void: pass
func _save_game() -> void: pass

func configure(kind: String = "cirno_boss", choice: String = "easy") -> void:
	size=Vector2(1600,900)
	current_level = {"id":"damage-contract","terrain":"day","events":[{"kind":kind,"time":100.0}],"touhou_difficulty":choice}
	active_rows = [0,1,2,3,4,5]
	water_rows = []
	board_size = CELL_SIZE * Vector2(9,6)
	grid = []; support_grid = []; zombies = []; projectiles = []; effects = []
	mowers = []
	for row in range(6):
		var cells: Array = []; cells.resize(9)
		grid.append(cells); support_grid.append(cells.duplicate())
		mowers.append({"row":row,"x":BOARD_ORIGIN.x-56.0,"armed":true,"active":false})
	rng.seed = 178
	level_time = 100.0

func add_plant(row: int = 2, col: int = 4, armor: float = 5.0) -> Dictionary:
	var p: Dictionary = _create_plant("wallnut",row,col)
	p.armor_health = armor; p.max_armor_health = armor
	grid[row][col] = p
	return p

func add_boss(kind: String, row: int = 2, col: int = 8) -> Dictionary:
	_spawn_zombie_at(kind,row,_cell_center(row,col).x,true)
	return zombies.back()

func vitality(p: Dictionary) -> float:
	return maxf(0.0,float(p.health))+maxf(0.0,float(p.get("armor_health",0.0)))
