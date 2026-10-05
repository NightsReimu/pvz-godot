extends RefCounted

const SpriteDefs = preload("res://scripts/data/touhou_sprite_defs.gd")
const Danmaku = preload("res://scripts/runtime/hina_danmaku.gd")
const KIND := "hina_boss"
const GREEN := Color("95e6b5")
const RED := Color("ec7391")
const GOLD := Color("f0d090")
const CURSE_FACTOR := 0.72
const MAX_FIELDS := 12
const MAX_DOLLS := 3
const FIELD_DURATION := 6.0
const FIELD_WARNING := 1.2
const DOLL_WARNING := 1.4
const DOLL_LIFETIME := 9.0
const DOLL_RELEASE_DAMAGE := 180.0
const MISFIRE_FACTOR := 0.75
const FALLBACK_ACTIONS := {
	"idle": [0, 1, 2, 1], "walk": [3, 4, 5, 4],
	"shot": [6, 7, 8, 7], "ofuda": [9, 10, 11, 10],
	"spin": [6, 7, 8, 7], "channel": [9, 10, 11, 10],
	"doll": [15, 16, 17, 16], "curse": [15, 16, 17, 16],
	"phase": [15, 16, 17, 23], "final": [18, 19, 20, 23],
	"hit": [12, 13, 14], "defeat": [21, 22],
}

var game: Control
var fields: Array[Dictionary] = []
var dolls: Array[Dictionary] = []
var serial := 0

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	fields.clear()
	dolls.clear()
	serial = 0
	for z in game.zombies:
		if z.has("hina_parent"):
			z["hina_cleanup"] = true
			z.health = 0.0

func clear_owner(owner: int) -> void:
	fields = fields.filter(func(p): return int(p.owner) != owner)
	dolls = dolls.filter(func(p): return int(p.owner) != owner)
	for z in game.zombies:
		if int(z.get("hina_parent", -1)) == owner:
			z["hina_cleanup"] = true
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

func queue_field(owner: int, cell: Vector2i, mode: String, delay: float = FIELD_WARNING) -> void:
	if fields.size() >= MAX_FIELDS or not game._is_row_active(cell.x) or cell.y < 0 or cell.y >= game.COLS: return
	if mode not in ["curse", "doll", "misfire"] or fields.any(func(p): return p.cell == cell): return
	var warning := maxf(DOLL_WARNING if mode == "doll" else FIELD_WARNING, delay)
	fields.append({"owner": owner, "cell": cell, "mode": mode, "age": 0.0, "delay": warning, "duration": FIELD_DURATION, "shots": 0, "misfires": 0, "pulse": 0.0})

func _choose_cells(count: int, start: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	# Prefer a real living plant, including a support-only tile, so the mark
	# interacts with an established defense instead of repeatedly picking bare soil.
	for i in range(game.active_rows.size()):
		if result.size() >= count: break
		var row := int(game.active_rows[posmod(start + i, game.active_rows.size())])
		var chosen := -1
		for step in range(game.COLS):
			var col := posmod(1 + serial + i + step, game.COLS)
			var plant = game._targetable_plant_at(row, col)
			if plant != null and float(plant.get("health", 0.0)) > 0.0:
				chosen = col
				break
		if chosen < 0: chosen = 1 + posmod(serial + i * 2, maxi(1, game.COLS - 3))
		result.append(Vector2i(row, chosen))
	return result

func cast(boss: Dictionary, pattern: String) -> void:
	var owner := int(boss.uid)
	clear_owner(owner)
	serial += 1
	if game.active_rows.is_empty(): return
	var start := posmod(serial, game.active_rows.size())
	match pattern:
		"hina_delayed":
			for cell in _choose_cells(2 + mini(2, _rank()), start): queue_field(owner, cell, "curse", 1.2)
			game._show_toast("迟发厄印：符纸落定后行动减慢；本行大招可驱厄")
		"hina_doll_offering":
			for i in range(mini(MAX_DOLLS, 1 + _rank())):
				var row := int(game.active_rows[posmod(start + i * 2, game.active_rows.size())])
				queue_field(owner, Vector2i(row, game.COLS - 2 + i % 2), "doll", 1.4 + i * 0.2)
			game._show_toast("打碎厄偶：净化本行、向附近普通敌释放积厄，并返25阳光")
		"hina_misfire":
			for cell in _choose_cells(mini(6, 3 + _rank()), start): queue_field(owner, cell, "misfire", 1.2)
			game._show_toast("失准弹仓：标记格每第三发普通弹伤害降低25%，本行大招净化")
		"hina_festival":
			var cells := _choose_cells(mini(6, game.active_rows.size()), start)
			for i in range(cells.size()): queue_field(owner, cells[i], "curse" if i % 2 == 0 else "misfire", 1.2 + i % 2 * 0.2)
			for i in range(2):
				var row := int(game.active_rows[posmod(start + i * 3, game.active_rows.size())])
				queue_field(owner, Vector2i(row, game.COLS - 1), "doll", 1.6 + i * 0.2)
			game._show_toast("流雏厄祭：厄印与失准交错，击破厄偶或施放本行大招可解围")

func _spawn_doll(owner: int, cell: Vector2i) -> Dictionary:
	if boss_for(owner).is_empty(): return {}
	dolls = dolls.filter(func(d): return not _unit(int(d.unit)).is_empty())
	if dolls.size() >= MAX_DOLLS: return {}
	var count := 0
	for z in game.zombies:
		if String(z.kind) == "hina_misfortune_doll" and float(z.health) > 0.0: count += 1
	if count >= MAX_DOLLS: return {}
	var point: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, -12)
	var previous_count: int = game.zombies.size()
	game._spawn_zombie_at("hina_misfortune_doll", cell.x, point.x, true)
	if game.zombies.size() <= previous_count: return {}
	var unit: Dictionary = game.zombies[previous_count]
	unit["hina_parent"] = owner
	unit["hina_cleanup"] = false
	unit["hina_rewarded"] = false
	unit["spawn_time"] = 0.0
	unit["health"] = 360.0 + 40.0 * _rank()
	unit["max_health"] = unit.health
	var state := {"owner": owner, "unit": int(unit.uid), "row": cell.x, "position": point, "age": 0.0}
	dolls.append(state)
	for offset in [1, 2]:
		var next_cell := Vector2i(cell.x, maxi(0, cell.y - offset))
		var prior: int = fields.size()
		queue_field(owner, next_cell, "curse", FIELD_WARNING)
		if fields.size() > prior: fields.back()["doll_uid"] = int(unit.uid)
	return state

func _active_field(field: Dictionary) -> bool:
	return not boss_for(int(field.owner)).is_empty() and float(field.age) >= float(field.delay) and float(field.age) < float(field.delay) + float(field.duration)

func action_factor(row: int, col: int) -> float:
	for p in fields:
		if String(p.mode) != "curse" or Vector2i(p.cell) != Vector2i(row, col) or not _active_field(p): continue
		var plant = game._targetable_plant_at(row, col)
		if plant != null and (float(plant.get("holy_invincible_timer", 0.0)) > 0.0 or bool(plant.get("ultimate_active", false))): return 1.0
		return CURSE_FACTOR
	return 1.0

func cleanse_row(row: int) -> void:
	var previous := fields.size()
	fields = fields.filter(func(p): return p.cell.x != row)
	if fields.size() < previous:
		game._show_toast("本行厄印与失准符纸已被驱散！")
		game.effects.append({"position": game._cell_center(row, 4), "radius": game.board_size.x * 0.45, "time": 0.35, "duration": 0.35, "color": Color(GREEN, 0.22)})

func _projectile_exempt(p: Dictionary) -> bool:
	for flag in ["ultimate", "plant_food", "fusion_ultimate", "empowered", "reflected", "fusion_fragment", "source_special", "special", "hina_exempt"]:
		if bool(p.get(flag, false)): return true
	var kind := String(p.get("kind", ""))
	return kind.contains("ultimate") or kind.contains("meteor") or kind.contains("plant_food") or float(p.get("damage", 0.0)) <= 0.0

func tag_emissions(first: int, row: int, col: int, plant: Dictionary) -> void:
	# Native multilanes and short mobile tiles cannot recover the emitting
	# plant's cell from the target lane or the muzzle's shifted coordinates.
	var exempt := bool(plant.get("ultimate_active", false)) or float(plant.get("plant_food_timer", 0.0)) > 0.0
	for i in range(clampi(first, 0, game.projectiles.size()), game.projectiles.size()):
		var p: Dictionary = game.projectiles[i]
		if not p.has("source_cell"): p["source_cell"] = Vector2i(row, col)
		if exempt: p["hina_exempt"] = true

func modify_projectile(p: Dictionary) -> Dictionary:
	# One birth decision only: a shot entering a marked tile later cannot acquire
	# a curse, and a returning/piercing projectile cannot be weakened repeatedly.
	if bool(p.get("hina_checked", false)): return p
	p["hina_checked"] = true
	if _projectile_exempt(p) or (not p.has("position") and not p.has("arc_origin")): return p
	var row := int(p.get("source_row", p.get("row", -1)))
	var origin := Vector2(p.get("arc_origin", p.get("position", Vector2.ZERO)))
	var col := int(p.get("source_col", floori((origin.x - game.BOARD_ORIGIN.x) / maxf(1.0, game.CELL_SIZE.x))))
	var source_cell = p.get("source_cell", null)
	if source_cell is Vector2i:
		row = source_cell.x
		col = source_cell.y
	if not game._is_row_active(row) or col < 0 or col >= game.COLS: return p
	for field in fields:
		if String(field.mode) != "misfire" or Vector2i(field.cell) != Vector2i(row, col) or not _active_field(field): continue
		field.shots += 1
		if int(field.shots) % 3 == 0:
			p["damage"] = float(p.damage) * MISFIRE_FACTOR
			p["hina_misfire"] = true
			p["hina_source_cell"] = Vector2i(row, col)
			field.misfires += 1
			field.pulse = 0.35
			if p.get("color", null) is Color: p["color"] = Color(p.color).lerp(RED, 0.35)
		return p
	return p

func on_doll_death(zombie: Dictionary) -> void:
	if String(zombie.get("kind", "")) != "hina_misfortune_doll" or not zombie.has("hina_parent"): return
	if float(zombie.get("health", 1.0)) > 0.0 or bool(zombie.get("hina_cleanup", false)) or bool(zombie.get("hina_rewarded", false)): return
	zombie["hina_rewarded"] = true
	var row := int(zombie.row)
	cleanse_row(row)
	var center := Vector2(float(zombie.x), game._row_center_y(row) - 12.0)
	# Damage modifies existing dictionaries only. Death processing stays in the
	# game's normal cleanup pass, so a release cannot recursively mutate its list.
	for target in game.zombies:
		if float(target.health) <= 0.0 or not game._is_enemy_zombie(target) or game._is_boss_kind(String(target.kind)): continue
		if bool(game.Defs.ZOMBIES.get(String(target.kind), {}).get("boss_summon", false)): continue
		var point := Vector2(float(target.x), game._row_center_y(int(target.row)) - 12.0)
		if point.distance_to(center) <= minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 1.7:
			game._apply_zombie_damage(target, DOLL_RELEASE_DAMAGE, 0.18)
	game._spawn_sun(center, center.y, "boss", 25)
	game.effects.append({"position": center, "radius": minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 1.7, "time": 0.45, "duration": 0.45, "color": Color(GREEN, 0.25)})

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0: return
	var dt := maxf(0.0, delta)
	for boss in game.zombies:
		if String(boss.kind) == KIND and float(boss.health) > 0.0:
			boss["hina_arrival_age"] = float(boss.get("hina_arrival_age", 0.0)) + dt
	var birth_deltas: Dictionary = {}
	for i in range(fields.size() - 1, -1, -1):
		var p: Dictionary = fields[i]
		if boss_for(int(p.owner)).is_empty():
			fields.remove_at(i)
			continue
		p.age += dt
		p.pulse = maxf(0.0, float(p.pulse) - dt)
		if String(p.mode) == "doll":
			if float(p.age) >= float(p.delay):
				var state := _spawn_doll(int(p.owner), Vector2i(p.cell))
				if not state.is_empty(): birth_deltas[int(state.unit)] = minf(dt, maxf(0.0, float(p.age) - float(p.delay)))
				fields.remove_at(i)
			continue
		if float(p.age) >= float(p.delay) + float(p.duration): fields.remove_at(i)
	for i in range(dolls.size() - 1, -1, -1):
		var d: Dictionary = dolls[i]
		var unit := _unit(int(d.unit))
		if unit.is_empty():
			dolls.remove_at(i)
			continue
		if boss_for(int(d.owner)).is_empty():
			unit["hina_cleanup"] = true
			unit.health = 0.0
			fields = fields.filter(func(p): return int(p.get("doll_uid", -1)) != int(d.unit))
			dolls.remove_at(i)
			continue
		d.age += float(birth_deltas.get(int(d.unit), dt))
		if float(d.age) >= DOLL_LIFETIME:
			unit["hina_cleanup"] = true
			unit.health = 0.0
			fields = fields.filter(func(p): return int(p.get("doll_uid", -1)) != int(d.unit))
			dolls.remove_at(i)

func frame_index(boss: Dictionary) -> int:
	var actions: Dictionary = SpriteDefs.SCARLET_ANIMATIONS.get(String(boss.get("kind", "")), FALLBACK_ACTIONS)
	var pose := String(boss.get("rumia_state", "idle"))
	if pose in ["arrival", "shift"]: pose = "walk"
	var frames: Array = actions.get(pose, FALLBACK_ACTIONS.get(pose, FALLBACK_ACTIONS.idle))
	if float(boss.get("health", 1.0)) <= 0.0: frames = actions.get("defeat", FALLBACK_ACTIONS.defeat)
	elif float(boss.get("impact_timer", 0.0)) > 0.0 or (float(boss.get("flash", 0.0)) > 0.1 and float(boss.get("touhou_cast_remaining", 0.0)) <= 0.0): frames = actions.get("hit", FALLBACK_ACTIONS.hit)
	return int(frames[posmod(int(float(boss.get("animation_time", game.level_time)) * 7.0), frames.size())])

func draw_ground() -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	for p in fields:
		var cell := Vector2i(p.cell)
		var rect: Rect2 = game._cell_rect(cell.x, cell.y).grow(-unit * 0.06)
		var center: Vector2 = game._cell_center(cell.x, cell.y)
		var active := float(p.age) >= float(p.delay)
		var mode := String(p.mode)
		var tint := RED if mode == "misfire" else GREEN
		game.draw_rect(rect, Color(tint, 0.10 if active else 0.035))
		game.draw_rect(rect, Color(tint, 0.66 + float(p.pulse) * 0.55), false, maxf(1, unit * 0.02), true)
		if not active:
			var progress := clampf(float(p.age) / float(p.delay), 0, 1)
			game.draw_arc(center, unit * 0.27, -PI / 2, -PI / 2 + TAU * progress, 24, Color(tint, 0.75), maxf(1, unit * 0.025), true)
			Danmaku.draw_ofuda(game, center, unit * 0.11, PI / 2, Color(tint, 0.58))
		elif mode == "curse":
			var turn := float(p.age) * 0.70
			for i in range(3):
				var angle := turn + TAU * i / 3.0
				Danmaku.draw_ofuda(game, center + Vector2.from_angle(angle) * unit * 0.23, unit * 0.09, angle + PI / 2, Color(GREEN, 0.60))
		elif mode == "misfire":
			for i in range(3):
				var point := center + Vector2((i - 1) * unit * 0.20, unit * 0.26)
				game.draw_circle(point, unit * 0.045, Color(GREEN if i < 2 else RED, 0.8))
				if i == 2: game.draw_line(point + Vector2(-unit * 0.06, unit * 0.06), point + Vector2(unit * 0.06, -unit * 0.06), RED, maxf(1, unit * 0.025), true)

func draw_overlay() -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	for p in fields:
		if float(p.pulse) <= 0.0: continue
		var point: Vector2 = game._cell_center(p.cell.x, p.cell.y) + Vector2(0, -unit * 0.30)
		game.draw_line(point - Vector2(unit * 0.13, unit * 0.13), point + Vector2(unit * 0.13, unit * 0.13), RED, maxf(1.5, unit * 0.03), true)
		game.draw_line(point - Vector2(-unit * 0.13, unit * 0.13), point + Vector2(-unit * 0.13, unit * 0.13), RED, maxf(1.5, unit * 0.03), true)
	for d in dolls:
		var age := float(d.age)
		if age < DOLL_LIFETIME - 1.0: continue
		var point := Vector2(d.position)
		game.draw_arc(point, unit * 0.34, 0, TAU, 24, Color(GREEN, 0.30 + 0.25 * sin(age * 10)), maxf(1, unit * 0.02), true)

func draw_doll(center: Vector2, zombie: Dictionary) -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	var point := center + Vector2(0, -unit * 0.20)
	var body := Rect2(point + Vector2(-unit * 0.10, -unit * 0.02), Vector2(unit * 0.20, unit * 0.32))
	game.draw_line(point + Vector2(-unit * 0.26, unit * 0.04), point + Vector2(unit * 0.26, unit * 0.04), GOLD, maxf(2, unit * 0.07), true)
	game.draw_rect(body, Color("b89763"))
	for offset in [-1, 1]: game.draw_line(point + Vector2(offset * unit * 0.055, unit * 0.22), point + Vector2(offset * unit * 0.13, unit * 0.38), GOLD, maxf(2, unit * 0.045), true)
	game.draw_circle(point - Vector2(0, unit * 0.13), unit * 0.13, Color("d4bc8f"))
	game.draw_line(point + Vector2(-unit * 0.055, -unit * 0.17), point + Vector2(unit * 0.055, -unit * 0.10), Color("754544"), maxf(1, unit * 0.018), true)
	game.draw_line(point + Vector2(-unit * 0.055, -unit * 0.10), point + Vector2(unit * 0.055, -unit * 0.17), Color("754544"), maxf(1, unit * 0.018), true)
	Danmaku.draw_ofuda(game, point + Vector2(0, unit * 0.13), unit * 0.09, PI / 2, GREEN)
	var ratio := clampf(float(zombie.get("health", 1.0)) / maxf(1.0, float(zombie.get("max_health", 1.0))), 0, 1)
	var bar := Rect2(point + Vector2(-unit * 0.28, -unit * 0.36), Vector2(unit * 0.56, maxf(2, unit * 0.04)))
	game.draw_rect(bar, Color(0.08, 0.18, 0.15, 0.82))
	game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), GREEN)
