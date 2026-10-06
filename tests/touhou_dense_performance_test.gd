extends SceneTree

const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/fixtures/touhou_damage_game.gd")
const Legacy = preload("res://tests/fixtures/touhou_dense_legacy.gd")
const OUTPUT := "res://output/touhou-next-balance/performance"
var failures := 0

class CountGame extends Fixture:
	var cell_checks := 0
	var mirror_component_checks := 0
	var zombie_checks := 0
	var hits: Array = []
	func _targetable_plant_at(row: int, col: int) -> Variant:
		cell_checks += 1
		return super._targetable_plant_at(row, col)
	func _plant_has_component(plant: Variant, component: String) -> bool:
		if component == "mirror_reed": mirror_component_checks += 1
		return super._plant_has_component(plant, component)
	func _is_enemy_zombie(zombie: Dictionary) -> bool:
		zombie_checks += 1
		return super._is_enemy_zombie(zombie)
	func _damage_plant_cell(row: int, col: int, damage: float, extra: float = 0.0, scaled: bool = false) -> bool:
		hits.append([row, col, damage])
		return super._damage_plant_cell(row, col, damage, extra, scaled)
	func counters() -> void:
		cell_checks = 0
		mirror_component_checks = 0
		zombie_checks = 0
		hits.clear()

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition: failures += 1; push_error(message)

func make_case(case: String, dimensions: Vector2) -> CountGame:
	var g := CountGame.new()
	g.configure("cirno_boss", "easy")
	g.CELL_SIZE = dimensions
	g.BOARD_ORIGIN = Vector2(37, 129)
	g.board_size = dimensions * Vector2(9, 6)
	var owner: Dictionary = g.add_boss("cirno_boss")
	owner.touhou_owner = 1
	owner.health = 100000000.0
	owner.max_health = owner.health
	if case != "empty":
		for row in range(6):
			for col in range(9):
				var p: Dictionary = g.add_plant(row, col, 0.0)
				p.health = 100000000.0
				p.max_health = p.health
	if case == "mirror":
		for row in range(6):
			g.grid[row][4] = g._create_plant("mirror_reed", row, 4)
			g.grid[row][4].health = 100000000.0
	if case == "reflected":
		for i in range(64):
			g._spawn_zombie_at("normal", i % 6, g._cell_center(i % 6, (i / 6) % 9).x + float(i % 3) * 7.0, true)
			g.zombies.back().health = 100000000.0
			g.zombies.back().max_health = 100000000.0
	return g

func projectiles(g: CountGame, case: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(480):
		var row := i % 6
		var col := (i / 6) % 9
		var center: Vector2 = g._cell_center(row, col) + Vector2(0, -12)
		var start := center + Vector2(g.CELL_SIZE.x * 0.34, g.CELL_SIZE.y * 0.12)
		var velocity := Vector2(-g.CELL_SIZE.x * 1.25, 0.0)
		if case == "crossboard":
			start = g.BOARD_ORIGIN + Vector2(g.board_size.x + 15, -12 if i % 2 else g.board_size.y + 12)
			velocity = Vector2(-g.board_size.x - 30, g.board_size.y + 24 if i % 2 else -g.board_size.y - 24) * 60.0
		elif case == "mirror":
			start = g._cell_center(row, 4) + Vector2(g.CELL_SIZE.x * 0.3, -12)
		elif case == "reflected":
			start = g._cell_center(row, col) + Vector2(-g.CELL_SIZE.x * 0.22, -12)
			velocity = Vector2(g.CELL_SIZE.x * 1.25, 0)
		result.append({"owner": 1, "kind": "cirno_boss", "position": start, "velocity": velocity, "age": 1.1, "life": 1000.0, "radius": 6.0, "damage": 1.0, "color": Color.WHITE, "shape": "ice", "arming_time": 1.0, "reflected": case == "reflected"})
	return result

func benchmark(case: String, dimensions: Vector2, optimized: bool, frames: int = 80) -> Dictionary:
	var g := make_case(case, dimensions)
	var dm = Game.TouhouDanmakuRuntime.new(g) if optimized else Legacy.new(g)
	var template := projectiles(g, case)
	var samples: Array = []
	var cells := 0
	var components := 0
	var zombies := 0
	var damage_hits := 0
	var retained := 0
	for frame in range(frames + 8):
		dm.bullets = template.duplicate(true)
		for z in g.zombies:
			z.health = 100000000.0
		for row in g.grid:
			for p in row:
				if p != null:
					p.health = 100000000.0
					p.erase("reflect_cooldown_until")
		g.counters()
		var start := Time.get_ticks_usec()
		dm.update(0.1 if case == "crossboard" else 1.0 / 60.0)
		var elapsed := Time.get_ticks_usec() - start
		if frame >= 8:
			samples.append(elapsed)
			cells += g.cell_checks
			components += g.mirror_component_checks
			zombies += g.zombie_checks
			damage_hits += g.hits.size()
			retained += dm.bullets.size()
	samples.sort()
	var sum := 0.0
	for sample in samples: sum += float(sample)
	var result := {"case": case, "cells": [dimensions.x, dimensions.y], "implementation": "current" if optimized else "legacy", "frames": frames, "mean_us": sum / frames, "p95_us": samples[ceili(frames * 0.95) - 1], "cell_checks_per_frame": float(cells) / frames, "mirror_component_checks_per_frame": float(components) / frames, "zombie_checks_per_frame": float(zombies) / frames, "damage_hits_per_frame": float(damage_hits) / frames, "retained_per_frame": float(retained) / frames}
	g.free()
	return result

func _run() -> void:
	var results: Array = []
	var gate_only := OS.get_cmdline_user_args().has("--gate-only")
	for dimensions in [Vector2(135, 110), Vector2(76, 33)]:
		for case in (["full", "crossboard", "reflected"] if gate_only else ["empty", "full", "crossboard", "mirror", "reflected"]):
			for trial in range(1 if gate_only else 3):
				for optimized in ([true, false] if trial % 2 else [false, true]):
					var r := benchmark(case, dimensions, optimized, 12 if gate_only else 80)
					r["trial"] = trial
					results.append(r)
					print(JSON.stringify(r))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var name := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	if gate_only: name = "gate"
	var f := FileAccess.open(OUTPUT + "/" + name + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "records": results}, "\t") + "\n")
	if name != "before":
		for dimensions in [Vector2(135, 110), Vector2(76, 33)]:
			for case in ["full", "crossboard", "reflected"]:
				var current: Dictionary = results.filter(func(r): return r.cells == [dimensions.x, dimensions.y] and r.case == case and r.implementation == "current")[0]
				var legacy: Dictionary = results.filter(func(r): return r.cells == [dimensions.x, dimensions.y] and r.case == case and r.implementation == "legacy")[0]
				check(current.damage_hits_per_frame == legacy.damage_hits_per_frame and current.retained_per_frame == legacy.retained_per_frame, "Optimization preserves native collision count and every surviving bullet: " + case)
				if case == "reflected":
					check(current.zombie_checks_per_frame <= legacy.zombie_checks_per_frame * 0.4, "Reflected sweep rejects irrelevant enemies before eligibility checks")
				else:
					check(current.cell_checks_per_frame <= legacy.cell_checks_per_frame * 0.7, "Dense sweep lowers actual target-cell reads without lowering the shot count: " + case)
	print("Dense native benchmark: ", results.size(), " alternating measurements; ", failures, " failure(s)")
	quit(1 if failures else 0)
