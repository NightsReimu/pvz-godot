extends SceneTree
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const Art = preload("res://scripts/ui/fusion_plant_art.gd")
var failures := 0
func _initialize():
	var rasterized := 0
	for id in Fusion.DEFINITIONS:
		var path: String = "res://art/vector/fusions/%s.svg" % id
		if not FileAccess.file_exists(path):
			failures += 1; push_error("Missing independent fusion model: "+id); continue
		var image := Image.new()
		if image.load_svg_from_string(FileAccess.get_file_as_string(path)) != OK or image.is_empty():
			failures += 1; push_error("Unrenderable fusion model: "+id)
		else: rasterized += 1
	var id: String = "pea_bastion"
	for ingredient in ["winter_melon","torchwood","coffee_bean","sunflower","nether_shroom","mirror_shroom","healing_gourd","starfruit"]:
		id = Fusion.result(id,ingredient)
		var image := Image.new()
		if image.load_svg_from_string(Art.svg_for(id,Defs.PLANTS[id])) != OK: failures += 1
	print("Fusion SVG rasterization: %d static models, 8 recursive stages, %d failure(s)" % [rasterized,failures])
	quit(1 if failures else 0)
