extends RefCounted
class_name PlantRuntime

const Defs = preload("res://scripts/game_defs.gd")
const MAGIC_FLOWER_PROJECTILES := [
	"pea",
	"amber_pea",
	"boomerang",
	"sakura_petal",
	"mist_bloom",
	"glow_seed",
	"heather_thorn",
	"origami_plane",
]

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
			if plant.has("holy_invincible_timer"):
				plant["holy_invincible_timer"] = maxf(0.0, float(plant["holy_invincible_timer"]) - delta)
			if plant.has("aurora_buff_timer"):
				plant["aurora_buff_timer"] = maxf(0.0, float(plant["aurora_buff_timer"]) - delta)
			if plant.has("destiny_dmg_timer"):
				plant["destiny_dmg_timer"] = maxf(0.0, float(plant["destiny_dmg_timer"]) - delta)
			if plant.has("destiny_speed_timer"):
				plant["destiny_speed_timer"] = maxf(0.0, float(plant["destiny_speed_timer"]) - delta)
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
					update_amber_shooter(plant, delta, row, col)
				"snow_pea":
					if update_shooter_plant_food(plant, delta, row, col, Color(0.54, 0.88, 1.0), 16.0, 1, 0.1):
						game.grid[row][col] = plant
						continue
					update_basic_shooter(plant, delta, row, col, Color(0.54, 0.88, 1.0), float(Defs.PLANTS["snow_pea"]["slow_duration"]))
				"repeater":
					update_repeater(plant, delta, row, col)
				"threepeater":
					update_threepeater(plant, delta, row, col)
				"heather_shooter":
					update_heather_shooter(plant, delta, row, col)
				"leyline":
					update_leyline(plant, delta, row, col)
				"holo_nut":
					update_holo_nut(plant, delta, row, col)
				"healing_gourd":
					update_healing_gourd(plant, delta, row, col)
				"mango_bowling":
					update_mango_bowling(plant, delta, row, col)
				"snow_bloom":
					if update_snow_bloom(plant, delta, row, col):
						game.grid[row][col] = null
						continue
				"cluster_boomerang":
					update_cluster_boomerang(plant, delta, row, col)
				"glitch_walnut":
					if update_glitch_walnut(plant, delta, row, col):
						game.grid[row][col] = null
						continue
				"nether_shroom":
					update_nether_shroom(plant, delta, row, col)
				"seraph_flower":
					update_seraph_flower(plant, delta, row, col)
				"magma_stream":
					if update_magma_stream(plant, delta, row, col):
						game.grid[row][col] = null
						continue
				"orange_bloom":
					update_orange_bloom(plant, delta, row, col)
				"hive_flower":
					update_hive_flower(plant, delta, row, col)
				"mamba_tree":
					update_mamba_tree(plant, delta, row, col)
				"chambord_sniper":
					update_chambord_sniper(plant, delta, row, col)
				"dream_disc":
					if update_dream_disc(plant, delta, row, col):
						game.grid[row][col] = null
						continue
				"shadow_pea":
					update_shadow_pea(plant, delta, row, col)
				"ice_queen":
					update_ice_queen(plant, delta, row, col)
				"vine_emperor":
					update_vine_emperor(plant, delta, row, col)
				"soul_flower":
					update_soul_flower(plant, delta, row, col)
				"plasma_shooter":
					update_plasma_shooter(plant, delta, row, col)
				"crystal_nut":
					update_crystal_nut(plant, delta, row, col)
				"dragon_fruit":
					update_dragon_fruit(plant, delta, row, col)
				"time_rose":
					update_time_rose(plant, delta, row, col)
				"galaxy_sunflower":
					update_galaxy_sunflower(plant, delta, row, col)
				"void_shroom":
					update_void_shroom(plant, delta, row, col)
				"phoenix_tree":
					update_phoenix_tree(plant, delta, row, col)
				"thunder_god":
					update_thunder_god(plant, delta, row, col)
				"prism_pea":
					update_prism_pea(plant, delta, row, col)
				"magnet_daisy":
					update_magnet_daisy(plant, delta, row, col)
				"thorn_cactus":
					update_thorn_cactus(plant, delta, row, col)
				"bubble_lotus":
					update_bubble_lotus(plant, delta, row, col)
				"spiral_bamboo":
					update_spiral_bamboo(plant, delta, row, col)
				"honey_blossom":
					update_honey_blossom(plant, delta, row, col)
				"echo_fern":
					update_echo_fern(plant, delta, row, col)
				"glow_ivy":
					update_glow_ivy(plant, delta, row, col)
				"laser_lily":
					update_laser_lily(plant, delta, row, col)
				"rock_armor_fruit":
					update_rock_armor_fruit(plant, delta, row, col)
				"aurora_orchid":
					update_aurora_orchid(plant, delta, row, col)
				"blast_pomegranate":
					update_blast_pomegranate(plant, delta, row, col)
				"frost_cypress":
					update_frost_cypress(plant, delta, row, col)
				"mirror_shroom":
					update_mirror_shroom(plant, delta, row, col)
				"chain_lotus":
					update_chain_lotus(plant, delta, row, col)
				"plasma_shroom":
					update_plasma_shroom(plant, delta, row, col)
				"meteor_flower":
					update_meteor_flower(plant, delta, row, col)
				"destiny_tree":
					update_destiny_tree(plant, delta, row, col)
				"abyss_tentacle":
					update_abyss_tentacle(plant, delta, row, col)
				"solar_emperor":
					update_solar_emperor(plant, delta, row, col)
				"shadow_assassin":
					update_shadow_assassin(plant, delta, row, col)
				"core_blossom":
					update_core_blossom(plant, delta, row, col)
				"holy_lotus":
					update_holy_lotus(plant, delta, row, col)
				"chaos_shroom":
					update_chaos_shroom(plant, delta, row, col)
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


func find_magic_flower_target(row: int, plant_x: float, range_limit: float) -> int:
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
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, position, "starfruit"))
	game.projectiles.append({
		"kind": "star",
		"row": row,
		"position": position,
		"speed": speed,
		"velocity_y": velocity_y,
		"damage": float(Defs.PLANTS["starfruit"]["damage"]) * damage_mult,
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


func update_amber_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "amber_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			if not game._has_zombie_ahead(row, center.x, game.board_size.x + game.CELL_SIZE.x):
				plant["plant_food_interval"] += 0.12
				break
			for shot_index in range(3):
				var y_offset = lerpf(-10.0, 10.0, float(shot_index) / 2.0)
				var spawn_position = center + Vector2(30.0 + float(shot_index) * 3.0, -10.0 + y_offset * 0.24)
				game._spawn_amber_ultimate_projectile(row, spawn_position, maxf(float(Defs.PLANTS["amber_shooter"]["damage"]) * 1.3, 40.0), 600.0 + float(shot_index) * 16.0, 10.5)
			var target_index = game._find_lane_target(row, center.x, game.board_size.x + game.CELL_SIZE.x)
			var burst_position = center + Vector2(game.board_size.x * 0.42, -8.0)
			if target_index != -1:
				var target = game.zombies[target_index]
				burst_position = Vector2(float(target["x"]), game._row_center_y(int(target["row"])) - 8.0)
			game.effects.append({
				"shape": "amber_prism_burst",
				"position": burst_position,
				"radius": 52.0,
				"time": 0.22,
				"duration": 0.22,
				"color": Color(1.0, 0.76, 0.3, 0.26),
				"anim_speed": 6.4,
			})
			plant["plant_food_interval"] += 0.12
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return

	var center_x = center.x
	if not game._has_zombie_ahead(row, center_x, game.board_size.x):
		return

	game._spawn_amber_projectile(row, center + Vector2(32.0, -10.0), float(Defs.PLANTS["amber_shooter"]["damage"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["amber_shooter"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.2)


func spawn_roof_lobbed_projectile(kind: String, row: int, spawn_position: Vector2, target: Vector2, damage: float, color: Color, arc_height: float, radius: float = 10.0, splash_radius: float = 0.0, butter_duration: float = 0.0, source_plant_kind: String = "") -> void:
	var travel_duration = maxf(spawn_position.distance_to(target) / 380.0, 0.42)
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, source_plant_kind))
	game.projectiles.append({
		"kind": kind,
		"row": row,
		"position": spawn_position,
		"speed": maxf((target.x - spawn_position.x) / travel_duration, 0.0),
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
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


func _spawn_magic_flower_projectile(row: int, center: Vector2, damage_mult: float = 1.0, projectile_kind: String = "", spawn_offset: Vector2 = Vector2.ZERO) -> String:
	var chosen_kind = projectile_kind
	if chosen_kind == "":
		chosen_kind = String(MAGIC_FLOWER_PROJECTILES[game.rng.randi_range(0, MAGIC_FLOWER_PROJECTILES.size() - 1)])
	var spawn_position = center + spawn_offset + Vector2(30.0 + game.rng.randf_range(-2.0, 4.0), -16.0 + game.rng.randf_range(-7.0, 7.0))
	var base_damage = maxf(float(Defs.PLANTS["origami_blossom"]["damage"]) * damage_mult, 12.0)
	match chosen_kind:
		"amber_pea":
			game._spawn_amber_projectile(row, spawn_position, base_damage * 0.96, 500.0, 8.4)
		"boomerang":
			spawn_boomerang_projectile(row, spawn_position, center.x, base_damage * 1.04, 3)
		"sakura_petal":
			spawn_sakura_projectile(row, spawn_position, base_damage * 0.94, game.rng.randf_range(-64.0, 64.0))
		"mist_bloom":
			spawn_mist_projectile(row, spawn_position, base_damage * 0.88, 0.85, 54.0, 1.6)
		"glow_seed":
			spawn_glowvine_projectile(row, spawn_position, base_damage)
		"heather_thorn":
			spawn_heather_projectile(row, spawn_position, base_damage * 0.92, 6.0 * damage_mult, 2.6, 0.18, game.rng.randf_range(-36.0, 36.0))
		"origami_plane":
			game._spawn_projectile(row, spawn_position, Color(0.96, 0.9, 0.74), base_damage, 0.0, 500.0, 7.0)
			if not game.projectiles.is_empty():
				game.projectiles[game.projectiles.size() - 1]["kind"] = "origami_plane"
		_:
			game._spawn_projectile(row, spawn_position, Color(0.96, 0.88, 0.72), base_damage, 0.0, 490.0, 7.6)
	if not game.projectiles.is_empty():
		game.projectiles[game.projectiles.size() - 1]["anti_air"] = true
	return chosen_kind


func _next_magic_flower_projectile_kind(plant: Dictionary) -> String:
	if not plant.has("magic_cycle_seed"):
		plant["magic_cycle_seed"] = game.rng.randi_range(0, MAGIC_FLOWER_PROJECTILES.size() - 1)
	var cycle_seed = int(plant.get("magic_cycle_seed", 0))
	var cycle_index = int(plant.get("magic_cycle_index", -1)) + 1
	plant["magic_cycle_index"] = cycle_index
	return String(MAGIC_FLOWER_PROJECTILES[(cycle_seed + cycle_index) % MAGIC_FLOWER_PROJECTILES.size()])


func update_origami_blossom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "origami_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			if find_magic_flower_target(row, center.x, float(Defs.PLANTS["origami_blossom"]["range"])) != -1:
				for _cast in range(3):
					_spawn_magic_flower_projectile(row, center, 1.12, _next_magic_flower_projectile_kind(plant))
				game.effects.append({
					"shape": "magic_lane_barrage",
					"position": center + Vector2(16.0, -8.0),
					"length": game.BOARD_ORIGIN.x + game.board_size.x - center.x,
					"width": game.CELL_SIZE.y * 0.8,
					"radius": game.BOARD_ORIGIN.x + game.board_size.x - center.x,
					"time": 0.24,
					"duration": 0.24,
					"color": Color(0.98, 0.86, 0.64, 0.28),
					"anim_speed": 7.2,
				})
			plant["plant_food_interval"] += 0.11
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			game._trigger_plant_action(plant, 0.14)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var target_index = find_magic_flower_target(row, center.x, float(Defs.PLANTS["origami_blossom"]["range"]))
	if target_index == -1:
		return
	_spawn_magic_flower_projectile(row, center, 1.0, _next_magic_flower_projectile_kind(plant))
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
					game._strike_tesla_chain(center + Vector2(12.0, -24.0), storm_index, float(Defs.PLANTS["tesla_tulip"]["damage"]) * 1.15, float(Defs.PLANTS["tesla_tulip"]["chain_damage"]) * 1.2, float(Defs.PLANTS["tesla_tulip"]["chain_range"]) + 24.0, 5)
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
	var chained = game._strike_tesla_chain(center + Vector2(12.0, -24.0), target_index, float(Defs.PLANTS["tesla_tulip"]["damage"]), float(Defs.PLANTS["tesla_tulip"]["chain_damage"]), float(Defs.PLANTS["tesla_tulip"]["chain_range"]), 3)
	if chained > 0:
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
	var gust_damage = float(Defs.PLANTS["roof_vane"].get("damage", 14.0))
	var gust_radius = float(Defs.PLANTS["roof_vane"].get("gust_radius", 92.0))
	var gust_center = center + Vector2(gust_radius * 0.5, -6.0)
	if String(plant.get("plant_food_mode", "")) == "roof_gale" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		push_distance *= 1.65
		gust_damage *= 1.7
		gust_radius += 26.0
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
			var zombie_pos = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 10.0)
			var lane_gust_center = Vector2(gust_center.x, game._row_center_y(lane) - 6.0)
			var local = zombie_pos - lane_gust_center
			if local.x < -gust_radius * 0.58 or local.x > gust_radius * 1.06:
				continue
			if absf(local.y) > gust_radius * 0.82:
				continue
			zombie = game._apply_zombie_damage(zombie, gust_damage, 0.12, 0.4)
			zombie["x"] += push_distance
			zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.1)
			game.zombies[i] = zombie
			did_push = true
	if did_push:
		game.effects.append({
			"shape": "roof_vane_ring",
			"position": gust_center,
			"radius": gust_radius,
			"width": game.CELL_SIZE.y * 0.78 * float(max(affected_rows.size(), 1)),
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.84, 0.98, 1.0, 0.32),
			"anim_speed": 7.6,
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


func spawn_heather_projectile(row: int, spawn_position: Vector2, damage: float, dot_damage: float, dot_duration: float, stun_duration: float, velocity_y: float = 0.0) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "heather_shooter"))
	game.projectiles.append({
		"kind": "heather_thorn",
		"row": row,
		"position": spawn_position,
		"speed": 390.0,
		"velocity_y": velocity_y,
		"damage": damage * damage_mult,
		"slow_duration": 0.0,
		"color": Color(0.92, 0.38, 0.62),
		"radius": 8.0,
		"reflected": false,
		"fire": false,
		"free_aim": absf(velocity_y) > 0.01,
		"dot_damage": dot_damage * damage_mult,
		"dot_duration": dot_duration,
		"stun_duration": stun_duration,
	})


func _apply_leyline_pulse(row: int, center: Vector2, damage: float, stun_duration: float, width: float, color: Color) -> bool:
	var hit = game._damage_zombies_in_row_segment(row, game.BOARD_ORIGIN.x - 24.0, game.BOARD_ORIGIN.x + game.board_size.x + 24.0, damage)
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if int(zombie["row"]) != row or not game._is_enemy_zombie(zombie):
			continue
		zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), stun_duration)
		game.zombies[i] = zombie
	game.effects.append({
		"shape": "lane_spray",
		"position": Vector2(game.BOARD_ORIGIN.x, game._row_center_y(row) + 18.0),
		"length": game.board_size.x,
		"width": width,
		"radius": game.board_size.x,
		"time": 0.2,
		"duration": 0.2,
		"color": color,
	})
	return hit


func _heal_targetable_plant(row: int, col: int, amount: float, flash: float = 0.08) -> bool:
	var plant = game._targetable_plant_at(row, col)
	if plant == null:
		return false
	var healed := false
	if float(plant.get("health", 0.0)) < float(plant.get("max_health", 0.0)):
		plant["health"] = minf(float(plant["max_health"]), float(plant["health"]) + amount)
		healed = true
	if float(plant.get("max_armor_health", 0.0)) > 0.0 and float(plant.get("armor_health", 0.0)) < float(plant.get("max_armor_health", 0.0)):
		plant["armor_health"] = minf(float(plant["max_armor_health"]), float(plant["armor_health"]) + amount * 0.45)
		healed = true
	if healed:
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), flash)
		game._set_targetable_plant(row, col, plant)
	return healed


func update_heather_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	var data = Defs.PLANTS["heather_shooter"]
	if String(plant.get("plant_food_mode", "")) == "heather_bloom" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for velocity_y in [-110.0, 0.0, 110.0]:
				spawn_heather_projectile(
					row,
					center + Vector2(32.0, -10.0 + velocity_y * 0.02),
					float(data["ultimate_damage"]),
					float(data["dot_damage"]) * 1.4,
					float(data["dot_duration"]) + 1.4,
					float(data["stun_duration"]) + 0.12,
					velocity_y
				)
			plant["plant_food_interval"] += 0.18
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not game._has_zombie_ahead(row, center.x - game.CELL_SIZE.x * 0.5, game.board_size.x + game.CELL_SIZE.x):
		return
	spawn_heather_projectile(
		row,
		center + Vector2(32.0, -10.0),
		float(data["damage"]),
		float(data["dot_damage"]),
		float(data["dot_duration"]),
		float(data["stun_duration"])
	)
	plant["shot_cooldown"] = float(data["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_leyline(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	var data = Defs.PLANTS["leyline"]
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	if String(plant.get("plant_food_mode", "")) == "leyline_quake" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		var any_hit := false
		for lane in [row - 1, row, row + 1]:
			if lane < 0 or lane >= game.ROWS or not game._is_row_active(lane):
				continue
			any_hit = _apply_leyline_pulse(
				int(lane),
				game._cell_center(int(lane), col),
				float(data["ultimate_damage"]),
				float(data["stun_duration"]) + 0.12,
				float(data["wave_width"]) + 14.0,
				Color(0.46, 0.86, 1.0, 0.28)
			) or any_hit
		if any_hit:
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			game._trigger_plant_action(plant, 0.2)
		plant["attack_timer"] = 0.24
		return
	if not game._has_zombie_ahead(row, center.x - game.CELL_SIZE.x * 0.5, game.board_size.x + game.CELL_SIZE.x):
		return
	if _apply_leyline_pulse(row, center, float(data["lane_damage"]), float(data["stun_duration"]), float(data["wave_width"]), Color(0.24, 0.86, 0.98, 0.24)):
		plant["flash"] = maxf(float(plant["flash"]), 0.14)
		game._trigger_plant_action(plant, 0.18)
	plant["attack_timer"] = float(data["attack_interval"])


func update_holo_nut(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if float(plant["support_timer"]) > 0.0:
		return
	var heal_amount = float(Defs.PLANTS["holo_nut"]["heal_per_tick"])
	var healed := false
	if float(plant["health"]) < float(plant["max_health"]):
		plant["health"] = minf(float(plant["max_health"]), float(plant["health"]) + heal_amount)
		healed = true
	if float(plant.get("armor_health", 0.0)) > 0.0 and float(plant.get("max_armor_health", 0.0)) > 0.0:
		plant["armor_health"] = minf(float(plant["max_armor_health"]), float(plant["armor_health"]) + heal_amount * 0.65)
		healed = true
	if healed:
		plant["flash"] = maxf(float(plant["flash"]), 0.12)
		game._trigger_plant_action(plant, 0.16)
	plant["support_timer"] = float(Defs.PLANTS["holo_nut"]["regen_interval"])


func update_healing_gourd(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if float(plant["support_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["healing_gourd"]
	var heal_amount = float(data["heal_amount"])
	var heal_radius = float(data["heal_radius"])
	if String(plant.get("plant_food_mode", "")) == "gourd_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		heal_amount = float(data["ultimate_heal"])
		heal_radius += 48.0
		plant["support_timer"] = 0.28
	else:
		plant["support_timer"] = float(data["pulse_interval"])
	var center = game._cell_center(row, col)
	var healed := false
	for other_row in range(max(0, row - 1), min(game.ROWS, row + 2)):
		for other_col in range(max(0, col - 1), min(game.COLS, col + 2)):
			var cell_center = game._cell_center(other_row, other_col)
			if cell_center.distance_to(center) > heal_radius:
				continue
			healed = _heal_targetable_plant(other_row, other_col, heal_amount) or healed
	if healed:
		game.effects.append({
			"shape": "glow_burst",
			"position": center,
			"radius": heal_radius,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.62, 1.0, 0.74, 0.24),
		})
		plant["flash"] = maxf(float(plant["flash"]), 0.14)
		game._trigger_plant_action(plant, 0.18)


func update_mango_bowling(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	if String(plant.get("plant_food_mode", "")) == "mango_rush" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		game._ensure_projectile_runtime().spawn_mango_roller(row, col, true)
		plant["attack_timer"] = 0.3
		plant["flash"] = maxf(float(plant["flash"]), 0.18)
		game._trigger_plant_action(plant, 0.16)
		return
	if not game._has_zombie_ahead(row, center.x, game.board_size.x):
		return
	game._ensure_projectile_runtime().spawn_mango_roller(row, col, false)
	plant["attack_timer"] = float(Defs.PLANTS["mango_bowling"]["attack_interval"])
	game._trigger_plant_action(plant, 0.18)


func update_snow_bloom(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	var data = Defs.PLANTS["snow_bloom"]
	if not bool(plant.get("snowfield_created", false)):
		game._create_snowfield_tile(row, col, float(data["snow_duration"]))
		plant["snowfield_created"] = true
		plant["support_timer"] = 0.7
		plant["fuse_timer"] = float(data["wilt_time"])
		plant["flash"] = maxf(float(plant["flash"]), 0.14)
		game._trigger_plant_action(plant, 0.2)
	plant["fuse_timer"] = maxf(0.0, float(plant.get("fuse_timer", 0.0)) - delta)
	if float(plant["support_timer"]) <= 0.0:
		var center = game._cell_center(row, col)
		var radius = game.CELL_SIZE.x * 0.82
		var slow_time = float(data["slow_duration"])
		if String(plant.get("plant_food_mode", "")) == "whiteout" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
			radius *= 1.6
			slow_time += 2.5
		for zombie_index in game._find_closest_zombies_in_radius(center, radius, 6):
			var zombie = game.zombies[zombie_index]
			zombie = game._apply_zombie_damage(zombie, 20.0, 0.12, slow_time)
			game.zombies[zombie_index] = zombie
		game.effects.append({
			"shape": "mist_cloud",
			"position": center,
			"radius": radius,
			"time": 0.2,
			"duration": 0.2,
			"color": Color(0.86, 0.98, 1.0, 0.22),
		})
		plant["support_timer"] = 1.15
	if float(plant["fuse_timer"]) <= 0.0:
		return true
	return false


func _count_cluster_boomerangs(row: int, col: int) -> int:
	var count := 0
	for projectile in game.projectiles:
		if String(projectile.get("kind", "")) != "boomerang":
			continue
		if int(projectile.get("cluster_owner_row", -1)) != row or int(projectile.get("cluster_owner_col", -1)) != col:
			continue
		count += 1
	return count


func spawn_cluster_boomerang_projectile(owner_row: int, owner_col: int, row: int, spawn_position: Vector2, anchor_x: float, damage: float, max_targets: int) -> void:
	var damage_mult = float(game.call("_plant_enhance_multiplier_at_cell", owner_row, owner_col))
	game.projectiles.append({
		"kind": "boomerang",
		"row": row,
		"position": spawn_position,
		"speed": 380.0,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
		"slow_duration": 0.0,
		"color": Color(0.54, 0.98, 0.96),
		"radius": 10.0,
		"reflected": false,
		"fire": false,
		"outbound": true,
		"anchor_x": anchor_x,
		"max_hits": max_targets,
		"hit_uids": [],
		"return_hits": [],
		"return_markers": [],
		"cluster_owner_row": owner_row,
		"cluster_owner_col": owner_col,
	})


func update_cluster_boomerang(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	var data = Defs.PLANTS["cluster_boomerang"]
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var max_projectiles = int(data["max_projectiles"])
	var damage = float(data["damage"])
	var spawn_interval = float(data["shoot_interval"])
	if String(plant.get("plant_food_mode", "")) == "cluster_field" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		max_projectiles += 4
		damage = float(data["ultimate_damage"])
		spawn_interval = 0.36
	if _count_cluster_boomerangs(row, col) >= max_projectiles:
		plant["shot_cooldown"] = 0.16
		return
	var target_rows: Array = []
	for lane in range(max(0, row - 1), min(game.ROWS, row + 2)):
		if not game._is_row_active(lane):
			continue
		var lane_target = game._find_lane_target_ignore_fog(lane, center.x - game.CELL_SIZE.x * 1.1, game.CELL_SIZE.x * 2.4)
		if lane_target != -1:
			target_rows.append(lane)
	if target_rows.is_empty():
		return
	for lane_variant in target_rows:
		if _count_cluster_boomerangs(row, col) >= max_projectiles:
			break
		var lane = int(lane_variant)
		spawn_cluster_boomerang_projectile(row, col, lane, game._cell_center(lane, col) + Vector2(24.0, -12.0), center.x - 10.0, damage, int(data["max_targets"]))
	plant["shot_cooldown"] = spawn_interval
	plant["flash"] = maxf(float(plant["flash"]), 0.14)
	game._trigger_plant_action(plant, 0.16)


func _trigger_glitch_burst(plant: Dictionary, row: int, col: int, boosted: bool) -> void:
	var center = game._cell_center(row, col)
	var base_damage = float(Defs.PLANTS["glitch_walnut"].get("ultimate_damage", 220.0)) if boosted else 84.0
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		var effect_roll = game.rng.randi_range(0, 3)
		zombie = game._apply_zombie_damage(zombie, base_damage * (1.0 if effect_roll != 0 else 0.65), 0.16)
		match effect_roll:
			0:
				zombie["slow_timer"] = maxf(float(zombie.get("slow_timer", 0.0)), 7.0 if not boosted else 11.0)
			1:
				zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer", 0.0)), 1.8 if not boosted else 3.2)
			2:
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.55 if not boosted else 1.1)
			3:
				zombie["corrode_timer"] = maxf(float(zombie.get("corrode_timer", 0.0)), 4.0 if not boosted else 6.5)
				zombie["corrode_dps"] = maxf(float(zombie.get("corrode_dps", 0.0)), 8.0 if not boosted else 16.0)
		if game._is_mechanical_zombie_kind(String(zombie.get("kind", ""))):
			zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 1.6 if not boosted else 3.2)
			zombie["slow_timer"] = maxf(float(zombie.get("slow_timer", 0.0)), 6.0 if not boosted else 9.0)
		game.zombies[i] = zombie
	game.effects.append({
		"shape": "glow_burst",
		"position": center,
		"radius": float(Defs.PLANTS["glitch_walnut"].get("explosion_radius", 220.0)),
		"time": 0.34,
		"duration": 0.34,
		"color": Color(0.62, 0.92, 1.0, 0.3) if boosted else Color(0.68, 0.62, 1.0, 0.26),
	})


func update_glitch_walnut(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	plant["support_timer"] -= delta
	var boosted = String(plant.get("plant_food_mode", "")) == "glitch_burst"
	if float(plant["support_timer"]) > 0.0 and not boosted:
		return false
	if boosted and float(plant.get("plant_food_timer", 0.0)) > 0.06:
		return false
	_trigger_glitch_burst(plant, row, col, boosted)
	return true


func _count_hypnotized_bucketheads() -> int:
	var total := 0
	for zombie in game.zombies:
		if not bool(zombie.get("hypnotized", false)):
			continue
		if String(zombie.get("kind", "")) != "buckethead":
			continue
		if float(zombie.get("health", 0.0)) <= 0.0:
			continue
		total += 1
	return total


func _spawn_hypnotized_buckethead(row: int, col: int, empowered: bool) -> bool:
	if row < 0 or row >= game.ROWS or not game._is_row_active(row):
		return false
	var spawn_col = clampi(col, 0, game.COLS - 1)
	var spawn_x = game._cell_center(row, spawn_col).x + 22.0
	var before_count = game.zombies.size()
	game._spawn_zombie_at("buckethead", row, spawn_x, false)
	if game.zombies.size() <= before_count:
		return false
	var zombie_index = game.zombies.size() - 1
	var summon = game.zombies[zombie_index]
	if String(summon.get("kind", "")) != "buckethead":
		return false
	summon = game._hypnotize_zombie(summon)
	if empowered:
		var boosted_health = float(summon.get("max_health", 1100.0)) * 1.25
		summon["max_health"] = boosted_health
		summon["health"] = boosted_health
		summon["base_speed"] = maxf(float(summon.get("base_speed", 18.0)), 22.0)
	summon["special_pause_timer"] = maxf(float(summon.get("special_pause_timer", 0.0)), 0.42)
	summon["flash"] = maxf(float(summon.get("flash", 0.0)), 0.18)
	game.zombies[zombie_index] = summon
	game.effects.append({
		"position": Vector2(float(summon["x"]) - 18.0, game._row_center_y(row) - 12.0),
		"radius": 58.0,
		"time": 0.28,
		"duration": 0.28,
		"color": Color(0.84, 0.42, 0.98, 0.26),
	})
	return true


func update_nether_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var data = Defs.PLANTS["nether_shroom"]
	plant["support_timer"] -= cadence_delta
	if String(plant.get("plant_food_mode", "")) == "nether_rites" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		if float(plant["support_timer"]) > 0.0:
			return
		var summon_rows = threepeater_rows(row)
		var summoned := 0
		for lane_variant in summon_rows:
			if _count_hypnotized_bucketheads() >= int(data.get("summon_limit", 3)) + 3:
				break
			if _spawn_hypnotized_buckethead(int(lane_variant), col, true):
				summoned += 1
		if summoned > 0:
			plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.18)
			game._trigger_plant_action(plant, 0.22)
		plant["support_timer"] = 0.85
		return
	if float(plant["support_timer"]) > 0.0:
		return
	if _count_hypnotized_bucketheads() >= int(data.get("summon_limit", 3)):
		plant["support_timer"] = 2.0
		return
	var summon_rows = threepeater_rows(row)
	var summon_row = row if summon_rows.is_empty() else int(summon_rows[game.rng.randi_range(0, summon_rows.size() - 1)])
	if _spawn_hypnotized_buckethead(summon_row, col, false):
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.14)
		game._trigger_plant_action(plant, 0.18)
	plant["support_timer"] = float(data.get("summon_interval", 18.0))


func spawn_seraph_spear(row: int, spawn_position: Vector2, damage: float, pierce_hits: int) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "seraph_flower"))
	game.projectiles.append({
		"kind": "angel_spear",
		"row": row,
		"position": spawn_position,
		"speed": 560.0,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
		"slow_duration": 0.0,
		"color": Color(1.0, 0.88, 0.58),
		"radius": 9.0,
		"reflected": false,
		"fire": false,
		"free_aim": false,
		"anti_air": true,
		"pierce_left": pierce_hits,
		"hit_uids": [],
	})


func update_seraph_flower(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var center = game._cell_center(row, col)
	var data = Defs.PLANTS["seraph_flower"]
	var attack_rows = threepeater_rows(row)
	if String(plant.get("plant_food_mode", "")) == "seraph_choir" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			var fired := false
			for lane_variant in attack_rows:
				var lane = int(lane_variant)
				if not game._has_zombie_ahead(lane, center.x, float(data.get("range", 760.0))):
					continue
				for burst_index in range(2):
					spawn_seraph_spear(lane, game._cell_center(lane, col) + Vector2(30.0 - float(burst_index) * 8.0, -18.0 + float(burst_index) * 8.0), float(data.get("ultimate_damage", 88.0)), int(data.get("pierce_hits", 5)) + 2)
				fired = true
			if fired:
				plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.18)
				game.effects.append({
					"shape": "lane_spray",
					"position": center + Vector2(14.0, -16.0),
					"length": game.board_size.x * 0.74,
					"width": game.CELL_SIZE.y * 2.4,
					"radius": game.board_size.x,
					"time": 0.26,
					"duration": 0.26,
					"color": Color(1.0, 0.9, 0.64, 0.22),
				})
				game._trigger_plant_action(plant, 0.18)
			plant["plant_food_interval"] += 0.18
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var fired := false
	for lane_variant in attack_rows:
		var lane = int(lane_variant)
		if not game._has_zombie_ahead(lane, center.x, float(data.get("range", 760.0))):
			continue
		spawn_seraph_spear(lane, game._cell_center(lane, col) + Vector2(30.0, -14.0), float(data.get("damage", 62.0)), int(data.get("pierce_hits", 5)))
		fired = true
	if not fired:
		return
	plant["shot_cooldown"] = float(data.get("shoot_interval", 2.4))
	plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
	game._trigger_plant_action(plant, 0.2)


func update_magma_stream(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	var data = Defs.PLANTS["magma_stream"]
	var center = game._cell_center(row, col)
	if not bool(plant.get("magma_created", false)):
		game._spawn_magma_patch(row, col, float(data.get("magma_duration", 11.0)), float(data.get("magma_dps", 56.0)))
		game._damage_zombies_in_circle(center, game.CELL_SIZE.x * 0.42, float(data.get("damage", 48.0)))
		plant["magma_created"] = true
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
		game._trigger_plant_action(plant, 0.18)
	if String(plant.get("plant_food_mode", "")) == "magma_surge" and not bool(plant.get("burst_done", false)):
		for magma_row in range(max(0, row - 1), min(game.ROWS, row + 2)):
			if not game._is_row_active(magma_row):
				continue
			for magma_col in range(max(0, col - 1), min(game.COLS, col + 2)):
				game._spawn_magma_patch(magma_row, magma_col, float(data.get("magma_duration", 11.0)) + 4.0, float(data.get("magma_dps", 56.0)) * 1.35)
				var magma_center = game._cell_center(magma_row, magma_col)
				game._damage_zombies_in_circle(magma_center, game.CELL_SIZE.x * 0.42, float(data.get("ultimate_damage", 180.0)))
				game._apply_ash_hits_in_circle(magma_center, game.CELL_SIZE.x * 0.42, 1)
		game.effects.append({
			"position": center,
			"radius": 180.0,
			"time": 0.4,
			"duration": 0.4,
			"color": Color(1.0, 0.38, 0.12, 0.34),
		})
		plant["burst_done"] = true
	plant["fuse_timer"] = maxf(0.0, float(plant.get("fuse_timer", 0.0)) - delta)
	return float(plant.get("fuse_timer", 0.0)) <= 0.0


func _fire_orange_bloom(center: Vector2, row: int, damage: float, splash_radius: float, range_limit: float, target_count: int) -> bool:
	var targets = game._find_lane_targets(row, center.x, range_limit, target_count)
	if targets.is_empty():
		return false
	for target_index in targets:
		var zombie = game.zombies[int(target_index)]
		var impact = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 4.0)
		game._damage_zombies_in_circle(impact, splash_radius, damage)
		game._damage_obstacles_in_circle(impact, splash_radius * 0.76, damage * 0.65)
	game.effects.append({
		"shape": "lane_spray",
		"position": center + Vector2(18.0, 0.0),
		"length": game.board_size.x * 0.78,
		"width": 54.0,
		"radius": game.board_size.x,
		"time": 0.24,
		"duration": 0.24,
		"color": Color(1.0, 0.58, 0.22, 0.3),
	})
	return true


func update_orange_bloom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var data = Defs.PLANTS["orange_bloom"]
	var center = game._cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "orange_tide" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			if _fire_orange_bloom(center, row, float(data.get("ultimate_damage", 64.0)), float(data.get("splash_radius", 78.0)) + 18.0, float(data.get("range", 760.0)), 4):
				plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
				game._trigger_plant_action(plant, 0.16)
			plant["plant_food_interval"] += 0.2
		return
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	if not _fire_orange_bloom(center, row, float(data.get("damage", 42.0)), float(data.get("splash_radius", 78.0)), float(data.get("range", 760.0)), 3):
		return
	plant["attack_timer"] = float(data.get("attack_interval", 2.0))
	plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.14)
	game._trigger_plant_action(plant, 0.18)


func _frontmost_enemy_indices(count: int, lane_filter: Array = []) -> Array:
	var candidates: Array = []
	for zombie_index in range(game.zombies.size()):
		var zombie = game.zombies[zombie_index]
		if not game._is_enemy_zombie(zombie):
			continue
		if bool(zombie.get("jumping", false)):
			continue
		if not lane_filter.is_empty() and not lane_filter.has(int(zombie.get("row", -1))):
			continue
		candidates.append({
			"index": zombie_index,
			"x": float(zombie.get("x", 999999.0)),
		})
	candidates.sort_custom(func(a, b): return float(a["x"]) < float(b["x"]))
	var result: Array = []
	for candidate in candidates:
		result.append(int(candidate["index"]))
		if result.size() >= count:
			break
	return result


func _sting_hive_target(origin: Vector2, target_index: int, damage: float, splash_radius: float) -> bool:
	if target_index < 0 or target_index >= game.zombies.size():
		return false
	var zombie = game.zombies[target_index]
	if not game._is_enemy_zombie(zombie):
		return false
	var impact = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 12.0)
	game._damage_zombies_in_circle(impact, splash_radius, damage)
	game.effects.append({
		"shape": "storm_arc",
		"position": origin,
		"target": impact,
		"radius": origin.distance_to(impact),
		"time": 0.2,
		"duration": 0.2,
		"color": Color(1.0, 0.86, 0.24, 0.28),
	})
	return true


func update_hive_flower(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var data = Defs.PLANTS["hive_flower"]
	var center = game._cell_center(row, col) + Vector2(4.0, -18.0)
	if String(plant.get("plant_food_mode", "")) == "queen_swarm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			var stung := false
			for target_index in _frontmost_enemy_indices(2):
				stung = _sting_hive_target(center, int(target_index), float(data.get("ultimate_damage", 52.0)), 52.0) or stung
			if stung:
				plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.18)
				game._trigger_plant_action(plant, 0.18)
			plant["plant_food_interval"] += 0.18
		return
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target_indices = _frontmost_enemy_indices(1)
	if target_indices.is_empty():
		return
	if _sting_hive_target(center, int(target_indices[0]), float(data.get("damage", 34.0)), 38.0):
		plant["attack_timer"] = float(data.get("attack_interval", 1.8))
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.14)
		game._trigger_plant_action(plant, 0.18)


func _apply_mamba_decay(center: Vector2, radius: float, dps: float, duration: float) -> void:
	for zombie_index in game._find_closest_zombies_in_radius(center, radius, 6):
		var zombie = game.zombies[zombie_index]
		zombie["corrode_timer"] = maxf(float(zombie.get("corrode_timer", 0.0)), duration)
		zombie["corrode_dps"] = maxf(float(zombie.get("corrode_dps", 0.0)), dps)
		zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.12)
		game.zombies[zombie_index] = zombie


func update_mamba_tree(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var data = Defs.PLANTS["mamba_tree"]
	var center = game._cell_center(row, col)
	plant["support_timer"] -= cadence_delta
	if String(plant.get("plant_food_mode", "")) == "mamba_grove" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		if float(plant["support_timer"]) > 0.0:
			return
		for coal_row in range(max(0, row - 1), min(game.ROWS, row + 2)):
			if not game._is_row_active(coal_row):
				continue
			for coal_col in range(col, min(game.COLS, col + 3)):
				game._spawn_coal_patch(coal_row, coal_col, float(data.get("ember_duration", 10.0)) + 4.0, float(data.get("ember_dps", 18.0)) * 1.4)
				_apply_mamba_decay(game._cell_center(coal_row, coal_col), game.CELL_SIZE.x * 0.42, float(data.get("ember_dps", 18.0)) * 1.15, 4.8)
		game.effects.append({
			"position": center,
			"radius": 170.0,
			"time": 0.34,
			"duration": 0.34,
			"color": Color(0.22, 0.18, 0.18, 0.3),
		})
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
		game._trigger_plant_action(plant, 0.18)
		plant["support_timer"] = 0.42
		return
	if float(plant["support_timer"]) > 0.0:
		return
	game._spawn_coal_patch(row, col, float(data.get("ember_duration", 10.0)), float(data.get("ember_dps", 18.0)))
	_apply_mamba_decay(center, game.CELL_SIZE.x * 0.42, float(data.get("ember_dps", 18.0)), 3.8)
	game.effects.append({
		"position": center + Vector2(0.0, 10.0),
		"radius": 72.0,
		"time": 0.24,
		"duration": 0.24,
		"color": Color(0.16, 0.12, 0.12, 0.22),
	})
	plant["support_timer"] = float(data.get("ember_interval", 4.6))
	plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.12)
	game._trigger_plant_action(plant, 0.16)


func _chambord_damage(base_damage: float, target_x: float) -> float:
	var proximity = 1.0 - clampf((target_x - game.BOARD_ORIGIN.x) / maxf(game.board_size.x, 1.0), 0.0, 1.0)
	return base_damage * (1.0 + proximity * 0.75)


func _fire_chambord_shot(origin: Vector2, row: int, target_index: int, damage: float) -> bool:
	if target_index < 0 or target_index >= game.zombies.size():
		return false
	var zombie = game.zombies[target_index]
	if not game._is_enemy_zombie(zombie):
		return false
	var actual_damage = _chambord_damage(damage, float(zombie["x"]))
	game.zombies[target_index] = game._apply_zombie_damage(zombie, actual_damage, 0.2)
	game.effects.append({
		"shape": "lane_spray",
		"position": origin,
		"length": maxf(0.0, float(zombie["x"]) - origin.x),
		"width": 10.0,
		"radius": game.board_size.x,
		"time": 0.18,
		"duration": 0.18,
		"color": Color(0.9, 0.98, 1.0, 0.4),
	})
	return true


func update_chambord_sniper(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var data = Defs.PLANTS["chambord_sniper"]
	var center = game._cell_center(row, col) + Vector2(18.0, -16.0)
	if String(plant.get("plant_food_mode", "")) == "sniper_focus" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			var target_index = game._find_lane_target_ignore_fog(row, center.x - 32.0, float(data.get("range", 999.0)))
			if _fire_chambord_shot(center, row, target_index, float(data.get("ultimate_damage", 320.0))):
				plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
				game._trigger_plant_action(plant, 0.18)
			plant["plant_food_interval"] += 0.26
		return
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target_index = game._find_lane_target_ignore_fog(row, center.x - 32.0, float(data.get("range", 999.0)))
	if not _fire_chambord_shot(center, row, target_index, float(data.get("damage", 180.0))):
		return
	plant["attack_timer"] = float(data.get("attack_interval", 3.4))
	plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
	game._trigger_plant_action(plant, 0.2)


func update_dream_disc(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	plant["support_timer"] -= delta
	var center = game._cell_center(row, col)
	if not bool(plant.get("dream_triggered", false)) and float(plant["support_timer"]) <= 0.0:
		var data = Defs.PLANTS["dream_disc"]
		var radius = float(data.get("radius", 150.0))
		var sleep_duration = float(data.get("sleep_duration", 6.0))
		var damage = float(data.get("damage", 26.0))
		if String(plant.get("plant_food_mode", "")) == "dream_wave" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
			radius *= 1.8
			sleep_duration += 3.0
			damage = float(data.get("ultimate_damage", 68.0))
		game._sleep_zombies_in_radius(center, radius, sleep_duration, false)
		game._damage_zombies_in_circle(center, radius * 0.78, damage)
		game.effects.append({
			"position": center,
			"radius": radius,
			"time": 0.34,
			"duration": 0.34,
			"color": Color(0.68, 0.58, 0.96, 0.3),
		})
		plant["dream_triggered"] = true
		plant["support_timer"] = 0.36
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.18)
		game._trigger_plant_action(plant, 0.22)
	if bool(plant.get("dream_triggered", false)) and float(plant["support_timer"]) <= 0.0:
		return true
	return false


func spawn_boomerang_projectile(row: int, spawn_position: Vector2, anchor_x: float, damage: float, max_targets: int) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "boomerang_shooter"))
	game.projectiles.append({
		"kind": "boomerang",
		"row": row,
		"position": spawn_position,
		"speed": 420.0,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
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
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "sakura_shooter"))
	game.projectiles.append({
		"kind": "sakura_petal",
		"row": row,
		"position": spawn_position,
		"speed": 340.0,
		"velocity_y": velocity_y,
		"damage": damage * damage_mult,
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
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if game.call("_find_highest_health_enemy_index") == -1:
		return
	var lotus_data = Defs.PLANTS["lotus_lancer"]
	var base_damage = float(lotus_data.get("damage", 24.0)) * float(game.call("_projectile_damage_multiplier_for_spawn", row, center, "lotus_lancer"))
	var radial_speed = float(lotus_data.get("radial_speed", 210.0))
	var orbit_speed = float(lotus_data.get("orbit_speed", 2.8))
	var max_radius = float(lotus_data.get("range", 520.0))
	var projectile_radius = float(lotus_data.get("projectile_radius", 9.0))
	var orbit_phase = float(game.get("level_time")) * 0.45
	for shot_index in range(8):
		var angle = TAU * float(shot_index) / 8.0 + orbit_phase
		game.projectiles.append({
			"kind": "lotus_orbit_shot",
			"row": row,
			"position": center + Vector2(cos(angle), sin(angle)) * 18.0,
			"speed": radial_speed,
			"velocity_y": 0.0,
			"damage": base_damage,
			"slow_duration": 0.0,
			"color": Color(0.84, 0.7, 1.0, 0.96),
			"radius": projectile_radius,
			"reflected": false,
			"fire": false,
			"free_aim": true,
			"anti_air": true,
			"orbit_center": center,
			"angle": angle,
			"orbit_radius": 18.0,
			"radial_speed": radial_speed,
			"orbit_speed": orbit_speed * (1.0 if shot_index % 2 == 0 else -1.0),
			"max_radius": max_radius,
			"spin_angle": angle,
			"hit_radius": 18.0,
		})
	game.effects.append({
		"shape": "lotus_converge_ring",
		"position": center + Vector2(0.0, -10.0),
		"radius": game.CELL_SIZE.x * 0.78,
		"time": 0.22,
		"duration": 0.22,
		"color": Color(0.82, 0.72, 1.0, 0.22),
		"anim_speed": 6.0,
	})
	plant["shot_cooldown"] = float(Defs.PLANTS["lotus_lancer"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func spawn_mist_projectile(row: int, spawn_position: Vector2, damage: float, slow_duration: float, splash_radius: float, reveal_duration: float) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "mist_orchid"))
	game.projectiles.append({
		"kind": "mist_bloom",
		"row": row,
		"position": spawn_position,
		"speed": 340.0,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
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
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "glowvine"))
	game.projectiles.append({
		"kind": "glow_seed",
		"row": row,
		"position": spawn_position,
		"speed": 360.0,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
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
	var row = clampi(int(round((target.y - game.BOARD_ORIGIN.y) / game.CELL_SIZE.y)), 0, game.ROWS - 1)
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, origin, "moonforge"))
	game.projectiles.append({
		"kind": "moon_meteor",
		"row": row,
		"position": origin,
		"speed": speed,
		"velocity_y": delta.y / travel_time,
		"damage": damage * damage_mult,
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
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var shooter_rows: Array = []
	for zombie in game.zombies:
		if not game._is_enemy_zombie(zombie):
			continue
		var zombie_kind = String(zombie.get("kind", ""))
		if zombie_kind != "shouyue" and zombie_kind != "flywheel_zombie" and zombie_kind != "mech_zombie":
			continue
		if abs(int(zombie["row"]) - row) > 0:
			continue
		shooter_rows.append(int(zombie["row"]))
	if not shooter_rows.is_empty():
		var center = game._cell_center(row, col)
		game.effects.append({
			"shape": "mirror_sniper_call",
			"position": center + Vector2(12.0, -16.0),
			"radius": 30.0,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.82, 0.96, 1.0, 0.14),
			"anim_speed": 5.6,
		})
		plant["flash"] = maxf(float(plant["flash"]), 0.08)
	plant["support_timer"] = float(Defs.PLANTS["mirror_reed"].get("pulse_interval", 2.6))


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
	var center = game._cell_center(row, col)
	var beam_origin = center + Vector2(20.0, -24.0)
	var beam_target = beam_origin + Vector2.RIGHT * 120.0
	var damage = float(Defs.PLANTS["pepper_mortar"]["damage"])
	var target_index = game._find_frontmost_zombie(row)
	if target_index == -1:
		var obstacle_x = game._find_frontmost_obstacle_x(row)
		if obstacle_x < -1000.0:
			plant["attack_timer"] = 0.25
			return
		beam_target = Vector2(obstacle_x, game._row_center_y(row) - 6.0)
		game._damage_obstacles_in_radius(row, obstacle_x, 14.0, damage)
	else:
		var zombie = game.zombies[target_index]
		beam_target = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])) - 10.0)
		zombie = game._apply_zombie_damage(zombie, damage, 0.18)
		game.zombies[target_index] = zombie
	game.effects.append({
		"shape": "pepper_beam",
		"position": beam_origin,
		"target": beam_target,
		"length": maxf(beam_target.x - beam_origin.x, 24.0),
		"width": 34.0,
		"time": 0.26,
		"duration": 0.26,
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
			"shape": "pulse_bulb_wave",
			"position": center,
			"radius": radius,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.98, 0.94, 0.36, 0.34),
			"width": 68.0,
			"anim_speed": 7.2,
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
		var burst_range = float(Defs.PLANTS["fume_shroom"]["range"]) + game.CELL_SIZE.x + 80.0
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
	var range_limit = float(Defs.PLANTS["fume_shroom"]["range"]) + game.CELL_SIZE.x
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
		var sun_count := 2 if game._is_night_level() else 1
		for sun_index in range(sun_count):
			var spread = 0.0
			if sun_count > 1:
				spread = -14.0 if sun_index == 0 else 14.0
			game._spawn_sun(
				center + Vector2(spread + game.rng.randf_range(-8.0, 8.0), -22.0 + sun_index * 4.0),
				center.y - 12.0,
				"plant"
			)
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
	var range_limit = float(Defs.PLANTS["prism_grass"]["range"]) + game.CELL_SIZE.x
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
		"shape": "rainbow_beam",
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
	var target = game._find_global_rearmost_target()
	if target["row"] == -1:
		plant["attack_timer"] = 0.24
		return
	var impact = Vector2(float(target["x"]), game._row_center_y(int(target["row"])))
	game._damage_zombies_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]), float(Defs.PLANTS["meteor_gourd"]["damage"]))
	game._damage_obstacles_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]), float(Defs.PLANTS["meteor_gourd"]["damage"]))
	game._spawn_meteor_strike_effect(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]), 0.34, Color(1.0, 0.54, 0.22, 0.38))
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
	var target = game.zombies[target_index]
	var strike_center = Vector2(float(target["x"]), game._row_center_y(int(target["row"])) - 12.0)
	var chained = game._strike_thunder_chain(target_index, float(Defs.PLANTS["thunder_pine"]["damage"]), float(Defs.PLANTS["thunder_pine"]["chain_damage"]), float(Defs.PLANTS["thunder_pine"]["chain_range"]), 3)
	if chained > 0:
		game._spawn_sky_thunder_strike(strike_center, 58.0, 0.2, Color(0.96, 0.98, 0.74, 0.32))
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
			"shape": "dream_drum_wave",
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
			"shape": "wind_gust_lane",
			"position": center + Vector2(14.0, -6.0),
			"length": game.BOARD_ORIGIN.x + game.board_size.x - center.x,
			"width": game.CELL_SIZE.y * 0.76,
			"radius": game.BOARD_ORIGIN.x + game.board_size.x - center.x,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.72, 0.94, 1.0, 0.36),
			"anim_speed": 5.8,
		})
		game._trigger_plant_action(plant, 0.28)
	plant["flash"] = maxf(float(plant["flash"]), 0.14)
	plant["gust_timer"] = float(Defs.PLANTS["wind_orchid"]["gust_interval"])


func spawn_shadow_pea_projectile(row: int, spawn_position: Vector2, damage: float, pierce_left: int) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "shadow_pea"))
	game.projectiles.append({
		"kind": "shadow_pea",
		"row": row,
		"position": spawn_position,
		"speed": 490.0,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
		"slow_duration": 1.5,
		"color": Color(0.52, 0.22, 0.82),
		"radius": 9.0,
		"reflected": false,
		"fire": false,
		"free_aim": false,
		"anti_air": false,
		"source_enhance_mult": damage_mult,
		"pierce_left": pierce_left,
		"hit_uids": [],
	})


func update_shadow_pea(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	if not game._has_lane_threat_ignore_roof_direct_fire(row, center.x, game.board_size.x):
		return
	spawn_shadow_pea_projectile(
		row,
		center + Vector2(34.0, -12.0),
		float(Defs.PLANTS["shadow_pea"]["damage"]),
		int(Defs.PLANTS["shadow_pea"].get("pierce_count", 2))
	)
	plant["shot_cooldown"] = float(Defs.PLANTS["shadow_pea"]["shoot_interval"])
	game._trigger_plant_action(plant, 0.2)


func update_ice_queen(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var radius = float(Defs.PLANTS["ice_queen"]["radius"])
	var freeze_duration = float(Defs.PLANTS["ice_queen"]["freeze_duration"])
	var hit := false
	for zombie_index in game._find_closest_zombies_in_radius(center, radius, 4):
		var zombie = game.zombies[zombie_index]
		zombie = game._apply_zombie_damage(zombie, 24.0, 0.14, freeze_duration + 2.0)
		zombie["frozen_timer"] = maxf(float(zombie.get("frozen_timer", 0.0)), freeze_duration)
		game.zombies[zombie_index] = zombie
		hit = true
	if hit:
		game.effects.append({
			"position": center,
			"radius": radius,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.72, 0.94, 1.0, 0.26),
		})
		game._trigger_plant_action(plant, 0.22)
	plant["support_timer"] = float(Defs.PLANTS["ice_queen"]["pulse_interval"])


func update_vine_emperor(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col) + Vector2(18.0, 0.0)
	var range_limit = float(Defs.PLANTS["vine_emperor"]["range"])
	var targets = game._find_closest_zombies_in_radius(center, range_limit, int(Defs.PLANTS["vine_emperor"]["max_targets"]))
	if targets.is_empty():
		plant["attack_timer"] = 0.24
		return
	var pulled := false
	for zombie_index in targets:
		var zombie = game.zombies[zombie_index]
		zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["vine_emperor"]["damage"]), 0.14)
		zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer", 0.0)), 1.9)
		zombie["x"] = maxf(center.x + 34.0, float(zombie["x"]) - float(Defs.PLANTS["vine_emperor"]["pull_distance"]))
		game.zombies[zombie_index] = zombie
		pulled = true
	if pulled:
		game.effects.append({
			"position": center,
			"radius": range_limit,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.28, 0.72, 0.24, 0.28),
		})
		game._trigger_plant_action(plant, 0.24)
	plant["attack_timer"] = float(Defs.PLANTS["vine_emperor"]["attack_interval"])


func update_soul_flower(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	game._spawn_sun(
		center + Vector2(game.rng.randf_range(-12.0, 12.0), -20.0),
		center.y - 18.0,
		"plant",
		int(Defs.PLANTS["soul_flower"].get("sun_amount", 75))
	)
	plant["sun_timer"] = float(Defs.PLANTS["soul_flower"]["sun_interval"])
	plant["flash"] = maxf(float(plant["flash"]), 0.12)
	game._trigger_plant_action(plant, 0.28)


func update_plasma_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var target_index = game._find_lane_target_ignore_roof_direct_fire(row, center.x, game.board_size.x)
	if target_index == -1:
		plant["attack_timer"] = 0.24
		return
	var chained = game._strike_thunder_chain(
		target_index,
		float(Defs.PLANTS["plasma_shooter"]["damage"]),
		float(Defs.PLANTS["plasma_shooter"]["chain_damage"]),
		float(Defs.PLANTS["plasma_shooter"]["chain_range"]),
		int(Defs.PLANTS["plasma_shooter"]["max_targets"])
	)
	if chained > 0:
		game.effects.append({
			"shape": "lane_spray",
			"position": center + Vector2(18.0, -12.0),
			"length": game.board_size.x,
			"width": 54.0,
			"radius": game.board_size.x * 0.5,
			"time": 0.18,
			"duration": 0.18,
			"color": Color(0.42, 0.9, 1.0, 0.28),
		})
		game._trigger_plant_action(plant, 0.22)
	plant["attack_timer"] = float(Defs.PLANTS["plasma_shooter"]["shoot_interval"])


func update_crystal_nut(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var hit := false
	for zombie_index in game._find_closest_zombies_in_radius(center, 110.0, 4):
		var zombie = game.zombies[zombie_index]
		zombie = game._apply_zombie_damage(zombie, 48.0, 0.12, 1.6)
		game.zombies[zombie_index] = zombie
		hit = true
	if hit:
		plant["armor_health"] = maxf(float(plant.get("armor_health", 0.0)), float(plant["max_health"]) * float(Defs.PLANTS["crystal_nut"].get("reflect_ratio", 0.3)) * 2.0)
		plant["max_armor_health"] = maxf(float(plant.get("max_armor_health", 0.0)), float(plant["armor_health"]))
		game.effects.append({
			"position": center,
			"radius": 112.0,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.7, 0.88, 1.0, 0.24),
		})
		game._trigger_plant_action(plant, 0.18)
	else:
		plant["health"] = minf(float(plant["max_health"]), float(plant["health"]) + 35.0)
	plant["support_timer"] = 1.15


func update_dragon_fruit(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var range_limit = float(Defs.PLANTS["dragon_fruit"]["cone_range"])
	var burn_duration = float(Defs.PLANTS["dragon_fruit"]["burn_duration"])
	var burn_damage = float(Defs.PLANTS["dragon_fruit"]["burn_damage"])
	var hit := false
	for lane in range(max(0, row - 1), min(game.ROWS, row + 2)):
		hit = game._damage_zombies_in_row_segment(lane, center.x + 10.0, center.x + range_limit, float(Defs.PLANTS["dragon_fruit"]["damage"]), 0.8) or hit
		for zombie_index in game._find_closest_zombies_in_radius(Vector2(center.x + range_limit * 0.45, game._row_center_y(lane)), range_limit * 0.5, 6):
			var zombie = game.zombies[zombie_index]
			if int(zombie["row"]) != lane or float(zombie["x"]) < center.x:
				continue
			zombie["corrode_timer"] = maxf(float(zombie.get("corrode_timer", 0.0)), burn_duration)
			zombie["corrode_dps"] = maxf(float(zombie.get("corrode_dps", 0.0)), burn_damage)
			game.zombies[zombie_index] = zombie
	if hit:
		game.effects.append({
			"shape": "lane_spray",
			"position": center + Vector2(18.0, -10.0),
			"length": range_limit,
			"width": float(Defs.PLANTS["dragon_fruit"]["cone_width"]),
			"radius": range_limit * 0.5,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(1.0, 0.46, 0.18, 0.3),
		})
		game._trigger_plant_action(plant, 0.24)
	plant["attack_timer"] = float(Defs.PLANTS["dragon_fruit"]["attack_interval"])


func update_time_rose(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var radius = float(Defs.PLANTS["time_rose"]["slow_radius"])
	var slowed := false
	for zombie_index in game._find_closest_zombies_in_radius(center, radius, 6):
		var zombie = game.zombies[zombie_index]
		zombie = game._apply_zombie_damage(zombie, 18.0, 0.12, 4.2)
		zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.25)
		game.zombies[zombie_index] = zombie
		slowed = true
	if slowed:
		game.effects.append({
			"position": center,
			"radius": radius,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.96, 0.72, 0.86, 0.24),
		})
		game._trigger_plant_action(plant, 0.22)
	plant["support_timer"] = 2.0


func update_galaxy_sunflower(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var sun_amount = int(Defs.PLANTS["galaxy_sunflower"].get("sun_amount", 100))
	for sun_index in range(2):
		var x_offset = -14.0 if sun_index == 0 else 14.0
		game._spawn_sun(center + Vector2(x_offset, -22.0), center.y - 18.0, "plant", sun_amount)
	for other_row in range(max(0, row - 1), min(game.ROWS, row + 2)):
		for other_col in range(max(0, col - 1), min(game.COLS, col + 2)):
			_heal_targetable_plant(other_row, other_col, 55.0, 0.06)
	game.effects.append({
		"position": center,
		"radius": float(Defs.PLANTS["galaxy_sunflower"].get("damage_boost_radius", 120.0)),
		"time": 0.22,
		"duration": 0.22,
		"color": Color(1.0, 0.9, 0.42, 0.24),
	})
	plant["sun_timer"] = float(Defs.PLANTS["galaxy_sunflower"]["sun_interval"])
	game._trigger_plant_action(plant, 0.3)


func update_void_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var radius = float(Defs.PLANTS["void_shroom"]["pull_radius"])
	var strength = float(Defs.PLANTS["void_shroom"]["pull_strength"])
	var hit := false
	for zombie_index in game._find_closest_zombies_in_radius(center, radius, 8):
		var zombie = game.zombies[zombie_index]
		zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["void_shroom"]["damage"]), 0.12)
		var direction = signf(float(zombie["x"]) - center.x)
		zombie["x"] -= direction * minf(absf(float(zombie["x"]) - center.x), strength)
		zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.12)
		game.zombies[zombie_index] = zombie
		hit = true
	if hit:
		game.effects.append({
			"position": center,
			"radius": radius,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.44, 0.18, 0.68, 0.28),
		})
		game._trigger_plant_action(plant, 0.24)
	plant["support_timer"] = float(Defs.PLANTS["void_shroom"]["pull_interval"])


func update_phoenix_tree(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var target = game._find_global_frontmost_target()
	if int(target.get("row", -1)) == -1:
		return
	var target_row = int(target["row"])
	var spawn_position = Vector2(center.x + 28.0, game._row_center_y(target_row) - 14.0)
	game._spawn_fire_projectile(target_row, spawn_position, float(Defs.PLANTS["phoenix_tree"]["damage"]), 520.0, 10.0)
	if not game.projectiles.is_empty():
		game.projectiles[game.projectiles.size() - 1]["kind"] = "phoenix_flame"
		game.projectiles[game.projectiles.size() - 1]["ignore_lane_hide"] = true
	plant["shot_cooldown"] = float(Defs.PLANTS["phoenix_tree"]["shoot_interval"])
	game.effects.append({
		"position": spawn_position,
		"radius": 34.0,
		"time": 0.16,
		"duration": 0.16,
		"color": Color(1.0, 0.54, 0.18, 0.22),
	})
	game._trigger_plant_action(plant, 0.22)


func update_thunder_god(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target = game._find_global_frontmost_target()
	if int(target.get("row", -1)) == -1:
		plant["attack_timer"] = 0.24
		return
	var target_index = game._find_lane_target(int(target["row"]), float(target["x"]) - 6.0, game.board_size.x)
	if target_index == -1:
		plant["attack_timer"] = 0.24
		return
	var chained = game._strike_thunder_chain(
		target_index,
		float(Defs.PLANTS["thunder_god"]["damage"]),
		float(Defs.PLANTS["thunder_god"]["chain_damage"]),
		float(Defs.PLANTS["thunder_god"]["chain_range"]),
		int(Defs.PLANTS["thunder_god"]["max_targets"])
	)
	if chained > 0:
		game.effects.append({
			"position": game._cell_center(row, col),
			"radius": game.board_size.x,
			"time": 0.2,
			"duration": 0.2,
			"color": Color(0.96, 0.92, 0.42, 0.24),
		})
		game._trigger_plant_action(plant, 0.24)
	plant["attack_timer"] = float(Defs.PLANTS["thunder_god"]["attack_interval"])


# ==================== NEW PURPLE GACHA UPDATE FUNCTIONS ====================

func spawn_prism_pea_projectile(row: int, spawn_position: Vector2, damage: float, split_at_x: float, split_count: int, fragment_damage: float) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "prism_pea"))
	game.projectiles.append({
		"kind": "prism_pea",
		"row": row,
		"position": spawn_position,
		"speed": 480.0,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
		"slow_duration": 0.0,
		"color": Color(0.72, 0.96, 1.0),
		"radius": 7.0,
		"reflected": false,
		"fire": false,
		"free_aim": false,
		"split_at_x": split_at_x,
		"split_count": split_count,
		"fragment_damage": fragment_damage * damage_mult,
		"split_done": false,
	})


func spawn_spiral_bamboo_projectile(row: int, spawn_position: Vector2, anchor_x: float, damage: float, max_hits: int, return_damage: float) -> void:
	var damage_mult = float(game.call("_projectile_damage_multiplier_for_spawn", row, spawn_position, "spiral_bamboo"))
	game.projectiles.append({
		"kind": "boomerang",
		"row": row,
		"position": spawn_position,
		"speed": 420.0,
		"velocity_y": 0.0,
		"damage": damage * damage_mult,
		"return_damage": return_damage * damage_mult,
		"slow_duration": 0.0,
		"color": Color(0.56, 0.88, 0.46),
		"radius": 10.0,
		"reflected": false,
		"fire": false,
		"outbound": true,
		"anchor_x": anchor_x,
		"max_hits": max_hits,
		"hit_uids": [],
		"return_hits": [],
		"return_markers": [],
	})


func update_prism_pea(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	if not game._has_lane_threat_ignore_roof_direct_fire(row, center.x, game.board_size.x):
		return
	var data = Defs.PLANTS["prism_pea"]
	spawn_prism_pea_projectile(row, center + Vector2(32.0, -10.0), float(data["damage"]), center.x + float(data["split_distance"]), int(data["split_count"]), float(data["fragment_damage"]))
	plant["shot_cooldown"] = float(data["shoot_interval"])
	game._trigger_plant_action(plant, 0.18)


func update_magnet_daisy(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["magnet_daisy"]
	var center = game._cell_center(row, col)
	var radius = float(data["radius"])
	var hit := false
	for zombie_index in game._find_closest_zombies_in_radius(center, radius, 8):
		var zombie = game.zombies[zombie_index]
		zombie["x"] += (center.x - float(zombie["x"])) * 0.22
		zombie = game._apply_zombie_slow(zombie, float(data["slow_ratio"]), float(data["slow_duration"]))
		game.zombies[zombie_index] = zombie
		hit = true
	if hit:
		game.effects.append({"position": center, "radius": radius, "time": 0.26, "duration": 0.26, "color": Color(0.64, 0.86, 1.0, 0.24)})
		game._trigger_plant_action(plant, 0.26)
	plant["support_timer"] = float(data["pulse_interval"])


func update_thorn_cactus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var data = Defs.PLANTS["thorn_cactus"]
	var range_dist = float(data["range"])
	var found := false
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie) or int(zombie["row"]) != row:
			continue
		var dist = float(zombie["x"]) - center.x
		if dist > 0.0 and dist < range_dist:
			game.zombies[i] = game._apply_zombie_damage(zombie, float(data["damage"]), 0.1, 0.0)
			found = true
	if found:
		game.effects.append({"position": center + Vector2(50.0, 0.0), "radius": 44.0, "time": 0.18, "duration": 0.18, "color": Color(0.56, 0.82, 0.34, 0.28)})
		game._trigger_plant_action(plant, 0.18)
	plant["shot_cooldown"] = float(data["shoot_interval"])


func update_bubble_lotus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["bubble_lotus"]
	var center = game._cell_center(row, col)
	var radius = float(data["shield_radius"])
	var shield = float(data["shield_hp"])
	var best_ratio := 1.0
	var best_row := -1
	var best_col := -1
	for r in range(game.ROWS):
		for c in range(game.COLS):
			var p = game._top_plant_at(r, c)
			if p == null or String(p.get("kind","")) == "bubble_lotus":
				continue
			var ratio = float(p["health"]) / maxf(float(p.get("max_health", 120.0)), 1.0)
			var dist = game._cell_center(r, c).distance_to(center)
			if dist <= radius and ratio < best_ratio:
				best_ratio = ratio
				best_row = r
				best_col = c
	if best_row >= 0:
		var tp = game._top_plant_at(best_row, best_col)
		if tp != null:
			tp["armor_health"] = maxf(float(tp.get("armor_health", 0.0)), shield)
			tp["max_armor_health"] = maxf(float(tp.get("max_armor_health", 0.0)), shield)
			tp["flash"] = 0.18
			game.grid[best_row][best_col] = tp
		game.effects.append({"position": game._cell_center(best_row, best_col), "radius": 56.0, "time": 0.3, "duration": 0.3, "color": Color(0.56, 0.9, 1.0, 0.3)})
		game._trigger_plant_action(plant, 0.22)
	plant["support_timer"] = float(data["support_interval"])


func update_spiral_bamboo(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	if not game._has_lane_threat_ignore_roof_direct_fire(row, center.x, game.board_size.x):
		return
	var data = Defs.PLANTS["spiral_bamboo"]
	spawn_spiral_bamboo_projectile(row, center + Vector2(30.0, -8.0), center.x + 6.0, float(data["damage"]), int(data["max_hits"]), float(data["return_damage"]))
	plant["shot_cooldown"] = float(data["shoot_interval"])
	game._trigger_plant_action(plant, 0.2)


func update_honey_blossom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["sun_timer"] -= cadence_delta
	if float(plant["sun_timer"]) <= 0.0:
		var center = game._cell_center(row, col)
		game._spawn_sun(center + Vector2(0.0, -20.0), center.y - 30.0, "normal", 50)
		game._trigger_plant_action(plant, 0.2)
		plant["sun_timer"] = float(Defs.PLANTS["honey_blossom"]["sun_interval"])
	plant["honey_timer"] -= cadence_delta
	if float(plant["honey_timer"]) <= 0.0:
		var center = game._cell_center(row, col)
		var slowed := false
		plant["honey_timer"] = float(Defs.PLANTS["honey_blossom"]["honey_refresh"])
		for i in range(game.zombies.size()):
			var zombie = game.zombies[i]
			if not game._is_enemy_zombie(zombie) or int(zombie["row"]) != row:
				continue
			var zpos = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
			if zpos.distance_to(center) < 98.0:
				game.zombies[i] = game._apply_zombie_slow(zombie,
					float(Defs.PLANTS["honey_blossom"]["slow_ratio"]),
					float(Defs.PLANTS["honey_blossom"]["slow_duration"]))
				slowed = true
		if slowed:
			game.effects.append({"position": center + Vector2(36.0, -10.0), "radius": 90.0, "time": 0.24, "duration": 0.24, "color": Color(1.0, 0.82, 0.24, 0.24)})
			game._trigger_plant_action(plant, 0.18)


func update_echo_fern(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["echo_fern"]
	var center = game._cell_center(row, col)
	var radius = float(data["radius"])
	var base_damage = float(data["damage"])
	for zombie_index in game._find_closest_zombies_in_radius(center, radius, 6):
		var zombie = game.zombies[zombie_index]
		var stacks = int(zombie.get("echo_stacks", 0))
		var dmg = base_damage * (1.0 + float(stacks) * float(data["stack_bonus"]))
		zombie = game._apply_zombie_damage(zombie, dmg, 0.12, 0.0)
		zombie["echo_stacks"] = min(stacks + 1, int(data["max_stacks"]))
		game.zombies[zombie_index] = zombie
	game.effects.append({"position": center, "radius": radius, "time": 0.22, "duration": 0.22, "color": Color(0.62, 1.0, 0.82, 0.22)})
	game._trigger_plant_action(plant, 0.22)
	plant["support_timer"] = float(data["pulse_interval"])


func update_glow_ivy(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["glow_ivy"]
	var center = game._cell_center(row, col)
	var hit := false
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie) or int(zombie["row"]) != row:
			continue
		game.zombies[i] = game._apply_zombie_damage(zombie, float(data["damage"]), 0.08, 0.0)
		game.zombies[i]["revealed_timer"] = maxf(float(game.zombies[i].get("revealed_timer",0.0)), 3.0)
		hit = true
	if hit:
		game.effects.append({"shape": "lane_spray", "position": center + Vector2(14.0, -6.0), "length": 180.0, "width": 34.0, "radius": 90.0, "time": 0.18, "duration": 0.18, "color": Color(0.34, 1.0, 0.62, 0.22)})
		game._trigger_plant_action(plant, 0.18)
	plant["attack_timer"] = float(data["attack_interval"])


# ==================== NEW ORANGE GACHA UPDATE FUNCTIONS ====================

func update_laser_lily(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var data = Defs.PLANTS["laser_lily"]
	if String(plant.get("laser_state","")) == "charging":
		plant["charge_timer"] -= cadence_delta
		if float(plant["charge_timer"]) <= 0.0:
			plant["laser_state"] = "firing"
			plant["beam_timer"] = float(data["beam_duration"])
			var center = game._cell_center(row, col)
			var ticks = int(data["ticks_per_beam"])
			game._damage_zombies_in_row_segment(row, center.x + 10.0,
				game.BOARD_ORIGIN.x + game.board_size.x + 20.0,
				float(data["damage"]) * float(ticks), 0.0)
			game.effects.append({"shape": "lane_spray", "position": center + Vector2(16.0, -8.0),
				"length": game.board_size.x, "width": 44.0, "radius": game.board_size.x * 0.5,
				"time": float(data["beam_duration"]), "duration": float(data["beam_duration"]),
				"color": Color(1.0, 0.22, 0.34, 0.36)})
			game._trigger_plant_action(plant, float(data["beam_duration"]))
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	if not game._has_lane_threat_ignore_roof_direct_fire(row, center.x, game.board_size.x):
		return
	plant["laser_state"] = "charging"
	plant["charge_timer"] = float(data["charge_time"])
	plant["shot_cooldown"] = float(data["charge_time"]) + float(data["beam_duration"]) + 0.4


func update_rock_armor_fruit(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var data = Defs.PLANTS["rock_armor_fruit"]
	var regen = float(data["regen"]) * delta
	plant["health"] = minf(float(plant["health"]) + regen, float(plant["max_health"]))
	var prev_layer = int(plant.get("armor_layer", 3))
	var max_layer_hp = float(data["layer_hp"])
	var full_hp = float(plant["max_health"])
	var ratio = float(plant["health"]) / maxf(full_hp, 1.0)
	var cur_layer = int(ceil(ratio * 3.0))
	if cur_layer < prev_layer and cur_layer >= 0:
		var center = game._cell_center(row, col)
		var radius = float(data["shockwave_radius"])
		game._damage_zombies_in_circle(center, radius, float(data["shockwave_damage"]))
		game.effects.append({"position": center, "radius": radius, "time": 0.28, "duration": 0.28, "color": Color(0.82, 0.62, 0.36, 0.32)})
		plant["armor_layer"] = cur_layer


func update_aurora_orchid(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["aurora_orchid"]
	var center = game._cell_center(row, col)
	var radius = float(data["buff_radius"])
	var buff_ratio = float(data["buff_ratio"])
	var heal = float(data["heal_per_pulse"])
	var buff_dur = float(data["buff_duration"])
	for r in range(game.ROWS):
		for c in range(game.COLS):
			var p = game._top_plant_at(r, c)
			if p == null:
				continue
			if game._cell_center(r, c).distance_to(center) > radius:
				continue
			p["aurora_buff_timer"] = buff_dur
			p["aurora_buff_ratio"] = buff_ratio
			p["health"] = minf(float(p["health"]) + heal, float(p.get("max_health", 120.0)))
			if String(p.get("kind","")) == "aurora_orchid":
				game.grid[r][c] = p
			else:
				game.grid[r][c] = p
	game.effects.append({"position": center, "radius": radius, "time": 0.32, "duration": 0.32, "color": Color(0.56, 0.88, 1.0, 0.22)})
	game._trigger_plant_action(plant, 0.3)
	plant["support_timer"] = float(data["support_interval"])


func update_blast_pomegranate(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	var target = game._find_frontmost_zombie(row)
	if target == -1:
		return
	var data = Defs.PLANTS["blast_pomegranate"]
	var target_zombie = game.zombies[target]
	var impact = Vector2(float(target_zombie["x"]), game._row_center_y(int(target_zombie["row"])) - 8.0)
	game._damage_zombies_in_circle(impact, float(data["splash_radius"]), float(data["damage"]))
	var cluster_count = int(data["cluster_count"])
	var cluster_r = float(data["cluster_radius"])
	var cluster_d = float(data["cluster_damage"])
	for i in range(cluster_count):
		var angle = TAU * float(i) / float(cluster_count) + randf() * 0.4
		var spread = impact + Vector2(cos(angle), sin(angle)) * (60.0 + randf() * 40.0)
		game._damage_zombies_in_circle(spread, cluster_r, cluster_d)
		game.effects.append({"position": spread, "radius": cluster_r, "time": 0.18, "duration": 0.18, "color": Color(1.0, 0.32, 0.24, 0.28)})
	game.effects.append({"position": impact, "radius": float(data["splash_radius"]), "time": 0.28, "duration": 0.28, "color": Color(1.0, 0.48, 0.22, 0.32)})
	game._trigger_plant_action(plant, 0.3)
	plant["attack_timer"] = float(data["attack_interval"])


func update_frost_cypress(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	var data = Defs.PLANTS["frost_cypress"]
	var center = game._cell_center(row, col)
	var radius = float(data["radius"])
	var accumulate = float(data["accumulate_time"])
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		var zpos = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		if zpos.distance_to(center) > radius:
			zombie["frost_exposure"] = 0.0
			game.zombies[i] = zombie
			continue
		zombie = game._apply_zombie_slow(zombie, float(data["slow_ratio"]), 0.4)
		zombie["frost_exposure"] = float(zombie.get("frost_exposure", 0.0)) + delta
		if float(zombie["frost_exposure"]) >= accumulate:
			zombie["frozen_timer"] = maxf(float(zombie.get("frozen_timer",0.0)), float(data["freeze_duration"]))
			zombie["frost_exposure"] = 0.0
		game.zombies[i] = zombie
	if float(plant["support_timer"]) <= 0.0:
		game.effects.append({"position": center, "radius": radius, "time": 0.26, "duration": 0.26, "color": Color(0.72, 0.94, 1.0, 0.22)})
		plant["support_timer"] = float(data["pulse_interval"])


func update_mirror_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["copy_timer"] -= cadence_delta
	if float(plant["copy_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["mirror_shroom"]
	var center = game._cell_center(row, col)
	var best_dmg := 0.0
	var best_row := -1
	var best_col := -1
	for r in range(game.ROWS):
		for c in range(max(0, col - 2), min(game.COLS, col + 3)):
			var p = game._top_plant_at(r, c)
			if p == null or String(p.get("kind","")) == "mirror_shroom":
				continue
			var pd = Defs.PLANTS.get(String(p["kind"]), {})
			var pdmg = float(pd.get("damage", float(pd.get("zone_damage", 0.0))))
			if pdmg > best_dmg:
				best_dmg = pdmg
				best_row = r
				best_col = c
	if best_row >= 0 and best_dmg > 0.0:
		var ratio = float(data["clone_damage_ratio"])
		game._damage_zombies_in_row_segment(best_row, center.x, game.BOARD_ORIGIN.x + game.board_size.x + 20.0, best_dmg * ratio, 0.0)
		game.effects.append({"position": game._cell_center(best_row, best_col), "radius": 80.0, "time": 0.22, "duration": 0.22, "color": Color(0.86, 0.86, 1.0, 0.3)})
		game._trigger_plant_action(plant, 0.22)
	plant["copy_timer"] = float(data["copy_interval"])


func update_chain_lotus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["chain_lotus"]
	var center = game._cell_center(row, col)
	var melee_range = float(data["melee_range"])
	var first_target := -1
	var best_dist: float = melee_range
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie) or int(zombie["row"]) != row:
			continue
		var dist = float(zombie["x"]) - center.x
		if dist > 0.0 and dist < best_dist:
			best_dist = dist
			first_target = i
	if first_target == -1:
		return
	var chain_range = float(data["chain_range"])
	var max_chains = int(data["max_chains"])
	var decay = float(data["chain_decay"])
	var cur_damage = float(data["damage"])
	var hit_indices := [first_target]
	var last_pos = Vector2(float(game.zombies[first_target]["x"]), game._row_center_y(row))
	game.zombies[first_target] = game._apply_zombie_damage(game.zombies[first_target], cur_damage, 0.12, 0.0)
	game.effects.append({"position": last_pos, "radius": 36.0, "time": 0.16, "duration": 0.16, "color": Color(0.36, 0.86, 0.72, 0.32)})
	for _chain in range(max_chains):
		cur_damage *= decay
		var next_i := -1
		var next_dist: float = chain_range
		for j in range(game.zombies.size()):
			if hit_indices.has(j):
				continue
			var zz = game.zombies[j]
			if not game._is_enemy_zombie(zz):
				continue
			var zp = Vector2(float(zz["x"]), game._row_center_y(int(zz["row"])))
			var d = zp.distance_to(last_pos)
			if d < next_dist:
				next_dist = d
				next_i = j
		if next_i == -1:
			break
		hit_indices.append(next_i)
		last_pos = Vector2(float(game.zombies[next_i]["x"]), game._row_center_y(int(game.zombies[next_i]["row"])))
		game.zombies[next_i] = game._apply_zombie_damage(game.zombies[next_i], cur_damage, 0.1, 0.0)
		game.effects.append({"position": last_pos, "radius": 28.0, "time": 0.14, "duration": 0.14, "color": Color(0.36, 0.86, 0.72, 0.28)})
	game._trigger_plant_action(plant, 0.18)
	plant["attack_timer"] = float(data["attack_interval"])


func update_plasma_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["plasma_shroom"]
	var center = game._cell_center(row, col)
	var zone_r = float(data["zone_radius"])
	var zone_dur = float(data["zone_duration"])
	var dps = float(data["zone_damage"])
	game.effects.append({
		"shape": "plasma_zone",
		"position": center,
		"radius": zone_r,
		"time": zone_dur,
		"duration": zone_dur,
		"color": Color(0.36, 0.72, 1.0, 0.22),
		"dps": dps,
	})
	game._trigger_plant_action(plant, 0.28)
	plant["attack_timer"] = float(data["attack_interval"])


# ==================== NEW GOLD GACHA UPDATE FUNCTIONS ====================

func update_meteor_flower(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center = game._cell_center(row, col)
	if not game._has_lane_threat_ignore_roof_direct_fire(row, center.x, game.board_size.x):
		return
	var data = Defs.PLANTS["meteor_flower"]
	var target_i = game._find_highest_hp_zombie_in_range(center, 800.0)
	var target_pos = Vector2(game.BOARD_ORIGIN.x + game.board_size.x - 60.0, center.y - 14.0)
	if target_i >= 0:
		target_pos = Vector2(float(game.zombies[target_i]["x"]), game._row_center_y(int(game.zombies[target_i]["row"])) - 14.0)
	game.projectiles.append({
		"kind": "meteor_flower",
		"row": row,
		"position": center + Vector2(28.0, -12.0),
		"speed": 0.0,
		"velocity_y": 0.0,
		"damage": float(data["damage"]),
		"slow_duration": 0.0,
		"color": Color(1.0, 0.48, 0.18),
		"radius": 9.0,
		"reflected": false,
		"fire": false,
		"arc_origin": center + Vector2(28.0, -12.0),
		"arc_target": target_pos,
		"arc_duration": 0.52,
		"arc_height": 82.0,
		"splash_radius": float(data["splash_radius"]),
		"burn_damage": float(data["burn_damage"]),
		"burn_duration": float(data["burn_duration"]),
	})
	plant["shot_cooldown"] = float(data["shoot_interval"])
	game._trigger_plant_action(plant, 0.22)


func update_destiny_tree(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["destiny_tree"]
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var buff_type = rng.randi() % 3
	var center = game._cell_center(row, col)
	for r in range(game.ROWS):
		for c in range(game.COLS):
			var p = game._top_plant_at(r, c)
			if p == null:
				continue
			match buff_type:
				0: p["destiny_dmg_timer"] = float(data["buff_duration"])
				1: p["destiny_speed_timer"] = float(data["buff_duration"])
				2:
					p["armor_health"] = minf(float(p.get("armor_health",0.0)) + 500.0, float(p.get("max_health",120.0)))
					p["max_armor_health"] = maxf(float(p.get("max_armor_health",0.0)), float(p.get("armor_health",0.0)))
			game.grid[r][c] = p
	game.effects.append({"position": center, "radius": 300.0, "time": 0.36, "duration": 0.36, "color": Color(1.0, 0.88, 0.42, 0.22)})
	game._trigger_plant_action(plant, 0.3)
	plant["support_timer"] = float(data["support_interval"])


func update_abyss_tentacle(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["abyss_tentacle"]
	var center = game._cell_center(row, col)
	var grab_range = float(data["grab_range"])
	var execute_hp = float(data["execute_threshold"])
	var best_i := -1
	var best_dist: float = grab_range
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie) or bool(zombie.get("grabbed", false)):
			continue
		var zpos = Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))
		var dist = zpos.distance_to(center)
		if dist < best_dist:
			best_dist = dist
			best_i = i
	if best_i == -1:
		return
	var zt = game.zombies[best_i]
	if float(zt["health"]) <= execute_hp:
		game.zombies[best_i] = game._apply_zombie_damage(zt, float(zt["health"]) + 9999.0, 0.2, 0.0)
	else:
		game.zombies[best_i] = game._apply_zombie_damage(zt, float(data["damage"]) * float(data["hold_duration"]), 0.2, 0.0)
		game.zombies[best_i]["rooted_timer"] = maxf(float(game.zombies[best_i].get("rooted_timer",0.0)), float(data["hold_duration"]))
	game.effects.append({"position": center, "radius": 80.0, "time": 0.28, "duration": 0.28, "color": Color(0.28, 0.08, 0.44, 0.36)})
	game._trigger_plant_action(plant, 0.28)
	plant["attack_timer"] = float(data["attack_interval"])


func update_solar_emperor(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["sun_timer"] -= cadence_delta
	if float(plant["sun_timer"]) <= 0.0:
		var center = game._cell_center(row, col)
		game._spawn_sun(center + Vector2(0.0, -22.0), center.y - 36.0, "normal", 150)
		game._trigger_plant_action(plant, 0.22)
		plant["sun_timer"] = float(Defs.PLANTS["solar_emperor"]["sun_interval"])
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) <= 0.0:
		var center = game._cell_center(row, col)
		var target_i = game._find_frontmost_zombie(row)
		if target_i >= 0:
			game._damage_zombies_in_row_segment(row, center.x + 10.0, game.BOARD_ORIGIN.x + game.board_size.x + 20.0, float(Defs.PLANTS["solar_emperor"]["damage"]), 0.0)
			game.effects.append({"shape": "lane_spray", "position": center + Vector2(14.0, -6.0),
				"length": game.board_size.x, "width": 32.0, "radius": game.board_size.x * 0.5,
				"time": 0.18, "duration": 0.18, "color": Color(1.0, 0.88, 0.32, 0.28)})
			game._trigger_plant_action(plant, 0.2)
		plant["shot_cooldown"] = float(Defs.PLANTS["solar_emperor"]["shoot_interval"])


func update_shadow_assassin(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["shadow_assassin"]
	var col_threshold = int(data["backstab_col_threshold"])
	var best_i := -1
	var best_hp := -1.0
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if not game._is_enemy_zombie(zombie):
			continue
		var zhp = float(zombie["health"])
		if zhp > best_hp:
			best_hp = zhp
			best_i = i
	if best_i == -1:
		return
	var zt = game.zombies[best_i]
	var zombie_col = int((float(zt["x"]) - game.BOARD_ORIGIN.x) / game.CELL_SIZE.x)
	var dmg = float(data["damage"])
	if zombie_col >= col_threshold:
		dmg *= float(data["backstab_multiplier"])
	game.zombies[best_i] = game._apply_zombie_damage(zt, dmg, 0.18, 0.0)
	var zpos = Vector2(float(zt["x"]), game._row_center_y(int(zt["row"])))
	game.effects.append({"position": zpos, "radius": 44.0, "time": 0.2, "duration": 0.2, "color": Color(0.22, 0.08, 0.36, 0.44)})
	game._trigger_plant_action(plant, 0.2)
	plant["attack_timer"] = float(data["attack_interval"])


func update_core_blossom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	var data = Defs.PLANTS["core_blossom"]
	if String(plant.get("core_state","")) == "charging":
		plant["charge_timer"] -= cadence_delta
		if float(plant["charge_timer"]) <= 0.0:
			var center = game._cell_center(row, col)
			game._damage_zombies_in_circle(center, float(data["radius"]), float(data["damage"]))
			game._damage_obstacles_in_circle(center, float(data["radius"]), float(data["damage"]))
			game.effects.append({"position": center, "radius": float(data["radius"]), "time": 0.36, "duration": 0.36, "color": Color(1.0, 0.48, 0.16, 0.36)})
			game._trigger_plant_action(plant, 0.36)
			plant["core_state"] = "recharging"
			plant["charge_timer"] = float(data["recharge_time"])
		return
	if String(plant.get("core_state","")) == "recharging":
		plant["charge_timer"] -= cadence_delta
		if float(plant["charge_timer"]) <= 0.0:
			plant["core_state"] = "charging"
			plant["charge_timer"] = float(data["charge_time"])
		return
	plant["core_state"] = "charging"
	plant["charge_timer"] = float(data["charge_time"])


func update_holy_lotus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) <= 0.0:
		var data = Defs.PLANTS["holy_lotus"]
		var center = game._cell_center(row, col)
		var radius = float(data["heal_radius"])
		for r in range(game.ROWS):
			for c in range(game.COLS):
				var p = game._top_plant_at(r, c)
				if p == null:
					continue
				if game._cell_center(r, c).distance_to(center) <= radius:
					p["health"] = minf(float(p["health"]) + float(data["heal_amount"]), float(p.get("max_health",120.0)))
					game.grid[r][c] = p
		game.effects.append({"position": center, "radius": radius, "time": 0.26, "duration": 0.26, "color": Color(1.0, 0.96, 0.72, 0.2)})
		game._trigger_plant_action(plant, 0.22)
		plant["support_timer"] = float(data["heal_interval"])
	plant["save_cooldown"] -= delta
	if float(plant.get("save_cooldown",0.0)) < 0.0:
		plant["save_cooldown"] = 0.0


func update_chaos_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = game._plant_cadence_delta(delta, row, col)
	plant["effect_timer"] -= cadence_delta
	if float(plant["effect_timer"]) > 0.0:
		return
	var data = Defs.PLANTS["chaos_shroom"]
	var center = game._cell_center(row, col)
	var effect_type = game.rng.randi() % 5
	match effect_type:
		0:
			var target_i = game._find_highest_hp_zombie_in_range(center, 600.0)
			if target_i >= 0:
				game.zombies[target_i] = game._apply_zombie_damage(game.zombies[target_i], 100.0, 0.2, 0.0)
				game.effects.append({"position": Vector2(float(game.zombies[target_i]["x"]), game._row_center_y(int(game.zombies[target_i]["row"]))), "radius": 60.0, "time": 0.24, "duration": 0.24, "color": Color(0.8, 0.2, 0.9, 0.4)})
		1:
			game._spawn_sun(center + Vector2(0.0, -18.0), center.y - 30.0, "normal", 100)
		2:
			for zombie_index in game._find_closest_zombies_in_radius(center, 200.0, 3):
				var zombie = game.zombies[zombie_index]
				zombie["frozen_timer"] = maxf(float(zombie.get("frozen_timer",0.0)), 2.0)
				game.zombies[zombie_index] = zombie
			game.effects.append({"position": center, "radius": 200.0, "time": 0.26, "duration": 0.26, "color": Color(0.72, 0.94, 1.0, 0.28)})
		3:
			for r in range(max(0, row - 1), min(game.ROWS, row + 2)):
				for c in range(max(0, col - 1), min(game.COLS, col + 2)):
					var p = game._top_plant_at(r, c)
					if p != null:
						p["health"] = minf(float(p["health"]) + 150.0, float(p.get("max_health",120.0)))
						game.grid[r][c] = p
			game.effects.append({"position": center, "radius": 120.0, "time": 0.28, "duration": 0.28, "color": Color(0.72, 1.0, 0.72, 0.26)})
		4:
			for i in range(5):
				var angle = TAU * float(i) / 5.0
				var spore_row = clampi(row + (game.rng.randi() % 3) - 1, 0, game.ROWS - 1)
				game._spawn_projectile(spore_row, center + Vector2(16.0, -8.0), Color(0.7, 0.3, 0.9), 40.0, 0.0, 440.0, 6.0)
			game.effects.append({"position": center, "radius": 110.0, "time": 0.22, "duration": 0.22, "color": Color(0.86, 0.48, 0.96, 0.32)})
	game._trigger_plant_action(plant, 0.22)
	plant["effect_timer"] = float(data["effect_interval"])
