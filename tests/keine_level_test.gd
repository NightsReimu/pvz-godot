extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")


func _initialize() -> void:
	var stage: Dictionary = {}
	for level in Defs.LEVELS:
		if String(level.id) == "3-21":
			stage = level
	if stage.is_empty():
		push_error("Missing Keine stage 3-21")
		quit(1)
		return
	assert(stage.terrain == "keine_moonlit_forest")
	assert(stage.row_count == 6 and stage.get("water_rows", []).is_empty())
	assert(stage.get("mid_boss_kind", "").is_empty())
	assert(stage.unlock_requirements == ["3-20"])
	assert(stage.mode == "conveyor")
	assert(stage.boss_intro_bgm == "res://audio/th08_keine_stage.mp3")
	assert(stage.boss_bgm == "res://audio/th08_keine_boss.mp3")
	var bosses := 0
	for event in stage.events:
		assert(Defs.ZOMBIES.has(event.kind))
		if bool(Defs.ZOMBIES[event.kind].get("boss", false)):
			assert(event.kind == "keine_boss")
			bosses += 1
	assert(bosses == 1)
	for kind in stage.conveyor_plants:
		assert(Defs.PLANTS.has(kind), "Invalid conveyor plant: " + kind)
	var cards: Array = Spells.cards_for("keine_boss", stage)
	var canonical: Array = []
	var originals := 0
	for entry in cards:
		if String(entry[0]).begins_with("original-"):
			originals += 1
		else:
			canonical.append(entry[0])
	assert(canonical == ["th08-037", "th08-041", "th08-045", "th08-049", "th08-052"])
	assert(originals == 3)
	assert(Spells.phase_count("keine_boss", stage) == 5)
	print("Keine level and canonical spell contracts passed")
	quit()
