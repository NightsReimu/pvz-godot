extends RefCounted
# Per-difficulty spell cards for the TH06/TH07/TH08 bosses, checked against
# THBWiki's spell lists (东方红魔乡/符卡, 东方妖妖梦/符卡, 东方永夜抄/符卡) on
# 2026-10-09. Each base Normal card maps to its Easy, Hard and Lunatic number;
# a different name or pattern is given only where the original card changes.
# Ranks: 0 Easy, 2 Hard, 3 Lunatic. TH06 has no separate Easy numbers for the
# Stage 4-6 bosses (Easy ends at Stage 5), so those keep their Normal card.

const VARIANTS := {
	"rumia_boss": {},
	"cirno_boss": {
		"th07-001": {3: ["th07-002", "", ""]},
		"th06-04": {2: ["th06-05", "雹符「Hailstorm」", "hailstorm"], 3: ["th06-05", "雹符「Hailstorm」", "hailstorm"]},
	},
	"meiling_boss": {
		"th06-08": {2: ["th06-09", "华符「Selaginella 9」", "selaginella"], 3: ["th06-09", "华符「Selaginella 9」", "selaginella"]},
		"th06-12": {2: ["th06-13", "彩符「彩光乱舞」", "saikou_ranbu"], 3: ["th06-13", "彩符「彩光乱舞」", "saikou_ranbu"]},
	},
	"patchouli_boss": {
		"th06-15": {2: ["th06-20", "火符「Agni Shine上级」", "agni"], 3: ["th06-20", "火符「Agni Shine上级」", "agni"]},
		"th06-22": {2: ["th06-26", "土符「Trilithon Shake」", "trilithon_shake"], 3: ["th06-26", "土符「Trilithon Shake」", "trilithon_shake"]},
	},
	"sakuya_boss": {
		"th06-33": {2: ["th06-34", "奇术「幻惑Misdirection」", ""], 3: ["th06-34", "奇术「幻惑Misdirection」", ""]},
		"th06-35": {2: ["th06-38", "幻幽「Jack the Ludo Bile」", ""], 3: ["th06-38", "幻幽「Jack the Ludo Bile」", ""]},
		"th06-36": {2: ["th06-39", "幻世「The World」", ""], 3: ["th06-39", "幻世「The World」", ""]},
		"th06-37": {2: ["th06-40", "女仆秘技「杀人玩偶」", ""], 3: ["th06-40", "女仆秘技「杀人玩偶」", ""]},
	},
	"remilia_boss": {
		"th06-42": {2: ["th06-47", "神罚「年幼的恶魔之王」", "young_demon_lord"], 3: ["th06-47", "神罚「年幼的恶魔之王」", "young_demon_lord"]},
		"th06-43": {2: ["th06-48", "狱符「千根针的针山」", "thousand_needles"], 3: ["th06-48", "狱符「千根针的针山」", "thousand_needles"]},
		"th06-44": {2: ["th06-49", "神术「吸血鬼幻想」", "vampire_illusion"], 3: ["th06-49", "神术「吸血鬼幻想」", "vampire_illusion"]},
		"th06-45": {2: ["th06-50", "红符「Scarlet Meister」", "scarlet_meister"], 3: ["th06-50", "红符「Scarlet Meister」", "scarlet_meister"]},
		"th06-46": {2: ["th06-51", "「红色的幻想乡」", "scarlet_gensokyo"], 3: ["th06-51", "「红色的幻想乡」", "scarlet_gensokyo"]},
	},
	"letty_boss": {
		"th07-004": {0: ["th07-003", "", ""], 2: ["th07-005", "", ""], 3: ["th07-006", "", ""]},
		"th07-008": {0: ["th07-007", "", ""], 2: ["th07-009", "白符「Undulation Ray」", "undulation_ray"], 3: ["th07-010", "怪符「Table Turning」", "table_turning"]},
	},
	"chen_boss": {
		"th07-012": {0: ["th07-011", "", ""], 2: ["th07-013", "仙符「凤凰展翅」", ""], 3: ["th07-014", "仙符「凤凰展翅」", ""]},
		"th07-016": {0: ["th07-015", "", ""], 2: ["th07-017", "阴阳「道满晴明」", ""], 3: ["th07-018", "阴阳「晴明大纹」", ""]},
		"th07-020": {0: ["th07-019", "", ""], 2: ["th07-021", "翔符「飞翔韦驮天」", ""], 3: ["th07-022", "童符「护法天童乱舞」", ""]},
		"th07-024": {0: ["th07-023", "", ""], 2: ["th07-025", "鬼符「鬼门金神」", ""], 3: ["th07-026", "方符「奇门遁甲」", ""]},
	},
	"alice_boss": {
		"th07-027": {3: ["th07-028", "", ""]},
		"th07-030": {0: ["th07-029", "", ""], 2: ["th07-031", "", ""], 3: ["th07-032", "苍符「博爱的奥尔良人偶」", ""]},
		"th07-034": {0: ["th07-033", "", ""], 2: ["th07-035", "白符「白垩的俄罗斯人偶」", ""], 3: ["th07-036", "白符「白垩的俄罗斯人偶」", ""]},
		"th07-038": {0: ["th07-037", "", ""], 2: ["th07-039", "回符「轮回的西藏人偶」", ""], 3: ["th07-040", "雅符「春之京都人偶」", ""]},
		"th07-042": {0: ["th07-041", "", ""], 2: ["th07-043", "", ""], 3: ["th07-044", "诅咒「上吊的蓬莱人偶」", ""]},
	},
	"youmu_boss": {
		"th07-070": {0: ["th07-069", "", ""], 2: ["th07-071", "饿鬼剑「饿鬼道草纸」", ""], 3: ["th07-072", "饿王剑「饿鬼十王的报应」", ""]},
		"th07-074": {0: ["th07-073", "", ""], 2: ["th07-075", "狱炎剑「业风闪影阵」", ""], 3: ["th07-076", "狱神剑「业风神闪斩」", ""]},
		"th07-078": {0: ["th07-077", "", ""], 2: ["th07-079", "修罗剑「现世妄执」", ""], 3: ["th07-080", "修罗剑「现世妄执」", ""]},
		"th07-082": {0: ["th07-081", "", ""], 2: ["th07-083", "人世剑「大悟显晦」", ""], 3: ["th07-084", "人神剑「俗谛常住」", ""]},
		"th07-086": {0: ["th07-085", "", ""], 2: ["th07-087", "天界剑「七魄忌讳」", ""], 3: ["th07-088", "天神剑「三魂七魄」", ""]},
		"th07-090": {0: ["th07-089", "", ""], 2: ["th07-091", "", ""], 3: ["th07-092", "", ""]},
	},
	"yuyuko_boss": {
		"th07-094": {0: ["th07-093", "亡乡「亡我乡 -彷徨的灵魂-」", ""], 2: ["th07-095", "亡乡「亡我乡 -无道之路-」", ""], 3: ["th07-096", "亡乡「亡我乡 -自尽-」", ""]},
		"th07-098": {0: ["th07-097", "亡舞「生者必灭之理 -眩惑-」", ""], 2: ["th07-099", "亡舞「生者必灭之理 -毒蛾-」", ""], 3: ["th07-100", "亡舞「生者必灭之理 -魔境-」", ""]},
		"th07-102": {0: ["th07-101", "华灵「Ghost Butterfly」", ""], 2: ["th07-103", "华灵「Deep-Rooted Butterfly」", ""], 3: ["th07-104", "华灵「Butterfly Delusion」", ""]},
		"th07-106": {0: ["th07-105", "幽曲「埋骨于弘川 -伪灵-」", ""], 2: ["th07-107", "幽曲「埋骨于弘川 -幻灵-」", ""], 3: ["th07-108", "幽曲「埋骨于弘川 -神灵-」", ""]},
		"th07-110": {0: ["th07-109", "樱符「完全墨染的樱花 -封印-」", ""], 2: ["th07-111", "樱符「完全墨染的樱花 -春眠-」", ""], 3: ["th07-112", "樱符「完全墨染的樱花 -开花-」", ""]},
		"th07-114": {0: ["th07-113", "「反魂蝶 -一分咲-」", ""], 2: ["th07-115", "「反魂蝶 -五分咲-」", ""], 3: ["th07-116", "「反魂蝶 -八分咲-」", ""]},
	},
	"keine_boss": {
		"th08-037": {0: ["th08-033", "产灵「First Pyramid」", "keine_pyramid"], 2: ["th08-038", "", ""], 3: ["th08-039", "", ""]},
		"th08-041": {0: ["th08-040", "野符「武烈的危机」", ""], 2: ["th08-042", "野符「义满的危机」", "keine_crisis"], 3: ["th08-043", "野符「GHQ的危机」", "keine_crisis"]},
		"th08-045": {0: ["th08-044", "国符「三种神器 剑」", ""], 2: ["th08-046", "国符「三种神器 镜」", "keine_mirror"], 3: ["th08-047", "国体「三种神器 乡」", "keine_mirror"]},
		"th08-049": {0: ["th08-048", "", ""], 2: ["th08-050", "虚史「幻想乡传说」", "keine_legend"], 3: ["th08-051", "虚史「幻想乡传说」", "keine_legend"]},
		"th08-052": {2: ["th08-053", "", ""], 3: ["th08-054", "", ""]},
	},
}

# Cards that exist only from Hard: [kind, insert index, entry].
const HARD_INSERTS := [
	["rumia_boss", 0, ["th06-01", "月符「Moonlight Ray」", "moonlight_ray", "dark"]],
	["meiling_boss", 2, ["th06-11", "幻符「华想梦葛」", "kasou_mukatsu", "rainbow"]],
	["patchouli_boss", 4, ["th06-29", "木&火符「Forest Blaze」", "forest_blaze", "fire"]],
	["alice_boss", 0, ["th07-027", "操符「少女文乐」", "otome_bunraku", "marionette"]],
]

# TH07 Stage 1's road Cirno declares Frost Columns on Hard and Lunatic.
const CIRNO_ROAD_HARD := ["th07-001", "霜符「Frost Columns」", "frost_columns", "icicle"]

# TH08 Stage 1 and 2 follow their per-difficulty lists exactly.
const WRIGGLE := {
	"easy": [
		["th08-003", "灯符「Firefly Phenomenon」", "wriggle_firefly", "firefly"],
		["th08-007", "蠢符「Little Bug」", "wriggle_bugs", "swarm"],
	],
	"normal": [
		["th08-004", "灯符「Firefly Phenomenon」", "wriggle_firefly", "firefly"],
		["th08-008", "蠢符「Little Bug Storm」", "wriggle_bugs", "swarm"],
		["th08-011", "隐虫「永夜蛰居」", "wriggle_final", "final", {"last_spell": true}],
	],
	"hard": [
		["th08-001", "萤符「地上的流星」", "wriggle_meteor", "firefly"],
		["th08-005", "灯符「Firefly Phenomenon」", "wriggle_firefly", "firefly"],
		["th08-009", "蠢符「Night Bug Storm」", "wriggle_bugs", "swarm"],
		["th08-012", "隐虫「永夜蛰居」", "wriggle_final", "final", {"last_spell": true}],
	],
	"lunatic": [
		["th08-002", "萤符「地上的彗星」", "wriggle_meteor", "firefly"],
		["th08-006", "灯符「Firefly Phenomenon」", "wriggle_firefly", "firefly"],
		["th08-010", "蠢符「Night Bug Tornado」", "wriggle_bugs", "swarm"],
		["th08-013", "隐虫「永夜蛰居」", "wriggle_final", "final", {"last_spell": true}],
	],
}

const MYSTIA := {
	"easy": [
		["th08-014", "声符「枭的夜鸣声」", "mystia_owl", "song"],
		["th08-018", "蛾符「天蛾的蛊道」", "mystia_moth", "wing"],
		["th08-022", "鹰符「Ill-Starred Dive」", "mystia_dive", "wing"],
		["th08-026", "夜盲「夜雀之歌」", "mystia_nightblind", "song"],
	],
	"normal": [
		["th08-015", "声符「枭的夜鸣声」", "mystia_owl", "song"],
		["th08-019", "蛾符「天蛾的蛊道」", "mystia_moth", "wing"],
		["th08-023", "鹰符「Ill-Starred Dive」", "mystia_dive", "wing"],
		["th08-027", "夜盲「夜雀之歌」", "mystia_nightblind", "song"],
		["th08-030", "夜雀「午夜的合唱指挥」", "mystia_chorus", "crescendo", {"last_spell": true}],
	],
	"hard": [
		["th08-016", "声符「木菟的咆哮」", "mystia_owl", "song"],
		["th08-020", "毒符「毒蛾的鳞粉」", "mystia_moth", "wing"],
		["th08-024", "鹰符「Ill-Starred Dive」", "mystia_dive", "wing"],
		["th08-028", "夜盲「夜雀之歌」", "mystia_nightblind", "song"],
		["th08-031", "夜雀「午夜的合唱指挥」", "mystia_chorus", "crescendo", {"last_spell": true}],
	],
	"lunatic": [
		["th08-017", "声符「木菟的咆哮」", "mystia_owl", "song"],
		["th08-021", "猛毒「毒蛾的黑暗演舞」", "mystia_moth", "wing"],
		["th08-025", "鹰符「Ill-Starred Dive」", "mystia_dive", "wing"],
		["th08-029", "夜盲「夜雀之歌」", "mystia_nightblind", "song"],
		["th08-032", "夜雀「午夜的合唱指挥」", "mystia_chorus", "crescendo", {"last_spell": true}],
	],
}

static func variant(kind: String, rank: int, entry: Array) -> Array:
	var table: Dictionary = VARIANTS.get(kind, {}).get(String(entry[0]), {})
	if not table.has(rank):
		return entry
	var replacement: Array = table[rank]
	var result := entry.duplicate(true)
	result[0] = replacement[0]
	if String(replacement[1]) != "": result[1] = replacement[1]
	if String(replacement[2]) != "": result[2] = replacement[2]
	return result

static func with_inserts(kind: String, rank: int, cards: Array) -> Array:
	if rank < 2:
		return cards
	var result := cards.duplicate(true)
	for insert in HARD_INSERTS:
		if String(insert[0]) == kind:
			result.insert(mini(int(insert[1]), result.size()), insert[2].duplicate(true))
	return result
