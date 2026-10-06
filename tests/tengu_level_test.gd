extends SceneTree
const Defs = preload("res://scripts/game_defs.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const FusionZombies = preload("res://scripts/data/fusion_zombie_defs.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)

func _initialize() -> void:
	var stage: Dictionary={}
	for level in Defs.LEVELS:
		if String(level.id)=="4-22": stage=level
	check(not stage.is_empty(),"Actual registered 4-22 Tengu stage is missing")
	if stage.is_empty():
		print("Tengu actual registered level: missing, 1 failure")
		quit(1); return
	check(String(stage.terrain)=="tengu_waterfall" and int(stage.row_count)==6,"Road starts on its independent six-row waterfall")
	check(stage.get("water_rows",[])==[0,1,2,3,4,5],"All six authored road lanes are real water")
	check(stage.unlock_requirements==["4-21"],"Only 4-22 extends the mountain route after Nitori")
	check(stage.mid_boss_kind=="momiji_boss" and stage.events.back().kind=="aya_boss","Weak Momiji patrol precedes full Aya")
	check(is_equal_approx(float(stage.mid_boss_locked_progress),0.4),"The weak patrol gates actual road progress at forty percent")
	check(float(stage.events.back().time)>=300.0,"There are at least 300 authored road seconds before final Aya")
	check(stage.get("preplaced_support_kind","")=="lily_pad" and stage.get("preplaced_supports",[]).size()==12,"Both initial columns across all six water rows have actual lily supports")
	var pad_cells: Array=[]
	for row in range(6):
		for col in [1,2]: pad_cells.append(Vector2i(row,col))
	for cell in stage.get("preplaced_supports",[]):
		var actual: Vector2i=Vector2i(int(cell[0]),int(cell[1])) if cell is Array else Vector2i(cell)
		check(pad_cells.has(actual),"Only the twelve authored opening-pad cells are seeded")
	check(stage.boss_intro_bgm=="res://audio/bgm/touhou/4-22-stage.mp3" and stage.boss_bgm=="res://audio/bgm/touhou/4-22-ending.mp3","Supplied music preserves road and true final-arrival roles")
	check(Difficulty.options(stage)==["easy","normal","hard","lunatic"],"Tengu has the four standard difficulty selections")
	for source in ["lily_pad","plantern","umbrella_leaf"]:
		check(stage.conveyor_plants.has(source) and stage.available_plants.has(source),"Both belt/manual menus provide native counter and support "+source)
	var fused:=0
	for kind in stage.enemy_whitelist:
		check(Defs.ZOMBIES.has(kind),"Every Tengu roster enemy is registered: "+kind)
		if FusionZombies.RECIPES.has(kind): fused+=1
	check(fused>0,"The waterfall and fortress roster includes real fusion equipment")
	for rank in range(4):
		var choice: String=["easy","normal","hard","lunatic"][rank]
		var level: Dictionary=Difficulty.build_level(stage,choice)
		check(level.water_rows==[0,1,2,3,4,5] and level.terrain=="tengu_waterfall","Selection retains all six actual water rows: "+choice)
		check((level.mode=="normal")== (rank==3),"Only Lunatic uses selected manual seeds: "+choice)
		if rank<3:
			var interval: Vector2=Vector2(level.get("conveyor_interval",Vector2.ZERO))
			check(interval.x>=2.8-0.00001 and interval.y>=4.0-0.00001,"Easy/Normal/Hard retain the requested slow physical belt")
		else: check(level.available_plants.has("sunflower"),"Manual Lunatic supplies a real sun economy")
		var momiji: Array=Spells.phases_for("momiji_boss",level)
		check(momiji.size()==(3 if rank>=2 else 2),"Momiji remains a short two/three-phase patrol")
		var road_canons:=0
		for phase in momiji:
			for entry in phase:
				if String(Spells.card_from_entry(entry).origin)=="canon": road_canons+=1
		check(road_canons==0,"TH10 Momiji receives no invented canonical spell identity")
		var phases: Array=Spells.phases_for("aya_boss",level)
		check(phases.size()==[6,8,9,10][rank],"Aya actual spell-phase route is six/eight/nine/ten: "+choice)
		var canon_ids: Array=[]; var originals:=0; var survival_index: int=-1; var blockade_index: int=-1
		for pi in range(phases.size()):
			for entry in phases[pi]:
				var card: Dictionary=Spells.card_from_entry(entry)
				if String(card.origin)=="canon":
					canon_ids.append(String(card.id))
					if bool(card.get("survival",false)): survival_index=pi
					if String(card.id)=="th10-%03d" % (54+rank): blockade_index=pi
				if String(card.origin)=="original": originals+=1
		var expected: Array=["th10-%03d" % (43+rank),"th10-%03d" % (47+rank)]
		if rank>0: expected.append("th10-%03d" % (50+rank))
		expected.append("th10-%03d" % (54+rank))
		check(canon_ids==expected,"All original TH10 identities preserve branch, wind, survival, blockade order: "+choice)
		check(originals==3+rank,"PvZ adaptations accumulate three plus rank declared cards: "+choice)
		check((survival_index==-1)==(rank==0),"Timed rapid-flight survival is absent on Easy only")
		if rank>0: check(survival_index<blockade_index and blockade_index==phases.size()-1,"Survival advances into the final canonical blockade rather than ending the encounter")
		check(Difficulty.boss_kinds().has("momiji_boss") and Difficulty.boss_kinds().has("aya_boss"),"Both Tengu use shared Touhou registration")
	print("Tengu water road, long route, four tiers and TH10 spell order: %d failure(s)" % failures)
	quit(1 if failures else 0)
