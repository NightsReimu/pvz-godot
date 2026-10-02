extends "res://tests/touhou_spell_contract_test.gd"

const Trio = preload("res://scripts/runtime/prismriver_trio.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")

func _run() -> void:
	var game := make_game("prismriver_boss")
	if not game.has_method("_zombie_hit_positions"):
		check(false, "Three real bodies must expose shared targeting geometry")
		release(game)
		quit(1)
		return
	var bodies := Trio.bodies(game, game.zombies[0])
	var rows := {}
	for body in bodies:
		rows[body.row] = true
		var point := Vector2(body.position)
		check(game._has_zombie_ahead(body.row, point.x - 200), "Plants must acquire every sister")
		check(game._find_lane_target(body.row, point.x - 200, 400) == 0, "Lane targeting resolves to the shared owner")
		check(game._find_frontmost_zombie(body.row) == 0, "Frontmost targeting sees every sister")
		check(game._find_projectile_target({"row":body.row, "position":point, "speed":480, "radius":8}) == 0, "Peas hit each sister")
		check(game._find_projectile_target({"row":body.row, "position":point, "speed":480, "radius":8, "hit_uids":[int(game.zombies[0].uid)]}) == -1, "Piercing/boomerang UID exclusion applies across all bodies")
		check(game._find_closest_zombies_in_radius(point, 10, 8) == [0], "Spatial targeting finds each body once")
		var hp := float(game.zombies[0].health)
		game._damage_zombies_in_radius(body.row, point.x, 10, 23)
		check(is_equal_approx(hp - float(game.zombies[0].health), 23), "Every sister damages shared HP")
		hp = float(game.zombies[0].health)
		game._spawn_projectile(body.row, point + Vector2(-1, -8), Color.GREEN, 19, 0, 0)
		game._update_projectiles(0.01)
		check(is_equal_approx(hp - float(game.zombies[0].health), 19) and game.projectiles.is_empty(), "Actual pea updates hit and consume the projectile at every body")
		var plant: Dictionary = game._create_plant("cabbage_pult", int(body.row), 0)
		plant.shot_cooldown = 0.0
		game._ensure_plant_runtime().update_cabbage_pult(plant, 0.01, int(body.row), 0)
		check(game.projectiles.size() == 1 and Vector2(game.projectiles[0].arc_target).distance_to(point + Vector2(0, -8)) < 0.01, "Cabbage arcs aim at the selected sister")
		game.projectiles.clear()
		hp = float(game.zombies[0].health)
		game._spawn_boomerang_projectile(body.row, point, point.x - 200, 17, 3)
		game._update_projectiles(0.001)
		check(is_equal_approx(hp - float(game.zombies[0].health), 17), "Actual boomerangs hit each sister")
		game.projectiles.clear()
	check(bodies.size() == 3 and rows.size() == 3 and game.zombies.size() == 1, "Three distinct lanes use one health/phase entity")
	var hp := float(game.zombies[0].health)
	game._damage_zombies_in_circle(Vector2(game.zombies[0].x, game._row_center_y(2)), 2000, 31)
	check(is_equal_approx(hp - float(game.zombies[0].health), 31), "One explosion covering the trio must not triple damage")
	check(game._find_closest_zombies_in_radius(Vector2(game.zombies[0].x, game._row_center_y(2)), 2000, 8) == [0], "Area target lists deduplicate the owner")
	var clock := float(game.zombies[0].get("prismriver_time",0))
	var frozen: Dictionary = game.zombies[0].duplicate(true)
	frozen.frozen_timer = 2.0
	frozen = game._update_prismriver_hovering_boss(frozen, 0.5)
	check(float(frozen.get("prismriver_time",0)) == clock, "Freeze holds all three body positions")
	for member in range(3):
		for frame in range(24):
			var image := Trio.texture(member, frame)
			check(image != null and image.get_width() == 512 and image.get_height() == 384, "All 72 individually saved poses import")
	release(game)
	for tier in ["easy","normal","hard","lunatic"]:
		var level := {"touhou_difficulty":tier}
		var expected: Array = {"easy":[45,49,53,57,61,65], "normal":[46,50,54,58,62,66], "hard":[47,51,55,59,63,67], "lunatic":[48,52,56,60,64,68]}[tier]
		for cycle in range(6):
			var g := make_game("prismriver_boss",cycle)
			g.current_level.merge(level)
			g.zombies[0] = g._trigger_boss_skill(g.zombies[0])
			var runtime = g.touhou_danmaku
			check(String(g.zombies[0].touhou_card.id) == "th07-%03d" % int(expected[cycle]), "PCB stage four IDs must match all four difficulties")
			var points := Trio.bodies(g,g.zombies[0])
			var emitters := {}
			for bullet in runtime.bullets:
				for body in points:
					if Vector2(bullet.position).distance_to(Vector2(body.position)+Vector2(-14,-12)) <= 26:
						emitters[body.member] = true
			check(emitters.size() == (1 if cycle in [1,2,3] else 3), "Solo and ensemble bullets come from the visible performers")
			runtime.clear_owner(int(g.zombies[0].touhou_owner))
			check(runtime.bullets.is_empty() and runtime.beams.is_empty() and runtime.casts.is_empty(), "Death/phase cleanup clears the whole ensemble")
			release(g)
	print("Prismriver trio: shared HP, targeting, once-only area damage, freeze, 72 poses and four difficulty solos/ensembles: %d failure(s)" % failures)
	quit(1 if failures else 0)
