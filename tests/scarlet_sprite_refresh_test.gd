extends SceneTree

const GameScript = preload("res://scripts/game.gd")
const SpriteDefs = preload("res://scripts/data/touhou_sprite_defs.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := GameScript.new()
	var passed := true
	var supplied: Dictionary = SpriteDefs.SCARLET_ANIMATIONS.duplicate()
	supplied.merge(SpriteDefs.IMPERISHABLE_ANIMATIONS)
	for kind in supplied:
		var animations: Dictionary = supplied[kind]
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
	game.level_time = 0.34
	passed = _check(SpriteDefs.IMPERISHABLE_ANIMATIONS.mystia_boss.cook.has(game._mystia_frame_index({"rumia_state": "wing", "mystia_cooking_timer": 1.0})), "Mystia cooking timer must select her charge poses") and passed
	passed = _check(SpriteDefs.IMPERISHABLE_ANIMATIONS.mystia_boss.song.has(game._mystia_frame_index({"rumia_state": "idle", "mystia_state": "song"})), "Mystia secondary state must be represented") and passed
	var timed_boss := {"kind": "keine_boss", "rumia_state": "whip", "touhou_cast_duration": 2.0, "touhou_cast_remaining": 1.4}
	var paused_frame := game._keine_frame_index(timed_boss)
	game.level_time += 1.0
	passed = _check(game._keine_frame_index(timed_boss) == paused_frame, "Keine timed cast must follow cast progress") and passed
	game.free()
	print("Supplied sprite animation, reaction, canvas and particle preservation: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition
