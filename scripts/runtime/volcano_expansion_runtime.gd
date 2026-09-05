extends RefCounted
class_name VolcanoExpansionRuntime

const Defs = preload("res://scripts/game_defs.gd")
const PLANTS := ["thermal_sunflower", "obsidian_artichoke", "steam_clover", "pumice_wall", "sulfur_pod", "resonance_beet", "pressure_bamboo", "fumarole_melon", "magnet_orchid", "caldera_lotus"]
const ZOMBIES := ["basalt_guard", "cinder_runner", "kiln_mason", "ash_bell", "sulfur_carrier", "geode_zombie", "vent_tunneler"]
const COLORS := [Color("#ffc84a"), Color("#61d6c2"), Color("#b0eff1"), Color("#c0cbd0"), Color("#d8df56"), Color("#f178ad"), Color("#85dc76"), Color("#76d6d8"), Color("#d879c1"), Color("#ff665e")]
var game: Control
var cooling: Dictionary = {}
var warned: Dictionary = {}
var heat_until := 0.0
var tide_timer := 0.0


func _init(owner: Control) -> void:
	game = owner


func reset() -> void:
	cooling.clear()
	warned.clear()
	heat_until = 0.0
	tide_timer = 0.0


func tint(kind: String) -> Color:
	return COLORS[maxi(0, PLANTS.find(kind)) % COLORS.size()]


func fx(center: Vector2, color: Color, radius: float = 65.0, duration: float = 0.45) -> void:
	game.effects.append({"shape": "volcano_pulse", "position": center, "radius": radius, "color": color, "time": duration, "duration": duration})


func is_cooled(cell: Vector2i) -> bool:
	return float(cooling.get(cell, 0.0)) > game.level_time


func active_vent(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < game.ROWS and cell.y >= 0 and cell.y < game.COLS and game._is_row_active(cell.x) and game._cell_terrain_kind(cell.x, cell.y) == "lava" and not is_cooled(cell)


func nearby_vent(row: int, col: int) -> bool:
	for cell in game.current_level.get("lava_cells", []):
		if absi(cell.x - row) <= 1 and absi(cell.y - col) <= 1 and active_vent(cell):
			return true
	return false


func cool(center: Vector2i, reach: int, duration: float) -> void:
	for cell in game.current_level.get("lava_cells", []):
		if absi(cell.x - center.x) <= reach and absi(cell.y - center.y) <= reach and game._cell_terrain_kind(cell.x, cell.y) == "lava":
			cooling[cell] = maxf(float(cooling.get(cell, 0.0)), game.level_time + duration)
			warned.erase(cell)
			fx(game._cell_center(cell.x, cell.y), Color("#b0eff1"), 48.0, 0.7)


func update_world(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0:
		for cell in cooling:
			cooling[cell] = float(cooling[cell]) + delta
		if heat_until > 0.0:
			heat_until += delta
		for z in game.zombies:
			for key in ["basalt_brace_until", "sulfur_brittle_until", "kiln_armor_until"]:
				if float(z.get(key, 0.0)) > 0.0:
					z[key] = float(z[key]) + delta
		return
	for cell in cooling.keys():
		if not is_cooled(cell):
			cooling.erase(cell)
	if not game._is_volcano_level():
		return
	var interval = float(game.current_level.get("heat_tide_interval", 0.0))
	if interval <= 0.0:
		return
	tide_timer += delta
	if tide_timer >= interval:
		tide_timer = fmod(tide_timer, interval)
		heat_until = game.level_time + 5.0
		for cell in game.current_level.get("lava_cells", []):
			if active_vent(cell):
				var key = "%d,%d" % [cell.x, cell.y]
				game.lava_eruption_timers[key] = minf(float(game.lava_eruption_timers.get(key, 5.0)), 2.0)
		game._show_banner("地热潮涌", 1.5)


func warn_vent(cell: Vector2i, remaining: float) -> void:
	if warned.has(cell):
		return
	warned[cell] = true
	game.effects.append({"shape": "volcano_warning", "action": "vent_cue", "position": game._cell_center(cell.x, cell.y), "cell": cell, "radius": 135.0, "color": Color("#ffb950"), "time": remaining, "duration": remaining})


func on_eruption(row: int, col: int) -> void:
	warned.erase(Vector2i(row, col))
	heat_until = game.level_time + 3.0
	for r in range(maxi(0, row - 1), mini(game.ROWS, row + 2)):
		for c in range(maxi(0, col - 1), mini(game.COLS, col + 2)):
			var p = game._top_plant_at(r, c)
			if p == null or float(p.get("health", 0.0)) <= 0.0 or game._plant_charm_blocks_actions(p) or float(p.get("sleep_timer", 0.0)) > 0.0:
				continue
			if String(p.kind) in ["thermal_sunflower", "caldera_lotus"]:
				p["geothermal_charge"] = mini(3, int(p.get("geothermal_charge", 0)) + 1)
				fx(game._cell_center(r, c), tint(p.kind), 40.0)


func targets(row: int, x: float, limit: int, cross_lane: bool = false, ground_only: bool = false) -> Array:
	var candidates: Array = []
	for i in range(game.zombies.size()):
		var z = game.zombies[i]
		if not game._is_enemy_zombie(z) or float(z.get("health", 0.0)) <= 0.0:
			continue
		if not cross_lane and int(z.row) != row:
			continue
		if float(z.x) < x - 30.0 or float(z.x) > game.BOARD_ORIGIN.x + game.board_size.x + 70.0:
			continue
		if ground_only and (bool(z.get("flying", false)) or bool(z.get("balloon_flying", false)) or bool(z.get("jumping", false))):
			continue
		candidates.append(i)
	candidates.sort_custom(func(a, b): return float(game.zombies[a].x) < float(game.zombies[b].x))
	return candidates.slice(0, limit)


func shoot(plant: Dictionary, index: int, row: int, col: int, power: float = 1.0) -> void:
	var z: Dictionary = game.zombies[index]
	var origin: Vector2 = game._cell_center(row, col) + Vector2(18, -25)
	var target: Vector2 = Vector2(float(z.x), game._row_center_y(int(z.row)) - 10.0)
	var kind = String(plant.kind)
	var damage = float(Defs.PLANTS[kind]["damage"]) * game._plant_enhance_multiplier_at_cell(row, col) * power
	if kind == "caldera_lotus":
		damage *= 1.0 + (0.35 if nearby_vent(row, col) else 0.0) + 0.15 * int(plant.get("geothermal_charge", 0))
		plant["geothermal_charge"] = 0
	game.projectiles.append({"kind": "volcano_seed", "volcano_seed": kind, "row": int(z.row), "position": origin, "arc_origin": origin, "arc_target": target, "arc_time": 0.0, "arc_duration": 0.42, "arc_height": 70.0, "damage": damage, "radius": 9.0, "color": tint(kind), "owner_cell": Vector2i(row, col)})
	game._play_firing_sfx("melon_pult" if kind in ["fumarole_melon", "caldera_lotus"] else "cabbage_pult")
	game._trigger_plant_action(plant, 0.32)


func update_plant(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var kind = String(plant.kind)
	var center: Vector2 = game._cell_center(row, col)
	var interval = float(Defs.PLANTS[kind].shoot_interval)
	if kind == "pumice_wall":
		var last_hp = float(plant.get("pumice_last_hp", plant.max_health))
		plant["pumice_pressure"] = minf(180.0, float(plant.get("pumice_pressure", 0.0)) + maxf(0.0, last_hp - float(plant.health)) * 0.3)
		plant["pumice_last_hp"] = plant.health
	plant["geothermal_timer"] = float(plant.get("geothermal_timer", interval if kind == "thermal_sunflower" else 0.1)) - game._plant_cadence_delta(delta, row, col)
	if float(plant.geothermal_timer) > 0.0:
		return
	plant["geothermal_timer"] = interval
	match kind:
		"thermal_sunflower":
			var amount = 25 + int(plant.get("geothermal_charge", 0)) * 25
			game._spawn_sun(center + Vector2(0, -28), center.y - 12, "plant", amount)
			plant["geothermal_charge"] = 0
			game._trigger_plant_action(plant, 0.4)
		"steam_clover":
			cool(Vector2i(row, col), 1, 10.0)
			pulse(center, 155.0, 30.0, 3.0)
			fx(center, tint(kind), 150.0)
		"pumice_wall":
			var found = targets(row, center.x, 1, false, true)
			if found.is_empty() or float(game.zombies[found[0]].x) - center.x > 120.0:
				plant["geothermal_timer"] = 0.1
				return
			pulse(center, 120.0, 24.0 + float(plant.get("pumice_pressure", 0.0)), 0.0, true)
			plant["pumice_pressure"] = 0.0
			fx(center, tint(kind), 115.0)
		"magnet_orchid":
			reclaim(row, col, 1, 70.0)
		"pressure_bamboo":
			plant["pressure_ammo"] = mini(3, int(plant.get("pressure_ammo", 0)) + 1)
			var found = targets(row, center.x, 1)
			if not found.is_empty():
				for _i in range(int(plant.pressure_ammo)):
					shoot(plant, found[0], row, col)
					game.projectiles.back()["arc_duration"] = 0.42 + _i * 0.14
				plant["pressure_ammo"] = 0
		_:
			var found = targets(row, center.x, 1, kind == "caldera_lotus", kind == "resonance_beet")
			if found.is_empty():
				plant["geothermal_timer"] = 0.1
				return
			shoot(plant, found[0], row, col)


func pulse(center: Vector2, radius: float, damage: float, slow: float = 0.0, ground_only: bool = false) -> void:
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not game._is_enemy_zombie(z) or float(z.health) <= 0.0:
			continue
		if ground_only and (bool(z.get("flying", false)) or bool(z.get("balloon_flying", false)) or bool(z.get("jumping", false))):
			continue
		if Vector2(float(z.x), game._row_center_y(int(z.row)) - 10).distance_to(center) <= radius:
			game.zombies[i] = game._apply_zombie_damage(z, damage, 0.16, slow)


func impact(projectile: Dictionary, center: Vector2) -> void:
	var kind = String(projectile.volcano_seed)
	var damage = float(projectile.damage)
	if kind == "resonance_beet":
		pulse(center, 90.0, damage, 0.0, true)
		game.effects.append({"shape": "volcano_warning", "action": "echo", "position": center, "radius": 95.0, "damage": damage, "color": tint(kind), "time": 0.65, "duration": 0.65})
	elif kind == "fumarole_melon":
		pulse(center, 80.0, damage, 1.0)
		game.effects.append({"shape": "volcano_steam", "position": center, "radius": 95.0, "dps": damage * 0.3, "time": 3.0, "duration": 3.0, "color": tint(kind)})
	else:
		var radius = 85.0 if kind == "caldera_lotus" else 58.0
		for i in range(game.zombies.size()):
			var z: Dictionary = game.zombies[i]
			if not game._is_enemy_zombie(z) or float(z.health) <= 0.0:
				continue
			if Vector2(float(z.x), game._row_center_y(int(z.row)) - 10).distance_to(center) > radius:
				continue
			var hit_damage = damage
			if kind == "obsidian_artichoke" and float(z.get("shield_health", 0.0)) > 0.0:
				hit_damage += 80.0
			z = game._apply_zombie_damage(z, hit_damage, 0.18)
			if kind == "sulfur_pod":
				z["sulfur_brittle_until"] = game.level_time + 4.0
			game.zombies[i] = z
	fx(center, tint(kind), 64.0)


func reclaim(row: int, col: int, count: int, amount: float) -> void:
	var recovered := 0.0
	for index in targets(row, game._cell_center(row, col).x, 20, count > 1):
		var z: Dictionary = game.zombies[index]
		var take = minf(amount, float(z.get("shield_health", 0.0)))
		if take <= 0.0:
			continue
		z["shield_health"] -= take
		z["kiln_armor_remaining"] = maxf(0.0, float(z.get("kiln_armor_remaining", 0.0)) - take)
		recovered += take
		count -= 1
		fx(Vector2(float(z.x), game._row_center_y(int(z.row)) - 15), tint("magnet_orchid"), 45.0)
		if count <= 0:
			break
	if recovered <= 0.0:
		return
	var recipients: Array = []
	for r in range(maxi(0, row - 1), mini(game.ROWS, row + 2)):
		for c in range(maxi(0, col - 1), mini(game.COLS, col + 2)):
			var p = game._top_plant_at(r, c)
			if p != null and float(p.health) > 0.0 and not game._plant_charm_blocks_actions(p) and float(p.get("armor_health", 0)) < 240.0:
				recipients.append(p)
	recipients.sort_custom(func(a, b): return float(a.get("armor_health", 0)) < float(b.get("armor_health", 0)))
	for recipient in recipients:
		var grant = minf(recovered, 240.0 - float(recipient.get("armor_health", 0)))
		recipient["armor_health"] = float(recipient.get("armor_health", 0)) + grant
		recipient["max_armor_health"] = maxf(float(recipient.get("max_armor_health", 0)), float(recipient.armor_health))
		fx(game._cell_center(int(recipient.row), int(recipient.col)), tint("magnet_orchid"))
		recovered -= grant
		if recovered <= 0.0:
			break


func ultimate(plant: Dictionary, row: int, col: int) -> void:
	var kind = String(plant.kind)
	var center: Vector2 = game._cell_center(row, col)
	match kind:
		"thermal_sunflower":
			game._spawn_sun(center + Vector2(0, -40), center.y - 15, "plant_food", 200 + int(plant.get("geothermal_charge", 0)) * 25)
			plant["geothermal_charge"] = 0
		"steam_clover":
			cool(Vector2i(row, col), game.COLS, 14.0)
			pulse(game.BOARD_ORIGIN + game.board_size * 0.5, game.board_size.x, 100.0, 5.0)
		"pumice_wall":
			pulse(center, 220.0, 260.0 + float(plant.get("pumice_pressure", 0)), 2.0, true)
			plant["pumice_pressure"] = 0.0
			plant["pumice_last_hp"] = plant.health
		"magnet_orchid":
			reclaim(row, col, 8, 180.0)
		"caldera_lotus":
			for cell in game.current_level.get("lava_cells", []):
				if game._cell_terrain_kind(cell.x, cell.y) != "lava":
					continue
				pulse(game._cell_center(cell.x, cell.y), 150.0, 160.0, 2.0)
				fx(game._cell_center(cell.x, cell.y), tint(kind), 145.0)
			cool(Vector2i(row, col), game.COLS, 6.0)
			pulse(center, 240.0, 220.0)
		_:
			var found = targets(row, game.BOARD_ORIGIN.x, 5 if kind == "fumarole_melon" else 8, true, kind == "resonance_beet")
			if kind == "pressure_bamboo" and not found.is_empty():
				for i in range(6):
					shoot(plant, found[i % found.size()], row, col, 2.4)
					game.projectiles.back()["arc_duration"] = 0.42 + i * 0.1
			else:
				for index in found:
					shoot(plant, index, row, col, 2.8)
	fx(center, tint(kind), 150.0, 0.65)


func controlled(z: Dictionary) -> bool:
	return float(z.get("slow_timer", 0)) > 0 or float(z.get("rooted_timer", 0)) > 0 or float(z.get("frozen_timer", 0)) > 0 or float(z.get("special_pause_timer", 0)) > 0


func runner_is_hot(z: Dictionary) -> bool:
	if not game._is_volcano_level() or controlled(z):
		return false
	var cell = Vector2i(int(z.get("row", 0)), game._zombie_cell_col(float(z.get("x", 0.0))))
	for vent in cooling:
		if is_cooled(vent) and absi(vent.x - cell.x) <= 1 and absi(vent.y - cell.y) <= 1:
			return false
	return heat_until > game.level_time or nearby_vent(cell.x, cell.y)


func effect_owner(effect: Dictionary) -> Dictionary:
	for z in game.zombies:
		if int(z.get("uid", -2)) == int(effect.get("owner_uid", -1)) and float(z.health) > 0.0:
			return z
	return {}


func warning_active(effect: Dictionary) -> bool:
	var action = String(effect.get("action", ""))
	if action == "echo":
		return true
	if action in ["vent_cue", "eruption", "tunnel"] and not active_vent(Vector2i(effect.cell)):
		return false
	if action == "vent_cue":
		return true
	var owner = effect_owner(effect)
	return not owner.is_empty() and bool(owner.get("hypnotized", false)) == bool(effect.get("friendly", false)) and (game._is_boss_zombie(owner) or not controlled(owner))


func warning(z: Dictionary, action: String, center: Vector2, radius: float, duration: float, extra: Dictionary = {}) -> void:
	var effect = {"shape": "volcano_warning", "action": action, "position": center, "radius": radius, "time": duration, "duration": duration, "color": Color("#ffbb62"), "owner_uid": int(z.uid), "friendly": bool(z.get("hypnotized", false))}
	effect.merge(extra)
	game.effects.append(effect)


func update_zombie(z: Dictionary, delta: float) -> void:
	if z.has("kiln_armor_remaining"):
		z["kiln_armor_remaining"] = minf(float(z.kiln_armor_remaining), float(z.get("shield_health", 0.0)))
	if float(z.get("kiln_armor_remaining", 0.0)) > 0.0 and float(z.get("kiln_armor_until", 0.0)) <= game.level_time:
		z["shield_health"] = maxf(0.0, float(z.shield_health) - float(z.kiln_armor_remaining))
		z["kiln_armor_remaining"] = 0.0
	var kind = String(z.kind)
	if not ZOMBIES.has(kind):
		return
	if kind == "geode_zombie" and float(z.shield_health) <= 0.0 and not bool(z.get("geode_broken", false)):
		z["geode_broken"] = true
		z["base_speed"] = float(z.base_speed) * 24.0 / float(Defs.ZOMBIES.geode_zombie.speed)
		for offset in [70.0, 145.0]:
			warning(z, "shards", Vector2(float(z.x) + (offset if bool(z.hypnotized) else -offset), game._row_center_y(int(z.row))), 42.0, 1.0, {"damage": 55.0})
	if controlled(z):
		z["basalt_brace_until"] = 0.0
		return
	z["volcano_ability_timer"] = float(z.get("volcano_ability_timer", 3.0)) - delta
	if float(z.volcano_ability_timer) > 0.0:
		return
	z["volcano_ability_timer"] = 6.0
	var center = Vector2(float(z.x), game._row_center_y(int(z.row)))
	match kind:
		"basalt_guard":
			z["basalt_brace_until"] = game.level_time + 2.0
			fx(center, Color("#91b9c2"), 54.0, 1.0)
		"kiln_mason":
			for ally in game.zombies:
				if ally == z or game._is_boss_zombie(ally) or float(ally.health) <= 0.0 or bool(ally.hypnotized) != bool(z.hypnotized):
					continue
				if absi(int(ally.row) - int(z.row)) > 1 or absf(float(ally.x) - float(z.x)) > 170.0:
					continue
				var grant = minf(100.0, 180.0 - float(ally.get("kiln_armor_remaining", 0.0)))
				if grant <= 0.0:
					continue
				ally["shield_health"] += grant
				ally["kiln_armor_remaining"] = float(ally.get("kiln_armor_remaining", 0.0)) + grant
				ally["kiln_armor_until"] = game.level_time + 8.0
				ally["max_shield_health"] = maxf(float(ally.max_shield_health), float(ally.shield_health))
				fx(Vector2(float(ally.x), game._row_center_y(int(ally.row))), Color("#efc683"))
				break
			z["volcano_ability_timer"] = 5.0
		"ash_bell":
			if bool(z.hypnotized):
				warning(z, "shards", center, 180.0, 1.0, {"damage": 80.0})
			else:
				var marked := 0
				for r in game.active_rows:
					for c in range(game.COLS - 1, -1, -1):
						if marked >= 2:
							break
						if game.grid[int(r)][c] != null and game._cell_center(int(r), c).distance_to(center) < 330.0:
							warning(z, "ash", game._cell_center(int(r), c), 43.0, 1.1, {"cell": Vector2i(r, c)})
							marked += 1
		"sulfur_carrier":
			if float(z.health) <= float(z.max_health) * 0.5 and not bool(z.get("sulfur_spent", false)):
				z["sulfur_spent"] = true
				warning(z, "shards", center, 105.0, 1.3, {"damage": 85.0})
			else:
				z["volcano_ability_timer"] = 0.2
		"vent_tunneler":
			if bool(z.get("vent_traveled", false)) or bool(z.hypnotized) or float(z.x) < game.BOARD_ORIGIN.x + game.board_size.x * 0.55:
				return
			for cell in game.current_level.get("lava_cells", []):
				if cell.y < 4 or not active_vent(cell) or game._cell_center(cell.x, cell.y).x >= float(z.x) - 70.0:
					continue
				z["vent_traveled"] = true
				warning(z, "tunnel", game._cell_center(cell.x, cell.y), 50.0, 1.4, {"cell": cell})
				break


func resolve(effect: Dictionary) -> void:
	if not warning_active(effect):
		return
	var action = String(effect.get("action", ""))
	var center = Vector2(effect.position)
	if action == "echo":
		pulse(center, float(effect.radius), float(effect.damage), 0.0, true)
		fx(center, tint("resonance_beet"), float(effect.radius))
		return
	if action == "vent_cue":
		return
	var owner = effect_owner(effect)
	match action:
		"ash":
			var cell = Vector2i(effect.cell)
			var p = game._top_plant_at(cell.x, cell.y)
			if p != null and float(p.get("holy_invincible_timer", 0)) <= 0.0 and not game._is_sleep_immune_plant_kind(String(p.kind)):
				p["sleep_timer"] = maxf(float(p.sleep_timer), 2.0)
		"shards", "meteor":
			if bool(effect.get("friendly", false)):
				pulse(center, float(effect.radius), float(effect.damage), 2.0)
			else:
				game._damage_plants_in_circle(center, float(effect.radius), float(effect.damage))
		"tunnel":
			var cell = Vector2i(effect.cell)
			if not active_vent(cell):
				return
			owner["row"] = cell.x
			owner["x"] = center.x + 25.0
			owner["special_pause_timer"] = 0.5
		"eruption":
			var cell = Vector2i(effect.cell)
			if active_vent(cell):
				game._erupt_lava_cell(cell.x, cell.y)
	fx(center, Color("#ffe195"), float(effect.radius))
	game._play_sfx(game.SFX_HIT_EXPLOSION_PATH, -17.0, 0.9)
	game._trigger_screen_shake(3.0)


func boss_skill(z: Dictionary) -> Dictionary:
	var phase = int(z.get("boss_phase", 0))
	match int(z.get("boss_skill_cycle", 0)) % 3:
		0:
			var marked := 0
			for row_offset in range(game.active_rows.size()):
				var row = int(game.active_rows[(int(z.row) + row_offset) % game.active_rows.size()])
				var col: int = game.COLS - 2
				for c in range(game.COLS - 1, 1, -1):
					if game.grid[row][c] != null:
						col = c
						break
				var cell = Vector2i(row, col)
				warning(z, "meteor", game._cell_center(cell.x, cell.y), 65.0, 1.6, {"damage": 100.0 + phase * 25.0})
				marked += 1
				if marked >= 3 + phase:
					break
		1:
			for cell in game.current_level.get("lava_cells", []):
				if active_vent(cell):
					warning(z, "eruption", game._cell_center(cell.x, cell.y), 130.0, 1.8, {"cell": cell})
		2:
			var pool: Array = ZOMBIES if String(game.current_level.get("id", "")) == "7-20" else ["umbrella_zombie", "shade_zombie", "crab_zombie", "camel_zombie"]
			for i in range(3 + phase):
				var kind = String(pool[(i + phase) % pool.size()])
				game._spawn_zombie_at(kind, game._choose_spawn_row_for_kind(kind), game.BOARD_ORIGIN.x + game.board_size.x + 50.0 + i * 18, true)
	game._show_banner(["熔炉落石", "火口共鸣", "炉卫集结"][int(z.get("boss_skill_cycle", 0)) % 3], 1.5)
	return z


func oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		points.append(center + Vector2(cos(i * TAU / 28.0), sin(i * TAU / 28.0)) * radii)
	game.draw_colored_polygon(points, color)


func polygon(center: Vector2, scale: float, points: Array, color: Color) -> void:
	var vertices := PackedVector2Array()
	for point in points:
		vertices.append(center + Vector2(point) * scale)
	game.draw_colored_polygon(vertices, color)


func draw_plant(kind: String, center: Vector2, scale: float = 1.0, flash: float = 0.0, alpha: float = 1.0, plant: Dictionary = {}) -> void:
	var ink = Color("#213b3a", alpha)
	var green = Color("#398451", alpha)
	var bright = tint(kind).lerp(Color.WHITE, clampf(flash * 3.0, 0.0, 0.8))
	bright.a = alpha
	var dark = bright.darkened(0.42)
	var face = center + Vector2(0, -11) * scale
	oval(center + Vector2(0, 23) * scale, Vector2(31, 7) * scale, Color(0.08, 0.14, 0.12, alpha * 0.25))
	polygon(center, scale, [Vector2(-3, 22), Vector2(-30, 7), Vector2(-17, 24), Vector2(16, 24), Vector2(31, 8), Vector2(4, 17)], green)
	match kind:
		"thermal_sunflower":
			game.draw_line(center + Vector2(0, 21) * scale, face, green, 8.0 * scale)
			for i in range(10):
				var dir = Vector2.from_angle(i * TAU / 10.0)
				oval(face + dir * 22.0 * scale, Vector2(9, 10) * scale, dark)
				oval(face + dir * 21.0 * scale, Vector2(7, 8) * scale, bright)
			oval(face, Vector2(18, 18) * scale, ink)
			oval(face, Vector2(15, 15) * scale, Color("#e99c46", alpha))
		"obsidian_artichoke":
			for layer in range(3):
				for offset in range(-1, 2):
					var point = center + Vector2(offset * (16 - layer * 3), 16 - layer * 13) * scale
					polygon(point, scale, [Vector2(-13, 6), Vector2(-10, -11), Vector2(0, -23), Vector2(11, -9), Vector2(13, 7)], ink)
					polygon(point, scale, [Vector2(-9, 4), Vector2(0, -18), Vector2(8, -5), Vector2(8, 4)], dark if layer == 0 else bright)
		"steam_clover", "magnet_orchid", "caldera_lotus":
			game.draw_line(center + Vector2(0, 22) * scale, face, green, 7.0 * scale)
			var petals = 3 if kind == "steam_clover" else 6
			for i in range(petals):
				var dir = Vector2.from_angle(-PI * 0.5 + i * TAU / petals)
				var petal = face + dir * 19.0 * scale
				oval(petal, Vector2(13, 14) * scale, dark)
				oval(petal - Vector2(1, 2) * scale, Vector2(10, 10) * scale, bright)
			oval(face, Vector2(14, 14) * scale, Color("#ffde76", alpha))
			if kind == "magnet_orchid":
				game.draw_arc(center + Vector2(0, 10) * scale, 13.0 * scale, 0.0, PI, 18, ink, 7.0 * scale)
				for side in [-1, 1]:
					game.draw_line(center + Vector2(side * 13, 10) * scale, center + Vector2(side * 13, 1) * scale, bright, 7.0 * scale)
			elif kind == "caldera_lotus":
				polygon(center, scale, [Vector2(-29, 20), Vector2(-18, 8), Vector2(-10, 18), Vector2(0, 7), Vector2(10, 18), Vector2(22, 8), Vector2(30, 20)], dark)
		"pumice_wall":
			oval(center + Vector2(0, -3) * scale, Vector2(30, 38) * scale, ink)
			oval(center + Vector2(0, -4) * scale, Vector2(27, 34) * scale, bright)
			for spot in [Vector2(-17, -21), Vector2(15, -27), Vector2(-18, 9), Vector2(18, 15), Vector2(3, 24)]:
				oval(center + spot * scale, Vector2(4, 3) * scale, dark)
			game.draw_arc(center + Vector2(0, 5) * scale, 17.0 * scale, 0.2, PI - 0.2, 16, dark, 2.0 * scale)
		"sulfur_pod":
			face = center + Vector2(2, -8) * scale
			oval(face, Vector2(32, 20) * scale, ink)
			oval(face, Vector2(29, 17) * scale, bright)
			for i in range(3):
				oval(face + Vector2(-17 + i * 16, 0) * scale, Vector2(8, 13) * scale, dark.lightened(0.15))
			polygon(center, scale, [Vector2(-25, 0), Vector2(-37, -12), Vector2(-27, -16)], green)
		"resonance_beet":
			polygon(center, scale, [Vector2(-7, -21), Vector2(-23, -37), Vector2(-5, -32), Vector2(0, -41), Vector2(10, -26), Vector2(25, -34), Vector2(15, -18)], green)
			oval(center + Vector2(0, -1) * scale, Vector2(25, 25) * scale, ink)
			oval(center + Vector2(0, -3) * scale, Vector2(22, 22) * scale, bright)
			polygon(center, scale, [Vector2(-9, 15), Vector2(0, 31), Vector2(9, 15)], bright)
			for side in [-1, 1]:
				game.draw_arc(center + Vector2(side * 4, 3) * scale, 26.0 * scale, -0.6 if side > 0 else PI - 0.6, 0.6 if side > 0 else PI + 0.6, 12, dark, 2.0 * scale)
		"pressure_bamboo":
			for i in range(3):
				var stem = center + Vector2((i - 1) * 17, 0 if i == 1 else 9) * scale
				game.draw_line(stem + Vector2(0, 21) * scale, stem + Vector2(0, -30) * scale, ink, 16.0 * scale)
				game.draw_line(stem + Vector2(0, 19) * scale, stem + Vector2(0, -29) * scale, bright, 12.0 * scale)
				for y in [-15, 4, 19]:
					game.draw_line(stem + Vector2(-7, y) * scale, stem + Vector2(7, y) * scale, dark, 3.0 * scale)
				oval(stem + Vector2(0, -29) * scale, Vector2(6, 4) * scale, ink)
		"fumarole_melon":
			oval(center + Vector2(0, 2) * scale, Vector2(32, 24) * scale, ink)
			oval(center + Vector2(0, 1) * scale, Vector2(29, 21) * scale, bright)
			for x in [-16, 16]:
				game.draw_line(center + Vector2(x, -14) * scale, center + Vector2(x, 16) * scale, dark, 3.0 * scale)
			polygon(center, scale, [Vector2(-10, -17), Vector2(-8, -33), Vector2(10, -33), Vector2(13, -17)], dark)
			oval(center + Vector2(1, -33) * scale, Vector2(9, 4) * scale, ink)
			face = center
	for side in [-1, 1]:
		oval(face + Vector2(side * 6, -2) * scale, Vector2(4, 5) * scale, Color(1, 1, 0.92, alpha))
		oval(face + Vector2(side * 6 + 1, -1) * scale, Vector2(2, 3) * scale, ink)
	game.draw_arc(face + Vector2(0, 6) * scale, 5.0 * scale, 0.15, PI - 0.15, 12, ink, 1.6 * scale)
	var charges = int(plant.get("pressure_ammo", plant.get("geothermal_charge", 0)))
	for i in range(charges):
		game.draw_rect(Rect2(center + Vector2(-11 + i * 9, 29) * scale, Vector2(6, 4) * scale), bright)


func draw_zombie(center: Vector2, z: Dictionary) -> void:
	var kind = String(z.kind)
	var accent = [Color("#76bac6"), Color("#ff785e"), Color("#e7c281"), Color("#c5b8e5"), Color("#dce964"), Color("#76e0d1"), Color("#d9c9a2")][ZOMBIES.find(kind)]
	var ink = Color("#243735")
	var skin = Color("#9ab393").lerp(Color.WHITE, clampf(float(z.get("flash", 0)) * 3.0, 0, 1))
	if bool(z.get("hypnotized", false)):
		skin = Color("#d7a9ed")
	if float(z.get("slow_timer", 0)) > 0.0:
		skin = skin.lerp(Color("#b1e9ff"), 0.6)
	var step = sin(game.level_time * 6.0 + float(z.get("anim_phase", 0))) * 5.0
	if float(z.get("basalt_brace_until", 0.0)) > game.level_time:
		step = 0.0
	for side in [-1, 1]:
		game.draw_line(center + Vector2(side * 8, 19), center + Vector2(side * 12 + step * side, 39), ink, 9)
		oval(center + Vector2(side * 12 + step * side - 3, 40), Vector2(10, 4), ink)
	polygon(center, 1.0, [Vector2(-17, -12), Vector2(14, -13), Vector2(19, 24), Vector2(-20, 24)], ink)
	polygon(center, 1.0, [Vector2(-13, -9), Vector2(11, -10), Vector2(15, 19), Vector2(-16, 19)], accent.darkened(0.38))
	game.draw_line(center + Vector2(4, -7), center + Vector2(-6, 18), accent, 4)
	game.draw_line(center + Vector2(-13, -6), center + Vector2(-28, 9 + step * 0.2), skin, 8)
	oval(center + Vector2(-2, -28), Vector2(20, 19), ink)
	oval(center + Vector2(-3, -29), Vector2(17, 16), skin)
	for x in [-10, 1]:
		oval(center + Vector2(x, -32), Vector2(6, 6), Color("#f9f8d9"))
		game.draw_circle(center + Vector2(x - 2, -31), 2.4, ink)
	game.draw_line(center + Vector2(-14, -20), center + Vector2(3, -18), ink, 3)
	game.draw_rect(Rect2(center + Vector2(-5, -21), Vector2(4, 5)), Color("#f8f2d7"))
	match kind:
		"basalt_guard":
			if float(z.get("shield_health", 0)) > 0.0 or float(z.get("basalt_brace_until", 0)) > game.level_time:
				polygon(center, 1.0, [Vector2(-38, -14), Vector2(-12, -20), Vector2(-8, 18), Vector2(-24, 32), Vector2(-39, 15)], ink)
				polygon(center, 1.0, [Vector2(-34, -10), Vector2(-17, -14), Vector2(-13, 16), Vector2(-24, 26), Vector2(-34, 13)], accent.darkened(0.24))
				game.draw_line(center + Vector2(-26, -7), center + Vector2(-22, 19), accent, 3)
		"cinder_runner":
			polygon(center, 1.0, [Vector2(-19, -42), Vector2(-25, -56), Vector2(-6, -48), Vector2(3, -57), Vector2(12, -41)], accent)
			for side in [-1, 1]:
				game.draw_line(center + Vector2(side * 12 + step * side - 11, 40), center + Vector2(side * 12 + step * side + 5, 40), accent, 6)
			if runner_is_hot(z):
				for i in range(3):
					game.draw_line(center + Vector2(20 + i * 8, 10 + i * 8), center + Vector2(35 + i * 8, 10 + i * 8), accent, 2)
		"kiln_mason":
			game.draw_rect(Rect2(center + Vector2(10, -13), Vector2(22, 31)), accent.darkened(0.15))
			for i in range(3):
				game.draw_line(center + Vector2(11, -7 + i * 9), center + Vector2(30, -7 + i * 9), ink, 2)
			polygon(center, 1.0, [Vector2(-35, 1), Vector2(-46, 13), Vector2(-22, 10)], Color("#b8ced2"))
		"ash_bell":
			polygon(center, 1.0, [Vector2(-37, -8), Vector2(-29, -8), Vector2(-25, 14), Vector2(-43, 14)], accent)
			game.draw_arc(center + Vector2(-33, -9), 5, PI, TAU, 12, accent, 3)
			game.draw_circle(center + Vector2(-33, 17), 4, accent.darkened(0.25))
		"sulfur_carrier":
			oval(center + Vector2(23, 2), Vector2(15, 25), ink)
			oval(center + Vector2(23, 2), Vector2(11, 21), accent.darkened(0.15) if bool(z.get("sulfur_spent", false)) else accent)
			game.draw_rect(Rect2(center + Vector2(19, -28), Vector2(8, 9)), ink)
			polygon(center + Vector2(23, 2), 1.0, [Vector2(0, -9), Vector2(-7, 5), Vector2(7, 5)], ink)
		"geode_zombie":
			if not bool(z.get("geode_broken", false)):
				for i in range(4):
					polygon(center + Vector2(-20 + i * 13, -38), 1.0, [Vector2(-8, 8), Vector2(-5, -7), Vector2(0, -18 - i % 2 * 7), Vector2(8, 0), Vector2(5, 11)], accent.darkened(0.15 * (i % 2)))
			else:
				game.draw_line(center + Vector2(-18, -42), center + Vector2(12, -40), accent, 4)
		"vent_tunneler":
			oval(center + Vector2(-3, -43), Vector2(21, 10), accent)
			game.draw_circle(center + Vector2(-17, -44), 6, Color("#fff3b1"))
			polygon(center, 1.0, [Vector2(-23, -4), Vector2(-47, 8), Vector2(-22, 18)], Color("#9fb9bc"))
			for i in range(3):
				game.draw_line(center + Vector2(-24 - i * 5, i), center + Vector2(-23 - i * 5, 14 - i), ink, 2)
	if float(z.get("sulfur_brittle_until", 0)) > game.level_time:
		game.draw_arc(center, 30, 0.2, TAU - 0.2, 28, Color("#e8ee66"), 2)


func draw_vent(cell: Vector2i) -> void:
	var center: Vector2 = game._cell_center(cell.x, cell.y)
	var cooled = is_cooled(cell)
	var heat = 0.7 + 0.3 * sin(game.level_time * 3.0 + cell.x)
	oval(center + Vector2(0, 10), Vector2(40, 26), Color("#1c2425"))
	oval(center, Vector2(38, 25), Color("#697d80") if cooled else Color("#a14c36"))
	oval(center, Vector2(30, 18), Color("#80bfc3") if cooled else Color(1.0, 0.3 + heat * 0.18, 0.13))
	for i in range(6):
		var angle = i * TAU / 6.0
		var rim = center + Vector2(cos(angle) * 33.0, sin(angle) * 21.0)
		polygon(rim, 1.0, [Vector2(-8, -3), Vector2(-3, -10), Vector2(7, -7), Vector2(10, 3), Vector2(1, 7)], Color("#526568") if cooled else Color("#594349"))
	if not cooled:
		for i in range(3):
			var rise = fmod(game.level_time * 21.0 + i * 15.0, 40.0)
			var point = center + Vector2(sin(i * 4.5) * 19, -rise)
			game.draw_line(point, point + Vector2(2, -7), Color(1, 0.88, 0.45, 1.0 - rise / 40.0), 2)


func draw_cooling() -> void:
	for cell in cooling:
		if not is_cooled(cell) or game._cell_terrain_kind(cell.x, cell.y) != "lava":
			continue
		var center: Vector2 = game._cell_center(cell.x, cell.y)
		game.draw_rect(Rect2(center - Vector2(37, 37), Vector2(74, 74)), Color(0.52, 0.94, 0.98, 0.16))
		game.draw_arc(center, 31, -PI * 0.5, -PI * 0.5 + TAU * minf(1.0, (float(cooling[cell]) - game.level_time) / 14.0), 36, Color("#b3f6ed"), 3)
		for i in range(3):
			var x = center.x - 16 + i * 16
			game.draw_line(Vector2(x, center.y + 10), Vector2(x + sin(game.level_time * 2 + i) * 5, center.y - 12), Color(0.78, 1, 1, 0.6), 2)


func draw_effect(effect: Dictionary) -> void:
	var center = Vector2(effect.position)
	var radius = float(effect.radius)
	var ratio = clampf(float(effect.time) / maxf(0.01, float(effect.duration)), 0.0, 1.0)
	var color = Color(effect.color)
	var shape = String(effect.shape)
	if shape == "volcano_warning":
		if not warning_active(effect):
			return
		var action = String(effect.get("action", ""))
		if action == "echo":
			color = tint("resonance_beet")
		elif bool(effect.get("friendly", false)):
			color = Color("#88f3b0")
		else:
			color = Color("#ffcf66") if action == "vent_cue" else Color("#ff887c")
		if action in ["vent_cue", "eruption"]:
			var cell = Vector2i(effect.cell)
			for r in range(maxi(0, cell.x - 1), mini(game.ROWS, cell.x + 2)):
				if not game._is_row_active(r):
					continue
				for c in range(maxi(0, cell.y - 1), mini(game.COLS, cell.y + 2)):
					var pos: Vector2 = game._cell_center(r, c)
					game.draw_rect(Rect2(pos - game.CELL_SIZE * 0.43, game.CELL_SIZE * 0.86), Color(color, 0.07 + 0.06 * (1.0 - ratio)))
					game.draw_rect(Rect2(pos - game.CELL_SIZE * 0.43, game.CELL_SIZE * 0.86), Color(color, 0.55), false, 1.5)
		else:
			game.draw_circle(center, radius, Color(color, 0.10))
			game.draw_arc(center, radius, 0, TAU, 48, Color(color, 0.75), 2)
		game.draw_arc(center, minf(radius, 44.0), -PI * 0.5, -PI * 0.5 + TAU * (1.0 - ratio), 40, color, 4)
		if action == "meteor":
			var rock = center + Vector2(0, -170.0 * minf(1.0, ratio * 2.8))
			game.draw_line(rock - Vector2(0, 34), rock, Color(color, 0.45), 7)
			polygon(rock, 1.0, [Vector2(-13, -12), Vector2(6, -17), Vector2(17, -2), Vector2(8, 15), Vector2(-10, 12)], color.darkened(0.22))
			game.draw_line(rock + Vector2(-4, -9), rock + Vector2(5, 7), Color("#fff1b0"), 3)
		elif action == "tunnel":
			for i in range(2):
				game.draw_line(center + Vector2(-14, -10 + i * 12), center + Vector2(0, i * 12), color, 3)
				game.draw_line(center + Vector2(14, -10 + i * 12), center + Vector2(0, i * 12), color, 3)
		elif action == "shards":
			polygon(center, 1.0, [Vector2(0, -15), Vector2(11, 8), Vector2(-11, 8)], color)
		elif action == "ash":
			game.draw_arc(center, 17, PI, TAU, 20, color, 3)
			game.draw_line(center + Vector2(-17, 0), center + Vector2(17, 0), color, 3)
	elif shape == "volcano_steam":
		game.draw_circle(center, radius, Color(color, 0.07 * minf(1.0, ratio * 3.0)))
		game.draw_arc(center, radius, 0, TAU, 48, Color(color, ratio * 0.35), 2)
		for i in range(7):
			var offset = Vector2(sin(i * 4.1) * radius * 0.7, cos(i * 2.4) * radius * 0.4 - fmod(game.level_time * 22 + i * 8, 32.0))
			game.draw_arc(center + offset, 12, -PI * 0.7, PI * 0.4, 16, Color(0.84, 1, 1, ratio * 0.46), 3)
	else:
		game.draw_arc(center, radius * (1.0 - ratio * 0.7), 0, TAU, 40, Color(color, ratio * 0.75), 3)
		for i in range(8):
			var dir = Vector2.from_angle(i * TAU / 8)
			game.draw_line(center + dir * radius * (1.0 - ratio) * 0.6, center + dir * radius * (1.0 - ratio), Color(color, ratio), 2)
