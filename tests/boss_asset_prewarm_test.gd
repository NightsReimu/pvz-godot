extends SceneTree

const Game=preload("res://scripts/game.gd")
var failures:=0

func _initialize()->void:call_deferred("_run")

func check(condition:bool,message:String)->void:
	if not condition:failures+=1;push_error(message)

func make_game()->Control:
	var game:=Game.new()
	game.banner_label=Label.new()
	game.toast_label=Label.new()
	game.message_panel=PanelContainer.new()
	game.completed_levels.resize(Game.Defs.LEVELS.size())
	game.completed_levels.fill(true)
	game.current_level={"terrain":"day","events":[]}
	for kind in Game.TouhouSpriteDefs.IDLE_HEIGHTS:
		game._set_shared_boss_frames_for_kind(kind,[],false,null)
	Game.shared_audio_stream_cache.clear()
	return game

func release(game:Control)->void:
	game.save_dirty=false
	game.banner_label.free()
	game.toast_label.free()
	game.message_panel.free()
	game.free()

func _run()->void:
	_test_battle_lookup_remains_nonblocking_and_full()
	_test_visible_and_selected_almanac_previews()
	_test_map_and_selected_level_context("day","1-17","rumia_boss")
	_test_map_and_selected_level_context("night","2-25","letty_boss")
	_test_all_visible_map_badges_survive_trimming()
	print("Boss assets: nonblocking full combat warmup, visible almanac/map previews and selected level music; ",failures," failure(s)")
	quit(1 if failures else 0)

func _test_battle_lookup_remains_nonblocking_and_full()->void:
	var game:=make_game()
	game.mode=Game.MODE_BATTLE
	check(game._try_get_boss_frame_texture("cirno_boss",0)==null,"Cold combat lookup queues decoding instead of synchronously loading art")
	check(not game.cirno_frames_loaded and not game.asset_prewarm_queue.is_empty(),"Queued combat frames are not marked complete before loading")
	game._drain_asset_prewarm_queue()
	check(game._try_get_boss_frame_texture("cirno_boss",23)!=null and game.cirno_frames_loaded,"Combat warmup retains all 24 animation frames")
	release(game)

func _test_all_visible_map_badges_survive_trimming()->void:
	var game:=make_game()
	game.current_world_key="pool"
	game.mode=Game.MODE_MAP
	game._set_map_scroll("pool",1406.0,true)
	var visible:Dictionary={}
	for index in game._visible_level_indices("pool"):
		if not game._map_node_visible(game._map_node_position(index)):continue
		var level:Dictionary=Game.Defs.LEVELS[index]
		var mid:=String(level.get("mid_boss_kind",""))
		if game._is_image_backed_hover_boss(mid):visible[mid]=true
		for event in level.events:
			if game._is_image_backed_hover_boss(String(event.kind)):visible[String(event.kind)]=true
	check(visible.size()>3,"The actual late-pool map contains more visible characters than the recent-cache budget")
	game._queue_world_boss_asset_prewarm("pool")
	game._drain_asset_prewarm_queue()
	for kind in visible:
		check(game._try_get_boss_frame_texture(kind,0)!=null,"Every visible map badge remains resident after warmup: "+kind)
	check(game.asset_prewarm_queue.is_empty(),"Drawing warmed visible badges must not constantly reload each other")
	release(game)

func _test_visible_and_selected_almanac_previews()->void:
	var game:=make_game()
	game.almanac_selected_kind="rumia_boss"
	game._enter_almanac_mode("zombies")
	check(not game.asset_prewarm_queue.is_empty(),"Opening a selected Boss entry queues its visible preview")
	game._drain_asset_prewarm_queue()
	for index in [0,1,2]:check(game._try_get_boss_frame_texture("rumia_boss",index)!=null,"The selected entry's idle animation is ready")
	check(not game.rumia_frames_loaded,"An idle almanac preview does not retain unused full combat poses")
	game.almanac_selected_kind="nitori_boss"
	game._queue_almanac_boss_asset_prewarm("zombies")
	game._drain_asset_prewarm_queue()
	check(game._try_get_boss_frame_texture("nitori_boss",2)!=null,"Changing entries loads the new character's dynamic preview normally")
	check(Game.shared_audio_stream_cache.is_empty(),"Browsing character entries does not decode unrelated soundtracks")
	release(game)

func _test_map_and_selected_level_context(world:String,stage:String,kind:String)->void:
	var game:=make_game()
	game.current_world_key=world
	game.mode=Game.MODE_HOME
	var index:int=game._find_level_index_by_id(stage)
	game.selected_level_index=index
	game._ensure_level_visible_on_map(index)
	game._enter_map_mode(false)
	game._drain_asset_prewarm_queue()
	check(game._try_get_boss_frame_texture(kind,0)!=null,"The visible map Boss badge is warm: "+stage)
	check(Game.shared_audio_stream_cache.is_empty(),"Map navigation does not preload every level's BGM")
	var level:Dictionary=Game.Defs.LEVELS[index]
	game.current_level=level
	game.mode=Game.MODE_SELECTION
	game._queue_level_boss_asset_prewarm(level)
	game._drain_asset_prewarm_queue()
	check(game._try_get_boss_frame_texture(kind,23)!=null,"Selecting the encounter warms its complete future animation")
	for path in [game._regular_level_bgm_path(level),level.get("boss_intro_bgm",""),level.get("boss_bgm","")]:
		if not String(path).is_empty():check(game._try_get_cached_audio_stream(String(path))!=null,"The selected encounter's soundtrack is ready before play")
	release(game)
