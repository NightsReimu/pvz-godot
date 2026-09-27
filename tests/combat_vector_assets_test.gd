extends SceneTree

const PROJECTILE_DIR := "res://art/vector/combat_projectiles"
const EFFECT_DIR := "res://art/vector/combat_effects"
const PROJECTILE_REFERENCE_DIR := "res://art/image2/projectiles"
const EFFECT_REFERENCE_DIR := "res://art/image2/effects"
const EXTRA_PROJECTILES := ["dragon_bubble", "toxic_gum", "gator_orb", "snow_pea", "fire_pea", "phoenix_flame"]
var failures := 0
var signatures := {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_family(PROJECTILE_REFERENCE_DIR, PROJECTILE_DIR, "projectile")
	_check_family(EFFECT_REFERENCE_DIR, EFFECT_DIR, "effect")
	for key in EXTRA_PROJECTILES:
		_check_asset(PROJECTILE_DIR, key, "projectile")
	print("Combat vector assets: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _check_family(reference_dir: String, asset_dir: String, label: String) -> void:
	for file in DirAccess.get_files_at(reference_dir):
		if file.ends_with(".png"):
			_check_asset(asset_dir, file.trim_suffix(".png"), label)

func _check_asset(directory: String, key: String, label: String) -> void:
	var path := "%s/%s.svg" % [directory, key]
	if not FileAccess.file_exists(path):
		_fail("Missing %s SVG: %s" % [label, path])
		return
	var source := FileAccess.get_file_as_string(path)
	for marker in ['data-art-key="%s"' % key, "data-art-signature=", "data-art-family="]:
		if source.find(marker) == -1:
			_fail("Missing %s in %s" % [marker, path])
	var signature := _attribute(source, "data-art-signature")
	if signatures.has(signature):
		_fail("Duplicate SVG signature: %s and %s" % [signatures[signature], path])
	signatures[signature] = path
	var texture: Texture2D = load(path)
	if texture == null or texture.get_image().get_used_rect().size.x < 10:
		_fail("Unreadable SVG: " + path)

func _attribute(source: String, name: String) -> String:
	var marker := name + "=\""
	var start := source.find(marker)
	if start == -1: return ""
	start += marker.length()
	var end := source.find("\"", start)
	return source.substr(start, end - start) if end > start else ""

func _fail(message: String) -> void:
	failures += 1
	push_error(message)
