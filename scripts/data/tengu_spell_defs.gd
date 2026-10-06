extends RefCounted

# TH10 practice IDs043–057. Momiji's named guard cards are lane adaptations;
# the original waterfall midboss uses unnamed nonspells.
const KINDS := ["momiji_boss", "aya_boss"]
const MOMIJI_PATROL := ["th10-momiji-patrol-nonspell", "非符 · 九天瀑布的白狼警戒", "nonspell_momiji_patrol", "patrol", {"duration":4.5}]
const MOMIJI_CROSS := ["th10-momiji-cross-nonspell", "非符 · 白狼天狗的交错剑阵", "nonspell_momiji_cross", "slash", {"duration":4.8}]
const MOMIJI_GUARD := ["original-momiji-sentinel", "符卡 · 哨戒「千里眼的巡山剑盾」", "momiji_sentinel", "guard", {"duration":7.5}]
const MOMIJI_MAPLE := ["original-momiji-maple-guard", "符卡 · 白狼「九天瀑布的枫盾围阵」", "momiji_maple_guard", "shield", {"duration":8.0}]
const AYA_OPENING := ["th10-aya-wind-nonspell", "非符 · 妖怪之山的疾风天狗", "nonspell_aya_wind", "wind", {"duration":4.0}]
const ORIGINALS := [
	["original-aya-headwind", "符卡 · 风垄「逆风的六畦苗圃」", "aya_headwind", "wind", {"duration":10.0}],
	["original-aya-report", "符卡 · 取材「文文。融合花圃特刊」", "aya_report", "fan", {"duration":10.0}],
	["original-aya-cyclone", "符卡 · 旋风「落叶回廊」", "aya_cyclone", "cyclone", {"duration":10.5}],
	["original-aya-wind-fence", "符卡 · 封路「山腰风栅」", "aya_wind_fence", "barrier", {"duration":10.5}],
	["original-aya-extra-edition", "符卡 · 号外「追风的天狗增援」", "aya_extra_edition", "fan", {"duration":11.0}],
	["original-aya-relay", "符卡 · 疾风「六道残影接力」", "aya_relay", "dash", {"duration":11.0}],
]

static func rank(level: Dictionary) -> int:
	return maxi(0, ["easy","normal","hard","lunatic"].find(String(level.get("touhou_difficulty","easy"))))

static func cards(kind: String, level: Dictionary) -> Array:
	var r := rank(level)
	if kind == "momiji_boss":
		var guard: Array = [MOMIJI_GUARD.duplicate(true)]
		if r >= 2: guard.append(MOMIJI_MAPLE.duplicate(true))
		return guard
	if kind != "aya_boss": return []
	var paths: Array = ["岐符「天之八衢」","aya_crossroads"] if r < 2 else ["岐符「猿田彦神之岔路」","aya_saruta_cross"]
	var wind: Array = [["风神「风神木叶隐身术」","aya_leaf_veiling"],["风神「风神木叶隐身术」","aya_leaf_veiling"],["风神「天狗颪」","aya_tengu_fall"],["风神「二百十日」","aya_storm_day"]][r]
	# The survival THIRD group precedes the blockade FOURTH group.
	var blockade: Array = [["塞符「山神渡御」","aya_procession"],["塞符「山神渡御」","aya_procession"],["塞符「天孙降临」","aya_divine_advent"],["塞符「天上天下的照国」","aya_terukuni"]][r]
	var result: Array = [["th10-%03d"%(43+r),paths[0],paths[1],"cross",{"duration":9.0}],["th10-%03d"%(47+r),wind[0],wind[1],"leaves",{"duration":10.0}]]
	for i in range(3+r): result.append(ORIGINALS[i].duplicate(true))
	if r > 0: result.append(["th10-%03d"%(50+r),"「无双风神」" if r==3 else "「幻想风靡」","aya_peerless_wind" if r==3 else "aya_fantasy_storm","dash",{"survival":true,"duration":22.0 if r==3 else 18.0}])
	result.append(["th10-%03d"%(54+r),blockade[0],blockade[1],"barrier",{"duration":12.0,"last_spell":true}])
	return result

static func phases(kind: String, level: Dictionary) -> Array:
	if kind == "momiji_boss":
		var result: Array = [[MOMIJI_PATROL.duplicate(true)],[MOMIJI_CROSS.duplicate(true),MOMIJI_GUARD.duplicate(true)]]
		if rank(level)>=2: result.append([MOMIJI_MAPLE.duplicate(true)])
		return result
	var result: Array = []
	for entry in cards(kind,level): result.append([entry] if String(entry[0]).begins_with("original-") or bool(entry[4].get("survival",false)) else [AYA_OPENING.duplicate(true),entry])
	return result
