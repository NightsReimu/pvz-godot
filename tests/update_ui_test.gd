extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_update_button_labels_follow_state_and_platform() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "ui-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.water_rows = []
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	if is_instance_valid(game.banner_label):
		game.banner_label.free()
	if is_instance_valid(game.message_panel):
		game.message_panel.free()
	if is_instance_valid(game.message_label):
		game.message_label.free()
	if is_instance_valid(game.action_button):
		game.action_button.free()
	game.free()


func _test_update_button_labels_follow_state_and_platform() -> bool:
	var game = _make_game()
	var passed := true
	game.update_state = "checking"
	passed = _assert_true(String(game.call("_update_action_text")) == "检查更新中", "checking state should show checking copy") and passed
	game.update_state = "latest"
	passed = _assert_true(String(game.call("_update_action_text")) == "重新检查", "latest state should allow a recheck action") and passed
	game.update_state = "available"
	game.update_release_info = {"install_mode": "desktop_replace", "latest_version": "0.1.6"}
	passed = _assert_true(String(game.call("_update_action_text")) == "下载并更新", "desktop available state should offer direct download and update") and passed
	game.update_state = "downloading"
	game.update_download_progress = 0.42
	passed = _assert_true(String(game.call("_update_action_text")).contains("42%"), "downloading state should show the download percentage") and passed
	game.update_state = "ready"
	game.update_release_info = {"install_mode": "android_handoff", "latest_version": "0.1.6"}
	passed = _assert_true(String(game.call("_update_action_text")) == "安装 APK", "android ready state should invite APK install") and passed
	game.update_release_info = {"install_mode": "notify_only", "latest_version": "0.1.6"}
	passed = _assert_true(String(game.call("_update_action_text")) == "查看更新", "web ready state should fall back to viewing the update") and passed
	game.update_state = "error"
	passed = _assert_true(String(game.call("_update_action_text")) == "重试更新", "error state should offer retry") and passed
	_free_game(game)
	return passed
