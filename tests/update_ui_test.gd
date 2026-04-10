extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const UpdateManagerScript = preload("res://scripts/system/update_manager.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_update_button_labels_follow_state_and_platform() or failed
	failed = not _test_android_install_spec_uses_file_provider_content_uri() or failed
	failed = not _test_finalize_update_check_restores_a_downloaded_android_apk() or failed
	failed = not _test_finalize_update_check_ignores_stale_or_missing_downloaded_apks() or failed
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


func _test_android_install_spec_uses_file_provider_content_uri() -> bool:
	var game = _make_game()
	var spec = game.call("_android_install_intent_spec", "com.hecrereed.pvz", "/data/user/0/com.hecrereed.pvz/files/updates/downloads/pvz-godot-android.apk")
	var passed := true
	passed = _assert_true(spec is Dictionary and not Dictionary(spec).is_empty(), "android update flow should expose an install intent spec for APK handoff") and passed
	if passed:
		passed = _assert_true(String(spec.get("provider_authority", "")) == "com.hecrereed.pvz.fileprovider", "android APK install should use the exported Godot FileProvider authority instead of a raw file:// URI") and passed
		passed = _assert_true(String(spec.get("uri_scheme", "")) == "content", "android APK install should hand the installer a content URI") and passed
		passed = _assert_true(String(spec.get("mime_type", "")) == "application/vnd.android.package-archive", "android APK install should keep the package archive MIME type") and passed
	_free_game(game)
	return passed


func _release_info(version: String = "1.0.8") -> Dictionary:
	return {
		"status": "update_available",
		"latest_version": version,
		"asset_name": "pvz-godot-android.apk",
		"asset_url": "https://example.invalid/pvz-godot-android.apk",
		"install_mode": "android_handoff",
		"platform": "android",
		"page_url": "https://example.invalid/releases/tag/v%s" % version,
	}


func _write_dummy_download(path: String) -> void:
	var dir_result = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if dir_result != OK:
		push_error("failed to create update downloads directory for test")
		return
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("failed to write dummy downloaded APK for test")
		return
	file.store_string("apk")
	file.close()


func _test_finalize_update_check_restores_a_downloaded_android_apk() -> bool:
	var manager = UpdateManagerScript.new()
	manager.clear_update_receipt()
	var local_path = manager.downloaded_asset_path("pvz-godot-android.apk")
	_write_dummy_download(local_path)
	manager.write_update_receipt({
		"latest_version": "1.0.8",
		"asset_name": "pvz-godot-android.apk",
		"install_mode": "android_handoff",
		"platform": "android",
		"local_path": local_path,
	})
	var game = _make_game()
	game.update_manager = manager
	game.update_best_release_info = _release_info("1.0.8")
	game.call("_finalize_update_check")
	var passed := true
	passed = _assert_true(game.update_state == "ready", "matching persisted APK downloads should restore the ready update state") and passed
	passed = _assert_true(game.update_download_target_path == local_path, "restored update state should keep the downloaded APK path") and passed
	passed = _assert_true(String(game.call("_update_action_text")) == "安装 APK", "restored Android updates should expose the install APK action") and passed
	passed = _assert_true(String(game.call("_update_status_line")).contains("APK 已下载"), "restored Android updates should tell the player the APK is already downloaded") and passed
	_free_game(game)
	manager.clear_update_receipt()
	manager.remove_recursive_absolute(local_path)
	return passed


func _test_finalize_update_check_ignores_stale_or_missing_downloaded_apks() -> bool:
	var manager = UpdateManagerScript.new()
	manager.clear_update_receipt()
	var local_path = manager.downloaded_asset_path("pvz-godot-android.apk")
	var passed := true

	manager.write_update_receipt({
		"latest_version": "1.0.7",
		"asset_name": "pvz-godot-android.apk",
		"install_mode": "android_handoff",
		"platform": "android",
		"local_path": local_path,
	})
	var stale_game = _make_game()
	stale_game.update_manager = manager
	stale_game.update_best_release_info = _release_info("1.0.8")
	stale_game.call("_finalize_update_check")
	passed = _assert_true(stale_game.update_state == "available", "stale receipts should not skip straight to install state") and passed
	passed = _assert_true(stale_game.update_download_target_path == "", "stale receipts should not restore a download path") and passed
	_free_game(stale_game)

	manager.write_update_receipt({
		"latest_version": "1.0.8",
		"asset_name": "pvz-godot-android.apk",
		"install_mode": "android_handoff",
		"platform": "android",
		"local_path": local_path,
	})
	var missing_game = _make_game()
	missing_game.update_manager = manager
	missing_game.update_best_release_info = _release_info("1.0.8")
	missing_game.call("_finalize_update_check")
	passed = _assert_true(missing_game.update_state == "available", "missing APK files should keep the update in downloadable state") and passed
	passed = _assert_true(missing_game.update_download_target_path == "", "missing APK files should not restore a deleted download path") and passed
	_free_game(missing_game)

	manager.clear_update_receipt()
	manager.remove_recursive_absolute(local_path)
	return passed
