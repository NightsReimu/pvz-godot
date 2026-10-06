extends SceneTree
const Fixture = preload("res://tests/fixtures/touhou_damage_game.gd")
const Game = preload("res://scripts/game.gd")
const Phase = preload("res://scripts/runtime/touhou_phase_runtime.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition: failures += 1; push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _formal(boss: Dictionary, level: Dictionary) -> Dictionary:
	for phase in Spells.phases_for(String(boss.kind),level):
		for entry in phase:
			var card: Dictionary = Spells.card_from_entry(entry)
			if String(card.origin) in ["canon","original"] and not String(card.pattern).begins_with("nonspell_") and not bool(card.get("survival",false)):
				return card
	return {}

func factor(boss: Dictionary) -> float:
	var api = Phase.new()
	return float(api.call("spell_damage_factor",boss)) if api.has_method("spell_damage_factor") else 1.0

func bind_card(boss: Dictionary, card: Dictionary, active: bool = true) -> void:
	boss.touhou_card = card.duplicate(true)
	boss.touhou_cast_remaining = 2.0 if active else 0.0
	boss.touhou_cast_duration = 3.0
	boss.touhou_invulnerable = false
	if boss.has("touhou_encounter"): boss.touhou_encounter.casting = active

func card_matrix(kind: String, choice: String, level: Dictionary, role: String) -> Dictionary:
	var g = Fixture.new(); g.configure(kind,choice); g.current_level=level
	var b: Dictionary = g.add_boss(kind)
	if role == "road":
		b.touhou_road_boss=true
		b.touhou_final_preview=bool(level.get("mid_boss_final_preview",false))
		Phase.start(b,level)
	var declared := 0; var nonspells := 0; var checked_ids: Array=[]
	if b.has("touhou_encounter"):
		var phases: Array = b.touhou_encounter.phases
		for pi in range(phases.size()):
			for ai in range(phases[pi].size()):
				b.touhou_encounter.index=pi; b.touhou_encounter.attack=ai; b.touhou_encounter.depleted=false; b.touhou_encounter.complete=false
				Phase._set_bounds(b); b.health=b.touhou_encounter.ceiling
				var card: Dictionary=Spells.card_for(b,level)
				bind_card(b,card)
				var formal := String(card.get("origin","")) in ["canon","original"] and not String(card.get("pattern","")).begins_with("nonspell_")
				var expected := 0.25 if formal else 1.0
				check(is_equal_approx(factor(b),expected),"%s %s %s %s has the exact formal-card factor" % [kind,choice,role,card.id])
				var before: float=float(b.health)
				g._apply_zombie_damage(b,40.0,0.12,0.0,true)
				check(absf(before-float(b.health)-40.0*expected)<0.001,"%s %s %s %s true bypass-shield damage preserves spell resistance" % [kind,choice,role,card.id])
				if formal: declared+=1
				else: nonspells+=1
				checked_ids.append(String(card.id))
	g.save_dirty=false; g.free()
	return {"kind":kind,"choice":choice,"role":role,"formal":declared,"nonspell":nonspells,"cards":checked_ids}

func inactive_and_lifecycle() -> void:
	var g=Fixture.new(); g.configure("cirno_boss","easy")
	var b: Dictionary=g.add_boss("cirno_boss")
	var card: Dictionary=_formal(b,g.current_level)
	for mode in ["expired","negative_timer","missing_card","empty_card","nonspell_origin","nonspell_pattern","missing_origin","missing_pattern","pending","recovery","dead","completed","changed_kind"]:
		var z: Dictionary=b.duplicate(true); bind_card(z,card); z.health=z.max_health
		match mode:
			"expired": z.touhou_cast_remaining=0.0
			"negative_timer": z.touhou_cast_remaining=-0.1
			"missing_card": z.erase("touhou_card")
			"empty_card": z.touhou_card={}
			"nonspell_origin": z.touhou_card.origin="nonspell"
			"nonspell_pattern": z.touhou_card.pattern="nonspell_fake"
			"missing_origin": z.touhou_card.erase("origin")
			"missing_pattern": z.touhou_card.erase("pattern")
			"pending": z.touhou_cast_remaining=0.0; z.boss_cast_pending=true
			"recovery": z.touhou_cast_remaining=0.0; z.boss_pause_timer=1.0
			"dead": z.health=0.0
			"completed": z.touhou_encounter.complete=true
			"changed_kind": z.kind="normal"
		check(is_equal_approx(factor(z),1.0),"%s cannot retain a formal-card damage reduction" % mode)
		if mode not in ["dead","completed"]:
			var before: float=float(z.health); g._apply_zombie_damage(z,40.0,0.12,0.0,true)
			check(absf(before-float(z.health)-40.0)<0.001,"%s real native damage remains unmodified" % mode)
	bind_card(b,card); var before: float=float(b.health)
	b.touhou_invulnerable=true; g._apply_zombie_damage(b,100000.0,0.12,0.0,true)
	check(is_equal_approx(float(b.health),before),"Existing survival invulnerability still rejects bypass-shield attacks")
	b.touhou_invulnerable=false
	g._apply_zombie_damage(b,1.0e9,0.12,0.0,true)
	check(b.touhou_encounter.depleted and absf(float(b.health)-float(b.touhou_encounter.floor)-0.01)<0.001,"Huge scaled hits retain the mandatory native phase floor")
	var phases: Array=b.touhou_encounter.phases
	b.touhou_cast_remaining=0.0; b.touhou_encounter.casting=false; b.touhou_encounter.completed=phases[0].size()
	Phase.update_progress(g,b)
	check(int(b.touhou_encounter.index)==1 and is_equal_approx(factor(b),1.0),"Actual phase transition resets resistance until another declared active cast")
	var ran: Dictionary=g.add_boss("ran_boss"); bind_card(ran,_formal(ran,g.current_level))
	var successor: Dictionary=g._trigger_ran_boss_successor(ran)
	check(String(successor.kind)=="yukari_boss" and is_equal_approx(factor(successor),1.0),"Actual Ran-to-Yukari successor retains no old active resistance")
	var yuyuko: Dictionary=g.add_boss("yuyuko_boss"); bind_card(yuyuko,_formal(yuyuko,g.current_level))
	yuyuko=g._trigger_yuyuko_boss_revival(yuyuko)
	check(bool(yuyuko.yuyuko_revived) and String(yuyuko.touhou_card.pattern)=="resurrection_butterfly" and bool(yuyuko.touhou_invulnerable),"Actual Yuyuko revival declares her own existing survival card")
	before=float(yuyuko.health); g._apply_zombie_damage(yuyuko,1.0e6,0.12,0.0,true)
	check(is_equal_approx(float(yuyuko.health),before),"Revival keeps existing survival invulnerability instead of an old vulnerability")
	yuyuko.touhou_cast_remaining=0.0; yuyuko.touhou_invulnerable=false
	check(is_equal_approx(factor(yuyuko),1.0),"Expired resurrection cast does not retain quarter damage")
	g.save_dirty=false; g.free()

func native_sample(path: String, active: bool, ordinary: bool=false) -> Dictionary:
	seed(1 if path == "ultimate_meteor_flower" else 178) # Paired actual meteor/chaos hits use repeatable global RNG.
	var g=Fixture.new(); g.configure("cirno_boss","easy")
	g.legacy_food_path = path.begins_with("food_")
	var b: Dictionary=g.add_boss("normal" if ordinary else "cirno_boss")
	var formal: Dictionary=_formal({"kind":"cirno_boss"},g.current_level)
	bind_card(b,formal,active)
	# Isolate incoming routing from mandatory floor gates and overkill; their
	# actual phase runtime is independently tested above with a billion hit.
	b.erase("touhou_encounter")
	b.x=g._cell_center(2,4).x+70.0
	var before: float=float(b.health)
	var plant_kind: String=path.trim_prefix("ultimate_") if path.begins_with("ultimate_") else (path.trim_prefix("food_") if path.begins_with("food_") else "peashooter")
	if path in ["mirror","bounce"]: plant_kind="mirror_reed"
	if path in ["fusion_ash","fusion_ultimate"]: plant_kind=g._ensure_plant_fusion().Fusion.result("peashooter","cherry_bomb")
	var p: Dictionary=g._create_plant(plant_kind,2,4); g.grid[2][4]=p
	match path:
		"projectile":
			g._spawn_projectile(2,Vector2(float(b.x)-30.0,g._row_center_y(2)-12),Color.WHITE,40.0,0.0,100.0,7.0,"peashooter"); g._update_projectiles(0.2)
		"cherry": g._explode_cherry(2,4)
		"doom": g._trigger_doom_shroom(2,4)
		"mirror": g._reflect_shot_with_mirror_reed(b,Vector2i(2,4),Vector2(float(b.x),g._row_center_y(2)),40.0)
		"bounce":
			var dm=Game.TouhouDanmakuRuntime.new(g)
			var shot: Dictionary={"damage":40.0,"velocity":Vector2(-100,0),"position":g._cell_center(2,4),"reflected":false}
			g._bounce_boss_danmaku(shot,Vector2i(2,4),true)
			dm._hit_zombie_segment(Vector2(float(b.x)-10,g._row_center_y(2)-12),Vector2(float(b.x)+10,g._row_center_y(2)-12),7.0,float(shot.damage),shot)
		"fusion_ash":
			for i in range(100):
				g._update_plants(0.05); g._update_projectiles(0.05)
		"fusion_ultimate": g._ensure_plant_fusion().ultimate(p,2,4); g._update_projectiles(0.3)
		_:
			if path.begins_with("food_"): g._ensure_plant_food_runtime().activate(2,4)
			elif path.begins_with("ultimate_"): g._execute_ultimate(p,plant_kind,2,4,{"style":"explicit"})
	var result := {"path":path,"active":active,"ordinary":ordinary,"before":before,"after":float(b.health),"removed":before-maxf(0.0,float(b.health))}
	g.save_dirty=false; g.free()
	return result

func native_source_pairs() -> Array:
	var records: Array=[]
	for path in ["projectile","cherry","doom","mirror","bounce","fusion_ash","fusion_ultimate","food_chomper","food_vine_lasher","ultimate_void_shroom","ultimate_phoenix_tree","ultimate_thunder_god","ultimate_glow_ivy","ultimate_rock_armor_fruit","ultimate_blast_pomegranate","ultimate_meteor_flower","ultimate_abyss_tentacle","ultimate_shadow_assassin","ultimate_core_blossom","ultimate_chaos_shroom"]:
		var plain: Dictionary=native_sample(path,false)
		var protected: Dictionary=native_sample(path,true)
		check(float(plain.removed)>0.0,"Actual %s produces real native Boss damage" % path)
		check(absf(float(protected.removed)-float(plain.removed)*0.25)<0.01,"Actual %s damage cannot bypass or repeat the formal .25 factor (%.2f -> %.2f)" % [path,plain.removed,protected.removed])
		records.append({"path":path,"inactive":plain.removed,"active":protected.removed})
	for path in ["food_chomper","food_vine_lasher"]:
		var plain: Dictionary=native_sample(path,false,true)
		var stale: Dictionary=native_sample(path,true,true)
		check(float(plain.removed)>0.0 and is_equal_approx(float(plain.removed),float(stale.removed)),"%s preserves ordinary zombie damage even with stale formal card metadata" % path)
	var g=Fixture.new(); g.configure("cirno_boss","easy"); var b: Dictionary=g.add_boss("cirno_boss")
	bind_card(b,_formal(b,g.current_level)); b.erase("touhou_encounter")
	var before: float=float(b.health)
	var mower: Dictionary=g.mowers[2]; mower.active=true; mower.armed=false; mower.x=float(b.x)-30.0
	g._update_mowers(0.01)
	var after: float=float(b.health)
	check(absf(before-after-before*0.25)<0.01,"A real mower collision routes one fixed max-health hit through formal resistance")
	g._update_mowers(0.01)
	check(is_equal_approx(float(b.health),after),"The same mower cannot repeatedly overlap a surviving Boss to erase the resistance")
	g.save_dirty=false; g.free()
	return records

func _run() -> void:
	var api=Phase.new(); check(api.has_method("spell_damage_factor"),"Phase runtime exposes the formal-card-only resistance contract")
	var matrix: Array=[]
	for kind in Difficulty.boss_kinds()+["tewi_boss"]:
		for choice in Difficulty.PROFILES:
			matrix.append(card_matrix(kind,choice,{"id":"full-card-contract","terrain":"day","events":[{"kind":kind,"time":100.0}],"touhou_difficulty":choice},"finale"))
	for base in Game.Defs.LEVELS:
		var road: String=String(base.get("mid_boss_kind",""))
		if not road in Difficulty.boss_kinds()+["tewi_boss"]: continue
		for choice in Difficulty.options(base): matrix.append(card_matrix(road,choice,Difficulty.build_level(base,choice),"road"))
	inactive_and_lifecycle()
	var native: Array=native_source_pairs()
	var f:=FileAccess.open("res://output/v178/resistance-coverage.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"matrix":matrix,"native_pairs":native,"failures":failures},"\t")+"\n")
	var formal:=0; var nonspell:=0
	for record in matrix: formal+=int(record.formal); nonspell+=int(record.nonspell)
	print("Touhou spell resistance: %d role/tier bodies, %d real formal cards, %d real nonspells, %d native paired incoming sources; %d failure(s)" % [matrix.size(),formal,nonspell,native.size(),failures])
	call_deferred("quit",1 if failures else 0)
