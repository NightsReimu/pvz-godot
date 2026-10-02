extends RefCounted

const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const ROOT := "res://art/storybook_ui/"
const MENU_MODES := ["home", "world_select", "map", "almanac", "minigames", "daily", "base", "enhance", "gacha", "selection"]
const DARK_MODES := ["daily", "base", "enhance", "gacha"]
const REGIONS := {
	"parchment": Rect2(63, 63, 1130, 1127),
	"wood_plaque": Rect2(31, 104, 2112, 488),
	"lantern": Rect2(300, 0, 402, 1514),
}

var textures := {}
var control_styles := {}
var motions := {}
var particles: Array = []
var page_mode := ""
var page_age := 10.0
var pointer_down := false
var press_position := Vector2(-9999, -9999)
var preview_index := -1
var previous_preview := -1
var preview_age := 1.0


func texture(key: String) -> Texture2D:
	if not textures.has(key):
		textures[key] = load(ROOT + key + ".png")
	return textures[key]


func control_style(key: String, tint: Color = Color.WHITE) -> StyleBoxTexture:
	if not control_styles.has(key):
		# Small, in-memory atlas derivative gives Control's nine-patch corners
		# the same physical size as our CanvasItem panels. Originals stay intact.
		var image := texture(key).get_image().get_region(Rect2i(REGIONS[key]))
		image.resize(240 if key == "parchment" else 480, 240 if key == "parchment" else 110, Image.INTERPOLATE_LANCZOS)
		var style := StyleBoxTexture.new()
		style.texture = ImageTexture.create_from_image(image)
		var edge := 40.0 if key == "parchment" else 21.0
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, edge)
			style.set_content_margin(side, 24.0 if key == "parchment" else 8.0)
		control_styles[key] = style
	var value: StyleBoxTexture = control_styles[key].duplicate()
	value.modulate_color = tint
	return value


static func is_menu(mode: String) -> bool:
	return mode in MENU_MODES


static func spring(value: float, velocity: float, target: float, delta: float) -> Vector2:
	# Bounded substeps keep suspend/resume and low frame rates from exploding.
	var remaining := clampf(delta, 0.0, 0.2)
	while remaining > 0.00001:
		var step := minf(remaining, 1.0 / 120.0)
		velocity += ((target - value) * 210.0 - velocity * 23.0) * step
		value += velocity * step
		remaining -= step
	return Vector2(clampf(value, -0.05, 1.08), velocity)


func update(game: Control, delta: float) -> void:
	if page_mode != game.mode:
		page_mode = game.mode
		page_age = 0.0
		motions.clear()
		pointer_down = false
	page_age = minf(10.0, page_age + maxf(0.0, delta))
	if preview_index != game.world_select_index:
		previous_preview = preview_index
		preview_index = game.world_select_index
		preview_age = 0.0
	preview_age = minf(1.0, preview_age + maxf(delta, 0.0))
	var pointer: Vector2 = game._pointer_local_position()
	var blocked: bool = game.page_transition_active or game._touhou_difficulty_is_open() or game._level_difficulty_is_open()
	for key in motions.keys():
		var state: Dictionary = motions[key]
		if game.ui_time - float(state.seen) > 0.8:
			motions.erase(key)
			continue
		var hovered: bool = not blocked and not bool(state.disabled) and Rect2(state.rect).has_point(pointer)
		var hover := spring(float(state.hover), float(state.velocity), 1.0 if hovered else 0.0, delta)
		state.hover = hover.x
		state.velocity = hover.y
		var pressed: bool = pointer_down and not blocked and not bool(state.disabled) and Rect2(state.rect).has_point(press_position)
		state.press = move_toward(float(state.press), 1.0 if pressed else 0.0, delta * 14.0)
	for i in range(particles.size() - 1, -1, -1):
		particles[i].age += maxf(0.0, delta)
		if float(particles[i].age) >= 0.65:
			particles.remove_at(i)
	if not is_menu(game.mode):
		particles.clear()


func record_input(_game: Control, event: InputEvent, position: Vector2) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_down = event.pressed
		press_position = position
	elif event is InputEventScreenTouch:
		pointer_down = event.pressed
		press_position = position
	elif event is InputEventScreenDrag:
		press_position = position


func click(position: Vector2) -> void:
	# Small, finite bursts; they never intercept input or alter the simulation.
	while particles.size() > 72:
		particles.pop_front()
	for i in range(8):
		particles.append({"position": position, "angle": TAU * i / 8.0 + 0.2, "age": 0.0, "seed": i})


func state(game: Control, rect: Rect2, id: String, disabled: bool = false) -> Dictionary:
	var key: String = game.mode + ":" + id
	if not motions.has(key):
		motions[key] = {"rect": rect, "hover": 0.0, "velocity": 0.0, "press": 0.0, "seen": game.ui_time, "disabled": disabled}
	var value: Dictionary = motions[key]
	value.rect = rect
	value.seen = game.ui_time
	value.disabled = disabled
	return value


func surface(game: Control, rect: Rect2, id: String, disabled: bool = false, stagger: float = 0.0) -> Rect2:
	var value := state(game, rect, id, disabled)
	var reveal := ThemeLib.ease_out(clampf((page_age - stagger) / 0.38, 0, 1)) if page_mode == game.mode else 1.0
	return Rect2(rect.position + Vector2(0, (1.0 - reveal) * 12.0 - float(value.hover) * 4.0 + float(value.press) * 5.0), rect.size)


func nine_slice(game: Control, key: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var tex := texture(key)
	if tex == null or rect.size.x < 1 or rect.size.y < 1:
		return
	var source: Rect2 = REGIONS.get(key, Rect2(Vector2.ZERO, tex.get_size()))
	var edge: Vector2 = Vector2(240, 230) if key == "parchment" else Vector2(265, 95)
	var corner := minf(36.0 if key == "parchment" else 18.0, minf(rect.size.x, rect.size.y) * 0.26)
	var sx := [source.position.x, source.position.x + edge.x, source.end.x - edge.x, source.end.x]
	var sy := [source.position.y, source.position.y + edge.y, source.end.y - edge.y, source.end.y]
	var dx := [rect.position.x, rect.position.x + corner, rect.end.x - corner, rect.end.x]
	var dy := [rect.position.y, rect.position.y + corner, rect.end.y - corner, rect.end.y]
	for row in range(3):
		for col in range(3):
			game.draw_texture_rect_region(tex, Rect2(dx[col], dy[row], dx[col + 1] - dx[col], dy[row + 1] - dy[row]), Rect2(sx[col], sy[row], sx[col + 1] - sx[col], sy[row + 1] - sy[row]), tint)


func panel(game: Control, rect: Rect2, fill: Color, border: Color, shadow: float = 0.14) -> void:
	if rect.size.x < 90 or rect.size.y < 42 or fill.a < 0.35:
		ThemeLib.draw_rounded_panel(game, rect, fill, border, 9, shadow)
		if rect.size.x >= 54 and rect.size.y >= 52 and fill.a > 0.5:
			game.draw_texture_rect_region(texture("parchment"), rect.grow(-3), Rect2(350, 350, 500, 500), Color(1, 1, 1, 0.13))
			for corner in [rect.position + Vector2(5, 5), Vector2(rect.end.x - 5, rect.position.y + 5)]:
				game.draw_circle(corner, 1.5, Color("b49a56"), true, -1, true)
		return
	ThemeLib.draw_soft_shadow(game, rect, Color(0.10, 0.065, 0.035, shadow), 2, 4.0, 4.0)
	var tint := Color.WHITE
	if fill.get_luminance() < 0.36:
		tint = Color(fill.lightened(0.06), fill.a)
	else:
		tint = Color(fill.lerp(Color.WHITE, 0.68), fill.a)
	nine_slice(game, "parchment", rect, tint)
	if fill.get_luminance() < 0.36:
		# A gold inlay stays visible on nocturnal workshop / summoning panels.
		var line := Color(border.lerp(Color("bdab77"), 0.45), 0.45 * fill.a)
		game.draw_line(rect.position + Vector2(18, 8), Vector2(rect.end.x - 18, rect.position.y + 8), line, 1, true)
		game.draw_line(Vector2(rect.position.x + 18, rect.end.y - 8), rect.end - Vector2(18, 8), line, 1, true)


func button(game: Control, rect: Rect2, text: String, fill: Color, border: Color, font_size: int = 22) -> void:
	var disabled := text in ["尚未解锁", "未开放"]
	var id := "button:%s:%s" % [rect.position, rect.size]
	var value := state(game, rect, id, disabled)
	var drawn := surface(game, rect, id, disabled)
	ThemeLib.draw_soft_shadow(game, drawn, Color(0.08, 0.04, 0.02, 0.22), 2, 3, 4)
	var tint := Color(0.75, 0.78, 0.74) if disabled else Color.WHITE
	if fill.get_luminance() < 0.25 and fill.b > fill.r * 1.4:
		tint = Color(0.82, 0.87, 1.0)
	tint = tint.lightened(float(value.hover) * 0.12).darkened(float(value.press) * 0.12)
	nine_slice(game, "wood_plaque", drawn, tint)
	if float(value.hover) > 0.01:
		game.draw_line(drawn.position + Vector2(22, drawn.size.y - 10), drawn.end - Vector2(22, 10), Color(1.0, 0.88, 0.48, float(value.hover) * 0.6), 1.3, true)
	ThemeLib.draw_label(game, game.ui_font, drawn.grow_individual(-16, -7, -16, -7), text, font_size, Color("fff6d7") if not disabled else Color("c8c6b2"), HORIZONTAL_ALIGNMENT_CENTER)


func background(game: Control, dark: bool = false) -> void:
	var tex := texture("courtyard")
	var pointer: Vector2 = game._pointer_local_position()
	var drift := Vector2(clampf((pointer.x - 800) / 800, -1, 1) * 3 + sin(game.ui_time * 0.18) * 3, cos(game.ui_time * 0.21) * 2)
	if tex != null:
		game.draw_texture_rect(tex, Rect2(drift - Vector2(12, 10), Vector2(1624, 920)), false)
	if dark:
		game.draw_rect(Rect2(0, 0, 1600, 900), Color(0.015, 0.035, 0.033, 0.88), true)
	else:
		ThemeLib.draw_gradient_rect_v(game, Rect2(0, 0, 1600, 900), Color(0.98, 0.94, 0.77, 0.10), Color(0.2, 0.35, 0.20, 0.26))
	ambient(game, Rect2(0, 0, 1600, 900), "night" if dark else "day", 14)


func lantern(game: Control, position: Vector2, height: float = 180.0) -> void:
	var tex := texture("lantern")
	if tex == null:
		return
	var old: Transform2D = game.menu_draw_transform
	var angle := sin(game.ui_time * 1.2) * 0.032
	var local := Transform2D(angle, position)
	var combined := old * local
	game.draw_set_transform_matrix(combined)
	game.draw_texture_rect_region(tex, Rect2(-height * 0.133, -8, height * 0.266, height), REGIONS.lantern)
	game.draw_set_transform_matrix(old)


func ambient(game: Control, rect: Rect2, world: String, count: int = 9) -> void:
	var t: float = game.ui_time
	for i in range(count):
		var seed := i * 37.13
		var pos := rect.position + Vector2(fposmod(seed * 19.1 + t * (7 + i % 3), rect.size.x), fposmod(seed * 11.7 - t * (5 + i % 4), rect.size.y))
		pos.x = clampf(pos.x + sin(t * 0.9 + seed) * 9, rect.position.x + 5, rect.end.x - 5)
		var alpha := 0.10 + 0.13 * (0.5 + sin(t * 1.8 + seed) * 0.5)
		if world in ["pool", "fog"]:
			game.draw_arc(pos, 5 + sin(t + seed) * 2, 0.1, PI * 1.7, 16, Color(0.65, 0.92, 1.0, alpha), 1, true)
		elif world == "city":
			game.draw_line(pos, pos + Vector2(-2, 9), Color(0.61, 0.88, 1.0, alpha), 1.2, true)
		elif world in ["night", "volcano"]:
			game.draw_circle(pos, 2.0 + (i % 2), Color(1.0, 0.62 if world == "volcano" else 0.94, 0.23, alpha * 1.6), true, -1, true)
		else:
			leaf(game, pos, 3.0 + i % 3, t * 0.5 + seed, Color(0.95, 0.84, 0.46, alpha * 1.6))


static func leaf(game: Control, center: Vector2, radius: float, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	for v in [Vector2(-radius, 0), Vector2(0, -radius * 0.5), Vector2(radius, 0), Vector2(0, radius * 0.5)]:
		points.append(center + v.rotated(angle))
	game.draw_colored_polygon(points, color)
	game.draw_line(center + Vector2(-radius * 0.6, 0).rotated(angle), center + Vector2(radius * 0.6, 0).rotated(angle), Color(1, 1, 0.75, color.a * 0.7), 1, true)


func finish(game: Control, draw_mode: String) -> void:
	if not is_menu(draw_mode):
		return
	if draw_mode != "selection":
		lantern(game, Vector2(1548, -20), 200)
	for particle in particles:
		var age := float(particle.age)
		var ratio := age / 0.65
		var origin: Vector2 = particle.position
		var pos := origin + Vector2.from_angle(float(particle.angle)) * (16 + 85 * age) + Vector2(0, age * age * 44)
		leaf(game, pos, (1 - ratio) * 5 + 1, float(particle.angle) + age * 3, Color(1, 0.86, 0.36, (1 - ratio) * 0.85))


func world_art(game: Control, rect: Rect2, index: int, tint: Color = Color.WHITE) -> void:
	var atlas: Texture2D = game._world_ui_texture("scene_atlas")
	if atlas == null:
		return
	var progress := ThemeLib.ease_ui(clampf(preview_age / 0.32, 0, 1)) if preview_index == index else 1.0
	if previous_preview >= 0 and previous_preview != index and progress < 1:
		game.draw_texture_rect_region(atlas, rect, game.GardenMenus.scene_region(atlas.get_size(), previous_preview, rect.size.x / rect.size.y), tint)
	var new_tint := tint
	new_tint.a *= progress
	game.draw_texture_rect_region(atlas, rect, game.GardenMenus.scene_region(atlas.get_size(), index, rect.size.x / rect.size.y), new_tint)
	ambient(game, rect.grow(-8), String(game.WorldDataLib.all()[index].key), 12)
