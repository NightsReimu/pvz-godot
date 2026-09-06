extends RefCounted

const Spells = preload("res://scripts/data/touhou_spell_defs.gd")


static func start(boss: Dictionary, level: Dictionary) -> void:
	var phases := Spells.phases_for(String(boss.get("kind", "")), level)
	if phases.is_empty():
		return
	boss["touhou_encounter"] = {"phases": phases, "index": 0, "attack": 0, "completed": 0, "casting": false, "depleted": false, "complete": false}
	boss["boss_skill_timer"] = 1.6
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
