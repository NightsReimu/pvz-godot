extends RefCounted

const ROAD_ENEMIES := ["ducky_tube","snorkel","dolphin_rider","cone_snorkel","bucket_snorkel","brick_snorkel","kabuto_snorkel","cone_dolphin_rider","bucket_dolphin_rider","kedama","star_fairy","cone_kedama","bucket_kedama","cone_star_fairy","bucket_star_fairy","kabuto_star_fairy"]
const FINAL_ENEMIES := ["kedama","star_fairy","cone_kedama","bucket_kedama","brick_kedama","kabuto_kedama","cone_star_fairy","bucket_star_fairy","brick_star_fairy","kabuto_star_fairy","cone_ninja","kabuto_ninja","bucket_newspaper","brick_ladder_zombie","bucket_pogo_zombie","cone_jack_in_the_box_zombie","bucket_umbrella_zombie","football_ninja"]
const LEVEL := {
	"id":"4-22", "title":"东方 4-22 · 九天瀑布与要塞之山",
	"description":"长道中穿过六行瀑布水路，犬走椛以巡山剑盾警戒。射命丸文登场后六行转为山腰旱地，保留已种阵型；她乘风极速换行，残影、交叉风路和叶刃环压迫花圃。四档原作岐符、风神和塞符，以及Normal以上的幻想风靡/无双风神耐久依序展开。逆风苗圃、融合花圃取材和旋风回廊等符卡针对阵型；伞叶庇护、路灯显形、本行大招清除风压。融合水兵、毛玉、精灵与山路护甲援军持续进攻。E/N/H传送带，L自选卡。",
	"terrain":"tengu_waterfall", "mode":"conveyor", "boss_level":true,
	"unlock_requirements":["4-21"], "water_rows":[0,1,2,3,4,5], "row_count":6,
	"mid_boss_kind":"momiji_boss", "mid_boss_locked_progress":0.4,
	"mid_boss_banner":"犬走椛 · 白狼天狗的瀑布哨戒",
	"boss_intro_bgm":"res://audio/bgm/touhou/4-22-stage.mp3", "boss_bgm":"res://audio/bgm/touhou/4-22-ending.mp3",
	"enemy_whitelist":ROAD_ENEMIES+FINAL_ENEMIES,
	"preplaced_support_kind":"lily_pad",
	"preplaced_supports":[Vector2i(0,1),Vector2i(0,2),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1),Vector2i(2,2),Vector2i(3,1),Vector2i(3,2),Vector2i(4,1),Vector2i(4,2),Vector2i(5,1),Vector2i(5,2)],
	"available_plants":["lily_pad","sea_shroom","tangle_kelp","repeater","threepeater","snow_pea","split_pea","cactus","starfruit","wallnut","tallnut","pumpkin","kernel_pult","melon_pult","torchwood","plantern","umbrella_leaf","healing_gourd","magnet_shroom","cherry_bomb","jalapeno","jasmine_tea","mirror_reed"],
	"conveyor_plants":["lily_pad","lily_pad","lily_pad","lily_pad","sea_shroom","tangle_kelp","repeater","repeater","repeater","threepeater","threepeater","snow_pea","split_pea","cactus","starfruit","wallnut","wallnut","tallnut","pumpkin","kernel_pult","melon_pult","melon_pult","torchwood","plantern","umbrella_leaf","umbrella_leaf","healing_gourd","healing_gourd","magnet_shroom","cherry_bomb","jalapeno","jasmine_tea","mirror_reed"],
	"conveyor_interval":Vector2(2.8,4.0), "start_sun":0, "unlock_plant":"", "time_scale":0.86,
	"sky_sun_range":Vector2(99,99), "node_pos":Vector2(2320,482),
	"events":[
		{"time":12.0,"kind":"ducky_tube","row":1},{"time":20.0,"kind":"kedama","row":4},
		{"time":29.0,"kind":"star_fairy","row":0},{"time":38.0,"kind":"cone_snorkel","row":5},
		{"time":47.0,"kind":"flag","wave":true},{"time":57.0,"kind":"cone_kedama","row":2},
		{"time":66.0,"kind":"cone_star_fairy","row":3},{"time":75.0,"kind":"dolphin_rider","row":1},
		{"time":85.0,"kind":"flag","wave":true},{"time":95.0,"kind":"bucket_snorkel","row":4},
		{"time":106.0,"kind":"bucket_star_fairy","row":0},{"time":118.0,"kind":"cone_dolphin_rider","row":5},
		{"time":133.0,"kind":"flag","wave":true},{"time":143.0,"kind":"bucket_kedama","row":2},
		{"time":153.0,"kind":"brick_snorkel","row":3},{"time":163.0,"kind":"star_fairy","row":1},
		{"time":174.0,"kind":"flag","wave":true},{"time":184.0,"kind":"bucket_dolphin_rider","row":4},
		{"time":195.0,"kind":"kabuto_star_fairy","row":0},{"time":205.0,"kind":"kabuto_snorkel","row":5},
		{"time":216.0,"kind":"flag","wave":true},{"time":226.0,"kind":"bucket_kedama","row":2},
		{"time":236.0,"kind":"bucket_snorkel","row":3},{"time":246.0,"kind":"bucket_star_fairy","row":1},
		{"time":256.0,"kind":"flag","wave":true},{"time":266.0,"kind":"brick_snorkel","row":4},
		{"time":276.0,"kind":"kabuto_star_fairy","row":0},{"time":286.0,"kind":"bucket_dolphin_rider","row":5},
		{"time":300.0,"kind":"aya_boss","row":2},
	],
}
