extends RefCounted

# Every ordinary spawn source uses this pool, including EX+ support waves.
const ENEMIES := ["normal", "flag", "conehead", "buckethead", "newspaper", "screen_door", "pole_vault", "football", "dark_football", "kedama", "mini_kedama", "moon_rabbit", "moon_rabbit_guard"]
const PLANTS := [ "plasma_shooter", "amber_shooter", "phoenix_tree", "shadow_pea", "snow_pea", "frost_boomerang", "pressure_bamboo", "starfruit", "mirror_reed", "healing_gourd", "pumice_wall", "umbrella_leaf", "cherry_bomb", "jalapeno", "ice_shroom"]
const LEVEL := {
	"id": "3-25", "title": "泳池时代 3-25 · 蓬莱人形",
	"description": "永夜抄EX：穿过深夜竹林，击破半兽慧音的三段历史，再挑战藤原妹红。留意左右球拍的发球预警；寒冰攻击可扑灭余烬格，及时补种、治疗并用镜芦苇返弹。EX+追加史格封印、双球连打和涅槃火圈。",
	"terrain": "reimu_midnight_bamboo", "water_rows": [], "grave_layout": [],
	"mode": "conveyor", "boss_level": true, "touhou_extra": true, "row_count": 6,
	"mid_boss_kind": "hakutaku_boss", "mid_boss_locked_progress": 0.42,
	"mid_boss_banner": "半兽慧音现身 · 旧史、一条归桥、新幻想史",
	"unlock_requirements": ["3-24-a", "3-24-b"], "branch_from": "3-24-b", "node_pos": Vector2(2200, 430),
	"boss_intro_bgm": "res://audio/th08_extra_stage.mp3", "boss_bgm": "res://audio/th08_mokou_boss.mp3",
	"enemy_whitelist": ENEMIES, "available_plants": PLANTS,
	"conveyor_plants": ["plasma_shooter", "plasma_shooter", "amber_shooter", "phoenix_tree", "shadow_pea", "snow_pea", "snow_pea", "frost_boomerang", "pressure_bamboo", "starfruit", "mirror_reed", "healing_gourd", "pumice_wall", "umbrella_leaf", "cherry_bomb", "jalapeno", "ice_shroom"],
	"unlock_plant": "", "start_sun": 0, "time_scale": 0.68, "sky_sun_range": Vector2(999, 999),
	"events": [
		{"time":5.0,"kind":"moon_rabbit","row":2}, {"time":11.0,"kind":"kedama","row":4},
		{"time":17.0,"kind":"conehead","row":0}, {"time":23.0,"kind":"newspaper","row":5},
		{"time":29.0,"kind":"flag","wave":true}, {"time":35.0,"kind":"moon_rabbit_guard","row":1},
		{"time":42.0,"kind":"screen_door","row":3}, {"time":49.0,"kind":"pole_vault","row":2},
		{"time":56.0,"kind":"flag","wave":true}, {"time":63.0,"kind":"buckethead","row":5},
		{"time":70.0,"kind":"moon_rabbit","row":0}, {"time":77.0,"kind":"football","row":4},
		{"time":84.0,"kind":"flag","wave":true}, {"time":91.0,"kind":"moon_rabbit_guard","row":2},
		{"time":98.0,"kind":"kedama","row":1}, {"time":105.0,"kind":"screen_door","row":3},
		{"time":112.0,"kind":"flag","wave":true}, {"time":119.0,"kind":"moon_rabbit_guard","row":5},
		{"time":126.0,"kind":"dark_football","row":0}, {"time":133.0,"kind":"football","row":4},
		{"time":140.0,"kind":"flag","wave":true}, {"time":155.0,"kind":"mokou_boss","row":2,"wave":true},
	],
}
