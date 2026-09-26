extends SceneTree
const Game = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var base: Dictionary = {}
	for level in Defs.LEVELS:
		if level.id == "3-25": base = level
	check(not base.is_empty(), "3-25 must exist")
	if base.is_empty():
		quit(1)
		return
	check(Difficulty.options(base) == ["extra", "extra_plus"], "Only EX and EX+ are offered")
	check(base.mid_boss_kind == "hakutaku_boss" and base.events.back().kind == "mokou_boss", "Distinct Keine road and Mokou finale")
	check(not base.get("mid_boss_final_preview", false), "Keine must play every mandatory card")
	check(base.terrain == "reimu_midnight_bamboo", "Use the dark midnight bamboo background")
	for path in [base.boss_intro_bgm, base.boss_bgm]: check(FileAccess.file_exists(path), "Supplied music exists")
	for choice in ["extra", "extra_plus"]:
		var level := Difficulty.build_level(base, choice)
		for event in level.events:
			check(event.kind in base.enemy_whitelist or event.kind == "mokou_boss", "No forbidden road enemy: " + event.kind)
		for kind in ["hakutaku_boss", "mokou_boss"]:
			var ids: Array = []
			for phase in Spells.phases_for(kind, level):
				for entry in phase:
					if String(entry[0]).begins_with("th08-"): ids.append(entry[0])
			var first := 192 if kind == "hakutaku_boss" else 195
			var count := 3 if kind == "hakutaku_boss" else 11
			check(ids.size() == count, "Every canonical spell appears once")
			for n in range(count): check(ids.has("th08-%d" % (first+n)), "Missing original spell number")
			if choice == "extra_plus":
				check(Spells.phase_count(kind, level) > Spells.phase_count(kind, Difficulty.build_level(base, "extra")), "EX+ has additional moves")
		var finale: Array = Spells.phases_for("mokou_boss", level).back()
		check(finale.back()[2] == "mokou_imperishable", "Imperishable Shooting stays last")
	print("TH08 Extra level contracts: %d failure(s)" % failures)
	quit(1 if failures else 0)
