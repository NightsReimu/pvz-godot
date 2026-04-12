extends SceneTree

const GameScript = preload("res://scripts/game.gd")

const GACHA_PLANTS = [
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
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_every_gacha_plant_can_activate_plant_food() or failed
	failed = not _test_chaos_shroom_base_behavior_is_seed_deterministic() or failed
	failed = not _test_every_gacha_plant_has_a_live_base_behavior() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_grid() -> Array:
	var result: Array = []
	for _row in range(6):
		var row_data: Array = []
		for _col in range(9):
			row_data.append(null)
		result.append(row_data)
	return result


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "test", "terrain": "day", "events": [], "title": "test", "description": ""}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
	game.grid = _make_grid()
	game.support_grid = _make_grid()
	game.zombies = []
	game.weeds = []
	game.spears = []
	game.effects = []
	game.graves = []
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	if is_instance_valid(game.banner_label):
		game.banner_label.free()
	if is_instance_valid(game.message_label):
		game.message_label.free()
	if is_instance_valid(game.action_button):
		game.action_button.free()
	if is_instance_valid(game.message_panel):
		game.message_panel.free()
	game.free()


func _spawn_target(game: Control, row: int, col: int) -> void:
	game.call("_spawn_zombie_at", "normal", row, game.call("_cell_center", row, col).x + 84.0)


func _spawn_target_at_offset(game: Control, row: int, source_col: int, offset_x: float) -> void:
	var spawn_x = float(game.call("_cell_center", row, source_col).x) + offset_x
	game.call("_spawn_zombie_at", "normal", row, spawn_x)


func _place_damaged_ally(game: Control, row: int, col: int, kind: String = "peashooter", health_ratio: float = 0.45) -> void:
	var ally = game.call("_create_plant", kind, row, col)
	ally["health"] = maxf(1.0, float(ally["max_health"]) * health_ratio)
	game.grid[row][col] = ally


func _gacha_runtime_snapshot(game: Control) -> Dictionary:
	var zombie_health_sum := 0.0
	var rooted_total := 0.0
	var slow_total := 0.0
	var frozen_total := 0.0
	var revealed_total := 0.0
	for zombie_variant in game.zombies:
		var zombie = Dictionary(zombie_variant)
		zombie_health_sum += float(zombie.get("health", 0.0)) + float(zombie.get("shield_health", 0.0))
		rooted_total += float(zombie.get("rooted_timer", 0.0))
		slow_total += float(zombie.get("slow_timer", 0.0))
		frozen_total += float(zombie.get("frozen_timer", 0.0))
		revealed_total += float(zombie.get("revealed_timer", 0.0))
	var plant_health_sum := 0.0
	var plant_armor_sum := 0.0
	var aurora_total := 0.0
	var destiny_total := 0.0
	for row in range(game.ROWS):
		for col in range(game.COLS):
			for plant_variant in [game.grid[row][col], game.support_grid[row][col]]:
				if plant_variant == null:
					continue
				var plant = Dictionary(plant_variant)
				plant_health_sum += float(plant.get("health", 0.0))
				plant_armor_sum += float(plant.get("armor_health", 0.0))
				aurora_total += float(plant.get("aurora_buff_timer", 0.0))
				destiny_total += float(plant.get("destiny_dmg_timer", 0.0)) + float(plant.get("destiny_speed_timer", 0.0))
	return {
		"projectiles": int(game.projectiles.size()),
		"suns": int(game.suns.size()),
		"effects": int(game.effects.size()),
		"zombie_health_sum": zombie_health_sum,
		"rooted_total": rooted_total,
		"slow_total": slow_total,
		"frozen_total": frozen_total,
		"revealed_total": revealed_total,
		"plant_health_sum": plant_health_sum,
		"plant_armor_sum": plant_armor_sum,
		"aurora_total": aurora_total,
		"destiny_total": destiny_total,
	}


func _scenario_changed(kind: String, before: Dictionary, after: Dictionary) -> bool:
	match kind:
		"shadow_pea", "plasma_shooter", "phoenix_tree", "thunder_god", "prism_pea", "spiral_bamboo", "meteor_flower":
			return int(after["projectiles"]) > int(before["projectiles"]) or float(after["zombie_health_sum"]) < float(before["zombie_health_sum"])
		"ice_queen", "frost_cypress":
			return float(after["frozen_total"]) > float(before["frozen_total"]) or float(after["slow_total"]) > float(before["slow_total"])
		"vine_emperor", "chain_lotus", "abyss_tentacle", "shadow_assassin", "core_blossom", "blast_pomegranate", "thorn_cactus", "laser_lily":
			return float(after["rooted_total"]) > float(before["rooted_total"]) or float(after["zombie_health_sum"]) < float(before["zombie_health_sum"])
		"soul_flower", "galaxy_sunflower", "honey_blossom", "solar_emperor":
			return int(after["suns"]) > int(before["suns"])
		"crystal_nut", "dragon_fruit", "time_rose", "void_shroom", "magnet_daisy", "echo_fern", "plasma_shroom":
			return float(after["zombie_health_sum"]) < float(before["zombie_health_sum"]) or int(after["effects"]) > int(before["effects"]) or float(after["slow_total"]) > float(before["slow_total"])
		"chaos_shroom":
			return int(after["suns"]) > int(before["suns"]) \
				or int(after["effects"]) > int(before["effects"]) \
				or float(after["zombie_health_sum"]) < float(before["zombie_health_sum"]) \
				or float(after["slow_total"]) > float(before["slow_total"]) \
				or float(after["frozen_total"]) > float(before["frozen_total"]) \
				or float(after["plant_health_sum"]) > float(before["plant_health_sum"])
		"bubble_lotus", "rock_armor_fruit", "aurora_orchid", "destiny_tree", "holy_lotus":
			return float(after["plant_health_sum"]) > float(before["plant_health_sum"]) \
				or float(after["plant_armor_sum"]) > float(before["plant_armor_sum"]) \
				or float(after["aurora_total"]) > float(before["aurora_total"]) \
				or float(after["destiny_total"]) > float(before["destiny_total"]) \
				or int(after["effects"]) > int(before["effects"])
		"glow_ivy":
			return float(after["zombie_health_sum"]) < float(before["zombie_health_sum"]) or float(after["revealed_total"]) > float(before["revealed_total"])
		"mirror_shroom":
			return float(after["zombie_health_sum"]) < float(before["zombie_health_sum"]) or int(after["effects"]) > int(before["effects"])
		_:
			return int(after["projectiles"]) > int(before["projectiles"]) \
				or int(after["suns"]) > int(before["suns"]) \
				or int(after["effects"]) > int(before["effects"]) \
				or float(after["zombie_health_sum"]) < float(before["zombie_health_sum"]) \
				or float(after["rooted_total"]) > float(before["rooted_total"]) \
				or float(after["slow_total"]) > float(before["slow_total"]) \
				or float(after["frozen_total"]) > float(before["frozen_total"]) \
				or float(after["plant_health_sum"]) > float(before["plant_health_sum"]) \
				or float(after["plant_armor_sum"]) > float(before["plant_armor_sum"]) \
				or float(after["revealed_total"]) > float(before["revealed_total"]) \
				or float(after["aurora_total"]) > float(before["aurora_total"]) \
				or float(after["destiny_total"]) > float(before["destiny_total"])


func _configure_gacha_runtime_scenario(game: Control, kind: String, row: int, col: int) -> void:
	var center_x = float(game.call("_cell_center", row, col).x)
	match kind:
		"shadow_pea", "plasma_shooter", "crystal_nut", "dragon_fruit", "time_rose", "phoenix_tree", "thunder_god", "prism_pea", "spiral_bamboo", "laser_lily", "blast_pomegranate", "meteor_flower", "solar_emperor":
			game.call("_spawn_zombie_at", "normal", row, center_x + 96.0)
		"ice_queen", "void_shroom", "magnet_daisy", "echo_fern", "frost_cypress":
			for lane in [row - 1, row, row + 1]:
				if lane < 0 or lane >= game.ROWS:
					continue
				game.call("_spawn_zombie_at", "normal", lane, center_x + 72.0)
		"vine_emperor":
			game.call("_spawn_zombie_at", "normal", row, center_x + 68.0)
			game.call("_spawn_zombie_at", "normal", row, center_x + 110.0)
		"soul_flower", "galaxy_sunflower":
			pass
		"thorn_cactus":
			_spawn_target_at_offset(game, row, col, 42.0)
		"bubble_lotus":
			_place_damaged_ally(game, row, col + 1)
		"honey_blossom":
			_spawn_target_at_offset(game, row, col, 54.0)
		"glow_ivy":
			_spawn_target_at_offset(game, row, col, 78.0)
		"rock_armor_fruit":
			game.grid[row][col]["health"] = float(game.grid[row][col]["max_health"]) * 0.52
		"aurora_orchid", "holy_lotus":
			_place_damaged_ally(game, row, col + 1)
		"mirror_shroom":
			_place_damaged_ally(game, row, col + 1, "repeater", 1.0)
			game.call("_spawn_zombie_at", "normal", row, center_x + 110.0)
		"chain_lotus", "shadow_assassin":
			_spawn_target_at_offset(game, row, col, 66.0)
		"plasma_shroom":
			game.call("_spawn_zombie_at", "normal", row, center_x + 80.0)
		"destiny_tree":
			_place_damaged_ally(game, row, col + 1)
		"abyss_tentacle":
			_spawn_target_at_offset(game, row, col, 72.0)
		"core_blossom":
			_spawn_target_at_offset(game, row, col, 78.0)
		"chaos_shroom":
			_place_damaged_ally(game, row, col + 1)
			game.call("_spawn_zombie_at", "normal", row, center_x + 74.0)


func _drive_gacha_runtime(game: Control, kind: String) -> void:
	match kind:
		"soul_flower":
			game.call("_update_plants", 6.5)
		"galaxy_sunflower":
			game.call("_update_plants", 5.5)
		"ice_queen", "void_shroom":
			game.call("_update_plants", 3.8)
		"dragon_fruit", "thunder_god", "blast_pomegranate":
			game.call("_update_plants", 2.2)
		"laser_lily":
			game.call("_update_plants", 0.1)
			game.call("_update_plants", 2.8)
		"core_blossom":
			game.call("_update_plants", 0.1)
			game.call("_update_plants", 8.2)
		"mirror_shroom":
			game.call("_update_plants", 6.2)
		"destiny_tree":
			game.call("_update_plants", 10.2)
		"aurora_orchid":
			game.call("_update_plants", 4.2)
		"frost_cypress":
			game.call("_update_plants", 5.4)
		"plasma_shroom":
			game.call("_update_plants", 2.2)
		_:
			game.call("_update_plants", 1.9)
	game.call("_update_projectiles", 1.2)


func _test_every_gacha_plant_can_activate_plant_food() -> bool:
	var passed := true
	for kind in GACHA_PLANTS:
		var game := _make_game()
		var row := 2
		var col := 2
		var plant = game.call("_create_plant", kind, row, col)
		game.grid[row][col] = plant
		_spawn_target(game, row, col)
		var activated = bool(game.call("_activate_plant_food", row, col))
		passed = _assert_true(activated, "%s should activate a plant food power instead of failing silently" % kind) and passed
		_free_game(game)
	return passed


func _test_every_gacha_plant_has_a_live_base_behavior() -> bool:
	var passed := true
	for kind in GACHA_PLANTS:
		var game := _make_game()
		var row := 2
		var col := 2
		var plant = game.call("_create_plant", kind, row, col)
		game.grid[row][col] = plant
		_configure_gacha_runtime_scenario(game, kind, row, col)
		var before = _gacha_runtime_snapshot(game)
		_drive_gacha_runtime(game, kind)
		var after = _gacha_runtime_snapshot(game)
		passed = _assert_true(_scenario_changed(kind, before, after), "%s should produce a visible base behavior during normal plant updates" % kind) and passed
		_free_game(game)
	return passed


func _test_chaos_shroom_base_behavior_is_seed_deterministic() -> bool:
	var sequences: Array = []
	for _attempt in range(2):
		var game := _make_game()
		game.rng.seed = 424242
		var row := 2
		var col := 2
		var plant = game.call("_create_plant", "chaos_shroom", row, col)
		game.grid[row][col] = plant
		_configure_gacha_runtime_scenario(game, "chaos_shroom", row, col)
		var signature: Array = []
		for _tick in range(6):
			var before = _gacha_runtime_snapshot(game)
			game.call("_update_plants", 1.9)
			game.call("_update_projectiles", 1.2)
			var after = _gacha_runtime_snapshot(game)
			signature.append({
				"suns": int(after["suns"]) - int(before["suns"]),
				"effects": int(after["effects"]) - int(before["effects"]),
				"projectiles": int(after["projectiles"]) - int(before["projectiles"]),
				"zdelta": snappedf(float(before["zombie_health_sum"]) - float(after["zombie_health_sum"]), 0.01),
				"pdelta": snappedf(float(after["plant_health_sum"]) - float(before["plant_health_sum"]), 0.01),
				"frozen": snappedf(float(after["frozen_total"]) - float(before["frozen_total"]), 0.01),
			})
		sequences.append(signature)
		_free_game(game)
	return _assert_true(sequences[0] == sequences[1], "chaos_shroom base behavior should be reproducible under the same rng seed")
