extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_conveyor_levels_exclude_sun_generators() or failed
	failed = not _test_pool_conveyor_levels_3_9_and_3_10_exist_with_expected_wave_counts() or failed
	failed = not _test_pool_conveyor_levels_bias_toward_lily_pads() or failed
	failed = not _test_3_10_uses_all_seen_non_boss_zombies() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _sun_producer_kinds() -> Dictionary:
	var producers := {}
	for kind in Defs.PLANTS.keys():
		var data = Defs.PLANTS[kind]
		if float(data.get("sun_interval", 0.0)) > 0.0:
			producers[String(kind)] = true
	return producers


func _find_level(level_id: String) -> Dictionary:
	for level in Defs.LEVELS:
		if String(level.get("id", "")) == level_id:
			return level
	return {}


func _wave_count(level: Dictionary) -> int:
	var count := 0
	for event in level.get("events", []):
		if bool(event.get("wave", false)):
			count += 1
	return count


func _event_kinds(level: Dictionary) -> Dictionary:
	var kinds := {}
	for event in level.get("events", []):
		var kind = String(event.get("kind", ""))
		if kind != "":
			kinds[kind] = true
	return kinds


func _count_kind(entries: Array, kind: String) -> int:
	var count := 0
	for entry in entries:
		if String(entry) == kind:
			count += 1
	return count


func _test_conveyor_levels_exclude_sun_generators() -> bool:
	var producers = _sun_producer_kinds()
	var offenders: Array = []
	for level in Defs.LEVELS:
		if String(level.get("mode", "")) != "conveyor":
			continue
		for list_name in ["available_plants", "conveyor_plants"]:
			for kind in level.get(list_name, []):
				var plant_kind = String(kind)
				if producers.has(plant_kind):
					offenders.append("%s:%s:%s" % [String(level["id"]), list_name, plant_kind])
	return _assert_true(
		offenders.is_empty(),
		"conveyor levels should not include sun producers: %s" % ", ".join(offenders)
	)


func _test_pool_conveyor_levels_3_9_and_3_10_exist_with_expected_wave_counts() -> bool:
	var level_3_9 = _find_level("3-9")
	var level_3_10 = _find_level("3-10")
	var passed = _assert_true(not level_3_9.is_empty(), "expected pool level 3-9 to exist") \
		and _assert_true(not level_3_10.is_empty(), "expected pool level 3-10 to exist")
	if level_3_9.is_empty() or level_3_10.is_empty():
		return false
	passed = _assert_true(String(level_3_9.get("terrain", "")) == "pool", "3-9 should stay in the pool world") and passed
	passed = _assert_true(String(level_3_10.get("terrain", "")) == "pool", "3-10 should stay in the pool world") and passed
	passed = _assert_true(String(level_3_9.get("mode", "")) == "conveyor", "3-9 should be a conveyor level") and passed
	passed = _assert_true(String(level_3_10.get("mode", "")) == "conveyor", "3-10 should be a conveyor level") and passed
	passed = _assert_true(_wave_count(level_3_9) == 3, "3-9 should contain exactly 3 waves") and passed
	passed = _assert_true(_wave_count(level_3_10) == 4, "3-10 should contain exactly 4 waves") and passed
	return passed


func _test_pool_conveyor_levels_bias_toward_lily_pads() -> bool:
	var level_3_9 = _find_level("3-9")
	var level_3_10 = _find_level("3-10")
	var passed = _assert_true(not level_3_9.is_empty(), "expected pool level 3-9 to exist for lily pad weighting") \
		and _assert_true(not level_3_10.is_empty(), "expected pool level 3-10 to exist for lily pad weighting")
	if level_3_9.is_empty() or level_3_10.is_empty():
		return false
	var lily_3_9 = _count_kind(level_3_9.get("conveyor_plants", []), "lily_pad")
	var lily_3_10 = _count_kind(level_3_10.get("conveyor_plants", []), "lily_pad")
	passed = _assert_true(lily_3_9 >= 4, "3-9 should give at least 4 lily_pad entries for pool support") and passed
	passed = _assert_true(lily_3_10 >= 5, "3-10 should give at least 5 lily_pad entries for pool support") and passed
	return passed


func _test_3_10_uses_all_seen_non_boss_zombies() -> bool:
	var expected := {}
	var seen_3_10 := false
	for level in Defs.LEVELS:
		var level_id = String(level.get("id", ""))
		if level_id == "3-10":
			seen_3_10 = true
			break
		for event in level.get("events", []):
			var kind = String(event.get("kind", ""))
			if kind == "":
				continue
			if Defs.ZOMBIES.has(kind) and bool(Defs.ZOMBIES[kind].get("boss", false)):
				continue
			expected[kind] = true
	if not _assert_true(seen_3_10, "expected to encounter 3-10 while scanning level order"):
		return false
	var level_3_10 = _find_level("3-10")
	if not _assert_true(not level_3_10.is_empty(), "expected 3-10 to exist for zombie coverage checks"):
		return false
	var actual = _event_kinds(level_3_10)
	var missing: Array = []
	for kind in expected.keys():
		if not actual.has(String(kind)):
			missing.append(String(kind))
	missing.sort()
	return _assert_true(
		missing.is_empty(),
		"3-10 should include every non-boss zombie seen so far, missing: %s" % ", ".join(missing)
	)
