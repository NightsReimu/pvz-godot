extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_ui_font_uses_bundled_cjk_font() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_ui_font_uses_bundled_cjk_font() -> bool:
	var game := GameScript.new()
	game.call("_build_font")
	var built_font = game.get("ui_font")
	var passed := true
	passed = _assert_true(built_font != null, "expected the game to build a UI font resource") and passed
	passed = _assert_true(built_font is FontFile, "web UI text should use a bundled font resource instead of a runtime SystemFont fallback") and passed
	if passed:
		passed = _assert_true(String(built_font.resource_path).begins_with("res://"), "bundled UI font should come from the project resources so web exports keep Chinese glyph coverage") and passed
		passed = _assert_true(built_font.get_string_size("植物大战僵尸svg版", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24).x > 0.0, "bundled UI font should measure Chinese text for the web UI") and passed
	game.free()
	return passed
