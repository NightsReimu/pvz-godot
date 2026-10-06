extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

func check(value: bool, message: String) -> void:
	if value: return
	failures += 1
	push_error(message)

func _run() -> void:
	for stage in ["4-19", "4-20", "8-6"]:
		var base: Dictionary = {}
		for level in GameScript.Defs.LEVELS:
			if level.id == stage: base = level
		for choice in ["easy", "normal", "hard", "lunatic"]:
			var game := PreviewGame.new()
			game.size = Vector2(1600, 900)
			root.add_child(game)
			game.rng.seed = 175
			var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
			game._begin_level(-1, [], level)
			game.hide()
			game._spawn_frozen_branch_midboss()
			var road: Dictionary = game.zombies.back()
			check(bool(road.get("touhou_road_boss", false)), "%s/%s: the actual road spawn owns its weak role" % [stage, choice])
			var count := game.zombies.size()
			road.rumia_reinforcement_timer = 0.0
			game._update_boss_reinforcements(road, 0.1)
			check(game.zombies.size() == count + 1, "%s/%s: road support retains its single arrival" % [stage, choice])
			var old_wait: float = game._boss_reinforcement_interval(String(road.kind), 0)
			check(float(road.rumia_reinforcement_timer) >= old_wait - 0.36, "%s/%s: the road retains its old support interval" % [stage, choice])
			game.zombies.clear()
			var kind: String = base.events.back().kind
			game._spawn_zombie(kind, 2, true)
			var boss: Dictionary = game.zombies.back()
			check(not bool(boss.touhou_road_boss), "%s/%s: the ending boss owns its full role" % [stage, choice])
			check(float(boss.rumia_reinforcement_timer) <= 2.2, "%s/%s: support starts within the finale's opening two seconds" % [stage, choice])
			count = game.zombies.size()
			boss.rumia_reinforcement_timer = 0.0
			game._update_boss_reinforcements(boss, 0.1)
			var batch := 3 if choice in ["hard", "lunatic"] else 2
			check(game.zombies.size() == count + batch, "%s/%s: the finale creates a real %d-enemy batch" % [stage, choice, batch])
			var rows: Array = []
			for enemy in game.zombies:
				if not bool(game.Defs.ZOMBIES[enemy.kind].get("boss", false)) and not rows.has(enemy.row): rows.append(enemy.row)
			check(rows.size() >= 2, "%s/%s: an arrival uses multiple lanes" % [stage, choice])
			check(float(boss.rumia_reinforcement_timer) <= 7.1, "%s/%s: repeated support does not retain an eleven-second gap" % [stage, choice])
			boss.boss_phase = 3
			for cycle in range(30):
				boss.rumia_reinforcement_timer = 0.0
				game._update_boss_reinforcements(boss, 0.1)
			check(game._active_zombie_count() == 42, "%s/%s: the repeated batches fill, but never exceed, the live-enemy cap" % [stage, choice])
			check(float(boss.rumia_reinforcement_timer) <= 5.2, "%s/%s: late phases sustain the faster support cadence" % [stage, choice])
			if stage == "4-20":
				for family in ["kedama", "star_fairy"]:
					check(game.zombies.any(func(enemy): return game.FusionZombieDefs.RECIPES.has(String(enemy.get("fusion_kind", ""))) and String(enemy.kind) == family and float(enemy.get("headgear_health", 0.0)) > 0.0), "%s: late Hina support includes actual armored %s fusions" % [choice, family])
			count = game.zombies.size()
			boss.health = 0.0
			game._update_boss_reinforcements(boss, 100.0)
			check(game.zombies.size() == count, "A defeated finale cannot summon another batch")
			print("Finale support %s/%s: batch=%d, lanes=%d, live cap=%d" % [stage, choice, batch, rows.size(), game._active_zombie_count()])
			game._stop_bgm()
			game.music_player.stream = null
			for player in game.sfx_players:
				player.stop()
				player.stream = null
			game.save_dirty = false
			await create_timer(0.15).timeout
			game.free()
			await process_frame
	print("New Touhou finale reinforcement: %d failure(s)" % failures)
	quit(1 if failures else 0)
