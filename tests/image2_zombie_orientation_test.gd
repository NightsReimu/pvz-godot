extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_enemy_zombies_face_left() or failed
	failed = not _test_art_left_exceptions_do_not_flip() or failed
	failed = not _test_hypnotized_zombies_face_right() or failed
	failed = not _test_wrong_facing_bosses_are_marked_for_flip() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	return game


func _zombie(kind: String, hypnotized: bool = false) -> Dictionary:
	return {"kind": kind, "hypnotized": hypnotized}


func _test_enemy_zombies_face_left() -> bool:
	var game = _make_game()
	var passed := true
	# day/night/fog/roof bosses ship as right-facing art; as enemies they must flip.
	for kind in ["day_boss", "night_boss", "fog_boss", "roof_boss", "normal", "conehead", "buckethead", "gargantuar"]:
		passed = _assert_true(game._image2_zombie_should_flip(kind, _zombie(kind, false)), "%s enemy should be flipped to face left" % kind) and passed
	game.free()
	return passed


func _test_art_left_exceptions_do_not_flip() -> bool:
	var game = _make_game()
	var passed := true
	# pool_boss / city_boss art already faces left; as enemies they must NOT flip.
	for kind in ["pool_boss", "city_boss"]:
		passed = _assert_true(not game._image2_zombie_should_flip(kind, _zombie(kind, false)), "%s (art faces left) enemy should not be flipped" % kind) and passed
	game.free()
	return passed


func _test_hypnotized_zombies_face_right() -> bool:
	var game = _make_game()
	var passed := true
	# Hypnotized zombies move right toward enemy zombies; they must face right.
	# Right-facing art should NOT be flipped; left-facing art SHOULD be flipped.
	passed = _assert_true(not game._image2_zombie_should_flip("normal", _zombie("normal", true)), "hypnotized normal (art right) should face right -> no flip") and passed
	passed = _assert_true(game._image2_zombie_should_flip("pool_boss", _zombie("pool_boss", true)), "hypnotized pool_boss (art left) should face right -> flip") and passed
	game.free()
	return passed


func _test_wrong_facing_bosses_are_marked_for_flip() -> bool:
	var game = _make_game()
	var passed := true
	# Regression guard: the four confirmed wrong-facing bosses must flip.
	for kind in ["day_boss", "night_boss", "fog_boss", "roof_boss"]:
		passed = _assert_true(game._image2_zombie_should_flip(kind, _zombie(kind, false)), "%s must remain marked for horizontal flip" % kind) and passed
	# Correct-facing bosses must remain in the exception set.
	for kind in ["pool_boss", "city_boss"]:
		passed = _assert_true(bool(game.IMAGE2_ZOMBIE_ART_FACES_LEFT.get(kind, false)), "%s must remain in IMAGE2_ZOMBIE_ART_FACES_LEFT" % kind) and passed
	game.free()
	return passed
