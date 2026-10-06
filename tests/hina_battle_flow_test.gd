extends "res://scripts/tools/capture_battle_polish.gd"

var failures := 0

class ObservedGame extends PreviewGame:
	var declared: Array = []
	func _trigger_boss_skill(boss: Dictionary) -> Dictionary:
		declared.append(GameScript.TouhouSpellDefs.card_for(boss, current_level).id)
		return super._trigger_boss_skill(boss)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var base: Dictionary = {}
	for level in GameScript.Defs.LEVELS:
		if level.id == "4-20": base = level.duplicate(true)
	check(not base.is_empty(), "4-20 must exist before exercising its actual battle flow")
	if base.is_empty():
		quit(1)
		return
	base.custom_level = true
	for rank in range(4):
		var choice: String = ["easy", "normal", "hard", "lunatic"][rank]
		var game := ObservedGame.new()
		game.size = Vector2(1600, 900)
		root.add_child(game)
		var level: Dictionary = game.TouhouDifficulty.build_level(base, choice)
		game._begin_level(-1, ["sunflower", "repeater", "wallnut", "healing_gourd", "melon_pult", "torchwood", "jasmine_tea"], level)
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		check(game.active_rows == [0, 1, 2, 3, 4, 5] and game.water_rows.is_empty(), choice + ": all six active forest lanes are land")
		check(not game._is_fog_level() and not game._is_pool_level(), "Forest does not inherit fog or pool rules")
		check(game.current_bgm_path == level.boss_intro_bgm and game.music_player.playing, "The supplied road track is actually audible before either boss")
		var preview: Dictionary = game._selection_level_preview_style(level)
		check(int(preview.row_count) == 6 and preview.water_rows.is_empty() and String(preview.label).contains("山麓"), "The actual level preview identifies six dry mountain terraces")
		if choice != "lunatic": game.active_cards[0] = "repeater"
		game._handle_primary_click(game._card_rect(0).get_center())
		game._handle_primary_click(game._cell_center(5, 1))
		check(game.grid[5][1] != null, choice + ": real seed controls work on the sixth dry lane")
		game._spawn_frozen_branch_midboss()
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		var roads: Array = game.zombies.filter(func(z): return z.kind == "hina_boss" and bool(z.get("touhou_final_preview", false)))
		check(roads.size() == 1, "The actual road-flow spawner creates Hina's weaker incarnation")
		if roads.is_empty():
			await _release_game(game)
			continue
		var road: Dictionary = roads.back()
		check(bool(road.touhou_road_boss) and bool(road.get("touhou_road_spell", false)), "Road Hina is a weaker same-character encounter with a mandatory spell")
		var road_card: Array = game.TouhouSpellDefs.Hina.road_card(level)
		check(road.touhou_encounter.phases == [[road_card]], "The weak road preserves exactly one canonical card")
		check(game.current_bgm_path == level.boss_intro_bgm and game.pending_bgm_path != String(level.boss_bgm), "Road Hina never queues finale music")
		check(game.music_player.stream == game._try_get_cached_audio_stream(String(level.boss_intro_bgm)), "Actual road playback remains the supplied stage MP3")
		var road_uid := int(road.uid)
		var road_hp := float(road.max_health)
		for frame in range(30):
			game.level_time += 0.1
			game._ensure_zombie_runtime().update_boss(road, 0.1)
			game._ensure_hina_runtime().update(0.1)
		check(game.declared.is_empty() and game._ensure_hina_runtime().fields.is_empty() and (game.touhou_danmaku == null or game.touhou_danmaku.casts.is_empty()), "The brief arrival fade never launches concealed attacks")
		check(float(road.get("hina_arrival_age", 0.0)) >= 3.0 and not bool(road.get("touhou_invulnerable", false)), "Road appearance timing advances without hiding an invulnerability phase")
		game._apply_zombie_damage(road, 10000000, 0, 0, true)
		check(not bool(road.touhou_encounter.complete) and road.health > 0, "Burst damage cannot interrupt the road's mandatory canonical spell")
		# Isolate sequencing from native defense, which is exercised separately
		# by the full empty-board balance routes with all enemy damage enabled.
		for frame in range(1200):
			game._apply_zombie_damage(road, 10000000, 0, 0, true)
			game.level_time += 0.1
			game._ensure_zombie_runtime().update_boss(road, 0.1)
			if game.touhou_danmaku != null: game.touhou_danmaku.update(0.1)
			game._ensure_hina_runtime().update(0.1)
			game._update_effects(0.1)
			if bool(road.touhou_encounter.complete): break
		check(bool(road.touhou_encounter.complete), "The weak road card finishes and permits retreat")
		check(game.declared.has(road_card[0]), "The actual road attack dispatch reaches its canonical card")
		game._cleanup_dead_zombies()
		game._update_frozen_branch_flow()
		check(not game.zombies.any(func(z): return z.kind == "hina_boss" and z.health > 0), "Defeated road Hina retreats before her full incarnation")
		check(game._ensure_hina_runtime().fields.is_empty() and game._ensure_hina_runtime().dolls.is_empty(), "Road retreat clears its hazards and bodies")
		check(game.current_bgm_path == level.boss_intro_bgm, "The stage track continues after the road retreats")
		game._spawn_zombie_at("hina_boss", 2, game._boss_anchor_x("hina_boss"), true)
		game._drain_asset_prewarm_queue()
		game._try_play_pending_bgm()
		var boss: Dictionary = game.zombies.filter(func(z): return z.kind == "hina_boss" and not bool(z.get("touhou_final_preview", false))).back()
		check(int(boss.uid) != road_uid and boss.max_health > road_hp * 8 and boss.health == boss.max_health, "Final Hina has a fresh UID and full strengthened health")
		check(not bool(boss.touhou_road_boss) and not bool(boss.get("touhou_road_spell", false)), "The finale inherits neither road role nor its shortened route")
		check(boss.touhou_encounter.phases.size() == rank + 6, "The actual finale uses six through nine full spell phases")
		check(game.current_bgm_path == level.boss_bgm and game.music_player.playing, "Only actual final Hina starts the supplied ending track")
		check(game.music_player.stream == game._try_get_cached_audio_stream(String(level.boss_bgm)), "The actual finale stream is the supplied ending MP3")
		check(int(game._boss_health_bar_layout(boss).segments) == 1, "Hina uses the standard live current-phase Touhou health bar")
		check(game._boss_cast_status(boss).text.contains("非符"), "Final Hina begins with her readable opening nonspell")
		var enemies_before: int = game.zombies.size()
		boss.rumia_reinforcement_timer = 0.0
		game._update_zombies(0.1)
		check(game.zombies.size() > enemies_before and game.zombies.any(func(z): return String(z.kind) in level.enemy_whitelist and z.health > 0), "Forest enemies keep appearing during Hina's live fight")
		for frame in range(24): check(game._try_get_boss_frame_texture("hina_boss", frame) != null, "The supplied Hina pose loads " + str(frame))
		var rt = game._ensure_hina_runtime()
		rt.queue_field(int(boss.uid), Vector2i(5, 1), "curse", 1.2)
		game.battle_paused = true
		game._process(1.0)
		check(float(rt.fields.back().age) == 0.0, "Battle pause freezes the curse warning")
		game.battle_paused = false
		rt.update(1.3)
		if game.grid[5][1] == null: game.grid[5][1] = game._create_plant("repeater", 5, 1)
		check(rt.action_factor(5, 1) == 0.72, "A native repeater on lane six receives the active curse")
		game._ensure_plant_food_runtime().activate(5, 1)
		check(rt.fields.is_empty(), "Actual plant-food activation cleans its cursed row")
		rt.queue_field(int(boss.uid), Vector2i(4, 1), "curse", 1.2)
		game.grid[4][1] = game._create_plant("repeater", 4, 1)
		game._update_ultimate_charges(120.0)
		check(game._try_activate_ultimate(4, 1) and rt.fields.is_empty(), "A real earned click ultimate cleans its cursed row")
		rt.queue_field(int(boss.uid), Vector2i(3, 1), "curse", 1.2)
		rt.queue_field(int(boss.uid), Vector2i(3, 7), "doll", 1.4)
		rt.update(1.5)
		game._trigger_boss_phase_shift(boss, 1)
		check(rt.fields.is_empty() and rt.dolls.is_empty(), "A real phase shift clears previous curses and dolls")
		_test_actual_emissions(game, boss)
		await _release_game(game)
	print("Hina real road/finale identities, mandatory road card, four modes, six-row input, BGM and counterplay: %d failure(s)" % failures)
	call_deferred("quit", 1 if failures else 0)


func _test_actual_emissions(game: Control, boss: Dictionary) -> void:
	var rt = game._ensure_hina_runtime()
	var owner := int(boss.uid)
	var cell := Vector2i(4, 2)
	# Short mobile cells expose muzzle-to-next-column errors. Every three-line
	# volley must retain the actual source row, including the two adjacent lanes.
	game.CELL_SIZE = Vector2(52, 20)
	game.BOARD_ORIGIN = Vector2(37, 129)
	game.board_size = game.CELL_SIZE * Vector2(9, 6)
	game._spawn_zombie_at("normal", 4, game._cell_center(4, 8).x, true)
	for route in ["native", "fusion", "support"]:
		for ultimate in [false, true]:
			for row in range(6):
				for col in range(9):
					game.grid[row][col] = null
					game.support_grid[row][col] = null
			rt.clear_owner(owner)
			game.projectiles.clear()
			var kind: String = "threepeater" if route == "native" else game._ensure_plant_fusion().Fusion.result("threepeater", "wallnut" if route == "fusion" else "holy_flower")
			var plant: Dictionary = game._create_plant(kind, cell.x, cell.y)
			if route == "support":
				plant.attached = true
				game.support_grid[cell.x][cell.y] = plant
			else: game.grid[cell.x][cell.y] = plant
			plant.shot_cooldown = 0.0
			plant.ultimate_active = ultimate
			plant.ultimate_timer = 10.0
			if plant.has("fusion_kind"):
				var state: Dictionary = game._ensure_plant_fusion().NativeRuntime.new(game).state_for(plant, "threepeater", cell.x, cell.y)
				state.shot_cooldown = 0.0
			rt.queue_field(owner, cell, "misfire", 1.2)
			rt.update(1.3)
			game._update_plants(0.01)
			check(game.projectiles.size() >= 3, route + ": actual plant actions produce the native three-line volley")
			if game.projectiles.size() < 3: continue
			check(game.projectiles.all(func(p): return Vector2i(p.get("source_cell", Vector2i(-1, -1))) == cell), route + ": ordinary and adjacent-lane shots retain their real source cell on mobile")
			game._update_projectiles(0.0)
			if ultimate:
				check(game.projectiles.all(func(p): return not bool(p.get("hina_misfire", false))) and int(rt.fields[0].shots) == 0, route + ": actual ultimate emissions are exempt and do not consume the misfire counter")
			else:
				check(game.projectiles.any(func(p): return bool(p.get("hina_misfire", false))), route + ": actual three-line emissions apply the cursed source's third-shot penalty")
		rt.clear_owner(owner)

func _release_game(game: Control) -> void:
	game._stop_bgm()
	game.music_player.stream = null
	game.save_dirty = false
	await create_timer(0.3).timeout
	game.free()
	await process_frame
