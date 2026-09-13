extends RefCounted

# TH08 6A: road 120–123, finale 124–147. See docs/touhou-spells.md.
static func rank(level: Dictionary) -> int:
	return ["easy", "normal", "hard", "lunatic"].find(String(level.get("touhou_difficulty", "easy")))

static func road_card(level: Dictionary) -> Array:
	return ["th08-%d" % (120 + maxi(0, rank(level))), "天丸「壶中的天地」", "eirin_vessel", "special"]

static func cards(level: Dictionary) -> Array:
	var r := maxi(0, rank(level))
	var hard := r >= 2
	return [
		["th08-%d" % (124 + r), "神符「天人的族谱」" if hard else "觉神「神代的记忆」", "eirin_genealogy" if hard else "eirin_memories", "shot"],
		["th08-%d" % (128 + r), "苏生「Rising Game」" if hard else "苏活「生命游戏 -Life Game-」", "eirin_rising" if hard else "eirin_life", "phase"],
		["th08-%d" % (132 + r), "神脑「Omoikane Brain」" if hard else "操神「Omoikane Device」", "eirin_brain" if hard else "eirin_device", "special"],
		["th08-%d" % (136 + r), "天咒「Apollo 13」", "eirin_apollo", "shot"],
		["th08-%d" % (140 + r), "秘术「天文密葬法」", "eirin_astronomical", "special"],
		["th08-%d" % (144 + r), "禁药「蓬莱之药」", "eirin_hourai", "final", {"last_spell": true, "duration": 12.0 + r * 2.0}],
	]
