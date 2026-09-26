extends SceneTree

# Headless regression for the v1.0.124 UI surface pass: one shared palette, a panel highlight that
# obeys its accent_alpha, and health bars that never spill past their own track.

const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const CombatDetails = preload("res://scripts/ui/combat_details.gd")

const COMBAT_DETAILS_PATH := "res://scripts/ui/combat_details.gd"
const GAME_PATH := "res://scripts/game.gd"

# The literals the v1.0.124 pass replaced with named GameTheme palette entries.
const LEGACY_PALETTE_LITERALS := [
	'"#283d37"', '"#e4efd5"', '"#b58b32"', '"#68532b"', '"#203c37"',
	"Color(0.38, 0.72, 0.96)", "Color(0.62, 0.8, 0.96)", "Color(0.32, 0.86, 0.24)",
	"Color(0.24, 0.82, 0.28)", "Color(0.92, 0.28, 0.22)",
]

const PALETTE_NAMES := [
	"INK", "ARMOR_BLUE", "SHIELD_BLUE", "HEALTH_GREEN", "PLANT_GREEN",
	"ZOMBIE_RED", "GOLD", "COST_GOLD", "BAR_TRACK", "PANEL_CREAM", "BAR_LOW_RIM",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	failed = not _test_palette_is_shared_and_opaque() or failed
	failed = not _test_panel_highlight_respects_accent() or failed
	failed = not _test_health_bar_geometry_stays_inside_track() or failed
	failed = not _test_combat_details_reuse_the_palette() or failed
	quit(1 if failed else 0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false



func _get_constant(name: String):
	var constants: Dictionary = load("res://scripts/ui/game_theme.gd").get_script_constant_map()
	if constants.has(name):
		return constants[name]
	return null


func _theme_script() -> Script:
	return load("res://scripts/ui/game_theme.gd")


func _theme_has_method(method_name: String) -> bool:
	return _script_has_method("res://scripts/ui/game_theme.gd", method_name)


func _script_has_method(path: String, method_name: String) -> bool:
	var script = load(path)
	if script == null:
		return false
	for method_data in script.get_script_method_list():
		if String(method_data.get("name", "")) == method_name:
			return true
	return false


func _test_palette_is_shared_and_opaque() -> bool:
	var passed := true
	for name in PALETTE_NAMES:
		passed = _assert_true(_get_constant(name) is Color, "palette is missing %s" % name) and passed
	for name in PALETTE_NAMES:
		var value: Color = _get_constant(name)
		passed = _assert_true(is_equal_approx(value.a, 1.0), "%s must be fully opaque so callers control alpha" % name) and passed
	return passed


func _test_panel_highlight_respects_accent() -> bool:
	var passed := true
	passed = _assert_true(_theme_has_method("draw_panel_highlight"), "panels need a shared top highlight") and passed
	# The highlight is pure geometry: segments must stay inside the panel, be brightest in the
	# middle, fade at both ends and never exceed the requested accent.
	var panel := Rect2(40, 30, 240, 90)
	for accent in [0.06, 0.14, 0.2]:
		var bands := _highlight_bands(panel, 10.0, accent)
		if not _assert_true(not bands.is_empty(), "a normal panel must draw a highlight at accent %s" % accent):
			passed = false
			continue
		var strip: Rect2 = bands[0]["rect"]
		passed = _assert_true(panel.encloses(strip), "the highlight must stay inside the panel") and passed
		passed = _assert_true(strip.position.y >= panel.position.y and strip.position.y <= panel.position.y + 1.0, "highlight must hug the top edge") and passed
		# Fade shape: transparent at both outer ends, full accent across the middle, never brighter.
		passed = _assert_true(is_zero_approx(float(bands[0]["left_alpha"])), "highlight must start transparent") and passed
		passed = _assert_true(is_zero_approx(float(bands[-1]["right_alpha"])) or float(bands[-1]["right_alpha"]) < 1.0, "highlight must end transparent") and passed
		var peak := 0.0
		for band in bands:
			peak = maxf(peak, maxf(float(band["left_alpha"]), float(band["right_alpha"])))
			passed = _assert_true(panel.encloses(Rect2(band["rect"])), "every highlight band must stay inside the panel") and passed
		# The hairline may exceed the accent (it is the glossy edge), but nothing may exceed full alpha.
		passed = _assert_true(peak <= 1.0 + 0.0001, "highlight alpha must never exceed 1") and passed
		passed = _assert_true(peak >= accent * 0.25, "highlight must be clearly visible at accent %s" % accent) and passed
		passed = _assert_true(float(bands[1]["left_alpha"]) >= accent * 0.25, "the middle of the sweep must carry the accent") and passed
	# A zero accent must not draw at all, and neither may a panel too small to hold the strip.
	passed = _assert_true(_highlight_bands(panel, 10.0, 0.0).is_empty(), "accent_alpha 0 must stay flat") and passed
	passed = _assert_true(_highlight_bands(Rect2(0, 0, 6, 6), 10.0, 0.2).is_empty(), "panels smaller than the strip must be skipped") and passed
	# The gloss must be stronger on a dark HUD chip than on a pale garden panel, and the body strip
	# must not exceed the caller's accent on either.
	var dark_gloss: float = float(_theme_script().call("panel_gloss_alpha", 0.05))
	var light_gloss: float = float(_theme_script().call("panel_gloss_alpha", 0.9))
	passed = _assert_true(dark_gloss > light_gloss, "a dark panel must show a stronger gloss than a pale one") and passed
	passed = _assert_true(light_gloss > 0.0 and dark_gloss <= 1.0, "gloss must stay within a visible, legal range") and passed
	passed = _assert_true(float(_theme_script().call("panel_highlight_share", 0.05)) > float(_theme_script().call("panel_highlight_share", 0.9)), "the body strip must fade more on pale fills") and passed
	passed = _assert_true(float(_theme_script().call("panel_highlight_share", 0.5)) <= 1.0, "the body strip must never exceed the caller accent") and passed
	# Wider panels must not push the sweep past the corner inset on either side.
	var wide := Rect2(0, 0, 1600, 900)
	var wide_bands := _highlight_bands(wide, 10.0, 0.16)
	passed = _assert_true(wide.encloses(Rect2(wide_bands[0]["rect"])) and wide.encloses(Rect2(wide_bands[-1]["rect"])), "wide panels must keep the sweep inside their bounds") and passed
	passed = _assert_true(Rect2(wide_bands[0]["rect"]).position.x >= wide.position.x + 1.0, "the sweep must respect the corner inset") and passed
	return passed


# Mirrors draw_panel_highlight's geometry so the numbers can be asserted without a live canvas.
# Returns the three fade bands plus the hairline, each as {rect, left_alpha, right_alpha}. The gloss
# values come from the shared helpers, so the renderer and this test cannot drift apart.
func _highlight_bands(rect: Rect2, corner_radius: float, accent_alpha: float, fill_luminance: float = 0.5) -> Array:
	if accent_alpha <= 0.0 or rect.size.y < 12.0 or rect.size.x < 12.0:
		return []
	accent_alpha *= float(_theme_script().call("panel_highlight_share", fill_luminance))
	var inset := maxf(1.5, corner_radius * 0.45)
	var strip_height := clampf(rect.size.y * 0.16, 2.0, 3.5)
	var strip_start := rect.position.x + inset
	var strip_width := rect.size.x - inset * 2.0
	if strip_width <= 0.0 or strip_height <= 0.0:
		return []
	var top := rect.position.y + 0.5
	var third := strip_width / 3.0
	var cuts := [strip_start, strip_start + third, strip_start + third * 2.0, strip_start + strip_width]
	var alphas := [0.0, accent_alpha, accent_alpha, 0.0]
	var result: Array = []
	for i in range(3):
		result.append({
			"rect": Rect2(Vector2(cuts[i], top), Vector2(cuts[i + 1] - cuts[i], strip_height)),
			"left_alpha": alphas[i],
			"right_alpha": alphas[i + 1],
		})
	var hairline := float(_theme_script().call("panel_gloss_alpha", fill_luminance))
	result.append({
		"rect": Rect2(Vector2(cuts[1], top), Vector2(cuts[2] - cuts[1], 1.0)),
		"left_alpha": hairline,
		"right_alpha": hairline,
	})
	return result


func _test_health_bar_geometry_stays_inside_track() -> bool:
	# The bar helper is pure geometry: fill must sit inside the inset track for every ratio.
	var passed := true
	for width in [58.0, 48.0, 44.0, 36.0]:
		for ratio in [0.0, 0.05, 0.2, 0.5, 0.99, 1.0, 1.4, -0.3]:
			var height := clampf(width * 6.0 / 58.0, 2.5, 6.0)
			var border := 1.0 if height >= 4.0 else 0.0
			var bar := Rect2(Vector2(-width * 0.5, 0.0), Vector2(width, height))
			var inner := bar.grow(-border) if border > 0.0 else bar
			var fill := ThemeLib.progress_fill_rect(inner, ratio)
			passed = _assert_true(inner.encloses(fill) or is_equal_approx(fill.size.x, inner.size.x), "fill must not exceed the track at width %s ratio %s" % [width, ratio]) and passed
			passed = _assert_true(fill.size.x >= 0.0, "fill width must never go negative") and passed
			passed = _assert_true(is_zero_approx(fill.position.x - inner.position.x), "fill must start at the track origin") and passed
	return passed


func _test_combat_details_reuse_the_palette() -> bool:
	var passed := true
	# The combat palette moved into GameTheme, so the unit renderers must not still carry the old
	# literals. Checked across both files that draw units.
	for entry in [[COMBAT_DETAILS_PATH, "combat details"], [GAME_PATH, "the game renderer"]]:
		var source := FileAccess.get_file_as_string(String(entry[0]))
		if not _assert_true(not source.is_empty(), "%s must be readable" % entry[1]):
			passed = false
			continue
		for literal in LEGACY_PALETTE_LITERALS:
			passed = _assert_true(not source.contains(literal), "%s must take %s from the shared palette" % [entry[1], literal]) and passed
	var details := FileAccess.get_file_as_string(COMBAT_DETAILS_PATH)
	passed = _assert_true(details.contains("GameTheme.INK"), "combat details must outline with the shared ink") and passed
	passed = _assert_true(_script_has_method(COMBAT_DETAILS_PATH, "impact_style"), "impact classification must stay available") and passed
	# Elemental classification must still read the same projectile/target contract.
	passed = _assert_true(String(CombatDetails.impact_style({"fire": true}, {})) == "fire", "fire projectiles must classify as fire") and passed
	passed = _assert_true(String(CombatDetails.impact_style({"slow_duration": 2.0}, {})) == "ice", "slowing projectiles must classify as ice") and passed
	passed = _assert_true(String(CombatDetails.impact_style({}, {"shield_health": 100.0})) == "armor", "shielded targets must classify as armor") and passed
	return passed
