extends RefCounted

# TH10 stage 3 spell-practice IDs 027–042. The mid-boss card is 光学 027–030;
# each finale group has E/N, Hard and Lunatic forms (034 is the Lunatic 漂溺).
# Originals target this game's lanes, conveyor and fusion defenses.
const KIND := "nitori_boss"
# The road Nitori first strikes from optical camouflage, then declares her card.
const ROAD_NONSPELL := ["th10-nitori-camouflage-nonspell", "非符 · 光学迷彩下的偷袭", "nonspell_nitori_camouflage", "camouflage", {"camouflage_duration": 6.0}]
const OPENING := ["th10-nitori-nonspell", "非符 · 河童的水枪连射", "nonspell_nitori_jet", "shot"]
const ORIGINALS := [
	["original-nitori-camo-squad", "原创 · 迷彩「光学迷彩突击队」", "nitori_camo_squad", "camouflage", {"duration": 9.0}],
	["original-nitori-cucumber", "原创 · 胡瓜「玄武之泽的黄瓜诱饵」", "nitori_cucumber_bait", "cucumber", {"duration": 10.0}],
	["original-nitori-cannon", "原创 · 水压「河童重工高压水炮」", "nitori_water_cannon", "cannon", {"duration": 9.5}],
	["original-nitori-workshop", "原创 · 河童「玄武工房总动员」", "nitori_workshop", "workshop", {"duration": 11.5}],
]

static func rank(level: Dictionary) -> int:
	return maxi(0, ["easy", "normal", "hard", "lunatic"].find(String(level.get("touhou_difficulty", "easy"))))

static func road_nonspell() -> Array:
	return ROAD_NONSPELL.duplicate(true)

static func road_card(level: Dictionary) -> Array:
	var r := rank(level)
	return ["th10-%03d" % (27 + r), "光学「水迷彩」" if r >= 2 else "光学「光学迷彩」", "nitori_hydro_camouflage" if r >= 2 else "nitori_optical_camouflage", "camouflage", {"duration": 8.0, "last_spell": true}]

static func road_phases(level: Dictionary) -> Array:
	return [[road_nonspell(), road_card(level)]]

static func cards(kind: String, level: Dictionary) -> Array:
	if kind != KIND: return []
	var r := rank(level)
	var flood: Array = [["洪水「泥浆泛滥」", "nitori_ooze_flooding"], ["洪水「泥浆泛滥」", "nitori_ooze_flooding"], ["洪水「冲积梦魇」", "nitori_diluvial_mare"], ["漂溺「粼粼水底之心伤」", "nitori_glimmering_trauma"]][r]
	var water: Array = [["水符「河童之河口浪潮」", "nitori_pororoca"], ["水符「河童之河口浪潮」", "nitori_pororoca"], ["水符「河童之山洪暴发」", "nitori_flash_flood"], ["水符「河童之幻想大瀑布」", "nitori_great_waterfall"]][r]
	var kappa: Array = [["河童「妖怪黄瓜」", "nitori_spook_cucumber", "cucumber"], ["河童「妖怪黄瓜」", "nitori_spook_cucumber", "cucumber"], ["河童「延展手臂」", "nitori_extend_arm", "arm"], ["河童「回转顶板」", "nitori_cephalic_plate", "spin"]][r]
	var result: Array = [
		["th10-%03d" % (31 + r), flood[0], flood[1], "flood", {"duration": 8.5}],
		["th10-%03d" % (35 + r), water[0], water[1], "waterfall", {"duration": 9.0}],
		["th10-%03d" % (39 + r), kappa[0], kappa[1], kappa[2], {"duration": 9.0}],
	]
	for i in range(r + 1): result.append(ORIGINALS[i].duplicate(true))
	result.back()[4]["last_spell"] = true
	result.back()[3] = "final"
	return result

static func phases(kind: String, level: Dictionary) -> Array:
	var result: Array = []
	for entry in cards(kind, level):
		result.append([entry] if String(entry[0]).begins_with("original-") else [OPENING.duplicate(true), entry])
	return result
