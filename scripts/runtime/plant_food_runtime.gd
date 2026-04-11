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
	"wallnut_bowling",
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
	"heather_shooter",
	"leyline",
	"holo_nut",
	"healing_gourd",
	"mango_bowling",
	"snow_bloom",
	"cluster_boomerang",
	"glitch_walnut",
	"nether_shroom",
	"seraph_flower",
	"magma_stream",
	"orange_bloom",
	"hive_flower",
	"mamba_tree",
	"chambord_sniper",
	"dream_disc",
	"prism_pea",
	"magnet_daisy",
	"thorn_cactus",
	"bubble_lotus",
	"spiral_bamboo",
	"honey_blossom",
	"echo_fern",
	"glow_ivy",
	"laser_lily",
	"rock_armor_fruit",
	"aurora_orchid",
	"blast_pomegranate",
	"frost_cypress",
	"mirror_shroom",
	"chain_lotus",
	"plasma_shroom",
	"meteor_flower",
	"destiny_tree",
	"abyss_tentacle",
	"solar_emperor",
	"shadow_assassin",
	"core_blossom",
	"holy_lotus",
	"chaos_shroom",
	"shadow_pea",
	"ice_queen",
	"vine_emperor",
	"soul_flower",
	"plasma_shooter",
	"crystal_nut",
	"dragon_fruit",
	"time_rose",
	"galaxy_sunflower",
	"void_shroom",
	"phoenix_tree",
	"thunder_god",
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
		"heather_shooter":
			if String(plant["plant_food_mode"]) == "heather_bloom" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "heather_bloom"
			plant["plant_food_timer"] = 2.0
			plant["plant_food_interval"] = 0.01
			plant["shot_cooldown"] = 0.0
		"leyline":
			if String(plant["plant_food_mode"]) == "leyline_quake" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "leyline_quake"
			plant["plant_food_timer"] = 0.8
			plant["plant_food_interval"] = 0.0
			plant["attack_timer"] = 0.0
		"holo_nut":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 7200.0
			plant["max_armor_health"] = 7200.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"healing_gourd":
			if String(plant["plant_food_mode"]) == "gourd_burst" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "gourd_burst"
			plant["plant_food_timer"] = 0.8
			plant["plant_food_interval"] = 0.0
			plant["support_timer"] = 0.0
		"mango_bowling":
			if String(plant["plant_food_mode"]) == "mango_rush" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "mango_rush"
			plant["plant_food_timer"] = 1.5
			plant["plant_food_interval"] = 0.0
			plant["attack_timer"] = 0.0
		"snow_bloom":
			plant["plant_food_mode"] = "whiteout"
			plant["plant_food_timer"] = 0.45
			for snow_row in range(max(0, row - 1), min(game.ROWS, row + 2)):
				for snow_col in range(max(0, col - 1), min(game.COLS, col + 2)):
					if not game._is_row_active(snow_row):
						continue
					game._create_snowfield_tile(snow_row, snow_col, float(Defs.PLANTS["snow_bloom"].get("snow_duration", 10.0)) + 4.0)
			game._damage_zombies_in_circle(center, game.CELL_SIZE.x * 1.8, 90.0)
			for zombie_index in game._find_closest_zombies_in_radius(center, game.CELL_SIZE.x * 1.8, 8):
				var frost_zombie = game.zombies[zombie_index]
				frost_zombie["slow_timer"] = maxf(float(frost_zombie.get("slow_timer", 0.0)), float(Defs.PLANTS["snow_bloom"].get("freeze_duration", 2.5)) + 4.0)
				frost_zombie["special_pause_timer"] = maxf(float(frost_zombie.get("special_pause_timer", 0.0)), 0.28)
				game.zombies[zombie_index] = frost_zombie
		"cluster_boomerang":
			if String(plant["plant_food_mode"]) == "cluster_field" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "cluster_field"
			plant["plant_food_timer"] = 2.6
			plant["plant_food_interval"] = 0.0
			plant["shot_cooldown"] = 0.0
		"glitch_walnut":
			plant["plant_food_mode"] = "glitch_burst"
			plant["plant_food_timer"] = 0.35
			plant["support_timer"] = 0.0
		"nether_shroom":
			if String(plant["plant_food_mode"]) == "nether_rites" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "nether_rites"
			plant["plant_food_timer"] = 2.4
			plant["plant_food_interval"] = 0.0
			plant["support_timer"] = 0.0
		"seraph_flower":
			if String(plant["plant_food_mode"]) == "seraph_choir" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "seraph_choir"
			plant["plant_food_timer"] = 2.2
			plant["plant_food_interval"] = 0.0
			plant["shot_cooldown"] = 0.0
		"magma_stream":
			plant["plant_food_mode"] = "magma_surge"
			plant["plant_food_timer"] = 0.45
			plant["burst_done"] = false
		"orange_bloom":
			if String(plant["plant_food_mode"]) == "orange_tide" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "orange_tide"
			plant["plant_food_timer"] = 1.8
			plant["plant_food_interval"] = 0.0
			plant["attack_timer"] = 0.0
		"hive_flower":
			if String(plant["plant_food_mode"]) == "queen_swarm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "queen_swarm"
			plant["plant_food_timer"] = 1.8
			plant["plant_food_interval"] = 0.0
			plant["attack_timer"] = 0.0
		"mamba_tree":
			if String(plant["plant_food_mode"]) == "mamba_grove" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "mamba_grove"
			plant["plant_food_timer"] = 1.6
			plant["plant_food_interval"] = 0.0
			plant["support_timer"] = 0.0
		"chambord_sniper":
			if String(plant["plant_food_mode"]) == "sniper_focus" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "sniper_focus"
			plant["plant_food_timer"] = 1.6
			plant["plant_food_interval"] = 0.0
			plant["attack_timer"] = 0.0
		"dream_disc":
			plant["plant_food_mode"] = "dream_wave"
			plant["plant_food_timer"] = 0.5
			plant["plant_food_interval"] = 0.0
			plant["dream_triggered"] = false
			plant["support_timer"] = 0.0
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
			plant["plant_food_timer"] = 0.55
			var fire_zone: Vector2i = game._spawn_pepper_mortar_fire_zone(12.0, 68.0, 1, 1, row)
			game.effects.append({
				"position": game._cell_center(fire_zone.x, fire_zone.y),
				"radius": game.CELL_SIZE.x * 1.45,
				"time": 0.44,
				"duration": 0.44,
				"color": Color(1.0, 0.42, 0.16, 0.42),
			})
		"cactus_guard":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 4200.0
			plant["max_armor_health"] = 4200.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"pulse_bulb":
			plant["plant_food_mode"] = "pulse_burst"
			plant["plant_food_timer"] = 0.5
			game._apply_pulse_bulb_push_zone(row, col, 2, 92.0, 0.55, 2.4)
			game.effects.append({
				"shape": "pulse_bulb_wave",
				"position": center,
				"radius": game.CELL_SIZE.x * 2.85,
				"time": 0.42,
				"duration": 0.42,
				"color": Color(0.9, 0.98, 1.0, 0.46),
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
			var fume_range = float(Defs.PLANTS["fume_shroom"]["range"]) + game.CELL_SIZE.x + 70.0
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
				var impact_target = game._find_global_rearmost_target()
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
		"shadow_pea":
			var shadow_range = 680.0
			var shadow_targets = game._find_lane_targets(row, center.x, shadow_range, 6)
			plant["plant_food_mode"] = "shadow_burst"
			plant["plant_food_timer"] = 0.35
			for zombie_index in shadow_targets:
				var shadow_zombie = game.zombies[zombie_index]
				shadow_zombie = game._apply_zombie_damage(shadow_zombie, 140.0, 0.22, 2.4)
				game.zombies[zombie_index] = shadow_zombie
			game._damage_obstacles_in_radius(row, center.x + shadow_range * 0.5, shadow_range * 0.5, 140.0)
			game.effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(18.0, -8.0),
				"length": shadow_range,
				"width": 68.0,
				"radius": shadow_range * 0.5,
				"time": 0.3,
				"duration": 0.3,
				"color": Color(0.44, 0.24, 0.72, 0.34),
			})
		"ice_queen":
			var freeze_radius = float(Defs.PLANTS["ice_queen"].get("radius", 160.0)) + 80.0
			for i in range(game.zombies.size()):
				var ice_zombie = game.zombies[i]
				if not game._is_enemy_zombie(ice_zombie):
					continue
				var ice_pos = Vector2(float(ice_zombie["x"]), game._row_center_y(int(ice_zombie["row"])))
				if ice_pos.distance_to(center) > freeze_radius:
					continue
				ice_zombie = game._apply_zombie_damage(ice_zombie, 110.0, 0.22, 8.0)
				ice_zombie["frozen_timer"] = maxf(float(ice_zombie.get("frozen_timer", 0.0)), float(Defs.PLANTS["ice_queen"].get("freeze_duration", 2.0)) + 1.2)
				game.zombies[i] = ice_zombie
			plant["plant_food_mode"] = "absolute_zero"
			plant["plant_food_timer"] = 0.4
			game.effects.append({
				"position": center,
				"radius": freeze_radius,
				"time": 0.36,
				"duration": 0.36,
				"color": Color(0.7, 0.94, 1.0, 0.4),
			})
		"vine_emperor":
			var vine_targets = game._find_closest_zombies_in_radius(center, 300.0, 6)
			plant["plant_food_mode"] = "thorn_cage"
			plant["plant_food_timer"] = 0.45
			for zombie_index in vine_targets:
				var vine_zombie = game.zombies[zombie_index]
				vine_zombie = game._apply_zombie_damage(vine_zombie, 120.0, 0.22)
				vine_zombie["rooted_timer"] = maxf(float(vine_zombie.get("rooted_timer", 0.0)), 4.8)
				game.zombies[zombie_index] = vine_zombie
			game.effects.append({
				"position": center,
				"radius": 300.0,
				"time": 0.34,
				"duration": 0.34,
				"color": Color(0.34, 0.96, 0.42, 0.28),
			})
		"soul_flower":
			plant["plant_food_mode"] = "soul_harvest"
			plant["plant_food_timer"] = 0.5
			for index in range(6):
				var angle = -1.2 + float(index) * 0.48
				var offset = Vector2(cos(angle), sin(angle)) * 36.0
				game._spawn_sun(center + offset, center.y - 22.0 + offset.y * 0.2, "plant_food")
			game._damage_zombies_in_circle(center + Vector2(50.0, 0.0), 140.0, 90.0)
			game.effects.append({
				"position": center,
				"radius": 120.0,
				"time": 0.34,
				"duration": 0.34,
				"color": Color(0.82, 0.56, 1.0, 0.28),
			})
		"plasma_shooter":
			var plasma_target = game._find_frontmost_zombie(row)
			plant["plant_food_mode"] = "ion_burst"
			plant["plant_food_timer"] = 0.3
			if plasma_target != -1:
				game._strike_thunder_chain(plasma_target, float(Defs.PLANTS["plasma_shooter"].get("ultimate_damage", 200.0)), 90.0, 180.0, 5)
			game.effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(18.0, -10.0),
				"length": 720.0,
				"width": 58.0,
				"radius": 360.0,
				"time": 0.24,
				"duration": 0.24,
				"color": Color(0.46, 0.92, 1.0, 0.36),
			})
		"crystal_nut":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 14000.0
			plant["max_armor_health"] = 14000.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"dragon_fruit":
			plant["plant_food_mode"] = "dragon_breath"
			plant["plant_food_timer"] = 0.4
			var cone_range = float(Defs.PLANTS["dragon_fruit"].get("cone_range", 180.0)) + 60.0
			for lane in range(max(0, row - 1), min(game.ROWS, row + 2)):
				game._damage_zombies_in_row_segment(lane, center.x - 20.0, center.x + cone_range, 130.0, 4.0)
				game._damage_obstacles_in_radius(lane, center.x + cone_range * 0.5, cone_range * 0.5, 130.0)
			game.effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(16.0, -12.0),
				"length": cone_range,
				"width": 136.0,
				"radius": cone_range * 0.5,
				"time": 0.28,
				"duration": 0.28,
				"color": Color(1.0, 0.44, 0.18, 0.34),
			})
		"time_rose":
			for i in range(game.zombies.size()):
				var time_zombie = game.zombies[i]
				if not game._is_enemy_zombie(time_zombie):
					continue
				time_zombie["special_pause_timer"] = maxf(float(time_zombie.get("special_pause_timer", 0.0)), 3.2)
				time_zombie["slow_timer"] = maxf(float(time_zombie.get("slow_timer", 0.0)), 8.0)
				time_zombie["flash"] = maxf(float(time_zombie.get("flash", 0.0)), 0.18)
				game.zombies[i] = time_zombie
			plant["plant_food_mode"] = "time_stop"
			plant["plant_food_timer"] = 0.45
			game.effects.append({
				"position": center,
				"radius": game.board_size.x,
				"time": 0.4,
				"duration": 0.4,
				"color": Color(1.0, 0.74, 0.86, 0.26),
			})
		"galaxy_sunflower":
			plant["plant_food_mode"] = "supernova"
			plant["plant_food_timer"] = 0.5
			for index in range(8):
				var angle = TAU * float(index) / 8.0
				var offset = Vector2(cos(angle), sin(angle)) * 42.0
				game._spawn_sun(center + offset, center.y - 26.0 + offset.y * 0.15, "plant_food")
			game.effects.append({
				"position": center,
				"radius": 150.0,
				"time": 0.4,
				"duration": 0.4,
				"color": Color(1.0, 0.9, 0.4, 0.36),
			})
		"void_shroom":
			var void_radius = float(Defs.PLANTS["void_shroom"].get("pull_radius", 140.0)) + 100.0
			for i in range(game.zombies.size()):
				var void_zombie = game.zombies[i]
				if not game._is_enemy_zombie(void_zombie):
					continue
				var void_pos = Vector2(float(void_zombie["x"]), game._row_center_y(int(void_zombie["row"])))
				var distance = void_pos.distance_to(center)
				if distance > void_radius:
					continue
				void_zombie = game._apply_zombie_damage(void_zombie, 150.0, 0.22)
				var pull_delta = clampf((float(void_zombie["x"]) - center.x) * 0.45, -90.0, 90.0)
				void_zombie["x"] -= pull_delta
				game.zombies[i] = void_zombie
			plant["plant_food_mode"] = "void_swallow"
			plant["plant_food_timer"] = 0.42
			game.effects.append({
				"position": center,
				"radius": void_radius,
				"time": 0.38,
				"duration": 0.38,
				"color": Color(0.5, 0.24, 0.76, 0.32),
			})
		"phoenix_tree":
			var phoenix_target = game._find_global_frontmost_target()
			var phoenix_radius = float(Defs.PLANTS["phoenix_tree"].get("ultimate_radius", 200.0))
			var phoenix_impact = center + Vector2(120.0, -12.0)
			if int(phoenix_target["row"]) != -1:
				phoenix_impact = Vector2(float(phoenix_target["x"]), game._row_center_y(int(phoenix_target["row"])))
			plant["plant_food_mode"] = "rebirth_flare"
			plant["plant_food_timer"] = 0.4
			game._damage_zombies_in_circle(phoenix_impact, phoenix_radius, 260.0)
			game._damage_obstacles_in_circle(phoenix_impact, phoenix_radius, 260.0)
			game.effects.append({
				"position": phoenix_impact,
				"radius": phoenix_radius,
				"time": 0.36,
				"duration": 0.36,
				"color": Color(1.0, 0.56, 0.16, 0.38),
			})
		"thunder_god":
			for lane in game.active_rows:
				var thunder_target = game._find_frontmost_zombie(int(lane))
				if thunder_target == -1:
					continue
				game._strike_thunder_chain(thunder_target, float(Defs.PLANTS["thunder_god"].get("ultimate_damage", 500.0)), 140.0, 220.0, 5)
			plant["plant_food_mode"] = "thunderstorm"
			plant["plant_food_timer"] = 0.35
			game.effects.append({
				"position": center,
				"radius": game.board_size.x,
				"time": 0.3,
				"duration": 0.3,
				"color": Color(1.0, 0.96, 0.48, 0.3),
			})
		# ==================== NEW PURPLE PLANT FOOD ====================
		"prism_pea":
			plant["plant_food_mode"] = "pea_storm"
			plant["plant_food_timer"] = 2.0
			plant["plant_food_interval"] = 0.12
			plant["prism_storm"] = true
		"magnet_daisy":
			var d = Defs.PLANTS["magnet_daisy"]
			for i in range(game.zombies.size()):
				var zombie = game.zombies[i]
				if not game._is_enemy_zombie(zombie):
					continue
				zombie["x"] += (center.x - float(zombie["x"])) * 0.45
				zombie = game._apply_zombie_slow(zombie, 0.5, 4.0)
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer",0.0)), 3.0)
				game.zombies[i] = zombie
			game.effects.append({"position": center, "radius": 300.0, "time": 0.4, "duration": 0.4, "color": Color(0.54, 0.82, 1.0, 0.32)})
		"thorn_cactus":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 3000.0
			plant["max_armor_health"] = 3000.0
			game._damage_zombies_in_circle(center, 200.0, 180.0)
			game.effects.append({"position": center, "radius": 200.0, "time": 0.3, "duration": 0.3, "color": Color(0.52, 0.86, 0.32, 0.3)})
		"bubble_lotus":
			for r in range(game.ROWS):
				for c in range(game.COLS):
					var p = game._top_plant_at(r, c)
					if p != null:
						p["armor_health"] = maxf(float(p.get("armor_health",0.0)), 800.0)
						p["max_armor_health"] = maxf(float(p.get("max_armor_health",0.0)), 800.0)
						game.grid[r][c] = p
			game.effects.append({"position": center, "radius": 400.0, "time": 0.36, "duration": 0.36, "color": Color(0.52, 0.9, 1.0, 0.24)})
		"spiral_bamboo":
			plant["plant_food_mode"] = "pea_storm"
			plant["plant_food_timer"] = 2.2
			plant["plant_food_interval"] = 0.15
			plant["spiral_storm"] = true
		"honey_blossom":
			for i in range(4):
				var angle = TAU * float(i) / 4.0
				game._spawn_sun(center + Vector2(cos(angle), sin(angle)) * 30.0, center.y - 24.0, "plant_food", 50)
			for r in range(game.active_rows.size()):
				var lane = int(game.active_rows[r])
				for i2 in range(game.zombies.size()):
					var zombie = game.zombies[i2]
					if not game._is_enemy_zombie(zombie) or int(zombie["row"]) != lane:
						continue
					game.zombies[i2] = game._apply_zombie_slow(zombie, 0.5, 8.0)
			game.effects.append({"position": center, "radius": 280.0, "time": 0.34, "duration": 0.34, "color": Color(1.0, 0.84, 0.22, 0.3)})
		"echo_fern":
			for _pulse in range(5):
				for zombie_index in game._find_closest_zombies_in_radius(center, 180.0, 8):
					var zombie = game.zombies[zombie_index]
					zombie = game._apply_zombie_damage(zombie, float(Defs.PLANTS["echo_fern"]["damage"]) * 1.3, 0.1, 0.0)
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer",0.0)), 0.4)
					game.zombies[zombie_index] = zombie
			game.effects.append({"position": center, "radius": 180.0, "time": 0.4, "duration": 0.4, "color": Color(0.52, 1.0, 0.78, 0.3)})
		"glow_ivy":
			for lane in game.active_rows:
				game._damage_zombies_in_row_segment(int(lane), game.BOARD_ORIGIN.x, game.BOARD_ORIGIN.x + game.board_size.x + 20.0, 30.0, 0.0)
				for i in range(game.zombies.size()):
					if int(game.zombies[i].get("row",-1)) == int(lane):
						game.zombies[i]["revealed_timer"] = maxf(float(game.zombies[i].get("revealed_timer",0.0)), 6.0)
			game.effects.append({"position": center, "radius": game.board_size.x, "time": 0.34, "duration": 0.34, "color": Color(0.72, 1.0, 0.56, 0.22)})
		# ==================== NEW ORANGE PLANT FOOD ====================
		"laser_lily":
			for lane in game.active_rows:
				var lane_center = Vector2(center.x, game._row_center_y(int(lane)))
				game._damage_zombies_in_row_segment(int(lane), center.x + 8.0, game.BOARD_ORIGIN.x + game.board_size.x + 20.0, 200.0, 0.0)
				game.effects.append({"shape": "lane_spray", "position": lane_center + Vector2(14.0, -6.0), "length": game.board_size.x, "width": 38.0, "radius": game.board_size.x * 0.5, "time": 0.8, "duration": 0.8, "color": Color(1.0, 0.22, 0.34, 0.32)})
		"rock_armor_fruit":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = float(Defs.PLANTS["rock_armor_fruit"]["layer_hp"]) * float(Defs.PLANTS["rock_armor_fruit"]["armor_layers"])
			plant["max_armor_health"] = plant["armor_health"]
			plant["armor_layer"] = 3
			game._damage_zombies_in_circle(center, 200.0, float(Defs.PLANTS["rock_armor_fruit"]["shockwave_damage"]) * 2.0)
			game.effects.append({"position": center, "radius": 200.0, "time": 0.34, "duration": 0.34, "color": Color(0.82, 0.64, 0.38, 0.36)})
		"aurora_orchid":
			for r in range(game.ROWS):
				for c in range(game.COLS):
					var p = game._top_plant_at(r, c)
					if p != null:
						p["aurora_buff_timer"] = 8.0
						p["aurora_buff_ratio"] = 0.5
						p["health"] = minf(float(p["health"]) + 300.0, float(p.get("max_health",120.0)))
						game.grid[r][c] = p
			game.effects.append({"position": center, "radius": 400.0, "time": 0.4, "duration": 0.4, "color": Color(0.56, 0.9, 1.0, 0.28)})
		"blast_pomegranate":
			for _volley in range(3):
				var t_i = game._find_frontmost_zombie(row)
				if t_i >= 0:
					var tz = game.zombies[t_i]
					var impact = Vector2(float(tz["x"]), game._row_center_y(int(tz["row"])) - 8.0)
					game._damage_zombies_in_circle(impact, 90.0, 80.0)
					for i in range(8):
						var angle = TAU * float(i) / 8.0
						var spread = impact + Vector2(cos(angle), sin(angle)) * (50.0 + randf() * 30.0)
						game._damage_zombies_in_circle(spread, 50.0, 50.0)
						game.effects.append({"position": spread, "radius": 50.0, "time": 0.18, "duration": 0.18, "color": Color(1.0, 0.36, 0.22, 0.28)})
		"frost_cypress":
			for i in range(game.zombies.size()):
				var zombie = game.zombies[i]
				if not game._is_enemy_zombie(zombie):
					continue
				zombie["frozen_timer"] = maxf(float(zombie.get("frozen_timer",0.0)), 3.0)
				game.zombies[i] = zombie
			game.effects.append({"position": center, "radius": game.board_size.x, "time": 0.4, "duration": 0.4, "color": Color(0.72, 0.96, 1.0, 0.32)})
		"mirror_shroom":
			for r in range(game.ROWS):
				for c in range(game.COLS):
					var p = game._top_plant_at(r, c)
					if p == null or String(p.get("kind","")) == "mirror_shroom":
						continue
					var pd = Defs.PLANTS.get(String(p["kind"]), {})
					var pdmg = float(pd.get("damage", float(pd.get("zone_damage", 0.0))))
					if pdmg > 0.0:
						game._damage_zombies_in_row_segment(r, game._cell_center(r,c).x, game.BOARD_ORIGIN.x + game.board_size.x + 20.0, pdmg * float(Defs.PLANTS["mirror_shroom"]["clone_damage_ratio"]) * 1.5, 0.0)
			game.effects.append({"position": center, "radius": 350.0, "time": 0.36, "duration": 0.36, "color": Color(0.88, 0.88, 1.0, 0.28)})
		"chain_lotus":
			for _hit in range(3):
				for i in range(game.zombies.size()):
					var zombie = game.zombies[i]
					if not game._is_enemy_zombie(zombie):
						continue
					game.zombies[i] = game._apply_zombie_damage(zombie, float(Defs.PLANTS["chain_lotus"]["damage"]), 0.12, 0.0)
			game.effects.append({"position": center, "radius": 280.0, "time": 0.34, "duration": 0.34, "color": Color(0.36, 0.88, 0.72, 0.3)})
		"plasma_shroom":
			for i in range(5):
				var angle = TAU * float(i) / 5.0
				var spread = center + Vector2(cos(angle), sin(angle)) * 100.0
				game.effects.append({"shape": "plasma_zone", "position": spread, "radius": 140.0, "time": 8.0, "duration": 8.0, "color": Color(0.36, 0.72, 1.0, 0.2), "dps": float(Defs.PLANTS["plasma_shroom"]["zone_damage"]) * 1.5})
			game.effects.append({"position": center, "radius": 260.0, "time": 0.32, "duration": 0.32, "color": Color(0.36, 0.72, 1.0, 0.3)})
		# ==================== NEW GOLD PLANT FOOD ====================
		"meteor_flower":
			for i in range(6):
				var angle = TAU * float(i) / 6.0
				var t_row = clampi(row + (randi() % 3) - 1, 0, game.ROWS - 1)
				game._spawn_projectile(t_row, center + Vector2(cos(angle) * 16.0, sin(angle) * 16.0), Color(1.0, 0.48, 0.18), 100.0, 0.0, 520.0, 10.0)
			game.effects.append({"position": center, "radius": 160.0, "time": 0.34, "duration": 0.34, "color": Color(1.0, 0.56, 0.22, 0.3)})
		"destiny_tree":
			for r in range(game.ROWS):
				for c in range(game.COLS):
					var p = game._top_plant_at(r, c)
					if p != null:
						p["health"] = float(p.get("max_health", 120.0))
						p["destiny_dmg_timer"] = 12.0
						p["destiny_speed_timer"] = 12.0
						p["destiny_dmg_ratio"] = 0.5
						game.grid[r][c] = p
			game.effects.append({"position": center, "radius": 400.0, "time": 0.44, "duration": 0.44, "color": Color(1.0, 0.9, 0.46, 0.28)})
		"abyss_tentacle":
			for zombie_index in game._find_closest_zombies_in_radius(center, 300.0, 3):
				var zombie = game.zombies[zombie_index]
				zombie = game._apply_zombie_damage(zombie, 200.0, 0.22, 0.0)
				zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer",0.0)), 4.0)
				game.zombies[zombie_index] = zombie
			game.effects.append({"position": center, "radius": 300.0, "time": 0.36, "duration": 0.36, "color": Color(0.28, 0.08, 0.44, 0.38)})
		"solar_emperor":
			for i in range(6):
				var angle = TAU * float(i) / 6.0
				game._spawn_sun(center + Vector2(cos(angle), sin(angle)) * 32.0, center.y - 26.0, "plant_food", 150)
			for lane in game.active_rows:
				game._damage_zombies_in_row_segment(int(lane), center.x + 10.0, game.BOARD_ORIGIN.x + game.board_size.x + 20.0, 150.0, 0.0)
			game.effects.append({"position": center, "radius": 250.0, "time": 0.38, "duration": 0.38, "color": Color(1.0, 0.9, 0.36, 0.3)})
		"shadow_assassin":
			for _strike in range(3):
				var best_i := -1
				var best_hp := -1.0
				for i in range(game.zombies.size()):
					var zombie = game.zombies[i]
					if not game._is_enemy_zombie(zombie) and float(zombie["health"]) > best_hp:
						best_hp = float(zombie["health"])
						best_i = i
				if best_i >= 0:
					game.zombies[best_i] = game._apply_zombie_damage(game.zombies[best_i], 200.0, 0.2, 0.0)
					game.effects.append({"position": Vector2(float(game.zombies[best_i]["x"]), game._row_center_y(int(game.zombies[best_i]["row"]))), "radius": 50.0, "time": 0.18, "duration": 0.18, "color": Color(0.22, 0.08, 0.36, 0.44)})
		"core_blossom":
			game._damage_zombies_in_circle(center, float(Defs.PLANTS["core_blossom"]["radius"]) * 1.25, 600.0)
			game._damage_obstacles_in_circle(center, float(Defs.PLANTS["core_blossom"]["radius"]) * 1.25, 600.0)
			game.effects.append({"position": center, "radius": float(Defs.PLANTS["core_blossom"]["radius"]) * 1.25, "time": 0.44, "duration": 0.44, "color": Color(1.0, 0.48, 0.16, 0.44)})
			plant["core_state"] = "recharging"
			plant["charge_timer"] = 3.0
		"holy_lotus":
			for r in range(game.ROWS):
				for c in range(game.COLS):
					var p = game._top_plant_at(r, c)
					if p != null:
						p["health"] = float(p.get("max_health", 120.0))
						p["holy_invincible_timer"] = 3.0
						game.grid[r][c] = p
			game._damage_zombies_in_circle(center, game.board_size.x, 300.0)
			game.effects.append({"position": center, "radius": 400.0, "time": 0.44, "duration": 0.44, "color": Color(1.0, 0.98, 0.78, 0.3)})
		"chaos_shroom":
			for _i in range(3):
				var rng = RandomNumberGenerator.new()
				rng.randomize()
				var et = rng.randi() % 5
				match et:
					0: game._damage_zombies_in_circle(center, 250.0, 150.0)
					1:
						for _s in range(2):
							game._spawn_sun(center + Vector2(randf_range(-30.0,30.0), -20.0), center.y - 30.0, "plant_food", 100)
					2:
						for zi in game._find_closest_zombies_in_radius(center, 220.0, 5):
							game.zombies[zi]["frozen_timer"] = maxf(float(game.zombies[zi].get("frozen_timer",0.0)), 3.0)
					3:
						for r in range(game.ROWS):
							for c2 in range(game.COLS):
								var p = game._top_plant_at(r, c2)
								if p != null:
									p["health"] = minf(float(p["health"]) + 200.0, float(p.get("max_health",120.0)))
									game.grid[r][c2] = p
					4:
						for _sp in range(10):
							var sp_row = clampi(row + (rng.randi() % 3) - 1, 0, game.ROWS - 1)
							game._spawn_projectile(sp_row, center + Vector2(randf_range(-10.0,10.0), -8.0), Color(0.7, 0.3, 0.9), 60.0, 0.0, 460.0, 7.0)
			game.effects.append({"position": center, "radius": 300.0, "time": 0.44, "duration": 0.44, "color": Color(0.8, 0.4, 1.0, 0.3)})
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
