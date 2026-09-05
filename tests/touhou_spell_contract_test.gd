extends SceneTree

const Game = preload("res://scripts/game.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func make_game(kind: String = "cirno_boss", cycle: int = 0) -> Control:
	var game = Game.new()
	game.size = Vector2(1600, 900)
	game.current_level = {"id": "spell-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.banner_label = Label.new()
	game.toast_label = Label.new()
	for row in range(6):
		var cells: Array = []
		cells.resize(9)
		game.grid.append(cells)
		game.support_grid.append(cells.duplicate())
	game.rng.seed = 906
	game._spawn_zombie_at(kind, 2, game._boss_anchor_x(kind), true)
	game.zombies[0]["boss_skill_cycle"] = cycle
	game.zombies[0]["hover_shift_timer"] = 100.0
	game.zombies[0]["rumia_reinforcement_timer"] = 100.0
	return game


func release(game: Control) -> void:
	game.save_dirty = false
	game.toast_label.free()
	game.banner_label.free()
	game.free()


func _run() -> void:
	_test_catalogue()
	_test_card_animation_poses()
	_test_midboss_patterns()
	_test_every_spell_has_live_pattern()
	_test_freeze_and_time_stop()
	_test_collision_and_reflection()
	_test_bullets_outlive_emission()
	_test_clones_and_successor_cleanup()
	_test_final_survival()
	_test_charm_blocks_all_normal_actions()
	_test_charm_layers_and_expiry()
	_test_wraith_respects_control()
	print("Touhou spell contracts: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)


func _test_catalogue() -> void:
	for kind in ["flandre_boss", "ran_boss", "yukari_boss"]:
		var start = 55 if kind == "flandre_boss" else (119 if kind == "ran_boss" else 131)
		var count = 11 if kind == "yukari_boss" else 10
		var entries: Array = Spells.CARDS[kind]
		check(entries.size() == count, "%s must include the complete Extra/Phantasm spell sequence" % kind)
		for index in range(entries.size()):
			check(String(entries[index][0]) == ("th06-%02d" if kind == "flandre_boss" else "th07-%03d") % (start + index), "Extra/Phantasm spell order must match the original")
	for kind in ["daiyousei_boss", "koakuma_boss", "lily_white_boss"]:
		check(Spells.card_for({"kind": kind}).origin == "nonspell", "unnamed midboss attacks must not become invented spell cards")
	check(Spells.card_for({"kind": "youmu_boss", "boss_skill_cycle": 5}).origin == "original", "preserve NightsReimu's original wraith charm card")
	check(Spells.card_for({"kind": "sakuya_boss"}, {"mid_boss_kind": "sakuya_boss"}).id == "th06-41", "stage 6 Sakuya must use Eternal Meek")
	check(Spells.card_for({"kind": "chen_boss"}, {"mid_boss_kind": "chen_boss"}).id == "th07-117", "Extra Chen must use her Extra cards")
	check(Spells.card_for({"kind": "youmu_boss"}, {"mid_boss_kind": "youmu_boss"}).id == "th07-090", "stage 6 Youmu must use Immeasurable Kalpas")
	check(Spells.card_for({"kind": "patchouli_boss"}, {"mid_boss_kind": "patchouli_boss"}).id == "th06-52", "Extra Patchouli must begin with Silent Selene")
	check(Spells.card_for({"kind": "cirno_boss"}, {"mid_boss_kind": "cirno_boss"}).origin == "nonspell", "TH07 Normal Cirno must not use the Hard/Lunatic Frost Columns card")


func _test_card_animation_poses() -> void:
	var game = make_game()
	for kind in Spells.CARDS:
		var selector = "_%s_frame_index" % String(kind).trim_suffix("_boss")
		for card in Spells.CARDS[kind]:
			var active_pose := false
			for frame in range(12):
				game.level_time = frame / 10.0
				active_pose = active_pose or int(game.call(selector, {"rumia_state": card[3]})) != int(game.call(selector, {"rumia_state": "idle"}))
			check(active_pose, "%s: spell animation must not silently fall back to idle" % card[0])
	release(game)


func _test_midboss_patterns() -> void:
	for kind in ["sakuya_boss", "chen_boss", "youmu_boss", "patchouli_boss", "cirno_boss"]:
		var level = {"mid_boss_kind": kind}
		for cycle in range(Spells.cards_for(kind, level).size()):
			var game = make_game(kind, cycle)
			game.current_level.merge(level)
			game.zombies[0] = game._trigger_boss_skill(game.zombies[0])
			check(not game.touhou_danmaku.bullets.is_empty() or not game.touhou_danmaku.beams.is_empty(), "%s midboss card must emit a playable pattern" % kind)
			release(game)


func _test_every_spell_has_live_pattern() -> void:
	for kind in Spells.CARDS:
		for cycle in range(Spells.CARDS[kind].size()):
			var game = make_game(kind, cycle)
			game.grid[2][3] = game._create_plant("wallnut", 2, 3)
			var hp = float(game.grid[2][3].health)
			game.zombies[0] = game._trigger_boss_skill(game.zombies[0])
			var runtime = game.touhou_danmaku
			check(runtime != null and runtime.casts.size() == 1, "%s/%d must use the live spell runtime" % [kind, cycle])
			check(not runtime.bullets.is_empty() or not runtime.beams.is_empty() or game.zombies.size() > 1, "%s/%d must emit bullets, beams or the original wraith entities" % [kind, cycle])
			check(float(game.grid[2][3].health) == hp, "%s/%d must not deal invisible instant area damage on declaration" % [kind, cycle])
			check(String(game._boss_cast_status(game.zombies[0]).text).contains(String(game.zombies[0].touhou_card.name)), "HUD must show the same card that is executing")
			runtime.update(0.12)
			check(runtime.bullets.size() <= runtime.MAX_BULLETS and runtime.beams.size() <= runtime.MAX_BEAMS, "patterns must respect particle budgets")
			release(game)


func _test_freeze_and_time_stop() -> void:
	var game = make_game("cirno_boss", 1)
	game.zombies[0] = game._trigger_boss_skill(game.zombies[0])
	var runtime = game.touhou_danmaku
	runtime.update(0.7)
	var bullet: Dictionary = runtime.bullets[0]
	var frozen_position = Vector2(bullet.position)
	runtime.update(0.3)
	check(Vector2(bullet.position).is_equal_approx(frozen_position) and bool(bullet.frozen), "Perfect Freeze must stop its actual bullets")
	runtime.update(0.7)
	check(not Vector2(bullet.position).is_equal_approx(frozen_position) and bool(bullet.thawed), "frozen bullets must resume in their changed direction")
	release(game)
	game = make_game("sakuya_boss", 2)
	game.zombies[0] = game._trigger_boss_skill(game.zombies[0])
	runtime = game.touhou_danmaku
	bullet = runtime.bullets[0]
	var before = Vector2(bullet.position)
	runtime.update(0.7)
	check(game.boss_time_stop_timer > 0 and Vector2(bullet.position) == before, "Sakuya must place motionless knives during time stop")
	game.boss_time_stop_timer = 0.0
	runtime.update(0.2)
	check(Vector2(bullet.position) != before, "Sakuya knives must launch after time resumes")
	game.boss_time_stop_timer = 1.5
	game.zombies[0].health = 0.0
	runtime.update(0.1)
	check(game.boss_time_stop_timer == 0.0 and runtime.bullets.is_empty(), "defeating Sakuya must release her time stop before the next encounter")
	release(game)


func _test_collision_and_reflection() -> void:
	var game = make_game("flandre_boss", 6)
	game.zombies[0] = game._trigger_boss_skill(game.zombies[0])
	var runtime = game.touhou_danmaku
	var b: Dictionary = runtime.bullets[0]
	b.position = game.BOARD_ORIGIN + Vector2(500, game.board_size.y - 7)
	b.velocity = Vector2(-100, 240)
	runtime.update(0.05)
	check(float(b.velocity.y) < 0 and int(b.bounces) == 1, "Catadioptric must reflect on the field boundary")
	runtime.clear()
	game.grid[2][5] = game._create_plant("wallnut", 2, 5)
	game.grid[2][3] = game._create_plant("wallnut", 2, 3)
	var front = float(game.grid[2][5].health)
	var rear = float(game.grid[2][3].health)
	var from = game._cell_center(2, 7) + Vector2(0, -12)
	var to = game._cell_center(2, 1) + Vector2(0, -12)
	check(runtime._hit_plant_segment(from, to, 5, 20, []), "swept collision must detect fast bullets")
	check(float(game.grid[2][5].health) == front - 20 and float(game.grid[2][3].health) == rear, "a bullet must hit the first plant on its path, not every crossed plant")
	var hits: Array = []
	runtime._hit_plant_segment(from, to, 5, 20, hits, false)
	front = float(game.grid[2][5].health)
	runtime._hit_plant_segment(from, to, 5, 20, hits, false)
	check(float(game.grid[2][5].health) == front, "persistent beams must not repeat damage every frame")
	release(game)


func _test_bullets_outlive_emission() -> void:
	var game = make_game("daiyousei_boss")
	game.grid[2][1] = game._create_plant("wallnut", 2, 1)
	var hp = float(game.grid[2][1].health)
	game.zombies[0] = game._trigger_boss_skill(game.zombies[0])
	game.touhou_danmaku.update(3.5)
	check(game.touhou_danmaku.casts.is_empty() and not game.touhou_danmaku.bullets.is_empty(), "ordinary bullets must continue flying after emission finishes")
	game.touhou_danmaku.update(2.7)
	check(float(game.grid[2][1].health) < hp, "slow aimed bullets must be able to reach the backline")
	game.zombies[0].health = 0.0
	game.touhou_danmaku.update(0.1)
	check(game.touhou_danmaku.bullets.is_empty(), "defeat must also clear bullets from completed casts")
	release(game)


func _test_clones_and_successor_cleanup() -> void:
	var game = make_game("flandre_boss", 2)
	game.zombies[0] = game._trigger_boss_skill(game.zombies[0])
	check(game.touhou_danmaku.casts[0].actors.size() == 3, "Four of a Kind consists of the original plus three additional emitters")
	game.zombies[0].health = 0.0
	game.touhou_danmaku.update(0.1)
	check(game.touhou_danmaku.bullets.is_empty() and game.touhou_danmaku.casts.is_empty(), "defeat must cancel pending emissions and bullets")
	release(game)
	game = make_game("ran_boss", 7)
	game.zombies[0] = game._trigger_boss_skill(game.zombies[0])
	check(game.touhou_danmaku.casts[0].actors[0].kind == "chen_boss", "Ran's Chen card must summon a Chen emitter")
	var successor: Dictionary = game._trigger_ran_boss_successor(game.zombies[0])
	check(game.touhou_danmaku.casts.is_empty() and game.touhou_danmaku.bullets.is_empty(), "Ran-to-Yukari handoff must clear old danmaku")
	check(not successor.has("touhou_owner") and not successor.has("touhou_card"), "successor must start with an independent spell state")
	release(game)


func _test_final_survival() -> void:
	var game = make_game("yuyuko_boss")
	game.zombies[0].health = 0.0
	game.zombies[0] = game._trigger_yuyuko_boss_revival(game.zombies[0])
	var boss: Dictionary = game.zombies[0]
	check(float(boss.health) == 1 and bool(boss.touhou_invulnerable), "Resurrection Butterfly must be a survival finale, not a second health pool")
	check(boss.touhou_card.id == "th07-114", "finale must use the Normal three-tenths bloom card")
	boss = game._apply_zombie_damage(boss, 100000, 0.1, 0.0, true)
	check(float(boss.health) == 1, "bombs and piercing attacks must not skip the survival finale")
	boss.health = 0.0
	game.touhou_danmaku.update(0.1)
	game._cleanup_dead_zombies()
	check(float(boss.health) == 1.0 and not game.touhou_danmaku.casts.is_empty(), "legacy direct health writes must not cancel or stall the survival clock")
	game.touhou_danmaku.casts[0].age = 23.95
	game.touhou_danmaku.casts[0].next_wave = 25.0
	game.touhou_danmaku.update(0.1)
	check(float(boss.health) == 0 and not bool(boss.touhou_invulnerable), "surviving the timer must end the finale")
	release(game)


func _test_charm_blocks_all_normal_actions() -> void:
	for kind in ["peashooter", "repeater", "split_pea", "starfruit", "sunflower", "snow_pea"]:
		var game = make_game("youmu_boss", 5)
		var plant: Dictionary = game._create_plant(kind, 2, 4)
		plant.shot_cooldown = 0.0
		plant["rear_shot_cooldown"] = 0.0
		plant["burst_remaining"] = 2
		plant["burst_timer"] = 0.0
		plant["sun_timer"] = 0.0
		plant["ultimate_charge"] = 1.0
		plant["ultimate_cooldown"] = 0.0
		game.grid[2][4] = plant
		game.grid[2][3] = game._create_plant("wallnut", 2, 3)
		var hp = float(game.grid[2][3].health)
		game._charm_plant_at_cell(2, 4, 2.0)
		check(not game._try_activate_ultimate(2, 4), "charmed %s must not execute a player-commanded ultimate" % kind)
		check(not game._activate_plant_food(2, 4), "plant food must not bypass charm on %s" % kind)
		game._update_plants(0.7)
		check(game.projectiles.is_empty() and game.suns.is_empty(), "charmed %s must suppress normal behavior even on a long frame" % kind)
		check(float(game.grid[2][3].health) < hp, "original charm must retain attacks against nearby plants")
		game._update_plants(1.4)
		game._update_plants(0.8)
		check(not game._plant_charm_blocks_actions(game.grid[2][4]), "normal actions must resume after charm expires")
		release(game)


func _test_charm_layers_and_expiry() -> void:
	var game = make_game("youmu_boss")
	game.support_grid[2][4] = game._create_plant("lily_pad", 2, 4)
	game._charm_plant_at_cell(2, 4, 0.6)
	game.grid[2][4] = game._create_plant("peashooter", 2, 4)
	game.grid[2][3] = game._create_plant("wallnut", 2, 3)
	var hp = float(game.grid[2][3].health)
	game._update_charmed_plants(0.7)
	check(float(game.support_grid[2][4].youmu_charm_timer) == 0.0, "covered support charm must still expire")
	check(float(game.grid[2][3].health) == hp, "covered support must not attack through a new top plant")
	game.grid[2][3].health = 0.0
	check(not game._charm_plant_at_cell(2, 3, 2), "dead plants must not be charmed")
	game.grid[2][2] = game._create_plant("wallnut", 2, 2)
	check(game._find_nearest_plant_cell_to_cell(2, 4) == Vector2i(2, 2), "charm targeting must skip dead plants awaiting cleanup")
	game.grid[2][4]["holy_invincible_timer"] = 2.0
	check(not game._charm_plant_at_cell(2, 4, 2), "holy immunity must reject incoming charm")
	release(game)


func _test_wraith_respects_control() -> void:
	var game = make_game("youmu_boss")
	game.grid[2][4] = game._create_plant("wallnut", 2, 4)
	game._spawn_youmu_wraith(2, game._cell_center(2, 6).x)
	var wraith: Dictionary = game.zombies.back()
	wraith.rooted_timer = 1.0
	var x = float(wraith.x)
	wraith = game._update_youmu_wraith(wraith, 0.5)
	check(float(wraith.x) == x, "rooted wraiths must not keep rushing into plants")
	wraith.youmu_wraith_age = 9.0
	wraith = game._update_youmu_wraith(wraith, 0.1)
	check(float(wraith.health) == 0.0, "stalled wraiths must expire even while a target exists")
	release(game)
