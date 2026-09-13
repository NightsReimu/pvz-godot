extends RefCounted

const KINDS = ["star_fairy", "kedama", "mini_kedama", "rabbit_airship", "eirin_medicine"]
var game: Control

func _init(owner: Control) -> void:
	game = owner

func update_unit(z: Dictionary, delta: float) -> bool:
	if float(z.health) <= 0 or game.boss_time_stop_timer > 0:
		return String(z.kind) in ["rabbit_airship", "eirin_medicine"]
	if String(z.kind) == "eirin_medicine":
		return true
	if String(z.kind) == "rabbit_airship":
		_update_airship(z, delta)
		return true
	if String(z.kind) == "star_fairy" and game._is_enemy_zombie(z):
		z["fairy_timer"] = float(z.get("fairy_timer", 5.0)) - delta
		if float(z.fairy_timer) <= 0:
			z.fairy_timer = 5.0
			var row = int(z.row)
			for col in range(game.COLS - 1, -1, -1):
				if game._cell_center(row, col).x < float(z.x) and game._targetable_plant_at(row, col) != null:
					z["fairy_target"] = Vector2i(row, col)
					z["fairy_warning"] = 1.0 + delta
					break
		if float(z.get("fairy_warning", 0)) > 0:
			z.fairy_warning -= delta
			if float(z.fairy_warning) <= 0:
				var cell: Vector2i = z.fairy_target
				game._damage_plant_cell(cell.x, cell.y, 38.0, 0.0)
	return false

func _update_airship(z: Dictionary, delta: float) -> void:
	if not z.has("airship_next_col"):
		z["airship_next_col"] = game.COLS - 1
		z["airship_returning"] = false
		z["airship_drops"] = []
	var budget: float = game._current_zombie_speed(z) * maxf(0, delta)
	while budget > 0.001 and float(z.health) > 0:
		var returning = bool(z.airship_returning)
		var next_col = int(z.airship_next_col)
		var leaving = returning and next_col >= game.COLS
		var target: float = game.BOARD_ORIGIN.x + game.board_size.x + 140 if leaving else game._cell_center(int(z.row), next_col).x
		var distance = absf(target - float(z.x))
		if budget < distance:
			z.x = move_toward(float(z.x), target, budget)
			break
		z.x = target
		budget -= distance
		if leaving:
			z["airship_departed"] = true
			z.health = 0.0
			break
		z.airship_drops.append(next_col)
		if game._count_alive_enemy_zombies_by_kind("moon_rabbit_guard") < 28 and game._active_zombie_count() < 65:
			game._spawn_zombie_at("moon_rabbit_guard", int(z.row), target, true)
		if not returning and next_col == 2:
			z.airship_returning = true
			z.airship_next_col = 3
		else:
			z.airship_next_col += 1 if returning else -1

func on_death(z: Dictionary) -> void:
	if String(z.kind) != "kedama" or z.get("kedama_split", false):
		return
	z["kedama_split"] = true
	for n in range(2):
		if game._count_alive_enemy_zombies_by_kind("mini_kedama") >= 12 or game._active_zombie_count() >= 65:
			break
		game._spawn_zombie_at("mini_kedama", int(z.row), float(z.x) + (n * 2 - 1) * 13, true)
		if not game._is_enemy_zombie(z):
			game.zombies.back()["hypnotized"] = true

func _oval(center: Vector2, half: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	for n in range(33):
		var a = TAU * n / 32
		points.append(center + Vector2(cos(a) * half.x, sin(a) * half.y))
	game.draw_colored_polygon(points, color)
	game.draw_polyline(points, Color("17243b"), 2, true)

func _star(center: Vector2, radius: float, color: Color, rotation: float = 0.0) -> void:
	var points = PackedVector2Array()
	for n in range(10):
		var a = -PI / 2 + TAU * n / 10 + rotation
		points.append(center + Vector2(cos(a), sin(a)) * radius * (1.0 if n % 2 == 0 else 0.45))
	game.draw_colored_polygon(points, color)

func draw_unit(center: Vector2, z: Dictionary) -> void:
	var kind = String(z.kind)
	var t = game.level_time + float(z.get("anim_phase", 0))
	var p = center + Vector2(0, sin(t * 3) * 3)
	if kind == "rabbit_airship":
		p.y -= 27
		_oval(p + Vector2(0, -30), Vector2(58, 25), Color("9eacc9"))
		_oval(p + Vector2(-6, -36), Vector2(42, 13), Color("e1d9e4"))
		for x in [-32, -12, 12, 32]:
			game.draw_line(p + Vector2(x, -48), p + Vector2(x * 0.85, -10), Color("6b7199"), 2, true)
		game.draw_line(p + Vector2(-30, -10), p + Vector2(-20, 12), Color("c7cee9"), 2)
		game.draw_line(p + Vector2(30, -10), p + Vector2(20, 12), Color("c7cee9"), 2)
		_oval(p + Vector2(0, 13), Vector2(28, 13), Color("4b536f"))
		_oval(p + Vector2(0, 3), Vector2(12, 13), Color("e8e4e8"))
		for side in [-1, 1]:
			_oval(p + Vector2(side * 7, -11), Vector2(4, 12), Color("efd9e0"))
			game.draw_circle(p + Vector2(side * 5, 2), 2, Color("f95183"))
		var rotor = p + Vector2(47 if z.get("airship_returning", false) else -47, 9)
		game.draw_line(rotor - Vector2(0, 14 * cos(t * 24)), rotor + Vector2(0, 14 * cos(t * 24)), Color("d3e8eb"), 3)
		_star(p + Vector2(7, -32), 10, Color("da677f"))
	elif kind in ["kedama", "mini_kedama"]:
		var s = 0.62 if kind == "mini_kedama" else 1.0
		var points = PackedVector2Array()
		for n in range(40):
			var a = TAU * n / 40
			points.append(p + Vector2(cos(a), sin(a)) * (32 if n % 2 == 0 else 25) * s)
		game.draw_colored_polygon(points, Color("ddd8ed"))
		game.draw_polyline(points, Color("666282"), 2, true)
		_oval(p + Vector2(-6, -9) * s, Vector2(19, 14) * s, Color("f3edf6"))
		for side in [-1, 1]:
			game.draw_circle(p + Vector2(side * 9, 2) * s, 4 * s, Color("554360"))
		game.draw_arc(p + Vector2(0, 8) * s, 5 * s, 0, PI, 8, Color("8b607e"), 1.5)
	elif kind == "star_fairy":
		p.y -= 9
		for side in [-1, 1]:
			_oval(p + Vector2(side * (22 + sin(t * 12) * 4), -14), Vector2(15, 24), Color(0.6, 0.86, 1, 0.62))
		game.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -13), p + Vector2(-23, 29), p + Vector2(23, 29)]), Color("6a80c5"))
		_oval(p + Vector2(0, -22), Vector2(17, 18), Color("efdbd2"))
		game.draw_arc(p + Vector2(0, -24), 17, PI, TAU + 0.4, 20, Color("d4deed"), 9, true)
		for side in [-1, 1]:
			game.draw_circle(p + Vector2(side * 6, -21), 2.3, Color("55324f"))
		_star(p + Vector2(0, -45), 10, Color("fff1a5"), t * 0.3)
		game.draw_line(p + Vector2(-13, 0), p + Vector2(-32, -8), Color("e2b995"), 3)
		_star(p + Vector2(-34, -11), 9, Color("ffdeb2"), t)
	elif kind == "eirin_medicine":
		var tint = Color("8ca6ff") if String(z.get("medicine_kind", "rage")) == "suppression" else Color("ff6b88")
		_oval(p + Vector2(0, 2), Vector2(21, 25), Color("bbcbd9"))
		_oval(p + Vector2(0, 9), Vector2(16, 16), tint)
		game.draw_rect(Rect2(p + Vector2(-9, -33), Vector2(18, 16)), Color("e0d8be"))
		game.draw_line(p - Vector2(8, 0), p + Vector2(8, 0), Color.WHITE, 4)
		game.draw_line(p - Vector2(0, 8), p + Vector2(0, 8), Color.WHITE, 4)
