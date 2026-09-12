extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var stage: Dictionary = {}
	for level in Defs.LEVELS:
		if level.id == "3-22-b":
			stage = level
	check(not stage.is_empty(), "Missing Marisa stage 3-22-b")
	if stage.is_empty():
		quit(1)
		return
	check(stage.terrain == "reimu_midnight_bamboo" and stage.row_count == 6 and stage.water_rows.is_empty(), "Marisa needs six grass lanes in the midnight bamboo forest")
	check(stage.get("mid_boss_kind", "") == "" and stage.unlock_requirements == ["3-21"], "Marisa is a single finale following 3-21")
	check(stage.boss_intro_bgm == "res://audio/th08_reimu_stage.mp3" and stage.boss_bgm == "res://audio/th08_marisa_boss.mp3", "Use both supplied music tracks")
	var bosses := 0
	for event in stage.events:
		check(Defs.ZOMBIES.has(event.kind), "Registered event kind " + event.kind)
		if bool(Defs.ZOMBIES[event.kind].get("boss", false)):
			bosses += 1
			check(event.kind == "marisa_boss", "No other boss belongs to this stage")
	check(bosses == 1, "Exactly one Marisa spawn")
	for plant in stage.conveyor_plants:
		check(Defs.PLANTS.has(plant), "Registered plant " + plant)
	check(Difficulty.options(stage) == ["easy", "normal", "hard", "lunatic"], "All four difficulties must be selectable")
	var ids := [[78, 82, 86, 90, 94], [79, 83, 87, 91, 95, 98], [80, 84, 88, 92, 96, 99], [81, 85, 89, 93, 97, 100]]
	var all_ids := {}
	for rank in range(4):
		var choice: String = ["easy", "normal", "hard", "lunatic"][rank]
		var level := Difficulty.build_level(stage, choice)
		var cards := Spells.cards_for("marisa_boss", level)
		var actual: Array = []
		for card in cards:
			actual.append(String(card[0]).trim_prefix("th08-").to_int())
			all_ids[card[0]] = true
		check(actual == ids[rank], choice + " must use exactly its TH08 4B card IDs, including former midboss cards")
		check(Spells.phases_for("marisa_boss", level).size() == ids[rank].size() + rank, "Preserve all canonical cards and cumulatively add one original move per tier")
		check((level.mode == "normal") == (choice == "lunatic"), "Only Lunatic uses manual seed selection")
		check(level.events.back().kind == "marisa_boss", "Reinforcement waves must precede the finale")
	check(all_ids.size() == 23, "All 23 difficulty-specific spell entries must be represented")
	print("Marisa level and four difficulty spell contracts: %d failure(s)" % failures)
	quit(1 if failures else 0)
