extends SceneTree

const Game = preload("res://scripts/game.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value: return
	failures += 1
	push_error(message)

func make_game(level: Dictionary) -> Control:
	var game := Game.new()
	game.current_level = level.duplicate(true)
	game.rng.seed = 175
	game.conveyor_source_cards = level.get("conveyor_plants", ["wallnut"]).duplicate()
	game.active_cards.resize(game.MAX_SEED_SLOTS)
	game.active_cards.fill("")
	game.conveyor_card_visual.resize(game.MAX_SEED_SLOTS)
	game.conveyor_card_visual.fill(0.0)
	for row in range(game.ROWS):
		var cells: Array = []
		cells.resize(game.COLS)
		cells.fill(null)
		game.grid.append(cells)
	return game

func _run() -> void:
	for mode in ["conveyor", "bowling"]:
		var game := make_game({"id": "1-pacing", "mode": mode, "events": []})
		game.active_cards.fill("wallnut")
		game.conveyor_spawn_timer = 5.0
		var before_rng: int = game.rng.state
		game._update_conveyor(20.0)
		check(is_equal_approx(game.conveyor_spawn_timer, 5.0), "%s: holding a full belt preserves the next delivery wait" % mode)
		check(game.rng.state == before_rng, "%s: holding cards does not reroll delivery RNG" % mode)
		game._consume_conveyor_card("wallnut")
		game._update_conveyor(1.0)
		check(game.active_cards.count("") == 1, "%s: using a card after a full belt cannot trigger a rapid refill" % mode)
		check(is_equal_approx(game.conveyor_spawn_timer, 4.0), "%s: the delivery clock resumes from its retained wait" % mode)
		game._update_conveyor(4.0)
		check(game.active_cards.count("") == 0, "%s: the next card still arrives when its wait finishes" % mode)
		check(game.conveyor_spawn_timer >= 4.6 and game.conveyor_spawn_timer <= 6.8, "Ordinary belt levels retain their existing delivery range")
		game.free()
	for id in ["4-19", "4-20"]:
		var base: Dictionary = {}
		for level in Game.Defs.LEVELS:
			if level.id == id: base = level
		check(not base.is_empty(), "%s exists" % id)
		if base.is_empty(): continue
		for choice in ["easy", "normal", "hard"]:
			var game := make_game(Difficulty.build_level(base, choice))
			game.conveyor_spawn_timer = 0.35
			for i in range(3): game._fill_conveyor_slot(i)
			var deliveries := 0
			var early := false
			for frame in range(1200):
				game._update_conveyor(0.05)
				for i in range(game.active_cards.size() - 1, -1, -1):
					var kind: String = game.active_cards[i]
					if kind == "": continue
					deliveries += 1
					if frame == 0: early = deliveries == 3
					game._consume_conveyor_card(kind)
			check(early, "%s/%s keeps the three opening seeds" % [id, choice])
			check(deliveries >= 18 and deliveries <= 26, "%s/%s: one minute supplies 18–26 seeds including opening reserves, got %d" % [id, choice, deliveries])
			print("Belt %s/%s: %d seeds in 60s including opening reserves" % [id, choice, deliveries])
			game.free()
	print("Conveyor pacing: %d failure(s)" % failures)
	quit(1 if failures else 0)
