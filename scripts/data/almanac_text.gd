extends RefCounted
class_name AlmanacText

const PlantDefs = preload("res://scripts/data/plant_defs.gd")


static func plant_lines(kind: String) -> Array:
	match kind:
		"peashooter":
			return ["基础直线输出，看到前方威胁就会持续开火。", "能量豆后进入豌豆风暴，短时间高速连射。"]
		"sunflower":
			return ["稳定生产 50 阳光，是白天关卡的经济核心。", "能量豆会立刻喷出一串阳光。"]
		"cherry_bomb":
			return ["短暂引信后爆炸，清掉一大片敌人和障碍。", "能量豆会扩大爆炸范围。"]
		"wallnut":
			return ["高耐久肉盾，负责拖住前排。", "能量豆提供额外护甲。"]
		"potato_mine":
			return ["埋下后需要时间起爆，成熟后对近身敌人造成高额伤害。", "能量豆会立刻武装并触发连环雷区。"]
		"snow_pea":
			return ["寒冰豌豆附带减速，适合稳住整路节奏。", "能量豆期间变成冰豆风暴。"]
		"chomper":
			return ["近距离一口吞掉僵尸，之后需要长时间咀嚼。", "能量豆会连续吞掉前方多只僵尸。"]
		"repeater":
			return ["一次开两枪，持续输出强于普通豌豆射手。", "能量豆会打出超高速双发弹幕。"]
		"amber_shooter":
			return ["自定义中坚射手，单发伤害更高。", "能量豆后进入强化连射。"]
		"vine_lasher":
			return ["中近距离鞭击，命中后还能短暂减速。", "能量豆会抽击一整排并清掉障碍。"]
		"pepper_mortar":
			return ["整行锁定最前方威胁，喷出细长的高温火焰束精准点杀。", "能量豆会连续重炮轰击该路。"]
		"cactus_guard":
			return ["高耐久防御植物，接触敌人会反刺。", "能量豆会立刻补满并套上厚护甲。"]
		"pulse_bulb":
			return ["周期性对范围内造成脉冲伤害。", "能量豆会立刻释放更大的电磁脉冲。"]
		"sun_bean":
			return ["兼顾产阳光和远程输出的混合型植物。", "能量豆会额外喷出更多阳光。"]
		"wind_orchid":
			return ["周期性吹退整路僵尸，并清空路上障碍。", "能量豆会制造更强的阵风清线。"]
		"wallnut_bowling":
			return ["保龄球模式专用植物，放下后沿草坪滚动碾压。", "该模式下由传送带直接提供。"]
		"puff_shroom":
			return ["夜晚零费短射程输出，适合前期过渡。", "能量豆后会高速喷出一整串孢子。"]
		"sun_shroom":
			return ["先产出 25 阳光，长大后恢复为 50 阳光。", "能量豆会立刻成熟并喷出额外阳光。"]
		"fume_shroom":
			return ["喷出穿透整段走廊的烟雾，能穿过手持护具。", "能量豆会释放更长更厚的一次性烟浪。"]
		"grave_buster":
			return ["只能种在坟墓上，几秒后直接把坟墓吞掉。", "能量豆会把全场坟墓一起吞光并返还资源。"]
		"hypno_shroom":
			return ["魅惑型蘑菇，适合针对高威胁近身敌人。", "能量豆会对周围多只僵尸施加精神冲击。"]
		"scaredy_shroom":
			return ["火力不错，但僵尸靠太近时会缩起来停止攻击。", "能量豆时会无视惊吓并高速开火。"]
		"ice_shroom":
			return ["引爆后冻结整场僵尸，并留下较长减速。", "能量豆会延长冻结和减速时间。"]
		"doom_shroom":
			return ["超大范围爆炸蘑菇，适合清理夜晚重压。", "能量豆会把范围和伤害再抬一档。"]
		"moon_lotus":
			return ["夜晚经济植物，会稳定产出 50 阳光。", "能量豆会喷出月华并叫醒全场植物。"]
		"prism_grass":
			return ["棱镜束会穿透一整排多个目标，并附带寒霜减速。", "能量豆后会射出更长更重的冰棱贯穿光束。"]
		"lantern_bloom":
			return ["提灯脉冲会伤害近处敌人，并唤醒附近友军。", "能量豆会爆出更大范围的照明震荡。"]
		"meteor_gourd":
			return ["会锁定全场最前方威胁落下陨星砸击。", "能量豆会连续召唤三发陨星。"]
		"root_snare":
			return ["用缠根拖住高速僵尸，并顺带造成小额伤害。", "能量豆会把大片敌人全部定在原地。"]
		"thunder_pine":
			return ["命中后会把雷电连到周围其他僵尸。", "能量豆会对每一路最前方目标同步落雷。"]
		"dream_drum":
			return ["鼓声会震晕附近僵尸并叫醒大范围植物。", "能量豆会唤醒全场并群体震退僵尸。"]
		"lily_pad":
			return ["水路支撑植物，给多数陆地植物提供下水的平台。", "能量豆会把水路空位快速铺满睡莲。"]
		"squash":
			return ["看到近身目标后会高高跳起重压一击。", "能量豆会连续锁定附近多只目标。"]
		"threepeater":
			return ["同时向本路、上一路和下一路发射豌豆。", "能量豆会在三路同时进入豌豆风暴。"]
		"tangle_kelp":
			return ["只能种在水里，贴身后会把僵尸拖下水。", "能量豆会在附近水路连续拖走多只目标。"]
		"jalapeno":
			return ["点燃整整一行，适合清掉泳池横向长线。", "能量豆会把火焰扩到相邻水路。"]
		"spikeweed":
			return ["不会拦路，但会持续扎伤踩上来的僵尸。", "能量豆会让整路地刺一起暴刺。"]
		"torchwood":
			return ["穿过它的豌豆会变成火球，伤害更高。", "能量豆会在整路打出火焰弹幕。"]
		"tallnut":
			return ["比坚果墙更厚，还能挡住撑杆和海豚跳跃。", "能量豆会立刻补满并叠上重甲。"]
		"sea_shroom":
			return ["海蘑菇只能直接种在水里，射程和原版一样偏短。", "能量豆会在短时间内向前方高速喷射孢子。"]
		"plantern":
			return ["路灯花会稳定驱散附近迷雾，让隐在雾里的敌人重新暴露。", "能量豆会把整片后院暂时照亮。"]
		"cactus":
			return ["仙人掌负责整路直线输出，也是浓雾时代最可靠的对空气球单位。", "能量豆会进入密集针雨并优先击落空中目标。"]
		"blover":
			return ["三叶草种下后会立刻吹散迷雾，并把气球僵尸整批吹走。", "能量豆会延长清雾时间并附带更强的吹飞冲击。"]
		"split_pea":
			return ["裂荚射手会同时照顾前后两个方向，后脑勺也会持续喷豆。", "能量豆会把前后双路都升级为连续火力风暴。"]
		"starfruit":
			return ["杨桃每次会朝五个固定方向发射星弹，能同时覆盖斜线与后场。", "能量豆会让星弹变得更密更亮，持续扫满整片场地。"]
		"pumpkin":
			return ["南瓜头会给格子里的植物额外套上一层厚壳。", "能量豆会立刻修满南瓜并额外加固。"]
		"magnet_shroom":
			return ["磁力菇会周期性吸走附近僵尸的金属装备。", "能量豆会发动整片区域的强制缴械。"]
		"boomerang_shooter":
			return ["回旋镖会沿直线最多命中前三只僵尸，然后折返再打同一批目标。", "能量豆会连续掷出强化回旋镖。"]
		"sakura_shooter":
			return ["樱花子弹命中后会向右上与右下分裂，形成持续扩散火力。", "能量豆会把花弹升级成三向樱潮。"]
		"lotus_lancer":
			return ["莲矛花每隔一会就会朝八个方向打出旋转扩散的莲花炮，炮弹会绕着本体外旋再扑向尸群。", "点击大招和能量豆都会锁定当前血量最高的僵尸，在它周围布下二十四发莲炮后同时收束轰杀。"]
		"mirror_reed":
			return ["镜芦苇会把百里守约这类射击僵尸的子弹折回去，替前排挡下远程点杀。", "大招会在前方唤出尚博乐狙击枪虚影，立刻补上一轮高伤狙击。"]
		"frost_fan":
			return ["霜扇草会朝前方三路扇出寒雾，边打边减速。", "能量豆会把霜风扩大成覆盖全场的寒潮。"]
		"cabbage_pult":
			return ["卷心菜投手会把抛物线菜叶砸到前方尸群头上，适合屋顶这种平射受限的地形。", "能量豆会让它短时间连续抛射，快速压低整路前场血线。"]
		"flower_pot":
			return ["花盆是屋顶与特殊地皮的基础种植台，没有它，很多位置根本放不下主力植物。", "能量豆会把附近可用地块快速补成临时种植位，方便你立即重建阵型。"]
		"kernel_pult":
			return ["玉米投手会交替抛出玉米粒和黄油，黄油命中时还能把目标直接糊在原地。", "能量豆会提高黄油压制频率，让前线连续陷入停顿。"]
		"coffee_bean":
			return ["咖啡豆专门叫醒夜行植物，让它们在白天和其他特殊场景里也能立刻投入战斗。", "能量豆会把附近仍在沉睡的植物一起唤醒，并短暂提高它们的作战节奏。"]
		"garlic":
			return ["大蒜会把啃到它的僵尸挤去相邻线路，是调度尸潮走位的经典转线前排。", "能量豆会把附近多只贴脸僵尸一起挤开，快速重排前线。"]
		"umbrella_leaf":
			return ["叶子保护伞会替周围植物挡下来自空中和抛射方向的偷袭，专门克制后场拆阵。", "能量豆会把保护范围暂时撑到更大，并顺带弹开一轮落下来的威胁。"]
		"marigold":
			return ["金盏花偏向长期收益，会稳定产出资源，适合在压力较低的关卡慢慢滚优势。", "能量豆会立刻喷出一波额外收益，让你更快完成阵容补强。"]
		"melon_pult":
			return ["西瓜投手会把重型瓜弹砸向目标，落点附近的尸群也会一起吃到溅射伤害。", "能量豆会让它进入重瓜连投状态，把整路前线持续砸穿。"]
		"mist_orchid":
			return ["雾兰会朝本行前方喷出雾团，命中后还会在小范围内显形并溅射。", "能量豆会让整行进入高频雾暴，持续显形并减速。"]
		"anchor_fern":
			return ["锚蕨会用锚链抽击近中程目标，并让附近植物短暂扎根防推。", "能量豆会让整行植物全部扎根并附带重锚横扫。"]
		"glowvine":
			return ["荧藤花的孢子会在命中后裂向上下两路，适合处理雾中多线威胁。", "能量豆会把裂变孢子升级成连续的荧光雨。"]
		"brine_pot":
			return ["盐沼壶会把泥壶抛向最前线，命中后留下持续减速的泥潭。", "能量豆会连续投出三枚强化泥壶，把前线变成大片沼泽。"]
		"storm_reed":
			return ["风暴芦会优先盯住右侧中场闯入的敌人，用电弧快速点杀入场单位。", "能量豆会在全场连续落下链式闪击。"]
		"moonforge":
			return ["月炉花会蓄力打出爆裂月焰，是浓雾终章的高压炮台。", "能量豆会让炉心过载，连续发射高伤月焰。"]
		"origami_blossom":
			return ["折纸花会放出整路巡航的纸燕，地面与空中目标都会被盯上。", "能量豆会把纸燕升级成连续出击的折纸风暴。"]
		"chimney_pepper":
			return ["烟囱椒炮会朝屋顶前方抛出爆裂火团，落地后还能顺带灼烧附近目标。", "能量豆会触发一轮短促但高压的火团连射。"]
		"tesla_tulip":
			return ["特斯拉郁金香会优先电击本路最前方目标，再把电弧串到附近僵尸身上。", "能量豆会在全场连续放出强化链雷。"]
		"brick_guard":
			return ["砖卫是屋顶延长战的厚重防线，适合扛住扶梯、炮塔和巨人的持续拆阵。", "能量豆会立即补满砖层并叠上一层更厚的护甲。"]
		"signal_ivy":
			return ["信号常春藤会周期性打出脉冲，顺带显形隐蔽与空中单位。", "能量豆会把信号塔扩成大范围高频扫描。"]
		"roof_vane":
			return ["风向草会顺着屋顶风道把整路敌人往后推，适合稳住高压中场。", "能量豆会掀起一阵更远更强的屋脊狂风。"]
		"skylight_melon":
			return ["天窗瓜炮会把重瓜投到前场上空，爆裂后还能顺带压到邻近线路。", "能量豆会把屋顶变成连续坠落的重瓜雨。"]
		"heather_shooter":
			return ["石楠花射手会给目标挂上持续腐蚀，并在命中时附带极短眩晕。", "能量豆会把前方整片街区变成连续腐蚀弹幕。"]
		"leyline":
			return ["地脉会从地底掀起整行脉冲，把同一路敌人全部震到。", "能量豆会让地下管网连锁共振，多次横扫整路。"]
		"holo_nut":
			return ["全息坚果会自动修复受损外壳，是城市世界的续航前排。", "能量豆会立刻补满护壳，并短时间提升减伤。"]
		"healing_gourd":
			return ["治愈葫芦会周期性为周围植物回春，适合维持长线阵地。", "能量豆会向周围倾倒甘露，瞬间抬起一圈血线。"]
		"mango_bowling":
			return ["芒果保龄球会把滚动重果砸向前方，并顺带波及邻行目标。", "能量豆会连续掷出强化芒果，把前场滚成连锁撞击。"]
		"snow_bloom":
			return ["雪中花会把脚下格子暂时冻成雪地，逼着你用花盆重建站位。", "能量豆会把更大区域一起封成寒霜地带。"]
		"cluster_boomerang":
			return ["聚集回旋镖会在周围 3x3 持续织出旋转封锁网，最多维持十枚回旋镖。", "能量豆会把整片近场升级成高密度回旋力场。"]
		"glitch_walnut":
			return ["失真核桃撑一段时间后会自行崩解，并给全场敌人施加随机异常。", "能量豆会把异常升级成一轮更强的全图清算。"]
		"nether_shroom":
			return ["冥界蘑菇会周期性从身边叫出一只魅惑铁桶，直接反咬尸潮。", "能量豆会把召唤升级成短时间连续倒戈列阵。"]
		"seraph_flower":
			return ["炽天使花会朝前方三行抛出贯穿长矛，能同时压住中路与上下相邻线路。", "能量豆会把圣矛升级成高速连发的炽羽裁决。"]
		"magma_stream":
			return ["流水花落地后会把脚下格子熔成岩浆，自己很快凋零，但熔浆会继续烧路。", "能量豆会让附近街面一起喷涌成灼热熔流。"]
		"orange_bloom":
			return ["橙汁花会把整行前压目标打成果汁爆浆，并顺带溅到附近尸群。", "能量豆会让整路连续爆开高压橙汁浪。"]
		"hive_flower":
			return ["密蜂花会盯住当前最靠前的僵尸放出蜂群，专门补刀卡线重装。", "能量豆会让蜂后直接下场，短时间连点前场多目标。"]
		"mamba_tree":
			return ["曼巴树会把脚下格子烧成煤炭陷阱，踩上来的僵尸会持续凋零。", "能量豆会把邻近几格一起炭化成毒火带。"]
		"chambord_sniper":
			return ["尚博勒狙击枪会锁定本行最前方敌人，目标越接近房子，狙击伤害越高。", "能量豆会切进连狙姿态，把前场高威胁单位快速点掉。"]
		"dream_disc":
			return ["梦中碟是一次性控场植物，会把附近僵尸直接拖进睡眠。", "能量豆会把梦域扩成更大范围的沉眠力场。"]
		_:
			return _fallback_plant_lines(kind)


static func _fallback_plant_lines(kind: String) -> Array:
	var plant_def: Dictionary = PlantDefs.PLANTS.get(kind, {})
	if plant_def.is_empty():
		return ["图鉴资料同步中。", "该植物的正式说明会在后续版本里补齐。"]
	var plant_name := String(plant_def.get("name", kind))
	return [
		_describe_plant_role(plant_name, plant_def),
		_describe_plant_ultimate(plant_def),
	]


static func _describe_plant_role(plant_name: String, plant_def: Dictionary) -> String:
	var health := float(plant_def.get("health", 0.0))
	if bool(plant_def.get("water_only", false)):
		return "%s是水路专用单位，主要负责补足泳池线路的火力或功能空位。" % plant_name
	if plant_def.has("sun_interval"):
		if plant_def.has("shoot_interval") or plant_def.has("attack_interval") or plant_def.has("pulse_interval"):
			return "%s兼顾资源与战斗节奏，能一边滚阳光一边给前线持续施压。" % plant_name
		return "%s偏向经济与辅助，会稳定提供资源，帮你更快搭起完整阵容。" % plant_name
	if health >= 3500.0 or plant_def.has("shield_hp") or plant_def.has("armor_layers") or plant_def.has("reflect_ratio") or plant_def.has("regen"):
		return "%s属于高耐久防线植物，职责是拖住尸潮并保护后排关键输出。" % plant_name
	if plant_def.has("heal_interval") or plant_def.has("support_interval") or plant_def.has("wake_radius"):
		return "%s偏向辅助定位，会给附近植物提供治疗、护盾或功能增益。" % plant_name
	if plant_def.has("freeze_duration") or plant_def.has("slow_duration") or plant_def.has("slow_ratio") or plant_def.has("sleep_duration") or plant_def.has("root_duration"):
		return "%s擅长控场，能靠冻结、减速、沉睡或定身把敌人的推进节奏拖慢。" % plant_name
	if plant_def.has("reveal_range") or plant_def.has("reveal_radius"):
		return "%s兼顾侦测与压制，能把隐蔽目标扫出来并稳定住周围线路。" % plant_name
	if plant_def.has("pull_interval") or plant_def.has("pull_strength") or plant_def.has("pull_distance"):
		return "%s会扰乱尸群站位，把已经成形的推进队列重新拉散。" % plant_name
	if plant_def.has("magma_dps") or plant_def.has("ember_dps") or plant_def.has("burn_damage") or plant_def.has("burn_duration"):
		return "%s更偏持续灼烧与地形压制，适合把敌人拖进长时间掉血状态。" % plant_name
	if plant_def.has("charge_time") or plant_def.has("beam_duration"):
		return "%s属于蓄力型炮台，出手不快，但每一轮命中都带着很强的爆发。" % plant_name
	if plant_def.has("shoot_interval"):
		if plant_def.has("chain_damage") or plant_def.has("split_count") or plant_def.has("pierce_count") or plant_def.has("max_hits") or bool(plant_def.get("homing", false)):
			return "%s属于远程特化输出，弹道会分裂、连锁、追踪或折返，适合处理中后场多目标。" % plant_name
		return "%s是稳定远程火力点，会持续朝前方输出，负责把整路压力压在中后场。" % plant_name
	if plant_def.has("attack_interval"):
		if plant_def.has("cone_range") or plant_def.has("cone_width"):
			return "%s会对前方扇形区域施压，适合处理中近距离成群目标。" % plant_name
		if plant_def.has("range"):
			return "%s会在射程内周期性主动出手，兼顾稳定伤害与功能压制。" % plant_name
		return "%s会按固定节奏主动出手，用独特机制反复干扰前线。" % plant_name
	if plant_def.has("pulse_interval") and plant_def.has("radius"):
		return "%s依赖范围脉冲作战，能在固定节奏里同时碰到一片尸群。" % plant_name
	if plant_def.has("radius"):
		return "%s更偏范围控场或一次性爆发，适合在小片区域里迅速改变战局。" % plant_name
	return "%s拥有独特定位，会围绕自身机制持续改变当前战局节奏。" % plant_name


static func _describe_plant_ultimate(plant_def: Dictionary) -> String:
	var prefix := ""
	if bool(plant_def.get("gacha_only", false)):
		prefix = "%s抽卡植物，" % _rarity_label(String(plant_def.get("rarity", "")))
	if plant_def.has("ultimate_name"):
		return "%s点击大招「%s」会把它的核心能力瞬间推到极限。" % [prefix, String(plant_def.get("ultimate_name", ""))]
	return "%s能量豆会进一步放大它的主要作用。" % prefix


static func _rarity_label(rarity: String) -> String:
	match rarity:
		"purple":
			return "紫卡"
		"orange":
			return "橙卡"
		"gold":
			return "金卡"
		_:
			return "特殊"


static func zombie_lines(kind: String) -> Array:
	match kind:
		"normal":
			return ["最基础的僵尸，没有额外能力。", "任何防线的默认压力来源。"]
		"flag":
			return ["大波来袭时的领头僵尸。", "通常意味着这一批会更密更重。"]
		"conehead":
			return ["头顶路障，耐久明显高于普通僵尸。", "需要更稳定的持续火力。"]
		"pole_vault":
			return ["第一次遇到植物会越过去。", "前排垫子容易被它直接跳过。"]
		"buckethead":
			return ["铁桶提供很高耐久，是典型重装单位。", "需要集火或爆发植物处理。"]
		"newspaper":
			return ["先举着报纸推进，报纸会先替它挡伤害。", "报纸被打碎后会暴走提速，和原版读报类似。"]
		"screen_door":
			return ["铁门会先承受前方伤害，等同一层高耐久护具。", "护具打碎后才会真正开始掉本体血量。"]
		"football":
			return ["橄榄球僵尸速度和耐久都很高。", "很适合用爆炸、控制或高 DPS 卡快速处理。"]
		"dark_football":
			return ["暗黑橄榄球僵尸和普通橄榄球一样快，但生命值翻倍。", "黑色头盔只是外观差异，真正麻烦的是它更长的前压时间。"]
		"dancing":
			return ["舞王进入舞台后会召唤伴舞。", "会在附近位置持续补足伴舞人数，被魅惑后召来的伴舞也会倒戈。"]
		"backup_dancer":
			return ["由舞王召唤的随从单位。", "会继承舞王的阵营，单体不强，但会迅速占满前线空间。"]
		"farmer":
			return ["农夫僵尸会边走边往前方格子撒杂草。", "杂草本身也需要植物主动拆掉。"]
		"spear":
			return ["长矛僵尸倒下后会留下标枪障碍。", "标枪打碎后还会在原地爬出普通僵尸。"]
		"kungfu":
			return ["功夫僵尸会周期性进入反弹状态。", "气功期间会反射前方飞来的子弹。"]
		"day_boss":
			return ["白天 Boss 会分阶段提速、召援和压前排。", "爆炸植物也只能削血，不能直接秒杀。"]
		"night_boss":
			return ["暗夜尸王会在夜战中召夜行僵尸、升起新坟墓并让植物入睡。", "这是 2-17 传送带关的压轴 Boss，需要持续解场和稳定控场。"]
		"pool_boss":
			return ["玄潮尸王是泳池世界的最终 Boss，会把水路与陆路新僵尸一起压上战场。", "它的技能节奏沿用大战式 Boss 结构，但会更强调龙舟冲锋、地面封锁与多线压迫。"]
		"fog_boss":
			return ["雾岚尸王是浓雾世界的最终 Boss，会在右侧持续召来浓雾时代和后院体系的高压混编。", "它的技能会把前线变成大片盐沼，还会在阶段切换时进一步压缩你的站位空间。"]
		"roof_boss":
			return ["穹顶尸王是屋顶世界的最终 Boss，会在右侧不断投下屋顶时代和扩展屋顶时代的混编尸潮。", "它的技能围绕瓦顶轰炸、工程封锁和后场空投展开，节奏比普通屋顶关更强调持续解场。"]
		"city_boss":
			return ["霓虹尸王是城市世界的最终 Boss，会把几乎全部非 Boss 僵尸一口气混进同一场暴风雪终章。", "它会反复召来整城尸潮、封锁街区格位，并用霓虹冲击波持续压缩你的阵型。"]
		"rumia_boss":
			return ["露米娅不会像普通僵尸那样前压，而是固定盘旋在右侧上空。", "她会轮流施放月光光束、夜鸟弹幕、黑暗结界并召唤眷属，是 1-17 血月支线的最终目标。"]
		"daiyousei_boss":
			return ["大妖精会在 1-18 半程拦截战场，冻结进度并持续撒出环形冰羽。", "只要她还活着，寒湖支线的推进就不会继续。"]
		"cirno_boss":
			return ["琪露诺会在右侧上空盘旋施放冰系符卡，并在登场时把左侧湖面完全冻住。", "她的冰锥、完美冻结和钻石暴风雪会让前排同时承受减速与范围压制。"]
		"meiling_boss":
			return ["红美铃会在右侧天际线持续游走，用红雾气劲和近身掌风轮番压场。", "她是 1-19 红雾特别关的最终 Boss，入场前后还会切换专属 BGM 并持续召来白天尸潮。"]
		"koakuma_boss":
			return ["小恶魔会在 1-20 的血色图书馆半程拦住进度，用魔导书弹幕、使魔群和召唤拖住战线。", "只要她还活着，帕秋莉所在的终幕就不会开始推进。"]
		"patchouli_boss":
			return ["帕秋莉会固定盘旋在图书馆右侧，以火、水、风、金与大范围爆裂魔法轮番压场。", "她是 1-20 图书馆特别关的最终 Boss，会一边施法一边持续召来红魔馆混编尸潮。"]
		"sakuya_boss":
			return ["十六夜咲夜会在空中悬停换行，用飞刀、时停、传送和召援把战场切成银色弹幕。", "她既会作为 1-21 的终幕 Boss，也会在 1-22 的半程拦住推进。"]
		"remilia_boss":
			return ["蕾米莉亚会在猩红长夜里持续压低全场植物血线，并以红魔枪雨、命运压场和蝙蝠群轮番施法。", "她是 1-22 的最终 Boss，会在右侧高空悬停并持续召来红魔馆混编尸潮。"]
		"ninja":
			return ["忍者僵尸前半程慢走，半血后会换行突进。", "残血阶段机动性明显更强。"]
		"basketball":
			return ["篮球僵尸自带一层会回充的护盾。", "破盾后若没及时处理，会重新张开护盾。"]
		"nezha":
			return ["哪吒僵尸会直接飞扑到中后排植物身边。", "落地后的风火轮会持续灼烧周围植物。"]
		"nether":
			return ["冥界僵尸会优先从墓碑附近钻出。", "灯火会让周围植物短暂睡眠，被魅惑后则会反过来催眠僵尸。"]
		"ducky_tube", "lifebuoy_normal":
			return ["基础救生圈僵尸，会在泳池水路里持续推进。", "本体不强，但会把水路压力常态化。"]
		"lifebuoy_cone":
			return ["头顶路障的救生圈僵尸，比普通版更能扛。", "适合和潜水僵尸一起把水路前排拖长。"]
		"lifebuoy_bucket":
			return ["铁桶救生圈僵尸是泳池里的重装单位。", "如果没有集中火力，水路很容易被它慢慢压穿。"]
		"snorkel":
			return ["潜水时能躲掉大多数直线攻击。", "靠近植物后才会上浮并开始啃咬。"]
		"balloon_zombie":
			return ["气球僵尸会飘在空中越过大多数地面阻挡。", "只有仙人掌或三叶草这类对空手段能稳定处理它。"]
		"digger_zombie":
			return ["矿工僵尸会先从右侧地下掘进，绕到后场再翻出地面。", "磁力菇能直接吸走它的工具，让它提前失去绕后能力。"]
		"pogo_zombie":
			return ["跳跳僵尸会连续越过前排植物。", "高坚果和磁力菇都能让它失去继续跳跃的资本。"]
		"jack_in_the_box_zombie":
			return ["小丑盒僵尸一边前进一边倒计时，时间一到就会在周围引爆。", "磁力菇能提前拆掉盒子，把它变回普通近战威胁。"]
		"bungee_zombie":
			return ["蹦极僵尸会从天上垂下来，优先抓走没有被伞叶保护的植物。", "它的威胁在于直接拆关键阵眼，而不是正面硬推。"]
		"ladder_zombie":
			return ["扶梯僵尸会把梯子架到高阻挡植物前。", "梯子一旦放下，后面的僵尸就能快速翻过原本很稳的前排。"]
		"catapult_zombie":
			return ["投石车僵尸会隔着整路往后场抛石块，优先砸掉靠右的重要植物。", "如果不尽快处理，后排会被它慢慢拆空。"]
		"gargantuar":
			return ["巨人僵尸拥有极高耐久和重击，近身后会快速拆掉前排。", "血量压到一半后，它还会把小鬼直接扔进你的阵线。"]
		"imp":
			return ["小鬼僵尸是巨人抛出的高速小体型单位。", "单体不厚，但落点突然，很容易钻进后排补刀。"]
		"zomboni":
			return ["会一路碾压植物并在身后留下冰道。", "地刺和火爆辣椒都非常适合针对它。"]
		"bobsled_team":
			return ["会借着冰道高速突进的一整队雪橇僵尸。", "一旦进场，前线压力会突然拉满。"]
		"dolphin_rider":
			return ["和撑杆类似，会骑海豚越过第一株植物。", "高坚果能像原版那样把它拦下来。"]
		"dragon_boat":
			return ["龙舟僵尸会从水路深处突然浮现，前冲时还能直接碾碎植物。", "它的划行节奏是前两格后退一格，水路压迫感很强。"]
		"qinghua":
			return ["青花瓷护具比报纸更耐打，碎裂后还会在地面留下暂时不能种植的碎片。", "它还能套救生圈走水路。"]
		"shouyue":
			return ["百里守约僵尸默认半隐身，普通子弹和直线锁定都抓不到它。", "必须被照明或前方植物卡出轮廓后，才能稳定集火。"]
		"ice_block":
			return ["手里的冰块不打碎，它就会定期铺在脚下形成冰面。", "陆路和水路都能留下冰块地形。"]
		"dragon_dance":
			return ["舞龙僵尸是一整串高速重装单位，推进速度接近橄榄球。", "它的龙身很长，视觉压迫和占位都比普通快尸更凶。"]
		"squash_zombie":
			return ["窝瓜僵尸会像重压植物那样突然跳起，落地后直接砸毁目标区域植物。", "看到它开始蓄力时，留给防线反应的时间不会太多。"]
		"excavator_zombie":
			return ["挖掘机僵尸不会老老实实啃咬，而是先用铲斗把植物整排往前推。", "如果左侧没有空位，最前端植物会被直接推出草坪。"]
		"barrel_screen_zombie":
			return ["桶杠门僵尸同时带着铁桶和铁门，是浓雾后段的纯重装墙。", "没有高伤或拆甲手段时，它会把前线拖得非常长。"]
		"tornado_zombie":
			return ["龙卷风僵尸会先被旋风卷入后场，再从中场落地慢慢前压。", "它最大的威胁不是血量，而是突然出现的位置。"]
		"wolf_knight_zombie":
			return ["骑士僵尸会骑狼高速冲锋，首次撞上植物时打出一记骑枪冲击。", "冲锋结束后狼和骑士会分离，骑士继续步行压前。"]
		"kite_zombie":
			return ["风筝僵尸本体不算太厚，但倒下后会把风筝挂到左侧植物上继续添乱。", "挂着的风筝会导电，落雷会顺着线把伤害传给植物。"]
		"kite_trap":
			return ["脱手风筝会悬在空中，普通对地火力拿它没什么办法。", "只要挂在线上，它就会继续威胁对应植物。"]
		"hive_zombie":
			return ["密蜂僵尸受伤过半后会放出一群高速蜜蜂，从附近三排同时冲脸。", "本体移动也偏快，不能只靠后排慢慢磨。"]
		"bee_minion":
			return ["蜜蜂群非常脆，一颗普通豌豆就能打碎。", "问题不在耐久，而在它们会在短时间内同时扑上来。"]
		"turret_zombie":
			return ["炮塔僵尸会扎在右侧后场，周期性把强化僵尸直接抛进中场。", "如果不尽快处理，前线会被它不断凭空补兵。"]
		"programmer_zombie":
			return ["程序员僵尸登场后会全局篡改你的攻击节奏，让植物射速直接减半。", "多只程序员会叠加减速，是典型必须优先击杀的后期威胁。"]
		"wenjie_zombie":
			return ["问界僵尸开车时会随机换行乱窜，行进轨迹并不稳定。", "它的威胁来自突然切线与偏高本体耐久。"]
		"janitor_zombie":
			return ["清洁工僵尸正面有厚铲当盾，贴近后会直接把植物铲掉。", "如果让它贴脸，它对阵型的破坏比单纯啃咬更快。"]
		"subway_zombie":
			return ["地铁僵尸只要踏上轨道就会高速冲家，是城市轨道关的直线爆压单位。", "花盆虽然能种在轨道上，但也会被它一口气撞穿。"]
		"enderman_zombie":
			return ["末影人僵尸会在场内不断瞬移，但自己不吃植物也不进家。", "它更像一块会动的肉盾，专门替后面的尸潮挡子弹。"]
		"router_zombie":
			return ["路由器僵尸在场时会给其他僵尸挂上全局增益。", "先拆它，往往比继续硬打重装更划算。"]
		"ski_zombie":
			return ["滑雪僵尸在暴风雪里移动极快，但本体不算太厚。", "如果被减速或卡停，它的压迫感会立刻掉下来。"]
		"flywheel_zombie":
			return ["飞轮僵尸步伐缓慢，但会定期朝前线扔出飞轮骚扰植物。", "厚血量配上远程压制，让它很适合当暴雪关卡的压阵单位。"]
		"wither_zombie":
			return ["枯萎僵尸死后会把周围地皮一起腐化，短时间内谁都别想再补种。", "如果在关键格子上放任它倒下，阵地会被它留下永久空窗。"]
		"mech_zombie":
			return ["机甲僵尸会周期性发射激光，而且对灰烬、爆炸、灼烧类攻击特别怕。", "普通输出也能把它打死，但灰烬类植物会更快拆掉它的机体。"]
		"wizard_zombie":
			return ["巫师僵尸会随机释放法术，可能削弱植物、强化尸潮或直接扰乱前线。", "它不是最硬的，但一旦让它连续施法，整盘节奏都会被拖偏。"]
		_:
			return ["资料暂未填写。"]
