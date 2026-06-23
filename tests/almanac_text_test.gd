extends SceneTree

const PlantDefs = preload("res://scripts/data/plant_defs.gd")
const ZombieDefs = preload("res://scripts/data/zombie_defs.gd")
const AlmanacText = preload("res://scripts/data/almanac_text.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_every_plant_has_non_placeholder_almanac_lines() or failed
	failed = not _test_wenjie_zombie_is_displayed_as_flying_car_zombie() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_every_plant_has_non_placeholder_almanac_lines() -> bool:
	var passed := true
	for kind_variant in PlantDefs.ORDER:
		var kind = String(kind_variant)
		var lines: Array = AlmanacText.plant_lines(kind)
		passed = _assert_true(lines.size() >= 2, "plant %s should have at least two almanac lines" % kind) and passed
		if lines.size() >= 1:
			passed = _assert_true(String(lines[0]).strip_edges() != "", "plant %s should have a non-empty first almanac line" % kind) and passed
			passed = _assert_true(not String(lines[0]).contains("资料暂未填写"), "plant %s should not show placeholder almanac copy" % kind) and passed
		if lines.size() >= 2:
			passed = _assert_true(String(lines[1]).strip_edges() != "", "plant %s should have a non-empty second almanac line" % kind) and passed
	return passed


func _test_wenjie_zombie_is_displayed_as_flying_car_zombie() -> bool:
	var passed := _assert_true(String(ZombieDefs.ZOMBIES["wenjie_zombie"]["name"]) == "飞车僵尸", "wenjie_zombie should display as 飞车僵尸")
	var lines: Array = AlmanacText.zombie_lines("wenjie_zombie")
	passed = _assert_true(lines.size() >= 2, "飞车僵尸 should keep almanac text") and passed
	for line in lines:
		passed = _assert_true(String(line).contains("飞车僵尸") or not String(line).contains("问界"), "wenjie_zombie almanac text should no longer mention 问界") and passed
	return passed
