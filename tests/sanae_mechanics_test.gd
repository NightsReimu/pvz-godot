extends SceneTree
const Game=preload("res://scripts/game.gd")
const Fusion=preload("res://scripts/data/fusion_plant_defs.gd")
const Sanae=preload("res://scripts/data/level_defs_sanae.gd")
var failures:=0
class Probe extends Game:
 func _ready()->void:_build_font();_build_overlay_ui();set_process(false)
 func _save_game()->void:pass
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g:=Probe.new();g.size=Vector2(1600,900);root.add_child(g)
 check(g.has_method("_ensure_sanae_runtime"),"NativeGame needs the Sanae mechanic hook")
 if not g.has_method("_ensure_sanae_runtime"):g.free();quit(1);return
 g._begin_level(-1,[],Game.TouhouDifficulty.build_level(Sanae.LEVEL,"normal"));g.battle_intro_timer=0
 g._spawn_zombie_at("sanae_boss",2,g._boss_anchor_x("sanae_boss"),true)
 var boss:Dictionary=g._find_alive_enemy_boss("sanae_boss");var rt:RefCounted=g._ensure_sanae_runtime()
 check(not boss.is_empty() and boss.has("touhou_encounter"),"Sanae uses native segmented phases")
 var id:String=Fusion.result("repeater","wallnut");var p:Dictionary=g._create_plant(id,2,3);g.grid[2][3]=p
 var before:Dictionary=p.duplicate(true)
 rt.queue_field(int(boss.uid),Vector2i(2,3),"frog",4.5)
 rt.update(1.3);check(not p.has("sanae_frog_until"),"Frog curse has a full1.4s warning")
 rt.update(.11);check(p.has("sanae_frog_until") and g._plant_charm_blocks_actions(p),"Warning ends in an actual temporary action block")
 check(is_same(p,g.grid[2][3]) and p.fusion_kind==id and p.stats==before.stats and p.health==before.health and p.ultimate_charge==before.ultimate_charge,"Frog form preserves native hybrid identity/health/charge")
 rt.cleanse_row(2);check(not p.has("sanae_frog_until") and not g._plant_charm_blocks_actions(p),"Row ultimate cleanse restores the original plant")
 g.grid[2][4]=g._create_plant(Fusion.result("wallnut","umbrella_leaf"),2,4)
 rt.queue_field(int(boss.uid),Vector2i(2,3),"frog");rt.update(1.5)
 check(not p.has("sanae_frog_until"),"Native umbrella component shelters adjacent fusion plants")
 rt.clear_owner(int(boss.uid));rt.queue_field(int(boss.uid),Vector2i(4,6),"summon",1.0);rt.update(1.5)
 var frogs:Array=g.zombies.filter(func(z):return z.kind=="sanae_frog" and z.health>0)
 check(frogs.size()==1 and frogs[0].sanae_owner==boss.uid,"Warned summon creates a real targetable owned frog zombie")
 rt.clear_owner(int(boss.uid));check(float(frogs[0].health)==0.0 and rt.fields.is_empty(),"Owner/phase cleanup retires frogs and fields")
 g._stop_bgm();for player in g.sfx_players:player.stop();player.stream=null
 g.free();await process_frame
 print("Sanae native fusion/frog mechanic contract: ",failures," failures");quit(1 if failures else 0)
