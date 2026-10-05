extends RefCounted

const KIND := "suika_boss"
const GOLD := Color("f6c974")
const PURPLE := Color("d49aef")
const WINE_FACTOR := 0.55
const MAX_POURS := 3
const MAX_IMPACTS := 12
const MAX_MINIS := 12
const MAX_CAPTURE := 8
const GOURD_PATH := "res://art/effects/suika_gourd.svg"

var game: Control
var pours: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var knots: Array[Dictionary] = []
var serial := 0

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	pours.clear()
	impacts.clear()
	knots.clear()
	serial = 0
	for z in game.zombies:
		if z.has("suika_parent"): z.health = 0.0

func clear_owner(owner: int) -> void:
	pours = pours.filter(func(p): return int(p.owner) != owner)
	impacts = impacts.filter(func(p): return int(p.owner) != owner)
	knots = knots.filter(func(p): return int(p.owner) != owner)
	for z in game.zombies:
		if int(z.get("suika_parent", -1)) == owner: z.health = 0.0

func boss_for(owner: int) -> Dictionary:
	for z in game.zombies:
		if int(z.uid) == owner and String(z.kind) == KIND and float(z.health) > 0.0: return z
	return {}

func queue_pour(owner: int, row: int, delay: float = 1.2, cols: Array = []) -> void:
	if pours.size() >= MAX_POURS or not game._is_row_active(row): return
	if pours.any(func(p): return int(p.row) == row): return
	pours.append({"owner": owner, "row": row, "age": 0.0, "delay": maxf(delay, 0.0), "travel": 1.4, "duration": 4.5, "cols": cols})

func queue_impact(owner: int, cell: Vector2i, kind: String, delay: float = 1.25) -> void:
	if impacts.size() >= MAX_IMPACTS or not game._is_row_active(cell.x) or cell.y < 0 or cell.y >= game.COLS: return
	if impacts.any(func(p): return p.cell == cell and not bool(p.hit)): return
	impacts.append({"owner": owner, "cell": cell, "kind": kind, "age": 0.0, "delay": maxf(delay, 0.8), "hit": false})

func spawn_mini(owner: int, row: int) -> void:
	if not game._is_row_active(row) or boss_for(owner).is_empty(): return
	var count := 0
	for z in game.zombies:
		if String(z.kind) == "suika_mini" and float(z.health) > 0: count += 1
	if count >= MAX_MINIS: return
	game._spawn_zombie_at("suika_mini", row, game._cell_center(row, game.COLS - 1).x, true)
	var unit: Dictionary = game.zombies.back()
	unit["suika_parent"] = owner
	unit["suika_lifetime"] = 12.0
	unit["spawn_time"] = 0.0

func cast(boss: Dictionary, pattern: String) -> void:
	clear_owner(int(boss.uid))
	serial += 1
	if game.active_rows.is_empty(): return
	var row := int(game.active_rows[posmod(serial * 2, game.active_rows.size())])
	match pattern:
		"suika_wine":
			queue_pour(int(boss.uid), row)
			game._show_toast("伊吹瓢将倾倒：茶／牛奶保护附近，大招清本行酒河")
		"suika_pea_knot":
			var point: Vector2 = game._cell_center(row, game.COLS - 3) + Vector2(0, -12)
			game._spawn_zombie_at("suika_knot", row, point.x, true)
			var unit: Dictionary = game.zombies.back()
			unit["suika_parent"] = int(boss.uid)
			unit["spawn_time"] = 0.0
			knots.append({"owner": int(boss.uid), "unit": int(unit.uid), "row": row, "position": point, "age": 0.0, "captured": 0, "released": false})
			game._show_toast("萃豆酒仓只收普通豌豆；打碎酒仓可取消鬼火反击")
		"suika_chain_banquet":
			for i in range(3):
				var lane := int(game.active_rows[posmod(row + i * 2, game.active_rows.size())])
				queue_impact(int(boss.uid), Vector2i(lane, 2 + i * 2), ["circle", "triangle", "square"][i], 1.4 + i * 0.45)
				queue_pour(int(boss.uid), lane, 2.1 + i * 0.45, [2 + i * 2])
		"suika_hundred_feasts":
			queue_pour(int(boss.uid), row, 1.3)
			queue_pour(int(boss.uid), int(game.active_rows[posmod(row + 2, game.active_rows.size())]), 3.2)

func protected_cell(row: int, col: int) -> bool:
	for r in range(maxi(0, row - 1), mini(game.ROWS, row + 2)):
		for c in range(maxi(0, col - 1), mini(game.COLS, col + 2)):
			for layer in [game.grid, game.support_grid]:
				var p = layer[r][c]
				if p == null or float(p.get("health", 0.0)) <= 0: continue
				if String(p.kind) in ["jasmine_tea", "golden_milk"]: return true
				for component in p.get("stats", {}).get("fusion_components", []):
					if String(component) in ["jasmine_tea", "golden_milk"]: return true
	return false

func action_factor(row: int, col: int) -> float:
	for p in pours:
		if int(p.row) != row or (not p.cols.is_empty() and not p.cols.has(col)): continue
		var arrival: float = float(p.delay) + float(p.travel) * (1.0 - (col + 0.5) / game.COLS)
		if float(p.age) >= arrival and float(p.age) < float(p.delay) + float(p.travel) + float(p.duration):
			if protected_cell(row, col): return 1.0
			var plant = game._targetable_plant_at(row, col)
			if plant != null and (float(plant.get("holy_invincible_timer", 0.0)) > 0 or bool(plant.get("ultimate_active", false))): return 1.0
			return WINE_FACTOR
	return 1.0

func cleanse_row(row: int) -> void:
	var count := pours.size()
	pours = pours.filter(func(p): return int(p.row) != row)
	if pours.size() < count:
		game._show_toast("大招冲散了本行酒河！")
		game.effects.append({"position": game._cell_center(row, 4), "radius": game.board_size.x * 0.48, "time": 0.35, "duration": 0.35, "color": Color(0.8, 1, 0.86, 0.25)})

func _unit(uid: int) -> Dictionary:
	for z in game.zombies:
		if int(z.uid) == uid and float(z.health) > 0: return z
	return {}

func _capture_eligible(shot: Dictionary) -> bool:
	if bool(shot.get("ultimate", false)) or bool(shot.get("empowered", false)) or bool(shot.get("plant_food", false)) or bool(shot.get("reflected", false)) or bool(shot.get("fire", false)) or bool(shot.get("free_aim", false)): return false
	if float(shot.get("damage", 0)) > 65.0 or float(shot.get("splash_radius", 0)) > 0 or shot.has("fusion_traits"): return false
	if String(shot.get("kind", "")) not in ["", "pea", "snow_pea"]: return false
	if String(shot.get("source_kind", "")) not in ["", "peashooter", "repeater", "threepeater", "split_pea", "snow_pea"]: return false
	if String(shot.get("shape", "pea")) != "pea" or bool(shot.get("lobbed", false)) or shot.has("target_position"): return false
	return float(shot.get("speed", Vector2(shot.get("velocity", Vector2(1, 0))).x)) > 0

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0: return
	var dt := maxf(delta, 0.0)
	for i in range(pours.size() - 1, -1, -1):
		var p: Dictionary = pours[i]
		p.age += dt
		if boss_for(int(p.owner)).is_empty() or float(p.age) >= float(p.delay) + float(p.travel) + float(p.duration): pours.remove_at(i)
	for i in range(impacts.size() - 1, -1, -1):
		var p: Dictionary = impacts[i]
		p.age += dt
		var boss := boss_for(int(p.owner))
		if boss.is_empty():
			impacts.remove_at(i)
			continue
		if bool(p.hit):
			if float(p.age) >= float(p.delay) + 0.65: impacts.remove_at(i)
			continue
		if float(p.age) < float(p.delay): continue
		p.hit = true
		var cell := Vector2i(p.cell)
		if String(p.kind) == "mini":
			spawn_mini(int(p.owner), cell.x)
			continue
		var damage := 140.0 if String(p.kind) == "stomp" else 115.0
		damage *= game.TouhouDifficulty.attack_damage(KIND, game.current_level, int(boss.get("boss_phase", 0)))
		game._damage_plant_cell(cell.x, cell.y, damage, 0.12, true)
		if String(p.kind) == "stomp": game._trigger_screen_shake(4.0)
		if String(p.kind) in ["circle", "triangle", "square"] and boss.has("touhou_owner"):
			var session := {"owner": int(boss.touhou_owner), "kind": KIND, "phase": int(boss.boss_phase), "wave": 0}
			var center: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, -12)
			var speed: float = minf(1, game.CELL_SIZE.x / 100.0) * 120.0
			if String(p.kind) == "circle":
				game._ensure_touhou_danmaku()._ring(session, center, 8, 0, speed, GOLD, "orb", {"arming_time": 0.3})
			else:
				var count := 3 if String(p.kind) == "triangle" else 4
				for n in range(count): game._ensure_touhou_danmaku()._fan(session, center, 3, TAU * n / count + PI, 0.25, speed, PURPLE, "suika_stone", {"arming_time": 0.3})
	for i in range(knots.size() - 1, -1, -1):
		var k: Dictionary = knots[i]
		k.age += dt
		var body := _unit(int(k.unit))
		if body.is_empty() or boss_for(int(k.owner)).is_empty():
			knots.remove_at(i)
			continue
		if float(k.age) >= 1.2 and float(k.age) < 4.8 and int(k.captured) < MAX_CAPTURE:
			for j in range(game.projectiles.size() - 1, -1, -1):
				var shot: Dictionary = game.projectiles[j]
				if int(k.captured) >= MAX_CAPTURE: break
				if int(shot.get("row", -1)) == int(k.row) and Vector2(shot.position).distance_to(k.position) < game.CELL_SIZE.x * 0.7 and _capture_eligible(shot):
					game.projectiles.remove_at(j)
					k.captured += 1
		if float(k.age) >= 6.0 and not bool(k.released):
			k.released = true
			var boss := boss_for(int(k.owner))
			if boss.has("touhou_owner"):
				var session := {"owner": int(boss.touhou_owner), "kind": KIND, "phase": int(boss.boss_phase), "wave": 0}
				game._ensure_touhou_danmaku()._fan(session, k.position, maxi(3, int(k.captured)), PI, 1.25, 155.0, PURPLE, "suika_fire", {"arming_time": 0.25})
		if float(k.age) >= 6.6:
			body.health = 0.0
			knots.remove_at(i)
	for z in game.zombies:
		if not z.has("suika_parent") or String(z.kind) != "suika_mini": continue
		z.suika_lifetime = float(z.get("suika_lifetime", 12.0)) - dt
		if float(z.suika_lifetime) <= 0 or boss_for(int(z.suika_parent)).is_empty(): z.health = 0.0

func frame_index(boss: Dictionary) -> int:
	var pose := String(boss.get("rumia_state", "idle"))
	var frames: Array = [0, 1, 2, 1]
	match pose:
		"shot": frames = [6, 7, 11, 7]
		"shift": frames = [3, 4, 5, 4]
		"throw", "gourd": frames = [6, 7, 8, 9, 10, 11]
		"fire", "density", "mist": frames = [12, 13, 14, 13]
		"giant": frames = [18, 19, 20, 19]
		"final": frames = [18, 19, 20, 14]
	if float(boss.get("flash", 0.0)) > 0.1 and float(boss.get("touhou_cast_remaining", 0.0)) <= 0.0: frames = [21, 22, 23]
	return int(frames[posmod(int(float(boss.get("animation_time", game.level_time)) * 7), frames.size())])

func draw_boss(center: Vector2, boss: Dictionary, mini: bool = false) -> void:
	var texture: Texture2D = game._try_get_boss_frame_texture(KIND, frame_index(boss))
	if texture == null: return
	var scale: float = game._touhou_boss_draw_scale(KIND) * (0.38 if mini else 1.0)
	var pattern := String(boss.get("touhou_card", {}).get("pattern", ""))
	if not mini and pattern == "suika_giant" and float(boss.get("touhou_cast_remaining", 0)) > 0:
		var elapsed := float(boss.get("touhou_cast_duration", 0)) - float(boss.get("touhou_cast_remaining", 0))
		var end := minf(1.0, float(boss.touhou_cast_remaining) / 0.7)
		scale *= 1.0 + 0.78 * smoothstep(0, 1.0, elapsed) * end
	var alpha := 0.42 if pattern == "suika_mist" and float(boss.get("touhou_cast_remaining", 0)) > 0 else 1.0
	var extent := texture.get_size() * scale
	# Feet remain fixed as Missing Power grows, using the same original poses.
	var top := -319.0 * scale + 28.0
	game.draw_texture_rect(texture, Rect2(center + Vector2(-extent.x * 0.5, top), extent), false, Color(1, 0.86, 0.88, alpha) if float(boss.get("flash", 0)) > 0 else Color(1, 1, 1, alpha))

func draw_knot(center: Vector2, body: Dictionary) -> void:
	var captured := 0
	var age := 0.0
	for k in knots:
		if int(k.unit) == int(body.uid):
			captured = int(k.captured)
			age = float(k.age)
	var radius := 24.0 + captured * 1.2
	game.draw_circle(center + Vector2(0, -12), radius, Color(0.19, 0.08, 0.28, 0.85))
	game.draw_arc(center + Vector2(0, -12), radius, -PI / 2, -PI / 2 + TAU * clampf(float(body.health) / float(body.max_health), 0, 1), 32, GOLD, 3, true)
	for i in range(maxi(3, captured)):
		var pos := center + Vector2(0, -12) + Vector2.from_angle(age * 2 + i * TAU / maxi(3, captured)) * radius * 0.65
		game.draw_circle(pos, 5, Color("a7dd86"))
	if age >= 4.8: game.draw_arc(center + Vector2(0, -12), radius + 7, 0, TAU, 32, Color(GOLD, 0.55 + 0.4 * sin(age * 10)), 2, true)

func draw_background() -> void:
	if not bool(game.current_level.get("suika_banquet", false)): return
	var scene := Rect2(Vector2.ZERO, game.size)
	game.draw_rect(scene, Color(0.10, 0.03, 0.23, 0.30))
	var moon := Vector2(game.size.x * 0.74, game.BOARD_ORIGIN.y * 0.23)
	game.draw_circle(moon, maxf(8, game.CELL_SIZE.x * 0.27), Color(1, 0.87, 0.69, 0.76))
	for i in range(9):
		var pos := Vector2(game.BOARD_ORIGIN.x + game.board_size.x * i / 8, game.BOARD_ORIGIN.y - game.CELL_SIZE.y * 0.15)
		game.draw_circle(pos, game.CELL_SIZE.x * 0.1, Color(1, 0.64, 0.28, 0.13))
		game.draw_circle(pos, game.CELL_SIZE.x * 0.035, Color(1, 0.72, 0.4, 0.75))

func draw_ground() -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	for p in pours:
		var row := int(p.row)
		var rect := Rect2(Vector2(game.BOARD_ORIGIN.x, game._row_center_y(row) - game.CELL_SIZE.y * 0.44), Vector2(game.board_size.x, game.CELL_SIZE.y * 0.88))
		var age := float(p.age)
		if age < float(p.delay):
			game.draw_rect(rect.grow(-3), Color(GOLD, 0.07 + 0.04 * sin(age * 8)))
			game.draw_rect(rect.grow(-3), Color(GOLD, 0.75), false, 2.0, true)
			for col in range(game.COLS):
				if not p.cols.is_empty() and not p.cols.has(col): continue
				game.draw_arc(game._cell_center(row, col), unit * 0.25, -PI / 2, -PI / 2 + TAU * age / maxf(0.1, float(p.delay)), 24, GOLD, 1.5, true)
			continue
		var left := rect.end.x - rect.size.x * clampf((age - float(p.delay)) / float(p.travel), 0, 1)
		for col in range(game.COLS):
			if not p.cols.is_empty() and not p.cols.has(col): continue
			var cell: Rect2 = game._cell_rect(row, col).grow(-4)
			if cell.end.x < left: continue
			cell.position.x = maxf(cell.position.x, left)
			cell.size.x = maxf(0, game._cell_rect(row, col).end.x - 4 - cell.position.x)
			game.draw_rect(cell, Color(0.93, 0.57, 0.19, 0.22))
			for band in range(3):
				var yy := cell.position.y + cell.size.y * (0.28 + band * 0.2) + sin(age * 4 + col + band) * unit * 0.035
				game.draw_line(Vector2(cell.position.x, yy), Vector2(cell.end.x, yy), Color(GOLD, 0.35), 1.5, true)
	for p in impacts:
		var center: Vector2 = game._cell_center(p.cell.x, p.cell.y)
		var radius := unit * (0.40 if String(p.kind) == "stomp" else 0.30)
		var progress := clampf(float(p.age) / float(p.delay), 0, 1)
		var tint := PURPLE if String(p.kind) == "mini" else GOLD
		game.draw_circle(center, radius, Color(tint, 0.06 if not bool(p.hit) else 0.17))
		game.draw_arc(center, radius, -PI / 2, -PI / 2 + TAU * progress, 32, Color(tint, 0.85), 2.0, true)
		if String(p.kind) in ["triangle", "square"]:
			var poly := PackedVector2Array()
			var count := 3 if String(p.kind) == "triangle" else 4
			for i in range(count): poly.append(center + Vector2.from_angle(-PI / 2 + i * TAU / count) * radius)
			poly.append(poly[0])
			game.draw_polyline(poly, Color(tint, 0.8), 2, true)

func draw_overlay() -> void:
	var unit: float = minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	if game.touhou_danmaku != null:
		var wells: Array = []
		for b in game.touhou_danmaku.bullets:
			if not b.has("suika_orbit") or float(b.age) >= float(b.get("release_at", 0)): continue
			var point := Vector2(b.suika_orbit)
			if wells.has(point) or wells.size() >= 6: continue
			wells.append(point)
			game.draw_circle(point, unit * 0.18, Color(0.08, 0.025, 0.15, 0.78))
			for ring in range(3):
				var radius := unit * (0.24 + ring * 0.13)
				var angle: float = game.level_time * (1.6 + ring * 0.4)
				game.draw_arc(point, radius, angle, angle + PI * 1.6, 28, Color(PURPLE, 0.6 - ring * 0.12), 2, true)
		for c in game.touhou_danmaku.casts:
			if String(c.kind) != KIND or String(c.pattern) != "suika_mist": continue
			for row in game.active_rows:
				var y: float = game._row_center_y(int(row))
				for i in range(4):
					var x: float = game.BOARD_ORIGIN.x + game.board_size.x * fposmod(i * 0.27 - float(c.age) * 0.04, 1.0)
					game.draw_circle(Vector2(x, y + sin(i + float(c.age)) * unit * 0.15), unit * 0.55, Color(PURPLE, 0.055))
	for p in impacts:
		if String(p.kind) == "stomp" and bool(p.hit):
			var point: Vector2 = game._cell_center(p.cell.x, p.cell.y)
			for i in range(5):
				var end := point + Vector2.from_angle(TAU * i / 5) * unit * 0.43
				game.draw_line(point, end, Color(0.09, 0.05, 0.16, 0.8), 2, true)
			continue
		if String(p.kind) != "rock" or bool(p.hit): continue
		var center: Vector2 = game._cell_center(p.cell.x, p.cell.y)
		var progress := clampf(float(p.age) / float(p.delay), 0, 1)
		center.y -= (1 - progress * progress) * unit * 1.5
		var r := unit * 0.26
		var rock := PackedVector2Array([center + Vector2(-r, -r * 0.3), center + Vector2(-r * 0.45, -r), center + Vector2(r * 0.7, -r * 0.8), center + Vector2(r, r * 0.2), center + Vector2(r * 0.4, r * 0.65), center + Vector2(-r * 0.85, r * 0.55)])
		game.draw_colored_polygon(rock, Color("777783"))
		game.draw_line(center - Vector2(r * 0.4, r * 0.75), center + Vector2(r * 0.5, -r * 0.45), Color("c7bcbb"), 2, true)
	for p in pours:
		var age := float(p.age)
		var scale := unit / 100.0
		var growth := lerpf(0.35, 1.0, smoothstep(0, maxf(0.1, float(p.delay)), age))
		var tilt := -PI * 0.42 * smoothstep(float(p.delay) * 0.6, float(p.delay) + 0.35, age)
		var center := Vector2(game.BOARD_ORIGIN.x + game.board_size.x - unit * 1.3, game._row_center_y(int(p.row)) - unit * 0.55)
		var texture: Texture2D = game._load_polished_texture(GOURD_PATH)
		if texture != null and age < float(p.delay) + 2.2:
			game.draw_set_transform(center + game.combat_draw_offset, tilt, Vector2.ONE * scale * growth * 0.8)
			game.draw_texture_rect(texture, Rect2(Vector2(-84, -160), Vector2(168, 218)), false)
			game._set_combat_transform()
			if age >= float(p.delay):
				var mouth := center + Vector2(-1, -142).rotated(tilt) * scale * growth * 0.8
				var landing := Vector2(center.x - unit * 0.9, game._row_center_y(int(p.row)) + unit * 0.1)
				game.draw_line(mouth, landing, Color(GOLD, 0.7), maxf(2, unit * 0.07), true)
				game.draw_circle(landing, unit * 0.12, Color(GOLD, 0.35))
	for row in game.active_rows:
		for col in range(game.COLS):
			if action_factor(int(row), col) >= 1.0 or game._targetable_plant_at(int(row), col) == null: continue
			var pos: Vector2 = game._cell_center(int(row), col) + Vector2(0, -unit * 0.38)
			for i in range(3):
				var point := pos + Vector2(sin(game.level_time * 3 + i * 2) * unit * 0.15, -i * unit * 0.07)
				game.draw_circle(point, unit * 0.028, Color(GOLD, 0.78), false, 1.0, true)
