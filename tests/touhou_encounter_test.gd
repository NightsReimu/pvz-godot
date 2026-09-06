extends SceneTree

const Game = preload("res://scripts/game.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
var failures := 0

class EncounterGame extends Game:
	var declarations: Array = []

	func _lose_level(_reason: String = "") -> void:
		pass

	func _trigger_boss_skill(boss: Dictionary) -> Dictionary:
		declarations.append({"id": Spells.card_for(boss, current_level).id, "stage": boss.touhou_encounter.index})
		return super._trigger_boss_skill(boss)

class EmptyBoardDanmaku extends Game.TouhouDanmakuRuntime:
	# These sequence fixtures have no plants. Swept collisions have separate contracts.
	func _hit_plant_segment(_from: Vector2, _to: Vector2, _radius: float, _damage: float, _hits: Array, _first: bool = true) -> bool:
		return false


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func make_game(kind: String, midboss: bool = false) -> EncounterGame:
	var game := EncounterGame.new()
	game.size = Vector2(1600, 900)
	game.current_level = {"id": "encounter-test", "terrain": "day", "events": []}
	if midboss:
		game.current_level.mid_boss_kind = kind
	game.active_rows = [0, 1, 2, 3, 4]
	game.banner_label = Label.new()
	game.toast_label = Label.new()
	for row in range(6):
		var cells: Array = []
		cells.resize(9)
		game.grid.append(cells)
		game.support_grid.append(cells.duplicate())
	game.rng.seed = 907
	game.touhou_danmaku = EmptyBoardDanmaku.new(game)
	game._spawn_zombie_at(kind, 2, game._boss_anchor_x(kind), true)
	game.zombies[0].hover_shift_timer = 10000.0
	game.zombies[0].rumia_reinforcement_timer = 10000.0
	return game


func release(game: Control) -> void:
	game.save_dirty = false
	game.banner_label.free()
	game.toast_label.free()
	game.free()


func tick(game: Control, dt: float = 0.1) -> void:
	game.level_time += dt
	game.boss_time_stop_timer = maxf(0.0, game.boss_time_stop_timer - dt)
	game._update_zombies(dt)
	if game.touhou_danmaku != null:
		game.touhou_danmaku.update(dt)
	game._update_effects(dt)


func finish_encounter(game: EncounterGame) -> void:
	var boss: Dictionary = game.zombies[0]
	for frame in range(2400):
		game._apply_zombie_damage(boss, 1000000.0, 0.0, 0.0, true)
		tick(game)
		check(int(boss.boss_phase) <= 3, "Extra stages must keep bounded combat and image-scale intensity")
		if bool(boss.touhou_encounter.complete):
			break
	check(bool(boss.touhou_encounter.complete) and float(boss.health) == 0.0, "%s must finish without stalling" % boss.kind)


func _run() -> void:
	var counts := {"rumia_boss": 2, "daiyousei_boss": 1, "cirno_boss": 3, "meiling_boss": 4, "koakuma_boss": 1, "patchouli_boss": 4, "sakuya_boss": 4, "remilia_boss": 5, "flandre_boss": 10, "letty_boss": 2, "chen_boss": 4, "alice_boss": 4, "lily_white_boss": 1, "prismriver_boss": 4, "youmu_boss": 5, "yuyuko_boss": 6, "ran_boss": 10, "yukari_boss": 11}
	for kind in counts:
		check(Spells.phase_count(kind) == counts[kind], "%s must have its own route's phase count" % kind)
		_test_full_route(kind)
	for kind in ["sakuya_boss", "chen_boss", "youmu_boss", "patchouli_boss", "cirno_boss"]:
		_test_full_route(kind, true)
	_test_health_boundaries()
	_test_transition_cleanup()
	_test_nonspell_identity()
	_test_survival_and_successor()
	_test_time_stop_and_pause()
	_test_undamaged_phase_and_survival()
	print("Touhou encounters: 18 bosses, 5 midboss routes, burst gates, nonspells, survival and successor; %d failure(s)" % failures)
	quit(1 if failures else 0)


func _test_full_route(kind: String, midboss: bool = false) -> void:
	var game := make_game(kind, midboss)
	var boss: Dictionary = game.zombies[0]
	var expected: Array = []
	for index in range(boss.touhou_encounter.phases.size()):
		for entry in boss.touhou_encounter.phases[index]:
			expected.append({"id": entry[0], "stage": index})
	finish_encounter(game)
	check(game.declarations == expected, "%s must execute every required attack once, in phase order, despite burst damage" % kind)
	var played_canon: Array = []
	for declaration in game.declarations:
		if not String(declaration.id).begins_with("adapted-") and not String(declaration.id).begins_with("original-"):
			played_canon.append(declaration.id)
	var route_canon: Array = []
	for card in Spells.cards_for(kind, game.current_level):
		if not String(card[0]).begins_with("original-"):
			route_canon.append(card[0])
	check(played_canon == route_canon, "%s must preserve every original route card in order" % kind)
	game._heal_hover_boss(boss, float(boss.max_health))
	check(float(boss.health) == 0.0, "A delayed heal must not restart a finished encounter")
	print("Route %s%s: %d phases, %d attacks" % [kind, " midboss" if midboss else "", boss.touhou_encounter.phases.size(), game.declarations.size()])
	if kind == "youmu_boss" and not midboss:
		check(game.declarations.any(func(d): return d.id == "original-youmu-wraith" and d.stage == 2), "Youmu's original charm must remain reachable inside the sword sequence")
	release(game)


func _test_health_boundaries() -> void:
	var game := make_game("remilia_boss")
	var boss: Dictionary = game.zombies[0]
	var encounter: Dictionary = boss.touhou_encounter
	var total := float(boss.max_health)
	game._apply_zombie_damage(boss, 1000000, 0, 0, true)
	check(float(boss.health) > total * 0.8 and int(encounter.index) == 0, "A bomb must not skip Remilia's first card")
	boss.health = 0.0
	game._cleanup_dead_zombies()
	check(game.zombies.has(boss) and float(boss.health) > total * 0.8 and game.total_kills == 0, "Legacy direct kills must not bypass stage gates or grant kill rewards")
	var low := float(boss.health)
	game._heal_hover_boss(boss, total)
	check(is_equal_approx(float(boss.health), low), "A depleted segment must not regenerate while its required card finishes")
	for frame in range(200):
		tick(game)
		if int(encounter.index) == 1:
			break
	check(int(encounter.index) == 1 and is_equal_approx(float(boss.health), total * 0.8), "Only one stage may advance at a time")
	game._apply_zombie_damage(boss, 100)
	game._heal_hover_boss(boss, total)
	check(is_equal_approx(float(boss.health), total * 0.8), "Vampiric healing must not restore earlier stages")
	check(int(game._boss_health_bar_layout(boss).segments) == 1, "Phased encounters must display the current segment's own health bar")
	boss.max_health *= 2.0
	boss.health *= 2.0
	Game.TouhouPhaseRuntime.guard_health(boss)
	check(is_equal_approx(float(encounter.ceiling), total * 1.6) and is_equal_approx(float(boss.health), total * 1.6), "Scaled encounter health must retain the full active segment")
	release(game)


func _test_transition_cleanup() -> void:
	var game := make_game("sakuya_boss")
	var boss: Dictionary = game.zombies[0]
	game._trigger_boss_skill(boss)
	var runtime = game.touhou_danmaku
	var other: Dictionary = runtime.bullets[0].duplicate(true)
	other.owner = 9999
	runtime.bullets.append(other)
	boss.touhou_encounter.completed = boss.touhou_encounter.phases[0].size()
	boss.touhou_encounter.casting = false
	boss.touhou_encounter.depleted = true
	boss.touhou_cast_remaining = 0.0
	game.boss_time_stop_timer = 1.0
	game._ensure_zombie_runtime().update_boss(boss, 0.1)
	check(runtime.bullets.size() == 1 and runtime.bullets[0].owner == 9999, "Stage transitions must clear only the outgoing owner's bullets")
	check(game.boss_time_stop_timer == 0.0 and runtime.casts.is_empty(), "Sakuya transitions must release the old time stop and emitters")
	check(not bool(boss.boss_cast_pending) and float(boss.boss_pause_timer) >= 0.9, "Next phase must have a clean, visible transition")
	release(game)


func _test_nonspell_identity() -> void:
	var signatures: Array = []
	for kind in Spells.NONSPELLS:
		var game := make_game(kind)
		var boss: Dictionary = game.zombies[0]
		game._trigger_boss_skill(boss)
		var runtime = game.touhou_danmaku
		check(String(boss.touhou_card.origin) == "nonspell" and not runtime.bullets.is_empty(), "%s must have a playable unnamed opening" % kind)
		var signature: Array = []
		for bullet in runtime.bullets:
			signature.append([bullet.position, bullet.velocity, bullet.shape])
		check(not signatures.has(signature), "%s nonspell must differ in geometry, not just tint" % kind)
		signatures.append(signature)
		check(runtime.bullets.size() <= runtime.MAX_BULLETS, "Nonspell budget must be bounded")
		release(game)


func _test_survival_and_successor() -> void:
	var game := make_game("yuyuko_boss")
	finish_encounter(game)
	game._cleanup_dead_zombies()
	var boss: Dictionary = game.zombies[0]
	check(bool(boss.yuyuko_revived) and boss.touhou_card.id == "th07-114", "Rebirth must follow all five main phases")
	for frame in range(30):
		game._apply_zombie_damage(boss, 1000000, 0, 0, true)
		tick(game)
	check(float(boss.health) == 1.0 and float(boss.touhou_survival_timer) > 20.0, "Damage must not skip Rebirth's survival clock")
	for frame in range(220):
		tick(game)
	check(float(boss.health) == 0.0 and not bool(boss.touhou_invulnerable), "Rebirth must end on time after an actual multi-stage fight")
	release(game)
	game = make_game("ran_boss")
	finish_encounter(game)
	game._cleanup_dead_zombies()
	boss = game.zombies[0]
	check(boss.kind == "yukari_boss" and int(boss.touhou_encounter.index) == 0 and not bool(boss.touhou_encounter.depleted), "Yukari must start her own eleven-phase encounter")
	check(boss.touhou_encounter.phases.size() == 11 and not boss.has("touhou_owner"), "Successor must inherit neither card progress nor emitter ownership")
	release(game)


func _test_time_stop_and_pause() -> void:
	var game := make_game("remilia_boss")
	game._trigger_boss_skill(game.zombies[0])
	var state: Dictionary = game.zombies[0].touhou_encounter.duplicate(true)
	var remaining := float(game.zombies[0].touhou_cast_remaining)
	game.boss_time_stop_timer = 1.0
	game._update_zombies(0.3)
	game.touhou_danmaku.update(0.3)
	check(game.zombies[0].touhou_encounter == state and is_equal_approx(float(game.zombies[0].touhou_cast_remaining), remaining), "Another boss's time stop must freeze encounter progress")
	game.mode = game.MODE_BATTLE
	game.battle_paused = true
	game._process(0.3)
	check(game.zombies[0].touhou_encounter == state, "Pausing must preserve stage progress")
	release(game)


func _test_undamaged_phase_and_survival() -> void:
	var game := make_game("remilia_boss")
	var boss: Dictionary = game.zombies[0]
	for frame in range(350):
		tick(game)
	check(int(boss.touhou_encounter.index) == 0 and game.declarations.size() >= 4, "An undamaged phase must keep alternating attacks without advancing")
	check(game.declarations[0].id == game.declarations[2].id and game.declarations[1].id == game.declarations[3].id, "Phase repeats must preserve the nonspell/spell alternation")
	release(game)
	game = make_game("flandre_boss")
	boss = game.zombies[0]
	boss.touhou_encounter.index = 8
	boss.touhou_encounter.attack = 1
	boss.touhou_encounter.completed = 1
	Game.TouhouPhaseRuntime._set_bounds(boss)
	boss.health = boss.touhou_encounter.ceiling
	game._trigger_boss_skill(boss)
	for frame in range(100):
		tick(game)
	check(int(boss.touhou_encounter.index) == 9, "Flandre's survival card must advance to QED without requiring damage")
	release(game)
