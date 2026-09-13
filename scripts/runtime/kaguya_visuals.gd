extends RefCounted

const GOLD = Color("f5dca2")
const ROSE = Color("efacd0")

static func treasure(g: Control, p: Vector2, kind: String, s: float) -> void:
	g.draw_circle(p, 33 * s, Color(ROSE, 0.1))
	g.draw_arc(p, 31 * s, g.level_time, g.level_time + TAU, 40, Color(GOLD, 0.65), 1.5 * s, true)
	if kind == "bowl":
		var pts = PackedVector2Array([p + Vector2(-24,-7)*s, p + Vector2(24,-7)*s, p + Vector2(16,15)*s, p + Vector2(-16,15)*s])
		g.draw_colored_polygon(pts, Color("96a99c"))
		g.draw_polyline(pts, GOLD, 2*s, true)
		g.draw_line(p+Vector2(-25,-7)*s,p+Vector2(25,-7)*s,GOLD,4*s,true)
		for n in range(3):
			g.draw_line(p+Vector2(-12+n*12,-1)*s,p+Vector2(-7+n*7,12)*s,Color("566e69"),2*s)
		g.draw_arc(p-Vector2(0,12)*s,12*s,PI,TAU,16,Color("bbe1b0"),2*s,true)
	else:
		var pts = PackedVector2Array([p+Vector2(-22,9)*s,p+Vector2(-18,-12)*s,p+Vector2(0,-22)*s,p+Vector2(18,-12)*s,p+Vector2(22,9)*s,p+Vector2(0,17)*s])
		g.draw_colored_polygon(pts, Color("e8d4ed"))
		for n in range(5):
			g.draw_line(p+Vector2(0,14)*s,p+Vector2(-18+n*9,-12-8*sin(n*PI/4))*s,Color("bc8faf"),2*s,true)
		g.draw_circle(p+Vector2(0,8)*s,7*s,Color("b8f3da"))

static func sky(rt: RefCounted) -> void:
	var g: Control = rt.game
	var s: float = g._battle_unit_scale()
	var center = Vector2(g.size.x * 0.72, g.size.y * 0.27)
	var radius = g.size.y * 0.23
	for ring in range(3):
		var angle = g.level_time * (0.05 if ring % 2 else -0.04)
		g.draw_arc(center, radius + ring * 12 * s, angle, angle + TAU, 100, Color(ROSE, 0.1 + ring * 0.04), 1.5*s, true)
	for n in range(32):
		var angle = TAU*n/32 + g.level_time*0.035
		var p = center + Vector2.from_angle(angle)*radius
		g.draw_line(p, p + Vector2.from_angle(angle)*(10 if n%4==0 else 4)*s, Color(GOLD,0.4), 1.5*s,true)
	# Bamboo silhouettes and the tiled eaves of Eientei frame the open sky.
	for side in [-1,1]:
		var x = g.BOARD_ORIGIN.x - 26*s if side < 0 else g.BOARD_ORIGIN.x + g.board_size.x + 22*s
		for stalk in range(3):
			var xx = x + side*stalk*18*s
			g.draw_line(Vector2(xx,g.size.y),Vector2(xx-side*22*s,g.size.y*0.18),Color("203b3b"),5*s,true)
			for node in range(5):
				var p = Vector2(xx-side*node*3*s,g.size.y*(0.3+node*0.13))
				g.draw_line(p-Vector2(4,0)*s,p+Vector2(4,0)*s,Color("6f8779"),2*s)
				for leaf in [-1,1]:
					g.draw_colored_polygon(PackedVector2Array([p,p+Vector2(leaf*35,-14)*s,p+Vector2(leaf*17,2)*s]),Color("36574f"))
	if rt.night >= 0:
		var dawn = float(rt.night)/4
		g.draw_rect(Rect2(Vector2.ZERO,g.size),Color(0.92,0.6,0.62,dawn*0.025))

static func overlay(rt: RefCounted) -> void:
	var g: Control = rt.game
	var s: float = g._battle_unit_scale()
	for m in rt.marks:
		var rect: Rect2 = g._cell_rect(m.cell.x,m.cell.y).grow(-4*s)
		var p = rect.get_center()
		var color: Color = {"robe": Color("ff965f"), "eternity": Color("abcaef"), "branch": Color("aee1a1")}.get(m.kind, ROSE)
		var ratio = minf(1,float(m.age)/float(m.delay))
		g.draw_rect(rect,Color(color,0.1 if not m.hit else 0.23))
		g.draw_rect(rect,Color(color,0.65),false,1.5*s)
		g.draw_arc(p,rect.size.y*0.33,-PI/2,-PI/2+TAU*ratio,32,color,2*s,true)
		if m.kind == "eternity":
			g.draw_line(p,p+Vector2.from_angle(-PI/2+minf(m.age,2)*3)*rect.size.y*0.24,color,2*s,true)
			g.draw_line(p,p+Vector2.from_angle(minf(m.age,2))*rect.size.y*0.17,color,2*s,true)
		elif not m.hit:
			var jewel = p-Vector2(0,rect.size.y*(0.75-ratio*0.35))
			var vertices=PackedVector2Array([jewel+Vector2(0,-9)*s,jewel+Vector2(7,0)*s,jewel+Vector2(0,9)*s,jewel+Vector2(-7,0)*s])
			g.draw_colored_polygon(vertices,color)
			g.draw_line(jewel+Vector2(0,9)*s,p,Color(color,0.4),1*s,true)
		else:
			for n in range(8):
				var angle=TAU*n/8+float(m.age)*0.3
				g.draw_line(p+Vector2.from_angle(angle)*8*s,p+Vector2.from_angle(angle)*rect.size.y*0.4,Color(color,0.75),2*s,true)
	for t in rt.treasures:
		if float(t.unit.health) <= 0:
			continue
		var origin = Vector2(float(t.unit.x),g._row_center_y(int(t.unit.row)))
		if float(t.age)<2:
			g.draw_arc(origin,38*s,-PI/2,-PI/2+TAU*t.age/2,32,GOLD,2*s,true)
		else:
			for z in g.zombies:
				if rt._ordinary(z) and g._is_enemy_zombie(z) and float(z.health)>0 and rt._near(z,t):
					var point = Vector2(float(z.x),g._row_center_y(int(z.row)))
					g.draw_line(origin,point,Color(GOLD if t.unit.treasure_kind=="bowl" else Color("a6edba"),0.32),1.5*s,true)
	if not rt.rewind.is_empty():
		var snap: Dictionary = rt.rewind
		for record in snap.plants:
			var rect: Rect2 = g._cell_rect(record.row,record.col).grow(-6*s)
			g.draw_rect(rect,Color(ROSE,0.5),false,1.5*s)
			for corner in [rect.position,rect.end]:
				g.draw_circle(corner,3*s,GOLD)
	if rt.flash>0:
		g.draw_rect(Rect2(g.BOARD_ORIGIN,g.board_size),Color(0.81,0.67,0.94,rt.flash*0.2))
		var p: Vector2 = g.BOARD_ORIGIN+g.board_size/2
		g.draw_arc(p,g.board_size.y*(1-rt.flash)*0.7,0,TAU,72,Color(ROSE,rt.flash*0.7),4*s,true)
