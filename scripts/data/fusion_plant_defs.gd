extends RefCounted

# Finite, symmetric recipes; fusion seeds are never sold as ordinary seed cards.
static var RECIPES: Dictionary = {}
static var DEFINITIONS: Dictionary = {}
const CROSS := [
	["sunflower", "peashooter", "sun_pea", "日光豌豆", "sun", ["sun", "shot"], "日轮齐射"],
	["snow_pea", "torchwood", "steam_pea", "蒸汽豌豆", "shooter", ["fire", "frost", "splash"], "汽化爆流"],
	["boomerang_shooter", "torchwood", "flame_blade", "烈焰刃花", "blade", ["fire"], "炎轮回旋"],
	["flame_blade", "snow_pea", "eclipse_blade", "冰焰回旋莲", "blade", ["fire", "frost", "lanes"], "冰焰双月"],
	["wallnut", "peashooter", "pea_bastion", "豌豆堡垒", "shooter", ["shield"], "守城连射"],
	["tallnut", "corn_cannon", "citadel_cannon", "坚城玉米炮", "lobber", ["shield", "splash"], "金穗城防"],
	["magnet_shroom", "cabbage_pult", "scrap_pult", "磁屑投手", "lobber", ["magnet", "splash"], "铁雨回收"],
	["scrap_pult", "obsidian_artichoke", "rail_artichoke", "磁轨黑曜炮", "beam", ["magnet", "pierce"], "磁轨贯城"],
	["lily_pad", "gator_cannon", "lotus_cannon", "莲台鳄鱼炮", "beam", ["pierce", "water"], "莲池龙阵"],
	["lotus_cannon", "storm_reed", "tidal_cannon", "潮雷莲炮", "beam", ["pierce", "shock", "water", "lanes"], "潮汐雷鸣"],
	["flower_pot", "sunflower", "garden_pot", "日光花园盆", "support", ["sun", "heal"], "庭院丰收"],
	["coffee_bean", "fume_shroom", "espresso_shroom", "浓缩喷菇", "beam", ["awake", "pierce"], "醒梦浓雾"],
	["hypno_shroom", "puff_shroom", "dream_spore", "梦蝶孢子菇", "shooter", ["hypno"], "蝶梦归队"],
	["dream_spore", "dream_drum", "dream_choir", "梦境合唱菇", "control", ["hypno", "awake", "heal"], "百蝶合唱"],
	["ice_shroom", "melon_pult", "winter_melon", "冰瓜投手", "lobber", ["frost", "splash"], "雪域瓜雨"],
	["cherry_bomb", "potato_mine", "cherry_mine", "樱桃连爆地雷", "bomb", ["splash", "ground"], "地雷花园"],
	["spikeweed", "wallnut", "thorn_nut", "荆棘坚果", "guard", ["ground", "thorns"], "荆城震荡"],
	["thorn_nut", "healing_gourd", "life_bastion", "生命荆棘堡", "guard", ["thorns", "heal", "shield"], "翠壁回春"],
	["garlic", "blover", "wind_garlic", "风旋蒜铃", "control", ["wind", "redirect"], "蒜香旋风"],
	["umbrella_leaf", "plantern", "beacon_canopy", "辉灯伞树", "support", ["reveal", "shield"], "光幕守望"],
	["time_rose", "sunflower", "hourglass_bloom", "日晷花", "sun", ["sun", "frost"], "流光丰年"],
	["laser_lily", "prism_grass", "prism_laser", "虹晶激光兰", "beam", ["pierce", "lanes"], "虹晶天幕"],
	["toxic_gum_pult", "kernel_pult", "gum_corn", "胶糖玉米", "lobber", ["poison", "stun", "splash"], "黏糖爆米花"],
	["phoenix_tree", "dragon_fruit", "phoenix_dragon", "凤龙果树", "beam", ["fire", "heal", "lanes"], "凤龙涅槃"],
	["cotton_candy", "wind_orchid", "cloud_orchid", "糖云风兰", "support", ["heal", "wind", "cloud"], "云海花宴"],
	["nether_shroom", "sun_shroom", "spirit_lantern", "幽灯阳光菇", "sun", ["sun", "summon"], "幽灯巡庭"],
	["mirror_shroom", "starfruit", "mirror_star", "镜星菇", "spread", ["pierce", "lanes"], "镜星万华"],
	["cork_plug", "thermal_sunflower", "geothermal_cork", "地热封口花", "support", ["sun", "cooling"], "地脉封火"],
	["resonance_beet", "pressure_bamboo", "resonant_bamboo", "共振蓄压竹", "beam", ["ground", "shock"], "竹海共鸣"],
	["mango_bowling", "torchwood", "flame_mango", "烈焰芒果", "roller", ["fire", "splash"], "火果冲阵"],
	["holy_flower", "pumpkin", "holy_pumpkin", "圣光南瓜堡", "guard", ["heal", "shield"], "圣庭庇护"],
	["grave_buster", "root_snare", "grave_warden", "墓园缠根卫", "melee", ["root", "grave"], "净土根网"],
	["solar_emperor", "sun_pea", "solar_gatling", "日冕机枪花", "shooter", ["sun", "fire", "lanes"], "日冕破晓"],
	["prism_laser", "mirror_star", "aurora_array", "极光镜阵", "beam", ["pierce", "frost", "lanes"], "极光回廊"],
	["winter_melon", "steam_pea", "blizzard_boiler", "暴雪蒸汽瓜炉", "lobber", ["frost", "fire", "splash"], "雪汽风暴"],
	["geothermal_cork", "caldera_lotus", "caldera_garden", "火山温室莲", "support", ["sun", "cooling", "heal"], "火口花园"],
]
const SUPPORTS := ["lily_pad", "flower_pot", "cork_plug"]
const SUNS := ["sunflower", "sun_shroom", "sun_bean", "marigold", "moon_lotus", "galaxy_sunflower", "soul_flower", "honey_blossom", "solar_emperor", "thermal_sunflower"]
const GUARDS := ["wallnut", "tallnut", "brick_guard", "holo_nut", "glitch_walnut", "crystal_nut", "pumpkin", "pumice_wall", "cactus_guard", "rock_armor_fruit"]
const BOMBS := ["cherry_bomb", "potato_mine", "jalapeno", "doom_shroom", "squash", "ice_shroom", "cyclone_grass", "sand_lotus", "snow_bloom", "magma_stream", "dream_disc"]
const MELEE := ["chomper", "tangle_kelp", "vine_lasher", "vine_emperor", "root_snare", "abyss_tentacle", "chain_lotus", "shadow_assassin", "grave_buster", "spikeweed", "thorn_cactus"]
const BEAMS := ["fume_shroom", "laser_lily", "mirror_shroom", "plasma_shooter", "gator_cannon", "prism_grass", "leyline", "dragon_fruit", "resonance_beet"]
const UTILITY := ["coffee_bean", "ice_cream", "holy_flower", "cotton_candy", "umbrella_leaf", "plantern", "lantern_bloom", "healing_gourd", "aurora_orchid", "bubble_lotus", "signal_ivy", "destiny_tree"]
const CONTROL := ["blover", "wind_orchid", "roof_vane", "steam_clover", "magnet_shroom", "magnet_daisy", "magnet_orchid", "anchor_fern", "time_rose", "ice_queen", "frost_cypress", "hypno_shroom", "void_shroom", "nether_shroom", "dream_drum", "chaos_shroom", "plasma_shroom", "thunder_god", "thunder_pine", "storm_reed", "tesla_tulip", "garlic", "mamba_tree"]

static func key(a: String, b: String) -> String:
	return a + "+" + b if a < b else b + "+" + a

static func result(a: String, b: String) -> String:
	return String(RECIPES.get(key(a,b), ""))

static func attack_for(kind: String) -> String:
	if kind in SUNS: return "sun"
	if kind in GUARDS: return "guard"
	if kind in BOMBS: return "bomb"
	if kind in MELEE: return "melee"
	if kind in BEAMS: return "beam"
	if kind in SUPPORTS or kind in UTILITY: return "support"
	if kind in CONTROL: return "control"
	if kind == "mango_bowling": return "roller"
	if "boomerang" in kind or kind == "spiral_bamboo": return "blade"
	if "pult" in kind or kind in ["corn_cannon", "moonforge", "meteor_gourd", "meteor_flower", "caldera_lotus", "pepper_mortar", "chimney_pepper", "chambord_sniper"]: return "lobber"
	if kind in ["starfruit", "threepeater", "lotus_lancer"]: return "spread"
	return "shooter"

static func traits_for(kind: String, data: Dictionary) -> Array:
	var t: Array = []
	if kind in SUNS: t.append("sun")
	if kind in GUARDS or kind in ["holy_flower", "bubble_lotus", "umbrella_leaf"]: t.append("shield")
	if kind in ["healing_gourd", "holy_lotus", "aurora_orchid", "holo_nut", "cotton_candy", "destiny_tree", "phoenix_tree"]: t.append("heal")
	if "frost" in kind or "snow" in kind or "ice" in kind or kind == "time_rose": t.append("frost")
	if kind in ["torchwood", "jalapeno", "dragon_fruit", "phoenix_tree", "mamba_tree", "magma_stream", "core_blossom", "chimney_pepper", "pepper_mortar", "caldera_lotus"]: t.append("fire")
	if "magnet" in kind: t.append("magnet")
	if kind in ["hypno_shroom", "chaos_shroom"]: t.append("hypno")
	if kind in ["root_snare", "anchor_fern", "vine_emperor", "abyss_tentacle", "sand_lotus", "glow_ivy"]: t.append("root")
	if kind in ["blover", "wind_orchid", "roof_vane", "cyclone_grass", "steam_clover"]: t.append("wind")
	if kind in ["thunder_god", "thunder_pine", "storm_reed", "tesla_tulip", "plasma_shooter", "resonance_beet"]: t.append("shock")
	if kind in ["toxic_gum_pult", "heather_shooter", "sulfur_pod"]: t.append("poison")
	if kind in ["kernel_pult", "pulse_bulb", "echo_fern"]: t.append("stun")
	if kind in ["spikeweed", "leyline", "potato_mine", "resonance_beet"]: t.append("ground")
	if kind in ["thorn_cactus", "cactus_guard", "crystal_nut"]: t.append("thorns")
	if kind in ["coffee_bean", "moon_lotus", "dream_drum", "lantern_bloom"]: t.append("awake")
	if kind in ["plantern", "lantern_bloom", "signal_ivy", "mist_orchid", "glow_ivy", "mirror_reed"]: t.append("reveal")
	if kind == "nether_shroom": t.append("summon")
	if kind == "grave_buster": t.append("grave")
	if kind in ["steam_clover", "cork_plug"]: t.append("cooling")
	if kind == "garlic": t.append("redirect")
	if kind == "torchwood": t.append("torch")
	if kind in ["tangle_kelp", "sea_shroom"]: t.append("water")
	if kind == "cotton_candy": t.append("cloud")
	if kind in ["threepeater", "starfruit", "lotus_lancer", "frost_fan", "prism_pea"]: t.append("lanes")
	if data.has("pierce") or data.has("pierce_count") or kind in BEAMS: t.append("pierce")
	if data.has("splash_radius") or kind in BOMBS: t.append("splash")
	if float(data.get("damage",0)) > 0: t.append("shot")
	return t

static func with_fusions(native: Dictionary, order: Array) -> Dictionary:
	if not DEFINITIONS.is_empty():
		var ready = native.duplicate(true); ready.merge(DEFINITIONS); return ready
	for kind in order:
		var first: String = "fusion_" + kind
		if kind == "sunflower": first = "twin_sunflower"
		if kind == "repeater": first = "gatling_pea"
		if kind == "peashooter":
			RECIPES[key(kind,kind)] = "repeater"
			_add(native, "repeater", "peashooter", "triple_pea", "三连豌豆", "shooter", [], "三重齐射")
			continue
		var style: String = attack_for(kind)
		var labels: Dictionary = {"sun":"双辉", "guard":"重铠", "bomb":"连爆", "melee":"双刃", "beam":"双脉", "support":"护庭", "control":"灵阵", "blade":"双环", "lobber":"双膛", "spread":"星簇", "roller":"双核", "shooter":"双生"}
		var name: String = String(labels[style]) + String(native[kind].name)
		if first == "twin_sunflower": name = "双头向日葵"
		if first == "gatling_pea": name = "机枪射手"
		_add(native, kind, kind, first, name, style, [], name + "盛放")
		var second: String = "fusion_prime_" + kind
		if kind == "sunflower": second = "triple_sunflower"
		if kind == "repeater": second = "siege_gatling"
		_add(native, first, kind, second, "三辉向日葵" if kind == "sunflower" else ("重炮机枪花" if kind == "repeater" else "共鸣" + String(native[kind].name)), style, [], "共鸣" + String(native[kind].name) + "领域")
	# Four original pea ingredients, matching two double shooters.
	RECIPES[key("triple_pea", "peashooter")] = "gatling_pea"
	_add(native,"twin_sunflower","twin_sunflower","solar_crown","日冠向日葵","sun",["sun","heal"],"日冠丰收")
	for cross in CROSS:
		_add(native,cross[0],cross[1],cross[2],cross[3],cross[4],cross[5],cross[6])
	# Every named cross also has a continued evolution by feeding its second ingredient.
	for cross in CROSS:
		_add(native,cross[2],cross[1],"prime_" + cross[2],"盛放" + cross[3],cross[4],cross[5],"极·" + cross[6])
	var all = native.duplicate(true); all.merge(DEFINITIONS); return all

static func _add(native: Dictionary, a: String, b: String, id: String, name: String, style: String, extras: Array, ultimate: String) -> void:
	var parts: Array = []
	for ingredient in [a,b]:
		if DEFINITIONS.has(ingredient): parts.append_array(DEFINITIONS[ingredient].fusion_components)
		elif ingredient == "repeater": parts.append_array(["peashooter","peashooter"])
		else: parts.append(ingredient)
	var health := 0.0; var damage := 0.0; var sun := 0.0; var cadence := 0.0
	var traits: Array = extras.duplicate(); var base: String = parts[0]
	for p in parts:
		var d: Dictionary = native[p]
		health += float(d.health); damage += float(d.get("damage", d.get("contact_damage",0)))
		if p in SUNS: sun += float(d.get("sun_amount",25 if p == "thermal_sunflower" else 50))
		cadence += float(d.get("shoot_interval",d.get("attack_interval",d.get("pulse_interval",2.5))))
		for tag in traits_for(p,d):
			if not traits.has(tag): traits.append(tag)
		if p in SUPPORTS: base = p
	# Keep canonical passive identities so existing ladder, hypnosis and terrain rules work.
	if not base in SUPPORTS:
		for p in parts:
			if p in ["hypno_shroom", "garlic", "umbrella_leaf", "plantern", "torchwood", "phoenix_tree", "tallnut", "pumpkin"]: base = p; break
	var n: int = parts.size()
	var shots: int = clampi(n,2,6)
	var interval: float = clampf(cadence / n,1.1,5.0)
	if style == "bomb": interval = 22.0
	if style == "control" or style == "support": interval = 4.5
	if style == "beam": interval = maxf(2.6,interval)
	if style == "roller": interval = 5.0
	var hit: float = maxf(12,damage * (1.0 if id in ["gatling_pea","triple_pea","siege_gatling"] else 0.85) / shots)
	if style == "bomb": hit = clampf(damage * 0.65,180,2400)
	if style == "beam" or style == "melee" or style == "lobber": hit *= shots * 0.72
	var tags: Dictionary = {"sun":"光合", "fire":"灼烧", "frost":"缓速", "magnet":"回收金属", "hypno":"梦蝶魅惑", "root":"缠根", "shock":"雷链", "poison":"毒蚀", "wind":"风推", "heal":"回春", "shield":"护盾", "pierce":"贯穿手持盾", "splash":"溅射", "stun":"震晕", "grave":"清墓", "awake":"唤醒", "summon":"幽灵援军", "cooling":"冷却岩浆", "reveal":"显形", "redirect":"改道", "torch":"炬火", "water":"水栖", "cloud":"云栖", "ground":"地面攻击", "thorns":"反刺", "lanes":"跨行", "shot":"齐射"}
	var words: Array = []
	for t in traits:
		if words.size() < 6: words.append(String(tags.get(t,t)))
	var inherited: Dictionary = native[base].duplicate(true)
	inherited.erase("volcano_expansion"); inherited.erase("one_shot"); inherited.erase("stacks_on_plant")
	inherited.merge({"name":name,"cost":0,"cooldown":7.5,"health":maxf(180,health*0.78),"damage":hit,"shoot_interval":interval,"fusion_only":true,"fusion_base":base,"fusion_components":parts,"fusion_recipe":[a,b],"fusion_attack":style,"fusion_traits":traits,"fusion_shots":shots,"fusion_tier":clampi(n-1,1,5),"sun_amount":roundi(sun),"sun_interval":maxf(12.0,24.0-float(n)),"ultimate_charge_time":clampf(52.0+n*4.0,56,84),"ultimate_duration":1.2,"ultimate_name":ultimate,"fusion_summary":"、".join(words)},true)
	var healing := 0.0
	for p in parts: healing += float(native[p].get("heal_amount",0))
	inherited.fusion_heal = maxf(14*(1+n*0.25),healing*0.78)
	DEFINITIONS[id] = inherited
	RECIPES[key(a,b)] = id
