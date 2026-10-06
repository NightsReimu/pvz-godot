extends RefCounted

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
			dm._fan(c,origin,9,aim,.9,172*scale,WIND,"tengu_feather",_extra(scale,12.0))
			_lanes(dm,c,origin,scale,3,3,WHITE,"tengu_feather",12.0,144)
			cadence=1.35
		"aya_crossroads":
			# Four braided, branching roads. Red and white forks cross at the body.
			for side in [-1,1]:
				for branch in [0,1]:
					var angle: float=PI+side*(.15+branch*.30)+sin(turn)*.1
					dm._fan(c,origin,5,angle,.32, (145+branch*22)*scale,WHITE if branch==0 else RED,"tengu_feather",_extra(scale,14.0,-side*.06))
			_lanes(dm,c,origin,scale,2,3,WIND,"tengu_leaf",13.0,125)
			cadence=1.35
		"aya_saruta_cross":
			for branch in range(6):
				var angle: float=PI+(branch-2.5)*.23+sin(turn)*.12
				dm._fan(c,origin,5,angle,.28,(144+branch%3*20)*scale,WHITE if branch%2 else RED,"tengu_feather",_extra(scale,15.0,(branch%2*2-1)*.075))
			cadence=1.3
		"aya_leaf_veiling":
			for layer in range(2): dm._fan(c,origin,9,PI+sin(turn+layer)*.20,1.5,(116+layer*28)*scale,RED if layer else WIND,"tengu_leaf",_extra(scale,13.0,.20*(1 if layer else -1)))
			_lanes(dm,c,origin,scale,3,3,WHITE,"tengu_feather",13.0,150)
			cadence=1.4
		"aya_tengu_fall":
			# Downhill wind enters from the mountain crest and bends toward the house.
			for i in range(6):
				var edge: Vector2=dm._point(.40+fposmod(wave*.047+i*.09,.56),0)
				dm._fan(c,edge,4,PI*.76,.35,136*scale,WIND if i%2 else WHITE,"tengu_feather",_extra(scale,15.0,-.07))
			_lanes(dm,c,origin,scale,3,3,RED,"tengu_leaf",14.0,150)
			cadence=1.35
		"aya_storm_day":
			for layer in range(2): dm._fan(c,origin,13,PI+sin(turn+layer)*.25,1.8,(142+layer*24)*scale,WHITE if layer else WIND,"tengu_feather",_extra(scale,16.0,.17*(1 if layer else -1)))
			dm._ring(c,origin,10,-turn,105*scale,RED,"tengu_leaf",_extra(scale,14.0,.2))
			cadence=1.25
		"aya_fantasy_storm", "aya_peerless_wind":
			# Native timed survival owns invulnerability; these are real moving-body
			# wind trails, not teleported hitboxes or a last-card shortcut.
			var peerless := String(c.pattern)=="aya_peerless_wind"
			dm._fan(c,origin,15 if peerless else 11,aim,1.35,195*scale,WHITE,"tengu_feather",_extra(scale,17.0 if peerless else 15.0))
			_lanes(dm,c,origin,scale,4,5 if peerless else 4,WIND,"tengu_leaf",15.0,156)
			if wave%2==0: dm._ring(c,origin,8,turn,108*scale,RED,"tengu_leaf",_extra(scale,13.0,.16))
			cadence=1.16 if peerless else 1.25
		"aya_procession", "aya_divine_advent", "aya_terukuni":
			var hard := String(c.pattern)!="aya_procession"
			_wall(dm,c,origin,scale,posmod(wave+int(c.stage),game.active_rows.size()),4 if hard else 3,138 if hard else 126)
			if hard: dm._fan(c,origin,9,aim,1.05,168*scale,RED,"tengu_feather",_extra(scale,16.0))
			if String(c.pattern)=="aya_terukuni": dm._ring(c,origin,12,turn,117*scale,GOLD,"tengu_leaf",_extra(scale,16.0,-.13))
			cadence=1.4
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
	var center := Vector2(b.position); var radius := float(b.radius)
	var tint := Color(b.color)
	if float(b.age)<float(b.get("arming_time",0)): tint.a*=.40
	var heading := Vector2(b.velocity).angle(); var axis := Vector2.from_angle(heading); var side := axis.orthogonal()
	match String(b.shape):
		"tengu_leaf": draw_leaf(game,center,radius,heading+sin(float(b.age)*4)*.22,tint)
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
			game.draw_colored_polygon(PackedVector2Array([center+axis*radius*1.7,center+axis*radius*.15+side*radius*.8,center-axis*radius*1.5,center-axis*radius*.25-side*radius*.65]),tint)
			game.draw_line(center-axis*radius*1.6,center+axis*radius*1.5,Color(WHITE,tint.a*.75),maxf(.7,radius*.18),true)
