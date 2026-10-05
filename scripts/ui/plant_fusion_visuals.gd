extends RefCounted
const Art = preload("res://scripts/ui/fusion_plant_art.gd")
const Defs = preload("res://scripts/game_defs.gd")
static var textures: Dictionary = {}
const MAX_TEXTURES := 256
const INK := Color("283e35")

# Element palettes: [deep, main, light]. Every fusion effect is drawn from these,
# so a fire-frost graft reads as both at a glance.
const PALETTES := {
	"fire": [Color("c8452a"), Color("ff8a3d"), Color("ffe08a")],
	"frost": [Color("3d8fb8"), Color("8fe3ff"), Color("f0ffff")],
	"shock": [Color("3c6fd1"), Color("8fd8ff"), Color("f2fdff")],
	"poison": [Color("4d8a2a"), Color("a6e05a"), Color("efffb0")],
	"hypno": [Color("8a3fb5"), Color("e39bff"), Color("ffe1fb")],
	"sun": [Color("c98a1e"), Color("ffd75e"), Color("fff6c8")],
	"heal": [Color("3f9a55"), Color("8fe39a"), Color("f0ffe0")],
	"magnet": [Color("b84a4a"), Color("ff9a8a"), Color("e8eeff")],
	"wind": [Color("4f9e8c"), Color("b8f2e0"), Color("ffffff")],
	"shield": [Color("9a7a3a"), Color("f2d48a"), Color("fffbe6")],
	"leaf": [Color("3f7a3a"), Color("9fd279"), Color("f1ffd8")],
}


static func texture_for(id: String) -> Texture2D:
	if textures.has(id): return textures[id]
	var texture: Texture2D
	if bool(Defs.PLANTS[id].get("fusion_art_dynamic",false)):
		var pixels := Image.new()
		if pixels.load_svg_from_string(Art.svg_for(id,Defs.PLANTS[id])) != OK: return null
		texture = ImageTexture.create_from_image(pixels)
	else: texture = load("res://art/vector/fusions/%s.svg" % id)
	if textures.size() >= MAX_TEXTURES: textures.erase(textures.keys()[0])
	textures[id] = texture
	return texture


static func element(traits: Array) -> String:
	for tag in ["fire","frost","shock","poison","hypno","sun","heal","magnet","wind","shield"]:
		if tag in traits: return tag
	if "chain" in traits: return "shock"
	if "dream" in traits or "summon" in traits: return "hypno"
	if "root" in traits or "thorns" in traits: return "leaf"
	return "leaf"


static func palette(traits: Array) -> Array:
	return PALETTES[element(traits)]


static func color_for(traits: Array) -> Color:
	if "fire" in traits and "frost" in traits: return Color("e7a5b9")
	return palette(traits)[1]


# ---------------------------------------------------------------- primitives

static func _a(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a*clampf(alpha,0,1))


static func glow(canvas: CanvasItem, c: Vector2, radius: float, color: Color, alpha: float, additive: bool = true) -> void:
	for i in range(4):
		var r: float = radius*(1.0-i*0.2)
		canvas.draw_circle(c, r, _a(color, alpha*(0.1+i*0.07)), true, -1, true)
	if additive and canvas.get("glow_primitives") != null:
		canvas.glow_primitives.append({"pos": c, "radius": radius*0.55, "color": _a(color, alpha*0.35)})


static func ring(canvas: CanvasItem, c: Vector2, r: float, width: float, color: Color, alpha: float, start: float = 0.0, sweep: float = TAU) -> void:
	if r <= 0.5: return
	canvas.draw_arc(c, r, start, start+sweep, 48, _a(color, alpha*0.28), width*2.6, true)
	canvas.draw_arc(c, r, start, start+sweep, 48, _a(color, alpha), width, true)
	canvas.draw_arc(c, r, start, start+sweep, 48, _a(Color.WHITE, alpha*0.55), maxf(0.8, width*0.35), true)


static func polygon(canvas: CanvasItem, points: PackedVector2Array, fill: Color, outline: float = 0.0, ink: Color = INK) -> void:
	if points.size() < 3: return
	canvas.draw_colored_polygon(points, fill)
	if outline > 0:
		var closed := points.duplicate(); closed.append(points[0])
		canvas.draw_polyline(closed, _a(ink, fill.a), outline, true)


static func teardrop(c: Vector2, dir: Vector2, length: float, width: float) -> PackedVector2Array:
	var side := dir.orthogonal()
	var points := PackedVector2Array()
	for i in range(13):
		var t: float = i/12.0
		var w: float = sin(t*PI)*width*(1.0-t*0.55)
		points.append(c+dir*length*t+side*w)
	for i in range(12, -1, -1):
		var t: float = i/12.0
		var w: float = sin(t*PI)*width*(1.0-t*0.55)
		points.append(c+dir*length*t-side*w)
	return points


static func flame(canvas: CanvasItem, base: Vector2, dir: Vector2, length: float, width: float, alpha: float, pal: Array) -> void:
	polygon(canvas, teardrop(base, dir, length, width), _a(pal[0], alpha*0.9))
	polygon(canvas, teardrop(base+dir*length*0.08, dir, length*0.78, width*0.68), _a(pal[1], alpha))
	polygon(canvas, teardrop(base+dir*length*0.16, dir, length*0.5, width*0.36), _a(pal[2], alpha))


static func star(canvas: CanvasItem, c: Vector2, r: float, fill: Color, rotation: float = 0.0, outline: float = 1.0) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		points.append(c+Vector2.from_angle(-PI*0.5+rotation+i*PI/5.0)*(r if i%2 == 0 else r*0.45))
	polygon(canvas, points, fill, outline)


static func sparkle(canvas: CanvasItem, c: Vector2, r: float, color: Color, alpha: float) -> void:
	canvas.draw_line(c-Vector2(r,0), c+Vector2(r,0), _a(color, alpha), maxf(1.0, r*0.22), true)
	canvas.draw_line(c-Vector2(0,r), c+Vector2(0,r), _a(color, alpha), maxf(1.0, r*0.22), true)
	canvas.draw_circle(c, r*0.25, _a(Color.WHITE, alpha), true, -1, true)


static func bolt(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float, seed: float, alpha: float) -> void:
	var points := PackedVector2Array([a])
	var normal: Vector2 = (b-a).normalized().orthogonal()
	var length: float = a.distance_to(b)
	for k in range(1, 7):
		points.append(a.lerp(b, k/7.0)+normal*sin(seed*13.7+k*5.1)*length*0.08)
	points.append(b)
	canvas.draw_polyline(points, _a(color, alpha*0.3), width*3.4, true)
	canvas.draw_polyline(points, _a(color, alpha), width, true)
	canvas.draw_polyline(points, _a(Color.WHITE, alpha), maxf(0.8, width*0.38), true)


static func snowflake(canvas: CanvasItem, c: Vector2, r: float, color: Color, alpha: float, rotation: float = 0.0) -> void:
	for i in range(6):
		var dir := Vector2.from_angle(rotation+i*TAU/6.0)
		canvas.draw_line(c, c+dir*r, _a(color, alpha), maxf(1.2, r*0.14), true)
		var tip := c+dir*r*0.6
		canvas.draw_line(tip, tip+dir.rotated(0.7)*r*0.32, _a(color, alpha), maxf(1.0, r*0.1), true)
		canvas.draw_line(tip, tip+dir.rotated(-0.7)*r*0.32, _a(color, alpha), maxf(1.0, r*0.1), true)
	canvas.draw_circle(c, r*0.16, _a(Color.WHITE, alpha), true, -1, true)


static func leaf_shape(canvas: CanvasItem, c: Vector2, angle: float, length: float, color: Color, alpha: float) -> void:
	var dir := Vector2.from_angle(angle)
	polygon(canvas, teardrop(c, dir, length, length*0.32), _a(color, alpha), 1.0)
	canvas.draw_line(c, c+dir*length*0.85, _a(color.darkened(0.35), alpha), 1.0, true)


static func butterfly(canvas: CanvasItem, c: Vector2, s: float, flap: float, pal: Array, alpha: float) -> void:
	var open: float = 0.45+0.55*absf(sin(flap))
	for side in [-1.0, 1.0]:
		polygon(canvas, PackedVector2Array([c, c+Vector2(side*11*open, -10)*s, c+Vector2(side*14*open, -2)*s, c+Vector2(side*8*open, 3)*s]), _a(pal[1], alpha), 1.0)
		polygon(canvas, PackedVector2Array([c, c+Vector2(side*9*open, 4)*s, c+Vector2(side*7*open, 10)*s, c+Vector2(side*2*open, 6)*s]), _a(pal[2], alpha), 1.0)
	canvas.draw_line(c+Vector2(0,-5)*s, c+Vector2(0,7)*s, _a(INK, alpha), 1.6*s, true)


static func hex(c: Vector2, r: float, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6): points.append(c+Vector2.from_angle(rotation+i*TAU/6.0+PI/6.0)*r)
	return points


static func crescent(canvas: CanvasItem, c: Vector2, r: float, angle: float, color: Color, alpha: float) -> void:
	var points := PackedVector2Array()
	for i in range(13): points.append(c+Vector2.from_angle(angle-1.2+i*2.4/12.0)*r)
	for i in range(12, -1, -1): points.append(c+Vector2.from_angle(angle-0.9+i*1.8/12.0)*r*0.62+Vector2.from_angle(angle)*r*0.18)
	polygon(canvas, points, _a(color, alpha), 1.2)


static func burst_particles(canvas: CanvasItem, c: Vector2, count: int, radius: float, progress: float, color: Color, alpha: float, seed: float = 0.0) -> void:
	for i in range(count):
		var a: float = i*TAU/count+seed+sin(i*2.3)*0.3
		var d: float = radius*(0.25+progress*(0.75+0.25*sin(i*1.7)))
		var p: Vector2 = c+Vector2.from_angle(a)*d+Vector2(0, progress*progress*18)
		canvas.draw_circle(p, maxf(0.8, (1.0-progress)*3.4), _a(color, alpha), true, -1, true)


# ---------------------------------------------------------------- plant overlays

static func draw_plant(canvas: CanvasItem, id: String, center: Vector2, scale: float, flash: float, alpha: float, plant: Dictionary = {}) -> void:
	var texture: Texture2D = texture_for(id)
	if texture == null: return
	var brightness: float = 1+clampf(flash*3,0,0.8)
	canvas.draw_texture_rect(texture,Rect2(center+Vector2(-48,-60)*scale,Vector2(96,112)*scale),false,Color(brightness,brightness,brightness,alpha))
	if plant.is_empty(): return
	var t: Array = plant.get("stats",{}).get("fusion_traits",[])
	var time: float = float(canvas.get("level_time"))
	var phase: float = float(plant.get("anim_phase",0))
	# Idle effects follow the hybrid's leading elements and rise from its crest.
	var layout: Dictionary = Art.layout(id,Defs.PLANTS[id])
	var crest: Vector2 = center+Vector2(layout.crown)*scale
	var head: Vector2 = center+Vector2(layout.head)*scale
	var span: float = maxf(14.0,(float(layout.right)-float(layout.left))*0.5)*scale
	var shown := 0
	for element in layout.elements:
		if shown >= 2: break
		if _idle(canvas,String(element),crest,head,span,scale,time,phase+shown*0.37,alpha): shown += 1
	for channel in plant.get("stats",{}).get("fusion_channels",[]):
		if channel.style != "burst" and float(channel.interval) < 10: continue
		var charge: float = clampf(1-float(plant.get("fusion_channel_timers",{}).get(channel.source,channel.interval))/float(channel.interval),0,1)
		var dial: Vector2 = center+Art.charge_anchor(id,Defs.PLANTS[id])*scale
		var pal: Array = palette(channel.get("traits",[]))
		canvas.draw_circle(dial,7.5*scale,_a(INK,alpha*0.85),true,-1,true)
		canvas.draw_circle(dial,6*scale,_a(pal[0].darkened(0.4),alpha*0.9),true,-1,true)
		canvas.draw_arc(dial,4.6*scale,-PI/2,-PI/2+TAU*maxf(0.01,charge),24,_a(pal[1],alpha),2.4*scale,true)
		canvas.draw_circle(dial,2.2*scale*(0.6+charge*0.4),_a(pal[2],alpha*(0.4+charge*0.6)),true,-1,true)
		if charge > 0.98:
			var pulse: float = 0.5+0.5*sin(time*6+phase)
			glow(canvas,dial,(10+pulse*3)*scale,pal[1],alpha*0.7,false)
		break
	if "reflect" in t:
		var plate: Vector2 = center+Vector2(33,-24)*scale
		var shine: float = 0.4+0.3*sin(time*3+phase)
		canvas.draw_line(plate+Vector2(-4,-8)*scale,plate+Vector2(4,8)*scale,Color(0.88,1,1,alpha*shine),1.6*scale,true)


static func _idle(canvas: CanvasItem, element: String, crest: Vector2, head: Vector2, span: float, scale: float, time: float, phase: float, alpha: float) -> bool:
	match element:
		"fire":
			for i in range(3):
				var rise: float = fposmod(time*0.9+i*0.31+phase,1.0)
				var p: Vector2 = crest+Vector2((-0.6+i*0.6)*span*0.6+sin(time*5+i*2)*2*scale,-4*scale-rise*30*scale)
				canvas.draw_circle(p,(1.9-rise*1.3)*scale,_a(PALETTES.fire[1 if i%2 else 2],alpha*(1.0-rise)),true,-1,true)
			glow(canvas,crest+Vector2(0,2)*scale,(9+2*sin(time*7+phase))*scale,PALETTES.fire[1],alpha*0.35)
		"frost":
			for i in range(2):
				var drift: float = fposmod(time*0.35+i*0.5+phase,1.0)
				snowflake(canvas,head+Vector2((i*2-1)*span*0.9+sin(time+i)*3*scale,-12*scale+drift*30*scale),2.8*scale,PALETTES.frost[2],alpha*(1.0-drift)*0.85,time*(1+i))
		"shock":
			if fposmod(time*1.4+phase,1.6) < 0.22:
				var a: Vector2 = crest+Vector2(-span*0.5,2*scale)
				bolt(canvas,a,a+Vector2(span,10*scale),PALETTES.shock[1],1.3*scale,time*10,alpha*0.9)
			sparkle(canvas,crest+Vector2(span*0.6,-2*scale),2.2*scale*(0.6+0.4*sin(time*9+phase)),PALETTES.shock[2],alpha*0.8)
		"poison":
			for i in range(3):
				var rise: float = fposmod(time*0.45+i*0.33+phase,1.0)
				var p: Vector2 = crest+Vector2((i-1)*span*0.45+sin(time*2+i)*2*scale,-rise*26*scale)
				canvas.draw_arc(p,(1.2+rise*1.8)*scale,0,TAU,12,_a(PALETTES.poison[1],alpha*(1.0-rise)),1.0*scale,true)
		"dream":
			var orbit: float = time*1.3+phase*TAU
			butterfly(canvas,head+Vector2(cos(orbit)*span*1.15,-10*scale+sin(orbit*1.7)*6*scale),0.8*scale,sin(time*12)*0.5+0.5,PALETTES.hypno,alpha*0.9)
		"shadow":
			for i in range(2):
				var rise: float = fposmod(time*0.4+i*0.5+phase,1.0)
				var p: Vector2 = crest+Vector2((i*2-1)*span*0.4+sin(time*1.5+i*3)*4*scale,-rise*28*scale)
				crescent(canvas,p,(2.6-rise)*scale,time+i,Color("8e7bc4"),alpha*(1.0-rise)*0.8)
		"blast":
			var flick: float = 0.5+0.5*sin(time*14+phase*9)
			star(canvas,crest+Vector2(span*0.5,-6*scale),(2.2+flick*1.6)*scale,_a(Color("ffd76a"),alpha),time*3,0.0)
			if flick > 0.8: sparkle(canvas,crest+Vector2(span*0.5+4*scale,-10*scale),2*scale,Color("fff6d0"),alpha)
		"sun":
			for i in range(3):
				var rise: float = fposmod(time*0.5+i*0.33+phase,1.0)
				var p: Vector2 = head+Vector2((i-1)*span*0.7+sin(time*2+i)*3*scale,-8*scale-rise*30*scale)
				canvas.draw_circle(p,(1.6-rise)*scale+0.4,_a(PALETTES.sun[2],alpha*(1.0-rise)*0.9),true,-1,true)
		"water":
			var fall: float = fposmod(time*0.6+phase,1.0)
			canvas.draw_colored_polygon(teardrop(head+Vector2(span*0.8,fall*24*scale),Vector2.DOWN,4*scale,2.2*scale),_a(Color("9fdcf2"),alpha*(1.0-fall)))
		"wind":
			var swirl: float = time*2.2+phase*TAU
			leaf_shape(canvas,head+Vector2(cos(swirl)*span*1.2,sin(swirl)*8*scale-6*scale),swirl,6*scale,PALETTES.wind[1],alpha*0.85)
		"light","holy":
			for i in range(2):
				var twinkle: float = 0.5+0.5*sin(time*4+i*2.1+phase*5)
				sparkle(canvas,crest+Vector2((i*2-1)*span*0.7,-4*scale-i*6*scale),(1.4+twinkle*1.6)*scale,PALETTES.sun[2],alpha*twinkle)
		"heal":
			var rise: float = fposmod(time*0.5+phase,1.0)
			var p: Vector2 = head+Vector2(-span*0.8,-rise*24*scale)
			canvas.draw_rect(Rect2(p-Vector2(0.8,2.4)*scale,Vector2(1.6,4.8)*scale),_a(PALETTES.heal[1],alpha*(1-rise)))
			canvas.draw_rect(Rect2(p-Vector2(2.4,0.8)*scale,Vector2(4.8,1.6)*scale),_a(PALETTES.heal[1],alpha*(1-rise)))
		"tea","milk","smoke":
			for i in range(2):
				var rise: float = fposmod(time*0.4+i*0.5+phase,1.0)
				var p: Vector2 = crest+Vector2((i*2-1)*4*scale+sin(time*3+i)*2*scale,-2*scale-rise*22*scale)
				canvas.draw_circle(p,(1.6+rise*2.2)*scale,Color(1,1,1,alpha*(1.0-rise)*0.45),true,-1,true)
		"metal":
			if fposmod(time*0.8+phase,1.2) < 0.4:
				ring(canvas,crest,10*scale,1.2*scale,PALETTES.magnet[1],alpha*0.6,PI,PI)
		_:
			return false
	return true


# ---------------------------------------------------------------- one-shot effects

static func draw_effect(canvas: CanvasItem, effect: Dictionary) -> void:
	var progress: float = clampf(1-float(effect.time)/maxf(float(effect.duration),0.01),0,1)
	var fade: float = 1.0-progress
	var c: Vector2 = effect.position
	var radius: float = float(effect.radius)
	var traits: Array = effect.get("traits",[])
	var pal: Array = palette(traits)
	var shape: String = effect.shape
	match shape:
		"fusion_blast": _draw_blast(canvas,effect,progress)
		"fusion_skill": draw_skill(canvas,effect,progress,pal[1])
		"fusion_beam":
			var target: Vector2 = effect.get("target",Vector2.INF)
			if target.is_finite(): _beam(canvas,c,target,10.0*fade+3,pal,fade)
		"fusion_muzzle":
			for i in range(5):
				var dir := Vector2.from_angle((i-2)*0.35)
				polygon(canvas,teardrop(c+Vector2(18,0),dir,radius*(0.4+progress*0.5),5*fade+1),_a(pal[1],fade))
			glow(canvas,c+Vector2(18,0),12*fade+4,pal[2],fade)
		"fusion_bloom":
			# Grafting bloom: petals unfurl from the joint, then lift away as motes.
			var petals: int = 8+int(effect.get("tier",1))*2
			for i in range(petals):
				var a: float = i*TAU/petals+progress*1.4
				var tip: Vector2 = c+Vector2.from_angle(a)*radius*(0.25+progress*0.7)
				polygon(canvas,teardrop(c+Vector2.from_angle(a)*radius*0.15*progress,Vector2.from_angle(a),radius*0.42*(1.0-progress*0.4),radius*0.14),_a(PALETTES.leaf[2] if i%2 else pal[1],fade*0.85),1.0)
				sparkle(canvas,tip,3+3*fade,pal[2],fade)
			ring(canvas,c,radius*(0.3+progress*0.8),2.2*fade+0.6,pal[1],fade)
			glow(canvas,c,radius*0.5*fade+6,pal[2],fade*0.8)
		"fusion_guard":
			var shell := hex(c,radius*(0.55+progress*0.25),progress*0.4)
			polygon(canvas,shell,_a(PALETTES.shield[1],fade*0.16))
			shell.append(shell[0])
			canvas.draw_polyline(shell,_a(PALETTES.shield[1],fade),2.4,true)
			for i in range(6):
				sparkle(canvas,shell[i],3*fade+1,PALETTES.shield[2],fade)
		"fusion_magnet":
			for i in range(3):
				canvas.draw_arc(c,radius*(0.3+i*0.22)*(1.0-progress*0.3),-PI*0.85,-PI*0.15,20,_a(PALETTES.magnet[1],fade*(1.0-i*0.25)),3.0-i*0.6,true)
			burst_particles(canvas,c,10,radius*(1.0-progress),0.3,PALETTES.magnet[2],fade,progress*4)
		_:
			# Impacts and waves: a soft flash, a bright ring and element motes.
			glow(canvas,c,radius*(0.35+progress*0.3),pal[1],fade*0.7)
			ring(canvas,c,radius*(0.3+progress*0.7),2.6*fade+0.6,pal[1],fade)
			burst_particles(canvas,c,10,radius,progress,pal[2],fade,float(c.x)*0.01)
			if "frost" in traits:
				for i in range(4): snowflake(canvas,c+Vector2.from_angle(i*TAU/4+progress)*radius*0.6*progress,5*fade+1,PALETTES.frost[2],fade)


static func _beam(canvas: CanvasItem, a: Vector2, b: Vector2, width: float, pal: Array, alpha: float) -> void:
	canvas.draw_line(a,b,_a(pal[0],alpha*0.25),width*3.2,true)
	canvas.draw_line(a,b,_a(pal[1],alpha*0.8),width*1.6,true)
	canvas.draw_line(a,b,_a(pal[2],alpha),width*0.7,true)
	canvas.draw_line(a,b,_a(Color.WHITE,alpha),maxf(1.0,width*0.25),true)
	glow(canvas,a,width*2.2,pal[1],alpha)
	glow(canvas,b,width*2.8,pal[2],alpha)
	if canvas.get("glow_primitives") != null:
		canvas.glow_primitives.append({"type":"line","from":a,"to":b,"width":width*1.4,"color":_a(pal[1],alpha*0.35)})


static func _fireball(canvas: CanvasItem, c: Vector2, r: float, progress: float, pal: Array, seed: float) -> void:
	var fade: float = 1.0-progress
	var grow: float = r*(0.45+0.55*sqrt(progress))
	canvas.draw_circle(c,grow,_a(pal[0],fade*0.55),true,-1,true)
	canvas.draw_circle(c,grow*0.78,_a(pal[1],fade*0.75),true,-1,true)
	canvas.draw_circle(c,grow*0.48*(1.0-progress*0.5),_a(pal[2],fade),true,-1,true)
	for i in range(9):
		var a: float = i*TAU/9+seed
		flame(canvas,c+Vector2.from_angle(a)*grow*0.55,Vector2.from_angle(a),grow*(0.55+0.2*sin(i*2.1+seed)),grow*0.22,fade,pal)
	ring(canvas,c,r*(0.4+progress*0.9),4*fade+1,pal[1],fade*0.9)
	# Smoke puffs drift up as the blast settles.
	for i in range(5):
		var p: Vector2 = c+Vector2(sin(i*2.4)*r*0.6,-progress*r*0.7-i*4)
		canvas.draw_circle(p,r*0.18*(0.6+progress),Color(0.35,0.32,0.3,0.25*progress*fade),true,-1,true)
	if canvas.get("glow_primitives") != null:
		canvas.glow_primitives.append({"pos":c,"radius":grow*0.7,"color":_a(pal[1],fade*0.4)})


static func _draw_blast(canvas: CanvasItem, effect: Dictionary, progress: float) -> void:
	var c: Vector2 = effect.position
	var fade: float = 1.0-progress
	var radius: float = float(effect.radius)
	var traits: Array = effect.get("traits",[])
	var shape: String = String(effect.get("blast_shape","circle"))
	var pal: Array = PALETTES.fire if not "frost" in traits else [Color("6f5ab8"),Color("b7a0de"),Color("f1e9ff")]
	match shape:
		"row":
			var start: Vector2 = effect.get("from",c-Vector2(300,0)); var end: Vector2 = effect.get("to",c+Vector2(450,0))
			canvas.draw_line(start,end,_a(pal[0],fade*0.3),40*fade+8,true)
			for i in range(24):
				var base: Vector2 = start.lerp(end,i/23.0)+Vector2(0,14)
				var h: float = (30+16*sin(i*1.9+progress*14))*(0.4+fade*0.8)
				flame(canvas,base,Vector2(sin(i+progress*9)*0.15,-1).normalized(),h,10,fade,pal)
		"freeze":
			for i in range(10):
				var a: float = i*TAU/10+progress
				var p: Vector2 = c+Vector2.from_angle(a)*minf(radius,240)*(0.2+progress*0.7)
				snowflake(canvas,p,8*fade+3,PALETTES.frost[2],fade,progress*2)
			ring(canvas,c,minf(radius,240)*(0.3+progress*0.7),3*fade+1,PALETTES.frost[1],fade)
			glow(canvas,c,60*fade+10,PALETTES.frost[2],fade)
		"sleep":
			for i in range(8):
				var p: Vector2 = c+Vector2.from_angle(i*TAU/8)*radius*0.6*progress+Vector2(0,-progress*24)
				butterfly(canvas,p,0.8,progress*20+i,PALETTES.hypno,fade)
			ring(canvas,c,radius*(0.3+progress*0.6),2*fade+0.5,PALETTES.hypno[1],fade)
		"snare":
			for i in range(7):
				var dir := Vector2.from_angle(i*TAU/7)
				var points := PackedVector2Array([c,c+dir*radius*0.3*progress+dir.orthogonal()*10,c+dir*radius*0.65*progress-dir.orthogonal()*8,c+dir*radius*progress])
				canvas.draw_polyline(points,_a(INK,fade),7,true)
				canvas.draw_polyline(points,_a(Color("8cb879"),fade),4.5,true)
				leaf_shape(canvas,points[2],dir.angle()-0.6,10,PALETTES.leaf[1],fade)
		"pull":
			for i in range(5):
				var points := PackedVector2Array()
				for n in range(26):
					var a: float = n/25.0*TAU*1.2+progress*8+i*1.3
					points.append(c+Vector2(cos(a),sin(a)*0.5)*radius*(1.0-n/25.0)*(0.6+i*0.1))
				canvas.draw_polyline(points,_a(PALETTES.wind[1],fade*0.8),2.4,true)
		"magma":
			for i in range(8):
				var p: Vector2 = c+Vector2.from_angle(i*TAU/8+0.3)*radius*0.55*sqrt(progress)
				canvas.draw_circle(p,9*fade+3,_a(PALETTES.fire[0],fade*0.8),true,-1,true)
				canvas.draw_circle(p-Vector2(1,2),5*fade+2,_a(PALETTES.fire[2],fade),true,-1,true)
			_fireball(canvas,c,minf(radius,180)*0.6,progress,PALETTES.fire,1.0)
		"single":
			star(canvas,c,26*fade+8,_a(pal[2],fade),progress*2,1.4)
			ring(canvas,c,30*(0.4+progress),3*fade+1,pal[1],fade)
		"revive":
			for i in range(4):
				ring(canvas,c,radius*fposmod(progress+i*0.25,1.0)*0.6,2.0,Color("b48cff"),fade*0.8)
		"milk":
			ring(canvas,c,40*(0.4+progress),3*fade+1,Color("fff8e6"),fade)
		_:
			_fireball(canvas,c,minf(240,radius),progress,pal,float(c.x)*0.01)


static func draw_projectile(canvas: CanvasItem, projectile: Dictionary) -> void:
	var c: Vector2 = projectile.position
	var r: float = float(projectile.get("radius",8))
	var traits: Array = projectile.get("fusion_traits",[])
	var pal: Array = palette(traits)
	var dir: float = signf(float(projectile.get("speed",1)))
	if dir == 0: dir = 1
	var time: float = float(canvas.get("level_time"))
	if projectile.has("fusion_blast"):
		# Burst chambers lob a seed bomb with a lit fuse and a landing marker.
		var b: Dictionary = projectile.fusion_blast
		var bomb: Color = Color("8f7bc4") if b.source == "doom_shroom" else Color("e9774a")
		canvas.draw_circle(c+Vector2(2,3),r+1,Color(0,0,0,0.18),true,-1,true)
		canvas.draw_circle(c,r+1.6,INK,true,-1,true)
		canvas.draw_circle(c,r,bomb,true,-1,true)
		canvas.draw_circle(c-Vector2(r*0.3,r*0.35),r*0.4,_a(Color.WHITE,0.55),true,-1,true)
		canvas.draw_line(c+Vector2(-2,-r),c+Vector2(2,-r-7),Color("8a6a3e"),2,true)
		glow(canvas,c+Vector2(3,-r-8),4+sin(time*20)*1.5,PALETTES.fire[2],0.9)
		if float(projectile.get("arc_time",0))/maxf(0.01,float(projectile.get("arc_duration",1))) > 0.5:
			var target: Vector2 = projectile.get("arc_target",c)
			ring(canvas,target,minf(230,float(b.radius))*0.5,1.4,bomb,0.4,time*2,TAU*0.8)
		return
	# Seed orb with an element trail that streams behind it.
	for i in range(4):
		var t: float = (i+1)/4.0
		canvas.draw_circle(c-Vector2(dir*r*1.6*t*2,sin(time*16+i)*1.5),r*(1.0-t*0.6),_a(pal[1],0.35*(1.0-t)),true,-1,true)
	if "fire" in traits:
		flame(canvas,c,Vector2(-dir,0),r*3.4,r*0.9,0.9,PALETTES.fire)
	if String(projectile.get("kind","")) == "boomerang":
		var angle: float = time*12+c.x*0.02
		crescent(canvas,c,r*1.4,angle,pal[1],1.0)
		return
	canvas.draw_circle(c,r+1.4,INK,true,-1,true)
	canvas.draw_circle(c,r,pal[1],true,-1,true)
	canvas.draw_circle(c+Vector2(r*0.2,r*0.25),r*0.55,_a(pal[0],0.5),true,-1,true)
	canvas.draw_circle(c-Vector2(r*0.32,r*0.32),r*0.32,_a(pal[2],0.95),true,-1,true)
	if "frost" in traits: snowflake(canvas,c,r*0.9,Color.WHITE,0.85,time*4)
	if "shock" in traits and fposmod(time*8,1.0) < 0.5: bolt(canvas,c,c+Vector2(-dir*r*2.2,-r),PALETTES.shock[1],1.0,time*30,0.9)
	if "poison" in traits:
		for i in range(3): canvas.draw_circle(c+Vector2.from_angle(time*3+i*2.1)*r*1.5,1.8,PALETTES.poison[1],true,-1,true)


# ---------------------------------------------------------------- ultimates

static func draw_skill(canvas: CanvasItem, effect: Dictionary, progress: float, tint: Color) -> void:
	var skill: String = effect.skill
	var origin: Vector2 = effect.position
	var target: Vector2 = effect.get("target",Vector2.INF)
	var c: Vector2 = target if target.is_finite() and skill in ["minefield","steam","miasma","devour","roots"] else origin
	var r: float = 35+progress*float(effect.radius)*0.65
	var fade: float = 1-progress
	var traits: Array = effect.get("traits",[])
	var pal: Array = palette(traits)
	var time: float = float(canvas.get("level_time"))
	match skill:
		"reflection":
			for i in range(6):
				var plate: Vector2 = c+Vector2.from_angle(i*TAU/6+progress*0.8)*r*0.75
				var shard := PackedVector2Array([plate+Vector2(0,-14),plate+Vector2(9,-3),plate+Vector2(4,14),plate+Vector2(-9,4)])
				polygon(canvas,shard,Color(0.78,0.96,1.0,fade*0.7),1.2)
				canvas.draw_line(plate+Vector2(-2,-8),plate+Vector2(3,6),_a(Color.WHITE,fade),1.6,true)
			ring(canvas,c,r,2,PALETTES.frost[1],fade*0.7)
		"laser","rail_storm","sun_lance","beacon":
			var end: Vector2 = target if target.is_finite() else c+Vector2(300,0)
			var beam_pal: Array = PALETTES.sun if skill in ["sun_lance","beacon"] else (PALETTES.shock if skill == "rail_storm" else pal)
			_beam(canvas,c,end,16*fade+4,beam_pal,fade)
			for i in range(6):
				var point: Vector2 = c.lerp(end,fposmod(progress*1.5+i/6.0,1.0))
				if skill == "rail_storm": ring(canvas,point,10,1.6,beam_pal[1],fade)
				else: sparkle(canvas,point,6*fade+2,beam_pal[2],fade)
		"inferno":
			for i in range(14):
				var a: float = i*TAU/14+progress*1.5
				flame(canvas,c+Vector2.from_angle(a)*r*0.35,Vector2.from_angle(a),r*(0.55+0.15*sin(i*2+progress*12)),r*0.16,fade,PALETTES.fire)
			glow(canvas,c,r*0.6,PALETTES.fire[2],fade)
		"steam":
			_fireball(canvas,c,r*0.7,progress,PALETTES.fire,1.3)
			for i in range(9):
				var p: Vector2 = c+Vector2.from_angle(i*TAU/9+progress)*r*0.8+Vector2(0,-progress*30)
				canvas.draw_circle(p,10+progress*14,Color(0.92,0.98,1.0,0.45*fade),true,-1,true)
				snowflake(canvas,p,5*fade+1,PALETTES.frost[2],fade)
		"blizzard":
			for i in range(12):
				var p: Vector2 = c+Vector2.from_angle(i*TAU/12+progress*0.8)*r*(0.4+0.5*(i%2))
				snowflake(canvas,p,9*fade+4,PALETTES.frost[2],fade,progress*3)
			ring(canvas,c,r,3,PALETTES.frost[1],fade)
			glow(canvas,c,r*0.5,PALETTES.frost[2],fade*0.6)
		"constellation":
			var stars := PackedVector2Array()
			for i in range(5):
				var point: Vector2 = c+Vector2.from_angle(i*TAU/5-PI/2+progress*0.6)*r
				stars.append(point)
			for i in range(5): canvas.draw_line(stars[i],stars[(i+2)%5],_a(PALETTES.sun[2],fade*0.6),2,true)
			for point in stars:
				glow(canvas,point,14*fade+4,PALETTES.sun[1],fade)
				star(canvas,point,12*fade+4,_a(PALETTES.sun[1],fade),progress*2)
		"lightning":
			for i in range(6):
				var end: Vector2 = target if target.is_finite() and i == 0 else c+Vector2.from_angle(i*TAU/6+0.4)*r
				bolt(canvas,c,end,PALETTES.shock[1],2.6*fade+0.8,i+progress*40,fade)
				glow(canvas,end,10*fade+3,PALETTES.shock[2],fade)
		"domain":
			canvas.draw_circle(c,r,Color(0.56,0.5,0.86,0.12*fade),true,-1,true)
			ring(canvas,c,r,2.4,Color("c9b6f2"),fade,progress*2)
			ring(canvas,c,r*0.72,1.6,Color("e9dcff"),fade,-progress*3)
			for i in range(12):
				var rune: Vector2 = c+Vector2.from_angle(i*TAU/12+progress*2)*r*0.86
				star(canvas,rune,4*fade+1.5,Color(0.94,0.9,1.0,fade),progress*4,0.6)
		"bowling":
			for i in range(5):
				var point: Vector2 = c+Vector2(progress*190-60,(i-2)*26)
				canvas.draw_line(point-Vector2(46,0),point,_a(PALETTES.leaf[1],fade*0.4),6,true)
				canvas.draw_circle(point,12,_a(Color("c58a4a"),fade),true,-1,true)
				canvas.draw_arc(point,12,0,TAU,24,_a(INK,fade),1.6,true)
				canvas.draw_arc(point,7,progress*14,progress*14+PI,12,_a(Color("f2d48a"),fade),2,true)
		"blades","needles","barrage":
			for i in range(10):
				var a: float = i*TAU/10+progress*(5 if skill == "blades" else 2)
				var p: Vector2 = c+Vector2.from_angle(a)*r*(0.45+(i%2)*0.35)
				if skill == "needles": polygon(canvas,teardrop(p,Vector2.from_angle(a),14,3),_a(Color("e7daa0"),fade),1.0)
				elif skill == "barrage": polygon(canvas,teardrop(p,Vector2(1,0),16,4),_a(pal[1],fade),1.0); canvas.draw_circle(p+Vector2(14,0),4,_a(pal[2],fade),true,-1,true)
				else:
					canvas.draw_arc(c,p.distance_to(c),a-0.5,a,10,_a(pal[1],fade*0.35),5,true)
					crescent(canvas,p,16,a+PI*0.5,_a(PALETTES.leaf[2],1.0),fade)
		"tornado","vortex":
			for i in range(5):
				var points := PackedVector2Array()
				for n in range(28):
					var a: float = n/27.0*PI*2.2+progress*9+i*1.2
					var h: float = n/27.0
					points.append(c+Vector2(cos(a)*r*(0.15+h*0.5),-h*r*0.9+sin(a)*6))
				canvas.draw_polyline(points,_a(PALETTES.wind[1] if i%2 else Color.WHITE,fade*0.75),3.0-i*0.3,true)
			for i in range(6):
				leaf_shape(canvas,c+Vector2.from_angle(progress*12+i)*r*0.5+Vector2(0,-i*8),progress*14+i,9,PALETTES.leaf[1],fade)
		"magnetic":
			for i in range(3):
				canvas.draw_arc(c,r*(0.4+i*0.2),-PI*0.9,-PI*0.1,24,_a(PALETTES.magnet[1],fade*(1-i*0.2)),3.2-i*0.5,true)
			for i in range(8):
				var p: Vector2 = c+Vector2.from_angle(i*TAU/8+progress*3)*r*(1.0-progress*0.6)
				polygon(canvas,PackedVector2Array([p,p+Vector2(6,2),p+Vector2(3,7)]),_a(Color("c9d2d8"),fade),0.8)
		"dream","spirits":
			for i in range(8):
				var p: Vector2 = c+Vector2.from_angle(i*TAU/8+progress*1.6)*r+Vector2(0,-progress*18)
				if skill == "dream": butterfly(canvas,p,1.0,time*12+i,PALETTES.hypno,fade)
				else:
					polygon(canvas,teardrop(p,Vector2(0,1),18,8),Color(0.88,0.92,1.0,0.7*fade),1.0)
					canvas.draw_circle(p+Vector2(-3,4),1.6,_a(INK,fade),true,-1,true); canvas.draw_circle(p+Vector2(3,4),1.6,_a(INK,fade),true,-1,true)
		"miasma":
			for i in range(10):
				var p: Vector2 = c+Vector2.from_angle(i*TAU/10)*r*(0.3+0.6*fposmod(progress+i*0.1,1.0))
				canvas.draw_circle(p,6+i%3*3,_a(PALETTES.poison[1],fade*0.55),true,-1,true)
				canvas.draw_arc(p,6+i%3*3,-2.4,-0.6,10,_a(PALETTES.poison[2],fade),1.4,true)
			glow(canvas,c,r*0.6,Color("9fd05a"),fade*0.5)
		"bastion","garden","renewal","awakening","spring":
			var tone: Array = PALETTES.shield if skill == "bastion" else (PALETTES.frost if skill == "spring" else (PALETTES.sun if skill == "awakening" else PALETTES.heal))
			var dome := hex(c,r*0.85,progress*0.3)
			polygon(canvas,dome,_a(tone[1],fade*0.14))
			dome.append(dome[0]); canvas.draw_polyline(dome,_a(tone[1],fade),2.6,true)
			for i in range(8):
				var rise: float = fposmod(progress*1.4+i*0.125,1.0)
				var p: Vector2 = c+Vector2(sin(i*2.4)*r*0.6,r*0.3-rise*r)
				if skill in ["garden","renewal"]:
					canvas.draw_line(p-Vector2(5,0),p+Vector2(5,0),_a(tone[2],fade),2.4,true); canvas.draw_line(p-Vector2(0,5),p+Vector2(0,5),_a(tone[2],fade),2.4,true)
				else: sparkle(canvas,p,5,tone[2],fade)
		"minefield","meteor","purge":
			if skill == "meteor":
				var drop: Vector2 = c+Vector2(60,-140)*(1.0-minf(1.0,progress*2.2))
				polygon(canvas,teardrop(drop,Vector2(0.4,1).normalized()*-1,40,10),_a(PALETTES.fire[1],fade*0.7))
				canvas.draw_circle(drop,9,_a(Color("e9a85d"),fade),true,-1,true)
			if skill == "purge":
				glow(canvas,c,r*0.7,PALETTES.sun[2],fade)
				for i in range(8):
					var dir := Vector2.from_angle(i*TAU/8)
					canvas.draw_line(c+dir*r*0.2,c+dir*r*(0.5+progress*0.5),_a(PALETTES.sun[2],fade),4*fade+1,true)
			else: _fireball(canvas,c,r*0.75,progress,PALETTES.fire,float(c.x)*0.02)
		"roots","devour":
			if skill == "devour":
				# A chomping jaw snaps shut on the target, then releases a burst of leaves.
				var open: float = 1.0-absf(sin(minf(1.0,progress*1.6)*PI))
				for side in [-1.0,1.0]:
					var jaw := PackedVector2Array()
					for i in range(13):
						var a: float = PI*(0.05+i*0.9/12.0)
						jaw.append(c+Vector2(-cos(a)*r*0.55,side*(6+sin(a)*r*0.42)*(0.25+open*0.75)))
					polygon(canvas,jaw,_a(Color("9b6fc4"),fade),1.8)
					for k in range(4):
						var tooth: Vector2 = c+Vector2(-r*0.42+k*r*0.26,side*6*(0.25+open*0.75))
						polygon(canvas,PackedVector2Array([tooth+Vector2(-4,0),tooth+Vector2(4,0),tooth+Vector2(0,-side*8)]),_a(Color("fff0d7"),fade),0.8)
				burst_particles(canvas,c,8,r*0.8,progress,PALETTES.leaf[1],fade)
			else:
				for i in range(7):
					var dir := Vector2.from_angle(i*TAU/7)
					var points := PackedVector2Array([c,c+dir*r*0.35+dir.orthogonal()*12,c+dir*r*0.7-dir.orthogonal()*10,c+dir*r])
					canvas.draw_polyline(points,_a(INK,fade),8,true)
					canvas.draw_polyline(points,_a(Color("9b7a48"),fade),5,true)
					polygon(canvas,teardrop(points[3],dir,10,3),_a(Color("e7daa0"),fade),0.8)
		"tea_ceremony":
			for i in range(10):
				var a: float = i*TAU/10+progress*1.2
				var p: Vector2 = c+Vector2.from_angle(a)*r*0.7
				for k in range(5): polygon(canvas,teardrop(p,Vector2.from_angle(k*TAU/5),6,2.6),Color(1,1,0.96,fade),0.6)
				canvas.draw_circle(p,1.8,_a(Color("f5d36a"),fade),true,-1,true)
			ring(canvas,c,r,3,Color("e0b65a"),fade)
		"samsara":
			for i in range(4): ring(canvas,c,r*fposmod(progress+i*0.25,1.0),2.4,Color("b48cff"),fade)
			canvas.draw_circle(c,10,_a(Color("fffdf5"),fade),true,-1,true)
			canvas.draw_circle(c,6,_a(Color("9b74d6"),fade),true,-1,true)
			canvas.draw_arc(c,4,0,TAU,16,_a(Color("3d2563"),fade),1,true)
		_:
			# Solar and remaining skills: a sun disc with turning rays and rising light.
			glow(canvas,c,r*0.55,pal[2],fade)
			for i in range(12):
				var a: float = i*TAU/12+progress*1.4
				polygon(canvas,teardrop(c+Vector2.from_angle(a)*r*0.32,Vector2.from_angle(a),r*0.45,6),_a(pal[1],fade))
			canvas.draw_circle(c,r*0.3,_a(pal[1],fade),true,-1,true)
			canvas.draw_circle(c-Vector2(4,4),r*0.15,_a(pal[2],fade),true,-1,true)


# The native kernel/butter/petal/blade silhouette stays visible inside each payload.
static func draw_ammo_overlay(canvas: CanvasItem, shot: Dictionary) -> void:
	var tags: Array = shot.get("ammo_elements",[])
	if tags.is_empty(): return
	var p: Vector2 = shot.position
	var r: float = float(shot.get("radius",9))
	var time: float = float(canvas.get("level_time"))
	var dir: float = -1 if float(shot.get("speed",1)) < 0 else 1
	if "flame" in tags:
		for i in range(3):
			var phase: float = time*12+i*2.1
			var end: Vector2 = p-Vector2(dir*(r*3+i*3),sin(phase)*r)
			canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-r),end,p+Vector2(0,r),p-Vector2(dir*r,0)]),Color(1,0.32+i*0.17,0.06,0.4))
		canvas.draw_arc(p,r+3,-1.4,1.4,16,Color("ffd367"),2,true)
	if "frost" in tags:
		for i in range(6):
			var ray := Vector2.from_angle(i*TAU/6+time)*r
			canvas.draw_line(p+ray*0.8,p+ray*1.55,Color("b8f8ff"),2,true)
	if "venom" in tags:
		for i in range(4):
			var offset := Vector2.from_angle(i*TAU/4-time)*r*1.4
			canvas.draw_circle(p+offset,2.5,Color("c8eb53"),true,-1,true)
	if "storm" in tags:
		canvas.draw_polyline(PackedVector2Array([p+Vector2(-r*2,0),p+Vector2(-r,-r),p+Vector2(-r*0.5,r),p+Vector2(r*1.5,0)]),Color("bcb5ff"),2,true)
	if "dream" in tags: canvas.draw_arc(p,r+5,time,time+PI*1.5,18,Color("fca1f0"),2,true)
	if "root" in tags: canvas.draw_arc(p,r+3,-time,-time+PI,18,Color("85d580"),2,true)
	if "tea" in tags:
		for i in range(3):
			var petal := p+Vector2.from_angle(time*2+i*TAU/3)*(r+5)
			canvas.draw_circle(petal,2.8,Color("fff3d2"),true,-1,true)
		canvas.draw_arc(p,r+2,0,TAU,18,Color("caba67"),1.4,true)
	if "milk" in tags:
		var tail := p-Vector2(dir*(r*2.4),0)
		canvas.draw_line(tail,p,Color("fff2cb"),r*0.7,true)
		canvas.draw_circle(tail,3.0,Color("eac45c"),true,-1,true)

# Ingredient-shaped payloads remain readable beneath the elemental trail.
static func draw_ammo_body(canvas: CanvasItem, shot: Dictionary) -> bool:
	if shot.get("ammo_elements",[]).is_empty(): return false
	var kind: String = shot.get("kind","")
	var p: Vector2 = shot.position
	var r: float = float(shot.get("radius",8))
	var dark := Color("5b4936")
	if kind == "kernel":
		var body := PackedVector2Array([p+Vector2(-0.85,-0.55)*r,p+Vector2(-0.3,-0.95)*r,p+Vector2(0.75,-0.7)*r,p+Vector2(1,0.2)*r,p+Vector2(0.15,0.9)*r,p+Vector2(-0.75,0.65)*r])
		canvas.draw_colored_polygon(body,Color("f6c54e"))
		canvas.draw_polyline(PackedVector2Array([body[0],body[1],body[2],body[3],body[4],body[5],body[0]]),dark,1.4,true)
		canvas.draw_line(p+Vector2(-0.2,-0.55)*r,p+Vector2(-0.1,0.6)*r,Color("ffe990"),r*0.3,true)
		canvas.draw_circle(p+Vector2(0.38,-0.25)*r,r*0.18,Color("fff4b7"),true,-1,true)
	elif kind == "butter":
		canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-1,-0.45)*r,p+Vector2(0.62,-0.85)*r,p+Vector2(1,0.38)*r,p+Vector2(-0.75,0.85)*r]),Color("f6be45"))
		canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-1,-0.45)*r,p+Vector2(-0.7,-0.86)*r,p+Vector2(0.95,-0.55)*r,p+Vector2(0.62,-0.12)*r]),Color("fff4b1"))
		canvas.draw_line(p+Vector2(-0.62,0.16)*r,p+Vector2(0.55,0.32)*r,Color("ffe779"),r*0.35,true)
		canvas.draw_circle(p+Vector2(0.77,0.42)*r,r*0.2,Color("fff0a4"),true,-1,true)
	elif kind == "cabbage" or kind == "melon":
		canvas.draw_circle(p,r,Color("2b693a"),true,-1,true)
		for i in range(4):
			var a: float = float(i)*1.57+0.4
			canvas.draw_circle(p+Vector2.from_angle(a)*r*0.3,r*0.67,Color("84c350") if i%2 == 0 else Color("b0d45e"),true,-1,true)
			canvas.draw_arc(p+Vector2.from_angle(a)*r*0.22,r*0.63,a,a+PI,12,Color("387f43"),maxf(1,r*0.09),true)
		canvas.draw_circle(p-Vector2(r*0.15,r*0.15),r*0.24,Color("d1e995"),true,-1,true)
	elif kind == "sakura_petal" or kind == "sakura_shard":
		var petal := PackedVector2Array([p+Vector2(-1,0)*r,p+Vector2(-0.1,-0.8)*r,p+Vector2(0.62,-0.62)*r,p+Vector2(0.9,-0.2)*r,p+Vector2(0.6,0)*r,p+Vector2(0.9,0.2)*r,p+Vector2(0.62,0.62)*r,p+Vector2(-0.1,0.8)*r])
		canvas.draw_colored_polygon(petal,Color("fac7df"))
		canvas.draw_line(p-Vector2(r*0.75,0),p+Vector2(r*0.55,0),Color("d975a8"),maxf(1,r*0.1),true)
	elif kind == "prism_pea" or kind == "prism_fragment":
		var crystal := PackedVector2Array([p-Vector2(r,0),p+Vector2(0,-r*0.9),p+Vector2(r,0),p+Vector2(0,r*0.9)])
		canvas.draw_colored_polygon(crystal,Color("65c3d8"))
		canvas.draw_colored_polygon(PackedVector2Array([crystal[0],crystal[1],crystal[2],p]),Color("d3faf3"))
		canvas.draw_line(crystal[1],crystal[3],Color("ffffff"),maxf(1,r*0.08),true)
	elif kind == "moon_meteor":
		canvas.draw_circle(p,r,Color("e9a85d"),true,-1,true)
		canvas.draw_circle(p-Vector2(r*0.12,r*0.08),r*0.72,Color("fff0bf"),true,-1,true)
		canvas.draw_arc(p+Vector2(r*0.12,0),r*0.48,-1.1,1.5,14,Color("c18452"),maxf(1,r*0.2),true)
		canvas.draw_circle(p+Vector2(-r*0.27,-r*0.35),r*0.16,Color("ffffff"),true,-1,true)
	else: return false
	return true
