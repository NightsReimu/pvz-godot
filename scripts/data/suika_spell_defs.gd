extends RefCounted

# TH7.5 story boss cards. PvZ mechanics and original interludes are documented
# separately in docs/plans/2026-10-05-suika-8-6.md.
const CANON := [
	["th075-suika-1", "符之一「投掷的天岩户」", "suika_rocks", "throw", {"duration": 6.0}],
	["th075-suika-2", "符之二「坤轴的大鬼」", "suika_giant", "giant", {"duration": 6.5}],
	["th075-suika-3", "符之三「追傩返黑洞」", "suika_black_hole", "density", {"duration": 7.0}],
	["th075-suika-4", "鬼火「超高密度磷祸术」", "suika_dense_fire", "fire", {"duration": 6.5}],
	["th075-suika-5", "疎符「六里雾中」", "suika_mist", "mist", {"duration": 7.0}],
	["th075-suika-6", "「百万鬼夜行」", "suika_million_oni", "final", {"duration": 12.0, "last_spell": true}],
]
const ORIGINALS := [
	["original-suika-wine", "原创 · 酿符「伊吹瓢的青石酒河」", "suika_wine", "gourd", {"duration": 8.5}],
	["original-suika-pea", "原创 · 萃豆「弹仓酿成的鬼火」", "suika_pea_knot", "density", {"duration": 8.0}],
	["original-suika-banquet", "原创 · 宴阵「方圆三角的分酒席」", "suika_chain_banquet", "throw", {"duration": 8.0}],
	["original-suika-hundred", "原创 · 疎宴「一瓢分作百鬼席」", "suika_hundred_feasts", "final", {"duration": 9.0}],
]
const OPENING := ["adapted-suika-nonspell", "非符 · 酒宴中的疏与密", "nonspell_suika_density", "shot"]

static func rank(level: Dictionary) -> int:
	return maxi(0, ["easy", "normal", "hard", "lunatic"].find(String(level.get("touhou_difficulty", "easy"))))

static func cards(level: Dictionary) -> Array:
	var result: Array = []
	for i in range(CANON.size()):
		result.append(CANON[i].duplicate(true))
		if i == 1: result.append(ORIGINALS[0].duplicate(true))
		if i == 2 and rank(level) >= 1: result.append(ORIGINALS[1].duplicate(true))
		if i == 3 and rank(level) >= 2: result.append(ORIGINALS[2].duplicate(true))
		if i == 4 and rank(level) >= 3: result.append(ORIGINALS[3].duplicate(true))
	return result

static func phases(level: Dictionary) -> Array:
	var result: Array = []
	for entry in cards(level):
		if String(entry[0]).begins_with("original-") or String(entry[0]) == "th075-suika-6":
			result.append([entry])
		else:
			result.append([OPENING.duplicate(true), entry])
	return result
