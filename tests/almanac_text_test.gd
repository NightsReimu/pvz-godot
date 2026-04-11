extends SceneTree

const PlantDefs = preload("res://scripts/data/plant_defs.gd")
const AlmanacText = preload("res://scripts/data/almanac_text.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_every_plant_has_non_placeholder_almanac_lines() or failed
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
