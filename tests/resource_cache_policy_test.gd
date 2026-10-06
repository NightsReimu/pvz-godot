extends SceneTree

const Game=preload("res://scripts/game.gd")
var failures:=0

func check(condition:bool,message:String)->void:
	if not condition:failures+=1;push_error(message)

func _initialize()->void:call_deferred("_run")

func make_game()->Control:
	var game:=Game.new()
	game.banner_label=Label.new()
	game.toast_label=Label.new()
	game.mode=Game.MODE_HOME
	return game

func free_game(game:Control)->void:
	game.save_dirty=false
	game.banner_label.free()
	game.toast_label.free()
	game.free()

func _run()->void:
	var game:=make_game()
	game._begin_startup_loading()
	var boss_tasks:=0
	var audio_tasks:=0
	for task in game.asset_prewarm_queue:
		if task.type in ["boss_frame","prismriver_frame"]:boss_tasks+=1
		if task.type=="audio":audio_tasks+=1
	check(boss_tasks==0 and audio_tasks==0,"Home startup cannot predecode every unseen Boss animation and soundtrack")
	check(game.asset_prewarm_queue.size()<=16,"Home startup warms only its small visible UI")
	game._drain_asset_prewarm_queue()
	check(game.has_method("_resource_cache_stats"),"Resource retention has measurable bounded cache statistics")
	if not game.has_method("_resource_cache_stats"):
		free_game(game)
		print("Resource cache policy: ",failures," failure(s)")
		quit(1)
		return
	var level:Dictionary={}
	for entry in Game.Defs.LEVELS:
		if entry.id=="4-19":level=entry
	game.current_level=level
	game.mode=Game.MODE_BATTLE
	game._queue_level_boss_asset_prewarm(level)
	game._drain_asset_prewarm_queue()
	var first:Texture2D=game._try_get_boss_frame_texture("minoriko_boss",23)
	check(first!=null and game._try_get_boss_frame_texture("shizuha_boss",23)!=null,"Current final/road retain every required animation pose")
	var before:Dictionary=game.call("_resource_cache_stats")
	game._queue_level_boss_asset_prewarm(level)
	game._drain_asset_prewarm_queue()
	var reused:Dictionary=game.call("_resource_cache_stats")
	check(reused.boss_loads==before.boss_loads and reused.music_loads==before.music_loads,"Repeating a prepared encounter reuses its frames and compressed audio")
	var trim_before:=int(reused.get("trim_passes",-1))
	for _frame in range(20):
		game._try_get_boss_frame_texture("minoriko_boss",0)
		game._service_asset_prewarm_queue(0)
	check(trim_before>=0 and int(game.call("_resource_cache_stats").get("trim_passes",-1))==trim_before,"A steady cached render loop must not repeatedly scan all retained resources")
	var trio_level:Dictionary={}
	for entry in Game.Defs.LEVELS:
		if entry.id=="2-28":trio_level=entry
	game.current_level=trio_level
	game._queue_level_boss_asset_prewarm(trio_level)
	game._drain_asset_prewarm_queue()
	check(Game.PrismriverTrio.textures.size()==72,"An active trio retains all three members' full animation before its first draw")
	for asset in Game.TouhouSpellArt.assets_for_kind("prismriver_boss"):
		check(Game.TouhouSpellArt.textures.has(asset),"Active spell art queued before the frame bank cannot be prematurely evicted")
	game.mode=Game.MODE_HOME
	for kind in ["rumia_boss","cirno_boss","hina_boss","nitori_boss","suika_boss"]:
		game._queue_boss_frame_set_prewarm(kind,false)
		game._drain_asset_prewarm_queue()
	var trimmed:Dictionary=game.call("_resource_cache_stats")
	check(trimmed.boss_sets<=3,"Leaving old encounters releases both shared and instance frame arrays beyond three recent characters")
	check(game._try_get_boss_frame_texture("minoriko_boss",0)==null,"An evicted pose queues loading instead of blocking its lookup")
	game._drain_asset_prewarm_queue()
	check(game._try_get_boss_frame_texture("minoriko_boss",0)!=null,"An evicted character reloads normally without losing its dynamic asset path")
	var paths:Array=[]
	for entry in Game.Defs.LEVELS:
		for key in ["boss_bgm","boss_intro_bgm"]:
			var path:=String(entry.get(key,""))
			if not path.is_empty() and not paths.has(path):paths.append(path)
	for path in paths.slice(0,12):
		var stream:AudioStream=game._load_audio_stream(path)
		check(stream is AudioStreamMP3 and stream.data==FileAccess.get_file_as_bytes(path),"Music cache preserves original compressed MP3 bytes")
	var music:Dictionary=game.call("_resource_cache_stats")
	check(music.music_streams<=6,"Compressed BGM cache retains at most six unpinned recent tracks")
	var recent_path:=String(paths[11])
	var recent:AudioStream=game._load_audio_stream(recent_path)
	var music_before:Dictionary=game.call("_resource_cache_stats")
	check(game._load_audio_stream(recent_path)==recent,"A recent music switch reuses the same AudioStream")
	check(game.call("_resource_cache_stats").music_loads==music_before.music_loads,"Cached music switching does not decode another copy")
	var texture_paths:Array[String]=[]
	for asset in DirAccess.get_files_at("res://art/vector/fusions"):
		if asset.ends_with(".svg"):texture_paths.append(asset)
	check(texture_paths.size()>160,"The cache fixture uses actual imported fusion art")
	var first_path:="res://art/vector/fusions/"+texture_paths[0]
	var original_pixels:PackedByteArray=game._load_polished_texture(first_path).get_image().get_data()
	for asset in texture_paths.slice(1,160):
		game._load_polished_texture("res://art/vector/fusions/"+asset)
		game._service_asset_prewarm_queue(0)
	check(not Game.shared_polished_texture_cache.has(first_path) and not game.polished_texture_cache.has(first_path),"Generic art eviction releases both shared and instance references")
	var texture_before:Dictionary=game.call("_resource_cache_stats")
	check(game._load_polished_texture(first_path).get_image().get_data()==original_pixels,"Reloaded art preserves every original imported pixel and alpha byte")
	check(game.call("_resource_cache_stats").texture_loads==texture_before.texture_loads+1,"An evicted image is loaded exactly once on return")
	game._service_asset_prewarm_queue(0)
	var texture_keys:Dictionary={}
	for cache in game._resource_texture_caches():
		for key in cache:texture_keys[key]=true
	check(texture_keys.size()<=128,"Generic UI and plant art retain at most 128 recent paths")
	free_game(game)
	print("Resource cache policy: current poses/music, eviction/reload, exact MP3 bytes and bounded startup; ",failures," failure(s)")
	quit(1 if failures else 0)
