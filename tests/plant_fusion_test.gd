extends SceneTree
const Game = preload("res://scripts/game.gd")
const Native = preload("res://scripts/data/plant_defs.gd")
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
var failures := 0
func _initialize():
	call_deferred("_run")
func check(value: bool, message: String):
	if not value:
		failures += 1
		push_error(message)
func make_game() -> Control:
	var g = Game.new()
	g.current_level = {"id":"fusion-test", "terrain":"day", "events":[]}
	g.active_rows = [0,1,2,3,4]; g.board_rows = 5; g.board_size = Vector2(882,550)
	g.toast_label = Label.new(); g.sun_points = 10000
	for r in range(g.ROWS):
		g.grid.append([]); g.support_grid.append([])
		for c in range(g.COLS):
			g.grid[r].append(null); g.support_grid[r].append(null)
	for k in Defs.PLANTS: g.card_cooldowns[k] = 0.0
	return g
func dispose(g):
	g.save_dirty = false; g.toast_label.free(); g.free()
func ready_weapons(g: Control, row: int, col: int, bursts: bool = false):
	var p: Dictionary = g._targetable_plant_at(row,col)
	for channel in Defs.PLANTS[p.fusion_kind].fusion_channels:
		if bursts or channel.style != "burst": p.fusion_channel_timers[channel.source] = 0

func test_canonical():
	var g = make_game()
	g.grid[2][2] = g._create_plant("peashooter",2,2)
	g.selected_tool = "peashooter"; g._handle_board_click(Vector2i(2,2))
	check(String(g.grid[2][2].kind) == "repeater", "Real pea-on-pea placement reuses existing repeater")
	g.grid[2][3] = g._create_plant("repeater",2,3)
	check(g._ensure_plant_fusion().merge_cells(Vector2i(2,3),Vector2i(2,2)), "Two planted repeaters can merge")
	check(g.grid[2][3] == null and g.grid[2][2].get("fusion_kind","") == "gatling_pea", "Board merge consumes donor and yields gatling")
	g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+170)
	ready_weapons(g,2,2)
	g._update_plants(0.1)
	check(g.projectiles.size() == 4, "Gatling fires four real projectiles per volley")
	dispose(g)

func test_catalogue():
	var g = make_game()
	check(Fusion.DEFINITIONS.size() >= 290,"All native plants have multiple fusion evolutions")
	for k in Native.ORDER:
		var first: String = g._fusion_result(k,k)
		check(not first.is_empty(),"Native fusion coverage: "+k)
		check(not g._fusion_result(first,k).is_empty(),"Recursive feeding route: "+k)
	for pair in Fusion.RECIPES:
		var input: PackedStringArray = String(pair).split("+")
		check(g._fusion_result(input[0],input[1]) == g._fusion_result(input[1],input[0]),"Recipe is symmetric: "+pair)
	for id in Fusion.DEFINITIONS:
		g.projectiles.clear(); g.rollers.clear(); g.effects.clear(); g.zombies.clear(); g.suns.clear()
		for r in range(g.ROWS):
			for c in range(g.COLS): g.grid[r][c] = null; g.support_grid[r][c] = null
		var d: Dictionary = Defs.PLANTS[id]
		var plant: Dictionary = g._create_plant(id,2,2)
		plant.sleep_timer = 0
		if d.fusion_base in Fusion.SUPPORTS: g.support_grid[2][2] = plant
		else: g.grid[2][2] = plant
		check(plant.get("fusion_kind","") == id and plant.kind == d.fusion_base,"Catalogue and passive identity: "+id)
		check(g._ultimate_profile_for_kind(id).get("style","") == "explicit","Named click/food ultimate: "+id)
		g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+40)
		g.zombies[0].health = 100000; g.zombies[0].max_health = 100000
		g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+40)
		g.zombies[1] = g._hypnotize_zombie(g.zombies[1])
		var friend_hp: float = g.zombies[1].health
		# Exercise each channel after its own complete charging cycle. A passive wall does not shoot.
		var enemy_before: Dictionary = g.zombies[0].duplicate(true)
		ready_weapons(g,2,2,true)
		g._update_plants(1.0)
		if not d.fusion_channels.is_empty():
			var reachable: bool = d.fusion_channels.any(func(channel): return channel.get("blast_shape","") != "single" and float(channel.get("range",10000)) >= 100 or float(channel.get("range",0)) >= 100)
			if reachable: check(not g.projectiles.is_empty() or not g.rollers.is_empty() or g.zombies[0] != enemy_before,"Fusion retains its real charged attack: "+id)
		check(g.zombies[1].health == friend_hp,"Normal fusion respects allies: "+id)
		var before: Array = [g.projectiles.size(),g.rollers.size(),g.suns.size(),g.zombies[0].duplicate(true),plant.duplicate(true),g.zombies.size()]
		check(g._activate_plant_food(2,2),"Actual energy bean activation: "+id)
		var after: Array = [g.projectiles.size(),g.rollers.size(),g.suns.size(),g.zombies[0],plant,g.zombies.size()]
		# Charge/cooldown/animation alone are not a working ultimate.
		var beneficial: bool = before[0] != after[0] or before[1] != after[1] or before[2] != after[2] or before[3] != after[3] or before[5] != after[5]
		for field in ["health","armor_health","fusion_haste_timer","fusion_renewal_timer","holy_invincible_timer"]:
			beneficial = beneficial or float(after[4].get(field,0)) > float(before[4].get(field,0))
		check(beneficial,"Every fusion ultimate changes actual combat/resources: "+id)
		check(g.zombies[1].health == friend_hp,"Ultimate respects allies: "+id)
		check(not g.effects.is_empty(),"Fusion ultimate has an effect: "+id)
	dispose(g)

func test_resource_and_state():
	var g = make_game()
	g.grid[2][2] = g._create_plant("sunflower",2,2)
	g.grid[2][2].health *= 0.25; g.grid[2][2].ultimate_cooldown = 80
	g.grid[2][2].armor_health = 200; g.grid[2][2].max_armor_health = 300; g.grid[2][2].shell_kind = "pumpkin"
	var before: Dictionary = g.grid[2][2].duplicate(true)
	g.sun_points = 0; g.selected_tool = "sunflower"; g._handle_board_click(Vector2i(2,2))
	check(g.grid[2][2] == before and g.card_cooldowns.sunflower == 0,"Insufficient sun is atomic")
	g.sun_points = 10000; g.card_cooldowns.sunflower = 5; g._handle_board_click(Vector2i(2,2))
	check(g.grid[2][2] == before and g.sun_points == 10000,"Cooldown rejection is atomic")
	g.card_cooldowns.sunflower = 0; g.grid[2][2].reimu_sealed = true
	g._handle_board_click(Vector2i(2,2))
	check(not g.grid[2][2].has("fusion_kind") and g.sun_points == 10000,"Sealed plants cannot use fusion to escape")
	g.grid[2][2].reimu_sealed = false; g._handle_board_click(Vector2i(2,2))
	var p: Dictionary = g.grid[2][2]
	check(is_equal_approx(p.health/p.max_health,0.25),"Fusion retains injury fraction")
	check(p.ultimate_cooldown == 80 and p.armor_health == 200 and p.shell_kind == "pumpkin","Fusion preserves cooldown and outer armor")
	g.card_cooldowns.sunflower = 0; g.selected_tool = "sunflower"; g._handle_board_click(Vector2i(2,2))
	check(g.grid[2][2].fusion_kind == "triple_sunflower","Fusion plant can accept another seed")
	g.grid[2][3] = g._create_plant("wallnut",2,3)
	g.grid[2][3].reimu_sealed = true
	before = g.grid[2][3].duplicate(true); var receiver: Dictionary = g.grid[2][2].duplicate(true)
	check(not g._ensure_plant_fusion().merge_cells(Vector2i(2,3),Vector2i(2,2)),"Controlled donor fusion rejected")
	check(g.grid[2][3] == before and g.grid[2][2] == receiver,"Failed board merge preserves both specimens")
	dispose(g)

func test_projectile_effects():
	var g = make_game()
	var center: Vector2 = g._cell_center(2,2)
	g.grid[2][2] = g._create_plant("winter_melon",2,2)
	g._spawn_zombie_at("normal",2,center.x+150)
	g._spawn_zombie_at("normal",2,center.x+155)
	g.zombies[1] = g._hypnotize_zombie(g.zombies[1])
	var friend_hp: float = g.zombies[1].health
	ready_weapons(g,2,2); g._update_plants(0.1)
	check(g.projectiles.size() == 1 and g.projectiles[0].has("arc_target"),"Ice melon uses a real lob")
	g._update_projectiles(2.0)
	check(g.zombies[0].health < g.zombies[0].max_health,"Fusion lob impact deals damage")
	check(float(g.zombies[0].get("slow_timer",0)) > 0,"Ice melon impact applies slow")
	check(g.zombies[1].health == friend_hp,"Fusion area impact skips hypnotized zombies")
	g.zombies.clear(); g.projectiles.clear()
	g.grid[2][2] = g._create_plant("eclipse_blade",2,2)
	g._spawn_zombie_at("bucket_ninja_door",2,center.x+65)
	var armor: float = g.zombies[0].headgear_health
	var door: float = g.zombies[0].handheld_health
	ready_weapons(g,2,2); g._update_plants(0.1)
	# Test the returning blade channel independently of the inherited snow-pea channel.
	g.projectiles = g.projectiles.filter(func(shot): return shot.kind == "boomerang")
	g._update_projectiles(0.05)
	check(g.zombies[0].headgear_health < armor and g.zombies[0].handheld_health == door,"Fusion blade pierces handheld but cannot pierce headgear")
	check(float(g.zombies[0].get("corrode_timer",0)) > 0 and float(g.zombies[0].get("slow_timer",0)) > 0,"Ice/fire blade applies both real statuses")
	dispose(g)

func test_support_and_click():
	var g = make_game()
	g.current_level.terrain = "pool"; g.water_rows = [2,3]
	g.support_grid[2][2] = g._create_plant("lily_pad",2,2)
	g.grid[2][2] = g._create_plant("peashooter",2,2)
	g.selected_tool = "lily_pad"; g._handle_board_click(Vector2i(2,2))
	check(g.support_grid[2][2].get("fusion_kind","") == "fusion_lily_pad" and g.grid[2][2].kind == "peashooter","Pad graft preserves the host and the support layer")
	g._update_plants(1.0)
	check(g._placement_error("wallnut",2,3) != "","Water requirement remains intact")
	g.grid[2][2].sleep_timer = 15; g.grid[2][2].kind = "fume_shroom"
	g.selected_tool = "coffee_bean"; g._handle_board_click(Vector2i(2,2))
	check(g.grid[2][2].sleep_timer == 0 and not g.grid[2][2].has("fusion_kind"),"Coffee retains wake gesture")
	g.grid[2][2] = g._create_plant("twin_sunflower",2,2)
	g.grid[2][2].ultimate_charge = 1
	check(g._try_activate_ultimate(2,2),"Actual click activates a fusion ultimate")
	check(g.grid[2][2].ultimate_active and g.grid[2][2].ultimate_charge == 0,"Click ultimate retains cooldown cycle")
	dispose(g)

func test_prepared_seeds():
	for id in Native.ORDER:
		var g = make_game(); g.active_cards = [id]
		var expected: String = g._fusion_result(id,id)
		var base: String = String(Defs.PLANTS[expected].get("fusion_base",expected))
		if base in ["lily_pad","sea_shroom","tangle_kelp"]:
			g.current_level.terrain = "pool"; g.water_rows = [2,3]
		elif base == "cork_plug": g._set_cell_terrain_kind(2,2,"lava")
		elif base == "cotton_candy": g._set_cell_terrain_kind(2,2,"cloud")
		g.selected_tool = "fusion"; g._try_select_tool(id); g._try_select_tool(id)
		check(g.selected_tool == expected,"Every native seed can pre-fuse: "+id)
		var cost: int = g._endless_cost_for_kind(id)*2
		g._handle_board_click(Vector2i(2,2))
		var p = g._targetable_plant_at(2,2)
		check(p != null and g._ensure_plant_fusion().kind(p) == expected,"Every fusion can actually be planted: "+id)
		check(g.sun_points == 10000-cost and g.card_cooldowns[id] > 0,"Prepared fusion pays both ingredients: "+id)
		if p != null:
			g._update_plants(0.1)
			check(g._targetable_plant_at(2,2) != null,"Instant-use source becomes a persistent hybrid: "+id)
		dispose(g)
	var g = make_game(); g.active_cards = ["cherry_bomb"]
	g.selected_tool = "fusion"; g._try_select_tool("cherry_bomb"); g._try_select_tool("cherry_bomb")
	g.sun_points = 0; g._handle_board_click(Vector2i(2,2))
	check(g.grid[2][2] == null and g.card_cooldowns.cherry_bomb == 0,"Prepared insufficient sun doesn't consume seeds")
	g.sun_points = 10000; g._set_cell_terrain_kind(2,2,"water"); g._handle_board_click(Vector2i(2,2))
	check(g.grid[2][2] == null and g.sun_points == 10000,"Prepared terrain rejection is atomic")
	g._set_cell_terrain_kind(2,2,"land"); g._handle_board_click(Vector2i(2,2))
	check(g.grid[2][2] != null,"Failed prepared planting can be retried")
	dispose(g)
	g = make_game(); g.current_level.mode = "conveyor"; g.active_cards = ["cherry_bomb",""]
	g.selected_tool = "fusion"; g._try_select_tool("cherry_bomb"); g._try_select_tool("cherry_bomb")
	check(g.selected_tool == "fusion" and g.active_cards[0] == "cherry_bomb","Belt cannot duplicate one seed into two")
	g.active_cards = ["cherry_bomb","cherry_bomb",""]
	g._try_select_tool("cherry_bomb"); g._handle_board_click(Vector2i(2,2))
	check(g.active_cards.count("cherry_bomb") == 0 and g.grid[2][2] != null,"Belt fusion consumes two actual cards")
	dispose(g)

func test_trio_and_control():
	var g = make_game(); g.banner_label = Label.new()
	g._spawn_zombie_at("prismriver_boss",2,g._boss_anchor_x("prismriver_boss"),true)
	g.zombies[0].erase("touhou_encounter")
	for point in g._zombie_hit_positions(g.zombies[0]):
		var row: int = g._zombie_target_row(g.zombies[0],point)
		g.grid[row][0] = g._create_plant("gatling_pea",row,0)
		ready_weapons(g,row,0)
	g._update_plants(0.1)
	var rows := {}
	for shot in g.projectiles: rows[shot.row] = true
	check(rows.size() == 3,"Fusion shooters acquire all three Prismriver bodies")
	g.banner_label.free(); dispose(g)
	g = make_game()
	g.grid[2][2] = g._create_plant("gum_corn",2,2)
	g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+100)
	ready_weapons(g,2,2); g._update_plants(0.1); g._update_projectiles(2)
	check(float(g.zombies[0].get("frozen_timer",0)) > 0 and float(g.zombies[0].corrode_timer) > 0,"Gum corn uses actual stun and poison fields")
	dispose(g)

func test_thorns_cadence():
	for delta in [0.1,0.2]:
		var g = make_game()
		g.level_time = 2.0
		g.grid[2][2] = g._create_plant("fusion_cactus_guard",2,2)
		g._spawn_zombie_at("normal",2,g._cell_center(2,2).x+20)
		g.zombies[0].spawn_time = 0.0; g.zombies[0].attack_dps = 200.0
		var health: float = g.zombies[0].health
		g._update_zombies(delta)
		check(is_equal_approx(health-float(g.zombies[0].health),80.0*delta),"Fusion thorns reflect a frame-independent portion of bite damage")
		dispose(g)

func _run():
	var g = make_game()
	check(g.has_method("_fusion_result"), "Fusion recipes must be available")
	check(Defs.PLANTS.has("twin_sunflower"), "Two sunflowers must produce a twin sunflower")
	check(Defs.PLANTS.has("gatling_pea"), "Two repeaters must produce a gatling")
	if g.has_method("_fusion_result"):
		check(g._fusion_result("peashooter","peashooter") == "repeater", "Canonical pea fusion reuses repeater")
		check(g._fusion_result("repeater","repeater") == "gatling_pea", "Canonical repeater fusion")
		for k in Native.ORDER:
			check(g._fusion_result(k,k) != "", "Every native participates: " + k)
		g.grid[2][2] = g._create_plant("sunflower",2,2)
		g.selected_tool = "sunflower"
		var cost = g._endless_cost_for_kind("sunflower")
		g._handle_board_click(Vector2i(2,2))
		check(g.grid[2][2].get("fusion_kind","") == "twin_sunflower", "Actual seed placement performs fusion")
		check(g.sun_points == 10000-cost, "Fusion charges one incoming seed")
		check(g.card_cooldowns.sunflower > 0, "Fusion applies incoming seed cooldown")
	dispose(g)
	test_canonical()
	test_catalogue()
	test_resource_and_state()
	test_projectile_effects()
	test_support_and_click()
	test_prepared_seeds()
	test_trio_and_control()
	test_thorns_cadence()
	print("Plant fusion regression: %d failure(s)" % failures)
	quit(1 if failures else 0)
