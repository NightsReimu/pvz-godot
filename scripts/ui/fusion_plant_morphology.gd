extends RefCounted
const Native = preload("res://scripts/data/plant_defs.gd")

# A fusion is one living organism. Ingredients choose its silhouette, growth habit,
# material, and attached weapons; we never paste miniature whole plants onto a bowl.
const FAMILIES := {
	"nut":["wallnut","tallnut","brick_guard","holo_nut","glitch_walnut","crystal_nut","pumice_wall","rock_armor_fruit","bowling_wallnut"],
	"pumpkin":["pumpkin"],
	"cherry":["cherry_bomb","blast_pomegranate"],
	"mine":["potato_mine","squash","meteor_gourd","healing_gourd","mango_bowling","resonance_beet","brine_pot"],
	"pepper":["jalapeno","pepper_mortar","chimney_pepper","magma_stream"],
	"shroom":["puff_shroom","sun_shroom","fume_shroom","sea_shroom","scaredy_shroom","hypno_shroom","ice_shroom","doom_shroom","nether_shroom","void_shroom","mirror_shroom","plasma_shroom","chaos_shroom","dream_drum","dream_disc","magnet_shroom"],
	"tree":["torchwood","thunder_pine","mamba_tree","phoenix_tree","frost_cypress","destiny_tree","thunder_god"],
	"bamboo":["spiral_bamboo","pressure_bamboo","storm_reed"],
	"mirror":["mirror_reed","prism_grass","leyline","moonforge"],
	"cabbage":["cabbage_pult"],"corn":["kernel_pult"],"melon":["melon_pult"],
	"cannon":["corn_cannon","gator_cannon"],"glassmelon":["skylight_melon"],
	"sulfur":["sulfur_pod"],"artichoke":["obsidian_artichoke"],
	"bubble":["dragon_bubble_pult"],"boiler":["fumarole_melon"],"gum":["toxic_gum_pult"],
	"vine":["vine_lasher","vine_emperor","tangle_kelp","root_snare","abyss_tentacle","grave_buster","chain_lotus","shadow_assassin","signal_ivy","glow_ivy","glowvine","spikeweed"],
	"mouth":["chomper","dragon_fruit"],
	"cactus":["cactus","cactus_guard","thorn_cactus"],
	"wind":["blover","roof_vane","steam_clover","cyclone_grass","frost_fan","echo_fern","anchor_fern"],
	"blade":["boomerang_shooter","cluster_boomerang","frost_boomerang","lotus_lancer"],
	"star":["starfruit","origami_blossom"],
	"bean":["coffee_bean","sun_bean","garlic","cork_plug","ice_cream"],
	"pot":["flower_pot"],"canopy":["umbrella_leaf"],
	"lotus":["lily_pad","moon_lotus","bubble_lotus","sand_lotus","holy_lotus","caldera_lotus"],
	"lantern":["plantern","lantern_bloom"],
	"sun":["sunflower","marigold","galaxy_sunflower","solar_emperor","thermal_sunflower","soul_flower"],
	"hive":["honey_blossom"],
	"flower":["wind_orchid","mist_orchid","tesla_tulip","cotton_candy","snow_bloom","seraph_flower","orange_bloom","hive_flower","ice_queen","time_rose","magnet_daisy","magnet_orchid","laser_lily","aurora_orchid","meteor_flower","core_blossom","holy_flower"],
	"pea":["peashooter","snow_pea","repeater","threepeater","split_pea","amber_shooter","sakura_shooter","heather_shooter","chambord_sniper","shadow_pea","plasma_shooter","prism_pea","pulse_bulb"]
}
const PRIORITY := {"nut":85,"pumpkin":86,"cherry":82,"mine":62,"pepper":76,"shroom":72,"tree":88,"bamboo":93,"mirror":91,"cabbage":94,"corn":95,"melon":96,"cannon":99,"glassmelon":97,"sulfur":96,"artichoke":98,"bubble":95,"boiler":97,"gum":95,"vine":70,"mouth":78,"cactus":80,"wind":68,"blade":79,"star":81,"bean":58,"pot":55,"canopy":83,"lotus":65,"lantern":75,"sun":64,"flower":66,"pea":50,"hive":67}
# Named recipes have deliberate architectures, rather than just a different name.
const ARCHITECTURES := {
	"sun_pea":"sun","steam_pea":"boiler","flame_blade":"blade","eclipse_blade":"blade",
	"pea_bastion":"nut","citadel_cannon":"citadel","scrap_pult":"cabbage","rail_artichoke":"rail",
	"lotus_cannon":"lotus","tidal_cannon":"lotus","garden_pot":"pot","espresso_shroom":"shroom",
	"dream_spore":"shroom","dream_choir":"choir","winter_melon":"melon","cherry_mine":"mine",
	"thorn_nut":"nut","life_bastion":"nut","wind_garlic":"wind","beacon_canopy":"canopy",
	"hourglass_bloom":"hourglass","prism_laser":"mirror","gum_corn":"corn","phoenix_dragon":"mouth",
	"cloud_orchid":"cloud","spirit_lantern":"lantern","mirror_star":"star","geothermal_cork":"bean",
	"resonant_bamboo":"bamboo","flame_mango":"mine","holy_pumpkin":"pumpkin","grave_warden":"vine",
	"solar_gatling":"crown","aurora_array":"array","blizzard_boiler":"boiler","caldera_garden":"lotus",
	"twin_sunflower":"sun","triple_sunflower":"sun","solar_crown":"crown","prime_sun_pea":"crown","prime_pea_bastion":"citadel"
}
const PALETTES := {
	"nut":["#e8c591","#996139"],"pumpkin":["#ffd386","#d87937"],"cherry":["#ffb3b3","#b53657"],
	"mine":["#e9c791","#a27648"],"pepper":["#ffb27d","#cc4d39"],"shroom":["#e0b9ef","#865697"],
	"tree":["#d5aa77","#72523b"],"bamboo":["#c2d894","#467562"],"mirror":["#d5f7ff","#609ab3"],
	"cabbage":["#d3eb9a","#60864b"],"corn":["#ffe899","#d09a3d"],"melon":["#9ecc83","#49745b"],
	"cannon":["#f6dfa3","#a7894e"],"glassmelon":["#d5eafd","#7394bd"],"sulfur":["#e9c5a4","#a45c91"],
	"artichoke":["#a8a9c7","#48435e"],"bubble":["#d0f1e5","#69a599"],"boiler":["#dcceb1","#807c6e"],
	"gum":["#f4bfdb","#bb709c"],"vine":["#b9d295","#577b55"],"mouth":["#e9b1d9","#944a83"],
	"cactus":["#b4d998","#4d8164"],"wind":["#d4efd5","#64a49b"],"blade":["#e8eed1","#799c7d"],
	"star":["#ffeba8","#b18c4b"],"bean":["#dec395","#a07354"],"pot":["#edb68e","#b96d4f"],
	"canopy":["#c5e3ab","#659977"],"lotus":["#f9d2dd","#af8197"],"lantern":["#ffebae","#b69e6b"],
	"sun":["#ffe797","#d69245"],"flower":["#f6cee3","#b56f9c"],"pea":["#c4e2a4","#67986e"],"hive":["#ffe4a0","#b28c46"]
}

static func family(source: String) -> String:
	for key in FAMILIES:
		if source in FAMILIES[key]: return key
	return "flower"

static func _path(d: String, fill: String, ink: String = "#3d5148", width: float = 1.4) -> String:
	return '<path d="%s" fill="%s" stroke="%s" stroke-width="%.2f" stroke-linecap="round" stroke-linejoin="round"/>' % [d,fill,ink,width]

static func _ellipse(x: float, y: float, rx: float, ry: float, fill: String, ink: String = "#3d5148", width: float = 1.2) -> String:
	return '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s" stroke="%s" stroke-width="%.2f"/>' % [x,y,rx,ry,fill,ink,width]

static func _group(body: String, x: float = 0, y: float = 0, angle: float = 0, size: float = 1) -> String:
	return '<g transform="translate(%.2f %.2f) rotate(%.2f) scale(%.3f)">%s</g>' % [x,y,angle,size,body]

static func _eye(x: float, y: float, size: float = 1) -> String:
	return _ellipse(x,y,1.9*size,3.1*size,"#2c3537","none")+_ellipse(x-0.5*size,y-size,0.6*size,0.9*size,"#fff7dd","none")

static func _face(x: float, y: float, span: float = 5) -> String:
	return _eye(x-span,y)+_eye(x+span,y)+_path("M%.2f %.2f q%.2f 4 %.2f 0" % [x-3,y+6,3.0,6.0],"none","#4b4d44",0.9)+_ellipse(x-span-3,y+4,2.7,1.4,"#f0b2a4","none")

static func _leaf(x: float, y: float, angle: float = 0, size: float = 1, hue: String = "url(#leaf)") -> String:
	return _group(_path("M0 0 Q-15 -17 -29 -3 Q-20 13 0 0Z",hue)+_path("M-3 0 L-23 -3 M-12 -2 l-3 -6 M-17 -2 l-4 5","none","#7b9c69",0.8),x,y,angle,size)

static func _petals(x: float, y: float, radius: float, count: int, hue: String) -> String:
	var b := ""
	for n in range(count):
		b += _group(_ellipse(0,-radius,3.8,radius*0.48,hue,"#847b5e",0.8),x,y,n*360.0/count)
	return b

static func _crystal(x: float, y: float, size: float = 1, angle: float = 0) -> String:
	return _group(_path("M0 -16 L9 -5 L5 13 L-6 9 L-9 -4Z","#b8e6ef","#557e91")+_path("M0 -16 L0 8 L9 -5 M0 8 L-6 9","none","#f5ffff",1.2),x,y,angle,size)

static func _flame(x: float, y: float, size: float = 1) -> String:
	return _group(_path("M0 8 Q-14 1 -8 -10 Q-4 -5 0 -23 Q14 -10 8 0 Q6 9 0 8Z","#efa95e","#a46247",1)+_path("M0 6 Q-7 0 1 -9 Q7 2 0 6Z","#fff0b5","none"),x,y,0,size)

static func _nozzle(x: float, y: float, size: float = 1, hue: String = "url(#skin)", pipes: int = 1) -> String:
	var b := ""
	for n in range(pipes):
		var yy: float = (n-(pipes-1)*0.5)*7
		b += _path("M-13 %.2f Q1 %.2f 13 %.2f L15 %.2f Q-1 %.2f -13 %.2fZ" % [yy-5,yy-7,yy-7,yy+6,yy+7,yy+4],hue)
		b += _ellipse(14,yy,3.3,6.7,"#476852")+_ellipse(14.7,yy,1.5,3.6,"#283d39","none")
	return _group(b,x,y,0,size)

static func _roots(source: String, tier: int) -> String:
	var f := family(source)
	var b := ""
	if f in ["tree","bamboo","vine"]:
		for n in range(4):
			var xx: float = -24+n*16
			b += _path("M0 27 Q%.2f 34 %.2f 42 l6 -2" % [xx*0.6,xx],"none","#6a7751",3)
	elif f in ["melon","glassmelon","cannon","boiler","mine","pumpkin","nut"]:
		b += _leaf(-6,37,-18,0.8)+_leaf(6,37,158,0.8)
	elif f == "pot":
		b += _path("M-26 37 L26 37 L24 42 L-24 42Z","#b67657")
	elif f == "shroom":
		b += _ellipse(-17,38,10,4,"#d2b4cf")+_ellipse(15,38,12,4,"#d2b4cf")
	else:
		b += _leaf(0,37,8,0.75)+_leaf(2,37,169,0.75)
	for n in range(mini(tier,5)):
		b += _leaf(-13+n*6,39,46+n*29,0.25)
	return b

static func _stem(x: float = 0, top: float = -12, width: float = 6) -> String:
	return _path("M%.2f 35 Q%.2f 9 %.2f %.2f L%.2f %.2f Q%.2f 12 %.2f 35Z" % [x-width,x-9,x-width,top,x+width,top,x+5,x+width],"url(#leaf)")+_leaf(x-2,19,25,0.55)+_leaf(x+3,29,155,0.5)

static func _body(arch: String, source: String, variant: int, tier: int, weights: Dictionary) -> String:
	var b := ""
	var count: int = mini(4,int(weights.get(source,1)))
	match arch:
		"nut","citadel":
			var tall := source in ["tallnut","brick_guard"] or arch == "citadel"
			var top: float = -45 if tall else -25
			b += _path("M-25 32 Q-31 6 -23 %.2f Q0 %.2f 22 %.2f Q32 6 25 32 Q0 47 -25 32Z" % [top,top-13,top],"url(#skin)","#725841",1.8)
			for n in range(4): b += _path("M%.2f %.2f q-4 17 0 28" % [-19+n*12,top+11+n%2*4],"none","#b58b62",1.2)
			b += _face(-4,-5,6)
			b += _path("M-25 20 L-19 14 L-12 19 L-15 31 L-23 34Z","#af895f")
			if source in ["holo_nut","glitch_walnut","crystal_nut"]: b += _crystal(-18,-26,0.8)+_crystal(15,25,0.6)
			if source == "brick_guard" or arch == "citadel":
				b += _path("M-26 -34 L-26 -47 L-17 -47 L-17 -40 L-7 -40 L-7 -47 L4 -47 L4 -40 L14 -40 L14 -47 L25 -47 L25 -34Z","#cfb998","#726453")
				b += _path("M-23 14 L22 14 M-22 25 L23 25 M-5 14 L-5 25 M9 25 L9 34","none","#9c8668",1)
		"pumpkin":
			for n in range(5): b += _ellipse(-24+n*12,12,12,26-absf(n-2)*3,"url(#skin)","#ab7649",1.5)
			b += _path("M-5 -10 q-3 -15 11 -17 l3 5 q-9 2 -7 12Z","url(#leaf)")
			b += _face(-3,8,7)+_leaf(-8,-10,-36,0.6)
		"cherry":
			b += _path("M-19 -7 Q-14 -44 8 -41 Q25 -38 24 -4 M0 29 L0 -26","none","#648150",3.4)
			for n in range(2+mini(1,count-1)):
				var x: float = -20+n*24; var y: float = 13 if n != 1 else 8
				b += _ellipse(x,y,16,21,"url(#skin)","#864558",1.7)+_ellipse(x-6,y-7,4,7,"#ffe0d5","none")
				b += _eye(x-3,y-2)+_eye(x+4,y-2)
			b += _leaf(6,-38,14,0.8)+_flame(4,-36,0.6)
		"mine":
			if source == "healing_gourd" or source == "meteor_gourd":
				b += _path("M-6 -39 Q-28 -39 -22 -16 Q-36 2 -28 29 Q0 43 26 26 Q35 1 18 -15 Q24 -42 -6 -39Z","url(#skin)","#776447",1.7)
			elif source == "mango_bowling": b += _path("M-21 31 Q-34 2 -14 -26 Q16 -48 29 -24 Q35 4 16 31 Q-3 46 -21 31Z","url(#skin)","#926145",1.7)
			elif source == "resonance_beet": b += _path("M-27 -3 Q-26 -22 -2 -20 Q29 -20 25 -2 Q18 22 0 38 Q-21 19 -27 -3Z","url(#skin)")
			else: b += _path("M-32 29 Q-40 10 -18 1 Q6 -15 29 4 Q41 14 33 30 Q0 45 -32 29Z","url(#skin)","#846745",1.8)
			b += _face(-7,13,6)+_leaf(0,-10,-13,0.7)
			b += _path("M-3 -7 L-3 -24 Q-3 -31 4 -31","none","#89795a",2)+_ellipse(4,-31,5,4,"#e6a568")
		"pepper":
			b += _path("M-16 -28 Q16 -49 24 -24 Q30 1 18 14 Q0 40 -31 30 Q-8 22 -14 0 Q-24 -17 -16 -28Z","url(#skin)","#8d4a3e",1.7)
			b += _face(-1,-10)+_path("M1 -32 q-8 -12 -19 -8","none","#6e8a54",4)+_flame(-15,-37,0.65)
			b += _path("M-17 4 Q-15 15 -6 19","none","#ffc88f",2)
		"shroom","choir":
			var cap_width: float = 29+variant%9
			var cap_top: float = -38 if source != "scaredy_shroom" else -48
			b += _path("M-13 34 L-11 -12 Q0 -22 11 -12 L15 34 Q0 44 -13 34Z","url(#cream)","#8d7790")
			b += _path("M-%.2f -12 Q-%.2f %.2f 0 %.2f Q%.2f %.2f %.2f -12 Q0 2 -%.2f -12Z" % [cap_width,cap_width,cap_top,cap_top,cap_width,cap_top,cap_width,cap_width],"url(#skin)","#75597d",1.8)
			for n in range(5): b += _ellipse(-22+n*11,-18-(n%2)*8,3+n%3,2.5,"#f3dcdf","none")
			b += _face(-1,13)
			if source in ["hypno_shroom","void_shroom","chaos_shroom","dream_disc"]: b += _path("M-7 -18 q-8 -9 -12 -1 q-4 10 8 10 q19 -1 15 -15 q-5 -15 -23 -5","none","#f3e1ff",1.9)
			if source == "magnet_shroom": b += _magnet(0,-30,1)
			if arch == "choir": b += _group(_path("M-7 0 L7 0 L7 13 Q0 18 -7 13Z","#d3a5ca")+_ellipse(0,0,9,3,"#f7e0c7")+_path("M-7 4 L7 10 M7 4 L-7 10","none","#937098"),-24,24)
		"tree":
			b += _path("M-18 38 Q-10 9 -17 -15 L-25 -33 L-16 -36 L-3 -19 L6 -44 L14 -41 L8 -15 L27 -28 L31 -19 L14 -7 Q12 18 22 38Z","url(#skin)","#655749",1.8)
			b += _path("M-7 27 L-3 -10 M7 31 L3 17 M-15 31 L-9 20","none","#aa8864",1.6)+_face(0,7)
			if source == "torchwood": b += _flame(-13,-29,0.75)+_flame(8,-35,0.95)
			elif source in ["thunder_pine","frost_cypress","thunder_god"]:
				for n in range(3): b += _group(_path("M-22 8 L-6 -11 L-15 -11 L0 -29 L16 -10 L8 -10 L24 8Z","#a3c698","#577866"),-6+n*7,-9-n*11,0,0.95-n*0.11)
			else:
				for n in range(3): b += _group(_path("M-23 7 Q-33 -16 -14 -22 Q-8 -39 9 -29 Q31 -30 28 -7 Q37 12 13 15Z","#b3cf98","#718962"),-13+n*13,-24+n%2*12,0,0.7)
				if source == "phoenix_tree": b += _flame(-24,-39,0.65)+_flame(23,-29,0.5)
		"bamboo":
			for n in range(3):
				var x: float = -22+n*19; var top: float = -27-n%2*25
				b += _path("M%.2f 36 L%.2f %.2f Q%.2f %.2f %.2f %.2f L%.2f 36Z" % [x-5,x-5,top,x,top-5,x+6,top,x+6],"url(#skin)")
				for segment in range(4): b += _path("M%.2f %.2f h12" % [x-5,top+6+segment*16],"none","#476d53",1.5)
				b += _leaf(x,top+14,22 if n%2 == 0 else 145,0.6)
			b += _face(-3,4,4)
		"mirror","array":
			b += _stem(0,-27,4)
			var crystals: int = 5 if arch == "mirror" else 7
			for n in range(crystals):
				var a: float = -PI/2+n*TAU/crystals
				b += _crystal(cos(a)*22,sin(a)*20-17,0.83,n*360.0/crystals+90)
			b += _ellipse(0,-17,11,12,"url(#cream)")+_face(0,-19,4)
		"cabbage":
			b += _stem(-8,-12,8)
			for n in range(5): b += _group(_path("M-21 13 Q-28 -17 0 -22 Q23 -19 22 12 Q0 29 -21 13Z","url(#skin)")+_path("M-17 9 Q-9 -18 9 -13 M-12 17 Q0 -2 20 8","none","#9eba7d",1.5),-7,-12,n*29,1-n*0.09)
			b += _face(-10,-9,4)+_path("M-27 26 L-35 -17 Q-34 -29 -24 -30","none","#6b8053",4)+_ellipse(-24,-31,9,6,"#a6c987")
		"corn":
			b += _path("M-13 30 L-18 -35 Q-15 -51 0 -51 Q15 -51 17 -35 L12 30Z","url(#skin)","#9b8046",1.6)
			for row in range(9):
				for col in range(3): b += _ellipse(-9+col*8,-40+row*7,3.4,2.7,"#f9dc86","#c4a256",0.5)
			b += _path("M-13 35 Q-38 13 -30 -23 Q-14 -13 -4 31Z","url(#leaf)")+_path("M2 33 Q6 -11 30 -20 Q38 16 13 36Z","url(#leaf)")+_face(-2,7,4)
		"melon":
			b += _ellipse(-5,9,34,26,"url(#skin)","#466a4a",1.8)
			for n in range(5): b += _path("M%.2f -14 Q%.2f 8 %.2f 32" % [-24+n*10,-36+n*16,-24+n*10],"none","#537c54",2.3)
			b += _face(-8,7,6)+_path("M-25 28 Q-24 -7 -32 -30 Q-29 -37 -22 -37","none","#7f9461",4)+_ellipse(-23,-37,10,5,"#b6d497")
		"cannon":
			b += _leaf(-2,37,-18,1)+_leaf(5,36,174,0.9)
			b += _path("M-35 18 L-35 -3 L22 -20 L30 -12 L29 14 L-20 26Z","url(#skin)","#6c714e",1.8)
			for n in range(7): b += _path("M%.2f 0 l2 19" % [-28+n*8],"none","#c3a65f",1.2)
			b += _ellipse(29,0,7,14,"#d2bb6e")+_ellipse(30,0,4,10,"#344f42","#af975e",1.8)+_face(-18,4,4)
			b += _path("M-21 25 L-25 36 L-9 36 L-7 24 M12 22 L13 35 L25 35 L23 21","url(#leaf)")
		"gator":
			b += _path("M-29 27 Q-39 9 -26 -12 Q-10 -28 8 -18 L36 -10 L39 2 L10 5 L36 12 L28 25 Q2 39 -29 27Z","url(#skin)","#4d7565",1.7)
			b += _path("M10 5 L35 -1 L29 7 L23 2 L18 8 L13 5 M11 8 L31 14 L23 20 L21 13 L16 17Z","#f4e9c0","#92a180",0.8)
			b += _eye(-4,-11,1.4)+_eye(-16,-7,1.2)+_path("M-29 3 L-37 -2 L-28 -6 M-27 16 L-37 16 L-27 11","#c8d6a4")
			b += _path("M-20 27 L-25 37 L-11 37 L-9 30 M9 29 L11 37 L25 37 L19 26","#93b27c")+_crystal(28,-5,0.38,90)
		"glassmelon":
			b += _path("M-23 31 L-32 1 L-20 -28 L7 -43 L27 -24 L33 1 L21 31Z","url(#skin)","#607e9d",1.6)
			b += _path("M7 -43 L0 29 M-20 -28 L-11 26 M27 -24 L12 28 M-30 2 L31 -3","none","#e7ffff",1.8)
			b += _ellipse(-1,3,11,12,"#e8efdd")+_face(-2,1,4)+_crystal(-27,-35,0.7,22)
		"sulfur":
			b += _stem(0,-25,6)+_path("M0 13 Q-18 -8 -25 -17 M0 12 Q23 2 24 -13","none","#8c8361",3)
			for n in range(3):
				var x: float = -25+n*24; var y: float = -13-n%2*22
				b += _path("M%.2f %.2f q-12 -18 -1 -25 q16 -8 22 6 q4 15 -9 28Z" % [x-6,y+11],"url(#skin)","#795475",1.5)
				b += _path("M%.2f %.2f q8 5 4 15" % [x,y-11],"none","#fae0b0",1.5)
			b += _face(-1,14,4)
		"artichoke","rail":
			b += _stem(0,-8,7)
			for row in range(4):
				for col in range(3-row%2):
					var x: float = -21+row%2*9+col*18; var y: float = 11-row*12
					b += _group(_path("M-12 9 L-9 -5 L0 -17 L10 -5 L12 9 Q0 16 -12 9Z","url(#skin)","#555066"),x,y,0,1-row*0.11)
			b += _face(-1,8,4)
			if arch == "rail": b += _path("M3 -1 L40 -15 L42 -5 L6 10 M8 -1 L39 -12 M9 5 L40 -8","#9bb0b5","#5a7079",1.6)
		"bubble":
			b += _stem(-8,-5,9)+_ellipse(-6,2,25,29,"url(#skin)")
			b += _path("M-27 -6 L-34 -24 L-15 -19 M6 -19 L23 -32 L20 -6","#96c1a8")
			b += _face(-10,2,5)+_nozzle(24,-3,1.1)
			for n in range(3): b += _ellipse(-20+n*11,-33-(n%2)*13,5+n,5+n,"#d9f3ed","#71a7a3",0.9)
		"boiler":
			b += _path("M-28 31 L-31 -2 Q-30 -16 -15 -18 L16 -18 Q31 -16 31 -2 L27 31Z","url(#skin)","#747463",1.7)
			b += _path("M-28 -2 L29 -2 M-25 25 L25 25","none","#bdac86",2)+_ellipse(0,8,13,13,"#b5c6a1")+_face(-1,6,4)
			b += _path("M-26 -8 L-28 -35 L-15 -35 L-13 -14 M12 -16 L14 -46 L25 -46 L26 -9","url(#skin)")+_ellipse(-22,-35,7,3,"#5b655a")+_ellipse(19,-46,6,3,"#5b655a")
		"gum":
			b += _path("M-23 33 Q-40 15 -21 -5 Q-31 -21 -13 -29 Q4 -37 13 -23 Q33 -26 32 -9 Q43 8 25 31Z","url(#skin)","#966388",1.8)
			b += _face(-4,6,6)+_path("M-13 -23 Q-3 -29 5 -21 M-29 8 Q-18 0 -9 10","none","#ffe5ef",2.5)
			b += _group(_path("M-5 -6 L5 -6 L5 6 L-5 6Z","#faf0cc")+_path("M-5 -5 L-12 -9 L-12 9 L-5 5 M5 -5 L13 -9 L13 9 L5 5","#e7d7a0"),-20,-38,15)
		"vine":
			for n in range(3):
				var x: float = -23+n*22
				b += _path("M%.2f 36 Q%.2f -2 %.2f -33 Q%.2f -46 %.2f -37 Q%.2f -23 %.2f -18" % [x,x-10,x+1,x+19,x+21,x+24,x+9],"none","#6e9263",6-n)
				b += _leaf(x,-2+n*7,-40+n*60,0.65)+_leaf(x+8,-26+n*5,170,0.5)
			b += _path("M-27 30 Q0 9 30 31 Q0 41 -27 30Z","url(#skin)")+_face(-2,26,6)
		"mouth":
			b += _stem(-7,-11,8)+_path("M-24 0 Q-37 -35 -6 -43 Q22 -49 36 -13 L11 -2 L34 11 Q14 32 -12 20Z","url(#skin)","#76516e",1.7)
			b += _path("M10 -2 L32 -11 L27 -3 L21 -6 L18 3 L12 0 M9 2 L30 11 L20 13 L18 6 L13 8Z","#fff1d0","#b59793",0.7)+_eye(-7,-24,1.4)+_leaf(-22,-27,-52,0.6)
		"cactus":
			b += _path("M-11 34 L-13 -35 Q0 -49 12 -35 L11 34Z M-10 3 L-27 3 Q-36 0 -34 -19 Q-26 -27 -23 -17 L-24 -6 L-9 -6 M11 12 L25 12 Q36 5 34 -8 Q29 -14 25 -8 L25 4 L11 4","url(#skin)","#57725b",1.6)
			for n in range(7): b += _path("M-11 %.2f l-5 -4 M11 %.2f l5 -4" % [-29+n*9,-25+n*9],"none","#f0e8bc",1.2)
			b += _face(0,-7,4)+_petals(0,-37,7,5,"#f4bdcb")
		"wind":
			b += _stem(0,-12,5)
			for n in range(4): b += _group(_path("M0 0 Q-8 -19 -3 -38 Q9 -39 18 -28 Q15 -7 0 0Z","url(#skin)")+_path("M1 -5 L5 -30","none","#ebf8d8",1.5),0,-6,45+n*90)
			b += _ellipse(0,-6,10,11,"url(#cream)")+_face(0,-8,3.5)
		"blade":
			b += _stem(0,-18,6)
			for n in range(3+mini(2,tier-1)): b += _group(_path("M0 0 Q-11 -29 -34 -36 Q-25 -15 -13 -8 Q-7 -1 0 0Z","url(#skin)")+_path("M-3 -4 L-28 -28","none","#e7f0dc",1.4),0,-13,n*360.0/(3+mini(2,tier-1))+14)
			b += _ellipse(0,-13,10,10,"url(#cream)")+_face(0,-15,3.5)
		"star":
			b += _stem(0,-16,4)
			var points := "M"
			for n in range(10):
				var a: float = -PI/2+n*PI/5; var length: float = 33 if n%2 == 0 else 16
				points += "%.2f %.2f L" % [cos(a)*length,sin(a)*length-9]
			b += _path(points.trim_suffix("L")+"Z","url(#skin)","#8d7c56",1.5)+_face(-2,-8,5)
		"bean":
			b += _path("M-26 24 Q-33 -11 -10 -31 Q10 -43 25 -20 Q35 4 21 28 Q-2 43 -26 24Z","url(#skin)","#80634c",1.7)
			b += _path("M4 -27 Q-13 -12 1 2 Q12 20 -6 31","none","#8c654c",3)+_face(-12,0,4)+_leaf(12,-20,166,0.65)
			if source == "garlic": b += _path("M-20 24 Q-16 0 -4 -29 M11 25 Q16 0 2 -30","none","#e7e0b5",2)
		"pot":
			b += _path("M-29 1 L29 1 L22 35 Q0 42 -22 35Z","url(#skin)","#94604a",1.7)+_ellipse(0,1,32,8,"#e8bda0","#986650",1.7)+_ellipse(0,0,24,4,"#77674b")
			b += _stem(0,-24,4)+_petals(0,-26,16,8,"#efc873")+_ellipse(0,-26,10,10,"url(#cream)")+_face(0,-28,3.5)
			b += _path("M-18 17 Q0 26 18 17 M-16 27 L16 27","none","#f8d2ad",1.6)
		"canopy":
			b += _stem(1,-38,5)+_path("M-40 -12 Q-37 -41 -2 -45 Q30 -43 39 -13 L25 -18 L12 -12 L-1 -18 L-16 -12 L-28 -19Z","url(#skin)","#53775e",1.6)
			b += _path("M-2 -44 L-1 -18 M-2 -44 L-28 -19 M-2 -44 L25 -18","none","#a9c597",1.3)+_face(-1,10,4)
		"lotus":
			if source == "sand_lotus":
				b += _path("M-40 36 L-31 26 L-16 29 L0 20 L18 28 L33 27 L41 36Z","#e7ca91","#b18d60")
			b += _path("M-39 34 Q-31 15 -5 22 L0 34 L8 21 Q35 17 39 35 Q4 48 -39 34Z","url(#leaf)")
			for n in range(5): b += _group(_path("M0 13 Q-13 -5 -4 -24 Q14 -16 12 2 Q9 15 0 13Z","url(#skin)","#a97c8c"),-22+n*11,12,(-2+n)*20)
			b += _ellipse(0,18,12,11,"url(#cream)")+_face(0,16,4)
		"lantern":
			b += _stem(0,-30,4)+_path("M-23 -23 Q0 -38 23 -23 L20 17 Q0 30 -20 17Z","url(#skin)","#8d7a57",1.7)
			b += _path("M-23 -23 L23 -23 M-20 17 L20 17 M-15 -23 L-12 17 M15 -23 L12 17","none","#917852",2)+_face(-1,-5,5)
			b += _path("M-25 -24 Q0 -49 25 -24Z","url(#leaf)")+_ellipse(0,-37,4,3,"#b9cd86")
		"sun","crown":
			var heads: int = count
			if weights.has("sunflower"): heads = mini(4,int(weights.sunflower))
			if heads < 2 or arch == "crown": heads = 1
			for n in range(heads):
				var x: float = (n-(heads-1)*0.5)*(25 if heads < 3 else 21)
				var y: float = -26+(n%2)*8 if heads > 1 else -18
				b += _path("M0 35 Q%.2f 13 %.2f %.2f" % [x,x,y],"none","#73965e",5)
				var rr: float = 23 if heads == 1 else 15
				b += _petals(x,y,rr,10,"url(#skin)")+_ellipse(x,y,rr*0.64,rr*0.64,"url(#cream)")+_face(x,y-2,4 if heads > 1 else 5)
			b += _leaf(-1,26,17,0.65)+_leaf(3,35,165,0.7)
			if arch == "crown": b += _path("M-15 -40 L-16 -53 L-7 -47 L0 -57 L7 -47 L17 -53 L16 -40Z","#f5d77e","#b28c4b")
		"hourglass":
			b += _stem(0,-7,5)+_petals(0,-8,30,8,"#e3b4cc")
			b += _path("M-17 -33 L17 -33 Q17 -13 4 -10 Q17 -4 17 17 L-17 17 Q-17 -3 -4 -10 Q-17 -14 -17 -33Z","#d8eada","#927d65",1.7)
			b += _path("M-14 -28 Q0 -8 14 -28 M-13 12 L0 -5 L13 12Z","#e9c178","none")+_eye(-6,-23)+_eye(6,-23)
			b += _path("M-20 -35 L20 -35 M-20 20 L20 20","none","#a68d68",4)
		"cloud":
			b += _stem(0,-12,5)
			for n in range(5): b += _ellipse(-25+n*12,-12-n%2*14,15,14,"url(#skin)","#a890b2",1.2)
			b += _face(-2,-10,5)+_petals(2,12,12,6,"#ebdaed")
		"hive":
			b += _stem(0,-14,7)
			b += _path("M-25 -25 L-13 -43 L11 -43 L28 -25 L29 -2 L13 19 L-13 19 L-29 1Z","url(#skin)","#8e7748",1.6)
			for n in range(5): b += _path("M-25 %.2f Q0 %.2f 27 %.2f" % [-26+n*10,-21+n*10,-26+n*10],"none","#ba9b5e",1.4)
			b += _face(0,-13,6)+_ellipse(-19,15,7,9,"#eed790")+_leaf(3,29,158,0.75)
		"flower":
			b += _stem(0,-19,5)
			if source in ["time_rose","magnet_daisy","magnet_orchid","orange_bloom"]:
				for n in range(7): b += _group(_path("M-12 8 Q-20 -14 0 -20 Q22 -8 12 11 Q0 20 -12 8Z","url(#skin)","#ae7998",1.1),0,-21,n*51,1-n*0.09)
			elif source in ["ice_queen","snow_bloom","core_blossom","meteor_flower"]:
				for n in range(6): b += _group(_path("M0 3 L-10 -11 L0 -35 L12 -14Z","url(#skin)","#9d87a7"),0,-10,n*60)
			elif source in ["cotton_candy","hive_flower","honey_blossom"]:
				for n in range(6): b += _ellipse(cos(n*TAU/6)*19,-19+sin(n*TAU/6)*17,11,11,"url(#skin)","#a884a5")
			else:
				for n in range(5): b += _group(_path("M0 6 Q-13 -5 -17 -32 Q1 -33 13 -18 Q18 -4 0 6Z","url(#skin)","#af849e",1.2),0,-13,n*72+variant%7*3)
			b += _ellipse(0,-16,11,12,"url(#cream)")+_face(-1,-18,4)
			if source in ["laser_lily","aurora_orchid","tesla_tulip"]: b += _crystal(17,-8,0.7,45)
		_: # Pea family: sockets grow from one connected trunk, all primary mouths face right.
			var heads: int = mini(3,maxi(count,3 if source == "threepeater" else 1))
			for n in range(heads):
				var x: float = -8+(n%2)*10; var y: float = -27+n*20
				b += _path("M-3 35 Q%.2f 9 %.2f %.2f" % [x-6,x,y],"none","#70945f",6)
				b += _ellipse(x,y,17,16,"url(#skin)")+_nozzle(x+22,y,0.8)+_eye(x-4,y-4)
				b += _leaf(x-10,y+9,-50,0.5)
			b += _leaf(0,24,20,0.65)+_leaf(4,36,158,0.7)
	return b

static func _magnet(x: float, y: float, size: float) -> String:
	return _group(_path("M-10 -11 L-4 -11 L-4 3 Q0 8 4 3 L4 -11 L10 -11 L10 4 Q0 20 -10 4Z","#e09a91","#7f5b5c",1.2)+_path("M-10 -8 L-4 -8 M4 -8 L10 -8","none","#e9edf0",3),x,y,0,size)

static func _ingredient_part(source: String, index: int, count: int, weight: int) -> String:
	# Ingredients modify the host's anatomy. These are fruit/leaf/weapon modules,
	# never reduced copies of the native character (no duplicate faces).
	var f := family(source)
	var v: int = maxi(0,Native.ORDER.find(source))
	var x: float = -23+(index%3)*21
	var y: float = -25+(index/3)*30-(v%4)*2
	var size: float = (0.8 if count <= 2 else 0.63)+mini(weight-1,3)*0.05
	var b := ""
	var hue: String = PALETTES[f][0]
	match f:
		"sun","flower","hive":
			b += _petals(0,0,14,6+v%5,hue)+_ellipse(0,0,5,5,"#f1d995")
		"nut":
			b += _path("M-11 11 L-15 -9 L-7 -19 L8 -17 L16 -6 L12 12 Q0 18 -11 11Z",hue,"#8b7051")+_path("M-6 -11 Q-10 2 -4 10 M6 -10 L8 8","none","#a9845d")
		"pumpkin":
			for n in range(3): b += _ellipse(-9+n*9,0,7,12,hue,"#b97f48")
		"cherry","sulfur":
			b += _path("M-8 2 Q-10 -20 4 -19 Q13 -19 11 4","none","#7f8858",2)+_ellipse(-9,6,9,11,hue,"#9b676e")+_ellipse(11,6,8,10,hue,"#9b676e")
		"shroom":
			b += _path("M-3 13 L-4 -1 L4 -1 L5 13Z","#ecddc6")+_path("M-18 0 Q-18 -20 0 -18 Q18 -18 19 0 Q0 10 -18 0Z",hue,"#8a6688")
			for n in range(3): b += _ellipse(-9+n*8,-5-n%2*5,2.5,2,"#ffeed4","none")
		"corn","cannon":
			b += _ellipse(0,0,8,19,hue,"#ab915b")
			for n in range(6): b += _path("M-6 %.2f h12" % [-12+n*5],"none","#d5b060",1)
			b += _leaf(1,14,12,0.5)
		"melon","glassmelon","boiler":
			b += _ellipse(0,0,17,12,hue,"#6d9470")+_path("M-10 -9 Q-15 0 -10 9 M0 -12 L0 12 M10 -9 Q15 0 10 9","none","#86ae7a",1.8)
		"cabbage","artichoke":
			for n in range(4): b += _group(_path("M-12 8 Q-14 -12 0 -19 Q14 -10 12 8Z",hue,"#738a67"),0,0,n*70,1-n*0.12)
		"mirror": b += _crystal(-5,0,1)+_crystal(8,6,0.65,25)
		"tree","bamboo":
			b += _path("M-6 15 L-6 -17 L5 -22 L7 15Z",hue)+_path("M-6 -7 L6 -7 M-6 6 L6 6","none","#7c9560",1.2)+_leaf(2,-11,146,0.5)
		"blade","wind":
			for n in range(3): b += _group(_path("M0 4 Q-12 -19 -25 -21 Q-21 -3 0 4Z",hue),0,0,n*120)
		"star": b += _path("M0 -18 L5 -6 L18 -5 L8 4 L11 16 L0 10 L-12 16 L-8 3 L-18 -6 L-5 -7Z",hue)
		"lotus","canopy":
			for n in range(3): b += _group(_path("M0 13 Q-12 0 -3 -19 Q11 -13 9 1Z",hue),-10+n*10,0,(-1+n)*32)
		"lantern": b += _path("M-10 -15 L10 -15 L12 9 L0 16 L-12 9Z",hue)+_path("M-10 -15 L10 -15 M-12 9 L12 9","none","#a08862",2)
		"vine","mouth","cactus": b += _path("M-9 15 Q-20 -8 -6 -18 Q9 -25 14 -9 Q14 3 4 3","none","#82a779",4)+_leaf(-9,6,-12,0.6)
		"pepper": b += _path("M-7 -12 Q8 -20 10 -5 Q13 14 -13 13 Q0 6 -7 -12Z",hue)+_flame(0,-12,0.5)
		"pea": b += _leaf(4,10,-28,0.65,hue)+_leaf(5,11,140,0.55,hue)+_path("M-5 9 Q0 -9 10 -13","none","#71915d",2.6)
		_: b += _ellipse(0,0,11,16,hue)+_path("M1 -13 Q-7 -3 1 4 Q7 11 0 14","none","#bfa176",1.4)
	# Source-specific venation changes the anatomy as well as palette within a family.
	for n in range(2+v%3): b += _leaf(-8+n*6,15,35+(v%7)*8+n*23,0.25+(v%5)*0.025)
	return '<g data-ingredient="%s">%s</g>' % [source,_group(b,x,y,-12+v%6*4,size)]

static func _weapons(data: Dictionary, arch: String, host: String) -> String:
	var b := ""
	var styles: Array = []
	for channel in data.get("fusion_channels",[]):
		if not styles.has(channel.style): styles.append(channel.style)
	if "shooter" in styles and arch != "pea":
		var pipes := 1
		if int(data.fusion_weights.get("peashooter",0)) >= 2: pipes = 2
		b += '<g data-organ="shooter">%s</g>' % _nozzle(25,-5 if arch not in ["lotus","mine"] else 14,0.84,"url(#leaf)",pipes)
	if "lobber" in styles and arch != "cannon":
		var yy: float = -32 if arch in ["corn","bamboo","artichoke"] else -24
		b += '<g data-organ="catapult">'+_path("M13 32 Q22 12 29 %.2f" % yy,"none","#6e875f",3)
		b += _path("M20 %.2f Q30 %.2f 42 %.2f L40 %.2f Q29 %.2f 20 %.2fZ" % [yy,yy+4,yy-6,yy-10,yy-2,yy-5],"#e3d4a4","#897f5b",1.2)
		b += _ellipse(31,yy-8,5.5,5,"#dfbb79","#a68b59")+_path("M17 23 Q28 18 29 2","none","#c4ac80",1.5)+_ellipse(16,25,3,3,"#e4d098")+'</g>'
	if "beam" in styles and arch not in ["mirror","array","rail","mouth","gator"]:
		b += '<g data-organ="beam-lens">'+_path("M12 14 L30 3 L39 7 L36 20 L17 22Z","#adcbd2","#557b82")+_crystal(34,11,0.48,90)+'</g>'
	if "burst" in styles:
		var y: float = 20 if arch in ["nut","tree","bamboo","canopy"] else 29
		var burst_hue: String = "#a796c6" if data.fusion_weights.has("doom_shroom") else "#e09b7b"
		b += '<g data-organ="burst-chamber">'+_path("M-32 %.2f l1 -13 q10 -12 20 0 l1 13 q-10 9 -22 0Z" % y,burst_hue,"#765a63")+_ellipse(-21,y-6,5,5,"#fde2a4","#94704d")+_path("M-21 %.2f l3 -3" % (y-6),"none","#876d52",1)+'</g>'
	return b

static func layout_for(id: String, data: Dictionary) -> Dictionary:
	var weights: Dictionary = data.fusion_weights
	var sources: Array = weights.keys(); sources.sort()
	var host: String = sources[0]
	var best := -1
	for source in sources:
		var score: int = int(PRIORITY[family(source)])+mini(4,int(weights[source])-1)
		if score > best: best = score; host = source
	var arch: String = ARCHITECTURES.get(id,family(host))
	if host == "gator_cannon" and not ARCHITECTURES.has(id): arch = "gator"
	return {"host":host,"arch":arch,"charge_anchor":Vector2(-21,14 if arch in ["nut","tree","bamboo","canopy"] else 23)}

static func svg_for(id: String, data: Dictionary) -> String:
	var weights: Dictionary = data.fusion_weights
	var sources: Array = weights.keys(); sources.sort()
	var layout := layout_for(id,data)
	var host: String = layout.host
	var arch: String = layout.arch
	var colors: Array = PALETTES[family(host)].duplicate()
	var traits: Array = data.get("fusion_traits",[])
	# Natural colors remain legible; elemental accents don't recolor every plant green.
	if host in ["snow_pea","ice_shroom","ice_queen","frost_cypress","frost_boomerang","snow_bloom"]: colors = ["#d8f4f8","#7aacbe"]
	if host == "doom_shroom" or host == "void_shroom": colors = ["#b9a7d5","#675477"]
	if host == "gator_cannon": colors = ["#c2dbaa","#658d70"]
	if host == "garlic": colors = ["#faf0d1","#c1bb9c"]
	if host == "torchwood" and "fire" in traits: colors = ["#d8b380","#916345"]
	var variant: int = maxi(0,Native.ORDER.find(host))
	var tier: int = int(data.fusion_tier)
	var b := '<defs><linearGradient id="skin" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient><linearGradient id="leaf" x2=".7" y2="1"><stop stop-color="#c1dca0"/><stop offset="1" stop-color="#618d67"/></linearGradient><linearGradient id="cream" x2=".6" y2="1"><stop stop-color="#fff0c9"/><stop offset="1" stop-color="#dfbb8d"/></linearGradient></defs>' % colors
	var root_family := family(host)
	var shadow_width: float = 36 if root_family in ["melon","cannon","lotus","pumpkin"] else 27
	b += _ellipse(0,42,shadow_width,3.3,"#263c32","none")+_roots(host,tier)
	# Secondary materials alter the host's branching and silhouette before its torso.
	var secondaries: Array = []
	for source in sources:
		if source != host: secondaries.append(source)
	for n in range(mini(6,secondaries.size())):
		var source: String = secondaries[n]
		b += _path("M0 30 Q%.2f 6 %.2f %.2f" % [-17+n%3*16,-23+n%3*21,-25+(n/3)*30],"none","#71895e",2.5)
		b += _ingredient_part(source,n,secondaries.size(),int(weights[source]))
	# Volume depends on actual composition, so different grafts have different ratios.
	var volume := 0
	for source in secondaries: volume += (maxi(0,Native.ORDER.find(source))+1)*int(weights[source])
	var sx: float = 0.85+(volume%7)*0.021+(variant%5)*0.015
	var sy: float = 0.88+(volume%5)*0.018+(variant%7)*0.012
	b += '<g data-host="%s" transform="scale(%.3f %.3f)">%s</g>' % [host,sx,sy,_body(arch,host,variant,tier,weights)]
	# Secondary grafts grow above or beside the torso, rather than hiding behind it.
	for n in range(mini(6,secondaries.size())):
		var source: String = secondaries[n]
		var part := _ingredient_part(source,n,secondaries.size(),int(weights[source]))
		b += _group(part,0,-8 if family(host) in ["mine","pumpkin","lotus"] else 0,0,0.8)
	b += _weapons(data,arch,host)
	if "reflect" in traits: b += '<g data-organ="reflector">'+_crystal(31,-29,0.78)+_path("M26 -30 Q17 -39 13 -27 l4 -2","none","#97c7d4",1.5)+'</g>'
	if "pressure" in traits: b += '<g data-organ="pressure-store">'+_path("M8 26 L8 12 L19 12 L19 26Z","#beca90")+_path("M8 17 L19 17 M8 22 L19 22","none","#738462")+'</g>'
	if "umbrella" in traits and arch != "canopy": b += '<g data-organ="canopy">'+_group(_path("M-18 0 Q-13 -21 0 -19 Q17 -19 20 1 L8 -3 L0 2 L-9 -3Z","#c6d9aa")+_path("M0 -19 L0 18","none","#729166",1.8),-23,-34,0,0.8)+'</g>'
	if "rear" in traits: b += '<g data-organ="rear-bud">'+_path("M-11 13 L-32 11 L-36 17 L-13 22Z","#b5d495")+_ellipse(-35,16,2.6,4.2,"#354f42")+'</g>'
	if "revive" in traits: b += '<g data-organ="phoenix-bud">'+_flame(9,-37,0.64)+'</g>'
	if "thorns" in traits or "ground" in traits:
		for n in range(5):
			var xx: float = -26+n*12
			b += _path("M%.2f 35 L%.2f 24 L%.2f 34Z" % [xx-4,xx,xx+4],"#dfdfb1","#6c7958",0.9)
	if "magnet" in traits: b += _magnet(-22,-29,0.73)
	if "frost" in traits and host not in ["ice_shroom","snow_pea","frost_cypress"]: b += _crystal(-28,21,0.48,-22)
	if "fire" in traits and host != "torchwood": b += _flame(-24,-14,0.48)
	# A few tiny buds identify successive growth without engulfing the main silhouette.
	for n in range(mini(3,maxi(0,tier-2))): b += _ellipse(-12+n*9,33,2.5,3.4,colors[0],"#73805d",0.8)
	# Sign actual geometry without labels or colors, to detect duplicate models.
	var shape_only := RegEx.new()
	shape_only.compile(' (data-[a-z-]+|fill|stroke|stop-color)="[^"]*"')
	var signature: String = shape_only.sub(b,"",true).md5_text()
	return '<svg xmlns="http://www.w3.org/2000/svg" width="192" height="224" viewBox="-48 -60 96 112" data-plant-kind="%s" data-facing="right" data-model-archetype="%s" data-geometry-signature="%s">%s</svg>' % [id,arch,signature,b]
