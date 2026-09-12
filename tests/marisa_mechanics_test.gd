extends "res://tests/touhou_encounter_test.gd"

const Geometry = preload("res://scripts/runtime/marisa_danmaku.gd")
const CHOICES := ["easy", "normal", "hard", "lunatic"]

func fixture(choice: String = "easy", isolated: bool = true) -> EncounterGame:
	var game := make_game("marisa_boss")
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.current_level = {"id": "3-22-b", "terrain": "reimu_midnight_bamboo", "events": [], "touhou_difficulty": choice}
	if isolated:
		game.zombies[0].erase("touhou_encounter")
	else:
		Game.TouhouPhaseRuntime.start(game.zombies[0], game.current_level)
	game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
	return game

func _run() -> void:
	_test_all_routes()
	_test_all_cards()
	_test_tiles_and_mushrooms()
	_test_beams_and_orbits()
	print("Marisa routes, 23 live spell cards, light tiles, mushrooms, beams and star geometry: %d failure(s)" % failures)
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
		check(game._ensure_marisa_runtime().tiles.is_empty(), "Defeat must clear tiles")
		print("Marisa %s: %d phases / %d attacks / %.1fs under burst" % [choice, boss.touhou_encounter.phases.size(), game.declarations.size(), game.level_time])
		release(game)

func _test_all_cards() -> void:
	for choice in CHOICES:
		var cards: Array = Spells.cards_for("marisa_boss", {"touhou_difficulty": choice})
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
				check(float(boss.health) == health and bool(boss.touhou_invulnerable), "Final Spark is a timed survival card")
				dm.update(8.0)
				check(not boss.touhou_invulnerable and dm.casts.is_empty() and dm.bullets.is_empty(), "Final Spark must end and clean up without an extra hit")
			release(game)

func total_plant_health(game: Control) -> float:
	var result := 0.0
	for row in game.grid:
		for plant in row:
			if plant != null:
				result += float(plant.health)
	return result

func _test_tiles_and_mushrooms() -> void:
	var game := fixture()
	var boss: Dictionary = game.zombies[0]
	game._trigger_boss_skill(boss)
	var runtime = game._ensure_marisa_runtime()
	runtime.clear_owner(int(boss.uid))
	game.grid[2][3] = game._create_plant("wallnut", 2, 3)
	game.grid[3][2] = game._create_plant("wallnut", 3, 2)
	runtime.queue_tile(boss, Vector2i(2, 3), "glare")
	runtime.queue_tile(boss, Vector2i(3, 2), "prism")
	runtime.queue_tile(boss, Vector2i(4, 6), "mushroom", 1.3)
	runtime.queue_tile(boss, Vector2i(5, 6), "mushroom", 1.3)
	var health := total_plant_health(game)
	runtime.update(1.0)
	check(total_plant_health(game) == health and game.zombies.size() == 1, "Warnings must neither harm nor summon early")
	game.grid[5][6] = game._create_plant("repeater", 5, 6)
	runtime.update(0.4)
	check(game._plant_attack_cadence_scale(2, 3) == 1.25, "Glare slows fire cadence on its occupied cell")
	check(game.grid[2][3].health < 4000.0, "Glare must apply actual gradual damage")
	var before := float(game.grid[3][2].health)
	game._damage_plant_cell(3, 2, 100, 0, true)
	check(is_equal_approx(before - float(game.grid[3][2].health), 70), "Prism reduces incoming damage by 30 percent once")
	var mushrooms: Array = game.zombies.filter(func(b): return String(b.kind) == "marisa_mushroom" and float(b.health) > 0)
	check(mushrooms.size() == 1 and mushrooms[0].row == 4, "Planting during the purple warning must block that summon without replacing the plant")
	var mushroom: Dictionary = mushrooms[0]
	var x := float(mushroom.x)
	game._update_zombies(0.5)
	check(is_equal_approx(float(mushroom.x), x), "Magic mushrooms must stay planted")
	game.grid[4][3] = game._create_plant("wallnut", 4, 3)
	game.touhou_danmaku.clear_owner(int(boss.touhou_owner))
	before = float(game.grid[4][3].health)
	for frame in range(60):
		runtime.update(0.1)
		game.touhou_danmaku.update(0.1)
	check(float(game.grid[4][3].health) < before, "Hostile mushrooms must shoot collision-bearing attacks at plants")
	game._apply_zombie_damage(mushroom, 100000, 0, 0, true)
	runtime.update(0.1)
	check(game.touhou_danmaku.bullets.all(func(b): return not b.has("marisa_source")) and game.touhou_danmaku.beams.all(func(b): return not b.has("marisa_source")), "Destroying a mushroom cancels its remaining attack and telegraph")
	check(game._plant_attack_cadence_scale(2, 3) == 1.0 and not game.grid[3][2].has("marisa_prism"), "Expired tiles restore plant cadence and defenses")
	for col in range(9):
		runtime.queue_tile(boss, Vector2i(0, col), "mushroom", 0.1)
	check(runtime.tiles.size() <= runtime.MAX_TILES, "Summon and tile caps must hold")
	runtime.update(0.2)
	check(game.zombies.filter(func(b): return String(b.kind) == "marisa_mushroom" and float(b.health) > 0).size() <= runtime.MAX_MUSHROOMS, "Live familiar cap must hold")
	runtime.clear_owner(int(boss.uid))
	check(runtime.tiles.is_empty() and game.zombies.all(func(b): return String(b.kind) != "marisa_mushroom" or float(b.health) <= 0), "Phase/death cleanup removes all owned tiles and mushrooms")
	runtime.reset()
	release(game)

func _test_beams_and_orbits() -> void:
	var game := fixture()
	var boss: Dictionary = game.zombies[0]
	game.grid[2][3] = game._create_plant("wallnut", 2, 3)
	game._trigger_boss_skill(boss)
	var dm = game.touhou_danmaku
	dm.clear_owner(int(boss.touhou_owner))
	var start: Vector2 = game._cell_center(2, 8) + Vector2(0, -12)
	var end: Vector2 = game._cell_center(2, 0) + Vector2(0, -12)
	var c := {"owner": int(boss.touhou_owner), "kind": "marisa_boss", "phase": 0}
	dm._beam(c, start, end, Color.GOLD, 1.0, 30, {"damage": 100.0, "duration": 1.0})
	var before := float(game.grid[2][3].health)
	dm.update(0.95)
	check(game.grid[2][3].health == before, "Laser telegraph must remain harmless")
	dm.update(0.2)
	var hit_health := float(game.grid[2][3].health)
	check(is_equal_approx(before - hit_health, 100 * 1.22 * game.TouhouDifficulty.boss_damage_multiplier(game.current_level)), "Beam damage must apply character tuning and difficulty exactly once")
	dm.update(0.6)
	check(game.grid[2][3].health == hit_health, "A sustained beam must not damage the same cell every frame")
	var rotating := {"from": Vector2.ZERO, "to": Vector2(100, 0), "turn_rate": 0.2}
	Geometry.advance_beam(rotating, 0.5)
	check(is_equal_approx(Vector2(rotating.to).length(), 100) and Vector2(rotating.to).y > 0, "Rotating lasers must rotate their collision endpoint at constant length")
	var b := {"age": 0.5, "position": Vector2(100, 0), "velocity": Vector2(0, 80), "orbit_until": 1.05, "orbit_center": Vector2.ZERO, "orbit_radius": 100, "orbit_angle": 0.0, "orbit_turn": 1.25}
	Geometry.advance_bullet(b, Vector2(100, 0), 0.1)
	check(is_equal_approx(Vector2(b.position).length(), 100) and Vector2(b.position).y > 0, "Event Horizon must orbit before releasing tangential stars")
	b.age = 1.2
	var prior := Vector2(b.position)
	Geometry.advance_bullet(b, prior, 0.1)
	check(b.position == prior, "Released stars must stop being snapped into the orbit")
	# Test the emitter-to-shared-motion wiring, not merely the metadata value.
	game.grid[2][3] = null
	boss.boss_skill_cycle = 1
	game._trigger_boss_skill(boss)
	dm.update(0.02)
	var star: Dictionary = dm.bullets[0]
	var angle := Vector2(star.velocity).angle()
	dm.update(0.2)
	check(absf(angle_difference(angle, Vector2(star.velocity).angle())) > 0.01, "Stardust stars must curve in the real shared update loop")

	release(game)
