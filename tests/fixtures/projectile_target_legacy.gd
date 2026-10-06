extends "res://tests/fixtures/touhou_damage_game.gd"

# Frozen v178 native endpoint target lookup. Deliberately retains its corpse
# behavior: that separate correctness fix is tested independently of parity.
var enemy_checks := 0
var point_checks := 0
func _is_enemy_zombie(zombie: Dictionary) -> bool:
	enemy_checks += 1
	return super._is_enemy_zombie(zombie)
func _zombie_hit_positions(zombie: Dictionary) -> Array[Vector2]:
	point_checks += 1
	return super._zombie_hit_positions(zombie)
func reset_target_counters() -> void:
	enemy_checks = 0
	point_checks = 0

func legacy_find_projectile_target(projectile: Dictionary) -> int:
	var best_index = -1
	var best_distance = 999999.0
	var projectile_pos = Vector2(projectile["position"])
	var projectile_radius = float(projectile.get("radius", 8.0))
	var free_aim = bool(projectile.get("free_aim", false))
	var anti_air = bool(projectile.get("anti_air", false))
	var ignore_lane_hide = bool(projectile.get("ignore_lane_hide", false))
	var moving_left = float(projectile.get("speed", 0.0)) < 0.0
	var ignored_uids: Array = projectile.get("hit_uids", [])
	for i in range(zombies.size()):
		var zombie = zombies[i]
		var hidden = _is_hidden_from_lane_attacks(zombie)
		var can_ignore_hidden = ignore_lane_hide and not _is_hidden_for_direct_fire_ignoring_fog(zombie)
		if ((hidden and not can_ignore_hidden and not (anti_air and bool(zombie.get("balloon_flying", false)))) or not _is_enemy_zombie(zombie)):
			continue
		if bool(zombie.get("balloon_flying", false)) and not anti_air:
			continue
		if ignored_uids.has(int(zombie.get("uid", -1))):
			continue
		for point in _zombie_hit_positions(zombie):
			if free_aim:
				if absf(point.y - projectile_pos.y) > 24.0:
					continue
			elif absf(point.y - _row_center_y(int(projectile.row))) > 1.0:
				continue
			var distance: float = projectile_pos.x - point.x if moving_left else point.x - projectile_pos.x
			if distance < -20.0 or distance > 20.0 + projectile_radius:
				continue
			if distance < best_distance:
				best_distance = distance
				best_index = i
	return best_index
