extends "res://tests/plant_fusion_test.gd"

func test_moving_lobbers():
 for source in ["cabbage_pult","kernel_pult","melon_pult","dragon_bubble_pult","toxic_gum_pult","chimney_pepper","skylight_melon","meteor_flower","obsidian_artichoke","pressure_bamboo"]:
  for fused in [false,true]:
   var g = make_game()
   var id: String = Fusion.result(source,"wallnut") if fused else source
   var p: Dictionary = g._create_plant(id,2,1); p.sleep_timer = 0; g.grid[2][1] = p
   g._spawn_zombie_at("normal",2,g._cell_center(2,7).x)
   g.zombies[0].health = 10000
   for n in range(450):
    if not g.projectiles.is_empty(): break
    g._update_plants(0.02)
   check(not g.projectiles.is_empty(),"Lobber launches: %s/%s" % [source,fused])
   for n in range(150):
    g.zombies[0].x -= 100.0*0.02
    g._update_projectiles(0.02)
   check(g.zombies[0].health < 10000,"Lobber hits moving target: %s/%s" % [source,fused])
   dispose(g)

func test_native_targeting():
 var g = make_game()
 var moon: Dictionary = g._create_plant(Fusion.result("moonforge","wallnut"),4,1)
 g.grid[4][1] = moon
 g._spawn_zombie_at("normal",0,g._cell_center(0,6).x)
 for n in range(400):
  g._update_plants(0.02)
  if not g.projectiles.is_empty(): break
 check(g.projectiles.any(func(s): return s.get("kind","") == "moon_meteor"),"Fusion moonforge retains global target and original moon meteor")
 g.grid[4][1] = null; g.projectiles.clear()
 g.grid[2][2] = g._create_plant(Fusion.result("lotus_lancer","torchwood"),2,2)
 g._update_plants(1)
 check(g.projectiles.filter(func(s): return s.get("kind","") == "lotus_orbit_shot").size() == 8,"Lotus retains eight orbiting radial projectiles across lanes")
 g.grid[2][2] = g._create_plant(Fusion.result("lantern_bloom","wallnut"),2,2)
 g.zombies.clear(); g._spawn_zombie_at("balloon_zombie",1,g._cell_center(1,2).x)
 var hp: float = g.zombies[0].health
 for n in range(200): g._update_plants(0.02)
 check(g.zombies[0].health < hp,"Lantern retains square-area anti-air")
 dispose(g)

func test_bases_and_heal():
 var g = make_game()
 for base in ["lily_pad","flower_pot"]:
  for source in Native.PLANTS:
   check(Fusion.result(base,source).is_empty(),"Terrain base never fuses: "+base+"/"+source)
  check(Fusion.result(base,Fusion.result("sunflower","peashooter")).is_empty(),"Recursive fusion rejects terrain base")
 var p: Dictionary = g._create_plant(Fusion.result("peashooter","cabbage_pult"),2,2)
 g.grid[2][2] = p; p.health = 1; p.ultimate_charge = 1
 check(g._try_activate_ultimate(2,2),"Click ultimate activates")
 check(p.health == p.max_health,"Click fusion ultimate heals to full")
 dispose(g)

func _run():
 test_moving_lobbers()
 test_native_targeting()
 test_bases_and_heal()
 print("Fusion native inheritance: %d failures" % failures)
 quit(1 if failures else 0)
