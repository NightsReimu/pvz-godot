extends RefCounted
class_name LevelDifficulty

const ZombieDefs = preload("res://scripts/data/zombie_defs.gd")

const HARD_EXTRA_ZOMBIES := ["conehead", "buckethead", "newspaper", "screen_door", "football", "ninja", "shieldbearer_zombie"]

static func build_hard_level(base: Dictionary) -> Dictionary:
	var level := base.duplicate(true)
	level["regular_difficulty"] = "hard"
	level["hard_mode"] = true
	level["title"] = "%s · 困难" % String(base.get("title", base.get("id", "关卡")))
	level["description"] = "困难：僵尸数量与波数至少提升至普通的两倍，并加入额外敌人。"
	var source_events: Array = Array(base.get("events", [])).duplicate(true)
	var regular_events: Array = []
	var boss_events: Array = []
	for event_variant in source_events:
		var event := Dictionary(event_variant).duplicate(true)
		var kind := String(event.get("kind", event.get("zombie", "")))
		if bool(ZombieDefs.ZOMBIES.get(kind, {}).get("boss", false)):
			boss_events.append(event)
		else:
			regular_events.append(event)

	var first_end := _last_event_time(regular_events)
	var shift := maxf(first_end + 8.0, 18.0)
	var hard_events: Array = []
	for event in regular_events:
		hard_events.append(event.duplicate(true))
	for event in regular_events:
		var copy: Dictionary = event.duplicate(true)
		copy["time"] = float(copy.get("time", 0.0)) + shift
		hard_events.append(copy)

	# Add a small rotating set of tougher ordinary enemies without touching any
	# boss or stage-specific special event.
	var extras := _extra_kinds(base)
	var extra_index := 0
	for i in range(hard_events.size()):
		var candidate := Dictionary(hard_events[i])
		if not _is_spawn_event(candidate) or i % 7 != 4 or extras.is_empty():
			continue
		var extra := candidate.duplicate(true)
		extra["kind"] = extras[extra_index % extras.size()]
		extra["time"] = float(candidate.get("time", 0.0)) + 0.45
		hard_events.append(extra)
		extra_index += 1

	var target_waves := maxi(2, _wave_count(source_events) * 2)
	var missing_waves := maxi(0, target_waves - _wave_count(hard_events))
	# Very short tutorial stages have no explicit flags; hard mode still gets
	# two visible pressure breaks. Boss-wave flags are also counted here so the
	# displayed wave total is genuinely at least double the ordinary stage.
	for wave_index in range(missing_waves):
		hard_events.append({"time": shift * (0.42 + float(wave_index + 1) / float(missing_waves + 1)), "kind": "flag", "wave": true})

	hard_events.sort_custom(func(a, b): return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	var final_time := _last_event_time(hard_events) + 8.0
	for event in boss_events:
		var boss: Dictionary = event.duplicate(true)
		boss["time"] = final_time
		hard_events.append(boss)
		final_time += 4.0
	hard_events.sort_custom(func(a, b): return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	level["events"] = hard_events
	level["hard_wave_multiplier"] = 2.0
	level["hard_zombie_multiplier"] = 2.0
	return level

static func _last_event_time(events: Array) -> float:
	var result := 0.0
	for event_variant in events:
		result = maxf(result, float(Dictionary(event_variant).get("time", 0.0)))
	return result

static func _wave_count(events: Array) -> int:
	var result := 0
	for event_variant in events:
		var event := Dictionary(event_variant)
		if bool(event.get("wave", false)) or String(event.get("kind", "")) == "flag":
			result += 1
	return result

static func _is_spawn_event(event: Dictionary) -> bool:
	var kind := String(event.get("kind", event.get("zombie", "")))
	return kind != "" and kind != "flag" and not bool(event.get("wave", false)) and ZombieDefs.ZOMBIES.has(kind)

static func _extra_kinds(base: Dictionary) -> Array:
	var result: Array = []
	for kind in HARD_EXTRA_ZOMBIES:
		if not ZombieDefs.ZOMBIES.has(kind):
			continue
		if bool(ZombieDefs.ZOMBIES[kind].get("boss", false)):
			continue
		result.append(kind)
	return result
