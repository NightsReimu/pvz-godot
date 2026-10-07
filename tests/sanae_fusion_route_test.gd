extends SceneTree

const Runner = preload("res://scripts/tools/wind_god_fusion_route.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func argument(args: PackedStringArray, key: String, fallback: String) -> String:
	var index: int = args.find(key)
	return args[index + 1] if index >= 0 and index + 1 < args.size() else fallback

func run() -> void:
	check(Runner.STAGES.has("4-23"), "The legal fusion-only whole-route runner must support authored Sanae 4-23")
	if failures:
		quit(1)
		return
	var runner := Runner.new(self)
	var args := OS.get_cmdline_user_args()
	runner.sanae_durable_strategy = args.has("--durable")
	if args.has("--run"):
		var directory: String = argument(args, "--output", "res://output/sanae-4-23/fusion")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		var result: Dictionary = await runner.run_case("4-23", argument(args, "--tier", "easy"), int(argument(args, "--seed", "1777")), float(argument(args, "--cap", "1200")))
		var file := FileAccess.open(directory + "/4-23-" + result.tier + "-" + str(result.seed) + ".json", FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "\t") + "\n")
		file.close()
		check(result.input_failures.is_empty(), "Whole-route input audit preserves actual two materials, normal fusion stats, earned charge and paid manual costs")
		check(result.source_manifest.loaded_sanae_source == 7.5, "Probe records the actually loaded scoped Sanae outgoing source")
		check(result.start_snapshot.combat_bodies == 0 and result.start_snapshot.fusion_bodies == 0, "Whole route begins without any preplanted combat army")
		if result.outcome == "won":
			var roads: Array = result.boss_actors.values().filter(func(actor): return actor.role == "road")
			var finales: Array = result.boss_actors.values().filter(func(actor): return actor.role == "finale")
			check(roads.size() == 1 and finales.size() == 1 and roads[0].uid != finales[0].uid, "A true whole-route win includes independent incomplete-road and fresh finale entities")
			if roads.size() == 1 and finales.size() == 1:
				check(roads[0].first_seen >= 105.0 and finales[0].first_seen >= 300.0, "Native full-route win preserves authored weak-road and finale timing gates")
				check(roads[0].complete and finales[0].complete and finales[0].phase_count == 7 + Runner.TIERS.find(result.tier), "The real winning finale completes every native phase bar")
			check(result.sanae_end_state.fields == 0 and result.sanae_end_state.living_frog_summons == 0 and result.sanae_end_state.frog_marks_on_plants == 0, "Actual victory cleanup retains no owned frog fields, summons or plant marks")
		print("SANAE_FUSION_ROUTE ", JSON.stringify(runner.compact(result)))
		call_deferred("quit", 1 if failures else 0)
		return
	for tier in ["easy", "lunatic"]:
		var g := runner.start("4-23", tier, 905)
		check(g.current_level.id == "4-23" and g.active_rows.size() == 6 and g.water_rows.is_empty(), "The true shrine has six dry lanes")
		check(g.grid.all(func(row): return row.all(func(p): return p == null)), "Sanae fusion route starts with an empty combat grid")
		check(g.support_grid.all(func(row): return row.all(func(p): return p == null)), "The dry shrine receives no invented terrain supports")
		if tier == "lunatic":
			var pool: Array = g._resolved_selection_pool_for_level(g.current_level)
			print("SANAE_MANUAL_POOL ", JSON.stringify({"selected":g.active_cards,"available":pool}))
			check(g.active_cards.size() == 10 and g.active_cards.all(func(card): return pool.has(card)), "Lunatic keeps a genuine legal ten-card selector")
			check(g.active_cards.has("sunflower") and g.active_cards.has("cactus") and g.active_cards.has("mirror_reed"), "Manual fusion route selects unlocked native economy, anti-air and reflection materials")
		else:
			check(g._is_conveyor_level() and runner.count_cards(g) == 3, "Easy retains three real initial belt deliveries")
			check(g.sun_points == 0, "Easy receives no manufactured currency")
		var audit: Array = []
		var materials: Dictionary = {}
		var initial_cards: int = runner.count_cards(g)
		var initial_sun: int = g.sun_points
		runner.place(g, audit, materials)
		check(not audit.is_empty() and runner.audit_combat_grid(g).is_empty(), "First actual preparation produces normal catalogue fusion bodies")
		var consumed: int = 0
		var price: int = 0
		for material in materials:
			consumed += int(materials[material])
			price += int(materials[material]) * g._endless_cost_for_kind(material)
		check(consumed == audit.size() * 2, "Each successful native fusion spends both real materials")
		if g._is_conveyor_level():
			check(initial_cards - runner.count_cards(g) == consumed, "Padded ten-slot conveyor reports actual occupied material consumption")
		else:
			check(initial_sun - g.sun_points == price, "Manual purchase pays native material sun costs")
			check(materials.keys().all(func(material): return float(g.card_cooldowns.get(material, 0)) > 0), "Paid materials enter their actual cooldown")
			check(materials.has("sunflower"), "Manual initial strategy pays for a native sun-producing fusion instead of exhausting its economy on nonproducing bodies")
		for row in g.grid:
			for plant in row:
				if plant == null:
					continue
				check(float(plant.ultimate_charge) == 0 and not bool(plant.ultimate_active), "Initial new fusion charge and active state are native and unfilled")
				var native_health: float = plant.max_health
				plant.max_health = native_health + 1.0
				check(runner.audit_combat_grid(g).has("Altered fusion maximum health"), "Live audit rejects a one-point synthetic maximum-health buff")
				plant.max_health = native_health
		check(runner.input_failures.is_empty(), "Sanae preparation has no missing seed or payment audit violations")
		g._spawn_zombie("bucket_kedama", 2)
		var born: Dictionary = g.zombies.back()
		var observations: Array = g.spawn_log.filter(func(entry): return int(entry.uid) == int(born.uid))
		check(observations.size() == 1 and observations[0].fusion_kind == "bucket_kedama", "Recursive fusion spawn observer counts one true UID and keeps the final equipped recipe")
		await runner.release(g)
	print("Sanae legal fusion-only empty-board/native-economy contracts: ", failures, " failures")
	call_deferred("quit", 1 if failures else 0)
