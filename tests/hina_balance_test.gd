extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

class NativeRouteGame extends PreviewGame:
	var generated_fusions := 0
	var final_reinforcements := 0
	var final_reinforcement_calls := 0
	var loss_reason := ""
	var lost_plants := 0
	func _remove_dead_plants() -> void:
		for table in [grid, support_grid]:
			for row in table:
				for plant in row:
					if plant != null and float(plant.health) <= 0.0: lost_plants += 1
		super._remove_dead_plants()
	func _lose_level(reason: String = "") -> void:
		loss_reason = reason
		super._lose_level(reason)
	func _spawn_hover_boss_reinforcement(kind: String, phase: int, boss: Dictionary = {}) -> void:
		var ending := zombies.any(func(z): return String(z.kind) == kind and float(z.health) > 0.0 and _is_stage_ending_boss(z))
		var before: int = zombies.size()
		super._spawn_hover_boss_reinforcement(kind, phase, boss)
		if ending:
			final_reinforcement_calls += 1
			for z in zombies.slice(before):
				if _is_enemy_zombie(z) and not _is_boss_kind(String(z.kind)) and not bool(Defs.ZOMBIES.get(String(z.kind), {}).get("boss_summon", false)): final_reinforcements += 1
	func _campaign_fusion_variant(kind: String) -> String:
		# Observe the existing campaign RNG without changing its decisions.
		var variant: String = super._campaign_fusion_variant(kind)
		if variant != kind: generated_fusions += 1
		return variant

func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var stage_id := "8-6" if arguments.has("--stage-8-6") else ("4-19" if arguments.has("--stage-4-19") else "4-20")
	var base: Dictionary = {}
	for level in GameScript.Defs.LEVELS:
		if level.id == stage_id: base = level.duplicate(true)
	if base.is_empty():
		push_error(stage_id + " is required for the live balance test")
		quit(1)
		return
	base.custom_level = false
	if arguments.has("--harness-check"):
		_harness_check(base)
		call_deferred("quit", 1 if failures else 0)
		return
	var road_choice := ""
	if arguments.has("--road-only"): road_choice = "easy"
	elif arguments.has("--road-normal"): road_choice = "normal"
	elif arguments.has("--road-hard"): road_choice = "hard"
	elif arguments.has("--road-lunatic"): road_choice = "lunatic"
	if road_choice != "":
		await _test_conveyor_route(base, road_choice)
		call_deferred("quit", 1 if failures else 0)
		return
	for choice in ["easy", "normal", "hard", "lunatic"]:
		if arguments.has("--full-routes"): break
		var game := NativeRouteGame.new()
		game.size = Vector2(1600, 900)
		root.add_child(game)
		game.rng.seed = 906
		var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
		game._begin_level(-1, _manual_cards(level), level)
		# The separate capture and flow checks render the UI. These long native
		# simulations only need combat; suppress repeated offscreen redraw work.
		game.hide()
		game.battle_intro_timer = 0.0
		game.next_event_index = game.current_level.events.size()
		game.frozen_branch_midboss_spawned = true
		game.frozen_branch_midboss_cleared = true
		game.frozen_branch_progress_locked = false
		# This is the developed six-lane defense at finale arrival. Every plant
		# has its normal native health, attack clock and earned ultimate charge.
		# Repairs use real conveyor deliveries or earned sun/cooldowns below.
		var first: String = "sunflower" if choice == "lunatic" else "kernel_pult"
		var layout: Array = [first, "healing_gourd", "repeater", "repeater", "healing_gourd", "melon_pult", "torchwood", "wallnut"]
		for row in game.active_rows:
			for col in range(layout.size()): game.grid[row][col] = game._create_plant(layout[col], row, col)
			if choice == "lunatic":
				var fusion = game._ensure_plant_fusion()
				game.grid[row][2] = game._create_plant(fusion.Fusion.result("repeater", "wallnut"), row, 2)
				game.grid[row][5] = game._create_plant(fusion.Fusion.result("melon_pult", "jasmine_tea" if level.available_plants.has("jasmine_tea") else "wallnut"), row, 5)
		var finale_kind: String = String(level.events.back().kind)
		game._spawn_zombie_at(finale_kind, 2, game._boss_anchor_x(finale_kind), true)
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
		if not passed:
			failures += 1
			push_error("%s: the real six-lane defense must be able to finish the live finale" % choice)
		print("Stage %s prepared six-lane defense %s: finished=%s, %.1fs, phase %d/%d, peak enemies=%d, boss health=%.0f, earned sun=%d" % [stage_id, choice, passed, game.level_time, int(boss.touhou_encounter.index) + 1, boss.touhou_encounter.phases.size(), peak, boss.health, game.sun_points])
		await _release_game(game)
	for choice in ["easy", "normal", "hard", "lunatic"]: await _test_conveyor_route(base, choice)
	# Let the nested async route and its retained local runtime references
	# unwind before SceneTree tears down the script resources.
	call_deferred("quit", 1 if failures else 0)

func _paid_replant(game: Control, layout: Array) -> void:
	for row in game.active_rows:
		for col in range(layout.size()):
			var plant = game.grid[row][col]
			var kind: String = layout[col] if plant == null else ""
			if plant != null and col == 2 and not plant.has("fusion_kind"): kind = "wallnut"
			if plant != null and col == 5 and not plant.has("fusion_kind"): kind = "jasmine_tea" if game.active_cards.has("jasmine_tea") else "wallnut"
			if kind == "" or not game.active_cards.has(kind) or game.sun_points < game._endless_cost_for_kind(kind) or float(game.card_cooldowns.get(kind, 0.0)) > 0.01: continue
			game.selected_tool = kind
			game._handle_board_click(Vector2i(row, col))

func _conveyor_replant(game: Control, layout: Array) -> void:
	# The belt remains live during the fight. Spend only a delivered seed on
	# an actual empty matching slot through the normal board-click path.
	for index in range(game.active_cards.size() - 1, -1, -1):
		var kind: String = game.active_cards[index]
		var planted := false
		for row in game.active_rows:
			for col in range(layout.size()):
				if game.grid[row][col] != null or String(layout[col]) != kind: continue
				game.selected_tool = kind
				game._handle_board_click(Vector2i(row, col))
				planted = game.grid[row][col] != null
				if planted: break
			if planted: break

func _test_conveyor_route(base: Dictionary, choice: String = "easy") -> void:
	var game := NativeRouteGame.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	game.rng.seed = 906
	var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
	game._begin_level(-1, _manual_cards(level) if choice == "lunatic" else [], level)
	game.hide()
	var plan: Dictionary = game.ZombieBalance.campaign_fusion(game.current_level)
	if plan.is_empty() or int(plan.get("gate", 0)) < 12 or float(plan.get("chance", 0.0)) < 0.18:
		failures += 1
		push_error("The complete route must retain the authored campaign fusion gate and chance")
	var placements := 0
	var peak := 0
	var peak_active := 0
	var show_progress := OS.get_cmdline_user_args().has("--progress")
	var road_seen := false
	var finale_seen := false
	var passed := false
	var boss: Dictionary = {}
	var road: Dictionary = {}
	var last_progress := 0.0
	var road_kind: String = String(level.mid_boss_kind)
	var finale_kind: String = String(level.events.back().kind)
	# Start with the actual empty board and its initial belt. Never alter
	# event progress, plant health, enemy damage or earned ultimate charge.
	for frame in range(24000):
		if frame % 30 == 0: await process_frame
		if frame % 10 == 0:
			placements += _auto_manual(game) if choice == "lunatic" else _auto_belt(game)
			for row in game.active_rows:
				for col in range(9): game._try_activate_ultimate(row, col)
		game._process(0.05)
		peak = maxi(peak, game.zombies.size())
		peak_active = maxi(peak_active, game._active_zombie_count())
		for z in game.zombies:
			if String(z.kind) == road_kind and bool(z.get("touhou_road_boss", false)):
				road_seen = true
				road = z
			if String(z.kind) == finale_kind and game._is_stage_ending_boss(z):
				finale_seen = true
				boss = z
		if show_progress and game.level_time >= last_progress + 120.0:
			last_progress = game.level_time
			print("Stage %s %s progress %.1fs: placements=%d, enemies=%d, shooters=%s, finale_hp=%.0f" % [base.id, choice, game.level_time, placements, game.zombies.size(), _row_attack_counts(game), float(boss.get("health", -1.0))])
		if not boss.is_empty() and bool(boss.touhou_encounter.complete):
			passed = true
		if game.battle_state == game.BATTLE_WON: break
		if game.battle_state == game.BATTLE_LOST: break
	if not passed or game.battle_state != game.BATTLE_WON or not road_seen or not finale_seen or game.generated_fusions <= 0 or game.final_reinforcements <= 0:
		failures += 1
		push_error("%s %s: a zero-preplant native route must beat %s and %s with sustained campaign reinforcement" % [base.id, choice.capitalize(), road_kind, finale_kind])
	if finale_seen and (road.is_empty() or int(road.uid) == int(boss.uid) or float(boss.max_health) <= float(road.max_health) * 8.0):
		failures += 1
		push_error("The finale must be a fresh, full-strength body after the weak road encounter")
	print("Stage %s complete %s route: finished=%s, road=%s, finale=%s, %.1fs, real placements=%d, peak enemies=%d, boss health=%.0f, state=%s, campaign replacements=%d, final supports=%d/%d calls, shooters=%s, used mowers=%d, lost plants=%d, peak active=%d, phase=%d/%d, loss=%s" % [base.id, choice.capitalize(), passed, road_seen, finale_seen, game.level_time, placements, peak, float(boss.get("health", -1.0)), game.battle_state, game.generated_fusions, game.final_reinforcements, game.final_reinforcement_calls, _row_attack_counts(game), game.mowers.filter(func(m): return game._is_row_active(int(m.row)) and not bool(m.armed)).size(), game.lost_plants, peak_active, int(boss.get("touhou_encounter", {}).get("index", -1)) + 1, boss.get("touhou_encounter", {}).get("phases", []).size(), game.loss_reason])
	await _release_game(game)

func _row_pressure(game: Control, row: int) -> float:
	var pressure := 0.0
	for z in game.zombies:
		if int(z.row) != row or float(z.health) <= 0.0 or not game._is_enemy_zombie(z): continue
		var progress := clampf((game.board_size.x - float(z.x) + game.BOARD_ORIGIN.x) / game.board_size.x, 0.0, 1.0)
		pressure += 1.0 + progress * 3.0
	return pressure

func _attack_count(game: Control, row: int) -> int:
	var count := 0
	for plant in game.grid[row]:
		if plant == null: continue
		for source in ["peashooter", "repeater", "threepeater", "snow_pea", "cactus", "melon_pult", "kernel_pult", "starfruit"]:
			if game._plant_has_component(plant, source):
				count += 1
				break
	return count

func _auto_belt(game: Control) -> int:
	var placed := 0
	for index in range(game.active_cards.size() - 1, -1, -1):
		var kind: String = game.active_cards[index]
		if kind == "": continue
		var cell := _belt_cell(game, kind)
		if cell.x < 0: continue
		var before: int = game.active_cards.count(kind)
		game.selected_tool = kind
		game._handle_board_click(cell)
		if game.active_cards.count(kind) < before: placed += 1
	return placed

func _belt_cell(game: Control, kind: String) -> Vector2i:
	var columns: Array = [1, 2, 3, 4, 0, 5]
	if bool(game.current_level.get("suika_banquet", false)) and kind in ["jasmine_tea", "golden_milk"]:
		var sober := _sober_fusion_cell(game, kind)
		if sober.x >= 0: return sober
	if kind in ["wallnut", "tallnut"]: columns = [7, 8, 6]
	elif kind == "torchwood": columns = [5, 6]
	elif kind == "healing_gourd": columns = [6, 0, 4]
	elif kind == "umbrella_leaf": columns = [4, 0]
	elif kind in ["cherry_bomb", "jalapeno", "blover"]:
		var threatening := false
		for z in game.zombies:
			if float(z.health) <= 0.0: continue
			if kind != "blover" or bool(z.get("balloon_flying", false)): threatening = true
		if not threatening: return Vector2i(-1, -1)
		columns = [8, 7, 6, 5, 4, 3, 2, 1, 0]
	elif kind == "pumpkin":
		# Reinforce an existing shooter through the actual available shell or
		# native fusion path; leave the early empty lanes for firing plants.
		for row in game.active_rows:
			for col in [7, 6, 1, 2, 3, 4, 5, 0]:
				if game.grid[row][col] == null: continue
				if game._placement_error(kind, row, col) == "": return Vector2i(row, col)
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var score := -INF
	for row in game.active_rows:
		var attacks := _attack_count(game, row)
		var value := 5.0 / (1.0 + attacks) + _row_pressure(game, row) * 0.8
		if kind in ["torchwood", "healing_gourd", "umbrella_leaf"]: value = attacks * 1.5 + _row_pressure(game, row) * 0.7
		if kind in ["cherry_bomb", "jalapeno", "blover"]: value = _row_pressure(game, row)
		for offset in range(columns.size()):
			var col := int(columns[offset])
			if game.grid[row][col] != null: continue
			var candidate := value - offset * 0.12
			if candidate > score and game._placement_error(kind, row, col) == "":
				score = candidate
				best = Vector2i(row, col)
	if best.x >= 0: return best
	# A full board may spend additional real belt seeds on the game's fusion
	# path. Selecting a fusible seed does not manufacture materials or sun.
	for row in game.active_rows:
		for col in [1, 2, 3, 4, 5, 6, 0, 7, 8]:
			if game.grid[row][col] == null: continue
			if not game._ensure_plant_fusion().candidate(kind, row, col).is_empty() and game._placement_error(kind, row, col) == "": return Vector2i(row, col)
	return Vector2i(-1, -1)

func _buy(game: Control, kind: String, cell: Vector2i) -> bool:
	if not game.active_cards.has(kind) or game.sun_points < game._endless_cost_for_kind(kind) or float(game.card_cooldowns.get(kind, 0.0)) > 0.01: return false
	if game._placement_error(kind, cell.x, cell.y) != "": return false
	var before: int = game.sun_points
	game.selected_tool = kind
	game._handle_board_click(cell)
	return game.sun_points < before

func _auto_manual(game: Control) -> int:
	# Optional full Lunatic probe: buy from an ordinary ten-card selection.
	# No seed, sunshine, recharge or damage is manufactured by this policy.
	var placements := 0
	var sunflower_count := 0
	for row in game.grid:
		for plant in row:
			if plant != null and game._plant_has_component(plant, "sunflower"): sunflower_count += 1
	if sunflower_count < 10:
		for col in [0, 1]:
			for row in game.active_rows:
				if game.grid[row][col] == null and _buy(game, "sunflower", Vector2i(row, col)):
					placements += 1
					break
	var ordered: Array = game.active_rows.duplicate()
	ordered.sort_custom(func(a, b): return _row_pressure(game, int(a)) / (1.0 + _attack_count(game, int(a))) > _row_pressure(game, int(b)) / (1.0 + _attack_count(game, int(b))))
	for row_value in ordered:
		var row := int(row_value)
		var pressure := _row_pressure(game, row)
		if pressure > 0.0 and _attack_count(game, row) < 2:
			for col in [2, 3]:
				if game.grid[row][col] == null and _buy(game, "peashooter", Vector2i(row, col)): placements += 1
		if pressure > 1.0 and game.grid[row][7] == null and _buy(game, "wallnut", Vector2i(row, 7)): placements += 1
		if _attack_count(game, row) < 2: continue
		for pair in [["healing_gourd", 4], ["repeater", 3], ["melon_pult", 5], ["torchwood", 6]]:
			var kind: String = pair[0]
			var col := int(pair[1])
			if game.grid[row][col] == null and _buy(game, kind, Vector2i(row, col)): placements += 1
		for col in [2, 3]:
			var plant = game.grid[row][col]
			if plant != null and not game._plant_has_component(plant, "wallnut") and _buy(game, "wallnut", Vector2i(row, col)): placements += 1
		var melon = game.grid[row][5]
		if melon != null and not game._plant_has_component(melon, "jasmine_tea") and _buy(game, "jasmine_tea", Vector2i(row, 5)): placements += 1
	return placements

func _release_game(game: Control) -> void:
	game._stop_bgm()
	if game.music_player != null: game.music_player.stream = null
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game.save_dirty = false
	await create_timer(0.3).timeout
	game.free()
	await create_timer(0.15).timeout
	await process_frame

func _manual_cards(level: Dictionary) -> Array:
	var result: Array = []
	var allowed: Array = level.available_plants.duplicate()
	# Touhou manual selection always includes these genuine UI essentials.
	if bool(level.get("touhou_seed_selection", false)):
		for kind in ["sunflower", "sun_shroom"]:
			if not allowed.has(kind): allowed.append(kind)
	for kind in ["sunflower", "peashooter", "repeater", "healing_gourd", "melon_pult", "torchwood", "wallnut", "jasmine_tea", "golden_milk", "magnet_shroom", "cherry_bomb", "cactus", "blover"]:
		if allowed.has(kind) and result.size() < GameScript.MAX_SEED_SLOTS: result.append(kind)
	return result

func _row_attack_counts(game: Control) -> Array:
	var counts: Array = []
	for row in game.active_rows: counts.append(_attack_count(game, row))
	return counts

func _harness_check(base: Dictionary) -> void:
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var level: Dictionary = GameScript.TouhouDifficulty.build_level(base, choice)
		var cards: Array = _manual_cards(level)
		if cards.size() > GameScript.MAX_SEED_SLOTS or cards.any(func(kind): return not level.available_plants.has(kind) and not (bool(level.get("touhou_seed_selection", false)) and kind in ["sunflower", "sun_shroom"])):
			failures += 1
			push_error("Manual route selection must use only the stage's legal card pool")
		if String(level.mid_boss_kind) != ("suika_boss" if base.id == "8-6" else ("shizuha_boss" if base.id == "4-19" else "hina_boss")) or String(level.events.back().kind) != ("suika_boss" if base.id == "8-6" else ("minoriko_boss" if base.id == "4-19" else "hina_boss")):
			failures += 1
			push_error("The reusable route must preserve each stage's actual road and finale identities")
		print("Harness %s %s: road=%s finale=%s manual_cards=%s" % [base.id, choice, level.mid_boss_kind, level.events.back().kind, cards])

func _sober_fusion_cell(game: Control, material: String) -> Vector2i:
	# Spend only a real delivered or paid tea/milk material on an existing
	# shooter. A native milk bottle on bare soil vanishes after its one wave;
	# grafting it supplies persistent wine protection and its normal reload.
	var best := Vector2i(-1, -1)
	var score := -INF
	for row in game.active_rows:
		for col in [2, 3, 5, 1, 4, 0, 6]:
			var plant = game.grid[row][col]
			if plant == null or game._plant_has_component(plant, "jasmine_tea") or game._plant_has_component(plant, "golden_milk"): continue
			if not ["peashooter", "repeater", "threepeater", "melon_pult", "kernel_pult", "snow_pea", "dandelion"].any(func(k): return game._plant_has_component(plant, k)): continue
			if game._ensure_plant_fusion().candidate(material, row, col).is_empty() or game._placement_error(material, row, col) != "": continue
			var protected: bool = game.suika_runtime != null and game.suika_runtime.protected_cell(row, col)
			var value := (0.0 if protected else 10.0) + _row_pressure(game, row) + (2.0 if col in [2, 3] else 0.0)
			if value > score:
				score = value
				best = Vector2i(row, col)
	return best
