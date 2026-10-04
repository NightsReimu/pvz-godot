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
	var color: Color = color_for(t); color.a = alpha*0.4
	var time: float = float(canvas.get("level_time"))
	var pulse: float = sin(time*3+float(plant.get("anim_phase",0)))
	canvas.draw_arc(center+Vector2(0,24)*scale,(28+pulse*2)*scale,time*0.5,time*0.5+PI*1.35,24,color,1.4*scale,true)
	for i in range(3):
		var angle: float = time*0.85+i*TAU/3
		var pos: Vector2 = center+Vector2(cos(angle)*30,sin(angle)*12+7)*scale
		canvas.draw_circle(pos,(1.8+pulse*0.4)*scale,color,true,-1,true)

static func draw_effect(canvas: CanvasItem, effect: Dictionary) -> void:
	var progress: float = clampf(1-float(effect.time)/maxf(float(effect.duration),0.01),0,1)
	var c: Vector2 = effect.position
	var radius: float = float(effect.radius)
	var color: Color = color_for(effect.get("traits",[])); color.a = (1-progress)*0.8
	var shape: String = effect.shape
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
	if skill in ["laser","rail_storm","sun_lance","beacon"]:
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
