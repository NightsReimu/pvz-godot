extends RefCounted
class_name TouhouSpellDefs

# TH06/TH07 Normal routes, followed by Extra/Phantasm where specified.
# Columns: reference ID, display name, pattern, animation pose.
# Sources and the tower-defense adaptations are documented in docs/touhou-spells.md.
const CARDS := {
	"rumia_boss": [
		["th06-02", "夜符「Night Bird」", "night_bird", "bird"],
		["th06-03", "暗符「Demarcation」", "demarcation", "dark"],
	],
	"daiyousei_boss": [["th06-daiyousei-nonspell", "非符 · 大妖精", "fairy_aim", "ring"]],
	"cirno_boss": [
		["th06-04", "冰符「Icicle Fall」", "icicle", "icicle"],
		["th06-06", "冻符「Perfect Freeze」", "perfect_freeze", "freeze"],
		["th06-07", "雪符「Diamond Blizzard」", "blizzard", "blizzard"],
	],
	"meiling_boss": [
		["th06-08", "华符「芳华绚烂」", "flower", "rainbow"],
		["th06-10", "虹符「彩虹的风铃」", "rainbow", "rainbow"],
		["th06-12", "彩符「彩雨」", "rainbow_rain", "rainbow"],
		["th06-14", "彩符「极彩台风」", "typhoon", "dragon"],
	],
	"koakuma_boss": [["th06-koakuma-nonspell", "非符 · 小恶魔", "library_orbs", "books"]],
	"patchouli_boss": [
		["th06-15", "火符「Agni Shine」", "agni", "fire"],
		["th06-22", "土符「Lazy Trilithon上级」", "trilithon", "metal"],
		["th06-28", "火&土符「Lava Cromlech」", "cromlech", "fire"],
		["th06-31", "金&水符「Mercury Poison」", "mercury", "water"],
	],
	"sakuya_boss": [
		["th06-33", "奇术「Misdirection」", "misdirection", "knives"],
		["th06-35", "幻在「Clock Corpse」", "clock_corpse", "clock"],
		["th06-36", "幻象「Luna Clock」", "luna_clock", "time"],
		["th06-37", "女仆秘技「操弄玩偶」", "marionette", "doll"],
	],
	"remilia_boss": [
		["th06-42", "天罚「Star of David」", "david", "magic"],
		["th06-43", "冥符「红色的冥界」", "scarlet_nether", "scarlet"],
		["th06-44", "诅咒「弗拉德·特佩斯的诅咒」", "vlad", "magic"],
		["th06-45", "红符「Scarlet Shoot」", "scarlet_shoot", "scarlet"],
		["th06-46", "「Red Magic」", "red_magic", "scarlet"],
	],
	"flandre_boss": [
		["th06-55", "禁忌「Cranberry Trap」", "cranberry", "cranberry"],
		["th06-56", "禁忌「Laevatein」", "laevatein", "laevatein"],
		["th06-57", "禁忌「Four of a Kind」", "four_of_a_kind", "clones"],
		["th06-58", "禁忌「Kagome Kagome」", "kagome", "kagome"],
		["th06-59", "禁忌「恋之迷宫」", "maze", "kagome"],
		["th06-60", "禁弹「Starbow Break」", "starbow", "starbow"],
		["th06-61", "禁弹「Catadioptric」", "catadioptric", "crystal"],
		["th06-62", "禁弹「刻着过去的钟表」", "past_clock", "laevatein"],
		["th06-63", "秘弹「之后就一个人都没有了吗？」", "and_then_none", "clones"],
		["th06-64", "QED「495年的波纹」", "qed", "starbow"],
	],
	"letty_boss": [
		["th07-004", "寒符「Lingering Cold」", "lingering_cold", "lingering"],
		["th07-008", "冬符「Flower Wither Away」", "wither", "wither"],
	],
	"chen_boss": [
		["th07-012", "仙符「凤凰卵」", "phoenix_egg", "phoenix"],
		["th07-016", "式符「飞翔晴明」", "seiman", "shikigami"],
		["th07-020", "天符「天仙鸣动」", "tianxian", "idaten"],
		["th07-024", "仙符「尸解永远」", "shijie", "rampage"],
	],
	"alice_boss": [
		["th07-030", "苍符「博爱的法兰西人偶」", "france", "marionette"],
		["th07-034", "红符「红发的荷兰人偶」", "holland", "seven"],
		["th07-038", "暗符「雾之伦敦人偶」", "london", "forest"],
		["th07-042", "诅咒「魔彩光的上海人偶」", "shanghai", "shanghai"],
	],
	"lily_white_boss": [["th07-lily-nonspell", "非符 · 莉莉霍瓦特", "spring_nonspell", "spring_herald"]],
	"prismriver_boss": [
		["th07-046", "骚符「Phantom Dinning」", "phantom_dinning", "phantom_dinning"],
		["th07-050", "弦奏「Guarneri del Gesù」", "guarneri", "lunasa"],
		["th07-062", "合葬「Prism Concerto」", "prism_concerto", "concerto"],
		["th07-066", "大合葬「灵车大协奏曲」", "concerto_grosso", "live_poltergeist"],
	],
	"youmu_boss": [
		["th07-070", "幽鬼剑「妖童饿鬼之断食」", "gaki", "slash"],
		["th07-074", "狱界剑「二百由旬之一闪」", "two_hundred_yojana", "dash"],
		["th07-078", "畜趣剑「无为无策之冥罚」", "animal_realm", "cross"],
		["th07-082", "人界剑「悟入幻想」", "human_realm", "instant"],
		["th07-086", "天上剑「天人之五衰」", "five_signs", "six_realms"],
		["original-youmu-wraith", "魂魄「怨灵使役」", "wraith_charm", "wraith"],
	],
	"yuyuko_boss": [
		["th07-094", "亡乡「亡我乡 -宿罪-」", "lost_soul", "spirit"],
		["th07-098", "亡舞「生者必灭之理 -死蝶-」", "mortal_butterfly", "butterfly"],
		["th07-102", "华灵「Swallowtail Butterfly」", "swallowtail", "butterfly"],
		["th07-106", "幽曲「埋骨于弘川 -亡灵-」", "hirokawa", "fan"],
		["th07-110", "樱符「完全墨染的樱花 -亡我-」", "sumizome", "tree"],
	],
	"ran_boss": [
		["th07-119", "式神「仙狐思念」", "senko", "senko"],
		["th07-120", "式神「十二神将之宴」", "twelve_generals", "generals"],
		["th07-121", "式辉「狐狸妖怪激光」", "fox_laser", "laser"],
		["th07-122", "式辉「迷人的四面楚歌」", "charming_siege", "tenko"],
		["th07-123", "式辉「天狐公主 -Illusion-」", "princess_tenko", "tenko"],
		["th07-124", "式弹「Ultimate Buddhist」", "buddhist", "buddhist"],
		["th07-125", "式弹「Unilateral Contact」", "contact", "contact"],
		["th07-126", "式神「橙」", "shikigami_chen", "shiki"],
		["th07-127", "「狐狗狸先生的契约」", "kokkuri", "kokkuri"],
		["th07-128", "幻神「饭纲权现降临」", "izuna", "izuna"],
	],
	"yukari_boss": [
		["th07-131", "结界「梦境与现实的咒术」", "dream_reality", "boundary"],
		["th07-132", "结界「动与静的均衡」", "motion_stillness", "barrier"],
		["th07-133", "结界「光明与黑暗的网目」", "light_dark_mesh", "mesh"],
		["th07-134", "罔两「直球与曲球的梦乡」", "straight_curve", "eyes"],
		["th07-135", "罔两「八云紫的神隐」", "spiriting_away", "dream"],
		["th07-136", "罔两「栖息于禅寺的妖蝶」", "zen_butterfly", "butterfly"],
		["th07-137", "魍魉「二重黑死蝶」", "double_butterfly", "butterfly"],
		["th07-138", "式神「八云蓝」", "shikigami_ran", "object"],
		["th07-139", "「人类与妖怪的界线」", "human_youkai", "boundary"],
		["th07-140", "结界「生与死的界线」", "life_death", "barrier"],
		["th07-141", "紫奥义「弹幕结界」", "danmaku_barrier", "infinite"],
	],
	"wriggle_boss": [
		["th08-01", "灯符「Firefly Phenomenon」", "wriggle_firefly", "firefly"],
		["th08-02", "蛍符「地上の彗星」", "wriggle_comet", "firefly"],
		["th08-03", "灯符「ファイヤフライフェノメノン」", "wriggle_swarm", "swarm"],
		["th08-04", "蠢符「ナイトバグストーム」", "wriggle_storm", "swarm"],
		["th08-05", "蠢符「リトルバグ」", "wriggle_little_bug", "swarm"],
		["th08-06", "終符「永夜蟄居」", "wriggle_final", "final"],
	],
	"mystia_boss": [
		["th08-07", "声符「木菟咆哮」", "mystia_song", "song"],
		["th08-08", "声符「木菟咆哮」", "mystia_song", "song"],
		["th08-09", "夜盲「夜雀之歌」", "mystia_nightblind", "song"],
		["th08-10", "鸟符「飞翔颈木菟」", "mystia_flight", "wing"],
		["th08-11", "声符「木菟咆哮」", "mystia_crescendo", "crescendo"],
		["th08-12", "终符「夜雀食堂」", "mystia_finale", "final"],
	],
}

const PATCHOULI_EXTRA := [
	["th06-52", "月符「Silent Selene」", "silent_selene", "water"],
	["th06-53", "日符「Royal Flare」", "royal_flare", "flare"],
	["th06-54", "火水木金土符「贤者之石」", "philosophers_stone", "metal"],
]
const SAKUYA_MIDBOSS := [["th06-41", "奇术「Eternal Meek」", "eternal_meek", "knives"]]
const CIRNO_MIDBOSS := [["th07-cirno-nonspell", "非符 · 琪露诺", "cold_nonspell", "ice"]]
const YOUMU_MIDBOSS := [["th07-090", "六道剑「一念无量劫」", "immeasurable_kalpas", "six_realms"]]
const CHEN_EXTRA := [
	["th07-117", "鬼符「青鬼赤鬼」", "blue_red_oni", "oni"],
	["th07-118", "鬼神「飞翔毘沙门天」", "bishamonten", "idaten"],
]
const REBIRTH := ["th07-114", "「反魂蝶 -三分咲-」", "resurrection_butterfly", "resurrection"]

# Unnamed attacks are tower-defense adaptations, never invented named spell cards.
const NONSPELLS := {
	"rumia_boss": ["露米娅", "dark_fan", "bird"],
	"cirno_boss": ["琪露诺", "ice_fan", "icicle"],
	"meiling_boss": ["红美铃", "rainbow_spiral", "rainbow"],
	"patchouli_boss": ["帕秋莉", "element_orbits", "metal"],
	"sakuya_boss": ["十六夜咲夜", "knife_fan", "knives"],
	"remilia_boss": ["蕾米莉亚", "scarlet_crossfire", "scarlet"],
	"flandre_boss": ["芙兰朵露", "crystal_fan", "crystal"],
	"letty_boss": ["蕾蒂", "snow_curtain", "lingering"],
	"chen_boss": ["橙", "shikigami_crossfire", "shikigami"],
	"alice_boss": ["爱丽丝", "doll_fan", "marionette"],
	"prismriver_boss": ["骚灵三姐妹", "note_crossfire", "concerto"],
	"youmu_boss": ["魂魄妖梦", "sword_fan", "slash"],
	"yuyuko_boss": ["西行寺幽幽子", "butterfly_fan", "butterfly"],
	"ran_boss": ["八云蓝", "fox_spiral", "senko"],
	"yukari_boss": ["八云紫", "gap_crossfire", "boundary"],
	"wriggle_boss": ["莉格露·奈特巴格", "wriggle_night_swarm", "firefly"],
	"mystia_boss": ["米斯蒂娅·萝蕾拉", "mystia_song", "song"],
}


static func phases_for(kind: String, level: Dictionary = {}) -> Array:
	var phases: Array = []
	var originals: Array = []
	for entry in cards_for(kind, level):
		if String(entry[0]).begins_with("original-"):
			originals.append(entry)
			continue
		var attacks: Array = []
		if NONSPELLS.has(kind) and not String(entry[0]).ends_with("nonspell"):
			var opening: Array = NONSPELLS[kind]
			attacks.append(["adapted-%s-nonspell" % kind, "非符 · %s" % opening[0], "nonspell_" + opening[1], opening[2]])
		attacks.append(entry)
		phases.append(attacks)
	if not originals.is_empty() and not phases.is_empty():
		# Youmu's original charm follows the third sword, preserving the last sword's finale.
		phases[mini(2, phases.size() - 1)].append_array(originals)
	return phases


static func phase_count(kind: String, level: Dictionary = {}) -> int:
	return phases_for(kind, level).size() + (1 if kind == "yuyuko_boss" else 0)


static func card_from_entry(entry: Array) -> Dictionary:
	return {"id": entry[0], "name": entry[1], "pattern": entry[2], "pose": entry[3], "origin": "original" if String(entry[0]).begins_with("original-") else ("nonspell" if String(entry[0]).ends_with("nonspell") else "canon")}


static func cards_for(kind: String, level: Dictionary = {}) -> Array:
	if String(level.get("mid_boss_kind", "")) == kind:
		if kind == "patchouli_boss":
			return PATCHOULI_EXTRA
		if kind == "cirno_boss":
			return CIRNO_MIDBOSS
		if kind == "sakuya_boss":
			return SAKUYA_MIDBOSS
		if kind == "chen_boss":
			return CHEN_EXTRA
		if kind == "youmu_boss":
			return YOUMU_MIDBOSS
	return CARDS.get(kind, [])


static func card_for(boss: Dictionary, level: Dictionary = {}) -> Dictionary:
	var kind = String(boss.get("kind", ""))
	if kind == "yuyuko_boss" and bool(boss.get("yuyuko_revived", false)):
		return card_from_entry(REBIRTH)
	if boss.has("touhou_encounter"):
		var encounter: Dictionary = boss.touhou_encounter
		var attacks: Array = encounter.phases[int(encounter.index)]
		return card_from_entry(attacks[int(encounter.attack)])
	var cards = cards_for(kind, level)
	if cards.is_empty():
		return {}
	var index = posmod(int(boss.get("boss_skill_cycle", 0)), cards.size())
	return card_from_entry(cards[index])
