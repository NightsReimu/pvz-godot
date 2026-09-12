extends RefCounted

# TH08 Stage 4A, spell IDs 055–077. Both midboss cards are folded into the
# single finale at the user's request; no separate midboss is spawned.
# Names and original spell comments: docs/touhou-spells.md.
const ROUTES := {
	"easy": [
		["th08-055", "梦符「二重结界」", "reimu_duplex", "barrier"],
		["th08-059", "灵符「梦想封印 散」", "reimu_spread", "dream"],
		["th08-063", "梦符「封魔阵」", "reimu_sealing_circle", "seal"],
		["th08-067", "灵符「梦想封印 集」", "reimu_concentrate", "dream"],
		["th08-071", "界线「二重弹幕结界」", "reimu_danmaku_barrier", "barrier"],
	],
	"normal": [
		["th08-056", "梦符「二重结界」", "reimu_duplex", "barrier"],
		["th08-060", "灵符「梦想封印 散」", "reimu_spread", "dream"],
		["th08-064", "梦符「封魔阵」", "reimu_sealing_circle", "seal"],
		["th08-068", "灵符「梦想封印 集」", "reimu_concentrate", "dream"],
		["th08-072", "界线「二重弹幕结界」", "reimu_danmaku_barrier", "barrier"],
		["th08-075", "神灵「梦想封印 瞬」", "reimu_blink", "final", {"last_spell": true, "duration": 12.0}],
	],
	"hard": [
		["th08-057", "梦境「二重大结界」", "reimu_great_duplex", "barrier"],
		["th08-061", "散灵「梦想封印 寂」", "reimu_worn", "dream"],
		["th08-065", "神技「八方鬼缚阵」", "reimu_binding_circle", "seal"],
		["th08-069", "回灵「梦想封印 侘」", "reimu_returning", "dream"],
		["th08-073", "大结界「博丽弹幕结界」", "reimu_hakurei_barrier", "barrier"],
		["th08-076", "神灵「梦想封印 瞬」", "reimu_blink", "final", {"last_spell": true, "duration": 14.0}],
	],
	"lunatic": [
		["th08-058", "梦境「二重大结界」", "reimu_great_duplex", "barrier"],
		["th08-062", "散灵「梦想封印 寂」", "reimu_worn", "dream"],
		["th08-066", "神技「八方龙杀阵」", "reimu_dragon_circle", "seal"],
		["th08-070", "回灵「梦想封印 侘」", "reimu_returning", "dream"],
		["th08-074", "大结界「博丽弹幕结界」", "reimu_hakurei_barrier", "barrier"],
		["th08-077", "神灵「梦想封印 瞬」", "reimu_blink", "final", {"last_spell": true, "duration": 16.0}],
	],
}

static func cards(level: Dictionary) -> Array:
	return ROUTES.get(String(level.get("touhou_difficulty", "easy")), ROUTES.easy).duplicate(true)
