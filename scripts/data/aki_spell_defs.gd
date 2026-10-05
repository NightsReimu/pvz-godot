extends RefCounted

# TH10 stage 1: Shizuha only declares her spell on Hard/Lunatic.
# The leaf fields and physical offering baskets are original PvZ adaptations.
const SHIZUHA_OPENING := ["th10-shizuha-nonspell", "非符 · 秋静叶的红叶回旋", "nonspell_aki_leaves", "shot"]
const MINORIKO_OPENING := ["th10-minoriko-nonspell", "非符 · 秋穰子的金穗巡礼", "nonspell_aki_grain", "shot"]
const ORIGINALS := [
	["original-aki-ripening", "原创 · 秋收「红枫田垄的收获祭」", "aki_ripening", "harvest", {"duration": 8.5}],
	["original-aki-offering", "原创 · 供奉「阳光贡仓的秋日祭」", "aki_offering", "harvest", {"duration": 9.0}],
	["original-aki-six-furrows", "原创 · 枫阵「交错六畦的红叶毯」", "aki_six_furrows", "leaves", {"duration": 8.5}],
	["original-aki-feast", "原创 · 丰穰「六畦同庆的秋日宴」", "aki_feast", "final", {"duration": 10.0}],
]

static func rank(level: Dictionary) -> int:
	return maxi(0, ["easy", "normal", "hard", "lunatic"].find(String(level.get("touhou_difficulty", "easy"))))

static func cards(kind: String, level: Dictionary) -> Array:
	var r := rank(level)
	if kind == "shizuha_boss":
		if r < 2: return [SHIZUHA_OPENING.duplicate(true)]
		return [["th10-%03d" % (r - 1), "叶符「狂乱的落叶」", "aki_falling_leaves", "leaves", {"duration": 7.5, "last_spell": true}]]
	if kind != "minoriko_boss": return []
	var hard := r >= 2
	var result: Array = [
		["th10-%03d" % (3 + r), "秋符「秋之天空与少女之心」" if hard else "秋符「秋之天空」", "aki_maidens_heart" if hard else "aki_autumn_sky", "leaves", {"duration": 8.0}],
		["th10-%03d" % (7 + r), "丰收「谷物神的允诺」" if hard else "丰符「大年收获者」", "aki_grain_promise" if hard else "aki_otoshi_harvester", "harvest", {"duration": 8.5}],
	]
	for i in range(r + 1): result.append(ORIGINALS[i].duplicate(true))
	result.back()[4]["last_spell"] = true
	result.back()[3] = "final"
	return result

static func phases(kind: String, level: Dictionary) -> Array:
	if kind == "shizuha_boss":
		if rank(level) < 2: return [[SHIZUHA_OPENING.duplicate(true)]]
		return [[SHIZUHA_OPENING.duplicate(true), cards(kind, level)[0]]]
	var result: Array = []
	for entry in cards(kind, level):
		if String(entry[0]).begins_with("original-"):
			result.append([entry])
		else:
			result.append([MINORIKO_OPENING.duplicate(true), entry])
	return result
