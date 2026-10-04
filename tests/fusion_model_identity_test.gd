extends "res://tests/plant_fusion_test.gd"
const Art = preload("res://scripts/ui/fusion_plant_art.gd")

func silhouette(id: String) -> PackedByteArray:
 var pixels := Image.new()
 check(pixels.load_svg_from_string(Art.svg_for(id,Defs.PLANTS[id])) == OK,"Renderable model: "+id)
 pixels.resize(48,56,Image.INTERPOLATE_LANCZOS)
 var mask := PackedByteArray()
 for y in range(48):
  for x in range(48): mask.append(1 if pixels.get_pixel(x,y).a > 0.5 else 0)
 return mask

func distance(a: PackedByteArray,b: PackedByteArray) -> float:
 var union := 0; var different := 0
 for i in range(a.size()):
  if a[i] != 0 or b[i] != 0: union += 1
  if a[i] != b[i]: different += 1
 return float(different)/maxf(1,union)

func test_native_only_almanac():
 var g = make_game()
 for id in Native.ORDER: g.plant_stars[id] = 1
 var grown: String = Fusion.result(Fusion.result("peashooter","wallnut"),"cherry_bomb")
 g.plant_stars[grown] = 1
 var entries: Array = g._visible_almanac_plants()
 check(entries.has("peashooter") and entries.has("wallnut"),"Native ownership still enters the almanac")
 for id in entries: check(not bool(Defs.PLANTS[id].get("fusion_only",false)),"Almanac must never list a fusion: "+id)
 g.almanac_tab = "plants"; g.almanac_selected_kind = grown
 g._ensure_almanac_selection()
 check(g.almanac_selected_kind in entries,"An old fusion selection resets to an available native plant")
 dispose(g)

func test_readable_silhouettes():
 var masks: Array = []; var labels: Array = []
 # Sharing one ingredient must not force every artillery model onto the same bowl.
 for source in ["cabbage_pult","kernel_pult","melon_pult","corn_cannon","skylight_melon","sulfur_pod","obsidian_artichoke","pressure_bamboo"]:
  var id: String = Fusion.result("peashooter",source)
  masks.append(silhouette(id)); labels.append(id)
 var smallest := 1.0; var total := 0.0; var pairs := 0
 for a in range(masks.size()):
  for b in range(a+1,masks.size()):
   var separation := distance(masks[a],masks[b]); smallest = minf(smallest,separation)
   total += separation; pairs += 1
   check(separation > 0.14,"Shared-ingredient models need different visible silhouettes: %s / %s (%.3f)" % [labels[a],labels[b],separation])
 check(total/pairs > 0.32,"A collection must have varied proportions, not just local decoration")
 print("Artillery silhouette distance: minimum=%.3f mean=%.3f" % [smallest,total/pairs])

func _run():
 test_native_only_almanac(); test_readable_silhouettes()
 print("Fusion model identity: %d failure(s)" % failures)
 quit(1 if failures else 0)
