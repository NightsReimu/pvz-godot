extends "res://scripts/runtime/touhou_danmaku_runtime.gd"

# Frozen collision/motion paths at 9d6aac73, before dense-barrage optimization.
# Live helpers and character motion stay shared so strength changes do not
# contaminate the performance or same-trajectory semantic comparison.

func _tick_bullets(delta: float, owners: Dictionary, focused_owners: Dictionary = {}) -> void:
	var board: Rect2 = Rect2(game.BOARD_ORIGIN, game.board_size)
	for index in range(bullets.size() - 1, -1, -1):
		var b = bullets[index]
		if not owners.has(int(b.owner)):
			bullets.remove_at(index)
			continue
		if game.boss_time_stop_timer > 0.0:
			continue
		var before = Vector2(b.position)
		b["slowed"] = focused_owners.has(int(b.owner))
		var motion_delta = delta * (0.35 if bool(b.slowed) else 1.0)
		b.age += delta
		if bool(b.get("reflected", false)):
			b["reflect_age"] = float(b.get("reflect_age", 0.0)) + delta
			b["reflect_flash"] = maxf(0.0, float(b.get("reflect_flash", 0.0)) - delta)
		var age = float(b.age)
		var frozen = b.has("freeze_at") and age >= float(b.freeze_at) and age < float(b.thaw_at)
		if not frozen:
			if b.has("thaw_at") and age >= float(b.thaw_at) and not bool(b.get("thawed", false)):
				b.velocity = _rotate_bullet_velocity(b, float(b.get("thaw_angle", 0.0)))
				b["thawed"] = true
			if float(b.get("redirect_at", 0.0)) > 0.0 and age >= float(b.redirect_at) and not bool(b.get("redirected", false)):
				if b.has("autumn_axes") and not bool(b.get("reflected", false)):
					var axes := Vector2(b.autumn_axes)
					b.velocity = ((Vector2(b.aim_point) - before) / axes).normalized() * (Vector2(b.velocity) / axes).length() * axes
				else:
					b.velocity = (Vector2(b.aim_point) - before).normalized() * Vector2(b.velocity).length()
				b["redirected"] = true
			b.velocity = _rotate_bullet_velocity(b, float(b.get("angular_speed", 0.0)) * motion_delta)
			b.position = before + Vector2(b.velocity) * motion_delta
		b["frozen"] = frozen
		var point = Vector2(b.position)
		if int(b.get("bounces", 0)) > 0 and (point.y < board.position.y + 5 or point.y > board.end.y - 5):
			b.position.y = clampf(point.y, board.position.y + 5, board.end.y - 5)
			b.velocity.y *= -1
			b.bounces -= 1
		if String(b.kind) == "suika_boss":
			before = SuikaDanmaku.advance_bullet(self, b, before)
		elif String(b.kind) == "reimu_boss":
			before = ReimuDanmaku.advance_bullet(b, before, motion_delta)
		elif String(b.kind) == "marisa_boss":
			before = MarisaDanmaku.advance_bullet(b, before, motion_delta)
		elif String(b.kind) == "reisen_boss":
			before = ReisenDanmaku.advance_bullet(b, before)
		if String(b.kind) == "mokou_boss":
			MokouDanmaku.advance_bullet(b, motion_delta)
		var hit := false
		if age >= float(b.get("arming_time", 0.0)) and not bool(b.get("reisen_phantom", false)):
			if bool(b.get("reflected", false)):
				# Already bounced: it now travels back out and bites every zombie it crosses.
				_hit_zombie_segment(before, Vector2(b.position), float(b.radius), float(b.damage), b)
			else:
				var mirror_cell: Vector2i = game._mirror_reed_on_segment(before, Vector2(b.position), float(b.radius))
				if mirror_cell.y >= 0 and game._bounce_boss_danmaku(b, mirror_cell):
					hit = false
				else:
					hit = _hit_plant_segment(before, Vector2(b.position), float(b.radius), float(b.damage), [])
		if hit or age >= float(b.life) or not board.grow(240).has_point(Vector2(b.position)):
			bullets.remove_at(index)


func _hit_zombie_segment(from: Vector2, to: Vector2, radius: float, damage: float, bullet: Dictionary) -> void:
	# Reflected danmaku damages each zombie it passes through, once per zombie.
	var hits: Array = bullet.get("hit_uids", [])
	var reach := radius + 24.0
	for zombie_variant in game.zombies:
		var zombie: Dictionary = zombie_variant
		if not game._is_enemy_zombie(zombie) or float(zombie.get("health", 0.0)) <= 0.0:
			continue
		var uid := int(zombie.get("uid", -1))
		if hits.has(uid):
			continue
		var center := Vector2(float(zombie.get("x", 0.0)), game._row_center_y(int(zombie.get("row", 0))) - 12.0)
		var closest = Geometry2D.get_closest_point_to_segment(center, from, to)
		if closest.distance_squared_to(center) > reach * reach:
			continue
		hits.append(uid)
		game._apply_zombie_damage(zombie, damage, 0.18)
		zombie["revealed_timer"] = maxf(float(zombie.get("revealed_timer", 0.0)), 1.4)
	bullet["hit_uids"] = hits


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
	# Collision centers are at cell center minus 12px, not at tile edges.
	# Derive candidate bounds from those centers, also rejecting off-board shots.
	var min_col := maxi(0, ceili((min_x - game.BOARD_ORIGIN.x) / game.CELL_SIZE.x - 0.5))
	var max_col := mini(game.COLS - 1, floori((max_x - game.BOARD_ORIGIN.x) / game.CELL_SIZE.x - 0.5))
	var min_row := maxi(0, ceili((min_y + 12 - game.BOARD_ORIGIN.y) / game.CELL_SIZE.y - 0.5))
	var max_row := mini(game.ROWS - 1, floori((max_y + 12 - game.BOARD_ORIGIN.y) / game.CELL_SIZE.y - 0.5))
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
			# A mirror reed bounces boss danmaku back instead of being damaged by it.
			if String(plant.get("kind", "")) == "mirror_reed" and game._mirror_reed_reflect_boss_shot(cell, damage):
				hit_cells.append(cell)
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
