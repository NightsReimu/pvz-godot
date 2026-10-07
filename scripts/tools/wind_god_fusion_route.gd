extends RefCounted
const Game=preload("res://scripts/game.gd")
const STAGES:=["4-19","4-20","4-21","4-22"]
const TIERS:=["easy","normal","hard","lunatic"]
var tree:SceneTree
func _init(owner:SceneTree)->void:tree=owner
var results:Array=[]
var input_failures:Array=[]

class RouteGame extends Game:
	var loss_reason:=""
	var breach:Dictionary={}
	var terrain_seed_actions:Array=[]
	var plant_damage:=0.0
	var boss_damage:=0.0
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

func count_cards(g:Control)->int:return g.active_cards.filter(func(v):return v!="").size()
func stage(id:String)->Dictionary:
	for level in Game.Defs.LEVELS:
		if String(level.id)==id:return level.duplicate(true)
	return {}
func normalize_tier(choice:String)->String:
	var key:String=choice.to_lower()
	return String({"e":"easy","n":"normal","h":"hard","l":"lunatic"}.get(key,key))
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
				for key in ["heal","reveal","umbrella","reflect"]:
					if traits.has(key):value+=8.0 if int(lane[key])==0 else 1.0
				var columns:Array=[2,1,3,4,0,5,6,7,8] if guard else [1,2,3,0,4,5,6,7,8]
				for offset in range(columns.size()):
					var cell:=Vector2i(int(row),int(columns[offset]))
					if g.grid[cell.x][cell.y]!=null or not legal_body(g,id,cell):continue
					var candidate:float=value-float(offset)*.45
					if candidate>score:score=candidate;best={"a":held[i],"b":held[j],"cell":cell,"result":id}
					break
	return best
func place(g:Control,audit:Array,material_counts:Dictionary)->void:
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
		audit.append({"time":g.level_time,"materials":[plan.a,plan.b],"cell":[plan.cell.x,plan.cell.y],"fusion_kind":p.fusion_kind,"native_health":p.max_health,"held_before":before,"held_after":count_cards(g)})
func run_case(stage_id:String,choice:String,seed:int,cap:float=1200.0)->Dictionary:
	input_failures.clear()
	var tier:String=normalize_tier(choice)
	if not STAGES.has(stage_id) or not TIERS.has(tier):return {"stage":stage_id,"tier":tier,"seed":seed,"input_failures":["Unsupported stage/tier"],"battle_state":"invalid"}
	var g:RouteGame=start(stage_id,tier,seed)
	var ending:String=String(g.current_level.events.back().kind)
	var road:String=String(g.current_level.get("mid_boss_kind",""))
	var tracked:Dictionary={}
	var audit:Array=[];var material_counts:Dictionary={};var timeline:Array=[];var boss_states:Dictionary={}
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
					if g._try_activate_ultimate(int(row),col):
						ultimates+=1
						if candidate.kind=="lily_pad":support_ultimates+=1
		g._process(.05)
		var alive:=0;var nonfusion:=0
		for row in g.grid:
			for p in row:
				if p==null:continue
				if p.has("fusion_kind"):alive+=1
				else:nonfusion+=1
		if nonfusion>0:input_failures.append("Unexpected ordinary combat plant")
		peak_fusions=maxi(peak_fusions,alive)
		for z in g.zombies:
			if String(z.kind) not in [road,ending]:continue
			var key:String=z.kind
			tracked[key]=z
			if not boss_states.has(key):boss_states[key]={"first_seen":g.level_time}
			boss_states[key].health=z.health;boss_states[key].phase=int(z.touhou_encounter.get("index",0))+1;boss_states[key].phase_count=z.touhou_encounter.phases.size();boss_states[key].complete=z.touhou_encounter.get("complete",false)
		if g.level_time>=next_sample:
			timeline.append({"time":g.level_time,"alive_fusions":alive,"placed":audit.size(),"held":count_cards(g),"sun":g.sun_points,"zombies":g.zombies.size(),"bosses":boss_states.duplicate(true)})
			next_sample+=10.0
		if g.battle_state!=g.BATTLE_PLAYING:break
	input_failures.append_array(audit_combat_grid(g))
	for key in tracked:
		var z:Dictionary=tracked[key]
		boss_states[key].health=z.health;boss_states[key].complete=z.touhou_encounter.get("complete",false)
	var report:={"stage":stage_id,"tier":tier,"seed":seed,"loaded_wind_damage":Game.TouhouDifficulty.WIND_GOD_DAMAGE,"battle_state":g.battle_state,"loss_reason":g.loss_reason,"breach":g.breach,"seconds":g.level_time,"fusion_placements":audit.size(),"peak_live_fusions":peak_fusions,"ultimates":ultimates,"lily_pad_ultimates":support_ultimates,"boss_states":boss_states,"native_boss_health_removed":g.boss_damage,"native_plant_damage":g.plant_damage,"materials_spent":material_counts,"placements":audit,"timeline":timeline,"input_failures":input_failures.duplicate(),"manual_bank":g.active_cards.duplicate() if not g._is_conveyor_level() else [],"actor_state_note":"Last actual retained actor reference; battle_state is authoritative after win/removal."}
	report["terrain_seed_actions"]=g.terrain_seed_actions.duplicate(true)
	print("Fusion-first native route: ",JSON.stringify(compact(report)))
	await release(g)
	return report
func compact(report:Dictionary)->Dictionary:
	var result:Dictionary=report.duplicate(false)
	result.erase("placements");result.erase("timeline")
	return result
