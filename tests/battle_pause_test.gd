extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_escape_toggles_battle_pause() or failed
	failed = not _test_almanac_close_returns_to_paused_battle() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.size = Vector2(1600.0, 900.0)
	game.current_level = {"id": "pause-test", "terrain": "day", "events": [], "title": "pause", "description": ""}
	game.active_rows = [0, 1, 2, 3, 4]
	game.water_rows = []
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	game.mode = game.MODE_BATTLE
	game.battle_state = game.BATTLE_PLAYING
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	if is_instance_valid(game.banner_label):
		game.banner_label.free()
	if is_instance_valid(game.message_label):
		game.message_label.free()
	if is_instance_valid(game.action_button):
		game.action_button.free()
	if is_instance_valid(game.message_panel):
		game.message_panel.free()
	game.free()


func _escape_key() -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.keycode = KEY_ESCAPE
	return event


func _test_escape_toggles_battle_pause() -> bool:
	var game := _make_game()
	game._unhandled_input(_escape_key())
	var passed = _assert_true(game.get("battle_paused") == true, "pressing Escape in battle should open the pause overlay")
	game._unhandled_input(_escape_key())
	passed = _assert_true(game.get("battle_paused") == false, "pressing Escape again in battle should close the pause overlay") and passed
	_free_game(game)
	return passed


func _test_almanac_close_returns_to_paused_battle() -> bool:
	var game := _make_game()
	game.set("battle_paused", true)
	game._enter_almanac_mode("plants")
	game._handle_almanac_click(game.ALMANAC_CLOSE_RECT.get_center())
	var passed = _assert_true(game.mode == game.MODE_BATTLE, "closing the almanac opened from battle pause should return to battle instead of leaving the level") \
		and _assert_true(game.get("battle_paused") == true, "closing the almanac opened from battle pause should restore the paused overlay")
	_free_game(game)
	return passed
