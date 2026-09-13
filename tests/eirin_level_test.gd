extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var stage: Dictionary = {}
	for level in Defs.LEVELS:
		if level.id == "3-24-a":
			stage = level
	check(not stage.is_empty(), "3-24-a must exist after 3-23")
	if stage.is_empty():
		quit(1)
		return
	check(stage.row_count == 6 and stage.water_rows.is_empty(), "Eirin starts with six solid corridor lanes")
	check(stage.unlock_requirements == ["3-23"] and stage.mid_boss_kind == "eirin_boss" and stage.mid_boss_final_preview, "Eirin is her own low-health road encounter")
	check(stage.events.back().kind == "eirin_boss", "Final event is Eirin")
	for event in stage.events:
		check(Defs.ZOMBIES.has(event.kind), "Event enemy must exist: " + event.kind)
	check(Difficulty.options(stage).size() == 4, "Stage has four Touhou difficulties")
	for path in [stage.boss_intro_bgm, stage.boss_bgm]:
		check(FileAccess.file_exists(path), "Supplied stage and boss audio must exist: " + path)
	for kind in stage.conveyor_plants:
		check(Defs.PLANTS.has(kind) and not Defs.PLANTS[kind].has("sun_interval"), "Conveyor kinds must exist and avoid sun generators: " + kind)
	for kind in ["healing_gourd", "lily_pad", "flower_pot", "cork_plug"]:
		check(stage.available_plants.has(kind), "Healing and terrain tools must be available: " + kind)
	for rank in range(4):
		var choice: String = ["easy", "normal", "hard", "lunatic"][rank]
		var level := Difficulty.build_level(stage, choice)
		var phases := Spells.phases_for("eirin_boss", level)
		check(phases.size() == 6 + rank, "Six canonical phases plus rank-specific originals")
		var cards := Spells.cards_for("eirin_boss", level)
		check(cards.size() == 6 and cards[0][0] == "th08-%d" % (124 + rank) and cards.back()[0] == "th08-%d" % (144 + rank), "6A canon IDs and finale order")
		check((level.mode == "normal") == (rank == 3), "Lunatic uses seed selection")
	for kind in ["eirin_boss", "star_fairy", "kedama", "mini_kedama", "rabbit_airship"]:
		check(Defs.ZOMBIES.has(kind), "New enemy definition: " + kind)
	for frame in range(24):
		var texture: Texture2D = load("res://art/eirin/frame_%02d.png" % frame)
		var image: Image = texture.get_image() if texture != null else null
		check(image != null and image.get_size() == Vector2i(256, 256), "Original Eirin frames retain a shared 256px canvas")
		if image != null:
			check(image.get_pixel(0, 0).a == 0 and image.get_pixel(255, 255).a == 0 and image.get_used_rect().size.x > 70, "Frames have transparent backgrounds and retain the character")
	print("Eirin stage, sources, routes and four difficulties: %d failure(s)" % failures)
	quit(1 if failures else 0)
