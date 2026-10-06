extends RefCounted

# TH10 stage 2 spell-practice IDs 011–026. The road spell and the three
# finale families retain their actual difficulty variants; originals are separate.
const KIND := "hina_boss"
const OPENING := ["th10-hina-nonspell", "非符 · 键山雏的厄运回旋", "nonspell_hina_spiral", "spin"]
const ORIGINALS := [
	["original-hina-delayed", "符卡 · 厄印「迟开的六畦厄花」", "hina_delayed", "curse", {"duration": 8.5}],
	["original-hina-doll", "符卡 · 流偶「代偿厄运的稻草人」", "hina_doll_offering", "doll", {"duration": 10.5}],
	["original-hina-misfire", "符卡 · 失准「第三颗豌豆的坏运气」", "hina_misfire", "ofuda", {"duration": 8.5}],
	["original-hina-festival", "符卡 · 厄祭「阵地轮回的流雏祭」", "hina_festival", "final", {"duration": 11.0}],
]

static func rank(level: Dictionary) -> int:
	return maxi(0, ["easy", "normal", "hard", "lunatic"].find(String(level.get("touhou_difficulty", "easy"))))

static func road_card(level: Dictionary) -> Array:
	var r := rank(level)
	return ["th10-%03d" % (11 + r), "厄符「厄神大人的生理节律」" if r >= 2 else "厄符「厄运」", "hina_biorhythm" if r >= 2 else "hina_bad_fortune", "spin", {"duration": 7.5, "last_spell": true}]

static func cards(kind: String, level: Dictionary) -> Array:
	if kind != KIND: return []
	var r := rank(level)
	var hard := r >= 2
	var result: Array = [
		["th10-%03d" % (15 + r), "疵痕「损坏的护符」" if hard else "疵符「破裂的护符」", "hina_damaged_amulet" if hard else "hina_broken_amulet", "ofuda", {"duration": 8.0}],
		["th10-%03d" % (19 + r), "悲运「大钟婆之火」" if hard else "恶灵「厄运之轮」", "hina_bell_fire" if hard else "hina_misfortune_wheel", "spin", {"duration": 8.5}],
		["th10-%03d" % (23 + r), "创符「流放人偶」" if hard else "创符「痛苦之流」", "hina_exiled_doll" if hard else "hina_pain_flow", "doll", {"duration": 8.5}],
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
