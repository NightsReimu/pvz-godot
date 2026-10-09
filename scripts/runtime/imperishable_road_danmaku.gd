extends RefCounted
# TH08 (Imperishable Night) Stage 1-3 cards - Wriggle, Mystia and Keine's
# history cards - rebuilt from the originals on the lawn. Keine's original
# whip, piano and bamboo cards stay in keine_boss_runtime.gd.

const Kit = preload("res://scripts/runtime/touhou_canon_kit.gd")
const Glyphs = preload("res://scripts/ui/touhou_glyphs.gd")
const KINDS := ["wriggle_boss", "mystia_boss", "keine_boss"]
const PATTERNS := [
	"nonspell_wriggle_night_swarm", "wriggle_meteor", "wriggle_firefly", "wriggle_bugs", "wriggle_final",
	"nonspell_mystia_song", "mystia_owl", "mystia_moth", "mystia_dive", "mystia_nightblind", "mystia_chorus",
	"nonspell_keine_scrolls", "keine_pyramid", "keine_ephemerality", "keine_masakado", "keine_crisis", "keine_treasures", "keine_mirror", "keine_emperor", "keine_legend", "keine_takamagahara",
]
const TUNE := {"keine_crisis": 0.57, "keine_emperor": 1.655, "keine_ephemerality": 1.438, "keine_legend": 1.298, "keine_masakado": 0.615, "keine_mirror": 1.757, "keine_pyramid": 1.5, "keine_takamagahara": 1.242, "keine_treasures": 1.824, "mystia_chorus": 1.868, "mystia_dive": 1.286, "mystia_moth": 0.796, "mystia_nightblind": 1.954, "mystia_owl": 2.504, "nonspell_keine_scrolls": 0.749, "nonspell_mystia_song": 0.818, "wriggle_bugs": 0.903, "wriggle_final": 1.966, "wriggle_firefly": 0.653, "wriggle_meteor": 0.565}
const RATE := {"keine_legend": 1.61, "keine_pyramid": 2.0, "keine_treasures": 2.0, "mystia_moth": 1.0, "mystia_nightblind": 2.0, "mystia_owl": 1.6, "wriggle_bugs": 1.9, "wriggle_final": 1.73}
const DURATIONS := {}
const GLOW := Color("c8f070")
const NIGHT := Color("6a58c8")
const NOTE := Color("e070c0")
const HISTORY := Color("7ec8e8")

static func owns(pattern: String) -> bool:
	return pattern in PATTERNS

static func duration(_card: Dictionary, pattern: String, fallback: float) -> float:
	return float(DURATIONS.get(pattern, fallback))

static func update_actors(_dm: RefCounted, _c: Dictionary) -> bool:
	return false

static func emit(dm: RefCounted, c: Dictionary) -> void:
	if not c.has("rate"): c["rate"] = float(RATE.get(String(c.pattern), 1.0))
	match String(c.kind):
		"wriggle_boss": _wriggle(dm, c)
		"mystia_boss": _mystia(dm, c)
		"keine_boss": _keine(dm, c)

static func _s(dm: RefCounted, c: Dictionary, from: Vector2, angle: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.shoot(dm, c, TUNE, from, angle, speed, color, shape, radius, extra)

static func _fan(dm: RefCounted, c: Dictionary, from: Vector2, n: int, angle: float, spread: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.fan(dm, c, TUNE, from, n, angle, spread, speed, color, shape, radius, extra)

static func _ring(dm: RefCounted, c: Dictionary, from: Vector2, n: int, rotation: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.ring(dm, c, TUNE, from, n, rotation, speed, color, shape, radius, extra)

# ------------------------------------------------------------------ Wriggle

static func _wriggle(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_wriggle_night_swarm":
			_ring(dm, c, o, Kit.count(dm, c, 18), w * 0.3, 115.0, GLOW, "firefly", 5.0, {"angular_speed": 0.22})
			_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.9, 175.0, Kit.GREEN, "orb", 5.5)
			Kit.next(dm, c, 0.45)
		"wriggle_meteor":
			# Earthly Meteor / Comet: fireflies shoot up from the ground at the
			# lawn's edges and streak across it; comets fly faster with tails.
			var comet := r >= 3
			for k in range(Kit.count(dm, c, 3)):
				var top := (k + w) % 2 == 0
				var x := board.position.x + board.size.x * (0.35 + 0.6 * Kit.noise(w, k))
				var from := Vector2(x, board.position.y + 4.0 if top else board.end.y - 4.0)
				var a := (PI * 0.5 if top else -PI * 0.5) + (0.55 if top else -0.55)
				_s(dm, c, from, a, 150.0 if comet else 120.0, GLOW, "firefly", 5.5, {"arming_time": 0.45, "bounces": 1})
				if comet:
					for f in range(3):
						_s(dm, c, from, a, 130.0 - f * 18.0, Color("90d860"), "orb", 4.0, {"arming_time": 0.45, "bounces": 1})
			if w % 4 == 0:
				_fan(dm, c, o, 3, aim, 0.3, 170.0, Kit.GREEN, "orb", 6.0)
			Kit.next(dm, c, 0.2)
		"wriggle_firefly":
			# Firefly Phenomenon: rings of fireflies drift out, hover blinking,
			# then each darts at the plants.
			_ring(dm, c, o, Kit.count(dm, c, 12 + r * 2), w * 0.41, 105.0, GLOW if w % 2 else Color("f4e070"), "firefly", 5.5, {"speed_curve": [[0.0, 105.0], [0.8, 8.0], [1.4, 8.0]], "turns": [{"t": 1.4 + 0.1 * (w % 3), "aim": true, "s": 150.0}]})
			Kit.next(dm, c, 0.45)
		"wriggle_bugs":
			# Little Bug (Storm), Night Bug Storm / Tornado: swarms of tiny bugs
			# stream out in turning spirals that thicken with difficulty; the
			# tornado winds them round her.
			var arms := 3 + r
			for arm in range(arms):
				var a := t * (1.6 if r < 3 else 2.4) * (1 if arm % 2 == 0 else -1) + TAU * arm / arms
				_s(dm, c, o, a, 120.0 + 20.0 * (arm % 2), Color("88c858") if arm % 2 else Color("d8e070"), "firefly", 4.0, {"angular_speed": 0.35 if r >= 3 else 0.0})
			if w % 6 == 0:
				_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.6, 165.0, Kit.GREEN, "orb", 5.5)
			Kit.next(dm, c, 0.09)
		"wriggle_final":
			# Hibernating Insects of the Eternal Night: dormant bugs settle all
			# over the lawn, dim and harmless, then all wake and swarm the plants.
			if t < 1.4:
				for k in range(Kit.count(dm, c, 7)):
					var p := board.position + board.size * Vector2(0.3 + 0.65 * Kit.noise(w * 13 + k, 1), 0.08 + 0.84 * Kit.noise(w * 13 + k, 2))
					_s(dm, c, p, PI, 0.0, Color("a0d070"), "firefly", 5.0, {"arming_time": 1.6 - t, "speed_curve": [[0.0, 0.0], [1.7 - t, 0.0], [2.2 - t, 130.0]], "turns": [{"t": 1.7 - t, "aim": true}]})
				Kit.at(c, t + 0.2)
			else:
				_ring(dm, c, o, Kit.count(dm, c, 18), w * 0.3, 125.0, GLOW, "firefly", 5.0)
				Kit.next(dm, c, 0.5)

# ------------------------------------------------------------------ Mystia

static func dive_point(c: Dictionary, board: Rect2) -> Vector2:
	# Ill-Starred Dive: she swoops in from the far edge across one row.
	var cycle := fposmod(float(c.age), 1.1) / 1.1
	var row := int(float(c.age) / 1.1)
	var y := board.position.y + board.size.y * (0.15 + 0.7 * Kit.noise(row, 3))
	return Vector2(board.end.x - board.size.x * 0.55 * sin(cycle * PI), y)

static func _mystia(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_mystia_song":
			_fan(dm, c, o, Kit.count(dm, c, 9, true), aim, 1.4, 165.0, NOTE, "note", 5.5)
			_ring(dm, c, o, Kit.count(dm, c, 16), w * 0.3, 110.0, NIGHT, "note", 5.0, {"angular_speed": 0.18})
			Kit.next(dm, c, 0.48)
		"mystia_owl":
			# Hooting in the Night (Howl of the Horned Owl): the cry spreads
			# in uneven rings of notes, beat after beat.
			var n := Kit.count(dm, c, 22 + r * 4)
			for k in range(n):
				var a := TAU * k / n + w * 0.33
				_s(dm, c, o, a, 95.0 + 45.0 * absf(sin(a * 3.0 + w)), NOTE if w % 2 else NIGHT, "note", 5.5)
			Kit.next(dm, c, 0.5)
		"mystia_moth":
			# Gu-Dao of the Hawkmoth (Poisonous Moth's Scales, Dark Dance):
			# fluttering moths shed poisonous scales as they cross the lawn.
			for k in range(Kit.count(dm, c, 4 + mini(r, 2))):
				var a := Kit.aim(dm, o) + (Kit.noise(w, k) - 0.5) * 1.4
				_s(dm, c, o, a, 110.0, Color("c8a0e8"), "moth", 6.5, {"sway_amp": 14.0, "sway_freq": 5.0, "trail_every": 0.4 if r < 2 else 0.3, "trail_left": 5, "trail": {"count": 2, "turn": PI * 0.5, "spread": PI, "speed": 30.0, "color": Color("d8f070") if r >= 2 else Color("e8d8f8"), "shape": "scale", "extra": {"radius": 4.0, "damage_scale": 0.6, "gravity_vec": Vector2(-60.0, 0.0), "gravity_cap": 90.0}}})
			Kit.next(dm, c, 0.36)
		"mystia_dive":
			# Ill-Starred Dive: Mystia swoops low over a row, scattering feathers
			# in the slipstream of each pass.
			var spot := dive_point(c, board)
			c["dive"] = spot
			_fan(dm, c, spot, Kit.count(dm, c, 4), PI * 0.5 if w % 2 else -PI * 0.5, 1.2, 70.0, Color("f0c070"), "rice", 5.0, {"arming_time": 0.3, "turns": [{"t": 0.7, "aim": true, "s": 150.0}]})
			Kit.next(dm, c, 0.14)
		"mystia_nightblind":
			# Song of the Night Sparrow: night-blindness closes over the lawn;
			# her song comes in rings of notes out of the dark.
			_ring(dm, c, o, Kit.count(dm, c, 14 + r * 2), w * 0.29, 105.0, NOTE, "note", 5.5, {"angular_speed": 0.25 if w % 2 else -0.25})
			if w % 2 == 1:
				_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.6, 160.0, NIGHT, "orb", 6.0)
			Kit.next(dm, c, 0.42)
		"mystia_chorus":
			# Midnight Chorus Master: a choir of three voices answering each
			# other - long phrases, rests, then a full chord.
			var voices := [o + Vector2(-20, -board.size.y * 0.28), o, o + Vector2(-20, board.size.y * 0.28)]
			var bar := w % 8
			if bar < 6:
				var v: Vector2 = voices[bar % 3]
				_fan(dm, c, v, Kit.count(dm, c, 7), Kit.aim(dm, v) + sin(w) * 0.3, 1.2, 145.0, [NOTE, NIGHT, Kit.GOLD][bar % 3], "note", 5.5)
				Kit.next(dm, c, 0.22)
			else:
				for v in voices:
					_ring(dm, c, v, Kit.count(dm, c, 12), w * 0.2, 115.0, NOTE, "note", 5.5)
				Kit.next(dm, c, 0.5)

# ------------------------------------------------------------------ Keine

static func treasure_points(c: Dictionary) -> Array:
	var points: Array = []
	for i in range(3):
		points.append(Vector2(c.center) + Vector2.from_angle(float(c.age) * 0.9 + TAU * i / 3.0) * 72.0)
	return points

static func _keine(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_keine_scrolls":
			for side in [-1.0, 1.0]:
				_fan(dm, c, o + Vector2(0, side * 45.0), Kit.count(dm, c, 7), PI + side * (0.24 + sin(w) * 0.18), 1.4, 150.0, Kit.RED if side < 0 else HISTORY, "ofuda", 5.0)
			Kit.next(dm, c, 0.4)
		"keine_pyramid":
			# First Pyramid: triangular frames of bullets that spread as they fly.
			for corner in range(3):
				var a := TAU * corner / 3.0 + w * 0.4
				var b := TAU * (corner + 1) / 3.0 + w * 0.4
				for k in range(5):
					var dir := Vector2.from_angle(a).lerp(Vector2.from_angle(b), k / 5.0)
					_s(dm, c, o, dir.angle() + aim + PI, 150.0 * dir.length() + 45.0, Kit.GOLD, "orb", 5.5)
			Kit.next(dm, c, 0.5)
		"keine_ephemerality":
			# Ephemerality 137: red and blue rings that stall and resume, layered
			# so each new history overwrites the last.
			for layer in range(2):
				_ring(dm, c, o, Kit.count(dm, c, 14), w * 0.137 * TAU + layer * 0.11, 120.0 + layer * 30.0, Kit.RED if (w + layer) % 2 == 0 else HISTORY, "orb", 5.5, {"speed_curve": [[0.0, 120.0 + layer * 30.0], [0.6, 20.0], [1.0, 20.0], [1.6, 140.0]]})
			Kit.next(dm, c, 0.42)
		"keine_masakado", "keine_crisis":
			# Masakado / Yoshimitsu / GHQ Crisis: streams sweep in from both
			# lawn edges and cross over the plants.
			var high := String(c.pattern) == "keine_crisis"
			for side in [-1.0, 1.0]:
				var from := Vector2(o.x - 20.0, board.get_center().y + side * board.size.y * 0.42)
				_fan(dm, c, from, Kit.count(dm, c, 5 + r), PI + side * (0.3 + 0.25 * sin(t * (1.6 if high else 1.1))), 0.5, 150.0, Kit.RED if side < 0 else HISTORY, "rice", 5.0, {"arming_time": 0.3})
			Kit.next(dm, c, 0.16)
		"keine_treasures", "keine_mirror":
			# The Three Sacred Treasures: sword, jewel and mirror orbit her - the
			# sword thrusts, the jewel rings, the mirror's bullets rebound.
			var points := treasure_points(c)
			var item := w % 3
			var from: Vector2 = points[item]
			match item:
				0: _fan(dm, c, from, 3, Kit.aim(dm, from), 0.15, 210.0, Kit.WHITE, "knife", 6.0)
				1: _ring(dm, c, from, Kit.count(dm, c, 12), w * 0.3, 110.0, Kit.GREEN, "jewel", 6.0)
				2: _fan(dm, c, from, Kit.count(dm, c, 6), PI, 1.6, 140.0, HISTORY, "orb", 6.0, {"bounces": 2 if String(c.pattern) == "keine_mirror" else 1})
			Kit.next(dm, c, 0.24)
		"keine_emperor", "keine_legend":
			# Emperor of Gensokyo / Legend of Gensokyo: a wide ring of rice and
			# beams of light that throw ofuda lines.
			_ring(dm, c, o, Kit.count(dm, c, 24), w * 0.21, 110.0, Kit.GOLD, "rice", 5.0)
			for light in range(5):
				var from := o + Vector2(-26.0, (light - 2) * 25.0)
				_fan(dm, c, from, 3, PI + sin(w + light * 0.18) * 0.32, 0.4, 125.0 + light * 12.0, Kit.RED if light % 2 == 0 else Kit.GOLD, "ofuda", 5.0)
			Kit.next(dm, c, 0.6 if String(c.pattern) == "keine_emperor" else 0.5)
		"keine_takamagahara":
			# Takamagahara: falling pillars of light with shifting gaps, and
			# fans of ofuda in between.
			if w % 2 == 0:
				for pillar in range(5):
					var x := 0.13 + pillar * 0.17 + (0.055 if w % 4 == 2 else 0.0)
					Kit.beam(dm, c, TUNE, Kit.point(dm, x, 0.02), Kit.point(dm, x - 0.06, 0.98), HISTORY if pillar % 2 == 0 else Kit.GOLD, 1.1, 11.0, 0.4)
				_fan(dm, c, o, Kit.count(dm, c, 15), PI, 2.1, 145.0, Kit.GOLD, "ofuda", 5.0)
			else:
				_ring(dm, c, o, Kit.count(dm, c, 22), w * 0.3, 128.0, Kit.RED, "rice", 5.0)
			Kit.next(dm, c, 0.62)

# ------------------------------------------------------------------ overlays

static func draw_cast(game: Control, c: Dictionary) -> void:
	var u := minf(game.CELL_SIZE.x / 135.0, game.CELL_SIZE.y / 127.0)
	var o := Vector2(c.center)
	var t := float(c.age)
	var fade := clampf(t / 0.4, 0.0, 1.0) * clampf((float(c.duration) - t) / 0.4, 0.0, 1.0)
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var p := String(c.pattern)
	match String(c.kind):
		"wriggle_boss":
			for k in range(10):
				var a := t * 0.8 + TAU * k / 10.0
				var spot := o + Vector2(cos(a) * (60.0 + 10.0 * sin(t * 2.0 + k)), sin(a * 1.3) * 40.0 - 20.0) * u
				Glyphs.draw(game, spot, 5.0 * u, "firefly", a, Color(0.85, 1.0, 0.5, (0.5 + 0.4 * sin(t * 7.0 + k)) * fade))
		"mystia_boss":
			if p == "mystia_nightblind":
				# Night blindness: the far lawn sinks into darkness.
				var dark := 0.35 * fade
				for k in range(6):
					var x := board.position.x + board.size.x * (0.35 + k * 0.11)
					game.draw_rect(Rect2(Vector2(x, board.position.y), Vector2(board.end.x - x, board.size.y)), Color(0.03, 0.02, 0.08, dark / 6.0), true)
			if p == "mystia_dive" and c.has("dive"):
				var spot := Vector2(c.dive)
				Glyphs.draw(game, spot, 18.0 * u, "feather", PI, Color(0.95, 0.75, 0.45, 0.75 * fade))
				game.draw_line(spot, spot + Vector2(60, 0) * u, Color(1, 0.85, 0.6, 0.35 * fade), 3.0 * u, true)
			for k in range(4):
				var rise := fposmod(t * 0.6 + k * 0.25, 1.0)
				Glyphs.draw(game, o + Vector2(-20.0 - k * 10.0, -40.0 - rise * 60.0) * u, 7.0 * u, "note", 0.0, Color(NOTE, (1.0 - rise) * 0.8 * fade))
		"keine_boss":
			if p in ["keine_treasures", "keine_mirror"]:
				var points := treasure_points(c)
				var glyphs := ["sword", "jewel", "eye"]
				for i in range(3):
					game.draw_circle(points[i], 14.0 * u, Color(HISTORY, 0.2 * fade))
					Glyphs.draw(game, points[i], 9.0 * u, glyphs[i], t, Color(1, 1, 1, 0.85 * fade))
			for k in range(3):
				var spot := o + Vector2(-50.0 - k * 6.0, -50.0 + k * 22.0) * u
				Glyphs.draw(game, spot + Vector2(0, sin(t * 2.0 + k) * 4.0 * u), 9.0 * u, "scroll", 0.0, Color(HISTORY, 0.55 * fade))
