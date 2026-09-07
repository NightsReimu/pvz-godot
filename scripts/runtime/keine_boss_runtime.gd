extends RefCounted

const KIND := "keine_boss"
const BAMBOO := "keine_bamboo"
const SUMMON_LIMIT := 6
const STEP := 1.0 / 60.0
const INK := Color("e45cb3")
const JADE := Color("9adfa7")
const GOLD := Color("f1ce7e")

var game: Control
var attacks: Array[Dictionary] = []
var shots: Array[Dictionary] = []


func _init(owner: Control) -> void:
	game = owner


func reset() -> void:
	attacks.clear()
	shots.clear()


func clear_owner(uid: int) -> void:
	attacks = attacks.filter(func(a): return int(a.owner) != uid)
	shots = shots.filter(func(s): return int(s.owner) != uid and int(s.get("boss_owner", -1)) != uid)
	for unit in game.zombies:
		if String(unit.kind) == BAMBOO and int(unit.get("keine_owner", -1)) == uid:
			unit.health = 0.0


func cancel_cast(uid: int) -> void:
	attacks = attacks.filter(func(a): return int(a.owner) != uid)
	shots = shots.filter(func(s): return int(s.owner) != uid)


func cast(boss: Dictionary, pattern: String) -> void:
	var uid := int(boss.get("uid", -1))
	var phase := int(boss.get("boss_phase", 0))
	var center := Vector2(float(boss.x), game._row_center_y(int(boss.row)) - 12.0)
	cancel_cast(uid)
	match pattern:
		"keine_whip":
			attacks.append({"kind": "whip", "owner": uid, "center": center, "age": 0.0, "delay": 1.15, "duration": 3.4, "radius": game.CELL_SIZE.x * (2.65 + phase * 0.15), "phase": phase, "hits": []})
		"keine_piano":
			var rows: Array = game.active_rows.duplicate()
			rows.sort_custom(func(a, b): return _plant_count(int(a)) > _plant_count(int(b)))
			rows.resize(mini(2, rows.size()))
			attacks.append({"kind": "piano", "owner": uid, "center": center, "age": 0.0, "delay": 1.2, "duration": 3.4, "rows": rows, "wave": 0, "phase": phase})
		"keine_bamboo":
			queue_bamboo(boss, 2 + phase)


func _plant_count(row: int) -> int:
	var count := 0
	for col in range(game.COLS):
		if game._targetable_plant_at(row, col) != null:
			count += 1
	return count


func queue_bamboo(boss: Dictionary, count: int) -> void:
	var occupied: Array[Vector2i] = []
	for unit in game.zombies:
		if String(unit.kind) == BAMBOO and float(unit.health) > 0.0:
			occupied.append(Vector2i(int(unit.row), game._zombie_cell_col(float(unit.x))))
	for attack in attacks:
		if String(attack.kind) == "summon":
			occupied.append(attack.cell)
	var candidates: Array[Vector2i] = []
	for row in game.active_rows:
		for col in range(5, game.COLS):
			var cell := Vector2i(int(row), col)
			if not occupied.has(cell) and game._targetable_plant_at(cell.x, cell.y) == null:
				candidates.append(cell)
	var remaining := mini(count, SUMMON_LIMIT - occupied.size())
	for index in range(maxi(0, remaining)):
		if candidates.is_empty():
			break
		var chosen: int = game.rng.randi_range(0, candidates.size() - 1)
		var cell := candidates[chosen]
		candidates.remove_at(chosen)
		attacks.append({"kind": "summon", "owner": int(boss.get("uid", -1)), "cell": cell, "age": 0.0, "delay": 1.35, "duration": 1.4, "phase": int(boss.get("boss_phase", 0)), "variant": index % 2})


func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0:
		return
	var remaining := maxf(0.0, delta)
	while remaining > 0.00001:
		var dt := minf(STEP, remaining)
		_tick(dt)
		remaining -= dt


func _tick(delta: float) -> void:
	var owners := {}
	for unit in game.zombies:
		if float(unit.health) > 0.0 and game._is_enemy_zombie(unit):
			owners[int(unit.get("uid", -1))] = unit
	for unit in game.zombies:
		if String(unit.kind) == BAMBOO and not owners.has(int(unit.get("keine_owner", -1))):
			unit.health = 0.0
	for index in range(attacks.size() - 1, -1, -1):
		var attack := attacks[index]
		attack.age += delta
		if not owners.has(int(attack.owner)) or float(attack.age) >= float(attack.duration):
			attacks.remove_at(index)
			continue
		if float(attack.age) < float(attack.delay):
			continue
		match String(attack.kind):
			"whip":
				for arm in range(3):
					var points := whip_points(attack, arm)
					for segment in range(1, points.size()):
						_hit_segment(points[segment - 1], points[segment], 7.0, 78.0 + int(attack.phase) * 14.0, attack.hits, 0.0, false)
			"piano":
				if int(attack.wave) < 3 and float(attack.age) >= float(attack.delay) + int(attack.wave) * 0.6:
					for row in attack.rows:
						var origin := Vector2(game.BOARD_ORIGIN.x + game.board_size.x - 12.0, game._row_center_y(int(row)) - 12.0)
						shots.append({"owner": attack.owner, "position": origin, "velocity": Vector2(-270, 0), "age": 0.0, "damage": 46.0 + int(attack.phase) * 7.0, "sleep": 2.2, "kind": "note", "color": GOLD})
					attack.wave += 1
			"summon":
				var cell := Vector2i(attack.cell)
				# A player may fill the warned square before the summon completes.
				if game._targetable_plant_at(cell.x, cell.y) == null:
					game._spawn_zombie_at(BAMBOO, cell.x, game._cell_center(cell.x, cell.y).x, true)
					var bamboo: Dictionary = game.zombies.back()
					bamboo["keine_owner"] = attack.owner
					bamboo["bamboo_variant"] = attack.variant
					bamboo["bamboo_life"] = 24.0
					bamboo["bamboo_cooldown"] = 1.5
					bamboo["keine_phase"] = attack.phase
				attacks.remove_at(index)
	for index in range(shots.size() - 1, -1, -1):
		var shot := shots[index]
		if not owners.has(int(shot.owner)) or not owners.has(int(shot.get("boss_owner", shot.owner))):
			shots.remove_at(index)
			continue
		var before := Vector2(shot.position)
		shot.age += delta
		shot.position += Vector2(shot.velocity) * delta
		var hit := _hit_segment(before, shot.position, 7.0, float(shot.damage), [], float(shot.get("sleep", 0.0)))
		if hit or float(shot.age) > 5.0 or not Rect2(game.BOARD_ORIGIN, game.board_size).grow(80).has_point(shot.position):
			shots.remove_at(index)


func update_bamboo(unit: Dictionary, delta: float) -> void:
	if float(unit.health) <= 0.0 or not game.zombies.any(func(b): return int(b.get("uid", -2)) == int(unit.get("keine_owner", -1)) and float(b.health) > 0.0):
		unit.health = 0.0
		return
	unit["bamboo_life"] = float(unit.get("bamboo_life", 24.0)) - delta
	if float(unit.bamboo_life) <= 0.0:
		unit.health = 0.0
		return
	if not game._is_enemy_zombie(unit) or float(unit.get("special_pause_timer", 0.0)) > 0.0 or float(unit.get("rooted_timer", 0.0)) > 0.0:
		return
	var pace := 0.5 if float(unit.get("slow_timer", 0.0)) > 0.0 else 1.0
	unit["bamboo_cooldown"] = float(unit.get("bamboo_cooldown", 1.5)) - delta * pace
	if float(unit.bamboo_cooldown) > 0.0:
		return
	unit.bamboo_cooldown = 3.8 if int(unit.get("bamboo_variant", 0)) == 1 else 2.8
	var origin := Vector2(float(unit.x), game._row_center_y(int(unit.row)) - 12.0)
	var target := origin + Vector2(-game.board_size.x, 0)
	var hits: Array = []
	if int(unit.get("bamboo_variant", 0)) == 1:
		_hit_segment(origin, target, 6.0, 56.0, hits, 0.0, false)
		game.effects.append({"shape": "line", "from": origin, "to": target, "position": origin, "radius": 38.0, "time": 0.26, "duration": 0.26, "color": JADE})
		unit["bamboo_strike_timer"] = 0.28
	else:
		shots.append({"owner": int(unit.uid), "boss_owner": int(unit.get("keine_owner", -1)), "position": origin, "velocity": Vector2(-235, 0), "age": 0.0, "damage": 42.0, "kind": "leaf", "color": JADE})


func _hit_segment(from: Vector2, to: Vector2, radius: float, damage: float, hits: Array, sleep: float = 0.0, first_only: bool = true) -> bool:
	var candidates: Array[Dictionary] = []
	for row in game.active_rows:
		for col in range(game.COLS):
			var cell := Vector2i(int(row), col)
			var plant = game._targetable_plant_at(cell.x, cell.y)
			if plant == null or float(plant.get("health", 0.0)) <= 0.0 or hits.has(cell):
				continue
			var point: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, -12)
			var nearest := Geometry2D.get_closest_point_to_segment(point, from, to)
			if nearest.distance_to(point) <= radius + minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 0.22:
				candidates.append({"cell": cell, "distance": from.distance_squared_to(point)})
	candidates.sort_custom(func(a, b): return float(a.distance) < float(b.distance))
	for candidate in candidates:
		var cell := Vector2i(candidate.cell)
		game._damage_plant_cell(cell.x, cell.y, damage, 0.8 if sleep == 0.0 else sleep)
		var plant = game._targetable_plant_at(cell.x, cell.y)
		if sleep > 0.0 and plant != null and float(plant.get("holy_invincible_timer", 0.0)) <= 0.0:
			plant["sleep_timer"] = maxf(float(plant.get("sleep_timer", 0.0)), sleep)
		hits.append(cell)
		if first_only:
			break
	return not candidates.is_empty()


func whip_points(attack: Dictionary, arm: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var rotation := maxf(0.0, float(attack.age) - float(attack.delay)) * 2.65 + arm * TAU / 3.0
	for index in range(17):
		var progress := float(index) / 16.0
		var angle := rotation - (1.0 - progress) * 1.15
		points.append(Vector2(attack.center) + Vector2.from_angle(angle) * float(attack.radius) * progress)
	return points


func frame_index(boss: Dictionary) -> int:
	var pose := String(boss.get("rumia_state", "idle"))
	var sequence: Array = [0, 1, 2, 3, 2, 1]
	match pose:
		"shift": sequence = [12, 13, 14, 15, 12]
		"history": sequence = [4, 5, 7, 8, 7, 5]
		"edict", "whip": sequence = [4, 5, 6, 7, 8, 7]
		"treasures", "bamboo": sequence = [9, 10, 11, 10, 9, 16]
		"piano": sequence = [9, 16, 17, 16, 9, 10]
		"emperor": sequence = [18, 19, 20, 19, 22, 19]
		"final", "phase": sequence = [20, 21, 22, 23, 22, 21]
	var elapsed := float(game.level_time)
	if float(boss.get("touhou_cast_duration", 0.0)) > 0.0 and pose != "idle":
		elapsed = float(boss.touhou_cast_duration) - float(boss.get("touhou_cast_remaining", 0.0))
	return int(sequence[posmod(int(floor(elapsed * 7.0)), sequence.size())])


func draw_boss(center: Vector2, boss: Dictionary) -> void:
	var texture: Texture2D = game._try_get_boss_frame_texture(KIND, frame_index(boss))
	if texture == null:
		return
	var scale := 0.72
	var extent := texture.get_size() * scale
	game.draw_texture_rect(texture, Rect2(center + Vector2(-extent.x * 0.5, -extent.y * 0.72), extent), false)
	var seal := center + Vector2(0, -35)
	for index in range(8):
		var angle: float = game.level_time * 0.55 + index * TAU / 8.0
		var point := seal + Vector2(cos(angle) * 85, sin(angle) * 33)
		var corners := PackedVector2Array()
		for corner in [Vector2(-3, -7), Vector2(3, -7), Vector2(3, 7), Vector2(-3, 7), Vector2(-3, -7)]:
			corners.append(point + corner.rotated(angle * 0.25))
		game.draw_polyline(corners, Color(INK, 0.7), 1.2, true)


func draw_bamboo(center: Vector2, unit: Dictionary) -> void:
	var pressure := int(unit.get("bamboo_variant", 0)) == 1
	game._draw_spiral_bamboo(center, 1.25 if pressure else 1.05, float(unit.get("flash", 0.0)))
	game.draw_arc(center + Vector2(0, -12), 34, game.level_time, game.level_time + TAU * 0.85, 24, INK, 2.5)
	game.draw_line(center + Vector2(-5, -24), center + Vector2(-1, -21), Color("ff4466"), 3)
	game.draw_line(center + Vector2(5, -24), center + Vector2(1, -21), Color("ff4466"), 3)
	var ratio := clampf(float(unit.get("health", 1.0)) / maxf(1.0, float(unit.get("max_health", 1.0))), 0.0, 1.0)
	game.draw_rect(Rect2(center + Vector2(-22, 42), Vector2(44, 4)), Color("1b1022"))
	game.draw_rect(Rect2(center + Vector2(-22, 42), Vector2(44 * ratio, 4)), INK)
	if pressure:
		game.draw_arc(center + Vector2(0, -12), 39, -PI / 2, -PI / 2 + TAU * (1.0 - clampf(float(unit.get("bamboo_cooldown", 0.0)) / 3.8, 0, 1)), 32, GOLD, 2.0)


func draw_overlay() -> void:
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var outline := PackedVector2Array([board.position, Vector2(board.end.x, board.position.y), board.end, Vector2(board.position.x, board.end.y)])
	for unit in game.zombies:
		if String(unit.kind) != BAMBOO or float(unit.health) <= 0.0 or not game._is_enemy_zombie(unit):
			continue
		if int(unit.get("bamboo_variant", 0)) == 1:
			var start := Vector2(float(unit.x), game._row_center_y(int(unit.row)) - 12)
			var finish := Vector2(game.BOARD_ORIGIN.x, start.y)
			var timer := float(unit.get("bamboo_cooldown", 1.5))
			if timer < 1.0:
				game.draw_line(start, finish, Color(JADE, 0.18 + (1.0 - timer) * 0.35), 2.0, true)
			elif timer > 3.52:
				game.draw_line(start, finish, Color(JADE, (timer - 3.52) / 0.28), 5.0, true)
	for attack in attacks:
		var warning := float(attack.age) < float(attack.delay)
		match String(attack.kind):
			"whip":
				var center := Vector2(attack.center)
				var perimeter := PackedVector2Array()
				for point in range(97):
					perimeter.append(center + Vector2.from_angle(point * TAU / 96.0) * float(attack.radius))
				for segment in Geometry2D.intersect_polyline_with_polygon(perimeter, outline):
					game.draw_polyline(segment, Color(INK, 0.5 if warning else 0.18), 2.0, true)
				for arm in range(3):
					var points := whip_points(attack, arm)
					for segment in Geometry2D.intersect_polyline_with_polygon(points, outline):
						game.draw_polyline(segment, Color(INK, 0.3), 11, true)
						game.draw_polyline(segment, Color(GOLD if warning else INK, 0.65 if warning else 1.0), 2 if warning else 3, true)
					for index in range(2, points.size(), 2):
						if board.has_point(points[index]):
							game.draw_circle(points[index], 2.0, Color("fff4d8"))
			"piano":
				_draw_piano(Vector2(attack.center) + Vector2(-28, 73), float(attack.age))
				for row in attack.rows:
					var y: float = game._row_center_y(int(row)) - 12
					for line in range(5):
						game.draw_line(Vector2(game.BOARD_ORIGIN.x, y + line * 5 - 10), Vector2(game.BOARD_ORIGIN.x + game.board_size.x, y + line * 5 - 10), Color(GOLD, 0.24 if warning else 0.12), 1, true)
			"summon":
				var point: Vector2 = game._cell_center(attack.cell.x, attack.cell.y)
				game.draw_rect(game._cell_rect(attack.cell.x, attack.cell.y).grow(-8), Color(INK, 0.12))
				game.draw_arc(point, 31 + sin(float(attack.age) * 8) * 3, 0, TAU, 32, INK, 2)
				game.draw_line(point + Vector2(-15, 0), point + Vector2(15, 0), JADE, 2)
	for shot in shots:
		var point := Vector2(shot.position)
		var color := Color(shot.color)
		game.draw_line(point, point + Vector2(24, 0), Color(color, 0.35), 4, true)
		if String(shot.kind) == "note":
			game.draw_circle(point, 5, color)
			game.draw_line(point + Vector2(4, 0), point + Vector2(4, -17), color, 2.5, true)
			game.draw_line(point + Vector2(4, -17), point + Vector2(12, -12), color, 2.5, true)
		else:
			game.draw_colored_polygon(PackedVector2Array([point + Vector2(-10, 0), point + Vector2(4, -6), point + Vector2(12, 0), point + Vector2(4, 6)]), color)


func _draw_piano(center: Vector2, age: float) -> void:
	game.draw_colored_polygon(PackedVector2Array([center + Vector2(-48, -22), center + Vector2(24, -45), center + Vector2(51, -22), center + Vector2(45, 18), center + Vector2(-48, 18)]), Color("191522"))
	game.draw_polyline(PackedVector2Array([center + Vector2(-48, -22), center + Vector2(24, -45), center + Vector2(51, -22)]), GOLD, 2, true)
	for key in range(12):
		var pressed := posmod(int(age * 7), 12) == key
		game.draw_rect(Rect2(center + Vector2(-43 + key * 7, -3 if pressed else -7), Vector2(6, 22)), GOLD if pressed else Color("f0ebdc"))
		if key % 7 in [0, 1, 3, 4, 5]:
			game.draw_rect(Rect2(center + Vector2(-38 + key * 7, -8), Vector2(4, 13)), Color("211929"))
	game.draw_line(center + Vector2(-36, 18), center + Vector2(-38, 35), Color("211929"), 5)
	game.draw_line(center + Vector2(33, 18), center + Vector2(36, 35), Color("211929"), 5)


func draw_background() -> void:
	game.draw_rect(Rect2(Vector2.ZERO, game.size), Color("070e13"))
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	game.draw_rect(Rect2(Vector2(0, board.position.y - 12), Vector2(game.size.x, game.size.y - board.position.y + 12)), Color("10251e"))
	var margin := maxf(64, game.size.x - board.end.x)
	var moon := Vector2(board.end.x + margin * 0.58, board.position.y + game.CELL_SIZE.y * 0.75)
	var radius := minf(62, margin * 0.3)
	game.draw_circle(moon, radius + 4, Color("4b646b"))
	game.draw_circle(moon, radius, Color("d9e3d2"))
	for crater in range(7):
		var angle := float(crater) * 2.4
		game.draw_circle(moon + Vector2.from_angle(angle) * radius * (0.2 + (crater % 3) * 0.19), radius * (0.07 + (crater % 2) * 0.04), Color("bdccbe"))
	for layer in range(3):
		var color: Color = [Color("112324"), Color("0c1c20"), Color("081317")][layer]
		for tree in range(18):
			var x := fmod(float(tree * 137 + layer * 61), game.size.x + 100) - 40
			var foot := Vector2(x, board.end.y + 60 + layer * 35)
			var tip := Vector2(x + sin(tree * 1.4) * 36, 10 + tree % 4 * 32)
			var width := float(10 + layer * 7)
			game.draw_colored_polygon(PackedVector2Array([foot + Vector2(-width, 0), tip + Vector2(-3, 0), tip + Vector2(4, 0), foot + Vector2(width, 0)]), color)
			for branch in range(5):
				var start := foot.lerp(tip, 0.45 + branch * 0.1)
				var end := start + Vector2((1 if (branch + tree) % 2 == 0 else -1) * (38 + branch * 11), -35 - branch * 8)
				game.draw_line(start, end, color, maxf(2, width * 0.4), true)
	# Tall segmented bamboo frames the grass without obscuring playable cells.
	for side in [0, 1]:
		for stalk in range(5):
			var x := board.position.x - 42 - stalk * 35 if side == 0 else board.end.x + 30 + stalk * 39
			x += sin(stalk * 4.7 + side * 2.3) * 11
			var bottom := game.size.y + 25.0
			var top := board.position.y - 80 + stalk % 3 * 32
			var lean := sin(stalk * 1.8 + side) * 24
			game.draw_line(Vector2(x, bottom), Vector2(x + lean, top), Color("183e30"), 10, true)
			game.draw_line(Vector2(x + 3, bottom), Vector2(x + lean + 3, top), Color("365d40"), 2, true)
			for joint in range(10):
				var pos := Vector2(x, bottom).lerp(Vector2(x + lean, top), float(joint) / 10)
				game.draw_line(pos + Vector2(-6, 0), pos + Vector2(6, 0), Color("486745"), 2, true)
				if joint % 2 == 1:
					for leaf in range(3):
						var direction := -1 if (joint + side) % 2 == 0 else 1
						var tip := pos + Vector2(direction * (25 + leaf * 13), -18 + leaf * 11)
						game.draw_colored_polygon(PackedVector2Array([pos, tip + Vector2(-direction * 9, -7), tip, pos + Vector2(4, 3)]), Color("294f38"))
	for stone in range(30):
		var pos := Vector2(board.position.x - 20 + stone * (board.size.x + 40) / 29, board.end.y + 18 + stone % 3 * 6)
		game.draw_colored_polygon(PackedVector2Array([pos + Vector2(-17, 3), pos + Vector2(-10, -8), pos + Vector2(12, -6), pos + Vector2(20, 5)]), Color("3e5044"))
	# Moonlit paths and drifting leaves stay outside the HUD.
	for leaf in range(22):
		var pos := Vector2(fmod(game.ui_time * (12 + leaf % 5 * 3) + leaf * 89, game.size.x), board.position.y + fmod(leaf * 43 + game.ui_time * 9, board.size.y + 70))
		game.draw_line(pos, pos + Vector2(7, -3 + sin(game.ui_time + leaf) * 4), Color(0.56, 0.7, 0.43, 0.35), 2, true)


func draw_ground() -> void:
	for row in game.active_rows:
		for col in range(game.COLS):
			var rect: Rect2 = game._cell_rect(int(row), col)
			for blade in range(4):
				var pos := rect.position + Vector2(12 + fmod(float(col * 17 + blade * 23), rect.size.x - 18), rect.size.y - 9 - blade % 2 * 8)
				game.draw_line(pos, pos + Vector2(sin(game.ui_time + blade + row) * 2, -5 - blade % 3), Color(0.42, 0.6, 0.35, 0.28), 1, true)
