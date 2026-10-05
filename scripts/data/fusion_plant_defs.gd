extends RefCounted
const Combat = preload("res://scripts/data/fusion_combat_profiles.gd")
const Ultimates = preload("res://scripts/data/fusion_ultimates.gd")

# Symmetric recipes and canonical recursive grafts; hybrids are not ordinary seed cards.
static var RECIPES: Dictionary = {}
static var DEFINITIONS: Dictionary = {}
static var NATIVE: Dictionary = {}
static var CATALOGUE: Dictionary = {}
static var COMPOSITIONS: Dictionary = {}
static var revision := 0
const CROSS := [
	["sunflower", "peashooter", "sun_pea", "日光豌豆", "sun", ["sun", "shot"], "日轮齐射"],
	["snow_pea", "torchwood", "steam_pea", "蒸汽豌豆", "shooter", ["fire", "frost", "splash"], "汽化爆流"],
	["boomerang_shooter", "torchwood", "flame_blade", "烈焰刃花", "blade", ["fire"], "炎轮回旋"],
	["flame_blade", "snow_pea", "eclipse_blade", "冰焰回旋莲", "blade", ["fire", "frost", "lanes"], "冰焰双月"],
	["wallnut", "peashooter", "pea_bastion", "豌豆堡垒", "shooter", ["shield"], "守城连射"],
	["tallnut", "corn_cannon", "citadel_cannon", "坚城玉米炮", "lobber", ["shield", "splash"], "金穗城防"],
	["magnet_shroom", "cabbage_pult", "scrap_pult", "磁屑投手", "lobber", ["magnet", "splash"], "铁雨回收"],
	["scrap_pult", "obsidian_artichoke", "rail_artichoke", "磁轨黑曜炮", "beam", ["magnet", "pierce"], "磁轨贯城"],
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
	["jasmine_tea", "golden_milk", "jasmine_milk_tea", "茉莉奶茶", "control", ["weaken", "milk"], "奶香满庭"],
	["electric_bonk_choy", "thunder_pine", "thunder_bonk_choy", "雷鸣菜问", "melee", ["shock", "chain"], "雷霆万钧"],
	["dandelion", "blover", "breeze_dandelion", "风絮蒲公英", "lobber", ["wind", "anti_air"], "长风万絮"],
	["samsara_eye", "phoenix_tree", "samsara_phoenix", "涅槃轮回树", "support", ["samsara", "revive", "fire"], "涅槃轮回"],
	["golden_milk", "coffee_bean", "golden_latte", "金铲拿铁", "bomb", ["milk", "awake"], "醒神奶浪"],
]
const EXCLUDED := ["lily_pad", "flower_pot"]
# Minigame-only seeds never reach a board where fusion is enabled.
const UNOBTAINABLE := ["wallnut_bowling"]
# A hybrid's rootstock is its body on the board. Low-profile, single-use, grave-bound
# and water/cloud-locked species contribute their weapon instead of becoming the body,
# so a fused wall is still bitten and a fused shooter is not trapped on one terrain.
const RESTRICTED_BODIES := ["spikeweed", "tangle_kelp", "cotton_candy", "sea_shroom", "grave_buster", "potato_mine", "cherry_bomb", "jalapeno", "squash", "ice_shroom", "doom_shroom", "cyclone_grass", "sand_lotus", "snow_bloom", "magma_stream", "dream_disc", "ice_cream", "holy_flower", "golden_milk", "samsara_eye"]
const IDENTITY_BODIES := ["hypno_shroom", "garlic", "umbrella_leaf", "plantern", "torchwood", "phoenix_tree", "tallnut", "pumpkin"]
const SUPPORTS := ["lily_pad", "flower_pot", "cork_plug"]
const SUNS := ["sunflower", "sun_shroom", "sun_bean", "marigold", "moon_lotus", "galaxy_sunflower", "soul_flower", "honey_blossom", "solar_emperor", "thermal_sunflower"]
const GUARDS := ["wallnut", "tallnut", "brick_guard", "holo_nut", "glitch_walnut", "crystal_nut", "pumpkin", "pumice_wall", "cactus_guard", "rock_armor_fruit"]
const BOMBS := ["cherry_bomb", "potato_mine", "jalapeno", "doom_shroom", "squash", "ice_shroom", "cyclone_grass", "sand_lotus", "snow_bloom", "magma_stream", "dream_disc", "golden_milk"]
const MELEE := ["electric_bonk_choy", "chomper", "tangle_kelp", "vine_lasher", "vine_emperor", "root_snare", "abyss_tentacle", "chain_lotus", "shadow_assassin", "grave_buster", "spikeweed", "thorn_cactus"]
const BEAMS := ["fume_shroom", "laser_lily", "mirror_shroom", "plasma_shooter", "gator_cannon", "prism_grass", "leyline", "dragon_fruit", "resonance_beet"]
const UTILITY := ["samsara_eye", "coffee_bean", "ice_cream", "holy_flower", "cotton_candy", "umbrella_leaf", "plantern", "lantern_bloom", "healing_gourd", "aurora_orchid", "bubble_lotus", "signal_ivy", "destiny_tree"]
const CONTROL := ["jasmine_tea", "blover", "wind_orchid", "roof_vane", "steam_clover", "magnet_shroom", "magnet_daisy", "magnet_orchid", "anchor_fern", "time_rose", "ice_queen", "frost_cypress", "hypno_shroom", "void_shroom", "nether_shroom", "dream_drum", "chaos_shroom", "plasma_shroom", "thunder_god", "thunder_pine", "storm_reed", "tesla_tulip", "garlic", "mamba_tree"]

static func key(a: String, b: String) -> String:
	return a + "+" + b if a < b else b + "+" + a

static func result(a: String, b: String) -> String:
	for input in [a,b]:
		for component in weights_for(input):
			if component in EXCLUDED or component in UNOBTAINABLE: return ""
	var pair := key(a,b)
	if RECIPES.has(pair): return String(RECIPES[pair])
	if not (NATIVE.has(a) or DEFINITIONS.has(a)) or not (NATIVE.has(b) or DEFINITIONS.has(b)): return ""
	var weights := weights_for(a)
	for component in weights_for(b): weights[component] = mini(8,int(weights.get(component,0))+int(weights_for(b)[component]))
	var signature := composition_key(weights)
	if COMPOSITIONS.has(signature):
		RECIPES[pair] = COMPOSITIONS[signature]
		return String(COMPOSITIONS[signature])
	var id := "mix_"+signature.md5_text().substr(0,20)
	var style := combined_attack(weights)
	var name := "%s·%s" % [String(CATALOGUE[a].name),String(CATALOGUE[b].name)]
	if name.length() > 22: name = "%s共生庭" % String(NATIVE[weights.keys()[0]].name)
	_add(NATIVE,a,b,id,name,style,[],"",weights)
	return id

# Supports keep their layer; canonical passive identities keep ladder, hypnosis and
# terrain rules; otherwise the first freely plantable, bitable species is the body.
static func rootstock(parts: Array) -> String:
	var base: String = parts[0]
	for p in parts:
		if p in SUPPORTS: base = p
	if base in SUPPORTS: return base
	for p in parts:
		if p in IDENTITY_BODIES: return p
	for p in parts:
		if not p in RESTRICTED_BODIES: return p
	return base

static func weights_for(id: String) -> Dictionary:
	if DEFINITIONS.has(id): return DEFINITIONS[id].fusion_weights.duplicate()
	return {"peashooter":2} if id == "repeater" else {id:1}

static func composition_key(weights: Dictionary) -> String:
	var keys: Array = weights.keys(); keys.sort()
	var tokens := PackedStringArray()
	for component in keys: tokens.append("%s:%d" % [component,int(weights[component])])
	return "/".join(tokens)

static func combined_attack(weights: Dictionary) -> String:
	# Passive rootstock must never replace an attacking ingredient's range/weapon.
	var scores := {"shooter":5,"spread":6,"beam":7,"lobber":8,"blade":9,"roller":10,"bomb":4,"melee":3,"control":2,"guard":1,"sun":0,"support":-1}
	var best := "support"
	for component in weights:
		var style := attack_for(component)
		if int(scores[style]) > int(scores[best]): best = style
	return best

static func skill_names() -> Dictionary:
	return {"tea_ceremony":"茶香满庭","samsara":"轮回再临","reflection":"镜面折返","barrage":"百叶齐射","solar":"日冕丰收","constellation":"星阵交火","laser":"棱镜扫射","meteor":"陨星瓜雨","blades":"万刃回旋","bowling":"果轮冲阵","minefield":"连锁爆田","devour":"巨颚吞噬","bastion":"城墙护庭","domain":"灵域镇压","garden":"共生花园","renewal":"生命回潮","awakening":"醒梦加速","magnetic":"磁暴回收","dream":"蝶梦归队","spirits":"幽灵游行","tornado":"风之环流","beacon":"辉光审判","purge":"净土清墓","spring":"冷泉封火","roots":"荆棘根网","lightning":"雷霆连锁","blizzard":"冰晶封阵","inferno":"不死鸟炎阵","miasma":"毒蝶蚀域","vortex":"逆风换道","needles":"千刺反击","steam":"冰火汽爆","rail_storm":"磁轨雷暴","sun_lance":"日轮贯城"}

static func skill_descriptions() -> Dictionary:
	return {"tea_ceremony":"前方三行六列腐蚀 12 秒，敌人虚弱并受到茶浪伤害","samsara":"复活周围 15 秒内倒下的植物，原格有植物时与之融合","reflection":"反转场上敌方弹幕，并保留镜面拦截；相邻植物获得短时镜盾", "barrage":"材料武器齐射与两次追击，保留原有锁敌方式", "solar":"立刻产生三份强化阳光", "constellation":"强化原有星弹、花瓣或环射，再追加两轮追击", "laser":"扫过五行的贯穿光束", "meteor":"保留各投手弹种、落点追踪与原有特殊效果", "blades":"原生回旋弹强化与追击，来回均可命中", "bowling":"强化原生滚动果轮，沿途连续撞击敌人", "minefield":"一次释放各爆舱，保留圆形、整行或近身范围；随后重新充能", "devour":"近身重击并回收生命", "bastion":"范围治疗、护盾及短暂无敌", "domain":"范围伤害、定身和缓速", "garden":"治疗自身与邻株，赋予十秒加速及护盾", "renewal":"范围治疗并留下八秒回春", "awakening":"唤醒睡眠植物并加速十秒", "magnetic":"回收周围手持与头戴金属，释放磁轨光束", "dream":"普通敌人累积梦蝶即魅惑，Boss受定身", "spirits":"召唤最多三名幽灵友军", "tornado":"推动普通敌人，驱散飞行敌人并清雾", "beacon":"全场显形，光束审判敌群", "purge":"清除范围坟墓，留下净土爆炸", "spring":"冷却周围岩浆，获得护盾", "roots":"全场缠根并在近处爆发荆棘", "lightning":"五行连锁电击和短暂震晕", "blizzard":"全场五秒减速与一秒冻结", "inferno":"五行烈焰，八秒持续灼烧", "miasma":"全场毒蚀并留下三次毒爆", "vortex":"推退普通敌群并切换合法邻行", "needles":"五行穿盾刺雨及反伤护甲", "steam":"冰火联合，敌群三次蒸汽爆炸", "rail_storm":"回收金属后发射五行磁轨雷束", "sun_lance":"产出阳光同时发射日轮贯穿束"}

static func attack_for(kind: String) -> String:
	if kind in Combat.LOBBERS or "pult" in kind: return "lobber"
	if kind in ["mirror_reed","holy_lotus"]: return "support"
	if kind in ["core_blossom","glitch_walnut"]: return "bomb"
	if kind in SUNS: return "sun"
	if kind in GUARDS: return "guard"
	if kind in BOMBS: return "bomb"
	if kind in MELEE: return "melee"
	if kind in BEAMS: return "beam"
	if kind in SUPPORTS or kind in UTILITY: return "support"
	if kind in CONTROL: return "control"
	if kind in ["mango_bowling","wallnut_bowling"]: return "roller"
	if "boomerang" in kind or kind == "spiral_bamboo": return "blade"
	if "pult" in kind or kind in Combat.LOBBERS: return "lobber"
	if kind in ["starfruit", "threepeater", "lotus_lancer"]: return "spread"
	return "shooter"

static func traits_for(kind: String, data: Dictionary) -> Array:
	var t: Array = []
	if kind in SUNS: t.append("sun")
	if kind in GUARDS or kind in ["holy_flower", "bubble_lotus", "umbrella_leaf"]: t.append("shield")
	if kind in ["healing_gourd", "holy_lotus", "aurora_orchid", "holo_nut", "cotton_candy", "destiny_tree", "phoenix_tree"]: t.append("heal")
	if "frost" in kind or "snow" in kind or "ice" in kind or kind == "time_rose": t.append("frost")
	if kind in ["torchwood", "jalapeno", "dragon_fruit", "phoenix_tree", "mamba_tree", "magma_stream", "core_blossom", "chimney_pepper", "pepper_mortar", "caldera_lotus", "meteor_flower"]: t.append("fire")
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
	if data.has("splash_radius"): t.append("splash")
	if float(data.get("damage",0)) > 0 and not kind in Combat.BURSTS and kind != "mirror_reed": t.append("shot")
	if kind == "mirror_reed": t.append("reflect")
	if kind == "jasmine_tea": t.append("weaken")
	if kind == "golden_milk": t.append("milk")
	if kind == "samsara_eye": t.append("samsara")
	if kind == "electric_bonk_choy":
		for tag in ["shock", "chain", "rear"]:
			if not t.has(tag): t.append(tag)
	if kind == "umbrella_leaf": t.append("umbrella")
	if kind in ["fumarole_melon","brine_pot"] and not "splash" in t: t.append("splash")
	if kind in ["thunder_god","thunder_pine","tesla_tulip","storm_reed","plasma_shooter","chain_lotus"]: t.append("chain")
	if kind in ["prism_pea","sakura_shooter","glowvine","dragon_bubble_pult","toxic_gum_pult"]: t.append("split")
	if kind == "pressure_bamboo": t.append("pressure")
	if kind == "mirror_shroom": t.append("copy")
	if kind == "phoenix_tree": t.append("revive")
	if kind == "split_pea": t.append("rear")
	if kind in ["cactus","seraph_flower","lantern_bloom","lotus_lancer","origami_blossom","dandelion"] or kind in Combat.ASH: t.append("anti_air")
	return t

static func with_fusions(native: Dictionary, order: Array) -> Dictionary:
	if not DEFINITIONS.is_empty():
		var ready = native.duplicate(true); ready.merge(DEFINITIONS); return ready
	NATIVE = native
	var ingredients: Array = order.duplicate()
	for id in native:
		if not ingredients.has(id): ingredients.append(id)
	ingredients = ingredients.filter(func(id): return not id in EXCLUDED and not id in UNOBTAINABLE)
	for kind in ingredients:
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
		_add(native, kind, kind, first, name, style, [], "")
		var second: String = "fusion_prime_" + kind
		if kind == "sunflower": second = "triple_sunflower"
		if kind == "repeater": second = "siege_gatling"
		_add(native, first, kind, second, "三辉向日葵" if kind == "sunflower" else ("重炮机枪花" if kind == "repeater" else "共鸣" + String(native[kind].name)), style, [], "")
	# Four original pea ingredients, matching two double shooters.
	RECIPES[key("triple_pea", "peashooter")] = "gatling_pea"
	_add(native,"twin_sunflower","twin_sunflower","solar_crown","日冠向日葵","sun",["sun","heal"],"日冠丰收")
	for cross in CROSS:
		_add(native,cross[0],cross[1],cross[2],cross[3],cross[4],cross[5],cross[6])
	# Every named cross also has a continued evolution by feeding its second ingredient.
	for cross in CROSS:
		_add(native,cross[2],cross[1],"prime_" + cross[2],"盛放" + cross[3],cross[4],cross[5],"极·" + cross[6])
	for a in ingredients:
		for b in ingredients:
			if String(a) > String(b) or RECIPES.has(key(a,b)): continue
			var weights := weights_for(a)
			for component in weights_for(b): weights[component] = int(weights.get(component,0))+int(weights_for(b)[component])
			var id := "pair_"+String(a)+"_"+String(b)
			_add(native,a,b,id,"%s·%s" % [native[a].name,native[b].name],combined_attack(weights),[],"",weights)
	CATALOGUE = native.duplicate(true); CATALOGUE.merge(DEFINITIONS)
	return CATALOGUE

static func _add(native: Dictionary, a: String, b: String, id: String, name: String, style: String, extras: Array, ultimate: String, weights_override: Dictionary = {}) -> void:
	if not (native.has(a) or DEFINITIONS.has(a)) or not (native.has(b) or DEFINITIONS.has(b)): return
	for input in [a,b]:
		for component in weights_for(input):
			if component in EXCLUDED or component in UNOBTAINABLE: return
	var parts: Array = []
	for ingredient in [a,b]:
		if DEFINITIONS.has(ingredient): parts.append_array(DEFINITIONS[ingredient].fusion_components)
		elif ingredient == "repeater": parts.append_array(["peashooter","peashooter"])
		else: parts.append(ingredient)
	var weights: Dictionary = weights_override.duplicate()
	if weights.is_empty():
		for part in parts: weights[part] = int(weights.get(part,0))+1
	else:
		parts.clear()
		var components: Array = weights.keys(); components.sort()
		for component in components:
			for n in range(int(weights[component])): parts.append(component)
	var health := 0.0; var sun := 0.0
	var traits: Array = extras.duplicate(); var base: String = rootstock(parts)
	for p in parts:
		var d: Dictionary = native[p]
		health += float(d.health)
		if p in SUNS: sun += float(d.get("sun_amount",25 if p == "thermal_sunflower" else 50))
		for tag in traits_for(p,d):
			if not traits.has(tag): traits.append(tag)
	if style in ["sun","support","guard","control"] and "shot" in traits:
		style = combined_attack(weights)
	var n: int = parts.size()
	var channels: Array = Combat.channels(native,weights,traits,attack_for,traits_for)
	var primary: Dictionary = {}
	for channel in channels:
		if channel.style == style: primary = channel; break
	if primary.is_empty() and not channels.is_empty(): primary = channels[0]
	var shots: int = int(primary.get("shots",1))
	var interval: float = float(primary.get("interval",4.5))
	var hit: float = float(primary.get("damage",0))
	var tags: Dictionary = {"weaken":"虚弱", "milk":"奶浪击退", "samsara":"轮回复苏", "sun":"光合", "fire":"灼烧", "frost":"缓速", "magnet":"回收金属", "hypno":"梦蝶魅惑", "root":"缠根", "shock":"雷链", "poison":"毒蚀", "wind":"风推", "heal":"回春", "shield":"护盾", "pierce":"贯穿手持盾", "splash":"溅射", "stun":"震晕", "grave":"清墓", "awake":"唤醒", "summon":"幽灵援军", "cooling":"冷却岩浆", "reveal":"显形", "redirect":"改道", "torch":"炬火", "water":"水栖", "cloud":"云栖", "ground":"地面攻击", "thorns":"反刺", "lanes":"跨行", "shot":"齐射", "chain":"连锁", "split":"分裂", "pressure":"蓄压", "copy":"镜像复制", "reflect":"镜面反弹", "umbrella":"空袭拦截", "revive":"凤凰复生", "rear":"背向防守", "anti_air":"对空"}
	var words: Array = []
	for t in traits:
		if words.size() < 6: words.append(String(tags.get(t,t)))
	var inherited: Dictionary = native[base].duplicate(true)
	inherited.erase("volcano_expansion"); inherited.erase("one_shot"); inherited.erase("stacks_on_plant")
	inherited.merge({"name":name,"cost":0,"cooldown":7.5,"health":clampf(health*0.78,180,30000),"damage":minf(hit,2400),"shoot_interval":interval,"fusion_channels":channels,"fusion_only":true,"fusion_base":base,"fusion_components":parts,"fusion_weights":weights,"fusion_recipe":[a,b],"fusion_attack":style,"fusion_traits":traits,"fusion_shots":shots,"fusion_tier":clampi(n-1,1,8),"sun_amount":mini(800,roundi(sun)),"sun_interval":maxf(12.0,24.0-float(n)),"ultimate_charge_time":clampf(52.0+n*4.0,56,84),"ultimate_duration":1.2,"ultimate_name":ultimate,"fusion_summary":"、".join(words)},true)
	var healing := 0.0
	for p in parts: healing += float(native[p].get("heal_amount",0))
	inherited.fusion_heal = minf(600,maxf(14*(1+n*0.25),healing*0.78))
	var weapon_skills := {"shooter":"barrage","spread":"constellation","beam":"laser","lobber":"meteor","blade":"blades","roller":"bowling","control":"domain","melee":"devour","burst":"minefield"}
	var attacks: Array = []
	for channel in channels:
		if channel.style == "payload": continue
		var skill: String = weapon_skills[channel.style]
		if not attacks.has(skill): attacks.append(skill)
	inherited.fusion_weapon_skills = attacks
	var traits_of := {}
	var attack_of := {}
	for part in weights:
		traits_of[part] = traits_for(part,native[part]); attack_of[part] = attack_for(part)
	var signature: Dictionary = Ultimates.compose(style,parts,weights,traits,traits_of,attack_of,ultimate,
		channels.any(func(channel): return channel.style == "burst"),
		channels.any(func(channel): return channel.style in ["shooter","spread","beam","lobber","blade","roller"]),
		channels.filter(func(channel): return channel.style == "payload").map(func(channel): return channel.source))
	inherited.fusion_skills = signature.skills
	var steady_damage := 0.0
	for channel in channels:
		if channel.style != "burst": steady_damage += float(channel.damage)
	inherited.fusion_utility_damage = clampf(steady_damage*1.8,40,300)/sqrt(maxf(1.0,float(inherited.fusion_skills.size()-1)))
	# The opening strike of an ultimate is worth about seven seconds of the hybrid's sustained fire.
	var sustained := 0.0
	for channel in channels:
		if channel.style == "payload": continue
		sustained += float(channel.damage)*float(channel.get("shots",1))/maxf(0.5,float(channel.interval))
	inherited.fusion_strike_damage = clampf(sustained*7.0,180.0,1100.0)*(1.0+0.1*minf(4.0,float(n-2)))
	inherited.fusion_utility_damage = maxf(float(inherited.fusion_utility_damage),float(inherited.fusion_strike_damage)*0.35)
	inherited.fusion_combat_description = []
	for channel in channels: inherited.fusion_combat_description.append(Combat.describe(channel,native))
	var passive_notes := {
		"mirror_reed":"镜芦苇：保留对敌方狙击与 Boss 弹幕的镜面反弹。",
		"umbrella_leaf":"伞叶：继续保护周围植物，拦截空袭。",
		"phoenix_tree":"凤凰树：保留原种的被动复生次数。",
		"ice_queen":"冰晶女王：每 3.5 秒冰击周围最近四敌，24 伤害并冻结 2 秒。",
		"frost_cypress":"寒霜柏：周围敌人减速 50%，累计停留 3 秒冻结 2.5 秒。",
		"pressure_bamboo":"蓄压竹：空闲时积蓄最多三枚弹药，发现敌人后错峰抛射。",
		"mirror_shroom":"镜像蘑菇：复制邻株持续武器伤害；一次性爆炸不能复制为光束。"
	}
	for source in passive_notes:
		if weights.has(source): inherited.fusion_combat_description.append(passive_notes[source])
	inherited.ultimate_name = signature.name
	inherited.fusion_ultimate_description = signature.description
	inherited.ultimate_duration = 2.4
	inherited.fusion_art_dynamic = id.begins_with("mix_")
	DEFINITIONS[id] = inherited
	RECIPES[key(a,b)] = id
	COMPOSITIONS[composition_key(weights)] = id
	if not CATALOGUE.is_empty(): CATALOGUE[id] = inherited
	revision += 1
