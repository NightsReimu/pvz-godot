extends RefCounted
class_name TouhouDanmakuRuntime

const SpellDefs = preload("res://scripts/data/touhou_spell_defs.gd")
const MAX_BULLETS := 640
const MAX_BEAMS := 72
const STEP := 1.0 / 60.0
const DANMAKU_BASE_DAMAGE := 22.0
const DANMAKU_PHASE_DAMAGE := 4.0
const DANMAKU_BASE_RADIUS := 6.0
const COLORS := [Color("ef5474"), Color("58ccec"), Color("f6d66c"), Color("9ada74"), Color("c28bed"), Color("f99b62")]

var game: Control
var bullets: Array[Dictionary] = []
var beams: Array[Dictionary] = []
var casts: Array[Dictionary] = []
var next_owner := 0


func _init(owner: Control) -> void:
	game = owner


func clear() -> void:
	bullets.clear()
	beams.clear()
	casts.clear()


func clear_owner(owner: int) -> void:
	for c in casts:
		if int(c.owner) == owner and String(c.kind) == "sakuya_boss":
			game.boss_time_stop_timer = 0.0
			game.boss_time_stop_flash_timer = 0.0
	bullets = bullets.filter(func(b): return int(b.owner) != owner)
	beams = beams.filter(func(b): return int(b.owner) != owner)
	casts = casts.filter(func(c): return int(c.owner) != owner)


func cast(boss: Dictionary) -> Dictionary:
	var card = SpellDefs.card_for(boss, game.current_level)
	if card.is_empty():
		return boss
	if String(boss.kind) in ["prismriver_boss", "youmu_boss"]:
		var bounds: Dictionary = game._prismriver_boss_bounds() if String(boss.kind) == "prismriver_boss" else game._youmu_boss_bounds()
		boss["x"] = clampf(float(boss.get("x", bounds.max_x)), float(bounds.min_x), float(bounds.max_x))
	if not boss.has("touhou_owner"):
		next_owner += 1
		boss["touhou_owner"] = next_owner
	var owner = int(boss.touhou_owner)
	clear_owner(owner)
	var pattern = String(card.pattern)
	var duration := 3.4
	if String(card.origin) == "nonspell" and boss.has("touhou_encounter"):
		duration = 2.2
	if boss.has("touhou_encounter"):
		boss.touhou_encounter.casting = true
	if pattern in ["and_then_none", "life_death"]:
		duration = 9.0
	if pattern == "resurrection_butterfly":
		duration = 24.0
	boss["touhou_card"] = card
	boss["touhou_invulnerable"] = pattern in ["and_then_none", "resurrection_butterfly"]
	boss["touhou_survival_timer"] = duration if bool(boss.touhou_invulnerable) else 0.0
	boss["touhou_cast_remaining"] = duration
	boss["touhou_cast_duration"] = duration
	var center = Vector2(float(boss.get("x", game._boss_anchor_x(String(boss.kind)))), game._row_center_y(int(boss.get("row", 2))) - 12.0)
	var session := {"owner": owner, "kind": String(boss.kind), "card": card, "pattern": pattern, "center": center, "age": 0.0, "next_wave": 0.0, "wave": 0, "duration": duration, "phase": int(boss.get("boss_phase", 0)), "stage": int(boss.get("touhou_encounter", {}).get("index", 0)), "actors": []}
	casts.append(session)
	game._show_banner(String(card.name), 1.8)
	game.effects.append({"shape": String(boss.kind).trim_suffix("_boss") + "_spell_seal", "position": center, "radius": 72.0, "time": 0.45, "duration": 0.45, "color": Color(0.9, 0.86, 1.0, 0.25)})
	if pattern == "wraith_charm":
		game._spawn_youmu_wraiths_from(center, 2 + mini(int(session.phase), 1), int(session.phase))
		session.next_wave = duration + 1.0
	if pattern in ["luna_clock", "clock_corpse"]:
		game.boss_time_stop_timer = 2.2
		game.boss_time_stop_flash_timer = 0.5
	_update_actors(session)
	_emit_wave(session)
	session.wave = 1
	session.next_wave = maxf(float(session.next_wave), 0.62)
	return game._set_rumia_state(boss, String(card.pose), duration)


func update(delta: float) -> void:
	var remaining = maxf(0.0, delta)
	while remaining > 0.00001:
		var dt = minf(remaining, STEP)
		_tick(dt)
		remaining -= dt


func _tick(delta: float) -> void:
	var owners := {}
	var focused_owners := {}
	for boss in game.zombies:
		var surviving = bool(boss.get("touhou_invulnerable", false)) and float(boss.get("touhou_survival_timer", 0.0)) > 0.0
		if boss.has("touhou_owner") and (float(boss.get("health", 0.0)) > 0.0 or surviving):
			owners[int(boss.touhou_owner)] = boss
	for index in range(casts.size() - 1, -1, -1):
		var session = casts[index]
		var owner = int(session.owner)
		if not owners.has(owner):
			clear_owner(owner)
			continue
		var boss: Dictionary = owners[owner]
		if game.boss_time_stop_timer > 0.0 and String(boss.kind) != "sakuya_boss":
			continue
		session.age += delta
		_update_actors(session)
		boss["touhou_cast_remaining"] = maxf(0.0, float(session.duration) - float(session.age))
		if bool(boss.get("touhou_invulnerable", false)):
			boss["touhou_survival_timer"] = boss.touhou_cast_remaining
		if float(session.age) >= float(session.duration):
			boss["touhou_invulnerable"] = false
			if String(session.pattern) == "and_then_none" and boss.has("touhou_encounter"):
				boss.touhou_encounter.depleted = true
			if String(session.pattern) == "resurrection_butterfly":
				boss["health"] = 0.0
			if String(session.pattern) in ["and_then_none", "resurrection_butterfly"]:
				clear_owner(owner)
			elif not beams.any(func(b): return int(b.owner) == owner and b.has("actor_index")):
				# Keep laser emitters visible until their final telegraph and beam end.
				casts.remove_at(index)
			continue
		if float(session.age) >= float(session.next_wave):
			_emit_wave(session)
			session.wave += 1
			var interval := 0.62
			if String(session.pattern) in ["qed", "izuna"]:
				interval = lerpf(0.68, 0.24, float(session.age) / float(session.duration))
			session.next_wave += interval
		if float(session.get("focus_until", 0.0)) > float(session.age):
			focused_owners[owner] = true
	_tick_bullets(delta, owners, focused_owners)
	_tick_beams(delta, owners)


func _point(x: float, y: float) -> Vector2:
	return game.BOARD_ORIGIN + game.board_size * Vector2(x, y)


func _target(origin: Vector2) -> Vector2:
	var best = _point(0.32, 0.5)
	var distance := INF
	for row in game.active_rows:
		for col in range(game.COLS):
			var plant = game._targetable_plant_at(int(row), col)
			if plant == null or float(plant.get("health", 0.0)) <= 0.0:
				continue
			var point: Vector2 = game._cell_center(int(row), col) + Vector2(0, -12)
			if point.distance_squared_to(origin) < distance:
				distance = point.distance_squared_to(origin)
				best = point
	return best


func _bullet(c: Dictionary, origin: Vector2, angle: float, speed: float, color: Color, shape: String = "orb", extra: Dictionary = {}) -> void:
	if bullets.size() >= MAX_BULLETS:
		return
	var intensity = 1.0 + minf(0.3, float(c.get("wave", 0)) * 0.018) + float(c.get("phase", 0)) * 0.05
	var b := {"owner": int(c.owner), "kind": String(c.kind), "position": origin, "velocity": Vector2.from_angle(angle) * speed * intensity, "age": 0.0, "life": 7.0, "radius": DANMAKU_BASE_RADIUS, "damage": DANMAKU_BASE_DAMAGE + float(c.get("phase", 0)) * DANMAKU_PHASE_DAMAGE, "color": color, "shape": shape}
	b.merge(extra, true)
	bullets.append(b)


func _fan(c: Dictionary, origin: Vector2, count: int, angle: float, spread: float, speed: float, color: Color, shape: String = "orb", extra: Dictionary = {}) -> void:
	for i in range(count):
		_bullet(c, origin, angle + (float(i) / maxf(1.0, count - 1) - 0.5) * spread, speed, color, shape, extra)


func _ring(c: Dictionary, origin: Vector2, count: int, rotation: float, speed: float, color: Color, shape: String = "orb", extra: Dictionary = {}) -> void:
	for i in range(count):
		_bullet(c, origin, rotation + TAU * i / count, speed, color, shape, extra)


func _beam(c: Dictionary, from: Vector2, to: Vector2, color: Color, delay: float = 0.7, width: float = 12.0, extra: Dictionary = {}) -> void:
	if beams.size() < MAX_BEAMS:
		var beam := {"owner": int(c.owner), "kind": String(c.kind), "from": from, "to": to, "color": color, "age": 0.0, "delay": delay, "duration": 0.38, "width": width, "damage": 68.0 + float(c.phase) * 8.0, "hits": []}
		beam.merge(extra, true)
		beams.append(beam)


func _actor(c: Dictionary, index: int, kind: String, position: Vector2, pose: String = "shift") -> void:
	if index >= c.actors.size():
		c.actors.append({"kind": kind})
	var actor: Dictionary = c.actors[index]
	actor["position"] = position
	actor["animation_time"] = float(c.age)
	actor["youmu_wraith_age"] = float(c.age)
	actor["rumia_state"] = pose
	actor["frame"] = game._boss_frame_index_for_kind(actor)


func _update_actors(c: Dictionary) -> void:
	var turn = float(c.age) * 0.25 / 0.62
	match String(c.pattern):
		"france", "holland", "london", "shanghai", "nonspell_doll_fan":
			for i in range(5):
				_actor(c, i, "alice_doll_zombie", _point(0.72 + 0.12 * sin(i + turn), 0.12 + i * 0.19))
		"shikigami_chen", "shikigami_ran":
			var familiar = _point(0.62 + 0.2 * cos(turn * 3), 0.5 + 0.34 * sin(turn * 3))
			_actor(c, 0, "chen_boss" if String(c.pattern) == "shikigami_chen" else "ran_boss", familiar)
		"four_of_a_kind":
			for i in range(3):
				_actor(c, i, "flandre_boss", _point(0.76 + 0.05 * ((i + 1) % 2), 0.18 + i * 0.32) + Vector2(0, sin(float(c.age) * 2.0 + i) * 5), "clones")
		"two_hundred_yojana":
			_actor(c, 0, "youmu_half_ghost", Vector2(c.center) + Vector2(-36, -48 + sin(float(c.age) * 2.0) * 6))


func _emit_wave(c: Dictionary) -> void:
	var p = String(c.pattern)
	if p.begins_with("nonspell_"):
		_emit_nonspell(c)
		return
	var origin = Vector2(c.center)
	var wave = int(c.wave)
	var turn = float(wave) * 0.25
	var aimed = (_target(origin) - origin).angle()
	var red = COLORS[0]
	var blue = COLORS[1]
	var gold = COLORS[2]
	var green = COLORS[3]
	var violet = COLORS[4]
	match p:
		"night_bird":
			_ring(c, origin, 28, turn, 120, red)
			_fan(c, origin, 7, aimed, 0.5, 205, blue)
		"demarcation":
			for side in [-1, 1]:
				_fan(c, origin + Vector2(0, side * 44), 17, PI + side * 0.42, 1.3, 160, red if side < 0 else blue)
		"fairy_aim", "spring_nonspell":
			_fan(c, origin, 15 if p == "spring_nonspell" else 9, aimed, 1.4, 175, gold if p == "spring_nonspell" else green)
			if p == "spring_nonspell":
				_ring(c, origin, 24, turn, 108, red)
		"library_orbs":
			_ring(c, origin, 22, turn, 132, red)
			_fan(c, origin, 5, aimed, 0.35, 210, blue)
		"cold_nonspell":
			_fan(c, origin, 13, PI + sin(turn) * 0.2, 1.7, 130, blue, "ice")
		"icicle":
			for side in [-1, 1]:
				_fan(c, origin + Vector2(-40, side * 108), 12, PI - side * 0.55, 0.55, 155, blue, "ice")
			_fan(c, origin, 5, aimed, 0.24, 190, gold)
		"perfect_freeze":
			_ring(c, origin, 38, turn, 175, COLORS[wave % COLORS.size()], "ice", {"freeze_at": 0.55, "thaw_at": 1.5, "thaw_angle": turn + 0.65})
		"blizzard":
			for i in range(9):
				var emit = origin + Vector2(-45 - (i % 3) * 30, sin(i * 2.4 + turn) * 140)
				_fan(c, emit, 3, PI, 0.9, 140 + i * 5, blue, "ice")
		"flower", "rainbow", "typhoon":
			for petal in range(6):
				_fan(c, origin, 7, turn + TAU * petal / 6, 0.38 if p != "rainbow" else 0.65, 150, COLORS[petal], "orb", {"angular_speed": 0.3 if p == "typhoon" else 0.0})
		"rainbow_rain":
			for i in range(18):
				_bullet(c, _point(0.2 + i * 0.044, 0.03), PI * 0.5 + sin(i + turn) * 0.4, 165, COLORS[i % 6])
		"agni":
			for i in range(3):
				_ring(c, origin, 15, turn + i * 0.16, 100 + i * 32, red, "orb", {"angular_speed": 0.16})
		"silent_selene":
			for i in range(3):
				_ring(c, origin, 22, -turn + i * 0.13, 110 + i * 24, blue, "orb", {"angular_speed": -0.18})
		"royal_flare":
			_ring(c, origin, 48, turn, 165, gold)
			_ring(c, origin, 48, -turn + 0.1, 195, red)
		"philosophers_stone":
			for element in range(5):
				var stone = origin + Vector2.from_angle(TAU * element / 5 + turn) * 92
				_ring(c, stone, 15, turn + element, 120 + element * 12, COLORS[element])
		"trilithon", "cromlech":
			for i in range(3):
				var pillar = origin + Vector2(-75, (i - 1) * 105)
				_fan(c, pillar, 9, PI, 1.5, 100 + wave * 7, gold, "orb", {"radius": 9.0})
			if p == "cromlech":
				_ring(c, origin, 26, -turn, 185, red)
		"mercury":
			for side in [-1, 1]:
				_fan(c, origin + Vector2(-35, side * 96), 22, PI, 2.5, 120, blue if side < 0 else gold, "orb", {"angular_speed": side * 0.32})
		"misdirection", "eternal_meek":
			_fan(c, origin, 17, aimed + sin(turn) * 0.3, 1.3 if p == "eternal_meek" else 0.65, 270 if p == "eternal_meek" else 205, blue, "knife")
		"clock_corpse", "luna_clock", "marionette":
			var stopped = p != "marionette"
			var knife_origin = origin + Vector2(-wave * 22, sin(wave * 1.6) * 115)
			_ring(c, knife_origin, 22, turn, 170, blue, "knife", {"time_stopped": stopped, "redirect_at": 0.65 if p == "marionette" else 0.0, "aim_point": _target(knife_origin)})
		"david":
			var seal = _point(0.68, 0.5)
			for i in range(6):
				var a = seal + Vector2.from_angle(TAU * i / 6 + turn) * 150
				var b = seal + Vector2.from_angle(TAU * (i + 2) / 6 + turn) * 150
				_beam(c, a, b, red)
				_fan(c, a, 3, PI, 0.6, 130, red)
		"scarlet_nether", "red_magic":
			_ring(c, origin, 36, turn, 145, red, "orb", {"angular_speed": -0.2 if p == "scarlet_nether" else 0.2})
			if p == "red_magic":
				_ring(c, origin, 24, -turn, 215, blue)
		"vlad":
			for i in range(5):
				_fan(c, _point(0.82, 0.1 + i * 0.2), 8, PI, 0.9, 115 + i * 15, red)
		"scarlet_shoot":
			_fan(c, origin, 23, aimed, 1.8, 235, red, "orb", {"radius": 8.0})
		"cranberry":
			for side in [0.12, 0.88]:
				var trap = _point(0.58, side)
				_fan(c, trap, 11, (_target(trap) - trap).angle(), 0.85, 185, red if side < 0.5 else blue)
		"laevatein", "past_clock":
			var angle = PI - 0.9 + wave * (0.36 if p == "laevatein" else 0.68)
			_beam(c, origin, origin + Vector2.from_angle(angle) * game.board_size.x, red, 0.7, 23)
			if p == "past_clock":
				_beam(c, origin, origin + Vector2.from_angle(angle + PI) * game.board_size.x, blue, 0.7, 16)
		"four_of_a_kind":
			for i in range(4):
				var clone = origin if i == 0 else Vector2(c.actors[i - 1].position)
				_fan(c, clone, 11, (_target(clone) - clone).angle(), 1.45, 165, COLORS[i])
		"kagome", "maze", "starbow":
			var count := 40
			var gap = 2.1 + turn
			for i in range(count):
				var angle = TAU * i / count
				if p == "maze" and absf(angle_difference(angle, gap)) < 0.24:
					continue
				var start = _point(0.6, 0.5) + Vector2.from_angle(angle + turn) * (195 if p == "kagome" else 32)
				_bullet(c, start, angle + turn + (PI if p == "kagome" else 0.0), 110 if p == "kagome" else 175, COLORS[i % 6] if p == "starbow" else red, "star" if p == "starbow" else "orb", {"angular_speed": 0.17 if p == "maze" else 0.0})
		"catadioptric":
			_fan(c, origin, 15, PI + (0.7 if wave % 2 == 0 else -0.7), 1.2, 250, violet, "orb", {"bounces": 2, "radius": 7.0})
		"and_then_none":
			var emit = _point(0.2 + fmod(wave * 0.19, 0.6), 0.1 if wave % 2 == 0 else 0.9)
			if float(c.age) < 4.5:
				_fan(c, emit, 9, (_target(emit) - emit).angle(), 0.75, 195, red)
			else:
				_ring(c, emit, 34, turn, 165, blue)
		"qed", "izuna":
			_ring(c, origin, 40 + wave * 2, turn, 100 + wave * 9, red if p == "qed" else gold)
		"lingering_cold", "wither":
			_ring(c, origin, 30, turn, 125, blue, "ice")
			if p == "wither":
				_fan(c, origin, 12, aimed, 1.0, 195, violet)
		"phoenix_egg", "seiman", "tianxian", "shijie", "blue_red_oni", "bishamonten":
			var path = _point(0.67 + 0.15 * sin(wave * 1.9), 0.5 + 0.32 * cos(wave * 1.9))
			_ring(c, path, 24, turn, 150, red if wave % 2 == 0 else blue)
			if p in ["tianxian", "bishamonten", "shijie"]:
				_fan(c, path, 9, (_target(path) - path).angle(), 0.8, 220, gold)
			if p in ["seiman", "blue_red_oni"]:
				_ring(c, _point(0.8, 0.5) - (path - _point(0.8, 0.5)), 18, -turn, 170, blue)
		"france", "holland", "london", "shanghai":
			for i in range(5):
				var doll = Vector2(c.actors[i].position)
				if p == "shanghai":
					_beam(c, doll, _point(0.05, 0.12 + i * 0.19), violet, 0.85, 10, {"actor_index": i})
				elif p == "holland":
					_ring(c, doll, 12, -turn, 115, red)
				elif p == "london":
					_fan(c, doll, 7, PI + sin(turn + i) * 0.5, 0.5, 135, violet)
				else:
					_fan(c, doll, 7, (_target(doll) - doll).angle(), 0.8, 160, blue)
		"phantom_dinning", "guarneri", "prism_concerto", "concerto_grosso":
			for i in range(1 if p == "guarneri" else 3):
				var instrument = _point(0.82, 0.25 + i * 0.25)
				_fan(c, instrument, 13 if p == "concerto_grosso" else 9, PI + sin(turn + i) * 0.4, 1.6, 135 + i * 30, COLORS[i], "note", {"angular_speed": 0.12 * (i - 1)})
		"two_hundred_yojana":
			if wave % 2 == 0:
				var ghost = Vector2(c.actors[0].position)
				_fan(c, ghost, 7, aimed, 2.1, 300, blue, "orb", {"radius": 12.0, "cuttable": true})
				c["focus_until"] = float(c.age) + 0.8
				_beam(c, origin, _target(origin), blue, 0.8, 18, {"sword_cut": true, "phase": c.phase})
		"human_realm":
			c["focus_until"] = float(c.age) + 0.3
			for i in range(17):
				var below = _point(0.06 + i * 0.055, 0.97)
				_bullet(c, below, -PI * 0.5 + sin(i * 0.8 + turn) * 0.12, 105 + (i % 3) * 12, red, "rice")
			_fan(c, origin, 17, aimed, 1.5, 190, blue, "rice")
		"five_signs":
			c["focus_until"] = float(c.age) + 0.24
			for i in range(5):
				_fan(c, origin, 11, aimed + (i - 2) * 0.035, 1.7, 130 + i * 24, blue if i % 2 == 0 else gold, "rice")
		"immeasurable_kalpas":
			c["focus_until"] = float(c.age) + 0.16
			for i in range(3):
				_ring(c, origin, 24, turn + i * 0.08, 155 + i * 28, blue if i % 2 == 0 else green, "rice")
			game.effects.append({"shape": "youmu_cross_slash", "position": origin, "radius": 150.0, "time": 0.3, "duration": 0.3, "color": Color(0.7, 0.95, 1, 0.6)})
		"gaki", "animal_realm":
			var target = _target(origin)
			if wave % 2 == 0:
				var slash_target = _point(0.03, clampf((target.y - game.BOARD_ORIGIN.y) / game.board_size.y, 0.05, 0.95))
				_beam(c, origin, slash_target, blue, 0.8, 9)
				game.effects.append({"shape": "youmu_half_ghost", "position": origin + Vector2(18, -48), "radius": 42.0, "time": 0.55, "duration": 0.55, "color": Color(0.7, 0.95, 1, 0.24)})
			else:
				var waves = 2
				for i in range(waves):
					_fan(c, origin + Vector2(-i * 22, (i - waves / 2.0) * 35), 12, aimed, 1.8, 145 + i * 18, blue, "knife", {"freeze_at": 0.3, "thaw_at": 0.7, "thaw_angle": 0.0})
		"wraith_charm":
			pass
		"lost_soul", "mortal_butterfly", "swallowtail", "hirokawa", "sumizome", "resurrection_butterfly":
			var color = blue if p == "lost_soul" else red
			var shape = "petal" if p == "sumizome" else "butterfly"
			var count = 24 + (wave % 4) * 4
			_ring(c, origin, count, turn, 105 if p == "hirokawa" else 140, color, shape, {"angular_speed": -0.18 if p == "swallowtail" else 0.12})
			if p in ["mortal_butterfly", "resurrection_butterfly"]:
				_fan(c, origin, 12, aimed, 1.9, 195, blue, "butterfly")
		"senko", "twelve_generals", "princess_tenko", "buddhist", "contact", "kokkuri":
			var count = 12 if p == "twelve_generals" else 8
			for i in range(count):
				var angle = TAU * i / count + turn
				var emit = origin + Vector2.from_angle(angle) * (80 if p == "princess_tenko" else 44)
				_fan(c, emit, 4, PI + sin(angle) * 0.8, 0.3, 150, gold, "ofuda", {"angular_speed": -0.22 if p in ["buddhist", "kokkuri"] else 0.0})
		"fox_laser", "light_dark_mesh":
			for i in range(4):
				var top = _point(0.26 + i * 0.2, 0.04)
				var bottom = _point(0.15 + fmod(i * 0.2 + wave * 0.08, 0.8), 0.96)
				_beam(c, top, bottom, gold if p == "fox_laser" else violet)
		"charming_siege", "dream_reality", "human_youkai", "life_death", "danmaku_barrier":
			var target = _target(origin)
			var center = _point(0.5, 0.5) if p == "life_death" else target
			for side in range(4):
				var angle = side * PI * 0.5 + turn * 0.15
				var emit = center + Vector2.from_angle(angle) * (200 if p != "danmaku_barrier" else 240)
				_fan(c, emit, 9, angle + PI, 1.2, 100 if p == "danmaku_barrier" else 145, gold if p == "charming_siege" else violet, "ofuda", {"freeze_at": 0.15, "thaw_at": 0.85, "thaw_angle": 0.0} if p == "danmaku_barrier" else {})
		"shikigami_chen", "shikigami_ran":
			var familiar = Vector2(c.actors[0].position)
			_ring(c, familiar, 26, turn, 155, gold, "ofuda")
			_fan(c, origin, 9, aimed, 1.3, 180, violet)
		"motion_stillness":
			_ring(c, origin, 32, turn, 180, violet, "orb", {"freeze_at": 0.5, "thaw_at": 1.25, "thaw_angle": PI * 0.5})
			_fan(c, origin, 9, aimed, 1.3, 105, red)
		"straight_curve":
			_fan(c, origin, 18, PI, 1.9, 165, blue)
			_fan(c, origin, 18, PI - 0.7, 1.9, 165, red, "orb", {"angular_speed": 0.55})
		"spiriting_away":
			var gap = _point(0.7, 0.15 + fmod(wave * 0.23, 0.7))
			_actor(c, 0, "yukari_boss", gap, "gap")
			_ring(c, gap, 34, turn, 150, violet, "ofuda")
		"zen_butterfly", "double_butterfly":
			for side in [-1, 1]:
				var butterfly_origin = origin + Vector2(-60, side * 88)
				_fan(c, butterfly_origin, 24, PI + side * turn, 2.4, 145, violet if side < 0 else blue, "butterfly", {"angular_speed": side * 0.24})
			if p == "zen_butterfly":
				_beam(c, origin, origin + Vector2.from_angle(PI + turn * 0.6) * game.board_size.x, red, 0.85)
		"wriggle_firefly", "wriggle_comet":
			_ring(c, origin, 28 + wave * 2, turn, 112 + wave * 4, COLORS[2], "orb", {"angular_speed": 0.18})
			_fan(c, origin, 7 + wave % 3, aimed, 0.7, 185, COLORS[3], "butterfly")
		"wriggle_swarm", "wriggle_night_swarm":
			for i in range(5 + int(c.phase)):
				var emit = origin + Vector2(-50.0 + float(i) * 22.0, sin(turn + i) * 110.0)
				_fan(c, emit, 8 + wave % 4, aimed + sin(i + turn) * 0.45, 1.5, 150 + wave * 3, COLORS[4], "butterfly")
		"wriggle_storm", "wriggle_little_bug":
			_ring(c, origin, 42 + wave * 3, -turn, 148 + wave * 5, COLORS[4], "butterfly", {"angular_speed": -0.32})
			_fan(c, origin, 11, aimed, 1.8, 205, COLORS[0], "orb")
		"wriggle_final":
			_ring(c, origin, 56 + wave * 4, turn, 168 + wave * 6, COLORS[2], "butterfly", {"angular_speed": 0.42})
			_fan(c, origin, 15, aimed, 2.2, 230, COLORS[0], "orb")
		"mystia_song":
			# Broad musical waves with a narrow aimed chorus, matching Mystia's song cards.
			_ring(c, origin, 24 + wave * 2, turn * 0.8, 112 + wave * 5, COLORS[4], "note", {"angular_speed": 0.16})
			_fan(c, origin, 8 + int(c.phase), aimed, 0.9, 196 + wave * 4, COLORS[0], "note")
		"mystia_nightblind":
			for side in [-1, 1]:
				var emit: Vector2 = origin + Vector2(-46.0, side * (76.0 + wave * 5.0))
				_fan(c, emit, 12 + wave % 4, (_target(emit) - emit).angle(), 1.3, 152 + wave * 4, COLORS[4], "note", {"angular_speed": side * 0.22})
			_ring(c, origin, 18, -turn, 132, COLORS[1], "orb")
		"mystia_flight":
			var wing_span := 74.0 + 12.0 * sin(float(wave) * 0.7)
			for side in [-1, 1]:
				var wing_origin: Vector2 = origin + Vector2(-28.0, side * wing_span)
				_fan(c, wing_origin, 10 + int(c.phase), (_target(wing_origin) - wing_origin).angle(), 0.78, 178 + wave * 6, COLORS[2], "butterfly")
			_ring(c, origin, 30, turn, 128, COLORS[3], "butterfly", {"angular_speed": -0.2})
		"mystia_crescendo":
			_ring(c, origin, 36 + wave * 3, turn, 148 + wave * 5, COLORS[0], "note", {"angular_speed": 0.28})
			_ring(c, origin, 24 + wave * 2, -turn * 1.2, 196 + wave * 7, COLORS[4], "butterfly", {"angular_speed": -0.18})
			_fan(c, origin, 13 + int(c.phase) * 2, aimed, 2.0, 220 + wave * 5, COLORS[2], "note")
		"mystia_finale":
			_ring(c, origin, 52 + wave * 4, turn, 164 + wave * 7, COLORS[2], "note", {"angular_speed": 0.36})
			_ring(c, origin, 42 + wave * 3, -turn, 204 + wave * 8, COLORS[0], "butterfly", {"angular_speed": -0.32})
			_fan(c, origin, 18 + int(c.phase) * 2, aimed, 2.35, 238 + wave * 4, COLORS[4], "note")


func _emit_nonspell(c: Dictionary) -> void:
	var origin := Vector2(c.center)
	var wave := int(c.wave)
	var stage := int(c.get("stage", 0))
	var turn := wave * 0.22 + stage * 0.17
	var aim := (_target(origin) - origin).angle()
	var extra := mini(4, stage)
	match String(c.pattern):
		"nonspell_dark_fan":
			for side in [-1, 1]:
				_fan(c, origin + Vector2(0, side * 32), 7 + extra, aim + side * 0.25, 0.75, 140, COLORS[0] if side < 0 else COLORS[1])
		"nonspell_ice_fan":
			for layer in range(3):
				_fan(c, origin, 5 + extra, PI + sin(turn) * 0.35, 1.4, 110 + layer * 30, COLORS[1], "ice")
		"nonspell_rainbow_spiral":
			for petal in range(6):
				_fan(c, origin, 3 + extra, turn + petal * TAU / 6, 0.28, 145, COLORS[petal])
		"nonspell_element_orbits":
			for element in range(5):
				var emit := origin + Vector2.from_angle(turn + element * TAU / 5) * 56
				_fan(c, emit, 4 + extra, (_target(emit) - emit).angle(), 0.65, 125 + element * 12, COLORS[element])
		"nonspell_knife_fan":
			for side in [-1, 1]:
				_fan(c, origin + Vector2(-20, side * 50), 9 + extra, aim + side * sin(turn) * 0.3, 1.1, 205, COLORS[1], "knife", {"redirect_at": 0.75, "aim_point": _target(origin)})
		"nonspell_scarlet_crossfire":
			for side in [-1, 1]:
				var emit := origin + Vector2(-55, side * (65 + wave * 12))
				_fan(c, emit, 10 + extra, (_target(emit) - emit).angle(), 1.4, 180, COLORS[0], "orb", {"radius": 7.0})
			if stage >= 2:
				_fan(c, origin, 5, aim, 0.5, 230, COLORS[1])
		"nonspell_crystal_fan":
			for layer in range(3):
				_fan(c, origin, 9 + extra, PI + sin(turn + layer) * 0.32, 1.9, 130 + layer * 35, COLORS[(stage + layer) % 6], "star")
		"nonspell_snow_curtain":
			for i in range(12 + extra):
				_bullet(c, _point(0.15 + i * 0.05, 0.02), PI * 0.5 + sin(i + turn) * 0.22, 100 + (i % 3) * 20, COLORS[1], "ice")
			_fan(c, origin, 7, aim, 0.7, 145, COLORS[4])
		"nonspell_shikigami_crossfire":
			for side in [-1, 1]:
				var emit := origin + Vector2(-40 - wave * 14, side * 85)
				_fan(c, emit, 8 + extra, PI + side * (0.4 + sin(turn) * 0.2), 1.15, 175, COLORS[0] if side < 0 else COLORS[1], "ofuda")
		"nonspell_doll_fan":
			for actor in c.actors:
				var emit := Vector2(actor.position)
				_fan(c, emit, 3 + extra, PI + sin(turn) * 0.2, 0.65, 140, COLORS[1])
		"nonspell_note_crossfire":
			for voice in range(3):
				_fan(c, _point(0.8, 0.2 + voice * 0.3), 7 + extra, PI + sin(turn + voice) * 0.25, 1.2, 130 + voice * 28, COLORS[voice], "note", {"angular_speed": (voice - 1) * 0.12})
		"nonspell_sword_fan":
			_fan(c, origin, 14 + extra, aim, 1.7, 175, COLORS[1], "rice")
			_fan(c, origin + Vector2(10, -48), 7 + extra, aim + sin(turn) * 0.4, 0.9, 125, COLORS[3])
		"nonspell_butterfly_fan":
			for side in [-1, 1]:
				_fan(c, origin + Vector2(0, side * 30), 12 + extra, PI + side * 0.35, 1.7, 125, COLORS[0] if side < 0 else COLORS[1], "butterfly", {"angular_speed": side * 0.2})
		"nonspell_fox_spiral":
			for tail in range(9):
				_fan(c, origin, 3 + extra, turn + tail * TAU / 9, 0.16, 165, COLORS[2], "ofuda", {"angular_speed": 0.16})
		"nonspell_gap_crossfire":
			for side in [-1, 1]:
				var emit := _point(0.62, 0.12 if side < 0 else 0.88)
				_fan(c, emit, 12 + extra, (_target(emit) - emit).angle(), 1.4, 160, COLORS[4], "ofuda", {"angular_speed": side * 0.22})
			if stage >= 4 and wave % 2 == 0:
				_beam(c, origin, _target(origin), COLORS[0], 0.9, 9)
		"nonspell_wriggle_night_swarm":
			_ring(c, origin, 24 + extra * 3, turn, 118 + stage * 16, COLORS[3], "butterfly", {"angular_speed": 0.24})
			_fan(c, origin, 8 + extra, aim, 1.4, 170 + stage * 12, COLORS[4], "orb")
		"nonspell_mystia_song":
			_fan(c, origin, 10 + extra * 2, aim, 1.6, 164 + stage * 12, COLORS[0], "note")
			_ring(c, origin, 22 + extra * 2, turn, 108 + stage * 12, COLORS[4], "note", {"angular_speed": 0.18})


func _tick_bullets(delta: float, owners: Dictionary, focused_owners: Dictionary = {}) -> void:
	var board: Rect2 = Rect2(game.BOARD_ORIGIN, game.board_size)
	for index in range(bullets.size() - 1, -1, -1):
		var b = bullets[index]
		if not owners.has(int(b.owner)):
			bullets.remove_at(index)
			continue
		if game.boss_time_stop_timer > 0.0:
			continue
		var before = Vector2(b.position)
		b["slowed"] = focused_owners.has(int(b.owner))
		var motion_delta = delta * (0.35 if bool(b.slowed) else 1.0)
		b.age += delta
		var age = float(b.age)
		var frozen = b.has("freeze_at") and age >= float(b.freeze_at) and age < float(b.thaw_at)
		if not frozen:
			if b.has("thaw_at") and age >= float(b.thaw_at) and not bool(b.get("thawed", false)):
				b.velocity = Vector2(b.velocity).rotated(float(b.get("thaw_angle", 0.0)))
				b["thawed"] = true
			if float(b.get("redirect_at", 0.0)) > 0.0 and age >= float(b.redirect_at) and not bool(b.get("redirected", false)):
				b.velocity = (Vector2(b.aim_point) - before).normalized() * Vector2(b.velocity).length()
				b["redirected"] = true
			b.velocity = Vector2(b.velocity).rotated(float(b.get("angular_speed", 0.0)) * motion_delta)
			b.position = before + Vector2(b.velocity) * motion_delta
		b["frozen"] = frozen
		var point = Vector2(b.position)
		if int(b.get("bounces", 0)) > 0 and (point.y < board.position.y + 5 or point.y > board.end.y - 5):
			b.position.y = clampf(point.y, board.position.y + 5, board.end.y - 5)
			b.velocity.y *= -1
			b.bounces -= 1
		var hit = _hit_plant_segment(before, Vector2(b.position), float(b.radius), float(b.damage), [])
		if hit or age >= float(b.life) or not board.grow(240).has_point(Vector2(b.position)):
			bullets.remove_at(index)


func _tick_beams(delta: float, owners: Dictionary) -> void:
	for index in range(beams.size() - 1, -1, -1):
		var beam = beams[index]
		if not owners.has(int(beam.owner)):
			beams.remove_at(index)
			continue
		if game.boss_time_stop_timer > 0.0:
			continue
		if beam.has("actor_index"):
			for c in casts:
				if int(c.owner) == int(beam.owner) and int(beam.actor_index) < c.actors.size():
					beam.from = c.actors[int(beam.actor_index)].position
					break
		beam.age += delta
		if float(beam.age) >= float(beam.delay):
			if bool(beam.get("sword_cut", false)) and not bool(beam.get("cut_done", false)):
				_cut_spirit_bullets(beam)
				beam["cut_done"] = true
			_hit_plant_segment(beam.from, beam.to, float(beam.width) * 0.5, float(beam.damage), beam.hits, false)
		if float(beam.age) >= float(beam.delay) + float(beam.duration):
			beams.remove_at(index)


func _cut_spirit_bullets(slash: Dictionary) -> void:
	# Only the half-ghost's existing large bullets belong to this sword pattern.
	var cut: Array[Dictionary] = []
	for index in range(bullets.size() - 1, -1, -1):
		var b = bullets[index]
		if int(b.owner) == int(slash.owner) and bool(b.get("cuttable", false)) and Vector2(b.position).distance_to(slash.from) <= 200.0:
			cut.append(b)
			bullets.remove_at(index)
	for b in cut:
		_ring(slash, b.position, 10, Vector2(b.velocity).angle(), 160, Color(b.color), "rice", {"sword_fragment": true})
		game.effects.append({"shape": "youmu_cross_slash", "position": b.position, "radius": 65.0, "time": 0.28, "duration": 0.28, "color": Color(0.8, 1, 1, 0.65)})


func _hit_plant_segment(from: Vector2, to: Vector2, radius: float, damage: float, hit_cells: Array, stop_at_first: bool = true) -> bool:
	var nearest := Vector2i(-1, -1)
	var distance := INF
	for row in game.active_rows:
		for col in range(game.COLS):
			var cell := Vector2i(int(row), col)
			if hit_cells.has(cell):
				continue
			var plant = game._targetable_plant_at(cell.x, cell.y)
			if plant == null or float(plant.get("health", 0.0)) <= 0.0:
				continue
			var center: Vector2 = game._cell_center(cell.x, cell.y) + Vector2(0, -12)
			var closest = Geometry2D.get_closest_point_to_segment(center, from, to)
			if closest.distance_squared_to(center) > pow(radius + minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * 0.22, 2):
				continue
			if not stop_at_first:
				game._damage_plant_cell(cell.x, cell.y, damage)
				hit_cells.append(cell)
			elif from.distance_squared_to(center) < distance:
				distance = from.distance_squared_to(center)
				nearest = cell
	if nearest.x >= 0:
		game._damage_plant_cell(nearest.x, nearest.y, damage)
		return true
	return not hit_cells.is_empty()


func draw() -> void:
	var board: Rect2 = Rect2(game.BOARD_ORIGIN, game.board_size)
	var outline = PackedVector2Array([board.position, Vector2(board.end.x, board.position.y), board.end, Vector2(board.position.x, board.end.y)])
	for c in casts:
		var cast_age = float(c.age)
		var pulse_window = clampf(1.0 - (float(c.next_wave) - cast_age) / 0.38, 0.0, 1.0)
		var pulse_center = Vector2(c.center) + Vector2(0, 34)
		var pulse_radius = 42.0 + pulse_window * 34.0
		var pulse_alpha = 0.08 + pulse_window * 0.18
		game.draw_circle(pulse_center, pulse_radius, Color(1.0, 0.16, 0.18, pulse_alpha), false, 2.0, true)
		if pulse_window > 0.65:
			var warning_angle = (cast_age * 2.7) - PI * 0.5
			game.draw_arc(pulse_center, pulse_radius + 10.0, warning_angle, warning_angle + PI * 0.54, 22, Color(1.0, 0.72, 0.28, 0.78), 3.0, true)
		if float(c.get("focus_until", 0.0)) > float(c.age):
			var center = Vector2(c.center)
			for i in range(8):
				var angle = TAU * i / 8.0 + float(c.age) * 1.4
				var petal = center + Vector2.from_angle(angle) * 68.0
				game.draw_circle(petal, 3.5, Color(1, 0.72, 0.85, 0.75))
				game.draw_line(petal, petal - Vector2.from_angle(angle + 0.5) * 10, Color(1, 0.8, 0.9, 0.4), 2, true)
			game.draw_arc(center, 56, float(c.age) * -2, float(c.age) * -2 + PI * 1.5, 40, Color(0.7, 0.95, 1, 0.55), 1.5, true)
		for actor in c.actors:
			if String(actor.kind) == "alice_doll_zombie":
				game._draw_alice_doll_zombie(actor.position, actor)
				continue
			if String(actor.kind) == "youmu_half_ghost":
				game._draw_youmu_wraith(Vector2(actor.position) + Vector2(0, 12), actor)
				continue
			var texture: Texture2D = game._try_get_boss_frame_texture(String(actor.kind), int(actor.frame))
			if texture != null:
				var dimensions = texture.get_size() * (156.0 / maxf(texture.get_height(), 1.0))
				game.draw_texture_rect(texture, Rect2(Vector2(actor.position) - dimensions * 0.5, dimensions), false, Color(1, 1, 1, 0.86))
			else:
				game.draw_circle(actor.position, 10, COLORS[4])
	for beam in beams:
		var clipped = Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([beam.from, beam.to]), outline)
		if clipped.is_empty() or clipped[0].size() < 2:
			continue
		var from: Vector2 = clipped[0][0]
		var to: Vector2 = clipped[0][1]
		var active = float(beam.age) >= float(beam.delay)
		var color = Color(beam.color)
		color.a = 0.75 if active else 0.45
		if active and bool(beam.get("sword_cut", false)):
			game._draw_effect_blade(to, from, float(beam.width) * 0.65, color, Color(0.95, 1, 1, 0.95))
			continue
		game.draw_line(from, to, Color(0.08, 0.05, 0.13, 0.65), float(beam.width) + 3 if active else 4, true)
		game.draw_line(from, to, color, float(beam.width) if active else 1.5, true)
		if active:
			game.draw_line(from, to, Color(1, 0.96, 0.9, 0.9), 3.0, true)
		else:
			var progress = clampf(float(beam.age) / float(beam.delay), 0.0, 1.0)
			game.draw_arc(from, 10, -PI * 0.5, -PI * 0.5 + TAU * progress, 24, color, 2, true)
			game.draw_circle(to, float(beam.width) * 0.5 + 4, color, false, 1.5, true)
	for b in bullets:
		var point = Vector2(b.position)
		var color = Color(b.color)
		var radius = float(b.radius)
		if not board.grow(-radius * 2).has_point(point):
			continue
		if String(b.shape) in ["orb", "butterfly", "petal", "note"]:
			game.draw_circle(point, radius + 1.7, Color(0.08, 0.05, 0.13, 0.86))
		var axis = Vector2(b.velocity).normalized()
		if axis.is_zero_approx():
			axis = Vector2.LEFT
		var normal = axis.orthogonal()
		match String(b.shape):
			"knife":
				var polygon = PackedVector2Array([point + axis * radius * 2, point + normal * radius * 0.65, point - axis * radius * 1.5, point - normal * radius * 0.65])
				_draw_bullet_polygon(polygon, color)
				game.draw_line(point - axis * radius, point + axis * radius, Color.WHITE, 1, true)
			"ice":
				var polygon = PackedVector2Array([point + axis * radius * 1.6, point + axis * radius * 0.3 + normal * radius * 0.8, point - axis * radius * 1.2 + normal * radius * 0.55, point - axis * radius * 1.2 - normal * radius * 0.55, point + axis * radius * 0.3 - normal * radius * 0.8])
				_draw_bullet_polygon(polygon, color)
				game.draw_line(point - axis * radius, point + axis * radius * 1.2, Color(1, 1, 1, 0.8), 1, true)
			"ofuda":
				var polygon = PackedVector2Array([point + axis * radius * 1.45 + normal * radius * 0.7, point - axis * radius * 1.45 + normal * radius * 0.7, point - axis * radius * 1.45 - normal * radius * 0.7, point + axis * radius * 1.45 - normal * radius * 0.7])
				_draw_bullet_polygon(polygon, Color(1, 0.97, 0.88))
				for offset in [-0.6, 0.0, 0.6]:
					var mark = point + axis * radius * offset
					game.draw_line(mark - normal * radius * 0.45, mark + normal * radius * 0.45, color.darkened(0.2), 1.7, true)
			"rice":
				var polygon := PackedVector2Array()
				for i in range(12):
					var angle = TAU * i / 12.0
					polygon.append(point + axis * cos(angle) * radius * 1.5 + normal * sin(angle) * radius * 0.6)
				_draw_bullet_polygon(polygon, color)
				game.draw_line(point - axis * radius * 0.65, point + axis * radius * 0.65, Color(1, 1, 1, 0.9), 1.2, true)
			"star":
				var polygon := PackedVector2Array()
				for i in range(10):
					var angle = -PI * 0.5 + TAU * i / 10.0
					polygon.append(point + Vector2.from_angle(angle) * radius * (1.7 if i % 2 == 0 else 0.75))
				_draw_bullet_polygon(polygon, color)
				game.draw_circle(point, radius * 0.4, Color.WHITE)
			"note":
				var stem = point + Vector2(radius * 0.7, -radius * 1.9)
				game.draw_line(point + Vector2(radius * 0.6, 0), stem, Color(0.08, 0.05, 0.13), 4.5, true)
				game.draw_line(point + Vector2(radius * 0.6, 0), stem, color, 2.5, true)
				game.draw_line(stem, stem + Vector2(radius * 0.8, radius * 0.5), color, 2.5, true)
				game.draw_circle(point, radius, color)
				game.draw_circle(point + Vector2(-1, -1), radius * 0.3, Color.WHITE)
			"butterfly", "petal":
				var wing = Vector2(b.velocity).normalized().orthogonal() * radius * 0.65
				game.draw_circle(point + wing, radius * 0.85, color)
				game.draw_circle(point - wing, radius * 0.85, color)
				game.draw_circle(point, 1.8, Color.WHITE)
			_:
				game.draw_circle(point, radius, color)
				game.draw_circle(point + Vector2(-1, -1), radius * 0.43, Color(1, 1, 1, 0.85))
		if bool(b.get("frozen", false)) or game.boss_time_stop_timer > 0.0:
			game.draw_arc(point, radius + 3, 0, TAU, 12, Color(0.85, 0.98, 1, 0.65), 1, true)


func _draw_bullet_polygon(polygon: PackedVector2Array, color: Color) -> void:
	game.draw_colored_polygon(polygon, color)
	polygon.append(polygon[0])
	game.draw_polyline(polygon, Color(0.08, 0.05, 0.13, 0.85), 1.2, true)
