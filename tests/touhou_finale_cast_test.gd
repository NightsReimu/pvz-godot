extends "res://tests/touhou_encounter_test.gd"

const Finales = preload("res://scripts/data/touhou_finale_spell_defs.gd")

func _run() -> void:
	var cards := 0
	for kind in Finales.THEMES:
		var signatures: Array = []
		for entry in Finales.additions(kind):
			var game := make_game(kind)
			game.current_level.touhou_difficulty = "lunatic"
			game.active_rows = [0, 1, 2, 3, 4, 5]
			game.board_size = game.CELL_SIZE * Vector2(9, 6)
			game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
			for row in game.active_rows:
				for col in range(9):
					game.grid[row][col] = game._create_plant("wallnut", row, col)
					game.grid[row][col].health = 100000.0
					game.grid[row][col].max_health = 100000.0
			var boss: Dictionary = game.zombies[0]
			boss.touhou_encounter.phases = [[entry]]
			boss.touhou_encounter.index = 0
			boss.touhou_encounter.attack = 0
			var before := _health(game)
			game._trigger_boss_skill(boss)
			var dm = game.touhou_danmaku
			check(dm.casts.size() == 1 and is_equal_approx(float(dm.casts[0].duration), float(entry[4].duration)), "Actual cast must honor the complete original duration: " + String(entry[0]))
			check(not bool(boss.get("touhou_invulnerable", false)), "New phases remain targetable by native/fusion ultimates")
			check(not dm.bullets.is_empty(), "Every new phase emits real collision-bearing bullets")
			check(_health(game) == before and float(dm.casts[0].next_wave) >= 1.0, "Declaration starts with a readable warning")
			for b in dm.bullets: check(float(b.arming_time) >= 1.1, "No added bullet damages immediately")
			for b in dm.beams: check(float(b.delay) >= 1.2, "Added lasers show at least 1.2 seconds of warning")
			var geometry := _signature(dm)
			check(not geometry.is_empty() and not signatures.has(geometry), "Character's new phases change real positions, shapes or motion: " + String(entry[0]))
			signatures.append(geometry)
			dm.update(0.8)
			check(_health(game) == before, "Warning objects cannot damage before arming")
			game.boss_time_stop_timer = 1.0
			var first_age := float(dm.bullets[0].age)
			dm.update(0.2)
			check(dm.bullets[0].age == first_age, "Time stop suspends the new collision-bearing objects")
			game.boss_time_stop_timer = 0.0
			game.grid[2][3] = game._create_plant("mirror_reed", 2, 3)
			game.grid[2][3].health = 100000.0
			game.grid[2][3].max_health = 100000.0
			var reflected: Dictionary = dm.bullets[0].duplicate(true)
			reflected.position = Vector2(float(boss.x) - 12, game._row_center_y(int(boss.row)) - 12)
			check(game._bounce_boss_danmaku(reflected, Vector2i(2, 3), true, false), "Existing mirror counter works on every added projectile family")
			dm.bullets.append(reflected)
			var hp := float(boss.health)
			dm.update(0.05)
			check(float(boss.health) < hp, "A reflected new projectile can damage its owner")
			var peak: int = dm.bullets.size()
			before = _health(game)
			for frame in range(85):
				dm.update(0.1)
				peak = maxi(peak, dm.bullets.size())
			check(_health(game) < before, "New phase must apply actual swept plant damage: " + String(entry[0]))
			check(peak <= dm.MAX_BULLETS and dm.beams.size() <= dm.MAX_BEAMS, "Expanded phases respect the existing particle budgets")
			dm.clear_owner(int(boss.touhou_owner))
			check(dm.bullets.is_empty() and dm.beams.is_empty() and dm.casts.is_empty(), "Phase/death cleanup removes all added attack state")
			release(game)
			cards += 1
	print("Touhou finale live casts: %d characters / %d real new spells, distinct geometry, warning damage, reflection, time stop and cleanup; %d failure(s)" % [Finales.THEMES.size(), cards, failures])
	quit(1 if failures else 0)

func _health(game: Control) -> float:
	var value := 0.0
	for row in game.active_rows:
		for p in game.grid[row]:
			if p != null: value += float(p.health)
	return value

func _signature(dm: RefCounted) -> Array:
	var forms := {}
	for b in dm.bullets:
		var motion: Array = []
		for key in ["freeze_at", "thaw_at", "redirect_at", "angular_speed", "bounces"]:
			if b.has(key): motion.append([key, b[key]])
		forms[str([Vector2(b.position).snapped(Vector2.ONE), snappedf(Vector2(b.velocity).angle(), 0.01), b.shape, motion])] = true
	for b in dm.beams: forms[str([b.from, b.to, b.delay])] = true
	var keys: Array = forms.keys()
	keys.sort()
	return keys
