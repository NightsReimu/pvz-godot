extends SceneTree

const Manifest = preload("res://scripts/data/vector_plant_manifest.gd")
const Defs = preload("res://scripts/game_defs.gd")
var failures := 0

func _initialize() -> void:
	for kind in Manifest.KINDS:
		if not Defs.PLANTS.has(kind): fail("Unknown species: " + kind)
	var files := DirAccess.get_files_at("res://art/vector/plants")
	var count := 0
	for file in files:
		if not file.ends_with(".svg"): continue
		var texture: Texture2D = load("res://art/vector/plants/" + file)
		if texture == null:
			fail("Missing imported vector: " + file)
			continue
		var image := texture.get_image()
		var used := image.get_used_rect()
		if used.size.x < 20 or used.size.y < 20: fail("Empty or unreadable model: " + file)
		if used.position.x < 2 or used.position.y < 2 or used.end.x > image.get_width()-2 or used.end.y > image.get_height()-2:
			fail("Art touches its canvas edge and risks clipping: " + file + " " + str(used))
		count += 1
	print("Vector assets: %d species, %d SVGs, %d failures" % [Manifest.KINDS.size(), count, failures])
	quit(1 if failures else 0)

func fail(message: String) -> void:
	failures += 1
	push_error(message)
