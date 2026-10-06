extends RefCounted

const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const DURATION := 1.65
const THEMES := {
	"shizuha_boss": [Color("f07846"), "maple"],
	"minoriko_boss": [Color("f3cc71"), "grain"],
	"hakutaku_boss": [Color("aee69b"), "ofuda"],
	"mokou_boss": [Color("ff9869"), "petal"],
	"kaguya_boss": [Color("efb7d6"), "clock"],
	"eirin_boss": [Color("ff9aaa"), "cross"],
	"reisen_boss": [Color("fa668d"), "eye"],
	"tewi_boss": [Color("f2c0cd"), "petal"],
	"reimu_boss": [Color("f7667e"), "ofuda"],
	"marisa_boss": [Color("ffd97b"), "star"],
	"rumia_boss": [Color("db769a"), "diamond"],
	"daiyousei_boss": [Color("91df9f"), "petal"],
	"cirno_boss": [Color("91e6ff"), "ice"],
	"meiling_boss": [Color("ffbc85"), "petal"],
	"koakuma_boss": [Color("e4a1ed"), "diamond"],
	"patchouli_boss": [Color("d2adff"), "star"],
	"sakuya_boss": [Color("a6e4f3"), "clock"],
	"remilia_boss": [Color("f97598"), "diamond"],
	"flandre_boss": [Color("ffb191"), "diamond"],
	"letty_boss": [Color("b5dfff"), "ice"],
	"chen_boss": [Color("ffbf80"), "ofuda"],
	"alice_boss": [Color("a9ceff"), "star"],
	"lily_white_boss": [Color("f5eabc"), "petal"],
	"prismriver_boss": [Color("dab5ff"), "note"],
	"youmu_boss": [Color("b4efd9"), "diamond"],
	"yuyuko_boss": [Color("fbb1d6"), "petal"],
	"ran_boss": [Color("ffe4a0"), "ofuda"],
	"yukari_boss": [Color("d1a1ff"), "ofuda"],
	"wriggle_boss": [Color("b8ea81"), "petal"],
	"mystia_boss": [Color("edb6e3"), "note"],
	"keine_boss": [Color("a5e5e8"), "ofuda"],
	"suika_boss": [Color("f2b072"), "diamond"],
	"nitori_boss": [Color("6fd3f2"), "drop"],
}


# Read only: animation shares the cast clock, so pause, phase changes and death
# use the combat lifecycle without introducing another timer or delayed action.
static func state(cast: Dictionary) -> Dictionary:
	var card: Dictionary = cast.get("card", {})
	var age := float(cast.get("age", 0.0))
	if card.is_empty() or String(card.get("origin", "")) == "nonspell" or String(card.get("id", "")).contains("nonspell") or age < 0.0 or age >= DURATION:
		return {}
	var palette: Array = THEMES.get(String(cast.get("kind", "")), [Color("d6b8ff"), "star"])
	var enter := clampf(age / 0.24, 0.0, 1.0)
	var leave := clampf((DURATION - age) / 0.42, 0.0, 1.0)
	return {"alpha": minf(enter, leave), "expand": 1.0 - pow(1.0 - clampf(age / 0.7, 0.0, 1.0), 3.0), "color": palette[0], "glyph": palette[1], "age": age, "name": String(card.get("name", "符卡展开"))}


static func glyph(canvas: CanvasItem, center: Vector2, radius: float, kind: String, angle: float, color: Color) -> void:
	var axis := Vector2.from_angle(angle)
	var side := axis.orthogonal()
	if kind == "maple":
		var points := PackedVector2Array()
		for p in [Vector2(0, -1), Vector2(0.25, -0.35), Vector2(0.8, -0.65), Vector2(0.5, -0.1), Vector2(1, 0.2), Vector2(0.3, 0.35), Vector2(0.2, 0.8), Vector2(0, 0.6), Vector2(-0.2, 0.8), Vector2(-0.3, 0.35), Vector2(-1, 0.2), Vector2(-0.5, -0.1), Vector2(-0.8, -0.65), Vector2(-0.25, -0.35)]:
			points.append(center + Vector2(p).rotated(angle) * radius)
		canvas.draw_colored_polygon(points, color)
		canvas.draw_line(center - axis * radius * 0.7, center + axis * radius, Color(color, color.a * 0.75), 1.2, true)
	elif kind == "grain":
		canvas.draw_line(center - axis * radius, center + axis * radius, color, 1.5, true)
		for i in range(3):
			var node := center + axis * radius * (i * 0.5 - 0.55)
			for sign in [-1, 1]:
				var tip: Vector2 = node - axis * radius * 0.35 + side * sign * radius * 0.35
				canvas.draw_line(node, tip, color, radius * 0.18, true)
	elif kind == "cross":
		canvas.draw_line(center - axis * radius, center + axis * radius, color, maxf(1.5, radius * 0.3), true)
		canvas.draw_line(center - side * radius, center + side * radius, color, maxf(1.5, radius * 0.3), true)
	elif kind == "eye":
		var outline := PackedVector2Array()
		for i in range(33):
			var t := TAU * i / 32.0
			outline.append(center + Vector2(cos(t) * radius * 1.5, sin(t) * radius * 0.65))
		canvas.draw_polyline(outline, color, 1.7, true)
		canvas.draw_circle(center, radius * 0.43, color)
		canvas.draw_line(center - Vector2(0, radius * 0.3), center + Vector2(0, radius * 0.3), Color("271329"), 2, true)
	elif kind == "ofuda":
		var points := PackedVector2Array([center - axis * radius - side * radius * 0.48, center + axis * radius - side * radius * 0.48, center + axis * radius + side * radius * 0.48, center - axis * radius + side * radius * 0.48])
		canvas.draw_colored_polygon(points, Color(color, color.a * 0.18))
		points.append(points[0])
		canvas.draw_polyline(points, color, 1.7, true)
		canvas.draw_line(center - axis * radius * 0.55, center + axis * radius * 0.55, color, 1.4, true)
		canvas.draw_line(center - side * radius * 0.28, center + side * radius * 0.28, color, 1.4, true)
	elif kind == "ice":
		for i in range(3):
			var spoke := Vector2.from_angle(angle + i * PI / 3.0) * radius
			canvas.draw_line(center - spoke, center + spoke, color, 1.6, true)
	elif kind == "drop":
		var points := PackedVector2Array()
		for i in range(16):
			var t := TAU * i / 16.0
			var swell := 1.0 - 0.55 * maxf(0.0, cos(t))
			points.append(center + (axis * cos(t) * radius * 1.15 + side * sin(t) * radius * 0.62 * swell))
		canvas.draw_colored_polygon(points, Color(color, color.a * 0.22))
		points.append(points[0])
		canvas.draw_polyline(points, color, 1.6, true)
		canvas.draw_circle(center - axis * radius * 0.25 + side * radius * 0.2, radius * 0.16, Color(1, 1, 1, color.a))
	elif kind == "note":
		canvas.draw_circle(center, radius * 0.4, color, true, -1, true)
		canvas.draw_line(center + side * radius * 0.3, center + side * radius * 0.3 - axis * radius * 1.7, color, 2, true)
		canvas.draw_line(center + side * radius * 0.3 - axis * radius * 1.7, center + side * radius * 1.05 - axis * radius * 1.3, color, 2, true)
	else:
		var vertices := 5 if kind == "star" else (6 if kind == "petal" else 4)
		var points := PackedVector2Array()
		for i in range(vertices * 2):
			points.append(center + Vector2.from_angle(angle + TAU * i / (vertices * 2.0)) * radius * (1.0 if i % 2 == 0 else 0.42))
		canvas.draw_colored_polygon(points, Color(color, color.a * 0.2))
		points.append(points[0])
		canvas.draw_polyline(points, color, 1.5, true)


static func draw(game: Control, cast: Dictionary) -> void:
	var visual := state(cast)
	if visual.is_empty() or float(visual.alpha) <= 0.0:
		return
	var scale: float = game._battle_unit_scale()
	var center := Vector2(cast.center)
	var age := float(visual.age)
	var alpha := float(visual.alpha)
	var color := Color(visual.color)
	var radius := (38.0 + 105.0 * float(visual.expand)) * scale
	# Soft local light only; leave the field, warnings and projectiles visible.
	game.draw_circle(center, radius, Color(color, alpha * 0.07), true, -1, true)
	for ring in range(3):
		var r := radius * (0.58 + ring * 0.2)
		var turn := age * (0.7 if ring % 2 == 0 else -0.9)
		game.draw_arc(center, r, turn, turn + TAU, 72, Color(color, alpha * (0.58 if ring == 2 else 0.28)), maxf(1.0, 1.8 * scale), true)
		for arc in range(4):
			var start := turn + arc * PI * 0.5
			game.draw_arc(center, r + 4 * scale, start, start + 0.36, 10, Color(color, alpha * 0.82), maxf(1.0, 2.4 * scale), true)
	for i in range(12):
		var turn := TAU * i / 12.0 + age * 0.32
		var point := center + Vector2.from_angle(turn) * radius * 0.81
		glyph(game, point, (9.0 if String(visual.glyph) != "ofuda" else 12.0) * scale, String(visual.glyph), turn + PI * 0.5, Color(color, alpha * 0.83))
	if String(visual.glyph) == "clock":
		game.draw_line(center, center + Vector2.from_angle(-PI * 0.5 + age) * radius * 0.52, Color(color, alpha * 0.6), 2.4 * scale, true)
		game.draw_line(center, center + Vector2.from_angle(age * 3) * radius * 0.34, Color(color, alpha * 0.6), 2.4 * scale, true)
	for i in range(20):
		var turn := TAU * i / 20.0 + sin(i * 4.7) * 0.14
		var distance := (50.0 + age * (92.0 + float(i % 4) * 12.0)) * scale
		var point := center + Vector2.from_angle(turn) * distance
		game.draw_line(point, point - Vector2.from_angle(turn) * 9 * scale, Color(color, alpha * 0.43), maxf(1.0, 1.8 * scale), true)
	var board := Rect2(game.BOARD_ORIGIN, game.board_size)
	var ui_scale := maxf(scale, 0.62)
	var slide := (1.0 - float(visual.expand)) * 44.0 * ui_scale
	# A compact tag at the board's upper-right edge, as in the original games, so the first
	# row of plants stays readable while the card is declared.
	var name_size := maxi(15, roundi(22 * ui_scale))
	var name_width: float = game.ui_font.get_string_size(String(visual.name), HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
	var height := 42.0 * ui_scale
	var width := minf(board.size.x - 36 * ui_scale, name_width + 168 * ui_scale)
	var banner := Rect2(Vector2(board.end.x - 14 * ui_scale - width + slide, board.position.y - height * 0.5), Vector2(width, height))
	ThemeLib.draw_rounded_panel(game, banner, Color(0.035, 0.045, 0.085, alpha * 0.74), Color(color, alpha * 0.7), 9 * ui_scale, 0.0)
	glyph(game, banner.position + Vector2(22 * ui_scale, height * 0.5), 10 * ui_scale, String(visual.glyph), -PI * 0.5, Color(color, alpha))
	ThemeLib.draw_label(game, game.ui_font, Rect2(banner.position + Vector2(40, 0) * ui_scale, Vector2(84 * ui_scale, height)), "符卡展开", maxi(11, roundi(14 * ui_scale)), Color(color, alpha))
	ThemeLib.draw_label(game, game.ui_font, Rect2(banner.position + Vector2(124 * ui_scale, 0), Vector2(banner.size.x - 136 * ui_scale, height)), String(visual.name), name_size, Color(1, 0.97, 0.91, alpha), HORIZONTAL_ALIGNMENT_RIGHT, maxi(10, roundi(13 * ui_scale)))
