extends RefCounted
const Sprites=preload("res://scripts/data/kanako_sprite_defs.gd")
const Danmaku=preload("res://scripts/runtime/kanako_danmaku.gd")
const KIND:="kanako_boss"
const PILLAR_WARNING:=1.5
const ROPE_WARNING:=1.3
const ROPE_FACTOR:=0.55
const ROPE_BURN:=0.9
const BLESS_SPEED:=1.25
const BLESS_DAMAGE:=0.75
const PILLAR_DAMAGE:=34.0
const FAITH_CHARGE:=0.12
const MAX_FIELDS:=18
const MAX_PILLARS:=4
const FIRE_COMPONENTS:=["torchwood","jalapeno","pepper_mortar","chimney_pepper","magma_stream","meteor_flower","core_blossom","phoenix_tree","dragon_fruit","caldera_lotus"]
var game:Control
var fields:Array[Dictionary]=[]
var impacts:Array[Dictionary]=[]
var pending_weather:Array[Dictionary]=[]
var serial:=0

func _init(owner:Control)->void:game=owner

func boss_for(uid:int)->Dictionary:
	for b in game.zombies:
		if int(b.get("uid",-1))==uid and String(b.kind)==KIND and float(b.health)>0:return b
	return {}

func _rank()->int:return int(game.TouhouDifficulty.profile(game.current_level).rank)

func sheltered(row:int,col:int)->bool:
	var p=game._targetable_plant_at(row,col)
	return game._is_cell_protected_by_umbrella(row,col) or (p!=null and (float(p.get("holy_invincible_timer",0))>0 or bool(p.get("ultimate_active",false))))

func reset()->void:
	fields.clear();impacts.clear();pending_weather.clear();serial=0
	for z in game.zombies:
		if String(z.kind)=="kanako_onbashira":z.health=0.0;z["kanako_expired"]=true

func clear_owner(owner:int)->void:
	fields=fields.filter(func(f):return int(f.owner)!=owner)
	pending_weather=pending_weather.filter(func(w):return int(w.owner)!=owner)
	for z in game.zombies:
		if String(z.kind)=="kanako_onbashira" and int(z.get("kanako_owner",-1))==owner:z.health=0.0;z["kanako_expired"]=true
	if game.ancient_expansion!=null and int(game.ancient_expansion.override_owner)==owner:
		game.ancient_expansion.override_until=game.level_time

func cleanse_row(row:int)->void:
	var before:=fields.size()
	fields=fields.filter(func(f):return not (String(f.mode) in ["rope","banner"] and int(f.row)==row))
	if fields.size()<before:
		game._show_toast("本行注连绳与军神加护已被解除！")
		game.effects.append({"position":game._cell_center(row,4),"radius":game.board_size.x*.45,"time":.35,"duration":.35,"color":Color(1,.82,.55,.22)})

func burn_row(row:int)->void:
	# A jalapeno's lane fire consumes the straw rope outright.
	var before:=fields.size()
	for f in fields:
		if String(f.mode)=="rope" and int(f.row)==row:
			impacts.append({"position":game._cell_center(row,int((int(f.from)+int(f.to))/2)),"age":0.0,"life":.7,"size":1.1,"burnt":true})
	fields=fields.filter(func(f):return not (String(f.mode)=="rope" and int(f.row)==row))
	if fields.size()<before:game._show_toast("火焰烧断了注连绳！")

func frame_index(boss:Dictionary)->int:return Sprites.frame_index(boss,game.level_time if game.mode==game.MODE_BATTLE else game.ui_time)

func _session(owner:int)->Dictionary:
	var boss:=boss_for(owner)
	if boss.is_empty() or game.touhou_danmaku==null or not boss.has("touhou_owner"):return {}
	for c in game.touhou_danmaku.casts:
		if int(c.owner)==int(boss.touhou_owner):return c
	return {}

func _plant_value(p:Dictionary,col:int)->float:
	return (20.0 if p.has("fusion_kind") else 0.0)+float(p.get("max_health",0))*.002+col*.1

func _busy_cells(amount:int)->Array[Vector2i]:
	# Real occupied cells, one per lane, favouring fused and sturdier plants.
	var choices:Array=[]
	for row in game.active_rows:
		for col in range(game.COLS):
			var p=game._targetable_plant_at(int(row),col)
			if p==null or float(p.health)<=0:continue
			choices.append({"cell":Vector2i(int(row),col),"score":_plant_value(p,col),"tie":posmod(int(row)*7+col+serial*5,54)})
	choices.sort_custom(func(a,b):return a.score>b.score or (a.score==b.score and a.tie<b.tie))
	var result:Array[Vector2i]=[]
	for c in choices:
		if result.size()>=amount:break
		if result.any(func(cell):return cell.x==c.cell.x):continue
		result.append(c.cell)
	return result

func _rope_rows(amount:int)->Array:
	var scored:Array=[]
	for row in game.active_rows:
		var count:=0
		for col in range(1,6):
			if game._targetable_plant_at(int(row),col)!=null:count+=1
		scored.append({"row":int(row),"count":count,"tie":posmod(int(row)*5+serial,11)})
	scored.sort_custom(func(a,b):return a.count>b.count or (a.count==b.count and a.tie<b.tie))
	return scored.slice(0,mini(amount,scored.size())).map(func(e):return int(e.row))

func queue_pillar(owner:int,cell:Vector2i,stay:bool=false,delay:float=PILLAR_WARNING)->void:
	if fields.size()>=MAX_FIELDS or boss_for(owner).is_empty() or not game._is_row_active(cell.x) or cell.y<0 or cell.y>=game.COLS:return
	if fields.any(func(f):return String(f.mode)=="pillar" and f.cell==cell):return
	fields.append({"owner":owner,"mode":"pillar","cell":cell,"row":cell.x,"age":0.0,"delay":maxf(PILLAR_WARNING,delay),"stay":stay,"applied":false})

func queue_rope(owner:int,row:int,from_col:int,to_col:int,duration:float=6.0)->void:
	if fields.size()>=MAX_FIELDS or boss_for(owner).is_empty() or not game._is_row_active(row):return
	if fields.any(func(f):return String(f.mode)=="rope" and int(f.row)==row):return
	fields.append({"owner":owner,"mode":"rope","row":row,"from":clampi(mini(from_col,to_col),0,game.COLS-1),"to":clampi(maxi(from_col,to_col),0,game.COLS-1),"age":0.0,"delay":ROPE_WARNING,"duration":clampf(duration,1.0,8.0),"burn":0.0})

func queue_banner(owner:int,row:int,duration:float)->void:
	if fields.size()>=MAX_FIELDS or boss_for(owner).is_empty() or not game._is_row_active(row):return
	if fields.any(func(f):return String(f.mode)=="banner" and int(f.row)==row):return
	fields.append({"owner":owner,"mode":"banner","row":row,"age":0.0,"delay":.8,"duration":clampf(duration,1.0,12.0)})

func _weather(owner:int,kind:String,duration:float,banner:String)->void:
	var rt=game._ensure_ancient_expansion()
	rt.set_override(kind,owner,duration,"神奈子 · %s · %s"%[banner,String(rt.weather_info(kind).name)])

func on_arrival(boss:Dictionary)->void:
	# Four ceremonial pillars crash beside the shrine floor as she descends.
	var board:=Rect2(game.BOARD_ORIGIN,game.board_size)
	for i in range(4):
		impacts.append({"position":Vector2(board.end.x-game.CELL_SIZE.x*(.3+i*.12),board.position.y+board.size.y*(.15+i*.24)),"age":-.15*i,"life":1.1,"size":1.4,"arrival":true})
	game.effects.append({"shape":"kanako_arrival","position":Vector2(boss.x,game._row_center_y(int(boss.row))),"radius":game.board_size.y*.5,"time":.9,"duration":.9,"color":Color(1,.42,.42,.24)})

func cast(boss:Dictionary,pattern:String)->void:
	var owner:=int(boss.uid);clear_owner(owner);serial+=1
	var r:=_rank();var duration:=float(boss.get("touhou_cast_duration",10.0))
	match pattern:
		"kanako_pillar_fall","kanako_faith":
			var drops:=_busy_cells(mini(6,3+r if pattern=="kanako_pillar_fall" else 2+r/2))
			for i in range(drops.size()):queue_pillar(owner,drops[i],false,PILLAR_WARNING+i*.28)
			var stay:=mini(MAX_PILLARS,1+(r+1)/2 if pattern=="kanako_pillar_fall" else 2)
			for i in range(stay):
				var row:=int(game.active_rows[posmod(serial+i*2+1,game.active_rows.size())])
				queue_pillar(owner,Vector2i(row,game.COLS-1-posmod(i+serial,2)),true,PILLAR_WARNING+.4+i*.3)
			if pattern=="kanako_faith":
				for row in _rope_rows(1+r/2):queue_rope(owner,int(row),1,4,5.0)
				_weather(owner,"wind",minf(12.0,duration),"六道神风")
			else:game._show_toast("御柱落点红影预警：伞叶可挡下坠柱；击倒后排御柱为本行植物返还信仰")
		"kanako_shimenawa":
			for row in _rope_rows(mini(5,2+r)):queue_rope(owner,int(row),1,5,6.0)
			game._show_toast("注连绳封锁：被缚植物出手放缓；火焰植物烧断绳索，本行大招解缚")
		"kanako_war_god":
			var rows:Array=[]
			for i in range(mini(game.active_rows.size(),2+r)):rows.append(int(game.active_rows[posmod(serial*2+i*2+i/3,game.active_rows.size())]))
			for row in rows:queue_banner(owner,int(row),duration)
			game._spawn_new_touhou_finale_support(KIND,int(boss.get("boss_phase",0)))
			game._show_toast("军神加护：军旗所在行的僵尸加速且减伤，本行大招驱散军旗")
		"kanako_weather":
			_weather(owner,"wind",duration*.5,"山岳东风")
			pending_weather.append({"owner":owner,"at":game.level_time+duration*.5,"weather":"storm" if r>=3 else "rain","duration":duration*.5,"banner":"御神渡的雨"})
		"kanako_otensui":_weather(owner,"rain",minf(12.0,duration),"天水奇迹")
		"kanako_rain_source":_weather(owner,"storm",minf(12.0,duration),"雨之源泉")
		"kanako_mountain_of_faith","kanako_wind_god_virtue":_weather(owner,"wind",minf(14.0,duration),"风神之神德" if pattern=="kanako_wind_god_virtue" else "信仰之山")

func _fire_in(row:int,from_col:int,to_col:int)->bool:
	for col in range(from_col,to_col+1):
		for layer in [game.grid,game.support_grid]:
			var p=layer[row][col]
			if p==null or float(p.get("health",0))<=0:continue
			for component in FIRE_COMPONENTS:
				if game._plant_has_component(p,component):return true
	return false

func _impact(field:Dictionary)->void:
	var cell:Vector2i=field.cell
	var point:Vector2=game._cell_center(cell.x,cell.y)
	impacts.append({"position":point,"age":0.0,"life":.9,"size":1.0,"blocked":false})
	var c:=_session(int(field.owner))
	if sheltered(cell.x,cell.y):
		impacts.back().blocked=true
		game.effects.append({"position":point,"radius":game.CELL_SIZE.y*.6,"time":.3,"duration":.3,"color":Color(.75,1,.8,.32)})
	else:
		var p=game._targetable_plant_at(cell.x,cell.y)
		if p!=null:game._damage_plant_cell(cell.x,cell.y,PILLAR_DAMAGE*game.TouhouDifficulty.direct_attack_damage(KIND,game.current_level),.4,true)
	if not c.is_empty():Danmaku.impact_ring(game.touhou_danmaku,c,point+Vector2(0,-8))
	game._play_sfx(game.SFX_SHOOT_ENERGY_PATH,-16.0,.55)
	if bool(field.stay):_spawn_pillar(field)

func _spawn_pillar(field:Dictionary)->void:
	var alive:int=game.zombies.filter(func(z):return String(z.kind)=="kanako_onbashira" and float(z.health)>0).size()
	if alive>=MAX_PILLARS:return
	var cell:Vector2i=field.cell
	var before:int=game.zombies.size()
	game._spawn_zombie_at("kanako_onbashira",cell.x,game._cell_center(cell.x,cell.y).x,true)
	if game.zombies.size()<=before:return
	var unit:Dictionary=game.zombies[before]
	unit["kanako_owner"]=int(field.owner);unit["kanako_expired"]=false;unit["kanako_pulse"]=1.6
	unit["health"]=620.0+60.0*_rank();unit["max_health"]=unit.health

func on_pillar_death(z:Dictionary)->void:
	if bool(z.get("kanako_expired",false)) or boss_for(int(z.get("kanako_owner",-1))).is_empty():return
	var row:=int(z.row);var rewarded:=0
	for layer in [game.grid,game.support_grid]:
		for col in range(game.COLS):
			var p=layer[row][col]
			if p==null or float(p.get("health",0))<=0 or bool(p.get("ultimate_active",false)) or float(p.get("ultimate_cooldown",0))>0:continue
			p["ultimate_charge"]=minf(1.0,float(p.get("ultimate_charge",0.0))+FAITH_CHARGE);rewarded+=1
	impacts.append({"position":Vector2(float(z.x),game._row_center_y(row)),"age":0.0,"life":.8,"size":1.2,"faith":true})
	if rewarded>0:game._show_toast("御柱倒下：本行%d株植物获得信仰，大招充能+12%%"%rewarded)

func _blessed(z:Dictionary)->bool:
	if fields.is_empty() or not game._is_enemy_zombie(z) or game._is_boss_kind(String(z.get("kind",""))) or String(z.get("kind",""))=="kanako_onbashira":return false
	for f in fields:
		if String(f.mode)=="banner" and int(f.row)==int(z.get("row",-1)) and float(f.age)>=float(f.delay) and not boss_for(int(f.owner)).is_empty():return true
	return false

func speed_factor(z:Dictionary)->float:return BLESS_SPEED if _blessed(z) else 1.0
func damage_factor(z:Dictionary)->float:return BLESS_DAMAGE if _blessed(z) else 1.0

func _rope_active(f:Dictionary)->bool:
	return String(f.mode)=="rope" and float(f.age)>=float(f.delay) and float(f.age)<float(f.delay)+float(f.duration) and float(f.burn)<ROPE_BURN

func action_factor(row:int,col:int)->float:
	for f in fields:
		if int(f.row)!=row or not _rope_active(f) or col<int(f.from) or col>int(f.to):continue
		if sheltered(row,col):return 1.0
		return ROPE_FACTOR
	return 1.0

func update(delta:float)->void:
	if game.boss_time_stop_timer>0:return
	for i in range(impacts.size()-1,-1,-1):
		impacts[i].age=float(impacts[i].age)+delta
		if float(impacts[i].age)>=float(impacts[i].life):impacts.remove_at(i)
	for i in range(pending_weather.size()-1,-1,-1):
		var w:Dictionary=pending_weather[i]
		if boss_for(int(w.owner)).is_empty():pending_weather.remove_at(i);continue
		if game.level_time>=float(w.at):_weather(int(w.owner),String(w.weather),float(w.duration),String(w.banner));pending_weather.remove_at(i)
	for index in range(fields.size()-1,-1,-1):
		var f:Dictionary=fields[index];f.age=float(f.age)+maxf(0,delta)
		if boss_for(int(f.owner)).is_empty():fields.remove_at(index);continue
		match String(f.mode):
			"pillar":
				if float(f.age)>=float(f.delay) and not bool(f.applied):
					f.applied=true;_impact(f);fields.remove_at(index)
			"rope":
				if float(f.age)>=float(f.delay)+float(f.duration):fields.remove_at(index);continue
				if float(f.age)>=float(f.delay) and _fire_in(int(f.row),int(f.from),int(f.to)):
					# Rain and storm damp the straw, so it smoulders more slowly.
					var damp:float=.5 if game.ancient_expansion!=null and game.ancient_expansion.is_weather(["rain","storm"]) else 1.0
					f.burn=float(f.burn)+delta*damp
					if float(f.burn)>=ROPE_BURN:
						game._show_toast("火焰烧断了注连绳！")
						impacts.append({"position":game._cell_center(int(f.row),int((int(f.from)+int(f.to))/2)),"age":0.0,"life":.7,"size":1.1,"burnt":true})
						fields.remove_at(index)
			"banner":
				if float(f.age)>=float(f.delay)+float(f.duration):fields.remove_at(index)
	for z in game.zombies:
		if String(z.kind)!="kanako_onbashira" or float(z.health)<=0:continue
		var owner:=int(z.get("kanako_owner",-1))
		if boss_for(owner).is_empty():z.health=0.0;z["kanako_expired"]=true;continue
		z.kanako_pulse=float(z.get("kanako_pulse",2.0))-delta
		if float(z.kanako_pulse)<=0:
			z.kanako_pulse=2.6-.2*_rank()
			var c:=_session(owner)
			if not c.is_empty():Danmaku.pillar_pulse(game.touhou_danmaku,c,Vector2(float(z.x),game._row_center_y(int(z.row))-game.CELL_SIZE.y*.35))

# ------------------------------------------------------------------ drawing

func draw_ground()->void:
	var unit:float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	for f in fields:
		match String(f.mode):
			"pillar":
				var center:Vector2=game._cell_center(f.cell.x,f.cell.y)
				var progress:=clampf(float(f.age)/float(f.delay),0.0,1.0)
				# The falling trunk's shadow tightens into the impact footprint.
				var w:=unit*(.62-.22*progress);var h:=unit*(.24-.08*progress)
				var shadow:=PackedVector2Array()
				for k in range(20):shadow.append(center+Vector2(cos(TAU*k/20.0)*w,sin(TAU*k/20.0)*h+unit*.18))
				game.draw_colored_polygon(shadow,Color(.12,.02,.04,.18+.32*progress))
				game.draw_arc(center+Vector2(0,unit*.18),w*1.05,0,TAU,24,Color(Danmaku.RED,.45+.4*progress),maxf(1,unit*.025),true)
				game.draw_arc(center,unit*.4,-PI*.5,-PI*.5+TAU*progress,24,Color(1,.86,.6,.85),maxf(1,unit*.03),true)
				for k in range(4):
					var a:=TAU*k/4.0+float(f.age)*1.5
					game.draw_line(center+Vector2.from_angle(a)*unit*.3,center+Vector2.from_angle(a)*unit*.44,Color(Danmaku.RED,.75),maxf(1,unit*.025),true)
				if bool(f.stay):Danmaku.draw_crest(game,center,unit*.12,Color(1,.9,.85,.5+.4*progress))
			"rope":_draw_rope(f,unit)
			"banner":
				var y:float=game._row_center_y(int(f.row))
				var ready:=clampf(float(f.age)/float(f.delay),0.0,1.0)
				var rect:=Rect2(Vector2(game.BOARD_ORIGIN.x,y-game.CELL_SIZE.y*.5),Vector2(game.board_size.x,game.CELL_SIZE.y))
				game.draw_rect(rect,Color(Danmaku.CRIMSON,.07*ready))
				for k in range(9):
					var x:=rect.position.x+rect.size.x*fposmod(k/9.0-game.level_time*.08,1.0)
					game.draw_line(Vector2(x,y+game.CELL_SIZE.y*.3),Vector2(x-unit*.12,y+game.CELL_SIZE.y*.3),Color(Danmaku.RED,.35*ready),maxf(1,unit*.03),true)
	for z in game.zombies:
		if float(z.get("health",0))<=0 or not _blessed(z):continue
		var foot:=Vector2(float(z.x),game._row_center_y(int(z.row))+game.CELL_SIZE.y*.28)
		game.draw_arc(foot,unit*.3,0,TAU,20,Color(Danmaku.RED,.55+.2*sin(game.level_time*6.0+float(z.uid))),maxf(1,unit*.03),true)
		game.draw_circle(foot,unit*.26,Color(Danmaku.RED,.1))

func _draw_rope(f:Dictionary,unit:float)->void:
	var y:float=game._row_center_y(int(f.row))-game.CELL_SIZE.y*.05
	var from:Vector2=Vector2(game._cell_center(int(f.row),int(f.from)).x-game.CELL_SIZE.x*.45,y)
	var to:Vector2=Vector2(game._cell_center(int(f.row),int(f.to)).x+game.CELL_SIZE.x*.45,y)
	var warning:=float(f.age)<float(f.delay)
	var progress:=clampf(float(f.age)/float(f.delay),0.0,1.0)
	var alpha:=.4+.5*progress if warning else 1.0
	var burn:=clampf(float(f.burn)/ROPE_BURN,0.0,1.0)
	var length:=to.x-from.x
	var segments:=maxi(8,int(length/maxf(4.0,unit*.12)))
	var sag:float=game.CELL_SIZE.y*.12
	var reach:=progress if warning else 1.0
	# Two twisted strands (a real shimenawa), dashed while it is still warning.
	for strand in range(2):
		var line:=PackedVector2Array()
		for k in range(segments+1):
			var t:=float(k)/segments
			if t>reach:break
			var base:=from.lerp(to,t)+Vector2(0,sin(PI*t)*sag)
			line.append(base+Vector2(0,sin(t*length/maxf(1.0,unit*.22)*PI+strand*PI)*unit*.05))
		if line.size()>=2:
			game.draw_polyline(line,Color(Danmaku.ROPE if strand==0 else Danmaku.ROPE_DARK,alpha*(1.0-burn*.6)),maxf(1.5,unit*(.07 if not warning else .035)),true)
	if not warning:
		for k in range(1,4):
			var t:=k/4.0
			var hang:=from.lerp(to,t)+Vector2(0,sin(PI*t)*sag+unit*.05)
			Danmaku.draw_shide(game,hang,unit*.24,1.0-burn*.7,sin(game.level_time*5.0+k)*.25)
		for col in range(int(f.from),int(f.to)+1):
			if game._targetable_plant_at(int(f.row),col)!=null and not sheltered(int(f.row),col):
				game.draw_arc(game._cell_center(int(f.row),col),unit*.36,0,TAU,18,Color(Danmaku.ROPE,.45),maxf(1,unit*.02),true)
	if burn>0:
		for k in range(6):
			var t:=fposmod(k*.17+game.level_time*.6,1.0)
			var p:=from.lerp(to,t)+Vector2(0,sin(PI*t)*sag-unit*.05)
			game.draw_circle(p,unit*(.05+.04*burn),Color(1,.55,.2,.75*burn))
			game.draw_circle(p-Vector2(0,unit*.06),unit*.03,Color(1,.9,.5,.8*burn))

func draw_overlay()->void:
	var unit:float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	for f in fields:
		if String(f.mode)!="pillar":continue
		var progress:=clampf(float(f.age)/float(f.delay),0.0,1.0)
		if progress<.6:continue
		# The trunk falls from above the lawn during the last part of the warning.
		var drop:=(progress-.6)/.4
		var center:Vector2=game._cell_center(f.cell.x,f.cell.y)
		var foot_y:float=lerpf(game.BOARD_ORIGIN.y-unit*.8,center.y+unit*.2,drop*drop)
		Danmaku.draw_pillar(game,Vector2(center.x,foot_y),unit*.34,unit*1.25,minf(1.0,drop*1.6),.4)
	for i in impacts:
		var age:=float(i.age)
		if age<0:continue
		var t:=clampf(age/float(i.life),0.0,1.0)
		var p:Vector2=i.position;var size:=float(i.get("size",1.0))
		if bool(i.get("arrival",false)):
			Danmaku.draw_pillar(game,p+Vector2(0,unit*.4),unit*.3,unit*1.2*minf(1.0,age*6.0),1.0-t,1.0-t)
		elif not bool(i.get("blocked",false)) and not bool(i.get("burnt",false)) and not bool(i.get("faith",false)):
			Danmaku.draw_pillar(game,p+Vector2(0,unit*.2),unit*.34,unit*1.25,1.0-t*t,.6*(1.0-t),t)
		var ring:=unit*(.3+t*.6)*size
		game.draw_arc(p+Vector2(0,unit*.2),ring,PI,TAU,18,Color(.85,.72,.5,(1.0-t)*.8),maxf(1,unit*.05*(1.0-t)),true)
		for k in range(6):
			var a:=PI+PI*(k+.5)/6.0
			var d:=p+Vector2(0,unit*.2)+Vector2.from_angle(a)*ring*1.1+Vector2(0,t*t*unit*.4)
			var tint:=Color(.6,1,.7) if bool(i.get("blocked",false)) else (Color(1,.6,.25) if bool(i.get("burnt",false)) else (Color(1,.85,.55) if bool(i.get("faith",false)) else Color(.55,.4,.28)))
			game.draw_circle(d,unit*.05*(1.0-t),Color(tint,1.0-t))
		if bool(i.get("faith",false)):
			for k in range(5):
				var rise:=p-Vector2((k-2)*unit*.18,t*unit*1.4+k%2*unit*.2)
				game.draw_circle(rise,unit*.04*(1.0-t*.5),Color(1,.88,.5,(1.0-t)))
	for z in game.zombies:
		if float(z.get("health",0))<=0 or not _blessed(z):continue
		var top:=Vector2(float(z.x)+unit*.18,game._row_center_y(int(z.row))-game.CELL_SIZE.y*.62)
		game.draw_line(top,top+Vector2(0,unit*.32),Color(Danmaku.WOOD_DARK,.9),maxf(1,unit*.025),true)
		game.draw_colored_polygon(PackedVector2Array([top,top+Vector2(unit*.2,unit*.03+sin(game.level_time*7.0+float(z.uid))*unit*.02),top+Vector2(0,unit*.13)]),Color(Danmaku.CRIMSON,.9))

func draw_pillar_unit(center:Vector2,z:Dictionary)->void:
	var unit:float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	var damage:=1.0-clampf(float(z.get("health",z.get("max_health",620.0)))/maxf(1.0,float(z.get("max_health",620.0))),0.0,1.0)
	var pulse:=clampf(1.0-float(z.get("kanako_pulse",1.0))/.5,0.0,1.0)
	var foot:=center+Vector2(0,unit*.32)
	var shake:=Vector2(sin(game.level_time*40.0)*unit*.02*float(z.get("flash",0.0))*5.0,0)
	game.draw_colored_polygon(PackedVector2Array([foot+Vector2(-unit*.32,0),foot+Vector2(-unit*.18,-unit*.06),foot+Vector2(unit*.2,-unit*.05),foot+Vector2(unit*.34,0),foot+Vector2(0,unit*.08)]),Color(.2,.14,.1,.45))
	Danmaku.draw_pillar(game,foot+shake,unit*.34,unit*1.3,1.0,.25+pulse*.75,damage)
	if pulse>0:game.draw_circle(foot-Vector2(0,unit*.9),unit*(.12+.1*pulse),Color(Danmaku.RED,.35*pulse))
