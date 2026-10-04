extends RefCounted
const Art = preload("res://scripts/ui/fusion_plant_art.gd")
const Defs = preload("res://scripts/game_defs.gd")
static var textures: Dictionary = {}
const MAX_TEXTURES := 256

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

static func color_for(traits: Array) -> Color:
	if "fire" in traits and "frost" in traits: return Color("e7a5b9")
	if "fire" in traits: return Color("f5ad52")
	if "frost" in traits: return Color("9ee4ef")
	if "hypno" in traits or "poison" in traits: return Color("d0a4e7")
	if "magnet" in traits or "shock" in traits: return Color("94cfdd")
	if "sun" in traits: return Color("f7d77c")
	return Color("9fd279")

static func draw_plant(canvas: CanvasItem, id: String, center: Vector2, scale: float, flash: float, alpha: float, plant: Dictionary = {}) -> void:
	var texture: Texture2D = texture_for(id)
	if texture == null: return
	var brightness: float = 1+clampf(flash*3,0,0.8)
	canvas.draw_texture_rect(texture,Rect2(center+Vector2(-48,-60)*scale,Vector2(96,112)*scale),false,Color(brightness,brightness,brightness,alpha))
	if plant.is_empty(): return
	var t: Array = plant.get("stats",{}).get("fusion_traits",[])
	var time: float = float(canvas.get("level_time"))
	var pulse: float = sin(time*3+float(plant.get("anim_phase",0)))
	# Idle particles reflect the material; no common orbit hides every silhouette.
	if "sun" in t:
		var glow := center+Vector2(-6,-26)*scale
		canvas.draw_circle(glow,(2+pulse*0.6)*scale,Color("ffe7a2",alpha*0.35),true,-1,true)
	elif "fire" in t:
		for i in range(2):
			var ember := center+Vector2(-23+i*10,-18-fposmod(time*9+i*13,28))*scale
			canvas.draw_circle(ember,1.2*scale,Color("fac17e",alpha*0.6),true,-1,true)

	for channel in plant.get("stats",{}).get("fusion_channels",[]):
		if channel.style != "burst" and float(channel.interval) < 10: continue
		var charge: float = clampf(1-float(plant.get("fusion_channel_timers",{}).get(channel.source,channel.interval))/float(channel.interval),0,1)
		var dial: Vector2 = center+Art.charge_anchor(id,Defs.PLANTS[id])*scale
		canvas.draw_circle(dial,7*scale,Color("374b40",alpha*0.8),true,-1,true)
		canvas.draw_arc(dial,6*scale,-PI/2,-PI/2+TAU*maxf(0.01,charge),24,Color("ffd6a0",alpha*0.9),2*scale,true)
		if charge > 0.9:
			canvas.draw_circle(dial,9*scale,Color("f8c776",alpha*(0.12+pulse*0.06)),true,-1,true)
		break
	if "reflect" in t:
		var plate: Vector2 = center+Vector2(33,-24)*scale
		canvas.draw_line(plate+Vector2(-4,-8)*scale,plate+Vector2(4,8)*scale,Color("e0fbff",alpha*(0.4+pulse*0.15)),1.5*scale,true)

static func draw_effect(canvas: CanvasItem, effect: Dictionary) -> void:
	var progress: float = clampf(1-float(effect.time)/maxf(float(effect.duration),0.01),0,1)
	var c: Vector2 = effect.position
	var radius: float = float(effect.radius)
	var color: Color = color_for(effect.get("traits",[])); color.a = (1-progress)*0.8
	var shape: String = effect.shape
	if shape == "fusion_blast":
		var hue: Color = Color("b7a0de") if "frost" in effect.get("traits",[]) else Color("fac088")
		hue.a = (1-progress)*0.65
		if effect.get("blast_shape","") == "row":
			var start: Vector2 = effect.get("from",c-Vector2(300,0)); var end: Vector2 = effect.get("to",c+Vector2(450,0))
			canvas.draw_line(start,end,Color(hue,hue.a*0.3),35*(1-progress)+8,true)
			for i in range(22):
				var ember: Vector2 = start.lerp(end,i/21.0)
				canvas.draw_colored_polygon(PackedVector2Array([ember+Vector2(-8,9),ember+Vector2(sin(i*2+progress*12)*8,-24-18*(1-progress)),ember+Vector2(9,9)]),hue)
		else:
			var wave: float = radius*sqrt(progress)
			canvas.draw_circle(c,wave,Color(hue,hue.a*0.13),true,-1,true)
			canvas.draw_arc(c,wave,0,TAU,64,hue,4*(1-progress)+1,true)
			canvas.draw_arc(c,wave*0.7,0,TAU,48,Color("fff1bc",hue.a*0.6),2,true)
			for i in range(14):
				var direction := Vector2.from_angle(i*TAU/14+0.2)
				canvas.draw_line(c+direction*wave*0.5,c+direction*(wave+12*(1-progress)),hue,3*(1-progress)+0.8,true)
		return
	if shape == "fusion_skill":
		draw_skill(canvas,effect,progress,color)
		return
	if shape == "fusion_beam" and Vector2(effect.get("target",Vector2.INF)).is_finite():
		var target: Vector2 = effect.target
		canvas.draw_line(c,target,Color(color,color.a*0.18),20*(1-progress)+4,true)
		canvas.draw_line(c,target,color,6*(1-progress)+1,true)
		canvas.draw_line(c,target,Color(1,1,0.92,color.a),2,true)
		for i in range(5):
			var pos: Vector2 = c.lerp(target,(i+progress)/5.0)
			canvas.draw_circle(pos,3.0,color,true,-1,true)
		return
	var r: float = radius*(0.24+progress*0.76)
	if shape == "fusion_muzzle":
		for i in range(5):
			var direction := Vector2.from_angle((i-2)*0.3)
			canvas.draw_line(c+Vector2(24,0)+direction*r*0.2,c+Vector2(24,0)+direction*r,color,2,true)
		return
	canvas.draw_circle(c,r*0.7,Color(color,color.a*0.09),true,-1,true)
	canvas.draw_arc(c,r,progress*PI,progress*PI+TAU*0.85,48,color,2.5,true)
	canvas.draw_arc(c,r*0.72,-progress*PI,-progress*PI+PI*1.5,40,Color(color,color.a*0.6),1.8,true)
	var petals: int = 12 if shape == "fusion_ultimate" else 8
	for i in range(petals):
		var a: float = i*TAU/petals+progress*0.8
		var tip: Vector2 = c+Vector2.from_angle(a)*r
		var side := Vector2.from_angle(a+PI*0.5)*5*(1-progress)
		canvas.draw_colored_polygon(PackedVector2Array([tip-Vector2.from_angle(a)*10,tip+side,tip+Vector2.from_angle(a)*9,tip-side]),color)
		if "frost" in effect.get("traits",[]):
			canvas.draw_line(tip-Vector2(4,0),tip+Vector2(4,0),Color(1,1,1,color.a),1,true)
			canvas.draw_line(tip-Vector2(0,4),tip+Vector2(0,4),Color(1,1,1,color.a),1,true)
	if shape == "fusion_bloom":
		for i in range(2):
			var points := PackedVector2Array()
			for n in range(28):
				var phase: float = n/27.0
				points.append(c+Vector2.from_angle(phase*TAU+progress*TAU+i*PI)*(radius*phase*(1-progress*0.4)))
			canvas.draw_polyline(points,Color(color,color.a*0.6),2,true)

static func draw_projectile(canvas: CanvasItem, projectile: Dictionary) -> void:
	var c: Vector2 = projectile.position
	var r: float = float(projectile.get("radius",8))
	var color: Color = color_for(projectile.get("fusion_traits",[]))
	var dir: float = signf(float(projectile.get("speed",1)))
	if projectile.has("fusion_blast"):
		var b: Dictionary = projectile.fusion_blast
		var hue: Color = Color("b8a6d5") if b.source == "doom_shroom" else Color("eea16d")
		canvas.draw_circle(c,r+2,Color("634c4c"),true,-1,true)
		canvas.draw_circle(c-Vector2(1,1),r,hue,true,-1,true)
		canvas.draw_arc(c,r*0.65,-2.5,-0.3,12,Color("ffe6b6"),2,true)
		canvas.draw_line(c+Vector2(-3,-r),c+Vector2(0,-r-6),Color("ab8658"),2,true)
		canvas.draw_circle(c+Vector2(1,-r-6),2,Color("ffe5a3"),true,-1,true)
		if float(projectile.get("arc_time",0))/maxf(0.01,float(projectile.get("arc_duration",1))) > 0.55:
			canvas.draw_arc(Vector2(projectile.get("arc_target",c)),minf(230,float(b.radius)),0,TAU,48,Color(hue,0.16),1,true)
		return
	canvas.draw_line(c-Vector2(dir*r*3,0),c,Color(color,0.28),r*1.2,true)
	if String(projectile.get("kind","")) == "boomerang":
		var angle: float = float(canvas.get("level_time"))*12+c.x*0.02
		canvas.draw_arc(c,r*1.15,angle,angle+PI*1.4,15,Color("334e3e"),5,true)
		canvas.draw_arc(c,r*1.15,angle,angle+PI*1.4,15,color,3,true)
	else:
		canvas.draw_circle(c,r,Color("385545"),true,-1,true)
		canvas.draw_circle(c-Vector2(1,1),r*0.77,color,true,-1,true)
		canvas.draw_circle(c-Vector2(r*0.25,r*0.25),r*0.25,Color("fff5da"),true,-1,true)
	if "fire" in projectile.get("fusion_traits",[]):
		canvas.draw_colored_polygon(PackedVector2Array([c-Vector2(dir*r,0),c-Vector2(dir*r*3.2,-r*0.6),c-Vector2(dir*r*2,0),c-Vector2(dir*r*3.2,r*0.6)]),Color(color,0.62))
	if "frost" in projectile.get("fusion_traits",[]):
		canvas.draw_line(c-Vector2(0,r),c+Vector2(0,r),Color("f0ffff"),1,true)

static func draw_skill(canvas: CanvasItem, effect: Dictionary, progress: float, tint: Color) -> void:
	var skill: String = effect.skill
	var origin: Vector2 = effect.position
	var target: Vector2 = effect.get("target",Vector2.INF)
	var c: Vector2 = target if target.is_finite() and skill in ["minefield","steam","miasma","devour","roots"] else origin
	var r: float = 35+progress*float(effect.radius)*0.65
	var alpha: float = 1-progress
	if skill == "reflection":
		for i in range(5):
			var plate := c+Vector2.from_angle(i*TAU/5+progress*0.5)*r*0.7
			canvas.draw_colored_polygon(PackedVector2Array([plate+Vector2(0,-16),plate+Vector2(10,-5),plate+Vector2(4,16),plate+Vector2(-10,5)]),Color("c1eff4",alpha*0.65))
			canvas.draw_polyline(PackedVector2Array([plate-Vector2(28,8),plate,plate+Vector2(35,-15)]),Color("f3ffff",alpha),2,true)
		canvas.draw_arc(c,r,0,TAU,48,Color("a2dfe9",alpha*0.5),2,true)
	elif skill in ["laser","rail_storm","sun_lance","beacon"]:
		var end: Vector2 = target if target.is_finite() else c+Vector2(260,0)
		canvas.draw_line(c,end,Color(tint,alpha*0.2),26*alpha+3,true)
		canvas.draw_line(c,end,Color("f8f8d9",alpha),4*alpha+1,true)
		for i in range(5):
			var point: Vector2 = c.lerp(end,fmod(progress+i*0.2,1))
			canvas.draw_circle(point,5,Color(tint,alpha),true,-1,true)
	elif skill in ["inferno","steam"]:
		for i in range(12):
			var a: float = i*TAU/12+progress*2
			var tip := c+Vector2.from_angle(a)*r
			var wing := Vector2.from_angle(a+PI*0.5)*14*alpha
			canvas.draw_colored_polygon(PackedVector2Array([c+Vector2.from_angle(a)*r*0.3,tip+wing,tip+Vector2.from_angle(a)*25*alpha,tip-wing]),Color("f8b760",alpha*0.75))
			if skill == "steam": canvas.draw_circle(tip-Vector2(0,progress*24),12*progress+3,Color("daffff",alpha*0.4),true,-1,true)
	elif skill == "blizzard":
		for i in range(6):
			var ray := Vector2.from_angle(i*TAU/6+progress*0.6)
			canvas.draw_line(c,c+ray*r,Color("c7f8ff",alpha),2,true)
			var tip := c+ray*r*0.65
			canvas.draw_line(tip,tip+ray.rotated(0.7)*r*0.3,Color("ebffff",alpha),2,true)
			canvas.draw_line(tip,tip+ray.rotated(-0.7)*r*0.3,Color("ebffff",alpha),2,true)
	elif skill == "constellation":
		var stars := PackedVector2Array()
		for i in range(5):
			var point := c+Vector2.from_angle(i*TAU/5-PI/2+progress)*r
			stars.append(point)
			var star := PackedVector2Array()
			for n in range(10): star.append(point+Vector2.from_angle(n*PI/5-PI/2)*(13 if n%2 == 0 else 5)*alpha)
			canvas.draw_colored_polygon(star,Color("fff4aa",alpha))
		for i in range(5): canvas.draw_line(stars[i],stars[(i+2)%5],Color("c3dca5",alpha*0.55),2,true)
	elif skill == "lightning":
		for i in range(5):
			var end: Vector2 = target if target.is_finite() else c+Vector2.from_angle(i*TAU/5)*r
			var bolt := PackedVector2Array([c])
			for n in range(1,9):
				var point: Vector2 = c.lerp(end,n/8.0)
				bolt.append(point+(end-c).normalized().orthogonal()*sin(n*4+i+progress*40)*12*alpha)
			canvas.draw_polyline(bolt,Color("82dbea",alpha*0.4),8,true)
			canvas.draw_polyline(bolt,Color("f0ffff",alpha),2,true)
	elif skill == "domain":
		canvas.draw_circle(c,r,Color("9083c5",alpha*0.12),true,-1,true)
		for i in range(2): canvas.draw_arc(c,r*(0.65+i*0.3),progress*(1 if i == 0 else -1),TAU+progress*(1 if i == 0 else -1),48,Color("d7c4f0",alpha),2,true)
		for i in range(12):
			var ray := Vector2.from_angle(i*TAU/12+progress)
			canvas.draw_line(c+ray*r*0.8,c+ray*r,Color("f4e8ff",alpha),3,true)
		canvas.draw_line(c,c+Vector2.from_angle(progress*TAU)*r*0.6,Color("fff4dc",alpha),3,true)
	elif skill == "bowling":
		for i in range(5):
			var point := c+Vector2(progress*170-60,(i-2)*26)
			canvas.draw_arc(point,11,progress*8,progress*8+TAU*0.9,18,Color("ffd595",alpha),4,true)
			canvas.draw_circle(point,6,Color("d69152",alpha*0.6),true,-1,true)
			canvas.draw_line(point-Vector2(40,0),point,Color("9ec58a",alpha*0.35),5,true)
	elif skill in ["blades","needles","barrage"]:
		for i in range(10):
			var a: float = i*TAU/10+progress*3
			canvas.draw_arc(c,r*(0.5+i%2*0.3),a,a+0.55,8,Color("e7efd4",alpha),4,true)
	elif skill in ["tornado","vortex","magnetic"]:
		for i in range(5):
			var points := PackedVector2Array()
			for n in range(24):
				var a: float = n/23.0*PI*1.5+progress*5+i
				points.append(c+Vector2(cos(a)*r*(0.4+i*0.12),sin(a)*r*0.28+i*7-20))
			canvas.draw_polyline(points,Color(tint,alpha*0.7),2.5,true)
	elif skill in ["dream","spirits","miasma"]:
		for i in range(8):
			var pos := c+Vector2.from_angle(i*TAU/8+progress)*r
			var wing: float = 8+sin(progress*18+i)*4
			canvas.draw_circle(pos+Vector2(-wing,0),wing,Color("d6a6ef",alpha*0.7),true,-1,true)
			canvas.draw_circle(pos+Vector2(wing,0),wing,Color("f1cfec",alpha*0.6),true,-1,true)
			canvas.draw_line(pos-Vector2(0,6),pos+Vector2(0,8),Color("725b91",alpha),2,true)
	elif skill in ["bastion","garden","renewal","awakening","spring"]:
		for i in range(6):
			var point := c+Vector2.from_angle(i*TAU/6)*r
			var shape := PackedVector2Array([point+Vector2(-10,-12),point+Vector2(10,-12),point+Vector2(12,4),point+Vector2(0,17),point+Vector2(-12,4)])
			canvas.draw_colored_polygon(shape,Color("b5e9ac",alpha*0.25))
			shape.append(shape[0]); canvas.draw_polyline(shape,Color("edf5c3",alpha),2,true)
			canvas.draw_line(point-Vector2(6,0),point+Vector2(6,0),Color("fff9db",alpha),2,true)
			canvas.draw_line(point-Vector2(0,6),point+Vector2(0,6),Color("fff9db",alpha),2,true)
	elif skill in ["minefield","meteor","purge"]:
		for i in range(10):
			var ray := Vector2.from_angle(i*TAU/10)
			canvas.draw_line(c+ray*r*0.4,c+ray*r,Color("ffd992",alpha),5*alpha+1,true)
		canvas.draw_circle(c,r*0.4,Color("fff2ce",alpha*0.2),true,-1,true)
	elif skill in ["roots","devour"]:
		for i in range(6):
			var ray := Vector2.from_angle(i*TAU/6)
			var points := PackedVector2Array([c,c+ray*r*0.35+ray.orthogonal()*12,c+ray*r*0.7-ray.orthogonal()*10,c+ray*r])
			canvas.draw_polyline(points,Color("8cb879",alpha),5,true)
	else:
		for i in range(12):
			var angle: float = i*TAU/12+progress
			var point := c+Vector2.from_angle(angle)*r
			canvas.draw_circle(point,8*alpha+2,Color("ffdf83",alpha*0.8),true,-1,true)
		canvas.draw_arc(c,r*0.55,0,TAU,48,Color("fff6ba",alpha),3,true)

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
