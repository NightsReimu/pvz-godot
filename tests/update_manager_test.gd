extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_compare_versions_and_normalize_tags() or failed
	failed = not _test_project_settings_release_payload_builds_stable_asset_links() or failed
	failed = not _test_release_page_html_builds_release_payload() or failed
	failed = not _test_default_update_sources_prioritize_release_sources() or failed
	failed = not _test_prefer_release_info_uses_the_highest_version() or failed
	failed = not _test_update_failure_messages_use_readable_copy() or failed
	failed = not _test_resolve_release_for_each_supported_platform() or failed
	failed = not _test_desktop_apply_script_templates_include_wait_copy_and_relaunch() or failed
	failed = not _test_update_receipt_round_trip_persists_downloaded_asset_metadata() or failed
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


func _test_project_settings_release_payload_builds_stable_asset_links() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var payload = manager.release_payload_from_project_settings_text("config/name=\"植物大战僵尸svg版\"\nconfig/version=\"1.2.3\"\n")
	var passed := true
	passed = _assert_true(String(payload.get("tag_name", "")) == "v1.2.3", "project settings text should be converted into a synthetic v-prefixed release tag") and passed
	passed = _assert_true(String(payload.get("html_url", "")) == "https://github.com/NightsReimu/pvz-godot/releases/tag/v1.2.3", "synthetic release payload should point to the matching GitHub release page") and passed
	var assets: Array = payload.get("assets", [])
	var asset_names: Array = []
	for asset_variant in assets:
		asset_names.append(String(Dictionary(asset_variant).get("name", "")))
	passed = _assert_true(asset_names.has("pvz-godot-windows.zip"), "synthetic payload should include the Windows asset") and passed
	passed = _assert_true(asset_names.has("pvz-godot-macos.zip"), "synthetic payload should include the macOS asset") and passed
	passed = _assert_true(asset_names.has("pvz-godot-web.zip"), "synthetic payload should include the Web asset") and passed
	passed = _assert_true(asset_names.has("pvz-godot-android.apk"), "synthetic payload should include the Android asset") and passed
	return passed


func _test_release_page_html_builds_release_payload() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var html = '<html><head><link rel="canonical" href="https://github.com/NightsReimu/pvz-godot/releases/tag/v1.0.2"></head></html>'
	var payload = manager.release_payload_from_release_page_html(html)
	var passed := true
	passed = _assert_true(String(payload.get("tag_name", "")) == "v1.0.2", "release page HTML should be converted into a synthetic payload using the detected tag") and passed
	passed = _assert_true(String(payload.get("html_url", "")) == "https://github.com/NightsReimu/pvz-godot/releases/tag/v1.0.2", "release page HTML should resolve to the matching release page") and passed
	return passed


func _test_default_update_sources_prioritize_release_sources() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var sources: Array = manager.default_update_sources()
	var passed := true
	passed = _assert_true(sources.size() >= 4, "update manager should expose multiple fallback sources for update checks") and passed
	if passed:
		passed = _assert_true(String(Dictionary(sources[0]).get("kind", "")) == "release_page", "first update source should use the latest release page to avoid stale manifest caches") and passed
		passed = _assert_true(String(Dictionary(sources[0]).get("url", "")).contains("/releases/latest"), "release page source should point at the latest release landing page") and passed
		passed = _assert_true(String(Dictionary(sources[1]).get("kind", "")) == "api", "second update source should still use the GitHub API") and passed
		passed = _assert_true(String(Dictionary(sources[2]).get("kind", "")) == "project_settings", "third update source should fall back to static manifests only after release sources") and passed
		passed = _assert_true(String(Dictionary(sources[2]).get("url", "")).contains("cdn.jsdelivr.net"), "third update source should keep jsDelivr as the mirror fallback") and passed
		passed = _assert_true(String(Dictionary(sources[3]).get("kind", "")) == "project_settings", "fourth update source should keep a direct raw manifest as the final fallback") and passed
	return passed


func _test_prefer_release_info_uses_the_highest_version() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var stale_info := {
		"status": "latest",
		"latest_version": "1.0.2",
		"page_url": "https://example.invalid/v1.0.2",
		"asset_name": "",
		"asset_url": "",
		"install_mode": "desktop_replace",
		"platform": "macos",
	}
	var newer_info := {
		"status": "update_available",
		"latest_version": "1.0.3",
		"page_url": "https://example.invalid/v1.0.3",
		"asset_name": "pvz-godot-macos.zip",
		"asset_url": "https://example.invalid/pvz-godot-macos.zip",
		"install_mode": "desktop_replace",
		"platform": "macos",
	}
	var same_version_better_status := {
		"status": "update_available",
		"latest_version": "1.0.3",
		"page_url": "https://example.invalid/v1.0.3",
		"asset_name": "pvz-godot-macos.zip",
		"asset_url": "https://example.invalid/pvz-godot-macos.zip",
		"install_mode": "desktop_replace",
		"platform": "macos",
	}
	var passed := true
	var preferred = manager.prefer_release_info(stale_info, newer_info)
	passed = _assert_true(String(preferred.get("latest_version", "")) == "1.0.3", "prefer_release_info should keep the highest version seen across all update sources") and passed
	passed = _assert_true(String(preferred.get("status", "")) == "update_available", "prefer_release_info should keep an update_available candidate when it is newer") and passed
	preferred = manager.prefer_release_info({"status": "latest", "latest_version": "1.0.3"}, same_version_better_status)
	passed = _assert_true(String(preferred.get("status", "")) == "update_available", "prefer_release_info should prefer a downloadable candidate over a same-version latest result") and passed
	return passed


func _test_update_failure_messages_use_readable_copy() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var dns_message = String(manager.build_update_check_failure_message("release_page", 3, "android"))
	var timeout_message = String(manager.build_update_check_failure_message("api", 13, "windows"))
	var request_message = String(manager.build_update_request_start_error_message(ERR_BUSY))
	var passed := true
	passed = _assert_true(dns_message.contains("无法解析更新服务器地址"), "result code 3 should be rendered as a readable DNS failure message") and passed
	passed = _assert_true(dns_message.contains("联网权限"), "android DNS failures should hint that the APK may be missing network permission") and passed
	passed = _assert_true(not dns_message.contains("release_page"), "user-facing update errors should not leak internal source ids") and passed
	passed = _assert_true(not dns_message.contains("（"), "user-facing update errors should avoid full-width punctuation that may render as tofu") and passed
	passed = _assert_true(timeout_message.contains("请求超时"), "timeouts should have a specific user-facing message") and passed
	passed = _assert_true(request_message.begins_with("无法发起版本检查:"), "request start failures should use a readable prefix") and passed
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


func _test_update_receipt_round_trip_persists_downloaded_asset_metadata() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	manager.clear_update_receipt()
	var receipt := {
		"latest_version": "1.0.8",
		"asset_name": "pvz-godot-android.apk",
		"install_mode": "android_handoff",
		"platform": "android",
		"local_path": manager.downloaded_asset_path("pvz-godot-android.apk"),
	}
	var write_result = manager.write_update_receipt(receipt)
	var loaded = manager.read_update_receipt()
	var passed := true
	passed = _assert_true(write_result == OK, "write_update_receipt should persist the receipt file") and passed
	passed = _assert_true(String(loaded.get("latest_version", "")) == "1.0.8", "read_update_receipt should restore the stored version") and passed
	passed = _assert_true(String(loaded.get("asset_name", "")) == "pvz-godot-android.apk", "read_update_receipt should restore the stored asset name") and passed
	passed = _assert_true(String(loaded.get("install_mode", "")) == "android_handoff", "read_update_receipt should restore the install mode") and passed
	passed = _assert_true(String(loaded.get("local_path", "")).ends_with("pvz-godot-android.apk"), "read_update_receipt should preserve the downloaded asset path") and passed
	manager.clear_update_receipt()
	passed = _assert_true(manager.read_update_receipt().is_empty(), "clear_update_receipt should remove persisted state") and passed
	return passed
