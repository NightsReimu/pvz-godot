extends RefCounted

# Easy/EX are compatibility baselines. Extra+ is an original challenge mode.
const PROFILES := {
	"easy": {"name": "Easy", "rank": 0, "health": 1.45, "damage": 1.0, "density": 0.9, "speed": 0.96, "cadence": 1.08, "phases": 0, "waves": 0, "select": false, "color": "8ece9a"},
	"normal": {"name": "Normal", "rank": 1, "health": 1.8, "damage": 1.12, "density": 1.05, "speed": 1.02, "cadence": 0.99, "phases": 1, "waves": 2, "select": false, "color": "72c6e5"},
	"hard": {"name": "Hard", "rank": 2, "health": 2.25, "damage": 1.28, "density": 1.2, "speed": 1.09, "cadence": 0.89, "phases": 2, "waves": 4, "select": false, "color": "e9c46a"},
	"lunatic": {"name": "Lunatic", "rank": 3, "health": 2.8, "damage": 1.46, "density": 1.38, "speed": 1.17, "cadence": 0.8, "phases": 3, "waves": 6, "select": true, "color": "ee809a"},
	"extra": {"name": "EX", "rank": 0, "health": 1.45, "damage": 1.0, "density": 0.96, "speed": 1.0, "cadence": 1.0, "phases": 0, "waves": 0, "select": false, "color": "e9c46a"},
	"extra_plus": {"name": "EX+", "rank": 3, "health": 2.5, "damage": 1.4, "density": 1.33, "speed": 1.15, "cadence": 0.8, "phases": 2, "waves": 6, "select": true, "color": "ee809a"},
}

# Theme, collision family, animation pose. Extra moves are explicitly original.
const EXTENSIONS := {
	"eirin_boss": ["月都医术", "medicine", "special"],
	"reisen_boss": ["狂气月廊", "lunar", "eye"],
	"marisa_boss": ["星光魔法", "stars", "stars"],
	"reimu_boss": ["博丽符阵", "ofuda", "seal"],
	"rumia_boss": ["夜幕追击", "dark", "bird"],
	"daiyousei_boss": ["妖精环流", "fairy", "ring"],
	"cirno_boss": ["冰棱封锁", "ice", "icicle"],
	"meiling_boss": ["虹彩回旋", "rainbow", "rainbow"],
	"koakuma_boss": ["禁书巡游", "books", "books"],
	"patchouli_boss": ["七曜交织", "elements", "metal"],
	"sakuya_boss": ["刻针追猎", "knives", "knives"],
	"remilia_boss": ["猩红枪阵", "scarlet", "scarlet"],
	"flandre_boss": ["破坏棱镜", "crystal", "crystal"],
	"letty_boss": ["寒潮封路", "snow", "lingering"],
	"chen_boss": ["式神穿阵", "shikigami", "shikigami"],
	"alice_boss": ["人偶织网", "dolls", "marionette"],
	"lily_white_boss": ["春风散华", "spring", "spring_herald"],
	"prismriver_boss": ["三重奏追击", "music", "concerto"],
	"youmu_boss": ["半灵连斩", "sword", "slash"],
	"yuyuko_boss": ["幽蝶返照", "butterfly", "butterfly"],
	"ran_boss": ["式神封阵", "fox", "senko"],
	"yukari_boss": ["隙间封锁", "boundary", "boundary"],
	"wriggle_boss": ["萤群夜袭", "insects", "swarm"],
	"mystia_boss": ["夜雀轮唱", "song", "song"],
	"keine_boss": ["史书回廊", "history", "history"],
}

# Each column is a different move, retained by all subsequent difficulty tiers.
# The first uses the character's pursuit pattern, then crossfire, then a domain.
const MOVE_NAMES := {
	"medicine": ["药符「朱月狂剂」", "禁疗「月都处方」", "虚月「万象临床」"],
	"lunar": ["月门「地月增援航路」", "蚀符「无光的月面温室」", "狂廊「无限折返之瞳」"],
	"stars": ["星符「棱镜播种」", "恋光「交差彗星」", "魔庭「恒星炉心」"],
	"ofuda": ["封符「轮转封田」", "阴阳「两仪夹阵」", "博丽「封魔棋盘」"],
	"dark": ["夜幕追击", "逆光暗弧", "无月回廊"],
	"fairy": ["妖精环流", "双翼返花", "翡翠花庭"],
	"ice": ["冰棱封锁", "迟冻交叉", "九瓣冰牢"],
	"rainbow": ["虹彩回旋", "镜虹对流", "六色盘龙"],
	"books": ["禁书巡游", "双页折返", "禁书索引"],
	"elements": ["七曜交织", "水火夹击", "五行轮转"],
	"knives": ["刻针追猎", "停刻剪刀", "银针钟盘"],
	"scarlet": ["猩红枪阵", "血翼交枪", "红月牢笼"],
	"crystal": ["破坏棱镜", "折光双棱", "碎星领域"],
	"snow": ["寒潮封路", "逆风回雪", "白夜霜环"],
	"shikigami": ["式神穿阵", "猫步折返", "回旋式网"],
	"dolls": ["人偶织网", "双列牵丝", "人偶光栅"],
	"spring": ["春风散华", "迎春双燕", "花开四时"],
	"music": ["三重奏追击", "错拍回声", "终夜轮唱"],
	"sword": ["半灵连斩", "双刃错位", "六道剑围"],
	"butterfly": ["幽蝶返照", "冥蝶双回", "幽庭花葬"],
	"fox": ["式神封阵", "九尾对冲", "狐火星罗"],
	"boundary": ["隙间封锁", "里外折返", "四隅境界"],
	"insects": ["萤群夜袭", "交错萤航", "夜空灯阵"],
	"song": ["夜雀轮唱", "反拍鸟鸣", "笼中回响"],
	"history": ["史书回廊", "今昔交错", "编年重围"],
}

# TH08 4A/B authored low fixed damage per projectile, so late phases previously
# fell behind other bosses. Keep character tuning separate from difficulty.
const ATTACK_TUNING := {
	"eirin_boss": {"damage": 1.35, "beam_damage": 1.35, "phase_damage": 0.10, "speed": 1.02, "density": 1.08, "cadence": 0.94},
	"reisen_boss": {"damage": 1.35, "beam_damage": 1.18, "phase_damage": 0.12, "speed": 1.08, "density": 1.16, "cadence": 0.86},
	"reimu_boss": {"damage": 1.45, "beam_damage": 1.35, "phase_damage": 0.12, "speed": 1.12, "density": 1.16, "cadence": 0.9},
	"marisa_boss": {"damage": 1.35, "beam_damage": 1.22, "phase_damage": 0.12, "speed": 1.10, "density": 1.15, "cadence": 0.9},
}


static func attack_density(kind: String, level: Dictionary) -> float:
	return float(profile(level).density) * float(ATTACK_TUNING.get(kind, {}).get("density", 1.0))


static func attack_speed(kind: String, level: Dictionary) -> float:
	return float(profile(level).speed) * float(ATTACK_TUNING.get(kind, {}).get("speed", 1.0))


static func attack_cadence(kind: String, level: Dictionary) -> float:
	return float(profile(level).cadence) * float(ATTACK_TUNING.get(kind, {}).get("cadence", 1.0))


static func attack_damage(kind: String, level: Dictionary, phase: int, beam: bool = false) -> float:
	var tuning: Dictionary = ATTACK_TUNING.get(kind, {})
	var growth := 1.0 + clampi(phase, 0, 3) * float(tuning.get("phase_damage", 0.0))
	return boss_damage_multiplier(level) * float(tuning.get("beam_damage" if beam else "damage", 1.0)) * growth


static func is_touhou(level: Dictionary) -> bool:
	for event in level.get("events", []):
		if EXTENSIONS.has(String(event.get("kind", ""))):
			return true
	return EXTENSIONS.has(String(level.get("mid_boss_kind", "")))


static func is_extra(level: Dictionary) -> bool:
	return String(level.get("id", "")) in ["1-23", "2-31"] or bool(level.get("touhou_extra", false))


static func options(level: Dictionary) -> Array:
	if not is_touhou(level):
		return []
	return ["extra", "extra_plus"] if is_extra(level) else ["easy", "normal", "hard", "lunatic"]


static func profile(level: Dictionary) -> Dictionary:
	return PROFILES.get(String(level.get("touhou_difficulty", "easy")), PROFILES.easy)


static func boss_damage_multiplier(level: Dictionary) -> float:
	if not level.has("touhou_difficulty") and not is_touhou(level):
		return 1.0
	return {"easy": 0.50, "normal": 0.60, "hard": 0.72, "lunatic": 0.86, "extra": 0.50, "extra_plus": 0.82}.get(String(level.get("touhou_difficulty", "easy")), 0.50)


static func build_level(base: Dictionary, choice: String) -> Dictionary:
	var level := base.duplicate(true)
	if not options(base).has(choice):
		return level
	var settings: Dictionary = PROFILES[choice]
	level["touhou_difficulty"] = choice
	level["title"] = "%s · %s" % [String(base.title), settings.name]
	if bool(settings.select):
		level["mode"] = "normal"
		level["start_sun"] = 350
		level["sky_sun_range"] = Vector2(7.0, 10.0)
		level.erase("conveyor_plants")
		level.erase("conveyor_plants_after_freeze")
		level["touhou_seed_selection"] = true
	var extra_waves := int(settings.waves)
	if extra_waves > 0:
		var events: Array = level.events
		var final_time := 0.0
		for event in events:
			final_time = maxf(final_time, float(event.time))
		for index in range(extra_waves):
			# Keep finale last and use the existing terrain-aware wave generator.
			var time := lerpf(18.0, maxf(20.0, final_time - 8.0), float(index + 1) / (extra_waves + 1))
			events.append({"time": time, "kind": "flag", "wave": true, "touhou_extra_wave": true})
		events.sort_custom(func(a, b): return float(a.time) < float(b.time))
	return level


static func extend_phases(kind: String, level: Dictionary, phases: Array) -> Array:
	var count := int(profile(level).phases)
	if count == 0 or phases.is_empty() or not EXTENSIONS.has(kind):
		return phases
	var theme: Array = EXTENSIONS[kind]
	for index in range(count):
		var suffix: String = ["", "_crossfire", "_domain"][index]
		var pose: String = theme[2]
		if kind == "reimu_boss":
			pose = ["seal", "dream", "barrier"][index]
		elif kind == "marisa_boss":
			pose = ["stars", "laser", "orbit"][index]
		var card := ["original-difficulty-%s-%d" % [kind, index + 1], "原创 · " + MOVE_NAMES[theme[1]][index], "pressure_" + theme[1] + suffix, pose, {"pressure_tier": index + 1, "pressure_family": theme[1]}]
		phases.insert(phases.size() - 1, [card])
	return phases


static func spell_variant(kind: String, level: Dictionary, entry: Array) -> Array:
	var rank := int(profile(level).rank)
	if rank < 2 or is_extra(level):
		return entry
	var result := entry.duplicate(true)
	var index := 1 if rank == 3 else 0
	var variants := {}
	if kind == "remilia_boss":
		variants = {
			"th06-42": ["th06-47", "神罚「年幼的恶魔领主」", "young_demon_lord"],
			"th06-43": ["th06-48", "狱符「千根针的针山」", "thousand_needles"],
			"th06-44": ["th06-49", "神术「吸血鬼幻想」", "vampire_illusion"],
			"th06-45": ["th06-50", "红符「Scarlet Meister」", "scarlet_meister"],
			"th06-46": ["th06-51", "「红色的幻想乡」", "scarlet_gensokyo"],
		}
	elif kind == "keine_boss":
		variants = {
			"th08-037": [["th08-038", "th08-039"][index], entry[1], entry[2]],
			"th08-041": [["th08-042", "th08-043"][index], ["野符「义满危机」", "野符「GHQ危机」"][index], "keine_crisis"],
			"th08-045": [["th08-046", "th08-047"][index], ["国符「三种神器·镜」", "国体「三种神器·乡」"][index], "keine_mirror"],
			"th08-049": [["th08-050", "th08-051"][index], "虚史「幻想乡传说」", "keine_legend"],
			"th08-052": [["th08-053", "th08-054"][index], entry[1], entry[2]],
		}
	elif kind == "yuyuko_boss":
		variants = {
			"th07-094": [["th07-095", "th07-096"][index], "亡乡「亡我乡 -%s-」" % ["无道之路", "自尽"][index], entry[2]],
			"th07-098": [["th07-099", "th07-100"][index], "亡舞「生者必灭之理 -%s-」" % ["毒蛾", "魔境"][index], entry[2]],
			"th07-102": [["th07-103", "th07-104"][index], ["华灵「Deep-Rooted Butterfly」", "华灵「Butterfly Delusion」"][index], entry[2]],
			"th07-106": [["th07-107", "th07-108"][index], "幽曲「埋骨于弘川 -%s-」" % ["幻灵", "神灵"][index], entry[2]],
			"th07-110": [["th07-111", "th07-112"][index], "樱符「完全墨染的樱花 -%s-」" % ["春眠", "开花"][index], entry[2]],
			"th07-114": [["th07-115", "th07-116"][index], "「反魂蝶 -%s-」" % ["五分咲", "八分咲"][index], entry[2]],
		}
	if variants.has(String(entry[0])):
		var replacement: Array = variants[String(entry[0])]
		for field in range(3):
			result[field] = replacement[field]
	return result
