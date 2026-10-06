extends RefCounted

# Original full-form spells. Each pair changes formation as well as its
# character-specific motion; none grants invulnerability or suppresses plants.
const RED := Color("ed7388")
const BLUE := Color("88d6ef")
const GOLD := Color("f1cf80")
const GREEN := Color("a4df9f")
const PURPLE := Color("c99deb")

static func _lane(dm: RefCounted, row: int, x: float = 0.89) -> Vector2:
	return Vector2(dm._point(x, 0.5).x, dm.game._row_center_y(row) - 12.0)

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var g: Control = dm.game
	if g.active_rows.is_empty(): return
	var move := int(c.card.finale_move)
	var wave := int(c.wave)
	var kind := String(c.kind)
	var scale := minf(1.0, minf(g.CELL_SIZE.x / 100.0, g.CELL_SIZE.y / 110.0))
	var origin := Vector2(c.center)
	var target: Vector2 = dm._target(origin)
	var aim := (target - origin).angle()
	var row := int(g.active_rows[posmod(wave, g.active_rows.size())])
	var other := int(g.active_rows[posmod(wave + 2, g.active_rows.size())])
	var common := {"arming_time": 1.15, "radius": 4.5 * scale, "damage": 28.0, "life": 6.0}
	var cadence := 1.55
	match kind:
		"rumia_boss":
			if move == 0:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(0, side * 38 * scale), 7, PI + side * 0.32, 0.95, 116 * scale, PURPLE, "orb", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.15, "angular_speed": side * 0.16}))
			elif move == 1:
				dm._ring(c, _lane(dm, row, 0.72), 14, wave * 0.3, 105 * scale, PURPLE, "orb", _extra(common, {"angular_speed": -0.20}))
				dm._beam(c, _lane(dm, other), _lane(dm, other, 0.18), GOLD, 1.25, 7 * scale, {"damage": 48.0, "duration": 0.35})
			else:
				for i in range(6):
					if i == wave % 6: continue
					var angle := TAU * i / 6 + wave * 0.2
					dm._fan(c, origin, 3, angle, 0.23, 114 * scale, PURPLE if i % 2 else GOLD, "orb", common)
		"daiyousei_boss":
			if move == 0:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-28, side * 45) * scale, 7, PI + side * 0.3, 1.20, 121 * scale, GREEN, "rice", _extra(common, {"angular_speed": side * 0.22}))
			elif move == 1:
				for lane in [row, other]: dm._ring(c, _lane(dm, lane, 0.73), 10, wave * 0.2, 99 * scale, GREEN, "rice", _extra(common, {"freeze_at": 0.1, "thaw_at": 1.2}))
			else:
				for i in range(g.active_rows.size()):
					if i == wave % g.active_rows.size(): continue
					dm._fan(c, _lane(dm, int(g.active_rows[i])), 3, PI, 0.30, (110 + i * 7) * scale, GREEN, "rice", common)
		"cirno_boss":
			if move == 0:
				for i in range(g.active_rows.size()):
					if i == wave % g.active_rows.size(): continue
					dm._fan(c, _lane(dm, int(g.active_rows[i])), 3, PI, 0.30, 128 * scale, BLUE, "ice", _extra(common, {"freeze_at": 0.15, "thaw_at": 1.2, "thaw_angle": (i % 2 * 2 - 1) * 0.10}))
			else:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-35, side * 48) * scale, 9, PI + side * 0.35, 1.2, 116 * scale, BLUE if side < 0 else PURPLE, "ice", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.15 if side < 0 else 1.5, "thaw_angle": -side * 0.35}))
		"meiling_boss":
			if move == 0:
				for layer in range(3): dm._fan(c, origin, 5, PI + (layer - 1) * 0.34, 0.76, (118 + layer * 22) * scale, [RED, GOLD, GREEN][layer], "rice", _extra(common, {"angular_speed": (layer - 1) * 0.13}))
			else:
				for arm in range(6): dm._fan(c, origin + Vector2.from_angle(arm * TAU / 6) * 35 * scale, 3, arm * TAU / 6 + wave * 0.22, 0.24, 128 * scale, dm.COLORS[arm], "rice", common)
		"koakuma_boss":
			if move == 0:
				for layer in range(3): dm._fan(c, origin + Vector2(-layer * 18, (layer - 1) * 42) * scale, 5, PI + sin(wave + layer) * 0.20, 0.78, (113 + layer * 18) * scale, PURPLE, "ofuda", _extra(common, {"angular_speed": (layer - 1) * 0.19}))
			elif move == 1:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane, 0.72), 7, PI + 0.40, 1.05, 117 * scale, RED, "ofuda", _extra(common, {"redirect_at": 1.25, "aim_point": target}))
			else:
				dm._fan(c, _lane(dm, row), 9, PI, 1.1, 123 * scale, PURPLE, "ofuda", common)
				dm._beam(c, _lane(dm, other), _lane(dm, other, 0.15), RED, 1.35, 7 * scale, {"damage": 46.0, "duration": 0.40})
		"patchouli_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI, 0.85, 125 * scale, RED if lane == row else BLUE, "orb" if lane == row else "ice", _extra(common, {"angular_speed": 0.15 if lane == row else -0.15}))
			else:
				for i in range(3): dm._fan(c, origin + Vector2(-30 * i, (i - 1) * 40) * scale, 5, PI, 0.80, (100 + i * 16) * scale, GOLD if i % 2 else GREEN, "suika_stone", common)
				dm._beam(c, _lane(dm, row), _lane(dm, other, 0.22), GOLD, 1.3, 8 * scale, {"damage": 48.0, "duration": 0.35})
		"sakuya_boss":
			if move == 0:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-20, side * 46) * scale, 7, aim + side * 0.26, 1.0, 162 * scale, BLUE, "knife", _extra(common, {"freeze_at": 0.15, "thaw_at": 1.2 + (0.25 if side > 0 else 0.0)}))
			else:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane, 0.78), 9, PI + 0.30, 1.10, 153 * scale, BLUE if lane == row else PURPLE, "knife", _extra(common, {"redirect_at": 1.25, "aim_point": _lane(dm, lane, 0.30)}))
		"remilia_boss":
			if move == 0:
				for lane in [row, other]:
					dm._fan(c, _lane(dm, lane), 7, PI + 0.18, 0.9, 143 * scale, RED, "rice", common)
					dm._beam(c, _lane(dm, lane), _lane(dm, lane, 0.15), RED, 1.3, 8 * scale, {"damage": 49.0, "duration": 0.36})
			else: dm._fan(c, origin, 17, PI, 1.95, 138 * scale, RED, "rice", _extra(common, {"angular_speed": -0.18, "redirect_at": 1.5, "aim_point": target}))
		"flandre_boss":
			if move == 0:
				for side in [-1, 1]: dm._fan(c, dm._point(0.75, 0.14 if side < 0 else 0.86), 7, PI + side * 0.32, 1.0, 136 * scale, RED if side < 0 else PURPLE, "star", _extra(common, {"angular_speed": -side * 0.18}))
			else: dm._fan(c, origin, 13, PI, 1.80, 146 * scale, PURPLE, "star", _extra(common, {"bounces": 2, "radius": 5.5 * scale}))
		"letty_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI + 0.12, 0.95, 101 * scale, BLUE, "ice", _extra(common, {"angular_speed": -0.13}))
			elif move == 1:
				dm._ring(c, dm._point(0.74, 0.5), 18, wave * 0.20, 94 * scale, BLUE, "ice", _extra(common, {"redirect_at": 1.35, "aim_point": target}))
			else:
				for i in range(5): dm._fan(c, dm._point(0.20 + i * 0.14, 0.02), 3, PI / 2 + sin(i + wave) * 0.18, 0.35, 96 * scale, BLUE, "ice", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2 + i * 0.10}))
		"chen_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI + (0.32 if lane == row else -0.32), 0.95, 146 * scale, GOLD, "ofuda", _extra(common, {"bounces": 1}))
			else: dm._fan(c, dm._point(0.70, 0.20 if wave % 2 else 0.80), 13, PI + sin(wave) * 0.35, 1.65, 132 * scale, GOLD, "ofuda", _extra(common, {"redirect_at": 1.25, "aim_point": target}))
		"alice_boss":
			if move == 0:
				for i in range(5):
					var point: Vector2 = c.actors[i].position if i < c.actors.size() else dm._point(0.80, 0.10 + i * 0.20)
					dm._fan(c, point, 3, PI + sin(wave + i) * 0.18, 0.36, (109 + i * 8) * scale, RED if i % 2 else BLUE, "rice", common)
			else:
				for side in [-1, 1]:
					var actor_index := 0 if side < 0 else 4
					var point: Vector2 = c.actors[actor_index].position if actor_index < c.actors.size() else dm._point(0.72, 0.10 if side < 0 else 0.90)
					dm._fan(c, point, 7, (target - point).angle(), 1.1, 127 * scale, RED, "rice", common)
					dm._beam(c, point, dm._point(0.20, 0.80 if side < 0 else 0.20), BLUE, 1.35, 7 * scale, {"damage": 46.0, "duration": 0.35, "actor_index": actor_index})
		"lily_white_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI + 0.12, 1.0, 112 * scale, RED, "rice", _extra(common, {"angular_speed": 0.14}))
			elif move == 1:
				for side in [-1, 1]: dm._ring(c, origin + Vector2(-30, side * 45) * scale, 10, wave * 0.22 * side, 94 * scale, RED if side < 0 else GOLD, "rice", _extra(common, {"angular_speed": -side * 0.18}))
			else:
				for i in range(g.active_rows.size()):
					if i == wave % g.active_rows.size(): continue
					dm._fan(c, _lane(dm, int(g.active_rows[i])), 3, PI + sin(wave + i) * 0.10, 0.32, 116 * scale, RED, "rice", common)
		"prismriver_boss":
			var bodies: Array = c.get("instrument_points", [])
			if move == 0:
				for voice in range(3):
					var point: Vector2 = bodies[voice] if voice < bodies.size() else dm._point(0.82, 0.17 + voice * 0.33)
					dm._fan(c, point, 5, PI + (voice - 1) * 0.18, 1.0, (107 + voice * 19) * scale, [RED, BLUE, GOLD][voice], "note", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.15 + voice * 0.17}))
			else:
				for voice in range(3):
					var point: Vector2 = bodies[voice] if voice < bodies.size() else dm._point(0.79, 0.17 + voice * 0.33)
					dm._fan(c, point, 7, PI + sin(wave + voice) * 0.24, 1.1, 121 * scale, [RED, BLUE, GOLD][voice], "note", _extra(common, {"angular_speed": (voice - 1) * 0.23}))
		"youmu_boss":
			if move == 0:
				dm._fan(c, origin, 13, aim, 1.80, 117 * scale, GREEN, "rice", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2}))
				dm._beam(c, _lane(dm, row), _lane(dm, other, 0.20), BLUE, 1.35, 8 * scale, {"damage": 48.0, "duration": 0.35})
			else:
				for lane in [row, other]:
					dm._fan(c, _lane(dm, lane), 5, PI, 0.80, 146 * scale, GREEN, "rice", common)
					dm._beam(c, _lane(dm, lane), _lane(dm, lane, 0.15), BLUE, 1.3, 7 * scale, {"damage": 46.0, "duration": 0.35})
		"yuyuko_boss":
			if move == 0:
				for side in [-1, 1]: dm._ring(c, origin + Vector2(-40, side * 42) * scale, 12, wave * 0.25, 91 * scale, RED if side < 0 else PURPLE, "butterfly", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2 + (0.2 if side > 0 else 0.0), "angular_speed": side * 0.18}))
			else: dm._fan(c, origin, 17, PI, 1.9, 110 * scale, PURPLE, "butterfly", _extra(common, {"redirect_at": 1.35, "aim_point": target, "angular_speed": -0.12}))
		"ran_boss":
			if move == 0:
				for tail in range(9): dm._fan(c, origin, 3, tail * TAU / 9 + wave * 0.18, 0.14, 122 * scale, GOLD, "ofuda", _extra(common, {"angular_speed": 0.14}))
			else:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-30, side * 50) * scale, 9, PI + side * 0.38, 1.15, 135 * scale, GOLD if side < 0 else PURPLE, "ofuda", _extra(common, {"bounces": 2}))
		"yukari_boss":
			if move == 0:
				for side in [-1, 1]: dm._fan(c, dm._point(0.70, 0.10 if side < 0 else 0.90), 9, PI + side * 0.35, 1.2, 128 * scale, PURPLE, "ofuda", _extra(common, {"redirect_at": 1.2, "aim_point": target}))
			else:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane, 0.74), 7, PI + 0.45, 1.0, 121 * scale, PURPLE if lane == row else RED, "ofuda", _extra(common, {"bounces": 1, "angular_speed": -0.20}))
		"wriggle_boss":
			if move == 0:
				for lane in [row, other]: dm._ring(c, _lane(dm, lane, 0.76), 10, wave * 0.22, 93 * scale, GREEN, "orb", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2, "angular_speed": 0.22}))
			else:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-40, side * 47) * scale, 9, PI + side * 0.32, 1.10, 112 * scale, GREEN, "orb", _extra(common, {"angular_speed": -side * 0.28}))
		"mystia_boss":
			if move == 0:
				for i in range(g.active_rows.size()):
					if i == wave % g.active_rows.size(): continue
					dm._fan(c, _lane(dm, int(g.active_rows[i])), 3, PI, 0.36, (109 + i * 8) * scale, RED, "note", common)
			else:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-25, side * 50) * scale, 9, PI + side * 0.28, 1.1, 120 * scale, PURPLE if side < 0 else RED, "note", _extra(common, {"redirect_at": 1.4, "aim_point": target}))
		"keine_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI, 1.0, 119 * scale, BLUE if lane == row else RED, "ofuda", _extra(common, {"freeze_at": 0.1, "thaw_at": 1.2 if lane == row else 1.5}))
			else: dm._fan(c, origin, 17, PI, 1.9, 123 * scale, BLUE, "ofuda", _extra(common, {"redirect_at": 1.3, "aim_point": target}))
		"hakutaku_boss":
			if move == 0:
				for arm in range(4): dm._fan(c, origin + Vector2.from_angle(arm * PI / 2) * 35 * scale, 5, arm * PI / 2 + wave * 0.15, 0.40, 118 * scale, GREEN, "ofuda", common)
			else:
				for side in [-1, 1]: dm._fan(c, dm._point(0.74, 0.18 if side < 0 else 0.82), 9, PI + side * 0.32, 1.2, 128 * scale, GREEN if side < 0 else RED, "rice", _extra(common, {"angular_speed": -side * 0.20}))
		"mokou_boss":
			if move == 0:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-35, side * 48) * scale, 9, PI + side * 0.35, 1.05, 127 * scale, RED if side < 0 else GOLD, "rice", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2 if side < 0 else 1.5}))
			else:
				for side in [-1, 1]: dm._ring(c, origin + Vector2(-45, side * 40) * scale, 12, wave * 0.27 * side, 104 * scale, RED if side < 0 else GOLD, "rice", _extra(common, {"angular_speed": -side * 0.25}))
		"reimu_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 9, PI + 0.12, 1.05, 119 * scale, RED if lane == row else BLUE, "ofuda", _extra(common, {"redirect_at": 1.25, "aim_point": target}))
			else:
				for side in [-1, 1]: dm._ring(c, origin + Vector2(-40, side * 45) * scale, 12, wave * 0.20 * side, 104 * scale, RED if side < 0 else BLUE, "dream_orb", _extra(common, {"radius": 6.0 * scale, "angular_speed": -side * 0.20}))
		"marisa_boss":
			if move == 0:
				for side in [-1, 1]: dm._ring(c, origin + Vector2(-40, side * 45) * scale, 12, wave * 0.25 * side, 109 * scale, GOLD if side < 0 else BLUE, "star", _extra(common, {"angular_speed": -side * 0.25}))
			else:
				for layer in range(3): dm._fan(c, origin + Vector2(-18 * layer, (layer - 1) * 40) * scale, 7, PI + (layer - 1) * 0.22, 0.9, (120 + layer * 18) * scale, GOLD, "star", _extra(common, {"bounces": 1}))
		"tewi_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI + 0.14, 0.90, 118 * scale, GOLD, "orb", _extra(common, {"bounces": 1}))
			elif move == 1: dm._ring(c, origin + Vector2(-40, 0) * scale, 16, wave * 0.24, 105 * scale, GOLD, "orb", _extra(common, {"bounces": 2}))
			else:
				for i in range(g.active_rows.size()):
					if i == wave % g.active_rows.size(): continue
					dm._fan(c, _lane(dm, int(g.active_rows[i])), 3, PI, 0.30, 111 * scale, GOLD, "orb", _extra(common, {"angular_speed": 0.13}))
		"reisen_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI + 0.18, 1.0, 125 * scale, RED if lane == row else PURPLE, "rice", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2 if lane == row else 1.5}))
			else:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-30, side * 47) * scale, 9, PI + side * 0.3, 1.15, 117 * scale, RED, "rice", _extra(common, {"redirect_at": 1.35, "aim_point": target, "angular_speed": side * 0.15}))
		"eirin_boss":
			if move == 0: dm._fan(c, origin, 17, PI, 1.95, 123 * scale, RED, "rice", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2, "thaw_angle": sin(wave) * 0.22}))
			else:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI, 1.05, 126 * scale, RED if lane == row else BLUE, "ofuda", _extra(common, {"angular_speed": 0.18 if lane == row else -0.18}))
		"kaguya_boss":
			if move == 0:
				for layer in range(3): dm._fan(c, origin, 5, PI + (layer - 1) * 0.30, 0.80, (108 + layer * 18) * scale, [RED, GOLD, PURPLE][layer], "orb", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2 + layer * 0.20}))
			else:
				for side in [-1, 1]: dm._ring(c, origin + Vector2(-35, side * 43) * scale, 12, wave * 0.22 * side, 103 * scale, GOLD if side < 0 else PURPLE, "orb", _extra(common, {"angular_speed": -side * 0.24}))
		"suika_boss":
			if move == 0:
				for i in range(3): dm._fan(c, origin + Vector2(-i * 23, (i - 1) * 42) * scale, 5, PI + (i - 1) * 0.22, 0.75, (109 + i * 17) * scale, GOLD, "suika_stone", _extra(common, {"radius": (4.5 + i) * scale}))
			else:
				for side in [-1, 1]: dm._fan(c, origin + Vector2(-35, side * 43) * scale, 9, PI + side * 0.35, 1.12, 115 * scale, PURPLE if side < 0 else RED, "suika_fire", _extra(common, {"redirect_at": 1.3, "aim_point": target, "angular_speed": -side * 0.16}))
		"shizuha_boss":
			if move == 0:
				for layer in range(3): dm._fan(c, origin, 5, PI + (layer - 1) * 0.25, 0.80, (105 + layer * 16) * scale, RED if layer % 2 else GOLD, "aki_leaf", _extra(common, {"angular_speed": (layer - 1) * 0.18}))
			elif move == 1:
				for side in [-1, 1]: dm._ring(c, origin + Vector2(-40, side * 40) * scale, 10, wave * 0.23 * side, 95 * scale, RED, "aki_leaf", _extra(common, {"angular_speed": -side * 0.20}))
			else:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI, 0.95, 114 * scale, RED, "aki_leaf", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2 if lane == row else 1.45}))
		"minoriko_boss":
			if move == 0:
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 7, PI + 0.14, 0.92, 122 * scale, GOLD if lane == row else RED, "aki_grain" if lane == row else "aki_leaf", _extra(common, {"angular_speed": 0.13 if lane == row else -0.13}))
			else:
				for layer in range(3): dm._ring(c, origin + Vector2(-25 * layer, (layer - 1) * 36) * scale, 8, wave * 0.22 + layer * 0.2, (98 + layer * 13) * scale, GOLD, "aki_grain", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.2 + layer * 0.12}))
		"hina_boss":
			if move == 0:
				for arm in range(7):
					if arm == wave % 7: continue
					dm._fan(c, origin, 3, arm * TAU / 7 + wave * 0.17, 0.15, 108 * scale, GREEN, "hina_ofuda", _extra(common, {"angular_speed": 0.17}))
			else:
				for side in [-1, 1]: dm._ring(c, origin + Vector2(-35, side * 43) * scale, 12, wave * 0.24 * side, 101 * scale, GREEN if side < 0 else RED, "hina_doll", _extra(common, {"angular_speed": -side * 0.22, "freeze_at": 0.0, "thaw_at": 1.2 if side < 0 else 1.45}))
		"nitori_boss":
			if move == 0:
				# A six-paddle water wheel; the missing paddle walks around each turn.
				for paddle in range(6):
					if paddle == wave % 6: continue
					dm._fan(c, origin, 3, paddle * TAU / 6 + wave * 0.21, 0.14, 104 * scale, BLUE, "nitori_drop", _extra(common, {"angular_speed": 0.19}))
				dm._ring(c, origin, 6, -wave * 0.3, 70 * scale, Color("dff6ff"), "nitori_bubble", _extra(common, {"radius": 5.0 * scale}))
			else:
				# Rain columns pour back down the riverbed while two lanes surge.
				for k in range(4):
					var top: Vector2 = dm._point(0.28 + fposmod(wave * 0.13 + k * 0.19, 0.68), 0.0) + Vector2(0, -6)
					dm._fan(c, top, 3, PI / 2 + 0.25, 0.18, 92 * scale, BLUE, "nitori_drop", common)
				for lane in [row, other]: dm._fan(c, _lane(dm, lane), 5, PI, 0.42, 118 * scale, Color("3a9ad6"), "nitori_drop", _extra(common, {"freeze_at": 0.0, "thaw_at": 1.15 if lane == row else 1.4}))
	c.next_wave = float(c.age) + maxf(1.1, cadence * g.TouhouDifficulty.attack_cadence(kind, g.current_level))

static func _extra(base: Dictionary, fields: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	result.merge(fields, true)
	return result
