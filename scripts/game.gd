extends Control

const Defs = preload("res://scripts/game_defs.gd")
const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const WindowModeLib = preload("res://scripts/system/window_mode.gd")
const UpdateManagerLib = preload("res://scripts/system/update_manager.gd")
const WorldDataLib = preload("res://scripts/data/world_data.gd")
const AlmanacTextLib = preload("res://scripts/data/almanac_text.gd")
const PlantFoodRuntime = preload("res://scripts/runtime/plant_food_runtime.gd")
const PlantRuntime = preload("res://scripts/runtime/plant_runtime.gd")
const ProjectileRuntime = preload("res://scripts/runtime/projectile_runtime.gd")

const ROWS := 6
const COLS := 9
const DEFAULT_BOARD_ROWS := 5

const MODE_WORLD_SELECT := "world_select"
const MODE_MAP := "map"
const MODE_ALMANAC := "almanac"
const MODE_SELECTION := "selection"
const MODE_BATTLE := "battle"
const MODE_ENDLESS := "endless"
const MODE_GACHA := "gacha"
const MODE_DAILY := "daily"

const BATTLE_PLAYING := "playing"
const BATTLE_WON := "won"
const BATTLE_LOST := "lost"

const BASE_VIEWPORT_SIZE := Vector2(1600.0, 900.0)
const BASE_BOARD_ORIGIN := Vector2(250.0, 160.0)
const BASE_CELL_SIZE := Vector2(98.0, 110.0)

var BOARD_ORIGIN := BASE_BOARD_ORIGIN
var CELL_SIZE := BASE_CELL_SIZE

const BASE_SEED_BANK_RECT := Rect2(26.0, 18.0, 920.0, 102.0)
const BASE_SUN_METER_RECT := Rect2(34.0, 24.0, 92.0, 88.0)
const CARD_SIZE := Vector2(82.0, 92.0)
const CARD_GAP := 6.0
const BASE_WAVE_BAR_RECT := Rect2(948.0, 26.0, 340.0, 24.0)
const BASE_PLANT_FOOD_RECT := Rect2(948.0, 58.0, 90.0, 46.0)
const BASE_COIN_METER_RECT := Rect2(1046.0, 64.0, 136.0, 40.0)
const BASE_PAUSE_BUTTON_RECT := Rect2(1088.0, 64.0, 96.0, 40.0)
const BASE_BACK_BUTTON_RECT := Rect2(1190.0, 64.0, 100.0, 40.0)
var SEED_BANK_RECT := BASE_SEED_BANK_RECT
var SUN_METER_RECT := BASE_SUN_METER_RECT
var WAVE_BAR_RECT := BASE_WAVE_BAR_RECT
var PLANT_FOOD_RECT := BASE_PLANT_FOOD_RECT
var COIN_METER_RECT := BASE_COIN_METER_RECT
var PAUSE_BUTTON_RECT := BASE_PAUSE_BUTTON_RECT
var BACK_BUTTON_RECT := BASE_BACK_BUTTON_RECT

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
const WORLD_SELECT_ENDLESS_RECT := Rect2(74.0, 732.0, 200.0, 62.0)
const WORLD_SELECT_GACHA_RECT := Rect2(294.0, 732.0, 200.0, 62.0)
const WORLD_SELECT_DAILY_RECT := Rect2(514.0, 732.0, 200.0, 62.0)
const WORLD_SELECT_UPDATE_RECT := Rect2(734.0, 732.0, 170.0, 62.0)
const WORLD_SELECT_UPDATE_INFO_RECT := Rect2(734.0, 802.0, 420.0, 46.0)
const MAP_VIEW_RECT := Rect2(120.0, 138.0, 716.0, 548.0)
const MAP_SCROLL_LEFT_RECT := Rect2(1080.0, 32.0, 44.0, 44.0)
const MAP_SCROLL_RIGHT_RECT := Rect2(1132.0, 32.0, 44.0, 44.0)
const WORLD_CARD_SPACING := 470.0
const TOUCH_DRAG_THRESHOLD := 18.0
const TOUCH_PRIORITY_CLICK_THRESHOLD := 34.0
const WORLD_DRAG_RELEASE_BIAS := 0.32
const MAP_DRAG_RELEASE_MULTIPLIER := 3.4

const RUMIA_FRAME_COUNT := 8
const CIRNO_FRAME_COUNT := 8
const DAIYOUSEI_FRAME_COUNT := 8
const MEILING_FRAME_COUNT := 8
const KOAKUMA_FRAME_COUNT := 8
const PATCHOULI_FRAME_COUNT := 8
const SAKUYA_FRAME_COUNT := 8
const REMILIA_FRAME_COUNT := 8

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
static var shared_meiling_frames: Array = []
static var shared_meiling_frames_loaded := false
static var shared_meiling_frames_face_left = null
static var shared_koakuma_frames: Array = []
static var shared_koakuma_frames_loaded := false
static var shared_koakuma_frames_face_left = null
static var shared_patchouli_frames: Array = []
static var shared_patchouli_frames_loaded := false
static var shared_patchouli_frames_face_left = null
static var shared_sakuya_frames: Array = []
static var shared_sakuya_frames_loaded := false
static var shared_sakuya_frames_face_left = null
static var shared_remilia_frames: Array = []
static var shared_remilia_frames_loaded := false
static var shared_remilia_frames_face_left = null

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
	"balloon_zombie",
	"digger_zombie",
	"pogo_zombie",
	"jack_in_the_box_zombie",
	"bungee_zombie",
	"ladder_zombie",
	"catapult_zombie",
	"gargantuar",
	"imp",
	"squash_zombie",
	"excavator_zombie",
	"barrel_screen_zombie",
	"tornado_zombie",
	"wolf_knight_zombie",
	"kite_zombie",
	"hive_zombie",
	"turret_zombie",
	"programmer_zombie",
	"wenjie_zombie",
	"janitor_zombie",
	"subway_zombie",
	"enderman_zombie",
	"router_zombie",
	"ski_zombie",
	"flywheel_zombie",
	"wither_zombie",
	"mech_zombie",
	"wizard_zombie",
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
	"fog_boss",
	"roof_boss",
	"rumia_boss",
	"daiyousei_boss",
	"cirno_boss",
	"meiling_boss",
	"koakuma_boss",
	"patchouli_boss",
	"sakuya_boss",
	"remilia_boss",
]

var rng = RandomNumberGenerator.new()
var ui_font: SystemFont

var mode := MODE_WORLD_SELECT
var battle_state := BATTLE_PLAYING
var battle_paused := false
var panel_action := ""
var board_rows := DEFAULT_BOARD_ROWS
var board_size := Vector2(COLS * CELL_SIZE.x, DEFAULT_BOARD_ROWS * CELL_SIZE.y)

var map_time := 0.0
var selected_level_index := -1
var hovered_level_index := -1
var unlocked_levels := 1
var completed_levels: Array = []
var coins_total := 0
var plant_stars: Dictionary = {}
var plant_fragments: Dictionary = {}
var gacha_pity_counter := 0
var endless_best_wave := 0
var daily_challenge_date := ""

# Endless mode state
var endless_wave := 0
var endless_difficulty_mult := 1.0
var endless_wave_timer := 0.0
var endless_wave_active := false
var endless_zombies_remaining := 0

# Gacha state
var gacha_draw_results: Array = []
var gacha_reveal_index := -1
var gacha_reveal_timer := 0.0
var gacha_mode_scroll := 0.0

# Daily challenge state
var daily_modifiers: Array = []
var daily_completed_today := false

# Enhancement system
var plant_enhance_levels: Dictionary = {}
var enhance_stones := 0
var enhance_selected_plant := ""
const MODE_ENHANCE := "enhance"
const ENHANCE_TABLE = [
	{"cost": 100, "frag_cost": 0, "rate": 1.0, "penalty": 0, "boost": 0.05},
	{"cost": 100, "frag_cost": 0, "rate": 1.0, "penalty": 0, "boost": 0.05},
	{"cost": 100, "frag_cost": 0, "rate": 1.0, "penalty": 0, "boost": 0.05},
	{"cost": 200, "frag_cost": 0, "rate": 0.8, "penalty": 0, "boost": 0.05},
	{"cost": 200, "frag_cost": 0, "rate": 0.8, "penalty": 0, "boost": 0.05},
	{"cost": 200, "frag_cost": 0, "rate": 0.8, "penalty": 0, "boost": 0.05},
	{"cost": 400, "frag_cost": 5, "rate": 0.6, "penalty": 0, "boost": 0.08},
	{"cost": 400, "frag_cost": 5, "rate": 0.6, "penalty": 1, "boost": 0.08},
	{"cost": 400, "frag_cost": 5, "rate": 0.6, "penalty": 1, "boost": 0.08},
	{"cost": 800, "frag_cost": 10, "rate": 0.4, "penalty": 1, "boost": 0.10},
	{"cost": 800, "frag_cost": 10, "rate": 0.4, "penalty": 1, "boost": 0.10},
	{"cost": 800, "frag_cost": 10, "rate": 0.4, "penalty": 1, "boost": 0.10},
	{"cost": 1500, "frag_cost": 20, "rate": 0.25, "penalty": 2, "boost": 0.15},
	{"cost": 1500, "frag_cost": 20, "rate": 0.25, "penalty": 2, "boost": 0.15},
	{"cost": 1500, "frag_cost": 20, "rate": 0.25, "penalty": 2, "boost": 0.15},
]
const ENHANCE_DAMAGE_KEYS := [
	"damage",
	"contact_damage",
	"chain_damage",
	"ultimate_damage",
	"dot_damage",
	"dot_dps",
	"heal",
	"ultimate_heal",
	"thorns",
]
const ENHANCE_INTERVAL_KEYS := [
	"shoot_interval",
	"attack_interval",
	"rear_interval",
	"burst_gap",
	"sun_interval",
	"regen_interval",
	"pulse_interval",
	"support_interval",
	"glitch_time",
	"wilt_time",
]

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
var screen_shake_amount := 0.0
var screen_shake_decay := 8.0
var vfx_particles: Array = []
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
var world_select_velocity := 0.0
var page_transition_active := false
var page_transition_from_mode := ""
var page_transition_to_mode := ""
var page_transition_target_world := ""
var page_transition_progress := 0.0
var page_transition_direction := 1
var map_scroll_by_world := {}
var map_scroll_target_by_world := {}
var map_scroll_velocity_by_world := {}
var touch_navigation_index := -1
var touch_navigation_mode := ""
var touch_navigation_start_pos := Vector2.ZERO
var touch_navigation_last_delta := Vector2.ZERO
var touch_navigation_release_velocity := Vector2.ZERO
var touch_navigation_world_scroll_origin := 0.0
var touch_navigation_map_scroll_origin := 0.0
var touch_navigation_dragging := false
var touch_navigation_press_target := ""
var touch_navigation_press_rect := Rect2()

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
var vases: Array = []
var mowers: Array = []
var effects: Array = []
var card_cooldowns := {}
var plant_runtime: PlantRuntime
var plant_food_runtime: PlantFoodRuntime
var projectile_runtime: ProjectileRuntime
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
var pending_bgm_path := ""
var audio_stream_cache := {}
var update_manager := UpdateManagerLib.new()
var update_check_request: HTTPRequest
var update_download_request: HTTPRequest
var update_state := "idle"
var update_release_info: Dictionary = {}
var update_error_text := ""
var update_status_text := ""
var update_download_progress := 0.0
var update_check_started := false
var update_download_target_path := ""
var update_check_sources: Array = []
var update_check_source_index := -1
var update_best_release_info: Dictionary = {}
var update_check_last_error := ""
var asset_prewarm_queue: Array = []
var asset_prewarm_keys := {}
var startup_loading_active := false
var startup_loading_total_tasks := 0
var startup_loading_completed_tasks := 0
var startup_loading_min_timer := 0.0
var rumia_frames: Array = []
var rumia_frames_loaded := false
var rumia_frames_face_left = null
var cirno_frames: Array = []
var cirno_frames_loaded := false
var cirno_frames_face_left = null
var daiyousei_frames: Array = []
var daiyousei_frames_loaded := false
var daiyousei_frames_face_left = null
var meiling_frames: Array = []
var meiling_frames_loaded := false
var meiling_frames_face_left = null
var koakuma_frames: Array = []
var koakuma_frames_loaded := false
var koakuma_frames_face_left = null
var patchouli_frames: Array = []
var patchouli_frames_loaded := false
var patchouli_frames_face_left = null
var sakuya_frames: Array = []
var sakuya_frames_loaded := false
var sakuya_frames_face_left = null
var remilia_frames: Array = []
var remilia_frames_loaded := false
var remilia_frames_face_left = null
var frozen_branch_midboss_spawned := false
var frozen_branch_midboss_cleared := false
var frozen_branch_progress_locked := false
var frozen_branch_final_boss_spawned := false
var frozen_branch_locked_progress := -1.0
var frozen_branch_post_freeze_cards: Array = []
var frozen_branch_freeze_visual_t := 1.0
var frozen_branch_freeze_visual_duration := 0.85
var frozen_branch_freeze_visual_active := false
var blood_library_hazard_timer := 0.0
var fog_global_reveal_timer := 0.0
var fog_lightning_timer := 0.0
var fog_drift_offset := 0.0
var boss_time_stop_timer := 0.0
var boss_time_stop_flash_timer := 0.0
var storm_lightning_cooldown := 0.0
var city_blizzard_timer := 0.0
var city_blizzard_drift := 0.0
var scarlet_clock_hazard_timer := 0.0
var scarlet_clock_drift := 0.0
var remilia_crimson_fx_timer := 0.0


func _ready() -> void:
	rng.randomize()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_refresh_battle_layout()
	_build_font()
	_build_overlay_ui()
	_build_audio_player()
	_build_update_requests()
	_init_campaign()
	call_deferred("_apply_display_mode")
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if save_dirty:
			_save_game()


func _pointer_local_position() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	return _scene_local_position(get_local_mouse_position())


func _event_local_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return _scene_local_position(event.position)
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return _scene_local_position(event.position)
	return _pointer_local_position()


func _smooth_ui_value(current: float, target: float, delta: float, response: float) -> float:
	if absf(target - current) <= 0.001:
		return target
	var blend = clampf(1.0 - exp(-maxf(delta, 0.0) * response), 0.0, 1.0)
	return lerpf(current, target, blend)


func _spring_ui_value(current: float, target: float, velocity: float, delta: float, stiffness: float, damping: float, snap_distance: float = 0.001, snap_velocity: float = 0.001) -> Dictionary:
	if delta <= 0.0:
		return {"value": current, "velocity": velocity}
	var displacement = target - current
	velocity += displacement * stiffness * delta
	velocity *= exp(-damping * delta)
	current += velocity * delta
	if absf(target - current) <= snap_distance and absf(velocity) <= snap_velocity:
		return {"value": target, "velocity": 0.0}
	return {"value": current, "velocity": velocity}


func _scene_local_position(raw_position: Vector2) -> Vector2:
	return raw_position


func _refresh_battle_layout() -> void:
	var viewport = size if size.x > 0.0 and size.y > 0.0 else BASE_VIEWPORT_SIZE
	var width_scale = maxf(viewport.x / BASE_VIEWPORT_SIZE.x, 1.0)
	var height_scale = maxf(viewport.y / BASE_VIEWPORT_SIZE.y, 1.0)
	var cell_width = clampf(BASE_CELL_SIZE.x * (1.04 + (width_scale - 1.0) * 0.16), BASE_CELL_SIZE.x * 1.04, BASE_CELL_SIZE.x * 1.1)
	var cell_height = clampf(BASE_CELL_SIZE.y * (1.02 + (height_scale - 1.0) * 0.14), BASE_CELL_SIZE.y * 1.02, BASE_CELL_SIZE.y * 1.06)
	CELL_SIZE = Vector2(round(cell_width), round(cell_height))
	var next_board_size = Vector2(COLS * CELL_SIZE.x, board_rows * CELL_SIZE.y)
	var origin_x = minf(clampf(viewport.x * 0.16, 220.0, 336.0), viewport.x - next_board_size.x - 214.0)
	var origin_y = minf(clampf(viewport.y * 0.16, 144.0, 176.0), viewport.y - next_board_size.y - 116.0)
	BOARD_ORIGIN = Vector2(maxf(172.0, origin_x), maxf(128.0, origin_y))
	board_size = next_board_size

	var hud_left = BASE_SEED_BANK_RECT.position.x
	var hud_top = BASE_SEED_BANK_RECT.position.y
	var seed_width = minf(maxf(BASE_SEED_BANK_RECT.size.x, viewport.x - 520.0), 1080.0)
	SEED_BANK_RECT = Rect2(hud_left, hud_top, seed_width, BASE_SEED_BANK_RECT.size.y)
	SUN_METER_RECT = Rect2(hud_left + 8.0, hud_top + 6.0, BASE_SUN_METER_RECT.size.x, BASE_SUN_METER_RECT.size.y)
	var wave_width = clampf(viewport.x * 0.23, BASE_WAVE_BAR_RECT.size.x, 420.0)
	var wave_x = maxf(SEED_BANK_RECT.position.x + SEED_BANK_RECT.size.x + 28.0, viewport.x - wave_width - 332.0)
	WAVE_BAR_RECT = Rect2(wave_x, BASE_WAVE_BAR_RECT.position.y, wave_width, BASE_WAVE_BAR_RECT.size.y)
	PLANT_FOOD_RECT = Rect2(WAVE_BAR_RECT.position.x, BASE_PLANT_FOOD_RECT.position.y, 96.0, BASE_PLANT_FOOD_RECT.size.y)
	BACK_BUTTON_RECT = Rect2(viewport.x - BASE_BACK_BUTTON_RECT.size.x - 44.0, BASE_BACK_BUTTON_RECT.position.y, BASE_BACK_BUTTON_RECT.size.x, BASE_BACK_BUTTON_RECT.size.y)
	PAUSE_BUTTON_RECT = Rect2(BACK_BUTTON_RECT.position.x - BASE_PAUSE_BUTTON_RECT.size.x - 14.0, BASE_PAUSE_BUTTON_RECT.position.y, BASE_PAUSE_BUTTON_RECT.size.x, BASE_PAUSE_BUTTON_RECT.size.y)
	COIN_METER_RECT = Rect2(PAUSE_BUTTON_RECT.position.x - BASE_COIN_METER_RECT.size.x - 14.0, BASE_COIN_METER_RECT.position.y, BASE_COIN_METER_RECT.size.x, BASE_COIN_METER_RECT.size.y)


func _reset_touch_navigation() -> void:
	touch_navigation_index = -1
	touch_navigation_mode = ""
	touch_navigation_start_pos = Vector2.ZERO
	touch_navigation_last_delta = Vector2.ZERO
	touch_navigation_release_velocity = Vector2.ZERO
	touch_navigation_world_scroll_origin = 0.0
	touch_navigation_map_scroll_origin = 0.0
	touch_navigation_dragging = false
	touch_navigation_press_target = ""
	touch_navigation_press_rect = Rect2()


func _world_select_touch_target(position: Vector2) -> Dictionary:
	var enhance_rect = Rect2(WORLD_SELECT_GACHA_RECT.position.x, WORLD_SELECT_GACHA_RECT.position.y + 72.0, 200.0, 52.0)
	var rect_targets = [
		{"id": "world_arrow_left", "rect": WORLD_SELECT_ARROW_LEFT_RECT},
		{"id": "world_arrow_right", "rect": WORLD_SELECT_ARROW_RIGHT_RECT},
		{"id": "world_almanac", "rect": WORLD_SELECT_ALMANAC_RECT},
		{"id": "world_endless", "rect": WORLD_SELECT_ENDLESS_RECT},
		{"id": "world_gacha", "rect": WORLD_SELECT_GACHA_RECT},
		{"id": "world_enhance", "rect": enhance_rect},
		{"id": "world_daily", "rect": WORLD_SELECT_DAILY_RECT},
		{"id": "world_update", "rect": WORLD_SELECT_UPDATE_RECT},
		{"id": "world_update_info", "rect": WORLD_SELECT_UPDATE_INFO_RECT},
		{"id": "world_enter", "rect": WORLD_SELECT_ENTER_RECT},
	]
	for target_variant in rect_targets:
		var target = Dictionary(target_variant)
		var rect = Rect2(target.get("rect", Rect2()))
		if rect.has_point(position):
			return {"id": String(target.get("id", "")), "rect": rect}
	for i in range(WorldDataLib.all().size()):
		var card_rect = _world_card_rect(i)
		if card_rect.has_point(position):
			return {"id": "world_card_%d" % i, "rect": card_rect}
	return {}


func _map_touch_target(position: Vector2) -> Dictionary:
	var rect_targets = [
		{"id": "map_almanac", "rect": MAP_ALMANAC_BUTTON_RECT},
		{"id": "map_back", "rect": MAP_WORLD_BACK_RECT},
		{"id": "map_left", "rect": MAP_SCROLL_LEFT_RECT},
		{"id": "map_right", "rect": MAP_SCROLL_RIGHT_RECT},
	]
	for target_variant in rect_targets:
		var target = Dictionary(target_variant)
		var rect = Rect2(target.get("rect", Rect2()))
		if rect.has_point(position):
			return {"id": String(target.get("id", "")), "rect": rect}
	var level_index = _level_node_at(position)
	if level_index != -1:
		var node_center = _map_node_position(level_index)
		return {"id": "map_level_%d" % level_index, "rect": Rect2(node_center - Vector2(44.0, 44.0), Vector2(88.0, 88.0))}
	return {}


func _touch_navigation_target(position: Vector2, target_mode: String) -> Dictionary:
	if target_mode == MODE_WORLD_SELECT:
		return _world_select_touch_target(position)
	if target_mode == MODE_MAP:
		return _map_touch_target(position)
	return {}


func _handle_touch_navigation_tap(released_mode: String, released_pos: Vector2) -> void:
	if released_mode == MODE_WORLD_SELECT:
		_handle_world_select_click(released_pos)
	elif released_mode == MODE_MAP:
		_handle_map_click(released_pos)


func _begin_touch_navigation(event: InputEventScreenTouch) -> bool:
	if mode != MODE_WORLD_SELECT and mode != MODE_MAP:
		return false
	touch_navigation_index = event.index
	touch_navigation_mode = mode
	touch_navigation_start_pos = event.position
	touch_navigation_last_delta = Vector2.ZERO
	touch_navigation_dragging = false
	touch_navigation_world_scroll_origin = world_select_scroll
	touch_navigation_map_scroll_origin = _map_scroll_value(current_world_key)
	var press_target = _touch_navigation_target(event.position, mode)
	touch_navigation_press_target = String(press_target.get("id", ""))
	touch_navigation_press_rect = Rect2(press_target.get("rect", Rect2()))
	if mode == MODE_WORLD_SELECT:
		world_select_velocity = 0.0
	elif mode == MODE_MAP:
		map_scroll_velocity_by_world[current_world_key] = 0.0
	return true


func _handle_touch_navigation_drag(event: InputEventScreenDrag) -> bool:
	if event.index != touch_navigation_index or touch_navigation_mode == "":
		return false
	var delta_total = event.position - touch_navigation_start_pos
	touch_navigation_last_delta = event.relative
	touch_navigation_release_velocity = event.velocity
	if not touch_navigation_dragging:
		if touch_navigation_press_target != "" and delta_total.length() < TOUCH_PRIORITY_CLICK_THRESHOLD:
			return false
		if delta_total.length() < TOUCH_DRAG_THRESHOLD:
			return false
		if absf(delta_total.x) <= absf(delta_total.y):
			return false
		touch_navigation_dragging = true
		touch_navigation_press_target = ""
		touch_navigation_press_rect = Rect2()
	if touch_navigation_mode == MODE_WORLD_SELECT:
		var world_count = max(WorldDataLib.all().size() - 1, 0)
		var dragged_scroll = clampf(touch_navigation_world_scroll_origin - delta_total.x / WORLD_CARD_SPACING, 0.0, float(world_count))
		world_select_scroll = dragged_scroll
		world_select_velocity = clampf(-event.velocity.x / WORLD_CARD_SPACING, -4.8, 4.8)
		world_select_index = clampi(int(round(dragged_scroll)), 0, max(world_count, 0))
		return true
	if touch_navigation_mode == MODE_MAP:
		_set_map_scroll(current_world_key, touch_navigation_map_scroll_origin - delta_total.x, true)
		map_scroll_velocity_by_world[current_world_key] = -event.velocity.x
		return true
	return false


func _finish_touch_navigation(event: InputEventScreenTouch) -> bool:
	if event.index != touch_navigation_index or touch_navigation_mode == "":
		return false
	var released_mode = touch_navigation_mode
	var released_pos = event.position
	var release_velocity = touch_navigation_release_velocity
	var was_dragging = touch_navigation_dragging
	var press_target = touch_navigation_press_target
	var press_rect = touch_navigation_press_rect
	_reset_touch_navigation()
	if released_mode == MODE_WORLD_SELECT:
		if was_dragging:
			var release_cards_per_second = clampf(-release_velocity.x / WORLD_CARD_SPACING, -4.8, 4.8)
			world_select_velocity = release_cards_per_second
			var predicted = clampf(world_select_scroll + release_cards_per_second * WORLD_DRAG_RELEASE_BIAS, 0.0, float(max(WorldDataLib.all().size() - 1, 0)))
			world_select_index = clampi(int(round(predicted)), 0, max(WorldDataLib.all().size() - 1, 0))
			return true
		if press_target == "" or press_rect.has_point(released_pos):
			_handle_touch_navigation_tap(released_mode, released_pos)
		return true
	if released_mode == MODE_MAP:
		if was_dragging:
			var release_speed = clampf(-release_velocity.x, -2800.0, 2800.0)
			map_scroll_velocity_by_world[current_world_key] = release_speed
			_set_map_scroll(current_world_key, _map_scroll_value(current_world_key, true) + release_speed * 0.14)
			return true
		if press_target == "" or press_rect.has_point(released_pos):
			_handle_touch_navigation_tap(released_mode, released_pos)
		return true
	return false


func _set_battle_paused(value: bool) -> void:
	if battle_paused == value:
		return
	battle_paused = value
	selected_tool = ""
	queue_redraw()


func _toggle_battle_pause() -> void:
	if mode != MODE_BATTLE or battle_state != BATTLE_PLAYING:
		return
	_set_battle_paused(not battle_paused)


func _restart_current_battle() -> void:
	_set_battle_paused(false)
	if _is_endless_level():
		_enter_endless_mode()
		return
	if String(current_level.get("id", "")) == "每日":
		_enter_daily_challenge()
		return
	if selected_level_index >= 0:
		_start_level(selected_level_index)
		return
	_begin_level(-1, active_cards, current_level)


func _battle_pause_menu_rect() -> Rect2:
	return Rect2(size * 0.5 - Vector2(182.0, 208.0), Vector2(364.0, 416.0))


func _battle_pause_button_rect(action: String) -> Rect2:
	var panel_rect = _battle_pause_menu_rect()
	var base_x = panel_rect.position.x + 46.0
	var width = panel_rect.size.x - 92.0
	match action:
		"resume":
			return Rect2(base_x, panel_rect.position.y + 118.0, width, 54.0)
		"restart":
			return Rect2(base_x, panel_rect.position.y + 184.0, width, 54.0)
		"almanac":
			return Rect2(base_x, panel_rect.position.y + 250.0, width, 54.0)
		"map":
			return Rect2(base_x, panel_rect.position.y + 316.0, width, 54.0)
		_:
			return Rect2()


func _handle_battle_pause_click(mouse_pos: Vector2) -> void:
	if not battle_paused:
		return
	if _battle_pause_button_rect("resume").has_point(mouse_pos):
		_set_battle_paused(false)
		return
	if _battle_pause_button_rect("restart").has_point(mouse_pos):
		_restart_current_battle()
		return
	if _battle_pause_button_rect("almanac").has_point(mouse_pos):
		_enter_almanac_mode("plants")
		return
	if _battle_pause_button_rect("map").has_point(mouse_pos):
		_set_battle_paused(false)
		_enter_map_mode()


func _process(delta: float) -> void:
	ui_time += delta
	# Screen shake decay
	if screen_shake_amount > 0.01:
		screen_shake_amount *= exp(-screen_shake_decay * delta)
	else:
		screen_shake_amount = 0.0
	# VFX particle update
	for i in range(vfx_particles.size() - 1, -1, -1):
		vfx_particles[i]["life"] -= delta
		if vfx_particles[i]["life"] <= 0.0:
			vfx_particles.remove_at(i)
		else:
			vfx_particles[i]["pos"] += vfx_particles[i]["vel"] * delta
			vfx_particles[i]["vel"].y += 200.0 * delta
	_update_overlay_timers(delta)
	_update_autosave(delta)
	_update_page_transition(delta)
	_update_freeze_transition_visual(delta)
	if not (touch_navigation_dragging and touch_navigation_mode == MODE_WORLD_SELECT):
		var world_spring = _spring_ui_value(world_select_scroll, float(world_select_index), world_select_velocity, delta, 52.0, 12.0, 0.002, 0.01)
		world_select_scroll = float(world_spring.get("value", world_select_scroll))
		world_select_velocity = float(world_spring.get("velocity", world_select_velocity))
	var prewarm_steps := 1 if mode == MODE_BATTLE else 2
	if page_transition_active:
		prewarm_steps = 3
	if startup_loading_active:
		prewarm_steps = 6
	_service_asset_prewarm_queue(prewarm_steps)
	if startup_loading_active:
		startup_loading_completed_tasks = max(startup_loading_total_tasks - asset_prewarm_queue.size(), 0)
		startup_loading_min_timer = maxf(0.0, startup_loading_min_timer - delta)
		if asset_prewarm_queue.is_empty() and startup_loading_min_timer <= 0.0:
			startup_loading_completed_tasks = startup_loading_total_tasks
			startup_loading_active = false
		queue_redraw()
		return

	_update_download_progress_runtime()

	if page_transition_active:
		queue_redraw()
		return

	if mode == MODE_WORLD_SELECT:
		_begin_auto_update_check_if_needed()
		map_time += delta
		queue_redraw()
		return

	if mode == MODE_MAP:
		map_time += delta
		_update_map_scroll(delta)
		hovered_level_index = _level_node_at(_pointer_local_position())
		queue_redraw()
		return

	if mode == MODE_ALMANAC:
		queue_redraw()
		return

	if mode == MODE_SELECTION:
		_ensure_selection_scene_ready()
		queue_redraw()
		return

	if mode == MODE_BATTLE and battle_paused:
		queue_redraw()
		return

	if battle_state != BATTLE_PLAYING:
		queue_redraw()
		return

	level_time += delta
	boss_time_stop_timer = maxf(0.0, boss_time_stop_timer - delta)
	boss_time_stop_flash_timer = maxf(0.0, boss_time_stop_flash_timer - delta)
	_update_fog_state(delta)
	_update_endless(delta)
	_apply_daily_modifiers(delta)
	for kind in active_cards:
		if kind == "" or not card_cooldowns.has(kind):
			continue
		card_cooldowns[kind] = maxf(0.0, float(card_cooldowns[kind]) - delta)

	sky_sun_cooldown -= delta
	if _level_has_sky_sun() and sky_sun_cooldown <= 0.0:
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
	_update_remilia_crimson_drain(delta)
	_update_blood_library_hazards(delta)
	_update_city_blizzard_weather(delta)
	_update_scarlet_clocktower_hazards(delta)
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
	page_transition_progress = minf(1.0, page_transition_progress + delta / 0.32)
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
	if startup_loading_active or page_transition_active:
		return

	var mouse_pos = _event_local_position(event)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel"):
			if mode == MODE_ALMANAC and almanac_return_mode == MODE_BATTLE:
				_handle_almanac_click(ALMANAC_CLOSE_RECT.get_center())
				return
			if mode == MODE_BATTLE and battle_state == BATTLE_PLAYING:
				_toggle_battle_pause()
				return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _begin_touch_navigation(event):
				return
		elif _finish_touch_navigation(event):
			queue_redraw()
			return
	if event is InputEventScreenDrag:
		if _handle_touch_navigation_drag(event):
			queue_redraw()
			return
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

	if event is InputEventMouseButton and event.pressed and mode == MODE_GACHA:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			gacha_mode_scroll = maxf(0.0, gacha_mode_scroll - 60.0)
			queue_redraw()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			gacha_mode_scroll += 60.0
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
		if mode == MODE_BATTLE and battle_state == BATTLE_PLAYING and not battle_paused:
			selected_tool = ""
			queue_redraw()
		return

	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	if mode == MODE_WORLD_SELECT:
		_handle_world_select_click(mouse_pos)
		return

	if mode == MODE_GACHA:
		_handle_gacha_click(mouse_pos)
		return

	if mode == MODE_ENHANCE:
		_handle_enhance_click(mouse_pos)
		return

	if mode == MODE_MAP:
		_handle_map_click(mouse_pos)
		return

	if mode == MODE_ALMANAC:
		_handle_almanac_click(mouse_pos)
		return

	if mode == MODE_SELECTION:
		_handle_selection_click(mouse_pos)
		return

	if mode == MODE_BATTLE and battle_paused:
		_handle_battle_pause_click(mouse_pos)
		return

	if battle_state != BATTLE_PLAYING:
		return

	if PAUSE_BUTTON_RECT.has_point(mouse_pos):
		_set_battle_paused(true)
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


func _build_update_requests() -> void:
	if update_check_request == null:
		update_check_request = HTTPRequest.new()
		update_check_request.accept_gzip = true
		update_check_request.use_threads = true
		update_check_request.timeout = 6.0
		update_check_request.request_completed.connect(_on_update_check_completed)
		add_child(update_check_request)
	if update_download_request == null:
		update_download_request = HTTPRequest.new()
		update_download_request.accept_gzip = true
		update_download_request.use_threads = true
		update_download_request.request_completed.connect(_on_update_download_completed)
		add_child(update_download_request)


func _begin_auto_update_check_if_needed() -> void:
	if update_check_started:
		return
	if not is_inside_tree():
		update_check_started = true
		return
	update_check_started = true
	_begin_update_check()


func _current_app_version() -> String:
	return update_manager.normalize_version(String(ProjectSettings.get_setting("application/config/version", "0.0.0")))


func _update_action_text() -> String:
	var install_mode = String(update_release_info.get("install_mode", "desktop_replace"))
	match update_state:
		"checking":
			return "检查更新中"
		"latest":
			return "重新检查"
		"available":
			if install_mode == "notify_only":
				return "查看更新"
			if install_mode == "android_handoff":
				return "下载 APK"
			return "下载并更新"
		"downloading":
			return "下载中 %d%%" % clampi(int(round(update_download_progress * 100.0)), 0, 100)
		"ready":
			if install_mode == "notify_only":
				return "查看更新"
			if install_mode == "android_handoff":
				return "安装 APK"
			return "安装更新"
		"applying":
			return "正在应用"
		"error":
			return "重试更新"
		_:
			return "检查更新"


func _update_status_line() -> String:
	if update_status_text != "":
		return update_status_text
	match update_state:
		"checking":
			return "正在检查 GitHub Release..."
		"latest":
			return "当前版本 v%s 已是最新" % _current_app_version()
		"available":
			return "发现新版本 v%s" % String(update_release_info.get("latest_version", "?"))
		"downloading":
			return "正在下载 %s" % String(update_release_info.get("asset_name", "更新包"))
		"ready":
			var install_mode = String(update_release_info.get("install_mode", "desktop_replace"))
			if install_mode == "notify_only":
				return "浏览器版无法自替换，可下载新版本或刷新页面"
			if install_mode == "android_handoff":
				return "APK 已下载，点击按钮继续安装"
			return "更新包已下载，点击按钮应用更新"
		"applying":
			return "更新助手已启动，游戏即将退出并替换文件"
		"error":
			return update_error_text if update_error_text != "" else "更新失败"
		_:
			return "当前版本 v%s" % _current_app_version()


func _update_badge_fill() -> Color:
	match update_state:
		"checking":
			return Color(0.36, 0.62, 0.92)
		"latest":
			return Color(0.3, 0.7, 0.3)
		"available", "ready":
			return Color(0.9, 0.44, 0.16)
		"downloading":
			return Color(0.78, 0.56, 0.18)
		"applying":
			return Color(0.72, 0.3, 0.78)
		"error":
			return Color(0.8, 0.22, 0.24)
		_:
			return Color(0.52, 0.58, 0.62)


func _begin_update_check() -> void:
	update_error_text = ""
	update_status_text = ""
	update_download_progress = 0.0
	update_state = "checking"
	update_release_info = {}
	update_best_release_info = {}
	update_check_last_error = ""
	update_check_sources = update_manager.default_update_sources()
	update_check_source_index = -1
	if update_check_request == null:
		_build_update_requests()
	_try_next_update_check_source("")


func _try_next_update_check_source(last_error: String) -> void:
	if last_error != "":
		update_check_last_error = last_error
	update_check_source_index += 1
	if update_check_source_index >= update_check_sources.size():
		_finalize_update_check()
		return
	var source = Dictionary(update_check_sources[update_check_source_index])
	var headers = PackedStringArray(["User-Agent: pvz-godot-updater"])
	if String(source.get("kind", "")) == "api":
		headers.append("Accept: application/vnd.github+json")
	var request_error = update_check_request.request(String(source.get("url", "")), headers)
	if request_error != OK:
		_try_next_update_check_source(update_manager.build_update_request_start_error_message(request_error))


func _finalize_update_check() -> void:
	if update_best_release_info.is_empty():
		_set_update_error(update_check_last_error if update_check_last_error != "" else "版本检查失败，请稍后重试")
		return
	update_release_info = update_best_release_info.duplicate(true)
	match String(update_release_info.get("status", "")):
		"latest":
			update_state = "latest"
			update_status_text = ""
		"update_available":
			update_state = "available"
			update_status_text = ""
			_show_toast("发现新版本 v%s" % String(update_release_info.get("latest_version", "")))
		"missing_asset":
			_set_update_error("该平台暂时没有对应的更新包")
		"unsupported_platform":
			_set_update_error("当前平台暂不支持自动更新")
		_:
			_set_update_error(update_check_last_error if update_check_last_error != "" else "无法获取可用更新信息")


func _start_update_download() -> void:
	var asset_url = String(update_release_info.get("asset_url", ""))
	var asset_name = String(update_release_info.get("asset_name", ""))
	if asset_url == "" or asset_name == "":
		_set_update_error("当前平台没有可下载的更新包")
		return
	var dir_result = update_manager.ensure_dir_absolute(update_manager.downloads_root_path())
	if dir_result != OK:
		_set_update_error("无法创建更新下载目录")
		return
	update_download_target_path = update_manager.downloaded_asset_path(asset_name)
	if FileAccess.file_exists(update_download_target_path):
		update_manager.remove_recursive_absolute(update_download_target_path)
	update_download_request.download_file = update_download_target_path
	update_download_progress = 0.0
	update_status_text = ""
	update_state = "downloading"
	var headers = PackedStringArray(["User-Agent: pvz-godot-updater"])
	var request_error = update_download_request.request(asset_url, headers)
	if request_error != OK:
		_set_update_error("无法开始下载：%s" % error_string(request_error))


func _update_download_progress_runtime() -> void:
	if update_state != "downloading" or update_download_request == null:
		return
	var body_size = update_download_request.get_body_size()
	var downloaded = update_download_request.get_downloaded_bytes()
	if body_size > 0:
		update_download_progress = clampf(float(downloaded) / float(body_size), 0.0, 1.0)


func _apply_or_open_downloaded_update() -> void:
	var install_mode = String(update_release_info.get("install_mode", "desktop_replace"))
	if install_mode == "desktop_replace":
		_apply_desktop_update()
		return
	if install_mode == "android_handoff":
		if _open_downloaded_android_apk():
			update_status_text = "已尝试拉起安装；若系统先要求允许安装未知应用，请授权后再点一次安装"
			update_state = "ready"
		else:
			_set_update_error("无法调用系统安装器打开 APK")
		return
	_open_release_page()


func _apply_desktop_update() -> void:
	if update_download_target_path == "":
		_set_update_error("更新包尚未下载完成")
		return
	var platform = String(update_release_info.get("platform", update_manager.platform_key_for_runtime()))
	var version = String(update_release_info.get("latest_version", "pending"))
	var stage_dir = update_manager.staged_root_path(version)
	var cleanup_result = update_manager.remove_recursive_absolute(stage_dir)
	if cleanup_result != OK and cleanup_result != ERR_DOES_NOT_EXIST:
		_set_update_error("无法清理旧的更新缓存目录")
		return
	var extract_result = update_manager.extract_zip_archive(update_download_target_path, stage_dir)
	if extract_result != OK:
		_set_update_error("无法解压更新包")
		return
	var install_target = update_manager.desktop_install_target(platform, OS.get_executable_path())
	var helper_path = update_manager.helper_script_path(platform)
	var helper_script = update_manager.build_desktop_apply_script(
		platform,
		OS.get_process_id(),
		stage_dir,
		String(install_target.get("install_dir", "")),
		String(install_target.get("relaunch_path", ""))
	)
	var write_result = update_manager.write_text_file_absolute(helper_path, helper_script)
	if write_result != OK:
		_set_update_error("无法写入更新助手脚本")
		return
	update_state = "applying"
	update_status_text = "正在退出并替换文件..."
	var launch_result = OK
	if platform == "windows":
		launch_result = OS.create_process("cmd.exe", PackedStringArray(["/C", helper_path]))
	else:
		launch_result = OS.create_process("/bin/sh", PackedStringArray([helper_path]))
	if launch_result != OK:
		_set_update_error("无法启动更新助手：%s" % error_string(launch_result))
		return
	_save_game()
	get_tree().quit()


func _android_runtime_singleton():
	if not OS.has_feature("android") and OS.get_name().to_lower() != "android":
		return null
	if not Engine.has_singleton("AndroidRuntime"):
		return null
	return Engine.get_singleton("AndroidRuntime")


func _android_should_request_install_sources(activity) -> bool:
	if activity == null:
		return false
	var package_manager = activity.getPackageManager()
	if package_manager == null:
		return false
	return package_manager.canRequestPackageInstalls() == false


func _open_downloaded_android_apk() -> bool:
	if update_download_target_path == "" or not FileAccess.file_exists(update_download_target_path):
		return false
	var android_runtime = _android_runtime_singleton()
	if android_runtime != null:
		var activity = android_runtime.getActivity()
		if activity != null:
			var intent_class = JavaClassWrapper.wrap("android.content.Intent")
			var uri_class = JavaClassWrapper.wrap("android.net.Uri")
			var file_class = JavaClassWrapper.wrap("java.io.File")
			var settings_class = JavaClassWrapper.wrap("android.provider.Settings")
			if intent_class != null and uri_class != null and file_class != null and settings_class != null:
				var apk_path = update_download_target_path
				var install_runnable = android_runtime.createRunnableFromGodotCallable(func ():
					if _android_should_request_install_sources(activity):
						var settings_intent = intent_class.Intent(settings_class.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
						settings_intent.addFlags(intent_class.FLAG_ACTIVITY_NEW_TASK)
						settings_intent.setData(uri_class.parse("package:%s" % String(activity.getPackageName())))
						activity.startActivity(settings_intent)
						return
					var apk_file = file_class.File(apk_path)
					var apk_uri_native = uri_class.fromFile(apk_file)
					var install_intent = intent_class.Intent(intent_class.ACTION_VIEW)
					install_intent.addFlags(intent_class.FLAG_ACTIVITY_NEW_TASK)
					install_intent.addFlags(intent_class.FLAG_GRANT_READ_URI_PERMISSION)
					install_intent.setDataAndType(apk_uri_native, "application/vnd.android.package-archive")
					activity.startActivity(install_intent)
				)
				activity.runOnUiThread(install_runnable)
				return true
	var apk_uri = "file://" + update_download_target_path.replace(" ", "%20")
	return OS.shell_open(apk_uri) == OK or OS.shell_open(update_download_target_path) == OK


func _open_release_page() -> void:
	var page_url = String(update_release_info.get("page_url", update_manager.releases_url()))
	if page_url == "":
		page_url = update_manager.releases_url()
	if OS.shell_open(page_url) != OK:
		_set_update_error("无法打开更新页面")


func _set_update_error(message: String) -> void:
	update_error_text = message
	update_status_text = message
	update_state = "error"


func _on_update_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var source := Dictionary(update_check_sources[update_check_source_index]) if update_check_source_index >= 0 and update_check_source_index < update_check_sources.size() else {}
	var source_kind = String(source.get("kind", "unknown"))
	if result != HTTPRequest.RESULT_SUCCESS:
		_try_next_update_check_source(update_manager.build_update_check_failure_message(source_kind, result, update_manager.platform_key_for_runtime()))
		return
	if response_code < 200 or response_code >= 300:
		_try_next_update_check_source(update_manager.build_update_http_status_error_message(response_code))
		return
	var body_text = body.get_string_from_utf8()
	var parsed
	if String(source.get("kind", "")) == "project_settings":
		parsed = update_manager.release_payload_from_project_settings_text(body_text)
	elif String(source.get("kind", "")) == "release_page":
		parsed = update_manager.release_payload_from_release_page_html(body_text)
	else:
		parsed = JSON.parse_string(body_text)
	if typeof(parsed) != TYPE_DICTIONARY or Dictionary(parsed).is_empty():
		_try_next_update_check_source(update_manager.build_update_parse_error_message())
		return
	var platform = update_manager.platform_key_for_runtime()
	var resolved = update_manager.resolve_release(parsed, _current_app_version(), platform)
	if String(resolved.get("status", "")) != "invalid_release":
		update_best_release_info = update_manager.prefer_release_info(update_best_release_info, resolved)
		_try_next_update_check_source("")
		return
	_try_next_update_check_source("版本检查失败: 无法获取可用更新信息")


func _on_update_download_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_set_update_error("更新包下载失败")
		return
	if response_code < 200 or response_code >= 300:
		_set_update_error("更新包下载失败，HTTP %d" % response_code)
		return
	update_download_progress = 1.0
	update_state = "ready"
	update_status_text = ""
	_apply_or_open_downloaded_update()


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


func _try_get_cached_audio_stream(path: String) -> AudioStream:
	if path == "":
		return null
	if audio_stream_cache.has(path):
		return audio_stream_cache[path]
	if shared_audio_stream_cache.has(path):
		audio_stream_cache[path] = shared_audio_stream_cache[path]
		return audio_stream_cache[path]
	return null


func _boss_frame_count_for_kind(kind: String) -> int:
	match kind:
		"rumia_boss":
			return RUMIA_FRAME_COUNT
		"daiyousei_boss":
			return DAIYOUSEI_FRAME_COUNT
		"cirno_boss":
			return CIRNO_FRAME_COUNT
		"meiling_boss":
			return MEILING_FRAME_COUNT
		"koakuma_boss":
			return KOAKUMA_FRAME_COUNT
		"patchouli_boss":
			return PATCHOULI_FRAME_COUNT
		"sakuya_boss":
			return SAKUYA_FRAME_COUNT
		"remilia_boss":
			return REMILIA_FRAME_COUNT
		_:
			return 0


func _boss_frame_folder_for_kind(kind: String) -> String:
	match kind:
		"rumia_boss":
			return "res://art/rumia"
		"daiyousei_boss":
			return "res://art/daiyousei"
		"cirno_boss":
			return "res://art/cirno"
		"meiling_boss":
			return "res://art/meiling"
		"koakuma_boss":
			return "res://art/koakuma"
		"patchouli_boss":
			return "res://art/patchouli"
		"sakuya_boss":
			return "res://art/sakuya"
		"remilia_boss":
			return "res://art/remilia"
		_:
			return ""


func _boss_frame_resource_path(kind: String, frame_index: int) -> String:
	var folder = _boss_frame_folder_for_kind(kind)
	if folder == "":
		return ""
	return "%s/frame_%02d.png" % [folder, frame_index]


func _boss_assets_are_preprocessed(kind: String) -> bool:
	return kind == "rumia_boss" or kind == "daiyousei_boss" or kind == "cirno_boss" or kind == "meiling_boss" or kind == "koakuma_boss" or kind == "patchouli_boss" or kind == "sakuya_boss" or kind == "remilia_boss"


func _is_image_backed_hover_boss(kind: String) -> bool:
	return _boss_frame_count_for_kind(kind) > 0


func _shared_boss_frames_for_kind(kind: String) -> Array:
	match kind:
		"rumia_boss":
			return shared_rumia_frames
		"daiyousei_boss":
			return shared_daiyousei_frames
		"cirno_boss":
			return shared_cirno_frames
		"meiling_boss":
			return shared_meiling_frames
		"koakuma_boss":
			return shared_koakuma_frames
		"patchouli_boss":
			return shared_patchouli_frames
		"sakuya_boss":
			return shared_sakuya_frames
		"remilia_boss":
			return shared_remilia_frames
		_:
			return []


func _shared_boss_frames_face_left_for_kind(kind: String):
	match kind:
		"rumia_boss":
			return shared_rumia_frames_face_left
		"daiyousei_boss":
			return shared_daiyousei_frames_face_left
		"cirno_boss":
			return shared_cirno_frames_face_left
		"meiling_boss":
			return shared_meiling_frames_face_left
		"koakuma_boss":
			return shared_koakuma_frames_face_left
		"patchouli_boss":
			return shared_patchouli_frames_face_left
		"sakuya_boss":
			return shared_sakuya_frames_face_left
		"remilia_boss":
			return shared_remilia_frames_face_left
		_:
			return null


func _set_shared_boss_frames_for_kind(kind: String, frames: Array, loaded: bool, face_left) -> void:
	match kind:
		"rumia_boss":
			shared_rumia_frames = frames
			shared_rumia_frames_loaded = loaded
			shared_rumia_frames_face_left = face_left
		"daiyousei_boss":
			shared_daiyousei_frames = frames
			shared_daiyousei_frames_loaded = loaded
			shared_daiyousei_frames_face_left = face_left
		"cirno_boss":
			shared_cirno_frames = frames
			shared_cirno_frames_loaded = loaded
			shared_cirno_frames_face_left = face_left
		"meiling_boss":
			shared_meiling_frames = frames
			shared_meiling_frames_loaded = loaded
			shared_meiling_frames_face_left = face_left
		"koakuma_boss":
			shared_koakuma_frames = frames
			shared_koakuma_frames_loaded = loaded
			shared_koakuma_frames_face_left = face_left
		"patchouli_boss":
			shared_patchouli_frames = frames
			shared_patchouli_frames_loaded = loaded
			shared_patchouli_frames_face_left = face_left
		"sakuya_boss":
			shared_sakuya_frames = frames
			shared_sakuya_frames_loaded = loaded
			shared_sakuya_frames_face_left = face_left
		"remilia_boss":
			shared_remilia_frames = frames
			shared_remilia_frames_loaded = loaded
			shared_remilia_frames_face_left = face_left


func _instance_boss_frames_for_kind(kind: String) -> Array:
	match kind:
		"rumia_boss":
			return rumia_frames
		"daiyousei_boss":
			return daiyousei_frames
		"cirno_boss":
			return cirno_frames
		"meiling_boss":
			return meiling_frames
		"koakuma_boss":
			return koakuma_frames
		"patchouli_boss":
			return patchouli_frames
		"sakuya_boss":
			return sakuya_frames
		"remilia_boss":
			return remilia_frames
		_:
			return []


func _instance_boss_frames_face_left_for_kind(kind: String):
	match kind:
		"rumia_boss":
			return rumia_frames_face_left
		"daiyousei_boss":
			return daiyousei_frames_face_left
		"cirno_boss":
			return cirno_frames_face_left
		"meiling_boss":
			return meiling_frames_face_left
		"koakuma_boss":
			return koakuma_frames_face_left
		"patchouli_boss":
			return patchouli_frames_face_left
		"sakuya_boss":
			return sakuya_frames_face_left
		"remilia_boss":
			return remilia_frames_face_left
		_:
			return null


func _set_instance_boss_frames_for_kind(kind: String, frames: Array, loaded: bool, face_left) -> void:
	match kind:
		"rumia_boss":
			rumia_frames = frames
			rumia_frames_loaded = loaded
			rumia_frames_face_left = face_left
		"daiyousei_boss":
			daiyousei_frames = frames
			daiyousei_frames_loaded = loaded
			daiyousei_frames_face_left = face_left
		"cirno_boss":
			cirno_frames = frames
			cirno_frames_loaded = loaded
			cirno_frames_face_left = face_left
		"meiling_boss":
			meiling_frames = frames
			meiling_frames_loaded = loaded
			meiling_frames_face_left = face_left
		"koakuma_boss":
			koakuma_frames = frames
			koakuma_frames_loaded = loaded
			koakuma_frames_face_left = face_left
		"patchouli_boss":
			patchouli_frames = frames
			patchouli_frames_loaded = loaded
			patchouli_frames_face_left = face_left
		"sakuya_boss":
			sakuya_frames = frames
			sakuya_frames_loaded = loaded
			sakuya_frames_face_left = face_left
		"remilia_boss":
			remilia_frames = frames
			remilia_frames_loaded = loaded
			remilia_frames_face_left = face_left


func _boss_frame_array_is_complete(frames: Array, expected_count: int) -> bool:
	if frames.size() != expected_count:
		return false
	for frame in frames:
		if frame == null:
			return false
	return true


func _sync_instance_boss_frames_from_shared(kind: String) -> void:
	var expected_count = _boss_frame_count_for_kind(kind)
	var expected_face_left = _boss_frames_face_left(kind)
	var shared_frames = _shared_boss_frames_for_kind(kind)
	var shared_face_left = _shared_boss_frames_face_left_for_kind(kind)
	if shared_frames.size() != expected_count or shared_face_left == null or bool(shared_face_left) != expected_face_left:
		return
	_set_instance_boss_frames_for_kind(kind, shared_frames, _boss_frame_array_is_complete(shared_frames, expected_count), shared_face_left)


func _enqueue_asset_prewarm_task(key: String, task: Dictionary) -> void:
	if key == "" or asset_prewarm_keys.has(key):
		return
	asset_prewarm_keys[key] = true
	var queued_task = task.duplicate()
	queued_task["key"] = key
	asset_prewarm_queue.append(queued_task)


func _queue_audio_stream_prewarm(path: String) -> void:
	if path == "" or _try_get_cached_audio_stream(path) != null:
		return
	_enqueue_asset_prewarm_task("audio:%s" % path, {
		"type": "audio",
		"path": path,
	})


func _queue_boss_frame_set_prewarm(kind: String) -> void:
	if not _is_image_backed_hover_boss(kind):
		return
	var expected_count = _boss_frame_count_for_kind(kind)
	var expected_face_left = _boss_frames_face_left(kind)
	_sync_instance_boss_frames_from_shared(kind)
	var frames = _instance_boss_frames_for_kind(kind)
	if _boss_frame_array_is_complete(frames, expected_count) and _instance_boss_frames_face_left_for_kind(kind) != null and bool(_instance_boss_frames_face_left_for_kind(kind)) == expected_face_left:
		return
	for frame_index in range(expected_count):
		if frame_index < frames.size() and frames[frame_index] != null:
			continue
		_enqueue_asset_prewarm_task("boss_frame:%s:%d:%s" % [kind, frame_index, expected_face_left], {
			"type": "boss_frame",
			"kind": kind,
			"frame_index": frame_index,
			"face_left": expected_face_left,
		})


func _queue_level_boss_asset_prewarm(level: Dictionary) -> void:
	if level.is_empty():
		return
	_queue_audio_stream_prewarm(String(level.get("boss_intro_bgm", "")))
	_queue_audio_stream_prewarm(String(level.get("boss_bgm", "")))
	var boss_kinds := {}
	var midboss_kind = String(level.get("mid_boss_kind", ""))
	if _is_image_backed_hover_boss(midboss_kind):
		boss_kinds[midboss_kind] = true
	for event in level.get("events", []):
		var kind = String(event.get("kind", ""))
		if _is_image_backed_hover_boss(kind):
			boss_kinds[kind] = true
	for kind in boss_kinds.keys():
		_queue_boss_frame_set_prewarm(String(kind))


func _queue_world_boss_asset_prewarm(world_key: String) -> void:
	for level_index in _visible_level_indices(world_key):
		_queue_level_boss_asset_prewarm(Defs.LEVELS[int(level_index)])


func _queue_global_boss_asset_prewarm() -> void:
	for level in Defs.LEVELS:
		_queue_level_boss_asset_prewarm(Dictionary(level))
	_queue_almanac_boss_asset_prewarm("zombies")


func _queue_almanac_boss_asset_prewarm(tab: String = "") -> void:
	var target_tab = tab if tab != "" else almanac_tab
	if target_tab != "zombies":
		return
	for kind in ["rumia_boss", "daiyousei_boss", "cirno_boss", "meiling_boss", "koakuma_boss", "patchouli_boss", "sakuya_boss", "remilia_boss"]:
		_queue_boss_frame_set_prewarm(kind)


func _load_single_boss_frame(kind: String, frame_index: int, face_left: bool) -> Texture2D:
	var resource_path = _boss_frame_resource_path(kind, frame_index)
	if resource_path == "":
		return null
	var image = Image.new()
	var path = ProjectSettings.globalize_path(resource_path)
	if image.load(path) != OK:
		return null
	if _boss_assets_are_preprocessed(kind):
		if face_left:
			image.flip_x()
		return ImageTexture.create_from_image(image)
	return ImageTexture.create_from_image(_prepare_boss_frame_image(image, face_left))


func _store_prewarmed_boss_frame(kind: String, frame_index: int, texture: Texture2D, face_left: bool) -> void:
	var expected_count = _boss_frame_count_for_kind(kind)
	if expected_count <= 0:
		return
	var shared_frames = _shared_boss_frames_for_kind(kind)
	if shared_frames.size() != expected_count or _shared_boss_frames_face_left_for_kind(kind) == null or bool(_shared_boss_frames_face_left_for_kind(kind)) != face_left:
		shared_frames = []
		shared_frames.resize(expected_count)
	if frame_index >= 0 and frame_index < expected_count:
		shared_frames[frame_index] = texture
	var loaded = _boss_frame_array_is_complete(shared_frames, expected_count)
	_set_shared_boss_frames_for_kind(kind, shared_frames, loaded, face_left)
	_set_instance_boss_frames_for_kind(kind, shared_frames, loaded, face_left)


func _run_asset_prewarm_task(task: Dictionary) -> void:
	match String(task.get("type", "")):
		"audio":
			_load_audio_stream(String(task.get("path", "")))
		"boss_frame":
			var kind = String(task.get("kind", ""))
			var frame_index = int(task.get("frame_index", -1))
			var face_left = bool(task.get("face_left", false))
			var texture = _load_single_boss_frame(kind, frame_index, face_left)
			_store_prewarmed_boss_frame(kind, frame_index, texture, face_left)


func _try_play_pending_bgm() -> void:
	if pending_bgm_path == "":
		return
	var stream = _try_get_cached_audio_stream(pending_bgm_path)
	if stream == null or not is_inside_tree():
		return
	_build_audio_player()
	if music_player == null:
		return
	current_bgm_path = pending_bgm_path
	music_player.stream = stream
	music_player.play()
	pending_bgm_path = ""


func _service_asset_prewarm_queue(step_count: int = 1) -> void:
	for _step in range(max(step_count, 0)):
		if asset_prewarm_queue.is_empty():
			break
		var task = Dictionary(asset_prewarm_queue[0])
		asset_prewarm_queue.remove_at(0)
		var task_key = String(task.get("key", ""))
		if task_key != "":
			asset_prewarm_keys.erase(task_key)
		_run_asset_prewarm_task(task)
	_try_play_pending_bgm()


func _drain_asset_prewarm_queue() -> void:
	while not asset_prewarm_queue.is_empty():
		_service_asset_prewarm_queue(1)


func _try_get_boss_frame_texture(kind: String, frame_index: int) -> Texture2D:
	if not _is_image_backed_hover_boss(kind):
		return null
	_sync_instance_boss_frames_from_shared(kind)
	var frames = _instance_boss_frames_for_kind(kind)
	if frame_index >= 0 and frame_index < frames.size() and frames[frame_index] != null:
		return frames[frame_index]
	_queue_boss_frame_set_prewarm(kind)
	return null


func _play_bgm(path: String) -> void:
	if path == "" or not is_inside_tree():
		return
	_build_audio_player()
	if current_bgm_path == path and music_player != null and music_player.playing:
		pending_bgm_path = ""
		return
	var stream = _try_get_cached_audio_stream(path)
	if stream == null:
		pending_bgm_path = path
		_queue_audio_stream_prewarm(path)
		return
	if stream == null or music_player == null:
		return
	pending_bgm_path = ""
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
		map_scroll_velocity_by_world[world_key] = 0.0


func _nudge_map_scroll(delta_x: float) -> void:
	map_scroll_velocity_by_world[current_world_key] = clampf(float(map_scroll_velocity_by_world.get(current_world_key, 0.0)) + delta_x * 3.2, -1800.0, 1800.0)
	_set_map_scroll(current_world_key, _map_scroll_value(current_world_key, true) + delta_x)


func _update_map_scroll(delta: float) -> void:
	if touch_navigation_dragging and touch_navigation_mode == MODE_MAP:
		return
	var current = _map_scroll_value(current_world_key)
	var target = _map_scroll_value(current_world_key, true)
	var velocity = float(map_scroll_velocity_by_world.get(current_world_key, 0.0))
	if absf(target - current) <= 0.25 and absf(velocity) <= 6.0:
		map_scroll_by_world[current_world_key] = target
		map_scroll_velocity_by_world[current_world_key] = 0.0
		return
	var spring = _spring_ui_value(current, target, velocity, delta, 44.0, 10.5, 0.22, 4.0)
	map_scroll_by_world[current_world_key] = float(spring.get("value", current))
	map_scroll_velocity_by_world[current_world_key] = float(spring.get("velocity", velocity))


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
	_begin_startup_loading()


func _finalize_campaign_init(load_succeeded: bool, had_existing_save: bool) -> void:
	save_dirty = false
	autosave_timer = 0.0
	if load_succeeded or had_existing_save:
		return
	_mark_save_dirty(true)


func _begin_startup_loading() -> void:
	asset_prewarm_queue.clear()
	asset_prewarm_keys.clear()
	startup_loading_total_tasks = 0
	startup_loading_completed_tasks = 0
	startup_loading_min_timer = 0.35
	_queue_global_boss_asset_prewarm()
	startup_loading_total_tasks = asset_prewarm_queue.size()
	startup_loading_active = startup_loading_total_tasks > 0


func _enter_world_select_mode(animated: bool = true) -> void:
	almanac_selected_kind = ""
	selected_tool = ""
	battle_paused = false
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
	battle_paused = false
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
	_queue_world_boss_asset_prewarm(current_world_key)
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
	world_select_velocity = 0.0
	if target_world != "":
		world_select_index = WorldDataLib.index_of(target_world)


func _shift_world_select(direction: int) -> void:
	var world_count = WorldDataLib.all().size()
	world_select_index = clampi(world_select_index + direction, 0, max(world_count - 1, 0))
	world_select_velocity = clampf(float(direction) * 1.6, -3.2, 3.2)


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
	if WORLD_SELECT_ENDLESS_RECT.has_point(mouse_pos):
		_enter_endless_mode()
		return
	if WORLD_SELECT_GACHA_RECT.has_point(mouse_pos):
		_enter_gacha_mode()
		return
	var enhance_rect = Rect2(WORLD_SELECT_GACHA_RECT.position.x, WORLD_SELECT_GACHA_RECT.position.y + 72.0, 200.0, 52.0)
	if enhance_rect.has_point(mouse_pos):
		_enter_enhance_mode()
		return
	if WORLD_SELECT_DAILY_RECT.has_point(mouse_pos):
		_enter_daily_challenge()
		return
	if WORLD_SELECT_UPDATE_RECT.has_point(mouse_pos) or WORLD_SELECT_UPDATE_INFO_RECT.has_point(mouse_pos):
		match update_state:
			"checking", "applying":
				_show_toast("更新流程进行中，请稍候")
			"latest", "idle":
				_begin_update_check()
			"available":
				var install_mode = String(update_release_info.get("install_mode", "desktop_replace"))
				if install_mode == "notify_only":
					_open_release_page()
				else:
					_start_update_download()
			"downloading":
				_show_toast("更新包下载中")
			"ready":
				_apply_or_open_downloaded_update()
			"error":
				_begin_update_check()
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


func _handle_map_click(mouse_pos: Vector2) -> void:
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


func _handle_gacha_click(mouse_pos: Vector2) -> void:
	# Back button
	var back_rect = Rect2(40.0, 40.0, 120.0, 52.0)
	if back_rect.has_point(mouse_pos):
		_enter_world_select_mode()
		return
	# Standard single draw
	var single_rect = Rect2(size.x * 0.5 - 360.0, 140.0, 220.0, 72.0)
	if single_rect.has_point(mouse_pos):
		_do_gacha_draw(1)
		return
	# Premium single draw
	var premium_rect = Rect2(size.x * 0.5 - 110.0, 140.0, 220.0, 72.0)
	if premium_rect.has_point(mouse_pos):
		_do_gacha_draw(1)
		return
	# Multi draw
	var multi_rect = Rect2(size.x * 0.5 + 140.0, 140.0, 220.0, 72.0)
	if multi_rect.has_point(mouse_pos):
		_do_gacha_draw(10)
		return
	# Reveal next card on click
	if gacha_draw_results.size() > 0 and gacha_reveal_index < gacha_draw_results.size():
		gacha_reveal_index += 1
		queue_redraw()
		return


func _enhance_panel_rect() -> Rect2:
	return Rect2(size.x - 380.0, 130.0, 340.0, 520.0)


func _enhance_owned_plants() -> Array:
	var owned_plants: Array = []
	for pk in Defs.PLANTS.keys():
		if plant_stars.has(pk) or not bool(Defs.PLANTS[pk].get("gacha_only", false)):
			owned_plants.append(pk)
	return owned_plants


func _enhance_grid_layout() -> Dictionary:
	var col_x = 40.0
	var col_y = 130.0
	var col_w = 86.0
	var col_h = 110.0
	var col_gap = 8.0
	var panel_rect = _enhance_panel_rect()
	var usable_width = maxf(col_w, panel_rect.position.x - col_x - 24.0)
	var cols_per_row = maxi(1, int(floor((usable_width + col_gap) / (col_w + col_gap))))
	return {
		"col_x": col_x,
		"col_y": col_y,
		"col_w": col_w,
		"col_h": col_h,
		"col_gap": col_gap,
		"cols_per_row": cols_per_row,
	}


func _enhance_cell_rect(index: int) -> Rect2:
	var layout = _enhance_grid_layout()
	var col_x = float(layout["col_x"])
	var col_y = float(layout["col_y"])
	var col_w = float(layout["col_w"])
	var col_h = float(layout["col_h"])
	var col_gap = float(layout["col_gap"])
	var cols_per_row = int(layout["cols_per_row"])
	var cx = col_x + float(index % cols_per_row) * (col_w + col_gap)
	var cy = col_y + floor(float(index) / float(cols_per_row)) * (col_h + col_gap)
	return Rect2(cx, cy, col_w, col_h)


func _enhance_button_rect() -> Rect2:
	var panel_rect = _enhance_panel_rect()
	return Rect2(panel_rect.position.x + 60.0, panel_rect.position.y + 360.0, 220.0, 56.0)


func _enhance_stone_button_rect() -> Rect2:
	var panel_rect = _enhance_panel_rect()
	return Rect2(panel_rect.position.x + 60.0, panel_rect.position.y + 430.0, 220.0, 48.0)


func _custom_level_template(world_key: String) -> Dictionary:
	var template_index = _world_start_index(world_key)
	if template_index >= 0 and template_index < Defs.LEVELS.size():
		var template_level = Dictionary(Defs.LEVELS[template_index]).duplicate(true)
		return {
			"id": "",
			"title": "",
			"description": "",
			"terrain": String(template_level.get("terrain", world_key)),
			"world": world_key,
			"mode": "",
			"start_sun": int(template_level.get("start_sun", 150)),
			"sky_sun_range": template_level.get("sky_sun_range", Vector2(6.0, 11.0)),
			"events": [],
			"available_plants": [],
			"row_count": int(template_level.get("row_count", 5)),
			"water_rows": template_level.get("water_rows", []).duplicate(),
			"time_scale": float(template_level.get("time_scale", 1.0)),
			"fog_columns": float(template_level.get("fog_columns", 0.0)),
			"cell_terrain_mask": template_level.get("cell_terrain_mask", []).duplicate(),
		}
	if not Defs.LEVELS.is_empty():
		var fallback_level = Dictionary(Defs.LEVELS[0]).duplicate(true)
		return {
			"id": "",
			"title": "",
			"description": "",
			"terrain": String(fallback_level.get("terrain", world_key)),
			"world": world_key,
			"mode": "",
			"start_sun": int(fallback_level.get("start_sun", 150)),
			"sky_sun_range": fallback_level.get("sky_sun_range", Vector2(6.0, 11.0)),
			"events": [],
			"available_plants": [],
			"row_count": int(fallback_level.get("row_count", 5)),
			"water_rows": fallback_level.get("water_rows", []).duplicate(),
			"time_scale": float(fallback_level.get("time_scale", 1.0)),
			"fog_columns": float(fallback_level.get("fog_columns", 0.0)),
			"cell_terrain_mask": fallback_level.get("cell_terrain_mask", []).duplicate(),
		}
	return {
		"id": "",
		"title": "",
		"description": "",
		"terrain": world_key,
		"world": world_key,
		"mode": "",
		"start_sun": 150,
		"sky_sun_range": Vector2(6.0, 11.0),
		"events": [],
		"available_plants": [],
		"row_count": 5,
		"water_rows": [],
	}


func _build_custom_level(world_key: String, level_id: String, title: String, description: String, extra: Dictionary = {}) -> Dictionary:
	var level = _custom_level_template(world_key)
	level["id"] = level_id
	level["title"] = title
	level["description"] = description
	level["world"] = world_key
	level["terrain"] = String(level.get("terrain", world_key))
	level["events"] = []
	level["available_plants"] = _player_plant_collection()
	level["custom_level"] = true
	level["unlock_plant"] = ""
	for key in extra.keys():
		level[key] = extra[key]
	if not level.has("start_sun"):
		level["start_sun"] = 150
	if not level.has("sky_sun_range"):
		level["sky_sun_range"] = Vector2(6.0, 11.0)
	if not level.has("row_count"):
		level["row_count"] = 5
	if not level.has("water_rows"):
		level["water_rows"] = []
	return level


func _resolved_selection_pool_for_level(level: Dictionary) -> Array:
	var pool: Array = []
	var seen := {}
	for kind_variant in _available_seed_cards_for_level(level):
		var kind = String(kind_variant)
		if kind == "" or seen.has(kind) or not Defs.PLANTS.has(kind):
			continue
		seen[kind] = true
		pool.append(kind)
	if pool.is_empty():
		for kind_variant in _player_plant_collection():
			var fallback_kind = String(kind_variant)
			if fallback_kind == "" or seen.has(fallback_kind) or not Defs.PLANTS.has(fallback_kind):
				continue
			seen[fallback_kind] = true
			pool.append(fallback_kind)
	if pool.is_empty() and Defs.PLANTS.has("peashooter"):
		pool.append("peashooter")
	return pool


func _ensure_selection_scene_ready() -> void:
	if mode != MODE_SELECTION:
		return
	if selection_pool_cards.is_empty():
		selection_pool_cards = _resolved_selection_pool_for_level(current_level)
		selection_pool_scroll = 0.0


func _selection_selected_panel_rect() -> Rect2:
	var rect = PREP_SELECTED_PANEL_RECT
	rect.position.y = maxf(rect.position.y, 144.0)
	rect.size.x = maxf(760.0, minf(rect.size.x, size.x - rect.position.x - 24.0))
	return rect


func _selection_zombie_panel_rect() -> Rect2:
	var rect = PREP_ZOMBIE_PANEL_RECT
	rect.position.y = _selection_selected_panel_rect().end.y + 10.0
	rect.size.x = _selection_selected_panel_rect().size.x
	return rect


func _selection_pool_panel_rect() -> Rect2:
	var rect = PREP_POOL_PANEL_RECT
	rect.position.y = _selection_zombie_panel_rect().end.y + 12.0
	rect.size.x = _selection_selected_panel_rect().size.x
	var max_height = size.y - rect.position.y - 24.0
	rect.size.y = clampf(max_height, 188.0, 420.0)
	return rect


func _selection_footer_rect() -> Rect2:
	var pool_panel_rect = _selection_pool_panel_rect()
	return Rect2(
		pool_panel_rect.position.x + 18.0,
		pool_panel_rect.end.y - 56.0,
		pool_panel_rect.size.x - 36.0,
		40.0
	)


func _selection_back_rect() -> Rect2:
	var footer_rect = _selection_footer_rect()
	return Rect2(
		footer_rect.position.x + footer_rect.size.x - 298.0,
		footer_rect.position.y - 2.0,
		122.0,
		44.0
	)


func _selection_start_rect() -> Rect2:
	var footer_rect = _selection_footer_rect()
	return Rect2(
		footer_rect.position.x + footer_rect.size.x - 162.0,
		footer_rect.position.y - 2.0,
		148.0,
		44.0
	)


func _handle_enhance_click(mouse_pos: Vector2) -> void:
	var back_rect = Rect2(40.0, 40.0, 120.0, 52.0)
	if back_rect.has_point(mouse_pos):
		_enter_world_select_mode()
		return

	if enhance_selected_plant != "":
		var elevel = int(plant_enhance_levels.get(enhance_selected_plant, 0))
		if elevel < 15:
			if _enhance_button_rect().has_point(mouse_pos) or _enhance_stone_button_rect().has_point(mouse_pos):
				_try_enhance_plant(enhance_selected_plant)
				return

	var owned_plants = _enhance_owned_plants()
	for i in range(owned_plants.size()):
		var cell_rect = _enhance_cell_rect(i)
		if cell_rect.position.y > size.y - 80.0:
			continue
		if cell_rect.has_point(mouse_pos):
			enhance_selected_plant = String(owned_plants[i])
			queue_redraw()
			return


func _enter_enhance_mode() -> void:
	enhance_selected_plant = ""
	mode = MODE_ENHANCE
	queue_redraw()


func _start_level(level_index: int) -> void:
	selected_level_index = level_index
	var level = Defs.LEVELS[level_index]
	_queue_level_boss_asset_prewarm(level)
	if _requires_seed_selection(level):
		_enter_seed_selection(level_index)
		return
	_begin_level(level_index, _default_level_cards(level))


func _enter_almanac_mode(initial_tab: String = "plants") -> void:
	almanac_return_mode = mode
	mode = MODE_ALMANAC
	almanac_tab = initial_tab
	almanac_scroll = 0.0
	_queue_almanac_boss_asset_prewarm(initial_tab)
	_ensure_almanac_selection()
	queue_redraw()


func _today_string() -> String:
	var dt = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


func _is_endless_level() -> bool:
	return String(current_level.get("id", "")) == "无尽"


func _enter_endless_mode() -> void:
	endless_wave = 0
	endless_difficulty_mult = 1.0
	endless_wave_timer = 0.0
	endless_wave_active = false
	endless_zombies_remaining = 0
	current_world_key = "day"
	selected_level_index = -1
	current_level = _build_custom_level("day", "无尽", "无尽模式", "白天草坪的尸潮不会停止，每一波都会更强。", {
		"events": [],
		"available_plants": _player_plant_collection(),
		"start_sun": 250,
		"sky_sun_range": Vector2(5.0, 10.0),
		"row_count": 5,
	})
	mode = MODE_SELECTION
	battle_state = BATTLE_PLAYING
	battle_paused = false
	panel_action = ""
	message_panel.visible = false
	selected_tool = ""
	active_rows = _build_active_rows(int(current_level.get("row_count", ROWS)))
	active_cards = []
	selection_pool_cards = _resolved_selection_pool_for_level(current_level)
	selection_cards = []
	selection_pool_scroll = 0.0
	queue_redraw()


func _normal_zombie_spawn_x() -> float:
	return BOARD_ORIGIN.x + board_size.x + 92.0


func _random_normal_zombie_spawn_x() -> float:
	return _normal_zombie_spawn_x() + rng.randf_range(-12.0, 18.0)


func _endless_spawn_candidate_kinds() -> Array:
	var candidates: Array = []
	for kind_variant in ZOMBIE_ALMANAC_ORDER:
		var kind = String(kind_variant)
		if kind == "" or not Defs.ZOMBIES.has(kind):
			continue
		if _is_boss_kind(kind):
			continue
		if kind == "bobsled_team" and not _endless_board_supports_bobsled():
			continue
		candidates.append(kind)
	return candidates


func _endless_board_supports_bobsled() -> bool:
	for row_variant in active_rows:
		if _row_has_ice(int(row_variant)):
			return true
	return false


func _start_endless_wave() -> void:
	endless_wave += 1
	endless_difficulty_mult = 1.0 + float(endless_wave - 1) * 0.18
	endless_wave_active = true
	endless_zombies_remaining = 0
	var zombie_count = 3 + endless_wave * 2
	var available_kinds = _endless_spawn_candidate_kinds()
	if available_kinds.is_empty():
		available_kinds = ["normal"]
	var wave_rng = RandomNumberGenerator.new()
	wave_rng.seed = hash(endless_wave * 7919)
	for i in range(zombie_count):
		var kind = String(available_kinds[wave_rng.randi_range(0, available_kinds.size() - 1)])
		var row = _choose_spawn_row_for_kind(kind)
		if row < 0:
			continue
		var lane_offset = float(i % 4) * 10.0
		var spawn_x = _normal_zombie_spawn_x() + lane_offset + wave_rng.randf_range(-8.0, 12.0)
		var previous_count = zombies.size()
		_spawn_zombie_at(kind, row, spawn_x)
		if zombies.size() <= previous_count:
			continue
		var zombie = zombies[zombies.size() - 1]
		var health_mult = endless_difficulty_mult
		zombie["health"] = float(zombie.get("health", float(Defs.ZOMBIES[kind]["health"]))) * health_mult
		zombie["max_health"] = float(zombie.get("max_health", float(Defs.ZOMBIES[kind]["health"]))) * health_mult
		if float(zombie.get("shield_health", 0.0)) > 0.0:
			zombie["shield_health"] = float(zombie.get("shield_health", 0.0)) * health_mult
			zombie["max_shield_health"] = float(zombie.get("max_shield_health", 0.0)) * health_mult
		zombies[zombies.size() - 1] = zombie
		endless_zombies_remaining += 1
	queue_redraw()


func _update_endless(delta: float) -> void:
	if mode != MODE_BATTLE or not current_level.get("id", "") == "无尽":
		return
	if not endless_wave_active:
		endless_wave_timer += delta
		if endless_wave_timer >= 6.0:
			endless_wave_timer = 0.0
			_start_endless_wave()
			# Bonus sun every 5 waves
			if endless_wave % 5 == 0:
				sun_points += 150
				_show_toast("第 %d 波! 奖励 150 阳光!" % endless_wave)
	else:
		var alive = _enemy_zombie_count()
		if alive == 0:
			endless_wave_active = false
			endless_wave_timer = 0.0
			if endless_wave > endless_best_wave:
				endless_best_wave = endless_wave


func _enter_gacha_mode() -> void:
	gacha_draw_results = []
	gacha_reveal_index = -1
	gacha_reveal_timer = 0.0
	gacha_mode_scroll = 0.0
	mode = MODE_GACHA
	queue_redraw()


func _gacha_plant_rarity(kind: String) -> String:
	var cost = int(Defs.PLANTS[kind].get("cost", 100))
	if cost >= 300:
		return "legendary"
	elif cost >= 175:
		return "epic"
	elif cost >= 100:
		return "rare"
	return "common"


func _gacha_rarity_color(rarity: String) -> Color:
	match rarity:
		"legendary":
			return Color(1.0, 0.72, 0.12)
		"epic":
			return Color(0.72, 0.36, 0.92)
		"rare":
			return Color(0.28, 0.68, 0.96)
		_:
			return Color(0.72, 0.78, 0.72)


func _do_gacha_draw(count: int) -> void:
	var is_premium = count >= 10 or count == -1
	var cost = 200 * count if count > 0 and is_premium else (50 * count if count > 0 else 1800)
	if count == 10:
		cost = 1800
	if count == 1 and not is_premium:
		cost = 50
	if coins_total < cost:
		_show_toast("金币不足! 需要 %d 金币" % cost)
		return
	coins_total -= cost
	gacha_draw_results = []
	gacha_reveal_index = 0
	gacha_reveal_timer = 0.0
	var actual_count = 10 if count == 10 else count
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var guaranteed_orange_plus = (actual_count >= 10)
	var got_orange_plus = false
	# Gacha plant pools
	var purple_plants = ["shadow_pea", "ice_queen", "vine_emperor", "soul_flower", "prism_pea", "magnet_daisy", "thorn_cactus", "bubble_lotus", "spiral_bamboo", "honey_blossom", "echo_fern", "glow_ivy"]
	var orange_plants = ["plasma_shooter", "crystal_nut", "dragon_fruit", "time_rose", "laser_lily", "rock_armor_fruit", "aurora_orchid", "blast_pomegranate", "frost_cypress", "mirror_shroom", "chain_lotus", "plasma_shroom"]
	var gold_plants = ["galaxy_sunflower", "void_shroom", "phoenix_tree", "thunder_god", "meteor_flower", "destiny_tree", "abyss_tentacle", "solar_emperor", "shadow_assassin", "core_blossom", "holy_lotus", "chaos_shroom"]
	for i in range(actual_count):
		gacha_pity_counter += 1
		var roll = rng.randf()
		# Soft pity at 40, hard pity at 80
		var gold_rate = 0.03
		var orange_rate = 0.12
		if gacha_pity_counter >= 80:
			gold_rate = 1.0
		elif gacha_pity_counter >= 40:
			gold_rate = 0.06
			orange_rate = 0.24
		# Force orange+ on last card of 10-draw if none yet
		if guaranteed_orange_plus and i == actual_count - 1 and not got_orange_plus:
			if roll >= gold_rate:
				roll = rng.randf() * orange_rate
		var result = {}
		if roll < gold_rate:
			# Gold card
			var chosen = gold_plants[rng.randi_range(0, gold_plants.size() - 1)]
			var is_new = not plant_stars.has(chosen)
			if is_new:
				plant_stars[chosen] = 1
				plant_fragments[chosen] = 0
			else:
				plant_fragments[chosen] = int(plant_fragments.get(chosen, 0)) + 3
			result = {"kind": chosen, "rarity": "gold", "is_new": is_new, "type": "plant"}
			gacha_pity_counter = 0
			got_orange_plus = true
		elif roll < gold_rate + orange_rate:
			# Orange card
			var chosen = orange_plants[rng.randi_range(0, orange_plants.size() - 1)]
			var is_new = not plant_stars.has(chosen)
			if is_new:
				plant_stars[chosen] = 1
				plant_fragments[chosen] = 0
			else:
				plant_fragments[chosen] = int(plant_fragments.get(chosen, 0)) + 2
			result = {"kind": chosen, "rarity": "orange", "is_new": is_new, "type": "plant"}
			got_orange_plus = true
		elif roll < gold_rate + orange_rate + 0.30:
			# Purple card
			var chosen = purple_plants[rng.randi_range(0, purple_plants.size() - 1)]
			var is_new = not plant_stars.has(chosen)
			if is_new:
				plant_stars[chosen] = 1
				plant_fragments[chosen] = 0
			else:
				plant_fragments[chosen] = int(plant_fragments.get(chosen, 0)) + 1
			result = {"kind": chosen, "rarity": "purple", "is_new": is_new, "type": "plant"}
		elif roll < gold_rate + orange_rate + 0.30 + 0.15:
			# Enhancement stone
			enhance_stones += 1
			result = {"kind": "enhance_stone", "rarity": "rare", "is_new": false, "type": "item", "name": "强化石"}
		elif roll < gold_rate + orange_rate + 0.30 + 0.15 + 0.35:
			# Green fragments
			var random_green = Defs.PLANTS.keys()
			var green_list: Array = []
			for pk in random_green:
				if not bool(Defs.PLANTS[pk].get("gacha_only", false)):
					green_list.append(pk)
			var chosen = String(green_list[rng.randi_range(0, green_list.size() - 1)])
			plant_fragments[chosen] = int(plant_fragments.get(chosen, 0)) + 5
			result = {"kind": chosen, "rarity": "common", "is_new": false, "type": "fragment", "name": "%s碎片x5" % String(Defs.PLANTS[chosen]["name"])}
		else:
			# Junk
			coins_total += 10
			var junk_texts = ["一堆杂草", "空花盆", "僵尸的领带", "过期肥料", "破损的铲子"]
			result = {"kind": "junk", "rarity": "junk", "is_new": false, "type": "junk", "name": junk_texts[rng.randi_range(0, junk_texts.size() - 1)]}
		gacha_draw_results.append(result)
	_mark_save_dirty(true)
	queue_redraw()


func _enter_daily_challenge() -> void:
	var today = _today_string()
	var reward_claimed_today = daily_challenge_date == today
	if reward_claimed_today:
		_show_toast("今日奖励已领取，可继续重玩练习")
	# Generate daily challenge from date seed
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(today)
	var worlds = ["day", "night", "pool", "fog", "roof"]
	var world_key = worlds[rng.randi_range(0, worlds.size() - 1)]
	current_world_key = world_key
	# Pick modifiers
	daily_modifiers = []
	var all_mods = [
		{"id": "costly", "name": "高消费", "desc": "植物费用+50%"},
		{"id": "fast_zombie", "name": "急速尸潮", "desc": "僵尸速度x1.5"},
		{"id": "rich_start", "name": "富裕开局", "desc": "初始500阳光"},
		{"id": "tough_zombie", "name": "铁壁尸潮", "desc": "僵尸血量x2"},
		{"id": "sun_drought", "name": "阳光干旱", "desc": "天降阳光减半"},
		{"id": "speed_plant", "name": "快速装填", "desc": "冷却时间减半"},
	]
	var mod_count = rng.randi_range(1, 2)
	for i in range(mod_count):
		var mod_index = rng.randi_range(0, all_mods.size() - 1)
		daily_modifiers.append(all_mods[mod_index])
		all_mods.remove_at(mod_index)
		if all_mods.is_empty():
			break
	# Build a daily level
	var rows = [0, 1, 2, 3, 4]
	var zombie_count = rng.randi_range(20, 35)
	var events: Array = []
	var available_kinds = ["normal", "conehead", "buckethead", "pole_vault", "newspaper"]
	if world_key == "night":
		available_kinds.append("screen_door")
	if world_key == "pool" or world_key == "fog":
		available_kinds.append("football")
	for i in range(zombie_count):
		var kind = available_kinds[rng.randi_range(0, available_kinds.size() - 1)]
		var row = rng.randi_range(0, rows.size() - 1)
		events.append({"type": "zombie", "kind": kind, "row": rows[row], "time": 8.0 + float(i) * 3.2 + rng.randf_range(0.0, 2.0)})
	events.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))
	var start_sun = 150
	for mod in daily_modifiers:
		if String(mod["id"]) == "rich_start":
			start_sun = 500
	var modifier_desc = ""
	for mod in daily_modifiers:
		if modifier_desc != "":
			modifier_desc += " / "
		modifier_desc += String(mod["name"])
	selected_level_index = -1
	current_level = _build_custom_level(world_key, "每日", "每日挑战", "世界: %s  修饰: %s" % [_map_mode_title_for_world(world_key), modifier_desc], {
		"events": events,
		"available_plants": _player_plant_collection(),
		"start_sun": start_sun,
		"row_count": rows.size(),
	})
	mode = MODE_SELECTION
	battle_state = BATTLE_PLAYING
	panel_action = ""
	message_panel.visible = false
	selected_tool = ""
	active_cards = []
	active_rows = _build_active_rows(int(current_level.get("row_count", ROWS)))
	selection_pool_cards = _resolved_selection_pool_for_level(current_level)
	selection_cards = []
	selection_pool_scroll = 0.0
	daily_completed_today = reward_claimed_today
	queue_redraw()


func _enter_seed_selection(level_index: int) -> void:
	selected_level_index = level_index
	current_level = Defs.LEVELS[level_index]
	_queue_level_boss_asset_prewarm(current_level)
	mode = MODE_SELECTION
	battle_state = BATTLE_PLAYING
	battle_paused = false
	panel_action = ""
	message_panel.visible = false
	selected_tool = ""
	active_cards = []
	active_rows = _build_active_rows(int(current_level.get("row_count", ROWS)))
	selection_pool_cards = _resolved_selection_pool_for_level(current_level)
	selection_cards = []
	selection_pool_scroll = 0.0
	queue_redraw()


func _apply_daily_modifiers(_delta: float) -> void:
	if current_level.get("id", "") != "每日":
		return
	for mod in daily_modifiers:
		match String(mod["id"]):
			"speed_plant":
				for kind in active_cards:
					if kind == "" or not card_cooldowns.has(kind):
						continue
					card_cooldowns[kind] = maxf(0.0, float(card_cooldowns[kind]) - _delta * 0.5)


func _daily_cost_multiplier() -> float:
	if current_level.get("id", "") != "每日":
		return 1.0
	for mod in daily_modifiers:
		if String(mod["id"]) == "costly":
			return 1.5
	return 1.0


func _daily_zombie_speed_mult() -> float:
	if current_level.get("id", "") != "每日":
		return 1.0
	for mod in daily_modifiers:
		if String(mod["id"]) == "fast_zombie":
			return 1.5
	return 1.0


func _daily_zombie_health_mult() -> float:
	if current_level.get("id", "") != "每日":
		return 1.0
	for mod in daily_modifiers:
		if String(mod["id"]) == "tough_zombie":
			return 2.0
	return 1.0


	return 1.0


func _get_enhance_multiplier(kind: String) -> float:
	var level = int(plant_enhance_levels.get(kind, 0))
	if level <= 0:
		return 1.0
	var total_boost = 0.0
	for i in range(mini(level, ENHANCE_TABLE.size())):
		total_boost += float(ENHANCE_TABLE[i]["boost"])
	return 1.0 + total_boost


func _get_enhance_attack_speed_multiplier(kind: String) -> float:
	var boost = _get_enhance_multiplier(kind) - 1.0
	if boost <= 0.0:
		return 1.0
	return 1.0 + boost * 0.9


func _enhanced_plant_stats(kind: String) -> Dictionary:
	var stats: Dictionary = Dictionary(Defs.PLANTS[kind]).duplicate(true)
	var enhance_mult = _get_enhance_multiplier(kind)
	if enhance_mult <= 1.0:
		return stats
	var attack_speed_mult = _get_enhance_attack_speed_multiplier(kind)
	if stats.has("health"):
		stats["health"] = float(stats["health"]) * enhance_mult
	for key_variant in ENHANCE_DAMAGE_KEYS:
		var key = String(key_variant)
		if stats.has(key):
			stats[key] = float(stats[key]) * enhance_mult
	for key_variant in ENHANCE_INTERVAL_KEYS:
		var key = String(key_variant)
		if stats.has(key):
			stats[key] = maxf(0.05, float(stats[key]) / attack_speed_mult)
	return stats


func _plant_enhance_multiplier_at_cell(row: int, col: int) -> float:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return 1.0
	var plant = _top_plant_at(row, col)
	if plant == null:
		plant = _support_plant_at(row, col)
	if plant == null:
		return 1.0
	var base = float(plant.get("enhance_damage_mult", _get_enhance_multiplier(String(plant.get("kind", "")))))
	if float(plant.get("aurora_buff_timer", 0.0)) > 0.0:
		base *= (1.0 + float(plant.get("aurora_buff_ratio", 0.0)))
	if float(plant.get("destiny_dmg_timer", 0.0)) > 0.0:
		base *= 1.5
	return base


func _plant_enhance_attack_speed_at_cell(row: int, col: int) -> float:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return 1.0
	var plant = _top_plant_at(row, col)
	if plant == null:
		plant = _support_plant_at(row, col)
	if plant == null:
		return 1.0
	var base = float(plant.get("enhance_attack_speed_mult", _get_enhance_attack_speed_multiplier(String(plant.get("kind", "")))))
	if float(plant.get("destiny_speed_timer", 0.0)) > 0.0:
		base *= 1.5
	return base


func _projectile_damage_multiplier_for_spawn(row: int, spawn_position: Vector2, fallback_kind: String = "") -> float:
	var best_kind := fallback_kind
	var best_score := INF
	for lane in range(max(0, row - 1), min(ROWS, row + 2)):
		for col in range(COLS):
			for candidate_variant in [grid[lane][col], support_grid[lane][col]]:
				if candidate_variant == null:
					continue
				var candidate = candidate_variant
				var candidate_kind = String(candidate.get("kind", ""))
				if candidate_kind == "":
					continue
				var center = _cell_center(lane, col)
				var dx = absf(center.x - spawn_position.x)
				if dx > CELL_SIZE.x * 1.15:
					continue
				var score = dx + absf(float(lane - row)) * 24.0
				if score < best_score:
					best_score = score
					best_kind = candidate_kind
	if best_kind == "":
		return 1.0
	return _get_enhance_multiplier(best_kind)


func _try_enhance_plant(kind: String) -> void:
	var level = int(plant_enhance_levels.get(kind, 0))
	if level >= 15:
		_show_toast("已达最高强化等级!")
		return
	var table = ENHANCE_TABLE[level]
	var cost = int(table["cost"])
	var frag_cost = int(table["frag_cost"])
	var frags = int(plant_fragments.get(kind, 0))
	if coins_total < cost:
		_show_toast("金币不足! 需要 %d" % cost)
		return
	if frag_cost > 0 and frags < frag_cost:
		_show_toast("碎片不足! 需要 %d" % frag_cost)
		return
	coins_total -= cost
	if frag_cost > 0:
		plant_fragments[kind] = frags - frag_cost
	# Use enhance stone for guaranteed success
	var rate = float(table["rate"])
	var use_stone = false
	if enhance_stones > 0 and rate < 1.0:
		enhance_stones -= 1
		use_stone = true
		rate = 1.0
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() < rate:
		plant_enhance_levels[kind] = level + 1
		_show_toast("强化成功! +%d" % (level + 1))
		if use_stone:
			_show_toast("(使用了强化石)")
	else:
		var penalty = int(table["penalty"])
		if penalty > 0 and level > 0:
			plant_enhance_levels[kind] = maxi(0, level - penalty)
			_show_toast("强化失败! 降级至 +%d" % maxi(0, level - penalty))
		else:
			_show_toast("强化失败!")
	_mark_save_dirty(true)
	queue_redraw()


func _draw_enhancement_aura(center: Vector2, kind: String) -> void:
	var level = int(plant_enhance_levels.get(kind, 0))
	if level <= 0:
		return
	var pulse = sin(level_time * 3.0) * 0.15
	if level <= 5:
		draw_circle(center, 36.0 + pulse * 8.0, Color(1.0, 1.0, 1.0, 0.06 + pulse * 0.02))
	elif level <= 10:
		draw_circle(center, 38.0 + pulse * 10.0, Color(0.36, 0.62, 1.0, 0.08 + pulse * 0.03))
		draw_circle(center, 34.0, Color(0.36, 0.62, 1.0, 0.04))
	elif level <= 14:
		draw_circle(center, 40.0 + pulse * 12.0, Color(0.72, 0.36, 0.92, 0.1 + pulse * 0.04))
		draw_circle(center, 36.0, Color(0.72, 0.36, 0.92, 0.06))
	else:
		# MAX level golden aura
		ThemeLib.draw_glow_circle(self, center, 38.0 + pulse * 14.0, Color(1.0, 0.86, 0.2, 0.12 + pulse * 0.05), 3)


func _draw_enhance_scene() -> void:
	ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, size), Color(0.08, 0.06, 0.14), Color(0.04, 0.03, 0.08))
	# Title
	var title_rect = Rect2(size.x * 0.5 - 180.0, 30.0, 360.0, 72.0)
	_draw_panel_shell(title_rect, Color(0.62, 0.36, 0.82, 0.96), Color(0.38, 0.18, 0.52), 0.2, 0.12)
	_draw_text("植物强化", title_rect.position + Vector2(112.0, 46.0), 32, Color(1.0, 0.96, 1.0))
	# Coin + stone display
	_draw_panel_shell(Rect2(size.x - 280.0, 40.0, 240.0, 52.0), Color(1.0, 0.92, 0.54), Color(0.55, 0.41, 0.08), 0.12, 0.06)
	_draw_text("金币: %d" % coins_total, Vector2(size.x - 256.0, 72.0), 20, Color(0.33, 0.21, 0.04))
	_draw_text("强化石: %d" % enhance_stones, Vector2(size.x - 256.0, 92.0), 16, Color(0.33, 0.21, 0.04))
	# Plant grid
	var layout = _enhance_grid_layout()
	var owned_plants = _enhance_owned_plants()
	for i in range(owned_plants.size()):
		var pk = String(owned_plants[i])
		var cell_rect = _enhance_cell_rect(i)
		if cell_rect.position.y > size.y - 80.0:
			continue
		var is_selected = pk == enhance_selected_plant
		var border_color = Color(0.82, 0.62, 0.18) if is_selected else Color(0.38, 0.32, 0.48)
		_draw_panel_shell(cell_rect, Color(0.16, 0.12, 0.24, 0.92), border_color, 0.1, 0.06)
		_draw_card_icon(pk, cell_rect.position + Vector2(cell_rect.size.x * 0.5, 48.0))
		var elevel = int(plant_enhance_levels.get(pk, 0))
		if elevel > 0:
			_draw_text("+%d" % elevel, cell_rect.position + Vector2(4.0, float(layout["col_h"]) - 4.0), 14, Color(0.82, 0.72, 0.18))
		# Rarity indicator
		var rarity = String(Defs.PLANTS[pk].get("rarity", "green"))
		var rarity_color = _gacha_rarity_color(rarity) if rarity != "green" else Color(0.52, 0.72, 0.42)
		draw_rect(Rect2(cell_rect.position + Vector2(0.0, 0.0), Vector2(cell_rect.size.x, 3.0)), rarity_color, true)
	# Enhancement panel (right side)
	if enhance_selected_plant != "":
		var panel_rect = _enhance_panel_rect()
		_draw_panel_shell(panel_rect, Color(0.14, 0.1, 0.22, 0.96), Color(0.42, 0.32, 0.56), 0.16, 0.08)
		var pk = enhance_selected_plant
		var data = Defs.PLANTS[pk]
		_draw_card_icon(pk, panel_rect.position + Vector2(170.0, 80.0))
		_draw_text(String(data["name"]), panel_rect.position + Vector2(120.0, 120.0), 24, Color(0.92, 0.88, 0.96))
		var elevel = int(plant_enhance_levels.get(pk, 0))
		_draw_text("强化等级: +%d / 15" % elevel, panel_rect.position + Vector2(20.0, 160.0), 18, Color(0.78, 0.72, 0.86))
		var mult = _get_enhance_multiplier(pk)
		_draw_text("属性加成: x%.2f" % mult, panel_rect.position + Vector2(20.0, 190.0), 16, Color(0.72, 0.82, 0.62))
		if elevel < 15:
			var table = ENHANCE_TABLE[elevel]
			_draw_text("费用: %d 金币" % int(table["cost"]), panel_rect.position + Vector2(20.0, 230.0), 16, Color(0.82, 0.78, 0.62))
			if int(table["frag_cost"]) > 0:
				_draw_text("碎片: %d / %d" % [int(plant_fragments.get(pk, 0)), int(table["frag_cost"])], panel_rect.position + Vector2(20.0, 256.0), 16, Color(0.82, 0.78, 0.62))
			_draw_text("成功率: %d%%" % int(float(table["rate"]) * 100.0), panel_rect.position + Vector2(20.0, 282.0), 16, Color(0.72, 0.82, 0.62) if float(table["rate"]) >= 0.6 else Color(0.92, 0.52, 0.42))
			if int(table["penalty"]) > 0:
				_draw_text("失败降级: -%d" % int(table["penalty"]), panel_rect.position + Vector2(20.0, 308.0), 16, Color(0.92, 0.42, 0.36))
			# Enhance button
			var btn_rect = _enhance_button_rect()
			_draw_panel_shell(btn_rect, Color(0.72, 0.36, 0.92), Color(0.48, 0.22, 0.62), 0.18, 0.1)
			_draw_text("强化!", btn_rect.position + Vector2(80.0, 36.0), 24, Color(1.0, 0.96, 1.0))
			if enhance_stones > 0:
				var stone_btn = _enhance_stone_button_rect()
				_draw_panel_shell(stone_btn, Color(0.82, 0.62, 0.18), Color(0.52, 0.36, 0.08), 0.14, 0.08)
				_draw_text("使用强化石", stone_btn.position + Vector2(52.0, 32.0), 20, Color(1.0, 0.96, 0.86))
		else:
			_draw_text("已达最高等级!", panel_rect.position + Vector2(80.0, 260.0), 22, Color(1.0, 0.86, 0.2))
	# Back button
	var back_rect = Rect2(40.0, 40.0, 120.0, 52.0)
	_draw_panel_shell(back_rect, Color(0.56, 0.52, 0.62), Color(0.36, 0.32, 0.42), 0.14, 0.08)
	_draw_text("返回", back_rect.position + Vector2(36.0, 34.0), 22, Color(0.96, 0.94, 0.98))


func _begin_level(level_index: int, chosen_cards: Array, level_override: Dictionary = {}) -> void:
	selected_level_index = level_index
	if not level_override.is_empty():
		current_level = level_override.duplicate(true)
	elif level_index >= 0 and level_index < Defs.LEVELS.size():
		current_level = Defs.LEVELS[level_index]
	else:
		current_level = current_level.duplicate(true)
	conveyor_source_cards = []
	frozen_branch_post_freeze_cards = []
	selection_cards = []
	selection_pool_cards = []
	board_rows = clampi(max(DEFAULT_BOARD_ROWS, int(current_level.get("row_count", DEFAULT_BOARD_ROWS))), DEFAULT_BOARD_ROWS, ROWS)
	_refresh_battle_layout()
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
	battle_paused = false
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
	var sky_range = Vector2(current_level.get("sky_sun_range", Vector2(999.0, 999.0)))
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
	vases = []
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
	blood_library_hazard_timer = _roll_blood_library_hazard_interval() if _is_blood_library_level() else 0.0
	fog_global_reveal_timer = 0.0
	fog_lightning_timer = 0.0
	fog_drift_offset = 0.0
	storm_lightning_cooldown = rng.randf_range(3.0, 5.0)
	city_blizzard_timer = rng.randf_range(2.2, 3.8) if _has_city_blizzard_weather() else 0.0
	city_blizzard_drift = rng.randf_range(0.0, TAU)
	scarlet_clock_hazard_timer = _roll_scarlet_clock_hazard_interval() if _has_scarlet_clock_hazard() else 0.0
	scarlet_clock_drift = rng.randf_range(0.0, TAU)
	remilia_crimson_fx_timer = 0.35
	if not _is_conveyor_level():
		for kind in active_cards:
			card_cooldowns[kind] = 0.0

	mowers = []
	for row in range(ROWS):
		var mower_kind := "lawn_mower"
		if _is_roof_level():
			mower_kind = "roof_cleaner"
		elif _uses_backyard_pool_board() and _is_water_row(row):
			mower_kind = "pool_cleaner"
		mowers.append({
			"row": row,
			"x": BOARD_ORIGIN.x - 64.0,
			"kind": mower_kind,
			"armed": _is_row_active(row),
			"active": false,
		})

	if _is_conveyor_level():
		for i in range(3):
			_fill_conveyor_slot(i)

	_setup_cell_terrain_mask()
	_setup_preplaced_supports()
	_refresh_fog_visibility_state()
	_setup_level_graves()
	if _is_vasebreaker_level():
		_setup_vasebreaker_vases()
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
	_queue_level_boss_asset_prewarm(current_level)


func _handle_selection_click(mouse_pos: Vector2) -> void:
	_ensure_selection_scene_ready()
	var back_rect = _selection_back_rect()
	if back_rect.has_point(mouse_pos) or PREP_BACK_RECT.has_point(mouse_pos):
		if bool(current_level.get("custom_level", false)):
			_enter_world_select_mode()
		else:
			_enter_map_mode()
		return

	var start_rect = _selection_start_rect()
	if start_rect.has_point(mouse_pos) or PREP_START_RECT.has_point(mouse_pos):
		var required_count = _required_seed_count(current_level)
		if selection_cards.size() < required_count:
			_show_toast("必须选满 %d 张植物" % required_count)
			return
		if bool(current_level.get("custom_level", false)):
			_begin_level(-1, selection_cards, current_level)
		else:
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
	if mode == MODE_SELECTION and (_selection_pool_panel_rect().has_point(mouse_pos) or _selection_pool_view_rect().has_point(mouse_pos)):
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
		elif almanac_return_mode == MODE_BATTLE:
			mode = MODE_BATTLE
			battle_paused = true
			selected_tool = ""
			queue_redraw()
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
		_queue_almanac_boss_asset_prewarm("zombies")
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
	var spawn_x = _random_normal_zombie_spawn_x()
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
	var zombie_base_speed = float(base["speed"]) * (0.78 if _is_whack_level() else 1.0)
	if kind == "digger_zombie":
		zombie_base_speed = float(base.get("tunnel_speed", base["speed"])) * (0.78 if _is_whack_level() else 1.0)
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
		"base_speed": zombie_base_speed,
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
		"boat_stride_timer": 0.46 if kind == "dragon_boat" else 0.0,
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
		"lane_shift_timer": float(base.get("lane_shift_interval", 0.0)),
		"teleport_cooldown": float(base.get("teleport_interval", 0.0)),
		"corrode_timer": 0.0,
		"corrode_dps": 0.0,
		"ninja_dashed": false,
			"nezha_dived": false,
			"nezha_target_col": -1,
		"burn_timer": 0.0,
		"ice_drop_cooldown": 3.8 if kind == "ice_block" else 0.0,
		"submerged": kind == "snorkel",
		"balloon_flying": kind == "balloon_zombie",
		"digger_tunneling": kind == "digger_zombie",
			"digger_reversed": false,
			"pogo_active": kind == "pogo_zombie",
			"jack_armed": kind == "jack_in_the_box_zombie",
			"jack_timer": rng.randf_range(7.8, 11.4) if kind == "jack_in_the_box_zombie" else 0.0,
			"spawned_bobsled": false,
			"on_ice": false,
			"hypnotized": false,
		"sleep_cooldown": 1.8 if kind == "nether" else 0.0,
		"plant_food_carrier": rng.randf() < 0.05,
		"whack_hits_left": _whack_hits_for_kind(kind) if _is_whack_level() else 0,
		"push_cooldown": 0.0,
		"tornado_entry": kind == "tornado_zombie",
		"tornado_target_x": spawn_x,
		"mounted": kind == "wolf_knight_zombie",
		"wolf_escape_timer": 0.0,
		"wolf_escape_offset": 0.0,
		"squash_active": false,
		"squash_timer": 0.0,
		"squash_duration": 0.0,
		"squash_from_x": spawn_x,
		"squash_to_x": spawn_x,
		"squash_hit": false,
		"squash_target_row": row,
		"squash_target_col": -1,
		"bungee_timer": 0.7 if kind == "bungee_zombie" else 0.0,
		"bungee_target_row": -1,
		"bungee_target_col": -1,
		"catapult_cooldown": 1.6 if kind == "catapult_zombie" else 0.0,
		"imp_thrown": kind != "gargantuar",
		"imp_throw_cooldown": 1.0 if kind == "gargantuar" else 0.0,
		"bee_summoned": kind != "hive_zombie",
		"launch_cooldown": 2.6 if kind == "turret_zombie" else 0.0,
		"flywheel_cooldown": float(base.get("throw_cooldown", 0.0)),
		"wizard_cooldown": float(base.get("cast_interval", 0.0)),
		"laser_cooldown": float(base.get("laser_cooldown", 0.0)),
		"ash_hits_taken": 0,
		"kite_target_row": -1,
		"kite_target_col": -1,
		"whacked": false,
		})
	next_zombie_uid += 1
	if kind == "programmer_zombie":
		var programmer_index = zombies.size() - 1
		var programmer = zombies[programmer_index]
		var rolled_health = float(rng.randi_range(1024, 2048))
		programmer["health"] = rolled_health
		programmer["max_health"] = rolled_health
		zombies[programmer_index] = programmer
	if kind == "turret_zombie":
		var turret_index = zombies.size() - 1
		var turret = zombies[turret_index]
		var turret_col = rng.randi_range(max(0, COLS - 2), COLS - 1)
		turret["x"] = _cell_center(row, turret_col).x + rng.randf_range(-6.0, 6.0)
		turret["special_pause_timer"] = 0.0
		zombies[turret_index] = turret
	if kind == "tornado_zombie":
		var tornado_index = zombies.size() - 1
		var tornado = zombies[tornado_index]
		var target_col = rng.randi_range(max(0, COLS - 5), COLS - 1)
		tornado["tornado_target_x"] = _cell_center(row, target_col).x + rng.randf_range(-16.0, 16.0)
		tornado["base_speed"] = float(base.get("entry_speed", base["speed"]))
		tornado["special_pause_timer"] = 0.0
		zombies[tornado_index] = tornado
	if kind == "wolf_knight_zombie":
		var knight_index = zombies.size() - 1
		var knight = zombies[knight_index]
		knight["base_speed"] = float(base.get("mounted_speed", base["speed"]))
		zombies[knight_index] = knight
	if kind == "ski_zombie":
		var ski_index = zombies.size() - 1
		var ski = zombies[ski_index]
		ski["special_pause_timer"] = 0.0
		zombies[ski_index] = ski
	if kind == "rumia_boss" or kind == "daiyousei_boss" or kind == "cirno_boss" or kind == "meiling_boss" or kind == "koakuma_boss" or kind == "patchouli_boss" or kind == "sakuya_boss" or kind == "remilia_boss":
		var boss_index = zombies.size() - 1
		var boss_unit = zombies[boss_index]
		boss_unit["x"] = _boss_anchor_x(kind)
		boss_unit["hover_direction"] = -1 if row >= int(round(float(active_rows.size() - 1) * 0.5)) else 1
		boss_unit["rumia_move_from_y"] = _row_center_y(int(boss_unit["row"]))
		boss_unit["rumia_move_to_y"] = _row_center_y(int(boss_unit["row"]))
		boss_unit["rumia_reinforcement_timer"] = 4.8 if kind == "rumia_boss" else (4.2 if kind == "cirno_boss" else (4.0 if kind == "patchouli_boss" else (3.9 if kind == "sakuya_boss" else (3.7 if kind == "remilia_boss" else 4.6))))
		boss_unit["hover_shift_timer"] = _roll_hover_shift_interval(kind, 0)
		boss_unit["sakuya_time_stop_charge"] = 0.0
		boss_unit["sakuya_mark_timer"] = 0.0
		zombies[boss_index] = boss_unit
		if kind == "rumia_boss":
			if String(current_level.get("boss_bgm", "")) != "":
				_play_bgm(String(current_level.get("boss_bgm", "")))
			_show_banner("露米娅出现了！", 2.4)
		elif kind == "daiyousei_boss":
			_show_banner("大妖精出现了！", 2.2)
		elif kind == "cirno_boss":
			frozen_branch_final_boss_spawned = true
			_trigger_cirno_freeze_transition()
			if String(current_level.get("boss_bgm", "")) != "":
				_play_bgm(String(current_level.get("boss_bgm", "")))
			_show_banner("琪露诺出现了！", 2.4)
		elif kind == "meiling_boss":
			if String(current_level.get("boss_bgm", "")) != "":
				_play_bgm(String(current_level.get("boss_bgm", "")))
			_show_banner("红美铃出现了！", 2.4)
		elif kind == "koakuma_boss":
			_show_banner("小恶魔出现了！", 2.2)
		elif kind == "patchouli_boss":
			if String(current_level.get("boss_bgm", "")) != "":
				_play_bgm(String(current_level.get("boss_bgm", "")))
			_show_banner("帕秋莉出现了！", 2.5)
		elif kind == "sakuya_boss":
			if _is_stage_ending_boss(boss_unit) and String(current_level.get("boss_bgm", "")) != "":
				_play_bgm(String(current_level.get("boss_bgm", "")))
			_show_banner("十六夜咲夜出现了！", 2.6)
		elif kind == "remilia_boss":
			if String(current_level.get("boss_bgm", "")) != "":
				_play_bgm(String(current_level.get("boss_bgm", "")))
			_show_banner("蕾米莉亚出现了！", 2.7)
	elif kind == "pool_boss":
		var boss_index = zombies.size() - 1
		var boss_unit = zombies[boss_index]
		boss_unit["rumia_reinforcement_timer"] = 4.9
		zombies[boss_index] = boss_unit
		_show_banner("玄潮尸王出现了！", 2.3)
	elif kind == "fog_boss":
		var boss_index = zombies.size() - 1
		var boss_unit = zombies[boss_index]
		boss_unit["x"] = BOARD_ORIGIN.x + board_size.x + 24.0
		boss_unit["rumia_reinforcement_timer"] = 4.6
		zombies[boss_index] = boss_unit
		_show_banner("雾岚尸王出现了！", 2.3)
	elif kind == "roof_boss":
		var boss_index = zombies.size() - 1
		var boss_unit = zombies[boss_index]
		boss_unit["x"] = BOARD_ORIGIN.x + board_size.x + 24.0
		boss_unit["rumia_reinforcement_timer"] = 4.5
		zombies[boss_index] = boss_unit
		_show_banner("穹顶尸王出现了！", 2.3)
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


func _has_pumpkin_shell(plant: Dictionary) -> bool:
	return String(plant.get("shell_kind", "")) == "pumpkin" or String(plant.get("kind", "")) == "pumpkin"


func _can_apply_pumpkin_shell(row: int, col: int) -> bool:
	var plant_variant = _top_plant_at(row, col)
	if plant_variant == null:
		return false
	var plant = plant_variant
	return String(plant.get("kind", "")) != "pumpkin" and not _has_pumpkin_shell(plant)


func _apply_pumpkin_shell_to_plant(plant: Dictionary, boosted: bool = false) -> Dictionary:
	var shell_health = float(Defs.PLANTS["pumpkin"]["shell_health"])
	if boosted:
		shell_health *= 1.5
	plant["shell_kind"] = "pumpkin"
	plant["armor_health"] = maxf(float(plant.get("armor_health", 0.0)), shell_health)
	plant["max_armor_health"] = maxf(float(plant.get("max_armor_health", 0.0)), shell_health)
	plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.18)
	return plant


func _can_plant_on_lily_pad(kind: String) -> bool:
	return kind != "lily_pad" and kind != "tangle_kelp" and kind != "spikeweed" and kind != "grave_buster" and kind != "wallnut_bowling"


func _is_roof_level() -> bool:
	return String(current_level.get("terrain", "")) == "roof"


func _is_city_level() -> bool:
	return String(current_level.get("terrain", "")) == "city"


func _has_city_blizzard_weather() -> bool:
	return _is_city_level() and String(current_level.get("city_weather", "")) == "blizzard"


func _is_sleepy_mushroom_kind(kind: String) -> bool:
	return kind == "puff_shroom" \
		or kind == "sun_shroom" \
		or kind == "fume_shroom" \
		or kind == "hypno_shroom" \
		or kind == "scaredy_shroom" \
		or kind == "ice_shroom" \
		or kind == "doom_shroom" \
		or kind == "magnet_shroom"


func _is_roof_support_present(row: int, col: int) -> bool:
	var support = _support_plant_at(row, col)
	return support != null and String(support.get("kind", "")) == "flower_pot"


func _is_ladderable_plant(plant: Dictionary) -> bool:
	var kind = String(plant.get("kind", ""))
	return kind == "wallnut" or kind == "tallnut" or kind == "pumpkin" or _has_pumpkin_shell(plant)


func _is_cell_protected_by_umbrella(row: int, col: int) -> bool:
	for other_row in range(max(0, row - 1), min(ROWS, row + 2)):
		for other_col in range(max(0, col - 1), min(COLS, col + 2)):
			var plant = _top_plant_at(other_row, other_col)
			if plant == null:
				continue
			if String(plant.get("kind", "")) != "umbrella_leaf":
				continue
			return true
	return false


func _roof_low_lane_limit_x() -> float:
	return _cell_center(active_rows[0] if not active_rows.is_empty() else 0, 4).x + 12.0


func _roof_shooter_col_from_x(plant_x: float) -> int:
	return clampi(int(floor((plant_x - BOARD_ORIGIN.x) / CELL_SIZE.x)), 0, COLS - 1)


func _is_roof_direct_fire_blocked(plant_x: float, target_x: float) -> bool:
	if not _is_roof_level():
		return false
	return _roof_shooter_col_from_x(plant_x) <= 2 and target_x > _roof_low_lane_limit_x()


func _choose_adjacent_valid_row_for_kind(kind: String, row: int) -> int:
	var candidates: Array = []
	for candidate in [row - 1, row + 1]:
		if candidate < 0 or candidate >= ROWS or not _is_row_active(candidate):
			continue
		if _is_row_valid_for_spawn_kind(kind, candidate):
			candidates.append(candidate)
	if candidates.is_empty():
		return row
	return int(candidates[rng.randi_range(0, candidates.size() - 1)])


func _choose_random_active_row_for_kind(kind: String, current_row: int) -> int:
	var candidates: Array = []
	for candidate_variant in active_rows:
		var candidate = int(candidate_variant)
		if candidate == current_row:
			continue
		if _is_row_valid_for_spawn_kind(kind, candidate):
			candidates.append(candidate)
	if candidates.is_empty():
		return current_row
	return int(candidates[rng.randi_range(0, candidates.size() - 1)])


func _is_mechanical_zombie_kind(kind: String) -> bool:
	return kind == "zomboni" \
		or kind == "bobsled_team" \
		or kind == "catapult_zombie" \
		or kind == "turret_zombie" \
		or kind == "programmer_zombie" \
		or kind == "subway_zombie" \
		or kind == "wenjie_zombie" \
		or kind == "router_zombie" \
		or kind == "mech_zombie" \
		or kind == "jack_in_the_box_zombie"


func _choose_bungee_target_cell() -> Vector2i:
	var candidates: Array = []
	for row in range(ROWS):
		if not _is_row_active(row):
			continue
		for col in range(COLS):
			if _targetable_plant_at(row, col) == null:
				continue
			candidates.append(Vector2i(row, col))
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return Vector2i(candidates[rng.randi_range(0, candidates.size() - 1)])


func _find_catapult_target(row: int) -> Vector2i:
	for col in range(COLS):
		if _targetable_plant_at(row, col) != null:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _setup_preplaced_supports() -> void:
	for support_cell_variant in current_level.get("preplaced_supports", []):
		var support_cell := Vector2i(support_cell_variant)
		if support_cell.x < 0 or support_cell.x >= ROWS or support_cell.y < 0 or support_cell.y >= COLS:
			continue
		if not _is_row_active(support_cell.x):
			continue
		if support_grid[support_cell.x][support_cell.y] != null:
			continue
		support_grid[support_cell.x][support_cell.y] = _create_plant("flower_pot", support_cell.x, support_cell.y)
		support_grid[support_cell.x][support_cell.y]["flash"] = 0.12


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


func _cell_effect_index(shape: String, row: int, col: int) -> int:
	for i in range(effects.size()):
		var effect = effects[i]
		if String(effect.get("shape", "")) != shape:
			continue
		if int(effect.get("row", -1)) == row and int(effect.get("col", -1)) == col:
			return i
	return -1


func _spawn_ground_patch(shape: String, row: int, col: int, duration: float, color: Color, radius_scale: float = 0.42, extra: Dictionary = {}) -> void:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS or not _is_row_active(row):
		return
	var effect_index = _cell_effect_index(shape, row, col)
	if effect_index != -1:
		var existing = effects[effect_index]
		existing["time"] = maxf(float(existing.get("time", 0.0)), duration)
		existing["duration"] = maxf(float(existing.get("duration", 0.0)), duration)
		for key in extra.keys():
			existing[key] = extra[key]
		effects[effect_index] = existing
		return
	var effect := {
		"shape": shape,
		"row": row,
		"col": col,
		"position": _cell_center(row, col) + Vector2(0.0, 18.0),
		"radius": CELL_SIZE.x * radius_scale,
		"time": duration,
		"duration": duration,
		"color": color,
	}
	for key in extra.keys():
		effect[key] = extra[key]
	effects.append(effect)


func _has_wither_patch(row: int, col: int) -> bool:
	return _cell_effect_index("wither_patch", row, col) != -1


func _spawn_magma_patch(row: int, col: int, duration: float, dps: float) -> void:
	_spawn_ground_patch("magma_patch", row, col, duration, Color(1.0, 0.34, 0.1, 0.28), 0.42, {
		"dps": dps,
	})


func _spawn_coal_patch(row: int, col: int, duration: float, dps: float) -> void:
	_spawn_ground_patch("coal_patch", row, col, duration, Color(0.18, 0.18, 0.18, 0.24), 0.38, {
		"dps": dps,
	})


func _spawn_wither_patch(row: int, col: int, duration: float) -> void:
	_spawn_ground_patch("wither_patch", row, col, duration, Color(0.34, 0.08, 0.36, 0.24), 0.48)


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
			elif _is_roof_level():
				row_data.append("roof")
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


func _create_snowfield_tile(row: int, col: int, duration: float) -> void:
	var current_terrain = _cell_terrain_kind(row, col)
	if current_terrain == "void" or current_terrain == "water" or current_terrain == "frozen":
		return
	var restore_terrain = current_terrain
	for i in range(effects.size()):
		var existing = effects[i]
		if String(existing.get("shape", "")) != "snow_patch":
			continue
		if int(existing.get("row", -1)) != row or int(existing.get("col", -1)) != col:
			continue
		restore_terrain = String(existing.get("restore_terrain", restore_terrain))
		existing["time"] = maxf(float(existing.get("time", 0.0)), duration)
		existing["duration"] = maxf(float(existing.get("duration", 0.0)), duration)
		existing["restore_terrain"] = restore_terrain
		effects[i] = existing
		_set_cell_terrain_kind(row, col, "snowfield")
		return
	_set_cell_terrain_kind(row, col, "snowfield")
	effects.append({
		"shape": "snow_patch",
		"row": row,
		"col": col,
		"restore_terrain": restore_terrain,
		"position": _cell_center(row, col),
		"radius": CELL_SIZE.x * 0.48,
		"time": duration,
		"duration": duration,
		"color": Color(0.86, 0.96, 1.0, 0.16),
	})


func _is_water_cell(row: int, col: int) -> bool:
	return _cell_terrain_kind(row, col) == "water"


func _is_frozen_cell(row: int, col: int) -> bool:
	return _cell_terrain_kind(row, col) == "frozen"


func _count_alive_enemy_zombies_by_kind(kind: String) -> int:
	var count := 0
	for zombie in zombies:
		if String(zombie.get("kind", "")) != kind:
			continue
		if float(zombie.get("health", 0.0)) <= 0.0:
			continue
		if not _is_enemy_zombie(zombie):
			continue
		count += 1
	return count


func _plant_attack_cadence_scale(row: int, col: int) -> float:
	var scale := 1.0
	if _is_frozen_cell(row, col):
		scale = maxf(scale, float(current_level.get("frozen_attack_slow", 1.3)))
	var programmer_count = _count_alive_enemy_zombies_by_kind("programmer_zombie")
	if programmer_count > 0:
		scale *= pow(2.0, programmer_count)
	return scale


func _plant_cadence_delta(delta: float, row: int, col: int) -> float:
	var attack_speed_mult = _plant_enhance_attack_speed_at_cell(row, col)
	return delta * attack_speed_mult / _plant_attack_cadence_scale(row, col)


func _placement_error(kind: String, row: int, col: int) -> String:
	var top_plant = _top_plant_at(row, col)
	var support_plant = _support_plant_at(row, col)
	var grave_index = _grave_index_at(row, col)
	var terrain = _cell_terrain_kind(row, col)
	if _vase_index_at(row, col) != -1:
		return "先打碎这个花瓶"
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
	if _has_wither_patch(row, col):
		return "这块地皮已经腐化"
	if _has_ice_tile(row, col):
		return "冰道上不能种植"
	if kind == "coffee_bean":
		if top_plant == null:
			return "咖啡豆要种在睡着的蘑菇上"
		if not _is_sleepy_mushroom_kind(String(top_plant.get("kind", ""))) or float(top_plant.get("sleep_timer", 0.0)) <= 0.0:
			return "这里只能唤醒睡着的蘑菇"
		return ""
	if kind == "flower_pot":
		if terrain != "roof" and terrain != "city_tile" and terrain != "rail" and terrain != "snowfield":
			return "花盆只能种在屋顶、瓷砖、轨道或雪地"
		if top_plant != null or support_plant != null:
			return "这个格子已经被占用了"
		return ""
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
	if kind == "sea_shroom":
		if terrain != "water":
			return "海蘑菇只能直接种在水里"
		if top_plant != null or support_plant != null:
			return "这个格子已经被占用了"
		return ""
	if kind == "pumpkin" and top_plant != null:
		if String(top_plant.get("kind", "")) == "pumpkin" or _has_pumpkin_shell(top_plant):
			return "这里已经有南瓜保护"
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
	if terrain == "roof":
		if top_plant != null:
			return "这个格子已经被占用了"
		if not _is_roof_support_present(row, col):
			return "屋顶需要先放花盆"
		return ""
	if terrain == "city_tile" or terrain == "rail" or terrain == "snowfield":
		if top_plant != null:
			return "这个格子已经被占用了"
		if support_plant == null or String(support_plant.get("kind", "")) != "flower_pot":
			return "这里需要先放花盆"
		return ""
	if top_plant != null or support_plant != null:
		return "这个格子已经被占用了"
	return ""


func _handle_board_click(cell: Vector2i) -> void:
	if selected_tool == "":
		if _is_vasebreaker_level() and _break_vase_at(cell.x, cell.y):
			queue_redraw()
			return
		# Try to activate ultimate on the clicked plant
		if _try_activate_ultimate(cell.x, cell.y):
			queue_redraw()
			return
		_show_toast("先选择植物卡片")
		return

	if selected_tool == "plant_food":
		if plant_food_count <= 0:
			_show_toast("没有可用的能量豆")
			selected_tool = ""
			queue_redraw()
			return
		if _targetable_plant_at(cell.x, cell.y) == null and not _can_target_empty_bowling_lane_with_plant_food(cell.x, cell.y):
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

	if selected_tool == "coffee_bean":
		var wake_target = _top_plant_at(cell.x, cell.y)
		if wake_target == null or not _is_sleepy_mushroom_kind(String(wake_target.get("kind", ""))) or float(wake_target.get("sleep_timer", 0.0)) <= 0.0:
			_show_toast("咖啡豆要种在睡着的蘑菇上")
			return
		var wake_data = Defs.PLANTS[selected_tool]
		if not _is_conveyor_level() and sun_points < int(wake_data["cost"]):
			_show_toast("阳光不够")
			return
		if not _is_conveyor_level() and float(card_cooldowns[selected_tool]) > 0.01:
			_show_toast("卡片还在冷却")
			return
		if not _is_conveyor_level():
			sun_points -= int(wake_data["cost"])
			card_cooldowns[selected_tool] = float(wake_data["cooldown"])
		wake_target["sleep_timer"] = 0.0
		wake_target["flash"] = maxf(float(wake_target.get("flash", 0.0)), 0.16)
		_trigger_plant_action(wake_target, 0.2)
		grid[cell.x][cell.y] = wake_target
		effects.append({
			"position": _cell_center(cell.x, cell.y) + Vector2(0.0, -16.0),
			"radius": 52.0,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.72, 0.46, 0.2, 0.24),
		})
		if _is_conveyor_level():
			_consume_conveyor_card(selected_tool)
		selected_tool = ""
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
	elif selected_tool == "pumpkin" and _can_apply_pumpkin_shell(cell.x, cell.y):
		var shelled_plant = _apply_pumpkin_shell_to_plant(_top_plant_at(cell.x, cell.y))
		grid[cell.x][cell.y] = shelled_plant
	elif selected_tool == "lily_pad" or selected_tool == "flower_pot":
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
	var stats = _enhanced_plant_stats(kind)
	var enhance_mult = _get_enhance_multiplier(kind)
	var attack_speed_mult = _get_enhance_attack_speed_multiplier(kind)
	var plant = {
		"kind": kind,
		"row": row,
		"col": col,
		"spawn_time": level_time,
		"anim_phase": rng.randf_range(0.0, TAU),
		"health": float(stats.get("health", data["health"])),
		"max_health": float(stats.get("health", data["health"])),
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
		"rear_shot_cooldown": 0.0,
		"plant_food_mode": "",
		"plant_food_timer": 0.0,
		"plant_food_interval": 0.0,
		"plant_food_charges": 0,
		"grow_timer": 0.0,
		"mature": false,
		"grave_row": -1,
		"grave_col": -1,
		"sleep_timer": 0.0,
		"rooted_timer": 0.0,
		"support_timer": 0.0,
		"contact_timer": 0.0,
		"action_timer": 0.0,
		"action_duration": 0.18,
		"push_timer": 0.0,
		"push_duration": 0.0,
		"push_offset_x": 0.0,
		"honey_timer": 0.0,
		"charge_timer": 0.0,
		"beam_timer": 0.0,
		"copy_timer": 0.0,
		"effect_timer": 0.0,
		"save_cooldown": 0.0,
		"armor_layer": 0,
		"laser_state": "",
		"core_state": "",
		"special_state": "",
		"special_timer": 0.0,
		"special_duration": 0.0,
		"attack_target_x": 0.0,
		"attack_target_row": row,
		"attack_has_hit": false,
		"shell_kind": "",
		"ultimate_charge": 0.0,
		"ultimate_active": false,
		"ultimate_timer": 0.0,
		"ultimate_cooldown": 0.0,
		"stats": stats,
		"enhance_damage_mult": enhance_mult,
		"enhance_attack_speed_mult": attack_speed_mult,
	}

	match kind:
		"sunflower":
			plant["sun_timer"] = float(stats.get("first_sun_delay", data["first_sun_delay"]))
		"peashooter", "snow_pea", "puff_shroom", "scaredy_shroom", "sea_shroom", "cactus":
			plant["shot_cooldown"] = 0.5
		"cabbage_pult":
			plant["shot_cooldown"] = 0.58
		"kernel_pult":
			plant["shot_cooldown"] = 0.68
		"melon_pult":
			plant["shot_cooldown"] = 1.0
		"origami_blossom":
			plant["shot_cooldown"] = 0.45
		"chimney_pepper":
			plant["shot_cooldown"] = 0.8
		"tesla_tulip":
			plant["attack_timer"] = 0.45
		"signal_ivy":
			plant["support_timer"] = 0.7
		"roof_vane":
			plant["gust_timer"] = 1.8
		"skylight_melon":
			plant["shot_cooldown"] = 0.95
		"repeater":
			plant["shot_cooldown"] = 0.45
		"threepeater":
			plant["shot_cooldown"] = 0.5
		"heather_shooter":
			plant["shot_cooldown"] = 0.52
		"leyline":
			plant["attack_timer"] = 0.55
		"holo_nut":
			plant["support_timer"] = float(stats.get("regen_interval", data["regen_interval"]))
		"healing_gourd":
			plant["support_timer"] = 0.8
		"mango_bowling":
			plant["attack_timer"] = 0.8
		"snow_bloom":
			plant["support_timer"] = 0.1
			plant["fuse_timer"] = float(stats.get("wilt_time", data["wilt_time"]))
			plant["snowfield_created"] = false
		"cluster_boomerang":
			plant["shot_cooldown"] = 0.5
		"glitch_walnut":
			plant["support_timer"] = float(stats.get("glitch_time", data["glitch_time"]))
		"nether_shroom":
			plant["support_timer"] = 2.0
		"seraph_flower":
			plant["shot_cooldown"] = 0.62
		"magma_stream":
			plant["support_timer"] = 0.08
			plant["fuse_timer"] = float(stats.get("wilt_time", data["wilt_time"]))
			plant["magma_created"] = false
			plant["burst_done"] = false
		"orange_bloom":
			plant["attack_timer"] = 0.56
		"hive_flower":
			plant["attack_timer"] = 0.48
		"mamba_tree":
			plant["support_timer"] = 0.34
		"chambord_sniper":
			plant["attack_timer"] = 0.74
		"dream_disc":
			plant["support_timer"] = 0.12
			plant["dream_triggered"] = false
		"shadow_pea":
			plant["shot_cooldown"] = 0.42
		"ice_queen":
			plant["support_timer"] = 0.65
		"vine_emperor":
			plant["attack_timer"] = 0.42
		"soul_flower":
			plant["sun_timer"] = float(stats.get("first_sun_delay", data["first_sun_delay"]))
		"plasma_shooter":
			plant["attack_timer"] = 0.55
		"crystal_nut":
			plant["support_timer"] = 0.6
		"dragon_fruit":
			plant["attack_timer"] = 0.72
		"time_rose":
			plant["support_timer"] = 0.58
		"galaxy_sunflower":
			plant["sun_timer"] = float(stats.get("first_sun_delay", data["first_sun_delay"]))
		"void_shroom":
			plant["support_timer"] = 0.55
		"phoenix_tree":
			plant["shot_cooldown"] = 0.48
		"thunder_god":
			plant["attack_timer"] = 0.68
		"blover":
			plant["fuse_timer"] = 0.12
		"split_pea":
			plant["shot_cooldown"] = 0.4
			plant["rear_shot_cooldown"] = 0.1
		"starfruit":
			plant["shot_cooldown"] = 0.45
		"boomerang_shooter":
			plant["shot_cooldown"] = 0.55
		"sakura_shooter":
			plant["shot_cooldown"] = 0.58
		"lotus_lancer":
			plant["shot_cooldown"] = 0.62
		"mist_orchid":
			plant["shot_cooldown"] = 0.52
		"anchor_fern":
			plant["support_timer"] = 0.65
		"glowvine":
			plant["shot_cooldown"] = 0.6
		"brine_pot":
			plant["attack_timer"] = 0.7
		"storm_reed":
			plant["support_timer"] = 0.45
		"moonforge":
			plant["shot_cooldown"] = 1.1
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
		"marigold":
			plant["sun_timer"] = float(data["first_sun_delay"])
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
		"magnet_shroom":
			plant["support_timer"] = 0.8
		"pumpkin":
			plant = _apply_pumpkin_shell_to_plant(plant)
		"ice_shroom", "doom_shroom":
			plant["fuse_timer"] = 0.6
		"grave_buster":
			plant["chew_timer"] = float(data["chew_time"])
			plant["grave_row"] = row
			plant["grave_col"] = col

	if _is_roof_level() and _is_sleepy_mushroom_kind(kind):
		plant["sleep_timer"] = 99999.0

	return plant


func _trigger_plant_action(plant: Dictionary, duration: float) -> void:
	plant["action_timer"] = maxf(float(plant.get("action_timer", 0.0)), duration)
	plant["action_duration"] = maxf(duration, 0.01)


func _ensure_plant_runtime() -> PlantRuntime:
	if plant_runtime == null:
		plant_runtime = PlantRuntime.new(self)
	return plant_runtime


func _ensure_projectile_runtime() -> ProjectileRuntime:
	if projectile_runtime == null:
		projectile_runtime = ProjectileRuntime.new(self)
	return projectile_runtime


func _update_plants(delta: float) -> void:
	if boss_time_stop_timer > 0.0:
		return
	_ensure_plant_runtime().update_plants(delta)
	_update_ultimate_charges(delta)


func _heal_targetable_plant_cell(row: int, col: int, amount: float, flash: float = 0.08) -> bool:
	var plant_variant = _targetable_plant_at(row, col)
	if plant_variant == null:
		return false
	var plant = plant_variant
	var healed := false
	if float(plant.get("health", 0.0)) < float(plant.get("max_health", 0.0)):
		plant["health"] = minf(float(plant["max_health"]), float(plant["health"]) + amount)
		healed = true
	if float(plant.get("max_armor_health", 0.0)) > 0.0 and float(plant.get("armor_health", 0.0)) < float(plant.get("max_armor_health", 0.0)):
		plant["armor_health"] = minf(float(plant["max_armor_health"]), float(plant["armor_health"]) + amount * 0.45)
		healed = true
	if healed:
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), flash)
		_set_targetable_plant(row, col, plant)
	return healed


func _plant_supports_click_ultimate(kind: String) -> bool:
	return not _ultimate_profile_for_kind(kind).is_empty()


func _ultimate_profile_for_kind(kind: String) -> Dictionary:
	var data = Defs.PLANTS.get(kind, {})
	if data.is_empty():
		return {}
	if data.has("ultimate_charge_time"):
		return {
			"style": "explicit",
			"ultimate_name": String(data.get("ultimate_name", "终极技能")),
			"ultimate_charge_time": float(data.get("ultimate_charge_time", 60.0)),
			"ultimate_duration": float(data.get("ultimate_duration", 1.2)),
		}
	var charge_time = clampf(46.0 + float(data.get("cost", 100)) * 0.08, 44.0, 72.0)
	if kind == "moonforge":
		return {"style": "explicit", "ultimate_name": "月蚀流星", "ultimate_charge_time": charge_time + 4.0, "ultimate_duration": 1.1}
	if kind == "lily_pad":
		return {"style": "pad_bloom", "ultimate_name": "涟漪蔓延", "ultimate_charge_time": charge_time - 6.0, "ultimate_duration": 0.8}
	if kind == "flower_pot":
		return {"style": "pot_bloom", "ultimate_name": "花盆蔓生", "ultimate_charge_time": charge_time - 6.0, "ultimate_duration": 0.8}
	if PlantFoodRuntime.supported_kinds().has(kind):
		return {"style": "plant_food_ultimate", "ultimate_name": String(data.get("ultimate_name", "植物能量")), "ultimate_charge_time": charge_time, "ultimate_duration": 0.8}
	match kind:
		"sunflower", "sun_shroom", "sun_bean", "moon_lotus", "marigold":
			return {"style": "sun_burst", "ultimate_name": "光合作用", "ultimate_charge_time": charge_time - 4.0, "ultimate_duration": 0.6}
		"peashooter", "puff_shroom", "sea_shroom", "amber_shooter", "scaredy_shroom", "cactus":
			return {"style": "lane_burst", "ultimate_name": "连珠齐射", "ultimate_charge_time": charge_time, "ultimate_duration": 1.0}
		"repeater", "threepeater", "split_pea", "starfruit", "boomerang_shooter", "sakura_shooter", "origami_blossom", "cluster_boomerang":
			return {"style": "multi_lane_burst", "ultimate_name": "暴风连击", "ultimate_charge_time": charge_time + 2.0, "ultimate_duration": 1.2}
		"cabbage_pult", "kernel_pult", "melon_pult", "pepper_mortar", "mango_bowling", "skylight_melon":
			return {"style": "artillery_barrage", "ultimate_name": "重火力覆盖", "ultimate_charge_time": charge_time + 4.0, "ultimate_duration": 1.0}
		"wallnut", "tallnut", "pumpkin", "cactus_guard", "garlic", "umbrella_leaf", "brick_guard", "holo_nut":
			return {"style": "fortify", "ultimate_name": "防线稳固", "ultimate_charge_time": charge_time + 6.0, "ultimate_duration": 6.0}
		"cherry_bomb", "potato_mine", "jalapeno", "ice_shroom", "doom_shroom", "squash", "tangle_kelp", "snow_bloom":
			return {"style": "detonate", "ultimate_name": "超载引爆", "ultimate_charge_time": charge_time - 2.0, "ultimate_duration": 0.5}
		"pulse_bulb", "signal_ivy", "mirror_reed", "mist_orchid", "anchor_fern", "glowvine", "brine_pot", "storm_reed", "lotus_lancer", "frost_fan", "heather_shooter", "leyline", "vine_lasher", "root_snare", "prism_grass", "meteor_gourd", "thunder_pine", "fume_shroom":
			return {"style": "pulse_control", "ultimate_name": "领域压制", "ultimate_charge_time": charge_time + 1.0, "ultimate_duration": 1.2}
		"blover", "wind_orchid", "roof_vane":
			return {"style": "gale_force", "ultimate_name": "飓风驱散", "ultimate_charge_time": charge_time - 3.0, "ultimate_duration": 0.8}
		"hypno_shroom":
			return {"style": "hypno_wave", "ultimate_name": "魅惑脉冲", "ultimate_charge_time": charge_time, "ultimate_duration": 0.8}
		"magnet_shroom":
			return {"style": "magnet_burst", "ultimate_name": "磁暴回路", "ultimate_charge_time": charge_time + 1.0, "ultimate_duration": 0.8}
		"plantern", "lantern_bloom":
			return {"style": "reveal_bloom", "ultimate_name": "辉光显形", "ultimate_charge_time": charge_time - 2.0, "ultimate_duration": 6.0}
		"grave_buster":
			return {"style": "grave_purge", "ultimate_name": "墓场清算", "ultimate_charge_time": charge_time, "ultimate_duration": 0.8}
		"dream_drum", "coffee_bean":
			return {"style": "wake_burst", "ultimate_name": "惊梦唤醒", "ultimate_charge_time": charge_time - 4.0, "ultimate_duration": 0.8}
		"torchwood":
			return {"style": "fire_lane", "ultimate_name": "燎原火线", "ultimate_charge_time": charge_time, "ultimate_duration": 1.0}
	if data.has("sun_interval"):
		return {"style": "sun_burst", "ultimate_name": "阳光喷涌", "ultimate_charge_time": charge_time, "ultimate_duration": 0.6}
	if data.has("shoot_interval") and data.has("damage"):
		return {"style": "lane_burst", "ultimate_name": "火力倾泻", "ultimate_charge_time": charge_time, "ultimate_duration": 1.0}
	if data.has("attack_interval") and data.has("damage") and data.has("splash_radius"):
		return {"style": "artillery_barrage", "ultimate_name": "面杀轰炸", "ultimate_charge_time": charge_time + 4.0, "ultimate_duration": 1.0}
	if data.has("pulse_interval") and data.has("damage"):
		return {"style": "pulse_control", "ultimate_name": "脉冲镇压", "ultimate_charge_time": charge_time, "ultimate_duration": 1.0}
	if data.has("health") and float(data.get("health", 0.0)) >= 1200.0:
		return {"style": "fortify", "ultimate_name": "坚壁加固", "ultimate_charge_time": charge_time + 4.0, "ultimate_duration": 6.0}
	return {"style": "support_bloom", "ultimate_name": "活力回响", "ultimate_charge_time": charge_time, "ultimate_duration": 0.8}


func _tick_click_ultimate_for_plant(plant: Dictionary, delta: float) -> Dictionary:
	var profile = _ultimate_profile_for_kind(String(plant.get("kind", "")))
	if profile.is_empty():
		return plant
	if float(plant.get("ultimate_cooldown", 0.0)) > 0.0:
		plant["ultimate_cooldown"] = maxf(0.0, float(plant["ultimate_cooldown"]) - delta)
	if bool(plant.get("ultimate_active", false)):
		plant["ultimate_timer"] = float(plant["ultimate_timer"]) - delta
		if float(plant["ultimate_timer"]) <= 0.0:
			plant["ultimate_active"] = false
			plant["ultimate_cooldown"] = 90.0
			plant["ultimate_charge"] = 0.0
		return plant
	if float(plant.get("ultimate_cooldown", 0.0)) <= 0.0 and float(plant.get("ultimate_charge", 0.0)) < 1.0:
		var charge_time = maxf(float(profile.get("ultimate_charge_time", 60.0)), 1.0)
		var data = Defs.PLANTS.get(String(plant.get("kind", "")), {})
		if bool(data.get("gacha_only", false)):
			charge_time *= 0.8
		plant["ultimate_charge"] = minf(1.0, float(plant["ultimate_charge"]) + delta / charge_time)
	return plant


func _update_ultimate_charges(delta: float) -> void:
	for row in range(grid.size()):
		for col in range(grid[row].size()):
			if grid[row][col] != null:
				grid[row][col] = _tick_click_ultimate_for_plant(grid[row][col], delta)
			elif support_grid[row][col] != null:
				support_grid[row][col] = _tick_click_ultimate_for_plant(support_grid[row][col], delta)


func _try_activate_ultimate(row: int, col: int) -> bool:
	var plant_variant = _targetable_plant_at(row, col)
	if plant_variant == null:
		return false
	var plant = plant_variant
	var kind = String(plant["kind"])
	var profile = _ultimate_profile_for_kind(kind)
	if profile.is_empty():
		return false
	if float(plant["ultimate_charge"]) < 1.0 or bool(plant["ultimate_active"]):
		return false
	if float(plant["ultimate_cooldown"]) > 0.0:
		return false
	plant["ultimate_active"] = true
	plant["ultimate_timer"] = float(profile.get("ultimate_duration", 1.2))
	_set_targetable_plant(row, col, plant)
	_trigger_screen_shake(6.0)
	_show_toast("%s: %s!" % [String(Defs.PLANTS[kind].get("name", kind)), String(profile.get("ultimate_name", "终极技能"))])
	_execute_ultimate(plant, kind, row, col, profile)
	return true


func _execute_generic_ultimate(plant: Dictionary, kind: String, row: int, col: int, profile: Dictionary) -> void:
	var center = _cell_center(row, col)
	var data = Defs.PLANTS.get(kind, {})
	match String(profile.get("style", "")):
		"sun_burst":
			var sun_value = max(50, int(data.get("sun_amount", 50)))
			var sun_count = 4 if sun_value <= 50 else 6
			for index in range(sun_count):
				var angle = TAU * float(index) / float(sun_count)
				var offset = Vector2(cos(angle), sin(angle)) * (38.0 + 8.0 * float(index % 2))
				_spawn_sun(center + offset, center.y - 22.0 + offset.y * 0.2, "plant_food", sun_value)
			effects.append({"position": center, "radius": 132.0, "time": 0.3, "duration": 0.3, "color": Color(1.0, 0.9, 0.38, 0.28)})
		"lane_burst":
			var damage = maxf(float(data.get("damage", 20.0)) * 5.0, 90.0)
			var slow_duration = float(data.get("slow_duration", 0.0))
			_damage_zombies_in_row_segment(row, center.x + 12.0, BOARD_ORIGIN.x + board_size.x + 24.0, damage, slow_duration + 1.2)
			for shot in range(4):
				_spawn_projectile(row, center + Vector2(30.0 + float(shot) * 12.0, -16.0 + float(shot % 2) * 12.0), Color(0.92, 0.88, 0.34), maxf(float(data.get("damage", 20.0)) * 1.4, 26.0), slow_duration, 560.0, 7.0)
			effects.append({"shape": "lane_spray", "position": center + Vector2(18.0, -8.0), "length": board_size.x, "width": 56.0, "radius": board_size.x * 0.5, "time": 0.24, "duration": 0.24, "color": Color(0.92, 0.88, 0.34, 0.24)})
		"multi_lane_burst":
			var lanes: Array = [row]
			if kind == "threepeater":
				lanes = []
				for lane in [row - 1, row, row + 1]:
					if lane >= 0 and lane < ROWS and _is_row_active(lane):
						lanes.append(lane)
			var damage = maxf(float(data.get("damage", 20.0)) * 4.4, 84.0)
			for lane_variant in lanes:
				var lane = int(lane_variant)
				_damage_zombies_in_row_segment(lane, center.x + 8.0, BOARD_ORIGIN.x + board_size.x + 24.0, damage, float(data.get("slow_duration", 0.0)) + 0.8)
			effects.append({"position": center, "radius": 170.0, "time": 0.26, "duration": 0.26, "color": Color(0.86, 0.84, 0.38, 0.24)})
		"artillery_barrage":
			var impact = _find_global_frontmost_target()
			var impact_pos = center + Vector2(180.0, -8.0)
			if int(impact.get("row", -1)) != -1:
				impact_pos = Vector2(float(impact["x"]), _row_center_y(int(impact["row"])) - 8.0)
			var radius = maxf(float(data.get("splash_radius", 86.0)) + 36.0, 96.0)
			var damage = maxf(float(data.get("damage", 32.0)) * 4.0, 120.0)
			_damage_zombies_in_circle(impact_pos, radius, damage)
			_damage_obstacles_in_circle(impact_pos, radius * 0.92, damage)
			effects.append({"position": impact_pos, "radius": radius, "time": 0.32, "duration": 0.32, "color": Color(1.0, 0.68, 0.24, 0.28)})
		"fortify":
			plant["health"] = float(plant["max_health"])
			plant["armor_health"] = maxf(float(plant.get("armor_health", 0.0)), float(plant["max_health"]) * 0.65)
			plant["max_armor_health"] = maxf(float(plant.get("max_armor_health", 0.0)), float(plant["armor_health"]))
			_set_targetable_plant(row, col, plant)
			for zombie_index in _find_closest_zombies_in_radius(center, 112.0, 6):
				var zombie = zombies[zombie_index]
				zombie = _apply_zombie_damage(zombie, maxf(float(data.get("thorns", 18.0)) * 6.0, 80.0), 0.16, 1.4)
				zombie["x"] += 28.0
				zombies[zombie_index] = zombie
			effects.append({"position": center, "radius": 116.0, "time": 0.3, "duration": 0.3, "color": Color(0.62, 0.92, 1.0, 0.26)})
		"detonate":
			match kind:
				"cherry_bomb":
					_explode_cherry(row, col, true)
				"jalapeno":
					_trigger_jalapeno(row, col, true)
				"ice_shroom":
					_trigger_ice_shroom(row, col, true)
				"doom_shroom":
					_trigger_doom_shroom(row, col, true)
				"potato_mine":
					_explode_mine(row, col)
				_:
					var radius = maxf(float(data.get("radius", data.get("explosion_radius", 120.0))), 108.0)
					var damage = maxf(float(data.get("damage", 160.0)), 260.0)
					_damage_zombies_in_circle(center, radius, damage)
					_damage_obstacles_in_circle(center, radius, damage)
					effects.append({"position": center, "radius": radius, "time": 0.34, "duration": 0.34, "color": Color(1.0, 0.52, 0.24, 0.28)})
		"pulse_control":
			var radius = maxf(float(data.get("radius", data.get("reveal_radius", data.get("pull_radius", data.get("range", 160.0))))), 140.0)
			var damage = maxf(float(data.get("damage", 26.0)) * 2.8, 78.0)
			for zombie_index in _find_closest_zombies_in_radius(center, radius, 8):
				var zombie = zombies[zombie_index]
				zombie = _apply_zombie_damage(zombie, damage, 0.16, float(data.get("slow_duration", 0.0)) + 2.5)
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.35)
				if kind == "root_snare" or kind == "vine_lasher" or kind == "anchor_fern":
					zombie["rooted_timer"] = maxf(float(zombie.get("rooted_timer", 0.0)), 2.8)
				zombies[zombie_index] = zombie
			effects.append({"position": center, "radius": radius, "time": 0.3, "duration": 0.3, "color": Color(0.68, 0.92, 1.0, 0.24)})
		"gale_force":
			var push_rows: Array = active_rows.duplicate()
			if kind != "blover":
				push_rows = []
				for lane in [row - 1, row, row + 1]:
					if lane >= 0 and lane < ROWS and _is_row_active(lane):
						push_rows.append(lane)
			for i in range(zombies.size()):
				var zombie = zombies[i]
				if not _is_enemy_zombie(zombie) or not push_rows.has(int(zombie["row"])):
					continue
				zombie["x"] += 120.0
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.38)
				if bool(zombie.get("balloon_flying", false)):
					zombie["balloon_flying"] = false
					zombie["base_speed"] = float(Defs.ZOMBIES["balloon_zombie"]["speed"])
				zombies[i] = zombie
			if kind == "blover":
				_trigger_blover_fog_clear(8.0)
			effects.append({"shape": "lane_spray", "position": center + Vector2(14.0, -8.0), "length": board_size.x, "width": CELL_SIZE.y * float(max(push_rows.size(), 1)), "radius": board_size.x * 0.5, "time": 0.24, "duration": 0.24, "color": Color(0.82, 0.98, 1.0, 0.24)})
		"hypno_wave":
			for zombie_index in _find_closest_zombies_in_radius(center, 220.0, 3):
				zombies[zombie_index] = _hypnotize_zombie(zombies[zombie_index])
			effects.append({"position": center, "radius": 220.0, "time": 0.28, "duration": 0.28, "color": Color(0.82, 0.48, 1.0, 0.28)})
		"magnet_burst":
			for i in range(zombies.size()):
				var zombie = zombies[i]
				if not _is_enemy_zombie(zombie):
					continue
				var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
				if zombie_pos.distance_to(center) > 320.0:
					continue
				if not _can_magnet_strip(zombie):
					continue
				zombies[i] = _strip_metal_from_zombie(zombie)
			effects.append({"position": center, "radius": 320.0, "time": 0.28, "duration": 0.28, "color": Color(0.86, 0.76, 1.0, 0.28)})
		"reveal_bloom":
			_trigger_blover_fog_clear(8.0)
			for i in range(zombies.size()):
				var zombie = zombies[i]
				if String(zombie.get("kind", "")) != "shouyue":
					continue
				zombie["revealed_timer"] = maxf(float(zombie.get("revealed_timer", 0.0)), 8.0)
				zombies[i] = zombie
			effects.append({"position": center, "radius": board_size.x, "time": 0.3, "duration": 0.3, "color": Color(1.0, 0.96, 0.72, 0.22)})
		"grave_purge":
			for grave in graves:
				var grave_center = _cell_center(int(grave["row"]), int(grave["col"]))
				_damage_zombies_in_circle(grave_center, 110.0, 140.0)
			graves.clear()
			effects.append({"position": center, "radius": 180.0, "time": 0.3, "duration": 0.3, "color": Color(0.74, 0.52, 0.36, 0.24)})
		"wake_burst":
			_wake_all_plants()
			_sleep_zombies_in_radius(center, 240.0, 1.8, false)
			effects.append({"position": center, "radius": 240.0, "time": 0.26, "duration": 0.26, "color": Color(0.88, 0.76, 0.36, 0.24)})
		"fire_lane":
			_damage_zombies_in_row_segment(row, BOARD_ORIGIN.x - 8.0, BOARD_ORIGIN.x + board_size.x + 24.0, 180.0, 1.6)
			effects.append({"shape": "lane_spray", "position": Vector2(BOARD_ORIGIN.x, _row_center_y(row)), "length": board_size.x, "width": 62.0, "radius": board_size.x * 0.5, "time": 0.26, "duration": 0.26, "color": Color(1.0, 0.48, 0.18, 0.28)})
		"plant_food_ultimate":
			if not _activate_plant_food(row, col):
				effects.append({"position": center, "radius": 120.0, "time": 0.24, "duration": 0.24, "color": Color(0.84, 0.92, 0.5, 0.2)})
		"pad_bloom":
			var pad_count := 0
			for water_row_variant in water_rows:
				var water_row = int(water_row_variant)
				for water_col in range(COLS):
					if _cell_terrain_kind(water_row, water_col) != "water":
						continue
					if _support_plant_at(water_row, water_col) != null or _top_plant_at(water_row, water_col) != null:
						continue
					support_grid[water_row][water_col] = _create_plant("lily_pad", water_row, water_col)
					support_grid[water_row][water_col]["flash"] = 0.18
					pad_count += 1
			effects.append({"position": center, "radius": 132.0 + float(pad_count) * 3.0, "time": 0.3, "duration": 0.3, "color": Color(0.42, 0.86, 0.96, 0.26)})
		"pot_bloom":
			var pot_count := 0
			for active_row in active_rows:
				var support_row = int(active_row)
				for support_col in range(COLS):
					var terrain = _cell_terrain_kind(support_row, support_col)
					if terrain != "roof" and terrain != "city_tile" and terrain != "rail" and terrain != "snowfield":
						continue
					if _support_plant_at(support_row, support_col) != null or _top_plant_at(support_row, support_col) != null:
						continue
					support_grid[support_row][support_col] = _create_plant("flower_pot", support_row, support_col)
					support_grid[support_row][support_col]["flash"] = 0.18
					pot_count += 1
			effects.append({"position": center, "radius": 140.0 + float(pot_count) * 3.0, "time": 0.3, "duration": 0.3, "color": Color(0.8, 0.66, 0.38, 0.28)})
		"support_bloom":
			var any_heal := false
			for other_row in range(max(0, row - 1), min(ROWS, row + 2)):
				for other_col in range(max(0, col - 1), min(COLS, col + 2)):
					any_heal = _heal_targetable_plant_cell(other_row, other_col, 120.0, 0.1) or any_heal
			if not any_heal and kind == "lily_pad":
				effects.append({"position": center, "radius": 120.0, "time": 0.3, "duration": 0.3, "color": Color(0.42, 0.86, 0.96, 0.26)})
			else:
				effects.append({"position": center, "radius": 120.0, "time": 0.3, "duration": 0.3, "color": Color(0.7, 0.96, 0.74, 0.26)})


func _execute_ultimate(plant: Dictionary, kind: String, row: int, col: int, profile: Dictionary) -> void:
	var center = _cell_center(row, col)
	if String(profile.get("style", "")) != "explicit":
		_execute_generic_ultimate(plant, kind, row, col, profile)
		return
	match kind:
		"shadow_pea":
			for r in range(grid.size()):
				for i in range(4):
					projectiles.append({
						"row": r,
						"position": Vector2(center.x + float(i) * 30.0, _row_center_y(r)),
						"speed": 420.0,
						"damage": 28.0,
						"kind": "pea",
						"color": Color(0.52, 0.22, 0.82),
					})
		"ice_queen":
			for z in zombies:
				z["frozen_timer"] = maxf(float(z.get("frozen_timer", 0.0)), 5.0)
			effects.append({"position": center, "radius": 600.0, "time": 0.6, "duration": 0.6, "color": Color(0.56, 0.82, 1.0, 0.4)})
		"vine_emperor":
			for z in zombies:
				var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
				if zpos.distance_to(center) < 240.0:
					z["rooted_timer"] = maxf(float(z.get("rooted_timer", 0.0)), 8.0)
			effects.append({"position": center, "radius": 240.0, "time": 0.5, "duration": 0.5, "color": Color(0.28, 0.62, 0.22, 0.5)})
		"soul_flower":
			effects.append({"position": center, "radius": 200.0, "time": 0.4, "duration": 0.4, "color": Color(0.62, 0.36, 0.82, 0.4)})
		"plasma_shooter":
			for z in zombies:
				if int(z["row"]) == row:
					z["health"] = float(z["health"]) - 2000.0
					z["flash"] = 0.4
			effects.append({"position": Vector2(center.x + 400.0, center.y), "radius": 800.0, "time": 0.8, "duration": 0.8, "color": Color(0.18, 0.72, 0.92, 0.6)})
			_trigger_screen_shake(10.0)
		"crystal_nut":
			plant["health"] = float(plant["max_health"])
			_set_targetable_plant(row, col, plant)
			effects.append({"position": center, "radius": 100.0, "time": 0.5, "duration": 0.5, "color": Color(0.56, 0.78, 0.96, 0.5)})
		"dragon_fruit":
			for r in range(maxi(0, row - 1), mini(grid.size(), row + 2)):
				for z in zombies:
					if int(z["row"]) == r and float(z["x"]) > center.x and float(z["x"]) < center.x + 400.0:
						z["health"] = float(z["health"]) - 200.0
						z["flash"] = 0.3
			effects.append({"position": center + Vector2(200.0, 0.0), "radius": 400.0, "time": 1.0, "duration": 1.0, "color": Color(1.0, 0.42, 0.12, 0.5)})
			_trigger_screen_shake(8.0)
		"time_rose":
			for z in zombies:
				z["frozen_timer"] = maxf(float(z.get("frozen_timer", 0.0)), 6.0)
			effects.append({"position": center, "radius": 500.0, "time": 0.6, "duration": 0.6, "color": Color(0.82, 0.56, 0.86, 0.4)})
		"galaxy_sunflower":
			sun_points += 500
			effects.append({"position": center, "radius": 300.0, "time": 0.8, "duration": 0.8, "color": Color(1.0, 0.92, 0.36, 0.5)})
			_trigger_screen_shake(6.0)
		"void_shroom":
			for z in zombies:
				z["health"] = float(z["health"]) - 800.0
				z["flash"] = 0.5
			effects.append({"position": center, "radius": 600.0, "time": 1.2, "duration": 1.2, "color": Color(0.18, 0.06, 0.28, 0.6)})
			_trigger_screen_shake(12.0)
		"phoenix_tree":
			for z in zombies:
				var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
				if zpos.distance_to(center) < 200.0:
					z["health"] = float(z["health"]) - 2000.0
					z["flash"] = 0.5
			plant["health"] = float(plant["max_health"])
			_set_targetable_plant(row, col, plant)
			effects.append({"position": center, "radius": 200.0, "time": 0.8, "duration": 0.8, "color": Color(1.0, 0.52, 0.12, 0.6)})
			_trigger_screen_shake(10.0)
			_spawn_death_poof(center, Color(1.0, 0.6, 0.2))
		"thunder_god":
			for z in zombies:
				z["health"] = float(z["health"]) - 500.0
				z["flash"] = 0.4
				var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
				_spawn_death_poof(zpos, Color(0.86, 0.82, 0.22))
			effects.append({"position": Vector2(size.x * 0.5, size.y * 0.5), "radius": 800.0, "time": 1.0, "duration": 1.0, "color": Color(0.86, 0.82, 0.22, 0.4)})
			_trigger_screen_shake(12.0)
		"moonforge":
			var launched := 0
			for _meteor in range(5):
				var moon_target = _find_global_frontmost_target()
				if int(moon_target.get("row", -1)) == -1:
					break
				var moon_origin = center + Vector2(18.0 - float(launched) * 3.0, -18.0 - float(launched % 2) * 6.0)
				var moon_impact = Vector2(float(moon_target["x"]) + rng.randf_range(-26.0, 26.0), _row_center_y(int(moon_target["row"])) - 10.0 + rng.randf_range(-8.0, 8.0))
				_spawn_moonforge_projectile(moon_origin, moon_impact, maxf(float(Defs.PLANTS[kind].get("damage", 48.0)) * 1.5, 96.0), maxf(float(Defs.PLANTS[kind].get("splash_radius", 72.0)) + 28.0, 94.0))
				launched += 1
			plant["shot_cooldown"] = 0.08
			_set_targetable_plant(row, col, plant)
			effects.append({"position": center, "radius": 160.0, "time": 0.4, "duration": 0.4, "color": Color(1.0, 0.8, 0.46, 0.3)})
		"nether_shroom":
			for active_row_variant in active_rows:
				var summon_row = int(active_row_variant)
				_spawn_zombie_at("buckethead", summon_row, _cell_center(summon_row, col).x + 22.0, false)
				if not zombies.is_empty() and String(zombies[zombies.size() - 1].get("kind", "")) == "buckethead":
					var summon = zombies[zombies.size() - 1]
					summon = _hypnotize_zombie(summon)
					summon["special_pause_timer"] = maxf(float(summon.get("special_pause_timer", 0.0)), 0.42)
					zombies[zombies.size() - 1] = summon
			effects.append({"position": center, "radius": 180.0, "time": 0.42, "duration": 0.42, "color": Color(0.74, 0.42, 0.96, 0.32)})
		"seraph_flower":
			var seraph_data = Defs.PLANTS[kind]
			for lane in [row - 1, row, row + 1]:
				if lane < 0 or lane >= ROWS or not _is_row_active(lane):
					continue
				for spear_index in range(3):
					projectiles.append({
						"kind": "angel_spear",
						"row": lane,
						"position": _cell_center(lane, col) + Vector2(22.0 - spear_index * 12.0, -16.0 + spear_index * 6.0),
						"speed": 640.0,
						"velocity_y": 0.0,
						"damage": float(seraph_data.get("ultimate_damage", 88.0)),
						"slow_duration": 0.0,
						"color": Color(1.0, 0.84, 0.58, 0.96),
						"radius": 8.0,
						"reflected": false,
						"fire": false,
						"free_aim": false,
						"pierce_left": int(seraph_data.get("pierce_hits", 5)) + 2,
						"hit_uids": [],
					})
			effects.append({"shape": "lane_spray", "position": Vector2(center.x + 16.0, center.y - 12.0), "length": board_size.x * 0.7, "width": CELL_SIZE.y * 2.2, "radius": board_size.x, "time": 0.34, "duration": 0.34, "color": Color(1.0, 0.9, 0.66, 0.22)})
		"magma_stream":
			var magma_data = Defs.PLANTS[kind]
			for magma_row in range(max(0, row - 1), min(ROWS, row + 2)):
				for magma_col in range(max(0, col - 1), min(COLS, col + 2)):
					_spawn_magma_patch(magma_row, magma_col, float(magma_data.get("magma_duration", 11.0)) + 4.0, float(magma_data.get("magma_dps", 56.0)) * 1.35)
					var magma_center = _cell_center(magma_row, magma_col)
					_damage_zombies_in_circle(magma_center, CELL_SIZE.x * 0.46, float(magma_data.get("ultimate_damage", 180.0)))
					_apply_ash_hits_in_circle(magma_center, CELL_SIZE.x * 0.46, 1)
			effects.append({"position": center, "radius": 180.0, "time": 0.46, "duration": 0.46, "color": Color(1.0, 0.36, 0.12, 0.34)})
		"orange_bloom":
			var orange_targets: Array = []
			for zombie_index in range(zombies.size()):
				var orange_zombie = zombies[zombie_index]
				if not _is_enemy_zombie(orange_zombie) or int(orange_zombie["row"]) != row or float(orange_zombie["x"]) <= center.x:
					continue
				orange_targets.append({"index": zombie_index, "x": float(orange_zombie["x"])})
			orange_targets.sort_custom(func(a, b): return float(a["x"]) < float(b["x"]))
			for target_index in range(min(4, orange_targets.size())):
				var orange_target = orange_targets[target_index]
				var impact = Vector2(float(orange_target["x"]), _row_center_y(row))
				_damage_zombies_in_circle(impact, float(Defs.PLANTS[kind].get("splash_radius", 78.0)) + 18.0, float(Defs.PLANTS[kind].get("ultimate_damage", 64.0)))
			effects.append({"shape": "lane_spray", "position": Vector2(center.x + 16.0, center.y + 6.0), "length": board_size.x * 0.82, "width": 54.0, "radius": board_size.x, "time": 0.34, "duration": 0.34, "color": Color(1.0, 0.58, 0.22, 0.28)})
		"hive_flower":
			for bee_cast in range(6):
				var bee_target = _find_global_frontmost_target()
				if int(bee_target.get("row", -1)) == -1:
					break
				var bee_impact = Vector2(float(bee_target["x"]), _row_center_y(int(bee_target["row"])) - 10.0)
				_damage_zombies_in_circle(bee_impact, 72.0, float(Defs.PLANTS[kind].get("ultimate_damage", 52.0)))
				effects.append({"shape": "storm_arc", "position": center + Vector2(6.0, -18.0), "target": bee_impact, "radius": 72.0, "time": 0.22, "duration": 0.22, "color": Color(1.0, 0.86, 0.26, 0.3)})
		"mamba_tree":
			for coal_row in range(max(0, row - 1), min(ROWS, row + 2)):
				for coal_col in range(col, min(COLS, col + 4)):
					_spawn_coal_patch(coal_row, coal_col, float(Defs.PLANTS[kind].get("ember_duration", 10.0)) + 4.0, float(Defs.PLANTS[kind].get("ember_dps", 18.0)) * 1.45)
			effects.append({"position": center, "radius": 190.0, "time": 0.36, "duration": 0.36, "color": Color(0.26, 0.18, 0.18, 0.34)})
		"chambord_sniper":
			for lane_variant in active_rows:
				var sniper_row = int(lane_variant)
				var sniper_target_index = _find_lane_target_ignore_fog(sniper_row, BOARD_ORIGIN.x - 20.0, board_size.x + 40.0)
				if sniper_target_index == -1:
					continue
				var sniper_target = zombies[sniper_target_index]
				var proximity = 1.0 - clampf((float(sniper_target["x"]) - BOARD_ORIGIN.x) / maxf(board_size.x, 1.0), 0.0, 1.0)
				zombies[sniper_target_index] = _apply_zombie_damage(sniper_target, float(Defs.PLANTS[kind].get("ultimate_damage", 320.0)) * (1.0 + proximity * 0.7), 0.22)
				effects.append({"shape": "lane_spray", "position": Vector2(center.x + 12.0, _row_center_y(sniper_row) - 10.0), "length": float(sniper_target["x"]) - center.x, "width": 10.0, "radius": board_size.x, "time": 0.2, "duration": 0.2, "color": Color(0.88, 0.96, 1.0, 0.38)})
			_trigger_screen_shake(6.0)
		"dream_disc":
			_sleep_zombies_in_radius(center, 320.0, float(Defs.PLANTS[kind].get("sleep_duration", 6.0)) + 3.0, false)
			_damage_zombies_in_circle(center, 180.0, float(Defs.PLANTS[kind].get("ultimate_damage", 68.0)))
			effects.append({"position": center, "radius": 220.0, "time": 0.34, "duration": 0.34, "color": Color(0.64, 0.58, 0.96, 0.28)})
		"prism_pea":
			var ppos = center
			for angle_deg in [-60, -30, 0, 30, 60]:
				var angle_rad = deg_to_rad(float(angle_deg))
				var dir = Vector2(cos(angle_rad), sin(angle_rad))
				projectiles.append({
					"kind": "prism_burst",
					"row": row,
					"position": ppos,
					"speed": dir.x * 420.0,
					"velocity_y": dir.y * 420.0,
					"damage": 120.0,
					"slow_duration": 0.0,
					"color": Color(0.4, 0.8, 1.0),
					"radius": 9.0,
					"reflected": false,
					"fire": false,
					"free_aim": true,
				})
			effects.append({"position": ppos, "radius": 120.0, "time": 0.6, "duration": 0.6, "color": Color(0.4, 0.8, 1.0, 0.7)})
		"magnet_daisy":
			var mpos = center
			for z in zombies:
				var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
				if mpos.distance_to(zpos) < 500.0:
					z["x"] = float(z["x"]) - 180.0
					z["frozen_timer"] = max(float(z.get("frozen_timer", 0.0)), 2.5)
					z["flash"] = 0.3
			effects.append({"position": mpos, "radius": 500.0, "time": 1.2, "duration": 1.2, "color": Color(0.8, 0.3, 1.0, 0.5)})
			_trigger_screen_shake(6.0)
		"thorn_cactus":
			var tpos = center
			for angle_deg in range(0, 360, 20):
				var angle_rad = deg_to_rad(float(angle_deg))
				var dir = Vector2(cos(angle_rad), sin(angle_rad))
				projectiles.append({
					"kind": "thorn_spike",
					"row": row,
					"position": tpos,
					"speed": dir.x * 340.0,
					"velocity_y": dir.y * 340.0,
					"damage": 60.0,
					"slow_duration": 0.0,
					"color": Color(0.4, 0.7, 0.2),
					"radius": 7.0,
					"reflected": false,
					"fire": false,
					"free_aim": true,
				})
			plant["health"] = min(float(plant["health"]) + float(plant.get("max_health", 200.0)) * 0.4, float(plant.get("max_health", 200.0)))
			effects.append({"position": tpos, "radius": 160.0, "time": 0.8, "duration": 0.8, "color": Color(0.4, 0.7, 0.2, 0.6)})
		"bubble_lotus":
			for row_idx in range(grid.size()):
				for col_idx in range(grid[row_idx].size()):
					var cell = grid[row_idx][col_idx]
					if cell != null and cell.get("kind", "") != "":
						cell["armor"] = float(cell.get("armor", 0.0)) + 600.0
			effects.append({"position": Vector2(size.x * 0.5, size.y * 0.5), "radius": 700.0, "time": 1.5, "duration": 1.5, "color": Color(0.2, 0.8, 1.0, 0.35)})
		"spiral_bamboo":
			var spos = center
			for lane in range(max(0, row - 2), min(ROWS, row + 3)):
				if not _is_row_active(lane):
					continue
				_spawn_boomerang_projectile(lane, Vector2(spos.x, _row_center_y(lane) - 8.0), spos.x - 12.0, 110.0, int(Defs.PLANTS[kind].get("max_hits", 4)) + 2)
				if not projectiles.is_empty():
					var bolt = projectiles[projectiles.size() - 1]
					bolt["color"] = Color(0.6, 0.9, 0.3)
					bolt["return_damage"] = maxf(float(Defs.PLANTS[kind].get("return_damage", 20.0)) * 2.0, 55.0)
					projectiles[projectiles.size() - 1] = bolt
			effects.append({"position": spos, "radius": 100.0, "time": 0.5, "duration": 0.5, "color": Color(0.6, 0.9, 0.3, 0.7)})
		"honey_blossom":
			var hpos = center
			for _i in range(5):
				var sx = float(randi() % int(size.x))
				var sy = float(randi() % int(size.y))
				_spawn_sun(Vector2(sx, sy - 80.0), sy, "plant")
			for z in zombies:
				if int(z["row"]) == row:
					z["slow_timer"] = max(float(z.get("slow_timer", 0.0)), 6.0)
			effects.append({"position": hpos, "radius": 300.0, "time": 1.0, "duration": 1.0, "color": Color(1.0, 0.85, 0.1, 0.5)})
		"echo_fern":
			var epos = center
			for z in zombies:
				var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
				if epos.distance_to(zpos) < 600.0:
					z["health"] = float(z["health"]) - 180.0
					z["frozen_timer"] = max(float(z.get("frozen_timer", 0.0)), 2.0)
					z["flash"] = 0.4
				effects.append({"position": epos, "radius": 600.0, "time": 1.0, "duration": 1.0, "color": Color(0.5, 0.9, 0.7, 0.45)})
			_trigger_screen_shake(7.0)
		"glow_ivy":
			var gpos = center
			for z in zombies:
				if int(z["row"]) == row:
					z["rooted_timer"] = max(float(z.get("rooted_timer", 0.0)), 4.0)
					z["health"] = float(z["health"]) - 80.0
					z["flash"] = 0.3
			effects.append({"position": gpos, "radius": 400.0, "time": 1.2, "duration": 1.2, "color": Color(0.3, 1.0, 0.6, 0.4)})
		"laser_lily":
			var lpos = center
			for row_off in [-1, 0, 1]:
				var target_row = row + row_off
				if target_row < 0 or target_row >= grid.size():
					continue
				for z in zombies:
					if int(z["row"]) == target_row:
						z["health"] = float(z["health"]) - 400.0
						z["flash"] = 0.5
					var row_y = _row_center_y(target_row)
					effects.append({"position": Vector2(lpos.x, row_y), "radius": 30.0, "time": 0.8, "duration": 0.8, "color": Color(1.0, 0.0, 0.5, 0.9)})
			_trigger_screen_shake(10.0)
		"rock_armor_fruit":
			var rpos = center
			plant["health"] = float(plant.get("max_health", 500.0))
			plant["armor"] = float(plant.get("max_health", 500.0)) * 0.8
			for z in zombies:
				var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
				if rpos.distance_to(zpos) < 350.0:
					z["health"] = float(z["health"]) - 300.0
					z["frozen_timer"] = max(float(z.get("frozen_timer", 0.0)), 1.5)
					z["flash"] = 0.4
			effects.append({"position": rpos, "radius": 350.0, "time": 1.0, "duration": 1.0, "color": Color(0.7, 0.55, 0.3, 0.6)})
			_trigger_screen_shake(12.0)
		"aurora_orchid":
			for row_idx in range(grid.size()):
				for col_idx in range(grid[row_idx].size()):
					var cell = grid[row_idx][col_idx]
					if cell != null and cell.get("kind", "") != "":
						cell["health"] = min(float(cell["health"]) + 200.0, float(cell.get("max_health", 200.0)))
						cell["aurora_buff_timer"] = 12.0
						cell["aurora_buff_ratio"] = 0.7
			effects.append({"position": Vector2(size.x * 0.5, size.y * 0.5), "radius": 800.0, "time": 2.0, "duration": 2.0, "color": Color(0.3, 1.0, 0.8, 0.35)})
		"blast_pomegranate":
			var bpos = center
			for i in range(3):
				var tx = bpos.x + float(i) * 160.0 + 120.0
				var target_row = clampi(row + (i - 1), 0, ROWS - 1)
				var ty = _row_center_y(target_row)
				for z in zombies:
					var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
					if zpos.distance_to(Vector2(tx, ty)) < 140.0:
						z["health"] = float(z["health"]) - 220.0
						z["flash"] = 0.4
				effects.append({"position": Vector2(tx, ty), "radius": 140.0, "time": 0.7, "duration": 0.7, "color": Color(1.0, 0.45, 0.1, 0.7)})
			_trigger_screen_shake(9.0)
		"frost_cypress":
			for z in zombies:
				z["frozen_timer"] = max(float(z.get("frozen_timer", 0.0)), 4.0)
				z["flash"] = 0.3
				effects.append({"position": Vector2(size.x * 0.5, size.y * 0.5), "radius": 900.0, "time": 1.5, "duration": 1.5, "color": Color(0.5, 0.85, 1.0, 0.45)})
			_trigger_screen_shake(8.0)
		"mirror_shroom":
			var mpos = center
			var target_row = row
			for col_idx in range(grid[target_row].size()):
				var cell = grid[target_row][col_idx]
				if cell != null and cell.get("kind", "") != "" and cell["kind"] != "mirror_shroom":
					var cx = _cell_center(target_row, col_idx).x
					var cy = _row_center_y(target_row)
					for z in zombies:
						if int(z["row"]) == target_row and float(z["x"]) > cx:
								z["health"] = float(z["health"]) - 200.0
								z["flash"] = 0.35
				effects.append({"position": mpos, "radius": 300.0, "time": 1.0, "duration": 1.0, "color": Color(0.8, 0.9, 1.0, 0.55)})
		"chain_lotus":
			var clpos = center
			var hit_ids: Array = []
			var dmg = 280.0
			for _chain in range(8):
				var best_z = null
				var best_dist = 9999.0
				for z in zombies:
					if z.get("id", -1) in hit_ids:
						continue
					var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
					var d = clpos.distance_to(zpos)
					if d < best_dist:
						best_dist = d
						best_z = z
					if best_z == null:
						break
					best_z["health"] = float(best_z["health"]) - dmg
					best_z["flash"] = 0.4
					hit_ids.append(best_z.get("id", -1))
					clpos = Vector2(float(best_z["x"]), _row_center_y(int(best_z["row"])))
					dmg = max(dmg * 0.85, 60.0)
			effects.append({"position": center, "radius": 200.0, "time": 0.8, "duration": 0.8, "color": Color(0.2, 0.9, 0.8, 0.6)})
		"plasma_shroom":
			var pspos = center
			for row_off in [-1, 0, 1]:
				var target_row = row + row_off
				if target_row < 0 or target_row >= grid.size():
					continue
				for z in zombies:
					if int(z["row"]) == target_row:
						z["health"] = float(z["health"]) - 350.0
						z["flash"] = 0.5
				effects.append({"position": Vector2(pspos.x, _row_center_y(target_row)), "radius": 200.0, "time": 1.2, "duration": 1.2, "color": Color(0.5, 0.2, 1.0, 0.6)})
			_trigger_screen_shake(10.0)
		"meteor_flower":
			for _i in range(12):
				var tx = float(randi() % int(size.x - 100)) + 50.0
				var ty = _row_center_y(randi() % grid.size())
				for z in zombies:
					var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
					if zpos.distance_to(Vector2(tx, ty)) < 120.0:
						z["health"] = float(z["health"]) - 200.0
						z["flash"] = 0.5
				effects.append({"position": Vector2(tx, ty), "radius": 120.0, "time": 0.6, "duration": 0.6, "color": Color(1.0, 0.6, 0.1, 0.75)})
			_trigger_screen_shake(14.0)
		"destiny_tree":
			for row_idx in range(grid.size()):
				for col_idx in range(grid[row_idx].size()):
					var cell = grid[row_idx][col_idx]
					if cell != null and cell.get("kind", "") != "":
						var mh = float(cell.get("max_health", 200.0))
						if float(cell["health"]) <= 0.01 * mh:
							cell["health"] = mh * 0.5
						else:
							cell["health"] = mh
						cell["destiny_dmg_timer"] = 12.0
						cell["destiny_speed_timer"] = 12.0
						cell["aurora_buff_timer"] = 12.0
						cell["aurora_buff_ratio"] = 0.5
				effects.append({"position": Vector2(size.x * 0.5, size.y * 0.5), "radius": 900.0, "time": 2.5, "duration": 2.5, "color": Color(1.0, 0.9, 0.3, 0.4)})
			_trigger_screen_shake(10.0)
		"abyss_tentacle":
			var apos = center
			var grabbed: Array = []
			for z in zombies:
				var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
				if apos.distance_to(zpos) < 600.0 and grabbed.size() < 5:
					z["health"] = float(z["health"]) - 450.0
					z["rooted_timer"] = max(float(z.get("rooted_timer", 0.0)), 3.0)
					z["flash"] = 0.5
					grabbed.append(z)
					effects.append({"position": zpos, "radius": 60.0, "time": 0.7, "duration": 0.7, "color": Color(0.1, 0.05, 0.3, 0.9)})
			_trigger_screen_shake(9.0)
		"solar_emperor":
			var sepos = center
			for _i in range(15):
				var sx = float(randi() % int(size.x))
				var sy = float(randi() % int(size.y))
				_spawn_sun(Vector2(sx, sy - 100.0), sy, "plant")
			for z in zombies:
				if int(z["row"]) == row:
					z["health"] = float(z["health"]) - 300.0
					z["flash"] = 0.5
			effects.append({"position": sepos, "radius": 500.0, "time": 1.5, "duration": 1.5, "color": Color(1.0, 0.9, 0.1, 0.7)})
			_trigger_screen_shake(11.0)
		"shadow_assassin":
			var sa_sorted = zombies.duplicate()
			sa_sorted.sort_custom(func(a, b): return float(a.get("health", 0)) > float(b.get("health", 0)))
			for i in range(min(5, sa_sorted.size())):
				sa_sorted[i]["health"] = float(sa_sorted[i]["health"]) - 600.0
				sa_sorted[i]["flash"] = 0.5
				var zpos = Vector2(float(sa_sorted[i]["x"]), _row_center_y(int(sa_sorted[i]["row"])))
				effects.append({"position": zpos, "radius": 50.0, "time": 0.4, "duration": 0.4, "color": Color(0.1, 0.05, 0.15, 0.9)})
			_trigger_screen_shake(8.0)
		"core_blossom":
			var cbpos = center
			for z in zombies:
				var zpos = Vector2(float(z["x"]), _row_center_y(int(z["row"])))
				if cbpos.distance_to(zpos) < 450.0:
					z["health"] = float(z["health"]) - 800.0
					z["flash"] = 0.6
			effects.append({"position": cbpos, "radius": 450.0, "time": 1.8, "duration": 1.8, "color": Color(1.0, 0.4, 0.0, 0.7)})
			_trigger_screen_shake(16.0)
		"holy_lotus":
			for row_idx in range(grid.size()):
				for col_idx in range(grid[row_idx].size()):
					var cell = grid[row_idx][col_idx]
					if cell != null and cell.get("kind", "") != "":
						cell["health"] = float(cell.get("max_health", 200.0))
						cell["holy_invincible_timer"] = 3.0
			effects.append({"position": Vector2(size.x * 0.5, size.y * 0.5), "radius": 900.0, "time": 2.0, "duration": 2.0, "color": Color(1.0, 0.95, 0.7, 0.5)})
			_trigger_screen_shake(8.0)
		"chaos_shroom":
			for _i in range(5):
				match randi() % 5:
					0:
						for z in zombies:
							z["health"] = float(z["health"]) - 300.0
							z["flash"] = 0.4
					1:
						for z in zombies:
							z["frozen_timer"] = max(float(z.get("frozen_timer", 0.0)), 3.5)
					2:
						for _j in range(8):
							var sx = float(randi() % int(size.x))
							_spawn_sun(Vector2(sx, 60.0), 120.0, "plant")
					3:
						for row_idx in range(grid.size()):
							for col_idx in range(grid[row_idx].size()):
								var cell = grid[row_idx][col_idx]
								if cell != null and cell.get("kind", "") != "":
									cell["health"] = min(float(cell["health"]) + 150.0, float(cell.get("max_health", 200.0)))
					4:
						for z in zombies:
							z["rooted_timer"] = max(float(z.get("rooted_timer", 0.0)), 4.0)
			effects.append({"position": Vector2(size.x * 0.5, size.y * 0.5), "radius": 800.0, "time": 1.5, "duration": 1.5, "color": Color(float(randf()), float(randf()), float(randf()), 0.6)})
			_trigger_screen_shake(10.0)


func _has_any_enemy_zombie() -> bool:
	return _ensure_plant_runtime().has_any_enemy_zombie()


func _has_zombie_behind(row: int, plant_x: float, range_limit: float = 10000.0) -> bool:
	return _ensure_plant_runtime().has_zombie_behind(row, plant_x, range_limit)


func _has_balloon_target_ahead(row: int, plant_x: float, range_limit: float = 10000.0) -> bool:
	return _ensure_plant_runtime().has_balloon_target_ahead(row, plant_x, range_limit)


func _update_cactus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_cactus(plant, delta, row, col)


func _update_blover(plant: Dictionary, delta: float, _row: int, _col: int) -> bool:
	return _ensure_plant_runtime().update_blover(plant, delta, _row, _col)


func _update_split_pea(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_split_pea(plant, delta, row, col)


func _spawn_starfruit_projectile(row: int, position: Vector2, speed: float, velocity_y: float) -> void:
	_ensure_plant_runtime().spawn_starfruit_projectile(row, position, speed, velocity_y)


func _update_starfruit(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_starfruit(plant, delta, row, col)


func _strip_metal_from_zombie(zombie: Dictionary) -> Dictionary:
	return _ensure_plant_runtime().strip_metal_from_zombie(zombie)


func _can_magnet_strip(zombie: Dictionary) -> bool:
	return _ensure_plant_runtime().can_magnet_strip(zombie)


func _update_magnet_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_magnet_shroom(plant, delta, row, col)


func _update_basic_shooter(plant: Dictionary, delta: float, row: int, col: int, projectile_color: Color, slow_duration: float) -> void:
	_ensure_plant_runtime().update_basic_shooter(plant, delta, row, col, projectile_color, slow_duration)


func _update_shooter_plant_food(plant: Dictionary, delta: float, row: int, col: int, projectile_color: Color, slow_duration: float, volley_count: int, volley_interval: float) -> bool:
	return _ensure_plant_runtime().update_shooter_plant_food(plant, delta, row, col, projectile_color, slow_duration, volley_count, volley_interval)


func _update_repeater(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_repeater(plant, delta, row, col)


func _threepeater_rows(row: int) -> Array:
	return _ensure_plant_runtime().threepeater_rows(row)


func _update_threepeater(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_threepeater(plant, delta, row, col)


func _threepeater_projectile_spawn_position(col: int, lane: int) -> Vector2:
	return _ensure_plant_runtime().threepeater_projectile_spawn_position(col, lane)


func _spawn_boomerang_projectile(row: int, spawn_position: Vector2, anchor_x: float, damage: float, max_targets: int) -> void:
	_ensure_plant_runtime().spawn_boomerang_projectile(row, spawn_position, anchor_x, damage, max_targets)


func _spawn_sakura_projectile(row: int, spawn_position: Vector2, damage: float, velocity_y: float = 0.0) -> void:
	_ensure_plant_runtime().spawn_sakura_projectile(row, spawn_position, damage, velocity_y)


func _update_boomerang_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_boomerang_shooter(plant, delta, row, col)


func _update_sakura_shooter(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_sakura_shooter(plant, delta, row, col)


func _update_lotus_lancer(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_lotus_lancer(plant, delta, row, col)


func _spawn_mist_projectile(row: int, spawn_position: Vector2, damage: float, slow_duration: float, splash_radius: float, reveal_duration: float) -> void:
	_ensure_plant_runtime().spawn_mist_projectile(row, spawn_position, damage, slow_duration, splash_radius, reveal_duration)


func _apply_mist_bloom_splash(center: Vector2, projectile: Dictionary, main_uid: int) -> void:
	_ensure_plant_runtime().apply_mist_bloom_splash(center, projectile, main_uid)


func _update_mist_orchid(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_mist_orchid(plant, delta, row, col)


func _update_anchor_fern(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_anchor_fern(plant, delta, row, col)


func _spawn_glowvine_projectile(row: int, spawn_position: Vector2, damage: float) -> void:
	_ensure_plant_runtime().spawn_glowvine_projectile(row, spawn_position, damage)


func _emit_glowvine_burst(center: Vector2, origin_row: int, damage: float) -> void:
	_ensure_plant_runtime().emit_glowvine_burst(center, origin_row, damage)


func _update_glowvine(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_glowvine(plant, delta, row, col)


func _spawn_bog_pool(center: Vector2, radius: float, duration: float) -> void:
	_ensure_plant_runtime().spawn_bog_pool(center, radius, duration)


func _update_brine_pot(plant: Dictionary, delta: float, _row: int, _col: int) -> void:
	_ensure_plant_runtime().update_brine_pot(plant, delta, _row, _col)


func _update_storm_reed(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_storm_reed(plant, delta, row, col)


func _spawn_moonforge_projectile(origin: Vector2, target: Vector2, damage: float, splash_radius: float) -> void:
	_ensure_plant_runtime().spawn_moonforge_projectile(origin, target, damage, splash_radius)


func _explode_moonforge_projectile(projectile: Dictionary, impact: Vector2) -> void:
	_ensure_plant_runtime().explode_moonforge_projectile(projectile, impact)


func _update_moonforge(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_moonforge(plant, delta, row, col)


func _update_mirror_reed(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_mirror_reed(plant, delta, row, col)


func _update_frost_fan(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_frost_fan(plant, delta, row, col)


func _find_squash_target(row: int, center_x: float, range_limit: float) -> int:
	return _ensure_plant_runtime().find_squash_target(row, center_x, range_limit)


func _resolve_squash_impact(plant: Dictionary, row: int, col: int) -> void:
	_ensure_plant_runtime().resolve_squash_impact(plant, row, col)


func _update_squash(plant: Dictionary, row: int, col: int, delta: float = 0.0) -> bool:
	return _ensure_plant_runtime().update_squash(plant, row, col, delta)


func _find_kelp_target(row: int, center_x: float) -> int:
	return _ensure_plant_runtime().find_kelp_target(row, center_x)


func _update_tangle_kelp(_plant: Dictionary, row: int, col: int) -> bool:
	return _ensure_plant_runtime().update_tangle_kelp(_plant, row, col)


func _update_spikeweed(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_spikeweed(plant, delta, row, col)


func _update_torchwood(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_torchwood(plant, delta, row, col)


func _update_vine_lasher(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_vine_lasher(plant, delta, row, col)


func _update_pepper_mortar(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_pepper_mortar(plant, delta, row, col)


func _update_pulse_bulb(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_pulse_bulb(plant, delta, row, col)


func _update_sun_bean(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_sun_bean(plant, delta, row, col)


func _update_sun_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_sun_shroom(plant, delta, row, col)


func _update_fume_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_fume_shroom(plant, delta, row, col)


func _update_scaredy_shroom(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_scaredy_shroom(plant, delta, row, col)


func _update_grave_buster(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	return _ensure_plant_runtime().update_grave_buster(plant, delta, row, col)


func _update_moon_lotus(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_moon_lotus(plant, delta, row, col)


func _update_prism_grass(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_prism_grass(plant, delta, row, col)


func _update_lantern_bloom(plant: Dictionary, _delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_lantern_bloom(plant, _delta, row, col)


func _update_meteor_gourd(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_meteor_gourd(plant, delta, row, col)


func _update_root_snare(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_root_snare(plant, delta, row, col)


func _update_thunder_pine(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_thunder_pine(plant, delta, row, col)


func _update_dream_drum(plant: Dictionary, _delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_dream_drum(plant, _delta, row, col)


func _update_wind_orchid(plant: Dictionary, delta: float, row: int, col: int) -> void:
	_ensure_plant_runtime().update_wind_orchid(plant, delta, row, col)


func _spawn_projectile(row: int, spawn_position: Vector2, projectile_color: Color, damage: float, slow_duration: float, speed: float = 460.0, radius: float = 8.0) -> void:
	_ensure_projectile_runtime().spawn_projectile(row, spawn_position, projectile_color, damage, slow_duration, speed, radius)


func _spawn_fire_projectile(row: int, spawn_position: Vector2, damage: float, speed: float = 500.0, radius: float = 9.0) -> void:
	_ensure_projectile_runtime().spawn_fire_projectile(row, spawn_position, damage, speed, radius)


func _update_projectiles(delta: float) -> void:
	if boss_time_stop_timer > 0.0:
		return
	_ensure_projectile_runtime().update_projectiles(delta)


func _spawn_bowling_roller(row: int, col: int, empowered: bool = false) -> void:
	_ensure_projectile_runtime().spawn_bowling_roller(row, col, empowered)


func _update_rollers(delta: float) -> void:
	_ensure_projectile_runtime().update_rollers(delta)


func _can_target_empty_bowling_lane_with_plant_food(row: int, col: int) -> bool:
	if not _is_bowling_level():
		return false
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return false
	if not _is_row_active(row):
		return false
	return _available_seed_cards_for_level(current_level).has("wallnut_bowling")


func _zombie_in_bog(zombie: Dictionary) -> bool:
	var zombie_center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
	for effect in effects:
		if String(effect.get("shape", "")) != "bog_pool":
			continue
		if Vector2(effect["position"]).distance_to(zombie_center) <= float(effect.get("radius", 0.0)):
			return true
	return false


func _push_plant_chain_left(row: int, col: int) -> bool:
	var start_col := col
	while start_col > 0 and _targetable_plant_at(row, start_col - 1) != null:
		start_col -= 1
	if start_col <= 0:
		return false
	var moved: Array = []
	for current_col in range(start_col, col + 1):
		var plant = _targetable_plant_at(row, current_col)
		if plant == null:
			continue
		if float(plant.get("rooted_timer", 0.0)) > 0.0:
			return false
		moved.append({
			"col": current_col,
			"plant": plant,
			"support": grid[row][current_col] == null,
		})
	for entry_variant in moved:
		var entry = Dictionary(entry_variant)
		if bool(entry["support"]):
			support_grid[row][int(entry["col"])] = null
		else:
			grid[row][int(entry["col"])] = null
	for entry_variant in moved:
		var entry = Dictionary(entry_variant)
		var new_col = int(entry["col"]) - 1
		var plant: Dictionary = entry["plant"]
		plant["col"] = new_col
		plant["push_timer"] = 0.26
		plant["push_duration"] = 0.26
		plant["push_offset_x"] = CELL_SIZE.x
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.12)
		if bool(entry["support"]):
			support_grid[row][new_col] = plant
		else:
			grid[row][new_col] = plant
	return true


func _relocate_random_top_plant_for_sakuya() -> bool:
	var source_cells: Array = []
	for row_variant in active_rows:
		var row = int(row_variant)
		for col in range(COLS):
			var plant_variant = grid[row][col]
			if plant_variant == null:
				continue
			if float(plant_variant.get("rooted_timer", 0.0)) > 0.0:
				continue
			source_cells.append(Vector2i(row, col))
	if source_cells.is_empty():
		return false
	source_cells.shuffle()
	for source_variant in source_cells:
		var source = Vector2i(source_variant)
		var plant = Dictionary(grid[source.x][source.y])
		var kind = String(plant.get("kind", ""))
		var destination_cells: Array = []
		for row_variant in active_rows:
			var row = int(row_variant)
			for col in range(COLS):
				if row == source.x and col == source.y:
					continue
				if grid[row][col] != null:
					continue
				if _placement_error(kind, row, col) != "":
					continue
				destination_cells.append(Vector2i(row, col))
		if destination_cells.is_empty():
			continue
		var destination = Vector2i(destination_cells[rng.randi_range(0, destination_cells.size() - 1)])
		grid[source.x][source.y] = null
		plant["row"] = destination.x
		plant["col"] = destination.y
		plant["push_timer"] = 0.34
		plant["push_duration"] = 0.34
		plant["push_offset_x"] = float(source.y - destination.y) * CELL_SIZE.x
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.16)
		grid[destination.x][destination.y] = plant
		effects.append({
			"shape": "arcane_circle",
			"position": _cell_center(source.x, source.y) + Vector2(0.0, -10.0),
			"radius": 30.0,
			"time": 0.24,
			"duration": 0.24,
			"anim_speed": 7.4,
			"color": Color(0.84, 0.92, 1.0, 0.16),
		})
		effects.append({
			"shape": "glow_burst",
			"position": _cell_center(destination.x, destination.y) + Vector2(0.0, -10.0),
			"radius": 54.0,
			"time": 0.3,
			"duration": 0.3,
			"color": Color(0.9, 0.96, 1.0, 0.22),
		})
		return true
	return false


func _update_sakuya_time_stop_relocation(zombie: Dictionary, delta: float) -> Dictionary:
	if boss_time_stop_timer <= 0.0:
		zombie["sakuya_relocate_timer"] = 0.0
		zombie["sakuya_relocations_remaining"] = 0
		return zombie
	var relocations_remaining = int(zombie.get("sakuya_relocations_remaining", 0))
	if relocations_remaining <= 0:
		return zombie
	var relocate_interval = maxf(float(zombie.get("sakuya_relocate_interval", 0.32)), 0.08)
	var relocate_timer = float(zombie.get("sakuya_relocate_timer", relocate_interval)) - delta
	while relocate_timer <= 0.0 and relocations_remaining > 0:
		if _relocate_random_top_plant_for_sakuya():
			zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.08)
		relocations_remaining -= 1
		relocate_timer += relocate_interval
	zombie["sakuya_relocate_timer"] = relocate_timer
	zombie["sakuya_relocations_remaining"] = relocations_remaining
	return zombie


func _update_tornado_entry(zombie: Dictionary, delta: float) -> Dictionary:
	if not bool(zombie.get("tornado_entry", false)):
		return zombie
	zombie["x"] -= float(Defs.ZOMBIES["tornado_zombie"].get("entry_speed", 760.0)) * delta
	if float(zombie["x"]) <= float(zombie.get("tornado_target_x", zombie["x"])):
		zombie["x"] = float(zombie.get("tornado_target_x", zombie["x"]))
		zombie["tornado_entry"] = false
		zombie["base_speed"] = minf(18.0, float(Defs.ZOMBIES["tornado_zombie"]["speed"]))
		zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.16)
		effects.append({
			"shape": "tornado_swirl",
			"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 12.0),
			"radius": 54.0,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.82, 0.96, 1.0, 0.26),
		})
	return zombie


func _update_squash_zombie_attack(zombie: Dictionary, delta: float) -> Dictionary:
	if not bool(zombie.get("squash_active", false)):
		var target = _find_bite_target(int(zombie["row"]), float(zombie["x"]))
		if target.y == -1:
			return zombie
		var target_center = _cell_center(target.x, target.y)
		if float(zombie["x"]) > target_center.x + float(Defs.ZOMBIES["squash_zombie"]["leap_range"]):
			return zombie
		zombie["squash_active"] = true
		zombie["squash_timer"] = 0.34
		zombie["squash_duration"] = 0.34
		zombie["squash_from_x"] = float(zombie["x"])
		zombie["squash_to_x"] = target_center.x + 6.0
		zombie["squash_target_row"] = target.x
		zombie["squash_target_col"] = target.y
		zombie["squash_hit"] = false
		return zombie
	zombie["squash_timer"] = maxf(0.0, float(zombie.get("squash_timer", 0.0)) - delta)
	var duration = maxf(float(zombie.get("squash_duration", 0.34)), 0.01)
	var ratio = 1.0 - clampf(float(zombie["squash_timer"]) / duration, 0.0, 1.0)
	zombie["x"] = lerpf(float(zombie.get("squash_from_x", zombie["x"])), float(zombie.get("squash_to_x", zombie["x"])), ratio)
	zombie["jump_offset"] = -sin(ratio * PI) * 72.0
	if not bool(zombie.get("squash_hit", false)) and ratio >= 0.78:
		zombie["squash_hit"] = true
		var impact = _cell_center(int(zombie.get("squash_target_row", zombie["row"])), int(zombie.get("squash_target_col", 0)))
		_damage_plants_in_circle(impact, 74.0, float(Defs.ZOMBIES["squash_zombie"]["slam_damage"]))
		effects.append({
			"shape": "squash_slam",
			"position": impact,
			"radius": 86.0,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.7, 0.96, 0.22, 0.34),
		})
	if float(zombie["squash_timer"]) <= 0.0:
		zombie["squash_active"] = false
		zombie["jump_offset"] = 0.0
		zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.24)
	return zombie


func _update_zombies(delta: float) -> void:
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if boss_time_stop_timer > 0.0 and String(zombie.get("kind", "")) != "sakuya_boss":
			zombies[i] = zombie
			continue
		if String(zombie.get("kind", "")) == "sakuya_boss" and boss_time_stop_timer > 0.0:
			zombie = _update_sakuya_time_stop_relocation(zombie, delta)
		zombie["flash"] = maxf(0.0, float(zombie["flash"]) - delta)
		zombie["slow_timer"] = maxf(0.0, float(zombie["slow_timer"]) - delta)
		zombie["rooted_timer"] = maxf(0.0, float(zombie.get("rooted_timer", 0.0)) - delta)
		zombie["bite_timer"] = maxf(0.0, float(zombie.get("bite_timer", 0.0)) - delta)
		zombie["impact_timer"] = maxf(0.0, float(zombie.get("impact_timer", 0.0)) - delta)
		zombie["special_pause_timer"] = maxf(0.0, float(zombie.get("special_pause_timer", 0.0)) - delta)
		zombie["revealed_timer"] = maxf(0.0, float(zombie.get("revealed_timer", 0.0)) - delta)
		zombie["lane_shift_timer"] = maxf(0.0, float(zombie.get("lane_shift_timer", 0.0)) - delta)
		zombie["teleport_cooldown"] = maxf(0.0, float(zombie.get("teleport_cooldown", 0.0)) - delta)
		zombie["corrode_timer"] = maxf(0.0, float(zombie.get("corrode_timer", 0.0)) - delta)
		zombie["push_cooldown"] = maxf(0.0, float(zombie.get("push_cooldown", 0.0)) - delta)
		zombie["launch_cooldown"] = maxf(0.0, float(zombie.get("launch_cooldown", 0.0)) - delta)
		zombie["bungee_timer"] = maxf(0.0, float(zombie.get("bungee_timer", 0.0)) - delta)
		zombie["catapult_cooldown"] = maxf(0.0, float(zombie.get("catapult_cooldown", 0.0)) - delta)
		zombie["imp_throw_cooldown"] = maxf(0.0, float(zombie.get("imp_throw_cooldown", 0.0)) - delta)
		zombie["wolf_escape_timer"] = maxf(0.0, float(zombie.get("wolf_escape_timer", 0.0)) - delta)
		if float(zombie.get("wolf_escape_timer", 0.0)) <= 0.0:
			zombie["wolf_escape_offset"] = 0.0
		else:
			zombie["wolf_escape_offset"] = 28.0 * clampf(float(zombie["wolf_escape_timer"]) / 0.42, 0.0, 1.0)
		zombie["jump_offset"] = 0.0
		if _zombie_in_bog(zombie):
			zombie["slow_timer"] = maxf(float(zombie.get("slow_timer", 0.0)), 0.45)
		if float(zombie.get("corrode_timer", 0.0)) > 0.0 and float(zombie.get("corrode_dps", 0.0)) > 0.0:
			zombie = _apply_zombie_damage(zombie, float(zombie["corrode_dps"]) * delta, 0.04)
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

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "bungee_zombie":
			var bungee_row = int(zombie.get("bungee_target_row", -1))
			var bungee_col = int(zombie.get("bungee_target_col", -1))
			if bungee_row < 0 or bungee_col < 0 or _targetable_plant_at(bungee_row, bungee_col) == null:
				var bungee_target = _choose_bungee_target_cell()
				bungee_row = bungee_target.x
				bungee_col = bungee_target.y
				zombie["bungee_target_row"] = bungee_row
				zombie["bungee_target_col"] = bungee_col
			if bungee_row == -1 or bungee_col == -1:
				zombie["health"] = 0.0
				zombies[i] = zombie
				continue
			if float(zombie.get("special_pause_timer", 0.0)) <= 0.0 and float(zombie.get("bungee_timer", 0.0)) <= 0.0:
				var protected_by_umbrella = _is_cell_protected_by_umbrella(bungee_row, bungee_col)
				var effect_color = Color(0.88, 0.22, 0.22, 0.24)
				if protected_by_umbrella:
					effect_color = Color(0.7, 0.96, 0.64, 0.22)
				elif grid[bungee_row][bungee_col] != null:
					grid[bungee_row][bungee_col] = null
					if _is_roof_support_present(bungee_row, bungee_col):
						support_grid[bungee_row][bungee_col] = null
				else:
					support_grid[bungee_row][bungee_col] = null
				effects.append({
					"shape": "anchor_ring",
					"position": _cell_center(bungee_row, bungee_col) + Vector2(0.0, -12.0),
					"radius": 48.0,
					"time": 0.22,
					"duration": 0.22,
					"color": effect_color,
				})
				zombie["health"] = 0.0
			zombies[i] = zombie
			continue

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "gargantuar":
			if not bool(zombie.get("imp_thrown", false)) and float(zombie["health"]) <= float(zombie["max_health"]) * 0.5 and float(zombie.get("imp_throw_cooldown", 0.0)) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				var imp_spawn_x = maxf(BOARD_ORIGIN.x + 30.0, float(zombie["x"]) - CELL_SIZE.x * 0.85)
				_spawn_zombie_at("imp", int(zombie["row"]), imp_spawn_x, true)
				if not zombies.is_empty() and String(zombies[zombies.size() - 1].get("kind", "")) == "imp":
					var imp = zombies[zombies.size() - 1]
					imp["special_pause_timer"] = maxf(float(imp.get("special_pause_timer", 0.0)), 0.18)
					zombies[zombies.size() - 1] = imp
				zombie["imp_thrown"] = true
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.55)
				effects.append({
					"shape": "push_wave",
					"position": Vector2(float(zombie["x"]) - 12.0, _row_center_y(int(zombie["row"])) - 18.0),
					"radius": 68.0,
					"time": 0.24,
					"duration": 0.24,
					"color": Color(0.78, 0.64, 0.22, 0.28),
				})
				zombies[i] = zombie
				continue
			zombies[i] = zombie

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

		if String(zombie["kind"]) == "jack_in_the_box_zombie" and bool(zombie.get("jack_armed", false)):
			zombie["jack_timer"] = maxf(0.0, float(zombie.get("jack_timer", 0.0)) - delta)
			if float(zombie["jack_timer"]) <= 0.0:
				_explode_jack_in_the_box(zombie)
				zombie["health"] = 0.0
				zombies[i] = zombie
				continue

		if String(zombie["kind"]) == "tornado_zombie" and bool(zombie.get("tornado_entry", false)):
			zombie = _update_tornado_entry(zombie, delta)
			zombies[i] = zombie
			continue

		if String(zombie["kind"]) == "squash_zombie":
			zombie = _update_squash_zombie_attack(zombie, delta)
			if bool(zombie.get("squash_active", false)):
				zombies[i] = zombie
				continue

		if String(zombie["kind"]) == "balloon_zombie" and bool(zombie.get("balloon_flying", false)):
			if float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				zombie["x"] -= _current_zombie_speed(zombie) * delta
			if float(zombie["x"]) <= BOARD_ORIGIN.x - 24.0:
				_lose_level()
				return
			zombies[i] = zombie
			continue

		if String(zombie["kind"]) == "kite_trap":
			var kite_row = int(zombie.get("kite_target_row", -1))
			var kite_col = int(zombie.get("kite_target_col", -1))
			if _targetable_plant_at(kite_row, kite_col) == null:
				zombie["health"] = 0.0
				zombies[i] = zombie
				continue
			zombie["row"] = kite_row
			zombie["x"] = _cell_center(kite_row, kite_col).x + 16.0
			zombies[i] = zombie
			continue

		if String(zombie["kind"]) == "hive_zombie" and not bool(zombie.get("bee_summoned", false)):
			if float(zombie["health"]) <= float(zombie["max_health"]) * 0.5 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				var summon_rows: Array = []
				for row_offset in [-1, 0, 1, 0]:
					var summon_row = clampi(int(zombie["row"]) + row_offset, 0, ROWS - 1)
					if not _is_row_active(summon_row):
						continue
					summon_rows.append(summon_row)
				for summon_index in range(summon_rows.size()):
					var spawn_x = float(zombie["x"]) - 18.0 - summon_index * 10.0
					_spawn_zombie_at("bee_minion", int(summon_rows[summon_index]), spawn_x, true)
					if not zombies.is_empty() and String(zombies[zombies.size() - 1].get("kind", "")) == "bee_minion":
						var bee = zombies[zombies.size() - 1]
						bee["special_pause_timer"] = 0.06
						zombies[zombies.size() - 1] = bee
				zombie["bee_summoned"] = true
				zombie["special_pause_timer"] = 0.32
				effects.append({
					"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 18.0),
					"radius": 62.0,
					"time": 0.22,
					"duration": 0.22,
					"color": Color(1.0, 0.86, 0.22, 0.28),
				})
				zombies[i] = zombie
				continue

		if String(zombie["kind"]) == "turret_zombie":
			if float(zombie.get("launch_cooldown", 0.0)) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				var landing_col = rng.randi_range(4, min(6, COLS - 1))
				_spawn_zombie_at("normal", int(zombie["row"]), _cell_center(int(zombie["row"]), landing_col).x, true)
				if not zombies.is_empty() and String(zombies[zombies.size() - 1].get("kind", "")) == "normal":
					var launched = zombies[zombies.size() - 1]
					var launched_health = float(Defs.ZOMBIES["conehead"]["health"]) + 60.0
					launched["health"] = launched_health
					launched["max_health"] = launched_health
					launched["special_pause_timer"] = 0.14
					zombies[zombies.size() - 1] = launched
				zombie["launch_cooldown"] = 6.2
				zombie["special_pause_timer"] = 0.34
				effects.append({
					"shape": "push_wave",
					"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 20.0),
					"radius": 70.0,
					"time": 0.24,
					"duration": 0.24,
					"color": Color(0.94, 0.58, 0.22, 0.26),
				})
			zombies[i] = zombie
			continue

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "flywheel_zombie":
			zombie["flywheel_cooldown"] = maxf(0.0, float(zombie.get("flywheel_cooldown", 0.0)) - delta)
			if float(zombie["flywheel_cooldown"]) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				var flywheel_target = _find_front_plant_target(int(zombie["row"]), float(zombie["x"]))
				if flywheel_target.y != -1:
					var flywheel_plant = _targetable_plant_at(flywheel_target.x, flywheel_target.y)
					if flywheel_plant != null:
						flywheel_plant["health"] -= float(Defs.ZOMBIES["flywheel_zombie"].get("throw_damage", 110.0))
						flywheel_plant["flash"] = maxf(float(flywheel_plant.get("flash", 0.0)), 0.18)
						_set_targetable_plant(flywheel_target.x, flywheel_target.y, flywheel_plant)
					var flywheel_target_pos = _cell_center(flywheel_target.x, flywheel_target.y)
					effects.append({
						"shape": "storm_arc",
						"position": Vector2(float(zombie["x"]) - 8.0, _row_center_y(int(zombie["row"])) - 18.0),
						"target": flywheel_target_pos + Vector2(0.0, -10.0),
						"radius": 56.0,
						"time": 0.22,
						"duration": 0.22,
						"color": Color(0.82, 0.9, 0.96, 0.3),
					})
					zombie["special_pause_timer"] = 0.24
				zombie["flywheel_cooldown"] = float(Defs.ZOMBIES["flywheel_zombie"].get("throw_cooldown", 5.2))
				zombies[i] = zombie
				continue

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "mech_zombie":
			zombie["laser_cooldown"] = maxf(0.0, float(zombie.get("laser_cooldown", 0.0)) - delta)
			if float(zombie["laser_cooldown"]) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				var beam_hit = _damage_plants_in_row_segment(int(zombie["row"]), BOARD_ORIGIN.x, float(zombie["x"]) - 12.0, float(Defs.ZOMBIES["mech_zombie"].get("laser_damage", 92.0)))
				effects.append({
					"shape": "lane_spray",
					"position": Vector2(BOARD_ORIGIN.x, _row_center_y(int(zombie["row"])) - 8.0),
					"length": maxf(0.0, float(zombie["x"]) - BOARD_ORIGIN.x - 12.0),
					"width": 12.0,
					"radius": board_size.x,
					"time": 0.18,
					"duration": 0.18,
					"color": Color(0.74, 0.96, 1.0, 0.34 if beam_hit else 0.24),
				})
				zombie["laser_cooldown"] = float(Defs.ZOMBIES["mech_zombie"].get("laser_cooldown", 4.8))
				zombie["special_pause_timer"] = 0.32
				zombies[i] = zombie
				continue

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "wizard_zombie":
			zombie["wizard_cooldown"] = maxf(0.0, float(zombie.get("wizard_cooldown", 0.0)) - delta)
			if float(zombie["wizard_cooldown"]) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				var spell_roll = rng.randi_range(0, 2)
				var spell_center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 10.0)
				match spell_roll:
					0:
						_sleep_plants_in_radius(spell_center, 145.0, 4.2)
						effects.append({"position": spell_center, "radius": 145.0, "time": 0.24, "duration": 0.24, "color": Color(0.74, 0.6, 0.98, 0.24)})
					1:
						for ally_index in range(zombies.size()):
							var ally = zombies[ally_index]
							if not _is_enemy_zombie(ally):
								continue
							var ally_pos = Vector2(float(ally["x"]), _row_center_y(int(ally["row"])))
							if ally_pos.distance_to(spell_center) > 160.0:
								continue
							ally["health"] = minf(float(ally["max_health"]), float(ally["health"]) + 140.0)
							ally["flash"] = maxf(float(ally.get("flash", 0.0)), 0.12)
							zombies[ally_index] = ally
						effects.append({"position": spell_center, "radius": 160.0, "time": 0.24, "duration": 0.24, "color": Color(0.34, 0.9, 1.0, 0.22)})
					2:
						_damage_plants_in_row_segment(int(zombie["row"]), float(zombie["x"]) - CELL_SIZE.x * 1.4, float(zombie["x"]) + 18.0, 52.0)
						effects.append({"shape": "push_wave", "position": spell_center, "radius": 72.0, "time": 0.22, "duration": 0.22, "color": Color(1.0, 0.58, 0.26, 0.24)})
				zombie["wizard_cooldown"] = float(Defs.ZOMBIES["wizard_zombie"].get("cast_interval", 5.8))
				zombie["special_pause_timer"] = 0.36
				zombies[i] = zombie
				continue

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "wenjie_zombie":
			if float(zombie.get("lane_shift_timer", 0.0)) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0 and not bool(zombie.get("jumping", false)):
				var drift_row = _choose_random_active_row_for_kind("wenjie_zombie", int(zombie["row"]))
				zombie["lane_shift_timer"] = float(Defs.ZOMBIES["wenjie_zombie"].get("lane_shift_interval", 1.6)) + rng.randf_range(0.5, 1.3)
				if drift_row != int(zombie["row"]):
					zombie["jumping"] = true
					zombie["jump_t"] = 0.0
					zombie["jump_from_x"] = float(zombie["x"])
					zombie["jump_to_x"] = float(zombie["x"]) - 14.0
					zombie["jump_duration"] = 0.34
					zombie["jump_row_to"] = drift_row
					zombie["jump_row_switched"] = false
					zombie["special_pause_timer"] = 0.18
					effects.append({
						"shape": "push_wave",
						"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + 8.0),
						"radius": 44.0,
						"time": 0.18,
						"duration": 0.18,
						"color": Color(0.42, 0.9, 1.0, 0.18),
					})
					zombies[i] = zombie
					continue

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "enderman_zombie":
			if float(zombie.get("teleport_cooldown", 0.0)) <= 0.0:
				var target_row = _choose_random_active_row_for_kind("enderman_zombie", int(zombie["row"]))
				var target_col = rng.randi_range(1, max(1, COLS - 2))
				zombie["row"] = target_row
				zombie["x"] = _cell_center(target_row, target_col).x + rng.randf_range(-16.0, 16.0)
				zombie["teleport_cooldown"] = float(Defs.ZOMBIES["enderman_zombie"].get("teleport_interval", 2.2)) + rng.randf_range(0.2, 0.8)
				zombie["special_pause_timer"] = 0.32
				effects.append({
					"shape": "glow_burst",
					"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 10.0),
					"radius": 64.0,
					"time": 0.2,
					"duration": 0.2,
					"color": Color(0.54, 0.32, 0.82, 0.22),
				})
			zombies[i] = zombie
			continue

		if String(zombie["kind"]) == "digger_zombie" and bool(zombie.get("digger_tunneling", false)):
			zombie = _update_digger_tunnel(zombie, delta)
			zombies[i] = zombie
			continue

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
				var cycle_length = 3
				var base_interval = 7.6
				match String(zombie["kind"]):
					"rumia_boss":
						cycle_length = 4
						base_interval = 6.0
					"koakuma_boss":
						base_interval = 6.9
					"patchouli_boss":
						cycle_length = 5
						base_interval = 6.8
					"sakuya_boss":
						cycle_length = 10
						base_interval = 6.3
					"remilia_boss":
						cycle_length = 10
						base_interval = 5.9
				zombie["boss_skill_cycle"] = (int(zombie["boss_skill_cycle"]) + 1) % cycle_length
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

		if String(zombie["kind"]) == "pogo_zombie" and bool(zombie.get("pogo_active", false)) and not bool(zombie.get("jumping", false)):
			var pogo_target = _find_jump_target(int(zombie["row"]), float(zombie["x"]))
			if pogo_target.y != -1:
				var pogo_plant = grid[pogo_target.x][pogo_target.y]
				if pogo_plant != null and String(pogo_plant["kind"]) == "tallnut":
					zombie["pogo_active"] = false
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.18)
				else:
					var plant_center_x = _cell_center(pogo_target.x, pogo_target.y).x
					zombie["jumping"] = true
					zombie["jump_t"] = 0.0
					zombie["jump_from_x"] = float(zombie["x"])
					zombie["jump_to_x"] = maxf(BOARD_ORIGIN.x - 18.0, plant_center_x - CELL_SIZE.x + 4.0)
					zombie["jump_duration"] = 0.32
					zombie["jump_row_to"] = int(zombie["row"])
					zombie["jump_row_switched"] = true
					zombies[i] = zombie
					continue

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

		if String(zombie["kind"]) == "digger_zombie" and bool(zombie.get("digger_reversed", false)):
			zombie = _update_reversed_digger(zombie, delta)
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
			if int(zombie["row"]) >= 0 and int(zombie["row"]) < mowers.size() and float(zombie["x"]) <= BOARD_ORIGIN.x - 24.0:
				var zomboni_mower = mowers[int(zombie["row"])]
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
			if int(zombie["row"]) >= 0 and int(zombie["row"]) < mowers.size() and float(zombie["x"]) <= BOARD_ORIGIN.x - 24.0:
				var boat_mower = mowers[int(zombie["row"])]
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

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "ladder_zombie" and float(zombie.get("shield_health", 0.0)) > 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
			var ladder_target = _find_bite_target(int(zombie["row"]), float(zombie["x"]))
			if ladder_target.y != -1:
				var ladder_plant = _targetable_plant_at(ladder_target.x, ladder_target.y)
				if ladder_plant != null and _is_ladderable_plant(ladder_plant) and not bool(ladder_plant.get("laddered", false)):
					ladder_plant["laddered"] = true
					ladder_plant["flash"] = maxf(float(ladder_plant.get("flash", 0.0)), 0.18)
					_set_targetable_plant(ladder_target.x, ladder_target.y, ladder_plant)
					zombie["shield_health"] = 0.0
					zombie["max_shield_health"] = 0.0
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.42)
					effects.append({
						"shape": "push_wave",
						"position": _cell_center(ladder_target.x, ladder_target.y) + Vector2(0.0, -8.0),
						"radius": 54.0,
						"time": 0.2,
						"duration": 0.2,
						"color": Color(0.82, 0.72, 0.52, 0.24),
					})
					zombies[i] = zombie
					continue

		if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "catapult_zombie":
			var catapult_target = _find_catapult_target(int(zombie["row"]))
			if catapult_target.y != -1:
				if float(zombie.get("catapult_cooldown", 0.0)) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
					var rock_target = _cell_center(catapult_target.x, catapult_target.y) + Vector2(0.0, -12.0)
					if _is_cell_protected_by_umbrella(catapult_target.x, catapult_target.y):
						effects.append({
							"shape": "anchor_ring",
							"position": rock_target,
							"radius": 56.0,
							"time": 0.22,
							"duration": 0.22,
							"color": Color(0.72, 0.96, 0.62, 0.22),
						})
					else:
						_damage_plant_cell(catapult_target.x, catapult_target.y, float(Defs.ZOMBIES["catapult_zombie"].get("lob_damage", 100.0)), 0.35)
						effects.append({
							"position": rock_target,
							"radius": 50.0,
							"time": 0.24,
							"duration": 0.24,
							"color": Color(0.72, 0.66, 0.58, 0.28),
						})
					zombie["catapult_cooldown"] = float(Defs.ZOMBIES["catapult_zombie"].get("lob_interval", 2.8))
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.34)
				zombies[i] = zombie
				continue

		if String(zombie["kind"]) == "excavator_zombie":
			var push_target = _find_bite_target(int(zombie["row"]), float(zombie["x"]))
			if push_target.y != -1 and float(zombie.get("push_cooldown", 0.0)) <= 0.0 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				if _push_plant_chain_left(push_target.x, push_target.y):
					zombie["push_cooldown"] = float(Defs.ZOMBIES["excavator_zombie"]["push_pause"]) + 0.2
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), float(Defs.ZOMBIES["excavator_zombie"]["push_pause"]))
					zombie["bite_timer"] = maxf(float(zombie.get("bite_timer", 0.0)), 0.18)
					effects.append({
						"shape": "push_wave",
						"position": _cell_center(push_target.x, max(push_target.y - 1, 0)) + Vector2(0.0, 10.0),
						"radius": 62.0,
						"time": 0.22,
						"duration": 0.22,
						"color": Color(0.82, 0.66, 0.32, 0.26),
					})
					zombies[i] = zombie
					continue

		if String(zombie["kind"]) == "wolf_knight_zombie" and bool(zombie.get("mounted", false)):
			var crash_target = _find_bite_target(int(zombie["row"]), float(zombie["x"]))
			if crash_target.y != -1 and float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
				var crash_plant = _targetable_plant_at(crash_target.x, crash_target.y)
				if crash_plant != null:
					var impact_damage = float(Defs.ZOMBIES["wolf_knight_zombie"]["impact_damage"])
					if float(crash_plant.get("armor_health", 0.0)) > 0.0:
						var armor_left = float(crash_plant["armor_health"]) - impact_damage
						if armor_left < 0.0:
							crash_plant["health"] += armor_left
							armor_left = 0.0
						crash_plant["armor_health"] = armor_left
					else:
						crash_plant["health"] -= impact_damage
					crash_plant["flash"] = maxf(float(crash_plant.get("flash", 0.0)), 0.18)
					if float(crash_plant.get("health", 0.0)) <= 0.0:
						_clear_targetable_plant(crash_target.x, crash_target.y)
					else:
						_set_targetable_plant(crash_target.x, crash_target.y, crash_plant)
					zombie["mounted"] = false
					zombie["base_speed"] = float(Defs.ZOMBIES["wolf_knight_zombie"]["speed"])
					zombie["wolf_escape_timer"] = 0.42
					zombie["special_pause_timer"] = 0.18
					zombie["bite_timer"] = 0.18
					effects.append({
						"shape": "push_wave",
						"position": _cell_center(crash_target.x, crash_target.y),
						"radius": 74.0,
						"time": 0.22,
						"duration": 0.22,
						"color": Color(0.9, 0.86, 0.72, 0.24),
					})
					zombies[i] = zombie
					continue

		var target = _find_bite_target(int(zombie["row"]), float(zombie["x"]))
		if target.y != -1:
			var plant = _targetable_plant_at(target.x, target.y)
			if _is_enemy_zombie(zombie) and String(zombie["kind"]) == "janitor_zombie" and plant != null and float(zombie.get("special_pause_timer", 0.0)) <= 0.0 and float(zombie.get("bite_timer", 0.0)) <= 0.0:
				_clear_targetable_plant(target.x, target.y)
				zombie["bite_timer"] = 0.4
				zombie["special_pause_timer"] = 0.32
				effects.append({
					"shape": "push_wave",
					"position": _cell_center(target.x, target.y),
					"radius": 58.0,
					"time": 0.18,
					"duration": 0.18,
					"color": Color(0.78, 0.92, 1.0, 0.18),
				})
				zombies[i] = zombie
				continue
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
			if float(plant.get("holy_invincible_timer", 0.0)) > 0.0:
				pass
			elif float(plant["armor_health"]) > 0.0:
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
			if String(plant["kind"]) == "garlic":
				var redirected_row = _choose_adjacent_valid_row_for_kind(String(zombie["kind"]), int(zombie["row"]))
				if redirected_row != int(zombie["row"]):
					zombie["row"] = redirected_row
					zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.24)
					effects.append({
						"shape": "anchor_ring",
						"position": _cell_center(target.x, target.y) + Vector2(0.0, -8.0),
						"radius": 42.0,
						"time": 0.18,
						"duration": 0.18,
						"color": Color(0.94, 0.92, 0.56, 0.22),
					})
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

		if int(zombie["row"]) >= 0 and int(zombie["row"]) < mowers.size() and float(zombie["x"]) <= BOARD_ORIGIN.x - 24.0:
			var mower = mowers[int(zombie["row"])]
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

		var previous_x = float(mower["x"])
		mower["x"] += MOWER_SPEED * delta
		var hit_min_x = minf(previous_x, float(mower["x"])) - 24.0
		var hit_max_x = maxf(previous_x, float(mower["x"])) + 52.0
		for z in range(zombies.size()):
			var zombie = zombies[z]
			if int(zombie["row"]) != int(mower["row"]):
				continue
			if float(zombie["x"]) >= hit_min_x and float(zombie["x"]) <= hit_max_x:
				zombie["health"] = 0.0
				zombie["killed_by_mower"] = true
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
			if String(effect.get("shape", "")) == "snow_patch":
				var effect_row = int(effect.get("row", -1))
				var effect_col = int(effect.get("col", -1))
				if _cell_terrain_kind(effect_row, effect_col) == "snowfield":
					_set_cell_terrain_kind(effect_row, effect_col, String(effect.get("restore_terrain", "land")))
			effects.remove_at(i)
			continue
		var shape = String(effect.get("shape", ""))
		if shape == "magma_patch" or shape == "coal_patch":
			var effect_row = int(effect.get("row", -1))
			var effect_col = int(effect.get("col", -1))
			var effect_center = _cell_center(effect_row, effect_col)
			var effect_radius = float(effect.get("radius", CELL_SIZE.x * 0.42))
			for zombie_index in range(zombies.size()):
				var zombie = zombies[zombie_index]
				if not _is_enemy_zombie(zombie) or int(zombie["row"]) != effect_row:
					continue
				var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
				if zombie_pos.distance_to(effect_center) > effect_radius:
					continue
				if shape == "magma_patch":
					zombie = _apply_zombie_damage(zombie, float(effect.get("dps", 0.0)) * delta, 0.08)
				else:
					zombie["corrode_timer"] = maxf(float(zombie.get("corrode_timer", 0.0)), 1.2)
					zombie["corrode_dps"] = maxf(float(zombie.get("corrode_dps", 0.0)), float(effect.get("dps", 0.0)))
					if _is_mechanical_zombie_kind(String(zombie.get("kind", ""))):
						zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.16)
				zombies[zombie_index] = zombie
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


func _pick_kite_trap_target() -> Vector2i:
	var candidates: Array = []
	for row in active_rows:
		var row_i = int(row)
		for col in range(min(4, COLS)):
			if _targetable_plant_at(row_i, col) == null:
				continue
			candidates.append(Vector2i(row_i, col))
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return Vector2i(candidates[rng.randi_range(0, candidates.size() - 1)])


func _spawn_kite_trap_from(_zombie: Dictionary) -> void:
	var target = _pick_kite_trap_target()
	if target.y == -1:
		return
	var spawn_x = _cell_center(target.x, target.y).x + 16.0
	_spawn_zombie_at("kite_trap", target.x, spawn_x)
	if zombies.is_empty():
		return
	var kite = zombies[zombies.size() - 1]
	if String(kite.get("kind", "")) != "kite_trap":
		return
	kite["kite_target_row"] = target.x
	kite["kite_target_col"] = target.y
	kite["balloon_flying"] = true
	kite["special_pause_timer"] = 9999.0
	kite["x"] = spawn_x
	kite["flash"] = 0.18
	zombies[zombies.size() - 1] = kite
	effects.append({
		"shape": "anchor_ring",
		"position": _cell_center(target.x, target.y) + Vector2(0.0, -52.0),
		"radius": 44.0,
		"time": 0.24,
		"duration": 0.24,
		"color": Color(0.98, 0.86, 0.48, 0.24),
	})


func _cleanup_dead_zombies() -> void:
	for i in range(zombies.size() - 1, -1, -1):
		var zombie = zombies[i]
		if float(zombie["health"]) > 0.0:
			continue
		total_kills += 1
		# Death VFX
		var death_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		_spawn_death_poof(death_pos, Color(0.5, 0.56, 0.48))
		if _is_stage_ending_boss(zombie):
			_trigger_screen_shake(12.0)
			_spawn_death_poof(death_pos + Vector2(-20.0, -10.0), Color(0.8, 0.4, 0.2))
			_spawn_death_poof(death_pos + Vector2(20.0, 10.0), Color(0.8, 0.4, 0.2))
			batch_spawn_queue = []
			batch_spawn_remaining = 0
			next_event_index = current_level["events"].size()
			var boss_cleanup_text = "Boss 被击退！清理残余僵尸即可过关"
			if bool(zombie.get("killed_by_mower", false)):
				boss_cleanup_text = "大型目标被清掉了！清理残余僵尸即可过关"
			_show_banner(boss_cleanup_text, 2.4)
		if String(zombie["kind"]) == "spear":
			_spawn_spear_obstacle(int(zombie["row"]), float(zombie["x"]))
		if String(zombie["kind"]) == "kite_zombie":
			_spawn_kite_trap_from(zombie)
		if String(zombie.get("kind", "")) == "wither_zombie":
			for patch_row in range(max(0, int(zombie["row"]) - 1), min(ROWS, int(zombie["row"]) + 2)):
				for patch_col in range(max(0, _zombie_cell_col(float(zombie["x"])) - 1), min(COLS, _zombie_cell_col(float(zombie["x"])) + 2)):
					_spawn_wither_patch(patch_row, patch_col, float(Defs.ZOMBIES["wither_zombie"].get("corrupt_duration", 30.0)))
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
			if reward > 0:
				_spawn_coin(Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 18.0), reward)
		var soul_bonus := 0
		for row in range(ROWS):
			for col in range(COLS):
				var plant_variant = _targetable_plant_at(row, col)
				if plant_variant == null:
					continue
				if String(plant_variant.get("kind", "")) != "soul_flower":
					continue
				if not bool(plant_variant.get("ultimate_active", false)):
					continue
				soul_bonus = max(soul_bonus, int(Defs.PLANTS["soul_flower"].get("kill_sun_bonus", 25)) * 2)
		if soul_bonus > 0:
			_spawn_sun(
				Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 18.0),
				_row_center_y(int(zombie["row"])) - 34.0,
				"plant_food",
				soul_bonus
			)
		zombies.remove_at(i)


func _trigger_screen_shake(amount: float) -> void:
	screen_shake_amount = maxf(screen_shake_amount, amount)


func _spawn_death_poof(pos: Vector2, color: Color = Color(0.6, 0.6, 0.6)) -> void:
	for j in range(6):
		var angle = TAU * float(j) / 6.0 + randf() * 0.5
		var speed = 40.0 + randf() * 60.0
		vfx_particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 40.0),
			"life": 0.4 + randf() * 0.3,
			"max_life": 0.7,
			"color": color,
			"size": 3.0 + randf() * 4.0,
		})


func _check_end_state() -> void:
	if _can_finish_level_ignoring_obstacles():
		_win_level()


func _win_level() -> void:
	if battle_state != BATTLE_PLAYING:
		return

	battle_state = BATTLE_WON
	var custom_level = bool(current_level.get("custom_level", false)) or selected_level_index < 0
	if not custom_level and selected_level_index >= 0 and selected_level_index < completed_levels.size():
		completed_levels[selected_level_index] = true
	if not current_level.is_empty():
		current_world_key = _world_key_for_level(current_level)

	# Daily challenge completion
	if current_level.get("id", "") == "每日":
		var first_clear_today = daily_challenge_date != _today_string()
		var reward = 200 if first_clear_today else 0
		if first_clear_today:
			daily_challenge_date = _today_string()
			daily_completed_today = true
			coins_total += reward
		_mark_save_dirty(true)
		var mod_names = ""
		for mod in daily_modifiers:
			if mod_names != "":
				mod_names += ", "
			mod_names += String(mod["name"])
		var reward_line = "今日奖励已领取，本次为练习通关" if not first_clear_today else "奖励金币 +%d" % reward
		_show_message("每日挑战完成!\n修饰: %s\n已消灭 %d 只僵尸\n%s" % [mod_names, total_kills, reward_line], "world_select", "返回")
		return

	var unlocked_new = false
	if not custom_level and selected_level_index + 1 >= unlocked_levels and selected_level_index < Defs.LEVELS.size() - 1:
		unlocked_levels = selected_level_index + 2
		unlocked_new = true

	coins_total += 50

	if _is_endless_level():
		coins_total += max(0, endless_wave * 10)
		_mark_save_dirty(true)
		_show_message("无尽模式结束\n坚持波数: %d\n奖励金币 +%d" % [endless_wave, 50 + max(0, endless_wave * 10)], "world_select", "返回")
		return

	_mark_save_dirty(true)
	var message = "%s 通关\n已消灭 %d 只僵尸\n奖励金币 +50" % [current_level["title"], total_kills]
	if unlocked_new and String(current_level.get("unlock_plant", "")) != "":
		message += "\n解锁植物：%s" % Defs.PLANTS[String(current_level["unlock_plant"])]["name"]

	_show_message(message, "map", "返回地图")
	_show_banner("关卡完成！", 2.0)


func _lose_level() -> void:
	if battle_state != BATTLE_PLAYING:
		return
	battle_state = BATTLE_LOST
	if _is_endless_level():
		if endless_wave > endless_best_wave:
			endless_best_wave = endless_wave
		_mark_save_dirty(true)
		_show_message("%s 失败\n坚持到第 %d 波" % [current_level["title"], max(endless_wave, 1)], "retry_endless", "再次挑战")
		return
	if String(current_level.get("id", "")) == "每日":
		_show_message("%s 失败\n今日挑战尚未完成" % current_level["title"], "retry_daily", "重试挑战")
		return
	_show_message("%s 失败\n僵尸闯进了房子" % current_level["title"], "retry", "重试本关")


func _show_message(text: String, action: String, button_text: String) -> void:
	panel_action = action
	battle_paused = false
	message_label.text = text
	action_button.text = button_text
	message_panel.visible = true


func _on_message_button_pressed() -> void:
	match panel_action:
		"retry":
			_start_level(selected_level_index)
		"retry_endless":
			_enter_endless_mode()
		"retry_daily":
			_enter_daily_challenge()
		"world_select":
			_enter_world_select_mode()
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
			if _is_roof_direct_fire_blocked(plant_x, float(zombie["x"])):
				continue
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


func _has_lane_threat_ignore_roof_direct_fire(row: int, plant_x: float, range_limit: float = 10000.0) -> bool:
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


func _is_hidden_for_direct_fire_ignoring_fog(zombie: Dictionary) -> bool:
	if bool(zombie.get("balloon_flying", false)):
		return true
	if bool(zombie.get("digger_tunneling", false)):
		return true
	if String(zombie.get("kind", "")) == "snorkel" and bool(zombie.get("submerged", false)):
		return true
	return false


func _find_lane_target_ignore_fog(row: int, plant_x: float, range_limit: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not _is_enemy_zombie(zombie):
			continue
		if _is_hidden_for_direct_fire_ignoring_fog(zombie):
			continue
		var distance = float(zombie["x"]) - plant_x
		if distance < -8.0 or distance > range_limit:
			continue
		if _is_roof_direct_fire_blocked(plant_x, float(zombie["x"])):
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _find_storm_reed_target(row: int, trigger_x: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or not _is_enemy_zombie(zombie):
			continue
		if _is_hidden_for_direct_fire_ignoring_fog(zombie):
			continue
		var distance = float(zombie["x"]) - trigger_x
		if distance < 0.0:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _is_hidden_from_lane_attacks(zombie: Dictionary) -> bool:
	var kind = String(zombie.get("kind", ""))
	var zombie_pos = Vector2(float(zombie.get("x", 0.0)), _row_center_y(int(zombie.get("row", -1))))
	if _is_fog_level() and _is_enemy_zombie(zombie) and not _is_position_revealed_by_fog_rules(zombie_pos):
		return true
	if bool(zombie.get("balloon_flying", false)):
		return true
	if bool(zombie.get("digger_tunneling", false)):
		return true
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
		if _is_roof_direct_fire_blocked(plant_x, float(zombie["x"])):
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _find_lane_target_ignore_roof_direct_fire(row: int, plant_x: float, range_limit: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
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


func _find_throw_lane_target(row: int, plant_x: float, range_limit: float) -> int:
	var best_index := -1
	var best_distance := 999999.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if int(zombie["row"]) != row or bool(zombie.get("jumping", false)) or not _is_enemy_zombie(zombie):
			continue
		if _is_hidden_from_lane_attacks(zombie):
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
		if _is_roof_direct_fire_blocked(plant_x, float(zombie["x"])):
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
		if bool(plant_variant.get("laddered", false)) and _is_ladderable_plant(plant_variant):
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


func _apply_ash_hits_in_circle(center: Vector2, radius: float, hits: int = 1, damage: float = 0.0) -> void:
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) > radius:
			continue
		if String(zombie.get("kind", "")) == "mech_zombie":
			zombie["ash_hits_taken"] = int(zombie.get("ash_hits_taken", 0)) + hits
			zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.28)
		if damage > 0.0:
			zombie = _apply_zombie_damage(zombie, damage, 0.18)
		zombies[i] = zombie


func _apply_ash_hits_in_row_segment(row: int, min_x: float, max_x: float, hits: int = 1, damage: float = 0.0) -> void:
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie) or int(zombie["row"]) != row:
			continue
		var zombie_x = float(zombie["x"])
		if zombie_x < min_x or zombie_x > max_x:
			continue
		if String(zombie.get("kind", "")) == "mech_zombie":
			zombie["ash_hits_taken"] = int(zombie.get("ash_hits_taken", 0)) + hits
			zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.28)
		if damage > 0.0:
			zombie = _apply_zombie_damage(zombie, damage, 0.18)
		zombies[i] = zombie


func _apply_zombie_damage(zombie: Dictionary, damage: float, flash_amount: float = 0.12, slow_duration: float = 0.0, ignore_shield: bool = false) -> Dictionary:
	if damage <= 0.0:
		return zombie

	var remaining_damage = damage
	if _is_enemy_zombie(zombie):
		var router_count = _count_alive_enemy_zombies_by_kind("router_zombie")
		if router_count > 0:
			remaining_damage /= pow(float(Defs.ZOMBIES["router_zombie"].get("aura_health_mult", 1.0)), router_count)
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
	return kind == "rumia_boss" or kind == "daiyousei_boss" or kind == "cirno_boss" or kind == "meiling_boss" or kind == "koakuma_boss" or kind == "patchouli_boss" or kind == "sakuya_boss" or kind == "remilia_boss"


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
		"koakuma_boss":
			var min_interval = maxf(2.6, 3.4 - float(phase) * 0.14)
			var max_interval = maxf(min_interval + 0.46, 4.5 - float(phase) * 0.1)
			return rng.randf_range(min_interval, max_interval)
		"patchouli_boss":
			var min_interval = maxf(3.5, 4.6 - float(phase) * 0.14)
			var max_interval = maxf(min_interval + 0.6, 5.8 - float(phase) * 0.12)
			return rng.randf_range(min_interval, max_interval)
		"sakuya_boss":
			var min_interval = maxf(3.2, 4.2 - float(phase) * 0.16)
			var max_interval = maxf(min_interval + 0.58, 5.2 - float(phase) * 0.12)
			return rng.randf_range(min_interval, max_interval)
		"remilia_boss":
			var min_interval = maxf(3.0, 4.1 - float(phase) * 0.14)
			var max_interval = maxf(min_interval + 0.6, 5.1 - float(phase) * 0.1)
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
		"koakuma_boss":
			return Color(0.96, 0.18, 0.34, 0.24)
		"patchouli_boss":
			return Color(0.74, 0.56, 1.0, 0.24)
		"sakuya_boss":
			return Color(0.82, 0.9, 1.0, 0.26)
		"remilia_boss":
			return Color(0.94, 0.2, 0.26, 0.28)
		_:
			return Color(0.94, 0.08, 0.18, 0.22)


func _hover_boss_move_duration(kind: String) -> float:
	match kind:
		"daiyousei_boss":
			return 0.6
		"cirno_boss":
			return 0.7
		"koakuma_boss":
			return 0.68
		"patchouli_boss":
			return 0.82
		"sakuya_boss":
			return 0.9
		"remilia_boss":
			return 0.84
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
		"meiling_boss":
			pools = [
				["conehead", "buckethead", "kungfu"],
				["football", "screen_door", "ninja", "buckethead"],
				["dark_football", "basketball", "football", "nezha"],
			]
			tint = Color(0.36, 0.88, 0.52, 0.22)
		"koakuma_boss":
			pools = [
				["conehead", "newspaper", "screen_door", "snorkel"],
				["football", "dancing", "lifebuoy_cone", "basketball", "ninja"],
				["dragon_boat", "dark_football", "qinghua", "shouyue", "ice_block"],
			]
			tint = Color(0.98, 0.2, 0.3, 0.22)
		"patchouli_boss":
			pools = [
				["conehead", "screen_door", "football", "newspaper", "snorkel"],
				["dancing", "basketball", "ninja", "qinghua", "lifebuoy_bucket", "dragon_boat"],
				["dark_football", "dragon_dance", "shouyue", "ice_block", "football", "screen_door"],
			]
			tint = Color(0.76, 0.58, 1.0, 0.24)
		"sakuya_boss":
			pools = [
				["screen_door", "football", "ninja", "newspaper", "conehead"],
				["dark_football", "basketball", "dragon_boat", "qinghua", "shouyue"],
				["dark_football", "dragon_dance", "ice_block", "basketball", "football", "snorkel"],
			]
			tint = Color(0.84, 0.9, 1.0, 0.26)
		"remilia_boss":
			pools = [
				["screen_door", "football", "ninja", "buckethead", "newspaper"],
				["dark_football", "basketball", "dragon_boat", "qinghua", "shouyue", "ice_block"],
				["dark_football", "dragon_dance", "basketball", "football", "ninja", "screen_door", "snorkel"],
			]
			tint = Color(0.96, 0.24, 0.3, 0.28)
		"pool_boss":
			pools = [
				["lifebuoy_normal", "qinghua", "ice_block"],
				["dragon_boat", "lifebuoy_cone", "shouyue", "qinghua"],
				["dragon_boat", "dragon_dance", "lifebuoy_bucket", "shouyue", "ice_block"],
			]
			tint = Color(0.54, 0.84, 1.0, 0.24)
		"fog_boss":
			pools = [
				["balloon_zombie", "digger_zombie", "snorkel"],
				["pogo_zombie", "squash_zombie", "screen_door", "tornado_zombie"],
				["excavator_zombie", "barrel_screen_zombie", "wolf_knight_zombie", "jack_in_the_box_zombie"],
			]
			tint = Color(0.72, 0.94, 0.86, 0.24)
		"roof_boss":
			pools = [
				["bungee_zombie", "kite_zombie", "ladder_zombie"],
				["catapult_zombie", "hive_zombie", "kite_zombie", "ladder_zombie"],
				["turret_zombie", "programmer_zombie", "catapult_zombie", "hive_zombie"],
			]
			tint = Color(1.0, 0.72, 0.34, 0.24)
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
		"fog_boss":
			default_interval = maxf(2.9, 4.6 - float(phase) * 0.42)
		"roof_boss":
			default_interval = maxf(2.7, 4.5 - float(phase) * 0.44)
		"koakuma_boss":
			default_interval = maxf(3.1, 4.7 - float(phase) * 0.36)
		"patchouli_boss":
			default_interval = maxf(2.8, 4.4 - float(phase) * 0.38)
		"sakuya_boss":
			default_interval = maxf(2.6, 4.1 - float(phase) * 0.34)
		"remilia_boss":
			default_interval = maxf(2.4, 3.9 - float(phase) * 0.32)
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
		if float(plant.get("holy_invincible_timer", 0.0)) > 0.0:
			plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.1)
			continue
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
	if float(plant.get("holy_invincible_timer", 0.0)) > 0.0:
		plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.12)
		return true
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


func _sakuya_target_cells(row: int, count: int, base_col: int = 4) -> Array:
	var cells: Array = []
	var candidates: Array = []
	for lane in active_rows:
		var lane_row = int(lane)
		for col_offset in range(3):
			var lane_col = clampi(base_col + col_offset + (lane_row + col_offset) % 2, 2, COLS - 1)
			candidates.append(Vector2i(lane_row, lane_col))
	candidates.shuffle()
	for candidate_variant in candidates:
		var candidate = Vector2i(candidate_variant)
		if cells.has(candidate):
			continue
		cells.append(candidate)
		if cells.size() >= count:
			break
	if cells.is_empty():
		cells.append(Vector2i(row, clampi(base_col, 0, COLS - 1)))
	return cells


func _trigger_sakuya_boss_skill(zombie: Dictionary) -> Dictionary:
	var data = Defs.ZOMBIES["sakuya_boss"]
	var row = int(zombie.get("row", 0))
	var phase = int(zombie.get("boss_phase", 0))
	var anchor_x = _boss_anchor_x("sakuya_boss")
	var cycle = int(zombie.get("boss_skill_cycle", 0))
	match cycle:
		0:
			var start_x = BOARD_ORIGIN.x + board_size.x * 0.44
			var fan_hit := false
			for lane_variant in [row, _next_active_row(row, -1).get("row", row), _next_active_row(row, 1).get("row", row)]:
				fan_hit = _damage_plants_in_row_segment(
					int(lane_variant),
					start_x,
					anchor_x,
					float(data.get("knife_damage", 58.0)) + phase * 12.0
				) or fan_hit
			effects.append({
				"shape": "sakuya_knife_fan",
				"position": Vector2(anchor_x - 12.0, _row_center_y(row) - 10.0),
				"length": anchor_x - start_x + CELL_SIZE.x * 0.24,
				"width": CELL_SIZE.y * 2.8,
				"radius": 210.0,
				"knife_count": 8 + phase * 2,
				"time": 0.4,
				"duration": 0.4,
				"anim_speed": 8.2,
				"color": Color(0.84, 0.92, 1.0, 0.32 if fan_hit else 0.18),
			})
			_show_banner("Knife Sign \"Misdirection\"", 1.16)
			return _set_rumia_state(zombie, "knives", 0.42)
		1:
			var rain_cells = _sakuya_target_cells(row, 4 + phase, 4)
			var rain_hits = _damage_plants_in_cells(rain_cells, float(data.get("knife_rain_damage", 96.0)) + phase * 15.0, 1.0 + phase * 0.08)
			var rain_points: Array = []
			for cell_variant in rain_cells:
				var cell = Vector2i(cell_variant)
				rain_points.append(_cell_center(cell.x, cell.y) + Vector2(0.0, -10.0))
			effects.append({
				"shape": "sakuya_knife_rain",
				"position": Vector2(anchor_x - 88.0, _row_center_y(row) - 10.0),
				"points": rain_points,
				"radius": 52.0,
				"knife_height": 120.0 + phase * 12.0,
				"knife_count": 3 + phase,
				"time": 0.46,
				"duration": 0.46,
				"anim_speed": 6.8,
				"color": Color(0.88, 0.94, 1.0, 0.28 if rain_hits > 0 else 0.15),
			})
			_show_banner("Illusion Sign \"Killing Doll\"", 1.16)
			return _set_rumia_state(zombie, "rain", 0.48)
		2:
			var doll_center = Vector2(anchor_x - 92.0, _row_center_y(row) - 10.0)
			var doll_radius = 176.0 + phase * 18.0
			var doll_hit = _damage_plants_in_circle(doll_center, doll_radius, float(data.get("doll_damage", 72.0)) + phase * 14.0)
			_stagger_plants_in_circle(doll_center, doll_radius, 0.75 + phase * 0.12)
			effects.append({
				"shape": "storm_arc",
				"position": doll_center + Vector2(0.0, -18.0),
				"target": doll_center + Vector2(-86.0, 28.0),
				"radius": doll_radius,
				"time": 0.48,
				"duration": 0.48,
				"color": Color(0.78, 0.88, 1.0, 0.34 if doll_hit else 0.18),
			})
			_show_banner("Close-up Magic", 1.0)
			return _set_rumia_state(zombie, "doll", 0.5)
		3:
			var target_row = _choose_rumia_hover_row(row)
			if target_row != row:
				var move_duration = _hover_boss_move_duration("sakuya_boss")
				zombie["rumia_move_from_y"] = _row_center_y(row)
				zombie["rumia_move_to_y"] = _row_center_y(target_row)
				zombie["rumia_move_duration"] = move_duration
				zombie["rumia_move_timer"] = move_duration
				zombie["row"] = target_row
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), move_duration * 0.84)
				effects.append({
					"shape": "sakuya_time_grid",
					"position": Vector2(anchor_x, _row_center_y(target_row) - 10.0),
					"radius": 86.0,
					"width": CELL_SIZE.y * 1.2,
					"time": 0.34,
					"duration": 0.34,
					"anim_speed": 7.8,
					"color": Color(0.84, 0.9, 1.0, 0.28),
				})
			_show_banner("Time Sign \"Teleport\"", 0.95)
			return _set_rumia_state(zombie, "shift", 0.56)
		4:
			var time_stop_duration = float(data.get("time_stop_duration", 2.3)) + phase * 0.25
			boss_time_stop_timer = maxf(boss_time_stop_timer, time_stop_duration)
			boss_time_stop_flash_timer = maxf(boss_time_stop_flash_timer, 0.5)
			zombie["sakuya_relocate_timer"] = 0.26
			zombie["sakuya_relocate_interval"] = maxf(0.24, minf(0.42, time_stop_duration * 0.26))
			zombie["sakuya_relocations_remaining"] = 1 + phase
			for _i in range(1 + phase):
				_spawn_hover_boss_reinforcement("sakuya_boss", phase)
			effects.append({
				"shape": "sakuya_time_grid",
				"position": Vector2(anchor_x - 92.0, _row_center_y(int(zombie.get("row", row))) - 12.0),
				"radius": 234.0 + phase * 20.0,
				"width": board_size.y * 0.44,
				"time": 0.62,
				"duration": 0.62,
				"anim_speed": 7.6,
				"color": Color(0.86, 0.92, 1.0, 0.34),
			})
			_show_banner("Luna Dial", 1.18)
			return _set_rumia_state(zombie, "time", 0.66)
		5:
			var clock_cells = _sakuya_target_cells(row, 5, 3)
			var clock_hits = _damage_plants_in_cells(clock_cells, float(data.get("clock_damage", 108.0)) + phase * 18.0, 1.3 + phase * 0.1)
			var clock_points: Array = []
			for cell_variant in clock_cells:
				var cell = Vector2i(cell_variant)
				clock_points.append(_cell_center(cell.x, cell.y) + Vector2(0.0, -10.0))
			effects.append({
				"shape": "sakuya_time_grid",
				"position": Vector2(anchor_x - 96.0, _row_center_y(row) - 12.0),
				"points": clock_points,
				"radius": 42.0,
				"width": 30.0,
				"time": 0.5,
				"duration": 0.5,
				"anim_speed": 8.6,
				"color": Color(0.8, 0.9, 1.0, 0.28 if clock_hits > 0 else 0.14),
			})
			_show_banner("Clock Sign \"Private Square\"", 1.16)
			return _set_rumia_state(zombie, "clock", 0.54)
		6:
			var column_targets: Array = []
			var candidate_columns: Array = []
			for col in range(2, COLS):
				candidate_columns.append(col)
			candidate_columns.shuffle()
			var chosen_column_count = min(2 + phase, candidate_columns.size())
			for col_index in range(chosen_column_count):
				var target_col = int(candidate_columns[col_index])
				for lane in active_rows:
					column_targets.append(Vector2i(int(lane), target_col))
			var column_hits = _damage_plants_in_cells(column_targets, float(data.get("clock_damage", 108.0)) * 0.66 + phase * 12.0, 0.92 + phase * 0.08)
			var column_points: Array = []
			for cell_variant in column_targets:
				var cell = Vector2i(cell_variant)
				column_points.append(_cell_center(cell.x, cell.y) + Vector2(0.0, -10.0))
			effects.append({
				"shape": "sakuya_time_grid",
				"position": Vector2(anchor_x - 96.0, _row_center_y(row) - 12.0),
				"points": column_points,
				"radius": 34.0,
				"width": 26.0,
				"time": 0.4,
				"duration": 0.4,
				"anim_speed": 9.0,
				"color": Color(0.82, 0.92, 1.0, 0.28 if column_hits > 0 else 0.14),
			})
			_show_banner("Maid Secret \"Changeling Magic\"", 1.12)
			return _set_rumia_state(zombie, "clock", 0.52)
		7:
			var hop_rows: Array = active_rows.duplicate()
			hop_rows.shuffle()
			var hop_count = min(2 + phase, hop_rows.size())
			var hop_hit := false
			var final_row = row
			for hop_index in range(hop_count):
				var target_row = int(hop_rows[hop_index])
				final_row = target_row
				var slash_start = BOARD_ORIGIN.x + board_size.x * (0.34 + float(hop_index) * 0.06)
				hop_hit = _damage_plants_in_row_segment(
					target_row,
					slash_start,
					anchor_x,
					float(data.get("knife_damage", 58.0)) * (0.92 + float(phase) * 0.12)
				) or hop_hit
				effects.append({
					"shape": "sakuya_knife_fan",
					"position": Vector2(anchor_x - 16.0, _row_center_y(target_row) - 10.0),
					"length": anchor_x - slash_start + CELL_SIZE.x * 0.16,
					"width": CELL_SIZE.y * 1.18,
					"knife_count": 4 + phase,
					"radius": 62.0,
					"time": 0.28,
					"duration": 0.28,
					"anim_speed": 9.0,
					"color": Color(0.84, 0.92, 1.0, 0.28 if hop_hit else 0.16),
				})
			if final_row != row:
				var blink_duration = _hover_boss_move_duration("sakuya_boss") * 0.88
				zombie["rumia_move_from_y"] = _row_center_y(row)
				zombie["rumia_move_to_y"] = _row_center_y(final_row)
				zombie["rumia_move_duration"] = blink_duration
				zombie["rumia_move_timer"] = blink_duration
				zombie["row"] = final_row
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), blink_duration * 0.84)
			boss_time_stop_flash_timer = maxf(boss_time_stop_flash_timer, 0.22)
			_show_banner("Illusion Sign \"Eternal Meek\"", 1.08)
			return _set_rumia_state(zombie, "shift", 0.58)
		8:
			var world_time_stop_duration = float(data.get("time_stop_duration", 2.3)) * 0.8 + phase * 0.18
			boss_time_stop_timer = maxf(boss_time_stop_timer, world_time_stop_duration)
			boss_time_stop_flash_timer = maxf(boss_time_stop_flash_timer, 0.48)
			zombie["sakuya_relocate_timer"] = 0.18
			zombie["sakuya_relocate_interval"] = maxf(0.2, minf(0.38, world_time_stop_duration * 0.24))
			zombie["sakuya_relocations_remaining"] = 2 + phase
			var world_cells = _sakuya_target_cells(row, 6 + phase, 2)
			var world_hits = _damage_plants_in_cells(world_cells, float(data.get("knife_rain_damage", 96.0)) * 0.72 + phase * 16.0, 1.18 + phase * 0.08)
			var world_points: Array = []
			for _i in range(1 + phase):
				_spawn_hover_boss_reinforcement("sakuya_boss", phase)
			for cell_variant in world_cells:
				var cell = Vector2i(cell_variant)
				world_points.append(_cell_center(cell.x, cell.y) + Vector2(0.0, -10.0))
			effects.append({
				"shape": "sakuya_time_grid",
				"position": Vector2(anchor_x - 92.0, _row_center_y(int(zombie.get("row", row))) - 12.0),
				"radius": 212.0 + phase * 18.0,
				"width": board_size.y * 0.4,
				"time": 0.44,
				"duration": 0.44,
				"anim_speed": 8.4,
				"color": Color(0.86, 0.94, 1.0, 0.3 if world_hits > 0 else 0.16),
			})
			effects.append({
				"shape": "sakuya_knife_rain",
				"position": Vector2(anchor_x - 84.0, _row_center_y(int(zombie.get("row", row))) - 10.0),
				"points": world_points,
				"radius": 54.0,
				"knife_height": 132.0 + phase * 12.0,
				"knife_count": 3 + phase,
				"time": 0.44,
				"duration": 0.44,
				"anim_speed": 8.4,
				"color": Color(0.86, 0.94, 1.0, 0.3 if world_hits > 0 else 0.16),
			})
			_show_banner("Time Sign \"Sakuya's World\"", 1.22)
			return _set_rumia_state(zombie, "time", 0.72)
		_:
			for _i in range(2 + phase):
				_spawn_hover_boss_reinforcement("sakuya_boss", phase)
			var summon_start = BOARD_ORIGIN.x + board_size.x * 0.36
			var summon_hit := false
			for lane in active_rows:
				summon_hit = _damage_plants_in_row_segment(
					int(lane),
					summon_start,
					anchor_x,
					float(data.get("slash_grid_damage", 42.0)) * (2.4 + phase * 0.24)
				) or summon_hit
			effects.append({
				"shape": "library_books",
				"position": Vector2(summon_start, BOARD_ORIGIN.y + board_size.y * 0.5 - 10.0),
				"length": anchor_x - summon_start,
				"width": board_size.y * 0.86,
				"radius": 240.0,
				"time": 0.56,
				"duration": 0.56,
				"anim_speed": 7.2,
				"color": Color(0.82, 0.9, 1.0, 0.32 if summon_hit else 0.18),
			})
			_show_banner("Maid Secret \"Perfect Maid\"", 1.18)
			return _set_rumia_state(zombie, "summon", 0.58)


func _remilia_target_cells(row: int, count: int, base_col: int = 3) -> Array:
	var cells: Array = []
	var occupied: Array = []
	var fallback: Array = []
	for lane_variant in active_rows:
		var lane_row = int(lane_variant)
		for col in range(max(1, base_col), COLS):
			var cell = Vector2i(lane_row, col)
			fallback.append(cell)
			if _targetable_plant_at(lane_row, col) != null:
				occupied.append(cell)
	occupied.shuffle()
	fallback.shuffle()
	for candidate_variant in occupied:
		var candidate = Vector2i(candidate_variant)
		if cells.has(candidate):
			continue
		cells.append(candidate)
		if cells.size() >= count:
			return cells
	for candidate_variant in fallback:
		var candidate = Vector2i(candidate_variant)
		if cells.has(candidate):
			continue
		cells.append(candidate)
		if cells.size() >= count:
			break
	if cells.is_empty():
		cells.append(Vector2i(row, clampi(base_col, 0, COLS - 1)))
	return cells


func _remilia_primary_target_cell(row: int) -> Vector2i:
	var best = Vector2i(-1, -1)
	var best_score := -999999.0
	for lane_variant in active_rows:
		var lane_row = int(lane_variant)
		for col in range(COLS):
			var plant_variant = _targetable_plant_at(lane_row, col)
			if plant_variant == null:
				continue
			var score = float(col) * 18.0 - absf(float(lane_row - row)) * 5.0 + float(plant_variant.get("health", 0.0)) * 0.02
			if score <= best_score:
				continue
			best_score = score
			best = Vector2i(lane_row, col)
	if best.y == -1:
		return Vector2i(row, clampi(COLS - 2, 0, COLS - 1))
	return best


func _heal_hover_boss(zombie: Dictionary, amount: float) -> Dictionary:
	zombie["health"] = minf(float(zombie.get("max_health", 0.0)), float(zombie.get("health", 0.0)) + amount)
	zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.08)
	return zombie


func _trigger_remilia_boss_skill(zombie: Dictionary) -> Dictionary:
	var data = Defs.ZOMBIES["remilia_boss"]
	var row = int(zombie.get("row", 0))
	var phase = int(zombie.get("boss_phase", 0))
	var anchor_x = _boss_anchor_x("remilia_boss")
	var cycle = int(zombie.get("boss_skill_cycle", 0))
	match cycle:
		0:
			var start_x = BOARD_ORIGIN.x + board_size.x * 0.34
			var lane_hit := false
			for lane_variant in [row, _next_active_row(row, -1).get("row", row), _next_active_row(row, 1).get("row", row)]:
				lane_hit = _damage_plants_in_row_segment(int(lane_variant), start_x, anchor_x, float(data.get("scarlet_shot_damage", 62.0)) + phase * 12.0) or lane_hit
			effects.append({
				"shape": "remilia_scarlet_wave",
				"position": Vector2(start_x, _row_center_y(row) - 12.0),
				"length": anchor_x - start_x,
				"width": CELL_SIZE.y * 2.26,
				"radius": 220.0,
				"spike_count": 9 + phase * 2,
				"time": 0.42,
				"duration": 0.42,
				"anim_speed": 8.0,
				"color": Color(0.96, 0.18, 0.24, 0.34 if lane_hit else 0.18),
			})
			_show_banner("Scarlet Shoot", 1.14)
			return _set_rumia_state(zombie, "scarlet", 0.46)
		1:
			var magic_cells = _remilia_target_cells(row, 4 + phase, 3)
			var magic_hits = _damage_plants_in_cells(magic_cells, float(data.get("red_magic_damage", 86.0)) + phase * 15.0, 1.05 + phase * 0.08)
			var magic_points: Array = []
			for cell_variant in magic_cells:
				var cell = Vector2i(cell_variant)
				magic_points.append(_cell_center(cell.x, cell.y) + Vector2(0.0, -10.0))
			effects.append({
				"shape": "remilia_blood_sigil",
				"position": Vector2(anchor_x - 88.0, _row_center_y(row) - 10.0),
				"points": magic_points,
				"radius": 52.0,
				"time": 0.46,
				"duration": 0.46,
				"anim_speed": 6.9,
				"color": Color(0.98, 0.22, 0.32, 0.28 if magic_hits > 0 else 0.16),
			})
			_show_banner("Red Magic", 1.12)
			return _set_rumia_state(zombie, "magic", 0.5)
		2:
			var world_hit := false
			for lane_variant in active_rows:
				world_hit = _damage_plants_in_row_segment(int(lane_variant), BOARD_ORIGIN.x + board_size.x * 0.18, anchor_x, float(data.get("gensokyo_damage", 48.0)) + phase * 10.0) or world_hit
			effects.append({
				"shape": "remilia_crimson_field",
				"position": Vector2(BOARD_ORIGIN.x + board_size.x * 0.54, BOARD_ORIGIN.y + board_size.y * 0.5 - 10.0),
				"length": board_size.x * 0.88,
				"width": board_size.y * 0.9,
				"radius": board_size.x * 0.5,
				"time": 0.54,
				"duration": 0.54,
				"anim_speed": 7.2,
				"color": Color(0.92, 0.14, 0.24, 0.28 if world_hit else 0.16),
			})
			_show_banner("Scarlet Gensokyo", 1.16)
			return _set_rumia_state(zombie, "scarlet", 0.56)
		3:
			var heart_target = _remilia_primary_target_cell(row)
			var heart_center = _cell_center(heart_target.x, heart_target.y) + Vector2(0.0, -10.0)
			var heart_hit = _damage_plants_in_circle(heart_center, CELL_SIZE.x * 0.82, float(data.get("heart_break_damage", 132.0)) + phase * 20.0)
			_stagger_plants_in_circle(heart_center, CELL_SIZE.x * 0.94, 1.0 + phase * 0.08)
			if heart_target.x != row:
				var move_duration = _hover_boss_move_duration("remilia_boss") * 0.9
				zombie["rumia_move_from_y"] = _row_center_y(row)
				zombie["rumia_move_to_y"] = _row_center_y(heart_target.x)
				zombie["rumia_move_duration"] = move_duration
				zombie["rumia_move_timer"] = move_duration
				zombie["row"] = heart_target.x
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), move_duration * 0.82)
			effects.append({
				"shape": "remilia_heart_break",
				"position": Vector2(anchor_x - 80.0, _row_center_y(int(zombie.get("row", heart_target.x))) - 20.0),
				"target": heart_center,
				"radius": 168.0,
				"time": 0.42,
				"duration": 0.42,
				"color": Color(0.96, 0.2, 0.3, 0.34 if heart_hit else 0.18),
			})
			_show_banner("Heart Break", 1.08)
			return _set_rumia_state(zombie, "heart", 0.58)
		4:
			var gungnir_target = _remilia_primary_target_cell(int(zombie.get("row", row)))
			var gungnir_cells: Array = [gungnir_target]
			for lane_variant in [_next_active_row(gungnir_target.x, -1).get("row", gungnir_target.x), _next_active_row(gungnir_target.x, 1).get("row", gungnir_target.x)]:
				var nearby_cell = Vector2i(int(lane_variant), gungnir_target.y)
				if gungnir_cells.has(nearby_cell):
					continue
				gungnir_cells.append(nearby_cell)
			var gungnir_hits = _damage_plants_in_cells(gungnir_cells, float(data.get("gungnir_damage", 168.0)) + phase * 20.0, 1.18 + phase * 0.1)
			for cell_variant in gungnir_cells:
				var cell = Vector2i(cell_variant)
				effects.append({
					"shape": "remilia_gungnir_lance",
					"position": Vector2(anchor_x - 64.0, _row_center_y(int(zombie.get("row", row))) - 16.0),
					"target": _cell_center(cell.x, cell.y) + Vector2(0.0, -10.0),
					"radius": 132.0,
					"time": 0.3,
					"duration": 0.3,
					"color": Color(1.0, 0.34, 0.22, 0.34 if gungnir_hits > 0 else 0.16),
				})
			_show_banner("Spear the Gungnir", 1.14)
			return _set_rumia_state(zombie, "gungnir", 0.62)
		5:
			var dive_rows: Array = active_rows.duplicate()
			dive_rows.shuffle()
			var dive_count = min(2 + phase, dive_rows.size())
			var dive_hit := false
			var final_row = row
			for dive_index in range(dive_count):
				var target_row = int(dive_rows[dive_index])
				final_row = target_row
				var slash_start = BOARD_ORIGIN.x + board_size.x * (0.24 + float(dive_index) * 0.08)
				dive_hit = _damage_plants_in_row_segment(target_row, slash_start, anchor_x, float(data.get("cradle_damage", 94.0)) + phase * 13.0) or dive_hit
				effects.append({
					"shape": "remilia_scarlet_wave",
					"position": Vector2(slash_start, _row_center_y(target_row) - 10.0),
					"length": anchor_x - slash_start,
					"width": CELL_SIZE.y * 1.18,
					"spike_count": 6 + phase,
					"radius": 66.0,
					"time": 0.26,
					"duration": 0.26,
					"anim_speed": 8.8,
					"color": Color(0.96, 0.2, 0.24, 0.28 if dive_hit else 0.16),
				})
			if final_row != row:
				var blink_duration = _hover_boss_move_duration("remilia_boss") * 0.82
				zombie["rumia_move_from_y"] = _row_center_y(row)
				zombie["rumia_move_to_y"] = _row_center_y(final_row)
				zombie["rumia_move_duration"] = blink_duration
				zombie["rumia_move_timer"] = blink_duration
				zombie["row"] = final_row
				zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), blink_duration * 0.82)
			_show_banner("Demon King Cradle", 1.08)
			return _set_rumia_state(zombie, "cradle", 0.56)
		6:
			var column_targets: Array = []
			var candidate_columns: Array = []
			for col in range(2, COLS):
				candidate_columns.append(col)
			candidate_columns.shuffle()
			var chosen_column_count = min(2 + phase, candidate_columns.size())
			for col_index in range(chosen_column_count):
				var target_col = int(candidate_columns[col_index])
				for lane_variant in active_rows:
					column_targets.append(Vector2i(int(lane_variant), target_col))
			var column_hits = _damage_plants_in_cells(column_targets, float(data.get("cradle_damage", 94.0)) * 0.78 + phase * 12.0, 0.92 + phase * 0.06)
			var column_points: Array = []
			for _i in range(1 + phase):
				_spawn_hover_boss_reinforcement("remilia_boss", phase)
			for cell_variant in column_targets:
				var cell = Vector2i(cell_variant)
				column_points.append(_cell_center(cell.x, cell.y) + Vector2(0.0, -10.0))
			effects.append({
				"shape": "remilia_bat_swarm",
				"position": Vector2(anchor_x - 84.0, _row_center_y(row) - 10.0),
				"points": column_points,
				"radius": 38.0,
				"time": 0.42,
				"duration": 0.42,
				"anim_speed": 8.4,
				"color": Color(0.88, 0.18, 0.26, 0.28 if column_hits > 0 else 0.14),
			})
			_show_banner("Dracula Cradle", 1.12)
			return _set_rumia_state(zombie, "drain", 0.58)
		7:
			var drained := 0
			for lane_variant in active_rows:
				var lane_row = int(lane_variant)
				for col in range(COLS):
					if _damage_plant_cell(lane_row, col, float(data.get("drain_dps", 11.0)) * (5.2 + float(phase) * 0.42), 0.5):
						drained += 1
			zombie = _heal_hover_boss(zombie, 180.0 + float(drained) * 24.0 + float(phase) * 60.0)
			effects.append({
				"shape": "remilia_blood_sigil",
				"position": Vector2(anchor_x - 92.0, _row_center_y(int(zombie.get("row", row))) - 12.0),
				"radius": 220.0,
				"time": 0.48,
				"duration": 0.48,
				"anim_speed": 6.8,
				"color": Color(0.92, 0.16, 0.24, 0.32 if drained > 0 else 0.16),
			})
			_show_banner("Vampirish Night", 1.18)
			return _set_rumia_state(zombie, "drain", 0.6)
		8:
			for _i in range(2 + phase):
				_spawn_hover_boss_reinforcement("remilia_boss", phase)
			var bat_cells = _remilia_target_cells(row, 5 + phase, 2)
			var bat_hits = _damage_plants_in_cells(bat_cells, float(data.get("bat_damage", 44.0)) + phase * 11.0, 0.82 + phase * 0.06)
			var bat_points: Array = []
			for cell_variant in bat_cells:
				var cell = Vector2i(cell_variant)
				bat_points.append(_cell_center(cell.x, cell.y) + Vector2(0.0, -12.0))
			effects.append({
				"shape": "remilia_bat_swarm",
				"position": Vector2(anchor_x - 92.0, _row_center_y(row) - 10.0),
				"points": bat_points,
				"radius": 54.0,
				"time": 0.22,
				"duration": 0.22,
				"anim_speed": 8.8,
				"color": Color(0.94, 0.08, 0.16, 0.22 if bat_hits > 0 else 0.12),
			})
			_show_banner("Scarlet Devil", 1.16)
			return _set_rumia_state(zombie, "bats", 0.58)
		_:
			var meister_cells = _remilia_target_cells(row, 6 + phase, 2)
			var meister_points: Array = []
			for cell_variant in meister_cells:
				var meister_cell = Vector2i(cell_variant)
				meister_points.append(_cell_center(meister_cell.x, meister_cell.y) + Vector2(0.0, -10.0))
			var meister_hits = _damage_plants_in_cells(meister_cells, float(data.get("red_magic_damage", 86.0)) * 0.82 + phase * 17.0, 1.24 + phase * 0.08)
			var cross_rows: Array = active_rows.duplicate()
			cross_rows.shuffle()
			for lane_index in range(min(3, cross_rows.size())):
				var lane_row = int(cross_rows[lane_index])
				_damage_plants_in_row_segment(lane_row, BOARD_ORIGIN.x + board_size.x * 0.22, anchor_x, float(data.get("scarlet_shot_damage", 62.0)) * 0.82 + phase * 8.0)
			zombie = _heal_hover_boss(zombie, 90.0 + float(meister_hits) * 16.0)
			effects.append({
				"shape": "remilia_meister_barrage",
				"position": Vector2(BOARD_ORIGIN.x + board_size.x * 0.22, BOARD_ORIGIN.y + board_size.y * 0.5 - 10.0),
				"length": anchor_x - (BOARD_ORIGIN.x + board_size.x * 0.22),
				"width": board_size.y * 0.92,
				"radius": board_size.x,
				"points": meister_points,
				"time": 0.58,
				"duration": 0.58,
				"anim_speed": 7.6,
				"color": Color(1.0, 0.18, 0.24, 0.34 if meister_hits > 0 else 0.18),
			})
			effects.append({
				"shape": "remilia_blood_sigil",
				"position": Vector2(anchor_x - 88.0, _row_center_y(row) - 10.0),
				"points": meister_points,
				"radius": 48.0,
				"time": 0.58,
				"duration": 0.58,
				"anim_speed": 7.2,
				"color": Color(0.98, 0.22, 0.28, 0.24 if meister_hits > 0 else 0.12),
			})
			_show_banner("Scarlet Meister", 1.2)
			return _set_rumia_state(zombie, "meister", 0.72)


func _trigger_boss_skill(zombie: Dictionary) -> Dictionary:
	if String(zombie["kind"]) == "rumia_boss":
		return _trigger_rumia_boss_skill(zombie)
	if String(zombie["kind"]) == "daiyousei_boss":
		return _trigger_daiyousei_boss_skill(zombie)
	if String(zombie["kind"]) == "cirno_boss":
		return _trigger_cirno_boss_skill(zombie)
	if String(zombie["kind"]) == "meiling_boss":
		return _trigger_meiling_boss_skill(zombie)
	if String(zombie["kind"]) == "koakuma_boss":
		return _trigger_koakuma_boss_skill(zombie)
	if String(zombie["kind"]) == "patchouli_boss":
		return _trigger_patchouli_boss_skill(zombie)
	if String(zombie["kind"]) == "sakuya_boss":
		return _trigger_sakuya_boss_skill(zombie)
	if String(zombie["kind"]) == "remilia_boss":
		return _trigger_remilia_boss_skill(zombie)
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
	if String(zombie["kind"]) == "fog_boss":
		var phase = int(zombie.get("boss_phase", 0))
		var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		effects.append({
			"position": center,
			"radius": 152.0 + phase * 14.0,
			"time": 0.44,
			"duration": 0.44,
			"color": Color(0.72, 0.96, 0.88, 0.34),
		})
		match int(zombie.get("boss_skill_cycle", 0)):
			0:
				effects.append({
					"shape": "mist_cloud",
					"position": center + Vector2(-32.0, -18.0),
					"radius": 92.0 + phase * 10.0,
					"time": 0.7,
					"duration": 0.7,
					"anim_speed": 5.4,
					"color": Color(0.74, 0.98, 0.92, 0.24),
				})
				effects.append({
					"shape": "mist_cloud",
					"position": center + Vector2(36.0, 26.0),
					"radius": 84.0 + phase * 10.0,
					"time": 0.66,
					"duration": 0.66,
					"anim_speed": 5.0,
					"color": Color(0.58, 0.92, 0.82, 0.2),
				})
				var summon_pool = ["balloon_zombie", "digger_zombie", "pogo_zombie", "jack_in_the_box_zombie", "squash_zombie", "excavator_zombie", "barrel_screen_zombie", "tornado_zombie", "wolf_knight_zombie", "screen_door", "football"]
				for summon_index in range(3 + phase):
					var summon_kind = String(summon_pool[rng.randi_range(0, summon_pool.size() - 1)])
					_spawn_zombie(summon_kind, _choose_spawn_row_for_kind(summon_kind), true)
				_show_banner("雾岚尸王卷来了新的混编尸群！", 1.5)
			1:
				for lane in active_rows:
					_damage_front_plant_in_row(int(lane), 150.0 + phase * 28.0)
					var bog_col = clampi(rng.randi_range(3, COLS - 2), 0, COLS - 1)
					var bog_center = _cell_center(int(lane), bog_col)
					_spawn_bog_pool(bog_center, 56.0 + phase * 10.0, 7.6 + phase * 1.5)
					effects.append({
						"shape": "mist_cloud",
						"position": bog_center + Vector2(rng.randf_range(-18.0, 18.0), -18.0),
						"radius": 46.0 + phase * 8.0,
						"time": 0.52,
						"duration": 0.52,
						"anim_speed": 4.8,
						"color": Color(0.74, 0.98, 0.88, 0.16),
					})
					if int(lane) % 2 == 0:
						effects.append({
							"shape": "lane_spray",
							"position": Vector2(BOARD_ORIGIN.x + CELL_SIZE.x * 2.0, _row_center_y(int(lane)) - 8.0),
							"length": board_size.x - CELL_SIZE.x * 1.5,
							"width": CELL_SIZE.y * 0.5,
							"radius": board_size.x,
							"time": 0.28,
							"duration": 0.28,
							"color": Color(0.62, 0.9, 0.78, 0.18),
						})
				_show_banner("雾岚尸王把前线拖进盐沼！", 1.45)
			_:
				effects.append({
					"shape": "mist_cloud",
					"position": center + Vector2(-64.0, -26.0),
					"radius": 110.0 + phase * 14.0,
					"time": 0.7,
					"duration": 0.7,
					"anim_speed": 5.6,
					"color": Color(0.82, 1.0, 0.94, 0.22),
				})
				effects.append({
					"shape": "mist_cloud",
					"position": center + Vector2(28.0, 30.0),
					"radius": 98.0 + phase * 12.0,
					"time": 0.68,
					"duration": 0.68,
					"anim_speed": 5.2,
					"color": Color(0.64, 0.94, 0.84, 0.18),
				})
				for lane in active_rows:
					if int(lane) == int(zombie["row"]) or rng.randf() < 0.55:
						effects.append({
							"shape": "lane_spray",
							"position": Vector2(BOARD_ORIGIN.x + CELL_SIZE.x * 1.4, _row_center_y(int(lane)) - 10.0),
							"length": board_size.x - CELL_SIZE.x * 0.8,
							"width": CELL_SIZE.y * 0.56,
							"radius": board_size.x,
							"time": 0.3,
							"duration": 0.3,
							"color": Color(0.76, 0.98, 0.9, 0.18),
						})
				for _i in range(2 + phase):
					var strike_kind = "tornado_zombie" if rng.randf() < 0.5 else "wolf_knight_zombie"
					_spawn_zombie(strike_kind, _choose_spawn_row_for_kind(strike_kind), true)
				for lane in active_rows:
					if rng.randf() < 0.6:
						_damage_front_plant_in_row(int(lane), 110.0 + phase * 22.0)
				_show_banner("雾岚尸王掀起了迷雾突袭！", 1.4)
		return zombie
	if String(zombie["kind"]) == "roof_boss":
		var phase = int(zombie.get("boss_phase", 0))
		var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 8.0)
		effects.append({
			"position": center,
			"radius": 158.0 + phase * 14.0,
			"time": 0.44,
			"duration": 0.44,
			"color": Color(1.0, 0.68, 0.24, 0.34),
		})
		match int(zombie.get("boss_skill_cycle", 0)):
			0:
				effects.append({
					"shape": "lane_spray",
					"position": Vector2(BOARD_ORIGIN.x + CELL_SIZE.x * 1.8, center.y),
					"length": board_size.x - CELL_SIZE.x * 0.9,
					"width": CELL_SIZE.y * 0.62,
					"radius": board_size.x,
					"time": 0.28,
					"duration": 0.28,
					"color": Color(1.0, 0.76, 0.34, 0.18),
				})
				var summon_pool = ["bungee_zombie", "ladder_zombie", "catapult_zombie", "kite_zombie", "hive_zombie", "turret_zombie", "programmer_zombie"]
				for summon_index in range(3 + phase):
					var summon_kind = String(summon_pool[rng.randi_range(0, summon_pool.size() - 1)])
					_spawn_zombie(summon_kind, _choose_spawn_row_for_kind(summon_kind), true)
				_show_banner("穹顶尸王放下了屋顶混编空投！", 1.5)
			1:
				for lane in active_rows:
					var lane_row = int(lane)
					_damage_front_plant_in_row(lane_row, 156.0 + phase * 28.0)
					effects.append({
						"shape": "lane_spray",
						"position": Vector2(BOARD_ORIGIN.x + CELL_SIZE.x * 1.5, _row_center_y(lane_row) - 8.0),
						"length": board_size.x - CELL_SIZE.x * 0.6,
						"width": CELL_SIZE.y * 0.54,
						"radius": board_size.x,
						"time": 0.26,
						"duration": 0.26,
						"color": Color(0.98, 0.62, 0.22, 0.16),
					})
					effects.append({
						"position": Vector2(BOARD_ORIGIN.x + board_size.x * 0.62, _row_center_y(lane_row) - 12.0),
						"radius": 56.0 + phase * 6.0,
						"time": 0.3,
						"duration": 0.3,
						"color": Color(0.82, 0.22, 0.08, 0.2),
					})
				_show_banner("穹顶尸王掀落了整片瓦顶轰炸！", 1.4)
			_:
				for lane in active_rows:
					if rng.randf() < 0.7 or int(lane) == int(zombie["row"]):
						_damage_front_plant_in_row(int(lane), 96.0 + phase * 18.0)
				for _i in range(2 + phase):
					var strike_kind = "turret_zombie" if rng.randf() < 0.4 else ("bungee_zombie" if rng.randf() < 0.55 else "ladder_zombie")
					_spawn_zombie(strike_kind, _choose_spawn_row_for_kind(strike_kind), true)
				effects.append({
					"shape": "lane_spray",
					"position": Vector2(BOARD_ORIGIN.x + CELL_SIZE.x * 1.2, center.y),
					"length": board_size.x - CELL_SIZE.x * 0.3,
					"width": CELL_SIZE.y * 0.68,
					"radius": board_size.x,
					"time": 0.3,
					"duration": 0.3,
					"color": Color(1.0, 0.82, 0.44, 0.14),
				})
				effects.append({
					"position": center + Vector2(-46.0, 18.0),
					"radius": 92.0 + phase * 10.0,
					"time": 0.34,
					"duration": 0.34,
					"color": Color(0.72, 0.18, 0.08, 0.16),
				})
				_show_banner("穹顶尸王展开了工程封锁！", 1.45)
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


func _trigger_meiling_boss_skill(zombie: Dictionary) -> Dictionary:
	var data = Defs.ZOMBIES["meiling_boss"]
	var row = int(zombie["row"])
	var phase = int(zombie.get("boss_phase", 0))
	var anchor_x = _boss_anchor_x("meiling_boss")
	match int(zombie.get("boss_skill_cycle", 0)):
		0:
			# Spinning kick — hits current lane and adjacent lanes
			var kick_rows = [row]
			var prev_r = _next_active_row(row, -1)
			var next_r = _next_active_row(row, 1)
			kick_rows.append(int(prev_r.get("row", row)))
			kick_rows.append(int(next_r.get("row", row)))
			var kick_hit := false
			var kick_start = BOARD_ORIGIN.x + board_size.x * 0.5
			for kick_row in kick_rows:
				kick_hit = _damage_plants_in_row_segment(
					int(kick_row),
					kick_start,
					anchor_x,
					float(data.get("kick_damage", 140.0)) + phase * 22.0
				) or kick_hit
			effects.append({
				"shape": "meiling_kick",
				"position": Vector2(anchor_x - 90.0, _row_center_y(row) - 14.0),
				"radius": 164.0 + phase * 18.0,
				"time": 0.36,
				"duration": 0.36,
				"anim_speed": 6.2,
				"color": Color(0.26, 0.82, 0.44, 0.32 if kick_hit else 0.18),
			})
			_show_banner("红美玲的华光一脚！", 1.2)
			return _set_rumia_state(zombie, "kick", 0.4)
		1:
			# Rainbow chi orbs — scatter in 3 lanes with spread
			var rainbow_hit := false
			for lane in active_rows:
				var lane_row = int(lane)
				var lane_start = BOARD_ORIGIN.x + board_size.x * (0.38 + rng.randf() * 0.14)
				rainbow_hit = _damage_plants_in_row_segment(
					lane_row,
					lane_start,
					anchor_x,
					float(data.get("rainbow_damage", 55.0)) + phase * 12.0
				) or rainbow_hit
			effects.append({
				"shape": "rainbow_chi",
				"position": Vector2(anchor_x - 80.0, _row_center_y(row) - 18.0),
				"radius": 192.0 + phase * 20.0,
				"time": 0.46,
				"duration": 0.46,
				"anim_speed": 5.8,
				"color": Color(0.5, 0.98, 0.74, 0.28 if rainbow_hit else 0.16),
			})
			_show_banner("红美玲散开了彩虹气功弹！", 1.15)
			return _set_rumia_state(zombie, "rainbow", 0.5)
		_:
			# Dragon Wave — massive green energy arc across whole board
			var dragon_hit := false
			var dragon_start = BOARD_ORIGIN.x + board_size.x * 0.18
			for lane in active_rows:
				dragon_hit = _damage_plants_in_row_segment(
					int(lane),
					dragon_start,
					anchor_x,
					float(data.get("dragon_wave_damage", 90.0)) + phase * 18.0
				) or dragon_hit
			var dragon_center = Vector2(BOARD_ORIGIN.x + board_size.x * 0.52, _row_center_y(row) - 8.0)
			_stagger_plants_in_circle(dragon_center, 280.0 + phase * 22.0, 1.2 + phase * 0.15)
			effects.append({
				"shape": "dragon_wave",
				"position": dragon_center,
				"radius": 280.0 + phase * 22.0,
				"time": 0.54,
				"duration": 0.54,
				"anim_speed": 4.8,
				"color": Color(0.28, 0.88, 0.52, 0.36 if dragon_hit else 0.22),
			})
			_show_banner("红美玲释放了青龙波！", 1.25)
			return _set_rumia_state(zombie, "dragon", 0.6)


func _trigger_meiling_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	var center = Vector2(_boss_anchor_x("meiling_boss") - 100.0, _row_center_y(int(zombie["row"])) - 10.0)
	_show_banner("红美玲进入第 %d 阶段！" % (phase + 1), 2.2)
	effects.append({
		"shape": "meiling_phase",
		"position": center,
		"radius": 240.0 + phase * 26.0,
		"time": 0.58,
		"duration": 0.58,
		"anim_speed": 5.0,
		"color": Color(0.32, 0.92, 0.56, 0.38),
	})
	_damage_plants_in_circle(center, 190.0 + phase * 16.0, 50.0 + phase * 16.0)
	_stagger_plants_in_circle(center, 190.0 + phase * 16.0, 1.1 + phase * 0.14)
	for _i in range(phase + 1):
		_spawn_hover_boss_reinforcement("meiling_boss", phase)
	return _set_rumia_state(zombie, "phase", 0.72)


func _trigger_koakuma_boss_skill(zombie: Dictionary) -> Dictionary:
	var data = Defs.ZOMBIES["koakuma_boss"]
	var row = int(zombie["row"])
	var phase = int(zombie.get("boss_phase", 0))
	var anchor_x = _boss_anchor_x("koakuma_boss")
	match int(zombie.get("boss_skill_cycle", 0)):
		0:
			var cells: Array = []
			var rows = [row, _next_active_row(row, -1).get("row", row), _next_active_row(row, 1).get("row", row)]
			for cell_index in range(rows.size()):
				var target_row = clampi(int(rows[cell_index]), 0, ROWS - 1)
				var target_col = clampi(4 + cell_index + (phase % 2), 2, COLS - 1)
				cells.append(Vector2i(target_row, target_col))
			var hit_count = _damage_plants_in_cells(cells, float(data.get("book_damage", 62.0)) + phase * 14.0, 0.9 + phase * 0.12)
			effects.append({
				"shape": "library_books",
				"position": Vector2(anchor_x - 110.0, _row_center_y(row) - 16.0),
				"length": 220.0,
				"width": 132.0,
				"radius": 150.0,
				"time": 0.48,
				"duration": 0.48,
				"anim_speed": 6.4,
				"color": Color(0.96, 0.22, 0.34, 0.32 if hit_count > 0 else 0.18),
			})
			for cell_variant in cells:
				var cell = Vector2i(cell_variant)
				effects.append({
					"shape": "arcane_circle",
					"position": _cell_center(cell.x, cell.y) + Vector2(0.0, -10.0),
					"radius": 44.0,
					"time": 0.44,
					"duration": 0.44,
					"anim_speed": 5.6,
					"color": Color(0.94, 0.26, 0.34, 0.26),
				})
			_show_banner("小恶魔散开了魔导书弹幕！", 1.15)
			return _set_rumia_state(zombie, "books", 0.48)
		1:
			var familiar_hit := false
			for lane in active_rows:
				var lane_row = int(lane)
				if abs(lane_row - row) > 1:
					continue
				var lane_start = BOARD_ORIGIN.x + board_size.x * (0.46 + 0.06 * float(abs(lane_row - row)))
				familiar_hit = _damage_plants_in_row_segment(
					lane_row,
					lane_start,
					anchor_x,
					float(data.get("familiar_damage", 36.0)) * (3.2 + phase * 0.28)
				) or familiar_hit
			effects.append({
				"shape": "library_books",
				"position": Vector2(BOARD_ORIGIN.x + board_size.x * 0.48, _row_center_y(row) - 10.0),
				"length": anchor_x - (BOARD_ORIGIN.x + board_size.x * 0.48),
				"width": CELL_SIZE.y * 1.6,
				"radius": 170.0,
				"time": 0.5,
				"duration": 0.5,
				"anim_speed": 7.0,
				"color": Color(0.82, 0.2, 0.34, 0.3 if familiar_hit else 0.18),
			})
			_show_banner("小恶魔放出了馆内使魔！", 1.15)
			return _set_rumia_state(zombie, "familiar", 0.5)
		_:
			for _i in range(2 + phase):
				_spawn_hover_boss_reinforcement("koakuma_boss", phase)
			effects.append({
				"shape": "arcane_circle",
				"position": Vector2(anchor_x - 90.0, _row_center_y(row) - 10.0),
				"radius": 118.0 + phase * 14.0,
				"time": 0.5,
				"duration": 0.5,
				"anim_speed": 4.8,
				"color": Color(0.94, 0.18, 0.3, 0.32),
			})
			_show_banner("小恶魔呼来了更多馆内尸潮！", 1.2)
			return _set_rumia_state(zombie, "summon", 0.56)


func _trigger_patchouli_boss_skill(zombie: Dictionary) -> Dictionary:
	var data = Defs.ZOMBIES["patchouli_boss"]
	var row = int(zombie["row"])
	var phase = int(zombie.get("boss_phase", 0))
	var anchor_x = _boss_anchor_x("patchouli_boss")
	match int(zombie.get("boss_skill_cycle", 0)):
		0:
			var fire_rows = [row, _next_active_row(row, -1).get("row", row), _next_active_row(row, 1).get("row", row)]
			var fire_hit := false
			var fire_start = BOARD_ORIGIN.x + board_size.x * 0.38
			for fire_row_variant in fire_rows:
				fire_hit = _damage_plants_in_row_segment(
					int(fire_row_variant),
					fire_start,
					anchor_x,
					float(data.get("fire_damage", 78.0)) + phase * 18.0
				) or fire_hit
			effects.append({
				"shape": "patchouli_flare",
				"position": Vector2(fire_start, _row_center_y(row) - 10.0),
				"length": anchor_x - fire_start,
				"width": CELL_SIZE.y * 1.7,
				"radius": 230.0,
				"time": 0.54,
				"duration": 0.54,
				"anim_speed": 6.2,
				"color": Color(1.0, 0.42, 0.22, 0.34 if fire_hit else 0.18),
			})
			_show_banner("Fire Sign \"Agni Shine\"", 1.18)
			return _set_rumia_state(zombie, "fire", 0.56)
		1:
			var cells: Array = []
			for target_row in active_rows:
				if cells.size() >= 3:
					break
				var row_i = int(target_row)
				var target_col = clampi(3 + cells.size() * 2 + phase % 2, 2, COLS - 1)
				cells.append(Vector2i(row_i, target_col))
			var water_hits = _damage_plants_in_cells(cells, float(data.get("water_damage", 62.0)) + phase * 12.0, 1.2 + phase * 0.1)
			for cell_variant in cells:
				var cell = Vector2i(cell_variant)
				effects.append({
					"shape": "arcane_circle",
					"position": _cell_center(cell.x, cell.y) + Vector2(0.0, -10.0),
					"radius": 48.0,
					"time": 0.5,
					"duration": 0.5,
					"anim_speed": 5.0,
					"color": Color(0.38, 0.78, 1.0, 0.3 if water_hits > 0 else 0.16),
				})
			_show_banner("Water Sign \"Princess Undine\"", 1.18)
			return _set_rumia_state(zombie, "water", 0.52)
		2:
			var wind_hit := false
			var wind_start = BOARD_ORIGIN.x + board_size.x * 0.26
			for lane in active_rows:
				wind_hit = _damage_plants_in_row_segment(
					int(lane),
					wind_start,
					anchor_x,
					float(data.get("wind_damage", 44.0)) * (2.1 + phase * 0.16)
				) or wind_hit
			_stagger_plants_in_circle(Vector2(BOARD_ORIGIN.x + board_size.x * 0.54, BOARD_ORIGIN.y + board_size.y * 0.5), 280.0 + phase * 16.0, 1.0 + phase * 0.1)
			effects.append({
				"shape": "lane_spray",
				"position": Vector2(wind_start, _row_center_y(row) - 10.0),
				"length": anchor_x - wind_start,
				"width": board_size.y * 0.86,
				"radius": 280.0,
				"time": 0.5,
				"duration": 0.5,
				"anim_speed": 6.0,
				"color": Color(0.64, 0.96, 0.72, 0.28 if wind_hit else 0.14),
			})
			_show_banner("Wood Sign \"Sylphy Horn\"", 1.16)
			return _set_rumia_state(zombie, "wind", 0.5)
		3:
			var metal_cells: Array = []
			for lane in active_rows:
				var lane_row = int(lane)
				var target_col = clampi(4 + (lane_row % 3), 3, COLS - 1)
				metal_cells.append(Vector2i(lane_row, target_col))
			var metal_hits = _damage_plants_in_cells(metal_cells, float(data.get("metal_damage", 88.0)) + phase * 14.0, 1.35 + phase * 0.14)
			for cell_variant in metal_cells:
				var cell = Vector2i(cell_variant)
				effects.append({
					"shape": "arcane_circle",
					"position": _cell_center(cell.x, cell.y) + Vector2(0.0, -12.0),
					"radius": 52.0,
					"time": 0.52,
					"duration": 0.52,
					"anim_speed": 6.2,
					"color": Color(0.92, 0.88, 1.0, 0.28 if metal_hits > 0 else 0.14),
				})
			_show_banner("Metal Sign \"Metal Fatigue\"", 1.18)
			return _set_rumia_state(zombie, "metal", 0.54)
		_:
			var flare_hit := false
			var flare_start = BOARD_ORIGIN.x + board_size.x * 0.16
			for lane in active_rows:
				flare_hit = _damage_plants_in_row_segment(
					int(lane),
					flare_start,
					anchor_x,
					float(data.get("flare_damage", 126.0)) + phase * 20.0
				) or flare_hit
			for _i in range(1 + phase):
				_spawn_hover_boss_reinforcement("patchouli_boss", phase)
			effects.append({
				"shape": "patchouli_flare",
				"position": Vector2(flare_start, BOARD_ORIGIN.y + board_size.y * 0.5 - 12.0),
				"length": anchor_x - flare_start,
				"width": board_size.y * 0.92,
				"radius": 320.0,
				"time": 0.62,
				"duration": 0.62,
				"anim_speed": 5.6,
				"color": Color(0.96, 0.68, 0.28, 0.32 if flare_hit else 0.16),
			})
			_show_banner("Sun&Moon Sign \"Royal Flare\"", 1.22)
			return _set_rumia_state(zombie, "flare", 0.62)


func _trigger_koakuma_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	var center = Vector2(_boss_anchor_x("koakuma_boss") - 86.0, _row_center_y(int(zombie["row"])) - 10.0)
	_show_banner("小恶魔的弹幕更乱了！", 1.9)
	effects.append({
		"shape": "arcane_circle",
		"position": center,
		"radius": 144.0 + phase * 18.0,
		"time": 0.52,
		"duration": 0.52,
		"anim_speed": 5.0,
		"color": Color(0.96, 0.22, 0.32, 0.34),
	})
	for _i in range(phase + 1):
		_spawn_hover_boss_reinforcement("koakuma_boss", phase)
	return _set_rumia_state(zombie, "phase", 0.62)


func _trigger_patchouli_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	var center = Vector2(_boss_anchor_x("patchouli_boss") - 98.0, _row_center_y(int(zombie["row"])) - 8.0)
	_show_banner("帕秋莉展开了更复杂的属性符卡！", 2.0)
	effects.append({
		"shape": "arcane_circle",
		"position": center,
		"radius": 198.0 + phase * 24.0,
		"time": 0.58,
		"duration": 0.58,
		"anim_speed": 5.2,
		"color": Color(0.78, 0.58, 1.0, 0.34),
	})
	_spawn_blood_library_hazard()
	_damage_plants_in_circle(center, 180.0 + phase * 18.0, 48.0 + phase * 16.0)
	_stagger_plants_in_circle(center, 190.0 + phase * 18.0, 1.0 + phase * 0.12)
	for _i in range(phase + 1):
		_spawn_hover_boss_reinforcement("patchouli_boss", phase)
	return _set_rumia_state(zombie, "phase", 0.72)


func _trigger_sakuya_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	var center = Vector2(_boss_anchor_x("sakuya_boss") - 96.0, _row_center_y(int(zombie["row"])) - 10.0)
	_show_banner("咲夜进入第 %d 阶段！" % (phase + 1), 2.0)
	effects.append({
		"shape": "sakuya_time_grid",
		"position": center,
		"radius": 210.0 + phase * 22.0,
		"width": board_size.y * 0.4,
		"time": 0.6,
		"duration": 0.6,
		"anim_speed": 8.0,
		"color": Color(0.84, 0.9, 1.0, 0.34),
	})
	boss_time_stop_timer = maxf(boss_time_stop_timer, 0.8 + phase * 0.18)
	boss_time_stop_flash_timer = maxf(boss_time_stop_flash_timer, 0.4)
	_damage_plants_in_circle(center, 168.0 + phase * 18.0, 46.0 + phase * 12.0)
	for _i in range(phase + 1):
		_spawn_hover_boss_reinforcement("sakuya_boss", phase)
	return _set_rumia_state(zombie, "phase", 0.72)


func _trigger_remilia_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	var center = Vector2(_boss_anchor_x("remilia_boss") - 104.0, _row_center_y(int(zombie["row"])) - 10.0)
	_show_banner("蕾米莉亚进入第 %d 阶段！" % (phase + 1), 2.2)
	effects.append({
		"shape": "remilia_crimson_field",
		"position": Vector2(BOARD_ORIGIN.x + board_size.x * 0.54, BOARD_ORIGIN.y + board_size.y * 0.5 - 12.0),
		"length": board_size.x * 0.88,
		"width": board_size.y * 0.92,
		"radius": board_size.x * 0.48,
		"time": 0.6,
		"duration": 0.6,
		"anim_speed": 7.4,
		"color": Color(0.98, 0.16, 0.22, 0.34),
	})
	effects.append({
		"shape": "remilia_blood_sigil",
		"position": center,
		"radius": 224.0 + phase * 22.0,
		"time": 0.64,
		"duration": 0.64,
		"anim_speed": 6.6,
		"color": Color(0.94, 0.18, 0.26, 0.34),
	})
	var cells = _remilia_target_cells(int(zombie.get("row", 0)), 3 + phase, 2)
	_damage_plants_in_cells(cells, 76.0 + phase * 18.0, 1.0 + phase * 0.08)
	for cell_variant in cells:
		var cell = Vector2i(cell_variant)
		effects.append({
			"shape": "remilia_gungnir_lance",
			"position": center,
			"target": _cell_center(cell.x, cell.y) + Vector2(0.0, -10.0),
			"radius": 156.0,
			"time": 0.34,
			"duration": 0.34,
			"color": Color(1.0, 0.3, 0.24, 0.26),
		})
	for _i in range(phase + 1):
		_spawn_hover_boss_reinforcement("remilia_boss", phase)
	zombie = _heal_hover_boss(zombie, 140.0 + float(phase) * 90.0)
	return _set_rumia_state(zombie, "phase", 0.78)


func _trigger_boss_phase_shift(zombie: Dictionary, phase: int) -> Dictionary:
	if String(zombie["kind"]) == "rumia_boss":
		return _trigger_rumia_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "daiyousei_boss":
		return _trigger_daiyousei_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "cirno_boss":
		return _trigger_cirno_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "meiling_boss":
		return _trigger_meiling_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "koakuma_boss":
		return _trigger_koakuma_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "patchouli_boss":
		return _trigger_patchouli_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "sakuya_boss":
		return _trigger_sakuya_boss_phase_shift(zombie, phase)
	if String(zombie["kind"]) == "remilia_boss":
		return _trigger_remilia_boss_phase_shift(zombie, phase)
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
	if String(zombie["kind"]) == "fog_boss":
		_show_banner("雾岚尸王进入第 %d 阶段！" % (phase + 1), 2.0)
		var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		effects.append({
			"position": center,
			"radius": 188.0 + phase * 24.0,
			"time": 0.58,
			"duration": 0.58,
			"color": Color(0.64, 0.96, 0.84, 0.4),
		})
		for lane in active_rows:
			var bog_col = clampi(rng.randi_range(2, COLS - 2), 0, COLS - 1)
			_spawn_bog_pool(_cell_center(int(lane), bog_col), 58.0 + phase * 10.0, 8.0 + phase * 1.6)
			_damage_front_plant_in_row(int(lane), 92.0 + phase * 24.0)
			effects.append({
				"shape": "mist_cloud",
				"position": _cell_center(int(lane), bog_col) + Vector2(rng.randf_range(-14.0, 14.0), -20.0),
				"radius": 50.0 + phase * 8.0,
				"time": 0.54,
				"duration": 0.54,
				"anim_speed": 4.6,
				"color": Color(0.76, 0.98, 0.9, 0.16),
			})
		for summon_kind in ["tornado_zombie", "barrel_screen_zombie", "wolf_knight_zombie"]:
			_spawn_zombie(summon_kind, _choose_spawn_row_for_kind(summon_kind), true)
		return zombie
	if String(zombie["kind"]) == "roof_boss":
		_show_banner("穹顶尸王进入第 %d 阶段！" % (phase + 1), 2.0)
		var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 8.0)
		effects.append({
			"position": center,
			"radius": 196.0 + phase * 22.0,
			"time": 0.58,
			"duration": 0.58,
			"color": Color(1.0, 0.64, 0.22, 0.42),
		})
		for lane in active_rows:
			var lane_row = int(lane)
			_damage_front_plant_in_row(lane_row, 108.0 + phase * 26.0)
			if lane_row % 2 == phase % 2:
				effects.append({
					"shape": "lane_spray",
					"position": Vector2(BOARD_ORIGIN.x + CELL_SIZE.x * 1.4, _row_center_y(lane_row) - 8.0),
					"length": board_size.x - CELL_SIZE.x * 0.8,
					"width": CELL_SIZE.y * 0.5,
					"radius": board_size.x,
					"time": 0.28,
					"duration": 0.28,
					"color": Color(1.0, 0.76, 0.34, 0.16),
				})
		for summon_kind in ["ladder_zombie", "catapult_zombie", "turret_zombie"]:
			_spawn_zombie(summon_kind, _choose_spawn_row_for_kind(summon_kind), true)
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
	var terrain = _cell_terrain_kind(int(zombie["row"]), _zombie_cell_col(float(zombie["x"])))
	if terrain == "snowfield":
		speed *= 0.42
	if String(zombie.get("kind", "")) == "subway_zombie" and terrain == "rail":
		speed *= 2.35
	if float(zombie["slow_timer"]) > 0.0:
		speed *= 0.5
	if float(zombie.get("rooted_timer", 0.0)) > 0.0:
		speed *= 0.24
	if _is_enemy_zombie(zombie):
		var router_count = _count_alive_enemy_zombies_by_kind("router_zombie")
		if router_count > 0:
			speed *= pow(float(Defs.ZOMBIES["router_zombie"].get("aura_speed_mult", 1.0)), router_count)
	return speed


func _explode_jack_in_the_box(zombie: Dictionary) -> void:
	var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) - 6.0)
	var radius = float(Defs.ZOMBIES["jack_in_the_box_zombie"].get("explode_radius", 132.0))
	var damage = float(Defs.ZOMBIES["jack_in_the_box_zombie"].get("explode_damage", 5000.0))
	_damage_plants_in_circle(center, radius, damage)
	_damage_zombies_in_circle(center, radius * 0.88, damage * 0.22)
	effects.append({
		"position": center,
		"radius": radius,
		"time": 0.34,
		"duration": 0.34,
		"color": Color(1.0, 0.46, 0.18, 0.36),
	})


func _update_digger_tunnel(zombie: Dictionary, delta: float) -> Dictionary:
	if float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
		zombie["x"] -= _current_zombie_speed(zombie) * delta
	if float(zombie["x"]) <= BOARD_ORIGIN.x + CELL_SIZE.x * 1.1:
		zombie["digger_tunneling"] = false
		zombie["digger_reversed"] = true
		zombie["base_speed"] = float(Defs.ZOMBIES["digger_zombie"]["speed"])
		zombie["special_pause_timer"] = maxf(float(zombie.get("special_pause_timer", 0.0)), 0.36)
		effects.append({
			"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + 14.0),
			"radius": 52.0,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.7, 0.56, 0.28, 0.28),
		})
	return zombie


func _find_reverse_bite_target(row: int, zombie_x: float) -> Vector2i:
	for col in range(COLS):
		var plant_variant = _targetable_plant_at(row, col)
		if plant_variant == null:
			continue
		if _is_low_profile_kind(String(plant_variant["kind"])):
			continue
		var center_x = _cell_center(row, col).x
		if zombie_x >= center_x - 38.0 and zombie_x <= center_x + 20.0:
			return Vector2i(row, col)
	return Vector2i(-1, -1)


func _update_reversed_digger(zombie: Dictionary, delta: float) -> Dictionary:
	var target = _find_reverse_bite_target(int(zombie["row"]), float(zombie["x"]))
	if target.y != -1:
		var plant = _targetable_plant_at(target.x, target.y)
		if plant != null:
			var bite_damage = float(zombie["attack_dps"]) * delta
			if float(plant.get("armor_health", 0.0)) > 0.0:
				var armor_left = float(plant["armor_health"]) - bite_damage
				if armor_left < 0.0:
					plant["health"] += armor_left
					armor_left = 0.0
				plant["armor_health"] = armor_left
			else:
				plant["health"] -= bite_damage
			plant["flash"] = 0.08
			_set_targetable_plant(target.x, target.y, plant)
			zombie["bite_timer"] = maxf(float(zombie.get("bite_timer", 0.0)), 0.18)
		return zombie
	if float(zombie.get("special_pause_timer", 0.0)) <= 0.0:
		zombie["x"] += _current_zombie_speed(zombie) * delta
	if float(zombie["x"]) >= BOARD_ORIGIN.x + board_size.x + 120.0:
		zombie["health"] = 0.0
	return zombie


func _begin_dragon_boat_stroke(zombie: Dictionary) -> Dictionary:
	var boat_phase = int(zombie.get("boat_phase", 0))
	var direction = 1.0 if boat_phase == 2 else -1.0
	var distance = CELL_SIZE.x
	zombie["boat_move_from_x"] = float(zombie["x"])
	zombie["boat_move_to_x"] = float(zombie["x"]) + direction * distance
	zombie["boat_move_t"] = 0.0
	zombie["boat_move_duration"] = 1.02 if boat_phase == 2 else 1.18
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
	var crush_cell = _find_crushable_cell(int(zombie["row"]), float(zombie["x"]), 94.0)
	if crush_cell.y != -1:
		_crush_cell(crush_cell.x, crush_cell.y)
	if move_t >= 1.0:
		zombie["boat_stride_timer"] = 0.46
		effects.append({
			"position": Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + 18.0),
			"radius": 48.0,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(0.82, 0.94, 1.0, 0.24),
		})
	return zombie


func _dragon_boat_visual_state(center: Vector2, zombie: Dictionary) -> Dictionary:
	var flash = float(zombie.get("flash", 0.0))
	var move_ratio = clampf(float(zombie.get("boat_move_t", 1.0)), 0.0, 1.0)
	var stroke_curve = sin(move_ratio * PI)
	var stroke_dir = 1.0 if int(zombie.get("boat_phase", 0)) == 0 else -1.0
	var bob = sin(level_time * 3.2 + float(zombie.get("anim_phase", 0.0))) * 1.8 + stroke_curve * 3.4
	var boat = center + Vector2(0.0, 12.0 + bob)
	var bow_lift = stroke_curve * 5.5
	var stern_lift = stroke_curve * 2.4
	var oar_swing = stroke_dir * stroke_curve * 18.0
	var hull = PackedVector2Array([
		boat + Vector2(-54.0, 8.0 + stern_lift),
		boat + Vector2(-18.0, -12.0 + stern_lift * 0.3),
		boat + Vector2(44.0, -10.0 - bow_lift * 0.9),
		boat + Vector2(62.0, 4.0 - bow_lift * 0.45),
		boat + Vector2(40.0, 17.0 + bow_lift * 0.24),
		boat + Vector2(-42.0, 19.0 + stern_lift * 0.42),
	])
	var riders: Array = []
	for seat in range(3):
		var rider_center = boat + Vector2(
			-26.0 + float(seat) * 22.0,
			-18.0 + sin(level_time * 4.2 + float(seat) * 0.6) * 1.2 + stroke_curve * (1.8 - seat * 0.35)
		)
		var paddle_base = rider_center + Vector2(10.0, 6.0)
		riders.append({
			"center": rider_center,
			"body_rect": Rect2(rider_center + Vector2(-10.0, 8.0), Vector2(20.0, 18.0)),
			"paddle_from": paddle_base,
			"paddle_to": paddle_base + Vector2(10.0 + oar_swing * 0.3, 18.0 - stroke_curve * 8.0),
		})
	return {
		"flash": flash,
		"stroke_curve": stroke_curve,
		"stroke_dir": stroke_dir,
		"boat": boat,
		"shadow_center": boat + Vector2(0.0, 28.0),
		"hull": hull,
		"riders": riders,
		"flag_a_from": boat + Vector2(36.0, -10.0 - bow_lift * 0.15),
		"flag_a_to": boat + Vector2(60.0, -32.0 - bow_lift * 0.22),
		"flag_b_from": boat + Vector2(60.0, -32.0 - bow_lift * 0.22),
		"flag_b_to": boat + Vector2(76.0, -26.0 - bow_lift * 0.1),
		"oar_left_from": boat + Vector2(-14.0, -8.0 + stern_lift * 0.2),
		"oar_left_to": boat + Vector2(-32.0 - oar_swing * 0.28, 22.0 - stroke_curve * 6.0),
		"oar_mid_from": boat + Vector2(8.0, -12.0),
		"oar_mid_to": boat + Vector2(-10.0 - oar_swing * 0.22, 18.0 - stroke_curve * 7.0),
	}


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
	_trigger_screen_shake(8.0 if mega else 5.0)
	_spawn_death_poof(center, Color(1.0, 0.6, 0.2) if not mega else Color(0.4, 1.0, 0.4))
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) <= radius:
			zombie["health"] -= damage
			zombie["flash"] = 0.24
			zombies[i] = zombie
	_apply_ash_hits_in_circle(center, radius, 1)
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
		_apply_ash_hits_in_row_segment(int(lane), BOARD_ORIGIN.x - 8.0, BOARD_ORIGIN.x + board_size.x + 24.0, 1)
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
	_trigger_screen_shake(12.0 if boosted else 8.0)
	_spawn_death_poof(center, Color(0.5, 0.1, 0.3))
	_damage_zombies_in_circle(center, radius, damage)
	_apply_ash_hits_in_circle(center, radius, 1)
	_damage_obstacles_in_circle(center, radius, damage)


func _find_projectile_target(projectile: Dictionary) -> int:
	var best_index = -1
	var best_distance = 999999.0
	var projectile_pos = Vector2(projectile["position"])
	var projectile_radius = float(projectile.get("radius", 8.0))
	var free_aim = bool(projectile.get("free_aim", false))
	var anti_air = bool(projectile.get("anti_air", false))
	var ignore_lane_hide = bool(projectile.get("ignore_lane_hide", false))
	var moving_left = float(projectile.get("speed", 0.0)) < 0.0
	var ignored_uids: Array = projectile.get("hit_uids", [])
	for i in range(zombies.size()):
		var zombie = zombies[i]
		var hidden = _is_hidden_from_lane_attacks(zombie)
		var can_ignore_hidden = ignore_lane_hide and not _is_hidden_for_direct_fire_ignoring_fog(zombie)
		if ((hidden and not can_ignore_hidden and not (anti_air and bool(zombie.get("balloon_flying", false)))) or not _is_enemy_zombie(zombie)):
			continue
		if free_aim:
			if absf(_row_center_y(int(zombie["row"])) - projectile_pos.y) > 24.0:
				continue
		elif int(zombie["row"]) != int(projectile["row"]):
			continue
		if bool(zombie.get("balloon_flying", false)) and not anti_air:
			continue
		if ignored_uids.has(int(zombie.get("uid", -1))):
			continue
		var distance = float(zombie["x"]) - projectile_pos.x
		if moving_left:
			distance = projectile_pos.x - float(zombie["x"])
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
	if _is_endless_level():
		return false
	if _is_vasebreaker_level() and not vases.is_empty():
		return false
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
			if float(plant.get("holy_invincible_timer", 0.0)) > 0.0:
				plant["flash"] = maxf(float(plant.get("flash", 0.0)), 0.1)
				continue
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
		if String(zombie.get("kind", "")) == "kite_trap":
			_damage_plant_cell(int(zombie.get("kite_target_row", -1)), int(zombie.get("kite_target_col", -1)), current_damage * 0.7, 0.2)
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
	var start_x = SUN_METER_RECT.position.x + SUN_METER_RECT.size.x + 12.0
	var y = SEED_BANK_RECT.position.y + 4.0
	return Rect2(
		Vector2(start_x + index * (card_size.x + card_gap), y),
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
	var start_x = SUN_METER_RECT.position.x + SUN_METER_RECT.size.x + 12.0
	var x = start_x + active_cards.size() * (card_size.x + card_gap) + 12.0
	return Rect2(x, SEED_BANK_RECT.position.y + 4.0, 84.0, 92.0)


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
	var selected_panel_rect = _selection_selected_panel_rect()
	var step = (selected_panel_rect.size.x - 40.0) / float(MAX_SEED_SLOTS)
	var width = maxf(68.0, minf(88.0, step - 8.0))
	return Rect2(
		Vector2(selected_panel_rect.position.x + 20.0 + index * step, selected_panel_rect.position.y + 14.0),
		Vector2(width, 100.0)
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
	var pool_panel_rect = _selection_pool_panel_rect()
	var footer_rect = _selection_footer_rect()
	return Rect2(
		pool_panel_rect.position + Vector2(18.0, 40.0),
		Vector2(pool_panel_rect.size.x - 62.0, maxf(72.0, footer_rect.position.y - pool_panel_rect.position.y - 56.0))
	)


func _selection_pool_hover_rect() -> Rect2:
	var view_rect = _selection_pool_view_rect()
	return Rect2(
		view_rect.position + Vector2(8.0, 10.0),
		Vector2(view_rect.size.x - 16.0, view_rect.size.y - 18.0)
	)


func _selection_pool_track_rect() -> Rect2:
	var view_rect = _selection_pool_view_rect()
	var pool_panel_rect = _selection_pool_panel_rect()
	return Rect2(
		Vector2(pool_panel_rect.position.x + pool_panel_rect.size.x - 28.0, view_rect.position.y),
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
	if mode_name == "conveyor" or mode_name == "bowling" or mode_name == "whack" or mode_name == "vasebreaker":
		return false
	return _resolved_selection_pool_for_level(level).size() > MAX_SEED_SLOTS


func _required_seed_count(level: Dictionary) -> int:
	var mode_name = String(level.get("mode", ""))
	if mode_name == "conveyor" or mode_name == "bowling" or mode_name == "vasebreaker":
		return 0
	if mode_name == "whack":
		return _resolved_selection_pool_for_level(level).size()
	return min(_resolved_selection_pool_for_level(level).size(), MAX_SEED_SLOTS)


func _default_level_cards(level: Dictionary) -> Array:
	var cards: Array = []
	var required_count = _required_seed_count(level)
	for kind in _resolved_selection_pool_for_level(level):
		if cards.size() >= required_count:
			break
		cards.append(kind)
	return cards


func _available_seed_cards_for_level(level: Dictionary) -> Array:
	var mode_name = String(level.get("mode", ""))
	if mode_name == "conveyor" or mode_name == "bowling" or mode_name == "whack" or mode_name == "vasebreaker":
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
	for kind_variant in plant_stars.keys():
		var plant_kind = String(kind_variant)
		if plant_kind == "" or seen.has(plant_kind) or not Defs.PLANTS.has(plant_kind):
			continue
		if int(plant_stars.get(plant_kind, 0)) <= 0:
			continue
		seen[plant_kind] = true
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
	if level_id.begins_with("6-"):
		return "city"
	if level_id.begins_with("5-"):
		return "roof"
	if level_id.begins_with("4-"):
		return "fog"
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


func _map_mode_title_for_world(world_key: String) -> String:
	match world_key:
		"city":
			return "城市冒险"
		"night":
			return "夜晚冒险"
		"pool":
			return "泳池冒险"
		"fog":
			return "浓雾冒险"
		"roof":
			return "屋顶冒险"
		_:
			return "白天冒险"


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
	for i in range(Defs.LEVELS.size()):
		if not _is_level_unlocked(i):
			continue
		var level = Defs.LEVELS[i]
		for kind in level["available_plants"]:
			var plant_kind = String(kind)
			if plant_kind == "" or seen.has(plant_kind) or not Defs.PLANTS.has(plant_kind):
				continue
			seen[plant_kind] = true
		var unlock_kind = String(level.get("unlock_plant", ""))
		if unlock_kind != "" and not seen.has(unlock_kind) and Defs.PLANTS.has(unlock_kind):
			seen[unlock_kind] = true
	for plant_kind in _player_plant_collection():
		var owned_kind = String(plant_kind)
		if owned_kind == "" or seen.has(owned_kind) or not Defs.PLANTS.has(owned_kind):
			continue
		seen[owned_kind] = true
	var result: Array = []
	for plant_kind in Defs.PLANT_ORDER:
		var ordered_kind = String(plant_kind)
		if seen.has(ordered_kind):
			result.append(ordered_kind)
	return result


func _visible_almanac_zombies() -> Array:
	var seen := {}
	var encountered := {}
	for i in range(Defs.LEVELS.size()):
		if not _is_level_unlocked(i):
			continue
		for event in Defs.LEVELS[i]["events"]:
			encountered[String(event["kind"])] = true
	if encountered.has("gargantuar"):
		encountered["imp"] = true
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


func _is_vasebreaker_level() -> bool:
	return String(current_level.get("mode", "")) == "vasebreaker"


func _is_night_level() -> bool:
	return not current_level.is_empty() and (_world_key_for_level(current_level) == "night" or String(current_level.get("terrain", "")) == "vasebreaker_night")


func _is_fog_level() -> bool:
	var terrain = String(current_level.get("terrain", ""))
	return terrain == "fog" or terrain == "storm_fog"


func _is_clear_backyard_level() -> bool:
	return String(current_level.get("terrain", "")) == "clear_backyard"


func _is_storm_fog_level() -> bool:
	return String(current_level.get("terrain", "")) == "storm_fog"


func _level_has_sky_sun() -> bool:
	if current_level.is_empty():
		return true
	return not _is_night_level() and not _is_fog_level()


func _is_blood_moon_level() -> bool:
	return String(current_level.get("terrain", "")) == "blood_moon"


func _is_blood_library_level() -> bool:
	return String(current_level.get("terrain", "")) == "blood_library"


func _is_scarlet_clocktower_level() -> bool:
	return String(current_level.get("terrain", "")) == "scarlet_clocktower"


func _scarlet_clocktower_floor_style() -> Dictionary:
	return {
		"tile_mode": "ceramic",
		"tile_inset": 9.0,
		"mortar": Color(0.14, 0.03, 0.06, 0.8),
		"tile_light": Color(0.82, 0.22, 0.18, 0.92),
		"tile_dark": Color(0.42, 0.08, 0.12, 0.96),
		"bevel_light": Color(1.0, 0.86, 0.8, 0.24),
		"bevel_shadow": Color(0.18, 0.02, 0.08, 0.46),
		"gloss": Color(1.0, 0.92, 0.86, 0.12),
		"accent": Color(0.98, 0.72, 0.52, 0.2),
		"rivet": Color(0.96, 0.82, 0.64, 0.24),
	}


func _has_scarlet_clock_hazard() -> bool:
	return _is_scarlet_clocktower_level() and current_level.has("clock_hazard_interval")


func _is_frozen_branch_level() -> bool:
	return String(current_level.get("terrain", "")) == "frozen_lake"


func _is_pool_level() -> bool:
	return not current_level.is_empty() and _world_key_for_level(current_level) == "pool"


func _uses_backyard_pool_board() -> bool:
	return _is_pool_level() or _is_fog_level() or _is_clear_backyard_level()


func _fog_hidden_columns() -> float:
	if not _is_fog_level():
		return 0.0
	return maxf(0.0, float(current_level.get("fog_columns", 4.0)))


func _fog_hidden_left_x() -> float:
	return BOARD_ORIGIN.x + maxf(0.0, board_size.x - _fog_hidden_columns() * CELL_SIZE.x)


func _plantern_reveal_radius() -> float:
	return CELL_SIZE.x * 2.35


func _refresh_fog_visibility_state() -> void:
	queue_redraw()


func _plantern_reveals_position(position: Vector2) -> bool:
	var reveal_radius = _plantern_reveal_radius()
	for row in range(ROWS):
		for col in range(COLS):
			var plant = _top_plant_at(row, col)
			if plant == null:
				continue
			var kind = String(plant.get("kind", ""))
			if kind != "plantern":
				continue
			if _cell_center(row, col).distance_to(position) <= reveal_radius:
				return true
	return false


func _is_position_revealed_by_fog_rules(position: Vector2) -> bool:
	if not _is_fog_level():
		return true
	if position.x <= _fog_hidden_left_x():
		return true
	if fog_global_reveal_timer > 0.0 or fog_lightning_timer > 0.0:
		return true
	return _plantern_reveals_position(position)


func _is_cell_revealed(row: int, col: int) -> bool:
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return false
	return _is_position_revealed_by_fog_rules(_cell_center(row, col))


func _trigger_blover_fog_clear(duration: float = 4.8) -> void:
	fog_global_reveal_timer = maxf(fog_global_reveal_timer, duration)
	effects.append({
		"position": BOARD_ORIGIN + board_size * 0.5,
		"radius": maxf(board_size.x, board_size.y) * 0.9,
		"time": 0.34,
		"duration": 0.34,
		"color": Color(0.82, 1.0, 0.92, 0.16),
	})


func _trigger_storm_lightning_flash(duration: float = 1.15) -> void:
	if not _is_storm_fog_level():
		return
	fog_lightning_timer = maxf(fog_lightning_timer, duration)
	storm_lightning_cooldown = rng.randf_range(3.8, 6.2)
	effects.append({
		"position": BOARD_ORIGIN + board_size * 0.5,
		"radius": maxf(board_size.x, board_size.y),
		"time": 0.24,
		"duration": 0.24,
		"color": Color(0.94, 0.98, 1.0, 0.3),
	})


func _update_fog_state(delta: float) -> void:
	if not _is_fog_level():
		fog_global_reveal_timer = 0.0
		fog_lightning_timer = 0.0
		return
	fog_drift_offset = fmod(fog_drift_offset + delta * 26.0, board_size.x + 220.0)
	fog_global_reveal_timer = maxf(0.0, fog_global_reveal_timer - delta)
	fog_lightning_timer = maxf(0.0, fog_lightning_timer - delta)
	if _is_storm_fog_level():
		storm_lightning_cooldown = maxf(0.0, storm_lightning_cooldown - delta)
		if storm_lightning_cooldown <= 0.0:
			_trigger_storm_lightning_flash()


func _is_water_row(row: int) -> bool:
	return water_rows.has(row)


func _grave_index_at(row: int, col: int) -> int:
	for i in range(graves.size()):
		var grave = graves[i]
		if int(grave["row"]) == row and int(grave["col"]) == col:
			return i
	return -1


func _vase_index_at(row: int, col: int) -> int:
	for i in range(vases.size()):
		var vase = vases[i]
		if int(vase["row"]) == row and int(vase["col"]) == col:
			return i
	return -1


func _setup_vasebreaker_vases() -> void:
	vases.clear()
	var rows: Array = []
	for row_variant in active_rows:
		rows.append(int(row_variant))
	if rows.is_empty():
		return
	var zombie_pool: Array = ["normal", "conehead", "screen_door", "balloon_zombie"]
	var plant_pool: Array = []
	for kind_variant in current_level.get("available_plants", []):
		var plant_kind = String(kind_variant)
		if plant_kind == "" or plant_kind == "grave_buster" or plant_kind == "blover":
			continue
		if bool(Defs.PLANTS.get(plant_kind, {}).get("water_only", false)):
			continue
		plant_pool.append(plant_kind)
	if plant_pool.is_empty():
		plant_pool = ["wallnut", "snow_pea", "puff_shroom", "fume_shroom", "cactus"]
	for row in rows:
		for col in range(4, COLS):
			var is_zombie_vase = col >= 6 or ((row + col) % 3 == 0)
			var content_kind = zombie_pool[(row + col) % zombie_pool.size()] if is_zombie_vase else plant_pool[(row * COLS + col) % plant_pool.size()]
			vases.append({
				"row": row,
				"col": col,
				"content_type": "zombie" if is_zombie_vase else "plant",
				"content_kind": content_kind,
			})


func _break_vase_at(row: int, col: int) -> bool:
	var vase_index = _vase_index_at(row, col)
	if vase_index == -1:
		return false
	var vase = vases[vase_index]
	vases.remove_at(vase_index)
	var center = _cell_center(row, col)
	effects.append({
		"position": center + Vector2(0.0, 10.0),
		"radius": 44.0,
		"time": 0.24,
		"duration": 0.24,
		"color": Color(0.86, 0.9, 1.0, 0.24),
	})
	if String(vase.get("content_type", "")) == "zombie":
		_spawn_zombie_at(String(vase.get("content_kind", "normal")), row, center.x + 22.0)
	else:
		if _top_plant_at(row, col) == null and _support_plant_at(row, col) == null:
			grid[row][col] = _create_plant(String(vase.get("content_kind", "puff_shroom")), row, col)
			grid[row][col]["flash"] = 0.18
	return true


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
	if kind == "buckethead" or kind == "day_boss" or kind == "night_boss" or kind == "pool_boss" or kind == "fog_boss" or kind == "roof_boss" or kind == "rumia_boss" or kind == "meiling_boss" or kind == "koakuma_boss" or kind == "patchouli_boss" or kind == "sakuya_boss" or kind == "remilia_boss" or kind == "football" or kind == "dark_football":
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
		"pool_boss":
			if extra_index == 0:
				return "qinghua"
			return "dragon_dance" if progress >= 0.7 else "ice_block"
		"fog_boss":
			if extra_index == 0:
				return "tornado_zombie" if progress >= 0.72 else "balloon_zombie"
			return "barrel_screen_zombie" if progress >= 0.72 else "screen_door"
		"roof_boss":
			if extra_index == 0:
				return "ladder_zombie" if progress >= 0.68 else "kite_zombie"
			return "turret_zombie" if progress >= 0.72 else "catapult_zombie"
		"rumia_boss":
			if extra_index == 0:
				return "conehead"
			return "buckethead" if progress >= 0.7 else "screen_door"
		"meiling_boss":
			if extra_index == 0:
				return "conehead" if progress < 0.55 else "football"
			return "dark_football" if progress >= 0.76 else "screen_door"
		"koakuma_boss":
			if extra_index == 0:
				return "newspaper" if progress < 0.5 else "screen_door"
			return "basketball" if progress >= 0.76 else "football"
		"patchouli_boss":
			if extra_index == 0:
				return "screen_door" if progress < 0.52 else "football"
			return "basketball" if progress >= 0.78 else "ninja"
		"sakuya_boss":
			if extra_index == 0:
				return "screen_door" if progress >= 0.48 else "conehead"
			return "dark_football" if progress >= 0.74 else "football"
		"remilia_boss":
			if extra_index == 0:
				return "screen_door" if progress < 0.45 else "football"
			return "dark_football" if progress >= 0.74 else "basketball"
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
	if startup_loading_active:
		_draw_startup_loading_scene()
		return
	if page_transition_active:
		var eased = ThemeLib.ease_in_out(page_transition_progress)
		var travel = size.x * 0.94
		var from_offset = Vector2(-travel * eased * page_transition_direction, 0.0)
		var to_offset = Vector2(travel * (1.0 - eased) * page_transition_direction, 0.0)
		_draw_mode_scene(page_transition_from_mode, from_offset)
		_draw_mode_scene(page_transition_to_mode, to_offset)
		# Improved transition overlay with vignette
		var fade_alpha = 0.1 * sin(eased * PI)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.04, fade_alpha), true)
		# Edge darkening during transition
		ThemeLib.draw_gradient_rect_h(self, Rect2(Vector2.ZERO, Vector2(80.0, size.y)), Color(0.0, 0.0, 0.0, fade_alpha * 0.6), Color(0.0, 0.0, 0.0, 0.0))
		ThemeLib.draw_gradient_rect_h(self, Rect2(Vector2(size.x - 80.0, 0.0), Vector2(80.0, size.y)), Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, fade_alpha * 0.6))
		return
	_draw_mode_scene(mode, Vector2.ZERO)


func _draw_startup_loading_scene() -> void:
	ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, size), Color(0.08, 0.05, 0.02), Color(0.18, 0.04, 0.04))
	for i in range(7):
		var seed = float(i) * 31.0
		var orbit = ui_time * (0.3 + float(i) * 0.05) + seed
		var center = size * 0.5 + Vector2(cos(orbit) * (180.0 + float(i) * 24.0), sin(orbit * 0.7) * (82.0 + float(i) * 14.0))
		draw_circle(center, 48.0 + float(i) * 10.0, Color(0.7, 0.14 + float(i) * 0.05, 0.16 + float(i) * 0.03, 0.05))
	var panel_rect = Rect2(size * 0.5 - Vector2(340.0, 176.0), Vector2(680.0, 352.0))
	_draw_panel_shell(panel_rect, Color(0.16, 0.1, 0.08, 0.94), Color(0.62, 0.22, 0.18), 0.12, 0.08)
	_draw_text("正在加载庭院", panel_rect.position + Vector2(192.0, 72.0), 36, Color(1.0, 0.94, 0.88))
	_draw_text("预热 Boss 立绘、图鉴和 BGM，避免进图和翻页时卡顿。", panel_rect.position + Vector2(72.0, 118.0), 21, Color(0.96, 0.86, 0.78))
	var progress = 1.0
	if startup_loading_total_tasks > 0:
		progress = clampf(float(startup_loading_completed_tasks) / float(startup_loading_total_tasks), 0.0, 1.0)
	var bar_rect = Rect2(panel_rect.position + Vector2(72.0, 180.0), Vector2(536.0, 26.0))
	_draw_panel_shell(bar_rect, Color(0.22, 0.14, 0.12, 0.96), Color(0.42, 0.18, 0.16), 0.1, 0.08)
	draw_rect(Rect2(bar_rect.position + Vector2(4.0, 4.0), Vector2((bar_rect.size.x - 8.0) * progress, bar_rect.size.y - 8.0)), Color(0.94, 0.34, 0.24, 0.96), true)
	_draw_text("已处理 %d / %d 项资源" % [startup_loading_completed_tasks, max(startup_loading_total_tasks, 1)], panel_rect.position + Vector2(178.0, 244.0), 20, Color(0.98, 0.92, 0.86))
	for dot_index in range(3):
		var pulse = 0.45 + 0.55 * sin(ui_time * 5.2 + float(dot_index) * 0.8)
		draw_circle(panel_rect.position + Vector2(302.0 + float(dot_index) * 34.0, 292.0), 8.0 + pulse * 4.0, Color(1.0, 0.84, 0.52, 0.35 + pulse * 0.45))


func _draw_mode_scene(draw_mode: String, offset: Vector2) -> void:
	var shake_offset = Vector2.ZERO
	if draw_mode == MODE_BATTLE and screen_shake_amount > 0.5:
		shake_offset = Vector2(sin(ui_time * 67.3) * screen_shake_amount, cos(ui_time * 53.7) * screen_shake_amount * 0.6)
	draw_set_transform(offset + shake_offset, 0.0, Vector2.ONE)
	if draw_mode == MODE_WORLD_SELECT:
		_draw_world_select_scene()
	elif draw_mode == MODE_MAP:
		_draw_map_scene()
	elif draw_mode == MODE_ALMANAC:
		_draw_almanac_scene()
	elif draw_mode == MODE_SELECTION:
		_draw_seed_selection_scene()
	elif draw_mode == MODE_GACHA:
		_draw_gacha_scene()
	elif draw_mode == MODE_ENHANCE:
		_draw_enhance_scene()
	elif draw_mode == MODE_ENDLESS:
		_draw_battle_scene()
	elif draw_mode == MODE_DAILY:
		_draw_battle_scene()
	else:
		_draw_battle_scene()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_gacha_scene() -> void:
	# Background gradient
	ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, size), Color(0.12, 0.08, 0.22), Color(0.06, 0.04, 0.14))
	# Floating card silhouettes
	for i in range(8):
		var seed_val = float(i) * 47.3
		var x = fmod(ui_time * (12.0 + fmod(seed_val, 8.0)) + seed_val * 5.1, size.x + 100.0) - 50.0
		var y = fmod(seed_val * 3.7 + sin(ui_time * 0.3 + seed_val) * 60.0, size.y)
		var rot = sin(ui_time * 0.5 + seed_val) * 0.3
		draw_rect(Rect2(Vector2(x - 20.0, y - 28.0), Vector2(40.0, 56.0)), Color(0.8, 0.7, 0.4, 0.04), true)

	# Title
	var title_rect = Rect2(size.x * 0.5 - 200.0, 30.0, 400.0, 80.0)
	_draw_panel_shell(title_rect, Color(0.82, 0.62, 0.18, 0.96), Color(0.52, 0.36, 0.08), 0.2, 0.12)
	_draw_text("抽卡系统", title_rect.position + Vector2(128.0, 50.0), 36, Color(1.0, 0.96, 0.86))

	# Coin display
	_draw_panel_shell(Rect2(size.x - 280.0, 40.0, 240.0, 52.0), Color(1.0, 0.92, 0.54), Color(0.55, 0.41, 0.08), 0.12, 0.06)
	_draw_text("金币: %d" % coins_total, Vector2(size.x - 256.0, 76.0), 26, Color(0.33, 0.21, 0.04))

	# Pity counter
	_draw_text("保底计数: %d/50" % gacha_pity_counter, Vector2(60.0, 76.0), 18, Color(0.72, 0.68, 0.82))

	# Draw buttons
	var single_rect = Rect2(size.x * 0.5 - 360.0, 140.0, 220.0, 72.0)
	var premium_rect = Rect2(size.x * 0.5 - 110.0, 140.0, 220.0, 72.0)
	var multi_rect = Rect2(size.x * 0.5 + 140.0, 140.0, 220.0, 72.0)
	_draw_panel_shell(single_rect, Color(0.42, 0.56, 0.42), Color(0.22, 0.32, 0.22), 0.18, 0.1)
	_draw_panel_shell(premium_rect, Color(0.62, 0.36, 0.82), Color(0.38, 0.18, 0.52), 0.2, 0.12)
	_draw_panel_shell(multi_rect, Color(0.86, 0.52, 0.18), Color(0.52, 0.28, 0.08), 0.2, 0.12)
	_draw_text("普通单抽", single_rect.position + Vector2(52.0, 32.0), 20, Color(0.96, 0.98, 0.94))
	_draw_text("50金", single_rect.position + Vector2(80.0, 56.0), 16, Color(0.82, 0.86, 0.78))
	_draw_text("高级单抽", premium_rect.position + Vector2(52.0, 32.0), 20, Color(1.0, 0.96, 1.0))
	_draw_text("200金", premium_rect.position + Vector2(72.0, 56.0), 16, Color(0.86, 0.78, 0.92))
	_draw_text("十连高级", multi_rect.position + Vector2(52.0, 32.0), 20, Color(1.0, 0.98, 0.94))
	_draw_text("1800金", multi_rect.position + Vector2(66.0, 56.0), 16, Color(0.86, 0.82, 0.72))

	# Draw results
	if gacha_draw_results.size() > 0:
		var results_y = 240.0
		var card_w = 120.0
		var card_h = 168.0
		var gap = 12.0
		var total_w = float(gacha_draw_results.size()) * (card_w + gap) - gap
		var start_x = (size.x - total_w) * 0.5
		for i in range(gacha_draw_results.size()):
			var result = gacha_draw_results[i]
			var card_x = start_x + float(i) * (card_w + gap)
			var card_rect = Rect2(card_x, results_y, card_w, card_h)
			var revealed = i < gacha_reveal_index
			if revealed:
				var rarity_color = _gacha_rarity_color(String(result["rarity"]))
				var result_type = String(result.get("type", "plant"))
				# Glow behind card
				draw_rect(card_rect.grow(6.0), Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.2), true)
				_draw_panel_shell(card_rect, Color(0.96, 0.94, 0.88), rarity_color, 0.16, 0.1)
				# Rarity bar
				draw_rect(Rect2(card_rect.position + Vector2(0.0, card_rect.size.y - 28.0), Vector2(card_rect.size.x, 28.0)), rarity_color.darkened(0.1), true)
				if result_type == "plant":
					_draw_card_icon(String(result["kind"]), card_rect.position + Vector2(card_rect.size.x * 0.5, 72.0))
					var pname = String(Defs.PLANTS[String(result["kind"])]["name"])
					if pname.length() > 4:
						pname = pname.left(4) + "…"
					_draw_text(pname, card_rect.position + Vector2(10.0, 22.0), 14, Color(0.22, 0.16, 0.06))
				elif result_type == "item":
					# Enhancement stone icon
					draw_circle(card_rect.position + Vector2(card_rect.size.x * 0.5, 72.0), 18.0, Color(0.82, 0.62, 0.18))
					draw_circle(card_rect.position + Vector2(card_rect.size.x * 0.5, 72.0), 12.0, Color(1.0, 0.86, 0.36))
					_draw_text("+1", card_rect.position + Vector2(card_rect.size.x * 0.5 - 10.0, 78.0), 16, Color(0.42, 0.22, 0.04))
					_draw_text(String(result.get("name", "道具")), card_rect.position + Vector2(10.0, 22.0), 12, Color(0.22, 0.16, 0.06))
				elif result_type == "fragment":
					draw_circle(card_rect.position + Vector2(card_rect.size.x * 0.5, 72.0), 16.0, Color(0.52, 0.72, 0.42))
					draw_circle(card_rect.position + Vector2(card_rect.size.x * 0.5, 72.0), 10.0, Color(0.62, 0.82, 0.52))
					_draw_text("x5", card_rect.position + Vector2(card_rect.size.x * 0.5 - 8.0, 78.0), 14, Color(0.22, 0.42, 0.12))
					var fname = String(result.get("name", "碎片"))
					if fname.length() > 6:
						fname = fname.left(6) + "…"
					_draw_text(fname, card_rect.position + Vector2(6.0, 22.0), 10, Color(0.22, 0.16, 0.06))
				else:
					# Junk
					draw_circle(card_rect.position + Vector2(card_rect.size.x * 0.5, 72.0), 14.0, Color(0.56, 0.52, 0.48))
					_draw_text("💩", card_rect.position + Vector2(card_rect.size.x * 0.5 - 10.0, 78.0), 20, Color(0.42, 0.36, 0.32))
					_draw_text(String(result.get("name", "垃圾")), card_rect.position + Vector2(6.0, 22.0), 10, Color(0.42, 0.36, 0.32))
				# Rarity label
				var rarity_labels = {"common": "普通", "rare": "稀有", "purple": "紫卡", "orange": "橙卡", "gold": "金卡", "junk": "垃圾"}
				var rarity_label = rarity_labels.get(String(result["rarity"]), "普通")
				_draw_text(rarity_label, card_rect.position + Vector2(28.0, card_rect.size.y - 8.0), 16, Color(1.0, 1.0, 1.0))
				# NEW badge
				if bool(result.get("is_new", false)):
					draw_rect(Rect2(card_rect.position + Vector2(card_rect.size.x - 40.0, 4.0), Vector2(36.0, 20.0)), Color(0.92, 0.24, 0.18), true)
					_draw_text("NEW", card_rect.position + Vector2(card_rect.size.x - 38.0, 20.0), 12, Color(1.0, 1.0, 1.0))
			else:
				# Unrevealed card back
				_draw_panel_shell(card_rect, Color(0.28, 0.22, 0.42), Color(0.48, 0.38, 0.62), 0.14, 0.08)
				draw_circle(card_rect.get_center(), 24.0, Color(0.62, 0.52, 0.82, 0.3))
				_draw_text("?", card_rect.get_center() + Vector2(-8.0, 10.0), 36, Color(0.72, 0.62, 0.92))

	# Collection grid (scrollable)
	var collection_y = 440.0
	_draw_panel_shell(Rect2(40.0, collection_y - 10.0, size.x - 80.0, 420.0), Color(0.14, 0.1, 0.24, 0.92), Color(0.38, 0.28, 0.52), 0.14, 0.06)
	_draw_text("植物收藏", Vector2(60.0, collection_y + 24.0), 22, Color(0.82, 0.78, 0.92))
	var col_x = 60.0
	var col_y = collection_y + 40.0
	var col_w = 86.0
	var col_h = 96.0
	var col_gap = 8.0
	var cols_per_row = int((size.x - 120.0) / (col_w + col_gap))
	var plant_keys = Defs.PLANTS.keys()
	for i in range(plant_keys.size()):
		var pk = String(plant_keys[i])
		var cx = col_x + float(i % cols_per_row) * (col_w + col_gap)
		var cy = col_y + floor(float(i) / float(cols_per_row)) * (col_h + col_gap) - gacha_mode_scroll
		if cy < collection_y + 30.0 or cy > collection_y + 400.0:
			continue
		var has_plant = plant_stars.has(pk)
		var cell_rect = Rect2(cx, cy, col_w, col_h)
		if has_plant:
			_draw_panel_shell(cell_rect, Color(0.92, 0.88, 0.78, 0.94), Color(0.48, 0.38, 0.22), 0.08, 0.04)
			_draw_card_icon(pk, cell_rect.position + Vector2(cell_rect.size.x * 0.5, 44.0))
			# Stars
			var stars = int(plant_stars[pk])
			for s in range(mini(stars, 5)):
				draw_circle(cell_rect.position + Vector2(12.0 + float(s) * 14.0, col_h - 10.0), 5.0, Color(1.0, 0.86, 0.2))
		else:
			draw_rect(cell_rect, Color(0.18, 0.14, 0.28, 0.6), true)
			draw_rect(cell_rect, Color(0.32, 0.26, 0.42), false, 1.5)
			_draw_text("?", cell_rect.get_center() + Vector2(-6.0, 8.0), 28, Color(0.42, 0.36, 0.52))

	# Back button
	var back_rect = Rect2(40.0, 40.0, 120.0, 52.0)
	_draw_panel_shell(back_rect, Color(0.56, 0.52, 0.62), Color(0.36, 0.32, 0.42), 0.14, 0.08)
	_draw_text("返回", back_rect.position + Vector2(36.0, 34.0), 22, Color(0.96, 0.94, 0.98))


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
	var center_x = size.x * 0.5 + (float(index) - world_select_scroll) * WORLD_CARD_SPACING
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

	# Endless mode button
	_draw_panel_shell(WORLD_SELECT_ENDLESS_RECT, Color(0.86, 0.28, 0.22), Color(0.52, 0.12, 0.1), 0.18, 0.1)
	_draw_text("无尽模式", WORLD_SELECT_ENDLESS_RECT.position + Vector2(48.0, 38.0), 22, Color(1.0, 0.94, 0.88))
	# Gacha button
	_draw_panel_shell(WORLD_SELECT_GACHA_RECT, Color(0.82, 0.62, 0.18), Color(0.48, 0.34, 0.08), 0.18, 0.1)
	_draw_text("抽卡系统", WORLD_SELECT_GACHA_RECT.position + Vector2(48.0, 38.0), 22, Color(1.0, 0.96, 0.86))
	# Enhance button (below gacha)
	var enhance_rect = Rect2(WORLD_SELECT_GACHA_RECT.position.x, WORLD_SELECT_GACHA_RECT.position.y + 72.0, 200.0, 52.0)
	_draw_panel_shell(enhance_rect, Color(0.62, 0.36, 0.82), Color(0.38, 0.18, 0.52), 0.16, 0.1)
	_draw_text("植物强化", enhance_rect.position + Vector2(52.0, 34.0), 20, Color(1.0, 0.96, 1.0))
	# Daily challenge button
	var daily_done = daily_challenge_date == _today_string()
	var daily_fill = Color(0.36, 0.64, 0.86) if not daily_done else Color(0.52, 0.56, 0.6)
	_draw_panel_shell(WORLD_SELECT_DAILY_RECT, daily_fill, Color(0.16, 0.32, 0.48), 0.18, 0.1)
	_draw_text("每日挑战" if not daily_done else "已完成", WORLD_SELECT_DAILY_RECT.position + Vector2(48.0, 38.0), 22, Color(1.0, 0.98, 0.94))
	# Update button and status
	_draw_panel_shell(WORLD_SELECT_UPDATE_RECT, _update_badge_fill(), Color(0.18, 0.22, 0.28), 0.18, 0.1)
	_draw_text(_update_action_text(), WORLD_SELECT_UPDATE_RECT.position + Vector2(18.0, 38.0), 20, Color(1.0, 0.98, 0.94))
	_draw_panel_shell(WORLD_SELECT_UPDATE_INFO_RECT, Color(0.14, 0.16, 0.2, 0.9), Color(0.34, 0.4, 0.48), 0.12, 0.08)
	_draw_text("自动更新", WORLD_SELECT_UPDATE_INFO_RECT.position + Vector2(16.0, 20.0), 16, Color(0.92, 0.96, 1.0))
	_draw_text(_update_status_line(), WORLD_SELECT_UPDATE_INFO_RECT.position + Vector2(16.0, 40.0), 14, Color(0.84, 0.9, 0.98))
	if update_state == "downloading":
		var bar_rect = Rect2(WORLD_SELECT_UPDATE_INFO_RECT.position + Vector2(250.0, 13.0), Vector2(148.0, 16.0))
		draw_rect(bar_rect, Color(0.08, 0.1, 0.12, 0.82), true)
		draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * clampf(update_download_progress, 0.0, 1.0), bar_rect.size.y)), Color(0.92, 0.66, 0.22, 0.94), true)
		draw_rect(bar_rect, Color(0.94, 0.96, 1.0, 0.24), false, 1.0)
	# Coin display
	_draw_panel_shell(Rect2(1180.0, 808.0, 236.0, 42.0), Color(1.0, 0.92, 0.54), Color(0.55, 0.41, 0.08), 0.1, 0.06)
	_draw_text("金币: %d" % coins_total, Vector2(1204.0, 838.0), 22, Color(0.33, 0.21, 0.04))
	_draw_text("滚轮、触控板或手指左右滑动切换世界", Vector2(76.0, 836.0), 18, Color(0.24, 0.18, 0.08) if not sky_night else Color(0.86, 0.9, 0.98))


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

	_draw_text(_map_mode_title_for_world(current_world_key), Vector2(70.0, 58.0), 36, Color(0.95, 0.95, 0.98) if is_night_world else Color(0.23, 0.15, 0.05))
	_draw_text("点击灯泡进入关卡，超过 10 张植物时先进入选卡。", Vector2(70.0, 90.0), 18, Color(0.88, 0.9, 0.96) if is_night_world else Color(0.26, 0.18, 0.08))
	_draw_text("世界地图", control_rect.position + Vector2(16.0, 24.0), 18, Color(0.22, 0.16, 0.08) if not is_night_world else Color(0.9, 0.94, 1.0))
	_draw_panel_shell(MAP_SCROLL_LEFT_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.08, 0.04)
	_draw_panel_shell(MAP_SCROLL_RIGHT_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.08, 0.04)
	draw_polyline(PackedVector2Array([MAP_SCROLL_LEFT_RECT.get_center() + Vector2(8.0, -10.0), MAP_SCROLL_LEFT_RECT.get_center() + Vector2(-6.0, 0.0), MAP_SCROLL_LEFT_RECT.get_center() + Vector2(8.0, 10.0)]), Color(0.28, 0.18, 0.08), 4.0)
	draw_polyline(PackedVector2Array([MAP_SCROLL_RIGHT_RECT.get_center() + Vector2(-8.0, -10.0), MAP_SCROLL_RIGHT_RECT.get_center() + Vector2(6.0, 0.0), MAP_SCROLL_RIGHT_RECT.get_center() + Vector2(-8.0, 10.0)]), Color(0.28, 0.18, 0.08), 4.0)
	var scroll_hint = "左右拖动地图或点箭头查看右侧支线" if _map_scroll_bounds_for_world(current_world_key).y > 0.0 else "当前世界地图已完整显示"
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
	var terrain_key = String(level.get("terrain", ""))
	if terrain_key == "blood_moon":
		halo_color = Color(1.0, 0.18, 0.26, 0.18 + 0.14 * pulse) if unlocked else Color(0.0, 0.0, 0.0, 0.0)
		bulb_color = Color(0.84, 0.08, 0.16) if unlocked else Color(0.42, 0.36, 0.4)
		outline = Color(0.28, 0.02, 0.04) if unlocked else Color(0.2, 0.18, 0.2)
	elif terrain_key == "blood_library":
		halo_color = Color(0.92, 0.14, 0.22, 0.22 + 0.14 * pulse) if unlocked else Color(0.0, 0.0, 0.0, 0.0)
		bulb_color = Color(0.66, 0.22, 0.34) if unlocked else Color(0.42, 0.36, 0.4)
		outline = Color(0.24, 0.0, 0.08) if unlocked else Color(0.2, 0.18, 0.2)

	if unlocked:
		draw_circle(node_pos, 44.0 + 5.0 * pulse + hover_boost * 6.0, Color(halo_color.r, halo_color.g, halo_color.b, halo_color.a * 0.4))
		draw_circle(node_pos, 36.0 + 4.0 * pulse + hover_boost * 4.0, halo_color)
		if hovered:
			draw_circle(node_pos, 50.0 + 4.0 * sin(map_time * 6.0), Color(1.0, 0.98, 0.72, 0.12), false, 3.0)
			draw_circle(node_pos, 54.0 + 3.0 * sin(map_time * 4.0), Color(1.0, 0.98, 0.72, 0.05), false, 2.0)
	# Shadow
	draw_circle(node_pos + Vector2(0.0, 8.0), 26.0, Color(0.12, 0.12, 0.14, 0.28))
	# Base/pedestal
	draw_circle(node_pos + Vector2(0.0, 6.0), 23.0, Color(0.44, 0.44, 0.48))
	draw_circle(node_pos + Vector2(0.0, 6.0), 20.0, Color(0.52, 0.52, 0.56))
	draw_rect(Rect2(node_pos + Vector2(-12.0, 18.0), Vector2(24.0, 10.0)), Color(0.48, 0.48, 0.52), true)
	# Main bulb
	draw_circle(node_pos, 28.0 + hover_boost * 2.0, bulb_color)
	# Bulb gradient highlight
	draw_circle(node_pos + Vector2(-8.0, -10.0), 10.0, Color(1.0, 1.0, 1.0, 0.36))
	draw_circle(node_pos + Vector2(-6.0, -8.0), 5.0, Color(1.0, 1.0, 1.0, 0.5))
	draw_circle(node_pos + Vector2(10.0, 10.0), 4.0, Color(1.0, 1.0, 1.0, 0.16))
	# Outline
	draw_circle(node_pos, 28.0, outline, false, 2.5)
	_draw_text(str(world_order), node_pos + Vector2(-8.0, 7.0), 24, Color(0.19, 0.19, 0.2))
	_draw_text(String(level["id"]), node_pos + Vector2(-22.0, -42.0), 16, Color(0.25, 0.18, 0.08))
	if terrain_key == "blood_moon" or terrain_key == "blood_library":
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
	_ensure_selection_scene_ready()
	_draw_world_sky(false)
	draw_rect(Rect2(Vector2(0.0, 148.0), Vector2(size.x, size.y - 148.0)), Color(0.68, 0.82, 0.5), true)
	draw_rect(Rect2(Vector2(0.0, 610.0), Vector2(size.x, 110.0)), Color(0.58, 0.42, 0.24), true)
	draw_rect(Rect2(Vector2(0.0, 148.0), Vector2(size.x, 44.0)), Color(1.0, 1.0, 1.0, 0.06), true)
	draw_rect(Rect2(Vector2(0.0, 566.0), Vector2(size.x, 30.0)), Color(0.0, 0.0, 0.0, 0.08), true)
	_draw_panel_shell(Rect2(Vector2(44.0, 182.0), Vector2(214.0, 392.0)), Color(0.86, 0.78, 0.58), Color(0.54, 0.38, 0.18))
	_draw_panel_shell(Rect2(Vector2(66.0, 238.0), Vector2(170.0, 164.0)), Color(0.93, 0.88, 0.74), Color(0.58, 0.42, 0.2), 0.12, 0.08)
	draw_rect(Rect2(Vector2(96.0, 192.0), Vector2(110.0, 62.0)), Color(0.79, 0.28, 0.21), true)
	var selected_panel_rect = _selection_selected_panel_rect()
	var zombie_panel_rect = _selection_zombie_panel_rect()
	var pool_panel_rect = _selection_pool_panel_rect()
	var footer_rect = _selection_footer_rect()
	var back_rect = _selection_back_rect()
	var start_rect = _selection_start_rect()

	_draw_panel_shell(selected_panel_rect, Color(0.95, 0.9, 0.76), Color(0.48, 0.35, 0.16), 0.14, 0.08)
	_draw_panel_shell(zombie_panel_rect, Color(0.92, 0.88, 0.8), Color(0.48, 0.35, 0.16), 0.1, 0.05)
	_draw_panel_shell(pool_panel_rect, Color(0.95, 0.92, 0.84), Color(0.48, 0.35, 0.16), 0.14, 0.08)
	var required_count = _required_seed_count(current_level)

	_draw_text(String(current_level["title"]), Vector2(122.0, 56.0), 34, Color(0.23, 0.15, 0.05))
	_draw_text("植物超过 10 张时必须先选满 %d 张再开战" % max(required_count, 1), Vector2(122.0, 88.0), 18, Color(0.26, 0.18, 0.08))
	_draw_text_block(String(current_level["description"]), Rect2(Vector2(122.0, 98.0), Vector2(820.0, 44.0)), 16, Color(0.32, 0.24, 0.1), 3.0, 2)
	_draw_text("已选 %d/10" % selection_cards.size(), selected_panel_rect.position + Vector2(20.0, 30.0), 24, Color(0.2, 0.32, 0.08))
	_draw_text("本关僵尸", zombie_panel_rect.position + Vector2(18.0, 32.0), 18, Color(0.24, 0.16, 0.06))
	_draw_text("可选植物", pool_panel_rect.position + Vector2(18.0, 30.0), 22, Color(0.24, 0.16, 0.06))
	_draw_text("点选下方卡牌加入上方卡槽，选满后右下角按钮高亮。", selected_panel_rect.position + Vector2(188.0, 28.0), 16, Color(0.28, 0.22, 0.1))
	var selection_progress_rect = Rect2(selected_panel_rect.position + Vector2(18.0, 90.0), Vector2(selected_panel_rect.size.x - 36.0, 18.0))
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
		var chip_rect = Rect2(zombie_panel_rect.position + Vector2(126.0 + i * 138.0, 8.0), Vector2(124.0, 34.0))
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
		pool_panel_rect.position + Vector2(10.0, 38.0),
		Vector2(pool_panel_rect.size.x - 14.0, footer_rect.position.y - pool_panel_rect.position.y - 30.0)
	)
	_draw_scroll_mask(pool_content_rect, pool_view_rect, Color(0.95, 0.92, 0.84), Color(0.58, 0.46, 0.24))
	_draw_panel_shell(footer_rect, Color(0.88, 0.84, 0.76, 0.9), Color(0.42, 0.3, 0.14), 0.06, 0.04)
	_draw_text("选满后即可开始", footer_rect.position + Vector2(18.0, 26.0), 16, Color(0.28, 0.2, 0.08))

	var track_rect = _selection_pool_track_rect()
	_draw_panel_shell(track_rect, Color(0.84, 0.8, 0.72), Color(0.42, 0.3, 0.14), 0.05, 0.03)
	var max_scroll = _selection_pool_max_scroll()
	var knob_rect = ThemeLib.scroll_knob_rect(track_rect, _selection_pool_view_rect().size.y, _selection_pool_content_height(), selection_pool_scroll)
	_draw_panel_shell(knob_rect, Color(0.58, 0.74, 0.3), Color(0.24, 0.36, 0.12), 0.04, 0.03)
	if max_scroll > 0.0:
		_draw_text("滚动查看", pool_panel_rect.position + Vector2(pool_panel_rect.size.x - 94.0, 30.0), 14, Color(0.24, 0.16, 0.06))

	var back_color = Color(0.88, 0.84, 0.76)
	var start_color = Color(0.42, 0.76, 0.24) if selection_cards.size() >= required_count else Color(0.62, 0.62, 0.62)
	_draw_panel_shell(back_rect, back_color, Color(0.42, 0.3, 0.14), 0.08, 0.04)
	_draw_panel_shell(start_rect, start_color, Color(0.22, 0.36, 0.12), 0.08, 0.04)
	_draw_text("返回地图", back_rect.position + Vector2(18.0, 28.0), 18, Color(0.26, 0.18, 0.08))
	_draw_text("开始战斗", start_rect.position + Vector2(24.0, 28.0), 20, Color(0.08, 0.2, 0.04))


func _draw_selection_card(kind: String, rect: Rect2, selected: bool, disabled: bool, allow_hover: bool = true) -> void:
	var mouse_pos = _pointer_local_position()
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
		"peashooter", "snow_pea", "repeater", "amber_shooter", "heather_shooter", "cluster_boomerang", "puff_shroom", "scaredy_shroom", "sun_bean":
			center_offset += Vector2(-10.0 * action_ratio, 0.0)
			scale_x += 0.08 * action_ratio
			sway += 0.06 * action_ratio
		"sunflower", "sun_shroom", "moon_lotus", "healing_gourd", "snow_bloom":
			center_offset += Vector2(0.0, -8.0 * action_ratio)
			scale_x += 0.06 * action_ratio
			scale_y += 0.08 * action_ratio
		"chomper", "grave_buster", "mango_bowling":
			center_offset += Vector2(10.0 * action_ratio, -8.0 * action_ratio)
			sway += 0.08 * action_ratio
		"vine_lasher", "wind_orchid", "root_snare", "leyline":
			center_offset += Vector2(8.0 * action_ratio, -4.0 * action_ratio)
			sway += 0.1 * action_ratio
		"pepper_mortar", "meteor_gourd", "dream_drum":
			center_offset += Vector2(-6.0 * action_ratio, -12.0 * action_ratio)
			scale_y += 0.08 * action_ratio
		"pulse_bulb", "fume_shroom", "ice_shroom", "doom_shroom", "lantern_bloom", "thunder_pine":
			scale_x += 0.1 * action_ratio
			scale_y += 0.1 * action_ratio
		"wallnut", "holo_nut", "glitch_walnut", "cactus_guard", "potato_mine", "prism_grass":
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
	if float(plant.get("push_timer", 0.0)) > 0.0:
		var push_duration = maxf(float(plant.get("push_duration", 0.26)), 0.01)
		var push_ratio = clampf(float(plant["push_timer"]) / push_duration, 0.0, 1.0)
		center_offset.x += float(plant.get("push_offset_x", 0.0)) * push_ratio
		sway += 0.08 * push_ratio
	if float(plant.get("rooted_timer", 0.0)) > 0.0:
		scale_y += 0.03 * sin(level_time * 5.2 + phase)
		center_offset.y += absf(sin(level_time * 5.2 + phase)) * 1.5
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
	_draw_panel_shell(PAUSE_BUTTON_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.1, 0.05)
	_draw_text("暂停", PAUSE_BUTTON_RECT.position + Vector2(24.0, 27.0), 18, Color(0.27, 0.18, 0.08))
	_draw_hover()
	_draw_mowers()
	_draw_lane_obstacles()
	_draw_plants()
	_draw_projectiles()
	_draw_rollers()
	_draw_zombies()
	_draw_city_blizzard_overlay()
	_draw_scarlet_clocktower_overlay()
	_draw_fog_overlay()
	_draw_suns()
	_draw_coins()
	_draw_plant_food_pickups()
	_draw_effects()
	_draw_sakuya_time_stop_overlay()
	_draw_vfx_particles()
	_draw_boss_health_bar()

	if battle_state != BATTLE_PLAYING:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.28), true)
	elif battle_paused:
		_draw_battle_pause_overlay()


func _draw_battle_pause_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.04, 0.46), true)
	var panel_rect = _battle_pause_menu_rect()
	var pulse = 0.48 + 0.52 * sin(ui_time * 2.6)
	var halo_rect = panel_rect.grow(34.0)
	ThemeLib.draw_gradient_rect_v(self, halo_rect, Color(0.14, 0.08, 0.02, 0.02), Color(0.0, 0.0, 0.0, 0.0))
	draw_rect(halo_rect, Color(0.0, 0.0, 0.0, 0.04 + pulse * 0.04), false, 2.0)
	_draw_panel_shell(panel_rect, Color(0.88, 0.76, 0.48, 0.96), Color(0.4, 0.24, 0.08), 0.2, 0.12)
	var title_rect = Rect2(panel_rect.position + Vector2(46.0, 28.0), Vector2(panel_rect.size.x - 92.0, 54.0))
	_draw_panel_shell(title_rect, Color(0.5, 0.28, 0.08, 0.92), Color(0.28, 0.14, 0.04), 0.1, 0.06)
	_draw_text("游戏暂停", title_rect.position + Vector2(86.0, 34.0), 28, Color(1.0, 0.96, 0.9))
	_draw_text("查看图鉴、重新布阵，或者直接返回地图。", panel_rect.position + Vector2(54.0, 104.0), 18, Color(0.32, 0.2, 0.08))
	var button_specs = [
		{"action": "resume", "label": "继续游戏", "fill": Color(0.5, 0.72, 0.32, 0.96), "border": Color(0.22, 0.36, 0.12)},
		{"action": "restart", "label": "重新开始", "fill": Color(0.9, 0.66, 0.22, 0.96), "border": Color(0.52, 0.32, 0.08)},
		{"action": "almanac", "label": "查看图鉴", "fill": Color(0.76, 0.62, 0.32, 0.96), "border": Color(0.42, 0.28, 0.1)},
		{"action": "map", "label": "返回地图", "fill": Color(0.74, 0.42, 0.24, 0.96), "border": Color(0.42, 0.18, 0.08)},
	]
	for spec_variant in button_specs:
		var spec = Dictionary(spec_variant)
		var button_rect = _battle_pause_button_rect(String(spec.get("action", "")))
		_draw_panel_shell(button_rect, Color(spec.get("fill", Color(0.92, 0.88, 0.78))), Color(spec.get("border", Color(0.42, 0.3, 0.14))), 0.16, 0.08)
		_draw_text(String(spec.get("label", "")), button_rect.position + Vector2(78.0, 34.0), 22, Color(0.96, 0.96, 0.92))


func _draw_battle_background() -> void:
	if _is_blood_moon_level():
		# Blood moon sky gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 156.0)), Color(0.12, 0.0, 0.02), Color(0.3, 0.02, 0.06))
		# Blood moon with glow
		ThemeLib.draw_glow_circle(self, Vector2(112.0, 72.0), 38.0, Color(0.92, 0.08, 0.12), 5)
		draw_circle(Vector2(126.0, 68.0), 36.0, Color(0.1, 0.0, 0.02))
		# Dark clouds
		for cloud_index in range(4):
			var drift = fmod(ui_time * (5.0 + cloud_index * 1.4), 240.0)
			var cloud_pos = Vector2(240.0 + float(cloud_index) * 270.0 + drift, 46.0 + float(cloud_index % 2) * 26.0)
			draw_circle(cloud_pos, 24.0, Color(0.26, 0.04, 0.08, 0.5))
			draw_circle(cloud_pos + Vector2(20.0, 6.0), 18.0, Color(0.36, 0.04, 0.1, 0.54))
			draw_circle(cloud_pos + Vector2(-18.0, 7.0), 16.0, Color(0.16, 0.02, 0.06, 0.48))
			draw_circle(cloud_pos + Vector2(8.0, -6.0), 14.0, Color(0.22, 0.02, 0.06, 0.4))
		# Ground gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.34, 0.04, 0.06), Color(0.22, 0.02, 0.04))
		# Hills
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 184.0), Vector2(180.0, 154.0), Vector2(362.0, 204.0),
				Vector2(616.0, 160.0), Vector2(852.0, 214.0), Vector2(1110.0, 170.0),
				Vector2(size.x, 208.0), Vector2(size.x, 238.0), Vector2(0.0, 238.0),
			]),
			PackedColorArray([
				Color(0.2, 0.02, 0.04), Color(0.22, 0.02, 0.04), Color(0.18, 0.01, 0.03),
				Color(0.22, 0.02, 0.04), Color(0.18, 0.01, 0.03), Color(0.2, 0.02, 0.04),
				Color(0.18, 0.01, 0.03), Color(0.16, 0.01, 0.02), Color(0.16, 0.01, 0.02),
			])
		)
		# House gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(28.0, 118.0), Vector2(160.0, size.y - 118.0)), Color(0.52, 0.1, 0.08), Color(0.42, 0.06, 0.06))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(46.0, 164.0), Vector2(124.0, 144.0)), Color(0.7, 0.2, 0.16), Color(0.6, 0.14, 0.12))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(68.0, 122.0), Vector2(80.0, 56.0)), Color(0.38, 0.04, 0.06), Color(0.3, 0.02, 0.04))
		# Eerie window glow
		draw_rect(Rect2(Vector2(78.0, 136.0), Vector2(22.0, 18.0)), Color(1.0, 0.3, 0.2, 0.4), true)
		draw_rect(Rect2(Vector2(116.0, 136.0), Vector2(22.0, 18.0)), Color(1.0, 0.3, 0.2, 0.4), true)
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.34, 0.06, 0.04), Color(0.28, 0.04, 0.04))
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.42, 0.12, 0.1), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.24, 0.04, 0.06), true)
		# Red light bands
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 22.0, BOARD_ORIGIN.y + 18.0), Vector2(board_size.x + 96.0, 96.0)), Color(1.0, 0.18, 0.24, 0.04), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 34.0, BOARD_ORIGIN.y + 232.0), Vector2(board_size.x + 116.0, 84.0)), Color(0.0, 0.0, 0.0, 0.08), true)
	elif _is_blood_library_level():
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 160.0)), Color(0.12, 0.02, 0.08), Color(0.36, 0.06, 0.12))
		ThemeLib.draw_glow_circle(self, Vector2(120.0, 70.0), 30.0, Color(0.92, 0.18, 0.22), 4)
		draw_circle(Vector2(134.0, 64.0), 28.0, Color(0.16, 0.02, 0.08))
		for shelf_index in range(6):
			var shelf_x = 218.0 + float(shelf_index) * 176.0
			var shelf_rect = Rect2(Vector2(shelf_x, 82.0), Vector2(112.0, 118.0))
			ThemeLib.draw_gradient_rect_v(self, shelf_rect, Color(0.34, 0.08, 0.1), Color(0.2, 0.04, 0.06))
			for row_index in range(3):
				var row_y = shelf_rect.position.y + 18.0 + row_index * 32.0
				draw_line(Vector2(shelf_rect.position.x + 8.0, row_y), Vector2(shelf_rect.position.x + shelf_rect.size.x - 8.0, row_y), Color(0.62, 0.18, 0.14, 0.4), 2.0)
				for book_index in range(6):
					var book_x = shelf_rect.position.x + 10.0 + book_index * 16.0
					var book_h = 18.0 + float((book_index + row_index + shelf_index) % 3) * 4.0
					draw_rect(Rect2(Vector2(book_x, row_y - book_h), Vector2(10.0, book_h)), Color(0.46 + 0.06 * float(book_index % 2), 0.12 + 0.04 * float(row_index % 2), 0.18 + 0.1 * float(book_index % 3), 0.92), true)
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.22, 0.04, 0.08), Color(0.12, 0.02, 0.04))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(24.0, 118.0), Vector2(184.0, size.y - 118.0)), Color(0.44, 0.08, 0.12), Color(0.3, 0.04, 0.08))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(48.0, 164.0), Vector2(136.0, 148.0)), Color(0.56, 0.12, 0.16), Color(0.42, 0.08, 0.12))
		draw_rect(Rect2(Vector2(76.0, 132.0), Vector2(84.0, 54.0)), Color(0.18, 0.02, 0.08), true)
		draw_rect(Rect2(Vector2(88.0, 144.0), Vector2(20.0, 16.0)), Color(0.92, 0.22, 0.28, 0.42), true)
		draw_rect(Rect2(Vector2(124.0, 144.0), Vector2(20.0, 16.0)), Color(0.82, 0.38, 0.92, 0.34), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.46, 0.08, 0.12), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.18, 0.02, 0.08), true)
		for candle_index in range(4):
			var candle_x = BOARD_ORIGIN.x + 40.0 + float(candle_index) * 210.0
			var candle_y = BOARD_ORIGIN.y - 18.0 + sin(ui_time * 2.4 + float(candle_index)) * 2.0
			draw_rect(Rect2(Vector2(candle_x, candle_y), Vector2(4.0, 14.0)), Color(0.82, 0.74, 0.62, 0.8), true)
			draw_circle(Vector2(candle_x + 2.0, candle_y - 3.0), 5.0, Color(1.0, 0.56, 0.22, 0.26))
			draw_circle(Vector2(candle_x + 2.0, candle_y - 5.0), 2.4, Color(1.0, 0.84, 0.42, 0.76))
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 22.0, BOARD_ORIGIN.y + 24.0), Vector2(board_size.x + 96.0, 92.0)), Color(0.9, 0.16, 0.22, 0.04), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 30.0, BOARD_ORIGIN.y + 230.0), Vector2(board_size.x + 108.0, 88.0)), Color(0.12, 0.0, 0.04, 0.1), true)
		ThemeLib.draw_ambient_particles(self, size, ui_time, "dust_motes", 12)
	elif _is_scarlet_clocktower_level():
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 162.0)), Color(0.08, 0.02, 0.06), Color(0.22, 0.04, 0.1))
		for star_index in range(8):
			var glow_pos = Vector2(260.0 + float(star_index) * 138.0, 34.0 + float(star_index % 3) * 24.0)
			draw_circle(glow_pos, 1.5 + float(star_index % 2), Color(1.0, 0.92, 0.86, 0.28))
		for pillar_index in range(5):
			var pillar_x = 232.0 + float(pillar_index) * 198.0
			ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(pillar_x, 80.0), Vector2(30.0, size.y - 80.0)), Color(0.26, 0.08, 0.1), Color(0.14, 0.04, 0.06))
			draw_rect(Rect2(Vector2(pillar_x - 8.0, 74.0), Vector2(46.0, 10.0)), Color(0.62, 0.14, 0.18, 0.84), true)
		var clock_center = Vector2(size.x - 144.0, 114.0)
		draw_circle(clock_center, 72.0, Color(0.14, 0.04, 0.08, 0.9))
		draw_circle(clock_center, 62.0, Color(0.88, 0.82, 0.74, 0.12))
		for tick_index in range(12):
			var tick_angle = -PI * 0.5 + TAU * float(tick_index) / 12.0
			var tick_from = clock_center + Vector2(cos(tick_angle), sin(tick_angle)) * 46.0
			var tick_to = clock_center + Vector2(cos(tick_angle), sin(tick_angle)) * 58.0
			draw_line(tick_from, tick_to, Color(0.96, 0.88, 0.76, 0.46), 2.0)
		draw_line(clock_center, clock_center + Vector2(cos(ui_time * 0.7 - PI * 0.5), sin(ui_time * 0.7 - PI * 0.5)) * 28.0, Color(0.92, 0.9, 0.86, 0.82), 3.0)
		draw_line(clock_center, clock_center + Vector2(cos(ui_time * 1.8 - PI * 0.5), sin(ui_time * 1.8 - PI * 0.5)) * 42.0, Color(0.82, 0.88, 1.0, 0.76), 2.0)
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.18, 0.04, 0.08), Color(0.08, 0.02, 0.04))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(22.0, 118.0), Vector2(186.0, size.y - 118.0)), Color(0.38, 0.08, 0.12), Color(0.22, 0.04, 0.08))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(46.0, 164.0), Vector2(140.0, 150.0)), Color(0.52, 0.12, 0.16), Color(0.34, 0.06, 0.1))
		draw_rect(Rect2(Vector2(66.0, 126.0), Vector2(96.0, 58.0)), Color(0.16, 0.02, 0.06), true)
		for window_index in range(3):
			draw_rect(Rect2(Vector2(78.0 + window_index * 24.0, 140.0), Vector2(16.0, 18.0)), Color(0.98, 0.28, 0.22, 0.34), true)
		var stair_origin = Vector2(BOARD_ORIGIN.x - 46.0, BOARD_ORIGIN.y + board_size.y - 28.0)
		for step_index in range(8):
			var step_rect = Rect2(stair_origin + Vector2(step_index * 22.0, -step_index * 16.0), Vector2(70.0, 18.0))
			draw_rect(step_rect, Color(0.24, 0.08, 0.08, 0.9), true)
			draw_rect(step_rect, Color(0.6, 0.16, 0.18, 0.3), false, 1.5)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 40.0, BOARD_ORIGIN.y), Vector2(30.0, board_size.y)), Color(0.34, 0.08, 0.1), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(84.0, board_size.y)), Color(0.14, 0.02, 0.06), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 24.0, BOARD_ORIGIN.y + 22.0), Vector2(board_size.x + 98.0, 86.0)), Color(0.92, 0.18, 0.22, 0.04), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 32.0, BOARD_ORIGIN.y + 224.0), Vector2(board_size.x + 112.0, 84.0)), Color(0.0, 0.0, 0.0, 0.08), true)
		ThemeLib.draw_ambient_particles(self, size, ui_time, "dust_motes", 10)
	elif _is_frozen_branch_level():
		# Icy sky gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 154.0)), Color(0.68, 0.84, 1.0), Color(0.88, 0.95, 1.0))
		# Pale sun with icy glow
		ThemeLib.draw_glow_circle(self, Vector2(112.0, 74.0), 32.0, Color(0.96, 0.98, 1.0), 4)
		# Clouds
		for cloud_index in range(5):
			var drift = fmod(ui_time * (6.0 + cloud_index * 1.2), 260.0)
			var cloud_pos = Vector2(220.0 + float(cloud_index) * 232.0 + drift, 42.0 + float(cloud_index % 3) * 22.0)
			draw_circle(cloud_pos + Vector2(2.0, 3.0), 24.0, Color(0.0, 0.0, 0.0, 0.015))
			draw_circle(cloud_pos, 24.0, Color(1.0, 1.0, 1.0, 0.5))
			draw_circle(cloud_pos + Vector2(18.0, 5.0), 18.0, Color(1.0, 1.0, 1.0, 0.58))
			draw_circle(cloud_pos + Vector2(-16.0, 6.0), 16.0, Color(0.92, 0.98, 1.0, 0.4))
		# Ground gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.68, 0.8, 0.62), Color(0.56, 0.7, 0.52))
		# Hills
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 180.0), Vector2(164.0, 150.0), Vector2(340.0, 196.0),
				Vector2(602.0, 156.0), Vector2(858.0, 212.0), Vector2(1098.0, 170.0),
				Vector2(size.x, 204.0), Vector2(size.x, 236.0), Vector2(0.0, 236.0),
			]),
			PackedColorArray([
				Color(0.52, 0.66, 0.5), Color(0.54, 0.68, 0.52), Color(0.5, 0.64, 0.48),
				Color(0.54, 0.68, 0.52), Color(0.48, 0.62, 0.46), Color(0.52, 0.66, 0.5),
				Color(0.48, 0.62, 0.46), Color(0.46, 0.6, 0.44), Color(0.46, 0.6, 0.44),
			])
		)
		# House gradient (frosty)
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(28.0, 118.0), Vector2(166.0, size.y - 118.0)), Color(0.9, 0.94, 0.92), Color(0.84, 0.88, 0.86))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(46.0, 164.0), Vector2(128.0, 146.0)), Color(0.96, 0.98, 0.97), Color(0.92, 0.94, 0.93))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(68.0, 124.0), Vector2(84.0, 54.0)), Color(0.56, 0.74, 0.86), Color(0.46, 0.66, 0.78))
		# Windows
		draw_rect(Rect2(Vector2(78.0, 138.0), Vector2(22.0, 18.0)), Color(0.86, 0.94, 1.0, 0.5), true)
		draw_rect(Rect2(Vector2(116.0, 138.0), Vector2(22.0, 18.0)), Color(0.86, 0.94, 1.0, 0.5), true)
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.8, 0.86, 0.86), Color(0.72, 0.78, 0.78))
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.66, 0.74, 0.74), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.58, 0.7, 0.62), true)
		# Frozen zone overlay
		var frozen_left = Rect2(Vector2(BOARD_ORIGIN.x - 14.0, BOARD_ORIGIN.y - 8.0), Vector2(CELL_SIZE.x * 5.0 + 24.0, board_size.y + 16.0))
		draw_rect(frozen_left, Color(0.68, 0.88, 1.0, 0.1), true)
		draw_rect(Rect2(frozen_left.position + Vector2(0.0, 12.0), Vector2(frozen_left.size.x, frozen_left.size.y * 0.3)), Color(1.0, 1.0, 1.0, 0.04), true)
		# Snowflakes
		ThemeLib.draw_ambient_particles(self, size, ui_time, "snowflakes", 20)
	elif _is_city_level():
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 166.0)), Color(0.08, 0.12, 0.22), Color(0.18, 0.3, 0.46))
		for star_index in range(18):
			var star_pos = Vector2(220.0 + float(star_index) * 52.0, 28.0 + float(star_index % 5) * 18.0)
			draw_circle(star_pos + Vector2(0.0, sin(ui_time * 1.6 + float(star_index)) * 2.0), 1.4, Color(0.8, 0.94, 1.0, 0.46))
		var skyline_base = 182.0
		for tower_index in range(12):
			var tower_x = 210.0 + float(tower_index) * 82.0
			var tower_w = 44.0 + float((tower_index % 3) * 10)
			var tower_h = 54.0 + float((tower_index * 37) % 88)
			var tower_rect = Rect2(Vector2(tower_x, skyline_base - tower_h), Vector2(tower_w, tower_h))
			ThemeLib.draw_gradient_rect_v(self, tower_rect, Color(0.12, 0.18, 0.28), Color(0.06, 0.08, 0.14))
			for win_row in range(int(max(2.0, floor(tower_h / 18.0)))):
				for win_col in range(int(max(1.0, floor(tower_w / 14.0)))):
					if (win_row + win_col + tower_index) % 3 == 0:
						continue
					var glow = 0.18 + 0.12 * sin(ui_time * 2.2 + float(win_row) * 0.7 + float(win_col) + float(tower_index))
					draw_rect(
						Rect2(tower_rect.position + Vector2(8.0 + win_col * 12.0, 8.0 + win_row * 14.0), Vector2(5.0, 7.0)),
						Color(0.72, 0.96, 1.0, glow),
						true
					)
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.2, 0.28, 0.24), Color(0.14, 0.18, 0.16))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(24.0, 118.0), Vector2(176.0, size.y - 118.0)), Color(0.34, 0.38, 0.44), Color(0.24, 0.26, 0.32))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(44.0, 164.0), Vector2(136.0, 150.0)), Color(0.48, 0.54, 0.62), Color(0.36, 0.4, 0.48))
		draw_rect(Rect2(Vector2(68.0, 124.0), Vector2(92.0, 58.0)), Color(0.1, 0.18, 0.24), true)
		draw_rect(Rect2(Vector2(80.0, 136.0), Vector2(22.0, 18.0)), Color(0.62, 0.96, 1.0, 0.42), true)
		draw_rect(Rect2(Vector2(120.0, 136.0), Vector2(22.0, 18.0)), Color(0.96, 0.56, 0.26, 0.36), true)
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(190.0, 118.0), Vector2(46.0, size.y - 118.0)), Color(0.28, 0.32, 0.38), Color(0.2, 0.22, 0.28))
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 40.0, BOARD_ORIGIN.y), Vector2(30.0, board_size.y)), Color(0.22, 0.24, 0.28), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(88.0, board_size.y)), Color(0.18, 0.22, 0.26), true)
		var neon_band = Rect2(Vector2(BOARD_ORIGIN.x - 28.0, BOARD_ORIGIN.y + 22.0), Vector2(board_size.x + 102.0, 86.0))
		draw_rect(neon_band, Color(0.22, 0.72, 1.0, 0.04), true)
		draw_rect(Rect2(neon_band.position + Vector2(0.0, 188.0), Vector2(neon_band.size.x, 80.0)), Color(0.98, 0.42, 0.22, 0.035), true)
		for rail_glow in range(4):
			var glow_y = BOARD_ORIGIN.y + 52.0 + rail_glow * 110.0
			draw_line(Vector2(BOARD_ORIGIN.x - 18.0, glow_y), Vector2(BOARD_ORIGIN.x + board_size.x + 60.0, glow_y), Color(0.66, 0.94, 1.0, 0.045), 2.0)
		for manhole_index in range(3):
			var cover_center = Vector2(BOARD_ORIGIN.x + 66.0 + manhole_index * 72.0, BOARD_ORIGIN.y + board_size.y + 38.0)
			draw_circle(cover_center, 18.0, Color(0.24, 0.28, 0.3, 0.7))
			draw_circle(cover_center, 12.0, Color(0.12, 0.16, 0.18, 0.78))
	elif _is_roof_level():
		# Sky gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 152.0)), Color(0.6, 0.8, 1.0), Color(0.92, 0.96, 1.0))
		# Sun with glow
		ThemeLib.draw_glow_circle(self, Vector2(114.0, 72.0), 32.0, Color(1.0, 0.92, 0.54), 4)
		for ray_i in range(8):
			var angle = TAU * float(ray_i) / 8.0 + ui_time * 0.1
			var ray_from = Vector2(114.0, 72.0) + Vector2(cos(angle), sin(angle)) * 38.0
			var ray_to = Vector2(114.0, 72.0) + Vector2(cos(angle), sin(angle)) * (50.0 + sin(ui_time * 1.2 + float(ray_i)) * 4.0)
			draw_line(ray_from, ray_to, Color(1.0, 0.92, 0.54, 0.1), 2.0)
		# Clouds
		for cloud_index in range(4):
			var drift = fmod(ui_time * (6.0 + cloud_index * 1.4), 240.0)
			var cloud_pos = Vector2(240.0 + float(cloud_index) * 238.0 + drift, 48.0 + float(cloud_index % 2) * 22.0)
			draw_circle(cloud_pos + Vector2(2.0, 3.0), 24.0, Color(0.0, 0.0, 0.0, 0.02))
			draw_circle(cloud_pos, 24.0, Color(1.0, 1.0, 1.0, 0.52))
			draw_circle(cloud_pos + Vector2(20.0, 6.0), 18.0, Color(1.0, 1.0, 1.0, 0.58))
			draw_circle(cloud_pos + Vector2(-16.0, 6.0), 16.0, Color(1.0, 1.0, 1.0, 0.44))
		# Ground
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.7, 0.76, 0.62), Color(0.58, 0.64, 0.5))
		# House wall gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(24.0, 118.0), Vector2(190.0, size.y - 118.0)), Color(0.92, 0.84, 0.68), Color(0.84, 0.76, 0.58))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(44.0, 164.0), Vector2(146.0, 160.0)), Color(0.98, 0.92, 0.8), Color(0.92, 0.86, 0.72))
		# Roof with gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(70.0, 124.0), Vector2(94.0, 58.0)), Color(0.78, 0.32, 0.26), Color(0.66, 0.24, 0.18))
		# Chimney
		draw_rect(Rect2(Vector2(138.0, 110.0), Vector2(16.0, 22.0)), Color(0.68, 0.28, 0.2), true)
		draw_rect(Rect2(Vector2(136.0, 108.0), Vector2(20.0, 4.0)), Color(0.58, 0.22, 0.16), true)
		# Windows
		draw_rect(Rect2(Vector2(80.0, 138.0), Vector2(22.0, 18.0)), Color(1.0, 0.94, 0.62, 0.6), true)
		draw_rect(Rect2(Vector2(122.0, 138.0), Vector2(22.0, 18.0)), Color(1.0, 0.94, 0.62, 0.6), true)
		draw_rect(Rect2(Vector2(80.0, 138.0), Vector2(22.0, 18.0)), Color(0.52, 0.34, 0.16), false, 1.5)
		draw_rect(Rect2(Vector2(122.0, 138.0), Vector2(22.0, 18.0)), Color(0.52, 0.34, 0.16), false, 1.5)
		# Side wall
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(210.0, 118.0), Vector2(36.0, size.y - 118.0)), Color(0.8, 0.68, 0.58), Color(0.72, 0.6, 0.48))
		# Roof surface with gradient shingles
		var roof_rect = Rect2(Vector2(BOARD_ORIGIN.x - 30.0, BOARD_ORIGIN.y - 18.0), Vector2(board_size.x + 96.0, board_size.y + 36.0))
		draw_polygon(
			PackedVector2Array([
				roof_rect.position + Vector2(0.0, 36.0),
				roof_rect.position + Vector2(roof_rect.size.x * 0.18, 0.0),
				roof_rect.position + Vector2(roof_rect.size.x * 0.46, 54.0),
				roof_rect.position + Vector2(roof_rect.size.x * 0.76, 6.0),
				roof_rect.position + Vector2(roof_rect.size.x, 44.0),
				roof_rect.position + Vector2(roof_rect.size.x, roof_rect.size.y),
				roof_rect.position + Vector2(0.0, roof_rect.size.y),
			]),
			PackedColorArray([
				Color(0.66, 0.3, 0.2), Color(0.68, 0.32, 0.22), Color(0.64, 0.28, 0.18),
				Color(0.68, 0.32, 0.22), Color(0.66, 0.3, 0.2), Color(0.44, 0.18, 0.1), Color(0.42, 0.16, 0.08),
			])
		)
		# Shingle lines with varied alpha
		for shingle in range(14):
			var shingle_x = BOARD_ORIGIN.x - 44.0 + float(shingle) * 74.0
			var shingle_alpha = 0.14 + 0.06 * sin(float(shingle) * 1.3)
			draw_line(Vector2(shingle_x, BOARD_ORIGIN.y - 6.0), Vector2(shingle_x + 38.0, BOARD_ORIGIN.y + board_size.y + 10.0), Color(0.88, 0.64, 0.5, shingle_alpha), 2.5)
		# Horizontal shingle rows
		for row_i in range(6):
			var row_y = BOARD_ORIGIN.y + float(row_i) * (board_size.y / 5.0)
			draw_line(Vector2(BOARD_ORIGIN.x - 28.0, row_y), Vector2(BOARD_ORIGIN.x + board_size.x + 60.0, row_y), Color(0.5, 0.22, 0.14, 0.12), 1.5)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.48, 0.22, 0.12), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.4, 0.16, 0.1), true)
		# Light band
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 26.0, BOARD_ORIGIN.y + 28.0), Vector2(board_size.x + 100.0, 88.0)), Color(1.0, 1.0, 1.0, 0.035), true)
		# Dust motes
		ThemeLib.draw_ambient_particles(self, size, ui_time, "dust_motes", 10)
	elif _is_fog_level():
		var is_storm = _is_storm_fog_level()
		var sky_color = Color(0.14, 0.18, 0.24) if not is_storm else Color(0.1, 0.12, 0.18)
		var ground_color = Color(0.28, 0.36, 0.26) if not is_storm else Color(0.22, 0.28, 0.24)
		# Sky gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 156.0)), sky_color.darkened(0.12), sky_color.lightened(0.06))
		# Moon (obscured by fog)
		draw_circle(Vector2(118.0, 72.0), 38.0, Color(0.86, 0.92, 1.0, 0.12))
		draw_circle(Vector2(118.0, 72.0), 28.0, Color(0.86, 0.92, 1.0, 0.16))
		draw_circle(Vector2(132.0, 66.0), 26.0, sky_color)
		# Ground gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), ground_color.lightened(0.04), ground_color.darkened(0.08))
		# Hills
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 182.0), Vector2(162.0, 150.0), Vector2(336.0, 194.0),
				Vector2(596.0, 156.0), Vector2(860.0, 210.0), Vector2(1092.0, 168.0),
				Vector2(size.x, 198.0), Vector2(size.x, 232.0), Vector2(0.0, 232.0),
			]),
			PackedColorArray([
				Color(0.16, 0.22, 0.18), Color(0.18, 0.24, 0.2), Color(0.14, 0.2, 0.16),
				Color(0.18, 0.24, 0.2), Color(0.14, 0.2, 0.16), Color(0.16, 0.22, 0.18),
				Color(0.14, 0.2, 0.16), Color(0.12, 0.18, 0.14), Color(0.12, 0.18, 0.14),
			])
		)
		# House gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(28.0, 118.0), Vector2(182.0, size.y - 118.0)), Color(0.54, 0.5, 0.44), Color(0.46, 0.42, 0.38))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(44.0, 166.0), Vector2(140.0, 154.0)), Color(0.66, 0.64, 0.66), Color(0.58, 0.56, 0.58))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(66.0, 124.0), Vector2(96.0, 60.0)), Color(0.36, 0.2, 0.2), Color(0.28, 0.14, 0.14))
		# Dim window glow
		draw_rect(Rect2(Vector2(78.0, 138.0), Vector2(22.0, 18.0)), Color(0.8, 0.72, 0.4, 0.3), true)
		draw_rect(Rect2(Vector2(118.0, 138.0), Vector2(22.0, 18.0)), Color(0.8, 0.72, 0.4, 0.3), true)
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(210.0, 118.0), Vector2(34.0, size.y - 118.0)), Color(0.52, 0.48, 0.46), Color(0.44, 0.4, 0.38))
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 40.0, BOARD_ORIGIN.y), Vector2(30.0, board_size.y)), Color(0.34, 0.28, 0.22), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(84.0, board_size.y)), Color(0.28, 0.34, 0.28), true)
		# Pool water (dark/murky)
		var pool_rect = Rect2(Vector2(BOARD_ORIGIN.x - 14.0, BOARD_ORIGIN.y + CELL_SIZE.y * 2.0 - 12.0), Vector2(board_size.x + 28.0, CELL_SIZE.y * 2.0 + 24.0))
		ThemeLib.draw_water_surface(self, pool_rect, ui_time, Color(0.12, 0.3, 0.44), 0.06)
		# Fog wisps
		ThemeLib.draw_ambient_particles(self, size, ui_time, "fog_wisps", 6)
		# Storm lightning flash
		if is_storm and fog_lightning_timer > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.92, 0.98, 1.0, 0.1 + fog_lightning_timer * 0.14), true)
	elif _is_pool_level() or _is_clear_backyard_level():
		# Sky gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 156.0)), Color(0.5, 0.76, 1.0), Color(0.86, 0.96, 1.0))
		# Sun with glow
		ThemeLib.draw_glow_circle(self, Vector2(114.0, 70.0), 36.0, Color(1.0, 0.94, 0.58), 5)
		for ray_i in range(10):
			var angle = TAU * float(ray_i) / 10.0 + ui_time * 0.1
			var ray_from = Vector2(114.0, 70.0) + Vector2(cos(angle), sin(angle)) * 42.0
			var ray_to = Vector2(114.0, 70.0) + Vector2(cos(angle), sin(angle)) * (56.0 + sin(ui_time * 1.3 + float(ray_i)) * 5.0)
			draw_line(ray_from, ray_to, Color(1.0, 0.94, 0.58, 0.1), 2.0)
		# Clouds
		for cloud_index in range(5):
			var drift = fmod(ui_time * (8.0 + cloud_index * 1.6), 280.0)
			var cloud_pos = Vector2(220.0 + float(cloud_index) * 224.0 + drift, 44.0 + float(cloud_index % 3) * 22.0)
			draw_circle(cloud_pos + Vector2(2.0, 4.0), 24.0, Color(0.0, 0.0, 0.0, 0.02))
			draw_circle(cloud_pos, 24.0, Color(1.0, 1.0, 1.0, 0.52))
			draw_circle(cloud_pos + Vector2(20.0, 5.0), 18.0, Color(1.0, 1.0, 1.0, 0.58))
			draw_circle(cloud_pos + Vector2(-16.0, 6.0), 16.0, Color(1.0, 1.0, 1.0, 0.44))
			draw_circle(cloud_pos + Vector2(6.0, -6.0), 14.0, Color(1.0, 1.0, 1.0, 0.36))
		# Ground gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.58, 0.78, 0.46), Color(0.44, 0.64, 0.3))
		# Hills with varied colors
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 178.0), Vector2(170.0, 152.0), Vector2(348.0, 192.0),
				Vector2(592.0, 152.0), Vector2(806.0, 208.0), Vector2(1088.0, 164.0),
				Vector2(size.x, 202.0), Vector2(size.x, 236.0), Vector2(0.0, 236.0),
			]),
			PackedColorArray([
				Color(0.44, 0.66, 0.24), Color(0.48, 0.7, 0.28), Color(0.42, 0.64, 0.22),
				Color(0.48, 0.7, 0.28), Color(0.4, 0.62, 0.2), Color(0.46, 0.68, 0.26),
				Color(0.42, 0.64, 0.22), Color(0.4, 0.6, 0.2), Color(0.38, 0.58, 0.18),
			])
		)
		# House wall gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(28.0, 118.0), Vector2(182.0, size.y - 118.0)), Color(0.92, 0.82, 0.64), Color(0.84, 0.72, 0.52))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(44.0, 166.0), Vector2(140.0, 154.0)), Color(0.96, 0.92, 0.82), Color(0.92, 0.86, 0.74))
		# Siding lines
		for house_line in range(6):
			draw_line(Vector2(46.0, 176.0 + house_line * 22.0), Vector2(182.0, 176.0 + house_line * 22.0), Color(0.8, 0.7, 0.56, 0.35), 1.0)
		# Roof gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(66.0, 124.0), Vector2(96.0, 60.0)), Color(0.84, 0.38, 0.26), Color(0.7, 0.26, 0.18))
		# Windows
		draw_rect(Rect2(Vector2(76.0, 138.0), Vector2(22.0, 18.0)), Color(1.0, 0.94, 0.62, 0.65), true)
		draw_rect(Rect2(Vector2(118.0, 138.0), Vector2(22.0, 18.0)), Color(1.0, 0.94, 0.62, 0.65), true)
		draw_rect(Rect2(Vector2(76.0, 138.0), Vector2(22.0, 18.0)), Color(0.56, 0.38, 0.18), false, 1.5)
		draw_rect(Rect2(Vector2(118.0, 138.0), Vector2(22.0, 18.0)), Color(0.56, 0.38, 0.18), false, 1.5)
		# Side wall
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(210.0, 118.0), Vector2(34.0, size.y - 118.0)), Color(0.84, 0.76, 0.66), Color(0.76, 0.68, 0.56))
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 40.0, BOARD_ORIGIN.y), Vector2(30.0, board_size.y)), Color(0.72, 0.56, 0.36), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(84.0, board_size.y)), Color(0.46, 0.66, 0.48), true)
		# Pool water with improved rendering
		var pool_rect = Rect2(Vector2(BOARD_ORIGIN.x - 14.0, BOARD_ORIGIN.y + CELL_SIZE.y * 2.0 - 12.0), Vector2(board_size.x + 28.0, CELL_SIZE.y * 2.0 + 24.0))
		ThemeLib.draw_water_surface(self, pool_rect, ui_time, Color(0.2, 0.58, 0.86), 0.14)
		# Deck lines
		for deck_line in range(10):
			var deck_x = BOARD_ORIGIN.x - 44.0 + float(deck_line) * 30.0
			draw_line(Vector2(deck_x, BOARD_ORIGIN.y), Vector2(deck_x + 14.0, BOARD_ORIGIN.y + board_size.y), Color(0.54, 0.42, 0.24, 0.18), 2.0)
		# Grass tufts
		ThemeLib.draw_grass_tufts(self, Rect2(Vector2(BOARD_ORIGIN.x + board_size.x + 4.0, BOARD_ORIGIN.y), Vector2(70.0, board_size.y)), ui_time, 6, Color(0.38, 0.58, 0.3))
		ThemeLib.draw_ambient_particles(self, size, ui_time, "leaves", 6)
	elif _is_night_level():
		# Night sky gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 140.0)), Color(0.03, 0.06, 0.14), Color(0.1, 0.16, 0.28))
		# Moon with glow
		ThemeLib.draw_glow_circle(self, Vector2(118.0, 78.0), 34.0, Color(0.92, 0.94, 1.0), 4)
		draw_circle(Vector2(132.0, 70.0), 32.0, Color(0.06, 0.09, 0.18))
		# Stars with twinkle
		for star_index in range(24):
			var star_pos = Vector2(180.0 + float(star_index) * 52.0, 22.0 + float(star_index % 6) * 18.0 + sin(ui_time * 0.7 + float(star_index)) * 3.0)
			var twinkle = 0.5 + 0.5 * sin(ui_time * (1.8 + float(star_index % 3) * 0.5) + float(star_index) * 1.1)
			draw_circle(star_pos, 1.4 + float(star_index % 3) * 0.6, Color(1.0, 1.0, 0.9, twinkle * 0.72))
			if star_index % 6 == 0:
				draw_circle(star_pos, 5.0, Color(1.0, 1.0, 0.9, twinkle * 0.06))
		# Ground gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.2, 0.26, 0.2), Color(0.14, 0.2, 0.16))
		# House wall gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(28.0, 118.0), Vector2(160.0, size.y - 118.0)), Color(0.42, 0.4, 0.42), Color(0.36, 0.34, 0.36))
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(46.0, 164.0), Vector2(124.0, 144.0)), Color(0.56, 0.54, 0.58), Color(0.5, 0.48, 0.52))
		# Roof
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(68.0, 122.0), Vector2(80.0, 56.0)), Color(0.34, 0.18, 0.18), Color(0.26, 0.12, 0.12))
		# Window glow (warm light at night)
		draw_circle(Vector2(89.0, 145.0), 18.0, Color(1.0, 0.86, 0.42, 0.06))
		draw_rect(Rect2(Vector2(78.0, 136.0), Vector2(22.0, 18.0)), Color(1.0, 0.86, 0.42, 0.6), true)
		draw_rect(Rect2(Vector2(116.0, 136.0), Vector2(22.0, 18.0)), Color(1.0, 0.86, 0.42, 0.6), true)
		draw_rect(Rect2(Vector2(78.0, 136.0), Vector2(22.0, 18.0)), Color(0.3, 0.2, 0.1), false, 1.5)
		draw_rect(Rect2(Vector2(116.0, 136.0), Vector2(22.0, 18.0)), Color(0.3, 0.2, 0.1), false, 1.5)
		# Side wall
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.36, 0.34, 0.38), Color(0.3, 0.28, 0.32))
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.34, 0.28, 0.22), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.28, 0.34, 0.28), true)
		# Moonlight bands on lawn
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 24.0, BOARD_ORIGIN.y + 36.0), Vector2(board_size.x + 96.0, 112.0)), Color(0.82, 0.86, 0.96, 0.04), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 40.0, BOARD_ORIGIN.y + 240.0), Vector2(board_size.x + 120.0, 96.0)), Color(0.82, 0.86, 0.96, 0.03), true)
		# Fireflies
		ThemeLib.draw_ambient_particles(self, size, ui_time, "fireflies", 14)
	elif String(current_level.get("terrain", "")) == "scarlet_gate":
		# SDM Gate (红茶馆) — dusk sky with crimson hues
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 162.0)), Color(0.56, 0.12, 0.06), Color(0.88, 0.44, 0.18))
		# Sun low on horizon, tinted red
		ThemeLib.draw_glow_circle(self, Vector2(size.x - 110.0, 118.0), 36.0, Color(1.0, 0.52, 0.18), 5)
		for ray_i in range(12):
			var angle = TAU * float(ray_i) / 12.0 + ui_time * 0.08
			var ray_from = Vector2(size.x - 110.0, 118.0) + Vector2(cos(angle), sin(angle)) * 44.0
			var ray_to = Vector2(size.x - 110.0, 118.0) + Vector2(cos(angle), sin(angle)) * (62.0 + sin(ui_time * 1.2 + float(ray_i)) * 6.0)
			draw_line(ray_from, ray_to, Color(1.0, 0.52, 0.18, 0.12), 2.5)
		# Clouds tinted red-orange
		for cloud_index in range(5):
			var drift = fmod(ui_time * (6.0 + cloud_index * 1.3), 280.0)
			var cloud_pos = Vector2(100.0 + float(cloud_index) * 240.0 + drift, 44.0 + float(cloud_index % 3) * 24.0)
			draw_circle(cloud_pos, 26.0, Color(0.9, 0.42, 0.22, 0.44))
			draw_circle(cloud_pos + Vector2(22.0, 5.0), 20.0, Color(0.88, 0.36, 0.18, 0.5))
			draw_circle(cloud_pos + Vector2(-18.0, 7.0), 18.0, Color(0.86, 0.32, 0.14, 0.4))
		# Ground — dark stone courtyard
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.28, 0.12, 0.08), Color(0.18, 0.06, 0.04))
		# SDM Gate left structure — large red mansion wall
		# Main gate wall
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 116.0), Vector2(228.0, size.y - 116.0)), Color(0.68, 0.14, 0.08), Color(0.52, 0.1, 0.06))
		# Gate arch top
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(32.0, 104.0), Vector2(164.0, 76.0)), Color(0.74, 0.18, 0.1), Color(0.62, 0.12, 0.08))
		# Pagoda roof tier 1 — upswept corners
		draw_polygon(
			PackedVector2Array([
				Vector2(14.0, 104.0), Vector2(108.0, 72.0), Vector2(202.0, 104.0),
				Vector2(214.0, 112.0), Vector2(108.0, 80.0), Vector2(2.0, 112.0),
			]),
			PackedColorArray([
				Color(0.86, 0.26, 0.14), Color(0.92, 0.32, 0.16), Color(0.86, 0.26, 0.14),
				Color(0.72, 0.18, 0.1), Color(0.82, 0.22, 0.12), Color(0.72, 0.18, 0.1),
			])
		)
		# Pagoda roof tier 2
		draw_polygon(
			PackedVector2Array([
				Vector2(36.0, 72.0), Vector2(108.0, 48.0), Vector2(180.0, 72.0),
				Vector2(188.0, 78.0), Vector2(108.0, 54.0), Vector2(28.0, 78.0),
			]),
			PackedColorArray([
				Color(0.82, 0.24, 0.12), Color(0.88, 0.28, 0.14), Color(0.82, 0.24, 0.12),
				Color(0.68, 0.16, 0.09), Color(0.78, 0.2, 0.1), Color(0.68, 0.16, 0.09),
			])
		)
		# Pagoda top spire
		draw_polygon(PackedVector2Array([Vector2(98.0, 48.0), Vector2(108.0, 26.0), Vector2(118.0, 48.0)]),
			PackedColorArray([Color(0.88, 0.3, 0.14), Color(0.96, 0.42, 0.18), Color(0.88, 0.3, 0.14)]))
		draw_circle(Vector2(108.0, 24.0), 4.0, Color(1.0, 0.78, 0.18))
		# Golden trim on gate
		draw_line(Vector2(32.0, 104.0), Vector2(196.0, 104.0), Color(0.96, 0.78, 0.22, 0.7), 2.5)
		draw_line(Vector2(14.0, 112.0), Vector2(202.0, 112.0), Color(0.86, 0.68, 0.18, 0.5), 1.5)
		# Gate opening (dark arch)
		draw_circle(Vector2(108.0, 216.0), 52.0, Color(0.08, 0.02, 0.01))
		draw_rect(Rect2(Vector2(56.0, 216.0), Vector2(104.0, size.y - 216.0)), Color(0.06, 0.01, 0.01), true)
		# Red lanterns hanging from gate
		for lantern_i in range(4):
			var lx = 54.0 + float(lantern_i) * 44.0
			var ly_bob = 158.0 + sin(ui_time * 1.8 + float(lantern_i) * 0.9) * 3.0
			draw_line(Vector2(lx, 112.0), Vector2(lx, ly_bob), Color(0.4, 0.2, 0.1, 0.6), 1.5)
			draw_circle(Vector2(lx, ly_bob + 14.0), 8.0, Color(0.94, 0.14, 0.08, 0.88))
			draw_circle(Vector2(lx, ly_bob + 14.0), 5.0, Color(1.0, 0.4, 0.12, 0.6))
			draw_circle(Vector2(lx, ly_bob + 14.0), 3.0, Color(1.0, 0.82, 0.22, 0.5))
			draw_line(Vector2(lx, ly_bob + 22.0), Vector2(lx, ly_bob + 28.0), Color(0.9, 0.6, 0.16, 0.6), 1.0)
		# Stone pillar left of gate
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(24.0, 112.0), Vector2(22.0, size.y - 112.0)), Color(0.52, 0.22, 0.14), Color(0.42, 0.16, 0.1))
		# Stone pillar right of gate
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(162.0, 112.0), Vector2(22.0, size.y - 112.0)), Color(0.52, 0.22, 0.14), Color(0.42, 0.16, 0.1))
		# Stone courtyard floor — tiled pattern
		for tile_row in range(8):
			var ty = BOARD_ORIGIN.y + tile_row * (board_size.y / 7.0)
			draw_line(Vector2(BOARD_ORIGIN.x - 30.0, ty), Vector2(BOARD_ORIGIN.x + board_size.x + 70.0, ty), Color(0.24, 0.08, 0.05, 0.18), 1.5)
		for tile_col in range(10):
			var tx = BOARD_ORIGIN.x + tile_col * (board_size.x / 9.0)
			draw_line(Vector2(tx, BOARD_ORIGIN.y), Vector2(tx, BOARD_ORIGIN.y + board_size.y), Color(0.24, 0.08, 0.05, 0.12), 1.0)
		# Board border
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.44, 0.16, 0.1), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.32, 0.1, 0.06), true)
		# Crimson light band on board
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 24.0, BOARD_ORIGIN.y + 26.0), Vector2(board_size.x + 96.0, 96.0)), Color(0.88, 0.22, 0.12, 0.04), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 32.0, BOARD_ORIGIN.y + 228.0), Vector2(board_size.x + 108.0, 86.0)), Color(0.0, 0.0, 0.0, 0.07), true)
		# Fallen sakura petals blowing across
		for petal_i in range(18):
			var seed_v = float(petal_i) * 53.7
			var px = fmod(ui_time * (18.0 + fmod(seed_v, 12.0)) + seed_v * 6.9, size.x + 40.0) - 20.0
			var py = fmod(seed_v * 3.8 + sin(ui_time * 1.1 + seed_v) * 28.0, size.y)
			var petal_c = Color(0.96, 0.62, 0.72, 0.18 + 0.06 * sin(ui_time * 1.4 + seed_v))
			draw_circle(Vector2(px, py), 2.5 + fmod(seed_v, 2.0), petal_c)
	else:
		# Sky gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2.ZERO, Vector2(size.x, 140.0)), Color(0.52, 0.78, 1.0), Color(0.86, 0.95, 1.0))
		# Sun with glow and rays
		ThemeLib.draw_glow_circle(self, Vector2(102.0, 74.0), 34.0, Color(1.0, 0.94, 0.56), 5)
		for ray_i in range(10):
			var angle = TAU * float(ray_i) / 10.0 + ui_time * 0.12
			var ray_from = Vector2(102.0, 74.0) + Vector2(cos(angle), sin(angle)) * 40.0
			var ray_to = Vector2(102.0, 74.0) + Vector2(cos(angle), sin(angle)) * (56.0 + sin(ui_time * 1.4 + float(ray_i)) * 5.0)
			draw_line(ray_from, ray_to, Color(1.0, 0.94, 0.56, 0.12), 2.0)
		# Clouds (volumetric)
		for cloud_index in range(5):
			var drift = fmod(ui_time * (7.0 + cloud_index * 1.6), 260.0)
			var cloud_pos = Vector2(240.0 + float(cloud_index) * 220.0 + drift, 48.0 + float(cloud_index % 3) * 22.0)
			draw_circle(cloud_pos + Vector2(2.0, 4.0), 26.0, Color(0.0, 0.0, 0.0, 0.025))
			draw_circle(cloud_pos, 26.0, Color(1.0, 1.0, 1.0, 0.54))
			draw_circle(cloud_pos + Vector2(22.0, 4.0), 20.0, Color(1.0, 1.0, 1.0, 0.58))
			draw_circle(cloud_pos + Vector2(-18.0, 6.0), 18.0, Color(1.0, 1.0, 1.0, 0.48))
			draw_circle(cloud_pos + Vector2(8.0, -8.0), 16.0, Color(1.0, 1.0, 1.0, 0.38))
			draw_circle(cloud_pos + Vector2(-4.0, -4.0), 10.0, Color(1.0, 1.0, 1.0, 0.16))
		# Ground gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(0.0, 118.0), Vector2(size.x, size.y - 118.0)), Color(0.62, 0.78, 0.44), Color(0.48, 0.66, 0.3))
		# Rolling hills with varied colors
		draw_polygon(
			PackedVector2Array([
				Vector2(0.0, 182.0), Vector2(160.0, 150.0), Vector2(336.0, 194.0),
				Vector2(596.0, 156.0), Vector2(860.0, 210.0), Vector2(1092.0, 168.0),
				Vector2(size.x, 198.0), Vector2(size.x, 232.0), Vector2(0.0, 232.0),
			]),
			PackedColorArray([
				Color(0.46, 0.68, 0.28), Color(0.5, 0.72, 0.32), Color(0.44, 0.66, 0.26),
				Color(0.5, 0.72, 0.32), Color(0.42, 0.64, 0.24), Color(0.48, 0.7, 0.3),
				Color(0.44, 0.66, 0.26), Color(0.42, 0.62, 0.24), Color(0.4, 0.6, 0.22),
			])
		)
		# House wall gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(28.0, 118.0), Vector2(160.0, size.y - 118.0)), Color(0.9, 0.82, 0.64), Color(0.82, 0.72, 0.52))
		# House front face
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(46.0, 164.0), Vector2(124.0, 144.0)), Color(0.96, 0.92, 0.8), Color(0.9, 0.84, 0.7))
		# House siding lines
		for house_line in range(6):
			var ly = 174.0 + house_line * 22.0
			draw_line(Vector2(48.0, ly), Vector2(168.0, ly), Color(0.82, 0.74, 0.6, 0.4), 1.0)
		# Roof with gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(68.0, 122.0), Vector2(80.0, 56.0)), Color(0.82, 0.32, 0.22), Color(0.68, 0.22, 0.16))
		# Chimney
		draw_rect(Rect2(Vector2(126.0, 108.0), Vector2(16.0, 22.0)), Color(0.72, 0.28, 0.2), true)
		draw_rect(Rect2(Vector2(124.0, 106.0), Vector2(20.0, 4.0)), Color(0.62, 0.22, 0.16), true)
		# Window glow
		draw_rect(Rect2(Vector2(78.0, 136.0), Vector2(22.0, 18.0)), Color(1.0, 0.94, 0.62, 0.7), true)
		draw_rect(Rect2(Vector2(116.0, 136.0), Vector2(22.0, 18.0)), Color(1.0, 0.94, 0.62, 0.7), true)
		draw_rect(Rect2(Vector2(78.0, 136.0), Vector2(22.0, 18.0)), Color(0.56, 0.38, 0.18), false, 1.5)
		draw_rect(Rect2(Vector2(116.0, 136.0), Vector2(22.0, 18.0)), Color(0.56, 0.38, 0.18), false, 1.5)
		# Door
		draw_rect(Rect2(Vector2(96.0, 270.0), Vector2(24.0, 38.0)), Color(0.52, 0.34, 0.18), true)
		draw_circle(Vector2(116.0, 290.0), 2.0, Color(0.86, 0.78, 0.42))
		# Side wall gradient
		ThemeLib.draw_gradient_rect_v(self, Rect2(Vector2(186.0, 118.0), Vector2(42.0, size.y - 118.0)), Color(0.78, 0.7, 0.56), Color(0.7, 0.62, 0.48))
		# Fence/border
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 38.0, BOARD_ORIGIN.y), Vector2(28.0, board_size.y)), Color(0.57, 0.43, 0.26), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x + board_size.x, BOARD_ORIGIN.y), Vector2(82.0, board_size.y)), Color(0.52, 0.65, 0.44), true)
		# Light bands on lawn
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 24.0, BOARD_ORIGIN.y + 28.0), Vector2(board_size.x + 96.0, 96.0)), Color(1.0, 1.0, 1.0, 0.04), true)
		draw_rect(Rect2(Vector2(BOARD_ORIGIN.x - 30.0, BOARD_ORIGIN.y + 214.0), Vector2(board_size.x + 108.0, 84.0)), Color(1.0, 1.0, 1.0, 0.03), true)
		# Grass tufts along edges
		ThemeLib.draw_grass_tufts(self, Rect2(Vector2(BOARD_ORIGIN.x + board_size.x + 4.0, BOARD_ORIGIN.y), Vector2(70.0, board_size.y)), ui_time, 8, Color(0.42, 0.58, 0.28))
		# Ambient leaves
		ThemeLib.draw_ambient_particles(self, size, ui_time, "leaves", 8)

	_draw_panel_shell(COIN_METER_RECT, Color(0.97, 0.89, 0.44), Color(0.48, 0.36, 0.09), 0.12, 0.06)
	_draw_coin_icon(COIN_METER_RECT.position + Vector2(22.0, 20.0), 1.0)
	_draw_text(str(coins_total), COIN_METER_RECT.position + Vector2(44.0, 27.0), 22, Color(0.31, 0.2, 0.05))

	_draw_panel_shell(BACK_BUTTON_RECT, Color(0.92, 0.88, 0.78), Color(0.42, 0.3, 0.14), 0.1, 0.05)
	_draw_text("返回地图", BACK_BUTTON_RECT.position + Vector2(14.0, 27.0), 18, Color(0.27, 0.18, 0.08))


func _draw_battle_board() -> void:
	var freeze_visual_ratio = _freeze_transition_visual_ratio()
	var clock_floor_style := _scarlet_clocktower_floor_style() if _is_scarlet_clocktower_level() else {}
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
		elif _is_blood_library_level():
			lane_color = Color(0.34, 0.06, 0.12) if row % 2 == 0 else Color(0.28, 0.04, 0.1)
		elif _is_frozen_branch_level():
			lane_color = Color(0.62, 0.78, 0.68) if row % 2 == 0 else Color(0.56, 0.72, 0.62)
		elif _is_city_level():
			lane_color = Color(0.24, 0.34, 0.3) if row % 2 == 0 else Color(0.2, 0.3, 0.26)
		elif _is_roof_level():
			lane_color = Color(0.56, 0.3, 0.2) if row % 2 == 0 else Color(0.5, 0.26, 0.18)
		elif _is_night_level():
			lane_color = Color(0.23, 0.38, 0.2) if row % 2 == 0 else Color(0.19, 0.32, 0.17)
		elif _is_fog_level():
			lane_color = Color(0.2, 0.34, 0.22) if row % 2 == 0 else Color(0.16, 0.28, 0.18)
		elif _uses_backyard_pool_board() and _is_water_row(row):
			lane_color = Color(0.16, 0.58, 0.84) if row % 2 == 0 else Color(0.12, 0.5, 0.78)
		# Lane gradient instead of flat fill
		ThemeLib.draw_gradient_rect_v(self, lane_rect, lane_color.lightened(0.04), lane_color.darkened(0.04))
		if _uses_backyard_pool_board() and _is_water_row(row):
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
		elif _is_roof_level():
			for stripe_index in range(5):
				var stripe_y = lane_rect.position.y + 12.0 + float(stripe_index) * 20.0
				draw_line(
					Vector2(lane_rect.position.x - 8.0, stripe_y),
					Vector2(lane_rect.position.x + lane_rect.size.x + 8.0, stripe_y - 10.0),
					Color(1.0, 0.86, 0.72, 0.06 if stripe_index % 2 == 0 else 0.04),
					2.0
				)
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
			elif _is_blood_library_level():
				tint = Color(0.94, 0.26, 0.34, 0.04) if (row + col) % 2 == 0 else Color(0.08, 0.0, 0.04, 0.08)
				border_color = Color(0.56, 0.14, 0.22, 0.3)
			elif _is_scarlet_clocktower_level():
				tint = Color(clock_floor_style.get("mortar", Color(0.14, 0.03, 0.06, 0.8)))
				border_color = Color(clock_floor_style.get("bevel_shadow", Color(0.18, 0.02, 0.08, 0.46)))
			elif String(current_level.get("terrain", "")) == "scarlet_gate":
				tint = Color(0.82, 0.28, 0.14, 0.04) if (row + col) % 2 == 0 else Color(0.0, 0.0, 0.0, 0.06)
				border_color = Color(0.48, 0.14, 0.08, 0.24)
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
			elif _is_roof_level():
				tint = Color(1.0, 0.92, 0.82, 0.05) if (row + col) % 2 == 0 else Color(0.16, 0.08, 0.04, 0.06)
				border_color = Color(0.48, 0.22, 0.14, 0.24)
			elif _is_city_level():
				var tile_terrain = _cell_terrain_kind(row, col)
				match tile_terrain:
					"city_tile":
						tint = Color(0.7, 0.78, 0.84, 0.26) if (row + col) % 2 == 0 else Color(0.46, 0.54, 0.62, 0.22)
						border_color = Color(0.22, 0.3, 0.38, 0.36)
					"rail":
						tint = Color(0.26, 0.28, 0.32, 0.34) if (row + col) % 2 == 0 else Color(0.18, 0.2, 0.24, 0.3)
						border_color = Color(0.78, 0.68, 0.42, 0.34)
					"snowfield":
						tint = Color(0.86, 0.96, 1.0, 0.22) if (row + col) % 2 == 0 else Color(0.68, 0.84, 0.94, 0.18)
						border_color = Color(0.54, 0.86, 1.0, 0.34)
					_:
						tint = Color(0.24, 0.48, 0.28, 0.12) if (row + col) % 2 == 0 else Color(0.12, 0.26, 0.18, 0.1)
						border_color = Color(0.1, 0.24, 0.16, 0.24)
			elif _uses_backyard_pool_board() and _is_water_row(row):
				tint = Color(0.88, 0.98, 1.0, 0.05) if (row + col) % 2 == 0 else Color(0.0, 0.2, 0.32, 0.05)
				border_color = Color(0.68, 0.94, 1.0, 0.16)
			draw_rect(tile, tint, true)
			if _is_scarlet_clocktower_level():
				var tile_inset = float(clock_floor_style.get("tile_inset", 9.0))
				var tile_center = tile.position + tile.size * 0.5
				var ceramic_rect = tile.grow(-tile_inset)
				ThemeLib.draw_gradient_rect_v(
					self,
					ceramic_rect,
					Color(clock_floor_style.get("tile_light", Color(0.82, 0.22, 0.18, 0.92))),
					Color(clock_floor_style.get("tile_dark", Color(0.42, 0.08, 0.12, 0.96)))
				)
				draw_rect(ceramic_rect, Color(clock_floor_style.get("bevel_shadow", Color(0.18, 0.02, 0.08, 0.46))), false, 2.0)
				draw_line(
					ceramic_rect.position + Vector2(4.0, 4.0),
					ceramic_rect.position + Vector2(ceramic_rect.size.x - 4.0, 4.0),
					Color(clock_floor_style.get("bevel_light", Color(1.0, 0.86, 0.8, 0.24))),
					2.0
				)
				draw_line(
					ceramic_rect.position + Vector2(4.0, 4.0),
					ceramic_rect.position + Vector2(4.0, ceramic_rect.size.y - 4.0),
					Color(clock_floor_style.get("bevel_light", Color(1.0, 0.86, 0.8, 0.24))),
					2.0
				)
				draw_rect(
					Rect2(ceramic_rect.position + Vector2(6.0, 6.0), Vector2(maxf(8.0, ceramic_rect.size.x - 12.0), maxf(10.0, ceramic_rect.size.y * 0.26))),
					Color(clock_floor_style.get("gloss", Color(1.0, 0.92, 0.86, 0.12))),
					true
				)
				draw_line(
					tile_center + Vector2(-ceramic_rect.size.x * 0.34, 0.0),
					tile_center + Vector2(ceramic_rect.size.x * 0.34, 0.0),
					Color(clock_floor_style.get("accent", Color(0.98, 0.72, 0.52, 0.2))),
					1.2
				)
				draw_line(
					tile_center + Vector2(0.0, -ceramic_rect.size.y * 0.32),
					tile_center + Vector2(0.0, ceramic_rect.size.y * 0.32),
					Color(0.12, 0.01, 0.04, 0.18),
					1.0
				)
				for rivet_offset in [
					Vector2(-ceramic_rect.size.x * 0.32, -ceramic_rect.size.y * 0.28),
					Vector2(ceramic_rect.size.x * 0.32, -ceramic_rect.size.y * 0.28),
					Vector2(-ceramic_rect.size.x * 0.32, ceramic_rect.size.y * 0.28),
					Vector2(ceramic_rect.size.x * 0.32, ceramic_rect.size.y * 0.28),
				]:
					draw_circle(tile_center + rivet_offset, 2.4, Color(clock_floor_style.get("rivet", Color(0.96, 0.82, 0.64, 0.24))))
				if (row + col) % 2 == 0:
					var arc_radius = minf(ceramic_rect.size.x, ceramic_rect.size.y) * 0.16
					var arc_start = scarlet_clock_drift * 0.68 + float(row) * 0.28 + float(col) * 0.2
					draw_arc(tile_center, arc_radius, arc_start, arc_start + PI * 1.42, 18, Color(clock_floor_style.get("accent", Color(0.98, 0.72, 0.52, 0.2))), 1.4)
				else:
					draw_rect(ceramic_rect.grow(-5.0), Color(0.12, 0.01, 0.04, 0.08), false, 1.0)
			elif _is_city_level():
				var city_terrain = _cell_terrain_kind(row, col)
				if city_terrain == "city_tile":
					for grid_line in range(1, 3):
						var t = float(grid_line) / 3.0
						draw_line(tile.position + Vector2(tile.size.x * t, 6.0), tile.position + Vector2(tile.size.x * t, tile.size.y - 6.0), Color(1.0, 1.0, 1.0, 0.08), 1.4)
						draw_line(tile.position + Vector2(6.0, tile.size.y * t), tile.position + Vector2(tile.size.x - 6.0, tile.size.y * t), Color(0.16, 0.22, 0.28, 0.1), 1.4)
				elif city_terrain == "rail":
					var rail_y_a = tile.position.y + tile.size.y * 0.34
					var rail_y_b = tile.position.y + tile.size.y * 0.66
					draw_line(Vector2(tile.position.x + 4.0, rail_y_a), Vector2(tile.position.x + tile.size.x - 4.0, rail_y_a), Color(0.82, 0.72, 0.48, 0.9), 2.2)
					draw_line(Vector2(tile.position.x + 4.0, rail_y_b), Vector2(tile.position.x + tile.size.x - 4.0, rail_y_b), Color(0.82, 0.72, 0.48, 0.9), 2.2)
					for sleeper_index in range(4):
						var sleeper_x = tile.position.x + 12.0 + sleeper_index * 20.0
						draw_line(Vector2(sleeper_x, tile.position.y + 10.0), Vector2(sleeper_x, tile.position.y + tile.size.y - 10.0), Color(0.38, 0.28, 0.16, 0.7), 3.2)
				elif city_terrain == "snowfield":
					draw_line(tile.position + Vector2(10.0, 12.0), tile.position + tile.size - Vector2(12.0, 16.0), Color(1.0, 1.0, 1.0, 0.2), 2.0)
					draw_line(tile.position + Vector2(tile.size.x * 0.62, 10.0), tile.position + Vector2(tile.size.x * 0.3, tile.size.y - 12.0), Color(0.72, 0.9, 1.0, 0.16), 2.0)
				else:
					if (row + col) % 4 == 0:
						var cover_center = tile.position + tile.size * 0.5
						draw_circle(cover_center, minf(tile.size.x, tile.size.y) * 0.15, Color(0.2, 0.26, 0.22, 0.32))
						draw_circle(cover_center, minf(tile.size.x, tile.size.y) * 0.09, Color(0.12, 0.16, 0.14, 0.42))
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

	var outline = Color(0.38, 0.04, 0.06, 0.8) if _is_blood_moon_level() else (Color(0.48, 0.08, 0.18, 0.82) if _is_blood_library_level() else (Color(0.72, 0.16, 0.08, 0.82) if String(current_level.get("terrain", "")) == "scarlet_gate" else (Color(0.62, 0.16, 0.24, 0.84) if _is_scarlet_clocktower_level() else (Color(0.52, 0.84, 1.0, 0.8) if _is_frozen_branch_level() else (Color(0.34, 0.78, 0.96, 0.82) if _is_city_level() else (Color(0.54, 0.24, 0.16, 0.76) if _is_roof_level() else (Color(0.08, 0.26, 0.34, 0.72) if _uses_backyard_pool_board() else (Color(0.16, 0.24, 0.22, 0.72) if _is_fog_level() else Color(0.12, 0.28, 0.08, 0.68)))))))))
	draw_rect(Rect2(BOARD_ORIGIN, board_size), outline, false, 4.0)


func _draw_fog_overlay() -> void:
	if not _is_fog_level():
		return
	var base_alpha = 0.34 if not _is_storm_fog_level() else 0.42
	if fog_global_reveal_timer > 0.0:
		base_alpha *= clampf(1.0 - fog_global_reveal_timer / 5.2, 0.18, 0.9)
	if fog_lightning_timer > 0.0:
		base_alpha *= 0.35
	for row_variant in active_rows:
		var row = int(row_variant)
		for col in range(COLS):
			if _is_cell_revealed(row, col):
				continue
			var tile = _cell_rect(row, col).grow(8.0)
			draw_rect(tile, Color(0.76, 0.84, 0.82, base_alpha * 0.16), true)
			var cell_center = tile.position + tile.size * 0.5
			var drift = sin(ui_time * 0.9 + float(row) * 0.7 + float(col) * 0.4) * 6.0
			draw_circle(cell_center + Vector2(-12.0 + drift, -6.0), 34.0, Color(0.84, 0.9, 0.88, base_alpha * 0.3))
			draw_circle(cell_center + Vector2(18.0 - drift, 8.0), 28.0, Color(0.9, 0.96, 0.94, base_alpha * 0.22))
			draw_circle(cell_center + Vector2(-30.0 + drift * 0.4, 12.0), 22.0, Color(0.72, 0.82, 0.8, base_alpha * 0.18))


func _draw_city_blizzard_overlay() -> void:
	if not _has_city_blizzard_weather():
		return
	for flake_index in range(42):
		var phase = city_blizzard_drift * (0.8 + float(flake_index % 5) * 0.18) + float(flake_index) * 0.34
		var x = BOARD_ORIGIN.x - 24.0 + fmod(phase * 90.0 + float(flake_index) * 42.0, board_size.x + 96.0)
		var y = BOARD_ORIGIN.y - 16.0 + fmod(phase * 56.0 + float(flake_index) * 27.0, board_size.y + 52.0)
		var alpha = 0.08 + 0.06 * sin(phase * 1.6 + float(flake_index))
		draw_circle(Vector2(x, y), 2.6 + float(flake_index % 3), Color(0.92, 0.98, 1.0, alpha))
		draw_line(Vector2(x - 4.0, y), Vector2(x + 4.0, y), Color(1.0, 1.0, 1.0, alpha * 0.72), 1.0)
		draw_line(Vector2(x, y - 4.0), Vector2(x, y + 4.0), Color(1.0, 1.0, 1.0, alpha * 0.72), 1.0)


func _draw_scarlet_clocktower_overlay() -> void:
	if not _is_scarlet_clocktower_level():
		return
	var board_rect = Rect2(BOARD_ORIGIN, board_size)
	for gear_index in range(4):
		var phase = scarlet_clock_drift * (0.72 + float(gear_index) * 0.08) + float(gear_index) * 1.14
		var center = Vector2(
			board_rect.position.x + board_rect.size.x * (0.16 + float(gear_index) * 0.22),
			board_rect.position.y + board_rect.size.y * (0.22 + float(gear_index % 3) * 0.28)
		)
		var radius = 24.0 + float(gear_index) * 9.0
		draw_arc(center, radius, phase, phase + PI * 1.52, 18, Color(0.92, 0.18, 0.24, 0.1), 2.2)
		for spoke_index in range(4):
			var spoke_angle = phase + float(spoke_index) * TAU / 4.0
			var spoke_from = center + Vector2(cos(spoke_angle), sin(spoke_angle)) * (radius * 0.32)
			var spoke_to = center + Vector2(cos(spoke_angle), sin(spoke_angle)) * (radius * 0.92)
			draw_line(spoke_from, spoke_to, Color(0.96, 0.84, 0.72, 0.08), 1.4)
	var scan_x = board_rect.position.x - 36.0 + fmod(scarlet_clock_drift * 92.0, board_rect.size.x + 96.0)
	draw_rect(Rect2(Vector2(scan_x, board_rect.position.y - 6.0), Vector2(54.0, board_rect.size.y + 12.0)), Color(1.0, 0.24, 0.28, 0.035), true)
	draw_line(Vector2(scan_x + 12.0, board_rect.position.y - 4.0), Vector2(scan_x + 42.0, board_rect.position.y + board_rect.size.y + 4.0), Color(1.0, 0.88, 0.82, 0.08), 2.0)


func _draw_sakuya_time_stop_overlay() -> void:
	if boss_time_stop_timer <= 0.0:
		return
	var max_duration = maxf(float(Defs.ZOMBIES.get("sakuya_boss", {}).get("time_stop_duration", 2.3)), 0.01)
	var ratio = clampf(boss_time_stop_timer / max_duration, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.86, 0.92, 1.0, 0.04 + ratio * 0.08), true)
	var ring_center = Vector2(BOARD_ORIGIN.x + board_size.x * 0.78, BOARD_ORIGIN.y + board_size.y * 0.5 - 10.0)
	draw_circle(ring_center, 220.0 + sin(ui_time * 8.0) * 10.0, Color(0.84, 0.9, 1.0, 0.03 + ratio * 0.05))
	for tick_index in range(12):
		var tick_angle = level_time * 0.4 - PI * 0.5 + TAU * float(tick_index) / 12.0
		var tick_from = ring_center + Vector2(cos(tick_angle), sin(tick_angle)) * 148.0
		var tick_to = ring_center + Vector2(cos(tick_angle), sin(tick_angle)) * 184.0
		draw_line(tick_from, tick_to, Color(0.9, 0.94, 1.0, 0.12 + ratio * 0.12), 2.0)


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
	# Sun icon glow
	ThemeLib.draw_glow_circle(self, SUN_METER_RECT.get_center() + Vector2(0.0, -14.0), 12.0, Color(1.0, 0.92, 0.36, 0.3 * sun_pulse), 2)
	draw_circle(SUN_METER_RECT.get_center(), 18.0 + sun_pulse * 3.0, Color(1.0, 0.9, 0.34, 0.08), false, 2.0)
	if _is_whack_level():
		_draw_text("木槌", Vector2(44.0, 48.0), 18, Color(0.33, 0.21, 0.04))
		_draw_text(str(sun_points), Vector2(55.0, 87.0), 28, Color(0.0, 0.0, 0.0, 0.15))
		_draw_text(str(sun_points), Vector2(54.0, 86.0), 28, Color(0.33, 0.21, 0.04))
	elif _is_conveyor_level():
		_draw_text("传送带", Vector2(38.0, 48.0), 18, Color(0.33, 0.21, 0.04))
		_draw_text("自动供卡", Vector2(34.0, 84.0), 22, Color(0.33, 0.21, 0.04))
	else:
		_draw_text("阳光", Vector2(46.0, 48.0), 18, Color(0.33, 0.21, 0.04))
		_draw_text(str(sun_points), Vector2(55.0, 87.0), 28, Color(0.0, 0.0, 0.0, 0.15))
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

		if not _is_conveyor_level() and not affordable and float(card_cooldowns[kind]) <= 0.01:
			draw_rect(draw_rect_local, Color(0.0, 0.0, 0.0, 0.24), true)

		if not _is_conveyor_level() and float(card_cooldowns[kind]) > 0.01:
			var cover_height = draw_rect_local.size.y * clampf(cooling_ratio, 0.0, 1.0)
			draw_rect(Rect2(draw_rect_local.position, Vector2(draw_rect_local.size.x, cover_height)), Color(0.12, 0.12, 0.12, 0.46), true)
			draw_rect(Rect2(draw_rect_local.position + Vector2(0.0, cover_height - 3.0), Vector2(draw_rect_local.size.x, 3.0)), Color(1.0, 1.0, 1.0, 0.14), true)
			var recharge_rect = Rect2(draw_rect_local.position + Vector2(4.0, draw_rect_local.size.y - 7.0), Vector2(draw_rect_local.size.x - 8.0, 3.0))
			draw_rect(recharge_rect, Color(0.0, 0.0, 0.0, 0.26), true)
			draw_rect(ThemeLib.progress_fill_rect(recharge_rect, 1.0 - cooling_ratio), Color(0.86, 0.96, 0.62, 0.82), true)

		# Draw name and cost AFTER overlays so they're always visible
		var name_font_size = 10 if draw_rect_local.size.x < 76.0 else 12
		var cost_x = 6.0 if draw_rect_local.size.x < 76.0 else 8.0
		var plant_name = String(data["name"])
		# Truncate long names for narrow cards
		if draw_rect_local.size.x < 76.0 and plant_name.length() > 3:
			plant_name = plant_name.left(3) + "…"
		elif draw_rect_local.size.x < 82.0 and plant_name.length() > 4:
			plant_name = plant_name.left(4) + "…"
		# Name backing strip for readability
		draw_rect(Rect2(draw_rect_local.position + Vector2(0.0, 2.0), Vector2(draw_rect_local.size.x, 18.0)), Color(card_color.r, card_color.g, card_color.b, 0.88), true)
		_draw_text(plant_name, draw_rect_local.position + Vector2(5.0, 18.0), name_font_size, Color(0.0, 0.0, 0.0, 0.12))
		_draw_text(plant_name, draw_rect_local.position + Vector2(4.0, 17.0), name_font_size, Color(0.29, 0.17, 0.05))
		if not _is_conveyor_level():
			# Cost backing strip
			draw_rect(Rect2(draw_rect_local.position + Vector2(0.0, draw_rect_local.size.y - 20.0), Vector2(draw_rect_local.size.x, 20.0)), Color(card_color.r, card_color.g, card_color.b, 0.82), true)
			_draw_text(str(data["cost"]), draw_rect_local.position + Vector2(cost_x + 1.0, 85.0), 16, Color(0.0, 0.0, 0.0, 0.12))
			_draw_text(str(data["cost"]), draw_rect_local.position + Vector2(cost_x, 84.0), 16, Color(0.29, 0.17, 0.05))
		# Star indicator if plant has stars
		if plant_stars.has(kind) and int(plant_stars[kind]) > 0:
			var star_count = int(plant_stars[kind])
			for star_i in range(mini(star_count, 3)):
				draw_circle(draw_rect_local.position + Vector2(draw_rect_local.size.x - 10.0 - float(star_i) * 10.0, 12.0), 4.0, Color(1.0, 0.86, 0.2, 0.9))

	if _is_whack_level():
		var hammer_rect = Rect2(WAVE_BAR_RECT.position.x, SEED_BANK_RECT.position.y + 2.0, 120.0, 80.0)
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
	if frozen_branch_progress_locked and not frozen_branch_midboss_cleared:
		return minf(progress_ratio, maxf(0.0, frozen_branch_locked_progress))
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
	frozen_branch_locked_progress = float(current_level.get("mid_boss_locked_progress", 0.5))
	var banner_text = String(current_level.get("mid_boss_banner", ""))
	if banner_text == "":
		banner_text = "大妖精挡住了前进路线！" if midboss_kind == "daiyousei_boss" else "中途 Boss 挡住了前进路线！"
	var effect_color = Color(0.58, 0.94, 1.0, 0.28)
	if midboss_kind == "koakuma_boss":
		effect_color = Color(0.96, 0.24, 0.34, 0.28)
	_show_banner(banner_text, 2.0)
	effects.append({
		"position": Vector2(BOARD_ORIGIN.x + board_size.x - 24.0, _row_center_y(spawn_row) - 12.0),
		"radius": 96.0,
		"time": 0.4,
		"duration": 0.4,
		"color": effect_color,
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
	var midboss_kind = String(current_level.get("mid_boss_kind", ""))
	if midboss_kind == "":
		return
	var lock_progress = float(current_level.get("mid_boss_locked_progress", 0.5))
	if not frozen_branch_midboss_spawned and _battle_progress_ratio_raw() >= lock_progress:
		_spawn_frozen_branch_midboss()
		return
	if frozen_branch_midboss_spawned and not frozen_branch_midboss_cleared and _find_alive_enemy_boss(midboss_kind).is_empty():
		frozen_branch_midboss_cleared = true
		frozen_branch_progress_locked = false
		frozen_branch_locked_progress = -1.0
		if midboss_kind == "daiyousei_boss":
			_show_banner("大妖精被击退，冰雾还在加深！", 2.0)
		elif midboss_kind == "koakuma_boss":
			_show_banner("小恶魔被逼退，深层书库打开了！", 2.0)
		else:
			_show_banner("中途 Boss 被击退，战线继续推进！", 2.0)


func _update_remilia_crimson_drain(delta: float) -> void:
	if delta <= 0.0:
		return
	var remilia = _find_alive_enemy_boss("remilia_boss")
	if remilia.is_empty():
		remilia_crimson_fx_timer = 0.35
		return
	var phase = int(remilia.get("boss_phase", 0))
	var damage = (float(Defs.ZOMBIES.get("remilia_boss", {}).get("drain_dps", 11.0)) + float(phase) * 1.6) * delta
	var affected := 0
	for lane_variant in active_rows:
		var row = int(lane_variant)
		for col in range(COLS):
			if _damage_plant_cell(row, col, damage):
				affected += 1
	remilia_crimson_fx_timer -= delta
	if affected <= 0 or remilia_crimson_fx_timer > 0.0:
		return
	var fx_cells = _remilia_target_cells(int(remilia.get("row", 0)), min(3 + phase, 5), 1)
	for cell_variant in fx_cells:
		var cell = Vector2i(cell_variant)
		effects.append({
			"shape": "glow_burst",
			"position": _cell_center(cell.x, cell.y) + Vector2(0.0, -12.0),
			"radius": 46.0 + phase * 4.0,
			"time": 0.24,
			"duration": 0.24,
			"color": Color(0.94, 0.12, 0.18, 0.2),
		})
	effects.append({
		"shape": "arcane_circle",
		"position": Vector2(_boss_anchor_x("remilia_boss") - 88.0, _row_center_y(int(remilia.get("row", 0))) - 12.0),
		"radius": 188.0 + phase * 18.0,
		"time": 0.32,
		"duration": 0.32,
		"anim_speed": 6.8,
		"color": Color(0.98, 0.16, 0.24, 0.18),
	})
	remilia_crimson_fx_timer = maxf(0.18, 0.38 - float(phase) * 0.04)


func _roll_blood_library_hazard_interval() -> float:
	var interval = Vector2(current_level.get("library_hazard_interval", Vector2(8.0, 12.0)))
	return rng.randf_range(interval.x, interval.y)


func _spawn_blood_library_hazard() -> void:
	if not _is_blood_library_level():
		return
	var patchouli_alive = not _find_alive_enemy_boss("patchouli_boss").is_empty()
	var cell_count = 2 + (1 if patchouli_alive else 0)
	var cells: Array = []
	for _i in range(cell_count * 3):
		if cells.size() >= cell_count:
			break
		var row = int(active_rows[rng.randi_range(0, active_rows.size() - 1)])
		var col = rng.randi_range(2, COLS - 1)
		var cell = Vector2i(row, col)
		if cells.has(cell):
			continue
		cells.append(cell)
	var damage = float(current_level.get("library_hazard_damage", 58.0)) + (22.0 if patchouli_alive else 0.0)
	var hit_count = _damage_plants_in_cells(cells, damage, 1.1 if patchouli_alive else 0.7)
	for cell_variant in cells:
		var cell = Vector2i(cell_variant)
		effects.append({
			"shape": "arcane_circle",
			"position": _cell_center(cell.x, cell.y) + Vector2(0.0, -12.0),
			"radius": 42.0 + (6.0 if patchouli_alive else 0.0),
			"time": 0.52,
			"duration": 0.52,
			"anim_speed": 5.8,
			"color": Color(0.9, 0.22, 0.3, 0.28 if hit_count > 0 else 0.18),
		})


func _update_blood_library_hazards(delta: float) -> void:
	if not _is_blood_library_level():
		return
	blood_library_hazard_timer -= delta
	if blood_library_hazard_timer > 0.0:
		return
	_spawn_blood_library_hazard()
	blood_library_hazard_timer = _roll_blood_library_hazard_interval()


func _roll_scarlet_clock_hazard_interval() -> float:
	var interval = Vector2(current_level.get("clock_hazard_interval", Vector2(5.8, 8.4)))
	return rng.randf_range(interval.x, interval.y)


func _spawn_scarlet_clocktower_hazard() -> void:
	if not _has_scarlet_clock_hazard() or active_rows.is_empty():
		return
	var damage = float(current_level.get("clock_hazard_damage", 52.0))
	var slow_duration = float(current_level.get("clock_hazard_slow", 0.9))
	scarlet_clock_drift += rng.randf_range(0.45, 0.9)
	if rng.randf() < 0.46:
		var lane = int(active_rows[rng.randi_range(0, active_rows.size() - 1)])
		var start_x = BOARD_ORIGIN.x + board_size.x * rng.randf_range(0.18, 0.4)
		var end_x = BOARD_ORIGIN.x + board_size.x + 24.0
		var hit = _damage_zombies_in_row_segment(lane, start_x, end_x, damage * 0.92, slow_duration)
		effects.append({
			"shape": "lane_spray",
			"position": Vector2(start_x, _row_center_y(lane) - 10.0),
			"length": end_x - start_x,
			"width": CELL_SIZE.y * 0.72,
			"radius": board_size.x,
			"time": 0.42,
			"duration": 0.42,
			"anim_speed": 8.4,
			"color": Color(0.94, 0.86, 0.82, 0.28 if hit else 0.18),
		})
		return
	var cell_count = 2 + (1 if rng.randf() < 0.6 else 0)
	var cells: Array = []
	for _i in range(cell_count * 4):
		if cells.size() >= cell_count:
			break
		var row = int(active_rows[rng.randi_range(0, active_rows.size() - 1)])
		var col = rng.randi_range(2, COLS - 1)
		var cell = Vector2i(row, col)
		if cells.has(cell):
			continue
		cells.append(cell)
	for cell_variant in cells:
		var cell = Vector2i(cell_variant)
		var center = _cell_center(cell.x, cell.y) + Vector2(0.0, -6.0)
		_damage_zombies_in_circle(center, CELL_SIZE.x * 0.42, damage * 0.76)
		effects.append({
			"shape": "arcane_circle",
			"position": center,
			"radius": 38.0,
			"time": 0.44,
			"duration": 0.44,
			"anim_speed": 7.6,
			"color": Color(0.9, 0.22, 0.28, 0.2),
		})
		effects.append({
			"shape": "glow_burst",
			"position": center,
			"radius": 54.0,
			"time": 0.22,
			"duration": 0.22,
			"color": Color(1.0, 0.92, 0.86, 0.14),
		})


func _update_scarlet_clocktower_hazards(delta: float) -> void:
	if not _has_scarlet_clock_hazard():
		return
	scarlet_clock_drift += delta
	scarlet_clock_hazard_timer -= delta
	if scarlet_clock_hazard_timer > 0.0:
		return
	_spawn_scarlet_clocktower_hazard()
	scarlet_clock_hazard_timer = _roll_scarlet_clock_hazard_interval()


func _update_city_blizzard_weather(delta: float) -> void:
	if not _has_city_blizzard_weather():
		return
	city_blizzard_drift += delta
	city_blizzard_timer -= delta
	if city_blizzard_timer > 0.0:
		return
	var rows: Array = active_rows.duplicate()
	rows.shuffle()
	var burst_count = min(rows.size(), 1 if rng.randf() < 0.58 else 2)
	for row_index in range(burst_count):
		var lane = int(rows[row_index])
		var start_x = BOARD_ORIGIN.x + board_size.x * rng.randf_range(0.34, 0.74)
		_damage_zombies_in_row_segment(
			lane,
			start_x,
			BOARD_ORIGIN.x + board_size.x + 24.0,
			18.0 + float(current_level.get("blizzard_damage", 18.0)),
			1.8
		)
		effects.append({
			"shape": "diamond_blizzard",
			"position": Vector2(start_x, _row_center_y(lane) - 4.0),
			"length": BOARD_ORIGIN.x + board_size.x - start_x + 28.0,
			"width": CELL_SIZE.y * 0.78,
			"radius": board_size.x,
			"time": 0.34,
			"duration": 0.34,
			"color": Color(0.82, 0.96, 1.0, 0.24),
		})
	city_blizzard_timer = rng.randf_range(3.6, 6.2)


func _draw_wave_bar() -> void:
	# Endless mode: show wave counter instead of progress bar
	if current_level.get("id", "") == "无尽":
		ThemeLib.draw_rounded_panel(self, WAVE_BAR_RECT, Color(0.52, 0.14, 0.14), Color(0.36, 0.08, 0.08), 8.0, 0.16, 0.08)
		var wave_text = "第 %d 波" % endless_wave if endless_wave > 0 else "准备中..."
		_draw_text(wave_text, WAVE_BAR_RECT.position + Vector2(11.0, 17.0), 14, Color(0.0, 0.0, 0.0, 0.3))
		_draw_text(wave_text, WAVE_BAR_RECT.position + Vector2(10.0, 16.0), 14, Color(1.0, 0.92, 0.86))
		_draw_text("最高: %d" % endless_best_wave, WAVE_BAR_RECT.position + Vector2(WAVE_BAR_RECT.size.x - 80.0, 17.0), 14, Color(0.0, 0.0, 0.0, 0.3))
		_draw_text("最高: %d" % endless_best_wave, WAVE_BAR_RECT.position + Vector2(WAVE_BAR_RECT.size.x - 81.0, 16.0), 14, Color(1.0, 0.86, 0.72))
		_draw_text("无尽", WAVE_BAR_RECT.position + Vector2(-54.0, 20.0), 18, Color(0.82, 0.18, 0.18))
		# Difficulty indicator
		var diff_text = "难度 x%.1f" % endless_difficulty_mult
		_draw_text(diff_text, WAVE_BAR_RECT.position + Vector2(WAVE_BAR_RECT.size.x * 0.5 - 40.0, 17.0), 12, Color(1.0, 0.72, 0.52))
		return
	# Daily mode: show modifiers
	if current_level.get("id", "") == "每日":
		ThemeLib.draw_rounded_panel(self, WAVE_BAR_RECT, Color(0.18, 0.36, 0.52), Color(0.12, 0.24, 0.36), 8.0, 0.14, 0.06)
		_draw_text("每日挑战", WAVE_BAR_RECT.position + Vector2(-68.0, 20.0), 18, Color(0.28, 0.56, 0.82))
		var mod_text = ""
		for mod in daily_modifiers:
			if mod_text != "":
				mod_text += " | "
			mod_text += String(mod["name"])
		_draw_text(mod_text, WAVE_BAR_RECT.position + Vector2(11.0, 17.0), 14, Color(0.0, 0.0, 0.0, 0.3))
		_draw_text(mod_text, WAVE_BAR_RECT.position + Vector2(10.0, 16.0), 14, Color(0.92, 0.96, 1.0))
		var progress_ratio = _battle_progress_ratio()
		_draw_text("%d%%" % int(round(progress_ratio * 100.0)), WAVE_BAR_RECT.position + Vector2(WAVE_BAR_RECT.size.x - 40.0, 16.0), 14, Color(0.92, 0.96, 1.0))
		return

	ThemeLib.draw_rounded_panel(self, WAVE_BAR_RECT, Color(0.24, 0.18, 0.16), Color(0.18, 0.1, 0.08), 8.0, 0.14, 0.06)

	var total_events = max(current_level["events"].size(), 1)
	var progress_ratio = _battle_progress_ratio()
	var inner_rect = WAVE_BAR_RECT.grow(-6.0)
	draw_rect(inner_rect, Color(0.06, 0.03, 0.03, 0.6), true)
	# Segment lines
	for segment_index in range(10):
		var segment_x = inner_rect.position.x + inner_rect.size.x * (float(segment_index) / 10.0)
		draw_line(Vector2(segment_x, inner_rect.position.y), Vector2(segment_x, inner_rect.position.y + inner_rect.size.y), Color(1.0, 1.0, 1.0, 0.04), 1.0)
	# Fill with gradient
	var fill_rect = ThemeLib.progress_fill_rect(inner_rect, progress_ratio)
	ThemeLib.draw_gradient_rect_v(self, fill_rect, Color(0.92, 0.24, 0.22), Color(0.72, 0.12, 0.12))
	# Top highlight
	draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, fill_rect.size.y * 0.36)), Color(1.0, 0.48, 0.36, 0.28), true)
	# Bottom shadow
	draw_rect(Rect2(fill_rect.position + Vector2(0.0, fill_rect.size.y * 0.7), Vector2(fill_rect.size.x, fill_rect.size.y * 0.3)), Color(0.48, 0.02, 0.04, 0.2), true)
	# Animated shimmer
	var shine_x = inner_rect.position.x + fmod(level_time * 180.0, inner_rect.size.x + 60.0) - 40.0
	ThemeLib.draw_gradient_rect_h(self, Rect2(Vector2(shine_x, inner_rect.position.y), Vector2(24.0, inner_rect.size.y)), Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.14))

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
	# Text with shadow
	_draw_text(wave_status, WAVE_BAR_RECT.position + Vector2(11.0, 17.0), 14, Color(0.0, 0.0, 0.0, 0.3))
	_draw_text(wave_status, WAVE_BAR_RECT.position + Vector2(10.0, 16.0), 14, Color(0.96, 0.9, 0.8))
	_draw_text("%d%%" % int(round(progress_ratio * 100.0)), WAVE_BAR_RECT.position + Vector2(WAVE_BAR_RECT.size.x - 39.0, 17.0), 14, Color(0.0, 0.0, 0.0, 0.3))
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
	# Boss name label
	var label_rect = Rect2(rect.position.x - 126.0, rect.position.y - 2.0, 114.0, 28.0)
	ThemeLib.draw_rounded_panel(self, label_rect, Color(0.2, 0.04, 0.06, 0.94), Color(0.58, 0.14, 0.16), 6.0, 0.1, 0.06)
	_draw_text(String(Defs.ZOMBIES[String(boss["kind"])]["name"]), label_rect.position + Vector2(19.0, 21.0), 18, Color(0.0, 0.0, 0.0, 0.3))
	_draw_text(String(Defs.ZOMBIES[String(boss["kind"])]["name"]), label_rect.position + Vector2(18.0, 20.0), 18, Color(1.0, 0.92, 0.94))
	# Outer glow
	draw_rect(rect.grow(8.0), Color(0.86, 0.08, 0.12, 0.06), true)
	draw_rect(rect.grow(6.0), Color(0.16, 0.0, 0.02, 0.32), true)
	ThemeLib.draw_rounded_panel(self, rect, Color(0.12, 0.02, 0.04, 0.96), Color(0.48, 0.1, 0.12), 6.0, 0.1, 0.04)
	for segment_index in range(segments):
		var x = rect.position.x + float(segment_index) * (segment_width + segment_gap)
		var segment_rect = Rect2(x, rect.position.y + 4.0, segment_width, rect.size.y - 8.0)
		draw_rect(segment_rect, Color(0.2, 0.03, 0.04), true)
		var segment_start = max_health * float(segment_index) / float(segments)
		var segment_end = max_health * float(segment_index + 1) / float(segments)
		var segment_ratio = clampf((health - segment_start) / maxf(segment_end - segment_start, 1.0), 0.0, 1.0)
		if segment_ratio > 0.0:
			var fill_rect = Rect2(segment_rect.position, Vector2(segment_rect.size.x * segment_ratio, segment_rect.size.y))
			# Gradient fill
			ThemeLib.draw_gradient_rect_v(self, fill_rect, Color(0.94, 0.16, 0.2), Color(0.76, 0.06, 0.1))
			# Inner glow
			draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, fill_rect.size.y * 0.36)), Color(1.0, 0.44, 0.48, 0.3), true)
			# Pulsing glow at fill edge
			if segment_ratio < 1.0:
				var edge_x = fill_rect.position.x + fill_rect.size.x
				var pulse_alpha = 0.12 + 0.08 * sin(level_time * 4.0)
				draw_line(Vector2(edge_x, segment_rect.position.y), Vector2(edge_x, segment_rect.position.y + segment_rect.size.y), Color(1.0, 0.6, 0.5, pulse_alpha), 3.0)
		draw_rect(segment_rect, Color(0.56, 0.16, 0.16), false, 2.0)


func _draw_click_ultimate_indicator(draw_center: Vector2, plant: Dictionary) -> void:
	var kind = String(plant.get("kind", ""))
	if not _plant_supports_click_ultimate(kind):
		return
	var ult_charge = float(plant.get("ultimate_charge", 0.0))
	var ult_active = bool(plant.get("ultimate_active", false))
	if ult_active:
		var pulse = 0.6 + 0.4 * sin(level_time * 8.0)
		draw_circle(draw_center, 38.0 + pulse * 6.0, Color(1.0, 0.86, 0.2, 0.2 * pulse))
		draw_circle(draw_center, 34.0, Color(1.0, 0.86, 0.2, 0.12), false, 3.0)
	elif ult_charge >= 1.0:
		var pulse = 0.5 + 0.5 * sin(level_time * 4.0)
		draw_circle(draw_center, 36.0 + pulse * 4.0, Color(1.0, 0.92, 0.36, 0.15 * pulse))
		draw_circle(draw_center, 32.0, Color(1.0, 0.92, 0.36, 0.3 + pulse * 0.15), false, 2.5)
		_draw_text("大招", draw_center + Vector2(-14.0, -42.0), 12, Color(1.0, 0.86, 0.2))
	elif ult_charge > 0.0:
		draw_arc(draw_center, 32.0, -PI * 0.5, -PI * 0.5 + TAU * ult_charge, 24, Color(0.72, 0.82, 0.36, 0.3), 2.0)


func _draw_hover() -> void:
	if battle_state != BATTLE_PLAYING or battle_paused:
		return
	if _is_whack_level() and selected_tool == "":
		var target_index = _find_whack_target(_pointer_local_position())
		if target_index != -1:
			var zombie = zombies[target_index]
			var center = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])) + float(zombie.get("jump_offset", 0.0)))
			draw_circle(center, 34.0, Color(1.0, 0.92, 0.38, 0.14))
			draw_circle(center, 30.0, Color(1.0, 0.9, 0.18, 0.7), false, 2.0)
		return
	var cell = _mouse_to_cell(_pointer_local_position())
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
				"flower_pot":
					_draw_flower_pot(Vector2.ZERO, 1.0, float(support.get("flash", 0.0)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if grid[row][col] == null:
				_draw_click_ultimate_indicator(support_draw_center, support)
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
				"mist_orchid":
					_draw_mist_orchid(Vector2.ZERO, 1.0, flash)
				"anchor_fern":
					_draw_anchor_fern(Vector2.ZERO, 1.0, flash)
				"glowvine":
					_draw_glowvine(Vector2.ZERO, 1.0, flash)
				"brine_pot":
					_draw_brine_pot(Vector2.ZERO, 1.0, flash)
				"storm_reed":
					_draw_storm_reed(Vector2.ZERO, 1.0, flash)
				"moonforge":
					_draw_moonforge(Vector2.ZERO, 1.0, flash)
				"mirror_reed":
					_draw_mirror_reed(Vector2.ZERO, 1.0, flash)
				"frost_fan":
					_draw_frost_fan(Vector2.ZERO, 1.0, flash)
				"cabbage_pult":
					_draw_cabbage_pult(Vector2.ZERO, 1.0, flash)
				"coffee_bean":
					_draw_coffee_bean(Vector2.ZERO, 1.0, flash)
				"garlic":
					_draw_garlic(Vector2.ZERO, 1.0, flash)
				"kernel_pult":
					_draw_kernel_pult(Vector2.ZERO, 1.0, flash)
				"marigold":
					_draw_marigold(Vector2.ZERO, 1.0, flash)
				"melon_pult":
					_draw_melon_pult(Vector2.ZERO, 1.0, flash)
				"origami_blossom":
					_draw_origami_blossom(Vector2.ZERO, 1.0, flash)
				"chimney_pepper":
					_draw_chimney_pepper(Vector2.ZERO, 1.0, flash)
				"tesla_tulip":
					_draw_tesla_tulip(Vector2.ZERO, 1.0, flash)
				"brick_guard":
					_draw_brick_guard(Vector2.ZERO, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
				"signal_ivy":
					_draw_signal_ivy(Vector2.ZERO, 1.0, flash)
				"roof_vane":
					_draw_roof_vane(Vector2.ZERO, 1.0, flash)
				"skylight_melon":
					_draw_skylight_melon(Vector2.ZERO, 1.0, flash)
				"heather_shooter":
					_draw_heather_shooter(Vector2.ZERO, 1.0, flash)
				"leyline":
					_draw_leyline(Vector2.ZERO, 1.0, flash)
				"holo_nut":
					_draw_holo_nut(Vector2.ZERO, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
				"healing_gourd":
					_draw_healing_gourd(Vector2.ZERO, 1.0, flash)
				"mango_bowling":
					_draw_mango_bowling(Vector2.ZERO, 1.0, flash)
				"snow_bloom":
					_draw_snow_bloom(Vector2.ZERO, 1.0, flash, clampf(float(plant.get("fuse_timer", 0.0)) / maxf(float(Defs.PLANTS["snow_bloom"].get("wilt_time", 8.0)), 0.01), 0.0, 1.0))
				"cluster_boomerang":
					_draw_cluster_boomerang(Vector2.ZERO, 1.0, flash)
				"glitch_walnut":
					_draw_glitch_walnut(Vector2.ZERO, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
				"nether_shroom":
					_draw_nether_shroom(Vector2.ZERO, 1.0, flash)
				"seraph_flower":
					_draw_seraph_flower(Vector2.ZERO, 1.0, flash)
				"magma_stream":
					_draw_magma_stream(
						Vector2.ZERO,
						1.0,
						flash,
						clampf(
							float(plant.get("fuse_timer", 0.0)) / maxf(float(Defs.PLANTS["magma_stream"].get("wilt_time", 9.0)), 0.01),
							0.0,
							1.0
						)
					)
				"orange_bloom":
					_draw_orange_bloom(Vector2.ZERO, 1.0, flash)
				"hive_flower":
					_draw_hive_flower(Vector2.ZERO, 1.0, flash)
				"mamba_tree":
					_draw_mamba_tree(Vector2.ZERO, 1.0, flash)
				"chambord_sniper":
					_draw_chambord_sniper(Vector2.ZERO, 1.0, flash)
				"dream_disc":
					_draw_dream_disc(Vector2.ZERO, 1.0, flash)
				"umbrella_leaf":
					_draw_umbrella_leaf(Vector2.ZERO, 1.0, flash)
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
				"sea_shroom":
					_draw_sea_shroom(Vector2.ZERO, 1.0, flash)
				"grave_buster":
					_draw_grave_buster(Vector2.ZERO, 1.0, flash)
				"hypno_shroom":
					_draw_hypno_shroom(Vector2.ZERO, 1.0, flash)
				"scaredy_shroom":
					_draw_scaredy_shroom(Vector2.ZERO, 1.0, flash, _has_close_zombie(center, float(Defs.PLANTS["scaredy_shroom"]["fear_radius"])))
				"plantern":
					_draw_plantern(Vector2.ZERO, 1.0, flash)
				"cactus":
					_draw_cactus(Vector2.ZERO, 1.0, flash)
				"blover":
					_draw_blover(Vector2.ZERO, 1.0, flash)
				"split_pea":
					_draw_split_pea(Vector2.ZERO, 1.0, flash)
				"starfruit":
					_draw_starfruit(Vector2.ZERO, 1.0, flash)
				"pumpkin":
					_draw_pumpkin(Vector2.ZERO, 1.0, flash, clampf(float(plant.get("armor_health", 0.0)) / maxf(float(plant.get("max_armor_health", 1.0)), 1.0), 0.0, 1.0))
				"magnet_shroom":
					_draw_magnet_shroom(Vector2.ZERO, 1.0, flash)
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
				# Gacha plants
				"shadow_pea":
					_draw_shadow_pea(Vector2.ZERO, 1.0, flash)
				"ice_queen":
					_draw_ice_queen(Vector2.ZERO, 1.0, flash)
				"vine_emperor":
					_draw_vine_emperor(Vector2.ZERO, 1.0, flash)
				"soul_flower":
					_draw_soul_flower(Vector2.ZERO, 1.0, flash)
				"plasma_shooter":
					_draw_plasma_shooter(Vector2.ZERO, 1.0, flash)
				"crystal_nut":
					_draw_crystal_nut(Vector2.ZERO, 1.0, flash, float(plant["health"]) / float(plant["max_health"]))
				"dragon_fruit":
					_draw_dragon_fruit(Vector2.ZERO, 1.0, flash)
				"time_rose":
					_draw_time_rose(Vector2.ZERO, 1.0, flash)
				"galaxy_sunflower":
					_draw_galaxy_sunflower(Vector2.ZERO, 1.0, flash)
				"void_shroom":
					_draw_void_shroom(Vector2.ZERO, 1.0, flash)
				"phoenix_tree":
					_draw_phoenix_tree(Vector2.ZERO, 1.0, flash)
				"thunder_god":
					_draw_thunder_god(Vector2.ZERO, 1.0, flash)
				"prism_pea":
					_draw_prism_pea(Vector2.ZERO, 1.0, flash)
				"magnet_daisy":
					_draw_magnet_daisy(Vector2.ZERO, 1.0, flash)
				"thorn_cactus":
					_draw_thorn_cactus(Vector2.ZERO, 1.0, flash)
				"bubble_lotus":
					_draw_bubble_lotus(Vector2.ZERO, 1.0, flash)
				"spiral_bamboo":
					_draw_spiral_bamboo(Vector2.ZERO, 1.0, flash)
				"honey_blossom":
					_draw_honey_blossom(Vector2.ZERO, 1.0, flash)
				"echo_fern":
					_draw_echo_fern(Vector2.ZERO, 1.0, flash)
				"glow_ivy":
					_draw_glow_ivy(Vector2.ZERO, 1.0, flash)
				"laser_lily":
					_draw_laser_lily(Vector2.ZERO, 1.0, flash)
				"rock_armor_fruit":
					_draw_rock_armor_fruit(Vector2.ZERO, 1.0, flash)
				"aurora_orchid":
					_draw_aurora_orchid(Vector2.ZERO, 1.0, flash)
				"blast_pomegranate":
					_draw_blast_pomegranate(Vector2.ZERO, 1.0, flash)
				"frost_cypress":
					_draw_frost_cypress(Vector2.ZERO, 1.0, flash)
				"mirror_shroom":
					_draw_mirror_shroom(Vector2.ZERO, 1.0, flash)
				"chain_lotus":
					_draw_chain_lotus(Vector2.ZERO, 1.0, flash)
				"plasma_shroom":
					_draw_plasma_shroom(Vector2.ZERO, 1.0, flash)
				"meteor_flower":
					_draw_meteor_flower(Vector2.ZERO, 1.0, flash)
				"destiny_tree":
					_draw_destiny_tree(Vector2.ZERO, 1.0, flash)
				"abyss_tentacle":
					_draw_abyss_tentacle(Vector2.ZERO, 1.0, flash)
				"solar_emperor":
					_draw_solar_emperor(Vector2.ZERO, 1.0, flash)
				"shadow_assassin":
					_draw_shadow_assassin(Vector2.ZERO, 1.0, flash)
				"core_blossom":
					_draw_core_blossom(Vector2.ZERO, 1.0, flash)
				"holy_lotus":
					_draw_holy_lotus(Vector2.ZERO, 1.0, flash)
				"chaos_shroom":
					_draw_chaos_shroom(Vector2.ZERO, 1.0, flash)
			if String(plant.get("shell_kind", "")) == "pumpkin" and String(plant["kind"]) != "pumpkin":
				_draw_pumpkin(Vector2.ZERO, 1.0, flash, clampf(float(plant.get("armor_health", 0.0)) / maxf(float(plant.get("max_armor_health", 1.0)), 1.0), 0.0, 1.0), 0.92)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			# Enhancement aura
			_draw_enhancement_aura(draw_center, String(plant["kind"]))
			_draw_click_ultimate_indicator(draw_center, plant)

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
		if projectile_kind == "origami_plane":
			for trail_index in range(3):
				var trail_ratio = float(trail_index + 1) / 3.0
				var trail_center = projectile_pos + Vector2(-trail_dir * trail_ratio * 11.0, -trail_ratio * 2.0)
				draw_polygon(
					PackedVector2Array([
						trail_center + Vector2(0.0, -projectile_radius * 0.72),
						trail_center + Vector2(projectile_radius * 0.86, 0.0),
						trail_center + Vector2(0.0, projectile_radius * 0.72),
						trail_center + Vector2(-projectile_radius * 0.92, 0.0),
					]),
					PackedColorArray([
						Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.16 - trail_ratio * 0.03),
						Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.14 - trail_ratio * 0.03),
						Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.16 - trail_ratio * 0.03),
						Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.14 - trail_ratio * 0.03),
					])
				)
			draw_polygon(
				PackedVector2Array([
					projectile_pos + Vector2(-projectile_radius * 1.18, 0.0),
					projectile_pos + Vector2(0.0, -projectile_radius * 0.92),
					projectile_pos + Vector2(projectile_radius * 1.24, 0.0),
					projectile_pos + Vector2(0.0, projectile_radius * 0.92),
				]),
				PackedColorArray([
					Color(0.96, 0.88, 0.72, 0.92),
					projectile_color,
					Color(0.98, 0.96, 0.86, 0.94),
					projectile_color,
				])
			)
			draw_line(projectile_pos + Vector2(-projectile_radius * 0.9, 0.0), projectile_pos + Vector2(projectile_radius * 0.96, 0.0), Color(0.72, 0.58, 0.38, 0.54), 1.2)
			draw_line(projectile_pos + Vector2(-projectile_radius * 0.14, -projectile_radius * 0.76), projectile_pos + Vector2(-projectile_radius * 0.14, projectile_radius * 0.76), Color(0.72, 0.58, 0.38, 0.54), 1.2)
			continue
		if projectile_kind == "chimney_fire":
			var arc_ratio = clampf(float(projectile.get("arc_time", 0.0)) / maxf(float(projectile.get("arc_duration", 0.42)), 0.01), 0.0, 1.0)
			var lift = sin(arc_ratio * PI)
			for ember_index in range(4):
				var ember_ratio = float(ember_index + 1) / 4.0
				var ember_center = projectile_pos + Vector2(-trail_dir * ember_ratio * 10.0, 8.0 * ember_ratio * lift)
				draw_circle(ember_center, projectile_radius * (0.6 - ember_ratio * 0.08), Color(1.0, 0.66, 0.24, 0.18 - ember_ratio * 0.03))
			draw_circle(projectile_pos, projectile_radius * 1.04, Color(0.96, 0.32, 0.12, 0.94))
			draw_circle(projectile_pos + Vector2(1.0, -1.0), projectile_radius * 0.62, Color(1.0, 0.8, 0.34, 0.86))
			draw_circle(projectile_pos + Vector2(-2.0, -2.0), projectile_radius * 0.3, Color(1.0, 0.96, 0.84, 0.54))
			continue
		if projectile_kind == "boomerang":
			for trail_index in range(3):
				var trail_ratio = float(trail_index + 1) / 3.0
				var trail_center = projectile_pos + Vector2(-trail_dir * trail_ratio * 12.0, 0.0)
				draw_arc(trail_center, projectile_radius * (0.92 - trail_ratio * 0.12), -1.2, 1.2, 14, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.22 - trail_ratio * 0.04), 2.0)
			draw_arc(projectile_pos, projectile_radius, -1.35, 1.35, 18, projectile_color, 3.0)
			draw_circle(projectile_pos + Vector2(2.0 * trail_dir, -1.0), projectile_radius * 0.22, Color(1.0, 0.96, 0.8, 0.58))
			continue
		if projectile_kind == "heather_thorn":
			for trail_index in range(3):
				var trail_ratio = float(trail_index + 1) / 3.0
				var trail_center = projectile_pos + Vector2(-trail_dir * trail_ratio * 10.0, -float(projectile.get("velocity_y", 0.0)) * 0.012 * trail_ratio)
				draw_circle(trail_center, projectile_radius * (0.72 - trail_ratio * 0.1), Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.18 - trail_ratio * 0.04))
			draw_polygon(
				PackedVector2Array([
					projectile_pos + Vector2(projectile_radius * 1.08, 0.0),
					projectile_pos + Vector2(-projectile_radius * 0.5, -projectile_radius * 0.54),
					projectile_pos + Vector2(-projectile_radius * 0.94, 0.0),
					projectile_pos + Vector2(-projectile_radius * 0.5, projectile_radius * 0.54),
				]),
				PackedColorArray([
					Color(0.98, 0.88, 0.98, 0.96),
					projectile_color,
					Color(0.42, 0.08, 0.28, 0.94),
					projectile_color,
				])
			)
			draw_line(projectile_pos + Vector2(-projectile_radius * 0.8, 0.0), projectile_pos + Vector2(projectile_radius * 0.82, 0.0), Color(1.0, 0.96, 1.0, 0.42), 1.2)
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
		if projectile_kind == "angel_spear":
			for trail_index in range(4):
				var trail_ratio = float(trail_index + 1) / 4.0
				var trail_center = projectile_pos + Vector2(-trail_dir * trail_ratio * 14.0, 0.0)
				draw_circle(trail_center, projectile_radius * (0.76 - trail_ratio * 0.12), Color(1.0, 0.9, 0.64, 0.16 - trail_ratio * 0.02))
			draw_polygon(
				PackedVector2Array([
					projectile_pos + Vector2(projectile_radius * 1.5, 0.0),
					projectile_pos + Vector2(-projectile_radius * 0.5, -projectile_radius * 0.5),
					projectile_pos + Vector2(-projectile_radius * 0.9, 0.0),
					projectile_pos + Vector2(-projectile_radius * 0.5, projectile_radius * 0.5),
				]),
				PackedColorArray([
					Color(1.0, 0.96, 0.86, 0.96),
					Color(0.98, 0.8, 0.38, 0.94),
					Color(0.82, 0.56, 0.18, 0.92),
					Color(0.98, 0.8, 0.38, 0.94),
				])
			)
			draw_line(projectile_pos + Vector2(-projectile_radius * 1.1, 0.0), projectile_pos + Vector2(projectile_radius * 1.2, 0.0), Color(0.88, 0.66, 0.22, 0.86), 2.0)
			draw_circle(projectile_pos + Vector2(projectile_radius * 0.2, 0.0), projectile_radius * 0.24, Color(1.0, 1.0, 0.94, 0.62))
			continue
		if projectile_kind == "mist_bloom":
			for trail_index in range(4):
				var trail_ratio = float(trail_index + 1) / 4.0
				draw_circle(projectile_pos + Vector2(-trail_dir * trail_ratio * 8.0, sin(level_time * 5.0 + trail_ratio) * 4.0), projectile_radius * (0.82 - trail_ratio * 0.12), Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.18 - trail_ratio * 0.03))
			draw_circle(projectile_pos, projectile_radius, projectile_color)
			draw_circle(projectile_pos + Vector2(0.0, -2.0), projectile_radius * 0.56, Color(1.0, 1.0, 1.0, 0.34))
			continue
		if projectile_kind == "glow_seed":
			draw_circle(projectile_pos, projectile_radius * 1.12, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.2))
			draw_circle(projectile_pos, projectile_radius, projectile_color)
			draw_arc(projectile_pos, projectile_radius * 1.6, level_time * 6.0, level_time * 6.0 + PI * 1.45, 18, Color(0.92, 1.0, 0.96, 0.34), 1.6)
			continue
		if projectile_kind == "moon_meteor":
			for tail_index in range(4):
				var tail_ratio = float(tail_index + 1) / 4.0
				var tail_center = projectile_pos + Vector2(-trail_dir * tail_ratio * 13.0, -float(projectile.get("velocity_y", 0.0)) * 0.01 * tail_ratio)
				draw_circle(tail_center, projectile_radius * (0.82 - tail_ratio * 0.12), Color(1.0, 0.78, 0.4, 0.18 - tail_ratio * 0.03))
			draw_circle(projectile_pos, projectile_radius, projectile_color)
			draw_circle(projectile_pos + Vector2(-2.0, -2.0), projectile_radius * 0.42, Color(1.0, 0.98, 0.88, 0.46))
			continue
		if projectile_kind == "cabbage" or projectile_kind == "kernel" or projectile_kind == "butter" or projectile_kind == "melon":
			var lift = sin(clampf(float(projectile.get("arc_time", 0.0)) / maxf(float(projectile.get("arc_duration", 0.42)), 0.01), 0.0, 1.0) * PI)
			for trail_index in range(3):
				var trail_ratio = float(trail_index + 1) / 3.0
				var trail_center = projectile_pos + Vector2(-trail_dir * trail_ratio * 8.0, 8.0 * trail_ratio * lift)
				draw_circle(trail_center, projectile_radius * (0.76 - trail_ratio * 0.12), Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.16 - trail_ratio * 0.03))
			if projectile_kind == "melon":
				draw_circle(projectile_pos, projectile_radius * 1.08, Color(0.28, 0.62, 0.18, 0.9))
				draw_arc(projectile_pos, projectile_radius * 0.72, 0.0, TAU, 18, Color(0.16, 0.38, 0.1, 0.72), 1.2)
			elif projectile_kind == "butter":
				draw_rect(Rect2(projectile_pos + Vector2(-projectile_radius, -projectile_radius * 0.72), Vector2(projectile_radius * 2.0, projectile_radius * 1.44)), Color(1.0, 0.9, 0.42, 0.94), true)
				draw_rect(Rect2(projectile_pos + Vector2(-projectile_radius * 0.5, -projectile_radius * 0.4), Vector2(projectile_radius, projectile_radius * 0.8)), Color(1.0, 0.98, 0.72, 0.52), true)
			elif projectile_kind == "kernel":
				draw_circle(projectile_pos, projectile_radius * 0.82, Color(0.98, 0.86, 0.34, 0.96))
			else:
				draw_circle(projectile_pos, projectile_radius, Color(0.58, 0.88, 0.32, 0.96))
			draw_circle(projectile_pos + Vector2(-1.0, -1.0), projectile_radius * 0.28, Color(1.0, 1.0, 1.0, 0.42))
			continue
		for trail_index in range(3):
			var trail_ratio = float(trail_index + 1) / 3.0
			draw_circle(projectile_pos + Vector2(-trail_dir * trail_ratio * 10.0, 0.0), projectile_radius * (0.76 - trail_ratio * 0.14), Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.2 - trail_ratio * 0.04))
		# Outer glow
		draw_circle(projectile_pos, projectile_radius * 1.4, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.08))
		draw_circle(projectile_pos, projectile_radius, projectile_color)
		# Inner highlight
		draw_circle(projectile_pos + Vector2(-2.0, -2.0), projectile_radius * 0.38, Color(1.0, 1.0, 1.0, 0.5))
		# Specular dot
		draw_circle(projectile_pos + Vector2(-1.0, -3.0), projectile_radius * 0.16, Color(1.0, 1.0, 1.0, 0.7))


func _draw_zombies() -> void:
	for zombie in zombies:
		if _is_fog_level() and _is_enemy_zombie(zombie):
			var fog_position = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
			if not _is_position_revealed_by_fog_rules(fog_position):
				continue
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
		# Outer glow
		draw_circle(bob_center, 28.0, Color(1.0, 0.92, 0.3, 0.08))
		draw_circle(bob_center, 22.0, Color(1.0, 0.92, 0.3, 0.12))
		# Rays with varying lengths
		for index in range(12):
			var angle = TAU * float(index) / 12.0 + angle_offset
			var ray_len = 22.0 + sin(level_time * 3.0 + float(index) * 1.1) * 4.0
			var ray_from = bob_center + Vector2(cos(angle), sin(angle)) * 14.0
			var ray_to = bob_center + Vector2(cos(angle), sin(angle)) * ray_len
			draw_line(ray_from, ray_to, Color(1.0, 0.86, 0.24, 0.7), 2.0)
		# Main body
		draw_circle(bob_center, 16.0, Color(1.0, 0.94, 0.42))
		# Inner ring
		draw_circle(bob_center, 10.0, Color(1.0, 0.86, 0.2))
		# Highlight
		draw_circle(bob_center + Vector2(-3.0, -4.0), 5.0, Color(1.0, 1.0, 0.8, 0.5))


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
	for vase in vases:
		var vase_center = _cell_center(int(vase["row"]), int(vase["col"])) + Vector2(0.0, 16.0 + sin(ui_time * 1.6 + float(vase["row"]) * 0.9 + float(vase["col"])) * 1.4)
		_draw_vase(vase_center, 1.0, String(vase.get("content_type", "plant")) == "zombie")
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
		var roller_kind = String(roller.get("kind", "wallnut"))
		var empowered = bool(roller.get("empowered", false))
		if empowered:
			var trail_phase = float(roller.get("trail_phase", 0.0))
			for ghost_index in range(3):
				var ghost_ratio = float(ghost_index + 1) / 3.0
				var ghost_center = center + Vector2(-14.0 - 12.0 * ghost_index, sin(level_time * 8.2 + trail_phase + ghost_index * 0.7) * (3.0 + ghost_index))
				if roller_kind == "mango":
					_draw_mango_bowling(ghost_center, 0.92 - ghost_index * 0.08, 0.0, 0.18 * (1.0 - ghost_ratio), true)
				else:
					_draw_bowling_nut(ghost_center, 0.9 - ghost_index * 0.08, 0.0, 0.18 * (1.0 - ghost_ratio), true)
			draw_circle(center + Vector2(0.0, 6.0), 34.0, Color(0.24, 0.98, 0.76, 0.18))
			draw_arc(center + Vector2(0.0, 6.0), 38.0, level_time * 5.8 + trail_phase, level_time * 5.8 + trail_phase + PI * 1.18, 22, Color(0.92, 1.0, 0.98, 0.58), 2.8)
		if roller_kind == "mango":
			_draw_mango_bowling(center, 0.98 if empowered else 0.92, absf(sin(level_time * 9.0 + float(roller.get("trail_phase", 0.0)))) * 0.16 if empowered else 0.0, 1.0, empowered)
		else:
			_draw_bowling_nut(center, 0.98 if empowered else 0.92, absf(sin(level_time * 9.0 + float(roller.get("trail_phase", 0.0)))) * 0.16 if empowered else 0.0, 1.0, empowered)


func _effect_visual_radius(effect: Dictionary, _ratio: float) -> float:
	return float(effect.get("radius", 0.0))


func _effect_visual_length(effect: Dictionary, _ratio: float) -> float:
	return float(effect.get("length", float(effect.get("radius", 0.0))))


func _effect_visual_width(effect: Dictionary, _ratio: float) -> float:
	return float(effect.get("width", 78.0))


func _draw_effect_blade(tip: Vector2, tail: Vector2, half_width: float, edge_color: Color, core_color: Color) -> void:
	var direction = tip - tail
	var direction_length = maxf(direction.length(), 0.001)
	var forward = direction / direction_length
	var normal = Vector2(-forward.y, forward.x) * half_width
	var shoulder = tail.lerp(tip, 0.22)
	var guard = tail.lerp(tip, 0.12)
	draw_polygon(
		PackedVector2Array([
			tip,
			shoulder + normal,
			tail + normal * 0.28,
			tail - normal * 0.28,
			shoulder - normal,
		]),
		PackedColorArray([core_color, edge_color, edge_color.darkened(0.14), edge_color.darkened(0.14), edge_color])
	)
	draw_line(guard - normal * 0.92, guard + normal * 0.92, Color(0.72, 0.82, 0.92, edge_color.a * 0.82), 1.6)
	draw_line(tail.lerp(tip, 0.16), tip, Color(1.0, 1.0, 1.0, core_color.a * 0.68), 1.2)


func _draw_effect_bat(center: Vector2, scale: float, color: Color, flutter: float) -> void:
	var wing = 11.0 * scale
	var body = 4.5 * scale
	var flap = flutter * 0.32 * scale
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-wing * 1.08, -2.0 * scale + flap),
			center + Vector2(-wing * 0.5, -wing * 0.54 - flap),
			center + Vector2(-body * 0.2, -body * 0.9),
			center + Vector2(0.0, body * 0.36),
			center + Vector2(body * 0.2, -body * 0.9),
			center + Vector2(wing * 0.5, -wing * 0.54 - flap),
			center + Vector2(wing * 1.08, -2.0 * scale + flap),
			center + Vector2(wing * 0.52, wing * 0.18),
			center + Vector2(-wing * 0.52, wing * 0.18),
		]),
		PackedColorArray([color, color, color, color.darkened(0.1), color, color, color, color.darkened(0.08), color.darkened(0.08)])
	)
	draw_circle(center + Vector2(0.0, -body * 0.24), body * 0.34, Color(1.0, 0.78, 0.78, color.a * 0.2))


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
		if shape == "nut_blast":
			var blast_center = Vector2(effect["position"])
			var blast_radius = _effect_visual_radius(effect, ratio)
			draw_circle(blast_center, blast_radius, effect_color)
			draw_circle(blast_center, blast_radius * 0.72, Color(1.0, 1.0, 1.0, effect_color.a * 0.12))
			for ring_index in range(3):
				var ring_angle = level_time * anim_speed + ring_index * 0.86
				draw_arc(blast_center, blast_radius * (0.36 + ring_index * 0.18), ring_angle, ring_angle + PI * 1.24, 24, Color(0.94, 1.0, 0.96, effect_color.a * (0.76 - ring_index * 0.14)), 2.2)
			for shard_index in range(8):
				var shard_ratio = float(shard_index) / 8.0
				var shard_angle = shard_ratio * TAU + level_time * anim_speed * 0.6
				var shard_center = blast_center + Vector2(cos(shard_angle), sin(shard_angle)) * blast_radius * (0.4 + ratio * 0.26)
				draw_circle(shard_center, 3.0 + (1.0 - ratio) * 3.0, Color(1.0, 0.98, 0.9, effect_color.a * 0.72))
			continue
		if shape == "rumia_burst":
			var burst_center = Vector2(effect["position"])
			var burst_radius = _effect_visual_radius(effect, ratio)
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
		if shape == "sakuya_knife_fan":
			var fan_origin = Vector2(effect["position"])
			var fan_length = _effect_visual_length(effect, ratio) * (0.56 + ratio * 0.44)
			var fan_width = _effect_visual_width(effect, ratio)
			var knife_count = max(3, int(effect.get("knife_count", 8)))
			for knife_index in range(knife_count):
				var knife_ratio = 0.5 if knife_count == 1 else float(knife_index) / float(knife_count - 1)
				var spread = lerpf(-0.5, 0.5, knife_ratio)
				var angle = spread * 0.92 + sin(level_time * anim_speed * 0.18 + knife_ratio * 4.8) * 0.05
				var tip = fan_origin + Vector2(-cos(angle) * fan_length, sin(angle) * fan_length * 0.28 + spread * fan_width * 0.72)
				var tail = fan_origin + Vector2(-6.0, spread * fan_width * 0.18)
				_draw_effect_blade(
					tip,
					tail,
					4.8 + (1.0 - absf(spread)) * 2.4,
					Color(0.8, 0.88, 0.96, effect_color.a * 0.92),
					Color(0.98, 1.0, 1.0, effect_color.a)
				)
				draw_line(tail, tip, Color(0.88, 0.96, 1.0, effect_color.a * 0.18), 1.2)
			draw_circle(fan_origin, 16.0, Color(0.92, 0.98, 1.0, effect_color.a * 0.16))
			draw_arc(fan_origin, 28.0 + (1.0 - ratio) * 6.0, -0.58, 0.58, 18, Color(0.88, 0.96, 1.0, effect_color.a * 0.42), 1.8)
			continue
		if shape == "sakuya_knife_rain":
			var rain_points: Array = effect.get("points", [])
			var knife_height = float(effect.get("knife_height", 120.0))
			var rain_count = max(1, int(effect.get("knife_count", 3)))
			for point_variant in rain_points:
				var impact = Vector2(point_variant)
				for knife_index in range(rain_count):
					var spread = (float(knife_index) - float(rain_count - 1) * 0.5) * 12.0
					var fall = knife_height * (0.54 + float(knife_index) * 0.08) * (1.0 - ratio * 0.1)
					var tip = impact + Vector2(spread * 0.1, -6.0)
					var tail = impact + Vector2(spread, -fall - 18.0)
					_draw_effect_blade(
						tip,
						tail,
						3.8 + float(knife_index) * 0.7,
						Color(0.82, 0.9, 0.98, effect_color.a * 0.92),
						Color(1.0, 1.0, 1.0, effect_color.a)
					)
					draw_line(tail + Vector2(0.0, -14.0), tip, Color(0.84, 0.92, 1.0, effect_color.a * 0.16), 1.0)
				draw_circle(impact + Vector2(0.0, 5.0), 12.0, Color(0.92, 0.98, 1.0, effect_color.a * 0.14))
				draw_line(impact + Vector2(-10.0, 6.0), impact + Vector2(10.0, 6.0), Color(0.98, 1.0, 1.0, effect_color.a * 0.22), 1.2)
			continue
		if shape == "sakuya_time_grid":
			var grid_points: Array = effect.get("points", [])
			var has_grid_points = not grid_points.is_empty()
			if grid_points.is_empty():
				grid_points.append(Vector2(effect["position"]))
			for point_variant in grid_points:
				var grid_center = Vector2(point_variant)
				var grid_radius = float(effect.get("radius", 120.0)) * (0.84 + (1.0 - ratio) * 0.22)
				if has_grid_points:
					grid_radius = minf(grid_radius, maxf(18.0, float(effect.get("width", 30.0)) * 1.3))
				var cell_span = clampf(grid_radius * 0.34, 12.0, 44.0)
				draw_circle(grid_center, grid_radius, Color(0.78, 0.88, 1.0, effect_color.a * 0.1))
				draw_circle(grid_center, grid_radius * 0.78, Color(1.0, 1.0, 1.0, effect_color.a * 0.08), false, 2.0)
				for line_index in range(-2, 3):
					var offset = float(line_index) * cell_span
					draw_line(
						grid_center + Vector2(offset, -grid_radius * 0.76),
						grid_center + Vector2(offset, grid_radius * 0.76),
						Color(0.86, 0.94, 1.0, effect_color.a * 0.2),
						1.1
					)
					draw_line(
						grid_center + Vector2(-grid_radius * 0.76, offset),
						grid_center + Vector2(grid_radius * 0.76, offset),
						Color(0.66, 0.78, 0.94, effect_color.a * 0.18),
						1.1
					)
				for tick_index in range(12):
					var tick_angle = level_time * anim_speed * 0.18 + float(tick_index) * TAU / 12.0
					var tick_from = grid_center + Vector2(cos(tick_angle), sin(tick_angle)) * grid_radius * 0.78
					var tick_to = grid_center + Vector2(cos(tick_angle), sin(tick_angle)) * grid_radius * 0.96
					draw_line(tick_from, tick_to, Color(0.98, 1.0, 1.0, effect_color.a * 0.42), 1.4)
				draw_arc(grid_center, grid_radius * 0.52, level_time * anim_speed * 0.22, level_time * anim_speed * 0.22 + PI * 1.28, 22, Color(0.92, 0.98, 1.0, effect_color.a * 0.46), 1.8)
			continue
		if shape == "remilia_scarlet_wave":
			var scarlet_origin = Vector2(effect["position"])
			var scarlet_length = _effect_visual_length(effect, ratio)
			var scarlet_width = _effect_visual_width(effect, ratio)
			var spike_count = max(5, int(effect.get("spike_count", 8)))
			draw_rect(
				Rect2(scarlet_origin + Vector2(0.0, -scarlet_width * 0.38), Vector2(scarlet_length, scarlet_width * 0.76)),
				Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.16),
				true
			)
			for band_index in range(3):
				var band_y = -scarlet_width * 0.24 + float(band_index) * scarlet_width * 0.24 + sin(level_time * anim_speed + float(band_index) * 1.4) * scarlet_width * 0.05
				draw_line(
					scarlet_origin + Vector2(0.0, band_y),
					scarlet_origin + Vector2(scarlet_length, band_y),
					Color(1.0, 0.54, 0.44, effect_color.a * (0.24 + float(band_index) * 0.08)),
					scarlet_width * (0.08 + float(band_index) * 0.04)
				)
			for spike_index in range(spike_count):
				var spike_ratio = float(spike_index) / float(max(1, spike_count - 1))
				var spike_center = scarlet_origin + Vector2(scarlet_length * spike_ratio, sin(level_time * anim_speed * 0.82 + spike_ratio * 7.0) * scarlet_width * 0.12)
				var spike_height = scarlet_width * (0.22 + (1.0 - absf(spike_ratio - 0.5) * 1.7) * 0.18)
				var spike_sign = -1.0 if spike_index % 2 == 0 else 1.0
				draw_polygon(
					PackedVector2Array([
						spike_center + Vector2(-8.0, spike_sign * scarlet_width * 0.12),
						spike_center + Vector2(12.0, spike_sign * spike_height),
						spike_center + Vector2(28.0, 0.0),
						spike_center + Vector2(12.0, -spike_sign * spike_height * 0.32),
					]),
					PackedColorArray([
						Color(0.9, 0.12, 0.18, effect_color.a * 0.82),
						Color(1.0, 0.48, 0.34, effect_color.a),
						Color(1.0, 0.72, 0.54, effect_color.a * 0.88),
						Color(0.9, 0.12, 0.18, effect_color.a * 0.72),
					])
				)
			draw_circle(scarlet_origin + Vector2(scarlet_length, 0.0), scarlet_width * 0.28, Color(1.0, 0.68, 0.52, effect_color.a * 0.84))
			continue
		if shape == "remilia_blood_sigil":
			var sigil_points: Array = effect.get("points", [])
			var has_sigil_points = not sigil_points.is_empty()
			if sigil_points.is_empty():
				sigil_points.append(Vector2(effect["position"]))
			for point_variant in sigil_points:
				var sigil_center = Vector2(point_variant)
				var sigil_radius = float(effect.get("radius", 54.0)) * (0.84 + (1.0 - ratio) * 0.22)
				if has_sigil_points:
					sigil_radius = minf(sigil_radius, 54.0)
				draw_circle(sigil_center, sigil_radius, Color(0.72, 0.04, 0.1, effect_color.a * 0.16))
				draw_circle(sigil_center, sigil_radius * 0.78, Color(1.0, 0.56, 0.5, effect_color.a * 0.1), false, 2.0)
				var outer_points: Array = []
				for rune_index in range(5):
					var outer_angle = level_time * anim_speed * 0.18 - PI * 0.5 + float(rune_index) * TAU / 5.0
					var outer_point = sigil_center + Vector2(cos(outer_angle), sin(outer_angle)) * sigil_radius * 0.8
					outer_points.append(outer_point)
					draw_circle(outer_point, 3.6, Color(1.0, 0.74, 0.62, effect_color.a * 0.76))
				for rune_index in range(5):
					var start = Vector2(outer_points[rune_index])
					var target = Vector2(outer_points[(rune_index + 2) % 5])
					draw_line(start, target, Color(0.98, 0.38, 0.34, effect_color.a * 0.54), 1.6)
				draw_line(sigil_center + Vector2(-sigil_radius * 0.42, 0.0), sigil_center + Vector2(sigil_radius * 0.42, 0.0), Color(1.0, 0.68, 0.54, effect_color.a * 0.42), 1.4)
				draw_line(sigil_center + Vector2(0.0, -sigil_radius * 0.42), sigil_center + Vector2(0.0, sigil_radius * 0.42), Color(0.66, 0.04, 0.12, effect_color.a * 0.32), 1.2)
			continue
		if shape == "remilia_heart_break":
			var heart_origin = Vector2(effect["position"])
			var heart_target = Vector2(effect.get("target", heart_origin))
			var heart_direction = heart_target - heart_origin
			var heart_length = maxf(heart_direction.length(), 1.0)
			var heart_forward = heart_direction / heart_length
			var heart_normal = Vector2(-heart_forward.y, heart_forward.x)
			for band_index in range(3):
				var band_offset = heart_normal * sin(level_time * anim_speed + float(band_index) * 1.4) * 6.0
				draw_line(
					heart_origin + band_offset,
					heart_target + band_offset,
					Color(0.86, 0.04, 0.12, effect_color.a * (0.24 + float(band_index) * 0.12)),
					3.2 - float(band_index) * 0.7
				)
			var heart_center = heart_target
			draw_circle(heart_center + Vector2(-9.0, -7.0), 10.0, Color(0.98, 0.2, 0.28, effect_color.a * 0.7))
			draw_circle(heart_center + Vector2(9.0, -7.0), 10.0, Color(0.98, 0.2, 0.28, effect_color.a * 0.7))
			draw_polygon(
				PackedVector2Array([
					heart_center + Vector2(-18.0, -2.0),
					heart_center + Vector2(0.0, 24.0),
					heart_center + Vector2(18.0, -2.0),
				]),
				PackedColorArray([
					Color(0.92, 0.08, 0.16, effect_color.a * 0.82),
					Color(1.0, 0.42, 0.36, effect_color.a),
					Color(0.92, 0.08, 0.16, effect_color.a * 0.82),
				])
			)
			draw_line(heart_center + Vector2(-4.0, -18.0), heart_center + Vector2(5.0, 20.0), Color(1.0, 0.92, 0.9, effect_color.a * 0.64), 2.0)
			continue
		if shape == "remilia_gungnir_lance":
			var lance_origin = Vector2(effect["position"])
			var lance_target = Vector2(effect.get("target", lance_origin + Vector2.LEFT * 160.0))
			var lance_direction = lance_target - lance_origin
			var lance_length = maxf(lance_direction.length(), 1.0)
			var lance_forward = lance_direction / lance_length
			var lance_normal = Vector2(-lance_forward.y, lance_forward.x)
			for band_index in range(3):
				var trail_width = 8.0 - float(band_index) * 2.0
				var trail_offset = lance_normal * sin(level_time * anim_speed + float(band_index) * 1.2) * 3.6
				draw_line(
					lance_origin + trail_offset,
					lance_target + trail_offset,
					Color(0.84, 0.04, 0.12, effect_color.a * (0.28 + float(band_index) * 0.14)),
					trail_width
				)
			var shaft_base = lance_target - lance_forward * 26.0
			draw_polygon(
				PackedVector2Array([
					lance_target,
					shaft_base + lance_normal * 12.0,
					shaft_base + lance_normal * 3.0,
					lance_target - lance_forward * 8.0,
					shaft_base - lance_normal * 3.0,
					shaft_base - lance_normal * 12.0,
				]),
				PackedColorArray([
					Color(1.0, 0.88, 0.72, effect_color.a),
					Color(1.0, 0.4, 0.26, effect_color.a * 0.92),
					Color(0.86, 0.08, 0.14, effect_color.a * 0.92),
					Color(0.7, 0.02, 0.08, effect_color.a * 0.82),
					Color(0.86, 0.08, 0.14, effect_color.a * 0.92),
					Color(1.0, 0.4, 0.26, effect_color.a * 0.92),
				])
			)
			draw_line(shaft_base, lance_origin, Color(1.0, 0.62, 0.5, effect_color.a * 0.32), 2.0)
			continue
		if shape == "remilia_bat_swarm":
			var swarm_points: Array = effect.get("points", [])
			if swarm_points.is_empty():
				swarm_points.append(Vector2(effect["position"]))
			for point_variant in swarm_points:
				var swarm_center = Vector2(point_variant)
				for bat_index in range(3):
					var bat_angle = level_time * anim_speed * 0.42 + float(bat_index) * TAU / 3.0
					var bat_radius = 12.0 + float(bat_index) * 8.0
					var bat_center = swarm_center + Vector2(cos(bat_angle), sin(bat_angle * 1.3)) * bat_radius
					_draw_effect_bat(bat_center, 0.7 + float(bat_index) * 0.14, Color(0.7, 0.02, 0.08, effect_color.a * (0.68 - float(bat_index) * 0.12)), sin(level_time * anim_speed + float(bat_index)) * 6.0)
				draw_circle(swarm_center, 12.0, Color(0.96, 0.18, 0.24, effect_color.a * 0.12))
			continue
		if shape == "remilia_crimson_field":
			var field_center = Vector2(effect["position"])
			var field_length = float(effect.get("length", board_size.x * 0.8))
			var field_width = float(effect.get("width", board_size.y * 0.88))
			var field_rect = Rect2(field_center - Vector2(field_length * 0.5, field_width * 0.5), Vector2(field_length, field_width))
			draw_rect(field_rect, Color(0.64, 0.02, 0.08, effect_color.a * 0.12), true)
			for ring_index in range(3):
				var ring_radius = float(effect.get("radius", 180.0)) * (0.38 + float(ring_index) * 0.16) * (0.86 + (1.0 - ratio) * 0.18)
				draw_arc(field_center, ring_radius, level_time * anim_speed * 0.14 + float(ring_index), level_time * anim_speed * 0.14 + float(ring_index) + PI * 1.34, 26, Color(1.0, 0.36, 0.32, effect_color.a * (0.42 - float(ring_index) * 0.08)), 2.2)
			for column_index in range(6):
				var column_ratio = float(column_index + 1) / 7.0
				var x = field_rect.position.x + field_rect.size.x * column_ratio
				draw_line(
					Vector2(x, field_rect.position.y + 10.0),
					Vector2(x, field_rect.position.y + field_rect.size.y - 10.0),
					Color(0.86, 0.08, 0.14, effect_color.a * 0.14),
					2.0
				)
			for drop_index in range(8):
				var drop_ratio = float(drop_index) / 7.0
				var drop_center = field_rect.position + Vector2(field_rect.size.x * drop_ratio, field_rect.size.y * (0.24 + 0.52 * absf(sin(level_time * 0.9 + drop_ratio * 4.0))))
				draw_circle(drop_center, 5.0 + float(drop_index % 3), Color(1.0, 0.18, 0.22, effect_color.a * 0.26))
			continue
		if shape == "remilia_meister_barrage":
			var barrage_origin = Vector2(effect["position"])
			var barrage_length = _effect_visual_length(effect, ratio)
			var barrage_width = _effect_visual_width(effect, ratio)
			var barrage_points: Array = effect.get("points", [])
			for lance_index in range(8):
				var lance_ratio = float(lance_index) / 7.0
				var lance_center = barrage_origin + Vector2(barrage_length * lance_ratio, lerpf(-0.42, 0.42, lance_ratio) * barrage_width)
				_draw_effect_blade(
					lance_center + Vector2(28.0, -18.0),
					lance_center + Vector2(-14.0, 18.0),
					5.2,
					Color(0.8, 0.08, 0.14, effect_color.a * 0.82),
					Color(1.0, 0.4, 0.3, effect_color.a)
				)
			for point_variant in barrage_points:
				var barrage_target = Vector2(point_variant)
				draw_circle(barrage_target, 18.0, Color(1.0, 0.26, 0.28, effect_color.a * 0.12))
				draw_line(barrage_target + Vector2(-12.0, 0.0), barrage_target + Vector2(12.0, 0.0), Color(1.0, 0.72, 0.58, effect_color.a * 0.24), 1.8)
				draw_line(barrage_target + Vector2(0.0, -12.0), barrage_target + Vector2(0.0, 12.0), Color(0.72, 0.04, 0.08, effect_color.a * 0.22), 1.4)
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
		if shape == "library_books":
			var book_origin = Vector2(effect["position"])
			var book_length = float(effect.get("length", float(effect.get("radius", 180.0)))) * (0.64 + ratio * 0.36)
			var book_width = float(effect.get("width", 120.0))
			for book_index in range(7):
				var book_ratio = float(book_index) / 6.0
				var book_center = book_origin + Vector2(book_length * book_ratio, sin(level_time * anim_speed + book_ratio * 6.0) * book_width * 0.22)
				var book_size = Vector2(12.0 + (1.0 - book_ratio) * 6.0, 16.0 + (1.0 - ratio) * 5.0)
				draw_rect(Rect2(book_center - book_size * 0.5, book_size), Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * (0.42 + (1.0 - book_ratio) * 0.3)), true)
				draw_line(book_center + Vector2(0.0, -book_size.y * 0.5), book_center + Vector2(0.0, book_size.y * 0.5), Color(1.0, 0.92, 0.86, effect_color.a * 0.38), 1.6)
			continue
		if shape == "arcane_circle":
			var circle_center = Vector2(effect["position"])
			var circle_radius = float(effect.get("radius", 80.0)) * (0.86 + (1.0 - ratio) * 0.24)
			draw_circle(circle_center, circle_radius, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.16))
			draw_circle(circle_center, circle_radius * 0.82, Color(1.0, 1.0, 1.0, effect_color.a * 0.08), false, 2.0)
			for rune_index in range(6):
				var rune_angle = level_time * anim_speed * 0.28 + float(rune_index) * TAU / 6.0
				var rune_center = circle_center + Vector2(cos(rune_angle), sin(rune_angle)) * circle_radius * 0.7
				draw_circle(rune_center, 4.0 + (1.0 - ratio) * 1.8, Color(1.0, 0.92, 0.88, effect_color.a * 0.68))
			for ring_index in range(3):
				draw_arc(circle_center, circle_radius * (0.34 + ring_index * 0.2), level_time * anim_speed * 0.22 + float(ring_index), level_time * anim_speed * 0.22 + float(ring_index) + PI * 1.3, 22, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * (0.8 - ring_index * 0.12)), 2.0)
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
		if shape == "mist_cloud":
			var mist_center = Vector2(effect["position"])
			for puff_index in range(5):
				var puff_ratio = float(puff_index) / 4.0
				var puff_center = mist_center + Vector2((-30.0 + puff_index * 16.0) * ratio, sin(level_time * 3.2 + puff_index) * 8.0)
				draw_circle(puff_center, float(effect["radius"]) * (0.34 + puff_ratio * 0.08), Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * (0.28 - puff_ratio * 0.03)))
			continue
		if shape == "anchor_ring":
			var ring_center = Vector2(effect["position"])
			var ring_radius = float(effect.get("radius", 120.0)) * (0.88 + (1.0 - ratio) * 0.16)
			draw_circle(ring_center, ring_radius, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.12))
			draw_arc(ring_center, ring_radius * 0.72, 0.2, PI - 0.2, 18, effect_color, 3.0)
			draw_line(ring_center + Vector2(0.0, -ring_radius * 0.6), ring_center + Vector2(0.0, ring_radius * 0.2), effect_color, 3.0)
			continue
		if shape == "glow_burst":
			var glow_center = Vector2(effect["position"])
			for orb_index in range(6):
				var angle = level_time * anim_speed * 0.4 + float(orb_index) * TAU / 6.0
				var orb_center = glow_center + Vector2(cos(angle), sin(angle)) * float(effect["radius"]) * 0.42
				draw_circle(orb_center, 8.0 + (1.0 - ratio) * 2.0, Color(0.9, 1.0, 0.92, effect_color.a * 0.74))
			draw_circle(glow_center, float(effect["radius"]) * 0.46, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.18))
			continue
		if shape == "bog_pool":
			var pool_center = Vector2(effect["position"])
			var pool_radius = _effect_visual_radius(effect, ratio)
			draw_circle(pool_center, pool_radius, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.38))
			draw_circle(pool_center + Vector2(-18.0, 4.0), pool_radius * 0.48, Color(0.72, 0.96, 0.88, effect_color.a * 0.14))
			draw_circle(pool_center + Vector2(20.0, -2.0), pool_radius * 0.38, Color(0.72, 0.96, 0.88, effect_color.a * 0.12))
			continue
		if shape == "magma_patch":
			var magma_center = Vector2(effect["position"])
			var magma_radius = _effect_visual_radius(effect, ratio)
			draw_circle(magma_center, magma_radius, Color(1.0, 0.24, 0.06, effect_color.a * 0.42))
			for blob_index in range(4):
				var blob_phase = level_time * 3.2 + float(blob_index) * TAU / 4.0
				var blob_center = magma_center + Vector2(cos(blob_phase) * magma_radius * 0.34, sin(blob_phase * 1.2) * magma_radius * 0.18)
				draw_circle(blob_center, magma_radius * 0.22, Color(1.0, 0.74, 0.28, effect_color.a * 0.3))
			continue
		if shape == "coal_patch":
			var coal_center = Vector2(effect["position"])
			var coal_radius = _effect_visual_radius(effect, ratio)
			draw_circle(coal_center, coal_radius, Color(0.12, 0.12, 0.14, effect_color.a * 0.44))
			for ember_index in range(3):
				var ember_phase = level_time * 4.0 + float(ember_index) * 1.4
				var ember_center = coal_center + Vector2(cos(ember_phase) * coal_radius * 0.3, sin(ember_phase) * coal_radius * 0.16)
				draw_circle(ember_center, coal_radius * 0.12, Color(1.0, 0.36, 0.16, effect_color.a * 0.46))
			continue
		if shape == "wither_patch":
			var wither_center = Vector2(effect["position"])
			var wither_radius = _effect_visual_radius(effect, ratio)
			draw_circle(wither_center, wither_radius, Color(0.28, 0.06, 0.32, effect_color.a * 0.34))
			draw_arc(wither_center, wither_radius * 0.7, level_time * 1.4, level_time * 1.4 + PI * 1.4, 18, Color(0.78, 0.3, 0.96, effect_color.a * 0.42), 1.6)
			continue
		if shape == "storm_arc":
			var arc_origin = Vector2(effect["position"])
			var arc_target = Vector2(effect.get("target", arc_origin))
			var arc_normal = (arc_target - arc_origin).normalized().orthogonal()
			var mid = arc_origin.lerp(arc_target, 0.5) + arc_normal * 18.0 * (1.0 - ratio)
			draw_polyline(PackedVector2Array([arc_origin, mid, arc_target]), Color(0.96, 0.98, 0.68, effect_color.a), 3.0)
			draw_circle(arc_target, 8.0, Color(1.0, 1.0, 0.82, effect_color.a * 0.72))
			continue
		if shape == "moon_blast":
			var moon_center = Vector2(effect["position"])
			var moon_radius = _effect_visual_radius(effect, ratio)
			draw_circle(moon_center, moon_radius, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.2))
			draw_arc(moon_center, moon_radius * 0.74, level_time * 2.6, level_time * 2.6 + PI * 1.4, 24, effect_color, 3.0)
			for spark_index in range(5):
				var spark_angle = level_time * anim_speed * 0.3 + float(spark_index) * TAU / 5.0
				draw_circle(moon_center + Vector2(cos(spark_angle), sin(spark_angle)) * moon_radius * 0.58, 5.0, Color(1.0, 0.96, 0.84, effect_color.a * 0.72))
			continue
		if shape == "tornado_swirl":
			var swirl_center = Vector2(effect["position"])
			for ring_index in range(4):
				var ring_radius = 18.0 + ring_index * 10.0
				draw_arc(swirl_center + Vector2(0.0, 14.0 - ring_index * 8.0), ring_radius, level_time * anim_speed + ring_index * 0.4, level_time * anim_speed + ring_index * 0.4 + PI * 1.25, 22, effect_color, 2.0)
			continue
		if shape == "push_wave":
			var wave_center = Vector2(effect["position"])
			var wave_radius = _effect_visual_radius(effect, ratio)
			draw_rect(Rect2(wave_center + Vector2(-wave_radius * 0.8, -10.0), Vector2(wave_radius * 1.6, 20.0)), Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.24), true)
			draw_circle(wave_center, wave_radius * 0.62, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.18))
			continue
		if shape == "lane_spray":
			var origin = Vector2(effect["position"])
			var length = _effect_visual_length(effect, ratio)
			var width = _effect_visual_width(effect, ratio)
			var plume_length = length
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
		if shape == "patchouli_flare":
			var flare_origin = Vector2(effect["position"])
			var flare_length = _effect_visual_length(effect, ratio)
			var flare_width = _effect_visual_width(effect, ratio)
			for band_index in range(4):
				var band_ratio = float(band_index) / 3.0
				var band_y = sin(level_time * anim_speed + float(band_index) * 1.2) * flare_width * 0.08
				var band_rect = Rect2(flare_origin + Vector2(0.0, -flare_width * 0.42 + flare_width * 0.26 * band_ratio + band_y), Vector2(flare_length, flare_width * (0.2 - band_ratio * 0.02)))
				draw_rect(band_rect, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * (0.28 + band_ratio * 0.12)), true)
			for burst_index in range(10):
				var burst_ratio = float(burst_index + 1) / 10.0
				var burst_center = flare_origin + Vector2(flare_length * burst_ratio, sin(level_time * anim_speed * 1.1 + burst_ratio * 7.0) * flare_width * 0.2)
				draw_circle(burst_center, 4.0 + (1.0 - burst_ratio) * 4.0, Color(1.0, 0.92, 0.72, effect_color.a * (0.54 - burst_ratio * 0.16)))
				draw_circle(burst_center, 9.0, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.12))
			draw_circle(flare_origin + Vector2(flare_length, 0.0), flare_width * 0.24, Color(1.0, 0.94, 0.78, effect_color.a * 0.86))
			continue
		if shape == "squash_slam":
			var slam_radius = _effect_visual_radius(effect, ratio)
			var slam_center = Vector2(effect["position"])
			draw_circle(slam_center, slam_radius, effect_color)
			draw_circle(slam_center, slam_radius * 0.82, Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.26), false, 4.0)
			draw_rect(Rect2(slam_center + Vector2(-slam_radius * 0.86, 12.0), Vector2(slam_radius * 1.72, 8.0)), Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.42), true)
			continue
		var radius = _effect_visual_radius(effect, ratio)
		draw_circle(Vector2(effect["position"]), radius, effect_color)
		draw_circle(Vector2(effect["position"]), radius * (0.72 + 0.18 * ratio), Color(effect_color.r, effect_color.g, effect_color.b, effect_color.a * 0.32), false, 3.0)


func _draw_vfx_particles() -> void:
	for p in vfx_particles:
		var life_ratio = clampf(float(p["life"]) / float(p["max_life"]), 0.0, 1.0)
		var c = Color(p["color"])
		c.a *= life_ratio
		var sz = float(p["size"]) * life_ratio
		draw_circle(Vector2(p["pos"]), sz, c)
		# Fading trail
		draw_circle(Vector2(p["pos"]) - Vector2(p["vel"]).normalized() * sz * 1.5, sz * 0.5, Color(c.r, c.g, c.b, c.a * 0.3))


func _draw_mowers() -> void:
	for mower in mowers:
		if not _is_row_active(int(mower["row"])) and not bool(mower["active"]):
			continue
		var center = Vector2(float(mower["x"]), _row_center_y(int(mower["row"])))
		var wheel_spin = level_time * 10.0 + float(mower["x"]) * 0.02
		var mower_kind = String(mower.get("kind", "pool_cleaner" if _uses_backyard_pool_board() and _is_water_row(int(mower["row"])) else "lawn_mower"))
		if mower_kind == "pool_cleaner":
			var pool_body = Color(0.22, 0.66, 0.92) if bool(mower["armed"]) else Color(0.56, 0.72, 0.86)
			draw_rect(Rect2(center + Vector2(-24.0, -14.0), Vector2(48.0, 22.0)), pool_body, true)
			draw_rect(Rect2(center + Vector2(-18.0, -22.0), Vector2(36.0, 10.0)), Color(0.92, 0.96, 1.0), true)
			draw_circle(center + Vector2(-14.0, 11.0), 8.0, Color(0.16, 0.34, 0.48))
			draw_circle(center + Vector2(14.0, 11.0), 8.0, Color(0.16, 0.34, 0.48))
			draw_line(center + Vector2(-14.0, 11.0), center + Vector2(-14.0 + cos(wheel_spin) * 6.0, 11.0 + sin(wheel_spin) * 6.0), Color(0.88, 0.96, 1.0), 2.0)
			draw_line(center + Vector2(14.0, 11.0), center + Vector2(14.0 + cos(wheel_spin + 0.8) * 6.0, 11.0 + sin(wheel_spin + 0.8) * 6.0), Color(0.88, 0.96, 1.0), 2.0)
			draw_line(center + Vector2(20.0, -8.0), center + Vector2(34.0, -22.0), Color(0.16, 0.34, 0.48), 3.0)
		elif mower_kind == "roof_cleaner":
			var body_color = Color(0.86, 0.42, 0.18) if bool(mower["armed"]) else Color(0.58, 0.56, 0.52)
			var trim = Color(0.96, 0.82, 0.54) if bool(mower["armed"]) else Color(0.76, 0.74, 0.72)
			draw_polygon(
				PackedVector2Array([
					center + Vector2(-26.0, 12.0),
					center + Vector2(-18.0, -12.0),
					center + Vector2(18.0, -16.0),
					center + Vector2(26.0, 8.0),
				]),
				PackedColorArray([body_color, body_color.lightened(0.08), body_color.lightened(0.04), body_color.darkened(0.08)])
			)
			draw_rect(Rect2(center + Vector2(-14.0, -12.0), Vector2(24.0, 10.0)), trim, true)
			draw_circle(center + Vector2(-12.0, 14.0), 7.0, Color(0.16, 0.16, 0.18))
			draw_circle(center + Vector2(12.0, 10.0), 7.0, Color(0.16, 0.16, 0.18))
			draw_line(center + Vector2(-12.0, 14.0), center + Vector2(-12.0 + cos(wheel_spin) * 5.0, 14.0 + sin(wheel_spin) * 5.0), Color(0.76, 0.76, 0.8), 2.0)
			draw_line(center + Vector2(12.0, 10.0), center + Vector2(12.0 + cos(wheel_spin + 0.8) * 5.0, 10.0 + sin(wheel_spin + 0.8) * 5.0), Color(0.76, 0.76, 0.8), 2.0)
			for blade_index in range(3):
				var blade_angle = wheel_spin * 1.2 + float(blade_index) * TAU / 3.0
				draw_line(center + Vector2(20.0, -2.0), center + Vector2(20.0, -2.0) + Vector2(cos(blade_angle), sin(blade_angle)) * 12.0, Color(0.9, 0.92, 0.96), 2.4)
			draw_circle(center + Vector2(20.0, -2.0), 4.0, Color(0.4, 0.42, 0.46))
			draw_line(center + Vector2(-18.0, -12.0), center + Vector2(-28.0, -34.0), Color(0.34, 0.24, 0.16), 3.0)
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
		"mist_orchid":
			_draw_mist_orchid(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"anchor_fern":
			_draw_anchor_fern(center + Vector2(0.0, 7.0), 0.5, 0.0)
		"glowvine":
			_draw_glowvine(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"brine_pot":
			_draw_brine_pot(center + Vector2(0.0, 7.0), 0.5, 0.0)
		"storm_reed":
			_draw_storm_reed(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"moonforge":
			_draw_moonforge(center + Vector2(0.0, 7.0), 0.5, 0.0)
		"mirror_reed":
			_draw_mirror_reed(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"frost_fan":
			_draw_frost_fan(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"cabbage_pult":
			_draw_cabbage_pult(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"flower_pot":
			_draw_flower_pot(center + Vector2(0.0, 12.0), 0.54, 0.0)
		"kernel_pult":
			_draw_kernel_pult(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"coffee_bean":
			_draw_coffee_bean(center + Vector2(0.0, 8.0), 0.54, 0.0)
		"garlic":
			_draw_garlic(center + Vector2(0.0, 10.0), 0.54, 0.0)
		"umbrella_leaf":
			_draw_umbrella_leaf(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"marigold":
			_draw_marigold(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"melon_pult":
			_draw_melon_pult(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"origami_blossom":
			_draw_origami_blossom(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"chimney_pepper":
			_draw_chimney_pepper(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"tesla_tulip":
			_draw_tesla_tulip(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"brick_guard":
			_draw_brick_guard(center + Vector2(0.0, 8.0), 0.5, 0.0, 1.0)
		"signal_ivy":
			_draw_signal_ivy(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"roof_vane":
			_draw_roof_vane(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"skylight_melon":
			_draw_skylight_melon(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"heather_shooter":
			_draw_heather_shooter(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"leyline":
			_draw_leyline(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"holo_nut":
			_draw_holo_nut(center + Vector2(0.0, 8.0), 0.5, 0.0, 1.0)
		"healing_gourd":
			_draw_healing_gourd(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"mango_bowling":
			_draw_mango_bowling(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"snow_bloom":
			_draw_snow_bloom(center + Vector2(0.0, 8.0), 0.5, 0.0, 1.0)
		"cluster_boomerang":
			_draw_cluster_boomerang(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"glitch_walnut":
			_draw_glitch_walnut(center + Vector2(0.0, 8.0), 0.5, 0.0, 1.0)
		"nether_shroom":
			_draw_nether_shroom(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"seraph_flower":
			_draw_seraph_flower(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"magma_stream":
			_draw_magma_stream(center + Vector2(0.0, 8.0), 0.5, 0.0, 1.0)
		"orange_bloom":
			_draw_orange_bloom(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"hive_flower":
			_draw_hive_flower(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"mamba_tree":
			_draw_mamba_tree(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"chambord_sniper":
			_draw_chambord_sniper(center + Vector2(0.0, 8.0), 0.5, 0.0)
		"dream_disc":
			_draw_dream_disc(center + Vector2(0.0, 8.0), 0.5, 0.0)
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
		"sea_shroom":
			_draw_sea_shroom(center + Vector2(0.0, 10.0), 0.52, 0.0)
		"fume_shroom":
			_draw_fume_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"grave_buster":
			_draw_grave_buster(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"hypno_shroom":
			_draw_hypno_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"scaredy_shroom":
			_draw_scaredy_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0, false)
		"plantern":
			_draw_plantern(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"cactus":
			_draw_cactus(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"blover":
			_draw_blover(center + Vector2(0.0, 8.0), 0.52, 0.0)
		"split_pea":
			_draw_split_pea(center + Vector2(0.0, 6.0), 0.5, 0.0)
		"starfruit":
			_draw_starfruit(center + Vector2(0.0, 6.0), 0.52, 0.0)
		"pumpkin":
			_draw_pumpkin(center + Vector2(0.0, 8.0), 0.52, 0.0, 1.0)
		"magnet_shroom":
			_draw_magnet_shroom(center + Vector2(0.0, 8.0), 0.52, 0.0)
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
		# Gacha plants
		"shadow_pea":
			_draw_shadow_pea(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"ice_queen":
			_draw_ice_queen(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"vine_emperor":
			_draw_vine_emperor(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"soul_flower":
			_draw_soul_flower(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"plasma_shooter":
			_draw_plasma_shooter(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"crystal_nut":
			_draw_crystal_nut(center + Vector2(0.0, 8.0), 0.52, 0.0, 1.0)
		"dragon_fruit":
			_draw_dragon_fruit(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"time_rose":
			_draw_time_rose(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"galaxy_sunflower":
			_draw_galaxy_sunflower(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"void_shroom":
			_draw_void_shroom(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"phoenix_tree":
			_draw_phoenix_tree(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"thunder_god":
			_draw_thunder_god(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"prism_pea":
			_draw_prism_pea(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"magnet_daisy":
			_draw_magnet_daisy(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"thorn_cactus":
			_draw_thorn_cactus(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"bubble_lotus":
			_draw_bubble_lotus(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"spiral_bamboo":
			_draw_spiral_bamboo(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"honey_blossom":
			_draw_honey_blossom(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"echo_fern":
			_draw_echo_fern(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"glow_ivy":
			_draw_glow_ivy(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"laser_lily":
			_draw_laser_lily(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"rock_armor_fruit":
			_draw_rock_armor_fruit(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"aurora_orchid":
			_draw_aurora_orchid(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"blast_pomegranate":
			_draw_blast_pomegranate(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"frost_cypress":
			_draw_frost_cypress(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"mirror_shroom":
			_draw_mirror_shroom(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"chain_lotus":
			_draw_chain_lotus(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"plasma_shroom":
			_draw_plasma_shroom(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"meteor_flower":
			_draw_meteor_flower(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"destiny_tree":
			_draw_destiny_tree(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"abyss_tentacle":
			_draw_abyss_tentacle(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"solar_emperor":
			_draw_solar_emperor(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"shadow_assassin":
			_draw_shadow_assassin(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"core_blossom":
			_draw_core_blossom(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"holy_lotus":
			_draw_holy_lotus(center + Vector2(0.0, 4.0), 0.52, 0.0)
		"chaos_shroom":
			_draw_chaos_shroom(center + Vector2(0.0, 4.0), 0.52, 0.0)


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
		"mist_orchid":
			_draw_mist_orchid(center, 1.0, 0.0, 0.42)
		"anchor_fern":
			_draw_anchor_fern(center, 1.0, 0.0, 0.42)
		"glowvine":
			_draw_glowvine(center, 1.0, 0.0, 0.42)
		"brine_pot":
			_draw_brine_pot(center, 1.0, 0.0, 0.42)
		"storm_reed":
			_draw_storm_reed(center, 1.0, 0.0, 0.42)
		"moonforge":
			_draw_moonforge(center, 1.0, 0.0, 0.42)
		"mirror_reed":
			_draw_mirror_reed(center, 1.0, 0.0, 0.42)
		"frost_fan":
			_draw_frost_fan(center, 1.0, 0.0, 0.42)
		"cabbage_pult":
			_draw_cabbage_pult(center, 1.0, 0.0, 0.42)
		"flower_pot":
			_draw_flower_pot(center + Vector2(0.0, 8.0), 1.0, 0.0, 0.42)
		"kernel_pult":
			_draw_kernel_pult(center, 1.0, 0.0, 0.42)
		"coffee_bean":
			_draw_coffee_bean(center, 1.0, 0.0, 0.42)
		"garlic":
			_draw_garlic(center, 1.0, 0.0, 0.42)
		"umbrella_leaf":
			_draw_umbrella_leaf(center, 1.0, 0.0, 0.42)
		"marigold":
			_draw_marigold(center, 1.0, 0.0, 0.42)
		"melon_pult":
			_draw_melon_pult(center, 1.0, 0.0, 0.42)
		"origami_blossom":
			_draw_origami_blossom(center, 1.0, 0.0, 0.42)
		"chimney_pepper":
			_draw_chimney_pepper(center, 1.0, 0.0, 0.42)
		"tesla_tulip":
			_draw_tesla_tulip(center, 1.0, 0.0, 0.42)
		"brick_guard":
			_draw_brick_guard(center, 1.0, 0.0, 1.0, 0.42)
		"signal_ivy":
			_draw_signal_ivy(center, 1.0, 0.0, 0.42)
		"roof_vane":
			_draw_roof_vane(center, 1.0, 0.0, 0.42)
		"skylight_melon":
			_draw_skylight_melon(center, 1.0, 0.0, 0.42)
		"heather_shooter":
			_draw_heather_shooter(center, 1.0, 0.0, 0.42)
		"leyline":
			_draw_leyline(center, 1.0, 0.0, 0.42)
		"holo_nut":
			_draw_holo_nut(center, 1.0, 0.0, 1.0, 0.42)
		"healing_gourd":
			_draw_healing_gourd(center, 1.0, 0.0, 0.42)
		"mango_bowling":
			_draw_mango_bowling(center, 1.0, 0.0, 0.42)
		"snow_bloom":
			_draw_snow_bloom(center, 1.0, 0.0, 1.0, 0.42)
		"cluster_boomerang":
			_draw_cluster_boomerang(center, 1.0, 0.0, 0.42)
		"glitch_walnut":
			_draw_glitch_walnut(center, 1.0, 0.0, 1.0, 0.42)
		"nether_shroom":
			_draw_nether_shroom(center, 1.0, 0.0, 0.42)
		"seraph_flower":
			_draw_seraph_flower(center, 1.0, 0.0, 0.42)
		"magma_stream":
			_draw_magma_stream(center, 1.0, 0.0, 1.0, 0.42)
		"orange_bloom":
			_draw_orange_bloom(center, 1.0, 0.0, 0.42)
		"hive_flower":
			_draw_hive_flower(center, 1.0, 0.0, 0.42)
		"mamba_tree":
			_draw_mamba_tree(center, 1.0, 0.0, 0.42)
		"chambord_sniper":
			_draw_chambord_sniper(center, 1.0, 0.0, 0.42)
		"dream_disc":
			_draw_dream_disc(center, 1.0, 0.0, 0.42)
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
		"sea_shroom":
			_draw_sea_shroom(center, 1.0, 0.0, 0.42)
		"fume_shroom":
			_draw_fume_shroom(center, 1.0, 0.0, 0.42)
		"grave_buster":
			_draw_grave_buster(center, 1.0, 0.0, 0.42)
		"hypno_shroom":
			_draw_hypno_shroom(center, 1.0, 0.0, 0.42)
		"scaredy_shroom":
			_draw_scaredy_shroom(center, 1.0, 0.0, false, 0.42)
		"plantern":
			_draw_plantern(center, 1.0, 0.0, 0.42)
		"cactus":
			_draw_cactus(center, 1.0, 0.0, 0.42)
		"blover":
			_draw_blover(center, 1.0, 0.0, 0.42)
		"split_pea":
			_draw_split_pea(center, 1.0, 0.0, 0.42)
		"starfruit":
			_draw_starfruit(center, 1.0, 0.0, 0.42)
		"pumpkin":
			_draw_pumpkin(center, 1.0, 0.0, 1.0, 0.42)
		"magnet_shroom":
			_draw_magnet_shroom(center, 1.0, 0.0, 0.42)
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
	# Shadow under plant
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	# Stem with slight curve
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(-2.0 * size_scale, 34.0 * size_scale), Color(0.2, 0.52, 0.16, alpha), 6.0 * size_scale)
	# Leaves with vein
	draw_circle(center + Vector2(-13.0 * size_scale, 18.0 * size_scale), 9.0 * size_scale, Color(0.28, 0.7, 0.22, alpha))
	draw_circle(center + Vector2(-13.0 * size_scale, 18.0 * size_scale), 7.0 * size_scale, Color(0.32, 0.74, 0.26, alpha))
	draw_circle(center + Vector2(13.0 * size_scale, 18.0 * size_scale), 9.0 * size_scale, Color(0.28, 0.7, 0.22, alpha))
	draw_circle(center + Vector2(13.0 * size_scale, 18.0 * size_scale), 7.0 * size_scale, Color(0.32, 0.74, 0.26, alpha))
	# Outer petals (darker layer)
	for index in range(10):
		var angle = TAU * float(index) / 10.0 + 0.16
		draw_circle(core_center + Vector2(cos(angle), sin(angle)) * 23.0 * size_scale, 9.0 * size_scale, petal_color.darkened(0.12))
	# Inner petals
	for index in range(10):
		var angle = TAU * float(index) / 10.0
		draw_circle(core_center + Vector2(cos(angle), sin(angle)) * 21.0 * size_scale, 9.0 * size_scale, petal_color)
	# Petal highlights
	for index in range(5):
		var angle = TAU * float(index) / 5.0 - 0.3
		draw_circle(core_center + Vector2(cos(angle), sin(angle)) * 18.0 * size_scale, 4.0 * size_scale, Color(1.0, 0.94, 0.5, 0.3 * alpha))
	# Core
	draw_circle(core_center, 17.0 * size_scale, Color(0.43, 0.22, 0.08, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(core_center, 13.0 * size_scale, Color(0.48, 0.26, 0.1, alpha))
	# Core highlight
	draw_circle(core_center + Vector2(-4.0 * size_scale, -4.0 * size_scale), 5.0 * size_scale, Color(0.56, 0.32, 0.14, alpha))
	# Eyes
	draw_circle(core_center + Vector2(-5.0 * size_scale, -4.0 * size_scale), 2.4 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_circle(core_center + Vector2(5.0 * size_scale, -4.0 * size_scale), 2.4 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	# Eye highlights
	draw_circle(core_center + Vector2(-4.0 * size_scale, -5.0 * size_scale), 1.0 * size_scale, Color(1.0, 1.0, 1.0, 0.6 * alpha))
	draw_circle(core_center + Vector2(6.0 * size_scale, -5.0 * size_scale), 1.0 * size_scale, Color(1.0, 1.0, 1.0, 0.6 * alpha))
	# Smile
	draw_arc(core_center + Vector2(0.0, 2.0 * size_scale), 6.0 * size_scale, 0.1, PI - 0.1, 12, Color(0.06, 0.06, 0.06, alpha), 2.0 * size_scale)


func _draw_peashooter(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.43, 0.83, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.2)
	# Shadow
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	# Stem
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(-1.0 * size_scale, 33.0 * size_scale), Color(0.2, 0.5, 0.14, alpha), 7.0 * size_scale)
	# Stem highlight
	draw_line(center + Vector2(-2.0 * size_scale, 10.0 * size_scale), center + Vector2(-3.0 * size_scale, 30.0 * size_scale), Color(0.28, 0.58, 0.2, alpha), 2.0 * size_scale)
	# Leaves
	draw_circle(center + Vector2(-14.0 * size_scale, 20.0 * size_scale), 9.0 * size_scale, Color(0.27, 0.72, 0.22, alpha))
	draw_circle(center + Vector2(-14.0 * size_scale, 20.0 * size_scale), 6.0 * size_scale, Color(0.32, 0.76, 0.26, alpha))
	draw_circle(center + Vector2(16.0 * size_scale, 18.0 * size_scale), 9.0 * size_scale, Color(0.27, 0.72, 0.22, alpha))
	draw_circle(center + Vector2(16.0 * size_scale, 18.0 * size_scale), 6.0 * size_scale, Color(0.32, 0.76, 0.26, alpha))
	# Head
	var head = center + Vector2(-2.0 * size_scale, -10.0 * size_scale)
	draw_circle(head, 20.0 * size_scale, body_color)
	# Head highlight
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 8.0 * size_scale, Color(0.52, 0.9, 0.38, alpha))
	# Barrel
	draw_circle(head + Vector2(24.0 * size_scale, 0.0), 11.0 * size_scale, body_color.darkened(0.06))
	draw_circle(head + Vector2(24.0 * size_scale, 0.0), 8.0 * size_scale, body_color.darkened(0.02))
	# Barrel opening
	draw_circle(head + Vector2(31.0 * size_scale, 0.0), 5.0 * size_scale, Color(0.18, 0.42, 0.12, alpha))
	draw_circle(head + Vector2(31.0 * size_scale, 0.0), 3.0 * size_scale, Color(0.12, 0.32, 0.08, alpha))
	# Eye
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(0.05, 0.05, 0.05, alpha))
	draw_circle(head + Vector2(-5.0 * size_scale, -7.0 * size_scale), 1.2 * size_scale, Color(1.0, 1.0, 1.0, 0.6 * alpha))
	# Lip/chin
	draw_circle(head + Vector2(-10.0 * size_scale, 10.0 * size_scale), 10.0 * size_scale, Color(0.24, 0.66, 0.2, alpha))
	draw_circle(head + Vector2(-10.0 * size_scale, 10.0 * size_scale), 7.0 * size_scale, Color(0.28, 0.7, 0.24, alpha))


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


func _draw_sea_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_arc(center + Vector2(0.0, 18.0 * size_scale), 26.0 * size_scale, PI * 0.06, PI * 0.94, 18, Color(0.22, 0.66, 0.72, alpha * 0.74), 5.0 * size_scale)
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 30.0 * size_scale), Color(0.78, 0.92, 0.96, alpha), 5.5 * size_scale)
	var cap_center = center + Vector2(0.0, -6.0 * size_scale)
	draw_circle(cap_center, 18.0 * size_scale, Color(0.42, 0.78, 0.9, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(cap_center + Vector2(10.0 * size_scale, -1.0 * size_scale), 8.0 * size_scale, Color(0.64, 0.92, 1.0, alpha))
	draw_circle(cap_center + Vector2(-5.0 * size_scale, -4.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(cap_center + Vector2(4.0 * size_scale, -4.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-14.0 * size_scale, 10.0 * size_scale), 3.4 * size_scale, Color(0.72, 0.96, 1.0, alpha * 0.6))
	draw_circle(center + Vector2(15.0 * size_scale, 14.0 * size_scale), 2.8 * size_scale, Color(0.72, 0.96, 1.0, alpha * 0.46))


func _draw_plantern(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.16, alpha), 6.0 * size_scale)
	draw_circle(center + Vector2(-12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.3, 0.72, 0.24, alpha))
	draw_circle(center + Vector2(12.0 * size_scale, 20.0 * size_scale), 8.0 * size_scale, Color(0.3, 0.72, 0.24, alpha))
	var lantern_center = center + Vector2(0.0, -6.0 * size_scale)
	draw_circle(lantern_center, 24.0 * size_scale, Color(0.96, 0.96, 0.54, alpha * 0.12 + flash * 0.12))
	draw_rect(Rect2(lantern_center + Vector2(-16.0 * size_scale, -12.0 * size_scale), Vector2(32.0 * size_scale, 28.0 * size_scale)), Color(0.96, 0.88, 0.38, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0), true)
	draw_rect(Rect2(lantern_center + Vector2(-20.0 * size_scale, -18.0 * size_scale), Vector2(40.0 * size_scale, 8.0 * size_scale)), Color(0.22, 0.46, 0.18, alpha), true)
	draw_rect(Rect2(lantern_center + Vector2(-20.0 * size_scale, 12.0 * size_scale), Vector2(40.0 * size_scale, 8.0 * size_scale)), Color(0.22, 0.46, 0.18, alpha), true)
	draw_line(lantern_center + Vector2(-12.0 * size_scale, -18.0 * size_scale), lantern_center + Vector2(-12.0 * size_scale, 20.0 * size_scale), Color(0.24, 0.42, 0.18, alpha), 2.0 * size_scale)
	draw_line(lantern_center + Vector2(12.0 * size_scale, -18.0 * size_scale), lantern_center + Vector2(12.0 * size_scale, 20.0 * size_scale), Color(0.24, 0.42, 0.18, alpha), 2.0 * size_scale)


func _draw_cactus(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.26, 0.74, 0.28, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_rect(Rect2(center + Vector2(-12.0 * size_scale, -22.0 * size_scale), Vector2(24.0 * size_scale, 58.0 * size_scale)), body_color, true)
	draw_circle(center + Vector2(0.0, -22.0 * size_scale), 12.0 * size_scale, body_color)
	draw_rect(Rect2(center + Vector2(-26.0 * size_scale, -4.0 * size_scale), Vector2(12.0 * size_scale, 24.0 * size_scale)), body_color.darkened(0.06), true)
	draw_circle(center + Vector2(-20.0 * size_scale, -4.0 * size_scale), 6.0 * size_scale, body_color.darkened(0.06))
	draw_rect(Rect2(center + Vector2(14.0 * size_scale, -10.0 * size_scale), Vector2(12.0 * size_scale, 26.0 * size_scale)), body_color.darkened(0.04), true)
	draw_circle(center + Vector2(20.0 * size_scale, -10.0 * size_scale), 6.0 * size_scale, body_color.darkened(0.04))
	for spike_x in [-10.0, -4.0, 4.0, 10.0]:
		draw_line(center + Vector2(spike_x * size_scale, -18.0 * size_scale), center + Vector2((spike_x - 4.0) * size_scale, -26.0 * size_scale), Color(0.98, 0.94, 0.82, alpha), 1.8 * size_scale)
		draw_line(center + Vector2(spike_x * size_scale, 2.0 * size_scale), center + Vector2((spike_x + 4.0) * size_scale, -6.0 * size_scale), Color(0.98, 0.94, 0.82, alpha), 1.8 * size_scale)
	draw_circle(center + Vector2(0.0, -32.0 * size_scale), 5.0 * size_scale, Color(0.94, 0.48, 0.82, alpha))
	draw_circle(center + Vector2(-4.0 * size_scale, -8.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -8.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_blover(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.24, 0.58, 0.2, alpha), 5.0 * size_scale)
	for offset in [Vector2(-12.0, -6.0), Vector2(12.0, -6.0), Vector2(-8.0, 8.0), Vector2(8.0, 8.0)]:
		draw_circle(center + offset * size_scale, 10.0 * size_scale, Color(0.54, 0.88, 0.34, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_circle(center + Vector2(0.0, 1.0 * size_scale), 5.0 * size_scale, Color(0.42, 0.76, 0.28, alpha))
	draw_arc(center + Vector2(20.0 * size_scale, -2.0 * size_scale), 18.0 * size_scale, -1.1, 1.1, 18, Color(0.86, 0.98, 0.94, alpha * 0.42), 2.4 * size_scale)
	draw_arc(center + Vector2(30.0 * size_scale, -2.0 * size_scale), 12.0 * size_scale, -1.0, 1.0, 16, Color(0.86, 0.98, 0.94, alpha * 0.32), 2.0 * size_scale)


func _draw_split_pea(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	_draw_peashooter(center + Vector2(-4.0 * size_scale, 0.0), size_scale, flash, alpha)
	var rear_head = center + Vector2(-24.0 * size_scale, -10.0 * size_scale)
	var body_color = Color(0.34, 0.78, 0.24, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(rear_head, 12.0 * size_scale, body_color)
	draw_circle(rear_head + Vector2(-14.0 * size_scale, 0.0), 6.0 * size_scale, body_color.darkened(0.06))
	draw_circle(rear_head + Vector2(4.0 * size_scale, -4.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_starfruit(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.56, 0.18, alpha), 6.0 * size_scale)
	var star_center = center + Vector2(0.0, -8.0 * size_scale)
	var star_points = PackedVector2Array()
	var star_colors = PackedColorArray()
	var star_fill = Color(1.0, 0.86, 0.28, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	for point_index in range(10):
		var angle = -PI * 0.5 + TAU * float(point_index) / 10.0
		var radius = 22.0 if point_index % 2 == 0 else 9.0
		star_points.append(star_center + Vector2(cos(angle), sin(angle)) * radius * size_scale)
		star_colors.append(star_fill)
	draw_polygon(star_points, star_colors)
	draw_circle(star_center + Vector2(-5.0 * size_scale, -4.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(star_center + Vector2(5.0 * size_scale, -4.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_arc(star_center + Vector2(0.0, 3.0 * size_scale), 5.0 * size_scale, 0.2, PI - 0.2, 12, Color(0.52, 0.3, 0.08, alpha), 2.0 * size_scale)


func _draw_pumpkin(center: Vector2, size_scale: float, flash: float, ratio: float, alpha: float = 1.0) -> void:
	var shell_color = Color(0.96, 0.54, 0.16, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	draw_circle(center + Vector2(0.0, 4.0 * size_scale), 24.0 * size_scale, shell_color)
	draw_circle(center + Vector2(-14.0 * size_scale, 4.0 * size_scale), 18.0 * size_scale, shell_color.darkened(0.04))
	draw_circle(center + Vector2(14.0 * size_scale, 4.0 * size_scale), 18.0 * size_scale, shell_color.darkened(0.04))
	draw_rect(Rect2(center + Vector2(-6.0 * size_scale, -28.0 * size_scale), Vector2(12.0 * size_scale, 10.0 * size_scale)), Color(0.24, 0.56, 0.16, alpha), true)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-14.0 * size_scale, -2.0 * size_scale),
			center + Vector2(-4.0 * size_scale, 8.0 * size_scale),
			center + Vector2(-18.0 * size_scale, 12.0 * size_scale),
		]),
		PackedColorArray([Color(0.16, 0.08, 0.02, alpha), Color(0.16, 0.08, 0.02, alpha), Color(0.16, 0.08, 0.02, alpha)])
	)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(14.0 * size_scale, -2.0 * size_scale),
			center + Vector2(4.0 * size_scale, 8.0 * size_scale),
			center + Vector2(18.0 * size_scale, 12.0 * size_scale),
		]),
		PackedColorArray([Color(0.16, 0.08, 0.02, alpha), Color(0.16, 0.08, 0.02, alpha), Color(0.16, 0.08, 0.02, alpha)])
	)
	draw_arc(center + Vector2(0.0, 12.0 * size_scale), 10.0 * size_scale, 0.16, PI - 0.16, 14, Color(0.16, 0.08, 0.02, alpha), 3.0 * size_scale)
	if ratio < 0.65:
		draw_line(center + Vector2(-8.0 * size_scale, -16.0 * size_scale), center + Vector2(2.0 * size_scale, 6.0 * size_scale), Color(0.58, 0.18, 0.06, alpha), 2.0 * size_scale)
	if ratio < 0.35:
		draw_line(center + Vector2(10.0 * size_scale, -14.0 * size_scale), center + Vector2(0.0, 18.0 * size_scale), Color(0.58, 0.18, 0.06, alpha), 2.2 * size_scale)


func _draw_magnet_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.82, 0.82, 0.72, alpha), 6.0 * size_scale)
	var cap_center = center + Vector2(0.0, -6.0 * size_scale)
	draw_circle(cap_center, 18.0 * size_scale, Color(0.68, 0.46, 0.9, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0))
	draw_arc(cap_center + Vector2(0.0, -6.0 * size_scale), 12.0 * size_scale, PI * 0.1, PI * 0.9, 18, Color(0.94, 0.22, 0.24, alpha), 4.0 * size_scale)
	draw_rect(Rect2(cap_center + Vector2(-14.0 * size_scale, -8.0 * size_scale), Vector2(6.0 * size_scale, 16.0 * size_scale)), Color(0.94, 0.22, 0.24, alpha), true)
	draw_rect(Rect2(cap_center + Vector2(8.0 * size_scale, -8.0 * size_scale), Vector2(6.0 * size_scale, 16.0 * size_scale)), Color(0.54, 0.72, 1.0, alpha), true)
	draw_circle(cap_center + Vector2(-4.0 * size_scale, -6.0 * size_scale), 2.0 * size_scale, Color(1.0, 0.94, 0.58, alpha * 0.8))
	draw_circle(cap_center + Vector2(4.0 * size_scale, -6.0 * size_scale), 2.0 * size_scale, Color(1.0, 0.94, 0.58, alpha * 0.8))


func _draw_grave(center: Vector2, size_scale: float, alpha: float = 1.0) -> void:
	draw_rect(Rect2(center + Vector2(-18.0 * size_scale, -26.0 * size_scale), Vector2(36.0 * size_scale, 42.0 * size_scale)), Color(0.48, 0.5, 0.58, alpha), true)
	draw_arc(center + Vector2(0.0, -26.0 * size_scale), 18.0 * size_scale, PI, TAU, 18, Color(0.48, 0.5, 0.58, alpha), 36.0 * size_scale)
	draw_rect(Rect2(center + Vector2(-20.0 * size_scale, 14.0 * size_scale), Vector2(40.0 * size_scale, 8.0 * size_scale)), Color(0.36, 0.3, 0.26, alpha), true)
	draw_line(center + Vector2(-8.0 * size_scale, -12.0 * size_scale), center + Vector2(8.0 * size_scale, -12.0 * size_scale), Color(0.8, 0.82, 0.88, alpha), 3.0 * size_scale)
	draw_line(center + Vector2(0.0, -20.0 * size_scale), center + Vector2(0.0, -4.0 * size_scale), Color(0.8, 0.82, 0.88, alpha), 3.0 * size_scale)


func _draw_vase(center: Vector2, size_scale: float, hostile: bool, alpha: float = 1.0) -> void:
	var shell_color = Color(0.82, 0.78, 0.96, alpha) if hostile else Color(0.86, 0.94, 1.0, alpha)
	var accent_color = Color(0.64, 0.36, 0.86, alpha) if hostile else Color(0.32, 0.64, 0.94, alpha)
	draw_arc(center + Vector2(0.0, -18.0 * size_scale), 20.0 * size_scale, PI, TAU, 20, shell_color, 16.0 * size_scale)
	draw_rect(Rect2(center + Vector2(-20.0 * size_scale, -18.0 * size_scale), Vector2(40.0 * size_scale, 42.0 * size_scale)), shell_color, true)
	draw_rect(Rect2(center + Vector2(-22.0 * size_scale, 20.0 * size_scale), Vector2(44.0 * size_scale, 8.0 * size_scale)), shell_color.darkened(0.08), true)
	draw_line(center + Vector2(-12.0 * size_scale, -6.0 * size_scale), center + Vector2(12.0 * size_scale, -6.0 * size_scale), accent_color, 3.0 * size_scale)
	draw_arc(center + Vector2(0.0, 6.0 * size_scale), 11.0 * size_scale, 0.1, PI - 0.1, 16, accent_color, 2.0 * size_scale)
	draw_circle(center + Vector2(0.0, -18.0 * size_scale), 4.0 * size_scale, accent_color)


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


func _draw_mist_orchid(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var stem = Color(0.28, 0.56, 0.24, alpha)
	var petal = Color(0.88, 0.98, 0.96, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	var mist = Color(0.7, 0.92, 0.9, alpha * 0.6)
	draw_line(center + Vector2(-4.0 * size_scale, 12.0 * size_scale), center + Vector2(-6.0 * size_scale, 34.0 * size_scale), stem, 5.0 * size_scale)
	draw_line(center + Vector2(6.0 * size_scale, 10.0 * size_scale), center + Vector2(8.0 * size_scale, 34.0 * size_scale), stem, 4.0 * size_scale)
	for petal_center in [Vector2(-12.0, -10.0), Vector2(0.0, -18.0), Vector2(12.0, -10.0), Vector2(0.0, 0.0)]:
		draw_circle(center + petal_center * size_scale, 10.0 * size_scale, petal)
	draw_circle(center + Vector2(0.0, -8.0 * size_scale), 6.0 * size_scale, Color(0.5, 0.76, 0.62, alpha))
	draw_circle(center + Vector2(-18.0 * size_scale, -20.0 * size_scale), 8.0 * size_scale, mist)
	draw_circle(center + Vector2(18.0 * size_scale, -24.0 * size_scale), 10.0 * size_scale, mist)
	draw_circle(center + Vector2(-4.0 * size_scale, -12.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -12.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_anchor_fern(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var fern = Color(0.34, 0.72, 0.28, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.7)
	var anchor = Color(0.52, 0.6, 0.66, alpha)
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.5, 0.18, alpha), 5.0 * size_scale)
	for index in range(4):
		var angle = -1.9 + float(index) * 0.55
		var tip = center + Vector2(cos(angle), sin(angle)) * 24.0 * size_scale
		draw_line(center + Vector2(0.0, 6.0 * size_scale), tip, fern, 4.0 * size_scale)
	draw_line(center + Vector2(18.0 * size_scale, -8.0 * size_scale), center + Vector2(18.0 * size_scale, 12.0 * size_scale), anchor, 4.0 * size_scale)
	draw_arc(center + Vector2(18.0 * size_scale, 10.0 * size_scale), 9.0 * size_scale, 0.2, PI - 0.2, 14, anchor, 3.0 * size_scale)
	draw_line(center + Vector2(10.0 * size_scale, 16.0 * size_scale), center + Vector2(2.0 * size_scale, 26.0 * size_scale), anchor, 3.0 * size_scale)
	draw_line(center + Vector2(26.0 * size_scale, 16.0 * size_scale), center + Vector2(34.0 * size_scale, 26.0 * size_scale), anchor, 3.0 * size_scale)
	draw_circle(center + Vector2(-8.0 * size_scale, -10.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(0.0, -12.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_glowvine(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var vine = Color(0.24, 0.62, 0.3, alpha)
	var glow = Color(0.68, 1.0, 0.76, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	draw_line(center + Vector2(-6.0 * size_scale, 10.0 * size_scale), center + Vector2(-10.0 * size_scale, 34.0 * size_scale), vine, 4.0 * size_scale)
	draw_line(center + Vector2(6.0 * size_scale, 10.0 * size_scale), center + Vector2(10.0 * size_scale, 34.0 * size_scale), vine, 4.0 * size_scale)
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, -18.0 * size_scale), vine, 5.0 * size_scale)
	for orb_center in [Vector2(-16.0, -12.0), Vector2(0.0, -20.0), Vector2(16.0, -8.0)]:
		draw_circle(center + orb_center * size_scale, 8.0 * size_scale, glow)
		draw_circle(center + orb_center * size_scale, 14.0 * size_scale, Color(glow.r, glow.g, glow.b, alpha * 0.18))
	draw_arc(center + Vector2(0.0, -8.0 * size_scale), 26.0 * size_scale, 3.5, 5.7, 20, Color(0.8, 1.0, 0.88, alpha * 0.24), 1.6 * size_scale)
	draw_circle(center + Vector2(-6.0 * size_scale, -14.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(2.0 * size_scale, -15.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_brine_pot(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var clay = Color(0.66, 0.46, 0.26, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	var brine = Color(0.68, 0.92, 0.84, alpha)
	draw_rect(Rect2(center + Vector2(-16.0 * size_scale, -8.0 * size_scale), Vector2(32.0 * size_scale, 26.0 * size_scale)), clay, true)
	draw_arc(center + Vector2(0.0, -10.0 * size_scale), 16.0 * size_scale, PI, TAU, 16, clay.lightened(0.1), 4.0 * size_scale)
	draw_line(center + Vector2(-6.0 * size_scale, 18.0 * size_scale), center + Vector2(-10.0 * size_scale, 34.0 * size_scale), Color(0.26, 0.56, 0.18, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(6.0 * size_scale, 18.0 * size_scale), center + Vector2(10.0 * size_scale, 34.0 * size_scale), Color(0.26, 0.56, 0.18, alpha), 4.0 * size_scale)
	draw_circle(center + Vector2(0.0, -10.0 * size_scale), 10.0 * size_scale, brine)
	draw_circle(center + Vector2(-10.0 * size_scale, -16.0 * size_scale), 6.0 * size_scale, Color(brine.r, brine.g, brine.b, alpha * 0.72))
	draw_circle(center + Vector2(10.0 * size_scale, -20.0 * size_scale), 7.0 * size_scale, Color(brine.r, brine.g, brine.b, alpha * 0.72))
	draw_circle(center + Vector2(-5.0 * size_scale, -2.0 * size_scale), 1.8 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(5.0 * size_scale, -2.0 * size_scale), 1.8 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_storm_reed(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var reed = Color(0.42, 0.68, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	var spark = Color(0.96, 0.96, 0.58, alpha)
	draw_line(center + Vector2(-4.0 * size_scale, 8.0 * size_scale), center + Vector2(-8.0 * size_scale, 34.0 * size_scale), reed, 4.0 * size_scale)
	draw_line(center + Vector2(6.0 * size_scale, 10.0 * size_scale), center + Vector2(8.0 * size_scale, 34.0 * size_scale), reed, 4.0 * size_scale)
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, -20.0 * size_scale), reed, 5.0 * size_scale)
	for branch in [Vector2(-14.0, -4.0), Vector2(12.0, -12.0), Vector2(2.0, -20.0)]:
		draw_line(center + Vector2(0.0, -4.0 * size_scale), center + branch * size_scale, reed, 3.0 * size_scale)
		draw_circle(center + branch * size_scale, 6.0 * size_scale, spark)
	draw_line(center + Vector2(-16.0 * size_scale, -18.0 * size_scale), center + Vector2(-6.0 * size_scale, -8.0 * size_scale), spark, 2.0 * size_scale)
	draw_line(center + Vector2(-6.0 * size_scale, -8.0 * size_scale), center + Vector2(-12.0 * size_scale, 0.0), spark, 2.0 * size_scale)
	draw_line(center + Vector2(10.0 * size_scale, -22.0 * size_scale), center + Vector2(18.0 * size_scale, -10.0 * size_scale), spark, 2.0 * size_scale)
	draw_circle(center + Vector2(-4.0 * size_scale, -12.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -13.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_moonforge(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal = Color(0.96, 0.72, 0.44, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	var forge = Color(0.56, 0.24, 0.12, alpha)
	var ember = Color(1.0, 0.84, 0.54, alpha)
	draw_line(center + Vector2(-4.0 * size_scale, 10.0 * size_scale), center + Vector2(-8.0 * size_scale, 34.0 * size_scale), Color(0.28, 0.54, 0.2, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(6.0 * size_scale, 12.0 * size_scale), center + Vector2(10.0 * size_scale, 34.0 * size_scale), Color(0.28, 0.54, 0.2, alpha), 4.0 * size_scale)
	draw_rect(Rect2(center + Vector2(-14.0 * size_scale, -8.0 * size_scale), Vector2(28.0 * size_scale, 24.0 * size_scale)), forge, true)
	draw_circle(center + Vector2(0.0, -18.0 * size_scale), 10.0 * size_scale, petal)
	draw_circle(center + Vector2(-10.0 * size_scale, -8.0 * size_scale), 8.0 * size_scale, petal)
	draw_circle(center + Vector2(10.0 * size_scale, -8.0 * size_scale), 8.0 * size_scale, petal)
	draw_circle(center + Vector2(0.0, -2.0 * size_scale), 7.0 * size_scale, ember)
	draw_line(center + Vector2(16.0 * size_scale, -18.0 * size_scale), center + Vector2(34.0 * size_scale, -28.0 * size_scale), Color(0.92, 0.96, 1.0, alpha), 2.6 * size_scale)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(34.0 * size_scale, -28.0 * size_scale),
			center + Vector2(48.0 * size_scale, -34.0 * size_scale),
			center + Vector2(42.0 * size_scale, -28.0 * size_scale),
			center + Vector2(48.0 * size_scale, -22.0 * size_scale),
		]),
		PackedColorArray([ember, Color(1.0, 1.0, 1.0, alpha), ember, ember])
	)
	draw_circle(center + Vector2(-4.0 * size_scale, -12.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -12.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


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


func _draw_flower_pot(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var pot_color = Color(0.7, 0.42, 0.22, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	draw_rect(Rect2(center + Vector2(-18.0 * size_scale, -2.0 * size_scale), Vector2(36.0 * size_scale, 22.0 * size_scale)), pot_color, true)
	draw_rect(Rect2(center + Vector2(-22.0 * size_scale, -8.0 * size_scale), Vector2(44.0 * size_scale, 8.0 * size_scale)), pot_color.lightened(0.12), true)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-18.0 * size_scale, 20.0 * size_scale),
			center + Vector2(-8.0 * size_scale, 34.0 * size_scale),
			center + Vector2(8.0 * size_scale, 34.0 * size_scale),
			center + Vector2(18.0 * size_scale, 20.0 * size_scale),
		]),
		PackedColorArray([pot_color.darkened(0.08), pot_color.darkened(0.18), pot_color.darkened(0.18), pot_color.darkened(0.08)])
	)
	draw_rect(Rect2(center + Vector2(-16.0 * size_scale, -4.0 * size_scale), Vector2(32.0 * size_scale, 6.0 * size_scale)), Color(0.34, 0.22, 0.14, alpha), true)


func _draw_cabbage_pult(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	_draw_flower_pot(center + Vector2(0.0, 12.0 * size_scale), size_scale * 0.92, flash, alpha)
	var leaf = Color(0.42, 0.78, 0.28, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	draw_line(center + Vector2(-4.0 * size_scale, 12.0 * size_scale), center + Vector2(-6.0 * size_scale, 34.0 * size_scale), Color(0.24, 0.56, 0.18, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(-2.0 * size_scale, 4.0 * size_scale), center + Vector2(20.0 * size_scale, -6.0 * size_scale), leaf, 4.0 * size_scale)
	draw_circle(center + Vector2(-10.0 * size_scale, -4.0 * size_scale), 14.0 * size_scale, leaf)
	draw_circle(center + Vector2(-20.0 * size_scale, -6.0 * size_scale), 10.0 * size_scale, leaf.darkened(0.06))
	draw_circle(center + Vector2(-2.0 * size_scale, -10.0 * size_scale), 10.0 * size_scale, leaf.lightened(0.08))
	draw_circle(center + Vector2(-16.0 * size_scale, -8.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-8.0 * size_scale, -10.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_kernel_pult(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	_draw_flower_pot(center + Vector2(0.0, 12.0 * size_scale), size_scale * 0.92, flash, alpha)
	var husk = Color(0.48, 0.76, 0.28, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	var cob = Color(0.98, 0.86, 0.32, alpha)
	draw_line(center + Vector2(-2.0 * size_scale, 10.0 * size_scale), center + Vector2(-4.0 * size_scale, 34.0 * size_scale), Color(0.24, 0.54, 0.18, alpha), 4.0 * size_scale)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-18.0 * size_scale, 2.0 * size_scale),
			center + Vector2(-6.0 * size_scale, -18.0 * size_scale),
			center + Vector2(6.0 * size_scale, -8.0 * size_scale),
			center + Vector2(-10.0 * size_scale, 10.0 * size_scale),
		]),
		PackedColorArray([husk, husk, husk.darkened(0.08), husk.darkened(0.04)])
	)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(12.0 * size_scale, -2.0 * size_scale),
			center + Vector2(-2.0 * size_scale, -20.0 * size_scale),
			center + Vector2(-12.0 * size_scale, -6.0 * size_scale),
			center + Vector2(0.0 * size_scale, 10.0 * size_scale),
		]),
		PackedColorArray([husk, husk, husk.darkened(0.08), husk.darkened(0.04)])
	)
	draw_rect(Rect2(center + Vector2(-9.0 * size_scale, -18.0 * size_scale), Vector2(18.0 * size_scale, 26.0 * size_scale)), cob, true)
	draw_circle(center + Vector2(-4.0 * size_scale, -8.0 * size_scale), 1.8 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -10.0 * size_scale), 1.8 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_coffee_bean(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var bean = Color(0.48, 0.28, 0.16, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	draw_circle(center + Vector2(-8.0 * size_scale, 2.0 * size_scale), 10.0 * size_scale, bean)
	draw_circle(center + Vector2(8.0 * size_scale, 2.0 * size_scale), 10.0 * size_scale, bean.darkened(0.06))
	draw_line(center + Vector2(0.0, -10.0 * size_scale), center + Vector2(0.0, 20.0 * size_scale), Color(0.26, 0.54, 0.18, alpha), 3.0 * size_scale)
	draw_line(center + Vector2(0.0, -8.0 * size_scale), center + Vector2(-12.0 * size_scale, -20.0 * size_scale), Color(0.34, 0.68, 0.2, alpha), 3.0 * size_scale)
	draw_line(center + Vector2(0.0, -8.0 * size_scale), center + Vector2(12.0 * size_scale, -18.0 * size_scale), Color(0.34, 0.68, 0.2, alpha), 3.0 * size_scale)
	draw_line(center + Vector2(-4.0 * size_scale, -6.0 * size_scale), center + Vector2(-1.0 * size_scale, 12.0 * size_scale), Color(0.26, 0.16, 0.1, alpha), 1.6 * size_scale)
	draw_line(center + Vector2(4.0 * size_scale, -6.0 * size_scale), center + Vector2(1.0 * size_scale, 12.0 * size_scale), Color(0.26, 0.16, 0.1, alpha), 1.6 * size_scale)


func _draw_garlic(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var bulb = Color(0.94, 0.88, 0.72, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	draw_circle(center + Vector2(-8.0 * size_scale, 6.0 * size_scale), 12.0 * size_scale, bulb)
	draw_circle(center + Vector2(0.0, 2.0 * size_scale), 14.0 * size_scale, bulb)
	draw_circle(center + Vector2(10.0 * size_scale, 6.0 * size_scale), 12.0 * size_scale, bulb.darkened(0.02))
	draw_line(center + Vector2(0.0, -10.0 * size_scale), center + Vector2(0.0, -28.0 * size_scale), Color(0.42, 0.74, 0.28, alpha), 3.0 * size_scale)
	draw_circle(center + Vector2(-4.0 * size_scale, 0.0), 2.0 * size_scale, Color(0.16, 0.12, 0.08, alpha))
	draw_circle(center + Vector2(5.0 * size_scale, -1.0 * size_scale), 2.0 * size_scale, Color(0.16, 0.12, 0.08, alpha))
	draw_arc(center + Vector2(1.0 * size_scale, 10.0 * size_scale), 8.0 * size_scale, 0.2, PI - 0.2, 12, Color(0.42, 0.22, 0.16, alpha), 1.8 * size_scale)


func _draw_umbrella_leaf(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var canopy = Color(0.36, 0.76, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	var vein = Color(0.18, 0.48, 0.14, alpha)
	draw_line(center + Vector2(0.0, -8.0 * size_scale), center + Vector2(0.0, 32.0 * size_scale), Color(0.36, 0.56, 0.18, alpha), 4.0 * size_scale)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(0.0, -32.0 * size_scale),
			center + Vector2(28.0 * size_scale, -8.0 * size_scale),
			center + Vector2(18.0 * size_scale, 6.0 * size_scale),
			center + Vector2(-18.0 * size_scale, 6.0 * size_scale),
			center + Vector2(-28.0 * size_scale, -8.0 * size_scale),
		]),
		PackedColorArray([canopy, canopy, canopy.darkened(0.08), canopy.darkened(0.08), canopy])
	)
	draw_line(center + Vector2(0.0, -28.0 * size_scale), center + Vector2(0.0, 4.0 * size_scale), vein, 2.0 * size_scale)
	draw_line(center + Vector2(0.0, -18.0 * size_scale), center + Vector2(-16.0 * size_scale, -4.0 * size_scale), vein, 1.6 * size_scale)
	draw_line(center + Vector2(0.0, -18.0 * size_scale), center + Vector2(16.0 * size_scale, -4.0 * size_scale), vein, 1.6 * size_scale)
	draw_arc(center + Vector2(0.0, 20.0 * size_scale), 8.0 * size_scale, 0.0, PI, 10, Color(0.32, 0.44, 0.16, alpha), 1.8 * size_scale)


func _draw_marigold(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal = Color(1.0, 0.84, 0.26, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.28, 0.62, 0.18, alpha), 4.0 * size_scale)
	for index in range(8):
		var angle = float(index) * TAU / 8.0
		draw_circle(center + Vector2(cos(angle), sin(angle)) * 14.0 * size_scale + Vector2(0.0, -8.0 * size_scale), 7.0 * size_scale, petal)
	draw_circle(center + Vector2(0.0, -8.0 * size_scale), 8.0 * size_scale, Color(0.88, 0.54, 0.12, alpha))
	draw_circle(center + Vector2(-3.0 * size_scale, -10.0 * size_scale), 1.6 * size_scale, Color(0.26, 0.18, 0.08, alpha))
	draw_circle(center + Vector2(3.0 * size_scale, -10.0 * size_scale), 1.6 * size_scale, Color(0.26, 0.18, 0.08, alpha))


func _draw_melon_pult(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	_draw_flower_pot(center + Vector2(0.0, 12.0 * size_scale), size_scale * 0.94, flash, alpha)
	var rind = Color(0.32, 0.72, 0.24, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	var flesh = Color(0.9, 0.26, 0.22, alpha)
	draw_line(center + Vector2(-2.0 * size_scale, 10.0 * size_scale), center + Vector2(-4.0 * size_scale, 34.0 * size_scale), Color(0.24, 0.54, 0.16, alpha), 4.0 * size_scale)
	draw_circle(center + Vector2(-6.0 * size_scale, -8.0 * size_scale), 16.0 * size_scale, rind)
	draw_circle(center + Vector2(-6.0 * size_scale, -8.0 * size_scale), 12.0 * size_scale, flesh)
	for seed_index in range(4):
		draw_circle(center + Vector2((-10.0 + seed_index * 3.8) * size_scale, (-8.0 + float(seed_index % 2) * 4.0) * size_scale), 1.4 * size_scale, Color(0.16, 0.08, 0.08, alpha))
	draw_line(center + Vector2(6.0 * size_scale, -6.0 * size_scale), center + Vector2(26.0 * size_scale, -16.0 * size_scale), Color(0.42, 0.72, 0.26, alpha), 4.0 * size_scale)
	draw_arc(center + Vector2(30.0 * size_scale, -18.0 * size_scale), 10.0 * size_scale, -1.2, 1.0, 16, rind, 2.4 * size_scale)


func _draw_origami_blossom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var stem = Color(0.3, 0.62, 0.2, alpha)
	var paper = Color(0.96, 0.9, 0.76, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	var crease = Color(0.72, 0.52, 0.34, alpha)
	draw_line(center + Vector2(-4.0 * size_scale, 12.0 * size_scale), center + Vector2(-6.0 * size_scale, 34.0 * size_scale), stem, 4.0 * size_scale)
	draw_line(center + Vector2(6.0 * size_scale, 10.0 * size_scale), center + Vector2(8.0 * size_scale, 34.0 * size_scale), stem, 4.0 * size_scale)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-22.0 * size_scale, -4.0 * size_scale),
			center + Vector2(-4.0 * size_scale, -24.0 * size_scale),
			center + Vector2(8.0 * size_scale, -6.0 * size_scale),
			center + Vector2(-10.0 * size_scale, 4.0 * size_scale),
		]),
		PackedColorArray([paper, paper, paper.darkened(0.04), paper.darkened(0.08)])
	)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(22.0 * size_scale, -6.0 * size_scale),
			center + Vector2(4.0 * size_scale, -24.0 * size_scale),
			center + Vector2(-8.0 * size_scale, -6.0 * size_scale),
			center + Vector2(10.0 * size_scale, 4.0 * size_scale),
		]),
		PackedColorArray([paper, paper, paper.darkened(0.04), paper.darkened(0.08)])
	)
	draw_line(center + Vector2(-18.0 * size_scale, -6.0 * size_scale), center + Vector2(18.0 * size_scale, -6.0 * size_scale), crease, 1.6 * size_scale)
	draw_line(center + Vector2(0.0, -24.0 * size_scale), center + Vector2(0.0, 4.0 * size_scale), crease, 1.6 * size_scale)
	draw_circle(center + Vector2(-4.0 * size_scale, -8.0 * size_scale), 2.0 * size_scale, Color(0.1, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -8.0 * size_scale), 2.0 * size_scale, Color(0.1, 0.08, 0.08, alpha))


func _draw_chimney_pepper(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var brick = Color(0.62, 0.28, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	var ember = Color(1.0, 0.54, 0.18, alpha)
	var pepper = Color(0.92, 0.18, 0.12, alpha)
	draw_line(center + Vector2(-6.0 * size_scale, 8.0 * size_scale), center + Vector2(-8.0 * size_scale, 34.0 * size_scale), Color(0.24, 0.54, 0.16, alpha), 4.0 * size_scale)
	draw_rect(Rect2(center + Vector2(-16.0 * size_scale, -6.0 * size_scale), Vector2(24.0 * size_scale, 28.0 * size_scale)), brick, true)
	draw_rect(Rect2(center + Vector2(-20.0 * size_scale, -12.0 * size_scale), Vector2(32.0 * size_scale, 8.0 * size_scale)), brick.lightened(0.1), true)
	draw_circle(center + Vector2(18.0 * size_scale, -4.0 * size_scale), 12.0 * size_scale, pepper)
	draw_circle(center + Vector2(22.0 * size_scale, -16.0 * size_scale), 8.0 * size_scale, ember)
	draw_circle(center + Vector2(0.0, -20.0 * size_scale), 6.0 * size_scale, Color(1.0, 0.76, 0.34, alpha * 0.7))
	draw_circle(center + Vector2(-4.0 * size_scale, -2.0 * size_scale), 1.8 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -2.0 * size_scale), 1.8 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_tesla_tulip(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal = Color(0.9, 0.82, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	var metal = Color(0.72, 0.8, 0.92, alpha)
	var spark = Color(1.0, 0.94, 0.56, alpha)
	draw_line(center + Vector2(-4.0 * size_scale, 12.0 * size_scale), center + Vector2(-6.0 * size_scale, 34.0 * size_scale), Color(0.28, 0.56, 0.18, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(4.0 * size_scale, 12.0 * size_scale), center + Vector2(6.0 * size_scale, 34.0 * size_scale), Color(0.28, 0.56, 0.18, alpha), 4.0 * size_scale)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-18.0 * size_scale, -6.0 * size_scale),
			center + Vector2(0.0, -24.0 * size_scale),
			center + Vector2(18.0 * size_scale, -6.0 * size_scale),
			center + Vector2(0.0, 8.0 * size_scale),
		]),
		PackedColorArray([petal, petal, petal, petal.darkened(0.08)])
	)
	draw_line(center + Vector2(0.0, -26.0 * size_scale), center + Vector2(0.0, -38.0 * size_scale), metal, 2.0 * size_scale)
	draw_line(center + Vector2(-8.0 * size_scale, -20.0 * size_scale), center + Vector2(-14.0 * size_scale, -30.0 * size_scale), metal, 1.8 * size_scale)
	draw_line(center + Vector2(8.0 * size_scale, -20.0 * size_scale), center + Vector2(14.0 * size_scale, -30.0 * size_scale), metal, 1.8 * size_scale)
	draw_line(center + Vector2(-14.0 * size_scale, -30.0 * size_scale), center + Vector2(-8.0 * size_scale, -36.0 * size_scale), spark, 1.4 * size_scale)
	draw_line(center + Vector2(14.0 * size_scale, -30.0 * size_scale), center + Vector2(8.0 * size_scale, -36.0 * size_scale), spark, 1.4 * size_scale)
	draw_circle(center + Vector2(-4.0 * size_scale, -8.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -8.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_brick_guard(center: Vector2, size_scale: float, flash: float, health_ratio: float, alpha: float = 1.0) -> void:
	var brick = Color(0.72, 0.36, 0.24, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.2)
	var mortar = Color(0.9, 0.84, 0.72, alpha)
	draw_rect(Rect2(center + Vector2(-22.0 * size_scale, -6.0 * size_scale), Vector2(44.0 * size_scale, 34.0 * size_scale)), brick, true)
	for row_index in range(3):
		var y = -4.0 + row_index * 11.0
		draw_line(center + Vector2(-22.0 * size_scale, y * size_scale), center + Vector2(22.0 * size_scale, y * size_scale), mortar, 2.0 * size_scale)
	for col_index in range(3):
		var x = -12.0 + col_index * 12.0 + (6.0 if col_index % 2 == 0 else 0.0)
		draw_line(center + Vector2(x * size_scale, -6.0 * size_scale), center + Vector2(x * size_scale, 28.0 * size_scale), mortar, 1.8 * size_scale)
	draw_circle(center + Vector2(-7.0 * size_scale, 2.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(7.0 * size_scale, 2.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_arc(center + Vector2(0.0, 12.0 * size_scale), 8.0 * size_scale, 0.25, PI - 0.25, 12, Color(0.24, 0.12, 0.1, alpha), 1.8 * size_scale)
	if health_ratio < 0.55:
		draw_line(center + Vector2(-16.0 * size_scale, 6.0 * size_scale), center + Vector2(-4.0 * size_scale, 18.0 * size_scale), mortar.darkened(0.12), 2.0 * size_scale)
		draw_line(center + Vector2(6.0 * size_scale, 0.0), center + Vector2(16.0 * size_scale, 14.0 * size_scale), mortar.darkened(0.12), 2.0 * size_scale)


func _draw_signal_ivy(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var vine = Color(0.34, 0.68, 0.26, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	var signal_color = Color(0.7, 0.96, 1.0, alpha)
	draw_line(center + Vector2(-6.0 * size_scale, 10.0 * size_scale), center + Vector2(-10.0 * size_scale, 34.0 * size_scale), vine, 4.0 * size_scale)
	draw_line(center + Vector2(4.0 * size_scale, 10.0 * size_scale), center + Vector2(8.0 * size_scale, 34.0 * size_scale), vine, 4.0 * size_scale)
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, -18.0 * size_scale), vine, 4.0 * size_scale)
	draw_circle(center + Vector2(-12.0 * size_scale, -6.0 * size_scale), 9.0 * size_scale, vine)
	draw_rect(Rect2(center + Vector2(6.0 * size_scale, -26.0 * size_scale), Vector2(20.0 * size_scale, 24.0 * size_scale)), Color(0.3, 0.48, 0.34, alpha), true)
	draw_rect(Rect2(center + Vector2(9.0 * size_scale, -23.0 * size_scale), Vector2(14.0 * size_scale, 18.0 * size_scale)), signal_color, true)
	draw_arc(center + Vector2(16.0 * size_scale, -16.0 * size_scale), 18.0 * size_scale, -0.9, 0.9, 16, Color(signal_color.r, signal_color.g, signal_color.b, alpha * 0.28), 1.8 * size_scale)
	draw_arc(center + Vector2(16.0 * size_scale, -16.0 * size_scale), 12.0 * size_scale, -0.8, 0.8, 16, Color(signal_color.r, signal_color.g, signal_color.b, alpha * 0.38), 1.4 * size_scale)
	draw_circle(center + Vector2(-16.0 * size_scale, -8.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-8.0 * size_scale, -9.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_roof_vane(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var vane = Color(0.82, 0.68, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	var leaf = Color(0.46, 0.74, 0.3, alpha)
	var sway = sin(level_time * 3.4 + center.x * 0.01) * 4.0
	draw_line(center + Vector2(0.0, -20.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.38, 0.32, 0.18, alpha), 3.4 * size_scale)
	draw_line(center + Vector2(-18.0 * size_scale, -2.0 * size_scale), center + Vector2(18.0 * size_scale, -2.0 * size_scale), vane, 2.0 * size_scale)
	draw_polygon(
		PackedVector2Array([
			center + Vector2((20.0 + sway) * size_scale, -2.0 * size_scale),
			center + Vector2((4.0 + sway) * size_scale, -12.0 * size_scale),
			center + Vector2((4.0 + sway) * size_scale, 8.0 * size_scale),
		]),
		PackedColorArray([vane, vane.darkened(0.08), vane.darkened(0.02)])
	)
	draw_polygon(
		PackedVector2Array([
			center + Vector2((-20.0 + sway * 0.4) * size_scale, -2.0 * size_scale),
			center + Vector2((-6.0 + sway * 0.4) * size_scale, -16.0 * size_scale),
			center + Vector2((-6.0 + sway * 0.4) * size_scale, 12.0 * size_scale),
		]),
		PackedColorArray([leaf, leaf.darkened(0.08), leaf.darkened(0.02)])
	)
	draw_circle(center + Vector2(-8.0 * size_scale, 10.0 * size_scale), 10.0 * size_scale, leaf)
	draw_circle(center + Vector2(-12.0 * size_scale, 8.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-4.0 * size_scale, 8.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_skylight_melon(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	_draw_flower_pot(center + Vector2(0.0, 12.0 * size_scale), size_scale * 0.94, flash, alpha)
	var frame = Color(0.76, 0.86, 0.98, alpha)
	var glass = Color(0.72, 0.9, 1.0, alpha * 0.72)
	var rind = Color(0.36, 0.76, 0.26, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	var flesh = Color(0.92, 0.32, 0.24, alpha)
	draw_rect(Rect2(center + Vector2(4.0 * size_scale, -28.0 * size_scale), Vector2(28.0 * size_scale, 24.0 * size_scale)), frame, true)
	draw_rect(Rect2(center + Vector2(7.0 * size_scale, -25.0 * size_scale), Vector2(22.0 * size_scale, 18.0 * size_scale)), glass, true)
	draw_line(center + Vector2(18.0 * size_scale, -25.0 * size_scale), center + Vector2(18.0 * size_scale, -7.0 * size_scale), frame.darkened(0.1), 1.8 * size_scale)
	draw_circle(center + Vector2(-10.0 * size_scale, -6.0 * size_scale), 15.0 * size_scale, rind)
	draw_circle(center + Vector2(-10.0 * size_scale, -6.0 * size_scale), 11.0 * size_scale, flesh)
	for seed_index in range(4):
		draw_circle(center + Vector2((-14.0 + seed_index * 3.4) * size_scale, (-6.0 + float(seed_index % 2) * 3.6) * size_scale), 1.3 * size_scale, Color(0.16, 0.08, 0.08, alpha))
	draw_line(center + Vector2(-2.0 * size_scale, 10.0 * size_scale), center + Vector2(-4.0 * size_scale, 34.0 * size_scale), Color(0.24, 0.54, 0.16, alpha), 4.0 * size_scale)
	draw_circle(center + Vector2(-14.0 * size_scale, -10.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(-6.0 * size_scale, -10.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_heather_shooter(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var stem = Color(0.22, 0.56, 0.18, alpha)
	var blossom = Color(0.82, 0.34, 0.62, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	var thorn = Color(0.46, 0.12, 0.32, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(-2.0 * size_scale, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), stem, 6.0 * size_scale)
	draw_circle(center + Vector2(-12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.36, 0.7, 0.24, alpha))
	draw_circle(center + Vector2(12.0 * size_scale, 16.0 * size_scale), 7.0 * size_scale, Color(0.3, 0.64, 0.22, alpha))
	var bloom_center = center + Vector2(-4.0 * size_scale, -10.0 * size_scale)
	draw_circle(bloom_center, 18.0 * size_scale, blossom)
	draw_circle(bloom_center + Vector2(22.0 * size_scale, 0.0), 10.0 * size_scale, blossom.darkened(0.08))
	draw_circle(bloom_center + Vector2(30.0 * size_scale, 0.0), 5.0 * size_scale, Color(0.22, 0.06, 0.14, alpha))
	for petal_index in range(6):
		var angle = TAU * float(petal_index) / 6.0
		draw_circle(bloom_center + Vector2(cos(angle), sin(angle)) * 18.0 * size_scale, 6.0 * size_scale, blossom.lightened(0.08))
	for thorn_index in range(3):
		var thorn_tip = bloom_center + Vector2(10.0 + thorn_index * 10.0, -16.0 + thorn_index * 8.0) * size_scale
		draw_line(thorn_tip, thorn_tip + Vector2(6.0, -6.0) * size_scale, thorn, 1.8 * size_scale)
	draw_circle(bloom_center + Vector2(-6.0 * size_scale, -6.0 * size_scale), 2.4 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(bloom_center + Vector2(3.0 * size_scale, -6.0 * size_scale), 2.4 * size_scale, Color(0.08, 0.08, 0.08, alpha))


func _draw_leyline(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var stone = Color(0.32, 0.38, 0.44, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	var rune = Color(0.38, 0.92, 1.0, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 16.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-18.0 * size_scale, 22.0 * size_scale),
			center + Vector2(-10.0 * size_scale, -12.0 * size_scale),
			center + Vector2(0.0, -28.0 * size_scale),
			center + Vector2(14.0 * size_scale, -8.0 * size_scale),
			center + Vector2(18.0 * size_scale, 24.0 * size_scale),
		]),
		PackedColorArray([stone.darkened(0.08), stone, stone.lightened(0.08), stone, stone.darkened(0.12)])
	)
	draw_line(center + Vector2(0.0, -20.0 * size_scale), center + Vector2(0.0, 18.0 * size_scale), rune, 2.4 * size_scale)
	draw_line(center + Vector2(-10.0 * size_scale, -2.0 * size_scale), center + Vector2(10.0 * size_scale, -10.0 * size_scale), rune, 1.8 * size_scale)
	draw_line(center + Vector2(-8.0 * size_scale, 12.0 * size_scale), center + Vector2(8.0 * size_scale, 4.0 * size_scale), rune, 1.8 * size_scale)
	for spark_index in range(3):
		var spark_phase = level_time * 4.2 + spark_index * 1.3
		var spark_center = center + Vector2(sin(spark_phase) * 12.0, -16.0 + spark_index * 14.0) * size_scale
		draw_circle(spark_center, 3.0 * size_scale, Color(rune.r, rune.g, rune.b, alpha * 0.6))
	draw_arc(center + Vector2(0.0, 10.0 * size_scale), 18.0 * size_scale, -1.1, -0.2, 12, Color(rune.r, rune.g, rune.b, alpha * 0.34), 1.8 * size_scale)
	draw_arc(center + Vector2(0.0, 10.0 * size_scale), 18.0 * size_scale, 0.2, 1.1, 12, Color(rune.r, rune.g, rune.b, alpha * 0.34), 1.8 * size_scale)


func _draw_holo_nut(center: Vector2, size_scale: float, flash: float, health_ratio: float, alpha: float = 1.0) -> void:
	var shell = Color(0.56, 0.76, 0.94, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	_draw_wallnut(center, size_scale, flash * 0.4, maxf(health_ratio, 0.15), alpha * 0.86)
	draw_circle(center + Vector2(0.0, 6.0 * size_scale), 31.0 * size_scale, Color(shell.r, shell.g, shell.b, alpha * 0.1), false, 2.2 * size_scale)
	for grid_index in range(3):
		var grid_y = -8.0 + grid_index * 10.0
		draw_line(center + Vector2(-18.0 * size_scale, grid_y * size_scale), center + Vector2(18.0 * size_scale, grid_y * size_scale), Color(shell.r, shell.g, shell.b, alpha * 0.44), 1.4 * size_scale)
	for grid_arc in range(2):
		draw_arc(center + Vector2(0.0, 6.0 * size_scale), (18.0 + grid_arc * 7.0) * size_scale, -1.0, 1.0, 18, Color(shell.r, shell.g, shell.b, alpha * 0.42), 1.6 * size_scale)
	if health_ratio < 0.55:
		draw_line(center + Vector2(-12.0 * size_scale, -12.0 * size_scale), center + Vector2(6.0 * size_scale, 16.0 * size_scale), Color(1.0, 0.84, 0.96, alpha * 0.52), 1.6 * size_scale)


func _draw_healing_gourd(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var gourd = Color(0.7, 0.9, 0.4, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	var glow = Color(0.72, 1.0, 0.82, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.54, 0.18, alpha), 6.0 * size_scale)
	draw_circle(center + Vector2(0.0, -8.0 * size_scale), 14.0 * size_scale, gourd)
	draw_circle(center + Vector2(0.0, 10.0 * size_scale), 20.0 * size_scale, gourd.darkened(0.04))
	draw_circle(center + Vector2(-4.0 * size_scale, -12.0 * size_scale), 4.0 * size_scale, Color(0.82, 0.98, 0.62, alpha))
	draw_line(center + Vector2(0.0, -24.0 * size_scale), center + Vector2(6.0 * size_scale, -34.0 * size_scale), Color(0.3, 0.66, 0.22, alpha), 3.0 * size_scale)
	draw_circle(center + Vector2(-6.0 * size_scale, -10.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -10.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	for drop_index in range(3):
		var drop_center = center + Vector2(16.0 + drop_index * 7.0, -14.0 + sin(level_time * 4.0 + drop_index) * 6.0) * size_scale
		draw_circle(drop_center, 3.4 * size_scale, Color(glow.r, glow.g, glow.b, alpha * 0.64))
		draw_circle(drop_center + Vector2(0.0, 3.0 * size_scale), 2.0 * size_scale, Color(glow.r, glow.g, glow.b, alpha * 0.44))


func _draw_mango_bowling(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0, empowered: bool = false) -> void:
	var mango = Color(0.98, 0.72, 0.22, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	var rind = Color(0.34, 0.68, 0.22, alpha)
	if empowered:
		draw_circle(center + Vector2(0.0, 8.0 * size_scale), 32.0 * size_scale, Color(0.98, 0.84, 0.34, alpha * 0.16))
		draw_arc(center + Vector2(0.0, 8.0 * size_scale), 28.0 * size_scale, -0.72, 0.72, 18, Color(1.0, 0.96, 0.74, alpha * 0.72), 2.0 * size_scale)
	draw_circle(center + Vector2(0.0, 10.0 * size_scale), 24.0 * size_scale, mango)
	draw_circle(center + Vector2(-4.0 * size_scale, 2.0 * size_scale), 18.0 * size_scale, mango.lightened(0.08))
	draw_arc(center + Vector2(2.0 * size_scale, 8.0 * size_scale), 16.0 * size_scale, -0.9, 0.9, 16, Color(0.88, 0.46, 0.12, alpha * 0.6), 2.0 * size_scale)
	draw_circle(center + Vector2(-2.0 * size_scale, 2.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(8.0 * size_scale, 2.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_line(center + Vector2(0.0, 32.0 * size_scale), center + Vector2(0.0, 40.0 * size_scale), Color(0.22, 0.5, 0.14, alpha), 4.0 * size_scale)
	draw_line(center + Vector2(-4.0 * size_scale, -12.0 * size_scale), center + Vector2(10.0 * size_scale, -22.0 * size_scale), rind, 3.0 * size_scale)
	draw_circle(center + Vector2(12.0 * size_scale, -22.0 * size_scale), 7.0 * size_scale, rind)


func _draw_snow_bloom(center: Vector2, size_scale: float, flash: float, wilt_ratio: float, alpha: float = 1.0) -> void:
	var petal = Color(0.82, 0.96, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.5)
	var core = Color(0.54, 0.8, 1.0, alpha)
	var bloom_scale = 0.78 + wilt_ratio * 0.22
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.56, 0.84, 0.94, alpha), 4.0 * size_scale)
	for petal_index in range(6):
		var angle = TAU * float(petal_index) / 6.0 + PI * 0.166
		var petal_center = center + Vector2(cos(angle), sin(angle)) * 16.0 * size_scale * bloom_scale
		draw_polygon(
			PackedVector2Array([
				petal_center + Vector2(0.0, -7.0 * size_scale * bloom_scale),
				petal_center + Vector2(6.0 * size_scale * bloom_scale, 0.0),
				petal_center + Vector2(0.0, 7.0 * size_scale * bloom_scale),
				petal_center + Vector2(-6.0 * size_scale * bloom_scale, 0.0),
			]),
			PackedColorArray([petal, core.lightened(0.08), petal, core.lightened(0.08)])
		)
	draw_circle(center, 8.0 * size_scale * bloom_scale, core)
	for flake_index in range(3):
		var flake_angle = level_time * 2.8 + flake_index * TAU / 3.0
		var flake_center = center + Vector2(cos(flake_angle) * 20.0, -12.0 + sin(flake_angle) * 8.0) * size_scale
		draw_line(flake_center + Vector2(-4.0, 0.0) * size_scale, flake_center + Vector2(4.0, 0.0) * size_scale, Color(1.0, 1.0, 1.0, alpha * 0.42), 1.2 * size_scale)
		draw_line(flake_center + Vector2(0.0, -4.0) * size_scale, flake_center + Vector2(0.0, 4.0) * size_scale, Color(1.0, 1.0, 1.0, alpha * 0.42), 1.2 * size_scale)


func _draw_cluster_boomerang(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var leaf = Color(0.36, 0.72, 0.24, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	var blade = Color(0.74, 0.96, 0.92, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.22, 0.52, 0.16, alpha), 5.0 * size_scale)
	draw_circle(center + Vector2(-10.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, leaf)
	draw_circle(center + Vector2(10.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, leaf.darkened(0.04))
	draw_circle(center + Vector2(0.0, -8.0 * size_scale), 16.0 * size_scale, Color(0.48, 0.86, 0.34, alpha))
	draw_circle(center + Vector2(-4.0 * size_scale, -10.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -10.0 * size_scale), 2.2 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	for blade_index in range(3):
		var orbit = level_time * 3.2 + float(blade_index) * TAU / 3.0
		var blade_center = center + Vector2(cos(orbit) * 24.0, -8.0 + sin(orbit) * 10.0) * size_scale
		draw_arc(blade_center, 7.0 * size_scale, -1.2 + orbit * 0.08, 1.2 + orbit * 0.08, 14, blade, 2.4 * size_scale)


func _draw_glitch_walnut(center: Vector2, size_scale: float, flash: float, health_ratio: float, alpha: float = 1.0) -> void:
	var shell = Color(0.48, 0.34, 0.68, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	_draw_wallnut(center, size_scale, flash * 0.3, maxf(health_ratio, 0.15), alpha * 0.88)
	draw_circle(center + Vector2(0.0, 6.0 * size_scale), 30.0 * size_scale, Color(shell.r, shell.g, shell.b, alpha * 0.08))
	for crack_index in range(3):
		var crack_y = -10.0 + crack_index * 12.0
		draw_line(center + Vector2(-14.0 * size_scale, crack_y * size_scale), center + Vector2(14.0 * size_scale, (crack_y + sin(level_time * 5.0 + crack_index) * 4.0) * size_scale), Color(0.42, 0.96, 1.0, alpha * 0.62), 1.8 * size_scale)
	for pixel_index in range(6):
		var pixel_center = center + Vector2(-18.0 + pixel_index * 7.0, -18.0 + fmod(float(pixel_index) * 5.0 + level_time * 18.0, 34.0)) * size_scale
		draw_rect(Rect2(pixel_center, Vector2(4.0, 4.0) * size_scale), Color(0.72, 0.96, 1.0, alpha * 0.42), true)
	if health_ratio < 0.5:
		draw_arc(center + Vector2(0.0, 4.0 * size_scale), 18.0 * size_scale, 0.2, PI - 0.2, 12, Color(0.96, 0.62, 1.0, alpha * 0.56), 1.8 * size_scale)


func _draw_nether_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var cap = Color(0.42, 0.18, 0.62, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	var stem = Color(0.84, 0.8, 0.9, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.08 * alpha))
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), stem, 6.0 * size_scale)
	draw_circle(center + Vector2(0.0, -6.0 * size_scale), 18.0 * size_scale, cap)
	draw_circle(center + Vector2(11.0 * size_scale, -2.0 * size_scale), 10.0 * size_scale, cap.lightened(0.12))
	draw_circle(center + Vector2(-10.0 * size_scale, -1.0 * size_scale), 8.0 * size_scale, cap.darkened(0.08))
	for swirl_index in range(3):
		var swirl_angle = level_time * 2.8 + float(swirl_index) * TAU / 3.0
		var swirl_center = center + Vector2(cos(swirl_angle) * 15.0, -16.0 + sin(swirl_angle) * 7.0) * size_scale
		draw_circle(swirl_center, 3.6 * size_scale, Color(0.76, 0.4, 0.98, 0.34 * alpha))
	draw_arc(center + Vector2(-5.0 * size_scale, -8.0 * size_scale), 4.5 * size_scale, 0.0, TAU, 16, Color(0.4, 0.92, 1.0, 0.8 * alpha), 1.6 * size_scale)
	draw_arc(center + Vector2(5.0 * size_scale, -8.0 * size_scale), 4.5 * size_scale, 0.0, TAU, 16, Color(0.4, 0.92, 1.0, 0.8 * alpha), 1.6 * size_scale)
	draw_circle(center + Vector2(-5.0 * size_scale, -8.0 * size_scale), 0.9 * size_scale, Color(0.4, 0.92, 1.0, alpha))
	draw_circle(center + Vector2(5.0 * size_scale, -8.0 * size_scale), 0.9 * size_scale, Color(0.4, 0.92, 1.0, alpha))
	draw_rect(Rect2(center + Vector2(-10.0 * size_scale, 12.0 * size_scale), Vector2(20.0, 8.0) * size_scale), Color(0.28, 0.16, 0.08, 0.72 * alpha), true)


func _draw_seraph_flower(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal = Color(1.0, 0.9, 0.7, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.8)
	var core = Color(0.98, 0.72, 0.28, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.3, 0.62, 0.2, alpha), 5.0 * size_scale)
	draw_circle(center + Vector2(-10.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.42, 0.76, 0.28, alpha))
	draw_circle(center + Vector2(10.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.42, 0.76, 0.28, alpha))
	var bloom = center + Vector2(0.0, -8.0 * size_scale)
	for petal_index in range(6):
		var angle = TAU * float(petal_index) / 6.0 - PI * 0.5
		var petal_center = bloom + Vector2(cos(angle), sin(angle)) * 16.0 * size_scale
		draw_circle(petal_center, 8.0 * size_scale, petal)
	draw_circle(bloom, 10.0 * size_scale, core)
	for spear_index in range(3):
		var spear_angle = -0.28 + float(spear_index) * 0.28
		var tip = bloom + Vector2(16.0 + float(spear_index) * 4.0, -18.0 + float(spear_index) * 5.0) * size_scale
		draw_line(bloom + Vector2(4.0, -2.0 + spear_index * 2.0) * size_scale, tip, Color(0.92, 0.76, 0.28, alpha), 2.0 * size_scale)
		draw_polygon(
			PackedVector2Array([
				tip + Vector2(8.0, 0.0) * size_scale,
				tip + Vector2(-2.0, -4.0) * size_scale,
				tip + Vector2(-2.0, 4.0) * size_scale,
			]),
			PackedColorArray([Color(1.0, 0.96, 0.88, alpha), Color(0.98, 0.84, 0.42, alpha), Color(0.98, 0.84, 0.42, alpha)])
		)
		draw_line(tip + Vector2(-6.0, 0.0) * size_scale, tip + Vector2(0.0, sin(level_time * 3.0 + spear_angle) * 4.0) * size_scale, Color(1.0, 0.94, 0.72, 0.4 * alpha), 1.2 * size_scale)
	draw_arc(bloom + Vector2(0.0, -22.0 * size_scale), 14.0 * size_scale, PI * 0.1, PI * 0.9, 18, Color(1.0, 0.92, 0.62, 0.42 * alpha), 2.0 * size_scale)


func _draw_magma_stream(center: Vector2, size_scale: float, flash: float, wilt_ratio: float, alpha: float = 1.0) -> void:
	var glow = clampf(wilt_ratio, 0.18, 1.0)
	var magma = Color(1.0, 0.38, 0.12, alpha).lerp(Color(1.0, 0.82, 0.5, alpha), flash * 0.8)
	var ember = Color(1.0, 0.84, 0.52, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.08 * alpha))
	draw_circle(center + Vector2(0.0, 26.0 * size_scale), 18.0 * size_scale, Color(0.72, 0.12, 0.04, 0.66 * alpha))
	draw_circle(center + Vector2(-6.0 * size_scale, 24.0 * size_scale), 10.0 * size_scale, Color(1.0, 0.34, 0.1, 0.74 * alpha))
	draw_circle(center + Vector2(8.0 * size_scale, 24.0 * size_scale), 8.0 * size_scale, Color(1.0, 0.6, 0.2, 0.58 * alpha))
	draw_line(center + Vector2(0.0, 6.0 * size_scale), center + Vector2(0.0, 24.0 * size_scale), Color(0.38, 0.16, 0.06, alpha), 6.0 * size_scale)
	var bloom = center + Vector2(0.0, -6.0 * size_scale)
	draw_polygon(
		PackedVector2Array([
			bloom + Vector2(0.0, -20.0) * size_scale,
			bloom + Vector2(16.0, -4.0) * size_scale,
			bloom + Vector2(8.0, 14.0) * size_scale,
			bloom + Vector2(-8.0, 14.0) * size_scale,
			bloom + Vector2(-16.0, -4.0) * size_scale,
		]),
		PackedColorArray([ember, magma, magma.darkened(0.08), magma.darkened(0.08), magma])
	)
	draw_circle(bloom, 8.0 * size_scale * glow, ember)
	for spark_index in range(4):
		var spark_angle = level_time * 4.0 + float(spark_index) * TAU / 4.0
		var spark_center = bloom + Vector2(cos(spark_angle) * 16.0, -12.0 + sin(spark_angle) * 10.0) * size_scale
		draw_circle(spark_center, 2.8 * size_scale, Color(1.0, 0.82, 0.5, 0.36 * alpha * glow))


func _draw_orange_bloom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal = Color(1.0, 0.62, 0.2, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	var juice = Color(1.0, 0.84, 0.38, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.28, 0.58, 0.18, alpha), 5.0 * size_scale)
	draw_circle(center + Vector2(-12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.34, 0.72, 0.24, alpha))
	draw_circle(center + Vector2(12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, Color(0.34, 0.72, 0.24, alpha))
	var bloom = center + Vector2(0.0, -8.0 * size_scale)
	for petal_index in range(7):
		var angle = TAU * float(petal_index) / 7.0 - PI * 0.5
		draw_circle(bloom + Vector2(cos(angle), sin(angle)) * 16.0 * size_scale, 8.0 * size_scale, petal)
	draw_circle(bloom, 10.0 * size_scale, Color(0.96, 0.46, 0.16, alpha))
	draw_circle(bloom + Vector2(-4.0 * size_scale, -4.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(bloom + Vector2(4.0 * size_scale, -4.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	for droplet_index in range(3):
		var droplet = bloom + Vector2(18.0 + droplet_index * 7.0, -2.0 + sin(level_time * 3.2 + droplet_index) * 5.0) * size_scale
		draw_circle(droplet, (4.0 - droplet_index * 0.6) * size_scale, Color(1.0, 0.7, 0.28, 0.46 * alpha))


func _draw_hive_flower(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var leaf = Color(0.38, 0.74, 0.24, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	var hive = Color(0.96, 0.78, 0.24, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.26, 0.56, 0.18, alpha), 5.0 * size_scale)
	draw_circle(center + Vector2(-12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, leaf)
	draw_circle(center + Vector2(12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, leaf.darkened(0.06))
	var hive_center = center + Vector2(0.0, -6.0 * size_scale)
	draw_circle(hive_center, 16.0 * size_scale, hive)
	for stripe_index in range(3):
		draw_line(hive_center + Vector2(-10.0, -8.0 + stripe_index * 8.0) * size_scale, hive_center + Vector2(10.0, -8.0 + stripe_index * 8.0) * size_scale, Color(0.36, 0.22, 0.08, 0.88 * alpha), 2.0 * size_scale)
	draw_circle(hive_center + Vector2(-4.0 * size_scale, -2.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_circle(hive_center + Vector2(4.0 * size_scale, -2.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	for bee_index in range(3):
		var orbit = level_time * 5.8 + float(bee_index) * TAU / 3.0
		var bee = hive_center + Vector2(cos(orbit) * 22.0, -12.0 + sin(orbit) * 10.0) * size_scale
		draw_circle(bee, 4.0 * size_scale, Color(0.98, 0.84, 0.24, 0.9 * alpha))
		draw_line(bee + Vector2(-1.8, 0.0) * size_scale, bee + Vector2(1.8, 0.0) * size_scale, Color(0.16, 0.16, 0.18, 0.7), 1.1 * size_scale)
		draw_circle(bee + Vector2(-2.0, -3.0) * size_scale, 1.8 * size_scale, Color(0.9, 0.96, 1.0, 0.34 * alpha))
		draw_circle(bee + Vector2(2.0, -3.0) * size_scale, 1.8 * size_scale, Color(0.9, 0.96, 1.0, 0.34 * alpha))


func _draw_mamba_tree(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var bark = Color(0.22, 0.16, 0.12, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 0.8)
	var venom = Color(0.56, 0.9, 0.3, alpha)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.08 * alpha))
	draw_line(center + Vector2(0.0, -2.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), bark, 10.0 * size_scale)
	draw_line(center + Vector2(0.0, 6.0 * size_scale), center + Vector2(-16.0, -12.0) * size_scale, bark, 5.0 * size_scale)
	draw_line(center + Vector2(0.0, 2.0 * size_scale), center + Vector2(18.0, -14.0) * size_scale, bark, 5.0 * size_scale)
	var canopy = center + Vector2(0.0, -16.0 * size_scale)
	draw_circle(canopy, 18.0 * size_scale, Color(0.1, 0.18, 0.08, alpha))
	draw_circle(canopy + Vector2(-12.0 * size_scale, 4.0 * size_scale), 12.0 * size_scale, Color(0.14, 0.22, 0.1, alpha))
	draw_circle(canopy + Vector2(12.0 * size_scale, 4.0 * size_scale), 12.0 * size_scale, Color(0.14, 0.22, 0.1, alpha))
	draw_circle(canopy + Vector2(-5.0 * size_scale, -3.0 * size_scale), 2.2 * size_scale, venom)
	draw_circle(canopy + Vector2(5.0 * size_scale, -3.0 * size_scale), 2.2 * size_scale, venom)
	for coal_index in range(4):
		var coal = center + Vector2(-18.0 + coal_index * 12.0, 18.0 + sin(level_time * 2.6 + coal_index) * 3.0) * size_scale
		draw_circle(coal, 4.4 * size_scale, Color(0.1, 0.08, 0.08, 0.9 * alpha))


func _draw_chambord_sniper(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var leaf = Color(0.3, 0.72, 0.26, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.6)
	var metal = Color(0.76, 0.82, 0.9, alpha)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.24, 0.56, 0.18, alpha), 5.0 * size_scale)
	draw_circle(center + Vector2(-12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, leaf)
	draw_circle(center + Vector2(12.0 * size_scale, 18.0 * size_scale), 8.0 * size_scale, leaf.darkened(0.08))
	var head = center + Vector2(-6.0 * size_scale, -8.0 * size_scale)
	draw_circle(head, 12.0 * size_scale, leaf)
	draw_circle(head + Vector2(-3.0 * size_scale, -4.0 * size_scale), 2.0 * size_scale, Color(0.08, 0.08, 0.08, alpha))
	draw_rect(Rect2(center + Vector2(-4.0 * size_scale, -12.0 * size_scale), Vector2(30.0, 8.0) * size_scale), metal, true)
	draw_rect(Rect2(center + Vector2(22.0 * size_scale, -10.0 * size_scale), Vector2(18.0, 4.0) * size_scale), metal.darkened(0.08), true)
	draw_circle(center + Vector2(8.0 * size_scale, -16.0 * size_scale), 5.0 * size_scale, Color(0.16, 0.2, 0.28, alpha))
	draw_circle(center + Vector2(8.0 * size_scale, -16.0 * size_scale), 2.2 * size_scale, Color(0.72, 0.96, 1.0, 0.78 * alpha))
	draw_line(center + Vector2(-6.0 * size_scale, -6.0 * size_scale), center + Vector2(-16.0, 8.0) * size_scale, Color(0.4, 0.32, 0.18, alpha), 2.4 * size_scale)


func _draw_dream_disc(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var ring = Color(0.72, 0.62, 0.98, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 1.4)
	draw_circle(center + Vector2(0.0, 34.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.28, 0.54, 0.2, alpha), 4.0 * size_scale)
	draw_circle(center + Vector2(-10.0 * size_scale, 20.0 * size_scale), 7.0 * size_scale, Color(0.42, 0.74, 0.3, alpha))
	draw_circle(center + Vector2(10.0 * size_scale, 20.0 * size_scale), 7.0 * size_scale, Color(0.42, 0.74, 0.3, alpha))
	var disc = center + Vector2(0.0, -6.0 * size_scale)
	draw_circle(disc, 18.0 * size_scale, Color(0.18, 0.14, 0.36, 0.24 * alpha))
	draw_circle(disc, 14.0 * size_scale, ring, false, 3.0 * size_scale)
	draw_circle(disc, 4.0 * size_scale, Color(0.92, 0.88, 1.0, 0.86 * alpha))
	for thread_index in range(4):
		var offset_x = -9.0 + thread_index * 6.0
		draw_line(disc + Vector2(offset_x, 12.0) * size_scale, disc + Vector2(offset_x, 24.0 + sin(level_time * 2.4 + thread_index) * 3.0) * size_scale, Color(0.84, 0.78, 0.98, 0.7 * alpha), 1.2 * size_scale)
		draw_circle(disc + Vector2(offset_x, 26.0 + sin(level_time * 2.4 + thread_index) * 3.0) * size_scale, 2.4 * size_scale, Color(0.96, 0.88, 0.58, 0.78 * alpha))
	for spark_index in range(3):
		var orbit = level_time * 2.8 + float(spark_index) * TAU / 3.0
		draw_circle(disc + Vector2(cos(orbit) * 20.0, sin(orbit) * 9.0) * size_scale, 3.0 * size_scale, Color(0.82, 0.76, 1.0, 0.34 * alpha))


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


func _draw_bowling_nut(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0, empowered: bool = false) -> void:
	if empowered:
		draw_circle(center + Vector2(0.0, 6.0 * size_scale), 33.0 * size_scale, Color(0.24, 0.98, 0.76, alpha * 0.18))
		draw_arc(center + Vector2(0.0, 6.0 * size_scale), 29.0 * size_scale, -0.82, 0.82, 18, Color(0.92, 1.0, 0.98, alpha * 0.72), 2.2 * size_scale)
	_draw_wallnut(center, size_scale, flash, 1.0, alpha)
	var stripe_color = Color(0.2, 0.96, 0.72, alpha) if empowered else Color(0.82, 0.16, 0.16, alpha)
	draw_line(center + Vector2(-18.0 * size_scale, 10.0 * size_scale), center + Vector2(18.0 * size_scale, 10.0 * size_scale), stripe_color, 4.0 * size_scale)
	if empowered:
		draw_arc(center + Vector2(0.0, 6.0 * size_scale), 16.0 * size_scale, 0.18, PI - 0.18, 14, Color(0.96, 1.0, 0.94, alpha * 0.82), 1.8 * size_scale)


func _draw_wallnut(center: Vector2, size_scale: float, flash: float, ratio: float, alpha: float = 1.0) -> void:
	var shell_color = Color(0.61, 0.38, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	# Shadow
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 18.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	# Shell body
	draw_circle(center + Vector2(0.0, 6.0 * size_scale), 28.0 * size_scale, shell_color)
	# Shell shading (darker bottom)
	draw_circle(center + Vector2(0.0, 16.0 * size_scale), 20.0 * size_scale, shell_color.darkened(0.08))
	# Shell highlight (top)
	draw_circle(center + Vector2(-6.0 * size_scale, -6.0 * size_scale), 12.0 * size_scale, shell_color.lightened(0.1))
	# Surface texture lines
	draw_arc(center + Vector2(0.0, 6.0 * size_scale), 22.0 * size_scale, -0.4, 0.4, 8, Color(0.52, 0.3, 0.12, 0.2 * alpha), 1.5 * size_scale)
	draw_arc(center + Vector2(0.0, 6.0 * size_scale), 22.0 * size_scale, PI - 0.4, PI + 0.4, 8, Color(0.52, 0.3, 0.12, 0.2 * alpha), 1.5 * size_scale)
	# Eyes
	draw_circle(center + Vector2(-7.0 * size_scale, 2.0 * size_scale), 3.0 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_circle(center + Vector2(7.0 * size_scale, 2.0 * size_scale), 3.0 * size_scale, Color(0.06, 0.06, 0.06, alpha))
	draw_circle(center + Vector2(-6.0 * size_scale, 1.0 * size_scale), 1.0 * size_scale, Color(1.0, 1.0, 1.0, 0.5 * alpha))
	draw_circle(center + Vector2(8.0 * size_scale, 1.0 * size_scale), 1.0 * size_scale, Color(1.0, 1.0, 1.0, 0.5 * alpha))
	# Mouth
	draw_arc(center + Vector2(0.0, 11.0 * size_scale), 7.0 * size_scale, 0.15, PI - 0.15, 12, Color(0.06, 0.06, 0.06, alpha), 2.0 * size_scale)
	# Damage cracks
	if ratio < 0.68:
		draw_line(center + Vector2(-4.0 * size_scale, -20.0 * size_scale), center + Vector2(4.0 * size_scale, -3.0 * size_scale), Color(0.35, 0.19, 0.08, alpha), 2.0 * size_scale)
	if ratio < 0.34:
		draw_line(center + Vector2(10.0 * size_scale, -14.0 * size_scale), center + Vector2(-6.0 * size_scale, 8.0 * size_scale), Color(0.35, 0.19, 0.08, alpha), 2.0 * size_scale)
		draw_line(center + Vector2(-16.0 * size_scale, -4.0 * size_scale), center + Vector2(-2.0 * size_scale, 12.0 * size_scale), Color(0.35, 0.19, 0.08, alpha), 2.0 * size_scale)
		# Extra damage detail
		draw_line(center + Vector2(14.0 * size_scale, 4.0 * size_scale), center + Vector2(6.0 * size_scale, 18.0 * size_scale), Color(0.35, 0.19, 0.08, 0.6 * alpha), 1.5 * size_scale)


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


func _draw_bungee_zombie(center: Vector2, zombie: Dictionary) -> void:
	var drop_ratio = 1.0 - clampf(float(zombie.get("bungee_timer", 0.0)) / 0.7, 0.0, 1.0)
	var target_row = int(zombie.get("bungee_target_row", int(zombie.get("row", 0))))
	var target_col = int(zombie.get("bungee_target_col", -1))
	var local_offset = Vector2.ZERO
	if target_col >= 0:
		local_offset.x = _cell_center(target_row, target_col).x - float(zombie.get("x", 0.0))
		local_offset.y = _row_center_y(target_row) - _row_center_y(int(zombie.get("row", 0)))
	var harness = center + local_offset + Vector2(0.0, lerpf(-220.0, -24.0, drop_ratio))
	var flash = float(zombie.get("flash", 0.0))
	var body = Color(0.3, 0.34, 0.42).lerp(Color(1.0, 1.0, 1.0), flash * 1.6)
	var vest = Color(0.72, 0.26, 0.16).lerp(Color(1.0, 1.0, 1.0), flash * 1.2)
	draw_line(harness + Vector2(0.0, -78.0), harness + Vector2(0.0, 22.0), Color(0.18, 0.18, 0.2), 2.0)
	draw_line(harness + Vector2(-12.0, -64.0), harness + Vector2(12.0, -40.0), Color(0.2, 0.2, 0.22), 2.0)
	draw_line(harness + Vector2(12.0, -64.0), harness + Vector2(-12.0, -40.0), Color(0.2, 0.2, 0.22), 2.0)
	draw_circle(harness + Vector2(0.0, -24.0), 14.0, Color(0.74, 0.82, 0.7))
	draw_rect(Rect2(harness + Vector2(-12.0, -8.0), Vector2(24.0, 30.0)), vest, true)
	draw_rect(Rect2(harness + Vector2(-10.0, -2.0), Vector2(20.0, 8.0)), body, true)
	draw_line(harness + Vector2(-8.0, 16.0), harness + Vector2(-14.0, 36.0), Color(0.22, 0.22, 0.24), 3.0)
	draw_line(harness + Vector2(8.0, 16.0), harness + Vector2(14.0, 36.0), Color(0.22, 0.22, 0.24), 3.0)
	draw_line(harness + Vector2(-10.0, -4.0), harness + Vector2(-22.0, 6.0), Color(0.56, 0.64, 0.54), 3.0)
	draw_line(harness + Vector2(10.0, -4.0), harness + Vector2(22.0, 6.0), Color(0.56, 0.64, 0.54), 3.0)
	draw_circle(harness + Vector2(-4.0, -26.0), 1.8, Color.BLACK)
	draw_circle(harness + Vector2(4.0, -26.0), 1.8, Color.BLACK)
	draw_arc(harness + Vector2(0.0, -18.0), 5.0, 0.2, PI - 0.2, 12, Color(0.18, 0.18, 0.18), 1.8)


func _draw_ladder_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var slow_tint = 0.55 if float(zombie.get("slow_timer", 0.0)) > 0.0 else 0.0
	var moving = float(zombie.get("special_pause_timer", 0.0)) <= 0.0
	var cycle = level_time * (3.3 + float(zombie.get("base_speed", 16.0)) * 0.08) + float(zombie.get("anim_phase", 0.0))
	var step = sin(cycle) if moving else 0.0
	var torso = center + Vector2(0.0, -absf(step) * 2.0)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 2.0).lerp(Color(0.64, 0.84, 1.0), slow_tint)
	var coat = Color(0.62, 0.42, 0.18).lerp(Color(1.0, 1.0, 1.0), flash * 1.8).lerp(Color(0.46, 0.64, 0.9), slow_tint)
	var pants = Color(0.22, 0.2, 0.18).lerp(Color(0.46, 0.64, 0.9), slow_tint * 0.8)
	draw_line(torso + Vector2(-7.0, 22.0), torso + Vector2(-14.0 - step * 5.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_line(torso + Vector2(7.0, 22.0), torso + Vector2(14.0 + step * 5.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 36.0)), coat, true)
	draw_rect(Rect2(torso + Vector2(-14.0, 14.0), Vector2(28.0, 12.0)), pants, true)
	draw_circle(torso + Vector2(0.0, -28.0), 16.0, skin)
	draw_circle(torso + Vector2(-5.0, -30.0), 2.2, Color.BLACK)
	draw_circle(torso + Vector2(5.0, -30.0), 2.2, Color.BLACK)
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-22.0 - step * 4.0, 8.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, 0.0), torso + Vector2(20.0 + step * 3.0, 12.0), Color(0.56, 0.64, 0.54), 4.0)
	if float(zombie.get("shield_health", 0.0)) > 0.0:
		var ladder = Rect2(torso + Vector2(12.0, -48.0), Vector2(26.0, 64.0))
		draw_rect(ladder, Color(0.66, 0.48, 0.24), false, 3.0)
		draw_line(ladder.position + Vector2(9.0, 4.0), ladder.position + Vector2(9.0, ladder.size.y - 4.0), Color(0.66, 0.48, 0.24), 3.0)
		draw_line(ladder.position + Vector2(17.0, 4.0), ladder.position + Vector2(17.0, ladder.size.y - 4.0), Color(0.66, 0.48, 0.24), 3.0)
		for rung in range(5):
			var y = ladder.position.y + 10.0 + rung * 11.0
			draw_line(Vector2(ladder.position.x + 2.0, y), Vector2(ladder.position.x + ladder.size.x - 2.0, y), Color(0.66, 0.48, 0.24), 2.0)


func _draw_catapult_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var slow_tint = 0.55 if float(zombie.get("slow_timer", 0.0)) > 0.0 else 0.0
	var moving = float(zombie.get("special_pause_timer", 0.0)) <= 0.0 and float(zombie.get("catapult_cooldown", 0.0)) > 0.2
	var cycle = level_time * (2.6 + float(zombie.get("base_speed", 10.0)) * 0.08) + float(zombie.get("anim_phase", 0.0))
	var step = sin(cycle) if moving else 0.0
	var chassis = Color(0.54, 0.42, 0.26).lerp(Color(1.0, 1.0, 1.0), flash * 1.6).lerp(Color(0.46, 0.64, 0.9), slow_tint)
	var metal = Color(0.42, 0.44, 0.48).lerp(Color(1.0, 1.0, 1.0), flash * 1.2)
	var ball_loaded = float(zombie.get("catapult_cooldown", 0.0)) > 0.24
	draw_circle(center + Vector2(-24.0, 18.0), 12.0, Color(0.18, 0.18, 0.18))
	draw_circle(center + Vector2(18.0, 18.0), 12.0, Color(0.18, 0.18, 0.18))
	draw_line(center + Vector2(-24.0, 18.0), center + Vector2(-24.0 + cos(level_time * 8.0) * 8.0, 18.0 + sin(level_time * 8.0) * 8.0), Color(0.76, 0.76, 0.8), 2.0)
	draw_line(center + Vector2(18.0, 18.0), center + Vector2(18.0 + cos(level_time * 8.0 + 0.8) * 8.0, 18.0 + sin(level_time * 8.0 + 0.8) * 8.0), Color(0.76, 0.76, 0.8), 2.0)
	draw_rect(Rect2(center + Vector2(-34.0, -4.0), Vector2(62.0, 20.0)), chassis, true)
	draw_line(center + Vector2(-18.0, -2.0), center + Vector2(-2.0, -48.0 - step * 4.0), chassis, 5.0)
	draw_line(center + Vector2(4.0, -2.0), center + Vector2(-2.0, -48.0 - step * 4.0), chassis, 5.0)
	draw_line(center + Vector2(-2.0, -48.0 - step * 4.0), center + Vector2(32.0, -24.0), chassis, 4.0)
	draw_circle(center + Vector2(36.0, -20.0), 10.0, metal)
	if ball_loaded:
		draw_circle(center + Vector2(36.0, -20.0), 7.0, Color(0.46, 0.28, 0.18))
		draw_circle(center + Vector2(34.0, -22.0), 2.0, Color(0.62, 0.4, 0.26))
	var zombie_center = center + Vector2(-4.0, -14.0 - absf(step) * 1.5)
	draw_circle(zombie_center + Vector2(0.0, -22.0), 14.0, Color(0.74, 0.82, 0.7))
	draw_rect(Rect2(zombie_center + Vector2(-12.0, -8.0), Vector2(24.0, 26.0)), Color(0.34, 0.28, 0.22), true)
	draw_rect(Rect2(zombie_center + Vector2(-10.0, 10.0), Vector2(20.0, 8.0)), Color(0.2, 0.2, 0.22), true)
	draw_line(zombie_center + Vector2(-8.0, 0.0), zombie_center + Vector2(-18.0, 12.0), Color(0.56, 0.64, 0.54), 3.0)
	draw_line(zombie_center + Vector2(8.0, 0.0), center + Vector2(-4.0, -36.0), Color(0.56, 0.64, 0.54), 3.0)
	draw_circle(zombie_center + Vector2(-4.0, -24.0), 1.8, Color.BLACK)
	draw_circle(zombie_center + Vector2(4.0, -24.0), 1.8, Color.BLACK)


func _draw_gargantuar(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var slow_tint = 0.55 if float(zombie.get("slow_timer", 0.0)) > 0.0 else 0.0
	var moving = float(zombie.get("special_pause_timer", 0.0)) <= 0.0
	var cycle = level_time * (2.4 + float(zombie.get("base_speed", 12.0)) * 0.05) + float(zombie.get("anim_phase", 0.0))
	var step = sin(cycle) if moving else 0.0
	var skin = Color(0.62, 0.74, 0.58).lerp(Color(1.0, 1.0, 1.0), flash * 1.8).lerp(Color(0.52, 0.76, 0.98), slow_tint)
	var coat = Color(0.54, 0.28, 0.18).lerp(Color(1.0, 1.0, 1.0), flash * 1.4)
	var pants = Color(0.22, 0.18, 0.16).lerp(Color(0.46, 0.64, 0.9), slow_tint * 0.8)
	var torso = center + Vector2(0.0, -absf(step) * 3.0)
	draw_line(torso + Vector2(-16.0, 44.0), torso + Vector2(-28.0 - step * 6.0, 88.0), Color(0.18, 0.18, 0.18), 8.0)
	draw_line(torso + Vector2(16.0, 44.0), torso + Vector2(28.0 + step * 6.0, 88.0), Color(0.18, 0.18, 0.18), 8.0)
	draw_rect(Rect2(torso + Vector2(-34.0, -16.0), Vector2(68.0, 64.0)), coat, true)
	draw_rect(Rect2(torso + Vector2(-30.0, 34.0), Vector2(60.0, 16.0)), pants, true)
	draw_circle(torso + Vector2(0.0, -40.0), 28.0, skin)
	draw_circle(torso + Vector2(-10.0, -46.0), 4.0, Color.BLACK)
	draw_circle(torso + Vector2(10.0, -46.0), 4.0, Color.BLACK)
	draw_arc(torso + Vector2(0.0, -26.0), 12.0, 0.25, PI - 0.25, 18, Color(0.14, 0.14, 0.14), 3.0)
	draw_line(torso + Vector2(20.0, -6.0), torso + Vector2(52.0, 24.0 + step * 4.0), Color(0.54, 0.6, 0.5), 7.0)
	draw_line(torso + Vector2(-20.0, -8.0), torso + Vector2(-48.0, 34.0), Color(0.54, 0.6, 0.5), 7.0)
	draw_line(torso + Vector2(-48.0, 34.0), torso + Vector2(-78.0, -34.0), Color(0.48, 0.34, 0.18), 8.0)
	draw_rect(Rect2(torso + Vector2(-96.0, -48.0), Vector2(28.0, 24.0)), Color(0.42, 0.3, 0.16), true)
	draw_circle(torso + Vector2(-82.0, -48.0), 10.0, Color(0.42, 0.3, 0.16))
	if not bool(zombie.get("imp_thrown", false)):
		var imp_center = torso + Vector2(18.0, -66.0)
		draw_circle(imp_center + Vector2(0.0, -10.0), 9.0, Color(0.72, 0.8, 0.68))
		draw_rect(Rect2(imp_center + Vector2(-8.0, -2.0), Vector2(16.0, 18.0)), Color(0.72, 0.18, 0.16), true)
		draw_line(imp_center + Vector2(-4.0, 14.0), imp_center + Vector2(-8.0, 24.0), Color(0.18, 0.18, 0.18), 2.0)
		draw_line(imp_center + Vector2(4.0, 14.0), imp_center + Vector2(8.0, 24.0), Color(0.18, 0.18, 0.18), 2.0)


func _draw_imp(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var slow_tint = 0.55 if float(zombie.get("slow_timer", 0.0)) > 0.0 else 0.0
	var moving = float(zombie.get("special_pause_timer", 0.0)) <= 0.0
	var cycle = level_time * (4.2 + float(zombie.get("base_speed", 28.0)) * 0.08) + float(zombie.get("anim_phase", 0.0))
	var step = sin(cycle) if moving else 0.0
	var torso = center + Vector2(0.0, -absf(step) * 2.0)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.8).lerp(Color(0.64, 0.84, 1.0), slow_tint)
	var shirt = Color(0.8, 0.22, 0.16).lerp(Color(1.0, 1.0, 1.0), flash * 1.4)
	draw_line(torso + Vector2(-5.0, 16.0), torso + Vector2(-12.0 - step * 4.0, 34.0), Color(0.2, 0.2, 0.22), 3.0)
	draw_line(torso + Vector2(5.0, 16.0), torso + Vector2(12.0 + step * 4.0, 34.0), Color(0.2, 0.2, 0.22), 3.0)
	draw_rect(Rect2(torso + Vector2(-12.0, -2.0), Vector2(24.0, 20.0)), shirt, true)
	draw_circle(torso + Vector2(0.0, -18.0), 12.0, skin)
	draw_circle(torso + Vector2(-4.0, -20.0), 1.8, Color.BLACK)
	draw_circle(torso + Vector2(4.0, -20.0), 1.8, Color.BLACK)
	draw_line(torso + Vector2(-8.0, 4.0), torso + Vector2(-18.0 - step * 3.0, 12.0), Color(0.56, 0.64, 0.54), 3.0)
	draw_line(torso + Vector2(8.0, 4.0), torso + Vector2(18.0 + step * 3.0, 12.0), Color(0.56, 0.64, 0.54), 3.0)
	draw_polygon(
		PackedVector2Array([
			torso + Vector2(0.0, -34.0),
			torso + Vector2(-8.0, -18.0),
			torso + Vector2(8.0, -18.0),
		]),
		PackedColorArray([Color(0.4, 0.14, 0.12), Color(0.4, 0.14, 0.12), Color(0.4, 0.14, 0.12)])
	)


func _draw_kite_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var slow_tint = 0.55 if float(zombie.get("slow_timer", 0.0)) > 0.0 else 0.0
	var moving = float(zombie.get("special_pause_timer", 0.0)) <= 0.0
	var cycle = level_time * (3.2 + float(zombie.get("base_speed", 17.0)) * 0.08) + float(zombie.get("anim_phase", 0.0))
	var step = sin(cycle) if moving else 0.0
	var torso = center + Vector2(0.0, -absf(step) * 2.0)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.8).lerp(Color(0.64, 0.84, 1.0), slow_tint)
	var coat = Color(0.52, 0.34, 0.18).lerp(Color(1.0, 1.0, 1.0), flash * 1.4).lerp(Color(0.46, 0.64, 0.9), slow_tint * 0.7)
	var pants = Color(0.2, 0.22, 0.24).lerp(Color(0.46, 0.64, 0.9), slow_tint * 0.7)
	var kite_phase = level_time * 2.4 + float(zombie.get("anim_phase", 0.0))
	var kite_anchor = torso + Vector2(18.0, -78.0 + sin(kite_phase) * 6.0)
	var kite_tip = kite_anchor + Vector2(26.0 + cos(kite_phase * 0.9) * 4.0, -6.0)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 - step * 4.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 + step * 4.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -10.0), Vector2(32.0, 38.0)), coat, true)
	draw_rect(Rect2(torso + Vector2(-14.0, 16.0), Vector2(28.0, 12.0)), pants, true)
	draw_circle(torso + Vector2(0.0, -28.0), 16.0, skin)
	draw_circle(torso + Vector2(-5.0, -30.0), 2.0, Color.BLACK)
	draw_circle(torso + Vector2(5.0, -30.0), 2.0, Color.BLACK)
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-24.0 - step * 5.0, 8.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, -2.0), kite_anchor + Vector2(-4.0, 20.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(16.0, -4.0), kite_anchor + Vector2(-10.0, 18.0), Color(0.88, 0.88, 0.9, 0.7), 1.8)
	draw_polygon(
		PackedVector2Array([
			kite_anchor + Vector2(0.0, -24.0),
			kite_tip + Vector2(6.0, 2.0),
			kite_anchor + Vector2(0.0, 24.0),
			kite_anchor + Vector2(-24.0, 0.0),
		]),
		PackedColorArray([
			Color(0.96, 0.36, 0.26, 0.94),
			Color(0.98, 0.86, 0.34, 0.94),
			Color(0.96, 0.5, 0.22, 0.94),
			Color(0.88, 0.22, 0.2, 0.94),
		])
	)
	draw_line(kite_anchor + Vector2(-20.0, 0.0), kite_anchor + Vector2(22.0, 0.0), Color(0.88, 0.96, 1.0, 0.46), 1.2)
	draw_line(kite_anchor + Vector2(0.0, -20.0), kite_anchor + Vector2(0.0, 20.0), Color(0.88, 0.96, 1.0, 0.46), 1.2)
	draw_line(kite_anchor + Vector2(-18.0, 18.0), kite_anchor + Vector2(-28.0, 36.0), Color(0.92, 0.72, 0.28, 0.82), 1.6)
	draw_line(kite_anchor + Vector2(-26.0, 34.0), kite_anchor + Vector2(-18.0, 46.0), Color(0.92, 0.72, 0.28, 0.7), 1.4)


func _draw_kite_trap(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var sway = sin(level_time * 2.8 + float(zombie.get("anim_phase", 0.0))) * 7.0
	var lift = cos(level_time * 1.8 + float(zombie.get("anim_phase", 0.0))) * 4.0
	var kite_center = center + Vector2(sway, -64.0 + lift)
	var cord_bottom = center + Vector2(0.0, -4.0)
	var kite_color = Color(0.98, 0.84, 0.32, 0.94).lerp(Color(1.0, 1.0, 1.0, 0.96), flash * 1.2)
	var trim = Color(0.92, 0.32, 0.24, 0.92)
	draw_circle(kite_center, 22.0, Color(0.96, 0.92, 0.42, 0.08))
	draw_line(cord_bottom, kite_center + Vector2(-4.0, 18.0), Color(0.92, 0.92, 0.96, 0.62), 1.4)
	draw_polygon(
		PackedVector2Array([
			kite_center + Vector2(0.0, -20.0),
			kite_center + Vector2(22.0, 0.0),
			kite_center + Vector2(0.0, 20.0),
			kite_center + Vector2(-22.0, 0.0),
		]),
		PackedColorArray([kite_color, trim, kite_color.darkened(0.04), trim.darkened(0.06)])
	)
	draw_line(kite_center + Vector2(-14.0, 0.0), kite_center + Vector2(14.0, 0.0), Color(1.0, 1.0, 1.0, 0.42), 1.2)
	draw_line(kite_center + Vector2(0.0, -14.0), kite_center + Vector2(0.0, 14.0), Color(1.0, 1.0, 1.0, 0.42), 1.2)
	for spark_index in range(3):
		var spark_angle = level_time * 5.0 + float(spark_index) * TAU / 3.0
		var spark_center = kite_center + Vector2(cos(spark_angle), sin(spark_angle)) * 18.0
		draw_circle(spark_center, 3.0, Color(0.88, 0.98, 1.0, 0.54))
		draw_line(spark_center + Vector2(-3.0, 0.0), spark_center + Vector2(3.0, 0.0), Color(0.9, 1.0, 1.0, 0.4), 1.2)
	draw_line(kite_center + Vector2(-16.0, 18.0), kite_center + Vector2(-24.0, 34.0), Color(0.98, 0.7, 0.24, 0.74), 1.4)
	draw_line(kite_center + Vector2(-22.0, 32.0), kite_center + Vector2(-12.0, 46.0), Color(0.98, 0.7, 0.24, 0.62), 1.2)


func _draw_hive_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var slow_tint = 0.55 if float(zombie.get("slow_timer", 0.0)) > 0.0 else 0.0
	var moving = float(zombie.get("special_pause_timer", 0.0)) <= 0.0
	var cycle = level_time * (3.5 + float(zombie.get("base_speed", 21.0)) * 0.08) + float(zombie.get("anim_phase", 0.0))
	var step = sin(cycle) if moving else 0.0
	var torso = center + Vector2(0.0, -absf(step) * 2.2)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.8).lerp(Color(0.64, 0.84, 1.0), slow_tint)
	var shirt = Color(0.44, 0.26, 0.14).lerp(Color(1.0, 1.0, 1.0), flash * 1.4).lerp(Color(0.46, 0.64, 0.9), slow_tint * 0.7)
	var hive = Color(0.98, 0.78, 0.24, 0.96)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 - step * 4.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 + step * 4.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -10.0), Vector2(32.0, 38.0)), shirt, true)
	draw_rect(Rect2(torso + Vector2(-14.0, 16.0), Vector2(28.0, 12.0)), Color(0.18, 0.2, 0.22), true)
	draw_circle(torso + Vector2(0.0, -28.0), 16.0, skin)
	draw_circle(torso + Vector2(-5.0, -30.0), 2.0, Color.BLACK)
	draw_circle(torso + Vector2(5.0, -30.0), 2.0, Color.BLACK)
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-22.0 - step * 3.0, 10.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, 0.0), torso + Vector2(20.0 + step * 2.0, 12.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_circle(torso + Vector2(20.0, -8.0), 16.0, hive)
	for stripe_index in range(3):
		draw_line(torso + Vector2(8.0, -16.0 + stripe_index * 8.0), torso + Vector2(30.0, -16.0 + stripe_index * 8.0), Color(0.42, 0.26, 0.1, 0.92), 2.2)
	draw_circle(torso + Vector2(28.0, -8.0), 3.6, Color(0.18, 0.18, 0.18, 0.84))
	var bee_total = 3 if not bool(zombie.get("bee_summoned", false)) else 5
	for bee_index in range(bee_total):
		var bee_angle = level_time * 6.0 + float(bee_index) * TAU / maxf(float(bee_total), 1.0)
		var bee_center = torso + Vector2(cos(bee_angle) * 22.0, -20.0 + sin(bee_angle) * 14.0)
		draw_circle(bee_center, 4.2, Color(0.96, 0.82, 0.22, 0.88))
		draw_line(bee_center + Vector2(-2.0, 0.0), bee_center + Vector2(2.0, 0.0), Color(0.18, 0.18, 0.18, 0.72), 1.2)
		draw_circle(bee_center + Vector2(-3.0, -3.0), 2.0, Color(0.9, 0.96, 1.0, 0.3))
		draw_circle(bee_center + Vector2(3.0, -3.0), 2.0, Color(0.9, 0.96, 1.0, 0.3))


func _draw_bee_minion(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var phase = level_time * 9.2 + float(zombie.get("anim_phase", 0.0))
	for bee_index in range(3):
		var orbit = phase + float(bee_index) * TAU / 3.0
		var bee_center = center + Vector2(cos(orbit) * 10.0, -12.0 + sin(orbit * 1.4) * 8.0)
		var body = Color(0.98, 0.84, 0.24, 0.92).lerp(Color(1.0, 1.0, 1.0, 0.94), flash * 1.2)
		draw_circle(bee_center, 5.0, body)
		draw_line(bee_center + Vector2(-2.0, 0.0), bee_center + Vector2(2.0, 0.0), Color(0.16, 0.16, 0.18, 0.78), 1.2)
		draw_circle(bee_center + Vector2(-3.0, -3.0), 2.2, Color(0.9, 0.96, 1.0, 0.34))
		draw_circle(bee_center + Vector2(3.0, -3.0), 2.2, Color(0.9, 0.96, 1.0, 0.34))
		draw_line(bee_center + Vector2(3.0, 1.0), bee_center + Vector2(7.0, 4.0), Color(0.26, 0.18, 0.08, 0.7), 1.0)
	draw_circle(center + Vector2(0.0, -8.0), 18.0, Color(1.0, 0.84, 0.22, 0.08))


func _draw_turret_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var recoil_ratio = 1.0 - clampf(float(zombie.get("launch_cooldown", 0.0)) / 6.2, 0.0, 1.0)
	var recoil = sin(recoil_ratio * PI) * 8.0 if float(zombie.get("special_pause_timer", 0.0)) > 0.0 else 0.0
	var chassis = Color(0.44, 0.34, 0.24, 0.96).lerp(Color(1.0, 1.0, 1.0, 0.96), flash * 1.4)
	var armor = Color(0.56, 0.58, 0.62, 0.94)
	var barrel = Color(0.26, 0.28, 0.34, 0.96)
	draw_circle(center + Vector2(-18.0, 20.0), 10.0, Color(0.16, 0.16, 0.18))
	draw_circle(center + Vector2(20.0, 20.0), 10.0, Color(0.16, 0.16, 0.18))
	draw_rect(Rect2(center + Vector2(-34.0, -2.0), Vector2(70.0, 22.0)), chassis, true)
	draw_rect(Rect2(center + Vector2(-12.0, -26.0), Vector2(28.0, 24.0)), armor, true)
	draw_line(center + Vector2(12.0, -18.0), center + Vector2(40.0 + recoil, -30.0 - recoil * 0.35), barrel, 8.0)
	draw_circle(center + Vector2(44.0 + recoil, -32.0 - recoil * 0.35), 8.0, barrel)
	draw_rect(Rect2(center + Vector2(-6.0, -40.0), Vector2(18.0, 10.0)), Color(0.74, 0.82, 0.7), true)
	draw_circle(center + Vector2(2.0, -34.0), 10.0, Color(0.74, 0.82, 0.7))
	draw_circle(center + Vector2(-2.0, -36.0), 1.8, Color.BLACK)
	draw_circle(center + Vector2(5.0, -36.0), 1.8, Color.BLACK)
	draw_line(center + Vector2(-4.0, -18.0), center + Vector2(-20.0, -6.0), Color(0.56, 0.64, 0.54), 3.0)
	draw_line(center + Vector2(10.0, -18.0), center + Vector2(24.0 + recoil * 0.5, -24.0 - recoil * 0.2), Color(0.56, 0.64, 0.54), 3.0)
	if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
		draw_circle(center + Vector2(52.0, -34.0), 14.0, Color(0.98, 0.68, 0.24, 0.18))
		draw_circle(center + Vector2(52.0, -34.0), 6.0, Color(1.0, 0.86, 0.4, 0.6))


func _draw_programmer_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var slow_tint = 0.55 if float(zombie.get("slow_timer", 0.0)) > 0.0 else 0.0
	var moving = float(zombie.get("special_pause_timer", 0.0)) <= 0.0
	var cycle = level_time * (2.8 + float(zombie.get("base_speed", 14.0)) * 0.07) + float(zombie.get("anim_phase", 0.0))
	var step = sin(cycle) if moving else 0.0
	var torso = center + Vector2(0.0, -absf(step) * 1.6)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.8).lerp(Color(0.64, 0.84, 1.0), slow_tint)
	var hoodie = Color(0.12, 0.16, 0.24, 0.96).lerp(Color(1.0, 1.0, 1.0, 0.96), flash * 1.4).lerp(Color(0.46, 0.64, 0.9), slow_tint * 0.7)
	var screen = Color(0.72, 0.96, 1.0, 0.92)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 - step * 3.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 + step * 3.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 40.0)), hoodie, true)
	draw_circle(torso + Vector2(0.0, -30.0), 16.0, skin)
	draw_circle(torso + Vector2(-5.0, -32.0), 2.0, Color.BLACK)
	draw_circle(torso + Vector2(5.0, -32.0), 2.0, Color.BLACK)
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-18.0, 14.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, 0.0), torso + Vector2(22.0, 12.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_rect(Rect2(torso + Vector2(8.0, -6.0), Vector2(24.0, 16.0)), Color(0.22, 0.24, 0.28, 0.96), true)
	draw_rect(Rect2(torso + Vector2(10.0, -4.0), Vector2(20.0, 12.0)), screen, true)
	draw_line(torso + Vector2(12.0, 0.0), torso + Vector2(26.0, 0.0), Color(0.2, 0.56, 0.26, 0.8), 1.2)
	var glyphs = ["0", "1", "0", "1"]
	for glyph_index in range(glyphs.size()):
		var glyph_x = -18.0 + glyph_index * 12.0
		var glyph_y = -54.0 - fmod(level_time * 24.0 + glyph_index * 10.0, 20.0)
		_draw_text(glyphs[glyph_index], torso + Vector2(glyph_x, glyph_y), 12, Color(0.72, 0.96, 1.0, 0.58))


func _draw_wenjie_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var lane_shift = float(zombie.get("lane_shift_timer", 0.0))
	var body = Color(0.26, 0.36, 0.42, 0.96).lerp(Color(1.0, 1.0, 1.0, 0.96), flash * 1.4)
	var trim = Color(0.72, 0.88, 1.0, 0.88)
	var shift_pulse = 0.28 + 0.32 * absf(sin(level_time * 7.0 + lane_shift))
	draw_circle(center + Vector2(-22.0, 22.0), 10.0, Color(0.14, 0.14, 0.16))
	draw_circle(center + Vector2(22.0, 22.0), 10.0, Color(0.14, 0.14, 0.16))
	draw_rect(Rect2(center + Vector2(-38.0, -2.0), Vector2(76.0, 24.0)), body, true)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-18.0, -2.0),
			center + Vector2(-8.0, -28.0),
			center + Vector2(18.0, -28.0),
			center + Vector2(30.0, -2.0),
		]),
		PackedColorArray([body.lightened(0.06), trim, trim, body.darkened(0.04)])
	)
	draw_rect(Rect2(center + Vector2(-6.0, -22.0), Vector2(20.0, 12.0)), Color(0.74, 0.82, 0.72), true)
	draw_circle(center + Vector2(4.0, -24.0), 10.0, Color(0.74, 0.82, 0.72))
	draw_circle(center + Vector2(0.0, -26.0), 1.8, Color.BLACK)
	draw_circle(center + Vector2(6.0, -26.0), 1.8, Color.BLACK)
	draw_rect(Rect2(center + Vector2(-28.0, 2.0), Vector2(18.0, 8.0)), Color(0.62, 0.72, 0.82, 0.86), true)
	draw_circle(center + Vector2(32.0, 10.0), 4.6, Color(1.0, 0.56, 0.26, 0.74))
	draw_circle(center + Vector2(-34.0, 10.0), 3.6, Color(0.78, 0.96, 1.0, 0.56 + shift_pulse))
	draw_arc(center + Vector2(0.0, -2.0), 46.0, -0.24, 0.24, 18, Color(0.68, 0.94, 1.0, shift_pulse * 0.38), 2.0)


func _draw_janitor_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var step = sin(level_time * 3.0 + float(zombie.get("anim_phase", 0.0)))
	var torso = center + Vector2(0.0, -absf(step) * 2.0)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.8)
	var uniform = Color(0.18, 0.42, 0.46, 0.96)
	var shovel = Color(0.74, 0.78, 0.82, 0.94)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 - step * 4.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 + step * 4.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 40.0)), uniform, true)
	draw_circle(torso + Vector2(0.0, -30.0), 16.0, skin)
	draw_circle(torso + Vector2(-5.0, -32.0), 2.0, Color.BLACK)
	draw_circle(torso + Vector2(5.0, -32.0), 2.0, Color.BLACK)
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-24.0, 12.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, -4.0), torso + Vector2(30.0, 10.0), Color(0.56, 0.64, 0.54), 4.0)
	if float(zombie.get("shield_health", 0.0)) > 0.0:
		draw_line(torso + Vector2(18.0, -10.0), torso + Vector2(34.0, 24.0), Color(0.54, 0.38, 0.18), 4.0)
		draw_rect(Rect2(torso + Vector2(24.0, -20.0), Vector2(14.0, 26.0)), shovel, true)
		draw_arc(torso + Vector2(31.0, 8.0), 12.0, -0.8, 0.9, 12, Color(0.38, 0.42, 0.46, 0.9), 2.0)
	else:
		draw_line(torso + Vector2(18.0, -8.0), torso + Vector2(42.0, 10.0), Color(0.54, 0.38, 0.18), 4.0)
		draw_rect(Rect2(torso + Vector2(36.0, 4.0), Vector2(18.0, 12.0)), shovel.darkened(0.08), true)
	draw_rect(Rect2(torso + Vector2(-12.0, -44.0), Vector2(24.0, 8.0)), Color(0.12, 0.18, 0.2, 0.94), true)


func _draw_subway_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var train = Color(0.5, 0.6, 0.72, 0.98).lerp(Color(1.0, 1.0, 1.0, 0.98), flash * 1.4)
	var cabin = Color(0.18, 0.22, 0.3, 0.98)
	var glow = 0.42 + 0.22 * sin(level_time * 8.0 + float(zombie.get("anim_phase", 0.0)))
	draw_circle(center + Vector2(-24.0, 22.0), 10.0, Color(0.14, 0.14, 0.16))
	draw_circle(center + Vector2(24.0, 22.0), 10.0, Color(0.14, 0.14, 0.16))
	draw_rect(Rect2(center + Vector2(-40.0, -10.0), Vector2(80.0, 34.0)), train, true)
	draw_rect(Rect2(center + Vector2(-32.0, -20.0), Vector2(64.0, 16.0)), cabin, true)
	draw_rect(Rect2(center + Vector2(-26.0, -16.0), Vector2(18.0, 10.0)), Color(0.78, 0.94, 1.0, 0.82), true)
	draw_rect(Rect2(center + Vector2(8.0, -16.0), Vector2(18.0, 10.0)), Color(0.78, 0.94, 1.0, 0.82), true)
	draw_circle(center + Vector2(0.0, -22.0), 9.0, Color(0.74, 0.82, 0.72))
	draw_circle(center + Vector2(-3.0, -24.0), 1.8, Color.BLACK)
	draw_circle(center + Vector2(3.0, -24.0), 1.8, Color.BLACK)
	draw_circle(center + Vector2(-26.0, 6.0), 4.8, Color(0.9, 0.98, 1.0, glow))
	draw_circle(center + Vector2(26.0, 6.0), 4.8, Color(1.0, 0.76, 0.4, glow))
	for stripe_index in range(3):
		draw_line(center + Vector2(-32.0 + stripe_index * 20.0, 12.0), center + Vector2(-18.0 + stripe_index * 20.0, 12.0), Color(0.16, 0.2, 0.24, 0.62), 2.0)


func _draw_enderman_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var phase = level_time * 5.2 + float(zombie.get("anim_phase", 0.0))
	var body = Color(0.08, 0.06, 0.14, 0.94).lerp(Color(0.64, 0.2, 0.82, 0.94), flash * 0.8)
	draw_circle(center + Vector2(0.0, 46.0), 12.0, Color(0.02, 0.02, 0.06, 0.22))
	draw_rect(Rect2(center + Vector2(-10.0, -54.0), Vector2(20.0, 78.0)), body, true)
	draw_rect(Rect2(center + Vector2(-22.0, -48.0), Vector2(12.0, 64.0)), body.darkened(0.04), true)
	draw_rect(Rect2(center + Vector2(10.0, -48.0), Vector2(12.0, 64.0)), body.darkened(0.04), true)
	draw_rect(Rect2(center + Vector2(-7.0, 20.0), Vector2(6.0, 28.0)), body, true)
	draw_rect(Rect2(center + Vector2(1.0, 20.0), Vector2(6.0, 28.0)), body, true)
	draw_rect(Rect2(center + Vector2(-6.0, -58.0), Vector2(12.0, 10.0)), Color(0.16, 0.0, 0.24, 0.94), true)
	draw_rect(Rect2(center + Vector2(-8.0, -44.0), Vector2(6.0, 2.0)), Color(0.96, 0.42, 1.0, 0.88), true)
	draw_rect(Rect2(center + Vector2(2.0, -44.0), Vector2(6.0, 2.0)), Color(0.96, 0.42, 1.0, 0.88), true)
	for shard_index in range(5):
		var shard_center = center + Vector2(sin(phase + shard_index) * 22.0, -20.0 + cos(phase * 0.7 + shard_index) * 26.0)
		draw_rect(Rect2(shard_center, Vector2(4.0, 4.0)), Color(0.82, 0.48, 1.0, 0.34), true)
	if float(zombie.get("teleport_cooldown", 0.0)) < 0.5:
		draw_circle(center, 34.0, Color(0.74, 0.36, 1.0, 0.08))


func _draw_router_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var step = sin(level_time * 2.8 + float(zombie.get("anim_phase", 0.0)))
	var torso = center + Vector2(0.0, -absf(step) * 1.8)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.7)
	var coat = Color(0.34, 0.34, 0.38, 0.96)
	var router = Color(0.86, 0.92, 0.98, 0.96)
	var wifi_alpha = 0.2 + 0.18 * sin(level_time * 4.4 + float(zombie.get("uid", 0)) * 0.1)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 - step * 3.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 + step * 3.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 40.0)), coat, true)
	draw_circle(torso + Vector2(0.0, -30.0), 16.0, skin)
	draw_circle(torso + Vector2(-5.0, -32.0), 2.0, Color.BLACK)
	draw_circle(torso + Vector2(5.0, -32.0), 2.0, Color.BLACK)
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-24.0, 8.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, 0.0), torso + Vector2(22.0, 12.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_rect(Rect2(torso + Vector2(10.0, -4.0), Vector2(24.0, 16.0)), router, true)
	draw_line(torso + Vector2(14.0, -4.0), torso + Vector2(14.0, -18.0), Color(0.4, 0.46, 0.52), 1.6)
	draw_line(torso + Vector2(30.0, -4.0), torso + Vector2(30.0, -18.0), Color(0.4, 0.46, 0.52), 1.6)
	draw_circle(torso + Vector2(18.0, 4.0), 2.0, Color(0.4, 0.92, 1.0, 0.8))
	draw_circle(torso + Vector2(26.0, 4.0), 2.0, Color(1.0, 0.72, 0.42, 0.8))
	draw_arc(torso + Vector2(22.0, -20.0), 18.0, -0.9, -0.2, 16, Color(0.64, 0.94, 1.0, wifi_alpha), 1.8)
	draw_arc(torso + Vector2(22.0, -20.0), 18.0, 0.2, 0.9, 16, Color(0.64, 0.94, 1.0, wifi_alpha), 1.8)
	draw_arc(torso + Vector2(22.0, -20.0), 28.0, -0.9, -0.2, 16, Color(0.64, 0.94, 1.0, wifi_alpha * 0.72), 1.4)
	draw_arc(torso + Vector2(22.0, -20.0), 28.0, 0.2, 0.9, 16, Color(0.64, 0.94, 1.0, wifi_alpha * 0.72), 1.4)


func _draw_ski_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var step = sin(level_time * 4.4 + float(zombie.get("anim_phase", 0.0)))
	var torso = center + Vector2(0.0, -absf(step) * 2.0)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.8)
	var coat = Color(0.18, 0.48, 0.78, 0.96)
	draw_line(torso + Vector2(-8.0, 18.0), torso + Vector2(-14.0 - step * 4.0, 34.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 18.0), torso + Vector2(14.0 + step * 4.0, 34.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 32.0)), coat, true)
	draw_circle(torso + Vector2(0.0, -28.0), 15.0, skin)
	draw_rect(Rect2(torso + Vector2(-14.0, -40.0), Vector2(28.0, 8.0)), Color(0.84, 0.22, 0.18, 0.96), true)
	draw_rect(Rect2(torso + Vector2(-10.0, -34.0), Vector2(20.0, 4.0)), Color(0.12, 0.18, 0.24, 0.94), true)
	draw_line(torso + Vector2(-10.0, -2.0), torso + Vector2(-24.0, 10.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, -2.0), torso + Vector2(24.0, 8.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(-18.0, 32.0), torso + Vector2(22.0, 28.0), Color(0.74, 0.82, 0.9, 0.96), 4.0)
	draw_line(torso + Vector2(-22.0, 36.0), torso + Vector2(18.0, 32.0), Color(0.74, 0.82, 0.9, 0.96), 4.0)
	draw_arc(torso + Vector2(-10.0, 34.0), 8.0, 0.2, PI - 0.2, 12, Color(0.22, 0.22, 0.26, 0.86), 2.0)
	draw_arc(torso + Vector2(10.0, 32.0), 8.0, 0.2, PI - 0.2, 12, Color(0.22, 0.22, 0.26, 0.86), 2.0)


func _draw_flywheel_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var step = sin(level_time * 2.2 + float(zombie.get("anim_phase", 0.0)))
	var cooldown_ratio = 1.0 - clampf(float(zombie.get("flywheel_cooldown", 0.0)) / maxf(float(Defs.ZOMBIES["flywheel_zombie"].get("throw_cooldown", 5.2)), 0.01), 0.0, 1.0)
	var torso = center + Vector2(0.0, -absf(step) * 1.8)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.8)
	var armor = Color(0.42, 0.46, 0.54, 0.98)
	var blade = Color(0.84, 0.9, 0.96, 0.94)
	draw_line(torso + Vector2(-10.0, 24.0), torso + Vector2(-16.0 - step * 3.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(10.0, 24.0), torso + Vector2(16.0 + step * 3.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-18.0, -14.0), Vector2(36.0, 42.0)), armor, true)
	draw_circle(torso + Vector2(0.0, -30.0), 16.0, skin)
	draw_circle(torso + Vector2(-5.0, -32.0), 2.0, Color.BLACK)
	draw_circle(torso + Vector2(5.0, -32.0), 2.0, Color.BLACK)
	draw_line(torso + Vector2(-10.0, -2.0), torso + Vector2(-24.0, 10.0), Color(0.56, 0.64, 0.54), 4.0)
	draw_line(torso + Vector2(10.0, -4.0), torso + Vector2(24.0 + cooldown_ratio * 6.0, 8.0 - cooldown_ratio * 4.0), Color(0.56, 0.64, 0.54), 4.0)
	var rotor = torso + Vector2(28.0 + cooldown_ratio * 6.0, -6.0)
	draw_circle(rotor, 12.0, Color(0.36, 0.38, 0.44, 0.98))
	for blade_index in range(4):
		var angle = level_time * (4.0 + cooldown_ratio * 8.0) + float(blade_index) * PI * 0.5
		draw_line(rotor, rotor + Vector2(cos(angle), sin(angle)) * 18.0, blade, 2.4)
	draw_circle(rotor, 4.0, Color(0.18, 0.18, 0.2, 0.96))


func _draw_wither_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var step = sin(level_time * 2.8 + float(zombie.get("anim_phase", 0.0)))
	var torso = center + Vector2(0.0, -absf(step) * 2.2)
	var skin = Color(0.48, 0.56, 0.44, 0.96).lerp(Color(1.0, 1.0, 1.0, 0.96), flash * 1.6)
	var robe = Color(0.26, 0.14, 0.18, 0.98)
	draw_circle(torso + Vector2(0.0, 46.0), 12.0, Color(0.04, 0.02, 0.06, 0.2))
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 - step * 4.0, 42.0), Color(0.16, 0.16, 0.18), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 + step * 4.0, 42.0), Color(0.16, 0.16, 0.18), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 40.0)), robe, true)
	draw_circle(torso + Vector2(0.0, -30.0), 16.0, skin)
	draw_circle(torso + Vector2(-5.0, -32.0), 2.0, Color(0.82, 0.96, 0.52, 0.9))
	draw_circle(torso + Vector2(5.0, -32.0), 2.0, Color(0.82, 0.96, 0.52, 0.9))
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-24.0, 10.0), Color(0.42, 0.5, 0.38), 4.0)
	draw_line(torso + Vector2(10.0, 0.0), torso + Vector2(24.0, 10.0), Color(0.42, 0.5, 0.38), 4.0)
	for shard_index in range(5):
		var shard = torso + Vector2(sin(level_time * 2.0 + shard_index) * 22.0, -14.0 + cos(level_time * 1.3 + shard_index) * 18.0)
		draw_rect(Rect2(shard, Vector2(4.0, 4.0)), Color(0.42, 0.1, 0.16, 0.34), true)
	draw_arc(torso + Vector2(0.0, -6.0), 28.0, 0.0, TAU, 24, Color(0.44, 0.12, 0.18, 0.16), 2.0)


func _draw_mech_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var ash_hits = int(zombie.get("ash_hits_taken", 0))
	var laser_ratio = 1.0 - clampf(float(zombie.get("laser_cooldown", 0.0)) / maxf(float(Defs.ZOMBIES["mech_zombie"].get("laser_cooldown", 4.8)), 0.01), 0.0, 1.0)
	var hull = Color(0.42, 0.46, 0.52, 0.98).lerp(Color(1.0, 1.0, 1.0, 0.98), flash * 1.2)
	draw_circle(center + Vector2(-20.0, 24.0), 11.0, Color(0.16, 0.16, 0.18))
	draw_circle(center + Vector2(22.0, 24.0), 11.0, Color(0.16, 0.16, 0.18))
	draw_rect(Rect2(center + Vector2(-34.0, -6.0), Vector2(70.0, 32.0)), hull, true)
	draw_rect(Rect2(center + Vector2(-20.0, -32.0), Vector2(38.0, 26.0)), hull.darkened(0.08), true)
	draw_circle(center + Vector2(0.0, -20.0), 12.0, Color(0.74, 0.82, 0.7))
	draw_circle(center + Vector2(-4.0, -22.0), 2.0, Color.BLACK)
	draw_circle(center + Vector2(4.0, -22.0), 2.0, Color.BLACK)
	draw_line(center + Vector2(16.0, -8.0), center + Vector2(40.0 + laser_ratio * 8.0, -18.0 - laser_ratio * 4.0), Color(0.18, 0.2, 0.26), 7.0)
	draw_circle(center + Vector2(44.0 + laser_ratio * 8.0, -20.0 - laser_ratio * 4.0), 7.0, Color(0.18, 0.2, 0.26))
	draw_circle(center + Vector2(46.0 + laser_ratio * 8.0, -20.0 - laser_ratio * 4.0), 4.0, Color(1.0, 0.24 + laser_ratio * 0.56, 0.24, 0.7))
	for plate_index in range(3):
		draw_rect(Rect2(center + Vector2(-24.0 + plate_index * 18.0, 2.0), Vector2(10.0, 8.0)), Color(0.58, 0.62, 0.7, 0.92), true)
	for scorch_index in range(ash_hits):
		draw_circle(center + Vector2(-12.0 + scorch_index * 12.0, -4.0), 5.0, Color(0.12, 0.08, 0.08, 0.9))


func _draw_wizard_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var cast_ratio = 1.0 - clampf(float(zombie.get("wizard_cooldown", 0.0)) / maxf(float(Defs.ZOMBIES["wizard_zombie"].get("cast_interval", 5.8)), 0.01), 0.0, 1.0)
	var step = sin(level_time * 2.4 + float(zombie.get("anim_phase", 0.0)))
	var torso = center + Vector2(0.0, -absf(step) * 1.8)
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.8)
	var robe = Color(0.34, 0.16, 0.52, 0.98)
	draw_circle(torso + Vector2(0.0, 44.0), 11.0, Color(0.02, 0.02, 0.04, 0.16))
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 - step * 3.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 + step * 3.0, 42.0), Color(0.2, 0.2, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -12.0), Vector2(32.0, 42.0)), robe, true)
	draw_circle(torso + Vector2(0.0, -30.0), 15.0, skin)
	draw_circle(torso + Vector2(-5.0, -32.0), 2.0, Color.BLACK)
	draw_circle(torso + Vector2(5.0, -32.0), 2.0, Color.BLACK)
	draw_polygon(
		PackedVector2Array([
			torso + Vector2(0.0, -62.0),
			torso + Vector2(-18.0, -20.0),
			torso + Vector2(18.0, -20.0),
		]),
		PackedColorArray([robe.darkened(0.08), robe, robe])
	)
	draw_rect(Rect2(torso + Vector2(-20.0, -20.0), Vector2(40.0, 6.0)), Color(0.18, 0.1, 0.28, 0.96), true)
	draw_line(torso + Vector2(12.0, -2.0), torso + Vector2(28.0, 20.0), Color(0.56, 0.42, 0.18), 3.0)
	draw_circle(torso + Vector2(30.0, 18.0), 6.0, Color(0.74, 0.62, 1.0, 0.94))
	for orb_index in range(3):
		var orb_angle = level_time * 3.6 + float(orb_index) * TAU / 3.0
		var orb_radius = 10.0 + cast_ratio * 16.0
		var orb = torso + Vector2(cos(orb_angle) * orb_radius, -12.0 + sin(orb_angle) * (6.0 + cast_ratio * 8.0))
		draw_circle(orb, 3.6, Color(0.84, 0.72, 1.0, 0.3 + cast_ratio * 0.3))


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
	return false


func _load_boss_frame_set(kind: String, face_left: bool = false) -> Array:
	var frames: Array = []
	var frame_count = _boss_frame_count_for_kind(kind)
	for frame_index in range(frame_count):
		frames.append(_load_single_boss_frame(kind, frame_index, face_left))
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
	rumia_frames = _load_boss_frame_set("rumia_boss", expected_face_left)
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
	daiyousei_frames = _load_boss_frame_set("daiyousei_boss", expected_face_left)
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
	cirno_frames = _load_boss_frame_set("cirno_boss", expected_face_left)
	cirno_frames_face_left = expected_face_left
	shared_cirno_frames_loaded = true
	shared_cirno_frames = cirno_frames
	shared_cirno_frames_face_left = expected_face_left


func _ensure_meiling_frames_loaded() -> void:
	var expected_face_left = _boss_frames_face_left("meiling_boss")
	if meiling_frames_loaded and _boss_frame_cache_matches(meiling_frames, MEILING_FRAME_COUNT, expected_face_left, meiling_frames_face_left):
		return
	if shared_meiling_frames_loaded and _boss_frame_cache_matches(shared_meiling_frames, MEILING_FRAME_COUNT, expected_face_left, shared_meiling_frames_face_left):
		meiling_frames_loaded = true
		meiling_frames = shared_meiling_frames
		meiling_frames_face_left = shared_meiling_frames_face_left
		return
	meiling_frames_loaded = true
	meiling_frames = _load_boss_frame_set("meiling_boss", expected_face_left)
	meiling_frames_face_left = expected_face_left
	shared_meiling_frames_loaded = true
	shared_meiling_frames = meiling_frames
	shared_meiling_frames_face_left = expected_face_left


func _ensure_koakuma_frames_loaded() -> void:
	var expected_face_left = _boss_frames_face_left("koakuma_boss")
	if koakuma_frames_loaded and _boss_frame_cache_matches(koakuma_frames, KOAKUMA_FRAME_COUNT, expected_face_left, koakuma_frames_face_left):
		return
	if shared_koakuma_frames_loaded and _boss_frame_cache_matches(shared_koakuma_frames, KOAKUMA_FRAME_COUNT, expected_face_left, shared_koakuma_frames_face_left):
		koakuma_frames_loaded = true
		koakuma_frames = shared_koakuma_frames
		koakuma_frames_face_left = shared_koakuma_frames_face_left
		return
	koakuma_frames_loaded = true
	koakuma_frames = _load_boss_frame_set("koakuma_boss", expected_face_left)
	koakuma_frames_face_left = expected_face_left
	shared_koakuma_frames_loaded = true
	shared_koakuma_frames = koakuma_frames
	shared_koakuma_frames_face_left = expected_face_left


func _ensure_patchouli_frames_loaded() -> void:
	var expected_face_left = _boss_frames_face_left("patchouli_boss")
	if patchouli_frames_loaded and _boss_frame_cache_matches(patchouli_frames, PATCHOULI_FRAME_COUNT, expected_face_left, patchouli_frames_face_left):
		return
	if shared_patchouli_frames_loaded and _boss_frame_cache_matches(shared_patchouli_frames, PATCHOULI_FRAME_COUNT, expected_face_left, shared_patchouli_frames_face_left):
		patchouli_frames_loaded = true
		patchouli_frames = shared_patchouli_frames
		patchouli_frames_face_left = shared_patchouli_frames_face_left
		return
	patchouli_frames_loaded = true
	patchouli_frames = _load_boss_frame_set("patchouli_boss", expected_face_left)
	patchouli_frames_face_left = expected_face_left
	shared_patchouli_frames_loaded = true
	shared_patchouli_frames = patchouli_frames
	shared_patchouli_frames_face_left = expected_face_left


func _ensure_sakuya_frames_loaded() -> void:
	var expected_face_left = _boss_frames_face_left("sakuya_boss")
	if sakuya_frames_loaded and _boss_frame_cache_matches(sakuya_frames, SAKUYA_FRAME_COUNT, expected_face_left, sakuya_frames_face_left):
		return
	if shared_sakuya_frames_loaded and _boss_frame_cache_matches(shared_sakuya_frames, SAKUYA_FRAME_COUNT, expected_face_left, shared_sakuya_frames_face_left):
		sakuya_frames_loaded = true
		sakuya_frames = shared_sakuya_frames
		sakuya_frames_face_left = shared_sakuya_frames_face_left
		return
	sakuya_frames_loaded = true
	sakuya_frames = _load_boss_frame_set("sakuya_boss", expected_face_left)
	sakuya_frames_face_left = expected_face_left
	shared_sakuya_frames_loaded = true
	shared_sakuya_frames = sakuya_frames
	shared_sakuya_frames_face_left = expected_face_left


func _ensure_remilia_frames_loaded() -> void:
	var expected_face_left = _boss_frames_face_left("remilia_boss")
	if remilia_frames_loaded and _boss_frame_cache_matches(remilia_frames, REMILIA_FRAME_COUNT, expected_face_left, remilia_frames_face_left):
		return
	if shared_remilia_frames_loaded and _boss_frame_cache_matches(shared_remilia_frames, REMILIA_FRAME_COUNT, expected_face_left, shared_remilia_frames_face_left):
		remilia_frames_loaded = true
		remilia_frames = shared_remilia_frames
		remilia_frames_face_left = shared_remilia_frames_face_left
		return
	remilia_frames_loaded = true
	remilia_frames = _load_boss_frame_set("remilia_boss", expected_face_left)
	remilia_frames_face_left = expected_face_left
	shared_remilia_frames_loaded = true
	shared_remilia_frames = remilia_frames
	shared_remilia_frames_face_left = expected_face_left


func _rumia_draw_scale(phase: int) -> float:
	return 0.25 + float(phase) * 0.016


func _daiyousei_draw_scale(phase: int) -> float:
	return 0.24 + float(phase) * 0.012


func _cirno_draw_scale(phase: int) -> float:
	return 0.26 + float(phase) * 0.014


func _meiling_draw_scale(phase: int) -> float:
	return 0.27 + float(phase) * 0.015


func _koakuma_draw_scale(phase: int) -> float:
	return 0.24 + float(phase) * 0.012


func _patchouli_draw_scale(phase: int) -> float:
	return 0.275 + float(phase) * 0.013


func _sakuya_draw_scale(phase: int) -> float:
	return 0.245 + float(phase) * 0.012


func _remilia_draw_scale(phase: int) -> float:
	return 0.212 + float(phase) * 0.01


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


func _koakuma_frame_index(zombie: Dictionary) -> int:
	var state = String(zombie.get("rumia_state", "idle"))
	var phase = float(zombie.get("anim_phase", 0.0))
	match state:
		"books":
			return _rumia_cycle_frame([2, 3, 2, 3], 7.8, phase * 0.48)
		"familiar":
			return _rumia_cycle_frame([5, 6, 5, 6], 7.0, phase * 0.56)
		"summon":
			return _rumia_cycle_frame([6, 4, 6, 4], 6.4, phase * 0.42)
		"phase":
			return _rumia_cycle_frame([4, 5, 4, 5], 6.8, phase * 0.44)
		"shift":
			return _rumia_cycle_frame([1, 4, 1, 4], 5.2, phase * 0.28)
		_:
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				return _rumia_cycle_frame([1, 2, 1], 5.8, phase * 0.24)
			return 0
	return 0


func _patchouli_frame_index(zombie: Dictionary) -> int:
	var state = String(zombie.get("rumia_state", "idle"))
	var phase = float(zombie.get("anim_phase", 0.0))
	match state:
		"fire":
			return _rumia_cycle_frame([2, 2, 6, 2], 7.0, phase * 0.5)
		"water":
			return _rumia_cycle_frame([1, 2, 1, 2], 6.0, phase * 0.36)
		"wind":
			return _rumia_cycle_frame([3, 6, 3, 6], 6.4, phase * 0.46)
		"metal":
			return _rumia_cycle_frame([5, 6, 5, 6], 6.8, phase * 0.52)
		"flare":
			return _rumia_cycle_frame([6, 5, 6, 3], 7.4, phase * 0.54)
		"phase":
			return _rumia_cycle_frame([4, 6, 4, 6], 6.4, phase * 0.42)
		"shift":
			return _rumia_cycle_frame([1, 3, 1, 3], 4.8, phase * 0.28)
		_:
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				return _rumia_cycle_frame([1, 0, 1], 5.0, phase * 0.24)
			return 0
	return 0


func _sakuya_frame_index(zombie: Dictionary) -> int:
	var state = String(zombie.get("rumia_state", "idle"))
	var phase = float(zombie.get("anim_phase", 0.0))
	match state:
		"knives":
			return _rumia_cycle_frame([1, 2, 1, 2], 7.6, phase * 0.44)
		"rain":
			return _rumia_cycle_frame([3, 4, 3, 4], 7.2, phase * 0.42)
		"doll":
			return _rumia_cycle_frame([5, 6, 5, 6], 6.4, phase * 0.38)
		"time":
			return _rumia_cycle_frame([6, 7, 6, 7], 5.8, phase * 0.34)
		"clock":
			return _rumia_cycle_frame([4, 2, 4, 2], 6.6, phase * 0.4)
		"summon":
			return _rumia_cycle_frame([2, 5, 2, 5], 6.0, phase * 0.36)
		"phase":
			return _rumia_cycle_frame([7, 5, 7, 5], 6.8, phase * 0.42)
		"shift":
			return _rumia_cycle_frame([3, 0, 3, 0], 8.0, phase * 0.5)
		_:
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				return _rumia_cycle_frame([1, 0, 1], 5.4, phase * 0.24)
			return 0
	return 0


func _remilia_frame_index(zombie: Dictionary) -> int:
	var state = String(zombie.get("rumia_state", "idle"))
	var phase = float(zombie.get("anim_phase", 0.0))
	match state:
		"scarlet":
			return _rumia_cycle_frame([2, 4, 2, 1], 7.2, phase * 0.42)
		"magic":
			return _rumia_cycle_frame([3, 2, 3, 0], 6.4, phase * 0.36)
		"heart":
			return _rumia_cycle_frame([7, 2, 7, 2], 7.8, phase * 0.48)
		"gungnir":
			return _rumia_cycle_frame([4, 7, 4, 7], 7.0, phase * 0.42)
		"cradle":
			return _rumia_cycle_frame([4, 5, 4, 5], 6.2, phase * 0.34)
		"drain":
			return _rumia_cycle_frame([5, 6, 5, 6], 5.8, phase * 0.32)
		"bats":
			return _rumia_cycle_frame([4, 1, 4, 1], 6.6, phase * 0.38)
		"meister":
			return _rumia_cycle_frame([6, 5, 6, 7], 6.0, phase * 0.34)
		"phase":
			return _rumia_cycle_frame([5, 6, 5, 6], 6.4, phase * 0.36)
		"shift":
			return _rumia_cycle_frame([1, 0, 1, 0], 5.6, phase * 0.26)
		_:
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				return _rumia_cycle_frame([1, 0, 1], 5.0, phase * 0.2)
			return 0
	return 0


func _draw_rumia_boss(center: Vector2, zombie: Dictionary) -> void:
	var frame_index = _rumia_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 4
	var texture := _try_get_boss_frame_texture("rumia_boss", frame_index)
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
	var frame_index = _daiyousei_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 4
	var texture := _try_get_boss_frame_texture("daiyousei_boss", frame_index)
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
	var frame_index = _cirno_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 5
	var texture := _try_get_boss_frame_texture("cirno_boss", frame_index)
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


func _meiling_frame_index(zombie: Dictionary) -> int:
	var phase = int(zombie.get("boss_phase", 0))
	match String(zombie.get("boss_state", "")):
		"kick":
			return _rumia_cycle_frame([2, 3, 2, 3], 8.0, phase * 0.5)
		"rainbow":
			return _rumia_cycle_frame([3, 7, 3, 7], 6.4, phase * 0.4)
		"dragon":
			return _rumia_cycle_frame([6, 7, 6, 7], 5.6, phase * 0.38)
		"phase":
			return _rumia_cycle_frame([4, 5, 4, 5], 6.8, phase * 0.42)
		_:
			if float(zombie.get("special_pause_timer", 0.0)) > 0.0:
				return _rumia_cycle_frame([1, 2, 1], 5.8, phase * 0.28)
			return 0
	return 0


func _draw_meiling_boss(center: Vector2, zombie: Dictionary) -> void:
	var frame_index = _meiling_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 4
	_ensure_meiling_frames_loaded()
	var texture := _try_get_boss_frame_texture("meiling_boss", frame_index)
	var draw_scale = _meiling_draw_scale(int(zombie.get("boss_phase", 0)))
	var local_phase = float(zombie.get("anim_phase", 0.0))
	var bob = sin(level_time * 2.7 + local_phase) * 5.8 + sin(level_time * 5.8 + local_phase * 0.72) * 1.3
	var sway = sin(level_time * 1.3 + local_phase) * 8.5
	var aura_center = center + Vector2(sway * 0.05, -32.0 + bob * 0.18)
	draw_circle(center + Vector2(sway * 0.04, 54.0), 22.0, Color(0.06, 0.14, 0.04, 0.12))
	draw_circle(aura_center, 42.0, Color(0.28, 0.82, 0.44, 0.08 + 0.025 * sin(level_time * 2.3 + local_phase)))
	draw_circle(aura_center, 28.0, Color(0.18, 0.52, 0.28, 0.07))
	if texture != null:
		var texture_size = texture.get_size() * draw_scale
		var top_left = center + Vector2(-texture_size.x * 0.5 + sway * 0.05, -texture_size.y * 0.85 + bob)
		draw_texture_rect(texture, Rect2(top_left, texture_size), false, Color(1.0, 1.0, 1.0, 1.0 - float(zombie.get("flash", 0.0)) * 0.25))
	else:
		draw_circle(center + Vector2(0.0, -40.0), 26.0, Color(0.86, 0.56, 0.44))
		draw_rect(Rect2(center + Vector2(-20.0, -14.0), Vector2(40.0, 66.0)), Color(0.22, 0.56, 0.28), true)
		draw_rect(Rect2(center + Vector2(-28.0, -14.0), Vector2(20.0, 66.0)), Color(0.18, 0.48, 0.22), true)
	var orb_colors = [
		Color(0.28, 0.88, 0.5, 0.84),
		Color(0.88, 0.72, 0.22, 0.78),
		Color(0.54, 0.34, 0.92, 0.74),
		Color(0.28, 0.78, 0.96, 0.8),
	]
	for orb_index in range(4):
		var angle = level_time * 2.2 + float(orb_index) * TAU / 4.0 + local_phase * 0.18
		var orb_center = center + Vector2(cos(angle) * 32.0, -26.0 + sin(angle) * 13.0 + bob * 0.16)
		draw_circle(orb_center, 5.5, orb_colors[orb_index])
		draw_circle(orb_center, 9.0, Color(orb_colors[orb_index].r, orb_colors[orb_index].g, orb_colors[orb_index].b, 0.22))


func _draw_koakuma_boss(center: Vector2, zombie: Dictionary) -> void:
	var frame_index = _koakuma_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 4
	_ensure_koakuma_frames_loaded()
	var texture := _try_get_boss_frame_texture("koakuma_boss", frame_index)
	var draw_scale = _koakuma_draw_scale(int(zombie.get("boss_phase", 0)))
	var local_phase = float(zombie.get("anim_phase", 0.0))
	var bob = sin(level_time * 2.7 + local_phase) * 5.2 + sin(level_time * 5.9 + local_phase * 0.7) * 1.2
	var sway = sin(level_time * 1.5 + local_phase) * 7.2
	var aura_center = center + Vector2(sway * 0.05, -30.0 + bob * 0.18)
	draw_circle(center + Vector2(sway * 0.04, 52.0), 20.0, Color(0.08, 0.04, 0.08, 0.12))
	draw_circle(aura_center, 36.0, Color(0.86, 0.16, 0.34, 0.08 + 0.03 * sin(level_time * 2.3 + local_phase)))
	draw_circle(aura_center, 26.0, Color(0.24, 0.06, 0.16, 0.08))
	if texture != null:
		var texture_size = texture.get_size() * draw_scale
		var top_left = center + Vector2(-texture_size.x * 0.5 + sway * 0.04, -texture_size.y * 0.84 + bob)
		draw_texture_rect(texture, Rect2(top_left, texture_size), false, Color(1.0, 1.0, 1.0, 1.0 - float(zombie.get("flash", 0.0)) * 0.25))
	else:
		draw_circle(center + Vector2(0.0, -36.0), 24.0, Color(0.86, 0.34, 0.44))
		draw_rect(Rect2(center + Vector2(-18.0, -12.0), Vector2(36.0, 60.0)), Color(0.18, 0.06, 0.12), true)
	for book_index in range(3):
		var angle = level_time * 2.1 + float(book_index) * TAU / 3.0 + local_phase * 0.2
		var book_center = center + Vector2(cos(angle) * 26.0, -22.0 + sin(angle) * 10.0 + bob * 0.14)
		draw_rect(Rect2(book_center + Vector2(-5.0, -6.0), Vector2(10.0, 12.0)), Color(0.68, 0.2, 0.28, 0.78), true)
		draw_line(book_center + Vector2(0.0, -6.0), book_center + Vector2(0.0, 6.0), Color(1.0, 0.9, 0.8, 0.38), 1.4)


func _draw_patchouli_boss(center: Vector2, zombie: Dictionary) -> void:
	var frame_index = _patchouli_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 4
	_ensure_patchouli_frames_loaded()
	var texture := _try_get_boss_frame_texture("patchouli_boss", frame_index)
	var draw_scale = _patchouli_draw_scale(int(zombie.get("boss_phase", 0)))
	var local_phase = float(zombie.get("anim_phase", 0.0))
	var bob = sin(level_time * 2.4 + local_phase) * 4.8 + sin(level_time * 4.9 + local_phase * 0.7) * 1.1
	var sway = sin(level_time * 1.1 + local_phase) * 6.0
	var aura_center = center + Vector2(sway * 0.05, -34.0 + bob * 0.16)
	draw_circle(center + Vector2(sway * 0.04, 54.0), 22.0, Color(0.1, 0.08, 0.14, 0.12))
	draw_circle(aura_center, 42.0, Color(0.72, 0.5, 0.96, 0.09 + 0.03 * sin(level_time * 2.1 + local_phase)))
	draw_circle(aura_center, 28.0, Color(0.3, 0.18, 0.54, 0.08))
	if texture != null:
		var texture_size = texture.get_size() * draw_scale
		var top_left = center + Vector2(-texture_size.x * 0.5 + sway * 0.04, -texture_size.y * 0.85 + bob)
		draw_texture_rect(texture, Rect2(top_left, texture_size), false, Color(1.0, 1.0, 1.0, 1.0 - float(zombie.get("flash", 0.0)) * 0.25))
	else:
		draw_circle(center + Vector2(0.0, -42.0), 26.0, Color(0.84, 0.68, 0.96))
		draw_rect(Rect2(center + Vector2(-22.0, -14.0), Vector2(44.0, 66.0)), Color(0.46, 0.28, 0.66), true)
	var gem_colors = [
		Color(0.96, 0.44, 0.28, 0.82),
		Color(0.42, 0.86, 1.0, 0.8),
		Color(0.62, 0.98, 0.54, 0.78),
		Color(0.94, 0.9, 0.42, 0.74),
		Color(0.94, 0.54, 0.86, 0.72),
	]
	for gem_index in range(gem_colors.size()):
		var angle = level_time * 1.8 + float(gem_index) * TAU / float(gem_colors.size()) + local_phase * 0.15
		var gem_center = center + Vector2(cos(angle) * 34.0, -24.0 + sin(angle) * 14.0 + bob * 0.14)
		draw_circle(gem_center, 5.0, gem_colors[gem_index])
		draw_circle(gem_center, 10.0, Color(gem_colors[gem_index].r, gem_colors[gem_index].g, gem_colors[gem_index].b, 0.18))


func _draw_sakuya_boss(center: Vector2, zombie: Dictionary) -> void:
	var frame_index = _sakuya_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 7
	_ensure_sakuya_frames_loaded()
	var texture := _try_get_boss_frame_texture("sakuya_boss", frame_index)
	var draw_scale = _sakuya_draw_scale(int(zombie.get("boss_phase", 0)))
	var local_phase = float(zombie.get("anim_phase", 0.0))
	var bob = sin(level_time * 2.0 + local_phase) * 4.4 + sin(level_time * 5.0 + local_phase * 0.8) * 1.1
	var sway = sin(level_time * 1.2 + local_phase) * 5.2
	var aura_center = center + Vector2(sway * 0.04, -36.0 + bob * 0.15)
	var flash_mul = 1.0 if boss_time_stop_timer <= 0.0 else 1.25
	draw_circle(center + Vector2(sway * 0.04, 54.0), 20.0, Color(0.08, 0.1, 0.14, 0.12))
	draw_circle(aura_center, 40.0, Color(0.82, 0.9, 1.0, (0.08 + 0.03 * sin(level_time * 2.2 + local_phase)) * flash_mul))
	draw_circle(aura_center, 26.0, Color(0.26, 0.34, 0.52, 0.08))
	if texture != null:
		var texture_size = texture.get_size() * draw_scale
		var top_left = center + Vector2(-texture_size.x * 0.5 + sway * 0.04, -texture_size.y * 0.85 + bob)
		draw_texture_rect(texture, Rect2(top_left, texture_size), false, Color(1.0, 1.0, 1.0, 1.0 - float(zombie.get("flash", 0.0)) * 0.25))
	else:
		draw_circle(center + Vector2(0.0, -40.0), 24.0, Color(0.86, 0.9, 0.96))
		draw_rect(Rect2(center + Vector2(-18.0, -12.0), Vector2(36.0, 62.0)), Color(0.22, 0.28, 0.44), true)
	for hand_index in range(6):
		var angle = level_time * 1.4 + float(hand_index) * TAU / 6.0 + local_phase * 0.16
		var hand_radius = 28.0 + float(hand_index % 2) * 8.0
		var tick_center = center + Vector2(cos(angle) * hand_radius, -26.0 + sin(angle) * (12.0 + float(hand_index % 2) * 3.0) + bob * 0.12)
		draw_line(tick_center, tick_center + Vector2(cos(angle) * 8.0, sin(angle) * 8.0), Color(0.88, 0.92, 1.0, 0.64), 2.0)
		draw_circle(tick_center, 2.2, Color(0.76, 0.86, 1.0, 0.56))
	if boss_time_stop_timer > 0.0:
		var stop_alpha = clampf(boss_time_stop_timer / maxf(float(Defs.ZOMBIES["sakuya_boss"].get("time_stop_duration", 2.3)), 0.01), 0.0, 1.0)
		draw_circle(center + Vector2(0.0, -14.0), 66.0 + sin(level_time * 5.4) * 4.0, Color(0.86, 0.92, 1.0, 0.06 + stop_alpha * 0.08))


func _draw_remilia_boss(center: Vector2, zombie: Dictionary) -> void:
	var frame_index = _remilia_frame_index(zombie)
	if float(zombie.get("impact_timer", 0.0)) > 0.0:
		frame_index = 5
	_ensure_remilia_frames_loaded()
	var texture := _try_get_boss_frame_texture("remilia_boss", frame_index)
	var draw_scale = _remilia_draw_scale(int(zombie.get("boss_phase", 0)))
	var local_phase = float(zombie.get("anim_phase", 0.0))
	var bob = sin(level_time * 1.8 + local_phase) * 4.8 + sin(level_time * 4.7 + local_phase * 0.7) * 1.2
	var sway = sin(level_time * 1.1 + local_phase) * 4.4
	var aura_center = center + Vector2(sway * 0.05, -42.0 + bob * 0.14)
	var pulse = 0.08 + 0.034 * sin(level_time * 2.0 + local_phase)
	draw_circle(center + Vector2(sway * 0.04, 50.0), 22.0, Color(0.12, 0.02, 0.04, 0.16))
	draw_circle(aura_center, 48.0, Color(0.96, 0.12, 0.18, pulse))
	draw_circle(aura_center, 30.0, Color(0.28, 0.02, 0.08, 0.12))
	if texture != null:
		var texture_size = texture.get_size() * draw_scale
		var top_left = center + Vector2(-texture_size.x * 0.5 + sway * 0.04, -texture_size.y * 0.86 + bob)
		draw_texture_rect(texture, Rect2(top_left, texture_size), false, Color(1.0, 1.0, 1.0, 1.0 - float(zombie.get("flash", 0.0)) * 0.25))
	else:
		draw_circle(center + Vector2(0.0, -42.0), 26.0, Color(0.94, 0.76, 0.82))
		draw_rect(Rect2(center + Vector2(-22.0, -14.0), Vector2(44.0, 66.0)), Color(0.42, 0.12, 0.18), true)
	var orb_colors = [
		Color(0.98, 0.18, 0.24, 0.86),
		Color(1.0, 0.4, 0.26, 0.78),
		Color(0.94, 0.68, 0.92, 0.68),
	]
	for orb_index in range(orb_colors.size()):
		var angle = level_time * 1.6 + float(orb_index) * TAU / float(orb_colors.size()) + local_phase * 0.16
		var radius = 32.0 + float(orb_index % 2) * 10.0
		var orb_center = center + Vector2(cos(angle) * radius, -26.0 + sin(angle) * (12.0 + float(orb_index) * 2.0) + bob * 0.14)
		draw_circle(orb_center, 5.6, orb_colors[orb_index])
		draw_circle(orb_center, 10.0, Color(orb_colors[orb_index].r, orb_colors[orb_index].g, orb_colors[orb_index].b, 0.2))
	if String(zombie.get("rumia_state", "")) == "drain":
		draw_circle(center + Vector2(0.0, -18.0), 72.0 + sin(level_time * 4.8) * 5.0, Color(0.96, 0.14, 0.22, 0.06))


func _draw_dragon_boat_zombie(center: Vector2, zombie: Dictionary) -> void:
	var state = _dragon_boat_visual_state(center, zombie)
	var flash = float(state["flash"])
	draw_circle(Vector2(state["shadow_center"]), 26.0, Color(0.0, 0.18, 0.28, 0.12))
	draw_polygon(
		PackedVector2Array(state["hull"]),
		PackedColorArray([
			Color(0.54, 0.2, 0.08),
			Color(0.68, 0.28, 0.12),
			Color(0.74, 0.34, 0.14),
			Color(0.64, 0.24, 0.1),
			Color(0.58, 0.2, 0.08),
			Color(0.52, 0.18, 0.08),
		])
	)
	for rider_variant in state["riders"]:
		var rider: Dictionary = rider_variant
		draw_circle(Vector2(rider["center"]), 11.0, Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 2.0))
		draw_rect(Rect2(rider["body_rect"]), Color(0.34, 0.46, 0.72), true)
		draw_line(Vector2(rider["paddle_from"]), Vector2(rider["paddle_to"]), Color(0.62, 0.44, 0.18), 2.0)
	draw_line(Vector2(state["flag_a_from"]), Vector2(state["flag_a_to"]), Color(0.96, 0.76, 0.22), 3.0)
	draw_line(Vector2(state["flag_b_from"]), Vector2(state["flag_b_to"]), Color(0.96, 0.34, 0.18), 3.0)
	draw_line(Vector2(state["oar_left_from"]), Vector2(state["oar_left_to"]), Color(0.68, 0.48, 0.18), 3.0)
	draw_line(Vector2(state["oar_mid_from"]), Vector2(state["oar_mid_to"]), Color(0.68, 0.48, 0.18), 3.0)


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


func _draw_squash_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var body = Color(0.56, 0.88, 0.24).lerp(Color(1.0, 1.0, 1.0), flash * 1.8)
	var stem = Color(0.26, 0.56, 0.16)
	var squash_offset = -6.0 if bool(zombie.get("squash_active", false)) else 0.0
	draw_line(center + Vector2(-4.0, 12.0), center + Vector2(-8.0, 36.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_line(center + Vector2(6.0, 12.0), center + Vector2(10.0, 36.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_circle(center + Vector2(0.0, -4.0 + squash_offset), 24.0, body)
	draw_circle(center + Vector2(-12.0, -6.0 + squash_offset), 8.0, Color(0.7, 0.96, 0.3))
	draw_circle(center + Vector2(12.0, -8.0 + squash_offset), 8.0, Color(0.7, 0.96, 0.3))
	draw_line(center + Vector2(0.0, -30.0 + squash_offset), center + Vector2(6.0, -42.0 + squash_offset), stem, 4.0)
	draw_circle(center + Vector2(-8.0, -8.0 + squash_offset), 2.6, Color.BLACK)
	draw_circle(center + Vector2(8.0, -8.0 + squash_offset), 2.6, Color.BLACK)
	draw_arc(center + Vector2(0.0, 8.0 + squash_offset), 9.0, 0.1, PI - 0.1, 12, Color.BLACK, 2.0)


func _draw_excavator_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var body = Color(0.94, 0.76, 0.2).lerp(Color(1.0, 1.0, 1.0), flash * 1.8)
	var cabin = Color(0.28, 0.38, 0.44)
	var scoop = sin(level_time * 2.6 + float(zombie.get("anim_phase", 0.0))) * 6.0
	draw_rect(Rect2(center + Vector2(-34.0, -2.0), Vector2(68.0, 28.0)), body, true)
	draw_rect(Rect2(center + Vector2(-12.0, -24.0), Vector2(26.0, 20.0)), cabin, true)
	draw_circle(center + Vector2(-20.0, 22.0), 10.0, Color(0.18, 0.18, 0.18))
	draw_circle(center + Vector2(18.0, 22.0), 10.0, Color(0.18, 0.18, 0.18))
	draw_circle(center + Vector2(-2.0, -30.0), 10.0, Color(0.74, 0.82, 0.7))
	draw_line(center + Vector2(14.0, -12.0), center + Vector2(34.0, -18.0 - scoop), body.darkened(0.2), 5.0)
	draw_line(center + Vector2(34.0, -18.0 - scoop), center + Vector2(48.0, -4.0 - scoop * 0.6), body.darkened(0.24), 4.0)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(48.0, -4.0 - scoop * 0.6),
			center + Vector2(64.0, -2.0 - scoop * 0.6),
			center + Vector2(54.0, 14.0 - scoop * 0.3),
		]),
		PackedColorArray([Color(0.62, 0.62, 0.66), Color(0.62, 0.62, 0.66), Color(0.62, 0.62, 0.66)])
	)


func _draw_barrel_screen_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var torso = center + Vector2(0.0, -4.0)
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
	draw_rect(Rect2(torso + Vector2(-16.0, -10.0), Vector2(32.0, 38.0)), Color(0.28, 0.44, 0.62).lerp(Color(1.0, 1.0, 1.0), flash * 1.6), true)
	draw_circle(torso + Vector2(0.0, -28.0), 16.0, Color(0.74, 0.82, 0.7))
	draw_rect(Rect2(torso + Vector2(8.0, -18.0), Vector2(30.0, 48.0)), Color(0.44, 0.56, 0.66, 0.92), true)
	draw_rect(Rect2(torso + Vector2(8.0, -18.0), Vector2(30.0, 48.0)), Color(0.24, 0.28, 0.34), false, 2.0)
	draw_rect(Rect2(torso + Vector2(-18.0, -54.0), Vector2(36.0, 24.0)), Color(0.62, 0.62, 0.66), true)
	draw_rect(Rect2(torso + Vector2(-22.0, -60.0), Vector2(44.0, 8.0)), Color(0.72, 0.72, 0.76), true)


func _draw_tornado_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var skin = Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.6)
	var phase = level_time * 5.8 + float(zombie.get("anim_phase", 0.0))
	for ring_index in range(4):
		var ring_radius = 16.0 + ring_index * 8.0
		draw_arc(center + Vector2(0.0, 18.0 - ring_index * 10.0), ring_radius, phase + ring_index * 0.3, phase + ring_index * 0.3 + PI * 1.25, 20, Color(0.82, 0.94, 1.0, 0.5 - ring_index * 0.08), 2.0)
	draw_circle(center + Vector2(0.0, -28.0), 14.0, skin)
	draw_rect(Rect2(center + Vector2(-12.0, -12.0), Vector2(24.0, 26.0)), Color(0.52, 0.58, 0.64, 0.84), true)


func _draw_wolf_knight_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var mounted = bool(zombie.get("mounted", false))
	if mounted:
		draw_circle(center + Vector2(0.0, 12.0), 22.0, Color(0.42, 0.42, 0.44))
		draw_circle(center + Vector2(20.0, 2.0), 14.0, Color(0.42, 0.42, 0.44))
		draw_polygon(
			PackedVector2Array([
				center + Vector2(24.0, -8.0),
				center + Vector2(32.0, -20.0),
				center + Vector2(18.0, -16.0),
			]),
			PackedColorArray([Color(0.28, 0.28, 0.3), Color(0.28, 0.28, 0.3), Color(0.28, 0.28, 0.3)])
		)
		draw_line(center + Vector2(-12.0, 24.0), center + Vector2(-20.0, 40.0), Color(0.18, 0.18, 0.18), 4.0)
		draw_line(center + Vector2(6.0, 24.0), center + Vector2(0.0, 40.0), Color(0.18, 0.18, 0.18), 4.0)
		draw_line(center + Vector2(24.0, 20.0), center + Vector2(18.0, 40.0), Color(0.18, 0.18, 0.18), 4.0)
		draw_circle(center + Vector2(-2.0, -20.0), 12.0, Color(0.74, 0.82, 0.7).lerp(Color(1.0, 1.0, 1.0), flash * 1.6))
		draw_rect(Rect2(center + Vector2(-12.0, -10.0), Vector2(24.0, 18.0)), Color(0.56, 0.2, 0.16), true)
		draw_rect(Rect2(center + Vector2(-14.0, -34.0), Vector2(28.0, 10.0)), Color(0.66, 0.66, 0.72), true)
	else:
		draw_line(center + Vector2(-8.0, 24.0), center + Vector2(-14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
		draw_line(center + Vector2(8.0, 24.0), center + Vector2(14.0, 42.0), Color(0.22, 0.22, 0.22), 4.0)
		draw_rect(Rect2(center + Vector2(-16.0, -10.0), Vector2(32.0, 38.0)), Color(0.56, 0.2, 0.16).lerp(Color(1.0, 1.0, 1.0), flash * 1.6), true)
		draw_circle(center + Vector2(0.0, -28.0), 16.0, Color(0.74, 0.82, 0.7))
		var wolf_offset = float(zombie.get("wolf_escape_offset", 0.0))
		if wolf_offset > 0.0:
			draw_circle(center + Vector2(24.0 + wolf_offset, 14.0), 14.0, Color(0.42, 0.42, 0.44, 0.72))
			draw_circle(center + Vector2(38.0 + wolf_offset, 8.0), 10.0, Color(0.42, 0.42, 0.44, 0.72))


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


func _draw_fog_boss(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var phase = int(zombie.get("boss_phase", 0))
	var bob = sin(level_time * 1.8 + float(zombie.get("anim_phase", 0.0))) * 3.6
	var torso = center + Vector2(0.0, -10.0 + bob)
	var body_color = Color(0.18, 0.44, 0.36).lerp(Color(1.0, 1.0, 1.0), flash * 1.35)
	draw_circle(torso + Vector2(0.0, 68.0), 36.0, Color(0.04, 0.12, 0.1, 0.18))
	draw_circle(torso + Vector2(0.0, 70.0), 58.0 + phase * 6.0, Color(0.62, 0.96, 0.84, 0.05))
	draw_rect(Rect2(torso + Vector2(-38.0, -16.0), Vector2(76.0, 88.0)), body_color, true)
	draw_polygon(
		PackedVector2Array([
			torso + Vector2(-52.0, 2.0),
			torso + Vector2(-82.0, 64.0),
			torso + Vector2(-16.0, 72.0),
			torso + Vector2(0.0, 20.0),
		]),
		PackedColorArray([
			Color(0.14, 0.34, 0.28, 0.9),
			Color(0.08, 0.22, 0.18, 0.84),
			Color(0.26, 0.56, 0.46, 0.76),
			Color(0.18, 0.44, 0.36, 0.88),
		])
	)
	draw_polygon(
		PackedVector2Array([
			torso + Vector2(52.0, 2.0),
			torso + Vector2(82.0, 64.0),
			torso + Vector2(16.0, 72.0),
			torso + Vector2(0.0, 20.0),
		]),
		PackedColorArray([
			Color(0.14, 0.34, 0.28, 0.9),
			Color(0.08, 0.22, 0.18, 0.84),
			Color(0.26, 0.56, 0.46, 0.76),
			Color(0.18, 0.44, 0.36, 0.88),
		])
	)
	draw_circle(torso + Vector2(0.0, -38.0), 26.0, Color(0.78, 0.86, 0.74))
	draw_rect(Rect2(torso + Vector2(-30.0, -60.0), Vector2(60.0, 18.0)), Color(0.08, 0.24, 0.2), true)
	draw_line(torso + Vector2(-18.0, 22.0), torso + Vector2(-38.0, 60.0), Color(0.18, 0.2, 0.18), 6.0)
	draw_line(torso + Vector2(18.0, 22.0), torso + Vector2(38.0, 60.0), Color(0.18, 0.2, 0.18), 6.0)
	draw_line(torso + Vector2(26.0, -8.0), torso + Vector2(62.0, -24.0), Color(0.78, 0.94, 0.88), 5.0)
	draw_line(torso + Vector2(62.0, -24.0), torso + Vector2(76.0, -8.0), Color(0.78, 0.94, 0.88), 4.0)
	draw_line(torso + Vector2(62.0, -24.0), torso + Vector2(78.0, -40.0), Color(0.78, 0.94, 0.88), 4.0)
	for orbit_index in range(5 + phase):
		var orbit = level_time * (1.45 + float(phase) * 0.16) + float(orbit_index) * TAU / float(5 + phase)
		var orb_center = torso + Vector2(cos(orbit) * (44.0 + phase * 3.0), 10.0 + sin(orbit) * (18.0 + phase * 1.6))
		draw_circle(orb_center, 5.4 + float(phase) * 0.34, Color(0.82, 1.0, 0.9, 0.8))
		draw_circle(orb_center, 12.0, Color(0.2, 0.56, 0.46, 0.18))
	for mist_index in range(4 + phase):
		var drift = level_time * (16.0 + float(mist_index) * 3.0) + float(mist_index) * 0.9
		var mist_center = torso + Vector2(-64.0 + fmod(drift * 0.62, 132.0), 20.0 + sin(drift) * 11.0)
		draw_circle(mist_center, 18.0, Color(0.78, 0.98, 0.9, 0.1))
		draw_circle(mist_center + Vector2(12.0, -5.0), 11.0, Color(0.62, 0.9, 0.82, 0.1))
		draw_circle(mist_center + Vector2(-10.0, 4.0), 8.0, Color(0.62, 0.9, 0.82, 0.08))


func _draw_roof_boss(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie.get("flash", 0.0))
	var phase = int(zombie.get("boss_phase", 0))
	var bob = sin(level_time * 1.9 + float(zombie.get("anim_phase", 0.0))) * 2.8
	var torso = center + Vector2(0.0, -10.0 + bob)
	var body_color = Color(0.52, 0.22, 0.14).lerp(Color(1.0, 1.0, 1.0), flash * 1.35)
	draw_circle(torso + Vector2(0.0, 74.0), 40.0, Color(0.14, 0.08, 0.06, 0.18))
	draw_rect(Rect2(torso + Vector2(-42.0, -10.0), Vector2(84.0, 92.0)), body_color, true)
	draw_rect(Rect2(torso + Vector2(-50.0, -20.0), Vector2(100.0, 18.0)), Color(0.74, 0.34, 0.18), true)
	draw_polygon(
		PackedVector2Array([
			torso + Vector2(-58.0, 10.0),
			torso + Vector2(-92.0, 62.0),
			torso + Vector2(-18.0, 74.0),
			torso + Vector2(-6.0, 18.0),
		]),
		PackedColorArray([
			Color(0.62, 0.26, 0.16, 0.88),
			Color(0.34, 0.12, 0.08, 0.84),
			Color(0.84, 0.46, 0.26, 0.72),
			Color(0.56, 0.22, 0.14, 0.86),
		])
	)
	draw_polygon(
		PackedVector2Array([
			torso + Vector2(58.0, 10.0),
			torso + Vector2(92.0, 62.0),
			torso + Vector2(18.0, 74.0),
			torso + Vector2(6.0, 18.0),
		]),
		PackedColorArray([
			Color(0.62, 0.26, 0.16, 0.88),
			Color(0.34, 0.12, 0.08, 0.84),
			Color(0.84, 0.46, 0.26, 0.72),
			Color(0.56, 0.22, 0.14, 0.86),
		])
	)
	draw_circle(torso + Vector2(0.0, -34.0), 24.0, Color(0.78, 0.82, 0.72))
	draw_rect(Rect2(torso + Vector2(-34.0, -58.0), Vector2(68.0, 16.0)), Color(0.24, 0.18, 0.14), true)
	draw_line(torso + Vector2(-20.0, 20.0), torso + Vector2(-42.0, 64.0), Color(0.22, 0.18, 0.16), 6.0)
	draw_line(torso + Vector2(20.0, 20.0), torso + Vector2(42.0, 64.0), Color(0.22, 0.18, 0.16), 6.0)
	draw_line(torso + Vector2(24.0, -10.0), torso + Vector2(62.0, -28.0), Color(0.9, 0.78, 0.56), 5.0)
	draw_line(torso + Vector2(62.0, -28.0), torso + Vector2(84.0, -28.0), Color(0.9, 0.78, 0.56), 4.0)
	draw_line(torso + Vector2(62.0, -28.0), torso + Vector2(78.0, -46.0), Color(0.9, 0.78, 0.56), 4.0)
	for orbit_index in range(4 + phase):
		var orbit = level_time * (1.3 + float(phase) * 0.14) + float(orbit_index) * TAU / float(4 + phase)
		var orb_center = torso + Vector2(cos(orbit) * (42.0 + phase * 3.0), 12.0 + sin(orbit) * (16.0 + phase * 1.6))
		draw_circle(orb_center, 5.0 + float(phase) * 0.3, Color(1.0, 0.78, 0.36, 0.78))
		draw_circle(orb_center, 12.0, Color(0.74, 0.24, 0.08, 0.16))
	for shard_index in range(3 + phase):
		var shard_phase = level_time * 0.9 + float(shard_index) * 1.1
		var shard_center = torso + Vector2(-44.0 + float(shard_index) * 26.0, -12.0 + sin(shard_phase) * 8.0)
		draw_polygon(
			PackedVector2Array([
				shard_center + Vector2(-6.0, 0.0),
				shard_center + Vector2(0.0, -10.0),
				shard_center + Vector2(7.0, 2.0),
				shard_center + Vector2(0.0, 12.0),
			]),
			PackedColorArray([
				Color(0.98, 0.66, 0.24, 0.62),
				Color(1.0, 0.86, 0.54, 0.76),
				Color(0.94, 0.54, 0.18, 0.64),
				Color(0.82, 0.22, 0.08, 0.4),
			])
		)


func _draw_zombie(center: Vector2, zombie: Dictionary) -> void:
	var flash = float(zombie["flash"])
	var slow_tint = 0.55 if float(zombie["slow_timer"]) > 0.0 else 0.0
	var kind = String(zombie["kind"])
	if kind == "bungee_zombie":
		_draw_bungee_zombie(center, zombie)
		return
	if kind == "ladder_zombie":
		_draw_ladder_zombie(center, zombie)
		return
	if kind == "catapult_zombie":
		_draw_catapult_zombie(center, zombie)
		return
	if kind == "gargantuar":
		_draw_gargantuar(center, zombie)
		return
	if kind == "imp":
		_draw_imp(center, zombie)
		return
	if kind == "kite_zombie":
		_draw_kite_zombie(center, zombie)
		return
	if kind == "kite_trap":
		_draw_kite_trap(center, zombie)
		return
	if kind == "hive_zombie":
		_draw_hive_zombie(center, zombie)
		return
	if kind == "bee_minion":
		_draw_bee_minion(center, zombie)
		return
	if kind == "turret_zombie":
		_draw_turret_zombie(center, zombie)
		return
	if kind == "programmer_zombie":
		_draw_programmer_zombie(center, zombie)
		return
	if kind == "wenjie_zombie":
		_draw_wenjie_zombie(center, zombie)
		return
	if kind == "janitor_zombie":
		_draw_janitor_zombie(center, zombie)
		return
	if kind == "subway_zombie":
		_draw_subway_zombie(center, zombie)
		return
	if kind == "enderman_zombie":
		_draw_enderman_zombie(center, zombie)
		return
	if kind == "router_zombie":
		_draw_router_zombie(center, zombie)
		return
	if kind == "ski_zombie":
		_draw_ski_zombie(center, zombie)
		return
	if kind == "flywheel_zombie":
		_draw_flywheel_zombie(center, zombie)
		return
	if kind == "wither_zombie":
		_draw_wither_zombie(center, zombie)
		return
	if kind == "mech_zombie":
		_draw_mech_zombie(center, zombie)
		return
	if kind == "wizard_zombie":
		_draw_wizard_zombie(center, zombie)
		return
	if kind == "rumia_boss":
		_draw_rumia_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "daiyousei_boss":
		_draw_daiyousei_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "cirno_boss":
		_draw_cirno_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "meiling_boss":
		_draw_meiling_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "koakuma_boss":
		_draw_koakuma_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "patchouli_boss":
		_draw_patchouli_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "sakuya_boss":
		_draw_sakuya_boss(center + Vector2(0.0, -10.0), zombie)
		return
	if kind == "remilia_boss":
		_draw_remilia_boss(center + Vector2(0.0, -10.0), zombie)
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
	if kind == "squash_zombie":
		_draw_squash_zombie(center, zombie)
		return
	if kind == "excavator_zombie":
		_draw_excavator_zombie(center, zombie)
		return
	if kind == "barrel_screen_zombie":
		_draw_barrel_screen_zombie(center, zombie)
		return
	if kind == "tornado_zombie":
		_draw_tornado_zombie(center, zombie)
		return
	if kind == "wolf_knight_zombie":
		_draw_wolf_knight_zombie(center, zombie)
		return
	if kind == "dragon_dance":
		_draw_dragon_dance_zombie(center, zombie)
		return
	if kind == "pool_boss":
		_draw_pool_boss(center + Vector2(0.0, -6.0), zombie)
		return
	if kind == "fog_boss":
		_draw_fog_boss(center + Vector2(0.0, -6.0), zombie)
		return
	if kind == "roof_boss":
		_draw_roof_boss(center + Vector2(0.0, -6.0), zombie)
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
		"balloon_zombie":
			shirt_base = Color(0.62, 0.2, 0.52)
			pants_base = Color(0.18, 0.18, 0.24)
		"digger_zombie":
			shirt_base = Color(0.64, 0.42, 0.18)
			pants_base = Color(0.18, 0.2, 0.18)
		"pogo_zombie":
			shirt_base = Color(0.82, 0.32, 0.18)
			pants_base = Color(0.14, 0.16, 0.18)
		"jack_in_the_box_zombie":
			shirt_base = Color(0.76, 0.18, 0.18)
			pants_base = Color(0.12, 0.12, 0.16)
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
	# Shadow under zombie
	draw_circle(torso + Vector2(0.0, 46.0), 14.0, Color(0.0, 0.0, 0.0, 0.06))
	# Legs with shoes
	draw_line(torso + Vector2(-8.0, 24.0), torso + Vector2(-14.0 + leg_swing, 42.0), Color(0.2, 0.2, 0.2), 4.0)
	draw_line(torso + Vector2(8.0, 24.0), torso + Vector2(14.0 - leg_swing, 42.0), Color(0.2, 0.2, 0.2), 4.0)
	draw_circle(torso + Vector2(-14.0 + leg_swing, 43.0), 3.0, Color(0.16, 0.14, 0.12))
	draw_circle(torso + Vector2(14.0 - leg_swing, 43.0), 3.0, Color(0.16, 0.14, 0.12))
	# Shirt body with gradient effect
	draw_rect(Rect2(torso + Vector2(-16.0, -10.0), Vector2(32.0, 38.0)), shirt, true)
	draw_rect(Rect2(torso + Vector2(-16.0, -10.0), Vector2(32.0, 12.0)), shirt.lightened(0.06), true)
	# Pants
	draw_rect(Rect2(torso + Vector2(-15.0, 16.0), Vector2(30.0, 12.0)), pants, true)
	# Belt
	draw_rect(Rect2(torso + Vector2(-15.0, 14.0), Vector2(30.0, 4.0)), Color(0.18, 0.16, 0.12), true)
	# Arms
	draw_line(torso + Vector2(-10.0, 0.0), torso + Vector2(-24.0 - arm_swing - bite_ratio * 4.0, 8.0 + arm_swing * 0.25 - bite_ratio * 6.0), Color(0.54, 0.62, 0.52), 4.0)
	draw_line(torso + Vector2(10.0, 0.0), torso + Vector2(24.0 + arm_swing + bite_ratio * 14.0, 8.0 - arm_swing * 0.25 + bite_ratio * 6.0), Color(0.54, 0.62, 0.52), 4.0)
	# Hands
	draw_circle(torso + Vector2(-24.0 - arm_swing - bite_ratio * 4.0, 8.0 + arm_swing * 0.25 - bite_ratio * 6.0), 3.0, Color(0.52, 0.6, 0.5))
	draw_circle(torso + Vector2(24.0 + arm_swing + bite_ratio * 14.0, 8.0 - arm_swing * 0.25 + bite_ratio * 6.0), 3.0, Color(0.52, 0.6, 0.5))
	# Head
	draw_circle(torso + Vector2(0.0, -28.0), 17.0, skin)
	# Head highlight
	draw_circle(torso + Vector2(-4.0, -34.0), 6.0, skin.lightened(0.08))
	# Eyes
	draw_circle(torso + Vector2(-6.0, -30.0), 2.8, Color(0.96, 0.96, 0.86))
	draw_circle(torso + Vector2(6.0, -30.0), 2.8, Color(0.96, 0.96, 0.86))
	draw_circle(torso + Vector2(-6.0, -30.0), 1.6, Color.BLACK)
	draw_circle(torso + Vector2(6.0, -30.0), 1.6, Color.BLACK)
	# Mouth
	draw_line(torso + Vector2(-3.0, -18.0), torso + Vector2(3.0, -18.0), Color(0.16, 0.16, 0.16), 2.0)

	match kind:
		"normal":
			# Tie
			draw_line(torso + Vector2(0.0, -10.0), torso + Vector2(0.0, 24.0), Color(0.82, 0.12, 0.12), 2.5)
			draw_polygon(PackedVector2Array([torso + Vector2(-4.0, 8.0), torso + Vector2(4.0, 8.0), torso + Vector2(0.0, 16.0)]), PackedColorArray([Color(0.82, 0.12, 0.12), Color(0.82, 0.12, 0.12), Color(0.82, 0.12, 0.12)]))
			# Hair
			draw_line(torso + Vector2(0.0, -42.0), torso + Vector2(4.0, -50.0), Color(0.16, 0.14, 0.1), 3.0)
			draw_line(torso + Vector2(-4.0, -42.0), torso + Vector2(-8.0, -48.0), Color(0.16, 0.14, 0.1), 2.5)
			draw_line(torso + Vector2(4.0, -42.0), torso + Vector2(10.0, -48.0), Color(0.16, 0.14, 0.1), 2.0)
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
		"balloon_zombie":
			if bool(zombie.get("balloon_flying", false)):
				var balloon_center = torso + Vector2(18.0, -90.0)
				draw_line(torso + Vector2(10.0, -36.0), balloon_center + Vector2(-2.0, 18.0), Color(0.82, 0.82, 0.86), 2.0)
				draw_circle(balloon_center, 20.0, Color(0.92, 0.24, 0.28))
				draw_circle(balloon_center + Vector2(-6.0, -6.0), 6.0, Color(1.0, 0.74, 0.76, 0.36))
			else:
				draw_arc(torso + Vector2(10.0, -52.0), 10.0, -0.6, 0.8, 12, Color(0.92, 0.24, 0.28, 0.42), 2.0)
				draw_arc(torso + Vector2(20.0, -44.0), 6.0, -0.8, 1.0, 12, Color(0.92, 0.24, 0.28, 0.32), 2.0)
		"digger_zombie":
			draw_rect(Rect2(torso + Vector2(-16.0, -54.0), Vector2(32.0, 14.0)), Color(0.92, 0.78, 0.22), true)
			draw_circle(torso + Vector2(0.0, -40.0), 6.0, Color(1.0, 0.96, 0.6, 0.34))
			draw_line(torso + Vector2(18.0, -10.0), torso + Vector2(32.0, -34.0), Color(0.52, 0.36, 0.18), 3.0)
			draw_line(torso + Vector2(30.0, -36.0), torso + Vector2(38.0, -24.0), Color(0.72, 0.72, 0.76), 3.0)
			if bool(zombie.get("digger_tunneling", false)):
				draw_rect(Rect2(torso + Vector2(-28.0, 2.0), Vector2(56.0, 28.0)), Color(0.48, 0.34, 0.18, 0.72), true)
				draw_circle(torso + Vector2(-20.0, 8.0), 10.0, Color(0.52, 0.38, 0.22, 0.84))
				draw_circle(torso + Vector2(18.0, 10.0), 12.0, Color(0.46, 0.32, 0.18, 0.84))
		"pogo_zombie":
			if bool(zombie.get("pogo_active", false)):
				draw_line(torso + Vector2(0.0, 8.0), torso + Vector2(0.0, 58.0), Color(0.82, 0.82, 0.88), 4.0)
				draw_arc(torso + Vector2(0.0, 58.0), 12.0, 0.2, PI - 0.2, 14, Color(0.88, 0.24, 0.24), 4.0)
			draw_rect(Rect2(torso + Vector2(-14.0, -52.0), Vector2(28.0, 10.0)), Color(0.24, 0.24, 0.28), true)
			draw_circle(torso + Vector2(-12.0, 16.0), 5.0, Color(0.88, 0.88, 0.92))
			draw_circle(torso + Vector2(12.0, 16.0), 5.0, Color(0.88, 0.88, 0.92))
		"jack_in_the_box_zombie":
			draw_rect(Rect2(torso + Vector2(-16.0, -18.0), Vector2(32.0, 22.0)), Color(0.92, 0.62, 0.18), true)
			draw_line(torso + Vector2(-16.0, -8.0), torso + Vector2(16.0, -8.0), Color(0.54, 0.24, 0.08), 2.0)
			draw_line(torso + Vector2(0.0, -18.0), torso + Vector2(0.0, 4.0), Color(0.54, 0.24, 0.08), 2.0)
			draw_circle(torso + Vector2(0.0, -58.0), 14.0, Color(0.96, 0.94, 0.92))
			draw_circle(torso + Vector2(-6.0, -60.0), 2.2, Color(0.08, 0.08, 0.08))
			draw_circle(torso + Vector2(6.0, -60.0), 2.2, Color(0.08, 0.08, 0.08))
			draw_arc(torso + Vector2(0.0, -52.0), 6.0, 0.2, PI - 0.2, 12, Color(0.18, 0.08, 0.08), 2.0)
			draw_arc(torso + Vector2(0.0, -74.0), 12.0, PI, TAU, 10, Color(0.42, 0.1, 0.12), 6.0)
			if bool(zombie.get("jack_armed", false)):
				draw_arc(torso + Vector2(18.0, -28.0), 7.0, -0.6, 1.2, 12, Color(0.92, 0.86, 0.22), 2.0)
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


# ===== GACHA PLANT DRAWINGS =====

func _draw_shadow_pea(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.28, 0.12, 0.42, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.08 * alpha))
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(-1.0 * size_scale, 33.0 * size_scale), Color(0.14, 0.06, 0.24, alpha), 7.0 * size_scale)
	draw_circle(center + Vector2(-14.0 * size_scale, 20.0 * size_scale), 9.0 * size_scale, Color(0.18, 0.08, 0.32, alpha))
	draw_circle(center + Vector2(16.0 * size_scale, 18.0 * size_scale), 9.0 * size_scale, Color(0.18, 0.08, 0.32, alpha))
	var head = center + Vector2(-2.0 * size_scale, -10.0 * size_scale)
	# Shadow aura
	draw_circle(head, 26.0 * size_scale, Color(0.36, 0.14, 0.56, 0.2 * alpha))
	draw_circle(head, 20.0 * size_scale, body_color)
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 8.0 * size_scale, Color(0.38, 0.18, 0.56, alpha))
	draw_circle(head + Vector2(24.0 * size_scale, 0.0), 11.0 * size_scale, body_color.darkened(0.06))
	draw_circle(head + Vector2(31.0 * size_scale, 0.0), 5.0 * size_scale, Color(0.12, 0.04, 0.2, alpha))
	# Glowing eye
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(0.82, 0.4, 1.0, alpha))
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 1.5 * size_scale, Color(1.0, 0.8, 1.0, alpha))


func _draw_ice_queen(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.56, 0.82, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.36, 0.62, 0.82, alpha), 6.0 * size_scale)
	# Ice crystal crown
	var crown = center + Vector2(0.0, -24.0 * size_scale)
	for i in range(5):
		var angle = -PI * 0.6 + PI * 1.2 * float(i) / 4.0
		var tip = crown + Vector2(cos(angle), sin(angle) - 0.8) * 18.0 * size_scale
		draw_line(crown, tip, Color(0.72, 0.92, 1.0, alpha), 2.5 * size_scale)
		draw_circle(tip, 3.0 * size_scale, Color(0.86, 0.96, 1.0, alpha))
	# Head
	draw_circle(center + Vector2(0.0, -8.0 * size_scale), 20.0 * size_scale, body_color)
	draw_circle(center + Vector2(-5.0 * size_scale, -14.0 * size_scale), 8.0 * size_scale, Color(0.76, 0.92, 1.0, alpha))
	# Eyes
	draw_circle(center + Vector2(-6.0 * size_scale, -10.0 * size_scale), 2.5 * size_scale, Color(0.12, 0.28, 0.56, alpha))
	draw_circle(center + Vector2(6.0 * size_scale, -10.0 * size_scale), 2.5 * size_scale, Color(0.12, 0.28, 0.56, alpha))
	# Frost aura
	draw_circle(center + Vector2(0.0, -8.0 * size_scale), 28.0 * size_scale, Color(0.56, 0.82, 1.0, 0.08 * alpha))


func _draw_vine_emperor(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.22, 0.52, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 16.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	# Thick vine body
	draw_line(center + Vector2(0.0, 6.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.16, 0.42, 0.12, alpha), 10.0 * size_scale)
	# Thorny whip arms
	for side in [-1.0, 1.0]:
		var arm_end = center + Vector2(side * 32.0 * size_scale, 4.0 * size_scale)
		draw_line(center + Vector2(side * 8.0 * size_scale, 0.0), arm_end, Color(0.18, 0.46, 0.14, alpha), 5.0 * size_scale)
		for t in range(3):
			var thorn_pos = center.lerp(arm_end, float(t + 1) / 4.0)
			draw_circle(thorn_pos + Vector2(0.0, -4.0 * size_scale), 3.0 * size_scale, Color(0.42, 0.22, 0.08, alpha))
	# Head with crown
	draw_circle(center + Vector2(0.0, -10.0 * size_scale), 22.0 * size_scale, body_color)
	draw_circle(center + Vector2(0.0, -10.0 * size_scale), 16.0 * size_scale, body_color.lightened(0.08))
	# Crown leaves
	for i in range(3):
		var lx = float(i - 1) * 10.0 * size_scale
		draw_line(center + Vector2(lx, -28.0 * size_scale), center + Vector2(lx, -40.0 * size_scale), Color(0.28, 0.62, 0.22, alpha), 3.0 * size_scale)
	# Eyes
	draw_circle(center + Vector2(-6.0 * size_scale, -12.0 * size_scale), 2.5 * size_scale, Color(0.86, 0.42, 0.12, alpha))
	draw_circle(center + Vector2(6.0 * size_scale, -12.0 * size_scale), 2.5 * size_scale, Color(0.86, 0.42, 0.12, alpha))


func _draw_soul_flower(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal_color = Color(0.62, 0.36, 0.82, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(-2.0 * size_scale, 34.0 * size_scale), Color(0.32, 0.18, 0.46, alpha), 6.0 * size_scale)
	# Ghost-like petals
	var core = center + Vector2(0.0, -8.0 * size_scale)
	for i in range(8):
		var angle = TAU * float(i) / 8.0 + sin(level_time * 1.5) * 0.15
		var petal_pos = core + Vector2(cos(angle), sin(angle)) * 20.0 * size_scale
		draw_circle(petal_pos, 8.0 * size_scale, Color(petal_color.r, petal_color.g, petal_color.b, 0.5 * alpha))
	# Ethereal glow
	draw_circle(core, 24.0 * size_scale, Color(0.62, 0.36, 0.82, 0.1 * alpha))
	draw_circle(core, 16.0 * size_scale, petal_color)
	draw_circle(core, 10.0 * size_scale, Color(0.82, 0.62, 1.0, alpha))
	# Soul eyes
	draw_circle(core + Vector2(-5.0 * size_scale, -2.0 * size_scale), 3.0 * size_scale, Color(0.96, 0.86, 1.0, alpha))
	draw_circle(core + Vector2(5.0 * size_scale, -2.0 * size_scale), 3.0 * size_scale, Color(0.96, 0.86, 1.0, alpha))
	draw_circle(core + Vector2(-5.0 * size_scale, -2.0 * size_scale), 1.5 * size_scale, Color(0.42, 0.18, 0.62, alpha))
	draw_circle(core + Vector2(5.0 * size_scale, -2.0 * size_scale), 1.5 * size_scale, Color(0.42, 0.18, 0.62, alpha))


func _draw_plasma_shooter(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.18, 0.72, 0.92, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 33.0 * size_scale), Color(0.12, 0.48, 0.62, alpha), 7.0 * size_scale)
	draw_circle(center + Vector2(-14.0 * size_scale, 20.0 * size_scale), 9.0 * size_scale, Color(0.14, 0.56, 0.72, alpha))
	draw_circle(center + Vector2(16.0 * size_scale, 18.0 * size_scale), 9.0 * size_scale, Color(0.14, 0.56, 0.72, alpha))
	var head = center + Vector2(-2.0 * size_scale, -10.0 * size_scale)
	# Electric aura
	draw_circle(head, 28.0 * size_scale, Color(0.18, 0.72, 0.92, 0.12 * alpha))
	draw_circle(head, 20.0 * size_scale, body_color)
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 8.0 * size_scale, Color(0.36, 0.86, 1.0, alpha))
	# Plasma barrel
	draw_circle(head + Vector2(24.0 * size_scale, 0.0), 12.0 * size_scale, body_color.darkened(0.06))
	draw_circle(head + Vector2(32.0 * size_scale, 0.0), 6.0 * size_scale, Color(0.56, 0.92, 1.0, alpha))
	draw_circle(head + Vector2(32.0 * size_scale, 0.0), 3.0 * size_scale, Color(0.86, 1.0, 1.0, alpha))
	# Electric eye
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(1.0, 1.0, 0.6, alpha))
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 1.5 * size_scale, Color(0.08, 0.36, 0.56, alpha))


func _draw_crystal_nut(center: Vector2, size_scale: float, flash: float, ratio: float, alpha: float = 1.0) -> void:
	var shell_color = Color(0.56, 0.78, 0.96, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 18.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	# Crystal facets
	draw_circle(center + Vector2(0.0, 6.0 * size_scale), 30.0 * size_scale, Color(0.42, 0.68, 0.92, 0.3 * alpha))
	draw_circle(center + Vector2(0.0, 6.0 * size_scale), 28.0 * size_scale, shell_color)
	# Facet highlights
	draw_circle(center + Vector2(-10.0 * size_scale, -6.0 * size_scale), 10.0 * size_scale, Color(0.76, 0.92, 1.0, 0.5 * alpha))
	draw_circle(center + Vector2(8.0 * size_scale, 14.0 * size_scale), 6.0 * size_scale, Color(0.86, 0.96, 1.0, 0.3 * alpha))
	draw_circle(center + Vector2(-14.0 * size_scale, 10.0 * size_scale), 4.0 * size_scale, Color(1.0, 1.0, 1.0, 0.4 * alpha))
	# Eyes
	draw_circle(center + Vector2(-7.0 * size_scale, 2.0 * size_scale), 3.0 * size_scale, Color(0.12, 0.36, 0.62, alpha))
	draw_circle(center + Vector2(7.0 * size_scale, 2.0 * size_scale), 3.0 * size_scale, Color(0.12, 0.36, 0.62, alpha))
	draw_arc(center + Vector2(0.0, 11.0 * size_scale), 7.0 * size_scale, 0.15, PI - 0.15, 12, Color(0.12, 0.36, 0.62, alpha), 2.0 * size_scale)
	# Cracks at low health
	if ratio < 0.5:
		draw_line(center + Vector2(-6.0 * size_scale, -22.0 * size_scale), center + Vector2(6.0 * size_scale, -2.0 * size_scale), Color(0.28, 0.52, 0.78, alpha), 2.0 * size_scale)
	if ratio < 0.25:
		draw_line(center + Vector2(12.0 * size_scale, -12.0 * size_scale), center + Vector2(-4.0 * size_scale, 10.0 * size_scale), Color(0.28, 0.52, 0.78, alpha), 2.0 * size_scale)


func _draw_dragon_fruit(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.86, 0.28, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.56, 0.18, 0.12, alpha), 8.0 * size_scale)
	# Dragon body
	var head = center + Vector2(0.0, -8.0 * size_scale)
	draw_circle(head, 22.0 * size_scale, body_color)
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 8.0 * size_scale, Color(0.96, 0.42, 0.28, alpha))
	# Dragon horns
	draw_line(head + Vector2(-12.0 * size_scale, -16.0 * size_scale), head + Vector2(-18.0 * size_scale, -30.0 * size_scale), Color(0.72, 0.22, 0.14, alpha), 3.0 * size_scale)
	draw_line(head + Vector2(12.0 * size_scale, -16.0 * size_scale), head + Vector2(18.0 * size_scale, -30.0 * size_scale), Color(0.72, 0.22, 0.14, alpha), 3.0 * size_scale)
	# Fire mouth
	draw_circle(head + Vector2(18.0 * size_scale, 4.0 * size_scale), 8.0 * size_scale, Color(1.0, 0.62, 0.18, alpha))
	draw_circle(head + Vector2(18.0 * size_scale, 4.0 * size_scale), 5.0 * size_scale, Color(1.0, 0.86, 0.36, alpha))
	# Dragon eyes
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(1.0, 0.72, 0.12, alpha))
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 1.5 * size_scale, Color(0.12, 0.04, 0.02, alpha))
	draw_circle(head + Vector2(6.0 * size_scale, -6.0 * size_scale), 3.0 * size_scale, Color(1.0, 0.72, 0.12, alpha))
	draw_circle(head + Vector2(6.0 * size_scale, -6.0 * size_scale), 1.5 * size_scale, Color(0.12, 0.04, 0.02, alpha))


func _draw_time_rose(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal_color = Color(0.82, 0.56, 0.86, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(-2.0 * size_scale, 34.0 * size_scale), Color(0.28, 0.42, 0.26, alpha), 6.0 * size_scale)
	# Rose petals (layered)
	var core = center + Vector2(0.0, -8.0 * size_scale)
	for layer in range(2):
		var offset_angle = float(layer) * 0.3
		for i in range(6):
			var angle = TAU * float(i) / 6.0 + offset_angle
			var dist = (18.0 - float(layer) * 4.0) * size_scale
			draw_circle(core + Vector2(cos(angle), sin(angle)) * dist, (8.0 - float(layer) * 1.5) * size_scale, petal_color.darkened(float(layer) * 0.08))
	draw_circle(core, 10.0 * size_scale, Color(0.92, 0.72, 0.96, alpha))
	# Clock hands (time theme)
	var hour_angle = level_time * 0.5
	var min_angle = level_time * 3.0
	draw_line(core, core + Vector2(cos(hour_angle), sin(hour_angle)) * 6.0 * size_scale, Color(0.42, 0.22, 0.46, alpha), 2.0 * size_scale)
	draw_line(core, core + Vector2(cos(min_angle), sin(min_angle)) * 8.0 * size_scale, Color(0.42, 0.22, 0.46, alpha), 1.5 * size_scale)
	# Time aura
	draw_circle(core, 30.0 * size_scale, Color(0.82, 0.56, 0.86, 0.06 * alpha))


func _draw_galaxy_sunflower(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var petal_color = Color(0.92, 0.76, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(-2.0 * size_scale, 34.0 * size_scale), Color(0.18, 0.14, 0.42, alpha), 6.0 * size_scale)
	var core = center + Vector2(0.0, -8.0 * size_scale)
	# Galaxy aura
	draw_circle(core, 34.0 * size_scale, Color(0.28, 0.18, 0.56, 0.12 * alpha))
	# Cosmic petals
	for i in range(12):
		var angle = TAU * float(i) / 12.0 + level_time * 0.2
		var petal_pos = core + Vector2(cos(angle), sin(angle)) * 22.0 * size_scale
		var star_color = petal_color if i % 2 == 0 else Color(0.72, 0.52, 1.0, alpha)
		draw_circle(petal_pos, 8.0 * size_scale, star_color)
	# Core (nebula)
	draw_circle(core, 16.0 * size_scale, Color(0.18, 0.08, 0.36, alpha))
	draw_circle(core, 12.0 * size_scale, Color(0.28, 0.14, 0.52, alpha))
	# Stars in core
	for i in range(5):
		var sx = core.x + sin(float(i) * 2.3 + level_time) * 6.0 * size_scale
		var sy = core.y + cos(float(i) * 1.7 + level_time * 0.8) * 6.0 * size_scale
		draw_circle(Vector2(sx, sy), 1.5 * size_scale, Color(1.0, 1.0, 0.8, 0.7 * alpha))
	# Eyes
	draw_circle(core + Vector2(-5.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(1.0, 0.92, 0.5, alpha))
	draw_circle(core + Vector2(5.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(1.0, 0.92, 0.5, alpha))


func _draw_void_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.12, 0.06, 0.18, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.08 * alpha))
	# Stem
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.08, 0.04, 0.14, alpha), 8.0 * size_scale)
	# Void aura (black hole effect)
	var core = center + Vector2(0.0, -4.0 * size_scale)
	draw_circle(core, 32.0 * size_scale, Color(0.08, 0.02, 0.14, 0.15 * alpha))
	draw_circle(core, 26.0 * size_scale, Color(0.12, 0.04, 0.2, 0.2 * alpha))
	# Mushroom cap
	draw_circle(core, 22.0 * size_scale, body_color)
	# Event horizon ring
	draw_circle(core, 22.0 * size_scale, Color(0.52, 0.22, 0.82, 0.4 * alpha), false, 2.5 * size_scale)
	# Singularity
	draw_circle(core, 8.0 * size_scale, Color(0.0, 0.0, 0.0, alpha))
	draw_circle(core, 4.0 * size_scale, Color(0.36, 0.16, 0.56, alpha))
	# Accretion particles
	for i in range(6):
		var angle = TAU * float(i) / 6.0 + level_time * 2.0
		var dist = 14.0 + sin(level_time * 3.0 + float(i)) * 4.0
		draw_circle(core + Vector2(cos(angle), sin(angle)) * dist * size_scale, 2.0 * size_scale, Color(0.72, 0.42, 1.0, 0.5 * alpha))


func _draw_phoenix_tree(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.92, 0.42, 0.12, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	# Trunk
	draw_line(center + Vector2(0.0, 6.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.52, 0.22, 0.08, alpha), 8.0 * size_scale)
	draw_line(center + Vector2(-2.0 * size_scale, 8.0 * size_scale), center + Vector2(-2.0 * size_scale, 32.0 * size_scale), Color(0.62, 0.28, 0.12, alpha), 3.0 * size_scale)
	# Fire crown
	var crown = center + Vector2(0.0, -10.0 * size_scale)
	# Flame aura
	draw_circle(crown, 30.0 * size_scale, Color(1.0, 0.52, 0.12, 0.1 * alpha))
	# Flame layers
	for i in range(8):
		var angle = TAU * float(i) / 8.0 + sin(level_time * 2.0) * 0.2
		var flame_h = (18.0 + sin(level_time * 4.0 + float(i) * 1.3) * 4.0) * size_scale
		draw_circle(crown + Vector2(cos(angle), sin(angle)) * flame_h, 8.0 * size_scale, Color(1.0, 0.62, 0.18, 0.6 * alpha))
	draw_circle(crown, 18.0 * size_scale, body_color)
	draw_circle(crown, 12.0 * size_scale, Color(1.0, 0.72, 0.28, alpha))
	# Phoenix eyes
	draw_circle(crown + Vector2(-5.0 * size_scale, -2.0 * size_scale), 3.0 * size_scale, Color(1.0, 0.92, 0.42, alpha))
	draw_circle(crown + Vector2(5.0 * size_scale, -2.0 * size_scale), 3.0 * size_scale, Color(1.0, 0.92, 0.42, alpha))
	draw_circle(crown + Vector2(-5.0 * size_scale, -2.0 * size_scale), 1.5 * size_scale, Color(0.62, 0.12, 0.04, alpha))
	draw_circle(crown + Vector2(5.0 * size_scale, -2.0 * size_scale), 1.5 * size_scale, Color(0.62, 0.12, 0.04, alpha))


func _draw_thunder_god(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.86, 0.82, 0.22, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.52, 0.48, 0.12, alpha), 8.0 * size_scale)
	var head = center + Vector2(0.0, -8.0 * size_scale)
	# Thunder aura
	draw_circle(head, 32.0 * size_scale, Color(0.86, 0.82, 0.22, 0.1 * alpha))
	# Lightning bolts around head
	for i in range(4):
		var angle = TAU * float(i) / 4.0 + level_time * 0.8
		var bolt_start = head + Vector2(cos(angle), sin(angle)) * 22.0 * size_scale
		var bolt_end = head + Vector2(cos(angle), sin(angle)) * 34.0 * size_scale
		draw_line(bolt_start, bolt_end, Color(1.0, 1.0, 0.5, 0.6 * alpha), 2.0 * size_scale)
	# Head
	draw_circle(head, 22.0 * size_scale, body_color)
	draw_circle(head + Vector2(-6.0 * size_scale, -6.0 * size_scale), 8.0 * size_scale, Color(1.0, 0.96, 0.52, alpha))
	# Thunder crown
	for i in range(3):
		var lx = float(i - 1) * 10.0 * size_scale
		draw_line(head + Vector2(lx, -18.0 * size_scale), head + Vector2(lx + 4.0 * size_scale, -32.0 * size_scale), Color(1.0, 0.92, 0.28, alpha), 3.0 * size_scale)
		draw_line(head + Vector2(lx + 4.0 * size_scale, -32.0 * size_scale), head + Vector2(lx - 2.0 * size_scale, -26.0 * size_scale), Color(1.0, 0.92, 0.28, alpha), 2.5 * size_scale)
	# Electric eyes
	draw_circle(head + Vector2(-6.0 * size_scale, -4.0 * size_scale), 3.0 * size_scale, Color(1.0, 1.0, 0.6, alpha))
	draw_circle(head + Vector2(6.0 * size_scale, -4.0 * size_scale), 3.0 * size_scale, Color(1.0, 1.0, 0.6, alpha))
	draw_circle(head + Vector2(-6.0 * size_scale, -4.0 * size_scale), 1.5 * size_scale, Color(0.12, 0.12, 0.04, alpha))
	draw_circle(head + Vector2(6.0 * size_scale, -4.0 * size_scale), 1.5 * size_scale, Color(0.12, 0.12, 0.04, alpha))


func _draw_prism_pea(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.4, 0.8, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.2, 0.5, 0.2, alpha), 7.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Prism crystal body
	draw_circle(head, 22.0 * size_scale, body_color)
	# Rainbow refraction petals
	var colors = [Color(1.0, 0.2, 0.2, 0.7 * alpha), Color(1.0, 0.8, 0.1, 0.7 * alpha), Color(0.2, 1.0, 0.3, 0.7 * alpha), Color(0.2, 0.5, 1.0, 0.7 * alpha), Color(0.8, 0.2, 1.0, 0.7 * alpha)]
	for i in range(5):
		var angle = TAU * float(i) / 5.0 + level_time * 0.6
		var tip = head + Vector2(cos(angle), sin(angle)) * 30.0 * size_scale
		draw_line(head, tip, colors[i], 2.5 * size_scale)
	# Crystal facets
	draw_circle(head, 12.0 * size_scale, Color(0.7, 0.95, 1.0, 0.6 * alpha))
	draw_circle(head, 6.0 * size_scale, Color(1.0, 1.0, 1.0, 0.9 * alpha))
	# Eyes
	draw_circle(head + Vector2(-5.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(0.1, 0.3, 0.6, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(0.1, 0.3, 0.6, alpha))


func _draw_magnet_daisy(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.8, 0.3, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.3, 0.25, 0.35, alpha), 7.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Magnetic field pulse ring
	draw_circle(head, 36.0 * size_scale, Color(0.8, 0.3, 1.0, 0.08 * alpha))
	# Petals
	for i in range(8):
		var angle = TAU * float(i) / 8.0 + level_time * 0.3
		var petal = head + Vector2(cos(angle), sin(angle)) * 24.0 * size_scale
		draw_circle(petal, 7.0 * size_scale, Color(0.6, 0.2, 0.9, 0.8 * alpha))
	draw_circle(head, 16.0 * size_scale, body_color)
	# Magnet core — N/S poles
	draw_circle(head + Vector2(-5.0 * size_scale, 0.0), 5.0 * size_scale, Color(1.0, 0.2, 0.2, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, 0.0), 5.0 * size_scale, Color(0.2, 0.4, 1.0, alpha))
	draw_circle(head, 3.0 * size_scale, Color(1.0, 1.0, 1.0, alpha))


func _draw_thorn_cactus(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.3, 0.65, 0.2, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	# Thick cactus body
	draw_rect(Rect2(center + Vector2(-12.0 * size_scale, -10.0 * size_scale), Vector2(24.0 * size_scale, 44.0 * size_scale)), body_color, true)
	# Arms
	draw_rect(Rect2(center + Vector2(-26.0 * size_scale, 0.0), Vector2(14.0 * size_scale, 20.0 * size_scale)), body_color, true)
	draw_rect(Rect2(center + Vector2(12.0 * size_scale, 2.0 * size_scale), Vector2(14.0 * size_scale, 18.0 * size_scale)), body_color, true)
	# Thorns
	for i in range(6):
		var tx = -14.0 + float(i % 2) * 28.0
		var ty = -8.0 + float(i / 2) * 14.0
		var tdx = -6.0 if float(i % 2) == 0.0 else 6.0
		draw_line(center + Vector2(tx * size_scale, ty * size_scale), center + Vector2((tx + tdx) * size_scale, (ty - 4.0) * size_scale), Color(0.5, 0.8, 0.3, alpha), 2.5 * size_scale)
	# Face
	draw_circle(center + Vector2(-4.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(0.1, 0.35, 0.05, alpha))
	draw_circle(center + Vector2(4.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(0.1, 0.35, 0.05, alpha))


func _draw_bubble_lotus(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.2, 0.8, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	# Lily pad base
	draw_circle(center + Vector2(0.0, 30.0 * size_scale), 16.0 * size_scale, Color(0.2, 0.6, 0.2, 0.7 * alpha))
	var head = center + Vector2(0.0, 2.0 * size_scale)
	# Bubble shield rings
	draw_circle(head, 38.0 * size_scale, Color(0.5, 0.9, 1.0, 0.07 * alpha))
	draw_circle(head, 30.0 * size_scale, Color(0.5, 0.9, 1.0, 0.1 * alpha))
	# Petals
	for i in range(6):
		var angle = TAU * float(i) / 6.0 + level_time * 0.2
		var petal = head + Vector2(cos(angle), sin(angle)) * 26.0 * size_scale
		draw_circle(petal, 8.0 * size_scale, body_color)
	draw_circle(head, 16.0 * size_scale, Color(0.6, 0.95, 1.0, alpha))
	draw_circle(head, 8.0 * size_scale, Color(1.0, 1.0, 1.0, 0.9 * alpha))
	# Floating bubbles
	for i in range(3):
		var bangle = TAU * float(i) / 3.0 + level_time * 0.5
		var bx = head.x + cos(bangle) * 20.0 * size_scale
		var by = head.y + sin(bangle) * 20.0 * size_scale
		draw_circle(Vector2(bx, by), 4.0 * size_scale, Color(0.8, 1.0, 1.0, 0.5 * alpha))
		draw_circle(Vector2(bx, by), 4.0 * size_scale, Color(0.6, 0.95, 1.0, 0.3 * alpha), false, 1.5 * size_scale)


func _draw_spiral_bamboo(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.6, 0.9, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 11.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	# Bamboo segments
	var seg_colors = [Color(0.45, 0.72, 0.18, alpha), Color(0.55, 0.82, 0.22, alpha)]
	for i in range(4):
		var seg_y = 34.0 - float(i) * 12.0
		draw_rect(Rect2(center + Vector2(-7.0 * size_scale, (seg_y - 10.0) * size_scale), Vector2(14.0 * size_scale, 10.0 * size_scale)), seg_colors[i % 2], true)
		draw_line(center + Vector2(-7.0 * size_scale, seg_y * size_scale), center + Vector2(7.0 * size_scale, seg_y * size_scale), Color(0.3, 0.55, 0.1, alpha), 2.0 * size_scale)
	var head = center + Vector2(0.0, -14.0 * size_scale)
	# Spiral leaves
	for i in range(3):
		var angle = TAU * float(i) / 3.0 + level_time * 0.4
		var leaf_tip = head + Vector2(cos(angle) * 18.0 * size_scale, sin(angle) * 12.0 * size_scale)
		draw_line(head, leaf_tip, body_color, 4.0 * size_scale)
	draw_circle(head, 10.0 * size_scale, body_color)
	draw_circle(head, 5.0 * size_scale, Color(0.9, 1.0, 0.6, alpha))


func _draw_honey_blossom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(1.0, 0.85, 0.1, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.45, 0.35, 0.12, alpha), 7.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Honey drip glow
	draw_circle(head, 34.0 * size_scale, Color(1.0, 0.85, 0.1, 0.08 * alpha))
	# Hexagon petals (honeycomb theme)
	for i in range(6):
		var angle = TAU * float(i) / 6.0
		var petal = head + Vector2(cos(angle), sin(angle)) * 22.0 * size_scale
		draw_circle(petal, 8.0 * size_scale, Color(1.0, 0.75, 0.05, 0.85 * alpha))
	draw_circle(head, 16.0 * size_scale, body_color)
	# Honey drop center
	draw_circle(head, 7.0 * size_scale, Color(1.0, 0.65, 0.0, alpha))
	# Bee stripes
	draw_line(head + Vector2(-6.0 * size_scale, 2.0 * size_scale), head + Vector2(6.0 * size_scale, 2.0 * size_scale), Color(0.1, 0.1, 0.1, 0.6 * alpha), 2.0 * size_scale)
	draw_line(head + Vector2(-6.0 * size_scale, 5.0 * size_scale), head + Vector2(6.0 * size_scale, 5.0 * size_scale), Color(0.1, 0.1, 0.1, 0.6 * alpha), 2.0 * size_scale)
	draw_circle(head + Vector2(-5.0 * size_scale, -3.0 * size_scale), 2.5 * size_scale, Color(0.1, 0.08, 0.0, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -3.0 * size_scale), 2.5 * size_scale, Color(0.1, 0.08, 0.0, alpha))


func _draw_echo_fern(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.5, 0.9, 0.7, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 11.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	# Fern stem
	draw_line(center + Vector2(0.0, 34.0 * size_scale), center + Vector2(0.0, -20.0 * size_scale), Color(0.3, 0.6, 0.3, alpha), 5.0 * size_scale)
	# Fronds
	for i in range(5):
		var fy = 20.0 - float(i) * 10.0
		var fl = (5 - i) * 14.0
		var sign_mult = 1.0 if i % 2 == 0 else -1.0
		draw_line(center + Vector2(0.0, fy * size_scale), center + Vector2(sign_mult * fl * size_scale, (fy - 8.0) * size_scale), body_color, 4.0 * size_scale)
	# Sound wave rings
	for i in range(3):
		var ring_alpha = (1.0 - float(i) * 0.3) * 0.3 * alpha
		var t_offset = fmod(level_time * 1.5 + float(i) * 0.3, 1.0)
		draw_circle(center + Vector2(0.0, 0.0), (20.0 + float(i) * 12.0 + t_offset * 10.0) * size_scale, Color(0.5, 0.9, 0.7, ring_alpha), false, 2.0 * size_scale)


func _draw_glow_ivy(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.3, 1.0, 0.6, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 11.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	# Vine tendrils
	for i in range(4):
		var angle = TAU * float(i) / 4.0 + level_time * 0.25
		var vine_end = center + Vector2(cos(angle) * 28.0 * size_scale, sin(angle) * 20.0 * size_scale + 10.0 * size_scale)
		draw_line(center + Vector2(0.0, 10.0 * size_scale), vine_end, Color(0.25, 0.7, 0.35, alpha), 3.5 * size_scale)
	# Glowing core
	draw_circle(center + Vector2(0.0, 0.0), 26.0 * size_scale, Color(0.3, 1.0, 0.6, 0.12 * alpha))
	draw_circle(center + Vector2(0.0, 0.0), 20.0 * size_scale, body_color)
	# Bioluminescent spots
	for i in range(5):
		var spot_angle = TAU * float(i) / 5.0 + level_time * 0.4
		var sx = center.x + cos(spot_angle) * 11.0 * size_scale
		var sy = center.y + sin(spot_angle) * 11.0 * size_scale
		draw_circle(Vector2(sx, sy), 3.5 * size_scale, Color(0.6, 1.0, 0.8, 0.8 * alpha))
	draw_circle(center, 8.0 * size_scale, Color(0.8, 1.0, 0.9, alpha))
	draw_circle(center + Vector2(-5.0 * size_scale, -2.0 * size_scale), 2.0 * size_scale, Color(0.0, 0.3, 0.1, alpha))
	draw_circle(center + Vector2(5.0 * size_scale, -2.0 * size_scale), 2.0 * size_scale, Color(0.0, 0.3, 0.1, alpha))


func _draw_laser_lily(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(1.0, 0.0, 0.5, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.5, 0.1, 0.3, alpha), 8.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Energy charge glow
	draw_circle(head, 30.0 * size_scale, Color(1.0, 0.0, 0.5, 0.1 * alpha))
	# Lily petals pointing forward
	for i in range(5):
		var angle = TAU * float(i) / 5.0 - PI * 0.5
		var petal = head + Vector2(cos(angle), sin(angle)) * 26.0 * size_scale
		draw_circle(petal, 7.0 * size_scale, Color(0.9, 0.0, 0.4, 0.9 * alpha))
	draw_circle(head, 16.0 * size_scale, body_color)
	# Laser core
	draw_line(head + Vector2(0.0, 0.0), head + Vector2(18.0 * size_scale, 0.0), Color(1.0, 0.5, 0.8, 0.8 * alpha), 3.0 * size_scale)
	draw_circle(head, 7.0 * size_scale, Color(1.0, 0.7, 0.9, alpha))
	draw_circle(head, 3.0 * size_scale, Color(1.0, 1.0, 1.0, alpha))


func _draw_rock_armor_fruit(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.65, 0.5, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 16.0 * size_scale, Color(0.0, 0.0, 0.0, 0.08 * alpha))
	draw_line(center + Vector2(0.0, 12.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.4, 0.3, 0.2, alpha), 9.0 * size_scale)
	var head = center + Vector2(0.0, -2.0 * size_scale)
	# Rock armor plates
	draw_circle(head, 28.0 * size_scale, Color(0.5, 0.4, 0.25, 0.4 * alpha))
	draw_circle(head, 24.0 * size_scale, body_color)
	# Rock texture cracks
	for i in range(5):
		var ca = TAU * float(i) / 5.0 + 0.3
		var c1 = head + Vector2(cos(ca), sin(ca)) * 12.0 * size_scale
		var c2 = head + Vector2(cos(ca + 0.4), sin(ca + 0.4)) * 22.0 * size_scale
		draw_line(c1, c2, Color(0.35, 0.25, 0.12, 0.6 * alpha), 1.5 * size_scale)
	# Face
	draw_circle(head + Vector2(-7.0 * size_scale, -3.0 * size_scale), 4.0 * size_scale, Color(0.2, 0.15, 0.08, alpha))
	draw_circle(head + Vector2(7.0 * size_scale, -3.0 * size_scale), 4.0 * size_scale, Color(0.2, 0.15, 0.08, alpha))
	draw_circle(head + Vector2(-7.0 * size_scale, -3.0 * size_scale), 2.0 * size_scale, Color(0.9, 0.7, 0.4, alpha))
	draw_circle(head + Vector2(7.0 * size_scale, -3.0 * size_scale), 2.0 * size_scale, Color(0.9, 0.7, 0.4, alpha))
	# Leaf crown
	for i in range(3):
		var lx = float(i - 1) * 10.0 * size_scale
		draw_line(head + Vector2(lx, -22.0 * size_scale), head + Vector2(lx + 2.0 * size_scale, -34.0 * size_scale), Color(0.3, 0.6, 0.1, alpha), 4.0 * size_scale)


func _draw_aurora_orchid(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.3, 1.0, 0.8, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.2, 0.5, 0.4, alpha), 7.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Aurora shimmer rings
	for i in range(3):
		var ring_a = (0.08 - float(i) * 0.02) * alpha
		draw_circle(head, (38.0 - float(i) * 6.0) * size_scale, Color(0.3, 1.0, 0.8, ring_a))
	# Orchid petals — asymmetric
	var petal_angles = [-1.2, -0.5, 0.0, 0.5, 1.2]
	for i in range(5):
		var angle = petal_angles[i] - PI * 0.5
		var petal = head + Vector2(cos(angle), sin(angle)) * 26.0 * size_scale
		draw_circle(petal, 9.0 * size_scale, Color(0.2, 0.9, 0.7, 0.85 * alpha))
	draw_circle(head, 15.0 * size_scale, body_color)
	# Bioluminescent spots
	for i in range(4):
		var sa = TAU * float(i) / 4.0 + level_time * 0.6
		draw_circle(head + Vector2(cos(sa), sin(sa)) * 7.0 * size_scale, 2.5 * size_scale, Color(0.8, 1.0, 0.9, 0.9 * alpha))
	draw_circle(head, 5.0 * size_scale, Color(1.0, 1.0, 1.0, alpha))


func _draw_blast_pomegranate(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.85, 0.15, 0.15, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.07 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.4, 0.18, 0.1, alpha), 7.0 * size_scale)
	var head = center + Vector2(0.0, -2.0 * size_scale)
	draw_circle(head, 22.0 * size_scale, body_color)
	# Crown
	for i in range(5):
		var ca = TAU * float(i) / 5.0 - PI * 0.5
		draw_line(head + Vector2(cos(ca) * 18.0 * size_scale, sin(ca) * 18.0 * size_scale - 4.0 * size_scale),
			head + Vector2(cos(ca) * 24.0 * size_scale, sin(ca) * 24.0 * size_scale - 4.0 * size_scale),
			Color(0.9, 0.3, 0.1, alpha), 3.0 * size_scale)
	# Seed dots visible through skin
	for i in range(8):
		var sa = TAU * float(i) / 8.0
		draw_circle(head + Vector2(cos(sa), sin(sa)) * 12.0 * size_scale, 2.5 * size_scale, Color(1.0, 0.7, 0.7, 0.7 * alpha))
	# Spark fuse on top
	draw_line(head + Vector2(0.0, -20.0 * size_scale), head + Vector2(4.0 * size_scale, -32.0 * size_scale), Color(0.9, 0.7, 0.1, alpha), 2.5 * size_scale)
	draw_circle(head + Vector2(4.0 * size_scale, -32.0 * size_scale), 4.0 * size_scale, Color(1.0, 0.6, 0.1, 0.9 * alpha))
	draw_circle(head + Vector2(-6.0 * size_scale, -4.0 * size_scale), 2.5 * size_scale, Color(0.5, 0.05, 0.05, alpha))
	draw_circle(head + Vector2(6.0 * size_scale, -4.0 * size_scale), 2.5 * size_scale, Color(0.5, 0.05, 0.05, alpha))


func _draw_frost_cypress(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.5, 0.85, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 11.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	# Trunk
	draw_line(center + Vector2(0.0, 34.0 * size_scale), center + Vector2(0.0, -24.0 * size_scale), Color(0.3, 0.45, 0.55, alpha), 6.0 * size_scale)
	# Layered branches (cypress shape)
	var widths = [28.0, 22.0, 16.0, 10.0, 6.0]
	for i in range(5):
		var by = 20.0 - float(i) * 12.0
		var bw = widths[i]
		draw_line(center + Vector2(-bw * size_scale, by * size_scale), center + Vector2(bw * size_scale, by * size_scale), body_color, 7.0 * size_scale)
	# Ice crystal tips
	for i in range(3):
		var tip_x = float(i - 1) * 16.0 * size_scale
		draw_line(center + Vector2(tip_x, -22.0 * size_scale), center + Vector2(tip_x, -38.0 * size_scale), Color(0.8, 0.95, 1.0, alpha), 3.0 * size_scale)
		draw_line(center + Vector2(tip_x - 4.0 * size_scale, -28.0 * size_scale), center + Vector2(tip_x + 4.0 * size_scale, -28.0 * size_scale), Color(0.8, 0.95, 1.0, alpha), 2.0 * size_scale)
	# Frost aura
	draw_circle(center + Vector2(0.0, -4.0 * size_scale), 30.0 * size_scale, Color(0.7, 0.95, 1.0, 0.08 * alpha))


func _draw_mirror_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.8, 0.9, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 12.0 * size_scale, Color(0.0, 0.0, 0.0, 0.05 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.4, 0.42, 0.46, alpha), 7.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Mirror cap (mushroom)
	draw_circle(head, 24.0 * size_scale, body_color)
	# Mirror facets
	for i in range(6):
		var fa = TAU * float(i) / 6.0 + level_time * 0.15
		var f1 = head + Vector2(cos(fa) * 10.0 * size_scale, sin(fa) * 10.0 * size_scale)
		var f2 = head + Vector2(cos(fa + TAU / 12.0) * 22.0 * size_scale, sin(fa + TAU / 12.0) * 22.0 * size_scale)
		draw_line(f1, f2, Color(0.6, 0.75, 0.9, 0.5 * alpha), 1.5 * size_scale)
	# Reflective center
	draw_circle(head, 10.0 * size_scale, Color(0.9, 0.95, 1.0, 0.8 * alpha))
	draw_circle(head, 5.0 * size_scale, Color(1.0, 1.0, 1.0, alpha))
	# Highlight dot
	draw_circle(head + Vector2(-5.0 * size_scale, -5.0 * size_scale), 2.5 * size_scale, Color(1.0, 1.0, 1.0, 0.9 * alpha))
	# Stem cap ridge
	draw_circle(head + Vector2(0.0, 18.0 * size_scale), 10.0 * size_scale, Color(0.55, 0.6, 0.65, alpha))


func _draw_chain_lotus(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.2, 0.9, 0.8, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_circle(center + Vector2(0.0, 30.0 * size_scale), 15.0 * size_scale, Color(0.15, 0.55, 0.2, 0.7 * alpha))
	var head = center + Vector2(0.0, 2.0 * size_scale)
	# Chain links around body
	for i in range(8):
		var angle = TAU * float(i) / 8.0 + level_time * 0.5
		var cx = head.x + cos(angle) * 24.0 * size_scale
		var cy = head.y + sin(angle) * 24.0 * size_scale
		draw_circle(Vector2(cx, cy), 4.5 * size_scale, body_color, false, 2.0 * size_scale)
	# Petals
	for i in range(6):
		var angle = TAU * float(i) / 6.0 + level_time * 0.15
		var petal = head + Vector2(cos(angle), sin(angle)) * 18.0 * size_scale
		draw_circle(petal, 7.0 * size_scale, Color(0.15, 0.75, 0.7, 0.9 * alpha))
	draw_circle(head, 12.0 * size_scale, body_color)
	draw_circle(head, 5.0 * size_scale, Color(0.8, 1.0, 0.95, alpha))


func _draw_plasma_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.5, 0.2, 1.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.25, 0.1, 0.4, alpha), 8.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Plasma corona
	for i in range(4):
		var ring_a = (0.12 - float(i) * 0.025) * alpha
		draw_circle(head, (38.0 - float(i) * 5.0) * size_scale, Color(0.5, 0.2, 1.0, ring_a))
	# Mushroom cap
	draw_circle(head, 22.0 * size_scale, body_color)
	# Plasma arcs
	for i in range(6):
		var arc_angle = TAU * float(i) / 6.0 + level_time * 1.2
		var a1 = head + Vector2(cos(arc_angle), sin(arc_angle)) * 14.0 * size_scale
		var a2 = head + Vector2(cos(arc_angle + 0.5), sin(arc_angle + 0.5)) * 20.0 * size_scale
		draw_line(a1, a2, Color(0.8, 0.5, 1.0, 0.7 * alpha), 1.5 * size_scale)
	draw_circle(head, 10.0 * size_scale, Color(0.7, 0.4, 1.0, alpha))
	draw_circle(head, 5.0 * size_scale, Color(1.0, 0.9, 1.0, alpha))
	draw_circle(head + Vector2(0.0, 16.0 * size_scale), 9.0 * size_scale, Color(0.35, 0.15, 0.65, alpha))


func _draw_meteor_flower(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(1.0, 0.6, 0.1, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.07 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.4, 0.25, 0.08, alpha), 8.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Fire corona
	draw_circle(head, 36.0 * size_scale, Color(1.0, 0.4, 0.0, 0.07 * alpha))
	draw_circle(head, 28.0 * size_scale, Color(1.0, 0.6, 0.1, 0.1 * alpha))
	# Meteor petals — trailing fire
	for i in range(8):
		var angle = TAU * float(i) / 8.0 + level_time * 0.4
		var petal = head + Vector2(cos(angle), sin(angle)) * 24.0 * size_scale
		var fire_color = Color(1.0, 0.3 + float(i % 3) * 0.25, 0.0, 0.85 * alpha)
		draw_circle(petal, 7.0 * size_scale, fire_color)
	draw_circle(head, 16.0 * size_scale, body_color)
	# Meteor core with crater
	draw_circle(head, 8.0 * size_scale, Color(0.85, 0.42, 0.0, alpha))
	draw_circle(head, 4.0 * size_scale, Color(1.0, 0.9, 0.5, alpha))
	# Flame eyes
	draw_circle(head + Vector2(-5.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(1.0, 1.0, 0.6, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(1.0, 1.0, 0.6, alpha))


func _draw_destiny_tree(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(1.0, 0.9, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 15.0 * size_scale, Color(0.0, 0.0, 0.0, 0.06 * alpha))
	draw_line(center + Vector2(0.0, 8.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.5, 0.35, 0.1, alpha), 9.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Divine aura
	draw_circle(head, 40.0 * size_scale, Color(1.0, 0.9, 0.3, 0.06 * alpha))
	# Branching crown
	for i in range(5):
		var angle = TAU * float(i) / 5.0 - PI * 0.5 + level_time * 0.1
		var branch_end = head + Vector2(cos(angle) * 28.0 * size_scale, sin(angle) * 28.0 * size_scale)
		draw_line(head, branch_end, Color(0.6, 0.42, 0.12, alpha), 3.5 * size_scale)
		draw_circle(branch_end, 5.0 * size_scale, Color(1.0, 0.95, 0.45, alpha))
	draw_circle(head, 18.0 * size_scale, body_color)
	# Destiny sigil
	for i in range(5):
		var sa = TAU * float(i) / 5.0 + level_time * 0.3
		var sb = TAU * float((i + 2) % 5) / 5.0 + level_time * 0.3
		draw_line(head + Vector2(cos(sa), sin(sa)) * 10.0 * size_scale, head + Vector2(cos(sb), sin(sb)) * 10.0 * size_scale, Color(1.0, 0.9, 0.5, 0.6 * alpha), 1.5 * size_scale)
	draw_circle(head, 6.0 * size_scale, Color(1.0, 1.0, 0.8, alpha))
	draw_circle(head + Vector2(-5.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(0.5, 0.35, 0.05, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -2.0 * size_scale), 2.5 * size_scale, Color(0.5, 0.35, 0.05, alpha))


func _draw_abyss_tentacle(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.1, 0.05, 0.3, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.1 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.06, 0.03, 0.18, alpha), 9.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Deep abyss void
	draw_circle(head, 28.0 * size_scale, Color(0.04, 0.02, 0.1, 0.4 * alpha))
	draw_circle(head, 22.0 * size_scale, body_color)
	# Tentacles
	for i in range(6):
		var angle = TAU * float(i) / 6.0 + level_time * 0.3
		var tent_end = head + Vector2(cos(angle) * 32.0 * size_scale, sin(angle) * 20.0 * size_scale)
		draw_line(head + Vector2(cos(angle) * 14.0 * size_scale, sin(angle) * 14.0 * size_scale), tent_end, Color(0.18, 0.08, 0.45, alpha), 3.5 * size_scale)
		draw_circle(tent_end, 3.0 * size_scale, Color(0.5, 0.2, 0.8, 0.8 * alpha))
	# Eyes — multiple eerie eyes
	for i in range(3):
		var ex = float(i - 1) * 9.0 * size_scale
		draw_circle(head + Vector2(ex, -3.0 * size_scale), 4.0 * size_scale, Color(0.6, 0.1, 0.8, alpha))
		draw_circle(head + Vector2(ex, -3.0 * size_scale), 2.0 * size_scale, Color(0.0, 0.0, 0.0, alpha))
		draw_circle(head + Vector2(ex, -3.0 * size_scale), 0.8 * size_scale, Color(0.8, 0.4, 1.0, alpha))


func _draw_solar_emperor(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(1.0, 0.9, 0.1, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 16.0 * size_scale, Color(0.0, 0.0, 0.0, 0.07 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.5, 0.4, 0.1, alpha), 10.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Solar corona
	for i in range(3):
		draw_circle(head, (46.0 - float(i) * 6.0) * size_scale, Color(1.0, 0.8, 0.0, (0.06 - float(i) * 0.015) * alpha))
	# Sun rays
	for i in range(12):
		var angle = TAU * float(i) / 12.0 + level_time * 0.2
		var ray_start = head + Vector2(cos(angle), sin(angle)) * 22.0 * size_scale
		var ray_end = head + Vector2(cos(angle), sin(angle)) * (32.0 + sin(level_time * 2.0 + float(i)) * 4.0) * size_scale
		draw_line(ray_start, ray_end, Color(1.0, 0.9, 0.3, 0.8 * alpha), 2.5 * size_scale)
	draw_circle(head, 22.0 * size_scale, body_color)
	# Crown
	for i in range(5):
		var ca = TAU * float(i) / 5.0 - PI * 0.5
		var tip = head + Vector2(cos(ca) * 30.0 * size_scale, sin(ca) * 30.0 * size_scale)
		draw_circle(tip, 5.0 * size_scale, Color(1.0, 0.7, 0.0, alpha))
	draw_circle(head, 12.0 * size_scale, Color(1.0, 0.95, 0.5, alpha))
	draw_circle(head, 5.0 * size_scale, Color(1.0, 1.0, 0.8, alpha))
	draw_circle(head + Vector2(-6.0 * size_scale, -3.0 * size_scale), 3.0 * size_scale, Color(0.5, 0.35, 0.0, alpha))
	draw_circle(head + Vector2(6.0 * size_scale, -3.0 * size_scale), 3.0 * size_scale, Color(0.5, 0.35, 0.0, alpha))


func _draw_shadow_assassin(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.1, 0.05, 0.15, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 11.0 * size_scale, Color(0.0, 0.0, 0.0, 0.1 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.08, 0.04, 0.12, alpha), 7.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Shadow cloak (dark aura)
	draw_circle(head, 30.0 * size_scale, Color(0.05, 0.02, 0.08, 0.3 * alpha))
	draw_circle(head, 22.0 * size_scale, body_color)
	# Stealth shimmer
	for i in range(5):
		var sa = TAU * float(i) / 5.0 + level_time * 0.8
		var sp = head + Vector2(cos(sa), sin(sa)) * 18.0 * size_scale
		draw_circle(sp, 2.5 * size_scale, Color(0.4, 0.2, 0.6, 0.5 * alpha))
	# Dagger blades
	draw_line(head + Vector2(-16.0 * size_scale, 4.0 * size_scale), head + Vector2(16.0 * size_scale, -12.0 * size_scale), Color(0.7, 0.7, 0.8, 0.8 * alpha), 2.5 * size_scale)
	draw_line(head + Vector2(-16.0 * size_scale, -12.0 * size_scale), head + Vector2(16.0 * size_scale, 4.0 * size_scale), Color(0.7, 0.7, 0.8, 0.8 * alpha), 2.5 * size_scale)
	# Glowing eyes
	draw_circle(head + Vector2(-5.0 * size_scale, -3.0 * size_scale), 3.0 * size_scale, Color(0.6, 0.1, 0.9, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -3.0 * size_scale), 3.0 * size_scale, Color(0.6, 0.1, 0.9, alpha))
	draw_circle(head + Vector2(-5.0 * size_scale, -3.0 * size_scale), 1.5 * size_scale, Color(1.0, 0.8, 1.0, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -3.0 * size_scale), 1.5 * size_scale, Color(1.0, 0.8, 1.0, alpha))


func _draw_core_blossom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(1.0, 0.4, 0.0, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 15.0 * size_scale, Color(0.0, 0.0, 0.0, 0.08 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.35, 0.14, 0.04, alpha), 9.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Magma corona
	draw_circle(head, 38.0 * size_scale, Color(1.0, 0.2, 0.0, 0.06 * alpha))
	draw_circle(head, 30.0 * size_scale, Color(1.0, 0.4, 0.0, 0.1 * alpha))
	# Lava petals
	for i in range(6):
		var angle = TAU * float(i) / 6.0 + level_time * 0.2
		var petal = head + Vector2(cos(angle), sin(angle)) * 26.0 * size_scale
		var lava_col = Color(1.0, 0.2 + float(i % 3) * 0.15, 0.0, 0.9 * alpha)
		draw_circle(petal, 9.0 * size_scale, lava_col)
	draw_circle(head, 18.0 * size_scale, body_color)
	# Molten core
	draw_circle(head, 10.0 * size_scale, Color(1.0, 0.7, 0.0, alpha))
	draw_circle(head, 5.0 * size_scale, Color(1.0, 0.95, 0.7, alpha))
	# Eruption crack lines
	for i in range(4):
		var ca = TAU * float(i) / 4.0 + 0.2
		draw_line(head + Vector2(cos(ca) * 5.0 * size_scale, sin(ca) * 5.0 * size_scale),
			head + Vector2(cos(ca) * 14.0 * size_scale, sin(ca) * 14.0 * size_scale),
			Color(1.0, 0.95, 0.7, 0.7 * alpha), 1.5 * size_scale)
	draw_circle(head + Vector2(-5.5 * size_scale, -3.0 * size_scale), 2.5 * size_scale, Color(0.4, 0.1, 0.0, alpha))
	draw_circle(head + Vector2(5.5 * size_scale, -3.0 * size_scale), 2.5 * size_scale, Color(0.4, 0.1, 0.0, alpha))


func _draw_holy_lotus(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(1.0, 0.95, 0.7, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 14.0 * size_scale, Color(0.0, 0.0, 0.0, 0.04 * alpha))
	draw_circle(center + Vector2(0.0, 30.0 * size_scale), 16.0 * size_scale, Color(0.2, 0.55, 0.2, 0.6 * alpha))
	var head = center + Vector2(0.0, 2.0 * size_scale)
	# Holy light rings
	for i in range(3):
		draw_circle(head, (44.0 - float(i) * 7.0) * size_scale, Color(1.0, 0.95, 0.6, (0.06 - float(i) * 0.015) * alpha))
	# Lotus petals — two tiers
	for tier in range(2):
		for i in range(8):
			var angle = TAU * float(i) / 8.0 + float(tier) * TAU / 16.0 + level_time * 0.1
			var dist = (22.0 - float(tier) * 6.0) * size_scale
			var petal = head + Vector2(cos(angle), sin(angle)) * dist
			var pcol = Color(1.0, 0.9 - float(tier) * 0.1, 0.6 + float(tier) * 0.2, 0.85 * alpha)
			draw_circle(petal, (8.0 - float(tier) * 2.0) * size_scale, pcol)
	draw_circle(head, 12.0 * size_scale, body_color)
	draw_circle(head, 6.0 * size_scale, Color(1.0, 1.0, 0.9, alpha))
	# Halo
	draw_circle(head + Vector2(0.0, -20.0 * size_scale), 12.0 * size_scale, Color(1.0, 0.9, 0.4, 0.4 * alpha), false, 2.0 * size_scale)
	draw_circle(head + Vector2(-5.0 * size_scale, -1.0 * size_scale), 2.5 * size_scale, Color(0.6, 0.4, 0.1, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -1.0 * size_scale), 2.5 * size_scale, Color(0.6, 0.4, 0.1, alpha))


func _draw_chaos_shroom(center: Vector2, size_scale: float, flash: float, alpha: float = 1.0) -> void:
	var body_color = Color(0.7, 0.2, 0.8, alpha).lerp(Color(1.0, 1.0, 1.0, alpha), flash * 2.0)
	draw_circle(center + Vector2(0.0, 36.0 * size_scale), 13.0 * size_scale, Color(0.0, 0.0, 0.0, 0.07 * alpha))
	draw_line(center + Vector2(0.0, 10.0 * size_scale), center + Vector2(0.0, 34.0 * size_scale), Color(0.3, 0.1, 0.38, alpha), 8.0 * size_scale)
	var head = center + Vector2(0.0, -4.0 * size_scale)
	# Chaos energy swirl
	for i in range(5):
		var swirl_angle = TAU * float(i) / 5.0 + level_time * 1.5
		var swirl_r = (20.0 + sin(level_time * 3.0 + float(i)) * 6.0) * size_scale
		var sp = head + Vector2(cos(swirl_angle) * swirl_r, sin(swirl_angle) * swirl_r)
		var chaos_col = Color(float(i) * 0.2, 1.0 - float(i) * 0.18, float(i % 3) * 0.4 + 0.2, 0.7 * alpha)
		draw_circle(sp, 4.5 * size_scale, chaos_col)
	draw_circle(head, 20.0 * size_scale, body_color)
	# Spot pattern
	for i in range(7):
		var sa = TAU * float(i) / 7.0
		draw_circle(head + Vector2(cos(sa), sin(sa)) * 12.0 * size_scale, 3.0 * size_scale, Color(1.0, 0.8, 0.2, 0.7 * alpha))
	draw_circle(head, 8.0 * size_scale, Color(0.9, 0.5, 1.0, alpha))
	# Question mark eyes
	draw_circle(head + Vector2(-5.0 * size_scale, -3.0 * size_scale), 2.5 * size_scale, Color(1.0, 1.0, 0.5, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -3.0 * size_scale), 2.5 * size_scale, Color(1.0, 1.0, 0.5, alpha))
	draw_circle(head + Vector2(-5.0 * size_scale, -3.0 * size_scale), 1.2 * size_scale, Color(0.1, 0.0, 0.15, alpha))
	draw_circle(head + Vector2(5.0 * size_scale, -3.0 * size_scale), 1.2 * size_scale, Color(0.1, 0.0, 0.15, alpha))


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
		"pumpkin":
			stats.append("定位：可套在植物外侧的护壳")
		"lily_pad":
			stats.append("定位：水路平台")
		"squash":
			stats.append("伤害：1600 重压")
		"threepeater":
			stats.append("攻击：三路齐射")
		"split_pea":
			stats.append("攻击：前后双向射击")
		"starfruit":
			stats.append("攻击：五向星弹散射")
		"sea_shroom":
			stats.append("定位：水路免费短射程")
		"plantern":
			stats.append("效果：持续揭开周围浓雾")
		"cactus":
			stats.append("效果：对地远射并可击落气球")
		"blover":
			stats.append("效果：吹走气球并短暂清雾")
		"magnet_shroom":
			stats.append("效果：拆除附近金属装备")
		"lotus_lancer":
			stats.append("攻击：整路贯穿水矛")
		"mirror_reed":
			stats.append("定位：反隐与范围脉冲")
		"frost_fan":
			stats.append("攻击：三路霜风减速")
		"heather_shooter":
			stats.append("攻击：连续刺弹附带腐蚀与短暂眩晕")
		"leyline":
			stats.append("攻击：沿整行掀起地脉冲击")
		"holo_nut":
			stats.append("定位：会自我回复的全息厚墙")
		"healing_gourd":
			stats.append("效果：脉冲治疗周围植物")
		"mango_bowling":
			stats.append("攻击：滚动芒果撞击并溅射相邻行")
		"snow_bloom":
			stats.append("效果：把格子冻成雪地并持续减速敌人")
		"cluster_boomerang":
			stats.append("攻击：维持周围回旋镖封锁带")
		"glitch_walnut":
			stats.append("效果：倒计时后引发全场异常并干扰机械")
		"nether_shroom":
			stats.append("效果：定期召唤魅惑铁桶僵尸")
		"seraph_flower":
			stats.append("攻击：前方三行圣矛贯穿")
		"magma_stream":
			stats.append("效果：留下岩浆地格持续灼烧")
		"orange_bloom":
			stats.append("攻击：整行橙汁爆浆并附带溅射")
		"hive_flower":
			stats.append("攻击：蜂群追咬当前最前面的敌人")
		"mamba_tree":
			stats.append("效果：煤炭陷阱会触发凋零")
		"chambord_sniper":
			stats.append("攻击：高伤狙击，越靠前伤害越高")
		"dream_disc":
			stats.append("效果：一次性大范围睡眠控制")
		"mist_orchid":
			stats.append("攻击：无视浓雾的雾团溅射")
		"anchor_fern":
			stats.append("效果：锚定周围植物并缠住近敌")
		"glowvine":
			stats.append("攻击：荧光种子命中后爆裂")
		"brine_pot":
			stats.append("攻击：抛洒盐沼并留下减速泥潭")
		"storm_reed":
			stats.append("效果：监视右侧并释放连锁雷击")
		"moonforge":
			stats.append("攻击：跨行投射月陨爆裂")
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
			if data.get("gacha_only", false):
				var rarity = data.get("rarity", "")
				if rarity == "purple":
					stats.append("稀有度：紫卡（抽卡专属）")
				elif rarity == "orange":
					stats.append("稀有度：橙卡（抽卡专属）")
				elif rarity == "gold":
					stats.append("稀有度：金卡（抽卡专属）")
				if data.has("ultimate_name"):
					stats.append("大招：%s" % str(data["ultimate_name"]))
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
		"balloon_zombie":
			stats.append("特性：飞行越过植物，需对空或吹风")
		"digger_zombie":
			stats.append("特性：地下绕后，磁力可破招")
		"pogo_zombie":
			stats.append("特性：连续跳过植物，高坚果可拦")
		"jack_in_the_box_zombie":
			stats.append("特性：会自爆清场，磁力可拆掉盒子")
		"squash_zombie":
			stats.append("特性：接近植物后会跃起重压")
		"excavator_zombie":
			stats.append("特性：推进植物链并制造细腻位移")
		"barrel_screen_zombie":
			stats.append("特性：铁门加铁桶双重护具")
		"tornado_zombie":
			stats.append("特性：入场会卷入右侧中段再步行")
		"wolf_knight_zombie":
			stats.append("特性：骑狼冲锋，首撞后下马")
		"kite_zombie":
			stats.append("特性：倒下后会留下导电风筝缠住左侧植物")
		"hive_zombie":
			stats.append("特性：半血后会在附近三排释放蜂群")
		"turret_zombie":
			stats.append("特性：后场炮塔会定点把强化僵尸抛进中场")
		"programmer_zombie":
			stats.append("特性：登场后全场植物攻速减半，可叠加")
		"wenjie_zombie":
			stats.append("特性：会随机变道乱入防线")
		"janitor_zombie":
			stats.append("特性：正面挡弹并用铲子直接铲除植物")
		"subway_zombie":
			stats.append("特性：在铁轨格上高速冲刺直达防线")
		"enderman_zombie":
			stats.append("特性：随机瞬移挡弹，但不会啃植物也不会进家")
		"router_zombie":
			stats.append("特性：在场时给全体僵尸提供增益")
		"ski_zombie":
			stats.append("特性：暴风雪里的高速突脸单位")
		"flywheel_zombie":
			stats.append("特性：厚血慢走，并会扔飞轮压前线")
		"wither_zombie":
			stats.append("特性：死后会把周围地皮腐化 30 秒")
		"mech_zombie":
			stats.append("特性：激光压线，灰烬类攻击对它的机体特别有效")
		"wizard_zombie":
			stats.append("特性：会随机施法扰乱战场节奏")
		"pool_boss":
			stats.append("特性：泳池终章 Boss，持续召援并压迫水陆两线")
		"fog_boss":
			stats.append("特性：浓雾终章 Boss，持续召援、制造盐沼并压前场")
		"roof_boss":
			stats.append("特性：屋顶终章 Boss，持续空投混编僵尸并发动瓦顶轰炸")
		"rumia_boss":
			stats.append("特性：右侧悬停、换行施法、不可魅惑")
		"daiyousei_boss":
			stats.append("特性：半程拦截 Boss，环形光芒与光枪连击")
		"cirno_boss":
			stats.append("特性：终章 Boss，冰柱落击、绝对零度与冰晶吹雪")
		"meiling_boss":
			stats.append("特性：红魔馆守卫，气功踢击、彩虹气功弹与青龙波")
		"koakuma_boss":
			stats.append("特性：半程拦截 Boss，魔导书弹幕、使魔与尸潮召唤")
		"patchouli_boss":
			stats.append("特性：图书馆终章 Boss，多属性魔法、法阵压场、不可魅惑")
		"sakuya_boss":
			stats.append("特性：红魔馆时钟厅 Boss，飞刀弹幕、瞬移换行、时停压场、不可魅惑")
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


func _ensure_plant_food_runtime() -> PlantFoodRuntime:
	if plant_food_runtime == null:
		plant_food_runtime = PlantFoodRuntime.new(self)
	return plant_food_runtime


func _plant_has_food_power(plant: Dictionary) -> bool:
	return _ensure_plant_food_runtime().plant_has_food_power(plant)


func _activate_plant_food(row: int, col: int) -> bool:
	return _ensure_plant_food_runtime().activate(row, col)


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


func _find_highest_hp_zombie_in_range(center: Vector2, radius: float) -> int:
	var best_index := -1
	var best_health := -1.0
	for i in range(zombies.size()):
		var zombie = zombies[i]
		if not _is_enemy_zombie(zombie):
			continue
		var zombie_pos = Vector2(float(zombie["x"]), _row_center_y(int(zombie["row"])))
		if zombie_pos.distance_to(center) > radius:
			continue
		var effective_health = float(zombie.get("health", 0.0)) + float(zombie.get("shield_health", 0.0))
		if effective_health > best_health:
			best_health = effective_health
			best_index = i
	return best_index


func _apply_zombie_slow(zombie: Dictionary, slow_ratio: float, duration: float) -> Dictionary:
	zombie["slow_timer"] = maxf(float(zombie.get("slow_timer", 0.0)), duration)
	zombie["slow_ratio"] = maxf(float(zombie.get("slow_ratio", 0.0)), clampf(slow_ratio, 0.0, 0.9))
	zombie["flash"] = maxf(float(zombie.get("flash", 0.0)), 0.12)
	return zombie


func _mark_save_dirty(immediate: bool = false) -> void:
	save_dirty = true
	autosave_timer = 0.0 if immediate else 0.5


func _update_autosave(delta: float) -> void:
	if not save_dirty:
		return
	autosave_timer = maxf(0.0, autosave_timer - delta)
	if autosave_timer <= 0.0:
		_save_game()


func _read_existing_save_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return {}
	var parsed = JSON.parse_string(save_file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _save_data_completed_ids(save_data: Dictionary) -> Array:
	var result: Array = []
	var seen := {}
	var saved_completed_ids = save_data.get("completed_level_ids", [])
	if saved_completed_ids is Array and not saved_completed_ids.is_empty():
		for level_id_variant in saved_completed_ids:
			var level_id = String(level_id_variant)
			if level_id.is_empty() or seen.has(level_id):
				continue
			seen[level_id] = true
			result.append(level_id)
		return result
	var saved_completed = save_data.get("completed_levels", [])
	if not (saved_completed is Array):
		return result
	for i in range(min(saved_completed.size(), Defs.LEVELS.size())):
		if not bool(saved_completed[i]):
			continue
		var level_id = String(Defs.LEVELS[i].get("id", ""))
		if level_id.is_empty() or seen.has(level_id):
			continue
		seen[level_id] = true
		result.append(level_id)
	return result


func _save_progress_snapshot(save_data: Dictionary) -> Dictionary:
	var completed_ids = _save_data_completed_ids(save_data)
	var completed_lookup := {}
	for level_id in completed_ids:
		completed_lookup[String(level_id)] = true
	var unlocked = clampi(int(save_data.get("unlocked_levels", 1)), 1, Defs.LEVELS.size())
	for level_id in completed_ids:
		var index = _find_level_index_by_id(String(level_id))
		if index != -1:
			unlocked = max(unlocked, min(index + 2, Defs.LEVELS.size()))
	return {
		"version": int(save_data.get("version", 1)),
		"completed_ids": completed_ids,
		"completed_lookup": completed_lookup,
		"completed_count": completed_ids.size(),
		"unlocked_levels": unlocked,
		"coins_total": max(0, int(save_data.get("coins_total", 0))),
		"last_level_index": clampi(int(save_data.get("last_level_index", -1)), -1, Defs.LEVELS.size() - 1),
		"current_world_key": String(save_data.get("current_world_key", "")),
	}


func _save_would_regress_progress(existing_save: Dictionary, candidate_save: Dictionary) -> bool:
	var existing = _save_progress_snapshot(existing_save)
	var candidate = _save_progress_snapshot(candidate_save)
	if int(candidate.get("unlocked_levels", 1)) < int(existing.get("unlocked_levels", 1)):
		return true
	if int(candidate.get("completed_count", 0)) < int(existing.get("completed_count", 0)):
		return true
	var candidate_lookup: Dictionary = candidate.get("completed_lookup", {})
	for level_id in existing.get("completed_ids", []):
		if not candidate_lookup.has(String(level_id)):
			return true
	return false


func _merge_enhance_progress(existing_save: Dictionary, candidate_save: Dictionary) -> Dictionary:
	var merged_levels: Dictionary = {}
	var existing_levels = existing_save.get("plant_enhance_levels", {})
	if existing_levels is Dictionary:
		for kind_variant in existing_levels.keys():
			var kind = String(kind_variant)
			merged_levels[kind] = int(existing_levels[kind_variant])
	var candidate_levels = candidate_save.get("plant_enhance_levels", {})
	if candidate_levels is Dictionary:
		for kind_variant in candidate_levels.keys():
			var kind = String(kind_variant)
			merged_levels[kind] = max(int(merged_levels.get(kind, 0)), int(candidate_levels[kind_variant]))
	return {
		"plant_enhance_levels": merged_levels,
		"enhance_stones": max(int(existing_save.get("enhance_stones", 0)), int(candidate_save.get("enhance_stones", 0))),
	}


func _merge_save_data_preserving_progress(existing_save: Dictionary, candidate_save: Dictionary) -> Dictionary:
	var existing = _save_progress_snapshot(existing_save)
	var candidate = _save_progress_snapshot(candidate_save)
	var merged = candidate_save.duplicate(true)
	var merged_ids: Array = []
	var seen := {}
	for level_id in existing.get("completed_ids", []):
		var id = String(level_id)
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		merged_ids.append(id)
	for level_id in candidate.get("completed_ids", []):
		var id = String(level_id)
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		merged_ids.append(id)
	var regresses = _save_would_regress_progress(existing_save, candidate_save)
	merged["version"] = max(int(existing.get("version", 1)), int(candidate.get("version", 1)))
	merged["unlocked_levels"] = max(int(existing.get("unlocked_levels", 1)), int(candidate.get("unlocked_levels", 1)))
	merged["completed_level_ids"] = merged_ids
	merged["coins_total"] = max(int(existing.get("coins_total", 0)), int(candidate.get("coins_total", 0)))
	var enhance_progress = _merge_enhance_progress(existing_save, candidate_save)
	merged["plant_enhance_levels"] = enhance_progress.get("plant_enhance_levels", {})
	merged["enhance_stones"] = int(enhance_progress.get("enhance_stones", 0))
	if regresses:
		merged["last_level_index"] = max(int(existing.get("last_level_index", -1)), int(candidate.get("last_level_index", -1)))
		var existing_world = String(existing.get("current_world_key", ""))
		var candidate_world = String(candidate.get("current_world_key", ""))
		merged["current_world_key"] = existing_world if not existing_world.is_empty() else candidate_world
	return merged


func _save_game() -> void:
	var save_data = {
		"version": 2,
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"completed_level_ids": _completed_level_ids(),
		"coins_total": coins_total,
		"last_level_index": selected_level_index,
		"current_world_key": current_world_key,
		"plant_stars": plant_stars,
		"plant_fragments": plant_fragments,
		"gacha_pity_counter": gacha_pity_counter,
		"endless_best_wave": endless_best_wave,
		"daily_challenge_date": daily_challenge_date,
		"plant_enhance_levels": plant_enhance_levels,
		"enhance_stones": enhance_stones,
	}
	var existing_save_data = _read_existing_save_data()
	if not existing_save_data.is_empty():
		save_data = _merge_save_data_preserving_progress(existing_save_data, save_data)
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		return
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

	# Load new gameplay data
	if save_data.has("plant_stars") and save_data["plant_stars"] is Dictionary:
		plant_stars = save_data["plant_stars"]
	if save_data.has("plant_fragments") and save_data["plant_fragments"] is Dictionary:
		plant_fragments = save_data["plant_fragments"]
	gacha_pity_counter = int(save_data.get("gacha_pity_counter", 0))
	endless_best_wave = int(save_data.get("endless_best_wave", 0))
	daily_challenge_date = String(save_data.get("daily_challenge_date", ""))
	if save_data.has("plant_enhance_levels") and save_data["plant_enhance_levels"] is Dictionary:
		plant_enhance_levels = save_data["plant_enhance_levels"]
	enhance_stones = int(save_data.get("enhance_stones", 0))

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
