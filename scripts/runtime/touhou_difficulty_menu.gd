extends RefCounted

const Difficulty = preload("res://scripts/data/touhou_difficulty_defs.gd")
const Spells = preload("res://scripts/data/touhou_spell_defs.gd")
var game: Control
var level_index := -1
var choice := "easy"
var pressed := Rect2()


func _init(owner: Control) -> void:
	game = owner


func open(index: int) -> void:
	level_index = index
	var level: Dictionary = game.Defs.LEVELS[index]
	var options := Difficulty.options(level)
	choice = String(game.touhou_difficulty_choices.get(String(level.id), options[0]))
	if not options.has(choice):
		choice = options[0]
	pressed = Rect2()
	game._queue_level_boss_asset_prewarm(level)
	game.queue_redraw()


func close() -> void:
	level_index = -1
	pressed = Rect2()
	game.queue_redraw()


func panel_rect() -> Rect2:
	var safe: Rect2 = game._viewport_safe_rect().grow(-12)
	var extent := Vector2(minf(940, safe.size.x), minf(480, safe.size.y))
	return Rect2(safe.get_center() - extent * 0.5, extent)


func choice_rect(index: int) -> Rect2:
	var panel := panel_rect()
	var columns := 2
	var portrait_space := 196.0 if panel.size.x >= 880 else 0.0
	var width := (panel.size.x - 48 - portrait_space - 12) / columns
	var top := 56.0 if panel.size.y < 350 else 76.0
	var height := minf(92, (panel.size.y - top - 112) * 0.5 - 5)
	return Rect2(panel.position + Vector2(24 + (index % columns) * (width + 12), top + (index / columns) * (height + 10)), Vector2(width, height))


func start_rect() -> Rect2:
	var panel := panel_rect()
	return Rect2(Vector2(panel.end.x - 196, panel.end.y - 56), Vector2(172, 40))


func close_rect() -> Rect2:
	var panel := panel_rect()
	return Rect2(Vector2(panel.end.x - 58, panel.position.y + 14), Vector2(36, 36))


func click(point: Vector2) -> void:
	if close_rect().has_point(point):
		close()
		return
	var options := Difficulty.options(game.Defs.LEVELS[level_index])
	for index in range(options.size()):
		if choice_rect(index).has_point(point):
			choice = options[index]
			game.queue_redraw()
			return
	if start_rect().has_point(point):
		var index := level_index
		close()
		game._start_touhou_difficulty(index, choice)


func input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			click(start_rect().get_center())
		elif event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			var options := Difficulty.options(game.Defs.LEVELS[level_index])
			var step := -1 if event.keycode in [KEY_LEFT, KEY_UP] else 1
			choice = options[posmod(options.find(choice) + step, options.size())]
			game.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not game._is_touch_generated_mouse_suppressed():
			click(event.position)
	elif event is InputEventScreenTouch:
		game._suppress_touch_generated_mouse()
		if event.pressed:
			pressed = Rect2()
			var rects := [start_rect(), close_rect()]
			for index in range(Difficulty.options(game.Defs.LEVELS[level_index]).size()):
				rects.append(choice_rect(index))
			for rect in rects:
				if rect.has_point(event.position):
					pressed = rect
		elif pressed.has_point(event.position):
			pressed = Rect2()
			click(event.position)


func _label(rect: Rect2, text: String, font_size: int, color: Color) -> void:
	while font_size > 11 and game.ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x:
		font_size -= 1
	game.ThemeLib.draw_label(game, game.ui_font, rect, text, font_size, color)


func draw() -> void:
	var panel := panel_rect()
	var level: Dictionary = game.Defs.LEVELS[level_index]
	var settings: Dictionary = Difficulty.PROFILES[choice]
	game.draw_rect(Rect2(Vector2.ZERO, game.size), Color(0.01, 0.015, 0.02, 0.78))
	game._draw_panel_shell(panel, Color("18221f"), Color("8ba596"), 0.04, 0.02)
	_label(Rect2(panel.position + Vector2(24, 16), Vector2(panel.size.x - 98, 32)), "%s · 难度选择" % level.id, 26, Color("f2f3e9"))
	if panel.size.y >= 350:
		_label(Rect2(panel.position + Vector2(24, 48), Vector2(panel.size.x - 98, 22)), String(level.title), 16, Color("a6b7ac"))
	var cross := close_rect().get_center()
	game.draw_line(cross - Vector2(6, 6), cross + Vector2(6, 6), Color("e0e8df"), 2, true)
	game.draw_line(cross + Vector2(-6, 6), cross + Vector2(6, -6), Color("e0e8df"), 2, true)
	var options := Difficulty.options(level)
	for index in range(options.size()):
		var id: String = options[index]
		var data: Dictionary = Difficulty.PROFILES[id]
		var rect := choice_rect(index)
		var selected := choice == id
		var tint := Color(data.color)
		game.draw_rect(rect, Color("2e4037") if selected else Color("202c26"))
		game.draw_rect(rect, tint if selected else Color("44594c"), false, 2 if selected else 1)
		game.draw_circle(rect.position + Vector2(19, 25), 6, tint if selected else Color("44594c"))
		_label(Rect2(rect.position + Vector2(34, 10), Vector2(rect.size.x - 102, 28)), String(data.name), 23, tint)
		var cleared: bool = game._touhou_difficulty_cleared(level_index, id)
		if cleared:
			_label(Rect2(Vector2(rect.end.x - 62, rect.position.y + 13), Vector2(52, 24)), "已通关", 13, tint)
		_label(Rect2(rect.position + Vector2(14, rect.size.y - 28), Vector2(rect.size.x - 28, 22)), "自选植物" if data.select else "传送带", 15, Color("d8e2da"))
	var chosen := Difficulty.build_level(level, choice)
	var phases := 0
	var attacks := 0
	var boss_kind := ""
	for event in level.events:
		if Difficulty.EXTENSIONS.has(String(event.kind)) and String(event.kind) != String(level.get("mid_boss_kind", "")):
			boss_kind = String(event.kind)
	for kind in [boss_kind, String(level.get("boss_successor_kind", ""))]:
		for phase in Spells.phases_for(kind, chosen):
			phases += 1
			attacks += phase.size()
		if kind == "yuyuko_boss":
			phases += 1
			attacks += 1
	var info_y := panel.end.y - 104
	_label(Rect2(Vector2(panel.position.x + 24, info_y), Vector2(panel.size.x - 48, 24)), "终末 %d 阶段 · %d 招式    Boss 生命 x%.1f    追加 %d 波" % [phases, attacks, float(settings.health), int(settings.waves)], 16, Color("dce5dc"))
	_label(Rect2(Vector2(panel.position.x + 24, info_y + 25), Vector2(panel.size.x - 48, 20)), "弹幕密度 x%.2f    弹幕伤害 x%.2f" % [float(settings.density), float(settings.damage)], 14, Color("a9bfb0"))
	var start := start_rect()
	game.draw_rect(start, Color(settings.color))
	_label(start.grow(-10), "选择植物" if settings.select else "开始战斗", 18, Color("17231d"))
	if panel.size.x >= 880 and boss_kind != "":
		var center := Vector2(panel.end.x - 110, panel.position.y + 224)
		game.draw_arc(center, 78, 0, TAU, 48, Color(Color(settings.color), 0.35), 1.5, true)
		game._draw_zombie_icon(boss_kind, center, 1.5)
