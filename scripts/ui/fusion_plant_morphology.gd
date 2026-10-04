extends RefCounted
const Parts = preload("res://scripts/data/fusion_art_parts.gd")
const Native = preload("res://scripts/data/plant_defs.gd")

# A fusion is drawn like the classic cast: the sturdiest ingredient lends its
# whole body (re-tinted toward its partners) and every other ingredient grows
# its signature graft on it: snouts, petal halos, caps, armor, catapult arms,
# lotus seats. Fixed SVG files and live recursive grafts share this composer.
const FAMILIES := {
	"nut":["wallnut","tallnut","brick_guard","holo_nut","glitch_walnut","crystal_nut","pumice_wall","rock_armor_fruit"],
	"pumpkin":["pumpkin"],
	"cherry":["cherry_bomb","blast_pomegranate"],
	"mine":["potato_mine","squash","meteor_gourd","healing_gourd","mango_bowling","resonance_beet","brine_pot"],
	"pepper":["jalapeno","pepper_mortar","chimney_pepper","magma_stream"],
	"shroom":["puff_shroom","sun_shroom","fume_shroom","sea_shroom","scaredy_shroom","hypno_shroom","ice_shroom","doom_shroom","nether_shroom","void_shroom","mirror_shroom","plasma_shroom","chaos_shroom","magnet_shroom"],
	"tree":["torchwood","thunder_pine","mamba_tree","phoenix_tree","frost_cypress","destiny_tree"],
	"bamboo":["spiral_bamboo","pressure_bamboo","storm_reed"],
	"mirror":["mirror_reed","prism_grass","leyline","moonforge"],
	"pult":["cabbage_pult","kernel_pult","melon_pult","skylight_melon","dragon_bubble_pult","fumarole_melon","toxic_gum_pult","sulfur_pod","obsidian_artichoke"],
	"cannon":["corn_cannon","gator_cannon","chambord_sniper"],
	"vine":["vine_lasher","vine_emperor","tangle_kelp","root_snare","abyss_tentacle","grave_buster","shadow_assassin","signal_ivy","glow_ivy","glowvine","spikeweed","anchor_fern","echo_fern"],
	"mouth":["chomper","dragon_fruit"],
	"cactus":["cactus","cactus_guard","thorn_cactus"],
	"wind":["blover","roof_vane","steam_clover","cyclone_grass","frost_fan","umbrella_leaf"],
	"blade":["boomerang_shooter","cluster_boomerang","frost_boomerang","lotus_lancer"],
	"star":["starfruit","origami_blossom"],
	"bean":["coffee_bean","sun_bean","garlic","cork_plug","ice_cream"],
	"lotus":["moon_lotus","bubble_lotus","sand_lotus","holy_lotus","caldera_lotus","chain_lotus"],
	"lantern":["plantern","lantern_bloom","pulse_bulb"],
	"sun":["sunflower","marigold","galaxy_sunflower","solar_emperor","thermal_sunflower","soul_flower","honey_blossom"],
	"drum":["dream_drum","dream_disc"],
	"cup":["jasmine_tea"],
	"bottle":["golden_milk"],
	"choy":["electric_bonk_choy"],
	"puff":["dandelion"],
	"eye":["samsara_eye"],
	"flower":["wind_orchid","mist_orchid","tesla_tulip","cotton_candy","snow_bloom","seraph_flower","orange_bloom","hive_flower","ice_queen","time_rose","magnet_daisy","magnet_orchid","laser_lily","aurora_orchid","meteor_flower","core_blossom","holy_flower","thunder_god"],
	"pea":["peashooter","snow_pea","repeater","threepeater","split_pea","amber_shooter","sakura_shooter","heather_shooter","shadow_pea","plasma_shooter","prism_pea"],
}
# Higher numbers make better bodies; low numbers read best as a graft.
const PRIORITY := {"nut":85,"pumpkin":30,"cherry":74,"mine":62,"pepper":66,"shroom":72,"tree":88,"bamboo":80,"mirror":70,"pult":92,"cannon":96,"vine":60,"mouth":78,"cactus":82,"wind":64,"blade":76,"star":68,"bean":58,"lotus":69,"lantern":67,"sun":65,"drum":63,"cup":84,"bottle":40,"choy":79,"puff":61,"eye":71,"flower":66,"pea":50}
# When a graft would land in an occupied place it moves to the next free one.
const FALLBACK := {
	"crown":["crown","orbit_tr","back_high"], "side":["side","side_low","front"], "back":["back","back_high","halo"],
	"halo":["halo","back","orbit"], "front":["front","base_left","side_low"], "base":["base","base_left","front"],
	"orbit":["orbit","orbit_tr","crown"], "front_head":["front_head","crown","orbit"], "sides":["sides","front","side_low"],
	"base_left":["base_left","base","front"],
}
const BEHIND := ["halo","back","back_high","base"]


static func family(source: String) -> String:
	for key in FAMILIES:
		if source in FAMILIES[key]: return key
	return "flower"


static func host_for(weights: Dictionary) -> String:
	var sources: Array = weights.keys(); sources.sort()
	var host: String = sources[0]
	var best := -1
	for source in sources:
		var score: int = int(PRIORITY[family(source)])*10+mini(4,int(weights[source])-1)*3
		if score > best: best = score; host = source
	return host


static func layout_for(id: String, data: Dictionary) -> Dictionary:
	var host := host_for(data.fusion_weights)
	var a: Array = Parts.ANCHORS.get(host,[0,-20,-20,20,-10,0])
	return {"host":host,"arch":family(host),"charge_anchor":Vector2(clampf(float(a[2])*0.86-4,-40,-18),24)}


# Hue turns toward the partner while saturation is kept, so mixed tissue never turns muddy.
static func _mix(a: String, b: String, t: float) -> String:
	var ca := Color(a)
	var cb := Color(b)
	var dh: float = fposmod(cb.h-ca.h+0.5,1.0)-0.5
	var hue: float = fposmod(ca.h+(dh*t if cb.s > 0.12 else 0.0),1.0)
	return "#"+Color.from_hsv(hue,lerpf(ca.s,maxf(ca.s,cb.s),t),lerpf(ca.v,cb.v,t*0.5)).to_html(false)


static func _ordered_partners(weights: Dictionary, host: String) -> Array:
	var partners: Array = []
	for source in weights:
		if source != host: partners.append(source)
	partners.sort_custom(func(x, y):
		if int(weights[x]) != int(weights[y]): return int(weights[x]) > int(weights[y])
		if PRIORITY[family(x)] != PRIORITY[family(y)]: return int(PRIORITY[family(x)]) > int(PRIORITY[family(y)])
		return String(x) < String(y))
	return partners


static func _g(body: String, x: float, y: float, s: float, rotation: float = 0.0) -> String:
	return '<g transform="translate(%.1f %.1f) rotate(%.1f) scale(%.3f)">%s</g>' % [x,y,rotation,s,body]


static func _spark(x: float, y: float, r: float, color: String) -> String:
	var points := PackedStringArray()
	for i in range(8):
		var radius: float = r if i%2 == 0 else r*0.38
		var angle: float = -PI*0.5+i*PI/4.0
		points.append("%.1f %.1f" % [x+cos(angle)*radius,y+sin(angle)*radius])
	return '<path d="M%sZ" fill="%s" stroke="#283e35" stroke-width="0.7"/>' % [" L".join(points),color]


static func svg_for(id: String, data: Dictionary) -> String:
	var weights: Dictionary = data.fusion_weights
	var host := host_for(weights)
	var partners := _ordered_partners(weights, host)
	var host_weight: int = int(weights[host])
	var a: Array = Parts.ANCHORS.get(host,[0,-20,-20,20,-10,0])
	var primary: String = Parts.PRIMARY.get(host,"leaf")
	# Partner colors seep into the host's main tissue; same-family partners tint harder.
	var tint: Array = Parts.GRADIENTS.get(primary,["#88b758","#3d774b"]).duplicate()
	if not partners.is_empty():
		var partner_colors: Array = Parts.GRADIENTS.get(Parts.PRIMARY.get(partners[0],"leaf"),tint)
		var amount: float = 0.45 if family(partners[0]) == family(host) else 0.22
		tint = [_mix(tint[0],partner_colors[0],amount),_mix(tint[1],partner_colors[1],amount)]
	elif host_weight > 1:
		tint = [_mix(tint[0],"#fff3b8",0.18),_mix(tint[1],"#e0a640",0.12)]
	var body: String = String(Parts.BODIES[host]).replace("url(#%s)" % primary,"url(#hp)")
	# Plan each visible graft's place before sizing the host.
	var placed := {}
	var grafts: Array = []
	for n in range(mini(4,partners.size())):
		var source: String = partners[n]
		var spec: Dictionary = Parts.GRAFTS[source]
		var slot: String = spec.slot
		var svg: String = spec.svg
		if spec.has("alt_slot") and family(source) == family(host):
			slot = spec.alt_slot; svg = spec.alt_svg
		var chosen := ""
		for option in FALLBACK.get(slot,[slot]):
			if not placed.has(option): chosen = option; break
		if chosen.is_empty(): continue
		placed[chosen] = true
		grafts.append({"source":source,"slot":chosen,"svg":svg,"weight":int(weights[source])})
	var tall: bool = placed.has("crown") or placed.has("orbit_tr") or placed.has("front_head")
	var hs: float = 0.8 if tall else 0.88
	if placed.has("halo"): hs = minf(hs,0.84)
	var hx: float = -3.0 if placed.has("side") or placed.has("sides") else 0.0
	if placed.has("back") or placed.has("back_high"): hx += 4.0
	# Twins and triplets shrink the lead body so the siblings can be seen.
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
			"side": placed_svg = _g(svg,right-6,head.y,gs)
			"side_low": placed_svg = _g(svg,right-8,head.y+17,gs*0.8)
			"sides": placed_svg = _g(svg,head.x,head.y+4,gs)
			"back": placed_svg = _g(svg,left+8,head.y+10,gs)
			"back_high": placed_svg = _g(svg,left+12,head.y-6,gs*0.8,-12)
			"halo": placed_svg = _g(svg,crown.x,head.y-2,width*(0.94+0.06*minf(3,w-1)))
			"front": placed_svg = _g(svg,crown.x,mid+8,gs*0.9)
			"base": placed_svg = _g(svg,0,38,gs*0.95)
			"base_left": placed_svg = _g(svg,-27,38,gs*0.82)
			"orbit": placed_svg = _g(svg,head.x,head.y,gs*0.9)
		# Doubled side weapons grow a second barrel below the first.
		if w >= 2 and String(item.slot) in ["side","side_low"]:
			placed_svg += _g(svg,right-10,head.y+12+minf(3,w-2)*4,gs*0.66)
		if String(item.slot) in BEHIND: behind += '<g data-ingredient="%s">%s</g>' % [item.source,placed_svg]
		else: front += '<g data-ingredient="%s">%s</g>' % [item.source,placed_svg]
	# Further partners appear as small buds along the root crown.
	var buds := ""
	for n in range(4,partners.size()):
		var source: String = partners[n]
		var gradient: String = Parts.PRIMARY.get(source,"leaf")
		var bx: float = -20+float((n-4)%6)*8
		buds += '<g data-ingredient="%s"><ellipse cx="%.1f" cy="%.1f" rx="3.2" ry="4.2" fill="url(#%s)" stroke="#283e35" stroke-width="0.9"/></g>' % [source,bx,33.0-float((n-4)/6)*5,gradient]
	# Repeated host material grows twin and triple heads behind the main body.
	var twins := ""
	if host_weight >= 2:
		twins += _g(body,hx-24,hy-9+28*hs*0.3,hs*0.7)
	if host_weight >= 3:
		twins += _g(body,hx+24,hy-9+28*hs*0.3,hs*0.66)
	for n in range(clampi(host_weight-3,0,5)):
		twins += _spark(-34+n*7,30-(n%2)*4,2.4,"#f8e7a0")
	var sparkles := ""
	for n in range(clampi(int(data.get("fusion_tier",1))-2,0,4)):
		sparkles += _spark(-30+n*20,-48+(n%2)*6,3.2+n*0.4,"#fff2a8")
	var host_svg: String = '<g data-host="%s">%s</g>' % [host,_g(body,hx,hy,hs)]
	# A grafting vine binds the materials at the root crown; its leaves carry the partner tones.
	var collar_tone: String = Parts.PRIMARY.get(partners[0],"leaf") if not partners.is_empty() else "leaf"
	var collar := '<g data-organ="graft-collar"><path d="M-20 35 Q-8 29 0 33 Q9 28 20 34" fill="none" stroke="#283e35" stroke-width="3.6"/><path d="M-20 35 Q-8 29 0 33 Q9 28 20 34" fill="none" stroke="#6fa553" stroke-width="2"/>'
	for n in range(3):
		var lx: float = -14+n*14
		collar += '<path d="M%.1f %.1f q-5 -6 -1 -10 q5 3 1 10Z" fill="url(#%s)" stroke="#283e35" stroke-width="0.9" transform="rotate(%d %.1f %.1f)"/>' % [lx,32.0-(n%2)*2,collar_tone,-30+n*30,lx,32.0-(n%2)*2]
	collar += '<circle cx="1" cy="32" r="2.2" fill="#fff2a8" stroke="#283e35" stroke-width="0.8"/></g>'
	# Named recipes wear a golden blossom on the graft; their full bloom adds a second one.
	if not (id.begins_with("pair_") or id.begins_with("fusion_") or id.begins_with("mix_")):
		collar += '<g data-organ="named-bloom">'+_spark(14,28,4.6,"#ffd76a")+'<circle cx="14" cy="28" r="1.6" fill="#fff6d0"/></g>'
		if id.begins_with("prime_"): collar += '<g data-organ="named-bloom">'+_spark(-15,29,4.0,"#ffd76a")+'</g>' 
	var shadow: String = '<ellipse cx="0" cy="38" rx="%.1f" ry="4" fill="#233e2b" opacity=".16"/>' % (24.0+6.0*width)
	var content: String = shadow+behind+twins+host_svg+collar+front+buds+sparkles
	# Only gradients that are actually referenced are written into the file.
	var defs := '<linearGradient id="hp" x1=".2" y1="0" x2=".8" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % tint
	for gid in Parts.GRADIENTS:
		if content.find("url(#%s)" % gid) != -1:
			var stops: Array = Parts.GRADIENTS[gid]
			defs += '<linearGradient id="%s" x1=".2" y1="0" x2=".8" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % [gid,stops[0],stops[1]]
	var b: String = '<defs>%s</defs><g stroke-linejoin="round" stroke-linecap="round">%s</g>' % [defs,content]
	# Sign actual geometry without labels or colors, to detect duplicate models.
	var shape_only := RegEx.new()
	shape_only.compile(' (data-[a-z-]+|fill|stroke|stop-color)="[^"]*"')
	var signature: String = shape_only.sub(b,"",true).md5_text()
	return '<svg xmlns="http://www.w3.org/2000/svg" width="192" height="224" viewBox="-48 -60 96 112" data-plant-kind="%s" data-facing="right" data-model-archetype="%s" data-geometry-signature="%s">%s</svg>' % [id,family(host),signature,b]
