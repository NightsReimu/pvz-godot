extends "res://tests/touhou_encounter_test.gd"

const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const SHORT_KINDS := ["rumia_boss", "letty_boss", "daiyousei_boss", "koakuma_boss", "lily_white_boss", "shizuha_boss", "tewi_boss"]

func _run() -> void:
	var snapshot = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/touhou_v174_routes.json"))
	check(snapshot != null and snapshot.routes.size() == 98, "Preserve the 98 real v174 Touhou route variants")
	if snapshot == null:
		quit(1)
		return
	var variants := 0
	for route in snapshot.routes:
		var base: Dictionary = {}
		for candidate in Game.Defs.LEVELS:
			if candidate.id == route.id: base = candidate
		var level := Difficulty.build_level(base, route.choice)
		var phases: Array = Spells.phases_for(route.kind, level)
		var extra := 3 if String(route.kind) in SHORT_KINDS else 2
		check(phases.size() == int(route.phases) + extra, "%s/%s receives complete new original phases" % [route.id, route.choice])
		check(phases.back().back()[0] == route.last, "Keep the real ending/rebirth sequence in its original final position")
		var canon: Array = []
		var additions: Array = []
		var patterns: Array = []
		for phase in phases:
			for entry in phase:
				if not String(entry[0]).begins_with("original-") and not String(entry[0]).ends_with("nonspell"): canon.append(entry[0])
				if entry.size() > 4 and bool(entry[4].get("finale_only", false)):
					additions.append(entry[0])
					patterns.append(entry[2])
					check(String(entry[0]).begins_with("original-") and String(entry[1]).begins_with("原创"), "New spells must never claim canonical provenance")
					check(float(entry[4].duration) >= 6.5 and float(entry[4].duration) <= 7.5 and not bool(entry[4].get("survival", false)), "New cards have bounded active durations and remain damageable")
		check(canon == route.canon, "Keep every actual canonical ID and relative order")
		check(additions.size() == extra and patterns.size() == extra, "Add real distinct moves rather than repeated authored phases")
		var mid := String(level.get("mid_boss_kind", ""))
		if not mid.is_empty():
			var game := make_game(mid)
			game.zombies.clear()
			game.current_level = level
			game._spawn_frozen_branch_midboss()
			var road: Dictionary = game.zombies.filter(func(z): return String(z.kind) == mid).back()
			check(road.touhou_encounter.phases.size() == int(route.road), "Road bosses keep the same incomplete authored route")
			for phase in road.touhou_encounter.phases:
				for entry in phase: check(entry.size() <= 4 or not bool(entry[4].get("finale_only", false)), "No full-strength new phase leaks into a road encounter")
			release(game)
		variants += 1
	_test_flandre_terminal_blocks()
	print("Touhou expanded finales: %d routes, canonical order, original provenance, durations, unchanged road gates and consecutive EX/EX+ endings; %d failure(s)" % [variants, failures])
	quit(1 if failures else 0)

func _test_flandre_terminal_blocks() -> void:
	for choice in ["extra", "extra_plus"]:
		var level := {"id": "1-23", "touhou_difficulty": choice}
		var phases: Array = Spells.phases_for("flandre_boss", level)
		check(String(phases[-2][-1][2]) == "and_then_none" and String(phases[-1][-1][2]) == "qed", choice + ": both legacy and new originals stay before the terminal survival/QED pair")
		for i in range(phases.size()):
			for entry in phases[i]:
				if String(entry[0]).begins_with("original-"): check(i < phases.size() - 2, "No original card splits Flandre's genuine ending block")
		var game := make_game("flandre_boss")
		game.current_level = level
		Game.TouhouPhaseRuntime.start(game.zombies[0], level)
		finish_encounter(game)
		var declared: Array = game.declarations.map(func(d): return String(d.id)).filter(func(id): return not id.ends_with("nonspell"))
		check(declared[-2] == "th06-63" and declared[-1] == "th06-64", choice + ": actual mandatory casts end with consecutive canonical cards")
		release(game)
