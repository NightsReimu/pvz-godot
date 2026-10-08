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
	check(Runner.STAGES.has("4-24"), "The legal fusion-only whole-route runner must support authored Kanako 4-24")
	if failures:
		quit(1)
		return
	var runner := Runner.new(self)
	var args := OS.get_cmdline_user_args()
	if args.has("--run"):
		var directory: String = argument(args, "--output", "res://output/kanako-4-24/fusion")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		var result: Dictionary = await runner.run_case("4-24", argument(args, "--tier", "easy"), int(argument(args, "--seed", "1777")), float(argument(args, "--cap", "1200")))
		var file := FileAccess.open(directory + "/4-24-" + result.tier + "-" + str(result.seed) + ".json", FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "\t") + "\n")
		file.close()
		check(result.input_failures.is_empty(), "Whole-route input audit preserves actual two materials, normal fusion stats, earned charge and paid manual costs")
		check(result.start_snapshot.combat_bodies == 0 and result.start_snapshot.fusion_bodies == 0, "Whole route begins without any preplanted combat army")
		var finales: Array = result.boss_actors.values().filter(func(actor): return actor.role == "finale")
		check(result.boss_actors.values().all(func(actor): return actor.role == "finale"), "No road boss ever appears on stage6")
		if result.outcome == "won":
			check(finales.size() == 1 and finales[0].complete and finales[0].phase_count == 8 + Runner.TIERS.find(result.tier), "The real winning finale completes every native phase bar")
			check(finales.size() == 1 and finales[0].first_seen >= 192.0, "The finale cannot arrive before its authored schedule")
		print("KANAKO_FUSION_ROUTE ", JSON.stringify(runner.compact(result)))
		call_deferred("quit", 1 if failures else 0)
		return
	for tier in ["easy", "lunatic"]:
		var g := runner.start("4-24", tier, 905)
		check(g.current_level.id == "4-24" and g.active_rows.size() == 6 and g.water_rows.is_empty(), "The summit has six dry lanes")
		check(g.grid.all(func(row): return row.all(func(p): return p == null)), "Kanako fusion route starts with an empty combat grid")
		if tier == "lunatic":
			var pool: Array = g._resolved_selection_pool_for_level(g.current_level)
			check(g.active_cards.size() == 10 and g.active_cards.all(func(card): return pool.has(card)), "Lunatic keeps a genuine legal ten-card selector")
			check(g.active_cards.has("sunflower") and g.active_cards.has("torchwood"), "Manual route selects unlocked economy and rope-burning fire")
		else:
			check(g._is_conveyor_level() and runner.count_cards(g) == 3, "Easy retains three real initial belt deliveries")
			check(g.sun_points == 0, "Easy receives no manufactured currency")
		var audit: Array = []
		var materials: Dictionary = {}
		runner.place(g, audit, materials)
		check(not audit.is_empty() and runner.audit_combat_grid(g).is_empty(), "First actual preparation produces normal catalogue fusion bodies")
		check(runner.input_failures.is_empty(), "Kanako preparation has no missing seed or payment audit violations")
		await runner.release(g)
	print("Kanako legal fusion-only empty-board/native-economy contracts: ", failures, " failures")
	call_deferred("quit", 1 if failures else 0)
