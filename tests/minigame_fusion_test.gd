extends "res://tests/ancient_world_test.gd"

func test_rain_fusion() -> void:
	var g = make_game()
	g._start_minigame("rain")
	check(g._ensure_plant_fusion().enabled(), "Rain exposes fusion tool")
	g.grid[0][0] = g._create_plant("peashooter",0,0)
	g.selected_tool = "snow_pea"
	g._handle_board_click(Vector2i(0,0))
	check(g.grid[0][0].get("fusion_kind","") == Fusion.result("peashooter","snow_pea"), "Held rain seed fuses by stacking")
	check(g.sun_points == 0 and g.selected_tool == "", "Rain consumes held seed without charging sun")
	g.grid[0][1] = g._create_plant("wallnut",0,1)
	check(g._ensure_plant_fusion().merge_cells(Vector2i(0,1),Vector2i(0,0)), "Two field plants can fuse in rain")
	check(g.grid[0][1] == null, "Field fusion consumes donor")
	check(g._ensure_ancient_expansion().current() == "rain", "Rain minigame participates in shared weather")
	dispose(g)

func test_objectives() -> void:
	var g = make_game()
	g._start_minigame("portals")
	g.grid[1][1] = g._create_plant("peashooter",1,1)
	check(not g._ensure_plant_fusion().merge_cells(Vector2i(1,2),Vector2i(1,1)), "Core cannot be a fusion donor")
	check(not g._ensure_plant_fusion().merge_cells(Vector2i(1,1),Vector2i(1,2)), "Core cannot be a fusion host")
	check(g.minigame_runtime.fail_reason() == "", "Rejected fusion preserves portal cores")
	g._start_minigame("stars")
	var cell = preload("res://scripts/data/minigame_defs.gd").STAR_CELLS[0]
	g.grid[cell.x][cell.y] = g._create_plant(Fusion.result("starfruit","wallnut"),cell.x,cell.y)
	check(g.minigame_runtime.star_count() == 1, "Fused starfruit still lights a star")
	g._start_minigame("invisible")
	g.grid[1][1] = g._create_plant(Fusion.result("plantern","wallnut"),1,1)
	var z = spawn(g,"normal",1,1.0)
	check(g.minigame_runtime.zombie_visible(z), "Fused plantern reveals invisible zombies")
	g._start_minigame("bare")
	g.grid[0][0] = g._create_plant(Fusion.result("kernel_pult","wallnut"),0,0)
	check(g.minigame_runtime.has_attacker(), "Fused attackers permit bare challenge deployment")
	g._start_minigame("columns")
	g.grid[0][0] = g._create_plant("cabbage_pult",0,0)
	g.active_cards = ["kernel_pult"]
	g.selected_tool = "kernel_pult"
	g._handle_board_click(Vector2i(0,0))
	check(g.grid[0][0].get("fusion_kind","") == Fusion.result("cabbage_pult","kernel_pult"), "Column seed fuses occupied legal cells")
	check(g.grid[1][0] != null and g.active_cards.count("kernel_pult") == 0, "Column consumes one card after planting and fusing its rows")
	g._start_minigame("gems")
	check(not g._ensure_plant_fusion().enabled(), "Match-three retains its swap gesture")
	dispose(g)

func _run() -> void:
	test_rain_fusion()
	test_objectives()
	print("Minigame fusion: %d failures" % failures)
	quit(1 if failures else 0)
