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


static func mushroom(canvas: CanvasItem, center: Vector2, scale: float, kind: String, flash: float, alpha: float, mature: bool = true, pose: String = "") -> void:
	# Shared mushroom skeleton: shadow, stipe, gill ring, pleats, dome, sheen,
	# spots, then eyes with a specular dot. Specialty shrooms only override colours
	# and their signature features so they read as one family.
	var sun := kind == "sun_shroom"
	var fume := kind == "fume_shroom"
	var hypno := kind == "hypno_shroom"
	var scaredy := kind == "scaredy_shroom"
	var ice := kind == "ice_shroom"
	var doom := kind == "doom_shroom"
	var specialty := hypno or scaredy or ice or doom
	var hiding := scaredy and pose == "hiding"
	var growth := 1.0 if not sun or mature else 0.72
	var s := scale * growth
	var origin := center + Vector2(0, 34 * scale * (1.0 - growth))
	var base_colour := "#9b65bc" if fume else ("#e8af38" if sun else "#b287c9")
	if hypno:
		base_colour = "#a866d4"
	elif scaredy:
		base_colour = "#9c7fd0"
	elif ice:
		base_colour = "#6fb9de"
	elif doom:
		base_colour = "#241a22"
	var cap := Color(base_colour, alpha)
	cap = cap.lerp(Color(1, 1, 1, alpha), clampf(flash * 1.8, 0, 1))
	var cream := Color("#f2e4bf" if not ice else "#dff2fb", alpha).lerp(Color(1, 1, 1, alpha), clampf(flash, 0, 1))
	if doom:
		cream = Color("#b8ada0", alpha).lerp(Color(1, 1, 1, alpha), clampf(flash, 0, 1))
	var ink := Color(GameTheme.INK.r, GameTheme.INK.g, GameTheme.INK.b, alpha)
	var width := 29.0 if fume else (26.0 if sun else 23.0)
	var height := 28.0 if fume else 24.0
	# Each specialty shroom gets its own silhouette, otherwise they read as one cap recoloured.
	if hypno:
		width = 29.0
		height = 18.0
	elif scaredy:
		width = 17.0
		height = 32.0
	elif ice:
		width = 26.0
		height = 16.0
	elif doom:
		width = 32.0
		height = 27.0
	var spot_tint := Color("#eedaf3", alpha * 0.88)
	if hypno:
		spot_tint = Color("#e9c6ff", alpha * 0.9)
	elif ice:
		spot_tint = Color("#f2fbff", alpha * 0.95)
	elif doom:
		spot_tint = Color("#ff9a6a", alpha * 0.7)
	ellipse(canvas, origin + Vector2(0, 36) * s, Vector2(22, 4) * s, Color(0.12, 0.24, 0.16, alpha * 0.16))
	polygon(canvas, origin, s, [Vector2(-11,-6), Vector2(10,-6), Vector2(11,15), Vector2(16,30), Vector2(9,35), Vector2(-10,35), Vector2(-16,30), Vector2(-11,13)], cream)
	polygon(canvas, origin, s, [Vector2(-11,0), Vector2(-6,0), Vector2(-6,27), Vector2(-10,31), Vector2(-14,29)], Color("#cabb98", alpha), 0)
	ellipse(canvas, origin + Vector2(0,-6) * s, Vector2(width,8) * s, Color(cap.darkened(0.32), alpha), 1.6*s)
	for i in range(-3,4):
		canvas.draw_line(origin + Vector2(i*5,-7)*s, origin + Vector2(i*7,-2)*s, Color("#ebcddd",alpha*0.5), s, true)
	var dome: Array = []
	for i in range(21):
		var angle := PI + PI*i/20.0
		dome.append(Vector2(cos(angle)*width, -10+sin(angle)*height))
	dome.append_array([Vector2(width*0.7,-4), Vector2(0,-5), Vector2(-width*0.7,-4)])
	polygon(canvas,origin,s,dome,cap)
	ellipse(canvas, origin+Vector2(-8,-23)*s, Vector2(9,4)*s, Color(cap.lightened(0.3), alpha*0.8))
	for spot in [Vector3(-16,-13,3.5),Vector3(7,-25,4.3),Vector3(17,-13,3.0)]:
		ellipse(canvas,origin+Vector2(spot.x,spot.y)*s,Vector2(spot.z,spot.z*0.65)*s,Color("#fff0b6" if sun else "#eedaf3",alpha*0.88))
	if doom:
		# Sunken sockets with a burning light behind them.
		for x in [-6,6]:
			ellipse(canvas, origin+Vector2(x,9)*s,Vector2(4.2,5.0)*s,Color(0.04,0.03,0.03,alpha))
			ellipse(canvas, origin+Vector2(x,9.5)*s,Vector2(2.0,2.4)*s,Color(1.0,0.62,0.24,alpha*0.9))
			canvas.draw_circle(origin+Vector2(x-0.4,8.6)*s,0.8*s,Color(1,1,1,alpha),true,-1,true)
		if not hiding:
			polygon(canvas, origin, s, [Vector2(-7,17),Vector2(-2,15),Vector2(0,19),Vector2(2,15),Vector2(7,17),Vector2(4,22),Vector2(-4,22)], ink, 0.9)
	elif hiding:
		# Squeezed-shut eyes while it cowers.
		for x in [-6,6]:
			canvas.draw_arc(origin+Vector2(x,9)*s, 3.4*s, PI, TAU, 12, ink, 1.8*s, true)
		canvas.draw_arc(origin+Vector2(0,19)*s, 4.0*s, 0.15, PI-0.15, 12, ink, 1.6*s, true)
	elif ice:
		# Frosted and glaring, matching the original's annoyed ice shroom.
		for x in [-6,6]:
			ellipse(canvas, origin+Vector2(x,9)*s,Vector2(3.0,3.8)*s,Color(0.06,0.14,0.3,alpha))
			canvas.draw_circle(origin+Vector2(x-0.5,7.8)*s,1.0*s,Color(1,1,1,alpha),true,-1,true)
			# Angled brow pointing inward: the scowl.
			var brow_in := 1.0 if x < 0 else -1.0
			canvas.draw_line(origin+Vector2(x-4.0*brow_in,4.0)*s, origin+Vector2(x+4.0*brow_in,6.5)*s, ink, 2.2*s, true)
		canvas.draw_arc(origin+Vector2(0,18)*s, 3.6*s, 0.15, PI-0.15, 10, ink, 1.5*s, true)
	elif hypno:
		# Counter-rotating spiral eyes.
		var span := float(Time.get_ticks_msec()) / 1000.0 * 3.4
		for x in [-6,6]:
			for ring in range(3):
				var ring_r := (5.6 - float(ring) * 1.7) * s
				var ring_col := Color(0.92,0.22,0.26,alpha*(0.6+float(ring)*0.16)) if ring % 2 == 0 else Color(1.0,0.78,0.72,alpha*(0.5+float(ring)*0.16))
				canvas.draw_arc(origin+Vector2(x,9)*s, ring_r, span+float(ring)*0.5, span+float(ring)*0.5+PI*1.5, 16, ring_col, 1.8*s, true)
			canvas.draw_circle(origin+Vector2(x,9)*s, 1.1*s, Color(0.92,0.22,0.26,alpha), true, -1, true)
		canvas.draw_arc(origin+Vector2(0,18)*s, 4.2*s, 0.15, PI-0.15, 12, ink, 1.6*s, true)
	else:
		for x in [-5,5]:
			ellipse(canvas, origin+Vector2(x,9)*s,Vector2(2.6,3.8)*s,ink)
			canvas.draw_circle(origin+Vector2(x-0.5,7.8)*s,0.9*s,Color(1,1,1,alpha),true,-1,true)
	if scaredy and not hiding:
		# Beads of sweat, plus oversized worried brows.
		for x in [-6,6]:
			canvas.draw_line(origin+Vector2(x-3,4)*s, origin+Vector2(x+3,1)*s, ink, 1.6*s, true)
		canvas.draw_circle(origin+Vector2(15,-2)*s, 2.0*s, Color(0.74,0.92,1.0,alpha*0.85), true, -1, true)
		canvas.draw_circle(origin+Vector2(18,3)*s, 1.4*s, Color(0.74,0.92,1.0,alpha*0.65), true, -1, true)
	if hypno:
		# Tie-dye blotches over deep purple, like the original psychedelic cap.
		for blotch in range(8):
			var blotch_angle := PI + PI * (float(blotch) + 0.5) / 8.0
			var blotch_pos := origin + Vector2(cos(blotch_angle) * width * 0.56, -8.0 + sin(blotch_angle) * height * 0.6) * s
			var blotch_r := (5.0 + float(blotch % 3) * 2.2) * s
			canvas.draw_circle(blotch_pos, blotch_r, Color(0.44, 0.74, 0.98, alpha * 0.45), true, -1, true)
			canvas.draw_circle(blotch_pos + Vector2(-1.0, -1.0) * s, blotch_r * 0.45, Color(0.86, 0.96, 1.0, alpha * 0.5), true, -1, true)
		for swirl in range(3):
			var swirl_r := (width * 0.5 - float(swirl) * 4.5) * s
			canvas.draw_arc(origin + Vector2(0, -8) * s, swirl_r, -0.6 + float(swirl) * 0.9, 2.4 + float(swirl) * 0.9, 18,
				Color(0.92, 0.82, 1.0, alpha * (0.5 - float(swirl) * 0.1)), 1.6 * s, true)
	elif ice:
		# A raised cluster of ice spikes instead of flat shards.
		for spike in range(5):
			var spike_x := -15.0 + float(spike) * 7.5
			var spike_h := 7.0 + float((spike * 3) % 4) * 3.2
			polygon(canvas, origin, s, [Vector2(spike_x - 3.4, -20), Vector2(spike_x, -20 - spike_h), Vector2(spike_x + 3.4, -20)],
				Color(0.88, 0.97, 1.0, alpha * 0.95), 0.9)
			canvas.draw_line(origin + Vector2(spike_x - 1.0, -21) * s, origin + Vector2(spike_x, -22 - spike_h * 0.7) * s,
				Color(1, 1, 1, alpha * 0.7), 1.0 * s, true)
	elif doom:
		# Warty growths bulging off the cap, with ember cracks between them.
		for wart in range(6):
			var wart_angle := PI + PI * (float(wart) + 0.5) / 6.0
			var wart_pos := origin + Vector2(cos(wart_angle) * width * 0.66, -8.0 + sin(wart_angle) * height * 0.66) * s
			var wart_r := (3.6 + float(wart % 3) * 1.1) * s
			canvas.draw_circle(wart_pos, wart_r, Color(0.55, 0.1, 0.18, alpha), true, -1, true)
			canvas.draw_circle(wart_pos + Vector2(-0.8, -0.8) * s, wart_r * 0.42, Color(0.86, 0.36, 0.3, alpha * 0.85), true, -1, true)
		for crack in range(4):
			var crack_dir := Vector2.from_angle(TAU * float(crack) / 4.0 + 0.4)
			canvas.draw_line(origin + crack_dir * 9.0 * s, origin + crack_dir * 20.0 * s, Color(0.3, 0.02, 0.08, alpha * 0.85), 2.0 * s, true)
	if sun:
		canvas.draw_arc(origin+Vector2(0,17)*s,4*s,0.15,PI-0.15,12,ink,1.4*s,true)
		ellipse(canvas,origin+Vector2(-9,16)*s,Vector2(3,1.6)*s,Color("#ecaa68",alpha*0.65))
	elif specialty:
		# Specialty shrooms get their own mouth above; a spore nozzle would read as a fume shroom.
		pass
	else:
		var muzzle := Vector2(17,15) if fume else Vector2(13,16)
		var reach := 16.0 if fume else 8.0
		polygon(canvas,origin,s,[muzzle+Vector2(-8,-7),muzzle+Vector2(reach,-9),muzzle+Vector2(reach,8),muzzle+Vector2(-8,6)],Color(cap.lightened(0.18),alpha))
		ellipse(canvas,origin+(muzzle+Vector2(reach,0))*s,Vector2(5,8)*s,Color(cap.lightened(0.32),alpha),1.5*s)
		ellipse(canvas,origin+(muzzle+Vector2(reach+0.5,0))*s,Vector2(2.8,5)*s,Color(cap.darkened(0.55),alpha))


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
