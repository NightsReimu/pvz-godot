extends RefCounted
# Small vector sigils for Touhou boss seals, auras and declarations. Each one
# reads at 6-14 px: a single silhouette in the tint, with at most one detail.

const KINDS := ["moon", "flower", "snow", "rainbow", "book", "element", "clock", "bat", "crystal", "pentagram", "doll", "note", "sword", "butterfly", "fox", "gap", "firefly", "feather", "scroll", "clover", "yinyang", "star", "eye", "arrow", "jewel", "flame", "gourd"]

static func _poly(canvas: CanvasItem, center: Vector2, radius: float, angle: float, points: Array, tint: Color) -> void:
	var shape := PackedVector2Array()
	for v in points:
		shape.append(center + Vector2(v).rotated(angle) * radius)
	canvas.draw_colored_polygon(shape, tint)

static func draw(canvas: CanvasItem, center: Vector2, radius: float, kind: String, angle: float, tint: Color) -> bool:
	var axis := Vector2.from_angle(angle)
	var side := axis.orthogonal()
	var line := maxf(1.0, radius * 0.18)
	match kind:
		"moon":
			var outer := PackedVector2Array()
			for i in range(13):
				var t := -PI * 0.75 + PI * 1.5 * i / 12.0
				outer.append(center + Vector2.from_angle(t + angle) * radius)
			for i in range(13):
				var t := PI * 0.75 - PI * 1.5 * i / 12.0
				outer.append(center + axis * radius * 0.42 + Vector2.from_angle(t + angle) * radius * 0.78)
			canvas.draw_colored_polygon(outer, tint)
		"flower", "clover":
			var petals := 4 if kind == "clover" else 5
			for i in range(petals):
				var a := angle + TAU * i / petals
				canvas.draw_circle(center + Vector2.from_angle(a) * radius * 0.52, radius * (0.46 if kind == "clover" else 0.4), tint)
			canvas.draw_circle(center, radius * 0.26, Color(1, 0.96, 0.7, tint.a))
		"snow":
			for i in range(3):
				var spoke := Vector2.from_angle(angle + i * PI / 3.0) * radius
				canvas.draw_line(center - spoke, center + spoke, tint, line, true)
				for sign in [-1.0, 1.0]:
					var tip: Vector2 = center + spoke * sign * 0.62
					var branch := spoke.normalized().orthogonal() * radius * 0.24
					canvas.draw_line(tip, tip + spoke * sign * 0.2 + branch, tint, line * 0.7, true)
					canvas.draw_line(tip, tip + spoke * sign * 0.2 - branch, tint, line * 0.7, true)
		"rainbow":
			var colors := [Color("f05a5a"), Color("f6c65a"), Color("6fd88a"), Color("62b4f2"), Color("b48cf0")]
			for i in range(colors.size()):
				canvas.draw_arc(center + axis * radius * 0.35, radius * (1.0 - i * 0.16), angle + PI, angle + TAU, 10, Color(colors[i], tint.a), line * 0.8, true)
		"book":
			_poly(canvas, center, radius, angle, [Vector2(-0.9, -0.7), Vector2(0, -0.5), Vector2(0, 0.8), Vector2(-0.9, 0.6)], tint)
			_poly(canvas, center, radius, angle, [Vector2(0.9, -0.7), Vector2(0, -0.5), Vector2(0, 0.8), Vector2(0.9, 0.6)], Color(tint, tint.a * 0.75))
		"element":
			var pent := PackedVector2Array()
			for i in range(6):
				pent.append(center + Vector2.from_angle(angle - PI * 0.5 + TAU * i / 5.0) * radius)
			canvas.draw_polyline(pent, tint, line, true)
			var hues := [Color("f06a4a"), Color("5ab8f0"), Color("6ad070"), Color("e8e0c8"), Color("d8a860")]
			for i in range(5):
				canvas.draw_circle(pent[i], radius * 0.2, Color(hues[i], tint.a))
		"clock":
			canvas.draw_arc(center, radius, 0, TAU, 16, tint, line, true)
			canvas.draw_line(center, center + Vector2.from_angle(angle - PI * 0.5) * radius * 0.75, tint, line, true)
			canvas.draw_line(center, center + Vector2.from_angle(angle) * radius * 0.5, tint, line, true)
		"bat":
			_poly(canvas, center, radius, angle, [Vector2(0, -0.25), Vector2(0.35, -0.55), Vector2(1, -0.5), Vector2(0.8, -0.1), Vector2(1, 0.25), Vector2(0.55, 0.15), Vector2(0.3, 0.45), Vector2(0, 0.25), Vector2(-0.3, 0.45), Vector2(-0.55, 0.15), Vector2(-1, 0.25), Vector2(-0.8, -0.1), Vector2(-1, -0.5), Vector2(-0.35, -0.55)], tint)
		"crystal":
			canvas.draw_line(center - side * radius * 0.9, center + side * radius * 0.9, Color(tint, tint.a * 0.7), line * 0.7, true)
			var hues := [Color("f05a5a"), Color("f6c65a"), Color("6fd88a"), Color("62b4f2"), Color("b48cf0"), Color("f08ad0")]
			for i in range(6):
				var p := center + side * radius * (-0.8 + i * 0.32) + axis * radius * 0.25
				_poly(canvas, p, radius * 0.32, angle, [Vector2(0, -0.2), Vector2(0.35, 0.4), Vector2(0, 1.1), Vector2(-0.35, 0.4)], Color(hues[i], tint.a))
		"pentagram":
			var star := PackedVector2Array()
			for i in range(6):
				star.append(center + Vector2.from_angle(angle - PI * 0.5 + TAU * (i * 2 % 5) / 5.0) * radius)
			canvas.draw_polyline(star, tint, line, true)
		"doll":
			canvas.draw_circle(center - axis * radius * 0.45, radius * 0.36, tint)
			_poly(canvas, center, radius, angle, [Vector2(-0.6, 0.95), Vector2(-0.25, -0.15), Vector2(0.25, -0.15), Vector2(0.6, 0.95)], tint)
			canvas.draw_line(center - axis * radius * 0.85, center - axis * radius * 1.4, Color(tint, tint.a * 0.6), 1.0, true)
		"note":
			canvas.draw_circle(center + axis * radius * 0.5, radius * 0.38, tint)
			canvas.draw_line(center + axis * radius * 0.5 + side * radius * 0.34, center - axis * radius * 0.9 + side * radius * 0.34, tint, line, true)
			canvas.draw_line(center - axis * radius * 0.9 + side * radius * 0.34, center - axis * radius * 0.5 + side * radius * 0.95, tint, line, true)
		"sword":
			canvas.draw_line(center - axis * radius, center + axis * radius * 0.55, tint, line * 1.1, true)
			canvas.draw_line(center + axis * radius * 0.55 - side * radius * 0.35, center + axis * radius * 0.55 + side * radius * 0.35, tint, line, true)
			canvas.draw_line(center + axis * radius * 0.6, center + axis * radius, Color(tint, tint.a * 0.7), line * 1.3, true)
		"butterfly":
			for sign in [-1.0, 1.0]:
				_poly(canvas, center, radius, angle, [Vector2(0, -0.1), Vector2(sign * 0.95, -0.85), Vector2(sign * 0.8, 0.0)], tint)
				_poly(canvas, center, radius, angle, [Vector2(0, 0.05), Vector2(sign * 0.65, 0.2), Vector2(sign * 0.45, 0.8)], Color(tint, tint.a * 0.75))
		"fox":
			for k in range(3):
				var a := angle + (k - 1) * 0.55
				var tip := center + Vector2.from_angle(a - PI * 0.5) * radius
				_poly(canvas, center, 1.0, 0.0, [Vector2.ZERO, tip - center + Vector2.from_angle(a) * radius * 0.25, tip - center, tip - center - Vector2.from_angle(a) * radius * 0.25], tint)
			canvas.draw_circle(center, radius * 0.3, Color(1, 0.94, 0.75, tint.a))
		"gap":
			var lid := PackedVector2Array()
			for i in range(17):
				var t := TAU * i / 16.0
				lid.append(center + axis * cos(t) * radius + side * sin(t) * radius * 0.42)
			canvas.draw_colored_polygon(lid, Color(0.12, 0.04, 0.16, tint.a * 0.9))
			lid.append(lid[0])
			canvas.draw_polyline(lid, tint, line * 0.8, true)
			canvas.draw_circle(center, radius * 0.22, Color(0.95, 0.35, 0.45, tint.a))
		"firefly":
			canvas.draw_circle(center, radius * 0.95, Color(tint, tint.a * 0.25))
			canvas.draw_circle(center + axis * radius * 0.2, radius * 0.42, tint)
			canvas.draw_circle(center - axis * radius * 0.35, radius * 0.24, Color(0.2, 0.18, 0.12, tint.a))
		"feather":
			_poly(canvas, center, radius, angle, [Vector2(1, 0), Vector2(0.1, 0.48), Vector2(-1, 0.1), Vector2(0.1, -0.42)], tint)
			canvas.draw_line(center - axis * radius * 1.15, center + axis * radius, Color(1, 1, 1, tint.a * 0.7), 1.0, true)
		"scroll":
			_poly(canvas, center, radius, angle, [Vector2(-0.75, -0.55), Vector2(0.75, -0.55), Vector2(0.75, 0.55), Vector2(-0.75, 0.55)], Color(tint, tint.a * 0.6))
			for s in [-1.0, 1.0]:
				canvas.draw_line(center + axis * radius * 0.85 * s - side * radius * 0.7, center + axis * radius * 0.85 * s + side * radius * 0.7, tint, line * 1.4, true)
		"yinyang":
			canvas.draw_circle(center, radius, Color(1, 1, 1, tint.a))
			var half := PackedVector2Array()
			for i in range(13):
				half.append(center + Vector2.from_angle(angle + PI * i / 12.0) * radius)
			canvas.draw_colored_polygon(half, tint)
			canvas.draw_circle(center + axis * radius * 0.5, radius * 0.5, tint)
			canvas.draw_circle(center - axis * radius * 0.5, radius * 0.5, Color(1, 1, 1, tint.a))
			canvas.draw_circle(center + axis * radius * 0.5, radius * 0.15, Color(1, 1, 1, tint.a))
			canvas.draw_circle(center - axis * radius * 0.5, radius * 0.15, tint)
		"star":
			var star := PackedVector2Array()
			for i in range(10):
				star.append(center + Vector2.from_angle(angle - PI * 0.5 + TAU * i / 10.0) * radius * (1.0 if i % 2 == 0 else 0.45))
			canvas.draw_colored_polygon(star, tint)
		"eye":
			var outline := PackedVector2Array()
			for i in range(17):
				var t := TAU * i / 16.0
				outline.append(center + axis * cos(t) * radius * 1.2 + side * sin(t) * radius * 0.55)
			canvas.draw_colored_polygon(outline, Color(tint, tint.a * 0.3))
			canvas.draw_circle(center, radius * 0.42, tint)
			canvas.draw_circle(center, radius * 0.16, Color(0.12, 0.04, 0.1, tint.a))
		"arrow":
			canvas.draw_line(center - axis * radius, center + axis * radius * 0.6, tint, line, true)
			_poly(canvas, center, radius, angle, [Vector2(1, 0), Vector2(0.45, 0.32), Vector2(0.45, -0.32)], tint)
			canvas.draw_line(center - axis * radius + side * radius * 0.3, center - axis * radius * 0.6, tint, line * 0.7, true)
			canvas.draw_line(center - axis * radius - side * radius * 0.3, center - axis * radius * 0.6, tint, line * 0.7, true)
		"jewel":
			_poly(canvas, center, radius, angle, [Vector2(0, -1), Vector2(0.7, -0.3), Vector2(0.45, 0.8), Vector2(-0.45, 0.8), Vector2(-0.7, -0.3)], tint)
			canvas.draw_line(center - axis * radius * 0.3 - side * radius * 0.6, center - axis * radius * 0.3 + side * radius * 0.6, Color(1, 1, 1, tint.a * 0.7), 1.0, true)
		"flame":
			_poly(canvas, center, radius, angle, [Vector2(0, -1.1), Vector2(0.45, -0.3), Vector2(0.6, 0.35), Vector2(0, 0.8), Vector2(-0.6, 0.35), Vector2(-0.45, -0.3)], tint)
			_poly(canvas, center, radius * 0.55, angle, [Vector2(0, -0.8), Vector2(0.45, 0.25), Vector2(0, 0.9), Vector2(-0.45, 0.25)], Color(1, 0.95, 0.65, tint.a))
		"gourd":
			canvas.draw_circle(center + axis * radius * 0.35, radius * 0.55, tint)
			canvas.draw_circle(center - axis * radius * 0.4, radius * 0.36, tint)
			canvas.draw_line(center - axis * radius * 0.75, center - axis * radius * 1.0, Color(0.5, 0.3, 0.2, tint.a), line, true)
		_:
			return false
	return true
