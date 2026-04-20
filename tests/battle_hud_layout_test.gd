extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_desktop_wave_hud_does_not_overlap_action_buttons() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_desktop_wave_hud_does_not_overlap_action_buttons() -> bool:
	var game := GameScript.new()
	game.size = Vector2(1600.0, 900.0)
	game.set("mode", game.get("MODE_BATTLE"))
	game.call("_refresh_battle_layout")

	var wave_rect: Rect2 = game.get("WAVE_BAR_RECT")
	var coin_rect: Rect2 = game.get("COIN_METER_RECT")
	var pause_rect: Rect2 = game.get("PAUSE_BUTTON_RECT")
	var back_rect: Rect2 = game.get("BACK_BUTTON_RECT")

	var passed := true
	passed = _assert_true(not wave_rect.intersects(coin_rect), "desktop wave bar should not overlap the coin meter at 1600x900") and passed
	passed = _assert_true(not wave_rect.intersects(pause_rect), "desktop wave bar should not overlap the pause button at 1600x900") and passed
	passed = _assert_true(not wave_rect.intersects(back_rect), "desktop wave bar should not overlap the back-to-map button at 1600x900") and passed
	game.free()
	return passed
