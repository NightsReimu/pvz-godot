extends RefCounted
class_name ZombieRuntime

# Zombie behaviour logic extracted from scripts/game.gd.
# This module owns pure logic only — it never calls draw_* (those stay in the
# game node's _draw). Like PlantRuntime, it takes the owning Control and reads /
# writes its fields directly.
#
# First increment: zombie-kind classification + spawn-row / spawn-x selection.
# _update_zombies and the boss skill/phase cluster remain in game.gd for now.

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
