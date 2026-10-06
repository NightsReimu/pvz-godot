extends "res://tests/touhou_dense_performance_test.gd"

func _run() -> void:
	_random_sweeps()
	_native_motion_and_counters()
	print("Dense danmaku semantics: 9,000 exact swept cases plus 480 mixed bullets/72 beams, mirrors, shields, support, portals, pause and cleanup; %d failure(s)" % failures)
	quit(1 if failures else 0)

func _random_sweeps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 781405
	for dimensions in [Vector2(135, 110), Vector2(76, 33), Vector2(52, 20)]:
		var g := make_case("full", dimensions)
		g.active_rows = [0, 2, 3, 5]
		for row in range(6):
			for col in range(9):
				if rng.randf() < 0.3:
					g.support_grid[row][col] = g.grid[row][col]
					g.grid[row][col] = null
				elif rng.randf() < 0.3: g.grid[row][col] = null
		var current := Game.TouhouDanmakuRuntime.new(g)
		var legacy := Legacy.new(g)
		for case in range(3000):
			var from := g.BOARD_ORIGIN + Vector2(rng.randf_range(-100, g.board_size.x + 100), rng.randf_range(-100, g.board_size.y + 100))
			var to := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0, 1400 if case % 5 == 0 else 24)
			if case % 23 == 0: to = from
			var radius := rng.randf_range(0, 30)
			var first := case % 2 == 0
			var excluded: Array = [Vector2i(case % 6, case % 9)] if case % 3 else []
			g.hits.clear()
			var old_cells: Array = excluded.duplicate()
			var old_result := legacy._hit_plant_segment(from, to, radius, 0.25, old_cells, first)
			var expected: Array = g.hits.duplicate(true)
			g.hits.clear()
			var new_cells: Array = excluded.duplicate()
			var result := current._hit_plant_segment(from, to, radius, 0.25, new_cells, first)
			check(result == old_result and g.hits == expected and new_cells == old_cells, "Swept narrowing preserves first hit, piercing order, exclusions and supports at %s case%d" % [dimensions, case])
		g.free()

func mixed(g: CountGame) -> Array[Dictionary]:
	var data := projectiles(g, "full")
	var kinds := ["cirno_boss", "suika_boss", "reimu_boss", "marisa_boss", "reisen_boss", "mokou_boss", "hina_boss", "nitori_boss", "minoriko_boss"]
	var shapes := ["ice", "suika_stone", "ofuda", "star", "rice", "orb", "hina_ofuda", "nitori_water", "aki_leaf"]
	for i in range(data.size()):
		var b: Dictionary = data[i]
		var group := i % 9
		b.kind = kinds[group]
		b.shape = shapes[group]
		b.age = 0.05
		b.arming_time = 0.4 if i % 2 else 1.0
		b.velocity = Vector2(-g.CELL_SIZE.x * 2.5, sin(i) * g.CELL_SIZE.y * 0.15)
		b.life = 7.0
		b.angular_speed = 0.12 if i % 3 else -0.13
		match group:
			0:
				b.freeze_at = 0.1; b.thaw_at = 0.45; b.thaw_angle = 0.3; b.bounces = 2
			1:
				b.suika_orbit = Vector2(b.position); b.release_at = 0.6; b.orbit_radius = 35.0; b.orbit_angle = i * 0.05
				b.split_at = 0.9; b.suika_scale = minf(g.CELL_SIZE.x / 100.0, g.CELL_SIZE.y / 110.0)
			2:
				b.homing_after = 0.5; b.homing_rate = 0.85; b.aim_point = g._cell_center(2, 1)
				b.boundary_x = g.BOARD_ORIGIN.x + g.board_size.x * 0.4; b.boundary_exit_x = g.BOARD_ORIGIN.x + g.board_size.x * 0.85
				b.boundary_top = g.BOARD_ORIGIN.y; b.boundary_height = g.board_size.y; b.boundary_shift = g.CELL_SIZE.y * 2
			3:
				b.orbit_until = 0.65; b.orbit_center = Vector2(b.position); b.orbit_radius = 36.0; b.orbit_angle = i * 0.1; b.orbit_turn = 0.85
			4:
				b.reisen_illusion = "tune"; b.reisen_cycle = 3.8; b.reisen_offset = 0.0
				b.reisen_return_x = g.BOARD_ORIGIN.x + g.board_size.x * 0.3; b.reisen_return_exit = g.BOARD_ORIGIN.x + g.board_size.x * 0.85
				b.reisen_mirror_y = g.BOARD_ORIGIN.y * 2 + g.board_size.y
			5: b.imperishable = true; b.mokou_accelerate = true
			6, 7, 8: b.autumn_axes = Vector2(g.CELL_SIZE.x / 100.0, g.CELL_SIZE.y / 110.0) / minf(1.0, minf(g.CELL_SIZE.x / 100.0, g.CELL_SIZE.y / 110.0))
		if i % 17 == 0: b.cuttable = true
	return data

func snapshot(g: CountGame, dm: RefCounted) -> Dictionary:
	var plants: Array = []
	for row in range(6):
		for col in range(9):
			var p = g._targetable_plant_at(row, col)
			plants.append(null if p == null else [p.kind, p.health, p.get("armor_health", 0.0), p.get("reflect_cooldown_until", 0.0)])
	var enemies: Array = []
	for z in g.zombies: enemies.append([z.uid, z.health, z.x, z.row, z.get("shield_health", 0.0), z.get("revealed_timer", 0.0)])
	return {"plants": plants, "enemies": enemies, "bullets": dm.bullets.duplicate(true), "beams": dm.beams.duplicate(true), "hits": g.hits.duplicate(true)}

func _native_motion_and_counters() -> void:
	for dimensions in [Vector2(135, 110), Vector2(76, 33), Vector2(52, 20)]:
		var games: Array = []
		for optimized in [true, false]:
			var g := make_case("mirror", dimensions)
			g.active_rows = [0, 1, 2, 4, 5]
			g.grid[1][4] = g._create_plant(Game.FusionPlantDefs.result("mirror_reed", "peashooter"), 1, 4)
			g.grid[1][4].health = 100000000.0
			g.grid[2][4] = g._create_plant("wallnut", 2, 4)
			g.grid[2][4].fusion_mirror_until = g.level_time + 1.0
			g.grid[2][4].health = 100000000.0
			for i in range(12):
				g._spawn_zombie_at("normal", i % 6, g._cell_center(i % 6, 3 + i / 6).x, true)
				g.zombies.back().health = 100000000.0
			var dm = Game.TouhouDanmakuRuntime.new(g) if optimized else Legacy.new(g)
			g.touhou_danmaku = dm
			dm.bullets = mixed(g)
			for i in range(72):
				dm.beams.append({"owner": 1, "kind": "marisa_boss", "phase": 0, "from": g._cell_center(i % 6, 8) + Vector2(0, -12), "to": g._cell_center(i % 6, 0) + Vector2(0, -12), "color": Color.WHITE, "age": 0.0, "delay": 0.2, "duration": 0.8, "width": 14.0, "damage": 0.5, "hits": [], "turn_rate": 0.1, "sword_cut": i % 5 == 0})
			games.append(g)
		for delta in [0.05, 0.4, 0.1, 0.8, 0.75]:
			for g in games:
				g.level_time += delta
				g.touhou_danmaku.update(delta)
			check(snapshot(games[0], games[0].touhou_danmaku) == snapshot(games[1], games[1].touhou_danmaku), "Mixed families/lasers/portals/mirror paths keep exact positions, HP and per-cell hit order at %s delta%s" % [dimensions, delta])
		for g in games:
			g.grid[2][4] = g._create_plant("wallnut", 2, 4)
			g.grid[2][5] = g._create_plant("mirror_reed", 2, 5)
			g.support_grid[5][4] = g.grid[5][4]
			g.grid[5][4] = null
			g.touhou_danmaku.update(0.1)
		check(snapshot(games[0], games[0].touhou_danmaku) == snapshot(games[1], games[1].touhou_danmaku), "Replacing mirrors and exposing supports between updates never leaves stale collision state")
		for g in games: g.boss_time_stop_timer = 1.0
		var frozen := snapshot(games[0], games[0].touhou_danmaku)
		for g in games: g.touhou_danmaku.update(0.3)
		check(snapshot(games[0], games[0].touhou_danmaku) == frozen and snapshot(games[1], games[1].touhou_danmaku) == frozen, "Pause suspends dense motion, warnings, damage and returns")
		for g in games:
			g.zombies[0].health = 0.0
			g.touhou_danmaku.update(0.1)
			check(g.touhou_danmaku.bullets.is_empty() and g.touhou_danmaku.beams.is_empty(), "Dead owners clear all dense attack state even during time stop")
			g.free()
