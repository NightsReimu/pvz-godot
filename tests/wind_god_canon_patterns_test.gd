extends SceneTree
# The Mountain of Faith cards keep their original topology on six lanes.
const Game=preload("res://scripts/game.gd")
const Spells=preload("res://scripts/data/touhou_spell_defs.gd")
const Phase=preload("res://scripts/runtime/touhou_phase_runtime.gd")
var failures:=0
class Probe extends Game:
 func _ready()->void:_build_font();_build_overlay_ui();set_process(false)
 func _save_game()->void:pass
 func _play_sfx(_path:String,_volume_db:float=-12.0,_pitch_scale:float=1.0)->void:pass
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func level(id:String,tier:String)->Dictionary:
 for candidate in Game.Defs.LEVELS:
  if String(candidate.id)==id:return Game.TouhouDifficulty.build_level(candidate,tier)
 return {}
func cast(g:Probe,kind:String,entry:Array,seconds:float)->Dictionary:
 var b:Dictionary=g._find_alive_enemy_boss(kind)
 if b.is_empty():
  g._spawn_zombie_at(kind,2,g._boss_anchor_x(kind),true);b=g.zombies.back()
 var dm:RefCounted=g._ensure_touhou_danmaku()
 if b.has("touhou_owner"):dm.clear_owner(int(b.touhou_owner))
 b.touhou_cast_remaining=0.0;b.touhou_invulnerable=false
 var e:Dictionary=b.touhou_encounter;e.phases=[[entry]];e.index=0;e.attack=0;e.completed=0;e.complete=false;e.depleted=false;Phase._set_bounds(b);b.health=e.ceiling
 g._trigger_boss_skill(b)
 var seen:={"bullets":[],"beams":[],"peak":0}
 for step in range(int(seconds/.05)):
  dm.update(.05)
  seen.peak=maxi(seen.peak,dm.bullets.size())
  for shot in dm.bullets:
   if not seen.bullets.has(shot):seen.bullets.append(shot)
  for beam in dm.beams:
   if not seen.beams.has(beam):seen.beams.append(beam)
 return seen
func entry_for(kind:String,lv:Dictionary,pattern:String)->Array:
 for phase in Spells.phases_for(kind,lv):
  for entry in phase:
   if String(entry[2])==pattern:return entry
 if kind=="hina_boss":return Spells.Hina.road_card(lv)
 return []
func run()->void:
 for tier in ["easy","normal","hard","lunatic"]:
  var r:int=["easy","normal","hard","lunatic"].find(tier)
  # Stage 1: Shizuha's lagging turret, Falling Frenzy, Minoriko's lasers.
  var lv:=level("4-19",tier);var g:=Probe.new();g.size=Vector2(1600,900);root.add_child(g);g._begin_level(-1,[],lv);g.battle_intro_timer=0
  var harvest:=entry_for("minoriko_boss",lv,"aki_grain_promise" if r>=2 else "aki_otoshi_harvester")
  var seen:Dictionary=cast(g,"minoriko_boss",harvest,2.4)
  check(seen.beams.filter(func(beam):return String(beam.get("wg_style",""))=="harvest").size()>=1,"Harvester/Promise fires warned harvest lasers: "+tier)
  check(seen.beams.all(func(beam):return float(beam.delay)>=1.0),"Every harvest laser keeps its warning line")
  check(seen.bullets.any(func(shot):return shot.has("gravity") and shot.shape=="aki_grain"),"Rice falls between the lasers")
  if r==3:check(seen.beams.any(func(beam):return String(beam.get("wg_style",""))=="crimson"),"Lunatic adds approaching red column lasers")
  var sky:=entry_for("minoriko_boss",lv,"aki_maidens_heart" if r>=2 else "aki_autumn_sky")
  seen=cast(g,"minoriko_boss",sky,2.4)
  var turns:Array=seen.bullets.map(func(shot):return signf(Vector2(shot.velocity).y))
  check(turns.has(1.0) and turns.has(-1.0),"Autumn Sky streams cross upward and downward lanes")
  if r>=2:check(seen.bullets.any(func(shot):return shot.shape=="aki_persimmon"),"Maiden's Heart adds stray medium orbs to its long rows")
  g.free();await process_frame
  # Stage 2: Hina's winders, amulet clumps and biorhythm.
  lv=level("4-20",tier);g=Probe.new();g.size=Vector2(1600,900);root.add_child(g);g._begin_level(-1,[],lv);g.battle_intro_timer=0
  seen=cast(g,"hina_boss",entry_for("hina_boss",lv,"hina_bell_fire" if r>=2 else "hina_misfortune_wheel"),1.2)
  check(seen.bullets.any(func(shot):return shot.shape==("hina_fire" if r>=2 else "hina_needle")),"Wheel uses needles on E/N and fire on H/L")
  var board:=Rect2(g.BOARD_ORIGIN,g.board_size)
  seen=cast(g,"hina_boss",entry_for("hina_boss",lv,"hina_damaged_amulet" if r>=2 else "hina_broken_amulet"),1.8)
  check(seen.bullets.any(func(shot):return Vector2(shot.velocity).y>0) and seen.bullets.any(func(shot):return Vector2(shot.velocity).y<0),"Amulet clumps enter from both corners and cross")
  check(seen.bullets.all(func(shot):return board.grow(g.CELL_SIZE.x).has_point(Vector2(shot.position))),"Amulet clumps travel into the lawn, not off its edge")
  if r>=2:check(seen.bullets.any(func(shot):return bool(shot.get("morphed",false))),"Damaged amulets crack into rice")
  if r>=2:
   lv["mid_boss_kind"]="hina_boss"
   seen=cast(g,"hina_boss",Spells.Hina.road_card(lv),1.2)
   check(seen.bullets.any(func(shot):return shot.has("speed_wave")),"Biorhythm pulses its bullets' speed")
  g.free();await process_frame
  # Stage 3: Nitori's crossing lasers and tidal bore.
  lv=level("4-21",tier);g=Probe.new();g.size=Vector2(1600,900);root.add_child(g);g._begin_level(-1,[],lv);g.grid[2][2]=g._create_plant("repeater",2,2);g.battle_intro_timer=0
  if r<3:
   seen=cast(g,"nitori_boss",entry_for("nitori_boss",lv,"nitori_extend_arm" if r==2 else "nitori_spook_cucumber"),1.6)
   check(seen.beams.filter(func(beam):return String(beam.get("wg_style",""))=="water").size()>=2,"Cucumber/Arm lasers cross from both arms")
  seen=cast(g,"nitori_boss",entry_for("nitori_boss",lv,["nitori_pororoca","nitori_pororoca","nitori_flash_flood","nitori_great_waterfall"][r]),2.0)
  check(seen.bullets.filter(func(shot):return shot.shape=="nitori_light").size()>=8,"Pororoca-family fronts are made of light bullets")
  g.free();await process_frame
  # Stage 4: Aya's crossroads lattice and leaf veils.
  lv=level("4-22",tier);g=Probe.new();g.size=Vector2(1600,900);root.add_child(g);g._begin_level(-1,[],lv);g.battle_intro_timer=0
  seen=cast(g,"aya_boss",entry_for("aya_boss",lv,"aya_saruta_cross" if r>=2 else "aya_crossroads"),0.5)
  var held:Array=seen.bullets.filter(func(shot):return shot.has("thaw_at") and float(shot.freeze_at)==0.0)
  check(held.size()>=15 and held.any(func(shot):return float(shot.thaw_at)>1.8) and held.any(func(shot):return float(shot.thaw_at)<1.4),"Crossroads lattice holds, then drops at different moments")
  if r<2:
   seen=cast(g,"aya_boss",entry_for("aya_boss",lv,"aya_leaf_veiling"),0.1)
   var leaves:int=seen.bullets.filter(func(shot):return shot.shape=="tengu_leaf").size()
   check(leaves>=(36 if r==0 else 52) and leaves<=(44 if r==0 else 60),"Leaf Veiling is two ~%d-way rings (%d)"%[20 if r==0 else 28,leaves])
  g.free();await process_frame
  # Stage 5: Sanae's lasers, ritual walls and divine wind.
  lv=level("4-23",tier);g=Probe.new();g.size=Vector2(1600,900);root.add_child(g);g._begin_level(-1,[],lv);g.battle_intro_timer=0
  seen=cast(g,"sanae_boss",entry_for("sanae_boss",lv,"sanae_guest_stars"),0.2)
  check(seen.beams.size()>=2,"Guest Stars fires lasers from both sides")
  check(seen.beams.any(func(beam):return bool(beam.get("wg_bounce",false)))==(r>=2),"Only H/L lasers reflect off the lawn edges")
  seen=cast(g,"sanae_boss",entry_for("sanae_boss",lv,"sanae_divine_wind"),0.1)
  var ring:int=seen.bullets.filter(func(shot):return shot.shape=="sanae_orb").size()
  check(ring>=30 and ring<=52,"Divine Wind keeps a ~34-way ring (%d)"%ring)
  check(seen.bullets.filter(func(shot):return shot.shape=="sanae_ofuda").size()>=15,"and a ~16-way aimed fan")
  seen=cast(g,"sanae_boss",entry_for("sanae_boss",lv,"sanae_prepare"),2.2)
  check(seen.bullets.any(func(shot):return shot.has("thaw_at") and Color(shot.color).r>Color(shot.color).b),"Red ritual stars hold then scatter")
  check(seen.bullets.any(func(shot):return Color(shot.color).b>Color(shot.color).r and shot.shape=="sanae_star"),"Blue wall advances")
  g._ensure_sanae_runtime().reset();g.free();await process_frame
 # PvZ adaptation: a nut-type plant takes a Wind God laser and stops it.
 var lv:=level("4-19","normal");var g:=Probe.new();g.size=Vector2(1600,900);root.add_child(g);g._begin_level(-1,[],lv);g.battle_intro_timer=0
 g._spawn_zombie_at("minoriko_boss",2,g._boss_anchor_x("minoriko_boss"),true);var b:Dictionary=g.zombies.back()
 for col in [2,5,7]:g.grid[3][col]=g._create_plant("wallnut" if col==5 else "repeater",3,col)
 var hp:Array=[2,5,7].map(func(col):return float(g.grid[3][col].health))
 var dm:RefCounted=g._ensure_touhou_danmaku();b["touhou_owner"]=77
 var session:={"owner":77,"kind":"minoriko_boss","phase":0,"card":{},"wave":0}
 g.WindGodFX.lane_beam(dm,session,3,g._boss_anchor_x("minoriko_boss"),"harvest",0.2,8.0,22.0,0.5)
 for step in range(16):dm._tick_beams(.05,{77:b})
 check(float(g.grid[3][7].health)<hp[2] and float(g.grid[3][5].health)<hp[1],"Laser damages plants up to and including the first nut")
 check(is_equal_approx(float(g.grid[3][2].health),hp[0]),"The wall-nut shelters the plant behind it from the laser")
 g.free();await process_frame
 print("Wind God canonical topology: ",failures," failures");quit(1 if failures else 0)
