extends SceneTree
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
func _initialize():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output"))
	var file := FileAccess.open("res://output/fusion-plant-data.json",FileAccess.WRITE)
	if file == null: quit(1); return
	file.store_string(JSON.stringify(Fusion.DEFINITIONS,"\t")); file.close()
	var organs := {}
	for id in Defs.PlantDefs.PLANTS:
		var weights := {id:1}
		organs[id] = {"fusion_attack":Fusion.attack_for(id),"fusion_components":[id],"fusion_traits":Fusion.traits_for(id,Defs.PlantDefs.PLANTS[id]),"fusion_base":id}
	var native_file := FileAccess.open("res://output/fusion-native-art-data.json",FileAccess.WRITE)
	native_file.store_string(JSON.stringify(organs)); native_file.close()
	print("Exported %d fusion plant models" % Fusion.DEFINITIONS.size())
	quit()
