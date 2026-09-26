extends RefCounted

const Manifest = preload("res://scripts/data/vector_plant_manifest.gd")
static var textures: Dictionary = {}

# Imported SVGs are cached once. Drawing keeps the caller's animation transform,
# and one alpha covers the entire model including outlines and ground contact.
static func draw_plant(canvas: CanvasItem, kind: String, center: Vector2, scale: float, flash: float, alpha: float, state: String = "") -> void:
	var key := kind + ("_" + state if not state.is_empty() else "")
	if not textures.has(key):
		textures[key] = load("res://art/vector/plants/%s.svg" % key)
	var texture: Texture2D = textures[key]
	var rect := Rect2(center + Vector2(-48, -60) * scale, Vector2(96, 112) * scale)
	var brightness := 1.0 + clampf(flash * 3.5, 0.0, 0.85)
	canvas.draw_texture_rect(texture, rect, false, Color(brightness, brightness, brightness, alpha))
