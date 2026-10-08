extends SceneTree
const Game=preload("res://scripts/game.gd")
const Kanako=preload("res://scripts/data/level_defs_kanako.gd")
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var level:Dictionary={}
	for candidate in Game.Defs.LEVELS:
		if String(candidate.id)=="4-24":level=candidate
	check(not level.is_empty(),"4-24 must be an authored Kanako summit stage")
	if not level.is_empty():
		check(level.row_count==6 and level.water_rows.is_empty(),"Six dry stone lanes")
		check(not level.has("mid_boss_kind"),"TH10 stage6 has no road boss")
		check(level.events.back().kind=="kanako_boss" and level.events.filter(func(e):return String(e.kind)=="kanako_boss").size()==1,"Kanako is the single finale event")
		check(level.events.filter(func(e):return bool(e.get("wave",false))).size()==4,"Four road waves before the finale")
		check(level.terrain=="kanako_onbashira_shrine" and level.unlock_requirements==["4-23"],"Dedicated shrine follows Sanae's stage")
		check(level.boss_intro_bgm.ends_with("4-24-stage.mp3") and level.boss_bgm.ends_with("4-24-ending.mp3"),"Independent supplied stage/finale music")
		var weathers:Array=level.weather_schedule.map(func(w):return String(w.weather))
		check(weathers.size()>=5 and weathers.has("wind") and weathers.has("rain") and weathers.has("storm") and not weathers.has("fog"),"Real mountain weather schedule without heavy fog")
		# Every world contributes ordinary, armoured and fused enemies.
		var families:={}
		for kind in Kanako.ENEMIES:
			check(Game.Defs.ZOMBIES.has(kind) and not bool(Game.Defs.ZOMBIES[kind].get("boss",false)) and not bool(Game.Defs.ZOMBIES[kind].get("boss_summon",false)),"Valid ordinary/fusion visitor: "+kind)
			families[Game.FusionZombieDefs.base_kind(kind) if Game.FusionZombieDefs.RECIPES.has(kind) else kind]=true
		check(Kanako.ENEMIES.size()>=70 and families.size()>=45,"Broad roster across all worlds")
		for kind in ["normal","farmer","balloon_zombie","ladder_zombie","wenjie_zombie","kedama","ancient_mage","cinder_runner","gargantuar"]:check(Kanako.ENEMIES.has(kind),"World representative visits the summit: "+kind)
		check(Kanako.ENEMIES.filter(func(k):return Game.FusionZombieDefs.RECIPES.has(k)).size()>=25,"Many fusion zombies")
		check(Kanako.FINAL_ENEMIES.all(func(k):return Kanako.ENEMIES.has(k)) and not Kanako.FINAL_ENEMIES.has("gargantuar"),"Finale support stays inside the roster without stacking giants")
		for kind in ["umbrella_leaf","torchwood","jalapeno","plantern"]:check(level.conveyor_plants.has(kind),"Counterplay plant on the belt: "+kind)
		for tier in ["easy","normal","hard","lunatic"]:
			var built:Dictionary=Game.TouhouDifficulty.build_level(level,tier)
			check(built.touhou_difficulty==tier,"Four genuine difficulty profiles")
			check(built.mode==("normal" if tier=="lunatic" else "conveyor"),"Native difficulty seed modes")
			check(built.available_plants.has("sunflower") if tier=="lunatic" else built.conveyor_interval.x>=2.799,"Manual economy or balanced conveyor")
			check(built.events.back().kind=="kanako_boss","Extra difficulty waves never follow the finale")
	print("Kanako summit level contract: ",failures," failures")
	quit(1 if failures else 0)
