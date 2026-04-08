extends RefCounted

const REPO_OWNER := "HecreReed"
const REPO_NAME := "pvz-godot"
const RELEASES_URL := "https://github.com/NightsReimu/pvz-godot/releases"
const LATEST_RELEASE_PAGE_URL := "https://github.com/NightsReimu/pvz-godot/releases/latest"
const LATEST_RELEASE_API_URL := "https://api.github.com/repos/NightsReimu/pvz-godot/releases/latest"
const PROJECT_SETTINGS_CDN_URL := "https://cdn.jsdelivr.net/gh/NightsReimu/pvz-godot@main/project.godot"
const PROJECT_SETTINGS_RAW_URL := "https://raw.githubusercontent.com/NightsReimu/pvz-godot/main/project.godot"
const UPDATES_ROOT := "user://updates"
const STAGE_ROOT_NAME := "staged"
const DOWNLOAD_ROOT_NAME := "downloads"


func latest_release_api_url() -> String:
	return LATEST_RELEASE_API_URL


func latest_release_page_url() -> String:
	return LATEST_RELEASE_PAGE_URL


func project_settings_cdn_url() -> String:
	return PROJECT_SETTINGS_CDN_URL


func project_settings_raw_url() -> String:
	return PROJECT_SETTINGS_RAW_URL


func releases_url() -> String:
	return RELEASES_URL


func default_update_sources() -> Array:
	return [
		{"kind": "project_settings", "url": project_settings_cdn_url()},
		{"kind": "project_settings", "url": project_settings_raw_url()},
		{"kind": "release_page", "url": latest_release_page_url()},
		{"kind": "api", "url": latest_release_api_url()},
	]


func normalize_version(raw: String) -> String:
	var version = raw.strip_edges()
	if version.begins_with("v") or version.begins_with("V"):
		version = version.substr(1)
	return version


func compare_versions(left: String, right: String) -> int:
	var left_parts = _version_parts(normalize_version(left))
	var right_parts = _version_parts(normalize_version(right))
	var count = maxi(left_parts.size(), right_parts.size())
	for index in range(count):
		var left_value = int(left_parts[index]) if index < left_parts.size() else 0
		var right_value = int(right_parts[index]) if index < right_parts.size() else 0
		if left_value < right_value:
			return -1
		if left_value > right_value:
			return 1
	return 0


func resolve_release(payload: Dictionary, current_version: String, platform: String) -> Dictionary:
	var latest_tag = normalize_version(String(payload.get("tag_name", "")))
	var info := {
		"status": "error",
		"latest_version": latest_tag,
		"page_url": String(payload.get("html_url", RELEASES_URL)),
		"asset_name": "",
		"asset_url": "",
		"install_mode": install_mode_for_platform(platform),
		"platform": platform,
	}
	if latest_tag == "":
		info["status"] = "invalid_release"
		return info
	if compare_versions(current_version, latest_tag) >= 0:
		info["status"] = "latest"
		return info
	var asset_name = asset_name_for_platform(platform)
	if asset_name == "":
		info["status"] = "unsupported_platform"
		return info
	for asset_variant in payload.get("assets", []):
		var asset = Dictionary(asset_variant)
		if String(asset.get("name", "")) != asset_name:
			continue
		info["asset_name"] = asset_name
		info["asset_url"] = String(asset.get("browser_download_url", ""))
		info["status"] = "update_available"
		return info
	info["status"] = "missing_asset"
	return info


func release_payload_from_project_settings_text(text: String) -> Dictionary:
	var version = _extract_project_version(text)
	if version == "":
		return {}
	var tag = "v%s" % normalize_version(version)
	return _payload_for_tag(tag)


func release_payload_from_release_page_html(text: String) -> Dictionary:
	var tag = _extract_release_tag(text)
	if tag == "":
		return {}
	return _payload_for_tag(tag)


func _payload_for_tag(tag: String) -> Dictionary:
	var payload := {
		"tag_name": tag,
		"html_url": "%s/tag/%s" % [RELEASES_URL, tag],
		"assets": [],
	}
	for asset_name in _known_release_asset_names():
		payload["assets"].append({
			"name": asset_name,
			"browser_download_url": "%s/download/%s/%s" % [RELEASES_URL, tag, asset_name],
		})
	return payload


func asset_name_for_platform(platform: String) -> String:
	match platform.to_lower():
		"windows":
			return "pvz-godot-windows.zip"
		"macos":
			return "pvz-godot-macos.zip"
		"android":
			return "pvz-godot-android.apk"
		"web":
			return "pvz-godot-web.zip"
		_:
			return ""


func install_mode_for_platform(platform: String) -> String:
	match platform.to_lower():
		"windows", "macos":
			return "desktop_replace"
		"android":
			return "android_handoff"
		"web":
			return "notify_only"
		_:
			return "unsupported"


func platform_key_for_runtime(os_name: String = "", features: PackedStringArray = PackedStringArray()) -> String:
	if os_name == "":
		os_name = OS.get_name()
	var lowered = os_name.to_lower()
	if features.is_empty():
		if OS.has_feature("web"):
			features.append("web")
		if OS.has_feature("android"):
			features.append("android")
	if "web" in features:
		return "web"
	if "android" in features or lowered == "android":
		return "android"
	if lowered.contains("windows"):
		return "windows"
	if lowered.contains("mac"):
		return "macos"
	return lowered


func updates_root_path() -> String:
	return ProjectSettings.globalize_path(UPDATES_ROOT)


func downloads_root_path() -> String:
	return updates_root_path().path_join(DOWNLOAD_ROOT_NAME)


func staged_root_path(version: String) -> String:
	return updates_root_path().path_join(STAGE_ROOT_NAME).path_join(normalize_version(version))


func helper_script_path(platform: String) -> String:
	var file_name = "apply_update.bat" if platform.to_lower() == "windows" else "apply_update.sh"
	return updates_root_path().path_join(file_name)


func downloaded_asset_path(asset_name: String) -> String:
	return downloads_root_path().path_join(asset_name)


func desktop_install_target(platform: String, executable_path: String) -> Dictionary:
	if platform.to_lower() == "windows":
		return {
			"install_dir": executable_path.get_base_dir(),
			"relaunch_path": executable_path,
		}
	if platform.to_lower() == "macos":
		var marker := ".app/"
		var marker_index = executable_path.find(marker)
		if marker_index != -1:
			var app_path = executable_path.substr(0, marker_index + 4)
			return {
				"install_dir": app_path.get_base_dir(),
				"relaunch_path": app_path,
			}
	return {
		"install_dir": executable_path.get_base_dir(),
		"relaunch_path": executable_path,
	}


func ensure_dir_absolute(path: String) -> Error:
	return DirAccess.make_dir_recursive_absolute(path)


func remove_recursive_absolute(path: String) -> Error:
	if path == "":
		return ERR_INVALID_PARAMETER
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path)
	if not DirAccess.dir_exists_absolute(path):
		return OK
	var dir = DirAccess.open(path)
	if dir == null:
		return FAILED
	dir.list_dir_begin()
	while true:
		var entry = dir.get_next()
		if entry == "":
			break
		if entry == "." or entry == "..":
			continue
		var child_path = path.path_join(entry)
		var result = remove_recursive_absolute(child_path) if dir.current_is_dir() else DirAccess.remove_absolute(child_path)
		if result != OK:
			dir.list_dir_end()
			return result
	dir.list_dir_end()
	return DirAccess.remove_absolute(path)


func write_text_file_absolute(path: String, content: String) -> Error:
	var parent = path.get_base_dir()
	var mkdir_result = ensure_dir_absolute(parent)
	if mkdir_result != OK:
		return mkdir_result
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FAILED
	file.store_string(content)
	file.close()
	return OK


func extract_zip_archive(zip_path: String, target_dir: String) -> Error:
	var mkdir_result = ensure_dir_absolute(target_dir)
	if mkdir_result != OK:
		return mkdir_result
	var zip = ZIPReader.new()
	var open_result = zip.open(zip_path)
	if open_result != OK:
		return open_result
	for entry_name in zip.get_files():
		var out_path = target_dir.path_join(String(entry_name))
		if String(entry_name).ends_with("/"):
			var dir_result = ensure_dir_absolute(out_path)
			if dir_result != OK:
				zip.close()
				return dir_result
			continue
		var dir_result = ensure_dir_absolute(out_path.get_base_dir())
		if dir_result != OK:
			zip.close()
			return dir_result
		var out_file = FileAccess.open(out_path, FileAccess.WRITE)
		if out_file == null:
			zip.close()
			return FAILED
		out_file.store_buffer(zip.read_file(entry_name))
		out_file.close()
	zip.close()
	return OK


func build_desktop_apply_script(platform: String, process_id: int, stage_dir: String, install_dir: String, relaunch_path: String) -> String:
	if platform.to_lower() == "windows":
		return _build_windows_apply_script(process_id, stage_dir, install_dir, relaunch_path)
	return _build_unix_apply_script(process_id, stage_dir, install_dir, relaunch_path, platform)


func _version_parts(version: String) -> Array:
	var parts: Array = []
	for raw_part in version.split("."):
		var digits := ""
		for ch in raw_part:
			if ch >= "0" and ch <= "9":
				digits += ch
			else:
				break
		parts.append(int(digits if digits != "" else "0"))
	return parts


func _extract_project_version(text: String) -> String:
	var marker = 'config/version="'
	var start = text.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end = text.find('"', start)
	if end == -1:
		return ""
	return normalize_version(text.substr(start, end - start))


func _extract_release_tag(text: String) -> String:
	var match = RegEx.new()
	var compile_error = match.compile("/releases/tag/(v[0-9A-Za-z._-]+)")
	if compile_error != OK:
		return ""
	var result = match.search(text)
	if result == null:
		return ""
	return String(result.get_string(1))


func _known_release_asset_names() -> Array:
	return [
		"pvz-godot-windows.zip",
		"pvz-godot-macos.zip",
		"pvz-godot-web.zip",
		"pvz-godot-android.apk",
	]


func _build_windows_apply_script(process_id: int, stage_dir: String, install_dir: String, relaunch_path: String) -> String:
	return "@echo off\r\n" \
		+ "set PID=%d\r\n" % process_id \
		+ ":waitloop\r\n" \
		+ "tasklist /FI \"PID eq %d\" | find \"%d\" >nul\r\n" % [process_id, process_id] \
		+ "if not errorlevel 1 (\r\n" \
		+ "  timeout /t 1 /nobreak >nul\r\n" \
		+ "  goto waitloop\r\n" \
		+ ")\r\n" \
		+ "robocopy \"%s\" \"%s\" /E /NFL /NDL /NJH /NJS /NC /NS >nul\r\n" % [stage_dir, install_dir] \
		+ "start \"\" \"%s\"\r\n" % relaunch_path \
		+ "exit /b 0\r\n"


func _build_unix_apply_script(process_id: int, stage_dir: String, install_dir: String, relaunch_path: String, platform: String) -> String:
	var relaunch_command = "open \"%s\"" % relaunch_path if platform.to_lower() == "macos" and relaunch_path.ends_with(".app") else "\"%s\" &" % relaunch_path
	return "#!/bin/sh\n" \
		+ "PID=%d\n" % process_id \
		+ "while kill -0 \"$PID\" 2>/dev/null; do\n" \
		+ "  sleep 1\n" \
		+ "done\n" \
		+ "mkdir -p \"%s\"\n" % install_dir \
		+ "cp -R \"%s\"/. \"%s\"/\n" % [stage_dir, install_dir] \
		+ "%s\n" % relaunch_command \
		+ "exit 0\n"
