extends RefCounted
static var textures: Dictionary = {}

static func color_for(traits: Array) -> Color:
	if "fire" in traits and "frost" in traits: return Color("e7a5b9")
	if "fire" in traits: return Color("f5ad52")
	if "frost" in traits: return Color("9ee4ef")
	if "hypno" in traits or "poison" in traits: return Color("d0a4e7")
	if "magnet" in traits or "shock" in traits: return Color("94cfdd")
	if "sun" in traits: return Color("f7d77c")
	return Color("9fd279")

static func draw_plant(canvas: CanvasItem, id: String, center: Vector2, scale: float, flash: float, alpha: float, plant: Dictionary = {}) -> void:
	if not textures.has(id): textures[id] = load("res://art/vector/fusions/%s.svg" % id)
	var texture: Texture2D = textures[id]
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
