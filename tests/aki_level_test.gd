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
		if level.id == "4-19": stage = level
	check(not stage.is_empty(), "Missing the Aki sisters' 4-19 red maple stage")
	if stage.is_empty():
		quit(1)
		return
	check(stage.terrain == "autumn_maple" and stage.row_count == 6, "4-19 has its independent six-row maple clearing")
	check(stage.get("water_rows", []) == [] and not String(stage.terrain).contains("fog"), "All six maple lanes are dry and free of fog")
	check(stage.unlock_requirements == ["4-18"], "The maple route follows 4-18")
	check(stage.mid_boss_kind == "shizuha_boss" and not stage.get("mid_boss_final_preview", false), "Shizuha is the distinct road encounter")
	check(stage.boss_intro_bgm == "res://audio/bgm/touhou/4-19-stage.mp3", "The supplied road music belongs before Minoriko")
	check(stage.boss_bgm == "res://audio/bgm/touhou/4-19-ending.mp3", "The supplied finale music belongs to Minoriko")
	check(stage.events.back().kind == "minoriko_boss", "Minoriko closes the stage")
	check(Difficulty.options(stage) == ["easy", "normal", "hard", "lunatic"], "All four standard difficulties are selectable")
	for rank in range(4):
		var choice: String = ["easy", "normal", "hard", "lunatic"][rank]
		var level: Dictionary = Difficulty.build_level(stage, choice)
		var canon: Array = []
		var canon_ids: Array = []
		var originals := 0
		for entry in Spells.cards_for("minoriko_boss", level):
			var card: Dictionary = Spells.card_from_entry(entry)
			if card.origin == "canon":
				canon.append(card.name)
				canon_ids.append(String(card.id).right(3))
			if card.origin == "original": originals += 1
		var expected: Array = ["秋符「秋之天空」", "丰符「大年收获者」"] if rank < 2 else ["秋符「秋之天空与少女之心」", "丰收「谷物神的允诺」"]
		var expected_ids: Array = [["003", "007"], ["004", "008"], ["005", "009"], ["006", "010"]][rank]
		check(canon == expected and canon_ids == expected_ids, choice + ": preserve both actual TH10 stage-one spell variants")
		check(originals == rank + 1, choice + ": PvZ-specific originals accumulate with difficulty")
		check(Spells.phases_for("minoriko_boss", level).size() == rank + 3, choice + ": the finale has a complete per-card phase route")
		var road_canon: Array = []
		for entry in Spells.cards_for("shizuha_boss", level):
			var card: Dictionary = Spells.card_from_entry(entry)
			if card.origin == "canon": road_canon.append([card.name, String(card.id).right(3)])
		check(road_canon == ([] if rank < 2 else [["叶符「狂乱的落叶」", "001" if rank == 2 else "002"]]), choice + ": Shizuha's canon spell is restricted to Hard and Lunatic")
		check((level.mode == "normal") == (rank == 3), "Only Lunatic offers free manual seed selection")
		check(level.terrain == "autumn_maple" and level.row_count == 6 and level.get("water_rows", []) == [], "Difficulty selection preserves six dry maple rows")
		check(level.events.back().kind == "minoriko_boss", "Additional difficulty waves precede the finale")
	for event in stage.events: check(Defs.ZOMBIES.has(event.kind), "Registered maple enemy " + event.kind)
	for plant in stage.conveyor_plants:
		check(Defs.PLANTS.has(plant), "Registered maple seed " + plant)
		check(not plant in ["lily_pad", "tangle_kelp", "sea_shroom"], "The dry maple conveyor does not waste deliveries on water-only plants")
	print("Aki 4-19 six-row dryland, BGM and four canon/original routes: %d failure(s)" % failures)
	quit(1 if failures else 0)
