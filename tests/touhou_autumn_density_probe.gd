extends "res://tests/touhou_encounter_test.gd"

const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
var records: Array=[]

class AuditDanmaku extends Game.TouhouDanmakuRuntime:
	var launched:=0
	var attempted:=0
	var beam_launched:=0
	var beam_attempted:=0
	var peak:=0
	var beam_peak:=0
	var armed_peak:=0
	var swept_calls:=0
	var swept_hits:=0
	var min_arming:=INF
	var min_beam_delay:=INF
	var waves:Array=[]
	func _bullet(c:Dictionary,origin:Vector2,angle:float,speed:float,color:Color,shape:String="orb",extra:Dictionary={}) -> void:
		attempted+=1
		var before:=bullets.size()
		super._bullet(c,origin,angle,speed,color,shape,extra)
		if bullets.size()>before:
			launched+=1
			min_arming=minf(min_arming,float(bullets.back().get("arming_time",0.0)))
		peak=maxi(peak,bullets.size())
	func _beam(c:Dictionary,from:Vector2,to:Vector2,color:Color,delay:float=0.7,width:float=12.0,extra:Dictionary={}) -> void:
		beam_attempted+=1
		var before:=beams.size()
		super._beam(c,from,to,color,delay,width,extra)
		if beams.size()>before:
			beam_launched+=1
			min_beam_delay=minf(min_beam_delay,float(beams.back().delay))
		beam_peak=maxi(beam_peak,beams.size())
	func _emit_wave(c:Dictionary) -> void:
		var before:=launched
		super._emit_wave(c)
		waves.append({"age":c.age,"wave":c.wave,"bullets":launched-before})
	func _hit_plant_segment(from:Vector2,to:Vector2,radius:float,damage:float,hits:Array,first:bool=true) -> bool:
		swept_calls+=1
		var hit:=super._hit_plant_segment(from,to,radius,damage,hits,first)
		if hit:swept_hits+=1
		return hit
	func sample() -> void:
		var board:=Rect2(game.BOARD_ORIGIN,game.board_size)
		var armed:=0
		for p in bullets:
			if float(p.age)>=float(p.get("arming_time",0.0)) and board.has_point(Vector2(p.position)):armed+=1
		armed_peak=maxi(armed_peak,armed)

func _row_health(game:Control) -> Array:
	var result:Array=[]
	for row in game.active_rows:
		var hp:=0.0
		for p in game.grid[row]:
			if p!=null:hp+=float(p.health)+float(p.get("armor_health",0.0))
		result.append(hp)
	return result

func _new_danmaku(game: Control) -> AuditDanmaku:
	return AuditDanmaku.new(game)

func _prepare_geometry(game: Control) -> void:
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.board_rows = 6
	game.board_size = game.CELL_SIZE * Vector2(9, 6)

func _plant_columns() -> Array:
	return range(9)

func _audit(base:Dictionary,choice:String,road:bool) -> void:
	var level:Dictionary=Difficulty.build_level(base,choice)
	var kind:=String(level.mid_boss_kind) if road else String(level.events.back().kind)
	var game:=make_game(kind)
	game.zombies.clear()
	game.current_level=level
	_prepare_geometry(game)
	game.rng.seed=176
	if road:game._spawn_frozen_branch_midboss()
	else:game._spawn_zombie_at(kind,2,game._boss_anchor_x(kind),true)
	var boss:Dictionary=game.zombies[0]
	var authored:Array=boss.touhou_encounter.phases.duplicate(true)
	var role_hp:float=boss.max_health
	for stage in range(authored.size()):
		for attack in range(authored[stage].size()):
			var entry:Array=authored[stage][attack]
			for row in range(6):
				for col in _plant_columns():
					game.grid[row][col]=game._create_plant("wallnut",row,col)
					game.grid[row][col].health=100000.0
					game.grid[row][col].max_health=100000.0
			boss.touhou_encounter={"phases":authored,"index":stage,"attack":attack,"completed":0,"casting":false,"depleted":false,"complete":false,"floor":0.0,"ceiling":boss.max_health,"max_health":boss.max_health}
			boss.health=boss.max_health
			boss.boss_phase=roundi(3.0*float(stage)/maxf(1.0,authored.size()-1))
			boss.flash=0.0
			boss.impact_timer=0.0
			game.touhou_danmaku=_new_danmaku(game)
			var dm:AuditDanmaku=game.touhou_danmaku
			var before:=_row_health(game)
			boss=game._trigger_boss_skill(boss)
			var duration:float=boss.touhou_cast_duration
			dm.sample()
			dm.update(0.95)
			var warning_damage:=0.0
			var warning_hp:=_row_health(game)
			for row in range(6):warning_damage+=float(before[row])-float(warning_hp[row])
			dm.sample()
			var elapsed:=0.95
			while elapsed<duration+0.10:
				dm.update(0.05)
				elapsed+=0.05
				dm.sample()
			var launch:=dm.launched
			var attempts:=dm.attempted
			var beam_launch:=dm.beam_launched
			var remaining:=dm.bullets.size()
			# Follow the cast's final bullets too, to count useful swept damage
			# rather than confusing post-cast flight with a missing hit.
			for frame in range(140):
				dm.update(0.05)
				dm.sample()
			var damage:=0.0
			var rows:Array=[]
			var after:=_row_health(game)
			for row in range(6):
				var lost:=float(before[row])-float(after[row])
				damage+=lost
				if lost>0.01:rows.append(row)
			records.append({"stage_id":level.id,"difficulty":choice,"role":"road" if road else "finale","kind":kind,"phase":stage,"attack":attack,"id":entry[0],"pattern":entry[2],"duration":duration,"boss_hp":role_hp,"phase_count":authored.size(),"launched":launch,"attempted":attempts,"rate":launch/maxf(0.1,duration),"beams":beam_launch,"drops":attempts-launch,"peak":dm.peak,"beam_peak":dm.beam_peak,"armed_on_board_peak":dm.armed_peak,"remaining_at_cast_end":remaining,"swept_calls":dm.swept_calls,"swept_hits":dm.swept_hits,"hit_rows":rows,"plant_damage":damage,"warning_damage":warning_damage,"min_arming":dm.min_arming if is_finite(dm.min_arming) else null,"min_beam_delay":dm.min_beam_delay if is_finite(dm.min_beam_delay) else null,"waves":dm.waves})
			print(level.id,"/",choice,"/",("road" if road else "finale"),"/",entry[0]," phase ",stage," launched=",launch," rate=",snappedf(launch/maxf(0.1,duration),0.1)," rows=",rows.size()," drops=",attempts-launch)
			dm.clear()
			if game.aki_runtime!=null:game.aki_runtime.clear_owner(int(boss.uid))
			if game.hina_runtime!=null:game.hina_runtime.clear_owner(int(boss.uid))
			game.zombies=game.zombies.filter(func(z):return int(z.uid)==int(boss.uid))
		records.back()["role_casts"]=authored[stage].size()
	release(game)

func _run() -> void:
	for stage in ["4-19","4-20"]:
		var base:Dictionary={}
		for level in Game.Defs.LEVELS:
			if level.id==stage:base=level
		for choice in ["easy","normal","hard","lunatic"]:
			_audit(base,choice,false)
			_audit(base,choice,true)
	var target:="res://output/v176/barrage-test-output.json"
	if not OS.get_cmdline_user_args().is_empty():target=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
	var f:=FileAccess.open(target,FileAccess.WRITE)
	f.store_string(JSON.stringify({"records":records},"\t")+"\n")
	print("Actual-dispatch barrage audit: ",records.size()," casts to ",target)
	quit(0)
