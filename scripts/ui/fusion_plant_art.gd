extends RefCounted
const Morphology = preload("res://scripts/ui/fusion_plant_morphology.gd")

# Fixed SVG assets and live recursive grafts use exactly the same anatomy.
static func svg_for(id: String, data: Dictionary) -> String:
	return Morphology.svg_for(id,data)

static func charge_anchor(id: String, data: Dictionary) -> Vector2:
	return Morphology.layout_for(id,data).charge_anchor
