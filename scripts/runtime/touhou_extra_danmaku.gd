extends RefCounted

# Original difficulty moves. Tier one keeps the established pursuit geometry;
# tier two attacks from opposing emitters; tier three forms a delayed enclosure.
# Colour, projectile, motion and formation retain each character's vocabulary.
const THEMES := {
	"dark": ["orb", 4, 145.0, 4], "fairy": ["rice", 3, 140.0, 4],
	"ice": ["ice", 1, 150.0, 9], "rainbow": ["rice", 2, 160.0, 6],
	"books": ["ofuda", 4, 150.0, 4], "elements": ["ofuda", 2, 155.0, 5],
	"knives": ["knife", 1, 210.0, 6], "scarlet": ["rice", 0, 175.0, 4],
	"crystal": ["star", 4, 185.0, 4], "snow": ["ice", 1, 115.0, 6],
	"shikigami": ["ofuda", 2, 185.0, 4], "dolls": ["rice", 0, 145.0, 5],
	"spring": ["rice", 0, 135.0, 4], "music": ["note", 2, 155.0, 3],
	"sword": ["rice", 1, 205.0, 6], "butterfly": ["butterfly", 4, 125.0, 4],
	"fox": ["ofuda", 2, 175.0, 9], "boundary": ["ofuda", 4, 165.0, 4],
	"insects": ["orb", 3, 120.0, 6], "song": ["note", 0, 145.0, 4],
	"history": ["ofuda", 1, 150.0, 4],
}

static func emit(dm: RefCounted, c: Dictionary) -> bool:
	var family := String(c.card.get("pressure_family", String(c.pattern).trim_prefix("pressure_")))
	var tier := int(c.card.get("pressure_tier", 1))
	var scale := minf(dm.game.CELL_SIZE.x / 100.0, dm.game.CELL_SIZE.y / 110.0)
	if family == "ofuda":
		_reimu(dm, c, tier, scale)
	elif family == "stars":
		_marisa(dm, c, tier, scale)
	elif tier >= 2 and THEMES.has(family):
		if tier == 2:
			_crossfire(dm, c, family, scale)
		else:
			_domain(dm, c, family, scale)
	else:
		return false
	return true

static func _motion(family: String, side: int, target: Vector2, scale: float) -> Dictionary:
	var extra := {"radius": 5.0 * scale, "arming_time": 0.65}
	match family:
		"ice", "knives":
			extra.merge({"freeze_at": 0.18, "thaw_at": 1.0, "thaw_angle": side * 0.24, "arming_time": 1.0})
		"books", "history", "shikigami", "boundary":
			extra.merge({"redirect_at": 0.8, "aim_point": target})
		"crystal", "fox":
			extra.merge({"bounces": 2, "radius": 7.0 * scale})
		"fairy", "rainbow", "snow", "spring", "music", "butterfly", "insects", "song", "dark":
			extra["angular_speed"] = side * (0.38 if family in ["butterfly", "insects"] else 0.22)
	return extra

static func _crossfire(dm: RefCounted, c: Dictionary, family: String, scale: float) -> void:
	var theme: Array = THEMES[family]
	var wave := int(c.wave)
	var target: Vector2 = dm._target(Vector2(c.center))
	for side in [-1, 1]:
		var start: Vector2 = dm._point(0.74 + 0.06 * sin(wave * 0.5), 0.09 if side < 0 else 0.91)
		var color: Color = dm.COLORS[posmod(int(theme[1]) + (1 if side > 0 else 0), 6)]
		if family == "dolls" and c.actors.size() >= 2:
			start = c.actors[0 if side < 0 else c.actors.size() - 1].position
		var aim := (target - start).angle()
		var motion := _motion(family, side, target, scale)
		dm._fan(c, start, 13, aim + side * sin(wave * 0.4) * 0.25, 1.2, float(theme[2]) * scale, color, String(theme[0]), motion)
		if family in ["elements", "scarlet", "sword", "dolls"] and wave % 3 == 0:
			var end: Vector2 = dm._point(0.12, 0.82 if side < 0 else 0.18)
			var beam := {"damage": 62.0, "duration": 0.55}
			if family == "dolls":
				beam["actor_index"] = 0 if side < 0 else c.actors.size() - 1
			dm._beam(c, start, end, color, 1.05, 9 * scale, beam)
		elif family in ["insects", "music", "fox"]:
			dm._ring(c, start, 9, wave * 0.25 * side, 90 * scale, color, String(theme[0]), motion)

static func _domain(dm: RefCounted, c: Dictionary, family: String, scale: float) -> void:
	var theme: Array = THEMES[family]
	var wave := int(c.wave)
	var center: Vector2 = dm._point(0.48, 0.5)
	var extent: Vector2 = dm.game.board_size * Vector2(0.33, 0.40)
	var count := int(theme[3])
	for node in range(count):
		# The missing emitter rotates each wave, keeping a visible open sector.
		if node == wave % count:
			continue
		var angle := TAU * node / count + wave * 0.11
		var start := center + Vector2.from_angle(angle) * extent
		if family == "dolls" and node < c.actors.size():
			start = c.actors[node].position
		var color: Color = dm.COLORS[posmod(int(theme[1]) + (node if family in ["rainbow", "elements", "music"] else wave % 2), 6)]
		var side := -1 if node % 2 == 0 else 1
		var motion := _motion(family, side, center, scale)
		motion["arming_time"] = 1.05
		# Enclosure bullets first fan tangentially, then converge on the lawn.
		# A delayed release is physically different from tier two's crossfire.
		motion["redirect_at"] = 1.0
		motion["aim_point"] = center + Vector2(0, sin(wave * 0.8) * extent.y * 0.4)
		dm._fan(c, start, 7, (center - start).angle() + side * 0.6, 0.95, float(theme[2]) * 0.72 * scale, color, String(theme[0]), motion)
		if family in ["elements", "scarlet", "sword", "dolls", "boundary"] and node % 2 == 0 and wave % 3 == 0:
			var end := center + Vector2.from_angle(angle + PI * 0.7) * extent
			var beam := {"duration": 0.6, "damage": 66.0}
			if family == "dolls":
				beam["actor_index"] = node
			dm._beam(c, start, end, color, 1.2, 10 * scale, beam)

static func _reimu(dm: RefCounted, c: Dictionary, tier: int, scale: float) -> void:
	var wave := int(c.wave)
	var red: Color = dm.COLORS[0]
	var blue: Color = dm.COLORS[1]
	var target: Vector2 = dm._target(Vector2(c.center))
	if tier == 1:
		for side in [-1, 1]:
			var start: Vector2 = dm._point(0.86, 0.24 if side < 0 else 0.76)
			dm._fan(c, start, 9, PI + side * 0.32, 1.1, 130 * scale, red if side < 0 else blue, "ofuda", {"radius": 4.5 * scale, "damage": 19.0, "homing_after": 0.65, "homing_rate": 0.8, "aim_point": target})
	elif tier == 2:
		for side in [-1, 1]:
			var start: Vector2 = dm._point(0.66, 0.12 if side < 0 else 0.88)
			dm._ring(c, start, 11, side * wave * 0.3, 95 * scale, blue if side < 0 else red, "dream_orb", {"radius": 7 * scale, "damage": 20.0, "angular_speed": side * 0.3, "arming_time": 0.85})
			dm._fan(c, start, 7, PI, 0.8, 148 * scale, red, "ofuda", {"radius": 4 * scale, "damage": 18.0, "redirect_at": 0.85, "aim_point": target, "arming_time": 0.85})
	else:
		for column in range(4):
			if column == wave % 4:
				continue
			for side in [-1, 1]:
				var start: Vector2 = dm._point(0.2 + column * 0.19, 0.06 if side < 0 else 0.94)
				dm._fan(c, start, 5, -side * PI * 0.5, 0.55, 112 * scale, red if side < 0 else blue, "ofuda", {"radius": 4 * scale, "damage": 18.0, "arming_time": 1.0, "freeze_at": 0.1, "thaw_at": 0.85})
		dm._fan(c, Vector2(c.center), 7, (target - Vector2(c.center)).angle(), 1.1, 150 * scale, dm.COLORS[2], "dream_orb", {"radius": 7 * scale, "damage": 21.0})

static func _marisa(dm: RefCounted, c: Dictionary, tier: int, scale: float) -> void:
	var wave := int(c.wave)
	var gold: Color = dm.COLORS[2]
	var blue: Color = dm.COLORS[1]
	if tier == 1:
		for lane in range(3):
			var start: Vector2 = dm._point(0.88, 0.18 + lane * 0.32)
			dm._fan(c, start, 7, PI + sin(wave * 0.5 + lane) * 0.3, 0.95, 155 * scale, gold if lane % 2 == 0 else blue, "star", {"radius": 5 * scale, "damage": 20.0, "bounces": 1})
	elif tier == 2:
		for side in [-1, 1]:
			var start: Vector2 = dm._point(0.86, 0.14 if side < 0 else 0.86)
			var end: Vector2 = dm._point(0.1, 0.82 if side < 0 else 0.18)
			dm._fan(c, start, 9, (end - start).angle(), 0.8, 168 * scale, gold if side < 0 else blue, "star", {"radius": 5 * scale, "damage": 20.0, "angular_speed": side * 0.18, "arming_time": 0.75})
			if wave % 3 == 0:
				dm._beam(c, start, end, gold if side < 0 else blue, 1.1, 15 * scale, {"damage": 65.0, "duration": 0.9, "turn_rate": side * 0.15})
	else:
		var center: Vector2 = dm._point(0.6, 0.5)
		var radius: float = dm.game.board_size.y * 0.24
		var count := ceili(24 * dm.Difficulty.attack_density(String(c.kind), dm.game.current_level))
		for i in range(count):
			var angle := TAU * i / count + wave * 0.2
			dm._bullet(c, center + Vector2.from_angle(angle) * radius, angle, 148 * scale, gold if i % 2 == 0 else blue, "star", {"radius": 5 * scale, "damage": 20.0, "orbit_center": center, "orbit_radius": radius, "orbit_angle": angle, "orbit_turn": -1.2 if wave % 2 == 0 else 1.2, "orbit_until": 1.15, "arming_time": 1.2})
		if wave % 3 == 0:
			for ray in range(3):
				var angle := PI + (ray - 1) * 0.55
				var end: Vector2 = center + Vector2.from_angle(angle) * dm.game.board_size.length()
				dm._beam(c, center, end, gold, 1.2, 14 * scale, {"damage": 62.0, "duration": 0.85, "turn_rate": -0.2 if wave % 2 == 0 else 0.2})
