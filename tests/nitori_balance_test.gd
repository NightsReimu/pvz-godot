extends "res://tests/hina_balance_test.gd"

# 4-21 reuses the Wind God native route harness with ravine-specific seat
# choices: lanterns light camouflage, umbrellas shelter rows from the cannon.
const LAYOUT := ["plantern", "healing_gourd", "repeater", "repeater", "healing_gourd", "melon_pult", "torchwood", "wallnut"]

func _run() -> void:
	var base: Dictionary = {}
	for level in GameScript.Defs.LEVELS:
		if level.id == "4-21": base = level.duplicate(true)
	if base.is_empty():
		push_error("4-21 is required for the live balance test")
		quit(1)
		return
	base.custom_level = false
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var only := ""
	for choice in ["easy", "normal", "hard", "lunatic"]:
		if arguments.has("--" + choice): only = choice
	if arguments.has("--prepared") or arguments.has("--prepared-only"):
		for choice in ["easy", "normal", "hard", "lunatic"]:
			if only != "" and choice != only: continue
			await _prepared(base, choice)
	if not arguments.has("--prepared-only"):
		for choice in ["easy", "normal", "hard", "lunatic"]:
			if only != "" and choice != only: continue
			await _test_conveyor_route(base, choice)
	call_deferred("quit", 1 if failures else 0)

func _prepared(base: Dictionary, choice: String) -> void:
	var game := NativeRouteGame.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	game.rng.seed = 921
	var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
	game._begin_level(-1, _manual_cards(level), level)
	game.hide()
	game.battle_intro_timer = 0.0
	game.next_event_index = game.current_level.events.size()
	game.frozen_branch_midboss_spawned = true
	game.frozen_branch_midboss_cleared = true
	game.frozen_branch_progress_locked = false
	var layout: Array = LAYOUT.duplicate()
	if choice == "lunatic": layout[0] = "sunflower"
	for row in game.active_rows:
		for col in range(layout.size()): game.grid[row][col] = game._create_plant(layout[col], row, col)
		if choice == "lunatic":
			var fusion = game._ensure_plant_fusion()
			game.grid[row][2] = game._create_plant(fusion.Fusion.result("repeater", "wallnut"), row, 2)
			game.grid[row][5] = game._create_plant(fusion.Fusion.result("melon_pult", "jasmine_tea"), row, 5)
	game._spawn_zombie_at("nitori_boss", 2, game._boss_anchor_x("nitori_boss"), true)
	var boss: Dictionary = game.zombies.back()
	var peak := 0
	var passed := false
	for frame in range(16000):
		if frame % 30 == 0: await process_frame
		if frame % 60 == 0:
			if choice == "lunatic": _paid_replant(game, layout)
			else: _conveyor_replant(game, layout)
			for row in game.active_rows:
				for col in range(layout.size()): game._try_activate_ultimate(row, col)
		game._process(0.05)
		peak = maxi(peak, game.zombies.size())
		if bool(boss.touhou_encounter.complete):
			passed = true
			break
		if game.battle_state == game.BATTLE_LOST: break
	# Informational: this boss-only fixture skips the stage build-up. At v1.0.176
	# Hina's own Hard fixture also loses, so the gate is the complete routes.
	print("Stage 4-21 prepared six-lane diagnostic %s: finished=%s, %.1fs, phase %d/%d, peak enemies=%d, boss health=%.0f, state=%s, final supports=%d/%d calls, lost plants=%d" % [choice, passed, game.level_time, int(boss.touhou_encounter.index) + 1, boss.touhou_encounter.phases.size(), peak, boss.health, game.battle_state, game.final_reinforcements, game.final_reinforcement_calls, game.lost_plants])
	await _release_game(game)

func _belt_cell(game: Control, kind: String) -> Vector2i:
	# Seeds that 4-19/4-20 never deliver get ravine seats; everything else
	# keeps the shared Wind God policy unchanged.
	var columns: Array = []
	if kind == "plantern": columns = [4, 0, 6]
	elif kind == "spikeweed": columns = [8, 7]
	elif kind == "split_pea": columns = [1, 2, 3]
	if columns.is_empty(): return super._belt_cell(game, kind)
	var best := Vector2i(-1, -1)
	var score := -INF
	for row in game.active_rows:
		var lit := false
		for plant in game.grid[row]:
			if plant != null and game._plant_has_component(plant, "plantern"): lit = true
		var value := _row_pressure(game, row) + (0.0 if kind == "plantern" and lit else 2.0)
		if kind == "split_pea": value = 5.0 / (1.0 + _attack_count(game, row)) + _row_pressure(game, row) * 0.8
		for offset in range(columns.size()):
			var col := int(columns[offset])
			if game.grid[row][col] != null: continue
			var candidate := value - offset * 0.12
			if candidate > score and game._placement_error(kind, row, col) == "":
				score = candidate
				best = Vector2i(row, col)
	return best if best.x >= 0 else super._belt_cell(game, kind)

func _manual_cards(level: Dictionary) -> Array:
	var result: Array = super._manual_cards(level)
	for kind in ["plantern", "umbrella_leaf"]:
		if level.available_plants.has(kind) and not result.has(kind) and result.size() < GameScript.MAX_SEED_SLOTS: result.append(kind)
	return result

func _auto_manual(game: Control) -> int:
	var placements: int = super._auto_manual(game)
	for row in game.active_rows:
		if _attack_count(game, row) < 2 or game.grid[row][6] != null: continue
		if _buy(game, "plantern" if int(row) % 3 == 1 else "umbrella_leaf", Vector2i(row, 6)): placements += 1
	return placements
