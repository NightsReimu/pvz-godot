extends SceneTree

const Game = preload("res://scripts/game.gd")
const PlantRuntimeScript = preload("res://scripts/runtime/plant_runtime.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var game := Game.new()
	game.current_level = {"id": "magic-variants", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	for row in range(6):
		var cells: Array = []
		cells.resize(9)
		game.grid.append(cells)
		game.support_grid.append(cells.duplicate())
	var runtime = game._ensure_plant_runtime()
	var center := game._cell_center(2, 3)
	var expected := {"moonforge_shot": "moon_meteor", "prism_pea": "prism_pea", "shadow_pea": "shadow_pea", "spiral_bamboo": "boomerang", "cluster_boomerang": "boomerang", "origami_plane": "origami_plane", "snow_pea": "snow_pea", "phoenix_flame": "phoenix_flame"}
	for variant in PlantRuntimeScript.MAGIC_FLOWER_PROJECTILES:
		game.projectiles = [{"kind": "sentinel", "anti_air": false}]
		game.rollers.clear()
		game.rng.seed = 138
		runtime._spawn_magic_flower_projectile(2, center, 1.0, variant)
		check(not bool(game.projectiles[0].anti_air), "%s must never change another plant's shot" % variant)
		var shots: Array = game.rollers if variant == "mango" else game.projectiles.slice(1)
		check(shots.size() == 1, "%s must create exactly one initial projectile or roller" % variant)
		if shots.is_empty(): continue
		var shot: Dictionary = shots[0]
		if expected.has(variant):
			check(shot.kind == expected[variant], "%s must use its native collision and rendering type" % variant)
		if variant == "prism_pea": check(int(shot.get("split_count", 0)) == 3, "Prism shots must split into three real fragments")
		if variant == "shadow_pea": check(int(shot.get("pierce_left", 0)) == 2, "Shadow shots must retain piercing")
		if variant == "spiral_bamboo": check(float(shot.get("return_damage", 0)) > 0, "Bamboo must have return damage")
		if variant == "cluster_boomerang": check(int(shot.get("cluster_owner_col", -1)) == 3, "Cluster boomerang must return to the actual owner cell")
		var baseline := float(shot.damage)
		game.projectiles.clear()
		game.rollers.clear()
		game.rng.seed = 138
		runtime._spawn_magic_flower_projectile(2, center, 2.0, variant)
		var stronger: Dictionary = game.rollers[0] if variant == "mango" else game.projectiles[0]
		check(is_equal_approx(float(stronger.damage), baseline * 2.0), "%s must respect the magic flower's damage multiplier" % variant)
	game.free()
	print("Magic flower: 20 native variants, isolation, ownership and damage scaling; %d failures" % failures)
	quit(1 if failures else 0)
