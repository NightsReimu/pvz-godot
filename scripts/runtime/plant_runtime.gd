extends RefCounted
class_name PlantRuntime

const Defs = preload("res://scripts/game_defs.gd")

var game: Control


func _init(game_owner: Control) -> void:
	game = game_owner


func update_plants(delta: float) -> void:
	for row in range(game.ROWS):
		for col in range(game.COLS):
			var plant_variant = game.grid[row][col]
			if plant_variant == null:
				continue

			var plant = plant_variant
			plant["flash"] = maxf(0.0, float(plant["flash"]) - delta)
			plant["action_timer"] = maxf(0.0, float(plant.get("action_timer", 0.0)) - delta)
			plant["sleep_timer"] = maxf(0.0, float(plant.get("sleep_timer", 0.0)) - delta)
			plant["rooted_timer"] = maxf(0.0, float(plant.get("rooted_timer", 0.0)) - delta)
			plant["support_timer"] = maxf(0.0, float(plant.get("support_timer", 0.0)) - delta)
			plant["push_timer"] = maxf(0.0, float(plant.get("push_timer", 0.0)) - delta)
			if float(plant.get("push_timer", 0.0)) <= 0.0:
				plant["push_offset_x"] = 0.0
			if float(plant["plant_food_timer"]) > 0.0:
				plant["plant_food_timer"] = maxf(0.0, float(plant["plant_food_timer"]) - delta)
			if float(plant["armor_health"]) <= 0.0 and String(plant["plant_food_mode"]) == "fortify":
				plant["armor_health"] = 0.0
				plant["max_armor_health"] = 0.0
				plant["plant_food_mode"] = ""
				plant["plant_food_timer"] = 0.0
			elif float(plant["plant_food_timer"]) <= 0.0 and String(plant["plant_food_mode"]) != "" and int(plant["plant_food_charges"]) <= 0 and String(plant["plant_food_mode"]) != "fortify":
				plant["plant_food_mode"] = ""
				plant["plant_food_interval"] = 0.0
			if String(plant.get("shell_kind", "")) == "pumpkin" and float(plant.get("armor_health", 0.0)) <= 0.0:
				plant["shell_kind"] = ""
				plant["max_armor_health"] = 0.0
			if String(plant["kind"]) == "pumpkin" and float(plant.get("armor_health", 0.0)) <= 0.0:
				game.grid[row][col] = null
				continue
			if float(plant["sleep_timer"]) > 0.0 and String(plant["plant_food_mode"]) == "":
				game.grid[row][col] = plant
				continue

			match String(plant["kind"]):
				"sunflower":
					plant["sun_timer"] -= delta
					if float(plant["sun_timer"]) <= 0.0:
						var center = game._cell_center(row, col)
						game._spawn_sun(center + Vector2(game.rng.randf_range(-8.0, 8.0), -18.0), center.y - 10.0, "plant")
						plant["sun_timer"] = float(Defs.PLANTS["sunflower"]["sun_interval"])
						game._trigger_plant_action(plant, 0.32)
				"peashooter":
					if update_shooter_plant_food(plant, delta, row, col, Color(0.36, 0.86, 0.3), 0.0, 1, 0.1):
						game.grid[row][col] = plant
						continue
					update_basic_shooter(plant, delta, row, col, Color(0.36, 0.86, 0.3), 0.0)
				"puff_shroom":
					if update_shooter_plant_food(plant, delta, row, col, Color(0.84, 0.68, 0.98), 0.0, 2, 0.07):
						game.grid[row][col] = plant
						continue
					update_basic_shooter(plant, delta, row, col, Color(0.84, 0.68, 0.98), 0.0)
				"sea_shroom":
					if update_shooter_plant_food(plant, delta, row, col, Color(0.66, 0.82, 0.96), 0.0, 2, 0.08):
						game.grid[row][col] = plant
						continue
					update_basic_shooter(plant, delta, row, col, Color(0.66, 0.82, 0.96), 0.0)
				"amber_shooter":
					if update_shooter_plant_food(plant, delta, row, col, Color(0.84, 0.58, 0.16), 0.0, 1, 0.08):
						game.grid[row][col] = plant
						continue
					update_basic_shooter(plant, delta, row, col, Color(0.84, 0.58, 0.16), 0.0)
				"snow_pea":
					if update_shooter_plant_food(plant, delta, row, col, Color(0.54, 0.88, 1.0), 16.0, 1, 0.1):
						game.grid[row][col] = plant
						continue
					update_basic_shooter(plant, delta, row, col, Color(0.54, 0.88, 1.0), float(Defs.PLANTS["snow_pea"]["slow_duration"]))
				"repeater":
					update_repeater(plant, delta, row, col)
				"threepeater":
					update_threepeater(plant, delta, row, col)
				"cactus":
					update_cactus(plant, delta, row, col)
				"blover":
					if update_blover(plant, delta, row, col):
						game.grid[row][col] = null
						continue
				"split_pea":
					update_split_pea(plant, delta, row, col)
				"starfruit":
					update_starfruit(plant, delta, row, col)
				"boomerang_shooter":
					update_boomerang_shooter(plant, delta, row, col)
				"sakura_shooter":
					update_sakura_shooter(plant, delta, row, col)
				"lotus_lancer":
					update_lotus_lancer(plant, delta, row, col)
				"mist_orchid":
					update_mist_orchid(plant, delta, row, col)
				"anchor_fern":
					update_anchor_fern(plant, delta, row, col)
				"glowvine":
					update_glowvine(plant, delta, row, col)
				"brine_pot":
					update_brine_pot(plant, delta, row, col)
				"storm_reed":
					update_storm_reed(plant, delta, row, col)
				"moonforge":
					update_moonforge(plant, delta, row, col)
				"mirror_reed":
					update_mirror_reed(plant, delta, row, col)
				"frost_fan":
					update_frost_fan(plant, delta, row, col)
				"cabbage_pult":
					update_cabbage_pult(plant, delta, row, col)
				"kernel_pult":
					update_kernel_pult(plant, delta, row, col)
				"melon_pult":
					update_melon_pult(plant, delta, row, col)
				"origami_blossom":
					update_origami_blossom(plant, delta, row, col)
				"chimney_pepper":
					update_chimney_pepper(plant, delta, row, col)
				"tesla_tulip":
					update_tesla_tulip(plant, delta, row, col)
				"signal_ivy":
					update_signal_ivy(plant, delta, row, col)
				"roof_vane":
					update_roof_vane(plant, delta, row, col)
				"skylight_melon":
					update_skylight_melon(plant, delta, row, col)
				"cherry_bomb":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						game._explode_cherry(row, col, String(plant["plant_food_mode"]) == "mega_bomb")
						game.grid[row][col] = null
						continue
				"jalapeno":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						game._trigger_jalapeno(row, col, String(plant["plant_food_mode"]) == "inferno")
						game.grid[row][col] = null
						continue
				"ice_shroom":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						game._trigger_ice_shroom(row, col, String(plant["plant_food_mode"]) == "deep_freeze")
						game.grid[row][col] = null
						continue
				"doom_shroom":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						game._trigger_doom_shroom(row, col, String(plant["plant_food_mode"]) == "doom_bloom")
						game.grid[row][col] = null
						continue
				"potato_mine":
					if not bool(plant["armed"]):
						plant["arm_timer"] -= delta
						if float(plant["arm_timer"]) <= 0.0:
							plant["armed"] = true
							game._trigger_plant_action(plant, 0.2)
					elif game._mine_has_target(row, col):
						game._explode_mine(row, col)
						game.grid[row][col] = null
						continue
				"chomper":
					plant["chew_timer"] = maxf(0.0, float(plant["chew_timer"]) - delta)
					if float(plant["chew_timer"]) <= 0.0:
						var zombie_index = game._find_chomper_target(row, game._cell_center(row, col).x)
						if zombie_index != -1:
							var zombie = game.zombies[zombie_index]
							if game._is_boss_zombie(zombie):
								zombie = game._apply_zombie_damage(zombie, 320.0, 0.25)
								plant["chew_timer"] = 7.5
							else:
								zombie["health"] = 0.0
								zombie["flash"] = 0.25
								plant["chew_timer"] = float(Defs.PLANTS["chomper"]["chew_time"])
							game.zombies[zombie_index] = zombie
							game._trigger_plant_action(plant, 0.42)
				"squash":
					if update_squash(plant, row, col, delta):
						game.grid[row][col] = null
						continue
				"tangle_kelp":
					if update_tangle_kelp(plant, row, col):
						game.grid[row][col] = null
						continue
				"spikeweed":
					update_spikeweed(plant, delta, row, col)
				"vine_lasher":
					update_vine_lasher(plant, delta, row, col)
				"pepper_mortar":
					update_pepper_mortar(plant, delta, row, col)
				"pulse_bulb":
					update_pulse_bulb(plant, delta, row, col)
				"sun_bean":
					update_sun_bean(plant, delta, row, col)
				"sun_shroom":
					update_sun_shroom(plant, delta, row, col)
				"marigold":
					update_marigold(plant, delta, row, col)
				"moon_lotus":
					update_moon_lotus(plant, delta, row, col)
				"prism_grass":
					update_prism_grass(plant, delta, row, col)
				"lantern_bloom":
					update_lantern_bloom(plant, delta, row, col)
				"meteor_gourd":
					update_meteor_gourd(plant, delta, row, col)
				"root_snare":
					update_root_snare(plant, delta, row, col)
				"thunder_pine":
					update_thunder_pine(plant, delta, row, col)
				"dream_drum":
					update_dream_drum(plant, delta, row, col)
				"fume_shroom":
					update_fume_shroom(plant, delta, row, col)
				"scaredy_shroom":
					update_scaredy_shroom(plant, delta, row, col)
				"grave_buster":
					if update_grave_buster(plant, delta, row, col):
						game.grid[row][col] = null
						continue
				"wind_orchid":
					update_wind_orchid(plant, delta, row, col)
				"magnet_shroom":
					update_magnet_shroom(plant, delta, row, col)
				"torchwood":
					update_torchwood(plant, delta, row, col)
				"lily_pad", "flower_pot", "wallnut", "tallnut", "hypno_shroom", "cactus_guard", "plantern", "pumpkin", "garlic", "umbrella_leaf", "brick_guard":
					pass

			game.grid[row][col] = plant
	for row in range(game.ROWS):
		for col in range(game.COLS):
			var support_variant = game.support_grid[row][col]
			if support_variant == null:
				continue
			var support = support_variant
			support["flash"] = maxf(0.0, float(support.get("flash", 0.0)) - delta)
			support["action_timer"] = maxf(0.0, float(support.get("action_timer", 0.0)) - delta)
			support["push_timer"] = maxf(0.0, float(support.get("push_timer", 0.0)) - delta)
			if float(support.get("push_timer", 0.0)) <= 0.0:
				support["push_offset_x"] = 0.0
			support["plant_food_timer"] = maxf(0.0, float(support.get("plant_food_timer", 0.0)) - delta)
			if float(support.get("plant_food_timer", 0.0)) <= 0.0 and String(support.get("plant_food_mode", "")) != "":
				support["plant_food_mode"] = ""
			game.support_grid[row][col] = support


func has_any_enemy_zombie() -> bool:
	for zombie in game.zombies:
		if game._is_enemy_zombie(zombie):
			return true
	return false


func has_zombie_behind(row: int, plant_x: float, range_limit: float = 10000.0) -> bool:
	for zombie in game.zombies:
		if int(zombie["row"]) != row or not game._is_enemy_zombie(zombie) or game._is_hidden_from_lane_attacks(zombie):
			continue
		var distance = plant_x - float(zombie["x"])
		if distance > 8.0 and distance <= range_limit:
			return true
	return false


func has_balloon_target_ahead(row: int, plant_x: float, range_limit: float = 10000.0) -> bool:
	for zombie in game.zombies:
		if int(zombie["row"]) != row or not game._is_enemy_zombie(zombie):
			continue
		if not bool(zombie.get("balloon_flying", false)):
			continue
		var distance = float(zombie["x"]) - plant_x
		if distance > 8.0 and distance <= range_limit:
			return true
	return false


func find_lane_or_air_target(row: int, plant_x: float, range_limit: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not game._is_enemy_zombie(zombie):
			continue
		var balloon = bool(zombie.get("balloon_flying", false))
		if game._is_hidden_from_lane_attacks(zombie) and not balloon:
			continue
		var distance = float(zombie["x"]) - plant_x
		if distance < -8.0 or distance > range_limit:
			continue
		if not balloon and game._is_roof_direct_fire_blocked(plant_x, float(zombie["x"])):
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func update_cactus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	if String(plant.get("plant_food_mode", "")) == "cactus_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		var storm_center = game._cell_center(row, col)
		while float(plant["plant_food_interval"]) <= 0.0:
			for y_offset in [-18.0, -2.0]:
				game._spawn_projectile(row, storm_center + Vector2(32.0, y_offset), Color(0.58, 0.96, 0.46), float(Defs.PLANTS["cactus"]["damage"]) * 1.2, 0.0, 520.0, 7.0)
				game.projectiles[game.projectiles.size() - 1]["anti_air"] = true
			plant["plant_food_interval"] += 0.08
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			game._trigger_plant_action(plant, 0.14)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var range_limit = float(Defs.PLANTS["cactus"]["range"])
	if not game._has_zombie_ahead(row, center.x, range_limit) and not has_balloon_target_ahead(row, center.x, range_limit):
		return
	game._spawn_projectile(row, center + Vector2(32.0, -22.0), Color(0.48, 0.86, 0.42), float(Defs.PLANTS["cactus"]["damage"]), 0.0, 470.0, 7.0)
	game.projectiles[game.projectiles.size() - 1]["anti_air"] = true
	plant["shot_cooldown"] = float(Defs.PLANTS["cactus"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.18)


func update_blover(plant: Dictionary, delta: float, _row: int, _col: int) -> bool:
	plant["fuse_timer"] -= delta
	if float(plant["fuse_timer"]) > 0.0:
		return false
	var burst_mode = String(plant.get("plant_food_mode", "")) == "blover_burst"
	game._trigger_blover_fog_clear(8.0 if burst_mode else float(Defs.PLANTS["blover"]["blover_duration"]))
	for i in range(game.zombies.size() - 1, -1, -1):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		if bool(zombie.get("balloon_flying", false)):
			game.effects.append({
				"position": Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 20.0),
				"radius": 48.0,
				"time": 0.22,
				"duration": 0.22,
				"color": Color(0.82, 1.0, 0.92, 0.24),
			})
			game.zombies.remove_at(i)
			continue
		if burst_mode:
			zombie["x"] = minf(float(zombie["x"]) + 96.0, game.BOARD_ORIGIN.x + game.board_size.x + 60.0)
			zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.4)
			zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.18)
			game.zombies[i] = zombie
	game.effects.append({
		"shape": "lane_spray",
		"position": game.BOARD_ORIGIN + Vector2(40.0, game.board_size.y * 0.5),
		"length": game.board_size.x,
		"width": game.board_size.y,
		"radius": game.board_size.x,
		"time": 0.2,
		"duration": 0.2,
		"color": Color(0.82, 1.0, 0.92, 0.2),
	})
	return true


func update_split_pea(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	if String(plant.get("plant_food_mode", "")) == "split_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		var storm_center = game._cell_center(row, col)
		while float(plant["plant_food_interval"]) <= 0.0:
			for y_offset in [-16.0, -4.0]:
				game._spawn_projectile(row, storm_center + Vector2(34.0, y_offset), Color(0.4, 0.9, 0.34), float(Defs.PLANTS["split_pea"]["damage"]) * 1.15, 0.0, 460.0, 8.0)
				game._spawn_projectile(row, storm_center + Vector2(-28.0, y_offset - 1.0), Color(0.48, 0.92, 0.42), float(Defs.PLANTS["split_pea"]["damage"]) * 1.15, 0.0, -460.0, 8.0)
			plant["plant_food_interval"] += 0.12
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			game._trigger_plant_action(plant, 0.14)
		return
	plant["shot_cooldown"] -= cadence_delta
	plant["rear_shot_cooldown"] -= cadence_delta
	var center = game._cell_center(row, col)
	var damage = float(Defs.PLANTS["split_pea"]["damage"])
	if float(plant["shot_cooldown"]) <= 0.0 and game._has_zombie_ahead(row, center.x):
		game._spawn_projectile(row, center + Vector2(34.0, -12.0), Color(0.36, 0.84, 0.28), damage, 0.0)
		plant["shot_cooldown"] = float(Defs.PLANTS["split_pea"]["shoot_interval"])
		game._trigger_plant_action(plant, 0.16)
	if float(plant["rear_shot_cooldown"]) <= 0.0 and has_zombie_behind(row, center.x):
		game._spawn_projectile(row, center + Vector2(-28.0, -14.0), Color(0.42, 0.86, 0.34), damage, 0.0, -430.0, 8.0)
		plant["rear_shot_cooldown"] = float(Defs.PLANTS["split_pea"]["rear_interval"])
		game._trigger_plant_action(plant, 0.16)


func spawn_starfruit_projectile(row: int, position: Vector2, speed: float, velocity_y: float) -> void:
	game.projectiles.append({
		"kind": "star",
		"row": row,
		"position": position,
		"speed": speed,
		"velocity_y": velocity_y,
		"damage": float(Defs.PLANTS["starfruit"]["damage"]),
		"slow_duration": 0.0,
		"color": Color(1.0, 0.9, 0.34),
		"radius": 8.0,
		"reflected": false,
		"fire": false,
		"free_aim": velocity_y != 0.0,
		"anti_air": false,
	})


func update_starfruit(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	if String(plant.get("plant_food_mode", "")) == "star_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		var storm_center = game._cell_center(row, col)
		while float(plant["plant_food_interval"]) <= 0.0:
			for burst_index in range(2):
				var x_offset = 4.0 * float(burst_index)
				spawn_starfruit_projectile(row, storm_center + Vector2(30.0 + x_offset, -12.0), 400.0, 0.0)
				spawn_starfruit_projectile(row, storm_center + Vector2(22.0 + x_offset, -18.0), 300.0, -300.0)
				spawn_starfruit_projectile(row, storm_center + Vector2(22.0 + x_offset, -6.0), 300.0, 300.0)
				spawn_starfruit_projectile(row, storm_center + Vector2(-18.0 - x_offset, -18.0), -300.0, -300.0)
				spawn_starfruit_projectile(row, storm_center + Vector2(-18.0 - x_offset, -6.0), -300.0, 300.0)
			plant["plant_food_interval"] += 0.12
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			game._trigger_plant_action(plant, 0.14)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not has_any_enemy_zombie():
		return
	var center = game._cell_center(row, col)
	spawn_starfruit_projectile(row, center + Vector2(30.0, -12.0), 360.0, 0.0)
	spawn_starfruit_projectile(row, center + Vector2(22.0, -18.0), 260.0, -260.0)
	spawn_starfruit_projectile(row, center + Vector2(22.0, -6.0), 260.0, 260.0)
	spawn_starfruit_projectile(row, center + Vector2(-18.0, -18.0), -260.0, -260.0)
	spawn_starfruit_projectile(row, center + Vector2(-18.0, -6.0), -260.0, 260.0)
	plant["shot_cooldown"] = float(Defs.PLANTS["starfruit"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.2)


func strip_metal_from_zombie(zombie: Dictionary) -> Dictionary:
	match String(zombie.get("kind", "")):
		"digger_zombie":
			if bool(zombie.get("digger_tunneling", false)):
				zombie["digger_tunneling"] = false
				zombie["base_speed"] = float(Defs.ZOMBIES["digger_zombie"]["speed"])
		"pogo_zombie":
			zombie["pogo_active"] = false
		"jack_in_the_box_zombie":
			zombie["jack_armed"] = false
			zombie["jack_timer"] = 9999.0
		"screen_door", "basketball", "qinghua", "lifebuoy_bucket", "barrel_screen_zombie":
			zombie["shield_health"] = 0.0
			zombie["max_shield_health"] = 0.0
	zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.18)
	zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.18)
	return zombie


func can_magnet_strip(zombie: Dictionary) -> bool:
	match String(zombie.get("kind", "")):
		"digger_zombie":
			return bool(zombie.get("digger_tunneling", false))
		"pogo_zombie":
			return bool(zombie.get("pogo_active", false))
		"jack_in_the_box_zombie":
			return bool(zombie.get("jack_armed", false))
		"screen_door", "basketball", "qinghua", "lifebuoy_bucket", "barrel_screen_zombie":
			return float(zombie.get("shield_health", 0.0)) > 0.0
		_:
			return false


func update_magnet_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var radius = maxf(float(Defs.PLANTS["magnet_shroom"].get("reveal_radius", 260.0)), game.CELL_SIZE.x * 4.2)
	var pulled := 0
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		if center.distance_to(Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))) > radius:
			continue
		if not can_magnet_strip(zombie):
			continue
		zombie = strip_metal_from_zombie(zombie)
		game.zombies[i] = zombie
		pulled += 1
	if pulled > 0:
		game.effects.append({
			"position": center,
			"radius": radius,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.82, 0.72, 1.0, 0.22),
		})
		game._trigger_plant_action(plant, 0.18)
	plant["support_timer"] = float(Defs.PLANTS["magnet_shroom"]["pulse_interval"])


func update_basic_shooter(plant: Dictionary, delta: float, row: int, col: int, projectile_color: Color, slow_duration: float) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return

	var center_x = game._cell_center(row, col).x
	var kind = String(plant["kind"])
	var range_limit = float(Defs.PLANTS[kind].get("range", 10000.0))
	if not game._has_zombie_ahead(row, center_x, range_limit):
		return

	var damage = float(Defs.PLANTS[kind]["damage"])
	game._spawn_projectile(row, game._cell_center(row, col) + Vector2(32.0, -10.0), projectile_color, damage, slow_duration)
	plant["shot_cooldown"] = float(Defs.PLANTS[kind]["shoot_interval"])
	game._trigger_plant_action(plant, 0.18)


func spawn_roof_lobbed_projectile(kind: String, row: int, spawn_position: Vector2, target: Vector2, damage: float, color: Color, arc_height: float, radius: float = 10.0, splash_radius: float = 0.0, butter_duration: float = 0.0) -> void:
	var travel_duration = maxf(spawn_position.distance_to(target) / 380.0, 0.42)
	game.projectiles.append({
		"kind": kind,
		"row": row,
		"position": spawn_position,
		"speed": maxf((target.x - spawn_position.x) / travel_duration, 0.0),
		"velocity_y": 0.0,
		"damage": damage,
		"slow_duration": 0.0,
		"color": color,
		"radius": radius,
		"reflected": false,
		"fire": false,
		"free_aim": false,
		"anti_air": false,
		"arc_origin": spawn_position,
		"arc_target": target,
		"arc_time": 0.0,
		"arc_duration": travel_duration,
		"arc_height": arc_height,
		"splash_radius": splash_radius,
		"butter_duration": butter_duration,
	})


func update_cabbage_pult(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "cabbage_barrage" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			var barrage_target = game._find_throw_lane_target(row, center.x, game.board_size.x + game.CELL_SIZE.x)
			if barrage_target != -1:
				var barrage_zombie = game.zombies[barrage_target]
				spawn_roof_lobbed_projectile("cabbage", row, center + Vector2(12.0, -30.0), Vector2(float(barrage_zombie["x"]), game._row_center_y(int(barrage_zombie["row"])) - 8.0), float(Defs.PLANTS["cabbage_pult"]["damage"]) * 1.25, Color(0.56, 0.92, 0.34), 68.0, 10.0)
				plant["flash"] = maxf(float(plant["flash"]), 0.16)
				game._trigger_plant_action(plant, 0.16)
			plant["plant_food_interval"] += 0.18
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var target_index = game._find_throw_lane_target(row, center.x, game.board_size.x + game.CELL_SIZE.x)
	if target_index == -1:
		return
	var zombie = game.zombies[target_index]
	spawn_roof_lobbed_projectile("cabbage", row, center + Vector2(12.0, -30.0), Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 8.0), float(Defs.PLANTS["cabbage_pult"]["damage"]), Color(0.56, 0.92, 0.34), 66.0, 10.0)
	plant["shot_cooldown"] = float(Defs.PLANTS["cabbage_pult"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_kernel_pult(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	var butter_mode = String(plant.get("plant_food_mode", "")) == "butter_barrage" and float(plant.get("plant_food_timer", 0.0)) > 0.0
	if butter_mode:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			var barrage_target = game._find_throw_lane_target(row, center.x, game.board_size.x + game.CELL_SIZE.x)
			if barrage_target != -1:
				var barrage_zombie = game.zombies[barrage_target]
				spawn_roof_lobbed_projectile("butter", row, center + Vector2(14.0, -26.0), Vector2(float(barrage_zombie["x"]), game._row_center_y(int(barrage_zombie["row"])) - 6.0), float(Defs.PLANTS["kernel_pult"]["damage"]) * 1.2, Color(1.0, 0.92, 0.42), 64.0, 10.0, 0.0, float(Defs.PLANTS["kernel_pult"]["butter_duration"]) + 1.4)
				plant["flash"] = maxf(float(plant["flash"]), 0.16)
				game._trigger_plant_action(plant, 0.16)
			plant["plant_food_interval"] += 0.2
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var target_index = game._find_throw_lane_target(row, center.x, game.board_size.x + game.CELL_SIZE.x)
	if target_index == -1:
		return
	var zombie = game.zombies[target_index]
	var butter_chance = float(Defs.PLANTS["kernel_pult"]["butter_chance"])
	var projectile_kind = "butter" if game.rng.randf() <= butter_chance else "kernel"
	var projectile_color = Color(1.0, 0.92, 0.42) if projectile_kind == "butter" else Color(0.98, 0.88, 0.34)
	var butter_duration = float(Defs.PLANTS["kernel_pult"]["butter_duration"]) if projectile_kind == "butter" else 0.0
	spawn_roof_lobbed_projectile(projectile_kind, row, center + Vector2(14.0, -26.0), Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 6.0), float(Defs.PLANTS["kernel_pult"]["damage"]), projectile_color, 62.0, 10.0, 0.0, butter_duration)
	plant["shot_cooldown"] = float(Defs.PLANTS["kernel_pult"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_melon_pult(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "melon_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			var storm_target = game._find_global_frontmost_target()
			if int(storm_target.get("row", -1)) != -1:
				var storm_impact = Vector2(float(storm_target["x"]), game._row_center_y(int(storm_target["row"])) - 8.0)
				spawn_roof_lobbed_projectile("melon", row, center + Vector2(10.0, -34.0), storm_impact, float(Defs.PLANTS["melon_pult"]["damage"]) * 1.18, Color(0.42, 0.82, 0.26), 82.0, 14.0, float(Defs.PLANTS["melon_pult"]["splash_radius"]) + 18.0)
				plant["flash"] = maxf(float(plant["flash"]), 0.16)
				game._trigger_plant_action(plant, 0.18)
			plant["plant_food_interval"] += 0.24
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var target_index = game._find_throw_lane_target(row, center.x, game.board_size.x + game.CELL_SIZE.x)
	if target_index == -1:
		return
	var zombie = game.zombies[target_index]
	spawn_roof_lobbed_projectile("melon", row, center + Vector2(10.0, -34.0), Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 8.0), float(Defs.PLANTS["melon_pult"]["damage"]), Color(0.42, 0.82, 0.26), 78.0, 14.0, float(Defs.PLANTS["melon_pult"]["splash_radius"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["melon_pult"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.24)


func update_origami_blossom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "origami_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for y_offset in [-20.0, -6.0]:
				game._spawn_projectile(row, center + Vector2(30.0, y_offset), Color(0.96, 0.9, 0.74), float(Defs.PLANTS["origami_blossom"]["damage"]) * 1.12, 0.0, 500.0, 7.0)
				if not game.projectiles.is_empty():
					game.projectiles[game.projectiles.size() - 1]["anti_air"] = true
					game.projectiles[game.projectiles.size() - 1]["kind"] = "origami_plane"
			plant["plant_food_interval"] += 0.11
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			game._trigger_plant_action(plant, 0.14)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var target_index = find_lane_or_air_target(row, center.x, float(Defs.PLANTS["origami_blossom"]["range"]))
	if target_index == -1:
		return
	game._spawn_projectile(row, center + Vector2(30.0, -16.0), Color(0.96, 0.9, 0.74), float(Defs.PLANTS["origami_blossom"]["damage"]), 0.0, 480.0, 7.0)
	if not game.projectiles.is_empty():
		game.projectiles[game.projectiles.size() - 1]["anti_air"] = true
		game.projectiles[game.projectiles.size() - 1]["kind"] = "origami_plane"
	plant["shot_cooldown"] = float(Defs.PLANTS["origami_blossom"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.18)


func update_chimney_pepper(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "chimney_volley" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			var storm_target = game._find_global_frontmost_target()
			if int(storm_target.get("row", -1)) != -1:
				spawn_roof_lobbed_projectile("chimney_fire", row, center + Vector2(8.0, -38.0), Vector2(float(storm_target["x"]), game._row_center_y(int(storm_target["row"])) - 8.0), float(Defs.PLANTS["chimney_pepper"]["damage"]) * 1.15, Color(1.0, 0.54, 0.22), 84.0, 11.0, float(Defs.PLANTS["chimney_pepper"]["splash_radius"]) + 18.0)
				plant["flash"] = maxf(float(plant["flash"]), 0.18)
				game._trigger_plant_action(plant, 0.16)
			plant["plant_food_interval"] += 0.2
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var target_index = game._find_throw_lane_target(row, center.x, game.board_size.x + game.CELL_SIZE.x)
	if target_index == -1:
		return
	var zombie = game.zombies[target_index]
	spawn_roof_lobbed_projectile("chimney_fire", row, center + Vector2(8.0, -38.0), Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 8.0), float(Defs.PLANTS["chimney_pepper"]["damage"]), Color(1.0, 0.54, 0.22), 78.0, 11.0, float(Defs.PLANTS["chimney_pepper"]["splash_radius"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["chimney_pepper"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_tesla_tulip(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "tesla_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			var storm_target = game._find_global_frontmost_target()
			if int(storm_target.get("row", -1)) != -1:
				var storm_index = game._find_throw_lane_target(int(storm_target["row"]), float(storm_target["x"]) - 6.0, game.board_size.x)
				if storm_index != -1:
					game._strike_thunder_chain(storm_index, float(Defs.PLANTS["tesla_tulip"]["damage"]) * 1.15, float(Defs.PLANTS["tesla_tulip"]["chain_damage"]) * 1.2, float(Defs.PLANTS["tesla_tulip"]["chain_range"]) + 24.0, 5)
			plant["plant_food_interval"] += 0.18
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.18)
		return
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target_index = game._find_throw_lane_target(row, center.x, game.board_size.x)
	if target_index == -1:
		plant["attack_timer"] = 0.2
		return
	var chained = game._strike_thunder_chain(target_index, float(Defs.PLANTS["tesla_tulip"]["damage"]), float(Defs.PLANTS["tesla_tulip"]["chain_damage"]), float(Defs.PLANTS["tesla_tulip"]["chain_range"]), 3)
	if chained > 0:
		var strike_center = Vector2(float(game.zombies[target_index]["x"]), game._row_center_y(int(game.zombies[target_index]["row"])) - 14.0)
		game.effects.append({
			"shape": "storm_arc",
			"position": center + Vector2(10.0, -20.0),
			"target": strike_center,
			"radius": strike_center.distance_to(center),
			"time": 0.18,
			"duration": 0.18,
			"color": Color(0.96, 0.88, 0.48, 0.32),
		})
		game._trigger_plant_action(plant, 0.22)
	plant["attack_timer"] = float(Defs.PLANTS["tesla_tulip"]["attack_interval"])


func update_signal_ivy(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var radius = float(Defs.PLANTS["signal_ivy"]["radius"])
	var damage = float(Defs.PLANTS["signal_ivy"]["damage"])
	if String(plant.get("plant_food_mode", "")) == "signal_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		radius = float(Defs.PLANTS["signal_ivy"]["reveal_radius"])
		damage *= 1.5
		plant["plant_food_mode"] = ""
		plant["plant_food_timer"] = 0.0
	var pulse_hit := false
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) > radius:
			continue
		zombie = game._apply_zombie_damage(zombie, damage, 0.12)
		if String(zombie.get("kind", "")) == "shouyue":
			zombie["revealed_timer"] = maxf(float(zombie.get("revealed_timer", 0.0)), 5.0)
		game.zombies[i] = zombie
		pulse_hit = true
	if pulse_hit:
		game.effects.append({
			"position": center,
			"radius": radius,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.72, 0.96, 1.0, 0.24),
		})
		game._trigger_plant_action(plant, 0.2)
	plant["support_timer"] = float(Defs.PLANTS["signal_ivy"]["pulse_interval"])


func update_roof_vane(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["gust_timer"] -= cadence_delta
	if float(plant["gust_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var affected_rows: Array = [row]
	var push_distance = float(Defs.PLANTS["roof_vane"]["push_distance"])
	if String(plant.get("plant_food_mode", "")) == "roof_gale" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		push_distance *= 1.5
		for lane in [row - 1, row + 1]:
			if lane >= 0 and lane < game.ROWS and game._is_row_active(lane):
				affected_rows.append(lane)
		plant["plant_food_mode"] = ""
		plant["plant_food_timer"] = 0.0
	var did_push := false
	for lane_variant in affected_rows:
		var lane = int(lane_variant)
		for i in range(game.zombies.size()):
			var zombie = game.zombies[i]
			if int(zombie["row"]) != lane or not game._is_enemy_zombie(zombie):
				continue
			zombie["x"] += push_distance
			zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.1)
			game.zombies[i] = zombie
			did_push = true
	if did_push:
		game.effects.append({
			"shape": "lane_spray",
			"position": center + Vector2(12.0, -8.0),
			"length": game.BOARD_ORIGIN.x + game.board_size.x - center.x,
			"width": game.CELL_SIZE.y * 0.82 * float(affected_rows.size()),
			"radius": game.BOARD_ORIGIN.x + game.board_size.x - center.x,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.88, 0.96, 1.0, 0.34),
		})
		game._trigger_plant_action(plant, 0.24)
	plant["gust_timer"] = float(Defs.PLANTS["roof_vane"]["gust_interval"])


func update_skylight_melon(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var target = game._find_global_frontmost_target()
	if int(target.get("row", -1)) == -1:
		return
	var impacted_rows: Array = []
	for lane in [int(target["row"]) - 1, int(target["row"]), int(target["row"]) + 1]:
		if lane < 0 or lane >= game.ROWS or not game._is_row_active(lane):
			continue
		impacted_rows.append(lane)
	var damage = float(Defs.PLANTS["skylight_melon"]["damage"])
	var splash = float(Defs.PLANTS["skylight_melon"]["splash_radius"])
	var boosted = String(plant.get("plant_food_mode", "")) == "skylight_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0
	if boosted:
		damage *= 1.15
		splash += 16.0
		plant["plant_food_interval"] -= cadence_delta
		if float(plant["plant_food_interval"]) > 0.0:
			return
		plant["plant_food_interval"] = 0.22
		if float(plant["plant_food_timer"]) <= 0.0:
			plant["plant_food_mode"] = ""
	for lane_variant in impacted_rows:
		var lane = int(lane_variant)
		var lane_damage = damage if lane == int(target["row"]) else damage * 0.82
		spawn_roof_lobbed_projectile("melon", lane, center + Vector2(10.0, -38.0), Vector2(float(target["x"]), game._row_center_y(lane) - 8.0), lane_damage, Color(0.52, 0.86, 0.34), 86.0, 14.0, splash)
	game._trigger_plant_action(plant, 0.24)
	if not boosted:
		plant["shot_cooldown"] = float(Defs.PLANTS["skylight_melon"]["shoot_interval"])
	else:
		plant["shot_cooldown"] = 0.18


func update_marigold(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	game._spawn_sun(center + Vector2(game.rng.randf_range(-10.0, 10.0), -18.0), center.y - 14.0, "plant")
	plant["sun_timer"] = float(Defs.PLANTS["marigold"]["sun_interval"])
	game._trigger_plant_action(plant, 0.28)


func update_shooter_plant_food(plant: Dictionary, delta: float, row: int, col: int, projectile_color: Color, slow_duration: float, volley_count: int, volley_interval: float) -> bool:
	var pf_mode = String(plant["plant_food_mode"])
	if pf_mode != "pea_storm" and pf_mode != "ice_storm":
		return false
	if float(plant["plant_food_timer"]) <= 0.0:
		return false

	plant["plant_food_interval"] -= delta
	var damage = float(Defs.PLANTS[String(plant["kind"])]["damage"])
	while float(plant["plant_food_interval"]) <= 0.0:
		for shot_index in range(volley_count):
			var y_offset = 0.0
			if volley_count > 1:
				y_offset = lerpf(-7.0, 7.0, float(shot_index) / float(max(volley_count - 1, 1)))
			game._spawn_projectile(
				row,
				game._cell_center(row, col) + Vector2(32.0, -10.0 + y_offset),
				projectile_color,
				damage,
				slow_duration
			)
		plant["plant_food_interval"] += volley_interval
		plant["flash"] = maxf(float(plant["flash"]), 0.16)
		game._trigger_plant_action(plant, 0.14)
	return true


func update_repeater(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	if String(plant["plant_food_mode"]) == "double_storm":
		if float(plant["plant_food_timer"]) > 0.0:
			plant["plant_food_interval"] -= cadence_delta
			while float(plant["plant_food_interval"]) <= 0.0:
				game._spawn_projectile(row, game._cell_center(row, col) + Vector2(32.0, -16.0), Color(0.3, 0.84, 0.26), 20.0, 0.0)
				game._spawn_projectile(row, game._cell_center(row, col) + Vector2(32.0, -4.0), Color(0.3, 0.84, 0.26), 20.0, 0.0)
				plant["plant_food_interval"] += 0.08
				plant["flash"] = maxf(float(plant["flash"]), 0.18)
				game._trigger_plant_action(plant, 0.16)
			return
		if int(plant["plant_food_charges"]) > 0:
			game._spawn_projectile(row, game._cell_center(row, col) + Vector2(38.0, -12.0), Color(0.32, 0.96, 0.38), 400.0, 0.0, 520.0, 14.0)
			plant["plant_food_charges"] = 0
			plant["plant_food_mode"] = ""
			plant["plant_food_interval"] = 0.0
			plant["flash"] = maxf(float(plant["flash"]), 0.2)
			game._trigger_plant_action(plant, 0.32)
			return

	plant["shot_cooldown"] -= cadence_delta
	if int(plant["burst_remaining"]) > 0:
		plant["burst_gap_timer"] -= cadence_delta
		if float(plant["burst_gap_timer"]) <= 0.0:
			var burst_damage = float(Defs.PLANTS["repeater"]["damage"])
			game._spawn_projectile(row, game._cell_center(row, col) + Vector2(32.0, -10.0), Color(0.3, 0.84, 0.26), burst_damage, 0.0)
			plant["burst_remaining"] = int(plant["burst_remaining"]) - 1
			if int(plant["burst_remaining"]) > 0:
				plant["burst_gap_timer"] = float(Defs.PLANTS["repeater"]["burst_gap"])
			game._trigger_plant_action(plant, 0.16)

	if float(plant["shot_cooldown"]) > 0.0:
		return

	var center_x = game._cell_center(row, col).x
	if not game._has_zombie_ahead(row, center_x):
		return

	var damage = float(Defs.PLANTS["repeater"]["damage"])
	game._spawn_projectile(row, game._cell_center(row, col) + Vector2(32.0, -10.0), Color(0.3, 0.84, 0.26), damage, 0.0)
	plant["burst_remaining"] = int(Defs.PLANTS["repeater"]["burst_count"]) - 1
	plant["burst_gap_timer"] = float(Defs.PLANTS["repeater"]["burst_gap"])
	plant["shot_cooldown"] = float(Defs.PLANTS["repeater"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func threepeater_rows(row: int) -> Array:
	var rows: Array = []
	for lane in [row - 1, row, row + 1]:
		if lane < 0 or lane >= game.ROWS or not game._is_row_active(lane):
			continue
		rows.append(lane)
	return rows


func update_threepeater(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var pf_mode = String(plant.get("plant_food_mode", ""))
	if pf_mode == "tri_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		var storm_rows = threepeater_rows(row)
		while float(plant["plant_food_interval"]) <= 0.0:
			for lane in storm_rows:
				game._spawn_projectile(lane, threepeater_projectile_spawn_position(col, int(lane)), Color(0.38, 0.88, 0.32), 20.0, 0.0)
			plant["plant_food_interval"] += 0.1
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center_x = game._cell_center(row, col).x
	var lanes = threepeater_rows(row)
	var has_target := false
	for lane in lanes:
		if game._has_zombie_ahead(int(lane), center_x):
			has_target = true
			break
	if not has_target:
		return
	var damage = float(Defs.PLANTS["threepeater"]["damage"])
	for lane in lanes:
		game._spawn_projectile(int(lane), threepeater_projectile_spawn_position(col, int(lane)), Color(0.38, 0.88, 0.32), damage, 0.0)
	plant["shot_cooldown"] = float(Defs.PLANTS["threepeater"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func threepeater_projectile_spawn_position(col: int, lane: int) -> Vector2:
	return game._cell_center(lane, col) + Vector2(32.0, -10.0)


func spawn_boomerang_projectile(row: int, spawn_position: Vector2, anchor_x: float, damage: float, max_targets: int) -> void:
	game.projectiles.append({
		"kind": "boomerang",
		"row": row,
		"position": spawn_position,
		"speed": 420.0,
		"velocity_y": 0.0,
		"damage": damage,
		"slow_duration": 0.0,
		"color": Color(0.96, 0.72, 0.28),
		"radius": 11.0,
		"reflected": false,
		"fire": false,
		"outbound": true,
		"anchor_x": anchor_x,
		"max_hits": max_targets,
		"hit_uids": [],
		"return_hits": [],
		"return_markers": [],
	})


func spawn_sakura_projectile(row: int, spawn_position: Vector2, damage: float, velocity_y: float = 0.0) -> void:
	game.projectiles.append({
		"kind": "sakura_petal",
		"row": row,
		"position": spawn_position,
		"speed": 340.0,
		"velocity_y": velocity_y,
		"damage": damage,
		"slow_duration": 0.0,
		"color": Color(1.0, 0.68, 0.82),
		"radius": 8.0,
		"reflected": false,
		"fire": false,
		"free_aim": absf(velocity_y) > 0.01,
		"split_speed": float(Defs.PLANTS["sakura_shooter"]["split_speed"]),
	})


func update_boomerang_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "boomerang_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			spawn_boomerang_projectile(row, center + Vector2(34.0, -10.0), center.x + 8.0, float(Defs.PLANTS["boomerang_shooter"]["damage"]) * 1.2, int(Defs.PLANTS["boomerang_shooter"]["max_targets"]) + 1)
			plant["plant_food_interval"] += 0.18
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not game._has_zombie_ahead(row, center.x):
		return
	spawn_boomerang_projectile(row, center + Vector2(34.0, -10.0), center.x + 8.0, float(Defs.PLANTS["boomerang_shooter"]["damage"]), int(Defs.PLANTS["boomerang_shooter"]["max_targets"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["boomerang_shooter"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_sakura_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "sakura_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for velocity_y in [-150.0, 0.0, 150.0]:
				spawn_sakura_projectile(row, center + Vector2(34.0, -10.0 + velocity_y * 0.03), float(Defs.PLANTS["sakura_shooter"]["damage"]) * 1.15, velocity_y)
			plant["plant_food_interval"] += 0.16
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not game._has_zombie_ahead(row, center.x):
		return
	spawn_sakura_projectile(row, center + Vector2(34.0, -10.0), float(Defs.PLANTS["sakura_shooter"]["damage"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["sakura_shooter"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_lotus_lancer(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	var range_limit = float(Defs.PLANTS["lotus_lancer"]["range"])
	if String(plant.get("plant_food_mode", "")) == "lancer_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for lane in threepeater_rows(row):
				game._damage_zombies_in_row_segment(int(lane), center.x + 18.0, center.x + range_limit, float(Defs.PLANTS["lotus_lancer"]["damage"]) * 1.4)
				game.effects.append({
					"shape": "lane_spray",
					"position": game._cell_center(int(lane), col) + Vector2(18.0, -12.0),
					"length": range_limit,
					"width": 28.0,
					"radius": range_limit,
					"time": 0.22,
					"duration": 0.22,
					"color": Color(0.68, 0.96, 1.0, 0.28),
				})
			plant["plant_food_interval"] += 0.24
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not game._has_zombie_ahead(row, center.x, range_limit):
		return
	game._damage_zombies_in_row_segment(row, center.x + 18.0, center.x + range_limit, float(Defs.PLANTS["lotus_lancer"]["damage"]))
	game.effects.append({
		"shape": "lane_spray",
		"position": center + Vector2(18.0, -12.0),
		"length": range_limit,
		"width": 24.0,
		"radius": range_limit,
		"time": 0.2,
		"duration": 0.2,
		"color": Color(0.62, 0.92, 1.0, 0.24),
	})
	plant["shot_cooldown"] = float(Defs.PLANTS["lotus_lancer"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func spawn_mist_projectile(row: int, spawn_position: Vector2, damage: float, slow_duration: float, splash_radius: float, reveal_duration: float) -> void:
	game.projectiles.append({
		"kind": "mist_bloom",
		"row": row,
		"position": spawn_position,
		"speed": 340.0,
		"velocity_y": 0.0,
		"damage": damage,
		"slow_duration": slow_duration,
		"color": Color(0.8, 0.98, 0.96),
		"radius": 10.0,
		"reflected": false,
		"fire": false,
		"free_aim": false,
		"ignore_lane_hide": true,
		"splash_radius": splash_radius,
		"reveal_duration": reveal_duration,
	})


func apply_mist_bloom_splash(center: Vector2, projectile: Dictionary, main_uid: int) -> void:
	var radius = float(projectile.get("splash_radius", 44.0))
	var splash_damage = maxf(8.0, float(projectile.get("damage", 0.0)) * 0.46)
	var slow_duration = maxf(0.8, float(projectile.get("slow_duration", 0.0)) * 0.7)
	var reveal_duration = float(projectile.get("reveal_duration", 0.0))
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		if int(zombie.get("uid", -1)) == main_uid:
			if reveal_duration > 0.0:
				zombie["revealed_timer"] = maxf(float(zombie.get("revealed_timer", 0.0)), reveal_duration)
				game.zombies[i] = zombie
			continue
		var zombie_pos = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) > radius:
			continue
		zombie = game._apply_zombie_damage(zombie, splash_damage, 0.14, slow_duration)
		if reveal_duration > 0.0:
			zombie["revealed_timer"] = maxf(float(zombie.get("revealed_timer", 0.0)), reveal_duration)
		game.zombies[i] = zombie
	game._damage_obstacles_in_circle(center, radius * 0.85, splash_damage * 0.8)
	game.effects.append({
		"shape": "mist_cloud",
		"position": center,
		"radius": radius,
		"time": 0.24,
		"duration": 0.24,
		"color": Color(0.72, 0.96, 0.92, 0.28),
	})


func update_mist_orchid(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "mist_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for y_offset in [-12.0, 0.0, 12.0]:
				spawn_mist_projectile(
					row,
					center + Vector2(30.0, -8.0 + y_offset),
					float(Defs.PLANTS["mist_orchid"]["damage"]) * 0.9,
					float(Defs.PLANTS["mist_orchid"]["slow_duration"]) + 1.0,
					float(Defs.PLANTS["mist_orchid"]["splash_radius"]) + 18.0,
					float(Defs.PLANTS["mist_orchid"]["reveal_duration"]) + 1.0
				)
			plant["plant_food_interval"] += 0.16
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var range_limit = maxf(float(Defs.PLANTS["mist_orchid"]["range"]), game.board_size.x + game.CELL_SIZE.x)
	if game._find_lane_target_ignore_fog(row, center.x, range_limit) == -1:
		return
	spawn_mist_projectile(
		row,
		center + Vector2(30.0, -8.0),
		float(Defs.PLANTS["mist_orchid"]["damage"]),
		float(Defs.PLANTS["mist_orchid"]["slow_duration"]),
		float(Defs.PLANTS["mist_orchid"]["splash_radius"]),
		float(Defs.PLANTS["mist_orchid"]["reveal_duration"])
	)
	plant["shot_cooldown"] = float(Defs.PLANTS["mist_orchid"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.2)


func update_anchor_fern(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var rooted := false
	var root_duration = float(Defs.PLANTS["anchor_fern"]["rooted_duration"])
	for other_row in range(max(0, row - 1), min(game.ROWS, row + 2)):
		for other_col in range(max(0, col - 1), min(game.COLS, col + 2)):
			if other_row == row and other_col == col:
				continue
			var ally = game._targetable_plant_at(other_row, other_col)
			if ally == null:
				continue
			ally["rooted_timer"] = maxf(float(ally.get("rooted_timer", 0.0)), root_duration)
			ally["flash"] = maxf(float(ally.get("flash", 0.0)), 0.08)
			game._set_targetable_plant(other_row, other_col, ally)
			rooted = true
	var hit := false
	var nearby_targets = game._find_closest_zombies_in_radius(center + Vector2(24.0, 0.0), float(Defs.PLANTS["anchor_fern"]["range"]), 2)
	for zombie_index in nearby_targets:
		var zombie = game.zombies[zombie_index]
		if not game._is_enemy_zombie(zombie):
			continue
		zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["anchor_fern"]["damage"]), 0.14, 0.0, true)
		zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer", 0.0)), 0.7)
		game.zombies[zombie_index] = zombie
		hit = true
	if rooted or hit:
		game.effects.append({
			"shape": "anchor_ring",
			"position": center,
			"radius": game.CELL_SIZE.x * 1.12,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.48, 0.86, 0.5, 0.24),
		})
		plant["flash"] = maxf(float(plant["flash"]), 0.12)
		game._trigger_plant_action(plant, 0.22)
	plant["support_timer"] = float(Defs.PLANTS["anchor_fern"]["support_interval"])


func spawn_glowvine_projectile(row: int, spawn_position: Vector2, damage: float) -> void:
	game.projectiles.append({
		"kind": "glow_seed",
		"row": row,
		"position": spawn_position,
		"speed": 360.0,
		"velocity_y": 0.0,
		"damage": damage,
		"slow_duration": 0.0,
		"color": Color(0.62, 1.0, 0.72),
		"radius": 9.0,
		"reflected": false,
		"fire": false,
		"free_aim": false,
		"burst_radius": 96.0,
	})


func emit_glowvine_burst(center: Vector2, origin_row: int, damage: float) -> void:
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		if abs(int(zombie["row"]) - origin_row) > 1:
			continue
		var zombie_center = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		if zombie_center.distance_to(center) > 96.0:
			continue
		zombie = game._apply_zombie_damage(zombie, damage, 0.14)
		game.zombies[i] = zombie
	game._damage_obstacles_in_circle(center, 74.0, damage * 0.7)
	game.effects.append({
		"shape": "glow_burst",
		"position": center,
		"radius": 96.0,
		"time": 0.24,
		"duration": 0.24,
		"color": Color(0.68, 1.0, 0.76, 0.28),
	})


func update_glowvine(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "glow_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			spawn_glowvine_projectile(row, center + Vector2(30.0, -6.0), float(Defs.PLANTS["glowvine"]["damage"]) * 1.15)
			plant["plant_food_interval"] += 0.12
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not game._has_zombie_ahead(row, center.x, float(Defs.PLANTS["glowvine"]["range"])):
		return
	spawn_glowvine_projectile(row, center + Vector2(30.0, -6.0), float(Defs.PLANTS["glowvine"]["damage"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["glowvine"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.2)


func spawn_bog_pool(center: Vector2, radius: float, duration: float) -> void:
	game.effects.append({
		"shape": "bog_pool",
		"position": center,
		"radius": radius,
		"time": duration,
		"duration": duration,
		"color": Color(0.28, 0.64, 0.46, 0.26),
	})


func update_brine_pot(plant: Dictionary, delta: float, _row: int, _col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, int(plant["row"]), int(plant["col"]))
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target = game._find_global_frontmost_target()
	if int(target["row"]) == -1:
		plant["attack_timer"] = 0.28
		return
	var impact = Vector2(float(target["x"]), game._row_center_y(int(target["row"])))
	var splash_radius = float(Defs.PLANTS["brine_pot"]["splash_radius"])
	var damage = float(Defs.PLANTS["brine_pot"]["damage"])
	game._damage_zombies_in_circle(impact, splash_radius, damage)
	game._damage_obstacles_in_circle(impact, splash_radius * 0.9, damage)
	spawn_bog_pool(impact, float(Defs.PLANTS["brine_pot"]["bog_radius"]), float(Defs.PLANTS["brine_pot"]["bog_duration"]))
	game.effects.append({
		"position": impact,
		"radius": splash_radius,
		"time": 0.28,
		"duration": 0.28,
		"color": Color(0.68, 0.94, 0.84, 0.28),
	})
	plant["attack_timer"] = float(Defs.PLANTS["brine_pot"]["attack_interval"])
	plant["flash"] = maxf(float(plant["flash"]), 0.14)
	game._trigger_plant_action(plant, 0.22)


func update_storm_reed(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var trigger_col = int(Defs.PLANTS["storm_reed"]["trigger_col"])
	var trigger_x = game._cell_center(row, trigger_col).x - game.CELL_SIZE.x * 0.4
	var target_index = game._find_storm_reed_target(row, trigger_x)
	if target_index == -1:
		plant["support_timer"] = 0.24
		return
	var chain_damage = float(Defs.PLANTS["storm_reed"]["damage"]) * 0.62
	var hit_count = game._strike_thunder_chain(target_index, float(Defs.PLANTS["storm_reed"]["damage"]), chain_damage, float(Defs.PLANTS["storm_reed"]["chain_range"]), 3)
	if hit_count > 0:
		var strike_center = Vector2(float(game.zombies[target_index]["x"]), game._row_center_y(int(game.zombies[target_index]["row"])) - 14.0)
		game.effects.append({
			"shape": "storm_arc",
			"position": game._cell_center(row, col) + Vector2(12.0, -18.0),
			"target": strike_center,
			"radius": strike_center.distance_to(game._cell_center(row, col)),
			"time": 0.18,
			"duration": 0.18,
			"color": Color(0.92, 0.98, 0.54, 0.34),
		})
		plant["flash"] = maxf(float(plant["flash"]), 0.16)
		game._trigger_plant_action(plant, 0.22)
	plant["support_timer"] = float(Defs.PLANTS["storm_reed"]["pulse_interval"])


func spawn_moonforge_projectile(origin: Vector2, target: Vector2, damage: float, splash_radius: float) -> void:
	var delta = target - origin
	var speed = 310.0
	var travel_time = maxf(delta.x / speed, 0.14)
	game.projectiles.append({
		"kind": "moon_meteor",
		"row": clampi(int(round((target.y - game.BOARD_ORIGIN.y) / game.CELL_SIZE.y)), 0, game.ROWS - 1),
		"position": origin,
		"speed": speed,
		"velocity_y": delta.y / travel_time,
		"damage": damage,
		"slow_duration": 0.0,
		"color": Color(1.0, 0.82, 0.48),
		"radius": 12.0,
		"reflected": false,
		"fire": false,
		"free_aim": true,
		"target": target,
		"splash_radius": splash_radius,
	})


func explode_moonforge_projectile(projectile: Dictionary, impact: Vector2) -> void:
	var splash_radius = float(projectile.get("splash_radius", 72.0))
	var damage = float(projectile.get("damage", 0.0))
	game._damage_zombies_in_circle(impact, splash_radius, damage)
	game._damage_obstacles_in_circle(impact, splash_radius * 0.92, damage)
	game.effects.append({
		"shape": "moon_blast",
		"position": impact,
		"radius": splash_radius,
		"time": 0.3,
		"duration": 0.3,
		"color": Color(1.0, 0.82, 0.54, 0.34),
	})


func update_moonforge(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var target = game._find_global_frontmost_target()
	if int(target["row"]) == -1:
		plant["shot_cooldown"] = 0.35
		return
	var origin = game._cell_center(row, col) + Vector2(20.0, -16.0)
	var impact = Vector2(float(target["x"]), game._row_center_y(int(target["row"])) - 14.0)
	spawn_moonforge_projectile(origin, impact, float(Defs.PLANTS["moonforge"]["damage"]), float(Defs.PLANTS["moonforge"]["splash_radius"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["moonforge"]["shoot_interval"])
	plant["flash"] = maxf(float(plant["flash"]), 0.16)
	game._trigger_plant_action(plant, 0.24)


func update_mirror_reed(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var reveal_radius = float(Defs.PLANTS["mirror_reed"]["reveal_radius"])
	var damage_radius = maxf(float(Defs.PLANTS["mirror_reed"]["radius"]), reveal_radius * 0.9)
	var damage = float(Defs.PLANTS["mirror_reed"]["damage"])
	if String(plant.get("plant_food_mode", "")) == "mirror_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		reveal_radius += 120.0
		damage_radius += 90.0
		damage *= 1.8
		plant["plant_food_mode"] = ""
		plant["plant_food_timer"] = 0.0
	var did_hit = game._damage_zombies_in_circle(center, damage_radius, damage)
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if String(zombie.get("kind", "")) != "shouyue" or not game._is_enemy_zombie(zombie):
			continue
		var zombie_center = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		if zombie_center.distance_to(center) > reveal_radius:
			continue
		zombie["revealed_timer"] = maxf(float(zombie.get("revealed_timer", 0.0)), 3.8)
		game.zombies[i] = zombie
	game.effects.append({
		"position": center,
		"radius": reveal_radius,
		"time": 0.28,
		"duration": 0.28,
		"color": Color(0.76, 0.92, 1.0, 0.22 if did_hit else 0.16),
	})
	plant["support_timer"] = float(Defs.PLANTS["mirror_reed"]["pulse_interval"])
	plant["flash"] = maxf(float(plant["flash"]), 0.12)
	game._trigger_plant_action(plant, 0.18)


func update_frost_fan(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	var range_limit = float(Defs.PLANTS["frost_fan"]["range"])
	var slow_duration = float(Defs.PLANTS["frost_fan"]["slow_duration"])
	var lanes = threepeater_rows(row)
	if String(plant.get("plant_food_mode", "")) == "frost_gale" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for lane in game.active_rows:
				game._damage_zombies_in_row_segment(int(lane), center.x + 12.0, center.x + range_limit, float(Defs.PLANTS["frost_fan"]["damage"]) * 1.35, slow_duration + 4.0)
				game.effects.append({
					"shape": "lane_spray",
					"position": game._cell_center(int(lane), col) + Vector2(18.0, -10.0),
					"length": range_limit,
					"width": 34.0,
					"radius": range_limit,
					"time": 0.22,
					"duration": 0.22,
					"color": Color(0.82, 0.98, 1.0, 0.26),
				})
			plant["plant_food_interval"] += 0.24
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var has_target := false
	for lane in lanes:
		if game._has_zombie_ahead(int(lane), center.x, range_limit):
			has_target = true
			break
	if not has_target:
		return
	for lane in lanes:
		game._damage_zombies_in_row_segment(int(lane), center.x + 16.0, center.x + range_limit, float(Defs.PLANTS["frost_fan"]["damage"]), slow_duration)
		game.effects.append({
			"shape": "lane_spray",
			"position": game._cell_center(int(lane), col) + Vector2(18.0, -10.0),
			"length": range_limit,
			"width": 30.0,
			"radius": range_limit,
			"time": 0.2,
			"duration": 0.2,
			"color": Color(0.8, 0.98, 1.0, 0.22),
		})
	plant["shot_cooldown"] = float(Defs.PLANTS["frost_fan"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func find_squash_target(row: int, center_x: float, range_limit: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not game._is_enemy_zombie(zombie):
			continue
		var distance = absf(float(zombie["x"]) - center_x)
		if distance > range_limit:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func resolve_squash_impact(plant: Dictionary, row: int, col: int) -> void:
	var center = game._cell_center(row, col)
	var impact_center = Vector2(float(plant.get("attack_target_x", center.x + 36.0)), game._row_center_y(int(plant.get("attack_target_row", row))))
	var targets = game._find_closest_zombies_in_radius(impact_center, 88.0, max(1, game.zombies.size()))
	if targets.is_empty():
		var fallback = find_squash_target(row, impact_center.x, float(Defs.PLANTS["squash"]["range"]) + 30.0)
		if fallback != -1:
			targets.append(fallback)
	if targets.is_empty():
		game.effects.append({
			"shape": "squash_slam",
			"position": impact_center,
			"radius": 72.0,
			"time": 0.26,
			"duration": 0.26,
			"color": Color(0.66, 0.96, 0.2, 0.32),
		})
		return
	for target_index in targets:
		var zombie = game.zombies[int(target_index)]
		zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["squash"]["damage"]), 0.24, 0.0, true)
		game.zombies[int(target_index)] = zombie
	game.effects.append({
		"shape": "squash_slam",
		"position": impact_center,
		"radius": 88.0,
		"time": 0.3,
		"duration": 0.3,
		"color": Color(0.66, 0.96, 0.2, 0.38),
	})


func update_squash(plant: Dictionary, row: int, col: int, delta: float = 0.0) -> bool:
	var center = game._cell_center(row, col)
	var state = String(plant.get("special_state", ""))
	if state == "":
		var target_index = find_squash_target(row, center.x, float(Defs.PLANTS["squash"]["range"]))
		if target_index == -1:
			return false
		var target = game.zombies[target_index]
		plant["special_state"] = "windup"
		plant["special_duration"] = 0.18
		plant["special_timer"] = 0.18
		plant["attack_target_x"] = float(target["x"])
		plant["attack_target_row"] = int(target["row"])
		plant["attack_has_hit"] = false
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.14)
		game._trigger_plant_action(plant, 0.22)
		return false
	plant["special_timer"] = maxf(0.0, float(plant.get("special_timer", 0.0)) - delta)
	match state:
		"windup":
			if float(plant["special_timer"]) > 0.0:
				return false
			plant["special_state"] = "launch"
			plant["special_duration"] = 0.16
			plant["special_timer"] = 0.16
			game._trigger_plant_action(plant, 0.16)
			return false
		"launch":
			var duration = maxf(float(plant.get("special_duration", 0.16)), 0.01)
			var progress = 1.0 - clampf(float(plant["special_timer"]) / duration, 0.0, 1.0)
			if not bool(plant.get("attack_has_hit", false)) and progress >= 0.78:
				plant["attack_has_hit"] = true
				resolve_squash_impact(plant, row, col)
				plant["special_state"] = "slam"
				plant["special_duration"] = 0.1
				plant["special_timer"] = 0.1
			return false
		"slam":
			return float(plant["special_timer"]) <= 0.0
	return false


func find_kelp_target(row: int, center_x: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not game._is_enemy_zombie(zombie):
			continue
		var distance = absf(float(zombie["x"]) - center_x)
		if distance > float(Defs.PLANTS["tangle_kelp"]["range"]):
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func update_tangle_kelp(_plant: Dictionary, row: int, col: int) -> bool:
	var center = game._cell_center(row, col)
	var target_index = find_kelp_target(row, center.x)
	if target_index == -1:
		return false
	var zombie = game.zombies[target_index]
	zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["tangle_kelp"]["damage"]), 0.3, 0.0, true)
	zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.45)
	game.zombies[target_index] = zombie
	game.effects.append({
		"position": Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) + 18.0),
		"radius": 68.0,
		"time": 0.32,
		"duration": 0.32,
		"color": Color(0.18, 0.72, 0.46, 0.34),
	})
	return true


func update_spikeweed(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["contact_timer"] -= delta
	if float(plant["contact_timer"]) > 0.0:
		return
	var center_x = game._cell_center(row, col).x
	var hit := false
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not game._is_enemy_zombie(zombie):
			continue
		if absf(float(zombie["x"]) - center_x) > 42.0:
			continue
		zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["spikeweed"]["contact_damage"]), 0.1)
		game.zombies[i] = zombie
		hit = true
	if hit:
		plant["flash"] = maxf(float(plant["flash"]), 0.12)
		game._trigger_plant_action(plant, 0.14)
	plant["contact_timer"] = float(Defs.PLANTS["spikeweed"]["contact_interval"])


func update_torchwood(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if String(plant.get("plant_food_mode", "")) != "fire_storm" or float(plant.get("plant_food_timer", 0.0)) <= 0.0:
		return
	plant["plant_food_interval"] -= delta
	while float(plant["plant_food_interval"]) <= 0.0:
		for lane in game.active_rows:
			game._spawn_fire_projectile(int(lane), game._cell_center(row, col) + Vector2(18.0, -10.0), 40.0, 520.0, 9.0)
		plant["plant_food_interval"] += 0.14
		plant["flash"] = maxf(float(plant["flash"]), 0.16)
		game._trigger_plant_action(plant, 0.16)


func update_vine_lasher(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = game._cell_center(row, col).x
	var range_limit = float(Defs.PLANTS["vine_lasher"]["range"])
	var target_index = game._find_lane_target(row, center_x, range_limit)
	var hit := false
	if target_index == -1:
		if not game._damage_obstacles_in_radius(row, center_x + range_limit * 0.5, range_limit * 0.5, float(Defs.PLANTS["vine_lasher"]["damage"])):
			plant["attack_timer"] = 0.2
			return
		hit = true
	else:
		var zombie = game.zombies[target_index]
		zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["vine_lasher"]["damage"]), 0.16, float(Defs.PLANTS["vine_lasher"]["slow_duration"]))
		game.zombies[target_index] = zombie
		hit = true
	if hit:
		game.effects.append({
			"shape": "lane_spray",
			"position": game._cell_center(row, col) + Vector2(18.0, -6.0),
			"length": range_limit,
			"width": 54.0,
			"radius": range_limit * 0.5,
			"time": 0.2,
			"duration": 0.2,
			"color": Color(0.42, 0.94, 0.34, 0.24),
		})
	plant["flash"] = maxf(float(plant["flash"]), 0.12)
	plant["attack_timer"] = float(Defs.PLANTS["vine_lasher"]["attack_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_pepper_mortar(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target_index = game._find_frontmost_zombie(row)
	var impact_x := 0.0
	if target_index == -1:
		impact_x = game._find_frontmost_obstacle_x(row)
		if impact_x < -1000.0:
			plant["attack_timer"] = 0.25
			return
	else:
		var zombie = game.zombies[target_index]
		impact_x = float(zombie["x"])
	var impact = Vector2(impact_x, game._row_center_y(row))
	game._damage_zombies_in_radius(row, impact.x, float(Defs.PLANTS["pepper_mortar"]["splash_radius"]), float(Defs.PLANTS["pepper_mortar"]["damage"]))
	game._damage_obstacles_in_radius(row, impact.x, float(Defs.PLANTS["pepper_mortar"]["splash_radius"]), float(Defs.PLANTS["pepper_mortar"]["damage"]))
	game.effects.append({
		"position": impact,
		"radius": float(Defs.PLANTS["pepper_mortar"]["splash_radius"]),
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.42, 0.12, 0.56),
	})
	plant["flash"] = maxf(float(plant["flash"]), 0.16)
	plant["attack_timer"] = float(Defs.PLANTS["pepper_mortar"]["attack_interval"])
	game._trigger_plant_action(plant, 0.28)


func update_pulse_bulb(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["pulse_timer"] -= cadence_delta
	if float(plant["pulse_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var radius = float(Defs.PLANTS["pulse_bulb"].get("radius", 175.0))
	var did_hit = false
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) > radius:
			continue
		zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["pulse_bulb"]["damage"]), 0.12)
		game.zombies[i] = zombie
		did_hit = true
	if game._damage_obstacles_in_circle(center, radius, float(Defs.PLANTS["pulse_bulb"]["damage"])):
		did_hit = true
	if did_hit:
		game.effects.append({
			"position": center,
			"radius": radius,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.98, 0.94, 0.36, 0.34),
		})
		game._trigger_plant_action(plant, 0.26)
	plant["flash"] = maxf(float(plant["flash"]), 0.14)
	plant["pulse_timer"] = float(Defs.PLANTS["pulse_bulb"]["pulse_interval"])


func update_sun_bean(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) <= 0.0:
		var center = game._cell_center(row, col)
		game._spawn_sun(center + Vector2(game.rng.randf_range(-8.0, 8.0), -18.0), center.y - 10.0, "plant")
		plant["sun_timer"] = float(Defs.PLANTS["sun_bean"]["sun_interval"])
		game._trigger_plant_action(plant, 0.32)
	update_basic_shooter(plant, delta, row, col, Color(0.94, 0.78, 0.22), 0.0)


func update_sun_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if not bool(plant["mature"]):
		plant["grow_timer"] = maxf(0.0, float(plant["grow_timer"]) - delta)
		if float(plant["grow_timer"]) <= 0.0:
			plant["mature"] = true
			plant["flash"] = maxf(float(plant["flash"]), 0.2)
			game._trigger_plant_action(plant, 0.36)

	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) > 0.0:
		return

	var center = game._cell_center(row, col)
	var sun_value = game.SUN_VALUE if bool(plant["mature"]) else int(game.SUN_VALUE * 0.5)
	game._spawn_sun(center + Vector2(game.rng.randf_range(-8.0, 8.0), -18.0), center.y - 10.0, "plant", sun_value)
	plant["sun_timer"] = float(Defs.PLANTS["sun_shroom"]["sun_interval"])
	game._trigger_plant_action(plant, 0.34)


func update_fume_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	if String(plant.get("plant_food_mode", "")) == "fume_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		var burst_center = game._cell_center(row, col)
		var burst_range = float(Defs.PLANTS["fume_shroom"]["range"]) + 80.0
		var burst_damage = 72.0
		while float(plant["plant_food_interval"]) <= 0.0:
			var burst_hit := false
			for i in range(game.zombies.size()):
				var zombie = game.zombies[i]
				if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not game._is_enemy_zombie(zombie):
					continue
				var distance = float(zombie["x"]) - burst_center.x
				if distance < -20.0 or distance > burst_range:
					continue
				zombie = game._apply_zombie_damage(zombie, burst_damage, 0.16, 0.0, true)
				game.zombies[i] = zombie
				burst_hit = true
			if game._damage_obstacles_in_radius(row, burst_center.x + burst_range * 0.5, burst_range * 0.5, burst_damage):
				burst_hit = true
			game.effects.append({
				"shape": "lane_spray",
				"position": burst_center + Vector2(28.0, -8.0),
				"length": burst_range,
				"width": float(Defs.PLANTS["fume_shroom"].get("width", 92.0)) * 1.45,
				"radius": burst_range * 0.58,
				"time": 0.22,
				"duration": 0.22,
				"color": Color(0.92, 0.72, 1.0, 0.34 if burst_hit else 0.22),
			})
			plant["plant_food_interval"] += 0.12
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.18)
		return

	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return

	var center = game._cell_center(row, col)
	var range_limit = float(Defs.PLANTS["fume_shroom"]["range"])
	var damage = float(Defs.PLANTS["fume_shroom"]["damage"])
	var hit := false
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not game._is_enemy_zombie(zombie):
			continue
		var distance = float(zombie["x"]) - center.x
		if distance < -20.0 or distance > range_limit:
			continue
		zombie = game._apply_zombie_damage(zombie, damage, 0.14, 0.0, true)
		game.zombies[i] = zombie
		hit = true
	if game._damage_obstacles_in_radius(row, center.x + range_limit * 0.5, range_limit * 0.5, damage):
		hit = true

	if hit:
		game.effects.append({
			"shape": "lane_spray",
			"position": center + Vector2(24.0, -8.0),
			"length": range_limit,
			"width": float(Defs.PLANTS["fume_shroom"].get("width", 92.0)) * 1.15,
			"radius": range_limit * 0.55,
			"time": 0.18,
			"duration": 0.18,
			"color": Color(0.88, 0.64, 0.98, 0.24),
		})
		plant["flash"] = maxf(float(plant["flash"]), 0.14)
		plant["attack_timer"] = float(Defs.PLANTS["fume_shroom"]["shoot_interval"])
		game._trigger_plant_action(plant, 0.24)
	else:
		plant["attack_timer"] = 0.24


func update_scaredy_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if update_shooter_plant_food(plant, delta, row, col, Color(0.74, 0.52, 0.98), 0.0, 3, 0.06):
		return
	var center = game._cell_center(row, col)
	if game._has_close_zombie(center, float(Defs.PLANTS["scaredy_shroom"]["fear_radius"])):
		plant["shot_cooldown"] = minf(float(plant["shot_cooldown"]), 0.35)
		return
	update_basic_shooter(plant, delta, row, col, Color(0.72, 0.52, 0.98), 0.0)


func update_grave_buster(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	plant["chew_timer"] -= delta
	var grave_index = game._grave_index_at(int(plant["grave_row"]), int(plant["grave_col"]))
	if float(plant["chew_timer"]) > 0.0 and grave_index != -1:
		return false
	if grave_index != -1:
		game.graves.remove_at(grave_index)
		if not game.grave_wave_triggered:
			game.pending_grave_wave_spawns = max(0, game.pending_grave_wave_spawns - 1)
			game.expected_spawn_units = max(game.total_spawned_units + game.zombies.size() + game.batch_spawn_queue.size() + 1, game._estimated_total_spawn_count())
		game.effects.append({
			"position": game._cell_center(row, col) + Vector2(0.0, 16.0),
			"radius": 56.0,
			"time": 0.26,
			"duration": 0.26,
			"color": Color(0.34, 0.92, 0.28, 0.28),
		})
		game._trigger_plant_action(plant, 0.36)
	return true


func update_moon_lotus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) <= 0.0:
		var center = game._cell_center(row, col)
		game._spawn_sun(center + Vector2(game.rng.randf_range(-10.0, 10.0), -22.0), center.y - 12.0, "plant")
		plant["sun_timer"] = float(Defs.PLANTS["moon_lotus"]["sun_interval"])
		game._trigger_plant_action(plant, 0.34)
	if float(plant["support_timer"]) <= 0.0:
		var woke = game._wake_plants_in_radius(game._cell_center(row, col), float(Defs.PLANTS["moon_lotus"]["wake_radius"]))
		if woke > 0:
			game.effects.append({
				"position": game._cell_center(row, col),
				"radius": float(Defs.PLANTS["moon_lotus"]["wake_radius"]),
				"time": 0.24,
				"duration": 0.24,
				"color": Color(0.72, 0.88, 1.0, 0.22),
			})
			game._trigger_plant_action(plant, 0.26)
		plant["support_timer"] = float(Defs.PLANTS["moon_lotus"]["wake_interval"])


func update_prism_grass(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = game._cell_center(row, col).x
	var range_limit = float(Defs.PLANTS["prism_grass"]["range"])
	var slow_duration = float(Defs.PLANTS["prism_grass"].get("slow_duration", 0.0))
	var targets = game._find_lane_targets(row, center_x, range_limit, int(Defs.PLANTS["prism_grass"]["pierce_count"]))
	if targets.is_empty():
		plant["attack_timer"] = 0.2
		return
	for zombie_index in targets:
		var zombie = game.zombies[zombie_index]
		zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["prism_grass"]["damage"]), 0.14, slow_duration, true)
		game.zombies[zombie_index] = zombie
	game._damage_obstacles_in_radius(row, center_x + range_limit * 0.5, range_limit * 0.5, float(Defs.PLANTS["prism_grass"]["damage"]))
	game.effects.append({
		"shape": "lane_spray",
		"position": game._cell_center(row, col) + Vector2(18.0, -4.0),
		"length": range_limit,
		"width": 42.0,
		"radius": range_limit * 0.5,
		"time": 0.18,
		"duration": 0.18,
		"color": Color(0.68, 0.9, 1.0, 0.28),
	})
	plant["attack_timer"] = float(Defs.PLANTS["prism_grass"]["attack_interval"])
	game._trigger_plant_action(plant, 0.24)


func update_lantern_bloom(plant: Dictionary, _delta: float, row: int, col: int) -> void:
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var radius = float(Defs.PLANTS["lantern_bloom"]["radius"])
	var wake_radius = float(Defs.PLANTS["lantern_bloom"]["wake_radius"])
	var did_hit = game._damage_zombies_in_circle(center, radius, float(Defs.PLANTS["lantern_bloom"]["damage"]))
	var woke = game._wake_plants_in_radius(center, wake_radius)
	if did_hit or woke > 0:
		game.effects.append({
			"position": center,
			"radius": wake_radius,
			"time": 0.28,
			"duration": 0.28,
			"color": Color(1.0, 0.82, 0.34, 0.22),
		})
		game._trigger_plant_action(plant, 0.26)
	plant["support_timer"] = float(Defs.PLANTS["lantern_bloom"]["pulse_interval"])


func update_meteor_gourd(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target = game._find_global_frontmost_target()
	if target["row"] == -1:
		plant["attack_timer"] = 0.24
		return
	var impact = Vector2(float(target["x"]), game._row_center_y(int(target["row"])))
	game._damage_zombies_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]), float(Defs.PLANTS["meteor_gourd"]["damage"]))
	game._damage_obstacles_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]), float(Defs.PLANTS["meteor_gourd"]["damage"]))
	game.effects.append({
		"position": impact,
		"radius": float(Defs.PLANTS["meteor_gourd"]["splash_radius"]),
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.54, 0.22, 0.38),
	})
	plant["attack_timer"] = float(Defs.PLANTS["meteor_gourd"]["attack_interval"])
	game._trigger_plant_action(plant, 0.28)


func update_root_snare(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = game._cell_center(row, col).x
	var target_index = game._find_lane_target(row, center_x, float(Defs.PLANTS["root_snare"]["range"]))
	if target_index == -1:
		plant["attack_timer"] = 0.22
		return
	var zombie = game.zombies[target_index]
	zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["root_snare"]["damage"]), 0.14)
	zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer", 0.0)), float(Defs.PLANTS["root_snare"]["root_duration"]))
	game.zombies[target_index] = zombie
	game.effects.append({
		"position": Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) + 12.0),
		"radius": 42.0,
		"time": 0.22,
		"duration": 0.22,
		"color": Color(0.42, 0.84, 0.28, 0.26),
	})
	plant["attack_timer"] = float(Defs.PLANTS["root_snare"]["attack_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_thunder_pine(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = game._cell_center(row, col).x
	var target_index = game._find_lane_target(row, center_x, game.board_size.x)
	if target_index == -1:
		plant["attack_timer"] = 0.22
		return
	var chained = game._strike_thunder_chain(target_index, float(Defs.PLANTS["thunder_pine"]["damage"]), float(Defs.PLANTS["thunder_pine"]["chain_damage"]), float(Defs.PLANTS["thunder_pine"]["chain_range"]), 3)
	if chained > 0:
		game._trigger_plant_action(plant, 0.28)
	plant["attack_timer"] = float(Defs.PLANTS["thunder_pine"]["attack_interval"])


func update_dream_drum(plant: Dictionary, _delta: float, row: int, col: int) -> void:
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var woke = game._wake_plants_in_radius(center, float(Defs.PLANTS["dream_drum"]["wake_radius"]))
	var did_hit = game._damage_zombies_in_circle(center, float(Defs.PLANTS["dream_drum"]["radius"]), float(Defs.PLANTS["dream_drum"]["damage"]))
	if woke > 0 or did_hit:
		game.effects.append({
			"position": center,
			"radius": float(Defs.PLANTS["dream_drum"]["wake_radius"]),
			"time": 0.3,
			"duration": 0.3,
			"color": Color(0.9, 0.78, 0.38, 0.22),
		})
		game._trigger_plant_action(plant, 0.32)
	plant["support_timer"] = float(Defs.PLANTS["dream_drum"]["pulse_interval"])


func update_wind_orchid(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["gust_timer"] -= cadence_delta
	if float(plant["gust_timer"]) > 0.0:
		return
	var did_push = false
	var center = game._cell_center(row, col)
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if int(zombie["row"]) != row:
			continue
		zombie["x"] += float(Defs.PLANTS["wind_orchid"]["push_distance"])
		zombie["flash"] = 0.1
		game.zombies[i] = zombie
		did_push = true
	for i in range(game.weeds.size() - 1, -1, -1):
		if int(game.weeds[i]["row"]) == row:
			game.weeds.remove_at(i)
			did_push = true
	for i in range(game.spears.size() - 1, -1, -1):
		if int(game.spears[i]["row"]) == row:
			game.spears.remove_at(i)
			did_push = true
	if did_push:
		game.effects.append({
			"shape": "lane_spray",
			"position": center + Vector2(14.0, -6.0),
			"length": game.BOARD_ORIGIN.x + game.board_size.x - center.x,
			"width": game.CELL_SIZE.y * 0.76,
			"radius": game.BOARD_ORIGIN.x + game.board_size.x - center.x,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.72, 0.94, 1.0, 0.36),
		})
		game._trigger_plant_action(plant, 0.28)
	plant["flash"] = maxf(float(plant["flash"]), 0.14)
	plant["gust_timer"] = float(Defs.PLANTS["wind_orchid"]["gust_interval"])
