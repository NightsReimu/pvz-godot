extends RefCounted
# Kanako's TH10 stage6 emitters, adapted to six horizontal lanes. Angles that
# the original randomises use a deterministic hash, so a spell never draws
# from the combat RNG and a replayed wave keeps its topology.
const RED := Color("ec4b5e")
const CRIMSON := Color("c22c48")
const PURPLE := Color("a172ec")
const BLUE := Color("5db4f0")
const CYAN := Color("8fe6ee")
const GOLD := Color("f3d06a")
const GREEN := Color("62c98a")
const DARK_GREEN := Color("3f8f5e")
const WHITE := Color("f7f1e3")
const WOOD := Color("8b6342")
const WOOD_DARK := Color("5a3d28")
const WOOD_LIGHT := Color("b88d5e")
const ROPE := Color("d9bd7a")
const ROPE_DARK := Color("a5844a")
const PAPER := Color("f4f1e6")
const INK := Color("1c1020")
const OFUDA_COLORS := [RED, DARK_GREEN, BLUE, PURPLE, GOLD]

static func _scale(game: Control) -> float:
	return minf(1.0, minf(game.CELL_SIZE.x / 100.0, game.CELL_SIZE.y / 110.0))

static func _extra(scale: float, damage: float, turn: float = 0.0, radius: float = 4.4) -> Dictionary:
	return {"arming_time": 1.1, "radius": maxf(2.0, radius * scale), "damage": damage, "angular_speed": turn, "life": 8.5}

static func noise(a: int, b: int = 0) -> float:
	var h: int = a * 374761393 + b * 668265263 + 1442695041
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(posmod(h, 100003)) / 100003.0

static func _rank(dm: RefCounted) -> int:
	return int(dm.game.TouhouDifficulty.profile(dm.game.current_level).rank)

static func _count(dm: RefCounted, c: Dictionary, base: int) -> int:
	return maxi(1, ceili(base * dm._attack_density_for_cast(c)))

static func _row(game: Control, index: int) -> int:
	return int(game.active_rows[posmod(index, game.active_rows.size())])

static func _speed(dm: RefCounted, c: Dictionary) -> float:
	return dm.Difficulty.attack_speed(String(c.kind), dm.game.current_level)

# ------------------------------------------------------------------ emitters

static func faith_emitters(game: Control, c: Dictionary, count: int) -> Array:
	# Onbashira that rise behind Kanako for Mountain of Faith and its variants.
	var points: Array = []
	var center := Vector2(c.center)
	for i in range(count):
		var angle := PI * 0.5 + TAU * i / count + float(c.age) * 0.16
		points.append(center + Vector2(cos(angle) * game.CELL_SIZE.x * 0.9, sin(angle) * game.CELL_SIZE.y * 1.3))
	return points

static func twin_sources(game: Control, c: Dictionary) -> Array:
	var center := Vector2(c.center)
	var sway: float = sin(float(c.age) * 1.7) * game.CELL_SIZE.y * 0.12
	return [center + Vector2(-game.CELL_SIZE.x * 0.35, -game.CELL_SIZE.y * 1.15 + sway), center + Vector2(-game.CELL_SIZE.x * 0.35, game.CELL_SIZE.y * 1.15 - sway)]

static func _snake(dm: RefCounted, c: Dictionary, head: Vector2, segments: int, spacing: float, amp: float, wavelength: float, phase: float, tint: Color, body: String, head_shape: String, damage: float, scale: float) -> void:
	# Every segment follows one path with a fixed lag. Until its turn a segment
	# waits, hidden and harmless, at the off-board head origin, so the body
	# visibly slithers in rather than appearing as a ring.
	var game: Control = dm.game
	var speed: float = game.CELL_SIZE.x * 1.05 * _speed(dm, c)
	var crossing: float = game.board_size.x + spacing * segments + game.CELL_SIZE.x * 3.0
	for i in range(segments):
		var body_radius := 4.4 if body == "kanako_rope" else 5.6
		var extra := _extra(scale, damage + (3.0 if i == 0 else 0.0), 0.0, body_radius + 1.6 if i == 0 else body_radius)
		extra.merge({"snake_x0": head.x, "snake_y0": head.y, "snake_speed": speed, "snake_lag": spacing * i, "snake_amp": amp, "snake_k": TAU / maxf(1.0, wavelength), "snake_phase": phase, "segment": i, "life": crossing / speed + 0.5, "arming_time": 0.0}, true)
		extra["dormant"] = i > 0
		dm._bullet(c, Vector2(head.x, head.y + amp * sin(phase)), PI, speed, tint, head_shape if i == 0 else body, extra)

static func impact_ring(dm: RefCounted, c: Dictionary, point: Vector2) -> void:
	var scale := _scale(dm.game)
	var count := _count(dm, c, 5)
	for i in range(count):
		var extra := _extra(scale, 11.0, 0.0, 3.8)
		extra.merge({"arming_time": 0.18, "life": 2.4}, true)
		dm._bullet(c, point, PI * 0.5 + TAU * (i + 0.5) / count, 96.0 * scale, WOOD_LIGHT if i % 2 else ROPE, "kanako_shard", extra)

static func pillar_pulse(dm: RefCounted, c: Dictionary, point: Vector2) -> void:
	var scale := _scale(dm.game)
	dm._fan(c, point, 5, PI, 0.7, 118.0 * scale, RED, "kanako_ofuda", _extra(scale, 12.0, 0.0, 4.2))

static func _aimed(dm: RefCounted, c: Dictionary, origin: Vector2, count: int, spread: float, speed: float, tint: Color, shape: String, damage: float) -> void:
	var scale := _scale(dm.game)
	dm._fan(c, origin, count, (Vector2(dm._target(origin)) - origin).angle(), spread, speed * scale, tint, shape, _extra(scale, damage))

static func tick_cast(dm: RefCounted, c: Dictionary) -> void:
	var pending: Array = c.get("kanako_torus", [])
	for i in range(pending.size() - 1, -1, -1):
		var torus: Dictionary = pending[i]
		if float(c.age) < float(torus.release): continue
		var scale := _scale(dm.game)
		var count := _count(dm, c, 6)
		for j in range(count):
			var extra := _extra(scale, 13.0, float(torus.turn), 4.2)
			extra.merge({"arming_time": 0.25, "life": 5.6}, true)
			dm._bullet(c, torus.position, TAU * j / count + float(torus.turn), 128.0 * scale, CYAN if j % 2 else BLUE, "kanako_knife", extra)
		pending.remove_at(i)
	c["kanako_torus"] = pending

static func emit(dm: RefCounted, c: Dictionary) -> void:
	var game: Control = dm.game
	var r := _rank(dm)
	var scale := _scale(game)
	var origin := Vector2(c.center)
	var wave := int(c.wave)
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var cell: Vector2 = game.CELL_SIZE
	var cadence := 1.5
	match String(c.pattern):
		"nonspell_kanako_twin":
			# Two sources, each a full ring at a hashed angle: the river-like
			# gaps of the original drift across all six lanes.
			var sources := twin_sources(game, c)
			for s in range(2):
				var count := _count(dm, c, 9)
				var base := noise(wave, s) * TAU
				for i in range(count):
					dm._bullet(c, sources[s], base + TAU * i / count, 112.0 * scale, RED if s == 0 else PURPLE, "kanako_orb", _extra(scale, 12.0, 0.0, 5.0))
			cadence = 1.05
		"kanako_onbashira", "kanako_medoteko":
			# Pillar lasers close in from both lawn edges towards the centre,
			# then aimed shots chase the last open column.
			var step := posmod(wave, 5)
			var columns: Array = [step, game.COLS - 1 - step]
			if r >= 3 and step < 4: columns.append_array([mini(step + 1, 4), game.COLS - 2 - step])
			var seen := {}
			for col in columns:
				if seen.has(col) or col < 0 or col >= game.COLS: continue
				seen[col] = true
				var x: float = board.position.x + cell.x * (float(col) + 0.5)
				dm._beam(c, Vector2(x, board.position.y - 2.0), Vector2(x, board.end.y + 2.0), RED, 1.05 if r < 2 else 0.92, cell.x * 0.48, {"damage": 15.0, "duration": 0.55, "kanako_pillar": true})
			_aimed(dm, c, origin, 5 if r == 0 else 7, 0.7, 150.0, WHITE, "kanako_orb", 13.0)
			if String(c.pattern) == "kanako_medoteko":
				# H/L: lever-driven shots rise from beneath the shrine floor.
				for i in range(3 + r):
					var x := board.position.x + board.size.x * (0.12 + 0.76 * noise(wave, 20 + i))
					var extra := _extra(scale, 11.0, 0.0, 3.8)
					extra["arming_time"] = 0.35
					dm._bullet(c, Vector2(x, board.end.y + 4.0), -PI * 0.5 - 0.2, 96.0 * scale, GOLD, "kanako_orb_small", extra)
			cadence = 1.3 if r < 2 else 1.12
		"nonspell_kanako_drift":
			# A fixed lattice launched at the nearest plant; on H/L the blue
			# block slides up the lanes and the red block slides down.
			var aim := (Vector2(dm._target(origin)) - origin).angle()
			var columns := 2 + mini(2, int(dm._attack_density_for_cast(c)))
			for block in range(2):
				var tint := BLUE if block == 0 else RED
				var turn := 0.0 if r < 2 else (-0.22 if block == 0 else 0.22)
				var offset := (block - 0.5) * 0.36
				for row in range(3):
					for col in range(columns):
						var start := origin + Vector2(col * cell.x * 0.16, (row - 1) * cell.y * 0.18)
						dm._bullet(c, start, aim + offset + (row - 1) * 0.05, (132.0 + col * 10.0) * scale, tint, "kanako_ofuda", _extra(scale, 12.0, turn))
			cadence = 1.25
		"kanako_porridge", "kanako_unremembered", "kanako_divining":
			# Almonds swap to rice grains mid-flight; alternate grains turn in
			# opposite senses, so the lattice crosses itself. E authors the
			# narrower ring (effectively ~34-way after the Wind God density).
			var count := _count(dm, c, 17 if r == 0 else 25)
			var base := noise(wave, 3) * TAU
			for i in range(count):
				var sense := 1.0 if i % 2 == 0 else -1.0
				var extra := _extra(scale, 13.0, 0.0, 4.6)
				extra.merge({"arming_time": 0.9, "morph_at": 0.85, "morph_shape": "kanako_rice", "morph_speed": 1.22, "morph_angular": sense * (0.42 if r < 2 else 0.5)}, true)
				var tint := GOLD if r < 2 else (RED if i % 2 == 0 else GREEN)
				dm._bullet(c, origin, base + TAU * i / count, 112.0 * scale, tint, "kanako_almond", extra)
			if r == 3:
				var blue := _count(dm, c, 8)
				for i in range(blue):
					var extra := _extra(scale, 13.0, 0.0, 4.6)
					extra.merge({"arming_time": 0.9, "morph_at": 0.7, "morph_shape": "kanako_rice", "morph_speed": 1.35, "morph_angular": 0.3 if i % 2 else -0.3}, true)
					dm._bullet(c, origin, base + PI / blue + TAU * i / blue, 142.0 * scale, BLUE, "kanako_almond", extra)
			cadence = 1.55 if r < 2 else 1.15
		"nonspell_kanako_cross":
			# Streams from above and below Kanako sweep past each other.
			var sweep := sin(wave * 0.7) * 0.25
			for side in [-1, 1]:
				var source := origin + Vector2(-cell.x * 0.2, side * cell.y * 1.6)
				var angle: float = PI - side * (0.42 + sweep)
				for i in range(_count(dm, c, 3)):
					dm._bullet(c, source, angle, (118.0 + i * 16.0) * scale, PURPLE if side < 0 else CYAN, "kanako_scale", _extra(scale, 12.0))
			cadence = 0.9
		"kanako_misayama":
			# Medium orbs hold on a fixed lattice before advancing, while the
			# knives deliberately miss the targeted lane and strike its neighbours.
			var lattice := 1 + mini(2, int(dm._attack_density_for_cast(c)))
			for i in range(game.active_rows.size()):
				var row := int(game.active_rows[i])
				for j in range(lattice):
					var x := board.position.x + cell.x * (5.4 + j * 1.1 + float((wave + i) % 2) * 0.5)
					var extra := _extra(scale, 15.0, 0.0, 6.6)
					extra.merge({"freeze_at": 0.0, "thaw_at": 1.25, "thaw_angle": 0.0, "arming_time": 1.25}, true)
					dm._bullet(c, Vector2(x, game._row_center_y(row)), PI, 88.0 * scale, RED if j % 2 == 0 else PURPLE, "kanako_big", extra)
			var target := Vector2(dm._target(origin))
			for side in [-1, 1]:
				var miss := target + Vector2(0, side * cell.y)
				dm._fan(c, origin, 3, (miss - origin).angle(), 0.12, 196.0 * scale, WHITE, "kanako_knife", _extra(scale, 13.0))
			cadence = 1.75
		"kanako_kuzui", "kanako_yamato_torus":
			# Fast knife trains enter from BOTH lawn edges; plants in the back
			# column are no longer safe from the hunt.
			var trains := _count(dm, c, 2 if String(c.pattern) == "kanako_kuzui" else 1)
			for i in range(trains):
				for side in [-1, 1]:
					var row := _row(game, wave * 2 + i * 3 + (1 if side > 0 else 0))
					var y: float = game._row_center_y(row) + (noise(wave, i * 7 + side) - 0.5) * cell.y * 0.36
					var x: float = board.position.x - cell.x * 0.4 if side < 0 else board.end.x + cell.x * 0.4
					for k in range(3):
						var extra := _extra(scale, 13.0, 0.0, 4.2)
						extra["arming_time"] = 0.2
						dm._bullet(c, Vector2(x + side * k * cell.x * 0.28, y), 0.0 if side < 0 else PI, 228.0 * scale, CYAN if side < 0 else BLUE, "kanako_knife", extra)
			if String(c.pattern) == "kanako_yamato_torus":
				var pending: Array = c.get("kanako_torus", [])
				for i in range(2):
					if pending.size() >= 6: break
					var col := 1.5 + noise(wave, 40 + i) * 5.5
					var row := _row(game, wave + i * 3)
					pending.append({"position": Vector2(board.position.x + cell.x * col, game._row_center_y(row)), "release": float(c.age) + 1.1, "turn": 1.15 if i % 2 == 0 else -1.15})
				c["kanako_torus"] = pending
			_aimed(dm, c, origin, 5, 0.5, 160.0, WHITE, "kanako_knife", 13.0)
			cadence = 1.0 if String(c.pattern) == "kanako_kuzui" else 1.2
		"nonspell_kanako_cycle":
			match posmod(wave, 3):
				0: _aimed(dm, c, origin, 3, 0.55, 108.0, RED, "kanako_big", 16.0)
				1:
					_aimed(dm, c, origin, 11, 1.2, 176.0, RED, "kanako_knife", 13.0)
					dm._ring(c, origin, 10, wave * 0.31, 132.0 * scale, PURPLE, "kanako_knife", _extra(scale, 13.0))
				_:
					var sense := 1.0 if posmod(wave, 2) == 0 else -1.0
					dm._fan(c, origin, 13, PI, 2.2, 124.0 * scale, GOLD, "kanako_orb", _extra(scale, 13.0, sense * 0.28, 5.0))
			cadence = 0.95
		"kanako_otensui", "kanako_rain_source":
			# Light bullets fall from heaven-water and turn into scales; red
			# scales sweep down from the top, purple scales rise from the base.
			for i in range(_count(dm, c, 3)):
				var x := board.position.x + board.size.x * (0.22 + 0.74 * noise(wave, 60 + i))
				var extra := _extra(scale, 13.0, 0.0, 5.2)
				extra.merge({"arming_time": 0.6, "morph_at": 1.25, "morph_shape": "kanako_scale", "morph_speed": 2.3, "morph_turn": 0.25 if i % 2 else -0.25}, true)
				dm._bullet(c, Vector2(x, board.position.y - cell.y * 0.3), PI * 0.62, 60.0 * scale, CYAN, "kanako_light", extra)
			var both := r == 0
			if both or wave % 2 == 0:
				dm._fan(c, Vector2(board.end.x, board.position.y), 7, PI * 0.82, 0.55, 150.0 * scale, RED, "kanako_scale", _extra(scale, 13.0))
			if both or wave % 2 == 1:
				dm._fan(c, Vector2(board.end.x, board.end.y), 7, -PI * 0.82, 0.55, 150.0 * scale, PURPLE, "kanako_scale", _extra(scale, 13.0))
			_aimed(dm, c, origin, 3, 0.3, 150.0, WHITE, "kanako_orb", 13.0)
			if String(c.pattern) == "kanako_rain_source" and wave % 2 == 0:
				# The source of rains: a scaled water dragon threads the lanes.
				var row := _row(game, wave)
				_snake(dm, c, Vector2(board.end.x + cell.x * 0.4, game._row_center_y(row)), 18, cell.x * 0.14, cell.y * 1.3, cell.x * 3.4, noise(wave, 77) * TAU, CYAN, "kanako_scale", "kanako_dragon_head", 13.0, scale)
			cadence = 1.5 if r == 0 else (1.3 if r == 1 else 1.15)
		"kanako_mountain_of_faith", "kanako_wind_god_virtue":
			# Coloured ofuda clusters at hashed angles from the rising pillars,
			# no aimed component; the release interval shortens over the card.
			var virtue := String(c.pattern) == "kanako_wind_god_virtue"
			var emitters := faith_emitters(game, c, 6 if virtue else 5)
			var per := 6 if r == 0 else (7 if r == 1 else 8)
			for e in range(emitters.size()):
				var tint: Color = OFUDA_COLORS[posmod(e + wave, OFUDA_COLORS.size())]
				var angle := PI + (noise(wave, e) - 0.5) * 1.5
				var loose := r == 0 and tint != RED and tint != DARK_GREEN
				for k in range(per):
					var jitter := (noise(wave * 31 + e, k) - 0.5) * (0.5 if loose else 0.14)
					dm._bullet(c, emitters[e], angle + jitter, (112.0 + k * 9.0) * scale, tint, "kanako_ofuda", _extra(scale, 14.0 if virtue else 13.0))
			var progress := clampf(float(c.age) / maxf(1.0, float(c.duration)), 0.0, 1.0)
			cadence = lerpf(1.55, 0.72, progress) * (0.9 if virtue else 1.0)
		"kanako_pillar_fall":
			for i in range(_count(dm, c, 2)):
				var x := board.position.x + board.size.x * (0.1 + 0.8 * noise(wave, 90 + i))
				var extra := _extra(scale, 12.0, 0.0, 4.0)
				extra.merge({"arming_time": 0.45, "gravity": cell.y * 1.4}, true)
				dm._bullet(c, Vector2(x, board.position.y - cell.y * 0.35), PI * 0.58, 48.0 * scale, WOOD_LIGHT, "kanako_shard", extra)
			_aimed(dm, c, origin, 5, 0.6, 150.0, RED, "kanako_orb", 13.0)
			cadence = 1.4
		"kanako_shimenawa":
			# A braided straw rope: two strands in opposite phase twist along a
			# lane, with paper shide tied into it.
			for i in range(2):
				var row := _row(game, wave * 2 + i * 3)
				var y: float = game._row_center_y(row)
				for strand in range(2):
					_snake(dm, c, Vector2(board.end.x + cell.x * 0.3, y), 9, cell.x * 0.22, cell.y * 0.2, cell.x * 1.5, PI * strand, ROPE if strand == 0 else ROPE_DARK, "kanako_rope", "kanako_shide", 12.0, scale)
			_aimed(dm, c, origin, 3, 0.4, 140.0, PAPER, "kanako_ofuda", 12.0)
			cadence = 1.7
		"kanako_weather":
			# The lake's ice ridge (御神渡) crosses every lane in a zigzag wall
			# with one open lane; the second half adds slanted rain.
			var gap := _row(game, wave)
			for i in range(game.active_rows.size()):
				var row := int(game.active_rows[i])
				if row == gap: continue
				var zig := (0.35 if i % 2 == 0 else -0.35) * cell.x
				for k in range(2 + mini(1, r)):
					var p := Vector2(origin.x + zig + k * cell.x * 0.18, game._row_center_y(row) + (k - 1) * cell.y * 0.18)
					dm._bullet(c, p, PI, 90.0 * scale, CYAN if k % 2 else WHITE, "kanako_ice", _extra(scale, 13.0, 0.0, 4.8))
			if float(c.age) >= float(c.duration) * 0.5:
				for i in range(_count(dm, c, 3)):
					var x := board.position.x + board.size.x * (0.15 + 0.85 * noise(wave, 120 + i))
					var extra := _extra(scale, 12.0, 0.0, 3.6)
					extra.merge({"arming_time": 0.5, "gravity": cell.y * 0.8}, true)
					dm._bullet(c, Vector2(x, board.position.y - cell.y * 0.3), PI * 0.6, 120.0 * scale, BLUE, "kanako_drop", extra)
			else:
				_aimed(dm, c, origin, 5, 0.9, 150.0, GREEN, "kanako_scale", 13.0)
			cadence = 1.45
		"kanako_war_god":
			# Volleys of arrows arc over the lanes and are only armed on the
			# way down, so they land on the column they were aimed at.
			for i in range(_count(dm, c, 3)):
				var col := posmod(wave * 3 + i * 2, game.COLS - 1)
				var row := _row(game, wave + i)
				var target: Vector2 = game._cell_center(row, col) + Vector2(0, -12)
				var extra := _extra(scale, 14.0, 0.0, 4.4)
				var flight := 1.3 + noise(wave, 150 + i) * 0.3
				extra.merge({"lob_from": origin, "lob_to": target, "lob_time": flight, "lob_height": cell.y * (1.4 + noise(wave, 160 + i)), "arming_time": flight * 0.82, "life": flight + 1.4}, true)
				dm._bullet(c, origin, PI, 120.0 * scale, RED if i % 2 == 0 else GOLD, "kanako_arrow", extra)
			_aimed(dm, c, origin, 7, 0.8, 168.0, RED, "kanako_knife", 13.0)
			cadence = 1.35
		"kanako_serpent":
			# White serpents slither diagonally across rows: the snake under
			# the war god's name.
			var snakes := 2 + (1 if r >= 2 else 0)
			for i in range(snakes):
				var row := _row(game, wave * 2 + i * 2)
				_snake(dm, c, Vector2(board.end.x + cell.x * 0.5, game._row_center_y(row)), 18 + 2 * r, cell.x * 0.12, cell.y * (0.9 + 0.25 * i), cell.x * (3.0 + i * 0.6), noise(wave, 170 + i) * TAU, Color("f1e9f2"), "kanako_snake", "kanako_snake_head", 13.0, scale)
			_aimed(dm, c, origin, 5, 0.6, 150.0, PURPLE, "kanako_scale", 13.0)
			cadence = 2.4
		"kanako_faith":
			var emitters := faith_emitters(game, c, 6)
			for e in range(emitters.size()):
				var angle := PI + sin(float(c.age) * 1.3 + e) * 0.85
				dm._fan(c, emitters[e], 3, angle, 0.24, 130.0 * scale, OFUDA_COLORS[posmod(e, OFUDA_COLORS.size())], "kanako_ofuda", _extra(scale, 14.0))
			if wave % 3 == 0:
				dm._ring(c, origin, 14, wave * 0.21, 108.0 * scale, RED, "kanako_orb", _extra(scale, 13.0, 0.0, 5.0))
			cadence = 0.95
	c.next_wave = float(c.age) + maxf(0.6, cadence * dm.Difficulty.attack_cadence(String(c.kind), game.current_level))

# ------------------------------------------------------------------ motion

static func advance_bullet(dm: RefCounted, b: Dictionary, before: Vector2, _delta: float) -> Vector2:
	var age := float(b.age)
	if b.has("snake_x0"):
		var s: float = maxf(0.0, float(b.snake_speed) * age - float(b.snake_lag))
		var k := float(b.snake_k)
		var amp := float(b.snake_amp)
		b.position = Vector2(float(b.snake_x0) - s, float(b.snake_y0) + amp * sin(k * s + float(b.snake_phase)))
		b.velocity = Vector2(-float(b.snake_speed), amp * k * float(b.snake_speed) * cos(k * s + float(b.snake_phase)))
		b["dormant"] = s <= 0.0 and int(b.get("segment", 0)) > 0
		return Vector2(b.position) if bool(b.dormant) else before
	if b.has("lob_from"):
		var t := clampf(age / maxf(0.05, float(b.lob_time)), 0.0, 1.0)
		var from := Vector2(b.lob_from)
		var to := Vector2(b.lob_to)
		var height := float(b.lob_height)
		b.position = from.lerp(to, t) - Vector2(0, height * 4.0 * t * (1.0 - t))
		var slope := (to - from) / maxf(0.05, float(b.lob_time)) - Vector2(0, height * 4.0 * (1.0 - 2.0 * t) / maxf(0.05, float(b.lob_time)))
		b.velocity = slope
		if t >= 1.0:
			# The arrow buries itself in the aimed cell instead of sliding on.
			b.erase("lob_from")
			b["life"] = age + 0.06
		return before
	if b.has("gravity"):
		b.velocity = Vector2(b.velocity) + Vector2(0, float(b.gravity) * _delta)
	if b.has("morph_at") and age >= float(b.morph_at) and not bool(b.get("morphed", false)):
		b["morphed"] = true
		b["morph_flash"] = age
		b.shape = String(b.morph_shape)
		b.velocity = dm._rotate_bullet_velocity(b, float(b.get("morph_turn", 0.0))) * float(b.get("morph_speed", 1.0))
		b["angular_speed"] = float(b.get("morph_angular", b.get("angular_speed", 0.0)))
		b.radius = float(b.radius) * 0.8
	return before

# ------------------------------------------------------------------ drawing

static func draw_pillar(game: CanvasItem, foot: Vector2, width: float, height: float, alpha: float = 1.0, glow: float = 0.0, cracks: float = 0.0) -> void:
	# A cut cedar onbashira: shaded trunk, bark grooves, a cut top showing
	# growth rings, and a shimenawa band with zigzag shide.
	if alpha <= 0.01 or width <= 0.5 or height <= 0.5: return
	var top := foot - Vector2(0, height)
	var half := width * 0.5
	if glow > 0.01:
		game.draw_rect(Rect2(top - Vector2(half + width * 0.22, width * 0.1), Vector2(width * 1.44, height + width * 0.12)), Color(RED, alpha * glow * 0.22))
	game.draw_rect(Rect2(top - Vector2(half, 0), Vector2(width, height)), Color(WOOD, alpha))
	game.draw_rect(Rect2(top - Vector2(half, 0), Vector2(width * 0.22, height)), Color(WOOD_DARK, alpha * 0.85))
	game.draw_rect(Rect2(top + Vector2(half - width * 0.2, 0), Vector2(width * 0.2, height)), Color(WOOD_DARK, alpha * 0.65))
	game.draw_rect(Rect2(top - Vector2(half - width * 0.3, 0), Vector2(width * 0.16, height)), Color(WOOD_LIGHT, alpha * 0.7))
	var grooves := clampi(int(width / 4.0), 2, 6)
	for i in range(grooves):
		var x := -half + width * (i + 0.7) / (grooves + 0.4)
		game.draw_line(top + Vector2(x, width * 0.5), foot + Vector2(x + sin(i * 2.3) * width * 0.05, -width * 0.1), Color(WOOD_DARK, alpha * 0.45), maxf(0.6, width * 0.04), true)
	game.draw_circle(top, half, Color(WOOD_LIGHT, alpha))
	game.draw_arc(top, half * 0.66, 0, TAU, 14, Color(WOOD_DARK, alpha * 0.55), maxf(0.6, width * 0.04), true)
	game.draw_arc(top, half * 0.33, 0, TAU, 10, Color(WOOD_DARK, alpha * 0.45), maxf(0.6, width * 0.035), true)
	var band := top + Vector2(0, minf(height * 0.22, width * 1.3))
	game.draw_rect(Rect2(band - Vector2(half * 1.12, width * 0.13), Vector2(width * 1.12, width * 0.26)), Color(ROPE, alpha))
	for i in range(4):
		var x := -half * 1.05 + width * 1.05 * (i + 0.5) / 4.0
		game.draw_line(band + Vector2(x - width * 0.1, -width * 0.12), band + Vector2(x + width * 0.1, width * 0.12), Color(ROPE_DARK, alpha), maxf(0.6, width * 0.05), true)
	for i in [-1, 1]:
		draw_shide(game, band + Vector2(i * half * 0.6, width * 0.12), width * 0.62, alpha, i * 0.08)
	if cracks > 0.05:
		var crack := PackedVector2Array([top + Vector2(-half * 0.2, height * 0.3), top + Vector2(half * 0.15, height * 0.42), top + Vector2(-half * 0.1, height * 0.55), top + Vector2(half * 0.25, height * (0.55 + cracks * 0.3))])
		game.draw_polyline(crack, Color(INK, alpha * clampf(cracks, 0.0, 1.0)), maxf(0.8, width * 0.06), true)

static func draw_shide(game: CanvasItem, hang: Vector2, size: float, alpha: float = 1.0, sway: float = 0.0) -> void:
	# A lightning-folded paper streamer: four strips stepping left and right.
	if alpha <= 0.01 or size <= 0.5: return
	var down := Vector2(sin(sway), cos(sway))
	var across := Vector2(down.y, -down.x)
	var point := hang
	for k in range(4):
		var corner := point + across * size * (0.06 if k % 2 == 0 else -0.24)
		var strip := PackedVector2Array([corner, corner + across * size * 0.3, corner + across * size * 0.3 + down * size * 0.36, corner + down * size * 0.36])
		game.draw_colored_polygon(strip, Color(PAPER, alpha))
		game.draw_line(strip[2], strip[3], Color(0.62, 0.58, 0.5, alpha * 0.7), 1.0, true)
		point += down * size * 0.3

static func draw_beam(game: Control, beam: Dictionary) -> void:
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var from := Vector2(beam.from)
	var to := Vector2(beam.to)
	var width := float(beam.width)
	var delay := maxf(0.01, float(beam.delay))
	var age := float(beam.age)
	var progress := clampf(age / delay, 0.0, 1.0)
	if age < delay:
		# Warning: a red column shadow brightens while the pillar descends.
		var shadow := Rect2(Vector2(from.x - width * 0.5, board.position.y), Vector2(width, board.size.y))
		game.draw_rect(shadow, Color(RED, 0.06 + progress * 0.12))
		for side in [-1, 1]:
			game.draw_line(Vector2(from.x + side * width * 0.5, board.position.y), Vector2(from.x + side * width * 0.5, board.end.y), Color(RED, 0.35 + progress * 0.4), 1.4, true)
		var dash := board.size.y / 12.0
		for i in range(12):
			if i % 2: continue
			var y := board.position.y + dash * (i + fposmod(age * 3.0, 2.0))
			game.draw_line(Vector2(from.x, y), Vector2(from.x, minf(board.end.y, y + dash * 0.7)), Color(1, 0.9, 0.8, 0.35 + progress * 0.3), 1.2, true)
		if progress > 0.45:
			var drop := (progress - 0.45) / 0.55
			var length := board.size.y * 0.55
			var foot_y: float = lerpf(board.position.y - 4.0, board.position.y + length * 0.35, drop * drop)
			draw_pillar(game, Vector2(from.x, foot_y), width * 0.72, length * drop, drop)
		return
	var fade := clampf((delay + float(beam.duration) - age) / 0.22, 0.0, 1.0)
	var impact := clampf((age - delay) / 0.12, 0.0, 1.0)
	game.draw_rect(Rect2(Vector2(from.x - width * 0.75, board.position.y), Vector2(width * 1.5, board.size.y)), Color(RED, 0.18 * fade))
	draw_pillar(game, Vector2(to.x, minf(to.y, board.end.y)), width * 0.82, (minf(to.y, board.end.y) - board.position.y + 6.0) * impact, fade, 1.0)
	game.draw_line(Vector2(from.x, board.position.y), Vector2(from.x, board.end.y), Color(1, 0.94, 0.86, 0.55 * fade), maxf(1.5, width * 0.08), true)
	if impact < 1.0 or age - delay < 0.3:
		var burst := clampf((age - delay) / 0.3, 0.0, 1.0)
		for side in [-1, 1]:
			for k in range(3):
				var p := Vector2(from.x + side * width * (0.5 + burst * (0.6 + k * 0.4)), board.end.y - 4.0 - k * 3.0)
				game.draw_circle(p, width * (0.16 - k * 0.03) * (1.0 - burst * 0.6), Color(WOOD_LIGHT, (1.0 - burst) * 0.75))

static func draw_cast(game: Control, c: Dictionary) -> void:
	var pattern := String(c.pattern)
	var unit := minf(game.CELL_SIZE.x, game.CELL_SIZE.y)
	match pattern:
		"nonspell_kanako_twin":
			var sources := twin_sources(game, c)
			for s in range(2):
				var tint := RED if s == 0 else PURPLE
				var p: Vector2 = sources[s]
				game.draw_circle(p, unit * 0.16, Color(tint, 0.22))
				game.draw_circle(p, unit * 0.08, Color(1, 0.95, 0.95, 0.85))
				game.draw_arc(p, unit * 0.22, float(c.age) * 2.6 * (1 - s * 2), float(c.age) * 2.6 * (1 - s * 2) + PI * 1.2, 16, Color(tint, 0.75), 1.6, true)
		"kanako_porridge", "kanako_unremembered", "kanako_divining":
			# The divining tube (筒粥) from which the porridge is drawn.
			var p := Vector2(c.center) + Vector2(-unit * 0.45, -unit * 0.05)
			game.draw_rect(Rect2(p - Vector2(unit * 0.09, unit * 0.32), Vector2(unit * 0.18, unit * 0.5)), Color("a9b86d", 0.92))
			for k in range(3): game.draw_line(p + Vector2(-unit * 0.1, -unit * 0.22 + k * unit * 0.16), p + Vector2(unit * 0.1, -unit * 0.22 + k * unit * 0.16), Color("6f7a3f", 0.9), 1.4, true)
			game.draw_arc(p - Vector2(0, unit * 0.32), unit * 0.09, PI, TAU, 10, Color("d8e3a2", 0.95), 1.4, true)
			game.draw_circle(p - Vector2(0, unit * 0.4), unit * (0.06 + 0.02 * sin(float(c.age) * 6.0)), Color(GOLD, 0.6))
		"kanako_mountain_of_faith", "kanako_wind_god_virtue", "kanako_faith":
			var emitters := faith_emitters(game, c, 5 if pattern == "kanako_mountain_of_faith" else 6)
			var rise := clampf(float(c.age) / 0.8, 0.0, 1.0)
			for e in range(emitters.size()):
				var p: Vector2 = emitters[e]
				var pulse := 0.5 + 0.5 * sin(float(c.age) * 5.0 + e)
				game.draw_circle(p, unit * 0.28, Color(OFUDA_COLORS[posmod(e, OFUDA_COLORS.size())], 0.12 + pulse * 0.1))
				draw_pillar(game, p + Vector2(0, unit * 0.32), unit * 0.17, unit * 0.62 * rise, 0.92, pulse)
		"kanako_yamato_torus":
			for torus in c.get("kanako_torus", []):
				var left := clampf((float(torus.release) - float(c.age)) / 1.1, 0.0, 1.0)
				var p := Vector2(torus.position)
				game.draw_arc(p, unit * (0.18 + left * 0.45), float(c.age) * 3.0, float(c.age) * 3.0 + TAU * 0.8, 24, Color(CYAN, 0.75 - left * 0.4), 1.6, true)
				game.draw_arc(p, unit * (0.12 + left * 0.25), -float(c.age) * 3.0, -float(c.age) * 3.0 + TAU * 0.6, 18, Color(BLUE, 0.6), 1.2, true)
				game.draw_circle(p, unit * 0.05, Color(1, 1, 1, 0.8 - left * 0.5))
		"kanako_war_god":
			for side in [-1, 1]:
				var pole := Vector2(c.center) + Vector2(unit * 0.5, side * unit * 0.95)
				game.draw_line(pole + Vector2(0, unit * 0.5), pole - Vector2(0, unit * 0.55), Color(WOOD_DARK, 0.95), maxf(1.5, unit * 0.04), true)
				var flag := PackedVector2Array()
				for k in range(7):
					var t := float(k) / 6.0
					flag.append(pole - Vector2(unit * 0.55 * t, unit * 0.55 - sin(float(c.age) * 6.0 + t * 4.0) * unit * 0.04 * t))
				for k in range(6, -1, -1):
					var t := float(k) / 6.0
					flag.append(pole - Vector2(unit * 0.55 * t, unit * 0.12 - sin(float(c.age) * 6.0 + t * 4.0) * unit * 0.04 * t))
				game.draw_colored_polygon(flag, Color(CRIMSON, 0.9))
				draw_crest(game, pole - Vector2(unit * 0.28, unit * 0.34), unit * 0.1, Color(PAPER, 0.95))

static func draw_crest(game: CanvasItem, center: Vector2, radius: float, tint: Color) -> void:
	# A simplified kaji-leaf mon of the Suwa shrines.
	game.draw_arc(center, radius, 0, TAU, 18, tint, maxf(1.0, radius * 0.16), true)
	for k in range(3):
		var axis := Vector2.from_angle(-PI * 0.5 + (k - 1) * 0.65)
		var tip := center + axis * radius * 0.85
		var side := axis.orthogonal() * radius * 0.22
		game.draw_colored_polygon(PackedVector2Array([center + axis * radius * 0.1, center + axis * radius * 0.5 + side, tip, center + axis * radius * 0.5 - side]), tint)

static func draw_bullet(game: Control, b: Dictionary) -> void:
	var tint := Color(b.color)
	var p := Vector2(b.position)
	var radius := float(b.radius)
	if bool(b.get("dormant", false)): return
	if float(b.age) < float(b.get("arming_time", 0.0)): tint.a *= 0.45
	var axis := Vector2(b.velocity).normalized()
	if axis.is_zero_approx(): axis = Vector2.LEFT
	var side := axis.orthogonal()
	var crowded: bool = game.touhou_danmaku != null and game.touhou_danmaku.bullets.size() >= 300
	if crowded:
		game.draw_circle(p, radius * 1.15, Color(INK, tint.a * 0.7))
		game.draw_circle(p, radius * 0.85, tint)
		return
	match String(b.shape):
		"kanako_orb", "kanako_orb_small":
			game.draw_circle(p, radius + 1.6, Color(INK, tint.a * 0.85))
			game.draw_circle(p, radius, tint)
			game.draw_circle(p, radius * 0.55, Color(1, 0.98, 0.95, tint.a * 0.9))
		"kanako_big":
			game.draw_circle(p, radius * 1.55, Color(tint, tint.a * 0.22))
			game.draw_circle(p, radius + 1.8, Color(INK, tint.a * 0.85))
			game.draw_circle(p, radius, tint)
			game.draw_circle(p, radius * 0.62, Color(1, 0.96, 0.96, tint.a * 0.85))
			game.draw_circle(p - Vector2(radius, radius) * 0.25, radius * 0.18, Color(1, 1, 1, tint.a))
		"kanako_almond":
			var outline := PackedVector2Array()
			for i in range(12):
				var t := TAU * i / 12.0
				outline.append(p + axis * cos(t) * radius * 1.7 + side * sin(t) * radius * (0.75 - 0.25 * absf(cos(t))))
			game.draw_colored_polygon(outline, tint)
			outline.append(outline[0])
			game.draw_polyline(outline, Color(INK, tint.a * 0.8), 1.1, true)
			game.draw_line(p - axis * radius * 0.9, p + axis * radius * 0.9, Color(1, 1, 1, tint.a * 0.85), maxf(1.0, radius * 0.3), true)
		"kanako_rice":
			var grain := PackedVector2Array()
			for i in range(10):
				var t := TAU * i / 10.0
				grain.append(p + axis * cos(t) * radius * 1.95 + side * sin(t) * radius * 0.66)
			game.draw_colored_polygon(grain, Color(tint.lerp(WHITE, 0.25), tint.a))
			game.draw_line(p - axis * radius * 0.7, p + axis * radius * 0.7, Color(1, 1, 1, tint.a * 0.9), 1.1, true)
		"kanako_scale":
			var scale_shape := PackedVector2Array([p + axis * radius * 2.1, p + side * radius * 1.0 - axis * radius * 0.2, p - axis * radius * 1.3, p - side * radius * 1.0 - axis * radius * 0.2])
			game.draw_colored_polygon(scale_shape, tint)
			scale_shape.append(scale_shape[0])
			game.draw_polyline(scale_shape, Color(INK, tint.a * 0.8), 1.1, true)
			game.draw_line(p - axis * radius * 0.6, p + axis * radius * 1.2, Color(1, 1, 1, tint.a * 0.75), 1.0, true)
		"kanako_knife":
			var blade := PackedVector2Array([p + axis * radius * 2.6, p + side * radius * 0.66, p - axis * radius * 1.1, p - side * radius * 0.66])
			game.draw_colored_polygon(blade, Color(tint.lerp(WHITE, 0.45), tint.a))
			blade.append(blade[0])
			game.draw_polyline(blade, Color(tint.darkened(0.3), tint.a), 1.2, true)
			game.draw_line(p - axis * radius * 1.0, p - axis * radius * 1.9, Color(tint, tint.a), maxf(1.4, radius * 0.55), true)
		"kanako_ofuda":
			var card := PackedVector2Array([p + axis * radius * 1.9 + side * radius * 0.95, p - axis * radius * 1.9 + side * radius * 0.95, p - axis * radius * 1.9 - side * radius * 0.95, p + axis * radius * 1.9 - side * radius * 0.95])
			game.draw_colored_polygon(card, Color(PAPER, tint.a))
			card.append(card[0])
			game.draw_polyline(card, Color(tint, tint.a), maxf(1.2, radius * 0.3), true)
			game.draw_line(p - axis * radius * 0.9, p + axis * radius * 0.9, Color(tint.darkened(0.15), tint.a), 1.2, true)
			game.draw_circle(p + axis * radius * 0.4, radius * 0.22, Color(tint, tint.a))
		"kanako_light":
			var pulse := 0.85 + 0.15 * sin(float(b.age) * 9.0)
			game.draw_circle(p, radius * 2.1 * pulse, Color(tint, tint.a * 0.18))
			game.draw_circle(p, radius * 1.3, Color(tint, tint.a * 0.55))
			game.draw_circle(p, radius * 0.75, Color(1, 1, 1, tint.a))
		"kanako_shard":
			var splinter := PackedVector2Array([p + axis * radius * 1.9, p + side * radius * 0.5, p - axis * radius * 1.3, p - side * radius * 0.35])
			game.draw_colored_polygon(splinter, tint)
			game.draw_line(p - axis * radius, p + axis * radius * 1.4, Color(WOOD_DARK, tint.a), 1.0, true)
		"kanako_rope", "kanako_shide":
			if String(b.shape) == "kanako_shide":
				var zig := radius * 0.9
				game.draw_circle(p, radius * 1.05, Color(ROPE, tint.a))
				game.draw_polyline(PackedVector2Array([p, p + Vector2(zig, zig * 1.1), p + Vector2(-zig * 0.4, zig * 2.1), p + Vector2(zig * 0.6, zig * 3.0)]), Color(PAPER, tint.a), maxf(1.2, radius * 0.45), true)
			else:
				game.draw_circle(p, radius * 1.2, Color(INK, tint.a * 0.55))
				game.draw_circle(p, radius, tint)
				game.draw_line(p - axis * radius * 0.7 - side * radius * 0.7, p + axis * radius * 0.7 + side * radius * 0.7, Color(ROPE_DARK.darkened(0.2), tint.a), maxf(1.0, radius * 0.35), true)
		"kanako_ice":
			var crystal := PackedVector2Array()
			for i in range(6):
				crystal.append(p + Vector2.from_angle(TAU * i / 6.0 + float(b.age) * 0.8) * radius * 1.6)
			game.draw_colored_polygon(crystal, Color(tint, tint.a * 0.85))
			crystal.append(crystal[0])
			game.draw_polyline(crystal, Color(1, 1, 1, tint.a), 1.1, true)
			game.draw_line(p - side * radius, p + side * radius, Color(1, 1, 1, tint.a * 0.8), 1.0, true)
		"kanako_drop":
			var drop := PackedVector2Array()
			for i in range(12):
				var t := TAU * i / 12.0
				var swell := 1.0 - 0.55 * maxf(0.0, cos(t))
				drop.append(p + axis * cos(t) * radius * 1.8 + side * sin(t) * radius * 0.95 * swell)
			game.draw_colored_polygon(drop, Color(tint, tint.a * 0.9))
			game.draw_circle(p - axis * radius * 0.3 + side * radius * 0.25, radius * 0.22, Color(1, 1, 1, tint.a))
		"kanako_arrow":
			game.draw_line(p - axis * radius * 2.6, p + axis * radius * 1.4, Color(WOOD_DARK, tint.a), maxf(1.4, radius * 0.4), true)
			game.draw_colored_polygon(PackedVector2Array([p + axis * radius * 2.4, p + axis * radius * 1.2 + side * radius * 0.6, p + axis * radius * 1.2 - side * radius * 0.6]), Color(WHITE, tint.a))
			for k in [-1, 1]:
				game.draw_line(p - axis * radius * 2.1, p - axis * radius * 2.9 + side * k * radius * 0.7, Color(tint, tint.a), maxf(1.2, radius * 0.35), true)
		"kanako_snake", "kanako_snake_head", "kanako_dragon_head":
			var head := String(b.shape) != "kanako_snake"
			var body_tint := tint if not head else tint.lerp(WHITE, 0.2)
			game.draw_circle(p, radius * (1.35 if head else 1.15), Color(INK, tint.a * 0.7))
			game.draw_circle(p, radius * (1.2 if head else 1.0), body_tint)
			if not head:
				game.draw_arc(p, radius * 0.7, axis.angle() + PI * 0.6, axis.angle() + PI * 1.4, 8, Color(tint.darkened(0.25), tint.a), 1.0, true)
				game.draw_circle(p + side * radius * 0.35, radius * 0.3, Color("f4c6cf", tint.a * 0.7))
			else:
				for k in [-1, 1]:
					game.draw_circle(p + axis * radius * 0.45 + side * k * radius * 0.45, radius * 0.22, Color(RED if String(b.shape) == "kanako_snake_head" else GOLD, tint.a))
				game.draw_line(p + axis * radius * 1.2, p + axis * radius * 1.9 + side * sin(float(b.age) * 14.0) * radius * 0.3, Color(RED, tint.a), 1.2, true)
				if String(b.shape) == "kanako_dragon_head":
					for k in [-1, 1]:
						game.draw_line(p - axis * radius * 0.2 + side * k * radius * 0.6, p - axis * radius * 1.4 + side * k * radius * 1.1, Color(GOLD, tint.a), 1.3, true)
		_:
			game.draw_circle(p, radius, tint)
	if b.has("morph_flash") and float(b.age) - float(b.morph_flash) < 0.18:
		var burst := (float(b.age) - float(b.morph_flash)) / 0.18
		game.draw_arc(p, radius * (1.2 + burst * 1.6), 0, TAU, 12, Color(1, 1, 1, (1.0 - burst) * 0.8), 1.2, true)
