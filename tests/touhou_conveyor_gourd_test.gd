extends SceneTree
# Every Touhou stage's conveyor hands out a healing gourd, on every difficulty
# that uses the belt, including Cirno's lake after it freezes.

const Game = preload("res://scripts/game.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
var failures := 0

class Probe extends Game:
	func _ready() -> void:
		_build_font(); _build_overlay_ui(); set_process(false)
	func _save_game() -> void:
		pass
	func _play_sfx(_p: String, _v: float = -12.0, _s: float = 1.0) -> void:
		pass

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var stages := 0
	for base in Game.Defs.LEVELS:
		if not Difficulty.is_touhou(base):
			continue
		stages += 1
		check(Array(base.get("conveyor_plants", [])).has("healing_gourd"), "%s lists a healing gourd on its conveyor" % base.id)
		if base.has("conveyor_plants_after_freeze"):
			check(Array(base.conveyor_plants_after_freeze).has("healing_gourd"), "%s keeps the gourd after the lake freezes" % base.id)
		for choice in Difficulty.options(base):
			var level := Difficulty.build_level(base, choice)
			if String(level.get("mode", "")) != "conveyor":
				continue
			var game := Probe.new()
			game.size = Vector2(1600, 900)
			root.add_child(game)
			game._begin_level(-1, [], level)
			check(game.conveyor_source_cards.has("healing_gourd"), "%s/%s conveyor pool hands out healing gourds" % [base.id, choice])
			game.free()
			await process_frame
	check(stages >= 30, "every Touhou stage was checked (%d)" % stages)
	# Stages added later get one even if their list forgets it.
	var game := Probe.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	var plain: Dictionary = Difficulty.build_level(Game.Defs.LEVELS.filter(func(l): return String(l.id) == "1-17")[0], "easy")
	plain.conveyor_plants = ["peashooter", "wallnut"]
	game._begin_level(-1, [], plain)
	check(game.conveyor_source_cards.has("healing_gourd") and game.conveyor_source_cards.has("mirror_reed"), "the Touhou belt adds the gourd and mirror reed when a list omits them")
	game.free()
	print("Touhou conveyor healing gourds: %d stages; %d failure(s)" % [stages, failures])
	quit(1 if failures else 0)
