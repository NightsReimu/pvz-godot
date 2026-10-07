extends RefCounted

# Developed formations are a strength diagnostic, not a claim that a random
# conveyor delivered these exact materials before the authored finale gate.
const Game = preload("res://scripts/game.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const STAGES := ["4-19", "4-20", "4-21", "4-22"]
const TIERS := ["easy", "normal", "hard", "lunatic"]
const STYLES := ["balanced", "ash", "defensive"]
const SOURCES := ["scripts/game.gd", "scripts/data/touhou_difficulty_defs.gd", "scripts/data/fusion_plant_defs.gd", "scripts/runtime/plant_fusion_runtime.gd", "scripts/runtime/fusion_native_runtime.gd", "scripts/runtime/projectile_runtime.gd", "scripts/runtime/touhou_phase_runtime.gd", "scripts/runtime/touhou_danmaku_runtime.gd", "scripts/runtime/tengu_boss_runtime.gd", "scripts/runtime/tengu_danmaku.gd", "scripts/runtime/nitori_danmaku.gd"]

class NativeGame extends Game:
	var declarations: Array=[]
	var dead_fusions: Array=[]
	var dead_refs: Array=[]
	var damage_to_plants:=0.0
	var damage_to_boss:=0.0
	var damaged_rows: Dictionary={}
	var reinforcement_calls:=0
	var reinforcements:=0
	var campaign_fusions:=0
	var ultimates:=0
	var ultimate_inputs: Array=[]
	var paid_actions: Array=[]
	var violations: Array=[]
	var loss_reason:=""
	var breach: Dictionary={}
	func _ready() -> void:
		_build_font(); _build_overlay_ui(); set_process(false)
	func _notification(what: int) -> void:
		if what==NOTIFICATION_RESIZED: _refresh_battle_layout()
	func _save_game() -> void: pass
	func _update_autosave(_delta: float) -> void: pass
	func _trigger_boss_skill(b: Dictionary) -> Dictionary:
		var c: Dictionary=TouhouSpellDefs.card_for(b,current_level)
		declarations.append({"time":level_time,"card":c.id,"phase":int(b.get("touhou_encounter",{}).get("index",-1))+1,"boss":b.kind})
		return super._trigger_boss_skill(b)
	func _damage_plant_cell(row: int,col: int,damage: float,extra_cooldown: float=0.0,damage_already_scaled: bool=false) -> bool:
		var p=_targetable_plant_at(row,col); var before:=0.0
		if p!=null: before=maxf(0,float(p.health))+maxf(0,float(p.get("armor_health",0)))
		var hit: bool=super._damage_plant_cell(row,col,damage,extra_cooldown,damage_already_scaled)
		if p!=null:
			var removed: float=maxf(0,before-maxf(0,float(p.health))-maxf(0,float(p.get("armor_health",0))))
			damage_to_plants+=removed
			if removed>0: damaged_rows[row]=true
		return hit
	func _apply_zombie_damage(z: Dictionary,damage: float,flash_amount: float=0.12,slow_duration: float=0.0,ignore_shield: bool=false,pierce_handheld: bool=false,from_x: float=INF) -> Dictionary:
		var before: float=float(z.health); var finale: bool=_is_stage_ending_boss(z)
		var result: Dictionary=super._apply_zombie_damage(z,damage,flash_amount,slow_duration,ignore_shield,pierce_handheld,from_x)
		if finale: damage_to_boss+=maxf(0,before-float(result.health))
		return result
	func _remove_dead_plants() -> void:
		for table in [grid,support_grid]:
			for row in table:
				for p in row:
					if p==null or float(p.health)>0 or not p.has("fusion_kind") or dead_refs.any(func(old): return is_same(old,p)): continue
					dead_refs.append(p); dead_fusions.append({"time":level_time,"row":p.row,"col":p.col,"fusion_kind":p.fusion_kind})
		super._remove_dead_plants()
	func _spawn_hover_boss_reinforcement(kind: String,phase: int,b: Dictionary={}) -> void:
		var before: int=zombies.size(); super._spawn_hover_boss_reinforcement(kind,phase,b)
		reinforcement_calls+=1
		for z in zombies.slice(before):
			if _is_enemy_zombie(z) and not _is_boss_kind(String(z.kind)) and not bool(Defs.ZOMBIES.get(String(z.kind),{}).get("boss_summon",false)): reinforcements+=1
	func _campaign_fusion_variant(kind: String) -> String:
		var actual: String=super._campaign_fusion_variant(kind)
		if actual!=kind: campaign_fusions+=1
		return actual
	func _try_activate_ultimate(row: int,col: int) -> bool:
		var p=_targetable_plant_at(row,col); var charge: float=float(p.get("ultimate_charge",0)) if p!=null else 0.0
		var cooldown: float=float(p.get("ultimate_cooldown",0)) if p!=null else 0.0
		var success: bool=super._try_activate_ultimate(row,col)
		if success:
			ultimates+=1; ultimate_inputs.append({"time":level_time,"row":row,"col":col,"charge":charge,"cooldown":cooldown})
			if charge<1.0-0.00001 or cooldown>0.01: violations.append("An ultimate succeeded without its native earned charge/cooldown")
		return success
	func _lose_level(reason: String="") -> void:
		loss_reason=reason; super._lose_level(reason)
	func _check_zombie_home_entry(z: Dictionary) -> bool:
		var result: bool=super._check_zombie_home_entry(z)
		if not result and battle_state==BATTLE_LOST: breach={"time":level_time,"kind":z.kind,"fusion_kind":z.get("fusion_kind",""),"row":z.row,"health":z.health,"x":z.x,"flying":z.get("balloon_flying",false)}
		return result

var tree: SceneTree
var policy_cursor:=0

func _init(owner: SceneTree) -> void: tree=owner

func stage(id: String) -> Dictionary:
	for level in Game.Defs.LEVELS:
		if String(level.id)==id: return level.duplicate(true)
	return {}

func formation(id: String,tier: String,style: String) -> Array:
	var plan: Array=[]
	for row in range(6):
		var healer: Array=["repeater" if tier=="lunatic" or row%2 else "snow_pea","healing_gourd"]
		if tier=="lunatic" and row in [0,3]: healer=["sunflower","healing_gourd"]
		var rear: Array=["melon_pult","umbrella_leaf" if row in [1,4] else "torchwood"]
		if style=="ash": rear=["repeater","cherry_bomb"] if row in [0,3] else (["melon_pult","jalapeno"] if row in [1,4] else ["melon_pult","torchwood"])
		elif style=="defensive": rear=["melon_pult","umbrella_leaf"] if row%2==0 else ["wallnut","pumpkin"]
		elif style=="fortified": rear=["melon_pult","wallnut"]; healer=["wallnut","healing_gourd"]
		if id=="4-19" and style!="ash" and row in [0,3]: rear=["cactus","wallnut"]
		for entry in [[1,rear],[2,healer],[3,["repeater","wallnut"]]]:
			plan.append({"row":row,"col":entry[0],"pair":entry[1],"role":"rear" if entry[0]==1 else ("healer" if entry[0]==2 else "tank")})
	if id in ["4-21","4-22"]:
		for row in [1,4]: plan.append({"row":row,"col":6,"pair":["wallnut","plantern"],"role":"reveal"})
	return plan

func ingredient_ledger(plan: Array) -> Dictionary:
	var counts: Dictionary={}; var cost:=0
	for slot in plan:
		for seed in slot.pair:
			counts[seed]=int(counts.get(seed,0))+1; cost+=int(Game.Defs.PLANTS[seed].cost)
	return {"counts":counts,"native_price_total":cost,"seed_total":plan.size()*2,"bodies":plan.size(),"label":"developed formation; these materials are initial snapshot provenance, not purchased inside this probe"}

func manual_cards(id: String,tier: String,style: String) -> Array:
	var cards: Array=ingredient_ledger(formation(id,tier,style)).counts.keys()
	if id=="4-22" and tier=="lunatic" and not cards.has("lily_pad"): cards.append("lily_pad")
	return cards

func setup(id: String,tier: String,style: String,seed: int) -> Dictionary:
	var g:=NativeGame.new(); g.size=Vector2(1600,900); tree.root.add_child(g); g.rng.seed=seed
	var level: Dictionary=Game.TouhouDifficulty.build_level(stage(id),tier)
	var selected: Array=manual_cards(id,tier,style)
	g._begin_level(-1,selected if tier=="lunatic" else [],level); g.hide(); g.battle_intro_timer=0.0
	# This explicit snapshot begins at the finale, with zero charged plants.
	# No combat tick, road kill, phase advancement or damage is manufactured.
	g.next_event_index=g.current_level.events.size(); g.frozen_branch_midboss_spawned=true; g.frozen_branch_midboss_cleared=true; g.frozen_branch_progress_locked=false
	var last_time:=0.0
	for event in level.events: last_time=maxf(last_time,float(event.time))
	g.level_time=last_time
	var final_kind: String=String(level.events.back().kind)
	g._spawn_zombie_at(final_kind,2,g._boss_anchor_x(final_kind),true)
	var boss: Dictionary=g._find_alive_enemy_boss(final_kind)
	var plan: Array=formation(id,tier,style)
	for slot in plan:
		var result: String=Fusion.result(slot.pair[0],slot.pair[1])
		if result.is_empty(): g.violations.append("Missing authored fusion recipe "+str(slot.pair)); continue
		g.grid[slot.row][slot.col]=g._create_plant(result,slot.row,slot.col)
	var authored: Dictionary=Game.TouhouDifficulty.build_level(stage(id),tier)
	var snapshot: Dictionary={"game":g,"boss":boss,"plan":plan,"ledger":ingredient_ledger(plan),"selected":selected,"start_time":g.level_time,"authored_material_pool":authored.available_plants.duplicate()}
	g.violations.append_array(audit(g,true))
	return snapshot

func audit(g: Control,initial: bool=false) -> Array:
	var errors: Array=[]; var bodies:=0
	for layer_name in ["grid","support_grid"]:
		for row in range(g.board_rows):
			for col in range(g.COLS):
				var p=g.get(layer_name)[row][col]
				if p==null: continue
				if String(p.kind)=="lily_pad" and layer_name=="support_grid": continue
				bodies+=1
				var id: String=String(p.get("fusion_kind",""))
				if id.is_empty() or not Game.Defs.PLANTS.has(id): errors.append("SINGLE combat/support plant at %s %d,%d" % [layer_name,row,col]); continue
				var d: Dictionary=Game.Defs.PLANTS[id]
				if p.get("stats",{})!=d: errors.append("Altered offensive/catalog stats: "+id)
				var base: String=String(d.fusion_base)
				if not is_equal_approx(float(p.get("enhance_damage_mult",1)),g._get_enhance_multiplier(base)) or not is_equal_approx(float(p.get("enhance_attack_speed_mult",1)),g._get_enhance_attack_speed_multiplier(base)): errors.append("Altered offensive enhancement multipliers: "+id)
				if initial:
					var normal: Dictionary=g._enhanced_plant_stats(base)
					var hp: float=float(d.health)*float(normal.health)/float(Game.Defs.PLANTS[base].health)
					if absf(float(p.max_health)-hp)>0.001 or absf(float(p.health)-hp)>0.001: errors.append("Artificial initial HP boost: "+id)
					var armor: float=float(d.health) if base=="pumpkin" else 0.0
					if absf(float(p.get("max_armor_health",0))-armor)>0.001 or absf(float(p.get("armor_health",0))-armor)>0.001: errors.append("Artificial initial armor boost: "+id)
					if float(p.ultimate_charge)!=0.0 or float(p.get("holy_invincible_timer",0.0))>0.0: errors.append("Artificial initial charge/invulnerability: "+id)
	if bodies>24: errors.append("More than twenty-four developed fusion bodies")
	return errors

func _available(g: Control,a: String,b: String) -> bool:
	if not g.active_cards.has(a) or not g.active_cards.has(b): return false
	if g._is_conveyor_level(): return g.active_cards.count(a)>=2 if a==b else true
	return float(g.card_cooldowns.get(a,0))<=0.01 and float(g.card_cooldowns.get(b,0))<=0.01 and g.sun_points>=g._endless_cost_for_kind(a)+g._endless_cost_for_kind(b)

func occupied_cards(cards: Array) -> int:
	return cards.filter(func(seed): return String(seed)!="").size()

func _prepared_purchase(g: Control,pair: Array,cell: Vector2i) -> bool:
	var a: String=String(pair[0]); var b: String=String(pair[1])
	if not _available(g,a,b): return false
	var fusion=g._ensure_plant_fusion(); var before_cards: Array=g.active_cards.duplicate(); var before_sun: int=g.sun_points
	fusion.reset(); g.selected_tool="fusion"; fusion.select_seed(a); fusion.select_seed(b)
	if fusion.prepared_result.is_empty(): fusion.reset(); g.selected_tool=""; return false
	if not fusion.prepared_error(cell.x,cell.y).is_empty(): fusion.reset(); g.selected_tool=""; return false
	g._handle_board_click(cell)
	var p=g._targetable_plant_at(cell.x,cell.y)
	var success: bool=p!=null and p.has("fusion_kind") and (occupied_cards(before_cards)-occupied_cards(g.active_cards)==2 if g._is_conveyor_level() else g.sun_points<before_sun)
	if not success: return false
	if g._is_conveyor_level():
		for ingredient in [a,b]:
			var needed:=2 if a==b else 1
			if g.active_cards.count(ingredient)!=before_cards.count(ingredient)-needed: g.violations.append("Fusion repair did not consume its actual belt ingredients")
	else:
		if before_sun-g.sun_points!=g._endless_cost_for_kind(a)+g._endless_cost_for_kind(b): g.violations.append("Fusion repair bypassed native seed prices")
		if float(g.card_cooldowns.get(a,0))<=0.01 or float(g.card_cooldowns.get(b,0))<=0.01: g.violations.append("Fusion repair bypassed native seed cooldowns")
	g.paid_actions.append({"time":g.level_time,"action":"fusion_pair","pair":pair,"cell":[cell.x,cell.y],"sun_spent":before_sun-g.sun_points,"belt_spent":occupied_cards(before_cards)-occupied_cards(g.active_cards) if g._is_conveyor_level() else 0,"result":p.fusion_kind})
	return true

func _graft(g: Control,seed: String,cell: Vector2i) -> bool:
	if not g.active_cards.has(seed): return false
	if not g._is_conveyor_level() and (g.sun_points<g._endless_cost_for_kind(seed) or float(g.card_cooldowns.get(seed,0))>0.01): return false
	var recipe: Dictionary=g._ensure_plant_fusion().candidate(seed,cell.x,cell.y)
	if recipe.is_empty() or not g._placement_error(seed,cell.x,cell.y).is_empty(): return false
	var before: int=g.active_cards.count(seed); var before_sun: int=g.sun_points
	g.selected_tool=seed; g._handle_board_click(cell)
	var consumed: bool=g.active_cards.count(seed)==before-1 if g._is_conveyor_level() else g.sun_points==before_sun-g._endless_cost_for_kind(seed)
	if not consumed: g.violations.append("A graft used an undelivered/unpaid seed"); return false
	g.paid_actions.append({"time":g.level_time,"action":"graft","seed":seed,"cell":[cell.x,cell.y],"sun_spent":before_sun-g.sun_points,"belt_spent":1 if g._is_conveyor_level() else 0})
	return true

func _pressure(g: Control,row: int) -> float:
	var score:=0.0
	for z in g.zombies:
		if g._is_enemy_zombie(z) and float(z.health)>0 and g._zombie_has_row(z,row): score+=1.0+maxf(0,6.0-(float(z.x)-g.BOARD_ORIGIN.x)/g.CELL_SIZE.x)
	return score

func act(g: Control,plan: Array,boss: Dictionary) -> void:
	var missing: Array=plan.filter(func(slot): return g._targetable_plant_at(slot.row,slot.col)==null)
	missing.sort_custom(func(a,b): return _pressure(g,a.row)+(8.0 if a.role=="reveal" else 0.0)>_pressure(g,b.row)+(8.0 if b.role=="reveal" else 0.0))
	for slot in missing:
		if _prepared_purchase(g,slot.pair,Vector2i(slot.row,slot.col)): continue
		if not g._is_conveyor_level(): continue
		# Inventory-matched alternatives prevent rare-seed waiting from clogging
		# the real belt. Every alternative still arrives as a two-seed fusion.
		for pair in [["repeater","wallnut"],["melon_pult","wallnut"],["snow_pea","healing_gourd"],["kernel_pult","umbrella_leaf"],["threepeater","wallnut"],["starfruit","wallnut"],["cactus","wallnut"],["melon_pult","torchwood"],["repeater","repeater"],["wallnut","healing_gourd"]]:
			if slot.role=="reveal" and pair[1]!="plantern": continue
			if _prepared_purchase(g,pair,Vector2i(slot.row,slot.col)): break
	if g._is_conveyor_level() and occupied_cards(g.active_cards)>=Game.MAX_SEED_SLOTS-2:
		for seed in g.active_cards.duplicate():
			if String(seed)=="" or String(seed) in Fusion.EXCLUDED: continue
			var candidates: Array=plan.duplicate()
			candidates.sort_custom(func(a,b):
				var pa=g._targetable_plant_at(a.row,a.col); var pb=g._targetable_plant_at(b.row,b.col)
				if pa==null: return false
				if pb==null: return true
				return float(pa.health)/maxf(1,float(pa.max_health))<float(pb.health)/maxf(1,float(pb.max_health)))
			for slot in candidates:
				var p=g._targetable_plant_at(slot.row,slot.col)
				if p==null or not p.has("fusion_kind"): continue
				if _graft(g,seed,Vector2i(slot.row,slot.col)): break
	var used:=0
	for offset in range(plan.size()):
		var slot: Dictionary=plan[(policy_cursor+offset)%plan.size()]; var p=g._targetable_plant_at(slot.row,slot.col)
		if p==null: continue
		var injured: bool=float(p.health)/maxf(1,float(p.max_health))<0.65
		var urgent: bool=_pressure(g,slot.row)>4.0 or injured
		if not urgent and bool(boss.get("touhou_encounter",{}).get("depleted",false)): continue
		if g._try_activate_ultimate(slot.row,slot.col): used+=1
		if used>=2: policy_cursor=(policy_cursor+offset+1)%plan.size(); break

func source_manifest() -> Dictionary:
	var files: Dictionary={}
	for file in SOURCES: files[file]=FileAccess.get_sha256("res://"+file)
	return {"loaded_extra_damage":Game.TouhouDifficulty.WIND_GOD_DAMAGE,"loaded_boss_source":Game.TouhouDifficulty.outgoing_damage_multiplier("aya_boss"),"files_sha256":files,"controller_sha256":{"scripts/tools/wind_god_fusion_balance.gd":FileAccess.get_sha256("res://scripts/tools/wind_god_fusion_balance.gd"),"tests/wind_god_fusion_balance_test.gd":FileAccess.get_sha256("res://tests/wind_god_fusion_balance_test.gd")}}

func release(g: Control) -> void:
	g._stop_bgm()
	if g.music_player!=null: g.music_player.stream=null
	for player in g.sfx_players: player.stop(); player.stream=null
	g.dead_refs.clear(); g.save_dirty=false
	await tree.create_timer(0.2).timeout; g.free(); await tree.create_timer(0.2).timeout; await tree.process_frame

func run_case(id: String,tier: String,style: String,seed: int,cap: float,wall_seconds: float,manifest: Dictionary) -> Dictionary:
	policy_cursor=0
	var snapshot: Dictionary=setup(id,tier,style,seed); var g: Control=snapshot.game; var b: Dictionary=snapshot.boss
	var beginning: float=g.level_time; var started: int=Time.get_ticks_msec(); var peak:=0; var peak_body:=0; var outcome:="simulation_cap"; var progress:=0.0
	if b.is_empty(): g.violations.append("The actual full finale did not spawn")
	for frame in range(ceili(cap/0.05)*2):
		if not g.violations.is_empty(): outcome="invalid_fixture"; break
		if frame%10==0:
			act(g,snapshot.plan,b); g.violations.append_array(audit(g))
		if frame%30==0: await tree.process_frame
		g._process(0.05); peak=maxi(peak,g._active_zombie_count())
		var bodies:=0
		for row in g.grid:
			for p in row:
				if p!=null and p.has("fusion_kind"): bodies+=1
		peak_body=maxi(peak_body,bodies)
		if g.battle_state==g.BATTLE_WON: outcome="won"; break
		if g.battle_state==g.BATTLE_LOST: outcome="lost"; break
		if g.level_time-beginning>=cap: break
		if float(Time.get_ticks_msec()-started)/1000.0>=wall_seconds: outcome="wall_cap"; break
		if g.level_time-beginning>=progress+120.0:
			progress=g.level_time-beginning
			print("Fusion %s %s %s %.1fs phase=%d/%d bodies=%d losses=%d mowers=%d" % [id,tier,style,progress,int(b.touhou_encounter.index)+1,b.touhou_encounter.phases.size(),bodies,g.dead_fusions.size(),g.mowers.filter(func(m): return not bool(m.armed)).size()])
	var ids: Array=[]
	for declaration in g.declarations:
		if not ids.has(declaration.card): ids.append(declaration.card)
	var result: Dictionary={"stage":id,"tier":tier,"style":style,"seed":seed,"policy":"fusion-only-v2-fixed-slot-bank","prepared_development_snapshot":true,"initial_charge":0.0,"initial_ledger":snapshot.ledger,"manual_selected":snapshot.selected if tier=="lunatic" else [],"loaded_extra_damage":manifest.loaded_extra_damage,"source_manifest":manifest,"outcome":outcome,"elapsed_seconds":g.level_time-beginning,"wall_seconds":float(Time.get_ticks_msec()-started)/1000.0,"battle_state":g.battle_state,"phase":int(b.get("touhou_encounter",{}).get("index",-1))+1,"phases":b.get("touhou_encounter",{}).get("phases",[]).size(),"boss_hp":b.get("health",-1),"boss_complete":b.get("touhou_encounter",{}).get("complete",false),"declared_cards":ids,"declarations":g.declarations,"fusion_losses":g.dead_fusions.size(),"losses":g.dead_fusions,"damaged_rows":g.damaged_rows.keys(),"used_mowers":g.mowers.filter(func(m): return not bool(m.armed)).size(),"peak_active_enemies":peak,"reinforcement_spawns":g.reinforcements,"reinforcement_calls":g.reinforcement_calls,"campaign_fusions":g.campaign_fusions,"peak_fusion_bodies":peak_body,"earned_ultimates":g.ultimates,"ultimate_inputs":g.ultimate_inputs,"paid_actions":g.paid_actions,"ending_sun":g.sun_points,"actual_incoming_plant_damage":g.damage_to_plants,"actual_outgoing_boss_damage":g.damage_to_boss,"loss_reason":g.loss_reason,"breach":g.breach,"structural_violations":g.violations,"final_audit":audit(g)}
	print("FUSION_RESULT "+JSON.stringify(result))
	await release(g)
	return result
