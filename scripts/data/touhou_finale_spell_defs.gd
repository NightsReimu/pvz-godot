extends RefCounted

# These are original tower-defense spells, never substitutions for game IDs.
# Existing character poses are reused; each card has its own live formation.
const THEMES := {
	"rumia_boss": ["bird", "影符「六畦间的暮光缝隙」", "宵阵「回转的暗珠灯廊」", "暮符「空缺一席的黑日环」"],
	"daiyousei_boss": ["ring", "翠流「双翼绕田的露珠」", "妖精「分列绽开的翡翠花」", "芽符「枝间接力的春光」"],
	"cirno_boss": ["icicle", "冰垄「留出一行的霜栏」", "冻芽「错时解冻的九瓣花」"],
	"meiling_boss": ["rainbow", "彩拳「三色交错的护田掌」", "虹阵「六合错步的巡门环」"],
	"koakuma_boss": ["books", "书页「旋叶双栏的禁书架」", "索引「折返花圃的散页」", "借阅「逐行开卷的赤书签」"],
	"patchouli_boss": ["metal", "火水「交替浇灌的双曜」", "金土「三重护栏的地脉」"],
	"sakuya_boss": ["knives", "时针「停走交替的银刃畦」", "剪影「错列折返的二时刻」"],
	"remilia_boss": ["scarlet", "血翼「红枪两列的领地」", "命运「弯折在黎明前的枪雨」"],
	"flandre_boss": ["crystal", "碎心「四隅共鸣的破坏晶格」", "禁阵「反弹两次的心之断片」"],
	"letty_boss": ["lingering", "雪垄「错列盛放的寒枝」", "冬庭「合拢之前的雪花窗」", "残冬「逐畦消融的白雪铃」"],
	"chen_boss": ["shikigami", "猫步「左右跳田的双尾符」", "式阵「转角追踪的猫爪印」"],
	"alice_boss": ["marionette", "人偶「五线接力的花圃剧」", "操线「两侧交缠的植株舞台」"],
	"lily_white_boss": ["spring_herald", "春种「逐行归来的花信」", "花庭「六畦错开的春分环」", "报春「绕过一垄的暖风信」"],
	"prismriver_boss": ["concerto", "错拍「三音接力的植株序曲」", "和弦「反向交织的六畦轮唱」"],
	"youmu_boss": ["slash", "半灵「先声后刃的双重剑痕」", "剑垄「留隙六道的交错割线」"],
	"yuyuko_boss": ["butterfly", "冥庭「双蝶迟开的葬花环」", "幽芽「由散至聚的返魂枝」"],
	"ran_boss": ["senko", "九尾「分垄巡行的式神印」", "狐火「边沿折返的双旋狐灯」"],
	"yukari_boss": ["boundary", "隙庭「对门相望的植株回廊」", "境垄「错位折返的两界缝」"],
	"wriggle_boss": ["swarm", "萤垄「轮流苏醒的灯虫列」", "虫阵「双群错步的夜光网」"],
	"mystia_boss": ["song", "夜唱「留出休止符的轮唱畦」", "羽声「由两翼传回的秋声」"],
	"keine_boss": ["history", "编年「今昔交替的两卷田书」", "史垄「逐行回读的纪年札」"],
	"hakutaku_boss": ["special", "旧历「方圆对照的白泽园」", "新章「改写两侧的年表灯」"],
	"mokou_boss": ["special", "炎羽「错时再开的不死枝」", "灰环「余烬双旋的回生路」"],
	"reimu_boss": ["seal", "御田「阴阳错列的护符畦」", "博丽「先散后合的双仪灯」"],
	"marisa_boss": ["stars", "星垄「反向公转的双星道」", "恋火「三列折光的彗星雨」"],
	"tewi_boss": ["luck", "幸运「三垄交替的兔足印」", "因幡「反跳归田的金色珠」", "福田「留空一畦的吉兆灯」"],
	"reisen_boss": ["eye", "幻垄「交替显形的赤月廊」", "波庭「错拍偏折的双眼光」"],
	"eirin_boss": ["special", "处方「先稳后散的月药阵」", "药庭「红蓝交替的诊疗札」"],
	"kaguya_boss": ["special", "须臾「错时开花的蓬莱枝」", "永夜「相背回转的月下双灯」"],
	"suika_boss": ["throw", "岩宴「三席错落的地岩舞」", "瓢环「由疏返密的回旋酒火」"],
	"shizuha_boss": ["leaves", "叶垄「层层染红的六畦秋枝」", "红庭「错向盘旋的枫叶窗」", "秋步「逐行落定的赤叶桥」"],
	"minoriko_boss": ["harvest", "穗阵「金穗红叶的交替丰收」", "秋庭「三垄回响的大年穗环」"],
	"hina_boss": ["spin", "厄垄「留隙转动的七轮纸偶」", "流庭「错向释放的厄神双环」"],
	"nitori_boss": ["waterfall", "水车「留出一格的六轮河童水车」", "雨垄「瀑布倒灌的雨后河道」"],
}

static func is_road_definition(kind: String, level: Dictionary) -> bool:
	return String(level.get("mid_boss_kind", "")) == kind and not bool(level.get("mid_boss_final_preview", false))

static func additions(kind: String) -> Array:
	if not THEMES.has(kind): return []
	var theme: Array = THEMES[kind]
	var result: Array = []
	for move in range(theme.size() - 1):
		result.append(["original-finale-%s-%d" % [kind, move + 1], "原创 · " + String(theme[move + 1]), "finale_%s_%d" % [kind.trim_suffix("_boss"), move + 1], String(theme[0]), {"finale_only": true, "finale_move": move, "duration": 6.5 if move == 0 else 7.5}])
	return result

static func extend(kind: String, level: Dictionary, phases: Array) -> Array:
	if phases.is_empty() or is_road_definition(kind, level): return phases
	var insert_at := maxi(1, phases.size() - 1)
	# Keep Kaguya's five nights and Mokou's terminal Last Spells consecutive.
	for i in range(1, phases.size()):
		if phases[i].any(func(entry): return (entry.size() > 4 and (bool(entry[4].get("last_spell", false)) or bool(entry[4].get("survival", false)))) or String(entry[2]) == "and_then_none"):
			insert_at = i
			break
	for entry in additions(kind):
		phases.insert(insert_at, [entry])
		insert_at += 1
	return phases
