extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const GlowLayerScript = preload("res://scripts/effect_glow_layer.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_glow_layer_loads_and_draws() or failed
	failed = not _test_game_exposes_glow_state() or failed
	failed = not _test_impact_feedback_populates_particles() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false


func _test_glow_layer_loads_and_draws() -> bool:
	var passed := true
	passed = _assert_true(GlowLayerScript != null, "effect_glow_layer.gd should load") and passed
	var layer = GlowLayerScript.new()
	passed = _assert_true(layer != null, "EffectGlowLayer should instantiate") and passed
	if layer == null:
		return false
	# _draw with no source must be safe.
	layer._draw()
	# _draw with a source that has no primitives must be safe.
	var game := GameScript.new()
	layer.source = game
	game.glow_primitives.clear()
	layer._draw()
	# With primitives present it must not error.
	game.glow_primitives.append({"type": "circle", "pos": Vector2(10.0, 10.0), "radius": 6.0, "color": Color(1.0, 1.0, 1.0, 0.5)})
	game.glow_primitives.append({"type": "line", "from": Vector2.ZERO, "to": Vector2(10.0, 0.0), "color": Color(1.0, 1.0, 1.0, 0.5), "width": 2.0})
	game.glow_draw_offset = Vector2(2.0, 3.0)
	layer._draw()
	layer.free()
	game.free()
	return passed


func _test_game_exposes_glow_state() -> bool:
	var game := GameScript.new()
	var passed := true
	passed = _assert_true("glow_primitives" in game, "game should expose glow_primitives") and passed
	passed = _assert_true("glow_layer" in game, "game should expose glow_layer") and passed
	passed = _assert_true("glow_draw_offset" in game, "game should expose glow_draw_offset") and passed
	passed = _assert_true("glow_draw_scale" in game, "game should expose glow_draw_scale") and passed
	passed = _assert_true(game.glow_primitives.is_empty(), "glow_primitives should start empty") and passed
	game.glow_primitives.append({"x": 1})
	game.glow_primitives.clear()
	passed = _assert_true(game.glow_primitives.is_empty(), "glow_primitives.clear() should empty the array") and passed
	game.free()
	return passed


func _test_impact_feedback_populates_particles() -> bool:
	var game := GameScript.new()
	# Minimal fields _emit_projectile_impact_feedback touches.
	game.vfx_particles = []
	game.effects = []
	game.rng = RandomNumberGenerator.new()
	game.screen_shake_amount = 0.0
	game._emit_projectile_impact_feedback(Vector2(100.0, 100.0), {"kind": "pea", "color": Color(0.4, 0.9, 0.3), "damage": 10.0}, {"uid": 1})
	var passed := true
	passed = _assert_true(game.vfx_particles.size() > 0, "impact feedback should spawn vfx particles") and passed
	passed = _assert_true(game.effects.size() > 0, "impact feedback should spawn a projectile_impact effect") and passed
	passed = _assert_true(String(game.effects[0].get("shape", "")) == "projectile_impact", "spawned effect should be a projectile_impact") and passed
	game.free()
	return passed
