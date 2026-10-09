extends RefCounted
const WindGodFX = preload("res://scripts/runtime/wind_god_fx.gd")

const SpriteDefs = preload("res://scripts/data/touhou_sprite_defs.gd")
const TenguDanmaku = preload("res://scripts/runtime/tengu_danmaku.gd")
const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const SKY := Color("aac5d1")
const WATER := Color("598c9e")
const FOAM := Color("d1e8e5")
const STONE_A := Color("aaa78e")
const STONE_B := Color("969b85")
const INK := Color("344942")
const MAPLE := Color("bb6751")

static func _poly(game: CanvasItem,rect: Rect2,vertices: Array,tint: Color) -> void:
	if tint.a <= .001 or rect.size.x <= 1 or rect.size.y <= 1: return
	var points := PackedVector2Array()
	for v in vertices: points.append(rect.position+rect.size*Vector2(v))
	game.draw_colored_polygon(points,tint)

static func _landscape(game: Control,rect: Rect2,mix: float,alpha: float) -> void:
	if rect.size.x <= 1 or rect.size.y <= 1: return
	var sky := SKY.lerp(Color("c7c6ab"),mix)
	game.draw_rect(rect,Color(sky,alpha))
	# Narrow painted bands give the sky depth without covering the battle in fog.
	for i in range(7):
		var band := Rect2(rect.position+Vector2(0,rect.size.y*i*.055),Vector2(rect.size.x,rect.size.y*.056))
		game.draw_rect(band,Color(sky.lerp(Color("e2d9b7"),float(i)/12.0),alpha))
	_poly(game,rect,[Vector2(0,.53),Vector2(.10,.27),Vector2(.22,.39),Vector2(.39,.15),Vector2(.54,.32),Vector2(.71,.19),Vector2(.87,.36),Vector2(1,.22),Vector2(1,.72),Vector2(0,.72)],Color(Color("809ba0").lerp(Color("94a58f"),mix),alpha))
	_poly(game,rect,[Vector2(0,.64),Vector2(.06,.42),Vector2(.20,.52),Vector2(.36,.32),Vector2(.51,.50),Vector2(.65,.29),Vector2(.82,.47),Vector2(.94,.33),Vector2(1,.47),Vector2(1,1),Vector2(0,1)],Color(Color("557b76").lerp(Color("607d5c"),mix),alpha))
	_poly(game,rect,[Vector2(0,.50),Vector2(.12,.37),Vector2(.24,.46),Vector2(.28,.71),Vector2(.14,.87),Vector2(.09,1),Vector2(0,1)],Color("485f50",alpha))
	_poly(game,rect,[Vector2(.77,.30),Vector2(.85,.22),Vector2(1,.32),Vector2(1,1),Vector2(.91,1),Vector2(.83,.77),Vector2(.76,.63)],Color(Color("536b60").lerp(Color("656b52"),mix),alpha))
	for i in range(8):
		var x: float=rect.position.x+rect.size.x*(.80+i*.021)
		var y: float=rect.position.y+rect.size.y*(.32+float(i%3)*.035)
		game.draw_line(Vector2(x,y),Vector2(x-rect.size.x*.028,y+rect.size.y*.41),Color(INK,alpha*.22),maxf(1,rect.size.x*.0014),true)
	var road_alpha := alpha*(1.0-mix)
	var fall := Rect2(rect.position+rect.size*Vector2(.786,.25),rect.size*Vector2(.088,.55))
	if road_alpha > .002:
		game.draw_rect(fall,Color("bad7d6",road_alpha))
		for i in range(12):
			var x: float=fall.position.x+fall.size.x*(i+.5)/12.0
			game.draw_line(Vector2(x,fall.position.y),Vector2(x+sin(i*1.7)*fall.size.x*.035,fall.end.y),Color(FOAM,road_alpha*(.35+i%3*.12)),maxf(1.0,fall.size.x*.035),true)
			var y: float=fall.position.y+fposmod(game.ui_time*(.20+i%3*.025)+i*.083,1.0)*fall.size.y
			game.draw_line(Vector2(x,y),Vector2(x, minf(fall.end.y,y+fall.size.y*.15)),Color(WHITE_COLOR(),road_alpha*.52),maxf(1,fall.size.x*.024),true)
		for i in range(9):
			var point := Vector2(fall.get_center().x+(i-4)*fall.size.x*.12,fall.end.y+sin(i*1.8+game.ui_time)*fall.size.y*.009)
			game.draw_arc(point,fall.size.x*(.20+i%3*.04),PI*.1,PI*.9,18,Color(FOAM,road_alpha*.38),maxf(1,fall.size.x*.015),true)
	# A dry mountain path climbs to a small tengu gate after the river retreats.
	if mix > .001:
		_poly(game,rect,[Vector2(.71,.68),Vector2(.75,.49),Vector2(.83,.40),Vector2(.89,.41),Vector2(.78,.56),Vector2(.76,.72)],Color("9a977f",alpha*mix))
		var gate := rect.position+rect.size*Vector2(.88,.36)
		var gw: float=rect.size.x*.065; var gh: float=rect.size.y*.13
		var stroke: float=maxf(1.5,rect.size.x*.004)
		for direction in [-1,1]: game.draw_line(gate+Vector2(direction*gw*.38,0),gate+Vector2(direction*gw*.42,gh),Color("714f3e",alpha*mix),stroke,true)
		game.draw_line(gate+Vector2(-gw*.65,-gh*.09),gate+Vector2(gw*.65,-gh*.09),Color("9d4d3f",alpha*mix),stroke*1.4,true)
		game.draw_line(gate+Vector2(-gw*.56,gh*.20),gate+Vector2(gw*.56,gh*.20),Color("a46043",alpha*mix),stroke,true)
		for i in range(3):
			var x: float=gate.x+gw*(i-1)*.22
			game.draw_line(Vector2(x,gate.y+gh*.22),Vector2(x-gw*.04,gate.y+gh*.42),Color("e4debe",alpha*mix),maxf(1,stroke*.4),true)
	# Sparse maple crowns frame the cliffs rather than obscuring the planting area.
	for side in [0,1]:
		var base := rect.position+rect.size*Vector2(.035 if side==0 else .967,.74)
		var width: float=rect.size.x*.035
		game.draw_line(base,base-Vector2(width*.2,rect.size.y*.25),Color("465245",alpha),maxf(2,width*.15),true)
		for i in range(5):
			var point := base+Vector2((i%3-1)*width*.75,-rect.size.y*(.18+i%2*.06))
			game.draw_circle(point,width*(.45+i%2*.10),Color(Color("56774f").lerp(MAPLE,mix*.6),alpha*.92))

static func WHITE_COLOR() -> Color:
	return Color("eff2dc")

static func _side_cascade(game: Control,mix: float) -> void:
	# The broad backdrop fall is behind the board. This second, visible cascade
	# uses only the unused right margin, so all six planting lanes stay readable.
	var left: float=game.BOARD_ORIGIN.x+game.board_size.x+10.0
	var width: float=game.size.x-8.0-left
	var top: float=maxf(80.0,game.BOARD_ORIGIN.y-12.0)
	var bottom: float=minf(game.size.y-8.0,game.BOARD_ORIGIN.y+game.board_size.y+22.0)
	if width<8.0 or bottom-top<20.0: return
	var area := Rect2(left,top,width,bottom-top)
	_poly(game,area,[Vector2(0,.03),Vector2(.24,0),Vector2(.53,.035),Vector2(.79,.015),Vector2(1,.055),Vector2(1,1),Vector2(0,1)],Color("52685b").lerp(Color("676b50"),mix))
	for i in range(6):
		var x: float=area.position.x+area.size.x*(.08+i*.16)
		var y: float=area.position.y+area.size.y*(.05+i%3*.015)
		game.draw_line(Vector2(x,y),Vector2(x+area.size.x*.06,y+area.size.y*.91),Color(INK,.25),maxf(1,area.size.x*.01),true)
	var road_alpha := 1.0-mix
	if road_alpha>.001:
		var fall := Rect2(area.position+area.size*Vector2(.14,.025),area.size*Vector2(.66,.91))
		game.draw_rect(fall,Color("9ec9cf",road_alpha))
		game.draw_rect(Rect2(fall.position+Vector2(fall.size.x*.14,0),Vector2(fall.size.x*.67,fall.size.y)),Color("d4e7df",road_alpha*.82))
		for i in range(10):
			var x: float=fall.position.x+fall.size.x*(i+.5)/10.0
			var bend := sin(i*1.6)*fall.size.x*.014
			game.draw_line(Vector2(x,fall.position.y),Vector2(x+bend,fall.end.y),Color(FOAM,road_alpha*(.40+i%3*.10)),maxf(.8,fall.size.x*.045),true)
			var y: float=fall.position.y+fposmod(game.ui_time*(.25+i%4*.017)+i*.11,1.0)*fall.size.y
			game.draw_line(Vector2(x,y),Vector2(x+bend,minf(fall.end.y,y+fall.size.y*.19)),Color("f5f4de",road_alpha*.65),maxf(.8,fall.size.x*.026),true)
		var pool := Rect2(area.position+area.size*Vector2(.05,.93),area.size*Vector2(.89,.06))
		game.draw_rect(pool,Color("77a6ae",road_alpha))
		for i in range(7):
			var x: float=pool.position.x+pool.size.x*(.12+i*.12)
			var y: float=pool.position.y+pool.size.y*.2+sin(game.ui_time*2.4+i)*pool.size.y*.08
			game.draw_arc(Vector2(x,y),maxf(1.2,area.size.x*(.06+i%2*.018)),PI*.06,PI*.94,14,Color(FOAM,road_alpha*.66),maxf(.8,area.size.x*.007),true)
	if mix>.001:
		_poly(game,area,[Vector2(.05,1),Vector2(.05,.79),Vector2(.43,.66),Vector2(.69,.39),Vector2(.91,.31),Vector2(1,.33),Vector2(.83,.53),Vector2(.56,.77),Vector2(.20,1)],Color("b0a482",mix))
		for i in range(6):
			var y: float=area.position.y+area.size.y*(.80-i*.055)
			var x: float=area.position.x+area.size.x*(.22+i*.072)
			game.draw_line(Vector2(x,y),Vector2(x+area.size.x*.24,y-area.size.y*.025),Color("646f56",mix*.65),maxf(1,area.size.x*.014),true)
		# A compact red gate and maple crown replace the blue, falling-water strip.
		var gate := area.position+area.size*Vector2(.53,.23)
		var gw: float=area.size.x*.65; var gh: float=area.size.y*.15
		var stroke: float=maxf(1.5,area.size.x*.04)
		for side in [-1,1]: game.draw_line(gate+Vector2(side*gw*.35,0),gate+Vector2(side*gw*.39,gh),Color("78503c",mix),stroke,true)
		game.draw_line(gate+Vector2(-gw*.56,-gh*.05),gate+Vector2(gw*.56,-gh*.05),Color("a55743",mix),stroke*1.4,true)
		game.draw_line(gate+Vector2(-gw*.48,gh*.20),gate+Vector2(gw*.48,gh*.20),Color("b0784e",mix),stroke,true)
		var tree := area.position+area.size*Vector2(.79,.69)
		var trunk := tree-Vector2(area.size.x*.08,area.size.y*.25)
		game.draw_line(tree,trunk,Color("594b39",mix),maxf(1.2,area.size.x*.035),true)
		for i in range(7):
			var tip := trunk+Vector2((i%3-1)*area.size.x*.18,-area.size.y*(.04+i%2*.055))
			game.draw_line(trunk,tip,Color("67513a",mix),maxf(.8,area.size.x*.012),true)
			game.draw_circle(tip,maxf(2,area.size.x*(.11+i%2*.025)),Color(Color("be6447").lerp(Color("d39457"),i%3*.24),mix))

static func draw_preview(game: Control,rect: Rect2,alpha: float,show_label: bool) -> void:
	_landscape(game,rect,0.0,alpha)
	if rect.size.x <= 1 or rect.size.y <= 1: return
	var board := Rect2(rect.position+rect.size*Vector2(.12,.37),rect.size*Vector2(.71,.54))
	var cell_size := board.size/Vector2(9,6)
	for row in range(6):
		for col in range(9):
			var cell := Rect2(board.position+Vector2(col,row)*cell_size,cell_size)
			game.draw_rect(cell,Color(WATER if (row+col)%2 else Color("6597a5"),alpha))
			game.draw_rect(cell.grow(-.4),Color(FOAM,alpha*.35),false,.8)
			if col in [1,2]: game.draw_arc(cell.get_center(),minf(cell_size.x,cell_size.y)*.24,.2,TAU-.2,14,Color("a8bd74",alpha),maxf(1,cell_size.y*.11),true)
	if show_label: ThemeLib.draw_label(game,game.ui_font,Rect2(rect.position+Vector2(8,4),Vector2(rect.size.x-16,24)),"妖怪之山 · 六行瀑布河道",15,Color("eff0d9",alpha))

static func draw_background(game: Control) -> void:
	var rt: RefCounted=game.call("_ensure_tengu_runtime")
	var mix: float=rt.transition_progress()
	_landscape(game,Rect2(Vector2.ZERO,game.size),mix,1.0)
	_side_cascade(game,mix)
	var perimeter: Rect2=Rect2(game.BOARD_ORIGIN,game.board_size).grow(8.0)
	game._draw_panel_shell(perimeter,Color("506d68").lerp(Color("636b54"),mix),Color("b3d6cb").lerp(Color("c2bb98"),mix),.1,.04)
	game._draw_panel_shell(game.COIN_METER_RECT,Color("dfddbd"),Color("465945"),.12,.06)
	game._draw_coin_icon(game.COIN_METER_RECT.position+Vector2(22,20),1.0)
	ThemeLib.draw_label(game,game.ui_font,Rect2(game.COIN_METER_RECT.position+Vector2(44,4),Vector2(game.COIN_METER_RECT.size.x-52,game.COIN_METER_RECT.size.y-8)),str(game.coins_total),22,Color("3c4e3e"))
	game._draw_fancy_button(game.BACK_BUTTON_RECT,"返回地图",Color("dddcb9"),Color("475b47"),18)

static func draw_board(game: Control) -> void:
	var rt: RefCounted=game.call("_ensure_tengu_runtime")
	var mix: float=rt.transition_progress()
	var unit: float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	for row in range(game.board_rows):
		for col in range(game.COLS):
			var rect: Rect2=game._cell_rect(row,col)
			var water := WATER if (row+col)%2==0 else Color("6895a2")
			var stone := STONE_A if (row+col)%2==0 else STONE_B
			game.draw_rect(rect,water.lerp(stone,mix))
			game.draw_rect(rect.grow(-maxf(.8,unit*.025)),Color(FOAM.lerp(Color("d9d4ad"),mix),.38),false,maxf(.8,unit*.015))
			if mix < .99:
				for i in range(2):
					var phase := fposmod(game.ui_time*.22+col*.17+row*.21+i*.43,1.0)
					var point := rect.position+rect.size*Vector2(phase,.30+i*.38)
					game.draw_arc(point,unit*(.08+i*.025),.15,PI*.85,12,Color(FOAM,(1.0-mix)*.28),maxf(.8,unit*.016),true)
			if mix > .01:
				var seam_y: float=rect.end.y-unit*.055
				game.draw_line(Vector2(rect.position.x+2,seam_y),Vector2(rect.end.x-2,seam_y),Color(INK,mix*.30),maxf(.8,unit*.022),true)
				if posmod(row*5+col*3,7)==0:
					var crack := PackedVector2Array([rect.position+rect.size*Vector2(.74,.04),rect.position+rect.size*Vector2(.62,.25),rect.position+rect.size*Vector2(.68,.37)])
					game.draw_polyline(crack,Color(INK,mix*.18),maxf(.8,unit*.013),true)
				if (row+col)%5==0: TenguDanmaku.draw_leaf(game,rect.position+rect.size*Vector2(.24,.78),maxf(1.4,unit*.042),row*.8+col,Color(MAPLE,mix*.32))
	rt.draw_ground()

static func draw_ambient(game: Control) -> void:
	var rt: RefCounted=game.call("_ensure_tengu_runtime")
	var mix: float=rt.transition_progress()
	var unit: float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	for i in range(14):
		var x: float=fposmod(i*137.1-game.ui_time*(22+i%4*6),maxf(1,game.size.x+40))-20
		var y: float=fposmod(i*79.2+game.ui_time*(13+i%3*4)+sin(i+game.ui_time)*16,maxf(1,game.size.y+40))-20
		TenguDanmaku.draw_leaf(game,Vector2(x,y),maxf(2.0,unit*(.045+i%3*.01)),game.ui_time*.7+i,Color(MAPLE.lerp(Color("8ba786"),1.0-mix),.30))
	if mix < .99:
		for i in range(8):
			var row := posmod(i*5, maxi(1,game.board_rows)); var col := posmod(i*4,game.COLS)
			var point: Vector2=game._cell_center(row,col)+Vector2(sin(i)*unit*.17,unit*.19)
			var cycle := fposmod(game.ui_time*.65+i*.29,1.0)
			game.draw_arc(point,unit*(.03+cycle*.15),0,TAU,16,Color(FOAM,(1.0-mix)*.3*(1-cycle)),maxf(.8,unit*.014),true)
	rt.draw_overlay()

static func _hud_floor(game: Control) -> float:
	return maxf(game.SEED_BANK_RECT.end.y,maxf(game.COIN_METER_RECT.end.y,maxf(game.PAUSE_BUTTON_RECT.end.y,game.BACK_BUTTON_RECT.end.y)))+2.0

static func _body_fit(game: Control,world_point: Vector2,kind: String) -> float:
	# Keep the live collision anchor unchanged. Near the upper board edge the
	# supplied foot-anchored pose needs less height to stay below the battle HUD.
	# Include the gap above the board so the character stays legible on phones.
	var above_anchor := maxf(1.0,-SpriteDefs.top_offset(kind)*game._battle_unit_scale())
	return clampf((world_point.y-_hud_floor(game))/above_anchor,.05,1.0)

static func _sprite(game: Control,point: Vector2,texture: Texture2D,kind: String,alpha: float,body_fit: float=1.0) -> void:
	if texture == null or alpha <= .001: return
	var scale: float=game._touhou_boss_draw_scale(kind)*body_fit
	var size: Vector2=texture.get_size()*scale
	game.draw_texture_rect(texture,Rect2(point+Vector2(-size.x*.5,SpriteDefs.top_offset(kind)*body_fit),size),false,Color(1,1,1,alpha))

static func draw_boss(game: Control,center: Vector2,boss: Dictionary) -> void:
	var rt: RefCounted=game.call("_ensure_tengu_runtime")
	var portrait := bool(boss.get("portrait",false))
	# Game already places the combat transform at the live body. Sprite drawing
	# is local to that transform; applying the world anchor again moves it twice.
	var point := center
	var kind := String(boss.kind)
	var combat_scale: float=1.0 if portrait else game._battle_unit_scale()
	var body_fit := 1.0 if portrait else _body_fit(game,rt.body_point(boss),kind)
	var unit: float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)/maxf(.01,combat_scale)*body_fit
	if kind=="aya_boss" and not portrait:
		for trail in rt.afterimages:
			if int(trail.owner)!=int(boss.get("uid",-1)): continue
			var anchor: Vector2=center+(rt._world(Vector2(trail.uv))-rt.body_point(boss))/maxf(.01,combat_scale)
			var fade := (1.0-clampf(float(trail.age)/.32,0,1))*.19
			var image: Texture2D=game._try_get_boss_frame_texture(kind,int(trail.frame))
			_sprite(game,anchor,image,kind,fade,_body_fit(game,rt._world(Vector2(trail.uv)),kind))
	var concealed: bool=not portrait and rt.is_hidden(boss)
	var alpha := .40 if concealed else 1.0
	if not concealed: WindGodFX.draw_boss_aura(game,point,boss,true)
	var texture: Texture2D=game._try_get_boss_frame_texture(kind,rt.frame_index(boss))
	_sprite(game,point,texture,kind,alpha*(1.0-float(boss.get("flash",0.0))*.25),body_fit)
	var anchor := point+Vector2(0,-30*body_fit)
	if not concealed: WindGodFX.draw_boss_aura(game,point,boss,false)
	if kind=="momiji_boss" and float(boss.get("tengu_shield_age",-1.0))>=0.0:
		var age := float(boss.tengu_shield_age)
		if age<4.2:
			var active := age>=1.2
			game.draw_arc(anchor,unit*.52,PI*.55,PI*1.45,28,Color("efe8cd",.72 if active else .26),maxf(1.2,unit*.045),true)
			for i in range(3): TenguDanmaku.draw_leaf(game,anchor+Vector2(-unit*.5,unit*(i-1)*.28),maxf(2,unit*.08),game.ui_time+i,Color(MAPLE,.65))
	if kind=="aya_boss" and (concealed or String(boss.get("tengu_pose","")) in ["wind","veil","cyclone","survival"]):
		for i in range(5):
			var angle: float=game.ui_time*2.1+TAU*i/5.0
			var p := anchor+Vector2(cos(angle)*unit*.52,sin(angle)*unit*.35)
			TenguDanmaku.draw_leaf(game,p,maxf(2,unit*.06),angle,Color(MAPLE,.65 if concealed else .35))
