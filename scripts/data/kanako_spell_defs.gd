extends RefCounted

# TH10 stage6 has no midboss. Kanako's practice IDs078–097 form five groups of
# four tiers; each of the first four is preceded by its own nonspell, while the
# last card follows the Otensui group directly.
const NONSPELLS := [
	["th10-kanako-twin-nonspell","非符 · 双源乱射的神威","nonspell_kanako_twin","mirror",{"duration":4.6}],
	["th10-kanako-drift-nonspell","非符 · 偏移的青赤神札","nonspell_kanako_drift","shot",{"duration":4.6}],
	["th10-kanako-cross-nonspell","非符 · 交错的神域弹列","nonspell_kanako_cross","channel",{"duration":4.6}],
	["th10-kanako-cycle-nonspell","非符 · 大玉、刃与中玉","nonspell_kanako_cycle","arrow",{"duration":5.2}],
]
# Lane adaptations authored for this game. They show only “符卡” in battle and
# never claim a TH10 practice number.
const ORIGINALS := [
	["original-kanako-pillar-fall","符卡 · 御柱「天降六畦的御柱祭」","kanako_pillar_fall","pillar",{"duration":11.0}],
	["original-kanako-shimenawa","符卡 · 注连「封锁苗圃的注连绳」","kanako_shimenawa","mirror",{"duration":11.0}],
	["original-kanako-weather","符卡 · 风雨「御神渡的山岳天候」","kanako_weather","wind",{"duration":11.0}],
	["original-kanako-war-god","符卡 · 军神「八坂军旗的总进军」","kanako_war_god","arrow",{"duration":11.5}],
	["original-kanako-serpent","符卡 · 蛇神「御射山的白蛇巡游」","kanako_serpent","storm",{"duration":11.5}],
	["original-kanako-faith","符卡 · 神德「守矢神域的六道御柱阵」","kanako_faith","final",{"duration":12.5}],
]
static func rank(level:Dictionary)->int:return maxi(0,["easy","normal","hard","lunatic"].find(String(level.get("touhou_difficulty","easy"))))
static func canonical(level:Dictionary)->Array:
	var r:=rank(level)
	return [
		["th10-%03d"%(78+r),["神祭「Expanded Onbashira」","神祭「Expanded Onbashira」","奇祭「目处梃子乱舞」","奇祭「目处梃子乱舞」"][r],"kanako_onbashira" if r<2 else "kanako_medoteko","pillar",{"duration":10.5}],
		["th10-%03d"%(82+r),["筒粥「神之粥」","筒粥「神之粥」","忘谷「Unremembered Crop」","神谷「Divining Crop」"][r],["kanako_porridge","kanako_porridge","kanako_unremembered","kanako_divining"][r],"wind",{"duration":10.5}],
		["th10-%03d"%(86+r),["贽符「御射山御狩神事」","贽符「御射山御狩神事」","神秘「葛井之清水」","神秘「Yamato Torus」"][r],["kanako_misayama","kanako_misayama","kanako_kuzui","kanako_yamato_torus"][r],"arrow" if r<2 else "mirror",{"duration":11.0}],
		["th10-%03d"%(90+r),"天流「天水奇迹」" if r<2 else "天龙「雨之源泉」","kanako_otensui" if r<2 else "kanako_rain_source","channel",{"duration":11.0}],
		["th10-%03d"%(94+r),"「Mountain of Faith」" if r<2 else "「风神之神德」","kanako_mountain_of_faith" if r<2 else "kanako_wind_god_virtue","final",{"duration":13.5,"last_spell":true}],
	]
static func originals(level:Dictionary)->Array:
	var result:Array=[]
	for i in range(3+rank(level)):result.append(ORIGINALS[i].duplicate(true))
	return result
static func cards(_kind:String,level:Dictionary)->Array:
	var canon:=canonical(level);var extra:=originals(level)
	# Originals alternate with the canonical groups; the last spell stays last.
	var result:Array=[canon[0],extra[0],canon[1],extra[1],canon[2],extra[2]]
	if extra.size()>3:result.append(extra[3])
	result.append(canon[3])
	for i in range(4,extra.size()):result.append(extra[i])
	result.append(canon[4])
	return result
static func phases(kind:String,level:Dictionary)->Array:
	var result:Array=[]
	var canon_index:=0
	for card in cards(kind,level):
		if String(card[0]).begins_with("th10-") and canon_index<NONSPELLS.size():
			result.append([NONSPELLS[canon_index].duplicate(true),card])
			canon_index+=1
		else:result.append([card])
	return result
