extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_1_18_unlock_requires_1_17_and_3_4() or failed
	failed = not _test_1_18_follows_1_17_in_day_world() or failed
	failed = not _test_1_18_starts_with_split_water_and_land_cells() or failed
	failed = not _test_cirno_freeze_turns_left_pool_into_frozen_support_cells() or failed
	failed = not _test_frozen_cells_slow_attack_cadence() or failed
	failed = not _test_daiyousei_midboss_locks_progress_until_defeated() or failed
	failed = not _test_daiyousei_spellcards_create_effects_and_damage_plants() or failed
	failed = not _test_cirno_freeze_swaps_conveyor_pool() or failed
	failed = not _test_cirno_spellcards_create_ice_effects_and_reinforcements() or failed
	failed = not _test_boss_frame_cleanup_removes_white_border_and_faces_left() or failed
	failed = not _test_prebaked_cirno_frames_have_clean_transparent_outer_edges() or failed
	failed = not _test_prebaked_cirno_frames_keep_safe_transparent_margin_and_no_far_fragments() or failed
	failed = not _test_cirno_freeze_clears_existing_water_support_cards() or failed
	failed = not _test_cirno_freeze_animates_smoothly() or failed
	failed = not _test_1_18_assets_and_bgm_are_present() or failed
	failed = not _test_daiyousei_defeat_does_not_end_remaining_stage_flow() or failed
	failed = not _test_cirno_event_supports_do_not_duplicate_the_boss() or failed
	failed = not _test_1_18_prewarms_boss_assets_before_spawn() or failed
	failed = not _test_cirno_shared_frame_cache_reloads_when_stale() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _find_level_index(level_id: String) -> int:
	for i in range(Defs.LEVELS.size()):
		if String(Defs.LEVELS[i].get("id", "")) == level_id:
			return i
	return -1


func _make_game() -> Control:
	var game := GameScript.new()
	game.current_level = {"id": "1-test", "terrain": "day", "events": []}
	game.active_rows = [0, 1, 2, 3, 4]
	game.water_rows = []
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	game.grid = []
	game.support_grid = []
	for _row in range(6):
		var row_data: Array = []
		var support_row: Array = []
		for _col in range(9):
			row_data.append(null)
			support_row.append(null)
		game.grid.append(row_data)
		game.support_grid.append(support_row)
	game.zombies = []
	game.mowers = []
	for row in range(6):
		game.mowers.append({
			"row": row,
			"x": game.BOARD_ORIGIN.x - 56.0,
			"armed": true,
			"active": false,
		})
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


func _begin_level(game: Control, level_id: String) -> int:
	var level_index = _find_level_index(level_id)
	if level_index != -1:
		game._begin_level(level_index, [])
	return level_index


func _test_1_18_unlock_requires_1_17_and_3_4() -> bool:
	var level_index = _find_level_index("1-18")
	var day_special_index = _find_level_index("1-17")
	var pool_gate_index = _find_level_index("3-4")
	var passed = _assert_true(level_index != -1, "expected special level 1-18 to exist") \
		and _assert_true(day_special_index != -1, "expected 1-17 prerequisite to exist") \
		and _assert_true(pool_gate_index != -1, "expected 3-4 prerequisite to exist")
	if not passed:
		return false
	var game = _make_game()
	game.completed_levels.resize(Defs.LEVELS.size())
	for i in range(game.completed_levels.size()):
		game.completed_levels[i] = false
	game.unlocked_levels = Defs.LEVELS.size()
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "1-18 should stay locked before both prerequisites are complete") and passed
	game.completed_levels[day_special_index] = true
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "1-18 should still stay locked with only 1-17 complete") and passed
	game.completed_levels[day_special_index] = false
	game.completed_levels[pool_gate_index] = true
	passed = _assert_true(not bool(game.call("_is_level_unlocked", level_index)), "1-18 should still stay locked with only 3-4 complete") and passed
	game.completed_levels[day_special_index] = true
	passed = _assert_true(bool(game.call("_is_level_unlocked", level_index)), "1-18 should unlock only after both 1-17 and 3-4 are complete") and passed
	_free_game(game)
	return passed


func _test_1_18_follows_1_17_in_day_world() -> bool:
	var level_index = _find_level_index("1-18")
	var prev_index = _find_level_index("1-17")
	var passed = _assert_true(level_index != -1, "expected 1-18 to exist for order checks") \
		and _assert_true(prev_index != -1, "expected 1-17 to exist for order checks")
	if not passed:
		return false
	var game = _make_game()
	var level = Defs.LEVELS[level_index]
	passed = _assert_true(level_index == prev_index + 1, "1-18 should be placed immediately after 1-17") and passed
	passed = _assert_true(String(game.call("_world_key_for_level", level)) == "day", "1-18 should remain in the day world") and passed
	passed = _assert_true(String(level.get("mode", "")) == "conveyor", "1-18 should be a conveyor level") and passed
	passed = _assert_true(bool(level.get("boss_level", false)), "1-18 should be marked as a boss level") and passed
	_free_game(game)
	return passed


func _test_1_18_starts_with_split_water_and_land_cells() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking split terrain"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_cell_terrain_kind"), "expected _cell_terrain_kind helper to exist for mixed terrain levels"):
		_free_game(game)
		return false
	var passed = _assert_true(String(game.call("_cell_terrain_kind", 0, 0)) == "water", "1-18 left edge should start as water") \
		and _assert_true(String(game.call("_cell_terrain_kind", 0, 4)) == "water", "1-18 fifth column should still be water") \
		and _assert_true(String(game.call("_cell_terrain_kind", 0, 5)) == "land", "1-18 sixth column should switch to land") \
		and _assert_true(String(game.call("_cell_terrain_kind", 4, 8)) == "land", "1-18 far right should stay land")
	passed = _assert_true(game._placement_error("peashooter", 0, 0) == "水路需要先放睡莲", "plants on the left pool should require lily pads before Cirno appears") and passed
	passed = _assert_true(game._placement_error("peashooter", 0, 5) == "", "plants on the right land should be placeable directly") and passed
	_free_game(game)
	return passed


func _test_cirno_freeze_turns_left_pool_into_frozen_support_cells() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking freeze conversion"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_trigger_cirno_freeze_transition"), "expected _trigger_cirno_freeze_transition helper to exist"):
		_free_game(game)
		return false
	game.call("_trigger_cirno_freeze_transition")
	var passed = _assert_true(String(game.call("_cell_terrain_kind", 0, 0)) == "frozen", "Cirno should freeze the left pool columns into frozen cells") \
		and _assert_true(String(game.call("_cell_terrain_kind", 0, 5)) == "land", "Cirno should not alter the right land columns")
	passed = _assert_true(game._placement_error("peashooter", 0, 0) == "", "frozen pool cells should no longer require lily pads") and passed
	passed = _assert_true(game._placement_error("lily_pad", 0, 0) != "", "lily pads should stop being valid on frozen cells") and passed
	_free_game(game)
	return passed


func _test_frozen_cells_slow_attack_cadence() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking frozen cadence slowdown"):
		_free_game(game)
		return false
	game.call("_trigger_cirno_freeze_transition")
	var frozen_plant = game._create_plant("peashooter", 0, 0)
	var land_plant = game._create_plant("peashooter", 0, 5)
	frozen_plant["shot_cooldown"] = 2.0
	land_plant["shot_cooldown"] = 2.0
	game.grid[0][0] = frozen_plant
	game.grid[0][5] = land_plant
	game._update_plants(1.0)
	var frozen_cooldown = float(game.grid[0][0]["shot_cooldown"])
	var land_cooldown = float(game.grid[0][5]["shot_cooldown"])
	var passed = _assert_true(frozen_cooldown > land_cooldown, "frozen cells should reduce plant attack cadence compared with land cells")
	_free_game(game)
	return passed


func _test_daiyousei_midboss_locks_progress_until_defeated() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking the mid-boss gate"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_update_frozen_branch_flow"), "expected _update_frozen_branch_flow helper to exist"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_battle_progress_ratio"), "expected _battle_progress_ratio helper to exist"):
		_free_game(game)
		return false
	game.total_kills = 30
	game.expected_spawn_units = 50
	game.call("_update_frozen_branch_flow")
	var found_midboss := false
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) == "daiyousei_boss":
			found_midboss = true
			break
	var passed = _assert_true(found_midboss, "Daiyousei should appear once the frozen branch reaches half progress") \
		and _assert_true(float(game.call("_battle_progress_ratio")) <= 0.5, "the wave bar should lock at half progress while Daiyousei is alive")
	if found_midboss:
		for i in range(game.zombies.size()):
			if String(game.zombies[i].get("kind", "")) == "daiyousei_boss":
				var boss = game.zombies[i]
				boss["rumia_reinforcement_timer"] = 0.0
				game.zombies[i] = boss
				break
		game._update_zombies(0.1)
		var reinforcement_found := false
		for zombie in game.zombies:
			if String(zombie.get("kind", "")) == "daiyousei_boss":
				continue
			if float(zombie.get("x", 0.0)) >= game.BOARD_ORIGIN.x + game.board_size.x:
				reinforcement_found = true
				break
		passed = _assert_true(reinforcement_found, "Daiyousei should keep spawning right-side pressure while the progress gate is active") and passed
		for i in range(game.zombies.size()):
			if String(game.zombies[i].get("kind", "")) == "daiyousei_boss":
				var boss = game.zombies[i]
				boss["health"] = 0.0
				game.zombies[i] = boss
				break
		game.call("_update_frozen_branch_flow")
		passed = _assert_true(float(game.call("_battle_progress_ratio")) > 0.5, "progress should resume after Daiyousei is defeated") and passed
	_free_game(game)
	return passed


func _test_daiyousei_spellcards_create_effects_and_damage_plants() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking Daiyousei spellcards"):
		_free_game(game)
		return false
	var center_plant = game._create_plant("wallnut", 2, 4)
	game.grid[2][4] = center_plant
	game._spawn_zombie_at("daiyousei_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 16.0)
	var expectations = {
		0: "fairy_ring",
		1: "fairy_lance",
	}
	var passed := true
	for cycle in expectations.keys():
		game.effects.clear()
		var boss = game.zombies[0]
		boss["boss_skill_cycle"] = int(cycle)
		game.zombies[0] = boss
		var before_health = float(game.grid[2][4]["health"])
		game._trigger_boss_skill(boss)
		var found := false
		for effect in game.effects:
			if String(effect.get("shape", "")) == String(expectations[cycle]) and float(effect.get("anim_speed", 0.0)) > 0.0:
				found = true
				break
		passed = _assert_true(found, "Daiyousei cycle %d should create an animated %s effect" % [int(cycle), String(expectations[cycle])]) and passed
		passed = _assert_true(float(game.grid[2][4]["health"]) < before_health, "Daiyousei cycle %d should damage plants instead of being pure decoration" % int(cycle)) and passed
	return passed


func _test_cirno_freeze_swaps_conveyor_pool() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking the post-freeze conveyor pool"):
		_free_game(game)
		return false
	var pre_freeze_lily_count := 0
	for kind in game.conveyor_source_cards:
		if String(kind) == "lily_pad":
			pre_freeze_lily_count += 1
	var pre_freeze_has_water_support = game.conveyor_source_cards.has("lily_pad") and game.conveyor_source_cards.has("tangle_kelp")
	game.call("_trigger_cirno_freeze_transition")
	var passed = _assert_true(pre_freeze_has_water_support, "1-18 should start with water-support plants in the conveyor pool") \
		and _assert_true(pre_freeze_lily_count >= 5, "1-18 should bias the pre-freeze conveyor pool toward lily pads") \
		and _assert_true(not game.conveyor_source_cards.has("lily_pad"), "frozen conveyor pool should remove lily pads after the lake freezes") \
		and _assert_true(not game.conveyor_source_cards.has("tangle_kelp"), "frozen conveyor pool should remove kelp after the lake freezes") \
		and _assert_true(game.conveyor_source_cards.has("ice_shroom"), "frozen conveyor pool should pivot toward ice-themed cards after Cirno appears")
	_free_game(game)
	return passed


func _test_cirno_spellcards_create_ice_effects_and_reinforcements() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking Cirno spellcards"):
		_free_game(game)
		return false
	for row in game.active_rows:
		var row_i = int(row)
		for col in range(5, game.COLS):
			var plant = game._create_plant("wallnut", row_i, col)
			game.grid[row_i][col] = plant
	game._spawn_zombie_at("cirno_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 16.0)
	var expectations = {
		0: "icicle_fall",
		1: "perfect_freeze",
		2: "diamond_blizzard",
	}
	var passed := true
	for cycle in expectations.keys():
		game.effects.clear()
		var boss = game.zombies[0]
		boss["boss_skill_cycle"] = int(cycle)
		game.zombies[0] = boss
		var before_health = float(game.grid[2][5]["health"])
		game._trigger_boss_skill(boss)
		var found := false
		for effect in game.effects:
			if String(effect.get("shape", "")) == String(expectations[cycle]) and float(effect.get("anim_speed", 0.0)) > 0.0:
				found = true
				break
		passed = _assert_true(found, "Cirno cycle %d should create an animated %s effect" % [int(cycle), String(expectations[cycle])]) and passed
		passed = _assert_true(float(game.grid[2][5]["health"]) < before_health, "Cirno cycle %d should threaten plants instead of only animating" % int(cycle)) and passed
	var cirno = game.zombies[0]
	cirno["rumia_reinforcement_timer"] = 0.0
	game.zombies[0] = cirno
	game._update_zombies(0.1)
	var reinforcement_found := false
	for zombie in game.zombies:
		if String(zombie.get("kind", "")) == "cirno_boss":
			continue
		if float(zombie.get("x", 0.0)) >= game.BOARD_ORIGIN.x + game.board_size.x:
			reinforcement_found = true
			break
	passed = _assert_true(reinforcement_found, "Cirno should keep spawning right-side reinforcements during the final boss phase") and passed
	_free_game(game)
	return passed


func _test_boss_frame_cleanup_removes_white_border_and_faces_left() -> bool:
	var game = _make_game()
	if not _assert_true(game.has_method("_prepare_boss_frame_image"), "expected _prepare_boss_frame_image helper to exist for runtime boss cleanup"):
		_free_game(game)
		return false
	var image := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 1.0))
	image.set_pixel(2, 1, Color(1.0, 0.0, 0.0, 1.0))
	image.set_pixel(3, 1, Color(0.0, 0.0, 1.0, 1.0))
	image.set_pixel(6, 3, Color(1.0, 1.0, 1.0, 1.0))
	var processed = game.call("_prepare_boss_frame_image", image, true)
	var passed = _assert_true(processed is Image, "boss cleanup should return an Image") 
	if processed is Image:
		passed = _assert_true(processed.get_width() < image.get_width(), "boss cleanup should trim away white borders") and passed
		passed = _assert_true(processed.get_height() < image.get_height(), "boss cleanup should crop away empty top/bottom whitespace") and passed
		passed = _assert_true(processed.get_pixel(0, 0).b > 0.8, "boss cleanup should flip the remaining sprite to face left") and passed
		passed = _assert_true(processed.get_pixel(processed.get_width() - 1, processed.get_height() - 1).a < 0.1 or processed.get_pixel(processed.get_width() - 1, processed.get_height() - 1).r > 0.8, "boss cleanup should discard stray white leftovers instead of keeping edge artifacts") and passed
	_free_game(game)
	return passed


func _test_prebaked_cirno_frames_have_clean_transparent_outer_edges() -> bool:
	var passed := true
	for frame_index in range(8):
		var image := Image.new()
		var path = ProjectSettings.globalize_path("res://art/cirno/frame_%02d.png" % frame_index)
		if image.load(path) != OK:
			passed = _assert_true(false, "expected prebaked Cirno frame %02d to load from disk" % frame_index) and passed
			continue
		image.convert(Image.FORMAT_RGBA8)
		var width = image.get_width()
		var height = image.get_height()
		for y in range(height):
			for x in range(width):
				if x != 0 and x != width - 1 and y != 0 and y != height - 1:
					continue
				var pixel = image.get_pixel(x, y)
				var is_opaque_white = pixel.a > 0.05 and pixel.r > 0.93 and pixel.g > 0.93 and pixel.b > 0.93
				passed = _assert_true(not is_opaque_white, "Cirno prebaked frame %02d should not keep opaque white edge pixels after offline cleanup" % frame_index) and passed
	return passed


func _test_prebaked_cirno_frames_keep_safe_transparent_margin_and_no_far_fragments() -> bool:
	var passed := true
	for frame_index in range(8):
		var image := Image.new()
		var path = ProjectSettings.globalize_path("res://art/cirno/frame_%02d.png" % frame_index)
		if image.load(path) != OK:
			passed = _assert_true(false, "expected Cirno prebaked frame %02d to load before checking sprite cleanup" % frame_index) and passed
			continue
		image.convert(Image.FORMAT_RGBA8)
		var width = image.get_width()
		var height = image.get_height()
		var safe_margin = min(4, min(width, height) / 2)
		var margin_is_clean := true
		for y in range(height):
			for x in range(width):
				if x >= safe_margin and x < width - safe_margin and y >= safe_margin and y < height - safe_margin:
					continue
				var pixel = image.get_pixel(x, y)
				if pixel.a > 0.05:
					margin_is_clean = false
					break
			if not margin_is_clean:
				break
		passed = _assert_true(margin_is_clean, "Cirno prebaked frame %02d should keep a transparent outer safety margin after offline cleanup" % frame_index) and passed
		var components = _collect_opaque_components(image)
		if components.is_empty():
			passed = _assert_true(false, "Cirno prebaked frame %02d should still contain a visible sprite body after cleanup" % frame_index) and passed
			continue
		var dominant_index := 0
		var dominant_pixels := int(components[0]["pixels"])
		for component_index in range(1, components.size()):
			var candidate_pixels = int(components[component_index]["pixels"])
			if candidate_pixels > dominant_pixels:
				dominant_pixels = candidate_pixels
				dominant_index = component_index
		var dominant_rect: Rect2i = components[dominant_index]["rect"]
		var dominant_safe_rect = _expand_rect(dominant_rect, 24)
		for component_index in range(components.size()):
			if component_index == dominant_index:
				continue
			var component = components[component_index]
			var component_pixels = int(component["pixels"])
			if component_pixels < 800:
				continue
			var component_rect: Rect2i = component["rect"]
			var fragment_is_attached = _rects_intersect(dominant_safe_rect, component_rect)
			passed = _assert_true(fragment_is_attached, "Cirno prebaked frame %02d still keeps a large disconnected fragment away from the boss body" % frame_index) and passed
			if not fragment_is_attached:
				break
	return passed


func _collect_opaque_components(image: Image) -> Array:
	var width = image.get_width()
	var height = image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var components: Array = []
	for y in range(height):
		for x in range(width):
			var index = y * width + x
			if visited[index] != 0:
				continue
			visited[index] = 1
			var pixel = image.get_pixel(x, y)
			if pixel.a <= 0.05:
				continue
			var queue: Array = [Vector2i(x, y)]
			var head := 0
			var min_x := x
			var min_y := y
			var max_x := x
			var max_y := y
			var pixels := 0
			while head < queue.size():
				var point: Vector2i = queue[head]
				head += 1
				pixels += 1
				min_x = min(min_x, point.x)
				min_y = min(min_y, point.y)
				max_x = max(max_x, point.x)
				max_y = max(max_y, point.y)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next = point + offset
					if next.x < 0 or next.x >= width or next.y < 0 or next.y >= height:
						continue
					var next_index = next.y * width + next.x
					if visited[next_index] != 0:
						continue
					visited[next_index] = 1
					if image.get_pixel(next.x, next.y).a <= 0.05:
						continue
					queue.append(next)
			components.append({
				"pixels": pixels,
				"rect": Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1),
			})
	return components


func _expand_rect(rect: Rect2i, amount: int) -> Rect2i:
	return Rect2i(
		rect.position - Vector2i(amount, amount),
		rect.size + Vector2i(amount * 2, amount * 2)
	)


func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
	return not (
		a.position.x + a.size.x <= b.position.x
		or b.position.x + b.size.x <= a.position.x
		or a.position.y + a.size.y <= b.position.y
		or b.position.y + b.size.y <= a.position.y
	)


func _test_cirno_freeze_clears_existing_water_support_cards() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking frozen conveyor hand cleanup"):
		_free_game(game)
		return false
	game.active_cards = ["lily_pad", "tangle_kelp", "snow_pea", "", "", "", "", "", "", ""]
	game.call("_trigger_cirno_freeze_transition")
	var passed = _assert_true(not game.active_cards.has("lily_pad"), "frozen transition should remove already drawn lily pads from the conveyor hand") \
		and _assert_true(not game.active_cards.has("tangle_kelp"), "frozen transition should remove already drawn kelp from the conveyor hand")
	_free_game(game)
	return passed


func _test_cirno_freeze_animates_smoothly() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking the freeze animation"):
		_free_game(game)
		return false
	if not _assert_true(game.has_method("_freeze_transition_visual_ratio"), "expected _freeze_transition_visual_ratio helper to exist"):
		_free_game(game)
		return false
	game.call("_trigger_cirno_freeze_transition")
	var start_ratio = float(game.call("_freeze_transition_visual_ratio"))
	game.call("_update_freeze_transition_visual", 0.18)
	var mid_ratio = float(game.call("_freeze_transition_visual_ratio"))
	game.call("_update_freeze_transition_visual", 1.2)
	var end_ratio = float(game.call("_freeze_transition_visual_ratio"))
	var passed = _assert_true(start_ratio <= 0.05, "freeze animation should start near zero instead of instantly snapping to full ice") \
		and _assert_true(mid_ratio > start_ratio and mid_ratio < 1.0, "freeze animation should ease through an in-between blend state") \
		and _assert_true(end_ratio >= 0.99, "freeze animation should eventually complete")
	_free_game(game)
	return passed


func _test_1_18_assets_and_bgm_are_present() -> bool:
	var required_paths = [
		"res://audio/cirno_intro.mp3",
		"res://audio/cirno_boss.mp3",
	]
	for frame_index in range(8):
		required_paths.append("res://art/cirno/frame_%02d.png" % frame_index)
		required_paths.append("res://art/daiyousei/frame_%02d.png" % frame_index)
	var passed := true
	for path in required_paths:
		passed = _assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(path)), "expected 1-18 asset to exist: %s" % path) and passed
	var game = _make_game()
	var intro_stream = game._load_audio_stream("res://audio/cirno_intro.mp3")
	var boss_stream = game._load_audio_stream("res://audio/cirno_boss.mp3")
	passed = _assert_true(intro_stream is AudioStreamMP3, "Cirno intro BGM should load as AudioStreamMP3") and passed
	passed = _assert_true(boss_stream is AudioStreamMP3, "Cirno boss BGM should load as AudioStreamMP3") and passed
	if intro_stream is AudioStreamMP3:
		passed = _assert_true(bool(intro_stream.loop), "Cirno intro BGM should loop") and passed
	if boss_stream is AudioStreamMP3:
		passed = _assert_true(bool(boss_stream.loop), "Cirno boss BGM should loop") and passed
	_free_game(game)
	return passed


func _test_daiyousei_defeat_does_not_end_remaining_stage_flow() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking midboss defeat flow"):
		_free_game(game)
		return false
	var level_events = game.current_level.get("events", [])
	game.next_event_index = max(1, int(floor(float(level_events.size()) * 0.5)))
	game.frozen_branch_midboss_spawned = true
	game.frozen_branch_progress_locked = true
	game.battle_state = game.BATTLE_PLAYING
	game._spawn_zombie_at("daiyousei_boss", 2, game.BOARD_ORIGIN.x + game.board_size.x - 24.0, true)
	game._spawn_zombie_at("normal", 2, game.BOARD_ORIGIN.x + game.board_size.x - 88.0)
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if String(zombie.get("kind", "")) == "daiyousei_boss":
			zombie["health"] = 0.0
			game.zombies[i] = zombie
			break
	game._cleanup_dead_zombies()
	for i in range(game.zombies.size()):
		var zombie = game.zombies[i]
		if String(zombie.get("kind", "")) == "normal":
			zombie["health"] = 0.0
			game.zombies[i] = zombie
			break
	game._cleanup_dead_zombies()
	game._check_end_state()
	var passed = _assert_true(game.next_event_index < level_events.size(), "defeating Daiyousei should not skip the remaining 1-18 event queue") \
		and _assert_true(game.battle_state == game.BATTLE_PLAYING, "clearing residual zombies after Daiyousei should not auto-win while the rest of 1-18 remains")
	_free_game(game)
	return passed


func _test_cirno_event_supports_do_not_duplicate_the_boss() -> bool:
	var level_index = _find_level_index("1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking Cirno support spawns"):
		return false
	var game = _make_game()
	var level = Defs.LEVELS[level_index]
	var cirno_event_index := -1
	for i in range(level.get("events", []).size()):
		if String(level["events"][i].get("kind", "")) == "cirno_boss":
			cirno_event_index = i
			break
	var passed = _assert_true(cirno_event_index != -1, "expected 1-18 to define a Cirno boss event")
	if passed:
		game.current_level = level
		passed = _assert_true(
			String(game.call("_support_spawn_kind", "cirno_boss", cirno_event_index, 0)) != "cirno_boss",
			"Cirno boss events should not enqueue a duplicate Cirno as a support spawn"
		) and passed
	_free_game(game)
	return passed


func _test_1_18_prewarms_boss_assets_before_spawn() -> bool:
	var game = _make_game()
	var level_index = _begin_level(game, "1-18")
	if not _assert_true(level_index != -1, "expected 1-18 to exist before checking boss prewarm"):
		_free_game(game)
		return false
	var passed = _assert_true(int(game.asset_prewarm_queue.size()) > 0, "1-18 should queue boss art and BGM warmup before the boss appears") \
		and _assert_true(not bool(game.cirno_frames_loaded), "1-18 boss warmup should be asynchronous until the queue is serviced") \
		and _assert_true(not bool(game.daiyousei_frames_loaded), "1-18 midboss warmup should be asynchronous until the queue is serviced")
	if passed:
		game.call("_drain_asset_prewarm_queue")
		passed = _assert_true(bool(game.cirno_frames_loaded), "1-18 should warm Cirno sprite frames once the prewarm queue is drained") and passed
		passed = _assert_true(bool(game.daiyousei_frames_loaded), "1-18 should warm Daiyousei sprite frames once the prewarm queue is drained") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/cirno_intro.mp3"), "1-18 should preload the intro BGM to avoid a boss-entry hitch") and passed
		passed = _assert_true(game.audio_stream_cache.has("res://audio/cirno_boss.mp3"), "1-18 should preload the boss BGM to avoid a boss-entry hitch") and passed
	_free_game(game)
	return passed


func _test_cirno_shared_frame_cache_reloads_when_stale() -> bool:
	var previous_loaded = GameScript.shared_cirno_frames_loaded
	var previous_frames = GameScript.shared_cirno_frames
	var previous_face_left = GameScript.shared_cirno_frames_face_left
	var stale_frames: Array = []
	for frame_index in range(8):
		var image := Image.create(2, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.0, 0.0, 0.0, 0.0))
		image.set_pixel(0, 0, Color(1.0, 0.0, 0.0, 1.0))
		image.set_pixel(1, 0, Color(0.0, 0.0, 1.0, 1.0))
		stale_frames.append(ImageTexture.create_from_image(image))
	GameScript.shared_cirno_frames_loaded = true
	GameScript.shared_cirno_frames = stale_frames
	GameScript.shared_cirno_frames_face_left = true
	var game = _make_game()
	game.cirno_frames = []
	game.cirno_frames_loaded = false
	game.call("_ensure_cirno_frames_loaded")
	var passed = _assert_true(game.cirno_frames.size() == 8, "Cirno should still load a full boss frame set when the shared cache is stale") \
		and _assert_true(game.cirno_frames[0] != stale_frames[0], "Cirno should rebuild a stale shared boss frame cache instead of reusing mismatched orientation metadata")
	_free_game(game)
	GameScript.shared_cirno_frames_loaded = previous_loaded
	GameScript.shared_cirno_frames = previous_frames
	GameScript.shared_cirno_frames_face_left = previous_face_left
	return passed
