extends RefCounted
const Game=preload("res://scripts/game.gd")
const STAGES:=["4-19","4-20","4-21","4-22","4-23","4-24"]
const TIERS:=["easy","normal","hard","lunatic"]
const SOURCE_PATHS := ["scripts/game.gd","scripts/game_defs.gd","scripts/data/touhou_difficulty_defs.gd","scripts/data/touhou_spell_defs.gd","scripts/runtime/touhou_phase_runtime.gd","scripts/runtime/plant_fusion_runtime.gd","scripts/runtime/fusion_native_runtime.gd","scripts/data/fusion_plant_defs.gd","scripts/tools/wind_god_fusion_route.gd","tests/wind_god_fusion_route_test.gd","tests/sanae_fusion_route_test.gd","tests/sanae_durable_fusion_route_test.gd","scripts/data/level_defs_sanae.gd","scripts/data/sanae_spell_defs.gd","scripts/runtime/sanae_boss_runtime.gd","scripts/runtime/sanae_danmaku.gd","scripts/ui/sanae_shrine_scene.gd"]
var tree:SceneTree
func _init(owner:SceneTree)->void:tree=owner
var results:Array=[]
var input_failures:Array=[]
var sanae_durable_strategy:=false
var graft_actions:Array=[]

class RouteGame extends Game:
	var loss_reason:=""
	var breach:Dictionary={}
	var terrain_seed_actions:Array=[]
	var plant_damage:=0.0
	var boss_damage:=0.0
	var spawn_log:Array=[]
	var spawn_indices:Dictionary={}
	var cast_log:Array=[]
	var support_calls:=0
	var support_context:=false
	var finale_seen:=false
	var collected_sun:=0
	var cleansing_log:Array=[]
	var fusion_deaths:Array=[]
	var death_seen:Dictionary={}
	var boss_exits:Dictionary={}
	func _trace_plant(p:Dictionary)->String:
		# Native plants have no numeric UID. This observer key uses immutable
		# birth time/cell/recipe; it never writes identity into combat state.
		return "%.8f:%d:%d:%s"%[float(p.spawn_time),int(p.row),int(p.col),String(p.get("fusion_kind",p.kind))]
	func _ready()->void:
		_build_font();_build_overlay_ui();set_process(false)
	func _save_game()->void:pass
	func _update_autosave(_delta:float)->void:pass
	func _play_bgm(_path:String)->void:pass
	func _prewarm_level_boss_assets()->void:pass
	func _apply_display_mode()->void:pass
	func _notification(what:int)->void:
		if what==NOTIFICATION_RESIZED:_refresh_battle_layout()
	func _lose_level(reason:String="")->void:
		loss_reason=reason;super._lose_level(reason)
	func _check_zombie_home_entry(z:Dictionary)->bool:
		var answer:bool=super._check_zombie_home_entry(z)
		if not answer and battle_state==BATTLE_LOST:breach={"time":level_time,"kind":z.kind,"row":z.row,"health":z.health,"x":z.x}
		return answer
	func _apply_zombie_damage(z:Dictionary,damage:float,flash:float=.12,slow:float=0.0,ignore_shield:bool=false,pierce:bool=false,from_x:float=INF)->Dictionary:
		var before:float=maxf(0.0,float(z.health));var isboss:bool=_is_boss_zombie(z)
		var result:Dictionary=super._apply_zombie_damage(z,damage,flash,slow,ignore_shield,pierce,from_x)
		if isboss:boss_damage+=maxf(0.0,before-maxf(0.0,float(result.health)))
		return result
	func _damage_plant_cell(row:int,col:int,amount:float,extra:float=0.0,scaled:bool=false)->bool:
		var p=_targetable_plant_at(row,col);var before:float=0.0
		if p!=null:before=maxf(0,float(p.health))+maxf(0,float(p.get("armor_health",0)))
		var result:bool=super._damage_plant_cell(row,col,amount,extra,scaled)
		if p!=null:plant_damage+=maxf(0,before-maxf(0,float(p.health))-maxf(0,float(p.get("armor_health",0))))
		return result
	func _spawn_zombie(kind:String,row_override:int=-1,reserve_progress:bool=false,final_preview:bool=false)->void:
		var before:int=zombies.size()
		super._spawn_zombie(kind,row_override,reserve_progress,final_preview)
		for index in range(before,zombies.size()):
			var z:Dictionary=zombies[index]
			var boss:bool=_is_boss_zombie(z)
			if boss and not bool(z.get("touhou_final_preview",false)):finale_seen=true
			var entry:={"time":level_time,"uid":z.uid,"kind":z.kind,"fusion_kind":z.get("fusion_kind",""),"row":z.row,"boss":boss,"preview":bool(z.get("touhou_final_preview",false)),"during_finale":finale_seen,"support_call":support_context,"native_health":z.health,"native_max_health":z.max_health}
			if spawn_indices.has(int(z.uid)):
				var slot:int=spawn_indices[int(z.uid)]
				entry.support_call=bool(entry.support_call) or bool(spawn_log[slot].support_call)
				entry.during_finale=bool(entry.during_finale) or bool(spawn_log[slot].during_finale)
				spawn_log[slot]=entry
			else:
				spawn_indices[int(z.uid)]=spawn_log.size()
				spawn_log.append(entry)
	func _spawn_new_touhou_finale_support(kind:String,phase:int)->void:
		support_calls+=1
		var previous:bool=support_context
		support_context=true
		super._spawn_new_touhou_finale_support(kind,phase)
		support_context=previous
	func _trigger_boss_skill(z:Dictionary)->Dictionary:
		var result:Dictionary=super._trigger_boss_skill(z)
		var card:Dictionary=result.get("touhou_card",{})
		cast_log.append({"time":level_time,"uid":result.uid,"kind":result.kind,"role":"road" if bool(result.get("touhou_final_preview",false)) or bool(result.get("touhou_road_boss",false)) else "finale","phase":int(result.get("touhou_encounter",{}).get("index",0))+1,"card_id":card.get("id",""),"pattern":card.get("pattern",""),"origin":card.get("origin",""),"health":result.health})
		return result
	func _execute_ultimate(plant:Dictionary,kind:String,row:int,col:int,profile:Dictionary)->void:
		var fields_before:int=sanae_runtime.fields.size() if sanae_runtime!=null else 0
		var frogs_before:=0
		for p in grid[row]:
			if p!=null and p.has("sanae_frog_owner"):frogs_before+=1
		super._execute_ultimate(plant,kind,row,col,profile)
		var frogs_after:=0
		for p in grid[row]:
			if p!=null and p.has("sanae_frog_owner"):frogs_after+=1
		if sanae_runtime!=null:cleansing_log.append({"time":level_time,"row":row,"col":col,"fusion_kind":plant.get("fusion_kind",""),"fields_removed":fields_before-sanae_runtime.fields.size(),"frog_marks_removed":frogs_before-frogs_after})
	func _update_suns(delta:float)->void:
		var before:int=sun_points
		super._update_suns(delta)
		collected_sun+=maxi(0,sun_points-before)
	func _remove_dead_plants()->void:
		var dying:Array=[]
		for layer in [grid,support_grid]:
			for row in range(layer.size()):
				for col in range(layer[row].size()):
					var p=layer[row][col]
					if p!=null and p.has("fusion_kind") and float(p.health)<=0:dying.append({"plant":p,"row":row,"col":col,"observer_id":_trace_plant(p)})
		super._remove_dead_plants()
		for entry in dying:
			if float(entry.plant.health)>0 or death_seen.has(entry.observer_id):continue
			death_seen[entry.observer_id]=true
			fusion_deaths.append({"time":level_time,"observer_id":entry.observer_id,"fusion_kind":entry.plant.fusion_kind,"row":entry.row,"col":entry.col})
	func _cleanup_dead_zombies()->void:
		var candidates:Array=zombies.filter(func(z):return _is_boss_zombie(z))
		super._cleanup_dead_zombies()
		for z in candidates:
			if zombies.any(func(alive):return int(alive.uid)==int(z.uid)):continue
			var role:String="road" if bool(z.get("touhou_final_preview",false)) or bool(z.get("touhou_road_boss",false)) else "finale"
			var encounter:Dictionary=z.get("touhou_encounter",{})
			boss_exits[role+":"+str(z.uid)]={"exit_time":level_time,"health":z.health,"complete":bool(encounter.get("complete",false)),"phase":int(encounter.get("index",0))+1,"phase_count":encounter.get("phases",[]).size(),"source":"Actual native cleanup removal, after super guard/cleanup"}

func count_cards(g:Control)->int:return g.active_cards.filter(func(v):return v!="").size()
func stage(id:String)->Dictionary:
	for level in Game.Defs.LEVELS:
		if String(level.id)==id:return level.duplicate(true)
	return {}
func normalize_tier(choice:String)->String:
	var key:String=choice.to_lower()
	return String({"e":"easy","n":"normal","h":"hard","l":"lunatic"}.get(key,key))
func source_manifest()->Dictionary:
	var hashes:Dictionary={}
	for path in SOURCE_PATHS:
		if FileAccess.file_exists("res://"+path):hashes[path]=FileAccess.get_sha256("res://"+path)
	return {"sha256_at_process_start":hashes,"engine":Engine.get_version_info(),"loaded_wind_damage":Game.TouhouDifficulty.WIND_GOD_DAMAGE,"loaded_sanae_source":Game.TouhouDifficulty.outgoing_damage_multiplier("sanae_boss"),"loaded_formal_incoming":Game.TouhouPhaseRuntime.SPELL_DAMAGE_FACTOR,"policy":"fusion-first-native-v180+sanae-observer","sanae_manual_strategy":"Native preceding-campaign collection: sunflower/repeater/wallnut/torchwood/cherry/cactus/mirror/plantern/pumpkin/tallnut, with paid sun-producing hybrids prioritised early. No later-world gourd/melon/umbrella assumed unlocked.","note":"Normal catalogue stats, no scripted charge, starting sun or phase/event/damage changes. Hashes sampled before simulation; loaded constants recorded independently."}
func start(id:String,choice:String,seed:int)->RouteGame:
	var g:=RouteGame.new();g.size=Vector2(1600,900);tree.root.add_child(g);g.rng.seed=seed
	var tier:String=normalize_tier(choice)
	var level:Dictionary=Game.TouhouDifficulty.build_level(stage(id),tier)
	var cards:Array=[]
	if tier=="lunatic":
		# A selected later campaign stage assumes its preceding campaign levels
		# have been completed. This unlocks the genuine collection, without stars,
		# RPG bonuses, free currency, or preplanted combat crops.
		g.completed_levels.resize(Game.Defs.LEVELS.size());g.completed_levels.fill(false)
		var index:int=g._find_level_index_by_id(id)
		for earlier in range(maxi(0,index)):g.completed_levels[earlier]=true
		var pool:Array=g._resolved_selection_pool_for_level(level)
		var priority:Array=["sunflower","repeater","wallnut","healing_gourd","melon_pult","torchwood","umbrella_leaf","cherry_bomb","plantern","lily_pad" if id=="4-22" else "jalapeno"]
		if id=="4-19":priority=["sunflower","repeater","wallnut","healing_gourd","melon_pult","torchwood","umbrella_leaf","cherry_bomb","cactus","blover"]
		if id=="4-23":priority=["sunflower","repeater","wallnut","torchwood","cherry_bomb","cactus","mirror_reed","plantern","pumpkin","tallnut"]
		if id=="4-24":priority=["sunflower","repeater","wallnut","torchwood","umbrella_leaf","cherry_bomb","melon_pult","healing_gourd","tallnut","jalapeno"]
		for kind in priority:
			if pool.has(kind) and cards.size()<Game.MAX_SEED_SLOTS:cards.append(kind)
		for kind in pool:
			if cards.size()>=mini(pool.size(),Game.MAX_SEED_SLOTS):break
			if not cards.has(kind):cards.append(kind)
	g._begin_level(-1,cards,level);g.hide()
	return g
func audit_combat_grid(g:Control)->Array:
	var errors:Array=[]
	for layer in [g.grid,g.support_grid]:
		for row in layer:
			for p in row:
				if p==null or String(p.kind)=="lily_pad":continue
				if not p.has("fusion_kind"):errors.append("Ordinary combat crop")
				else:
					var d:Dictionary=Game.Defs.PLANTS[String(p.fusion_kind)]
					if p.stats!=d:errors.append("Altered fusion catalogue stats")
					var base:String=d.fusion_base
					if not is_equal_approx(float(p.enhance_damage_mult),g._get_enhance_multiplier(base)) or not is_equal_approx(float(p.enhance_attack_speed_mult),g._get_enhance_attack_speed_multiplier(base)):errors.append("Altered fusion offensive enhancement")
					var native_health:float=float(d.health)*float(g._enhanced_plant_stats(base).health)/float(Game.Defs.PLANTS[base].health)
					if not is_equal_approx(float(p.max_health),native_health):errors.append("Altered fusion maximum health")
	return errors
func release(g:Control)->void:
	g._stop_bgm()
	if g.music_player!=null:g.music_player.stream=null
	for player in g.sfx_players:player.stop();player.stream=null
	g.save_dirty=false
	await tree.create_timer(.2).timeout
	g.free()
	await tree.create_timer(.1).timeout
	await tree.process_frame
func row_stats(g:Control,row:int)->Dictionary:
	var stats:={"shooters":0,"guards":0,"heal":0,"reveal":0,"umbrella":0,"reflect":0,"pressure":0.0}
	for p in g.grid[row]:
		if p==null:continue
		var d:Dictionary=Game.Defs.PLANTS[String(p.get("fusion_kind",p.kind))]
		var traits:Array=d.get("fusion_traits",[])
		if d.get("fusion_channels",[]).any(func(c):return float(c.get("damage",0))>0):stats.shooters+=1
		if float(p.max_health)>1500:stats.guards+=1
		for key in ["heal","reveal","umbrella","reflect"]:
			if traits.has(key):stats[key]+=1
	for z in g.zombies:
		if int(z.row)!=row or float(z.health)<=0 or not g._is_enemy_zombie(z):continue
		var advance:float=clampf((g.BOARD_ORIGIN.x+g.board_size.x-float(z.x))/g.board_size.x,0,1)
		stats.pressure+=1.0+advance*5.0+minf(3.0,float(z.health)/1500.0)
	return stats
func legal_body(g:Control,id:String,cell:Vector2i)->bool:
	var base:String=Game.Defs.PLANTS[id].fusion_base
	var terrain:String=g._cell_terrain_kind(cell.x,cell.y)
	if base in ["sea_shroom","tangle_kelp"] and terrain!="water":return false
	if base=="spikeweed" and terrain=="water":return false
	if terrain=="water" and base not in ["sea_shroom","tangle_kelp"] and g.support_grid[cell.x][cell.y]==null:return false
	return true
func choose_pair(g:Control)->Dictionary:
	var held:Array=g.active_cards.duplicate();var best:Dictionary={};var score:float=-INF
	var stats:Array=[]
	for row in g.active_rows:stats.append(row_stats(g,int(row)))
	var sanae_manual:bool=String(g.current_level.id)=="4-23" and not g._is_conveyor_level()
	var durable:bool=String(g.current_level.id)=="4-23" and sanae_durable_strategy
	var economy_bodies:=0
	if sanae_manual:
		for lane in g.grid:
			for p in lane:
				if p!=null and Game.Defs.PLANTS[String(p.get("fusion_kind",p.kind))].get("fusion_traits",[]).has("sun"):economy_bodies+=1
	for i in range(held.size()):
		if held[i]=="" or held[i]=="lily_pad":continue
		for j in range(i+1 if g._is_conveyor_level() else i,held.size()):
			if held[j]=="" or held[j]=="lily_pad":continue
			if not g._is_conveyor_level():
				if float(g.card_cooldowns.get(held[i],0))>.01 or float(g.card_cooldowns.get(held[j],0))>.01:continue
				if g.sun_points<g._endless_cost_for_kind(held[i])+g._endless_cost_for_kind(held[j]):continue
			var id:String=g._ensure_plant_fusion().Fusion.result(String(held[i]),String(held[j]))
			if id.is_empty():continue
			var d:Dictionary=Game.Defs.PLANTS[id]
			# Some canonical seed upgrades return a standalone native species.
			# This diagnostic deliberately selects the catalogue's tagged hybrids.
			if not bool(d.get("fusion_only",false)):continue
			var traits:Array=d.fusion_traits
			var dps:float=0.0
			for c in d.fusion_channels:dps+=float(c.get("damage",0))*int(c.get("shots",1))/maxf(.5,float(c.get("interval",2)))
			var shoots:bool=dps>0.0;var guard:bool=float(d.health)>1500
			for row in g.active_rows:
				var lane:Dictionary=stats[int(row)]
				var value:float=24.0/(1.0+float(lane.shooters))+float(lane.pressure)*3.0
				value+=minf(100,dps)*.12+minf(9000,float(d.health))/700.0
				if shoots:value+=14.0 if int(lane.shooters)==0 else 4.0
				elif int(lane.shooters)==0:value-=22.0
				if guard:value+=9.0 if int(lane.guards)==0 else 1.0
				if durable and guard:
					value+=90.0+(40.0 if shoots else 0.0)+(30.0 if traits.has("heal") else 0.0)+(25.0 if traits.has("umbrella") else 0.0)
				# The new manual route cannot buy a second army without genuine
				# sun-producing hybrids. This is a declared Sanae-only placement
				# heuristic; it changes no resource, cooldown or catalogue stat.
				if sanae_manual and traits.has("sun") and economy_bodies<6:value+=[75.0,50.0,30.0,20.0,12.0,8.0][economy_bodies]
				for key in ["heal","reveal","umbrella","reflect"]:
					if traits.has(key):value+=8.0 if int(lane[key])==0 else 1.0
				var columns:Array=[2,1,3,4,0,5,6,7,8] if guard else [1,2,3,0,4,5,6,7,8]
				if durable and guard:columns=[3,2,4,1,5,0,6,7,8]
				for offset in range(columns.size()):
					var cell:=Vector2i(int(row),int(columns[offset]))
					if g.grid[cell.x][cell.y]!=null or not legal_body(g,id,cell):continue
					var candidate:float=value-float(offset)*.45
					if candidate>score:score=candidate;best={"a":held[i],"b":held[j],"cell":cell,"result":id}
					break
	return best
func graft_protection(g:Control,material_counts:Dictionary)->void:
	if not sanae_durable_strategy or String(g.current_level.id)!="4-23":return
	var bodies:=0
	for lane in g.grid:
		for p in lane:
			if p!=null and p.has("fusion_kind"):bodies+=1
	if bodies<6 and count_cards(g)<8:return
	for attempt in range(4):
		var best:Dictionary={};var score:float=-INF
		var f:RefCounted=g._ensure_plant_fusion()
		for seed in g.active_cards:
			if seed not in ["wallnut","tallnut","healing_gourd","umbrella_leaf","mirror_reed"]:continue
			if not g._is_conveyor_level() and (g.sun_points<g._endless_cost_for_kind(seed) or float(g.card_cooldowns.get(seed,0))>.01):continue
			for row in g.active_rows:
				for col in range(g.COLS):
					var host=g.grid[int(row)][col]
					if host==null or not host.has("fusion_kind") or float(host.health)/maxf(1,float(host.max_health))<.6:continue
					var recipe:Dictionary=f.candidate(seed,int(row),col)
					if recipe.is_empty() or f.placement_error(seed,int(row),col,recipe)!="":continue
					var old:Dictionary=Game.Defs.PLANTS[String(host.fusion_kind)]
					var d:Dictionary=Game.Defs.PLANTS[String(recipe.id)]
					if not bool(d.get("fusion_only",false)):continue
					var wanted:bool=(seed in ["wallnut","tallnut"] and float(host.max_health)<5000 and float(d.health)>float(host.max_health)+1000) or (seed=="healing_gourd" and float(host.max_health)>=1500 and not old.fusion_traits.has("heal")) or (seed=="umbrella_leaf" and float(host.max_health)>=1500 and not old.fusion_traits.has("umbrella")) or (seed=="mirror_reed" and float(host.max_health)>=1500 and not old.fusion_traits.has("reflect"))
					if not wanted:continue
					var value:float=(80.0 if seed in ["wallnut","tallnut"] else 45.0)+col*.75+float(row_stats(g,int(row)).pressure)*2.0
					if old.fusion_channels.any(func(c):return float(c.get("damage",0))>0):value+=25.0
					if value>score:score=value;best={"seed":seed,"cell":Vector2i(int(row),col),"recipe":recipe,"host":host}
		if best.is_empty():return
		var before:int=g.active_cards.count(best.seed);var sun_before:int=g.sun_points
		var charge_before:float=best.host.ultimate_charge
		var ratio_before:float=float(best.host.health)/float(best.host.max_health)
		var health_before:float=best.host.max_health
		f.reset();g.selected_tool="";g._try_select_tool(best.seed);g._handle_board_click(best.cell)
		var p=g.grid[best.cell.x][best.cell.y]
		if p==null or not p.has("fusion_kind") or String(p.fusion_kind)!=String(best.recipe.id):input_failures.append("Paid graft did not produce its native recipe");return
		var belt_spent:int=before-g.active_cards.count(best.seed) if g._is_conveyor_level() else 0
		var sun_spent:int=sun_before-g.sun_points
		if g._is_conveyor_level() and belt_spent!=1:input_failures.append("Graft did not consume exactly1 actual seed")
		if not g._is_conveyor_level() and (sun_spent!=g._endless_cost_for_kind(best.seed) or float(g.card_cooldowns.get(best.seed,0))<=.01):input_failures.append("Unpaid graft/cooldown")
		if not is_equal_approx(float(p.ultimate_charge),charge_before):input_failures.append("Graft changed earned charge")
		material_counts[best.seed]=int(material_counts.get(best.seed,0))+1
		graft_actions.append({"time":g.level_time,"seed":best.seed,"row":best.cell.x,"col":best.cell.y,"fusion_kind":p.fusion_kind,"belt_spent":belt_spent,"sun_spent":sun_spent,"charge_before":charge_before,"charge_after":p.ultimate_charge,"health_ratio_before":ratio_before,"health_ratio_after":float(p.health)/float(p.max_health),"max_health_before":health_before,"native_max_health_after":p.max_health,"cooldown_after":g.card_cooldowns.get(best.seed,0)})
func place(g:Control,audit:Array,material_counts:Dictionary)->void:
	graft_protection(g,material_counts)
	if g.active_cards.has("lily_pad") and (g._is_conveyor_level() or (g.sun_points>=g._endless_cost_for_kind("lily_pad") and float(g.card_cooldowns.get("lily_pad",0))<=.01)):
		for row in g.active_rows:
			var done:=false
			for col in [3,4,0,5,6,7,8,1,2]:
				if g._placement_error("lily_pad",int(row),col)!="":continue
				var before:int=g.active_cards.count("lily_pad");var sun_before:int=g.sun_points
				g.selected_tool="";g._try_select_tool("lily_pad");g._handle_board_click(Vector2i(int(row),col))
				if g._is_conveyor_level():
					if g.active_cards.count("lily_pad")!=before-1:input_failures.append("Lily not consumed exactly1")
				elif sun_before-g.sun_points!=g._endless_cost_for_kind("lily_pad") or float(g.card_cooldowns.get("lily_pad",0))<=.01:input_failures.append("Unpaid lily/cooldown")
				g.terrain_seed_actions.append({"time":g.level_time,"kind":"lily_pad","cell":[int(row),col],"sun_spent":sun_before-g.sun_points,"belt_spent":before-g.active_cards.count("lily_pad") if g._is_conveyor_level() else 0,"cooldown":g.card_cooldowns.get("lily_pad",0)})
				done=true;break
			if done:break
	for attempt in range(5):
		var plan:Dictionary=choose_pair(g)
		if plan.is_empty():return
		var f:RefCounted=g._ensure_plant_fusion();f.reset();g.selected_tool="fusion"
		var needed:Dictionary={}
		for material in [plan.a,plan.b]:needed[material]=int(needed.get(material,0))+1
		for material in needed:
			if (g._is_conveyor_level() and g.active_cards.count(material)<int(needed[material])) or not g.active_cards.has(material):input_failures.append("Missing held ingredient");return
		var before:Dictionary={}
		for material in needed:before[material]=g.active_cards.count(material)
		g._try_select_tool(String(plan.a));g._try_select_tool(String(plan.b))
		if f.prepared_result.is_empty() or f.prepared_error(plan.cell.x,plan.cell.y)!="":f.reset();g.selected_tool="";return
		var total:int=count_cards(g);var sun_before:int=g.sun_points;g._handle_board_click(plan.cell)
		var p=g.grid[plan.cell.x][plan.cell.y]
		if p==null or not p.has("fusion_kind"):input_failures.append("Prepared action did not create native fusion");return
		if g._is_conveyor_level():
			if total-count_cards(g)!=2:input_failures.append("Prepared action did not spend exactly2")
		else:
			if sun_before-g.sun_points!=g._endless_cost_for_kind(plan.a)+g._endless_cost_for_kind(plan.b):input_failures.append("Unpaid fusion pair")
		for material in needed:
			if g._is_conveyor_level():
				if int(before[material])-g.active_cards.count(material)!=int(needed[material]):input_failures.append("Ingredient count mismatch")
			elif float(g.card_cooldowns.get(material,0))<=.01:input_failures.append("Uncharged manual cooldown")
			material_counts[material]=int(material_counts.get(material,0))+int(needed[material])
		audit.append({"time":g.level_time,"materials":[plan.a,plan.b],"cell":[plan.cell.x,plan.cell.y],"fusion_kind":p.fusion_kind,"native_health":p.max_health,"native_armor":p.get("armor_health",0),"native_initial_charge":p.ultimate_charge,"observer_id":g._trace_plant(p),"held_before":before,"held_after":count_cards(g),"sun_spent":sun_before-g.sun_points,"cooldowns":g.card_cooldowns.duplicate(true) if not g._is_conveyor_level() else {}})
func run_case(stage_id:String,choice:String,seed:int,cap:float=1200.0)->Dictionary:
	input_failures.clear()
	graft_actions.clear()
	var tier:String=normalize_tier(choice)
	if not STAGES.has(stage_id) or not TIERS.has(tier):return {"stage":stage_id,"tier":tier,"seed":seed,"input_failures":["Unsupported stage/tier"],"battle_state":"invalid"}
	var manifest:Dictionary=source_manifest()
	manifest["durable_strategy"]=sanae_durable_strategy
	var g:RouteGame=start(stage_id,tier,seed)
	var start_snapshot:={"combat_bodies":0,"fusion_bodies":0,"sun":g.sun_points,"held_cards":g.active_cards.duplicate(),"level_time":g.level_time,"enemy_count":g.zombies.size(),"water_rows":g.water_rows.duplicate(),"manual_bank":g.active_cards.duplicate() if not g._is_conveyor_level() else [],"control_size":[g.size.x,g.size.y],"cell_size":[g.CELL_SIZE.x,g.CELL_SIZE.y],"board_origin":[g.BOARD_ORIGIN.x,g.BOARD_ORIGIN.y]}
	for layer in [g.grid,g.support_grid]:
		for lane in layer:
			for p in lane:
				if p!=null and String(p.kind)!="lily_pad":start_snapshot.combat_bodies+=1
				if p!=null and p.has("fusion_kind"):start_snapshot.fusion_bodies+=1
	var ending:String=String(g.current_level.events.back().kind)
	var road:String=String(g.current_level.get("mid_boss_kind",""))
	var tracked:Dictionary={}
	var audit:Array=[];var material_counts:Dictionary={};var timeline:Array=[];var boss_states:Dictionary={}
	var boss_actors:Dictionary={};var actor_refs:Dictionary={};var weather_log:Array=[];var weather_seconds:Dictionary={};var last_weather:=""
	var charge_actions:Array=[];var frog_refs:Dictionary={};var frog_events:Array=[];var frog_peak:=0;var enemy_peak:=0
	var ultimates:=0;var support_ultimates:=0;var peak_fusions:=0;var next_sample:=0.0
	for frame in range(ceili(maxf(.05,cap)/.05)):
		if frame%30==0:await tree.process_frame
		if frame%5==0:
			place(g,audit,material_counts)
			input_failures.append_array(audit_combat_grid(g))
			for row in g.active_rows:
				for col in range(g.COLS):
					var candidate:Dictionary=g._ready_click_ultimate_candidate_at(int(row),col)
					if candidate.is_empty():continue
					var charge_before:float=float(candidate.get("plant",{}).get("ultimate_charge",0))
					var cooldown_before:float=float(candidate.get("plant",{}).get("ultimate_cooldown",0))
					if g._try_activate_ultimate(int(row),col):
						ultimates+=1
						charge_actions.append({"time":g.level_time,"row":int(row),"col":col,"kind":candidate.kind,"fusion_kind":candidate.get("plant",{}).get("fusion_kind",""),"charge_before":charge_before,"cooldown_before":cooldown_before})
						if charge_before<.999:input_failures.append("Ultimate was not earned by native charge")
						if candidate.kind=="lily_pad":support_ultimates+=1
		g._process(.05)
		enemy_peak=maxi(enemy_peak,g._active_zombie_count())
		if g.ancient_expansion!=null:
			var weather:String=g.ancient_expansion.current()
			weather_seconds[weather]=float(weather_seconds.get(weather,0))+.05
			if weather!=last_weather:weather_log.append({"time":g.level_time,"weather":weather,"override_owner":g.ancient_expansion.override_owner});last_weather=weather
		var alive:=0;var nonfusion:=0
		for row in g.grid:
			for p in row:
				if p==null:continue
				if p.has("fusion_kind"):alive+=1
				else:nonfusion+=1
				if p.has("fusion_kind") and p.has("sanae_frog_owner") and not frog_refs.has(g._trace_plant(p)):
					frog_refs[g._trace_plant(p)]={"plant":p,"active":false}
		var active_frogs:=0
		for uid in frog_refs:
			var entry:Dictionary=frog_refs[uid]
			var active:bool=entry.plant.has("sanae_frog_owner") and float(entry.plant.get("sanae_frog_until",0))>g.level_time and float(entry.plant.health)>0
			if active:active_frogs+=1
			if active!=bool(entry.active):frog_events.append({"time":g.level_time,"uid":uid,"active":active,"health":entry.plant.health});entry.active=active
		frog_peak=maxi(frog_peak,active_frogs)
		if nonfusion>0:input_failures.append("Unexpected ordinary combat plant")
		peak_fusions=maxi(peak_fusions,alive)
		for z in g.zombies:
			if String(z.kind) not in [road,ending]:continue
			var key:String=z.kind
			var role:String="road" if bool(z.get("touhou_final_preview",false)) or bool(z.get("touhou_road_boss",false)) else "finale"
			var actor_key:String=role+":"+str(z.uid)
			actor_refs[actor_key]=z
			if not boss_actors.has(actor_key):boss_actors[actor_key]={"role":role,"kind":z.kind,"uid":z.uid,"first_seen":g.level_time,"initial_health":z.health,"max_health":z.max_health,"phase_count":z.touhou_encounter.phases.size()}
			boss_actors[actor_key].health=z.health;boss_actors[actor_key].phase=int(z.touhou_encounter.get("index",0))+1;boss_actors[actor_key].complete=z.touhou_encounter.get("complete",false)
			tracked[key]=z
			if not boss_states.has(key):boss_states[key]={"first_seen":g.level_time}
			boss_states[key].health=z.health;boss_states[key].phase=int(z.touhou_encounter.get("index",0))+1;boss_states[key].phase_count=z.touhou_encounter.phases.size();boss_states[key].complete=z.touhou_encounter.get("complete",false)
		if g.level_time>=next_sample:
			timeline.append({"time":g.level_time,"alive_fusions":alive,"placed":audit.size(),"held":count_cards(g),"sun":g.sun_points,"zombies":g.zombies.size(),"bosses":boss_states.duplicate(true)})
			if stage_id in ["4-23","4-24"] and int(next_sample)%120==0:print("SANAE_ROUTE_PROGRESS " if stage_id=="4-23" else "KANAKO_ROUTE_PROGRESS ",JSON.stringify({"tier":tier,"seed":seed,"time":g.level_time,"alive_fusions":alive,"sun":g.sun_points,"bosses":boss_actors.duplicate(true),"losses":g.fusion_deaths.size(),"support_spawns":g.spawn_log.filter(func(s):return s.support_call).size()}))
			next_sample+=10.0
		if g.battle_state!=g.BATTLE_PLAYING:break
	input_failures.append_array(audit_combat_grid(g))
	for key in tracked:
		var z:Dictionary=tracked[key]
		boss_states[key].health=z.health;boss_states[key].complete=z.touhou_encounter.get("complete",false)
	for key in actor_refs:
		var z:Dictionary=actor_refs[key]
		boss_actors[key].health=z.health;boss_actors[key].complete=z.touhou_encounter.get("complete",false)
		if g.boss_exits.has(key):boss_actors[key].merge(g.boss_exits[key],true)
	var sanae_end_state:={"fields":g.sanae_runtime.fields.size() if g.sanae_runtime!=null else 0,"living_frog_summons":g.zombies.filter(func(z):return String(z.kind)=="sanae_frog" and float(z.health)>0).size(),"frog_marks_on_plants":0}
	for layer in [g.grid,g.support_grid]:
		for lane in layer:
			for p in lane:
				if p!=null and p.has("sanae_frog_owner"):sanae_end_state.frog_marks_on_plants+=1
	var report:={"stage":stage_id,"tier":tier,"seed":seed,"loaded_wind_damage":Game.TouhouDifficulty.WIND_GOD_DAMAGE,"battle_state":g.battle_state,"loss_reason":g.loss_reason,"breach":g.breach,"seconds":g.level_time,"fusion_placements":audit.size(),"peak_live_fusions":peak_fusions,"ultimates":ultimates,"lily_pad_ultimates":support_ultimates,"boss_states":boss_states,"native_boss_health_removed":g.boss_damage,"native_plant_damage":g.plant_damage,"materials_spent":material_counts,"placements":audit,"timeline":timeline,"input_failures":input_failures.duplicate(),"manual_bank":g.active_cards.duplicate() if not g._is_conveyor_level() else [],"actor_state_note":"Last actual retained actor reference; battle_state is authoritative after win/removal."}
	report["terrain_seed_actions"]=g.terrain_seed_actions.duplicate(true)
	report["sanae_end_state"]=sanae_end_state
	report["native_boss_exits"]=g.boss_exits.duplicate(true)
	report["strategy"]="sanae-native-durable-grafts" if sanae_durable_strategy and stage_id=="4-23" else "standard-native-fusion-first"
	report["graft_actions"]=graft_actions.duplicate(true)
	report["graft_count"]=graft_actions.size()
	report["manual_graft_sun_spent"]=graft_actions.reduce(func(total,entry):return total+int(entry.sun_spent),0)
	report.merge({"source_manifest":manifest,"start_snapshot":start_snapshot,"outcome":"won" if g.battle_state==g.BATTLE_WON else ("lost" if g.battle_state==g.BATTLE_LOST else "unfinished_simulation_cap"),"diagnostic_cap_seconds":cap,"boss_actors":boss_actors,"cast_log":g.cast_log.duplicate(true),"fusion_deaths":g.fusion_deaths.duplicate(true),"fusion_loss_count":g.fusion_deaths.size(),"lane_losses":g.fusion_deaths.reduce(func(counts,entry):counts[str(entry.row)]=int(counts.get(str(entry.row),0))+1;return counts,{}),"mowers_spent":g.mowers.filter(func(m):return not bool(m.armed)).size(),"peak_active_enemies":enemy_peak,"actual_finale_support_calls":g.support_calls,"actual_finale_support_spawns":g.spawn_log.filter(func(s):return s.support_call).size(),"actual_finale_other_spawns":g.spawn_log.filter(func(s):return s.during_finale and not s.boss).size(),"summoned_frogs":g.spawn_log.filter(func(s):return s.kind=="sanae_frog").size(),"spawn_log":g.spawn_log.duplicate(true),"weather_log":weather_log,"weather_seconds":weather_seconds,"frog_events":frog_events,"peak_frogified_fusions":frog_peak,"ultimate_cleansing":g.cleansing_log.duplicate(true),"earned_charge_actions":charge_actions,"collected_sun":g.collected_sun,"sun_remaining":g.sun_points,"manual_sun_spent":audit.reduce(func(total,entry):return total+int(entry.sun_spent),0)})
	print("Fusion-first native route: ",JSON.stringify(compact(report)))
	await release(g)
	return report
func compact(report:Dictionary)->Dictionary:
	var result:Dictionary=report.duplicate(false)
	result.erase("placements");result.erase("timeline")
	for key in ["spawn_log","cast_log","fusion_deaths","frog_events","ultimate_cleansing","earned_charge_actions","graft_actions"]:result.erase(key)
	return result
