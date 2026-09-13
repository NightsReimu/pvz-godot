extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0
var checks := 0
const MiniData = preload("res://scripts/data/minigame_defs.gd")
const MiniMenu = preload("res://scripts/ui/minigame_menu.gd")
const MiniVisuals = preload("res://scripts/ui/minigame_visuals.gd")
const CAPTURES := "res://output/minigames"

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var game := PreviewGame.new()
	game.size = Vector2(1600,900)
	root.add_child(game)
	game.rng.seed = 913
	test_rules(game)
	test_rain(game)
	test_gems(game)
	test_invisible(game)
	test_stars(game)
	test_bare(game)
	test_portals(game)
	test_columns(game)
	test_complete_waves(game)
	test_results(game)
	cleanup(game)
	if OS.get_cmdline_user_args().has("--capture"): await capture_flows()
	await process_frame
	print("Seven minigames: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func test_rules(game: Control) -> void:
	game._enter_minigames_mode()
	check(game.mode == game.MODE_MINIGAMES,"Independent menu")
	for entry in MiniData.ENTRIES:
		var level := MiniData.level(entry.id)
		for kind in level.minigame_cards: check(game.Defs.PLANTS.has(kind),"Loaned seed exists: "+kind)
		for event in level.events: check(game.Defs.ZOMBIES.has(event.kind),"Enemy exists: "+event.kind)
		game._start_minigame(entry.id)
		game._check_end_state()
		check(game.battle_state == game.BATTLE_PLAYING,"No immediate win: "+entry.id)
		var before := float(game.level_time)
		game.battle_paused = true
		game._process(1)
		check(game.level_time == before,"Pause freezes mini: "+entry.id)
		game.battle_paused = false
		game._handle_primary_click(MiniVisuals.help_rect(game).get_center())
		game._process(1)
		check(game.level_time == before and game.minigame_runtime.help_open,"Help pauses mini: "+entry.id)
		game._handle_primary_click(MiniVisuals.help_close_rect(game).get_center())
		game._restart_current_battle()
		check(game.minigame_runtime.spawn_index == 0 and game.level_time == 0,"Fresh retry: "+entry.id)
		game._enter_map_mode()
		check(game.mode == game.MODE_MINIGAMES,"Exit returns to hub: "+entry.id)

func test_rain(game: Control) -> void:
	game._start_minigame("rain")
	var rt = game.minigame_runtime
	game._update_conveyor(100)
	check(game.active_cards.count("")==6,"Rain has no automatic conveyor")
	rt.update_rain(0.1)
	check(rt.packets.size()==1,"Seed falls")
	var point: Vector2 = rt.packet_rect(rt.packets[0]).get_center()
	game._handle_primary_click(point)
	check(game.active_cards.has("peashooter") and rt.packets.is_empty(),"Click collects falling seed")
	game.selected_tool = "peashooter"
	game._handle_board_click(Vector2i(0,0))
	check(game.grid[0][0] != null and game.sun_points == 0 and game.active_cards.count("")==6,"Free planting consumes collected seed")
	game.active_cards.fill("wallnut")
	rt.update_rain(2)
	game._handle_primary_click(rt.packet_rect(rt.packets[0]).get_center())
	check(rt.packets.size()==1,"Full bank leaves seed on field")
	rt.packet_timer = 100
	rt.update_rain(16)
	check(rt.packets.is_empty(),"Seeds expire")
	check(game._placement_error("peashooter",2,0)!="" and game._placement_error("lily_pad",2,0)=="","Water still requires pads")

func test_gems(game: Control) -> void:
	for seed_value in range(12):
		game.rng.seed = seed_value
		game._start_minigame("gems")
		var p = game.minigame_runtime.puzzle
		check(p.groups().is_empty(),"Puzzle starts without free matches")
		check(not p.find_move().is_empty(),"Puzzle starts solvable")
	var puzzle = game.minigame_runtime.puzzle
	var old: Dictionary = game.grid[0][0]
	puzzle.click(Vector2i(0,0))
	puzzle.click(Vector2i(4,7))
	check(game.grid[0][0] == old and puzzle.selected == Vector2i(4,7),"Nonadjacent click selects instead of swapping")
	puzzle.selected = Vector2i(-1,-1)
	var move: Array = puzzle.find_move()
	puzzle.click(move[0])
	puzzle.click(move[1])
	check(not puzzle.pending.is_empty(),"Valid swap queues visible match")
	for frame in range(100): puzzle.update(0.1)
	check(puzzle.score > 0 and puzzle.pending.is_empty() and not puzzle.find_move().is_empty(),"Match resolves, refills, remains playable")
	var invalid_found := false
	for row in range(5):
		for col in range(7):
			if invalid_found: break
			var a := Vector2i(row,col)
			var b := a+Vector2i(0,1)
			puzzle.exchange(a,b)
			var invalid: bool = puzzle.groups().is_empty()
			puzzle.exchange(a,b)
			if not invalid: continue
			var original = game.grid[row][col]
			puzzle.selected = Vector2i(-1,-1)
			puzzle.click(a)
			puzzle.click(b)
			check(game.grid[row][col] == original,"Invalid swap restores exact plant and HP")
			invalid_found = true
	game.grid[2][3] = null
	puzzle.update(0.1)
	check(game.grid[2][3] != null,"Eaten tile refills")
	for turn in range(150):
		for frame in range(50): puzzle.update(0.1)
		if puzzle.score >= 50: break
		var next: Array = puzzle.find_move()
		if next.is_empty(): break
		puzzle.selected = Vector2i(-1,-1)
		puzzle.click(next[0])
		puzzle.click(next[1])
	check(puzzle.score >= 50,"Goal reachable using legal swaps through repeated refill and hint cycles")
	puzzle.score = 49
	game.next_event_index = game.current_level.events.size()
	game._check_end_state()
	check(game.battle_state == game.BATTLE_PLAYING,"Empty enemies do not finish puzzle")
	puzzle.score = 50
	game._check_end_state()
	check(game.battle_state == game.BATTLE_WON,"50 groups wins")

func test_invisible(game: Control) -> void:
	game._start_minigame("invisible")
	game._spawn_zombie_at("normal",2,game._cell_center(2,5).x,true)
	var zombie: Dictionary = game.zombies.back()
	zombie.flash = 0
	check(not game.minigame_runtime.zombie_visible(zombie),"Unhit zombie invisible")
	check(game._has_zombie_ahead(2,game._cell_center(2,0).x) and not game._is_hidden_from_lane_attacks(zombie),"Invisible zombie still targeted")
	var hp := float(zombie.health)
	game._apply_zombie_damage(zombie,20,0.3)
	check(zombie.health<hp and game.minigame_runtime.zombie_visible(zombie),"Damage lands and flashes invisible enemy")
	zombie.flash = 0
	game.grid[2][4] = game._create_plant("plantern",2,4)
	check(game.minigame_runtime.zombie_visible(zombie),"Nearby lamp reveals")
	game.grid[2][4] = null
	zombie.slow_timer = 2
	check(game.minigame_runtime.zombie_visible(zombie),"Ice reveals")

func test_stars(game: Control) -> void:
	game._start_minigame("stars")
	for cell in MiniData.STAR_CELLS: game.grid[cell.x][cell.y] = game._create_plant("starfruit",cell.x,cell.y)
	check(game.minigame_runtime.star_count()==14 and game.minigame_runtime.won(),"All star positions wins")
	game.grid[0][4].health = 0
	check(not game.minigame_runtime.won(),"Dead star does not fulfill objective")
	game.grid[0][4] = game._create_plant("wallnut",0,4)
	check(not game.minigame_runtime.won(),"Non-star occupying target does not count")

func test_bare(game: Control) -> void:
	game._start_minigame("bare")
	var rt = game.minigame_runtime
	game._process(15)
	check(game.level_time == 0 and game.zombies.is_empty() and game.sun_points==5000,"Unlimited planning time and fixed sun")
	check(not game._level_has_sky_sun() and game._placement_error("cabbage_pult",0,0)!="","Bare ground needs pots; no sky income")
	game._handle_primary_click(MiniVisuals.action_rect(game).get_center())
	check(rt.planning,"Cannot start an empty defense")
	for kind in ["flower_pot","cabbage_pult"]:
		game.selected_tool = kind
		game._handle_board_click(Vector2i(0,0))
		game._process(0.1)
	check(game.grid[0][0]!=null and game.support_grid[0][0]!=null,"Pot then attacker on bare stone")
	game._handle_primary_click(MiniVisuals.action_rect(game).get_center())
	check(not rt.planning,"Start button launches combat")
	var before := int(game.sun_points)
	rt.spawn_index = 10
	rt.update_spawns(0.1)
	check(rt.planning and rt.wave==2 and game.sun_points==before+250,"Cleared round grants one resupply and intermission")
	rt.update_spawns(9)
	check(game.sun_points==before+250,"Intermission cannot duplicate supply")
	game.grid[0][0].health *= 0.5
	before = game.sun_points
	game.selected_tool = "shovel"
	game._handle_board_click(Vector2i(0,0))
	check(game.grid[0][0]==null and game.sun_points==before+int(game._endless_cost_for_kind("cabbage_pult")*0.5),"Damaged-plant refund uses remaining health")
	rt.planning = false
	rt.spawn_index = game.current_level.events.size()
	check(rt.won(),"Fifth round ends only after final enemy is gone")

func test_portals(game: Control) -> void:
	game._start_minigame("portals")
	var rt = game.minigame_runtime
	var core: Dictionary = rt.cores[0]
	game.selected_tool = "shovel"
	game._handle_board_click(Vector2i(1,2))
	check(game.grid[1][2]==core,"Core cannot be shoveled")
	game._spawn_zombie_at("normal",0,game._cell_center(0,7).x,true)
	var zombie: Dictionary = game.zombies.back()
	rt.update_portals(0.1)
	check(zombie.row==1 and is_equal_approx(zombie.x,game._cell_center(1,4).x),"Portal relocates enemy in front of defended core")
	zombie.x = game._cell_center(0,7).x
	zombie.row = 0
	rt.update_portals(0.1)
	check(zombie.row == 0,"A zombie cannot loop through portals")
	rt.update_portals(24)
	check(rt.portal_rows == [2,0],"Entrance routes rotate")
	core.health = 0
	game._check_end_state()
	check(game.battle_state==game.BATTLE_LOST,"Core destruction loses")

func test_columns(game: Control) -> void:
	game._start_minigame("columns")
	game.active_cards = ["cabbage_pult","cabbage_pult","flower_pot","","",""]
	game.selected_tool = "cabbage_pult"
	game._handle_board_click(Vector2i(2,4))
	check(game.active_cards.count("cabbage_pult")==2,"Invalid column consumes nothing")
	game.selected_tool = "flower_pot"
	game._handle_board_click(Vector2i(2,4))
	for row in range(5): check(game.support_grid[row][4]!=null,"Whole support column planted")
	game.grid[1][4] = game._create_plant("wallnut",1,4)
	game.selected_tool = "cabbage_pult"
	game._handle_board_click(Vector2i(2,4))
	check(game.active_cards.count("cabbage_pult")==1,"Exactly one card consumed")
	check(game.grid[1][4].kind=="wallnut","Existing plants preserved")
	for row in [0,2,3,4]: check(game.grid[row][4].kind=="cabbage_pult","Valid empty cells filled")

func test_complete_waves(game: Control) -> void:
	for id in ["rain","invisible","bare","portals","columns"]:
		game._start_minigame(id)
		var rt = game.minigame_runtime
		var observed := {}
		for frame in range(1400):
			if rt.planning:
				rt.planning = false
				rt.spawn_timer = 0
			game._process(0.5)
			observed[rt.wave] = true
			# Clear each actual spawn to exercise the director, death cleanup and gates.
			for zombie in game.zombies: zombie.health = 0
			if game.battle_state != game.BATTLE_PLAYING: break
		check(game.battle_state==game.BATTLE_WON,"All scheduled waves finish: "+id)
		check(observed.size()==(5 if id=="bare" else 6),"No rounds skipped: "+id)
		check(game.total_spawned_units==game.current_level.events.size(),"No campaign extra spawns: "+id)
		check(is_equal_approx(game._battle_progress_ratio(),1.0),"Completed progress reaches 100%: "+id)

func test_results(game: Control) -> void:
	game.minigame_clears.clear()
	var campaign: Array = game.completed_levels.duplicate()
	var unlocked: int = game.unlocked_levels
	var coins: int = game.coins_total
	game._start_minigame("columns")
	game.minigame_runtime.spawn_index = game.current_level.events.size()
	game._check_end_state()
	check(game.battle_state==game.BATTLE_WON and game.coins_total==coins+200,"First clear grants 200")
	game._check_end_state()
	check(game.coins_total==coins+200,"Repeated win check does not double grant")
	game._restart_current_battle()
	game.minigame_runtime.spawn_index = game.current_level.events.size()
	game._check_end_state()
	check(game.coins_total==coins+200,"Replay does not duplicate first-clear reward")
	check(game.completed_levels==campaign and game.unlocked_levels==unlocked,"No campaign unlock pollution")
	var merged: Dictionary = game._merge_save_data_preserving_progress({"minigame_clears":{"rain":true}},{"minigame_clears":{"columns":true,"invalid":true}})
	check(merged.minigame_clears == {"rain":true,"columns":true},"Save merge preserves previous badges and filters invalid IDs")
	game._apply_loaded_save_data({"minigame_clears":{"rain":true,"gems":"yes"}})
	check(game.minigame_clears == {"rain":true},"Load validates badge types")
	game._on_message_button_pressed()
	check(game.mode == game.MODE_MINIGAMES,"Win panel returns to minigame hub")

func capture_flows() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURES))
	for viewport in [Vector2i(1600,900),Vector2i(844,390)]:
		var surface := SubViewport.new()
		surface.size = viewport
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(surface)
		var game := PreviewGame.new()
		game.size = Vector2(viewport)
		game.mobile_runtime_override = 1 if viewport.x == 844 else 0
		surface.add_child(game)
		game._enter_minigames_mode()
		await save_capture(game,"%d-menu" % viewport.x)
		for i in range(MiniData.ENTRIES.size()):
			var entry: Dictionary = MiniData.ENTRIES[i]
			game._enter_minigames_mode()
			# Drive the real touch-release coordinate conversion on both sizes.
			var touch := InputEventScreenTouch.new()
			touch.position = game._ui_offset(game.MODE_MINIGAMES)+MiniMenu.card_rect(i).get_center()*game._ui_scale_vector(game.MODE_MINIGAMES)
			touch.pressed = false
			game._unhandled_input(touch)
			check(game._is_minigame() and game.current_level.minigame==entry.id,"Touch opens "+entry.id)
			var rt = game.minigame_runtime
			if rt.id != "gems":
				for row in range(game.board_rows):
					for col in range(2):
						if rt.id in ["bare","columns"]: game.support_grid[row][col] = game._create_plant("flower_pot",row,col)
						if rt.id=="rain" and row in [2,3]: game.support_grid[row][col] = game._create_plant("lily_pad",row,col)
						game.grid[row][col] = game._create_plant("cabbage_pult" if rt.id in ["bare","columns"] else "repeater",row,col)
			if rt.planning: rt.click(MiniVisuals.action_rect(game).get_center())
			for n in range(400): game._process(0.1)
			check(game.battle_state==game.BATTLE_PLAYING,"40 seconds of real combat without premature completion: "+entry.id)
			check(not game.zombies.is_empty() or game.total_kills>0,"Real enemies arrive: "+entry.id)
			if rt.id=="portals": rt.portal_time = 22
			game._drain_asset_prewarm_queue()
			game.banner_timer = 0
			game.banner_label.visible = false
			check(MiniVisuals.footer_rect(game).position.y>=game.BOARD_ORIGIN.y+game.board_size.y,"Footer leaves planting board clear")
			await save_capture(game,"%d-%s" % [viewport.x,entry.id])
			if rt.id=="bare":
				rt.help_open = true
				await save_capture(game,"%d-help" % viewport.x)
		cleanup(game)
		surface.free()

func save_capture(game: Control, label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var im: Image = game.get_viewport().get_texture().get_image()
	check(im.save_png("%s/%s.png" % [CAPTURES,label])==OK,"Capture saved")

func cleanup(game: Control) -> void:
	game.save_dirty = false
	for child in game.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	game.free()
