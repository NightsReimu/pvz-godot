extends SceneTree
# Fusion anatomy: hybrids are drawn as one new plant, and ash grafts keep their reach into the sky.
const Game = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const Art = preload("res://scripts/ui/fusion_plant_art.gd")
var failures := 0


func _initialize():
	call_deferred("_run")


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func make_game() -> Control:
	var g = Game.new()
	g.size = Vector2(1600, 900)
	root.add_child(g)
	g.set_process(false)
	var level: Dictionary = Defs.LEVELS[0].duplicate(true)
	level["custom_level"] = true
	level["events"] = [{"time": 999.0, "kind": "normal", "row": 2}]
	g._begin_level(-1, ["peashooter", "wallnut", "cherry_bomb"], level)
	g.battle_paused = false
	g.startup_loading_active = false
	g.page_transition_active = false
	return g


func dispose(g) -> void:
	g.save_dirty = false
	for child in g.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	g.free()


func balloon_health_after(source: String) -> float:
	var g = make_game()
	var id: String = Fusion.result(source, "wallnut")
	g.grid[2][1] = g._create_plant(id, 2, 1)
	g._spawn_zombie_at("balloon_zombie", 2, g.BOARD_ORIGIN.x + g.CELL_SIZE.x * 2.3)
	var balloon: Dictionary = g.zombies.back()
	balloon["balloon_flying"] = true
	balloon["flying"] = true
	balloon["base_speed"] = 0.0
	g.grid[2][1].fusion_channel_timers[source] = 0.0
	var t := 0.0
	while t < 3.0:
		g._process(1.0 / 30.0)
		t += 1.0 / 30.0
	var health := 0.0
	for z in g.zombies:
		if String(z.kind) == "balloon_zombie": health = maxf(health, float(z.health))
	dispose(g)
	return health


func test_ash_reaches_the_sky() -> void:
	var full := float(Defs.ZOMBIES.balloon_zombie.health)
	for source in ["cherry_bomb", "jalapeno", "doom_shroom"]:
		check("anti_air" in Defs.PLANTS[Fusion.result(source, "wallnut")].fusion_traits, "An ash hybrid is marked anti-air: " + source)
		check(balloon_health_after(source) < full - 1.0, "An ash graft still blasts flying enemies: " + source)
	check(is_equal_approx(balloon_health_after("potato_mine"), full), "A buried mine still cannot reach a balloon")


func svg(a: String, b: String) -> String:
	var id: String = Fusion.result(a, b)
	return Art.svg_for(id, Defs.PLANTS[id])


func skin_hue(model: String) -> float:
	var at := model.find('<linearGradient id="skin"')
	var color := model.substr(model.find('stop-color="', at) + 12, 7)
	return Color(color).h


func test_one_new_plant() -> void:
	var cherry_pea := svg("cherry_bomb", "peashooter")
	check(cherry_pea.contains('data-model-archetype="peashooter"'), "A cherry shooter keeps the shooter's body")
	var hue := skin_hue(cherry_pea)
	check(hue < 0.06 or hue > 0.9, "The cherry partner re-colours the shooter's skin red")
	check(cherry_pea.contains('data-organ="pattern"') and cherry_pea.contains('data-organ="mood"'), "The cherry lends its gloss and angry brows")
	var nut_gun := svg("wallnut", "fume_shroom")
	check(nut_gun.contains('data-model-archetype="wallnut"') and nut_gun.contains('data-organ="weapon"'), "An unarmed wall grows its partner's nozzle from its mouth")
	var toothy := svg("snow_pea", "chomper")
	check(toothy.contains('data-organ="muzzle"') and not toothy.contains('data-organ="weapon"'), "An armed shooter reshapes its muzzle instead of growing a second gun")
	var pea_nut := svg("peashooter", "wallnut")
	check(pea_nut.contains('data-model-archetype="wallnut"'), "A plain pea grafts its snout onto a sturdier body")
	var seen := {}
	for partner in ["cherry_bomb", "snow_pea", "ice_shroom", "torchwood", "doom_shroom", "sunflower", "jalapeno", "hypno_shroom"]:
		var model := svg("repeater" if partner == "snow_pea" else "peashooter", partner)
		var image := Image.new()
		check(image.load_svg_from_string(model) == OK, "Renderable hybrid with " + partner)
		var tone := "%.2f" % skin_hue(model)
		seen[tone] = true
	check(seen.size() >= 5, "Different partners give a shooter visibly different skins")


func _run() -> void:
	test_ash_reaches_the_sky()
	test_one_new_plant()
	# Give the audio mixer time to release the stopped native playback handles.
	await create_timer(0.5).timeout
	print("Fusion anatomy: %d failure(s)" % failures)
	quit(1 if failures else 0)
