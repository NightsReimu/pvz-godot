extends RefCounted
class_name WindowMode


static func target_window_mode(is_web: bool) -> int:
	return DisplayServer.WINDOW_MODE_WINDOWED if is_web else DisplayServer.WINDOW_MODE_FULLSCREEN


static func apply(root: Window) -> void:
	if root == null:
		return
	var is_mobile = OS.has_feature("android") or OS.has_feature("ios") or OS.get_name().to_lower() in ["android", "ios"]
	var is_web = OS.has_feature("web")
	root.min_size = Vector2i.ZERO if is_mobile else Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.borderless = true
	var display_mode = target_window_mode(is_web)
	root.mode = Window.MODE_WINDOWED if display_mode == DisplayServer.WINDOW_MODE_WINDOWED else Window.MODE_FULLSCREEN
	DisplayServer.window_set_mode(display_mode)
