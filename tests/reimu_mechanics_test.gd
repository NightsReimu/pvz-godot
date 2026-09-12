extends "res://tests/touhou_encounter_test.gd"

const Geometry = preload("res://scripts/runtime/reimu_danmaku.gd")
const CHOICES := ["easy", "normal", "hard", "lunatic"]

func fixture(choice: String = "easy", isolated: bool = true) -> EncounterGame:
	var game := make_game("reimu_boss")
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.current_level = {"id": "3-22-a", "terrain": "reimu_midnight_bamboo", "events": [], "touhou_difficulty": choice}
	if isolated:
		game.zombies[0].erase("touhou_encounter")
	else:
		Game.TouhouPhaseRuntime.start(game.zombies[0], game.current_level)
	game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
	return game

func _run() -> void:
	_test_all_routes()
	_test_all_cards()
	_test_tiles()
	_test_sealed_actions()
	_test_geometry()
	print("Reimu routes, 23 live spell cards, seals, tile effects and geometry: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_all_routes() -> void:
	for choice in CHOICES:
		var game := fixture(choice, false)
		var boss: Dictionary = game.zombies[0]
		var expected: Array = []
		for phase in boss.touhou_encounter.phases:
			for entry in phase:
				expected.append(entry[0])
		finish_encounter(game)
		check(game.declarations.map(func(d): return d.id) == expected, choice + ": burst damage must not skip any nonspell or spell")
		check(game.touhou_danmaku.bullets.is_empty() and game.touhou_danmaku.casts.is_empty(), "Finishing must remove owner bullets")
		game._cleanup_dead_zombies()
		check(game._ensure_reimu_runtime().tiles.is_empty(), "Defeat must clear tiles")
		print("Reimu %s: %d phases / %d attacks / %.1fs under burst" % [choice, boss.touhou_encounter.phases.size(), game.declarations.size(), game.level_time])
		release(game)

func _test_all_cards() -> void:
	for choice in CHOICES:
		var cards: Array = Spells.cards_for("reimu_boss", {"touhou_difficulty": choice})
		for cycle in range(cards.size()):
			var game := fixture(choice)
			for row in range(6):
				for col in range(8):
					game.grid[row][col] = game._create_plant("wallnut", row, col)
			game.zombies[0].boss_skill_cycle = cycle
			var initial := total_plant_health(game)
			game._trigger_boss_skill(game.zombies[0])
			var dm = game.touhou_danmaku
			check(dm.casts[0].card.id == cards[cycle][0], "Declared card must match selected difficulty")
			check(initial == total_plant_health(game), "Casting must not apply instantaneous board damage")
			var peak: int = dm.bullets.size()
			for frame in range(90):
				dm.update(0.1)
				peak = maxi(peak, dm.bullets.size())
			check(peak > 0 and peak <= dm.MAX_BULLETS, "%s emits bounded live bullets" % cards[cycle][0])
			check(total_plant_health(game) < initial, "%s must be capable of hitting plants" % cards[cycle][0])
			if cycle == 5:
				var boss: Dictionary = game.zombies[0]
				var health := float(boss.health)
				game._apply_zombie_damage(boss, 1000000, 0, 0, true)
				check(float(boss.health) == health and bool(boss.touhou_invulnerable), "Blink is a timed survival card")
				dm.update(8.0)
				check(not boss.touhou_invulnerable and dm.casts.is_empty() and dm.bullets.is_empty(), "Blink must end and clean up without an extra hit")
			release(game)

func total_plant_health(game: Control) -> float:
	var result := 0.0
	for row in game.grid:
		for plant in row:
			if plant != null:
				result += float(plant.health)
	return result

func _test_tiles() -> void:
	var game := fixture()
	var boss: Dictionary = game.zombies[0]
	var runtime = game._ensure_reimu_runtime()
	game.grid[2][3] = game._create_plant("peashooter", 2, 3)
	game.support_grid[2][3] = game._create_plant("lily_pad", 2, 3)
	game.grid[2][2] = game._create_plant("peashooter", 2, 2)
	game.grid[3][2] = game._create_plant("wallnut", 3, 2)
	game.grid[3][2].health -= 100
	game._spawn_zombie_at("normal", 4, game._cell_center(4, 5).x, true)
	var enemy: Dictionary = game.zombies.back()
	var health := float(enemy.health)
	var speed := game._current_zombie_speed(enemy)
	boss.row = 4
	boss.x = game._cell_center(4, 5).x
	runtime.queue_tile(boss, Vector2i(2, 3), "seal")
	runtime.queue_tile(boss, Vector2i(4, 5), "purify")
	runtime.queue_tile(boss, Vector2i(3, 2), "guard")
	runtime.update(0.9)
	check(not game.grid[2][3].has("reimu_sealed") and enemy.health == health, "Tile warning must last a full second")
	var plant_hp := float(game.grid[3][2].health)
	runtime.update(0.2)
	check(game._plant_charm_blocks_actions(game.grid[2][3]) and not game._plant_charm_blocks_actions(game.grid[2][2]), "Only the red tile must seal its plant")
	check(game._plant_charm_blocks_actions(game.support_grid[2][3]), "A covered support plant must also be sealed")
	check(float(game.grid[3][2].health) > plant_hp, "Gold tile must heal its plant")
	plant_hp = float(game.grid[3][2].health)
	game._damage_plant_cell(3, 2, 100, 0, true)
	check(is_equal_approx(plant_hp - float(game.grid[3][2].health), 55), "Gold tile must reduce a bullet hit by 45 percent")
	check(float(enemy.health) < health and is_equal_approx(game._current_zombie_speed(enemy), speed * 0.55), "Blue tile must cleanse and slow enemy zombies")
	check(not boss.has("reimu_purified"), "Reimu must be immune to her own purification")
	game.grid[2][3] = game._create_plant("repeater", 2, 3)
	runtime.update(0.1)
	check(game.grid[2][3].get("reimu_sealed", false), "Plants placed during an active seal inherit the tile effect")
	game.grid[2][3].holy_invincible_timer = 1.0
	runtime.update(0.1)
	check(not game.grid[2][3].has("reimu_sealed"), "Holy protection must resist a seal even within the active tile")
	game.grid[2][3].holy_invincible_timer = 0.0
	enemy.x = game._cell_center(4, 6).x
	runtime.update(0.1)
	check(not enemy.has("reimu_purified") and is_equal_approx(game._current_zombie_speed(enemy), speed), "Leaving a blue tile removes its slow")
	runtime.update(1.4)
	check(not game.grid[2][3].has("reimu_sealed"), "Seal must expire rather than lock the cell permanently")
	check(not game.support_grid[2][3].has("reimu_sealed"), "Covered support marks must also expire")
	runtime.clear_owner(int(boss.uid))
	check(runtime.tiles.is_empty() and not game.grid[3][2].has("reimu_guard"), "Changing phases must clear tile effects")
	for col in range(9):
		runtime.queue_tile(boss, Vector2i(0, col), "seal")
	check(runtime.tiles.size() == runtime.MAX_TILES, "Tile cap must be enforced")
	runtime.reset()
	check(runtime.tiles.is_empty() and runtime.light == 0, "Restart must reset light and tiles")
	release(game)

func _test_sealed_actions() -> void:
	for kind in ["peashooter", "repeater", "split_pea", "starfruit", "sunflower", "snow_pea"]:
		var game := fixture()
		var plant: Dictionary = game._create_plant(kind, 2, 4)
		plant.shot_cooldown = 0.0
		plant["rear_shot_cooldown"] = 0.0
		plant["burst_remaining"] = 2
		plant["burst_timer"] = 0.0
		plant["sun_timer"] = 0.0
		plant["ultimate_charge"] = 1.0
		plant["ultimate_cooldown"] = 0.0
		game.grid[2][4] = plant
		var runtime = game._ensure_reimu_runtime()
		runtime.queue_tile(game.zombies[0], Vector2i(2, 4), "seal", 0)
		runtime.update(0.1)
		check(not game._try_activate_ultimate(2, 4) and not game._activate_plant_food(2, 4), kind + " seal must block ultimates and food")
		game._update_plants(0.7)
		check(game.projectiles.is_empty() and game.suns.is_empty(), kind + " seal must stop shooting / sun generation")
		runtime.update(1.6)
		game._update_plants(0.7)
		check(not game._plant_charm_blocks_actions(plant) and (not game.projectiles.is_empty() or not game.suns.is_empty()), kind + " must resume after sealing")
		release(game)

func _test_geometry() -> void:
	var bullet := {"age": 1.0, "position": Vector2(60, 40), "velocity": Vector2(-100, 0), "boundary_x": 65.0, "boundary_exit_x": 40.0, "boundary_top": 0.0, "boundary_height": 100.0, "boundary_shift": 20.0}
	var before := Geometry.advance_bullet(bullet, Vector2(70, 40), 0.1)
	check(before == bullet.position and before == Vector2(40, 60), "Boundary crossing must not sweep a phantom damage segment through the portal gap")
	bullet = {"age": 1.0, "position": Vector2.ZERO, "velocity": Vector2.RIGHT * 100, "aim_point": Vector2.DOWN * 100, "homing_after": 0.5, "homing_rate": 1.0}
	Geometry.advance_bullet(bullet, Vector2.ZERO, 0.1)
	check(bullet.velocity.y > 0 and is_equal_approx(bullet.velocity.length(), 100), "Returning charms curve toward the target without speed jumps")
	var game := fixture()
	game.grid[2][4] = game._create_plant("wallnut", 2, 4)
	game._trigger_boss_skill(game.zombies[0])
	var dm = game.touhou_danmaku
	dm.casts.clear()
	dm.bullets.clear()
	var center: Vector2 = game._cell_center(2, 4) + Vector2(0, -12)
	dm._bullet({"owner": game.zombies[0].touhou_owner, "kind": "reimu_boss"}, center, 0, 0, Color.RED, "ofuda", {"arming_time": 0.8})
	var health := float(game.grid[2][4].health)
	dm.update(0.7)
	check(float(game.grid[2][4].health) == health, "Ofuda appearing over plants must respect arming delay")
	dm.update(0.2)
	check(float(game.grid[2][4].health) < health, "Armed ofuda must use the actual collision shape")
	release(game)
