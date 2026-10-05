extends RefCounted

const Detail = preload("res://scripts/ui/combat_details.gd")

# Follow the native body pose; the caller supplies the battle/icon transform,
# including jumps and hypnosis facing. Drawing never changes combat state.
static func pose(game, c: Vector2, z: Dictionary) -> Dictionary:
	var kind := String(z.kind)
	var phase := float(z.get("anim_phase", 0.0))
	var raw_speed := float(z.get("base_speed", 18.0))
	var speed := raw_speed * (0.5 if float(z.get("slow_timer", 0.0)) > 0.0 else 1.0)
	var custom_moving := float(z.get("special_pause_timer", 0.0)) <= 0.0
	var moving := not bool(z.get("jumping", false))
	for timer in ["special_pause_timer", "boss_pause_timer", "weed_pause_timer", "reflect_timer"]:
		moving = moving and float(z.get(timer, 0.0)) <= 0.0
	var step := sin(game.level_time * (3.0 + speed * 0.08) + phase + float(z.get("x", 0.0)) * 0.02) if moving else sin(game.level_time * 1.4 + phase) * 0.12
	var bite := sin((1.0 - clampf(float(z.get("bite_timer", 0.0)) / 0.18, 0.0, 1.0)) * PI)
	var impact := sin((1.0 - clampf(float(z.get("impact_timer", 0.0)) / 0.16, 0.0, 1.0)) * PI)
	var body := c + Vector2(impact * 8.0, -absf(step) * 2.6 - bite * 3.0)
	var head := Vector2(0, -28)
	var scale := 1.0
	var alpha := 1.0
	match kind:
		"kedama":
			body = c + Vector2(0, sin(game.level_time * 3 + phase) * 3)
			head = Vector2(0, -16); scale = 0.80
		"star_fairy":
			body = c + Vector2(0, sin(game.level_time * 3 + phase) * 3)
			head = Vector2(0, -34); scale = 0.75
		"imp":
			body = c + Vector2(0, -absf(sin(game.level_time * (4.2 + raw_speed * 0.08) + phase)) * 2 if custom_moving else 0)
			head = Vector2(0, -18); scale = 0.71
		"wolf_knight_zombie":
			body = c
			head = Vector2(-2, -20) if bool(z.get("mounted", false)) else Vector2(0, -28)
			scale = 0.71 if bool(z.get("mounted", false)) else 0.94
		"enderman_zombie":
			body = c; head = Vector2(0, -43); scale = 0.68
		"shania_zombie":
			body = c + Vector2(0, -18 + sin(game.level_time * 5.2 + phase) * 8)
			head = Vector2(0, -18); scale = 0.88
		"shade_zombie":
			body = c + Vector2(0, sin(game.level_time * 4 + phase) * 2)
			scale = 0.82; alpha = 0.4 if bool(z.get("blink_active", false)) else 1.0
		"camel_zombie":
			body = c + Vector2(0, -absf(sin(game.level_time * 2.4 + phase)) * 2 if custom_moving else 0)
			head = Vector2(0, -41); scale = 0.53
		"squash_zombie":
			body = c + Vector2(0, -6 if bool(z.get("squash_active", false)) else 0)
			head = Vector2(0, -4); scale = 1.4
		"barrel_screen_zombie":
			body = c + Vector2(0, -4 - (absf(sin(game.level_time * 3.1 + phase)) * 1.6 if custom_moving else 0))
			scale = 0.94
		"shouyue":
			var aiming := bool(z.get("snipe_charge_active", false))
			var aim := 1.0 - clampf(float(z.get("snipe_charge_timer", 0.0)) / maxf(float(z.get("snipe_charge_duration", 0.16)), 0.01), 0, 1) if aiming else 0.0
			body = c + Vector2(-aim * 5, -2 - absf(sin(game.level_time * 2.2 + phase)) * (1.2 if aiming else 1.8))
			head = Vector2(0, -30); scale = 0.94
			alpha = 0.42 if not bool(z.get("portrait", false)) and game._is_hidden_from_lane_attacks(z) else 0.92
		_:
			var specs := {
				"hive_zombie":[3.5 + raw_speed * 0.08, 2.2, -28, 0.94], "ladder_zombie":[3.3 + raw_speed * 0.08, 2.0, -28, 0.94],
				"janitor_zombie":[3.0, 2.0, -30, 0.94], "ski_zombie":[4.4, 2.0, -28, 0.88],
				"flywheel_zombie":[2.2, 1.8, -30, 0.94], "wither_zombie":[2.8, 2.2, -30, 0.94],
				"wizard_zombie":[2.4, 1.8, -30, 0.88], "qinghua":[2.6, 2.2, -28, 1.0],
				"umbrella_zombie":[2.4 + raw_speed * 0.05, 3.0, -30, 0.88],
			}
			if kind in ["medic_zombie", "shieldbearer_zombie", "saboteur_zombie", "rift_zombie", "bomber_zombie"]:
				body = c + Vector2(0, -absf(sin(game.level_time * (2.7 + raw_speed * 0.04) + phase)) * 2)
			elif specs.has(kind):
				var spec: Array = specs[kind]
				var bob := absf(sin(game.level_time * float(spec[0]) + phase)) * float(spec[1])
				if kind in ["hive_zombie", "ladder_zombie", "umbrella_zombie"] and not custom_moving: bob = 0.0
				body = c + Vector2(0, -bob)
				head.y = float(spec[2]); scale = float(spec[3])
			elif bool(game.Defs.ZOMBIES[kind].get("volcano_expansion", false)):
				body = c
	return {"body":body, "head":body + head, "scale":scale, "alpha":alpha}

static func draw(game, center: Vector2, zombie: Dictionary) -> void:
	if not zombie.has("fusion_kind"): return
	var anchor := pose(game, center, zombie)
	if float(zombie.get("headgear_health", 0.0)) > 0:
		var ratio := float(zombie.headgear_health) / maxf(float(zombie.max_headgear_health), 1)
		_headgear(game, anchor.head, float(anchor.scale), String(zombie.headgear_kind), ratio, float(anchor.alpha))
	if float(zombie.get("handheld_health", 0.0)) > 0:
		var ratio := float(zombie.handheld_health) / maxf(float(zombie.max_handheld_health), 1)
		_door(game, anchor.body, ratio, float(anchor.alpha))

static func _headgear(canvas: CanvasItem, head: Vector2, s: float, kind: String, ratio: float, alpha: float) -> void:
	var worn := ratio < 0.5
	var c := head + Vector2(0, 28) * s
	match kind:
		"cone":
			Detail.polygon(canvas, c, s, [Vector2(-5,-55) if worn else Vector2(0,-61), Vector2(15,-35), Vector2(-15,-35)], Color("#ed8836", alpha))
			Detail.polygon(canvas, c, s, [Vector2(-9,-45),Vector2(9,-45),Vector2(12,-40),Vector2(-12,-40)], Color("#fff2cf", alpha), 0)
			canvas.draw_line(c + Vector2(-18,-34) * s, c + Vector2(18,-34) * s, Color("#a4562f", alpha), 3 * s, true)
		"bucket":
			Detail.polygon(canvas, c, s, [Vector2(-17,-51),Vector2(8,-53),Vector2(12,-48) if worn else Vector2(17,-51),Vector2(20,-34),Vector2(-20,-34)], Color("#98aeb6", alpha))
			canvas.draw_line(c + Vector2(-12,-48) * s, c + Vector2(-14,-37) * s, Color("#dbe9e6", alpha), 4 * s, true)
			canvas.draw_line(c + Vector2(-20,-34) * s, c + Vector2(20,-34) * s, Color("#566e77", alpha), 3 * s, true)
			canvas.draw_arc(c + Vector2(0,-40) * s, 22 * s, 0.15, PI - 0.15, 20, Color("#566e77", alpha), 1.8 * s, true)
		"brick":
			Detail.polygon(canvas, c, s, [Vector2(-19,-34),Vector2(-18,-55),Vector2(18,-57),Vector2(20,-34)], Color("#b8613e", alpha))
			for y in [-48.0, -41.0]:
				canvas.draw_line(c + Vector2(-18,y) * s, c + Vector2(19,y) * s, Color("#e8c9a2", alpha), 1.4 * s, true)
			for seam in [Vector2(-6,-55), Vector2(8,-48), Vector2(-9,-41), Vector2(5,-41)]:
				canvas.draw_line(c + seam * s, c + (seam + Vector2(0,7)) * s, Color("#e8c9a2", alpha), 1.4 * s, true)
			if worn: Detail.polygon(canvas, c, s, [Vector2(10,-57),Vector2(19,-56),Vector2(19,-47)], Color("#3a2a24", alpha), 0)
		"kabuto":
			Detail.contour(canvas, c, s, [Vector2(-22,-33),Vector2(-20,-47),Vector2(-8,-56),Vector2(9,-56),Vector2(21,-47),Vector2(23,-33),Vector2(13,-30),Vector2(-14,-30)], Color("#3d3a48", alpha))
			canvas.draw_line(c + Vector2(-24,-33) * s, c + Vector2(25,-33) * s, Color("#7b7488", alpha), 3.4 * s, true)
			if not worn:
				Detail.polygon(canvas, c, s, [Vector2(-3,-55),Vector2(-16,-70),Vector2(-8,-55)], Color("#e3b84f", alpha))
				Detail.polygon(canvas, c, s, [Vector2(3,-55),Vector2(16,-70),Vector2(8,-55)], Color("#e3b84f", alpha))
			canvas.draw_circle(c + Vector2(0,-50) * s, 3.2 * s, Color("#c4433a", alpha))
		_:
			var red := Color("#594c68" if kind == "dark_football" else "#bf534a", alpha)
			Detail.contour(canvas, c, s, [Vector2(-21,-36),Vector2(-21,-47),Vector2(-10,-56),Vector2(10,-55),Vector2(22,-44),Vector2(19,-26),Vector2(11,-21),Vector2(6,-36)], red)
			canvas.draw_line(c + Vector2(-4,-52) * s, c + Vector2(4,-50) * s, Color("#f4ddba", alpha), 3 * s, true)
			Detail.ellipse(canvas, c + Vector2(12,-32) * s, Vector2(5,6) * s, red.lightened(0.16), s)
			canvas.draw_polyline(PackedVector2Array([c+Vector2(10,-29)*s,c+Vector2(-22,-29)*s,c+Vector2(-22,-20)*s,c+Vector2(6,-20)*s]), Color("#c3d1cc", alpha), 2 * s, true)
	if worn:
		canvas.draw_polyline(PackedVector2Array([c+Vector2(8,-47)*s,c+Vector2(2,-43)*s,c+Vector2(8,-40)*s,c+Vector2(2,-37)*s]), Color("#46524c", alpha), 1.8 * s, true)

static func _door(canvas: CanvasItem, c: Vector2, ratio: float, alpha: float) -> void:
	var frame := Rect2(c + Vector2(-43,-25), Vector2(32,60))
	canvas.draw_line(c + Vector2(-12,1), c + Vector2(-26,6), Color("#627561", alpha), 6, true)
	canvas.draw_rect(frame, Color("#5f7980", alpha * 0.3))
	canvas.draw_rect(frame, Color("#8aa9b2", alpha), false, 4)
	canvas.draw_rect(frame.grow(2), Color("#283d40", alpha), false, 1.5)
	for x in range(-38, -14, 6):
		canvas.draw_line(c + Vector2(x,-20), c + Vector2(x,30), Color("#b7ccce", alpha * 0.6), 0.9, true)
	for y in range(-18, 31, 6):
		canvas.draw_line(c + Vector2(-38,y), c + Vector2(-16,y), Color("#b7ccce", alpha * 0.6), 0.9, true)
	canvas.draw_circle(c + Vector2(-17,8), 2.5, Color("#e7d8aa", alpha))
	if ratio < 0.5:
		Detail.polygon(canvas, c, 1, [Vector2(-34,-7),Vector2(-23,-12),Vector2(-19,0),Vector2(-29,12),Vector2(-37,6)], Color("#273e3a", alpha * 0.9), 1)
		canvas.draw_polyline(PackedVector2Array([c+Vector2(-39,26),c+Vector2(-33,21),c+Vector2(-27,28),c+Vector2(-18,22)]), Color("#dae3d6", alpha), 1.5, true)
