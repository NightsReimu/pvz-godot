extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const FusionZombies = preload("res://scripts/data/fusion_zombie_defs.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var stage: Dictionary = {}
	for level in Defs.LEVELS:
		if level.id == "4-21": stage = level
	check(not stage.is_empty(), "Missing Nitori's independent 4-21 waterfall stage")
	if stage.is_empty():
		quit(1)
		return
	check(stage.terrain == "nitori_waterfall" and stage.row_count == 6, "Nitori uses an independent six-row waterfall terrace")
	check(stage.get("water_rows", []) == [] and not String(stage.terrain).contains("fog") and not bool(stage.get("fog", false)), "All six lanes are dry and the rain never becomes fog")
	check(stage.unlock_requirements == ["4-20"], "Genbu Ravine follows Hina's mountain road")
	check(stage.mid_boss_kind == "nitori_boss" and stage.get("mid_boss_final_preview", false), "Road and finale use distinct instances of the same Nitori character")
	check(stage.events.back().kind == "nitori_boss", "The full Nitori closes the stage")
	check(stage.boss_intro_bgm == "res://audio/bgm/touhou/4-21-stage.mp3" and stage.boss_bgm == "res://audio/bgm/touhou/4-21-ending.mp3", "The supplied stage and ending tracks retain their roles")
	check(Difficulty.options(stage) == ["easy", "normal", "hard", "lunatic"], "All four standard difficulties are available")
	var fused := 0
	for kind in stage.enemy_whitelist:
		check(Defs.ZOMBIES.has(kind), "Registered ravine enemy " + kind)
		if FusionZombies.RECIPES.has(kind): fused += 1
	check(fused * 3 >= stage.enemy_whitelist.size() * 2, "At least two thirds of the ravine roster are fusion zombies")
	var event_fused := 0
	var event_enemies := 0
	for event in stage.events:
		check(Defs.ZOMBIES.has(event.kind) or event.kind == "flag", "Registered ravine event " + event.kind)
		if event.kind in ["flag", "nitori_boss"]: continue
		event_enemies += 1
		if FusionZombies.RECIPES.has(event.kind): event_fused += 1
	check(event_fused * 3 >= event_enemies * 2, "Most scripted arrivals already wear fused gear")
	for kind in stage.conveyor_plants:
		check(Defs.PLANTS.has(kind), "Registered ravine seed " + kind)
		check(not kind in ["lily_pad", "tangle_kelp", "sea_shroom"], "The dry terrace belt avoids water-only seeds")
	for counter in ["plantern", "umbrella_leaf", "magnet_shroom"]:
		check(stage.conveyor_plants.has(counter) and stage.available_plants.has(counter), "The belt and Lunatic list both carry " + counter)
	var cards_seen := {}
	for rank in range(4):
		var choice: String = ["easy", "normal", "hard", "lunatic"][rank]
		var level: Dictionary = Difficulty.build_level(stage, choice)
		var road_phases: Array = Spells.Nitori.road_phases(level)
		var road: Dictionary = Spells.card_from_entry(road_phases[0][1])
		check(road_phases.size() == 1 and road_phases[0].size() == 2, choice + ": road is one camouflaged nonspell followed by one spell")
		check(Spells.card_from_entry(road_phases[0][0]).origin == "nonspell", choice + ": the road opens from camouflage before declaring")
		check(road.id == "th10-%03d" % (27 + rank) and road.origin == "canon", choice + ": road keeps the TH10 027–030 identity")
		check(road.name == ("光学「水迷彩」" if rank >= 2 else "光学「光学迷彩」"), choice + ": road uses the correct optics card name")
		var canon_ids: Array = []
		var originals := 0
		var identities: Array = []
		for entry in Spells.cards_for("nitori_boss", level):
			var card: Dictionary = Spells.card_from_entry(entry)
			if card.origin == "canon": canon_ids.append(card.id)
			if card.origin == "original": originals += 1
			check(not identities.has(card.id), choice + ": Nitori's spell identities are distinct")
			identities.append(card.id)
			cards_seen[card.pattern] = true
		check(canon_ids == ["th10-%03d" % (31 + rank), "th10-%03d" % (35 + rank), "th10-%03d" % (39 + rank)], choice + ": finale preserves its three TH10 difficulty variants")
		check(originals == rank + 1, choice + ": original PvZ cards accumulate by difficulty")
		check(bool(Spells.card_from_entry(Spells.cards_for("nitori_boss", level).back()).get("last_spell", false)), choice + ": the last original is marked as last spell")
		var phases: Array = Spells.phases_for("nitori_boss", level)
		check(phases.size() == rank + 6, choice + ": finale has six through nine spell phases")
		var finale_extra := 0
		for phase in phases:
			for entry in phase:
				if String(entry[0]).begins_with("original-finale-nitori_boss"): finale_extra += 1
		check(finale_extra == 2, choice + ": both original finale formations are present")
		check(level.terrain == "nitori_waterfall" and level.row_count == 6 and level.get("water_rows", []) == [], "Difficulty selection preserves six dry terrace lanes")
		check((level.mode == "normal") == (rank == 3), "Only Lunatic uses manual seed selection")
		if rank == 3: check(level.available_plants.has("sunflower"), "Lunatic manual selection supplies a sun producer")
		check(level.events.back().kind == "nitori_boss", "Extra difficulty waves precede Nitori")
	for pattern in ["nitori_ooze_flooding", "nitori_diluvial_mare", "nitori_glimmering_trauma", "nitori_pororoca", "nitori_flash_flood", "nitori_great_waterfall", "nitori_spook_cucumber", "nitori_extend_arm", "nitori_cephalic_plate", "nitori_camo_squad", "nitori_cucumber_bait", "nitori_water_cannon", "nitori_workshop"]:
		check(cards_seen.has(pattern), "Some difficulty reaches " + pattern)
	var lunatic_names: Array = Spells.cards_for("nitori_boss", Difficulty.build_level(stage, "lunatic")).map(func(entry): return String(entry[1]))
	check(lunatic_names.has("漂溺「粼粼水底之心伤」") and lunatic_names.has("水符「河童之幻想大瀑布」") and lunatic_names.has("河童「回转顶板」"), "Lunatic uses the three TH10 Lunatic names")
	check(Defs.ZOMBIES.nitori_boss.boss and Defs.ZOMBIES.nitori_cucumber.boss_summon and Defs.ZOMBIES.nitori_cucumber.balance_fixed, "Boss and cucumber bait are registered with the right roles")
	print("Nitori 4-21 dry six-row waterfall stage, camouflaged road, fusion roster and four routes: %d failure(s)" % failures)
	quit(1 if failures else 0)
