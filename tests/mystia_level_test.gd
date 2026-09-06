extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := _find_level("3-20")
	var failed := false
	failed = not _assert_true(not level.is_empty(), "3-20 should exist") or failed
	failed = not _assert_true(String(level.get("terrain", "")) == "mystia_night_food_stand", "3-20 should use the Mystia restaurant terrain") or failed
	failed = not _assert_true(int(level.get("row_count", 0)) == 6, "3-20 should have six grass rows") or failed
	failed = not _assert_true(not level.has("water_rows") or Array(level.get("water_rows", [])).is_empty(), "3-20 should not have pool rows") or failed
	failed = not _assert_true(String(level.get("mid_boss_kind", "")) == "cirno_boss", "3-20 should gate Mystia behind Cirno") or failed
	failed = not _assert_true(String(level.get("boss_intro_bgm", "")) == "res://audio/th08_mystia_stage.mp3", "3-20 should use the supplied stage BGM") or failed
	failed = not _assert_true(String(level.get("boss_bgm", "")) == "res://audio/th08_mystia_boss.mp3", "3-20 should use the supplied finale BGM") or failed
	var finale_count := 0
	for event in level.get("events", []):
		if String(event.get("kind", "")) == "mystia_boss":
			finale_count += 1
	failed = not _assert_true(finale_count == 1, "3-20 should schedule exactly one Mystia finale") or failed
	quit(1 if failed else 0)


func _find_level(level_id: String) -> Dictionary:
	for level in Defs.LEVELS:
		if String(level.get("id", "")) == level_id:
			return Dictionary(level)
	return {}


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
