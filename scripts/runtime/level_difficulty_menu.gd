extends RefCounted
class_name LevelDifficultyMenu

var game: Node
var level_index := -1

const PANEL := Rect2(430.0, 188.0, 740.0, 510.0)
const NORMAL_BUTTON := Rect2(478.0, 390.0, 300.0, 176.0)
const HARD_BUTTON := Rect2(822.0, 390.0, 300.0, 176.0)
const BACK_BUTTON := Rect2(682.0, 606.0, 236.0, 48.0)

func _init(owner: Node) -> void:
	game = owner

func open(index: int) -> void:
	level_index = index
	game.queue_redraw()

func close() -> void:
	level_index = -1
	game.queue_redraw()

func click(mouse_pos: Vector2) -> void:
	if level_index < 0:
		return
	if BACK_BUTTON.has_point(mouse_pos):
		close()
		return
	if NORMAL_BUTTON.has_point(mouse_pos):
		game._start_regular_difficulty(level_index, false)
		return
	if HARD_BUTTON.has_point(mouse_pos) and game._regular_level_cleared(level_index):
		game._start_regular_difficulty(level_index, true)

func input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel")):
		close()
		return
	# game.gd routes all input to the modal while it is open, so mouse releases
	# must be handled here instead of waiting for the normal scene click path.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(game._event_local_position(event))
		return
	if event is InputEventScreenTouch and not event.pressed:
		click(game._event_local_position(event))

func draw() -> void:
	if level_index < 0 or level_index >= game.Defs.LEVELS.size():
		return
	var level: Dictionary = game.Defs.LEVELS[level_index]
	var can_hard: bool = game._regular_level_cleared(level_index)
	game.storybook_ui.panel(game, PANEL, Color("253b32"), Color("bea66d"), 0.22)
	game._draw_text("关卡难度", PANEL.position + Vector2(36.0, 58.0), 34, Color(0.94, 0.99, 0.96))
	game._draw_text(String(level.get("title", level.get("id", "关卡"))), PANEL.position + Vector2(36.0, 92.0), 20, Color(0.58, 0.82, 0.8))
	game._draw_text("首次挑战从普通开始；通关普通后解锁困难。", PANEL.position + Vector2(36.0, 132.0), 17, Color(0.72, 0.82, 0.82))
	_draw_option(NORMAL_BUTTON, "普通", "原版关卡节奏", Color(0.32, 0.72, 0.48), true)
	_draw_option(HARD_BUTTON, "困难", "至少 2 倍僵尸与波数", Color(0.9, 0.4, 0.28), can_hard)
	game._draw_fancy_button(BACK_BUTTON, "返回地图", Color(0.16, 0.24, 0.26), Color(0.48, 0.66, 0.68), 18)

func _draw_option(rect: Rect2, title: String, subtitle: String, accent: Color, enabled: bool) -> void:
	var fill := Color(0.11, 0.17, 0.18, 0.98) if enabled else Color(0.06, 0.09, 0.1, 0.92)
	var edge := Color(accent.r, accent.g, accent.b, 0.9 if enabled else 0.22)
	game.storybook_ui.panel(game, rect, fill, edge, 0.12)
	game._draw_text(title, rect.position + Vector2(28.0, 58.0), 30, Color(0.96, 0.98, 0.94) if enabled else Color(0.46, 0.52, 0.52))
	game._draw_text(subtitle, rect.position + Vector2(28.0, 94.0), 16, Color(0.7, 0.86, 0.78) if enabled else Color(0.4, 0.46, 0.46))
	game._draw_text("点击进入" if enabled else "普通通关后解锁", rect.position + Vector2(28.0, 142.0), 15, accent if enabled else Color(0.5, 0.54, 0.54))
