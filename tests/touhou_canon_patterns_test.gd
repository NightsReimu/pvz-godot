extends SceneTree
# The reworked TH06/TH07/TH08 cards: per-difficulty card lists from THBWiki,
# and the bullet structure that identifies each original card.

const Game = preload("res://scripts/game.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
const Phase = preload("res://scripts/runtime/touhou_phase_runtime.gd")
const Eosd = preload("res://scripts/runtime/eosd_danmaku.gd")
const Pcb = preload("res://scripts/runtime/pcb_danmaku.gd")
const Night = preload("res://scripts/runtime/imperishable_road_danmaku.gd")
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

func level(id: String, tier: String) -> Dictionary:
	for entry in Game.Defs.LEVELS:
		if String(entry.id) == id:
			return Game.TouhouDifficulty.build_level(entry, tier)
	return {}

func ids(kind: String, lv: Dictionary) -> Array:
	var result: Array = []
	for phase in Spells.phases_for(kind, lv):
		for entry in phase:
			if not String(entry[0]).begins_with("original-") and not String(entry[0]).begins_with("adapted-"):
				result.append(String(entry[0]))
	return result

func entry_for(kind: String, lv: Dictionary, pattern: String) -> Array:
	for phase in Spells.phases_for(kind, lv):
		for entry in phase:
			if String(entry[2]) == pattern:
				return entry
	return []

func cast(kind: String, lv: Dictionary, entry: Array) -> Probe:
	var g := Probe.new()
	g.size = Vector2(1600, 900)
	root.add_child(g)
	g._begin_level(-1, [], lv)
	g.battle_intro_timer = 0
	for row in range(6):
		if not g._is_row_active(row): continue
		for col in range(6):
			var p: Dictionary = g._create_plant("wallnut" if col == 4 else "repeater", row, col)
			p.health = 100000.0; p.max_health = 100000.0
			g.grid[row][col] = p
	g._spawn_zombie_at(kind, 2, g._boss_anchor_x(kind), true)
	var b: Dictionary = g.zombies.back()
	var e: Dictionary = b.touhou_encounter
	e.phases = [[entry]]; e.index = 0; e.attack = 0; e.completed = 0
	Phase._set_bounds(b)
	b.health = e.ceiling
	g._trigger_boss_skill(b)
	return g

func done(g: Probe) -> void:
	g.boss_time_stop_timer = 0.0
	g.touhou_danmaku.clear()
	g.free()

func _run() -> void:
	_test_routes()
	_test_every_card_emits()
	_test_scarlet_mechanics()
	_test_cherry_and_night_mechanics()
	print("Touhou canon patterns: %d failure(s)" % failures)
	quit(1 if failures else 0)

func _test_routes() -> void:
	check(ids("cirno_boss", level("1-18", "normal")).has("th06-04") and ids("cirno_boss", level("1-18", "hard")).has("th06-05"), "Cirno uses Icicle Fall on E/N and Hailstorm on H/L")
	var meiling := ids("meiling_boss", level("1-19", "lunatic"))
	check(meiling.has("th06-09") and meiling.has("th06-11") and meiling.has("th06-13") and not meiling.has("th06-08"), "Hard/Lunatic Meiling: Selaginella 9, Kasou Mukatsu and Saikou Ranbu")
	check(not ids("meiling_boss", level("1-19", "normal")).has("th06-11"), "Kasou Mukatsu exists only on Hard/Lunatic")
	check(ids("patchouli_boss", level("1-20", "hard")) == ["th06-20", "th06-26", "th06-28", "th06-31", "th06-29"], "Hard Patchouli follows the Reimu A Hard route (Agni Shine upper grade ... Forest Blaze)")
	check(ids("sakuya_boss", level("1-21", "lunatic")) == ["th06-34", "th06-38", "th06-39", "th06-40"], "Lunatic Sakuya uses her Hard/Lunatic cards")
	check(ids("rumia_boss", level("1-17", "hard"))[0] == "th06-01" and not ids("rumia_boss", level("1-17", "normal")).has("th06-01"), "Moonlight Ray is a Hard/Lunatic card")
	check(ids("letty_boss", level("2-25", "easy")) == ["th07-003", "th07-007"] and ids("letty_boss", level("2-25", "lunatic")) == ["th07-006", "th07-010"], "Letty's per-difficulty numbers")
	check(entry_for("letty_boss", level("2-25", "hard"), "undulation_ray").size() > 0 and entry_for("letty_boss", level("2-25", "lunatic"), "table_turning").size() > 0, "Undulation Ray on Hard, Table Turning on Lunatic")
	check(ids("chen_boss", level("2-26", "lunatic")) == ["th07-014", "th07-018", "th07-022", "th07-026"], "Lunatic Chen")
	check(ids("alice_boss", level("2-27", "lunatic")) == ["th07-032", "th07-036", "th07-040", "th07-044"], "Lunatic Alice")
	check(ids("youmu_boss", level("2-29", "hard")) == ["th07-071", "th07-075", "th07-079", "th07-083", "th07-087"], "Hard Youmu")
	check(ids("youmu_boss", level("2-30", "lunatic")) == ["th07-092"], "Stage 6 Youmu's Immeasurable Aeons uses its Lunatic number")
	check(ids("yuyuko_boss", level("2-30", "easy"))[0] == "th07-093", "Easy Yuyuko uses her Easy cards")
	var stygian := entry_for("prismriver_boss", level("2-28", "hard"), "stygian_riverside")
	check(stygian.size() > 0 and String(stygian[0]) == "th07-063" and String(stygian[1]).contains("Stygian Riverside"), "Hard Prismriver ends on Stygian Riverside")
	check(ids("wriggle_boss", level("3-19", "easy")) == ["th08-003", "th08-007"] and ids("wriggle_boss", level("3-19", "lunatic")) == ["th08-002", "th08-006", "th08-010", "th08-013"], "Wriggle's per-difficulty route")
	check(ids("mystia_boss", level("3-20", "normal")) == ["th08-015", "th08-019", "th08-023", "th08-027", "th08-030"], "Normal Mystia's route")
	check(ids("keine_boss", level("3-21", "easy"))[0] == "th08-033" and ids("keine_boss", level("3-21", "hard")).has("th08-042"), "Keine's Easy First Pyramid and Hard Yoshimitsu Crisis")
	var kana := RegEx.new()
	kana.compile("[\\x{3041}-\\x{30ff}]")
	for kind in ["wriggle_boss", "mystia_boss", "keine_boss", "prismriver_boss", "youmu_boss", "alice_boss"]:
		for tier in ["easy", "normal", "hard", "lunatic"]:
			var id: String = {"wriggle_boss": "3-19", "mystia_boss": "3-20", "keine_boss": "3-21", "prismriver_boss": "2-28", "youmu_boss": "2-29", "alice_boss": "2-27"}[kind]
			for phase in Spells.phases_for(kind, level(id, tier)):
				for entry in phase:
					check(kana.search(String(entry[1])) == null, "%s card names are translated: %s" % [kind, entry[1]])

const CONFIGS := [["1-17", "rumia_boss"], ["1-18", "daiyousei_boss"], ["1-18", "cirno_boss"], ["1-19", "meiling_boss"], ["1-20", "koakuma_boss"], ["1-20", "patchouli_boss"], ["1-21", "sakuya_boss"], ["1-22", "sakuya_boss"], ["1-22", "remilia_boss"], ["2-25", "cirno_boss"], ["2-25", "letty_boss"], ["2-26", "chen_boss"], ["2-27", "alice_boss"], ["2-28", "lily_white_boss"], ["2-29", "youmu_boss"], ["2-30", "yuyuko_boss"], ["3-19", "wriggle_boss"], ["3-20", "mystia_boss"], ["3-21", "keine_boss"]]

func _test_every_card_emits() -> void:
	var seen := {}
	var configs: Array = []
	for config in CONFIGS:
		for tier in ["easy", "lunatic"]:
			configs.append([config[0], config[1], tier])
	for extra in [["1-23", "flandre_boss"], ["1-23", "patchouli_boss"], ["2-31", "ran_boss"], ["2-31", "yukari_boss"], ["2-31", "chen_boss"]]:
		configs.append([extra[0], extra[1], "extra_plus"])
	for config in configs:
		var lv := level(config[0], config[2])
		for phase in Spells.phases_for(config[1], lv):
			for entry in phase:
				var pattern := String(entry[2])
				if not (Eosd.owns(pattern) or Pcb.owns(pattern) or Night.owns(pattern)) or seen.has(pattern + config[2]): continue
				seen[pattern + config[2]] = true
				var g := cast(config[1], lv, entry)
				var dm = g.touhou_danmaku
				check(bool(dm.casts[0].get("own_clock", false)), "%s runs on its authored clock" % pattern)
				check(not dm.bullets.is_empty() or not dm.beams.is_empty() or g.zombies.size() > 1, "%s/%s emits on declaration" % [pattern, config[2]])
				var peak := 0
				for i in range(70):
					dm.update(0.05)
					peak = maxi(peak, dm.bullets.size())
				check(peak <= dm.MAX_BULLETS and dm.beams.size() <= dm.MAX_BEAMS, "%s keeps to the bullet budget" % pattern)
				check(dm.bullets.all(func(b): return b.has("cm") or String(b.shape) in ["rice"]), "%s bullets use the shared canon motion" % pattern)
				done(g)
	check(seen.size() >= 100, "every reworked card was exercised (%d)" % seen.size())

func _bullets(g: Probe) -> Array:
	return g.touhou_danmaku.bullets

func _test_scarlet_mechanics() -> void:
	# Perfect Freeze: the scattered field turns white while held.
	var lv := level("1-18", "normal")
	var g := cast("cirno_boss", lv, entry_for("cirno_boss", lv, "perfect_freeze"))
	g.touhou_danmaku.update(0.8)
	var held: Array = _bullets(g).filter(func(b): return bool(b.get("frozen", false)))
	check(held.size() >= 10 and held.all(func(b): return bool(b.get("whiten", false))), "Perfect Freeze holds and whitens its scatter")
	done(g)
	# Icicle Fall: icicles climb to the edges, then fall towards the plants.
	g = cast("cirno_boss", lv, entry_for("cirno_boss", lv, "icicle"))
	var first: Dictionary = _bullets(g)[0]
	check(absf(Vector2(first.velocity).y) > absf(Vector2(first.velocity).x) * 2.0, "Icicles first climb towards the lawn edges")
	g.touhou_danmaku.update(0.7)
	check(Vector2(first.velocity).x < -abs(Vector2(first.velocity).y), "then fall towards the plants")
	done(g)
	# Star of David: six laser sides of a hexagram.
	lv = level("1-22", "normal")
	g = cast("remilia_boss", lv, entry_for("remilia_boss", lv, "david"))
	check(g.touhou_danmaku.beams.size() == 6, "Star of David draws a hexagram of six lasers")
	done(g)
	# Red Magic: great bullets shed smaller ones along their paths.
	g = cast("remilia_boss", lv, entry_for("remilia_boss", lv, "red_magic"))
	var before := _bullets(g).size()
	g.touhou_danmaku.update(0.6)
	check(_bullets(g).size() > before and _bullets(g).any(func(b): return float(b.radius) >= 10.0), "Red Magic's great bullets leave trails")
	done(g)
	# Clock Corpse stops time only after its scatter.
	lv = level("1-21", "normal")
	g = cast("sakuya_boss", lv, entry_for("sakuya_boss", lv, "clock_corpse"))
	check(g.boss_time_stop_timer <= 0.0, "Clock Corpse begins with a scatter, not a stopped world")
	g.touhou_danmaku.update(1.0)
	check(g.boss_time_stop_timer > 0.0, "then time stops while knives are laid")
	done(g)
	# Misdirection: the kunai ring doubles back at the plants.
	g = cast("sakuya_boss", lv, entry_for("sakuya_boss", lv, "misdirection"))
	var kunai: Dictionary = _bullets(g).filter(func(b): return Vector2(b.velocity).x > 20.0)[0]
	g.touhou_danmaku.update(0.7)
	check(Vector2(kunai.velocity).x < 0.0, "Misdirection's outward kunai turn back on the target")
	done(g)
	# Flandre: Laevatein sweeps only once it fires; the clock's hands turn;
	# Kagome closes a harmless lattice before it moves; Starbow rains down.
	lv = level("1-23", "extra")
	g = cast("flandre_boss", lv, entry_for("flandre_boss", lv, "laevatein"))
	var beam: Dictionary = g.touhou_danmaku.beams[0]
	var start := (Vector2(beam.to) - Vector2(beam.from)).angle()
	g.touhou_danmaku.update(0.6)
	check(is_equal_approx((Vector2(beam.to) - Vector2(beam.from)).angle(), start), "Laevatein's warning shows the sweep's start")
	g.touhou_danmaku.update(0.8)
	check(absf(angle_difference((Vector2(beam.to) - Vector2(beam.from)).angle(), start)) > 0.4, "then the blade sweeps across the lawn")
	done(g)
	g = cast("flandre_boss", lv, entry_for("flandre_boss", lv, "past_clock"))
	check(g.touhou_danmaku.beams.size() == 2 and g.touhou_danmaku.beams.all(func(b): return b.has("pivot")), "the past clock has two laser hands on one pivot")
	done(g)
	g = cast("flandre_boss", lv, entry_for("flandre_boss", lv, "kagome"))
	var cage: Array = _bullets(g).filter(func(b): return Vector2(b.velocity).length() < 1.0)
	check(cage.size() >= 40, "Kagome Kagome lays a lattice (%d)" % cage.size())
	done(g)
	g = cast("flandre_boss", lv, entry_for("flandre_boss", lv, "starbow"))
	var star: Dictionary = _bullets(g)[0]
	var vx := Vector2(star.velocity).x
	g.touhou_danmaku.update(1.5)
	check(Vector2(star.velocity).x < vx - 30.0, "Starbow Break's bullets fall back across the lawn")
	done(g)
	# Rings fired from the far edge skip only the bullets that would leave at once.
	lv = level("1-20", "normal")
	g = cast("patchouli_boss", lv, entry_for("patchouli_boss", lv, "cromlech"))
	check(_bullets(g).filter(func(b): return String(b.shape) == "fire").all(func(b): return cos(Vector2(b.velocity).angle()) <= 0.46), "edge rings drop only their outward bullets")
	done(g)

func _test_cherry_and_night_mechanics() -> void:
	var lv := level("2-30", "normal")
	var g := cast("yuyuko_boss", lv, entry_for("yuyuko_boss", lv, "swallowtail"))
	var speeds := {}
	for b in _bullets(g):
		speeds[snappedf(Vector2(b.velocity).length(), 5.0)] = true
	check(speeds.size() >= 8, "Swallowtail's volley spreads into a butterfly outline")
	done(g)
	lv = level("2-25", "lunatic")
	g = cast("letty_boss", lv, entry_for("letty_boss", lv, "table_turning"))
	var ring: Dictionary = _bullets(g)[0]
	var spin := float(ring.get("angular_speed", 0.0))
	g.touhou_danmaku.update(1.2)
	check(spin != 0.0 and signf(float(ring.get("angular_speed", 0.0))) == -signf(spin), "Table Turning reverses its rings")
	done(g)
	lv = level("3-19", "normal")
	g = cast("wriggle_boss", lv, entry_for("wriggle_boss", lv, "wriggle_final"))
	var dormant: Array = _bullets(g).filter(func(b): return float(b.arming_time) > 1.0)
	check(not dormant.is_empty() and dormant.all(func(b): return Vector2(b.velocity).length() < 1.0), "hibernating fireflies settle harmlessly")
	g.touhou_danmaku.update(2.4)
	check(dormant.any(func(b): return Vector2(b.velocity).length() > 30.0), "and later wake to swarm the plants")
	done(g)
	lv = level("3-20", "hard")
	g = cast("mystia_boss", lv, entry_for("mystia_boss", lv, "mystia_dive"))
	var first := Vector2(g.touhou_danmaku.casts[0].dive)
	g.touhou_danmaku.update(0.5)
	check(Vector2(g.touhou_danmaku.casts[0].dive).distance_to(first) > 40.0, "Ill-Starred Dive swoops across the lawn")
	done(g)
