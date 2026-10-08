extends RefCounted

# Every campaign world can visit the summit: ordinary, armoured and fused land
# enemies alike. Water-only units, sleds, fliers and other Bosses stay home.
const ENEMIES := [
	"normal","flag","conehead","buckethead","pole_vault","newspaper","screen_door","football","dark_football","dancing","ninja",
	"farmer","spear","kungfu","basketball","qinghua","shouyue","kite_zombie","hive_zombie",
	"balloon_zombie","digger_zombie","pogo_zombie","jack_in_the_box_zombie","squash_zombie","barrel_screen_zombie","tornado_zombie","wolf_knight_zombie",
	"ladder_zombie","catapult_zombie","imp","gargantuar","wenjie_zombie","janitor_zombie","wither_zombie","wizard_zombie","umbrella_zombie","shade_zombie",
	"kedama","star_fairy","ancient_samurai","ancient_mage","cinder_runner","basalt_guard","kiln_mason","ash_bell","geode_zombie",
	"cone_kedama","bucket_kedama","brick_kedama","kabuto_kedama","cone_star_fairy","bucket_star_fairy","brick_star_fairy","kabuto_star_fairy",
	"cone_ninja","kabuto_ninja","football_ninja","bucket_newspaper","brick_ladder_zombie","bucket_pogo_zombie","cone_jack_in_the_box_zombie","bucket_umbrella_zombie",
	"cone_backup_dancer","bucket_screen_door","cone_digger_zombie","kabuto_imp","brick_wolf_knight_zombie","bucket_farmer","kabuto_spear","cone_qinghua",
	"brick_wizard_zombie","bucket_wither_zombie","kabuto_ancient_mage","bucket_cinder_runner","cone_balloon_zombie","football_kungfu","cone_shade_zombie_door","ninja_door",
]
# Finale reinforcements keep the same variety without stacking two giants.
const FINAL_ENEMIES := [
	"conehead","buckethead","newspaper","football","ninja","spear","kungfu","qinghua","pogo_zombie","jack_in_the_box_zombie","ladder_zombie","imp","wolf_knight_zombie",
	"wizard_zombie","umbrella_zombie","kedama","star_fairy","ancient_mage","cinder_runner","kiln_mason",
	"cone_kedama","bucket_kedama","brick_kedama","kabuto_star_fairy","cone_ninja","kabuto_ninja","bucket_newspaper","brick_ladder_zombie","bucket_pogo_zombie",
	"bucket_umbrella_zombie","cone_backup_dancer","kabuto_imp","brick_wolf_knight_zombie","kabuto_spear","bucket_cinder_runner","football_kungfu",
]
const LEVEL := {
	"id":"4-24","title":"东方 4-24 · 御柱林立的风神之社",
	"description":"妖怪之山山顶，守矢神社的御柱林立在风神之湖畔，六行全陆地神域石庭。本关没有道中Boss：四波道中涌来各个世界的普通、护甲与融合僵尸，晴、东风、细雨、雷暴、烈日与虹光轮流改变战场。终末八坂神奈子依风神录6面展开四段非符与原作五组符卡（E/N扩展御柱·神之粥·御射山御狩神事·天水奇迹·Mountain of Faith，H/L目处梃子乱舞·忘谷/神谷·葛井之清水/Yamato Torus·雨之源泉·风神之神德），并按难度加入御柱坠落、注连封锁、山岳天候、军神进军、白蛇巡游与六道御柱阵原创符卡。伞叶挡住坠柱，火焰烧断注连绳，击倒御柱为本行植物返还信仰充能，本行大招解除束缚与军神加护。E/N/H慢传送带，L自选卡。",
	"terrain":"kanako_onbashira_shrine","mode":"conveyor","boss_level":true,
	"unlock_requirements":["4-23"],"row_count":6,"water_rows":[],
	"boss_intro_bgm":"res://audio/bgm/touhou/4-24-stage.mp3","boss_bgm":"res://audio/bgm/touhou/4-24-ending.mp3",
	"weather_schedule":[{"weather":"clear","duration":34.0},{"weather":"wind","duration":30.0},{"weather":"rain","duration":28.0},{"weather":"storm","duration":22.0},{"weather":"sunny","duration":26.0},{"weather":"rainbow","duration":26.0}],
	"enemy_whitelist":ENEMIES,
	"available_plants":["repeater","threepeater","snow_pea","split_pea","cactus","starfruit","wallnut","tallnut","pumpkin","kernel_pult","melon_pult","torchwood","plantern","umbrella_leaf","healing_gourd","magnet_shroom","spikeweed","cherry_bomb","jalapeno","jasmine_tea","mirror_reed","electric_bonk_choy","dandelion"],
	"conveyor_plants":["repeater","repeater","repeater","threepeater","threepeater","snow_pea","split_pea","cactus","starfruit","wallnut","wallnut","tallnut","pumpkin","kernel_pult","melon_pult","melon_pult","torchwood","torchwood","plantern","umbrella_leaf","umbrella_leaf","healing_gourd","healing_gourd","magnet_shroom","spikeweed","cherry_bomb","jalapeno","jasmine_tea","mirror_reed","electric_bonk_choy","dandelion"],
	"conveyor_interval":Vector2(2.8,4.0),"start_sun":0,"unlock_plant":"","time_scale":0.86,"sky_sun_range":Vector2(99,99),"node_pos":Vector2(2712,344),
	"events":[
		{"time":12.0,"kind":"kedama","row":2},{"time":21.0,"kind":"conehead","row":4},{"time":30.0,"kind":"star_fairy","row":0},{"time":40.0,"kind":"flag","wave":true},
		{"time":52.0,"kind":"cone_qinghua","row":3},{"time":63.0,"kind":"newspaper","row":1},{"time":74.0,"kind":"cinder_runner","row":5},{"time":86.0,"kind":"flag","wave":true},
		{"time":98.0,"kind":"bucket_kedama","row":2},{"time":109.0,"kind":"football","row":4},{"time":120.0,"kind":"kabuto_spear","row":0},{"time":131.0,"kind":"wizard_zombie","row":3},{"time":140.0,"kind":"flag","wave":true},
		{"time":151.0,"kind":"ancient_mage","row":5},{"time":160.0,"kind":"brick_wolf_knight_zombie","row":1},{"time":168.0,"kind":"bucket_umbrella_zombie","row":2},{"time":175.0,"kind":"gargantuar","row":3},{"time":182.0,"kind":"flag","wave":true},
		{"time":192.0,"kind":"kanako_boss","row":2},
	],
}
