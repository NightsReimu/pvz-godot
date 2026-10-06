extends RefCounted

const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const SELF_MIDBOSS_HEALTH_RATIO := 0.09
const ROAD_HEALTH_RATIO := 0.18
const ROAD_FINALE_CAP := 0.10
const FINALE_HEALTH_MULTIPLIER := 1.95
const SPELL_DAMAGE_FACTOR := 0.125


static func spell_damage_factor(boss: Dictionary) -> float:
	var kind := String(boss.get("kind", ""))
	if not Spells.CARDS.has(kind) and not Spells.Difficulty.boss_kinds().has(kind):
		return 1.0
	if float(boss.get("health", 0.0)) <= 0.0 or float(boss.get("touhou_cast_remaining", 0.0)) <= 0.0:
		return 1.0
	if bool(boss.get("touhou_encounter", {}).get("complete", false)) and not bool(boss.get("yuyuko_revived", false)):
		return 1.0
	var card: Dictionary = boss.get("touhou_card", {})
	if String(card.get("origin", "")) not in ["canon", "original"]:
		return 1.0
	var pattern := String(card.get("pattern", ""))
	if pattern.is_empty() or pattern.begins_with("nonspell_"):
		return 1.0
	return SPELL_DAMAGE_FACTOR


static func configure_health(boss: Dictionary, level: Dictionary, definitions: Dictionary) -> void:
	# Spawn owns role scaling, before phase floors/HUD bounds are calculated.
	var preview := bool(boss.get("touhou_final_preview", false))
	var road := preview or (String(boss.kind) == String(level.get("mid_boss_kind", "")) and not bool(level.get("mid_boss_final_preview", false)))
	var health := float(boss.max_health)
	if road:
		health *= SELF_MIDBOSS_HEALTH_RATIO if preview else ROAD_HEALTH_RATIO
		var finale_health := 0.0
		for event in level.get("events", []):
			var kind := String(event.get("kind", ""))
			if Spells.Difficulty.boss_kinds().has(kind):
				finale_health = float(definitions[kind].health) * float(Spells.Difficulty.profile(level).health)
		if finale_health > 0: health = minf(health, finale_health * ROAD_FINALE_CAP)
	else:
		health *= FINALE_HEALTH_MULTIPLIER
	boss["touhou_road_boss"] = road
	boss.max_health = health
	boss.health = health


static func start(boss: Dictionary, level: Dictionary) -> void:
	var phases := Spells.phases_for(String(boss.get("kind", "")), level)
	if bool(boss.get("touhou_road_boss", false)):
		var road_phases: Array = []
		for phase in phases:
			var attacks: Array = phase.filter(func(entry): return entry.size() <= 4 or not bool(entry[4].get("finale_only", false)))
			if not attacks.is_empty(): road_phases.append(attacks)
		phases = road_phases
	if phases.is_empty():
		return
	if bool(boss.get("touhou_final_preview", false)):
		phases = [[phases[0][0].duplicate(true)]]
		if String(boss.kind) == "hina_boss":
			phases = [[Spells.Hina.road_card(level)]]
			boss["touhou_road_spell"] = true
		if String(boss.kind) == "eirin_boss":
			phases = [[Spells.Eirin.road_card(level)]]
		if String(boss.kind) == "nitori_boss":
			# TH10 3: she first harries from optical camouflage, then declares.
			phases = Spells.Nitori.road_phases(level)
			boss["touhou_road_spell"] = true
			boss["nitori_camouflaged"] = true
	if String(boss.kind) == String(level.get("mid_boss_kind", "")) and bool(level.get("mid_boss_nonspell_only", false)):
		# Different-character roads retain their authored nonspell identity.
		phases = [[phases[0][0].duplicate(true)]]
		boss["touhou_road_nonspell"] = true
	boss["touhou_encounter"] = {"phases": phases, "index": 0, "attack": 0, "completed": 0, "casting": false, "depleted": false, "complete": false}
	boss["boss_skill_timer"] = 3.2 if bool(boss.get("touhou_road_spell", false)) else 1.6
	if String(boss.kind) == "nitori_boss" and bool(boss.get("touhou_final_preview", false)):
		boss["boss_skill_timer"] = 1.4
	_set_bounds(boss)


static func _set_bounds(boss: Dictionary) -> void:
	var encounter: Dictionary = boss.touhou_encounter
	var count: int = encounter.phases.size()
	var health := float(boss.max_health)
	encounter["max_health"] = health
	encounter["ceiling"] = health * (1.0 - float(encounter.index) / count)
	encounter["floor"] = health * (1.0 - float(int(encounter.index) + 1) / count)
	# Existing pressure and image-scale consumers expect four bounded intensity tiers.
	boss["boss_phase"] = roundi(3.0 * float(encounter.index) / maxf(1.0, count - 1))


static func guard_health(boss: Dictionary) -> void:
	if not boss.has("touhou_encounter") or bool(boss.get("yuyuko_revived", false)):
		return
	# Basic road attacks can end on damage; declared spells keep their attack gates.
	if (bool(boss.get("touhou_final_preview", false)) and not bool(boss.get("touhou_road_spell", false))) or bool(boss.get("touhou_road_nonspell", false)):
		if float(boss.health) <= 0.0:
			boss.health = 0.0
			boss.touhou_encounter.complete = true
		return
	var encounter: Dictionary = boss.touhou_encounter
	if bool(encounter.complete):
		boss.health = 0.0
		return
	if not is_equal_approx(float(encounter.max_health), float(boss.max_health)):
		_set_bounds(boss)
	if float(boss.health) <= float(encounter.floor):
		encounter.depleted = true
	if bool(encounter.depleted):
		# Keep a targetable owner alive until this segment's mandatory attacks finish.
		boss.health = float(encounter.floor) + 0.01
	else:
		boss.health = minf(float(boss.health), float(encounter.ceiling))


static func health_ceiling(boss: Dictionary) -> float:
	guard_health(boss)
	if boss.has("touhou_encounter") and not bool(boss.get("yuyuko_revived", false)):
		if bool(boss.touhou_encounter.complete):
			return 0.0
		return float(boss.touhou_encounter.floor) + 0.01 if bool(boss.touhou_encounter.depleted) else float(boss.touhou_encounter.ceiling)
	return float(boss.get("max_health", 0.0))


static func update_progress(game: Control, boss: Dictionary) -> bool:
	if not boss.has("touhou_encounter") or bool(boss.get("yuyuko_revived", false)):
		return false
	var encounter: Dictionary = boss.touhou_encounter
	if bool(encounter.complete):
		return false
	guard_health(boss)
	if float(boss.get("touhou_cast_remaining", 0.0)) > 0.0:
		return false
	var attacks: Array = encounter.phases[int(encounter.index)]
	if bool(encounter.casting):
		encounter.casting = false
		encounter.completed = mini(int(encounter.completed) + 1, attacks.size())
		encounter.attack = (int(encounter.attack) + 1) % attacks.size()
		boss["boss_skill_timer"] = 1.0 if int(encounter.completed) < attacks.size() else game._boss_skill_interval(String(boss.kind), int(boss.boss_phase))
		boss["boss_pause_timer"] = 0.65
	if not bool(encounter.depleted) or int(encounter.completed) < attacks.size():
		return false
	if String(boss.kind) == "hina_boss" and game.hina_runtime != null:
		game.hina_runtime.clear_owner(int(boss.uid))
	if String(boss.kind) in ["shizuha_boss", "minoriko_boss"] and game.aki_runtime != null:
		game.aki_runtime.clear_owner(int(boss.uid))
	if String(boss.kind) == "suika_boss" and game.suika_runtime != null:
		game.suika_runtime.clear_owner(int(boss.uid))
	if String(boss.kind) == "nitori_boss" and game.nitori_runtime != null:
		game.nitori_runtime.clear_owner(int(boss.uid))
	if String(boss.kind) in ["momiji_boss", "aya_boss"] and game.tengu_runtime != null:
		game.tengu_runtime.clear_owner(int(boss.uid))
	if game.touhou_danmaku != null and boss.has("touhou_owner"):
		game.touhou_danmaku.clear_owner(int(boss.touhou_owner))
	if int(encounter.index) + 1 >= encounter.phases.size():
		encounter.complete = true
		boss.health = 0.0
		return true
	encounter.index += 1
	encounter.attack = 0
	encounter.completed = 0
	encounter.depleted = false
	_set_bounds(boss)
	boss.health = encounter.ceiling
	boss["boss_cast_pending"] = false
	boss["boss_skill_cycle"] = 0
	boss["boss_skill_timer"] = 1.2
	boss["boss_pause_timer"] = 1.0
	for key in ["boss_hud_health", "boss_hud_trail", "boss_hud_hold", "killed_by_mower"]:
		boss.erase(key)
	game._trigger_boss_phase_shift(boss, int(boss.boss_phase))
	var name := String(game.Defs.ZOMBIES[String(boss.kind)].name)
	game._show_banner("%s · 阶段 %d / %d" % [name, int(encounter.index) + 1, Spells.phase_count(String(boss.kind), game.current_level)], 1.3)
	return true
