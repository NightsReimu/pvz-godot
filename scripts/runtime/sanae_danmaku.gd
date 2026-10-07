extends RefCounted
const BLUE:=Color("69cde6")
const RED:=Color("ef8399")
const GREEN:=Color("93ddac")
const WHITE:=Color("f0f0d8")
const GOLD:=Color("f1d679")
static func _extra(scale:float,damage:float,turn:float=0.0)->Dictionary:return {"arming_time":1.15,"radius":maxf(2,4.2*scale),"damage":damage,"angular_speed":turn,"life":8.5}
static func _scale(game:Control)->float:return minf(1,minf(game.CELL_SIZE.x/100.0,game.CELL_SIZE.y/110.0))
static func _glyph(dm:RefCounted,c:Dictionary,center:Vector2,radius:float,tint:Color,scale:float,rotation:float,generation:int=0)->void:
	# Two five-point star outlines, not a radial fan with a star icon. The
	# stationary outline is warned before its original star-shaped scatter.
	var detail:=maxi(2,ceili(3*dm._attack_density_for_cast(c)))
	for edge in range(5):
		var a:=Vector2.from_angle(rotation+TAU*edge/5)*radius
		var b:=Vector2.from_angle(rotation+TAU*(edge+2)/5)*radius
		for i in range(detail):
			var p:=center+a.lerp(b,float(i)/detail)
			var extra:=_extra(scale,12.0)
			extra.merge({"freeze_at":0.0,"thaw_at":1.3,"arming_time":1.3,"sanae_generation":generation},true)
			dm._bullet(c,p,(p-center).angle(),108*scale,tint,"sanae_star",extra)
static func tick_cast(dm:RefCounted,c:Dictionary)->void:
	var splits:Array=c.get("sanae_splits",[])
	for i in range(splits.size()-1,-1,-1):
		var split:Dictionary=splits[i]
		if float(c.age)<float(split.release):continue
		var scale:=_scale(dm.game)
		if String(split.mode)=="ritual":
			for daughter in range(int(split.count)):
				var angle:float=PI+TAU*daughter/int(split.count)
				var p:Vector2=split.position+Vector2(cos(angle)*dm.game.CELL_SIZE.x*.72,sin(angle)*dm.game.CELL_SIZE.y*.8)
				_glyph(dm,c,p,dm.game.CELL_SIZE.y*.34,split.tint,scale,float(c.age)*.2,1)
		else:
			# Preparation stars split into transverse walls after the seed.
			for row in dm.game.active_rows:
				dm._fan(c,Vector2(float(split.position.x),dm.game._row_center_y(int(row))),5,PI,.12,132*scale,GOLD,"sanae_star",_extra(scale,13))
			dm._fan(c,split.position,7,PI,.45,152*scale,GREEN,"sanae_ofuda",_extra(scale,13))
		splits.remove_at(i)
	c["sanae_splits"]=splits
	var pending:Array=c.get("sanae_stars",[])
	for i in range(pending.size()-1,-1,-1):
		var star:Dictionary=pending[i]
		if float(c.age)<float(star.release):continue
		var scale:=_scale(dm.game)
		dm._ring(c,star.position,10+2*int(star.rank),float(c.wave)*.18,116*scale,star.tint,"sanae_star",_extra(scale,13.0))
		if int(star.rank)>0:dm._fan(c,star.position,7,(Vector2(dm._target(star.position))-Vector2(star.position)).angle(),.6,167*scale,WHITE,"sanae_ofuda",_extra(scale,14.0))
		pending.remove_at(i)
	c["sanae_stars"]=pending
static func _lanes(dm:RefCounted,c:Dictionary,scale:float,rows:int,shots:int,tint:Color,speed:float,damage:float)->void:
	var game:Control=dm.game
	for i in range(mini(rows,game.active_rows.size())):
		var row:int=game.active_rows[posmod(int(c.wave)+i*2+i/3,game.active_rows.size())]
		dm._fan(c,Vector2(float(c.center.x),game._row_center_y(row)),shots,PI,.2,speed*scale,tint,"sanae_ofuda",_extra(scale,damage))
static func emit(dm:RefCounted,c:Dictionary)->void:
	var game:Control=dm.game;var r:int=int(game.TouhouDifficulty.profile(game.current_level).rank)
	var scale:=_scale(game);var origin:=Vector2(c.center);var wave:=int(c.wave);var cadence:=1.6
	var aim:float=(Vector2(dm._target(origin))-origin).angle()
	match String(c.pattern):
		"nonspell_sanae_ofuda":
			_lanes(dm,c,scale,4,5,BLUE,150,10)
			dm._fan(c,origin,9,aim,1.2,144*scale,WHITE,"sanae_ofuda",_extra(scale,11))
			cadence=1.85
		"sanae_ritual":
			var radius:float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)*.72
			var splits:Array=c.get("sanae_splits",[])
			for side in [-1,1]:
				var center:=origin+Vector2(-game.CELL_SIZE.x*.9,side*game.CELL_SIZE.y*1.1)
				_glyph(dm,c,center,radius,BLUE if side<0 else RED,scale,float(wave)*.17)
				if splits.size()<8:splits.append({"mode":"ritual","position":center,"release":float(c.age)+1.6,"count":3 if r==0 else 5,"tint":BLUE if side<0 else RED})
			c["sanae_splits"]=splits
			# Five ray origins retain the expanding star-ritual topology at all
			# tiers. Difficulty increases daughter fans, not a generic ring.
			_lanes(dm,c,scale,3+r,4,WHITE,145,11)
			cadence=2.8
		"sanae_guest_stars":
			var pending:Array=c.get("sanae_stars",[])
			for i in range(3+mini(r,2)):
				if pending.size()>=10:break
				var row:int=game.active_rows[posmod(wave+i*2+i/3,game.active_rows.size())]
				pending.append({"position":Vector2(game.BOARD_ORIGIN.x+game.CELL_SIZE.x*(5.0+float(i%2)),game._row_center_y(row)),"release":float(c.age)+1.45,"rank":r,"tint":BLUE if i%2 else GOLD})
			c["sanae_stars"]=pending
			_lanes(dm,c,scale,4,5,WHITE,155,12)
			cadence=1.9
		"sanae_sea_opening":
			# A horizontal adaptation of the original split sea. Two warned
			# boundaries enclose one intact dry lane; aimed knives fill the gap.
			var gap:int=posmod(wave,game.active_rows.size())
			var density:=maxi(3,ceili(4*dm._attack_density_for_cast(c)))
			for row in game.active_rows:
				if int(row)==gap:continue
				for j in range(density):
					var p:=Vector2(origin.x,game._row_center_y(int(row))+(float(j)/maxi(1,density-1)-.5)*game.CELL_SIZE.y*.52)
					dm._bullet(c,p,PI,127*scale,BLUE,"sanae_drop",_extra(scale,14))
			for side in [-1,1]:
				var y:float=game._row_center_y(gap)+side*game.CELL_SIZE.y*.49
				dm._beam(c,Vector2(origin.x,y),Vector2(game.BOARD_ORIGIN.x+game.CELL_SIZE.x*.5,y),BLUE,1.3,maxf(2,game.CELL_SIZE.y*.04),{"damage":12.0,"duration":.45})
			dm._fan(c,origin,5 if r==0 else 9,aim,.55,184*scale,WHITE,"sanae_ofuda",_extra(scale,14))
			cadence=1.8
		"sanae_prepare":
			var splits:Array=c.get("sanae_splits",[])
			for layer in range(2+mini(r,1)):
				var row:int=game.active_rows[posmod(wave*2+layer*3,game.active_rows.size())]
				var point:=Vector2(origin.x-game.CELL_SIZE.x*(.8+layer*.7),game._row_center_y(row))
				_glyph(dm,c,point,game.CELL_SIZE.y*.65,GOLD,scale,wave*.2)
				if splits.size()<10:splits.append({"mode":"prepare","position":point-Vector2(game.CELL_SIZE.x*.8,0),"release":float(c.age)+1.5})
			c["sanae_splits"]=splits
			_lanes(dm,c,scale,4+r,5,GREEN,142,13)
			cadence=1.65
		"sanae_divine_wind":
			for side in [-1,1]:dm._fan(c,origin+Vector2(0,side*game.CELL_SIZE.y*.7),21+2*r,PI+side*.36,1.0,155*scale,GREEN,"sanae_ofuda",_extra(scale,15,side*.32))
			_lanes(dm,c,scale,5,5,WHITE,179,14)
			cadence=1.25
		"sanae_frog_procession","sanae_frog_garden":
			_lanes(dm,c,scale,5,6,GREEN,150,13)
			dm._fan(c,origin,13,aim,1.25,148*scale,GOLD,"sanae_star",_extra(scale,13,.12))
		"sanae_weather":
			for row in game.active_rows:dm._fan(c,Vector2(origin.x,game._row_center_y(int(row))),7,PI,.3,143*scale,BLUE if wave%2 else GOLD,"sanae_drop",_extra(scale,13))
			cadence=1.65
		"sanae_rice","sanae_pillars","sanae_faith":
			_lanes(dm,c,scale,6,7,WHITE,168,15)
			for side in [-1,1]:dm._fan(c,origin,11,PI+side*.22,.8,149*scale,GREEN,"sanae_ofuda",_extra(scale,14,side*.22))
			cadence=1.4
	c.next_wave=float(c.age)+maxf(.82,cadence*game.TouhouDifficulty.attack_cadence("sanae_boss",game.current_level))
static func draw_star(game:Control,p:Vector2,radius:float,tint:Color,turn:float=0)->void:
	var points:=PackedVector2Array()
	for i in range(10):points.append(p+Vector2.from_angle(-PI*.5+TAU*i/10+turn)*radius*(1.0 if i%2==0 else .46))
	game.draw_colored_polygon(points,tint)
static func draw_cast(game:Control,c:Dictionary)->void:
	for star in c.get("sanae_stars",[]):
		var progress:=clampf((float(star.release)-float(c.age))/1.45,0,1)
		draw_star(game,star.position,minf(game.CELL_SIZE.x,game.CELL_SIZE.y)*(.12+.08*(1-progress)),Color(star.tint,.52),float(c.age)*.5)
		game.draw_arc(star.position,game.CELL_SIZE.y*(.16+.06*progress),0,TAU,18,Color(star.tint,.4),1.0,true)
static func draw_bullet(game:Control,b:Dictionary)->void:
	var tint:=Color(b.color);var p:=Vector2(b.position);var radius:=float(b.radius)
	if b.age<float(b.get("arming_time",0)):tint.a*=.4
	match String(b.shape):
		"sanae_star":draw_star(game,p,radius*1.25,tint,float(b.age)*.6)
		"sanae_ofuda":
			var axis:=Vector2(b.velocity).normalized()*radius*1.5;var side:=axis.orthogonal()*.4
			game.draw_colored_polygon(PackedVector2Array([p-axis-side,p+axis-side,p+axis+side,p-axis+side]),tint)
			game.draw_line(p-axis*.6,p+axis*.6,Color(.3,.5,.6,tint.a),maxf(.7,radius*.18),true)
		_:
			game.draw_circle(p,radius,tint);game.draw_circle(p-Vector2(radius*.2,radius*.2),radius*.35,Color(1,1,1,tint.a*.7))
