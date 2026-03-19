extends Control

const Defs = preload("res://scripts/game_defs.gd")

const ROWS := 5
const COLS := 9

const MODE_MAP := "map"
const MODE_SELECTION := "selection"
const MODE_BATTLE := "battle"

const BATTLE_PLAYING := "playing"
const BATTLE_WON := "won"
const BATTLE_LOST := "lost"

const BOARD_ORIGIN := Vector2(250.0, 160.0)
const CELL_SIZE := Vector2(98.0, 110.0)
const BOARD_SIZE := Vector2(COLS * CELL_SIZE.x, ROWS * CELL_SIZE.y)

const SEED_BANK_RECT := Rect2(26.0, 18.0, 920.0, 102.0)
const SUN_METER_RECT := Rect2(34.0, 24.0, 92.0, 88.0)
const CARD_SIZE := Vector2(82.0, 92.0)
const CARD_GAP := 6.0
const WAVE_BAR_RECT := Rect2(948.0, 26.0, 340.0, 24.0)
const PLANT_FOOD_RECT := Rect2(948.0, 58.0, 90.0, 46.0)
const COIN_METER_RECT := Rect2(1046.0, 64.0, 136.0, 40.0)
const BACK_BUTTON_RECT := Rect2(1190.0, 64.0, 100.0, 40.0)

const MOWER_SPEED := 760.0
const SUN_COLLECT_SPEED := 920.0
const COIN_COLLECT_SPEED := 980.0
const PLANT_FOOD_COLLECT_SPEED := 980.0
const SUN_VALUE := 50
const MAX_PLANT_FOOD := 3
const SAVE_PATH := "user://pvz_progress_save.json"
const MAX_SEED_SLOTS := 10
const PREP_SELECTED_PANEL_RECT := Rect2(122.0, 110.0, 1036.0, 128.0)
const PREP_ZOMBIE_PANEL_RECT := Rect2(122.0, 248.0, 1036.0, 52.0)
const PREP_POOL_PANEL_RECT := Rect2(122.0, 314.0, 1036.0, 308.0)
const PREP_BACK_RECT := Rect2(874.0, 642.0, 122.0, 44.0)
const PREP_START_RECT := Rect2(1010.0, 642.0, 148.0, 44.0)

var rng = RandomNumberGenerator.new()
var ui_font: SystemFont

var mode := MODE_MAP
var battle_state := BATTLE_PLAYING
var panel_action := ""

var map_time := 0.0
var selected_level_index := -1
var hovered_level_index := -1
var unlocked_levels := 1
var completed_levels: Array = []
var coins_total := 0

var current_level = {}
var active_cards: Array = []
var active_rows: Array = []
var conveyor_source_cards: Array = []
var conveyor_spawn_timer := 0.0
var level_end_time := 1.0
var next_event_index := 0
var level_time := 0.0
var sky_sun_cooldown := 0.0
var batch_spawn_remaining := 0
var spawn_director_timer := 0.0
var selected_tool := ""
var sun_points := 0
var plant_food_count := 0
var total_kills := 0
var selection_cards: Array = []
var selection_pool_cards: Array = []

var grid: Array = []
var zombies: Array = []
var projectiles: Array = []
var suns: Array = []
var coins: Array = []
var plant_food_pickups: Array = []
var rollers: Array = []
var weeds: Array = []
var spears: Array = []
var mowers: Array = []
var effects: Array = []
var card_cooldowns := {}
var save_dirty := false
var autosave_timer := 0.0

var toast_timer := 0.0
var banner_timer := 0.0

var toast_label: Label
var banner_label: Label
var message_panel: PanelContainer
var message_label: Label
var action_button: Button


func _ready() -> void:
	rng.randomize()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_font()
	_build_overlay_ui()
	_init_campaign()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if save_dirty:
			_save_game()


func _process(delta: float) -> void:
	_update_overlay_timers(delta)
	_update_autosave(delta)

	if mode == MODE_MAP:
		map_time += delta
		hovered_level_index = _level_node_at(get_local_mouse_position())
		queue_redraw()
		return

	if mode == MODE_SELECTION:
		queue_redraw()
		return

	if battle_state != BATTLE_PLAYING:
		queue_redraw()
		return

	level_time += delta
	for kind in active_cards:
		if kind == "" or not card_cooldowns.has(kind):
			continue
		card_cooldowns[kind] = maxf(0.0, float(card_cooldowns[kind]) - delta)

	sky_sun_cooldown -= delta
	if sky_sun_cooldown <= 0.0:
		var sky_range = current_level["sky_sun_range"]
		_spawn_sun(
			Vector2(
				rng.randf_range(BOARD_ORIGIN.x + 30.0, BOARD_ORIGIN.x + BOARD_SIZE.x - 30.0),
				80.0
			),
			_random_active_target_y(),
			"sky"
		)
		sky_sun_cooldown = rng.randf_range(sky_range.x, sky_range.y)

	_update_spawn_director(delta)
	_update_conveyor(delta)
	_update_plants(delta)
	_update_projectiles(delta)
	_update_rollers(delta)
	_update_zombies(delta)
	_update_mowers(delta)
	_update_suns(delta)
	_update_coins(delta)
	_update_plant_food_pickups(delta)
	_update_weeds_and_spears()
	_update_effects(delta)
	_remove_dead_plants()
	_cleanup_dead_zombies()
	_check_end_state()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if mode == MODE_BATTLE and battle_state == BATTLE_PLAYING:
			selected_tool = ""
			queue_redraw()
		return

	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var mouse_pos = get_local_mouse_position()

	if mode == MODE_MAP:
		var level_index = _level_node_at(mouse_pos)
		if level_index != -1 and level_index < unlocked_levels:
			_start_level(level_index)
		return

	if mode == MODE_SELECTION:
		_handle_selection_click(mouse_pos)
		return

	if battle_state != BATTLE_PLAYING:
		return

	if BACK_BUTTON_RECT.has_point(mouse_pos):
		_enter_map_mode()
		return

	var card_kind = _card_at(mouse_pos)
	if card_kind != "":
		_try_select_tool(card_kind)
		return

	if _shovel_rect().has_point(mouse_pos):
		selected_tool = "" if selected_tool == "shovel" else "shovel"
		queue_redraw()
		return

	if PLANT_FOOD_RECT.has_point(mouse_pos):
		_toggle_plant_food_tool()
		return

	var cell = _mouse_to_cell(mouse_pos)
	if cell.x != -1:
		_handle_board_click(cell)


func _build_font() -> void:
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray([
		"Arial Unicode MS",
		"STHeiti",
		"PingFang SC",
		"Songti SC",
	])


func _build_overlay_ui() -> void:
	toast_label = Label.new()
	toast_label.visible = false
	toast_label.anchor_left = 0.5
	toast_label.anchor_right = 0.5
	toast_label.anchor_top = 1.0
	toast_label.anchor_bottom = 1.0
	toast_label.offset_left = -240.0
	toast_label.offset_top = -78.0
	toast_label.offset_right = 240.0
	toast_label.offset_bottom = -36.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_override("font", ui_font)
	toast_label.add_theme_font_size_override("font_size", 18)
	add_child(toast_label)

	banner_label = Label.new()
	banner_label.visible = false
	banner_label.anchor_left = 0.5
	banner_label.anchor_right = 0.5
	banner_label.offset_left = -300.0
	banner_label.offset_top = 122.0
	banner_label.offset_right = 300.0
	banner_label.offset_bottom = 166.0
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_override("font", ui_font)
	banner_label.add_theme_font_size_override("font_size", 24)
	add_child(banner_label)

	message_panel = PanelContainer.new()
	message_panel.visible = false
	message_panel.anchor_left = 0.5
	message_panel.anchor_right = 0.5
	message_panel.anchor_top = 0.5
	message_panel.anchor_bottom = 0.5
	message_panel.offset_left = -240.0
	message_panel.offset_top = -126.0
	message_panel.offset_right = 240.0
	message_panel.offset_bottom = 126.0
	add_child(message_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	message_panel.add_child(margin)

	var column = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.custom_minimum_size = Vector2(390.0, 90.0)
	message_label.add_theme_font_override("font", ui_font)
	message_label.add_theme_font_size_override("font_size", 28)
	column.add_child(message_label)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(190.0, 52.0)
	action_button.add_theme_font_override("font", ui_font)
	action_button.add_theme_font_size_override("font_size", 20)
	action_button.pressed.connect(_on_message_button_pressed)
	column.add_child(action_button)


func _init_campaign() -> void:
	completed_levels.resize(Defs.LEVELS.size())
	for i in range(completed_levels.size()):
		completed_levels[i] = false
	unlocked_levels = 1
	coins_total = 0
	if _load_game():
		_show_toast("已读取本地存档")
	_mark_save_dirty(true)
	_enter_map_mode()


func _enter_map_mode() -> void:
	mode = MODE_MAP
	battle_state = BATTLE_PLAYING
	current_level = {}
	active_cards = []
	active_rows = []
	selection_cards = []
	selection_pool_cards = []
	selected_tool = ""
	message_panel.visible = false
	var hover_index = selected_level_index
	if hover_index < 0 or hover_index >= unlocked_levels:
		hover_index = unlocked_levels - 1
	hovered_level_index = clampi(hover_index, 0, Defs.LEVELS.size() - 1)
	queue_redraw()


func _start_level(level_index: int) -> void:
	selected_level_index = level_index
	var level = Defs.LEVELS[level_index]
	if _requires_seed_selection(level):
		_enter_seed_selection(level_index)
		return
	_begin_level(level_index, level["available_plants"])


func _enter_seed_selection(level_index: int) -> void:
	selected_level_index = level_index
	current_level = Defs.LEVELS[level_index]
	mode = MODE_SELECTION
	battle_state = BATTLE_PLAYING
	panel_action = ""
	message_panel.visible = false
	selected_tool = ""
	active_cards = []
	active_rows = _build_active_rows(int(current_level.get("row_count", ROWS)))
	selection_pool_cards = current_level["available_plants"].duplicate()
	selection_cards = []
	for kind in selection_pool_cards:
		if selection_cards.size() >= MAX_SEED_SLOTS:
			break
		selection_cards.append(kind)
	queue_redraw()


func _begin_level(level_index: int, chosen_cards: Array) -> void:
	selected_level_index = level_index
	current_level = Defs.LEVELS[level_index]
	conveyor_source_cards = []
	selection_cards = []
	selection_pool_cards = []
	if current_level.has("conveyor_plants"):
		conveyor_source_cards = current_level["conveyor_plants"].duplicate()
	if _is_conveyor_level():
		active_cards = ["", "", "", "", "", ""]
	else:
		active_cards = chosen_cards.duplicate()
	active_rows = _build_active_rows(int(current_level.get("row_count", ROWS)))
	mode = MODE_BATTLE
	battle_state = BATTLE_PLAYING
	panel_action = ""
	message_panel.visible = false
	selected_tool = ""

	sun_points = int(current_level["start_sun"])
	plant_food_count = 0
	total_kills = 0
	level_time = 0.0
	next_event_index = 0
	batch_spawn_remaining = 0
	spawn_director_timer = 2.0 * _level_time_scale()
	conveyor_spawn_timer = 0.35
	level_end_time = float(current_level["events"].size())
	var sky_range = current_level["sky_sun_range"]
	sky_sun_cooldown = rng.randf_range(sky_range.x, sky_range.y)

	grid.clear()
	for row in range(ROWS):
		var row_data = []
		row_data.resize(COLS)
		for col in range(COLS):
			row_data[col] = null
		grid.append(row_data)

	zombies = []
	projectiles = []
	suns = []
	coins = []
	plant_food_pickups = []
	rollers = []
	weeds = []
	spears = []
	effects = []
	card_cooldowns.clear()
	if not _is_conveyor_level():
		for kind in active_cards:
			card_cooldowns[kind] = 0.0

	mowers = []
	for row in range(ROWS):
		mowers.append({
			"row": row,
			"x": BOARD_ORIGIN.x - 64.0,
			"armed": _is_row_active(row),
			"active": false,
		})

	if _is_conveyor_level():
		for i in range(3):
			_fill_conveyor_slot(i)

	_mark_save_dirty(true)
	_show_banner(String(current_level["title"]), 2.2)
	queue_redraw()


func _handle_selection_click(mouse_pos: Vector2) -> void:
	if PREP_BACK_RECT.has_point(mouse_pos):
		_enter_map_mode()
		return

	if PREP_START_RECT.has_point(mouse_pos):
		if selection_cards.is_empty():
			_show_toast("至少选择 1 张植物")
			return
		_begin_level(selected_level_index, selection_cards)
		return

	var selected_index = _selection_slot_at(mouse_pos)
	if selected_index != -1:
		if selected_index < selection_cards.size():
			selection_cards.remove_at(selected_index)
			queue_redraw()
		return

	var kind = _selection_pool_card_at(mouse_pos)
	if kind == "":
		return
	if selection_cards.has(kind):
		selection_cards.erase(kind)
		queue_redraw()
		return
	if selection_cards.size() >= MAX_SEED_SLOTS:
		_show_toast("最多只能携带 10 张植物")
		return
	selection_cards.append(kind)
	queue_redraw()


func _update_spawn_director(delta: float) -> void:
	var events = current_level["events"]
	if next_event_index >= events.size():
		return

	if batch_spawn_remaining > 0:
		spawn_director_timer -= delta
		if spawn_director_timer > 0.0:
			return

		var event = events[next_event_index]
		_spawn_zombie(String(event["kind"]), int(event.get("row", -1)))
		next_event_index += 1
		batch_spawn_remaining -= 1
		spawn_director_timer = _intra_batch_spawn_delay()
		return

	if _active_zombie_count() > _spawn_gate_limit():
		spawn_director_timer = _batch_pause_duration()
		return

	spawn_director_timer -= delta
	if spawn_director_timer > 0.0:
		return

	_begin_next_batch()


func _begin_next_batch() -> void:
	var events = current_level["events"]
	if next_event_index >= events.size():
		return

	var batch_size = min(_target_batch_size(), events.size() - next_event_index)
	for i in range(batch_size):
		if bool(events[next_event_index + i].get("wave", false)):
			var is_final = next_event_index + i >= events.size() - 4
			_show_banner("最后一波！" if is_final else "一大波僵尸正在逼近！", 2.2)
			break

	batch_spawn_remaining = batch_size
	spawn_director_timer = 0.01


func _spawn_zombie(kind: String, row_override: int = -1) -> void:
	var base = Defs.ZOMBIES[kind]
	var row = row_override if row_override >= 0 else _choose_spawn_row()
	zombies.append({
			"kind": kind,
			"row": row,
			"x": BOARD_ORIGIN.x + BOARD_SIZE.x + 80.0 + rng.randf_range(0.0, 36.0),
		"health": float(base["health"]),
		"max_health": float(base["health"]),
		"base_speed": float(base["speed"]),
		"attack_dps": float(base["attack_dps"]),
		"flash": 0.0,
		"slow_timer": 0.0,
		"has_vaulted": kind != "pole_vault",
		"jumping": false,
			"jump_t": 0.0,
			"jump_from_x": 0.0,
			"jump_to_x": 0.0,
			"jump_offset": 0.0,
			"reflect_timer": 0.0,
			"reflect_cooldown": 5.0 if kind == "kungfu" else 0.0,
			"weed_pause_timer": 0.0,
			"last_cell_col": COLS + 1,
			"boss_skill_timer": 8.0 if kind == "day_boss" else 0.0,
			"boss_pause_timer": 0.0,
			"plant_food_carrier": rng.randf() < 0.05,
		})


func _choose_spawn_row() -> int:
	var counts = []
	for row in range(ROWS):
		if not _is_row_active(row):
			counts.append(9999)
			continue
		var amount = 0
		for zombie in zombies:
			if int(zombie["row"]) == row:
				amount += 1
		counts.append(amount)

	var min_count = counts[0]
	for value in counts:
		min_count = min(min_count, value)

	var candidates = []
	for row in range(ROWS):
		if counts[row] == min_count:
			candidates.append(row)

	return int(candidates[rng.randi_range(0, candidates.size() - 1)])


func _handle_board_click(cell: Vector2i) -> void:
	if selected_tool == "":
		_show_toast("先选择植物卡片")
		return

	if selected_tool == "plant_food":
		if plant_food_count <= 0:
			_show_toast("没有可用的能量豆")
			selected_tool = ""
			queue_redraw()
			return
		if grid[cell.x][cell.y] == null:
			_show_toast("请对植物使用能量豆")
			return
		if not _activate_plant_food(cell.x, cell.y):
			_show_toast("这株植物现在不能使用能量豆")
			return
		plant_food_count -= 1
		selected_tool = ""
		queue_redraw()
		return

	if selected_tool == "shovel":
		if grid[cell.x][cell.y] == null:
			_show_toast("这里没有植物")
			return
		grid[cell.x][cell.y] = null
		selected_tool = ""
		_show_toast("植物已铲除")
		queue_redraw()
		return

	if grid[cell.x][cell.y] != null:
		_show_toast("这个格子已经被占用了")
		return

	var data = Defs.PLANTS[selected_tool]
	if not _is_conveyor_level() and sun_points < int(data["cost"]):
		_show_toast("阳光不够")
		return

	if not _is_conveyor_level() and float(card_cooldowns[selected_tool]) > 0.01:
		_show_toast("卡片还在冷却")
		return

	if not _is_conveyor_level():
		sun_points -= int(data["cost"])
		card_cooldowns[selected_tool] = float(data["cooldown"])

	if selected_tool == "wallnut_bowling":
		_spawn_bowling_roller(cell.x, cell.y)
	else:
		grid[cell.x][cell.y] = _create_plant(selected_tool, cell.x, cell.y)
	if _is_conveyor_level():
		_consume_conveyor_card(selected_tool)
	selected_tool = ""
	queue_redraw()


func _try_select_tool(kind: String) -> void:
	if kind == "":
		return
	if _is_conveyor_level():
		selected_tool = "" if selected_tool == kind else kind
		queue_redraw()
		return
	var data = Defs.PLANTS[kind]
	if sun_points < int(data["cost"]):
		_show_toast("阳光不够")
		return
	if float(card_cooldowns[kind]) > 0.01:
		_show_toast("%s还在冷却" % data["name"])
		return
	selected_tool = "" if selected_tool == kind else kind
	queue_redraw()


func _create_plant(kind: String, row: int, col: int) -> Dictionary:
	var data = Defs.PLANTS[kind]
	var plant = {
		"kind": kind,
		"row": row,
		"col": col,
		"health": float(data["health"]),
		"max_health": float(data["health"]),
		"armor_health": 0.0,
		"max_armor_health": 0.0,
		"flash": 0.0,
		"shot_cooldown": 0.0,
		"burst_remaining": 0,
		"burst_gap_timer": 0.0,
		"sun_timer": 0.0,
		"fuse_timer": 0.0,
		"arm_timer": 0.0,
		"armed": false,
		"chew_timer": 0.0,
		"attack_timer": 0.0,
		"pulse_timer": 0.0,
		"gust_timer": 0.0,
		"plant_food_mode": "",
		"plant_food_timer": 0.0,
		"plant_food_interval": 0.0,
		"plant_food_charges": 0,
	}

	match kind:
		"sunflower":
			plant["sun_timer"] = float(data["first_sun_delay"])
		"peashooter", "snow_pea":
			plant["shot_cooldown"] = 0.5
		"repeater":
			plant["shot_cooldown"] = 0.45
		"cherry_bomb":
			plant["fuse_timer"] = float(data["fuse"])
		"potato_mine":
			plant["arm_timer"] = float(data["arm_time"])
		"vine_lasher", "pepper_mortar":
			plant["attack_timer"] = 0.45
		"pulse_bulb":
			plant["pulse_timer"] = 1.0
		"sun_bean":
			plant["sun_timer"] = float(data["first_sun_delay"])
			plant["shot_cooldown"] = 0.6
		"wind_orchid":
			plant["gust_timer"] = 2.0

	return plant


func _update_plants(delta: float) -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue

			var plant = plant_variant
			plant["flash"] = maxf(0.0, float(plant["flash"]) - delta)
			if float(plant["plant_food_timer"]) > 0.0:
				plant["plant_food_timer"] = maxf(0.0, float(plant["plant_food_timer"]) - delta)
			if float(plant["armor_health"]) <= 0.0 and String(plant["plant_food_mode"]) == "fortify":
				plant["armor_health"] = 0.0
				plant["max_armor_health"] = 0.0
				plant["plant_food_mode"] = ""
				plant["plant_food_timer"] = 0.0
			elif float(plant["plant_food_timer"]) <= 0.0 and String(plant["plant_food_mode"]) != "" and int(plant["plant_food_charges"]) <= 0 and String(plant["plant_food_mode"]) != "fortify":
				plant["plant_food_mode"] = ""
				plant["plant_food_interval"] = 0.0

			match String(plant["kind"]):
				"sunflower":
					plant["sun_timer"] -= delta
					if float(plant["sun_timer"]) <= 0.0:
						var center = _cell_center(row, col)
						_spawn_sun(center + Vector2(rng.randf_range(-8.0, 8.0), -18.0), center.y - 10.0, "plant")
						plant["sun_timer"] = float(Defs.PLANTS["sunflower"]["sun_interval"])
				"peashooter":
					if _update_shooter_plant_food(plant, delta, row, col, Color(0.36, 0.86, 0.3), 0.0, 1, 0.1):
						grid[row][col] = plant
						continue
					_update_basic_shooter(plant, delta, row, col, Color(0.36, 0.86, 0.3), 0.0)
				"amber_shooter":
					if _update_shooter_plant_food(plant, delta, row, col, Color(0.84, 0.58, 0.16), 0.0, 1, 0.08):
						grid[row][col] = plant
						continue
					_update_basic_shooter(plant, delta, row, col, Color(0.84, 0.58, 0.16), 0.0)
				"snow_pea":
					if _update_shooter_plant_food(plant, delta, row, col, Color(0.54, 0.88, 1.0), 16.0, 1, 0.1):
						grid[row][col] = plant
						continue
					_update_basic_shooter(plant, delta, row, col, Color(0.54, 0.88, 1.0), float(Defs.PLANTS["snow_pea"]["slow_duration"]))
				"repeater":
					_update_repeater(plant, delta, row, col)
				"cherry_bomb":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						_explode_cherry(row, col, String(plant["plant_food_mode"]) == "mega_bomb")
						grid[row][col] = null
						continue
				"potato_mine":
					if not bool(plant["armed"]):
						plant["arm_timer"] -= delta
						if float(plant["arm_timer"]) <= 0.0:
							plant["armed"] = true
					elif _mine_has_target(row, col):
						_explode_mine(row, col)
						grid[row][col] = null
						continue
				"chomper":
					plant["chew_timer"] = maxf(0.0, float(plant["chew_timer"]) - delta)
					if float(plant["chew_timer"]) <= 0.0:
						var zombie_index = _find_chomper_target(row, _cell_center(row, col).x)
						if zombie_index != -1:
							var zombie = zombies[zombie_index]
							zombie["health"] = 0.0
							zombie["flash"] = 0.25
							zombies[zombie_index] = zombie
							plant["chew_timer"] = float(Defs.PLANTS["chomper"]["chew_time"])
				"vine_lasher":
					_update_vine_lasher(plant, delta, row, col)
				"pepper_mortar":
					_update_pepper_mortar(plant, delta, row, col)
				"pulse_bulb":
					_update_pulse_bulb(plant, delta, row, col)
				"sun_bean":
					_update_sun_bean(plant, delta, row, col)
				"wind_orchid":
					_update_wind_orchid(plant, delta, row, col)

			grid[row][col] = plant


func _update_basic_shooter(plant: Dictionary, delta: float, row: int, col: int, projectile_color: Color, slow_duration: float) -> void:
	plant["shot_cooldown"] -= delta
	if float(plant["shot_cooldown"]) > 0.0:
		return

	var center_x = _cell_center(row, col).x
	if not _has_zombie_ahead(row, center_x):
		return

	var damage = float(Defs.PLANTS[String(plant["kind"])]["damage"])
	_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -10.0), projectile_color, damage, slow_duration)
	plant["shot_cooldown"] = float(Defs.PLANTS[String(plant["kind"])]["shoot_interval"])


func _update_shooter_plant_food(plant: Dictionary, delta: float, row: int, col: int, projectile_color: Color, slow_duration: float, volley_count: int, volley_interval: float) -> bool:
	var pf_mode = String(plant["plant_food_mode"])
	if pf_mode != "pea_storm" and pf_mode != "ice_storm":
		return false
	if float(plant["plant_food_timer"]) <= 0.0:
		return false

	plant["plant_food_interval"] -= delta
	var damage = float(Defs.PLANTS[String(plant["kind"])]["damage"])
	while float(plant["plant_food_interval"]) <= 0.0:
		for shot_index in range(volley_count):
			var y_offset = 0.0
			if volley_count > 1:
				y_offset = lerpf(-7.0, 7.0, float(shot_index) / float(max(volley_count - 1, 1)))
			_spawn_projectile(
				row,
				_cell_center(row, col) + Vector2(32.0, -10.0 + y_offset),
				projectile_color,
				damage,
				slow_duration
			)
		plant["plant_food_interval"] += volley_interval
		plant["flash"] = maxf(float(plant["flash"]), 0.16)
	return true


func _update_repeater(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if String(plant["plant_food_mode"]) == "double_storm":
		if float(plant["plant_food_timer"]) > 0.0:
			plant["plant_food_interval"] -= delta
			while float(plant["plant_food_interval"]) <= 0.0:
				_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -16.0), Color(0.3, 0.84, 0.26), 20.0, 0.0)
				_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -4.0), Color(0.3, 0.84, 0.26), 20.0, 0.0)
				plant["plant_food_interval"] += 0.08
				plant["flash"] = maxf(float(plant["flash"]), 0.18)
			return
		if int(plant["plant_food_charges"]) > 0:
			_spawn_projectile(row, _cell_center(row, col) + Vector2(38.0, -12.0), Color(0.32, 0.96, 0.38), 400.0, 0.0, 520.0, 14.0)
			plant["plant_food_charges"] = 0
			plant["plant_food_mode"] = ""
			plant["plant_food_interval"] = 0.0
			plant["flash"] = maxf(float(plant["flash"]), 0.2)
			return

	plant["shot_cooldown"] -= delta
	if int(plant["burst_remaining"]) > 0:
		plant["burst_gap_timer"] -= delta
		if float(plant["burst_gap_timer"]) <= 0.0:
			var burst_damage = float(Defs.PLANTS["repeater"]["damage"])
			_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -10.0), Color(0.3, 0.84, 0.26), burst_damage, 0.0)
			plant["burst_remaining"] = int(plant["burst_remaining"]) - 1
			if int(plant["burst_remaining"]) > 0:
				plant["burst_gap_timer"] = float(Defs.PLANTS["repeater"]["burst_gap"])

	if float(plant["shot_cooldown"]) > 0.0:
		return

	var center_x = _cell_center(row, col).x
	if not _has_zombie_ahead(row, center_x):
		return

	var damage = float(Defs.PLANTS["repeater"]["damage"])
	_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -10.0), Color(0.3, 0.84, 0.26), damage, 0.0)
	plant["burst_remaining"] = int(Defs.PLANTS["repeater"]["burst_count"]) - 1
	plant["burst_gap_timer"] = float(Defs.PLANTS["repeater"]["burst_gap"])
	plant["shot_cooldown"] = float(Defs.PLANTS["repeater"]["shoot_interval"])


func _update_vine_lasher(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["attack_timer"] -= delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = _cell_center(row, col).x
	var target_index = _find_lane_target(row, center_x, float(Defs.PLANTS["vine_lasher"]["range"]))
	if target_index == -1:
		plant["attack_timer"] = 0.2
		return
	var zombie = zombies[target_index]
	zombie["health"] -= float(Defs.PLANTS["vine_lasher"]["damage"])
	zombie["slow_timer"] = maxf(float(zombie["slow_timer"]), float(Defs.PLANTS["vine_lasher"]["slow_duration"]))
	zombie["flash"] = 0.16
	zombies[target_index] = zombie
	plant["flash"] = maxf(float(plant["flash"]), 0.12)
	plant["attack_timer"] = float(Defs.PLANTS["vine_lasher"]["attack_interval"])


func _update_pepper_mortar(plant: Dictionary, delta: float, row: int, _col: int) -> void:
	plant["attack_timer"] -= delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target_index = _find_frontmost_zombie(row)
	if target_index == -1:
		plant["attack_timer"] = 0.25
		return
	var zombie = zombies[target_index]
	var impact = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
	_damage_zombies_in_radius(row, impact.x, float(Defs.PLANTS["pepper_mortar"]["splash_radius"]), float(Defs.PLANTS["pepper_mortar"]["damage"]))
	effects.append({
		"position": impact,
		"radius": float(Defs.PLANTS["pepper_mortar"]["splash_radius"]),
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.42, 0.12, 0.56),
	})
	plant["flash"] = maxf(float(plant["flash"]), 0.16)
	plant["attack_timer"] = float(Defs.PLANTS["pepper_mortar"]["attack_interval"])


func _update_pulse_bulb(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["pulse_timer"] -= delta
	if float(plant["pulse_timer"]) > 0.0:
		return
	var did_hit = false
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row:
			continue
		zombie["health"] -= float(Defs.PLANTS["pulse_bulb"]["damage"])
		zombie["flash"] = 0.12
		zombies[i] = zombie
		did_hit = true
	if did_hit:
		var center = _cell_center(row, col)
		effects.append({
			"position": center,
			"radius": 220.0,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.98, 0.94, 0.36, 0.34),
		})
	plant["flash"] = maxf(float(plant["flash"]), 0.14)
	plant["pulse_timer"] = float(Defs.PLANTS["pulse_bulb"]["pulse_interval"])


func _update_sun_bean(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) <= 0.0:
		var center = _cell_center(row, col)
		_spawn_sun(center + Vector2(rng.randf_range(-8.0, 8.0), -18.0), center.y - 10.0, "plant")
		plant["sun_timer"] = float(Defs.PLANTS["sun_bean"]["sun_interval"])
	_update_basic_shooter(plant, delta, row, col, Color(0.94, 0.78, 0.22), 0.0)


func _update_wind_orchid(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["gust_timer"] -= delta
	if float(plant["gust_timer"]) > 0.0:
		return
	var did_push = false
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row:
			continue
		zombie["x"] += float(Defs.PLANTS["wind_orchid"]["push_distance"])
		zombie["flash"] = 0.1
		zombies[i] = zombie
		did_push = true
	for i in range(weeds.size() - 1, -1, -1):
		if int(weeds[i]["row"]) == row:
			weeds.remove_at(i)
			did_push = true
	for i in range(spears.size() - 1, -1, -1):
		if int(spears[i]["row"]) == row:
			spears.remove_at(i)
			did_push = true
	if did_push:
		effects.append({
			"position": _cell_center(row, col),
			"radius": 210.0,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.72, 0.94, 1.0, 0.36),
		})
	plant["flash"] = maxf(float(plant["flash"]), 0.14)
	plant["gust_timer"] = float(Defs.PLANTS["wind_orchid"]["gust_interval"])


func _spawn_projectile(row: int, spawn_position: Vector2, projectile_color: Color, damage: float, slow_duration: float, speed: float = 460.0, radius: float = 8.0) -> void:
	projectiles.append({
		"row": row,
		"position": spawn_position,
		"speed": speed,
		"damage": damage,
		"slow_duration": slow_duration,
		"color": projectile_color,
		"radius": radius,
		"reflected": false,
	})


func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile = projectiles[i]
		var projectile_pos = projectile["position"]
		projectile_pos.x += float(projectile["speed"]) * delta
		projectile["position"] = projectile_pos

		if bool(projectile.get("reflected", false)):
			var plant_target = _find_projectile_plant_target(projectile)
			if plant_target.y != -1:
				var plant = grid[plant_target.x][plant_target.y]
				plant["health"] -= float(projectile["damage"])
				plant["flash"] = 0.16
				grid[plant_target.x][plant_target.y] = plant
				projectiles.remove_at(i)
				continue
			if projectile_pos.x < BOARD_ORIGIN.x - 120.0:
				projectiles.remove_at(i)
				continue
			projectiles[i] = projectile
			continue

		if _damage_projectile_obstacle(projectile):
			projectiles.remove_at(i)
			continue

		var hit_index = _find_projectile_target(projectile)
		if hit_index != -1:
			var zombie = zombies[hit_index]
			if String(zombie["kind"]) == "kungfu" and float(zombie.get("reflect_timer", 0.0)) > 0.0:
				projectile["reflected"] = true
				projectile["speed"] = -absf(float(projectile["speed"]))
				projectile["color"] = Color(1.0, 0.42, 0.42)
				projectile["slow_duration"] = 0.0
				projectile["position"] = Vector2(float(zombie["x"]) - 18.0, projectile_pos.y)
				projectiles[i] = projectile
				continue

			zombie["health"] -= float(projectile["damage"])
			zombie["flash"] = 0.12
			if float(projectile["slow_duration"]) > 0.0:
				zombie["slow_timer"] = maxf(float(zombie["slow_timer"]), float(projectile["slow_duration"]))
			zombies[hit_index] = zombie
			projectiles.remove_at(i)
			continue

		if projectile_pos.x > BOARD_ORIGIN.x + BOARD_SIZE.x + 120.0:
			projectiles.remove_at(i)
			continue

		projectiles[i] = projectile


func _spawn_bowling_roller(row: int, col: int) -> void:
	var center = _cell_center(row, col)
	rollers.append({
		"row": row,
		"x": center.x,
		"speed": float(Defs.PLANTS["wallnut_bowling"]["roll_speed"]),
		"damage": float(Defs.PLANTS["wallnut_bowling"]["damage"]),
		"hits_left": 4,
			"bounce_dir": 1 if float(row) < float(ROWS) * 0.5 else -1,
		"last_hit_frame": -1,
	})


func _update_rollers(delta: float) -> void:
	for i in range(rollers.size() - 1, -1, -1):
		var roller = rollers[i]
		roller["x"] += float(roller["speed"]) * delta
		var removed = false
		for z in range(zombies.size()):
			var zombie = zombies[z]
			if int(zombie["row"]) != int(roller["row"]):
				continue
			if absf(float(zombie["x"]) - float(roller["x"])) > 26.0:
				continue
			zombie["health"] -= float(roller["damage"])
			zombie["flash"] = 0.2
			zombies[z] = zombie
			roller["hits_left"] = int(roller["hits_left"]) - 1
			var next_row = int(roller["row"]) + int(roller["bounce_dir"])
			if next_row < 0 or next_row >= ROWS:
				roller["bounce_dir"] = -int(roller["bounce_dir"])
				next_row = clampi(int(roller["row"]) + int(roller["bounce_dir"]), 0, ROWS - 1)
			if _is_row_active(next_row):
				roller["row"] = next_row
			if int(roller["hits_left"]) <= 0:
				rollers.remove_at(i)
				removed = true
			break
		if removed:
			continue
		if float(roller["x"]) > BOARD_ORIGIN.x + BOARD_SIZE.x + 120.0:
			rollers.remove_at(i)
			continue
		rollers[i] = roller


func _update_zombies(delta: float) -> void:
	for i in range(zombies.size()):
		var zombie = zombies[i]
		zombie["flash"] = maxf(0.0, float(zombie["flash"]) - delta)
		zombie["slow_timer"] = maxf(0.0, float(zombie["slow_timer"]) - delta)
		zombie["jump_offset"] = 0.0
		if float(zombie.get("reflect_timer", 0.0)) > 0.0:
			zombie["reflect_timer"] = maxf(0.0, float(zombie["reflect_timer"]) - delta)
		elif String(zombie["kind"]) == "kungfu":
			zombie["reflect_cooldown"] = maxf(0.0, float(zombie["reflect_cooldown"]) - delta)
			if float(zombie["reflect_cooldown"]) <= 0.0:
				zombie["reflect_timer"] = 3.0
				zombie["reflect_cooldown"] = 5.0

		if String(zombie["kind"]) == "day_boss":
			zombie["boss_skill_timer"] = maxf(0.0, float(zombie["boss_skill_timer"]) - delta)
			zombie["boss_pause_timer"] = maxf(0.0, float(zombie["boss_pause_timer"]) - delta)
			if float(zombie["boss_skill_timer"]) <= 0.0:
				_trigger_boss_skill(zombie)
				zombie["boss_skill_timer"] = 8.0
				zombie["boss_pause_timer"] = 1.2

		if bool(zombie["jumping"]):
			zombie["jump_t"] += delta / 0.34
			var jump_ratio = clampf(float(zombie["jump_t"]), 0.0, 1.0)
			zombie["x"] = lerpf(float(zombie["jump_from_x"]), float(zombie["jump_to_x"]), jump_ratio)
			zombie["jump_offset"] = -sin(jump_ratio * PI) * 54.0
			if jump_ratio >= 1.0:
				zombie["jumping"] = false
				zombie["has_vaulted"] = true
				zombie["base_speed"] = float(Defs.ZOMBIES["pole_vault"]["post_jump_speed"])
				zombie["jump_offset"] = 0.0
			zombies[i] = zombie
			continue

		if String(zombie["kind"]) == "pole_vault" and not bool(zombie["has_vaulted"]):
			var jump_target = _find_jump_target(int(zombie["row"]), float(zombie["x"]))
			if jump_target.y != -1:
				var plant_center_x = _cell_center(jump_target.x, jump_target.y).x
				zombie["jumping"] = true
				zombie["jump_t"] = 0.0
				zombie["jump_from_x"] = float(zombie["x"])
				zombie["jump_to_x"] = maxf(BOARD_ORIGIN.x - 18.0, plant_center_x - CELL_SIZE.x + 8.0)
				zombies[i] = zombie
				continue

		if String(zombie["kind"]) == "farmer":
			zombie["weed_pause_timer"] = maxf(0.0, float(zombie["weed_pause_timer"]) - delta)
			var current_col = int(floor((float(zombie["x"]) - BOARD_ORIGIN.x) / CELL_SIZE.x))
			if current_col < int(zombie["last_cell_col"]):
				zombie["last_cell_col"] = current_col
				if _spawn_farmer_weed(int(zombie["row"]), current_col - 1):
					zombie["weed_pause_timer"] = 0.55

		var target = _find_bite_target(int(zombie["row"]), float(zombie["x"]))
		if target.y != -1:
			var plant = grid[target.x][target.y]
			var bite_damage = float(zombie["attack_dps"]) * delta
			if float(plant["armor_health"]) > 0.0:
				var armor_left = float(plant["armor_health"]) - bite_damage
				if armor_left < 0.0:
					plant["health"] += armor_left
					armor_left = 0.0
				plant["armor_health"] = armor_left
				if armor_left <= 0.0 and String(plant["plant_food_mode"]) == "fortify":
					plant["plant_food_mode"] = ""
					plant["plant_food_timer"] = 0.0
					plant["max_armor_health"] = 0.0
			else:
				plant["health"] -= bite_damage
			if String(plant["kind"]) == "cactus_guard":
				zombie["health"] -= float(Defs.PLANTS["cactus_guard"]["thorns"]) * delta
			plant["flash"] = 0.08
			grid[target.x][target.y] = plant
		else:
			var should_pause = false
			if String(zombie["kind"]) == "kungfu" and float(zombie["reflect_timer"]) > 0.0:
				should_pause = true
			if String(zombie["kind"]) == "farmer" and float(zombie["weed_pause_timer"]) > 0.0:
				should_pause = true
			if String(zombie["kind"]) == "day_boss" and float(zombie["boss_pause_timer"]) > 0.0:
				should_pause = true
			if not should_pause:
				zombie["x"] -= _current_zombie_speed(zombie) * delta

		var mower = mowers[int(zombie["row"])]
		if float(zombie["x"]) <= BOARD_ORIGIN.x - 24.0:
			if bool(mower["armed"]):
				mower["armed"] = false
				mower["active"] = true
				mowers[int(zombie["row"])] = mower
			elif not bool(mower["active"]):
				_lose_level()
				return

		zombies[i] = zombie


func _update_mowers(delta: float) -> void:
	for i in range(mowers.size()):
		var mower = mowers[i]
		if not bool(mower["active"]):
			continue

		mower["x"] += MOWER_SPEED * delta
		for z in range(zombies.size()):
			var zombie = zombies[z]
			if int(zombie["row"]) != int(mower["row"]):
				continue
			if float(zombie["x"]) <= float(mower["x"]) + 52.0 and float(zombie["x"]) >= float(mower["x"]) - 24.0:
				zombie["health"] = 0.0
				zombie["flash"] = 0.2
				zombies[z] = zombie
		if float(mower["x"]) > BOARD_ORIGIN.x + BOARD_SIZE.x + 120.0:
			mower["active"] = false
			mower["x"] = BOARD_ORIGIN.x + BOARD_SIZE.x + 160.0
		mowers[i] = mower


func _spawn_sun(spawn_position: Vector2, target_y: float, source: String) -> void:
	var settle_speed = 165.0 if source == "sky" else 122.0
	var auto_delay = 0.65 if source == "sky" else 0.75
	if source == "plant_food":
		auto_delay = 0.2
	suns.append({
			"position": spawn_position,
			"target_y": target_y,
			"velocity": Vector2(rng.randf_range(-12.0, 12.0), settle_speed),
			"life": 12.0,
			"value": SUN_VALUE,
			"settled": false,
			"collecting": false,
			"auto_delay": auto_delay,
		})


func _update_suns(delta: float) -> void:
	for i in range(suns.size() - 1, -1, -1):
		var sun = suns[i]
		var sun_pos = sun["position"]
		sun["life"] -= delta

		if bool(sun["collecting"]):
			var to_target = _sun_target() - sun_pos
			var distance = to_target.length()
			if distance <= SUN_COLLECT_SPEED * delta:
				sun_points += int(sun["value"])
				suns.remove_at(i)
				continue
			sun_pos += to_target.normalized() * SUN_COLLECT_SPEED * delta
			sun["position"] = sun_pos
		elif not bool(sun["settled"]):
			sun_pos += Vector2(sun["velocity"]) * delta
			if sun_pos.y >= float(sun["target_y"]):
				sun_pos.y = float(sun["target_y"])
				sun["settled"] = true
				sun["velocity"] = Vector2.ZERO
			sun["position"] = sun_pos
		else:
			sun["auto_delay"] -= delta
			if float(sun["auto_delay"]) <= 0.0:
				sun["collecting"] = true
			sun["position"] = sun_pos

		if float(sun["life"]) <= 0.0 and not bool(sun["collecting"]):
			sun["collecting"] = true

		if i < suns.size():
			suns[i] = sun


func _spawn_coin(spawn_position: Vector2, value: int) -> void:
	coins.append({
		"position": spawn_position,
		"velocity": Vector2(rng.randf_range(-8.0, 8.0), -80.0),
		"value": value,
		"auto_delay": 0.55,
		"collecting": false,
		"life": 10.0,
	})


func _update_coins(delta: float) -> void:
	for i in range(coins.size() - 1, -1, -1):
		var coin = coins[i]
		var coin_pos = coin["position"]
		coin["life"] -= delta

		if bool(coin["collecting"]):
			var to_target = _coin_target() - coin_pos
			var distance = to_target.length()
			if distance <= COIN_COLLECT_SPEED * delta:
				coins_total += int(coin["value"])
				_mark_save_dirty()
				coins.remove_at(i)
				continue
			coin_pos += to_target.normalized() * COIN_COLLECT_SPEED * delta
			coin["position"] = coin_pos
		else:
			coin["auto_delay"] -= delta
			var velocity = coin["velocity"]
			coin_pos += velocity * delta
			velocity.y = minf(velocity.y + 180.0 * delta, 24.0)
			coin["velocity"] = velocity
			coin["position"] = coin_pos
			if float(coin["auto_delay"]) <= 0.0:
				coin["collecting"] = true

		if float(coin["life"]) <= 0.0 and not bool(coin["collecting"]):
			coin["collecting"] = true

		if i < coins.size():
			coins[i] = coin


func _spawn_plant_food_pickup(spawn_position: Vector2) -> void:
	plant_food_pickups.append({
		"position": spawn_position,
		"velocity": Vector2(rng.randf_range(-8.0, 8.0), -90.0),
		"collecting": false,
		"auto_delay": 0.45,
		"life": 12.0,
	})


func _update_plant_food_pickups(delta: float) -> void:
	for i in range(plant_food_pickups.size() - 1, -1, -1):
		var pickup = plant_food_pickups[i]
		var pickup_pos = pickup["position"]
		pickup["life"] -= delta

		if bool(pickup["collecting"]):
			var to_target = _plant_food_target() - pickup_pos
			var distance = to_target.length()
			if distance <= PLANT_FOOD_COLLECT_SPEED * delta:
				plant_food_count = min(plant_food_count + 1, MAX_PLANT_FOOD)
				plant_food_pickups.remove_at(i)
				continue
			pickup_pos += to_target.normalized() * PLANT_FOOD_COLLECT_SPEED * delta
			pickup["position"] = pickup_pos
		else:
			pickup["auto_delay"] -= delta
			var velocity = pickup["velocity"]
			pickup_pos += velocity * delta
			velocity.y = minf(velocity.y + 180.0 * delta, 28.0)
			pickup["velocity"] = velocity
			pickup["position"] = pickup_pos
			if float(pickup["auto_delay"]) <= 0.0:
				pickup["collecting"] = true

		if float(pickup["life"]) <= 0.0 and not bool(pickup["collecting"]):
			pickup["collecting"] = true

		if i < plant_food_pickups.size():
			plant_food_pickups[i] = pickup


func _update_effects(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		var effect = effects[i]
		effect["time"] -= delta
		if float(effect["time"]) <= 0.0:
			effects.remove_at(i)
			continue
		effects[i] = effect


func _remove_dead_plants() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue
			if float(plant_variant["health"]) <= 0.0:
				grid[row][col] = null


func _cleanup_dead_zombies() -> void:
	for i in range(zombies.size() - 1, -1, -1):
		var zombie = zombies[i]
		if float(zombie["health"]) > 0.0:
			continue
		total_kills += 1
		if String(zombie["kind"]) == "spear":
			_spawn_spear_obstacle(int(zombie["row"]), float(zombie["x"]))
		if bool(zombie.get("plant_food_carrier", false)):
			_spawn_plant_food_pickup(Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 28.0))
		var reward = int(Defs.ZOMBIES[String(zombie["kind"])]["reward"])
		_spawn_coin(Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 18.0), reward)
		zombies.remove_at(i)


func _check_end_state() -> void:
	if next_event_index >= current_level["events"].size() and zombies.is_empty() and spears.is_empty():
		_win_level()


func _win_level() -> void:
	if battle_state != BATTLE_PLAYING:
		return

	battle_state = BATTLE_WON
	completed_levels[selected_level_index] = true

	var unlocked_new = false
	if selected_level_index + 1 >= unlocked_levels and selected_level_index < Defs.LEVELS.size() - 1:
		unlocked_levels = selected_level_index + 2
		unlocked_new = true

	coins_total += 50
	_mark_save_dirty(true)
	var message = "%s 通关\n已消灭 %d 只僵尸\n奖励金币 +50" % [current_level["title"], total_kills]
	if unlocked_new and String(current_level["unlock_plant"]) != "":
		message += "\n解锁植物：%s" % Defs.PLANTS[String(current_level["unlock_plant"])]["name"]

	_show_message(message, "map", "返回地图")
	_show_banner("关卡完成！", 2.0)


func _lose_level() -> void:
	if battle_state != BATTLE_PLAYING:
		return
	battle_state = BATTLE_LOST
	_show_message("%s 失败\n僵尸闯进了房子" % current_level["title"], "retry", "重试本关")


func _show_message(text: String, action: String, button_text: String) -> void:
	panel_action = action
	message_label.text = text
	action_button.text = button_text
	message_panel.visible = true


func _on_message_button_pressed() -> void:
	match panel_action:
		"retry":
			_start_level(selected_level_index)
		_:
			_enter_map_mode()


func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_timer = 1.2
	toast_label.visible = true


func _show_banner(text: String, duration: float) -> void:
	banner_label.text = text
	banner_timer = duration
	banner_label.visible = true


func _update_overlay_timers(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer = maxf(0.0, toast_timer - delta)
		toast_label.visible = toast_timer > 0.0

	if banner_timer > 0.0:
		banner_timer = maxf(0.0, banner_timer - delta)
		banner_label.visible = banner_timer > 0.0


func _has_zombie_ahead(row: int, plant_x: float) -> bool:
	for zombie in zombies:
		if int(zombie["row"]) == row and float(zombie["x"]) > plant_x + 8.0:
			return true
	return false


func _mine_has_target(row: int, col: int) -> bool:
	var center_x = _cell_center(row, col).x
	for zombie in zombies:
		if int(zombie["row"]) != row or bool(zombie["jumping"]):
			continue
		if absf(float(zombie["x"]) - center_x) <= 42.0:
			return true
	return false


func _find_chomper_target(row: int, plant_x: float) -> int:
	return _find_lane_target(row, plant_x, float(Defs.PLANTS["chomper"]["range"]))


func _find_lane_target(row: int, plant_x: float, range_limit: float) -> int:
	var best_index = -1
	var best_distance = 999999.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie["jumping"]):
			continue
		var distance = float(zombie["x"]) - plant_x
		if distance < -8.0 or distance > range_limit:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _find_jump_target(row: int, zombie_x: float) -> Vector2i:
	for col in range(COLS - 1, -1, -1):
		var plant_variant = grid[row][col]
		if plant_variant == null:
			continue
		var center_x = _cell_center(row, col).x
		if zombie_x <= center_x + 82.0 and zombie_x >= center_x + 12.0:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _find_bite_target(row: int, zombie_x: float) -> Vector2i:
	for col in range(COLS - 1, -1, -1):
		var plant_variant = grid[row][col]
		if plant_variant == null:
			continue
		var center_x = _cell_center(row, col).x
		if zombie_x <= center_x + 38.0 and zombie_x >= center_x - 20.0:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _spawn_farmer_weed(row: int, target_col: int) -> bool:
	if target_col < 0 or target_col >= COLS or not _is_row_active(row):
		return false
	for weed in weeds:
		if int(weed["row"]) == row and int(weed["col"]) == target_col:
			return false
	var weed_x = _cell_center(row, target_col).x
	weeds.append({
		"row": row,
		"col": target_col,
		"x": weed_x,
		"health": float(Defs.ZOMBIES["conehead"]["health"]),
		"max_health": float(Defs.ZOMBIES["conehead"]["health"]),
	})
	return true


func _spawn_spear_obstacle(row: int, x: float) -> void:
	spears.append({
		"row": row,
		"x": x,
		"health": 120.0,
		"max_health": 120.0,
		"spawned": false,
	})


func _update_weeds_and_spears() -> void:
	for i in range(weeds.size() - 1, -1, -1):
		if float(weeds[i]["health"]) <= 0.0:
			weeds.remove_at(i)
	for i in range(spears.size() - 1, -1, -1):
		var spear = spears[i]
		if float(spear["health"]) > 0.0:
			continue
		if not bool(spear["spawned"]):
			_spawn_zombie_at("normal", int(spear["row"]), float(spear["x"]))
			spear["spawned"] = true
		spears.remove_at(i)


func _spawn_zombie_at(kind: String, row: int, x: float) -> void:
	_spawn_zombie(kind, row)
	if zombies.is_empty():
		return
	var zombie = zombies[zombies.size() - 1]
	zombie["x"] = x
	zombies[zombies.size() - 1] = zombie


func _trigger_boss_skill(zombie: Dictionary) -> void:
	effects.append({
		"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"]))),
		"radius": 120.0,
		"time": 0.4,
		"duration": 0.4,
		"color": Color(1.0, 0.32, 0.2, 0.4),
	})
	for kind in ["normal", "farmer", "spear"]:
		var row = _choose_spawn_row()
		_spawn_zombie(kind, row)


func _current_zombie_speed(zombie: Dictionary) -> float:
	var speed = float(zombie["base_speed"])
	if float(zombie["slow_timer"]) > 0.0:
		speed *= 0.5
	return speed


func _explode_cherry(row: int, col: int, mega: bool = false) -> void:
	var center = _cell_center(row, col)
	var radius = float(Defs.PLANTS["cherry_bomb"]["radius"])
	if mega:
		radius += 72.0
	effects.append({
			"position": center,
			"radius": radius,
			"time": 0.42,
			"duration": 0.42,
			"color": Color(0.36, 1.0, 0.38, 0.68) if mega else Color(1.0, 0.44, 0.24, 0.72),
		})
	for i in range(zombies.size()):
		var zombie = zombies[i]
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) <= radius:
			zombie["health"] = 0.0
			zombie["flash"] = 0.24
			zombies[i] = zombie


func _explode_mine(row: int, col: int) -> void:
	var center = _cell_center(row, col)
	var radius = float(Defs.PLANTS["potato_mine"]["radius"])
	effects.append({
		"position": center,
		"radius": 96.0,
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.84, 0.28, 0.74),
	})
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row:
			continue
		if absf(float(zombie["x"]) - center.x) <= radius:
			zombie["health"] = 0.0
			zombie["flash"] = 0.24
			zombies[i] = zombie


func _find_projectile_target(projectile: Dictionary) -> int:
	var best_index = -1
	var best_distance = 999999.0
	var projectile_pos = projectile["position"]
	var projectile_radius = float(projectile.get("radius", 8.0))
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != int(projectile["row"]):
			continue
		var distance = float(zombie["x"]) - projectile_pos.x
		if distance < -20.0 or distance > 20.0 + projectile_radius:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _find_projectile_plant_target(projectile: Dictionary) -> Vector2i:
	var projectile_pos = Vector2(projectile["position"])
	for col in range(COLS - 1, -1, -1):
		var plant_variant = grid[int(projectile["row"])][col]
		if plant_variant == null:
			continue
		var center_x = _cell_center(int(projectile["row"]), col).x
		if projectile_pos.x <= center_x + 26.0 and projectile_pos.x >= center_x - 30.0:
			return Vector2i(int(projectile["row"]), col)
	return Vector2i(-1, -1)


func _damage_projectile_obstacle(projectile: Dictionary) -> bool:
	var projectile_pos = Vector2(projectile["position"])
	for i in range(weeds.size()):
		var weed = weeds[i]
		if int(weed["row"]) != int(projectile["row"]):
			continue
		if absf(float(weed["x"]) - projectile_pos.x) > 26.0:
			continue
		weed["health"] -= float(projectile["damage"])
		weeds[i] = weed
		return true
	for i in range(spears.size()):
		var spear = spears[i]
		if int(spear["row"]) != int(projectile["row"]):
			continue
		if absf(float(spear["x"]) - projectile_pos.x) > 22.0:
			continue
		spear["health"] -= float(projectile["damage"])
		spears[i] = spear
		return true
	return false


func _find_frontmost_zombie(row: int) -> int:
	var best_index = -1
	var best_x = -999999.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row:
			continue
		if float(zombie["x"]) > best_x:
			best_x = float(zombie["x"])
			best_index = i
	return best_index


func _damage_zombies_in_radius(row: int, center_x: float, radius: float, damage: float) -> void:
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row:
			continue
		if absf(float(zombie["x"]) - center_x) > radius:
			continue
		zombie["health"] -= damage
		zombie["flash"] = 0.16
		zombies[i] = zombie


func _card_rect(index: int) -> Rect2:
	var card_size = _seed_bank_card_size()
	var card_gap = _seed_bank_card_gap()
	return Rect2(
		Vector2(138.0 + index * (card_size.x + card_gap), 22.0),
		card_size
	)


func _card_at(mouse_pos: Vector2) -> String:
	for i in range(active_cards.size()):
		if _card_rect(i).has_point(mouse_pos):
			return String(active_cards[i])
	return ""


func _shovel_rect() -> Rect2:
	var card_size = _seed_bank_card_size()
	var card_gap = _seed_bank_card_gap()
	var x = 138.0 + active_cards.size() * (card_size.x + card_gap) + 12.0
	return Rect2(x, 22.0, 84.0, 92.0)


func _seed_bank_card_size() -> Vector2:
	if active_cards.size() >= 10:
		return Vector2(68.0, 92.0)
	if active_cards.size() >= 9:
		return Vector2(74.0, 92.0)
	return CARD_SIZE


func _seed_bank_card_gap() -> float:
	if active_cards.size() >= 10:
		return 4.0
	if active_cards.size() >= 9:
		return 5.0
	return CARD_GAP


func _selection_slot_rect(index: int) -> Rect2:
	return Rect2(
		Vector2(PREP_SELECTED_PANEL_RECT.position.x + 20.0 + index * 100.0, PREP_SELECTED_PANEL_RECT.position.y + 14.0),
		Vector2(88.0, 100.0)
	)


func _selection_pool_rect(index: int) -> Rect2:
	var columns := 6
	var col = index % columns
	var row = int(floor(float(index) / float(columns)))
	return Rect2(
		Vector2(PREP_POOL_PANEL_RECT.position.x + 24.0 + col * 110.0, PREP_POOL_PANEL_RECT.position.y + 44.0 + row * 118.0),
		Vector2(96.0, 108.0)
	)


func _selection_slot_at(mouse_pos: Vector2) -> int:
	for i in range(MAX_SEED_SLOTS):
		if _selection_slot_rect(i).has_point(mouse_pos):
			return i
	return -1


func _selection_pool_card_at(mouse_pos: Vector2) -> String:
	for i in range(selection_pool_cards.size()):
		if _selection_pool_rect(i).has_point(mouse_pos):
			return String(selection_pool_cards[i])
	return ""


func _requires_seed_selection(level: Dictionary) -> bool:
	var mode_name = String(level.get("mode", ""))
	if mode_name == "conveyor" or mode_name == "bowling":
		return false
	return level["available_plants"].size() > MAX_SEED_SLOTS


func _selection_zombie_kinds() -> Array:
	var kinds: Array = []
	var seen := {}
	for event in current_level.get("events", []):
		var kind = String(event.get("kind", ""))
		if kind == "" or seen.has(kind):
			continue
		seen[kind] = true
		kinds.append(kind)
	return kinds


func _level_node_at(mouse_pos: Vector2) -> int:
	for i in range(Defs.LEVELS.size()):
		var node_pos = Vector2(Defs.LEVELS[i]["node_pos"])
		if mouse_pos.distance_to(node_pos) <= 34.0:
			return i
	return -1


func _mouse_to_cell(mouse_pos: Vector2) -> Vector2i:
	var board_rect = Rect2(BOARD_ORIGIN, BOARD_SIZE)
	if not board_rect.has_point(mouse_pos):
		return Vector2i(-1, -1)
	var col = int((mouse_pos.x - BOARD_ORIGIN.x) / CELL_SIZE.x)
	var row = int((mouse_pos.y - BOARD_ORIGIN.y) / CELL_SIZE.y)
	if not _is_row_active(row):
		return Vector2i(-1, -1)
	return Vector2i(row, col)


func _cell_center(row: int, col: int) -> Vector2:
	return BOARD_ORIGIN + Vector2(col * CELL_SIZE.x + CELL_SIZE.x * 0.5, row * CELL_SIZE.y + CELL_SIZE.y * 0.5)


func _cell_rect(row: int, col: int) -> Rect2:
	return Rect2(BOARD_ORIGIN + Vector2(col * CELL_SIZE.x, row * CELL_SIZE.y), CELL_SIZE)


func _row_center_y(row: int) -> float:
	return BOARD_ORIGIN.y + row * CELL_SIZE.y + CELL_SIZE.y * 0.58


func _sun_target() -> Vector2:
	return SUN_METER_RECT.position + SUN_METER_RECT.size * 0.5


func _plant_food_target() -> Vector2:
	return PLANT_FOOD_RECT.position + PLANT_FOOD_RECT.size * 0.5


func _coin_target() -> Vector2:
	return COIN_METER_RECT.position + COIN_METER_RECT.size * 0.5


func _is_conveyor_level() -> bool:
	return String(current_level.get("mode", "")) == "conveyor" or String(current_level.get("mode", "")) == "bowling"


func _is_bowling_level() -> bool:
	return String(current_level.get("mode", "")) == "bowling"


func _update_conveyor(delta: float) -> void:
	if not _is_conveyor_level():
		return
	conveyor_spawn_timer -= delta
	if conveyor_spawn_timer > 0.0:
		return

	for i in range(active_cards.size()):
		if String(active_cards[i]) == "":
			_fill_conveyor_slot(i)
			conveyor_spawn_timer = rng.randf_range(1.1, 2.0)
			return
	conveyor_spawn_timer = 0.6


func _fill_conveyor_slot(index: int) -> void:
	if index < 0 or index >= active_cards.size() or conveyor_source_cards.is_empty():
		return
	var kind = String(conveyor_source_cards[rng.randi_range(0, conveyor_source_cards.size() - 1)])
	active_cards[index] = kind


func _consume_conveyor_card(kind: String) -> void:
	for i in range(active_cards.size()):
		if String(active_cards[i]) == kind:
			active_cards[i] = ""
			break


func _level_time_scale() -> float:
	if current_level.is_empty():
		return 1.0
	return float(current_level.get("time_scale", 1.0))


func _batch_pause_duration() -> float:
	return 1.4 * _level_time_scale()


func _intra_batch_spawn_delay() -> float:
	return clampf(0.62 * _level_time_scale(), 0.55, 1.2)


func _max_batch_size() -> int:
	var row_count = int(current_level.get("row_count", ROWS))
	if row_count <= 1:
		return 1
	if row_count == 2:
		return 2
	if row_count == 3:
		return 2
	if row_count == 4:
		return 3
	return 4


func _target_batch_size() -> int:
	var total_events = max(current_level["events"].size(), 1)
	var progress = float(next_event_index) / float(total_events)
	var batch_size = 1 + int(floor(progress * float(_max_batch_size())))
	return clampi(batch_size, 1, _max_batch_size())


func _spawn_gate_limit() -> int:
	return min(2, max(0, _target_batch_size() - 1))


func _active_zombie_count() -> int:
	return zombies.size() + batch_spawn_remaining


func _build_active_rows(row_count: int) -> Array:
	match row_count:
		1:
			return [2]
		2:
			return [1, 3]
		3:
			return [1, 2, 3]
		4:
			return [0, 1, 3, 4]
		_:
			return [0, 1, 2, 3, 4]


func _is_row_active(row: int) -> bool:
	if active_rows.is_empty():
		return true
	return active_rows.has(row)


func _random_active_target_y() -> float:
	var row = int(active_rows[rng.randi_range(0, active_rows.size() - 1)])
	return rng.randf_range(
		BOARD_ORIGIN.y + row * CELL_SIZE.y + 24.0,
		BOARD_ORIGIN.y + row * CELL_SIZE.y + CELL_SIZE.y - 24.0
	)


func _draw() -> void:
	if mode == MODE_MAP:
		_draw_map_scene()
	elif mode == MODE_SELECTION:
		_draw_seed_selection_scene()
	else:
		_draw_battle_scene()


func _draw_map_scene() -> void:
	_draw_rect_full(Color(0.77, 0.89, 1.0))
	draw_rect(Rect2(Vector2(0.0, 160.0), Vector2(size.x, size.y - 160.0)), Color(0.68, 0.82, 0.5), true)
	draw_circle(Vector2(102.0, 86.0), 38.0, Color(1.0, 0.94, 0.56))
	draw_circle(Vector2(220.0, 114.0), 32.0, Color(1.0, 1.0, 1.0, 0.82))
	draw_circle(Vector2(280.0, 92.0), 26.0, Color(1.0, 1.0, 1.0, 0.82))

	draw_rect(Rect2(Vector2(40.0, 186.0), Vector2(220.0, 420.0)), Color(0.86, 0.78, 0.58), true)
	draw_rect(Rect2(Vector2(64.0, 242.0), Vector2(170.0, 164.0)), Color(0.93, 0.88, 0.74), true)
	draw_rect(Rect2(Vector2(94.0, 196.0), Vector2(110.0, 62.0)), Color(0.79, 0.28, 0.21), true)

	var nodes = []
	for level in Defs.LEVELS:
		nodes.append(Vector2(level["node_pos"]))

	for i in range(nodes.size() - 1):
		draw_line(nodes[i], nodes[i + 1], Color(0.47, 0.37, 0.24), 16.0)
		draw_line(nodes[i], nodes[i + 1], Color(0.82, 0.71, 0.42), 8.0)

	for i in range(Defs.LEVELS.size()):
		_draw_level_node(i)

	_draw_text("白天冒险", Vector2(34.0, 58.0), 36, Color(0.23, 0.15, 0.05))
	_draw_text("点击灯泡进入关卡，超过 10 张植物时先进入选卡。", Vector2(34.0, 90.0), 18, Color(0.26, 0.18, 0.08))

	draw_rect(COIN_METER_RECT, Color(0.97, 0.89, 0.44), true)
	draw_rect(COIN_METER_RECT, Color(0.48, 0.36, 0.09), false, 2.0)
	_draw_coin_icon(COIN_METER_RECT.position + Vector2(22.0, 20.0), 1.0)
	_draw_text(str(coins_total), COIN_METER_RECT.position + Vector2(44.0, 27.0), 22, Color(0.31, 0.2, 0.05))

	_draw_map_info_panel()


func _draw_level_node(level_index: int) -> void:
	var level = Defs.LEVELS[level_index]
	var node_pos = Vector2(level["node_pos"])
	var unlocked = level_index < unlocked_levels
	var completed = bool(completed_levels[level_index])
	var hovered = level_index == hovered_level_index
	var pulse = 0.55 + 0.45 * sin(map_time * 3.2 + float(level_index) * 0.8)

	var halo_color = Color(0.38, 0.86, 0.42, 0.18 + 0.1 * pulse)
	var bulb_color = Color(0.74, 0.86, 0.78)
	var outline = Color(0.3, 0.45, 0.25)

	if not unlocked:
		halo_color = Color(0.0, 0.0, 0.0, 0.0)
		bulb_color = Color(0.56, 0.58, 0.6)
		outline = Color(0.34, 0.34, 0.36)
	elif completed:
		halo_color = Color(1.0, 0.88, 0.28, 0.22 + 0.1 * pulse)
		bulb_color = Color(1.0, 0.94, 0.58)
		outline = Color(0.6, 0.48, 0.12)
	elif hovered:
		halo_color = Color(0.7, 1.0, 0.64, 0.34 + 0.08 * pulse)
		bulb_color = Color(0.82, 1.0, 0.74)
		outline = Color(0.28, 0.54, 0.22)

	if unlocked:
		draw_circle(node_pos, 40.0 + 5.0 * pulse, halo_color)
	draw_circle(node_pos + Vector2(0.0, 6.0), 22.0, Color(0.42, 0.42, 0.46))
	draw_rect(Rect2(node_pos + Vector2(-11.0, 18.0), Vector2(22.0, 10.0)), Color(0.48, 0.48, 0.52), true)
	draw_circle(node_pos, 28.0, bulb_color)
	draw_circle(node_pos + Vector2(-8.0, -10.0), 8.0, Color(1.0, 1.0, 1.0, 0.42))
	draw_circle(node_pos + Vector2(10.0, 10.0), 3.0, Color(1.0, 1.0, 1.0, 0.2))
	draw_circle(node_pos, 28.0, outline, false, 2.0)
	_draw_text(str(level_index + 1), node_pos + Vector2(-8.0, 7.0), 24, Color(0.19, 0.19, 0.2))
	_draw_text(String(level["id"]), node_pos + Vector2(-22.0, -42.0), 16, Color(0.25, 0.18, 0.08))

	if completed:
		draw_polygon(
			PackedVector2Array([
				node_pos + Vector2(-6.0, -48.0),
				node_pos + Vector2(0.0, -60.0),
				node_pos + Vector2(6.0, -48.0),
			]),
			PackedColorArray([
				Color(1.0, 0.84, 0.24),
				Color(1.0, 0.84, 0.24),
				Color(1.0, 0.84, 0.24),
			])
		)

	if bool(level.get("boss_level", false)):
		var skull_center = node_pos + Vector2(0.0, -56.0)
		draw_circle(skull_center, 14.0, Color(0.96, 0.96, 0.94))
		draw_circle(skull_center + Vector2(-5.0, -2.0), 2.4, Color(0.12, 0.12, 0.12))
		draw_circle(skull_center + Vector2(5.0, -2.0), 2.4, Color(0.12, 0.12, 0.12))
		draw_polygon(
			PackedVector2Array([
				skull_center + Vector2(0.0, 3.0),
				skull_center + Vector2(-3.0, 8.0),
				skull_center + Vector2(3.0, 8.0),
			]),
			PackedColorArray([Color(0.12, 0.12, 0.12), Color(0.12, 0.12, 0.12), Color(0.12, 0.12, 0.12)])
		)
		draw_rect(Rect2(skull_center + Vector2(-5.0, 8.0), Vector2(10.0, 5.0)), Color(0.96, 0.96, 0.94), true)
		draw_line(skull_center + Vector2(-11.0, -16.0), skull_center + Vector2(-20.0, -24.0), Color(0.82, 0.18, 0.18), 3.0)
		draw_line(skull_center + Vector2(11.0, -16.0), skull_center + Vector2(20.0, -24.0), Color(0.82, 0.18, 0.18), 3.0)

	if not unlocked:
		draw_rect(Rect2(node_pos + Vector2(-9.0, -8.0), Vector2(18.0, 16.0)), Color(0.3, 0.3, 0.32), true)
		draw_arc(node_pos + Vector2(0.0, -8.0), 8.0, PI, TAU, 8, Color(0.3, 0.3, 0.32), 2.0)


func _draw_map_info_panel() -> void:
	var info_index = hovered_level_index
	if info_index == -1:
		info_index = clampi(unlocked_levels - 1, 0, Defs.LEVELS.size() - 1)

	var level = Defs.LEVELS[info_index]
	var panel_rect = Rect2(892.0, 122.0, 392.0, 152.0)
	draw_rect(panel_rect, Color(0.95, 0.9, 0.76), true)
	draw_rect(panel_rect, Color(0.48, 0.35, 0.16), false, 3.0)

	var status_text = "已解锁"
	if info_index >= unlocked_levels:
		status_text = "未解锁"
	elif bool(completed_levels[info_index]):
		status_text = "已完成"

	_draw_text(String(level["title"]), panel_rect.position + Vector2(18.0, 34.0), 28, Color(0.24, 0.16, 0.06))
	_draw_text("状态：%s" % status_text, panel_rect.position + Vector2(18.0, 64.0), 18, Color(0.28, 0.2, 0.08))
	_draw_text(String(level["description"]), panel_rect.position + Vector2(18.0, 92.0), 16, Color(0.3, 0.22, 0.1))

	var unlock_text = "最终关"
	var unlock_color = Color(0.42, 0.2, 0.08)
	if String(level["unlock_plant"]) != "":
		unlock_text = "解锁：" + String(Defs.PLANTS[String(level["unlock_plant"])]["name"])
		unlock_color = Color(0.1, 0.42, 0.18)
	elif info_index < Defs.LEVELS.size() - 1:
		unlock_text = "下一关：" + String(Defs.LEVELS[info_index + 1]["id"])
		unlock_color = Color(0.24, 0.3, 0.08)
	_draw_text(unlock_text, panel_rect.position + Vector2(18.0, 120.0), 18, unlock_color)

	var plants = level["available_plants"]
	var plant_preview_count = min(plants.size(), 8)
	for i in range(plant_preview_count):
		var chip_x = panel_rect.position.x + 216.0 + float(i % 4) * 42.0
		var chip_y = panel_rect.position.y + 30.0 + floor(float(i) / 4.0) * 54.0
		var chip_rect = Rect2(chip_x, chip_y, 38.0, 48.0)
		draw_rect(chip_rect, Color(0.97, 0.94, 0.86), true)
		draw_rect(chip_rect, Color(0.48, 0.35, 0.16), false, 1.0)
		_draw_card_icon(String(plants[i]), chip_rect.position + Vector2(chip_rect.size.x * 0.5, 24.0))
	if plants.size() > plant_preview_count:
		_draw_text("+%d" % (plants.size() - plant_preview_count), panel_rect.position + Vector2(338.0, 136.0), 16, Color(0.24, 0.16, 0.06))

	if info_index < unlocked_levels:
		var prompt = "点击灯泡选植物" if _requires_seed_selection(level) else "点击灯泡开始"
		_draw_text(prompt, panel_rect.position + Vector2(238.0, 136.0), 16, Color(0.3, 0.22, 0.1))
	else:
		_draw_text("先通关前一关", panel_rect.position + Vector2(244.0, 136.0), 16, Color(0.42, 0.18, 0.1))


func _draw_seed_selection_scene() -> void:
	_draw_rect_full(Color(0.79, 0.9, 1.0))
	draw_rect(Rect2(Vector2(0.0, 148.0), Vector2(size.x, size.y - 148.0)), Color(0.68, 0.82, 0.5), true)
	draw_rect(Rect2(Vector2(0.0, 610.0), Vector2(size.x, 110.0)), Color(0.58, 0.42, 0.24), true)
	draw_circle(Vector2(104.0, 86.0), 38.0, Color(1.0, 0.94, 0.56))
	draw_rect(Rect2(Vector2(44.0, 182.0), Vector2(214.0, 392.0)), Color(0.86, 0.78, 0.58), true)
	draw_rect(Rect2(Vector2(66.0, 238.0), Vector2(170.0, 164.0)), Color(0.93, 0.88, 0.74), true)
	draw_rect(Rect2(Vector2(96.0, 192.0), Vector2(110.0, 62.0)), Color(0.79, 0.28, 0.21), true)

	draw_rect(PREP_SELECTED_PANEL_RECT, Color(0.95, 0.9, 0.76), true)
	draw_rect(PREP_SELECTED_PANEL_RECT, Color(0.48, 0.35, 0.16), false, 3.0)
	draw_rect(PREP_ZOMBIE_PANEL_RECT, Color(0.92, 0.88, 0.8), true)
	draw_rect(PREP_ZOMBIE_PANEL_RECT, Color(0.48, 0.35, 0.16), false, 2.0)
	draw_rect(PREP_POOL_PANEL_RECT, Color(0.95, 0.92, 0.84), true)
	draw_rect(PREP_POOL_PANEL_RECT, Color(0.48, 0.35, 0.16), false, 3.0)

	_draw_text(String(current_level["title"]), Vector2(122.0, 56.0), 34, Color(0.23, 0.15, 0.05))
	_draw_text("选择最多 10 张植物后进入关卡", Vector2(122.0, 88.0), 18, Color(0.26, 0.18, 0.08))
	_draw_text(String(current_level["description"]), Vector2(122.0, 118.0), 16, Color(0.32, 0.24, 0.1))
	_draw_text("已选 %d/10" % selection_cards.size(), PREP_SELECTED_PANEL_RECT.position + Vector2(20.0, 30.0), 24, Color(0.2, 0.32, 0.08))
	_draw_text("本关僵尸", PREP_ZOMBIE_PANEL_RECT.position + Vector2(18.0, 32.0), 18, Color(0.24, 0.16, 0.06))
	_draw_text("可选植物", PREP_POOL_PANEL_RECT.position + Vector2(18.0, 30.0), 22, Color(0.24, 0.16, 0.06))

	for i in range(MAX_SEED_SLOTS):
		var slot_rect = _selection_slot_rect(i)
		draw_rect(slot_rect, Color(0.9, 0.86, 0.76), true)
		draw_rect(slot_rect, Color(0.46, 0.34, 0.16), false, 2.0)
		if i < selection_cards.size():
			_draw_selection_card(String(selection_cards[i]), slot_rect, true, false)

	var zombie_kinds = _selection_zombie_kinds()
	for i in range(zombie_kinds.size()):
		var chip_rect = Rect2(PREP_ZOMBIE_PANEL_RECT.position + Vector2(126.0 + i * 138.0, 8.0), Vector2(124.0, 34.0))
		draw_rect(chip_rect, Color(0.87, 0.9, 0.84), true)
		draw_rect(chip_rect, Color(0.42, 0.35, 0.2), false, 1.0)
		_draw_text(String(Defs.ZOMBIES[String(zombie_kinds[i])]["name"]), chip_rect.position + Vector2(12.0, 22.0), 15, Color(0.22, 0.16, 0.08))

	for i in range(selection_pool_cards.size()):
		var kind = String(selection_pool_cards[i])
		var selected = selection_cards.has(kind)
		var disabled = selection_cards.size() >= MAX_SEED_SLOTS and not selected
		_draw_selection_card(kind, _selection_pool_rect(i), selected, disabled)

	var back_color = Color(0.88, 0.84, 0.76)
	var start_color = Color(0.42, 0.76, 0.24) if not selection_cards.is_empty() else Color(0.62, 0.62, 0.62)
	draw_rect(PREP_BACK_RECT, back_color, true)
	draw_rect(PREP_BACK_RECT, Color(0.42, 0.3, 0.14), false, 2.0)
	draw_rect(PREP_START_RECT, start_color, true)
	draw_rect(PREP_START_RECT, Color(0.22, 0.36, 0.12), false, 2.0)
	_draw_text("返回地图", PREP_BACK_RECT.position + Vector2(18.0, 28.0), 18, Color(0.26, 0.18, 0.08))
	_draw_text("开始战斗", PREP_START_RECT.position + Vector2(24.0, 28.0), 20, Color(0.08, 0.2, 0.04))


func _draw_selection_card(kind: String, rect: Rect2, selected: bool, disabled: bool) -> void:
	var bg = Color(0.96, 0.94, 0.87) if not disabled else Color(0.82, 0.8, 0.76)
	draw_rect(rect, bg, true)
	draw_rect(rect, Color(0.42, 0.3, 0.14), false, 2.0)
	if selected:
		draw_rect(rect.grow(2.0), Color(0.94, 0.84, 0.24), false, 4.0)
	_draw_card_icon(kind, rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.53))
	_draw_text(String(Defs.PLANTS[kind]["name"]), rect.position + Vector2(8.0, 18.0), 12, Color(0.28, 0.18, 0.06))
	_draw_text(str(Defs.PLANTS[kind]["cost"]), rect.position + Vector2(10.0, rect.size.y - 10.0), 16, Color(0.28, 0.18, 0.06))
	if disabled:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.16), true)


func _draw_battle_scene() -> void:
	_draw_battle_background()
	_draw_battle_board()
	_draw_seed_bank()
	_draw_wave_bar()
	_draw_hover()
	_draw_mowers()
	_draw_lane_obstacles()
	_draw_plants()
	_draw_projectiles()
	_draw_rollers()
	_draw_zombies()
	_draw_suns()
	_draw_coins()
	_draw_plant_food_pickups()
	_draw_effects()

	if battle_state != BATTLE_PLAYING:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.28), true)


func _draw_battle_background() -> void:
	_draw_rect_full(Color(0.79, 0.9, 1.0))
	draw_rect(Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.66, 0.79, 0.49), true)
	draw_rect(Rect2(Vector2(28.0, 118.0), Vector2(160.0, size.y - 118.0)), Color(0.86, 0.77, 0.58), true)
	draw_rect(Rect2(Vector2(46.0, 164.0), Vector2(124.0, 144.0)), Color(0.93, 0.88, 0.75), true)
	draw_rect(Rect2(Vector2(68.0, 122.0), Vector2(80.0, 56.0)), Color(0.78, 0.28, 0.2), true)
	draw_rect(Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.76, 0.67, 0.54), true)
	draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, BOARD_SIZE.y)), Color(0.57, 0.43, 0.26), true)
	draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + BOARD_SIZE.x, BOARD_ORIGIN.y), Vector2(82.0, BOARD_SIZE.y)), Color(0.52, 0.65, 0.44), true)

	draw_rect(COIN_METER_RECT, Color(0.97, 0.89, 0.44), true)
	draw_rect(COIN_METER_RECT, Color(0.48, 0.36, 0.09), false, 2.0)
	_draw_coin_icon(COIN_METER_RECT.position + Vector2(22.0, 20.0), 1.0)
	_draw_text(str(coins_total), COIN_METER_RECT.position + Vector2(44.0, 27.0), 22, Color(0.31, 0.2, 0.05))

	draw_rect(BACK_BUTTON_RECT, Color(0.92, 0.88, 0.78), true)
	draw_rect(BACK_BUTTON_RECT, Color(0.42, 0.3, 0.14), false, 2.0)
	_draw_text("返回地图", BACK_BUTTON_RECT.position + Vector2(14.0, 27.0), 18, Color(0.27, 0.18, 0.08))


func _draw_battle_board() -> void:
	for row in range(ROWS):
		var lane_rect = Rect2(
			Vector2(BOARD_ORIGIN.x, BOARD_ORIGIN.y + row * CELL_SIZE.y),
			Vector2(BOARD_SIZE.x, CELL_SIZE.y)
		)
		if not _is_row_active(row):
			draw_rect(lane_rect, Color(0.44, 0.53, 0.31), true)
			draw_rect(lane_rect, Color(0.12, 0.18, 0.08, 0.34), true)
			draw_rect(lane_rect, Color(0.16, 0.26, 0.12, 0.36), false, 2.0)
			continue
		var lane_color = Color(0.39, 0.75, 0.31) if row % 2 == 0 else Color(0.34, 0.68, 0.26)
		draw_rect(lane_rect, lane_color, true)
		draw_rect(lane_rect, Color(1.0, 1.0, 1.0, 0.1), false, 2.0)

		for col in range(COLS):
			var tile = _cell_rect(row, col).grow(-2.0)
			var tint = Color(1.0, 1.0, 1.0, 0.03) if (row + col) % 2 == 0 else Color(0.0, 0.0, 0.0, 0.02)
			draw_rect(tile, tint, true)
			draw_rect(tile, Color(0.16, 0.35, 0.12, 0.22), false, 1.0)

	draw_rect(Rect2(BOARD_ORIGIN, BOARD_SIZE), Color(0.12, 0.28, 0.08, 0.68), false, 4.0)


func _draw_seed_bank() -> void:
	draw_rect(SEED_BANK_RECT, Color(0.93, 0.88, 0.72), true)
	draw_rect(SEED_BANK_RECT, Color(0.43, 0.33, 0.18), false, 3.0)

	draw_rect(SUN_METER_RECT, Color(1.0, 0.92, 0.54), true)
	draw_rect(SUN_METER_RECT, Color(0.55, 0.41, 0.08), false, 3.0)
	if _is_conveyor_level():
		_draw_text("传送带", Vector2(38.0, 48.0), 18, Color(0.33, 0.21, 0.04))
		_draw_text("自动供卡", Vector2(34.0, 84.0), 22, Color(0.33, 0.21, 0.04))
	else:
		_draw_text("阳光", Vector2(46.0, 48.0), 18, Color(0.33, 0.21, 0.04))
		_draw_text(str(sun_points), Vector2(54.0, 86.0), 28, Color(0.33, 0.21, 0.04))

	for index in range(active_cards.size()):
		var kind = String(active_cards[index])
		var rect = _card_rect(index)
		if kind == "":
			draw_rect(rect, Color(0.88, 0.84, 0.76), true)
			draw_rect(rect, Color(0.38, 0.28, 0.16), false, 2.0)
			continue
		var data = Defs.PLANTS[kind]
		var selected = selected_tool == kind
		var affordable = sun_points >= int(data["cost"])
		var cooling_ratio = 0.0
		if card_cooldowns.has(kind) and float(data["cooldown"]) > 0.0:
			cooling_ratio = float(card_cooldowns[kind]) / float(data["cooldown"])
		var card_color = Color(0.95, 0.94, 0.86) if affordable else Color(0.8, 0.76, 0.72)
		if _is_conveyor_level():
			card_color = Color(0.92, 0.96, 0.86)

		draw_rect(rect, card_color, true)
		draw_rect(rect, Color(0.38, 0.28, 0.16), false, 2.0)
		if selected:
			draw_rect(rect.grow(2.0), Color(1.0, 0.9, 0.18), false, 4.0)

		_draw_card_icon(kind, rect.position + Vector2(rect.size.x * 0.5, 46.0))
		var name_font_size = 10 if rect.size.x < 76.0 else 12
		var cost_x = 6.0 if rect.size.x < 76.0 else 8.0
		if not _is_conveyor_level():
			_draw_text(str(data["cost"]), rect.position + Vector2(cost_x, 84.0), 16, Color(0.29, 0.17, 0.05))
		_draw_text(String(data["name"]), rect.position + Vector2(4.0, 17.0), name_font_size, Color(0.29, 0.17, 0.05))

		if not _is_conveyor_level() and not affordable and float(card_cooldowns[kind]) <= 0.01:
			draw_rect(rect, Color(0.0, 0.0, 0.0, 0.24), true)

		if not _is_conveyor_level() and float(card_cooldowns[kind]) > 0.01:
			var cover_height = rect.size.y * clampf(cooling_ratio, 0.0, 1.0)
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, cover_height)), Color(0.12, 0.12, 0.12, 0.46), true)

	var shovel_rect = _shovel_rect()
	draw_rect(shovel_rect, Color(0.91, 0.88, 0.79), true)
	draw_rect(shovel_rect, Color(0.38, 0.28, 0.16), false, 2.0)
	if selected_tool == "shovel":
		draw_rect(shovel_rect.grow(2.0), Color(1.0, 0.9, 0.18), false, 4.0)
	_draw_shovel_icon(shovel_rect.position + shovel_rect.size * 0.5)
	_draw_text("铲子", shovel_rect.position + Vector2(20.0, 82.0), 18, Color(0.26, 0.19, 0.08))

	draw_rect(PLANT_FOOD_RECT, Color(0.84, 0.96, 0.76), true)
	draw_rect(PLANT_FOOD_RECT, Color(0.2, 0.54, 0.14), false, 2.0)
	if selected_tool == "plant_food":
		draw_rect(PLANT_FOOD_RECT.grow(2.0), Color(1.0, 0.9, 0.18), false, 4.0)
	if plant_food_count <= 0:
		draw_rect(PLANT_FOOD_RECT, Color(0.0, 0.0, 0.0, 0.18), true)
	_draw_plant_food_icon(PLANT_FOOD_RECT.position + Vector2(20.0, 23.0), 0.8)
	_draw_text("能量豆", PLANT_FOOD_RECT.position + Vector2(34.0, 18.0), 12, Color(0.12, 0.33, 0.08))
	_draw_text("x%d" % plant_food_count, PLANT_FOOD_RECT.position + Vector2(36.0, 37.0), 18, Color(0.12, 0.33, 0.08))


func _draw_wave_bar() -> void:
	draw_rect(WAVE_BAR_RECT, Color(0.18, 0.18, 0.18, 0.34), true)
	draw_rect(WAVE_BAR_RECT, Color(0.18, 0.18, 0.18), false, 2.0)

	var total_events = max(current_level["events"].size(), 1)
	var progress_ratio = clampf(float(next_event_index) / float(total_events), 0.0, 1.0)
	draw_rect(
		Rect2(WAVE_BAR_RECT.position, Vector2(WAVE_BAR_RECT.size.x * progress_ratio, WAVE_BAR_RECT.size.y)),
		Color(0.86, 0.18, 0.18),
		true
	)

	for i in range(current_level["events"].size()):
		var event = current_level["events"][i]
		if not bool(event.get("wave", false)):
			continue
		var flag_ratio = float(i + 1) / float(total_events)
		var x = WAVE_BAR_RECT.position.x + WAVE_BAR_RECT.size.x * flag_ratio
		draw_line(Vector2(x, WAVE_BAR_RECT.position.y - 4.0), Vector2(x, WAVE_BAR_RECT.position.y + WAVE_BAR_RECT.size.y + 4.0), Color(0.22, 0.12, 0.12), 2.0)
		draw_polygon(
			PackedVector2Array([
				Vector2(x, WAVE_BAR_RECT.position.y - 2.0),
				Vector2(x + 12.0, WAVE_BAR_RECT.position.y + 4.0),
				Vector2(x, WAVE_BAR_RECT.position.y + 10.0),
			]),
			PackedColorArray([Color(0.95, 0.18, 0.18), Color(0.95, 0.18, 0.18), Color(0.95, 0.18, 0.18)])
		)

	_draw_text(String(current_level["id"]), WAVE_BAR_RECT.position + Vector2(-54.0, 20.0), 18, Color(0.18, 0.18, 0.18))


func _draw_hover() -> void:
	if battle_state != BATTLE_PLAYING:
		return
	var cell = _mouse_to_cell(get_local_mouse_position())
	if cell.x == -1:
		return

	var rect = _cell_rect(cell.x, cell.y).grow(-5.0)
	var highlight = Color(1.0, 0.96, 0.55, 0.22)
	if selected_tool == "shovel":
		highlight = Color(0.95, 0.3, 0.3, 0.2)
	elif selected_tool == "plant_food":
		highlight = Color(0.24, 0.96, 0.36, 0.2) if grid[cell.x][cell.y] != null else Color(0.95, 0.3, 0.3, 0.2)
	elif selected_tool == "":
		highlight = Color(1.0, 1.0, 1.0, 0.08)
	elif grid[cell.x][cell.y] != null:
		highlight = Color(0.95, 0.3, 0.3, 0.2)
	elif not _is_conveyor_level() and sun_points < int(Defs.PLANTS[selected_tool]["cost"]):
		highlight = Color(0.88, 0.55, 0.12, 0.24)

	draw_rect(rect, highlight, true)

	if selected_tool != "" and selected_tool != "shovel" and selected_tool != "plant_food" and grid[cell.x][cell.y] == null:
		_draw_plant_preview(selected_tool, _cell_center(cell.x, cell.y))


func _draw_plants() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue

			var plant = plant_variant
			var center = _cell_center(row, col)
			var flash = float(plant["flash"])
			if _plant_has_food_power(plant):
				draw_circle(center + Vector2(0.0, -8.0), 34.0, Color(0.2, 0.98, 0.34, 0.14))
				_draw_plant_food_icon(center + Vector2(0.0, -52.0), 0.38)

			match String(plant["kind"]):
				"sunflower":
					_draw_sunflower(center, 1.0, flash)
				"peashooter":
					_draw_peashooter(center, 1.0, flash)
				"snow_pea":
					_draw_snow_pea(center, 1.0, flash)
				"wallnut":
					_draw_wallnut(center, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
				"cherry_bomb":
					_draw_cherry_bomb(center, 1.0, clampf(float(plant["fuse_timer"]) / float(Defs.PLANTS["cherry_bomb"]["fuse"]), 0.0, 1.0))
				"potato_mine":
					_draw_potato_mine(center, 1.0, bool(plant["armed"]), clampf(1.0 - float(plant["arm_timer"]) / float(Defs.PLANTS["potato_mine"]["arm_time"]), 0.0, 1.0))
				"chomper":
					_draw_chomper(center, 1.0, clampf(float(plant["chew_timer"]) / float(Defs.PLANTS["chomper"]["chew_time"]), 0.0, 1.0))
				"repeater":
					_draw_repeater(center, 1.0, flash)
				"amber_shooter":
					_draw_amber_shooter(center, 1.0, flash)
				"vine_lasher":
					_draw_vine_lasher(center, 1.0, flash)
				"pepper_mortar":
					_draw_pepper_mortar(center, 1.0, flash)
				"cactus_guard":
					_draw_cactus_guard(center, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
				"pulse_bulb":
					_draw_pulse_bulb(center, 1.0, flash)
				"sun_bean":
					_draw_sun_bean(center, 1.0, flash)
				"wind_orchid":
					_draw_wind_orchid(center, 1.0, flash)

			if String(plant["kind"]) != "cherry_bomb":
				if float(plant["armor_health"]) > 0.0 and float(plant["max_armor_health"]) > 0.0:
					_draw_health_bar(
						center + Vector2(0.0, -52.0),
						58.0,
						clampf(float(plant["armor_health"]) / float(plant["max_armor_health"]), 0.0, 1.0),
						Color(0.16, 0.96, 0.3)
					)
				_draw_health_bar(
					center + Vector2(0.0, -42.0),
					58.0,
					clampf(float(plant["health"]) / float(plant["max_health"]), 0.0, 1.0),
					Color(0.32, 0.86, 0.24)
				)


func _draw_projectiles() -> void:
	for projectile in projectiles:
		var projectile_pos = Vector2(projectile["position"])
		var projectile_color = Color(projectile["color"])
		var projectile_radius = float(projectile.get("radius", 8.0))
		draw_circle(projectile_pos, projectile_radius, projectile_color)
		draw_circle(projectile_pos + Vector2(-2.0, -2.0), projectile_radius * 0.38, Color(1.0, 1.0, 1.0, 0.5))


func _draw_zombies() -> void:
	for zombie in zombies:
		var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + float(zombie["jump_offset"]))
		_draw_zombie(center, zombie)
		_draw_health_bar(
			center + Vector2(0.0, -56.0),
			58.0,
			clampf(float(zombie["health"]) / float(zombie["max_health"]), 0.0, 1.0),
			Color(0.92, 0.28, 0.22)
		)


func _draw_suns() -> void:
	for sun in suns:
		var center = Vector2(sun["position"])
		for index in range(8):
			var angle = TAU * float(index) / 8.0
			var ray_from = center + Vector2(cos(angle), sin(angle)) * 16.0
			var ray_to = center + Vector2(cos(angle), sin(angle)) * 24.0
			draw_line(ray_from, ray_to, Color(1.0, 0.84, 0.22), 2.0)
		draw_circle(center, 16.0, Color(1.0, 0.94, 0.42))
		draw_circle(center, 8.0, Color(1.0, 0.82, 0.14))


func _draw_coins() -> void:
	for coin in coins:
		_draw_coin_icon(Vector2(coin["position"]), 0.8)


func _draw_lane_obstacles() -> void:
	for weed in weeds:
		var center = Vector2(float(weed["x"]), _row_center_y(int(weed["row"])) + 18.0)
		draw_circle(center, 18.0, Color(0.2, 0.46, 0.14))
		draw_circle(center + Vector2(-10.0, -6.0), 10.0, Color(0.24, 0.56, 0.16))
		draw_circle(center + Vector2(9.0, -4.0), 9.0, Color(0.18, 0.42, 0.12))
		_draw_health_bar(center + Vector2(0.0, -28.0), 44.0, clampf(float(weed["health"]) / float(weed["max_health"]), 0.0, 1.0), Color(0.28, 0.84, 0.22))
	for spear in spears:
		var center = Vector2(float(spear["x"]), _row_center_y(int(spear["row"])) + 10.0)
		draw_line(center + Vector2(0.0, -30.0), center + Vector2(0.0, 24.0), Color(0.45, 0.3, 0.12), 4.0)
		draw_polygon(
			PackedVector2Array([
				center + Vector2(0.0, -40.0),
				center + Vector2(-7.0, -24.0),
				center + Vector2(7.0, -24.0),
			]),
			PackedColorArray([Color(0.76, 0.76, 0.78), Color(0.76, 0.76, 0.78), Color(0.76, 0.76, 0.78)])
		)
		_draw_health_bar(center + Vector2(0.0, -48.0), 36.0, clampf(float(spear["health"]) / float(spear["max_health"]), 0.0, 1.0), Color(0.82, 0.82, 0.86))


func _draw_plant_food_pickups() -> void:
	for pickup in plant_food_pickups:
		_draw_plant_food_icon(Vector2(pickup["position"]), 0.75)


func _draw_rollers() -> void:
	for roller in rollers:
		var center = Vector2(float(roller["x"]), _row_center_y(int(roller["row"])) + 16.0)
		_draw_bowling_nut(center, 0.92, 0.0)


func _draw_effects() -> void:
	for effect in effects:
		var ratio = float(effect["time"]) / float(effect["duration"])
		var radius = float(effect["radius"]) * (1.0 - ratio * 0.35)
		var effect_color = Color(effect["color"])
		effect_color.a *= ratio
		draw_circle(Vector2(effect["position"]), radius, effect_color)


func _draw_mowers() -> void:
	for mower in mowers:
		if not _is_row_active(int(mower["row"])) and not bool(mower["active"]):
			continue
		var center = Vector2(float(mower["x"]), _row_center_y(int(mower["row"])))
		var body_color = Color(0.84, 0.2, 0.16) if bool(mower["armed"]) else Color(0.54, 0.54, 0.54)
		draw_rect(Rect2(center + Vector2(-20.0, -16.0), Vector2(40.0, 24.0)), body_color, true)
		draw_circle(center + Vector2(-11.0, 10.0), 8.0, Color(0.18, 0.18, 0.18))
		draw_circle(center + Vector2(11.0, 10.0), 8.0, Color(0.18, 0.18, 0.18))
		draw_line(center + Vector2(16.0, -12.0), center + Vector2(34.0, -28.0), Color(0.28, 0.28, 0.28), 3.0)


func _draw_card_icon(kind: String, center: Vector2) -> void:
	match kind:
		"peashooter":
			_draw_peashooter(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"sunflower":
			_draw_sunflower(center + Vector2(0.0, 2.0), 0.52, 0.0)
		"cherry_bomb":
			_draw_cherry_bomb(center + Vector2(0.0, 6.0), 0.54, 0.0)
		"wallnut":
			_draw_wallnut(center + Vector2(0.0, 8.0), 0.56, 0.0, 1.0)
		"potato_mine":
			_draw_potato_mine(center + Vector2(0.0, 8.0), 0.56, true, 1.0)
		"snow_pea":
			_draw_snow_pea(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"chomper":
			_draw_chomper(center + Vector2(0.0, 10.0), 0.54, 0.0)
		"repeater":
			_draw_repeater(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"amber_shooter":
			_draw_amber_shooter(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"vine_lasher":
			_draw_vine_lasher(center + Vector2(0.0, 6.0), 0.52, 0.0)
		"pepper_mortar":
			_draw_pepper_mortar(center + Vector2(0.0, 6.0), 0.54, 0.0)
		"cactus_guard":
			_draw_cactus_guard(center + Vector2(0.0, 8.0), 0.54, 0.0, 1.0)
		"pulse_bulb":
			_draw_pulse_bulb(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"sun_bean":
			_draw_sun_bean(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"wind_orchid":
			_draw_wind_orchid(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"wallnut_bowling":
			_draw_bowling_nut(center + Vector2(0.0, 8.0), 0.54, 0.0)


func _draw_plant_preview(kind: String, center: Vector2) -> void:
	match kind:
		"peashooter":
			_draw_peashooter(center, 1.0, 0.0, 0.42)
		"sunflower":
			_draw_sunflower(center, 1.0, 0.0, 0.42)
		"cherry_bomb":
			_draw_cherry_bomb(center, 1.0, 0.0, 0.42)
		"wallnut":
			_draw_wallnut(center, 1.0, 0.0, 1.0, 0.42)
		"potato_mine":
			_draw_potato_mine(center, 1.0, false, 0.0, 0.42)
		"snow_pea":
			_draw_snow_pea(center, 1.0, 0.0, 0.42)
		"chomper":
			_draw_chomper(center, 1.0, 0.0, 0.42)
		"repeater":
			_draw_repeater(center, 1.0, 0.0, 0.42)
		"amber_shooter":
			_draw_amber_shooter(center, 1.0, 0.0, 0.42)
		"vine_lasher":
			_draw_vine_lasher(center, 1.0, 0.0, 0.42)
		"pepper_mortar":
			_draw_pepper_mortar(center, 1.0, 0.0, 0.42)
		"cactus_guard":
			_draw_cactus_guard(center, 1.0, 0.0, 1.0, 0.42)
		"pulse_bulb":
			_draw_pulse_bulb(center, 1.0, 0.0, 0.42)
		"sun_bean":
			_draw_sun_bean(center, 1.0, 0.0, 0.42)
		"wind_orchid":
			_draw_wind_orchid(center, 1.0, 0.0, 0.42)
		"wallnut_bowling":
			_draw_bowling_nut(center, 1.0, 0.0, 0.42)


func _draw_sunflower(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal_color = Color(1.0, 0.84, 0.24, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.2)
	var core_center = center + Vector2(0.0, -8.0 * size_scale)
	for index in range(10):
		var angle = TAU * float(index) / 10.0
		draw_circle(core_center + Vector2(cos(angle), sin(angle)) * 22.0 * size_scale, 9.0 * size_scale, petal_color)
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.18, alpha), 6.0 * size_scale)
	draw_circle(center + Vector2(-12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.28, 0.7, 0.22, alpha))
	draw_circle(center + Vector2(12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.28, 0.7, 0.22, alpha))
	draw_circle(core_center, 17.0 * size_scale, Color(0.43, 0.22, 0.08, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(core_center + Vector2(-5.0 * size_scale, -4.0 * size_scale), 2.4 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_circle(core_center + Vector2(5.0 * size_scale, -4.0 * size_scale), 2.4 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_arc(core_center + Vector2(0.0, 2.0 * size_scale), 6.0 * size_scale, 0.1, PI - 0.1, 12, Color(0.06, 0.06, 0.06, alpha), 2.0 * size_scale)


func _draw_peashooter(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.43, 0.83, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.2)
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 33.0 * size_scale), Color(0.22, 0.53, 0.16, alpha), 7.0 * size_scale)
	draw_circle(center + Vector2(-14.0 * size_scale, 20.0 * size_scale), 8.0 * size_scale, Color(0.27, 0.72, 0.22, alpha))
	draw_circle(center + Vector2(16.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.27, 0.72, 0.22, alpha))
	var head = center + Vector2(-2.0 * size_scale, -10.0 * size_scale)
	draw_circle(head, 20.0 * size_scale, body_color)
	draw_circle(head + Vector2(24.0 * size_scale, 0.0), 11.0 * size_scale, body_color.darkened(0.06))
	draw_circle(head + Vector2(31.0 * size_scale, 0.0), 4.0 * size_scale, Color(0.2, 0.45, 0.14, alpha))
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(0.05, 0.05, 0.05, alpha))
	draw_circle(head + Vector2(-10.0 * size_scale, 10.0 * size_scale), 10.0 * size_scale, Color(0.24, 0.66, 0.2, alpha))


func _draw_snow_pea(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.58, 0.88, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.2)
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 33.0 * size_scale), Color(0.22, 0.53, 0.16, alpha), 7.0 * size_scale)
	draw_circle(center + Vector2(-14.0 * size_scale, 20.0 * size_scale), 8.0 * size_scale, Color(0.34, 0.77, 0.78, alpha))
	draw_circle(center + Vector2(16.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.34, 0.77, 0.78, alpha))
	var head = center + Vector2(-2.0 * size_scale, -10.0 * size_scale)
	draw_circle(head, 20.0 * size_scale, body_color)
	draw_circle(head + Vector2(24.0 * size_scale, 0.0), 11.0 * size_scale, body_color.darkened(0.06))
	draw_circle(head + Vector2(31.0 * size_scale, 0.0), 4.0 * size_scale, Color(0.26, 0.54, 0.7, alpha))
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(0.05, 0.05, 0.05, alpha))
	draw_circle(head + Vector2(-10.0 * size_scale, 10.0 * size_scale), 10.0 * size_scale, Color(0.4, 0.82, 0.9, alpha))


func _draw_repeater(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	_draw_peashooter(center + Vector2(-6.0 * size_scale, 0.0), size_scale, flash, alpha)
	var extra_head = center + Vector2(18.0 * size_scale, -14.0 * size_scale)
	draw_circle(extra_head, 11.0 * size_scale, Color(0.35, 0.74, 0.25, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(extra_head + Vector2(14.0 * size_scale, 0.0), 5.0 * size_scale, Color(0.2, 0.45, 0.14, alpha))


func _draw_amber_shooter(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	_draw_peashooter(center, size_scale, flash, alpha)
	draw_circle(center + Vector2(-2.0 * size_scale, -12.0 * size_scale), 10.0 * size_scale, Color(0.92, 0.68, 0.24, alpha))


func _draw_vine_lasher(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.53, 0.16, alpha), 7.0 * size_scale)
	draw_circle(center + Vector2(0.0, -10.0 * size_scale), 16.0 * size_scale, Color(0.28, 0.74, 0.24, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_line(center + Vector2(-14.0 * size_scale, -6.0 * size_scale), center + Vector2(18.0 * size_scale, -18.0 * size_scale), Color(0.18, 0.58, 0.14, alpha), 4.0 * size_scale)
	draw_circle(center + Vector2(20.0 * size_scale, -19.0 * size_scale), 5.0 * size_scale, Color(0.58, 0.92, 0.42, alpha))


func _draw_pepper_mortar(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(0.0, 10.0 * size_scale), 19.0 * size_scale, Color(0.7, 0.18, 0.12, alpha))
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), 15.0 * size_scale, Color(0.96, 0.5, 0.2, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_rect(Rect2(center + Vector2(-18.0 * size_scale, 2.0 * size_scale), Vector2(36.0 * size_scale, 12.0 * size_scale)), Color(0.48, 0.24, 0.08, alpha), true)


func _draw_cactus_guard(center: Vector2, size_scale: float, flash: float, ratio: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(0.0, 8.0 * size_scale), 24.0 * size_scale, Color(0.24, 0.72, 0.22, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(-10.0 * size_scale, -4.0 * size_scale), 8.0 * size_scale, Color(0.3, 0.78, 0.28, alpha))
	draw_circle(center + Vector2(10.0 * size_scale, -6.0 * size_scale), 8.0 * size_scale, Color(0.3, 0.78, 0.28, alpha))
	draw_line(center + Vector2(-16.0 * size_scale, 2.0 * size_scale), center + Vector2(-24.0 * size_scale, -8.0 * size_scale), Color(0.92, 0.88, 0.68, alpha), 2.0 * size_scale)
	draw_line(center + Vector2(16.0 * size_scale, 2.0 * size_scale), center + Vector2(24.0 * size_scale, -8.0 * size_scale), Color(0.92, 0.88, 0.68, alpha), 2.0 * size_scale)
	if ratio < 0.45:
		draw_line(center + Vector2(-6.0 * size_scale, -16.0 * size_scale), center + Vector2(8.0 * size_scale, 14.0 * size_scale), Color(0.18, 0.42, 0.14, alpha), 2.0 * size_scale)


func _draw_pulse_bulb(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), 18.0 * size_scale, Color(0.98, 0.92, 0.34, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), 9.0 * size_scale, Color(1.0, 0.72, 0.12, alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.18, alpha), 6.0 * size_scale)


func _draw_sun_bean(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(-6.0 * size_scale, -6.0 * size_scale), 12.0 * size_scale, Color(0.98, 0.82, 0.24, alpha))
	draw_circle(center + Vector2(8.0 * size_scale, -2.0 * size_scale), 12.0 * size_scale, Color(0.92, 0.72, 0.2, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.18, alpha), 6.0 * size_scale)


func _draw_wind_orchid(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.18, alpha), 6.0 * size_scale)
	for index in range(4):
		var angle = TAU * float(index) / 4.0 + 0.2
		draw_circle(center + Vector2(cos(angle), sin(angle)) * 14.0 * size_scale, 9.0 * size_scale, Color(0.74, 0.92, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))


func _draw_bowling_nut(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	_draw_wallnut(center, size_scale, flash, 1.0, alpha)
	draw_line(center + Vector2(-18.0 * size_scale, 10.0 * size_scale), center + Vector2(18.0 * size_scale, 10.0 * size_scale), Color(0.82, 0.16, 0.16, alpha), 4.0 * size_scale)


func _draw_wallnut(center: Vector2, size_scale: float, flash: float, ratio: float, alpha: float = 1.0) -> void:
	var shell_color = Color(0.61, 0.38, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 6.0 * size_scale), 28.0 * size_scale, shell_color)
	draw_circle(center + Vector2(-7.0 * size_scale, 2.0 * size_scale), 3.0 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_circle(center + Vector2(7.0 * size_scale, 2.0 * size_scale), 3.0 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_arc(center + Vector2(0.0, 11.0 * size_scale), 7.0 * size_scale, 0.15, PI - 0.15, 12, Color(0.06, 0.06, 0.06, alpha), 2.0 * size_scale)
	if ratio < 0.68:
		draw_line(center + Vector2(-4.0 * size_scale, -20.0 * size_scale), center + Vector2(4.0 * size_scale, -3.0 * size_scale), Color(0.35, 0.19, 0.08, alpha), 2.0 * size_scale)
	if ratio < 0.34:
		draw_line(center + Vector2(10.0 * size_scale, -14.0 * size_scale), center + Vector2(-6.0 * size_scale, 8.0 * size_scale), Color(0.35, 0.19, 0.08, alpha), 2.0 * size_scale)
		draw_line(center + Vector2(-16.0 * size_scale, -4.0 * size_scale), center + Vector2(-2.0 * size_scale, 12.0 * size_scale), Color(0.35, 0.19, 0.08, alpha), 2.0 * size_scale)


func _draw_cherry_bomb(center: Vector2, size_scale: float, fuse_ratio: float, alpha: float = 1.0) -> void:
	var left = center + Vector2(-12.0 * size_scale, -2.0 * size_scale)
	var right = center + Vector2(12.0 * size_scale, -4.0 * size_scale)
	draw_circle(left, 16.0 * size_scale, Color(0.88, 0.12, 0.18, alpha))
	draw_circle(right, 16.0 * size_scale, Color(0.93, 0.16, 0.22, alpha))
	draw_line(center + Vector2(0.0, 6.0 * size_scale), center + Vector2(0.0, 28.0 * size_scale), Color(0.22, 0.5, 0.16, alpha), 6.0 * size_scale)
	draw_line(left + Vector2(2.0 * size_scale, -16.0 * size_scale), left + Vector2(10.0 * size_scale, -28.0 * size_scale), Color(0.28, 0.46, 0.16, alpha), 3.0 * size_scale)
	draw_line(right + Vector2(-2.0 * size_scale, -16.0 * size_scale), right + Vector2(8.0 * size_scale, -26.0 * size_scale), Color(0.28, 0.46, 0.16, alpha), 3.0 * size_scale)
	draw_line(center + Vector2(4.0 * size_scale, -18.0 * size_scale), center + Vector2(14.0 * size_scale, -30.0 * size_scale), Color(0.2, 0.2, 0.2, alpha), 2.0 * size_scale)
	var spark_color = Color(1.0, 0.92, 0.28, alpha)
	if fuse_ratio > 0.0:
		spark_color = spark_color.lerp(Color(1.0, 0.22, 0.16, alpha), 1.0 - clampf(fuse_ratio, 0.0, 1.0))
	draw_circle(center + Vector2(16.0 * size_scale, -32.0 * size_scale), 5.0 * size_scale, spark_color)


func _draw_potato_mine(center: Vector2, size_scale: float, armed: bool, arm_ratio: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.63, 0.45, 0.2, alpha)
	if armed:
		body_color = Color(0.78, 0.56, 0.23, alpha)
	draw_circle(center + Vector2(0.0, 14.0 * size_scale), 23.0 * size_scale, body_color)
	draw_circle(center + Vector2(-7.0 * size_scale, 10.0 * size_scale), 2.5 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_circle(center + Vector2(7.0 * size_scale, 10.0 * size_scale), 2.5 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_line(center + Vector2(-12.0 * size_scale, 28.0 * size_scale), center + Vector2(-24.0 * size_scale, 38.0 * size_scale), Color(0.2, 0.46, 0.14, alpha), 3.0 * size_scale)
	draw_line(center + Vector2(12.0 * size_scale, 28.0 * size_scale), center + Vector2(24.0 * size_scale, 38.0 * size_scale), Color(0.2, 0.46, 0.14, alpha), 3.0 * size_scale)
	if armed:
		draw_circle(center + Vector2(0.0, -2.0 * size_scale), 7.0 * size_scale, Color(0.95, 0.24, 0.18, alpha))
	else:
		draw_arc(center + Vector2(0.0, 16.0 * size_scale), 10.0 * size_scale, 0.2, PI - 0.2, 12, Color(0.06, 0.06, 0.06, alpha), 2.0 * size_scale)
		draw_rect(Rect2(center + Vector2(-18.0 * size_scale, -18.0 * size_scale), Vector2(36.0 * size_scale * arm_ratio, 4.0 * size_scale)), Color(1.0, 0.84, 0.24, alpha), true)


func _draw_chomper(center: Vector2, size_scale: float, chew_ratio: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.53, 0.16, alpha), 7.0 * size_scale)
	draw_circle(center + Vector2(-14.0 * size_scale, 20.0 * size_scale), 8.0 * size_scale, Color(0.32, 0.72, 0.24, alpha))
	draw_circle(center + Vector2(16.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.32, 0.72, 0.24, alpha))
	var head = center + Vector2(0.0, -6.0 * size_scale)
	draw_circle(head, 18.0 * size_scale, Color(0.64, 0.2, 0.48, alpha))
	draw_circle(head + Vector2(14.0 * size_scale, 2.0 * size_scale), 14.0 * size_scale, Color(0.72, 0.28, 0.56, alpha))
	draw_circle(head + Vector2(11.0 * size_scale, -4.0 * size_scale), 3.0 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_line(head + Vector2(16.0 * size_scale, 12.0 * size_scale), head + Vector2(24.0 * size_scale, 24.0 * size_scale), Color(0.86, 0.92, 0.9, alpha), 4.0 * size_scale)
	if chew_ratio > 0.0:
		draw_rect(Rect2(head + Vector2(-18.0 * size_scale, -26.0 * size_scale), Vector2(40.0 * size_scale * chew_ratio, 4.0 * size_scale)), Color(1.0, 0.82, 0.22, alpha), true)


func _draw_plant_food_icon(center: Vector2, size_scale: float) -> void:
	draw_circle(center, 16.0 * size_scale, Color(0.18, 0.76, 0.18, 0.18))
	draw_circle(center + Vector2(-4.5 * size_scale, -2.0 * size_scale), 7.0 * size_scale, Color(0.34, 0.92, 0.24))
	draw_circle(center + Vector2(4.5 * size_scale, 2.0 * size_scale), 7.0 * size_scale, Color(0.24, 0.78, 0.18))
	draw_circle(center, 8.0 * size_scale, Color(0.42, 0.98, 0.3))
	draw_line(center + Vector2(-4.0 * size_scale, -5.0 * size_scale), center + Vector2(4.0 * size_scale, 5.0 * size_scale), Color(0.82, 1.0, 0.68), 2.0 * size_scale)


func _draw_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie["flash"])
	var slow_tint = 0.55 if float(zombie["slow_timer"]) > 0.0 else 0.0
	if bool(zombie.get("plant_food_carrier", false)):
		draw_circle(center + Vector2(0.0, -24.0), 30.0, Color(0.18, 0.92, 0.26, 0.16))
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 2.0).lerp(Color(0.64, 0.84, 1.0), slow_tint)
	var shirt = Color(0.26, 0.39, 0.67).lerp(Color(1.0, 1.0, 1.0), flash * 2.0).lerp(Color(0.46, 0.64, 0.9), slow_tint)
	draw_line(center + Vector2(-8.0, 24.0), center + Vector2(-14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_line(center + Vector2(8.0, 24.0), center + Vector2(14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_rect(Rect2(center + Vector2(-16.0, -10.0), Vector2(32.0, 38.0)), shirt, true)
	draw_line(center + Vector2(-10.0, 0.0), center + Vector2(-24.0, 8.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(center + Vector2(10.0, 0.0), center + Vector2(24.0, 8.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_circle(center + Vector2(0.0, -28.0), 17.0, skin)
	draw_circle(center + Vector2(-6.0, -30.0), 2.4, Color.BLACK)
	draw_circle(center + Vector2(6.0, -30.0), 2.4, Color.BLACK)

	match String(zombie["kind"]):
		"flag":
			draw_line(center + Vector2(18.0, -8.0), center + Vector2(18.0, -50.0), Color(0.24, 0.24, 0.24), 3.0)
			draw_polygon(
				PackedVector2Array([
					center + Vector2(18.0, -48.0),
					center + Vector2(42.0, -40.0),
					center + Vector2(18.0, -28.0),
				]),
				PackedColorArray([
					Color(0.95, 0.16, 0.16),
					Color(0.95, 0.16, 0.16),
					Color(0.95, 0.16, 0.16),
				])
			)
		"conehead":
			draw_polygon(
				PackedVector2Array([
					center + Vector2(0.0, -62.0),
					center + Vector2(-16.0, -10.0),
					center + Vector2(16.0, -10.0),
				]),
				PackedColorArray([
					Color(0.95, 0.54, 0.15),
					Color(0.95, 0.54, 0.15),
					Color(0.95, 0.54, 0.15),
				])
			)
		"buckethead":
			draw_rect(Rect2(center + Vector2(-17.0, -54.0), Vector2(34.0, 24.0)), Color(0.62, 0.62, 0.66), true)
			draw_rect(Rect2(center + Vector2(-20.0, -60.0), Vector2(40.0, 8.0)), Color(0.72, 0.72, 0.76), true)
		"pole_vault":
			if not bool(zombie["has_vaulted"]) or bool(zombie["jumping"]):
				draw_line(center + Vector2(-28.0, -42.0), center + Vector2(34.0, -60.0), Color(0.54, 0.38, 0.18), 4.0)
		"farmer":
			draw_rect(Rect2(center + Vector2(-19.0, -50.0), Vector2(38.0, 18.0)), Color(0.78, 0.68, 0.24), true)
			draw_line(center + Vector2(-14.0, -8.0), center + Vector2(14.0, -22.0), Color(0.34, 0.24, 0.12), 3.0)
		"spear":
			draw_line(center + Vector2(-26.0, -14.0), center + Vector2(30.0, -34.0), Color(0.54, 0.38, 0.18), 4.0)
			draw_polygon(
				PackedVector2Array([
					center + Vector2(30.0, -34.0),
					center + Vector2(20.0, -28.0),
					center + Vector2(22.0, -40.0),
				]),
				PackedColorArray([Color(0.82, 0.82, 0.84), Color(0.82, 0.82, 0.84), Color(0.82, 0.82, 0.84)])
			)
		"kungfu":
			draw_rect(Rect2(center + Vector2(-18.0, -12.0), Vector2(36.0, 40.0)), Color(0.72, 0.18, 0.12), true)
			draw_rect(Rect2(center + Vector2(-18.0, -52.0), Vector2(36.0, 12.0)), Color(0.12, 0.12, 0.14), true)
			if float(zombie.get("reflect_timer", 0.0)) > 0.0:
				draw_circle(center + Vector2(0.0, -18.0), 34.0, Color(0.66, 0.9, 1.0, 0.18))
		"day_boss":
			draw_rect(Rect2(center + Vector2(-34.0, -28.0), Vector2(68.0, 68.0)), Color(0.42, 0.18, 0.12), true)
			draw_rect(Rect2(center + Vector2(-40.0, -58.0), Vector2(80.0, 20.0)), Color(0.78, 0.52, 0.12), true)
			draw_circle(center + Vector2(0.0, -46.0), 22.0, Color(0.82, 0.84, 0.74))
			draw_circle(center + Vector2(0.0, -46.0), 28.0, Color(1.0, 0.42, 0.22, 0.1))

	if bool(zombie.get("plant_food_carrier", false)):
		_draw_plant_food_icon(center + Vector2(0.0, -56.0), 0.46)


func _draw_shovel_icon(center: Vector2) -> void:
	draw_line(center + Vector2(-10.0, -18.0), center + Vector2(18.0, 18.0), Color(0.47, 0.3, 0.12), 6.0)
	draw_circle(center + Vector2(22.0, 22.0), 12.0, Color(0.55, 0.55, 0.58))
	draw_rect(Rect2(center + Vector2(8.0, 10.0), Vector2(28.0, 16.0)), Color(0.66, 0.66, 0.7), true)


func _draw_coin_icon(center: Vector2, size_scale: float) -> void:
	draw_circle(center, 14.0 * size_scale, Color(0.98, 0.86, 0.24))
	draw_circle(center, 10.0 * size_scale, Color(1.0, 0.95, 0.54))
	draw_circle(center, 14.0 * size_scale, Color(0.62, 0.46, 0.08), false, 2.0 * size_scale)
	_draw_text("C", center + Vector2(-6.0 * size_scale, 6.0 * size_scale), int(20 * size_scale), Color(0.56, 0.36, 0.04))


func _draw_health_bar(center: Vector2, width: float, ratio: float, fill_color: Color) -> void:
	var bar_rect = Rect2(center + Vector2(-width * 0.5, 0.0), Vector2(width, 6.0))
	draw_rect(bar_rect, Color(0.0, 0.0, 0.0, 0.3), true)
	draw_rect(Rect2(bar_rect.position, Vector2(width * clampf(ratio, 0.0, 1.0), 6.0)), fill_color, true)


func _draw_rect_full(fill_color: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), fill_color, true)


func _draw_text(text: String, text_pos: Vector2, font_size: int, text_color: Color) -> void:
	draw_string(ui_font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_color)


func _toggle_plant_food_tool() -> void:
	if plant_food_count <= 0:
		_show_toast("还没有收集到能量豆")
		return
	selected_tool = "" if selected_tool == "plant_food" else "plant_food"
	queue_redraw()


func _plant_has_food_power(plant: Dictionary) -> bool:
	return String(plant["plant_food_mode"]) != "" or float(plant.get("armor_health", 0.0)) > 0.0


func _activate_plant_food(row: int, col: int) -> bool:
	var plant_variant = grid[row][col]
	if plant_variant == null:
		return false

	var plant = plant_variant
	var center = _cell_center(row, col)
	var kind = String(plant["kind"])
	match kind:
		"peashooter":
			if String(plant["plant_food_mode"]) == "pea_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "pea_storm"
			plant["plant_food_timer"] = 2.5
			plant["plant_food_interval"] = 0.01
		"amber_shooter":
			if String(plant["plant_food_mode"]) == "pea_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "pea_storm"
			plant["plant_food_timer"] = 2.8
			plant["plant_food_interval"] = 0.01
		"sunflower":
			plant["plant_food_mode"] = "sun_burst"
			plant["plant_food_timer"] = 0.7
			plant["plant_food_interval"] = 0.0
			for index in range(3):
				var angle = -0.6 + float(index) * 0.6
				var offset = Vector2(cos(angle), sin(angle)) * 26.0
				_spawn_sun(center + offset, center.y - 20.0 + offset.y * 0.2, "plant_food")
		"cherry_bomb":
			if float(plant["fuse_timer"]) <= 0.05:
				return false
			plant["plant_food_mode"] = "mega_bomb"
			plant["plant_food_timer"] = minf(float(plant["fuse_timer"]), 0.18)
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.18)
		"wallnut":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 8000.0
			plant["max_armor_health"] = 8000.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"potato_mine":
			plant["armed"] = true
			plant["arm_timer"] = 0.0
			plant["plant_food_mode"] = "mine_burst"
			plant["plant_food_timer"] = 0.7
			_spawn_bonus_potato_mines(row, col, 2)
		"snow_pea":
			if String(plant["plant_food_mode"]) == "ice_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "ice_storm"
			plant["plant_food_timer"] = 2.5
			plant["plant_food_interval"] = 0.01
			for i in range(zombies.size()):
				var zombie = zombies[i]
				if int(zombie["row"]) == row and float(zombie["x"]) >= center.x - 20.0:
					zombie["slow_timer"] = maxf(float(zombie["slow_timer"]), 16.0)
					zombie["flash"] = maxf(float(zombie["flash"]), 0.12)
					zombies[i] = zombie
		"chomper":
			plant["plant_food_mode"] = "chomp_frenzy"
			plant["plant_food_timer"] = 0.85
			plant["chew_timer"] = 0.0
			var eaten = 0
			var targets = _find_closest_lane_zombies(row, center.x, 3, 300.0)
			for zombie_index in targets:
				var zombie = zombies[zombie_index]
				zombie["health"] = 0.0
				zombie["flash"] = 0.25
				zombies[zombie_index] = zombie
				eaten += 1
			if eaten <= 0:
				plant["plant_food_timer"] = 0.45
		"repeater":
			if String(plant["plant_food_mode"]) == "double_storm" and (float(plant["plant_food_timer"]) > 0.0 or int(plant["plant_food_charges"]) > 0):
				return false
			plant["plant_food_mode"] = "double_storm"
			plant["plant_food_timer"] = 2.7
			plant["plant_food_interval"] = 0.01
			plant["plant_food_charges"] = 1
		"vine_lasher":
			plant["plant_food_mode"] = "lash_frenzy"
			plant["plant_food_timer"] = 0.6
			for zombie_index in _find_closest_lane_zombies(row, center.x, 3, 180.0):
				var zombie = zombies[zombie_index]
				zombie["health"] -= 120.0
				zombie["slow_timer"] = maxf(float(zombie["slow_timer"]), 4.0)
				zombie["flash"] = 0.2
				zombies[zombie_index] = zombie
		"pepper_mortar":
			plant["plant_food_mode"] = "mortar_burst"
			plant["plant_food_timer"] = 0.4
			_damage_zombies_in_radius(row, center.x + 130.0, 210.0, 110.0)
			effects.append({
				"position": center + Vector2(130.0, 0.0),
				"radius": 180.0,
				"time": 0.4,
				"duration": 0.4,
				"color": Color(1.0, 0.36, 0.14, 0.5),
			})
		"cactus_guard":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 4200.0
			plant["max_armor_health"] = 4200.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		"pulse_bulb":
			plant["plant_food_mode"] = "pulse_burst"
			plant["plant_food_timer"] = 0.4
			for i in range(zombies.size()):
				var zombie = zombies[i]
				if int(zombie["row"]) == row:
					zombie["health"] -= 120.0
					zombie["flash"] = 0.2
					zombies[i] = zombie
		"sun_bean":
			plant["plant_food_mode"] = "sun_burst"
			plant["plant_food_timer"] = 0.7
			plant["plant_food_interval"] = 0.0
			for index in range(4):
				var angle = -0.8 + float(index) * 0.5
				var offset = Vector2(cos(angle), sin(angle)) * 28.0
				_spawn_sun(center + offset, center.y - 20.0 + offset.y * 0.2, "plant_food")
		"wind_orchid":
			plant["plant_food_mode"] = "gust_burst"
			plant["plant_food_timer"] = 0.6
			for lane in range(ROWS):
				if not _is_row_active(lane):
					continue
				for i in range(zombies.size()):
					var zombie = zombies[i]
					if int(zombie["row"]) != lane:
						continue
					zombie["x"] += 120.0
					zombie["flash"] = 0.16
					zombies[i] = zombie
				for i in range(weeds.size() - 1, -1, -1):
					if int(weeds[i]["row"]) == lane:
						weeds.remove_at(i)
				for i in range(spears.size() - 1, -1, -1):
					if int(spears[i]["row"]) == lane:
						spears.remove_at(i)
		_:
			return false

	plant["flash"] = maxf(float(plant["flash"]), 0.22)
	grid[row][col] = plant
	effects.append({
		"position": center,
		"radius": 72.0,
		"time": 0.3,
		"duration": 0.3,
		"color": Color(0.22, 1.0, 0.34, 0.34),
	})
	_show_toast("%s 大招启动" % Defs.PLANTS[kind]["name"])
	return true


func _spawn_bonus_potato_mines(origin_row: int, origin_col: int, amount: int) -> void:
	var candidates: Array = []
	for row in range(ROWS):
		if not _is_row_active(row):
			continue
		for col in range(COLS):
			if row == origin_row and col == origin_col:
				continue
			if grid[row][col] != null:
				continue
			candidates.append(Vector2i(row, col))

	for i in range(min(amount, candidates.size())):
		var pick_index = rng.randi_range(0, candidates.size() - 1)
		var cell: Vector2i = candidates[pick_index]
		candidates.remove_at(pick_index)
		var bonus_mine = _create_plant("potato_mine", cell.x, cell.y)
		bonus_mine["armed"] = true
		bonus_mine["arm_timer"] = 0.0
		bonus_mine["flash"] = 0.18
		grid[cell.x][cell.y] = bonus_mine


func _find_closest_lane_zombies(row: int, plant_x: float, count: int, range_limit: float) -> Array:
	var candidates: Array = []
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie["jumping"]):
			continue
		var distance = absf(float(zombie["x"]) - plant_x)
		if distance > range_limit:
			continue
		candidates.append({"index": i, "distance": distance})

	var result: Array = []
	while result.size() < count and not candidates.is_empty():
		var best_pick = 0
		var best_distance = float(candidates[0]["distance"])
		for i in range(1, candidates.size()):
			var candidate_distance = float(candidates[i]["distance"])
			if candidate_distance < best_distance:
				best_distance = candidate_distance
				best_pick = i
		result.append(int(candidates[best_pick]["index"]))
		candidates.remove_at(best_pick)
	return result


func _mark_save_dirty(immediate: bool = false) -> void:
	save_dirty = true
	autosave_timer = 0.0 if immediate else 0.5


func _update_autosave(delta: float) -> void:
	if not save_dirty:
		return
	autosave_timer = maxf(0.0, autosave_timer - delta)
	if autosave_timer <= 0.0:
		_save_game()


func _save_game() -> void:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		return

	var save_data = {
		"version": 1,
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"coins_total": coins_total,
		"last_level_index": selected_level_index,
	}
	save_file.store_string(JSON.stringify(save_data))
	save_dirty = false


func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return false

	var parsed = JSON.parse_string(save_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var save_data: Dictionary = parsed
	unlocked_levels = clampi(int(save_data.get("unlocked_levels", 1)), 1, Defs.LEVELS.size())
	coins_total = max(0, int(save_data.get("coins_total", 0)))
	selected_level_index = clampi(int(save_data.get("last_level_index", -1)), -1, Defs.LEVELS.size() - 1)

	var saved_completed = save_data.get("completed_levels", [])
	if not (saved_completed is Array):
		saved_completed = []
	completed_levels.resize(Defs.LEVELS.size())
	for i in range(completed_levels.size()):
		completed_levels[i] = bool(saved_completed[i]) if i < saved_completed.size() else false

	for i in range(completed_levels.size()):
		if bool(completed_levels[i]):
			unlocked_levels = max(unlocked_levels, min(i + 2, Defs.LEVELS.size()))

	return true
