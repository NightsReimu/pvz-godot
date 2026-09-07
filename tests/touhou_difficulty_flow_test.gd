extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func index_of(id: String) -> int:
	for index in range(GameScript.Defs.LEVELS.size()):
		if GameScript.Defs.LEVELS[index].id == id:
			return index
	return -1


func _run() -> void:
	var game := PreviewGame.new()
	game.size = Vector2(1600, 900)
	root.add_child(game)
	game.unlocked_levels = GameScript.Defs.LEVELS.size()
	game.completed_levels.resize(GameScript.Defs.LEVELS.size())
	game.completed_levels.fill(true)
	for id in ["1-17", "1-18", "1-23", "2-28", "2-30", "2-31", "3-20", "3-21"]:
		game._start_level(index_of(id))
		check(game._touhou_difficulty_is_open() and game.mode == game.MODE_MAP, "Clicking a Touhou level must open a modal before battle")
		var menu = game.touhou_difficulty_menu
		var choices: Array = game.TouhouDifficulty.options(GameScript.Defs.LEVELS[index_of(id)])
		menu.click(menu.choice_rect(choices.size() - 1).get_center())
		menu.click(menu.start_rect().get_center())
		check(game.mode == game.MODE_SELECTION and game.current_level.touhou_difficulty == choices.back(), "Highest difficulty must enter native seed selection")
		check(game.selection_pool_cards.has("sunflower"), "Manual mode must offer sun production")
		for support in ["lily_pad", "flower_pot", "cotton_candy"]:
			if GameScript.Defs.LEVELS[index_of(id)].get("available_plants", []).has(support):
				check(game.selection_pool_cards.has(support), "Manual stages must retain access to their terrain support")
		var seeds: Array = game.selection_pool_cards.slice(0, game._required_seed_count(game.current_level))
		seeds[0] = "sunflower"
		game.selection_cards = seeds.duplicate()
		game._handle_selection_click(game._selection_start_rect().get_center())
		check(game.mode == game.MODE_BATTLE and not game._is_conveyor_level(), "Starting selected seeds must preserve the manual-mode override")
		check(game.active_cards == seeds and game.card_cooldowns.has("sunflower") and game.sun_points == 350 and game._level_has_sky_sun(), "Manual battle must have chosen seeds, costs, cooldowns and usable sun")
		var cell := Vector2i(0, 5) if id == "1-18" else Vector2i(0, 0)
		if id != "2-28":
			game._handle_primary_click(game._card_rect(0).get_center())
			game._handle_primary_click(game._cell_center(cell.x, cell.y))
			check(game.grid[cell.x][cell.y] != null and game.sun_points < 350, "%s planting must charge sun rather than consume a conveyor slot" % id)
		var events: Array = game.current_level.events.duplicate(true)
		game._restart_current_battle()
		check(game.current_level.events == events and game.active_cards == seeds and game.current_level.touhou_difficulty == choices.back(), "Restart must retain seeds/difficulty without duplicating extra waves")
		game._win_level()
		check(game.touhou_difficulty_clears.get("%s:%s" % [id, choices.back()], false), "Winning must record the exact difficulty on the original stage")
	game._start_level(index_of("3-21"))
	game.touhou_difficulty_menu.choice = "easy"
	game.touhou_difficulty_menu.click(game.touhou_difficulty_menu.start_rect().get_center())
	check(game.mode == game.MODE_BATTLE and game._is_conveyor_level(), "Easy must still enter the conveyor directly")
	game._start_level(index_of("1-1"))
	check(not game._touhou_difficulty_is_open(), "Normal PvZ levels must not show the selector")
	game._start_level(index_of("3-21"))
	var cancel := InputEventKey.new()
	cancel.pressed = true
	cancel.keycode = KEY_ESCAPE
	game._unhandled_input(cancel)
	check(not game._touhou_difficulty_is_open() and game.mode == game.MODE_MAP, "Escape must close the selector without starting battle")
	game._start_level(index_of("3-21"))
	var touch_menu = game.touhou_difficulty_menu
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = touch_menu.choice_rect(1).get_center()
	game._unhandled_input(touch)
	touch.pressed = false
	game._unhandled_input(touch)
	check(touch_menu.choice == "normal" and game._touhou_difficulty_is_open(), "Touch must select a tier without leaking into the map")
	touch_menu.choice = "lunatic"
	touch_menu.click(touch_menu.start_rect().get_center())
	game._handle_selection_click(game._selection_back_rect().get_center())
	check(game._touhou_difficulty_is_open() and touch_menu.choice == "lunatic", "Seed-selection back must return to the chosen tier")
	var merged: Dictionary = game._merge_save_data_preserving_progress({"touhou_difficulty_clears": {"3-21:hard": true}}, {"touhou_difficulty_clears": {"3-21:lunatic": true}})
	check(merged.touhou_difficulty_clears.size() == 2, "Save merging must preserve independent difficulty clears")
	game._apply_loaded_save_data({"version": 2, "touhou_difficulty_choices": {"3-21": "lunatic", "1-1": "lunatic"}, "touhou_difficulty_clears": {"3-21:lunatic": true, "3-21:invalid": true}})
	check(game.touhou_difficulty_choices == {"3-21": "lunatic"} and game.touhou_difficulty_clears == {"3-21:lunatic": true}, "Load must retain valid settings and reject unrelated/unknown entries")
	for viewport in [Vector2(1600, 900), Vector2(844, 390), Vector2(640, 360), Vector2(568, 320)]:
		game.size = viewport
		game._start_level(index_of("3-21"))
		var menu = game.touhou_difficulty_menu
		for option in range(4):
			check(menu.panel_rect().encloses(menu.choice_rect(option)), "Every difficulty hitbox must fit the viewport")
			check(menu.choice_rect(option).end.y <= menu.panel_rect().end.y - 104, "Difficulty choices must not overlap their stats")
	game.save_dirty = false
	game.free()
	print("Touhou difficulty selection, planting, retry, progress and layouts: %d failure(s)" % failures)
	quit(1 if failures else 0)
