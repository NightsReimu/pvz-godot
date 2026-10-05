extends SceneTree
# Signature ultimates: one action of the hybrid's weapon or role, infused by its partners,
# reaching only as far as that action.
const Game = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
var failures := 0


func _initialize():
	call_deferred("_run")


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func test_catalogue() -> void:
	var actions: Array = Fusion.Ultimates.ACTION.values()
	var names := {}
	var largest := 0
	for id in Fusion.DEFINITIONS:
		var d: Dictionary = Fusion.DEFINITIONS[id]
		var skills: Array = d.fusion_skills
		check(skills.size() >= 1 and skills.size() <= 4 and String(skills[0]) in actions, "One signature action leads the ultimate: " + id)
		check(not String(d.ultimate_name).trim_prefix("极·").contains("·") and not String(d.ultimate_name).is_empty(), "An ultimate has one name, not a list: " + id)
		names[d.ultimate_name] = int(names.get(d.ultimate_name, 0)) + 1
		largest = maxi(largest, int(names[d.ultimate_name]))
	check(names.size() > 1800 and largest <= 40, "Names follow the partner and the action instead of a few templates (%d names, largest %d)" % [names.size(), largest])
	check(String(Defs.PLANTS.steam_pea.ultimate_name) == "汽化爆流", "Named recipes keep their own ultimate")
	check(Defs.PLANTS.steam_pea.fusion_skills == ["barrage", "steam"], "Fire and frost together become one steam infusion")
	var cherry_wall: Dictionary = Defs.PLANTS[Fusion.result("cherry_bomb", "wallnut")]
	check(String(cherry_wall.ultimate_name) == "坚壳爆田" and cherry_wall.fusion_skills == ["minefield", "bastion"], "A cherry wall detonates and shields: " + String(cherry_wall.ultimate_name))
	var pea_fire: Dictionary = Defs.PLANTS[Fusion.result("peashooter", "torchwood")]
	check(pea_fire.fusion_skills == ["barrage", "inferno"] and String(pea_fire.ultimate_name) == "炬火齐射", "A torch shooter fires a burning volley")


func make_game() -> Control:
	var g = Game.new()
	g.size = Vector2(1600, 900)
	root.add_child(g)
	g.set_process(false)
	var level: Dictionary = Defs.LEVELS[0].duplicate(true)
	level["custom_level"] = true
	level["row_count"] = 5
	level["events"] = [{"time": 999.0, "kind": "normal", "row": 2}]
	g._begin_level(-1, ["peashooter", "torchwood"], level)
	g.battle_paused = false
	g.startup_loading_active = false
	g.page_transition_active = false
	return g


func test_reach() -> void:
	var g = make_game()
	var id: String = Fusion.result("peashooter", "torchwood")
	var plant: Dictionary = g._create_plant(id, 2, 1)
	plant.sleep_timer = 0
	g.grid[2][1] = plant
	g._spawn_zombie_at("buckethead", 2, g._cell_center(2, 6).x)
	g._spawn_zombie_at("buckethead", 0, g._cell_center(0, 6).x)
	g._spawn_zombie_at("buckethead", 4, g._cell_center(4, 6).x)
	for z in g.zombies:
		z.base_speed = 0.0
	g._ensure_plant_fusion().ultimate(plant, 2, 1)
	check(float(g.zombies[0].get("corrode_timer", 0)) >= 8, "The burning volley sets the lanes ahead alight")
	check(float(g.zombies[1].get("corrode_timer", 0)) <= 0 and float(g.zombies[2].get("corrode_timer", 0)) <= 0, "A shooter's flames stay within the three lanes ahead")
	g.save_dirty = false
	g.free()


func _run() -> void:
	test_catalogue()
	test_reach()
	print("Fusion signature ultimates: %d failure(s)" % failures)
	quit(1 if failures else 0)
