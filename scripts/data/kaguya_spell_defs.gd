extends RefCounted

# TH08 6B finale: five treasures (152–171), then five Last Spells (172–191).
# The user explicitly requests the 6A Eirin road instead of 6B's 148–151.
static func cards(level: Dictionary) -> Array:
	var r := maxi(0, ["easy", "normal", "hard", "lunatic"].find(String(level.get("touhou_difficulty", "easy"))))
	var hard := r >= 2
	var result: Array = [
		["th08-%d" % (152 + r), "神宝「Brilliant Dragon Bullet」" if hard else "难题「龙颈之玉 -五色的弹丸-」", "kaguya_dragon", "shot"],
		["th08-%d" % (156 + r), "神宝「Buddhist Diamond」" if hard else "难题「佛御石之钵 -不碎的意志-」", "kaguya_bowl", "special"],
		["th08-%d" % (160 + r), "神宝「Salamander Shield」" if hard else "难题「火鼠的皮衣 -不焦躁的内心-」", "kaguya_robe", "phase"],
		["th08-%d" % (164 + r), "神宝「Life Spring Infinity」" if hard else "难题「燕的子安贝 -永命线-」", "kaguya_swallow", "special", {"duration": 7.0}],
		["th08-%d" % (168 + r), "神宝「蓬莱的玉枝 -梦色之乡-」" if hard else "难题「蓬莱的弹枝 -七色的弹幕-」", "kaguya_branch", "final"],
	]
	var nights := [["初月", "新月", "上弦月", "待宵"], ["子之刻", "子时二刻", "子时三刻", "子时四刻"], ["丑之刻", "丑时二刻", "丑时三刻", "丑时四刻"], ["寅之刻", "寅时二刻", "寅时三刻", "寅时四刻"], ["朝霭", "拂晓", "破晓明星", "世间开明"]]
	for n in range(5):
		result.append(["th08-%d" % (172 + n * 4 + r), "「永夜归返 -%s-」" % nights[n][r], "kaguya_night_%d" % n, "final", {"last_spell": true, "survival": true, "duration": 6.0 + r * 0.8}])
	return result
