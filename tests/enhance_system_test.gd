extends SceneTree

const GameScript = preload("res://scripts/game.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_enhance_roster_includes_every_plant() or failed
	failed = not _test_every_plant_has_an_enhance_profile_and_material() or failed
	failed = not _test_enhance_bonuses_are_distinct_by_plant_role() or failed
	failed = not _test_enhancement_consumes_matching_material() or failed
	failed = not _test_enhance_terminal_layout_uses_distinct_operator_panels() or failed
	failed = not _test_save_merge_preserves_material_inventory() or failed
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


func _test_enhance_roster_includes_every_plant() -> bool:
	var game := _make_game()
	var roster: Array = game.call("_enhance_owned_plants")
	var passed := _assert_true(roster.size() == GameScript.Defs.PLANT_ORDER.size(), "enhance roster should include every plant, including gacha and volcano plants")
	for kind_variant in GameScript.Defs.PLANT_ORDER:
		var kind := String(kind_variant)
		passed = _assert_true(roster.has(kind), "enhance roster should include %s" % kind) and passed
	_free_game(game)
	return passed


func _test_every_plant_has_an_enhance_profile_and_material() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_plant_enhance_profile"), "expected plant enhance profile helper") \
		and _assert_true(game.has_method("_enhance_material_inventory"), "expected material inventory helper")
	if not passed:
		_free_game(game)
		return false
	var material_defs: Dictionary = game.call("_enhance_material_defs")
	for kind_variant in GameScript.Defs.PLANT_ORDER:
		var kind := String(kind_variant)
		var profile: Dictionary = game.call("_plant_enhance_profile", kind)
		var material := String(profile.get("material", ""))
		var archetype := String(profile.get("archetype", ""))
		var bonus_lines = profile.get("bonus_lines", [])
		passed = _assert_true(not archetype.is_empty(), "%s should have an enhance archetype" % kind) and passed
		passed = _assert_true(material_defs.has(material), "%s should reference a valid material" % kind) and passed
		passed = _assert_true(bonus_lines is Array and not bonus_lines.is_empty(), "%s should describe its role bonuses" % kind) and passed
	_free_game(game)
	return passed


func _test_enhance_bonuses_are_distinct_by_plant_role() -> bool:
	var game := _make_game()
	if not _assert_true(game.has_method("_plant_enhance_bonus"), "expected plant enhance bonus helper"):
		_free_game(game)
		return false
	game.plant_enhance_levels = {
		"peashooter": 6,
		"sunflower": 6,
		"wallnut": 6,
	}
	var pea_bonus: Dictionary = game.call("_plant_enhance_bonus", "peashooter")
	var sun_bonus: Dictionary = game.call("_plant_enhance_bonus", "sunflower")
	var nut_bonus: Dictionary = game.call("_plant_enhance_bonus", "wallnut")
	var passed := _assert_true(float(pea_bonus.get("damage_mult", 1.0)) > float(sun_bonus.get("damage_mult", 1.0)), "attacker enhancement should emphasize damage more than economy plants") \
		and _assert_true(float(sun_bonus.get("interval_mult", 1.0)) < float(pea_bonus.get("interval_mult", 1.0)), "producer enhancement should speed up sun production more than attacker cadence") \
		and _assert_true(float(nut_bonus.get("health_mult", 1.0)) > float(pea_bonus.get("health_mult", 1.0)), "defender enhancement should emphasize durability")
	_free_game(game)
	return passed


func _test_enhancement_consumes_matching_material() -> bool:
	var game := _make_game()
	if not _assert_true(game.has_method("_plant_enhance_profile"), "expected profile helper before consuming materials"):
		_free_game(game)
		return false
	var profile: Dictionary = game.call("_plant_enhance_profile", "peashooter")
	var material := String(profile.get("material", ""))
	game.coins_total = 99999
	game.enhance_stones = 0
	game.enhance_materials = {material: 2}
	game.call("_try_enhance_plant", "peashooter")
	var passed := _assert_true(int(game.plant_enhance_levels.get("peashooter", 0)) == 1, "peashooter should enhance when its role material is available") \
		and _assert_true(int(game.enhance_materials.get(material, 0)) == 1, "enhancing should consume the matching role material")
	_free_game(game)
	return passed


func _test_enhance_terminal_layout_uses_distinct_operator_panels() -> bool:
	var game := _make_game()
	var passed := _assert_true(game.has_method("_enhance_portrait_rect"), "enhance UI should expose a central operator portrait panel") \
		and _assert_true(game.has_method("_enhance_detail_rect"), "enhance UI should expose a right-side detail panel") \
		and _assert_true(game.has_method("_enhance_material_strip_rect"), "enhance UI should expose a material inventory strip")
	if passed:
		var viewport_rect := Rect2(Vector2.ZERO, GameScript.BASE_VIEWPORT_SIZE)
		var roster_rect: Rect2 = game.call("_enhance_roster_panel_rect")
		var portrait_rect: Rect2 = game.call("_enhance_portrait_rect")
		var detail_rect: Rect2 = game.call("_enhance_detail_rect")
		var material_rect: Rect2 = game.call("_enhance_material_strip_rect")
		passed = _assert_true(viewport_rect.encloses(roster_rect), "enhance roster panel should stay inside the base viewport") and passed
		passed = _assert_true(viewport_rect.encloses(portrait_rect), "enhance portrait panel should stay inside the base viewport") and passed
		passed = _assert_true(viewport_rect.encloses(detail_rect), "enhance detail panel should stay inside the base viewport") and passed
		passed = _assert_true(viewport_rect.encloses(material_rect), "enhance material strip should stay inside the base viewport") and passed
		passed = _assert_true(not roster_rect.intersects(portrait_rect), "enhance roster and portrait panels should be distinct columns") and passed
		passed = _assert_true(not portrait_rect.intersects(detail_rect), "enhance portrait and detail panels should be distinct columns") and passed
		passed = _assert_true(material_rect.position.y > portrait_rect.position.y, "enhance material inventory should read as a lower terminal strip") and passed
	_free_game(game)
	return passed


func _test_save_merge_preserves_material_inventory() -> bool:
	var game := _make_game()
	var existing_save = {
		"plant_enhance_levels": {"sunflower": 2},
		"enhance_stones": 1,
		"enhance_materials": {"growth_core": 3, "guard_plate": 1},
	}
	var candidate_save = {
		"plant_enhance_levels": {"sunflower": 1},
		"enhance_stones": 4,
		"enhance_materials": {"growth_core": 1, "assault_chip": 2},
	}
	var merged: Dictionary = game.call("_merge_enhance_progress", existing_save, candidate_save)
	var materials: Dictionary = merged.get("enhance_materials", {})
	var passed := _assert_true(int(materials.get("growth_core", 0)) == 3, "save merge should preserve stronger material counts") \
		and _assert_true(int(materials.get("guard_plate", 0)) == 1, "save merge should keep material entries missing from the candidate") \
		and _assert_true(int(materials.get("assault_chip", 0)) == 2, "save merge should include newer material entries")
	_free_game(game)
	return passed
