extends RefCounted
const WindGodFX=preload("res://scripts/runtime/wind_god_fx.gd")
const BLUE:=Color("69cde6")
const RED:=Color("ef8399")
const GREEN:=Color("93ddac")
const WHITE:=Color("f0f0d8")
const GOLD:=Color("f1d679")
const CYAN:=Color("9ce8f2")
const RED_STAR:=Color("ef6f86")
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
			# Lasers from Sanae's two sides sweep across the lanes and cross; on
			# Hard/Lunatic the lower sweep runs the other way and both lasers
			# reflect off the lawn's edges. Aimed ofuda follow every volley,
			# and the guest stars flare where the lasers begin.
			var step:int=posmod(wave,3)
			for side in [-1,1]:
				var emitter:=guest_emitter(game,c,side)
				var k:int=step if (side<0 or r<2) else 2-step
				WindGodFX.ray_beam(dm,c,emitter,PI-side*(.1+.24*k),"miracle",1.0,maxf(2.5,game.CELL_SIZE.y*.09),12.0,r>=2,.42)
			var pending:Array=c.get("sanae_stars",[])
			for i in range(2+mini(r,1)):
				if pending.size()>=10:break
				var row:int=game.active_rows[posmod(wave+i*2+i/3,game.active_rows.size())]
				pending.append({"position":Vector2(game.BOARD_ORIGIN.x+game.CELL_SIZE.x*(5.0+float(i%2)),game._row_center_y(row)),"release":float(c.age)+1.45,"rank":r,"tint":BLUE if i%2 else GOLD})
			c["sanae_stars"]=pending
			dm._fan(c,origin,5,aim,.45,160*scale,WHITE,"sanae_ofuda",_extra(scale,12))
			_lanes(dm,c,scale,4,5,WHITE,155,12)
			cadence=1.9 if r<2 else (1.2 if r==2 else 1.55)
		"sanae_sea_opening":
			# A horizontal adaptation of the original split sea. Two warned
			# sea lasers bound one intact dry lane; the walls of spear bullets
			# grow longer as the card goes on; aimed knives fill the gap; H/L
			# add fixed down-shots from the top edge.
			var gap:int=posmod(wave,game.active_rows.size())
			var swell:=1.0+clampf(float(c.age)/maxf(1.0,float(c.duration)),0.0,1.0)*.6
			var density:=maxi(3,ceili(4*dm._attack_density_for_cast(c)*swell*.8))
			for row in game.active_rows:
				if int(row)==gap:continue
				for j in range(density):
					var p:=Vector2(origin.x,game._row_center_y(int(row))+(float(j)/maxi(1,density-1)-.5)*game.CELL_SIZE.y*.52)
					dm._bullet(c,p,PI,127*scale,BLUE,"sanae_drop",_extra(scale,14))
			for side in [-1,1]:
				var y:float=game._row_center_y(gap)+side*game.CELL_SIZE.y*.49
				dm._beam(c,Vector2(origin.x,y),Vector2(game.BOARD_ORIGIN.x+game.CELL_SIZE.x*.5,y),BLUE,1.3,maxf(2,game.CELL_SIZE.y*.06),{"damage":12.0,"duration":.45,"wg_style":"water"})
			dm._fan(c,origin,5 if r==0 else 9,aim,.55,184*scale,WHITE,"sanae_ofuda",_extra(scale,14))
			if r>=2:
				var board:=Rect2(game.BOARD_ORIGIN,game.board_size)
				for i in range(3):
					var x:=board.position.x+board.size.x*(.25+.22*i+.08*sin(wave+i))
					dm._bullet(c,Vector2(x,board.position.y-6),PI*.5,96*scale,CYAN,"sanae_drop",_extra(scale,14))
			cadence=1.8
		"sanae_prepare":
			# Star ritual: red stars hold in a pentagram and then scatter,
			# while a blue wall advances as one piece. E/N alternate red then
			# blue; H/L release both at once (Lunatic faster).
			var red_turn:=wave%2==0 or r>=2
			var blue_turn:=wave%2==1 or r>=2
			if red_turn:
				_glyph(dm,c,origin+Vector2(-game.CELL_SIZE.x*1.1,0),game.CELL_SIZE.y*.85,RED_STAR,scale,wave*.2)
			if blue_turn:
				var board:=Rect2(game.BOARD_ORIGIN,game.board_size)
				var hole:int=posmod(wave*3+1,game.active_rows.size())
				var per:=maxi(2,ceili(2*dm._attack_density_for_cast(c)))
				for i in range(game.active_rows.size()):
					if i==hole and float(c.age)>float(c.duration)*.4:continue
					for j in range(per):
						var y:float=game._row_center_y(int(game.active_rows[i]))+(float(j)/maxi(1,per-1)-.5)*game.CELL_SIZE.y*.6
						dm._bullet(c,Vector2(board.end.x+game.CELL_SIZE.x*.3,y),PI,(78.0 if r<3 else 130.0)*scale,BLUE,"sanae_star",_extra(scale,13))
						if r==3:dm._bullet(c,Vector2(board.end.x+game.CELL_SIZE.x*.75,y),PI,130.0*scale,BLUE,"sanae_star",_extra(scale,13))
			_lanes(dm,c,scale,5 if r==0 else 4+r,5,GREEN,142,13)
			cadence=1.1 if r==0 else 1.65
		"sanae_divine_wind":
			# 34-way fixed ring plus a 16-way aimed fan (after the Wind God
			# density); Yasaka's divine wind turns its ring as it flies.
			var ring:=ceili(17*dm._attack_density_for_cast(c))
			var base:=WindGodFX.noise(wave,9)*TAU if r<2 else wave*.21
			for i in range(ring):dm._bullet(c,origin,base+TAU*i/ring,124*scale,GREEN,"sanae_orb",_extra(scale,15,(.16 if i%2 else -.16) if r>=2 else 0.0))
			dm._fan(c,origin,8,aim,1.1,168*scale,WHITE,"sanae_ofuda",_extra(scale,14))
			# Retain the earlier lane pressure: ofuda sweep every planting row.
			_lanes(dm,c,scale,5,5,WHITE,179,14)
			cadence=1.0
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
static func guest_emitter(game:Control,c:Dictionary,side:int)->Vector2:
	return Vector2(c.center)+Vector2(-game.CELL_SIZE.x*.25,side*game.CELL_SIZE.y*1.25)
static func draw_star(game:Control,p:Vector2,radius:float,tint:Color,turn:float=0)->void:
	var points:=PackedVector2Array()
	for i in range(10):points.append(p+Vector2.from_angle(-PI*.5+TAU*i/10+turn)*radius*(1.0 if i%2==0 else .46))
	game.draw_colored_polygon(points,tint)
static func draw_cast(game:Control,c:Dictionary)->void:
	var unit:float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	var age:float=float(c.age)
	for star in c.get("sanae_stars",[]):
		var progress:=clampf((float(star.release)-age)/1.45,0,1)
		WindGodFX.halo(game,star.position,unit*.12,Color(star.tint,.6),1.2-progress)
		draw_star(game,star.position,unit*(.12+.08*(1-progress)),Color(star.tint,.52),age*.5)
		game.draw_arc(star.position,game.CELL_SIZE.y*(.16+.06*progress),0,TAU,18,Color(star.tint,.4),1.0,true)
	match String(c.pattern):
		"sanae_guest_stars":
			for side in [-1,1]:
				var p:=guest_emitter(game,c,side)
				WindGodFX.halo(game,p,unit*.12,Color(BLUE if side<0 else GOLD,.8))
				draw_star(game,p,unit*(.13+.02*sin(age*7.0)),Color(BLUE if side<0 else GOLD,.9),age*1.5*side)
		"sanae_prepare","sanae_ritual":
			# The star ritual's circle is drawn on the ground before the stars.
			var hub:=Vector2(c.center)+Vector2(-game.CELL_SIZE.x*1.1,0)
			WindGodFX.magic_circle(game,hub,unit*.85,"sanae_boss",age*.6,.8,.45)
		"sanae_divine_wind":
			for k in range(4):
				var a:=age*(2.4+k*.4)+TAU*k/4.0
				game.draw_arc(Vector2(c.center),unit*(.4+k*.12),a,a+PI*.8,18,Color(GREEN,.5-k*.08),maxf(1.0,unit*.03),true)
static func draw_bullet(game:Control,b:Dictionary)->void:
	# Drawn larger than the collision radius so shapes read on the lawn.
	var tint:=Color(b.color);var p:=Vector2(b.position);var radius:=float(b.radius)*1.3
	if b.age<float(b.get("arming_time",0)):tint.a*=.4
	var axis:=Vector2(b.velocity).normalized()
	if axis.is_zero_approx():axis=Vector2.LEFT
	var side:=axis.orthogonal()
	if WindGodFX.crowded(game):
		game.draw_circle(p,radius*1.1,Color(WindGodFX.INK,tint.a*.6));game.draw_circle(p,radius*.85,tint)
		return
	match String(b.shape):
		"sanae_star":
			game.draw_circle(p,radius*2.0,Color(tint,tint.a*.12))
			draw_star(game,p,radius*1.45,Color(WindGodFX.INK,tint.a*.55),float(b.age)*.6)
			draw_star(game,p,radius*1.28,tint,float(b.age)*.6)
			game.draw_circle(p,radius*.35,Color(1,1,1,tint.a*.9))
			if bool(b.get("frozen",false)):game.draw_arc(p,radius*1.8,0,TAU,12,Color(1,1,1,tint.a*.5),1.0,true)
		"sanae_ofuda":
			var long:=axis*radius*1.7;var wide:=side*radius*.62
			var card:=PackedVector2Array([p-long-wide,p+long-wide,p+long+wide,p-long+wide])
			game.draw_colored_polygon(card,Color(.97,.98,.94,tint.a))
			card.append(card[0])
			game.draw_polyline(card,Color(tint,tint.a),maxf(1.0,radius*.3),true)
			game.draw_line(p-long*.6,p+long*.6,Color(tint.darkened(.25),tint.a),maxf(.8,radius*.22),true)
		"sanae_drop":
			# The sea's "spear": a light orb trailing a crystal point.
			game.draw_circle(p,radius*1.7,Color(tint,tint.a*.14))
			game.draw_colored_polygon(PackedVector2Array([p+axis*radius*2.4,p+side*radius*.55,p-axis*radius*.5,p-side*radius*.55]),Color(tint.lightened(.3),tint.a))
			game.draw_circle(p,radius*.8,tint)
			game.draw_circle(p,radius*.38,Color(1,1,1,tint.a))
		"sanae_orb":
			WindGodFX.halo(game,p,radius,tint,.8)
			game.draw_circle(p,radius+1.5,Color(WindGodFX.INK,tint.a*.8))
			game.draw_circle(p,radius,tint)
			game.draw_circle(p,radius*.5,Color(1,1,1,tint.a*.85))
		_:
			game.draw_circle(p,radius,tint);game.draw_circle(p-Vector2(radius*.2,radius*.2),radius*.35,Color(1,1,1,tint.a*.7))
	WindGodFX.morph_flash(game,b,p,radius)
