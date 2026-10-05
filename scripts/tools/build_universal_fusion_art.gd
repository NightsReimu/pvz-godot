extends SceneTree
const Defs = preload("res://scripts/game_defs.gd")
const Art = preload("res://scripts/ui/fusion_plant_art.gd")

# Writes one SVG per fixed fusion and removes models whose recipe no longer exists.
func _initialize():
	var count := 0
	var keep := {}
	for id in Defs.PLANTS:
		if not bool(Defs.PLANTS[id].get("fusion_only",false)) or bool(Defs.PLANTS[id].get("fusion_art_dynamic",false)): continue
		keep[id] = true
		var svg: String = Art.svg_for(id,Defs.PLANTS[id])
		var file := FileAccess.open("res://art/vector/fusions/%s.svg" % id,FileAccess.WRITE)
		if file == null: quit(1); return
		file.store_string(svg); file.close(); count += 1
	var removed := 0
	for name in DirAccess.get_files_at("res://art/vector/fusions"):
		var stem: String = name.get_basename().get_basename() if name.ends_with(".svg.import") else name.get_basename()
		if not keep.has(stem):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("res://art/vector/fusions/"+name))
			removed += 1
	print("Composed %d fusion SVGs from the fusion anatomy library; removed %d stale files" % [count,removed])
	quit()
