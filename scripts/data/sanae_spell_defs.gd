extends RefCounted

# TH10 stage5 practice058–061 is the MIDBOSS, not a fifth finale spell.
const OPENING := ["th10-sanae-nonspell","非符 · 风祝的青白御币","nonspell_sanae_ofuda","shot",{"duration":4.2}]
const ORIGINALS := [
	["original-sanae-frog-procession","符卡 · 蛙符「守矢的跃步参拜」","sanae_frog_procession","frog",{"duration":10.5}],
	["original-sanae-frog-garden","符卡 · 神德「六畦花圃的蛙之奇迹」","sanae_frog_garden","prayer",{"duration":10.5}],
	["original-sanae-weather","符卡 · 祈雨「五色天象的苗圃」","sanae_weather","prayer",{"duration":11.0}],
	["original-sanae-rice","符卡 · 丰穰「神社的融合贡穗」","sanae_rice","shot",{"duration":11.0}],
	["original-sanae-pillars","符卡 · 神域「御柱之间的风蛇」","sanae_pillars","wind",{"duration":11.0}],
	["original-sanae-faith","符卡 · 信仰「现人神的六道奇迹」","sanae_faith","final",{"duration":12.0}],
]
static func rank(level:Dictionary)->int:return maxi(0,["easy","normal","hard","lunatic"].find(String(level.get("touhou_difficulty","easy"))))
static func road_card(level:Dictionary)->Array:
	var r:=rank(level)
	return ["th10-%03d"%(58+r),["秘术「Gray Thaumaturgy」","秘术「Gray Thaumaturgy」","秘术「遗忘之祭仪」","秘术「一子相传的弹幕」"][r],"sanae_ritual","prayer",{"duration":9.0,"ritual_stars":6 if r==0 else 10}]
static func road_phases(level:Dictionary)->Array:return [[OPENING.duplicate(true)],[road_card(level)]]
static func cards(_kind:String,level:Dictionary)->Array:
	var r:=rank(level)
	var result:Array=[
		["th10-%03d"%(62+r),["奇迹「白昼的客星」","奇迹「白昼的客星」","奇迹「客星明亮之夜」","奇迹「客星过于明亮之夜」"][r],"sanae_guest_stars","stars",{"duration":10.5}],
		["th10-%03d"%(66+r),"开海「海水分开之日」" if r<2 else "开海「摩西的奇迹」","sanae_sea_opening","sweep",{"duration":11.0}],
	]
	for i in range(3+r):result.append(ORIGINALS[i].duplicate(true))
	# The preparing ritual directly precedes the culminating wind, as in TH10.
	result.append(["th10-%03d"%(70+r),"准备「呼唤神风的星之仪式」" if r<2 else "准备「召唤建御名方神」","sanae_prepare","prayer",{"duration":12.0}])
	result.append(["th10-%03d"%(74+r),"奇迹「神之风」" if r<2 else "大奇迹「八坂之神风」","sanae_divine_wind","final",{"duration":13.0,"last_spell":true}])
	return result
static func phases(kind:String,level:Dictionary)->Array:
	var result:Array=[]
	for card in cards(kind,level):result.append([OPENING.duplicate(true),card] if String(card[0]).begins_with("th10-") else [card])
	return result
