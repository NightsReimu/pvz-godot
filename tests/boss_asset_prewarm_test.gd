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
	failed = not _test_entering_night_map_queues_pcb_boss_assets() or failed
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
		"meiling_frames": GameScript.shared_meiling_frames.duplicate(),
		"meiling_loaded": GameScript.shared_meiling_frames_loaded,
		"meiling_face_left": GameScript.shared_meiling_frames_face_left,
		"koakuma_frames": GameScript.shared_koakuma_frames.duplicate(),
		"koakuma_loaded": GameScript.shared_koakuma_frames_loaded,
		"koakuma_face_left": GameScript.shared_koakuma_frames_face_left,
		"patchouli_frames": GameScript.shared_patchouli_frames.duplicate(),
		"patchouli_loaded": GameScript.shared_patchouli_frames_loaded,
		"patchouli_face_left": GameScript.shared_patchouli_frames_face_left,
		"sakuya_frames": GameScript.shared_sakuya_frames.duplicate(),
		"sakuya_loaded": GameScript.shared_sakuya_frames_loaded,
		"sakuya_face_left": GameScript.shared_sakuya_frames_face_left,
		"remilia_frames": GameScript.shared_remilia_frames.duplicate(),
		"remilia_loaded": GameScript.shared_remilia_frames_loaded,
		"remilia_face_left": GameScript.shared_remilia_frames_face_left,
		"letty_frames": GameScript.shared_letty_frames.duplicate(),
		"letty_loaded": GameScript.shared_letty_frames_loaded,
		"letty_face_left": GameScript.shared_letty_frames_face_left,
		"chen_frames": GameScript.shared_chen_frames.duplicate(),
		"chen_loaded": GameScript.shared_chen_frames_loaded,
		"chen_face_left": GameScript.shared_chen_frames_face_left,
		"alice_frames": GameScript.shared_alice_frames.duplicate(),
		"alice_loaded": GameScript.shared_alice_frames_loaded,
		"alice_face_left": GameScript.shared_alice_frames_face_left,
		"lily_white_frames": GameScript.shared_lily_white_frames.duplicate(),
		"lily_white_loaded": GameScript.shared_lily_white_frames_loaded,
		"lily_white_face_left": GameScript.shared_lily_white_frames_face_left,
		"prismriver_frames": GameScript.shared_prismriver_frames.duplicate(),
		"prismriver_loaded": GameScript.shared_prismriver_frames_loaded,
		"prismriver_face_left": GameScript.shared_prismriver_frames_face_left,
		"youmu_frames": GameScript.shared_youmu_frames.duplicate(),
		"youmu_loaded": GameScript.shared_youmu_frames_loaded,
		"youmu_face_left": GameScript.shared_youmu_frames_face_left,
		"flandre_frames": GameScript.shared_flandre_frames.duplicate(),
		"flandre_loaded": GameScript.shared_flandre_frames_loaded,
		"flandre_face_left": GameScript.shared_flandre_frames_face_left,
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
	GameScript.shared_meiling_frames = Array(snapshot["meiling_frames"]).duplicate()
	GameScript.shared_meiling_frames_loaded = bool(snapshot["meiling_loaded"])
	GameScript.shared_meiling_frames_face_left = snapshot["meiling_face_left"]
	GameScript.shared_koakuma_frames = Array(snapshot["koakuma_frames"]).duplicate()
	GameScript.shared_koakuma_frames_loaded = bool(snapshot["koakuma_loaded"])
	GameScript.shared_koakuma_frames_face_left = snapshot["koakuma_face_left"]
	GameScript.shared_patchouli_frames = Array(snapshot["patchouli_frames"]).duplicate()
	GameScript.shared_patchouli_frames_loaded = bool(snapshot["patchouli_loaded"])
	GameScript.shared_patchouli_frames_face_left = snapshot["patchouli_face_left"]
	GameScript.shared_sakuya_frames = Array(snapshot["sakuya_frames"]).duplicate()
	GameScript.shared_sakuya_frames_loaded = bool(snapshot["sakuya_loaded"])
	GameScript.shared_sakuya_frames_face_left = snapshot["sakuya_face_left"]
	GameScript.shared_remilia_frames = Array(snapshot["remilia_frames"]).duplicate()
	GameScript.shared_remilia_frames_loaded = bool(snapshot["remilia_loaded"])
	GameScript.shared_remilia_frames_face_left = snapshot["remilia_face_left"]
	GameScript.shared_letty_frames = Array(snapshot["letty_frames"]).duplicate()
	GameScript.shared_letty_frames_loaded = bool(snapshot["letty_loaded"])
	GameScript.shared_letty_frames_face_left = snapshot["letty_face_left"]
	GameScript.shared_chen_frames = Array(snapshot["chen_frames"]).duplicate()
	GameScript.shared_chen_frames_loaded = bool(snapshot["chen_loaded"])
	GameScript.shared_chen_frames_face_left = snapshot["chen_face_left"]
	GameScript.shared_alice_frames = Array(snapshot["alice_frames"]).duplicate()
	GameScript.shared_alice_frames_loaded = bool(snapshot["alice_loaded"])
	GameScript.shared_alice_frames_face_left = snapshot["alice_face_left"]
	GameScript.shared_lily_white_frames = Array(snapshot["lily_white_frames"]).duplicate()
	GameScript.shared_lily_white_frames_loaded = bool(snapshot["lily_white_loaded"])
	GameScript.shared_lily_white_frames_face_left = snapshot["lily_white_face_left"]
	GameScript.shared_prismriver_frames = Array(snapshot["prismriver_frames"]).duplicate()
	GameScript.shared_prismriver_frames_loaded = bool(snapshot["prismriver_loaded"])
	GameScript.shared_prismriver_frames_face_left = snapshot["prismriver_face_left"]
	GameScript.shared_youmu_frames = Array(snapshot["youmu_frames"]).duplicate()
	GameScript.shared_youmu_frames_loaded = bool(snapshot["youmu_loaded"])
	GameScript.shared_youmu_frames_face_left = snapshot["youmu_face_left"]
	GameScript.shared_flandre_frames = Array(snapshot["flandre_frames"]).duplicate()
	GameScript.shared_flandre_frames_loaded = bool(snapshot["flandre_loaded"])
	GameScript.shared_flandre_frames_face_left = snapshot["flandre_face_left"]


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
	GameScript.shared_meiling_frames = []
	GameScript.shared_meiling_frames_loaded = false
	GameScript.shared_meiling_frames_face_left = null
	GameScript.shared_koakuma_frames = []
	GameScript.shared_koakuma_frames_loaded = false
	GameScript.shared_koakuma_frames_face_left = null
	GameScript.shared_patchouli_frames = []
	GameScript.shared_patchouli_frames_loaded = false
	GameScript.shared_patchouli_frames_face_left = null
	GameScript.shared_sakuya_frames = []
	GameScript.shared_sakuya_frames_loaded = false
	GameScript.shared_sakuya_frames_face_left = null
	GameScript.shared_remilia_frames = []
	GameScript.shared_remilia_frames_loaded = false
	GameScript.shared_remilia_frames_face_left = null
	GameScript.shared_letty_frames = []
	GameScript.shared_letty_frames_loaded = false
	GameScript.shared_letty_frames_face_left = null
	GameScript.shared_chen_frames = []
	GameScript.shared_chen_frames_loaded = false
	GameScript.shared_chen_frames_face_left = null
	GameScript.shared_alice_frames = []
	GameScript.shared_alice_frames_loaded = false
	GameScript.shared_alice_frames_face_left = null
	GameScript.shared_lily_white_frames = []
	GameScript.shared_lily_white_frames_loaded = false
	GameScript.shared_lily_white_frames_face_left = null
	GameScript.shared_prismriver_frames = []
	GameScript.shared_prismriver_frames_loaded = false
	GameScript.shared_prismriver_frames_face_left = null
	GameScript.shared_youmu_frames = []
	GameScript.shared_youmu_frames_loaded = false
	GameScript.shared_youmu_frames_face_left = null
	GameScript.shared_flandre_frames = []
	GameScript.shared_flandre_frames_loaded = false
	GameScript.shared_flandre_frames_face_left = null


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
		passed = _assert_true(bool(GameScript.shared_meiling_frames_loaded), "zombie almanac prewarm should populate Meiling art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_sakuya_frames_loaded), "zombie almanac prewarm should populate Sakuya art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_remilia_frames_loaded), "zombie almanac prewarm should populate Remilia art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_letty_frames_loaded), "zombie almanac prewarm should populate Letty art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_lily_white_frames_loaded), "zombie almanac prewarm should populate Lily White art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_prismriver_frames_loaded), "zombie almanac prewarm should populate Prismriver art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_youmu_frames_loaded), "zombie almanac prewarm should populate Youmu art into the shared cache") and passed
		var flandre_texture = game.call("_try_get_boss_frame_texture", "flandre_boss", 0)
		passed = _assert_true(flandre_texture is Texture2D, "zombie almanac prewarm should warm Flandre art before the user scrolls to her entry") and passed
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
		passed = _assert_true(bool(GameScript.shared_meiling_frames_loaded), "switching to the zombie almanac should warm Meiling art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_sakuya_frames_loaded), "switching to the zombie almanac should warm Sakuya art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_remilia_frames_loaded), "switching to the zombie almanac should warm Remilia art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_letty_frames_loaded), "switching to the zombie almanac should warm Letty art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_lily_white_frames_loaded), "switching to the zombie almanac should warm Lily White art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_prismriver_frames_loaded), "switching to the zombie almanac should warm Prismriver art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_youmu_frames_loaded), "switching to the zombie almanac should warm Youmu art into the shared cache") and passed
		var flandre_texture = game.call("_try_get_boss_frame_texture", "flandre_boss", 0)
		passed = _assert_true(flandre_texture is Texture2D, "switching to the zombie almanac should warm Flandre art before the user scrolls to her entry") and passed
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
		passed = _assert_true(game.audio_stream_cache.has("res://audio/th06_06.mp3"), "day map prewarm should decode the Meiling intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/th06_07.mp3"), "day map prewarm should decode the Meiling boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/patchouli_intro.mp3"), "day map prewarm should decode the Patchouli intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/patchouli_boss.mp3"), "day map prewarm should decode the Patchouli boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/sakuya_intro.mp3"), "day map prewarm should decode the Sakuya intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/sakuya_boss.mp3"), "day map prewarm should decode the Sakuya boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/remilia_intro.mp3"), "day map prewarm should decode the Remilia intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/remilia_boss.mp3"), "day map prewarm should decode the Remilia boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/flandre_intro.mp3"), "day map prewarm should decode the Flandre intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/flandre_boss.mp3"), "day map prewarm should decode the Flandre boss BGM ahead of the click path") and passed
		passed = _assert_true(bool(GameScript.shared_rumia_frames_loaded), "day map prewarm should populate Rumia art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_daiyousei_frames_loaded), "day map prewarm should populate Daiyousei art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_cirno_frames_loaded), "day map prewarm should populate Cirno art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_meiling_frames_loaded), "day map prewarm should populate Meiling art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_koakuma_frames_loaded), "day map prewarm should populate Koakuma art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_patchouli_frames_loaded), "day map prewarm should populate Patchouli art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_sakuya_frames_loaded), "day map prewarm should populate Sakuya art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_remilia_frames_loaded), "day map prewarm should populate Remilia art into the shared cache") and passed
		var flandre_texture = game.call("_try_get_boss_frame_texture", "flandre_boss", 0)
		passed = _assert_true(flandre_texture is Texture2D, "day map prewarm should populate Flandre art before the player clicks 1-23") and passed
	_free_game(game)
	_restore_shared_state(snapshot)
	return passed


func _test_entering_night_map_queues_pcb_boss_assets() -> bool:
	var snapshot = _snapshot_shared_state()
	_reset_boss_caches()
	var game = _make_game()
	var passed = _assert_true(game.has_method("_drain_asset_prewarm_queue"), "expected asset queue drain helper to exist")
	if passed:
		game.completed_levels.resize(GameScript.Defs.LEVELS.size())
		for i in range(game.completed_levels.size()):
			game.completed_levels[i] = false
		for i in range(GameScript.Defs.LEVELS.size()):
			var level_id := String(GameScript.Defs.LEVELS[i].get("id", ""))
			if level_id == "1-16" or level_id == "1-22" or level_id == "2-25" or level_id == "2-26" or level_id == "2-27" or level_id == "2-28" or level_id == "2-29":
				game.completed_levels[i] = true
		game.current_world_key = "night"
		game.call("_enter_map_mode")
		passed = _assert_true(int(game.asset_prewarm_queue.size()) > 0, "entering the night map should queue 2-25 through 2-30 boss assets before the player clicks those stages") and passed
		game.call("_drain_asset_prewarm_queue")
		passed = _assert_true(game.audio_stream_cache.has("res://audio/letty_intro.mp3"), "night map prewarm should decode the Letty intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/letty_boss.mp3"), "night map prewarm should decode the Letty boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/chen_intro.mp3"), "night map prewarm should decode the Chen intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/chen_boss.mp3"), "night map prewarm should decode the Chen boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/alice_intro.mp3"), "night map prewarm should decode the Alice intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/alice_boss.mp3"), "night map prewarm should decode the Alice boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/prismriver_intro.mp3"), "night map prewarm should decode the Prismriver intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/prismriver_boss.mp3"), "night map prewarm should decode the Prismriver boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/youmu_intro.mp3"), "night map prewarm should decode the Youmu intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/youmu_boss.mp3"), "night map prewarm should decode the Youmu boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/yuyuko_intro.mp3"), "night map prewarm should decode the Yuyuko intro BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/yuyuko_boss.mp3"), "night map prewarm should decode the Yuyuko boss BGM ahead of the click path") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/yuyuko_revival.mp3"), "night map prewarm should decode the Yuyuko revival BGM ahead of the click path") and passed
		passed = _assert_true(bool(GameScript.shared_letty_frames_loaded), "night map prewarm should populate Letty art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_chen_frames_loaded), "night map prewarm should populate Chen art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_alice_frames_loaded), "night map prewarm should populate Alice art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_lily_white_frames_loaded), "night map prewarm should populate Lily White art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_prismriver_frames_loaded), "night map prewarm should populate Prismriver art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_youmu_frames_loaded), "night map prewarm should populate Youmu art into the shared cache") and passed
		passed = _assert_true(bool(GameScript.shared_yuyuko_frames_loaded), "night map prewarm should populate Yuyuko art into the shared cache") and passed
		var letty_texture = game.call("_try_get_boss_frame_texture", "letty_boss", 0)
		passed = _assert_true(letty_texture is Texture2D, "night map prewarm should populate Letty art before the player clicks 2-25") and passed
		var chen_texture = game.call("_try_get_boss_frame_texture", "chen_boss", 0)
		passed = _assert_true(chen_texture is Texture2D, "night map prewarm should populate Chen art before the player clicks 2-26") and passed
		var alice_texture = game.call("_try_get_boss_frame_texture", "alice_boss", 0)
		passed = _assert_true(alice_texture is Texture2D, "night map prewarm should populate Alice art before the player clicks 2-27") and passed
		var lily_texture = game.call("_try_get_boss_frame_texture", "lily_white_boss", 0)
		passed = _assert_true(lily_texture is Texture2D, "night map prewarm should populate Lily White art before the player clicks 2-28") and passed
		var prismriver_texture = game.call("_try_get_boss_frame_texture", "prismriver_boss", 0)
		passed = _assert_true(prismriver_texture is Texture2D, "night map prewarm should populate Prismriver art before the player clicks 2-28") and passed
		var youmu_texture = game.call("_try_get_boss_frame_texture", "youmu_boss", 0)
		passed = _assert_true(youmu_texture is Texture2D, "night map prewarm should populate Youmu art before the player clicks 2-29") and passed
		var yuyuko_texture = game.call("_try_get_boss_frame_texture", "yuyuko_boss", 0)
		passed = _assert_true(yuyuko_texture is Texture2D, "night map prewarm should populate Yuyuko art before the player clicks 2-30") and passed
	_free_game(game)
	_restore_shared_state(snapshot)
	return passed
