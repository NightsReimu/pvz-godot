extends RefCounted
class_name ProjectileRuntime

const Defs = preload("res://scripts/game_defs.gd")
const AMBER_ARMORED_KINDS := {
	"conehead": true,
	"buckethead": true,
	"football": true,
	"dark_football": true,
	"screen_door": true,
	"newspaper": true,
	"basketball": true,
	"lifebuoy_cone": true,
	"lifebuoy_bucket": true,
	"qinghua": true,
	"barrel_screen_zombie": true,
	"ice_block": true,
	"janitor_zombie": true,
}

var game: Control


func _init(game_owner: Control) -> void:
	game = game_owner


func spawn_projectile(row: int, spawn_position: Vector2, projectile_color: Color, damage: float, slow_duration: float, speed: float = 460.0, radius: float = 8.0) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position))
	game.projectiles.append({
		"kind": "pea",
		"row": row,
		"position": spawn_position,
		"speed": speed,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
		"slow_duration": slow_duration,
		"color": projectile_color,
		"radius": radius,
		"reflected": false,
		"fire": false,
		"free_aim": false,
		"anti_air": false,
		"source_enhance_mult": damage_mult,
	})


func spawn_amber_projectile(row: int, spawn_position: Vector2, damage: float, speed: float = 480.0, radius: float = 8.5) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "amber_shooter"))
	game.projectiles.append({
		"kind": "amber_pea",
		"row": row,
		"position": spawn_position,
		"speed": speed,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
		"slow_duration": 0.0,
		"color": Color(0.96, 0.66, 0.18),
		"radius": radius,
		"reflected": false,
		"fire": false,
		"free_aim": false,
		"anti_air": false,
		"source_enhance_mult": damage_mult,
		"armor_bonus_mult": 2.0,
	})


func spawn_fire_projectile(row: int, spawn_position: Vector2, damage: float, speed: float = 500.0, radius: float = 9.0) -> void:
	spawn_projectile(row, spawn_position, Color(1.0, 0.54, 0.18), damage, 0.0, speed, radius)
	if not game.projectiles.is_empty():
		game.projectiles[game.projectiles.size() - 1]["fire"] = true


func find_zombie_index_by_uid(uid: int) -> int:
	for i in range(game.zombies.size()):
		if int(game.zombies[i].get("uid", -1)) == uid:
			return i
	return -1


func _is_amber_armored_target(zombie: Dictionary) -> bool:
	if float(zombie.get("shield_health", 0.0)) > 0.0:
		return true
	return bool(AMBER_ARMORED_KINDS.get(String(zombie.get("kind", "")), false))


func _projectile_hit_damage(projectile: Dictionary, zombie: Dictionary) -> float:
	var damage = float(projectile.get("damage", 0.0))
	if String(projectile.get("kind", "")) == "amber_pea" and _is_amber_armored_target(zombie):
		damage *= float(projectile.get("armor_bonus_mult", 2.0))
	return damage


func _emit_amber_impact(impact_position: Vector2, armored: bool) -> void:
	game.effects.append({
		"shape": "amber_splash",
		"position": impact_position,
		"radius": 62.0 if armored else 50.0,
		"time": 0.2,
		"duration": 0.2,
		"color": Color(1.0, 0.72, 0.24, 0.32) if armored else Color(0.96, 0.66, 0.22, 0.26),
		"anim_speed": 6.6 if armored else 5.6,
	})


func _apply_boomerang_damage(zombie: Dictionary, damage: float, flash_amount: float = 0.12) -> Dictionary:
	var shield_health = float(zombie.get("shield_health", 0.0))
	if shield_health > 0.0:
		return game._apply_zombie_damage(zombie, minf(damage, shield_health), flash_amount)
	return game._apply_zombie_damage(zombie, damage, flash_amount)


func apply_fire_projectile_splash(row: int, center_x: float, damage: float, skip_index: int) -> void:
	var splash_radius = 48.0
	for i in range(game.zombies.size()):
		if i == skip_index:
			continue
		var zombie = game.zombies[i]
		if int(zombie["row"]) != row or not game._is_enemy_zombie(zombie):
			continue
		if absf(float(zombie["x"]) - center_x) > splash_radius:
			continue
		zombie = game._apply_zombie_damage(zombie, damage, 0.1)
		game.zombies[i] = zombie
	game.effects.append({
		"position": Vector2(center_x, game._row_center_y(row)),
		"radius": splash_radius,
		"time": 0.2,
		"duration": 0.2,
		"color": Color(1.0, 0.52, 0.18, 0.24),
	})


func spawn_sakura_split_projectiles(projectile: Dictionary, impact_position: Vector2) -> void:
	var child_damage = maxf(6.0, float(projectile.get("damage", 0.0)) * 0.78)
	var split_speed = float(projectile.get("split_speed", float(Defs.PLANTS["sakura_shooter"]["split_speed"])))
	for velocity_y in [-split_speed, split_speed]:
		game.projectiles.append({
			"kind": "sakura_petal",
			"row": int(projectile["row"]),
			"position": impact_position + Vector2(12.0, velocity_y * 0.012),
			"speed": split_speed,
			"velocity_y": velocity_y,
			"damage": child_damage,
			"slow_duration": 0.0,
			"color": Color(1.0, 0.72, 0.86),
			"radius": 7.0,
			"reflected": false,
			"fire": false,
			"free_aim": true,
			"split_speed": split_speed,
		})


func update_boomerang_projectile(projectile: Dictionary, delta: float) -> Dictionary:
	var projectile_pos = Vector2(projectile["position"])
	projectile_pos.x += float(projectile["speed"]) * delta
	projectile["position"] = projectile_pos
	var hit_uids: Array = projectile.get("hit_uids", [])
	var return_hits: Array = projectile.get("return_hits", [])
	var return_markers: Array = projectile.get("return_markers", [])
	if bool(projectile.get("outbound", true)):
		var target_index = game._find_projectile_target(projectile)
		if target_index != -1:
			var zombie = game.zombies[target_index]
			var uid = int(zombie.get("uid", -1))
			if not hit_uids.has(uid):
				zombie = _apply_boomerang_damage(zombie, float(projectile["damage"]), 0.12)
				game.zombies[target_index] = zombie
				hit_uids.append(uid)
				return_markers.append({
					"uid": uid,
					"x": float(zombie["x"]),
				})
				projectile["hit_uids"] = hit_uids
				projectile["return_markers"] = return_markers
				if hit_uids.size() >= int(projectile.get("max_hits", 3)):
					projectile["outbound"] = false
					projectile["speed"] = -absf(float(projectile["speed"])) * 0.92
			else:
				projectile_pos.x += 18.0
				projectile["position"] = projectile_pos
		if projectile_pos.x >= game.BOARD_ORIGIN.x + game.board_size.x + 40.0:
			projectile["outbound"] = false
			projectile["speed"] = -absf(float(projectile["speed"])) * 0.92
	else:
		for marker_variant in return_markers:
			var marker = Dictionary(marker_variant)
			var uid = int(marker.get("uid", -1))
			if return_hits.has(uid):
				continue
			if projectile_pos.x > float(marker.get("x", projectile_pos.x)):
				continue
			var zombie_index = find_zombie_index_by_uid(uid)
			if zombie_index != -1:
				var zombie = game.zombies[zombie_index]
				if game._is_enemy_zombie(zombie):
					var return_damage = float(projectile.get("return_damage", projectile["damage"]))
					zombie = _apply_boomerang_damage(zombie, return_damage, 0.12)
					game.zombies[zombie_index] = zombie
			return_hits.append(uid)
		projectile["return_hits"] = return_hits
	return projectile


func apply_torchwood_to_projectile(projectile: Dictionary) -> Dictionary:
	if String(projectile.get("kind", "")) != "" and String(projectile.get("kind", "")) != "pea":
		return projectile
	if bool(projectile.get("fire", false)) or bool(projectile.get("reflected", false)) or float(projectile.get("speed", 0.0)) <= 0.0:
		return projectile
	var row = int(projectile["row"])
	for col in range(game.COLS):
		var plant_variant = game.grid[row][col]
		if plant_variant == null or String(plant_variant["kind"]) != "torchwood":
			continue
		var center_x = game._cell_center(row, col).x
		var projectile_x = float(Vector2(projectile["position"]).x)
		if projectile_x < center_x - 20.0 or projectile_x > center_x + 20.0:
			continue
		projectile["fire"] = true
		projectile["damage"] = float(projectile["damage"]) * 2.0
		projectile["color"] = Color(1.0, 0.54, 0.18)
		projectile["radius"] = maxf(float(projectile.get("radius", 8.0)), 9.0)
		projectile["slow_duration"] = 0.0
		return projectile
	return projectile


func resolve_lobbed_projectile_impact(projectile: Dictionary, impact_position: Vector2) -> void:
	var projectile_kind = String(projectile.get("kind", ""))
	var damage = float(projectile.get("damage", 0.0))
	match projectile_kind:
		"melon":
			var splash_radius = float(projectile.get("splash_radius", 86.0))
			game._damage_zombies_in_circle(impact_position, splash_radius, damage)
			game._damage_obstacles_in_circle(impact_position, splash_radius * 0.92, damage)
			game.effects.append({
				"position": impact_position,
				"radius": splash_radius,
				"time": 0.28,
				"duration": 0.28,
				"color": Color(0.58, 0.86, 0.34, 0.28),
			})
		"chimney_fire":
			var fire_radius = float(projectile.get("splash_radius", 72.0))
			game._damage_zombies_in_circle(impact_position, fire_radius, damage)
			game._damage_obstacles_in_circle(impact_position, fire_radius * 0.9, damage)
			game.effects.append({
				"shape": "lane_spray",
				"position": impact_position + Vector2(-fire_radius * 0.3, 0.0),
				"length": fire_radius * 0.9,
				"width": fire_radius * 0.8,
				"radius": fire_radius,
				"time": 0.24,
				"duration": 0.24,
				"color": Color(1.0, 0.48, 0.16, 0.3),
			})
		"cabbage", "kernel", "butter":
			var hit_targets = game._find_closest_zombies_in_radius(impact_position, 42.0, 1)
			if not hit_targets.is_empty():
				var zombie_index = int(hit_targets[0])
				var zombie = game.zombies[zombie_index]
				zombie = game._apply_zombie_damage(zombie, damage, 0.14)
				if projectile_kind == "butter":
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), float(projectile.get("butter_duration", 2.6)))
				game.zombies[zombie_index] = zombie
			else:
				game._damage_obstacles_in_circle(impact_position, 32.0, damage * 0.9)
			game.effects.append({
				"position": impact_position,
				"radius": 36.0 if projectile_kind != "butter" else 42.0,
				"time": 0.2,
				"duration": 0.2,
				"color": Color(0.92, 0.9, 0.42, 0.24) if projectile_kind != "cabbage" else Color(0.56, 0.9, 0.34, 0.24),
			})
		"meteor_flower":
			var meteor_radius = float(projectile.get("splash_radius", 80.0))
			var burn_damage = float(projectile.get("burn_damage", 0.0))
			var burn_duration = float(projectile.get("burn_duration", 0.0))
			game._damage_zombies_in_circle(impact_position, meteor_radius, damage)
			game._damage_obstacles_in_circle(impact_position, meteor_radius * 0.92, damage)
			for zombie_index in game._find_closest_zombies_in_radius(impact_position, meteor_radius, 8):
				var zombie = game.zombies[zombie_index]
				zombie["corrode_timer"] = maxf(float(zombie.get("corrode_timer", 0.0)), burn_duration)
				zombie["corrode_dps"] = maxf(float(zombie.get("corrode_dps", 0.0)), burn_damage)
				game.zombies[zombie_index] = zombie
			game.effects.append({
				"position": impact_position,
				"radius": meteor_radius,
				"time": 0.28,
				"duration": 0.28,
				"color": Color(1.0, 0.56, 0.22, 0.3),
			})


func update_projectiles(delta: float) -> void:
	for i in range(game.projectiles.size() - 1, -1, -1):
		var projectile = game.projectiles[i]
		var projectile_pos = Vector2(projectile["position"])
		var projectile_kind = String(projectile.get("kind", "pea"))
		if projectile_kind == "boomerang":
			projectile = update_boomerang_projectile(projectile, delta)
			projectile_pos = Vector2(projectile["position"])
		elif projectile.has("arc_target"):
			var arc_origin = Vector2(projectile.get("arc_origin", projectile_pos))
			var arc_target = Vector2(projectile.get("arc_target", projectile_pos))
			var arc_duration = maxf(float(projectile.get("arc_duration", 0.42)), 0.01)
			var arc_time = minf(float(projectile.get("arc_time", 0.0)) + delta, arc_duration)
			var arc_ratio = clampf(arc_time / arc_duration, 0.0, 1.0)
			projectile_pos = arc_origin.lerp(arc_target, arc_ratio)
			projectile_pos.y -= sin(arc_ratio * PI) * float(projectile.get("arc_height", 64.0))
			projectile["arc_time"] = arc_time
			projectile["position"] = projectile_pos
			if arc_ratio >= 1.0:
				resolve_lobbed_projectile_impact(projectile, arc_target)
				game.projectiles.remove_at(i)
				continue
			game.projectiles[i] = projectile
			continue
		else:
			projectile_pos.x += float(projectile["speed"]) * delta
			projectile_pos.y += float(projectile.get("velocity_y", 0.0)) * delta
			projectile["position"] = projectile_pos
		if projectile_kind == "prism_pea" and not bool(projectile.get("split_done", false)) and projectile_pos.x >= float(projectile.get("split_at_x", projectile_pos.x + 1.0)):
			var fragment_count = max(1, int(projectile.get("split_count", 3)))
			for fragment_index in range(fragment_count):
				var spread = 0.0 if fragment_count <= 1 else lerpf(-1.0, 1.0, float(fragment_index) / float(fragment_count - 1))
				game.projectiles.append({
					"kind": "prism_fragment",
					"row": int(projectile["row"]),
					"position": projectile_pos + Vector2(8.0, spread * 8.0),
					"speed": 360.0,
					"velocity_y": spread * 210.0,
					"damage": float(projectile.get("fragment_damage", projectile.get("damage", 0.0) * 0.8)),
					"slow_duration": 0.0,
					"color": Color(0.72, 0.96, 1.0),
					"radius": maxf(5.0, float(projectile.get("radius", 7.0)) - 1.0),
					"reflected": false,
					"fire": false,
					"free_aim": absf(spread) > 0.01,
				})
			game.projectiles.remove_at(i)
			continue
		projectile = apply_torchwood_to_projectile(projectile)
		if projectile_kind == "moon_meteor":
			var impact_target = Vector2(projectile.get("target", projectile_pos))
			var impact_distance = projectile_pos.distance_to(impact_target)
			if impact_distance <= maxf(float(projectile.get("radius", 12.0)) * 1.3, float(projectile.get("speed", 0.0)) * delta):
				game._explode_moonforge_projectile(projectile, impact_target)
				game.projectiles.remove_at(i)
				continue

		if bool(projectile.get("reflected", false)):
			var plant_target = game._find_projectile_plant_target(projectile)
			if plant_target.y != -1:
				var plant = game._targetable_plant_at(plant_target.x, plant_target.y)
				if plant != null:
					plant["health"] -= float(projectile["damage"])
					plant["flash"] = 0.16
					game._set_targetable_plant(plant_target.x, plant_target.y, plant)
				game.projectiles.remove_at(i)
				continue
			if projectile_pos.x < game.BOARD_ORIGIN.x - 120.0:
				game.projectiles.remove_at(i)
				continue
			game.projectiles[i] = projectile
			continue

		if game._damage_projectile_obstacle(projectile):
			game.projectiles.remove_at(i)
			continue

		var hit_index = -1 if projectile_kind == "boomerang" else game._find_projectile_target(projectile)
		if hit_index != -1:
			var zombie = game.zombies[hit_index]
			var hit_damage = _projectile_hit_damage(projectile, zombie)
			var amber_armored_hit = String(projectile_kind) == "amber_pea" and _is_amber_armored_target(zombie)
			if bool(zombie.get("balloon_flying", false)) and bool(projectile.get("anti_air", false)):
				zombie["balloon_flying"] = false
				zombie["base_speed"] = float(Defs.ZOMBIES["balloon_zombie"]["speed"])
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.18)
				zombie = game._apply_zombie_damage(zombie, hit_damage, 0.12, float(projectile["slow_duration"]))
				game.zombies[hit_index] = zombie
				game.effects.append({
					"position": Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 30.0),
					"radius": 34.0,
					"time": 0.18,
					"duration": 0.18,
					"color": Color(0.82, 1.0, 0.9, 0.22),
				})
				game.projectiles.remove_at(i)
				continue
			if String(zombie["kind"]) == "kungfu" and float(zombie.get("reflect_timer", 0.0)) > 0.0:
				projectile["reflected"] = true
				projectile["speed"] = -absf(float(projectile["speed"]))
				projectile["color"] = Color(1.0, 0.42, 0.42)
				projectile["slow_duration"] = 0.0
				projectile["position"] = Vector2(float(zombie["x"]) - 18.0, projectile_pos.y)
				game.projectiles[i] = projectile
				continue
			if String(zombie["kind"]) == "janitor_zombie" and float(zombie.get("shield_health", 0.0)) > 0.0 and float(projectile.get("speed", 0.0)) >= 0.0:
				zombie["shield_health"] = maxf(0.0, float(zombie["shield_health"]) - hit_damage)
				zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.1)
				zombie["impact_timer"] = maxf(float(zombie.get("impact_timer", 0.0)), 0.12)
				game.zombies[hit_index] = zombie
				if projectile_kind == "amber_pea":
					_emit_amber_impact(Vector2(float(zombie["x"]) - 10.0, game._row_center_y(int(zombie["row"])) - 10.0), true)
				game.effects.append({
					"shape": "anchor_ring",
					"position": Vector2(float(zombie["x"]) - 12.0, game._row_center_y(int(zombie["row"])) - 10.0),
					"radius": 34.0,
					"time": 0.14,
					"duration": 0.14,
					"color": Color(0.82, 0.92, 1.0, 0.18),
				})
				game.projectiles.remove_at(i)
				continue

			zombie = game._apply_zombie_damage(zombie, hit_damage, 0.12, float(projectile["slow_duration"]))
			if projectile_kind == "mist_bloom":
				var reveal_duration = float(projectile.get("reveal_duration", 0.0))
				if reveal_duration > 0.0:
					zombie["revealed_timer"] = maxf(float(zombie.get("revealed_timer", 0.0)), reveal_duration)
			if projectile_kind == "heather_thorn":
				zombie["corrode_timer"] = maxf(float(zombie.get("corrode_timer", 0.0)), float(projectile.get("dot_duration", 0.0)))
				zombie["corrode_dps"] = maxf(float(zombie.get("corrode_dps", 0.0)), float(projectile.get("dot_damage", 0.0)))
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), float(projectile.get("stun_duration", 0.0)))
			if projectile_kind == "moon_meteor":
				game.zombies[hit_index] = zombie
				game._explode_moonforge_projectile(projectile, Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 10.0))
				game.projectiles.remove_at(i)
				continue
			game.zombies[hit_index] = zombie
			if projectile_kind == "amber_pea":
				_emit_amber_impact(Vector2(float(zombie["x"]) + 2.0, game._row_center_y(int(zombie["row"])) - 8.0), amber_armored_hit)
			elif projectile_kind == "sakura_petal":
				spawn_sakura_split_projectiles(projectile, Vector2(float(zombie["x"]) + 8.0, projectile_pos.y))
			elif projectile_kind == "mist_bloom":
				game._apply_mist_bloom_splash(Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"]))), projectile, int(zombie.get("uid", -1)))
			elif projectile_kind == "glow_seed":
				game._emit_glowvine_burst(Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"]))), int(zombie["row"]), float(projectile["damage"]) * 0.72)
			elif bool(projectile.get("fire", false)):
				apply_fire_projectile_splash(int(projectile["row"]), float(zombie["x"]), float(projectile["damage"]) * 0.55, hit_index)
			if int(projectile.get("pierce_left", 0)) > 0:
				var hit_uids: Array = projectile.get("hit_uids", [])
				hit_uids.append(int(zombie.get("uid", -1)))
				projectile["hit_uids"] = hit_uids
				projectile["pierce_left"] = int(projectile.get("pierce_left", 0)) - 1
				var step = 26.0 if float(projectile.get("speed", 0.0)) >= 0.0 else -26.0
				projectile["position"] = Vector2(float(zombie["x"]) + step, projectile_pos.y)
				game.projectiles[i] = projectile
				continue
			game.projectiles.remove_at(i)
			continue

		if projectile_kind == "boomerang":
			if not bool(projectile.get("outbound", true)) and float(projectile_pos.x) <= float(projectile.get("anchor_x", game.BOARD_ORIGIN.x)):
				game.projectiles.remove_at(i)
				continue
			if bool(projectile.get("outbound", true)) and projectile_pos.x > game.BOARD_ORIGIN.x + game.board_size.x + 120.0:
				game.projectiles.remove_at(i)
				continue
			game.projectiles[i] = projectile
			continue

		if projectile_pos.x > game.BOARD_ORIGIN.x + game.board_size.x + 120.0:
			game.projectiles.remove_at(i)
			continue
		if projectile_pos.y < game.BOARD_ORIGIN.y - 120.0 or projectile_pos.y > game.BOARD_ORIGIN.y + game.board_size.y + 120.0:
			game.projectiles.remove_at(i)
			continue

		game.projectiles[i] = projectile


func spawn_bowling_roller(row: int, col: int, empowered: bool = false) -> void:
	var center = game._cell_center(row, col)
	var base_speed = float(Defs.PLANTS["wallnut_bowling"]["roll_speed"])
	var base_damage = float(Defs.PLANTS["wallnut_bowling"]["damage"])
	game.rollers.append({
		"row": row,
		"x": center.x,
		"speed": base_speed * (1.18 if empowered else 1.0),
		"damage": base_damage * (1.85 if empowered else 1.0),
		"hits_left": 9 if empowered else 4,
		"bounce_dir": 1 if float(row) < float(game.ROWS) * 0.5 else -1,
		"last_hit_frame": -1,
		"empowered": empowered,
		"impact_radius": 96.0 if empowered else 48.0,
		"splash_ratio": 0.52 if empowered else 0.0,
		"trail_phase": game.rng.randf_range(0.0, TAU),
	})


func spawn_mango_roller(row: int, col: int, empowered: bool = false) -> void:
	var center = game._cell_center(row, col)
	var base_damage = float(Defs.PLANTS["mango_bowling"]["damage"]) * float(game.call("_plant_enhance_multiplier_at_cell", row, col))
	game.rollers.append({
		"kind": "mango",
		"row": row,
		"x": center.x,
		"speed": float(Defs.PLANTS["mango_bowling"]["roll_speed"]) * (1.12 if empowered else 1.0),
		"damage": base_damage * (1.4 if empowered else 1.0),
		"hits_left": 8 if empowered else 5,
		"bounce_dir": 1 if float(row) < float(game.ROWS) * 0.5 else -1,
		"last_hit_frame": -1,
		"empowered": empowered,
		"impact_radius": 88.0 if empowered else 64.0,
		"splash_ratio": 0.38 if empowered else 0.24,
		"trail_phase": game.rng.randf_range(0.0, TAU),
	})


func _spawn_roller_impact_effect(position: Vector2, empowered: bool) -> void:
	game.effects.append({
		"position": position,
		"radius": 118.0 if empowered else 52.0,
		"time": 0.22 if empowered else 0.14,
		"duration": 0.22 if empowered else 0.14,
		"color": Color(0.28, 0.98, 0.76, 0.28) if empowered else Color(0.86, 0.32, 0.22, 0.22),
		"shape": "nut_blast",
		"anim_speed": 8.6 if empowered else 6.2,
	})


func _apply_empowered_roller_blast(roller: Dictionary, primary_index: int, impact_position: Vector2) -> void:
	var impact_radius = float(roller.get("impact_radius", 0.0))
	if impact_radius <= 0.0:
		return
	var splash_ratio = float(roller.get("splash_ratio", 0.0))
	if splash_ratio <= 0.0:
		return
	for z in range(game.zombies.size()):
		if z == primary_index:
			continue
		var zombie = game.zombies[z]
		if not game._is_enemy_zombie(zombie):
			continue
		if abs(int(zombie["row"]) - int(roller["row"])) > 1:
			continue
		var zombie_position = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		var distance = zombie_position.distance_to(impact_position)
		if distance > impact_radius:
			continue
		var falloff = 1.0 - clampf(distance / impact_radius, 0.0, 1.0)
		var splash_damage = float(roller["damage"]) * splash_ratio * (0.45 + falloff * 0.55)
		zombie = game._apply_zombie_damage(zombie, splash_damage, 0.16)
		zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.16)
		game.zombies[z] = zombie


func _apply_mango_roller_blast(roller: Dictionary, primary_index: int, impact_position: Vector2) -> void:
	var impact_radius = float(roller.get("impact_radius", 64.0))
	var splash_ratio = float(roller.get("splash_ratio", 0.24))
	for z in range(game.zombies.size()):
		if z == primary_index:
			continue
		var zombie = game.zombies[z]
		if not game._is_enemy_zombie(zombie):
			continue
		if abs(int(zombie["row"]) - int(roller["row"])) > 1:
			continue
		var zombie_position = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		if zombie_position.distance_to(impact_position) > impact_radius:
			continue
		zombie = game._apply_zombie_damage(zombie, float(roller["damage"]) * splash_ratio, 0.12)
		game.zombies[z] = zombie


func update_rollers(delta: float) -> void:
	for i in range(game.rollers.size() - 1, -1, -1):
		var roller = game.rollers[i]
		roller["x"] += float(roller["speed"]) * delta
		var removed = false
		for z in range(game.zombies.size()):
			var zombie = game.zombies[z]
			if int(zombie["row"]) != int(roller["row"]):
				continue
			if absf(float(zombie["x"]) - float(roller["x"])) > 26.0:
				continue
			zombie = game._apply_zombie_damage(zombie, float(roller["damage"]), 0.2)
			game.zombies[z] = zombie
			var impact_position = Vector2(float(roller["x"]), game._row_center_y(int(roller["row"])))
			_spawn_roller_impact_effect(impact_position, bool(roller.get("empowered", false)))
			if String(roller.get("kind", "")) == "mango":
				_apply_mango_roller_blast(roller, z, impact_position)
			elif bool(roller.get("empowered", false)):
				_apply_empowered_roller_blast(roller, z, impact_position)
			roller["hits_left"] = int(roller["hits_left"]) - 1
			var next_row = int(roller["row"]) + int(roller["bounce_dir"])
			if next_row < 0 or next_row >= game.ROWS:
				roller["bounce_dir"] = -int(roller["bounce_dir"])
				next_row = clampi(int(roller["row"]) + int(roller["bounce_dir"]), 0, game.ROWS - 1)
			if game._is_row_active(next_row):
				roller["row"] = next_row
			if int(roller["hits_left"]) <= 0:
				game.rollers.remove_at(i)
				removed = true
			break
		if removed:
			continue
		if float(roller["x"]) > game.BOARD_ORIGIN.x + game.board_size.x + 120.0:
			game.rollers.remove_at(i)
			continue
		game.rollers[i] = roller
