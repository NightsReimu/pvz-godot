extends SceneTree

const TARGETS := [
	{
		"name": "Cirno",
		"folder": "res://art/cirno",
		"max_total_halo_pixels": 700,
		"max_frame_halo_pixels": 125,
	},
	{
		"name": "Daiyousei",
		"folder": "res://art/daiyousei",
		"max_total_halo_pixels": 300,
		"max_frame_halo_pixels": 80,
	},
	{
		"name": "Rumia",
		"folder": "res://art/rumia",
		"max_total_halo_pixels": 700,
		"max_frame_halo_pixels": 225,
	},
	{
		"name": "Meiling",
		"folder": "res://art/meiling",
		"max_total_halo_pixels": 140,
		"max_frame_halo_pixels": 35,
	},
	{
		"name": "Koakuma",
		"folder": "res://art/koakuma",
		"max_total_halo_pixels": 260,
		"max_frame_halo_pixels": 70,
	},
	{
		"name": "Patchouli",
		"folder": "res://art/patchouli",
		"max_total_halo_pixels": 260,
		"max_frame_halo_pixels": 70,
	},
	{
		"name": "Sakuya",
		"folder": "res://art/sakuya",
		"max_total_halo_pixels": 320,
		"max_frame_halo_pixels": 84,
	},
	{
		"name": "Remilia",
		"folder": "res://art/remilia",
		"max_total_halo_pixels": 380,
		"max_frame_halo_pixels": 96,
	},
]

const ALPHA_EMPTY_THRESHOLD := 8.0 / 255.0
const SOLID_NEIGHBOR_ALPHA_THRESHOLD := 180.0 / 255.0
const HALO_BRIGHTNESS_THRESHOLD := 232.0 / 255.0
const HALO_CHROMA_THRESHOLD := 22.0 / 255.0
const NEIGHBOR_OFFSETS := [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	for target in TARGETS:
		failed = not _assert_boss_folder_cleanup(Dictionary(target)) or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _assert_boss_folder_cleanup(target: Dictionary) -> bool:
	var folder = String(target.get("folder", ""))
	var dir = DirAccess.open(folder)
	if dir == null:
		return _assert_true(false, "failed to open boss art folder %s" % folder)
	var total_halo_pixels := 0
	var worst_frame_halo_pixels := 0
	var frame_count := 0
	for file_name in dir.get_files():
		if not String(file_name).ends_with(".png"):
			continue
		frame_count += 1
		var image := Image.new()
		var path = "%s/%s" % [folder, file_name]
		var absolute_path = ProjectSettings.globalize_path(path)
		if image.load(absolute_path) != OK:
			return _assert_true(false, "failed to load boss art frame %s" % path)
		image.convert(Image.FORMAT_RGBA8)
		var halo_pixels = _count_halo_pixels(image)
		total_halo_pixels += halo_pixels
		worst_frame_halo_pixels = max(worst_frame_halo_pixels, halo_pixels)
	var passed = _assert_true(frame_count > 0, "%s should include exported boss frames" % String(target.get("name", folder)))
	passed = _assert_true(total_halo_pixels <= int(target.get("max_total_halo_pixels", 0)), "%s still has too many bright contour halo pixels (%d total)" % [String(target.get("name", folder)), total_halo_pixels]) and passed
	passed = _assert_true(worst_frame_halo_pixels <= int(target.get("max_frame_halo_pixels", 0)), "%s still has an obvious white fringe on at least one frame (%d pixels on the worst frame)" % [String(target.get("name", folder)), worst_frame_halo_pixels]) and passed
	return passed


func _count_halo_pixels(image: Image) -> int:
	var width = image.get_width()
	var height = image.get_height()
	var halo_pixels := 0
	for y in range(height):
		for x in range(width):
			if _is_halo_pixel(image, x, y):
				halo_pixels += 1
	return halo_pixels


func _is_halo_pixel(image: Image, x: int, y: int) -> bool:
	var pixel = image.get_pixel(x, y)
	if pixel.a <= ALPHA_EMPTY_THRESHOLD:
		return false
	var max_channel = max(pixel.r, max(pixel.g, pixel.b))
	var min_channel = min(pixel.r, min(pixel.g, pixel.b))
	if max_channel < HALO_BRIGHTNESS_THRESHOLD:
		return false
	if max_channel - min_channel > HALO_CHROMA_THRESHOLD:
		return false
	var touches_transparency := false
	var has_darker_solid_neighbor := false
	for offset in NEIGHBOR_OFFSETS:
		var next_x = x + offset.x
		var next_y = y + offset.y
		if next_x < 0 or next_x >= image.get_width() or next_y < 0 or next_y >= image.get_height():
			continue
		var neighbor = image.get_pixel(next_x, next_y)
		if neighbor.a <= ALPHA_EMPTY_THRESHOLD:
			touches_transparency = true
		if neighbor.a >= SOLID_NEIGHBOR_ALPHA_THRESHOLD and max(neighbor.r, max(neighbor.g, neighbor.b)) <= 220.0 / 255.0:
			has_darker_solid_neighbor = true
		if touches_transparency and has_darker_solid_neighbor:
			return true
	return false
