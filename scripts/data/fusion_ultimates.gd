extends RefCounted
# A hybrid has one signature ultimate: the action of its weapon or role, infused
# by its partners' strongest element. Its reach follows the action - a shooter's
# volley sweeps the three lanes ahead, an artillery strike the field ahead, a
# blast, bite or domain the cells around the plant - so a fire graft no longer
# sets the whole lawn ablaze from any body.

const ACTION := {"shooter":"barrage","sun":"solar","spread":"constellation","beam":"laser","lobber":"meteor","blade":"blades","roller":"bowling","bomb":"minefield","melee":"devour","guard":"bastion","control":"domain","support":"garden"}
const SCOPE := {"barrage":"lanes","laser":"lanes","blades":"lanes","bowling":"lanes","constellation":"front","meteor":"front"}
const AREA := {"lanes":"前方三行","front":"前方全场","radius":"周围3格"}
# The first tag (or tag pair) a hybrid carries becomes its infusion.
const INFUSIONS := [
	["samsara",["samsara"]],["tea_ceremony",["weaken"]],["reflection",["reflect"]],["steam",["fire","frost"]],["rail_storm",["magnet","shock"]],
	["dream",["hypno"]],["inferno",["fire"]],["blizzard",["frost"]],["lightning",["shock"]],["miasma",["poison"]],["spirits",["summon"]],
	["magnetic",["magnet"]],["roots",["root"]],["tornado",["wind"]],["vortex",["redirect"]],["purge",["grave"]],["spring",["cooling"]],
	["needles",["thorns"]],["beacon",["reveal"]],["renewal",["heal"]],["sun_lance",["sun","shot"]],["solar",["sun"]],["awakening",["awake"]],["bastion",["shield"]],
]
const CONDITIONAL := ["samsara","reflection","awakening","spring"]
const NOUN := {"barrage":"齐射","constellation":"星阵","laser":"光束","meteor":"天降","blades":"回旋","bowling":"冲阵","minefield":"爆田","devour":"吞噬","bastion":"城垒","solar":"丰收","garden":"花园","domain":"领域"}
const METEOR_NOUN := {"melon_pult":"瓜雨","skylight_melon":"瓜雨","fumarole_melon":"瓜雨","cabbage_pult":"菜雨","kernel_pult":"粒雨","corn_cannon":"炮击","pepper_mortar":"椒雨","chimney_pepper":"烟火","dandelion":"絮雨"}
const PREFIX := {
	"peashooter":"豌豆","sunflower":"向阳","cherry_bomb":"樱爆","wallnut":"坚壳","potato_mine":"地雷","snow_pea":"寒霜","chomper":"巨口","repeater":"双发",
	"puff_shroom":"孢雾","sun_shroom":"晨菇","fume_shroom":"喷雾","grave_buster":"噬墓","hypno_shroom":"魅惑","scaredy_shroom":"胆怯","ice_shroom":"冰封","doom_shroom":"末日",
	"squash":"重压","threepeater":"三叉","tangle_kelp":"缠海","jalapeno":"烈椒","spikeweed":"地刺","torchwood":"炬火","tallnut":"高垒","sea_shroom":"海孢",
	"plantern":"灯照","cactus":"仙刺","blover":"风车","split_pea":"回身","starfruit":"星芒","pumpkin":"南瓜","magnet_shroom":"磁暴","cabbage_pult":"菜叶",
	"kernel_pult":"黄油","coffee_bean":"醒神","garlic":"蒜香","umbrella_leaf":"伞护","marigold":"金盏","melon_pult":"西瓜","amber_shooter":"琥珀","vine_lasher":"藤鞭",
	"pepper_mortar":"椒炮","cactus_guard":"仙卫","pulse_bulb":"脉冲","sun_bean":"阳豆","wind_orchid":"风兰","moon_lotus":"月莲","prism_grass":"棱晶","lantern_bloom":"提灯",
	"meteor_gourd":"陨瓜","root_snare":"根缚","thunder_pine":"雷松","dream_drum":"梦鼓","storm_reed":"风雷","moonforge":"月炉","boomerang_shooter":"回旋","sakura_shooter":"樱瓣",
	"lotus_lancer":"莲矛","mirror_reed":"镜芦","frost_fan":"霜扇","origami_blossom":"折纸","chimney_pepper":"烟囱","tesla_tulip":"电郁","brick_guard":"砖垒","signal_ivy":"信号",
	"roof_vane":"风标","skylight_melon":"天窗","heather_shooter":"石楠","leyline":"地脉","holo_nut":"全息","healing_gourd":"回春","cotton_candy":"糖云","mango_bowling":"芒果",
	"snow_bloom":"雪绽","cluster_boomerang":"群刃","glitch_walnut":"故障","nether_shroom":"幽冥","seraph_flower":"炽天","magma_stream":"熔流","orange_bloom":"橙花","hive_flower":"蜂巢",
	"mamba_tree":"曼巴","chambord_sniper":"狙击","dream_disc":"梦盘","shadow_pea":"暗影","ice_queen":"冰后","vine_emperor":"藤皇","soul_flower":"魂花","plasma_shooter":"电浆",
	"crystal_nut":"晶壳","dragon_fruit":"龙焰","time_rose":"时光","galaxy_sunflower":"星河","void_shroom":"虚空","phoenix_tree":"凤炎","thunder_god":"雷神","prism_pea":"棱镜",
	"magnet_daisy":"磁菊","thorn_cactus":"棘刺","bubble_lotus":"泡莲","spiral_bamboo":"螺竹","honey_blossom":"蜜糖","echo_fern":"回声","glow_ivy":"萤藤","laser_lily":"激光",
	"rock_armor_fruit":"岩铠","aurora_orchid":"极光","blast_pomegranate":"爆榴","frost_cypress":"霜柏","mirror_shroom":"镜像","chain_lotus":"链刃","plasma_shroom":"等离","meteor_flower":"陨星",
	"destiny_tree":"命运","abyss_tentacle":"深渊","solar_emperor":"日皇","shadow_assassin":"影刺","core_blossom":"地核","holy_lotus":"圣莲","chaos_shroom":"混沌","dragon_bubble_pult":"龙泡",
	"cork_plug":"木塞","cyclone_grass":"旋草","sand_lotus":"沙莲","frost_boomerang":"霜刃","toxic_gum_pult":"毒胶","corn_cannon":"玉米","holy_flower":"圣光","ice_cream":"冰淇",
	"gator_cannon":"鳄炮","thermal_sunflower":"地热","obsidian_artichoke":"黑曜","steam_clover":"汽叶","pumice_wall":"浮岩","sulfur_pod":"硫磺","resonance_beet":"共振","pressure_bamboo":"蓄压",
	"fumarole_melon":"喷气","magnet_orchid":"磁兰","caldera_lotus":"火山","dandelion":"飞絮","jasmine_tea":"茶香","golden_milk":"奶浪","samsara_eye":"轮回","electric_bonk_choy":"雷拳",
	"glowvine":"光藤","anchor_fern":"锚蕨","mist_orchid":"雾兰","brine_pot":"盐沼",
}
const ACTION_TEXT := {
	"barrage":"所有持续武器立即齐射，并以0.45秒间隔追击两轮，保留各自弹道与锁敌",
	"constellation":"星弹、花瓣与环射立即全开，并追击两轮",
	"laser":"光束武器立刻满功率贯穿，并追击两轮",
	"meteor":"各投手立即抛出强化弹并追击两轮，保留落点追踪与原弹种",
	"blades":"回旋武器齐出并追击两轮，去程与回程都能命中",
	"bowling":"滚出强化果轮，沿途连续撞击",
	"minefield":"所有爆舱立刻引爆，保留圆形、整行或近身范围，随后重新充能",
	"devour":"重咬身边最强的两个敌人，并回复自身25%生命",
	"bastion":"周围植物回复生命、获得护盾与2秒无敌",
	"solar":"立刻产出三份强化阳光",
	"garden":"治疗自身与邻株，赋予十秒加速及护盾",
	"domain":"展开灵域，重创周围3格内敌人，定身3秒并减速",
}
# Every combat ultimate opens with a strike of its own, so a click always lands.
const STRIKE_TEXT := {
	"barrage":"起手对前方三行敌人各重击一次","blades":"起手对前方三行敌人各重击一次","laser":"起手贯穿前方三行敌人",
	"bowling":"起手撞击前方三行敌人","meteor":"起手轰击最靠近房子的6个敌人","constellation":"起手星落最靠近房子的6个敌人",
	"minefield":"起手炸伤周围3格敌人，范围内无敌人时炸向本行最近的敌人","bastion":"起手震退周围3格敌人并眩晕1秒",
}
const INFUSION_TEXT := {
	"inferno":"{area}燃起烈焰，敌人灼烧8秒","blizzard":"{area}敌人减速5秒并冻结1秒","lightning":"{area}降下连锁电击并短暂震晕",
	"miasma":"{area}弥漫毒雾，持续毒蚀并追加两次毒爆","steam":"冰火相激，{area}三次蒸汽爆炸并灼烧","rail_storm":"回收金属后向{area}发射磁轨雷束",
	"dream":"{area}普通敌人被梦蝶魅惑，首领受定身","roots":"全场敌人被缠根定身4秒，{area}爆发荆棘","tornado":"{area}普通敌人被吹退、飞行敌人坠落，并吹散浓雾",
	"vortex":"{area}普通敌人被推退并换到合法邻行","purge":"清除周围坟墓，{area}净土爆炸","needles":"{area}落下穿盾刺雨",
	"beacon":"全场显形，{area}敌人受光束审判","sun_lance":"产出阳光，并以日轮光束贯穿{area}","magnetic":"回收周围金属护具并释放磁轨光束",
	"renewal":"周围植物回复生命并获得8秒回春","spirits":"召唤至多三名幽灵友军","spring":"冷却周围岩浆并获得护盾",
	"awakening":"唤醒周围睡眠植物并加速十秒","reflection":"反转场上敌方弹幕，周围植物获得3秒镜盾","solar":"额外产出三份强化阳光",
	"bastion":"周围植物获得护盾与2秒无敌","tea_ceremony":"前方三行六列腐蚀12秒，敌人虚弱并受到茶浪伤害","samsara":"复活周围15秒内倒下的植物，原格有植物时与之融合",
}


static func _provider(tags: Array, parts: Array, prefer: Array, traits_of: Dictionary) -> String:
	for group in [prefer, parts]:
		for part in group:
			for tag in tags:
				if tag in traits_of[part]: return part
	return ""


# Returns {skills, name, description} for a hybrid.
const WARHEAD_TEXT := {"cherry_bomb":"齐射弹药带樱桃弹头，命中小范围爆炸","doom_shroom":"齐射弹药带暗爆弹头","jalapeno":"齐射弹药持续灼烧"}

static func compose(style: String, parts: Array, weights: Dictionary, traits: Array, traits_of: Dictionary, attack_of: Dictionary, explicit_name: String, has_bursts: bool, has_weapons: bool, warheads: Array = []) -> Dictionary:
	var action: String = ACTION[style]
	# A body counted as a weapon but carrying none (a bare torch stump) commands its ground instead.
	if action in ["barrage","constellation","laser","meteor","blades","bowling"] and not has_weapons: action = "domain"
	var scope: String = SCOPE.get(action,"radius")
	var actors: Array = []
	var partners: Array = []
	var distinct: Array = weights.keys(); distinct.sort()
	for part in distinct:
		if attack_of[part] == style: actors.append(part)
		else: partners.append(part)
	var limit: int = 2 if distinct.size() >= 3 else 1
	var conditional_limit: int = limit
	var infusions: Array = []
	var sources: Array = []
	var counted := 0
	var conditional := 0
	for entry in INFUSIONS:
		if counted >= limit: break
		var skill: String = entry[0]
		if skill == action: continue
		var needed: Array = entry[1]
		if not needed.all(func(tag): return tag in traits): continue
		# Combinations swallow their single-element forms.
		if skill in ["inferno","blizzard"] and "steam" in infusions: continue
		if skill in ["magnetic","lightning"] and "rail_storm" in infusions: continue
		if skill == "solar" and "sun_lance" in infusions: continue
		# At most one waiting effect (revival, reflection, waking, cooling) per pair of materials.
		if skill in CONDITIONAL and conditional >= conditional_limit: continue
		var source: String = _provider(needed, distinct, partners, traits_of)
		infusions.append(skill); sources.append(source)
		# Revival, reflection, waking and cooling only act when needed; a combat infusion still follows.
		if skill in CONDITIONAL: conditional += 1
		else: counted += 1
	var name := explicit_name
	if name.is_empty():
		var noun: String = NOUN[action]
		if action == "meteor":
			for part in actors:
				if METEOR_NOUN.has(part): noun = METEOR_NOUN[part]; break
		var lead := ""
		# The partner that changed the move names it; a weapon's own element never renames itself.
		if not sources.is_empty() and String(sources[0]) in partners: lead = sources[0]
		elif not partners.is_empty(): lead = partners[0]
		else:
			# Two weapons of one kind: the less plain of them names the move.
			for part in actors:
				if part != "peashooter": lead = part
			if lead.is_empty() and not actors.is_empty(): lead = actors.back()
		if distinct.size() == 1:
			var count: int = int(weights[distinct[0]])
			name = ("双生" if count == 2 else ("三生" if count == 3 else "共鸣"))+noun
		else: name = String(PREFIX.get(lead,"共生"))+noun
	var area: String = AREA[scope]
	var parts_text: Array = [ACTION_TEXT[action]]
	if STRIKE_TEXT.has(action) and not (action == "minefield" and has_bursts): parts_text.append(STRIKE_TEXT[action])
	if action == "minefield" and has_bursts: parts_text.append("爆炸范围内没有敌人时，炸向本行附近最近的敌人")
	if has_bursts and action != "minefield": parts_text.append("所有爆舱同时引爆")
	for source in warheads:
		if WARHEAD_TEXT.has(source): parts_text.append(WARHEAD_TEXT[source])
	for skill in infusions: parts_text.append(String(INFUSION_TEXT[skill]).replace("{area}",area))
	if has_weapons and action in ["minefield","devour","bastion","solar","garden","domain"]: parts_text.append("持续武器随后追击两轮")
	return {"skills":[action]+infusions,"name":name,"description":"；".join(parts_text)+"。"}
