extends "res://tests/touhou_encounter_test.gd"

class AudioGame extends Game:
	func _ready() -> void:
		set_process(false)
	func _save_game() -> void:
		pass


func _run() -> void:
	_test_full_route("keine_boss")
	_test_whip_and_piano()
	_test_summons_and_cleanup()
	_test_bgm_and_reinforcements()
	_test_frames_and_patterns()
	print("Keine mechanics, music, assets and full encounter: %d failure(s)" % failures)
	quit(1 if failures else 0)


func keine_game() -> EncounterGame:
	var game := make_game("keine_boss")
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.board_rows = 6
	game.board_size = Vector2(882, 660)
	return game


func tick(game: Control, dt: float = 0.1) -> void:
	super.tick(game, dt)
	if game.keine_runtime != null:
		game.keine_runtime.update(dt)


func _test_whip_and_piano() -> void:
	var game := keine_game()
	var boss: Dictionary = game.zombies[0]
	var runtime = game._ensure_keine_runtime()
	for col in [0, 3, 6, 7]:
		game.grid[2][col] = game._create_plant("wallnut", 2, col)
	var near_hp: float = game.grid[2][7].health
	var far_hp: float = game.grid[2][0].health
	runtime.cast(boss, "keine_whip")
	runtime.update(1.0)
	check(game.grid[2][7].health == near_hp, "Whips must respect their warning period")
	runtime.update(2.0)
	check(game.grid[2][7].health < near_hp and game.grid[2][7].health >= near_hp - 120, "Whip sweep must hit nearby plants once per cast")
	check(game.grid[2][0].health == far_hp, "Whip radius must not hit distant plants")
	runtime.reset()
	game.grid[2][7] = null
	game.grid[2][6] = game._create_plant("peashooter", 2, 6)
	game.grid[2][6].shot_cooldown = 0.0
	var piano_hp: float = game.grid[2][6].health
	runtime.cast(boss, "keine_piano")
	runtime.update(1.15)
	check(game.grid[2][6].health == piano_hp and runtime.shots.is_empty(), "Piano telegraph must precede notes and damage")
	runtime.update(1.1)
	check(game.grid[2][6].health < piano_hp and game.grid[2][6].sleep_timer > 0, "Moving notes must damage and briefly silence the first plant they hit")
	check(game.grid[2][3].sleep_timer == 0.0, "Piano notes must collide with the frontline before plants behind it")
	game._update_plants(0.1)
	check(game.projectiles.is_empty(), "A silenced shooter must not fire")
	runtime.reset()
	game._update_plants(2.5)
	check(not game.projectiles.is_empty(), "Silenced plants must resume firing after the timer expires")
	release(game)


func _test_summons_and_cleanup() -> void:
	var game := keine_game()
	var boss: Dictionary = game.zombies[0]
	var runtime = game._ensure_keine_runtime()
	game.grid[2][6] = game._create_plant("wallnut", 2, 6)
	var original_plant: Dictionary = game.grid[2][6]
	runtime.queue_bamboo(boss, 20)
	runtime.queue_bamboo(boss, 20)
	check(runtime.attacks.size() == 6, "Summon limit includes pending telegraphs")
	var blocked_cell := Vector2i(runtime.attacks[0].cell)
	game.grid[blocked_cell.x][blocked_cell.y] = game._create_plant("wallnut", blocked_cell.x, blocked_cell.y)
	runtime.update(1.0)
	check(game.zombies.size() == 1, "Bamboo must not appear before its warning expires")
	runtime.update(0.4)
	check(game.zombies.size() == 6, "Filling a warned cell must cancel that individual summon")
	check(game.grid[2][6] == original_plant, "Summoning must preserve the player's existing plant")
	var bamboo: Dictionary = game.zombies[1]
	bamboo.row = 2
	bamboo.x = game._cell_center(2, 7).x
	bamboo.bamboo_variant = 0
	bamboo.bamboo_cooldown = 0.0
	var hp: float = original_plant.health
	runtime.update_bamboo(bamboo, 0.1)
	runtime.update(0.5)
	check(original_plant.health < hp, "Enemy bamboo leaf projectiles must harm allied plants")
	var enemy_hp: float = bamboo.health
	game.grid[2][6] = game._create_plant("peashooter", 2, 6)
	game.grid[2][6].shot_cooldown = 0.0
	game._update_plants(0.1)
	for _frame in range(40):
		game._update_projectiles(1.0 / 60.0)
	check(bamboo.health < enemy_hp, "Ordinary plant projectiles must target and damage hostile bamboo")
	game._apply_zombie_damage(bamboo, 10000.0)
	check(bamboo.health <= 0.0, "Bamboo must be destructible without a boss phase gate")
	var another: Dictionary = game.zombies[2]
	another.bamboo_variant = 1
	another.row = 2
	another.x = game._cell_center(2, 8).x
	another.bamboo_cooldown = 0.5
	var front_hp: float = game.grid[2][6].health
	runtime.update_bamboo(another, 0.2)
	check(game.grid[2][6].health == front_hp, "Pressure bamboo must warn before its thrust")
	runtime.update_bamboo(another, 0.4)
	check(game.grid[2][6].health < front_hp, "Pressure bamboo's warned line must deal damage")
	boss.erase("touhou_encounter")
	boss.health = 0.0
	runtime.update(0.1)
	check(game.zombies.filter(func(z): return z.kind == "keine_bamboo" and z.health > 0).is_empty(), "Summons must disappear when their owning boss dies")
	check(runtime.attacks.is_empty() and runtime.shots.is_empty(), "Dead owners must not leave pending damage")
	runtime.reset()
	check(runtime.attacks.is_empty() and runtime.shots.is_empty(), "Restart cleanup must clear all Keine state")
	release(game)


func _test_bgm_and_reinforcements() -> void:
	var game := AudioGame.new()
	game.size = Vector2(1600, 900)
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.board_rows = 6
	game.banner_label = Label.new()
	game.toast_label = Label.new()
	for row in range(6):
		game.grid.append([null, null, null, null, null, null, null, null, null])
		game.support_grid.append([null, null, null, null, null, null, null, null, null])
	root.add_child(game)
	game.current_level = {"id": "3-21", "events": [{"kind": "keine_boss", "time": 100.0}], "boss_intro_bgm": "res://audio/th08_keine_stage.mp3", "boss_bgm": "res://audio/th08_keine_boss.mp3"}
	game.zombies.clear()
	game._spawn_zombie_at("keine_boss", 2, game._boss_anchor_x("keine_boss"), true)
	check(game.pending_bgm_path == game.current_level.boss_bgm or game.current_bgm_path == game.current_level.boss_bgm, "Final boss entry must switch to the supplied finale music")
	var boss: Dictionary = game.zombies[0]
	game._trigger_boss_skill(boss)
	boss.rumia_reinforcement_timer = 0.0
	game._update_zombies(0.1)
	check(game.zombies.size() > 1, "Ordinary enemies must keep spawning while Keine is casting")
	check(game.zombies.all(func(z): return not game._is_water_zombie_kind(String(z.kind))), "Grass stage reinforcements must not require water")
	release(game)


func _test_frames_and_patterns() -> void:
	var game := keine_game()
	var frames: Array = game._load_boss_frame_set("keine_boss", false)
	check(frames.size() == 24, "Supplied sheet must produce 24 frames")
	for frame in frames:
		check(frame != null and frame.get_size() == Vector2(272, 272), "Frames must have consistent transparent canvases")
		if frame != null:
			var image: Image = frame.get_image()
			check(image.get_pixel(0, 0).a == 0.0 and image.get_pixel(271, 271).a == 0.0, "No opaque backdrop should remain at frame corners")
	var seen: Array = []
	for pose in ["idle", "shift", "history", "edict", "treasures", "piano", "emperor", "final"]:
		for frame in range(60):
			game.level_time = float(frame) / 20.0
			var index: int = game._keine_frame_index({"rumia_state": pose})
			if not seen.has(index):
				seen.append(index)
	check(seen.size() == 24, "All 24 supplied poses must be reachable")
	var signatures: Array = []
	for cycle in range(5):
		var boss: Dictionary = game.zombies[0]
		boss.erase("touhou_encounter")
		boss.boss_skill_cycle = cycle
		game.touhou_danmaku.cast(boss)
		var runtime = game.touhou_danmaku
		check(not runtime.bullets.is_empty() or not runtime.beams.is_empty(), "Each canonical spell must have live collision-bearing attacks")
		var signature: Array = []
		for bullet in runtime.bullets:
			signature.append([bullet.position, bullet.velocity, bullet.shape])
		check(not signatures.has(signature), "Canonical spells must differ in geometry")
		signatures.append(signature)
	release(game)
