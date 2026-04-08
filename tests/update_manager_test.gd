extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_compare_versions_and_normalize_tags() or failed
	failed = not _test_project_settings_release_payload_builds_stable_asset_links() or failed
	failed = not _test_release_page_html_builds_release_payload() or failed
	failed = not _test_default_update_sources_prioritize_static_version_sources() or failed
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


func _test_default_update_sources_prioritize_static_version_sources() -> bool:
	var manager = _manager()
	if manager == null:
		return false
	var sources: Array = manager.default_update_sources()
	var passed := true
	passed = _assert_true(sources.size() >= 4, "update manager should expose multiple fallback sources for update checks") and passed
	if passed:
		passed = _assert_true(String(Dictionary(sources[0]).get("kind", "")) == "project_settings", "first update source should be a static project settings manifest") and passed
		passed = _assert_true(String(Dictionary(sources[0]).get("url", "")).contains("cdn.jsdelivr.net"), "first update source should prefer the jsDelivr mirror") and passed
		passed = _assert_true(String(Dictionary(sources[1]).get("kind", "")) == "project_settings", "second update source should keep using a static project settings mirror") and passed
		passed = _assert_true(String(Dictionary(sources[1]).get("url", "")).contains("raw.githubusercontent.com"), "second update source should use raw.githubusercontent.com directly instead of github.com/raw redirects") and passed
		passed = _assert_true(String(Dictionary(sources[2]).get("kind", "")) == "release_page", "third update source should read the GitHub release page as a non-API fallback") and passed
		passed = _assert_true(String(Dictionary(sources[2]).get("url", "")).contains("/releases/latest"), "release page fallback should point at the latest release landing page") and passed
		passed = _assert_true(String(Dictionary(sources[3]).get("kind", "")) == "api", "fourth update source should still use the GitHub API") and passed
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
