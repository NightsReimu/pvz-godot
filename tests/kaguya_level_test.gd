extends "res://tests/eirin_level_test.gd"

func _initialize() -> void:
	var a: Dictionary = {}
	var b: Dictionary = {}
	var reisen: Dictionary = {}
	for level in Defs.LEVELS:
		if level.id == "3-24-a": a = level
		if level.id == "3-24-b": b = level
		if level.id == "3-23": reisen = level
	check(not b.is_empty(), "6B exists")
	if b.is_empty():
		quit(1)
		return
	for key in a:
		if key not in ["id", "title", "description", "node_pos", "branch_from", "boss_bgm", "events"]:
			check(a[key] == b[key], "6A and 6B road match: " + key)
	check(a.events.slice(0, -1) == b.events.slice(0, -1), "Every road event is shared")
	check(a.events.back().kind == "eirin_boss" and b.events.back().kind == "kaguya_boss", "Copy does not mutate 6A finale")
	check(b.unlock_requirements == ["3-23"] and b.mid_boss_kind == "eirin_boss" and b.mid_boss_final_preview, "6B branches after Reisen with the same preview road")
	check(reisen.events.filter(func(e): return e.kind == "rabbit_airship").size() == 2, "Reisen has two authored airship events")
	check(FileAccess.file_exists(b.boss_bgm), "Supplied finale music exists")
	for rank in range(4):
		var level := Difficulty.build_level(b, ["easy", "normal", "hard", "lunatic"][rank])
		var cards := Spells.cards_for("kaguya_boss", level)
		var phases := Spells.phases_for("kaguya_boss", level)
		check(cards.size() == 10 and phases.size() == 10 + rank, "Five treasures and five nights plus originals")
		for index in range(10):
			check(cards[index][0] == "th08-%d" % (152 + index * 4 + rank), "Correct 6B canonical spell number")
		for index in range(5):
			check(phases[phases.size()-5+index][0][2] == "kaguya_night_%d" % index, "Five uninterrupted final Last Spells")
		check((level.mode == "normal") == (rank == 3), "Lunatic seed selection")
	for index in range(24):
		var texture: Texture2D = load("res://art/kaguya/frame_%02d.png" % index)
		check(texture != null, "Original frame exists")
		if texture != null:
			var im := texture.get_image()
			check(im.get_size() == Vector2i(256,256) and im.get_pixel(0,0).a == 0, "Uniform transparent sprite canvas")
	print("Kaguya shared road, canonical routes, assets and airships: %d failure(s)" % failures)
	quit(1 if failures else 0)
