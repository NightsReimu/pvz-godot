extends RefCounted
# Lawn zombies endure and bite closer to the original game. With hybrids, ultimates
# and energy beans a plain zombie needed four times as long to finish a plant, so
# defences rarely broke. Bosses keep their own tuning.
const HEALTH := 1.25
const ATTACK := 1.8
const SPEED := 1.08

# From the second world on, part of each wave arrives already wearing fused gear.
# Index: world number. Gate is the strongest recipe wave allowed, chance per spawn.
const CAMPAIGN_FUSION_GATE := {2: 6, 3: 9, 4: 12, 5: 14, 6: 16, 7: 18, 8: 18}
const CAMPAIGN_FUSION_CHANCE := {2: 0.10, 3: 0.14, 4: 0.18, 5: 0.20, 6: 0.22, 7: 0.25, 8: 0.25}
const HARD_FUSION_BONUS := 0.08


static func apply(defs: Dictionary) -> Dictionary:
	for kind in defs:
		var data: Dictionary = defs[kind]
		# Bosses and hand-specified units (the 2100-durability samurai) keep their numbers.
		if bool(data.get("boss", false)) or bool(data.get("balance_fixed", false)):
			continue
		data["health"] = float(data.get("health", 0.0)) * HEALTH
		if data.has("attack_dps"):
			data["attack_dps"] = float(data.attack_dps) * ATTACK
		if data.has("speed"):
			data["speed"] = float(data.speed) * SPEED
	return defs


static func world_of(level: Dictionary) -> int:
	var id := String(level.get("id", ""))
	var dash := id.find("-")
	if dash <= 0 or not id.substr(0, dash).is_valid_int():
		return 0
	return int(id.substr(0, dash))


static func campaign_fusion(level: Dictionary) -> Dictionary:
	if bool(level.get("custom_level", false)) or level.has("minigame") or String(level.get("mode", "")) in ["bowling", "whack", "vasebreaker", "endless"]:
		return {}
	var world := world_of(level)
	if not CAMPAIGN_FUSION_GATE.has(world):
		return {}
	var chance: float = float(CAMPAIGN_FUSION_CHANCE[world]) + (HARD_FUSION_BONUS if bool(level.get("hard_mode", false)) else 0.0)
	return {"gate": int(CAMPAIGN_FUSION_GATE[world]), "chance": chance}
