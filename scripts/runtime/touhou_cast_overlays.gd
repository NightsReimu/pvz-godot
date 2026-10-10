extends RefCounted
# Casting flourishes for the Touhou bosses whose cards keep their own emitters
# (Reimu, Marisa, Reisen, Tewi, Mokou, Keine's Hakutaku form, Suika). Read-only:
# everything follows the cast clock and owns no timers or attacks.

const Glyphs = preload("res://scripts/ui/touhou_glyphs.gd")
const KINDS := ["reimu_boss", "marisa_boss", "reisen_boss", "tewi_boss", "mokou_boss", "hakutaku_boss", "suika_boss"]

static func draw(game: Control, c: Dictionary) -> void:
	var kind := String(c.kind)
	if not kind in KINDS:
		return
	var u := minf(game.CELL_SIZE.x / 135.0, game.CELL_SIZE.y / 127.0)
	var o := Vector2(c.center)
	var t := float(c.age)
	var fade := clampf(t / 0.4, 0.0, 1.0) * clampf((float(c.duration) - t) / 0.4, 0.0, 1.0)
	if fade <= 0.01:
		return
	var p := String(c.pattern)
	var formal := not p.begins_with("nonspell")
	match kind:
		"reimu_boss":
			# Yin-yang orbs circle her; the dream-seal cards add coloured orbs.
			var count := 4 if formal else 2
			for k in range(count):
				var a := t * 2.2 + TAU * k / count
				var spot := o + Vector2(cos(a) * 52.0, sin(a) * 22.0 - 26.0) * u
				game.draw_circle(spot, 10.0 * u, Color(1, 0.5, 0.55, 0.15 * fade))
				Glyphs.draw(game, spot, 7.0 * u, "yinyang", a * 2.0, Color(0.92, 0.25, 0.32, 0.9 * fade))
			if p.contains("reimu_spread") or p.contains("reimu_worn") or p.contains("reimu_concentrate") or p.contains("reimu_returning"):
				var hues := [Color("f65a76"), Color("72cdeb"), Color("b594f3"), Color("f1cc70"), Color("87d6a4")]
				for k in range(5):
					var a := -t * 1.4 + TAU * k / 5.0
					game.draw_circle(o + Vector2.from_angle(a) * 74.0 * u, 7.0 * u, Color(hues[k], 0.45 * fade))
		"marisa_boss":
			# The Mini-Hakkero glows in her hands; spark cards charge it white-hot.
			var hakkero := o + Vector2(-34, -22) * u
			var charge := 0.5 + 0.5 * sin(t * 6.0)
			if p.contains("spark"):
				charge = 1.0
				for k in range(8):
					var a := TAU * k / 8.0 + t * 3.0
					game.draw_line(hakkero + Vector2.from_angle(a) * 10.0 * u, hakkero + Vector2.from_angle(a) * (22.0 + 6.0 * sin(t * 12.0 + k)) * u, Color(1, 0.95, 0.7, 0.6 * fade), 2.0 * u, true)
			game.draw_circle(hakkero, (14.0 + charge * 6.0) * u, Color(1, 0.8, 0.35, 0.18 * fade))
			game.draw_circle(hakkero, 6.0 * u, Color(1, 0.95, 0.8, 0.8 * fade))
			for k in range(5):
				var rise := fposmod(t * 0.7 + k * 0.2, 1.0)
				Glyphs.draw(game, o + Vector2((k - 2) * 16.0, -20.0 - rise * 70.0) * u, 5.0 * u, "star", t + k, Color([Color("ffc85a"), Color("7cd6ff"), Color("d59afa")][k % 3], (1.0 - rise) * 0.8 * fade))
		"reisen_boss", "tewi_boss":
			if kind == "tewi_boss":
				for k in range(4):
					var a := t * 1.5 + TAU * k / 4.0
					Glyphs.draw(game, o + Vector2(cos(a) * 40.0, sin(a) * 18.0 - 20.0) * u, 6.0 * u, "clover", a, Color(0.6, 0.95, 0.55, 0.8 * fade))
				return
			# The lunatic red eyes: ripples of madness spreading from her gaze.
			var eye := o + Vector2(-6, -44) * u
			for k in range(3):
				var ring := fposmod(t * 0.9 + k / 3.0, 1.0)
				game.draw_arc(eye, (12.0 + ring * 70.0) * u, 0, TAU, 32, Color(1, 0.3, 0.45, (1.0 - ring) * 0.5 * fade), 1.8 * u, true)
			Glyphs.draw(game, eye, 8.0 * u, "eye", 0.0, Color(1, 0.35, 0.5, 0.85 * fade))
		"mokou_boss":
			# Phoenix wings of flame unfold behind her.
			for side in [-1.0, 1.0]:
				for k in range(6):
					var a: float = -PI * 0.5 + side * (0.5 + k * 0.22) + sin(t * 4.0 + k) * 0.05
					var spot := o + Vector2(12, -30) * u + Vector2.from_angle(a) * (26.0 + k * 9.0) * u
					Glyphs.draw(game, spot, (11.0 - k) * u, "flame", a + PI * 0.5, Color(1, 0.5 + k * 0.06, 0.25, (0.65 - k * 0.07) * fade))
		"hakutaku_boss":
			for k in range(3):
				var spot := o + Vector2(-50.0 - k * 6.0, -50.0 + k * 22.0) * u
				Glyphs.draw(game, spot + Vector2(0, sin(t * 2.0 + k) * 4.0 * u), 9.0 * u, "scroll", 0.0, Color(0.65, 0.95, 0.6, 0.6 * fade))
		"suika_boss":
			# Her gourd and a drifting haze of mist.
			Glyphs.draw(game, o + Vector2(30, -20) * u, 10.0 * u, "gourd", 0.4 + sin(t * 2.0) * 0.2, Color(0.95, 0.65, 0.4, 0.85 * fade))
			for k in range(6):
				var drift := fposmod(t * 0.3 + k / 6.0, 1.0)
				game.draw_circle(o + Vector2(-20.0 - drift * 120.0, (k - 2.5) * 22.0) * u, (18.0 + drift * 20.0) * u, Color(0.95, 0.85, 0.75, 0.08 * (1.0 - drift) * fade))
