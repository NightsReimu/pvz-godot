extends RefCounted

const FIRE = Color("ff8557")
const GOLD = Color("ffdb99")

static func ground(rt: RefCounted) -> void:
	var g: Control = rt.game
	var s: float = g._battle_unit_scale()
	for m in rt.marks:
		var center: Vector2 = g._cell_center(m.cell.x,m.cell.y)
		var rect = Rect2(center-g.CELL_SIZE*0.45,g.CELL_SIZE*0.9)
		var ready = float(m.age)>=float(m.delay)
		var color = Color("adf1b3") if m.kind=="archive" else FIRE
		g.draw_rect(rect,Color(color,0.18 if ready else 0.065),true)
		g.draw_rect(rect,Color(color,0.85),false,1.5*s)
		var progress = clampf(float(m.age)/float(m.delay),0,1)
		g.draw_arc(center,g.CELL_SIZE.y*0.30,-PI/2,-PI/2+TAU*progress,32,Color(color,0.7),2*s,true)
		if m.kind=="archive":
			g.draw_rect(Rect2(center-Vector2(11,15)*s,Vector2(22,30)*s),Color(color,0.55),false,2*s)
			for i in range(3): g.draw_line(center+Vector2(-6,-7+i*7)*s,center+Vector2(6,-7+i*7)*s,color,s,true)
		elif ready:
			for n in range(4):
				var point = center + Vector2((n-1.5)*15,12)*s
				flame(g,point,10*s,float(m.age)*5+n)
		else:
			g.draw_line(center+Vector2(-8,-8)*s,center+Vector2(8,8)*s,color,2*s,true)
			g.draw_line(center+Vector2(8,-8)*s,center+Vector2(-8,8)*s,color,2*s,true)

static func flame(g: Control, p: Vector2, radius: float, time: float) -> void:
	g.draw_circle(p,radius*1.5,Color(FIRE,0.08))
	var points = PackedVector2Array([p+Vector2(-radius,0),p+Vector2(-radius*0.55,-radius),p+Vector2(sin(time)*radius*0.4,-radius*2.2),p+Vector2(radius*0.35,-radius*0.7),p+Vector2(radius,0),p+Vector2(0,radius*0.45)])
	g.draw_colored_polygon(points,Color(FIRE,0.85))
	g.draw_circle(p,radius*0.53,GOLD)

static func paddle(g: Control, point: Vector2, left: bool, s: float) -> void:
	var tilt = -0.3 if left else 0.3
	var handle = point+Vector2(0,27*s).rotated(tilt)
	g.draw_line(point,handle,Color("522c28"),9*s,true)
	g.draw_line(point,handle,Color("d9af79"),4*s,true)
	g.draw_circle(point,18*s,Color("341c2a"))
	g.draw_circle(point,15*s,Color("f75f63"))
	g.draw_arc(point,14*s,-PI,0,24,Color("ffdac4"),2*s,true)
	for n in range(3):
		g.draw_line(point+Vector2(-9,-6+n*6)*s,point+Vector2(9,-6+n*6)*s,Color(0.4,0.07,0.1,0.3),s,true)

static func overlay(rt: RefCounted) -> void:
	var g: Control = rt.game
	var s: float = g._battle_unit_scale()
	for r in rt.rallies:
		var a = Vector2(r.from)
		var b = Vector2(r.to)
		paddle(g,a,a.x<b.x,s)
		paddle(g,b,b.x<a.x,s)
		if float(r.warning)>0:
			g.draw_dashed_line(a,b,Color(FIRE,0.7),2*s,9*s,true)
			for fraction in [0.25,0.5,0.75]:
				var p = a.lerp(b,fraction)
				var direction = (b-a).normalized()
				g.draw_line(p,p-direction.rotated(0.5)*12*s,GOLD,2*s,true)
				g.draw_line(p,p-direction.rotated(-0.5)*12*s,GOLD,2*s,true)
		else:
			for n in range(r.trail.size()):
				g.draw_circle(r.trail[n],(3+n*0.55)*s,Color(FIRE,0.04+n*0.035))
		var ball = Vector2(r.position)
		flame(g,ball,11*s,float(r.age)*8)
		g.draw_circle(ball,6*s,Color("fff7d5"))
