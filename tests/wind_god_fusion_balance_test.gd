extends SceneTree
const Harness = preload("res://scripts/tools/wind_god_fusion_balance.gd")
var failures:=0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args(); var runner:=Harness.new(self)
	var manifest: Dictionary=runner.source_manifest()
	var variant: String=_arg(args,"--variant","current")
	if variant.begins_with("before") or variant.begins_with("after"):
		check(is_equal_approx(float(manifest.loaded_extra_damage),2.5 if variant.begins_with("before") else 1.5),"Requested comparison variant must match the genuinely preloaded production coefficient")
	if failures: quit(1); return
	var directory: String="res://output/wind-god-fusion-balance/"+variant
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var lock:=FileAccess.open(directory+"/source-lock.json",FileAccess.WRITE); lock.store_string(JSON.stringify(manifest,"\t")+"\n"); lock.close()
	print("FUSION_SOURCE_LOCKED "+JSON.stringify(manifest))
	if not args.has("--run"):
		await _contracts(runner)
		print("Fusion-only native formations, materials, unchanged stats and input contract: %d failure(s)" % failures)
		call_deferred("quit",1 if failures else 0); return
	var chosen_stage: String=_arg(args,"--stage","all"); var chosen_tier: String=_arg(args,"--tier","all"); var chosen_style: String=_arg(args,"--style","all")
	check(chosen_stage=="all" or Harness.STAGES.has(chosen_stage),"CLI stage must select an authored Wind God stage")
	check(chosen_tier=="all" or Harness.TIERS.has(chosen_tier),"CLI tier must select an actual difficulty")
	check(chosen_style=="all" or Harness.STYLES.has(chosen_style) or chosen_style=="fortified","CLI style must select a declared fusion cohort")
	if failures: quit(1); return
	var styles: Array=["fortified"] if chosen_style=="fortified" else Harness.STYLES
	var cap: float=float(_arg(args,"--cap","450")); var wall: float=float(_arg(args,"--wall-seconds","90")); var seed: int=int(_arg(args,"--seed","180906"))
	var results: Array=[]
	for id in Harness.STAGES:
		if chosen_stage!="all" and chosen_stage!=id: continue
		for tier in Harness.TIERS:
			if chosen_tier!="all" and chosen_tier!=tier: continue
			for style in styles:
				if chosen_style!="all" and chosen_style!=style: continue
				var result: Dictionary=await runner.run_case(id,tier,style,seed,cap,wall,manifest)
				results.append(result)
				var file:=FileAccess.open(directory+"/%s-%s-%s-%d.json" % [id,tier,style,seed],FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")+"\n"); file.close()
				check(result.structural_violations.is_empty() and result.final_audit.is_empty(),"Real fusion battle must retain native stats, all-fusion bodies and legal resource inputs")
	var summary:=FileAccess.open(directory+"/summary-%s-%s-%s-%d.json" % [chosen_stage,chosen_tier,chosen_style,seed],FileAccess.WRITE)
	summary.store_string(JSON.stringify({"source_lock":manifest,"results":results,"structural_failures":failures},"\t")+"\n"); summary.close()
	print("Fusion native diagnostic cases=%d structural_failures=%d; wins are recorded, not forced" % [results.size(),failures])
	call_deferred("quit",1 if failures else 0)

func _arg(args: PackedStringArray,key: String,fallback: String) -> String:
	var index: int=args.find(key)
	return args[index+1] if index>=0 and index+1<args.size() else fallback

func check(ok: bool,message: String) -> void:
	if not ok: failures+=1; push_error(message)

func _contracts(runner: RefCounted) -> void:
	for id in Harness.STAGES:
		for tier in Harness.TIERS:
			for style in Harness.STYLES:
				var state: Dictionary=runner.setup(id,tier,style,180906); var g: Control=state.game
				check(g.violations.is_empty(),"Prepared "+id+"/"+tier+"/"+style+" uses only native fusion stats/health/zero charge")
				check(state.plan.size()>=12 and state.plan.size()<=24,"Developed cohort has twelve to twenty-four real fusion bodies")
				check(state.selected.size()<=Harness.Game.MAX_SEED_SLOTS,"Every manual choice fits the actual ten-card bank")
				for seed in state.ledger.counts:
					check(state.authored_material_pool.has(seed),"Every initial recipe material belongs to its actual authored stage/tier pool: "+seed)
					if tier!="lunatic": check(g.conveyor_source_cards.has(seed),"Every conveyor snapshot material is genuinely delivered in this stage: "+seed)
				if style=="balanced" and tier=="easy":
					var old=g.grid[0][1]; g.grid[0][1]=g._create_plant("repeater",0,1)
					check(runner.audit(g).any(func(message): return String(message).begins_with("SINGLE")),"The structural guard rejects the old ordinary single-shooter balance fixture")
					g.grid[0][1]=old
					var damage_before: float=float(old.stats.get("damage",0)); old.stats.damage=damage_before+1.0
					check(runner.audit(g).any(func(message): return String(message).contains("offensive")),"The structural guard detects a one-point offensive-stat alteration")
					old.stats.damage=damage_before
					var enhance_before: float=float(old.enhance_damage_mult); old.enhance_damage_mult+=0.1
					check(runner.audit(g).any(func(message): return String(message).contains("offensive enhancement")),"The structural guard rejects a hidden damage multiplier buff")
					old.enhance_damage_mult=enhance_before
					if id=="4-19":
						var pair: Array=[]
						for a in g.active_cards:
							for b in g.active_cards:
								if String(a)=="" or String(b)=="" or not runner._available(g,a,b) or Harness.Fusion.result(a,b).is_empty(): continue
								pair=[a,b]; break
							if not pair.is_empty(): break
						check(not pair.is_empty(),"A real initial conveyor bank has a genuine two-material fusion recipe")
						if not pair.is_empty():
							var before: int=runner.occupied_cards(g.active_cards)
							check(runner._prepared_purchase(g,pair,Vector2i(0,8)),"A real successful prepared fusion purchase is recognized despite the fixed ten-slot belt")
							check(runner.occupied_cards(g.active_cards)==before-2 and g.paid_actions.back().belt_spent==2 and g.grid[0][8].has("fusion_kind"),"The actual pair input consumes and records exactly two delivered seeds and never a single combat crop")
				await runner.release(g)
