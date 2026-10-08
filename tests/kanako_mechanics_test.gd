extends SceneTree
const Game=preload("res://scripts/game.gd")
const Fusion=preload("res://scripts/data/fusion_plant_defs.gd")
const Kanako=preload("res://scripts/data/level_defs_kanako.gd")
var failures:=0
class Probe extends Game:
 func _ready()->void:_build_font();_build_overlay_ui();set_process(false)
 func _save_game()->void:pass
 # Audio is not under test; headless mixers otherwise keep SFX playbacks alive at exit.
 func _play_sfx(_path:String,_volume_db:float=-12.0,_pitch_scale:float=1.0)->void:pass
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g:=Probe.new();g.size=Vector2(1600,900);root.add_child(g)
 g._begin_level(-1,[],Game.TouhouDifficulty.build_level(Kanako.LEVEL,"normal"));g.battle_intro_timer=0
 check(g.current_bgm_path.ends_with("4-24-stage.mp3") or g.pending_bgm_path.ends_with("4-24-stage.mp3"),"Road plays the supplied stage music from the start")
 g._spawn_zombie_at("kanako_boss",2,g._boss_anchor_x("kanako_boss"),true)
 var boss:Dictionary=g._find_alive_enemy_boss("kanako_boss");var rt:RefCounted=g._ensure_kanako_runtime()
 check(not boss.is_empty() and boss.has("touhou_encounter") and not bool(boss.touhou_road_boss),"Kanako arrives directly as the full finale")
 check(g.current_bgm_path.ends_with("4-24-ending.mp3") or g.pending_bgm_path.ends_with("4-24-ending.mp3"),"Arrival switches to the supplied finale music")
 var owner:int=int(boss.uid)
 # Onbashira drop: full warning, real damage through native plant health.
 var id:String=Fusion.result("repeater","wallnut");var p:Dictionary=g._create_plant(id,2,3);g.grid[2][3]=p
 var hp:float=float(p.health);var charge:float=float(p.get("ultimate_charge",0.0))
 rt.queue_pillar(owner,Vector2i(2,3))
 rt.update(1.4);check(is_equal_approx(float(p.health),hp),"Falling pillar waits for its1.5s warning")
 rt.update(.15);check(float(p.health)<hp and p.fusion_kind==id,"Impact damages the native fusion plant without replacing it")
 # Umbrella shelter stops the trunk.
 g.grid[3][2]=g._create_plant(Fusion.result("wallnut","umbrella_leaf"),3,2)
 var q:Dictionary=g._create_plant("repeater",3,3);g.grid[3][3]=q;var q_hp:float=float(q.health)
 rt.queue_pillar(owner,Vector2i(3,3));rt.update(1.6)
 check(is_equal_approx(float(q.health),q_hp),"Adjacent umbrella leaf shelters a cell from the falling pillar")
 # Staying pillars become real targetable units; felling one returns faith.
 g.grid[1][2]=g._create_plant("repeater",1,2);g.grid[1][2]["ultimate_charge"]=0.2
 rt.queue_pillar(owner,Vector2i(1,8),true);rt.update(1.6)
 var pillars:Array=g.zombies.filter(func(z):return z.kind=="kanako_onbashira" and z.health>0)
 check(pillars.size()==1 and int(pillars[0].kanako_owner)==owner,"Staying pillar spawns an owned onbashira unit")
 if pillars.size()==1:
  pillars[0].health=0.0;g._cleanup_dead_zombies()
  check(is_equal_approx(float(g.grid[1][2].ultimate_charge),0.2+rt.FAITH_CHARGE),"Felling a pillar grants native ultimate charge to its lane")
 rt.queue_pillar(owner,Vector2i(4,8),true);rt.update(1.6)
 var kept:Array=g.zombies.filter(func(z):return z.kind=="kanako_onbashira" and z.health>0)
 g.grid[4][1]=g._create_plant("repeater",4,1);var before_charge:float=float(g.grid[4][1].get("ultimate_charge",0.0))
 rt.clear_owner(owner);g._cleanup_dead_zombies()
 check(kept.size()==1 and float(kept[0].health)==0.0 and is_equal_approx(float(g.grid[4][1].get("ultimate_charge",0.0)),before_charge),"Card cleanup retires pillars without a faith reward")
 # Shimenawa: warned binding, fire burns it, ultimate cleanse removes it.
 var a:Dictionary=g._create_plant("repeater",0,2);g.grid[0][2]=a
 rt.queue_rope(owner,0,1,5,6.0);rt.update(1.2);check(rt.action_factor(0,2)==1.0,"Rope binding waits for its warning")
 rt.update(.2);check(is_equal_approx(rt.action_factor(0,2),rt.ROPE_FACTOR) and rt.action_factor(0,7)==1.0,"Bound cells act slower; cells outside the rope do not")
 g.grid[0][4]=g._create_plant("torchwood",0,4);rt.update(.5);check(rt.action_factor(0,2)<1.0,"Fire takes time to burn through straw")
 rt.update(.6);check(rt.action_factor(0,2)==1.0,"A fire plant inside the rope burns it away")
 rt.queue_rope(owner,5,1,5,6.0);rt.update(1.4);check(rt.action_factor(5,3)<1.0,"Second rope binds")
 rt.cleanse_row(5);check(rt.action_factor(5,3)==1.0,"Row ultimate cleanse unties the rope")
 rt.queue_rope(owner,4,1,5,6.0);rt.update(1.4);g._trigger_jalapeno(4,6)
 check(rt.action_factor(4,3)==1.0,"A jalapeno's lane fire consumes the rope")
 # War god banner: blessed ordinary zombies are faster and resist damage.
 g._spawn_zombie_at("conehead",1,g._cell_center(1,7).x,true);var z:Dictionary=g.zombies.back()
 rt.queue_banner(owner,1,6.0);rt.update(.9)
 check(rt.speed_factor(z)==rt.BLESS_SPEED and rt.damage_factor(z)==rt.BLESS_DAMAGE,"Banner lane zombies receive the war god's blessing")
 check(rt.speed_factor(boss)==1.0,"The blessing never applies to Kanako herself")
 rt.cleanse_row(1);check(rt.speed_factor(z)==1.0,"Row ultimate cleanse dispels the banner")
 # Weather spells drive the real weather runtime with Kanako as owner.
 boss["touhou_cast_duration"]=11.0
 rt.cast(boss,"kanako_otensui");check(g.ancient_expansion.weather=="rain" and int(g.ancient_expansion.override_owner)==owner,"Otensui calls real rain")
 rt.cast(boss,"kanako_weather");check(g.ancient_expansion.weather=="wind","Mountain weather opens with wind")
 g.level_time+=6.0;rt.update(.05);check(g.ancient_expansion.weather=="rain","Then the lake's rain follows")
 rt.clear_owner(owner);check(rt.fields.is_empty() and rt.pending_weather.is_empty(),"Owner cleanup clears every field")
 g._ensure_kanako_runtime().reset();g._stop_bgm();g.music_player.stream=null
 for player in g.sfx_players:player.stop();player.stream=null
 g.free();await process_frame
 print("Kanako native pillar/rope/banner/weather contract: ",failures," failures");quit(1 if failures else 0)
