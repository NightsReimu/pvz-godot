extends RefCounted

# Separate from campaign levels: all challenges loan their seed cards.
const ENTRIES := [
	{"id":"rain", "title":"雨中种植物", "icon":"lily_pad", "color":"709ac2", "tag":"落种 · 暴雨泳池", "description":"点击雨中落下的种子收入卡槽，再免费种植。种子会过期，水路先放睡莲。", "goal":"守住 6 波尸潮"},
	{"id":"gems", "title":"宝石连连看", "icon":"repeater", "color":"a986ce", "tag":"交换 · 活体三消", "description":"依次点击两株相邻植物进行交换。三个同类成线消除补种，植物同时抵御僵尸。", "goal":"累计消除 50 组"},
	{"id":"invisible", "title":"隐形僵尸", "icon":"plantern", "color":"8397ad", "tag":"传送带 · 寻迹防守", "description":"脚印暴露行踪，受击与冰冻让僵尸现形。用路灯照亮周围，再布置交叉火力。", "goal":"守住 6 波隐形尸潮"},
	{"id":"stars", "title":"星星果", "icon":"starfruit", "color":"d5b65d", "tag":"布阵 · 点亮星图", "description":"在所有金色标记上同时种下星星果。可以先种其他植物防守，再铲除调整阵型。", "goal":"点亮全部 14 个星位"},
	{"id":"bare", "title":"无草皮之地", "icon":"flower_pot", "color":"b28c71", "tag":"花盆 · 五轮布防", "description":"石地先放花盆。初始 5000 阳光，无天降阳光；每轮后补给 250，点击出击继续。", "goal":"有限资源守住 5 轮"},
	{"id":"portals", "title":"保护传送门", "icon":"wallnut", "color":"74b9b2", "tag":"守护 · 空间换路", "description":"守住两座蓝色核心。紫色入口把僵尸送到核心前方；入口定期换路，提前补防。", "goal":"两座核心存活并守住 6 波"},
	{"id":"columns", "title":"排山倒海", "icon":"melon_pult", "color":"d38e6e", "tag":"屋顶 · 整列种植", "description":"一张卡种满一整列的可用空位。先整列放花盆，再投下成排的植物；已有植物保留。", "goal":"守住 6 波屋顶尸潮"},
]

const STAR_CELLS := [Vector2i(0,4), Vector2i(1,3), Vector2i(1,5), Vector2i(2,1), Vector2i(2,2), Vector2i(2,3), Vector2i(2,5), Vector2i(2,6), Vector2i(2,7), Vector2i(3,2), Vector2i(3,6), Vector2i(4,1), Vector2i(4,4), Vector2i(4,7)]

static func entry(id: String) -> Dictionary:
	for item in ENTRIES:
		if item.id == id: return item.duplicate(true)
	return {}

static func level(id: String) -> Dictionary:
	var info := entry(id)
	if info.is_empty(): return {}
	var cards: Array = ["sunflower", "peashooter", "snow_pea", "wallnut", "cherry_bomb", "starfruit", "healing_gourd", "repeater"]
	var result := {"id":"mini-" + id, "minigame":id, "title":info.title, "description":info.description, "custom_level":true, "world":"day", "terrain":"day", "row_count":5, "water_rows":[], "start_sun":250, "sky_sun_range":Vector2(4,7), "unlock_plant":"", "mode":"normal", "events":[]}
	match id:
		"rain":
			cards = ["lily_pad", "peashooter", "repeater", "snow_pea", "wallnut", "cherry_bomb", "tangle_kelp", "starfruit"]
			result.merge({"world":"fog", "terrain":"storm_fog", "row_count":6, "water_rows":[2,3], "mode":"conveyor", "start_sun":0}, true)
		"gems":
			cards = []
			result.start_sun = 0
		"invisible":
			cards = ["peashooter", "repeater", "snow_pea", "wallnut", "plantern", "cherry_bomb", "starfruit"]
			result.mode = "conveyor"
			result.start_sun = 0
		"stars":
			cards = ["sunflower", "starfruit", "peashooter", "wallnut", "cherry_bomb", "healing_gourd"]
			result.start_sun = 400
		"bare":
			cards = ["flower_pot", "cabbage_pult", "kernel_pult", "melon_pult", "wallnut", "snow_pea", "cherry_bomb", "healing_gourd"]
			result.start_sun = 5000
		"portals":
			result.start_sun = 600
		"columns":
			cards = ["flower_pot", "cabbage_pult", "kernel_pult", "melon_pult", "wallnut", "cherry_bomb"]
			result.merge({"world":"roof", "terrain":"roof", "mode":"conveyor", "start_sun":0}, true)
	result.available_plants = cards.duplicate()
	result.minigame_cards = cards.duplicate()
	if result.mode == "conveyor": result.conveyor_plants = cards.duplicate()
	for wave in range(5 if id == "bare" else 6):
		for n in range(10 + wave * 2):
			var pool: Array = ["normal", "normal", "conehead"]
			if wave >= 2: pool.append("buckethead")
			if wave >= 3: pool.append("newspaper")
			if wave >= 4: pool.append("football")
			var row := (n + wave * 2) % int(result.row_count)
			var kind: String = pool[(n * 3 + wave + n / 3) % pool.size()]
			if id == "rain" and row in [2,3]: kind = "ducky_tube" if wave < 3 else "lifebuoy_cone"
			result.events.append({"kind":kind, "row":row, "mini_wave":wave + 1})
	return result
