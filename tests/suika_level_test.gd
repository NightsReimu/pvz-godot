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
		if level.id == "8-6": stage = level
	check(not stage.is_empty(), "Missing Suika finale 8-6")
	if stage.is_empty():
		quit(1)
		return
	check(stage.terrain == "ancient" and stage.row_count == 5 and stage.unlock_requirements == ["8-5"], "Suika belongs after the ancient courtyard campaign")
	check(stage.get("mid_boss_final_preview", false) and stage.mid_boss_kind == "suika_boss", "Road Suika must preview, then retreat before her finale")
	check(stage.boss_bgm == "res://audio/th075_suika_boss.mp3", "Use the supplied final BGM")
	check(Difficulty.options(stage) == ["easy", "normal", "hard", "lunatic"], "All four difficulties must be selectable")
	for rank in range(4):
		var choice: String = ["easy", "normal", "hard", "lunatic"][rank]
		var level := Difficulty.build_level(stage, choice)
		var canon: Array = []
		var originals := 0
		for entry in Spells.cards_for("suika_boss", level):
			var card := Spells.card_from_entry(entry)
			if card.origin == "canon": canon.append(card.name)
			if card.origin == "original": originals += 1
		check(canon == ["符之一「投掷的天岩户」", "符之二「坤轴的大鬼」", "符之三「追傩返黑洞」", "鬼火「超高密度磷祸术」", "疎符「六里雾中」", "「百万鬼夜行」"], choice + ": preserve exactly the six TH7.5 story cards")
		check(originals == 1 + rank, choice + ": original interludes accumulate with difficulty")
		var phases := Spells.phases_for("suika_boss", level)
		check(phases.back().back()[1] == "「百万鬼夜行」", "Canonical Million Oni must remain the final declaration")
		check((level.mode == "normal") == (choice == "lunatic"), "Only Lunatic uses manual seed selection")
		check(level.events.back().kind == "suika_boss", "Additional waves precede Suika")
	for event in stage.events: check(Defs.ZOMBIES.has(event.kind), "Registered enemy " + event.kind)
	for plant in stage.conveyor_plants: check(Defs.PLANTS.has(plant), "Registered seed " + plant)
	print("Suika 8-6 four-difficulty level contracts: %d failure(s)" % failures)
	quit(1 if failures else 0)
