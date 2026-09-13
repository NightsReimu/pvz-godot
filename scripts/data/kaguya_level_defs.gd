extends RefCounted

const Eirin = preload("res://scripts/data/eirin_level_defs.gd")

# A shared source prevents the two approved road routes drifting apart.
static func level() -> Dictionary:
	var result: Dictionary = Eirin.LEVEL.duplicate(true)
	result.merge({
		"id": "3-24-b", "title": "泳池时代 3-24-b · 五道难题",
		"description": "与六面A共用永琳道中，击破后辉夜展开五道难题与五段永夜归返。打碎石钵和子安贝解除护阵与复苏；回溯倒计时结束时，植物和小怪回到记录时的生死与位置，期间新种的植物也会消失。带好葫芦和三种地形底座。",
		"node_pos": Vector2(1980, 510), "branch_from": "3-23",
		"boss_bgm": "res://audio/th08_kaguya_boss.mp3",
	}, true)
	result.events.back().kind = "kaguya_boss"
	return result
