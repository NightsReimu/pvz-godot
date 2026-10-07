extends SceneTree
const Fixture = preload("res://tests/fixtures/touhou_damage_game.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const Game = preload("res://scripts/game.gd")
const BASELINE := "res://tests/fixtures/touhou_attack_v177.json"
var failures := 0

func expected_source_multiplier(kind: String) -> float:
	if kind in ["normal","day_boss","catapult_zombie"]: return 1.0
	if kind in ["shizuha_boss","minoriko_boss","hina_boss","nitori_boss","momiji_boss","aya_boss","sanae_boss","sanae_frog","aki_harvest_basket","hina_misfortune_doll","nitori_cucumber"]: return 7.5
	return 5.0

func check(condition: bool, message: String) -> void:
	if not condition: failures += 1; push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func probe(path: String, choice: String) -> Dictionary:
	var kind: String = {"bullet":"cirno_boss","beam":"marisa_boss","suika_stomp":"suika_boss","aki_harvest":"minoriko_boss","nitori_jet":"nitori_boss","drain":"remilia_boss","meiling_phase":"meiling_boss","ordinary_bite":"normal","ordinary_catapult":"catapult_zombie"}[path]
	var g = Fixture.new(); g.configure(kind,choice)
	var col := 7 if path == "meiling_phase" else 4
	var p: Dictionary = g.add_plant(2,col)
	var before := {"health":float(p.health),"armor":float(p.armor_health)}
	var boss: Dictionary = g.add_boss(kind)
	boss.boss_phase = 2
	match path:
		"bullet", "beam":
			boss.touhou_owner = 1
			var dm = Game.TouhouDanmakuRuntime.new(g)
			var center: Vector2 = g._cell_center(2,col)+Vector2(0,-12)
			var c := {"owner":1,"kind":kind,"phase":2,"wave":0}
			if path == "bullet": dm._bullet(c,center+Vector2(10,0),PI,100.0,Color.WHITE)
			else: dm._beam(c,center+Vector2(10,0),center-Vector2(10,0),Color.WHITE,0.0)
			dm.update(0.2)
		"suika_stomp":
			var rt = g._ensure_suika_runtime(); rt.queue_impact(int(boss.uid),Vector2i(2,col),"stomp",0.8); rt.update(0.81)
		"aki_harvest":
			var rt = g._ensure_aki_runtime(); rt.queue_field(int(boss.uid),Vector2i(2,col),"ripening",1.2); rt.update(7.3)
		"nitori_jet":
			var rt = g._ensure_nitori_runtime(); rt.queue_jet(int(boss.uid),2)
			rt.jets[0].age = rt.JET_WARNING+rt.JET_SWEEP*0.7; rt._advance_jet(rt.jets[0])
		"drain": g._update_remilia_crimson_drain(0.5)
		"meiling_phase": g._trigger_meiling_boss_phase_shift(boss,2)
		"ordinary_bite":
			boss.x = g._cell_center(2,col).x+20.0; boss.special_pause_timer=0.0; g._update_zombies(0.25)
		"ordinary_catapult":
			boss.catapult_cooldown=0.0; boss.special_pause_timer=0.0; g._update_zombies(0.25)
	var result := {"path":path,"kind":kind,"choice":choice,"before":before,"after":{"health":float(p.health),"armor":float(p.armor_health)},"removed":float(before.health)+float(before.armor)-g.vitality(p)}
	g.save_dirty=false; g.free()
	return result

func direct_probe(path: String, choice: String) -> float:
	var kind: String={"keine_segment":"keine_boss","marisa_glare":"marisa_boss","reisen_eye":"reisen_boss","reisen_eclipse":"reisen_boss","eirin_strike":"eirin_boss","kaguya_mark":"kaguya_boss","owned_lava":"kaguya_boss","suika_mini_bite":"suika_boss","ordinary_generic":"normal"}[path]
	var g=Fixture.new(); g.configure(kind,choice)
	var p: Dictionary=g.add_plant(); var before: float=g.vitality(p)
	var b: Dictionary=g.add_boss(kind); b.boss_phase=3
	match path:
		"keine_segment":
			var rt=g._ensure_keine_runtime(); var point: Vector2=g._cell_center(2,4)+Vector2(0,-12)
			rt._hit_segment(point+Vector2(10,0),point-Vector2(10,0),5.0,100.0,[])
		"marisa_glare":
			var rt=g._ensure_marisa_runtime(); rt.queue_tile(b,Vector2i(2,4),"glare",1.2); rt.update(1.4)
		"reisen_eye":
			var rt=g._ensure_reisen_runtime(); rt.queue_eye(b,Vector2i(2,4),1.25); rt.update(1.3)
		"reisen_eclipse":
			var rt=g._ensure_reisen_runtime(); rt.start_eclipse(b,true); rt.update(2.6)
		"eirin_strike":
			var rt=g._ensure_eirin_runtime(); rt.queue_strike(b,Vector2i(2,4),100.0,"eirin_arrow"); rt.update(1.9)
		"kaguya_mark":
			var rt=g._ensure_kaguya_runtime(); rt.mark(b,Vector2i(2,4),"dragon",100.0,2.0); rt.update(2.1)
		"owned_lava":
			var rt=g._ensure_eirin_runtime(); rt.tiles.append({"owner":int(b.uid),"cell":Vector2i(2,4),"kind":"lava","age":0.0,"active":false,"tick":0.0,"previous":"land"}); rt.update(2.1)
		"suika_mini_bite":
			g._ensure_suika_runtime().spawn_mini(int(b.uid),2)
			var mini: Dictionary=g.zombies.back(); mini.x=g._cell_center(2,4).x+20.0; mini.special_pause_timer=0.0; g._update_zombies(0.25)
		"ordinary_generic": g._damage_plant_cell(2,4,100.0)
	var removed: float=before-g.vitality(p)
	g.save_dirty=false; g.free()
	return removed

func supplemental(old: Dictionary) -> void:
	var raw := {"keine_segment":100.0,"marisa_glare":2.0,"reisen_eye":72.0,"reisen_eclipse":110.0,"eirin_strike":100.0,"kaguya_mark":100.0,"owned_lava":55.0}
	var samples: Array=[]
	for choice in Difficulty.PROFILES:
		var legacy: float=0.0
		for row in old.scaling:
			if row.kind=="normal" and row.choice==choice and int(row.phase)==0 and not bool(row.beam): legacy=float(row.factor); break
		check(legacy>0.0,"Read the unchanged captured v177 untuned difficulty factor")
		for path in raw:
			var removed: float=direct_probe(path,choice)
			check(removed>0.0 and absf(removed-float(raw[path])*legacy*5.0)<0.01,"%s %s native direct damage is v177 untuned difficulty ×source5 only: %.4f" % [choice,path,removed])
			samples.append({"path":path,"choice":choice,"removed":removed,"v177_authored_raw":raw[path],"v177_untuned":legacy})
		var bite: float=direct_probe("suika_mini_bite",choice)
		var old_bite: float=0.0
		for row in old.native_melee:
			if row.choice==choice: old_bite=float(row.removed); break
		check(old_bite>0.0 and absf(bite-old_bite*5.0)<0.01,"Owned Suika mini actual native melee scales archived v177 loss fivefold once, preserving spawn tuning (%.3f -> %.3f)" % [old_bite,bite])
		var ordinary: float=direct_probe("ordinary_generic",choice)
		check(absf(ordinary-100.0*legacy)<0.01,"A generic/ordinary plant-cell hit in a Touhou stage keeps its v177 difficulty only")
	for kind in Difficulty.OWNED_ATTACK_SOURCES:
		check(is_equal_approx(Difficulty.outgoing_damage_multiplier(kind),expected_source_multiplier(kind)),"Intrinsic owned source %s follows its authored Boss amplification exactly once" % kind)
	for kind in ["normal","conehead","cone_star_fairy","bucket_kedama","day_boss"]:
		check(is_equal_approx(Difficulty.outgoing_damage_multiplier(kind),1.0),"Ordinary enemy/equipment kind %s gets no Touhou source damage boost" % kind)
	var f:=FileAccess.open("res://output/v178/attack-supplemental.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"samples":samples,"failures":failures},"\t")+"\n")

func _run() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture-v177")
	var records: Array = []
	for choice in ["easy","normal","hard","lunatic","extra","extra_plus"]:
		for path in ["bullet","beam","suika_stomp","aki_harvest","nitori_jet","drain","meiling_phase","ordinary_bite","ordinary_catapult"]:
			records.append(probe(path,choice))
			check(float(records.back().removed)>0.0,"Native %s %s reaches real plant health/armor" % [choice,path])
	var scaling: Array = []
	for kind in Difficulty.boss_kinds()+["tewi_boss","normal","day_boss"]:
		for choice in Difficulty.PROFILES:
			for phase in [0,3]:
				for beam in [false,true]: scaling.append({"kind":kind,"choice":choice,"phase":phase,"beam":beam,"factor":Difficulty.attack_damage(kind,{"touhou_difficulty":choice},phase,beam)})
	if capture:
		check(false,"The archived v177 fixture is immutable; current production must never overwrite its paired baseline")
	else:
		var old = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
		check(old!=null,"Read immutable v177 paired native baseline")
		if old!=null:
			for i in range(records.size()):
				var r: Dictionary = records[i]; var b: Dictionary = old.records[i]
				var ratio := expected_source_multiplier(String(r.kind))
				check(absf(float(r.removed)-float(b.removed)*ratio)<0.01,"%s %s native health+armor removes exactly v177 ×%.1f (%.3f -> %.3f)" % [r.choice,r.path,ratio,b.removed,r.removed])
			for r in scaling:
				# Later authored Bosses are absent from the immutable v177 roster;
				# compare every archived sample by identity, not shifted array index.
				var matches: Array = old.scaling.filter(func(b): return b.kind==r.kind and b.choice==r.choice and int(b.phase)==int(r.phase) and bool(b.beam)==bool(r.beam))
				if matches.is_empty():
					check(String(r.kind) in ["momiji_boss","aya_boss","sanae_boss"] and Difficulty.outgoing_damage_multiplier(String(r.kind))==7.5,"New Tengu definitions use the Wind God source amplification: "+String(r.kind))
					continue
				var b: Dictionary = matches[0]
				var ratio := expected_source_multiplier(String(r.kind))
				check(absf(float(r.factor)-float(b.factor)*ratio)<0.0001,"%s %s phase%d beam%s attack source factor must scale once ×%.1f" % [r.kind,r.choice,r.phase,r.beam,ratio])
		supplemental(old)
		print("Touhou attack strength: %d paired native paths and %d source factors; %d failure(s)" % [records.size(),scaling.size(),failures])
	call_deferred("quit",1 if failures else 0)
