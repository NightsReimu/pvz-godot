extends RefCounted

const COLORS := [Color("ef5474"), Color("8a94ff"), Color("ffc4dc")]

static func emit(runtime: RefCounted, cast: Dictionary) -> void:
	var pattern := String(cast.pattern)
	var wave := int(cast.wave)
	var turn := wave * 0.25
	var points: Array = cast.instrument_points
	var solo := -1
	if pattern in ["guarneri", "pseudo_stradivarius"]:
		solo = 0
	elif pattern in ["hino_phantasm", "ghost_clifford"]:
		solo = 1
	elif pattern in ["fazioli", "bosendorfer"]:
		solo = 2
	if solo >= 0:
		var origin := Vector2(points[solo]) + Vector2(-14, -12)
		var aimed: float = (runtime._target(origin) - origin).angle()
		match solo:
			0:
				# Violin strings: slow curling parallel streams, stronger counterpoint on H/L.
				for string_index in range(3):
					runtime._fan(cast, origin + Vector2(0, (string_index - 1) * 12), 7, aimed + sin(turn + string_index * 0.4) * 0.30, 0.9, 95 + string_index * 28, COLORS[0], "note", {"angular_speed": (string_index - 1) * 0.30})
				if pattern == "pseudo_stradivarius":
					runtime._fan(cast, origin, 9, PI - sin(turn) * 0.55, 1.7, 180, COLORS[0], "rice", {"angular_speed": -0.28})
			1:
				# Trumpet: spreading curved notes, then a warned piercing sound ray.
				runtime._fan(cast, origin, 13, aimed + sin(turn) * 0.35, 1.6, 145, COLORS[1], "note", {"angular_speed": 0.22 if wave % 2 == 0 else -0.22})
				if wave % 2 == 0 or pattern == "ghost_clifford":
					runtime._beam(cast, origin, runtime._target(origin), COLORS[1], 0.85, 9, {"instrument": 1})
			2:
				# Keyboard: alternating triads with staggered speeds and echoing keys.
				for chord in range(3):
					runtime._fan(cast, origin, 7, PI + sin(turn + chord * 1.8) * 0.45, 1.1, 110 + chord * 35, COLORS[2], "note", {"angular_speed": 0.20 * (chord - 1), "bounces": 1 if pattern == "bosendorfer" else 0})
		return
	for member in range(3):
		var origin := Vector2(points[member]) + Vector2(-14, -12)
		var color: Color = COLORS[member]
		var aimed: float = (runtime._target(origin) - origin).angle()
		if pattern in ["phantom_dinning", "live_poltergeist", "nonspell_note_crossfire"]:
			runtime._fan(cast, origin, 9, PI + sin(turn + member * 2.1) * 0.32, 1.6, 125 + member * 22, color, "note", {"angular_speed": 0.12 * (member - 1)})
			if pattern == "live_poltergeist":
				runtime._fan(cast, origin, 5, aimed, 0.6, 195, color, "rice")
		elif pattern == "prism_concerto":
			runtime._fan(cast, origin, 11, PI + sin(turn * 1.4 + member * 2.1) * 0.5, 1.7, 135 + member * 24, color, "note", {"angular_speed": 0.18 * (member - 1)})
			if wave % 3 == member:
				runtime._ring(cast, origin, 12, turn, 100, color, "note")
		elif pattern == "concerto_grosso":
			runtime._fan(cast, origin, 13, PI + sin(turn * 1.7 + member * 2.1) * 0.5, 1.8, 150 + member * 28, color, "note", {"angular_speed": 0.16 * (member - 1)})
			if wave % 2 == member % 2:
				runtime._ring(cast, origin, 14, turn + member, 115, color, "note")
		elif pattern.begins_with("pressure_music"):
			runtime._fan(cast, origin, 9, aimed + (member - 1) * 0.18, 1.1, 175, color, "note", {"angular_speed": (member - 1) * 0.26})
			if pattern.ends_with("_crossfire"):
				runtime._fan(cast, origin, 7, PI - sin(turn + member) * 0.6, 1.8, 145, color, "note")
			elif pattern.ends_with("_domain") and wave % 2 == 0:
				runtime._beam(cast, origin, runtime._target(origin), color, 0.9, 10, {"instrument": member})
