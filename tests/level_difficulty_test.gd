extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")
const TouhouDifficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const LevelDifficulty = preload("res://scripts/data/level_difficulty.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var checked := 0
	for level_variant in Defs.LEVELS:
		var level: Dictionary = level_variant
		if TouhouDifficulty.is_touhou(level) or bool(level.get("custom_level", false)):
			continue
		var base_events: Array = Array(level.get("events", []))
		var hard: Dictionary = LevelDifficulty.build_hard_level(level)
		if String(Dictionary(hard.get("hard_profile", {})).get("level_id", "")) != String(level.get("id", "")):
			_fail("Hard profile is not bound to concrete level %s" % level.id)
		var hard_events: Array = Array(hard.get("events", []))
		var base_zombies := _count_regular_events(base_events)
		var hard_zombies := _count_regular_events(hard_events)
		if hard_zombies < base_zombies * 2:
			_fail("Hard zombie count below 2x for %s: %d vs %d" % [level.id, hard_zombies, base_zombies])
		var base_waves := _count_waves(base_events)
		var hard_waves := _count_waves(hard_events)
		if hard_waves < maxi(2, base_waves * 2):
			_fail("Hard wave count below requirement for %s: %d vs %d" % [level.id, hard_waves, base_waves])
		checked += 1
	print("Level difficulty: %d non-Touhou levels checked, %d failure(s)" % [checked, failures])
	quit(1 if failures else 0)

func _count_regular_events(events: Array) -> int:
	var count := 0
	for event_variant in events:
		var event: Dictionary = event_variant
		var kind := String(event.get("kind", event.get("zombie", "")))
		if kind != "" and kind != "flag" and not bool(event.get("wave", false)):
			count += 1
	return count

func _count_waves(events: Array) -> int:
	var count := 0
	for event_variant in events:
		var event: Dictionary = event_variant
		if bool(event.get("wave", false)) or String(event.get("kind", "")) == "flag":
			count += 1
	return count

func _fail(message: String) -> void:
	failures += 1
	push_error(message)
