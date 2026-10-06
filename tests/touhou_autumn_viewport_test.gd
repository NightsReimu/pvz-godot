extends "res://tests/touhou_autumn_density_probe.gd"

var dimensions := Vector2(52, 20)
var layout_mode := "static"
var viewport := Vector2.ZERO

class MobileEncounter extends EncounterGame:
	func _is_mobile_runtime() -> bool:
		return true

func make_game(kind: String, midboss: bool = false) -> EncounterGame:
	if layout_mode != "mobile": return super.make_game(kind, midboss)
	var game := MobileEncounter.new()
	game.size = viewport
	game.current_level = {"id": "encounter-test", "terrain": "day", "events": []}
	if midboss: game.current_level.mid_boss_kind = kind
	game.active_rows = [0, 1, 2, 3, 4]
	game.banner_label = Label.new()
	game.toast_label = Label.new()
	for row in range(6):
		var cells: Array = []
		cells.resize(9)
		game.grid.append(cells)
		game.support_grid.append(cells.duplicate())
	game.rng.seed = 907
	game.touhou_danmaku = EmptyBoardDanmaku.new(game)
	game._spawn_zombie_at(kind, 2, game._boss_anchor_x(kind), true)
	game.zombies[0].hover_shift_timer = 10000.0
	game.zombies[0].rumia_reinforcement_timer = 10000.0
	return game

func _prepare_geometry(game: Control) -> void:
	game.active_rows = [0, 1, 2, 3, 4, 5]
	game.board_rows = 6
	if layout_mode == "static":
		game.CELL_SIZE = dimensions
		game.BOARD_ORIGIN = Vector2(100, 100)
		game.board_size = dimensions * Vector2(9, 6)
	else:
		game.size = viewport
		game._refresh_battle_layout()
		dimensions = game.CELL_SIZE

func _plant_columns() -> Array:
	return [2, 3, 4]

func _run() -> void:
	var attacks := 0
	for layout in [
		{"mode": "static", "cells": Vector2(52, 20), "viewport": Vector2.ZERO},
		{"mode": "static", "cells": Vector2(76, 33), "viewport": Vector2.ZERO},
		{"mode": "static", "cells": Vector2(135, 111), "viewport": Vector2.ZERO},
		{"mode": "mobile", "cells": Vector2.ZERO, "viewport": Vector2(844, 390)},
		{"mode": "desktop", "cells": Vector2.ZERO, "viewport": Vector2(1600, 900)},
	]:
		layout_mode = layout.mode
		viewport = layout.viewport
		dimensions = layout.cells
		records = []
		for stage in ["4-19", "4-20"]:
			var base: Dictionary = {}
			for level in Game.Defs.LEVELS:
				if level.id == stage: base = level
			for choice in ["easy", "normal", "hard", "lunatic"]:
				_audit(base, choice, false)
		for r in records:
			var context := str([layout_mode, dimensions, r.stage_id, r.difficulty, r.id])
			check(float(r.warning_damage) == 0.0 and float(r.min_arming) >= 1.0, "Thin boards retain harmless declarations: " + context)
			check(int(r.drops) == 0 and int(r.peak) <= 480, "Useful pressure fits the bullet budget: " + context)
			check(int(r.swept_hits) > 0 and float(r.plant_damage) > 0.0, "Each complete attack reaches real middle-board plants before its TTL: " + context)
			if String(r.pattern) in ["aki_ripening", "aki_offering", "hina_delayed", "hina_doll_offering", "hina_misfire"]:
				check(r.hit_rows.size() >= 5, "Field accompaniment crosses the six-lane middle board: " + context)
			attacks += 1
	_test_counterplay()
	print("Autumn wide/thin viewport: %d actual casts on real cols2–4 targets; %d failure(s)" % [attacks, failures])
	quit(1 if failures else 0)

func _test_counterplay() -> void:
	layout_mode = "mobile"
	viewport = Vector2(844, 390)
	for kind in ["minoriko_boss", "hina_boss"]:
		var game := make_game(kind)
		game.current_level.touhou_difficulty = "easy"
		_prepare_geometry(game)
		var boss: Dictionary = game.zombies[0]
		boss.x = game._boss_anchor_x(kind)
		var pattern := "aki_ripening" if kind == "minoriko_boss" else "hina_delayed"
		var entry: Array = []
		for phase in Spells.phases_for(kind, game.current_level):
			for candidate in phase:
				if candidate[2] == pattern: entry = candidate
		boss.touhou_encounter.phases = [[entry]]
		boss.touhou_encounter.index = 0
		boss.touhou_encounter.attack = 0
		game.touhou_danmaku = AuditDanmaku.new(game)
		game._trigger_boss_skill(boss)
		var dm = game.touhou_danmaku
		check(not dm.bullets.is_empty() and dm.bullets[0].has("autumn_axes"), "Full mobile wind attacks own their grid-space trajectories")
		var first: Dictionary = dm.bullets[0]
		var original_position := Vector2(first.position)
		var original_age := float(first.age)
		var cast_age := float(dm.casts[0].age)
		game.boss_time_stop_timer = 1.0
		dm.update(0.4)
		check(Vector2(first.position) == original_position and float(first.age) == original_age and float(dm.casts[0].age) == cast_age, "Mobile normalized paths and volleys obey time stop")
		game.boss_time_stop_timer = 0.0
		var axes := Vector2(first.autumn_axes)
		var logical := Vector2(first.velocity) / axes
		check((dm._rotate_bullet_velocity(first, 0.3) / axes).is_equal_approx(logical.rotated(0.3)), "Curves and thaw turns rotate in grid space")
		game.grid[2][3] = game._create_plant("mirror_reed", 2, 3)
		game.grid[2][3].ultimate_charge = 1.0
		var reflected: Dictionary = first.duplicate(true)
		reflected.position = Vector2(float(boss.x) - 12, game._row_center_y(int(boss.row)) - 12)
		check(game._bounce_boss_danmaku(reflected, Vector2i(2, 3), true, false), "Mirror reflection accepts normalized mobile projectiles")
		dm.bullets.append(reflected)
		var hp := float(boss.health)
		dm.update(0.05)
		check(float(boss.health) < hp, "Reflected mobile bullets actually damage their owner")
		game.mode = Game.MODE_BATTLE
		check(game._try_activate_ultimate(2, 3) and dm.bullets.all(func(b): return bool(b.get("reflected", false))), "A real charged mirror ultimate reflects the entire denser cast")
		dm.clear_owner(int(boss.touhou_owner))
		check(dm.bullets.is_empty() and dm.casts.is_empty() and dm.beams.is_empty(), "Phase transitions clear normalized bullet state")
		_test_motion_transforms(game, dm, boss)
		dm.clear_owner(int(boss.touhou_owner))
		game._trigger_boss_skill(boss)
		boss.health = 0.0
		dm.update(0.05)
		check(dm.bullets.is_empty() and dm.casts.is_empty(), "Dead full-form owners cannot leave mobile pressure behind")
		release(game)

func _test_motion_transforms(game: Control, dm: RefCounted, boss: Dictionary) -> void:
	var session := {"owner": boss.touhou_owner, "kind": boss.kind, "wave": 0, "phase": 0, "autumn_full": true}
	var origin: Vector2 = game.BOARD_ORIGIN + game.board_size * Vector2(0.75, 0.5)
	var target: Vector2 = game.BOARD_ORIGIN + game.board_size * Vector2(0.25, 0.6)
	var scale := minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))
	dm._bullet(session, origin, PI, 100.0 * scale, Color.WHITE, "hina_ofuda", {"freeze_at": 0.0, "thaw_at": 0.3, "thaw_angle": 0.2, "redirect_at": 0.6, "aim_point": target, "arming_time": 2.0, "damage": 24.0})
	var b: Dictionary = dm.bullets.back()
	var axes := Vector2(b.autumn_axes)
	var logical := Vector2(b.velocity) / axes
	var damage := float(b.damage)
	dm.update(0.2)
	check(Vector2(b.position) == origin, "Normalized projectiles preserve their stationary freeze window")
	dm.update(0.15)
	check((Vector2(b.velocity) / axes).is_equal_approx(logical.rotated(0.2)) and bool(b.get("thawed", false)), "Thaw applies its authored turn once in normalized axes")
	dm.update(0.3)
	var new_logical := Vector2(b.velocity) / axes
	var aim := (target - Vector2(b.position)) / axes
	check(bool(b.get("redirected", false)) and new_logical.normalized().dot(aim.normalized()) > 0.9999 and is_equal_approx(new_logical.length(), logical.length()), "Redirect aims at its real point while preserving grid-space speed")
	check(float(b.life) == 7.0 and float(b.arming_time) == 2.0 and float(b.damage) == damage, "Viewport transforms preserve TTL, warning and individual damage")
