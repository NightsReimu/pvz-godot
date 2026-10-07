extends SceneTree

const RUNNER_PATH="res://scripts/tools/wind_god_fusion_route.gd"
var failures:=0

func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error(message)
func argument(args:PackedStringArray,key:String,fallback:String)->String:
	var i:int=args.find(key)
	return args[i+1] if i>=0 and i+1<args.size() else fallback
func run()->void:
	if not ResourceLoader.exists(RUNNER_PATH):
		check(false,"The permanent legal fusion-first full-route runner must exist")
		quit(1);return
	var runner=load(RUNNER_PATH).new(self)
	var args:=OS.get_cmdline_user_args()
	if args.has("--run"):
		var directory:String=argument(args,"--output","res://output/wind-god-fusion-route")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		var result:Dictionary=await runner.run_case(argument(args,"--stage","4-22"),argument(args,"--tier","easy"),int(argument(args,"--seed","1777")),float(argument(args,"--cap","1200")))
		var file:=FileAccess.open(directory+"/"+result.stage+"-"+result.tier+"-"+str(result.seed)+".json",FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"\t")+"\n");file.close()
		check(result.input_failures.is_empty(),"Full route must spend real materials and retain fusion-only combat plants")
		print("FUSION_ROUTE ",JSON.stringify(runner.compact(result)))
		call_deferred("quit",1 if failures else 0);return
	var g=runner.start("4-22","easy",905)
	check(runner.count_cards(g)==3 and g.active_cards.size()==10,"Authored belt starts with3 actual cards in10 held slots")
	var pads:=0
	for row in g.support_grid:
		for p in row:
			if p!=null and String(p.kind)=="lily_pad":pads+=1
	check(pads==12,"Water road begins with exactly12 authored native lily foundations")
	check(g.sun_points==0,"Easy starts with no manufactured sun")
	check(g.grid.all(func(row):return row.all(func(p):return p==null)),"The real combat grid starts empty")
	check(g.mowers.size()==6 and g.mowers.all(func(m):return bool(m.armed) and String(m.kind)=="pool_cleaner"),"Six native water mowers remain armed")
	var audit:Array=[];var spent:Dictionary={};var before:int=runner.count_cards(g)
	runner.place(g,audit,spent)
	check(audit.size()==1 and before-runner.count_cards(g)==2,"The actual initial prepare gesture spends exactly2 delivered seeds")
	check(spent.values().reduce(func(total,value):return total+int(value),0)==2,"Both consumed materials are recorded")
	check(runner.input_failures.is_empty(),"Preparation enforces each actual ingredient multiplicity")
	check(runner.audit_combat_grid(g).is_empty(),"Prepared combat bodies have native fusion identity/stats")
	var planted:Dictionary={}
	for row in g.grid:
		for p in row:
			if p!=null:planted=p;break
		if not planted.is_empty():break
	check(not planted.is_empty(),"The resource-consumption fixture produced a real fusion")
	if not planted.is_empty():
		var catalog_before:Dictionary=planted.stats
		planted.stats=catalog_before.duplicate(true);planted.stats["damage"]=float(planted.stats.get("damage",0))+1.0
		check(runner.audit_combat_grid(g).has("Altered fusion catalogue stats"),"Live-route audit rejects even a one-point catalogue mutation")
		planted.stats=catalog_before
		var mult_before:float=planted.enhance_damage_mult
		planted.enhance_damage_mult=mult_before+0.1
		check(runner.audit_combat_grid(g).has("Altered fusion offensive enhancement"),"Live-route audit rejects a hidden offensive multiplier buff")
		planted.enhance_damage_mult=mult_before
	check(not g._try_activate_ultimate(0,1),"Uncharged native plant/support ultimate is rejected")
	# Run the authored stage clock and all enemies normally; no HP, charge,
	# event, mower, or phase values are injected to make the pad ready.
	for frame in range(900):
		if frame%30==0:await process_frame
		g._process(.05)
	var earned:Dictionary={}
	var earned_cell:=Vector2i(-1,-1)
	for row in g.active_rows:
		for col in range(g.COLS):
			var candidate:Dictionary=g._ready_click_ultimate_candidate_at(int(row),col)
			if not candidate.is_empty() and String(candidate.kind)=="lily_pad":earned=candidate;earned_cell=Vector2i(int(row),col);break
		if not earned.is_empty():break
	check(not earned.is_empty() and float(earned.get("plant",{}).get("ultimate_charge",0))>=1.0,"A lily charge is earned by normal native time/combat")
	if earned_cell.x>=0:
		check(g._try_activate_ultimate(earned_cell.x,earned_cell.y),"Earned lily ultimate follows the real click path")
		var new_pads:=0
		for row in g.support_grid:
			for p in row:
				if p!=null and String(p.kind)=="lily_pad":new_pads+=1
		check(new_pads>pads,"Actual earned pad bloom creates real water foundations")
	check(g.zombies.size()>0 and g.level_time>=44.9,"Structural charge probe retains actual authored enemy spawning and stage time")
	check(runner.audit_combat_grid(g).is_empty(),"Live structural fixture never falls back to ordinary combat plants")
	await runner.release(g)
	var manual=runner.start("4-22","lunatic",905)
	check(manual.active_cards.size()==10,"Lunatic uses a real ten-card selection")
	var legal_pool:Array=manual._resolved_selection_pool_for_level(manual.current_level)
	check(manual.active_cards.all(func(seed):return legal_pool.has(seed)),"Manual bank belongs to actual campaign collection/essentials")
	var paid:Array=[];var paid_materials:Dictionary={};var sun_before:int=manual.sun_points
	runner.place(manual,paid,paid_materials)
	var price:=0
	for seed in paid_materials:price+=int(paid_materials[seed])*manual._endless_cost_for_kind(seed)
	for action in manual.terrain_seed_actions:price+=int(action.sun_spent)
	check(not paid.is_empty() and sun_before-manual.sun_points==price,"Lunatic fusion pairs pay both native seed prices")
	check(paid_materials.keys().all(func(seed):return float(manual.card_cooldowns.get(seed,0))>0),"Every manual fusion material enters its native cooldown")
	var paid_count:int=paid.size()
	runner.place(manual,paid,paid_materials)
	check(paid.size()==paid_count,"Already-spent sun/cooling seeds cannot buy a repeated pair")
	check(runner.input_failures.is_empty() and runner.audit_combat_grid(manual).is_empty(),"Paid manual actions remain legal native fusion bodies")
	await runner.release(manual)
	print("Legal fusion-first route input/charge/mower contracts: ",failures," failures")
	call_deferred("quit",1 if failures else 0)
