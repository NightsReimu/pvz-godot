extends RefCounted

const Native = preload("res://scripts/data/zombie_defs.gd")

# Reviewed equipment slots: hands already carrying a pole, weapon, ladder, paper,
# umbrella or shield cannot carry another door. Native helmets cannot stack.
const HEAD_BASES := [
	"flag", "pole_vault", "farmer", "spear", "kungfu", "newspaper", "screen_door",
	"dancing", "backup_dancer", "ninja", "basketball", "nezha", "nether",
	"snorkel", "balloon_zombie", "digger_zombie", "pogo_zombie", "jack_in_the_box_zombie",
	"squash_zombie", "barrel_screen_zombie", "wolf_knight_zombie", "dolphin_rider",
	"ladder_zombie", "imp", "qinghua", "shouyue", "hive_zombie", "janitor_zombie",
	"enderman_zombie", "ski_zombie", "flywheel_zombie", "wither_zombie", "wizard_zombie",
	"medic_zombie", "shieldbearer_zombie", "saboteur_zombie", "rift_zombie", "bomber_zombie",
	"umbrella_zombie", "shania_zombie", "shade_zombie", "camel_zombie",
	"cinder_runner", "kiln_mason", "ash_bell", "sulfur_carrier", "vent_tunneler",
	"ancient_mage", "ancient_strategist", "star_fairy", "kedama",
]
const HELMET_BASES := [
	"ninja", "pole_vault", "dancing", "backup_dancer", "pogo_zombie", "ski_zombie",
	"spear", "kungfu", "wolf_knight_zombie", "saboteur_zombie",
]
const DOOR_BASES := [
	"conehead", "buckethead", "football", "dark_football", "flag", "ninja",
	"backup_dancer", "dancing", "nether", "wither_zombie", "medic_zombie",
	"saboteur_zombie", "rift_zombie", "shade_zombie", "shania_zombie",
	"enderman_zombie", "cinder_runner",
]
const HEADS := {
	"cone": {"name":"路障", "health":170.0, "metal":false, "wave":6, "reward":5},
	"bucket": {"name":"铁桶", "health":900.0, "metal":true, "wave":9, "reward":12},
	"football": {"name":"橄榄球头盔", "health":1261.0, "metal":true, "wave":12, "reward":16},
	"dark_football": {"name":"暗黑头盔", "health":2682.0, "metal":true, "wave":16, "reward":24},
	# A brick cannot be pulled off by a magnet; the samurai helmet is metal.
	"brick": {"name":"砖块", "health":1400.0, "metal":false, "wave":13, "reward":14},
	"kabuto": {"name":"武士盔", "health":1050.0, "metal":true, "wave":15, "reward":15},
}
# Helmets any bare-headed zombie can wear (native helmets cannot stack).
const WORN_HEADS := ["cone", "bucket", "brick", "kabuto"]
static var RECIPES: Dictionary = _recipes()

static func _recipes() -> Dictionary:
	var result := {}
	for base in HEAD_BASES:
		# Native helmet + added door below supplies these canonical combinations.
		if base == "screen_door": continue
		for head in WORN_HEADS:
			_add(result, String(base), String(head), false)
	for base in HELMET_BASES:
		for head in ["football", "dark_football"]:
			_add(result, String(base), String(head), false)
	for base in DOOR_BASES:
		_add(result, String(base), "", true)
		if base in HEAD_BASES:
			for head in WORN_HEADS:
				_add(result, String(base), String(head), true)
		if base in HELMET_BASES:
			for head in ["football", "dark_football"]:
				_add(result, String(base), String(head), true)
	return result

static func _add(result: Dictionary, base: String, head: String, door: bool) -> void:
	var id := (head + "_" if head != "" else "") + base + ("_door" if door else "")
	if door and base in ["conehead", "buckethead", "football", "dark_football"]:
		id = {"conehead":"cone", "buckethead":"bucket", "football":"football", "dark_football":"dark_football"}[base] + "_screen_door"
	var wave := int(HEADS[head].wave) if head != "" else 10
	if door: wave = maxi(wave, 14 if head != "" or base in ["buckethead", "football", "dark_football"] else 10)
	if base == "dark_football": wave = maxi(wave, 18)
	result[id] = {"base":base, "head":head, "door":door, "wave":wave}

static func with_fusions(native_defs: Dictionary) -> Dictionary:
	var result := native_defs.duplicate(true)
	for id in RECIPES:
		var recipe: Dictionary = RECIPES[id]
		var data: Dictionary = native_defs[recipe.base].duplicate(true)
		var head: String = recipe.head
		var base_name: String = data.name
		data["name"] = (String(HEADS[head].name) if head != "" else "") + ("铁门" if recipe.door else "") + base_name
		if id in ["cone_screen_door", "bucket_screen_door", "football_screen_door", "dark_football_screen_door"]:
			data.name = {"cone_screen_door":"路障铁门僵尸", "bucket_screen_door":"铁桶铁门僵尸", "football_screen_door":"橄榄球铁门僵尸", "dark_football_screen_door":"暗黑橄榄球铁门僵尸"}[id]
		data["fusion_base"] = recipe.base
		data["non_mainline_special"] = true
		data["headgear_health"] = float(HEADS[head].health) if head != "" else 0.0
		data["handheld_health"] = 1100.0 if recipe.door else 0.0
		data["reward"] += (int(HEADS[head].reward) if head != "" else 0) + (18 if recipe.door else 0)
		var lines: Array = Array(data.get("almanac", [])).duplicate()
		lines.append("融合原型：%s，保留原有行动与技能。" % base_name)
		if head != "" or recipe.base in ["conehead", "buckethead", "football", "dark_football"]:
			lines.append("橙金色为头戴护具；喷雾、回旋镖和穿透攻击仍需先击破它。")
		if recipe.door or float(data.get("shield_health", 0.0)) > 0.0 and String(data.get("armor_kind", "")) == "handheld":
			lines.append("蓝色为手持护具；阻挡正面普通攻击，喷雾、穿透攻击与背后攻击可绕过。")
		data["almanac"] = lines
		result[id] = data
	return result

static func base_kind(kind: String) -> String:
	return String(RECIPES[kind].base) if RECIPES.has(kind) else kind

static func variants_for(base: String, wave: int) -> Array:
	var result: Array = []
	for id in RECIPES:
		if String(RECIPES[id].base) == base and int(RECIPES[id].wave) <= wave:
			result.append(id)
	return result
