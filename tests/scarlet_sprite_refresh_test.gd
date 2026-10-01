extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const SpriteDefs = preload("res://scripts/data/touhou_sprite_defs.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := GameScript.new()
	var passed := true
	for kind in SpriteDefs.SCARLET_ANIMATIONS:
		var animations: Dictionary = SpriteDefs.SCARLET_ANIMATIONS[kind]
		for state in animations:
			if state == "hit":
				continue
			var seen := {}
			for tick in range(48):
				game.level_time = tick / 12.0
				var boss := {"kind": kind, "rumia_state": state, "boss_state": state, "anim_phase": 0.0}
				var frame: int = game._boss_frame_index_for_kind(boss)
				passed = _check(animations[state].has(frame), kind + " must use its supplied " + state + " poses") and passed
				passed = _check(not animations.hit.has(frame), kind + " must not play a hit reaction during " + state) and passed
				seen[frame] = true
			passed = _check(seen.size() > 1, kind + " " + state + " must animate") and passed
		for tick in range(12):
			game.level_time = tick / 10.0
			var boss := {"kind": kind, "rumia_state": "phase", "impact_timer": 0.2}
			passed = _check(animations.hit.has(game._boss_frame_index_for_kind(boss)), kind + " must use its actual hit poses") and passed
		for index in range(24):
			var texture: Texture2D = game._load_single_boss_frame(kind, index, false)
			passed = _check(texture != null and texture.get_size() == Vector2(512, 384), kind + " must retain its full anchored canvas") and passed
			if texture != null:
				var source := Image.new()
				source.load(ProjectSettings.globalize_path(game._boss_frame_resource_path(kind, index)))
				var imported := texture.get_image()
				source.convert(Image.FORMAT_RGBA8)
				imported.convert(Image.FORMAT_RGBA8)
				var source_bytes := source.get_data()
				var imported_bytes := imported.get_data()
				var same_alpha := source_bytes.size() == imported_bytes.size()
				# Godot's alpha-border import fills invisible RGB to avoid dark
				# filtering fringes; compare the actual silhouette/particles.
				for byte_index in range(3, mini(source_bytes.size(), imported_bytes.size()), 4):
					if source_bytes[byte_index] != imported_bytes[byte_index]:
						same_alpha = false
						break
				passed = _check(same_alpha, kind + " must preserve alpha, facing and detached spell particles") and passed
	game.free()
	print("Scarlet sprite animation, reaction, canvas and particle preservation: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition
