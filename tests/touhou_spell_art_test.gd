extends "res://tests/touhou_spell_contract_test.gd"

const Art = preload("res://scripts/ui/touhou_spell_art.gd")

func _run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/touhou_spell_fx/manifest.json"))
	for asset in Art.ASSETS:
		var image: Texture2D = Art.texture(asset)
		check(image != null and image == Art.texture(asset), "Spell art must load once and be shared")
		var pixels := image.get_image()
		pixels.convert(Image.FORMAT_RGBA8)
		var rgba := pixels.get_data()
		var alpha := PackedByteArray()
		alpha.resize(pixels.get_width() * pixels.get_height())
		for index in range(alpha.size()):
			alpha[index] = rgba[index * 4 + 3]
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(alpha)
		check(hash.finish().hex_encode() == manifest.assets[asset].alpha_sha256, "Godot imports must preserve the generated glow alpha exactly")
	check(Art.texture("missing") == null, "Unknown art falls back without loading an invalid resource")
	Art.textures.clear()
	var prewarm := make_game()
	prewarm._queue_boss_frame_set_prewarm("reimu_boss")
	prewarm._queue_boss_frame_set_prewarm("chen_boss")
	var tasks := 0
	for task in prewarm.asset_prewarm_queue:
		if task.type == "touhou_spell_art":
			tasks += 1
	check(tasks == 1, "Bosses sharing an illustration must queue one prewarm task")
	prewarm._queue_boss_frame_set_prewarm("prismriver_boss")
	var trio_tasks := 0
	for task in prewarm.asset_prewarm_queue:
		if task.type == "prismriver_frame": trio_tasks += 1
	check(trio_tasks == 72, "All three performers prewarm independent poses")
	prewarm._drain_asset_prewarm_queue()
	check(Art.textures.has("crimson_seal"), "Prewarm must load art before the first spell")
	release(prewarm)
	Art.textures.clear()
	var menus := make_game()
	menus._queue_global_boss_asset_prewarm()
	check(not menus.asset_prewarm_queue.any(func(task): return task.type == "touhou_spell_art"), "Menu browsing must not eagerly load all large spell images")
	release(menus)
	check(Art.KIND_ART.size() == 29 and Art.ASSETS.size() == 27, "Every Touhou boss has a mapped illustration")
	var card_count := 0
	for kind in Spells.CARDS:
		for cycle in range(Spells.CARDS[kind].size()):
			var game := make_game(kind, cycle)
			game._trigger_boss_skill(game.zombies[0])
			var runtime = game.touhou_danmaku
			var cast: Dictionary = runtime.casts[0]
			var before: Dictionary = cast.duplicate(true)
			var bullets: Array = runtime.bullets.duplicate(true)
			var beams: Array = runtime.beams.duplicate(true)
			var random_state: int = game.rng.state
			var eligible: bool = Art.eligible(kind, cast.card)
			for age in [0.0, 0.15, 0.6, 1.8, float(cast.duration) - 0.01]:
				var snapshot := cast.duplicate(true)
				snapshot.age = age
				var visual := Art.state(snapshot)
				check(visual.is_empty() != eligible, "Illustrations apply only to supported spells and four unnamed midboss attacks")
				if not visual.is_empty():
					check(visual.alpha >= 0 and visual.alpha <= 0.42, "Spell illustration opacity is bounded")
					check(visual.extent > 0 and visual.extent <= 330, "Art must stay local to the boss")
					check(visual == Art.state(snapshot), "Paused spell visuals must hold exactly")
			var expired := cast.duplicate(true)
			expired.age = cast.duration
			check(Art.state(expired).is_empty(), "Art expires with its actual owning spell")
			expired.age = -0.1
			check(Art.state(expired).is_empty(), "Invalid ages cannot draw stale art")
			check(before == cast and bullets == runtime.bullets and beams == runtime.beams and random_state == game.rng.state, "Visual state reads must not alter combat or consume random numbers")
			runtime.clear_owner(int(cast.owner))
			check(runtime.casts.is_empty(), "Phase/death cleanup removes the illustration owner")
			card_count += 1
			release(game)
	print("Spell art: 27 exact imported alpha hashes, cache/prewarm, %d cards, immutable timing and ownership: %d failure(s)" % [card_count, failures])
	quit(1 if failures else 0)
