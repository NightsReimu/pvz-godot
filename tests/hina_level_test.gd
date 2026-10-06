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
		if level.id == "4-20": stage = level
	check(not stage.is_empty(), "Missing Hina's independent 4-20 mountain forest stage")
	if stage.is_empty():
		quit(1)
		return
	check(stage.terrain == "hina_mountain_forest" and stage.row_count == 6, "Hina uses an independent six-row mountain forest")
	check(stage.get("water_rows", []) == [] and not String(stage.terrain).contains("fog"), "All six mountain lanes are dry and clear")
	check(stage.unlock_requirements == ["4-19"], "The mountain route follows the Aki sisters")
	check(stage.mid_boss_kind == "hina_boss" and stage.get("mid_boss_final_preview", false), "Road and finale use distinct instances of the same Hina character")
	check(Spells.card_from_entry(Spells.Hina.road_card(stage)).origin == "canon", "Road Hina must declare one real canonical spell")
	check(stage.events.back().kind == "hina_boss", "The full Hina closes the stage")
	check(stage.boss_intro_bgm == "res://audio/bgm/touhou/4-20-stage.mp3" and stage.boss_bgm == "res://audio/bgm/touhou/4-20-ending.mp3", "The supplied stage and ending tracks retain their intended roles")
	check(Difficulty.options(stage) == ["easy", "normal", "hard", "lunatic"], "All four standard difficulties are available")
	for rank in range(4):
		var choice: String = ["easy", "normal", "hard", "lunatic"][rank]
		var level: Dictionary = Difficulty.build_level(stage, choice)
		var road: Dictionary = Spells.card_from_entry(Spells.Hina.road_card(level))
		check(road.id == "th10-%03d" % (11 + rank) and road.origin == "canon", choice + ": road retains the correct TH10 spell-practice identity")
		var canon_ids: Array = []
		var canon := 0
		var originals := 0
		var identities: Array = []
		for entry in Spells.cards_for("hina_boss", level):
			var card: Dictionary = Spells.card_from_entry(entry)
			if card.origin == "canon":
				canon += 1
				canon_ids.append(card.id)
			if card.origin == "original": originals += 1
			check(not identities.has(card.id), choice + ": Hina's spell identities are distinct")
			identities.append(card.id)
		check(canon_ids == ["th10-%03d" % (15 + rank), "th10-%03d" % (19 + rank), "th10-%03d" % (23 + rank)], choice + ": finale preserves its three original difficulty variants")
		check(bool(Spells.card_from_entry(Spells.cards_for("hina_boss", level).back()).get("last_spell", false)), choice + ": the final original card is marked as last spell")
		check(canon == 3, choice + ": Hina retains the three TH10 stage-two cards")
		check(originals == rank + 1, choice + ": original PvZ cards accumulate by difficulty")
		check(Spells.phases_for("hina_boss", level).size() == rank + 6, choice + ": finale has six through nine full spell phases")
		check(level.terrain == "hina_mountain_forest" and level.row_count == 6 and level.get("water_rows", []) == [], "Difficulty selection preserves six dry forest lanes")
		check((level.mode == "normal") == (rank == 3), "Only Lunatic uses manual seed selection")
		check(level.events.back().kind == "hina_boss", "Extra difficulty waves precede Hina")
	for event in stage.events: check(Defs.ZOMBIES.has(event.kind), "Registered forest enemy " + event.kind)
	for kind in stage.conveyor_plants:
		check(Defs.PLANTS.has(kind), "Registered forest seed " + kind)
		check(not kind in ["lily_pad", "tangle_kelp", "sea_shroom"], "The dry forest belt avoids water-only seeds")
	print("Hina 4-20 dry six-row stage, same-character road spell and four routes: %d failure(s)" % failures)
	quit(1 if failures else 0)
