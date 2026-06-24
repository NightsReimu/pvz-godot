extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_game_script_loads() or failed
	failed = not _test_game_starts_on_home_terminal() or failed
	failed = not _test_regular_level_bgm_mapping_and_assets() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_game_script_loads() -> bool:
	var script = load("res://scripts/game.gd")
	var passed = _assert_true(script != null, "expected scripts/game.gd to load without parse errors during boot")
	if not passed:
		return false
	var game = script.new()
	passed = _assert_true(game.has_method("_draw_shovel_icon"), "expected game boot script to expose the shovel icon draw helper used by the seed bank") and passed
	passed = _assert_true(game.has_method("_draw_heather_shooter"), "expected game boot script to expose city plant draw helpers") and passed
	passed = _assert_true(game.has_method("_draw_wenjie_zombie"), "expected game boot script to expose city zombie draw helpers") and passed
	game.free()
	return passed


func _test_game_starts_on_home_terminal() -> bool:
	var script = load("res://scripts/game.gd")
	if not _assert_true(script != null, "expected scripts/game.gd to load before checking startup mode"):
		return false
	var game = script.new()
	var passed = _assert_true(game.get("MODE_HOME") != null, "game should expose a home mode for the top-level terminal") \
		and _assert_true(String(game.mode) == String(game.get("MODE_HOME")), "game should boot to the home terminal instead of directly opening world selection")
	game.free()
	return passed


func _test_regular_level_bgm_mapping_and_assets() -> bool:
	var script = load("res://scripts/game.gd")
	if not _assert_true(script != null, "expected scripts/game.gd to load before checking regular BGM mapping"):
		return false
	var game = script.new()
	var expected_paths := [
		"res://audio/bgm/day.mp3",
		"res://audio/bgm/night.mp3",
		"res://audio/bgm/pool.mp3",
		"res://audio/bgm/roof.mp3",
		"res://audio/bgm/fog.mp3",
		"res://audio/bgm/city.mp3",
		"res://audio/bgm/volcano.mp3",
	]
	var passed = _assert_true(game.has_method("_regular_level_bgm_path"), "game should expose a helper for regular level BGM routing")
	for path in expected_paths:
		passed = _assert_true(FileAccess.file_exists(path), "%s should exist for ordinary level music" % path) and passed
		var stream = game.call("_load_audio_stream", path)
		passed = _assert_true(stream is AudioStreamMP3, "%s should load as an MP3 stream" % path) and passed
		if stream is AudioStreamMP3:
			passed = _assert_true(bool(stream.loop), "%s should loop during ordinary battles" % path) and passed
	if passed:
		passed = _assert_true(String(game.call("_regular_level_bgm_path", {"id": "1-1", "terrain": "day"})) == "res://audio/bgm/day.mp3", "day levels should use the day BGM") and passed
		passed = _assert_true(String(game.call("_regular_level_bgm_path", {"id": "2-1"})) == "res://audio/bgm/night.mp3", "night levels without explicit terrain should use the night BGM") and passed
		passed = _assert_true(String(game.call("_regular_level_bgm_path", {"id": "3-1", "terrain": "pool"})) == "res://audio/bgm/pool.mp3", "pool levels should use the pool BGM") and passed
		passed = _assert_true(String(game.call("_regular_level_bgm_path", {"id": "4-1", "terrain": "fog"})) == "res://audio/bgm/fog.mp3", "fog levels should use the fog BGM") and passed
		passed = _assert_true(String(game.call("_regular_level_bgm_path", {"id": "5-1", "terrain": "roof"})) == "res://audio/bgm/roof.mp3", "roof levels should use the roof BGM") and passed
		passed = _assert_true(String(game.call("_regular_level_bgm_path", {"id": "6-1", "terrain": "city"})) == "res://audio/bgm/city.mp3", "city levels should use the city BGM") and passed
		passed = _assert_true(String(game.call("_regular_level_bgm_path", {"id": "7-1", "terrain": "volcano"})) == "res://audio/bgm/volcano.mp3", "volcano levels should use the volcano BGM") and passed
		passed = _assert_true(String(game.call("_regular_level_bgm_path", {"id": "2-25", "terrain": "winter_forest", "boss_intro_bgm": "res://audio/letty_intro.mp3"})) == "", "Touhou boss branch levels should keep their dedicated intro BGM instead of ordinary music") and passed
	game.free()
	return passed
