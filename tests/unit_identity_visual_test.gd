extends SceneTree

# Requires the display renderer: godot --path . -s res://tests/unit_identity_visual_test.gd
const GameScript = preload("res://scripts/game.gd")
const Defs = preload("res://scripts/game_defs.gd")
var failures := 0

class Pose extends GameScript:
	var subject := "peashooter"
	var category := "plants"
	var pose_state: Dictionary = {}
	var animated := false

	func _ready() -> void:
		_build_font()
		set_process(false)
		set_process_unhandled_input(false)

	func _save_game() -> void:
		pass

	func _draw() -> void:
		var center := Vector2(128, 144)
		if category == "plants":
			if animated:
				var state := {"kind": subject, "spawn_time": 0.0, "anim_phase": 0.0}
				state.merge(pose_state, true)
				var motion := _plant_draw_motion(state, center)
				draw_set_transform(motion.center, motion.rotation, motion.scale)
				center = Vector2.ZERO
			_draw_plant_body(subject, center, 1.0, 0.0, 1.0, pose_state)
		else:
			var state := {"kind": subject, "flash": 0.0, "slow_timer": 0.0, "shield_health": float(Defs.ZOMBIES[subject].get("shield_health", 0.0)), "has_vaulted": false, "portrait": true}
			state.merge(pose_state, true)
			_draw_zombie(center, state)


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func capture(surface: SubViewport, pose: Pose, category: String, subject: String, state: Dictionary = {}) -> Image:
	pose.category = category
	pose.subject = subject
	pose.pose_state = state
	pose.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return surface.get_texture().get_image()


func difference(a: Image, b: Image, silhouette: bool) -> float:
	var changed := 0
	var occupied := 0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var a_solid := ca.a > 0.6
			var b_solid := cb.a > 0.6
			if a_solid or b_solid:
				occupied += 1
				if (a_solid != b_solid) if silhouette else (absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) + absf(ca.a - cb.a) > 0.15):
					changed += 1
	return float(changed) / maxf(occupied, 1)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP: pixel comparison requires a display renderer")
		quit()
		return
	var surface := SubViewport.new()
	surface.size = Vector2i(256, 256)
	surface.transparent_bg = true
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(surface)
	var pose := Pose.new()
	pose.size = Vector2(surface.size)
	pose.current_level = {"terrain": "day"}
	pose.level_time = 5.0
	surface.add_child(pose)
	var groups := {
		"plants": [["peashooter", "threepeater"], ["peashooter", "cherry_bomb"], ["wallnut", "tallnut"], ["sunflower", "wallnut"], ["cactus", "spikeweed"], ["cabbage_pult", "kernel_pult"], ["lily_pad", "flower_pot"]],
		"zombies": [["normal", "conehead"], ["conehead", "buckethead"], ["normal", "newspaper"], ["normal", "pole_vault"], ["zomboni", "gargantuar"]],
	}
	for category in groups:
		for pair in groups[category]:
			var a := await capture(surface, pose, category, pair[0])
			var b := await capture(surface, pose, category, pair[1])
			check(a.get_used_rect().has_area() and b.get_used_rect().has_area(), "Both species must produce visible pixels")
			check(difference(a, b, true) > 0.03, "Species must differ in silhouette, not just color: %s / %s" % pair)
	var states := [
		["plants", "potato_mine", {"armed": false, "arm_timer": 12.0}, {"armed": true, "arm_timer": 0.0}],
		["plants", "wallnut", {"health": 100.0, "max_health": 100.0}, {"health": 20.0, "max_health": 100.0}],
		["plants", "chomper", {"chew_timer": 0.0}, {"chew_timer": 8.0}],
		["plants", "sun_shroom", {"mature": false}, {"mature": true}],
		["zombies", "conehead", {"shield_health": 100.0}, {"shield_health": 0.0}],
		["zombies", "newspaper", {"shield_health": 100.0}, {"shield_health": 0.0}],
		["zombies", "balloon_zombie", {"balloon_flying": true}, {"balloon_flying": false}],
	]
	for entry in states:
		var a := await capture(surface, pose, entry[0], entry[1], entry[2])
		var b := await capture(surface, pose, entry[0], entry[1], entry[3])
		check(difference(a, b, false) > 0.01, "Gameplay state must visibly change %s" % entry[1])
	pose.animated = true
	for subject in ["peashooter", "chomper", "sunflower"]:
		var idle := await capture(surface, pose, "plants", subject)
		var action := await capture(surface, pose, "plants", subject, {"action_timer": 0.09, "action_duration": 0.18})
		check(difference(idle, action, false) > 0.1, "Action motion must be visible: %s" % subject)
	pose.save_dirty = false
	surface.free()
	print("Unit visual identity: 12 silhouette pairs, 7 state changes, 3 action poses; %d failure(s)" % failures)
	quit(1 if failures else 0)
