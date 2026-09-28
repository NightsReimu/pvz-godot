extends SceneTree

const GameScript = preload("res://scripts/game.gd")

var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GameScript.new()
	check(game.has_method("_selection_zombie_entry_progress"), "selection should expose a staggered zombie entry progress helper")
	check(game.has_method("_update_selection_card_flights"), "selection should update card flight animations")
	check(game.has_method("_update_hover_plant_motion"), "battle should update the smooth held-plant position")
	check(game.has_method("_battle_intro_text"), "battle should expose the original-style ready set plant sequence")
	if game.has_method("_battle_intro_text"):
		game.battle_intro_timer = game.BATTLE_INTRO_DURATION
		check(String(game.call("_battle_intro_text")) == "准备", "battle intro should begin with a preparation prompt")
		game.battle_intro_timer = 0.0
		check(String(game.call("_battle_intro_text")) == "", "battle intro should clear after planting prompt")
	if game.has_method("_selection_zombie_entry_progress"):
		game.selection_intro_time = 0.0
		check(float(game.call("_selection_zombie_entry_progress", 0)) == 0.0, "zombie preview should start offscreen")
		game.selection_intro_time = 1.0
		check(float(game.call("_selection_zombie_entry_progress", 0)) == 1.0, "zombie preview should settle after the intro")
	if game.has_method("_update_selection_card_flights"):
		game.selection_card_flights = [{"age": 0.0, "duration": 0.3}]
		game.call("_update_selection_card_flights", 0.1)
		check(float(game.selection_card_flights[0].age) > 0.0, "card flight age should advance")
	game.mode = game.MODE_SELECTION
	game.current_level = {"id": "motion", "available_plants": ["peashooter"], "events": [{"kind": "normal"}], "row_count": 5}
	game.selection_pool_cards = ["peashooter"]
	game.selection_cards = []
	game.selection_card_flights.clear()
	var pool_card_rect: Rect2 = game.call("_selection_pool_rect", 0)
	game.call("_handle_selection_click", pool_card_rect.get_center())
	check(game.selection_cards == ["peashooter"], "selecting a pool card should update the selected cards immediately")
	check(game.selection_card_flights.size() == 1, "selecting a pool card should create one flight animation")
	if game.has_method("_update_hover_plant_motion"):
		game.mode = game.MODE_BATTLE
		game.selected_tool = "peashooter"
		game.hover_preview_initialized = false
		game.hover_preview_position = Vector2.ZERO
		game.hover_preview_target = Vector2(420.0, 260.0)
		var smoothed: Vector2 = game.call("_smooth_ui_vector", Vector2.ZERO, game.hover_preview_target, 0.1, 18.0)
		check(smoothed != Vector2.ZERO, "held plant preview should move toward the target")
	game.free()
	print("Preparation motion animation checks: %d failure(s)" % failures)
	quit(1 if failures else 0)
