extends "res://tests/ancient_world_test.gd"


func _run() -> void:
	for viewport in [Vector2(1600, 900), Vector2(1365, 768), Vector2(844, 390)]:
		var g = make_game()
		g.size = viewport
		g.mobile_runtime_override = 1 if viewport.y < 500.0 else 0
		g._refresh_battle_layout()
		var control_bottom = maxf(g.SEED_BANK_RECT.end.y, g.PAUSE_BUTTON_RECT.end.y)
		var building_gap = g.BOARD_ORIGIN.y - control_bottom
		check(building_gap >= (24.0 if viewport.y < 500.0 else 90.0), "Ancient architecture has a visible band below HUD at %s" % viewport)
		check(g.CELL_SIZE.y >= 32.0, "Ancient planting cells stay tappable on short screens")
		check(g.BOARD_ORIGIN.x + g.board_size.x <= viewport.x and g.BOARD_ORIGIN.y + g.board_size.y <= viewport.y - 32.0, "Ancient board fits within the viewport")
		for row in range(5):
			for col in range(9):
				var center: Vector2 = g._cell_center(row, col)
				check(g._mouse_to_cell(center) == Vector2i(row, col), "Stone slabs share real planting hit coordinates")
		g.grid[2][3] = g._create_plant("peashooter", 2, 3)
		g.size = viewport + Vector2(24, 12)
		g._refresh_battle_layout()
		check(g.grid[2][3] != null and String(g.grid[2][3].kind) == "peashooter", "Resizing the stone board preserves planted units")
		g.current_level = {"id": "1-1", "terrain": "day", "events": []}
		g._refresh_battle_layout()
		check(g.BOARD_ORIGIN.y < control_bottom + building_gap, "Ancient scenery spacing stays scoped to the eighth world")
		dispose(g)
	print("Ancient courtyard layout: %d failures" % failures)
	quit(1 if failures else 0)
