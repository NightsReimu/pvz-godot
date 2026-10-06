extends "res://tests/plant_fusion_test.gd"
const Morphology = preload("res://scripts/ui/fusion_plant_morphology.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")

func vitality(z: Dictionary) -> float:
	return maxf(0.0,float(z.health))+maxf(0.0,float(z.get("shield_health",0)))+maxf(0.0,float(z.get("headgear_health",0)))+maxf(0.0,float(z.get("handheld_health",0)))

func measure(id: String, ultimate: bool=false, seconds: float=24.0, close: bool=false) -> Dictionary:
	var g=make_game(); var p: Dictionary=g._create_plant(id,2,1); p.sleep_timer=0; g.grid[2][1]=p
	var targets: Array=[]
	for row in [1,2,3]:
		g._spawn_zombie_at("gargantuar",row,g._cell_center(row,2 if close else 7).x,true)
		var z: Dictionary=g.zombies.back(); z.base_speed=0.0; targets.append(z)
	var before:=0.0
	for z in targets: before+=vitality(z)
	var activated:=false
	if ultimate: p.ultimate_charge=1.0; activated=g._try_activate_ultimate(2,1)
	var opening: int=g.projectiles.size()
	var native_opening: int=0
	var opening_kinds: Array=[]
	for shot in g.projectiles:
		if bool(shot.get("fusion_native",false)): native_opening+=1
		if not opening_kinds.has(String(shot.get("kind",""))): opening_kinds.append(String(shot.get("kind","")))
	var first_two:=0.0
	for frame in range(ceili(seconds/0.05)):
		g._update_ultimate_charges(0.05); g._update_plants(0.05); g._update_projectiles(0.05); g._update_effects(0.05)
		if frame==39:
			var after:=0.0
			for z in targets: after+=vitality(z)
			first_two=before-after
	var after:=0.0
	for z in targets: after+=vitality(z)
	var suns:=0
	for sun in g.suns: suns+=int(sun.get("value",25))
	var result: Dictionary={"id":id,"damage":before-after,"first_two":first_two,"opening":opening,"native_opening":native_opening,"opening_kinds":opening_kinds,"health":p.max_health,"armor":p.get("armor_health",0),"sun":suns,"activated":activated,"cooldown":p.get("ultimate_cooldown",0)}
	dispose(g); return result

func twin_roles() -> void:
	for source in ["cactus","snow_pea","starfruit","melon_pult","electric_bonk_choy"]:
		var close: bool=source=="electric_bonk_choy"
		var single: Dictionary=measure(source,false,24.0,close)
		var twin: Dictionary=measure(Fusion.result(source,source),false,24.0,close)
		check(float(single.damage)>0.0 and float(twin.damage)>=float(single.damage)*1.7,"Two actual %s materials produce visibly stronger native output: %.2f -> %.2f" % [source,single.damage,twin.damage])
	var single: Dictionary=measure("cactus",true,3.0)
	var twin: Dictionary=measure(Fusion.result("cactus","cactus"),true,3.0)
	check(float(twin.damage)>=float(single.damage)*1.5,"Twin cactus's actual clicked native ultimate is stronger than a single plant (%.2f -> %.2f)" % [single.damage,twin.damage])
	for source in ["wallnut","tallnut","healing_gourd"]:
		var g=make_game(); var p: Dictionary=g._create_plant(Fusion.result(source,source),2,1)
		check(float(p.max_health)>=float(Native.PLANTS[source].health)*1.8,"Twin %s has materially greater native durability" % source)
		dispose(g)
	for source in ["cherry_bomb","jalapeno"]:
		var normal: Dictionary=measure(source,false,3.0,true)
		var pair: Dictionary=measure(Fusion.result(source,source),false,3.0,true)
		check(float(pair.first_two)>0.0 and float(pair.damage)>=float(normal.damage)*1.5,"Two %s ingredients have an actual prompt native-fuse impact instead of a hidden initial reload (%.2f -> %.2f)" % [source,normal.damage,pair.damage])
	var sun_single: Dictionary=measure("sunflower",false,24.0)
	var sun_pair: Dictionary=measure(Fusion.result("sunflower","sunflower"),false,24.0)
	check(int(sun_pair.sun)>=int(sun_single.sun)*2 and int(sun_pair.sun)<=int(sun_single.sun)*3,"Twin sunflower already has two materials' real production; do not indiscriminately multiply it again")

func shooter_openings() -> void:
	for source in ["peashooter","cactus","starfruit","melon_pult"]:
		for partner in ["sunflower","healing_gourd","chomper","cherry_bomb","wallnut","torchwood","magnet_shroom","jasmine_tea"]:
			var id: String=Fusion.result(source,partner)
			var actual: Dictionary=measure(id,true,3.0)
			check(bool(actual.activated) and int(actual.opening)>=3,"%s+%s true click opens a real native volley, not one ordinary shot (%d)" % [source,partner,actual.opening])
			check(int(actual.native_opening)>=3,"%s+%s first frame retains the ingredient's real native weapon" % [source,partner])
			check(float(actual.damage)>0.0,"%s+%s follows the real native projectile/impact route after activation" % [source,partner])

func catalogue_and_charge() -> void:
	var g=make_game()
	var count:=0
	for source in Native.ORDER:
		if source in Fusion.EXCLUDED or source in Fusion.UNOBTAINABLE: continue
		var id: String=Fusion.result(source,source)
		check(not id.is_empty(),"Every legal same-material catalogue entry has a real recipe: "+source)
		if id=="repeater": continue # Existing canonical two-head pea remains native.
		var d: Dictionary=Defs.PLANTS[id]
		check(int(d.get("fusion_repeat_count",0))>=2 and bool(d.get("fusion_same_species",false)),"Mono-material strength has explicit scoped metadata: "+source)
		check(Morphology.svg_for(id,d).contains('data-organ="twin"'),"Two visible native organs identify the repeated ingredient: "+source)
		count+=1
		check(float(d.health)>=float(Native.PLANTS[d.fusion_weights.keys()[0]].health)*1.8,"All repeated-material bodies have substantive durability: "+source)
		check(String(d.fusion_summary).contains("器官") and String(d.fusion_ultimate_description).contains("器官"),"The actual player's summary and ultimate describe repeated organs: "+source)
		if source in ["cactus","starfruit","healing_gourd"]:
			g.plant_stars[source] = 1 # The real catalogue only shows collected seeds.
			check("；".join(d.fusion_combat_description).contains("节奏 ×2"),"Repeated native action descriptions match the actual two-organ clock: "+source)
			check("；".join(g._plant_almanac_lines(id)).contains("节奏 ×2"),"The player's actual native fusion description shows the strengthened clock: "+source)
			check(g._visible_almanac_plants().has(source) and "；".join(g._plant_almanac_lines(source)).contains("节奏 ×2"),"The selectable original plant actually exposes its same-species fusion benefit: "+source)
	for excluded in Fusion.EXCLUDED+Fusion.UNOBTAINABLE:
		check(Fusion.result(excluded,excluded).is_empty(),"Terrain bases and bowling-only objects never become twins: "+excluded)
	var id: String=Fusion.result("peashooter","wallnut")
	var p: Dictionary=g._create_plant(id,2,1); g.grid[2][1]=p
	check(not g._try_activate_ultimate(2,1),"Uncharged fusion cannot spend a free ultimate")
	g._update_ultimate_charges(float(g._ultimate_profile_for_kind(id).ultimate_charge_time)+0.01)
	check(g._try_activate_ultimate(2,1),"Native elapsed charge enables the actual click path")
	check(not g._try_activate_ultimate(2,1),"The same click does not bypass active/cooldown guards")
	var cost: int=int(Native.PLANTS.peashooter.cost)+int(Native.PLANTS.wallnut.cost)
	g.active_cards=["peashooter","wallnut"]; g.sun_points=cost-1
	var runtime=g._ensure_plant_fusion(); runtime.select_seed("peashooter"); runtime.select_seed("wallnut")
	check(runtime.prepared_seeds.is_empty(),"A real two-material selection cannot bypass native paid cost")
	g.sun_points=cost; runtime.reset(); runtime.select_seed("peashooter"); runtime.select_seed("wallnut")
	check(runtime.prepared_cost()==cost and runtime.plant_prepared(3,1),"Legal prepared fusion uses both real seed prices")
	check(g.sun_points==0,"Native placement deducts exactly the two-material cost")
	runtime.reset(); g.active_cards=["cactus"]; g.sun_points=int(Native.PLANTS.cactus.cost)*2
	runtime.select_seed("cactus"); runtime.select_seed("cactus")
	check(runtime.plant_prepared(3,2) and g.sun_points==0,"A same-seed twin pays both native material prices")
	check(float(g.card_cooldowns.cactus)>0,"Twin placement enters the real seed cooldown")
	runtime.select_seed("cactus")
	check(runtime.source_seed.is_empty(),"The same materials cannot be acquired again before their native cooldown")
	print("Twin catalogue/charge/paid placement: %d entries" % count)
	dispose(g)

func healing_output(id: String, active: bool=false, seconds: float=12.0) -> float:
	var g=make_game(); var p: Dictionary=g._create_plant(id,2,1); g.grid[2][1]=p
	var ally_row: int=0 if active else 2; var ally_col: int=7 if active else 2
	var ally: Dictionary=g._create_plant("wallnut",ally_row,ally_col); ally.health=500.0; g.grid[ally_row][ally_col]=ally
	if active: p.ultimate_charge=1.0; g._try_activate_ultimate(2,1)
	for frame in range(ceili(seconds/0.05)):
		g._update_ultimate_charges(0.05); g._update_plants(0.05); g._update_effects(0.05)
	var healed: float=float(ally.health)-500.0+float(ally.get("armor_health",0)); dispose(g); return healed

func support_and_payloads() -> void:
	var single: float=healing_output("healing_gourd")
	var twin: float=healing_output(Fusion.result("healing_gourd","healing_gourd"))
	check(single>0 and twin>=single*1.8,"Two real healing organs heal the neighboring native wall faster: %.1f -> %.1f" % [single,twin])
	var normal_click: float=healing_output("healing_gourd",true,2.0)
	var twin_click: float=healing_output(Fusion.result("healing_gourd","healing_gourd"),true,2.0)
	check(twin_click>normal_click,"Twin healing signature is stronger than the same real native clicked support: %.1f -> %.1f" % [normal_click,twin_click])
	for source in ["wallnut","tallnut","pumpkin"]:
		var normal: Dictionary=measure(source,true,0.1)
		var pair: Dictionary=measure(Fusion.result(source,source),true,0.1)
		check(float(normal.armor)>0 and float(pair.armor)>=float(normal.armor)*1.8,"Twin %s's click produces actual two-body native fortification (%.1f -> %.1f)" % [source,normal.armor,pair.armor])
	var g=make_game(); var id: String=Fusion.result("peashooter","cherry_bomb")
	var p: Dictionary=g._create_plant(id,2,1); g.grid[2][1]=p; p.ultimate_charge=1
	g._try_activate_ultimate(2,1)
	check(not g.projectiles.is_empty(),"Ash-imbued shooting has a real immediate native volley")
	for shot in g.projectiles:
		check(not shot.has("fusion_blast"),"Shooter ash remains the small payload system, never a disposable 1800 blast chamber")
		check(float(shot.get("ash_payload_damage",shot.get("ash_damage",0)))<1800.0,"Per-shot ash budgets remain bounded during overdrive")
	for frame in range(220):
		g._update_ultimate_charges(0.05); g._update_plants(0.05); g._update_projectiles(0.05); g._update_effects(0.05)
	var state: Dictionary=p.fusion_native_states.peashooter
	check(float(state.plant_food_timer)==0.0 and float(state.fusion_overdrive_timer)==0.0,"Native overdrive expires on its original real-time clock")
	check(not g._try_activate_ultimate(2,1),"Finishing the native storm does not refill the actual 90-second fusion cooldown")
	dispose(g)

func guarded_fusion_hit(id: String, formal: bool) -> float:
	var g=make_game(); var p: Dictionary=g._create_plant(id,2,1); g.grid[2][1]=p; p.ultimate_charge=1
	g._spawn_zombie_at("cirno_boss",2,g._cell_center(2,7).x,true)
	var b: Dictionary=g.zombies.back(); b.erase("touhou_encounter")
	for phase in Spells.phases_for("cirno_boss",g.current_level):
		for entry in phase:
			var card: Dictionary=Spells.card_from_entry(entry)
			if String(card.origin) in ["canon","original"] and not String(card.pattern).begins_with("nonspell_"):
				b.touhou_card=card; break
		if b.has("touhou_card"): break
	b.touhou_cast_remaining=100.0 if formal else 0.0; b.touhou_invulnerable=false
	var before: float=vitality(b); g._try_activate_ultimate(2,1)
	for frame in range(60):
		g._update_ultimate_charges(0.05); g._update_plants(0.05); g._update_projectiles(0.05); g._update_effects(0.05)
	var loss: float=before-vitality(b); dispose(g); return loss

func boss_guard_and_chambers() -> void:
	for pair in [["peashooter","wallnut"],["cactus","healing_gourd"],["peashooter","cherry_bomb"],["melon_pult","torchwood"]]:
		var id: String=Fusion.result(pair[0],pair[1]); var plain: float=guarded_fusion_hit(id,false); var guarded: float=guarded_fusion_hit(id,true)
		check(plain>0 and absf(guarded-plain*0.125)<0.1,"Actual fusion signature, overdrive and ash retain active formal 87.5%% resistance: %s %.2f -> %.2f" % [id,plain,guarded])
	var g=make_game(); var id: String=Fusion.result("cherry_bomb","cherry_bomb"); var p: Dictionary=g._create_plant(id,2,1)
	g.grid[2][1]=p; g._spawn_zombie_at("gargantuar",2,g._cell_center(2,2).x,true)
	g._update_plants(1.0)
	check(p.fusion_opening_chambers.is_empty(),"The native planting blast is consumed once")
	var combined: Dictionary=g._ensure_plant_fusion().combined(Fusion.result(id,"cherry_bomb"),p)
	check(combined.fusion_opening_chambers.is_empty(),"Recursive grafting cannot refill a spent twin planting blast")
	dispose(g)

func consecutive_native_lotus_hits() -> void:
	var g=make_game(); g._spawn_zombie_at("normal",2,g._cell_center(2,4).x,true)
	var z: Dictionary=g.zombies.back(); g._apply_zombie_damage(z,float(z.health)-1.0)
	var pos: Vector2=g._zombie_target_point(z,g._cell_center(2,4))+Vector2(0,-10)
	var shot: Dictionary={"kind":"lotus_converge_shot","row":2,"position":pos,"target_position":pos,"target_uid":int(z.uid),"speed":460.0,"velocity_y":0.0,"damage":1.0,"slow_duration":0.0,"color":Color.WHITE,"radius":8.0,"reflected":false,"fire":false}
	g.projectiles=[shot.duplicate(true),shot.duplicate(true)]
	g._update_projectiles(1.0/60.0)
	check(float(z.health)==0.0,"Consecutive native converge shots hit the living enemy once; the second never damages its corpse")
	check(g._ensure_projectile_runtime()._find_spatial_enemy_hit(shot)==-1,"The dedicated lotus query cannot target a fresh corpse in the same update")
	z.touhou_invulnerable=true; z.touhou_survival_timer=1.0
	check(g._ensure_projectile_runtime()._find_spatial_enemy_hit(shot)==0,"The original zero-HP timed survival exception remains targetable")
	dispose(g)

func _run() -> void:
	twin_roles(); shooter_openings(); catalogue_and_charge(); support_and_payloads(); boss_guard_and_chambers(); consecutive_native_lotus_hits()
	print("Actual fusion activation/twin balance: %d failure(s)" % failures)
	call_deferred("quit",1 if failures else 0)
