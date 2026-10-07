extends SceneTree
const Game=preload("res://scripts/game.gd")
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var level:Dictionary={}
	for candidate in Game.Defs.LEVELS:
		if String(candidate.id)=="4-23":level=candidate
	check(not level.is_empty(),"4-23 must be an authored Sanae shrine stage")
	if not level.is_empty():
		check(level.row_count==6 and level.water_rows.is_empty(),"Six dry shrine rows")
		check(level.mid_boss_kind=="sanae_boss" and level.mid_boss_final_preview,"Same-character incomplete road and fresh finale")
		check(level.events.back().kind=="sanae_boss" and float(level.events.back().time)==180.0,"Moderate shrine approach reaches its finale schedule at three minutes")
		check(level.events.size()==18 and level.events.filter(func(event):return bool(event.get("wave",false))).size()==4,"Four main waves leave time to develop a fusion formation without repeating the long stage4 road")
		check(is_equal_approx(float(level.mid_boss_locked_progress),.5) and not level.has("mid_boss_time"),"Sanae midboss belongs at half progress rather than a fixed timestamp")
		check(level.terrain=="sanae_moriya_shrine" and level.unlock_requirements==["4-22"],"Dedicated shrine follows mountain ascent")
		check(level.boss_intro_bgm!=level.boss_bgm and level.weather_schedule.size()>=4,"Independent stage/finale music and real weather schedule")
		for tier in ["easy","normal","hard","lunatic"]:
			var built:Dictionary=Game.TouhouDifficulty.build_level(level,tier)
			check(built.touhou_difficulty==tier,"Four genuine difficulty profiles")
			check(built.mode==("normal" if tier=="lunatic" else "conveyor"),"Native difficulty seed modes")
			check(built.available_plants.has("sunflower") if tier=="lunatic" else built.conveyor_interval.x>=2.799,"Manual economy or balanced conveyor")
	print("Sanae shrine level contract: ",failures," failures")
	quit(1 if failures else 0)
