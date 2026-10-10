extends "res://tests/touhou_autumn_density_probe.gd"

const RebuiltCards = preload("res://scripts/runtime/touhou_canon_registry.gd")
const QUIET := ["aki_ripening", "aki_offering", "hina_delayed", "hina_doll_offering", "hina_misfire"]

class LegacyDanmaku extends AuditDanmaku:
	func _emit_wave(c: Dictionary) -> void:
		c.erase("autumn_full")
		c.erase("autumn_density")
		super._emit_wave(c)

func _key(r: Dictionary) -> String:
	return str([String(r.stage_id), String(r.difficulty), String(r.role), int(r.phase), int(r.attack), String(r.id)])

func _same_capture(a: Variant, b: Variant) -> bool:
	# JSON round-trips integer variants and the last floating-point digits.
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a) - float(b)) <= 0.0000001
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in range(a.size()):
			if not _same_capture(a[i], b[i]): return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for k in a:
			if not b.has(k) or not _same_capture(a[k], b[k]): return false
		return true
	return a == b

func _run() -> void:
	var snapshot = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/touhou_autumn_danmaku_v175.json"))
	check(snapshot != null and snapshot.records.size() == 86 and snapshot.controls.size() == 30, "Use the complete actual v175 barrage baseline")
	for stage in ["4-19", "4-20"]:
		var base: Dictionary = {}
		for level in Game.Defs.LEVELS:
			if level.id == stage: base = level
		for choice in ["easy", "normal", "hard", "lunatic"]:
			_audit(base, choice, false)
			_audit(base, choice, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/v176"))
	var capture := FileAccess.open("res://output/v176/density-test-after.json", FileAccess.WRITE)
	capture.store_string(JSON.stringify({"records": records}, "\t") + "\n")
	var prior := {}
	for r in snapshot.records: prior[_key(r)] = r
	var full_totals := {}
	var row_improvements := 0
	for r in records:
		if not prior.has(_key(r)):
			check(false, "Every live cast has a captured v175 baseline: " + _key(r))
			continue
		var before: Dictionary = prior[_key(r)]
		for field in ["id", "pattern", "duration", "phase_count", "boss_hp"]: check(_same_capture(r[field], before[field]), "Bullet tuning cannot change " + field + ": " + _key(r))
		check(float(r.min_arming) >= 1.0 and float(r.warning_damage) == 0.0, "Denser volleys retain a complete harmless warning")
		check(int(r.drops) == 0 and int(r.peak) <= 480 and int(r.beam_peak) <= 72, "Density cannot turn into silently dropped particle spam")
		if r.role == "road":
			for field in ["launched", "beams", "waves", "hit_rows", "min_arming"]: check(_same_capture(r[field], before[field]), "Road " + field + " remains identical: " + _key(r))
			# v178 doubles all Boss damage; retain the immutable v175 firing baseline.
			check(_same_capture(r.plant_damage, float(before.plant_damage) * Difficulty.OUTGOING_DAMAGE_MULTIPLIER), "Road damage gains exactly the global Boss multiplier")
			continue
		var group := str([r.stage_id, r.difficulty])
		if not full_totals.has(group): full_totals[group] = {"before": 0, "after": 0, "duration": 0.0}
		full_totals[group].before += int(before.launched)
		full_totals[group].after += int(r.launched)
		full_totals[group].duration += float(r.duration)
		if not String(r.id).ends_with("nonspell"):
			check(int(r.launched) >= int(before.launched) * 1.70, "Every existing full spell gains real on-time bullets: " + _key(r))
			check(int(r.swept_hits) >= int(before.swept_hits) * 1.35, "Extra bullet quantity must produce actual useful swept hits")
		if String(r.pattern) in QUIET:
			check(r.hit_rows.size() >= 5 and float(r.rate) >= 4.0, "Quiet board-mechanic spells gain meaningful cross-lane accompaniment")
			if r.hit_rows.size() > before.hit_rows.size(): row_improvements += 1
	for group in full_totals:
		var totals: Dictionary = full_totals[group]
		check(float(totals.after) / maxf(1, float(totals.before)) >= 1.85, "The full route gains about twice the actual barrage, with unchanged clock lengths")
	check(row_improvements > 0, "Lane pressure expands instead of merely recoloring existing shots")
	_test_other_character_controls(snapshot.controls)
	_test_unchanged_trajectories(snapshot.controls)
	print("Autumn barrage quantity: 86 actual attacks, unchanged roads/HP/cards, useful dense six-lane collisions and 30 unchanged other characters; %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_other_character_controls(controls: Array) -> void:
	for before in controls:
		# v1.0.185/186 deliberately rebuilt these characters' cards from the
		# originals; touhou_canon_patterns_test covers them instead.
		var entry_pattern := String(Spells.phases_for(before.kind, {"touhou_difficulty": "lunatic"})[0].back()[2])
		if RebuiltCards.owns(String(before.kind), entry_pattern):
			continue
		var game := make_game(before.kind)
		game.current_level.touhou_difficulty = "lunatic"
		game.active_rows = [0, 1, 2, 3, 4, 5]
		game.board_rows = 6
		game.board_size = game.CELL_SIZE * Vector2(9, 6)
		var boss: Dictionary = game.zombies[0]
		var entry: Array = Spells.phases_for(before.kind, game.current_level)[0].back()
		boss.touhou_encounter.phases = [[entry]]
		boss.touhou_encounter.index = 0
		boss.touhou_encounter.attack = 0
		for row in range(6):
			for col in range(9):
				game.grid[row][col] = game._create_plant("wallnut", row, col)
				game.grid[row][col].health = 100000.0
				game.grid[row][col].max_health = 100000.0
		var dm := AuditDanmaku.new(game)
		game.touhou_danmaku = dm
		game._trigger_boss_skill(boss)
		var elapsed := 0.0
		while elapsed < float(before.duration) + 0.1:
			dm.update(0.05)
			elapsed += 0.05
		check(dm.launched == int(before.launched) and dm.beam_launched == int(before.beams) and _same_capture(dm.waves, before.waves) and _same_capture(boss.max_health, before.boss_hp), "Other character's actual quantity/cadence/HP is unchanged: " + String(before.kind))
		dm.clear()
		release(game)

func _test_unchanged_trajectories(controls: Array) -> void:
	var cases: Array = controls.map(func(c): return {"kind": c.kind, "road": false})
	cases.append({"kind": "shizuha_boss", "road": true})
	cases.append({"kind": "hina_boss", "road": true})
	for sample in cases:
		var games: Array = []
		for legacy in [false, true]:
			var game := make_game(sample.kind)
			game.current_level.touhou_difficulty = "lunatic"
			game.active_rows = [0, 1, 2, 3, 4, 5]
			game.board_rows = 6
			game.CELL_SIZE = Vector2(76, 33)
			game.board_size = game.CELL_SIZE * Vector2(9, 6)
			var boss: Dictionary = game.zombies[0]
			boss.x = game._boss_anchor_x(sample.kind)
			boss.touhou_road_boss = sample.road
			boss.touhou_final_preview = sample.road
			boss.touhou_road_spell = sample.road
			var entry: Array = Spells.phases_for(sample.kind, game.current_level)[0].back()
			boss.touhou_encounter.phases = [[entry]]
			boss.touhou_encounter.index = 0
			boss.touhou_encounter.attack = 0
			game.touhou_danmaku = LegacyDanmaku.new(game) if legacy else AuditDanmaku.new(game)
			game._trigger_boss_skill(boss)
			games.append(game)
		for step in [0.0, 0.7, 1.1, 2.0]:
			for game in games: game.touhou_danmaku.update(step)
			var actual = games[0].touhou_danmaku
			var legacy = games[1].touhou_danmaku
			check(_same_capture(actual.bullets, legacy.bullets) and _same_capture(actual.beams, legacy.beams) and _same_capture(actual.waves, legacy.waves), "Road/other trajectories remain exactly legacy on thin boards: " + String(sample.kind))
		for game in games: release(game)
