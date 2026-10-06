extends RefCounted

# Genbu Ravine: kedama and fairies from TH10 stage 3, rain-gear and engineering
# zombies, and mostly fused helmets. Brick resists magnets; kabuto and buckets
# do not, so the belt carries both answers.
const ENEMIES := [
	"kedama", "star_fairy", "cone_kedama", "bucket_kedama", "brick_kedama", "kabuto_kedama",
	"cone_star_fairy", "bucket_star_fairy", "brick_star_fairy", "kabuto_star_fairy",
	"cone_umbrella_zombie", "bucket_umbrella_zombie", "brick_ladder_zombie", "cone_jack_in_the_box_zombie",
	"kabuto_ninja", "bucket_newspaper", "cone_digger_zombie", "bucket_pogo_zombie",
]
const LEVEL := {
	"id": "4-21", "title": "东方 4-21 · 玄武之泽的河童",
	"description": "六行旱地岸台，瀑布在雨中轰鸣。道中河城荷取先以光学迷彩隐身偷袭，再宣告光学/水迷彩符卡；终末荷取展开洪水、水符与河童三组原作符卡，并逐级加入迷彩突击队、黄瓜诱饵、高压水炮与工房总动员。路灯花照出迷彩，叶子保护伞挡住会浇灭火炬树桩的水炮，本行大招清除积水。融合护甲毛玉、精灵与雨伞、扶梯、小丑盒僵尸持续进攻。E/N/H传送带，L自选卡。",
	"terrain": "nitori_waterfall", "mode": "conveyor", "boss_level": true,
	"unlock_requirements": ["4-20"], "water_rows": [], "row_count": 6,
	"mid_boss_kind": "nitori_boss", "mid_boss_final_preview": true, "mid_boss_locked_progress": 0.4,
	"mid_boss_banner": "河城荷取 · 雨幕中似乎有什么在发光……",
	"boss_intro_bgm": "res://audio/bgm/touhou/4-21-stage.mp3", "boss_bgm": "res://audio/bgm/touhou/4-21-ending.mp3",
	"enemy_whitelist": ENEMIES,
	"available_plants": ["peashooter", "repeater", "threepeater", "snow_pea", "split_pea", "wallnut", "tallnut", "pumpkin", "kernel_pult", "melon_pult", "torchwood", "plantern", "umbrella_leaf", "healing_gourd", "magnet_shroom", "starfruit", "spikeweed", "cherry_bomb", "jalapeno", "jasmine_tea"],
	"conveyor_plants": ["repeater", "repeater", "repeater", "threepeater", "threepeater", "snow_pea", "split_pea", "wallnut", "wallnut", "tallnut", "pumpkin", "kernel_pult", "melon_pult", "melon_pult", "torchwood", "plantern", "plantern", "umbrella_leaf", "umbrella_leaf", "healing_gourd", "healing_gourd", "magnet_shroom", "starfruit", "spikeweed", "cherry_bomb", "jalapeno", "jasmine_tea"],
	"conveyor_interval": Vector2(2.8, 4.0), "start_sun": 0, "unlock_plant": "",
	"time_scale": 0.86, "sky_sun_range": Vector2(99, 99), "node_pos": Vector2(2116, 548),
	"events": [
		{"time": 10.0, "kind": "kedama", "row": 1},
		{"time": 17.0, "kind": "star_fairy", "row": 4},
		{"time": 25.0, "kind": "cone_umbrella_zombie", "row": 2},
		{"time": 34.0, "kind": "flag", "wave": true},
		{"time": 41.0, "kind": "cone_kedama", "row": 5},
		{"time": 48.0, "kind": "cone_star_fairy", "row": 0},
		{"time": 56.0, "kind": "cone_jack_in_the_box_zombie", "row": 3},
		{"time": 65.0, "kind": "flag", "wave": true},
		{"time": 74.0, "kind": "bucket_umbrella_zombie", "row": 1},
		{"time": 83.0, "kind": "brick_ladder_zombie", "row": 4},
		{"time": 91.0, "kind": "bucket_star_fairy", "row": 2},
		{"time": 100.0, "kind": "flag", "wave": true},
		{"time": 109.0, "kind": "kabuto_ninja", "row": 5},
		{"time": 118.0, "kind": "brick_kedama", "row": 0},
		{"time": 127.0, "kind": "bucket_pogo_zombie", "row": 3},
		{"time": 136.0, "kind": "cone_digger_zombie", "row": 1},
		{"time": 145.0, "kind": "kabuto_star_fairy", "row": 4},
		{"time": 154.0, "kind": "bucket_newspaper", "row": 2},
		{"time": 162.0, "kind": "kabuto_kedama", "row": 5},
		{"time": 176.0, "kind": "nitori_boss", "row": 2},
	],
}
