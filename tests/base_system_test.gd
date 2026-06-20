extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_base_defaults_create_all_rooms_and_resources() or failed
	failed = not _test_base_assignments_are_unique_and_capacity_limited() or failed
	failed = not _test_base_elapsed_generates_pending_resources_and_morale_changes() or failed
	failed = not _test_base_collect_all_transfers_rewards_to_existing_currencies() or failed
	failed = not _test_base_offline_elapsed_is_capped() or failed
	failed = not _test_base_layout_rects_do_not_overlap_or_leave_viewport() or failed
	failed = not _test_base_roster_draws_complete_cells() or failed
	failed = not _test_base_collect_spawns_typed_fx_and_decay() or failed
	failed = not _test_base_drone_boost_spawns_scan_and_drone_fx() or failed
	failed = not _test_base_assignment_and_selection_spawn_feedback_fx() or failed
	failed = not _test_base_fx_particles_are_bounded() or failed
	failed = not _test_base_fx_anchors_stay_inside_layout_rects() or failed
	failed = not _test_base_save_merge_preserves_progress() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _make_game() -> Control:
	var game := GameScript.new()
	game.size = Vector2(1600.0, 900.0)
	game.toast_label = Label.new()
	game.banner_label = Label.new()
	game.message_panel = PanelContainer.new()
	game.message_label = Label.new()
	game.action_button = Button.new()
	return game


func _free_game(game: Control) -> void:
	game.save_dirty = false
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


func _base_ready_game() -> Control:
	var game := _make_game()
	if game.has_method("_init_base_defaults"):
		game.call("_init_base_defaults")
	return game


func _test_base_defaults_create_all_rooms_and_resources() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_init_base_defaults"), "base mode should expose default initialization") \
		and _assert_true(game.has_method("_base_room_defs"), "base mode should expose room definitions")
	if passed:
		game.call("_init_base_defaults")
		var room_defs: Dictionary = game.call("_base_room_defs")
		for room_id in ["control", "trade", "factory", "power", "dorm", "workshop", "training"]:
			passed = _assert_true(room_defs.has(room_id), "base room defs should include %s" % room_id) and passed
			passed = _assert_true(game.base_rooms.has(room_id), "base save state should create room %s" % room_id) and passed
			passed = _assert_true(game.base_assignments.has(room_id), "base assignments should create room %s" % room_id) and passed
		passed = _assert_true(game.base_inventory.has("coins") and game.base_inventory.has("materials") and game.base_inventory.has("fragments"), "base inventory should track pending coins, materials, and fragments") and passed
		passed = _assert_true(float(game.base_morale.get("peashooter", 0.0)) > 0.0, "base morale should initialize known plants") and passed
		passed = _assert_true(String(game.base_selected_room) == "control", "base should default-select the control center") and passed
	_free_game(game)
	return passed


func _test_base_assignments_are_unique_and_capacity_limited() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_assign_plant"), "base should assign plants to rooms")
	if passed:
		var first := bool(game.call("_base_assign_plant", "power", "peashooter"))
		var second := bool(game.call("_base_assign_plant", "power", "sunflower"))
		passed = _assert_true(first, "first plant should enter a room with free capacity") and passed
		passed = _assert_true(not second, "second plant should not exceed a one-slot power room") and passed
		passed = _assert_true(Array(game.base_assignments.get("power", [])).has("peashooter"), "power room should keep its assigned plant") and passed
		var moved := bool(game.call("_base_assign_plant", "factory", "peashooter"))
		passed = _assert_true(moved, "assigning a plant to another room should move it") and passed
		passed = _assert_true(not Array(game.base_assignments.get("power", [])).has("peashooter"), "moving a plant should remove it from its old room") and passed
		passed = _assert_true(Array(game.base_assignments.get("factory", [])).has("peashooter"), "moving a plant should add it to the new room") and passed
	_free_game(game)
	return passed


func _test_base_elapsed_generates_pending_resources_and_morale_changes() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_apply_base_elapsed"), "base should apply elapsed production time") \
		and _assert_true(game.has_method("_base_assign_plant"), "base should assign plants before production")
	if passed:
		game.call("_base_assign_plant", "trade", "sunflower")
		game.call("_base_assign_plant", "factory", "peashooter")
		game.call("_base_assign_plant", "power", "wallnut")
		var before_morale := float(game.base_morale.get("sunflower", 0.0))
		game.call("_apply_base_elapsed", 3600.0)
		var pending_materials: Dictionary = game.base_inventory.get("materials", {})
		passed = _assert_true(float(game.base_inventory.get("coins", 0.0)) > 0.0, "trade room should generate pending coins") and passed
		passed = _assert_true(not pending_materials.is_empty(), "factory should generate pending enhancement materials") and passed
		passed = _assert_true(float(game.base_drones) > 0.0, "power room should generate drones") and passed
		passed = _assert_true(float(game.base_morale.get("sunflower", before_morale)) < before_morale, "working plants should lose morale") and passed
	_free_game(game)
	return passed


func _test_base_collect_all_transfers_rewards_to_existing_currencies() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_collect_all"), "base should collect pending rewards")
	if passed:
		game.base_inventory = {
			"coins": 180.0,
			"materials": {"growth_core": 3.0},
			"fragments": {"peashooter": 2.0},
		}
		game.coins_total = 5
		game.enhance_materials = {}
		game.plant_fragments = {}
		game.call("_base_collect_all")
		passed = _assert_true(int(game.coins_total) == 185, "base collect should transfer pending coins") and passed
		passed = _assert_true(int(game.enhance_materials.get("growth_core", 0)) == 3, "base collect should transfer pending materials") and passed
		passed = _assert_true(int(game.plant_fragments.get("peashooter", 0)) == 2, "base collect should transfer pending plant fragments") and passed
		passed = _assert_true(float(game.base_inventory.get("coins", -1.0)) == 0.0, "base collect should clear pending coins") and passed
	_free_game(game)
	return passed


func _test_base_offline_elapsed_is_capped() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_apply_base_elapsed"), "base should apply capped offline production")
	if passed:
		game.call("_base_assign_plant", "trade", "sunflower")
		game.call("_apply_base_elapsed", 24.0 * 3600.0)
		var day_coins := float(game.base_inventory.get("coins", 0.0))
		game.base_inventory["coins"] = 0.0
		game.base_morale["sunflower"] = 24.0
		game.call("_apply_base_elapsed", 8.0 * 3600.0)
		var capped_coins := float(game.base_inventory.get("coins", 0.0))
		passed = _assert_true(absf(day_coins - capped_coins) < 0.01, "offline production should be capped to the configured 8-hour window") and passed
	_free_game(game)
	return passed


func _test_base_layout_rects_do_not_overlap_or_leave_viewport() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_top_bar_rect"), "base UI should expose top bar rect") \
		and _assert_true(game.has_method("_base_room_grid_rect"), "base UI should expose room grid rect") \
		and _assert_true(game.has_method("_base_detail_rect"), "base UI should expose detail rect") \
		and _assert_true(game.has_method("_base_roster_panel_rect"), "base UI should expose roster rect")
	if passed:
		var viewport_rect := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
		var rects := [
			Rect2(game.call("_base_top_bar_rect")),
			Rect2(game.call("_base_room_grid_rect")),
			Rect2(game.call("_base_detail_rect")),
			Rect2(game.call("_base_roster_panel_rect")),
			Rect2(game.call("_base_back_rect")),
			Rect2(game.call("_base_collect_rect")),
			Rect2(game.call("_base_boost_rect")),
		]
		for rect in rects:
			passed = _assert_true(viewport_rect.encloses(rect), "base UI rect should stay inside viewport: %s" % str(rect)) and passed
		passed = _assert_true(not rects[1].intersects(rects[2]), "base room grid should not overlap detail panel") and passed
		passed = _assert_true(not rects[2].intersects(rects[3]), "base detail panel should not overlap roster panel") and passed
		passed = _assert_true(not rects[1].intersects(rects[3]), "base room grid should not overlap roster panel") and passed
		passed = _assert_true(not rects[5].intersects(rects[6]), "base collect and drone boost buttons should not overlap") and passed
		for i in range(7):
			var room_rect: Rect2 = game.call("_base_room_card_rect", i)
			passed = _assert_true(rects[1].encloses(room_rect), "base room card %d should stay inside the room grid" % i) and passed
	_free_game(game)
	return passed


func _test_base_roster_draws_complete_cells() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_roster_layout"), "base roster should expose a layout helper") \
		and _assert_true(game.has_method("_base_roster_cell_rect"), "base roster should expose cell rects")
	if passed:
		var layout: Dictionary = game.call("_base_roster_layout")
		var view_rect: Rect2 = game.call("_base_roster_view_rect")
		var cell_w := float(layout.get("cell_w", 0.0))
		var cell_gap := float(layout.get("cell_gap", 0.0))
		var visible_cols := int(floor((view_rect.size.x + cell_gap) / maxf(cell_w + cell_gap, 1.0)))
		var used_w := float(visible_cols) * cell_w + float(max(0, visible_cols - 1)) * cell_gap
		passed = _assert_true(visible_cols >= 3, "base roster should fit several complete plant cells") and passed
		passed = _assert_true(absf(view_rect.size.x - used_w) < 0.01, "base roster view width should fit whole cells without clipping") and passed
		for index in range(visible_cols):
			var cell_rect: Rect2 = game.call("_base_roster_cell_rect", index)
			passed = _assert_true(view_rect.encloses(cell_rect), "base roster should draw only complete cells in the view") and passed
	_free_game(game)
	return passed


func _test_base_collect_spawns_typed_fx_and_decay() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_fx_count"), "base should expose typed fx counts") \
		and _assert_true(game.has_method("_update_base_fx"), "base should update transient fx")
	if passed:
		game.base_inventory = {
			"coins": 90.0,
			"materials": {"growth_core": 2.0},
			"fragments": {"peashooter": 1.0},
		}
		game.call("_base_collect_all")
		passed = _assert_true(int(game.call("_base_fx_count", "collect")) >= 3, "collect should spawn typed flying resource fx") and passed
		var first_fx: Dictionary = game.base_fx_particles[0]
		passed = _assert_true(first_fx.has("kind") and first_fx.has("from") and first_fx.has("to") and first_fx.has("duration"), "collect fx should carry typed path metadata") and passed
		game.call("_update_base_fx", 3.0)
		passed = _assert_true(int(game.call("_base_fx_count", "collect")) == 0, "collect fx should expire after its lifetime") and passed
	_free_game(game)
	return passed


func _test_base_drone_boost_spawns_scan_and_drone_fx() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_fx_count"), "base should expose typed fx counts")
	if passed:
		game.base_drones = 24.0
		var boosted := bool(game.call("_base_boost_room", "factory"))
		passed = _assert_true(boosted, "drone boost should succeed when enough drones exist") and passed
		passed = _assert_true(float(game.base_scan_pulse) > 0.0, "drone boost should start the scan pulse") and passed
		passed = _assert_true(int(game.call("_base_fx_count", "drone")) >= 3, "drone boost should spawn drone streak fx") and passed
		passed = _assert_true(int(game.call("_base_fx_count", "room_pulse")) >= 1, "drone boost should pulse the boosted room") and passed
	_free_game(game)
	return passed


func _test_base_assignment_and_selection_spawn_feedback_fx() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_fx_count"), "base should expose typed fx counts")
	if passed:
		var assigned := bool(game.call("_base_assign_plant", "trade", "sunflower"))
		passed = _assert_true(assigned, "assignment should still succeed") and passed
		passed = _assert_true(int(game.call("_base_fx_count", "slot_flash")) >= 1, "assignment should flash the target slot") and passed
		passed = _assert_true(int(game.call("_base_fx_count", "assign_line")) >= 1, "assignment should draw a short roster-to-room feedback line") and passed
		game.call("_base_set_factory_recipe", "assault_chip")
		passed = _assert_true(int(game.call("_base_fx_count", "chip_sweep")) >= 1, "recipe changes should sweep the selected material chip") and passed
		game.call("_base_set_training_target", "sunflower")
		passed = _assert_true(int(game.call("_base_fx_count", "chip_sweep")) >= 2, "training target changes should sweep the target panel") and passed
	_free_game(game)
	return passed


func _test_base_fx_particles_are_bounded() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_spawn_fx"), "base should expose a central fx spawn helper") \
		and _assert_true(game.has_method("_base_fx_count"), "base should expose typed fx counts")
	if passed:
		for i in range(140):
			game.call("_base_spawn_fx", "collect", Vector2(120.0 + float(i), 150.0), Vector2(700.0, 62.0), Color(1.0, 0.8, 0.2), 1.0, {})
		passed = _assert_true(game.base_fx_particles.size() <= 96, "base fx should be capped to prevent stutter") and passed
		passed = _assert_true(int(game.call("_base_fx_count", "collect")) <= 96, "typed fx count should respect the cap") and passed
	_free_game(game)
	return passed


func _test_base_fx_anchors_stay_inside_layout_rects() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_base_fx_anchor"), "base should expose testable fx anchors")
	if passed:
		var viewport_rect := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
		var grid: Rect2 = game.call("_base_room_grid_rect")
		var top: Rect2 = game.call("_base_top_bar_rect")
		for room_id in ["control", "trade", "factory", "power", "dorm", "workshop", "training"]:
			var room_anchor: Vector2 = game.call("_base_fx_anchor", room_id, "room")
			var slot_anchor: Vector2 = game.call("_base_fx_anchor", room_id, "slot")
			passed = _assert_true(grid.has_point(room_anchor), "room fx anchor should stay inside room grid for %s" % room_id) and passed
			passed = _assert_true(viewport_rect.has_point(slot_anchor), "slot fx anchor should stay inside viewport for %s" % room_id) and passed
		for target in ["coins", "drones", "pending"]:
			var target_anchor: Vector2 = game.call("_base_fx_anchor", target, "resource")
			passed = _assert_true(top.has_point(target_anchor), "resource fx target should stay inside top bar: %s" % target) and passed
	_free_game(game)
	return passed


func _test_base_save_merge_preserves_progress() -> bool:
	var game := _base_ready_game()
	var passed := _assert_true(game.has_method("_merge_base_progress"), "base should merge save progress")
	if passed:
		var existing_save := {
			"base_rooms": {"factory": {"level": 2, "recipe": "growth_core"}},
			"base_assignments": {"factory": ["sunflower"]},
			"base_morale": {"sunflower": 12.0},
			"base_inventory": {"coins": 120.0, "materials": {"growth_core": 4.0}, "fragments": {"peashooter": 1.0}},
			"base_drones": 40.0,
			"base_last_tick_unix": 1000,
		}
		var candidate_save := {
			"base_rooms": {"factory": {"level": 1, "recipe": "assault_chip"}, "trade": {"level": 1}},
			"base_assignments": {"trade": ["peashooter"]},
			"base_morale": {"sunflower": 20.0, "peashooter": 19.0},
			"base_inventory": {"coins": 80.0, "materials": {"growth_core": 1.0, "assault_chip": 3.0}, "fragments": {"peashooter": 4.0}},
			"base_drones": 12.0,
			"base_last_tick_unix": 1500,
		}
		var merged: Dictionary = game.call("_merge_base_progress", existing_save, candidate_save)
		var rooms: Dictionary = merged.get("base_rooms", {})
		var inventory: Dictionary = merged.get("base_inventory", {})
		var materials: Dictionary = inventory.get("materials", {})
		var fragments: Dictionary = inventory.get("fragments", {})
		passed = _assert_true(int(Dictionary(rooms.get("factory", {})).get("level", 0)) == 2, "base merge should preserve stronger room levels") and passed
		passed = _assert_true(int(materials.get("growth_core", 0)) == 4, "base merge should preserve stronger pending material counts") and passed
		passed = _assert_true(int(materials.get("assault_chip", 0)) == 3, "base merge should include newer pending material entries") and passed
		passed = _assert_true(int(fragments.get("peashooter", 0)) == 4, "base merge should preserve stronger pending fragments") and passed
		passed = _assert_true(float(merged.get("base_drones", 0.0)) == 40.0, "base merge should preserve stronger drone count") and passed
		passed = _assert_true(int(merged.get("base_last_tick_unix", 0)) == 1500, "base merge should keep the latest tick timestamp") and passed
	_free_game(game)
	return passed
