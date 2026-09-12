extends "res://tests/touhou_encounter_test.gd"

# Static collision comparison, not whole-battle DPS: 48 high-HP wallnuts,
# actual six-row desktop layout, phase intensity 3, nine seconds per card.
# Can also run this external script with --main-pack pointing to an older PCK.
func _run() -> void:
	for kind in ["reimu_boss", "marisa_boss", "keine_boss"]:
		for choice in ["easy", "normal", "hard", "lunatic"]:
			var losses := []
			var cards := Spells.cards_for(kind, {"touhou_difficulty": choice})
			for cycle in range(cards.size()):
				var game := make_game(kind)
				game.current_level.touhou_difficulty = choice
				game.current_level.row_count = 6
				game._refresh_battle_layout()
				game.active_rows = [0, 1, 2, 3, 4, 5]
				var boss: Dictionary = game.zombies[0]
				boss.x = game._boss_anchor_x(kind)
				boss.erase("touhou_encounter")
				boss.boss_phase = 3
				boss.boss_skill_cycle = cycle
				game.touhou_danmaku = Game.TouhouDanmakuRuntime.new(game)
				for row in range(6):
					for col in range(8):
						game.grid[row][col] = game._create_plant("wallnut", row, col)
						game.grid[row][col].health = 100000.0
				game._trigger_boss_skill(boss)
				game.touhou_danmaku.update(9.0)
				var health := 0.0
				for row in game.grid:
					for plant in row:
						if plant != null:
							health += float(plant.health)
				losses.append(4800000.0 - health)
				release(game)
			print(JSON.stringify({"boss": kind, "difficulty": choice, "damage": losses, "mean": losses.reduce(func(a, b): return a + b, 0.0) / losses.size()}))
	quit()
