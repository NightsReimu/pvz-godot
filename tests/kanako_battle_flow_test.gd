extends SceneTree
const Game=preload("res://scripts/game.gd")
const Level=preload("res://scripts/data/level_defs_kanako.gd")
const Spells=preload("res://scripts/data/kanako_spell_defs.gd")
const Phase=preload("res://scripts/runtime/touhou_phase_runtime.gd")
const DAMAGES:=[11.0,12.0,13.0,14.0,15.0,16.0,17.0]
var failures:=0
class Probe extends Game:
 func _ready()->void:_build_font();_build_overlay_ui();set_process(false)
 func _save_game()->void:pass
 func _play_sfx(_path:String,_volume_db:float=-12.0,_pitch_scale:float=1.0)->void:pass
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var canonical_names:Array=[]
 for r in range(4):
  var tier:String=["easy","normal","hard","lunatic"][r];var level:Dictionary=Game.TouhouDifficulty.build_level(Level.LEVEL,tier)
  var g:=Probe.new();g.size=Vector2(1600,900);root.add_child(g);g._begin_level(-1,["sunflower","repeater","wallnut","healing_gourd","melon_pult","umbrella_leaf","torchwood","cherry_bomb","plantern","cactus"] if r==3 else [],level);g.battle_intro_timer=0
  check(g._ensure_ancient_expansion().active() and g.water_rows.is_empty(),"Actual summit is dry and weather-enabled")
  check(not g.frozen_branch_midboss_spawned and String(level.get("mid_boss_kind",""))=="","No road boss interrupts the stage")
  # A few planted cells give the pillar/rope cards real targets.
  for row in range(6):
   for col in [1,3,5]:g.grid[row][col]=g._create_plant("repeater" if col<5 else "wallnut",row,col)
  g._spawn_zombie_at("kanako_boss",2,g._boss_anchor_x("kanako_boss"),true);var b:Dictionary=g._find_alive_enemy_boss("kanako_boss")
  check(not b.is_empty() and not bool(b.touhou_road_boss) and b.health==b.max_health,"Kanako arrives as a fresh full finale")
  check(b.touhou_encounter.phases.size()==8+r,"Kanako has8/9/10/11 native phase bars")
  check(g.current_bgm_path.ends_with("4-24-ending.mp3") or g.pending_bgm_path.ends_with("4-24-ending.mp3"),"Finale switches to the supplied ending music")
  var cards:Array=Spells.cards("kanako_boss",level)
  var canon:Array=cards.filter(func(card):return String(card[0]).begins_with("th10-"))
  check(canon.map(func(card):return String(card[0]))==["th10-%03d"%(78+r),"th10-%03d"%(82+r),"th10-%03d"%(86+r),"th10-%03d"%(90+r),"th10-%03d"%(94+r)],"Original practice IDs078–097 match difficulty")
  canonical_names.append(canon.map(func(card):return String(card[1])))
  check(bool(cards.back()[4].get("last_spell",false)) and String(cards.back()[2]) in ["kanako_mountain_of_faith","kanako_wind_god_virtue"],"Mountain of Faith / Divine Virtues of Wind God stays last")
  check(cards.filter(func(card):return String(card[0]).begins_with("original-")).size()==3+r,"Tier adds 3/4/5/6 original lane cards")
  var phases:Array=b.touhou_encounter.phases
  check(phases.filter(func(p):return p.size()==2 and String(p[0][2]).begins_with("nonspell_kanako")).size()==4,"Four distinct original nonspells precede the first four canonical groups")
  check(phases.back().size()==1 and String(phases.back()[0][0])=="th10-%03d"%(94+r),"The last spell follows Otensui without a nonspell, as in TH10")
  var seen_patterns:={}
  for pi in range(phases.size()):
   for ai in range(phases[pi].size()):
    var e:Dictionary=b.touhou_encounter;e.index=pi;e.attack=ai;e.completed=ai;e.depleted=false;e.complete=false;Phase._set_bounds(b);b.health=e.ceiling
    g._trigger_boss_skill(b);var dm:RefCounted=g._ensure_touhou_danmaku();var card:Dictionary=Game.TouhouSpellDefs.card_for(b,level)
    seen_patterns[String(card.pattern)]=true
    check(Phase.spell_damage_factor(b)==(1.0 if card.origin=="nonspell" else .125),"Formal cards use87.5percent incoming resistance; nonspells do not: "+String(card.pattern))
    var rng_before:int=g.rng.state
    var peak:=0;var peak_beams:=0;var shapes:={}
    for step in range(60):
     dm.update(.05);g._ensure_kanako_runtime().update(.05)
     peak=maxi(peak,dm.bullets.size());peak_beams=maxi(peak_beams,dm.beams.size())
     for shot in dm.bullets:shapes[String(shot.shape)]=true
    check(peak>=30 and peak<=dm.MAX_BULLETS,"Dense bounded emission for %s/%s (peak %d)"%[tier,card.pattern,peak])
    # Only cards that spawn real units (pillars, reinforcements) may use combat RNG.
    if not String(card.pattern) in ["kanako_war_god","kanako_pillar_fall","kanako_faith"]:check(g.rng.state==rng_before,"Deterministic emission does not steal combat RNG: "+String(card.pattern))
    var source_factor:float=g.TouhouDifficulty.boss_damage_multiplier(level)*5.0
    check(dm.bullets.all(func(shot):return shot.kind=="kanako_boss" and DAMAGES.any(func(d):return is_equal_approx(float(shot.damage),d*g.TouhouDifficulty.attack_damage("kanako_boss",level,int(b.boss_phase))))),"Authored bullet damage uses the shared source factor: %s/%s"%[tier,card.pattern])
    check(is_equal_approx(g.TouhouDifficulty.attack_damage("kanako_boss",level,0),source_factor),"Kanako has no extra damage tuning beyond the common Touhou factor")
    match String(card.pattern):
     "kanako_onbashira","kanako_medoteko":check(peak_beams>=2 and dm.beams.all(func(beam):return bool(beam.get("kanako_pillar",false))),"Expanded Onbashira closes pillar lasers from both edges")
     "kanako_porridge","kanako_unremembered","kanako_divining":check(shapes.has("kanako_almond") and shapes.has("kanako_rice"),"Almonds really turn into rice grains")
     "kanako_otensui","kanako_rain_source":check(shapes.has("kanako_light") and shapes.has("kanako_scale"),"Heaven-water light turns into scales")
     "kanako_kuzui","kanako_yamato_torus":check(dm.bullets.any(func(shot):return Vector2(shot.velocity).x>0),"Knives enter from the back edge too")
     "kanako_misayama":check(shapes.has("kanako_big") and shapes.has("kanako_knife"),"Misayama mixes held orbs and knives")
     "kanako_serpent":check(shapes.has("kanako_snake_head") and shapes.has("kanako_snake"),"Serpents slither as chained bodies")
     "kanako_shimenawa":check(g._ensure_kanako_runtime().fields.any(func(f):return f.mode=="rope") or g._ensure_kanako_runtime().action_factor(0,1)<1.0 or shapes.has("kanako_rope"),"Shimenawa binds lanes and braids rope bullets")
     "kanako_mountain_of_faith","kanako_wind_god_virtue":check(shapes.has("kanako_ofuda") and g.ancient_expansion.weather=="wind","Mountain of Faith releases ofuda clusters under the god's wind")
     "kanako_war_god":check(g._ensure_kanako_runtime().fields.any(func(f):return f.mode=="banner"),"War god raises lane banners")
    g._ensure_kanako_runtime().clear_owner(int(b.uid));dm.clear_owner(int(b.touhou_owner));b.touhou_cast_remaining=0;b.touhou_invulnerable=false
  for pattern in ["kanako_pillar_fall","kanako_shimenawa","kanako_weather"]:check(seen_patterns.has(pattern),"Every tier keeps the first three originals: "+pattern)
  var count:int=g._active_zombie_count();g._spawn_hover_boss_reinforcement("kanako_boss",3,b)
  check(g._active_zombie_count()>=count+2,"Finale keeps multirow real reinforcements")
  g._ensure_kanako_runtime().reset();g._stop_bgm();g.music_player.stream=null
  for player in g.sfx_players:player.stop();player.stream=null
  g.free();await process_frame
 check(canonical_names[0]==canonical_names[1] and canonical_names[2][0]=="奇祭「目处梃子乱舞」" and canonical_names[3][1]=="神谷「Divining Crop」" and canonical_names[2][2]=="神秘「葛井之清水」" and canonical_names[3][2]=="神秘「Yamato Torus」","E/N share names while H/L use their own TH10 cards")
 print("Kanako four-tier native phases/BGM/dense emission: ",failures," failures");quit(1 if failures else 0)
