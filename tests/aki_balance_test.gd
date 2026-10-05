extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

func _run() -> void:
	var base: Dictionary = {}
	for level in GameScript.Defs.LEVELS:
		if level.id == "4-19": base = level.duplicate(true)
	if base.is_empty():
		push_error("4-19 is required for the four-difficulty live balance test")
		quit(1)
		return
	base.custom_level = true
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var road_choice := ""
	if arguments.has("--road-only"): road_choice = "easy"
	elif arguments.has("--road-normal"): road_choice = "normal"
	elif arguments.has("--road-hard"): road_choice = "hard"
	if road_choice != "":
		await _test_conveyor_route(base, road_choice)
		call_deferred("quit", 1 if failures else 0)
		return
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var game := PreviewGame.new()
		game.size = Vector2(1600, 900)
		root.add_child(game)
		game.rng.seed = 905
		var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
		game._begin_level(-1, ["sunflower", "repeater", "healing_gourd", "melon_pult", "torchwood", "wallnut", "jasmine_tea"], level)
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
		for row in range(6):
			for col in range(layout.size()): game.grid[row][col] = game._create_plant(layout[col], row, col)
			if choice == "lunatic":
				var fusion = game._ensure_plant_fusion()
				game.grid[row][2] = game._create_plant(fusion.Fusion.result("repeater", "wallnut"), row, 2)
				game.grid[row][5] = game._create_plant(fusion.Fusion.result("melon_pult", "jasmine_tea"), row, 5)
		game._spawn_zombie_at("minoriko_boss", 2, game._boss_anchor_x("minoriko_boss"), true)
		var boss: Dictionary = game.zombies.back()
		var peak := 0
		var passed := false
		for frame in range(16000):
			if frame % 30 == 0: await process_frame
			if frame % 60 == 0:
				if choice == "lunatic": _paid_replant(game, layout)
				else: _conveyor_replant(game, layout)
				for row in range(6):
					for col in range(layout.size()): game._try_activate_ultimate(row, col)
			game._process(0.05)
			peak = maxi(peak, game.zombies.size())
			if bool(boss.touhou_encounter.complete):
				passed = true
				break
			if game.battle_state == game.BATTLE_LOST: break
		if not passed:
			failures += 1
			push_error("%s: the real six-lane defense must be able to finish Minoriko's live fight" % choice)
		print("Aki prepared six-lane defense %s: finished=%s, %.1fs, phase %d/%d, peak enemies=%d, boss health=%.0f, earned sun=%d" % [choice, passed, game.level_time, int(boss.touhou_encounter.index) + 1, boss.touhou_encounter.phases.size(), peak, boss.health, game.sun_points])
		game._stop_bgm()
		game.music_player.stream = null
		game.save_dirty = false
		await create_timer(0.15).timeout
		game.free()
		await process_frame
	await _test_conveyor_route(base)
	# Let the nested async route and its retained local runtime references
	# unwind before SceneTree tears down the script resources.
	call_deferred("quit", 1 if failures else 0)

func _paid_replant(game: Control, layout: Array) -> void:
	for row in range(6):
		for col in range(layout.size()):
			var plant = game.grid[row][col]
			var kind: String = layout[col] if plant == null else ""
			if plant != null and col == 2 and not plant.has("fusion_kind"): kind = "wallnut"
			if plant != null and col == 5 and not plant.has("fusion_kind"): kind = "jasmine_tea"
			if kind == "" or game.sun_points < game._endless_cost_for_kind(kind) or float(game.card_cooldowns.get(kind, 0.0)) > 0.01: continue
			game.selected_tool = kind
			game._handle_board_click(Vector2i(row, col))

func _conveyor_replant(game: Control, layout: Array) -> void:
	# The belt remains live during the fight. Spend only a delivered seed on
	# an actual empty matching slot through the normal board-click path.
	for index in range(game.active_cards.size() - 1, -1, -1):
		var kind: String = game.active_cards[index]
		var planted := false
		for row in range(6):
			for col in range(layout.size()):
				if game.grid[row][col] != null or String(layout[col]) != kind: continue
				game.selected_tool = kind
				game._handle_board_click(Vector2i(row, col))
				planted = game.grid[row][col] != null
				if planted: break
			if planted: break

func _test_conveyor_route(base: Dictionary, choice: String = "easy") -> void:
	var game := PreviewGame.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	game.rng.seed = 905
	var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
	game._begin_level(-1, [], level)
	game.hide()
	var placements := 0
	var peak := 0
	var road_seen := false
	var finale_seen := false
	var passed := false
	var boss: Dictionary = {}
	# Start with the actual empty board and its initial belt. Never alter
	# event progress, plant health, enemy damage or earned ultimate charge.
	for frame in range(24000):
		if frame % 30 == 0: await process_frame
		if frame % 10 == 0:
			placements += _auto_belt(game)
			for row in range(6):
				for col in range(9): game._try_activate_ultimate(row, col)
		game._process(0.05)
		peak = maxi(peak, game.zombies.size())
		for z in game.zombies:
			if String(z.kind) == "shizuha_boss": road_seen = true
			if String(z.kind) == "minoriko_boss":
				finale_seen = true
				boss = z
		if not boss.is_empty() and bool(boss.touhou_encounter.complete):
			passed = true
		if game.battle_state == game.BATTLE_WON: break
		if game.battle_state == game.BATTLE_LOST: break
	if not passed or game.battle_state != game.BATTLE_WON or not road_seen or not finale_seen:
		failures += 1
		push_error("%s: a zero-preplant real conveyor route must beat Shizuha and Minoriko without bypassing the road" % choice.capitalize())
	print("Aki complete %s conveyor route: finished=%s, road=%s, finale=%s, %.1fs, real placements=%d, peak enemies=%d, boss health=%.0f, state=%s" % [choice.capitalize(), passed, road_seen, finale_seen, game.level_time, placements, peak, float(boss.get("health", -1.0)), game.battle_state])
	game._stop_bgm()
	game.music_player.stream = null
	game.save_dirty = false
	await create_timer(0.15).timeout
	game.free()
	await process_frame

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
		for row in range(6):
			for col in [7, 6, 1, 2, 3, 4, 5, 0]:
				if game.grid[row][col] == null: continue
				if game._placement_error(kind, row, col) == "": return Vector2i(row, col)
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	var score := -INF
	for row in range(6):
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
	for row in range(6):
		for col in [1, 2, 3, 4, 5, 6, 0, 7, 8]:
			if game.grid[row][col] == null: continue
			if not game._ensure_plant_fusion().candidate(kind, row, col).is_empty() and game._placement_error(kind, row, col) == "": return Vector2i(row, col)
	return Vector2i(-1, -1)
