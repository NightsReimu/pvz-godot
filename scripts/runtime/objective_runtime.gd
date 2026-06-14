extends RefCounted
class_name ObjectiveRuntime

# PvZ2-style challenge objectives for branch levels. Pure logic, no draw_* calls
# (the HUD chip lives in game.gd). Follows the same owner-Control pattern as the
# other runtime modules: reads/writes game fields directly.
#
# Objective types (level "objective" dict, "type" field):
#   protect_plants  — pre-place endangered plants; fail if too many die.
#   no_mower        — fail if any lawn mower triggers.
#   max_plant_loss  — fail if more than N plants are lost.
#   column_defense  — fail if any enemy zombie crosses the guard column.
#   time_limit      — win once the player survives until the time limit.
#   sun_budget      — economic constraint (fixed start sun, no sky sun); win by
#                     surviving all waves. No fail condition of its own.
# Levels without an "objective" dict are unaffected (active stays false).

var game: Control
var objective: Dictionary = {}
var active: bool = false
var endangered_expected: int = 0
var endangered_lost: int = 0
var plants_lost: int = 0
var mowers_used: int = 0
var start_time: float = 0.0


func _init(game_owner: Control) -> void:
	game = game_owner


func setup(level: Dictionary) -> void:
	objective = level.get("objective", {}) if level != null else {}
	active = not objective.is_empty()
	endangered_lost = 0
	plants_lost = 0
	mowers_used = 0
	start_time = float(game.level_time)
	endangered_expected = 0
	if not active:
		return
	# Pre-place endangered plants (Save Our Seeds). Marked so their death is tracked.
	for entry in objective.get("preplaced", []):
		var kind := String(entry.get("kind", ""))
		var row := int(entry.get("row", 0))
		var col := int(entry.get("col", 0))
		if kind == "" or row < 0 or row >= game.ROWS or col < 0 or col >= game.COLS:
			continue
		var plant = game._create_plant(kind, row, col)
		if plant == null:
			continue
		plant["endangered"] = true
		game.grid[row][col] = plant
		endangered_expected += 1


func notify_plant_removed(plant) -> void:
	if not active or plant == null:
		return
	if bool(plant.get("endangered", false)):
		endangered_lost += 1
	plants_lost += 1


func notify_mower_activated() -> void:
	if active:
		mowers_used += 1


func fail_check() -> String:
	# Returns a localized failure reason, or "" when the objective still holds.
	if not active:
		return ""
	var type := String(objective.get("type", ""))
	match type:
		"protect_plants":
			if endangered_lost > int(objective.get("max_loss", 0)):
				return "被保护的植物被摧毁了！"
		"no_mower":
			if mowers_used > 0:
				return "除草机被触发，防线失守！"
		"max_plant_loss":
			if plants_lost > int(objective.get("max_loss", 0)):
				return "损失植物过多（已损失 %d 株）！" % plants_lost
		"column_defense":
			var guard_x := float(game.BOARD_ORIGIN.x) + float(int(objective.get("guard_column", 0))) * float(game.CELL_SIZE.x)
			for zombie in game.zombies:
				if not game._is_enemy_zombie(zombie):
					continue
				if float(zombie.get("x", 999999.0)) < guard_x:
					return "僵尸突破了第 %d 列防线！" % int(objective.get("guard_column", 0))
	return ""


func win_check() -> bool:
	# Only time_limit grants an early win; every other type wins by surviving all
	# waves (handled by game._can_finish_level_ignoring_obstacles).
	if not active:
		return false
	if String(objective.get("type", "")) == "time_limit":
		return float(game.level_time) - start_time >= float(objective.get("time_limit", 999999.0))
	return false


func status_text() -> Dictionary:
	# Feed for the in-battle objective HUD chip.
	if not active:
		return {"label": "", "progress": "", "danger": false}
	var title := String(objective.get("title", "挑战"))
	var type := String(objective.get("type", ""))
	match type:
		"protect_plants":
			var alive := maxi(0, endangered_expected - endangered_lost)
			return {"label": title, "progress": "存活 %d/%d" % [alive, endangered_expected], "danger": endangered_lost > 0}
		"no_mower":
			return {"label": title, "progress": "除草机 %d" % mowers_used, "danger": mowers_used > 0}
		"max_plant_loss":
			var max_l := int(objective.get("max_loss", 0))
			return {"label": title, "progress": "损失 %d/%d" % [plants_lost, max_l], "danger": plants_lost >= max_l}
		"column_defense":
			return {"label": title, "progress": "守住第 %d 列" % int(objective.get("guard_column", 0)), "danger": false}
		"time_limit":
			var remain := maxf(0.0, float(objective.get("time_limit", 0.0)) - (float(game.level_time) - start_time))
			return {"label": title, "progress": "剩余 %ds" % int(ceil(remain)), "danger": remain < 10.0}
		"sun_budget":
			return {"label": title, "progress": "阳光 %d" % int(game.sun_points), "danger": int(game.sun_points) < 100}
	return {"label": title, "progress": "", "danger": false}
