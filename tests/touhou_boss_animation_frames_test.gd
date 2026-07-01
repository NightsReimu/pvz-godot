extends SceneTree

const GameScript = preload("res://scripts/game.gd")

const BOSS_KINDS := [
	"rumia_boss",
	"daiyousei_boss",
	"cirno_boss",
	"meiling_boss",
	"koakuma_boss",
	"patchouli_boss",
	"sakuya_boss",
	"remilia_boss",
	"letty_boss",
	"chen_boss",
	"alice_boss",
	"lily_white_boss",
	"prismriver_boss",
	"youmu_boss",
	"flandre_boss",
]

const STATE_SAMPLES := {
	"rumia_boss": ["dark", "night", "swallow", "phase", "shift"],
	"daiyousei_boss": ["heal", "fairy", "summon", "phase", "shift"],
	"cirno_boss": ["ice", "freeze", "snow", "phase", "shift"],
	"meiling_boss": ["punch", "dash", "guard", "phase", "shift"],
	"koakuma_boss": ["books", "familiar", "summon", "phase", "shift"],
	"patchouli_boss": ["fire", "water", "wind", "metal", "flare", "phase", "shift"],
	"sakuya_boss": ["knives", "rain", "time", "clock", "phase", "shift"],
	"remilia_boss": ["scarlet", "heart", "gungnir", "drain", "phase", "shift"],
	"letty_boss": ["lingering", "wither", "ray", "snap", "table", "phase", "shift"],
	"chen_boss": ["phoenix", "shikigami", "dash", "idaten", "rampage", "phase", "shift"],
	"alice_boss": ["procession", "marionette", "seven", "grave", "return", "phase", "shift"],
	"lily_white_boss": ["spring_herald", "petals", "cloud_bloom", "fairy_barrage", "phase", "shift"],
	"prismriver_boss": ["phantom_dinning", "lunasa", "merlin", "lyrica", "live_poltergeist", "phase", "shift"],
	"youmu_boss": ["slash", "dash", "instant", "cross", "wraith", "finale", "phase"],
	"flandre_boss": ["laevatein", "clones", "kagome", "crystal", "judgement", "cranberry", "phase", "shift"],
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_all_touhou_bosses_have_24_frame_sets() or failed
	failed = not _test_all_touhou_boss_frame_textures_load() or failed
	failed = not _test_touhou_boss_frame_indices_use_24_frame_ranges() or failed
	failed = not _test_youmu_render_scale_stays_compact() or failed
	failed = not _test_youmu_frames_share_a_stable_canvas() or failed
	failed = not _test_youmu_skill_states_use_coherent_frame_ranges() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	return GameScript.new()


func _free_game(game: Control) -> void:
	game.free()


func _test_all_touhou_bosses_have_24_frame_sets() -> bool:
	var game := _make_game()
	var passed := true
	for kind in BOSS_KINDS:
		var frame_count := int(game.call("_boss_frame_count_for_kind", kind))
		passed = _assert_true(frame_count == 24, "%s should expose 24 animation frames" % kind) and passed
		var folder := String(game.call("_boss_frame_folder_for_kind", kind))
		passed = _assert_true(folder != "", "%s should resolve to a boss art folder" % kind) and passed
		for frame_index in range(24):
			var path := "%s/frame_%02d.png" % [folder, frame_index]
			passed = _assert_true(FileAccess.file_exists(path), "%s should exist" % path) and passed
			passed = _assert_true(FileAccess.file_exists("%s.import" % path), "%s.import should exist" % path) and passed
	_free_game(game)
	return passed


func _test_all_touhou_boss_frame_textures_load() -> bool:
	var passed := true
	for kind in BOSS_KINDS:
		for frame_index in range(24):
			var path := "res://art/%s/frame_%02d.png" % [_folder_name_for_kind(kind), frame_index]
			var image := Image.new()
			var load_result := image.load(ProjectSettings.globalize_path(path))
			passed = _assert_true(load_result == OK, "%s should load as an image" % path) and passed
			if load_result != OK:
				continue
			image.convert(Image.FORMAT_RGBA8)
			passed = _assert_true(image.get_width() >= 96 and image.get_height() >= 96, "%s should stay large enough for boss rendering" % path) and passed
			passed = _assert_true(_corner_alpha_max(image) <= 0.08, "%s should have transparent corners after cleanup" % path) and passed
	return passed


func _test_touhou_boss_frame_indices_use_24_frame_ranges() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_boss_pose_frame"), "boss animation should expose a pose-to-24-frame helper")
	for kind in BOSS_KINDS:
		for pose_index in range(8):
			var samples := {}
			for phase in [0.0, 0.18, 0.36, 0.54, 0.72, 0.90]:
				var frame := int(game.call("_boss_pose_frame", pose_index, 9.0, phase))
				samples[frame] = true
				passed = _assert_true(frame >= pose_index * 3 and frame <= pose_index * 3 + 2, "%s pose %d should stay inside its 3-frame group" % [kind, pose_index]) and passed
			passed = _assert_true(samples.size() >= 2, "%s pose %d should animate across multiple subframes" % [kind, pose_index]) and passed
		for state in Array(STATE_SAMPLES.get(kind, [])):
			var state_frames := {}
			for phase in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]:
				var boss := {
					"kind": kind,
					"rumia_state": String(state),
					"anim_phase": phase,
					"special_pause_timer": 0.0,
				}
				var frame_index := int(game.call("_boss_frame_index_for_kind", boss))
				state_frames[frame_index] = true
				passed = _assert_true(frame_index >= 0 and frame_index < 24, "%s state %s should return a valid 24-frame index" % [kind, String(state)]) and passed
			passed = _assert_true(state_frames.size() >= 2, "%s state %s should animate across multiple 24-frame indices" % [kind, String(state)]) and passed
	_free_game(game)
	return passed


func _test_youmu_render_scale_stays_compact() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_youmu_draw_scale"), "Youmu should expose a draw scale helper")
	var max_alpha_height := 0.0
	for frame_index in range(24):
		var path := "res://art/youmu/frame_%02d.png" % frame_index
		var bounds := _alpha_bounds_for_frame(path)
		passed = _assert_true(bounds.size.y > 0, "%s should have visible sprite pixels" % path) and passed
		max_alpha_height = maxf(max_alpha_height, float(bounds.size.y))
	if game.has_method("_youmu_draw_scale"):
		var opening_height := max_alpha_height * float(game.call("_youmu_draw_scale", 0))
		var late_height := max_alpha_height * float(game.call("_youmu_draw_scale", 3))
		passed = _assert_true(opening_height <= 158.0, "Youmu opening render should stay close to the old boss size instead of ballooning to %.1fpx" % opening_height) and passed
		passed = _assert_true(late_height <= 166.0, "Youmu late-phase render should stay readable without becoming oversized (%.1fpx)" % late_height) and passed
	_free_game(game)
	return passed


func _test_youmu_frames_share_a_stable_canvas() -> bool:
	var expected_size := Vector2i.ZERO
	var passed := true
	for frame_index in range(24):
		var path := "res://art/youmu/frame_%02d.png" % frame_index
		var image := Image.new()
		var load_result := image.load(ProjectSettings.globalize_path(path))
		passed = _assert_true(load_result == OK, "%s should load for canvas stability checks" % path) and passed
		if load_result != OK:
			continue
		var size := Vector2i(image.get_width(), image.get_height())
		if expected_size == Vector2i.ZERO:
			expected_size = size
		passed = _assert_true(size == expected_size, "%s should keep the same canvas as the other Youmu frames to avoid anchor jitter" % path) and passed
	return passed


func _test_youmu_skill_states_use_coherent_frame_ranges() -> bool:
	var game := _make_game()
	var state_ranges := {
		"slash": Vector2i(3, 7),
		"dash": Vector2i(12, 17),
		"instant": Vector2i(12, 17),
		"shift": Vector2i(12, 17),
		"cross": Vector2i(17, 20),
		"half_ghost": Vector2i(8, 11),
		"wraith": Vector2i(8, 11),
		"six_realms": Vector2i(20, 23),
		"finale": Vector2i(17, 23),
		"phase": Vector2i(20, 23),
	}
	var passed := true
	for state in state_ranges.keys():
		var frame_range := Vector2i(state_ranges[state])
		var seen := {}
		for time in [0.0, 0.14, 0.28, 0.42, 0.56, 0.7, 0.84, 0.98]:
			game.level_time = float(time)
			var boss := {
				"kind": "youmu_boss",
				"rumia_state": String(state),
				"anim_phase": 0.0,
				"special_pause_timer": 0.0,
			}
			var frame_index := int(game.call("_boss_frame_index_for_kind", boss))
			seen[frame_index] = true
			passed = _assert_true(frame_index >= frame_range.x and frame_index <= frame_range.y, "Youmu %s animation should stay in a coherent frame range %d..%d, got %d" % [String(state), frame_range.x, frame_range.y, frame_index]) and passed
		passed = _assert_true(seen.size() >= 2, "Youmu %s animation should still move within its coherent frame range" % String(state)) and passed
	_free_game(game)
	return passed


func _folder_name_for_kind(kind: String) -> String:
	match kind:
		"daiyousei_boss":
			return "daiyousei"
		"lily_white_boss":
			return "lily_white"
		_:
			return kind.replace("_boss", "")


func _corner_alpha_max(image: Image) -> float:
	var width := image.get_width()
	var height := image.get_height()
	return maxf(
		maxf(image.get_pixel(0, 0).a, image.get_pixel(width - 1, 0).a),
		maxf(image.get_pixel(0, height - 1).a, image.get_pixel(width - 1, height - 1).a)
	)


func _alpha_bounds_for_frame(path: String) -> Rect2i:
	var image := Image.new()
	var load_result := image.load(ProjectSettings.globalize_path(path))
	if load_result != OK:
		return Rect2i()
	image.convert(Image.FORMAT_RGBA8)
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 8.0 / 255.0:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
