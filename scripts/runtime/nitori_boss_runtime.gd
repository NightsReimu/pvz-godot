extends RefCounted

const SpriteDefs = preload("res://scripts/data/nitori_sprite_defs.gd")
const KIND := "nitori_boss"
const CUCUMBER := "nitori_cucumber"
const WATER := Color("6fd3f2")
const DEEP := Color("2f8fc4")
const CUCUMBER_GREEN := Color("5fb04a")
const CAMO_FACTOR := 0.7
const POWER_FACTOR := 0.8
const SOAK_FACTOR := 0.7
const SOAK_DURATION := 6.0
const JET_WARNING := 1.4
const JET_SWEEP := 1.1
const CUCUMBER_WARNING := 1.2
const CUCUMBER_LIFETIME := 10.0
const CUCUMBER_REWARD := 15
const MAX_CUCUMBERS := 4
const MAX_JETS := 3
const MAX_SQUAD := 4
const POWER_DURATION := 6.0
# Rain smears the optical camouflage once a unit wades into the near half.
const CAMO_BREAK_COL := 4
const CAMO_PATTERNS := ["nitori_camo_squad", "nitori_workshop"]
const SQUAD_POOL := [
	["cone_kedama", "cone_star_fairy", "cone_umbrella_zombie"],
	["bucket_kedama", "cone_umbrella_zombie", "brick_ladder_zombie", "kabuto_star_fairy"],
	["brick_kedama", "bucket_umbrella_zombie", "kabuto_ninja", "brick_ladder_zombie", "bucket_star_fairy"],
]

var game: Control
var jets: Array[Dictionary] = []
var baits: Array[Dictionary] = []
var cucumbers: Array[Dictionary] = []
var soaked: Dictionary = {}
var serial := 0

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	jets.clear()
	baits.clear()
	cucumbers.clear()
	soaked.clear()
	serial = 0
	for z in game.zombies:
		if z.has("nitori_parent"):
			z["nitori_cleanup"] = true
			z.health = 0.0

func clear_owner(owner: int) -> void:
	jets = jets.filter(func(p): return int(p.owner) != owner)
	baits = baits.filter(func(p): return int(p.owner) != owner)
	cucumbers = cucumbers.filter(func(p): return int(p.owner) != owner)
	for z in game.zombies:
		if int(z.get("nitori_parent", -1)) == owner and String(z.kind) == CUCUMBER:
			z["nitori_cleanup"] = true
			z.health = 0.0

func boss_for(owner: int) -> Dictionary:
	for z in game.zombies:
		if int(z.uid) == owner and String(z.kind) == KIND and float(z.health) > 0.0: return z
	return {}

func _unit(uid: int) -> Dictionary:
	for z in game.zombies:
		if int(z.uid) == uid and float(z.health) > 0.0: return z
	return {}

func _rank() -> int:
	return int(game.TouhouDifficulty.profile(game.current_level).rank)

func _unit_size() -> float:
	return minf(game.CELL_SIZE.x, game.CELL_SIZE.y)

# --- Optical camouflage -----------------------------------------------------

func _reveals(plant) -> bool:
	if plant == null or float(plant.get("health", 0.0)) <= 0.0: return false
	if game._plant_has_component(plant, "plantern"): return true
	return "reveal" in game.Defs.PLANTS.get(String(plant.get("fusion_kind", "")), {}).get("fusion_traits", [])

func row_has_revealer(row: int) -> bool:
	if row < 0 or row >= game.ROWS: return false
	for col in range(game.COLS):
		if _reveals(game._top_plant_at(row, col)): return true
	return false

func boss_revealed(boss: Dictionary) -> bool:
	return float(boss.get("revealed_timer", 0.0)) > 0.0 or row_has_revealer(int(boss.get("row", -1)))

func boss_camouflaged(boss: Dictionary) -> bool:
	if String(boss.get("kind", "")) != KIND or float(boss.get("health", 0.0)) <= 0.0: return false
	if bool(boss.get("touhou_final_preview", false)): return true
	return float(boss.get("touhou_cast_remaining", 0.0)) > 0.0 and String(boss.get("touhou_card", {}).get("pattern", "")) in CAMO_PATTERNS

func is_camouflaged(z: Dictionary) -> bool:
	# Lane targeting only: projectiles already in flight still collide.
	if not bool(z.get("nitori_camo", false)) or float(z.get("health", 0.0)) <= 0.0: return false
	if float(z.get("revealed_timer", 0.0)) > 0.0 or bool(z.get("hypnotized", false)): return false
	var row := int(z.get("row", -1))
	if not game._is_row_active(row): return false
	if float(z.get("x", 0.0)) < game._cell_center(row, CAMO_BREAK_COL).x: return false
	if row_has_revealer(row): return false
	return not game._plantern_reveals_position(Vector2(float(z.x), game._row_center_y(row)))

func damage_factor(z: Dictionary) -> float:
	var factor := 1.0
	if boss_camouflaged(z) and not boss_revealed(z): factor *= CAMO_FACTOR
	if float(z.get("nitori_power_until", 0.0)) > float(game.level_time): factor *= POWER_FACTOR
	return factor

func on_damaged(z: Dictionary) -> void:
	# A hit disturbs the light-bending film briefly; the rule stays readable.
	if bool(z.get("nitori_camo", false)):
		z["revealed_timer"] = maxf(float(z.get("revealed_timer", 0.0)), 2.0)

# --- Soaked rows and water cannons -------------------------------------------

func action_factor(row: int, col: int) -> float:
	if float(soaked.get(Vector2i(row, col), 0.0)) <= 0.0: return 1.0
	var plant = game._targetable_plant_at(row, col)
	if plant != null and (float(plant.get("holy_invincible_timer", 0.0)) > 0.0 or bool(plant.get("ultimate_active", false))): return 1.0
	return SOAK_FACTOR

func doused(row: int, col: int) -> bool:
	return float(soaked.get(Vector2i(row, col), 0.0)) > 0.0

func cleanse_row(row: int) -> void:
	var before := soaked.size() + jets.size()
	for cell in soaked.keys():
		if Vector2i(cell).x == row: soaked.erase(cell)
	jets = jets.filter(func(p): return int(p.row) != row or float(p.age) >= float(p.delay) + JET_SWEEP)
	if soaked.size() + jets.size() < before:
		game._show_toast("本行积水与水炮瞄准已被清除！")
		game.effects.append({"position": game._cell_center(row, 4), "radius": game.board_size.x * 0.45, "time": 0.35, "duration": 0.35, "color": Color(WATER, 0.22)})

func _rows_by_plants(count: int) -> Array[int]:
	var scored: Array = []
	for i in range(game.active_rows.size()):
		var row := int(game.active_rows[i])
		var plants := 0
		for col in range(game.COLS):
			if game._targetable_plant_at(row, col) != null: plants += 1
		# Deterministic tie break rotates with each cast.
		scored.append([plants * 10 + posmod(i + serial, game.active_rows.size()), row])
	scored.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
	var result: Array[int] = []
	for entry in scored:
		if result.size() >= count: break
		if jets.any(func(p): return int(p.row) == int(entry[1])): continue
		result.append(int(entry[1]))
	return result

func queue_jet(owner: int, row: int, delay: float = JET_WARNING) -> void:
	if jets.size() >= MAX_JETS or not game._is_row_active(row) or jets.any(func(p): return int(p.row) == row): return
	# Shooters have 120 health: the jet chips, the soak is the real threat.
	var damage := 30.0 + 8.0 * _rank()
	jets.append({"owner": owner, "row": row, "age": 0.0, "delay": maxf(JET_WARNING, delay), "damage": damage, "hit": [], "blocked": []})

func _advance_jet(jet: Dictionary) -> void:
	var progress := clampf((float(jet.age) - float(jet.delay)) / JET_SWEEP, 0.0, 1.0)
	if progress <= 0.0: return
	var row := int(jet.row)
	var front: float = game.BOARD_ORIGIN.x + game.board_size.x * (1.0 - progress)
	for col in range(game.COLS - 1, -1, -1):
		var cell := Vector2i(row, col)
		if game._cell_center(row, col).x < front or jet.hit.has(cell) or jet.blocked.has(cell): continue
		if game._targetable_plant_at(row, col) == null:
			jet.hit.append(cell)
			continue
		if game._is_cell_protected_by_umbrella(row, col):
			jet.blocked.append(cell)
			game.effects.append({"position": game._cell_center(row, col) + Vector2(0, -_unit_size() * 0.35), "radius": _unit_size() * 0.42, "time": 0.3, "duration": 0.3, "color": Color(WATER, 0.30)})
			continue
		jet.hit.append(cell)
		game._damage_plant_cell(row, col, float(jet.damage) * game.TouhouDifficulty.outgoing_damage_multiplier(KIND))
		soaked[cell] = SOAK_DURATION

# --- Cucumber bait ----------------------------------------------------------

func _bait_cells(count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var rows := _rows_by_plants(game.active_rows.size())
	for row in rows:
		if result.size() >= count: break
		var col := 4 + posmod(serial + result.size() * 2, 3)
		for step in range(4):
			var candidate := 4 + posmod(col - 4 + step, 4)
			if game._targetable_plant_at(row, candidate) == null and not baits.any(func(b): return Vector2i(b.cell) == Vector2i(row, candidate)):
				col = candidate
				break
		result.append(Vector2i(row, col))
	return result

func queue_bait(owner: int, cell: Vector2i, delay: float = CUCUMBER_WARNING) -> void:
	if not game._is_row_active(cell.x) or cell.y < 0 or cell.y >= game.COLS: return
	if baits.size() + _live_cucumbers() >= MAX_CUCUMBERS or baits.any(func(b): return Vector2i(b.cell) == cell): return
	baits.append({"owner": owner, "cell": cell, "age": 0.0, "delay": maxf(CUCUMBER_WARNING, delay)})

func _live_cucumbers() -> int:
	var count := 0
	for z in game.zombies:
		if String(z.kind) == CUCUMBER and float(z.health) > 0.0: count += 1
	return count

func _spawn_cucumber(owner: int, cell: Vector2i) -> Dictionary:
	if boss_for(owner).is_empty() or _live_cucumbers() >= MAX_CUCUMBERS: return {}
	var point: Vector2 = game._cell_center(cell.x, cell.y)
	var previous_count: int = game.zombies.size()
	game._spawn_zombie_at(CUCUMBER, cell.x, point.x, true)
	if game.zombies.size() <= previous_count: return {}
	var unit: Dictionary = game.zombies[previous_count]
	unit["nitori_parent"] = owner
	unit["nitori_cleanup"] = false
	unit["nitori_rewarded"] = false
	unit["spawn_time"] = 0.0
	unit["health"] = 260.0 + 30.0 * _rank()
	unit["max_health"] = unit.health
	var state := {"owner": owner, "unit": int(unit.uid), "cell": cell, "position": point, "age": 0.0}
	cucumbers.append(state)
	return state

func _try_eat(state: Dictionary, cucumber: Dictionary) -> bool:
	var reach: float = game.CELL_SIZE.x * 0.45
	for z in game.zombies:
		if float(z.health) <= 0.0 or not game._is_enemy_zombie(z) or game._is_boss_kind(String(z.kind)): continue
		if bool(game.Defs.ZOMBIES.get(String(z.kind), {}).get("boss_summon", false)) or bool(z.get("hypnotized", false)): continue
		if int(z.get("row", -1)) != Vector2i(state.cell).x or absf(float(z.x) - float(cucumber.x)) > reach: continue
		# Kappa cucumbers restore a fifth of health and harden the eater briefly.
		z.health = minf(float(z.max_health), float(z.health) + float(z.max_health) * 0.20)
		z["nitori_power_until"] = float(game.level_time) + POWER_DURATION
		z["special_pause_timer"] = maxf(float(z.get("special_pause_timer", 0.0)), 0.8)
		cucumber["nitori_cleanup"] = true
		cucumber.health = 0.0
		game.effects.append({"position": Vector2(cucumber.x, game._row_center_y(int(cucumber.row)) - 10.0), "radius": _unit_size() * 0.45, "time": 0.35, "duration": 0.35, "color": Color(CUCUMBER_GREEN, 0.32)})
		return true
	return false

func on_cucumber_death(zombie: Dictionary) -> void:
	if String(zombie.get("kind", "")) != CUCUMBER or not zombie.has("nitori_parent"): return
	if float(zombie.get("health", 1.0)) > 0.0 or bool(zombie.get("nitori_cleanup", false)) or bool(zombie.get("nitori_rewarded", false)): return
	zombie["nitori_rewarded"] = true
	var center := Vector2(float(zombie.x), game._row_center_y(int(zombie.row)) - 12.0)
	game._spawn_sun(center, center.y, "boss", CUCUMBER_REWARD)
	game.effects.append({"position": center, "radius": _unit_size() * 0.5, "time": 0.4, "duration": 0.4, "color": Color(CUCUMBER_GREEN, 0.28)})

# --- Camouflage squad -------------------------------------------------------

func spawn_squad(owner: int, count: int) -> int:
	var boss := boss_for(owner)
	if boss.is_empty() or game.active_rows.is_empty(): return 0
	var tier := clampi(int(boss.get("boss_phase", 0)) - 1 + mini(1, _rank() / 2), 0, SQUAD_POOL.size() - 1)
	var pool: Array = SQUAD_POOL[tier]
	var live := 0
	for z in game.zombies:
		if bool(z.get("nitori_camo", false)) and float(z.health) > 0.0: live += 1
	var spawned := 0
	for i in range(mini(count, MAX_SQUAD - live)):
		if game._active_zombie_count() >= 42: break
		var row := int(game.active_rows[posmod(serial + i * 2 + 1, game.active_rows.size())])
		var previous_count: int = game.zombies.size()
		game._spawn_zombie_at(String(pool[posmod(serial + i, pool.size())]), row, game.BOARD_ORIGIN.x + game.board_size.x - 6.0, true)
		if game.zombies.size() <= previous_count: continue
		var unit: Dictionary = game.zombies[previous_count]
		unit["nitori_camo"] = true
		unit["revealed_timer"] = 0.0
		spawned += 1
	return spawned

# --- Casting ----------------------------------------------------------------

func cast(boss: Dictionary, pattern: String) -> void:
	var owner := int(boss.uid)
	jets = jets.filter(func(p): return int(p.owner) != owner)
	baits = baits.filter(func(p): return int(p.owner) != owner)
	serial += 1
	if game.active_rows.is_empty(): return
	var rank := _rank()
	match pattern:
		"nitori_camo_squad":
			spawn_squad(owner, 2 + rank / 2)
			game._show_toast("光学迷彩突击队：路灯花或显形植物可照出，受击或走近也会短暂现形")
		"nitori_cucumber_bait":
			var cells := _bait_cells([2, 3, 3, 4][rank])
			for i in range(cells.size()): queue_bait(owner, cells[i], CUCUMBER_WARNING + i * 0.15)
			game._show_toast("黄瓜诱饵：击碎返15阳光；被僵尸啃到会回血并减伤")
		"nitori_water_cannon":
			var rows := _rows_by_plants(1 + (1 if rank >= 2 else 0))
			for i in range(rows.size()): queue_jet(owner, rows[i], JET_WARNING + i * 0.5)
			game._show_toast("高压水炮：浇灭火炬树桩并让植物减速；叶子保护伞可挡水，本行大招清除积水")
		"nitori_workshop":
			spawn_squad(owner, 1 + rank / 2)
			var cells := _bait_cells(2)
			for i in range(cells.size()): queue_bait(owner, cells[i], CUCUMBER_WARNING + i * 0.2)
			for row in _rows_by_plants(1 + rank / 3): queue_jet(owner, row, JET_WARNING + 0.6)
			game._show_toast("玄武工房总动员：迷彩、黄瓜与水炮同时出动")

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0: return
	var dt := maxf(0.0, delta)
	for boss in game.zombies:
		if String(boss.kind) == KIND and float(boss.health) > 0.0:
			boss["nitori_arrival_age"] = float(boss.get("nitori_arrival_age", 0.0)) + dt
			boss["nitori_camouflaged"] = boss_camouflaged(boss)
	for cell in soaked.keys():
		soaked[cell] = float(soaked[cell]) - dt
		if float(soaked[cell]) <= 0.0 or game._targetable_plant_at(Vector2i(cell).x, Vector2i(cell).y) == null: soaked.erase(cell)
	for i in range(jets.size() - 1, -1, -1):
		var jet: Dictionary = jets[i]
		if boss_for(int(jet.owner)).is_empty():
			jets.remove_at(i)
			continue
		jet.age += dt
		_advance_jet(jet)
		if float(jet.age) >= float(jet.delay) + JET_SWEEP + 0.25: jets.remove_at(i)
	for i in range(baits.size() - 1, -1, -1):
		var bait: Dictionary = baits[i]
		if boss_for(int(bait.owner)).is_empty():
			baits.remove_at(i)
			continue
		bait.age += dt
		if float(bait.age) >= float(bait.delay):
			_spawn_cucumber(int(bait.owner), Vector2i(bait.cell))
			baits.remove_at(i)
	for i in range(cucumbers.size() - 1, -1, -1):
		var state: Dictionary = cucumbers[i]
		var unit := _unit(int(state.unit))
		if unit.is_empty():
			cucumbers.remove_at(i)
			continue
		state.age += dt
		if boss_for(int(state.owner)).is_empty() or float(state.age) >= CUCUMBER_LIFETIME or _try_eat(state, unit):
			unit["nitori_cleanup"] = true
			unit.health = 0.0
			cucumbers.remove_at(i)

func frame_index(boss: Dictionary) -> int:
	return SpriteDefs.frame_index(boss, float(boss.get("animation_time", game.level_time)))

# --- Drawing ----------------------------------------------------------------

func draw_ground() -> void:
	var unit := _unit_size()
	for cell in soaked.keys():
		var c := Vector2i(cell)
		var rect: Rect2 = game._cell_rect(c.x, c.y).grow(-unit * 0.08)
		var left := clampf(float(soaked[cell]) / SOAK_DURATION, 0.0, 1.0)
		game.draw_rect(rect, Color(WATER, 0.10 + 0.08 * left))
		var plant = game._targetable_plant_at(c.x, c.y)
		if plant != null and game._plant_has_component(plant, "torchwood"):
			# Doused torchwood steams instead of lighting peas.
			for i in range(3):
				var rise := fposmod(float(game.ui_time) * 0.7 + i * 0.33, 1.0)
				var puff := rect.get_center() + Vector2((i - 1) * unit * 0.16, -unit * (0.25 + rise * 0.45))
				game.draw_circle(puff, unit * (0.06 + rise * 0.07), Color(0.92, 0.95, 0.97, 0.45 * (1.0 - rise)))
		for i in range(3):
			var point: Vector2 = rect.position + rect.size * Vector2(0.22 + i * 0.28, 0.78 - (i % 2) * 0.12)
			game.draw_arc(point, unit * (0.05 + 0.03 * fposmod(game.ui_time * 0.8 + i * 0.37, 1.0)), 0, TAU, 14, Color(WATER, 0.55 * left), maxf(1, unit * 0.012), true)
	for bait in baits:
		var c := Vector2i(bait.cell)
		var center: Vector2 = game._cell_center(c.x, c.y)
		var progress := clampf(float(bait.age) / float(bait.delay), 0.0, 1.0)
		game.draw_arc(center, unit * 0.27, -PI / 2, -PI / 2 + TAU * progress, 24, Color(CUCUMBER_GREEN, 0.85), maxf(1, unit * 0.025), true)
		game.draw_circle(center, unit * 0.06, Color(CUCUMBER_GREEN, 0.5))

func draw_overlay() -> void:
	var unit := _unit_size()
	for jet in jets:
		var row := int(jet.row)
		var y: float = game._row_center_y(row) - 10.0
		var left: float = game.BOARD_ORIGIN.x
		var right: float = game.BOARD_ORIGIN.x + game.board_size.x
		if float(jet.age) < float(jet.delay):
			var progress := clampf(float(jet.age) / float(jet.delay), 0.0, 1.0)
			var blink := 0.35 + 0.35 * absf(sin(float(jet.age) * 9.0))
			game.draw_rect(Rect2(left, y - game.CELL_SIZE.y * 0.18, game.board_size.x, game.CELL_SIZE.y * 0.36), Color(WATER, 0.07 + 0.08 * progress))
			game.draw_line(Vector2(right, y), Vector2(right - game.board_size.x * progress, y), Color(WATER, blink), maxf(1.5, unit * 0.025), true)
			for i in range(3):
				var x := right - unit * (0.3 + i * 0.22)
				game.draw_line(Vector2(x, y - unit * 0.12), Vector2(x - unit * 0.12, y), Color(1, 1, 1, blink), maxf(1, unit * 0.02), true)
				game.draw_line(Vector2(x, y + unit * 0.12), Vector2(x - unit * 0.12, y), Color(1, 1, 1, blink), maxf(1, unit * 0.02), true)
			continue
		var sweep := clampf((float(jet.age) - float(jet.delay)) / JET_SWEEP, 0.0, 1.0)
		var front: float = right - game.board_size.x * sweep
		var fade := 1.0 - clampf((float(jet.age) - float(jet.delay) - JET_SWEEP) / 0.25, 0.0, 1.0)
		var width: float = game.CELL_SIZE.y * 0.30
		game.draw_rect(Rect2(front, y - width * 0.5, right - front, width), Color(DEEP, 0.38 * fade))
		game.draw_line(Vector2(front, y), Vector2(right, y), Color(WATER, 0.85 * fade), width * 0.55, true)
		game.draw_line(Vector2(front, y), Vector2(right, y), Color(1, 1, 1, 0.65 * fade), maxf(1.5, width * 0.16), true)
		for i in range(5):
			var spray := Vector2(front - unit * 0.05, y) + Vector2(-cos(i * 1.3) * unit * 0.18, (i - 2) * unit * 0.08)
			game.draw_circle(spray, maxf(1.5, unit * 0.03), Color(WATER, 0.75 * fade))
	# Camouflaged squads keep a refraction outline, so the hidden rule is readable.
	for z in game.zombies:
		if not is_camouflaged(z): continue
		var center := Vector2(float(z.x), game._row_center_y(int(z.row)) - unit * 0.30)
		var wobble := sin(float(game.ui_time) * 6.0 + float(z.uid)) * unit * 0.03
		game.draw_arc(center + Vector2(wobble, 0), unit * 0.30, 0, TAU, 20, Color(WATER, 0.40), maxf(1, unit * 0.016), true)
		game.draw_arc(center - Vector2(wobble, 0), unit * 0.24, PI * 0.2, PI * 1.3, 14, Color(1, 1, 1, 0.30), maxf(1, unit * 0.012), true)

func draw_cucumber(center: Vector2, zombie: Dictionary) -> void:
	var unit := _unit_size()
	var base := center + Vector2(0, -unit * 0.12)
	var tilt := 0.35 + sin(float(game.ui_time) * 2.0 + float(zombie.get("uid", 0))) * 0.05
	var axis := Vector2.from_angle(-PI / 2 + tilt) * unit * 0.30
	var side := axis.orthogonal().normalized() * unit * 0.09
	var body := PackedVector2Array()
	# Rounded tips are shared once; a repeated vertex breaks triangulation.
	body.append(base - axis)
	for i in range(1, 13):
		var t := float(i) / 13.0
		var swell := sin(t * PI) * (0.85 + 0.15 * sin(t * 9.0))
		body.append(base - axis + axis * 2.0 * t + side * swell)
	body.append(base + axis)
	for i in range(12, 0, -1):
		var t := float(i) / 13.0
		var swell := sin(t * PI) * (0.85 + 0.15 * cos(t * 7.0))
		body.append(base - axis + axis * 2.0 * t - side * swell)
	game.draw_colored_polygon(body, CUCUMBER_GREEN)
	var outline := body.duplicate()
	outline.append(body[0])
	game.draw_polyline(outline, Color("2e6a2a"), maxf(1, unit * 0.018), true)
	for i in range(4):
		var p := base - axis * 0.6 + axis * 0.4 * i + side * (0.3 if i % 2 else -0.3)
		game.draw_circle(p, maxf(1, unit * 0.015), Color("d8f0a0"))
	game.draw_line(base + axis, base + axis * 1.18 + side * 0.4, Color("8a6b32"), maxf(1.5, unit * 0.025), true)
	var ratio := clampf(float(zombie.get("health", 1.0)) / maxf(1.0, float(zombie.get("max_health", 1.0))), 0, 1)
	var bar := Rect2(center + Vector2(-unit * 0.26, -unit * 0.56), Vector2(unit * 0.52, maxf(2, unit * 0.04)))
	game.draw_rect(bar, Color(0.06, 0.16, 0.10, 0.82))
	game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color("9be37c"))
