extends "res://tests/plant_fusion_test.gd"
const Ammo = preload("res://scripts/data/plant_ammo.gd")

func fixture() -> Control:
 var g = make_game(); g.rng.seed = 162
 for row in range(5):
  for col in [3,6]:
   g._spawn_zombie_at("normal",row,g._cell_center(row,col).x)
   g.zombies.back().health = 1000000
 g._spawn_zombie_at("balloon_zombie",2,g._cell_center(2,4).x)
 g._spawn_zombie_at("shouyue",2,g._cell_center(2,7).x)
 g.grid[1][2] = g._create_plant("wallnut",1,2); g.grid[1][2].health = 20
 g.grid[3][2] = g._create_plant("sunflower",3,2); g.grid[3][2].health = 20
 return g

func sample_patterns(g: Control, source: String, fused: bool) -> Dictionary:
 var signatures: Dictionary = {}
 var key: String = "peashooter" if source == "repeater" else source
 var id: String = Fusion.result(source,"wallnut") if fused else source
 if id.is_empty() or not Defs.PLANTS.has(id):
  check(false,"Missing audited fusion definition: "+source+" / "+id)
  return signatures
 var p: Dictionary = g._create_plant(id,2,2); p.sleep_timer = 0; g.grid[2][2] = p
 for n in range(450):
  g.level_time += 0.1
  if fused: g._ensure_plant_fusion().update(p,0.1,2,2)
  else: g._update_plants(0.1)
  for shot in g.projectiles:
   if not fused or shot.get("fusion_channel_source","") == key:
    signatures[String(shot.get("volcano_seed",shot.get("kind","pea")))] = true
  for roller in g.rollers:
   if not fused or roller.get("fusion_channel_source","") == key: signatures["roller"] = true
  g.projectiles.clear(); g.rollers.clear(); g.effects.clear(); g.suns.clear()
 if fused and not Fusion.Combat.BURSTS.has(source):
  check(p.fusion_native_states.has(key),"Every continuous material owns its native state: "+source)
 return signatures

func test_all_native_patterns():
 var rows: Array = []
 for source in Native.PLANTS:
  if source in Fusion.EXCLUDED or source in Fusion.UNOBTAINABLE: continue
  var original = fixture(); var mixed = fixture()
  var baseline := sample_patterns(original,source,false)
  var inherited := sample_patterns(mixed,source,true)
  # Random magic ammunition is exhaustively tested separately, one registered variant at a time.
  if not Fusion.Combat.BURSTS.has(source) and source != "origami_blossom":
   for kind in baseline:
    check(inherited.has(kind),"Native projectile lost after fusion: "+source+" / "+kind)
  rows.append({"source":source,"native":baseline.keys(),"fused":inherited.keys(),"burst":Fusion.Combat.BURSTS.has(source)})
  dispose(original); dispose(mixed)
 var file = FileAccess.open("res://output/fusion-native-audit162.json",FileAccess.WRITE)
 if file: file.store_string(JSON.stringify(rows,"  "))
 check(rows.size() == Native.PLANTS.size()-Fusion.EXCLUDED.size()-Fusion.UNOBTAINABLE.size(),"Audit covers all eligible native materials")

func test_composed_ammunition():
 var g = make_game(); g.rng.seed = 162
 g.grid[2][2] = g._create_plant(Fusion.result("kernel_pult","torchwood"),2,2)
 g._spawn_zombie_at("normal",2,g._cell_center(2,6).x)
 g.zombies[0].health = 100000
 var kinds: Dictionary = {}
 for n in range(1200):
  g._update_plants(0.1)
  for shot in g.projectiles:
   if shot.get("fusion_channel_source","") == "kernel_pult":
    kinds[shot.kind] = true
    check("flame" in shot.get("ammo_elements",[]),"Every kernel/butter payload carries flame")
    if shot.kind == "butter": check(float(shot.butter_duration) > 0,"Flaming butter keeps its stun")
  g.projectiles.clear()
 check(kinds.has("kernel") and kinds.has("butter"),"Corn fusion retains real corn/butter probability")
 var center: Vector2 = g._zombie_lane_point(g.zombies[0],2)
 g._ensure_plant_runtime().spawn_roof_lobbed_projectile("butter",2,center,center,20,Color.YELLOW,20,10,0,2.6)
 var butter: Dictionary = g.projectiles.back(); Ammo.compose(butter,{"torchwood":1},"kernel_pult")
 g._ensure_projectile_runtime().resolve_lobbed_projectile_impact(butter,center)
 check(g.zombies[0].health < 100000 and float(g.zombies[0].special_pause_timer) >= 2.6 and float(g.zombies[0].corrode_dps) > 0,"Flaming butter hits, stuns, and burns")
 dispose(g)

func test_cannon_and_merge():
 var g = make_game()
 var id: String = Fusion.result("corn_cannon","sunflower")
 var p: Dictionary = g._create_plant(id,2,2); g.grid[2][2] = p
 g._spawn_zombie_at("normal",0,g._cell_center(0,6).x); g.zombies[0].health = 1000
 g._handle_corn_cannon_right_click(g._cell_center(0,6))
 check(g.zombies[0].health < 1000,"Fused cannon retains manual cross-lane targeting")
 var hp: float = g.zombies[0].health
 g._handle_corn_cannon_right_click(g._cell_center(0,6))
 check(g.zombies[0].health == hp,"Manual fusion cannon cannot ignore reload")
 var next: Dictionary = g._ensure_plant_fusion().combined(Fusion.result(id,"peashooter"),p)
 check(next.get("corn_reload",0) > 0,"Recursive graft preserves manual cannon reload")
 g.grid[2][2] = next
 for n in range(210): g._update_plants(0.1)
 g._handle_corn_cannon_right_click(g._cell_center(0,6))
 check(g.zombies[0].health < hp,"Manual cannon reload finishes normally")
 dispose(g)

func test_lost_target():
 var g = make_game()
 g._spawn_zombie_at("normal",2,g._cell_center(2,6).x)
 var point: Vector2 = g._zombie_lane_point(g.zombies[0],2)
 g._ensure_plant_runtime().spawn_roof_lobbed_projectile("cabbage",2,g._cell_center(2,1),point,40,Color.GREEN,60)
 g.zombies[0] = g._hypnotize_zombie(g.zombies[0])
 var hp: float = g.zombies[0].health
 for n in range(150):
  g.zombies[0].x += 1
  g._update_projectiles(0.02)
 check(g.zombies[0].health == hp,"A homing target that becomes friendly is never hit")
 dispose(g)

func test_payload_inheritance_and_passives():
 var g = make_game()
 g._spawn_zombie_at("normal",2,g._cell_center(2,6).x); g.zombies[0].health = 10000
 var shot := {"kind":"sakura_petal","damage":20.0,"row":2,"position":g._cell_center(2,2),"radius":8.0,"split_count":2}
 Ammo.compose(shot,{"torchwood":1,"snow_pea":1,"heather_shooter":1,"storm_reed":1,"hypno_shroom":1,"root_snare":1})
 check(shot.ammo_elements.size() == 6,"All six payload families can coexist")
 g._ensure_projectile_runtime().spawn_sakura_split_projectiles(shot,g._cell_center(2,5))
 check(g.projectiles.size() == 2 and g.projectiles[0].ammo_elements == shot.ammo_elements,"Magic/fused split petals retain every element")
 var z: Dictionary = g._ensure_projectile_runtime().apply_ammo_status(g.zombies[0],shot)
 check(float(z.corrode_dps) >= 15 and float(z.slow_timer) > 0 and float(z.rooted_timer) > 0 and float(z.special_pause_timer) > 0,"Burn, poison, frost, roots and electricity have actual combat effects")
 check(g._is_enemy_zombie(z),"Dream ammunition needs multiple hits")
 for n in range(5): z = g._ensure_projectile_runtime().apply_ammo_status(z,shot)
 check(not g._is_enemy_zombie(z),"Dream ammunition eventually converts an ordinary enemy")
 var p: Dictionary = g._create_plant(Fusion.result("pumpkin","peashooter"),2,2)
 p.armor_health = 0; g.grid[2][2] = p
 g._update_plants(1)
 check(g.grid[2][2] != null and float(p.health) > 0,"Losing a pumpkin armor layer does not erase the living hybrid")
 var thermal: Dictionary = g._create_plant(Fusion.result("thermal_sunflower","peashooter"),2,3)
 g.grid[2][3] = thermal
 g._ensure_volcano_expansion().on_eruption(2,3)
 check(int(thermal.geothermal_charge) > 0,"A hybrid retains its thermal eruption response")
 g.zombies.clear()
 var runtime = g._ensure_plant_fusion()
 var chamber: Dictionary = runtime.native_runtime.state_for(p,"peashooter",2,2)
 chamber.flash = 0.16; p.flash = 0.16
 g._update_plants(0.3)
 check(float(p.flash) == 0 and float(chamber.flash) == 0,"Native component hit flashes expire instead of keeping the hybrid white")
 dispose(g)

func test_magic_runtime():
 for base in Ammo.BASES:
  var g = make_game()
  for row in range(5):
   g._spawn_zombie_at("normal",row,g._cell_center(row,5).x); g.zombies.back().health = 10000
  g._spawn_zombie_at("normal",2,g._cell_center(2,4).x)
  g.zombies[g.zombies.size()-1] = g._hypnotize_zombie(g.zombies.back())
  var friend: Dictionary = g.zombies.back(); var hp: float = friend.health
  g._spawn_magic_flower_projectile(2,g._cell_center(2,1),1.0,"flame+frost+venom+storm:"+base)
  for n in range(200):
   g._update_projectiles(0.02); g._update_rollers(0.02)
  check(friend.health == hp,"Every magic ammunition handler protects allies: "+base)
  dispose(g)
 var g = make_game()
 g.grid[2][3] = g._create_plant("torchwood",2,3)
 g._spawn_zombie_at("normal",2,g._cell_center(2,7).x)
 var origin: Vector2 = g._cell_center(2,2)
 var aim: Vector2 = g._cell_center(2,7)
 g._ensure_plant_runtime().spawn_roof_lobbed_projectile("butter",2,origin,aim,20,Color.YELLOW,80,10,0,2.6)
 g._update_projectiles(0.4)
 check("flame" in g.projectiles[0].get("ammo_elements",[]) and g.projectiles[0].kind == "butter","An actual butter arc crossing a torch becomes flaming butter even in a long frame")
 dispose(g)

func _run():
 test_all_native_patterns()
 test_composed_ammunition()
 test_cannon_and_merge()
 test_lost_target()
 test_payload_inheritance_and_passives()
 test_magic_runtime()
 print("Native fusion audit and ammunition: %d failures" % failures)
 quit(1 if failures else 0)
