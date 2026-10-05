extends RefCounted
const Morphology = preload("res://scripts/ui/fusion_plant_morphology.gd")

# Fixed SVG assets and live recursive grafts use exactly the same anatomy.
static func svg_for(id: String, data: Dictionary) -> String:
	return Morphology.svg_for(id,data)

static var layouts: Dictionary = {}

static func layout(id: String, data: Dictionary) -> Dictionary:
	if not layouts.has(id):
		if layouts.size() > 512: layouts.clear()
		layouts[id] = Morphology.layout_for(id,data)
	return layouts[id]

static func charge_anchor(id: String, data: Dictionary) -> Vector2:
	return layout(id,data).charge_anchor
