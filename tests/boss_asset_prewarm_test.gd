extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_try_get_boss_frame_texture_queues_without_sync_loading() or failed
	failed = not _test_entering_zombie_almanac_queues_boss_assets() or failed
	failed = not _test_switching_to_zombie_almanac_queues_boss_assets() or failed
	failed = not _test_entering_day_map_queues_special_boss_assets() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	return game


func _free_game(game: Control) -> void:
	if is_instance_valid(game.toast_label):
		game.toast_label.free()
	if is_instance_valid(game.banner_label):
		game.banner_label.free()
	if is_instance_valid(game.message_label):
		game.message_label.free()
	if is_instance_valid(game.action_button):
		game.action_button.free()
	if is_instance_valid(game.message_panel):
		game.message_panel.free()
	game.free()


func _snapshot_shared_state() -> Dictionary:
	return {
		"audio": GameScript.shared_audio_stream_cache.duplicate(),
		"rumia_frames": GameScript.shared_rumia_frames.duplicate(),
		"rumia_loaded": GameScript.shared_rumia_frames_loaded,
		"rumia_face_left": GameScript.shared_rumia_frames_face_left,
		"cirno_frames": GameScript.shared_cirno_frames.duplicate(),
		"cirno_loaded": GameScript.shared_cirno_frames_loaded,
		"cirno_face_left": GameScript.shared_cirno_frames_face_left,
		"daiyousei_frames": GameScript.shared_daiyousei_frames.duplicate(),
		"daiyousei_loaded": GameScript.shared_daiyousei_frames_loaded,
		"daiyousei_face_left": GameScript.shared_daiyousei_frames_face_left,
	}


func _restore_shared_state(snapshot: Dictionary) -> void:
	GameScript.shared_audio_stream_cache = Dictionary(snapshot["audio"]).duplicate()
	GameScript.shared_rumia_frames = Array(snapshot["rumia_frames"]).duplicate()
	GameScript.shared_rumia_frames_loaded = bool(snapshot["rumia_loaded"])
	GameScript.shared_rumia_frames_face_left = snapshot["rumia_face_left"]
	GameScript.shared_cirno_frames = Array(snapshot["cirno_frames"]).duplicate()
	GameScript.shared_cirno_frames_loaded = bool(snapshot["cirno_loaded"])
	GameScript.shared_cirno_frames_face_left = snapshot["cirno_face_left"]
	GameScript.shared_daiyousei_frames = Array(snapshot["daiyousei_frames"]).duplicate()
	GameScript.shared_daiyousei_frames_loaded = bool(snapshot["daiyousei_loaded"])
	GameScript.shared_daiyousei_frames_face_left = snapshot["daiyousei_face_left"]


func _reset_boss_caches() -> void:
	GameScript.shared_audio_stream_cache = {}
	GameScript.shared_rumia_frames = []
	GameScript.shared_rumia_frames_loaded = false
	GameScript.shared_rumia_frames_face_left = null
	GameScript.shared_cirno_frames = []
	GameScript.shared_cirno_frames_loaded = false
	GameScript.shared_cirno_frames_face_left = null
	GameScript.shared_daiyousei_frames = []
	GameScript.shared_daiyousei_frames_loaded = false
	GameScript.shared_daiyousei_frames_face_left = null


func _test_try_get_boss_frame_texture_queues_without_sync_loading() -> bool:
	var snapshot = _snapshot_shared_state()
	_reset_boss_caches()
	var game = _make_game()
	var passed = _assert_true(game.has_method("_try_get_boss_frame_texture"), "expected non-blocking boss frame lookup helper to exist") \
		and _assert_true(game.has_method("_drain_asset_prewarm_queue"), "expected boss asset queue drain helper to exist for tests")
	if passed:
		var first_texture = game.call("_try_get_boss_frame_texture", "cirno_boss", 0)
		passed = _assert_true(first_texture == null, "first non-blocking Cirno frame lookup should queue work instead of synchronously decoding art") and passed
		passed = _assert_true(not bool(game.cirno_frames_loaded), "queuing a Cirno frame should not mark the whole frame set as loaded yet") and passed
		passed = _assert_true(int(game.asset_prewarm_queue.size()) > 0, "non-blocking Cirno frame lookup should enqueue background warmup work") and passed
		game.call("_drain_asset_prewarm_queue")
		var warmed_texture = game.call("_try_get_boss_frame_texture", "cirno_boss", 0)
		passed = _assert_true(warmed_texture is Texture2D, "after draining the queue, Cirno frame lookup should return a warmed texture") and passed
		passed = _assert_true(bool(game.cirno_frames_loaded), "draining the queue should complete the Cirno frame cache") and passed
	_free_game(game)
	_restore_shared_state(snapshot)
	return passed


func _test_entering_zombie_almanac_queues_boss_assets() -> bool:
	var snapshot = _snapshot_shared_state()
	_reset_boss_caches()
	var game = _make_game()
	var passed = _assert_true(game.has_method("_drain_asset_prewarm_queue"), "expected asset queue drain helper to exist")
	if passed:
		game.call("_enter_almanac_mode", "zombies")
		passed = _assert_true(int(game.asset_prewarm_queue.size()) > 0, "entering the zombie almanac should queue Touhou boss art so scrolling to them does not hitch") and passed
		game.call("_drain_asset_prewarm_queue")
		passed = _assert_true(bool(GameScript.shared_rumia_frames_loaded), "zombie almanac prewarm should populate Rumia art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_daiyousei_frames_loaded), "zombie almanac prewarm should populate Daiyousei art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_cirno_frames_loaded), "zombie almanac prewarm should populate Cirno art into the shared cache") and passed
	_free_game(game)
	_restore_shared_state(snapshot)
	return passed


func _test_switching_to_zombie_almanac_queues_boss_assets() -> bool:
	var snapshot = _snapshot_shared_state()
	_reset_boss_caches()
	var game = _make_game()
	game.call("_enter_almanac_mode", "plants")
	var passed = _assert_true(int(game.asset_prewarm_queue.size()) == 0, "opening the plant almanac should not prewarm zombie boss art yet")
	if passed:
		game.call("_handle_almanac_click", Vector2(260.0, 136.0))
		passed = _assert_true(game.almanac_tab == "zombies", "clicking the zombie tab should switch the almanac tab") and passed
		passed = _assert_true(int(game.asset_prewarm_queue.size()) > 0, "switching to the zombie almanac should queue Touhou boss art before the user scrolls to it") and passed
		game.call("_drain_asset_prewarm_queue")
		passed = _assert_true(bool(GameScript.shared_rumia_frames_loaded), "switching to the zombie almanac should warm Rumia art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_daiyousei_frames_loaded), "switching to the zombie almanac should warm Daiyousei art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_cirno_frames_loaded), "switching to the zombie almanac should warm Cirno art into the shared cache") and passed
	_free_game(game)
	_restore_shared_state(snapshot)
	return passed


func _test_entering_day_map_queues_special_boss_assets() -> bool:
	var snapshot = _snapshot_shared_state()
	_reset_boss_caches()
	var game = _make_game()
	var passed = _assert_true(game.has_method("_drain_asset_prewarm_queue"), "expected asset queue drain helper to exist")
	if passed:
		game.current_world_key = "day"
		game.call("_enter_map_mode")
		passed = _assert_true(int(game.asset_prewarm_queue.size()) > 0, "entering the day map should queue 1-17 and 1-18 boss assets before the player clicks those stages") and passed
		game.call("_drain_asset_prewarm_queue")
		passed = _assert_true(game.audio_stream_cache.has("res://audio/rumia_intro.mp3"), "day map prewarm should decode the Rumia intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/rumia_boss.mp3"), "day map prewarm should decode the Rumia boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/cirno_intro.mp3"), "day map prewarm should decode the Cirno intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/cirno_boss.mp3"), "day map prewarm should decode the Cirno boss BGM ahead of the click path") and passed
		passed = _assert_true(bool(GameScript.shared_rumia_frames_loaded), "day map prewarm should populate Rumia art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_daiyousei_frames_loaded), "day map prewarm should populate Daiyousei art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_cirno_frames_loaded), "day map prewarm should populate Cirno art into the shared cache") and passed
	_free_game(game)
	_restore_shared_state(snapshot)
	return passed
