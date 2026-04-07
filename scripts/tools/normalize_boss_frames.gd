extends SceneTree

const TARGETS := {
	"rumia_boss": {
		"output_folder": "res://art/rumia",
		"frame_count": 8,
		"sheet_path": "/Users/hecrereed/Downloads/露米娅总图.png",
		"grid": Vector2i(4, 2),
	},
	"daiyousei_boss": {
		"output_folder": "res://art/daiyousei",
		"frame_count": 8,
		"sheet_path": "/Users/hecrereed/Downloads/大妖精.png",
		"grid": Vector2i(3, 3),
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(1, 2),
		],
	},
	"cirno_boss": {
		"output_folder": "res://art/cirno",
		"frame_count": 8,
		"sheet_path": "/Users/hecrereed/Downloads/琪露诺.png",
		"grid": Vector2i(4, 2),
	},
	"meiling_boss": {
		"output_folder": "res://art/meiling",
		"frame_count": 8,
		"existing_frames": true,
	},
	"koakuma_boss": {
		"output_folder": "res://art/koakuma",
		"frame_count": 8,
		"sheet_path": "/Users/hecrereed/Downloads/1-20道中boss.png",
		"grid": Vector2i(4, 2),
	},
	"patchouli_boss": {
		"output_folder": "res://art/patchouli",
		"frame_count": 8,
		"sheet_path": "/Users/hecrereed/Downloads/1-20终末boss.png",
		"grid": Vector2i(4, 2),
	},
	"sakuya_boss": {
		"output_folder": "res://art/sakuya",
		"frame_count": 8,
		"sheet_path": "/Users/hecrereed/Downloads/1-21终末boss.png",
		"grid": Vector2i(3, 3),
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(2, 2),
		],
	},
	"remilia_boss": {
		"output_folder": "res://art/remilia",
		"frame_count": 8,
		"sheet_path": "/Users/hecrereed/Downloads/1-22终末boss.png",
		"grid": Vector2i(3, 4),
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(2, 2),
			Vector2i(0, 3), Vector2i(2, 3),
		],
	},
}

const WHITE_THRESHOLD := 0.93
const ALPHA_THRESHOLD := 0.05
const TRIM_PADDING := 6
const MIN_FOREGROUND_PIXELS := 24
const SAFE_MARGIN := 12
const COMPONENT_BRIDGE_DISTANCE := 28
const HALO_BRIGHTNESS_THRESHOLD := 0.82
const HALO_CHROMA_THRESHOLD := 0.18
const NEIGHBOR_OFFSETS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := 0
	var requested_targets = OS.get_cmdline_user_args()
	var target_keys: Array = []
	if requested_targets.is_empty():
		target_keys = TARGETS.keys()
	else:
		for raw_kind in requested_targets:
			var kind = String(raw_kind)
			if TARGETS.has(kind):
				target_keys.append(kind)
			else:
				push_warning("unknown normalize target: %s" % kind)
	for kind in target_keys:
		if not _normalize_target(String(kind), Dictionary(TARGETS[kind])):
			failures += 1
	quit(1 if failures > 0 else 0)


func _normalize_target(kind: String, config: Dictionary) -> bool:
	var folder = String(config.get("output_folder", ""))
	if folder == "":
		push_error("missing output folder for %s" % kind)
		return false
	var output_dir = ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var frames: Array = []
	if config.has("sheet_path"):
		var sheet_path = String(config.get("sheet_path", ""))
		var sheet = _load_image(sheet_path)
		if sheet == null:
			push_error("failed to load source sheet for %s: %s" % [kind, sheet_path])
			return false
		frames = _extract_sheet_frames(sheet, Vector2i(config.get("grid", Vector2i.ONE)), config.get("cells", []))
	else:
		frames = _normalize_existing_frames(folder, int(config.get("frame_count", 0)))
	var expected_count = int(config.get("frame_count", 0))
	if frames.size() != expected_count:
		push_error("%s expected %d frames, got %d" % [kind, expected_count, frames.size()])
		return false
	for frame_index in range(frames.size()):
		var frame = frames[frame_index]
		if not (frame is Image):
			push_error("%s frame %d is not a valid image" % [kind, frame_index])
			return false
		var frame_image: Image = frame
		var output_path = ProjectSettings.globalize_path("%s/frame_%02d.png" % [folder, frame_index])
		if frame_image.save_png(output_path) != OK:
			push_error("failed to save normalized frame: %s" % output_path)
			return false
	return true


func _normalize_existing_frames(folder: String, frame_count: int) -> Array:
	var frames: Array = []
	for frame_index in range(frame_count):
		var resource_path = "%s/frame_%02d.png" % [folder, frame_index]
		var absolute_path = ProjectSettings.globalize_path(resource_path)
		var image = _load_image(absolute_path)
		if image == null:
			push_error("failed to load frame for offline normalization: %s" % resource_path)
			continue
		var normalized = _extract_trimmed_image(image)
		if normalized == null:
			push_error("frame has no detectable sprite pixels after cleanup: %s" % resource_path)
			continue
		frames.append(normalized)
	return frames


func _extract_sheet_frames(sheet: Image, grid: Vector2i, cells: Array) -> Array:
	var frames: Array = []
	if not cells.is_empty():
		for cell_variant in cells:
			var cell = Vector2i(cell_variant)
			var cell_rect = _sheet_cell_rect(sheet, grid, cell.x, cell.y)
			var frame = _extract_trimmed_image(sheet, cell_rect)
			if frame == null:
				continue
			frames.append(frame)
		return frames
	for row in range(grid.y):
		for col in range(grid.x):
			var cell_rect = _sheet_cell_rect(sheet, grid, col, row)
			var frame = _extract_trimmed_image(sheet, cell_rect)
			if frame == null:
				continue
			frames.append(frame)
	return frames


func _sheet_cell_rect(image: Image, grid: Vector2i, col: int, row: int) -> Rect2i:
	var x0 = int(floor(float(image.get_width()) * float(col) / float(grid.x)))
	var x1 = int(floor(float(image.get_width()) * float(col + 1) / float(grid.x)))
	var y0 = int(floor(float(image.get_height()) * float(row) / float(grid.y)))
	var y1 = int(floor(float(image.get_height()) * float(row + 1) / float(grid.y)))
	return Rect2i(x0, y0, x1 - x0, y1 - y0)


func _extract_trimmed_image(source: Image, source_rect: Rect2i = Rect2i()) -> Image:
	var rect = source_rect
	if rect.size == Vector2i.ZERO:
		rect = Rect2i(0, 0, source.get_width(), source.get_height())
	var component_data = _collect_foreground_components(source, rect)
	var components: Array = component_data.get("components", [])
	if components.is_empty():
		return null
	var keep_component_indices = _select_components_to_keep(components)
	if keep_component_indices.is_empty():
		return null
	var sprite_bounds = _combined_component_rect(components, keep_component_indices)
	var padded_rect = Rect2i(
		max(rect.position.x, sprite_bounds.position.x - TRIM_PADDING),
		max(rect.position.y, sprite_bounds.position.y - TRIM_PADDING),
		0,
		0
	)
	var padded_max_x = min(rect.position.x + rect.size.x - 1, sprite_bounds.end.x - 1 + TRIM_PADDING)
	var padded_max_y = min(rect.position.y + rect.size.y - 1, sprite_bounds.end.y - 1 + TRIM_PADDING)
	padded_rect.size = Vector2i(padded_max_x - padded_rect.position.x + 1, padded_max_y - padded_rect.position.y + 1)
	var out = Image.create(padded_rect.size.x + SAFE_MARGIN * 2, padded_rect.size.y + SAFE_MARGIN * 2, false, Image.FORMAT_RGBA8)
	out.fill(Color(1.0, 1.0, 1.0, 0.0))
	var keep_lookup := {}
	for component_index in keep_component_indices:
		keep_lookup[int(component_index)] = true
	var labels: PackedInt32Array = component_data.get("labels", PackedInt32Array())
	for y in range(padded_rect.size.y):
		for x in range(padded_rect.size.x):
			var src_x = padded_rect.position.x + x
			var src_y = padded_rect.position.y + y
			var label_index = (src_y - rect.position.y) * rect.size.x + (src_x - rect.position.x)
			if label_index < 0 or label_index >= labels.size():
				continue
			var component_index = labels[label_index]
			if component_index < 0 or not keep_lookup.has(component_index):
				continue
			var pixel = source.get_pixel(src_x, src_y)
			if _is_foreground(pixel):
				out.set_pixel(x + SAFE_MARGIN, y + SAFE_MARGIN, pixel)
	_clear_border_connected_halo(out)
	out.flip_x()
	return out


func _collect_foreground_components(source: Image, rect: Rect2i) -> Dictionary:
	var width = rect.size.x
	var height = rect.size.y
	var visited := PackedByteArray()
	visited.resize(width * height)
	var labels := PackedInt32Array()
	labels.resize(width * height)
	labels.fill(-1)
	var components: Array = []
	for local_y in range(height):
		for local_x in range(width):
			var linear_index: int = local_y * width + local_x
			if visited[linear_index] != 0:
				continue
			visited[linear_index] = 1
			var source_x: int = rect.position.x + local_x
			var source_y: int = rect.position.y + local_y
			if not _is_foreground(source.get_pixel(source_x, source_y)):
				continue
			var component_index: int = components.size()
			var queue: Array = [Vector2i(local_x, local_y)]
			var head := 0
			labels[linear_index] = component_index
			var min_x: int = source_x
			var min_y: int = source_y
			var max_x: int = source_x
			var max_y: int = source_y
			var pixels := 0
			while head < queue.size():
				var point: Vector2i = queue[head]
				head += 1
				var absolute_x: int = rect.position.x + point.x
				var absolute_y: int = rect.position.y + point.y
				pixels += 1
				min_x = min(min_x, absolute_x)
				min_y = min(min_y, absolute_y)
				max_x = max(max_x, absolute_x)
				max_y = max(max_y, absolute_y)
				for offset in NEIGHBOR_OFFSETS:
					var next = point + offset
					if next.x < 0 or next.x >= width or next.y < 0 or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if visited[next_index] != 0:
						continue
					visited[next_index] = 1
					var next_pixel = source.get_pixel(rect.position.x + next.x, rect.position.y + next.y)
					if not _is_foreground(next_pixel):
						continue
					labels[next_index] = component_index
					queue.append(next)
			components.append({
				"pixels": pixels,
				"rect": Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1),
			})
	return {
		"components": components,
		"labels": labels,
	}


func _select_components_to_keep(components: Array) -> Array:
	if components.is_empty():
		return []
	var primary_index := 0
	var primary_pixels := int(components[0].get("pixels", 0))
	for component_index in range(1, components.size()):
		var component_pixels = int(components[component_index].get("pixels", 0))
		if component_pixels > primary_pixels:
			primary_pixels = component_pixels
			primary_index = component_index
	var dominant_rect: Rect2i = components[primary_index].get("rect", Rect2i())
	var dominant_bridge_rect = _expand_rect(dominant_rect, COMPONENT_BRIDGE_DISTANCE)
	var kept: Array = [primary_index]
	for component_index in range(components.size()):
		if component_index == primary_index:
			continue
		var component_rect: Rect2i = components[component_index].get("rect", Rect2i())
		if _rects_intersect(dominant_bridge_rect, component_rect):
			kept.append(component_index)
	return kept


func _combined_component_rect(components: Array, keep_component_indices: Array) -> Rect2i:
	var merged_rect: Rect2i = components[int(keep_component_indices[0])].get("rect", Rect2i())
	for i in range(1, keep_component_indices.size()):
		var component_index = int(keep_component_indices[i])
		merged_rect = merged_rect.merge(components[component_index].get("rect", Rect2i()))
	return merged_rect


func _clear_border_connected_halo(image: Image) -> void:
	var width = image.get_width()
	var height = image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array = []
	for x in range(width):
		_enqueue_halo_seed(image, visited, queue, x, 0)
		_enqueue_halo_seed(image, visited, queue, x, height - 1)
	for y in range(height):
		_enqueue_halo_seed(image, visited, queue, 0, y)
		_enqueue_halo_seed(image, visited, queue, width - 1, y)
	var head := 0
	while head < queue.size():
		var point: Vector2i = queue[head]
		head += 1
		var pixel = image.get_pixel(point.x, point.y)
		if pixel.a > ALPHA_THRESHOLD:
			image.set_pixel(point.x, point.y, Color(1.0, 1.0, 1.0, 0.0))
		for offset in NEIGHBOR_OFFSETS:
			var next = point + offset
			if next.x < 0 or next.x >= width or next.y < 0 or next.y >= height:
				continue
			var index = next.y * width + next.x
			if visited[index] != 0:
				continue
			var next_pixel = image.get_pixel(next.x, next.y)
			if not _is_clearable_halo_pixel(next_pixel):
				continue
			visited[index] = 1
			queue.append(next)


func _enqueue_halo_seed(image: Image, visited: PackedByteArray, queue: Array, x: int, y: int) -> void:
	var pixel = image.get_pixel(x, y)
	if not _is_clearable_halo_pixel(pixel):
		return
	var index = y * image.get_width() + x
	if visited[index] != 0:
		return
	visited[index] = 1
	queue.append(Vector2i(x, y))


func _is_clearable_halo_pixel(pixel: Color) -> bool:
	if pixel.a <= ALPHA_THRESHOLD:
		return true
	var max_channel = max(pixel.r, max(pixel.g, pixel.b))
	var min_channel = min(pixel.r, min(pixel.g, pixel.b))
	var chroma = max_channel - min_channel
	return max_channel >= HALO_BRIGHTNESS_THRESHOLD and chroma <= HALO_CHROMA_THRESHOLD


func _expand_rect(rect: Rect2i, amount: int) -> Rect2i:
	return Rect2i(
		rect.position - Vector2i(amount, amount),
		rect.size + Vector2i(amount * 2, amount * 2)
	)


func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
	return not (
		a.position.x + a.size.x <= b.position.x
		or b.position.x + b.size.x <= a.position.x
		or a.position.y + a.size.y <= b.position.y
		or b.position.y + b.size.y <= a.position.y
	)


func _is_foreground(pixel: Color) -> bool:
	if pixel.a <= ALPHA_THRESHOLD:
		return false
	return not (pixel.r >= WHITE_THRESHOLD and pixel.g >= WHITE_THRESHOLD and pixel.b >= WHITE_THRESHOLD)


func _load_image(path: String) -> Image:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image
