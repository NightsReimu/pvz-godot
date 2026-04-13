extends RefCounted
class_name WindowMode


static func apply(root: Window) -> void:
	if root == null:
		return
	var is_mobile = OS.has_feature("android") or OS.has_feature("ios") or OS.get_name().to_lower() in ["android", "ios"]
	root.min_size = Vector2i.ZERO if is_mobile else Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.mode = Window.MODE_FULLSCREEN
	root.borderless = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
