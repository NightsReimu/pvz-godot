extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var passed := true
	passed = _test_spell_recovers_and_telegraphs() and passed
	passed = _test_hover_preserves_spell_and_expires_pose() and passed
	passed = _test_defeated_boss_cannot_cast() and passed
	passed = _test_successor_clears_pending_cast() and passed
	passed = _test_pause_preserves_particles() and passed
	passed = _test_common_impacts_do_not_shake() and passed
	passed = _test_health_trail_settles_and_heals() and passed
	passed = _test_hud_layouts() and passed
	passed = _test_particle_budget_and_restart() and passed
	passed = _test_pose_groups_play_complete_sequences() and passed
	passed = _test_phase_cancels_pending_spell() and passed
	passed = _test_sun_ultimates_land_on_board() and passed
	quit(0 if passed else 1)


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition


func _make_game() -> Control:
	var game := GameScript.new()
	game.size = Vector2(1600, 900)
	game.current_level = {"id": "flow-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	for row in range(6):
		var cells: Array = []
		cells.resize(9)
		game.grid.append(cells)
		game.support_grid.append(cells.duplicate())
	game.rng.seed = 905
	game._spawn_zombie_at("rumia_boss", 2, game._boss_anchor_x("rumia_boss"), true)
	game.zombies[0]["rumia_reinforcement_timer"] = 100.0
	game.zombies[0]["hover_shift_timer"] = 100.0
	return game


func _free_game(game: Control) -> void:
	game.toast_label.free()
	game.banner_label.free()
	game.save_dirty = false
	game.free()


func _test_spell_recovers_and_telegraphs() -> bool:
	var game := _make_game()
	game.zombies[0]["boss_pause_timer"] = 1.5
	game.zombies[0]["boss_skill_timer"] = 0.1
	game._update_zombies(0.2)
	var passed := _check(int(game.zombies[0]["boss_skill_cycle"]) == 0, "boss must finish recovery before casting")
	game._update_zombies(1.4)
	passed = _check(bool(game.zombies[0].get("boss_cast_pending", false)), "expired cooldown must begin a visible windup") and passed
	passed = _check(int(game.zombies[0]["boss_skill_cycle"]) == 0, "starting windup must not release damage in the same frame") and passed
	game._update_zombies(0.3)
	passed = _check(int(game.zombies[0]["boss_skill_cycle"]) == 0, "windup should leave time to react") and passed
	game._update_zombies(0.6)
	passed = _check(int(game.zombies[0]["boss_skill_cycle"]) == 1, "windup must release exactly one spell") and passed
	passed = _check(not bool(game.zombies[0].get("boss_cast_pending", false)), "released spell must clear its pending cast") and passed
	_free_game(game)
	return passed


func _test_hover_preserves_spell_and_expires_pose() -> bool:
	var game := _make_game()
	var passed := true
	for kind in ["rumia_boss", "prismriver_boss", "youmu_boss", "yuyuko_boss"]:
		var boss: Dictionary = game.zombies[0].duplicate(true)
		boss["kind"] = kind
		boss["rumia_state"] = "phase"
		boss["rumia_state_timer"] = 0.8
		boss["hover_shift_timer"] = 0.0
		boss["boss_pause_timer"] = 0.0
		boss = game._update_hovering_boss(boss, 0.1)
		passed = _check(String(boss["rumia_state"]) == "phase" and int(boss["row"]) == 2, "%s autonomous movement must not interrupt a spell" % kind) and passed
		boss["hover_shift_timer"] = 100.0
		boss = game._update_hovering_boss(boss, 1.0)
		passed = _check(String(boss["rumia_state"]) == "idle", "%s timed spell pose must expire" % kind) and passed
		boss["rumia_state"] = "phase"
		boss["rumia_state_timer"] = 0.1
		boss = game._update_hovering_boss(boss, 0.2)
		passed = _check(String(boss["rumia_state"]) == "idle", "%s expired spell must return to idle without relying on a shift" % kind) and passed
	_free_game(game)
	return passed


func _test_defeated_boss_cannot_cast() -> bool:
	var game := _make_game()
	game.zombies[0]["health"] = 0.0
	game.zombies[0]["boss_skill_timer"] = 0.0
	game.effects.clear()
	game._update_zombies(0.1)
	var passed := _check(game.effects.is_empty() and game.zombies.size() == 1, "defeated boss must not phase-shift, summon, or cast before cleanup")
	_free_game(game)
	return passed


func _test_successor_clears_pending_cast() -> bool:
	var game := _make_game()
	var boss: Dictionary = game.zombies[0].duplicate(true)
	boss["kind"] = "ran_boss"
	boss["boss_cast_pending"] = true
	boss["boss_pause_timer"] = 0.0
	boss["corrode_timer"] = 4.0
	boss["corrode_dps"] = 120.0
	boss["boss_hud_trail"] = 0.1
	var successor: Dictionary = game._trigger_ran_boss_successor(boss)
	var passed := _check(not bool(successor.get("boss_cast_pending", false)), "Yukari must not inherit Ran's pending cast")
	passed = _check(float(successor.get("corrode_timer", 0.0)) == 0.0, "Yukari must not inherit Ran's corrosion") and passed
	passed = _check(float(successor.get("boss_pause_timer", 0.0)) >= 1.35, "successor arrival must have a recovery window") and passed
	passed = _check(not successor.has("boss_hud_trail"), "successor health display must start fresh") and passed
	var revived: Dictionary = game._trigger_yuyuko_boss_revival({"kind": "yuyuko_boss", "row": 2, "health": 0.0, "max_health": 1000.0, "boss_cast_pending": true})
	passed = _check(not bool(revived.get("boss_cast_pending", false)), "revival must clear the interrupted pending cast") and passed
	_free_game(game)
	return passed


func _test_pause_preserves_particles() -> bool:
	var game := _make_game()
	game.mode = game.MODE_BATTLE
	game.battle_paused = true
	game.screen_shake_amount = 4.0
	game.vfx_particles = [{"pos": Vector2(20, 20), "vel": Vector2(10, 10), "life": 0.5, "max_life": 0.5}]
	game._process(0.2)
	var passed := _check(is_equal_approx(float(game.vfx_particles[0]["life"]), 0.5), "pause must preserve particle lifetime")
	passed = _check(Vector2(game.vfx_particles[0]["pos"]) == Vector2(20, 20), "pause must preserve particle position") and passed
	passed = _check(is_equal_approx(game.screen_shake_amount, 4.0), "pause must preserve remaining shake") and passed
	_free_game(game)
	return passed


func _test_common_impacts_do_not_shake() -> bool:
	var game := _make_game()
	game.screen_shake_amount = 0.0
	game._emit_projectile_impact_feedback(Vector2(500, 300), {"kind": "pea", "damage": 20.0})
	var passed := _check(game.screen_shake_amount == 0.0, "ordinary pea hits should use local impact feedback without constant screen shake")
	passed = _check(game.vfx_particles.size() >= 4, "ordinary hits must retain readable particles") and passed
	_free_game(game)
	return passed


func _test_health_trail_settles_and_heals() -> bool:
	var runtime = GameScript.ZombieRuntime
	var boss: Dictionary = runtime.update_boss_health_display({"health": 1000.0, "max_health": 1000.0}, 0.01)
	boss["health"] = 600.0
	boss = runtime.update_boss_health_display(boss, 0.016)
	var passed := _check(float(boss["boss_hud_trail"]) > 0.6, "damage must leave a visible health trail")
	for frame in range(90):
		boss = runtime.update_boss_health_display(boss, 1.0 / 60.0)
	passed = _check(is_equal_approx(float(boss["boss_hud_trail"]), 0.6), "health trail must settle after damage") and passed
	boss["health"] = 900.0
	boss = runtime.update_boss_health_display(boss, 0.016)
	passed = _check(float(boss["boss_hud_trail"]) >= 0.9 and is_equal_approx(float(boss["boss_hud_health"]), 0.9), "healing must update the real bar immediately") and passed
	return passed


func _test_hud_layouts() -> bool:
	var passed := true
	for viewport in [Vector2(1600, 900), Vector2(1365, 768), Vector2(1920, 1080), Vector2(2400, 1080)]:
		for rows in [5, 6]:
			var game := _make_game()
			game.board_rows = rows
			game.size = viewport
			game.mobile_runtime_override = 1 if viewport.x > 2000 else 0
			game._refresh_battle_layout()
			var layout: Dictionary = game._boss_health_bar_layout(game.zombies[0])
			var board: Rect2 = Rect2(game.BOARD_ORIGIN, game.board_size)
			for key in ["rect", "name_rect", "status_rect", "health_rect", "cast_rect"]:
				var region: Rect2 = layout[key]
				passed = _check(Rect2(Vector2.ZERO, viewport).encloses(region), "%s should fit %s (%d rows)" % [key, viewport, rows]) and passed
				passed = _check(not board.intersects(region), "%s must not cover the board at %s (%d rows)" % [key, viewport, rows]) and passed
			passed = _check(not Rect2(layout["name_rect"]).intersects(layout["status_rect"]), "boss name and cast status must not overlap") and passed
			var hud_regions = [game.SEED_BANK_RECT, game.WAVE_BAR_RECT, game.PLANT_FOOD_RECT, game.COIN_METER_RECT, game.PAUSE_BUTTON_RECT, game.BACK_BUTTON_RECT]
			for i in range(hud_regions.size()):
				passed = _check(Rect2(Vector2.ZERO, viewport).encloses(hud_regions[i]), "battle HUD must fit the viewport") and passed
				for j in range(i + 1, hud_regions.size()):
					passed = _check(not Rect2(hud_regions[i]).intersects(hud_regions[j]), "battle HUD controls %d and %d overlap at %s" % [i, j, viewport]) and passed
			game.active_cards.resize(10)
			passed = _check(game.SEED_BANK_RECT.encloses(game._shovel_rect()), "ten cards and shovel must fit the seed bank") and passed
			game.current_level["objective"] = {"type": "no_mower"}
			game._refresh_battle_layout()
			var objective_rect: Rect2 = game._objective_chip_rect()
			passed = _check(not objective_rect.intersects(Rect2(game.BOARD_ORIGIN, game.board_size)), "challenge objective must sit above the board") and passed
			for hud_rect in hud_regions:
				passed = _check(not objective_rect.intersects(hud_rect), "challenge objective must not overlap HUD controls") and passed
			_free_game(game)
	return passed


func _test_particle_budget_and_restart() -> bool:
	var game := _make_game()
	for i in range(500):
		game.vfx_particles.append({"pos": Vector2.ZERO, "vel": Vector2.ZERO, "life": 1.0})
	game._update_combat_particles(0.016)
	var passed := _check(game.vfx_particles.size() <= game.MAX_COMBAT_PARTICLES, "decorative particles must remain bounded")
	game.message_panel = PanelContainer.new()
	game.screen_shake_amount = 8.0
	game._begin_level(-1, ["peashooter"], {"id": "restart-test", "title": "", "terrain": "day", "events": [], "start_sun": 100, "custom_level": true})
	passed = _check(game.vfx_particles.is_empty() and game.screen_shake_amount == 0.0, "restarting must clear particles and shake") and passed
	game.message_panel.free()
	_free_game(game)
	return passed


func _test_pose_groups_play_complete_sequences() -> bool:
	var game := _make_game()
	var passed := true
	var expected = [6, 7, 8, 15, 16, 17, 6]
	for i in range(expected.size()):
		game.level_time = float(i) / 8.0
		passed = _check(game._boss_pose_cycle_frame([2, 5], 8.0, 0.0) == expected[i], "boss animation should finish all subframes before changing pose") and passed
	_free_game(game)
	return passed


func _test_phase_cancels_pending_spell() -> bool:
	var game := _make_game()
	game.zombies[0]["health"] = float(game.zombies[0]["max_health"]) * 0.7
	game.zombies[0]["boss_cast_pending"] = true
	game.zombies[0]["boss_skill_timer"] = 0.01
	game._update_zombies(0.2)
	var boss: Dictionary = game.zombies[0]
	var passed := _check(int(boss["boss_phase"]) == 1 and not bool(boss["boss_cast_pending"]), "phase transition must interrupt the old pending spell")
	passed = _check(int(boss["boss_skill_cycle"]) == 0 and String(boss["rumia_state"]) == "phase", "phase transition must play before the next spell") and passed
	_free_game(game)
	return passed


func _test_sun_ultimates_land_on_board() -> bool:
	var game := _make_game()
	var passed := true
	for kind in ["honey_blossom", "solar_emperor"]:
		game.suns.clear()
		var plant: Dictionary = game._create_plant(kind, 2, 1)
		game._execute_ultimate(plant, kind, 2, 1, game._ultimate_profile_for_kind(kind))
		passed = _check(game.suns.size() == (5 if kind == "honey_blossom" else 15), "sun ultimate must complete its resource burst") and passed
		for sun in game.suns:
			var landing = Vector2(Vector2(sun["position"]).x, float(sun["target_y"]))
			passed = _check(Rect2(game.BOARD_ORIGIN, game.board_size).has_point(landing), "ultimate sunlight must land inside the battle board") and passed
	_free_game(game)
	return passed
