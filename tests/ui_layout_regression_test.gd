extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const Defs = preload("res://scripts/game_defs.gd")
var failures := 0

class InsetGame extends GameScript:
	var inset := 0.0
	func _viewport_safe_rect() -> Rect2:
		return Rect2(Vector2(0, inset), size - Vector2(0, inset))


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	for viewport in [Vector2(844, 330), Vector2(844, 390), Vector2(1000, 450), Vector2(1600, 900), Vector2(1280, 720)]:
		var game := InsetGame.new()
		game.size = viewport
		game.mobile_runtime_override = 1 if viewport.y <= 450 else 0
		game.mode = game.MODE_SELECTION
		game.current_level = Defs.LEVELS[0]
		game.selection_pool_cards = Defs.PLANTS.keys()
		var panel: Rect2 = game._selection_selected_panel_rect()
		for i in range(10):
			check(panel.encloses(game._selection_slot_rect(i)), "Selection slot %d must fit at %s" % [i, viewport])
		check(game._selection_pool_view_rect().encloses(game._selection_pool_rect(0)), "At least one full plant row must fit at %s" % viewport)
		check(not panel.intersects(game._selection_zombie_panel_rect()), "Selected cards must not overlap enemies")
		var view: Rect2 = game._selection_pool_view_rect()
		check(not view.intersects(game._selection_footer_rect()), "Plant pool must stay above action buttons at %s" % viewport)
		check(game._viewport_safe_rect().encloses(game._selection_pool_panel_rect()), "Plant pool must fit the safe viewport at %s" % viewport)
		for scroll in [0.0, 23.0, 99.0, 183.0, game._selection_pool_max_scroll()]:
			game.selection_pool_scroll = scroll
			var visible_count := 0
			for index in range(game.selection_pool_cards.size()):
				var card: Rect2 = game._selection_pool_rect(index)
				if view.encloses(card):
					visible_count += 1
					check(game._selection_pool_index_at(card.get_center()) == index, "Scrolled cards must match their hit targets")
			check(visible_count > 0, "Compact scrolling must always show selectable cards")
		game.free()
	for viewport in [Vector2(844, 390), Vector2(1000, 450), Vector2(1280, 720), Vector2(1600, 900)]:
		for row_count in [5, 6]:
			var battle := InsetGame.new()
			battle.size = viewport
			battle.mobile_runtime_override = 1 if viewport.y <= 450 else 0
			battle.mode = battle.MODE_BATTLE
			battle.board_rows = row_count
			battle.active_cards = Defs.PLANTS.keys().slice(0, 10)
			battle._refresh_battle_layout()
			var safe: Rect2 = battle._viewport_safe_rect()
			check(safe.encloses(Rect2(battle.BOARD_ORIGIN, battle.board_size)), "All %d battle rows must fit at %s" % [row_count, viewport])
			if viewport.y <= 450:
				check(battle.board_size.y >= viewport.y * 0.5, "Small landscape boards must retain at least half the viewport for gameplay")
			for index in range(10):
				check(battle.SEED_BANK_RECT.encloses(battle._card_rect(index)), "Every battle card must stay inside the seed bank")
			check(battle.SEED_BANK_RECT.encloses(battle._shovel_rect()), "Shovel must remain inside the seed bank")
			var controls := [battle.SEED_BANK_RECT, battle.PLANT_FOOD_RECT, battle.WAVE_BAR_RECT, battle.COIN_METER_RECT, battle.PAUSE_BUTTON_RECT, battle.BACK_BUTTON_RECT]
			for i in range(controls.size()):
				check(safe.encloses(controls[i]), "Battle controls must fit the viewport")
				for j in range(i + 1, controls.size()):
					check(not Rect2(controls[i]).intersects(controls[j]), "Battle controls must not overlap at %s" % viewport)
			var pause_rect: Rect2 = battle._battle_pause_menu_rect()
			check(safe.encloses(pause_rect), "Pause panel must fit small screens")
			for action in ["resume", "restart", "almanac", "map"]:
				check(pause_rect.encloses(battle._battle_pause_button_rect(action)), "Pause actions must fit the panel")
			for index in range(3):
				check(safe.encloses(battle._endless_bonus_card_rect(index)), "All three endless bonuses must be selectable")
			battle.free()
	var game := GameScript.new()
	game._build_font()
	game.mobile_runtime_override = 1
	game.size = Vector2(390, 844)
	game.mode = game.MODE_BATTLE
	game.level_time = 12
	check(game._should_show_mobile_rotate_prompt(), "Portrait battle must show a readable rotation prompt")
	game._process(1.0)
	check(game.level_time == 12, "Battle must stop advancing while portrait UI is hidden")
	game.mobile_runtime_override = 0
	check(game._map_mode_title_for_world("volcano") != game._map_mode_title_for_world("day"), "Volcano map needs its own world title")
	var map_controls := [game.MAP_COIN_RECT, game.MAP_WORLD_BACK_RECT, game.MAP_ALMANAC_BUTTON_RECT, game.MAP_SCROLL_LEFT_RECT, game.MAP_SCROLL_RIGHT_RECT]
	for i in range(map_controls.size()):
		check(Rect2(Vector2.ZERO, game.BASE_VIEWPORT_SIZE).encloses(map_controls[i]), "Map controls must remain on screen")
		for j in range(i + 1, map_controls.size()):
			check(not Rect2(map_controls[i]).intersects(map_controls[j]), "Map navigation and resource controls must not overlap")
	game.current_world_key = "volcano"
	for index in game._visible_level_indices():
		var node: Vector2 = game._map_node_position(index)
		if not game._map_node_visible(node):
			check(game._level_node_at(node) == -1, "Hidden map nodes must not receive clicks")
	if game.has_method("_menu_icon_transform"):
		game.menu_draw_transform = Transform2D(0.0, Vector2(0.5, 0.5), 0.0, Vector2(100, 20))
		var icon: Transform2D = game._menu_icon_transform(Vector2(200, 300), 0.72)
		check((icon * Vector2.ZERO).is_equal_approx(Vector2(200, 170)), "Icon must inherit the scaled menu origin")
		check(icon.x.is_equal_approx(Vector2(0.36, 0)), "Icon must inherit menu scale")
	else:
		check(false, "Menu icon transform helper is required")
	var theme = load("res://scripts/ui/game_theme.gd")
	var has_fit := false
	for method in theme.get_script_method_list():
		has_fit = has_fit or String(method.name) == "fit_label"
	if has_fit:
		for kind in Defs.ZOMBIES:
			var label: Dictionary = theme.call("fit_label", game.ui_font, Defs.ZOMBIES[kind].name, Vector2(64, 24), 15, 10)
			check(Vector2(label.size).x <= 64.01 and Vector2(label.size).y <= 24.01, "Zombie name must fit: %s" % kind)
		var number: Dictionary = theme.call("fit_label", game.ui_font, "987654321012345", Vector2(100, 24), 22, 12)
		check(Vector2(number.size).x <= 100.01, "Long resource values must stay in their own column")
	else:
		check(false, "Measured label fitting is required")
	var track := Rect2(0, 0, 8, 24)
	check(track.encloses(ThemeLib.scroll_knob_rect(track, 50, 500, 450)), "Short scroll tracks must contain their knob")
	game.free()
	print("UI layout regression: %d failure(s)" % failures)
	quit(1 if failures else 0)
