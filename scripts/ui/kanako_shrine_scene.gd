extends RefCounted
# The summit of Youkai Mountain at dusk: the Lake of the Wind God, Moriya's
# main hall and torii, and onbashira standing in several depth layers. Every
# pillar sits outside the planting cells; the six stone lanes stay readable.
const ThemeLib=preload("res://scripts/ui/game_theme.gd")
const Sprites=preload("res://scripts/data/touhou_sprite_defs.gd")
const Danmaku=preload("res://scripts/runtime/kanako_danmaku.gd")
const STONE_A:=Color("968d86")
const STONE_B:=Color("a39a91")
const STONE_EDGE:=Color("cfc6b6")
const MOSS:=Color("6f8a5a")
const INK:=Color("3a2f35")
const SKY_TOP:=Color("3d3a6e")
const SKY_MID:=Color("b7698a")
const SKY_LOW:=Color("f2b07a")
const LAKE:=Color("5c6f9a")
const MAPLE:=Color("c4523f")

static func _poly(game:CanvasItem,points:Array,tint:Color)->void:
	if tint.a<=.002:return
	game.draw_colored_polygon(PackedVector2Array(points),tint)

static func _kanako_alive(game:Control)->Dictionary:
	if not game.has_method("_find_alive_enemy_boss"):return {}
	return game._find_alive_enemy_boss("kanako_boss")

static func _dread(game:Control)->float:
	# The sky reddens as Kanako reaches her last spells.
	var boss:=_kanako_alive(game)
	if boss.is_empty():return 0.0
	var phase:=float(boss.get("boss_phase",0))/3.0
	var last:=1.0 if bool(boss.get("touhou_card",{}).get("last_spell",false)) and float(boss.get("touhou_cast_remaining",0))>0 else 0.0
	return clampf(.25+phase*.45+last*.3,0.0,1.0)

static func _sky(game:Control,rect:Rect2,alpha:float,dread:float)->void:
	var top:=SKY_TOP.lerp(Color("4a1f33"),dread*.6)
	var mid:=SKY_MID.lerp(Color("b2404d"),dread*.5)
	var low:=SKY_LOW.lerp(Color("f08a5c"),dread*.4)
	ThemeLib.draw_gradient_rect_v(game,Rect2(rect.position,Vector2(rect.size.x,rect.size.y*.42)),Color(top,alpha),Color(mid,alpha))
	ThemeLib.draw_gradient_rect_v(game,Rect2(rect.position+Vector2(0,rect.size.y*.42),Vector2(rect.size.x,rect.size.y*.58)),Color(mid,alpha),Color(low,alpha))
	# A low evening sun with soft rays behind the shrine.
	var sun:=rect.position+rect.size*Vector2(.63,.3)
	for k in range(4):game.draw_circle(sun,rect.size.y*(.16-k*.03),Color(1,.82,.6,alpha*(.06+k*.05)))
	game.draw_circle(sun,rect.size.y*.045,Color(1,.93,.78,alpha*.9))
	for k in range(9):
		var a:=-PI+PI*(k+.5)/9.0+sin(game.ui_time*.12)*.03
		game.draw_line(sun+Vector2.from_angle(a)*rect.size.y*.07,sun+Vector2.from_angle(a)*rect.size.y*.27,Color(1,.86,.66,alpha*.08),maxf(1,rect.size.x*.004),true)
	for i in range(6):
		# Drifting puffs wrap inside the painted rect, so preview cards never bleed.
		var x:=rect.position.x+rect.size.x*(.05+.78*fposmod(i*.19+game.ui_time*.004*(1+i%3),1.0))
		var y:=rect.position.y+rect.size.y*(.07+i%3*.06)
		for j in range(4):game.draw_circle(Vector2(x+j*rect.size.x*.022,y+sin(j*1.7)*rect.size.y*.008),rect.size.x*(.026+j%2*.01),Color(Color("f7d6c4").lerp(Color("e8a0a8"),dread*.5),alpha*.26))

static func _ridges(game:Control,rect:Rect2,alpha:float,dread:float)->void:
	var tones:=[Color("6d5a86"),Color("554a6c"),Color("3f3a52")]
	for layer in range(3):
		var points:Array=[Vector2(rect.position.x,rect.end.y)]
		for i in range(14):
			var t:=i/13.0
			points.append(rect.position+rect.size*Vector2(t,.3+layer*.13+sin(t*7.0+layer*1.9)*(.09-layer*.02)+sin(t*19.0+layer)*.015))
		points.append(rect.end)
		_poly(game,points,Color(Color(tones[layer]).lerp(Color("5a2a3a"),dread*.35),alpha))

static func _lake(game:Control,rect:Rect2,alpha:float,dread:float)->void:
	ThemeLib.draw_gradient_rect_v(game,rect,Color(LAKE.lerp(Color("7a3c55"),dread*.4),alpha),Color(Color("8fa0c0").lerp(Color("c06070"),dread*.3),alpha))
	var sun_x:=rect.position.x+rect.size.x*.63
	for k in range(8):
		var y:=rect.position.y+rect.size.y*(k+.5)/8.0
		var w:=rect.size.x*(.03+k*.012)*(1.0+.15*sin(game.ui_time*1.3+k))
		game.draw_line(Vector2(sun_x-w,y),Vector2(sun_x+w,y),Color(1,.86,.66,alpha*(.35-k*.03)),maxf(1,rect.size.y*.05),true)
	for k in range(14):
		var x:=rect.position.x+rect.size.x*fposmod(k*.137+game.ui_time*.01,1.0)
		var y:=rect.position.y+rect.size.y*(.2+fposmod(k*.31,0.7))
		game.draw_line(Vector2(x,y),Vector2(x+rect.size.x*.03,y),Color(1,1,1,alpha*.18),1.0,true)
	# The Omiwatari ice ridge of the god's crossing, faint on the far water.
	var ridge:=PackedVector2Array()
	for k in range(10):ridge.append(rect.position+rect.size*Vector2(.08+k*.09,.45+(.12 if k%2 else -.1)))
	game.draw_polyline(ridge,Color(.9,.95,1,alpha*.35),maxf(1,rect.size.y*.06),true)

static func _hall(game:Control,base:Vector2,w:float,h:float,alpha:float)->void:
	# Moriya's main hall: stone podium, vermilion posts, deep cypress roof with
	# crossed chigi and katsuogi logs, and a heavy shimenawa over the doors.
	for i in range(3):game.draw_rect(Rect2(base-Vector2(w*(.6+i*.04),-i*h*.07),Vector2(w*(1.2+i*.08),h*.07)),Color(Color("7d7480").lerp(Color("5c5560"),i*.3),alpha))
	game.draw_rect(Rect2(base-Vector2(w*.5,h),Vector2(w,h)),Color("8a5a3c",alpha))
	game.draw_rect(Rect2(base-Vector2(w*.2,h*.82),Vector2(w*.4,h*.82)),Color("3b2a2d",alpha))
	for k in range(4):game.draw_line(base+Vector2(-w*.2+w*.4*(k+.5)/4.0,-h*.82),base+Vector2(-w*.2+w*.4*(k+.5)/4.0,0),Color("6b4a3a",alpha*.6),maxf(1,w*.01),true)
	for side in [-1,1]:
		for k in range(2):game.draw_rect(Rect2(base+Vector2(side*w*(.44-k*.22)-w*.03,-h*1.02),Vector2(w*.06,h*1.02)),Color("b94a37",alpha))
	_poly(game,[base+Vector2(-w*.82,-h*.86),base+Vector2(-w*.9,-h*1.02),base+Vector2(-w*.62,-h*.98),base+Vector2(-w*.3,-h*1.5),base+Vector2(w*.3,-h*1.5),base+Vector2(w*.62,-h*.98),base+Vector2(w*.9,-h*1.02),base+Vector2(w*.82,-h*.86)],Color("3e3542",alpha))
	for i in range(11):
		var x:=lerpf(-w*.3,w*.3,i/10.0)
		game.draw_line(base+Vector2(x,-h*1.48),base+Vector2(x*2.6,-h*.92),Color("6c6070",alpha*.55),maxf(.7,w*.008),true)
	game.draw_line(base+Vector2(-w*.82,-h*.86),base+Vector2(w*.82,-h*.86),Color("d8c6a0",alpha),maxf(1.2,w*.016),true)
	for k in range(5):
		var x:=lerpf(-w*.22,w*.22,k/4.0)
		game.draw_line(base+Vector2(x-w*.04,-h*1.53),base+Vector2(x+w*.04,-h*1.53),Color("d7b56a",alpha),maxf(1.5,h*.06),true)
	for side in [-1,1]:
		game.draw_line(base+Vector2(side*w*.24,-h*1.46),base+Vector2(side*w*.44,-h*1.82),Color("d7b56a",alpha),maxf(1.2,w*.018),true)
		game.draw_line(base+Vector2(side*w*.3,-h*1.46),base+Vector2(side*w*.12,-h*1.8),Color("d7b56a",alpha),maxf(1.2,w*.018),true)
	var rope:=PackedVector2Array()
	for i in range(17):rope.append(base+Vector2(lerpf(-w*.46,w*.46,i/16.0),-h*.82+sin(PI*i/16.0)*h*.16))
	game.draw_polyline(rope,Color(Danmaku.ROPE,alpha),maxf(2,w*.035),true)
	game.draw_polyline(rope,Color(Danmaku.ROPE_DARK,alpha*.7),maxf(1,w*.012),true)
	for i in [3,6,10,13]:
		Danmaku.draw_shide(game,rope[i],w*.1,alpha,sin(game.ui_time*1.8+i)*.18)
	game.draw_circle(base+Vector2(0,-h*1.2),h*.11,Color("d7b56a",alpha))
	Danmaku.draw_crest(game,base+Vector2(0,-h*1.2),h*.08,Color("5a2a2e",alpha))

static func _torii(game:CanvasItem,base:Vector2,w:float,h:float,alpha:float)->void:
	var stroke:=maxf(1.5,w*.08)
	for side in [-1,1]:game.draw_line(base+Vector2(side*w*.36,0),base+Vector2(side*w*.32,-h),Color("c0442f",alpha),stroke,true)
	game.draw_line(base+Vector2(-w*.6,-h*1.02),base+Vector2(w*.6,-h*1.02),Color("2d2326",alpha),stroke*1.25,true)
	game.draw_line(base+Vector2(-w*.55,-h*.96),base+Vector2(w*.55,-h*.96),Color("c0442f",alpha),stroke,true)
	game.draw_line(base+Vector2(-w*.44,-h*.78),base+Vector2(w*.44,-h*.78),Color("c0442f",alpha),stroke*.8,true)

static func _pillar_forest(game:Control,rect:Rect2,alpha:float,layer:int)->void:
	# Deterministic placements; far pillars are hazier and thinner.
	var count:int=[9,7,5][layer]
	for i in range(count):
		var t:=fposmod(i*.618+layer*.21,1.0)
		var x:=rect.position.x+rect.size.x*t
		var foot:=rect.position.y+rect.size.y*(.55+layer*.2+Danmaku.noise(i,layer)*.08)
		var w:=rect.size.x*(.008+layer*.006)*(.8+.4*Danmaku.noise(i,layer+9))
		var h:=rect.size.y*(.22+layer*.12)*(.8+.4*Danmaku.noise(i,layer+19))
		Danmaku.draw_pillar(game,Vector2(x,foot),w,h,alpha*(.55+layer*.2))

static func _landscape(game:Control,rect:Rect2,alpha:float=1.0,dread:float=0.0)->void:
	_sky(game,rect,alpha,dread)
	_ridges(game,Rect2(rect.position+Vector2(0,rect.size.y*.08),Vector2(rect.size.x,rect.size.y*.4)),alpha,dread)
	_lake(game,Rect2(rect.position+Vector2(0,rect.size.y*.4),Vector2(rect.size.x,rect.size.y*.1)),alpha,dread)
	_pillar_forest(game,Rect2(rect.position+Vector2(0,rect.size.y*.3),Vector2(rect.size.x,rect.size.y*.2)),alpha,0)
	# Shrine grounds: a pale gravel terrace above the lake shore.
	_poly(game,[rect.position+rect.size*Vector2(0,.5),rect.position+rect.size*Vector2(.2,.46),rect.position+rect.size*Vector2(.8,.45),rect.position+rect.size*Vector2(1,.49),rect.end,rect.position+rect.size*Vector2(0,1)],Color(Color("8c8079").lerp(Color("6d4a4e"),dread*.3),alpha))
	_hall(game,rect.position+rect.size*Vector2(.5,.47),rect.size.x*.13,rect.size.y*.13,alpha)
	_torii(game,rect.position+rect.size*Vector2(.27,.49),rect.size.x*.07,rect.size.y*.12,alpha)
	_pillar_forest(game,Rect2(rect.position+Vector2(0,rect.size.y*.25),Vector2(rect.size.x,rect.size.y*.32)),alpha,1)

static func _lantern(game:CanvasItem,foot:Vector2,h:float,alpha:float,glow:float)->void:
	# A stone tōrō: base, post, fire box with a warm window, and a curved cap.
	var w:=h*.36
	var stone:=Color("8a8381",alpha);var dark:=Color("5e5755",alpha)
	game.draw_rect(Rect2(foot-Vector2(w*.5,h*.1),Vector2(w,h*.1)),dark)
	game.draw_rect(Rect2(foot-Vector2(w*.16,h*.55),Vector2(w*.32,h*.46)),stone)
	game.draw_rect(Rect2(foot-Vector2(w*.42,h*.62),Vector2(w*.84,h*.08)),dark)
	game.draw_rect(Rect2(foot-Vector2(w*.34,h*.82),Vector2(w*.68,h*.2)),stone)
	game.draw_rect(Rect2(foot-Vector2(w*.16,h*.78),Vector2(w*.32,h*.12)),Color(1,.78,.42,alpha*(.55+.45*glow)))
	game.draw_circle(foot-Vector2(0,h*.72),w*.5,Color(1,.7,.35,alpha*.12*glow))
	_poly(game,[foot+Vector2(-w*.62,-h*.82),foot+Vector2(w*.62,-h*.82),foot+Vector2(w*.3,-h*.96),foot+Vector2(-w*.3,-h*.96)],dark)
	game.draw_circle(foot-Vector2(0,h*.99),w*.1,dark)

static func draw_background(game:Control)->void:
	var dread:=_dread(game)
	var full:=Rect2(Vector2.ZERO,game.size)
	var board:=Rect2(game.BOARD_ORIGIN,game.board_size)
	var left_room:float=board.position.x-10.0
	var right_left:float=board.end.x+8.0
	var right_room:float=game.size.x-right_left
	var wide:=left_room>=90.0 and right_room>=90.0
	# Wide screens put the horizon beside the lawn so both margins show sky,
	# peaks, the lake and the shrine grounds; phones keep it above the lawn.
	var horizon:float=board.position.y+board.size.y*.3 if wide else maxf(board.position.y*.82,game.size.y*.24)
	var span:float=maxf(140.0,horizon)
	_sky(game,Rect2(Vector2.ZERO,Vector2(full.size.x,horizon+span*.1)),1.0,dread)
	_ridges(game,Rect2(Vector2(0,horizon-span*.45),Vector2(full.size.x,span*.47)),1.0,dread)
	var lake_h:float=span*.12
	_lake(game,Rect2(Vector2(0,horizon),Vector2(full.size.x,lake_h)),1.0,dread)
	var ground_top:float=horizon+lake_h
	ThemeLib.draw_gradient_rect_v(game,Rect2(Vector2(0,ground_top),Vector2(full.size.x,maxf(1,full.size.y-ground_top))),Color("8b7f78").lerp(Color("6d4a4e"),dread*.3),Color("514746"))
	for k in range(40):
		var x:=fposmod(k*173.3,full.size.x);var y:=ground_top+fposmod(k*97.1,maxf(1,full.size.y-ground_top))
		game.draw_circle(Vector2(x,y),1.5+k%3,Color(MOSS,.22) if k%3 else Color(.92,.88,.8,.18))
	# Far pillars stand along the shore and in the shallows, in two depths.
	var shore:=Rect2(Vector2(0,horizon-span*.16),Vector2(full.size.x,span*.3))
	for i in range(18):
		var t:=fposmod(i*.618034+.07,1.0)
		var foot:=Vector2(full.size.x*t,shore.position.y+shore.size.y*(.55+Danmaku.noise(i,3)*.4))
		var h:=span*(.13+Danmaku.noise(i,5)*.1)
		Danmaku.draw_pillar(game,foot,maxf(2.0,h*.1),h,.7)
		game.draw_line(foot+Vector2(-h*.08,2),foot+Vector2(h*.08,2),Color(1,1,1,.18),1.0,true)
	if wide:
		# A middle row of pillars on the shrine grounds, between shore and lawn.
		for side in [0,1]:
			for i in range(4):
				var x:float=(left_room*(.12+i*.24)) if side==0 else (right_left+right_room*(.1+i*.27))
				var foot:=Vector2(x,ground_top+span*(.1+Danmaku.noise(i,side+31)*.12))
				var h:=span*(.36+Danmaku.noise(i,side+41)*.18)
				Danmaku.draw_pillar(game,foot,maxf(4.0,h*.075),h,.85,dread*.3)
		# Moriya's hall rises behind Kanako in the right margin; a torii and
		# stone lanterns mark the approach on the left.
		_hall(game,Vector2(right_left+right_room*.52,ground_top+span*.24),right_room*.42,span*.32,1.0)
		_torii(game,Vector2(left_room*.5,ground_top+span*.36),left_room*.62,span*.62,1.0)
		var glow:=.6+.4*sin(game.ui_time*2.3)
		_lantern(game,Vector2(left_room*.2,ground_top+span*.62),span*.3,1.0,glow)
		_lantern(game,Vector2(right_left+right_room*.18,ground_top+span*.7),span*.3,1.0,glow)
	else:
		_hall(game,Vector2(board.get_center().x,ground_top+lake_h*.6),board.size.x*.11,span*.2,1.0)
		_torii(game,Vector2(board.position.x+board.size.x*.24,ground_top+lake_h*.8),board.size.x*.06,span*.22,1.0)
	# A giant shimenawa ring hangs in the sky while Kanako declares a card.
	var boss:=_kanako_alive(game)
	if not boss.is_empty() and float(boss.get("touhou_cast_remaining",0))>0 and String(boss.get("touhou_card",{}).get("origin",""))!="nonspell":
		var ring_c:=Vector2(right_left+right_room*.5 if wide else board.end.x-board.size.x*.12,horizon-span*.42)
		var ring_r:=span*.3
		var turn:float=game.ui_time*.15
		var rope:=PackedVector2Array()
		for k in range(49):rope.append(ring_c+Vector2.from_angle(turn+TAU*k/48.0)*ring_r)
		game.draw_polyline(rope,Color(Danmaku.ROPE,.32+.25*dread),maxf(3,ring_r*.12),true)
		for k in range(24):
			var a:float=turn+TAU*k/24.0
			game.draw_line(ring_c+Vector2.from_angle(a)*ring_r*.93,ring_c+Vector2.from_angle(a+.13)*ring_r*1.07,Color(Danmaku.ROPE_DARK,.35+.25*dread),maxf(1,ring_r*.035),true)
	# Mid pillars inside the margins, near pillars framing the screen edges,
	# joined by sagging shimenawa with fluttering shide.
	var foot_y:float=board.end.y+game.CELL_SIZE.y*.25
	var near:Array=[]
	if left_room>18:near.append_array([[Vector2(maxf(8.0,left_room*.16),full.size.y+6),1.0],[Vector2(left_room*.78,foot_y-board.size.y*.18),.62]])
	if right_room>18:near.append_array([[Vector2(full.size.x-maxf(8.0,right_room*.14),full.size.y+6),1.0],[Vector2(right_left+right_room*.36,foot_y-board.size.y*.12),.62]])
	var thick:float=clampf(minf(left_room,right_room)*.2,8.0,34.0)
	var tops:Array=[]
	for entry in near:
		var p:Vector2=entry[0];var scale:float=float(entry[1])
		var h:float=(full.size.y-board.position.y*.35)*scale
		Danmaku.draw_pillar(game,p,thick*scale,h,1.0,dread*.5)
		tops.append(p-Vector2(0,h*.8))
	if tops.size()>=2:_rope_between(game,tops[0],tops[1],dread)
	if tops.size()>=4:_rope_between(game,tops[2],tops[3],dread)
	game._draw_panel_shell(board.grow(8),Color("5c4b4e"),Color("d8c6a6"),.12,.04)
	game._draw_panel_shell(game.COIN_METER_RECT,Color("eadfcb"),INK,.12,.06)
	game._draw_coin_icon(game.COIN_METER_RECT.position+Vector2(22,20),1.0)
	ThemeLib.draw_label(game,game.ui_font,Rect2(game.COIN_METER_RECT.position+Vector2(44,4),Vector2(game.COIN_METER_RECT.size.x-52,game.COIN_METER_RECT.size.y-8)),str(game.coins_total),22,INK)
	game._draw_fancy_button(game.BACK_BUTTON_RECT,"返回地图",Color("eadfcb"),INK,18)

static func _rope_between(game:CanvasItem,a:Vector2,b:Vector2,dread:float)->void:
	var rope:=PackedVector2Array()
	for i in range(13):
		var t:=i/12.0
		rope.append(a.lerp(b,t)+Vector2(0,sin(PI*t)*a.distance_to(b)*.12))
	game.draw_polyline(rope,Color(Danmaku.ROPE.lerp(Color("e07a6a"),dread*.3)),maxf(2,a.distance_to(b)*.02),true)
	for i in [3,6,9]:
		var p:Vector2=rope[i];var z:=maxf(2.0,a.distance_to(b)*.018)
		Danmaku.draw_shide(game,p,z*1.4,1.0,sin(Time.get_ticks_msec()*.002+i)*.25)

static func draw_board(game:Control)->void:
	var unit:float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	for row in range(6):
		for col in range(game.COLS):
			var rect:Rect2=game._cell_rect(row,col)
			var tone:=STONE_A if (row+col)%2==0 else STONE_B
			game.draw_rect(rect,tone.lerp(Color("a39a8e"),Danmaku.noise(row,col)*.25))
			game.draw_rect(rect.grow(-maxf(.8,unit*.03)),Color(STONE_EDGE,.42),false,maxf(.8,unit*.016))
			game.draw_line(rect.position+Vector2(2,rect.size.y-2),rect.end-Vector2(2,2),Color(INK,.28),maxf(.8,unit*.025),true)
			# Moss in the joints, a few fallen maple leaves, worn cracks.
			if (row*5+col)%4==0:game.draw_circle(rect.position+Vector2(rect.size.x*.08,rect.size.y*.9),unit*.05,Color(MOSS,.55))
			if (row*7+col*3)%9==0:
				var leaf:=rect.position+rect.size*Vector2(.2+Danmaku.noise(row,col+40)*.6,.2+Danmaku.noise(row+9,col)*.6)
				_leaf(game,leaf,unit*.06,Danmaku.noise(row,col)*TAU,Color(MAPLE,.55))
			if (row*3+col)%7==0:game.draw_polyline(PackedVector2Array([rect.position+rect.size*Vector2(.66,.06),rect.position+rect.size*Vector2(.58,.24),rect.position+rect.size*Vector2(.66,.36)]),Color(INK,.24),maxf(.7,unit*.015),true)
	# The sacred precinct begins at the shimenawa along the lawn's right edge.
	var x:float=game.BOARD_ORIGIN.x+game.board_size.x-2.0
	var rope:=PackedVector2Array()
	for i in range(25):
		var t:=i/24.0
		rope.append(Vector2(x+sin(t*TAU*3.0)*unit*.02,game.BOARD_ORIGIN.y+game.board_size.y*t))
	game.draw_polyline(rope,Color(Danmaku.ROPE,.55),maxf(1.5,unit*.05),true)

static func _leaf(game:CanvasItem,p:Vector2,size:float,angle:float,tint:Color)->void:
	var points:=PackedVector2Array()
	for v in [Vector2(0,-1),Vector2(.3,-.35),Vector2(.85,-.55),Vector2(.5,0),Vector2(.9,.3),Vector2(.25,.35),Vector2(0,.9),Vector2(-.25,.35),Vector2(-.9,.3),Vector2(-.5,0),Vector2(-.85,-.55),Vector2(-.3,-.35)]:
		points.append(p+Vector2(v).rotated(angle)*size)
	game.draw_colored_polygon(points,tint)

static func draw_preview(game:Control,rect:Rect2,alpha:float,show_label:bool)->void:
	_landscape(game,rect,alpha,0.0)
	var board:=Rect2(rect.position+rect.size*Vector2(.13,.58),rect.size*Vector2(.73,.38))
	for row in range(6):
		for col in range(9):game.draw_rect(Rect2(board.position+board.size*Vector2(col/9.0,row/6.0),board.size/Vector2(9,6)-Vector2(.4,.4)),Color(STONE_A if (row+col)%2 else STONE_B,alpha))
	for side in [0,1]:Danmaku.draw_pillar(game,Vector2(rect.position.x+rect.size.x*(.06 if side==0 else .93),rect.end.y-2),maxf(3,rect.size.x*.022),rect.size.y*.55,alpha)
	if show_label:ThemeLib.draw_label(game,game.ui_font,Rect2(rect.position+Vector2(8,4),Vector2(rect.size.x-16,24)),"守矢神社 · 御柱林立的风神之湖",15,Color("fbefe0",alpha))

static func draw_ambient(game:Control)->void:
	var windy:bool=game.ancient_expansion!=null and game.ancient_expansion.is_weather(["wind","storm"])
	var drift:=2.2 if windy else 1.0
	for i in range(14):
		var fall:=fposmod(i*0.137+game.ui_time*(.035+i%4*.006),1.0)
		var p:=Vector2(fposmod(i*157.3-game.ui_time*(22.0*drift)+sin(game.ui_time*.8+i)*30.0,game.size.x+40.0)-20.0,fall*(game.size.y+40.0)-20.0)
		_leaf(game,p,4.0+i%3*1.5,game.ui_time*(1.2+i%3*.4)+i,Color(MAPLE.lerp(Color("e6a04a"),(i%4)/4.0),.55))
	if windy:
		for i in range(8):
			var y:float=game.BOARD_ORIGIN.y+game.board_size.y*fposmod(i*.29+.05,1.0)
			var x:=fposmod(game.ui_time*340.0+i*211.0,game.size.x+300.0)-150.0
			game.draw_line(Vector2(x,y),Vector2(x+90,y-6),Color(1,1,1,.12),1.4,true)

static func draw_boss(game:Control,center:Vector2,boss:Dictionary)->void:
	var portrait:bool=bool(boss.get("portrait",false))
	var unit_scale:float=1.0 if portrait else game._battle_unit_scale()
	var fit:=1.0
	if not portrait:
		var top:float=maxf(game.SEED_BANK_RECT.end.y,maxf(game.COIN_METER_RECT.end.y,game.BACK_BUTTON_RECT.end.y))+4
		var room:float=game._row_center_y(int(boss.row))-top
		fit=clampf(room/maxf(1,Sprites.BODY_HEIGHT*unit_scale),.36,1.0)
	var texture:Texture2D=game._try_get_boss_frame_texture("kanako_boss",game._ensure_kanako_runtime().frame_index(boss))
	if texture==null:return
	var scale:float=game._touhou_boss_draw_scale("kanako_boss")*fit
	var size:Vector2=texture.get_size()*scale
	var casting:=float(boss.get("touhou_cast_remaining",0))>0 and String(boss.get("touhou_card",{}).get("origin",""))!="nonspell"
	var t:float=game.ui_time
	var body:=center+Vector2(0,-size.y*.28)
	# Shadow on the stone, then a divine aura behind her rope ring.
	game.draw_colored_polygon(_ellipse(center+Vector2(0,30*fit),46*fit,9*fit),Color(.1,.03,.06,.3))
	if casting:
		var last:=bool(boss.get("touhou_card",{}).get("last_spell",false))
		var aura:=Color(Danmaku.RED,.16 if not last else .26)
		for k in range(3):game.draw_circle(body,(62+k*14+sin(t*3.0+k)*4)*fit,Color(aura,aura.a*(1.0-k*.3)))
		# Four miniature onbashira orbit behind her during formal cards.
		for k in range(4):
			var a:=t*.9+TAU*k/4.0
			var p:=body+Vector2(cos(a)*72*fit,sin(a)*26*fit)
			if sin(a)<0:Danmaku.draw_pillar(game,p+Vector2(0,20*fit),9*fit,40*fit,.85,.6)
	game.draw_texture_rect(texture,Rect2(center+Vector2(-size.x*.5,Sprites.top_offset("kanako_boss")*fit),size),false,Color.WHITE)
	if casting:
		for k in range(4):
			var a:=t*.9+TAU*k/4.0
			var p:=body+Vector2(cos(a)*72*fit,sin(a)*26*fit)
			if sin(a)>=0:Danmaku.draw_pillar(game,p+Vector2(0,20*fit),9*fit,40*fit,.92,.6)
		# A glint sweeps across the mirror she carries.
		var glint:=body+Vector2(-6*fit,6*fit)
		var sweep:=fposmod(t*.8,1.0)
		game.draw_line(glint+Vector2(-10,-10)*fit*sweep,glint+Vector2(10,10)*fit*sweep,Color(1,1,1,.5*(1.0-sweep)),2.0*fit,true)

static func _ellipse(center:Vector2,rx:float,ry:float)->PackedVector2Array:
	var points:=PackedVector2Array()
	for k in range(20):points.append(center+Vector2(cos(TAU*k/20.0)*rx,sin(TAU*k/20.0)*ry))
	return points

static func draw_effect(game:Control,effect:Dictionary)->void:
	var ratio:=clampf(float(effect.time)/maxf(.01,float(effect.duration)),0.0,1.0)
	var p:=Vector2(effect.position);var grow:=1.0-ratio
	var radius:=float(effect.get("radius",72.0))*(.5+grow*.9)
	match String(effect.get("shape","")):
		"kanako_spell_seal":
			# Her great shimenawa ring flares and a kaji-leaf crest is stamped.
			var rope:=PackedVector2Array()
			for k in range(41):rope.append(p+Vector2.from_angle(TAU*k/40.0+grow*.6)*radius)
			game.draw_polyline(rope,Color(Danmaku.ROPE,ratio*.9),maxf(2,radius*.12),true)
			for k in range(20):
				var a:=TAU*k/20.0+grow*.6
				game.draw_line(p+Vector2.from_angle(a)*radius*.94,p+Vector2.from_angle(a+.12)*radius*1.06,Color(Danmaku.ROPE_DARK,ratio*.9),maxf(1,radius*.04),true)
			Danmaku.draw_crest(game,p,radius*.35,Color(Danmaku.RED,ratio*.7))
		"kanako_arrival":
			for k in range(3):game.draw_arc(p,radius*(.6+k*.25),0,TAU,40,Color(Danmaku.RED,ratio*(.6-k*.15)),maxf(1.5,4.0-k),true)
			Danmaku.draw_crest(game,p,radius*.22,Color(1,.9,.8,ratio*.8))
		_:
			game.draw_circle(p,radius,Color(effect.color,ratio*float(Color(effect.color).a)))
