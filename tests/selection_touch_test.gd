extends SceneTree

# Verifies that long-pressing a selection pool card is NOT mis-detected as a
# scroll drag: a small or diagonal move keeps it a tap (selectable), while a
# clearly vertical large move still scrolls the pool.

const GameScript = preload("res://scripts/game.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failed := false
	failed = not _test_small_move_on_card_stays_tap() or failed
	failed = not _test_diagonal_move_on_card_stays_tap() or failed
	failed = not _test_large_vertical_move_on_card_scrolls() or failed
	failed = not _test_empty_area_scrolls_at_small_threshold() or failed
	quit(1 if failed else 0)

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false

func _make_selection_game() -> Control:
	var game = GameScript.new()
	game.mode = "selection"
	game.current_level = {"id": "1-1", "terrain": "day", "available_plants": ["peashooter", "sunflower", "wallnut", "snow_pea", "repeater", "chomper", "potato_mine", "cherry_bomb"], "events": []}
	game.selection_pool_cards = ["peashooter", "sunflower", "wallnut", "snow_pea", "repeater", "chomper", "potato_mine", "cherry_bomb"]
	game.selection_cards = []
	game.selection_pool_scroll = 0.0
	return game

func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e = InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressed
	return e

func _drag(pos: Vector2, relative: Vector2) -> InputEventScreenDrag:
	var e = InputEventScreenDrag.new()
	e.index = 0
	e.position = pos
	e.relative = relative
	e.velocity = Vector2.ZERO
	return e

# Find a point that lands on a pool card.
func _card_point(game: Control) -> Vector2:
	var idx_rect = game._selection_pool_rect(0)
	return idx_rect.get_center()

func _test_small_move_on_card_stays_tap() -> bool:
	var game = _make_selection_game()
	var start = _card_point(game)
	# Confirm the press target is actually a card.
	var target = game._selection_touch_target(start)
	var passed := _assert_true(String(target.get("id", "")).begins_with("selection_pool_card_"), "test setup: start point should be on a pool card, got '%s'" % String(target.get("id", "")))
	if not passed:
		game.free()
		return false
	game._begin_touch_navigation(_touch(start, true))
	# Small move (~20px) — below the 48px card threshold.
	game._handle_touch_navigation_drag(_drag(start + Vector2(6.0, 20.0), Vector2(6.0, 20.0)))
	passed = _assert_true(not game.touch_navigation_dragging, "small move on a card should NOT start a drag (stays a tap)") and passed
	game.free()
	return passed

func _test_diagonal_move_on_card_stays_tap() -> bool:
	var game = _make_selection_game()
	var start = _card_point(game)
	game._begin_touch_navigation(_touch(start, true))
	# Large but diagonal move (y not clearly > x) — should not scroll.
	game._handle_touch_navigation_drag(_drag(start + Vector2(50.0, 52.0), Vector2(50.0, 52.0)))
	var passed := _assert_true(not game.touch_navigation_dragging, "diagonal move on a card should NOT start a scroll (y must dominate x by 1.5x)")
	game.free()
	return passed

func _test_large_vertical_move_on_card_scrolls() -> bool:
	var game = _make_selection_game()
	var start = _card_point(game)
	game._begin_touch_navigation(_touch(start, true))
	# Large clearly-vertical move (y > 1.5x and > 48px) — should scroll.
	game._handle_touch_navigation_drag(_drag(start + Vector2(8.0, 70.0), Vector2(8.0, 70.0)))
	var passed := _assert_true(game.touch_navigation_dragging, "large vertical move on a card SHOULD start a scroll drag")
	game.free()
	return passed

func _test_empty_area_scrolls_at_small_threshold() -> bool:
	var game = _make_selection_game()
	# Press on the pool view but not on a card (use the track/view area).
	var view = game._selection_pool_view_rect()
	# A point near the bottom edge inside the view, unlikely to be a card center.
	var start = Vector2(view.position.x + view.size.x - 4.0, view.position.y + view.size.y - 4.0)
	var target = game._selection_touch_target(start)
	var tid = String(target.get("id", ""))
	# Only meaningful if this is a non-card draggable area; if it resolved to a card, skip gracefully.
	if tid.begins_with("selection_pool_card_") or not game._selection_touch_target_allows_drag(tid):
		game.free()
		return true
	game._begin_touch_navigation(_touch(start, true))
	# Vertical move (~40px) — above the 34px priority-click guard for non-card
	# draggable areas (which keep the smaller threshold, unlike the 48px cards).
	game._handle_touch_navigation_drag(_drag(start + Vector2(2.0, 40.0), Vector2(2.0, 40.0)))
	var passed := _assert_true(game.touch_navigation_dragging, "empty pool area should scroll above the standard click guard")
	game.free()
	return passed
