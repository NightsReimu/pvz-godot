extends RefCounted
const Sprites=preload("res://scripts/data/sanae_sprite_defs.gd")
const WARNING:=1.4
const MAX_FIELDS:=10
const MAX_FROGS:=6
var game:Control
var fields:Array[Dictionary]=[]
var serial:=0
func _init(owner:Control)->void:game=owner
func boss_for(uid:int)->Dictionary:
	for b in game.zombies:
		if int(b.get("uid",-1))==uid and String(b.kind)=="sanae_boss" and float(b.health)>0:return b
	return {}
func sheltered(row:int,col:int)->bool:
	var p=game._targetable_plant_at(row,col)
	return p!=null and (game._is_cell_protected_by_umbrella(row,col) or float(p.get("holy_invincible_timer",0))>0 or bool(p.get("ultimate_active",false)))
func _unfrog(p)->void:
	if p==null:return
	for key in ["sanae_frog_until","sanae_frog_owner"]:p.erase(key)
func reset()->void:
	for f in fields:_unfrog(f.get("target"))
	fields.clear();serial=0
	for layer in [game.grid,game.support_grid]:
		for row in layer:
			for p in row:_unfrog(p)
func clear_owner(owner:int)->void:
	for f in fields:
		if int(f.owner)==owner:_unfrog(f.get("target"))
	fields=fields.filter(func(f):return int(f.owner)!=owner)
	for z in game.zombies:
		if String(z.kind)=="sanae_frog" and int(z.get("sanae_owner",-1))==owner:z.health=0.0;z["sanae_expired"]=true
	if game.ancient_expansion!=null and int(game.ancient_expansion.override_owner)==owner:
		game.ancient_expansion.override_until=game.level_time
func cleanse_row(row:int)->void:
	for f in fields:
		if int(f.cell.x)==row:_unfrog(f.get("target"))
	fields=fields.filter(func(f):return int(f.cell.x)!=row)
func frame_index(boss:Dictionary)->int:return Sprites.frame_index(boss,game.level_time if game.mode==game.MODE_BATTLE else game.ui_time)
func _rank()->int:return int(game.TouhouDifficulty.profile(game.current_level).rank)
func _busy_cells(amount:int)->Array[Vector2i]:
	var choices:Array=[]
	for row in game.active_rows:
		for col in range(game.COLS):
			var p=game._targetable_plant_at(int(row),col)
			if p==null or float(p.health)<=0 or sheltered(int(row),col):continue
			choices.append({"cell":Vector2i(int(row),col),"score":(20 if p.has("fusion_kind") else 0)+col*.1,"tie":posmod(int(row)*9+col+serial*11,54)})
	choices.sort_custom(func(a,b):return a.score>b.score or (a.score==b.score and a.tie<b.tie))
	var result:Array[Vector2i]=[]
	for c in choices:
		if result.size()>=amount:break
		if result.any(func(cell):return cell.x==c.cell.x):continue
		result.append(c.cell)
	return result
func queue_field(owner:int,cell:Vector2i,mode:String,duration:float=5.0)->void:
	if fields.size()>=MAX_FIELDS or boss_for(owner).is_empty() or not game._is_row_active(cell.x) or cell.y<0 or cell.y>=game.COLS:return
	if fields.any(func(f):return f.owner==owner and f.cell==cell):return
	fields.append({"owner":owner,"cell":cell,"mode":mode,"age":0.0,"delay":WARNING,"duration":clampf(duration,1,6),"applied":false,"target":game._targetable_plant_at(cell.x,cell.y) if mode=="frog" else null})
func cast(boss:Dictionary,pattern:String)->void:
	clear_owner(int(boss.uid));serial+=1
	if pattern in ["sanae_frog_garden","sanae_faith"]:
		for cell in _busy_cells(3+_rank()):queue_field(int(boss.uid),cell,"frog",4.5+_rank()*.3)
	if pattern in ["sanae_frog_procession","sanae_faith"]:
		for i in range(2+mini(2,_rank())):
			queue_field(int(boss.uid),Vector2i(int(game.active_rows[posmod(serial+i*2,game.active_rows.size())]),6+i%2),"summon",1.0)
	if pattern in ["sanae_weather","sanae_divine_wind","sanae_pillars"]:
		var weather:String="wind" if pattern!="sanae_weather" else ["rain","storm","rainbow","storm"][_rank()]
		game._ensure_ancient_expansion().set_override(weather,int(boss.uid),minf(12,float(boss.get("touhou_cast_duration",10))),"风祝祈祷 · "+String(game._ensure_ancient_expansion().weather_info(weather).name))
	if pattern=="sanae_rice":
		game._spawn_new_touhou_finale_support("sanae_boss",int(boss.get("boss_phase",0)))
func _spawn_frog(field:Dictionary)->void:
	if game.zombies.filter(func(z):return String(z.kind)=="sanae_frog" and float(z.health)>0).size()>=MAX_FROGS:return
	var before:int=game.zombies.size()
	game._spawn_zombie_at("sanae_frog",int(field.cell.x),game._cell_center(field.cell.x,field.cell.y).x,true)
	if game.zombies.size()>before:
		var z:Dictionary=game.zombies.back();z["sanae_owner"]=int(field.owner);z["sanae_life"]=15.0;z["sanae_hop_timer"]=2.6;z["sanae_hop_age"]=-1.0
func update(delta:float)->void:
	if game.boss_time_stop_timer>0:return
	for index in range(fields.size()-1,-1,-1):
		var f:Dictionary=fields[index];f.age+=maxf(0,delta)
		if boss_for(int(f.owner)).is_empty() or float(f.age)>=float(f.delay)+float(f.duration):_unfrog(f.get("target"));fields.remove_at(index);continue
		if f.age<f.delay or bool(f.applied):continue
		f.applied=true
		if String(f.mode)=="summon":_spawn_frog(f);continue
		var p=game._targetable_plant_at(f.cell.x,f.cell.y)
		if p==null or not is_same(p,f.target) or sheltered(f.cell.x,f.cell.y):continue
		p["sanae_frog_until"]=game.level_time+float(f.duration)
		p["sanae_frog_owner"]=int(f.owner)
	for z in game.zombies:
		if String(z.kind)!="sanae_frog" or float(z.health)<=0:continue
		z.sanae_life=float(z.get("sanae_life",0))-delta
		if boss_for(int(z.get("sanae_owner",-1))).is_empty() or z.sanae_life<=0:z.health=0.0;z["sanae_expired"]=true;continue
		z.sanae_hop_timer=float(z.get("sanae_hop_timer",2.6))-delta
		if float(z.get("frozen_timer",0))>0 or float(z.get("rooted_timer",0))>0:continue
		var age:float=float(z.get("sanae_hop_age",-1))
		if age>=0:
			age+=delta;z.sanae_hop_age=age;z.jump_offset=-sin(clampf(age/.5,0,1)*PI)*game.CELL_SIZE.y*.35
			if age>=.5:
				var col:int=clampi(int((float(z.x)-game.BOARD_ORIGIN.x)/game.CELL_SIZE.x),0,game.COLS-1)
				var p=game._targetable_plant_at(int(z.row),col)
				if p==null or (not game._plant_has_component(p,"tallnut") and not game._plant_has_component(p,"anchor_fern")):z.x=maxf(game.BOARD_ORIGIN.x+game.CELL_SIZE.x*.35,float(z.x)-game.CELL_SIZE.x*.85)
				z.sanae_hop_age=-1.0;z.sanae_hop_timer=3.0;z.jump_offset=0.0
		elif z.sanae_hop_timer<=0:z.sanae_hop_age=0.0
func draw_ground()->void:
	for f in fields:
		var center:Vector2=game._cell_center(f.cell.x,f.cell.y);var unit:float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
		var ready:bool=f.age>=f.delay
		game.draw_arc(center,unit*(.24 if ready else .3),0,TAU,24,Color(.4,.95,.67,.46 if ready else .65),maxf(1,unit*.025),true)
		if not ready:game.draw_arc(center,unit*.34,-PI*.5,-PI*.5+TAU*clampf(float(f.age)/float(f.delay),0,1),20,Color(.95,.9,.58,.8),maxf(1,unit*.025),true)
func draw_overlay()->void:pass
func draw_frog(center:Vector2,scale:float=1.0,alpha:float=1.0,zombie:bool=false)->void:
	var ink:=Color("335740",alpha);var green:=Color("7aaa57",alpha)
	game.draw_circle(center,20*scale,green)
	for side in [-1,1]:
		game.draw_circle(center+Vector2(side*14,-17)*scale,8*scale,green)
		game.draw_circle(center+Vector2(side*14,-18)*scale,4*scale,Color("f3e5c4",alpha))
		game.draw_circle(center+Vector2(side*14,-18)*scale,2*scale,ink)
		game.draw_line(center+Vector2(side*18,4)*scale,center+Vector2(side*27,11)*scale,ink,maxf(1,3*scale),true)
	game.draw_arc(center+Vector2(0,-6)*scale,11*scale,.15,PI-.15,12,ink,maxf(1,1.5*scale),true)
	if zombie:game.draw_rect(Rect2(center+Vector2(-4,1)*scale,Vector2(8,11)*scale),Color("bc6761",alpha))
