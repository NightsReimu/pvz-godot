extends SceneTree
const Game=preload("res://scripts/game.gd")
const Level=preload("res://scripts/data/level_defs_sanae.gd")
const Spells=preload("res://scripts/data/sanae_spell_defs.gd")
const Phase=preload("res://scripts/runtime/touhou_phase_runtime.gd")
var failures:=0
class Probe extends Game:
 func _ready()->void:_build_font();_build_overlay_ui();set_process(false)
 func _save_game()->void:pass
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 for r in range(4):
  var tier:String=["easy","normal","hard","lunatic"][r];var level:Dictionary=Game.TouhouDifficulty.build_level(Level.LEVEL,tier)
  var g:=Probe.new();g.size=Vector2(1600,900);root.add_child(g);g._begin_level(-1,["sunflower","repeater","wallnut","healing_gourd","melon_pult","umbrella_leaf","torchwood","cherry_bomb","plantern","cactus"] if r==3 else [],level);g.battle_intro_timer=0
  check(g._ensure_ancient_expansion().active() and g.water_rows.is_empty(),"Actual shrine is dry and weather-enabled")
  g.level_time=104.9;g._update_frozen_branch_flow();check(not g.frozen_branch_midboss_spawned,"Road cannot arrive before authored105s")
  g.level_time=105.1;g._update_frozen_branch_flow();var road:Dictionary=g._find_alive_enemy_boss("sanae_boss")
  check(road.touhou_road_boss and road.touhou_encounter.phases.size()==2,"Incomplete road has nonspell then its actual TH10 ritual")
  check(String(road.touhou_encounter.phases[1][0][0])=="th10-%03d"%(58+r),"Original road IDs058–061 match difficulty")
  check(g.current_bgm_path.ends_with("4-23-stage.mp3") or g.pending_bgm_path.ends_with("4-23-stage.mp3"),"Road never selects ending music")
  road.touhou_encounter.index=1;road.touhou_encounter.attack=0;road.touhou_encounter.completed=0;Phase._set_bounds(road);road.health=road.touhou_encounter.ceiling
  g._trigger_boss_skill(road);var road_dm:RefCounted=g._ensure_touhou_danmaku()
  for step in range(40):road_dm.update(.05)
  check(road_dm.bullets.any(func(shot):return int(shot.get("sanae_generation",0))==1),"Road parent pentagrams actually generate smaller daughter stars before scatter")
  check(int(Game.TouhouSpellDefs.card_for(road,level).ritual_stars)==(6 if r==0 else 10),"Easy/Normal ritual reproduces two stars becoming6/10 daughter outlines")
  var road_hp:float=road.max_health;road.health=0;road.touhou_encounter.complete=true;g._cleanup_dead_zombies();g._update_frozen_branch_flow()
  g._spawn_zombie_at("sanae_boss",2,g._boss_anchor_x("sanae_boss"),true);var b:Dictionary=g._find_alive_enemy_boss("sanae_boss")
  check(not b.touhou_road_boss and b.max_health>road_hp*10 and b.health==b.max_health,"Fresh finale health is genuinely stronger than incomplete self-road")
  check(b.touhou_encounter.phases.size()==7+r,"Sanae has7/8/9/10 native phase bars")
  check(g.current_bgm_path.ends_with("4-23-ending.mp3") or g.pending_bgm_path.ends_with("4-23-ending.mp3"),"Only full finale changes BGM")
  var entries:Array=Spells.cards("sanae_boss",level)
  check(entries[-2][2]=="sanae_prepare" and entries[-1][2]=="sanae_divine_wind","Canonical preparation and final miracle remain consecutive")
  for pi in range(b.touhou_encounter.phases.size()):
   var e:Dictionary=b.touhou_encounter;e.index=pi;e.attack=e.phases[pi].size()-1;e.completed=e.attack;e.depleted=false;e.complete=false;Phase._set_bounds(b);b.health=e.ceiling
   g._trigger_boss_skill(b);var dm:RefCounted=g._ensure_touhou_danmaku();var card:Dictionary=Game.TouhouSpellDefs.card_for(b,level)
   check(not card.is_empty() and card.origin in ["canon","original"],"A native formal card was actually selected")
   check(Phase.spell_damage_factor(b)==.125,"Every formal card uses87.5percent incoming resistance")
   var rng_before:int=g.rng.state
   for step in range(40):dm.update(.05)
   check(dm.bullets.size()>=35 and dm.bullets.size()<=dm.MAX_BULLETS,"Every actual spell emits dense bounded bullets")
   check(g.rng.state==rng_before,"Deterministic spell emission does not steal combat RNG")
   check(dm.bullets.all(func(shot):return shot.damage>40 and shot.kind=="sanae_boss"),"Actual emitter bullets inherit current scoped damage")
   if card.pattern=="sanae_sea_opening":check(dm.beams.size()>=2 and g.water_rows.is_empty(),"Split-sea beams bound a canal without changing dry terrain")
   if card.pattern=="sanae_guest_stars":check(dm.bullets.any(func(shot):return shot.shape=="sanae_star"),"Actual delayed guest-star emitters burst into stars")
   if card.pattern=="sanae_prepare":check(dm.bullets.any(func(shot):return shot.has("thaw_at")),"Preparation includes warned fixed star outlines before scatter")
   g._ensure_sanae_runtime().clear_owner(int(b.uid));dm.clear_owner(int(b.touhou_owner));b.touhou_cast_remaining=0;b.touhou_invulnerable=false
  var count:int=g._active_zombie_count();g._spawn_hover_boss_reinforcement("sanae_boss",3,b)
  check(g._active_zombie_count()>=count+2,"Finale keeps multirow real reinforcements")
  check(Level.ENEMIES.all(func(kind):return Game.Defs.ZOMBIES.has(kind) and not bool(Game.Defs.ZOMBIES[kind].get("boss",false))),"Broad roster contains actual ordinary/fusion enemies, no other Boss")
  g._ensure_sanae_runtime().reset();g._stop_bgm();g.music_player.stream=null
  for player in g.sfx_players:player.stop();player.stream=null
  g.free();await process_frame
 print("Sanae four-tier native phases/BGM/dense emission: ",failures," failures");quit(1 if failures else 0)
