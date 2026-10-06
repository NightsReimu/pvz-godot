extends RefCounted

# Retain active encounter assets plus a small recent working set. Neither
# source pixels nor compressed audio bytes are altered by this policy.
const RECENT_BOSS_SETS := 3
const RECENT_MUSIC_STREAMS := 6
const RECENT_TEXTURE_PATHS := 128

var game: Control
var bosses: Array[String] = []
var music: Array[String] = []
var textures: Array[String] = []
var level_bosses: Dictionary = {}
var level_music: Dictionary = {}
var boss_loads := 0
var music_loads := 0
var texture_loads := 0
var dirty := true
var last_context := ""
var trim_passes := 0

func _init(owner: Control) -> void:
	game = owner

func _touch(recent: Array[String], key: String) -> void:
	if not recent.is_empty() and recent.back() == key: return
	recent.erase(key)
	recent.append(key)

func touch_boss(kind: String) -> void: _touch(bosses, kind)
func touch_music(path: String) -> void: _touch(music, path)
func touch_texture(path: String) -> void: _touch(textures, path)

func set_level(kinds: Dictionary, paths: Array) -> void:
	dirty = true
	level_bosses = kinds.duplicate()
	level_music.clear()
	for path in paths:
		if not String(path).is_empty(): level_music[String(path)] = true

func _has_level_context() -> bool:
	return game.mode in [game.MODE_BATTLE, game.MODE_SELECTION] or game._touhou_difficulty_is_open() or game._level_difficulty_is_open()

func _boss_pins() -> Dictionary:
	var pins := level_bosses.duplicate() if _has_level_context() else {}
	if game.mode == game.MODE_BATTLE:
		for zombie in game.zombies:
			var kind := String(zombie.get("kind", ""))
			if game._is_image_backed_hover_boss(kind): pins[kind] = true
	if game.mode == game.MODE_MAP:
		for index in game._visible_level_indices(game.current_world_key):
			if not game._map_node_visible(game._map_node_position(int(index))): continue
			var level: Dictionary = game.Defs.LEVELS[int(index)]
			var mid := String(level.get("mid_boss_kind", ""))
			if game._is_image_backed_hover_boss(mid): pins[mid] = true
			for event in level.events:
				var kind := String(event.kind)
				if game._is_image_backed_hover_boss(kind): pins[kind] = true
	if game.mode == game.MODE_ALMANAC and game.almanac_tab == "zombies":
		var entries: Array = game._visible_almanac_zombies()
		var view: Rect2 = game._almanac_list_view_rect()
		for i in range(entries.size()):
			if view.encloses(game._almanac_item_rect(i)) and game._is_image_backed_hover_boss(String(entries[i])): pins[String(entries[i])] = true
		if game._is_image_backed_hover_boss(String(game.almanac_selected_kind)): pins[String(game.almanac_selected_kind)] = true
	for task in game.asset_prewarm_queue:
		if String(task.type) == "boss_frame": pins[String(task.kind)] = true
		if String(task.type) == "prismriver_frame": pins["prismriver_boss"] = true
	return pins

func _keep(keys: Dictionary, recent: Array[String], pins: Dictionary, limit: int) -> Dictionary:
	var kept := {}
	for key in pins:
		if keys.has(key): kept[key] = true
	for i in range(recent.size() - 1, -1, -1):
		if kept.size() >= limit: break
		if keys.has(recent[i]): kept[recent[i]] = true
	# Shared caches can survive the previous Game instance, while its recency
	# list does not. Keep a bounded tail until those entries are touched again.
	var inherited: Array = keys.keys()
	for i in range(inherited.size() - 1, -1, -1):
		if kept.size() >= limit: break
		kept[inherited[i]] = true
	return kept

func trim() -> void:
	var context := str([game.mode, game.current_level.get("id", ""), game.current_bgm_path, game.pending_bgm_path, game.almanac_tab, game.almanac_selected_kind, game.almanac_scroll, game.current_world_key, game._touhou_difficulty_is_open(), game._level_difficulty_is_open(), game._map_scroll_value(game.current_world_key) if game.mode == game.MODE_MAP else 0.0])
	if not dirty and context == last_context: return
	dirty = false
	last_context = context
	trim_passes += 1
	var cached := {}
	for kind in game.TouhouSpriteDefs.IDLE_HEIGHTS:
		var frames: Array = game._shared_boss_frames_for_kind(String(kind))
		if frames.any(func(frame): return frame != null): cached[String(kind)] = true
	var pinned := _boss_pins()
	var kept := _keep(cached, bosses, pinned, RECENT_BOSS_SETS)
	for kind in cached:
		if kept.has(kind): continue
		game._set_shared_boss_frames_for_kind(kind, [], false, null)
		game._set_instance_boss_frames_for_kind(kind, [], false, null)
		bosses.erase(kind)
	if not kept.has("prismriver_boss") and not pinned.has("prismriver_boss"): game.PrismriverTrio.textures.clear()
	var spell_art := {}
	var art_kinds := kept.duplicate()
	art_kinds.merge(pinned)
	for kind in art_kinds:
		for asset in game.TouhouSpellArt.assets_for_kind(kind): spell_art[String(asset)] = true
	for asset in game.TouhouSpellArt.textures.keys():
		if not spell_art.has(asset): game.TouhouSpellArt.textures.erase(asset)
	var music_pins := level_music.duplicate() if _has_level_context() else {}
	for path in [game.current_bgm_path, game.pending_bgm_path]:
		if not String(path).is_empty(): music_pins[String(path)] = true
	for task in game.asset_prewarm_queue:
		if String(task.type) == "audio": music_pins[String(task.path)] = true
	_trim_dictionaries(game._resource_music_caches(), music, music_pins, RECENT_MUSIC_STREAMS)
	_trim_dictionaries(game._resource_texture_caches(), textures, {}, RECENT_TEXTURE_PATHS)

func _trim_dictionaries(caches: Array, recent: Array[String], pins: Dictionary, limit: int) -> void:
	var keys := {}
	for cache in caches:
		for key in cache: keys[String(key)] = true
	var kept := _keep(keys, recent, pins, limit)
	for key in keys:
		if kept.has(key): continue
		for cache in caches: cache.erase(key)
		recent.erase(key)

func stats() -> Dictionary:
	var sets := 0
	var frames := 0
	for kind in game.TouhouSpriteDefs.IDLE_HEIGHTS:
		var available: Array = game._shared_boss_frames_for_kind(String(kind))
		var count: int = available.filter(func(frame): return frame != null).size()
		if count > 0: sets += 1
		frames += count
	var paths := {}
	var bytes := 0
	for cache in game._resource_music_caches():
		for path in cache:
			if paths.has(path): continue
			paths[path] = true
			var stream: AudioStream = cache[path]
			if stream is AudioStreamMP3: bytes += stream.data.size()
	return {"boss_sets": sets, "boss_frames": frames, "music_streams": paths.size(), "music_bytes": bytes, "boss_loads": boss_loads, "music_loads": music_loads, "texture_loads": texture_loads, "trim_passes": trim_passes}
