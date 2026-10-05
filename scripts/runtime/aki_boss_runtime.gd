extends RefCounted

const Danmaku = preload("res://scripts/runtime/aki_danmaku.gd")
const KINDS := ["shizuha_boss", "minoriko_boss"]
const GOLD := Color("f4cc78")
const RED := Color("e95c40")
const GREEN := Color("b7d66e")
const MAX_FIELDS := 12
const MAX_BASKETS := 3
const FIELD_DURATION := 6.0
const HARVEST_WARNING := 1.2
const BASKET_LIFETIME := 8.5
const HEAL_INTERVAL := 4.0
const HEAL_AMOUNT := 30.0
const HARVEST_DAMAGE := 90.0

var game: Control
var fields: Array[Dictionary] = []
var baskets: Array[Dictionary] = []
var serial := 0

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	fields.clear()
	baskets.clear()
	serial = 0
	for z in game.zombies:
		if z.has("aki_parent"):
			z["aki_cleanup"] = true
			z.health = 0.0

func clear_owner(owner: int) -> void:
	fields = fields.filter(func(p): return int(p.owner) != owner)
	baskets = baskets.filter(func(p): return int(p.owner) != owner)
	for z in game.zombies:
		if int(z.get("aki_parent", -1)) == owner:
			# Phase/death cleanup must not award a basket's kill-only sunshine.
			z["aki_cleanup"] = true
			z.health = 0.0

func boss_for(owner: int) -> Dictionary:
	for z in game.zombies:
		if int(z.uid) == owner and String(z.kind) in KINDS and float(z.health) > 0.0: return z
	return {}

func queue_field(owner: int, cell: Vector2i, mode: String, delay: float = 1.2) -> void:
	if fields.size() >= MAX_FIELDS or not game._is_row_active(cell.x) or cell.y < 0 or cell.y >= game.COLS: return
	if mode not in ["ripening", "leaf_mat", "basket"]: return
	if fields.any(func(p): return p.cell == cell): return
	fields.append({"owner": owner, "cell": cell, "mode": mode, "age": 0.0, "delay": maxf(1.0, delay), "duration": FIELD_DURATION, "hit": false})

func _unit(uid: int) -> Dictionary:
	for z in game.zombies:
		if int(z.uid) == uid and float(z.health) > 0.0: return z
	return {}

func _spawn_basket(owner: int, cell: Vector2i) -> void:
	if boss_for(owner).is_empty(): return
	baskets = baskets.filter(func(b): return not _unit(int(b.unit)).is_empty())
	if baskets.size() >= MAX_BASKETS: return
	var count := 0
	for z in game.zombies:
		if String(z.kind) == "aki_harvest_basket" and float(z.health) > 0.0: count += 1
	if count >= MAX_BASKETS: return
	var point: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, -12)
	var previous_count: int = game.zombies.size()
	game._spawn_zombie_at("aki_harvest_basket", cell.x, point.x, true)
	if game.zombies.size() <= previous_count: return
	var unit: Dictionary = game.zombies[previous_count]
	unit["aki_parent"] = owner
	unit["aki_cleanup"] = false
	unit["aki_rewarded"] = false
	unit["spawn_time"] = 0.0
	unit["health"] = 320.0 + 45.0 * _rank()
	unit["max_health"] = unit.health
	baskets.append({"owner": owner, "unit": int(unit.uid), "row": cell.x, "position": point, "age": 0.0, "next_heal": HEAL_INTERVAL, "pulse": 0.0})

func _rank() -> int:
	return int(game.TouhouDifficulty.profile(game.current_level).rank)

func cast(boss: Dictionary, pattern: String) -> void:
	var owner := int(boss.uid)
	clear_owner(owner)
	serial += 1
	if game.active_rows.is_empty(): return
	var start := posmod(serial, game.active_rows.size())
	match pattern:
		"aki_ripening":
			for i in range(2 + mini(1, _rank())):
				var row := int(game.active_rows[posmod(start + i * 2, game.active_rows.size())])
				queue_field(owner, Vector2i(row, 1 + posmod(serial + i * 2, game.COLS - 3)), "ripening", 1.2 + i * 0.2)
			game._show_toast("金穗催熟：植物行动加快；红圈收割前用本行大招清除")
		"aki_offering":
			for i in range(mini(MAX_BASKETS, 1 + _rank())):
				var row := int(game.active_rows[posmod(start + i * 2, game.active_rows.size())])
				queue_field(owner, Vector2i(row, game.COLS - 2 - (i % 2)), "basket", 1.4 + i * 0.3)
			game._show_toast("贡仓每四秒为附近普通僵尸治疗；打碎一仓返还25阳光")
		"aki_six_furrows":
			for i in range(game.active_rows.size()):
				var row := int(game.active_rows[i])
				queue_field(owner, Vector2i(row, 2 + posmod(i + serial, game.COLS - 4)), "leaf_mat", 1.3)
			game._show_toast("交错红叶毯：标记格行动减慢；本行大招扫净落叶")
		"aki_feast":
			for i in range(game.active_rows.size()):
				var row := int(game.active_rows[posmod(start + i, game.active_rows.size())])
				queue_field(owner, Vector2i(row, 1 + posmod(i * 2 + serial, game.COLS - 3)), "ripening" if i % 2 == 0 else "leaf_mat", 1.2 + (i % 2) * 0.3)
			for i in range(2):
				var row := int(game.active_rows[posmod(start + i * 3, game.active_rows.size())])
				queue_field(owner, Vector2i(row, game.COLS - 2), "basket", 1.5 + i * 0.25)
			game._show_toast("秋日宴：金穗先增产后收割，贡仓可打碎，大招清本行叶毯")

func action_factor(row: int, col: int) -> float:
	for p in fields:
		if Vector2i(p.cell) != Vector2i(row, col): continue
		if float(p.age) < float(p.delay) or float(p.age) >= float(p.delay) + float(p.duration): continue
		var plant = game._targetable_plant_at(row, col)
		if plant != null and (float(plant.get("holy_invincible_timer", 0.0)) > 0.0 or bool(plant.get("ultimate_active", false))): return 1.0
		if String(p.mode) == "ripening": return 1.20 + _rank() * 0.015
		if String(p.mode) == "leaf_mat": return 0.80
	return 1.0

func cleanse_row(row: int) -> void:
	var count := fields.size()
	fields = fields.filter(func(p): return p.cell.x != row)
	if fields.size() < count:
		game._show_toast("大招扫净了本行落叶与催熟田垄！")
		game.effects.append({"position": game._cell_center(row, 4), "radius": game.board_size.x * 0.46, "time": 0.30, "duration": 0.30, "color": Color(1.0, 0.8, 0.36, 0.20)})

func on_basket_death(zombie: Dictionary) -> void:
	if String(zombie.get("kind", "")) != "aki_harvest_basket" or not zombie.has("aki_parent"): return
	if float(zombie.get("health", 1.0)) > 0.0 or bool(zombie.get("aki_cleanup", false)) or bool(zombie.get("aki_rewarded", false)): return
	zombie["aki_rewarded"] = true
	var point := Vector2(float(zombie.x), game._row_center_y(int(zombie.row)) - 12.0)
	game._spawn_sun(point, point.y, "boss", 25)

func _heal_nearby(basket: Dictionary) -> void:
	var remaining := 10
	for z in game.zombies:
		if remaining <= 0: break
		if not game._is_enemy_zombie(z) or float(z.health) <= 0.0 or game._is_boss_kind(String(z.kind)) or z.has("aki_parent"): continue
		if bool(game.Defs.ZOMBIES.get(String(z.kind), {}).get("boss_summon", false)): continue
		if absi(int(z.row) - int(basket.row)) > 1 or absf(float(z.x) - Vector2(basket.position).x) > game.CELL_SIZE.x * 1.6: continue
		var maximum := float(z.get("max_health", z.health))
		if float(z.health) >= maximum: continue
		z.health = minf(maximum, float(z.health) + HEAL_AMOUNT)
		z["flash"] = maxf(float(z.get("flash", 0.0)), 0.10)
		remaining -= 1

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0: return
	var dt := maxf(0.0, delta)
	var birth_deltas: Dictionary = {}
	for i in range(fields.size() - 1, -1, -1):
		var p: Dictionary = fields[i]
		if boss_for(int(p.owner)).is_empty():
			fields.remove_at(i)
			continue
		p.age += dt
		var age := float(p.age)
		if String(p.mode) == "basket":
			if age >= float(p.delay):
				var existing_uids: Array = baskets.map(func(b): return int(b.unit))
				_spawn_basket(int(p.owner), Vector2i(p.cell))
				for fresh in baskets:
					if not existing_uids.has(int(fresh.unit)):
						birth_deltas[int(fresh.unit)] = minf(dt, maxf(0.0, age - float(p.delay)))
				fields.remove_at(i)
			continue
		if age < float(p.delay) + float(p.duration): continue
		if String(p.mode) == "ripening" and not bool(p.hit):
			p.hit = true
			var boss := boss_for(int(p.owner))
			var damage: float = HARVEST_DAMAGE * game.TouhouDifficulty.attack_damage(String(boss.kind), game.current_level, int(boss.get("boss_phase", 0)))
			game._damage_plant_cell(p.cell.x, p.cell.y, damage, 0.0, true)
			game.effects.append({"position": game._cell_center(p.cell.x, p.cell.y), "radius": minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 0.30, "time": 0.45, "duration": 0.45, "color": Color(RED, 0.30)})
		fields.remove_at(i)
	for i in range(baskets.size() - 1, -1, -1):
		var b: Dictionary = baskets[i]
		var unit := _unit(int(b.unit))
		if unit.is_empty():
			baskets.remove_at(i)
			continue
		if boss_for(int(b.owner)).is_empty():
			unit["aki_cleanup"] = true
			unit.health = 0.0
			baskets.remove_at(i)
			continue
		var elapsed := float(birth_deltas.get(int(b.unit), dt))
		b.age += elapsed
		b.pulse = maxf(0.0, float(b.pulse) - elapsed)
		if float(b.age) >= float(b.next_heal):
			_heal_nearby(b)
			b.next_heal = float(b.next_heal) + HEAL_INTERVAL
			b.pulse = 0.65
		if float(b.age) >= BASKET_LIFETIME:
			unit["aki_cleanup"] = true
			unit.health = 0.0
			baskets.remove_at(i)

func frame_index(boss: Dictionary) -> int:
	var pose := String(boss.get("rumia_state", "idle"))
	var frames: Array = [0, 1, 2, 1]
	match pose:
		"arrival", "shift": frames = [3, 4, 5, 4]
		"shot": frames = [6, 7, 8, 7]
		"leaf", "leaves": frames = [6, 7, 8, 7]
		"channel": frames = [9, 10, 11, 10]
		"harvest": frames = [15, 16, 17, 16]
		"phase", "final": frames = [18, 19, 20, 19]
	if float(boss.get("health", 1.0)) <= 0.0: frames = [21, 22, 23]
	elif float(boss.get("flash", 0.0)) > 0.1 and float(boss.get("touhou_cast_remaining", 0.0)) <= 0.0: frames = [21, 22, 21] if String(boss.kind) == "minoriko_boss" else [12, 13, 14]
	return int(frames[posmod(int(float(boss.get("animation_time", game.level_time)) * 7.0), frames.size())])

func draw_ground() -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	for p in fields:
		var cell := Vector2i(p.cell)
		var center: Vector2 = game._cell_center(cell.x, cell.y)
		var rect: Rect2 = game._cell_rect(cell.x, cell.y).grow(-unit * 0.055)
		var age := float(p.age)
		var mode := String(p.mode)
		var active := age >= float(p.delay)
		var harvest := mode == "ripening" and age >= float(p.delay) + float(p.duration) - HARVEST_WARNING
		var tint := RED if mode == "leaf_mat" or harvest else GOLD
		var progress := clampf(age / float(p.delay), 0.0, 1.0)
		if harvest: progress = clampf((age - float(p.delay) - float(p.duration) + HARVEST_WARNING) / HARVEST_WARNING, 0.0, 1.0)
		game.draw_rect(rect, Color(tint, 0.11 if active else 0.055))
		game.draw_rect(rect, Color(tint, 0.70 if not harvest else 0.70 + 0.25 * sin(age * 11.0)), false, maxf(1.0, unit * 0.02), true)
		if not active or harvest:
			game.draw_arc(center, unit * 0.28, -PI / 2, -PI / 2 + TAU * progress, 24, Color(tint, 0.80), maxf(1.0, unit * 0.02), true)
		if mode == "basket":
			game.draw_line(center + Vector2(-unit * 0.20, unit * 0.18), center + Vector2(unit * 0.20, unit * 0.18), Color(GOLD, 0.70), unit * 0.08, true)
		else:
			for i in range(4):
				var point := center + Vector2(sin(i * 2.3) * unit * 0.28, cos(i * 2.3) * unit * 0.27)
				Danmaku.draw_leaf(game, point, unit * (0.07 if not active else 0.11), i * 1.1 + age * 0.15, Color(tint, 0.55 if not active else 0.65))

func draw_overlay() -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	for p in fields:
		if String(p.mode) != "ripening" or float(p.age) < float(p.delay): continue
		var center: Vector2 = game._cell_center(p.cell.x, p.cell.y)
		var height := unit * 0.30
		for side in [-1, 1]:
			var root := center + Vector2(side * unit * 0.30, unit * 0.27)
			var tip := root + Vector2(side * unit * 0.035, -height)
			game.draw_line(root, tip, Color(GREEN, 0.75), maxf(1.0, unit * 0.02), true)
			for i in range(3):
				var grain := tip + Vector2(0, unit * i * 0.075)
				game.draw_line(grain - Vector2(unit * 0.055, unit * 0.04), grain, Color(GOLD, 0.78), unit * 0.05, true)
				game.draw_line(grain + Vector2(unit * 0.055, unit * 0.04), grain, Color(GOLD, 0.78), unit * 0.05, true)
	for b in baskets:
		if float(b.pulse) <= 0.0: continue
		var t := 1.0 - float(b.pulse) / 0.65
		game.draw_arc(Vector2(b.position), unit * lerpf(0.25, 1.6, t), 0, TAU, 40, Color(GREEN, (1.0 - t) * 0.40), maxf(1.0, unit * 0.02), true)
	for boss in game.zombies:
		if String(boss.kind) not in KINDS or float(boss.health) <= 0.0 or float(boss.get("touhou_cast_remaining", 0.0)) <= 0.0: continue
		var center := Vector2(float(boss.x), game._row_center_y(int(boss.row)) - unit * 0.60)
		for i in range(6):
			var angle: float = game.level_time * 1.1 + TAU * i / 6.0
			var point := center + Vector2(cos(angle) * unit * 0.50, sin(angle) * unit * 0.21)
			Danmaku.draw_leaf(game, point, unit * 0.075, angle + PI * 0.5, Color(RED if String(boss.kind) == "shizuha_boss" else GOLD, 0.62))

func draw_basket(center: Vector2, zombie: Dictionary) -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var point := center + Vector2(0, -unit * 0.13)
	var rect := Rect2(point + Vector2(-unit * 0.28, -unit * 0.18), Vector2(unit * 0.56, unit * 0.40))
	game.draw_rect(rect, Color("956033"))
	game.draw_rect(rect, Color("ebba72"), false, maxf(1.0, unit * 0.025), true)
	for i in range(4):
		var x := rect.position.x + rect.size.x * (i + 0.5) / 4.0
		game.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.33, 0.16, 0.08, 0.7), maxf(1.0, unit * 0.018), true)
	game.draw_line(rect.position + Vector2(0, rect.size.y * 0.65), rect.position + Vector2(rect.size.x, rect.size.y * 0.65), GOLD, maxf(1.0, unit * 0.04), true)
	for i in range(5):
		var root := point + Vector2((i - 2) * unit * 0.075, -unit * 0.06)
		var tip := root + Vector2((i - 2) * unit * 0.025, -unit * (0.28 + 0.035 * (i % 2)))
		game.draw_line(root, tip, GREEN, maxf(1.0, unit * 0.018), true)
		for j in range(3): game.draw_circle(tip + Vector2(0, j * unit * 0.055), unit * 0.038, GOLD)
	Danmaku.draw_leaf(game, point + Vector2(unit * 0.12, unit * 0.055), unit * 0.10, 0.4, RED)
	var ratio := clampf(float(zombie.get("health", 1.0)) / maxf(1.0, float(zombie.get("max_health", 1.0))), 0.0, 1.0)
	var hp := Rect2(rect.position + Vector2(0, -unit * 0.40), Vector2(rect.size.x, maxf(2.0, unit * 0.04)))
	game.draw_rect(hp, Color(0.17, 0.08, 0.04, 0.8))
	game.draw_rect(Rect2(hp.position, Vector2(hp.size.x * ratio, hp.size.y)), GREEN)
