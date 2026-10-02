extends "res://tests/world_navigation_test.gd"

class PointerGame extends GameScript:
	var pointer := Vector2(-9999, -9999)
	func _pointer_local_position() -> Vector2:
		return pointer


func _run() -> void:
	var passed := true
	var game := PointerGame.new()
	game.size = Vector2(1600, 900)
	# Exercise the real popup builder; script exceptions can otherwise abort it
	# while a SceneTree test still exits successfully.
	game._build_font()
	game._build_overlay_ui()
	passed = _assert_true(game.action_button.is_connected("pressed", game._on_message_button_pressed) and game.action_button.get_parent() != null, "The result popup must finish building its working action button") and passed
	for style in ["normal", "hover", "pressed", "focus"]:
		passed = _assert_true(game.action_button.get_theme_stylebox(style) is StyleBoxTexture, "Result buttons must use valid illustrated styles: " + style) and passed
	game.mode = game.MODE_HOME
	var ui = game.storybook_ui
	ui.update(game, 0.01)
	var rect: Rect2 = game._home_action_rects().daily
	game.pointer = rect.get_center()
	for i in range(45):
		game.ui_time += 1.0 / 60.0
		ui.state(game, rect, "target")
		ui.update(game, 1.0 / 60.0)
	var state: Dictionary = ui.state(game, rect, "target")
	passed = _assert_true(float(state.hover) > 0.97, "Hover must smoothly reach its visible state") and passed
	var hovered: Rect2 = ui.surface(game, rect, "target")
	passed = _assert_true(hovered.position.y < rect.position.y and hovered.size == rect.size, "Animated cards must lift without changing touch geometry") and passed
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	ui.record_input(game, press, rect.get_center())
	ui.update(game, 0.08)
	passed = _assert_true(float(state.press) > 0.99, "Mouse press must have visible feedback") and passed
	press.pressed = false
	ui.record_input(game, press, rect.get_center())
	ui.update(game, 0.1)
	passed = _assert_true(is_zero_approx(float(state.press)), "Press feedback must clear on release") and passed
	var disabled: Dictionary = ui.state(game, rect, "disabled", true)
	ui.update(game, 0.1)
	passed = _assert_true(is_zero_approx(float(disabled.hover)), "Locked actions must not animate as available") and passed
	game.pointer = Vector2(-9999, -9999)
	ui.update(game, 30.0)
	passed = _assert_true(is_finite(float(state.hover)) and absf(float(state.hover)) < 1.1, "Resume after a long frame must not explode the animation") and passed
	for i in range(100):
		ui.click(rect.get_center())
	passed = _assert_true(ui.particles.size() <= 80, "Rapid tapping must keep a bounded particle budget") and passed
	ui.update(game, 0.7)
	passed = _assert_true(ui.particles.is_empty(), "Click particles must expire") and passed
	var coins: int = game.coins_total
	var time: float = game.level_time
	var zombies: Array = game.zombies.duplicate(true)
	game.mode = game.MODE_BATTLE
	game.battle_paused = true
	ui.update(game, 0.1)
	passed = _assert_true(ui.motions.is_empty() and not ui.pointer_down, "Page changes must clear old hover/press targets") and passed
	passed = _assert_true(game.coins_total == coins and game.level_time == time and game.zombies == zombies, "Presentation must not alter currency or battle state") and passed
	game.mode = game.MODE_WORLD_SELECT
	game.world_select_index = 1
	ui.update(game, 0.1)
	game.world_select_index = 2
	ui.update(game, 0.01)
	passed = _assert_true(ui.previous_preview == 1 and ui.preview_index == 2 and ui.preview_age < 0.1, "World preview changes must start a crossfade") and passed
	for key in ["courtyard", "parchment", "wood_plaque", "lantern", "title_logo"]:
		var asset: Texture2D = ui.texture(key)
		passed = _assert_true(asset != null and asset.get_size().x > 500, "Shipped illustration must load: " + key) and passed
		if key != "courtyard":
			passed = _assert_true(asset.get_image().detect_alpha() != Image.ALPHA_NONE, "Cutout must retain genuine transparency: " + key) and passed
	_free_game(game)
	print("Storybook UI hover/press, disabled actions, time-step stability, particle budget, isolation and assets: %s" % ("PASS" if passed else "FAIL"))
	quit(0 if passed else 1)
