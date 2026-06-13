extends Control
class_name EffectGlowLayer

# Additive-blend overlay drawn on top of the battle scene. The game node pushes
# glow primitives (game.glow_primitives) during its own _draw and records the
# active battle transform (game.glow_draw_offset / game.glow_draw_scale) so the
# bloom lines up with the (possibly screen-shaken) gameplay underneath. ADD
# blending makes overlapping bright shapes bloom instead of darken.
var source: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _draw() -> void:
	if source == null:
		return
	var primitives: Array = source.glow_primitives
	if primitives == null or primitives.is_empty():
		return
	draw_set_transform(source.glow_draw_offset, 0.0, source.glow_draw_scale)
	for g in primitives:
		var t := String(g.get("type", "circle"))
		var pos := Vector2(g.get("pos", Vector2.ZERO))
		var color := Color(g.get("color", Color(1.0, 1.0, 1.0, 0.4)))
		if t == "line":
			var from_v := Vector2(g.get("from", pos))
			var to_v := Vector2(g.get("to", pos))
			draw_line(from_v, to_v, color, maxf(0.6, float(g.get("width", 2.0))))
		else:
			var radius := float(g.get("radius", 6.0))
			if radius < 0.5:
				continue
			draw_circle(pos, radius, color)
			if radius > 1.5:
				draw_circle(pos, radius * 0.5, Color(min(1.0, color.r + 0.15), min(1.0, color.g + 0.15), min(1.0, color.b + 0.15), min(1.0, color.a * 1.7)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
