extends RefCounted
class_name ZombieRuntime

# Zombie behaviour logic extracted from scripts/game.gd.
# This module owns pure logic only — it never calls draw_* (those stay in the
# game node's _draw). Like PlantRuntime, it takes the owning Control and reads /
# writes its fields directly.
#
# Owns spawn selection and shared boss timing; individual spells remain in game.gd.

const BOSS_WINDUP := 0.85

var game: Control


func _init(game_owner: Control) -> void:
	game = game_owner


func is_water_zombie_kind(kind: String) -> bool:
	return kind == "ducky_tube" \
		or kind == "lifebuoy_normal" \
		or kind == "lifebuoy_cone" \
		or kind == "lifebuoy_bucket" \
		or kind == "snorkel" \
		or kind == "dolphin_rider" \
		or kind == "dragon_boat"


func is_dual_terrain_zombie_kind(kind: String) -> bool:
	return kind == "qinghua" or kind == "ice_block" or kind == "shouyue"


func is_mechanical_zombie_kind(kind: String) -> bool:
	return kind == "zomboni" \
		or kind == "bobsled_team" \
		or kind == "catapult_zombie" \
		or kind == "turret_zombie" \
		or kind == "programmer_zombie" \
		or kind == "subway_zombie" \
		or kind == "wenjie_zombie" \
		or kind == "router_zombie" \
		or kind == "mech_zombie" \
		or kind == "jack_in_the_box_zombie"


func is_row_valid_for_spawn_kind(kind: String, row: int) -> bool:
	if not game._is_row_active(row):
		return false
	if not game._is_pool_level():
		return true
	if kind == "bobsled_team":
		return true
	if is_dual_terrain_zombie_kind(kind):
		return true
	if is_water_zombie_kind(kind):
		return game._is_water_row(row)
	return not game._is_water_row(row)


func eligible_spawn_rows_for_kind(kind: String) -> Array:
	var rows: Array = []
	for row in game.active_rows:
		var row_i = int(row)
		if is_row_valid_for_spawn_kind(kind, row_i):
			rows.append(row_i)
	if rows.is_empty():
		for row in game.active_rows:
			rows.append(int(row))
	return rows


func choose_spawn_row_for_kind(kind: String) -> int:
	var candidates = eligible_spawn_rows_for_kind(kind)
	if candidates.is_empty():
		return -1
	var min_count := 999999
	var row_counts := {}
	for row in candidates:
		var amount := 0
		for zombie in game.zombies:
			if int(zombie["row"]) == int(row):
				amount += 1
		row_counts[int(row)] = amount
		min_count = min(min_count, amount)
	var filtered: Array = []
	for row in candidates:
		if int(row_counts[int(row)]) == min_count:
			filtered.append(int(row))
	return int(filtered[game.rng.randi_range(0, filtered.size() - 1)])


func choose_spawn_row() -> int:
	return choose_spawn_row_for_kind("normal")


func normal_zombie_spawn_x() -> float:
	return game.BOARD_ORIGIN.x + game.board_size.x + 92.0


func random_normal_zombie_spawn_x() -> float:
	return normal_zombie_spawn_x() + game.rng.randf_range(-12.0, 18.0)


func update_boss(zombie: Dictionary, delta: float) -> Dictionary:
	if float(zombie.get("health", 0.0)) <= 0.0:
		return zombie
	var kind := String(zombie["kind"])
	var phase: int = game._boss_phase_from_ratio(float(zombie["health"]) / maxf(float(zombie["max_health"]), 1.0))
	if phase > int(zombie.get("boss_phase", 0)):
		zombie["boss_phase"] = phase
		zombie["boss_cast_pending"] = false
		zombie = game._trigger_boss_phase_shift(zombie, phase)
		zombie["boss_skill_timer"] = 1.2
		zombie["boss_pause_timer"] = 1.5
		return zombie
	if game._is_hovering_boss_kind(kind):
		zombie = game._update_hovering_boss(zombie, delta)
	zombie = game._update_boss_reinforcements(zombie, delta)
	zombie["boss_skill_timer"] = maxf(0.0, float(zombie.get("boss_skill_timer", 0.0)) - delta)
	zombie["boss_pause_timer"] = maxf(0.0, float(zombie.get("boss_pause_timer", 0.0)) - delta)
	if float(zombie["boss_pause_timer"]) > 0.0 or float(zombie.get("rumia_state_timer", 0.0)) > 0.0 or float(zombie.get("rumia_move_timer", 0.0)) > 0.0:
		return zombie
	if not bool(zombie.get("boss_cast_pending", false)):
		if float(zombie["boss_skill_timer"]) <= BOSS_WINDUP:
			# Always show a full warning, even when a long frame crosses the cooldown.
			zombie["boss_cast_pending"] = true
			zombie["boss_skill_timer"] = BOSS_WINDUP
		return zombie
	if float(zombie["boss_skill_timer"]) <= 0.0:
		zombie["boss_cast_pending"] = false
		zombie["boss_last_skill_cycle"] = int(zombie.get("boss_skill_cycle", 0))
		zombie = game._trigger_boss_skill(zombie)
		zombie["boss_skill_cycle"] = (int(zombie["boss_skill_cycle"]) + 1) % game._boss_skill_cycle_length(kind)
		zombie["boss_skill_timer"] = game._boss_skill_interval(kind, int(zombie["boss_phase"]))
		zombie["boss_pause_timer"] = 1.3
	return zombie


static func tick_hover_pose(zombie: Dictionary, delta: float) -> Dictionary:
	zombie["rumia_state_timer"] = maxf(0.0, float(zombie.get("rumia_state_timer", 0.0)) - delta)
	zombie["rumia_move_timer"] = maxf(0.0, float(zombie.get("rumia_move_timer", 0.0)) - delta)
	if float(zombie["rumia_state_timer"]) <= 0.0 and float(zombie["rumia_move_timer"]) <= 0.0:
		zombie["rumia_state"] = "idle"
	return zombie


static func hover_action_locked(zombie: Dictionary) -> bool:
	return bool(zombie.get("boss_cast_pending", false)) \
		or float(zombie.get("rumia_state_timer", 0.0)) > 0.0 \
		or float(zombie.get("rumia_move_timer", 0.0)) > 0.0 \
		or float(zombie.get("boss_pause_timer", 0.0)) > 0.0


static func update_boss_health_display(zombie: Dictionary, delta: float) -> Dictionary:
	var ratio := clampf(float(zombie.get("health", 0.0)) / maxf(1.0, float(zombie.get("max_health", 1.0))), 0.0, 1.0)
	var previous := float(zombie.get("boss_hud_health", ratio))
	var trail := float(zombie.get("boss_hud_trail", previous))
	var hold := maxf(0.0, float(zombie.get("boss_hud_hold", 0.0)) - delta)
	if ratio < previous and trail <= previous + 0.001:
		hold = 0.18
	if ratio > previous:
		trail = maxf(trail, ratio)
	elif hold <= 0.0:
		trail = move_toward(trail, ratio, delta * 0.65)
	zombie["boss_hud_health"] = ratio
	zombie["boss_hud_trail"] = clampf(trail, ratio, 1.0)
	zombie["boss_hud_hold"] = hold
	return zombie
