extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _stage() -> Dictionary:
	for level in GameScript.Defs.LEVELS:
		if level.id == "4-21": return level.duplicate(true)
	return {}

func _game(choice: String, viewport := Vector2(1600, 900)) -> Control:
	var base := _stage()
	base.custom_level = true
	var game := PreviewGame.new()
	game.size = viewport
	game.mobile_runtime_override = 1 if viewport.y < 600 else 0
	root.add_child(game)
	game._begin_level(-1, ["repeater", "wallnut", "plantern", "umbrella_leaf", "melon_pult"], game.TouhouDifficulty.build_level(base, choice))
	game.battle_intro_timer = 0.0
	for row in range(6):
		for col in range(6):
			game.grid[row][col] = game._create_plant(["repeater", "repeater", "melon_pult", "wallnut", "umbrella_leaf", "wallnut"][col], row, col)
	return game

func _select(boss: Dictionary, pattern: String) -> bool:
	var encounter: Dictionary = boss.touhou_encounter
	for phase in range(encounter.phases.size()):
		for attack in range(encounter.phases[phase].size()):
			if String(encounter.phases[phase][attack][2]) == pattern:
				encounter.index = phase
				encounter.attack = attack
				encounter.completed = attack
				GameScript.TouhouPhaseRuntime._set_bounds(boss)
				boss.health = encounter.ceiling
				return true
	return false

func _run() -> void:
	if _stage().is_empty():
		push_error("4-21 is required")
		quit(1)
		return
	var patterns_by_choice := {
		"easy": ["nonspell_nitori_jet", "nitori_ooze_flooding", "nitori_pororoca", "nitori_spook_cucumber", "nitori_camo_squad", "finale_nitori_1", "finale_nitori_2"],
		"normal": ["nitori_cucumber_bait"],
		"hard": ["nitori_diluvial_mare", "nitori_flash_flood", "nitori_extend_arm", "nitori_water_cannon"],
		"lunatic": ["nitori_glimmering_trauma", "nitori_great_waterfall", "nitori_cephalic_plate", "nitori_workshop"],
	}
	for viewport in [Vector2(1600, 900), Vector2(844, 390)]:
		for choice in patterns_by_choice:
			for pattern in patterns_by_choice[choice]:
				var game := _game(choice, viewport)
				game._spawn_zombie_at("nitori_boss", 2, game._boss_anchor_x("nitori_boss"), true)
				var boss: Dictionary = game.zombies.back()
				check(_select(boss, pattern), "%s reaches %s" % [choice, pattern])
				game._trigger_boss_skill(boss)
				var dm = game.touhou_danmaku
				var emitted := 0
				var beams := 0
				var hits_before := 0.0
				for row in range(6):
					for col in range(6): hits_before += float(game.grid[row][col].health) if game.grid[row][col] != null else 0.0
				var top_or_bottom := false
				for frame in range(240):
					game.level_time += 0.025
					dm.update(0.025)
					game._ensure_nitori_runtime().update(0.025)
					emitted = maxi(emitted, dm.bullets.size())
					beams = maxi(beams, dm.beams.size())
					for b in dm.bullets:
						var y := Vector2(b.position).y
						if y < game.BOARD_ORIGIN.y + game.CELL_SIZE.y * 0.3 or y > game.BOARD_ORIGIN.y + game.board_size.y - game.CELL_SIZE.y * 0.3: top_or_bottom = true
				var hits_after := 0.0
				for row in range(6):
					for col in range(6): hits_after += float(game.grid[row][col].health) if game.grid[row][col] != null else 0.0
				check(emitted > 0, "%s %s actually emits danmaku at %s" % [choice, pattern, viewport])
				check(dm.bullets.all(func(b): return String(b.shape).begins_with("nitori_") or String(b.shape) == "orb"), "%s uses Nitori's own water/cucumber/plate bullets" % pattern)
				if pattern in ["nitori_extend_arm"]: check(beams > 0, "Extend Arm telegraphs real arm beams")
				if pattern in ["nitori_ooze_flooding", "nitori_diluvial_mare", "nitori_great_waterfall"]: check(top_or_bottom, pattern + " floods in from the board edges")
				if pattern in ["nonspell_nitori_jet", "nitori_flash_flood", "nitori_great_waterfall", "nitori_cephalic_plate"]: check(hits_after < hits_before, "%s reaches and damages real plants at %s" % [pattern, viewport])
				var rt = game._ensure_nitori_runtime()
				if pattern == "nitori_camo_squad": check(game.zombies.any(func(z): return bool(z.get("nitori_camo", false))), "The camo squad spawns hidden units")
				if pattern in ["nitori_cucumber_bait", "nitori_workshop"]: check(game.zombies.any(func(z): return String(z.kind) == "nitori_cucumber"), pattern + " grows cucumber bait")
				if pattern in ["nitori_water_cannon", "nitori_workshop"]: check(not rt.soaked.is_empty(), pattern + " soaks a planted row")
				if pattern in ["nitori_camo_squad", "nitori_workshop"]: check(rt.boss_camouflaged(boss), pattern + " wraps the boss in camouflage while casting")
				# Owner death removes summons without paying any sun.
				var suns: int = game.suns.size()
				boss.touhou_encounter.complete = true
				boss.health = 0.0
				game.touhou_danmaku.clear_owner(int(boss.get("touhou_owner", -1)))
				game._cleanup_dead_zombies()
				game._cleanup_dead_zombies()
				check(not game.zombies.any(func(z): return String(z.kind) == "nitori_cucumber" and float(z.health) > 0.0) and rt.jets.is_empty() and rt.baits.is_empty(), pattern + ": owner defeat clears cucumbers and jets")
				check(game.suns.size() == suns, pattern + ": cleanup never pays cucumber sun")
				await _release(game)
	# Time stop and reset.
	var game := _game("hard")
	game._spawn_zombie_at("nitori_boss", 2, game._boss_anchor_x("nitori_boss"), true)
	var boss: Dictionary = game.zombies.back()
	var rt = game._ensure_nitori_runtime()
	rt.queue_jet(int(boss.uid), 3)
	game.boss_time_stop_timer = 1.0
	rt.update(1.0)
	check(float(rt.jets[0].age) == 0.0, "Time stop freezes the water-cannon warning")
	game.boss_time_stop_timer = 0.0
	rt.update(0.2)
	check(float(rt.jets[0].age) > 0.0, "The warning resumes after time stop")
	rt.reset()
	check(rt.jets.is_empty() and rt.soaked.is_empty() and rt.cucumbers.is_empty(), "Reset clears all Nitori board state")
	# Frames map every authored action onto valid supplied poses.
	for action in GameScript.TouhouSpriteDefs.NitoriSpriteDefs.ACTIONS:
		for frame in GameScript.TouhouSpriteDefs.NitoriSpriteDefs.ACTIONS[action]: check(int(frame) >= 0 and int(frame) < 24, "Pose %s uses a supplied frame" % action)
	for pose in ["camouflage", "flood", "waterfall", "cucumber", "arm", "spin", "cannon", "workshop", "final", "shot", "phase"]:
		check(GameScript.TouhouSpriteDefs.NitoriSpriteDefs.ACTIONS.has(pose), "Card pose %s is animated" % pose)
	await _release(game)
	print("Nitori emissions, board mechanics, cleanup, time stop and poses: %d failure(s)" % failures)
	call_deferred("quit", 1 if failures else 0)

func _release(game: Control) -> void:
	game._stop_bgm()
	if game.music_player != null: game.music_player.stream = null
	game.save_dirty = false
	await create_timer(0.1).timeout
	game.free()
	await process_frame
