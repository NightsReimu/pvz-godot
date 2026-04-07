extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_compare_versions_and_normalize_tags() or failed
	failed = not _test_resolve_release_for_each_supported_platform() or failed
	failed = not _test_desktop_apply_script_templates_include_wait_copy_and_relaunch() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _manager():
	var script_resource = load("res://scripts/system/update_manager.gd")
	if script_resource == null:
		push_error("expected res://scripts/system/update_manager.gd to exist")
		return null
	return script_resource.new()


func _sample_release_payload() -> Dictionary:
	return {
		"tag_name": "v0.1.6",
		"html_url": "https://github.com/NightsReimu/pvz-godot/releases/tag/v0.1.6",
		"assets": [
			{
				"name": "pvz-godot-windows.zip",
				"browser_download_url": "https://example.invalid/pvz-godot-windows.zip",
			},
			{
				"name": "pvz-godot-macos.zip",
				"browser_download_url": "https://example.invalid/pvz-godot-macos.zip",
			},
			{
				"name": "pvz-godot-web.zip",
				"browser_download_url": "https://example.invalid/pvz-godot-web.zip",
			},
			{
				"name": "pvz-godot-android.apk",
				"browser_download_url": "https://example.invalid/pvz-godot-android.apk",
			},
		],
	}


func _test_compare_versions_and_normalize_tags() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var passed := true
	passed = _assert_true(manager.normalize_version("v0.1.6") == "0.1.6", "normalize_version should strip a leading v") and passed
	passed = _assert_true(int(manager.compare_versions("0.1.5", "0.1.6")) < 0, "0.1.5 should compare lower than 0.1.6") and passed
	passed = _assert_true(int(manager.compare_versions("0.1.6", "0.1.6")) == 0, "same versions should compare equal") and passed
	passed = _assert_true(int(manager.compare_versions("0.2.0", "0.1.9")) > 0, "0.2.0 should compare higher than 0.1.9") and passed
	return passed


func _test_resolve_release_for_each_supported_platform() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var payload = _sample_release_payload()
	var windows = manager.resolve_release(payload, "0.1.5", "windows")
	var macos = manager.resolve_release(payload, "0.1.5", "macos")
	var android = manager.resolve_release(payload, "0.1.5", "android")
	var web = manager.resolve_release(payload, "0.1.5", "web")
	var latest = manager.resolve_release(payload, "0.1.6", "windows")
	var passed := true
	passed = _assert_true(String(windows.get("status", "")) == "update_available", "windows should resolve to update_available when a newer release exists") and passed
	passed = _assert_true(String(windows.get("asset_name", "")) == "pvz-godot-windows.zip", "windows should select the windows zip asset") and passed
	passed = _assert_true(String(windows.get("install_mode", "")) == "desktop_replace", "windows should use desktop_replace install mode") and passed
	passed = _assert_true(String(macos.get("asset_name", "")) == "pvz-godot-macos.zip", "macos should select the macOS zip asset") and passed
	passed = _assert_true(String(android.get("asset_name", "")) == "pvz-godot-android.apk", "android should select the APK asset") and passed
	passed = _assert_true(String(android.get("install_mode", "")) == "android_handoff", "android should use android_handoff install mode") and passed
	passed = _assert_true(String(web.get("asset_name", "")) == "pvz-godot-web.zip", "web should select the web asset") and passed
	passed = _assert_true(String(web.get("install_mode", "")) == "notify_only", "web should degrade to notify_only mode") and passed
	passed = _assert_true(String(latest.get("status", "")) == "latest", "current version equal to latest release should report latest") and passed
	return passed


func _test_desktop_apply_script_templates_include_wait_copy_and_relaunch() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var win_script = String(manager.build_desktop_apply_script("windows", 4242, "C:/tmp/stage", "C:/Games/pvz-godot", "C:/Games/pvz-godot/pvz-godot.exe"))
	var unix_script = String(manager.build_desktop_apply_script("macos", 4242, "/tmp/stage", "/Applications/pvz-godot.app", "/Applications/pvz-godot.app/Contents/MacOS/pvz-godot"))
	var passed := true
	passed = _assert_true(win_script.contains("tasklist") or win_script.contains("timeout"), "windows update script should wait for the running process to exit") and passed
	passed = _assert_true(win_script.contains("robocopy") or win_script.contains("xcopy"), "windows update script should copy staged files into the install directory") and passed
	passed = _assert_true(win_script.contains("start"), "windows update script should relaunch the game") and passed
	passed = _assert_true(unix_script.contains("while kill -0"), "unix update script should wait for the running process to exit") and passed
	passed = _assert_true(unix_script.contains("cp -R") or unix_script.contains("rsync"), "unix update script should copy staged files into the install directory") and passed
	passed = _assert_true(unix_script.contains("open ") or unix_script.contains("\"/Applications/pvz-godot.app/Contents/MacOS/pvz-godot\""), "unix update script should relaunch the game") and passed
	return passed
