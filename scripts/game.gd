extends Control

const Defs = preload("res://scripts/game_defs.gd")
const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const WindowModeLib = preload("res://scripts/system/window_mode.gd")
const WorldDataLib = preload("res://scripts/data/world_data.gd")
const AlmanacTextLib = preload("res://scripts/data/almanac_text.gd")

const ROWS := 6
const COLS := 9
const DEFAULT_BOARD_ROWS := 5

const MODE_WORLD_SELECT := "world_select"
const MODE_MAP := "map"
const MODE_ALMANAC := "almanac"
const MODE_SELECTION := "selection"
const MODE_BATTLE := "battle"

const BATTLE_PLAYING := "playing"
const BATTLE_WON := "won"
const BATTLE_LOST := "lost"

const BOARD_ORIGIN := Vector2(250.0, 160.0)
const CELL_SIZE := Vector2(98.0, 110.0)

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
const PREP_POOL_COLUMNS := 6
const PREP_POOL_STEP := Vector2(110.0, 118.0)
const MAP_ALMANAC_BUTTON_RECT := Rect2(1190.0, 64.0, 100.0, 40.0)
const MAP_WORLD_BACK_RECT := Rect2(892.0, 64.0, 108.0, 40.0)
const ALMANAC_BOOK_RECT := Rect2(74.0, 94.0, 1148.0, 614.0)
const ALMANAC_CLOSE_RECT := Rect2(1098.0, 114.0, 96.0, 40.0)
const ALMANAC_PLANT_TAB_RECT := Rect2(116.0, 114.0, 112.0, 44.0)
const ALMANAC_ZOMBIE_TAB_RECT := Rect2(236.0, 114.0, 112.0, 44.0)
const ALMANAC_LIST_RECT := Rect2(108.0, 176.0, 404.0, 494.0)
const ALMANAC_DETAIL_RECT := Rect2(530.0, 176.0, 648.0, 494.0)
const ALMANAC_GRID_COLUMNS := 4
const ALMANAC_GRID_STEP := Vector2(94.0, 118.0)
const WORLD_SELECT_ARROW_LEFT_RECT := Rect2(74.0, 390.0, 58.0, 150.0)
const WORLD_SELECT_ARROW_RIGHT_RECT := Rect2(1468.0, 390.0, 58.0, 150.0)
const WORLD_SELECT_ENTER_RECT := Rect2(1180.0, 732.0, 236.0, 62.0)
const WORLD_SELECT_ALMANAC_RECT := Rect2(924.0, 732.0, 236.0, 62.0)
const MAP_VIEW_RECT := Rect2(120.0, 138.0, 716.0, 548.0)
const MAP_SCROLL_LEFT_RECT := Rect2(1080.0, 32.0, 44.0, 44.0)
const MAP_SCROLL_RIGHT_RECT := Rect2(1132.0, 32.0, 44.0, 44.0)

const RUMIA_FRAME_COUNT := 8
const CIRNO_FRAME_COUNT := 8
const DAIYOUSEI_FRAME_COUNT := 8

static var shared_audio_stream_cache := {}
static var shared_rumia_frames: Array = []
static var shared_rumia_frames_loaded := false
static var shared_rumia_frames_face_left = null
static var shared_cirno_frames: Array = []
static var shared_cirno_frames_loaded := false
static var shared_cirno_frames_face_left = null
static var shared_daiyousei_frames: Array = []
static var shared_daiyousei_frames_loaded := false
static var shared_daiyousei_frames_face_left = null

const ZOMBIE_ALMANAC_ORDER := [
	"normal",
	"flag",
	"conehead",
	"pole_vault",
	"buckethead",
	"newspaper",
	"screen_door",
	"football",
	"dark_football",
	"dancing",
	"backup_dancer",
	"ninja",
	"basketball",
	"nezha",
	"nether",
	"lifebuoy_normal",
	"lifebuoy_cone",
	"lifebuoy_bucket",
	"snorkel",
	"zomboni",
	"bobsled_team",
	"dolphin_rider",
	"dragon_boat",
	"qinghua",
	"shouyue",
	"ice_block",
	"dragon_dance",
	"farmer",
	"spear",
	"kungfu",
	"day_boss",
	"night_boss",
	"pool_boss",
	"rumia_boss",
	"daiyousei_boss",
	"cirno_boss",
]

var rng = RandomNumberGenerator.new()
var ui_font: SystemFont

var mode := MODE_WORLD_SELECT
var battle_state := BATTLE_PLAYING
var panel_action := ""
var board_rows := DEFAULT_BOARD_ROWS
var board_size := Vector2(COLS * CELL_SIZE.x, DEFAULT_BOARD_ROWS * CELL_SIZE.y)

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
var base_events_spawned := 0
var total_spawned_units := 0
var expected_spawn_units := 1
var pending_grave_wave_spawns := 0
var grave_wave_triggered := false
var level_time := 0.0
var sky_sun_cooldown := 0.0
var batch_spawn_remaining := 0
var batch_spawn_queue: Array = []
var spawn_director_timer := 0.0
var selected_tool := ""
var sun_points := 0
var plant_food_count := 0
var total_kills := 0
var selection_cards: Array = []
var selection_pool_cards: Array = []
var selection_pool_scroll := 0.0
var almanac_tab := "plants"
var almanac_selected_kind := ""
var almanac_scroll := 0.0
var almanac_return_mode := MODE_WORLD_SELECT
var current_world_key := "day"
var world_select_index := 0
var world_select_scroll := 0.0
var page_transition_active := false
var page_transition_from_mode := ""
var page_transition_to_mode := ""
var page_transition_target_world := ""
var page_transition_progress := 0.0
var page_transition_direction := 1
var map_scroll_by_world := {}
var map_scroll_target_by_world := {}

var grid: Array = []
var support_grid: Array = []
var cell_terrain_mask: Array = []
var zombies: Array = []
var next_zombie_uid := 1
var projectiles: Array = []
var suns: Array = []
var coins: Array = []
var plant_food_pickups: Array = []
var rollers: Array = []
var weeds: Array = []
var spears: Array = []
var graves: Array = []
var porcelain_shards: Array = []
var water_rows: Array = []
var ice_tiles: Array = []
var mowers: Array = []
var effects: Array = []
var card_cooldowns := {}
var save_dirty := false
var autosave_timer := 0.0

var toast_timer := 0.0
var banner_timer := 0.0
var ui_time := 0.0

var toast_label: Label
var banner_label: Label
var message_panel: PanelContainer
var message_label: Label
var action_button: Button
var overlay_panel_style: StyleBoxFlat
var overlay_button_style: StyleBoxFlat
var music_player: AudioStreamPlayer
var current_bgm_path := ""
var audio_stream_cache := {}
var rumia_frames: Array = []
var rumia_frames_loaded := false
var rumia_frames_face_left = null
var cirno_frames: Array = []
var cirno_frames_loaded := false
var cirno_frames_face_left = null
var daiyousei_frames: Array = []
var daiyousei_frames_loaded := false
var daiyousei_frames_face_left = null
var frozen_branch_midboss_spawned := false
var frozen_branch_midboss_cleared := false
var frozen_branch_progress_locked := false
var frozen_branch_final_boss_spawned := false
var frozen_branch_locked_progress := -1.0
var frozen_branch_post_freeze_cards: Array = []
var frozen_branch_freeze_visual_t := 1.0
var frozen_branch_freeze_visual_duration := 0.85
var frozen_branch_freeze_visual_active := false


func _ready() -> void:
	rng.randomize()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_font()
	_build_overlay_ui()
	_build_audio_player()
	_init_campaign()
	call_deferred("_apply_display_mode")
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if save_dirty:
			_save_game()


func _process(delta: float) -> void:
	ui_time += delta
	_update_overlay_timers(delta)
	_update_autosave(delta)
	_update_page_transition(delta)
	_update_freeze_transition_visual(delta)
	world_select_scroll = lerpf(world_select_scroll, float(world_select_index), min(1.0, delta * 7.5))

	if page_transition_active:
		queue_redraw()
		return

	if mode == MODE_WORLD_SELECT:
		map_time += delta
		queue_redraw()
		return

	if mode == MODE_MAP:
		map_time += delta
		_update_map_scroll(delta)
		hovered_level_index = _level_node_at(get_local_mouse_position())
		queue_redraw()
		return

	if mode == MODE_ALMANAC:
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
	if not _is_night_level() and sky_sun_cooldown <= 0.0:
		var sky_range = current_level["sky_sun_range"]
		_spawn_sun(
			Vector2(
				rng.randf_range(BOARD_ORIGIN.x + 30.0, BOARD_ORIGIN.x + board_size.x - 30.0),
				80.0
			),
			_random_active_target_y(),
			"sky"
		)
		sky_sun_cooldown = rng.randf_range(sky_range.x, sky_range.y)

	_update_frozen_branch_flow()
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


func _apply_display_mode() -> void:
	WindowModeLib.apply(get_window())


func _update_page_transition(delta: float) -> void:
	if not page_transition_active:
		return
	page_transition_progress = minf(1.0, page_transition_progress + delta / 0.46)
	if page_transition_progress < 1.0:
		return
	page_transition_active = false
	page_transition_progress = 1.0
	mode = page_transition_to_mode
	if page_transition_target_world != "":
		current_world_key = page_transition_target_world
		world_select_index = WorldDataLib.index_of(current_world_key)
	if mode == MODE_MAP:
		_sync_hovered_level_for_world()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if page_transition_active:
		return

	var mouse_pos = get_local_mouse_position()
	if event is InputEventPanGesture:
		if mode == MODE_WORLD_SELECT and absf(event.delta.x) > absf(event.delta.y):
			if event.delta.x >= 0.35:
				_shift_world_select(-1)
			elif event.delta.x <= -0.35:
				_shift_world_select(1)
			queue_redraw()
			return
		if mode == MODE_MAP and absf(event.delta.x) > absf(event.delta.y):
			_nudge_map_scroll(-float(event.delta.x) * 140.0)
			queue_redraw()
			return
		if _handle_scroll_input(float(event.delta.y) * 32.0, mouse_pos):
			queue_redraw()
			return

	if event is InputEventMouseButton and event.pressed and mode == MODE_WORLD_SELECT:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_shift_world_select(-1)
			queue_redraw()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_shift_world_select(1)
			queue_redraw()
			return

	if event is InputEventMouseButton and event.pressed and mode == MODE_SELECTION:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _handle_scroll_input(-PREP_POOL_STEP.y, mouse_pos):
				queue_redraw()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _handle_scroll_input(PREP_POOL_STEP.y, mouse_pos):
				queue_redraw()
			return

	if event is InputEventMouseButton and event.pressed and mode == MODE_ALMANAC:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _handle_scroll_input(-ALMANAC_GRID_STEP.y, mouse_pos):
				queue_redraw()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _handle_scroll_input(ALMANAC_GRID_STEP.y, mouse_pos):
				queue_redraw()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if mode == MODE_BATTLE and battle_state == BATTLE_PLAYING:
			selected_tool = ""
			queue_redraw()
		return

	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	if mode == MODE_WORLD_SELECT:
		_handle_world_select_click(mouse_pos)
		return

	if mode == MODE_MAP:
		if MAP_ALMANAC_BUTTON_RECT.has_point(mouse_pos):
			_enter_almanac_mode("plants")
			return
		if MAP_WORLD_BACK_RECT.has_point(mouse_pos):
			_enter_world_select_mode()
			return
		if MAP_SCROLL_LEFT_RECT.has_point(mouse_pos):
			_nudge_map_scroll(-MAP_VIEW_RECT.size.x * 0.32)
			return
		if MAP_SCROLL_RIGHT_RECT.has_point(mouse_pos):
			_nudge_map_scroll(MAP_VIEW_RECT.size.x * 0.32)
			return
		var level_index = _level_node_at(mouse_pos)
		if level_index != -1 and _is_level_unlocked(level_index):
			_start_level(level_index)
		return

	if mode == MODE_ALMANAC:
		_handle_almanac_click(mouse_pos)
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

	if _is_whack_level() and selected_tool == "":
		if _handle_whack_click(mouse_pos):
			queue_redraw()
		return

	if _is_whack_level():
		var whack_cell = _mouse_to_cell(mouse_pos)
		if whack_cell.x != -1:
			_handle_board_click(whack_cell)
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
	overlay_panel_style = StyleBoxFlat.new()
	overlay_panel_style.bg_color = Color(0.14, 0.12, 0.09, 0.9)
	overlay_panel_style.border_width_left = 3
	overlay_panel_style.border_width_top = 3
	overlay_panel_style.border_width_right = 3
	overlay_panel_style.border_width_bottom = 3
	overlay_panel_style.border_color = Color(0.92, 0.82, 0.54, 0.9)
	overlay_panel_style.corner_radius_top_left = 18
	overlay_panel_style.corner_radius_top_right = 18
	overlay_panel_style.corner_radius_bottom_right = 18
	overlay_panel_style.corner_radius_bottom_left = 18
	overlay_panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	overlay_panel_style.shadow_size = 14
	overlay_panel_style.shadow_offset = Vector2(0.0, 8.0)

	overlay_button_style = StyleBoxFlat.new()
	overlay_button_style.bg_color = Color(0.34, 0.68, 0.24, 0.96)
	overlay_button_style.border_width_left = 2
	overlay_button_style.border_width_top = 2
	overlay_button_style.border_width_right = 2
	overlay_button_style.border_width_bottom = 2
	overlay_button_style.border_color = Color(0.14, 0.28, 0.1)
	overlay_button_style.corner_radius_top_left = 14
	overlay_button_style.corner_radius_top_right = 14
	overlay_button_style.corner_radius_bottom_right = 14
	overlay_button_style.corner_radius_bottom_left = 14
	overlay_button_style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	overlay_button_style.shadow_size = 8
	overlay_button_style.shadow_offset = Vector2(0.0, 4.0)

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
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	toast_label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.05, 0.92))
	toast_label.add_theme_constant_override("outline_size", 6)
	toast_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
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
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78))
	banner_label.add_theme_color_override("font_outline_color", Color(0.18, 0.1, 0.06, 0.94))
	banner_label.add_theme_constant_override("outline_size", 7)
	banner_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
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
	message_panel.add_theme_stylebox_override("panel", overlay_panel_style)
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
	message_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88))
	message_label.add_theme_color_override("font_outline_color", Color(0.14, 0.1, 0.06, 0.9))
	message_label.add_theme_constant_override("outline_size", 5)
	column.add_child(message_label)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(190.0, 52.0)
	action_button.add_theme_font_override("font", ui_font)
	action_button.add_theme_font_size_override("font_size", 20)
	action_button.add_theme_color_override("font_color", Color(0.08, 0.18, 0.06))
	action_button.add_theme_stylebox_override("normal", overlay_button_style)
	action_button.add_theme_stylebox_override("hover", overlay_button_style.duplicate())
	action_button.add_theme_stylebox_override("pressed", overlay_button_style.duplicate())
	action_button.add_theme_stylebox_override("focus", overlay_button_style.duplicate())
	var hover_style := action_button.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.42, 0.8, 0.28, 0.98)
	hover_style.shadow_offset = Vector2(0.0, 6.0)
	action_button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := action_button.get_theme_stylebox("pressed").duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.28, 0.6, 0.2, 0.98)
	pressed_style.shadow_offset = Vector2(0.0, 2.0)
	action_button.add_theme_stylebox_override("pressed", pressed_style)
	action_button.pressed.connect(_on_message_button_pressed)
	column.add_child(action_button)


func _build_audio_player() -> void:
	if music_player != null:
		return
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -7.0
	add_child(music_player)


func _load_audio_stream(path: String) -> AudioStream:
	if path == "":
		return null
	if audio_stream_cache.has(path):
		return audio_stream_cache[path]
	if shared_audio_stream_cache.has(path):
		audio_stream_cache[path] = shared_audio_stream_cache[path]
		return audio_stream_cache[path]
	var absolute_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return null
	var data = file.get_buffer(file.get_length())
	if absolute_path.get_extension().to_lower() == "mp3":
		var stream := AudioStreamMP3.new()
		stream.data = data
		stream.loop = true
		stream.loop_offset = 0.0
		shared_audio_stream_cache[path] = stream
		audio_stream_cache[path] = stream
		return stream
	return null


func _prewarm_audio_stream(path: String) -> void:
	if path == "":
		return
	_load_audio_stream(path)


func _play_bgm(path: String) -> void:
	if path == "" or not is_inside_tree():
		return
	_build_audio_player()
	if current_bgm_path == path and music_player != null and music_player.playing:
		return
	var stream = _load_audio_stream(path)
	if stream == null or music_player == null:
		return
	current_bgm_path = path
	music_player.stream = stream
	music_player.play()


func _stop_bgm() -> void:
	current_bgm_path = ""
	if music_player != null:
		music_player.stop()


func _map_scroll_bounds_for_world(world_key: String) -> Vector2:
	var visible_levels = _visible_level_indices(world_key)
	if visible_levels.is_empty():
		return Vector2.ZERO
	var right_limit = MAP_VIEW_RECT.position.x + MAP_VIEW_RECT.size.x - 42.0
	var max_node_x = 0.0
	for index in visible_levels:
		max_node_x = maxf(max_node_x, float(Vector2(Defs.LEVELS[int(index)]["node_pos"]).x))
	var max_scroll = maxf(0.0, max_node_x - right_limit)
	return Vector2(0.0, max_scroll)


func _map_scroll_value(world_key: String, use_target: bool = false) -> float:
	var bounds = _map_scroll_bounds_for_world(world_key)
	var storage = map_scroll_target_by_world if use_target else map_scroll_by_world
	return clampf(float(storage.get(world_key, 0.0)), bounds.x, bounds.y)


func _set_map_scroll(world_key: String, value: float, snap: bool = false) -> void:
	var bounds = _map_scroll_bounds_for_world(world_key)
	var clamped = clampf(value, bounds.x, bounds.y)
	map_scroll_target_by_world[world_key] = clamped
	if snap:
		map_scroll_by_world[world_key] = clamped


func _nudge_map_scroll(delta_x: float) -> void:
	_set_map_scroll(current_world_key, _map_scroll_value(current_world_key, true) + delta_x)


func _update_map_scroll(delta: float) -> void:
	var current = _map_scroll_value(current_world_key)
	var target = _map_scroll_value(current_world_key, true)
	if absf(target - current) <= 0.25:
		map_scroll_by_world[current_world_key] = target
		return
	map_scroll_by_world[current_world_key] = lerpf(current, target, minf(1.0, delta * 10.5))


func _map_node_position(level_index: int) -> Vector2:
	var level = Defs.LEVELS[level_index]
	return Vector2(level["node_pos"]) - Vector2(_map_scroll_value(_world_key_for_level(level)), 0.0)


func _ensure_level_visible_on_map(level_index: int) -> void:
	if level_index < 0 or level_index >= Defs.LEVELS.size():
		return
	var level = Defs.LEVELS[level_index]
	var world_key = _world_key_for_level(level)
	var node_x = float(Vector2(level["node_pos"]).x)
	var target_scroll = _map_scroll_value(world_key, true)
	var left_limit = MAP_VIEW_RECT.position.x + 36.0
	var right_limit = MAP_VIEW_RECT.position.x + MAP_VIEW_RECT.size.x - 46.0
	var screen_x = node_x - target_scroll
	if screen_x > right_limit:
		target_scroll += screen_x - right_limit
	elif screen_x < left_limit:
		target_scroll -= left_limit - screen_x
	_set_map_scroll(world_key, target_scroll, mode != MODE_MAP)


func _init_campaign() -> void:
	completed_levels.resize(Defs.LEVELS.size())
	for i in range(completed_levels.size()):
		completed_levels[i] = false
	unlocked_levels = 1
	coins_total = 0
	var load_state = _load_game_status()
	if bool(load_state.get("loaded", false)):
		_show_toast("已读取本地存档")
	_finalize_campaign_init(bool(load_state.get("loaded", false)), bool(load_state.get("had_file", false)))
	world_select_index = WorldDataLib.index_of(current_world_key)
	world_select_scroll = float(world_select_index)
	_enter_world_select_mode(false)


func _finalize_campaign_init(load_succeeded: bool, had_existing_save: bool) -> void:
	save_dirty = false
	autosave_timer = 0.0
	if load_succeeded or had_existing_save:
		return
	_mark_save_dirty(true)


func _enter_world_select_mode(animated: bool = true) -> void:
	almanac_selected_kind = ""
	selected_tool = ""
	message_panel.visible = false
	_stop_bgm()
	var target_world = current_world_key if _is_world_unlocked(current_world_key) else "day"
	world_select_index = WorldDataLib.index_of(target_world)
	if animated and mode != MODE_WORLD_SELECT:
		_begin_page_transition(MODE_WORLD_SELECT, target_world, -1)
		return
	page_transition_active = false
	current_world_key = target_world
	mode = MODE_WORLD_SELECT
	queue_redraw()


func _enter_map_mode(animated: bool = false) -> void:
	battle_state = BATTLE_PLAYING
	board_rows = DEFAULT_BOARD_ROWS
	board_size = Vector2(COLS * CELL_SIZE.x, board_rows * CELL_SIZE.y)
	current_level = {}
	active_cards = []
	active_rows = []
	water_rows = []
	selection_cards = []
	selection_pool_cards = []
	selection_pool_scroll = 0.0
	almanac_selected_kind = ""
	selected_tool = ""
	message_panel.visible = false
	_stop_bgm()
	if not _is_world_unlocked(current_world_key):
		current_world_key = "day"
	if animated and mode != MODE_MAP:
		_begin_page_transition(MODE_MAP, current_world_key, 1)
		return
	mode = MODE_MAP
	_sync_hovered_level_for_world()
	queue_redraw()


func _sync_hovered_level_for_world() -> void:
	var hover_index = selected_level_index
	var visible_levels = _visible_level_indices()
	if visible_levels.is_empty():
		hovered_level_index = -1
		return
	if hover_index < 0 or not _is_level_unlocked(hover_index) or not visible_levels.has(hover_index):
		var fallback_index = -1
		for index in visible_levels:
			if _is_level_unlocked(int(index)):
				fallback_index = int(index)
		if fallback_index == -1:
			fallback_index = int(visible_levels[0])
		hover_index = fallback_index
	hovered_level_index = hover_index
	_ensure_level_visible_on_map(hover_index)


func _begin_page_transition(target_mode: String, target_world: String = "", direction: int = 1) -> void:
	page_transition_active = true
	page_transition_from_mode = mode
	page_transition_to_mode = target_mode
	page_transition_target_world = target_world
	page_transition_progress = 0.0
	page_transition_direction = direction
	if target_world != "":
		world_select_index = WorldDataLib.index_of(target_world)


func _shift_world_select(direction: int) -> void:
	var world_count = WorldDataLib.all().size()
	world_select_index = clampi(world_select_index + direction, 0, max(world_count - 1, 0))


func _selected_world_data() -> Dictionary:
	var worlds = WorldDataLib.all()
	if worlds.is_empty():
		return {}
	return worlds[clampi(world_select_index, 0, worlds.size() - 1)]


func _handle_world_select_click(mouse_pos: Vector2) -> void:
	if WORLD_SELECT_ARROW_LEFT_RECT.has_point(mouse_pos):
		_shift_world_select(-1)
		return
	if WORLD_SELECT_ARROW_RIGHT_RECT.has_point(mouse_pos):
		_shift_world_select(1)
		return
	if WORLD_SELECT_ALMANAC_RECT.has_point(mouse_pos):
		_enter_almanac_mode("plants")
		return
	if WORLD_SELECT_ENTER_RECT.has_point(mouse_pos):
		var selected_world = _selected_world_data()
		var world_key = String(selected_world.get("key", "day"))
		if not _is_world_unlocked(world_key):
			_show_toast("先通关前一世界才能进入这里")
			return
		current_world_key = world_key
		selected_level_index = _world_start_index(world_key)
		_enter_map_mode(true)
		return
	for i in range(WorldDataLib.all().size()):
		var card_rect = _world_card_rect(i)
		if not card_rect.has_point(mouse_pos):
			continue
		world_select_index = i
		var world_key = String(WorldDataLib.all()[i]["key"])
		if _is_world_unlocked(world_key):
			current_world_key = world_key
			selected_level_index = _world_start_index(world_key)
			_enter_map_mode(true)
		else:
			_show_toast("该世界尚未解锁")
		return


func _start_level(level_index: int) -> void:
	selected_level_index = level_index
	var level = Defs.LEVELS[level_index]
	if _requires_seed_selection(level):
		_enter_seed_selection(level_index)
		return
	_begin_level(level_index, _default_level_cards(level))


func _enter_almanac_mode(initial_tab: String = "plants") -> void:
	almanac_return_mode = mode
	mode = MODE_ALMANAC
	almanac_tab = initial_tab
	almanac_scroll = 0.0
	_ensure_almanac_selection()
	queue_redraw()


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
	selection_pool_cards = _available_seed_cards_for_level(current_level)
	selection_cards = []
	selection_pool_scroll = 0.0
	queue_redraw()


func _begin_level(level_index: int, chosen_cards: Array) -> void:
	selected_level_index = level_index
	current_level = Defs.LEVELS[level_index]
	conveyor_source_cards = []
	frozen_branch_post_freeze_cards = []
	selection_cards = []
	selection_pool_cards = []
	board_rows = clampi(max(DEFAULT_BOARD_ROWS, int(current_level.get("row_count", DEFAULT_BOARD_ROWS))), DEFAULT_BOARD_ROWS, ROWS)
	board_size = Vector2(COLS * CELL_SIZE.x, board_rows * CELL_SIZE.y)
	water_rows = current_level.get("water_rows", []).duplicate()
	if current_level.has("conveyor_plants"):
		conveyor_source_cards = current_level["conveyor_plants"].duplicate()
	if current_level.has("conveyor_plants_after_freeze"):
		frozen_branch_post_freeze_cards = current_level["conveyor_plants_after_freeze"].duplicate()
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
	base_events_spawned = 0
	total_spawned_units = 0
	expected_spawn_units = 1
	pending_grave_wave_spawns = 0
	grave_wave_triggered = false
	batch_spawn_remaining = 0
	batch_spawn_queue = []
	spawn_director_timer = 2.0 * _level_time_scale()
	conveyor_spawn_timer = 0.35
	level_end_time = float(current_level["events"].size())
	var sky_range = current_level["sky_sun_range"]
	sky_sun_cooldown = rng.randf_range(sky_range.x, sky_range.y)

	grid.clear()
	support_grid.clear()
	for row in range(ROWS):
		var row_data = []
		row_data.resize(COLS)
		var support_row = []
		support_row.resize(COLS)
		for col in range(COLS):
			row_data[col] = null
			support_row[col] = null
		grid.append(row_data)
		support_grid.append(support_row)

	zombies = []
	next_zombie_uid = 1
	projectiles = []
	suns = []
	coins = []
	plant_food_pickups = []
	rollers = []
	weeds = []
	spears = []
	graves = []
	porcelain_shards = []
	ice_tiles = []
	cell_terrain_mask = []
	effects = []
	card_cooldowns.clear()
	frozen_branch_midboss_spawned = false
	frozen_branch_midboss_cleared = false
	frozen_branch_progress_locked = false
	frozen_branch_final_boss_spawned = false
	frozen_branch_locked_progress = -1.0
	frozen_branch_freeze_visual_t = 1.0
	frozen_branch_freeze_visual_active = false
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

	_setup_cell_terrain_mask()
	_setup_level_graves()
	pending_grave_wave_spawns = graves.size()
	expected_spawn_units = _estimated_total_spawn_count()
	_prewarm_level_boss_assets()

	_mark_save_dirty(true)
	_show_banner(String(current_level["title"]), 2.2)
	if _is_whack_level():
		_show_toast("点击僵尸挥锤，敲出阳光再使用卡片")
	elif String(current_level.get("boss_intro_bgm", "")) != "":
		_play_bgm(String(current_level.get("boss_intro_bgm", "")))
	else:
		_stop_bgm()
	queue_redraw()


func _prewarm_level_boss_assets() -> void:
	if current_level.is_empty():
		return
	_prewarm_audio_stream(String(current_level.get("boss_intro_bgm", "")))
	_prewarm_audio_stream(String(current_level.get("boss_bgm", "")))
	var boss_kinds := {}
	var midboss_kind = String(current_level.get("mid_boss_kind", ""))
	if _is_hovering_boss_kind(midboss_kind):
		boss_kinds[midboss_kind] = true
	for event in current_level.get("events", []):
		var kind = String(event.get("kind", ""))
		if _is_hovering_boss_kind(kind):
			boss_kinds[kind] = true
	for kind in boss_kinds.keys():
		match String(kind):
			"rumia_boss":
				_ensure_rumia_frames_loaded()
			"daiyousei_boss":
				_ensure_daiyousei_frames_loaded()
			"cirno_boss":
				_ensure_cirno_frames_loaded()


func _handle_selection_click(mouse_pos: Vector2) -> void:
	if PREP_BACK_RECT.has_point(mouse_pos):
		_enter_map_mode()
		return

	if PREP_START_RECT.has_point(mouse_pos):
		var required_count = _required_seed_count(current_level)
		if selection_cards.size() < required_count:
			_show_toast("必须选满 %d 张植物" % required_count)
			return
		_begin_level(selected_level_index, selection_cards)
		return

	var selected_index = _selection_slot_at(mouse_pos)
	if selected_index != -1:
		if selected_index < selection_cards.size():
			selection_cards.remove_at(selected_index)
			queue_redraw()
		return

	var track_rect = _selection_pool_track_rect()
	if track_rect.has_point(mouse_pos):
		var max_scroll = _selection_pool_max_scroll()
		if max_scroll > 0.0:
			var ratio = clampf((mouse_pos.y - track_rect.position.y) / track_rect.size.y, 0.0, 1.0)
			_set_selection_pool_scroll(ratio * max_scroll)
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


func _handle_scroll_input(delta_y: float, mouse_pos: Vector2) -> bool:
	if mode == MODE_SELECTION and (PREP_POOL_PANEL_RECT.has_point(mouse_pos) or _selection_pool_view_rect().has_point(mouse_pos)):
		_set_selection_pool_scroll(selection_pool_scroll + delta_y)
		return true
	if mode == MODE_ALMANAC and (ALMANAC_LIST_RECT.has_point(mouse_pos) or _almanac_list_view_rect().has_point(mouse_pos)):
		_set_almanac_scroll(almanac_scroll + delta_y)
		return true
	return false


func _handle_almanac_click(mouse_pos: Vector2) -> void:
	if ALMANAC_CLOSE_RECT.has_point(mouse_pos):
		if almanac_return_mode == MODE_WORLD_SELECT:
			_enter_world_select_mode(false)
		else:
			_enter_map_mode(false)
		return
	if ALMANAC_PLANT_TAB_RECT.has_point(mouse_pos):
		almanac_tab = "plants"
		almanac_scroll = 0.0
		_ensure_almanac_selection()
		queue_redraw()
		return
	if ALMANAC_ZOMBIE_TAB_RECT.has_point(mouse_pos):
		almanac_tab = "zombies"
		almanac_scroll = 0.0
		_ensure_almanac_selection()
		queue_redraw()
		return

	var track_rect = _almanac_list_track_rect()
	if track_rect.has_point(mouse_pos):
		var max_scroll = _almanac_max_scroll()
		if max_scroll > 0.0:
			var ratio = clampf((mouse_pos.y - track_rect.position.y) / track_rect.size.y, 0.0, 1.0)
			_set_almanac_scroll(ratio * max_scroll)
			queue_redraw()
		return

	var entries = _current_almanac_entries()
	var view_rect = _almanac_list_view_rect()
	for i in range(entries.size()):
		var rect = _almanac_item_rect(i)
		if view_rect.intersects(rect) and rect.has_point(mouse_pos):
			almanac_selected_kind = String(entries[i])
			queue_redraw()
			return


func _update_spawn_director(delta: float) -> void:
	var events = current_level["events"]
	if _is_frozen_branch_level() and frozen_branch_progress_locked:
		return
	if not batch_spawn_queue.is_empty():
		spawn_director_timer -= delta
		if spawn_director_timer > 0.0:
			return

		var spawn_info = batch_spawn_queue[0]
		batch_spawn_queue.remove_at(0)
		if spawn_info.has("spawn_x"):
			_spawn_zombie_at(String(spawn_info["kind"]), int(spawn_info.get("row", -1)), float(spawn_info["spawn_x"]))
		else:
			_spawn_zombie(String(spawn_info["kind"]), int(spawn_info.get("row", -1)))
		if bool(spawn_info.get("progress_event", false)):
			base_events_spawned += 1
		batch_spawn_remaining = batch_spawn_queue.size()
		spawn_director_timer = _intra_batch_spawn_delay() * float(spawn_info.get("delay_scale", 1.0))
		return

	if next_event_index >= events.size():
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

	if _is_whack_level():
		_replenish_whack_graves()

	var wave_markers = _wave_marker_indices()
	var batch_size = min(_target_batch_size(), events.size() - next_event_index)
	batch_spawn_queue = []
	for i in range(batch_size):
		var event_index = next_event_index + i
		var event = events[event_index]
		var event_row = int(event.get("row", -1))
		if wave_markers.has(event_index):
			var is_final = event_index == int(wave_markers[wave_markers.size() - 1])
			_show_banner("最后一波！" if is_final else "一大波僵尸正在逼近！", 2.2)
			if is_final:
				_queue_final_grave_wave_spawns()
		batch_spawn_queue.append({
			"kind": String(event["kind"]),
			"row": event_row,
			"delay_scale": 1.0,
			"progress_event": true,
		})
		var extra_count = _extra_spawn_count_for_event(event_index, event)
		for extra_index in range(extra_count):
			var support_kind = _support_spawn_kind(String(event["kind"]), event_index, extra_index)
			batch_spawn_queue.append({
				"kind": support_kind,
				"row": _support_spawn_row_for_event(event_row, support_kind),
				"delay_scale": 0.8 if extra_index == 0 else 0.68,
				"progress_event": false,
			})

	next_event_index += batch_size
	batch_spawn_remaining = batch_spawn_queue.size()
	spawn_director_timer = 0.01


func _replenish_whack_graves() -> void:
	if not _is_whack_level() or graves.size() >= 5 or not current_level.has("grave_layout"):
		return
	var candidates: Array = []
	for cell in current_level["grave_layout"]:
		if _grave_index_at(int(cell.x), int(cell.y)) == -1:
			candidates.append(cell)
	var add_count = min(5 - graves.size(), candidates.size())
	if add_count <= 0:
		return
	for _i in range(add_count):
		var pick = rng.randi_range(0, candidates.size() - 1)
		var cell = candidates[pick]
		candidates.remove_at(pick)
		graves.append({
			"row": int(cell.x),
			"col": int(cell.y),
		})
		effects.append({
			"position": _cell_center(int(cell.x), int(cell.y)) + Vector2(0.0, 18.0),
			"radius": 52.0,
			"time": 0.28,
			"duration": 0.28,
			"color": Color(0.78, 0.78, 0.84, 0.24),
		})
	_show_banner("新的坟墓升起了！", 1.6)


func _wave_marker_indices() -> Array:
	var events = current_level.get("events", [])
	var markers: Array = []
	for i in range(events.size()):
		if bool(events[i].get("wave", false)):
			markers.append(i)
	if events.size() >= 4 and markers.size() < 2:
		var first_marker = max(1, int(floor(float(events.size()) * 0.45)))
		var final_marker = max(first_marker + 1, events.size() - 2)
		if not markers.has(first_marker):
			markers.append(first_marker)
		if not markers.has(final_marker):
			markers.append(final_marker)
	markers.sort()
	return markers


func _queue_final_grave_wave_spawns() -> void:
	if grave_wave_triggered or not _is_night_level() or graves.is_empty() or _is_whack_level():
		return
	grave_wave_triggered = true
	var extra_queue: Array = []
	for grave in graves:
		var row = int(grave["row"])
		var col = int(grave["col"])
		var spawn_kind = _grave_wave_kind_for_cell(row, col)
		extra_queue.append({
			"kind": spawn_kind,
			"row": row,
			"spawn_x": _cell_center(row, col).x + rng.randf_range(-10.0, 10.0),
			"delay_scale": 0.72,
			"progress_event": false,
		})
	if extra_queue.is_empty():
		return
	_show_banner("坟墓中的僵尸也开始爬出了！", 2.0)
	batch_spawn_queue.append_array(extra_queue)
	batch_spawn_remaining = batch_spawn_queue.size()
	pending_grave_wave_spawns = 0


func _grave_wave_kind_for_cell(row: int, col: int) -> String:
	var progress = float(next_event_index) / float(max(current_level.get("events", []).size(), 1))
	if progress >= 0.72:
		var level_id = String(current_level.get("id", ""))
		if (level_id == "2-16" or level_id == "2-17") and rng.randf() < 0.28:
			return "dark_football"
		if rng.randf() < 0.34:
			return "football"
		if rng.randf() < 0.5:
			return "screen_door"
	if progress >= 0.4:
		if rng.randf() < 0.45:
			return "newspaper"
		if rng.randf() < 0.55:
			return "screen_door"
	return "normal" if (row + col) % 2 == 0 else "newspaper"


func _spawn_zombie(kind: String, row_override: int = -1, reserve_progress: bool = false) -> void:
	var base = Defs.ZOMBIES[kind]
	if _is_boss_kind(kind) and not _find_alive_enemy_boss(kind).is_empty():
		return
	var row = row_override if row_override >= 0 else _choose_spawn_row_for_kind(kind)
	if row < 0:
		return
	if kind != "bobsled_team" and not _is_row_valid_for_spawn_kind(kind, row):
		row = _choose_spawn_row_for_kind(kind)
		if row < 0:
			return
	var spawn_x = BOARD_ORIGIN.x + board_size.x + 80.0 + rng.randf_range(0.0, 36.0)
	if kind == "bobsled_team":
		if row_override >= 0:
			if not _row_has_ice(row_override):
				return
			row = row_override
		else:
			var ice_rows: Array = []
			for active_row in active_rows:
				if _row_has_ice(int(active_row)):
					ice_rows.append(int(active_row))
			if ice_rows.is_empty():
				return
			row = int(ice_rows[rng.randi_range(0, ice_rows.size() - 1)])
		spawn_x = BOARD_ORIGIN.x + board_size.x + 46.0 + rng.randf_range(0.0, 18.0)
	if kind == "nether" and not graves.is_empty():
		var grave = graves[rng.randi_range(0, graves.size() - 1)]
		row = int(grave["row"])
		spawn_x = _cell_center(row, int(grave["col"])).x + rng.randf_range(-12.0, 12.0)
	if _is_whack_level():
		var grave_candidates: Array = []
		for grave in graves:
			if row_override >= 0 and int(grave["row"]) != row_override:
				continue
			grave_candidates.append(grave)
		if not grave_candidates.is_empty():
			var grave = grave_candidates[rng.randi_range(0, grave_candidates.size() - 1)]
			row = int(grave["row"])
			spawn_x = _cell_center(row, int(grave["col"])).x + rng.randf_range(-16.0, 16.0)
	if reserve_progress:
		expected_spawn_units += 1
	zombies.append({
			"uid": next_zombie_uid,
			"kind": kind,
			"row": row,
			"x": spawn_x,
		"spawn_time": level_time,
		"anim_phase": rng.randf_range(0.0, TAU),
		"health": float(base["health"]),
		"max_health": float(base["health"]),
		"shield_health": float(base.get("shield_health", 0.0)),
		"max_shield_health": float(base.get("shield_health", 0.0)),
		"base_speed": float(base["speed"]) * (0.78 if _is_whack_level() else 1.0),
		"attack_dps": float(base["attack_dps"]),
		"flash": 0.0,
		"slow_timer": 0.0,
		"rooted_timer": 0.0,
		"bite_timer": 0.0,
		"impact_timer": 0.0,
		"special_pause_timer": 0.28 if _is_whack_level() else 0.0,
		"enraged": false,
			"dance_summoned": kind != "dancing",
			"summon_cooldown": 1.8 if kind == "dancing" else 0.0,
			"has_vaulted": kind != "pole_vault" and kind != "dolphin_rider",
			"jumping": false,
		"jump_t": 0.0,
		"jump_from_x": 0.0,
		"jump_to_x": 0.0,
		"jump_duration": 0.34,
		"jump_row_to": row,
		"jump_row_switched": true,
		"jump_offset": 0.0,
		"reflect_timer": 0.0,
		"reflect_cooldown": 5.0 if kind == "kungfu" else 0.0,
		"weed_pause_timer": 0.0,
		"last_cell_col": COLS + 1,
		"boss_skill_timer": 8.0 if _is_boss_kind(kind) else 0.0,
		"boss_pause_timer": 0.0,
		"boss_phase": 0,
		"boss_skill_cycle": 0,
		"hover_shift_timer": float(base.get("hover_shift_interval", 0.0)),
		"hover_direction": -1,
		"rumia_state": "idle",
		"rumia_state_timer": 0.0,
		"rumia_move_timer": 0.0,
		"rumia_move_duration": 0.0,
		"rumia_move_from_y": 0.0,
		"rumia_move_to_y": 0.0,
		"rumia_reinforcement_timer": 0.0,
		"boat_phase": 0,
		"boat_stride_timer": 0.35 if kind == "dragon_boat" else 0.0,
		"boat_move_from_x": spawn_x,
		"boat_move_to_x": spawn_x,
		"boat_move_t": 1.0,
		"boat_move_duration": 0.0,
		"shield_regens_left": 1 if kind == "basketball" else 0,
		"shield_regen_timer": -1.0,
		"snipe_cooldown": 1.6 if kind == "shouyue" else 0.0,
		"snipe_charge_timer": 0.0,
		"snipe_charge_duration": 0.16,
		"snipe_charge_active": false,
		"snipe_focus_timer": 0.0,
		"snipe_target_row": -1,
		"snipe_target_col": -1,
		"revealed_timer": 0.0,
		"ninja_dashed": false,
			"nezha_dived": false,
			"nezha_target_col": -1,
			"burn_timer": 0.0,
			"ice_drop_cooldown": 3.8 if kind == "ice_block" else 0.0,
			"submerged": kind == "snorkel",
			"spawned_bobsled": false,
			"on_ice": false,
			"hypnotized": false,
			"sleep_cooldown": 1.8 if kind == "nether" else 0.0,
			"plant_food_carrier": rng.randf() < 0.05,
			"whack_hits_left": _whack_hits_for_kind(kind) if _is_whack_level() else 0,
		"whacked": false,
		})
	next_zombie_uid += 1
	if kind == "rumia_boss" or kind == "daiyousei_boss" or kind == "cirno_boss":
		var boss_index = zombies.size() - 1
		var boss_unit = zombies[boss_index]
		boss_unit["x"] = _boss_anchor_x(kind)
		boss_unit["hover_direction"] = -1 if row >= int(round(float(active_rows.size() - 1) * 0.5)) else 1
		boss_unit["rumia_move_from_y"] = _row_center_y(int(boss_unit["row"]))
		boss_unit["rumia_move_to_y"] = _row_center_y(int(boss_unit["row"]))
		boss_unit["rumia_reinforcement_timer"] = 4.8 if kind == "rumia_boss" else (4.2 if kind == "cirno_boss" else 4.6)
		boss_unit["hover_shift_timer"] = _roll_hover_shift_interval(kind, 0)
		zombies[boss_index] = boss_unit
		if kind == "rumia_boss":
			if String(current_level.get("boss_bgm", "")) != "":
				_play_bgm(String(current_level.get("boss_bgm", "")))
			_show_banner("露米娅出现了！", 2.4)
		elif kind == "daiyousei_boss":
			_show_banner("大妖精出现了！", 2.2)
		else:
			frozen_branch_final_boss_spawned = true
			_trigger_cirno_freeze_transition()
			if String(current_level.get("boss_bgm", "")) != "":
				_play_bgm(String(current_level.get("boss_bgm", "")))
			_show_banner("琪露诺出现了！", 2.4)
	elif kind == "pool_boss":
		var boss_index = zombies.size() - 1
		var boss_unit = zombies[boss_index]
		boss_unit["rumia_reinforcement_timer"] = 4.9
		zombies[boss_index] = boss_unit
		_show_banner("玄潮尸王出现了！", 2.3)
	total_spawned_units += 1


func _is_water_zombie_kind(kind: String) -> bool:
	return kind == "ducky_tube" \
		or kind == "lifebuoy_normal" \
		or kind == "lifebuoy_cone" \
		or kind == "lifebuoy_bucket" \
		or kind == "snorkel" \
		or kind == "dolphin_rider" \
		or kind == "dragon_boat"


func _is_dual_terrain_zombie_kind(kind: String) -> bool:
	return kind == "qinghua" or kind == "ice_block" or kind == "shouyue"


func _is_row_valid_for_spawn_kind(kind: String, row: int) -> bool:
	if not _is_row_active(row):
		return false
	if not _is_pool_level():
		return true
	if kind == "bobsled_team":
		return true
	if _is_dual_terrain_zombie_kind(kind):
		return true
	if _is_water_zombie_kind(kind):
		return _is_water_row(row)
	return not _is_water_row(row)


func _eligible_spawn_rows_for_kind(kind: String) -> Array:
	var rows: Array = []
	for row in active_rows:
		var row_i = int(row)
		if _is_row_valid_for_spawn_kind(kind, row_i):
			rows.append(row_i)
	if rows.is_empty():
		for row in active_rows:
			rows.append(int(row))
	return rows


func _choose_spawn_row_for_kind(kind: String) -> int:
	var candidates = _eligible_spawn_rows_for_kind(kind)
	if candidates.is_empty():
		return -1
	var min_count := 999999
	var row_counts := {}
	for row in candidates:
		var amount := 0
		for zombie in zombies:
			if int(zombie["row"]) == int(row):
				amount += 1
		row_counts[int(row)] = amount
		min_count = min(min_count, amount)
	var filtered: Array = []
	for row in candidates:
		if int(row_counts[int(row)]) == min_count:
			filtered.append(int(row))
	return int(filtered[rng.randi_range(0, filtered.size() - 1)])


func _choose_spawn_row() -> int:
	return _choose_spawn_row_for_kind("normal")


func _top_plant_at(row: int, col: int) -> Variant:
	return grid[row][col]


func _support_plant_at(row: int, col: int) -> Variant:
	return support_grid[row][col]


func _targetable_plant_at(row: int, col: int) -> Variant:
	var plant_variant = grid[row][col]
	return plant_variant if plant_variant != null else support_grid[row][col]


func _set_targetable_plant(row: int, col: int, plant: Variant) -> void:
	if grid[row][col] != null:
		grid[row][col] = plant
	else:
		support_grid[row][col] = plant


func _clear_targetable_plant(row: int, col: int) -> void:
	if grid[row][col] != null:
		grid[row][col] = null
	else:
		support_grid[row][col] = null


func _is_low_profile_kind(kind: String) -> bool:
	return kind == "spikeweed" or kind == "tangle_kelp"


func _can_plant_on_lily_pad(kind: String) -> bool:
	return kind != "lily_pad" and kind != "tangle_kelp" and kind != "spikeweed" and kind != "grave_buster" and kind != "wallnut_bowling"


func _ice_index_at(row: int, col: int) -> int:
	for i in range(ice_tiles.size()):
		var tile = ice_tiles[i]
		if int(tile["row"]) == row and int(tile["col"]) == col:
			return i
	return -1


func _porcelain_shard_index_at(row: int, col: int) -> int:
	for i in range(porcelain_shards.size()):
		var shard = porcelain_shards[i]
		if int(shard["row"]) == row and int(shard["col"]) == col:
			return i
	return -1


func _has_porcelain_shard(row: int, col: int) -> bool:
	return _porcelain_shard_index_at(row, col) != -1


func _add_porcelain_shard(row: int, col: int, duration: float = 20.0) -> void:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return
	var shard_index = _porcelain_shard_index_at(row, col)
	if shard_index != -1:
		porcelain_shards[shard_index]["time"] = maxf(float(porcelain_shards[shard_index].get("time", 0.0)), duration)
		return
	porcelain_shards.append({
		"row": row,
		"col": col,
		"time": duration,
		"duration": duration,
	})
	effects.append({
		"position": _cell_center(row, col) + Vector2(0.0, 10.0),
		"radius": 34.0,
		"time": 0.32,
		"duration": 0.32,
		"color": Color(0.72, 0.9, 1.0, 0.28),
	})


func _has_ice_tile(row: int, col: int) -> bool:
	return _ice_index_at(row, col) != -1


func _row_has_ice(row: int) -> bool:
	for tile in ice_tiles:
		if int(tile["row"]) == row:
			return true
	return false


func _set_ice_tile(row: int, col: int) -> void:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return
	if _ice_index_at(row, col) != -1:
		return
	ice_tiles.append({
		"row": row,
		"col": col,
	})


func _clear_ice_row(row: int) -> void:
	for i in range(ice_tiles.size() - 1, -1, -1):
		if int(ice_tiles[i]["row"]) == row:
			ice_tiles.remove_at(i)


func _setup_cell_terrain_mask() -> void:
	cell_terrain_mask.clear()
	for row in range(ROWS):
		var row_data: Array = []
		for col in range(COLS):
			if not _is_row_active(row):
				row_data.append("void")
			else:
				row_data.append("water" if _is_water_row(row) else "land")
		cell_terrain_mask.append(row_data)
	var level_mask = current_level.get("cell_terrain_mask", [])
	if not (level_mask is Array) or level_mask.is_empty():
		return
	for mask_row_index in range(min(level_mask.size(), active_rows.size())):
		var source_row = level_mask[mask_row_index]
		if not (source_row is Array):
			continue
		var target_row = int(active_rows[mask_row_index])
		for col in range(min(source_row.size(), COLS)):
			cell_terrain_mask[target_row][col] = String(source_row[col])


func _cell_terrain_kind(row: int, col: int) -> String:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return "void"
	if cell_terrain_mask.size() == ROWS and cell_terrain_mask[row] is Array and col < cell_terrain_mask[row].size():
		return String(cell_terrain_mask[row][col])
	if not _is_row_active(row):
		return "void"
	return "water" if _is_water_row(row) else "land"


func _set_cell_terrain_kind(row: int, col: int, terrain: String) -> void:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return
	if cell_terrain_mask.size() != ROWS:
		_setup_cell_terrain_mask()
	cell_terrain_mask[row][col] = terrain


func _is_water_cell(row: int, col: int) -> bool:
	return _cell_terrain_kind(row, col) == "water"


func _is_frozen_cell(row: int, col: int) -> bool:
	return _cell_terrain_kind(row, col) == "frozen"


func _plant_attack_cadence_scale(row: int, col: int) -> float:
	if _is_frozen_cell(row, col):
		return maxf(1.0, float(current_level.get("frozen_attack_slow", 1.3)))
	return 1.0


func _plant_cadence_delta(delta: float, row: int, col: int) -> float:
	return delta / _plant_attack_cadence_scale(row, col)


func _placement_error(kind: String, row: int, col: int) -> String:
	var top_plant = _top_plant_at(row, col)
	var support_plant = _support_plant_at(row, col)
	var grave_index = _grave_index_at(row, col)
	var terrain = _cell_terrain_kind(row, col)
	if kind == "grave_buster":
		if grave_index == -1:
			return "坟墓吞噬者只能种在坟墓上"
		if top_plant != null or support_plant != null:
			return "这个格子已经被占用了"
		return ""
	if grave_index != -1:
		return "这里有坟墓，先用坟墓吞噬者处理"
	if _has_porcelain_shard(row, col):
		return "青花瓷碎片还没清理干净"
	if _has_ice_tile(row, col):
		return "冰道上不能种植"
	if kind == "lily_pad":
		if terrain != "water":
			return "睡莲只能种在水路"
		if top_plant != null or support_plant != null:
			return "这个格子已经被占用了"
		return ""
	if kind == "tangle_kelp":
		if terrain != "water":
			return "缠绕海草只能种在水里"
		if top_plant != null or support_plant != null:
			return "这个格子已经被占用了"
		return ""
	if kind == "spikeweed" and terrain == "water":
		return "地刺不能种在水里"
	if terrain == "water":
		if top_plant != null:
			return "这个格子已经被占用了"
		if support_plant == null:
			return "水路需要先放睡莲"
		if not _can_plant_on_lily_pad(kind):
			return "这个植物不能种在睡莲上"
		return ""
	if terrain == "frozen":
		if top_plant != null:
			return "这个格子已经被占用了"
		return ""
	if top_plant != null or support_plant != null:
		return "这个格子已经被占用了"
	return ""


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
		if _targetable_plant_at(cell.x, cell.y) == null:
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
		if _targetable_plant_at(cell.x, cell.y) == null:
			_show_toast("这里没有植物")
			return
		if _top_plant_at(cell.x, cell.y) != null:
			grid[cell.x][cell.y] = null
		else:
			support_grid[cell.x][cell.y] = null
		selected_tool = ""
		_show_toast("植物已铲除")
		queue_redraw()
		return

	var placement_error = _placement_error(selected_tool, cell.x, cell.y)
	if placement_error != "":
		_show_toast(placement_error)
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
	elif selected_tool == "lily_pad":
		support_grid[cell.x][cell.y] = _create_plant(selected_tool, cell.x, cell.y)
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


func _find_whack_target(mouse_pos: Vector2) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + float(zombie.get("jump_offset", 0.0)))
		var distance = zombie_pos.distance_to(mouse_pos)
		if distance > 52.0:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _whack_hits_for_kind(kind: String) -> int:
	match kind:
		"buckethead":
			return 3
		"conehead":
			return 2
		_:
			return 1


func _handle_whack_click(mouse_pos: Vector2) -> bool:
	if not _is_whack_level():
		return false
	var zombie_index = _find_whack_target(mouse_pos)
	if zombie_index == -1:
		return false
	var zombie = zombies[zombie_index]
	var hits_left = max(1, int(zombie.get("whack_hits_left", _whack_hits_for_kind(String(zombie["kind"])))))
	hits_left -= 1
	zombie["whack_hits_left"] = hits_left
	zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.3)
	zombie["impact_timer"] = maxf(float(zombie.get("impact_timer", 0.0)), 0.24)
	zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.18)
	effects.append({
		"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 18.0),
		"radius": 42.0,
		"time": 0.18,
		"duration": 0.18,
		"color": Color(1.0, 0.88, 0.24, 0.46),
	})
	if hits_left <= 0:
		zombie["health"] = 0.0
		zombie["whacked"] = true
	else:
		var total_hits = max(1, _whack_hits_for_kind(String(zombie["kind"])))
		zombie["health"] = maxf(1.0, float(zombie["max_health"]) * float(hits_left) / float(total_hits))
	zombies[zombie_index] = zombie
	return true


func _create_plant(kind: String, row: int, col: int) -> Dictionary:
	var data = Defs.PLANTS[kind]
	var plant = {
		"kind": kind,
		"row": row,
		"col": col,
		"spawn_time": level_time,
		"anim_phase": rng.randf_range(0.0, TAU),
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
		"grow_timer": 0.0,
		"mature": false,
		"grave_row": -1,
		"grave_col": -1,
		"sleep_timer": 0.0,
		"support_timer": 0.0,
		"contact_timer": 0.0,
		"action_timer": 0.0,
		"action_duration": 0.18,
		"special_state": "",
		"special_timer": 0.0,
		"special_duration": 0.0,
		"attack_target_x": 0.0,
		"attack_target_row": row,
		"attack_has_hit": false,
	}

	match kind:
		"sunflower":
			plant["sun_timer"] = float(data["first_sun_delay"])
		"peashooter", "snow_pea", "puff_shroom", "scaredy_shroom":
			plant["shot_cooldown"] = 0.5
		"repeater":
			plant["shot_cooldown"] = 0.45
		"threepeater":
			plant["shot_cooldown"] = 0.5
		"boomerang_shooter":
			plant["shot_cooldown"] = 0.55
		"sakura_shooter":
			plant["shot_cooldown"] = 0.58
		"lotus_lancer":
			plant["shot_cooldown"] = 0.62
		"mirror_reed":
			plant["support_timer"] = 0.7
		"frost_fan":
			plant["shot_cooldown"] = 0.65
		"cherry_bomb":
			plant["fuse_timer"] = float(data["fuse"])
		"jalapeno":
			plant["fuse_timer"] = float(data["fuse"])
		"potato_mine":
			plant["arm_timer"] = float(data["arm_time"])
		"spikeweed":
			plant["contact_timer"] = 0.18
		"vine_lasher", "pepper_mortar":
			plant["attack_timer"] = 0.45
		"pulse_bulb":
			plant["pulse_timer"] = 1.0
		"sun_bean":
			plant["sun_timer"] = float(data["first_sun_delay"])
			plant["shot_cooldown"] = 0.6
		"sun_shroom":
			plant["sun_timer"] = float(data["first_sun_delay"])
			plant["grow_timer"] = float(data["grow_time"])
		"moon_lotus":
			plant["sun_timer"] = float(data["first_sun_delay"])
			plant["support_timer"] = float(data["wake_interval"])
		"prism_grass", "meteor_gourd", "root_snare", "thunder_pine":
			plant["attack_timer"] = 0.45
		"lantern_bloom", "dream_drum":
			plant["support_timer"] = 0.8
		"wind_orchid":
			plant["gust_timer"] = 2.0
		"fume_shroom":
			plant["attack_timer"] = 0.5
		"ice_shroom", "doom_shroom":
			plant["fuse_timer"] = 0.6
		"grave_buster":
			plant["chew_timer"] = float(data["chew_time"])
			plant["grave_row"] = row
			plant["grave_col"] = col

	return plant


func _trigger_plant_action(plant: Dictionary, duration: float) -> void:
	plant["action_timer"] = maxf(float(plant.get("action_timer", 0.0)), duration)
	plant["action_duration"] = maxf(duration, 0.01)


func _update_plants(delta: float) -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue

			var plant = plant_variant
			plant["flash"] = maxf(0.0, float(plant["flash"]) - delta)
			plant["action_timer"] = maxf(0.0, float(plant.get("action_timer", 0.0)) - delta)
			plant["sleep_timer"] = maxf(0.0, float(plant.get("sleep_timer", 0.0)) - delta)
			plant["support_timer"] = maxf(0.0, float(plant.get("support_timer", 0.0)) - delta)
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
			if float(plant["sleep_timer"]) > 0.0 and String(plant["plant_food_mode"]) == "":
				grid[row][col] = plant
				continue

			match String(plant["kind"]):
				"sunflower":
					plant["sun_timer"] -= delta
					if float(plant["sun_timer"]) <= 0.0:
						var center = _cell_center(row, col)
						_spawn_sun(center + Vector2(rng.randf_range(-8.0, 8.0), -18.0), center.y - 10.0, "plant")
						plant["sun_timer"] = float(Defs.PLANTS["sunflower"]["sun_interval"])
						_trigger_plant_action(plant, 0.32)
				"peashooter":
					if _update_shooter_plant_food(plant, delta, row, col, Color(0.36, 0.86, 0.3), 0.0, 1, 0.1):
						grid[row][col] = plant
						continue
					_update_basic_shooter(plant, delta, row, col, Color(0.36, 0.86, 0.3), 0.0)
				"puff_shroom":
					if _update_shooter_plant_food(plant, delta, row, col, Color(0.84, 0.68, 0.98), 0.0, 2, 0.07):
						grid[row][col] = plant
						continue
					_update_basic_shooter(plant, delta, row, col, Color(0.84, 0.68, 0.98), 0.0)
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
				"threepeater":
					_update_threepeater(plant, delta, row, col)
				"boomerang_shooter":
					_update_boomerang_shooter(plant, delta, row, col)
				"sakura_shooter":
					_update_sakura_shooter(plant, delta, row, col)
				"lotus_lancer":
					_update_lotus_lancer(plant, delta, row, col)
				"mirror_reed":
					_update_mirror_reed(plant, delta, row, col)
				"frost_fan":
					_update_frost_fan(plant, delta, row, col)
				"cherry_bomb":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						_explode_cherry(row, col, String(plant["plant_food_mode"]) == "mega_bomb")
						grid[row][col] = null
						continue
				"jalapeno":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						_trigger_jalapeno(row, col, String(plant["plant_food_mode"]) == "inferno")
						grid[row][col] = null
						continue
				"ice_shroom":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						_trigger_ice_shroom(row, col, String(plant["plant_food_mode"]) == "deep_freeze")
						grid[row][col] = null
						continue
				"doom_shroom":
					plant["fuse_timer"] -= delta
					if float(plant["fuse_timer"]) <= 0.0:
						_trigger_doom_shroom(row, col, String(plant["plant_food_mode"]) == "doom_bloom")
						grid[row][col] = null
						continue
				"potato_mine":
					if not bool(plant["armed"]):
						plant["arm_timer"] -= delta
						if float(plant["arm_timer"]) <= 0.0:
							plant["armed"] = true
							_trigger_plant_action(plant, 0.2)
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
							if _is_boss_zombie(zombie):
								zombie = _apply_zombie_damage(zombie, 320.0, 0.25)
								plant["chew_timer"] = 7.5
							else:
								zombie["health"] = 0.0
								zombie["flash"] = 0.25
								plant["chew_timer"] = float(Defs.PLANTS["chomper"]["chew_time"])
							zombies[zombie_index] = zombie
							_trigger_plant_action(plant, 0.42)
				"squash":
					if _update_squash(plant, row, col, delta):
						grid[row][col] = null
						continue
				"tangle_kelp":
					if _update_tangle_kelp(plant, row, col):
						grid[row][col] = null
						continue
				"spikeweed":
					_update_spikeweed(plant, delta, row, col)
				"vine_lasher":
					_update_vine_lasher(plant, delta, row, col)
				"pepper_mortar":
					_update_pepper_mortar(plant, delta, row, col)
				"pulse_bulb":
					_update_pulse_bulb(plant, delta, row, col)
				"sun_bean":
					_update_sun_bean(plant, delta, row, col)
				"sun_shroom":
					_update_sun_shroom(plant, delta, row, col)
				"moon_lotus":
					_update_moon_lotus(plant, delta, row, col)
				"prism_grass":
					_update_prism_grass(plant, delta, row, col)
				"lantern_bloom":
					_update_lantern_bloom(plant, delta, row, col)
				"meteor_gourd":
					_update_meteor_gourd(plant, delta, row, col)
				"root_snare":
					_update_root_snare(plant, delta, row, col)
				"thunder_pine":
					_update_thunder_pine(plant, delta, row, col)
				"dream_drum":
					_update_dream_drum(plant, delta, row, col)
				"fume_shroom":
					_update_fume_shroom(plant, delta, row, col)
				"scaredy_shroom":
					_update_scaredy_shroom(plant, delta, row, col)
				"grave_buster":
					if _update_grave_buster(plant, delta, row, col):
						grid[row][col] = null
						continue
				"wind_orchid":
					_update_wind_orchid(plant, delta, row, col)
				"torchwood":
					_update_torchwood(plant, delta, row, col)
				"lily_pad", "wallnut", "tallnut", "hypno_shroom", "cactus_guard":
					pass

			grid[row][col] = plant
	for row in range(ROWS):
		for col in range(COLS):
			var support_variant = support_grid[row][col]
			if support_variant == null:
				continue
			var support = support_variant
			support["flash"] = maxf(0.0, float(support.get("flash", 0.0)) - delta)
			support["action_timer"] = maxf(0.0, float(support.get("action_timer", 0.0)) - delta)
			support["plant_food_timer"] = maxf(0.0, float(support.get("plant_food_timer", 0.0)) - delta)
			if float(support.get("plant_food_timer", 0.0)) <= 0.0 and String(support.get("plant_food_mode", "")) != "":
				support["plant_food_mode"] = ""
			support_grid[row][col] = support


func _update_basic_shooter(plant: Dictionary, delta: float, row: int, col: int, projectile_color: Color, slow_duration: float) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return

	var center_x = _cell_center(row, col).x
	var kind = String(plant["kind"])
	var range_limit = float(Defs.PLANTS[kind].get("range", 10000.0))
	if not _has_zombie_ahead(row, center_x, range_limit):
		return

	var damage = float(Defs.PLANTS[kind]["damage"])
	_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -10.0), projectile_color, damage, slow_duration)
	plant["shot_cooldown"] = float(Defs.PLANTS[kind]["shoot_interval"])
	_trigger_plant_action(plant, 0.18)


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
		_trigger_plant_action(plant, 0.14)
	return true


func _update_repeater(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	if String(plant["plant_food_mode"]) == "double_storm":
		if float(plant["plant_food_timer"]) > 0.0:
			plant["plant_food_interval"] -= cadence_delta
			while float(plant["plant_food_interval"]) <= 0.0:
				_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -16.0), Color(0.3, 0.84, 0.26), 20.0, 0.0)
				_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -4.0), Color(0.3, 0.84, 0.26), 20.0, 0.0)
				plant["plant_food_interval"] += 0.08
				plant["flash"] = maxf(float(plant["flash"]), 0.18)
				_trigger_plant_action(plant, 0.16)
			return
		if int(plant["plant_food_charges"]) > 0:
			_spawn_projectile(row, _cell_center(row, col) + Vector2(38.0, -12.0), Color(0.32, 0.96, 0.38), 400.0, 0.0, 520.0, 14.0)
			plant["plant_food_charges"] = 0
			plant["plant_food_mode"] = ""
			plant["plant_food_interval"] = 0.0
			plant["flash"] = maxf(float(plant["flash"]), 0.2)
			_trigger_plant_action(plant, 0.32)
			return

	plant["shot_cooldown"] -= cadence_delta
	if int(plant["burst_remaining"]) > 0:
		plant["burst_gap_timer"] -= cadence_delta
		if float(plant["burst_gap_timer"]) <= 0.0:
			var burst_damage = float(Defs.PLANTS["repeater"]["damage"])
			_spawn_projectile(row, _cell_center(row, col) + Vector2(32.0, -10.0), Color(0.3, 0.84, 0.26), burst_damage, 0.0)
			plant["burst_remaining"] = int(plant["burst_remaining"]) - 1
			if int(plant["burst_remaining"]) > 0:
				plant["burst_gap_timer"] = float(Defs.PLANTS["repeater"]["burst_gap"])
			_trigger_plant_action(plant, 0.16)

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
	_trigger_plant_action(plant, 0.22)


func _threepeater_rows(row: int) -> Array:
	var rows: Array = []
	for lane in [row - 1, row, row + 1]:
		if lane < 0 or lane >= ROWS or not _is_row_active(lane):
			continue
		rows.append(lane)
	return rows


func _update_threepeater(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	var pf_mode = String(plant.get("plant_food_mode", ""))
	if pf_mode == "tri_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		var storm_rows = _threepeater_rows(row)
		while float(plant["plant_food_interval"]) <= 0.0:
			for lane in storm_rows:
				_spawn_projectile(lane, _threepeater_projectile_spawn_position(col, int(lane)), Color(0.38, 0.88, 0.32), 20.0, 0.0)
			plant["plant_food_interval"] += 0.1
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			_trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var center_x = _cell_center(row, col).x
	var lanes = _threepeater_rows(row)
	var has_target := false
	for lane in lanes:
		if _has_zombie_ahead(int(lane), center_x):
			has_target = true
			break
	if not has_target:
		return
	var damage = float(Defs.PLANTS["threepeater"]["damage"])
	for lane in lanes:
		_spawn_projectile(int(lane), _threepeater_projectile_spawn_position(col, int(lane)), Color(0.38, 0.88, 0.32), damage, 0.0)
	plant["shot_cooldown"] = float(Defs.PLANTS["threepeater"]["shoot_interval"])
	_trigger_plant_action(plant, 0.22)


func _threepeater_projectile_spawn_position(col: int, lane: int) -> Vector2:
	return _cell_center(lane, col) + Vector2(32.0, -10.0)


func _spawn_boomerang_projectile(row: int, spawn_position: Vector2, anchor_x: float, damage: float, max_targets: int) -> void:
	projectiles.append({
		"kind": "boomerang",
		"row": row,
		"position": spawn_position,
		"speed": 420.0,
		"velocity_y": 0.0,
		"damage": damage,
		"slow_duration": 0.0,
		"color": Color(0.96, 0.72, 0.28),
		"radius": 11.0,
		"reflected": false,
		"fire": false,
		"outbound": true,
		"anchor_x": anchor_x,
		"max_hits": max_targets,
		"hit_uids": [],
		"return_hits": [],
		"return_markers": [],
	})


func _spawn_sakura_projectile(row: int, spawn_position: Vector2, damage: float, velocity_y: float = 0.0) -> void:
	projectiles.append({
		"kind": "sakura_petal",
		"row": row,
		"position": spawn_position,
		"speed": 340.0,
		"velocity_y": velocity_y,
		"damage": damage,
		"slow_duration": 0.0,
		"color": Color(1.0, 0.68, 0.82),
		"radius": 8.0,
		"reflected": false,
		"fire": false,
		"free_aim": absf(velocity_y) > 0.01,
		"split_speed": float(Defs.PLANTS["sakura_shooter"]["split_speed"]),
	})


func _update_boomerang_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	var center = _cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "boomerang_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			_spawn_boomerang_projectile(row, center + Vector2(34.0, -10.0), center.x + 8.0, float(Defs.PLANTS["boomerang_shooter"]["damage"]) * 1.2, int(Defs.PLANTS["boomerang_shooter"]["max_targets"]) + 1)
			plant["plant_food_interval"] += 0.18
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			_trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not _has_zombie_ahead(row, center.x):
		return
	_spawn_boomerang_projectile(row, center + Vector2(34.0, -10.0), center.x + 8.0, float(Defs.PLANTS["boomerang_shooter"]["damage"]), int(Defs.PLANTS["boomerang_shooter"]["max_targets"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["boomerang_shooter"]["shoot_interval"])
	_trigger_plant_action(plant, 0.22)


func _update_sakura_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	var center = _cell_center(row, col)
	if String(plant.get("plant_food_mode", "")) == "sakura_storm" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for velocity_y in [-150.0, 0.0, 150.0]:
				_spawn_sakura_projectile(row, center + Vector2(34.0, -10.0 + velocity_y * 0.03), float(Defs.PLANTS["sakura_shooter"]["damage"]) * 1.15, velocity_y)
			plant["plant_food_interval"] += 0.16
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			_trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not _has_zombie_ahead(row, center.x):
		return
	_spawn_sakura_projectile(row, center + Vector2(34.0, -10.0), float(Defs.PLANTS["sakura_shooter"]["damage"]))
	plant["shot_cooldown"] = float(Defs.PLANTS["sakura_shooter"]["shoot_interval"])
	_trigger_plant_action(plant, 0.22)


func _update_lotus_lancer(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	var center = _cell_center(row, col)
	var range_limit = float(Defs.PLANTS["lotus_lancer"]["range"])
	if String(plant.get("plant_food_mode", "")) == "lancer_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for lane in _threepeater_rows(row):
				_damage_zombies_in_row_segment(int(lane), center.x + 18.0, center.x + range_limit, float(Defs.PLANTS["lotus_lancer"]["damage"]) * 1.4)
				effects.append({
					"shape": "lane_spray",
					"position": _cell_center(int(lane), col) + Vector2(18.0, -12.0),
					"length": range_limit,
					"width": 28.0,
					"radius": range_limit,
					"time": 0.22,
					"duration": 0.22,
					"color": Color(0.68, 0.96, 1.0, 0.28),
				})
			plant["plant_food_interval"] += 0.24
			plant["flash"] = maxf(float(plant["flash"]), 0.16)
			_trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	if not _has_zombie_ahead(row, center.x, range_limit):
		return
	_damage_zombies_in_row_segment(row, center.x + 18.0, center.x + range_limit, float(Defs.PLANTS["lotus_lancer"]["damage"]))
	effects.append({
		"shape": "lane_spray",
		"position": center + Vector2(18.0, -12.0),
		"length": range_limit,
		"width": 24.0,
		"radius": range_limit,
		"time": 0.2,
		"duration": 0.2,
		"color": Color(0.62, 0.92, 1.0, 0.24),
	})
	plant["shot_cooldown"] = float(Defs.PLANTS["lotus_lancer"]["shoot_interval"])
	_trigger_plant_action(plant, 0.22)


func _update_mirror_reed(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	var center = _cell_center(row, col)
	plant["support_timer"] -= cadence_delta
	if float(plant["support_timer"]) > 0.0:
		return
	var reveal_radius = float(Defs.PLANTS["mirror_reed"]["reveal_radius"])
	var damage_radius = maxf(float(Defs.PLANTS["mirror_reed"]["radius"]), reveal_radius * 0.9)
	var damage = float(Defs.PLANTS["mirror_reed"]["damage"])
	if String(plant.get("plant_food_mode", "")) == "mirror_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		reveal_radius += 120.0
		damage_radius += 90.0
		damage *= 1.8
		plant["plant_food_mode"] = ""
		plant["plant_food_timer"] = 0.0
	var did_hit = _damage_zombies_in_circle(center, damage_radius, damage)
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if String(zombie.get("kind", "")) != "shouyue" or not _is_enemy_zombie(zombie):
			continue
		var zombie_center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_center.distance_to(center) > reveal_radius:
			continue
		zombie["revealed_timer"] = maxf(float(zombie.get("revealed_timer", 0.0)), 3.8)
		zombies[i] = zombie
	effects.append({
		"position": center,
		"radius": reveal_radius,
		"time": 0.28,
		"duration": 0.28,
		"color": Color(0.76, 0.92, 1.0, 0.22 if did_hit else 0.16),
	})
	plant["support_timer"] = float(Defs.PLANTS["mirror_reed"]["pulse_interval"])
	plant["flash"] = maxf(float(plant["flash"]), 0.12)
	_trigger_plant_action(plant, 0.18)


func _update_frost_fan(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	var center = _cell_center(row, col)
	var range_limit = float(Defs.PLANTS["frost_fan"]["range"])
	var slow_duration = float(Defs.PLANTS["frost_fan"]["slow_duration"])
	var lanes = _threepeater_rows(row)
	if String(plant.get("plant_food_mode", "")) == "frost_gale" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		while float(plant["plant_food_interval"]) <= 0.0:
			for lane in active_rows:
				_damage_zombies_in_row_segment(int(lane), center.x + 12.0, center.x + range_limit, float(Defs.PLANTS["frost_fan"]["damage"]) * 1.35, slow_duration + 4.0)
				effects.append({
					"shape": "lane_spray",
					"position": _cell_center(int(lane), col) + Vector2(18.0, -10.0),
					"length": range_limit,
					"width": 34.0,
					"radius": range_limit,
					"time": 0.22,
					"duration": 0.22,
					"color": Color(0.82, 0.98, 1.0, 0.26),
				})
			plant["plant_food_interval"] += 0.24
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			_trigger_plant_action(plant, 0.16)
		return
	plant["shot_cooldown"] -= cadence_delta
	if float(plant["shot_cooldown"]) > 0.0:
		return
	var has_target := false
	for lane in lanes:
		if _has_zombie_ahead(int(lane), center.x, range_limit):
			has_target = true
			break
	if not has_target:
		return
	for lane in lanes:
		_damage_zombies_in_row_segment(int(lane), center.x + 16.0, center.x + range_limit, float(Defs.PLANTS["frost_fan"]["damage"]), slow_duration)
		effects.append({
			"shape": "lane_spray",
			"position": _cell_center(int(lane), col) + Vector2(18.0, -10.0),
			"length": range_limit,
			"width": 30.0,
			"radius": range_limit,
			"time": 0.2,
			"duration": 0.2,
			"color": Color(0.8, 0.98, 1.0, 0.22),
		})
	plant["shot_cooldown"] = float(Defs.PLANTS["frost_fan"]["shoot_interval"])
	_trigger_plant_action(plant, 0.22)


func _find_squash_target(row: int, center_x: float, range_limit: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not _is_enemy_zombie(zombie):
			continue
		var distance = absf(float(zombie["x"]) - center_x)
		if distance > range_limit:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _resolve_squash_impact(plant: Dictionary, row: int, col: int) -> void:
	var center = _cell_center(row, col)
	var impact_center = Vector2(float(plant.get("attack_target_x", center.x + 36.0)), _row_center_y(int(plant.get("attack_target_row", row))))
	var targets = _find_closest_zombies_in_radius(impact_center, 88.0, max(1, zombies.size()))
	if targets.is_empty():
		var fallback = _find_squash_target(row, impact_center.x, float(Defs.PLANTS["squash"]["range"]) + 30.0)
		if fallback != -1:
			targets.append(fallback)
	if targets.is_empty():
		effects.append({
			"shape": "squash_slam",
			"position": impact_center,
			"radius": 72.0,
			"time": 0.26,
			"duration": 0.26,
			"color": Color(0.66, 0.96, 0.2, 0.32),
		})
		return
	for target_index in targets:
		var zombie = zombies[int(target_index)]
		zombie = _apply_zombie_damage(zombie, float(Defs.PLANTS["squash"]["damage"]), 0.24, 0.0, true)
		zombies[int(target_index)] = zombie
	effects.append({
		"shape": "squash_slam",
		"position": impact_center,
		"radius": 88.0,
		"time": 0.3,
		"duration": 0.3,
		"color": Color(0.66, 0.96, 0.2, 0.38),
	})


func _update_squash(plant: Dictionary, row: int, col: int, delta: float = 0.0) -> bool:
	var center = _cell_center(row, col)
	var state = String(plant.get("special_state", ""))
	if state == "":
		var target_index = _find_squash_target(row, center.x, float(Defs.PLANTS["squash"]["range"]))
		if target_index == -1:
			return false
		var target = zombies[target_index]
		plant["special_state"] = "windup"
		plant["special_duration"] = 0.18
		plant["special_timer"] = 0.18
		plant["attack_target_x"] = float(target["x"])
		plant["attack_target_row"] = int(target["row"])
		plant["attack_has_hit"] = false
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.14)
		_trigger_plant_action(plant, 0.22)
		return false
	plant["special_timer"] = maxf(0.0, float(plant.get("special_timer", 0.0)) - delta)
	match state:
		"windup":
			if float(plant["special_timer"]) > 0.0:
				return false
			plant["special_state"] = "launch"
			plant["special_duration"] = 0.16
			plant["special_timer"] = 0.16
			_trigger_plant_action(plant, 0.16)
			return false
		"launch":
			var duration = maxf(float(plant.get("special_duration", 0.16)), 0.01)
			var progress = 1.0 - clampf(float(plant["special_timer"]) / duration, 0.0, 1.0)
			if not bool(plant.get("attack_has_hit", false)) and progress >= 0.78:
				plant["attack_has_hit"] = true
				_resolve_squash_impact(plant, row, col)
				plant["special_state"] = "slam"
				plant["special_duration"] = 0.1
				plant["special_timer"] = 0.1
			return false
		"slam":
			return float(plant["special_timer"]) <= 0.0
	return false


func _find_kelp_target(row: int, center_x: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not _is_enemy_zombie(zombie):
			continue
		var distance = absf(float(zombie["x"]) - center_x)
		if distance > float(Defs.PLANTS["tangle_kelp"]["range"]):
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _update_tangle_kelp(_plant: Dictionary, row: int, col: int) -> bool:
	var center = _cell_center(row, col)
	var target_index = _find_kelp_target(row, center.x)
	if target_index == -1:
		return false
	var zombie = zombies[target_index]
	zombie = _apply_zombie_damage(zombie, float(Defs.PLANTS["tangle_kelp"]["damage"]), 0.3, 0.0, true)
	zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.45)
	zombies[target_index] = zombie
	effects.append({
		"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + 18.0),
		"radius": 68.0,
		"time": 0.32,
		"duration": 0.32,
		"color": Color(0.18, 0.72, 0.46, 0.34),
	})
	return true


func _update_spikeweed(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["contact_timer"] -= delta
	if float(plant["contact_timer"]) > 0.0:
		return
	var center_x = _cell_center(row, col).x
	var hit := false
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not _is_enemy_zombie(zombie):
			continue
		if absf(float(zombie["x"]) - center_x) > 42.0:
			continue
		zombie = _apply_zombie_damage(zombie, float(Defs.PLANTS["spikeweed"]["contact_damage"]), 0.1)
		zombies[i] = zombie
		hit = true
	if hit:
		plant["flash"] = maxf(float(plant["flash"]), 0.12)
		_trigger_plant_action(plant, 0.14)
	plant["contact_timer"] = float(Defs.PLANTS["spikeweed"]["contact_interval"])


func _update_torchwood(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if String(plant.get("plant_food_mode", "")) != "fire_storm" or float(plant.get("plant_food_timer", 0.0)) <= 0.0:
		return
	plant["plant_food_interval"] -= delta
	while float(plant["plant_food_interval"]) <= 0.0:
		for lane in active_rows:
			_spawn_fire_projectile(int(lane), _cell_center(row, col) + Vector2(18.0, -10.0), 40.0, 520.0, 9.0)
		plant["plant_food_interval"] += 0.14
		plant["flash"] = maxf(float(plant["flash"]), 0.16)
		_trigger_plant_action(plant, 0.16)


func _update_vine_lasher(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = _cell_center(row, col).x
	var range_limit = float(Defs.PLANTS["vine_lasher"]["range"])
	var target_index = _find_lane_target(row, center_x, range_limit)
	var hit := false
	if target_index == -1:
		if not _damage_obstacles_in_radius(row, center_x + range_limit * 0.5, range_limit * 0.5, float(Defs.PLANTS["vine_lasher"]["damage"])):
			plant["attack_timer"] = 0.2
			return
		hit = true
	else:
		var zombie = zombies[target_index]
		zombie = _apply_zombie_damage(zombie, float(Defs.PLANTS["vine_lasher"]["damage"]), 0.16, float(Defs.PLANTS["vine_lasher"]["slow_duration"]))
		zombies[target_index] = zombie
		hit = true
	if hit:
		effects.append({
			"shape": "lane_spray",
			"position": _cell_center(row, col) + Vector2(18.0, -6.0),
			"length": range_limit,
			"width": 54.0,
			"radius": range_limit * 0.5,
			"time": 0.2,
			"duration": 0.2,
			"color": Color(0.42, 0.94, 0.34, 0.24),
		})
	plant["flash"] = maxf(float(plant["flash"]), 0.12)
	plant["attack_timer"] = float(Defs.PLANTS["vine_lasher"]["attack_interval"])
	_trigger_plant_action(plant, 0.22)


func _update_pepper_mortar(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target_index = _find_frontmost_zombie(row)
	var impact_x := 0.0
	if target_index == -1:
		impact_x = _find_frontmost_obstacle_x(row)
		if impact_x < -1000.0:
			plant["attack_timer"] = 0.25
			return
	else:
		var zombie = zombies[target_index]
		impact_x = float(zombie["x"])
	var impact = Vector2(impact_x, _row_center_y(row))
	_damage_zombies_in_radius(row, impact.x, float(Defs.PLANTS["pepper_mortar"]["splash_radius"]), float(Defs.PLANTS["pepper_mortar"]["damage"]))
	_damage_obstacles_in_radius(row, impact.x, float(Defs.PLANTS["pepper_mortar"]["splash_radius"]), float(Defs.PLANTS["pepper_mortar"]["damage"]))
	effects.append({
		"position": impact,
		"radius": float(Defs.PLANTS["pepper_mortar"]["splash_radius"]),
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.42, 0.12, 0.56),
	})
	plant["flash"] = maxf(float(plant["flash"]), 0.16)
	plant["attack_timer"] = float(Defs.PLANTS["pepper_mortar"]["attack_interval"])
	_trigger_plant_action(plant, 0.28)


func _update_pulse_bulb(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["pulse_timer"] -= cadence_delta
	if float(plant["pulse_timer"]) > 0.0:
		return
	var center = _cell_center(row, col)
	var radius = float(Defs.PLANTS["pulse_bulb"].get("radius", 175.0))
	var did_hit = false
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) > radius:
			continue
		zombie = _apply_zombie_damage(zombie, float(Defs.PLANTS["pulse_bulb"]["damage"]), 0.12)
		zombies[i] = zombie
		did_hit = true
	if _damage_obstacles_in_circle(center, radius, float(Defs.PLANTS["pulse_bulb"]["damage"])):
		did_hit = true
	if did_hit:
		effects.append({
			"position": center,
			"radius": radius,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.98, 0.94, 0.36, 0.34),
		})
		_trigger_plant_action(plant, 0.26)
	plant["flash"] = maxf(float(plant["flash"]), 0.14)
	plant["pulse_timer"] = float(Defs.PLANTS["pulse_bulb"]["pulse_interval"])


func _update_sun_bean(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) <= 0.0:
		var center = _cell_center(row, col)
		_spawn_sun(center + Vector2(rng.randf_range(-8.0, 8.0), -18.0), center.y - 10.0, "plant")
		plant["sun_timer"] = float(Defs.PLANTS["sun_bean"]["sun_interval"])
		_trigger_plant_action(plant, 0.32)
	_update_basic_shooter(plant, delta, row, col, Color(0.94, 0.78, 0.22), 0.0)


func _update_sun_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if not bool(plant["mature"]):
		plant["grow_timer"] = maxf(0.0, float(plant["grow_timer"]) - delta)
		if float(plant["grow_timer"]) <= 0.0:
			plant["mature"] = true
			plant["flash"] = maxf(float(plant["flash"]), 0.2)
			_trigger_plant_action(plant, 0.36)

	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) > 0.0:
		return

	var center = _cell_center(row, col)
	var sun_value = SUN_VALUE if bool(plant["mature"]) else int(SUN_VALUE * 0.5)
	_spawn_sun(center + Vector2(rng.randf_range(-8.0, 8.0), -18.0), center.y - 10.0, "plant", sun_value)
	plant["sun_timer"] = float(Defs.PLANTS["sun_shroom"]["sun_interval"])
	_trigger_plant_action(plant, 0.34)


func _update_fume_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	if String(plant.get("plant_food_mode", "")) == "fume_burst" and float(plant.get("plant_food_timer", 0.0)) > 0.0:
		plant["plant_food_interval"] -= cadence_delta
		var burst_center = _cell_center(row, col)
		var burst_range = float(Defs.PLANTS["fume_shroom"]["range"]) + 80.0
		var burst_damage = 72.0
		while float(plant["plant_food_interval"]) <= 0.0:
			var burst_hit := false
			for i in range(zombies.size()):
				var zombie = zombies[i]
				if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not _is_enemy_zombie(zombie):
					continue
				var distance = float(zombie["x"]) - burst_center.x
				if distance < -20.0 or distance > burst_range:
					continue
				zombie = _apply_zombie_damage(zombie, burst_damage, 0.16, 0.0, true)
				zombies[i] = zombie
				burst_hit = true
			if _damage_obstacles_in_radius(row, burst_center.x + burst_range * 0.5, burst_range * 0.5, burst_damage):
				burst_hit = true
			effects.append({
				"shape": "lane_spray",
				"position": burst_center + Vector2(28.0, -8.0),
				"length": burst_range,
				"width": float(Defs.PLANTS["fume_shroom"].get("width", 92.0)) * 1.45,
				"radius": burst_range * 0.58,
				"time": 0.22,
				"duration": 0.22,
				"color": Color(0.92, 0.72, 1.0, 0.34 if burst_hit else 0.22),
			})
			plant["plant_food_interval"] += 0.12
			plant["flash"] = maxf(float(plant["flash"]), 0.18)
			_trigger_plant_action(plant, 0.18)
		return

	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return

	var center = _cell_center(row, col)
	var range_limit = float(Defs.PLANTS["fume_shroom"]["range"])
	var damage = float(Defs.PLANTS["fume_shroom"]["damage"])
	var hit := false
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not _is_enemy_zombie(zombie):
			continue
		var distance = float(zombie["x"]) - center.x
		if distance < -20.0 or distance > range_limit:
			continue
		zombie = _apply_zombie_damage(zombie, damage, 0.14, 0.0, true)
		zombies[i] = zombie
		hit = true
	if _damage_obstacles_in_radius(row, center.x + range_limit * 0.5, range_limit * 0.5, damage):
		hit = true

	if hit:
		effects.append({
			"shape": "lane_spray",
			"position": center + Vector2(24.0, -8.0),
			"length": range_limit,
			"width": float(Defs.PLANTS["fume_shroom"].get("width", 92.0)) * 1.15,
			"radius": range_limit * 0.55,
			"time": 0.18,
			"duration": 0.18,
			"color": Color(0.88, 0.64, 0.98, 0.24),
		})
		plant["flash"] = maxf(float(plant["flash"]), 0.14)
		plant["attack_timer"] = float(Defs.PLANTS["fume_shroom"]["shoot_interval"])
		_trigger_plant_action(plant, 0.24)
	else:
		plant["attack_timer"] = 0.24


func _update_scaredy_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	if _update_shooter_plant_food(plant, delta, row, col, Color(0.74, 0.52, 0.98), 0.0, 3, 0.06):
		return
	var center = _cell_center(row, col)
	if _has_close_zombie(center, float(Defs.PLANTS["scaredy_shroom"]["fear_radius"])):
		plant["shot_cooldown"] = minf(float(plant["shot_cooldown"]), 0.35)
		return
	_update_basic_shooter(plant, delta, row, col, Color(0.72, 0.52, 0.98), 0.0)


func _update_grave_buster(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	plant["chew_timer"] -= delta
	var grave_index = _grave_index_at(int(plant["grave_row"]), int(plant["grave_col"]))
	if float(plant["chew_timer"]) > 0.0 and grave_index != -1:
		return false
	if grave_index != -1:
		graves.remove_at(grave_index)
		if not grave_wave_triggered:
			pending_grave_wave_spawns = max(0, pending_grave_wave_spawns - 1)
			expected_spawn_units = max(total_spawned_units + zombies.size() + batch_spawn_queue.size() + 1, _estimated_total_spawn_count())
		effects.append({
			"position": _cell_center(row, col) + Vector2(0.0, 16.0),
			"radius": 56.0,
			"time": 0.26,
			"duration": 0.26,
			"color": Color(0.34, 0.92, 0.28, 0.28),
		})
		_trigger_plant_action(plant, 0.36)
	return true


func _update_moon_lotus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["sun_timer"] -= delta
	if float(plant["sun_timer"]) <= 0.0:
		var center = _cell_center(row, col)
		_spawn_sun(center + Vector2(rng.randf_range(-10.0, 10.0), -22.0), center.y - 12.0, "plant")
		plant["sun_timer"] = float(Defs.PLANTS["moon_lotus"]["sun_interval"])
		_trigger_plant_action(plant, 0.34)
	if float(plant["support_timer"]) <= 0.0:
		var woke = _wake_plants_in_radius(_cell_center(row, col), float(Defs.PLANTS["moon_lotus"]["wake_radius"]))
		if woke > 0:
			effects.append({
				"position": _cell_center(row, col),
				"radius": float(Defs.PLANTS["moon_lotus"]["wake_radius"]),
				"time": 0.24,
				"duration": 0.24,
				"color": Color(0.72, 0.88, 1.0, 0.22),
			})
			_trigger_plant_action(plant, 0.26)
		plant["support_timer"] = float(Defs.PLANTS["moon_lotus"]["wake_interval"])


func _update_prism_grass(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = _cell_center(row, col).x
	var range_limit = float(Defs.PLANTS["prism_grass"]["range"])
	var slow_duration = float(Defs.PLANTS["prism_grass"].get("slow_duration", 0.0))
	var targets = _find_lane_targets(row, center_x, range_limit, int(Defs.PLANTS["prism_grass"]["pierce_count"]))
	if targets.is_empty():
		plant["attack_timer"] = 0.2
		return
	for zombie_index in targets:
		var zombie = zombies[zombie_index]
		zombie = _apply_zombie_damage(zombie, float(Defs.PLANTS["prism_grass"]["damage"]), 0.14, slow_duration, true)
		zombies[zombie_index] = zombie
	_damage_obstacles_in_radius(row, center_x + range_limit * 0.5, range_limit * 0.5, float(Defs.PLANTS["prism_grass"]["damage"]))
	effects.append({
		"shape": "lane_spray",
		"position": _cell_center(row, col) + Vector2(18.0, -4.0),
		"length": range_limit,
		"width": 42.0,
		"radius": range_limit * 0.5,
		"time": 0.18,
		"duration": 0.18,
		"color": Color(0.68, 0.9, 1.0, 0.28),
	})
	plant["attack_timer"] = float(Defs.PLANTS["prism_grass"]["attack_interval"])
	_trigger_plant_action(plant, 0.24)


func _update_lantern_bloom(plant: Dictionary, _delta: float, row: int, col: int) -> void:
	if float(plant["support_timer"]) > 0.0:
		return
	var center = _cell_center(row, col)
	var radius = float(Defs.PLANTS["lantern_bloom"]["radius"])
	var wake_radius = float(Defs.PLANTS["lantern_bloom"]["wake_radius"])
	var did_hit = _damage_zombies_in_circle(center, radius, float(Defs.PLANTS["lantern_bloom"]["damage"]))
	var woke = _wake_plants_in_radius(center, wake_radius)
	if did_hit or woke > 0:
		effects.append({
			"position": center,
			"radius": wake_radius,
			"time": 0.28,
			"duration": 0.28,
			"color": Color(1.0, 0.82, 0.34, 0.22),
		})
		_trigger_plant_action(plant, 0.26)
	plant["support_timer"] = float(Defs.PLANTS["lantern_bloom"]["pulse_interval"])


func _update_meteor_gourd(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var target = _find_global_frontmost_target()
	if target["row"] == -1:
		plant["attack_timer"] = 0.24
		return
	var impact = Vector2(float(target["x"]), _row_center_y(int(target["row"])))
	_damage_zombies_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]), float(Defs.PLANTS["meteor_gourd"]["damage"]))
	_damage_obstacles_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]), float(Defs.PLANTS["meteor_gourd"]["damage"]))
	effects.append({
		"position": impact,
		"radius": float(Defs.PLANTS["meteor_gourd"]["splash_radius"]),
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.54, 0.22, 0.38),
	})
	plant["attack_timer"] = float(Defs.PLANTS["meteor_gourd"]["attack_interval"])
	_trigger_plant_action(plant, 0.28)


func _update_root_snare(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = _cell_center(row, col).x
	var target_index = _find_lane_target(row, center_x, float(Defs.PLANTS["root_snare"]["range"]))
	if target_index == -1:
		plant["attack_timer"] = 0.22
		return
	var zombie = zombies[target_index]
	zombie = _apply_zombie_damage(zombie, float(Defs.PLANTS["root_snare"]["damage"]), 0.14)
	zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer", 0.0)), float(Defs.PLANTS["root_snare"]["root_duration"]))
	zombies[target_index] = zombie
	effects.append({
		"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + 12.0),
		"radius": 42.0,
		"time": 0.22,
		"duration": 0.22,
		"color": Color(0.42, 0.84, 0.28, 0.26),
	})
	plant["attack_timer"] = float(Defs.PLANTS["root_snare"]["attack_interval"])
	_trigger_plant_action(plant, 0.22)


func _update_thunder_pine(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["attack_timer"] -= cadence_delta
	if float(plant["attack_timer"]) > 0.0:
		return
	var center_x = _cell_center(row, col).x
	var target_index = _find_lane_target(row, center_x, board_size.x)
	if target_index == -1:
		plant["attack_timer"] = 0.22
		return
	var chained = _strike_thunder_chain(target_index, float(Defs.PLANTS["thunder_pine"]["damage"]), float(Defs.PLANTS["thunder_pine"]["chain_damage"]), float(Defs.PLANTS["thunder_pine"]["chain_range"]), 3)
	if chained > 0:
		_trigger_plant_action(plant, 0.28)
	plant["attack_timer"] = float(Defs.PLANTS["thunder_pine"]["attack_interval"])


func _update_dream_drum(plant: Dictionary, _delta: float, row: int, col: int) -> void:
	if float(plant["support_timer"]) > 0.0:
		return
	var center = _cell_center(row, col)
	var woke = _wake_plants_in_radius(center, float(Defs.PLANTS["dream_drum"]["wake_radius"]))
	var did_hit = _damage_zombies_in_circle(center, float(Defs.PLANTS["dream_drum"]["radius"]), float(Defs.PLANTS["dream_drum"]["damage"]))
	if woke > 0 or did_hit:
		effects.append({
			"position": center,
			"radius": float(Defs.PLANTS["dream_drum"]["wake_radius"]),
			"time": 0.3,
			"duration": 0.3,
			"color": Color(0.9, 0.78, 0.38, 0.22),
		})
		_trigger_plant_action(plant, 0.32)
	plant["support_timer"] = float(Defs.PLANTS["dream_drum"]["pulse_interval"])


func _update_wind_orchid(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var cadence_delta = _plant_cadence_delta(delta, row, col)
	plant["gust_timer"] -= cadence_delta
	if float(plant["gust_timer"]) > 0.0:
		return
	var did_push = false
	var center = _cell_center(row, col)
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
			"shape": "lane_spray",
			"position": center + Vector2(14.0, -6.0),
			"length": BOARD_ORIGIN.x + board_size.x - center.x,
			"width": CELL_SIZE.y * 0.76,
			"radius": BOARD_ORIGIN.x + board_size.x - center.x,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.72, 0.94, 1.0, 0.36),
		})
		_trigger_plant_action(plant, 0.28)
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
		"fire": false,
	})


func _spawn_fire_projectile(row: int, spawn_position: Vector2, damage: float, speed: float = 500.0, radius: float = 9.0) -> void:
	_spawn_projectile(row, spawn_position, Color(1.0, 0.54, 0.18), damage, 0.0, speed, radius)
	if not projectiles.is_empty():
		projectiles[projectiles.size() - 1]["fire"] = true


func _find_zombie_index_by_uid(uid: int) -> int:
	for i in range(zombies.size()):
		if int(zombies[i].get("uid", -1)) == uid:
			return i
	return -1


func _apply_fire_projectile_splash(row: int, center_x: float, damage: float, skip_index: int) -> void:
	var splash_radius = 48.0
	for i in range(zombies.size()):
		if i == skip_index:
			continue
		var zombie = zombies[i]
		if int(zombie["row"]) != row or not _is_enemy_zombie(zombie):
			continue
		if absf(float(zombie["x"]) - center_x) > splash_radius:
			continue
		zombie = _apply_zombie_damage(zombie, damage, 0.1)
		zombies[i] = zombie
	effects.append({
		"position": Vector2(center_x, _row_center_y(row)),
		"radius": splash_radius,
		"time": 0.2,
		"duration": 0.2,
		"color": Color(1.0, 0.52, 0.18, 0.24),
	})


func _spawn_sakura_split_projectiles(projectile: Dictionary, impact_position: Vector2) -> void:
	var child_damage = maxf(6.0, float(projectile.get("damage", 0.0)) * 0.78)
	var split_speed = float(projectile.get("split_speed", float(Defs.PLANTS["sakura_shooter"]["split_speed"])))
	for velocity_y in [-split_speed, split_speed]:
		projectiles.append({
			"kind": "sakura_petal",
			"row": int(projectile["row"]),
			"position": impact_position + Vector2(12.0, velocity_y * 0.012),
			"speed": split_speed,
			"velocity_y": velocity_y,
			"damage": child_damage,
			"slow_duration": 0.0,
			"color": Color(1.0, 0.72, 0.86),
			"radius": 7.0,
			"reflected": false,
			"fire": false,
			"free_aim": true,
			"split_speed": split_speed,
		})


func _update_boomerang_projectile(projectile: Dictionary, delta: float) -> Dictionary:
	var projectile_pos = Vector2(projectile["position"])
	projectile_pos.x += float(projectile["speed"]) * delta
	projectile["position"] = projectile_pos
	var hit_uids: Array = projectile.get("hit_uids", [])
	var return_hits: Array = projectile.get("return_hits", [])
	var return_markers: Array = projectile.get("return_markers", [])
	if bool(projectile.get("outbound", true)):
		var target_index = _find_projectile_target(projectile)
		if target_index != -1:
			var zombie = zombies[target_index]
			var uid = int(zombie.get("uid", -1))
			if not hit_uids.has(uid):
				zombie = _apply_zombie_damage(zombie, float(projectile["damage"]), 0.12)
				zombies[target_index] = zombie
				hit_uids.append(uid)
				return_markers.append({
					"uid": uid,
					"x": float(zombie["x"]),
				})
				projectile["hit_uids"] = hit_uids
				projectile["return_markers"] = return_markers
				if hit_uids.size() >= int(projectile.get("max_hits", 3)):
					projectile["outbound"] = false
					projectile["speed"] = -absf(float(projectile["speed"])) * 0.92
			else:
				projectile_pos.x += 18.0
				projectile["position"] = projectile_pos
		if projectile_pos.x >= BOARD_ORIGIN.x + board_size.x + 40.0:
			projectile["outbound"] = false
			projectile["speed"] = -absf(float(projectile["speed"])) * 0.92
	else:
		for marker_variant in return_markers:
			var marker = Dictionary(marker_variant)
			var uid = int(marker.get("uid", -1))
			if return_hits.has(uid):
				continue
			if projectile_pos.x > float(marker.get("x", projectile_pos.x)):
				continue
			var zombie_index = _find_zombie_index_by_uid(uid)
			if zombie_index != -1:
				var zombie = zombies[zombie_index]
				if _is_enemy_zombie(zombie):
					zombie = _apply_zombie_damage(zombie, float(projectile["damage"]), 0.12)
					zombies[zombie_index] = zombie
			return_hits.append(uid)
		projectile["return_hits"] = return_hits
	return projectile


func _apply_torchwood_to_projectile(projectile: Dictionary) -> Dictionary:
	if String(projectile.get("kind", "")) != "" and String(projectile.get("kind", "")) != "pea":
		return projectile
	if bool(projectile.get("fire", false)) or bool(projectile.get("reflected", false)) or float(projectile.get("speed", 0.0)) <= 0.0:
		return projectile
	var row = int(projectile["row"])
	for col in range(COLS):
		var plant_variant = grid[row][col]
		if plant_variant == null or String(plant_variant["kind"]) != "torchwood":
			continue
		var center_x = _cell_center(row, col).x
		var projectile_x = float(Vector2(projectile["position"]).x)
		if projectile_x < center_x - 20.0 or projectile_x > center_x + 20.0:
			continue
		projectile["fire"] = true
		projectile["damage"] = float(projectile["damage"]) * 2.0
		projectile["color"] = Color(1.0, 0.54, 0.18)
		projectile["radius"] = maxf(float(projectile.get("radius", 8.0)), 9.0)
		projectile["slow_duration"] = 0.0
		return projectile
	return projectile


func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile = projectiles[i]
		var projectile_pos = Vector2(projectile["position"])
		var projectile_kind = String(projectile.get("kind", "pea"))
		if projectile_kind == "boomerang":
			projectile = _update_boomerang_projectile(projectile, delta)
			projectile_pos = Vector2(projectile["position"])
		else:
			projectile_pos.x += float(projectile["speed"]) * delta
			projectile_pos.y += float(projectile.get("velocity_y", 0.0)) * delta
			projectile["position"] = projectile_pos
		projectile = _apply_torchwood_to_projectile(projectile)

		if bool(projectile.get("reflected", false)):
			var plant_target = _find_projectile_plant_target(projectile)
			if plant_target.y != -1:
				var plant = _targetable_plant_at(plant_target.x, plant_target.y)
				if plant != null:
					plant["health"] -= float(projectile["damage"])
					plant["flash"] = 0.16
					_set_targetable_plant(plant_target.x, plant_target.y, plant)
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

			zombie = _apply_zombie_damage(zombie, float(projectile["damage"]), 0.12, float(projectile["slow_duration"]))
			zombies[hit_index] = zombie
			if projectile_kind == "sakura_petal":
				_spawn_sakura_split_projectiles(projectile, Vector2(float(zombie["x"]) + 8.0, projectile_pos.y))
			elif bool(projectile.get("fire", false)):
				_apply_fire_projectile_splash(int(projectile["row"]), float(zombie["x"]), float(projectile["damage"]) * 0.55, hit_index)
			projectiles.remove_at(i)
			continue

		if projectile_kind == "boomerang":
			if not bool(projectile.get("outbound", true)) and float(projectile_pos.x) <= float(projectile.get("anchor_x", BOARD_ORIGIN.x)):
				projectiles.remove_at(i)
				continue
			if bool(projectile.get("outbound", true)) and projectile_pos.x > BOARD_ORIGIN.x + board_size.x + 120.0:
				projectiles.remove_at(i)
				continue
			projectiles[i] = projectile
			continue

		if projectile_pos.x > BOARD_ORIGIN.x + board_size.x + 120.0:
			projectiles.remove_at(i)
			continue
		if projectile_pos.y < BOARD_ORIGIN.y - 120.0 or projectile_pos.y > BOARD_ORIGIN.y + board_size.y + 120.0:
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
			zombie = _apply_zombie_damage(zombie, float(roller["damage"]), 0.2)
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
		if float(roller["x"]) > BOARD_ORIGIN.x + board_size.x + 120.0:
			rollers.remove_at(i)
			continue
		rollers[i] = roller


func _update_zombies(delta: float) -> void:
	for i in range(zombies.size()):
		var zombie = zombies[i]
		zombie["flash"] = maxf(0.0, float(zombie["flash"]) - delta)
		zombie["slow_timer"] = maxf(0.0, float(zombie["slow_timer"]) - delta)
		zombie["rooted_timer"] = maxf(0.0, float(zombie.get("rooted_timer", 0.0)) - delta)
		zombie["bite_timer"] = maxf(0.0, float(zombie.get("bite_timer", 0.0)) - delta)
		zombie["impact_timer"] = maxf(0.0, float(zombie.get("impact_timer", 0.0)) - delta)
		zombie["special_pause_timer"] = maxf(0.0, float(zombie.get("special_pause_timer", 0.0)) - delta)
		zombie["revealed_timer"] = maxf(0.0, float(zombie.get("revealed_timer", 0.0)) - delta)
		zombie["jump_offset"] = 0.0
		if float(zombie.get("reflect_timer", 0.0)) > 0.0:
			zombie["reflect_timer"] = maxf(0.0, float(zombie["reflect_timer"]) - delta)
		elif String(zombie["kind"]) == "kungfu":
			zombie["reflect_cooldown"] = maxf(0.0, float(zombie["reflect_cooldown"]) - delta)
			if float(zombie["reflect_cooldown"]) <= 0.0:
				zombie["reflect_timer"] = 3.0
				zombie["reflect_cooldown"] = 5.0

		if String(zombie["kind"]) == "basketball" and float(zombie.get("shield_health", 0.0)) <= 0.0 and int(zombie.get("shield_regens_left", 0)) > 0:
			zombie["shield_regen_timer"] = maxf(0.0, float(zombie.get("shield_regen_timer", 0.0)) - delta)
			if float(zombie["shield_regen_timer"]) <= 0.0:
				zombie["shield_health"] = float(Defs.ZOMBIES["basketball"]["shield_health"])
				zombie["max_shield_health"] = float(Defs.ZOMBIES["basketball"]["shield_health"])
				zombie["shield_regens_left"] = int(zombie["shield_regens_left"]) - 1
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.28)
				effects.append({
					"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 14.0),
					"radius": 58.0,
					"time": 0.22,
					"duration": 0.22,
					"color": Color(0.98, 0.64, 0.18, 0.24),
				})
		if String(zombie["kind"]) == "snorkel":
			zombie["submerged"] = _is_enemy_zombie(zombie) and _is_water_row(int(zombie["row"])) and _find_bite_target(int(zombie["row"]), float(zombie["x"])).y == -1 and not bool(zombie.get("jumping", false))
		if String(zombie["kind"]) == "bobsled_team":
			var bobsled_col = _zombie_cell_col(float(zombie["x"]))
			zombie["on_ice"] = _has_ice_tile(int(zombie["row"]), bobsled_col)
			zombie["base_speed"] = float(Defs.ZOMBIES["bobsled_team"]["speed"]) if bool(zombie["on_ice"]) else float(Defs.ZOMBIES["bobsled_team"]["off_ice_speed"])

		if String(zombie["kind"]) == "nether":
			zombie["sleep_cooldown"] = maxf(0.0, float(zombie.get("sleep_cooldown", 0.0)) - delta)
			if float(zombie["sleep_cooldown"]) <= 0.0:
				var sleep_center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
				var sleep_radius = float(Defs.ZOMBIES["nether"]["sleep_radius"])
				var sleep_duration = float(Defs.ZOMBIES["nether"]["sleep_duration"])
				var slept := 0
				if bool(zombie.get("hypnotized", false)):
					slept = _sleep_zombies_in_radius(sleep_center, sleep_radius, sleep_duration, false, i)
				else:
					slept = _sleep_plants_in_radius(sleep_center, sleep_radius, sleep_duration)
				if slept > 0:
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.24)
					effects.append({
						"position": sleep_center + Vector2(0.0, -18.0),
						"radius": sleep_radius,
						"time": 0.26,
						"duration": 0.26,
						"color": Color(0.7, 0.72, 1.0, 0.2),
					})
				zombie["sleep_cooldown"] = 4.4

		if String(zombie["kind"]) == "ice_block":
			zombie["ice_drop_cooldown"] = maxf(0.0, float(zombie.get("ice_drop_cooldown", 0.0)) - delta)
			if float(zombie["ice_drop_cooldown"]) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				_set_ice_tile(int(zombie["row"]), _zombie_cell_col(float(zombie["x"])))
				zombie["ice_drop_cooldown"] = 6.6
				zombie["special_pause_timer"] = 0.2
				effects.append({
					"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + 14.0),
					"radius": 52.0,
					"time": 0.26,
					"duration": 0.26,
					"color": Color(0.72, 0.94, 1.0, 0.24),
				})

		if String(zombie["kind"]) == "ninja" and not bool(zombie.get("ninja_dashed", false)) and float(zombie["health"]) <= float(zombie["max_health"]) * 0.5:
			var target_row = _choose_adjacent_active_row(int(zombie["row"]))
			zombie["ninja_dashed"] = true
			zombie["base_speed"] = float(Defs.ZOMBIES["ninja"]["dash_speed"])
			zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.12)
			if target_row != int(zombie["row"]):
				zombie["jumping"] = true
				zombie["jump_t"] = 0.0
				zombie["jump_from_x"] = float(zombie["x"])
				zombie["jump_to_x"] = float(zombie["x"]) + 34.0
				zombie["jump_duration"] = 0.42
				zombie["jump_row_to"] = target_row
				zombie["jump_row_switched"] = false

		if String(zombie["kind"]) == "nezha" and not bool(zombie.get("nezha_dived", false)):
			var dive_target = _pick_nezha_target(zombie)
			zombie["nezha_dived"] = true
			zombie["nezha_target_col"] = int(dive_target["col"])
			zombie["jumping"] = true
			zombie["jump_t"] = 0.0
			zombie["jump_from_x"] = float(zombie["x"])
			zombie["jump_to_x"] = float(dive_target["x"])
			zombie["jump_duration"] = 0.56
			zombie["jump_row_to"] = int(dive_target["row"])
			zombie["jump_row_switched"] = false
			zombie["special_pause_timer"] = 0.0

		if _is_boss_zombie(zombie):
			var new_phase = _boss_phase_from_ratio(float(zombie["health"]) / maxf(float(zombie["max_health"]), 1.0))
			if new_phase > int(zombie["boss_phase"]):
				zombie["boss_phase"] = new_phase
				zombie = _trigger_boss_phase_shift(zombie, new_phase)
				zombie["boss_skill_timer"] = 1.2
				zombie["boss_pause_timer"] = 1.5
			if _is_hovering_boss_kind(String(zombie["kind"])):
				zombie = _update_hovering_boss(zombie, delta)
			zombie = _update_boss_reinforcements(zombie, delta)
			zombie["boss_skill_timer"] = maxf(0.0, float(zombie["boss_skill_timer"]) - delta)
			zombie["boss_pause_timer"] = maxf(0.0, float(zombie["boss_pause_timer"]) - delta)
			if float(zombie["boss_skill_timer"]) <= 0.0:
				zombie = _trigger_boss_skill(zombie)
				var cycle_length = 4 if String(zombie["kind"]) == "rumia_boss" else 3
				zombie["boss_skill_cycle"] = (int(zombie["boss_skill_cycle"]) + 1) % cycle_length
				var base_interval = 6.0 if String(zombie["kind"]) == "rumia_boss" else 7.6
				zombie["boss_skill_timer"] = maxf(3.6, base_interval - float(zombie["boss_phase"]) * 0.8)
				zombie["boss_pause_timer"] = 1.3

		if String(zombie["kind"]) == "dancing":
			zombie["summon_cooldown"] = maxf(0.0, float(zombie.get("summon_cooldown", 0.0)) - delta)
			var summon_ready = float(zombie["summon_cooldown"]) <= 0.0
			var entered_stage = float(zombie["x"]) <= BOARD_ORIGIN.x + board_size.x * 0.9
			if summon_ready and entered_stage:
				var nearby_backup = _count_backup_dancers_near(int(zombie["row"]), float(zombie["x"]))
				if not bool(zombie.get("dance_summoned", false)) or nearby_backup < 2:
					_spawn_backup_dancers(zombie)
					zombie["dance_summoned"] = true
					zombie["summon_cooldown"] = 6.0
					zombie["special_pause_timer"] = 0.78
					effects.append({
						"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 12.0),
						"radius": 86.0,
						"time": 0.32,
						"duration": 0.32,
						"color": Color(0.92, 0.2, 0.84, 0.24),
					})

		if bool(zombie["jumping"]):
			zombie["jump_t"] += delta / maxf(float(zombie.get("jump_duration", 0.34)), 0.01)
			var jump_ratio = clampf(float(zombie["jump_t"]), 0.0, 1.0)
			zombie["x"] = lerpf(float(zombie["jump_from_x"]), float(zombie["jump_to_x"]), jump_ratio)
			if not bool(zombie.get("jump_row_switched", true)) and jump_ratio >= 0.5:
				zombie["row"] = int(zombie.get("jump_row_to", zombie["row"]))
				zombie["jump_row_switched"] = true
			zombie["jump_offset"] = -sin(jump_ratio * PI) * 54.0
			if jump_ratio >= 1.0:
				zombie["jumping"] = false
				zombie["has_vaulted"] = true
				zombie["jump_offset"] = 0.0
				if String(zombie["kind"]) == "pole_vault":
					zombie["base_speed"] = float(Defs.ZOMBIES["pole_vault"]["post_jump_speed"])
				elif String(zombie["kind"]) == "dolphin_rider":
					zombie["base_speed"] = float(Defs.ZOMBIES["dolphin_rider"]["post_jump_speed"])
				elif String(zombie["kind"]) == "nezha":
					zombie["burn_timer"] = 4.2
					_apply_nezha_landing(zombie)
			elif String(zombie["kind"]) == "ninja":
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.16)
			zombies[i] = zombie
			continue

		if (String(zombie["kind"]) == "pole_vault" or String(zombie["kind"]) == "dolphin_rider") and not bool(zombie["has_vaulted"]):
			var jump_target = _find_jump_target(int(zombie["row"]), float(zombie["x"]))
			if jump_target.y != -1:
				var jump_plant = grid[jump_target.x][jump_target.y]
				if jump_plant != null and String(jump_plant["kind"]) == "tallnut":
					zombie["has_vaulted"] = true
					if String(zombie["kind"]) == "pole_vault":
						zombie["base_speed"] = float(Defs.ZOMBIES["pole_vault"]["post_jump_speed"])
					else:
						zombie["base_speed"] = float(Defs.ZOMBIES["dolphin_rider"]["post_jump_speed"])
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.16)
					zombies[i] = zombie
					continue
				var plant_center_x = _cell_center(jump_target.x, jump_target.y).x
				zombie["jumping"] = true
				zombie["jump_t"] = 0.0
				zombie["jump_from_x"] = float(zombie["x"])
				zombie["jump_to_x"] = maxf(BOARD_ORIGIN.x - 18.0, plant_center_x - CELL_SIZE.x + (4.0 if String(zombie["kind"]) == "dolphin_rider" else 8.0))
				zombie["jump_duration"] = 0.34
				zombie["jump_row_to"] = int(zombie["row"])
				zombie["jump_row_switched"] = true
				zombies[i] = zombie
				continue

		if String(zombie["kind"]) == "farmer":
			zombie["weed_pause_timer"] = maxf(0.0, float(zombie["weed_pause_timer"]) - delta)
			var current_col = int(floor((float(zombie["x"]) - BOARD_ORIGIN.x) / CELL_SIZE.x))
			if current_col < int(zombie["last_cell_col"]):
				zombie["last_cell_col"] = current_col
				if _spawn_farmer_weed(int(zombie["row"]), current_col - 1):
					zombie["weed_pause_timer"] = 0.55
		if String(zombie["kind"]) == "zomboni":
			var zomboni_row = int(zombie["row"])
			var spike_cell = _find_plant_cell_by_kind(zomboni_row, "spikeweed", float(zombie["x"]), 42.0)
			if spike_cell.y != -1:
				grid[spike_cell.x][spike_cell.y] = null
				zombie["health"] = 0.0
				effects.append({
					"position": Vector2(float(zombie["x"]), _row_center_y(zomboni_row)),
					"radius": 84.0,
					"time": 0.28,
					"duration": 0.28,
					"color": Color(1.0, 0.56, 0.18, 0.34),
				})
				zombies[i] = zombie
				continue
			var crush_cell = _find_crushable_cell(zomboni_row, float(zombie["x"]))
			if crush_cell.y != -1:
				_crush_cell(crush_cell.x, crush_cell.y)
				effects.append({
					"position": _cell_center(crush_cell.x, crush_cell.y),
					"radius": 52.0,
					"time": 0.18,
					"duration": 0.18,
					"color": Color(0.82, 0.92, 1.0, 0.2),
				})
			if float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				zombie["x"] -= _current_zombie_speed(zombie) * delta
			_set_ice_tile(zomboni_row, _zombie_cell_col(float(zombie["x"])))
			var zomboni_mower = mowers[int(zombie["row"])]
			if float(zombie["x"]) <= BOARD_ORIGIN.x - 24.0:
				if bool(zomboni_mower["armed"]):
					zomboni_mower["armed"] = false
					zomboni_mower["active"] = true
					mowers[int(zombie["row"])] = zomboni_mower
				elif not bool(zomboni_mower["active"]):
					_lose_level()
					return
				zombies[i] = zombie
				continue

		if bool(zombie.get("hypnotized", false)):
			var enemy_target_index = _find_zombie_contact_target(i, int(zombie["row"]), float(zombie["x"]), false)
			if enemy_target_index != -1:
				var enemy_zombie = zombies[enemy_target_index]
				enemy_zombie = _apply_zombie_damage(enemy_zombie, float(zombie["attack_dps"]) * delta, 0.12)
				zombies[enemy_target_index] = enemy_zombie
				zombie["bite_timer"] = maxf(float(zombie.get("bite_timer", 0.0)), 0.18)
			elif float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				zombie["x"] += _current_zombie_speed(zombie) * delta
				if float(zombie["x"]) >= BOARD_ORIGIN.x + board_size.x + 120.0:
					zombie["health"] = 0.0
			zombies[i] = zombie
			continue

		var hypnotized_target_index = _find_zombie_contact_target(i, int(zombie["row"]), float(zombie["x"]), true)
		if hypnotized_target_index != -1:
			var hypnotized_target = zombies[hypnotized_target_index]
			hypnotized_target = _apply_zombie_damage(hypnotized_target, float(zombie["attack_dps"]) * delta, 0.12)
			zombies[hypnotized_target_index] = hypnotized_target
			zombie["bite_timer"] = maxf(float(zombie.get("bite_timer", 0.0)), 0.18)
			zombies[i] = zombie
			continue

		if String(zombie["kind"]) == "dragon_boat":
			zombie = _update_dragon_boat_motion(zombie, delta)
			var boat_mower = mowers[int(zombie["row"])]
			if float(zombie["x"]) <= BOARD_ORIGIN.x - 24.0:
				if bool(boat_mower["armed"]):
					boat_mower["armed"] = false
					boat_mower["active"] = true
					mowers[int(zombie["row"])] = boat_mower
				elif not bool(boat_mower["active"]):
					_lose_level()
					return
			zombies[i] = zombie
			continue

		if String(zombie["kind"]) == "shouyue":
			zombie["snipe_cooldown"] = maxf(0.0, float(zombie.get("snipe_cooldown", 0.0)) - delta)
			var snipe_target = _find_front_plant_target(int(zombie["row"]), float(zombie["x"]))
			if bool(zombie.get("snipe_charge_active", false)) and snipe_target.y == -1:
				zombie["snipe_charge_active"] = false
				zombie["snipe_charge_timer"] = 0.0
				zombie["snipe_focus_timer"] = 0.0
				zombie["snipe_target_row"] = -1
				zombie["snipe_target_col"] = -1
			if snipe_target.y != -1:
				if not bool(zombie.get("snipe_charge_active", false)) and float(zombie.get("special_pause_timer", 0.0)) <= 0.0 and float(zombie["snipe_cooldown"]) <= 0.0:
					zombie = _begin_shouyue_charge(zombie, snipe_target)
				if bool(zombie.get("snipe_charge_active", false)):
					zombie["snipe_target_row"] = snipe_target.x
					zombie["snipe_target_col"] = snipe_target.y
					zombie["snipe_focus_timer"] = maxf(0.0, float(zombie.get("snipe_focus_timer", 0.0)) - delta)
					if float(zombie["snipe_focus_timer"]) <= 0.0:
						_spawn_shouyue_focus_effect(zombie, snipe_target)
						zombie["snipe_focus_timer"] = 0.06
					zombie["snipe_charge_timer"] = maxf(0.0, float(zombie.get("snipe_charge_timer", 0.0)) - delta)
					if float(zombie["snipe_charge_timer"]) <= 0.0:
						zombie = _fire_shouyue_snipe(zombie, snipe_target)
				zombies[i] = zombie
				continue

		var target = _find_bite_target(int(zombie["row"]), float(zombie["x"]))
		if target.y != -1:
			var plant = _targetable_plant_at(target.x, target.y)
			if plant != null and String(plant["kind"]) == "hypno_shroom" and not _is_boss_zombie(zombie):
				zombie = _hypnotize_zombie(zombie)
				zombie["bite_timer"] = maxf(float(zombie.get("bite_timer", 0.0)), 0.18)
				_clear_targetable_plant(target.x, target.y)
				effects.append({
					"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 6.0),
					"radius": 76.0,
					"time": 0.34,
					"duration": 0.34,
					"color": Color(0.88, 0.42, 1.0, 0.3),
				})
				zombies[i] = zombie
				continue
			var bite_damage = float(zombie["attack_dps"]) * delta
			zombie["bite_timer"] = maxf(float(zombie.get("bite_timer", 0.0)), 0.18)
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
				zombie = _apply_zombie_damage(zombie, float(Defs.PLANTS["cactus_guard"]["thorns"]) * delta, 0.08)
			plant["flash"] = 0.08
			_set_targetable_plant(target.x, target.y, plant)
		else:
			var should_pause = false
			if String(zombie["kind"]) == "kungfu" and float(zombie["reflect_timer"]) > 0.0:
				should_pause = true
			if String(zombie["kind"]) == "farmer" and float(zombie["weed_pause_timer"]) > 0.0:
				should_pause = true
			if _is_boss_zombie(zombie) and float(zombie.get("boss_pause_timer", 0.0)) > 0.0:
				should_pause = true
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				should_pause = true
			if not should_pause:
				if _is_boss_zombie(zombie) and not _is_hovering_boss_kind(String(zombie["kind"])):
					zombie["base_speed"] = float(Defs.ZOMBIES[String(zombie["kind"])]["speed"]) + float(zombie["boss_phase"]) * 1.6
				if not _is_hovering_boss_kind(String(zombie["kind"])):
					zombie["x"] -= _current_zombie_speed(zombie) * delta

		if String(zombie["kind"]) == "nezha" and float(zombie.get("burn_timer", 0.0)) > 0.0:
			zombie["burn_timer"] = maxf(0.0, float(zombie["burn_timer"]) - delta)
			_damage_plants_in_circle(
				Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + 18.0),
				64.0,
				float(Defs.ZOMBIES["nezha"]["burn_dps"]) * delta
			)

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
		if float(mower["x"]) > BOARD_ORIGIN.x + board_size.x + 120.0:
			mower["active"] = false
			mower["x"] = BOARD_ORIGIN.x + board_size.x + 160.0
		mowers[i] = mower


func _spawn_sun(spawn_position: Vector2, target_y: float, source: String, value: int = SUN_VALUE) -> void:
	var settle_speed = 165.0 if source == "sky" else 122.0
	var auto_delay = 0.65 if source == "sky" else 0.75
	if source == "plant_food":
		auto_delay = 0.2
	suns.append({
			"position": spawn_position,
			"target_y": target_y,
			"velocity": Vector2(rng.randf_range(-12.0, 12.0), settle_speed),
			"life": 12.0,
			"value": value,
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
	for i in range(porcelain_shards.size() - 1, -1, -1):
		var shard = porcelain_shards[i]
		shard["time"] = maxf(0.0, float(shard.get("time", 0.0)) - delta)
		if float(shard["time"]) <= 0.0:
			porcelain_shards.remove_at(i)
			continue
		porcelain_shards[i] = shard
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
	for row in range(ROWS):
		for col in range(COLS):
			var support_variant = support_grid[row][col]
			if support_variant == null:
				continue
			if float(support_variant["health"]) <= 0.0:
				support_grid[row][col] = null
				grid[row][col] = null


func _cleanup_dead_zombies() -> void:
	for i in range(zombies.size() - 1, -1, -1):
		var zombie = zombies[i]
		if float(zombie["health"]) > 0.0:
			continue
		total_kills += 1
		if _is_stage_ending_boss(zombie):
			batch_spawn_queue = []
			batch_spawn_remaining = 0
			next_event_index = current_level["events"].size()
			_show_banner("Boss 被击退！清理残余僵尸即可过关", 2.4)
		if String(zombie["kind"]) == "spear":
			_spawn_spear_obstacle(int(zombie["row"]), float(zombie["x"]))
		if bool(zombie.get("plant_food_carrier", false)):
			_spawn_plant_food_pickup(Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 28.0))
		if _is_whack_level():
			var sun_chance = 0.38 if bool(zombie.get("whacked", false)) else 0.22
			if rng.randf() < sun_chance:
				_spawn_sun(
					Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 18.0),
					_row_center_y(int(zombie["row"])) - 36.0,
					"plant",
					75
				)
		else:
			var reward = int(Defs.ZOMBIES[String(zombie["kind"])]["reward"])
			_spawn_coin(Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 18.0), reward)
		zombies.remove_at(i)


func _check_end_state() -> void:
	if _can_finish_level_ignoring_obstacles():
		_win_level()


func _win_level() -> void:
	if battle_state != BATTLE_PLAYING:
		return

	battle_state = BATTLE_WON
	completed_levels[selected_level_index] = true
	if not current_level.is_empty():
		current_world_key = _world_key_for_level(current_level)

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
	if toast_label == null:
		return
	toast_label.text = text
	toast_timer = 1.2
	toast_label.visible = true


func _show_banner(text: String, duration: float) -> void:
	if banner_label == null:
		return
	banner_label.text = text
	banner_timer = duration
	banner_label.visible = true


func _update_overlay_timers(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer = maxf(0.0, toast_timer - delta)
		toast_label.visible = toast_timer > 0.0
	var toast_ratio = clampf(toast_timer / 1.2, 0.0, 1.0)
	toast_label.modulate = Color(1.0, 1.0, 1.0, minf(1.0, toast_ratio * 1.45))
	toast_label.position = Vector2(0.0, -8.0 * (1.0 - toast_ratio))

	if banner_timer > 0.0:
		banner_timer = maxf(0.0, banner_timer - delta)
		banner_label.visible = banner_timer > 0.0
	var banner_ratio = clampf(banner_timer / 2.0, 0.0, 1.0)
	banner_label.modulate = Color(1.0, 1.0, 1.0, minf(1.0, banner_ratio * 1.3))
	banner_label.position = Vector2(0.0, -14.0 * (1.0 - banner_ratio))


func _has_zombie_ahead(row: int, plant_x: float, range_limit: float = 10000.0) -> bool:
	for zombie in zombies:
		var distance = float(zombie["x"]) - plant_x
		if int(zombie["row"]) == row and _is_enemy_zombie(zombie) and not _is_hidden_from_lane_attacks(zombie) and distance > 8.0 and distance <= range_limit:
			return true
	for weed in weeds:
		var weed_distance = float(weed["x"]) - plant_x
		if int(weed["row"]) == row and weed_distance > 8.0 and weed_distance <= range_limit:
			return true
	for spear in spears:
		var spear_distance = float(spear["x"]) - plant_x
		if int(spear["row"]) == row and spear_distance > 8.0 and spear_distance <= range_limit:
			return true
	return false


func _is_hidden_from_lane_attacks(zombie: Dictionary) -> bool:
	var kind = String(zombie.get("kind", ""))
	if kind == "snorkel":
		return bool(zombie.get("submerged", false))
	if kind != "shouyue":
		return false
	if float(zombie.get("revealed_timer", 0.0)) > 0.0:
		return false
	if bool(zombie.get("hypnotized", false)):
		return false
	var row = int(zombie.get("row", -1))
	var zombie_x = float(zombie.get("x", 0.0))
	for col in range(COLS):
		var plant = _targetable_plant_at(row, col)
		if plant == null:
			continue
		if _cell_center(row, col).x < zombie_x - 6.0:
			return false
	for other_row in range(ROWS):
		for col in range(COLS):
			var plant = _targetable_plant_at(other_row, col)
			if plant == null:
				continue
			var plant_kind = String(plant.get("kind", ""))
			if plant_kind != "lantern_bloom" and plant_kind != "dream_drum":
				continue
			if _cell_center(other_row, col).distance_to(Vector2(zombie_x, _row_center_y(row))) <= CELL_SIZE.x * 3.6:
				return false
	return true


func _is_hypnotized_zombie(zombie: Dictionary) -> bool:
	return bool(zombie.get("hypnotized", false))


func _is_boss_kind(kind: String) -> bool:
	return bool(Defs.ZOMBIES.get(kind, {}).get("boss", false))


func _is_boss_zombie(zombie: Dictionary) -> bool:
	return _is_boss_kind(String(zombie.get("kind", "")))


func _is_stage_ending_boss(zombie: Dictionary) -> bool:
	var kind = String(zombie.get("kind", ""))
	if not _is_boss_kind(kind):
		return false
	var midboss_kind = String(current_level.get("mid_boss_kind", ""))
	return kind != midboss_kind


func _is_enemy_zombie(zombie: Dictionary) -> bool:
	return not _is_hypnotized_zombie(zombie)


func _enemy_zombie_count() -> int:
	var count := 0
	for zombie in zombies:
		if _is_enemy_zombie(zombie):
			count += 1
	return count


func _hypnotize_zombie(zombie: Dictionary) -> Dictionary:
	if _is_boss_zombie(zombie):
		return zombie
	zombie["hypnotized"] = true
	zombie["submerged"] = false
	zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.24)
	zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.35)
	zombie["bite_timer"] = 0.0
	return zombie


func _find_zombie_contact_target(self_index: int, row: int, zombie_x: float, target_hypnotized: bool) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(zombies.size()):
		if i == self_index:
			continue
		var other = zombies[i]
		if int(other["row"]) != row or bool(other.get("jumping", false)):
			continue
		if bool(other.get("hypnotized", false)) != target_hypnotized:
			continue
		var distance = absf(float(other["x"]) - zombie_x)
		if distance > 34.0:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _zombie_cell_col(zombie_x: float) -> int:
	return clampi(int(floor((zombie_x - BOARD_ORIGIN.x) / CELL_SIZE.x)), 0, COLS - 1)


func _find_plant_cell_by_kind(row: int, kind: String, zombie_x: float, radius: float = 38.0) -> Vector2i:
	for col in range(COLS - 1, -1, -1):
		var plant_variant = grid[row][col]
		if plant_variant == null or String(plant_variant["kind"]) != kind:
			continue
		if absf(_cell_center(row, col).x - zombie_x) <= radius:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _find_crushable_cell(row: int, zombie_x: float, radius: float = 42.0) -> Vector2i:
	for col in range(COLS - 1, -1, -1):
		var plant_variant = _targetable_plant_at(row, col)
		if plant_variant == null:
			continue
		if absf(_cell_center(row, col).x - zombie_x) <= radius:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _crush_cell(row: int, col: int) -> void:
	grid[row][col] = null
	support_grid[row][col] = null


func _has_close_zombie(center: Vector2, radius: float) -> bool:
	for zombie in zombies:
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) <= radius:
			return true
	return false


func _mine_has_target(row: int, col: int) -> bool:
	var center_x = _cell_center(row, col).x
	for zombie in zombies:
		if int(zombie["row"]) != row or bool(zombie["jumping"]) or not _is_enemy_zombie(zombie):
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
		if int(zombie["row"]) != row or bool(zombie["jumping"]) or _is_hidden_from_lane_attacks(zombie) or not _is_enemy_zombie(zombie):
			continue
		var distance = float(zombie["x"]) - plant_x
		if distance < -8.0 or distance > range_limit:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _find_lane_targets(row: int, plant_x: float, range_limit: float, count: int) -> Array:
	var candidates: Array = []
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie["jumping"]) or _is_hidden_from_lane_attacks(zombie) or not _is_enemy_zombie(zombie):
			continue
		var distance = float(zombie["x"]) - plant_x
		if distance < -8.0 or distance > range_limit:
			continue
		candidates.append({"index": i, "distance": distance})
	var result: Array = []
	while result.size() < count and not candidates.is_empty():
		var best_pick := 0
		var best_distance = float(candidates[0]["distance"])
		for candidate_index in range(1, candidates.size()):
			var candidate_distance = float(candidates[candidate_index]["distance"])
			if candidate_distance < best_distance:
				best_distance = candidate_distance
				best_pick = candidate_index
		result.append(int(candidates[best_pick]["index"]))
		candidates.remove_at(best_pick)
	return result


func _find_global_frontmost_target() -> Dictionary:
	var best_row := -1
	var best_x := -999999.0
	for zombie in zombies:
		if bool(zombie.get("jumping", false)) or not _is_enemy_zombie(zombie):
			continue
		if float(zombie["x"]) > best_x:
			best_x = float(zombie["x"])
			best_row = int(zombie["row"])
	if best_row != -1:
		return {"row": best_row, "x": best_x}
	var obstacle_row := -1
	var obstacle_x := -999999.0
	for weed in weeds:
		if float(weed["x"]) > obstacle_x:
			obstacle_x = float(weed["x"])
			obstacle_row = int(weed["row"])
	for spear in spears:
		if float(spear["x"]) > obstacle_x:
			obstacle_x = float(spear["x"])
			obstacle_row = int(spear["row"])
	return {"row": obstacle_row, "x": obstacle_x}


func _choose_adjacent_active_row(row: int) -> int:
	var candidates: Array = []
	if row - 1 >= 0 and _is_row_active(row - 1):
		candidates.append(row - 1)
	if row + 1 < ROWS and _is_row_active(row + 1):
		candidates.append(row + 1)
	if candidates.is_empty():
		return row
	return int(candidates[rng.randi_range(0, candidates.size() - 1)])


func _pick_nezha_target(zombie: Dictionary) -> Dictionary:
	var candidates: Array = []
	for row in range(ROWS):
		if not _is_row_active(row):
			continue
		for col in range(2, COLS):
			if _targetable_plant_at(row, col) == null:
				continue
			candidates.append({"row": row, "col": col, "x": _cell_center(row, col).x})
	if not candidates.is_empty():
		return candidates[rng.randi_range(0, candidates.size() - 1)]
	return {
		"row": int(zombie["row"]),
		"col": 4,
		"x": _cell_center(int(zombie["row"]), 4).x,
	}


func _find_jump_target(row: int, zombie_x: float) -> Vector2i:
	for col in range(COLS - 1, -1, -1):
		var plant_variant = grid[row][col]
		if plant_variant == null:
			continue
		if _is_low_profile_kind(String(plant_variant["kind"])):
			continue
		var center_x = _cell_center(row, col).x
		if zombie_x <= center_x + 82.0 and zombie_x >= center_x + 12.0:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _find_bite_target(row: int, zombie_x: float) -> Vector2i:
	for col in range(COLS - 1, -1, -1):
		var plant_variant = _targetable_plant_at(row, col)
		if plant_variant == null:
			continue
		if _is_low_profile_kind(String(plant_variant["kind"])):
			continue
		var center_x = _cell_center(row, col).x
		if zombie_x <= center_x + 38.0 and zombie_x >= center_x - 20.0:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _find_front_plant_target(row: int, zombie_x: float) -> Vector2i:
	for col in range(COLS - 1, -1, -1):
		var plant_variant = _targetable_plant_at(row, col)
		if plant_variant == null:
			continue
		if _cell_center(row, col).x < zombie_x - 6.0:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _spawn_shouyue_focus_effect(zombie: Dictionary, target: Vector2i) -> void:
	var target_center = _cell_center(target.x, target.y) + Vector2(0.0, -10.0)
	effects.append({
		"shape": "sniper_focus",
		"position": Vector2(float(zombie["x"]) - 4.0, _row_center_y(int(zombie["row"])) - 22.0),
		"target": target_center,
		"time": 0.16,
		"duration": 0.16,
		"color": Color(0.92, 0.98, 1.0, 0.34),
		"anim_speed": 8.2,
	})


func _begin_shouyue_charge(zombie: Dictionary, target: Vector2i) -> Dictionary:
	zombie["snipe_charge_active"] = true
	zombie["snipe_target_row"] = target.x
	zombie["snipe_target_col"] = target.y
	zombie["snipe_charge_timer"] = float(zombie.get("snipe_charge_duration", 0.16))
	zombie["snipe_focus_timer"] = 0.0
	return zombie


func _fire_shouyue_snipe(zombie: Dictionary, target: Vector2i) -> Dictionary:
	var target_plant = _targetable_plant_at(target.x, target.y)
	if target_plant != null:
		target_plant["health"] -= float(Defs.ZOMBIES["shouyue"]["snipe_damage"])
		target_plant["flash"] = maxf(float(target_plant.get("flash", 0.0)), 0.24)
		_set_targetable_plant(target.x, target.y, target_plant)
		var target_center = _cell_center(target.x, target.y) + Vector2(0.0, -8.0)
		effects.append({
			"shape": "sniper_beam",
			"position": Vector2(float(zombie["x"]) - 6.0, _row_center_y(int(zombie["row"])) - 18.0),
			"target": target_center,
			"time": 0.72,
			"duration": 0.72,
			"color": Color(0.72, 0.96, 1.0, 0.56),
			"anim_speed": 11.0,
		})
	zombie["snipe_cooldown"] = 3.4
	zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.24)
	zombie["bite_timer"] = maxf(float(zombie.get("bite_timer", 0.0)), 0.18)
	zombie["snipe_charge_active"] = false
	zombie["snipe_charge_timer"] = 0.0
	zombie["snipe_focus_timer"] = 0.0
	zombie["snipe_target_row"] = -1
	zombie["snipe_target_col"] = -1
	return zombie


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
		if not bool(spear["spawned"]) and not _can_finish_level_ignoring_obstacles():
			_spawn_zombie_at("normal", int(spear["row"]), float(spear["x"]), true)
			spear["spawned"] = true
		spears.remove_at(i)


func _spawn_zombie_at(kind: String, row: int, x: float, reserve_progress: bool = false) -> void:
	var previous_count = zombies.size()
	_spawn_zombie(kind, row, reserve_progress)
	if zombies.size() <= previous_count:
		return
	var zombie = zombies[zombies.size() - 1]
	zombie["x"] = x
	zombies[zombies.size() - 1] = zombie


func _apply_zombie_damage(zombie: Dictionary, damage: float, flash_amount: float = 0.12, slow_duration: float = 0.0, ignore_shield: bool = false) -> Dictionary:
	if damage <= 0.0:
		return zombie

	var remaining_damage = damage
	var kind = String(zombie["kind"])
	var shield_health = float(zombie.get("shield_health", 0.0))
	if shield_health > 0.0 and not ignore_shield:
		if remaining_damage >= shield_health:
			remaining_damage -= shield_health
			zombie["shield_health"] = 0.0
			if kind == "basketball" and int(zombie.get("shield_regens_left", 0)) > 0 and float(zombie.get("shield_regen_timer", -1.0)) < 0.0:
				zombie["shield_regen_timer"] = float(Defs.ZOMBIES["basketball"]["shield_regen_cooldown"])
			if kind == "newspaper" and not bool(zombie.get("enraged", false)):
				zombie["enraged"] = true
				zombie["base_speed"] = float(Defs.ZOMBIES["newspaper"]["rage_speed"])
				zombie["special_pause_timer"] = 0.55
				effects.append({
					"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 18.0),
					"radius": 54.0,
					"time": 0.28,
					"duration": 0.28,
					"color": Color(1.0, 0.28, 0.22, 0.28),
				})
			elif kind == "qinghua":
				_add_porcelain_shard(int(zombie["row"]), _zombie_cell_col(float(zombie["x"])), 20.0)
		else:
			zombie["shield_health"] = shield_health - remaining_damage
			remaining_damage = 0.0

	if remaining_damage > 0.0:
		zombie["health"] -= remaining_damage

	zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), flash_amount)
	zombie["impact_timer"] = maxf(float(zombie.get("impact_timer", 0.0)), 0.16)
	if slow_duration > 0.0:
		zombie["slow_timer"] = maxf(float(zombie.get("slow_timer", 0.0)), slow_duration)
	return zombie


func _spawn_backup_dancers(dancing_zombie: Dictionary) -> void:
	var spawn_specs = [
		{"row": int(dancing_zombie["row"]), "x": float(dancing_zombie["x"]) + 54.0},
		{"row": int(dancing_zombie["row"]), "x": float(dancing_zombie["x"]) - 56.0},
		{"row": int(dancing_zombie["row"]) - 1, "x": float(dancing_zombie["x"]) + 18.0},
		{"row": int(dancing_zombie["row"]) + 1, "x": float(dancing_zombie["x"]) + 18.0},
	]
	for spec in spawn_specs:
		var row = int(spec["row"])
		if row < 0 or row >= ROWS or not _is_row_active(row):
			continue
		var spawn_x = clampf(float(spec["x"]), BOARD_ORIGIN.x + 42.0, BOARD_ORIGIN.x + board_size.x + 70.0)
		if _has_zombie_near_spawn("backup_dancer", row, spawn_x, 34.0):
			continue
		_spawn_zombie_at("backup_dancer", row, spawn_x, true)
		if bool(dancing_zombie.get("hypnotized", false)):
			var backup = zombies[zombies.size() - 1]
			backup = _hypnotize_zombie(backup)
			zombies[zombies.size() - 1] = backup


func _has_zombie_near_spawn(kind: String, row: int, x: float, distance: float) -> bool:
	for zombie in zombies:
		if String(zombie["kind"]) != kind or int(zombie["row"]) != row:
			continue
		if absf(float(zombie["x"]) - x) <= distance:
			return true
	return false


func _count_backup_dancers_near(row: int, x: float) -> int:
	var count := 0
	for zombie in zombies:
		if String(zombie["kind"]) != "backup_dancer":
			continue
		if abs(int(zombie["row"]) - row) > 1:
			continue
		if absf(float(zombie["x"]) - x) <= 180.0:
			count += 1
	return count


func _rumia_anchor_x() -> float:
	return BOARD_ORIGIN.x + board_size.x - 12.0


func _boss_anchor_x(_kind: String) -> float:
	return _rumia_anchor_x()


func _is_hovering_boss_kind(kind: String) -> bool:
	return kind == "rumia_boss" or kind == "daiyousei_boss" or kind == "cirno_boss"


func _next_active_row(current_row: int, direction: int) -> Dictionary:
	var rows: Array = []
	for row in active_rows:
		rows.append(int(row))
	if rows.size() <= 1:
		return {"row": current_row, "direction": direction}
	rows.sort()
	var current_index = rows.find(current_row)
	if current_index == -1:
		current_index = clampi(int(floor(float(rows.size()) * 0.5)), 0, rows.size() - 1)
	var next_direction = direction if direction != 0 else -1
	var next_index = current_index + next_direction
	if next_index < 0 or next_index >= rows.size():
		next_direction *= -1
		next_index = clampi(current_index + next_direction, 0, rows.size() - 1)
	return {"row": int(rows[next_index]), "direction": next_direction}


func _set_rumia_state(zombie: Dictionary, state: String, duration: float) -> Dictionary:
	zombie["rumia_state"] = state
	zombie["rumia_state_timer"] = duration
	return zombie


func _roll_rumia_hover_interval(phase: int) -> float:
	var min_interval = maxf(1.9, 2.6 - float(phase) * 0.18)
	var max_interval = maxf(min_interval + 0.35, 3.9 - float(phase) * 0.14)
	return rng.randf_range(min_interval, max_interval)


func _roll_hover_shift_interval(kind: String, phase: int) -> float:
	match kind:
		"daiyousei_boss":
			var min_interval = maxf(2.3, 3.1 - float(phase) * 0.18)
			var max_interval = maxf(min_interval + 0.42, 4.4 - float(phase) * 0.12)
			return rng.randf_range(min_interval, max_interval)
		"cirno_boss":
			var min_interval = maxf(2.8, 3.7 - float(phase) * 0.18)
			var max_interval = maxf(min_interval + 0.5, 4.9 - float(phase) * 0.14)
			return rng.randf_range(min_interval, max_interval)
		_:
			return _roll_rumia_hover_interval(phase)


func _choose_rumia_hover_row(current_row: int) -> int:
	var candidates: Array = []
	for row in active_rows:
		var row_i = int(row)
		if row_i != current_row:
			candidates.append(row_i)
	if candidates.is_empty():
		return current_row
	return int(candidates[rng.randi_range(0, candidates.size() - 1)])


func _update_rumia_hover(zombie: Dictionary, delta: float) -> Dictionary:
	return _update_hovering_boss(zombie, delta)


func _hover_boss_effect_tint(kind: String) -> Color:
	match kind:
		"daiyousei_boss":
			return Color(0.46, 1.0, 0.76, 0.24)
		"cirno_boss":
			return Color(0.72, 0.94, 1.0, 0.26)
		_:
			return Color(0.94, 0.08, 0.18, 0.22)


func _hover_boss_move_duration(kind: String) -> float:
	match kind:
		"daiyousei_boss":
			return 0.6
		"cirno_boss":
			return 0.7
		_:
			return 0.52


func _update_hovering_boss(zombie: Dictionary, delta: float) -> Dictionary:
	var kind = String(zombie.get("kind", ""))
	var hover_interval = _roll_hover_shift_interval(kind, int(zombie.get("boss_phase", 0)))
	zombie["x"] = _boss_anchor_x(kind)
	zombie["rumia_state_timer"] = maxf(0.0, float(zombie.get("rumia_state_timer", 0.0)) - delta)
	var move_timer = maxf(0.0, float(zombie.get("rumia_move_timer", 0.0)) - delta)
	zombie["rumia_move_timer"] = move_timer
	if move_timer <= 0.0 and String(zombie.get("rumia_state", "idle")) == "shift" and float(zombie.get("rumia_state_timer", 0.0)) <= 0.0:
		zombie["rumia_state"] = "idle"
	zombie["hover_shift_timer"] = float(zombie.get("hover_shift_timer", hover_interval)) - delta
	if float(zombie["hover_shift_timer"]) > 0.0:
		return zombie
	var current_row = int(zombie["row"])
	var target_row = _choose_rumia_hover_row(current_row)
	if target_row != int(zombie["row"]):
		var move_duration = _hover_boss_move_duration(kind)
		zombie["rumia_move_from_y"] = _row_center_y(current_row)
		zombie["rumia_move_to_y"] = _row_center_y(target_row)
		zombie["rumia_move_duration"] = move_duration
		zombie["rumia_move_timer"] = move_duration
		zombie["row"] = target_row
		zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), move_duration * 0.82)
		zombie = _set_rumia_state(zombie, "shift", move_duration)
		effects.append({
			"position": Vector2(_boss_anchor_x(kind), _row_center_y(target_row) - 6.0),
			"radius": 74.0,
			"time": 0.36,
			"duration": 0.36,
			"color": _hover_boss_effect_tint(kind),
		})
	zombie["hover_shift_timer"] = hover_interval
	return zombie


func _spawn_rumia_reinforcement(phase: int) -> void:
	var pools = [
		["conehead", "screen_door", "football"],
		["conehead", "screen_door", "football", "ninja"],
		["screen_door", "football", "basketball", "nether"],
		["football", "dark_football", "basketball", "nezha", "screen_door"],
	]
	var pool: Array = pools[min(phase, pools.size() - 1)]
	var kind = String(pool[rng.randi_range(0, pool.size() - 1)])
	var row = _choose_spawn_row_for_kind(kind)
	if row < 0:
		return
	var spawn_x = BOARD_ORIGIN.x + board_size.x + 52.0 + rng.randf_range(0.0, 20.0)
	_spawn_zombie_at(kind, row, spawn_x, true)
	effects.append({
		"position": Vector2(spawn_x - 12.0, _row_center_y(int(row)) - 8.0),
		"radius": 52.0,
		"time": 0.24,
		"duration": 0.24,
		"color": Color(0.82, 0.08, 0.14, 0.2),
	})


func _update_rumia_reinforcements(zombie: Dictionary, delta: float) -> Dictionary:
	return _update_boss_reinforcements(zombie, delta)


func _spawn_hover_boss_reinforcement(kind: String, phase: int) -> void:
	if kind == "rumia_boss":
		_spawn_rumia_reinforcement(phase)
		return
	var pools: Array = []
	var tint = Color(0.76, 0.94, 1.0, 0.22)
	match kind:
		"daiyousei_boss":
			pools = [
				["normal", "conehead", "lifebuoy_normal"],
				["conehead", "screen_door", "lifebuoy_cone", "snorkel"],
				["screen_door", "football", "lifebuoy_bucket", "dolphin_rider"],
			]
			tint = Color(0.44, 0.98, 0.72, 0.22)
		"cirno_boss":
			pools = [
				["lifebuoy_normal", "snorkel", "conehead"],
				["lifebuoy_cone", "screen_door", "dolphin_rider", "football"],
				["lifebuoy_bucket", "dark_football", "basketball", "snorkel"],
			]
			tint = Color(0.72, 0.94, 1.0, 0.24)
		"pool_boss":
			pools = [
				["lifebuoy_normal", "qinghua", "ice_block"],
				["dragon_boat", "lifebuoy_cone", "shouyue", "qinghua"],
				["dragon_boat", "dragon_dance", "lifebuoy_bucket", "shouyue", "ice_block"],
			]
			tint = Color(0.54, 0.84, 1.0, 0.24)
		_:
			return
	var pool: Array = pools[min(phase, pools.size() - 1)]
	var spawn_kind = String(pool[rng.randi_range(0, pool.size() - 1)])
	var row = _choose_spawn_row_for_kind(spawn_kind)
	if row < 0:
		return
	var spawn_x = BOARD_ORIGIN.x + board_size.x + 54.0 + rng.randf_range(0.0, 24.0)
	_spawn_zombie_at(spawn_kind, row, spawn_x, true)
	effects.append({
		"position": Vector2(spawn_x - 10.0, _row_center_y(int(row)) - 10.0),
		"radius": 54.0,
		"time": 0.24,
		"duration": 0.24,
		"color": tint,
	})


func _update_boss_reinforcements(zombie: Dictionary, delta: float) -> Dictionary:
	var kind = String(zombie.get("kind", ""))
	var phase = int(zombie.get("boss_phase", 0))
	var default_interval = 4.8
	match kind:
		"daiyousei_boss":
			default_interval = maxf(3.5, 5.2 - float(phase) * 0.4)
		"cirno_boss":
			default_interval = maxf(3.1, 4.7 - float(phase) * 0.42)
		"rumia_boss":
			default_interval = maxf(3.4, 5.3 - float(phase) * 0.6)
		"pool_boss":
			default_interval = maxf(3.0, 4.9 - float(phase) * 0.45)
		_:
			return zombie
	zombie["rumia_reinforcement_timer"] = float(zombie.get("rumia_reinforcement_timer", default_interval)) - delta
	if float(zombie["rumia_reinforcement_timer"]) > 0.0:
		return zombie
	_spawn_hover_boss_reinforcement(kind, phase)
	zombie["rumia_reinforcement_timer"] = default_interval + rng.randf_range(-0.35, 0.65)
	return zombie


func _damage_plants_in_row_segment(row: int, min_x: float, max_x: float, damage: float) -> bool:
	var hit := false
	for col in range(COLS):
		var plant_variant = _targetable_plant_at(row, col)
		if plant_variant == null:
			continue
		var plant_center_x = _cell_center(row, col).x
		if plant_center_x < min_x or plant_center_x > max_x:
			continue
		var plant = plant_variant
		if float(plant.get("armor_health", 0.0)) > 0.0:
			var armor_left = float(plant["armor_health"]) - damage
			if armor_left < 0.0:
				plant["health"] += armor_left
				armor_left = 0.0
			plant["armor_health"] = armor_left
		else:
			plant["health"] -= damage
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
		_set_targetable_plant(row, col, plant)
		hit = true
	return hit


func _damage_plant_cell(row: int, col: int, damage: float, extra_cooldown: float = 0.0) -> bool:
	var plant_variant = _targetable_plant_at(row, col)
	if plant_variant == null:
		return false
	var plant = plant_variant
	if float(plant.get("armor_health", 0.0)) > 0.0:
		var armor_left = float(plant["armor_health"]) - damage
		if armor_left < 0.0:
			plant["health"] += armor_left
			armor_left = 0.0
		plant["armor_health"] = armor_left
	else:
		plant["health"] -= damage
	if extra_cooldown > 0.0 and plant.has("shot_cooldown"):
		plant["shot_cooldown"] = maxf(float(plant.get("shot_cooldown", 0.0)), extra_cooldown)
	plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.18)
	_set_targetable_plant(row, col, plant)
	return true


func _damage_plants_in_cells(cells: Array, damage: float, extra_cooldown: float = 0.0) -> int:
	var hit_count := 0
	for cell_variant in cells:
		var cell = Vector2i(cell_variant)
		if _damage_plant_cell(cell.x, cell.y, damage, extra_cooldown):
			hit_count += 1
	return hit_count


func _stagger_plants_in_circle(center: Vector2, radius: float, extra_cooldown: float) -> int:
	var affected := 0
	for row in active_rows:
		var row_i = int(row)
		for col in range(COLS):
			var cell_center = _cell_center(row_i, col)
			if cell_center.distance_to(center) > radius:
				continue
			if _damage_plant_cell(row_i, col, 0.0, extra_cooldown):
				affected += 1
	return affected


func _trigger_daiyousei_boss_skill(zombie: Dictionary) -> Dictionary:
	var data = Defs.ZOMBIES["daiyousei_boss"]
	var row = int(zombie["row"])
	var phase = int(zombie.get("boss_phase", 0))
	var anchor_x = _boss_anchor_x("daiyousei_boss")
	var ring_center = Vector2(BOARD_ORIGIN.x + board_size.x * 0.72, _row_center_y(row) - 10.0)
	match int(zombie.get("boss_skill_cycle", 0)):
		0:
			var ring_hit := false
			var segment_start = BOARD_ORIGIN.x + board_size.x * 0.48
			for lane in active_rows:
				var lane_row = int(lane)
				if abs(lane_row - row) > 1:
					continue
				ring_hit = _damage_plants_in_row_segment(
					lane_row,
					segment_start,
					anchor_x,
					float(data.get("ring_damage", 46.0)) * (2.8 + phase * 0.45)
				) or ring_hit
			effects.append({
				"shape": "fairy_ring",
				"position": ring_center,
				"radius": 152.0 + phase * 18.0,
				"time": 0.42,
				"duration": 0.42,
				"anim_speed": 5.6,
				"color": Color(0.48, 0.98, 0.74, 0.3 if ring_hit else 0.2),
			})
			_show_banner("大妖精散开了星辉弹幕！", 1.2)
			return _set_rumia_state(zombie, "ring", 0.48)
		1:
			var lance_start = BOARD_ORIGIN.x + board_size.x * 0.44
			var lance_hit = _damage_plants_in_row_segment(
				row,
				lance_start,
				anchor_x,
				float(data.get("lance_damage", 180.0)) + phase * 32.0
			)
			effects.append({
				"shape": "fairy_lance",
				"position": Vector2(lance_start, _row_center_y(row) - 10.0),
				"length": anchor_x - lance_start,
				"width": CELL_SIZE.y * 0.36,
				"radius": anchor_x - lance_start,
				"time": 0.34,
				"duration": 0.34,
				"anim_speed": 7.2,
				"color": Color(0.72, 1.0, 0.88, 0.34 if lance_hit else 0.22),
			})
			_show_banner("大妖精聚起了光枪！", 1.15)
			return _set_rumia_state(zombie, "lance", 0.4)
		_:
			for _i in range(2 + (1 if phase >= 1 else 0)):
				_spawn_hover_boss_reinforcement("daiyousei_boss", phase)
			effects.append({
				"shape": "fairy_ring",
				"position": ring_center,
				"radius": 124.0 + phase * 14.0,
				"time": 0.36,
				"duration": 0.36,
				"anim_speed": 4.9,
				"color": Color(0.56, 1.0, 0.82, 0.24),
			})
			_show_banner("大妖精呼来了更多妖精！", 1.2)
			return _set_rumia_state(zombie, "summon", 0.54)


func _trigger_cirno_boss_skill(zombie: Dictionary) -> Dictionary:
	var data = Defs.ZOMBIES["cirno_boss"]
	var row = int(zombie["row"])
	var phase = int(zombie.get("boss_phase", 0))
	var anchor_x = _boss_anchor_x("cirno_boss")
	match int(zombie.get("boss_skill_cycle", 0)):
		0:
			var impact_rows = [row]
			var prev_row = _next_active_row(row, -1)
			var next_row = _next_active_row(row, 1)
			impact_rows.append(int(prev_row.get("row", row)))
			impact_rows.append(int(next_row.get("row", row)))
			var impact_cells: Array = []
			var impact_points: Array = []
			var land_cols = [5, 6, 7, 8]
			for index in range(impact_rows.size()):
				var impact_row = clampi(int(impact_rows[index]), 0, ROWS - 1)
				var col = int(land_cols[min(index, land_cols.size() - 1)])
				var cell = Vector2i(impact_row, col)
				if impact_cells.has(cell):
					continue
				impact_cells.append(cell)
				impact_points.append(_cell_center(impact_row, col))
			var impact_hit_count = _damage_plants_in_cells(
				impact_cells,
				float(data.get("icicle_damage", 110.0)) + phase * 18.0,
				1.1 + phase * 0.18
			)
			effects.append({
				"shape": "icicle_fall",
				"position": Vector2(anchor_x - 120.0, _row_center_y(row) - 28.0),
				"points": impact_points,
				"radius": 150.0,
				"time": 0.4,
				"duration": 0.4,
				"anim_speed": 6.8,
				"color": Color(0.78, 0.96, 1.0, 0.34 if impact_hit_count > 0 else 0.22),
			})
			_show_banner("Icicle Fall", 1.1)
			return _set_rumia_state(zombie, "icicle", 0.44)
		1:
			var freeze_center = Vector2(BOARD_ORIGIN.x + board_size.x * 0.64, _row_center_y(row) - 10.0)
			var freeze_radius = 264.0 + phase * 22.0
			var freeze_hit = _damage_plants_in_circle(
				freeze_center,
				freeze_radius,
				float(data.get("freeze_damage", 86.0)) + phase * 16.0
			)
			_stagger_plants_in_circle(freeze_center, freeze_radius, 1.35 + phase * 0.2)
			effects.append({
				"shape": "perfect_freeze",
				"position": freeze_center,
				"radius": freeze_radius,
				"time": 0.5,
				"duration": 0.5,
				"anim_speed": 5.6,
				"color": Color(0.7, 0.92, 1.0, 0.32 if freeze_hit else 0.2),
			})
			_show_banner("Perfect Freeze", 1.15)
			return _set_rumia_state(zombie, "freeze", 0.56)
		_:
			var blizzard_start = BOARD_ORIGIN.x + board_size.x * 0.42
			var blizzard_hit := false
			for lane in active_rows:
				blizzard_hit = _damage_plants_in_row_segment(
					int(lane),
					blizzard_start,
					anchor_x,
					float(data.get("blizzard_damage", 62.0)) * (1.9 + phase * 0.18)
				) or blizzard_hit
			effects.append({
				"shape": "diamond_blizzard",
				"position": Vector2(blizzard_start, BOARD_ORIGIN.y + board_size.y * 0.5 - 4.0),
				"length": anchor_x - blizzard_start,
				"width": board_size.y * 0.9,
				"radius": 220.0 + phase * 12.0,
				"time": 0.5,
				"duration": 0.5,
				"anim_speed": 6.2,
				"color": Color(0.78, 0.96, 1.0, 0.34 if blizzard_hit else 0.22),
			})
			if phase >= 1:
				_spawn_hover_boss_reinforcement("cirno_boss", phase)
			_show_banner("Diamond Blizzard", 1.15)
			return _set_rumia_state(zombie, "blizzard", 0.54)


func _trigger_rumia_boss_skill(zombie: Dictionary) -> Dictionary:
	var data = Defs.ZOMBIES["rumia_boss"]
	var center = Vector2(_rumia_anchor_x(), _row_center_y(int(zombie["row"])) - 8.0)
	var phase = int(zombie.get("boss_phase", 0))
	effects.append({
		"shape": "rumia_burst",
		"position": center,
		"radius": 118.0 + phase * 12.0,
		"time": 0.34,
		"duration": 0.34,
		"anim_speed": 4.6,
		"color": Color(0.98, 0.08, 0.18, 0.34),
	})
	match int(zombie.get("boss_skill_cycle", 0)):
		0:
			var summon_rows: Array = []
			summon_rows.append(int(zombie["row"]))
			var row_data = _next_active_row(int(zombie["row"]), -1)
			summon_rows.append(int(row_data["row"]))
			row_data = _next_active_row(int(zombie["row"]), 1)
			summon_rows.append(int(row_data["row"]))
			var summon_kinds = ["normal", "conehead", "buckethead"]
			for summon_index in range(min(int(data.get("summon_count", 3)), summon_rows.size())):
				var summon_kind = summon_kinds[min(summon_index + phase, summon_kinds.size() - 1)]
				_spawn_zombie_at(summon_kind, int(summon_rows[summon_index]), _rumia_anchor_x() - 64.0 - summon_index * 22.0, true)
			_show_banner("露米娅召来了黑暗眷属！", 1.7)
			return _set_rumia_state(zombie, "summon", 0.56)
		1:
			var beam_hit = _damage_plants_in_row_segment(int(zombie["row"]), BOARD_ORIGIN.x, _rumia_anchor_x(), float(data.get("moonlight_damage", 220.0)) + phase * 26.0)
			effects.append({
				"shape": "rumia_beam",
				"position": Vector2(BOARD_ORIGIN.x + 12.0, _row_center_y(int(zombie["row"])) - 10.0),
				"length": _rumia_anchor_x() - BOARD_ORIGIN.x,
				"width": CELL_SIZE.y * 0.7,
				"radius": _rumia_anchor_x() - BOARD_ORIGIN.x,
				"time": 0.34,
				"duration": 0.34,
				"anim_speed": 8.4,
				"color": Color(1.0, 0.16, 0.22, 0.34 if beam_hit else 0.24),
			})
			_show_banner("Moonlight Ray", 1.2)
			return _set_rumia_state(zombie, "beam", 0.42)
		2:
			for lane in active_rows:
				var lane_row = int(lane)
				if abs(lane_row - int(zombie["row"])) > 1:
					continue
				var bird_x = BOARD_ORIGIN.x + board_size.x * (0.44 + 0.1 * float(abs(lane_row - int(zombie["row"]))))
				_damage_plants_in_row_segment(lane_row, bird_x - 72.0, _rumia_anchor_x(), float(data.get("night_bird_damage", 34.0)) * (4.0 + phase * 0.6))
				effects.append({
					"shape": "night_bird_swarm",
					"position": Vector2(bird_x, _row_center_y(lane_row) - 8.0),
					"length": _rumia_anchor_x() - bird_x + 34.0,
					"width": CELL_SIZE.y * 0.54,
					"radius": 120.0,
					"time": 0.42,
					"duration": 0.42,
					"anim_speed": 6.8,
					"color": Color(0.16, 0.02, 0.04, 0.48),
				})
			_show_banner("Night Bird", 1.2)
			return _set_rumia_state(zombie, "bird", 0.48)
		_:
			var slept = _sleep_plants_in_radius(center, float(data.get("darkness_radius", 170.0)) + phase * 16.0, 3.4 + phase * 0.7)
			_damage_plants_in_circle(center, float(data.get("darkness_radius", 170.0)) * 0.72, 44.0 + phase * 12.0)
			effects.append({
				"shape": "dark_orbit",
				"position": center,
				"radius": float(data.get("darkness_radius", 170.0)) + phase * 16.0,
				"time": 0.52,
				"duration": 0.52,
				"anim_speed": 5.4,
				"color": Color(0.16, 0.0, 0.06, 0.42 if slept > 0 else 0.28),
			})
			_show_banner("Dark Side of the Moon", 1.3)
			return _set_rumia_state(zombie, "dark", 0.56)


func _trigger_boss_skill(zombie: Dictionary) -> Dictionary:
	if String(zombie["kind"]) == "rumia_boss":
		return _trigger_rumia_boss_skill(zombie)
	if String(zombie["kind"]) == "daiyousei_boss":
		return _trigger_daiyousei_boss_skill(zombie)
	if String(zombie["kind"]) == "cirno_boss":
		return _trigger_cirno_boss_skill(zombie)
	if String(zombie["kind"]) == "night_boss":
		return _trigger_night_boss_skill(zombie)
	if String(zombie["kind"]) == "pool_boss":
		var phase = int(zombie.get("boss_phase", 0))
		effects.append({
			"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"]))),
			"radius": 146.0 + phase * 12.0,
			"time": 0.42,
			"duration": 0.42,
			"color": Color(0.26, 0.62, 0.92, 0.34),
		})
		match int(zombie.get("boss_skill_cycle", 0)):
			0:
				var summon_pool = ["dragon_boat", "qinghua", "shouyue", "ice_block", "dragon_dance"]
				for summon_index in range(3 + phase):
					var summon_kind = String(summon_pool[min(summon_index, summon_pool.size() - 1)]) if summon_index < summon_pool.size() else String(summon_pool[rng.randi_range(0, summon_pool.size() - 1)])
					_spawn_zombie(summon_kind, _choose_spawn_row_for_kind(summon_kind), true)
				_show_banner("玄潮尸王掀起了尸潮！", 1.5)
			1:
				for lane in active_rows:
					_damage_front_plant_in_row(int(lane), 180.0 + phase * 38.0)
					if _is_water_row(int(lane)):
						_set_ice_tile(int(lane), clampi(rng.randi_range(3, COLS - 1), 0, COLS - 1))
				_show_banner("玄潮尸王掀起了激浪！", 1.35)
			_:
				for lane in water_rows:
					var water_row = int(lane)
					_set_ice_tile(water_row, clampi(rng.randi_range(2, COLS - 2), 0, COLS - 1))
					_add_porcelain_shard(water_row, clampi(rng.randi_range(3, COLS - 2), 0, COLS - 1), 10.0 + phase * 2.0)
				for summon_kind in ["dragon_boat", "dragon_dance"]:
					_spawn_zombie(summon_kind, _choose_spawn_row_for_kind(summon_kind), true)
				_show_banner("玄潮尸王封锁了前场格位！", 1.45)
		return zombie
	effects.append({
		"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"]))),
		"radius": 120.0,
		"time": 0.4,
		"duration": 0.4,
		"color": Color(1.0, 0.32, 0.2, 0.4),
	})
	match int(zombie.get("boss_skill_cycle", 0)):
		0:
			for kind in ["buckethead", "farmer", "spear", "kungfu"]:
				var row = _choose_spawn_row_for_kind(kind)
				_spawn_zombie(kind, row, true)
		1:
			for lane in active_rows:
				_damage_front_plant_in_row(int(lane), 220.0 + float(zombie.get("boss_phase", 0)) * 60.0)
				if rng.randf() < 0.65:
					_spawn_farmer_weed(int(lane), rng.randi_range(3, COLS - 2))
		_:
			for lane in active_rows:
				_spawn_spear_obstacle(int(lane), BOARD_ORIGIN.x + board_size.x * 0.55 + rng.randf_range(-60.0, 120.0))
				if rng.randf() < 0.7:
					_spawn_farmer_weed(int(lane), rng.randi_range(2, COLS - 2))
	return zombie


func _boss_phase_from_ratio(health_ratio: float) -> int:
	if health_ratio <= 0.2:
		return 3
	if health_ratio <= 0.45:
		return 2
	if health_ratio <= 0.72:
		return 1
	return 0


func _trigger_rumia_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	_show_banner("露米娅进入第 %d 阶段！" % (phase + 1), 2.1)
	effects.append({
		"shape": "dark_orbit",
		"position": Vector2(_rumia_anchor_x(), _row_center_y(int(zombie["row"])) - 6.0),
		"radius": 160.0 + phase * 20.0,
		"time": 0.54,
		"duration": 0.54,
		"color": Color(0.38, 0.0, 0.08, 0.5),
	})
	for _i in range(phase + 1):
		var spawn_kind = "conehead" if phase <= 1 else "buckethead"
		_spawn_zombie_at(spawn_kind, _choose_spawn_row_for_kind(spawn_kind), _rumia_anchor_x() - 48.0, true)
	_sleep_plants_in_radius(Vector2(_rumia_anchor_x(), _row_center_y(int(zombie["row"]))), 132.0 + phase * 16.0, 1.8 + phase * 0.5)
	return _set_rumia_state(zombie, "phase", 0.72)


func _trigger_daiyousei_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	var center = Vector2(_boss_anchor_x("daiyousei_boss"), _row_center_y(int(zombie["row"])) - 10.0)
	_show_banner("大妖精的弹幕加速了！", 1.8)
	effects.append({
		"shape": "fairy_ring",
		"position": center,
		"radius": 138.0 + phase * 18.0,
		"time": 0.48,
		"duration": 0.48,
		"anim_speed": 5.2,
		"color": Color(0.54, 1.0, 0.78, 0.32),
	})
	for _i in range(phase + 1):
		_spawn_hover_boss_reinforcement("daiyousei_boss", phase)
	_damage_front_plant_in_row(int(zombie["row"]), 88.0 + phase * 24.0)
	return _set_rumia_state(zombie, "phase", 0.62)


func _trigger_cirno_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	var center = Vector2(_boss_anchor_x("cirno_boss") - 108.0, _row_center_y(int(zombie["row"])) - 10.0)
	_show_banner("琪露诺的寒气更强了！", 2.0)
	effects.append({
		"shape": "perfect_freeze",
		"position": center,
		"radius": 228.0 + phase * 24.0,
		"time": 0.52,
		"duration": 0.52,
		"anim_speed": 5.2,
		"color": Color(0.74, 0.94, 1.0, 0.34),
	})
	_damage_plants_in_circle(center, 180.0 + phase * 14.0, 42.0 + phase * 14.0)
	_stagger_plants_in_circle(center, 180.0 + phase * 14.0, 1.0 + phase * 0.12)
	for _i in range(phase + 1):
		_spawn_hover_boss_reinforcement("cirno_boss", phase)
	return _set_rumia_state(zombie, "phase", 0.7)


func _trigger_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	if String(zombie["kind"]) == "rumia_boss":
		return _trigger_rumia_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "daiyousei_boss":
		return _trigger_daiyousei_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "cirno_boss":
		return _trigger_cirno_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "night_boss":
		return _trigger_night_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "pool_boss":
		_show_banner("玄潮尸王进入第 %d 阶段！" % (phase + 1), 2.0)
		effects.append({
			"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"]))),
			"radius": 200.0 + phase * 22.0,
			"time": 0.56,
			"duration": 0.56,
			"color": Color(0.18, 0.58, 0.94, 0.42),
		})
		for lane in water_rows:
			_set_ice_tile(int(lane), clampi(rng.randi_range(2, COLS - 2), 0, COLS - 1))
		for summon_kind in ["dragon_boat", "dragon_dance", "qinghua"]:
			_spawn_zombie(summon_kind, _choose_spawn_row_for_kind(summon_kind), true)
		for lane in active_rows:
			_damage_front_plant_in_row(int(lane), 100.0 + phase * 26.0)
		return zombie
	_show_banner("Boss 进入第 %d 阶段！" % (phase + 1), 2.0)
	effects.append({
		"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"]))),
		"radius": 180.0 + phase * 20.0,
		"time": 0.6,
		"duration": 0.6,
		"color": Color(1.0, 0.18, 0.12, 0.5),
	})
	for lane in active_rows:
		_damage_front_plant_in_row(int(lane), 120.0 + phase * 30.0)
	for _i in range(phase + 2):
		var kind = "buckethead" if phase >= 2 and rng.randf() < 0.5 else "conehead"
		if phase >= 1 and rng.randf() < 0.4:
			kind = "farmer"
		if phase >= 2 and rng.randf() < 0.3:
			kind = "kungfu"
		_spawn_zombie(kind, _choose_spawn_row_for_kind(kind), true)
	return zombie


func _can_raise_grave_at(row: int, col: int) -> bool:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return false
	if _grave_index_at(row, col) != -1:
		return false
	if grid[row][col] != null:
		return false
	if support_grid[row][col] != null:
		return false
	if _is_pool_level() and _is_water_row(row):
		return false
	return true


func _raise_random_graves(count: int) -> int:
	if count <= 0:
		return 0
	var candidates: Array = []
	if current_level.has("grave_layout"):
		for cell in current_level["grave_layout"]:
			var row = int(cell.x)
			var col = int(cell.y)
			if _can_raise_grave_at(row, col):
				candidates.append(Vector2i(row, col))
	for row in active_rows:
		for col in range(2, COLS - 1):
			var row_i = int(row)
			if not _can_raise_grave_at(row_i, col):
				continue
			var cell = Vector2i(row_i, col)
			if candidates.has(cell):
				continue
			candidates.append(cell)
	var raised := 0
	while raised < count and not candidates.is_empty():
		var pick = rng.randi_range(0, candidates.size() - 1)
		var cell: Vector2i = candidates[pick]
		candidates.remove_at(pick)
		graves.append({
			"row": cell.x,
			"col": cell.y,
		})
		effects.append({
			"position": _cell_center(cell.x, cell.y) + Vector2(0.0, 18.0),
			"radius": 54.0,
			"time": 0.32,
			"duration": 0.32,
			"color": Color(0.62, 0.68, 1.0, 0.24),
		})
		raised += 1
	return raised


func _trigger_night_boss_skill(zombie: Dictionary) -> Dictionary:
	var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
	var phase = int(zombie.get("boss_phase", 0))
	var data = Defs.ZOMBIES["night_boss"]
	effects.append({
		"position": center,
		"radius": 136.0 + phase * 14.0,
		"time": 0.44,
		"duration": 0.44,
		"color": Color(0.36, 0.24, 0.76, 0.44),
	})
	match int(zombie.get("boss_skill_cycle", 0)):
		0:
			var summon_kinds: Array = ["nether", "screen_door", "ninja"]
			if phase >= 1:
				summon_kinds.append("dark_football")
			elif rng.randf() < 0.45:
				summon_kinds.append("football")
			for kind_variant in summon_kinds:
				_spawn_zombie(String(kind_variant), _choose_spawn_row_for_kind(String(kind_variant)), true)
		1:
			var raised = _raise_random_graves(int(data.get("grave_raise_count", 3)) + phase)
			if raised > 0:
				_show_banner("暗夜尸王唤醒了新的坟墓！", 1.8)
			for _i in range(1 + phase):
				var spawn_kind = "nether" if rng.randf() < 0.65 else "newspaper"
				_spawn_zombie(spawn_kind, _choose_spawn_row_for_kind(spawn_kind), true)
		_:
			for lane in active_rows:
				var sleep_center = Vector2(BOARD_ORIGIN.x + board_size.x * (0.54 + rng.randf_range(-0.04, 0.06)), _row_center_y(int(lane)))
				_sleep_plants_in_radius(
					sleep_center,
					float(data.get("sleep_radius", 150.0)),
					float(data.get("sleep_duration", 5.2)) + phase * 0.8
				)
				_damage_front_plant_in_row(int(lane), 150.0 + phase * 35.0)
	return zombie


func _trigger_night_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	_show_banner("暗夜尸王进入第 %d 阶段！" % (phase + 1), 2.1)
	effects.append({
		"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"]))),
		"radius": 190.0 + phase * 24.0,
		"time": 0.62,
		"duration": 0.62,
		"color": Color(0.26, 0.28, 0.72, 0.52),
	})
	var raised = _raise_random_graves(phase + 1)
	if raised > 0:
		_show_banner("新的坟墓正在升起！", 1.5)
	for lane in active_rows:
		_damage_front_plant_in_row(int(lane), 90.0 + phase * 28.0)
	for _i in range(phase + 2):
		var kind = "newspaper"
		if phase >= 1 and rng.randf() < 0.45:
			kind = "nether"
		if phase >= 2 and rng.randf() < 0.38:
			kind = "dark_football"
		_spawn_zombie(kind, _choose_spawn_row_for_kind(kind), true)
	return zombie


func _damage_front_plant_in_row(row: int, damage: float) -> void:
	for col in range(COLS - 1, -1, -1):
		var plant = _targetable_plant_at(row, col)
		if plant == null:
			continue
		if float(plant.get("armor_health", 0.0)) > 0.0:
			plant["armor_health"] = maxf(0.0, float(plant["armor_health"]) - damage)
		else:
			plant["health"] -= damage
		plant["flash"] = 0.22
		_set_targetable_plant(row, col, plant)
		return


func _current_zombie_speed(zombie: Dictionary) -> float:
	var speed = float(zombie["base_speed"])
	if float(zombie["slow_timer"]) > 0.0:
		speed *= 0.5
	if float(zombie.get("rooted_timer", 0.0)) > 0.0:
		speed *= 0.24
	return speed


func _begin_dragon_boat_stroke(zombie: Dictionary) -> Dictionary:
	var boat_phase = int(zombie.get("boat_phase", 0))
	var direction = 1.0 if boat_phase == 2 else -1.0
	var distance = CELL_SIZE.x
	zombie["boat_move_from_x"] = float(zombie["x"])
	zombie["boat_move_to_x"] = float(zombie["x"]) + direction * distance
	zombie["boat_move_t"] = 0.0
	zombie["boat_move_duration"] = 0.58 if boat_phase == 2 else 0.64
	zombie["boat_phase"] = (boat_phase + 1) % 3
	zombie["boat_stride_timer"] = 0.0
	return zombie


func _update_dragon_boat_motion(zombie: Dictionary, delta: float) -> Dictionary:
	var move_t = float(zombie.get("boat_move_t", 1.0))
	if move_t >= 1.0:
		zombie["boat_stride_timer"] = maxf(0.0, float(zombie.get("boat_stride_timer", 0.0)) - delta)
		if float(zombie.get("special_pause_timer", 0.0)) <= 0.0 and float(zombie["boat_stride_timer"]) <= 0.0:
			zombie = _begin_dragon_boat_stroke(zombie)
			move_t = 0.0
		else:
			return zombie
	var duration = maxf(float(zombie.get("boat_move_duration", 0.0)), 0.01)
	move_t = minf(1.0, move_t + delta / duration)
	var eased = smoothstep(0.0, 1.0, move_t)
	zombie["boat_move_t"] = move_t
	zombie["x"] = lerpf(float(zombie.get("boat_move_from_x", zombie["x"])), float(zombie.get("boat_move_to_x", zombie["x"])), eased)
	var crush_cell = _find_crushable_cell(int(zombie["row"]), float(zombie["x"]), 86.0)
	if crush_cell.y != -1:
		_crush_cell(crush_cell.x, crush_cell.y)
	if move_t >= 1.0:
		zombie["boat_stride_timer"] = 0.32
		effects.append({
			"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + 18.0),
			"radius": 48.0,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.82, 0.94, 1.0, 0.24),
		})
	return zombie


func _explode_cherry(row: int, col: int, mega: bool = false) -> void:
	var center = _cell_center(row, col)
	var radius = float(Defs.PLANTS["cherry_bomb"]["radius"])
	var damage = float(Defs.PLANTS["cherry_bomb"]["damage"])
	if mega:
		radius += 72.0
		damage *= 1.35
	effects.append({
			"position": center,
			"radius": radius,
			"time": 0.42,
			"duration": 0.42,
			"color": Color(0.36, 1.0, 0.38, 0.68) if mega else Color(1.0, 0.44, 0.24, 0.72),
		})
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) <= radius:
			zombie["health"] -= damage
			zombie["flash"] = 0.24
			zombies[i] = zombie
	_damage_obstacles_in_circle(center, radius, damage)


func _explode_mine(row: int, col: int) -> void:
	var center = _cell_center(row, col)
	var radius = float(Defs.PLANTS["potato_mine"]["radius"])
	var damage = float(Defs.PLANTS["potato_mine"]["damage"])
	effects.append({
		"position": center,
		"radius": 96.0,
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.84, 0.28, 0.74),
	})
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or not _is_enemy_zombie(zombie):
			continue
		if absf(float(zombie["x"]) - center.x) <= radius:
			zombie["health"] -= damage
			zombie["flash"] = 0.24
			zombies[i] = zombie
	_damage_obstacles_in_radius(row, center.x, radius, damage)


func _trigger_jalapeno(row: int, col: int, boosted: bool = false) -> void:
	var base_center = _cell_center(row, col)
	var damage = float(Defs.PLANTS["jalapeno"]["damage"])
	var lanes: Array = [row]
	if boosted:
		for lane in [row - 1, row + 1]:
			if lane >= 0 and lane < ROWS and _is_row_active(lane):
				lanes.append(lane)
	for lane in lanes:
		var lane_center_x = BOARD_ORIGIN.x + board_size.x * 0.5
		_damage_zombies_in_radius(int(lane), lane_center_x, board_size.x, damage)
		_damage_obstacles_in_radius(int(lane), lane_center_x, board_size.x, damage)
		_clear_ice_row(int(lane))
		effects.append({
			"shape": "lane_spray",
			"position": Vector2(BOARD_ORIGIN.x, _row_center_y(int(lane))),
			"length": board_size.x,
			"width": CELL_SIZE.y * 0.72,
			"radius": board_size.x,
			"time": 0.34,
			"duration": 0.34,
			"color": Color(1.0, 0.44, 0.14, 0.56),
		})
	effects.append({
		"position": base_center,
		"radius": 96.0,
		"time": 0.28,
		"duration": 0.28,
		"color": Color(1.0, 0.76, 0.18, 0.42),
	})


func _trigger_ice_shroom(row: int, col: int, boosted: bool = false) -> void:
	var center = _cell_center(row, col)
	var freeze_duration = float(Defs.PLANTS["ice_shroom"]["freeze_duration"])
	var slow_duration = float(Defs.PLANTS["ice_shroom"]["slow_duration"])
	if boosted:
		freeze_duration += 2.0
		slow_duration += 4.0
	effects.append({
		"position": center,
		"radius": 520.0,
		"time": 0.46,
		"duration": 0.46,
		"color": Color(0.62, 0.88, 1.0, 0.46),
	})
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		zombie["slow_timer"] = maxf(float(zombie["slow_timer"]), slow_duration + freeze_duration)
		zombie["flash"] = 0.22
		zombies[i] = zombie


func _trigger_doom_shroom(row: int, col: int, boosted: bool = false) -> void:
	var center = _cell_center(row, col)
	var radius = float(Defs.PLANTS["doom_shroom"]["radius"])
	var damage = 1800.0
	if boosted:
		radius += 80.0
		damage = 2600.0
	effects.append({
		"position": center,
		"radius": radius,
		"time": 0.54,
		"duration": 0.54,
		"color": Color(0.38, 0.0, 0.16, 0.56),
	})
	_damage_zombies_in_circle(center, radius, damage)
	_damage_obstacles_in_circle(center, radius, damage)


func _find_projectile_target(projectile: Dictionary) -> int:
	var best_index = -1
	var best_distance = 999999.0
	var projectile_pos = Vector2(projectile["position"])
	var projectile_radius = float(projectile.get("radius", 8.0))
	var free_aim = bool(projectile.get("free_aim", false))
	var ignored_uids: Array = projectile.get("hit_uids", [])
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if _is_hidden_from_lane_attacks(zombie) or not _is_enemy_zombie(zombie):
			continue
		if free_aim:
			if absf(_row_center_y(int(zombie["row"])) - projectile_pos.y) > 24.0:
				continue
		elif int(zombie["row"]) != int(projectile["row"]):
			continue
		if ignored_uids.has(int(zombie.get("uid", -1))):
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
		var plant_variant = _targetable_plant_at(int(projectile["row"]), col)
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
		if int(zombie["row"]) != row or _is_hidden_from_lane_attacks(zombie) or not _is_enemy_zombie(zombie):
			continue
		if float(zombie["x"]) > best_x:
			best_x = float(zombie["x"])
			best_index = i
	return best_index


func _find_frontmost_obstacle_x(row: int) -> float:
	var best_x := -999999.0
	for weed in weeds:
		if int(weed["row"]) != row:
			continue
		best_x = max(best_x, float(weed["x"]))
	for spear in spears:
		if int(spear["row"]) != row:
			continue
		best_x = max(best_x, float(spear["x"]))
	return best_x


func _damage_obstacles_in_radius(row: int, center_x: float, radius: float, damage: float) -> bool:
	var hit := false
	for i in range(weeds.size()):
		var weed = weeds[i]
		if int(weed["row"]) != row:
			continue
		if absf(float(weed["x"]) - center_x) > radius:
			continue
		weed["health"] -= damage
		weeds[i] = weed
		hit = true
	for i in range(spears.size()):
		var spear = spears[i]
		if int(spear["row"]) != row:
			continue
		if absf(float(spear["x"]) - center_x) > radius:
			continue
		spear["health"] -= damage
		spears[i] = spear
		hit = true
	return hit


func _can_finish_level_ignoring_obstacles() -> bool:
	return next_event_index >= current_level["events"].size() and _enemy_zombie_count() <= 0 and batch_spawn_queue.is_empty() and batch_spawn_remaining <= 0


func _damage_zombies_in_radius(row: int, center_x: float, radius: float, damage: float) -> void:
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or not _is_enemy_zombie(zombie):
			continue
		if absf(float(zombie["x"]) - center_x) > radius:
			continue
		zombie = _apply_zombie_damage(zombie, damage, 0.16)
		zombies[i] = zombie


func _damage_zombies_in_row_segment(row: int, min_x: float, max_x: float, damage: float, slow_duration: float = 0.0) -> bool:
	var hit := false
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or not _is_enemy_zombie(zombie) or _is_hidden_from_lane_attacks(zombie):
			continue
		var zombie_x = float(zombie["x"])
		if zombie_x < min_x or zombie_x > max_x:
			continue
		zombie = _apply_zombie_damage(zombie, damage, 0.18, slow_duration)
		zombies[i] = zombie
		hit = true
	return hit


func _damage_zombies_in_circle(center: Vector2, radius: float, damage: float) -> bool:
	var hit := false
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) > radius:
			continue
		zombie = _apply_zombie_damage(zombie, damage, 0.18)
		zombies[i] = zombie
		hit = true
	return hit


func _damage_obstacles_in_circle(center: Vector2, radius: float, damage: float) -> bool:
	var hit := false
	for i in range(weeds.size()):
		var weed = weeds[i]
		var weed_pos = Vector2(float(weed["x"]), _row_center_y(int(weed["row"])) + 18.0)
		if weed_pos.distance_to(center) > radius:
			continue
		weed["health"] -= damage
		weeds[i] = weed
		hit = true
	for i in range(spears.size()):
		var spear = spears[i]
		var spear_pos = Vector2(float(spear["x"]), _row_center_y(int(spear["row"])) + 10.0)
		if spear_pos.distance_to(center) > radius:
			continue
		spear["health"] -= damage
		spears[i] = spear
		hit = true
	return hit


func _damage_plants_in_circle(center: Vector2, radius: float, damage: float) -> bool:
	var hit := false
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = _targetable_plant_at(row, col)
			if plant_variant == null:
				continue
			var plant_center = _cell_center(row, col)
			if plant_center.distance_to(center) > radius:
				continue
			var plant = plant_variant
			if float(plant.get("armor_health", 0.0)) > 0.0:
				var armor_left = float(plant["armor_health"]) - damage
				if armor_left < 0.0:
					plant["health"] += armor_left
					armor_left = 0.0
				plant["armor_health"] = armor_left
			else:
				plant["health"] -= damage
			plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.12)
			_set_targetable_plant(row, col, plant)
			hit = true
	return hit


func _sleep_plants_in_radius(center: Vector2, radius: float, duration: float) -> int:
	var count := 0
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue
			if _cell_center(row, col).distance_to(center) > radius:
				continue
			var plant = plant_variant
			plant["sleep_timer"] = maxf(float(plant.get("sleep_timer", 0.0)), duration)
			plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.08)
			grid[row][col] = plant
			count += 1
	return count


func _sleep_zombies_in_radius(center: Vector2, radius: float, duration: float, target_hypnotized: bool, source_index: int = -1) -> int:
	var count := 0
	for i in range(zombies.size()):
		if i == source_index:
			continue
		var zombie = zombies[i]
		if bool(zombie.get("hypnotized", false)) != target_hypnotized:
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) > radius:
			continue
		zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), duration)
		zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.08)
		zombies[i] = zombie
		count += 1
	return count


func _wake_plants_in_radius(center: Vector2, radius: float) -> int:
	var count := 0
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue
			if _cell_center(row, col).distance_to(center) > radius:
				continue
			if float(plant_variant.get("sleep_timer", 0.0)) <= 0.0:
				continue
			var plant = plant_variant
			plant["sleep_timer"] = 0.0
			plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.14)
			grid[row][col] = plant
			count += 1
	return count


func _wake_all_plants() -> int:
	var count := 0
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue
			if float(plant_variant.get("sleep_timer", 0.0)) <= 0.0:
				continue
			var plant = plant_variant
			plant["sleep_timer"] = 0.0
			plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
			grid[row][col] = plant
			count += 1
	return count


func _apply_nezha_landing(zombie: Dictionary) -> void:
	var impact = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
	_damage_plants_in_circle(impact, 76.0, 220.0)
	effects.append({
		"position": impact,
		"radius": 84.0,
		"time": 0.32,
		"duration": 0.32,
		"color": Color(1.0, 0.48, 0.18, 0.32),
	})


func _strike_thunder_chain(start_index: int, first_damage: float, chain_damage: float, chain_range: float, max_targets: int) -> int:
	if start_index < 0 or start_index >= zombies.size():
		return 0
	if not _is_enemy_zombie(zombies[start_index]):
		return 0
	var hit_count := 0
	var queue: Array = [start_index]
	var used := {}
	var current_damage = first_damage
	while not queue.is_empty() and hit_count < max_targets:
		var zombie_index = int(queue.pop_front())
		if used.has(zombie_index) or zombie_index < 0 or zombie_index >= zombies.size():
			continue
		used[zombie_index] = true
		var zombie = zombies[zombie_index]
		var strike_center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 12.0)
		zombie = _apply_zombie_damage(zombie, current_damage, 0.2)
		zombies[zombie_index] = zombie
		effects.append({
			"position": strike_center,
			"radius": 54.0,
			"time": 0.18,
			"duration": 0.18,
			"color": Color(0.92, 0.92, 0.36, 0.28),
		})
		hit_count += 1
		current_damage = chain_damage
		var nearest_index := -1
		var nearest_distance := 999999.0
		for i in range(zombies.size()):
			if used.has(i):
				continue
			var next_zombie = zombies[i]
			if not _is_enemy_zombie(next_zombie):
				continue
			var next_center = Vector2(float(next_zombie["x"]), _row_center_y(int(next_zombie["row"])))
			var distance = next_center.distance_to(Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"]))))
			if distance > chain_range:
				continue
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_index = i
		if nearest_index != -1:
			queue.append(nearest_index)
	return hit_count


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
	var view_rect = _selection_pool_view_rect()
	var col = index % PREP_POOL_COLUMNS
	var row = int(floor(float(index) / float(PREP_POOL_COLUMNS)))
	return Rect2(
		Vector2(view_rect.position.x + col * PREP_POOL_STEP.x, view_rect.position.y + row * PREP_POOL_STEP.y - selection_pool_scroll),
		Vector2(96.0, 108.0)
	)


func _selection_slot_at(mouse_pos: Vector2) -> int:
	for i in range(MAX_SEED_SLOTS):
		if _selection_slot_rect(i).has_point(mouse_pos):
			return i
	return -1


func _selection_pool_card_at(mouse_pos: Vector2) -> String:
	var view_rect = _selection_pool_view_rect()
	if not view_rect.has_point(mouse_pos):
		return ""
	for i in range(selection_pool_cards.size()):
		var rect = _selection_pool_rect(i)
		if view_rect.intersects(rect) and rect.has_point(mouse_pos):
			return String(selection_pool_cards[i])
	return ""


func _selection_pool_view_rect() -> Rect2:
	return Rect2(
		PREP_POOL_PANEL_RECT.position + Vector2(18.0, 40.0),
		Vector2(PREP_POOL_PANEL_RECT.size.x - 62.0, PREP_POOL_PANEL_RECT.size.y - 68.0)
	)


func _selection_pool_hover_rect() -> Rect2:
	var view_rect = _selection_pool_view_rect()
	return Rect2(
		view_rect.position + Vector2(8.0, 10.0),
		Vector2(view_rect.size.x - 16.0, view_rect.size.y - 18.0)
	)


func _selection_pool_track_rect() -> Rect2:
	var view_rect = _selection_pool_view_rect()
	return Rect2(
		Vector2(PREP_POOL_PANEL_RECT.position.x + PREP_POOL_PANEL_RECT.size.x - 28.0, view_rect.position.y),
		Vector2(12.0, view_rect.size.y)
	)


func _selection_pool_content_height() -> float:
	var row_count = int(ceil(float(selection_pool_cards.size()) / float(PREP_POOL_COLUMNS)))
	if row_count <= 0:
		return 0.0
	return 108.0 + float(max(row_count - 1, 0)) * PREP_POOL_STEP.y


func _selection_pool_max_scroll() -> float:
	return maxf(0.0, _selection_pool_content_height() - _selection_pool_view_rect().size.y)


func _set_selection_pool_scroll(value: float) -> void:
	selection_pool_scroll = clampf(value, 0.0, _selection_pool_max_scroll())


func _requires_seed_selection(level: Dictionary) -> bool:
	var mode_name = String(level.get("mode", ""))
	if mode_name == "conveyor" or mode_name == "bowling" or mode_name == "whack":
		return false
	return _available_seed_cards_for_level(level).size() > MAX_SEED_SLOTS


func _required_seed_count(level: Dictionary) -> int:
	var mode_name = String(level.get("mode", ""))
	if mode_name == "conveyor" or mode_name == "bowling":
		return 0
	if mode_name == "whack":
		return _available_seed_cards_for_level(level).size()
	return min(_available_seed_cards_for_level(level).size(), MAX_SEED_SLOTS)


func _default_level_cards(level: Dictionary) -> Array:
	var cards: Array = []
	var required_count = _required_seed_count(level)
	for kind in _available_seed_cards_for_level(level):
		if cards.size() >= required_count:
			break
		cards.append(kind)
	return cards


func _available_seed_cards_for_level(level: Dictionary) -> Array:
	var mode_name = String(level.get("mode", ""))
	if mode_name == "conveyor" or mode_name == "bowling" or mode_name == "whack":
		return level.get("available_plants", []).duplicate()
	return _player_plant_collection()


func _level_uses_persistent_plant_pool(level: Dictionary) -> bool:
	var mode_name = String(level.get("mode", ""))
	return mode_name != "conveyor" and mode_name != "bowling" and mode_name != "whack"


func _is_branch_level(level: Dictionary) -> bool:
	return level.has("unlock_requirements")


func _previous_mainline_level_index(level_index: int) -> int:
	for i in range(level_index - 1, -1, -1):
		if not _is_branch_level(Defs.LEVELS[i]):
			return i
	return -1


func _player_plant_collection() -> Array:
	var seen := {}
	for i in range(Defs.LEVELS.size()):
		var level = Defs.LEVELS[i]
		if _level_uses_persistent_plant_pool(level) and _is_level_unlocked(i):
			for kind_variant in level.get("available_plants", []):
				var plant_kind = String(kind_variant)
				if plant_kind == "" or seen.has(plant_kind) or not Defs.PLANTS.has(plant_kind):
					continue
				seen[plant_kind] = true
		if i < completed_levels.size() and bool(completed_levels[i]):
			var unlock_kind = String(level.get("unlock_plant", ""))
			if unlock_kind != "" and not seen.has(unlock_kind) and Defs.PLANTS.has(unlock_kind):
				seen[unlock_kind] = true
	if Defs.PLANTS.has("peashooter") and not seen.has("peashooter"):
		seen["peashooter"] = true
	var ordered: Array = []
	for kind in Defs.PLANT_ORDER:
		var plant_kind = String(kind)
		if seen.has(plant_kind):
			ordered.append(plant_kind)
	return ordered


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


func _world_key_for_level(level: Dictionary) -> String:
	var level_id = String(level.get("id", ""))
	if level_id.begins_with("3-"):
		return "pool"
	if level_id.begins_with("2-"):
		return "night"
	return "day"


func _world_start_index(world_key: String) -> int:
	for i in range(Defs.LEVELS.size()):
		if _world_key_for_level(Defs.LEVELS[i]) == world_key:
			return i
	return -1


func _visible_level_indices(world_key: String = current_world_key) -> Array:
	var result: Array = []
	for i in range(Defs.LEVELS.size()):
		if _world_key_for_level(Defs.LEVELS[i]) == world_key:
			result.append(i)
	return result


func _find_level_index_by_id(level_id: String) -> int:
	for i in range(Defs.LEVELS.size()):
		if String(Defs.LEVELS[i].get("id", "")) == level_id:
			return i
	return -1


func _level_unlock_requirements_met(level: Dictionary) -> bool:
	var requirements = level.get("unlock_requirements", [])
	if not (requirements is Array):
		return true
	for requirement in requirements:
		var index = _find_level_index_by_id(String(requirement))
		if index == -1 or index >= completed_levels.size() or not bool(completed_levels[index]):
			return false
	return true


func _is_level_unlocked(level_index: int) -> bool:
	if level_index < 0 or level_index >= Defs.LEVELS.size():
		return false
	var level = Defs.LEVELS[level_index]
	if level_index < completed_levels.size() and bool(completed_levels[level_index]):
		return true
	if not _level_unlock_requirements_met(level):
		return false
	if _is_branch_level(level):
		return true
	var previous_index = _previous_mainline_level_index(level_index)
	if previous_index == -1:
		return true
	return previous_index < completed_levels.size() and bool(completed_levels[previous_index])


func _visible_unlocked_count(world_key: String) -> int:
	var count := 0
	for index in _visible_level_indices(world_key):
		if _is_level_unlocked(int(index)):
			count += 1
	return count


func _is_world_unlocked(world_key: String) -> bool:
	var start_index = _world_start_index(world_key)
	return start_index != -1 and _is_level_unlocked(start_index)


func _visible_almanac_plants() -> Array:
	var seen := {}
	var result: Array = []
	for i in range(Defs.LEVELS.size()):
		if not _is_level_unlocked(i):
			continue
		var level = Defs.LEVELS[i]
		for kind in level["available_plants"]:
			var plant_kind = String(kind)
			if plant_kind == "" or seen.has(plant_kind):
				continue
			seen[plant_kind] = true
			result.append(plant_kind)
		var unlock_kind = String(level.get("unlock_plant", ""))
		if unlock_kind != "" and not seen.has(unlock_kind):
			seen[unlock_kind] = true
			result.append(unlock_kind)
	return result


func _visible_almanac_zombies() -> Array:
	var seen := {}
	var encountered := {}
	for i in range(Defs.LEVELS.size()):
		if not _is_level_unlocked(i):
			continue
		for event in Defs.LEVELS[i]["events"]:
			encountered[String(event["kind"])] = true
	var result: Array = []
	for kind in ZOMBIE_ALMANAC_ORDER:
		if encountered.has(kind) and not seen.has(kind):
			seen[kind] = true
			result.append(kind)
	return result


func _current_almanac_entries() -> Array:
	return _visible_almanac_plants() if almanac_tab == "plants" else _visible_almanac_zombies()


func _ensure_almanac_selection() -> void:
	var entries = _current_almanac_entries()
	if entries.is_empty():
		almanac_selected_kind = ""
		return
	if not entries.has(almanac_selected_kind):
		almanac_selected_kind = String(entries[0])
	_set_almanac_scroll(almanac_scroll)


func _almanac_list_view_rect() -> Rect2:
	return Rect2(
		ALMANAC_LIST_RECT.position + Vector2(16.0, 48.0),
		Vector2(ALMANAC_LIST_RECT.size.x - 42.0, ALMANAC_LIST_RECT.size.y - 76.0)
	)


func _almanac_list_hover_rect() -> Rect2:
	var view_rect = _almanac_list_view_rect()
	return Rect2(
		view_rect.position + Vector2(8.0, 10.0),
		Vector2(view_rect.size.x - 16.0, view_rect.size.y - 16.0)
	)


func _almanac_list_track_rect() -> Rect2:
	var view_rect = _almanac_list_view_rect()
	return Rect2(
		Vector2(ALMANAC_LIST_RECT.position.x + ALMANAC_LIST_RECT.size.x - 20.0, view_rect.position.y),
		Vector2(10.0, view_rect.size.y)
	)


func _almanac_content_height() -> float:
	var entries = _current_almanac_entries()
	var row_count = int(ceil(float(entries.size()) / float(ALMANAC_GRID_COLUMNS)))
	if row_count <= 0:
		return 0.0
	return 102.0 + float(max(row_count - 1, 0)) * ALMANAC_GRID_STEP.y


func _almanac_max_scroll() -> float:
	return maxf(0.0, _almanac_content_height() - _almanac_list_view_rect().size.y)


func _set_almanac_scroll(value: float) -> void:
	almanac_scroll = clampf(value, 0.0, _almanac_max_scroll())


func _almanac_item_rect(index: int) -> Rect2:
	var col = index % ALMANAC_GRID_COLUMNS
	var row = int(floor(float(index) / float(ALMANAC_GRID_COLUMNS)))
	var view_rect = _almanac_list_view_rect()
	var step_x = 90.0
	return Rect2(
		Vector2(view_rect.position.x + col * step_x, view_rect.position.y + row * ALMANAC_GRID_STEP.y - almanac_scroll),
		Vector2(80.0, 102.0)
	)


func _level_node_at(mouse_pos: Vector2) -> int:
	for index in _visible_level_indices():
		var node_pos = _map_node_position(int(index))
		if mouse_pos.distance_to(node_pos) <= 34.0:
			return int(index)
	return -1


func _mouse_to_cell(mouse_pos: Vector2) -> Vector2i:
	var board_rect = Rect2(BOARD_ORIGIN, board_size)
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


func _is_whack_level() -> bool:
	return String(current_level.get("mode", "")) == "whack"


func _is_night_level() -> bool:
	return not current_level.is_empty() and _world_key_for_level(current_level) == "night"


func _is_blood_moon_level() -> bool:
	return String(current_level.get("terrain", "")) == "blood_moon"


func _is_frozen_branch_level() -> bool:
	return String(current_level.get("terrain", "")) == "frozen_lake"


func _is_pool_level() -> bool:
	return not current_level.is_empty() and _world_key_for_level(current_level) == "pool"


func _is_water_row(row: int) -> bool:
	return water_rows.has(row)


func _grave_index_at(row: int, col: int) -> int:
	for i in range(graves.size()):
		var grave = graves[i]
		if int(grave["row"]) == row and int(grave["col"]) == col:
			return i
	return -1


func _setup_level_graves() -> void:
	graves = []
	if not _is_night_level():
		return
	if current_level.has("grave_layout"):
		for cell in current_level["grave_layout"]:
			graves.append({
				"row": int(cell.x),
				"col": int(cell.y),
			})
		return

	var level_id = String(current_level.get("id", "2-1"))
	var stage = 1
	var parts = level_id.split("-")
	if parts.size() >= 2:
		stage = max(1, int(parts[1]))

	var grave_count = clampi(stage, 1, 6)
	var candidates: Array = []
	for row in active_rows:
		for col in range(3, COLS - 1):
			candidates.append(Vector2i(int(row), col))

	for _i in range(min(grave_count, candidates.size())):
		var pick = rng.randi_range(0, candidates.size() - 1)
		var cell: Vector2i = candidates[pick]
		candidates.remove_at(pick)
		graves.append({
			"row": cell.x,
			"col": cell.y,
		})


func _update_conveyor(delta: float) -> void:
	if not _is_conveyor_level():
		return
	_sync_conveyor_special_cards()
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
	var kind = _pick_conveyor_card_for_slot(index)
	if kind == "":
		return
	active_cards[index] = kind


func _consume_conveyor_card(kind: String) -> void:
	for i in range(active_cards.size()):
		if String(active_cards[i]) == kind:
			active_cards[i] = ""
			break


func _available_grave_targets_for_conveyor() -> int:
	var occupied := 0
	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue
			if String(plant_variant.get("kind", "")) != "grave_buster":
				continue
			occupied += 1
	return max(0, graves.size() - occupied)


func _conveyor_grave_buster_count(ignore_slot: int = -1) -> int:
	var count := 0
	for i in range(active_cards.size()):
		if i == ignore_slot:
			continue
		if String(active_cards[i]) == "grave_buster":
			count += 1
	return count


func _pick_conveyor_card_for_slot(index: int) -> String:
	if conveyor_source_cards.is_empty():
		return ""
	var available_graves = _available_grave_targets_for_conveyor()
	var current_grave_busters = _conveyor_grave_buster_count(index)
	var options: Array = []
	for source_kind in conveyor_source_cards:
		var kind = String(source_kind)
		if kind == "grave_buster" and current_grave_busters >= available_graves:
			continue
		options.append(kind)
	if options.is_empty():
		return ""
	return String(options[rng.randi_range(0, options.size() - 1)])


func _sync_conveyor_special_cards() -> void:
	if not _is_conveyor_level():
		return
	var allowed_grave_busters = _available_grave_targets_for_conveyor()
	var kept_grave_busters := 0
	for i in range(active_cards.size()):
		if String(active_cards[i]) != "grave_buster":
			continue
		if kept_grave_busters < allowed_grave_busters:
			kept_grave_busters += 1
			continue
		var replacement = _pick_conveyor_card_for_slot(i)
		active_cards[i] = replacement


func _level_time_scale() -> float:
	if current_level.is_empty():
		return 1.0
	return float(current_level.get("time_scale", 1.0))


func _batch_pause_duration() -> float:
	return 1.4 * _level_time_scale()


func _intra_batch_spawn_delay() -> float:
	return clampf(0.62 * _level_time_scale(), 0.55, 1.2)


func _max_batch_size() -> int:
	if _is_whack_level():
		return 2
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
	if _is_whack_level():
		return 3
	return min(2, max(0, _target_batch_size() - 1))


func _active_zombie_count() -> int:
	return _enemy_zombie_count() + batch_spawn_remaining


func _estimated_total_spawn_count() -> int:
	var events = current_level.get("events", [])
	var total := 0
	for i in range(events.size()):
		total += 1 + _extra_spawn_count_for_event(i, events[i])
	total += pending_grave_wave_spawns
	return max(total, 1)


func _extra_spawn_count_for_event(event_index: int, event: Dictionary) -> int:
	if _is_whack_level():
		var total_events_whack = max(current_level["events"].size(), 1)
		var progress_whack = float(event_index + 1) / float(total_events_whack)
		var extra_whack := 0
		if progress_whack >= 0.3:
			extra_whack += 1
		if progress_whack >= 0.68:
			extra_whack += 1
		if _wave_marker_indices().has(event_index):
			extra_whack += 1
		if String(event["kind"]) == "buckethead":
			extra_whack = max(extra_whack - 1, 0)
		return min(extra_whack, 2)
	var total_events = max(current_level["events"].size(), 1)
	var progress = float(event_index + 1) / float(total_events)
	var extra := 2
	if progress >= 0.18:
		extra += 1
	if progress >= 0.34:
		extra += 1
	if progress >= 0.5:
		extra += 1
	if progress >= 0.68:
		extra += 1
	if progress >= 0.84:
		extra += 1
	if _wave_marker_indices().has(event_index):
		extra += 2
	if total_events <= 8:
		extra += 1
	var kind = String(event["kind"])
	if kind == "buckethead" or kind == "day_boss" or kind == "night_boss" or kind == "rumia_boss" or kind == "football" or kind == "dark_football":
		extra = max(extra - 2, 2)
	if kind == "screen_door":
		extra = max(extra - 1, 3)
	return min(extra, 8)


func _support_spawn_kind(main_kind: String, event_index: int, extra_index: int) -> String:
	var total_events = max(current_level["events"].size(), 1)
	var progress = float(event_index + 1) / float(total_events)
	match main_kind:
		"day_boss":
			if extra_index == 0:
				return "buckethead"
			return "kungfu" if progress >= 0.7 else "farmer"
		"night_boss":
			if extra_index == 0:
				return "nether"
			return "dark_football" if progress >= 0.7 else "screen_door"
		"rumia_boss":
			if extra_index == 0:
				return "conehead"
			return "buckethead" if progress >= 0.7 else "screen_door"
		"daiyousei_boss":
			if extra_index == 0:
				return "lifebuoy_normal" if progress >= 0.5 else "conehead"
			return "screen_door" if progress >= 0.7 else "normal"
		"cirno_boss":
			if extra_index == 0:
				return "lifebuoy_cone" if progress >= 0.5 else "snorkel"
			return "dark_football" if progress >= 0.78 else "screen_door"
		"buckethead":
			return "conehead" if extra_index == 0 else "normal"
		"pole_vault":
			return "conehead" if progress >= 0.55 else "normal"
		"farmer":
			return "conehead" if extra_index == 0 else "normal"
		"spear":
			return "conehead" if extra_index == 0 else "normal"
		"kungfu":
			return "conehead" if progress >= 0.6 else "normal"
		"flag":
			return "conehead" if progress >= 0.45 else "normal"
		_:
			return main_kind if progress >= 0.6 and extra_index == 0 else "normal"


func _support_spawn_row_for_event(event_row: int, kind: String) -> int:
	if event_row < 0:
		return -1
	var candidates = _eligible_spawn_rows_for_kind(kind)
	if candidates.is_empty():
		return -1
	var alternate_rows: Array = []
	for row in candidates:
		var row_i = int(row)
		if row_i != event_row:
			alternate_rows.append(row_i)
	if alternate_rows.is_empty():
		return event_row if candidates.has(event_row) else -1
	return int(alternate_rows[rng.randi_range(0, alternate_rows.size() - 1)])


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
		6:
			return [0, 1, 2, 3, 4, 5]
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
	if page_transition_active:
		var eased = ThemeLib.ease_ui(page_transition_progress)
		var width = size.x
		var from_offset = Vector2(-width * eased * page_transition_direction, 0.0)
		var to_offset = Vector2(width * (1.0 - eased) * page_transition_direction, 0.0)
		_draw_mode_scene(page_transition_from_mode, from_offset)
		_draw_mode_scene(page_transition_to_mode, to_offset)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.04, 0.08 * sin(eased * PI)), true)
		return
	_draw_mode_scene(mode, Vector2.ZERO)


func _draw_mode_scene(draw_mode: String, offset: Vector2) -> void:
	draw_set_transform(offset, 0.0, Vector2.ONE)
	if draw_mode == MODE_WORLD_SELECT:
		_draw_world_select_scene()
	elif draw_mode == MODE_MAP:
		_draw_map_scene()
	elif draw_mode == MODE_ALMANAC:
		_draw_almanac_scene()
	elif draw_mode == MODE_SELECTION:
		_draw_seed_selection_scene()
	else:
		_draw_battle_scene()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_panel_shell(rect: Rect2, fill_color: Color, border_color: Color, shadow_alpha: float = 0.18, accent_alpha: float = 0.14) -> void:
	ThemeLib.draw_panel_shell(self, rect, fill_color, border_color, shadow_alpha, accent_alpha)


func _draw_world_sky(is_night_world: bool) -> void:
	ThemeLib.draw_world_sky(self, size, ui_time, is_night_world)


func _draw_scroll_mask(content_rect: Rect2, view_rect: Rect2, fill_color: Color, border_color: Color) -> void:
	ThemeLib.draw_scroll_mask(self, content_rect, view_rect, fill_color, border_color)


func _path_midpoint(from: Vector2, to: Vector2, index: int) -> Vector2:
	var midpoint = (from + to) * 0.5
	var direction = (to - from).normalized()
	var normal = Vector2(-direction.y, direction.x)
	var offset = normal * (28.0 + float(index % 3) * 12.0) * (1.0 if index % 2 == 0 else -1.0)
	return midpoint + offset


func _world_card_rect(index: int) -> Rect2:
	var center_x = size.x * 0.5 + (float(index) - world_select_scroll) * 470.0
	var delta = absf(float(index) - world_select_scroll)
	var card_scale = clampf(1.0 - delta * 0.12, 0.84, 1.0)
	var card_size = Vector2(460.0, 560.0) * card_scale
	return Rect2(Vector2(center_x - card_size.x * 0.5, 150.0 + delta * 18.0), card_size)


func _draw_world_select_scene() -> void:
	var blend = clampf(world_select_scroll / float(max(WorldDataLib.all().size() - 1, 1)), 0.0, 1.0)
	var sky_night = blend >= 0.5
	_draw_world_sky(sky_night)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 120.0)), Color(0.08, 0.12, 0.2, 0.12) if sky_night else Color(1.0, 1.0, 1.0, 0.12), true)
	draw_rect(Rect2(Vector2(0.0, size.y - 142.0), Vector2(size.x, 142.0)), Color(0.12, 0.1, 0.08, 0.22), true)

	var title_rect = Rect2(58.0, 34.0, 616.0, 102.0)
	_draw_panel_shell(title_rect, Color(0.98, 0.94, 0.82, 0.95) if not sky_night else Color(0.16, 0.2, 0.32, 0.95), Color(0.54, 0.4, 0.16) if not sky_night else Color(0.58, 0.68, 0.88), 0.2, 0.12)
	_draw_text("世界选择", title_rect.position + Vector2(24.0, 42.0), 36, Color(0.22, 0.16, 0.06) if not sky_night else Color(0.94, 0.96, 1.0))
	_draw_text("像 PvZ2 一样先选世界，再进入该世界的关卡地图。", title_rect.position + Vector2(24.0, 76.0), 18, Color(0.3, 0.22, 0.08) if not sky_night else Color(0.82, 0.88, 0.98))

	for i in range(WorldDataLib.all().size()):
		var world = WorldDataLib.all()[i]
		var card_rect = _world_card_rect(i)
		var selected = roundi(world_select_scroll) == i
		var unlocked = _is_world_unlocked(String(world["key"])) or String(world["key"]) == "day"
		var fill = Color(world["panel"])
		var border = Color(world["accent_dark"])
		var accent = Color(world["accent"])
		if not unlocked:
			fill = fill.darkened(0.24)
		_draw_panel_shell(card_rect, fill, border, 0.24, 0.14)
		draw_rect(Rect2(card_rect.position + Vector2(18.0, 18.0), Vector2(card_rect.size.x - 36.0, 160.0)), Color(accent.r, accent.g, accent.b, 0.16), true)
		draw_circle(card_rect.position + Vector2(card_rect.size.x - 68.0, 72.0), 34.0, Color(accent.r, accent.g, accent.b, 0.22))
		if String(world["key"]) == "night":
			draw_circle(card_rect.position + Vector2(card_rect.size.x - 72.0, 76.0), 22.0, Color(0.92, 0.96, 1.0))
			draw_circle(card_rect.position + Vector2(card_rect.size.x - 64.0, 72.0), 20.0, fill)
		else:
			draw_circle(card_rect.position + Vector2(card_rect.size.x - 72.0, 76.0), 22.0, Color(1.0, 0.92, 0.38))
		if selected:
			draw_rect(card_rect.grow(4.0), Color(1.0, 0.92, 0.46, 0.42), false, 4.0)

		_draw_text(String(world["title"]), card_rect.position + Vector2(26.0, 56.0), 34, Color(0.22, 0.16, 0.06) if String(world["key"]) == "day" else Color(0.94, 0.96, 1.0))
		_draw_text(String(world["subtitle"]), card_rect.position + Vector2(26.0, 88.0), 18, Color(world["accent_dark"]).lerp(Color.WHITE, 0.15))
		_draw_text_block(String(world["description"]), Rect2(card_rect.position + Vector2(26.0, 112.0), Vector2(card_rect.size.x - 120.0, 72.0)), 18, Color(0.26, 0.2, 0.1) if String(world["key"]) == "day" else Color(0.82, 0.88, 0.96), 4.0, 3)

		var preview_plants = world["plants"]
		for plant_index in range(preview_plants.size()):
			var chip_rect = Rect2(card_rect.position + Vector2(26.0 + float(plant_index % 3) * 110.0, 208.0 + floor(float(plant_index) / 3.0) * 118.0), Vector2(96.0, 106.0))
			_draw_panel_shell(chip_rect, Color(0.98, 0.95, 0.88, 0.94) if String(world["key"]) == "day" else Color(0.24, 0.3, 0.42, 0.96), Color(world["accent_dark"]), 0.1, 0.06)
			_draw_card_icon(String(preview_plants[plant_index]), chip_rect.position + Vector2(chip_rect.size.x * 0.5, 56.0))
			_draw_text(String(Defs.PLANTS[String(preview_plants[plant_index])]["name"]), chip_rect.position + Vector2(8.0, 20.0), 12, Color(0.24, 0.16, 0.06) if String(world["key"]) == "day" else Color(0.92, 0.96, 1.0))

		var progress_label = "已解锁 %d/%d 关" % [_visible_unlocked_count(String(world["key"])), _visible_level_indices(String(world["key"])).size()]
		_draw_text(progress_label, card_rect.position + Vector2(26.0, card_rect.size.y - 52.0), 20, Color(world["accent_dark"]).lerp(Color.WHITE, 0.1))
		if not unlocked:
			draw_rect(card_rect, Color(0.0, 0.0, 0.0, 0.26), true)
			_draw_text("通关 1-16 后解锁", card_rect.position + Vector2(26.0, card_rect.size.y - 20.0), 20, Color(1.0, 0.96, 0.86))

	_draw_panel_shell(WORLD_SELECT_ARROW_LEFT_RECT, Color(0.96, 0.92, 0.82, 0.94), Color(0.48, 0.35, 0.16), 0.18, 0.12)
	_draw_panel_shell(WORLD_SELECT_ARROW_RIGHT_RECT, Color(0.96, 0.92, 0.82, 0.94), Color(0.48, 0.35, 0.16), 0.18, 0.12)
	draw_polyline(PackedVector2Array([WORLD_SELECT_ARROW_LEFT_RECT.get_center() + Vector2(12.0, -24.0), WORLD_SELECT_ARROW_LEFT_RECT.get_center() + Vector2(-10.0, 0.0), WORLD_SELECT_ARROW_LEFT_RECT.get_center() + Vector2(12.0, 24.0)]), Color(0.28, 0.18, 0.08), 7.0)
	draw_polyline(PackedVector2Array([WORLD_SELECT_ARROW_RIGHT_RECT.get_center() + Vector2(-12.0, -24.0), WORLD_SELECT_ARROW_RIGHT_RECT.get_center() + Vector2(10.0, 0.0), WORLD_SELECT_ARROW_RIGHT_RECT.get_center() + Vector2(-12.0, 24.0)]), Color(0.28, 0.18, 0.08), 7.0)

	var selected_world = _selected_world_data()
	var world_key = String(selected_world.get("key", "day"))
	var unlocked_world = _is_world_unlocked(world_key)
	var enter_fill = Color(selected_world.get("accent", Color(0.42, 0.76, 0.24)))
	if not unlocked_world:
		enter_fill = Color(0.44, 0.46, 0.52)
	_draw_panel_shell(WORLD_SELECT_ALMANAC_RECT, Color(0.94, 0.9, 0.82), Color(0.42, 0.3, 0.14), 0.18, 0.1)
	_draw_panel_shell(WORLD_SELECT_ENTER_RECT, enter_fill, Color(0.18, 0.22, 0.16), 0.22, 0.12)
	_draw_text("图鉴", WORLD_SELECT_ALMANAC_RECT.position + Vector2(94.0, 38.0), 24, Color(0.24, 0.16, 0.06))
	_draw_text("进入世界", WORLD_SELECT_ENTER_RECT.position + Vector2(66.0, 38.0), 26, Color(0.1, 0.14, 0.06) if unlocked_world else Color(0.9, 0.92, 0.96))
	_draw_text("滚轮或触控板左右滑动切换世界", Vector2(76.0, 836.0), 18, Color(0.24, 0.18, 0.08) if not sky_night else Color(0.86, 0.9, 0.98))


func _draw_map_scene() -> void:
	var is_night_world = current_world_key == "night"
	_draw_world_sky(is_night_world)
	var header_rect = Rect2(22.0, 22.0, 516.0, 88.0)
	_draw_panel_shell(header_rect, Color(0.96, 0.92, 0.8, 0.94) if not is_night_world else Color(0.18, 0.22, 0.34, 0.94), Color(0.48, 0.35, 0.16) if not is_night_world else Color(0.52, 0.62, 0.82), 0.14, 0.08)
	draw_circle(header_rect.position + Vector2(36.0, 44.0), 18.0, Color(1.0, 0.92, 0.34) if not is_night_world else Color(0.84, 0.9, 1.0))
	if is_night_world:
		draw_circle(header_rect.position + Vector2(42.0, 38.0), 18.0, Color(0.18, 0.22, 0.34, 0.94))
	else:
		draw_circle(header_rect.position + Vector2(36.0, 44.0), 30.0, Color(1.0, 0.92, 0.34, 0.12))
	var control_rect = Rect2(876.0, 20.0, 366.0, 96.0)
	_draw_panel_shell(control_rect, Color(0.95, 0.91, 0.8, 0.94) if not is_night_world else Color(0.18, 0.22, 0.34, 0.94), Color(0.48, 0.35, 0.16) if not is_night_world else Color(0.52, 0.62, 0.82), 0.14, 0.08)
	_draw_panel_shell(MAP_VIEW_RECT, Color(1.0, 1.0, 1.0, 0.06), Color(0.4, 0.28, 0.14, 0.2), 0.04, 0.03)

	_draw_panel_shell(Rect2(Vector2(40.0, 186.0), Vector2(220.0, 420.0)), Color(0.86, 0.78, 0.58), Color(0.54, 0.38, 0.18))
	_draw_panel_shell(Rect2(Vector2(64.0, 242.0), Vector2(170.0, 164.0)), Color(0.93, 0.88, 0.74), Color(0.58, 0.42, 0.2), 0.12, 0.1)
	draw_rect(Rect2(Vector2(94.0, 196.0), Vector2(110.0, 62.0)), Color(0.79, 0.28, 0.21), true)

	var nodes = []
	var visible_indices = _visible_level_indices()
	for index in visible_indices:
		nodes.append(_map_node_position(int(index)))

	for i in range(nodes.size() - 1):
		var mid = _path_midpoint(nodes[i], nodes[i + 1], i)
		draw_polyline(PackedVector2Array([nodes[i], mid, nodes[i + 1]]), Color(0.44, 0.34, 0.2, 0.8), 16.0)
		draw_polyline(PackedVector2Array([nodes[i], mid, nodes[i + 1]]), Color(0.82, 0.71, 0.42), 8.0)

	for index in visible_indices:
		_draw_level_node(int(index))

	_draw_text("夜晚冒险" if is_night_world else "白天冒险", Vector2(70.0, 58.0), 36, Color(0.95, 0.95, 0.98) if is_night_world else Color(0.23, 0.15, 0.05))
	_draw_text("点击灯泡进入关卡，超过 10 张植物时先进入选卡。", Vector2(70.0, 90.0), 18, Color(0.88, 0.9, 0.96) if is_night_world else Color(0.26, 0.18, 0.08))
	_draw_text("世界地图", control_rect.position + Vector2(16.0, 24.0), 18, Color(0.22, 0.16, 0.08) if not is_night_world else Color(0.9, 0.94, 1.0))
	_draw_panel_shell(MAP_SCROLL_LEFT_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.08, 0.04)
	_draw_panel_shell(MAP_SCROLL_RIGHT_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.08, 0.04)
	draw_polyline(PackedVector2Array([MAP_SCROLL_LEFT_RECT.get_center() + Vector2(8.0, -10.0), MAP_SCROLL_LEFT_RECT.get_center() + Vector2(-6.0, 0.0), MAP_SCROLL_LEFT_RECT.get_center() + Vector2(8.0, 10.0)]), Color(0.28, 0.18, 0.08), 4.0)
	draw_polyline(PackedVector2Array([MAP_SCROLL_RIGHT_RECT.get_center() + Vector2(-8.0, -10.0), MAP_SCROLL_RIGHT_RECT.get_center() + Vector2(6.0, 0.0), MAP_SCROLL_RIGHT_RECT.get_center() + Vector2(-8.0, 10.0)]), Color(0.28, 0.18, 0.08), 4.0)
	var scroll_hint = "触控板左右滑动或点箭头查看右侧支线" if _map_scroll_bounds_for_world(current_world_key).y > 0.0 else "当前世界地图已完整显示"
	_draw_text(scroll_hint, control_rect.position + Vector2(16.0, 68.0), 14, Color(0.28, 0.18, 0.08) if not is_night_world else Color(0.86, 0.92, 0.98))

	_draw_panel_shell(COIN_METER_RECT, Color(0.97, 0.89, 0.44), Color(0.48, 0.36, 0.09), 0.14, 0.08)
	_draw_coin_icon(COIN_METER_RECT.position + Vector2(22.0, 20.0), 1.0)
	_draw_text(str(coins_total), COIN_METER_RECT.position + Vector2(44.0, 27.0), 22, Color(0.31, 0.2, 0.05))
	_draw_panel_shell(MAP_WORLD_BACK_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.1, 0.06)
	_draw_text("世界页", MAP_WORLD_BACK_RECT.position + Vector2(24.0, 27.0), 18, Color(0.27, 0.18, 0.08))
	_draw_panel_shell(MAP_ALMANAC_BUTTON_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.1, 0.06)
	_draw_text("图鉴", MAP_ALMANAC_BUTTON_RECT.position + Vector2(28.0, 27.0), 18, Color(0.27, 0.18, 0.08))

	_draw_map_info_panel()


func _draw_almanac_scene() -> void:
	_draw_world_sky(false)
	draw_rect(Rect2(Vector2(0.0, 164.0), Vector2(size.x, size.y - 164.0)), Color(0.71, 0.82, 0.58), true)
	_draw_panel_shell(ALMANAC_BOOK_RECT, Color(0.93, 0.88, 0.75), Color(0.46, 0.34, 0.16), 0.16, 0.08)
	draw_line(ALMANAC_BOOK_RECT.position + Vector2(ALMANAC_BOOK_RECT.size.x * 0.38, 18.0), ALMANAC_BOOK_RECT.position + Vector2(ALMANAC_BOOK_RECT.size.x * 0.38, ALMANAC_BOOK_RECT.size.y - 18.0), Color(0.78, 0.68, 0.52), 3.0)

	_draw_text("图鉴", Vector2(106.0, 72.0), 34, Color(0.24, 0.16, 0.06))
	_draw_text("像原版 Almanac 一样查看植物和僵尸资料。", Vector2(106.0, 102.0), 18, Color(0.28, 0.2, 0.08))

	var plant_tab_color = Color(0.96, 0.92, 0.78) if almanac_tab == "plants" else Color(0.84, 0.8, 0.72)
	var zombie_tab_color = Color(0.96, 0.92, 0.78) if almanac_tab == "zombies" else Color(0.84, 0.8, 0.72)
	_draw_panel_shell(ALMANAC_PLANT_TAB_RECT, plant_tab_color, Color(0.42, 0.3, 0.14), 0.08, 0.05)
	_draw_panel_shell(ALMANAC_ZOMBIE_TAB_RECT, zombie_tab_color, Color(0.42, 0.3, 0.14), 0.08, 0.05)
	_draw_panel_shell(ALMANAC_CLOSE_RECT, Color(0.88, 0.84, 0.76), Color(0.42, 0.3, 0.14), 0.08, 0.05)
	_draw_text("植物", ALMANAC_PLANT_TAB_RECT.position + Vector2(34.0, 29.0), 20, Color(0.24, 0.16, 0.06))
	_draw_text("僵尸", ALMANAC_ZOMBIE_TAB_RECT.position + Vector2(34.0, 29.0), 20, Color(0.24, 0.16, 0.06))
	_draw_text("返回", ALMANAC_CLOSE_RECT.position + Vector2(28.0, 26.0), 18, Color(0.24, 0.16, 0.06))

	_draw_panel_shell(ALMANAC_LIST_RECT, Color(0.96, 0.93, 0.86), Color(0.44, 0.32, 0.14), 0.12, 0.06)
	_draw_panel_shell(ALMANAC_DETAIL_RECT, Color(0.96, 0.93, 0.86), Color(0.44, 0.32, 0.14), 0.12, 0.06)

	var entries = _current_almanac_entries()
	_draw_text("已收录 %d 项" % entries.size(), ALMANAC_LIST_RECT.position + Vector2(16.0, 24.0), 18, Color(0.28, 0.2, 0.08))
	_draw_text("滚轮/触控板可向下翻", ALMANAC_LIST_RECT.position + Vector2(178.0, 24.0), 14, Color(0.36, 0.28, 0.14))
	var view_rect = _almanac_list_view_rect()
	var hover_rect = _almanac_list_hover_rect()
	for i in range(entries.size()):
		var rect = _almanac_item_rect(i)
		if view_rect.intersects(rect):
			var allow_hover = hover_rect.encloses(rect)
			_draw_almanac_entry(String(entries[i]), rect, String(entries[i]) == almanac_selected_kind, almanac_tab == "plants", allow_hover)

	var list_content_rect = Rect2(
		ALMANAC_LIST_RECT.position + Vector2(10.0, 42.0),
		Vector2(ALMANAC_LIST_RECT.size.x - 14.0, ALMANAC_LIST_RECT.size.y - 50.0)
	)
	_draw_scroll_mask(list_content_rect, view_rect, Color(0.96, 0.93, 0.86), Color(0.58, 0.46, 0.24))

	var track_rect = _almanac_list_track_rect()
	_draw_panel_shell(track_rect, Color(0.84, 0.8, 0.72), Color(0.42, 0.3, 0.14), 0.06, 0.03)
	var knob_rect = ThemeLib.scroll_knob_rect(track_rect, view_rect.size.y, _almanac_content_height(), almanac_scroll)
	_draw_panel_shell(knob_rect, Color(0.58, 0.74, 0.3), Color(0.24, 0.36, 0.12), 0.04, 0.04)

	if almanac_selected_kind == "":
		return
	if almanac_tab == "plants":
		_draw_almanac_plant_detail(almanac_selected_kind)
	else:
		_draw_almanac_zombie_detail(almanac_selected_kind)


func _draw_level_node(level_index: int) -> void:
	var level = Defs.LEVELS[level_index]
	var world_levels = _visible_level_indices(_world_key_for_level(level))
	var world_order = max(0, world_levels.find(level_index)) + 1
	var node_pos = _map_node_position(level_index)
	var unlocked = _is_level_unlocked(level_index)
	var completed = bool(completed_levels[level_index])
	var hovered = level_index == hovered_level_index
	var pulse = 0.55 + 0.45 * sin(map_time * 3.2 + float(level_index) * 0.8)
	var hover_boost = 1.0 if hovered else 0.0

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
	if String(level.get("terrain", "")) == "blood_moon":
		halo_color = Color(1.0, 0.18, 0.26, 0.18 + 0.14 * pulse) if unlocked else Color(0.0, 0.0, 0.0, 0.0)
		bulb_color = Color(0.84, 0.08, 0.16) if unlocked else Color(0.42, 0.36, 0.4)
		outline = Color(0.28, 0.02, 0.04) if unlocked else Color(0.2, 0.18, 0.2)

	if unlocked:
		draw_circle(node_pos, 40.0 + 5.0 * pulse + hover_boost * 6.0, halo_color)
		if hovered:
			draw_circle(node_pos, 48.0 + 4.0 * sin(map_time * 6.0), Color(1.0, 0.98, 0.72, 0.1), false, 3.0)
	draw_circle(node_pos + Vector2(0.0, 7.0), 24.0, Color(0.18, 0.18, 0.2, 0.24))
	draw_circle(node_pos + Vector2(0.0, 6.0), 22.0, Color(0.42, 0.42, 0.46))
	draw_rect(Rect2(node_pos + Vector2(-11.0, 18.0), Vector2(22.0, 10.0)), Color(0.48, 0.48, 0.52), true)
	draw_circle(node_pos, 28.0 + hover_boost * 2.0, bulb_color)
	draw_circle(node_pos + Vector2(-8.0, -10.0), 8.0, Color(1.0, 1.0, 1.0, 0.42))
	draw_circle(node_pos + Vector2(10.0, 10.0), 3.0, Color(1.0, 1.0, 1.0, 0.2))
	draw_circle(node_pos, 28.0, outline, false, 2.0)
	_draw_text(str(world_order), node_pos + Vector2(-8.0, 7.0), 24, Color(0.19, 0.19, 0.2))
	_draw_text(String(level["id"]), node_pos + Vector2(-22.0, -42.0), 16, Color(0.25, 0.18, 0.08))
	if String(level.get("terrain", "")) == "blood_moon":
		draw_circle(node_pos, 18.0 + pulse * 4.0, Color(1.0, 0.3, 0.36, 0.16), false, 2.0)

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
		var world_levels = _visible_level_indices()
		if world_levels.is_empty():
			return
		var fallback_idx = min(world_levels.size() - 1, max(0, _visible_unlocked_count(current_world_key) - 1))
		info_index = int(world_levels[fallback_idx])

	var level = Defs.LEVELS[info_index]
	var panel_rect = Rect2(892.0, 122.0, 392.0, 152.0)
	_draw_panel_shell(panel_rect, Color(0.95, 0.9, 0.76), Color(0.48, 0.35, 0.16), 0.14, 0.08)

	var status_text = "已解锁"
	if not _is_level_unlocked(info_index):
		status_text = "未解锁"
	elif bool(completed_levels[info_index]):
		status_text = "已完成"

	_draw_text(String(level["title"]), panel_rect.position + Vector2(18.0, 34.0), 28, Color(0.24, 0.16, 0.06))
	_draw_text("状态：%s" % status_text, panel_rect.position + Vector2(18.0, 64.0), 18, Color(0.28, 0.2, 0.08))
	_draw_text_block(String(level["description"]), Rect2(panel_rect.position + Vector2(18.0, 72.0), Vector2(180.0, 52.0)), 16, Color(0.3, 0.22, 0.1), 3.0, 2)

	var unlock_text = "最终关"
	var unlock_color = Color(0.42, 0.2, 0.08)
	if bool(level.get("boss_level", false)):
		unlock_text = "Boss 关卡"
		unlock_color = Color(0.72, 0.16, 0.12)
	elif String(level["unlock_plant"]) != "":
		unlock_text = "解锁：" + String(Defs.PLANTS[String(level["unlock_plant"])]["name"])
		unlock_color = Color(0.1, 0.42, 0.18)
	else:
		var world_levels = _visible_level_indices(_world_key_for_level(level))
		var world_index = world_levels.find(info_index)
		if world_index != -1 and world_index < world_levels.size() - 1:
			unlock_text = "下一关：" + String(Defs.LEVELS[int(world_levels[world_index + 1])]["id"])
			unlock_color = Color(0.24, 0.3, 0.08)
	if not _is_level_unlocked(info_index):
		var requirements = level.get("unlock_requirements", [])
		if requirements is Array and not requirements.is_empty():
			unlock_text = "解锁条件：" + ", ".join(requirements)
			unlock_color = Color(0.64, 0.12, 0.12)
	_draw_text_block(unlock_text, Rect2(panel_rect.position + Vector2(18.0, 118.0), Vector2(184.0, 32.0)), 18, unlock_color, 2.0, 1)

	var plants = level["available_plants"]
	var plant_preview_count = min(plants.size(), 8)
	for i in range(plant_preview_count):
		var chip_x = panel_rect.position.x + 216.0 + float(i % 4) * 42.0
		var chip_y = panel_rect.position.y + 30.0 + floor(float(i) / 4.0) * 54.0
		var chip_rect = Rect2(chip_x, chip_y, 38.0, 48.0)
		_draw_panel_shell(chip_rect, Color(0.97, 0.94, 0.86), Color(0.48, 0.35, 0.16), 0.08, 0.04)
		_draw_card_icon(String(plants[i]), chip_rect.position + Vector2(chip_rect.size.x * 0.5, 24.0))
	if plants.size() > plant_preview_count:
		_draw_text("+%d" % (plants.size() - plant_preview_count), panel_rect.position + Vector2(338.0, 136.0), 16, Color(0.24, 0.16, 0.06))

	if _is_level_unlocked(info_index):
		var prompt = "点击灯泡选植物" if _requires_seed_selection(level) else "点击灯泡开始"
		_draw_text(prompt, panel_rect.position + Vector2(238.0, 136.0), 16, Color(0.3, 0.22, 0.1))
	else:
		_draw_text("先满足解锁条件", panel_rect.position + Vector2(232.0, 136.0), 16, Color(0.42, 0.18, 0.1))


func _draw_seed_selection_scene() -> void:
	_draw_world_sky(false)
	draw_rect(Rect2(Vector2(0.0, 148.0), Vector2(size.x, size.y - 148.0)), Color(0.68, 0.82, 0.5), true)
	draw_rect(Rect2(Vector2(0.0, 610.0), Vector2(size.x, 110.0)), Color(0.58, 0.42, 0.24), true)
	draw_rect(Rect2(Vector2(0.0, 148.0), Vector2(size.x, 44.0)), Color(1.0, 1.0, 1.0, 0.06), true)
	draw_rect(Rect2(Vector2(0.0, 566.0), Vector2(size.x, 30.0)), Color(0.0, 0.0, 0.0, 0.08), true)
	_draw_panel_shell(Rect2(Vector2(44.0, 182.0), Vector2(214.0, 392.0)), Color(0.86, 0.78, 0.58), Color(0.54, 0.38, 0.18))
	_draw_panel_shell(Rect2(Vector2(66.0, 238.0), Vector2(170.0, 164.0)), Color(0.93, 0.88, 0.74), Color(0.58, 0.42, 0.2), 0.12, 0.08)
	draw_rect(Rect2(Vector2(96.0, 192.0), Vector2(110.0, 62.0)), Color(0.79, 0.28, 0.21), true)

	_draw_panel_shell(PREP_SELECTED_PANEL_RECT, Color(0.95, 0.9, 0.76), Color(0.48, 0.35, 0.16), 0.14, 0.08)
	_draw_panel_shell(PREP_ZOMBIE_PANEL_RECT, Color(0.92, 0.88, 0.8), Color(0.48, 0.35, 0.16), 0.1, 0.05)
	_draw_panel_shell(PREP_POOL_PANEL_RECT, Color(0.95, 0.92, 0.84), Color(0.48, 0.35, 0.16), 0.14, 0.08)
	var required_count = _required_seed_count(current_level)

	_draw_text(String(current_level["title"]), Vector2(122.0, 56.0), 34, Color(0.23, 0.15, 0.05))
	_draw_text("植物超过 10 张时必须先选满 %d 张再开战" % max(required_count, 1), Vector2(122.0, 88.0), 18, Color(0.26, 0.18, 0.08))
	_draw_text_block(String(current_level["description"]), Rect2(Vector2(122.0, 98.0), Vector2(820.0, 44.0)), 16, Color(0.32, 0.24, 0.1), 3.0, 2)
	_draw_text("已选 %d/10" % selection_cards.size(), PREP_SELECTED_PANEL_RECT.position + Vector2(20.0, 30.0), 24, Color(0.2, 0.32, 0.08))
	_draw_text("本关僵尸", PREP_ZOMBIE_PANEL_RECT.position + Vector2(18.0, 32.0), 18, Color(0.24, 0.16, 0.06))
	_draw_text("可选植物", PREP_POOL_PANEL_RECT.position + Vector2(18.0, 30.0), 22, Color(0.24, 0.16, 0.06))
	_draw_text("点选下方卡牌加入上方卡槽，选满后右下角按钮高亮。", PREP_SELECTED_PANEL_RECT.position + Vector2(188.0, 28.0), 16, Color(0.28, 0.22, 0.1))
	var selection_progress_rect = Rect2(PREP_SELECTED_PANEL_RECT.position + Vector2(18.0, 90.0), Vector2(PREP_SELECTED_PANEL_RECT.size.x - 36.0, 18.0))
	draw_rect(selection_progress_rect, Color(0.34, 0.24, 0.12, 0.22), true)
	var selection_fill = ThemeLib.progress_fill_rect(selection_progress_rect, float(selection_cards.size()) / float(max(required_count, 1)))
	draw_rect(selection_fill, Color(0.52, 0.8, 0.26, 0.84), true)
	draw_rect(Rect2(selection_fill.position, Vector2(selection_fill.size.x, selection_fill.size.y * 0.42)), Color(0.96, 1.0, 0.82, 0.26), true)
	draw_rect(selection_progress_rect, Color(0.4, 0.28, 0.12, 0.4), false, 2.0)

	for i in range(MAX_SEED_SLOTS):
		var slot_rect = _selection_slot_rect(i)
		_draw_panel_shell(slot_rect, Color(0.9, 0.86, 0.76), Color(0.46, 0.34, 0.16), 0.08, 0.04)
		if i < selection_cards.size():
			_draw_selection_card(String(selection_cards[i]), slot_rect, true, false)
		else:
			_draw_text(str(i + 1), slot_rect.position + Vector2(34.0, 62.0), 28, Color(0.46, 0.36, 0.22, 0.28))

	var zombie_kinds = _selection_zombie_kinds()
	for i in range(zombie_kinds.size()):
		var chip_rect = Rect2(PREP_ZOMBIE_PANEL_RECT.position + Vector2(126.0 + i * 138.0, 8.0), Vector2(124.0, 34.0))
		_draw_panel_shell(chip_rect, Color(0.87, 0.9, 0.84), Color(0.42, 0.35, 0.2), 0.05, 0.04)
		_draw_text(String(Defs.ZOMBIES[String(zombie_kinds[i])]["name"]), chip_rect.position + Vector2(12.0, 22.0), 15, Color(0.22, 0.16, 0.08))

	var pool_view_rect = _selection_pool_view_rect()
	var pool_hover_rect = _selection_pool_hover_rect()
	for i in range(selection_pool_cards.size()):
		var kind = String(selection_pool_cards[i])
		var selected = selection_cards.has(kind)
		var disabled = selection_cards.size() >= MAX_SEED_SLOTS and not selected
		var card_rect = _selection_pool_rect(i)
		if pool_view_rect.encloses(card_rect):
			var allow_hover = pool_hover_rect.encloses(card_rect)
			_draw_selection_card(kind, card_rect, selected, disabled, allow_hover)

	var pool_content_rect = Rect2(
		PREP_POOL_PANEL_RECT.position + Vector2(10.0, 38.0),
		Vector2(PREP_POOL_PANEL_RECT.size.x - 14.0, PREP_POOL_PANEL_RECT.size.y - 46.0)
	)
	_draw_scroll_mask(pool_content_rect, pool_view_rect, Color(0.95, 0.92, 0.84), Color(0.58, 0.46, 0.24))

	var track_rect = _selection_pool_track_rect()
	_draw_panel_shell(track_rect, Color(0.84, 0.8, 0.72), Color(0.42, 0.3, 0.14), 0.05, 0.03)
	var max_scroll = _selection_pool_max_scroll()
	var knob_rect = ThemeLib.scroll_knob_rect(track_rect, _selection_pool_view_rect().size.y, _selection_pool_content_height(), selection_pool_scroll)
	_draw_panel_shell(knob_rect, Color(0.58, 0.74, 0.3), Color(0.24, 0.36, 0.12), 0.04, 0.03)
	if max_scroll > 0.0:
		_draw_text("滚动查看", PREP_POOL_PANEL_RECT.position + Vector2(PREP_POOL_PANEL_RECT.size.x - 94.0, 30.0), 14, Color(0.24, 0.16, 0.06))

	var back_color = Color(0.88, 0.84, 0.76)
	var start_color = Color(0.42, 0.76, 0.24) if selection_cards.size() >= required_count else Color(0.62, 0.62, 0.62)
	_draw_panel_shell(PREP_BACK_RECT, back_color, Color(0.42, 0.3, 0.14), 0.08, 0.04)
	_draw_panel_shell(PREP_START_RECT, start_color, Color(0.22, 0.36, 0.12), 0.08, 0.04)
	_draw_text("返回地图", PREP_BACK_RECT.position + Vector2(18.0, 28.0), 18, Color(0.26, 0.18, 0.08))
	_draw_text("开始战斗", PREP_START_RECT.position + Vector2(24.0, 28.0), 20, Color(0.08, 0.2, 0.04))


func _draw_selection_card(kind: String, rect: Rect2, selected: bool, disabled: bool, allow_hover: bool = true) -> void:
	var mouse_pos = get_local_mouse_position()
	var hovered = allow_hover and rect.has_point(mouse_pos)
	var lift = 4.0 if hovered and not disabled else 0.0
	var card_rect_draw = rect.grow(2.0 if hovered else 0.0)
	card_rect_draw.position.y -= lift
	var bg = Color(0.96, 0.94, 0.87) if not disabled else Color(0.82, 0.8, 0.76)
	if hovered and not disabled:
		draw_rect(card_rect_draw.grow(6.0), Color(1.0, 0.96, 0.72, 0.12), true)
	_draw_panel_shell(card_rect_draw, bg, Color(0.42, 0.3, 0.14), 0.08, 0.05)
	if selected:
		var pulse = 0.72 + 0.28 * sin(ui_time * 6.0 + rect.position.x * 0.02)
		draw_rect(card_rect_draw.grow(6.0), Color(1.0, 0.9, 0.3, 0.08 * pulse), true)
		draw_rect(card_rect_draw.grow(-1.0), Color(0.94, 0.84, 0.24), false, 3.0)
	_draw_card_icon(kind, card_rect_draw.position + Vector2(card_rect_draw.size.x * 0.5, card_rect_draw.size.y * 0.53))
	_draw_text(String(Defs.PLANTS[kind]["name"]), card_rect_draw.position + Vector2(8.0, 18.0), 12, Color(0.28, 0.18, 0.06))
	_draw_text(str(Defs.PLANTS[kind]["cost"]), card_rect_draw.position + Vector2(10.0, card_rect_draw.size.y - 10.0), 16, Color(0.28, 0.18, 0.06))
	if disabled:
		draw_rect(card_rect_draw, Color(0.0, 0.0, 0.0, 0.16), true)


func _draw_almanac_entry(kind: String, rect: Rect2, selected: bool, is_plant: bool, allow_hover: bool = true) -> void:
	var mouse_pos = get_local_mouse_position()
	var hovered = allow_hover and rect.has_point(mouse_pos)
	var card_rect_draw = rect.grow(2.0 if hovered else 0.0)
	card_rect_draw.position.y -= 3.0 if hovered else 0.0
	if hovered:
		draw_rect(card_rect_draw.grow(5.0), Color(1.0, 1.0, 1.0, 0.06), true)
	_draw_panel_shell(card_rect_draw, Color(0.95, 0.93, 0.86), Color(0.42, 0.3, 0.14), 0.08, 0.05)
	if selected:
		var pulse = 0.76 + 0.24 * sin(ui_time * 5.2 + rect.position.y * 0.03)
		draw_rect(card_rect_draw.grow(6.0), Color(1.0, 0.88, 0.2, 0.08 * pulse), true)
		draw_rect(card_rect_draw.grow(-1.0), Color(0.96, 0.84, 0.24), false, 3.0)
	if is_plant:
		_draw_card_icon(kind, card_rect_draw.position + Vector2(card_rect_draw.size.x * 0.5, 46.0))
		_draw_text(String(Defs.PLANTS[kind]["name"]), card_rect_draw.position + Vector2(4.0, 18.0), 11, Color(0.28, 0.18, 0.06))
	else:
		_draw_zombie_icon(kind, card_rect_draw.position + Vector2(card_rect_draw.size.x * 0.5, 58.0), 0.72)
		_draw_text(String(Defs.ZOMBIES[kind]["name"]), card_rect_draw.position + Vector2(4.0, 18.0), 11, Color(0.28, 0.18, 0.06))


func _draw_almanac_plant_detail(kind: String) -> void:
	var data = Defs.PLANTS[kind]
	var icon_center = ALMANAC_DETAIL_RECT.position + Vector2(114.0, 112.0)
	_draw_panel_shell(Rect2(ALMANAC_DETAIL_RECT.position + Vector2(36.0, 46.0), Vector2(156.0, 170.0)), Color(0.98, 0.95, 0.88), Color(0.46, 0.34, 0.16), 0.08, 0.06)
	_draw_card_icon(kind, icon_center)
	_draw_text(String(data["name"]), ALMANAC_DETAIL_RECT.position + Vector2(214.0, 54.0), 32, Color(0.24, 0.16, 0.06))
	var stats = _plant_almanac_stats(kind)
	for i in range(stats.size()):
		var chip_rect = Rect2(ALMANAC_DETAIL_RECT.position + Vector2(206.0, 76.0 + i * 32.0), Vector2(378.0, 26.0))
		_draw_panel_shell(chip_rect, Color(0.98, 0.95, 0.88), Color(0.52, 0.4, 0.22), 0.04, 0.04)
		_draw_text(String(stats[i]), chip_rect.position + Vector2(12.0, 19.0), 18, Color(0.28, 0.2, 0.08))
	var lines = _plant_almanac_lines(kind)
	var plant_text := ""
	for i in range(lines.size()):
		if i > 0:
			plant_text += "\n"
		plant_text += String(lines[i])
	_draw_text_block(plant_text, Rect2(ALMANAC_DETAIL_RECT.position + Vector2(44.0, 224.0), Vector2(564.0, 196.0)), 20, Color(0.26, 0.18, 0.08), 8.0, 5)


func _draw_almanac_zombie_detail(kind: String) -> void:
	var data = Defs.ZOMBIES[kind]
	var icon_center = ALMANAC_DETAIL_RECT.position + Vector2(122.0, 136.0)
	_draw_panel_shell(Rect2(ALMANAC_DETAIL_RECT.position + Vector2(36.0, 46.0), Vector2(172.0, 196.0)), Color(0.98, 0.95, 0.88), Color(0.46, 0.34, 0.16), 0.08, 0.06)
	_draw_zombie_icon(kind, icon_center, 1.18)
	_draw_text(String(data["name"]), ALMANAC_DETAIL_RECT.position + Vector2(224.0, 54.0), 32, Color(0.24, 0.16, 0.06))
	var stats = _zombie_almanac_stats(kind)
	for i in range(stats.size()):
		var chip_rect = Rect2(ALMANAC_DETAIL_RECT.position + Vector2(216.0, 76.0 + i * 32.0), Vector2(378.0, 26.0))
		_draw_panel_shell(chip_rect, Color(0.98, 0.95, 0.88), Color(0.52, 0.4, 0.22), 0.04, 0.04)
		_draw_text(String(stats[i]), chip_rect.position + Vector2(12.0, 19.0), 18, Color(0.28, 0.2, 0.08))
	var lines = _zombie_almanac_lines(kind)
	var zombie_text := ""
	for i in range(lines.size()):
		if i > 0:
			zombie_text += "\n"
		zombie_text += String(lines[i])
	_draw_text_block(zombie_text, Rect2(ALMANAC_DETAIL_RECT.position + Vector2(44.0, 240.0), Vector2(564.0, 188.0)), 20, Color(0.26, 0.18, 0.08), 8.0, 5)


func _ease_out_back(t: float) -> float:
	var x = clampf(t, 0.0, 1.0)
	var c1 = 1.70158
	var c3 = c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


func _plant_draw_motion(plant: Dictionary, base_center: Vector2) -> Dictionary:
	var phase = float(plant.get("anim_phase", 0.0))
	var appear_t = clampf((level_time - float(plant.get("spawn_time", level_time))) / 0.24, 0.0, 1.0)
	var appear = _ease_out_back(appear_t)
	var kind = String(plant["kind"])
	var bob_strength = 1.8
	var sway_strength = 0.03
	if kind == "wallnut" or kind == "grave_buster":
		bob_strength = 0.8
		sway_strength = 0.015
	elif kind == "potato_mine":
		bob_strength = 0.6
		sway_strength = 0.01
	elif kind.ends_with("shroom"):
		bob_strength = 2.2
		sway_strength = 0.025
	var breathe = sin(level_time * 2.4 + phase)
	var bob = sin(level_time * 2.8 + phase) * bob_strength
	var sway = sin(level_time * 1.7 + phase) * sway_strength
	var scale_x = 1.0 + breathe * 0.018
	var scale_y = 1.0 - breathe * 0.018
	var center_offset = Vector2(0.0, bob)
	var action_ratio = 0.0
	if float(plant.get("action_timer", 0.0)) > 0.0:
		var duration = maxf(float(plant.get("action_duration", 0.18)), 0.01)
		action_ratio = sin((1.0 - clampf(float(plant["action_timer"]) / duration, 0.0, 1.0)) * PI)
	if kind == "cherry_bomb" or kind == "ice_shroom" or kind == "doom_shroom":
		var fuse_ratio = 1.0 - clampf(float(plant.get("fuse_timer", 0.0)) / 0.75, 0.0, 1.0)
		scale_x += fuse_ratio * 0.06
		scale_y += fuse_ratio * 0.06
		center_offset += Vector2(sin(level_time * 22.0 + phase) * fuse_ratio * 4.0, -fuse_ratio * 3.0)
	elif kind == "potato_mine" and bool(plant.get("armed", false)):
		scale_x += 0.04 * absf(sin(level_time * 6.0 + phase))
		scale_y += 0.04 * absf(sin(level_time * 6.0 + phase))
	match kind:
		"peashooter", "snow_pea", "repeater", "amber_shooter", "puff_shroom", "scaredy_shroom", "sun_bean":
			center_offset += Vector2(-10.0 * action_ratio, 0.0)
			scale_x += 0.08 * action_ratio
			sway += 0.06 * action_ratio
		"sunflower", "sun_shroom", "moon_lotus":
			center_offset += Vector2(0.0, -8.0 * action_ratio)
			scale_x += 0.06 * action_ratio
			scale_y += 0.08 * action_ratio
		"chomper", "grave_buster":
			center_offset += Vector2(10.0 * action_ratio, -8.0 * action_ratio)
			sway += 0.08 * action_ratio
		"vine_lasher", "wind_orchid", "root_snare":
			center_offset += Vector2(8.0 * action_ratio, -4.0 * action_ratio)
			sway += 0.1 * action_ratio
		"pepper_mortar", "meteor_gourd", "dream_drum":
			center_offset += Vector2(-6.0 * action_ratio, -12.0 * action_ratio)
			scale_y += 0.08 * action_ratio
		"pulse_bulb", "fume_shroom", "ice_shroom", "doom_shroom", "lantern_bloom", "thunder_pine":
			scale_x += 0.1 * action_ratio
			scale_y += 0.1 * action_ratio
		"wallnut", "cactus_guard", "potato_mine", "prism_grass":
			scale_x += 0.05 * action_ratio
			scale_y -= 0.04 * action_ratio
	if kind == "fume_shroom":
		center_offset += Vector2(12.0 * action_ratio, -4.0 * action_ratio)
		scale_x += 0.06 * action_ratio
		scale_y -= 0.02 * action_ratio
	if kind == "squash":
		var squash_state = String(plant.get("special_state", ""))
		var squash_duration = maxf(float(plant.get("special_duration", 0.16)), 0.01)
		var squash_ratio = 1.0 - clampf(float(plant.get("special_timer", 0.0)) / squash_duration, 0.0, 1.0)
		var travel = clampf(float(plant.get("attack_target_x", base_center.x)) - base_center.x, -CELL_SIZE.x * 0.55, CELL_SIZE.x * 1.25)
		match squash_state:
			"windup":
				center_offset += Vector2(10.0 * squash_ratio, 10.0 * squash_ratio)
				scale_x += 0.18 * squash_ratio
				scale_y -= 0.24 * squash_ratio
				sway += 0.12 * squash_ratio
			"launch":
				var arc = sin(squash_ratio * PI)
				center_offset += Vector2(travel * squash_ratio, -arc * 82.0)
				scale_x += 0.24 * arc
				scale_y -= 0.14 * arc
				sway += 0.16 * squash_ratio * signf(travel if absf(travel) > 0.01 else 1.0)
			"slam":
				center_offset += Vector2(travel, 8.0 * squash_ratio)
				scale_x += 0.28 * (1.0 - squash_ratio * 0.3)
				scale_y -= 0.34 * (1.0 - squash_ratio * 0.2)
	return {
		"center": base_center + center_offset,
		"rotation": sway,
		"scale": Vector2(scale_x * appear, scale_y * appear),
	}


func _zombie_draw_motion(zombie: Dictionary, base_center: Vector2) -> Dictionary:
	var phase = float(zombie.get("anim_phase", 0.0))
	var appear_t = clampf((level_time - float(zombie.get("spawn_time", level_time))) / 0.22, 0.0, 1.0)
	var appear = _ease_out_back(appear_t)
	if _is_hovering_boss_kind(String(zombie.get("kind", ""))):
		var kind = String(zombie.get("kind", ""))
		var move_timer = float(zombie.get("rumia_move_timer", 0.0))
		var move_duration = maxf(float(zombie.get("rumia_move_duration", 0.0)), 0.001)
		var shift_ratio = 0.0
		var visual_y = base_center.y
		if move_timer > 0.0:
			shift_ratio = 1.0 - clampf(move_timer / move_duration, 0.0, 1.0)
			shift_ratio = shift_ratio * shift_ratio * (3.0 - 2.0 * shift_ratio)
			visual_y = lerpf(float(zombie.get("rumia_move_from_y", base_center.y)), float(zombie.get("rumia_move_to_y", base_center.y)), shift_ratio)
		var hover_amp = 5.0
		var drift_amp = 4.0
		var swoop_amp = -26.0
		var stretch_base = 0.02
		match kind:
			"daiyousei_boss":
				hover_amp = 6.0
				drift_amp = 5.0
				swoop_amp = -22.0
				stretch_base = 0.024
			"cirno_boss":
				hover_amp = 7.0
				drift_amp = 5.8
				swoop_amp = -30.0
				stretch_base = 0.028
		var hover = sin(level_time * 2.1 + phase) * (hover_amp + shift_ratio * 2.8)
		var drift = cos(level_time * 1.3 + phase + shift_ratio * 1.7) * (drift_amp + shift_ratio * 3.4)
		var swoop = sin(shift_ratio * PI) * swoop_amp
		var sway = sin(level_time * 1.1 + phase + shift_ratio * 1.6) * (0.02 + shift_ratio * 0.045)
		var stretch = 1.0 + sin(level_time * 2.4 + phase + shift_ratio) * stretch_base + shift_ratio * 0.03
		return {
			"center": Vector2(base_center.x, visual_y) + Vector2(drift, hover + swoop - 8.0),
			"rotation": sway,
			"scale": Vector2(stretch * appear, (2.0 - stretch) * appear),
		}
	var moving = not bool(zombie.get("jumping", false)) and float(zombie.get("special_pause_timer", 0.0)) <= 0.0 and float(zombie.get("boss_pause_timer", 0.0)) <= 0.0 and float(zombie.get("weed_pause_timer", 0.0)) <= 0.0 and float(zombie.get("reflect_timer", 0.0)) <= 0.0
	var speed = float(zombie.get("base_speed", Defs.ZOMBIES[String(zombie["kind"])].get("speed", 18.0)))
	if float(zombie.get("slow_timer", 0.0)) > 0.0:
		speed *= 0.5
	var cycle = level_time * (3.0 + speed * 0.07) + phase + float(zombie.get("x", 0.0)) * 0.015
	var stride = sin(cycle) if moving else sin(level_time * 1.2 + phase) * 0.18
	var bob = absf(stride) * 3.2
	var lean = -0.03 - clampf(speed / 700.0, 0.0, 0.06) if moving else -0.01
	var squash = absf(stride) * 0.02
	var center_offset = Vector2(0.0, -bob)
	var bite_ratio = 0.0
	if float(zombie.get("bite_timer", 0.0)) > 0.0:
		bite_ratio = sin((1.0 - clampf(float(zombie["bite_timer"]) / 0.18, 0.0, 1.0)) * PI)
	var impact_ratio = 0.0
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		impact_ratio = sin((1.0 - clampf(float(zombie["impact_timer"]) / 0.16, 0.0, 1.0)) * PI)
	center_offset += Vector2(12.0 * bite_ratio, -5.0 * bite_ratio)
	center_offset += Vector2(10.0 * impact_ratio, 0.0)
	lean -= 0.14 * bite_ratio
	lean += 0.12 * impact_ratio
	squash += 0.04 * impact_ratio
	if String(zombie["kind"]) == "newspaper" and float(zombie.get("shield_health", 0.0)) <= 0.0:
		lean -= 0.06
	if _is_water_zombie_kind(String(zombie["kind"])):
		center_offset += Vector2(0.0, -2.0 + sin(level_time * 3.8 + phase) * 4.0)
		lean += 0.012 * sin(level_time * 2.8 + phase)
	if String(zombie["kind"]) == "dancing" and float(zombie.get("special_pause_timer", 0.0)) > 0.0:
		center_offset += Vector2(0.0, -10.0 * sin((1.0 - clampf(float(zombie["special_pause_timer"]) / 0.78, 0.0, 1.0)) * PI))
		lean += 0.05
	if String(zombie["kind"]) == "kungfu" and float(zombie.get("reflect_timer", 0.0)) > 0.0:
		lean += 0.04 * sin(level_time * 10.0 + phase)
	if String(zombie["kind"]) == "ninja" and bool(zombie.get("ninja_dashed", false)):
		lean -= 0.05
	if String(zombie["kind"]) == "nether":
		center_offset += Vector2(0.0, -3.0 - absf(sin(level_time * 3.0 + phase)) * 3.0)
	if String(zombie["kind"]) == "nezha" and float(zombie.get("burn_timer", 0.0)) > 0.0:
		lean += 0.05 * sin(level_time * 12.0 + phase)
	return {
		"center": base_center + center_offset,
		"rotation": lean,
		"scale": Vector2((1.0 + squash) * appear, (1.0 - squash * 0.6) * appear),
	}


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
	_draw_boss_health_bar()

	if battle_state != BATTLE_PLAYING:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.28), true)


func _draw_battle_background() -> void:
	if _is_blood_moon_level():
		_draw_rect_full(Color(0.18, 0.0, 0.04))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 156.0)), Color(0.32, 0.02, 0.06), true)
		draw_circle(Vector2(112.0, 72.0), 40.0, Color(0.92, 0.08, 0.12))
		draw_circle(Vector2(112.0, 72.0), 68.0, Color(1.0, 0.08, 0.12, 0.12))
		draw_circle(Vector2(126.0, 68.0), 38.0, Color(0.12, 0.0, 0.04))
		for cloud_index in range(4):
			var drift = fmod(ui_time * (6.0 + cloud_index * 1.6), 220.0)
			var cloud_pos = Vector2(240.0 + float(cloud_index) * 270.0 + drift, 46.0 + float(cloud_index % 2) * 26.0)
			draw_circle(cloud_pos, 22.0, Color(0.28, 0.04, 0.08, 0.54))
			draw_circle(cloud_pos + Vector2(20.0, 7.0), 18.0, Color(0.38, 0.04, 0.1, 0.58))
			draw_circle(cloud_pos + Vector2(-18.0, 8.0), 16.0, Color(0.18, 0.02, 0.06, 0.52))
		draw_rect(Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.36, 0.05, 0.08), true)
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 184.0), Vector2(180.0, 154.0), Vector2(362.0, 204.0),
				Vector2(616.0, 160.0), Vector2(852.0, 214.0), Vector2(1110.0, 170.0),
				Vector2(size.x, 208.0), Vector2(size.x, 238.0), Vector2(0.0, 238.0),
			]),
			PackedColorArray([
				Color(0.22, 0.02, 0.04), Color(0.22, 0.02, 0.04), Color(0.22, 0.02, 0.04),
				Color(0.22, 0.02, 0.04), Color(0.22, 0.02, 0.04), Color(0.22, 0.02, 0.04),
				Color(0.22, 0.02, 0.04), Color(0.22, 0.02, 0.04), Color(0.22, 0.02, 0.04),
			])
		)
		draw_rect(Rect2(Vector2(28.0, 118.0), Vector2(160.0, size.y - 118.0)), Color(0.54, 0.12, 0.1), true)
		draw_rect(Rect2(Vector2(46.0, 164.0), Vector2(124.0, 144.0)), Color(0.72, 0.22, 0.18), true)
		draw_rect(Rect2(Vector2(68.0, 122.0), Vector2(80.0, 56.0)), Color(0.4, 0.04, 0.08), true)
		draw_rect(Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.36, 0.08, 0.06), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.42, 0.12, 0.1), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.24, 0.04, 0.06), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 22.0, BOARD_ORIGIN.y + 18.0), Vector2(board_size.x + 96.0, 96.0)), Color(1.0, 0.18, 0.24, 0.05), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 34.0, BOARD_ORIGIN.y + 232.0), Vector2(board_size.x + 116.0, 84.0)), Color(0.0, 0.0, 0.0, 0.1), true)
	elif _is_frozen_branch_level():
		_draw_rect_full(Color(0.76, 0.88, 1.0))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 154.0)), Color(0.9, 0.96, 1.0), true)
		draw_circle(Vector2(112.0, 74.0), 50.0, Color(0.96, 0.98, 1.0, 0.18))
		draw_circle(Vector2(112.0, 74.0), 32.0, Color(0.98, 1.0, 1.0))
		for cloud_index in range(5):
			var drift = fmod(ui_time * (7.0 + cloud_index * 1.3), 240.0)
			var cloud_pos = Vector2(228.0 + float(cloud_index) * 232.0 + drift, 46.0 + float(cloud_index % 3) * 22.0)
			draw_circle(cloud_pos, 22.0, Color(1.0, 1.0, 1.0, 0.54))
			draw_circle(cloud_pos + Vector2(18.0, 7.0), 18.0, Color(1.0, 1.0, 1.0, 0.64))
			draw_circle(cloud_pos + Vector2(-18.0, 8.0), 16.0, Color(0.92, 0.98, 1.0, 0.44))
		draw_rect(Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.7, 0.82, 0.66), true)
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 180.0), Vector2(164.0, 150.0), Vector2(340.0, 196.0),
				Vector2(602.0, 156.0), Vector2(858.0, 212.0), Vector2(1098.0, 170.0),
				Vector2(size.x, 204.0), Vector2(size.x, 236.0), Vector2(0.0, 236.0),
			]),
			PackedColorArray([
				Color(0.54, 0.68, 0.52), Color(0.54, 0.68, 0.52), Color(0.54, 0.68, 0.52),
				Color(0.54, 0.68, 0.52), Color(0.54, 0.68, 0.52), Color(0.54, 0.68, 0.52),
				Color(0.54, 0.68, 0.52), Color(0.54, 0.68, 0.52), Color(0.54, 0.68, 0.52),
			])
		)
		draw_rect(Rect2(Vector2(28.0, 118.0), Vector2(166.0, size.y - 118.0)), Color(0.88, 0.92, 0.9), true)
		draw_rect(Rect2(Vector2(46.0, 164.0), Vector2(128.0, 146.0)), Color(0.95, 0.97, 0.96), true)
		draw_rect(Rect2(Vector2(68.0, 124.0), Vector2(84.0, 54.0)), Color(0.52, 0.72, 0.84), true)
		draw_rect(Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.78, 0.84, 0.84), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.66, 0.74, 0.74), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.58, 0.7, 0.62), true)
		var frozen_left = Rect2(Vector2(BOARD_ORIGIN.x - 14.0, BOARD_ORIGIN.y - 8.0), Vector2(CELL_SIZE.x * 5.0 + 24.0, board_size.y + 16.0))
		draw_rect(frozen_left, Color(0.68, 0.88, 1.0, 0.12), true)
		draw_rect(Rect2(frozen_left.position + Vector2(0.0, 12.0), Vector2(frozen_left.size.x, frozen_left.size.y * 0.3)), Color(1.0, 1.0, 1.0, 0.05), true)
		for snow_index in range(22):
			var snow_x = BOARD_ORIGIN.x - 20.0 + fmod(ui_time * (28.0 + snow_index * 1.7) + float(snow_index) * 54.0, board_size.x + 120.0)
			var snow_y = BOARD_ORIGIN.y - 8.0 + fmod(ui_time * (36.0 + snow_index * 1.2) + float(snow_index) * 32.0, board_size.y + 48.0)
			draw_circle(Vector2(snow_x, snow_y), 1.8 + float(snow_index % 3) * 0.4, Color(1.0, 1.0, 1.0, 0.3))
	elif _is_pool_level():
		_draw_rect_full(Color(0.74, 0.9, 1.0))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 156.0)), Color(0.88, 0.97, 1.0), true)
		draw_circle(Vector2(114.0, 70.0), 58.0, Color(1.0, 0.94, 0.58, 0.14))
		draw_circle(Vector2(114.0, 70.0), 36.0, Color(1.0, 0.94, 0.58))
		for cloud_index in range(5):
			var drift = fmod(ui_time * (9.0 + cloud_index * 1.7), 260.0)
			var cloud_pos = Vector2(240.0 + float(cloud_index) * 224.0 + drift, 48.0 + float(cloud_index % 3) * 20.0)
			draw_circle(cloud_pos, 20.0, Color(1.0, 1.0, 1.0, 0.56))
			draw_circle(cloud_pos + Vector2(18.0, 8.0), 17.0, Color(1.0, 1.0, 1.0, 0.64))
			draw_circle(cloud_pos + Vector2(-16.0, 8.0), 15.0, Color(1.0, 1.0, 1.0, 0.48))
		draw_rect(Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.6, 0.8, 0.5), true)
		draw_rect(Rect2(Vector2(0.0, 118.0), Vector2(size.x, 38.0)), Color(1.0, 1.0, 1.0, 0.04), true)
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 178.0), Vector2(170.0, 152.0), Vector2(348.0, 192.0),
				Vector2(592.0, 152.0), Vector2(806.0, 208.0), Vector2(1088.0, 164.0),
				Vector2(size.x, 202.0), Vector2(size.x, 236.0), Vector2(0.0, 236.0),
			]),
			PackedColorArray([
				Color(0.46, 0.68, 0.26), Color(0.46, 0.68, 0.26), Color(0.46, 0.68, 0.26),
				Color(0.46, 0.68, 0.26), Color(0.46, 0.68, 0.26), Color(0.46, 0.68, 0.26),
				Color(0.46, 0.68, 0.26), Color(0.46, 0.68, 0.26), Color(0.46, 0.68, 0.26),
			])
		)
		draw_rect(Rect2(Vector2(28.0, 118.0), Vector2(182.0, size.y - 118.0)), Color(0.9, 0.78, 0.6), true)
		draw_rect(Rect2(Vector2(44.0, 166.0), Vector2(140.0, 154.0)), Color(0.95, 0.9, 0.8), true)
		draw_rect(Rect2(Vector2(66.0, 124.0), Vector2(96.0, 60.0)), Color(0.8, 0.34, 0.24), true)
		for house_line in range(4):
			draw_line(Vector2(48.0, 196.0 + house_line * 34.0), Vector2(180.0, 196.0 + house_line * 34.0), Color(0.78, 0.68, 0.56), 2.0)
		draw_rect(Rect2(Vector2(210.0, 118.0), Vector2(34.0, size.y - 118.0)), Color(0.82, 0.74, 0.64), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 40.0, BOARD_ORIGIN.y), Vector2(30.0, board_size.y)), Color(0.72, 0.56, 0.36), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(84.0, board_size.y)), Color(0.46, 0.66, 0.48), true)
		var pool_rect = Rect2(Vector2(BOARD_ORIGIN.x - 14.0, BOARD_ORIGIN.y + CELL_SIZE.y * 2.0 - 12.0), Vector2(board_size.x + 28.0, CELL_SIZE.y * 2.0 + 24.0))
		draw_rect(pool_rect, Color(0.26, 0.66, 0.9, 0.16), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 18.0, BOARD_ORIGIN.y + CELL_SIZE.y * 2.0 - 4.0), Vector2(board_size.x + 36.0, CELL_SIZE.y * 2.0 + 8.0)), Color(0.9, 0.98, 1.0, 0.06), true)
		for reflection_index in range(6):
			var reflection_y = pool_rect.position.y + 18.0 + reflection_index * 26.0 + sin(ui_time * 2.1 + float(reflection_index)) * 4.0
			draw_line(Vector2(pool_rect.position.x + 12.0, reflection_y), Vector2(pool_rect.position.x + pool_rect.size.x - 12.0, reflection_y), Color(0.94, 1.0, 1.0, 0.12), 2.0)
		for deck_line in range(10):
			var deck_x = BOARD_ORIGIN.x - 44.0 + float(deck_line) * 30.0
			draw_line(Vector2(deck_x, BOARD_ORIGIN.y), Vector2(deck_x + 14.0, BOARD_ORIGIN.y + board_size.y), Color(0.54, 0.42, 0.24, 0.22), 2.0)
	elif _is_night_level():
		_draw_rect_full(Color(0.08, 0.11, 0.2))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 140.0)), Color(0.11, 0.16, 0.28), true)
		draw_rect(Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.22, 0.28, 0.22), true)
		draw_circle(Vector2(118.0, 78.0), 34.0, Color(0.92, 0.94, 1.0))
		draw_circle(Vector2(118.0, 78.0), 56.0, Color(0.92, 0.94, 1.0, 0.12))
		draw_circle(Vector2(132.0, 70.0), 34.0, Color(0.08, 0.11, 0.2))
		for star_index in range(14):
			var star_pos = Vector2(210.0 + float(star_index) * 68.0, 42.0 + float(star_index % 4) * 20.0 + sin(ui_time * 0.7 + float(star_index)) * 3.0)
			draw_circle(star_pos, 2.0, Color(1.0, 1.0, 0.88, 0.74 + 0.12 * sin(ui_time * 2.1 + float(star_index))))
		draw_rect(Rect2(Vector2(28.0, 118.0), Vector2(160.0, size.y - 118.0)), Color(0.46, 0.42, 0.42), true)
		draw_rect(Rect2(Vector2(46.0, 164.0), Vector2(124.0, 144.0)), Color(0.58, 0.56, 0.6), true)
		draw_rect(Rect2(Vector2(68.0, 122.0), Vector2(80.0, 56.0)), Color(0.3, 0.16, 0.16), true)
		draw_rect(Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.38, 0.36, 0.4), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.34, 0.28, 0.22), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.28, 0.34, 0.28), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 24.0, BOARD_ORIGIN.y + 36.0), Vector2(board_size.x + 96.0, 112.0)), Color(0.82, 0.86, 0.96, 0.05), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 40.0, BOARD_ORIGIN.y + 240.0), Vector2(board_size.x + 120.0, 96.0)), Color(0.82, 0.86, 0.96, 0.04), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 60.0, BOARD_ORIGIN.y + 420.0), Vector2(board_size.x + 150.0, 80.0)), Color(0.82, 0.86, 0.96, 0.03), true)
		draw_rect(Rect2(Vector2(0.0, 148.0), Vector2(size.x, 24.0)), Color(0.86, 0.92, 1.0, 0.03), true)
	else:
		_draw_rect_full(Color(0.79, 0.9, 1.0))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 140.0)), Color(0.9, 0.97, 1.0), true)
		draw_circle(Vector2(102.0, 74.0), 56.0, Color(1.0, 0.94, 0.56, 0.12))
		draw_circle(Vector2(102.0, 74.0), 34.0, Color(1.0, 0.94, 0.56))
		for cloud_index in range(4):
			var drift = fmod(ui_time * (8.0 + cloud_index * 2.0), 220.0)
			var cloud_pos = Vector2(280.0 + float(cloud_index) * 240.0 + drift, 52.0 + float(cloud_index % 2) * 24.0)
			draw_circle(cloud_pos, 20.0, Color(1.0, 1.0, 1.0, 0.58))
			draw_circle(cloud_pos + Vector2(20.0, 6.0), 18.0, Color(1.0, 1.0, 1.0, 0.62))
			draw_circle(cloud_pos + Vector2(-18.0, 8.0), 16.0, Color(1.0, 1.0, 1.0, 0.52))
		draw_rect(Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.66, 0.79, 0.49), true)
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 182.0), Vector2(160.0, 150.0), Vector2(336.0, 194.0),
				Vector2(596.0, 156.0), Vector2(860.0, 210.0), Vector2(1092.0, 168.0),
				Vector2(size.x, 198.0), Vector2(size.x, 232.0), Vector2(0.0, 232.0),
			]),
			PackedColorArray([
				Color(0.5, 0.7, 0.3), Color(0.5, 0.7, 0.3), Color(0.5, 0.7, 0.3),
				Color(0.5, 0.7, 0.3), Color(0.5, 0.7, 0.3), Color(0.5, 0.7, 0.3),
				Color(0.5, 0.7, 0.3), Color(0.5, 0.7, 0.3), Color(0.5, 0.7, 0.3),
			])
		)
		draw_rect(Rect2(Vector2(28.0, 118.0), Vector2(160.0, size.y - 118.0)), Color(0.86, 0.77, 0.58), true)
		draw_rect(Rect2(Vector2(46.0, 164.0), Vector2(124.0, 144.0)), Color(0.93, 0.88, 0.75), true)
		draw_rect(Rect2(Vector2(68.0, 122.0), Vector2(80.0, 56.0)), Color(0.78, 0.28, 0.2), true)
		for house_line in range(4):
			draw_line(Vector2(50.0, 194.0 + house_line * 32.0), Vector2(168.0, 194.0 + house_line * 32.0), Color(0.8, 0.72, 0.58), 2.0)
		draw_rect(Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.76, 0.67, 0.54), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.57, 0.43, 0.26), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.52, 0.65, 0.44), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 24.0, BOARD_ORIGIN.y + 28.0), Vector2(board_size.x + 96.0, 96.0)), Color(1.0, 1.0, 1.0, 0.05), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 30.0, BOARD_ORIGIN.y + 214.0), Vector2(board_size.x + 108.0, 84.0)), Color(1.0, 1.0, 1.0, 0.04), true)
		draw_rect(Rect2(Vector2(0.0, 148.0), Vector2(size.x, 24.0)), Color(1.0, 1.0, 1.0, 0.04), true)

	_draw_panel_shell(COIN_METER_RECT, Color(0.97, 0.89, 0.44), Color(0.48, 0.36, 0.09), 0.12, 0.06)
	_draw_coin_icon(COIN_METER_RECT.position + Vector2(22.0, 20.0), 1.0)
	_draw_text(str(coins_total), COIN_METER_RECT.position + Vector2(44.0, 27.0), 22, Color(0.31, 0.2, 0.05))

	_draw_panel_shell(BACK_BUTTON_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.1, 0.05)
	_draw_text("返回地图", BACK_BUTTON_RECT.position + Vector2(14.0, 27.0), 18, Color(0.27, 0.18, 0.08))


func _draw_battle_board() -> void:
	var freeze_visual_ratio = _freeze_transition_visual_ratio()
	for row in range(board_rows):
		var lane_rect = Rect2(
			Vector2(BOARD_ORIGIN.x, BOARD_ORIGIN.y + row * CELL_SIZE.y),
			Vector2(board_size.x, CELL_SIZE.y)
		)
		if not _is_row_active(row):
			draw_rect(lane_rect, Color(0.44, 0.53, 0.31), true)
			draw_rect(lane_rect, Color(0.12, 0.18, 0.08, 0.34), true)
			draw_rect(lane_rect, Color(0.16, 0.26, 0.12, 0.36), false, 2.0)
			continue

		var lane_color := Color(0.39, 0.75, 0.31) if row % 2 == 0 else Color(0.34, 0.68, 0.26)
		if _is_blood_moon_level():
			lane_color = Color(0.46, 0.08, 0.12) if row % 2 == 0 else Color(0.38, 0.05, 0.08)
		elif _is_frozen_branch_level():
			lane_color = Color(0.62, 0.78, 0.68) if row % 2 == 0 else Color(0.56, 0.72, 0.62)
		elif _is_night_level():
			lane_color = Color(0.23, 0.38, 0.2) if row % 2 == 0 else Color(0.19, 0.32, 0.17)
		elif _is_pool_level() and _is_water_row(row):
			lane_color = Color(0.16, 0.58, 0.84) if row % 2 == 0 else Color(0.12, 0.5, 0.78)
		draw_rect(lane_rect, lane_color, true)
		if _is_pool_level() and _is_water_row(row):
			draw_rect(Rect2(lane_rect.position, Vector2(lane_rect.size.x, lane_rect.size.y * 0.24)), Color(0.9, 0.98, 1.0, 0.12), true)
			for ripple_index in range(3):
				var ripple_y = lane_rect.position.y + 18.0 + ripple_index * 30.0 + sin(ui_time * 2.4 + float(ripple_index) + float(row)) * 4.0
				draw_line(Vector2(lane_rect.position.x + 10.0, ripple_y), Vector2(lane_rect.position.x + lane_rect.size.x - 10.0, ripple_y), Color(0.82, 0.96, 1.0, 0.1), 2.0)
			for caustic_index in range(6):
				var caustic_x = lane_rect.position.x - 80.0 + fmod(ui_time * (54.0 + float(caustic_index) * 7.0) + float(row) * 42.0 + float(caustic_index) * 120.0, lane_rect.size.x + 160.0)
				draw_line(
					Vector2(caustic_x, lane_rect.position.y + 12.0),
					Vector2(caustic_x + 64.0, lane_rect.position.y + lane_rect.size.y - 10.0),
					Color(0.94, 1.0, 1.0, 0.08),
					2.0
				)
			draw_line(lane_rect.position + Vector2(0.0, 10.0), lane_rect.position + Vector2(lane_rect.size.x, 10.0), Color(0.9, 1.0, 1.0, 0.18), 2.0)
			draw_line(lane_rect.position + Vector2(0.0, lane_rect.size.y - 10.0), lane_rect.position + Vector2(lane_rect.size.x, lane_rect.size.y - 10.0), Color(0.0, 0.22, 0.34, 0.16), 2.0)
		else:
			for stripe_index in range(5):
				var stripe_y = lane_rect.position.y + 16.0 + float(stripe_index) * 18.0
				draw_line(
					Vector2(lane_rect.position.x + 8.0, stripe_y),
					Vector2(lane_rect.position.x + lane_rect.size.x - 8.0, stripe_y),
					Color(1.0, 1.0, 1.0, 0.035 if stripe_index % 2 == 0 else 0.022),
					2.0
				)
		draw_rect(lane_rect, Color(1.0, 1.0, 1.0, 0.1), false, 2.0)

		for col in range(COLS):
			var tile = _cell_rect(row, col).grow(-2.0)
			var tint = Color(1.0, 1.0, 1.0, 0.03) if (row + col) % 2 == 0 else Color(0.0, 0.0, 0.0, 0.02)
			var border_color = Color(0.16, 0.35, 0.12, 0.22)
			if _is_blood_moon_level():
				tint = Color(1.0, 0.22, 0.28, 0.04) if (row + col) % 2 == 0 else Color(0.0, 0.0, 0.0, 0.06)
				border_color = Color(0.44, 0.08, 0.08, 0.24)
			elif _is_frozen_branch_level():
				var terrain = _cell_terrain_kind(row, col)
				if terrain == "water":
					tint = Color(0.72, 0.92, 1.0, 0.12) if (row + col) % 2 == 0 else Color(0.18, 0.52, 0.72, 0.08)
					border_color = Color(0.58, 0.88, 1.0, 0.24)
				elif terrain == "frozen":
					var water_tint = Color(0.72, 0.92, 1.0, 0.12) if (row + col) % 2 == 0 else Color(0.18, 0.52, 0.72, 0.08)
					var ice_tint = Color(0.9, 0.98, 1.0, 0.18) if (row + col) % 2 == 0 else Color(0.7, 0.9, 1.0, 0.12)
					tint = water_tint.lerp(ice_tint, freeze_visual_ratio)
					border_color = Color(0.58, 0.88, 1.0, 0.24).lerp(Color(0.74, 0.96, 1.0, 0.3), freeze_visual_ratio)
				else:
					tint = Color(0.94, 1.0, 1.0, 0.03) if (row + col) % 2 == 0 else Color(0.0, 0.0, 0.0, 0.03)
					border_color = Color(0.22, 0.42, 0.18, 0.2)
			elif _is_night_level():
				tint = Color(0.9, 0.94, 1.0, 0.03) if (row + col) % 2 == 0 else Color(0.0, 0.0, 0.0, 0.04)
			elif _is_pool_level() and _is_water_row(row):
				tint = Color(0.88, 0.98, 1.0, 0.05) if (row + col) % 2 == 0 else Color(0.0, 0.2, 0.32, 0.05)
				border_color = Color(0.68, 0.94, 1.0, 0.16)
			draw_rect(tile, tint, true)
			if _is_frozen_branch_level():
				var tile_terrain = _cell_terrain_kind(row, col)
				if tile_terrain == "water":
					var mid_y = tile.position.y + tile.size.y * 0.5
					draw_line(Vector2(tile.position.x + 8.0, mid_y - 12.0), Vector2(tile.position.x + tile.size.x - 8.0, mid_y - 12.0), Color(1.0, 1.0, 1.0, 0.12), 2.0)
					draw_line(Vector2(tile.position.x + 14.0, mid_y + 12.0), Vector2(tile.position.x + tile.size.x - 14.0, mid_y + 12.0), Color(0.78, 0.96, 1.0, 0.12), 2.0)
				elif tile_terrain == "frozen":
					var mid_y = tile.position.y + tile.size.y * 0.5
					var water_alpha = (1.0 - freeze_visual_ratio) * 0.12
					if water_alpha > 0.0:
						draw_line(Vector2(tile.position.x + 8.0, mid_y - 12.0), Vector2(tile.position.x + tile.size.x - 8.0, mid_y - 12.0), Color(1.0, 1.0, 1.0, water_alpha), 2.0)
						draw_line(Vector2(tile.position.x + 14.0, mid_y + 12.0), Vector2(tile.position.x + tile.size.x - 14.0, mid_y + 12.0), Color(0.78, 0.96, 1.0, water_alpha), 2.0)
					var crack_alpha = freeze_visual_ratio * 0.18
					draw_line(tile.position + Vector2(12.0, 14.0), tile.position + tile.size - Vector2(18.0, 16.0), Color(1.0, 1.0, 1.0, crack_alpha), 2.0)
					draw_line(tile.position + Vector2(tile.size.x * 0.55, 12.0), tile.position + Vector2(tile.size.x * 0.32, tile.size.y - 12.0), Color(0.72, 0.92, 1.0, freeze_visual_ratio * 0.16), 2.0)
			draw_rect(tile, border_color, false, 1.0)

	var outline = Color(0.38, 0.04, 0.06, 0.8) if _is_blood_moon_level() else (Color(0.52, 0.84, 1.0, 0.8) if _is_frozen_branch_level() else (Color(0.06, 0.26, 0.36, 0.72) if _is_pool_level() else Color(0.12, 0.28, 0.08, 0.68)))
	draw_rect(Rect2(BOARD_ORIGIN, board_size), outline, false, 4.0)


func _draw_seed_bank() -> void:
	_draw_panel_shell(SEED_BANK_RECT, Color(0.93, 0.88, 0.72), Color(0.43, 0.33, 0.18), 0.16, 0.08)
	draw_rect(Rect2(SEED_BANK_RECT.position + Vector2(12.0, 10.0), Vector2(SEED_BANK_RECT.size.x - 24.0, 16.0)), Color(1.0, 1.0, 1.0, 0.08), true)
	if _is_conveyor_level():
		for belt_index in range(12):
			var belt_x = SEED_BANK_RECT.position.x - 40.0 + fmod(ui_time * 120.0 + float(belt_index) * 82.0, SEED_BANK_RECT.size.x + 90.0)
			draw_line(Vector2(belt_x, SEED_BANK_RECT.position.y + 18.0), Vector2(belt_x + 34.0, SEED_BANK_RECT.position.y + SEED_BANK_RECT.size.y - 18.0), Color(0.18, 0.34, 0.12, 0.16), 3.0)
	else:
		_draw_text(String(current_level["id"]), SEED_BANK_RECT.position + Vector2(SEED_BANK_RECT.size.x - 86.0, 18.0), 16, Color(0.34, 0.22, 0.08))
		_draw_text("防线状态", SEED_BANK_RECT.position + Vector2(SEED_BANK_RECT.size.x - 152.0, 40.0), 12, Color(0.4, 0.3, 0.14))

	_draw_panel_shell(SUN_METER_RECT, Color(1.0, 0.92, 0.54), Color(0.55, 0.41, 0.08), 0.08, 0.05)
	var sun_pulse = 0.72 + 0.28 * sin(ui_time * 4.2)
	draw_circle(SUN_METER_RECT.get_center(), 18.0 + sun_pulse * 3.0, Color(1.0, 0.9, 0.34, 0.08), false, 2.0)
	if _is_whack_level():
		_draw_text("木槌", Vector2(44.0, 48.0), 18, Color(0.33, 0.21, 0.04))
		_draw_text(str(sun_points), Vector2(54.0, 86.0), 28, Color(0.33, 0.21, 0.04))
	elif _is_conveyor_level():
		_draw_text("传送带", Vector2(38.0, 48.0), 18, Color(0.33, 0.21, 0.04))
		_draw_text("自动供卡", Vector2(34.0, 84.0), 22, Color(0.33, 0.21, 0.04))
	else:
		_draw_text("阳光", Vector2(46.0, 48.0), 18, Color(0.33, 0.21, 0.04))
		_draw_text(str(sun_points), Vector2(54.0, 86.0), 28, Color(0.33, 0.21, 0.04))

	var mouse_pos = get_local_mouse_position()
	for index in range(active_cards.size()):
		var kind = String(active_cards[index])
		var rect = _card_rect(index)
		var hovered = rect.has_point(mouse_pos)
		var draw_rect_local = rect.grow(2.0 if hovered else 0.0)
		draw_rect_local.position.y -= 4.0 if hovered else 0.0
		if kind == "":
			_draw_panel_shell(draw_rect_local, Color(0.88, 0.84, 0.76), Color(0.38, 0.28, 0.16), 0.06, 0.04)
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
		if hovered and kind != "":
			draw_rect(draw_rect_local.grow(5.0), Color(1.0, 0.98, 0.72, 0.12), true)

		_draw_panel_shell(draw_rect_local, card_color, Color(0.38, 0.28, 0.16), 0.08, 0.05)
		if selected:
			var card_pulse = 0.76 + 0.24 * sin(ui_time * 6.8 + float(index))
			draw_rect(draw_rect_local.grow(6.0), Color(1.0, 0.92, 0.22, 0.08 * card_pulse), true)
			draw_rect(draw_rect_local.grow(2.0), Color(1.0, 0.9, 0.18), false, 4.0)

		_draw_card_icon(kind, draw_rect_local.position + Vector2(draw_rect_local.size.x * 0.5, 46.0))
		var name_font_size = 10 if draw_rect_local.size.x < 76.0 else 12
		var cost_x = 6.0 if draw_rect_local.size.x < 76.0 else 8.0
		if not _is_conveyor_level():
			_draw_text(str(data["cost"]), draw_rect_local.position + Vector2(cost_x, 84.0), 16, Color(0.29, 0.17, 0.05))
		_draw_text(String(data["name"]), draw_rect_local.position + Vector2(4.0, 17.0), name_font_size, Color(0.29, 0.17, 0.05))

		if not _is_conveyor_level() and not affordable and float(card_cooldowns[kind]) <= 0.01:
			draw_rect(draw_rect_local, Color(0.0, 0.0, 0.0, 0.24), true)

		if not _is_conveyor_level() and float(card_cooldowns[kind]) > 0.01:
			var cover_height = draw_rect_local.size.y * clampf(cooling_ratio, 0.0, 1.0)
			draw_rect(Rect2(draw_rect_local.position, Vector2(draw_rect_local.size.x, cover_height)), Color(0.12, 0.12, 0.12, 0.46), true)
			draw_rect(Rect2(draw_rect_local.position + Vector2(0.0, cover_height - 3.0), Vector2(draw_rect_local.size.x, 3.0)), Color(1.0, 1.0, 1.0, 0.14), true)
			var recharge_rect = Rect2(draw_rect_local.position + Vector2(4.0, draw_rect_local.size.y - 7.0), Vector2(draw_rect_local.size.x - 8.0, 3.0))
			draw_rect(recharge_rect, Color(0.0, 0.0, 0.0, 0.26), true)
			draw_rect(ThemeLib.progress_fill_rect(recharge_rect, 1.0 - cooling_ratio), Color(0.86, 0.96, 0.62, 0.82), true)

	if _is_whack_level():
		var hammer_rect = Rect2(948.0, 24.0, 120.0, 80.0)
		_draw_panel_shell(hammer_rect, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.08, 0.05)
		_draw_mallet_icon(hammer_rect.position + Vector2(34.0, 38.0))
		_draw_text("默认挥锤", hammer_rect.position + Vector2(52.0, 28.0), 16, Color(0.26, 0.19, 0.08))
		_draw_text("点卡再种植", hammer_rect.position + Vector2(50.0, 52.0), 14, Color(0.26, 0.19, 0.08))
		return

	var shovel_rect = _shovel_rect()
	_draw_panel_shell(shovel_rect, Color(0.91, 0.88, 0.79), Color(0.38, 0.28, 0.16), 0.08, 0.04)
	if selected_tool == "shovel":
		draw_rect(shovel_rect.grow(2.0), Color(1.0, 0.9, 0.18), false, 4.0)
	_draw_shovel_icon(shovel_rect.position + shovel_rect.size * 0.5)
	_draw_text("铲子", shovel_rect.position + Vector2(20.0, 82.0), 18, Color(0.26, 0.19, 0.08))

	_draw_panel_shell(PLANT_FOOD_RECT, Color(0.84, 0.96, 0.76), Color(0.2, 0.54, 0.14), 0.08, 0.05)
	if selected_tool == "plant_food":
		draw_rect(PLANT_FOOD_RECT.grow(2.0), Color(1.0, 0.9, 0.18), false, 4.0)
	if plant_food_count <= 0:
		draw_rect(PLANT_FOOD_RECT, Color(0.0, 0.0, 0.0, 0.18), true)
	_draw_plant_food_icon(PLANT_FOOD_RECT.position + Vector2(20.0, 23.0), 0.8)
	_draw_text("能量豆", PLANT_FOOD_RECT.position + Vector2(34.0, 18.0), 12, Color(0.12, 0.33, 0.08))
	_draw_text("x%d" % plant_food_count, PLANT_FOOD_RECT.position + Vector2(36.0, 37.0), 18, Color(0.12, 0.33, 0.08))


func _battle_progress_ratio_raw() -> float:
	return clampf(float(total_kills + _enemy_zombie_count() * 0.42 + total_spawned_units * 0.18) / float(max(expected_spawn_units, 1)), 0.0, 1.0)


func _battle_progress_ratio() -> float:
	var progress_ratio = _battle_progress_ratio_raw()
	if _is_frozen_branch_level() and frozen_branch_progress_locked and not frozen_branch_midboss_cleared:
		return minf(progress_ratio, 0.5)
	return progress_ratio


func _find_alive_enemy_boss(kind: String) -> Dictionary:
	for zombie in zombies:
		if String(zombie.get("kind", "")) != kind:
			continue
		if not _is_enemy_zombie(zombie):
			continue
		if float(zombie.get("health", 0.0)) <= 0.0:
			continue
		return zombie
	return {}


func _spawn_frozen_branch_midboss() -> void:
	var midboss_kind = String(current_level.get("mid_boss_kind", "daiyousei_boss"))
	if midboss_kind == "":
		return
	var spawn_row = int(active_rows[max(0, int(floor(float(active_rows.size()) * 0.5)))])
	_spawn_zombie_at(midboss_kind, spawn_row, BOARD_ORIGIN.x + board_size.x - 24.0, true)
	frozen_branch_midboss_spawned = true
	frozen_branch_progress_locked = true
	frozen_branch_locked_progress = 0.5
	_show_banner("大妖精挡住了前进路线！", 2.0)
	effects.append({
		"position": Vector2(BOARD_ORIGIN.x + board_size.x - 24.0, _row_center_y(spawn_row) - 12.0),
		"radius": 96.0,
		"time": 0.4,
		"duration": 0.4,
		"color": Color(0.58, 0.94, 1.0, 0.28),
	})


func _trigger_cirno_freeze_transition() -> void:
	if not _is_frozen_branch_level():
		return
	frozen_branch_freeze_visual_t = 0.0
	frozen_branch_freeze_visual_active = true
	for row in active_rows:
		var row_i = int(row)
		for col in range(5):
			_set_cell_terrain_kind(row_i, col, "frozen")
			var support_variant = support_grid[row_i][col]
			if support_variant != null and String(support_variant.get("kind", "")) == "lily_pad":
				support_grid[row_i][col] = null
			effects.append({
				"position": _cell_center(row_i, col),
				"radius": 48.0,
				"time": 0.28,
				"duration": 0.28,
				"color": Color(0.78, 0.94, 1.0, 0.24),
			})
	if not frozen_branch_post_freeze_cards.is_empty():
		conveyor_source_cards = frozen_branch_post_freeze_cards.duplicate()
		for i in range(active_cards.size()):
			var active_kind = String(active_cards[i])
			if active_kind != "lily_pad" and active_kind != "tangle_kelp":
				continue
			active_cards[i] = _pick_conveyor_card_for_slot(i)
	_show_banner("琪露诺冻结了左侧寒湖！", 2.2)


func _update_freeze_transition_visual(delta: float) -> void:
	if not frozen_branch_freeze_visual_active:
		return
	frozen_branch_freeze_visual_t = minf(frozen_branch_freeze_visual_duration, frozen_branch_freeze_visual_t + delta)
	if frozen_branch_freeze_visual_t >= frozen_branch_freeze_visual_duration:
		frozen_branch_freeze_visual_active = false


func _freeze_transition_visual_ratio() -> float:
	if not _is_frozen_branch_level():
		return 1.0
	var duration = maxf(frozen_branch_freeze_visual_duration, 0.001)
	var t = clampf(frozen_branch_freeze_visual_t / duration, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _update_frozen_branch_flow() -> void:
	if not _is_frozen_branch_level():
		return
	if not frozen_branch_midboss_spawned and _battle_progress_ratio_raw() >= 0.5:
		_spawn_frozen_branch_midboss()
		return
	if frozen_branch_midboss_spawned and not frozen_branch_midboss_cleared and _find_alive_enemy_boss("daiyousei_boss").is_empty():
		frozen_branch_midboss_cleared = true
		frozen_branch_progress_locked = false
		frozen_branch_locked_progress = -1.0
		_show_banner("大妖精被击退，冰雾还在加深！", 2.0)


func _draw_wave_bar() -> void:
	_draw_panel_shell(WAVE_BAR_RECT, Color(0.24, 0.18, 0.16), Color(0.18, 0.1, 0.08), 0.1, 0.04)

	var total_events = max(current_level["events"].size(), 1)
	var progress_ratio = _battle_progress_ratio()
	var inner_rect = WAVE_BAR_RECT.grow(-6.0)
	draw_rect(inner_rect, Color(0.08, 0.04, 0.04, 0.54), true)
	for segment_index in range(10):
		var segment_x = inner_rect.position.x + inner_rect.size.x * (float(segment_index) / 10.0)
		draw_line(Vector2(segment_x, inner_rect.position.y), Vector2(segment_x, inner_rect.position.y + inner_rect.size.y), Color(1.0, 1.0, 1.0, 0.05), 1.0)
	var fill_rect = ThemeLib.progress_fill_rect(inner_rect, progress_ratio)
	draw_rect(fill_rect, Color(0.86, 0.18, 0.18), true)
	draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, fill_rect.size.y * 0.44)), Color(1.0, 0.42, 0.3, 0.32), true)
	draw_rect(Rect2(fill_rect.position + Vector2(0.0, fill_rect.size.y * 0.66), Vector2(fill_rect.size.x, fill_rect.size.y * 0.34)), Color(0.52, 0.04, 0.06, 0.18), true)
	var shine_x = inner_rect.position.x + fmod(level_time * 180.0, inner_rect.size.x + 60.0) - 40.0
	draw_rect(Rect2(Vector2(shine_x, inner_rect.position.y), Vector2(24.0, inner_rect.size.y)), Color(1.0, 1.0, 1.0, 0.12), true)

	for marker in _wave_marker_indices():
		var i = int(marker)
		var flag_ratio = float(i + 1) / float(total_events)
		var x = inner_rect.position.x + inner_rect.size.x * flag_ratio
		draw_line(Vector2(x, WAVE_BAR_RECT.position.y - 4.0), Vector2(x, WAVE_BAR_RECT.position.y + WAVE_BAR_RECT.size.y + 4.0), Color(0.22, 0.12, 0.12), 2.0)
		var flag_pulse = 1.0 + 0.12 * sin(level_time * 5.0 + float(i))
		draw_polygon(
			PackedVector2Array([
				Vector2(x, WAVE_BAR_RECT.position.y - 2.0),
				Vector2(x + 12.0 * flag_pulse, WAVE_BAR_RECT.position.y + 4.0),
				Vector2(x, WAVE_BAR_RECT.position.y + 10.0 * flag_pulse),
			]),
			PackedColorArray([Color(0.95, 0.18, 0.18), Color(0.95, 0.18, 0.18), Color(0.95, 0.18, 0.18)])
		)

	var wave_status = "最终推进" if progress_ratio >= 0.96 else ("尸潮逼近" if progress_ratio >= 0.72 else "防线稳定")
	_draw_text(wave_status, WAVE_BAR_RECT.position + Vector2(10.0, 16.0), 14, Color(0.96, 0.9, 0.8))
	_draw_text("%d%%" % int(round(progress_ratio * 100.0)), WAVE_BAR_RECT.position + Vector2(WAVE_BAR_RECT.size.x - 40.0, 16.0), 14, Color(0.96, 0.9, 0.8))
	_draw_text(String(current_level["id"]), WAVE_BAR_RECT.position + Vector2(-54.0, 20.0), 18, Color(0.18, 0.18, 0.18))


func _current_active_boss() -> Dictionary:
	for zombie in zombies:
		if _is_boss_zombie(zombie) and _is_enemy_zombie(zombie) and float(zombie.get("health", 0.0)) > 0.0:
			return zombie
	return {}


func _boss_health_bar_layout(_boss: Dictionary) -> Dictionary:
	var bar_width = clampf(board_size.x + 42.0, 780.0, 920.0)
	var bar_height = 26.0
	var scene_width = size.x if size.x > 0.0 else BOARD_ORIGIN.x * 2.0 + board_size.x + 120.0
	var board_bottom = BOARD_ORIGIN.y + board_size.y
	var rect_x = maxf(28.0, (scene_width - bar_width) * 0.5)
	var baseline_y = board_bottom + 20.0
	var bottom_locked_y = (size.y if size.y > 0.0 else board_bottom + 84.0) - bar_height - 10.0
	var rect = Rect2(rect_x, maxf(baseline_y, bottom_locked_y), bar_width, bar_height)
	return {
		"rect": rect,
		"rect_y": rect.position.y,
		"segments": 5,
	}


func _draw_boss_health_bar() -> void:
	var boss = _current_active_boss()
	if boss.is_empty():
		return
	var layout = _boss_health_bar_layout(boss)
	var rect = Rect2(layout.get("rect", Rect2(214.0, size.y - 50.0, 868.0, 24.0)))
	var segments = int(layout.get("segments", 5))
	var health = maxf(0.0, float(boss.get("health", 0.0)))
	var max_health = maxf(1.0, float(boss.get("max_health", 1.0)))
	var segment_gap = 6.0
	var segment_width = (rect.size.x - segment_gap * float(segments - 1)) / float(max(segments, 1))
	var label_rect = Rect2(rect.position.x - 126.0, rect.position.y - 2.0, 114.0, 28.0)
	_draw_panel_shell(label_rect, Color(0.2, 0.04, 0.06, 0.94), Color(0.58, 0.14, 0.16), 0.08, 0.04)
	_draw_text(String(Defs.ZOMBIES[String(boss["kind"])]["name"]), label_rect.position + Vector2(18.0, 20.0), 18, Color(1.0, 0.92, 0.94))
	draw_rect(rect.grow(6.0), Color(0.18, 0.0, 0.02, 0.3), true)
	_draw_panel_shell(rect, Color(0.12, 0.02, 0.04, 0.96), Color(0.48, 0.1, 0.12), 0.08, 0.04)
	for segment_index in range(segments):
		var x = rect.position.x + float(segment_index) * (segment_width + segment_gap)
		var segment_rect = Rect2(x, rect.position.y + 4.0, segment_width, rect.size.y - 8.0)
		draw_rect(segment_rect, Color(0.22, 0.04, 0.05), true)
		var segment_start = max_health * float(segment_index) / float(segments)
		var segment_end = max_health * float(segment_index + 1) / float(segments)
		var segment_ratio = clampf((health - segment_start) / maxf(segment_end - segment_start, 1.0), 0.0, 1.0)
		if segment_ratio > 0.0:
			var fill_rect = Rect2(segment_rect.position, Vector2(segment_rect.size.x * segment_ratio, segment_rect.size.y))
			draw_rect(fill_rect, Color(0.88, 0.1, 0.16), true)
			draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, fill_rect.size.y * 0.42)), Color(1.0, 0.38, 0.44, 0.28), true)
		draw_rect(segment_rect, Color(0.56, 0.16, 0.16), false, 2.0)


func _draw_hover() -> void:
	if battle_state != BATTLE_PLAYING:
		return
	if _is_whack_level() and selected_tool == "":
		var target_index = _find_whack_target(get_local_mouse_position())
		if target_index != -1:
			var zombie = zombies[target_index]
			var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + float(zombie.get("jump_offset", 0.0)))
			draw_circle(center, 34.0, Color(1.0, 0.92, 0.38, 0.14))
			draw_circle(center, 30.0, Color(1.0, 0.9, 0.18, 0.7), false, 2.0)
		return
	var cell = _mouse_to_cell(get_local_mouse_position())
	if cell.x == -1:
		return

	var rect = _cell_rect(cell.x, cell.y).grow(-5.0)
	var highlight = Color(1.0, 0.96, 0.55, 0.22)
	if selected_tool == "shovel":
		highlight = Color(0.95, 0.3, 0.3, 0.2)
	elif selected_tool == "plant_food":
		highlight = Color(0.24, 0.96, 0.36, 0.2) if _targetable_plant_at(cell.x, cell.y) != null else Color(0.95, 0.3, 0.3, 0.2)
	elif selected_tool == "":
		highlight = Color(1.0, 1.0, 1.0, 0.08)
	elif _placement_error(selected_tool, cell.x, cell.y) != "":
		highlight = Color(0.95, 0.3, 0.3, 0.2)
	elif not _is_conveyor_level() and sun_points < int(Defs.PLANTS[selected_tool]["cost"]):
		highlight = Color(0.88, 0.55, 0.12, 0.24)

	draw_rect(rect, highlight, true)
	draw_rect(rect, Color(1.0, 1.0, 1.0, 0.08), false, 2.0)

	if selected_tool != "" and selected_tool != "shovel" and selected_tool != "plant_food" and _placement_error(selected_tool, cell.x, cell.y) == "":
		_draw_plant_preview(selected_tool, _cell_center(cell.x, cell.y))


func _draw_plants() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var support_variant = support_grid[row][col]
			if support_variant == null:
				continue
			var support = support_variant
			var support_center = _cell_center(row, col) + Vector2(0.0, 16.0)
			var support_motion = _plant_draw_motion(support, support_center)
			var support_draw_center = Vector2(support_motion["center"])
			draw_set_transform(support_draw_center, float(support_motion["rotation"]), Vector2(support_motion["scale"]))
			match String(support["kind"]):
				"lily_pad":
					_draw_lily_pad(Vector2.ZERO, 1.0, float(support.get("flash", 0.0)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if grid[row][col] == null:
				_draw_health_bar(
					support_draw_center + Vector2(0.0, -26.0),
					48.0,
					clampf(float(support["health"]) / float(support["max_health"]), 0.0, 1.0),
					Color(0.24, 0.82, 0.28)
				)

	for row in range(ROWS):
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue

			var plant = plant_variant
			var center = _cell_center(row, col)
			var flash = float(plant["flash"])
			var motion = _plant_draw_motion(plant, center)
			var draw_center = Vector2(motion["center"])
			if _plant_has_food_power(plant):
				draw_circle(draw_center + Vector2(0.0, -8.0), 34.0, Color(0.2, 0.98, 0.34, 0.14))
				_draw_plant_food_icon(draw_center + Vector2(0.0, -52.0), 0.38)

			draw_set_transform(draw_center, float(motion["rotation"]), Vector2(motion["scale"]))
			match String(plant["kind"]):
				"sunflower":
					_draw_sunflower(Vector2.ZERO, 1.0, flash)
				"peashooter":
					_draw_peashooter(Vector2.ZERO, 1.0, flash)
				"puff_shroom":
					_draw_puff_shroom(Vector2.ZERO, 1.0, flash)
				"snow_pea":
					_draw_snow_pea(Vector2.ZERO, 1.0, flash)
				"wallnut":
					_draw_wallnut(Vector2.ZERO, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
				"cherry_bomb":
					_draw_cherry_bomb(Vector2.ZERO, 1.0, clampf(float(plant["fuse_timer"]) / float(Defs.PLANTS["cherry_bomb"]["fuse"]), 0.0, 1.0))
				"potato_mine":
					_draw_potato_mine(Vector2.ZERO, 1.0, bool(plant["armed"]), clampf(1.0 - float(plant["arm_timer"]) / float(Defs.PLANTS["potato_mine"]["arm_time"]), 0.0, 1.0))
				"chomper":
					_draw_chomper(Vector2.ZERO, 1.0, clampf(float(plant["chew_timer"]) / float(Defs.PLANTS["chomper"]["chew_time"]), 0.0, 1.0))
				"repeater":
					_draw_repeater(Vector2.ZERO, 1.0, flash)
				"threepeater":
					_draw_threepeater(Vector2.ZERO, 1.0, flash)
				"boomerang_shooter":
					_draw_boomerang_shooter(Vector2.ZERO, 1.0, flash)
				"sakura_shooter":
					_draw_sakura_shooter(Vector2.ZERO, 1.0, flash)
				"lotus_lancer":
					_draw_lotus_lancer(Vector2.ZERO, 1.0, flash)
				"mirror_reed":
					_draw_mirror_reed(Vector2.ZERO, 1.0, flash)
				"frost_fan":
					_draw_frost_fan(Vector2.ZERO, 1.0, flash)
				"amber_shooter":
					_draw_amber_shooter(Vector2.ZERO, 1.0, flash)
				"vine_lasher":
					_draw_vine_lasher(Vector2.ZERO, 1.0, flash)
				"pepper_mortar":
					_draw_pepper_mortar(Vector2.ZERO, 1.0, flash)
				"cactus_guard":
					_draw_cactus_guard(Vector2.ZERO, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
				"pulse_bulb":
					_draw_pulse_bulb(Vector2.ZERO, 1.0, flash)
				"sun_bean":
					_draw_sun_bean(Vector2.ZERO, 1.0, flash)
				"sun_shroom":
					_draw_sun_shroom(Vector2.ZERO, 1.0, flash, bool(plant["mature"]))
				"fume_shroom":
					_draw_fume_shroom(Vector2.ZERO, 1.0, flash)
				"grave_buster":
					_draw_grave_buster(Vector2.ZERO, 1.0, flash)
				"hypno_shroom":
					_draw_hypno_shroom(Vector2.ZERO, 1.0, flash)
				"scaredy_shroom":
					_draw_scaredy_shroom(Vector2.ZERO, 1.0, flash, _has_close_zombie(center, float(Defs.PLANTS["scaredy_shroom"]["fear_radius"])))
				"ice_shroom":
					_draw_ice_shroom(Vector2.ZERO, 1.0, flash)
				"doom_shroom":
					_draw_doom_shroom(Vector2.ZERO, 1.0, flash)
				"moon_lotus":
					_draw_moon_lotus(Vector2.ZERO, 1.0, flash)
				"prism_grass":
					_draw_prism_grass(Vector2.ZERO, 1.0, flash)
				"lantern_bloom":
					_draw_lantern_bloom(Vector2.ZERO, 1.0, flash)
				"meteor_gourd":
					_draw_meteor_gourd(Vector2.ZERO, 1.0, flash)
				"root_snare":
					_draw_root_snare(Vector2.ZERO, 1.0, flash)
				"thunder_pine":
					_draw_thunder_pine(Vector2.ZERO, 1.0, flash)
				"dream_drum":
					_draw_dream_drum(Vector2.ZERO, 1.0, flash)
				"wind_orchid":
					_draw_wind_orchid(Vector2.ZERO, 1.0, flash)
				"squash":
					_draw_squash(Vector2.ZERO, 1.0, flash)
				"tangle_kelp":
					_draw_tangle_kelp(Vector2.ZERO, 1.0, flash)
				"jalapeno":
					_draw_jalapeno(Vector2.ZERO, 1.0, flash)
				"spikeweed":
					_draw_spikeweed(Vector2.ZERO, 1.0, flash)
				"torchwood":
					_draw_torchwood(Vector2.ZERO, 1.0, flash)
				"tallnut":
					_draw_tallnut(Vector2.ZERO, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			if String(plant["kind"]) != "cherry_bomb" and String(plant["kind"]) != "jalapeno":
				if float(plant["armor_health"]) > 0.0 and float(plant["max_armor_health"]) > 0.0:
					_draw_health_bar(
						draw_center + Vector2(0.0, -52.0),
						58.0,
						clampf(float(plant["armor_health"]) / float(plant["max_armor_health"]), 0.0, 1.0),
						Color(0.16, 0.96, 0.3)
					)
				_draw_health_bar(
					draw_center + Vector2(0.0, -42.0),
					58.0,
					clampf(float(plant["health"]) / float(plant["max_health"]), 0.0, 1.0),
					Color(0.32, 0.86, 0.24)
				)
			if float(plant.get("sleep_timer", 0.0)) > 0.0:
				_draw_text("Z", draw_center + Vector2(-10.0, -62.0), 18, Color(0.86, 0.9, 1.0, 0.9))
				_draw_text("Z", draw_center + Vector2(6.0, -76.0), 14, Color(0.86, 0.9, 1.0, 0.7))


func _draw_projectiles() -> void:
	for projectile in projectiles:
		var projectile_pos = Vector2(projectile["position"])
		var projectile_color = Color(projectile["color"])
		var projectile_kind = String(projectile.get("kind", "pea"))
		var pulse = 1.0 + 0.12 * sin(level_time * 14.0 + projectile_pos.x * 0.04)
		var projectile_radius = float(projectile.get("radius", 8.0)) * pulse
		var trail_dir = 1.0 if float(projectile.get("speed", 0.0)) >= 0.0 else -1.0
		if projectile_kind == "boomerang":
			for trail_index in range(3):
				var trail_ratio = float(trail_index + 1) / 3.0
				var trail_center = projectile_pos + Vector2(-trail_dir * trail_ratio * 12.0, 0.0)
				draw_arc(trail_center, projectile_radius * (0.92 - trail_ratio * 0.12), -1.2, 1.2, 14, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.22 - trail_ratio * 0.04), 2.0)
			draw_arc(projectile_pos, projectile_radius, -1.35, 1.35, 18, projectile_color, 3.0)
			draw_circle(projectile_pos + Vector2(2.0 * trail_dir, -1.0), projectile_radius * 0.22, Color(1.0, 0.96, 0.8, 0.58))
			continue
		if projectile_kind == "sakura_petal":
			for trail_index in range(3):
				var trail_ratio = float(trail_index + 1) / 3.0
				draw_circle(projectile_pos + Vector2(-trail_dir * trail_ratio * 9.0, -float(projectile.get("velocity_y", 0.0)) * 0.014 * trail_ratio), projectile_radius * (0.72 - trail_ratio * 0.12), Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.18 - trail_ratio * 0.03))
			draw_polygon(
				PackedVector2Array([
					projectile_pos + Vector2(0.0, -projectile_radius),
					projectile_pos + Vector2(projectile_radius * 0.9, 0.0),
					projectile_pos + Vector2(0.0, projectile_radius),
					projectile_pos + Vector2(-projectile_radius * 0.9, 0.0),
				]),
				PackedColorArray([
					Color(1.0, 0.88, 0.94, 0.88),
					projectile_color,
					Color(0.98, 0.72, 0.84, 0.92),
					projectile_color,
				])
			)
			draw_circle(projectile_pos + Vector2(-1.0, -1.0), projectile_radius * 0.24, Color(1.0, 1.0, 1.0, 0.46))
			continue
		for trail_index in range(3):
			var trail_ratio = float(trail_index + 1) / 3.0
			draw_circle(projectile_pos + Vector2(-trail_dir * trail_ratio * 10.0, 0.0), projectile_radius * (0.76 - trail_ratio * 0.14), Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.2 - trail_ratio * 0.04))
		draw_circle(projectile_pos, projectile_radius, projectile_color)
		draw_circle(projectile_pos + Vector2(-2.0, -2.0), projectile_radius * 0.38, Color(1.0, 1.0, 1.0, 0.5))


func _draw_zombies() -> void:
	for zombie in zombies:
		var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + float(zombie["jump_offset"]))
		var motion = _zombie_draw_motion(zombie, center)
		var draw_center = Vector2(motion["center"])
		draw_set_transform(draw_center, float(motion["rotation"]), Vector2(motion["scale"]))
		_draw_zombie(Vector2.ZERO, zombie)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if _is_whack_level():
			var hit_count = max(0, int(zombie.get("whack_hits_left", 0)))
			for pip_index in range(hit_count):
				draw_circle(draw_center + Vector2(-8.0 + pip_index * 12.0, -58.0), 4.0, Color(1.0, 0.88, 0.28))
			continue
		if float(zombie.get("shield_health", 0.0)) > 0.0 and float(zombie.get("max_shield_health", 0.0)) > 0.0:
			_draw_health_bar(
				draw_center + Vector2(0.0, -64.0),
				58.0,
				clampf(float(zombie["shield_health"]) / float(zombie["max_shield_health"]), 0.0, 1.0),
				Color(0.62, 0.8, 0.96)
			)
		_draw_health_bar(
			draw_center + Vector2(0.0, -56.0),
			58.0,
			clampf(float(zombie["health"]) / float(zombie["max_health"]), 0.0, 1.0),
			Color(0.92, 0.28, 0.22)
		)


func _draw_suns() -> void:
	for sun in suns:
		var center = Vector2(sun["position"])
		var angle_offset = level_time * 2.6
		var bob_center = center + Vector2(0.0, sin(level_time * 3.2 + center.x * 0.02) * 2.0)
		for index in range(8):
			var angle = TAU * float(index) / 8.0 + angle_offset
			var ray_from = bob_center + Vector2(cos(angle), sin(angle)) * 16.0
			var ray_to = bob_center + Vector2(cos(angle), sin(angle)) * 24.0
			draw_line(ray_from, ray_to, Color(1.0, 0.84, 0.22), 2.0)
		draw_circle(bob_center, 16.0, Color(1.0, 0.94, 0.42))
		draw_circle(bob_center, 8.0, Color(1.0, 0.82, 0.14))


func _draw_coins() -> void:
	for coin in coins:
		var center = Vector2(coin["position"]) + Vector2(0.0, sin(level_time * 5.2 + float(coin["position"].x) * 0.03) * 1.5)
		_draw_coin_icon(center, 0.8 + 0.03 * sin(level_time * 7.0 + center.x * 0.02))


func _draw_lane_obstacles() -> void:
	for tile in ice_tiles:
		var row = int(tile["row"])
		var col = int(tile["col"])
		var ice_rect = _cell_rect(row, col).grow(-7.0)
		draw_rect(ice_rect, Color(0.8, 0.94, 1.0, 0.24), true)
		draw_rect(ice_rect, Color(0.9, 0.98, 1.0, 0.34), false, 2.0)
		draw_line(ice_rect.position + Vector2(12.0, 12.0), ice_rect.position + ice_rect.size - Vector2(10.0, 16.0), Color(1.0, 1.0, 1.0, 0.16), 2.0)
	for grave in graves:
		var grave_center = _cell_center(int(grave["row"]), int(grave["col"])) + Vector2(0.0, 18.0 + sin(ui_time * 1.4 + float(grave["row"]) * 0.8 + float(grave["col"])) * 1.8)
		_draw_grave(grave_center, 1.0 + 0.02 * sin(ui_time * 2.2 + float(grave["col"])))
	for weed in weeds:
		var center = Vector2(float(weed["x"]), _row_center_y(int(weed["row"])) + 18.0 + sin(ui_time * 3.6 + float(weed["x"]) * 0.02) * 2.0)
		draw_circle(center, 18.0, Color(0.2, 0.46, 0.14))
		draw_circle(center + Vector2(-10.0, -6.0), 10.0, Color(0.24, 0.56, 0.16))
		draw_circle(center + Vector2(9.0, -4.0), 9.0, Color(0.18, 0.42, 0.12))
		_draw_health_bar(center + Vector2(0.0, -28.0), 44.0, clampf(float(weed["health"]) / float(weed["max_health"]), 0.0, 1.0), Color(0.28, 0.84, 0.22))
	for spear in spears:
		var sway = sin(ui_time * 2.8 + float(spear["x"]) * 0.02) * 3.0
		var center = Vector2(float(spear["x"]), _row_center_y(int(spear["row"])) + 10.0)
		draw_line(center + Vector2(sway * 0.2, -30.0), center + Vector2(-sway * 0.5, 24.0), Color(0.45, 0.3, 0.12), 4.0)
		draw_polygon(
			PackedVector2Array([
				center + Vector2(sway * 0.3, -40.0),
				center + Vector2(-7.0 + sway * 0.1, -24.0),
				center + Vector2(7.0 + sway * 0.1, -24.0),
			]),
			PackedColorArray([Color(0.76, 0.76, 0.78), Color(0.76, 0.76, 0.78), Color(0.76, 0.76, 0.78)])
		)
		_draw_health_bar(center + Vector2(0.0, -48.0), 36.0, clampf(float(spear["health"]) / float(spear["max_health"]), 0.0, 1.0), Color(0.82, 0.82, 0.86))


func _draw_plant_food_pickups() -> void:
	for pickup in plant_food_pickups:
		var center = Vector2(pickup["position"]) + Vector2(0.0, sin(level_time * 4.6 + float(pickup["position"].x) * 0.03) * 1.8)
		draw_circle(center, 18.0, Color(0.22, 0.92, 0.24, 0.08))
		_draw_plant_food_icon(center, 0.75 + 0.04 * sin(level_time * 8.0 + center.x * 0.02))


func _draw_rollers() -> void:
	for roller in rollers:
		var center = Vector2(float(roller["x"]), _row_center_y(int(roller["row"])) + 16.0)
		_draw_bowling_nut(center, 0.92, 0.0)


func _draw_effects() -> void:
	for effect in effects:
		var ratio = float(effect["time"]) / float(effect["duration"])
		var effect_color = Color(effect["color"])
		effect_color.a *= ratio
		var shape = String(effect.get("shape", "circle"))
		var anim_speed = float(effect.get("anim_speed", 4.0))
		if shape == "dark_orbit":
			var orbit_center = Vector2(effect["position"])
			var orbit_radius = float(effect.get("radius", 120.0)) * (0.82 + (1.0 - ratio) * 0.24)
			draw_circle(orbit_center, orbit_radius, effect_color)
			draw_circle(orbit_center, orbit_radius * 0.72, Color(0.02, 0.0, 0.02, effect_color.a * 0.72), true)
			for orb_index in range(4):
				var angle = level_time * anim_speed + float(orb_index) * TAU * 0.25
				var orb_center = orbit_center + Vector2(cos(angle), sin(angle)) * orbit_radius * 0.74
				draw_circle(orb_center, 10.0 + (1.0 - ratio) * 4.0, Color(0.92, 0.08, 0.18, effect_color.a * 0.8))
			for ring_index in range(3):
				var ring_phase = level_time * (anim_speed * 0.7) + ring_index * 0.8
				draw_arc(orbit_center, orbit_radius * (0.42 + ring_index * 0.16), ring_phase, ring_phase + PI * 1.28, 26, Color(0.76, 0.06, 0.16, effect_color.a * 0.68), 2.0)
			continue
		if shape == "night_bird_swarm":
			var bird_origin = Vector2(effect["position"])
			var bird_length = float(effect.get("length", 180.0)) * (0.62 + ratio * 0.38)
			var bird_width = float(effect.get("width", 64.0))
			for bird_index in range(4):
				var bird_ratio = float(bird_index + 1) / 4.0
				var bird_phase = level_time * anim_speed + bird_ratio * 1.7
				var flap = sin(bird_phase) * bird_width * 0.16
				var start = bird_origin + Vector2(bird_length * bird_ratio * 0.28, sin(bird_phase * 0.7) * bird_width * 0.08)
				var end = bird_origin + Vector2(bird_length * bird_ratio, 0.0)
				draw_polygon(
					PackedVector2Array([
						start + Vector2(bird_length * 0.12, -bird_width * 0.16 - flap),
						end,
						start + Vector2(bird_length * 0.12, bird_width * 0.16 + flap),
						start + Vector2(-bird_length * 0.04, 0.0),
					]),
					PackedColorArray([effect_color, effect_color, effect_color, effect_color])
				)
			for feather_index in range(7):
				var feather_ratio = float(feather_index + 1) / 7.0
				var feather_center = bird_origin + Vector2(bird_length * feather_ratio, sin(level_time * anim_speed + feather_ratio * 4.0) * bird_width * 0.22)
				draw_circle(feather_center, bird_width * (0.08 + (1.0 - feather_ratio) * 0.04), Color(0.96, 0.22, 0.3, effect_color.a * (0.32 - feather_ratio * 0.02)))
			continue
		if shape == "rumia_burst":
			var burst_center = Vector2(effect["position"])
			var burst_radius = float(effect.get("radius", 120.0)) * (0.66 + (1.0 - ratio) * 0.34)
			draw_circle(burst_center, burst_radius, effect_color)
			draw_circle(burst_center, burst_radius * 0.8, Color(1.0, 1.0, 1.0, effect_color.a * 0.12), false, 4.0)
			for ring_index in range(3):
				draw_arc(burst_center, burst_radius * (0.42 + ring_index * 0.16), level_time * anim_speed + ring_index, level_time * anim_speed + ring_index + PI * 1.34, 22, Color(0.94, 0.12, 0.18, effect_color.a * 0.72), 2.0)
			continue
		if shape == "rumia_beam":
			var origin = Vector2(effect["position"])
			var length = float(effect.get("length", float(effect.get("radius", 120.0))))
			var width = float(effect.get("width", 78.0)) * (0.78 + ratio * 0.22)
			var beam_length = length * (0.58 + ratio * 0.42)
			for band_index in range(3):
				var band_ratio = float(band_index + 1) / 3.0
				var jitter = sin(level_time * anim_speed + band_index * 1.4) * width * 0.08
				var band_width = width * (0.52 - band_ratio * 0.12)
				draw_rect(Rect2(origin + Vector2(0.0, -band_width * 0.5 + jitter), Vector2(beam_length, band_width)), Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * (0.42 + band_ratio * 0.12)), true)
			for spark_index in range(6):
				var spark_ratio = float(spark_index + 1) / 6.0
				var spark_center = origin + Vector2(beam_length * spark_ratio, sin(level_time * anim_speed * 1.4 + spark_ratio * 7.0) * width * 0.18)
				draw_circle(spark_center, width * (0.06 + (1.0 - spark_ratio) * 0.03), Color(1.0, 0.56, 0.62, effect_color.a * 0.54))
			draw_circle(origin + Vector2(beam_length, 0.0), width * 0.3, Color(1.0, 0.28, 0.34, effect_color.a * 0.92))
			continue
		if shape == "sniper_focus":
			var focus_origin = Vector2(effect["position"])
			var focus_target = Vector2(effect.get("target", focus_origin))
			var focus_dir = focus_target - focus_origin
			var focus_length = maxf(focus_dir.length(), 1.0)
			var focus_normal = Vector2(-focus_dir.y, focus_dir.x).normalized()
			var focus_dir_n = focus_dir / focus_length
			for band_index in range(4):
				var offset_scale = (1.0 - ratio) * (18.0 + band_index * 6.0)
				var band_start = focus_origin + focus_normal * offset_scale
				var band_end = focus_target - focus_dir_n * (12.0 + band_index * 4.0)
				draw_line(band_start, band_end, Color(0.82, 0.96, 1.0, effect_color.a * (0.34 + band_index * 0.08)), 1.8 + band_index * 0.35)
				draw_line(focus_origin - focus_normal * offset_scale, band_end, Color(0.82, 0.96, 1.0, effect_color.a * (0.28 + band_index * 0.06)), 1.4 + band_index * 0.3)
			draw_circle(focus_target, 12.0 + (1.0 - ratio) * 8.0, Color(0.92, 1.0, 1.0, effect_color.a * 0.16))
			draw_circle(focus_target, 4.0 + sin(level_time * anim_speed) * 1.0, Color(0.92, 1.0, 1.0, effect_color.a * 0.82))
			continue
		if shape == "sniper_beam":
			var beam_origin = Vector2(effect["position"])
			var beam_target = Vector2(effect.get("target", beam_origin + Vector2.RIGHT * 120.0))
			var beam_dir = beam_target - beam_origin
			var beam_length = maxf(beam_dir.length(), 1.0)
			var beam_normal = Vector2(-beam_dir.y, beam_dir.x).normalized()
			var beam_dir_n = beam_dir / beam_length
			for band_index in range(3):
				var beam_width = (7.0 - band_index * 1.8) * (0.78 + ratio * 0.22)
				var jitter = sin(level_time * anim_speed + band_index * 1.6) * 1.6
				var band_offset = beam_normal * jitter
				draw_line(beam_origin + band_offset, beam_target + band_offset, Color(0.66, 0.94, 1.0, effect_color.a * (0.3 + band_index * 0.18)), beam_width)
			for spark_index in range(5):
				var spark_ratio = float(spark_index + 1) / 5.0
				var spark_center = beam_origin + beam_dir_n * beam_length * spark_ratio + beam_normal * sin(level_time * anim_speed * 1.2 + spark_ratio * 6.0) * 5.0
				draw_circle(spark_center, 2.6 + (1.0 - spark_ratio) * 2.0, Color(0.92, 1.0, 1.0, effect_color.a * 0.72))
			draw_circle(beam_origin, 7.0, Color(0.88, 0.98, 1.0, effect_color.a * 0.5))
			draw_circle(beam_target, 12.0, Color(0.9, 1.0, 1.0, effect_color.a * 0.78))
			continue
		if shape == "fairy_ring":
			var ring_center = Vector2(effect["position"])
			var ring_radius = float(effect.get("radius", 120.0)) * (0.78 + (1.0 - ratio) * 0.28)
			draw_circle(ring_center, ring_radius, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.22))
			draw_circle(ring_center, ring_radius * 0.74, Color(1.0, 1.0, 1.0, effect_color.a * 0.08), false, 3.0)
			for ring_index in range(3):
				var ring_phase = level_time * anim_speed + ring_index * 0.92
				draw_arc(ring_center, ring_radius * (0.46 + ring_index * 0.16), ring_phase, ring_phase + PI * 1.22, 24, Color(0.9, 1.0, 0.96, effect_color.a * 0.64), 2.0)
			for orb_index in range(6):
				var angle = level_time * anim_speed * 0.82 + float(orb_index) * TAU / 6.0
				var orb_center = ring_center + Vector2(cos(angle), sin(angle)) * ring_radius * 0.78
				draw_circle(orb_center, 6.0 + (1.0 - ratio) * 2.0, Color(0.88, 1.0, 0.92, effect_color.a * 0.82))
			continue
		if shape == "fairy_lance":
			var lance_origin = Vector2(effect["position"])
			var lance_length = float(effect.get("length", float(effect.get("radius", 160.0)))) * (0.58 + ratio * 0.42)
			var lance_width = float(effect.get("width", 48.0))
			for band_index in range(3):
				var band_width = lance_width * (0.46 - float(band_index) * 0.09)
				var jitter = sin(level_time * anim_speed + band_index * 1.3) * lance_width * 0.08
				draw_rect(
					Rect2(lance_origin + Vector2(0.0, -band_width * 0.5 + jitter), Vector2(lance_length, band_width)),
					Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * (0.36 + float(band_index) * 0.08)),
					true
				)
			draw_polygon(
				PackedVector2Array([
					lance_origin + Vector2(lance_length, 0.0),
					lance_origin + Vector2(lance_length - lance_width * 0.74, -lance_width * 0.42),
					lance_origin + Vector2(lance_length - lance_width * 0.74, lance_width * 0.42),
				]),
				PackedColorArray([Color(0.96, 1.0, 0.98, effect_color.a), effect_color, effect_color])
			)
			continue
		if shape == "icicle_fall":
			var shard_points: Array = effect.get("points", [])
			for point_variant in shard_points:
				var impact = Vector2(point_variant)
				var fall = (1.0 - ratio) * 110.0
				var top = impact + Vector2(0.0, -fall)
				draw_polygon(
					PackedVector2Array([
						top + Vector2(0.0, -30.0),
						impact + Vector2(-12.0, -8.0),
						impact + Vector2(12.0, -8.0),
					]),
					PackedColorArray([
						Color(0.96, 1.0, 1.0, effect_color.a),
						Color(0.72, 0.94, 1.0, effect_color.a * 0.84),
						Color(0.72, 0.94, 1.0, effect_color.a * 0.84),
					])
				)
				draw_circle(impact + Vector2(0.0, 4.0), 12.0 + (1.0 - ratio) * 4.0, Color(0.92, 1.0, 1.0, effect_color.a * 0.24))
			continue
		if shape == "perfect_freeze":
			var freeze_center = Vector2(effect["position"])
			var freeze_radius = float(effect.get("radius", 200.0)) * (0.84 + (1.0 - ratio) * 0.24)
			draw_circle(freeze_center, freeze_radius, Color(0.88, 0.98, 1.0, effect_color.a * 0.18))
			for ring_index in range(3):
				draw_circle(freeze_center, freeze_radius * (0.38 + ring_index * 0.2), Color(0.72, 0.94, 1.0, effect_color.a * (0.22 - ring_index * 0.03)), false, 3.0)
			for spoke_index in range(6):
				var angle = level_time * anim_speed * 0.22 + float(spoke_index) * TAU / 6.0
				var spoke_dir = Vector2(cos(angle), sin(angle))
				draw_line(freeze_center - spoke_dir * freeze_radius * 0.16, freeze_center + spoke_dir * freeze_radius * 0.86, Color(1.0, 1.0, 1.0, effect_color.a * 0.38), 2.0)
				var branch_center = freeze_center + spoke_dir * freeze_radius * 0.62
				draw_line(branch_center, branch_center + spoke_dir.rotated(0.7) * 18.0, Color(0.84, 0.98, 1.0, effect_color.a * 0.3), 2.0)
				draw_line(branch_center, branch_center + spoke_dir.rotated(-0.7) * 18.0, Color(0.84, 0.98, 1.0, effect_color.a * 0.3), 2.0)
			continue
		if shape == "diamond_blizzard":
			var storm_origin = Vector2(effect["position"])
			var storm_length = float(effect.get("length", float(effect.get("radius", 180.0)))) * (0.66 + ratio * 0.34)
			var storm_width = float(effect.get("width", 240.0))
			for diamond_index in range(14):
				var diamond_ratio = float(diamond_index) / 13.0
				var diamond_center = storm_origin + Vector2(
					storm_length * diamond_ratio,
					sin(level_time * anim_speed + diamond_ratio * 7.0) * storm_width * 0.34
				)
				var diamond_size = 10.0 + float(diamond_index % 3) * 2.5
				draw_polygon(
					PackedVector2Array([
						diamond_center + Vector2(0.0, -diamond_size),
						diamond_center + Vector2(diamond_size * 0.72, 0.0),
						diamond_center + Vector2(0.0, diamond_size),
						diamond_center + Vector2(-diamond_size * 0.72, 0.0),
					]),
					PackedColorArray([
						Color(0.98, 1.0, 1.0, effect_color.a),
						Color(0.74, 0.96, 1.0, effect_color.a * 0.86),
						Color(0.74, 0.96, 1.0, effect_color.a * 0.76),
						Color(0.74, 0.96, 1.0, effect_color.a * 0.86),
					])
				)
			continue
		if shape == "lane_spray":
			var origin = Vector2(effect["position"])
			var length = float(effect.get("length", float(effect.get("radius", 120.0))))
			var width = float(effect.get("width", 78.0)) * (0.86 + ratio * 0.14)
			var plume_length = length * (0.64 + ratio * 0.36)
			var plume_rect = Rect2(origin + Vector2(0.0, -width * 0.5), Vector2(plume_length, width))
			draw_rect(plume_rect, effect_color, true)
			draw_rect(
				Rect2(plume_rect.position + Vector2(0.0, width * 0.08), Vector2(plume_rect.size.x, width * 0.26)),
				Color(1.0, 1.0, 1.0, effect_color.a * 0.34),
				true
			)
			for puff_index in range(5):
				var puff_ratio = float(puff_index + 1) / 5.0
				var puff_center = origin + Vector2(plume_length * puff_ratio, sin(level_time * 8.0 + puff_ratio * 5.0) * width * 0.1)
				var puff_radius = width * (0.24 + (1.0 - puff_ratio) * 0.12)
				draw_circle(puff_center, puff_radius, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * (0.46 - puff_ratio * 0.05)))
			draw_circle(origin + Vector2(plume_length, 0.0), width * 0.28, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.84))
			continue
		if shape == "squash_slam":
			var slam_radius = float(effect.get("radius", 72.0)) * (0.8 + (1.0 - ratio) * 0.24)
			var slam_center = Vector2(effect["position"])
			draw_circle(slam_center, slam_radius, effect_color)
			draw_circle(slam_center, slam_radius * 0.82, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.26), false, 4.0)
			draw_rect(Rect2(slam_center + Vector2(-slam_radius * 0.86, 12.0), Vector2(slam_radius * 1.72, 8.0)), Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.42), true)
			continue
		var radius = float(effect["radius"]) * (1.0 - ratio * 0.35)
		draw_circle(Vector2(effect["position"]), radius, effect_color)
		draw_circle(Vector2(effect["position"]), radius * (0.72 + 0.18 * ratio), Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.32), false, 3.0)


func _draw_mowers() -> void:
	for mower in mowers:
		if not _is_row_active(int(mower["row"])) and not bool(mower["active"]):
			continue
		var center = Vector2(float(mower["x"]), _row_center_y(int(mower["row"])))
		var wheel_spin = level_time * 10.0 + float(mower["x"]) * 0.02
		if _is_pool_level() and _is_water_row(int(mower["row"])):
			var pool_body = Color(0.22, 0.66, 0.92) if bool(mower["armed"]) else Color(0.56, 0.72, 0.86)
			draw_rect(Rect2(center + Vector2(-24.0, -14.0), Vector2(48.0, 22.0)), pool_body, true)
			draw_rect(Rect2(center + Vector2(-18.0, -22.0), Vector2(36.0, 10.0)), Color(0.92, 0.96, 1.0), true)
			draw_circle(center + Vector2(-14.0, 11.0), 8.0, Color(0.16, 0.34, 0.48))
			draw_circle(center + Vector2(14.0, 11.0), 8.0, Color(0.16, 0.34, 0.48))
			draw_line(center + Vector2(-14.0, 11.0), center + Vector2(-14.0 + cos(wheel_spin) * 6.0, 11.0 + sin(wheel_spin) * 6.0), Color(0.88, 0.96, 1.0), 2.0)
			draw_line(center + Vector2(14.0, 11.0), center + Vector2(14.0 + cos(wheel_spin + 0.8) * 6.0, 11.0 + sin(wheel_spin + 0.8) * 6.0), Color(0.88, 0.96, 1.0), 2.0)
			draw_line(center + Vector2(20.0, -8.0), center + Vector2(34.0, -22.0), Color(0.16, 0.34, 0.48), 3.0)
		else:
			var body_color = Color(0.84, 0.2, 0.16) if bool(mower["armed"]) else Color(0.54, 0.54, 0.54)
			draw_rect(Rect2(center + Vector2(-20.0, -16.0), Vector2(40.0, 24.0)), body_color, true)
			draw_circle(center + Vector2(-11.0, 10.0), 8.0, Color(0.18, 0.18, 0.18))
			draw_circle(center + Vector2(11.0, 10.0), 8.0, Color(0.18, 0.18, 0.18))
			draw_line(center + Vector2(-11.0, 10.0), center + Vector2(-11.0 + cos(wheel_spin) * 6.0, 10.0 + sin(wheel_spin) * 6.0), Color(0.72, 0.72, 0.74), 2.0)
			draw_line(center + Vector2(11.0, 10.0), center + Vector2(11.0 + cos(wheel_spin + 0.8) * 6.0, 10.0 + sin(wheel_spin + 0.8) * 6.0), Color(0.72, 0.72, 0.74), 2.0)
			draw_line(center + Vector2(16.0, -12.0), center + Vector2(34.0, -28.0), Color(0.28, 0.28, 0.28), 3.0)


func _draw_card_icon(kind: String, center: Vector2) -> void:
	match kind:
		"peashooter":
			_draw_peashooter(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"puff_shroom":
			_draw_puff_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0)
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
		"threepeater":
			_draw_threepeater(center + Vector2(0.0, 6.0), 0.48, 0.0)
		"boomerang_shooter":
			_draw_boomerang_shooter(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"sakura_shooter":
			_draw_sakura_shooter(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"lotus_lancer":
			_draw_lotus_lancer(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"mirror_reed":
			_draw_mirror_reed(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"frost_fan":
			_draw_frost_fan(center + Vector2(0.0, 6.0), 0.5, 0.0)
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
		"sun_shroom":
			_draw_sun_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0, false)
		"fume_shroom":
			_draw_fume_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"grave_buster":
			_draw_grave_buster(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"hypno_shroom":
			_draw_hypno_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"scaredy_shroom":
			_draw_scaredy_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0, false)
		"ice_shroom":
			_draw_ice_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"doom_shroom":
			_draw_doom_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"moon_lotus":
			_draw_moon_lotus(center + Vector2(0.0, 6.0), 0.52, 0.0)
		"prism_grass":
			_draw_prism_grass(center + Vector2(0.0, 6.0), 0.52, 0.0)
		"lantern_bloom":
			_draw_lantern_bloom(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"meteor_gourd":
			_draw_meteor_gourd(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"root_snare":
			_draw_root_snare(center + Vector2(0.0, 6.0), 0.52, 0.0)
		"thunder_pine":
			_draw_thunder_pine(center + Vector2(0.0, 6.0), 0.52, 0.0)
		"dream_drum":
			_draw_dream_drum(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"wind_orchid":
			_draw_wind_orchid(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"lily_pad":
			_draw_lily_pad(center + Vector2(0.0, 12.0), 0.56, 0.0)
		"squash":
			_draw_squash(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"tangle_kelp":
			_draw_tangle_kelp(center + Vector2(0.0, 10.0), 0.54, 0.0)
		"jalapeno":
			_draw_jalapeno(center + Vector2(0.0, 8.0), 0.54, 0.0)
		"spikeweed":
			_draw_spikeweed(center + Vector2(0.0, 12.0), 0.56, 0.0)
		"torchwood":
			_draw_torchwood(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"tallnut":
			_draw_tallnut(center + Vector2(0.0, 8.0), 0.52, 0.0, 1.0)
		"wallnut_bowling":
			_draw_bowling_nut(center + Vector2(0.0, 8.0), 0.54, 0.0)


func _draw_plant_preview(kind: String, center: Vector2) -> void:
	match kind:
		"peashooter":
			_draw_peashooter(center, 1.0, 0.0, 0.42)
		"puff_shroom":
			_draw_puff_shroom(center, 1.0, 0.0, 0.42)
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
		"threepeater":
			_draw_threepeater(center, 1.0, 0.0, 0.42)
		"boomerang_shooter":
			_draw_boomerang_shooter(center, 1.0, 0.0, 0.42)
		"sakura_shooter":
			_draw_sakura_shooter(center, 1.0, 0.0, 0.42)
		"lotus_lancer":
			_draw_lotus_lancer(center, 1.0, 0.0, 0.42)
		"mirror_reed":
			_draw_mirror_reed(center, 1.0, 0.0, 0.42)
		"frost_fan":
			_draw_frost_fan(center, 1.0, 0.0, 0.42)
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
		"sun_shroom":
			_draw_sun_shroom(center, 1.0, 0.0, false, 0.42)
		"fume_shroom":
			_draw_fume_shroom(center, 1.0, 0.0, 0.42)
		"grave_buster":
			_draw_grave_buster(center, 1.0, 0.0, 0.42)
		"hypno_shroom":
			_draw_hypno_shroom(center, 1.0, 0.0, 0.42)
		"scaredy_shroom":
			_draw_scaredy_shroom(center, 1.0, 0.0, false, 0.42)
		"ice_shroom":
			_draw_ice_shroom(center, 1.0, 0.0, 0.42)
		"doom_shroom":
			_draw_doom_shroom(center, 1.0, 0.0, 0.42)
		"moon_lotus":
			_draw_moon_lotus(center, 1.0, 0.0, 0.42)
		"prism_grass":
			_draw_prism_grass(center, 1.0, 0.0, 0.42)
		"lantern_bloom":
			_draw_lantern_bloom(center, 1.0, 0.0, 0.42)
		"meteor_gourd":
			_draw_meteor_gourd(center, 1.0, 0.0, 0.42)
		"root_snare":
			_draw_root_snare(center, 1.0, 0.0, 0.42)
		"thunder_pine":
			_draw_thunder_pine(center, 1.0, 0.0, 0.42)
		"dream_drum":
			_draw_dream_drum(center, 1.0, 0.0, 0.42)
		"wind_orchid":
			_draw_wind_orchid(center, 1.0, 0.0, 0.42)
		"lily_pad":
			_draw_lily_pad(center, 1.0, 0.0, 0.42)
		"squash":
			_draw_squash(center, 1.0, 0.0, 0.42)
		"tangle_kelp":
			_draw_tangle_kelp(center, 1.0, 0.0, 0.42)
		"jalapeno":
			_draw_jalapeno(center, 1.0, 0.0, 0.42)
		"spikeweed":
			_draw_spikeweed(center, 1.0, 0.0, 0.42)
		"torchwood":
			_draw_torchwood(center, 1.0, 0.0, 0.42)
		"tallnut":
			_draw_tallnut(center, 1.0, 0.0, 1.0, 0.42)
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


func _draw_puff_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 14.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.72, 0.84, 0.62, alpha), 6.0 * size_scale)
	draw_circle(center + Vector2(0.0, -2.0 * size_scale), 18.0 * size_scale, Color(0.74, 0.52, 0.92, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(12.0 * size_scale, 0.0), 8.0 * size_scale, Color(0.86, 0.72, 0.98, alpha))
	draw_circle(center + Vector2(-5.0 * size_scale, -4.0 * size_scale), 2.6 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(3.0 * size_scale, -4.0 * size_scale), 2.6 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_arc(center + Vector2(-1.0 * size_scale, 3.0 * size_scale), 5.0 * size_scale, 0.2, PI - 0.2, 12, Color(0.1, 0.1, 0.1, alpha), 2.0 * size_scale)


func _draw_sun_shroom(center: Vector2, size_scale: float, flash: float, mature: bool, alpha: float = 1.0) -> void:
	var cap_radius = 20.0 if mature else 14.0
	var stem_height = 34.0 if mature else 26.0
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, stem_height * size_scale), Color(0.88, 0.86, 0.66, alpha), 6.0 * size_scale)
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), cap_radius * size_scale, Color(0.98, 0.84, 0.28, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(-6.0 * size_scale, -8.0 * size_scale), 4.0 * size_scale, Color(1.0, 0.95, 0.58, alpha))
	draw_circle(center + Vector2(6.0 * size_scale, -4.0 * size_scale), 4.0 * size_scale, Color(1.0, 0.95, 0.58, alpha))
	draw_circle(center + Vector2(-4.0 * size_scale, -7.0 * size_scale), 2.4 * size_scale, Color(0.16, 0.1, 0.06, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -7.0 * size_scale), 2.4 * size_scale, Color(0.16, 0.1, 0.06, alpha))


func _draw_fume_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.84, 0.8, 0.76, alpha), 7.0 * size_scale)
	draw_circle(center + Vector2(-2.0 * size_scale, -8.0 * size_scale), 22.0 * size_scale, Color(0.62, 0.34, 0.76, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(18.0 * size_scale, -10.0 * size_scale), 12.0 * size_scale, Color(0.78, 0.54, 0.92, alpha))
	draw_circle(center + Vector2(-7.0 * size_scale, -11.0 * size_scale), 3.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(3.0 * size_scale, -11.0 * size_scale), 3.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_rect(Rect2(center + Vector2(12.0 * size_scale, -18.0 * size_scale), Vector2(32.0 * size_scale, 16.0 * size_scale)), Color(0.9, 0.72, 1.0, alpha), true)
	draw_circle(center + Vector2(44.0 * size_scale, -10.0 * size_scale), 8.0 * size_scale, Color(0.94, 0.8, 1.0, alpha * 0.9))
	draw_circle(center + Vector2(54.0 * size_scale, -10.0 * size_scale), 5.0 * size_scale, Color(0.94, 0.8, 1.0, alpha * 0.54))


func _draw_grave_buster(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(0.0, 8.0 * size_scale), 18.0 * size_scale, Color(0.22, 0.72, 0.2, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(-12.0 * size_scale, 4.0 * size_scale), 10.0 * size_scale, Color(0.28, 0.82, 0.26, alpha))
	draw_circle(center + Vector2(12.0 * size_scale, 4.0 * size_scale), 10.0 * size_scale, Color(0.28, 0.82, 0.26, alpha))
	draw_arc(center + Vector2(0.0, 10.0 * size_scale), 12.0 * size_scale, PI, TAU, 14, Color(0.08, 0.08, 0.08, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(-16.0 * size_scale, 22.0 * size_scale), center + Vector2(16.0 * size_scale, 22.0 * size_scale), Color(0.12, 0.52, 0.1, alpha), 4.0 * size_scale)


func _draw_hypno_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.82, 0.82, 0.72, alpha), 6.0 * size_scale)
	draw_circle(center + Vector2(0.0, -4.0 * size_scale), 18.0 * size_scale, Color(0.86, 0.5, 0.92, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_arc(center + Vector2(-5.0 * size_scale, -5.0 * size_scale), 4.0 * size_scale, 0.0, TAU, 18, Color(0.24, 0.58, 0.98, alpha), 2.0 * size_scale)
	draw_arc(center + Vector2(5.0 * size_scale, -5.0 * size_scale), 4.0 * size_scale, 0.0, TAU, 18, Color(0.24, 0.58, 0.98, alpha), 2.0 * size_scale)
	draw_circle(center + Vector2(-5.0 * size_scale, -5.0 * size_scale), 0.8 * size_scale, Color(0.24, 0.58, 0.98, alpha))
	draw_circle(center + Vector2(5.0 * size_scale, -5.0 * size_scale), 0.8 * size_scale, Color(0.24, 0.58, 0.98, alpha))


func _draw_scaredy_shroom(center: Vector2, size_scale: float, flash: float, hiding: bool, alpha: float = 1.0) -> void:
	var cap_center = center + Vector2(0.0, -6.0 * size_scale if not hiding else 4.0 * size_scale)
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.82, 0.82, 0.72, alpha), 6.0 * size_scale)
	draw_circle(cap_center, 17.0 * size_scale, Color(0.74, 0.5, 0.9, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(cap_center + Vector2(-6.0 * size_scale, -2.0 * size_scale), 4.0 * size_scale, Color(1.0, 1.0, 1.0, alpha))
	draw_circle(cap_center + Vector2(6.0 * size_scale, -2.0 * size_scale), 4.0 * size_scale, Color(1.0, 1.0, 1.0, alpha))
	draw_circle(cap_center + Vector2(-6.0 * size_scale, -2.0 * size_scale), 1.4 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(cap_center + Vector2(6.0 * size_scale, -2.0 * size_scale), 1.4 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	if hiding:
		draw_arc(cap_center + Vector2(0.0, 5.0 * size_scale), 5.0 * size_scale, PI, TAU, 12, Color(0.08, 0.08, 0.08, alpha), 2.0 * size_scale)
	else:
		draw_arc(cap_center + Vector2(0.0, 5.0 * size_scale), 5.0 * size_scale, 0.1, PI - 0.1, 12, Color(0.08, 0.08, 0.08, alpha), 2.0 * size_scale)


func _draw_ice_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.86, 0.92, 1.0, alpha), 6.0 * size_scale)
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), 20.0 * size_scale, Color(0.62, 0.88, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(-8.0 * size_scale, -14.0 * size_scale), 6.0 * size_scale, Color(0.86, 0.96, 1.0, alpha))
	draw_circle(center + Vector2(8.0 * size_scale, -12.0 * size_scale), 5.0 * size_scale, Color(0.86, 0.96, 1.0, alpha))
	draw_line(center + Vector2(-18.0 * size_scale, -4.0 * size_scale), center + Vector2(18.0 * size_scale, -4.0 * size_scale), Color(0.9, 0.98, 1.0, alpha), 2.0 * size_scale)


func _draw_doom_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 14.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.58, 0.52, 0.46, alpha), 7.0 * size_scale)
	draw_circle(center + Vector2(0.0, -2.0 * size_scale), 24.0 * size_scale, Color(0.42, 0.08, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(0.0, -2.0 * size_scale), 11.0 * size_scale, Color(0.86, 0.22, 0.36, alpha))
	draw_circle(center + Vector2(-8.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_circle(center + Vector2(8.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(0.06, 0.06, 0.06, alpha))


func _draw_grave(center: Vector2, size_scale: float, alpha: float = 1.0) -> void:
	draw_rect(Rect2(center + Vector2(-18.0 * size_scale, -26.0 * size_scale), Vector2(36.0 * size_scale, 42.0 * size_scale)), Color(0.48, 0.5, 0.58, alpha), true)
	draw_arc(center + Vector2(0.0, -26.0 * size_scale), 18.0 * size_scale, PI, TAU, 18, Color(0.48, 0.5, 0.58, alpha), 36.0 * size_scale)
	draw_rect(Rect2(center + Vector2(-20.0 * size_scale, 14.0 * size_scale), Vector2(40.0 * size_scale, 8.0 * size_scale)), Color(0.36, 0.3, 0.26, alpha), true)
	draw_line(center + Vector2(-8.0 * size_scale, -12.0 * size_scale), center + Vector2(8.0 * size_scale, -12.0 * size_scale), Color(0.8, 0.82, 0.88, alpha), 3.0 * size_scale)
	draw_line(center + Vector2(0.0, -20.0 * size_scale), center + Vector2(0.0, -4.0 * size_scale), Color(0.8, 0.82, 0.88, alpha), 3.0 * size_scale)


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


func _draw_moon_lotus(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), 18.0 * size_scale, Color(0.7, 0.82, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), 8.0 * size_scale, Color(0.92, 0.96, 1.0, alpha))
	for index in range(6):
		var angle = TAU * float(index) / 6.0
		draw_circle(center + Vector2(cos(angle), sin(angle)) * 16.0 * size_scale, 6.0 * size_scale, Color(0.54, 0.72, 0.98, alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.2, alpha), 6.0 * size_scale)


func _draw_prism_grass(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.2, alpha), 6.0 * size_scale)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(0.0, -24.0 * size_scale),
			center + Vector2(-18.0 * size_scale, 4.0 * size_scale),
			center + Vector2(18.0 * size_scale, 4.0 * size_scale),
		]),
		PackedColorArray([
			Color(0.72, 0.96, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0),
			Color(0.42, 0.84, 0.96, alpha),
			Color(0.42, 0.84, 0.96, alpha),
		])
	)
	draw_circle(center + Vector2(0.0, 8.0 * size_scale), 10.0 * size_scale, Color(0.28, 0.72, 0.24, alpha))


func _draw_lantern_bloom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.24, 0.56, 0.2, alpha), 6.0 * size_scale)
	draw_circle(center + Vector2(0.0, -12.0 * size_scale), 16.0 * size_scale, Color(0.96, 0.72, 0.24, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_rect(Rect2(center + Vector2(-12.0 * size_scale, -2.0 * size_scale), Vector2(24.0 * size_scale, 24.0 * size_scale)), Color(0.5, 0.28, 0.12, alpha), true)
	draw_circle(center + Vector2(-10.0 * size_scale, 16.0 * size_scale), 8.0 * size_scale, Color(0.3, 0.78, 0.24, alpha))
	draw_circle(center + Vector2(10.0 * size_scale, 16.0 * size_scale), 8.0 * size_scale, Color(0.3, 0.78, 0.24, alpha))


func _draw_meteor_gourd(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(0.0, 8.0 * size_scale), 20.0 * size_scale, Color(0.86, 0.48, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(-10.0 * size_scale, -4.0 * size_scale), 7.0 * size_scale, Color(1.0, 0.72, 0.3, alpha))
	draw_circle(center + Vector2(12.0 * size_scale, -8.0 * size_scale), 6.0 * size_scale, Color(0.7, 0.18, 0.12, alpha))
	draw_line(center + Vector2(0.0, 14.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.24, 0.54, 0.16, alpha), 6.0 * size_scale)


func _draw_root_snare(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.24, 0.56, 0.18, alpha), 6.0 * size_scale)
	for index in range(3):
		var x_offset = -12.0 + float(index) * 12.0
		draw_line(center + Vector2(x_offset * size_scale, 4.0 * size_scale), center + Vector2((x_offset + 6.0 * sin(float(index))) * size_scale, -18.0 * size_scale), Color(0.38, 0.72, 0.24, alpha), 4.0 * size_scale)
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), 10.0 * size_scale, Color(0.64, 0.88, 0.28, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))


func _draw_thunder_pine(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_polygon(
		PackedVector2Array([
			center + Vector2(0.0, -26.0 * size_scale),
			center + Vector2(-18.0 * size_scale, 20.0 * size_scale),
			center + Vector2(18.0 * size_scale, 20.0 * size_scale),
		]),
		PackedColorArray([
			Color(0.26, 0.54, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0),
			Color(0.18, 0.38, 0.12, alpha),
			Color(0.18, 0.38, 0.12, alpha),
		])
	)
	draw_line(center + Vector2(0.0, 18.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.38, 0.26, 0.12, alpha), 5.0 * size_scale)
	draw_line(center + Vector2(-6.0 * size_scale, -4.0 * size_scale), center + Vector2(4.0 * size_scale, 10.0 * size_scale), Color(1.0, 0.92, 0.28, alpha), 2.0 * size_scale)
	draw_line(center + Vector2(4.0 * size_scale, 10.0 * size_scale), center + Vector2(-2.0 * size_scale, 18.0 * size_scale), Color(1.0, 0.92, 0.28, alpha), 2.0 * size_scale)


func _draw_dream_drum(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(0.0, 10.0 * size_scale), 18.0 * size_scale, Color(0.74, 0.46, 0.2, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(0.0, 10.0 * size_scale), 10.0 * size_scale, Color(0.94, 0.82, 0.52, alpha))
	draw_line(center + Vector2(-14.0 * size_scale, -10.0 * size_scale), center + Vector2(-6.0 * size_scale, 2.0 * size_scale), Color(0.28, 0.64, 0.22, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(14.0 * size_scale, -10.0 * size_scale), center + Vector2(6.0 * size_scale, 2.0 * size_scale), Color(0.28, 0.64, 0.22, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(0.0, 18.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.26, 0.56, 0.18, alpha), 5.0 * size_scale)


func _draw_lily_pad(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_circle(center + Vector2(-14.0 * size_scale, 12.0 * size_scale), 18.0 * size_scale, Color(0.24, 0.72, 0.38, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4))
	draw_circle(center + Vector2(10.0 * size_scale, 10.0 * size_scale), 20.0 * size_scale, Color(0.2, 0.64, 0.34, alpha))
	draw_circle(center + Vector2(0.0, 4.0 * size_scale), 16.0 * size_scale, Color(0.28, 0.8, 0.44, alpha))
	draw_polygon(
		PackedVector2Array([
			center + Vector2(4.0 * size_scale, -4.0 * size_scale),
			center + Vector2(22.0 * size_scale, 8.0 * size_scale),
			center + Vector2(4.0 * size_scale, 18.0 * size_scale),
		]),
		PackedColorArray([Color(0.12, 0.56, 0.28, alpha), Color(0.12, 0.56, 0.28, alpha), Color(0.12, 0.56, 0.28, alpha)])
	)


func _draw_squash(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 30.0 * size_scale), Color(0.22, 0.58, 0.18, alpha), 5.0 * size_scale)
	draw_circle(center + Vector2(0.0, 0.0), 22.0 * size_scale, Color(0.44, 0.86, 0.22, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6))
	draw_circle(center + Vector2(-11.0 * size_scale, -3.0 * size_scale), 7.0 * size_scale, Color(0.58, 0.92, 0.28, alpha))
	draw_circle(center + Vector2(11.0 * size_scale, -4.0 * size_scale), 7.0 * size_scale, Color(0.58, 0.92, 0.28, alpha))
	draw_circle(center + Vector2(-7.0 * size_scale, -2.0 * size_scale), 2.6 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(7.0 * size_scale, -2.0 * size_scale), 2.6 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_line(center + Vector2(-12.0 * size_scale, -14.0 * size_scale), center + Vector2(-4.0 * size_scale, -10.0 * size_scale), Color(0.08, 0.08, 0.08, alpha), 2.0 * size_scale)
	draw_line(center + Vector2(4.0 * size_scale, -10.0 * size_scale), center + Vector2(12.0 * size_scale, -14.0 * size_scale), Color(0.08, 0.08, 0.08, alpha), 2.0 * size_scale)
	draw_arc(center + Vector2(0.0, 11.0 * size_scale), 9.0 * size_scale, 0.15, PI - 0.15, 12, Color(0.08, 0.08, 0.08, alpha), 2.2 * size_scale)


func _draw_threepeater(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.18, alpha), 6.0 * size_scale)
	_draw_peashooter(center + Vector2(-2.0 * size_scale, -20.0 * size_scale), size_scale * 0.62, flash, alpha)
	_draw_peashooter(center + Vector2(-10.0 * size_scale, 0.0), size_scale * 0.68, flash, alpha)
	_draw_peashooter(center + Vector2(-2.0 * size_scale, 20.0 * size_scale), size_scale * 0.62, flash, alpha)


func _draw_boomerang_shooter(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.56, 0.84, 0.26, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	var arm_color = Color(0.72, 0.9, 0.38, alpha)
	var boom_color = Color(0.96, 0.68, 0.18, alpha)
	var spin = sin(level_time * 6.0) * 2.0
	draw_line(center + Vector2(-4.0 * size_scale, 12.0 * size_scale), center + Vector2(-8.0 * size_scale, 34.0 * size_scale), Color(0.24, 0.54, 0.16, alpha), 6.0 * size_scale)
	draw_line(center + Vector2(-8.0 * size_scale, 22.0 * size_scale), center + Vector2(-22.0 * size_scale, 12.0 * size_scale), Color(0.3, 0.62, 0.18, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(-8.0 * size_scale, 24.0 * size_scale), center + Vector2(8.0 * size_scale, 34.0 * size_scale), Color(0.3, 0.62, 0.18, alpha), 4.0 * size_scale)
	draw_circle(center + Vector2(-12.0 * size_scale, -2.0 * size_scale), 17.0 * size_scale, body_color)
	draw_circle(center + Vector2(-24.0 * size_scale, -4.0 * size_scale), 12.0 * size_scale, body_color.darkened(0.04))
	draw_circle(center + Vector2(-2.0 * size_scale, -6.0 * size_scale), 12.0 * size_scale, arm_color)
	draw_circle(center + Vector2(-30.0 * size_scale, -8.0 * size_scale), 8.0 * size_scale, Color(0.72, 0.9, 0.3, alpha))
	draw_line(center + Vector2(-4.0 * size_scale, -8.0 * size_scale), center + Vector2(20.0 * size_scale, -18.0 * size_scale), Color(0.34, 0.6, 0.18, alpha), 4.0 * size_scale)
	draw_arc(center + Vector2(26.0 * size_scale, (-18.0 + spin) * size_scale), 12.0 * size_scale, -1.25, 0.95, 18, boom_color, 3.2 * size_scale)
	draw_arc(center + Vector2(24.0 * size_scale, (-18.0 + spin) * size_scale), 7.0 * size_scale, -1.15, 0.82, 14, Color(0.5, 0.28, 0.08, alpha), 1.4 * size_scale)
	draw_arc(center + Vector2(-26.0 * size_scale, -28.0 * size_scale), 10.0 * size_scale, 1.8, 4.3, 16, boom_color.darkened(0.08), 2.4 * size_scale)
	draw_circle(center + Vector2(-20.0 * size_scale, -10.0 * size_scale), 2.6 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-11.0 * size_scale, -12.0 * size_scale), 2.4 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_sakura_shooter(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var bark = Color(0.48, 0.3, 0.18, alpha)
	var canopy = Color(0.98, 0.76, 0.86, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	var blossom_core = Color(0.98, 0.56, 0.72, alpha)
	var drift = sin(level_time * 2.4 + center.x * 0.02) * 2.0
	draw_line(center + Vector2(-8.0 * size_scale, 14.0 * size_scale), center + Vector2(-8.0 * size_scale, 34.0 * size_scale), bark, 6.0 * size_scale)
	draw_line(center + Vector2(-8.0 * size_scale, 6.0 * size_scale), center + Vector2(10.0 * size_scale, -10.0 * size_scale), bark, 4.0 * size_scale)
	draw_line(center + Vector2(-6.0 * size_scale, -2.0 * size_scale), center + Vector2(-22.0 * size_scale, -18.0 * size_scale), bark, 3.2 * size_scale)
	for blossom in [
		Vector2(-24.0, -20.0),
		Vector2(-8.0, -24.0 + drift),
		Vector2(10.0, -14.0),
		Vector2(20.0, -22.0 - drift * 0.6),
		Vector2(4.0, -2.0 + drift * 0.4)
	]:
		var petal_center = center + blossom * size_scale
		for index in range(4):
			var angle = PI * 0.25 + float(index) * PI * 0.5
			var offset = Vector2(cos(angle), sin(angle)) * 6.0 * size_scale
			draw_circle(petal_center + offset, 6.0 * size_scale, canopy)
		draw_circle(petal_center, 4.0 * size_scale, blossom_core)
	draw_circle(center + Vector2(-16.0 * size_scale, -10.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-8.0 * size_scale, -12.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	for petal_index in range(3):
		var fall_center = center + Vector2((10.0 + petal_index * 10.0) * size_scale, (-2.0 + petal_index * 8.0 + sin(level_time * 3.0 + petal_index) * 3.0) * size_scale)
		draw_circle(fall_center, 3.0 * size_scale, canopy * Color(1.0, 1.0, 1.0, 0.78))


func _draw_lotus_lancer(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var lotus_green = Color(0.28, 0.72, 0.46, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	var lotus_purple = Color(0.7, 0.54, 0.88, alpha)
	var lance_blue = Color(0.78, 0.94, 1.0, alpha)
	var wave = sin(level_time * 3.1 + center.x * 0.01) * 2.0
	draw_circle(center + Vector2(-8.0 * size_scale, 18.0 * size_scale), 16.0 * size_scale, Color(0.18, 0.62, 0.38, alpha))
	draw_circle(center + Vector2(8.0 * size_scale, 18.0 * size_scale), 14.0 * size_scale, Color(0.22, 0.68, 0.42, alpha))
	draw_polygon(
		PackedVector2Array([
			center + Vector2(6.0 * size_scale, 10.0 * size_scale),
			center + Vector2(24.0 * size_scale, 18.0 * size_scale),
			center + Vector2(2.0 * size_scale, 28.0 * size_scale),
		]),
		PackedColorArray([Color(0.12, 0.54, 0.32, alpha), Color(0.16, 0.62, 0.38, alpha), Color(0.12, 0.54, 0.32, alpha)])
	)
	draw_line(center + Vector2(-4.0 * size_scale, 12.0 * size_scale), center + Vector2(-2.0 * size_scale, -20.0 * size_scale), Color(0.24, 0.58, 0.3, alpha), 5.0 * size_scale)
	for petal in [
		Vector2(-16.0, -6.0 + wave),
		Vector2(-4.0, -18.0),
		Vector2(8.0, -8.0 - wave * 0.5),
		Vector2(-2.0, -2.0)
	]:
		draw_circle(center + petal * size_scale, 10.0 * size_scale, lotus_purple)
	draw_circle(center + Vector2(-2.0 * size_scale, -8.0 * size_scale), 7.0 * size_scale, Color(0.98, 0.88, 0.46, alpha))
	draw_line(center + Vector2(10.0 * size_scale, -10.0 * size_scale), center + Vector2(34.0 * size_scale, -20.0 * size_scale), lance_blue, 3.0 * size_scale)
	draw_line(center + Vector2(34.0 * size_scale, -20.0 * size_scale), center + Vector2(54.0 * size_scale, -20.0 * size_scale), Color(0.92, 0.98, 1.0, alpha), 2.2 * size_scale)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(54.0 * size_scale, -20.0 * size_scale),
			center + Vector2(68.0 * size_scale, -26.0 * size_scale),
			center + Vector2(62.0 * size_scale, -20.0 * size_scale),
			center + Vector2(68.0 * size_scale, -14.0 * size_scale),
		]),
		PackedColorArray([lance_blue, Color(0.94, 1.0, 1.0, alpha), lance_blue, lance_blue])
	)
	draw_circle(center + Vector2(-10.0 * size_scale, -10.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-2.0 * size_scale, -12.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_arc(center + Vector2(-4.0 * size_scale, 18.0 * size_scale), 24.0 * size_scale, 3.5, 5.8, 18, Color(0.74, 0.96, 1.0, alpha * 0.28), 1.2 * size_scale)


func _draw_mirror_reed(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var reed_green = Color(0.46, 0.7, 0.34, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	var frame_color = Color(0.88, 0.78, 0.42, alpha)
	var mirror_color = Color(0.76, 0.9, 1.0, alpha * 0.92)
	var gleam = 4.0 * sin(level_time * 2.6)
	draw_line(center + Vector2(-10.0 * size_scale, 12.0 * size_scale), center + Vector2(-12.0 * size_scale, 34.0 * size_scale), Color(0.22, 0.52, 0.16, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(2.0 * size_scale, 14.0 * size_scale), center + Vector2(4.0 * size_scale, 34.0 * size_scale), Color(0.22, 0.52, 0.16, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(-4.0 * size_scale, 8.0 * size_scale), center + Vector2(12.0 * size_scale, -20.0 * size_scale), Color(0.3, 0.62, 0.18, alpha), 3.4 * size_scale)
	draw_rect(Rect2(center + Vector2(8.0 * size_scale, -30.0 * size_scale), Vector2(28.0 * size_scale, 34.0 * size_scale)), frame_color, true)
	draw_rect(Rect2(center + Vector2(11.0 * size_scale, -27.0 * size_scale), Vector2(22.0 * size_scale, 28.0 * size_scale)), mirror_color, true)
	draw_line(center + Vector2((14.0 + gleam) * size_scale, -24.0 * size_scale), center + Vector2((30.0 + gleam) * size_scale, -8.0 * size_scale), Color(1.0, 1.0, 1.0, alpha * 0.7), 2.0 * size_scale)
	draw_circle(center + Vector2(-10.0 * size_scale, 0.0), 10.0 * size_scale, reed_green)
	draw_circle(center + Vector2(0.0, -10.0 * size_scale), 9.0 * size_scale, Color(0.64, 0.86, 0.5, alpha))
	draw_circle(center + Vector2(-14.0 * size_scale, -2.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-6.0 * size_scale, -4.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_arc(center + Vector2(22.0 * size_scale, -12.0 * size_scale), 18.0 * size_scale, -0.9, 0.9, 18, Color(0.92, 1.0, 1.0, alpha * 0.32), 1.6 * size_scale)


func _draw_frost_fan(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var fan_white = Color(0.9, 0.98, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	var fan_blue = Color(0.62, 0.84, 1.0, alpha)
	var handle = Color(0.4, 0.66, 0.34, alpha)
	var gust = sin(level_time * 4.2 + center.x * 0.01) * 2.4
	draw_line(center + Vector2(-8.0 * size_scale, 14.0 * size_scale), center + Vector2(-12.0 * size_scale, 34.0 * size_scale), handle, 5.0 * size_scale)
	draw_circle(center + Vector2(-14.0 * size_scale, -2.0 * size_scale), 11.0 * size_scale, Color(0.54, 0.82, 0.44, alpha))
	draw_circle(center + Vector2(-8.0 * size_scale, -4.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-16.0 * size_scale, -2.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	var fan_origin = center + Vector2(-2.0 * size_scale, 8.0 * size_scale)
	for rib in range(5):
		var angle = -1.45 + float(rib) * 0.42
		var tip = fan_origin + Vector2(cos(angle), sin(angle)) * (32.0 + gust + rib * 2.0) * size_scale
		draw_line(fan_origin, tip, Color(0.68, 0.86, 1.0, alpha * 0.9), 2.0 * size_scale)
	draw_polygon(
		PackedVector2Array([
			fan_origin + Vector2(-6.0 * size_scale, -34.0 * size_scale),
			fan_origin + Vector2(26.0 * size_scale, -22.0 * size_scale),
			fan_origin + Vector2(34.0 * size_scale, 2.0 * size_scale),
			fan_origin + Vector2(-2.0 * size_scale, 12.0 * size_scale),
		]),
		PackedColorArray([fan_white, fan_blue, fan_blue.darkened(0.08), fan_white])
	)
	draw_arc(fan_origin + Vector2(10.0 * size_scale, -10.0 * size_scale), 26.0 * size_scale, -1.45, 0.2, 24, Color(1.0, 1.0, 1.0, alpha * 0.42), 1.8 * size_scale)
	for snow in range(3):
		var flake = center + Vector2((18.0 + snow * 10.0) * size_scale, (-20.0 + snow * 8.0 + sin(level_time * 2.4 + snow) * 4.0) * size_scale)
		draw_line(flake + Vector2(-3.0 * size_scale, 0.0), flake + Vector2(3.0 * size_scale, 0.0), Color(0.92, 0.98, 1.0, alpha * 0.8), 1.2 * size_scale)
		draw_line(flake + Vector2(0.0, -3.0 * size_scale), flake + Vector2(0.0, 3.0 * size_scale), Color(0.92, 0.98, 1.0, alpha * 0.8), 1.2 * size_scale)


func _draw_tangle_kelp(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	for index in range(4):
		var x_offset = -14.0 + float(index) * 9.0
		draw_line(
			center + Vector2(x_offset * size_scale, 28.0 * size_scale),
			center + Vector2((x_offset + sin(ui_time * 2.0 + float(index)) * 4.0) * size_scale, (-8.0 - float(index % 2) * 10.0) * size_scale),
			Color(0.16, 0.54, 0.32, alpha),
			4.0 * size_scale
		)
	draw_circle(center + Vector2(-6.0 * size_scale, 12.0 * size_scale), 8.0 * size_scale, Color(0.24, 0.66, 0.38, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4))
	draw_circle(center + Vector2(8.0 * size_scale, 8.0 * size_scale), 7.0 * size_scale, Color(0.22, 0.58, 0.34, alpha))


func _draw_jalapeno(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 32.0 * size_scale), Color(0.26, 0.56, 0.16, alpha), 5.0 * size_scale)
	draw_circle(center + Vector2(0.0, 2.0 * size_scale), 18.0 * size_scale, Color(0.96, 0.22, 0.12, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8))
	draw_circle(center + Vector2(10.0 * size_scale, -10.0 * size_scale), 12.0 * size_scale, Color(0.9, 0.14, 0.1, alpha))
	draw_circle(center + Vector2(14.0 * size_scale, -18.0 * size_scale), 7.0 * size_scale, Color(0.98, 0.48, 0.18, alpha))
	draw_line(center + Vector2(-6.0 * size_scale, -16.0 * size_scale), center + Vector2(2.0 * size_scale, -28.0 * size_scale), Color(0.24, 0.62, 0.18, alpha), 3.0 * size_scale)


func _draw_spikeweed(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	for index in range(6):
		var x_offset = -20.0 + float(index) * 8.0
		draw_polygon(
			PackedVector2Array([
				center + Vector2(x_offset * size_scale, 18.0 * size_scale),
				center + Vector2((x_offset + 4.0) * size_scale, (-2.0 - float(index % 2) * 8.0) * size_scale),
				center + Vector2((x_offset + 8.0) * size_scale, 18.0 * size_scale),
			]),
			PackedColorArray([
				Color(0.58, 0.46, 0.14, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.2),
				Color(0.46, 0.34, 0.1, alpha),
				Color(0.58, 0.46, 0.14, alpha),
			])
		)


func _draw_torchwood(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_rect(Rect2(center + Vector2(-16.0 * size_scale, -4.0 * size_scale), Vector2(32.0 * size_scale, 28.0 * size_scale)), Color(0.54, 0.28, 0.12, alpha), true)
	draw_rect(Rect2(center + Vector2(-10.0 * size_scale, -20.0 * size_scale), Vector2(20.0 * size_scale, 16.0 * size_scale)), Color(0.34, 0.18, 0.08, alpha), true)
	draw_circle(center + Vector2(0.0, -20.0 * size_scale), 10.0 * size_scale, Color(1.0, 0.72, 0.2, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4))
	draw_circle(center + Vector2(0.0, -26.0 * size_scale), 8.0 * size_scale, Color(1.0, 0.42, 0.14, alpha))
	draw_line(center + Vector2(0.0, 24.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.26, 0.5, 0.16, alpha), 5.0 * size_scale)


func _draw_tallnut(center: Vector2, size_scale: float, flash: float, ratio: float, alpha: float = 1.0) -> void:
	var shell_color = Color(0.64, 0.42, 0.2, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	draw_rect(Rect2(center + Vector2(-24.0 * size_scale, -24.0 * size_scale), Vector2(48.0 * size_scale, 62.0 * size_scale)), shell_color, true)
	draw_arc(center + Vector2(0.0, -24.0 * size_scale), 24.0 * size_scale, PI, TAU, 18, shell_color, 48.0 * size_scale)
	draw_circle(center + Vector2(-8.0 * size_scale, -2.0 * size_scale), 3.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(8.0 * size_scale, -2.0 * size_scale), 3.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_arc(center + Vector2(0.0, 14.0 * size_scale), 7.0 * size_scale, 0.15, PI - 0.15, 12, Color(0.08, 0.08, 0.08, alpha), 2.0 * size_scale)
	if ratio < 0.7:
		draw_line(center + Vector2(-6.0 * size_scale, -10.0 * size_scale), center + Vector2(4.0 * size_scale, 12.0 * size_scale), Color(0.34, 0.18, 0.08, alpha), 2.0 * size_scale)
	if ratio < 0.4:
		draw_line(center + Vector2(12.0 * size_scale, -4.0 * size_scale), center + Vector2(-4.0 * size_scale, 20.0 * size_scale), Color(0.34, 0.18, 0.08, alpha), 2.0 * size_scale)


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


func _draw_zombie_icon(kind: String, center: Vector2, size_scale: float) -> void:
	draw_set_transform(center, 0.0, Vector2(size_scale, size_scale))
	_draw_zombie(
		Vector2.ZERO,
		{
			"kind": kind,
			"flash": 0.0,
			"slow_timer": 0.0,
			"has_vaulted": true,
			"jumping": false,
			"reflect_timer": 0.0,
			"plant_food_carrier": false,
		}
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _prepare_boss_frame_image(image: Image, face_left: bool = false) -> Image:
	var prepared = image.duplicate()
	prepared.convert(Image.FORMAT_RGBA8)
	var width = prepared.get_width()
	var height = prepared.get_height()
	var opaque_points: Array = []
	for y in range(height):
		for x in range(width):
			var pixel = prepared.get_pixel(x, y)
			var is_background = pixel.a <= 0.05 or (pixel.r > 0.93 and pixel.g > 0.93 and pixel.b > 0.93)
			if is_background:
				prepared.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.0))
				continue
			opaque_points.append(Vector2i(x, y))
	if opaque_points.is_empty():
		if face_left:
			prepared.flip_x()
		return prepared
	var opaque_lookup := {}
	for point_variant in opaque_points:
		var point = Vector2i(point_variant)
		opaque_lookup[Vector2i(point.x, point.y)] = true
	var visited := {}
	var component_cells: Array = []
	var largest_component: Array = []
	var queue: Array = []
	var directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	for point_variant in opaque_points:
		var start = Vector2i(point_variant)
		if visited.has(start):
			continue
		component_cells.clear()
		queue.clear()
		queue.append(start)
		visited[start] = true
		while not queue.is_empty():
			var current = Vector2i(queue.pop_back())
			component_cells.append(current)
			for dir_variant in directions:
				var dir = Vector2i(dir_variant)
				var next = current + dir
				if next.x < 0 or next.x >= width or next.y < 0 or next.y >= height:
					continue
				if not opaque_lookup.has(next) or visited.has(next):
					continue
				visited[next] = true
				queue.append(next)
		if component_cells.size() > largest_component.size():
			largest_component = component_cells.duplicate()
	if largest_component.is_empty():
		if face_left:
			prepared.flip_x()
		return prepared
	var keep_lookup := {}
	var min_x = width
	var min_y = height
	var max_x = 0
	var max_y = 0
	for point_variant in largest_component:
		var point = Vector2i(point_variant)
		keep_lookup[Vector2i(point.x, point.y)] = true
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	for y in range(height):
		for x in range(width):
			var key = Vector2i(x, y)
			if keep_lookup.has(key):
				continue
			var pixel = prepared.get_pixel(x, y)
			prepared.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, 0.0))
	var cropped = Image.create(max_x - min_x + 1, max_y - min_y + 1, false, Image.FORMAT_RGBA8)
	cropped.blit_rect(prepared, Rect2i(min_x, min_y, cropped.get_width(), cropped.get_height()), Vector2i.ZERO)
	if face_left:
		cropped.flip_x()
	return cropped


func _boss_frames_face_left(kind: String) -> bool:
	return kind == "rumia_boss" or kind == "daiyousei_boss" or kind == "cirno_boss"


func _load_boss_frame_set(folder: String, frame_count: int, face_left: bool = false) -> Array:
	var frames: Array = []
	for frame_index in range(frame_count):
		var image = Image.new()
		var path = ProjectSettings.globalize_path("%s/frame_%02d.png" % [folder, frame_index])
		if image.load(path) != OK:
			frames.append(null)
			continue
		frames.append(ImageTexture.create_from_image(_prepare_boss_frame_image(image, face_left)))
	return frames


func _boss_frame_cache_matches(frames: Array, expected_count: int, expected_face_left: bool, cached_face_left) -> bool:
	return frames.size() == expected_count and cached_face_left != null and bool(cached_face_left) == expected_face_left


func _ensure_rumia_frames_loaded() -> void:
	var expected_face_left = _boss_frames_face_left("rumia_boss")
	if rumia_frames_loaded and _boss_frame_cache_matches(rumia_frames, RUMIA_FRAME_COUNT, expected_face_left, rumia_frames_face_left):
		return
	if shared_rumia_frames_loaded and _boss_frame_cache_matches(shared_rumia_frames, RUMIA_FRAME_COUNT, expected_face_left, shared_rumia_frames_face_left):
		rumia_frames_loaded = true
		rumia_frames = shared_rumia_frames
		rumia_frames_face_left = shared_rumia_frames_face_left
		return
	rumia_frames_loaded = true
	rumia_frames = _load_boss_frame_set("res://art/rumia", RUMIA_FRAME_COUNT, expected_face_left)
	rumia_frames_face_left = expected_face_left
	shared_rumia_frames_loaded = true
	shared_rumia_frames = rumia_frames
	shared_rumia_frames_face_left = expected_face_left


func _ensure_daiyousei_frames_loaded() -> void:
	var expected_face_left = _boss_frames_face_left("daiyousei_boss")
	if daiyousei_frames_loaded and _boss_frame_cache_matches(daiyousei_frames, DAIYOUSEI_FRAME_COUNT, expected_face_left, daiyousei_frames_face_left):
		return
	if shared_daiyousei_frames_loaded and _boss_frame_cache_matches(shared_daiyousei_frames, DAIYOUSEI_FRAME_COUNT, expected_face_left, shared_daiyousei_frames_face_left):
		daiyousei_frames_loaded = true
		daiyousei_frames = shared_daiyousei_frames
		daiyousei_frames_face_left = shared_daiyousei_frames_face_left
		return
	daiyousei_frames_loaded = true
	daiyousei_frames = _load_boss_frame_set("res://art/daiyousei", DAIYOUSEI_FRAME_COUNT, expected_face_left)
	daiyousei_frames_face_left = expected_face_left
	shared_daiyousei_frames_loaded = true
	shared_daiyousei_frames = daiyousei_frames
	shared_daiyousei_frames_face_left = expected_face_left


func _ensure_cirno_frames_loaded() -> void:
	var expected_face_left = _boss_frames_face_left("cirno_boss")
	if cirno_frames_loaded and _boss_frame_cache_matches(cirno_frames, CIRNO_FRAME_COUNT, expected_face_left, cirno_frames_face_left):
		return
	if shared_cirno_frames_loaded and _boss_frame_cache_matches(shared_cirno_frames, CIRNO_FRAME_COUNT, expected_face_left, shared_cirno_frames_face_left):
		cirno_frames_loaded = true
		cirno_frames = shared_cirno_frames
		cirno_frames_face_left = shared_cirno_frames_face_left
		return
	cirno_frames_loaded = true
	cirno_frames = _load_boss_frame_set("res://art/cirno", CIRNO_FRAME_COUNT, expected_face_left)
	cirno_frames_face_left = expected_face_left
	shared_cirno_frames_loaded = true
	shared_cirno_frames = cirno_frames
	shared_cirno_frames_face_left = expected_face_left


func _rumia_draw_scale(phase: int) -> float:
	return 0.25 + float(phase) * 0.016


func _daiyousei_draw_scale(phase: int) -> float:
	return 0.24 + float(phase) * 0.012


func _cirno_draw_scale(phase: int) -> float:
	return 0.26 + float(phase) * 0.014


func _rumia_cycle_frame(frames: Array, speed: float, phase: float) -> int:
	if frames.is_empty():
		return 0
	return int(frames[int(floor(level_time * speed + phase)) % frames.size()])


func _rumia_frame_index(zombie: Dictionary) -> int:
	var state = String(zombie.get("rumia_state", "idle"))
	var phase = float(zombie.get("anim_phase", 0.0))
	match state:
		"summon":
			return _rumia_cycle_frame([5, 6, 5, 3], 7.8, phase * 0.65)
		"beam":
			return _rumia_cycle_frame([2, 6, 2, 4], 8.6, phase * 0.45)
		"bird":
			return _rumia_cycle_frame([3, 4, 1, 4], 7.0, phase * 0.5)
		"dark":
			return _rumia_cycle_frame([7, 6, 5, 6], 8.8, phase * 0.75)
		"phase":
			return _rumia_cycle_frame([4, 6, 5, 6, 4], 9.4, phase * 0.8)
		"shift":
			return _rumia_cycle_frame([1, 4, 3, 4], 5.1, phase * 0.3)
		_:
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				return _rumia_cycle_frame([1, 4, 1], 6.2, phase * 0.3)
			return 0
	return 0


func _daiyousei_frame_index(zombie: Dictionary) -> int:
	var state = String(zombie.get("rumia_state", "idle"))
	var phase = float(zombie.get("anim_phase", 0.0))
	match state:
		"summon":
			return _rumia_cycle_frame([5, 6, 5, 7], 7.2, phase * 0.62)
		"ring":
			return _rumia_cycle_frame([4, 5, 6, 5], 6.8, phase * 0.46)
		"lance":
			return _rumia_cycle_frame([2, 3, 4, 3], 7.8, phase * 0.52)
		"phase":
			return _rumia_cycle_frame([6, 7, 6, 5], 7.0, phase * 0.48)
		"shift":
			return _rumia_cycle_frame([1, 3, 2, 3], 5.4, phase * 0.32)
		_:
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				return _rumia_cycle_frame([1, 2, 1], 5.8, phase * 0.28)
			return 0
	return 0


func _cirno_frame_index(zombie: Dictionary) -> int:
	var state = String(zombie.get("rumia_state", "idle"))
	var phase = float(zombie.get("anim_phase", 0.0))
	match state:
		"icicle":
			return _rumia_cycle_frame([2, 4, 2, 5], 8.0, phase * 0.52)
		"freeze":
			return _rumia_cycle_frame([6, 7, 6, 5], 7.2, phase * 0.6)
		"blizzard":
			return _rumia_cycle_frame([4, 6, 5, 6], 7.6, phase * 0.54)
		"phase":
			return _rumia_cycle_frame([5, 6, 7, 6], 7.0, phase * 0.44)
		"shift":
			return _rumia_cycle_frame([1, 3, 2, 3], 5.2, phase * 0.3)
		_:
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				return _rumia_cycle_frame([1, 2, 1], 6.0, phase * 0.3)
			return 0
	return 0


func _draw_rumia_boss(center: Vector2, zombie: Dictionary) -> void:
	_ensure_rumia_frames_loaded()
	var frame_index = _rumia_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 4
	var texture: Texture2D = rumia_frames[frame_index] if frame_index < rumia_frames.size() else null
	var draw_scale = _rumia_draw_scale(int(zombie.get("boss_phase", 0)))
	var local_phase = float(zombie.get("anim_phase", 0.0))
	var bob = sin(level_time * 2.9 + local_phase) * 5.4 + sin(level_time * 6.4 + local_phase * 0.7) * 1.4
	var sway = sin(level_time * 1.5 + local_phase) * 9.0
	var aura_alpha = 0.07 + 0.024 * sin(level_time * 2.2 + local_phase)
	var aura_center = center + Vector2(sway * 0.06, -30.0 + bob * 0.18)
	draw_circle(center + Vector2(sway * 0.04, 56.0), 24.0, Color(0.08, 0.0, 0.02, 0.12))
	draw_circle(center + Vector2(sway * 0.04, 56.0), 15.0, Color(0.16, 0.0, 0.04, 0.1))
	draw_circle(aura_center, 40.0, Color(0.88, 0.04, 0.14, aura_alpha))
	draw_circle(aura_center, 26.0, Color(0.16, 0.0, 0.04, 0.08))
	if texture != null:
		var texture_size = texture.get_size() * draw_scale
		var top_left = center + Vector2(-texture_size.x * 0.5 + sway * 0.06, -texture_size.y * 0.86 + bob)
		draw_texture_rect(texture, Rect2(top_left, texture_size), false, Color(1.0, 1.0, 1.0, 1.0 - float(zombie.get("flash", 0.0)) * 0.25))
	else:
		draw_circle(center + Vector2(0.0, -40.0), 28.0, Color(0.94, 0.84, 0.5))
		draw_rect(Rect2(center + Vector2(-24.0, -16.0), Vector2(48.0, 68.0)), Color(0.08, 0.04, 0.08), true)
	for orb_index in range(3):
		var angle = level_time * 2.4 + float(orb_index) * TAU / 3.0 + local_phase * 0.2
		var orb_center = center + Vector2(cos(angle) * 30.0, -32.0 + sin(angle) * 12.0 + bob * 0.18)
		draw_circle(orb_center, 5.0, Color(0.92, 0.08, 0.16, 0.82))
		draw_circle(orb_center, 9.0, Color(0.18, 0.0, 0.04, 0.3))


func _draw_daiyousei_boss(center: Vector2, zombie: Dictionary) -> void:
	_ensure_daiyousei_frames_loaded()
	var frame_index = _daiyousei_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 4
	var texture: Texture2D = daiyousei_frames[frame_index] if frame_index < daiyousei_frames.size() else null
	var draw_scale = _daiyousei_draw_scale(int(zombie.get("boss_phase", 0)))
	var local_phase = float(zombie.get("anim_phase", 0.0))
	var bob = sin(level_time * 2.6 + local_phase) * 5.0 + sin(level_time * 5.4 + local_phase * 0.8) * 1.2
	var sway = sin(level_time * 1.4 + local_phase) * 7.0
	var aura_center = center + Vector2(sway * 0.05, -28.0 + bob * 0.2)
	draw_circle(center + Vector2(sway * 0.04, 52.0), 20.0, Color(0.06, 0.14, 0.08, 0.1))
	draw_circle(aura_center, 36.0, Color(0.4, 0.96, 0.72, 0.09 + 0.03 * sin(level_time * 2.2 + local_phase)))
	draw_circle(aura_center, 24.0, Color(0.18, 0.42, 0.28, 0.08))
	if texture != null:
		var texture_size = texture.get_size() * draw_scale
		var top_left = center + Vector2(-texture_size.x * 0.5 + sway * 0.05, -texture_size.y * 0.84 + bob)
		draw_texture_rect(texture, Rect2(top_left, texture_size), false, Color(1.0, 1.0, 1.0, 1.0 - float(zombie.get("flash", 0.0)) * 0.25))
	else:
		draw_circle(center + Vector2(0.0, -36.0), 24.0, Color(0.74, 0.96, 0.72))
		draw_rect(Rect2(center + Vector2(-20.0, -12.0), Vector2(40.0, 62.0)), Color(0.26, 0.58, 0.34), true)
	for mote_index in range(4):
		var angle = level_time * 1.8 + float(mote_index) * TAU / 4.0 + local_phase * 0.16
		var mote_center = center + Vector2(cos(angle) * 24.0, -20.0 + sin(angle) * 10.0 + bob * 0.18)
		draw_circle(mote_center, 4.5, Color(0.92, 1.0, 0.94, 0.78))
		draw_circle(mote_center, 8.0, Color(0.42, 0.98, 0.76, 0.22))


func _draw_cirno_boss(center: Vector2, zombie: Dictionary) -> void:
	_ensure_cirno_frames_loaded()
	var frame_index = _cirno_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 5
	var texture: Texture2D = cirno_frames[frame_index] if frame_index < cirno_frames.size() else null
	var draw_scale = _cirno_draw_scale(int(zombie.get("boss_phase", 0)))
	var local_phase = float(zombie.get("anim_phase", 0.0))
	var bob = sin(level_time * 2.8 + local_phase) * 6.0 + sin(level_time * 6.1 + local_phase * 0.7) * 1.4
	var sway = sin(level_time * 1.6 + local_phase) * 8.0
	var aura_center = center + Vector2(sway * 0.05, -34.0 + bob * 0.18)
	draw_circle(center + Vector2(sway * 0.04, 54.0), 22.0, Color(0.08, 0.14, 0.2, 0.12))
	draw_circle(aura_center, 40.0, Color(0.74, 0.94, 1.0, 0.1 + 0.03 * sin(level_time * 2.4 + local_phase)))
	draw_circle(aura_center, 26.0, Color(0.22, 0.44, 0.74, 0.08))
	if texture != null:
		var texture_size = texture.get_size() * draw_scale
		var top_left = center + Vector2(-texture_size.x * 0.5 + sway * 0.04, -texture_size.y * 0.84 + bob)
		draw_texture_rect(texture, Rect2(top_left, texture_size), false, Color(1.0, 1.0, 1.0, 1.0 - float(zombie.get("flash", 0.0)) * 0.25))
	else:
		draw_circle(center + Vector2(0.0, -38.0), 26.0, Color(0.78, 0.92, 1.0))
		draw_rect(Rect2(center + Vector2(-22.0, -12.0), Vector2(44.0, 66.0)), Color(0.38, 0.7, 0.94), true)
	for shard_index in range(5):
		var angle = level_time * 2.1 + float(shard_index) * TAU / 5.0 + local_phase * 0.18
		var shard_center = center + Vector2(cos(angle) * 28.0, -24.0 + sin(angle) * 12.0 + bob * 0.16)
		draw_polygon(
			PackedVector2Array([
				shard_center + Vector2(0.0, -6.0),
				shard_center + Vector2(5.0, 0.0),
				shard_center + Vector2(0.0, 6.0),
				shard_center + Vector2(-5.0, 0.0),
			]),
			PackedColorArray([
				Color(0.98, 1.0, 1.0, 0.84),
				Color(0.72, 0.94, 1.0, 0.74),
				Color(0.72, 0.94, 1.0, 0.66),
				Color(0.72, 0.94, 1.0, 0.74),
			])
		)


func _draw_dragon_boat_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var move_ratio = clampf(float(zombie.get("boat_move_t", 1.0)), 0.0, 1.0)
	var stroke_curve = sin(move_ratio * PI)
	var stroke_dir = 1.0 if int(zombie.get("boat_phase", 0)) == 0 else -1.0
	var bob = sin(level_time * 3.2 + float(zombie.get("anim_phase", 0.0))) * 1.8 + stroke_curve * 3.4
	var boat = center + Vector2(0.0, 12.0 + bob)
	var boat_tilt = stroke_dir * stroke_curve * 0.12
	var oar_swing = stroke_dir * stroke_curve * 18.0
	draw_circle(boat + Vector2(0.0, 28.0), 26.0, Color(0.0, 0.18, 0.28, 0.12))
	draw_set_transform(boat, boat_tilt, Vector2.ONE)
	draw_polygon(
		PackedVector2Array([
			Vector2(-54.0, 6.0),
			Vector2(-18.0, -12.0),
			Vector2(44.0, -8.0),
			Vector2(62.0, 4.0),
			Vector2(40.0, 16.0),
			Vector2(-42.0, 18.0),
		]),
		PackedColorArray([
			Color(0.54, 0.2, 0.08),
			Color(0.68, 0.28, 0.12),
			Color(0.74, 0.34, 0.14),
			Color(0.64, 0.24, 0.1),
			Color(0.58, 0.2, 0.08),
			Color(0.52, 0.18, 0.08),
		])
	)
	for seat in range(3):
		var rider = Vector2(-26.0 + float(seat) * 22.0, -18.0 + sin(level_time * 4.2 + float(seat) * 0.6) * 1.2 + stroke_curve * (1.8 - seat * 0.35))
		draw_circle(rider, 11.0, Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 2.0))
		draw_rect(Rect2(rider + Vector2(-10.0, 8.0), Vector2(20.0, 18.0)), Color(0.34, 0.46, 0.72), true)
		var paddle_base = rider + Vector2(10.0, 6.0)
		draw_line(paddle_base, paddle_base + Vector2(10.0 + oar_swing * 0.3, 18.0 - stroke_curve * 8.0), Color(0.62, 0.44, 0.18), 2.0)
	draw_line(Vector2(36.0, -10.0), Vector2(60.0, -32.0), Color(0.96, 0.76, 0.22), 3.0)
	draw_line(Vector2(60.0, -32.0), Vector2(76.0, -26.0), Color(0.96, 0.34, 0.18), 3.0)
	draw_line(Vector2(-14.0, -8.0), Vector2(-32.0 - oar_swing * 0.28, 22.0 - stroke_curve * 6.0), Color(0.68, 0.48, 0.18), 3.0)
	draw_line(Vector2(8.0, -12.0), Vector2(-10.0 - oar_swing * 0.22, 18.0 - stroke_curve * 7.0), Color(0.68, 0.48, 0.18), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_qinghua_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var slow_tint = 0.55 if float(zombie.get("slow_timer", 0.0)) > 0.0 else 0.0
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 2.0).lerp(Color(0.64, 0.84, 1.0), slow_tint)
	var torso = center + Vector2(0.0, -absf(sin(level_time * 2.6 + float(zombie.get("anim_phase", 0.0)))) * 2.2)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -10.0), Vector2(32.0, 38.0)), Color(0.24, 0.4, 0.62), true)
	draw_circle(torso + Vector2(0.0, -28.0), 17.0, skin)
	draw_circle(torso + Vector2(-6.0, -30.0), 2.2, Color.BLACK)
	draw_circle(torso + Vector2(6.0, -30.0), 2.2, Color.BLACK)
	if float(zombie.get("shield_health", 0.0)) > 0.0:
		draw_rect(Rect2(torso + Vector2(8.0, -18.0), Vector2(28.0, 40.0)), Color(0.94, 0.98, 1.0, 0.94), true)
		draw_arc(torso + Vector2(22.0, 2.0), 20.0, -1.0, 1.0, 18, Color(0.2, 0.42, 0.86), 3.0)
		for line in range(3):
			draw_line(torso + Vector2(12.0, -10.0 + line * 10.0), torso + Vector2(32.0, -10.0 + line * 10.0), Color(0.22, 0.42, 0.78), 1.2)
		draw_circle(torso + Vector2(22.0, 2.0), 4.0, Color(0.24, 0.56, 0.9, 0.66))
	else:
		for shard in range(4):
			var shard_center = torso + Vector2(10.0 + float(shard) * 6.0, 18.0 + sin(level_time * 4.0 + float(shard)) * 2.0)
			draw_polygon(
				PackedVector2Array([
					shard_center + Vector2(0.0, -4.0),
					shard_center + Vector2(3.0, 0.0),
					shard_center + Vector2(0.0, 4.0),
					shard_center + Vector2(-3.0, 0.0),
				]),
				PackedColorArray([Color(0.86, 0.94, 1.0, 0.82), Color(0.62, 0.82, 1.0, 0.72), Color(0.86, 0.94, 1.0, 0.82), Color(0.62, 0.82, 1.0, 0.72)])
			)


func _draw_shouyue_zombie(center: Vector2, zombie: Dictionary) -> void:
	var hidden_alpha = 0.42 if _is_hidden_from_lane_attacks(zombie) else 0.92
	var flash = float(zombie.get("flash", 0.0))
	var aim_active = bool(zombie.get("snipe_charge_active", false))
	var aim_ratio = 0.0
	var charge_duration = maxf(float(zombie.get("snipe_charge_duration", 0.16)), 0.01)
	if aim_active:
		aim_ratio = 1.0 - clampf(float(zombie.get("snipe_charge_timer", 0.0)) / charge_duration, 0.0, 1.0)
	var torso = center + Vector2(-aim_ratio * 5.0, -2.0 - absf(sin(level_time * 2.2 + float(zombie.get("anim_phase", 0.0)))) * (1.2 if aim_active else 1.8))
	var alpha = hidden_alpha - flash * 0.12
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 - aim_ratio * 3.0, 42.0), Color(0.18, 0.18, 0.2, alpha), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0, 42.0), Color(0.18, 0.18, 0.2, alpha), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 40.0)), Color(0.16, 0.26, 0.32, alpha), true)
	draw_circle(torso + Vector2(0.0, -30.0), 16.0, Color(0.72, 0.8, 0.72, alpha))
	draw_line(torso + Vector2(10.0, -6.0), torso + Vector2(34.0 + aim_ratio * 10.0, -18.0 - aim_ratio * 4.0), Color(0.22, 0.22, 0.24, alpha), 4.0)
	draw_line(torso + Vector2(34.0 + aim_ratio * 10.0, -18.0 - aim_ratio * 4.0), torso + Vector2(48.0 + aim_ratio * 16.0, -18.0 - aim_ratio * 6.0), Color(0.76, 0.88, 0.98, alpha), 2.0 + aim_ratio * 0.8)
	draw_circle(torso + Vector2(-5.0, -31.0), 2.0, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(torso + Vector2(5.0, -31.0), 2.0, Color(0.08, 0.08, 0.08, alpha))
	if float(zombie.get("revealed_timer", 0.0)) > 0.0:
		draw_circle(torso + Vector2(0.0, -20.0), 26.0, Color(0.62, 0.9, 1.0, 0.12))
	if aim_active:
		draw_circle(torso + Vector2(24.0, -20.0), 9.0 + aim_ratio * 4.0, Color(0.82, 0.96, 1.0, 0.12 + aim_ratio * 0.08))


func _draw_ice_block_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var torso = center + Vector2(0.0, -2.0 - absf(sin(level_time * 2.4 + float(zombie.get("anim_phase", 0.0)))) * 2.0)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 40.0)), Color(0.22, 0.42, 0.6), true)
	draw_circle(torso + Vector2(0.0, -30.0), 16.0, Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 2.0))
	var ice_alpha = 0.86 if float(zombie.get("shield_health", 0.0)) > 0.0 else 0.28
	draw_rect(Rect2(torso + Vector2(8.0, -36.0), Vector2(28.0, 28.0)), Color(0.76, 0.96, 1.0, ice_alpha), true)
	draw_line(torso + Vector2(12.0, -28.0), torso + Vector2(30.0, -18.0), Color(1.0, 1.0, 1.0, ice_alpha * 0.6), 2.0)
	draw_line(torso + Vector2(14.0, -12.0), torso + Vector2(28.0, -30.0), Color(0.64, 0.9, 1.0, ice_alpha * 0.6), 2.0)


func _draw_dragon_dance_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var phase = level_time * 4.0 + float(zombie.get("anim_phase", 0.0))
	var torso = center + Vector2(0.0, -absf(sin(phase * 0.5)) * 2.0)
	for segment in range(4):
		var segment_center = torso + Vector2(-18.0 + float(segment) * 16.0, -10.0 + sin(phase + float(segment) * 0.7) * 5.0)
		draw_circle(segment_center, 11.0 - float(segment), Color(0.92, 0.12, 0.08, 0.9))
		draw_circle(segment_center, 6.0 - float(segment) * 0.4, Color(0.98, 0.74, 0.16, 0.82))
	draw_rect(Rect2(torso + Vector2(-12.0, 4.0), Vector2(26.0, 28.0)), Color(0.54, 0.12, 0.08).lerp(Color(1.0, 1.0, 1.0), flash * 1.6), true)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_circle(torso + Vector2(18.0, -16.0), 12.0, Color(0.98, 0.28, 0.12))
	draw_circle(torso + Vector2(22.0, -18.0), 2.4, Color.BLACK)


func _draw_pool_boss(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var phase = int(zombie.get("boss_phase", 0))
	var bob = sin(level_time * 2.2 + float(zombie.get("anim_phase", 0.0))) * 4.0
	var torso = center + Vector2(0.0, -8.0 + bob)
	draw_circle(torso + Vector2(0.0, 64.0), 28.0, Color(0.02, 0.14, 0.22, 0.16))
	draw_rect(Rect2(torso + Vector2(-34.0, -12.0), Vector2(68.0, 76.0)), Color(0.12, 0.3, 0.44).lerp(Color(1.0, 1.0, 1.0), flash * 1.4), true)
	draw_circle(torso + Vector2(0.0, -34.0), 24.0, Color(0.74, 0.82, 0.7))
	draw_rect(Rect2(torso + Vector2(-30.0, -56.0), Vector2(60.0, 18.0)), Color(0.18, 0.44, 0.62), true)
	draw_line(torso + Vector2(-18.0, 18.0), torso + Vector2(-34.0, 54.0), Color(0.2, 0.2, 0.22), 6.0)
	draw_line(torso + Vector2(18.0, 18.0), torso + Vector2(34.0, 54.0), Color(0.2, 0.2, 0.22), 6.0)
	draw_line(torso + Vector2(20.0, -10.0), torso + Vector2(52.0, -26.0), Color(0.74, 0.82, 0.9), 5.0)
	draw_line(torso + Vector2(52.0, -26.0), torso + Vector2(68.0, -8.0), Color(0.74, 0.82, 0.9), 4.0)
	draw_line(torso + Vector2(52.0, -26.0), torso + Vector2(68.0, -42.0), Color(0.74, 0.82, 0.9), 4.0)
	draw_line(torso + Vector2(52.0, -26.0), torso + Vector2(78.0, -26.0), Color(0.74, 0.82, 0.9), 4.0)
	for wave in range(3 + phase):
		var orbit = level_time * 1.7 + float(wave) * TAU / float(3 + phase)
		var orb_center = torso + Vector2(cos(orbit) * 38.0, 14.0 + sin(orbit) * 12.0)
		draw_circle(orb_center, 5.0, Color(0.72, 0.94, 1.0, 0.78))
		draw_circle(orb_center, 10.0, Color(0.12, 0.42, 0.64, 0.18))


func _draw_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie["flash"])
	var slow_tint = 0.55 if float(zombie["slow_timer"]) > 0.0 else 0.0
	var kind = String(zombie["kind"])
	if kind == "rumia_boss":
		_draw_rumia_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "daiyousei_boss":
		_draw_daiyousei_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "cirno_boss":
		_draw_cirno_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "dragon_boat":
		_draw_dragon_boat_zombie(center, zombie)
		return
	if kind == "qinghua":
		_draw_qinghua_zombie(center, zombie)
		return
	if kind == "shouyue":
		_draw_shouyue_zombie(center, zombie)
		return
	if kind == "ice_block":
		_draw_ice_block_zombie(center, zombie)
		return
	if kind == "dragon_dance":
		_draw_dragon_dance_zombie(center, zombie)
		return
	if kind == "pool_boss":
		_draw_pool_boss(center + Vector2(0.0, -6.0), zombie)
		return
	var base_speed = float(zombie.get("base_speed", Defs.ZOMBIES[kind].get("speed", 18.0)))
	if float(zombie.get("slow_timer", 0.0)) > 0.0:
		base_speed *= 0.5
	var moving = not bool(zombie.get("jumping", false)) and float(zombie.get("special_pause_timer", 0.0)) <= 0.0 and float(zombie.get("boss_pause_timer", 0.0)) <= 0.0 and float(zombie.get("weed_pause_timer", 0.0)) <= 0.0 and float(zombie.get("reflect_timer", 0.0)) <= 0.0
	var phase = float(zombie.get("anim_phase", 0.0))
	var cycle = level_time * (3.0 + base_speed * 0.08) + phase + float(zombie.get("x", 0.0)) * 0.02
	var step = sin(cycle) if moving else sin(level_time * 1.4 + phase) * 0.12
	var bite_ratio = 0.0
	if float(zombie.get("bite_timer", 0.0)) > 0.0:
		bite_ratio = sin((1.0 - clampf(float(zombie["bite_timer"]) / 0.18, 0.0, 1.0)) * PI)
	var impact_ratio = 0.0
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		impact_ratio = sin((1.0 - clampf(float(zombie["impact_timer"]) / 0.16, 0.0, 1.0)) * PI)
	var arm_swing = step * 8.0 - bite_ratio * 10.0
	var leg_swing = -step * 7.0
	var head_bob = absf(step) * 2.6
	var torso = center + Vector2(impact_ratio * 8.0, -head_bob - bite_ratio * 3.0)
	if bool(zombie.get("plant_food_carrier", false)):
		draw_circle(torso + Vector2(0.0, -24.0), 30.0, Color(0.18, 0.92, 0.26, 0.16))
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 2.0).lerp(Color(0.64, 0.84, 1.0), slow_tint)
	var shirt_base = Color(0.26, 0.39, 0.67)
	var pants_base = Color(0.22, 0.22, 0.24)
	match kind:
		"normal", "conehead", "buckethead":
			shirt_base = Color(0.42, 0.28, 0.18)
			pants_base = Color(0.2, 0.22, 0.24)
		"flag":
			shirt_base = Color(0.6, 0.16, 0.16)
			pants_base = Color(0.24, 0.24, 0.26)
		"pole_vault":
			shirt_base = Color(0.2, 0.56, 0.24)
			pants_base = Color(0.16, 0.2, 0.22)
		"newspaper":
			shirt_base = Color(0.56, 0.56, 0.6)
			pants_base = Color(0.18, 0.18, 0.2)
		"screen_door":
			shirt_base = Color(0.28, 0.44, 0.62)
			pants_base = Color(0.16, 0.16, 0.18)
		"football":
			shirt_base = Color(0.72, 0.08, 0.08)
			pants_base = Color(0.92, 0.92, 0.94)
		"dark_football":
			shirt_base = Color(0.72, 0.08, 0.08)
			pants_base = Color(0.92, 0.92, 0.94)
		"dancing":
			shirt_base = Color(0.58, 0.14, 0.52)
			pants_base = Color(0.12, 0.12, 0.16)
		"backup_dancer":
			shirt_base = Color(0.92, 0.92, 0.94)
			pants_base = Color(0.16, 0.16, 0.18)
		"ninja":
			shirt_base = Color(0.16, 0.18, 0.22)
			pants_base = Color(0.08, 0.08, 0.1)
		"basketball":
			shirt_base = Color(0.92, 0.46, 0.12)
			pants_base = Color(0.12, 0.12, 0.14)
		"ducky_tube", "lifebuoy_normal", "lifebuoy_cone", "lifebuoy_bucket":
			shirt_base = Color(0.22, 0.48, 0.82)
			pants_base = Color(0.16, 0.2, 0.24)
		"snorkel":
			shirt_base = Color(0.18, 0.52, 0.72)
			pants_base = Color(0.12, 0.22, 0.26)
		"dolphin_rider":
			shirt_base = Color(0.24, 0.66, 0.78)
			pants_base = Color(0.12, 0.2, 0.22)
		"zomboni":
			shirt_base = Color(0.5, 0.54, 0.58)
			pants_base = Color(0.18, 0.2, 0.24)
		"bobsled_team":
			shirt_base = Color(0.72, 0.84, 0.94)
			pants_base = Color(0.16, 0.18, 0.22)
		"nezha":
			shirt_base = Color(0.94, 0.26, 0.18)
			pants_base = Color(0.46, 0.22, 0.08)
		"nether":
			shirt_base = Color(0.34, 0.3, 0.52)
			pants_base = Color(0.12, 0.12, 0.18)
		"farmer":
			shirt_base = Color(0.68, 0.5, 0.22)
			pants_base = Color(0.26, 0.2, 0.14)
		"spear":
			shirt_base = Color(0.46, 0.34, 0.22)
			pants_base = Color(0.2, 0.18, 0.16)
		"kungfu":
			shirt_base = Color(0.72, 0.18, 0.12)
			pants_base = Color(0.1, 0.1, 0.12)
		"day_boss":
			shirt_base = Color(0.42, 0.18, 0.12)
			pants_base = Color(0.22, 0.14, 0.12)
		"night_boss":
			shirt_base = Color(0.18, 0.2, 0.42)
			pants_base = Color(0.08, 0.08, 0.16)
	var shirt = shirt_base.lerp(Color(1.0, 1.0, 1.0), flash * 2.0).lerp(Color(0.46, 0.64, 0.9), slow_tint)
	var pants = pants_base.lerp(Color(1.0, 1.0, 1.0), flash * 1.6).lerp(Color(0.46, 0.64, 0.9), slow_tint * 0.8)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 + leg_swing, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 - leg_swing, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -10.0), Vector2(32.0, 38.0)), shirt, true)
	draw_rect(Rect2(torso + Vector2(-15.0, 16.0), Vector2(30.0, 12.0)), pants, true)
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-24.0 - arm_swing - bite_ratio * 4.0, 8.0 + arm_swing * 0.25 - bite_ratio * 6.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, 0.0), torso + Vector2(24.0 + arm_swing + bite_ratio * 14.0, 8.0 - arm_swing * 0.25 + bite_ratio * 6.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_circle(torso + Vector2(0.0, -28.0), 17.0, skin)
	draw_circle(torso + Vector2(-6.0, -30.0), 2.4, Color.BLACK)
	draw_circle(torso + Vector2(6.0, -30.0), 2.4, Color.BLACK)
	draw_line(torso + Vector2(-3.0, -18.0), torso + Vector2(3.0, -18.0), Color(0.18, 0.18, 0.18), 2.0)

	match kind:
		"normal":
			draw_line(torso + Vector2(0.0, -10.0), torso + Vector2(0.0, 24.0), Color(0.82, 0.12, 0.12), 2.0)
			draw_line(torso + Vector2(-10.0, -42.0), torso + Vector2(4.0, -50.0), Color(0.18, 0.16, 0.12), 3.0)
		"flag":
			draw_line(torso + Vector2(0.0, -10.0), torso + Vector2(0.0, 24.0), Color(1.0, 0.94, 0.82), 2.0)
			draw_line(torso + Vector2(18.0, -8.0), torso + Vector2(18.0, -50.0), Color(0.24, 0.24, 0.24), 3.0)
			draw_polygon(
				PackedVector2Array([
					torso + Vector2(18.0, -48.0),
					torso + Vector2(42.0, -40.0),
					torso + Vector2(18.0, -28.0),
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
					torso + Vector2(0.0, -62.0),
					torso + Vector2(-16.0, -10.0),
					torso + Vector2(16.0, -10.0),
				]),
				PackedColorArray([
					Color(0.95, 0.54, 0.15),
					Color(0.95, 0.54, 0.15),
					Color(0.95, 0.54, 0.15),
				])
			)
		"buckethead":
			draw_rect(Rect2(torso + Vector2(-17.0, -54.0), Vector2(34.0, 24.0)), Color(0.62, 0.62, 0.66), true)
			draw_rect(Rect2(torso + Vector2(-20.0, -60.0), Vector2(40.0, 8.0)), Color(0.72, 0.72, 0.76), true)
		"pole_vault":
			draw_line(torso + Vector2(-10.0, -46.0), torso + Vector2(10.0, -46.0), Color(0.96, 0.96, 0.98), 4.0)
			draw_rect(Rect2(torso + Vector2(-12.0, -4.0), Vector2(24.0, 10.0)), Color(0.96, 0.96, 0.98), true)
			if not bool(zombie.get("has_vaulted", true)) or bool(zombie.get("jumping", false)):
				draw_line(torso + Vector2(-28.0, -42.0), torso + Vector2(34.0, -60.0), Color(0.54, 0.38, 0.18), 4.0)
		"newspaper":
			if float(zombie.get("shield_health", 0.0)) > 0.0:
				draw_rect(Rect2(torso + Vector2(8.0, -30.0), Vector2(24.0, 34.0)), Color(0.9, 0.9, 0.9), true)
				draw_rect(Rect2(torso + Vector2(10.0, -28.0), Vector2(20.0, 30.0)), Color(1.0, 1.0, 1.0), true)
				for line_y in range(4):
					draw_line(torso + Vector2(12.0, -22.0 + line_y * 7.0), torso + Vector2(28.0, -22.0 + line_y * 7.0), Color(0.38, 0.38, 0.38), 1.0)
			else:
				draw_line(torso + Vector2(-8.0, -38.0), torso + Vector2(-2.0, -34.0), Color(0.22, 0.12, 0.08), 3.0)
				draw_line(torso + Vector2(2.0, -38.0), torso + Vector2(8.0, -34.0), Color(0.22, 0.12, 0.08), 3.0)
				draw_arc(torso + Vector2(0.0, -18.0), 10.0, 0.0, PI, 12, Color(0.18, 0.06, 0.06), 2.0)
			draw_rect(Rect2(torso + Vector2(-14.0, -12.0), Vector2(28.0, 14.0)), Color(0.42, 0.42, 0.46), true)
		"screen_door":
			if float(zombie.get("shield_health", 0.0)) > 0.0:
				draw_rect(Rect2(torso + Vector2(8.0, -18.0), Vector2(28.0, 48.0)), Color(0.46, 0.58, 0.68, 0.92), true)
				for grid_x in range(3):
					draw_line(torso + Vector2(12.0 + grid_x * 8.0, -16.0), torso + Vector2(12.0 + grid_x * 8.0, 28.0), Color(0.82, 0.9, 0.96), 1.0)
				for grid_y in range(5):
					draw_line(torso + Vector2(10.0, -14.0 + grid_y * 10.0), torso + Vector2(34.0, -14.0 + grid_y * 10.0), Color(0.82, 0.9, 0.96), 1.0)
				draw_rect(Rect2(torso + Vector2(8.0, -18.0), Vector2(28.0, 48.0)), Color(0.28, 0.34, 0.4), false, 2.0)
			else:
				draw_line(torso + Vector2(10.0, -16.0), torso + Vector2(32.0, 26.0), Color(0.52, 0.56, 0.62), 3.0)
				draw_line(torso + Vector2(30.0, -16.0), torso + Vector2(12.0, 26.0), Color(0.52, 0.56, 0.62), 3.0)
		"football":
			draw_rect(Rect2(torso + Vector2(-22.0, -16.0), Vector2(44.0, 16.0)), Color(0.96, 0.96, 0.98), true)
			draw_rect(Rect2(torso + Vector2(-16.0, -52.0), Vector2(32.0, 22.0)), Color(0.88, 0.12, 0.12), true)
			draw_line(torso + Vector2(-10.0, -41.0), torso + Vector2(10.0, -41.0), Color(0.96, 0.96, 0.98), 3.0)
			draw_line(torso + Vector2(0.0, -48.0), torso + Vector2(0.0, -30.0), Color(0.96, 0.96, 0.98), 3.0)
		"dark_football":
			draw_rect(Rect2(torso + Vector2(-22.0, -16.0), Vector2(44.0, 16.0)), Color(0.96, 0.96, 0.98), true)
			draw_rect(Rect2(torso + Vector2(-16.0, -52.0), Vector2(32.0, 22.0)), Color(0.08, 0.08, 0.1), true)
			draw_line(torso + Vector2(-10.0, -41.0), torso + Vector2(10.0, -41.0), Color(0.42, 0.42, 0.46), 3.0)
			draw_line(torso + Vector2(0.0, -48.0), torso + Vector2(0.0, -30.0), Color(0.42, 0.42, 0.46), 3.0)
		"dancing":
			draw_circle(torso + Vector2(0.0, -42.0), 18.0, Color(0.12, 0.12, 0.12))
			draw_rect(Rect2(torso + Vector2(-18.0, -18.0), Vector2(36.0, 10.0)), Color(0.98, 0.88, 0.18), true)
			draw_line(torso + Vector2(-18.0, -4.0), torso + Vector2(-30.0, -14.0), Color(0.98, 0.88, 0.18), 3.0)
			draw_line(torso + Vector2(18.0, -4.0), torso + Vector2(30.0, -14.0), Color(0.98, 0.88, 0.18), 3.0)
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				draw_circle(torso + Vector2(0.0, -62.0), 14.0, Color(0.96, 0.24, 0.86, 0.18))
		"backup_dancer":
			draw_circle(torso + Vector2(0.0, -42.0), 15.0, Color(0.14, 0.14, 0.16))
			draw_rect(Rect2(torso + Vector2(-12.0, -10.0), Vector2(24.0, 36.0)), Color(0.94, 0.94, 0.96), true)
			draw_line(torso + Vector2(0.0, -10.0), torso + Vector2(0.0, 24.0), Color(0.16, 0.16, 0.18), 2.0)
			draw_line(torso + Vector2(-8.0, 0.0), torso + Vector2(-18.0, 10.0), Color(0.96, 0.96, 0.98), 3.0)
			draw_line(torso + Vector2(8.0, 0.0), torso + Vector2(18.0, 10.0), Color(0.96, 0.96, 0.98), 3.0)
		"ninja":
			draw_rect(Rect2(torso + Vector2(-18.0, -16.0), Vector2(36.0, 44.0)), Color(0.1, 0.12, 0.16), true)
			draw_rect(Rect2(torso + Vector2(-18.0, -52.0), Vector2(36.0, 10.0)), Color(0.04, 0.04, 0.06), true)
			draw_rect(Rect2(torso + Vector2(-12.0, -34.0), Vector2(24.0, 6.0)), Color(0.78, 0.12, 0.12), true)
			if bool(zombie.get("ninja_dashed", false)):
				draw_line(torso + Vector2(-26.0, -12.0), torso + Vector2(-40.0, -20.0), Color(0.8, 0.8, 0.88, 0.46), 3.0)
				draw_line(torso + Vector2(-18.0, 8.0), torso + Vector2(-36.0, 10.0), Color(0.8, 0.8, 0.88, 0.36), 3.0)
		"basketball":
			draw_rect(Rect2(torso + Vector2(-18.0, -16.0), Vector2(36.0, 44.0)), Color(0.96, 0.52, 0.14), true)
			draw_rect(Rect2(torso + Vector2(-14.0, -52.0), Vector2(28.0, 14.0)), Color(0.22, 0.22, 0.24), true)
			if float(zombie.get("shield_health", 0.0)) > 0.0:
				var orbit = level_time * 4.6 + phase
				for orb_index in range(2):
					var angle = orbit + float(orb_index) * PI
					var orb_center = torso + Vector2(cos(angle) * 18.0, -6.0 + sin(angle) * 12.0)
					draw_circle(orb_center, 9.0, Color(0.92, 0.54, 0.16))
					draw_arc(orb_center, 7.0, 0.0, TAU, 12, Color(0.24, 0.16, 0.08), 1.0)
		"ducky_tube", "lifebuoy_normal", "lifebuoy_cone", "lifebuoy_bucket":
			var ring_color = Color(0.98, 0.84, 0.22, 0.92)
			if kind == "lifebuoy_cone":
				ring_color = Color(0.98, 0.72, 0.18, 0.94)
			elif kind == "lifebuoy_bucket":
				ring_color = Color(0.78, 0.82, 0.9, 0.94)
			draw_circle(torso + Vector2(0.0, 14.0), 18.0, ring_color)
			draw_circle(torso + Vector2(0.0, 14.0), 10.0, Color(0.18, 0.36, 0.52, 0.9))
			draw_rect(Rect2(torso + Vector2(-10.0, -44.0), Vector2(20.0, 6.0)), Color(0.18, 0.18, 0.22), true)
			draw_circle(torso + Vector2(-6.0, -41.0), 4.0, Color(0.62, 0.88, 0.96))
			draw_circle(torso + Vector2(6.0, -41.0), 4.0, Color(0.62, 0.88, 0.96))
			if kind == "lifebuoy_cone":
				draw_polygon(
					PackedVector2Array([
						torso + Vector2(0.0, -62.0),
						torso + Vector2(-16.0, -10.0),
						torso + Vector2(16.0, -10.0),
					]),
					PackedColorArray([
						Color(0.95, 0.54, 0.15),
						Color(0.95, 0.54, 0.15),
						Color(0.95, 0.54, 0.15),
					])
				)
			elif kind == "lifebuoy_bucket":
				draw_rect(Rect2(torso + Vector2(-17.0, -54.0), Vector2(34.0, 24.0)), Color(0.62, 0.62, 0.66), true)
				draw_rect(Rect2(torso + Vector2(-20.0, -60.0), Vector2(40.0, 8.0)), Color(0.72, 0.72, 0.76), true)
		"snorkel":
			if bool(zombie.get("submerged", false)):
				draw_rect(Rect2(torso + Vector2(-26.0, -4.0), Vector2(52.0, 32.0)), Color(0.16, 0.52, 0.76, 0.22), true)
			draw_rect(Rect2(torso + Vector2(-10.0, -42.0), Vector2(20.0, 8.0)), Color(0.16, 0.2, 0.24), true)
			draw_line(torso + Vector2(8.0, -42.0), torso + Vector2(18.0, -62.0), Color(0.94, 0.76, 0.18), 3.0)
			draw_line(torso + Vector2(18.0, -62.0), torso + Vector2(10.0, -70.0), Color(0.94, 0.76, 0.18), 3.0)
		"dolphin_rider":
			draw_circle(torso + Vector2(0.0, -48.0), 13.0, Color(0.18, 0.64, 0.8))
			draw_arc(torso + Vector2(0.0, -58.0), 8.0, PI, TAU, 10, Color(0.92, 0.94, 0.98), 3.0)
			if not bool(zombie.get("has_vaulted", true)) or bool(zombie.get("jumping", false)):
				draw_circle(torso + Vector2(2.0, 28.0), 16.0, Color(0.54, 0.82, 0.94))
				draw_circle(torso + Vector2(18.0, 26.0), 10.0, Color(0.54, 0.82, 0.94))
				draw_polygon(
					PackedVector2Array([
						torso + Vector2(-10.0, 18.0),
						torso + Vector2(-24.0, 6.0),
						torso + Vector2(-18.0, 24.0),
					]),
					PackedColorArray([Color(0.4, 0.72, 0.88), Color(0.4, 0.72, 0.88), Color(0.4, 0.72, 0.88)])
				)
			else:
				draw_line(torso + Vector2(-8.0, 18.0), torso + Vector2(-20.0, 28.0), Color(0.72, 0.82, 0.88), 3.0)
		"zomboni":
			draw_rect(Rect2(torso + Vector2(-34.0, -8.0), Vector2(68.0, 34.0)), Color(0.58, 0.64, 0.7), true)
			draw_rect(Rect2(torso + Vector2(-18.0, -28.0), Vector2(36.0, 18.0)), Color(0.82, 0.86, 0.9), true)
			draw_rect(Rect2(torso + Vector2(-38.0, 18.0), Vector2(76.0, 10.0)), Color(0.16, 0.2, 0.24), true)
			draw_rect(Rect2(torso + Vector2(10.0, -18.0), Vector2(16.0, 10.0)), Color(0.24, 0.42, 0.58), true)
			draw_circle(torso + Vector2(22.0, -22.0), 7.0, Color(0.74, 0.82, 0.7))
			draw_rect(Rect2(torso + Vector2(-40.0, 26.0), Vector2(80.0, 6.0)), Color(0.86, 0.96, 1.0, 0.4), true)
		"bobsled_team":
			draw_rect(Rect2(torso + Vector2(-34.0, 12.0), Vector2(68.0, 14.0)), Color(0.56, 0.7, 0.82), true)
			for rider_index in range(4):
				var rider_offset = -24.0 + float(rider_index) * 16.0
				draw_circle(torso + Vector2(rider_offset, -34.0), 10.0, skin)
				draw_rect(Rect2(torso + Vector2(rider_offset - 8.0, -18.0), Vector2(16.0, 18.0)), Color(0.68, 0.82, 0.94), true)
				draw_rect(Rect2(torso + Vector2(rider_offset - 8.0, -44.0), Vector2(16.0, 6.0)), Color(0.18, 0.24, 0.34), true)
		"nezha":
			draw_rect(Rect2(torso + Vector2(-18.0, -16.0), Vector2(36.0, 42.0)), Color(0.98, 0.26, 0.18), true)
			draw_rect(Rect2(torso + Vector2(-14.0, -52.0), Vector2(28.0, 12.0)), Color(0.94, 0.78, 0.24), true)
			draw_arc(torso + Vector2(0.0, -52.0), 12.0, PI, TAU, 12, Color(1.0, 0.84, 0.28), 3.0)
			draw_circle(torso + Vector2(-10.0, 28.0), 7.0, Color(1.0, 0.54, 0.18))
			draw_circle(torso + Vector2(10.0, 28.0), 7.0, Color(1.0, 0.54, 0.18))
		"nether":
			draw_rect(Rect2(torso + Vector2(-18.0, -18.0), Vector2(36.0, 46.0)), Color(0.34, 0.3, 0.52), true)
			draw_rect(Rect2(torso + Vector2(-14.0, -54.0), Vector2(28.0, 12.0)), Color(0.18, 0.18, 0.28), true)
			draw_circle(torso + Vector2(20.0, -12.0), 7.0, Color(1.0, 0.94, 0.42))
			draw_circle(torso + Vector2(20.0, -12.0), 12.0, Color(1.0, 0.94, 0.42, 0.18))
		"farmer":
			draw_rect(Rect2(torso + Vector2(-19.0, -50.0), Vector2(38.0, 18.0)), Color(0.78, 0.68, 0.24), true)
			draw_line(torso + Vector2(-14.0, -8.0), torso + Vector2(14.0, -22.0), Color(0.34, 0.24, 0.12), 3.0)
		"spear":
			draw_rect(Rect2(torso + Vector2(-14.0, -50.0), Vector2(28.0, 12.0)), Color(0.66, 0.56, 0.26), true)
			draw_line(torso + Vector2(-26.0, -14.0), torso + Vector2(30.0, -34.0), Color(0.54, 0.38, 0.18), 4.0)
			draw_polygon(
				PackedVector2Array([
					torso + Vector2(30.0, -34.0),
					torso + Vector2(20.0, -28.0),
					torso + Vector2(22.0, -40.0),
				]),
				PackedColorArray([Color(0.82, 0.82, 0.84), Color(0.82, 0.82, 0.84), Color(0.82, 0.82, 0.84)])
			)
		"kungfu":
			draw_rect(Rect2(torso + Vector2(-18.0, -12.0), Vector2(36.0, 40.0)), Color(0.72, 0.18, 0.12), true)
			draw_rect(Rect2(torso + Vector2(-18.0, -52.0), Vector2(36.0, 12.0)), Color(0.12, 0.12, 0.14), true)
			if float(zombie.get("reflect_timer", 0.0)) > 0.0:
				draw_circle(torso + Vector2(0.0, -18.0), 34.0, Color(0.66, 0.9, 1.0, 0.18))
				draw_arc(torso + Vector2(0.0, -18.0), 26.0, level_time * 5.0, level_time * 5.0 + PI * 1.4, 18, Color(0.88, 0.98, 1.0, 0.42), 3.0)
		"day_boss":
			draw_rect(Rect2(torso + Vector2(-34.0, -28.0), Vector2(68.0, 68.0)), Color(0.42, 0.18, 0.12), true)
			draw_rect(Rect2(torso + Vector2(-40.0, -58.0), Vector2(80.0, 20.0)), Color(0.78, 0.52, 0.12), true)
			draw_circle(torso + Vector2(0.0, -46.0), 22.0, Color(0.82, 0.84, 0.74))
			draw_circle(torso + Vector2(0.0, -46.0), 28.0, Color(1.0, 0.42, 0.22, 0.1))
		"night_boss":
			draw_rect(Rect2(torso + Vector2(-34.0, -30.0), Vector2(68.0, 70.0)), Color(0.16, 0.18, 0.42), true)
			draw_rect(Rect2(torso + Vector2(-40.0, -60.0), Vector2(80.0, 20.0)), Color(0.04, 0.04, 0.1), true)
			draw_circle(torso + Vector2(0.0, -46.0), 22.0, Color(0.84, 0.86, 0.92))
			draw_arc(torso + Vector2(0.0, -46.0), 30.0, level_time * 2.4, level_time * 2.4 + PI * 1.6, 20, Color(0.74, 0.84, 1.0, 0.34), 3.0)
			draw_circle(torso + Vector2(-20.0, -20.0), 7.0, Color(0.44, 0.74, 1.0, 0.26))
			draw_circle(torso + Vector2(20.0, -20.0), 7.0, Color(0.7, 0.48, 1.0, 0.22))

	if float(zombie.get("rooted_timer", 0.0)) > 0.0:
		draw_line(torso + Vector2(-20.0, 24.0), torso + Vector2(18.0, 30.0), Color(0.34, 0.72, 0.2, 0.9), 3.0)
		draw_line(torso + Vector2(-16.0, 18.0), torso + Vector2(10.0, 36.0), Color(0.24, 0.58, 0.16, 0.9), 2.0)

	if bool(zombie.get("plant_food_carrier", false)):
		_draw_plant_food_icon(torso + Vector2(0.0, -56.0), 0.46)
	if bool(zombie.get("hypnotized", false)):
		draw_circle(torso + Vector2(0.0, -60.0), 16.0, Color(0.9, 0.42, 1.0, 0.16))
		draw_arc(torso + Vector2(0.0, -60.0), 11.0, level_time * 4.0, level_time * 4.0 + PI * 1.5, 18, Color(0.96, 0.56, 1.0, 0.52), 2.0)


func _draw_shovel_icon(center: Vector2) -> void:
	draw_line(center + Vector2(-10.0, -18.0), center + Vector2(18.0, 18.0), Color(0.47, 0.3, 0.12), 6.0)
	draw_circle(center + Vector2(22.0, 22.0), 12.0, Color(0.55, 0.55, 0.58))
	draw_rect(Rect2(center + Vector2(8.0, 10.0), Vector2(28.0, 16.0)), Color(0.66, 0.66, 0.7), true)


func _draw_mallet_icon(center: Vector2) -> void:
	draw_line(center + Vector2(-8.0, 18.0), center + Vector2(14.0, -12.0), Color(0.47, 0.3, 0.12), 6.0)
	draw_rect(Rect2(center + Vector2(-10.0, -20.0), Vector2(26.0, 12.0)), Color(0.62, 0.5, 0.34), true)
	draw_rect(Rect2(center + Vector2(-14.0, -24.0), Vector2(34.0, 8.0)), Color(0.78, 0.68, 0.54), true)
	draw_rect(Rect2(center + Vector2(10.0, -18.0), Vector2(6.0, 18.0)), Color(0.54, 0.42, 0.28), true)


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


func _wrap_text_lines(text: String, max_width: float, font_size: int) -> Array:
	if max_width <= 0.0:
		return [text]
	var result: Array = []
	for paragraph in text.split("\n", false):
		if paragraph == "":
			result.append("")
			continue
		var line := ""
		for glyph in paragraph:
			var candidate = line + glyph
			var width = ui_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
			if line != "" and width > max_width:
				result.append(line)
				line = glyph
			else:
				line = candidate
		if line != "":
			result.append(line)
	if result.is_empty():
		result.append("")
	return result


func _draw_text_block(text: String, rect: Rect2, font_size: int, text_color: Color, line_gap: float = 6.0, max_lines: int = 0) -> void:
	var lines = _wrap_text_lines(text, rect.size.x, font_size)
	if max_lines > 0 and lines.size() > max_lines:
		lines = lines.slice(0, max_lines)
		var last_index = lines.size() - 1
		var ellipsis_line = String(lines[last_index])
		while ellipsis_line.length() > 0 and ui_font.get_string_size(ellipsis_line + "...", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > rect.size.x:
			ellipsis_line = ellipsis_line.left(ellipsis_line.length() - 1)
		lines[last_index] = ellipsis_line + "..."
	var line_height = float(font_size) + line_gap
	for i in range(lines.size()):
		var baseline = rect.position + Vector2(0.0, font_size + i * line_height)
		if baseline.y > rect.position.y + rect.size.y:
			break
		_draw_text(String(lines[i]), baseline, font_size, text_color)


func _plant_almanac_stats(kind: String) -> Array:
	var data = Defs.PLANTS[kind]
	var stats: Array = [
		"花费：%d" % int(data["cost"]),
		"耐久：%d" % int(data["health"]),
		"冷却：%.1f 秒" % float(data["cooldown"]),
	]
	match kind:
		"sunflower", "sun_bean":
			stats.append("生产：每次 50 阳光")
		"sun_shroom":
			stats.append("生产：先 25，长大后 50 阳光")
		"moon_lotus":
			stats.append("生产：50 阳光并叫醒附近植物")
		"wallnut", "cactus_guard":
			stats.append("定位：防线与拖延")
		"lily_pad":
			stats.append("定位：水路平台")
		"squash":
			stats.append("伤害：1600 重压")
		"threepeater":
			stats.append("攻击：三路齐射")
		"lotus_lancer":
			stats.append("攻击：整路贯穿水矛")
		"mirror_reed":
			stats.append("定位：反隐与范围脉冲")
		"frost_fan":
			stats.append("攻击：三路霜风减速")
		"tangle_kelp":
			stats.append("定位：水路拖拽")
		"jalapeno":
			stats.append("伤害：整行 1600")
		"spikeweed":
			stats.append("定位：接触持续伤害")
		"torchwood":
			stats.append("效果：豌豆穿过后翻倍并点燃")
		"tallnut":
			stats.append("定位：超厚防线，阻挡跳跃")
		"cherry_bomb", "potato_mine", "wallnut_bowling":
			stats.append("定位：爆发清场")
		"puff_shroom", "fume_shroom", "scaredy_shroom":
			stats.append("定位：夜晚远程输出")
		"lantern_bloom", "dream_drum":
			stats.append("定位：范围控场与唤醒")
		_:
			if data.has("damage"):
				stats.append("伤害：%d" % int(data["damage"]))
	return stats


func _zombie_almanac_stats(kind: String) -> Array:
	var data = Defs.ZOMBIES[kind]
	var stats = [
		"耐久：%d" % int(data["health"]),
		"速度：%.0f" % float(data["speed"]),
		"啃咬：%.0f DPS" % float(data["attack_dps"]),
		"击杀金币：%d" % int(data["reward"]),
	]
	if data.has("shield_health"):
		stats.append("护具：%d" % int(data["shield_health"]))
	match kind:
		"ducky_tube", "lifebuoy_normal":
			stats.append("特性：水路常规推进")
		"lifebuoy_cone":
			stats.append("特性：水路路障前压")
		"lifebuoy_bucket":
			stats.append("特性：水路重装推进")
		"snorkel":
			stats.append("特性：潜水时免疫直线攻击")
		"zomboni":
			stats.append("特性：碾压植物并留下冰道")
		"bobsled_team":
			stats.append("特性：必须借冰道高速冲锋")
		"dolphin_rider":
			stats.append("特性：首次遇植物会跃过")
		"pool_boss":
			stats.append("特性：泳池终章 Boss，持续召援并压迫水陆两线")
		"rumia_boss":
			stats.append("特性：右侧悬停、换行施法、不可魅惑")
	return stats


func _plant_almanac_lines(kind: String) -> Array:
	return AlmanacTextLib.plant_lines(kind)


func _zombie_almanac_lines(kind: String) -> Array:
	return AlmanacTextLib.zombie_lines(kind)


func _toggle_plant_food_tool() -> void:
	if plant_food_count <= 0:
		_show_toast("还没有收集到能量豆")
		return
	selected_tool = "" if selected_tool == "plant_food" else "plant_food"
	queue_redraw()


func _plant_has_food_power(plant: Dictionary) -> bool:
	return String(plant["plant_food_mode"]) != "" or float(plant.get("armor_health", 0.0)) > 0.0


func _activate_plant_food(row: int, col: int) -> bool:
	var plant_variant = _targetable_plant_at(row, col)
	if plant_variant == null:
		return false

	var plant = plant_variant
	plant["sleep_timer"] = 0.0
	var center = _cell_center(row, col)
	var kind = String(plant["kind"])
	match kind:
		"peashooter", "amber_shooter", "puff_shroom", "scaredy_shroom":
			if String(plant["plant_food_mode"]) == "pea_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "pea_storm"
			plant["plant_food_timer"] = 2.5
			if kind == "amber_shooter":
				plant["plant_food_timer"] = 2.8
			elif kind == "scaredy_shroom":
				plant["plant_food_timer"] = 3.0
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
		"lily_pad":
			plant["plant_food_mode"] = "pad_bloom"
			plant["plant_food_timer"] = 0.4
			for water_row in water_rows:
				for water_col in range(COLS):
					if _support_plant_at(int(water_row), water_col) != null or _top_plant_at(int(water_row), water_col) != null:
						continue
					support_grid[int(water_row)][water_col] = _create_plant("lily_pad", int(water_row), water_col)
					support_grid[int(water_row)][water_col]["flash"] = 0.18
		"squash":
			var squash_targets = _find_closest_zombies_in_radius(center, 240.0, 3)
			if squash_targets.is_empty():
				return false
			plant["plant_food_mode"] = "squash_frenzy"
			plant["plant_food_timer"] = 0.3
			for zombie_index in squash_targets:
				var squash_zombie = zombies[zombie_index]
				squash_zombie = _apply_zombie_damage(squash_zombie, float(Defs.PLANTS["squash"]["damage"]), 0.3, 0.0, true)
				zombies[zombie_index] = squash_zombie
			plant["health"] = 0.0
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
				if not _is_enemy_zombie(zombie):
					continue
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
		"threepeater":
			if String(plant["plant_food_mode"]) == "tri_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "tri_storm"
			plant["plant_food_timer"] = 2.8
			plant["plant_food_interval"] = 0.01
		"boomerang_shooter":
			if String(plant["plant_food_mode"]) == "boomerang_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "boomerang_storm"
			plant["plant_food_timer"] = 2.1
			plant["plant_food_interval"] = 0.01
		"sakura_shooter":
			if String(plant["plant_food_mode"]) == "sakura_storm" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "sakura_storm"
			plant["plant_food_timer"] = 2.0
			plant["plant_food_interval"] = 0.01
		"lotus_lancer":
			if String(plant["plant_food_mode"]) == "lancer_burst" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "lancer_burst"
			plant["plant_food_timer"] = 1.4
			plant["plant_food_interval"] = 0.01
		"mirror_reed":
			plant["plant_food_mode"] = "mirror_burst"
			plant["plant_food_timer"] = 0.35
			plant["support_timer"] = 0.0
		"frost_fan":
			if String(plant["plant_food_mode"]) == "frost_gale" and float(plant["plant_food_timer"]) > 0.0:
				return false
			plant["plant_food_mode"] = "frost_gale"
			plant["plant_food_timer"] = 1.6
			plant["plant_food_interval"] = 0.01
		"vine_lasher":
			plant["plant_food_mode"] = "lash_frenzy"
			plant["plant_food_timer"] = 0.6
			var lash_range = 280.0
			for zombie_index in _find_closest_lane_zombies(row, center.x, 5, lash_range):
				var lash_zombie = zombies[zombie_index]
				lash_zombie["health"] -= 120.0
				lash_zombie["slow_timer"] = maxf(float(lash_zombie["slow_timer"]), 4.0)
				lash_zombie["flash"] = 0.2
				zombies[zombie_index] = lash_zombie
			_damage_obstacles_in_radius(row, center.x + lash_range * 0.5, lash_range * 0.5, 120.0)
			effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(20.0, -6.0),
				"length": lash_range,
				"width": 62.0,
				"radius": lash_range * 0.5,
				"time": 0.28,
				"duration": 0.28,
				"color": Color(0.42, 0.94, 0.34, 0.3),
			})
		"pepper_mortar":
			plant["plant_food_mode"] = "mortar_burst"
			plant["plant_food_timer"] = 0.4
			_damage_zombies_in_radius(row, center.x + 130.0, 210.0, 110.0)
			_damage_obstacles_in_radius(row, center.x + 130.0, 210.0, 110.0)
			effects.append({
				"position": center + Vector2(130.0, 0.0),
				"radius": 210.0,
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
			var burst_radius = float(Defs.PLANTS["pulse_bulb"].get("radius", 175.0)) + 70.0
			_damage_zombies_in_circle(center, burst_radius, 120.0)
			_damage_obstacles_in_circle(center, burst_radius, 120.0)
			effects.append({
				"position": center,
				"radius": burst_radius,
				"time": 0.38,
				"duration": 0.38,
				"color": Color(0.98, 0.98, 0.42, 0.46),
			})
		"spikeweed":
			plant["plant_food_mode"] = "spike_storm"
			plant["plant_food_timer"] = 0.45
			for lane in [row - 1, row, row + 1]:
				if lane < 0 or lane >= ROWS or not _is_row_active(lane):
					continue
				_damage_zombies_in_radius(int(lane), center.x, board_size.x, 120.0)
				for i in range(zombies.size()):
					var spike_zombie = zombies[i]
					if int(spike_zombie["row"]) != int(lane) or String(spike_zombie["kind"]) != "zomboni":
						continue
					spike_zombie["health"] = 0.0
					zombies[i] = spike_zombie
		"sun_bean":
			plant["plant_food_mode"] = "sun_burst"
			plant["plant_food_timer"] = 0.7
			plant["plant_food_interval"] = 0.0
			for index in range(4):
				var angle = -0.8 + float(index) * 0.5
				var offset = Vector2(cos(angle), sin(angle)) * 28.0
				_spawn_sun(center + offset, center.y - 20.0 + offset.y * 0.2, "plant_food")
		"sun_shroom":
			plant["mature"] = true
			plant["grow_timer"] = 0.0
			plant["plant_food_mode"] = "sun_burst"
			plant["plant_food_timer"] = 0.8
			plant["plant_food_interval"] = 0.0
			for index in range(5):
				var angle = -1.0 + float(index) * 0.5
				var offset = Vector2(cos(angle), sin(angle)) * 32.0
				_spawn_sun(center + offset, center.y - 24.0 + offset.y * 0.2, "plant_food")
			effects.append({
				"position": center,
				"radius": 76.0,
				"time": 0.32,
				"duration": 0.32,
				"color": Color(1.0, 0.92, 0.42, 0.3),
			})
		"fume_shroom":
			plant["plant_food_mode"] = "fume_burst"
			plant["plant_food_timer"] = 1.8
			plant["plant_food_interval"] = 0.01
			var fume_range = float(Defs.PLANTS["fume_shroom"]["range"]) + 70.0
			var fume_damage = 160.0
			for i in range(zombies.size()):
				var fume_zombie = zombies[i]
				if int(fume_zombie["row"]) != row or bool(fume_zombie.get("jumping", false)) or not _is_enemy_zombie(fume_zombie):
					continue
				var distance = float(fume_zombie["x"]) - center.x
				if distance < -20.0 or distance > fume_range:
					continue
				fume_zombie = _apply_zombie_damage(fume_zombie, fume_damage, 0.22, 0.0, true)
				zombies[i] = fume_zombie
			_damage_obstacles_in_radius(row, center.x + fume_range * 0.5, fume_range * 0.5, fume_damage)
			effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(30.0, -8.0),
				"length": fume_range,
				"width": float(Defs.PLANTS["fume_shroom"].get("width", 92.0)) * 1.65,
				"radius": fume_range * 0.58,
				"time": 0.36,
				"duration": 0.36,
				"color": Color(0.9, 0.68, 1.0, 0.3),
			})
		"grave_buster":
			var removed_graves := 0
			for i in range(graves.size() - 1, -1, -1):
				graves.remove_at(i)
				removed_graves += 1
			if removed_graves <= 0:
				return false
			plant["plant_food_mode"] = "grave_storm"
			plant["plant_food_timer"] = 0.45
			for index in range(min(removed_graves, 4)):
				var angle = -0.8 + float(index) * 0.5
				var offset = Vector2(cos(angle), sin(angle)) * 24.0
				_spawn_sun(center + offset, center.y - 18.0, "plant_food")
			effects.append({
				"position": center,
				"radius": 150.0,
				"time": 0.38,
				"duration": 0.38,
				"color": Color(0.42, 0.94, 0.34, 0.24),
			})
		"hypno_shroom":
			var blast_targets = _find_closest_zombies_in_radius(center, 220.0, 3)
			if blast_targets.is_empty():
				return false
			plant["plant_food_mode"] = "mind_burst"
			plant["plant_food_timer"] = 0.4
			for zombie_index in blast_targets:
				var zombie = zombies[zombie_index]
				if _is_boss_zombie(zombie):
					continue
				zombie = _hypnotize_zombie(zombie)
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.9)
				zombies[zombie_index] = zombie
			effects.append({
				"position": center,
				"radius": 220.0,
				"time": 0.34,
				"duration": 0.34,
				"color": Color(0.92, 0.42, 1.0, 0.32),
			})
		"scaredy_shroom":
			effects.append({
				"position": center,
				"radius": 96.0,
				"time": 0.32,
				"duration": 0.32,
				"color": Color(0.78, 0.48, 1.0, 0.26),
			})
		"ice_shroom":
			if float(plant["fuse_timer"]) <= 0.05:
				return false
			plant["plant_food_mode"] = "deep_freeze"
			plant["plant_food_timer"] = minf(float(plant["fuse_timer"]), 0.18)
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.18)
		"doom_shroom":
			if float(plant["fuse_timer"]) <= 0.05:
				return false
			plant["plant_food_mode"] = "doom_bloom"
			plant["plant_food_timer"] = minf(float(plant["fuse_timer"]), 0.18)
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.18)
		"moon_lotus":
			plant["plant_food_mode"] = "moon_burst"
			plant["plant_food_timer"] = 0.5
			for index in range(5):
				var angle = -1.0 + float(index) * 0.45
				var offset = Vector2(cos(angle), sin(angle)) * 34.0
				_spawn_sun(center + offset, center.y - 20.0 + offset.y * 0.2, "plant_food")
			_wake_all_plants()
		"prism_grass":
			plant["plant_food_mode"] = "prism_burst"
			plant["plant_food_timer"] = 0.35
			var prism_burst_range = float(Defs.PLANTS["prism_grass"]["range"]) + 120.0
			var targets = _find_lane_targets(row, center.x, prism_burst_range, 5)
			for zombie_index in targets:
				var zombie = zombies[zombie_index]
				zombie = _apply_zombie_damage(zombie, 180.0, 0.22, 0.0, true)
				zombies[zombie_index] = zombie
			_damage_obstacles_in_radius(row, center.x + prism_burst_range * 0.5, prism_burst_range * 0.5, 180.0)
			effects.append({
				"shape": "lane_spray",
				"position": center + Vector2(22.0, -4.0),
				"length": prism_burst_range,
				"width": 52.0,
				"radius": prism_burst_range * 0.5,
				"time": 0.26,
				"duration": 0.26,
				"color": Color(0.66, 1.0, 1.0, 0.3),
			})
		"lantern_bloom":
			plant["plant_food_mode"] = "lantern_burst"
			plant["plant_food_timer"] = 0.4
			_damage_zombies_in_circle(center, 240.0, 120.0)
			_wake_plants_in_radius(center, 260.0)
		"meteor_gourd":
			plant["plant_food_mode"] = "meteor_burst"
			plant["plant_food_timer"] = 0.45
			for _i in range(3):
				var impact_target = _find_global_frontmost_target()
				if int(impact_target["row"]) == -1:
					break
				var impact = Vector2(float(impact_target["x"]) + rng.randf_range(-16.0, 16.0), _row_center_y(int(impact_target["row"])))
				_damage_zombies_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]) + 22.0, 160.0)
				_damage_obstacles_in_circle(impact, float(Defs.PLANTS["meteor_gourd"]["splash_radius"]) + 22.0, 160.0)
				effects.append({
					"position": impact,
					"radius": float(Defs.PLANTS["meteor_gourd"]["splash_radius"]) + 20.0,
					"time": 0.34,
					"duration": 0.34,
					"color": Color(1.0, 0.54, 0.2, 0.34),
				})
		"root_snare":
			plant["plant_food_mode"] = "root_burst"
			plant["plant_food_timer"] = 0.45
			var rooted_targets = _find_closest_zombies_in_radius(center, 420.0, 5)
			if rooted_targets.is_empty():
				return false
			for zombie_index in rooted_targets:
				var zombie = zombies[zombie_index]
				zombie = _apply_zombie_damage(zombie, 100.0, 0.2)
				zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer", 0.0)), 5.0)
				zombies[zombie_index] = zombie
		"thunder_pine":
			plant["plant_food_mode"] = "storm_burst"
			plant["plant_food_timer"] = 0.45
			for lane in active_rows:
				var target_index = _find_frontmost_zombie(int(lane))
				if target_index != -1:
					_strike_thunder_chain(target_index, 120.0, 60.0, 180.0, 3)
		"dream_drum":
			plant["plant_food_mode"] = "dream_burst"
			plant["plant_food_timer"] = 0.45
			_wake_all_plants()
			for i in range(zombies.size()):
				var drum_zombie = zombies[i]
				if not _is_enemy_zombie(drum_zombie):
					continue
				drum_zombie = _apply_zombie_damage(drum_zombie, 90.0, 0.18)
				drum_zombie["special_pause_timer"] = maxf(float(drum_zombie.get("special_pause_timer", 0.0)), 1.1)
				zombies[i] = drum_zombie
		"wind_orchid":
			plant["plant_food_mode"] = "gust_burst"
			plant["plant_food_timer"] = 0.6
			for lane in range(ROWS):
				if not _is_row_active(lane):
					continue
				var lane_center = Vector2(center.x, _row_center_y(lane))
				for i in range(zombies.size()):
					var gust_zombie = zombies[i]
					if int(gust_zombie["row"]) != lane or not _is_enemy_zombie(gust_zombie):
						continue
					gust_zombie["x"] += 78.0
					gust_zombie["flash"] = 0.16
					zombies[i] = gust_zombie
				for i in range(weeds.size() - 1, -1, -1):
					if int(weeds[i]["row"]) == lane:
						weeds.remove_at(i)
				for i in range(spears.size() - 1, -1, -1):
					if int(spears[i]["row"]) == lane:
						spears.remove_at(i)
				effects.append({
					"shape": "lane_spray",
					"position": lane_center + Vector2(14.0, -6.0),
					"length": BOARD_ORIGIN.x + board_size.x - lane_center.x,
					"width": CELL_SIZE.y * 0.76,
					"radius": BOARD_ORIGIN.x + board_size.x - lane_center.x,
					"time": 0.24,
					"duration": 0.24,
					"color": Color(0.72, 0.94, 1.0, 0.28),
				})
		"tangle_kelp":
			var kelp_targets = _find_closest_zombies_in_radius(center, 220.0, 3)
			if kelp_targets.is_empty():
				return false
			plant["plant_food_mode"] = "kelp_frenzy"
			plant["plant_food_timer"] = 0.3
			for zombie_index in kelp_targets:
				var kelp_zombie = zombies[zombie_index]
				kelp_zombie = _apply_zombie_damage(kelp_zombie, float(Defs.PLANTS["tangle_kelp"]["damage"]), 0.3, 0.0, true)
				zombies[zombie_index] = kelp_zombie
			plant["health"] = 0.0
		"jalapeno":
			if float(plant["fuse_timer"]) <= 0.05:
				return false
			plant["plant_food_mode"] = "inferno"
			plant["plant_food_timer"] = minf(float(plant["fuse_timer"]), 0.18)
			plant["fuse_timer"] = minf(float(plant["fuse_timer"]), 0.18)
		"torchwood":
			plant["plant_food_mode"] = "fire_storm"
			plant["plant_food_timer"] = 2.3
			plant["plant_food_interval"] = 0.01
		"tallnut":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = 12000.0
			plant["max_armor_health"] = 12000.0
			plant["plant_food_mode"] = "fortify"
			plant["plant_food_timer"] = 9999.0
		_:
			return false

	plant["flash"] = maxf(float(plant["flash"]), 0.22)
	_set_targetable_plant(row, col, plant)
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
		if int(zombie["row"]) != row or bool(zombie["jumping"]) or not _is_enemy_zombie(zombie):
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


func _find_closest_zombies_in_radius(center: Vector2, radius: float, count: int) -> Array:
	var candidates: Array = []
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		var distance = zombie_pos.distance_to(center)
		if distance > radius:
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
		"version": 2,
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"completed_level_ids": _completed_level_ids(),
		"coins_total": coins_total,
		"last_level_index": selected_level_index,
		"current_world_key": current_world_key,
	}
	save_file.store_string(JSON.stringify(save_data))
	save_dirty = false


func _completed_level_ids() -> Array:
	var result: Array = []
	for i in range(min(completed_levels.size(), Defs.LEVELS.size())):
		if not bool(completed_levels[i]):
			continue
		result.append(String(Defs.LEVELS[i].get("id", "")))
	return result


func _count_completed_levels() -> int:
	var completed_count := 0
	for completed in completed_levels:
		if bool(completed):
			completed_count += 1
	return completed_count


func _sparse_progress_backfill_count() -> int:
	var reached_level_count = max(unlocked_levels, selected_level_index + 1)
	return min(max(reached_level_count, 0), completed_levels.size())


func _should_backfill_sparse_progress(completed_count: int) -> bool:
	return unlocked_levels >= max(12, Defs.LEVELS.size() - 2) and completed_count <= max(4, int(floor(float(unlocked_levels) * 0.2)))


func _should_recover_inconsistent_blank_save(save_version: int, completed_count: int) -> bool:
	return save_version >= 2 and completed_count == 0 and unlocked_levels <= 1 and selected_level_index >= 12


func _apply_loaded_save_data(save_data: Dictionary) -> bool:
	var save_version = int(save_data.get("version", 1))
	unlocked_levels = clampi(int(save_data.get("unlocked_levels", 1)), 1, Defs.LEVELS.size())
	coins_total = max(0, int(save_data.get("coins_total", 0)))
	selected_level_index = clampi(int(save_data.get("last_level_index", -1)), -1, Defs.LEVELS.size() - 1)
	current_world_key = String(save_data.get("current_world_key", "day"))

	completed_levels.resize(Defs.LEVELS.size())
	for i in range(completed_levels.size()):
		completed_levels[i] = false

	var migrated := false
	var saved_completed_ids = save_data.get("completed_level_ids", [])
	if saved_completed_ids is Array and not saved_completed_ids.is_empty():
		for level_id_variant in saved_completed_ids:
			var index = _find_level_index_by_id(String(level_id_variant))
			if index != -1:
				completed_levels[index] = true
	else:
		var saved_completed = save_data.get("completed_levels", [])
		if not (saved_completed is Array):
			saved_completed = []
		for i in range(completed_levels.size()):
			completed_levels[i] = bool(saved_completed[i]) if i < saved_completed.size() else false
		if save_version <= 1:
			migrated = true

	var completed_count = _count_completed_levels()
	if _should_recover_inconsistent_blank_save(save_version, completed_count):
		unlocked_levels = max(unlocked_levels, min(selected_level_index + 1, Defs.LEVELS.size()))
		for i in range(_sparse_progress_backfill_count()):
			completed_levels[i] = true
		completed_count = _count_completed_levels()
		migrated = true
	if _should_backfill_sparse_progress(completed_count):
		for i in range(_sparse_progress_backfill_count()):
			completed_levels[i] = true
		migrated = true

	for i in range(completed_levels.size()):
		if bool(completed_levels[i]):
			unlocked_levels = max(unlocked_levels, min(i + 2, Defs.LEVELS.size()))

	return migrated


func _load_game() -> bool:
	return bool(_load_game_status().get("loaded", false))


func _load_game_status() -> Dictionary:
	var had_file = FileAccess.file_exists(SAVE_PATH)
	if not had_file:
		return {
			"loaded": false,
			"had_file": false,
			"migrated": false,
		}

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return {
			"loaded": false,
			"had_file": true,
			"migrated": false,
		}

	var parsed = JSON.parse_string(save_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"loaded": false,
			"had_file": true,
			"migrated": false,
		}

	var save_data: Dictionary = parsed
	var migrated = _apply_loaded_save_data(save_data)
	if migrated:
		_save_game()
	return {
		"loaded": true,
		"had_file": true,
		"migrated": migrated,
	}
