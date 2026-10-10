extends RefCounted
# TH07 (Perfect Cherry Blossom) cards rebuilt from the originals' bullet
# structure on the lawn (original "down" = towards the plants on the left).
# Hard/Lunatic variants share a pattern and read the difficulty rank.

const Kit = preload("res://scripts/runtime/touhou_canon_kit.gd")
const Glyphs = preload("res://scripts/ui/touhou_glyphs.gd")
const KINDS := ["cirno_boss", "letty_boss", "chen_boss", "alice_boss", "lily_white_boss", "youmu_boss", "yuyuko_boss", "ran_boss", "yukari_boss"]
const PATTERNS := [
	"cold_nonspell", "frost_columns",
	"nonspell_snow_curtain", "lingering_cold", "wither", "undulation_ray", "table_turning",
	"nonspell_shikigami_crossfire", "phoenix_egg", "seiman", "tianxian", "shijie", "blue_red_oni", "bishamonten",
	"nonspell_doll_fan", "otome_bunraku", "france", "holland", "london", "shanghai",
	"spring_nonspell",
	"nonspell_sword_fan", "gaki", "two_hundred_yojana", "animal_realm", "human_realm", "five_signs", "immeasurable_kalpas",
	"nonspell_butterfly_fan", "lost_soul", "mortal_butterfly", "swallowtail", "hirokawa", "sumizome", "resurrection_butterfly",
	"nonspell_fox_spiral", "senko", "twelve_generals", "fox_laser", "charming_siege", "princess_tenko", "buddhist", "contact", "shikigami_chen", "kokkuri", "izuna",
	"nonspell_gap_crossfire", "dream_reality", "motion_stillness", "light_dark_mesh", "straight_curve", "spiriting_away", "zen_butterfly", "double_butterfly", "shikigami_ran", "human_youkai", "life_death", "danmaku_barrier",
]
const TUNE := {"animal_realm": [1.175, 0.995, 0.925, 0.707], "bishamonten": 0.838, "blue_red_oni": 0.803, "buddhist": 1.791, "charming_siege": 1.0, "cold_nonspell": [0.809, 0.685, 0.685, 0.685], "contact": 1.332, "danmaku_barrier": 1.0, "double_butterfly": [1.181, 1.0, 1.0, 1.0], "dream_reality": 1.325, "five_signs": 0.678, "fox_laser": 0.318, "france": [1.118, 1.445, 1.686, 1.948], "frost_columns": [0.758, 0.642, 0.597, 0.69], "gaki": [0.771, 0.652, 0.606, 0.467], "hirokawa": [0.477, 0.404, 0.404, 0.314], "holland": [1.487, 1.27, 1.27, 1.27], "human_realm": 1.0, "human_youkai": 1.304, "immeasurable_kalpas": 1.201, "izuna": [1.302, 1.302, 1.302, 1.051], "kokkuri": 1.461, "life_death": 0.822, "light_dark_mesh": 1.519, "lingering_cold": [1.334, 1.128, 1.048, 0.86], "london": [0.924, 0.782, 0.782, 0.757], "lost_soul": [0.606, 0.652, 0.606, 0.606], "mortal_butterfly": [0.444, 0.478, 0.444, 0.444], "motion_stillness": 1.0, "nonspell_butterfly_fan": [1.181, 1.0, 1.0, 1.0], "nonspell_doll_fan": [0.711, 0.711, 0.711, 1.125], "nonspell_fox_spiral": [0.947, 1.212, 1.212, 1.682], "nonspell_gap_crossfire": 1.527, "nonspell_shikigami_crossfire": [0.764, 0.764, 0.972, 0.764], "nonspell_snow_curtain": 1.388, "nonspell_sword_fan": [0.79, 0.79, 0.96, 0.79], "otome_bunraku": [1.0, 1.0, 1.621, 1.516], "phoenix_egg": [1.0, 1.076, 1.0, 0.769], "princess_tenko": [1.516, 1.296, 1.296, 1.296], "seiman": [1.328, 1.773, 1.773, 1.773], "senko": [2.035, 2.035, 2.035, 2.6], "shanghai": 1.88, "shijie": [0.842, 1.0, 1.0, 1.0], "shikigami_chen": 1.0, "shikigami_ran": 0.847, "spiriting_away": 1.0, "spring_nonspell": [0.882, 0.747, 1.0, 0.861], "straight_curve": 1.239, "sumizome": [0.445, 0.377, 0.35, 0.298], "swallowtail": [0.476, 0.571, 0.571, 0.571], "table_turning": 2.357, "tianxian": [1.402, 1.402, 1.336, 1.021], "twelve_generals": 0.688, "two_hundred_yojana": 2.351, "undulation_ray": 0.454, "wither": 0.693, "zen_butterfly": [1.181, 1.0, 1.0, 1.0]}
const RATE := {"buddhist": 2.0, "human_youkai": 1.59, "izuna": 1.52, "kokkuri": 2.0, "princess_tenko": 1.69, "senko": 2.0, "swallowtail": 2.0, "table_turning": 2.0, "twelve_generals": 1.5}
const DURATIONS := {}
const SAKURA := Color("f7a8c8")
const SPIRIT := Color("8fc8f8")
const DUSK := Color("a070e0")

static func owns(pattern: String) -> bool:
	return pattern in PATTERNS

static func duration(_card: Dictionary, pattern: String, fallback: float) -> float:
	return float(DURATIONS.get(pattern, fallback))

static func update_actors(dm: RefCounted, c: Dictionary) -> bool:
	match String(c.pattern):
		"otome_bunraku":
			# Maiden's Bunraku: five dolls dance in a line on their strings.
			var board := Kit.board(dm)
			for i in range(5):
				var sway := sin(float(c.age) * 1.6 + i * 0.9)
				dm._actor(c, i, "alice_doll_zombie", Vector2(board.position.x + board.size.x * (0.62 + 0.12 * sway), board.position.y + board.size.y * (0.12 + i * 0.19) + 18.0 * cos(float(c.age) * 2.2 + i)))
			return true
		"spiriting_away":
			# Yukari herself steps out of a gap that moves about the lawn.
			var board := Kit.board(dm)
			var step := int(float(c.age) / 0.9)
			dm._actor(c, 0, "yukari_boss", Vector2(board.position.x + board.size.x * (0.62 + 0.2 * Kit.noise(step, 1)), board.position.y + board.size.y * (0.15 + 0.7 * Kit.noise(step, 2))), "gap")
			return true
	return false

static func emit(dm: RefCounted, c: Dictionary) -> void:
	if not c.has("rate"): c["rate"] = float(RATE.get(String(c.pattern), 1.0))
	match String(c.kind):
		"cirno_boss", "letty_boss", "lily_white_boss": _winter(dm, c)
		"chen_boss": _chen(dm, c)
		"alice_boss": _alice(dm, c)
		"youmu_boss": _youmu(dm, c)
		"yuyuko_boss": _yuyuko(dm, c)
		"ran_boss": _ran(dm, c)
		"yukari_boss": _yukari(dm, c)

static func _s(dm: RefCounted, c: Dictionary, from: Vector2, angle: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.shoot(dm, c, TUNE, from, angle, speed, color, shape, radius, extra)

static func _fan(dm: RefCounted, c: Dictionary, from: Vector2, n: int, angle: float, spread: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.fan(dm, c, TUNE, from, n, angle, spread, speed, color, shape, radius, extra)

static func _ring(dm: RefCounted, c: Dictionary, from: Vector2, n: int, rotation: float, speed: float, color: Color, shape: String = "orb", radius: float = 6.0, extra: Dictionary = {}) -> void:
	Kit.ring(dm, c, TUNE, from, n, rotation, speed, color, shape, radius, extra)

# ------------------------------------------------------------------ Cirno, Letty, Lily

static func _winter(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"cold_nonspell":
			# Cirno's snowfield nonspell: a wide fan of ice and a slower ring.
			_fan(dm, c, o, Kit.count(dm, c, 9, true), aim, 1.6, 150.0, Kit.SKY, "ice", 5.5)
			if w % 2 == 1:
				_ring(dm, c, o, Kit.count(dm, c, 14), w * 0.3, 105.0, Kit.WHITE, "ice", 5.0)
			Kit.next(dm, c, 0.38)
		"frost_columns":
			# Frost Columns: columns of ice that hang, then fall towards the plants.
			for k in range(5):
				var p := o + Vector2(-30.0 - (w % 4) * 50.0, (k - 2) * board.size.y * 0.18)
				_s(dm, c, p, PI, 0.0, Kit.SKY, "ice", 5.5, {"speed_curve": [[0.0, 0.0], [0.8, 0.0], [1.6, 135.0]], "arming_time": 0.4})
			Kit.next(dm, c, 0.22)
		"nonspell_snow_curtain":
			# Letty's flurry: snow drifting in from the far side, aimed sleet.
			for k in range(Kit.count(dm, c, 6)):
				var seed := w * 37 + k
				var from := Vector2(board.end.x - 10.0, board.position.y + board.size.y * Kit.noise(seed, 1))
				_s(dm, c, from, PI + (Kit.noise(seed, 2) - 0.5) * 0.5, 80.0 + 40.0 * Kit.noise(seed, 3), Kit.WHITE, "ice", 4.5, {"sway_amp": 10.0, "sway_freq": 3.0, "arming_time": 0.5})
			_fan(dm, c, o, 3, aim, 0.3, 160.0, Kit.SKY, "orb", 6.0)
			Kit.next(dm, c, 0.36)
		"lingering_cold":
			# Lingering Cold: spirals of snow that slow almost to a stop and
			# linger, then pick up speed again.
			for arm in range(Kit.count(dm, c, 5 + r)):
				var a := t * 1.4 + TAU * arm / (5 + r)
				_s(dm, c, o, a, 150.0, Kit.WHITE if arm % 2 else Kit.SKY, "orb", 5.5, {"speed_curve": [[0.0, 150.0], [0.8, 12.0], [1.6, 12.0], [2.6, 120.0]]})
			Kit.next(dm, c, 0.13)
		"wither":
			# Flower Wither Away: snow flowers bloom, hang, then wilt towards the lawn.
			for k in range(Kit.count(dm, c, 25)):
				var a := w * 0.6 + TAU * k / 25.0
				var speed := 70.0 * (1.0 + 0.45 * cos(5.0 * (a - w * 0.6)))
				_s(dm, c, o + Vector2(-20.0, 0), a, speed, Color("c8e8ff"), "petal", 5.5, {"speed_curve": [[0.0, speed], [0.9, 0.0]], "gravity_vec": Vector2(-70.0, 0.0), "gravity_at": 1.1, "gravity_cap": 120.0})
			_fan(dm, c, o, 5, aim, 0.5, 170.0, DUSK, "orb", 6.0)
			Kit.next(dm, c, 0.55)
		"undulation_ray":
			# Undulation Ray: lasers that sway back and forth, with snow.
			if w % 5 == 0:
				for k in range(3):
					Kit.ray(dm, c, TUNE, o, PI + (k - 1) * 0.55, Color("c8e8ff"), 1.0, 8.0, 1.6, {"turn_rate": 0.55 if k % 2 == 0 else -0.55})
			_ring(dm, c, o, Kit.count(dm, c, 14), w * 0.21, 110.0, Kit.WHITE, "ice", 5.0)
			Kit.next(dm, c, 0.35)
		"table_turning":
			# Table Turning: rings that turn one way, then swing the other.
			_ring(dm, c, o, Kit.count(dm, c, 18), w * 0.3, 110.0, DUSK if w % 2 else Kit.SKY, "orb", 5.5, {"angular_speed": 0.9, "spin_flip_at": 0.9, "spin_flip_gain": 1.0, "angular_stop_at": 2.0})
			Kit.next(dm, c, 0.42)
		"spring_nonspell":
			# Lily White: rings of spring blossoms and an aimed shower of petals.
			_ring(dm, c, o, Kit.count(dm, c, 20), w * 0.25, 105.0, [SAKURA, Color("f8f0b8"), Color("b8f0c0")][w % 3], "petal", 6.0)
			_fan(dm, c, o, Kit.count(dm, c, 9, true), aim, 1.3, 165.0, Kit.GOLD, "orb", 5.5)
			Kit.next(dm, c, 0.38)

# ------------------------------------------------------------------ Chen

static func chen_point(c: Dictionary, board: Rect2) -> Vector2:
	# Chen's darting path: she bounds about the right of the lawn.
	var t := float(c.age)
	var pattern := String(c.pattern)
	var centre := Vector2(board.position.x + board.size.x * 0.68, board.get_center().y)
	var reach := Vector2(board.size.x * 0.2, board.size.y * 0.4)
	match pattern:
		"seiman":
			# The five-pointed Seimei star traced corner to corner.
			var leg := fmod(t * 1.6, 5.0)
			var a := -PI * 0.5 + TAU * (int(leg) * 2 % 5) / 5.0
			var b := -PI * 0.5 + TAU * ((int(leg) + 1) * 2 % 5) / 5.0
			return centre + (Vector2.from_angle(a).lerp(Vector2.from_angle(b), fmod(leg, 1.0))) * reach
		"tianxian", "bishamonten":
			# Bouncing dashes from wall to wall.
			var x := absf(fmod(t * 0.9, 2.0) - 1.0)
			var y := absf(fmod(t * 1.37 + 0.4, 2.0) - 1.0)
			return centre + Vector2(x * 2.0 - 1.0, y * 2.0 - 1.0) * reach
	return centre + Vector2(sin(t * 2.2), sin(t * 3.1 + 1.0)) * reach

static func _chen(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var board := Kit.board(dm)
	var chen := chen_point(c, board)
	c["chen"] = chen
	match String(c.pattern):
		"nonspell_shikigami_crossfire":
			for side in [-1.0, 1.0]:
				var from := o + Vector2(-30.0, side * 70.0)
				_fan(dm, c, from, Kit.count(dm, c, 6), PI + side * 0.35, 1.0, 165.0, Kit.RED if side < 0 else Kit.BLUE, "ofuda", 5.0)
			Kit.next(dm, c, 0.38)
		"phoenix_egg":
			# Phoenix Egg: Chen leaves tight egg clutches that hatch outward;
			# the spread-wing grade hatches into wider rings.
			_ring(dm, c, chen, Kit.count(dm, c, 10 + r * 2), w * 0.4, 70.0, Kit.ORANGE, "orb", 5.5, {"speed_curve": [[0.0, 30.0], [0.25, 0.0], [0.9, 0.0], [1.5, 120.0 + r * 10.0]]})
			Kit.next(dm, c, 0.3)
		"seiman":
			# Flying Seimei: bullets dropped along the pentagram path wait, then
			# fan out from the star once she has drawn it.
			for k in range(2):
				_s(dm, c, chen, PI + (Kit.noise(w, k) - 0.5) * 1.6, 0.0, Kit.BLUE if k else Kit.RED, "ofuda", 5.0, {"speed_curve": [[0.0, 0.0], [1.4, 0.0], [2.2, 120.0 + r * 12.0]], "facing": PI + (Kit.noise(w, k) - 0.5) * 2.0, "arming_time": 0.5})
			Kit.next(dm, c, 0.09)
		"tianxian":
			# Heavenly Wizard's Rumbling: dashing bounces leave rings behind.
			_ring(dm, c, chen, Kit.count(dm, c, 8 + r * 2), w * 0.3, 95.0, Kit.ORANGE if w % 2 else Kit.GREEN, "orb", 5.5, {"arming_time": 0.3})
			Kit.next(dm, c, 0.2)
		"shijie":
			# Eternal Shijie: Chen spins in place, wheeling fast and slow rings.
			_ring(dm, c, chen, Kit.count(dm, c, 14), t * 2.0, 135.0, Kit.ORANGE, "orb", 5.5)
			_ring(dm, c, chen, Kit.count(dm, c, 10), -t * 2.0, 80.0, Kit.GREEN, "rice", 5.0)
			Kit.next(dm, c, 0.3)
		"blue_red_oni":
			# Blue Oni Red Oni: two coloured wheels circling against each other.
			for side in [-1.0, 1.0]:
				var from := Vector2(board.position.x + board.size.x * 0.68, board.get_center().y) + Vector2.from_angle(t * 1.4 * side) * board.size.y * 0.32
				_ring(dm, c, from, Kit.count(dm, c, 10), t * side, 110.0, Kit.BLUE if side < 0 else Kit.RED, "orb", 6.0)
			Kit.next(dm, c, 0.33)
		"bishamonten":
			# Flying Bishamonten: high-speed bounding leaves dense lines.
			_fan(dm, c, chen, 3, Kit.aim(dm, chen), 0.4, 70.0, Kit.GOLD, "orb", 5.5, {"speed_curve": [[0.0, 20.0], [0.8, 20.0], [1.4, 160.0]]})
			_ring(dm, c, chen, Kit.count(dm, c, 6), w * 0.5, 100.0, Kit.RED, "rice", 5.0)
			Kit.next(dm, c, 0.12)

# ------------------------------------------------------------------ Alice

static func _alice(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var dolls: Array = []
	for actor in c.actors: dolls.append(Vector2(actor.position))
	if dolls.is_empty(): dolls = [o]
	match String(c.pattern):
		"nonspell_doll_fan":
			for doll in dolls:
				_fan(dm, c, doll, 3, PI + sin(t + doll.y) * 0.25, 0.5, 150.0, Kit.BLUE, "orb", 5.5)
			Kit.next(dm, c, 0.42)
		"otome_bunraku":
			# Maiden's Bunraku: the dancing dolls take turns - a short aimed
			# burst each, then all five open into rings together.
			if w % 4 == 3:
				for doll in dolls:
					_ring(dm, c, doll, Kit.count(dm, c, 8), w * 0.4, 105.0, Color("f0d080"), "orb", 5.5)
			else:
				for i in range(dolls.size()):
					if (i + w) % 2 == 0:
						var doll: Vector2 = dolls[i]
						_fan(dm, c, doll, 3, Kit.aim(dm, doll), 0.3, 160.0, Kit.BLUE, "rice", 5.0)
			Kit.next(dm, c, 0.3)
		"france":
			# Charitable French Doll (Orleans): each doll fires a fixed blue
			# cross that rotates with her, plus aimed shots.
			for i in range(dolls.size()):
				var doll: Vector2 = dolls[i]
				var spin := t * (0.8 + r * 0.15) * (1 if i % 2 == 0 else -1)
				for k in range(4):
					_s(dm, c, doll, spin + k * PI * 0.5, 120.0, Kit.BLUE, "orb", 5.5)
				if w % 3 == 2:
					_s(dm, c, doll, Kit.aim(dm, doll), 175.0, Color("f0d080"), "rice", 5.0)
			Kit.next(dm, c, 0.24)
		"holland":
			# Red-Haired Dutch Doll (Chalky Russian): dolls spray red rings
			# that slow and burst back out.
			for doll in dolls:
				_ring(dm, c, doll, Kit.count(dm, c, 7 + r), w * 0.5 + doll.y * 0.01, 110.0, Kit.RED if r < 2 else Kit.WHITE, "orb", 5.5, {"speed_curve": [[0.0, 110.0], [0.7, 25.0], [1.3, 125.0]]})
			Kit.next(dm, c, 0.5)
		"london":
			# Foggy London Doll (Tibetan, Kyoto): dolls loose drifting purple
			# bullets that waver through the fog.
			for doll in dolls:
				_fan(dm, c, doll, Kit.count(dm, c, 3 + mini(r, 2)), PI + sin(t * 1.3 + doll.y * 0.02) * 0.6, 0.6, 120.0, DUSK, "orb", 5.5, {"sway_amp": 12.0, "sway_freq": 4.0})
			Kit.next(dm, c, 0.3)
		"shanghai":
			# Shanghai Doll of Magic Light (Hanged Hourai): each doll aims a
			# laser that follows her; colourful sparks spill from the dolls.
			for i in range(dolls.size()):
				var doll: Vector2 = dolls[i]
				if w % 4 == 0:
					Kit.beam(dm, c, TUNE, doll, doll + Vector2.from_angle(PI + (i - 2) * 0.12) * dm.game.board_size.x * 1.2, Kit.RAINBOW[(i * 2 + w) % 7], 0.85, 9.0, 0.45, {"actor_index": i})
				_s(dm, c, doll, Kit.aim(dm, doll) + (Kit.noise(w, i) - 0.5) * 0.6, 135.0, Kit.RAINBOW[(i + w) % 7], "star", 5.5)
			Kit.next(dm, c, 0.25)

# ------------------------------------------------------------------ Youmu

static func _slash_fx(dm: RefCounted, at: Vector2, radius: float) -> void:
	Kit.effect(dm, "youmu_cross_slash", at, radius, 0.3, Color(0.75, 1, 0.95, 0.65))

static func _youmu(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	var blade := Color("a8f0e0")
	match String(c.pattern):
		"nonspell_sword_fan":
			# Sword-energy rice and the half-phantom's slower shots.
			_fan(dm, c, o, Kit.count(dm, c, 13, true), aim, 1.5, 175.0, blade, "rice", 5.0)
			_fan(dm, c, o + Vector2(10, -48), Kit.count(dm, c, 5, true), aim + sin(t) * 0.4, 0.8, 125.0, Color("e8f4ff"), "ghost", 5.5)
			Kit.next(dm, c, 0.42)
		"gaki":
			# Fasting of the Young Ghost (Hungry King): each slash leaves a line
			# of sword energy that hangs, then lunges at the plants; a cut
			# lane opens towards the nearest target.
			if w % 3 == 0:
				var target: Vector2 = dm._target(o)
				Kit.beam(dm, c, TUNE, o, Vector2(board.position.x - 10.0, target.y), blade, 0.8, 9.0, 0.3)
				Kit.effect(dm, "youmu_half_ghost", o + Vector2(18, -48), 42.0, 0.55, Color(0.7, 0.95, 1, 0.24))
			var line := Kit.count(dm, c, 7 + r * 2)
			var dir := aim + (Kit.noise(w, 1) - 0.5) * 1.4
			for k in range(line):
				var p := o + Vector2.from_angle(dir + PI * 0.5) * (k - line * 0.5) * 16.0
				_s(dm, c, p, dir, 0.0, blade, "knife", 5.5, {"speed_curve": [[0.0, 0.0], [0.6, 0.0], [0.9, 200.0]], "facing": dir, "arming_time": 0.3, "turns": [{"t": 0.6, "aim": true}]})
			_slash_fx(dm, o + Vector2.from_angle(dir) * 40.0, 70.0)
			Kit.next(dm, c, 0.36)
		"two_hundred_yojana":
			# Two Hundred Yojana in One Slash: the half-phantom lobs large spirit
			# bullets; while Youmu gathers herself everything slows, then her
			# slash cuts every spirit bullet into a spray of rice.
			if w % 2 == 0:
				var ghost := Vector2(c.actors[0].position) if not c.actors.is_empty() else o + Vector2(-36, -48)
				_fan(dm, c, ghost, 7, aim, 2.1, 300.0, Kit.BLUE, "big", 14.0, {"cuttable": true})
				c["focus_until"] = t + 0.8
				var target: Vector2 = dm._target(o)
				dm._beam(c, o, target, blade, 0.8, 18, {"sword_cut": true, "phase": c.phase})
			Kit.next(dm, c, 0.62)
		"animal_realm":
			# Punishment of the Mindless (Present Attachment): Youmu dashes
			# leaving after-images; each drops a hanging line that falls in.
			var dash := Vector2(board.position.x + board.size.x * (0.55 + 0.35 * Kit.noise(w, 1)), board.position.y + board.size.y * (0.12 + 0.76 * Kit.noise(w, 2)))
			c["afterimage"] = dash
			for k in range(Kit.count(dm, c, 6 + r)):
				var a := TAU * k / (6 + r) + w * 0.4
				_s(dm, c, dash + Vector2.from_angle(a) * 22.0, PI, 0.0, Color("c8a8f0") if r >= 2 else blade, "knife", 5.5, {"speed_curve": [[0.0, 0.0], [0.7, 0.0], [1.3, 150.0]], "facing": PI + (Kit.noise(w, k + 4) - 0.5) * 0.6, "arming_time": 0.35})
			_slash_fx(dm, dash, 60.0)
			Kit.next(dm, c, 0.32)
		"human_realm":
			# Fantasy Enlightenment: rice rises from below the lawn while a
			# frontal stream comes at the plants; sakura spin when she focuses.
			c["focus_until"] = t + 0.3
			for i in range(Kit.count(dm, c, 15)):
				var below := Vector2(board.position.x + board.size.x * (0.06 + i * 0.058), board.end.y - 4.0)
				_s(dm, c, below, -PI * 0.5 + sin(i * 0.8 + w) * 0.12, 105.0 + (i % 3) * 12.0, Color("f08aa0"), "rice", 5.0)
			_fan(dm, c, o, Kit.count(dm, c, 15 + r * 2, true), aim, 1.5, 190.0, Kit.BLUE, "rice", 5.0)
			Kit.next(dm, c, 0.62)
		"five_signs":
			# Five Signs of the Heavenly Being (Seven Souls, Three Souls): straight
			# layers of rice at five different speeds - a line, not a spread.
			c["focus_until"] = t + 0.24
			for i in range(5 + mini(r, 2)):
				_fan(dm, c, o, Kit.count(dm, c, 9, true), aim + (i - 2) * 0.035, 1.7, 125.0 + i * 24.0, Kit.BLUE if i % 2 == 0 else Kit.GOLD, "rice", 5.0)
			Kit.next(dm, c, 0.62)
		"immeasurable_kalpas":
			# Immeasurable Aeons: whirling slashes around her body throw rings.
			c["focus_until"] = t + 0.16
			for i in range(3):
				_ring(dm, c, o, Kit.count(dm, c, 20), w * 0.3 + i * 0.08, 150.0 + i * 28.0, blade if i % 2 == 0 else Kit.GREEN, "rice", 5.0)
			_slash_fx(dm, o, 150.0)
			Kit.next(dm, c, 0.62)

# ------------------------------------------------------------------ Yuyuko

static func swallowtail_radius(a: float) -> float:
	# Temple Fay's butterfly curve, used to shape the Swallowtail volley.
	return exp(sin(a)) - 2.0 * cos(4.0 * a) + pow(sin((2.0 * a - PI) / 24.0), 5)

static func _yuyuko(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var r := Kit.rank(dm)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	match String(c.pattern):
		"nonspell_butterfly_fan":
			for side in [-1.0, 1.0]:
				_fan(dm, c, o + Vector2(0, side * 30.0), Kit.count(dm, c, 9), PI + side * 0.35, 1.5, 125.0, SAKURA if side < 0 else SPIRIT, "butterfly", 6.0, {"angular_speed": side * 0.2})
			Kit.next(dm, c, 0.44)
		"lost_soul":
			# Deathly Land: lasers frame her fan while streams of blue spirits
			# drift out along curving paths.
			if w % 6 == 0:
				for side in [-1.0, 1.0]:
					Kit.ray(dm, c, TUNE, o, PI + side * 0.75, SPIRIT, 1.0, 7.0, 1.2)
			for side in [-1.0, 1.0]:
				_s(dm, c, o + Vector2(0, side * 26.0), PI + side * (0.35 + 0.25 * sin(t * 2.0)), 120.0, SPIRIT, "ghost", 6.0, {"angular_speed": -side * 0.3})
			if w % 3 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 14 + r * 2), w * 0.2, 85.0, Color("6aa8f0"), "orb", 5.5)
			Kit.next(dm, c, 0.16)
		"mortal_butterfly":
			# Law of Mortality: wheels of butterflies that stall and dive, and an
			# aimed spray of dusky moths.
			_ring(dm, c, o, Kit.count(dm, c, 14 + r * 2), w * 0.27, 120.0, SAKURA, "butterfly", 6.0, {"speed_curve": [[0.0, 120.0], [0.7, 25.0], [1.3, 25.0]], "turns": [{"t": 1.3, "aim": true, "s": 140.0}]})
			if w % 2 == 1:
				_fan(dm, c, o, Kit.count(dm, c, 7, true), aim, 1.0, 175.0, DUSK, "moth", 6.0)
			Kit.next(dm, c, 0.48)
		"swallowtail":
			# Swallowtail Butterfly: every volley spreads into a butterfly outline.
			# The curve's radius runs from about -2.4 to 4.7; shift it so every
			# bullet flies outward and the wings keep their proportions.
			var n := Kit.count(dm, c, 44)
			var spin := PI * 0.5 + (w % 2) * 0.25
			for k in range(n):
				var a := TAU * k / n
				_s(dm, c, o, a + spin, 30.0 + (swallowtail_radius(a) + 2.5) * 20.0, [SAKURA, Color("f5d070"), SPIRIT][w % 3], "orb", 5.0)
			Kit.next(dm, c, 0.85)
		"hirokawa":
			# Bury in a Hirokawa: ghosts rise from the lawn's edges, drift in,
			# then turn on the plants, while Yuyuko fans slow rings.
			for k in range(Kit.count(dm, c, 3 + r)):
				var top := (k + w) % 2 == 0
				var x := board.position.x + board.size.x * (0.3 + 0.65 * Kit.noise(w, k))
				var from := Vector2(x, board.position.y + 4.0 if top else board.end.y - 4.0)
				_s(dm, c, from, PI * 0.5 if top else -PI * 0.5, 60.0, SPIRIT, "ghost", 6.0, {"arming_time": 0.6, "turns": [{"t": 1.0 + 0.4 * Kit.noise(w, k + 7), "aim": true, "s": 115.0}]})
			if w % 3 == 0:
				_ring(dm, c, o, Kit.count(dm, c, 16), w * 0.15, 95.0, SAKURA, "butterfly", 6.0)
			Kit.next(dm, c, 0.26)
		"sumizome":
			# Perfect Sumizome Cherry: Saigyou Ayakashi sheds spirals of petals
			# that drift down across the lawn.
			var tree := o + Vector2(20.0, -40.0)
			for arm in range(Kit.count(dm, c, 4 + r)):
				var a := t * 1.1 + TAU * arm / (4 + r)
				_s(dm, c, tree, a, 105.0, SAKURA if arm % 2 else Color("f8d8e8"), "petal", 6.0, {"gravity_vec": Vector2(-55.0, 12.0), "gravity_cap": 130.0, "angular_speed": 0.25})
			Kit.next(dm, c, 0.14)
		"resurrection_butterfly":
			# Resurrection Butterfly: the great butterfly unfolds over and over
			# while rings of butterflies wheel out, blooming more as it nears
			# full bloom.
			var bloom := clampf(t / 24.0, 0.0, 1.0)
			if w % 3 == 0:
				var n := Kit.count(dm, c, 30 + r * 4)
				for k in range(n):
					var a := TAU * k / n
					_s(dm, c, o, a + PI * 0.5, 28.0 + (swallowtail_radius(a) + 2.5) * (17.0 + 6.0 * bloom), SAKURA, "butterfly", 6.0)
			else:
				_ring(dm, c, o, Kit.count(dm, c, 10 + int(bloom * 8.0)), t * 0.7, 120.0, SPIRIT if w % 2 else Color("e070b0"), "butterfly", 5.5, {"angular_speed": 0.2 if w % 2 else -0.2})
			Kit.next(dm, c, 0.42 - bloom * 0.12)

# ------------------------------------------------------------------ Ran

static func _ran(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	var fox := Color("f6c85a")
	match String(c.pattern):
		"nonspell_fox_spiral":
			for tail in range(9):
				_s(dm, c, o, t * 1.2 + TAU * tail / 9.0, 150.0, fox, "ofuda", 5.0, {"angular_speed": 0.18})
			Kit.next(dm, c, 0.22)
		"senko":
			# Thoughts of a Thousand Years: nine tails of rice curl out in
			# alternating spirals.
			for tail in range(9):
				var a := TAU * tail / 9.0 + w * 0.17
				_s(dm, c, o, a, 135.0, fox if tail % 2 else Kit.ORANGE, "rice", 5.0, {"angular_speed": 0.55 if w % 2 == 0 else -0.55, "angular_stop_at": 1.2})
			Kit.next(dm, c, 0.14)
		"twelve_generals":
			# Banquet of the Twelve General Gods: twelve emitters on a wheel,
			# each throwing a short ofuda burst.
			for g in range(12):
				var a := TAU * g / 12.0 + t * 0.5
				var from := o + Vector2.from_angle(a) * 64.0
				if (g + w) % 3 == 0:
					_fan(dm, c, from, 3, Kit.aim(dm, from) + (Kit.noise(w, g) - 0.5) * 0.8, 0.35, 125.0, Kit.RAINBOW[g % 7], "ofuda", 5.0)
			Kit.next(dm, c, 0.16)
		"fox_laser":
			# Kitsune-Tanuki Youkai Laser: lasers fan across the lawn, crossing
			# as they rotate, with an aimed fox-fire spray.
			if w % 5 == 0:
				for k in range(4):
					Kit.ray(dm, c, TUNE, o, PI + (k - 1.5) * 0.36, fox, 1.0, 8.0, 1.3, {"turn_rate": 0.32 if k % 2 == 0 else -0.32})
			_fan(dm, c, o, Kit.count(dm, c, 5, true), aim, 0.5, 170.0, Kit.ORANGE, "fire", 6.0)
			Kit.next(dm, c, 0.3)
		"charming_siege":
			# Charming Quadruple Siege: ofuda close in from all four sides of
			# the target.
			var target: Vector2 = dm._target(o)
			for side in range(4):
				var a := side * PI * 0.5 + t * 0.15
				var from := (target + Vector2.from_angle(a) * 230.0).clamp(board.position, board.end)
				_fan(dm, c, from, Kit.count(dm, c, 5), (target - from).angle(), 0.9, 120.0, fox, "ofuda", 5.0, {"arming_time": 0.5})
			Kit.next(dm, c, 0.4)
		"princess_tenko":
			# Princess Tenko -Illusion-: Ran blinks between illusions; each
			# illusion bursts into a wheel of ofuda.
			var spot := Vector2(board.position.x + board.size.x * (0.55 + 0.35 * Kit.noise(w, 1)), board.position.y + board.size.y * (0.15 + 0.7 * Kit.noise(w, 2)))
			c["illusion"] = spot
			_ring(dm, c, spot, Kit.count(dm, c, 14), w * 0.3, 110.0, fox, "ofuda", 5.0, {"arming_time": 0.3})
			Kit.next(dm, c, 0.36)
		"buddhist":
			# Ultimate Buddhist: a turning manji of ofuda arms.
			for arm in range(4):
				var a := t * 0.9 + arm * PI * 0.5
				for k in range(4):
					var p := o + Vector2.from_angle(a) * (18.0 + k * 16.0)
					_s(dm, c, p, a + 0.6, 125.0, fox, "ofuda", 5.0)
			Kit.next(dm, c, 0.22)
		"contact":
			# Unilateral Contact: straight walls of ofuda that touch the edges
			# and come back along the other side.
			_fan(dm, c, o, Kit.count(dm, c, 9), PI + (w % 2 - 0.5) * 0.9, 0.8, 150.0, fox, "ofuda", 5.0, {"bounces": 1})
			Kit.next(dm, c, 0.32)
		"shikigami_chen":
			# Shikigami "Chen": the cat familiar wheels about firing rings.
			var familiar := Vector2(c.actors[0].position) if not c.actors.is_empty() else o
			_ring(dm, c, familiar, Kit.count(dm, c, 16), t, 140.0, Kit.ORANGE, "ofuda", 5.0)
			_fan(dm, c, o, Kit.count(dm, c, 7, true), aim, 1.0, 170.0, Kit.VIOLET, "orb", 5.5)
			Kit.next(dm, c, 0.4)
		"kokkuri":
			# Kokkuri-san's Contract: the coin glides between marks; at every
			# mark a burst of fox fire.
			var mark := o + Vector2.from_angle(w * 2.4) * 80.0
			c["coin"] = mark
			_ring(dm, c, mark, Kit.count(dm, c, 12), w * 0.5, 115.0, Kit.ORANGE, "fire", 6.0, {"angular_speed": -0.22})
			_fan(dm, c, mark, 3, Kit.aim(dm, mark), 0.3, 160.0, Color("f6c85a"), "fire", 6.0)
			Kit.next(dm, c, 0.34)
		"izuna":
			# Descent of Izuna Gongen: rings come quicker and denser to the end.
			_ring(dm, c, o, Kit.count(dm, c, mini(40, 18 + w)), w * 0.23, 100.0 + w * 3.0, fox, "orb", 5.5)
			Kit.next(dm, c, lerpf(0.62, 0.22, clampf(t / 3.4, 0.0, 1.0)))

# ------------------------------------------------------------------ Yukari

static func gap_points(board: Rect2, step: int, count: int) -> Array:
	var points: Array = []
	for i in range(count):
		points.append(Vector2(board.position.x + board.size.x * (0.4 + 0.55 * Kit.noise(step * 7 + i, 1)), board.position.y + board.size.y * (0.08 + 0.84 * Kit.noise(step * 7 + i, 2))))
	return points

static func _yukari(dm: RefCounted, c: Dictionary) -> void:
	var o := Vector2(c.center)
	var w := int(c.wave)
	var t := float(c.age)
	var aim := Kit.aim(dm, o)
	var board := Kit.board(dm)
	var gap := Color("c070f0")
	match String(c.pattern):
		"nonspell_gap_crossfire":
			for side in [-1.0, 1.0]:
				var from := Vector2(board.position.x + board.size.x * 0.62, board.position.y + board.size.y * (0.1 if side < 0 else 0.9))
				_fan(dm, c, from, Kit.count(dm, c, 9), Kit.aim(dm, from), 1.2, 150.0, gap, "ofuda", 5.0, {"angular_speed": side * 0.2, "arming_time": 0.4})
			Kit.next(dm, c, 0.45)
		"dream_reality":
			# Curse of Dreams and Reality: red and blue ofuda pour from gaps.
			var points := gap_points(board, w / 3, 3)
			c["gaps"] = points
			for i in range(points.size()):
				var p: Vector2 = points[i]
				_fan(dm, c, p, Kit.count(dm, c, 4), Kit.aim(dm, p), 0.6, 125.0, Kit.RED if i % 2 else Kit.BLUE, "ofuda", 5.0, {"arming_time": 0.45})
			Kit.next(dm, c, 0.3)
		"motion_stillness":
			# Balance of Motion and Stillness: one ring stops dead and resumes at
			# right angles while the next keeps moving.
			_ring(dm, c, o, Kit.count(dm, c, 24), w * 0.2, 165.0, gap, "orb", 5.5, {"freeze_at": 0.45, "thaw_at": 1.2, "thaw_angle": PI * 0.5 * (1 if w % 2 else -1)})
			_fan(dm, c, o, Kit.count(dm, c, 7, true), aim, 1.0, 110.0, Kit.RED, "orb", 5.5)
			Kit.next(dm, c, 0.5)
		"light_dark_mesh":
			# Mesh of Light and Darkness: a grid of lasers with slow orbs.
			if w % 4 == 0:
				for k in range(4):
					var x := board.position.x + board.size.x * (0.25 + 0.2 * k + 0.05 * (w % 8 / 4))
					Kit.beam(dm, c, TUNE, Vector2(x, board.position.y - 4.0), Vector2(x - board.size.x * 0.1, board.end.y + 4.0), gap, 1.0, 7.0, 0.45)
			_ring(dm, c, o, Kit.count(dm, c, 12), w * 0.3, 90.0, Color("40304a").lerp(gap, 0.5), "orb", 6.0)
			Kit.next(dm, c, 0.3)
		"straight_curve":
			# Dreamland of Straight and Curve: a straight volley crossed by a
			# curving one.
			_fan(dm, c, o, Kit.count(dm, c, 13), PI, 1.8, 150.0, Kit.BLUE, "orb", 5.5)
			_fan(dm, c, o, Kit.count(dm, c, 13), PI - 0.6, 1.8, 150.0, Kit.RED, "orb", 5.5, {"angular_speed": 0.55})
			Kit.next(dm, c, 0.45)
		"spiriting_away":
			# Yukari's Spiriting Away: she steps from gap to gap, each arrival
			# bursting into a ring of ofuda.
			var spot := Vector2(c.actors[0].position) if not c.actors.is_empty() else o
			_ring(dm, c, spot, Kit.count(dm, c, 20), w * 0.3, 135.0, gap, "ofuda", 5.0, {"arming_time": 0.25})
			Kit.next(dm, c, 0.45)
		"zen_butterfly", "double_butterfly":
			# Butterflies of the Zen temple / Double Black Death Butterfly:
			# wing-shaped butterfly waves, doubled and darkened on the latter.
			var dark := String(c.pattern) == "double_butterfly"
			for side in [-1.0, 1.0]:
				_fan(dm, c, o + Vector2(-40.0, side * 70.0), Kit.count(dm, c, 9), PI + side * (0.4 + 0.3 * sin(t * 2.0)), 1.4, 120.0, Color("402040") if dark and side < 0 else gap, "butterfly", 6.0, {"angular_speed": side * 0.25})
			if not dark and w % 4 == 0:
				Kit.ray(dm, c, TUNE, o, PI + sin(t) * 0.4, Kit.RED, 0.9, 8.0, 0.5)
			Kit.next(dm, c, 0.3)
		"shikigami_ran":
			# Shikigami "Ran Yakumo": the fox familiar sweeps about firing rings.
			var familiar := Vector2(c.actors[0].position) if not c.actors.is_empty() else o
			_ring(dm, c, familiar, Kit.count(dm, c, 18), t, 140.0, Color("f6c85a"), "ofuda", 5.0)
			_fan(dm, c, o, Kit.count(dm, c, 7, true), aim, 1.0, 175.0, gap, "orb", 5.5)
			Kit.next(dm, c, 0.4)
		"human_youkai":
			# Boundary of Humans and Youkai: a boundary line splits the lawn;
			# ofuda pour from it in both directions.
			var x := board.position.x + board.size.x * (0.62 + 0.08 * sin(t))
			c["boundary_x"] = x
			for k in range(Kit.count(dm, c, 6)):
				var y := board.position.y + board.size.y * Kit.noise(w, k)
				_s(dm, c, Vector2(x, y), PI + (Kit.noise(w, k + 9) - 0.5) * 0.8, 120.0, gap if k % 2 else Kit.RED, "ofuda", 5.0, {"arming_time": 0.45})
			Kit.next(dm, c, 0.22)
		"life_death":
			# Boundary of Life and Death: from the centre of the boundary every
			# side turns inward in alternating colours.
			var centre := board.get_center()
			for side in range(4):
				var a := side * PI * 0.5 + t * 0.2
				var from := centre + Vector2.from_angle(a) * 230.0
				_fan(dm, c, from, Kit.count(dm, c, 7), a + PI, 1.1, 120.0, gap if side % 2 else Color("f070a0"), "butterfly", 6.0, {"arming_time": 0.5})
			Kit.next(dm, c, 0.4)
		"danmaku_barrier":
			# Danmaku Bounded Field: walls of ofuda surround the target, hold,
			# and then all close in together.
			var target: Vector2 = dm._target(o)
			for side in range(4):
				var a := side * PI * 0.5 + t * 0.12
				var from := (target + Vector2.from_angle(a) * 240.0).clamp(board.position, board.end)
				_fan(dm, c, from, Kit.count(dm, c, 7), a + PI, 1.2, 100.0, gap, "ofuda", 5.0, {"freeze_at": 0.15, "thaw_at": 0.85, "thaw_angle": 0.0, "arming_time": 0.5})
			Kit.next(dm, c, 0.5)

# ------------------------------------------------------------------ cast overlays

static func _gap(game: Control, at: Vector2, width: float, alpha: float, turn: float) -> void:
	Glyphs.draw(game, at, width, "gap", turn, Color(0.85, 0.5, 1.0, alpha))
	for k in range(2):
		game.draw_circle(at + Vector2.from_angle(turn).orthogonal() * width * 0.35 * (k * 2 - 1), width * 0.08, Color(1, 0.6, 0.75, alpha))

static func draw_cast(game: Control, c: Dictionary) -> void:
	var u := minf(game.CELL_SIZE.x / 135.0, game.CELL_SIZE.y / 127.0)
	var o := Vector2(c.center)
	var t := float(c.age)
	var fade := clampf(t / 0.4, 0.0, 1.0) * clampf((float(c.duration) - t) / 0.4, 0.0, 1.0)
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var p := String(c.pattern)
	match String(c.kind):
		"cirno_boss", "letty_boss":
			for k in range(8):
				var a := t * 0.9 + TAU * k / 8.0
				Glyphs.draw(game, o + Vector2(cos(a) * 54.0, sin(a) * 26.0 - 24.0) * u, 6.5 * u, "snow", a, Color(0.92, 0.98, 1.0, 0.7 * fade))
		"lily_white_boss":
			for k in range(6):
				var a := t * 1.2 + TAU * k / 6.0
				Glyphs.draw(game, o + Vector2(cos(a) * 48.0, sin(a) * 22.0 - 24.0) * u, 7.0 * u, "flower", a, Color(SAKURA, 0.75 * fade))
		"chen_boss":
			if p == "seiman":
				var centre := Vector2(board.position.x + board.size.x * 0.68, board.get_center().y)
				var reach := Vector2(board.size.x * 0.2, board.size.y * 0.4)
				var star := PackedVector2Array()
				for i in range(6):
					star.append(centre + Vector2.from_angle(-PI * 0.5 + TAU * (i * 2 % 5) / 5.0) * reach)
				game.draw_polyline(star, Color(1, 0.75, 0.4, 0.28 * fade), 2.0 * u, true)
			if c.has("chen"):
				var spot := Vector2(c.chen)
				game.draw_circle(spot, 18.0 * u, Color(1, 0.6, 0.25, 0.18 * fade))
				game.draw_arc(spot, 16.0 * u, t * 9.0, t * 9.0 + PI * 1.4, 18, Color(1, 0.7, 0.35, 0.8 * fade), 2.4 * u, true)
				Glyphs.draw(game, spot, 9.0 * u, "pentagram", t * 6.0, Color(1, 0.9, 0.6, 0.9 * fade))
		"alice_boss":
			for actor in c.actors:
				var doll := Vector2(actor.position)
				game.draw_line(o + Vector2(0, -30) * u, doll + Vector2(0, -18) * u, Color(0.9, 0.95, 1.0, 0.22 * fade), 1.0, true)
		"youmu_boss":
			if c.has("afterimage"):
				var spot := Vector2(c.afterimage)
				game.draw_circle(spot, 22.0 * u, Color(0.7, 1.0, 0.9, 0.16 * fade))
				Glyphs.draw(game, spot, 16.0 * u, "sword", -0.7, Color(0.85, 1.0, 0.95, 0.7 * fade))
		"yuyuko_boss":
			# Her folding fan opens behind her; Saigyou Ayakashi for the cherry cards.
			for k in range(9):
				var a := -PI * 0.5 + (k - 4) * 0.2
				game.draw_line(o + Vector2(20, -10) * u, o + Vector2(20, -10) * u + Vector2.from_angle(a + PI) * 70.0 * u * fade, Color(0.95, 0.65, 0.8, 0.25 * fade), 6.0 * u, true)
			if p in ["sumizome", "resurrection_butterfly"]:
				var root := o + Vector2(60.0, 40.0) * u
				for k in range(5):
					var a := -PI * 0.5 + (k - 2) * 0.45
					var tip := root + Vector2.from_angle(a + PI * 0.15) * 150.0 * u
					game.draw_line(root, tip, Color(0.25, 0.15, 0.2, 0.45 * fade), 6.0 * u, true)
					for b in range(5):
						var bloom := tip + Vector2.from_angle(b * 1.3 + t) * (16.0 + b * 6.0) * u
						game.draw_circle(bloom, (9.0 + 2.0 * sin(t * 2.0 + b)) * u, Color(0.98, 0.7, 0.85, 0.32 * fade))
		"ran_boss":
			for k in range(9):
				var a := PI * 0.5 + (k - 4) * 0.28 + sin(t * 2.0 + k) * 0.05
				var tail := PackedVector2Array()
				for s in range(6):
					tail.append(o + Vector2(14.0, 6.0) * u + Vector2.from_angle(a - PI * 0.5 + s * 0.05) * (12.0 + s * 12.0) * u)
				game.draw_polyline(tail, Color(1, 0.85, 0.45, 0.35 * fade), 7.0 * u, true)
			if c.has("illusion") and p == "princess_tenko":
				game.draw_arc(Vector2(c.illusion), 26.0 * u, t * 4.0, t * 4.0 + TAU, 24, Color(1, 0.85, 0.4, 0.6 * fade), 2.0 * u, true)
			if c.has("coin") and p == "kokkuri":
				game.draw_circle(Vector2(c.coin), 12.0 * u, Color(1, 0.85, 0.35, 0.75 * fade))
		"yukari_boss":
			if c.has("gaps"):
				for spot in c.gaps:
					_gap(game, Vector2(spot), 26.0 * u, 0.85 * fade, 0.4)
			if p == "spiriting_away" and not c.actors.is_empty():
				_gap(game, Vector2(c.actors[0].position) + Vector2(0, 40) * u, 40.0 * u, 0.8 * fade, 0.0)
			if p == "human_youkai" and c.has("boundary_x"):
				var x := float(c.boundary_x)
				game.draw_line(Vector2(x, board.position.y), Vector2(x, board.end.y), Color(0.85, 0.5, 1.0, 0.5 * fade), 3.0 * u, true)
				game.draw_line(Vector2(x + 3.0 * u, board.position.y), Vector2(x + 3.0 * u, board.end.y), Color(1, 0.55, 0.7, 0.3 * fade), 1.5 * u, true)
