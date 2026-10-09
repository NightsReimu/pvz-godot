extends RefCounted
const WindGodFX = preload("res://scripts/runtime/wind_god_fx.gd")

const WHITE := Color("eae9d9")
const RED := Color("d85950")
const WIND := Color("b0d4c4")
const GOLD := Color("f2cf86")
const INK := Color("59636b")

static func _origin(dm: RefCounted, c: Dictionary) -> Vector2:
	var rt = dm.game.get("tengu_runtime")
	if rt != null:
		for boss in dm.game.zombies:
			if int(boss.get("uid",-1)) == int(c.get("boss_uid",-2)):
				c.center = rt.body_point(boss)
				break
	return Vector2(c.center)

static func _extra(scale: float, damage: float, turn: float = 0.0) -> Dictionary:
	return {"arming_time":1.15,"radius":maxf(2.0,4.2*scale),"damage":damage,"angular_speed":turn,"life":8.5}

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	if game.active_rows.is_empty(): return
	# The existing normalized-axis mover preserves horizontal board crossing on
	# six very short rows. This flag is local to these new sessions only.
	c.autumn_full = true; c.autumn_density = 1.0
	var rank := clampi(int(game.TouhouDifficulty.profile(game.current_level).rank),0,3)
	var wave := int(c.wave); var turn := wave*.37
	var origin := _origin(dm,c)
	var scale: float = minf(1.0,minf(game.CELL_SIZE.x/100.0,game.CELL_SIZE.y/110.0))
	var aim: float = (Vector2(dm._target(origin))-origin).angle()
	var cadence := 1.45
	match String(c.pattern):
		"nonspell_momiji_patrol":
			dm._fan(c,origin,5,aim,.62,142*scale,RED,"tengu_blade",_extra(scale,8.0))
			dm._fan(c,origin,5,PI+sin(turn)*.13,.92,110*scale,WHITE,"tengu_blade",_extra(scale,8.0))
			cadence=1.85
		"nonspell_momiji_cross":
			for direction in [-1,1]:
				dm._fan(c,origin+Vector2(0,direction*game.CELL_SIZE.y*.20),5,PI+direction*.28,.48,148*scale,RED if direction<0 else WHITE,"tengu_blade",_extra(scale,9.0,-direction*.08))
			cadence=1.7
		"momiji_sentinel":
			dm._fan(c,origin,7,aim,.8,146*scale,RED,"tengu_blade",_extra(scale,10.0))
			_lanes(dm,c,origin,scale,2,3,WHITE,"tengu_blade",9.0,115)
			cadence=1.7
		"momiji_maple_guard":
			for direction in [-1,1]: dm._fan(c,origin,6,PI+direction*.25,1.1,123*scale,RED if direction<0 else WHITE,"tengu_leaf",_extra(scale,10.0,direction*.14))
			if wave%2==0:
				var row := int(game.active_rows[posmod(wave+int(c.stage),game.active_rows.size())])
				var y: float=game._row_center_y(row)
				dm._beam(c,Vector2(origin.x,y),Vector2(game.BOARD_ORIGIN.x,y),WHITE,1.3,maxf(2,game.CELL_SIZE.y*.055),{"damage":12.0,"duration":.22})
			cadence=1.75
		"nonspell_aya_wind":
			# Three different openings, as in TH10: a feather ring, then a fast
			# clockwise and a slow counter-clockwise "pon de ring", then larger
			# rings at a shorter interval.
			var opening: int=mini(2,int(c.stage))
			if opening==0:
				dm._ring(c,origin,12,turn,128*scale,WIND,"tengu_feather",_extra(scale,12.0))
				dm._fan(c,origin,5,aim,.5,172*scale,WHITE,"tengu_feather",_extra(scale,12.0))
				_lanes(dm,c,origin,scale,3,3,WHITE,"tengu_feather",12.0,144)
				cadence=1.35
			else:
				var clusters: int=5 if opening==1 else 7
				_ponde(dm,c,origin,scale,clusters,turn,150*scale,.26,RED,3.2 if opening==1 else 4.2)
				_ponde(dm,c,origin,scale,clusters,-turn+.3,96*scale,-.2,Color("6fa8e8"),3.2 if opening==1 else 4.6)
				cadence=1.45 if opening==1 else 1.25
		"aya_crossroads","aya_saruta_cross":
			# 天之八衢 / 猿田彦: a lattice of crossing roads is laid out and held,
			# then its bullets drop away one by one at hashed moments.
			var saruta := String(c.pattern)=="aya_saruta_cross"
			_crossroads(dm,c,scale,saruta)
			dm._fan(c,origin,5,aim,.5,168*scale,RED,"tengu_feather",_extra(scale,15.0 if saruta else 14.0))
			_lanes(dm,c,origin,scale,2,3,WIND,"tengu_leaf",13.0,125)
			cadence=1.2 if not saruta else 1.45
		"aya_leaf_veiling":
			# Two half-fixed leaf rings turning against each other: about 20-way
			# on Easy and 28-way above, after the Wind God density.
			_veil(dm,c,origin,scale,12 if rank==0 else 14,wave,0.0,13.0)
			_lanes(dm,c,origin,scale,5,3,WHITE,"tengu_feather",13.0,150)
			cadence=1.15
		"aya_tengu_fall":
			# Hard scatters the same rings badly, and a downhill gust enters
			# from the mountain crest.
			_veil(dm,c,origin,scale,14,wave,.35,15.0,1.0,.62)
			_lanes(dm,c,origin,scale,3,3,RED,"tengu_leaf",14.0,150)
			for i in range(3):
				var edge: Vector2=dm._point(.40+fposmod(wave*.047+i*.17,.56),0)
				dm._fan(c,edge,3,PI*.76,.3,136*scale,WIND if i%2 else WHITE,"tengu_feather",_extra(scale,15.0,-.07))
			cadence=1.2
		"aya_storm_day":
			# The 210th day: faster crossing rings, scattered, every 1.3s.
			_veil(dm,c,origin,scale,16,wave,.25,16.0,1.25,.62)
			_lanes(dm,c,origin,scale,4,3,RED,"tengu_leaf",15.0,160)
			cadence=1.05
		"aya_fantasy_storm", "aya_peerless_wind":
			# Native timed survival owns invulnerability; these are real moving-body
			# wind trails, not teleported hitboxes or a last-card shortcut.
			var peerless := String(c.pattern)=="aya_peerless_wind"
			dm._fan(c,origin,15 if peerless else 11,aim,1.35,195*scale,WHITE,"tengu_feather",_extra(scale,17.0 if peerless else 15.0))
			_lanes(dm,c,origin,scale,4,5 if peerless else 4,WIND,"tengu_leaf",15.0,156)
			if wave%2==0: dm._ring(c,origin,8,turn,108*scale,RED,"tengu_leaf",_extra(scale,13.0,.16))
			cadence=1.16 if peerless else 1.25
		"aya_procession", "aya_divine_advent", "aya_terukuni":
			# Fixed rows of scales plus a ring of rice at a hashed angle.
			var tier: int=["aya_procession","aya_divine_advent","aya_terukuni"].find(String(c.pattern))
			var rows: int=4+tier
			for i in range(rows):
				var angle: float=PI+(i-(rows-1)*.5)*.3
				for k in range(maxi(3,ceili((3 if tier==0 else 4)*dm._attack_density_for_cast(c)))):
					dm._bullet(c,origin,angle,(112+k*16)*scale,WHITE if i%2 else WIND,"tengu_scale",_extra(scale,15.0+tier))
			dm._ring(c,origin,9+tier*2,WindGodFX.noise(wave,11)*TAU,(98+tier*10)*scale,RED,"tengu_rice",_extra(scale,15.0))
			if String(c.pattern)=="aya_terukuni": dm._ring(c,origin,10,turn,117*scale,GOLD,"tengu_leaf",_extra(scale,16.0,-.13))
			cadence=1.5 if tier==0 else 1.3
		"aya_headwind":
			_lanes(dm,c,origin,scale,4,5,WIND,"tengu_leaf",13.0,126)
			dm._fan(c,origin,7,aim,.8,165*scale,WHITE,"tengu_feather",_extra(scale,14.0))
			cadence=1.45
		"aya_report", "aya_extra_edition":
			# Newspaper sheets keep four corners and a red masthead; the separate
			# marked photographs carry the original lane-defense adaptation.
			dm._fan(c,origin,9,aim,.72,155*scale,WHITE,"tengu_paper",_extra(scale,14.0))
			_lanes(dm,c,origin,scale,4,4,INK,"tengu_feather",14.0,140)
			cadence=1.5 if String(c.pattern)=="aya_report" else 1.35
		"aya_cyclone":
			for side in [-1,1]: dm._fan(c,origin+Vector2(0,side*game.CELL_SIZE.y*.35),11,PI+side*.12,1.35,137*scale,WIND,"tengu_leaf",_extra(scale,14.0,side*.25))
			_lanes(dm,c,origin,scale,2,3,WHITE,"tengu_feather",14.0,174)
			cadence=1.4
		"aya_wind_fence":
			_wall(dm,c,origin,scale,posmod(wave*2+1,game.active_rows.size()),4,128)
			dm._fan(c,origin,7,aim,.45,166*scale,GOLD,"tengu_blade",_extra(scale,15.0))
			cadence=1.45
		"aya_relay":
			_lanes(dm,c,origin,scale,game.active_rows.size(),4,WHITE,"tengu_feather",15.0,167)
			dm._fan(c,origin,9,aim,1.1,180*scale,RED,"tengu_leaf",_extra(scale,15.0,-.12))
			cadence=1.3
	c.next_wave=float(c.age)+maxf(.82,cadence*game.TouhouDifficulty.attack_cadence(String(c.kind),game.current_level))

static func _ponde(dm: RefCounted,c: Dictionary,origin: Vector2,scale: float,clusters: int,base: float,speed: float,turn: float,tint: Color,cluster_radius: float) -> void:
	# A "pon de ring": a ring of small rings that keep their shape in flight.
	clusters=maxi(3,ceili(clusters*dm._attack_density_for_cast(c)*.6))
	for i in range(clusters):
		var a: float=base+TAU*i/clusters
		for k in range(4):
			var offset := Vector2.from_angle(TAU*k/4.0)*cluster_radius*scale
			dm._bullet(c,origin+offset,a,speed,tint,"tengu_orb",_extra(scale,12.0,turn))

static func _veil(dm: RefCounted,c: Dictionary,origin: Vector2,scale: float,base_count: int,wave: int,scatter: float,damage: float,pace: float=1.0,arc: float=1.0) -> void:
	# arc<1 keeps the Hard/Lunatic gusts inside a leftward sector, so their
	# denser rings spend the shared bullet budget over the lawn.
	var count: int=ceili(base_count*dm._attack_density_for_cast(c))
	var start: float=WindGodFX.noise(wave,1)*TAU if arc>=1.0 else PI-arc*PI+WindGodFX.noise(wave,1)*.3
	for layer in range(2):
		for i in range(count):
			var jitter: float=(WindGodFX.noise(wave*31+i,layer)-.5)*scatter
			var extra := _extra(scale,damage,(.22 if layer==0 else -.22)*pace)
			dm._bullet(c,origin,start+TAU*arc*i/count+layer*PI*arc/count+jitter,(104+layer*22)*scale*pace*(1.0+jitter*.6),Color("df5a48") if layer else WIND,"tengu_leaf",extra)

static func _crossroads(dm: RefCounted,c: Dictionary,scale: float,saruta: bool) -> void:
	var game: Control=dm.game
	var board := Rect2(game.BOARD_ORIGIN,game.board_size)
	var wave: int=int(c.wave)
	var centers: Array=[Vector2(board.position.x+board.size.x*(.55+.12*WindGodFX.noise(wave,2)),board.position.y+board.size.y*(.3+.4*WindGodFX.noise(wave,3)))]
	if saruta: centers.append(Vector2(board.position.x+board.size.x*(.35+.1*WindGodFX.noise(wave,4)),board.position.y+board.size.y*(.25+.5*WindGodFX.noise(wave,5))))
	var roads: Array=c.get("aya_roads",[])
	roads=roads.filter(func(road): return float(road.until)>float(c.age))
	var step: float=maxf(10.0,game.CELL_SIZE.x*.36)
	var density: float=dm._attack_density_for_cast(c)
	for ci in range(centers.size()):
		var hub: Vector2=centers[ci]
		var angles: Array=[0.0,.62,-.62] if ci==0 else [PI*.5,.95,-.95]
		for angle in angles:
			var axis := Vector2.from_angle(float(angle))
			var half: int=ceili((2.0+density)*(1.4 if saruta else 1.0))
			roads.append({"from":hub-axis*step*half,"to":hub+axis*step*half,"until":float(c.age)+2.2})
			for k in range(-half,half+1):
				var p: Vector2=hub+axis*step*k
				if not board.grow(-4).has_point(p): continue
				var drop: float=1.0+WindGodFX.noise(wave*13+k,ci*7+int(float(angle)*10))*2.0
				var extra := _extra(scale,15.0 if saruta else 14.0)
				extra.merge({"freeze_at":0.0,"thaw_at":drop,"thaw_angle":0.0,"arming_time":drop,"gravity":game.CELL_SIZE.y*.6,"life":drop+6.0},true)
				dm._bullet(c,p,PI*.62+(WindGodFX.noise(k,wave)-.5)*.4,(56+40*WindGodFX.noise(wave,k+40))*scale,WHITE if k%2 else RED,"tengu_feather",extra)
	c["aya_roads"]=roads

static func _lanes(dm: RefCounted,c: Dictionary,origin: Vector2,scale: float,count: int,shots: int,tint: Color,shape: String,damage: float,speed: float) -> void:
	var game: Control=dm.game
	for i in range(mini(count,game.active_rows.size())):
		var row := int(game.active_rows[posmod(int(c.wave)+int(c.stage)+i*2+i/3,game.active_rows.size())])
		var start := Vector2(origin.x,game._row_center_y(row))
		dm._fan(c,start,shots,PI,.30,speed*scale,tint,shape,_extra(scale,damage))

static func _wall(dm: RefCounted,c: Dictionary,origin: Vector2,scale: float,gap: int,count: int,speed: float) -> void:
	var game: Control=dm.game
	count=maxi(2,ceili(count*dm._attack_density_for_cast(c)))
	for i in range(game.active_rows.size()):
		if i==gap: continue
		var row := int(game.active_rows[i])
		for j in range(count):
			var y: float=game._row_center_y(row)+(float(j)/(count-1)-.5)*game.CELL_SIZE.y*.56
			dm._bullet(c,Vector2(origin.x,y),PI,speed*scale,WHITE if j%2 else WIND,"tengu_feather",_extra(scale,15.0,.035*(-1 if i%2 else 1)))

static func draw_leaf(game: CanvasItem,center: Vector2,radius: float,angle: float,tint: Color) -> void:
	var axis := Vector2.from_angle(angle); var side := axis.orthogonal()
	var points := PackedVector2Array([center+axis*radius*1.35,center+axis*radius*.2+side*radius*.9,center-axis*radius*.4+side*radius*.52,center-axis*radius*1.2,center-axis*radius*.4-side*radius*.52,center+axis*radius*.2-side*radius*.9])
	game.draw_colored_polygon(points,tint)
	game.draw_line(center-axis*radius,center+axis*radius,Color(WHITE,tint.a*.65),maxf(.8,radius*.16),true)

static func draw_bullet(game: Control,b: Dictionary) -> void:
	# Drawn larger than the collision radius so shapes read on the lawn.
	var center := Vector2(b.position); var radius := float(b.radius)*1.4
	var tint := Color(b.color)
	if float(b.age)<float(b.get("arming_time",0)): tint.a*=.40
	var heading := Vector2(b.velocity).angle(); var axis := Vector2.from_angle(heading); var side := axis.orthogonal()
	if WindGodFX.crowded(game):
		game.draw_circle(center,radius*1.1,Color(WindGodFX.INK,tint.a*.6))
		game.draw_circle(center,radius*.85,tint)
		return
	if bool(b.get("frozen",false)): game.draw_arc(center,radius*1.9,0,TAU,12,Color(WHITE,tint.a*.5),1.0,true)
	match String(b.shape):
		"tengu_leaf":
			draw_leaf(game,center+Vector2(1,1.5),radius*1.15,heading+sin(float(b.age)*4)*.22,Color(INK,tint.a*.35))
			draw_leaf(game,center,radius*1.1,heading+sin(float(b.age)*4)*.22,tint)
		"tengu_scale":
			var shell := PackedVector2Array([center+axis*radius*2.0,center+side*radius*.95-axis*radius*.2,center-axis*radius*1.25,center-side*radius*.95-axis*radius*.2])
			game.draw_colored_polygon(shell,tint)
			shell.append(shell[0])
			game.draw_polyline(shell,Color(INK,tint.a*.8),1.1,true)
			game.draw_line(center-axis*radius*.6,center+axis*radius*1.2,Color(1,1,1,tint.a*.8),1.0,true)
		"tengu_rice":
			var grain := PackedVector2Array()
			for i in range(10):
				var t := TAU*i/10.0
				grain.append(center+axis*cos(t)*radius*1.7+side*sin(t)*radius*.6)
			game.draw_colored_polygon(grain,tint)
			game.draw_line(center-axis*radius*.8,center+axis*radius*.8,Color(1,1,1,tint.a*.85),1.0,true)
		"tengu_orb":
			game.draw_circle(center,radius*1.2,Color(INK,tint.a*.7))
			game.draw_circle(center,radius*.95,tint)
			game.draw_circle(center,radius*.45,Color(1,1,1,tint.a*.85))
		"tengu_blade":
			game.draw_colored_polygon(PackedVector2Array([center+axis*radius*1.8,center+side*radius*.48,center-axis*radius*1.5,center-side*radius*.48]),tint)
			game.draw_line(center-axis*radius,center+axis*radius*1.4,Color(WHITE,tint.a*.8),maxf(.7,radius*.18),true)
		"tengu_paper":
			var long := axis*radius*1.25; var wide := side*radius*.82
			var paper := PackedVector2Array([center-long-wide,center+long-wide,center+long+wide,center-long+wide])
			game.draw_colored_polygon(paper,Color(WHITE,tint.a))
			game.draw_line(center-long*.7-wide*.65,center-long*.7+wide*.65,Color(RED,tint.a),maxf(1,radius*.22),true)
			for i in range(3): game.draw_line(center+long*(-.2+i*.4)-wide*.65,center+long*(-.2+i*.4)+wide*.65,Color(INK,tint.a*.8),maxf(.7,radius*.13),true)
		"tengu_feather":
			var vane := PackedVector2Array([center+axis*radius*1.9,center+axis*radius*.15+side*radius*.9,center-axis*radius*1.6,center-axis*radius*.25-side*radius*.72])
			game.draw_colored_polygon(vane,tint)
			vane.append(vane[0])
			game.draw_polyline(vane,Color(INK,tint.a*.55),1.0,true)
			game.draw_line(center-axis*radius*1.8,center+axis*radius*1.7,Color(WHITE,tint.a*.85),maxf(.7,radius*.2),true)
			for k in range(3): game.draw_line(center+axis*radius*(-.8+k*.6),center+axis*radius*(-1.1+k*.6)+side*radius*.55,Color(WHITE,tint.a*.45),.8,true)

static func draw_cast(game: Control,c: Dictionary) -> void:
	var unit: float=minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	var age: float=float(c.age)
	var origin := Vector2(c.center)
	for road in c.get("aya_roads",[]):
		# The laid-out roads glow faintly until their bullets have fallen.
		var left: float=clampf((float(road.until)-age)/2.2,0.0,1.0)
		game.draw_line(road.from,road.to,Color(WIND,.18*left),maxf(2.0,unit*.12),true)
		game.draw_line(road.from,road.to,Color(WHITE,.35*left),1.0,true)
	match String(c.pattern):
		"aya_leaf_veiling","aya_tengu_fall","aya_storm_day","nonspell_aya_wind":
			# Her hauchiwa fan swirls the wind into a visible vortex.
			for k in range(3):
				var a: float=age*(3.0+k)+TAU*k/3.0
				game.draw_arc(origin,unit*(.35+k*.13),a,a+PI*.9,18,Color(WIND,.5-k*.12),maxf(1.0,unit*.03),true)
		"momiji_sentinel","momiji_maple_guard","nonspell_momiji_patrol","nonspell_momiji_cross":
			# Momiji's thousand-league sight: a slow scan line over the lawn.
			var board := Rect2(game.BOARD_ORIGIN,game.board_size)
			var x: float=board.end.x-fposmod(age*.35,1.0)*board.size.x
			game.draw_line(Vector2(x,board.position.y),Vector2(x,board.end.y),Color(RED,.18),maxf(2.0,unit*.08),true)
			game.draw_line(Vector2(x,board.position.y),Vector2(x,board.end.y),Color(WHITE,.35),1.0,true)
