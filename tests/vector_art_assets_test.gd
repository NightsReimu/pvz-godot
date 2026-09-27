extends SceneTree

const Manifest = preload("res://scripts/data/vector_plant_manifest.gd")
const Defs = preload("res://scripts/game_defs.gd")
var failures := 0
var primary_signatures := {}
var primary_masks := {}

func _initialize() -> void:
	_check_classic_plant_contracts()
	for kind in Manifest.KINDS:
		if not Defs.PLANTS.has(kind): fail("Unknown species: " + kind)
	var files := DirAccess.get_files_at("res://art/vector/plants")
	var count := 0
	for file in files:
		if not file.ends_with(".svg"): continue
		var asset_path := "res://art/vector/plants/" + file
		var texture: Texture2D = load(asset_path)
		if texture == null:
			fail("Missing imported vector: " + file)
			continue
		var image := texture.get_image()
		var used := image.get_used_rect()
		if used.size.x < 20 or used.size.y < 20: fail("Empty or unreadable model: " + file)
		if used.position.x < 2 or used.position.y < 2 or used.end.x > image.get_width()-2 or used.end.y > image.get_height()-2:
			fail("Art touches its canvas edge and risks clipping: " + file + " " + str(used))
		var source := FileAccess.get_file_as_string(asset_path)
		if source.find("data-plant-kind=") == -1 or source.find("data-art-signature=") == -1:
			fail("SVG is missing its generated species identity metadata: " + file)
		if not _is_state_variant(file):
			var signature := _attribute_value(source, "data-art-signature")
			if signature.is_empty():
				fail("Primary SVG has an empty species signature: " + file)
			elif primary_signatures.has(signature):
				fail("Primary SVG shares an art signature with %s: %s" % [primary_signatures[signature], file])
			else:
				primary_signatures[signature] = file
			var mask := _silhouette_signature(image)
			if primary_masks.has(mask):
				fail("Primary SVG shares its sampled silhouette with %s: %s" % [primary_masks[mask], file])
			else:
				primary_masks[mask] = file
		count += 1
	if primary_signatures.size() != Manifest.KINDS.size():
		fail("Expected one unique art signature per species, got %d for %d species" % [primary_signatures.size(), Manifest.KINDS.size()])
	if primary_masks.size() != Manifest.KINDS.size():
		fail("Expected one unique sampled silhouette per species, got %d for %d species" % [primary_masks.size(), Manifest.KINDS.size()])
	print("Vector assets: %d species, %d SVGs, %d unique signatures, %d unique silhouettes, %d failures" % [Manifest.KINDS.size(), count, primary_signatures.size(), primary_masks.size(), failures])
	quit(1 if failures else 0)

func _check_classic_plant_contracts() -> void:
	var grave := _svg_source("grave_buster")
	if grave.find('fill="url(#leaf)"') == -1:
		fail("Grave Buster must keep its green leaf body")
	if grave.find('fill="url(#plum)"') != -1:
		fail("Grave Buster must not fall back to the Chomper purple palette")

	var hypno := _svg_source("hypno_shroom")
	for marker in ["id=\"hypno\"", "#d77be2", "#713b91", "#9b4eae"]:
		if hypno.find(marker) == -1:
			fail("Hypno-shroom is missing its purple hypnotic marker: " + marker)

	var repeater := _svg_source("repeater")
	if repeater.find('data-plant-kind="repeater"') == -1 or repeater.count('translate(') < 3:
		fail("Repeater must retain its distinct two-headed silhouette")
	if _svg_source("marigold").find('url(#fire)') == -1:
		fail("Marigold must retain its orange fire-petal palette")
	if _svg_source("squash").find('Q-34 3 -25 -15') == -1:
		fail("Squash must retain its broad ribbed PVZ silhouette")
	if _svg_source("sea_shroom").find('id=\"sea\"') == -1:
		fail("Sea-shroom must retain its blue aquatic palette")

func _svg_source(kind: String) -> String:
	return FileAccess.get_file_as_string("res://art/vector/plants/" + kind + ".svg")

func fail(message: String) -> void:
	failures += 1
	push_error(message)

func _is_state_variant(file: String) -> bool:
	for suffix in ["_damaged.svg", "_critical.svg", "_unarmed.svg", "_chewing.svg", "_young.svg", "_hiding.svg"]:
		if file.ends_with(suffix):
			return true
	return false

func _attribute_value(source: String, attribute: String) -> String:
	var marker := attribute + "=\""
	var start := source.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end := source.find("\"", start)
	return "" if end == -1 else source.substr(start, end - start)

func _silhouette_signature(image: Image) -> String:
	var signature := ""
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			signature += "1" if image.get_pixel(x, y).a > 0.31 else "0"
	return signature
