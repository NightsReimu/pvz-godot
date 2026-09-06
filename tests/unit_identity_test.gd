extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
var failures := 0

class StateProbe extends GameScript:
	var trace: Array = []

	func _draw_threepeater(center: Vector2, scale: float, flash: float, alpha: float = 1.0) -> void:
		trace.append(["threepeater", center, scale, flash, alpha])

	func _draw_wallnut(center: Vector2, scale: float, flash: float, ratio: float, alpha: float = 1.0) -> void:
		trace.append(["wallnut", center, scale, ratio, alpha])

	func _draw_pumpkin(center: Vector2, scale: float, flash: float, ratio: float, alpha: float = 1.0) -> void:
		trace.append(["pumpkin", center, scale, ratio, alpha])

	func _draw_potato_mine(center: Vector2, scale: float, armed: bool, ratio: float, alpha: float = 1.0) -> void:
		trace.append(["potato_mine", center, scale, armed, ratio, alpha])

	func _draw_chomper(center: Vector2, scale: float, chew: float, alpha: float = 1.0) -> void:
		trace.append(["chomper", center, scale, chew, alpha])

	func _draw_sun_shroom(center: Vector2, scale: float, flash: float, mature: bool, alpha: float = 1.0) -> void:
		trace.append(["sun_shroom", center, scale, mature, alpha])

	func _draw_scaredy_shroom(center: Vector2, scale: float, flash: float, hiding: bool, alpha: float = 1.0) -> void:
		trace.append(["scaredy_shroom", center, scale, hiding, alpha])

	func _draw_snow_bloom(center: Vector2, scale: float, flash: float, wilt: float, alpha: float = 1.0) -> void:
		trace.append(["snow_bloom", center, scale, wilt, alpha])


class DrawingProbe extends GameScript:
	var drew := false
	var plant_count := 0
	var zombie_count := 0
	var textures_used: Dictionary = {}
	var current_kind := ""
	var wrong_texture := false
	var missing_texture := false

	func _ready() -> void:
		_build_font()
		set_process(false)
		set_process_unhandled_input(false)

	func _save_game() -> void:
		pass

	func _try_get_boss_frame_texture(kind: String, frame: int) -> Texture2D:
		var texture := super._try_get_boss_frame_texture(kind, frame)
		wrong_texture = wrong_texture or kind != current_kind
		missing_texture = missing_texture or texture == null
		textures_used[kind] = texture != null
		return texture

	func _draw() -> void:
		if drew:
			return
		for kind in Defs.PLANTS:
			_draw_card_icon(kind, Vector2(200, 180), 0.6)
			_draw_plant_preview(kind, Vector2(200, 180))
			plant_count += 1
		for kind in Defs.ZOMBIES:
			current_kind = kind
			_draw_zombie_icon(kind, Vector2(400, 300), 0.6)
			zombie_count += 1
		drew = true


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var probe := StateProbe.new()
	probe.current_level = {"terrain": "day"}
	var center := Vector2(130, 220)
	probe._draw_card_icon("threepeater", center, 0.5)
	check(probe.trace.size() == 1 and probe.trace[0][0] == "threepeater", "The card must draw the actual three-headed species")
	check(is_equal_approx(float(probe.trace[0][2]), 0.29), "Compact cards must scale their own renderer")
	probe._draw_plant_preview("threepeater", center)
	check(probe.trace.back()[1] == center and is_equal_approx(probe.trace.back()[4], 0.42), "Placement preview must retain its species and transparency")
	probe.CELL_SIZE = probe.BASE_CELL_SIZE * 0.4
	probe._draw_plant_preview("threepeater", center)
	check(is_equal_approx(probe.trace.back()[2], 0.4), "Placement preview must fit the same mobile cell scale as the planted unit")
	probe._draw_plant_body("wallnut", center, 1.0, 0.0, 1.0, {"health": 20.0, "max_health": 100.0})
	check(is_equal_approx(probe.trace.back()[3], 0.2), "Damaged walnuts must show the cracked body")
	probe._draw_plant_body("pumpkin", center, 1.0, 0.0, 0.42, {"armor_health": 25.0, "max_armor_health": 100.0})
	check(is_equal_approx(probe.trace.back()[3], 0.25) and is_equal_approx(probe.trace.back()[4], 0.42), "Pumpkin must retain armor state and alpha")
	probe._draw_plant_body("potato_mine", center, 1.0, 0.0, 1.0, {"armed": false, "arm_timer": float(Defs.PLANTS.potato_mine.arm_time) * 0.75})
	check(probe.trace.back()[3] == false and is_equal_approx(probe.trace.back()[4], 0.25), "An unarmed mine must not use the armed portrait")
	probe._draw_plant_body("potato_mine", center)
	check(probe.trace.back()[3] == true, "Mine portraits must show the recognizable armed form")
	probe._draw_plant_body("chomper", center, 1.0, 0.0, 1.0, {"chew_timer": float(Defs.PLANTS.chomper.chew_time) * 0.5})
	check(is_equal_approx(probe.trace.back()[3], 0.5), "Chomper must retain its chewing pose")
	probe._draw_plant_body("sun_shroom", center, 1.0, 0.0, 1.0, {"mature": false})
	check(probe.trace.back()[3] == false, "Young sun-shrooms must stay visibly young")
	probe._draw_plant_body("sun_shroom", center)
	check(probe.trace.back()[3] == true, "The almanac must show the mature sun-shroom")
	probe._draw_plant_body("scaredy_shroom", center)
	check(probe.trace.back()[3] == false, "Portraits must not inherit a nearby battle enemy's fear state")
	probe._draw_plant_body("snow_bloom", center, 1.0, 0.0, 1.0, {"fuse_timer": float(Defs.PLANTS.snow_bloom.wilt_time) * 0.4})
	check(is_equal_approx(probe.trace.back()[3], 0.4), "Wilting state must reach the dedicated flower renderer")
	for kind in Defs.PLANTS:
		if bool(Defs.PLANTS[kind].get("volcano_expansion", false)):
			continue
		var method := "_draw_bowling_nut" if kind == "wallnut_bowling" else "_draw_%s" % kind
		check(probe.has_method(method), "Missing species-specific renderer: %s" % kind)
	for kind in Defs.ZOMBIES:
		var bounds: Rect2 = probe._zombie_portrait_bounds(kind)
		var fit := minf(96.0 / bounds.size.x, 104.0 / bounds.size.y)
		check(bounds.size.x * fit <= 96.01 and bounds.size.y * fit <= 104.01, "Accessories must fit the portrait: %s" % kind)
	probe.free()
	for viewport in [Vector2(844, 390), Vector2(1000, 450), Vector2(1280, 720), Vector2(1600, 900)]:
		var layout := GameScript.new()
		layout.size = viewport
		layout.mobile_runtime_override = 1 if viewport.y < 600 else 0
		layout.mode = layout.MODE_BATTLE
		for rows in [5, 6]:
			layout.board_rows = rows
			layout._refresh_battle_layout()
			var hud: Dictionary = layout._boss_health_bar_layout({})
			check(hud.rect.position.y - 26.0 >= layout.BOARD_ORIGIN.y + layout.board_size.y, "Boss labels must stay below all lanes at %s" % viewport)
		layout.free()

	var drawing := DrawingProbe.new()
	drawing.size = Vector2(800, 600)
	drawing.current_level = {"id": "identity-test", "terrain": "day", "events": []}
	drawing.level_time = 5.0
	var bosses := 0
	for kind in Defs.ZOMBIES:
		if drawing._boss_frame_count_for_kind(kind) > 0:
			bosses += 1
			drawing._queue_boss_frame_set_prewarm(kind)
	drawing._drain_asset_prewarm_queue()
	root.add_child(drawing)
	for frame in range(6):
		await process_frame
		if drawing.drew:
			break
	check(drawing.drew, "The live CanvasItem drawing path must execute")
	check(drawing.plant_count == Defs.PLANTS.size(), "Every plant must render through both card and preview paths")
	check(drawing.zombie_count == Defs.ZOMBIES.size(), "Every zombie must render through the icon path")
	check(bosses == 18 and drawing.textures_used.size() == bosses, "All 18 Touhou bosses must reach the original image pipeline")
	check(not drawing.wrong_texture and not drawing.missing_texture, "Each Touhou boss must use its own existing image frames")
	print("Unit identity: %d plants, %d zombies, %d original Touhou image sets; %d failure(s)" % [drawing.plant_count, drawing.zombie_count, bosses, failures])
	drawing.save_dirty = false
	drawing.free()
	quit(1 if failures else 0)
