extends RefCounted

# TH08 Stage 4B, IDs 078–100. Former midboss spells join the single finale.
# Last Word «Blazing Star» belongs to spell practice, not the Stage 4B route.
const ROUTES := {
	"easy": [
		["th08-078", "魔符「银河」", "marisa_milky_way", "stars"],
		["th08-082", "魔符「星尘幻想」", "marisa_stardust", "orbit"],
		["th08-086", "恋符「非定向激光」", "marisa_non_directional", "laser"],
		["th08-090", "恋符「极限火花」", "marisa_master_spark", "spark"],
		["th08-094", "光符「地球光」", "marisa_earthlight", "light"],
	],
	"normal": [
		["th08-079", "魔符「银河」", "marisa_milky_way", "stars"],
		["th08-083", "魔符「星尘幻想」", "marisa_stardust", "orbit"],
		["th08-087", "恋符「非定向激光」", "marisa_non_directional", "laser"],
		["th08-091", "恋符「极限火花」", "marisa_master_spark", "spark"],
		["th08-095", "光符「地球光」", "marisa_earthlight", "light"],
		["th08-098", "魔炮「究极火花」", "marisa_final_spark", "final", {"last_spell": true, "duration": 12.0}],
	],
	"hard": [
		["th08-080", "魔空「小行星带」", "marisa_asteroid", "stars"],
		["th08-084", "黑魔「黑洞边缘」", "marisa_event_horizon", "orbit"],
		["th08-088", "恋风「星光台风」", "marisa_typhoon", "laser"],
		["th08-092", "恋心「二重火花」", "marisa_double_spark", "spark"],
		["th08-096", "光击「射月」", "marisa_shoot_moon", "light"],
		["th08-099", "魔炮「究极火花」", "marisa_final_spark", "final", {"last_spell": true, "duration": 14.0}],
	],
	"lunatic": [
		["th08-081", "魔空「小行星带」", "marisa_asteroid", "stars"],
		["th08-085", "黑魔「黑洞边缘」", "marisa_event_horizon", "orbit"],
		["th08-089", "恋风「星光台风」", "marisa_typhoon", "laser"],
		["th08-093", "恋心「二重火花」", "marisa_double_spark", "spark"],
		["th08-097", "光击「射月」", "marisa_shoot_moon", "light"],
		["th08-100", "魔炮「超究极火花」", "marisa_final_master", "final", {"last_spell": true, "duration": 16.0}],
	],
}

static func cards(level: Dictionary) -> Array:
	return ROUTES.get(String(level.get("touhou_difficulty", "easy")), ROUTES.easy).duplicate(true)
