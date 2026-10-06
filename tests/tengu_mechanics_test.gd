extends "res://scripts/tools/capture_battle_polish.gd"
var failures := 0
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const Phase = preload("res://scripts/runtime/touhou_phase_runtime.gd")
const Scene = preload("res://scripts/ui/tengu_mountain_scene.gd")

func _stage() -> Dictionary:
	for level in GameScript.Defs.LEVELS:
		if String(level.id)=="4-22": return level.duplicate(true)
	return {}

func _game(viewport: Vector2,choice: String="easy") -> Control:
	var g:=PreviewGame.new(); g.size=viewport; g.mobile_runtime_override=1 if viewport.y<600 else 0; root.add_child(g)
	var base: Dictionary=_stage(); base.custom_level=true
	g._begin_level(-1,["repeater","wallnut","plantern","umbrella_leaf","anchor_fern","lily_pad"],g.TouhouDifficulty.build_level(base,choice))
	g.battle_intro_timer=0; g.startup_loading_active=false; g.page_transition_active=false
	g._spawn_zombie_at("aya_boss",2,g._boss_anchor_x("aya_boss"),true)
	return g

func _plant(g: Control, cell: Vector2i, fused: bool=false) -> Dictionary:
	var p: Dictionary=g._create_plant(Fusion.result("wallnut","peashooter") if fused else "wallnut",cell.x,cell.y)
	g.grid[cell.x][cell.y]=p
	return p

func _vitality(p: Dictionary) -> float:
	return maxf(0,float(p.health))+maxf(0,float(p.get("armor_health",0)))

func _select_id(g: Control,b: Dictionary,id: String) -> bool:
	var e: Dictionary=b.touhou_encounter
	for pi in range(e.phases.size()):
		for ai in range(e.phases[pi].size()):
			if String(e.phases[pi][ai][0])==id:
				e.index=pi; e.attack=ai; e.completed=ai; e.complete=false; e.depleted=false; Phase._set_bounds(b); b.health=e.ceiling
				return true
	return false

func _fields(g: Control,b: Dictionary) -> void:
	var rt=g._ensure_tengu_runtime(); var owner: int=int(b.uid)
	for fused in [false,true]:
		var cell:=Vector2i(3,2); var p: Dictionary=_plant(g,cell,fused); var before: float=_vitality(p)
		rt.queue_field(owner,cell,"report",1.4)
		rt.update(1.3)
		check(_vitality(p)==before,"The 1.4-second photo warning cannot hit ordinary/fusion plants early")
		rt.update(0.2)
		var after: float=_vitality(p)
		check(after<before,"The actual photo follow-up reaches ordinary/fusion plant bodies")
		check(absf(before-after-16.0*g.TouhouDifficulty.direct_attack_damage("aya_boss",g.current_level))<0.01,"The real photo hit scales the latest scoped Wind God Boss source exactly once")
		rt.update(2.0)
		check(_vitality(p)==after,"Each marked photograph damages its cell once")
		rt.clear_owner(owner)
		before=_vitality(p); rt.queue_field(owner,cell,"wind",1.2); rt.update(1.1)
		check(is_equal_approx(rt.action_factor(cell.x,cell.y),1.0),"Wind warning leaves native/fusion action clocks unchanged")
		rt.update(0.2)
		check(is_equal_approx(rt.action_factor(cell.x,cell.y),0.8),"Active wind slows real ordinary and fused source cells")
		check(_vitality(p)==before,"Wind's speed effect adds no invisible untelegraphed damage")
		rt.cleanse_row(cell.x)
		check(rt.fields.is_empty() and is_equal_approx(rt.action_factor(cell.x,cell.y),1.0),"Row cleanse removes pending/active wind and photographs")
	for mode in ["cyclone","fence","sword"]:
		var cell:=Vector2i(4,3); var p: Dictionary=_plant(g,cell,true); var before: float=_vitality(p)
		rt.queue_field(owner,cell,mode,1.2); rt.update(1.1)
		check(_vitality(p)==before,mode+": readable warning never damages a real fused wall early")
		rt.update(0.5)
		check(_vitality(p)<before,mode+": the native pressure reaches its actual marked plant")
		rt.clear_owner(owner)
	for n in range(40): rt.queue_field(owner,Vector2i(n%6,(n/6)%9),"wind",1.2)
	check(rt.fields.size()<=12,"Tengu board fields stay bounded under repeated cast scheduling")
	rt.clear_owner(owner)

func _native_clocks(g: Control,b: Dictionary) -> void:
	var rt=g._ensure_tengu_runtime(); var owner: int=int(b.uid); var cell:=Vector2i(0,1)
	for route in ["ordinary","fusion","support"]:
		var observed: Array=[]
		for wind in [false,true]:
			g.grid[0][1]=null; g.support_grid[0][1]=null; rt.clear_owner(owner)
			var p: Dictionary=g._create_plant("peashooter" if route=="ordinary" else Fusion.result("peashooter","wallnut" if route=="fusion" else "holy_flower"),cell.x,cell.y)
			if route=="support": p.attached=true; g.support_grid[0][1]=p
			else: g.grid[0][1]=p
			p.shot_cooldown=1.0
			var state: Dictionary=p
			if p.has("fusion_kind"):
				var native=g._ensure_plant_fusion().NativeRuntime.new(g)
				state=native.state_for(p,"peashooter",cell.x,cell.y); state.shot_cooldown=1.0; p.fusion_channel_timers.peashooter=1.0
			if wind: rt.queue_field(owner,cell,"wind",1.2); rt.update(1.3)
			g._update_plants(0.1); observed.append(1.0-float(state.shot_cooldown))
		check(float(observed[0])>0 and absf(float(observed[1])-float(observed[0])*0.8)<0.0001,"Active wind modifies actual "+route+" source action clocks, including the support loop")
		rt.clear_owner(owner)

func _veil_and_incoming(g: Control,b: Dictionary) -> void:
	var rt=g._ensure_tengu_runtime()
	check(_select_id(g,b,"th10-043"),"Native incoming probe selects an actual canonical Aya card")
	g._trigger_boss_skill(b); var before: float=float(b.health); g._apply_zombie_damage(b,80.0,0,0,true)
	check(absf(before-float(b.health)-10.0)<0.001,"New active Aya formal card keeps .125 incoming resistance even for bypass-shield hits")
	rt.clear_owner(int(b.uid)); g.touhou_danmaku.clear_owner(int(b.touhou_owner))
	check(_select_id(g,b,"th10-047"),"Easy Aya reaches the original leaf-veiling wind card")
	g._trigger_boss_skill(b); rt.update_boss(b,1.1)
	check(not rt.is_hidden(b),"Leaf veiling gives a visible warning before direct-fire hiding")
	rt.update_boss(b,0.2)
	check(rt.is_hidden(b) and g._is_hidden_from_lane_attacks(b),"Actual Aya leaf silhouette joins the native hidden-target rule")
	var point: Vector2=rt.body_point(b)
	var query: Dictionary={"row":int(b.row),"position":point,"speed":460.0,"radius":8.0,"free_aim":true,"ignore_lane_hide":true}
	check(g._find_projectile_target(query)==-1,"Ignoring ordinary fog cannot bypass Aya's actual leaf veil")
	var col: int=clampi(roundi((point.x-g.BOARD_ORIGIN.x)/g.CELL_SIZE.x-0.5),0,8)
	g.grid[int(b.row)][col]=g._create_plant("plantern",int(b.row),col)
	check(not rt.is_hidden(b) and not g._is_hidden_from_lane_attacks(b),"Actual nearby plantern reveals Aya's visible leaf silhouette")
	rt.clear_owner(int(b.uid)); g.touhou_danmaku.clear_owner(int(b.touhou_owner))
	g._spawn_zombie_at("momiji_boss",3,g._boss_anchor_x("momiji_boss"),true)
	var momiji: Dictionary=g._find_alive_enemy_boss("momiji_boss")
	check(_select_id(g,momiji,"original-momiji-sentinel"),"Momiji's real lane guard card is declared")
	g._trigger_boss_skill(momiji); rt.update_boss(momiji,1.3)
	check(is_equal_approx(rt.damage_factor(momiji,rt.body_point(momiji).x-80),0.68),"Warned Momiji shield remains a bounded directional reduction")
	before=float(momiji.health); g._apply_zombie_damage(momiji,80.0,0,0,false,false,rt.body_point(momiji).x-80)
	check(absf(before-float(momiji.health)-80.0*0.125*0.68)<0.001,"Real normal hits combine bounded shield with the shared formal guard")
	before=float(momiji.health); g._apply_zombie_damage(momiji,80.0,0,0,true)
	check(absf(before-float(momiji.health)-10.0)<0.001,"Piercing bypasses the directional shield without bypassing formal resistance")
	rt.clear_owner(int(momiji.uid)); g.touhou_danmaku.clear_owner(int(momiji.touhou_owner))

func _counters(g: Control,b: Dictionary) -> void:
	var rt=g._ensure_tengu_runtime(); var owner: int=int(b.uid); var cell:=Vector2i(2,2)
	for counter in ["umbrella_leaf","anchor_fern"]:
		var p: Dictionary=g._create_plant(counter,cell.x,cell.y); g.grid[cell.x][cell.y]=p
		var before: float=_vitality(p); rt.queue_field(owner,cell,"report",1.4); rt.update(1.5)
		check(_vitality(p)==before,"Actual "+counter+" counter blocks the warned photo strike")
		rt.clear_owner(owner)
	var p: Dictionary=_plant(g,cell); p.rooted_timer=2.0
	var before: float=_vitality(p); rt.queue_field(owner,cell,"cyclone",1.2); rt.update(1.5)
	check(_vitality(p)==before,"A genuinely rooted defense resists the warned moving cyclone")
	rt.clear_owner(owner)
	p=_plant(g,cell); rt.queue_field(owner,cell,"wind",1.2); rt.update(1.3)
	var shot: Dictionary={"kind":"pea","row":cell.x,"position":g._cell_center(cell.x,cell.y),"source_cell":cell,"speed":460.0,"velocity_y":0.0,"damage":20.0}
	rt.modify_projectile(shot,0.1)
	check(float(shot.damage)==20.0 and (bool(shot.get("free_aim",false)) or not is_zero_approx(float(shot.velocity_y))),"Active wind alters actual ordinary flight rather than multiplying player damage")
	for flag in ["ultimate","plant_food","fusion_ultimate","reflected"]:
		var special: Dictionary={"kind":"pea","row":cell.x,"position":g._cell_center(cell.x,cell.y),"source_cell":cell,"speed":460.0,"velocity_y":0.0,"damage":20.0,flag:true}
		rt.modify_projectile(special,0.1)
		check(float(special.damage)==20.0 and is_zero_approx(float(special.velocity_y)),flag+": wind preserves real counter-attack flight")
	rt.clear_owner(owner)

func _motion(g: Control,b: Dictionary) -> void:
	var rt=g._ensure_tengu_runtime(); var owner: int=int(b.uid)
	var start: Vector2=rt.body_point(b); rt.queue_dash(owner,Vector2i(5,2),1.2,0.36)
	rt.update_boss(b,1.1); rt.update(1.1)
	check(rt.body_point(b).distance_to(start)<0.01,"Aya gives a real stationary approach warning before dashing")
	rt.update_boss(b,0.15); rt.update(0.15)
	var middle: Vector2=rt.body_point(b)
	check(middle.distance_to(start)>1.0 and middle.distance_to(g._cell_center(5,2))>1.0,"Aya's dash visibly moves through an intermediate body, not an instantaneous ghost")
	check(g._zombie_target_point(b,middle).distance_to(middle)<0.01,"Native targeting uses Aya's exact current dash body")
	check(g._zombie_hit_positions(b).any(func(point): return Vector2(point).distance_to(middle)<0.01),"Collision and dash drawing share a live body position")
	rt.cleanse_row(5)
	check(rt.dashes.is_empty(),"The actual target-row cleanse cancels a pending/active dash")
	for n in range(40): rt.queue_dash(owner,Vector2i(n%6,2),1.2,0.36)
	check(rt.dashes.size()<=12,"Queued visible dashes remain bounded")
	rt.clear_owner(owner)

func _capture_sample(g: Control,b: Dictionary,route: String,mode: String) -> Dictionary:
	var rt=g._ensure_tengu_runtime(); var owner: int=int(b.uid); rt.clear_owner(owner); g.projectiles.clear()
	for enemy in g.zombies:
		if not g._is_boss_zombie(enemy): enemy.health=0.0
	g._cleanup_dead_zombies()
	for row in range(6):
		for col in range(9): g.grid[row][col]=null; g.support_grid[row][col]=null
	var row:=1 if mode=="outside" else 3; var cell:=Vector2i(3,4)
	var returning: bool=route.ends_with("_return")
	var fused: bool=route=="fusion" or route.begins_with("fusion_")
	var physical: String=route.trim_prefix("fusion_").trim_suffix("_return")
	# Converging barrage approaches from several sides. Put the cyclone on one
	# actual inbound ray rather than demanding it block rays outside its body.
	if physical=="converge": cell.y=5
	if mode!="control" and not returning:
		rt.queue_field(owner,cell,"cyclone",1.2)
		rt.update(1.3 if mode!="warning" else 1.1)
	var aim: Vector2=g._cell_center(row,4)
	if route=="fast": aim.x+=g.CELL_SIZE.x*0.75
	g._spawn_zombie_at("normal",row,aim.x,true); var target: Dictionary=g.zombies.back(); var hp_before: float=float(target.health)
	var origin: Vector2=g._cell_center(row,2)
	if fused and physical!="converge":
		var base: String={"fusion":"peashooter","boomerang":"boomerang_shooter","frost":"frost_boomerang","orbit":"lotus_lancer"}[physical]
		var plant_col:=4 if physical=="orbit" else 2
		g.grid[row][plant_col]=g._create_plant(Fusion.result(base,"wallnut"),row,plant_col)
		for frame in range(100):
			g._update_plants(0.05)
			if not g.projectiles.is_empty(): break
		check(not g.projectiles.is_empty() and g.projectiles.any(func(p): return p.has("fusion_source")),"The cyclone fusion sample uses an actual native fused firing channel")
	elif route=="lob": g._ensure_plant_runtime().spawn_roof_lobbed_projectile("melon",row,origin,aim,45.0,Color.GREEN,72.0,12.0,86.0,0.0,"melon_pult")
	elif route=="homing": g._ensure_plant_runtime().spawn_moonforge_projectile(origin,aim,45.0,72.0)
	elif physical=="boomerang": g._ensure_plant_runtime().spawn_boomerang_projectile(row,origin,origin.x-10,26.0,3)
	elif physical=="frost": g._spawn_frost_boomerang_projectile(row,origin,origin.x-10,26.0,2.6)
	elif physical=="orbit":
		var p: Dictionary=g._create_plant("lotus_lancer",row,4); p.shot_cooldown=0.0
		g._ensure_plant_runtime().update_lotus_lancer(p,0.1,row,4)
	elif physical=="converge": g._spawn_lotus_lancer_converge_barrage(origin,g.zombies.find(target),1)
	else: g._spawn_projectile(row,origin,Color.GREEN,45.0,0.0,(aim.x-origin.x)/0.1 if route=="fast" else 460.0,8.0,"peashooter")
	if g.projectiles.is_empty(): return {"captured":false,"removed":false,"damage":0.0,"tokens":0}
	var shot: Dictionary=g.projectiles[0]
	if returning:
		for frame in range(400):
			g._update_projectiles(0.05)
			if not bool(shot.get("outbound",true)): break
		check(not bool(shot.get("outbound",true)) and shot.get("return_markers",[]).any(func(marker): return int(marker.uid)==int(target.uid)) and float(target.health)<hp_before,"The native outbound first leg records real enemy UID/x return markers before the return-capture fixture")
		hp_before=float(target.health)
		if mode!="control": rt.queue_field(owner,cell,"cyclone",1.2); rt.update(1.3)
	for frame in range(160):
		g._update_projectiles(0.1 if route=="fast" else 0.05)
		if not g.projectiles.any(func(p): return is_same(p,shot)): break
	var tokens: int=rt.fields[0].get("orbit_tokens",[]).size() if not rt.fields.is_empty() else 0
	var result: Dictionary={"captured":bool(shot.get("tengu_captured",false)),"removed":not g.projectiles.any(func(p): return is_same(p,shot)),"damage":hp_before-float(target.health),"tokens":tokens}
	g.projectiles.clear(); g.grid[row][2]=null; rt.clear_owner(owner)
	return result

func _cyclone_capture(g: Control,b: Dictionary) -> void:
	for route in ["ordinary","fusion","fast","lob","homing","boomerang","fusion_boomerang","boomerang_return","fusion_boomerang_return","frost","fusion_frost","orbit","fusion_orbit","converge"]:
		var control: Dictionary=_capture_sample(g,b,route,"control")
		var active: Dictionary=_capture_sample(g,b,route,"active")
		check(float(control.damage)>0,"The native "+route+" control really reaches an ordinary enemy without a cyclone")
		check(bool(active.captured) and bool(active.removed) and float(active.damage)==0.0 and int(active.tokens)>0,"Active cyclone consumes actual "+route+" motion before native hit/splash, leaving only a bounded visible token")
		print(JSON.stringify({"cyclone_route":route,"viewport":g.size,"control":control,"active":active}))
	for mode in ["warning","outside"]:
		var sample: Dictionary=_capture_sample(g,b,"ordinary",mode)
		check(not bool(sample.captured) and float(sample.damage)>0 and int(sample.tokens)==0,"Cyclone "+mode+" leaves actual native projectile damage and flight intact")
	var rt=g._ensure_tengu_runtime(); var owner: int=int(b.uid); var cell:=Vector2i(3,4)
	rt.queue_field(owner,cell,"cyclone",1.2); rt.update(1.3)
	var field: Dictionary=rt.fields[0]; var center: Vector2=rt.cyclone_point(field)
	for kind in ["boomerang","frost_boomerang","lotus_orbit_shot","lotus_converge_shot"]:
		g.projectiles.clear()
		match kind:
			"boomerang": g._ensure_plant_runtime().spawn_boomerang_projectile(3,center,center.x-100.0,26.0,3)
			"frost_boomerang": g._spawn_frost_boomerang_projectile(3,center,center.x-100.0,26.0,2.6)
			"lotus_orbit_shot":
				var p: Dictionary=g._create_plant("lotus_lancer",3,4); p.shot_cooldown=0.0
				g._ensure_plant_runtime().update_lotus_lancer(p,0.1,3,4)
			"lotus_converge_shot": g._spawn_lotus_lancer_converge_barrage(center,g.zombies.find(b),4)
		check(not g.projectiles.is_empty() and String(g.projectiles[0].kind)==kind,"Physical capture contract starts from the actual native shot factory: "+kind)
		if g.projectiles.is_empty(): continue
		check(rt.capture_projectile(g.projectiles[0],center-Vector2(80,0),center+Vector2(80,0)),"Unempowered physical "+kind+" must not bypass active cyclone capture")
	for flag in ["ultimate","plant_food","fusion_ultimate","reflected","hina_exempt"]:
		g.projectiles.clear(); g._spawn_projectile(3,center-Vector2(20,0),Color.GREEN,45,0,460,8,"peashooter")
		var shot: Dictionary=g.projectiles[0]; shot[flag]=true
		check(not rt.capture_projectile(shot,center-Vector2(20,0),center+Vector2(20,0)),flag+": cyclone preserves the real special counterattack")
		g._update_projectiles(0.01)
		check(not bool(shot.get("tengu_captured",false)) and g.projectiles.any(func(p): return is_same(p,shot)),flag+": the native projectile loop keeps the immune shot")
	for n in range(40):
		var shot: Dictionary={"kind":"pea","position":center,"radius":8.0,"color":Color.GREEN}
		check(rt.capture_projectile(shot,center-Vector2(80,0),center+Vector2(80,0)),"An active cyclone catches a swept physical segment")
		var count: int=field.orbit_tokens.size()
		check(rt.capture_projectile(shot,center,center) and field.orbit_tokens.size()==count,"Repeated consumption keeps the capture marker and cannot create duplicate orbit debris")
	check(field.orbit_tokens.size()==12,"Many captures retain at most twelve compact orbit tokens")
	var age_before: float=float(field.orbit_tokens[0].age); g.boss_time_stop_timer=1.0
	g.projectiles.clear(); g._spawn_projectile(3,center,Color.GREEN,45,0,460,8,"peashooter"); var frozen_shot: Dictionary=g.projectiles[0]; var frozen_position: Vector2=frozen_shot.position
	g._update_projectiles(0.5); rt.update(0.5)
	check(Vector2(frozen_shot.position)==frozen_position and not bool(frozen_shot.get("tengu_captured",false)) and float(field.orbit_tokens[0].age)==age_before,"Native time stop freezes both shot capture and visible orbit debris")
	g.boss_time_stop_timer=0.0; g.battle_paused=true; g._process(0.5)
	check(Vector2(frozen_shot.position)==frozen_position and float(field.orbit_tokens[0].age)==age_before,"Actual pause freezes cyclone tokens and native projectile motion")
	g.battle_paused=false; g.projectiles.clear(); rt.update(1.0)
	check(field.orbit_tokens.is_empty(),"Captured debris expires at native lifetime instead of retaining projectile dictionaries")
	rt.capture_projectile({"kind":"pea","position":rt.cyclone_point(field),"radius":8,"color":Color.GREEN},rt.cyclone_point(field),rt.cyclone_point(field))
	rt.cleanse_row(cell.x)
	check(rt.fields.is_empty(),"Real row cleansing clears the cyclone and its owned orbit tokens")

func _clocks_and_cleanup(g: Control,b: Dictionary) -> void:
	var rt=g._ensure_tengu_runtime(); var owner: int=int(b.uid); var cell:=Vector2i(5,1)
	rt.queue_field(owner,cell,"wind",1.2); rt.queue_dash(owner,cell,1.2,0.36)
	var point: Vector2=rt.body_point(b); g.boss_time_stop_timer=1.0; rt.update(1.0); rt.update_boss(b,1.0)
	check(float(rt.fields[0].age)==0.0 and rt.body_point(b).distance_to(point)<0.01,"Native time stop freezes fields and continuous movement")
	g.boss_time_stop_timer=0; g.battle_paused=true; g._process(1.0)
	check(float(rt.fields[0].age)==0.0,"Actual pause leaves warning clocks unchanged")
	g.battle_paused=false; rt.update(1.3); _plant(g,cell,true)
	var click_orbit: Dictionary=_native_orbit_field(g,b,cell)
	g.grid[cell.x][cell.y].ultimate_charge=1.0
	check(g._try_activate_ultimate(cell.x,cell.y) and rt.fields.is_empty() and rt.dashes.is_empty(),"Real fused click ultimate clears wind and dash threats on its row")
	check(click_orbit.orbit_tokens.is_empty(),"Actual fused click cleansing releases captured projectile debris")
	rt.queue_field(owner,Vector2i(4,1),"wind",1.2); _plant(g,Vector2i(4,1))
	var food_orbit: Dictionary=_native_orbit_field(g,b,Vector2i(4,1))
	check(g._ensure_plant_food_runtime().activate(4,1) and rt.fields.is_empty(),"Real native plant-food activation clears the row")
	check(food_orbit.orbit_tokens.is_empty(),"Actual plant food cleansing clears visible captured orbit debris")
	rt.queue_field(owner,Vector2i(3,1),"report",1.4); rt.queue_dash(owner,Vector2i(3,1),1.2,0.36)
	var phase_orbit: Dictionary=_native_orbit_field(g,b,Vector2i(3,1))
	g._trigger_boss_phase_shift(b,1)
	check(rt.fields.is_empty() and rt.dashes.is_empty(),"Actual phase transition clears old pressure and movement")
	check(phase_orbit.orbit_tokens.is_empty(),"Native phase cleanup releases captured orbit tokens even when observed by a retained fixture reference")
	rt.queue_field(owner,Vector2i(2,1),"wind",1.2); rt.clear_owner(owner)
	check(rt.fields.is_empty() and rt.dashes.is_empty(),"Owner cleanup removes all finite hazards")
	var reset_orbit: Dictionary=_native_orbit_field(g,b,Vector2i(2,1)); rt.reset()
	check(rt.fields.is_empty() and rt.dashes.is_empty() and not rt.land_arrived,"Retry reset clears hazard state and the one-shot land arrival flag")
	check(reset_orbit.orbit_tokens.is_empty(),"Native retry reset releases captured projectile orbit state")

func _native_orbit_field(g: Control,b: Dictionary,cell: Vector2i) -> Dictionary:
	var rt=g._ensure_tengu_runtime(); rt.queue_field(int(b.uid),cell,"cyclone",1.2); rt.update(1.3)
	var field: Dictionary=rt.fields.filter(func(f): return String(f.mode)=="cyclone" and f.cell==cell).back()
	var center: Vector2=rt.cyclone_point(field)
	g._spawn_projectile(cell.x,center,Color.GREEN,20,0,460,8,"peashooter"); var shot: Dictionary=g.projectiles.back(); g._update_projectiles(0.001)
	check(bool(shot.get("tengu_captured",false)) and not field.orbit_tokens.is_empty(),"Lifecycle cleanup starts with a truly intercepted native projectile and live orbit token")
	return field

func _sprite_fit(g: Control,b: Dictionary) -> void:
	for kind in ["momiji_boss","aya_boss"]:
		for row in range(6):
			var point: Vector2=g._cell_center(row,7)
			var fit: float=Scene._body_fit(g,point,kind)
			var top: float=point.y+Scene.SpriteDefs.top_offset(kind)*g._battle_unit_scale()*fit
			check(fit>0 and fit<=1 and top>=Scene._hud_floor(g)-0.01,"Native "+kind+" supplied sprite/trail rectangle fits below the battle HUD at every actual row")
	var rt=g._ensure_tengu_runtime()
	rt.queue_dash(int(b.uid),Vector2i(0,6),1.2,0.36)
	for frame in range(28): rt.update_boss(b,0.05); rt.update(0.05)
	check(not rt.afterimages.is_empty(),"The top-edge fit probe uses actual finite dash trails")
	for trail in rt.afterimages:
		var point: Vector2=rt._world(Vector2(trail.uv)); var fit: float=Scene._body_fit(g,point,"aya_boss")
		check(point.y+Scene.SpriteDefs.top_offset("aya_boss")*g._battle_unit_scale()*fit>=Scene._hud_floor(g)-0.01,"Each finite trail is fitted at its own world anchor")
	rt.clear_owner(int(b.uid))

func _all_card_roaming(viewport: Vector2) -> void:
	for rank in range(4):
		var choice: String=["easy","normal","hard","lunatic"][rank]; var g: Control=_game(viewport,choice)
		var b: Dictionary=g._find_alive_enemy_boss("aya_boss"); var rt=g._ensure_tengu_runtime(); var ids: Array=[]
		for phase in b.touhou_encounter.phases:
			for attack in phase:
				if not ids.has(String(attack[0])): ids.append(String(attack[0]))
		for id in ids:
			rt.clear_owner(int(b.uid))
			if g.touhou_danmaku!=null: g.touhou_danmaku.clear_owner(int(b.get("touhou_owner",b.uid)))
			check(_select_id(g,b,id),"Every actual Aya card can be reached for the roaming regression")
			g._trigger_boss_skill(b)
			var first: Vector2=rt.body_point(b); var active_moved:=false; var emitted:=false
			for frame in range(72):
				var was_active: bool=float(b.get("touhou_cast_remaining",0.0))>0.0
				g.level_time+=0.05; g._update_zombies(0.05); g.touhou_danmaku.update(0.05); rt.update(0.05); g._update_effects(0.05)
				var point: Vector2=rt.body_point(b)
				if was_active and point.distance_to(first)>2.0: active_moved=true
				check(g._zombie_target_point(b,point).distance_to(point)<0.01,"All-card native movement keeps collision on Aya's actual live body")
				for cast in g.touhou_danmaku.casts:
					if int(cast.boss_uid)==int(b.uid):
						emitted=true
						check(Vector2(cast.center).distance_to(point)<0.01,"Every real card emitter follows the new all-board roaming body")
				check(rt.afterimages.size()<=12 and rt.dashes.size()<=12,"Every declared route keeps movement and afterimages finite")
			check(active_moved and emitted,"Aya moves visibly during actual native active casting: "+id)
		# This is an isolated between-cast state, not a balance fixture. Native
		# enemy update must continue moving without depending on a spell session.
		rt.clear_owner(int(b.uid)); g.touhou_danmaku.clear_owner(int(b.touhou_owner))
		b.touhou_cast_remaining=0.0; b.touhou_survival_timer=0.0; b.touhou_invulnerable=false
		b.touhou_encounter.casting=false
		b.boss_cast_pending=false; b.boss_skill_timer=1000.0; b.boss_pause_timer=0.0; b.rumia_state="idle"; b.rumia_state_timer=0.0
		var rows: Dictionary={}; var min_col:=INF; var max_col:=-INF; var intermediate:=false; var warned:=false
		for frame in range(400):
			g.level_time+=0.05; g._update_zombies(0.05); rt.update(0.05); g._update_effects(0.05)
			check(float(b.get("touhou_cast_remaining",0.0))==0.0 and not bool(b.get("touhou_invulnerable",false)),"The between-cast roaming fixture stays genuinely inactive without a survival or hidden attack session")
			var uv: Vector2=rt._body_uv(b); rows[roundi(uv.y)]=true; min_col=minf(min_col,uv.x); max_col=maxf(max_col,uv.x)
			for dash in rt.dashes:
				check(float(dash.delay)>=1.2-0.00001,"Every autonomous flight retains a readable native approach warning")
				if float(dash.age)<float(dash.delay): warned=true
				if float(dash.motion_time)>0.0 and float(dash.motion_time)<float(dash.duration): intermediate=true
		check(rows.size()==6 and min_col<=1.6 and max_col>=8.4 and warned and intermediate,"Between real casts Aya continuously traverses all six rows and cols 1–8 with warned intermediate positions")
		print(JSON.stringify({"aya_roaming_choice":choice,"viewport":viewport,"actual_cards":ids,"idle_rows":rows.keys(),"idle_min_col":min_col,"idle_max_col":max_col,"warned":warned,"intermediate":intermediate}))
		await _release(g)

func _release(g: Control) -> void:
	g._stop_bgm(); g.music_player.stream=null
	for player in g.sfx_players: player.stop(); player.stream=null
	g.save_dirty=false; await create_timer(0.35).timeout; g.free(); await create_timer(0.35).timeout; await process_frame

func check(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)

func _run() -> void:
	var g:=GameScript.new()
	check(g.has_method("_ensure_tengu_runtime"),"Native Game is missing the actual Tengu field/motion mechanics entry")
	g.save_dirty=false; g.free()
	if failures or _stage().is_empty(): quit(1); return
	for viewport in [Vector2(1600,900),Vector2(844,390)]:
		var game: Control=_game(viewport); var boss: Dictionary=game.zombies.filter(func(z): return String(z.kind)=="aya_boss").back()
		var capture_api: bool=game._ensure_tengu_runtime().has_method("capture_projectile")
		check(capture_api,"An actual active cyclone must consume swept ordinary and fused physical projectiles through the native update path")
		if not capture_api: await _release(game); call_deferred("quit",1); return
		var road: Dictionary=game._selection_level_preview_style(_stage())
		var land_level: Dictionary=_stage(); land_level.terrain="tengu_mountainside"; land_level.water_rows=[]
		var land: Dictionary=game._selection_level_preview_style(land_level)
		check(int(road.row_count)==6 and road.water_rows==[0,1,2,3,4,5] and int(land.row_count)==6 and land.water_rows.is_empty(),"Actual desktop/mobile map/selection previews distinguish six water and six land rows")
		check(not game._is_fog_level(),"Neither independent mountain phase inherits the fourth world's heavy fog")
		_cyclone_capture(game,boss); _fields(game,boss); _native_clocks(game,boss); _counters(game,boss); _motion(game,boss); _veil_and_incoming(game,boss); _sprite_fit(game,boss); _clocks_and_cleanup(game,boss)
		await _release(game)
		await _all_card_roaming(viewport)
	print("Tengu actual field pressure, counters, dash geometry and cleanup: %d failure(s)" % failures)
	call_deferred("quit",1 if failures else 0)
