extends "res://tests/plant_fusion_test.gd"

func profile(id: String, source: String) -> Dictionary:
 for channel in Defs.PLANTS[id].get("fusion_channels",[]):
  if channel.source == source: return channel
 return {}

func test_explosive_channels():
 var g = make_game()
 var id: String = Fusion.result("cherry_bomb","peashooter")
 var pea := profile(id,"peashooter"); var bomb := profile(id,"cherry_bomb")
 check(not pea.is_empty() and not bomb.is_empty(),"Cherry/pea must have independent sustained and burst channels")
 if not pea.is_empty() and not bomb.is_empty():
  check(float(pea.damage) <= 24 and float(bomb.interval) >= 24,"Burst damage cannot leak into rapid pea fire")
  check(bomb.blast_shape == "circle" and float(bomb.radius) >= 150,"Cherry retains its area explosion")
  var doom := profile(Fusion.result("doom_shroom","peashooter"),"doom_shroom")
  check(float(doom.radius) > float(bomb.radius) and float(doom.interval) > float(bomb.interval),"Doom has a larger explosion with a longer charge")
 var p: Dictionary = g._create_plant(id,2,2); g.grid[2][2] = p
 g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+300)
 g.zombies[0].health = 10000
 g._update_plants(1)
 check(not g.projectiles.is_empty(),"Pea still fires while explosive chamber charges")
 for shot in g.projectiles: check(float(shot.damage) <= 24,"First rapid bullet must not inherit 1800 damage")
 check(is_equal_approx(float(g.zombies[0].health),10000),"No free explosion immediately after grafting")
 if not bomb.is_empty():
  g.projectiles.clear(); p.fusion_channel_timers.cherry_bomb = 0
  g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+350); g.zombies[1].health = 10000
  g._spawn_zombie_at("normal",0,g._cell_center(0,2).x+300); g.zombies[2].health = 10000
  g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+320); g.zombies[3] = g._hypnotize_zombie(g.zombies[3])
  var friendly_hp: float = g.zombies[3].health
  g._update_plants(0.01)
  for n in range(160): g._update_projectiles(0.02)
  check(g.zombies[0].health < 10000 and g.zombies[1].health < 10000,"Charged cherry shell damages the cluster around its landing point")
  check(g.zombies[2].health == 10000 and g.zombies[3].health == friendly_hp,"Explosion respects radius and friendly zombies")
  var cooldown: float = p.fusion_channel_timers.cherry_bomb
  var next: Dictionary = g._ensure_plant_fusion().combined(Fusion.result(id,"sunflower"),p)
  check(float(next.get("fusion_channel_timers",{}).get("cherry_bomb",0)) >= cooldown,"Recursive grafting cannot refill a burst chamber")
  g._ensure_plant_fusion().ultimate(p,2,2)
  var charged := 0
  for shot in g.projectiles:
   if shot.get("fusion_channel_source","") == "cherry_bomb": charged += 1
  check(charged == 1,"Ultimate fires one charged explosion, without copying it into every pea bullet")
 dispose(g)

func test_lobbers_and_heavy_cadence():
 var g = make_game()
 for source in ["cabbage_pult","kernel_pult","melon_pult","skylight_melon","obsidian_artichoke","sulfur_pod","pressure_bamboo","fumarole_melon","caldera_lotus"]:
  var id: String = Fusion.result(source,"peashooter")
  var lob := profile(id,source)
  check(not lob.is_empty() and lob.get("style","") == "lobber","Original catapult retains its lobbed channel: "+source)
  g.grid[2][2] = g._create_plant(id,2,2)
  g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+250)
  if not lob.is_empty(): g.grid[2][2].fusion_channel_timers[source] = 0
  g._update_plants(1)
  var found := false
  for shot in g.projectiles:
   if shot.get("fusion_channel_source","") == source and shot.has("arc_target") and float(shot.get("arc_height",0)) > 0: found = true
  check(found,"Actual arc projectile, rather than a renamed straight shot: "+source)
  g.projectiles.clear(); g.zombies.clear()
 var cannon := profile(Fusion.result("corn_cannon","peashooter"),"corn_cannon")
 check(not cannon.is_empty() and float(cannon.get("interval",0)) >= 20,"Heavy cannon keeps its twenty-second loading cycle")
 dispose(g)

func test_mirror_and_passives():
 var g = make_game()
 var id: String = Fusion.result(Fusion.result("mirror_reed","peashooter"),"cabbage_pult")
 var p: Dictionary = g._create_plant(id,2,3); g.grid[2][3] = p
 g._spawn_zombie_at("shouyue",2,g._cell_center(2,7).x)
 var hp: float = g.zombies[0].health
 var reflected: Dictionary = g._try_reflect_targeted_hostile_shot(g.zombies[0],Vector2i(2,1),40,Vector2(g.zombies[0].x,g._row_center_y(2)))
 check(bool(reflected.reflected) and reflected.zombie.health < hp,"Mixed mirror reed intercepts real hostile sniper shots")
 var bullet := {"position":g._cell_center(2,3),"velocity":Vector2(-120,25),"damage":20.0}
 check(g._bounce_boss_danmaku(bullet,Vector2i(2,3)) and Vector2(bullet.velocity).x > 0,"Mixed mirror reed reverses real boss danmaku")
 g._update_plants(1)
 check(not g.projectiles.is_empty(),"Reflection and pea fire coexist")
 check("reflection" in Defs.PLANTS[id].fusion_skills,"Mirror component inherits an explicit reflection ultimate")
 var revived: Dictionary = g._create_plant(Fusion.result("phoenix_tree","garlic"),2,4)
 revived.health = 0
 check(g._ensure_plant_runtime().try_passive_revival(revived,2,4),"Phoenix revival survives a different passive base")
 dispose(g)

func test_additional_identity_and_balance():
 var g = make_game()
 for id in Fusion.DEFINITIONS:
  for channel in Defs.PLANTS[id].fusion_channels:
   if channel.style == "burst": continue
   var original: Dictionary = Native.PLANTS[channel.source]
   var base_damage: float = float(original.get("damage",original.get("contact_damage",original.get("zone_damage",0))))
   check(float(channel.damage) <= maxf(60,base_damage*3),"Disposable damage never enters a sustained weapon: "+id)
   if channel.source == "corn_cannon": check(float(channel.interval) >= 20,"Every recursive cannon preserves heavy reload")
 var id: String = Fusion.result("pressure_bamboo","peashooter")
 var p: Dictionary = g._create_plant(id,2,2); g.grid[2][2] = p
 for n in range(4): g._update_plants(1.8)
 check(int(p.pressure_ammo) == 3,"Fused pressure bamboo stores up to three lobbed rounds during idle time")
 g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+280)
 p.fusion_channel_timers.pressure_bamboo = 0
 g._update_plants(0.1)
 var lobbed := 0
 for shot in g.projectiles:
  if shot.get("fusion_channel_source","") == "pressure_bamboo" and shot.has("arc_target"): lobbed += 1
 check(lobbed == 3 and int(p.pressure_ammo) == 0,"Stored pressure rounds discharge as a real staggered lob volley")
 g.grid[2][2] = g._create_plant(Fusion.result("cherry_bomb","peashooter"),2,2)
 p = g.grid[2][2]; p.fusion_haste_timer = 10
 g._update_plants(1)
 check(is_equal_approx(float(p.fusion_channel_timers.cherry_bomb),31),"Haste cannot accelerate a destructive burst cooldown")
 var sulfur_id: String = Fusion.result("sulfur_pod","sunflower")
 var sulfur: Dictionary = g._create_plant(sulfur_id,2,2)
 var z: Dictionary = g._ensure_plant_fusion().projectile_hit(g.zombies[0],{"fusion_source":sulfur_id,"fusion_channel_source":"sulfur_pod","fusion_mechanics":Native.PLANTS.sulfur_pod,"fusion_traits":Defs.PLANTS[sulfur_id].fusion_traits})
 check(float(z.get("sulfur_brittle_until",0)) > g.level_time,"Sulfur ammunition retains its real vulnerability effect")
 g.grid[2][1] = g._create_plant("cherry_bomb",2,1)
 g.grid[2][2] = g._create_plant(Fusion.result("mirror_shroom","peashooter"),2,2)
 g._update_plants(0.1)
 check(float(g.grid[2][2].fusion_copy_damage) < 180,"Mirror mushrooms cannot copy a disposable explosion into beam damage")
 g.grid[2][3] = g._create_plant(Fusion.result("mirror_reed","peashooter"),2,3)
 var mirror: Dictionary = g.grid[2][3]
 g._ensure_touhou_danmaku().bullets.clear()
 g.touhou_danmaku.bullets.append({"position":g._cell_center(1,6),"velocity":Vector2(-130,25),"damage":20.0})
 g._ensure_plant_fusion().ultimate(mirror,2,3)
 check(bool(g.touhou_danmaku.bullets[0].get("reflected",false)) and Vector2(g.touhou_danmaku.bullets[0].velocity).x > 0,"Fusion mirror ultimate actually reverses live danmaku")
 dispose(g)

func test_native_control_and_split_ammo():
 var g = make_game()
 var p: Dictionary = g._create_plant(Fusion.result("ice_queen","sunflower"),2,2); g.grid[2][2] = p
 g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+90)
 g._update_plants(1)
 check(float(g.zombies[0].frozen_timer) >= 2 and float(g.zombies[0].health) < float(g.zombies[0].max_health),"Fused ice queen retains its actual close-range freezing pulse")
 g.zombies.clear(); g.grid[2][2] = g._create_plant(Fusion.result("frost_cypress","sunflower"),2,2)
 g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+90)
 for n in range(31): g._update_plants(0.1)
 check(float(g.zombies[0].frozen_timer) >= 2.5,"Fused frost cypress keeps its three-second exposure freeze")
 var sakura: String = Fusion.result("sakura_shooter","torchwood")
 var shot := {"kind":"sakura_petal","damage":22.0,"row":2,"position":g._cell_center(2,2),"fusion_source":sakura,"fusion_channel_source":"sakura_shooter","fusion_traits":["fire"],"fusion_mechanics":Native.PLANTS.sakura_shooter,"fire":true}
 g._ensure_projectile_runtime().spawn_sakura_split_projectiles(shot,g._cell_center(2,2))
 check(g.projectiles.size() == 2 and g.projectiles[0].get("fusion_source","") == sakura and bool(g.projectiles[0].fire),"Sakura child petals retain the fused weapon and element")
 g.projectiles.clear(); g.zombies.clear()
 var glow: String = Fusion.result("glowvine","sunflower")
 p = g._create_plant(glow,2,2); g.grid[2][2] = p
 g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+170)
 g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+200)
 g.zombies[0].health = 10000; g.zombies[1].health = 10000
 p.fusion_channel_timers.glowvine = 0
 g._update_plants(0.1)
 check(not g.projectiles.is_empty() and g.projectiles[0].kind == "glow_seed","Fused glowvine fires its native burst seed")
 for n in range(60): g._update_projectiles(0.02)
 var glow_effect := false
 for effect in g.effects:
  if effect.get("shape","") == "glow_burst": glow_effect = true
 check(glow_effect and g.zombies[1].health < 10000,"Glowvine's real secondary blast reaches a nearby enemy")
 dispose(g)

func _run():
 test_explosive_channels(); test_lobbers_and_heavy_cadence(); test_mirror_and_passives(); test_additional_identity_and_balance(); test_native_control_and_split_ammo()
 print("Fusion trait combat: %d failure(s)" % failures)
 quit(1 if failures else 0)
