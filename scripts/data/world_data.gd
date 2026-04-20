extends RefCounted
class_name WorldData


const WORLDS: Array = [
	{
		"key": "day",
		"title": "白天庭院",
		"subtitle": "Adventure 1-1 ~ 1-23",
		"description": "从单行开局到保龄球、传送带与白天 Boss，最右侧还藏着露米娅的血月支线 1-17、琪露诺的寒湖支线 1-18、美铃守门的 1-19、帕秋莉坐镇的 1-20 血色图书馆、咲夜压轴的 1-21 红魔馆时钟厅终幕、蕾米莉亚坐镇的 1-22 猩红长夜决战，以及最终由芙兰朵露守着的 1-23 血月玩具屋顶终幕。",
		"accent": Color(0.95, 0.76, 0.22),
		"accent_dark": Color(0.64, 0.42, 0.08),
		"panel": Color(0.98, 0.93, 0.78),
		"panel_dark": Color(0.86, 0.7, 0.36),
		"plants": ["peashooter", "sunflower", "wallnut", "repeater", "cherry_bomb"],
	},
	{
		"key": "night",
		"title": "夜幕庭院",
		"subtitle": "Adventure 2-1 ~ 2-17",
		"description": "夜晚无天降阳光，墓碑、新僵尸和夜晚植物体系完整展开，后段压力更高。",
		"accent": Color(0.72, 0.8, 1.0),
		"accent_dark": Color(0.26, 0.34, 0.56),
		"panel": Color(0.18, 0.24, 0.36),
		"panel_dark": Color(0.1, 0.14, 0.22),
		"plants": ["puff_shroom", "sun_shroom", "fume_shroom", "moon_lotus", "dream_drum"],
	},
	{
		"key": "pool",
		"title": "泳池时代",
		"subtitle": "Adventure 3-1 ~ 3-10",
		"description": "六行泳池、中央水路、冰道与游泳系僵尸同时展开，末段还会进入两张高压传送带关卡。",
		"accent": Color(0.18, 0.66, 0.9),
		"accent_dark": Color(0.08, 0.28, 0.5),
		"panel": Color(0.84, 0.96, 1.0),
		"panel_dark": Color(0.38, 0.68, 0.88),
		"plants": ["lily_pad", "threepeater", "tangle_kelp", "torchwood", "tallnut"],
	},
	{
		"key": "fog",
		"title": "浓雾后院",
		"subtitle": "Adventure 4-1 ~ 4-18",
		"description": "后院泳池被雾带吞没，前半段围绕路灯、三叶草与防空体系展开，后半段加入六株自定义雾系植物与五种高压新僵尸，最终在 4-17 的盐沼传送带和 4-18 的浓雾 Boss 终章收束。",
		"accent": Color(0.64, 0.86, 0.88),
		"accent_dark": Color(0.14, 0.24, 0.3),
		"panel": Color(0.84, 0.92, 0.9),
		"panel_dark": Color(0.26, 0.42, 0.46),
		"plants": ["sea_shroom", "plantern", "mist_orchid", "storm_reed", "moonforge"],
	},
	{
		"key": "roof",
		"title": "屋顶时代",
		"subtitle": "Adventure 5-1 ~ 5-17",
		"description": "白天战场被斜坡屋顶取代，花盆、投掷植物和伞叶体系接管节奏；后半段继续延展出纸鸢、电塔、风向与天窗炮台体系，最终会在 5-17 迎来屋顶终章 Boss 的空袭与工程封锁。",
		"accent": Color(0.9, 0.52, 0.22),
		"accent_dark": Color(0.5, 0.22, 0.08),
		"panel": Color(0.98, 0.9, 0.8),
		"panel_dark": Color(0.72, 0.48, 0.28),
		"plants": ["cabbage_pult", "flower_pot", "kernel_pult", "tesla_tulip", "skylight_melon"],
	},
	{
		"key": "city",
		"title": "城市世界",
		"subtitle": "Adventure 6-1 ~ 6-19",
		"description": "霓虹街区、广场砖面、地铁轨道与下水道井盖共同组成新的战场。后半段会被暴风雪席卷，寒潮会覆盖整片城市战场，并在 6-19 由霓虹尸王把几乎全部非 Boss 僵尸混编进城市终章。",
		"accent": Color(0.4, 0.76, 0.92),
		"accent_dark": Color(0.08, 0.18, 0.32),
		"panel": Color(0.86, 0.94, 0.98),
		"panel_dark": Color(0.34, 0.46, 0.58),
		"plants": ["heather_shooter", "leyline", "holo_nut", "healing_gourd", "mango_bowling"],
	},
]


static func all() -> Array:
	return WORLDS


static func by_key(key: String) -> Dictionary:
	for world in WORLDS:
		if String(world["key"]) == key:
			return world
	return WORLDS[0]


static func index_of(key: String) -> int:
	for i in range(WORLDS.size()):
		if String(WORLDS[i]["key"]) == key:
			return i
	return 0
