extends SceneTree
const Defs = preload("res://scripts/game_defs.gd")
const Art = preload("res://scripts/ui/fusion_plant_art.gd")

func _initialize():
	var count := 0
	for id in Defs.PLANTS:
		if not bool(Defs.PLANTS[id].get("fusion_only",false)): continue
		var svg: String = Art.svg_for(id,Defs.PLANTS[id])
		var file := FileAccess.open("res://art/vector/fusions/%s.svg" % id,FileAccess.WRITE)
		if file == null: quit(1); return
		file.store_string(svg); file.close(); count += 1
	print("Authored %d independent botanical fusion SVGs" % count)
	quit()
