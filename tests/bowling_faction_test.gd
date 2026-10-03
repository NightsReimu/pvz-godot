extends SceneTree

const Game = preload("res://scripts/game.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func make_game() -> Control:
	var game := Game.new()
	game.current_level = {"id":"bowling-test", "terrain":"day", "events":[]}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(882, 550)
	game.toast_label = Label.new()
	return game

func free_game(game: Control) -> void:
	game.save_dirty = false
	game.toast_label.free()
	game.free()

func spawn_roller(game: Control, mango: bool, empowered: bool) -> void:
	if mango:
		game._ensure_projectile_runtime().spawn_mango_roller(2, 2, empowered)
	else:
		game._spawn_bowling_roller(2, 2, empowered)

func health_state(zombie: Dictionary) -> Array:
	return [zombie.health, zombie.shield_health, zombie.get("headgear_health", 0), zombie.get("handheld_health", 0)]

func check_friendly_pass_through(mango: bool, empowered: bool, friend_kind: String) -> void:
	var game := make_game()
	spawn_roller(game, mango, empowered)
	var roller: Dictionary = game.rollers[0].duplicate(true)
	game._spawn_zombie_at(friend_kind, 2, float(roller.x) + 8)
	game.zombies[0] = game._hypnotize_zombie(game.zombies[0])
	game.effects.clear()
	var before := health_state(game.zombies[0])
	game._update_rollers(0.01)
	var label := "%s/%s/%s" % ["mango" if mango else "wallnut", "empowered" if empowered else "ordinary", friend_kind]
	check(health_state(game.zombies[0]) == before, "Roller must preserve hypnotized health and equipment: " + label)
	check(game.rollers.size() == 1, "Friendly collision must not consume the roller: " + label)
	if game.rollers.size() == 1:
		check(game.rollers[0].hits_left == roller.hits_left, "Friendly collision must not spend a hit: " + label)
		check(game.rollers[0].row == roller.row and game.rollers[0].bounce_dir == roller.bounce_dir, "Friendly collision must not bounce: " + label)
		check(game.rollers[0].x > roller.x, "Roller keeps moving through friendly zombies: " + label)
	check(game.effects.is_empty(), "Friendly collision must not trigger an impact blast: " + label)
	free_game(game)

func check_enemy_behind_friend(mango: bool, empowered: bool) -> void:
	var game := make_game()
	spawn_roller(game, mango, empowered)
	var roller: Dictionary = game.rollers[0].duplicate(true)
	game._spawn_zombie_at("normal", 2, float(roller.x) + 8)
	game.zombies[0] = game._hypnotize_zombie(game.zombies[0])
	game._spawn_zombie_at("normal", 2, float(roller.x) + 12)
	game.zombies[1].health = 10000.0
	game.zombies[1].max_health = 10000.0
	game._spawn_zombie_at("normal", 2, float(roller.x) + 40)
	game.zombies[2].health = 10000.0
	game.zombies[2].max_health = 10000.0
	var friend_before := health_state(game.zombies[0])
	game._update_rollers(0.01)
	var label := "%s/%s" % ["mango" if mango else "wallnut", "empowered" if empowered else "ordinary"]
	check(health_state(game.zombies[0]) == friend_before, "Direct and splash damage must preserve the overlapping ally: " + label)
	check(is_equal_approx(game.zombies[1].health, 10000.0 - float(roller.damage)), "Roller must hit the enemy behind the ally exactly once: " + label)
	check(game.rollers.size() == 1 and game.rollers[0].hits_left == int(roller.hits_left) - 1, "An enemy hit spends exactly one bounce: " + label)
	if game.rollers.size() == 1:
		check(game.rollers[0].row == int(roller.row) + int(roller.bounce_dir), "Enemy collision retains lane bounce: " + label)
	var has_splash := mango or empowered
	check((game.zombies[2].health < 10000.0) == has_splash, "Enemy splash damage retains its roller variant behavior: " + label)
	free_game(game)

func _run() -> void:
	for mango in [false, true]:
		for empowered in [false, true]:
			for friend_kind in ["normal", "bucket_ninja_door"]:
				check_friendly_pass_through(mango, empowered, friend_kind)
			check_enemy_behind_friend(mango, empowered)
	print("Bowling faction regression: 4 roller variants, 12 scenarios; %d failure(s)" % failures)
	quit(1 if failures else 0)
