extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_sfx_pool_is_prepared_with_hit_streams() or failed
	failed = not _test_hit_sfx_assets_and_routing() or failed
	failed = not _test_basic_projectile_hit_emits_feedback() or failed
	failed = not _test_polished_art_assets_load_for_common_combat_readability() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_grid() -> Array:
	var result: Array = []
	for _row in range(6):
		var row_data: Array = []
		for _col in range(9):
			row_data.append(null)
		result.append(row_data)
	return result


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "polish-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.board_rows = 5
	game.board_size = Vector2(9.0 * 98.0, 5.0 * 110.0)
	game.water_rows = []
	game.grid = _make_grid()
	game.support_grid = _make_grid()
	game.zombies = []
	game.projectiles = []
	game.effects = []
	game.vfx_particles = []
	game.toast_label = Label.new()
	return game


func _free_game(game: Control) -> void:
	for player_variant in game.sfx_players:
		var player := player_variant as AudioStreamPlayer
		if player == null:
			continue
		player.stop()
		player.stream = null
	game.sfx_stream_cache.clear()
	game.polished_texture_cache.clear()
	game.image2_texture_cache.clear()
	GameScript.shared_sfx_stream_cache.clear()
	GameScript.shared_polished_texture_cache.clear()
	GameScript.shared_image2_texture_cache.clear()
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	game.free()


func _effect_log_contains_shape(game: Control, shape_name: String) -> bool:
	for effect_variant in game.effects:
		if String(Dictionary(effect_variant).get("shape", "")) == shape_name:
			return true
	return false


func _test_sfx_pool_is_prepared_with_hit_streams() -> bool:
	var game = _make_game()
	var passed := _assert_true(game.has_method("_build_sfx_players"), "game should expose an SFX player pool builder")
	if passed:
		game.call("_build_sfx_players")
		passed = _assert_true(game.sfx_players.size() >= 4, "SFX pool should contain several reusable AudioStreamPlayer nodes") and passed
		passed = _assert_true(game.has_method("_load_sfx_stream"), "game should expose a short SFX stream loader") and passed
		var hit_stream = game.call("_load_sfx_stream", "res://audio/sfx/hit-soft.wav")
		passed = _assert_true(hit_stream is AudioStreamWAV, "soft hit SFX should load as AudioStreamWAV") and passed
	_free_game(game)
	return passed


func _test_hit_sfx_assets_and_routing() -> bool:
	var game = _make_game()
	var paths := [
		"res://audio/sfx/hit-soft.wav",
		"res://audio/sfx/hit-bright.wav",
		"res://audio/sfx/hit-heavy.wav",
		"res://audio/sfx/hit-explosion.wav",
		"res://audio/sfx/hit-ice.wav",
		"res://audio/sfx/hit-electric.wav",
		"res://audio/sfx/hit-bite.wav",
	]
	var passed := _assert_true(game.has_method("_impact_sfx_path"), "game should expose impact SFX routing") \
		and _assert_true(game.has_method("_play_bite_hit_sfx"), "game should expose bite SFX throttling")
	if passed:
		for path in paths:
			passed = _assert_true(game.call("_load_sfx_stream", path) is AudioStreamWAV, "%s should load as AudioStreamWAV" % path) and passed
		passed = _assert_true(String(game.call("_impact_sfx_path", {"kind": "pea", "damage": 20.0}, false)) == "res://audio/sfx/hit-soft.wav", "basic peas should use the soft hit SFX") and passed
		passed = _assert_true(String(game.call("_impact_sfx_path", {"kind": "pea", "damage": 80.0}, true)) == "res://audio/sfx/hit-heavy.wav", "heavy peas should use the heavy hit SFX") and passed
		passed = _assert_true(String(game.call("_impact_sfx_path", {"kind": "pea", "fire": true}, true)) == "res://audio/sfx/hit-explosion.wav", "fire projectiles should use the explosion hit SFX") and passed
		passed = _assert_true(String(game.call("_impact_sfx_path", {"kind": "pea", "slow_duration": 2.0}, false)) == "res://audio/sfx/hit-ice.wav", "slow projectiles should use the ice hit SFX") and passed
		passed = _assert_true(String(game.call("_impact_sfx_path", {"kind": "amber_pea"}, false)) == "res://audio/sfx/hit-bright.wav", "crystalline projectiles should use the bright hit SFX") and passed
		passed = _assert_true(String(game.call("_impact_sfx_path", {"kind": "thunder_arc"}, false)) == "res://audio/sfx/hit-electric.wav", "electric projectiles should use the electric hit SFX") and passed
		var bite_zombie := {"bite_sfx_timer": 0.0}
		bite_zombie = game.call("_play_bite_hit_sfx", bite_zombie)
		passed = _assert_true(float(bite_zombie.get("bite_sfx_timer", 0.0)) > 0.0, "bite SFX helper should set a short cooldown") and passed
	_free_game(game)
	return passed


func _test_basic_projectile_hit_emits_feedback() -> bool:
	var game = _make_game()
	var row := 2
	var spawn_position = game._cell_center(row, 2) + Vector2(32.0, -10.0)
	game._spawn_zombie_at("normal", row, spawn_position.x + 72.0)
	game._spawn_projectile(row, spawn_position, Color(0.36, 0.86, 0.3), 20.0, 0.0, 500.0, 8.0)
	game._update_projectiles(0.12)
	var passed = _assert_true(_effect_log_contains_shape(game, "projectile_impact"), "basic pea hit should emit the shared projectile_impact effect") \
		and _assert_true(game.vfx_particles.size() >= 4, "basic pea hit should emit visible impact particles") \
		and _assert_true(float(game.screen_shake_amount) > 0.0, "basic pea hit should add a small screen shake impulse")
	_free_game(game)
	return passed


func _test_polished_art_assets_load_for_common_combat_readability() -> bool:
	var game = _make_game()
	var passed := _assert_true(game.has_method("_polished_plant_texture"), "game should expose cached polished plant texture loading") \
		and _assert_true(game.has_method("_polished_projectile_texture"), "game should expose cached polished projectile texture loading")
	if passed:
		passed = _assert_true(game.call("_polished_plant_texture", "peashooter") is Texture2D, "polished peashooter PNG should load") and passed
		passed = _assert_true(game.call("_polished_plant_texture", "sunflower") is Texture2D, "polished sunflower PNG should load") and passed
		passed = _assert_true(game.call("_polished_plant_texture", "wallnut") is Texture2D, "polished wallnut PNG should load") and passed
		passed = _assert_true(game.call("_polished_projectile_texture", "pea") is Texture2D, "polished pea projectile PNG should load") and passed
	_free_game(game)
	return passed
