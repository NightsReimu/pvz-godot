extends RefCounted
const ThemeLib=preload("res://scripts/ui/game_theme.gd")
const Sprites=preload("res://scripts/data/touhou_sprite_defs.gd")
const Danmaku=preload("res://scripts/runtime/sanae_danmaku.gd")
const STONE_A:=Color("8d9d91")
const STONE_B:=Color("98a99c")
const INK:=Color("354940")
static func _polygon(game:Control,points:Array,tint:Color)->void:game.draw_colored_polygon(PackedVector2Array(points),tint)
static func _pillar(game:Control,foot:Vector2,width:float,height:float,alpha:float=1.0)->void:
	var top:=foot-Vector2(0,height)
	game.draw_rect(Rect2(top-Vector2(width*.5,0),Vector2(width,height)),Color("795c40",alpha))
	game.draw_rect(Rect2(top-Vector2(width*.5,0),Vector2(width*.25,height)),Color("a18759",alpha))
	for i in range(5):game.draw_line(top+Vector2(width*(-.3+i*.14),8),foot+Vector2(width*(-.3+i*.14),-5),Color("4f4935",alpha*.3),maxf(.6,width*.035),true)
	game.draw_arc(top+Vector2(0,width*.4),width*.47,0,TAU,20,Color("d6c498",alpha),maxf(.8,width*.12),true)
	for i in range(3):
		var p:=top+Vector2((i-1)*width*.32,width*.6)
		game.draw_polyline(PackedVector2Array([p,p+Vector2(width*.08,width*.35),p+Vector2(-width*.08,width*.6),p+Vector2(width*.04,width*.9)]),Color("eee5ca",alpha),maxf(.8,width*.12),true)
static func _shrine(game:Control,rect:Rect2,alpha:float)->void:
	var base:=rect.position+rect.size*Vector2(.54,.82);var w:=rect.size.x*.61;var h:=rect.size.y*.43
	for i in range(4):game.draw_rect(Rect2(base-Vector2(w*(.52+i*.025),-i*h*.06),Vector2(w*(1.04+i*.05),h*.06)),Color("70786a",alpha))
	game.draw_rect(Rect2(base-Vector2(w*.5,h),Vector2(w,h)),Color("9b7856",alpha))
	game.draw_rect(Rect2(base-Vector2(w*.18,h*.86),Vector2(w*.36,h*.85)),Color("394b42",alpha))
	for side in [-1,1]:
		game.draw_rect(Rect2(base+Vector2(side*w*.42-w*.035,-h*1.05),Vector2(w*.07,h*1.08)),Color("ac6550",alpha))
		for i in range(4):game.draw_line(base+Vector2(side*w*.3,-h*(.24+i*.16)),base+Vector2(side*w*.46,-h*(.24+i*.16)),Color("e0c392",alpha),maxf(1,w*.008),true)
	_polygon(game,[base+Vector2(-w*.72,-h*.88),base+Vector2(-w*.76,-h*1.06),base+Vector2(-w*.60,-h*.96),base+Vector2(-w*.28,-h*1.47),base+Vector2(w*.28,-h*1.47),base+Vector2(w*.60,-h*.96),base+Vector2(w*.76,-h*1.06),base+Vector2(w*.72,-h*.88)],Color("42584f",alpha))
	for i in range(9):
		var ridge:float=lerpf(-w*.25,w*.25,i/8.0)
		game.draw_line(base+Vector2(ridge,-h*1.45),base+Vector2(ridge*2.4,-h*.92),Color("7c9581",alpha*.5),maxf(.7,w*.009),true)
	game.draw_line(base+Vector2(-w*.73,-h*.87),base+Vector2(w*.73,-h*.87),Color("c8b99a",alpha),maxf(1.3,w*.018),true)
	for side in [-1,1]:game.draw_line(base+Vector2(side*w*.16,-h*1.39),base+Vector2(side*w*.34,-h*1.65),Color("cab990",alpha),maxf(1.2,w*.02),true)
	# A real sagging shimenawa with folded shide in front of the hall.
	var rope:=PackedVector2Array()
	for i in range(17):rope.append(base+Vector2(lerpf(-w*.43,w*.43,i/16.0),-h*.8+sin(PI*i/16.0)*h*.14))
	game.draw_polyline(rope,Color("d5be85",alpha),maxf(1,w*.02),true)
	for i in [4,8,12]:
		var p:Vector2=rope[i]
		game.draw_polyline(PackedVector2Array([p,p+Vector2(w*.025,h*.07),p+Vector2(-w*.02,h*.13),p+Vector2(w*.015,h*.2)]),Color("eee6ce",alpha),maxf(1,w*.015),true)
static func _landscape(game:Control,rect:Rect2,alpha:float=1.0)->void:
	ThemeLib.draw_gradient_rect_v(game,rect,Color("83b1ae",alpha),Color("ddd9b7",alpha))
	for layer in range(3):
		var points:Array=[Vector2(rect.position.x,rect.end.y)]
		for i in range(12):points.append(rect.position+rect.size*Vector2(i/11.0,.34+layer*.11+sin(i*1.8+layer)*(.1-layer*.018)))
		points.append(rect.end);_polygon(game,points,Color(["74908d","668278","5c7568"][layer],alpha*.9))
	for i in range(8):
		var x:float=rect.position.x+rect.size.x*fposmod(i*.163+game.ui_time*.0015,1)
		var y:float=rect.position.y+rect.size.y*(.29+i%3*.09)
		for j in range(4):game.draw_circle(Vector2(x+j*rect.size.x*.015,y),rect.size.x*(.022+j%2*.007),Color("e4e6d1",alpha*.24))
	_shrine(game,Rect2(rect.position+rect.size*Vector2(.3,.005),rect.size*Vector2(.5,.34)),alpha)
	# Four Onbashira stay beside the play area, not on plant cells.
	for entry in [[.08,.38,.095],[.92,.38,.095],[.065,.93,.15],[.95,.93,.15]]:
		_pillar(game,rect.position+rect.size*Vector2(entry[0],entry[1]),maxf(5,rect.size.x*.022),rect.size.y*entry[2],alpha)
static func draw_background(game:Control)->void:
	_landscape(game,Rect2(Vector2.ZERO,game.size))
	var side_width:float=maxf(25,game.size.x-game.BOARD_ORIGIN.x-game.board_size.x-8)
	_shrine(game,Rect2(Vector2(game.BOARD_ORIGIN.x+game.board_size.x+4,game.BOARD_ORIGIN.y+game.CELL_SIZE.y*.1),Vector2(side_width,game.board_size.y*.52)),1.0)
	game._draw_panel_shell(Rect2(game.BOARD_ORIGIN,game.board_size).grow(8),Color("536e5b"),Color("c8d5ae"),.1,.04)
	# Side gate and approaching stone stairs remain visible on narrow phones.
	var x:float=game.BOARD_ORIGIN.x*.44;var y:float=game.BOARD_ORIGIN.y+game.board_size.y*.28;var w:float=maxf(18,game.BOARD_ORIGIN.x*.45)
	for side in [-1,1]:game.draw_line(Vector2(x+side*w*.3,y),Vector2(x+side*w*.33,y+w*1.7),Color("a96147"),maxf(2,w*.1),true)
	game.draw_line(Vector2(x-w*.6,y),Vector2(x+w*.6,y),Color("b97150"),maxf(3,w*.15),true)
	game.draw_line(Vector2(x-w*.44,y+w*.26),Vector2(x+w*.44,y+w*.26),Color("b97150"),maxf(2,w*.1),true)
	game._draw_panel_shell(game.COIN_METER_RECT,Color("e1ddbc"),INK,.12,.06)
	game._draw_coin_icon(game.COIN_METER_RECT.position+Vector2(22,20),1.0)
	ThemeLib.draw_label(game,game.ui_font,Rect2(game.COIN_METER_RECT.position+Vector2(44,4),Vector2(game.COIN_METER_RECT.size.x-52,game.COIN_METER_RECT.size.y-8)),str(game.coins_total),22,INK)
	game._draw_fancy_button(game.BACK_BUTTON_RECT,"返回地图",Color("dddcb9"),INK,18)
static func draw_board(game:Control)->void:
	var unit:float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	for row in range(6):
		for col in range(game.COLS):
			var rect:Rect2=game._cell_rect(row,col)
			game.draw_rect(rect,STONE_A if (row+col)%2==0 else STONE_B)
			game.draw_rect(rect.grow(-maxf(.8,unit*.025)),Color("d9ddbf",.46),false,maxf(.8,unit*.015))
			game.draw_line(rect.position+Vector2(2,rect.size.y-2),rect.end-Vector2(2,2),Color(INK,.3),maxf(.8,unit*.025),true)
			if (row*3+col)%8==0:game.draw_polyline(PackedVector2Array([rect.position+rect.size*Vector2(.68,.04),rect.position+rect.size*Vector2(.6,.23),rect.position+rect.size*Vector2(.68,.33)]),Color(INK,.23),maxf(.7,unit*.015),true)
static func draw_preview(game:Control,rect:Rect2,alpha:float,show_label:bool)->void:
	_landscape(game,rect,alpha)
	var board:=Rect2(rect.position+rect.size*Vector2(.13,.38),rect.size*Vector2(.73,.52))
	for row in range(6):
		for col in range(9):game.draw_rect(Rect2(board.position+board.size*Vector2(col/9.0,row/6.0),board.size/Vector2(9,6)-Vector2(.4,.4)),Color(STONE_A if (row+col)%2 else STONE_B,alpha))
	if show_label:ThemeLib.draw_label(game,game.ui_font,Rect2(rect.position+Vector2(8,4),Vector2(rect.size.x-16,24)),"守矢神社 · 山顶六畦青石庭院",15,Color("f0eed5",alpha))
static func draw_ambient(game:Control)->void:
	for i in range(10):
		var p:=Vector2(fposmod(i*131.3-game.ui_time*19,game.size.x+20)-10,fposmod(i*79+game.ui_time*14,game.size.y+20)-10)
		game.draw_line(p,p+Vector2(4,9),Color("eadbbc",.23),1.2,true)
static func draw_boss(game:Control,center:Vector2,boss:Dictionary)->void:
	var portrait:bool=bool(boss.get("portrait",false))
	var unit_scale:float=1.0 if portrait else game._battle_unit_scale()
	var fit:=1.0
	if not portrait:
		var top:float=maxf(game.SEED_BANK_RECT.end.y,maxf(game.COIN_METER_RECT.end.y,game.BACK_BUTTON_RECT.end.y))+4
		var room:float=game._row_center_y(int(boss.row))-top
		fit=clampf(room/maxf(1,Sprites.BODY_HEIGHT*unit_scale),.36,1.0)
	var texture:Texture2D=game._try_get_boss_frame_texture("sanae_boss",game._ensure_sanae_runtime().frame_index(boss))
	if texture==null:return
	var scale:float=game._touhou_boss_draw_scale("sanae_boss")*fit
	var size:Vector2=texture.get_size()*scale
	game.draw_texture_rect(texture,Rect2(center+Vector2(-size.x*.5,Sprites.top_offset("sanae_boss")*fit),size),false,Color.WHITE)
	if float(boss.get("touhou_cast_remaining",0))>0:
		var turn:float=game.ui_time*.6
		for i in range(5):Danmaku.draw_star(game,center+Vector2(cos(turn+TAU*i/5)*36,sin(turn+TAU*i/5)*15-30)*fit,3.0*fit,Color("bedf9a",.45),turn)
