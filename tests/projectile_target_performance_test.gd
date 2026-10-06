extends SceneTree

const Fixture = preload("res://tests/fixtures/projectile_target_legacy.gd")
const OUTPUT := "res://output/touhou-next-balance/performance"
var failures := 0

class LegacyGame extends Fixture:
	func _find_projectile_target(projectile: Dictionary) -> int:
		return legacy_find_projectile_target(projectile)

func _initialize() -> void: call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)

func make_game(dimensions: Vector2, legacy: bool = false) -> Control:
	var g = LegacyGame.new() if legacy else Fixture.new()
	g.configure()
	g.CELL_SIZE = dimensions
	g.BOARD_ORIGIN = Vector2(37, 129)
	g.board_size = dimensions * Vector2(9, 6)
	for row in range(6):
		for col in range(9):
			g.add_plant(row, col, 0.0)
	for i in range(65):
		g._spawn_zombie_at("normal", i % 6, g._cell_center(i % 6, (i / 6) % 9).x + float(i % 3) * 7.0, true)
		g.zombies.back().health = 100000000.0
		g.zombies.back().max_health = 100000000.0
	return g

func shots(g: Control) -> Array:
	var template: Array = []
	for i in range(480):
		var row := i % 6
		var point: Vector2 = g._cell_center(row, (i / 6) % 9) + Vector2(-16, -12)
		template.append({"kind":"pea", "row":row, "position":point, "speed":460.0, "velocity_y":0.0, "damage":1.0, "slow_duration":0.0, "color":Color.WHITE, "radius":8.0, "reflected":false, "fire":false, "free_aim":false, "anti_air":false})
	return template

func average(values: Array) -> float:
	var total := 0.0
	for value in values: total += float(value)
	return total / values.size()

func benchmark(dimensions: Vector2, legacy: bool, frames: int) -> Dictionary:
	var g := make_game(dimensions, legacy)
	var template := shots(g)
	var positioned := template.duplicate(true)
	for p in positioned: p.position += Vector2(460.0 / 60.0, 0)
	var times: Array = []; var query_times: Array = []
	var query_checks := 0; var query_points := 0; var contacts := 0
	var health_damage := 0.0; var retained := 0; var visuals := 0
	var choices: Array = []
	for frame in range(frames + 6):
		g.projectiles = template.duplicate(true)
		for z in g.zombies: z.health = 100000000.0
		g.effects.clear(); g.vfx_particles.clear()
		var start := Time.get_ticks_usec()
		g._update_projectiles(1.0 / 60.0)
		var elapsed := Time.get_ticks_usec() - start
		g.reset_target_counters()
		var query_start := Time.get_ticks_usec()
		choices.clear()
		for p in positioned: choices.append(g._find_projectile_target(p))
		var query_elapsed := Time.get_ticks_usec() - query_start
		if frame >= 6:
			times.append(elapsed); query_times.append(query_elapsed)
			query_checks += g.enemy_checks; query_points += g.point_checks
			contacts += 480 - g.projectiles.size(); retained += g.projectiles.size()
			visuals += g.effects.size() + g.vfx_particles.size()
			for z in g.zombies: health_damage += 100000000.0 - float(z.health)
	times.sort(); query_times.sort()
	var result := {"cells":[dimensions.x,dimensions.y], "implementation":"legacy" if legacy else "current", "frames":frames, "mean_us":average(times), "p95_us":times[ceili(frames*.95)-1], "query_mean_us":average(query_times), "query_p95_us":query_times[ceili(frames*.95)-1], "query_enemy_checks":float(query_checks)/frames, "query_point_allocations":float(query_points)/frames, "contacts":float(contacts)/frames, "retained":float(retained)/frames, "visuals":float(visuals)/frames, "health_damage":health_damage/frames, "choices":choices.duplicate()}
	g.free()
	return result

func _run() -> void:
	var results: Array = []
	var quick := OS.get_cmdline_user_args().has("--gate-only")
	for dimensions in [Vector2(135,110), Vector2(76,33)]:
		for trial in range(1 if quick else 3):
			var pair: Array = []
			for legacy in ([false,true] if trial % 2 else [true,false]):
				var r := benchmark(dimensions, legacy, 6 if quick else 40)
				r.trial = trial; pair.append(r); results.append(r)
				var report := r.duplicate(); report.erase("choices")
				print(JSON.stringify(report))
			var old: Dictionary = pair.filter(func(r): return r.implementation == "legacy")[0]
			var now: Dictionary = pair.filter(func(r): return r.implementation == "current")[0]
			check(now.query_enemy_checks <= old.query_enemy_checks * .4, "Target index must reduce real candidate eligibility checks, while retaining all 480 native shots")
			check(now.query_point_allocations <= old.query_point_allocations * .4, "Target index must avoid allocating irrelevant enemy hit-point arrays")
			for field in ["contacts","retained","visuals","health_damage","choices"]:
				check(now[field] == old[field], "Native paired target and projectile update preserves " + field)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var name := "target-gate" if quick else "target-after"
	var f := FileAccess.open(OUTPUT+"/"+name+".json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"records":results}, "\t")+"\n")
	print("Plant native paired benchmark: ", results.size(), " measurements; ", failures, " failure(s)")
	quit(1 if failures else 0)
