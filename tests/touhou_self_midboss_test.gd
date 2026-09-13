extends "res://tests/touhou_encounter_test.gd"

const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const DifficultyMenu = preload("res://scripts/runtime/touhou_difficulty_menu.gd")
const ROUTES := {
	"1-17": "rumia_boss", "1-19": "meiling_boss", "1-21": "sakuya_boss",
	"2-26": "chen_boss", "2-27": "alice_boss", "2-29": "youmu_boss",
	"3-19": "wriggle_boss", "3-20": "mystia_boss", "3-21": "keine_boss",
	"3-22-a": "reimu_boss", "3-22-b": "marisa_boss",
}

class RoadGame extends EncounterGame:
	var music_requests: Array[String] = []

	func _play_bgm(path: String) -> void:
		music_requests.append(path)


func _run() -> void:
	for id in ROUTES:
		var base := _level(id)
		check(not base.is_empty(), "%s must exist" % id)
		check(base.get("mid_boss_kind", "") == ROUTES[id] and bool(base.get("mid_boss_final_preview", false)), "%s must use its own finale character as the road boss" % id)
		var previous_hp := 0.0
		for choice in ["easy", "normal", "hard", "lunatic"]:
			var game := _road_game(id, choice)
			game._spawn_frozen_branch_midboss()
			var boss: Dictionary = game.zombies[0]
			var phases: Array = boss.touhou_encounter.phases
			check(phases.size() == 1 and phases[0].size() == 1, "%s %s road encounter needs exactly one basic attack" % [id, choice])
			for attacks in phases:
				for entry in attacks:
					check(Spells.card_from_entry(entry).origin == "nonspell", "%s road must not inherit finale spells or high-difficulty extra moves" % id)
			check(float(boss.max_health) > previous_hp, "%s road HP must increase with difficulty" % id)
			previous_hp = float(boss.max_health)
			var finale_hp := float(Game.Defs.ZOMBIES[ROUTES[id]].health) * float(Difficulty.profile(game.current_level).health)
			check(float(boss.max_health) <= finale_hp * 0.15, "%s road HP must be a small fraction of finale HP" % id)
			var menu := DifficultyMenu.new(game)
			check(menu.has_method("finale_summary"), "Difficulty menu must expose the actual finale route, even when its kind matches the road boss")
			if menu.has_method("finale_summary"):
				var summary: Dictionary = menu.finale_summary(game.current_level)
				check(summary.kind == ROUTES[id] and int(summary.phases) == Spells.phase_count(ROUTES[id], game.current_level), "%s menu must show full finale phases" % id)
			check(game.music_requests.is_empty(), "%s midboss spawn must never request finale music" % id)
			check(not game._is_stage_ending_boss(boss), "%s road identity must not be stage-ending" % id)
			var health_before := float(boss.health)
			game._spawn_frozen_branch_midboss()
			check(game.zombies.size() == 1, "Repeated road spawn must not duplicate the boss")
			check(is_equal_approx(float(boss.health), health_before), "Repeated road spawn must not rescale or heal its health")
			_test_reinforcements_and_progress(game)
			release(game)
		_test_defeat_flow(id)
		_test_queued_finale(id)
	_test_instant_defeat()
	print("Self-midbosses: 11 routes, 44 difficulty variants, damage-only defeat, music, nonspells and finale gates; %d failure(s)" % failures)
	quit(1 if failures else 0)


func _level(id: String) -> Dictionary:
	for entry in Game.Defs.LEVELS:
		if entry.id == id:
			return entry.duplicate(true)
	return {}


func _road_game(id: String, choice: String = "easy") -> RoadGame:
	var game := RoadGame.new()
	game.size = Vector2(1600, 900)
	game.current_level = Difficulty.build_level(_level(id), choice)
	game.active_rows = [0, 1, 2, 3, 4, 5] if id.begins_with("3-") else [0, 1, 2, 3, 4]
	game.board_rows = game.active_rows.size()
	game.board_size = Vector2(882, 550)
	game.banner_label = Label.new()
	game.toast_label = Label.new()
	for row in range(6):
		var cells: Array = []
		cells.resize(9)
		game.grid.append(cells)
		game.support_grid.append(cells.duplicate())
	game.rng.seed = 913
	game.touhou_danmaku = EmptyBoardDanmaku.new(game)
	game.current_bgm_path = game.current_level.boss_intro_bgm
	return game


func _test_defeat_flow(id: String) -> void:
	var game := _road_game(id)
	game._spawn_frozen_branch_midboss()
	var boss: Dictionary = game.zombies[0]
	var initial_health := float(boss.health)
	for frame in range(200):
		tick(game)
		game._update_frozen_branch_flow()
	check(float(boss.health) == initial_health and not game.frozen_branch_midboss_cleared, "%s must remain alive beyond 16 seconds without damage" % id)
	check(game.declarations.size() >= 2, "%s must repeat its basic attack while alive" % id)
	check(game.declarations.all(func(d): return String(d.id).ends_with("nonspell")), "%s must use only nonspells during live play" % id)
	check(game.zombies.size() > 1, "%s road must keep spawning supporting monsters" % id)
	check(game.boss_time_stop_timer == 0.0, "Road nonspells must not activate time-stop skills")
	if game.reimu_runtime != null:
		check(game.reimu_runtime.tiles.is_empty(), "Road Reimu must not cast special terrain tiles")
	if game.marisa_runtime != null:
		check(game.marisa_runtime.tiles.is_empty(), "Road Marisa must not cast special terrain tiles")
	if game.keine_runtime != null:
		check(game.keine_runtime.attacks.is_empty(), "Road Keine must not cast special attacks")
	game.batch_spawn_queue = [{"kind": "normal", "row": 0}]
	game.batch_spawn_remaining = 1
	game.next_event_index = 1
	var queue: Array = game.batch_spawn_queue.duplicate(true)
	game._trigger_boss_skill(boss)
	var owner := int(boss.get("touhou_owner", -1))
	game._apply_zombie_damage(boss, 1000000.0, 0.0, 0.0, true)
	game._cleanup_dead_zombies()
	game._update_frozen_branch_flow()
	check(not game.zombies.has(boss), "%s damage must defeat the road boss without waiting for an attack" % id)
	check(game.frozen_branch_midboss_cleared and not game.frozen_branch_progress_locked, "%s defeat must release the road gate" % id)
	check(game.next_event_index == 1 and game.batch_spawn_queue == queue, "%s road defeat must preserve remaining events and queued zombies" % id)
	check(game.total_kills == 1, "%s road defeat must grant its kill exactly once" % id)
	check(not game.zombies.is_empty(), "%s road defeat must preserve living supporting monsters" % id)
	check(game.music_requests.is_empty() and game.current_bgm_path == game.current_level.boss_intro_bgm, "%s road fight and defeat must keep the stage music" % id)
	check(not game.touhou_danmaku.casts.any(func(c): return c.owner == owner) and not game.touhou_danmaku.bullets.any(func(b): return b.owner == owner), "%s defeat must clear the outgoing attack and bullets" % id)
	game._check_end_state()
	check(game.battle_state != game.BATTLE_WON, "%s road defeat must not win the level" % id)
	if not game.zombies.has(boss):
		game._spawn_zombie_at(ROUTES[id], 2, game._boss_anchor_x(ROUTES[id]), true)
		var finale: Dictionary = game.zombies.back()
		check(game._is_stage_ending_boss(finale) and not bool(finale.get("touhou_final_preview", false)), "%s finale must have a fresh identity" % id)
		check(finale.touhou_encounter.phases == Spells.phases_for(ROUTES[id], game.current_level), "%s finale must keep its full spell route" % id)
		check(game.music_requests == [game.current_level.boss_bgm], "%s only the real finale may switch music" % id)
		finale.touhou_encounter.complete = true
		finale.health = 0.0
		game._cleanup_dead_zombies()
		check(game.batch_spawn_queue.is_empty() and game.next_event_index == game.current_level.events.size(), "%s real finale defeat must finish the event route" % id)
	release(game)


func _test_reinforcements_and_progress(game: RoadGame) -> void:
	var boss: Dictionary = game.zombies[0]
	game.expected_spawn_units = 100
	game.batch_spawn_queue = [{"kind": "normal", "row": 0, "progress_event": true}]
	game.batch_spawn_remaining = 1
	game.next_event_index = 1
	var queue := game.batch_spawn_queue.duplicate(true)
	var progress := game._battle_progress_ratio()
	for step in range(60):
		game._update_boss_reinforcements(boss, 0.2)
		game._update_spawn_director(0.2)
	check(game.zombies.size() > 1, "Road fight must spawn supporting monsters while the director is locked")
	check(is_equal_approx(game._battle_progress_ratio(), progress), "Supporting spawns must not move the locked progress bar")
	check(game.next_event_index == 1 and game.base_events_spawned == 0 and game.batch_spawn_queue == queue, "Supporting spawns must not consume waves or the existing queue")
	if game.zombies.size() > 1:
		var minion: Dictionary = game.zombies.back()
		game._apply_zombie_damage(minion, 1000000, 0, 0, true)
		game._cleanup_dead_zombies()
		game._update_frozen_branch_flow()
		check(is_equal_approx(game._battle_progress_ratio(), progress), "Supporting kills must not move the locked progress bar")
		check(game.frozen_branch_progress_locked and not game.frozen_branch_midboss_cleared, "A supporting kill cannot clear the road gate")
		var count := game.zombies.size()
		var health := float(boss.health)
		game._spawn_frozen_branch_midboss()
		check(game.zombies.size() == count and is_equal_approx(float(boss.health), health), "Repeated road spawn with minions present must leave all units unchanged")
		check(game.zombies.filter(func(z): return bool(z.get("touhou_final_preview", false))).size() == 1, "Only the road boss can have preview identity")
	game._apply_zombie_damage(boss, 1000000, 0, 0, true)
	game._cleanup_dead_zombies()
	game._update_frozen_branch_flow()
	game._update_spawn_director(1.0)
	check(game.batch_spawn_queue.is_empty() and game.base_events_spawned == 1, "After road defeat the paused wave must resume normally")


func _test_queued_finale(id: String) -> void:
	var game := _road_game(id)
	game.batch_spawn_queue = [{"kind": ROUTES[id], "row": 2}]
	game.batch_spawn_remaining = 1
	game._update_spawn_director(1.0)
	check(game.frozen_branch_midboss_spawned and game.zombies.size() == 1 and bool(game.zombies[0].get("touhou_final_preview", false)), "%s queued finale must first force a road encounter" % id)
	check(game.batch_spawn_queue.size() == 1, "%s forced road must leave finale queued" % id)
	var boss: Dictionary = game.zombies[0]
	game._apply_zombie_damage(boss, 1000000.0, 0.0, 0.0, true)
	game._cleanup_dead_zombies()
	game._update_frozen_branch_flow()
	game._update_spawn_director(1.0)
	check(game.batch_spawn_queue.is_empty() and game.zombies.size() == 1 and game._is_stage_ending_boss(game.zombies[0]), "%s queued finale must enter after actual defeat" % id)
	release(game)


func _test_instant_defeat() -> void:
	var game := _road_game("1-21")
	game._spawn_frozen_branch_midboss()
	var boss: Dictionary = game.zombies[0]
	boss.health = 0.0
	game._cleanup_dead_zombies()
	game._update_frozen_branch_flow()
	check(game.zombies.is_empty() and game.frozen_branch_midboss_cleared, "Direct damage must not revive a road boss to enforce a mandatory attack")
	game._heal_hover_boss(boss, float(boss.max_health))
	check(float(boss.health) == 0.0, "Delayed healing must not revive a defeated road boss")
	release(game)
