extends RefCounted

# TH08 Stage 5 spell-practice IDs 101–119. Normal+ adds the Last Spell.
# The four canonical families remain ordered; original TD phases are separate.
const ROUTES := {
	"easy": [
		["th08-101", "波符「赤眼催眠」", "reisen_mind_shaker", "eye"],
		["th08-105", "狂符「幻视调律」", "reisen_visionary_tuning", "shot"],
		["th08-109", "懒符「生神停止」", "reisen_idling_wave", "phase"],
		["th08-113", "散符「真实之月」", "reisen_invisible_moon", "special"],
	],
	"normal": [
		["th08-102", "波符「赤眼催眠」", "reisen_mind_shaker", "eye"],
		["th08-106", "狂符「幻视调律」", "reisen_visionary_tuning", "shot"],
		["th08-110", "懒符「生神停止」", "reisen_idling_wave", "phase"],
		["th08-114", "散符「真实之月」", "reisen_invisible_moon", "special"],
		["th08-117", "月眼「月兔远隔催眠术」", "reisen_tele_mesmerism", "final", {"last_spell": true, "duration": 10.0}],
	],
	"hard": [
		["th08-103", "幻波「赤眼催眠」", "reisen_mind_blowing", "eye"],
		["th08-107", "狂视「狂视调律」", "reisen_illusion_seeker", "shot"],
		["th08-111", "懒惰「生神停止」", "reisen_mind_stopper", "phase"],
		["th08-115", "散符「真实之月」", "reisen_invisible_moon", "special"],
		["th08-118", "月眼「月兔远隔催眠术」", "reisen_tele_mesmerism", "final", {"last_spell": true, "duration": 12.0}],
	],
	"lunatic": [
		["th08-104", "幻波「赤眼催眠」", "reisen_mind_blowing", "eye"],
		["th08-108", "狂视「狂视调律」", "reisen_illusion_seeker", "shot"],
		["th08-112", "懒惰「生神停止」", "reisen_mind_stopper", "phase"],
		["th08-116", "散符「真实之月」", "reisen_invisible_moon", "special"],
		["th08-119", "月眼「月兔远隔催眠术」", "reisen_tele_mesmerism", "final", {"last_spell": true, "duration": 14.0}],
	],
}

static func cards(level: Dictionary) -> Array:
	return ROUTES.get(String(level.get("touhou_difficulty", "easy")), ROUTES.easy).duplicate(true)
