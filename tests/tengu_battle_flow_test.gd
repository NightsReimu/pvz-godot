extends "res://scripts/tools/capture_battle_polish.gd"
const Phase = preload("res://scripts/runtime/touhou_phase_runtime.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
var failures := 0

class ObservedGame extends PreviewGame:
	var declarations: Array=[]
	var arrival_records: Array=[]
	var arrival_calls:=0
	func _tengu_begin_mountainside() -> void:
		arrival_calls+=1
		for row in range(6):
			for col in range(9):
				for layer_name in ["grid","support_grid"]:
					var p=get(layer_name)[row][col]
					if p!=null: arrival_records.append({"layer":layer_name,"row":row,"col":col,"plant":p,"health":p.health,"charge":p.ultimate_charge,"uid":p.get("uid",null),"kind":p.kind,"fusion_kind":p.get("fusion_kind",""),"stats":p.get("stats",{}).duplicate(true),"states":p.get("fusion_native_states",{}).duplicate(true),"payload":p.duplicate(true)})
		super._tengu_begin_mountainside()
	func _trigger_boss_skill(boss: Dictionary) -> Dictionary:
		declarations.append({"kind":boss.kind,"card":GameScript.TouhouSpellDefs.card_for(boss,current_level).id,"time":level_time})
		return super._trigger_boss_skill(boss)

func check(ok: bool,message: String) -> void:
	if not ok: failures+=1; push_error(message)

func _stage() -> Dictionary:
	for level in GameScript.Defs.LEVELS:
		if String(level.id)=="4-22": return level.duplicate(true)
	return {}

func _game(choice: String) -> Control:
	var g:=ObservedGame.new(); g.size=Vector2(1600,900); root.add_child(g)
	g._begin_level(-1,["sunflower","wallnut","repeater","sea_shroom","tangle_kelp","lily_pad","plantern","umbrella_leaf"],g.TouhouDifficulty.build_level(_stage(),choice))
	g.battle_intro_timer=0; g.startup_loading_active=false; g.page_transition_active=false
	g._drain_asset_prewarm_queue(); g._try_play_pending_bgm()
	return g

func _legal_first_plant(g: Control) -> void:
	if g._is_conveyor_level():
		for frame in range(200):
			if g.active_cards.has("wallnut"): break
			g._update_conveyor(0.1)
	else:
		check(g.sun_points>=int(g.Defs.PLANTS.wallnut.cost),"Manual selection supplies the real price for an opening wall")
	if not g.active_cards.has("wallnut"):
		# Every delivered ordinary plant uses the authored support; this is actual
		# seed delivery, not a injected bank or free board reconstruction.
		var options: Array=g.active_cards.filter(func(kind): return not String(kind) in ["","lily_pad","tangle_kelp","sea_shroom","cherry_bomb","jalapeno","pumpkin"])
		check(not options.is_empty(),"The physical slow belt delivers a legal supported opening plant")
		if options.is_empty(): return
		g._handle_primary_click(g._card_rect(g.active_cards.find(options[0])).get_center())
	else: g._handle_primary_click(g._card_rect(g.active_cards.find("wallnut")).get_center())
	g._handle_primary_click(g._cell_center(5,1))
	check(g.grid[5][1]!=null and String(g.support_grid[5][1].kind)=="lily_pad","Real seed controls place on the sixth lane's actual initial lily")

func _snapshot(g: Control) -> Array:
	var result: Array=[]
	for row in range(6):
		for col in range(9):
			for layer_name in ["grid","support_grid"]:
				var p=g.get(layer_name)[row][col]
				if p!=null:
					result.append({"layer":layer_name,"row":row,"col":col,"plant":p,"health":p.health,"charge":p.ultimate_charge,"uid":p.get("uid",null),"kind":p.kind,"fusion_kind":p.get("fusion_kind",""),"stats":p.get("stats",{}).duplicate(true),"states":p.get("fusion_native_states",{}).duplicate(true),"payload":p.duplicate(true)})
	return result

func _lily_count(g: Control) -> int:
	var count:=0
	for row in range(6):
		for col in range(9):
			for layer_name in ["grid","support_grid"]:
				var p=g.get(layer_name)[row][col]
				if p!=null and String(p.kind)=="lily_pad": count+=1
	return count

func _assert_preserved(g: Control,plants: Array) -> int:
	var removed:=0
	for record in plants:
		var p=g.get(record.layer)[record.row][record.col]
		if String(record.kind)=="lily_pad":
			removed+=1
			check(p==null,"Aya arrival removes every original or later lily support, including occupied cells")
			continue
		check(p!=null and is_same(p,record.plant),"Atomic terrain change preserves every living upper plant and non-lily support dictionary identity")
		if p==null: continue
		check(p.health==record.health and p.ultimate_charge==record.charge and p.get("uid",null)==record.uid,"Terrain change cannot heal, damage, recharge or change an existing identity")
		check(p.kind==record.kind and p.get("fusion_kind","")==record.fusion_kind and p.get("stats",{})==record.stats and p.get("fusion_native_states",{})==record.states,"Terrain change keeps aquatic/native/fusion stats and native chambers")
		var retained: Dictionary=p.duplicate(true); retained.erase("tengu_acclimated")
		var original: Dictionary=record.payload.duplicate(true); original.erase("tengu_acclimated")
		check(retained==original,"Lily removal preserves all existing upper-plant state, armor, timers and native chambers exactly")
		check(bool(p.get("tengu_acclimated",false)),"Existing native and non-lily support plants receive scoped acclimation")
	check(_lily_count(g)==0,"The complete six-by-nine grid and support grid contain zero lilies after Aya arrival")
	return removed

func _resolve_momiji(g: Control,b: Dictionary) -> void:
	# Sequencing/controller proof only: use the actual damage/phase APIs to
	# deplete floors, then let every mandatory cast finish at native duration.
	for frame in range(1800):
		g._apply_zombie_damage(b,1.0e7,0,0,true)
		g.level_time+=0.1; g._ensure_zombie_runtime().update_boss(b,0.1)
		if g.touhou_danmaku!=null: g.touhou_danmaku.update(0.1)
		g._ensure_tengu_runtime().update(0.1); g._update_effects(0.1)
		if bool(b.touhou_encounter.complete): break
	check(bool(b.touhou_encounter.complete),"Weak Momiji's actual mandatory guard route finishes and permits retreat")
	g._cleanup_dead_zombies(); g._update_frozen_branch_flow()
	check(g.frozen_branch_midboss_cleared and not g.frozen_branch_progress_locked,"Actual patrol defeat releases the native road gate")
	check(g.current_bgm_path==g.current_level.boss_intro_bgm,"The supplied road music continues after Momiji retreats")

func _director(g: Control) -> Dictionary:
	var ordinary_before:=0; var ordinary_after:=0; var momiji_time: float=-1.0; var road_hp:=0.0; var road_uid: int=-1
	var seen: Dictionary={}
	for frame in range(4200):
		g.level_time+=0.1; g._update_frozen_branch_flow(); g._update_spawn_director(0.1)
		var momiji: Dictionary=g._find_alive_enemy_boss("momiji_boss")
		if not momiji.is_empty() and momiji_time<0:
			momiji_time=g.level_time; road_hp=momiji.max_health; road_uid=int(momiji.uid)
			check(momiji_time>=120.0-0.0001 and momiji_time<150.0,"Actual weak patrol arrives at the long road's forty-percent gate")
			check(g.current_bgm_path==g.current_level.boss_intro_bgm and g.water_rows.size()==6,"Momiji neither plays ending music nor turns the water road into land")
			check(g._should_hold_final_boss_kind("aya_boss"),"The real director holds queued Aya while the patrol is alive")
			_resolve_momiji(g,momiji)
		for z in g.zombies:
			if String(z.kind) in ["momiji_boss","aya_boss"] or seen.has(int(z.uid)): continue
			seen[int(z.uid)]=true
			if momiji_time<0: ordinary_before+=1
			else: ordinary_after+=1
			g._apply_zombie_damage(z,1.0e7,0,0,true)
		g._cleanup_dead_zombies()
		var final_boss: Dictionary=g._find_alive_enemy_boss("aya_boss")
		if not final_boss.is_empty():
			check(g.level_time>=300.0-0.0001,"Even fast real native kills cannot spawn Aya before 300 road seconds")
			check(ordinary_before>0 and ordinary_after>0,"Many real batches appear both before and after weak Momiji")
			return {"boss":final_boss,"momiji_time":momiji_time,"aya_time":g.level_time,"road_hp":road_hp,"road_uid":road_uid,"pre":ordinary_before,"post":ordinary_after}
	check(false,"Actual authored road director must eventually arrive at full Aya")
	return {}

func _select(g: Control,b: Dictionary,id: String) -> bool:
	var e: Dictionary=b.touhou_encounter
	for pi in range(e.phases.size()):
		for ai in range(e.phases[pi].size()):
			if String(e.phases[pi][ai][0])==id:
				e.index=pi; e.attack=ai; e.completed=ai; e.complete=false; e.depleted=false; Phase._set_bounds(b); b.health=e.ceiling
				return true
	return false

func _survival(g: Control,b: Dictionary,rank: int) -> void:
	if rank==0: return
	check(_select(g,b,"th10-%03d" % (50+rank)),"The real full encounter contains the required survival card")
	g._trigger_boss_skill(b); var before: float=float(b.health)
	g._apply_zombie_damage(b,1.0e8,0,0,true)
	check(float(b.health)==before and bool(b.touhou_invulnerable),"Rapid-flight survival keeps original invulnerability against actual bypass-shield damage")
	for frame in range(500):
		g.level_time+=0.1; g._update_zombies(0.1)
		if g.touhou_danmaku!=null: g.touhou_danmaku.update(0.1)
		g._ensure_tengu_runtime().update(0.1); g._update_effects(0.1)
		if int(b.touhou_encounter.index)==b.touhou_encounter.phases.size()-1: break
	check(int(b.touhou_encounter.index)==b.touhou_encounter.phases.size()-1 and not bool(b.touhou_encounter.complete),"The actual survival timer advances to the still-live final blockade")
	check(String(g.TouhouSpellDefs.card_for(b,g.current_level).id)!="th10-%03d" % (50+rank),"The timed survival cannot retain its old spell identity")

func _live_cast_motion(g: Control,b: Dictionary,rank: int) -> void:
	check(_select(g,b,"th10-%03d" % (43+rank)),"The actual cast-motion probe reaches Aya's canonical branching paths")
	g._trigger_boss_skill(b)
	var rt=g._ensure_tengu_runtime(); var first: Vector2=rt.body_point(b); var moved:=false; var origin_matches:=false
	for frame in range(70):
		g.level_time+=0.05; g._update_zombies(0.05); g.touhou_danmaku.update(0.05); rt.update(0.05)
		var point: Vector2=rt.body_point(b)
		if point.distance_to(first)>2.0: moved=true
		check(g._zombie_target_point(b,point).distance_to(point)<0.01,"Real active-cast zombie update preserves exact body targeting")
		for cast in g.touhou_danmaku.casts:
			if int(cast.boss_uid)==int(b.uid):
				check(Vector2(cast.center).distance_to(point)<0.01,"Live emitted spell follows the moving body instead of an old ghost")
				origin_matches=true
	check(moved and origin_matches,"Aya visibly dashes during actual active-cast _update_zombies, with live danmaku origin")
	check(rt.afterimages.size()<=12,"The real active-cast afterimages stay finite")
	g.touhou_danmaku.clear_owner(int(b.touhou_owner)); rt.clear_owner(int(b.uid))

func _finish_blockade(g: Control,b: Dictionary,rank: int) -> bool:
	check(_select(g,b,"th10-%03d" % (54+rank)),"The actual canonical blockade remains the encounter's last phase")
	g._trigger_boss_skill(b)
	for frame in range(1000):
		g._apply_zombie_damage(b,1.0e7,0,0,true); g.level_time+=0.1; g._update_zombies(0.1)
		if g.touhou_danmaku!=null: g.touhou_danmaku.update(0.1)
		g._ensure_tengu_runtime().update(0.1); g._update_effects(0.1)
		for enemy in g.zombies:
			if String(enemy.kind) not in ["aya_boss","momiji_boss"]: g._apply_zombie_damage(enemy,1.0e7,0,0,true)
		g._cleanup_dead_zombies()
		if bool(b.touhou_encounter.complete): break
	check(bool(b.touhou_encounter.complete),"The canonical final blockade can actually finish and defeat Aya")
	check(g.declarations.any(func(record): return String(record.card)=="th10-%03d" % (54+rank)),"Ending requires the actual final canonical declaration")
	for frame in range(100):
		g._update_spawn_director(0.1)
		for enemy in g.zombies:
			if g._is_enemy_zombie(enemy): g._apply_zombie_damage(enemy,1.0e7,0,0,true)
		g._cleanup_dead_zombies()
		if g.batch_spawn_queue.is_empty(): break
	check(g._ensure_tengu_runtime().fields.is_empty() and g._ensure_tengu_runtime().dashes.is_empty() and g._ensure_tengu_runtime().afterimages.is_empty(),"Actual Aya defeat removes field, motion and finite image state")
	var finished: bool=g._can_finish_level_ignoring_obstacles()
	check(finished,"Native final level gate accepts the completed blockade and drained ordinary arrivals")
	return finished

func _transfer_state() -> void:
	# A transition unit fixture uses native objects and actual damage/charge
	# progression; the separate road-controller proof exercises real paid input.
	var g: Control=_game("lunatic"); var id: String=Fusion.result("repeater","wallnut")
	check(_lily_count(g)==12,"The transfer fixture starts with the exact twelve authored lilies")
	var pad_price: int=int(g.Defs.PLANTS.lily_pad.cost); var paid_before: int=g.sun_points
	g._handle_primary_click(g._card_rect(g.active_cards.find("lily_pad")).get_center()); g._handle_primary_click(g._cell_center(0,8))
	check(g.support_grid[0][8]!=null and String(g.support_grid[0][8].kind)=="lily_pad" and g.sun_points==paid_before-pad_price,"A late top-corner lily is planted using actual selection and sun payment")
	for frame in range(76): g._process(0.1)
	paid_before=g.sun_points
	g._handle_primary_click(g._card_rect(g.active_cards.find("lily_pad")).get_center()); g._handle_primary_click(g._cell_center(5,8))
	check(g.support_grid[5][8]!=null and String(g.support_grid[5][8].kind)=="lily_pad" and g.sun_points==paid_before-pad_price,"A late sixth-row corner lily uses its real native cooldown and price")
	g._handle_primary_click(g._card_rect(g.active_cards.find("wallnut")).get_center()); g._handle_primary_click(g._cell_center(5,8))
	check(g.grid[5][8]!=null and String(g.grid[5][8].kind)=="wallnut","A real paid upper wall occupies the late lily before drying")
	check(_lily_count(g)==14,"Transfer exercises all twelve initial lilies plus both legally planted later lilies")
	var p: Dictionary=g._create_plant(id,1,1); g.grid[1][1]=p
	var sea: Dictionary=g._create_plant("sea_shroom",2,3); g.grid[2][3]=sea
	check(float(sea.sleep_timer)==0.0,"The supplied road water shooter is actually awake on placement")
	g._damage_plant_cell(1,1,37.0); g._update_ultimate_charges(21.0)
	var rt=g._ensure_plant_fusion(); rt.native_runtime=rt.NativeRuntime.new(g)
	var native: Dictionary=rt.native_runtime.state_for(p,"peashooter",1,1); native.shot_cooldown=0.73
	g._spawn_zombie_at("snorkel",5,g._cell_center(5,7).x,true); var swimmer: Dictionary=g.zombies.back(); var swimmer_uid: int=int(swimmer.uid)
	var before: Array=_snapshot(g); g.level_time=300.0; g._spawn_zombie_at("aya_boss",2,g._boss_anchor_x("aya_boss"),true)
	var b: Dictionary=g._find_alive_enemy_boss("aya_boss"); var removed: int=_assert_preserved(g,before)
	check(removed==14,"Native atomic arrival removes the exact fourteen initial and later lilies while retaining every upper plant")
	check(int(swimmer.uid)==swimmer_uid and g.zombies.any(func(z): return int(z.uid)==swimmer_uid),"Atomic land arrival preserves the existing swimmer's actual UID")
	var x_before: float=float(swimmer.x); g._update_zombies(0.1); g._update_plants(0.1)
	check(float(swimmer.health)>0 and float(swimmer.x)<x_before,"A swimmer already on the board continues after all lanes dry")
	check(g.grid[2][3]!=null and float(sea.health)>0,"The placed aquatic shooter continues living and acting on acclimated land")
	var tengu=g._ensure_tengu_runtime(); var arrival_count: int=g.arrival_calls; tengu.on_finale_arrival(b)
	check(g.arrival_calls==arrival_count and arrival_count==1,"Repeated actual-arrival notifications cannot apply the terrain/belt transition twice")
	g._restart_current_battle()
	check(g.current_level.terrain=="tengu_waterfall" and g.water_rows==[0,1,2,3,4,5] and not bool(g.current_level.get("tengu_finale_arrived",false)),"Actual land-checkpoint retry rebuilds the original six-water road")
	check(_lily_count(g)==12 and g.support_grid[0][8]==null and g.support_grid[5][8]==null,"Real retry restores exactly twelve initial lilies without retaining the two later ones")
	for row in range(6):
		for col in [1,2]: check(g.support_grid[row][col]!=null and String(g.support_grid[row][col].kind)=="lily_pad","Retry restores every authored lily at the actual initial support coordinate")
	var retry_cards: Array=g.conveyor_source_cards if g._is_conveyor_level() else g.active_cards
	check(retry_cards.has("lily_pad") and retry_cards.has("sea_shroom") and not g._ensure_tengu_runtime().land_arrived,"Retry restores the original mode's water seeds and runtime arrival state")
	check(_stage().terrain=="tengu_waterfall" and _stage().water_rows==[0,1,2,3,4,5],"The one-battle terrain swap never mutates the registered shared level")
	await _release(g)

func _manual_replacement_seeds() -> void:
	for pair in [["lily_pad","wallnut",Vector2i(5,3)],["sea_shroom","repeater",Vector2i(4,3)],["tangle_kelp","squash",Vector2i(3,4)]]:
		var g: Control=_game("lunatic"); var source: String=pair[0]; var target: String=pair[1]; var cell: Vector2i=pair[2]
		var sun_before: int=g.sun_points
		g._handle_primary_click(g._card_rect(g.active_cards.find(source)).get_center()); g._handle_primary_click(g._cell_center(cell.x,cell.y))
		print(JSON.stringify({"replacement_source":source,"water_seed_cards":g.active_cards,"water_seed_cooldown":g.card_cooldowns.get(source,-1),"water_seed_top":g.grid[cell.x][cell.y].get("kind","") if g.grid[cell.x][cell.y]!=null else "","water_seed_support":g.support_grid[cell.x][cell.y].get("kind","") if g.support_grid[cell.x][cell.y]!=null else "","toast":g.toast_label.text}))
		check(g.support_grid[cell.x][cell.y]!=null if source=="lily_pad" else g.grid[cell.x][cell.y]!=null,"The clicked water material is really present before migration: "+source)
		check(g.sun_points==sun_before-int(g.Defs.PLANTS[source].cost),"Manual water source is really planted and paid before its replacement")
		var waiting: float=float(g.card_cooldowns[source])-4.0
		for frame in range(ceili(waiting/0.1)): g._process(minf(0.1,waiting-float(frame)*0.1))
		var remaining: float=float(g.card_cooldowns[source]); check(absf(remaining-4.0)<0.001,"Native elapsed play leaves an actual four-second water-seed cooldown: %s %.4f state=%s" % [source,remaining,g.battle_state])
		g.level_time=300.0; g._spawn_zombie_at("aya_boss",2,g._boss_anchor_x("aya_boss"),true)
		check(g.active_cards.has(target) and g.card_cooldowns.has(target),"Land conversion supplies the real replacement card and cooldown key: "+target)
		if not g.card_cooldowns.has(target): await _release(g); continue
		check(absf(float(g.card_cooldowns[target])-remaining)<0.001,"Land replacement inherits the unfinished native source cooldown")
		g._handle_primary_click(g._card_rect(g.active_cards.find(target)).get_center())
		check(String(g.selected_tool).is_empty(),"The new land alias cannot spend a free card during its inherited cooldown")
		g._process(0.1)
		check(absf(float(g.card_cooldowns[target])-(remaining-0.1))<0.001,"Multiple transformed aliases tick one shared cooldown once per native frame: %s %.4f -> %.4f state=%s" % [source,remaining,g.card_cooldowns[target],g.battle_state])
		for frame in range(40): g._process(0.1)
		var paid_before: int=g.sun_points
		g._handle_primary_click(g._card_rect(g.active_cards.find(target)).get_center()); g._handle_primary_click(g._cell_center(5,4))
		check(g.grid[5][4]!=null and String(g.grid[5][4].kind)==target,"Actual replacement land seed clicks and plants legally after its native cooldown")
		check(g.sun_points==paid_before-int(g.Defs.PLANTS[target].cost),"Actual replacement uses its own real land seed price")
		await _release(g)

func _release(g: Control) -> void:
	g._stop_bgm(); g.music_player.stream=null
	for player in g.sfx_players: player.stop(); player.stream=null
	g.save_dirty=false; await create_timer(0.35).timeout; g.free(); await create_timer(0.35).timeout; await process_frame

func _run() -> void:
	check(not _stage().is_empty(),"Native Tengu battle flow requires the actual registered 4-22")
	if failures: quit(1); return
	var rows: Array=[]
	for rank in range(4):
		var choice: String=["easy","normal","hard","lunatic"][rank]; var g: Control=_game(choice)
		check(g.active_rows==[0,1,2,3,4,5] and g.water_rows==[0,1,2,3,4,5],"Initial native board really has six active water lanes")
		check(g.current_bgm_path==g.current_level.boss_intro_bgm and g.music_player.playing,"The actual supplied road MP3 plays before either boss")
		for row in range(6):
			for col in [1,2]: check(g.support_grid[row][col]!=null and String(g.support_grid[row][col].kind)=="lily_pad","Opening support is a real lily dictionary on every water row")
		_legal_first_plant(g)
		# Controller proof traverses all original director batches with actual
		# phase damage; it does not assert balance or silently weaken enemy stats.
		var flow: Dictionary=_director(g)
		if flow.is_empty(): await _release(g); continue
		var b: Dictionary=flow.boss
		check(int(b.uid)!=int(flow.road_uid) and float(b.max_health)>float(flow.road_hp)*8.0 and b.health==b.max_health,"Full Aya has a new identity and strength far above the short road patrol")
		check(g.current_level.terrain=="tengu_mountainside" and g.water_rows.is_empty(),"Actual final-boss arrival atomically switches all six rows to dry mountainside")
		var removed_lilies: int=_assert_preserved(g,g.arrival_records)
		check(removed_lilies==12,"Actual long-road Aya arrival removes exactly the original twelve lilies")
		check(g.arrival_calls==1,"The real long-road director applies one atomic arrival transition")
		for row in range(6):
			for col in range(9): check(g._cell_terrain_kind(row,col)=="land","Every actual final board cell is dry in the same arrival")
		check(g.current_bgm_path==g.current_level.boss_bgm and g.music_player.playing,"The ending MP3 begins only on real Aya arrival")
		check(b.touhou_encounter.phases.size()==[6,8,9,10][rank],"The actual spawned finale uses the four designed full routes")
		check(int(g._boss_health_bar_layout(b).segments)==1,"Aya uses the live single-phase Touhou health bar")
		for cards in [g.active_cards,g.conveyor_source_cards,g.selection_cards,g.selection_pool_cards]:
			check(not cards.any(func(kind): return String(kind) in ["lily_pad","sea_shroom","tangle_kelp"]),"Only future water-only seed entries are replaced by land-compatible alternatives")
		var before: int=g.zombies.size(); b.rumia_reinforcement_timer=0.0; g._update_zombies(0.1)
		check(g.zombies.size()>before and g.zombies.any(func(z): return String(z.get("fusion_kind","")).length()>0),"Real native fused reinforcements keep arriving while Aya is alive")
		check(g._enemy_zombie_count()+g.batch_spawn_queue.size()<=42,"New finale reinforcement batches respect the live/queued enemy budget")
		check(_select(g,b,"original-aya-headwind"),"The actual route contains the PvZ headwind card")
		g._trigger_boss_skill(b)
		check(not String(g._boss_cast_status(b).text).contains("原创") and String(g._boss_cast_status(b).text).contains("符卡"),"Gameplay labels PvZ adaptations as declared spell cards")
		check(is_equal_approx(Phase.spell_damage_factor(b),0.125),"New declared cards retain the latest formal resistance")
		check(is_equal_approx(g.TouhouDifficulty.outgoing_damage_multiplier("aya_boss"),5.0) and is_equal_approx(g.TouhouDifficulty.outgoing_damage_multiplier("momiji_boss"),5.0) and is_equal_approx(g.TouhouDifficulty.outgoing_damage_multiplier("rumia_boss"),5.0) and is_equal_approx(g.TouhouDifficulty.outgoing_damage_multiplier("normal"),1.0),"Wind God Boss sources now use only common fivefold damage, matching other Touhou sources")
		_live_cast_motion(g,b,rank)
		_survival(g,b,rank)
		var finished: bool=_finish_blockade(g,b,rank)
		rows.append({"choice":choice,"momiji_seconds":flow.momiji_time,"aya_seconds":flow.aya_time,"probe_complete_seconds":g.level_time,"road_hp":flow.road_hp,"final_hp":b.max_health,"pre_patrol_enemies":flow.pre,"post_patrol_enemies":flow.post,"phase_count":b.touhou_encounter.phases.size(),"removed_lilies":removed_lilies,"remaining_lilies":_lily_count(g),"finished":finished})
		await _release(g)
	await _transfer_state()
	await _manual_replacement_seeds()
	var file:=FileAccess.open("res://output/tengu-4-22/tests/flow-summary.json",FileAccess.WRITE); file.store_string(JSON.stringify({"controller_only":true,"routes":rows,"failures":failures},"\t")+"\n")
	print("Tengu actual long-road gate, music, terrain, roster and timed survival flow: %d failure(s)" % failures)
	call_deferred("quit",1 if failures else 0)
