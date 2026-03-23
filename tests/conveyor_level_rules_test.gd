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
	failed = not _test_pool_expansion_levels_3_11_to_3_18_exist() or failed
	failed = not _test_4_17_is_brine_only_and_uses_all_non_boss_zombies() or failed
	failed = not _test_4_18_conveyor_contains_every_fog_world_plant_except_lily_pad() or failed
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


func _all_non_boss_zombies() -> Dictionary:
	var result := {}
	for kind_variant in Defs.ZOMBIES.keys():
		var kind = String(kind_variant)
		if bool(Defs.ZOMBIES[kind].get("boss", false)):
			continue
		result[kind] = true
	return result


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


func _test_pool_expansion_levels_3_11_to_3_18_exist() -> bool:
	var expected_unlocks := {
		"3-11": "boomerang_shooter",
		"3-12": "sakura_shooter",
		"3-13": "lotus_lancer",
		"3-14": "mirror_reed",
		"3-16": "frost_fan",
	}
	var passed := true
	for number in range(11, 19):
		var level_id = "3-%d" % number
		var level = _find_level(level_id)
		passed = _assert_true(not level.is_empty(), "expected %s to exist in the pool expansion" % level_id) and passed
		if level.is_empty():
			continue
		passed = _assert_true(String(level.get("terrain", "")) == "pool", "%s should remain in the pool world" % level_id) and passed
		if expected_unlocks.has(level_id):
			var unlock_kind = String(expected_unlocks[level_id])
			passed = _assert_true(String(level.get("unlock_plant", "")) == unlock_kind, "%s should unlock %s" % [level_id, unlock_kind]) and passed
			passed = _assert_true(Defs.PLANTS.has(unlock_kind), "%s unlock plant %s should exist" % [level_id, unlock_kind]) and passed
	if not passed:
		return false

	var level_3_15 = _find_level("3-15")
	var level_3_18 = _find_level("3-18")
	passed = _assert_true(String(level_3_15.get("mode", "")) == "whack", "3-15 should be the special whack-style minigame stage") and passed
	passed = _assert_true(level_3_15.has("grave_layout") and level_3_15.get("grave_layout", []).size() >= 12, "3-15 should configure a dense grave layout for the minigame") and passed
	passed = _assert_true(bool(level_3_18.get("boss_level", false)), "3-18 should be marked as a boss level") and passed
	passed = _assert_true(String(level_3_18.get("mode", "")) == "conveyor", "3-18 should be a conveyor boss stage") and passed
	var event_kinds = _event_kinds(level_3_18)
	for kind in ["dragon_boat", "qinghua", "shouyue", "ice_block", "dragon_dance", "pool_boss"]:
		passed = _assert_true(event_kinds.has(kind), "3-18 should feature %s in its event roster" % kind) and passed
	return passed


func _test_4_17_is_brine_only_and_uses_all_non_boss_zombies() -> bool:
	var level = _find_level("4-17")
	if not _assert_true(not level.is_empty(), "expected 4-17 to exist before checking the brine gauntlet"):
		return false
	var passed = _assert_true(String(level.get("mode", "")) == "conveyor", "4-17 should be a conveyor level") \
		and _assert_true(String(level.get("terrain", "")) == "clear_backyard", "4-17 should use the clear backyard terrain")
	for kind in level.get("conveyor_plants", []):
		passed = _assert_true(String(kind) == "brine_pot", "4-17 conveyor should only contain brine_pot cards") and passed
	var actual = _event_kinds(level)
	var expected = _all_non_boss_zombies()
	var missing: Array = []
	for kind in expected.keys():
		if not actual.has(String(kind)):
			missing.append(String(kind))
	missing.sort()
	passed = _assert_true(missing.is_empty(), "4-17 should include every non-boss zombie, missing: %s" % ", ".join(missing)) and passed
	return passed


func _test_4_18_conveyor_contains_every_fog_world_plant_except_lily_pad() -> bool:
	var level = _find_level("4-18")
	if not _assert_true(not level.is_empty(), "expected 4-18 to exist before checking the fog boss conveyor"):
		return false
	var expected_plants = [
		"sea_shroom",
		"plantern",
		"cactus",
		"blover",
		"split_pea",
		"starfruit",
		"pumpkin",
		"magnet_shroom",
		"mist_orchid",
		"anchor_fern",
		"glowvine",
		"brine_pot",
		"storm_reed",
		"moonforge",
	]
	var conveyor_plants = level.get("conveyor_plants", [])
	var passed = _assert_true(String(level.get("mode", "")) == "conveyor", "4-18 should be a conveyor level") \
		and _assert_true(bool(level.get("boss_level", false)), "4-18 should be marked as a boss level") \
		and _assert_true(_count_kind(conveyor_plants, "lily_pad") == 0, "4-18 conveyor should not contain lily_pad")
	for plant_kind in expected_plants:
		passed = _assert_true(conveyor_plants.has(plant_kind), "4-18 conveyor should include fog-world plant %s" % plant_kind) and passed
	return passed
