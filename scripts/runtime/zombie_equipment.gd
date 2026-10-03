extends RefCounted

const Native = preload("res://scripts/data/zombie_defs.gd")
const Fusion = preload("res://scripts/data/fusion_zombie_defs.gd")
const Palette = preload("res://scripts/ui/game_theme.gd")

const HANDHELD := ["newspaper", "screen_door", "basketball", "barrel_screen_zombie", "ladder_zombie", "qinghua", "janitor_zombie", "shieldbearer_zombie", "umbrella_zombie", "moon_rabbit_guard", "basalt_guard"]
const NATIVE_METAL := ["buckethead", "football", "dark_football", "lifebuoy_bucket", "screen_door", "basketball", "barrel_screen_zombie", "ladder_zombie", "qinghua", "janitor_zombie", "shieldbearer_zombie"]

static func native_slot(kind: String) -> String:
	if kind in HANDHELD: return "handheld"
	return String(Native.ZOMBIES.get(kind, {}).get("armor_kind", "headgear"))

static func apply_recipe(zombie: Dictionary, id: String) -> void:
	var recipe: Dictionary = Fusion.RECIPES[id]
	zombie["fusion_kind"] = id
	zombie["headgear_kind"] = recipe.head
	zombie["handheld_kind"] = "screen_door" if recipe.door else ""
	zombie["headgear_health"] = float(Fusion.HEADS[recipe.head].health) if recipe.head != "" else 0.0
	zombie["max_headgear_health"] = zombie.headgear_health
	zombie["handheld_health"] = 1100.0 if recipe.door else 0.0
	zombie["max_handheld_health"] = zombie.handheld_health

# Outer hand shields before headgear. Native equipment keeps its existing field
# so newspapers, basketball regrowth, ladders and other behaviors keep working.
static func layers(zombie: Dictionary) -> Array:
	var result: Array = []
	if float(zombie.get("handheld_health", 0.0)) > 0.0:
		result.append({"field":"handheld_health", "max_field":"max_handheld_health", "slot":"handheld"})
	var slot := native_slot(String(zombie.kind))
	if slot == "handheld" and float(zombie.get("shield_health", 0.0)) > 0.0:
		result.append({"field":"shield_health", "max_field":"max_shield_health", "slot":slot})
	if float(zombie.get("headgear_health", 0.0)) > 0.0:
		result.append({"field":"headgear_health", "max_field":"max_headgear_health", "slot":"headgear"})
	if slot != "handheld" and float(zombie.get("shield_health", 0.0)) > 0.0:
		result.append({"field":"shield_health", "max_field":"max_shield_health", "slot":slot})
	return result

static func handheld_bypassed(zombie: Dictionary, pierce: bool, from_x: float) -> bool:
	if pierce: return true
	if not is_finite(from_x): return false
	return from_x < float(zombie.x) if bool(zombie.get("hypnotized", false)) else from_x > float(zombie.x)

static func total_health(zombie: Dictionary) -> float:
	return float(zombie.get("health", 0.0)) + float(zombie.get("shield_health", 0.0)) + float(zombie.get("headgear_health", 0.0)) + float(zombie.get("handheld_health", 0.0))

static func bar_color(slot: String) -> Color:
	return Palette.HEADGEAR_AMBER if slot == "headgear" else Palette.SHIELD_BLUE

static func metal_field(zombie: Dictionary) -> String:
	if float(zombie.get("handheld_health", 0.0)) > 0.0: return "handheld_health"
	var kind := String(zombie.kind)
	if kind in NATIVE_METAL and native_slot(kind) == "handheld" and float(zombie.get("shield_health", 0.0)) > 0.0: return "shield_health"
	var head := String(zombie.get("headgear_kind", ""))
	if head != "" and bool(Fusion.HEADS[head].metal) and float(zombie.get("headgear_health", 0.0)) > 0.0: return "headgear_health"
	if kind in NATIVE_METAL and float(zombie.get("shield_health", 0.0)) > 0.0: return "shield_health"
	return ""

static func catalogue_kind(zombie: Dictionary) -> String:
	return String(zombie.get("fusion_kind", zombie.kind))
