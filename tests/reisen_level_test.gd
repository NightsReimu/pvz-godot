extends SceneTree

const Defs = preload("res://scripts/game_defs.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
var failures := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		push_error(msg)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := {}
	for level in Defs.LEVELS:
		if String(level.get("id", "")) == "3-23":
			stage = level
	check(not stage.is_empty(), "3-23 must exist")
	if stage.is_empty():
		quit(1)
		return
	check(int(stage.get("row_count", 0)) == 6, "3-23 must use six rows")
	check(Array(stage.get("water_rows", [])).is_empty(), "3-23 must be pure grass")
	check(String(stage.get("terrain", "")) == "infinite_moon_corridor", "3-23 must use the infinite moon corridor")
	check(String(stage.get("mid_boss_kind", "")) == "tewi_boss" and bool(stage.get("mid_boss_nonspell_only", false)) and not bool(stage.get("mid_boss_final_preview", false)), "Tewi is a distinct nonspell road boss, not a Reisen preview")
	check(String(stage.get("boss_bgm", "")) == "res://audio/th08_reisen_boss.mp3", "3-23 must use Reisen finale music")
	check(String(stage.get("boss_intro_bgm", "")) == "res://audio/th08_tewi_stage.mp3", "3-23 must use Tewi stage music")
	check(stage.get("available_plants", []).has("healing_gourd") and stage.get("conveyor_plants", []).has("healing_gourd"), "Healing gourd must be mandatory")
	check(String(stage.events.back().get("kind", "")) == "reisen_boss", "Reisen must be the final event")
	var boss_count := 0
	for event in stage.events:
		if bool(Defs.ZOMBIES.get(String(event.get("kind", "")), {}).get("boss", false)):
			boss_count += 1
			check(String(event.get("kind", "")) == "reisen_boss", "Only Reisen may be the final event boss")
	check(boss_count == 1, "3-23 must schedule exactly one final boss event")
	check(Difficulty.options(stage) == ["easy", "normal", "hard", "lunatic"], "3-23 must expose four difficulties")
	var expected_ids := {"easy": [101, 105, 109, 113], "normal": [102, 106, 110, 114, 117], "hard": [103, 107, 111, 115, 118], "lunatic": [104, 108, 112, 116, 119]}
	var expected_phases := {"easy": 4, "normal": 6, "hard": 7, "lunatic": 8}
	for choice in ["easy", "normal", "hard", "lunatic"]:
		var level := Difficulty.build_level(stage, choice)
		check(Spells.cards_for("reisen_boss", level).map(func(c): return int(String(c[0]).trim_prefix("th08-"))) == expected_ids[choice], "Spell IDs must exactly match the original difficulty route")
		check(Spells.phase_count("reisen_boss", level) == expected_phases[choice], "Difficulty adds cumulative original phases")
		check((String(level.mode) == "normal") == (choice == "lunatic"), "Only Lunatic requires chosen plants")
		check(level.events.size() == stage.events.size() + int(Difficulty.PROFILES[choice].waves), "Higher difficulties add waves")
		check(Spells.cards_for("reisen_boss", level).size() >= 4, "%s must retain Reisen canonical cards" % choice)
		check(Spells.phases_for("reisen_boss", level).size() >= Spells.cards_for("reisen_boss", level).size(), "%s phases must be populated" % choice)
	check(Spells.cards_for("tewi_boss", stage).size() >= 1, "Tewi must have an opening nonspell")
	for kind in ["tewi_boss", "reisen_boss"]:
		check(Defs.ZOMBIES.has(kind), "%s must be registered" % kind)
	for folder in ["res://art/tewi", "res://art/reisen"]:
		for i in range(24):
			var path := "%s/frame_%02d.png" % [folder, i]
			check(FileAccess.file_exists(path), "Missing %s" % path)
			var texture = load(path)
			check(texture is Texture2D and texture.get_size() == Vector2(256, 256), "All atlas frames must load at original cell size")
	print("3-23 Reisen/Tewi level contract: %d failure(s)" % failures)
	quit(1 if failures else 0)
