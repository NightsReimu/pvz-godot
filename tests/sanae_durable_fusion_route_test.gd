extends SceneTree

const Runner = preload("res://scripts/tools/wind_god_fusion_route.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var runner := Runner.new(self)
	check(runner.has_method("graft_protection"), "Opt-in Sanae durability uses the real paid graft action, rather than raising plant stats")
	if failures: quit(1); return
	runner.set("sanae_durable_strategy", true)
	var g := runner.start("4-23", "normal", 1777)
	var placements: Array = []
	var materials: Dictionary = {}
	for frame in range(3000):
		if frame % 30 == 0: await process_frame
		if frame % 5 == 0:
			runner.place(g, placements, materials)
			for row in g.active_rows:
				for col in range(g.COLS):
					if not g._ready_click_ultimate_candidate_at(int(row), col).is_empty():g._try_activate_ultimate(int(row), col)
		g._process(.05)
		if g.battle_state != g.BATTLE_PLAYING: break
	print("DURABLE_NATIVE_FIXTURE ", JSON.stringify({"time":g.level_time,"placed":placements.size(),"held":g.active_cards,"grafts":runner.get("graft_actions").size(),"alive":g.grid.reduce(func(total,row):return total+row.filter(func(p):return p!=null).size(),0)}))
	check(not runner.get("graft_actions").is_empty(), "Naturally delivered protection materials actually graft into existing fusion bodies")
	for action in runner.get("graft_actions"):
		check(action.belt_spent == 1 and action.sun_spent == 0, "Each native conveyor graft consumes exactly one actual held material")
		check(is_equal_approx(action.charge_before, action.charge_after), "A paid graft carries earned charge without filling it")
		check(is_equal_approx(action.health_ratio_before, action.health_ratio_after), "Native graft preserves the prior health ratio instead of giving a free repair")
	check(runner.input_failures.is_empty() and runner.audit_combat_grid(g).is_empty(), "Durable composition uses only native fusion stats and audited held ingredients")
	check(materials.values().reduce(func(total, n): return total + int(n), 0) == placements.size() * 2 + runner.get("graft_actions").size(), "Preparation and graft material ledger accounts for every spent seed")
	await runner.release(g)
	print("Sanae opt-in native durable fusion graft contracts: ", failures, " failures")
	call_deferred("quit", 1 if failures else 0)
