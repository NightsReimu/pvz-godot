extends RefCounted

# Shared vector details for battle units, seed cards and the almanac.
# Coordinates stay local: callers may already have an animation transform.
static func polygon(canvas: CanvasItem, center: Vector2, scale: float, vertices: Array, color: Color, outline: float = 1.8) -> void:
	var points := PackedVector2Array()
	for vertex in vertices:
		points.append(center + Vector2(vertex) * scale)
	canvas.draw_colored_polygon(points, color)
	if outline > 0:
		points.append(points[0])
		canvas.draw_polyline(points, Color(GameTheme.INK.r, GameTheme.INK.g, GameTheme.INK.b, color.a), outline * scale, true)


static func ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color, outline: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		points.append(center + Vector2.from_angle(TAU * i / 32.0) * radius)
	canvas.draw_colored_polygon(points, color)
	if outline > 0:
		points.append(points[0])
		canvas.draw_polyline(points, Color(GameTheme.INK.r, GameTheme.INK.g, GameTheme.INK.b, color.a), outline, true)


static func torchwood(canvas: CanvasItem, center: Vector2, s: float, flash: float, alpha: float, time: float) -> void:
	var bark := Color("#986039",alpha).lerp(Color(1,1,1,alpha),clampf(flash*1.6,0,1))
	var dark := Color("#603d2b",alpha)
	ellipse(canvas,center+Vector2(0,36)*s,Vector2(27,5)*s,Color(0.12,0.24,0.16,alpha*0.16))
	polygon(canvas,center,s,[Vector2(-18,-7),Vector2(18,-7),Vector2(17,23),Vector2(25,34),Vector2(12,32),Vector2(5,37),Vector2(-6,33),Vector2(-24,35),Vector2(-17,23)],bark,2)
	polygon(canvas,center,s,[Vector2(-18,-4),Vector2(-10,-2),Vector2(-9,28),Vector2(-22,33),Vector2(-16,22)],dark,0)
	for x in [-9,0,11]:
		canvas.draw_polyline(PackedVector2Array([center+Vector2(x,4)*s,center+Vector2(x-2,18)*s,center+Vector2(x+1,30)*s]),dark,1.5*s,true)
	ellipse(canvas,center+Vector2(0,-5)*s,Vector2(18,7)*s,Color("#d89552",alpha),1.8*s)
	ellipse(canvas,center+Vector2(0,-5)*s,Vector2(12,4)*s,dark)
	ellipse(canvas,center+Vector2(0,-5)*s,Vector2(8,2.4)*s,Color("#e9ad66",alpha))
	for i in range(3):
		var x := float(i-1)*12
		var sway := sin(time*7+i*2)*3
		var height := 27.0 + (12.0 if i==1 else 0.0) + sin(time*9+i)*3
		var flame := [Vector2(x-9,-5),Vector2(x-11,-14),Vector2(x-6,-25),Vector2(x-3+sway,-height),Vector2(x+1+sway,-height-7),Vector2(x+3,-22),Vector2(x+8,-15),Vector2(x+9,-8),Vector2(x+4,-3)]
		polygon(canvas,center,s,flame,Color("#f16a28",alpha*0.92),0)
		polygon(canvas,center,s,[Vector2(x-5,-5),Vector2(x-5,-13),Vector2(x+sway*0.4,-height*0.7),Vector2(x+4,-15),Vector2(x+5,-6)],Color("#ffc64b",alpha),0)
		polygon(canvas,center,s,[Vector2(x-2,-5),Vector2(x,-17),Vector2(x+3,-6)],Color("#fff1a6",alpha),0)
	for x in [-7,7]:
		ellipse(canvas,center+Vector2(x,11)*s,Vector2(4,5)*s,dark)
		ellipse(canvas,center+Vector2(x,12)*s,Vector2(2,3)*s,Color("#ffd365",alpha))
	canvas.draw_polyline(PackedVector2Array([center+Vector2(-4,23)*s,center+Vector2(0,25)*s,center+Vector2(5,22)*s]),dark,1.8*s,true)


static func jacket(canvas: CanvasItem, c: Vector2, shirt: Color, pants: Color) -> void:
	polygon(canvas,c,1,[Vector2(-11,-10),Vector2(-1,-6),Vector2(-5,7),Vector2(-13,-1)],shirt.lightened(0.24),1)
	polygon(canvas,c,1,[Vector2(10,-10),Vector2(1,-6),Vector2(5,7),Vector2(13,-1)],shirt.lightened(0.18),1)
	canvas.draw_line(c+Vector2(1,5),c+Vector2(1,14),shirt.darkened(0.35),1.4,true)
	canvas.draw_circle(c+Vector2(3,11),1.1,Color("#d8c8a0"),true,-1,true)
	canvas.draw_rect(Rect2(c+Vector2(-12,18),Vector2(7,6)),pants.lightened(0.3))
	for x in [-12,-9,-6]:
		canvas.draw_line(c+Vector2(x,17),c+Vector2(x,20),Color("#b7bca6"),0.8,true)


static func equipment(canvas: CanvasItem, c: Vector2, kind: String, ratio: float) -> void:
	var worn := ratio <= 0.5
	match kind:
		"conehead":
			var tip := Vector2(-5,-55) if worn else Vector2(0,-61)
			polygon(canvas,c,1,[tip,Vector2(13,-34),Vector2(-13,-34)],Color("#ec8334"))
			polygon(canvas,c,1,[Vector2(-8,-44),Vector2(7,-44),Vector2(10,-39),Vector2(-10,-39)],Color("#fff1c9"),0)
			canvas.draw_line(c+Vector2(-15,-33),c+Vector2(15,-33),Color("#a75129"),3,true)
			if worn:
				polygon(canvas,c,1,[Vector2(-5,-55),Vector2(4,-50),Vector2(-1,-47)],Color("#905239"),0)
				canvas.draw_polyline(PackedVector2Array([c+Vector2(7,-41),c+Vector2(2,-38),c+Vector2(6,-35)]),Color("#6e4d37"),2,true)
		"buckethead":
			var edge := Vector2(9,-46) if worn else Vector2(14,-49)
			polygon(canvas,c,1,[Vector2(-14,-49),Vector2(5,-51),edge,Vector2(17,-31),Vector2(-17,-31)],Color("#94a6ac"))
			canvas.draw_line(c+Vector2(-10,-46),c+Vector2(-11,-34),Color("#d7e2dd"),4,true)
			canvas.draw_line(c+Vector2(-17,-31),c+Vector2(17,-31),Color("#536870"),3,true)
			canvas.draw_arc(c+Vector2(0,-36),19,0.12,PI-0.12,20,Color("#536870"),1.7,true)
			if worn:
				canvas.draw_polyline(PackedVector2Array([c+Vector2(11,-45),c+Vector2(3,-41),c+Vector2(10,-37),c+Vector2(1,-34)]),Color("#4a6166"),2,true)
				canvas.draw_line(c+Vector2(-6,-43),c+Vector2(0,-39),Color("#dee6dd"),2,true)
		"newspaper":
			# Paper is held in front: images mirror the left-facing walk direction.
			var page := [Vector2(-7,-29),Vector2(-19,-31),Vector2(-33,-28),Vector2(-32,6),Vector2(-20,3),Vector2(-7,6)]
			if worn:
				page = [Vector2(-7,-29),Vector2(-19,-31),Vector2(-33,-28),Vector2(-32,-9),Vector2(-26,-5),Vector2(-30,0),Vector2(-24,-2),Vector2(-20,3),Vector2(-16,-2),Vector2(-7,1)]
			polygon(canvas,c,1,page,Color("#f3ebd7"),1.4)
			canvas.draw_line(c+Vector2(-20,-27),c+Vector2(-20,1),Color("#baae96"),1,true)
			canvas.draw_rect(Rect2(c+Vector2(-28,-25),Vector2(18,3)),Color("#59696a"))
			canvas.draw_rect(Rect2(c+Vector2(-17,-18),Vector2(7,7)),Color("#a1aea1"))
			for y in range(-18, -3 if worn else 1, 4):
				canvas.draw_line(c+Vector2(-29,y),c+Vector2(-23,y),Color("#8e9486"),1,true)
			for y in [-8,-4]:
				canvas.draw_line(c+Vector2(-17,y),c+Vector2(-10,y),Color("#8e9486"),1,true)


static func impact_style(projectile: Dictionary, target: Dictionary) -> String:
	if bool(projectile.get("fire", false)):
		return "fire"
	if float(projectile.get("slow_duration", 0.0)) > 0:
		return "ice"
	if float(target.get("shield_health", 0.0)) > 0:
		return "armor"
	return "leaf"


static func impact(canvas: CanvasItem, center: Vector2, radius: float, life: float, color: Color, style: String) -> void:
	var fade := clampf(life,0,1)
	var spread := radius*(0.25+(1-fade)*0.7)
	canvas.draw_circle(center,radius*0.16*fade,Color(1,0.98,0.85,fade*0.85),true,-1,true)
	for i in range(6):
		var angle := TAU*i/6.0+0.3
		var direction := Vector2.from_angle(angle)
		var point := center+direction*spread
		var side := direction.orthogonal()
		var length := radius*(0.1+fade*0.1)
		if style == "ice":
			canvas.draw_colored_polygon(PackedVector2Array([point-direction*length,point+side*length*0.4,point+direction*length,point-side*length*0.4]),Color("#b6ecf6",fade))
			canvas.draw_line(point-direction*length,point+direction*length,Color(1,1,1,fade),1,true)
		elif style == "fire" or style == "armor":
			var spark := Color("#ffad48" if style=="fire" else "#ffe2a0",fade)
			canvas.draw_line(point-direction*length,point+direction*length*0.7,spark,2 if style=="fire" else 1.5,true)
			canvas.draw_circle(point,1.2,Color(1,0.97,0.78,fade),true,-1,true)
		else:
			ellipse(canvas,point,Vector2(2.2,3.0)*fade,Color(color,fade*0.85))
	if style == "fire":
		canvas.draw_arc(center,spread*0.7,0.2,PI*1.7,20,Color(1,0.57,0.2,fade*0.55),1.6,true)


# Rounded anatomy built from a closed quadratic contour. The sparse points are
# species landmarks, not per-frame tessellation of a full SVG document.
static func contour(canvas: CanvasItem, c: Vector2, s: float, anchors: Array, fill: Color, stroke: float = 1.6) -> void:
	var outline: Array = []
	for i in range(anchors.size()):
		var previous: Vector2 = anchors[posmod(i - 1, anchors.size())]
		var current: Vector2 = anchors[i]
		var next: Vector2 = anchors[(i + 1) % anchors.size()]
		var begin := (previous + current) * 0.5
		var end := (current + next) * 0.5
		for sample in range(5):
			var t := float(sample) / 5.0
			outline.append((1.0 - t) * (1.0 - t) * begin + 2.0 * (1.0 - t) * t * current + t * t * end)
	polygon(canvas, c, s, outline, fill, stroke)


static func zombie_head(canvas: CanvasItem, c: Vector2, radius: float, skin: Color, bite: float = 0.0) -> void:
	var s := radius / 17.0
	var ink := Color("#2d4039", skin.a)
	contour(canvas, c, s, [Vector2(-18,-5), Vector2(-16,-16), Vector2(0,-18), Vector2(17,-12), Vector2(17,4), Vector2(10,8), Vector2(9,17), Vector2(-8,19), Vector2(-17,11), Vector2(-15,3), Vector2(-20,2)], skin)
	contour(canvas, c, s, [Vector2(-14,-10),Vector2(-9,-14),Vector2(1,-13),Vector2(-4,-9),Vector2(-12,-7)],skin.lightened(0.16),0)
	ellipse(canvas,c+Vector2(15,2)*s,Vector2(4,6)*s,skin.darkened(0.08),1.2*s)
	canvas.draw_arc(c+Vector2(15,2)*s,2.3*s,-1.5,1.6,8,skin.darkened(0.38),s,true)
	for eye_data in [Vector3(-7,-4,5.7),Vector3(5,-3,5.0)]:
		var point := c+Vector2(eye_data.x,eye_data.y)*s
		ellipse(canvas,point,Vector2(eye_data.z,eye_data.z*1.12)*s,Color("#f2e8cc", skin.a),1.2*s)
		ellipse(canvas,point+Vector2(-1.4,1)*s,Vector2(1.8,2.2)*s,ink)
		canvas.draw_circle(point+Vector2(-1.8,0.1)*s,.6*s,Color("#fff8e2", skin.a),true,-1,true)
	polygon(canvas,c,s,[Vector2(-5,0),Vector2(-10,5),Vector2(-3,5)],skin.darkened(0.18),.9)
	contour(canvas,c,s,[Vector2(-12,9),Vector2(-6,8),Vector2(1,10),Vector2(8,9),Vector2(7,15+bite*3),Vector2(-4,16+bite*3),Vector2(-12,13)],Color("#59463c", skin.a),1)
	for x in [-8.0,0.0]:
		polygon(canvas,c,s,[Vector2(x,9),Vector2(x+3,9.5),Vector2(x+3,13),Vector2(x,12.5)],Color("#ece2c8", skin.a),.6)
	canvas.draw_line(c+Vector2(-13,-12)*s,c+Vector2(-5,-11)*s,skin.darkened(.35),1.2*s,true)
	canvas.draw_line(c+Vector2(3,-11)*s,c+Vector2(10,-10)*s,skin.darkened(.35),1.2*s,true)
	canvas.draw_line(c+Vector2(-11,19)*s,c+Vector2(0,20)*s,skin.darkened(.28),s,true)


static func zombie_body(canvas: CanvasItem, c: Vector2, shirt: Color, pants: Color, skin: Color, step: float, arms: float, bite: float = 0.0) -> void:
	# Feet point toward the lawn. Sleeves, elbows, palms and torn hems remain
	# separate from armor so losing a held item reveals a complete body.
	for side in [-1.0,1.0]:
		var knee := Vector2(side*10+step*side*.5,32)
		var foot := Vector2(side*13+step*side,43)
		polygon(canvas,c,1,[Vector2(side*6-5,19),Vector2(side*6+5,19),knee+Vector2(4,0),foot+Vector2(3,0),foot+Vector2(-4,0),knee+Vector2(-4,0)],pants,1.5)
		contour(canvas,c+foot,1,[Vector2(-5,-3),Vector2(3,-3),Vector2(7,3),Vector2(5,6),Vector2(-12,6),Vector2(-15,2),Vector2(-11,-1)],Color("#514d3e"),1.5)
		canvas.draw_line(c+foot+Vector2(-11,3),c+foot+Vector2(4,3),Color("#b7b298"),1,true)
	contour(canvas,c,1,[Vector2(-13,-11),Vector2(4,-12),Vector2(16,-3),Vector2(19,17),Vector2(13,28),Vector2(-13,27),Vector2(-18,11)],shirt,1.8)
	polygon(canvas,c,1,[Vector2(-9,-9),Vector2(1,-9),Vector2(4,21),Vector2(-8,22)],Color("#d8d1b7"),0)
	polygon(canvas,c,1,[Vector2(-15,19),Vector2(-5,23),Vector2(-10,30),Vector2(-14,26),Vector2(-18,28)],shirt,1)
	polygon(canvas,c,1,[Vector2(8,18),Vector2(18,17),Vector2(15,28),Vector2(9,25),Vector2(6,29)],shirt.darkened(.1),1)
	jacket(canvas,c,shirt,pants)
	for side in [-1.0,1.0]:
		var elbow := Vector2(side*20,7+arms*.25*side)
		var hand := Vector2(side*(25+arms+4*bite),12-5*bite)
		contour(canvas,c,1,[Vector2(side*11,-7),Vector2(side*17,-4),elbow+Vector2(side*3,-1),elbow+Vector2(-side*3,5),Vector2(side*10,5)],shirt,1.5)
		canvas.draw_line(c+elbow,c+hand,Color("#2d4039"),6.5,true)
		canvas.draw_line(c+elbow,c+hand,skin.darkened(.1),4.3,true)
		contour(canvas,c+hand,1,[Vector2(-5,-2),Vector2(3,-3),Vector2(5,1),Vector2(2,6),Vector2(-4,4)],skin,1.2)
		for finger in [-2.0,1.0]:
			canvas.draw_line(c+hand+Vector2(finger,1),c+hand+Vector2(finger-1,4),skin.darkened(.35),.8,true)
	zombie_head(canvas,c+Vector2(0,-28),17,skin,bite)


static func coat_panel(canvas: CanvasItem, rect: Rect2, fill: Color) -> void:
	var c := rect.position + Vector2(rect.size.x * 0.5, 0)
	var w := rect.size.x * 0.5
	var h := rect.size.y
	contour(canvas,c,1,[Vector2(-w*.7,0),Vector2(w*.6,0),Vector2(w,9),Vector2(w*.92,h-4),Vector2(w*.4,h),Vector2(0,h-3),Vector2(-w*.9,h),Vector2(-w,10)],fill,1.7)
	polygon(canvas,c,1,[Vector2(-w*.6,1),Vector2(0,4),Vector2(-4,14),Vector2(-w*.8,7)],fill.lightened(.22),.9)
	polygon(canvas,c,1,[Vector2(w*.5,1),Vector2(0,4),Vector2(4,14),Vector2(w*.8,7)],fill.lightened(.13),.9)
	canvas.draw_line(c+Vector2(0,13),c+Vector2(1,h-6),fill.darkened(.32),1.2,true)
	for y in [16.0,24.0]:
		if y<h-3: canvas.draw_circle(c+Vector2(3,y),1.2,Color("#c5be9c"),true,-1,true)
	canvas.draw_line(c+Vector2(-w*.7,h-8),c+Vector2(-w*.3,h-10),fill.darkened(.22),1,true)


static func football_gear(canvas: CanvasItem, c: Vector2, dark: bool, ratio: float) -> void:
	var red := Color("#544e64" if dark else "#b95049")
	for side in [-1.0,1.0]:
		contour(canvas,c+Vector2(side*17,-5),1,[Vector2(-10,-8),Vector2(3,-11),Vector2(12,-5),Vector2(10,6),Vector2(-8,5)],red,1.7)
		canvas.draw_line(c+Vector2(side*19,-11),c+Vector2(side*24,-4),Color("#e8dbc4"),2,true)
	if ratio <= 0: return
	contour(canvas,c,1,[Vector2(-20,-36),Vector2(-20,-46),Vector2(-10,-54),Vector2(9,-53),Vector2(20,-43),Vector2(17,-25),Vector2(10,-20),Vector2(6,-36)],red,1.8)
	canvas.draw_line(c+Vector2(-4,-51),c+Vector2(3,-48),Color("#eadcbd"),3,true)
	ellipse(canvas,c+Vector2(11,-32),Vector2(5,6),red.lightened(.18),1.2)
	ellipse(canvas,c+Vector2(11,-32),Vector2(1.5,2),Color("#3c4040"))
	canvas.draw_polyline(PackedVector2Array([c+Vector2(10,-29),c+Vector2(-21,-29),c+Vector2(-21,-20),c+Vector2(5,-20),c+Vector2(10,-29)]),Color("#b8c1b8"),2.1,true)
	canvas.draw_line(c+Vector2(-12,-29),c+Vector2(-12,-20),Color("#b8c1b8"),1.7,true)
	if ratio < 0.5:
		canvas.draw_polyline(PackedVector2Array([c+Vector2(7,-49),c+Vector2(2,-43),c+Vector2(8,-41),c+Vector2(3,-37)]),Color("#373e38"),1.8,true)
