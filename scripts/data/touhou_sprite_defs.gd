extends RefCounted

# One opaque idle silhouette calibration per character; never rescale each pose.
# Height excludes transparent canvas padding and faint spell glows.
const BODY_HEIGHT := 180.0
const IDLE_HEIGHTS := {
	"mokou_boss": 208.0,
	"hakutaku_boss": 238.0,
	"kaguya_boss": 208.0,
	"eirin_boss": 216.0,
	"tewi_boss": 222.0,
	"reisen_boss": 248.0,
	"alice_boss": 242.0,
	"chen_boss": 225.0,
	"cirno_boss": 199.0,
	"daiyousei_boss": 220.0,
	"flandre_boss": 224.0,
	"keine_boss": 249.0,
	"koakuma_boss": 202.0,
	"letty_boss": 181.0,
	"lily_white_boss": 210.0,
	"marisa_boss": 232.0,
	"meiling_boss": 234.0,
	"mystia_boss": 230.0,
	"patchouli_boss": 227.0,
	"prismriver_boss": 150.0,
	"ran_boss": 198.0,
	"reimu_boss": 227.0,
	"remilia_boss": 230.0,
	"rumia_boss": 198.0,
	"sakuya_boss": 242.0,
	"wriggle_boss": 248.0,
	"youmu_boss": 219.0,
	"yukari_boss": 210.0,
	"yuyuko_boss": 201.0,
}

const IDLE_BOTTOM := {
	"mokou_boss": 319.0,
	"hakutaku_boss": 254.0,
	"kaguya_boss": 236.0,
	"eirin_boss": 246.0,
	"tewi_boss": 246.0,
	"reisen_boss": 253.0,
	"alice_boss": 262.0,
	"chen_boss": 243.0,
	"cirno_boss": 319.0,
	"daiyousei_boss": 319.0,
	"flandre_boss": 320.0,
	"keine_boss": 320.0,
	"koakuma_boss": 320.0,
	"letty_boss": 213.0,
	"lily_white_boss": 240.0,
	"marisa_boss": 247.0,
	"meiling_boss": 319.0,
	"mystia_boss": 319.0,
	"patchouli_boss": 319.0,
	"prismriver_boss": 216.0,
	"ran_boss": 226.0,
	"reimu_boss": 249.0,
	"remilia_boss": 319.0,
	"rumia_boss": 319.0,
	"sakuya_boss": 319.0,
	"wriggle_boss": 320.0,
	"youmu_boss": 242.0,
	"yukari_boss": 241.0,
	"yuyuko_boss": 233.0,
}

# These supplied sheets contain different actions, rather than generated
# inbetweens of eight interchangeable poses. Keep reactions out of spell casts.
const SCARLET_ANIMATIONS := {
	"rumia_boss": {
		"hit": [12, 13, 14], "summon": [9, 10, 11, 10],
		"beam": [6, 7, 8, 7], "swallow": [6, 7, 8, 7],
		"bird": [15, 16, 17, 16], "dark": [18, 19, 20, 19],
		"night": [21, 22, 23, 22], "phase": [15, 16, 17, 20, 22],
	},
	"daiyousei_boss": {
		"hit": [12, 13, 14], "heal": [9, 10, 11, 10],
		"summon": [18, 19, 20, 23], "fairy": [18, 19, 20, 23],
		"ring": [15, 16, 17, 16], "lance": [6, 7, 8, 7],
		"phase": [15, 16, 17, 23],
	},
	"cirno_boss": {
		"hit": [12, 13, 14], "icicle": [6, 7, 8, 7], "ice": [6, 7, 8, 7],
		"freeze": [9, 10, 11, 10], "blizzard": [18, 19, 20, 23],
		"snow": [15, 16, 17, 16], "phase": [15, 16, 17, 23],
	},
	"meiling_boss": {
		"hit": [18, 19, 22], "kick": [6, 7, 8, 7], "punch": [6, 7, 8, 7],
		"rainbow": [8, 9, 10, 11], "dragon": [14, 15, 16, 20, 21],
		"dash": [3, 4, 5, 4], "guard": [12, 13, 14, 13],
		"phase": [14, 15, 16, 20, 21],
	},
	"koakuma_boss": {
		"hit": [12, 13, 14], "books": [6, 7, 8, 7],
		"familiar": [15, 16, 17, 16], "summon": [18, 19, 20, 23],
		"phase": [15, 16, 17, 23],
	},
	"patchouli_boss": {
		"hit": [12, 13, 14], "fire": [6, 7, 8, 7], "water": [9, 10, 11, 10],
		"wind": [15, 16, 17, 16], "metal": [18, 19, 20, 19],
		"flare": [18, 19, 20, 23], "phase": [15, 16, 17, 23],
	},
	"sakuya_boss": {
		"hit": [18, 19, 20], "knives": [6, 7, 8, 7], "rain": [9, 10, 11, 10],
		"doll": [12, 13, 14, 13], "time": [15, 16, 17, 16],
		"clock": [12, 13, 14, 23], "summon": [12, 13, 14, 13],
		"phase": [14, 15, 16, 23],
	},
	"remilia_boss": {
		"hit": [18, 19, 20], "scarlet": [12, 13, 14, 13],
		"magic": [12, 13, 14, 13], "heart": [15, 16, 17, 16],
		"gungnir": [6, 7, 8, 9, 10, 11], "cradle": [21, 22, 23, 22],
		"drain": [15, 16, 17, 16], "bats": [12, 13, 14, 13],
		"meister": [15, 17, 21, 23], "phase": [15, 16, 17, 23],
	},
	"flandre_boss": {
		"hit": [18, 19, 20], "laevatein": [6, 7, 8, 9, 10, 11],
		"clones": [15, 16, 17, 23], "kagome": [12, 13, 14, 13],
		"starbow": [12, 13, 14, 15, 16, 17], "dolls": [12, 13, 14, 13],
		"crystal": [12, 13, 14, 15, 16, 17], "break": [21, 22, 23, 22],
		"storm": [15, 16, 17, 16], "secret": [21, 22, 23, 22],
		"judgement": [21, 22, 23, 22], "cranberry": [12, 13, 14, 13],
		"phase": [21, 22, 23, 22],
	},
}

static func scarlet_frame_index(kind: String, zombie: Dictionary, time: float) -> int:
	var animations: Dictionary = SCARLET_ANIMATIONS.get(kind, {})
	var state := String(zombie.get("rumia_state", "idle"))
	if kind == "meiling_boss":
		state = String(zombie.get("boss_state", state))
	var frames: Array = animations.get(state, [0, 1, 2, 1])
	var speed := 6.0 if animations.has(state) else 3.0
	if state == "shift" or (state == "idle" and float(zombie.get("special_pause_timer", 0.0)) > 0.0):
		frames = [3, 4, 5, 4]
		speed = 5.0
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frames = animations.get("hit", [12, 13, 14])
		speed = 10.0
	var tick := maxi(0, int(floor(time * speed + float(zombie.get("anim_phase", 0.0)) * frames.size())))
	return int(frames[tick % frames.size()])

const IMPERISHABLE_ANIMATIONS := {
	"wriggle_boss": {
		"hit": [12, 13, 12], "firefly": [9, 10, 11, 10],
		"swarm": [15, 16, 17, 16], "storm": [6, 7, 20, 7],
		"final": [18, 19, 23, 19], "phase": [15, 16, 18, 19, 23],
	},
	"mystia_boss": {
		"hit": [20, 21, 20], "song": [12, 13, 14, 15],
		"wing": [6, 7, 8, 9, 10, 11], "crescendo": [15, 16, 17, 16],
		"cook": [12, 13, 14, 13], "final": [18, 19, 22, 19],
		"enraged": [16, 17, 18, 19], "phase": [16, 17, 18, 19, 22],
	},
	"keine_boss": {
		"hit": [12, 13, 14], "history": [6, 7, 8, 7],
		"edict": [6, 7, 8, 7], "whip": [6, 7, 18, 20],
		"treasures": [9, 10, 11, 10], "bamboo": [9, 10, 11, 10],
		"piano": [9, 11, 16, 17], "emperor": [18, 19, 20, 19],
		"final": [15, 16, 17, 23], "phase": [15, 16, 17, 23],
	},
}

static func imperishable_frame_index(kind: String, boss: Dictionary, time: float) -> int:
	var animations: Dictionary = IMPERISHABLE_ANIMATIONS.get(kind, {})
	var state := String(boss.get("rumia_state", "idle"))
	if kind == "mystia_boss":
		if state == "idle":
			state = String(boss.get("mystia_state", state))
		if float(boss.get("mystia_cooking_timer", 0.0)) > 0.0:
			state = "cook"
	var frames: Array = animations.get(state, [0, 1, 2, 1])
	var speed := 6.0 if animations.has(state) else 3.0
	if state == "shift" or (state == "idle" and float(boss.get("special_pause_timer", 0.0)) > 0.0):
		frames = [3, 4, 5, 4]
		speed = 5.0
	var elapsed := time
	if kind == "keine_boss" and state != "idle" and float(boss.get("touhou_cast_duration", 0.0)) > 0.0:
		elapsed = float(boss.touhou_cast_duration) - float(boss.get("touhou_cast_remaining", 0.0))
	if float(boss.get("impact_timer", 0.0)) > 0.0:
		frames = animations.hit
		speed = 10.0
		elapsed = time
	var tick := maxi(0, int(floor(elapsed * speed + float(boss.get("anim_phase", 0.0)) * frames.size())))
	return int(frames[tick % frames.size()])

static func draw_scale(kind: String) -> float:
	return BODY_HEIGHT / float(IDLE_HEIGHTS.get(kind, BODY_HEIGHT))

static func top_offset(kind: String) -> float:
	return 32.0 - float(IDLE_BOTTOM.get(kind, 256.0)) * draw_scale(kind)
