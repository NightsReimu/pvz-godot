extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_boss_frame_loader_avoids_filesystem_only_paths() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_boss_frame_loader_avoids_filesystem_only_paths() -> bool:
	var source := FileAccess.get_file_as_string("res://scripts/game.gd")
	var start := source.find("func _load_single_boss_frame")
	var end := source.find("func _store_prewarmed_boss_frame", start)
	var loader_source := source.substr(start, end - start)
	var passed := true
	passed = _assert_true(start >= 0 and end > start, "expected to find the boss frame loader implementation in scripts/game.gd") and passed
	passed = _assert_true(not loader_source.contains("ProjectSettings.globalize_path"), "web boss frame loading should stay on resource paths instead of globalized filesystem paths") and passed
	passed = _assert_true(not loader_source.contains("image.load(path)"), "web boss frame loading should not decode raw files directly from filesystem paths") and passed
	return passed
