extends RefCounted
const Parts = preload("res://scripts/data/fusion_art_parts.gd")
const Patterns = preload("res://scripts/ui/fusion_patterns.gd")
const Flair = preload("res://scripts/ui/fusion_flair.gd")

# A fusion is drawn as one new plant. The strongest silhouette lends the body;
# the most striking partner lends its skin, re-colouring the living tissue and
# patterning it (cherry gloss, nut cracks, melon stripes, frost...). A host
# without a weapon grows its partner's barrel from its own mouth, an armed host
# reshapes its muzzle instead. Partners add their accessory, the fiercest
# expression and their elemental aura. Fixed SVGs and live recursive fusions
# share this composer.
const FALLBACK := {
	"crown":["crown","orbit_tr","back_high"], "side":["side","side_low","front"], "back":["back","back_high","halo"],
	"halo":["halo","back","orbit"], "front":["front","base_left","side_low"], "base":["base","base_left","front"],
	"orbit":["orbit","orbit_tr","crown"], "front_head":["front_head","crown","orbit"], "sides":["sides","front","side_low"],
	"base_left":["base_left","base","front"],
}
const BEHIND := ["halo","back","back_high","base"]


static func _k(source: String) -> Dictionary:
	return Parts.KINDS[source]


static func host_for(weights: Dictionary) -> String:
	var sources: Array = weights.keys(); sources.sort()
	var host: String = sources[0]
	var best := -1
	for source in sources:
		var score: int = int(_k(source).form)*10+mini(4,int(weights[source])-1)*3
		if score > best: best = score; host = source
	return host


static func _partners(weights: Dictionary, host: String) -> Array:
	var partners: Array = []
	for source in weights:
		if source != host: partners.append(source)
	partners.sort_custom(func(x, y):
		if int(weights[x]) != int(weights[y]): return int(weights[x]) > int(weights[y])
		if float(_k(x).mat) != float(_k(y).mat): return float(_k(x).mat) > float(_k(y).mat)
		return String(x) < String(y))
	return partners


# The partner whose skin the hybrid wears, or "" when the host keeps its own.
static func donor_for(weights: Dictionary, host: String) -> String:
	var best := ""
	var mat := 0.0
	var sources: Array = weights.keys(); sources.sort()
	for source in sources:
		if source != host and float(_k(source).mat) > mat: mat = float(_k(source).mat); best = source
	if best.is_empty(): return ""
	var own: float = float(_k(host).mat)
	# Two equally striking skins keep the host's; its partner shows as pattern, crest and aura.
	return best if mat >= 0.4 and (mat >= own+0.1 or own < 0.6) else ""


static func elements_for(weights: Dictionary, host: String = "") -> Array:
	var found: Array = []
	for element in Flair.ELEMENT_ORDER:
		for source in weights:
			if source != host and element in _k(source).elems and not found.has(element): found.append(element)
	if not host.is_empty():
		for element in Flair.ELEMENT_ORDER:
			if element in _k(host).elems and not found.has(element): found.append(element)
	return found


static func layout_for(id: String, data: Dictionary) -> Dictionary:
	var host := host_for(data.fusion_weights)
	var a: Array = _k(host).anchors
	var hs := 0.82
	var hy: float = 37.0-35.0*hs
	return {"host":host,"charge_anchor":Vector2(clampf(float(a[2])*0.86-4,-40,-18),24),"elements":elements_for(data.fusion_weights,host),
		"crown":Vector2(float(a[0])*hs,hy+float(a[1])*hs),"head":Vector2(float(a[0])*hs,hy+float(a[4])*hs),"left":float(a[2])*hs,"right":float(a[3])*hs}


# A colour on a material's light->dark axis; <0 is highlight, >1 deep shadow.
static func _shade(light: Color, dark: Color, t: float) -> Color:
	if t <= 0.0:
		var a: float = clampf(-t*0.9,0,1)
		return Color.from_hsv(light.h,light.s*(1-a),light.v+(1-light.v)*a)
	if t >= 1.0:
		var b: float = clampf((t-1)*0.9,0,1)
		return Color.from_hsv(dark.h,clampf(dark.s*(1+b*0.3),0,1),dark.v*(1-b*0.75))
	var dh: float = fposmod(dark.h-light.h+0.5,1.0)-0.5
	return Color.from_hsv(fposmod(light.h+dh*t,1.0),lerpf(light.s,dark.s,t),lerpf(light.v,dark.v,t))


static func _hex(color: Color) -> String:
	return "#"+color.to_html(false)


static func _paint(host: String, light: Color, dark: Color, own: bool, tint_light: Color, tint_dark: Color, tint: float) -> String:
	var body: String = Parts.BODIES[host]
	var slots: Array = _k(host).slots
	for n in range(slots.size()):
		var t: float = float(slots[n][0])
		var c: Color = Color(slots[n][1]) if own else _shade(light,dark,t)
		if own and tint > 0: c = c.lerp(_shade(tint_light,tint_dark,t),tint)
		body = body.replace("{s%d}" % n,_hex(c))
	return body


static func _tissue(svg: String, light: Color, dark: Color) -> String:
	return svg.replace("{sd}",_hex(_shade(light,dark,1.9))).replace("{sl}",_hex(_shade(light,dark,-0.6)))


static func _g(body: String, x: float, y: float, s: float, rotation: float = 0.0) -> String:
	return '<g transform="translate(%.1f %.1f) rotate(%.1f) scale(%.3f)">%s</g>' % [x,y,rotation,s,body]


static func _spark(x: float, y: float, r: float, color: String) -> String:
	var points := PackedStringArray()
	for i in range(8):
		var radius: float = r if i%2 == 0 else r*0.38
		var angle: float = -PI*0.5+i*PI/4.0
		points.append("%.1f %.1f" % [x+cos(angle)*radius,y+sin(angle)*radius])
	return '<path d="M%sZ" fill="%s" stroke="#283e35" stroke-width="0.7"/>' % [" L".join(points),color]


static func _mood_for(partners: Array, host: String) -> String:
	var best := ""
	for mood in Flair.MOOD_ORDER:
		for source in partners:
			if String(_k(source).mood) == mood and mood != String(_k(host).mood): return mood
	return best


static func svg_for(id: String, data: Dictionary) -> String:
	var weights: Dictionary = data.fusion_weights
	var host := host_for(weights)
	var hk: Dictionary = _k(host)
	var partners := _partners(weights, host)
	var host_weight: int = int(weights[host])
	var donor := donor_for(weights, host)
	var seed: int = hash(id)
	# Skin: a striking partner re-colours the tissue; otherwise the host only blushes toward it.
	var own: bool = donor.is_empty()
	var light := Color(hk.own[0]); var dark := Color(hk.own[1])
	if not own: light = Color(_k(donor).light); dark = Color(_k(donor).dark)
	var tint_light := light; var tint_dark := dark; var tint := 0.0
	if own and not partners.is_empty():
		tint_light = Color(_k(partners[0]).light); tint_dark = Color(_k(partners[0]).dark); tint = 0.16
	elif own and host_weight > 1:
		tint_light = Color("#fff3b8"); tint_dark = Color("#e0a640"); tint = 0.2
	var skin_light: Color = light.lerp(tint_light,tint) if own else light
	var skin_dark: Color = dark.lerp(tint_dark,tint) if own else dark
	var body := _paint(host,light,dark,own,tint_light,tint_dark,tint)
	# Surface: the donor's pattern, a weaker partner's pattern at half strength, then a second material.
	var patterns := ""
	var used: Array = []
	var sources: Array = [donor] if not own else []
	for source in partners:
		if not sources.has(source) and float(_k(source).mat) >= (0.5 if sources.is_empty() else 0.75): sources.append(source)
	for source in sources:
		var pattern: String = _k(source).pattern
		if pattern == "none" or used.has(pattern) or used.size() >= 2: continue
		var strength: float = 1.0 if source == donor else (0.55 if used.is_empty() else 0.45)
		patterns += Patterns.draw(pattern,hk.box,Color(_k(source).light),Color(_k(source).dark),seed+used.size(),strength)
		used.append(pattern)
	var mask := ""
	if not patterns.is_empty() and not String(hk.mask).is_empty():
		mask = '<mask id="mk" maskUnits="userSpaceOnUse" x="-80" y="-100" width="170" height="190">%s' % hk.mask
		for e in hk.eyes: mask += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#000"/>' % [float(e[0]),float(e[1]),float(e[2])*1.7+0.6,float(e[3])*1.4+0.6]
		if bool(hk.frontal): mask += '<ellipse cx="%.1f" cy="%.1f" rx="5.5" ry="3.4" fill="#000"/>' % [float(hk.mouth[0]),float(hk.mouth[1])]
		for m in hk.muzzles: mask += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#000"/>' % [float(m[0]),float(m[1]),float(m[2])*1.1,float(m[2])*1.6]
		mask += '</mask>'
	var tissue: String = body+('<g data-organ="pattern" mask="url(#mk)">%s</g>' % patterns if not mask.is_empty() else "")
	var face: String = Flair.mood(hk.eyes,bool(hk.frontal),_mood_for(partners,host),_hex(_shade(skin_light,skin_dark,0.25)))
	if not face.is_empty(): tissue += '<g data-organ="mood">%s</g>' % face
	# Weapon: an unarmed host grows the first armed partner's barrel from its mouth.
	var weapon := ""
	var gunner := ""
	for source in partners:
		if String(_k(source).weapon).is_empty(): continue
		gunner = source
		if bool(hk.armed) and not hk.muzzles.is_empty():
			weapon = '<g data-organ="muzzle" data-ingredient="%s">%s</g>' % [source,Flair.muzzle(String(_k(source).muzzle),hk.muzzles,Color(_k(source).light),Color(_k(source).dark))]
		else:
			# A frontal face pushes the barrel past its cheek; a profile grows it from the snout line.
			var reach: float = float(hk.anchors[3])-float(hk.mouth[0])
			var ws: float = clampf((reach+9.0)/17.0,0.85,1.45) if bool(hk.frontal) else float(hk.head)*0.95
			var barrel: String = _tissue(String(_k(source).weapon),skin_light,skin_dark)
			weapon = _g(barrel,float(hk.mouth[0])-1,float(hk.mouth[1]),ws)
			if int(weights[source]) >= 2: weapon = _g(barrel,float(hk.mouth[0])-2,float(hk.mouth[1])+8*ws,ws*0.78)+weapon
			weapon = '<g data-organ="weapon" data-ingredient="%s">%s</g>' % [source,weapon]
		break
	# Accessories find a free place on the body.
	var placed := {}
	var grafts: Array = []
	for n in range(mini(4,partners.size())):
		var source: String = partners[n]
		var chosen := ""
		for option in FALLBACK.get(String(_k(source).slot),[String(_k(source).slot)]):
			if not placed.has(option): chosen = option; break
		if chosen.is_empty(): continue
		placed[chosen] = true
		grafts.append({"source":source,"slot":chosen,"svg":String(_k(source).acc),"weight":int(weights[source])})
	var a: Array = hk.anchors
	var tall: bool = placed.has("crown") or placed.has("orbit_tr") or placed.has("front_head")
	var hs: float = 0.8 if tall else 0.88
	if placed.has("halo"): hs = minf(hs,0.84)
	var hx: float = -3.0 if placed.has("side") or placed.has("sides") or (not weapon.is_empty() and not bool(hk.armed)) else 0.0
	if placed.has("back") or placed.has("back_high"): hx += 4.0
	if host_weight >= 2: hs *= 0.88
	if host_weight == 2: hx += 7.0
	var hy: float = 37.0-35.0*hs
	var crown := Vector2(hx+float(a[0])*hs,hy+float(a[1])*hs)
	var head := Vector2(crown.x,hy+float(a[4])*hs)
	var right: float = hx+float(a[3])*hs
	var left: float = hx+float(a[2])*hs
	var mid: float = hy+float(a[5])*hs
	var width: float = clampf((float(a[3])-float(a[2]))*hs/36.0,0.76,1.3)
	var behind := ""
	var front := ""
	for item in grafts:
		var w: int = int(item.weight)
		var gs: float = 0.96+0.08*minf(3,w-1)
		var svg: String = item.svg
		var placed_svg := ""
		match String(item.slot):
			"crown": placed_svg = _g(svg,crown.x,crown.y+5,gs*0.92)
			"orbit_tr": placed_svg = _g(svg,right-4,crown.y+8,gs*0.62,14)
			"front_head": placed_svg = _g(svg,crown.x,crown.y+9,gs*0.85)
			"side": placed_svg = _g(svg,right-6,head.y+4,gs)
			"side_low": placed_svg = _g(svg,right-8,head.y+17,gs*0.8)
			"sides": placed_svg = _g(svg,head.x,head.y+4,gs)
			"back": placed_svg = _g(svg,left+8,head.y+10,gs)
			"back_high": placed_svg = _g(svg,left+12,head.y-6,gs*0.8,-12)
			"halo": placed_svg = _g(svg,crown.x,head.y-2,width*(0.94+0.06*minf(3,w-1)))
			"front": placed_svg = _g(svg,crown.x,mid+8,gs*0.9)
			"base": placed_svg = _g(svg,0,38,gs*0.95)
			"base_left": placed_svg = _g(svg,-27,38,gs*0.82)
			"orbit": placed_svg = _g(svg,head.x,head.y,gs*0.9)
		if String(item.slot) in BEHIND: behind += '<g data-ingredient="%s">%s</g>' % [item.source,placed_svg]
		else: front += '<g data-ingredient="%s">%s</g>' % [item.source,placed_svg]
	# Further partners ripen as small fruits of their own colour along the root crown.
	var buds := ""
	for n in range(4,partners.size()):
		var source: String = partners[n]
		var bx: float = -20+float((n-4)%6)*8
		buds += '<g data-ingredient="%s"><ellipse cx="%.1f" cy="%.1f" rx="3.2" ry="4.2" fill="%s" stroke="#283e35" stroke-width="0.9"/></g>' % [source,bx,33.0-float((n-4)/6)*5,_k(source).light]
	# Repeated host material grows twin and triple heads behind the main body.
	var twins := ""
	if host_weight >= 2: twins += _g(tissue,hx-24,hy-9+28*hs*0.3,hs*0.7)
	if host_weight >= 3: twins += _g(tissue,hx+24,hy-9+28*hs*0.3,hs*0.66)
	for n in range(clampi(host_weight-3,0,5)):
		twins += _spark(-34+n*7,30-(n%2)*4,2.4,"#f8e7a0")
	# Elemental emblems sit beside the head, never across the face.
	var auras := ""
	var elements := elements_for(weights,host)
	var spots: Array = [Vector2(clampf(right+5,-40,40),clampf(crown.y+6,-50,30)),Vector2(clampf(left-5,-40,40),clampf(crown.y+12,-50,30)),Vector2(clampf(right+3,-40,40),clampf(mid+12,-46,34))]
	var shown := 0
	var total := 0
	for source in weights: total += int(weights[source])
	for element in elements:
		if shown >= (1 if total <= 2 else 2): break
		var emblem: String = Flair.aura(element,spots[shown].x,spots[shown].y,0.9,seed)
		if emblem.is_empty(): continue
		auras += '<g data-element="%s">%s</g>' % [element,emblem]
		shown += 1
	var host_svg: String = '<g data-host="%s">%s</g>' % [host,_g(tissue+weapon,hx,hy,hs)]
	# Named recipes wear a golden blossom at the stem; their full bloom adds a second one.
	var emblem := ""
	if not (id.begins_with("pair_") or id.begins_with("fusion_") or id.begins_with("mix_")):
		emblem = '<g data-organ="named-bloom">'+_spark(14,30,4.6,"#ffd76a")+'<circle cx="14" cy="30" r="1.6" fill="#fff6d0"/></g>'
		if id.begins_with("prime_"): emblem += '<g data-organ="named-bloom">'+_spark(-15,31,4.0,"#ffd76a")+'</g>'
	var shadow: String = '<ellipse cx="0" cy="38" rx="%.1f" ry="4" fill="#233e2b" opacity=".16"/>' % (24.0+6.0*width)
	var content: String = shadow+behind+twins+host_svg+front+buds+auras+emblem
	# Leaves turn with the hybrid's leading element.
	var leaf: Array = Parts.GRADIENTS["leaf"]
	for element in elements:
		if Flair.LEAF_TINTS.has(element): leaf = Flair.LEAF_TINTS[element]; break
	var defs := '<linearGradient id="skin" x1=".2" y1="0" x2=".8" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % [_hex(skin_light),_hex(skin_dark)]
	defs += '<linearGradient id="lf" x1=".2" y1="0" x2=".8" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % [leaf[0],leaf[1]]
	for gid in Parts.GRADIENTS:
		if content.find("url(#%s)" % gid) != -1:
			var stops: Array = Parts.GRADIENTS[gid]
			defs += '<linearGradient id="%s" x1=".2" y1="0" x2=".8" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % [gid,stops[0],stops[1]]
	defs += mask
	var b: String = '<defs>%s</defs><g stroke-linejoin="round" stroke-linecap="round">%s</g>' % [defs,content]
	# Sign actual geometry without labels or colours, to detect duplicate models.
	var shape_only := RegEx.new()
	shape_only.compile(' (data-[a-z-]+|fill|stroke|stop-color)="[^"]*"')
	var signature: String = shape_only.sub(b,"",true).md5_text()
	return '<svg xmlns="http://www.w3.org/2000/svg" width="192" height="224" viewBox="-48 -60 96 112" data-plant-kind="%s" data-facing="right" data-model-archetype="%s" data-geometry-signature="%s">%s</svg>' % [id,host,signature,b]
