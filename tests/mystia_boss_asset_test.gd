extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScript.new()
	var passed := true
	var frames := game._load_boss_frame_set("mystia_boss", false)
	passed = _assert_true(frames.size() == 24, "Mystia should provide 24 animation frames") and passed
	for index in range(frames.size()):
		passed = _assert_true(frames[index] is Texture2D, "Mystia frame %02d should load as a texture" % index) and passed
	game.free()
	quit(0 if passed else 1)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
