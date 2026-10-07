extends RefCounted

# Visitors from every campaign world; water-only units and other bosses stay
# in their native stages. Reinforcement selection uses the same safe roster.
const ENEMIES := ["normal","conehead","buckethead","screen_door","newspaper","football","pole_vault","ladder_zombie","pogo_zombie","digger_zombie","balloon_zombie","jack_in_the_box_zombie","umbrella_zombie","ninja","kedama","star_fairy","cone_kedama","bucket_kedama","brick_kedama","kabuto_kedama","cone_star_fairy","bucket_star_fairy","brick_star_fairy","kabuto_star_fairy","cone_ninja","kabuto_ninja","bucket_newspaper","brick_ladder_zombie","bucket_pogo_zombie","cone_jack_in_the_box_zombie","bucket_umbrella_zombie","football_ninja","ancient_samurai","ancient_mage","cinder_runner","basalt_guard","kiln_mason","ash_bell","geode_zombie","imp","dark_football","barrel_screen_zombie","wolf_knight_zombie"]
const LEVEL := {
	"id":"4-23","title":"东方 4-23 · 山顶神社的现人神",
	"description":"登上妖怪之山的守矢神社，六行全陆地青石庭院，四御柱、注连绳与社殿立于云海之上。风祝早苗道中以弱化秘术星阵迎战；终末客星、开海、神风准备与神风按四档展开。晴、风、雨、雷暴、虹光实际改变战斗，青蛙使魔跃入阵型，预警后短暂蛙化植物；伞叶、圣光与本行大招可反制。各世界普通、护甲与融合僵尸持续登场，E/N/H慢传送带，L自选卡。",
	"terrain":"sanae_moriya_shrine","mode":"conveyor","boss_level":true,
	"unlock_requirements":["4-22"],"row_count":6,"water_rows":[],
	"mid_boss_kind":"sanae_boss","mid_boss_final_preview":true,"mid_boss_locked_progress":0.4,"mid_boss_time":105.0,"timed_touhou_road":true,
	"mid_boss_banner":"东风谷早苗 · 山顶的秘术祭仪",
	"boss_intro_bgm":"res://audio/bgm/touhou/4-23-stage.mp3","boss_bgm":"res://audio/bgm/touhou/4-23-ending.mp3",
	"weather_schedule":[{"weather":"clear","duration":36.0},{"weather":"wind","duration":32.0},{"weather":"rain","duration":32.0},{"weather":"storm","duration":24.0},{"weather":"rainbow","duration":30.0}],
	"enemy_whitelist":ENEMIES,
	"available_plants":["repeater","threepeater","snow_pea","split_pea","cactus","starfruit","wallnut","tallnut","pumpkin","kernel_pult","melon_pult","torchwood","plantern","umbrella_leaf","healing_gourd","magnet_shroom","cherry_bomb","jalapeno","jasmine_tea","mirror_reed","electric_bonk_choy","dandelion"],
	"conveyor_plants":["repeater","repeater","repeater","threepeater","threepeater","snow_pea","split_pea","cactus","starfruit","wallnut","wallnut","tallnut","pumpkin","kernel_pult","melon_pult","melon_pult","torchwood","plantern","umbrella_leaf","umbrella_leaf","healing_gourd","healing_gourd","magnet_shroom","cherry_bomb","jalapeno","jasmine_tea","mirror_reed","electric_bonk_choy","dandelion"],
	"conveyor_interval":Vector2(2.8,4.0),"start_sun":0,"unlock_plant":"","time_scale":0.86,"sky_sun_range":Vector2(99,99),"node_pos":Vector2(2520,416),
	"events":[
		{"time":12.0,"kind":"kedama","row":1},{"time":22.0,"kind":"normal","row":4},{"time":33.0,"kind":"conehead","row":0},{"time":43.0,"kind":"flag","wave":true},
		{"time":55.0,"kind":"cone_star_fairy","row":3},{"time":67.0,"kind":"newspaper","row":2},{"time":79.0,"kind":"cinder_runner","row":5},{"time":91.0,"kind":"flag","wave":true},
		{"time":120.0,"kind":"bucket_kedama","row":1},{"time":132.0,"kind":"football","row":4},{"time":144.0,"kind":"bucket_star_fairy","row":0},{"time":156.0,"kind":"flag","wave":true},
		{"time":168.0,"kind":"ancient_mage","row":3},{"time":180.0,"kind":"bucket_umbrella_zombie","row":2},{"time":192.0,"kind":"basalt_guard","row":5},{"time":204.0,"kind":"flag","wave":true},
		{"time":216.0,"kind":"brick_kedama","row":1},{"time":228.0,"kind":"bucket_newspaper","row":4},{"time":240.0,"kind":"kabuto_star_fairy","row":0},{"time":252.0,"kind":"flag","wave":true},
		{"time":264.0,"kind":"ancient_samurai","row":3},{"time":276.0,"kind":"brick_ladder_zombie","row":2},{"time":288.0,"kind":"bucket_pogo_zombie","row":5},{"time":300.0,"kind":"sanae_boss","row":2},
	],
}
