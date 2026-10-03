extends SceneTree

const Game = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_zombie_defs.gd")
const Gear = preload("res://scripts/runtime/zombie_equipment.gd")
const Almanac = preload("res://scripts/data/almanac_text.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func make_game() -> Control:
	var game := Game.new()
	game.size = Vector2(1600, 900)
	game.current_level = {"id":"1-test", "terrain":"day", "events":[]}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(882, 550)
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	for row in range(6):
		var cells: Array = []; cells.resize(9)
		game.grid.append(cells); game.support_grid.append(cells.duplicate())
	return game

func release_game(game: Control) -> void:
	game.save_dirty = false
	game.toast_label.free(); game.banner_label.free(); game.free()

func spawn(game: Control, id: String) -> Dictionary:
	game.zombies.clear(); game.effects.clear(); game.projectiles.clear()
	game.current_level = {"id":"1-test", "terrain":"day", "events":[]}
	game.water_rows = []
	if game._is_water_zombie_kind(id):
		game.current_level.terrain = "pool"; game.water_rows = [2, 3]
	game._spawn_zombie_at(id, 2, game._cell_center(2, 3).x)
	check(not game.zombies.is_empty(), "Spawn must succeed: " + id)
	return game.zombies[0] if not game.zombies.is_empty() else {}

func _native_fume_regression(game: Control) -> void:
	for kind in ["conehead", "buckethead", "football", "dark_football", "lifebuoy_cone", "lifebuoy_bucket"]:
		game.zombies.clear()
		game.current_level.terrain = "pool" if kind.begins_with("lifebuoy") else "day"
		game.water_rows = [2, 3] if kind.begins_with("lifebuoy") else []
		game._spawn_zombie_at(kind, 2, game._cell_center(2, 3).x)
		var hp: float = game.zombies[0].health
		var armor: float = game.zombies[0].shield_health
		var plant: Dictionary = game._create_plant("fume_shroom", 2, 2)
		plant.attack_timer = 0.0
		game._ensure_plant_runtime().update_fume_shroom(plant, 0.02, 2, 2)
		check(is_equal_approx(game.zombies[0].health, hp), "Fume must preserve body behind headgear: " + kind)
		check(game.zombies[0].shield_health < armor, "Fume must damage headgear: " + kind)

func _catalogue_and_layers(game: Control) -> void:
	check(Fusion.RECIPES.size() >= 150, "Catalogue must cover more than the three example zombies")
	for id in Fusion.RECIPES:
		var recipe: Dictionary = Fusion.RECIPES[id]
		check(Defs.ZOMBIES.has(id), "Missing fusion definition: " + id)
		check(Almanac.zombie_lines(id).size() >= 3, "Fusion almanac must explain its equipment: " + id)
		var z := spawn(game, id)
		if z.is_empty(): continue
		check(String(z.kind) == String(recipe.base) and String(z.fusion_kind) == id, "Keep base behavior and catalogue identity: " + id)
		var body := float(z.health)
		var outer: Dictionary = Gear.layers(z)[0]
		var before := float(z[outer.field])
		z = game._apply_zombie_damage(z, 7)
		check(is_equal_approx(z.health, body) and z[outer.field] < before, "Ordinary hits damage the outer layer: " + id)
		z = spawn(game, id)
		var layers := Gear.layers(z)
		var head: Dictionary = {}
		for layer in layers:
			if layer.slot == "headgear": head = layer; break
		z = game._apply_zombie_damage(z, 9, 0, 0, false, true)
		for layer in layers:
			if layer.slot == "handheld":
				check(is_equal_approx(z[layer.field], z[layer.max_field]), "Piercing must preserve held equipment: " + id)
		if not head.is_empty():
			check(is_equal_approx(z.health, body) and z[head.field] < z[head.max_field], "Piercing still damages headgear: " + id)
		else:
			check(is_equal_approx(z.health, body - 9), "Piercing hits the unhelmeted body: " + id)
	check(Gear.bar_color("headgear") != Gear.bar_color("handheld"), "Head and hand bars must use distinct colors")
	for id in ["cone_screen_door", "football_screen_door", "cone_ninja", "bucket_ninja_door", "football_pole_vault", "bucket_snorkel", "bucket_wizard_zombie"]:
		check(Fusion.RECIPES.has(id), "Requested/diverse fusion is missing: " + id)

func _overflow_and_direction(game: Control) -> void:
	var z := spawn(game, "cone_screen_door")
	var body := float(z.health)
	z = game._apply_zombie_damage(z, 1100 + 170 + 20)
	check(z.handheld_health == 0 and z.shield_health == 0 and is_equal_approx(z.health, body - 20), "Overflow crosses all layers exactly once")
	z = spawn(game, "cone_screen_door")
	z = game._apply_zombie_damage(z, 170 + 20, 0, 0, false, true)
	check(z.handheld_health == 1100 and z.shield_health == 0 and is_equal_approx(z.health, body - 20), "Piercing overflow leaves the door untouched")
	for hypnotized in [false, true]:
		z = spawn(game, "cone_screen_door"); z.hypnotized = hypnotized
		var front := float(z.x) + (20 if hypnotized else -20)
		var rear := float(z.x) - (20 if hypnotized else -20)
		var hit: Dictionary = game._apply_zombie_damage(z.duplicate(true), 10, 0, 0, false, false, front)
		check(hit.handheld_health == 1090 and hit.shield_health == 170, "Front attacks must hit the door with either facing")
		hit = game._apply_zombie_damage(z.duplicate(true), 10, 0, 0, false, false, rear)
		check(hit.handheld_health == 1100 and hit.shield_health == 160 and hit.health == body, "Rear attacks skip the door but still meet the helmet")
	z = spawn(game, "bucket_ninja_door")
	game.current_level.id = "无尽"; game.endless_bonus_levels = {"shield_break":2}
	var mult: float = game._endless_shield_damage_mult()
	body = z.health
	z = game._apply_zombie_damage(z, (1100 + 900) / mult + 20)
	check(is_equal_approx(z.health, body - 20), "Armor bonus cannot multiply overflow body damage")

func _real_attacks(game: Control) -> void:
	for attack in ["pea", "piercing_pea", "boomerang", "fume", "fume_food", "fume_click", "prism_click", "laser", "mirror", "mirror_food", "gator_beam", "laser_food", "solar_food", "plasma_shroom_food", "dragon_food", "echo_food"]:
		var z := spawn(game, "bucket_ninja_door")
		var body := float(z.health)
		var plant: Dictionary = game._create_plant("fume_shroom", 2, 2)
		if attack in ["pea", "piercing_pea"]:
			game._spawn_projectile(2, Vector2(z.x - 20, game._row_center_y(2) - 10), Color.GREEN, 20, 0)
			if attack == "piercing_pea": game.projectiles[0].pierce_left = 2
			game._update_projectiles(0.06)
		elif attack == "boomerang":
			game._spawn_boomerang_projectile(2, Vector2(z.x - 24, game._row_center_y(2) - 10), z.x - 100, 20, 3)
			for _step in range(5): game._update_projectiles(0.03)
		elif attack == "fume":
			plant.attack_timer = 0
			game._ensure_plant_runtime().update_fume_shroom(plant, 0.02, 2, 2)
		elif attack == "fume_food":
			game.grid[2][2] = plant
			game._ensure_plant_food_runtime().activate(2, 2)
			game.grid[2][2] = null
		elif attack in ["fume_click", "prism_click"]:
			var kind := "fume_shroom" if attack == "fume_click" else "prism_grass"
			plant = game._create_plant(kind, 2, 2)
			game.grid[2][2] = plant
			game._execute_ultimate(plant, kind, 2, 2, game._ultimate_profile_for_kind(kind))
			game.grid[2][2] = null
		elif attack == "laser":
			plant = game._create_plant("laser_lily", 2, 2)
			plant.laser_state = "charging"; plant.charge_timer = 0
			game._ensure_plant_runtime().update_laser_lily(plant, 0.02, 2, 2)
		elif attack == "mirror":
			plant = game._create_plant("mirror_shroom", 2, 2)
			plant.shot_cooldown = 0
			game._ensure_plant_runtime().update_mirror_shroom(plant, 0.02, 2, 2)
		elif attack == "mirror_food":
			game.grid[2][2] = game._create_plant("mirror_shroom", 2, 2)
			game.grid[2][1] = game._create_plant("peashooter", 2, 1)
			game._ensure_plant_food_runtime().activate(2, 2)
			game.grid[2][2] = null; game.grid[2][1] = null
		elif attack == "gator_beam":
			game._execute_volcano_gator_cannon_ultimate(2, 2)
		else:
			var kind: String = {"laser_food":"laser_lily", "solar_food":"solar_emperor", "plasma_shroom_food":"plasma_shroom", "dragon_food":"dragon_fruit", "echo_food":"echo_fern"}[attack]
			game.grid[2][2] = game._create_plant(kind, 2, 2)
			game._ensure_plant_food_runtime().activate(2, 2)
			game.grid[2][2] = null
		z = game.zombies[0]
		check(z.health == body, "Real attack cannot bypass the bucket: " + attack)
		if attack == "pea":
			check(z.handheld_health < 1100 and z.headgear_health == 900, "Pea crossing the body center must still hit the front door")
		else:
			check(z.handheld_health == 1100 and z.headgear_health < 900, "Real piercing attack damages headgear only: " + attack)
	# The last target remains a piercing hit when the extra-hit counter reaches 0.
	spawn(game, "normal")
	var x: float = game.zombies[0].x
	game._spawn_zombie_at("cone_screen_door", 2, x + 100)
	game._spawn_projectile(2, Vector2(x - 20, game._row_center_y(2) - 10), Color.GREEN, 20, 0)
	game.projectiles[0].pierce_left = 1
	for _step in range(12): game._update_projectiles(0.03)
	check(game.zombies[1].handheld_health == 1100 and game.zombies[1].shield_health == 150, "The final piercing hit still bypasses handheld armor")
	var plasma := spawn(game, "dark_football_ninja_door")
	game.grid[2][2] = game._create_plant("plasma_shooter", 2, 2)
	game._ensure_plant_food_runtime().activate(2, 2)
	game.grid[2][2] = null
	check(game.zombies[0].health == plasma.max_health and game.zombies[0].handheld_health == 1100 and game.zombies[0].headgear_health == 682, "The plasma ultimate pierces the door but consumes 2000 helmet durability")

func _magnet_and_break_reactions(game: Control) -> void:
	var runtime = game._ensure_plant_runtime()
	var z := spawn(game, "bucket_ninja_door")
	z = runtime.strip_metal_from_zombie(z)
	check(z.handheld_health == 0 and z.headgear_health == 900, "Magnet removes the outer door first")
	z = runtime.strip_metal_from_zombie(z)
	check(z.headgear_health == 0 and not runtime.can_magnet_strip(z), "Next magnet removes the bucket")
	z = spawn(game, "cone_ninja")
	check(not runtime.can_magnet_strip(z), "A plastic cone is not magnetic")
	z = spawn(game, "bucket_pogo_zombie")
	z = runtime.strip_metal_from_zombie(z)
	check(z.headgear_health == 0 and z.pogo_active, "Removing a bucket preserves the pogo stick")
	z = runtime.strip_metal_from_zombie(z)
	check(not z.pogo_active, "A later magnet removes the pogo stick")
	z = spawn(game, "bucket_newspaper")
	z = game._apply_zombie_damage(z, 150)
	check(z.enraged and z.headgear_health == 900 and z.health == z.max_health, "Breaking paper triggers rage while the bucket stays")
	z = spawn(game, "cone_basketball")
	z = game._apply_zombie_damage(z, 220)
	check(z.shield_regen_timer > 0 and z.headgear_health == 170, "Basketball regrowth retains added headgear")

func _roles_and_endless(game: Control) -> void:
	var z := spawn(game, "cone_ninja")
	z.health = z.max_health * 0.45; game.zombies[0] = z
	game._update_zombies(0.01)
	check(game.zombies[0].ninja_dashed and game.zombies[0].jumping and game.zombies[0].headgear_health == 170, "Armored ninja retains the actual dash and lane jump")
	z = spawn(game, "football_pole_vault")
	game.grid[2][2] = game._create_plant("wallnut", 2, 2)
	game.zombies[0].x = game._cell_center(2, 2).x + 44
	game._update_zombies(0.01)
	check(game.zombies[0].jumping, "Armored pole-vault zombie still jumps over plants")
	game._update_zombies(0.5)
	check(game.zombies[0].has_vaulted and game.zombies[0].headgear_health == 1261, "Vault landing preserves helmet")
	game.grid[2][2] = null
	z = spawn(game, "bucket_dancing_door")
	game._spawn_backup_dancers(z)
	check(game.zombies.size() == 5, "Fusion dancer keeps all four backup dancers")
	game.zombies.clear()
	game.current_level = {"id":"无尽", "terrain":"day", "events":[]}
	game.endless_bonus_levels.clear()
	for wave in [3, 5, 6, 9, 14, 18]:
		var candidates: Array = game._endless_wave_candidate_kinds(wave)
		for id in candidates:
			if Fusion.RECIPES.has(id): check(int(Fusion.RECIPES[id].wave) <= wave, "Endless equipment strength gate: " + id)
		if wave < 6: check(not candidates.any(func(id): return Fusion.RECIPES.has(id)), "Early endless waves must not contain fusion gear")
		if wave >= 14: check(candidates.has("bucket_ninja_door"), "Later endless waves must include double gear")
	game.endless_wave = 29
	seed(163)
	game._start_endless_wave()
	var fusions := 0
	for spawned in game.zombies:
		if not spawned.has("fusion_kind"): continue
		fusions += 1
		var data: Dictionary = Defs.ZOMBIES[spawned.fusion_kind]
		check(is_equal_approx(spawned.headgear_health, float(data.headgear_health) * game.endless_difficulty_mult), "Endless scales added headgear")
		check(is_equal_approx(spawned.handheld_health, float(data.handheld_health) * game.endless_difficulty_mult), "Endless scales added doors")
	check(fusions > 0 and fusions < game.zombies.size() / 2, "Fusion rolls appear without dominating the whole wave")
	game.zombies.clear()
	game.current_level = Defs.LEVELS[game._find_level_index_by_id("3-25")].duplicate(true)
	game._spawn_zombie("bucket_digger_zombie", 2)
	check(game.zombies.is_empty(), "Fusion cannot bypass an authored stage whitelist")

func _run() -> void:
	var game := make_game()
	_native_fume_regression(game)
	_catalogue_and_layers(game)
	_overflow_and_direction(game)
	_real_attacks(game)
	_magnet_and_break_reactions(game)
	_roles_and_endless(game)
	release_game(game)
	print("Fusion catalogue: %d recipes" % Fusion.RECIPES.size())
	print("Fusion/equipment tests: failures=%d" % failures)
	quit(1 if failures else 0)
