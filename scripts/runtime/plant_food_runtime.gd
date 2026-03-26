extends RefCounted
class_name PlantFoodRuntime

const Defs = preload("res://scripts/game_defs.gd")
const SUPPORTED_KINDS = [
	"peashooter",
	"sunflower",
	"cherry_bomb",
	"wallnut",
	"potato_mine",
	"snow_pea",
	"chomper",
	"repeater",
	"amber_shooter",
	"vine_lasher",
	"pepper_mortar",
	"cactus_guard",
	"pulse_bulb",
	"sun_bean",
	"wind_orchid",
	"wallnut_bowling",
	"puff_shroom",
	"sun_shroom",
	"fume_shroom",
	"grave_buster",
	"hypno_shroom",
	"scaredy_shroom",
	"ice_shroom",
	"doom_shroom",
	"moon_lotus",
	"prism_grass",
	"lantern_bloom",
	"meteor_gourd",
	"root_snare",
	"thunder_pine",
	"dream_drum",
	"lily_pad",
	"squash",
	"threepeater",
	"tangle_kelp",
	"jalapeno",
	"spikeweed",
	"torchwood",
	"tallnut",
	"sea_shroom",
	"plantern",
	"cactus",
	"blover",
	"split_pea",
	"starfruit",
	"pumpkin",
	"magnet_shroom",
	"mist_orchid",
	"anchor_fern",
	"glowvine",
	"brine_pot",
	"storm_reed",
	"moonforge",
	"boomerang_shooter",
	"sakura_shooter",
	"lotus_lancer",
	"mirror_reed",
	"frost_fan",
	"cabbage_pult",
	"flower_pot",
	"kernel_pult",
	"coffee_bean",
	"garlic",
	"umbrella_leaf",
	"marigold",
	"melon_pult",
	"origami_blossom",
	"chimney_pepper",
	"tesla_tulip",
	"brick_guard",
	"signal_ivy",
	"roof_vane",
	"skylight_melon",
]

var game: Control


func _init(game_owner: Control) -> void:
	game = game_owner


static func supported_kinds() -> Array:
	return SUPPORTED_KINDS.duplicate()


func plant_has_food_power(plant: Dictionary) -> bool:
	return String(plant["plant_food_mode"]) != "" or float(plant.get("armor_health", 0.0)) > 0.0


func _can_activate_bowling_lane_food(row: int, col: int) -> bool:
	return game._can_target_empty_bowling_lane_with_plant_food(row, col)


func activate(row: int, col: int) -> bool:
	var plant_variant = game._targetable_plant_at(row, col)
	if plant_variant == null:
		if _can_activate_bowling_lane_food(row, col):
			var spawn_center = game._cell_center(row, col)
			game._spawn_bowling_roller(row, col, true)
			game.effects.append({
				"position": spawn_center,
				"radius": 86.0,
				"time": 0.28,
				"duration": 0.28,
				"color": Color(0.28, 0.98, 0.76, 0.32),
				"shape": "nut_blast",
				"anim_speed": 7.8,
			})
			return true
		return false

	var plant = plant_variant
	plant["sleep_timer"] = 0.0
	var center = game._cell_center(row, col)
	var kind = String(plant["kind"])
	match kind:
		"peashooter", "amber_shooter", "puff_shroom", "scaredy_shroom":
			if String(plant["plant_food_mode"]) == "pea_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "pea_storm"
			plant["plant_food_timer"] = 2.5
			if kind == "amber_shooter":
				plant["plant_food_timer"] = 2.8
			elif kind == "scaredy_shroom":
				plant["plant_food_timer"] = 3.0
			plant["plant_food_interval"] = 0.01
		"sunflower":
			plant["plant_food_mode"] = "sun_burst"
			plant["plant_food_timer"] = 0.7
			plant["plant_food_interval"] = 0.0
			for index in range(3):
				var angle = -0.6 + float(index) * 0.6
				var offset = Vector2(cos(angle), sin(angle)) * 26.0
				game._spawn_sun(center + offset, center.y - 20.0 + offset.y * 0.2, "plant_food")
		"cherry_bomb":
			if float(plant["fuse_timer"]) <= 0.05:
				return false
			plant["plant_food_mode"] = "mega_bomb"
			plant["plant_food_timer"] = minf(float(plant["fuse_timer"]), 0.18)
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.18)
		"wallnut":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 8000.0
			plant["max_armor_health"] = 8000.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"lily_pad":
			plant["plant_food_mode"] = "pad_bloom"
			plant["plant_food_timer"] = 0.4
			for water_row in game.water_rows:
				for water_col in range(game.COLS):
					if game._support_plant_at(int(water_row), water_col) != null or game._top_plant_at(int(water_row), water_col) != null:
						continue
					game.support_grid[int(water_row)][water_col] = game._create_plant("lily_pad", int(water_row), water_col)
					game.support_grid[int(water_row)][water_col]["flash"] = 0.18
		"sea_shroom":
			if String(plant["plant_food_mode"]) == "pea_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "pea_storm"
			plant["plant_food_timer"] = 2.3
			plant["plant_food_interval"] = 0.01
		"plantern":
			plant["plant_food_mode"] = "fog_lantern"
			plant["plant_food_timer"] = 8.0
			game._trigger_blover_fog_clear(8.0)
			game.effects.append({
				"position": center,
				"radius": 260.0,
				"time": 0.36,
				"duration": 0.36,
				"color": Color(1.0, 0.94, 0.66, 0.24),
			})
		"cactus":
			if String(plant["plant_food_mode"]) == "cactus_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "cactus_storm"
			plant["plant_food_timer"] = 2.4
			plant["plant_food_interval"] = 0.01
		"blover":
			plant["plant_food_mode"] = "blover_burst"
			plant["plant_food_timer"] = 0.45
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.06)
		"split_pea":
			if String(plant["plant_food_mode"]) == "split_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "split_storm"
			plant["plant_food_timer"] = 2.3
			plant["plant_food_interval"] = 0.01
		"starfruit":
			if String(plant["plant_food_mode"]) == "star_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "star_storm"
			plant["plant_food_timer"] = 2.0
			plant["plant_food_interval"] = 0.01
		"squash":
			var squash_targets = game._find_closest_zombies_in_radius(center, 240.0, 3)
			if squash_targets.is_empty():
				return false
			plant["plant_food_mode"] = "squash_frenzy"
			plant["plant_food_timer"] = 0.3
			for zombie_index in squash_targets:
				var squash_zombie = game.zombies[zombie_index]
				squash_zombie = game._apply_zombie_damage(squash_zombie, float(Defs.PLANTS["squash"]["damage"]), 0.3, 0.0, true)
				game.zombies[zombie_index] = squash_zombie
			plant["health"] = 0.0
		"potato_mine":
			plant["armed"] = true
			plant["arm_timer"] = 0.0
			plant["plant_food_mode"] = "mine_burst"
			plant["plant_food_timer"] = 0.7
			game._spawn_bonus_potato_mines(row, col, 2)
		"snow_pea":
			if String(plant["plant_food_mode"]) == "ice_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "ice_storm"
			plant["plant_food_timer"] = 2.5
			plant["plant_food_interval"] = 0.01
			for i in range(game.zombies.size()):
				var zombie = game.zombies[i]
				if not game._is_enemy_zombie(zombie):
					continue
				if int(zombie["row"]) == row and float(zombie["x"]) >= center.x - 20.0:
					zombie["slow_timer"] = maxf(float(zombie["slow_timer"]), 16.0)
					zombie["flash"] = maxf(float(zombie["flash"]), 0.12)
					game.zombies[i] = zombie
		"chomper":
			plant["plant_food_mode"] = "chomp_frenzy"
			plant["plant_food_timer"] = 0.85
			plant["chew_timer"] = 0.0
			var eaten = 0
			var targets = game._find_closest_lane_zombies(row, center.x, 3, 300.0)
			for zombie_index in targets:
				var zombie = game.zombies[zombie_index]
				zombie["health"] = 0.0
				zombie["flash"] = 0.25
				game.zombies[zombie_index] = zombie
				eaten += 1
			if eaten <= 0:
				plant["plant_food_timer"] = 0.45
		"repeater":
			if String(plant["plant_food_mode"]) == "double_storm" and (float(plant["plant_food_timer"]) > 0.0 or int(plant["plant_food_charges"]) > 0):
				return false
			plant["plant_food_mode"] = "double_storm"
			plant["plant_food_timer"] = 2.7
			plant["plant_food_interval"] = 0.01
			plant["plant_food_charges"] = 1
		"threepeater":
			if String(plant["plant_food_mode"]) == "tri_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "tri_storm"
			plant["plant_food_timer"] = 2.8
			plant["plant_food_interval"] = 0.01
		"boomerang_shooter":
			if String(plant["plant_food_mode"]) == "boomerang_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "boomerang_storm"
			plant["plant_food_timer"] = 2.1
			plant["plant_food_interval"] = 0.01
		"sakura_shooter":
			if String(plant["plant_food_mode"]) == "sakura_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "sakura_storm"
			plant["plant_food_timer"] = 2.0
			plant["plant_food_interval"] = 0.01
		"lotus_lancer":
			if String(plant["plant_food_mode"]) == "lancer_burst" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "lancer_burst"
			plant["plant_food_timer"] = 1.4
			plant["plant_food_interval"] = 0.01
		"mist_orchid":
			if String(plant["plant_food_mode"]) == "mist_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "mist_storm"
			plant["plant_food_timer"] = 1.8
			plant["plant_food_interval"] = 0.01
		"anchor_fern":
			plant["plant_food_mode"] = "anchor_burst"
			plant["plant_food_timer"] = 0.45
			for other_row in range(max(0, row - 1), min(game.ROWS, row + 2)):
				for other_col in range(max(0, col - 2), min(game.COLS, col + 3)):
					var ally = game._targetable_plant_at(other_row, other_col)
					if ally == null:
						continue
					ally["rooted_timer"] = maxf(float(ally.get("rooted_timer", 0.0)), 6.0)
					ally["flash"] = maxf(float(ally.get("flash", 0.0)), 0.16)
					game._set_targetable_plant(other_row, other_col, ally)
			for zombie_index in game._find_closest_zombies_in_radius(center, 260.0, 6):
				var anchor_zombie = game.zombies[zombie_index]
				anchor_zombie = game._apply_zombie_damage(anchor_zombie, 110.0, 0.2)
				anchor_zombie["rooted_timer"] = maxf(float(anchor_zombie.get("rooted_timer", 0.0)), 2.8)
				game.zombies[zombie_index] = anchor_zombie
		"glowvine":
			if String(plant["plant_food_mode"]) == "glow_burst" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "glow_burst"
			plant["plant_food_timer"] = 1.6
			plant["plant_food_interval"] = 0.01
		"brine_pot":
			plant["plant_food_mode"] = "brine_flood"
			plant["plant_food_timer"] = 0.45
			for _burst in range(2):
				var brine_target = game._find_global_frontmost_target()
				if int(brine_target["row"]) == -1:
					break
				var brine_impact = Vector2(float(brine_target["x"]) + game.rng.randf_range(-18.0, 18.0), game._row_center_y(int(brine_target["row"])))
				game._damage_zombies_in_circle(brine_impact, float(Defs.PLANTS["brine_pot"]["splash_radius"]) + 22.0, 120.0)
				game._damage_obstacles_in_circle(brine_impact, float(Defs.PLANTS["brine_pot"]["splash_radius"]), 120.0)
				game._spawn_bog_pool(brine_impact, float(Defs.PLANTS["brine_pot"]["bog_radius"]) + 30.0, float(Defs.PLANTS["brine_pot"]["bog_duration"]) + 2.0)
		"storm_reed":
			plant["plant_food_mode"] = "storm_front"
			plant["plant_food_timer"] = 0.45
			for lane in game.active_rows:
				var reed_target = game._find_storm_reed_target(int(lane), game._cell_center(int(lane), int(Defs.PLANTS["storm_reed"]["trigger_col"])).x - game.CELL_SIZE.x * 0.4)
				if reed_target != -1:
					game._strike_thunder_chain(reed_target, 120.0, 78.0, 160.0, 4)
		"moonforge":
			plant["plant_food_mode"] = "moonfall"
			plant["plant_food_timer"] = 0.5
			for _meteor in range(3):
				var moon_target = game._find_global_frontmost_target()
				if int(moon_target["row"]) == -1:
					break
				var moon_impact = Vector2(float(moon_target["x"]) + game.rng.randf_range(-22.0, 22.0), game._row_center_y(int(moon_target["row"])) - 10.0)
				game._explode_moonforge_projectile({"damage": 130.0, "splash_radius": 94.0}, moon_impact)
		"mirror_reed":
			plant["plant_food_mode"] = "mirror_burst"
			plant["plant_food_timer"] = 0.35
			plant["support_timer"] = 0.0
		"frost_fan":
			if String(plant["plant_food_mode"]) == "frost_gale" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "frost_gale"
			plant["plant_food_timer"] = 1.6
			plant["plant_food_interval"] = 0.01
		"cabbage_pult":
			plant["plant_food_mode"] = "cabbage_barrage"
			plant["plant_food_timer"] = 2.1
			plant["plant_food_interval"] = 0.01
		"flower_pot":
			plant["plant_food_mode"] = "pot_rain"
			plant["plant_food_timer"] = 0.45
			for lane in game.active_rows:
				for pot_col in range(game.COLS):
					if game._targetable_plant_at(int(lane), pot_col) != null:
						continue
					if game._cell_terrain_kind(int(lane), pot_col) != "roof":
						continue
					game.support_grid[int(lane)][pot_col] = game._create_plant("flower_pot", int(lane), pot_col)
					game.support_grid[int(lane)][pot_col]["flash"] = 0.18
		"kernel_pult":
			plant["plant_food_mode"] = "butter_barrage"
			plant["plant_food_timer"] = 2.0
			plant["plant_food_interval"] = 0.01
		"coffee_bean":
			plant["plant_food_mode"] = "coffee_awaken"
			plant["plant_food_timer"] = 0.35
			game._wake_all_plants()
			for lane in game.active_rows:
				for wake_col in range(game.COLS):
					var wake_plant = game._top_plant_at(int(lane), wake_col)
					if wake_plant == null:
						continue
					wake_plant["sleep_timer"] = 0.0
					wake_plant["flash"] = maxf(float(wake_plant.get("flash", 0.0)), 0.16)
					game.grid[int(lane)][wake_col] = wake_plant
		"garlic":
			plant["plant_food_mode"] = "garlic_guard"
			plant["plant_food_timer"] = 0.45
			for zombie_index in game._find_closest_zombies_in_radius(center, 220.0, 6):
				var garlic_zombie = game.zombies[zombie_index]
				var redirect_row = game._choose_adjacent_valid_row_for_kind(String(garlic_zombie["kind"]), int(garlic_zombie["row"]))
				garlic_zombie["row"] = redirect_row
				garlic_zombie["special_pause_timer"] = maxf(float(garlic_zombie.get("special_pause_timer", 0.0)), 0.35)
				garlic_zombie["flash"] = maxf(float(garlic_zombie.get("flash", 0.0)), 0.14)
				game.zombies[zombie_index] = garlic_zombie
		"umbrella_leaf":
			plant["plant_food_mode"] = "umbrella_guard"
			plant["plant_food_timer"] = 1.2
			for i in range(game.zombies.size() - 1, -1, -1):
				var umbrella_zombie = game.zombies[i]
				var umbrella_kind = String(umbrella_zombie.get("kind", ""))
				if not game._is_enemy_zombie(umbrella_zombie):
					continue
				if umbrella_kind == "bungee_zombie":
					game.zombies.remove_at(i)
					continue
				if umbrella_kind == "catapult_zombie":
					umbrella_zombie["catapult_cooldown"] = maxf(float(umbrella_zombie.get("catapult_cooldown", 0.0)), 2.4)
					umbrella_zombie["special_pause_timer"] = maxf(float(umbrella_zombie.get("special_pause_timer", 0.0)), 0.55)
					game.zombies[i] = umbrella_zombie
		"marigold":
			plant["plant_food_mode"] = "gold_bloom"
			plant["plant_food_timer"] = 0.55
			for index in range(5):
				var angle = -1.0 + float(index) * 0.5
				var offset = Vector2(cos(angle), sin(angle)) * 30.0
				game._spawn_sun(center + offset, center.y - 18.0 + offset.y * 0.2, "plant_food")
		"melon_pult":
			plant["plant_food_mode"] = "melon_storm"
			plant["plant_food_timer"] = 1.9
			plant["plant_food_interval"] = 0.01
		"origami_blossom":
			if String(plant["plant_food_mode"]) == "origami_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "origami_storm"
			plant["plant_food_timer"] = 1.9
			plant["plant_food_interval"] = 0.01
		"chimney_pepper":
			plant["plant_food_mode"] = "chimney_volley"
			plant["plant_food_timer"] = 1.8
			plant["plant_food_interval"] = 0.01
		"tesla_tulip":
			plant["plant_food_mode"] = "tesla_storm"
			plant["plant_food_timer"] = 1.8
			plant["plant_food_interval"] = 0.01
		"brick_guard":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 9000.0
			plant["max_armor_health"] = 9000.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"signal_ivy":
			plant["plant_food_mode"] = "signal_burst"
			plant["plant_food_timer"] = 0.45
			plant["support_timer"] = 0.0
		"roof_vane":
			plant["plant_food_mode"] = "roof_gale"
			plant["plant_food_timer"] = 0.45
			plant["gust_timer"] = 0.0
		"skylight_melon":
			plant["plant_food_mode"] = "skylight_storm"
			plant["plant_food_timer"] = 1.8
			plant["plant_food_interval"] = 0.01
			plant["shot_cooldown"] = 0.0
		"vine_lasher":
			plant["plant_food_mode"] = "lash_frenzy"
			plant["plant_food_timer"] = 0.6
			var lash_range = 280.0
			for zombie_index in game._find_closest_lane_zombies(row, center.x, 5, lash_range):
				var lash_zombie = game.zombies[zombie_index]
				lash_zombie["health"] -= 120.0
				lash_zombie["slow_timer"] = maxf(float(lash_zombie["slow_timer"]), 4.0)
				lash_zombie["flash"] = 0.2
				game.zombies[zombie_index] = lash_zombie
			game._damage_obstacles_in_radius(row, center.x + lash_range * 0.5, lash_range * 0.5, 120.0)
			game.effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(20.0, -6.0),
				"length": lash_range,
				"width": 62.0,
				"radius": lash_range * 0.5,
				"time": 0.28,
				"duration": 0.28,
				"color": Color(0.42, 0.94, 0.34, 0.3),
			})
		"pepper_mortar":
			plant["plant_food_mode"] = "mortar_burst"
			plant["plant_food_timer"] = 0.4
			game._damage_zombies_in_radius(row, center.x + 130.0, 210.0, 110.0)
			game._damage_obstacles_in_radius(row, center.x + 130.0, 210.0, 110.0)
			game.effects.append({
				"position": center + Vector2(130.0, 0.0),
				"radius": 210.0,
				"time": 0.4,
				"duration": 0.4,
				"color": Color(1.0, 0.36, 0.14, 0.5),
			})
		"cactus_guard":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 4200.0
			plant["max_armor_health"] = 4200.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"pulse_bulb":
			plant["plant_food_mode"] = "pulse_burst"
			plant["plant_food_timer"] = 0.4
			var burst_radius = float(Defs.PLANTS["pulse_bulb"].get("radius", 175.0)) + 70.0
			game._damage_zombies_in_circle(center, burst_radius, 120.0)
			game._damage_obstacles_in_circle(center, burst_radius, 120.0)
			game.effects.append({
				"position": center,
				"radius": burst_radius,
				"time": 0.38,
				"duration": 0.38,
				"color": Color(0.98, 0.98, 0.42, 0.46),
			})
		"spikeweed":
			plant["plant_food_mode"] = "spike_storm"
			plant["plant_food_timer"] = 0.45
			for lane in [row - 1, row, row + 1]:
				if lane < 0 or lane >= game.ROWS or not game._is_row_active(lane):
					continue
				game._damage_zombies_in_radius(int(lane), center.x, game.board_size.x, 120.0)
				for i in range(game.zombies.size()):
					var spike_zombie = game.zombies[i]
					if int(spike_zombie["row"]) != int(lane) or String(spike_zombie["kind"]) != "zomboni":
						continue
					spike_zombie["health"] = 0.0
					game.zombies[i] = spike_zombie
		"sun_bean":
			plant["plant_food_mode"] = "sun_burst"
			plant["plant_food_timer"] = 0.7
			plant["plant_food_interval"] = 0.0
			for index in range(4):
				var angle = -0.8 + float(index) * 0.5
				var offset = Vector2(cos(angle), sin(angle)) * 28.0
				game._spawn_sun(center + offset, center.y - 20.0 + offset.y * 0.2, "plant_food")
		"sun_shroom":
			plant["mature"] = true
			plant["grow_timer"] = 0.0
			plant["plant_food_mode"] = "sun_burst"
			plant["plant_food_timer"] = 0.8
			plant["plant_food_interval"] = 0.0
			for index in range(5):
				var angle = -1.0 + float(index) * 0.5
				var offset = Vector2(cos(angle), sin(angle)) * 32.0
				game._spawn_sun(center + offset, center.y - 24.0 + offset.y * 0.2, "plant_food")
			game.effects.append({
				"position": center,
				"radius": 76.0,
				"time": 0.32,
				"duration": 0.32,
				"color": Color(1.0, 0.92, 0.42, 0.3),
			})
		"fume_shroom":
			plant["plant_food_mode"] = "fume_burst"
			plant["plant_food_timer"] = 1.8
			plant["plant_food_interval"] = 0.01
			var fume_range = float(Defs.PLANTS["fume_shroom"]["range"]) + 70.0
			var fume_damage = 160.0
			for i in range(game.zombies.size()):
				var fume_zombie = game.zombies[i]
				if int(fume_zombie["row"]) != row or bool(fume_zombie.get("jumping", false)) or not game._is_enemy_zombie(fume_zombie):
					continue
				var distance = float(fume_zombie["x"]) - center.x
				if distance < -20.0 or distance > fume_range:
					continue
				fume_zombie = game._apply_zombie_damage(fume_zombie, fume_damage, 0.22, 0.0, true)
				game.zombies[i] = fume_zombie
			game._damage_obstacles_in_radius(row, center.x + fume_range * 0.5, fume_range * 0.5, fume_damage)
			game.effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(30.0, -8.0),
				"length": fume_range,
				"width": float(Defs.PLANTS["fume_shroom"].get("width", 92.0)) * 1.65,
				"radius": fume_range * 0.58,
				"time": 0.36,
				"duration": 0.36,
				"color": Color(0.9, 0.68, 1.0, 0.3),
			})
		"grave_buster":
			var removed_graves := 0
			for i in range(game.graves.size() - 1, -1, -1):
				game.graves.remove_at(i)
				removed_graves += 1
			if removed_graves <= 0:
				return false
			plant["plant_food_mode"] = "grave_storm"
			plant["plant_food_timer"] = 0.45
			for index in range(min(removed_graves, 4)):
				var angle = -0.8 + float(index) * 0.5
				var offset = Vector2(cos(angle), sin(angle)) * 24.0
				game._spawn_sun(center + offset, center.y - 18.0, "plant_food")
			game.effects.append({
				"position": center,
				"radius": 150.0,
				"time": 0.38,
				"duration": 0.38,
				"color": Color(0.42, 0.94, 0.34, 0.24),
			})
		"hypno_shroom":
			var blast_targets = game._find_closest_zombies_in_radius(center, 220.0, 3)
			if blast_targets.is_empty():
				return false
			plant["plant_food_mode"] = "mind_burst"
			plant["plant_food_timer"] = 0.4
			for zombie_index in blast_targets:
				var zombie = game.zombies[zombie_index]
				if game._is_boss_zombie(zombie):
					continue
				zombie = game._hypnotize_zombie(zombie)
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.9)
				game.zombies[zombie_index] = zombie
			game.effects.append({
				"position": center,
				"radius": 220.0,
				"time": 0.34,
				"duration": 0.34,
				"color": Color(0.92, 0.42, 1.0, 0.32),
			})
		"scaredy_shroom":
			game.effects.append({
				"position": center,
				"radius": 96.0,
				"time": 0.32,
				"duration": 0.32,
				"color": Color(0.78, 0.48, 1.0, 0.26),
			})
		"ice_shroom":
			if float(plant["fuse_timer"]) <= 0.05:
				return false
			plant["plant_food_mode"] = "deep_freeze"
			plant["plant_food_timer"] = minf(float(plant["fuse_timer"]), 0.18)
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.18)
		"doom_shroom":
			if float(plant["fuse_timer"]) <= 0.05:
				return false
			plant["plant_food_mode"] = "doom_bloom"
			plant["plant_food_timer"] = minf(float(plant["fuse_timer"]), 0.18)
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.18)
		"moon_lotus":
			plant["plant_food_mode"] = "moon_burst"
			plant["plant_food_timer"] = 0.5
			for index in range(5):
				var angle = -1.0 + float(index) * 0.45
				var offset = Vector2(cos(angle), sin(angle)) * 34.0
				game._spawn_sun(center + offset, center.y - 20.0 + offset.y * 0.2, "plant_food")
			game._wake_all_plants()
		"prism_grass":
			plant["plant_food_mode"] = "prism_burst"
			plant["plant_food_timer"] = 0.35
			var prism_burst_range = float(Defs.PLANTS["prism_grass"]["range"]) + 120.0
			var targets = game._find_lane_targets(row, center.x, prism_burst_range, 5)
			for zombie_index in targets:
				var zombie = game.zombies[zombie_index]
				zombie = game._apply_zombie_damage(zombie, 180.0, 0.22, 0.0, true)
				game.zombies[zombie_index] = zombie
			game._damage_obstacles_in_radius(row, center.x + prism_burst_range * 0.5, prism_burst_range * 0.5, 180.0)
			game.effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(22.0, -4.0),
				"length": prism_burst_range,
				"width": 52.0,
				"radius": prism_burst_range * 0.5,
				"time": 0.26,
				"duration": 0.26,
				"color": Color(0.66, 1.0, 1.0, 0.3),
			})
		"lantern_bloom":
			plant["plant_food_mode"] = "lantern_burst"
			plant["plant_food_timer"] = 0.4
			game._damage_zombies_in_circle(center, 240.0, 120.0)
			game._wake_plants_in_radius(center, 260.0)
		"meteor_gourd":
			plant["plant_food_mode"] = "meteor_burst"
			plant["plant_food_timer"] = 0.45
			for _i in range(3):
				var impact_target = game._find_global_frontmost_target()
				if int(impact_target["row"]) == -1:
					break
				var impact = Vector2(float(impact_target["x"]) + game.rng.randf_range(-16.0, 16.0), game._row_center_y(int(impact_target["row"])))
				game._damage_zombies_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]) + 22.0, 160.0)
				game._damage_obstacles_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]) + 22.0, 160.0)
				game.effects.append({
					"position": impact,
					"radius": float(Defs.PLANTS["meteor_gourd"]["splash_radius"]) + 20.0,
					"time": 0.34,
					"duration": 0.34,
					"color": Color(1.0, 0.54, 0.2, 0.34),
				})
		"root_snare":
			plant["plant_food_mode"] = "root_burst"
			plant["plant_food_timer"] = 0.45
			var rooted_targets = game._find_closest_zombies_in_radius(center, 420.0, 5)
			if rooted_targets.is_empty():
				return false
			for zombie_index in rooted_targets:
				var zombie = game.zombies[zombie_index]
				zombie = game._apply_zombie_damage(zombie, 100.0, 0.2)
				zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer", 0.0)), 5.0)
				game.zombies[zombie_index] = zombie
		"thunder_pine":
			plant["plant_food_mode"] = "storm_burst"
			plant["plant_food_timer"] = 0.45
			for lane in game.active_rows:
				var target_index = game._find_frontmost_zombie(int(lane))
				if target_index != -1:
					game._strike_thunder_chain(target_index, 120.0, 60.0, 180.0, 3)
		"dream_drum":
			plant["plant_food_mode"] = "dream_burst"
			plant["plant_food_timer"] = 0.45
			game._wake_all_plants()
			for i in range(game.zombies.size()):
				var drum_zombie = game.zombies[i]
				if not game._is_enemy_zombie(drum_zombie):
					continue
				drum_zombie = game._apply_zombie_damage(drum_zombie, 90.0, 0.18)
				drum_zombie["special_pause_timer"] = maxf(float(drum_zombie.get("special_pause_timer", 0.0)), 1.1)
				game.zombies[i] = drum_zombie
		"wind_orchid":
			plant["plant_food_mode"] = "gust_burst"
			plant["plant_food_timer"] = 0.6
			for lane in range(game.ROWS):
				if not game._is_row_active(lane):
					continue
				var lane_center = Vector2(center.x, game._row_center_y(lane))
				for i in range(game.zombies.size()):
					var gust_zombie = game.zombies[i]
					if int(gust_zombie["row"]) != lane or not game._is_enemy_zombie(gust_zombie):
						continue
					gust_zombie["x"] += 78.0
					gust_zombie["flash"] = 0.16
					game.zombies[i] = gust_zombie
				for i in range(game.weeds.size() - 1, -1, -1):
					if int(game.weeds[i]["row"]) == lane:
						game.weeds.remove_at(i)
				for i in range(game.spears.size() - 1, -1, -1):
					if int(game.spears[i]["row"]) == lane:
						game.spears.remove_at(i)
				game.effects.append({
					"shape": "lane_spray",
					"position": lane_center + Vector2(14.0, -6.0),
					"length": game.BOARD_ORIGIN.x + game.board_size.x - lane_center.x,
					"width": game.CELL_SIZE.y * 0.76,
					"radius": game.BOARD_ORIGIN.x + game.board_size.x - lane_center.x,
					"time": 0.24,
					"duration": 0.24,
					"color": Color(0.72, 0.94, 1.0, 0.28),
				})
		"tangle_kelp":
			var kelp_targets = game._find_closest_zombies_in_radius(center, 220.0, 3)
			if kelp_targets.is_empty():
				return false
			plant["plant_food_mode"] = "kelp_frenzy"
			plant["plant_food_timer"] = 0.3
			for zombie_index in kelp_targets:
				var kelp_zombie = game.zombies[zombie_index]
				kelp_zombie = game._apply_zombie_damage(kelp_zombie, float(Defs.PLANTS["tangle_kelp"]["damage"]), 0.3, 0.0, true)
				game.zombies[zombie_index] = kelp_zombie
			plant["health"] = 0.0
		"jalapeno":
			if float(plant["fuse_timer"]) <= 0.05:
				return false
			plant["plant_food_mode"] = "inferno"
			plant["plant_food_timer"] = minf(float(plant["fuse_timer"]), 0.18)
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.18)
		"torchwood":
			plant["plant_food_mode"] = "fire_storm"
			plant["plant_food_timer"] = 2.3
			plant["plant_food_interval"] = 0.01
		"pumpkin":
			plant = game._apply_pumpkin_shell_to_plant(plant, true)
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"tallnut":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 12000.0
			plant["max_armor_health"] = 12000.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"magnet_shroom":
			plant["plant_food_mode"] = "magnet_burst"
			plant["plant_food_timer"] = 0.45
			var burst_radius = game.board_size.x + game.CELL_SIZE.x
			for i in range(game.zombies.size()):
				var zombie = game.zombies[i]
				if not game._is_enemy_zombie(zombie):
					continue
				if center.distance_to(Vector2(float(zombie["x"]), game._row_center_y(int(zombie["row"])))) > burst_radius:
					continue
				if not game._can_magnet_strip(zombie):
					continue
				zombie = game._strip_metal_from_zombie(zombie)
				game.zombies[i] = zombie
			game.effects.append({
				"position": center,
				"radius": burst_radius,
				"time": 0.3,
				"duration": 0.3,
				"color": Color(0.82, 0.72, 1.0, 0.28),
			})
		_:
			return false

	plant["flash"] = maxf(float(plant["flash"]), 0.22)
	game._set_targetable_plant(row, col, plant)
	game.effects.append({
		"position": center,
		"radius": 72.0,
		"time": 0.3,
		"duration": 0.3,
		"color": Color(0.22, 1.0, 0.34, 0.34),
	})
	game._show_toast("%s 大招启动" % Defs.PLANTS[kind]["name"])
	return true
